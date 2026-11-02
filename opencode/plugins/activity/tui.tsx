/** @jsxImportSource @opentui/solid */
import type { SessionInfo, SessionMessageInfo, ShellInfo } from "@opencode/client"
import { Plugin, usePlugin } from "@opencode/plugin/tui"
import { createMemo, createSignal, For, Show } from "solid-js"

// Sidebar section listing the running subagents and shell commands of the
// current session's family, with each agent's model, thinking variant and
// output speed. Speed is measured like the transcript footer: output plus
// reasoning tokens over the time from step start to the end of the stream,
// across the most recently finished steps.

/** How many finished steps the speed is averaged over. */
const STEPS = 5

export default Plugin.define({
  id: "activity.sidebar",
  setup(context) {
    const location = context.location ?? context.data.location.default()
    const [now, setNow] = createSignal(Date.now())
    const tick = setInterval(() => setNow(Date.now()), 1000)
    const synced = new Set<string>()

    void context.data.location.model.sync(location).catch(() => {})

    /** Loads a collection once; later updates arrive through the host's event stream. */
    function once(key: string, load: () => Promise<void>) {
      if (synced.has(key)) return
      synced.add(key)
      void load().catch(() => synced.delete(key))
    }

    // A shell's status lives in the location's shell list; refresh it when one starts or stops.
    const resync = () => {
      for (const key of synced) {
        if (!key.startsWith("shell:")) continue
        const directory = key.slice("shell:".length)
        context.data.shell.invalidate({ directory })
        void context.data.shell.sync({ directory }).catch(() => {})
      }
    }
    const stops = (["shell.created", "shell.exited", "shell.deleted"] as const).map((type) => context.data.on(type, resync))

    const api: Api = {
      now,
      model(session) {
        const ref = session?.model
        if (!ref) return
        const models = context.data.location.model.list(location) ?? []
        const name = models.find((item) => item.id === ref.id && item.providerID === ref.providerID)?.name ?? ref.id
        return ref.variant ? `${name} · ${ref.variant}` : name
      },
      speed(sessionID) {
        once(`message:${sessionID}`, () => context.data.session.message.sync(sessionID))
        return speed(context.data.session.message.list(sessionID) ?? [])
      },
      shells(directory) {
        once(`shell:${directory}`, () => context.data.shell.sync({ directory }))
        return context.data.shell.list({ directory })
      },
    }

    const unslot = context.ui.slot({
      // Outside the content boundary, so it lands below every section appended inside it (Usage included).
      after: "sidebar.content",
      render: (input) => <Activity sessionID={input.sessionID} api={api} />,
    })

    return () => {
      clearInterval(tick)
      for (const stop of stops) stop()
      unslot()
    }
  },
})

interface Api {
  now(): number
  model(session: SessionInfo | undefined): string | undefined
  speed(sessionID: string): number | undefined
  shells(directory: string): ShellInfo[]
}

function Activity(props: { sessionID: string; api: Api }) {
  const { data, theme, ui } = usePlugin()
  const family = createMemo(() =>
    data.session.family(props.sessionID).flatMap((id) => {
      const session = data.session.get(id)
      return session ? [session] : []
    }),
  )
  const current = () => data.session.get(props.sessionID)
  const agents = createMemo(() =>
    family().filter((session) => session.id !== props.sessionID && !!session.parentID && data.session.status(session.id) === "running"),
  )
  const shells = createMemo(() => {
    const ids = new Set(family().map((session) => session.id))
    const directories = new Set(family().map((session) => session.location.directory))
    return [...directories]
      .flatMap((directory) => props.api.shells(directory))
      .filter((shell) => shell.status === "running" && ids.has(shell.metadata.sessionID))
      .toSorted((left, right) => left.time.started - right.time.started)
  })
  const open = (sessionID: string) => {
    if (sessionID !== props.sessionID) ui.router.navigate({ type: "session", sessionID })
  }
  return (
    <box flexDirection="column" width="100%" gap={1}>
      <box flexDirection="column" width="100%">
        <text fg={theme.text.base}>
          <b>Model</b>
        </text>
        <Details session={current()} api={props.api} />
      </box>
      <Show when={agents().length > 0}>
        <box flexDirection="column" width="100%">
          <text fg={theme.text.base}>
            <b>Agents</b>
          </text>
          <For each={agents()}>
            {(session) => (
              <box flexDirection="column" width="100%" onMouseUp={() => open(session.id)}>
                <Row label={title(session)} />
                <box paddingLeft={2}>
                  <Details session={session} api={props.api} />
                </box>
              </box>
            )}
          </For>
        </box>
      </Show>
      <Show when={shells().length > 0}>
        <box flexDirection="column" width="100%">
          <text fg={theme.text.base}>
            <b>Shells</b>
          </text>
          <For each={shells()}>
            {(shell) => (
              <box width="100%" onMouseUp={() => open(String(shell.metadata.sessionID))}>
                <Row label={command(shell.command)} status={elapsed(props.api.now() - shell.time.started)} />
              </box>
            )}
          </For>
        </box>
      </Show>
    </box>
  )
}

function Row(props: { label: string; status?: string }) {
  const { theme } = usePlugin()
  return (
    <box flexDirection="row" width="100%" gap={1}>
      <text fg={theme.text.feedback.success.base} flexShrink={0}>
        •
      </text>
      <box flexGrow={1} flexShrink={1} minWidth={0}>
        <text fg={theme.text.muted} wrapMode="none">
          {props.label}
        </text>
      </box>
      <Show when={props.status}>
        <text fg={theme.text.faint} flexShrink={0}>
          {props.status}
        </text>
      </Show>
    </box>
  )
}

/** Model, variant and speed on one line, each part only when known. */
function Details(props: { session: SessionInfo | undefined; api: Api }) {
  const { theme } = usePlugin()
  const text = () => {
    const session = props.session
    if (!session) return ""
    const tps = props.api.speed(session.id)
    return [props.api.model(session), tps === undefined ? undefined : `${tps.toFixed(1)} tok/s`].filter(Boolean).join(" · ")
  }
  return (
    <Show when={text()}>
      <text fg={theme.text.faint} wrapMode="none">
        {text()}
      </text>
    </Show>
  )
}

/** Tokens per second over the latest finished steps, or undefined before any step has finished. */
function speed(messages: SessionMessageInfo[]) {
  let tokens = 0
  let time = 0
  let steps = 0
  for (let index = messages.length - 1; index >= 0 && steps < STEPS; index--) {
    const message = messages[index]!
    if (message.type !== "assistant" || !message.tokens || message.time.streamed === undefined) continue
    tokens += message.tokens.output + message.tokens.reasoning
    time += Math.max(0, message.time.streamed - message.time.created)
    steps++
  }
  if (tokens <= 0 || time <= 0) return
  return tokens / (time / 1000)
}

/** The subagent's name and task, as the subagent picker shows them. */
function title(session: SessionInfo) {
  const raw = session.title ?? "Subagent"
  const tag = raw.match(/@(\w+) subagent/)
  const agent = session.agent ?? tag?.[1]
  const task = tag ? raw.replace(tag[0], "").trim() || raw : raw
  if (!agent) return task
  const name = agent.split("-").map((word) => word.charAt(0).toUpperCase() + word.slice(1)).join("-")
  return `${name}: ${task}`
}

/** The part of a shell command worth showing: its last line, without a leading `cd <dir> &&`. */
function command(text: string) {
  const line = text.split("\n").findLast((item) => item.trim() !== "")?.trim() ?? text
  return line.replace(/^cd\s+\S+\s*(&&|;)\s*/, "") || line
}

function elapsed(milliseconds: number) {
  const seconds = Math.max(0, Math.floor(milliseconds / 1000))
  if (seconds < 60) return `${seconds}s`
  const minutes = Math.floor(seconds / 60)
  if (minutes < 60) return `${minutes}m`
  return `${Math.floor(minutes / 60)}h${String(minutes % 60).padStart(2, "0")}m`
}
