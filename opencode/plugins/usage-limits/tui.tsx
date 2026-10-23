/** @jsxImportSource @opentui/solid */
import { Plugin, usePlugin } from "@opencode/plugin/tui"
import { createSignal, For, Show } from "solid-js"
import { UsageLimits, type Account, type Snapshot, type Window } from "./rpc"

/** Matches the server's cache TTL; polling faster would only return the cached snapshot. */
const POLL = 60_000
const BAR = 10
/** Widest countdown, e.g. "23h59m". */
const RESET = 6

export default Plugin.define({
  id: "usage-limits.sidebar",
  setup(context) {
    const [snapshot, setSnapshot] = createSignal<Snapshot>()
    const [error, setError] = createSignal<string>()
    const [now, setNow] = createSignal(Date.now())
    const rpc = context.client.rpc(UsageLimits)

    async function refresh() {
      try {
        setSnapshot((await rpc.get({})) as Snapshot)
        setError(undefined)
      } catch (cause) {
        setError(cause instanceof Error ? cause.message : String(cause))
      }
    }

    void refresh()
    const poll = setInterval(() => void refresh(), POLL)
    const tick = setInterval(() => setNow(Date.now()), 30_000)

    const unslot = context.ui.slot({
      append: "sidebar.content",
      render: () => <Usage snapshot={snapshot()} error={error()} now={now()} />,
    })

    return () => {
      clearInterval(poll)
      clearInterval(tick)
      unslot()
    }
  },
})

function Usage(props: { snapshot?: Snapshot; error?: string; now: number }) {
  const { theme } = usePlugin()
  // Align bars across accounts.
  const width = () =>
    Math.max(0, ...(props.snapshot?.accounts ?? []).flatMap((account) => account.windows.map((window) => window.label.length)))
  return (
    <box flexDirection="column" width="100%">
      <text fg={theme.text.base}>
        <b>Usage</b>
      </text>
      <Show when={props.error}>
        <text fg={theme.text.feedback.error.base}>{props.error}</text>
      </Show>
      <Show when={!props.snapshot && !props.error}>
        <text fg={theme.text.muted}>Loading…</text>
      </Show>
      <box flexDirection="column" width="100%" gap={1}>
        <For each={props.snapshot?.accounts}>
          {(account) => <AccountUsage account={account} width={width()} now={props.now} />}
        </For>
      </box>
    </box>
  )
}

function AccountUsage(props: { account: Account; width: number; now: number }) {
  const { theme } = usePlugin()
  return (
    <box flexDirection="column" width="100%">
      <box flexDirection="row" width="100%" justifyContent="space-between" gap={1}>
        <box flexDirection="row" gap={1}>
          <text fg={theme.text.muted}>{props.account.name}</text>
          <Show when={props.account.plan}>
            <text fg={theme.text.faint}>{props.account.plan}</text>
          </Show>
          <Show when={props.account.error}>
            <text fg={theme.text.feedback.error.base}>{props.account.error}</text>
          </Show>
        </box>
        <Show when={props.account.rateLimited}>
          <text fg={theme.text.faint}>{age(props.now - props.account.fetchedAt)}</text>
        </Show>
      </box>
      <For each={props.account.windows}>
        {(window) => <WindowUsage window={window} width={props.width} now={props.now} />}
      </For>
    </box>
  )
}

function WindowUsage(props: { window: Window; width: number; now: number }) {
  const { theme } = usePlugin()
  // The bar takes whatever the sidebar leaves after the label and numbers.
  const [bar, setBar] = createSignal(BAR)
  const left = () => 100 - Math.min(100, Math.max(0, props.window.usedPercent))
  const filled = () => Math.round((left() / 100) * bar())
  const color = () =>
    left() <= 10 ? theme.text.feedback.error.base
    : left() <= 25 ? theme.text.feedback.warning.base
    : theme.text.feedback.success.base
  const reset = () => (props.window.resetsAt ? countdown(props.window.resetsAt - props.now) : "")
  // Empty text nodes still take a column, so only render the parts that have content.
  return (
    <box flexDirection="column" width="100%" paddingLeft={1}>
      <Show when={props.window.scope}>
        <text fg={theme.text.faint}>{props.window.scope}</text>
      </Show>
      <box flexDirection="row" width="100%">
        <text fg={theme.text.muted}>{props.window.label.padEnd(props.width) + " "}</text>
        <box
          flexDirection="row"
          flexGrow={1}
          flexShrink={1}
          minWidth={0}
          overflow="hidden"
          onSizeChange={function () {
            if (this.width > 0) setBar(this.width)
          }}
        >
          <Show when={filled() > 0}>
            <text fg={color()} flexShrink={0}>
              {"▰".repeat(filled())}
            </text>
          </Show>
          <Show when={filled() < bar()}>
            <text fg={theme.text.faint} flexShrink={0}>
              {"▱".repeat(bar() - filled())}
            </text>
          </Show>
        </box>
        <text fg={theme.text.base}>{" " + `${Math.round(left())}%`.padStart(4)}</text>
        <text fg={theme.text.faint}>{" " + reset().padStart(RESET)}</text>
      </box>
    </box>
  )
}

/** How long ago a rate-limited account's numbers were fetched. */
function age(milliseconds: number) {
  const minutes = Math.max(0, Math.floor(milliseconds / 60_000))
  if (minutes < 60) return `${minutes}m`
  return `${Math.floor(minutes / 60)}h${String(minutes % 60).padStart(2, "0")}m`
}

function countdown(milliseconds: number) {
  if (milliseconds <= 0) return "now"
  const minutes = Math.ceil(milliseconds / 60_000)
  if (minutes < 60) return `${minutes}m`
  const hours = Math.floor(minutes / 60)
  if (hours < 24) return `${hours}h${String(minutes % 60).padStart(2, "0")}m`
  return `${Math.floor(hours / 24)}d${hours % 24}h`
}
