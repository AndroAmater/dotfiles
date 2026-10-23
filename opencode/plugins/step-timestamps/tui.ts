import { Plugin } from "@opencode/plugin/tui"
import type { OptimizedBuffer, Renderable } from "@opentui/core"

// OpenCode has no slot inside the transcript, so this draws over the finished
// frame instead. It relies on the host's transcript row IDs (`msg_<id>` and
// `session-part:<messageID>:<key>`), which are not public API: if they change,
// timestamps silently stop appearing. Nothing in the host tree is modified.

type Json = Record<string, any>

export default Plugin.define({
  id: "step-timestamps",
  setup(context) {
    const synced = new Set<string>()

    function draw(buffer: OptimizedBuffer) {
      const route = context.ui.router.current()
      if (route.type !== "session") return
      const sessionID = route.sessionID
      if (!synced.has(sessionID)) {
        synced.add(sessionID)
        void context.data.session.message.sync(sessionID)
      }
      const pane = context.renderer.root.findDescendantById("session-pane")
      const scrollbox = pane && findScrollbox(pane)
      if (!scrollbox) return
      const viewport = scrollbox.viewport
      const top = viewport.y
      const bottom = viewport.y + viewport.height
      const today = new Date().toDateString()
      const fg = context.theme.text.faint
      const chars = buffer.buffers.char
      for (const row of scrollbox.getChildren() as Renderable[]) {
        const line = row.y + row.height
        if (line < top) continue
        if (row.y >= bottom) break
        if (line >= bottom || !row.visible) continue
        const time = rowTime(row.id, (id) => context.data.session.message.get(sessionID, id))
        if (time === undefined) continue
        const text = format(time, today)
        const x = row.x + row.width - text.length
        if (x < viewport.x) continue
        // Only draw into the blank gap below a step, never over content.
        let blank = true
        for (let column = x; column < x + text.length && blank; column++) {
          const char = chars[line * buffer.width + column]
          blank = char === 32 || char === 0
        }
        if (blank) buffer.drawText(text, x, line, fg)
      }
    }

    const process = (buffer: OptimizedBuffer) => {
      try {
        draw(buffer)
      } catch {
        // The host layout changed shape; skip this frame rather than break rendering.
      }
    }
    context.renderer.addPostProcessFn(process)
    context.renderer.requestRender()
    return () => {
      context.renderer.removePostProcessFn(process)
      context.renderer.requestRender()
    }
  },
})

function findScrollbox(node: Renderable): (Renderable & { viewport: Renderable }) | undefined {
  if (node.id.startsWith("scrollbox-") && "viewport" in node) return node as Renderable & { viewport: Renderable }
  for (const child of node.getChildren() as Renderable[]) {
    const found = findScrollbox(child)
    if (found) return found
  }
}

/** Completion time of the step a transcript row shows, or undefined while it is still running. */
function rowTime(rowID: string, message: (id: string) => unknown): number | undefined {
  const part = /^session-part:(msg_[^:]+):(.+)$/.exec(rowID)
  const messageID = part ? part[1]! : rowID.startsWith("msg_") ? rowID : undefined
  if (!messageID) return
  const info = message(messageID) as Json | undefined
  if (!info) return
  if (info.type !== "assistant") {
    if (info.type === "shell") return millis(info.time?.completed)
    if (info.type === "compaction" && info.status === "running") return
    return millis(info.time?.created)
  }
  const content = (info.content ?? []) as Json[]
  // A message's first item is rendered in the message row itself; later items get their own part rows.
  const item = part ? findItem(content, part[2]!) : content[0]
  if (item?.type === "tool" || item?.type === "reasoning") {
    const completed = millis(item.time?.completed)
    if (completed !== undefined || item.type === "tool") return completed
  }
  // Text has no time of its own; it is done once the response body ends.
  return millis(info.time?.streamed) ?? millis(info.time?.completed)
}

function findItem(content: Json[], key: string) {
  const tool = content.find((item) => item.type === "tool" && item.id === key)
  if (tool) return tool
  const [type, index] = key.split(":")
  return content.filter((item) => item.type === type)[Number(index)]
}

function millis(value: unknown): number | undefined {
  if (typeof value === "number") return value
  if (typeof value === "string") {
    const parsed = Date.parse(value)
    return Number.isNaN(parsed) ? undefined : parsed
  }
  if (value instanceof Date) return value.getTime()
  if (value && typeof value === "object" && "epochMilliseconds" in value) return Number(value.epochMilliseconds)
}

function format(time: number, today: string) {
  const date = new Date(time)
  const clock = [date.getHours(), date.getMinutes(), date.getSeconds()].map((n) => String(n).padStart(2, "0")).join(":")
  if (date.toDateString() === today) return clock
  return `${date.toLocaleDateString(undefined, { month: "short", day: "numeric" })} ${clock}`
}
