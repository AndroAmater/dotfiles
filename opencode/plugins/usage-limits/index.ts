import { Plugin } from "@opencode/plugin"
import { readFile } from "node:fs/promises"
import { homedir } from "node:os"
import { join } from "node:path"
import { UsageLimits, type Account, type Snapshot, type Window } from "./rpc"

// Both usage endpoints are the private ones the official Claude Code and Codex
// clients poll. They are rate limited, so serve repeated sidebar refreshes
// from a cache.
const TTL = 60_000
const FORCED_TTL = 10_000
const USER_AGENT = "opencode-usage-limits"

type Json = Record<string, any>

export default Plugin.define({
  id: "usage-limits",
  async setup(ctx) {
    let cached: Snapshot | undefined
    let fetchedAt = 0
    let inflight: Promise<Snapshot> | undefined

    async function openai(signal: AbortSignal): Promise<Account | undefined> {
      const connection = await ctx.integration.connection.active("openai")
      if (!connection) return
      const credential = await ctx.integration.connection.resolve(connection)
      // API keys are billed per token and have no subscription windows.
      if (credential?.type !== "oauth") return
      const base = { id: "openai", name: "OpenAI", fetchedAt: Date.now() }
      if (credential.expires < Date.now()) return { ...base, windows: [], error: "sign-in expired" }
      const headers: Record<string, string> = {
        Authorization: `Bearer ${credential.access}`,
        Accept: "application/json",
        "User-Agent": USER_AGENT,
      }
      const accountID = credential.metadata?.accountID
      if (typeof accountID === "string") headers["ChatGPT-Account-Id"] = accountID
      const response = await fetch("https://chatgpt.com/backend-api/wham/usage", { headers, signal })
      if (!response.ok) return { ...base, windows: [], error: `HTTP ${response.status}` }
      const body = (await response.json()) as Json
      const windows: Window[] = [...openaiWindows(body.rate_limit)]
      if (Array.isArray(body.additional_rate_limits)) {
        for (const extra of body.additional_rate_limits as Json[]) {
          const name = extra.limit_name ?? extra.metered_feature
          windows.push(...openaiWindows(extra.rate_limit, typeof name === "string" ? name : undefined))
        }
      }
      return { ...base, plan: capitalize(body.plan_type), windows }
    }

    async function claude(signal: AbortSignal): Promise<Account | undefined> {
      const directory = process.env.CLAUDE_CONFIG_DIR ?? join(homedir(), ".claude")
      const file = await readFile(join(directory, ".credentials.json"), "utf8").catch(() => undefined)
      if (!file) return
      const oauth = (JSON.parse(file) as Json).claudeAiOauth as Json | undefined
      if (!oauth?.accessToken) return
      const base = { id: "claude", name: "Claude", plan: claudePlan(oauth), fetchedAt: Date.now() }
      // Claude Code owns the refresh token and rotates it on refresh, so only
      // read the access token it keeps current.
      if (typeof oauth.expiresAt === "number" && oauth.expiresAt < Date.now()) {
        return { ...base, windows: [], error: "token expired, run claude" }
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
      if (!response.ok) return { ...base, windows: [], error: `HTTP ${response.status}` }
      return { ...base, windows: claudeWindows((await response.json()) as Json) }
    }

    async function load(): Promise<Snapshot> {
      const signal = AbortSignal.timeout(15_000)
      const sources = [
        { id: "claude", name: "Claude", fetch: claude },
        { id: "openai", name: "OpenAI", fetch: openai },
      ]
      const results = await Promise.all(
        sources.map(async (source): Promise<Account | undefined> => {
          try {
            return await source.fetch(signal)
          } catch (error) {
            // Keep showing the last known windows rather than blanking the sidebar.
            const previous = cached?.accounts.find((account) => account.id === source.id)
            return {
              ...previous,
              id: source.id,
              name: source.name,
              windows: previous?.windows ?? [],
              error: error instanceof Error ? error.message : String(error),
              fetchedAt: Date.now(),
            }
          }
        }),
      )
      const accounts = results.filter((account): account is Account => account !== undefined)
      // RPC output must be plain JSON, which rejects properties set to undefined.
      return JSON.parse(JSON.stringify({ accounts })) as Snapshot
    }

    const registration = await ctx.rpc.register(UsageLimits, {
      get: async (input) => {
        const ttl = (input as { force?: boolean }).force ? FORCED_TTL : TTL
        if (cached && Date.now() - fetchedAt < ttl) return cached
        inflight ??= load()
          .then((snapshot) => {
            cached = snapshot
            fetchedAt = Date.now()
            return snapshot
          })
          .finally(() => (inflight = undefined))
        return inflight
      },
    })

    return () => registration.dispose()
  },
})

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
