import { Plugin } from "@opencode/plugin"
import { mkdir, readFile, rename, writeFile } from "node:fs/promises"
import { homedir } from "node:os"
import { dirname, join } from "node:path"
import { UsageLimits, type Account, type Snapshot, type Window } from "./rpc"

// Both usage endpoints are the private ones the official Claude Code and Codex
// clients poll, and they are rate limited. Every plugin instance (one per
// location, recreated on reload) and every OpenCode process shares one cache
// file, so the endpoints are hit at most once per TTL.
const TTL = 60_000
/** Back-off after a 429 without a usable Retry-After. */
const RATE_LIMITED = 5 * 60_000
const USER_AGENT = "opencode-usage-limits"
const CACHE = join(process.env.XDG_CACHE_HOME ?? join(homedir(), ".cache"), "opencode", "usage-limits.json")

type Json = Record<string, any>

interface Cache {
  readonly fetchedAt: number
  readonly snapshot: Snapshot
  /** Per account, when the endpoint may be called again after a 429. */
  readonly retryAt: Readonly<Record<string, number>>
}

class HttpError extends Error {
  constructor(
    readonly status: number,
    readonly retryAfter: number | undefined,
  ) {
    super(status === 429 ? "rate limited" : `HTTP ${status}`)
  }

  static from(response: Response) {
    const header = Number(response.headers.get("retry-after"))
    return new HttpError(response.status, Number.isFinite(header) && header > 0 ? header * 1000 : undefined)
  }
}

// Shared across plugin instances in this process, which each load a fresh copy of this module.
const global = globalThis as { [key: symbol]: { inflight?: Promise<Cache> } }
const shared = (global[Symbol.for("opencode.usage-limits")] ??= {})

export default Plugin.define({
  id: "usage-limits",
  async setup(ctx) {
    async function openai(signal: AbortSignal): Promise<Account | undefined> {
      const connection = await ctx.integration.connection.active("openai")
      if (!connection) return
      const credential = await ctx.integration.connection.resolve(connection)
      // API keys are billed per token and have no subscription windows.
      if (credential?.type !== "oauth") return
      if (credential.expires < Date.now()) throw new Error("sign-in expired")
      const headers: Record<string, string> = {
        Authorization: `Bearer ${credential.access}`,
        Accept: "application/json",
        "User-Agent": USER_AGENT,
      }
      const accountID = credential.metadata?.accountID
      if (typeof accountID === "string") headers["ChatGPT-Account-Id"] = accountID
      const response = await fetch("https://chatgpt.com/backend-api/wham/usage", { headers, signal })
      if (!response.ok) throw HttpError.from(response)
      const body = (await response.json()) as Json
      const windows: Window[] = [...openaiWindows(body.rate_limit)]
      if (Array.isArray(body.additional_rate_limits)) {
        for (const extra of body.additional_rate_limits as Json[]) {
          const name = extra.limit_name ?? extra.metered_feature
          windows.push(...openaiWindows(extra.rate_limit, typeof name === "string" ? name : undefined))
        }
      }
      return { id: "openai", name: "OpenAI", plan: capitalize(body.plan_type), windows, fetchedAt: Date.now() }
    }

    async function claude(signal: AbortSignal): Promise<Account | undefined> {
      const directory = process.env.CLAUDE_CONFIG_DIR ?? join(homedir(), ".claude")
      const file = await readFile(join(directory, ".credentials.json"), "utf8").catch(() => undefined)
      if (!file) return
      const oauth = (JSON.parse(file) as Json).claudeAiOauth as Json | undefined
      if (!oauth?.accessToken) return
      // Claude Code owns the refresh token and rotates it on refresh, so only
      // read the access token it keeps current.
      if (typeof oauth.expiresAt === "number" && oauth.expiresAt < Date.now()) {
        throw new Error("token expired, run claude")
      }
      const response = await fetch("https://api.anthropic.com/api/oauth/usage", {
        headers: {
          Authorization: `Bearer ${oauth.accessToken}`,
          "anthropic-beta": "oauth-2025-04-20",
          Accept: "application/json",
          "User-Agent": USER_AGENT,
        },
        signal,
      })
      if (!response.ok) throw HttpError.from(response)
      const windows = claudeWindows((await response.json()) as Json)
      return { id: "claude", name: "Claude", plan: claudePlan(oauth), windows, fetchedAt: Date.now() }
    }

    async function refresh(previous: Cache | undefined): Promise<Cache> {
      // Claim the slot first so other processes serve the old snapshot meanwhile.
      if (previous) await writeCache({ ...previous, fetchedAt: Date.now() })
      const signal = AbortSignal.timeout(15_000)
      const retryAt: Record<string, number> = { ...previous?.retryAt }
      const sources = [
        { id: "claude", name: "Claude", fetch: claude },
        { id: "openai", name: "OpenAI", fetch: openai },
      ]
      const results = await Promise.all(
        sources.map(async (source): Promise<Account | undefined> => {
          // Keep showing the last known windows rather than blanking the sidebar.
          const stale = (error: string): Account => {
            const last = previous?.snapshot.accounts.find((account) => account.id === source.id)
            return { fetchedAt: Date.now(), ...last, id: source.id, name: source.name, windows: last?.windows ?? [], error }
          }
          if ((retryAt[source.id] ?? 0) > Date.now()) return stale("rate limited")
          try {
            const account = await source.fetch(signal)
            delete retryAt[source.id]
            return account
          } catch (error) {
            if (error instanceof HttpError && error.status === 429) {
              retryAt[source.id] = Date.now() + Math.max(TTL, error.retryAfter ?? RATE_LIMITED)
            }
            return stale(error instanceof Error ? error.message : String(error))
          }
        }),
      )
      const accounts = results.filter((account): account is Account => account !== undefined)
      // RPC output must be plain JSON, which rejects properties set to undefined.
      const snapshot = JSON.parse(JSON.stringify({ accounts })) as Snapshot
      const cache = { fetchedAt: Date.now(), snapshot, retryAt }
      await writeCache(cache)
      return cache
    }

    const registration = await ctx.rpc.register(UsageLimits, {
      get: async () => {
        const cache = await readCache()
        if (cache && Date.now() - cache.fetchedAt < TTL) return cache.snapshot
        shared.inflight ??= refresh(cache).finally(() => (shared.inflight = undefined))
        return (await shared.inflight).snapshot
      },
    })

    return () => registration.dispose()
  },
})

async function readCache(): Promise<Cache | undefined> {
  try {
    return JSON.parse(await readFile(CACHE, "utf8")) as Cache
  } catch {
    return undefined
  }
}

async function writeCache(cache: Cache) {
  await mkdir(dirname(CACHE), { recursive: true })
  const temporary = `${CACHE}.${process.pid}.tmp`
  await writeFile(temporary, JSON.stringify(cache))
  await rename(temporary, CACHE)
}

function claudeWindows(body: Json): Window[] {
  const window = (label: string, entry: Json | null | undefined, scope?: string): Window[] =>
    entry && typeof entry.utilization === "number"
      ? [{ label, scope, usedPercent: entry.utilization, resetsAt: time(entry.resets_at) }]
      : []
  // Newer responses list every limit, including model-scoped weekly ones.
  if (Array.isArray(body.limits) && body.limits.length > 0) {
    return (body.limits as Json[])
      .filter((limit) => typeof limit.percent === "number")
      .map((limit) => {
        const scope = limit.scope?.model?.display_name ?? limit.scope?.surface
        const label =
          limit.kind === "session" ? "5h"
          : limit.group === "weekly" ? "7d"
          : String(limit.group ?? limit.kind)
        return {
          label,
          scope: typeof scope === "string" ? scope : limit.kind === "weekly_scoped" ? "scoped" : undefined,
          usedPercent: limit.percent,
          resetsAt: time(limit.resets_at),
        }
      })
  }
  return [
    ...window("5h", body.five_hour),
    ...window("7d", body.seven_day),
    ...window("7d", body.seven_day_opus, "Opus"),
    ...window("7d", body.seven_day_sonnet, "Sonnet"),
  ]
}

function openaiWindows(limit: Json | null | undefined, name?: string): Window[] {
  if (!limit) return []
  return [limit.primary_window, limit.secondary_window]
    .filter((window): window is Json => typeof window?.used_percent === "number")
    .map((window) => ({
      label: duration(window.limit_window_seconds),
      scope: name,
      usedPercent: window.used_percent,
      resetsAt: typeof window.reset_at === "number" ? window.reset_at * 1000 : undefined,
    }))
}

function claudePlan(oauth: Json) {
  const multiplier = /_(\d+x)$/.exec(String(oauth.rateLimitTier ?? ""))?.[1]
  const plan = capitalize(oauth.subscriptionType)
  return plan && multiplier ? `${plan} ${multiplier}` : plan
}

function duration(seconds: unknown) {
  if (typeof seconds !== "number") return "?"
  if (seconds % 86_400 === 0) return `${seconds / 86_400}d`
  if (seconds % 3_600 === 0) return `${seconds / 3_600}h`
  return `${Math.round(seconds / 60)}m`
}

function time(value: unknown) {
  if (typeof value !== "string") return undefined
  const parsed = Date.parse(value)
  return Number.isNaN(parsed) ? undefined : parsed
}

function capitalize(value: unknown) {
  return typeof value === "string" && value ? value[0]!.toUpperCase() + value.slice(1) : undefined
}
