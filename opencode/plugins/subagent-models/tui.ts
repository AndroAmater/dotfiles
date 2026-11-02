import { Plugin } from "@opencode/plugin/tui"
import type { OptimizedBuffer, Renderable } from "@opentui/core"

// Shows each subagent's model and thinking variant in the composer's subagent
// picker. The picker has no slot, so like step-timestamps this draws over the
// finished frame. It recognises picker rows by their shape (a row box holding
// a box with one `<prefix><Agent>: <title>` text), which is not public API: if
// the host changes it, the labels silently stop appearing.

type Json = Record<string, any>

export default Plugin.define({
  id: "subagent-models",
  setup(context) {
    const location = context.location ?? context.data.location.default()
    void context.data.location.model.sync(location).catch(() => {})

    function label(session: Json) {
      const model = session.model as Json | undefined
      if (!model?.id) return
      const models = (context.data.location.model.list(location) ?? []) as Json[]
      const name = models.find((item) => item.id === model.id && item.providerID === model.providerID)?.name ?? model.id
      return model.variant ? `${name} · ${model.variant}` : name
    }

    function draw(buffer: OptimizedBuffer) {
      const route = context.ui.router.current()
      if (route.type !== "session") return
      const family = context.data.session.family(route.sessionID) ?? []
      const sessions = family
        .map((id) => context.data.session.get(id) as Json | undefined)
        .filter((session): session is Json => !!session?.parentID)
      if (sessions.length === 0) return
      const picker = findPicker(context.renderer.root, sessions)
      if (!picker) return
      const viewport = picker.scrollbox.viewport
      const chars = buffer.buffers.char
      const theme = context.theme
      for (const { row, inner, session } of picker.rows) {
        if (row.y < viewport.y || row.y >= viewport.y + viewport.height) continue
        const text = label(session)
        if (!text) continue
        const selected = sameColor(row.backgroundColor, theme.background.action.primary.focused)
        const fg = selected ? theme.text.action.primary.focused : theme.text.muted
        // Keep a column free before the status text ("Running") that follows a running row.
        const end = inner.x + inner.width - (row.getChildren().length > 1 ? 1 : 0)
        const x = end - text.length
        // Leave the start of the row (tree prefix and agent) readable.
        if (x < inner.x + Math.min(inner.width, 16)) continue
        // Cut a title that runs into the label with an ellipsis instead of mixing them.
        let blank = true
        for (let column = x - 1; column < end && blank; column++) {
          const char = chars[row.y * buffer.width + column]
          blank = char === 32 || char === 0
        }
        const tail = blank ? " " : "… "
        buffer.drawText(tail + text, x - tail.length, row.y, fg)
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

type Row = { row: Renderable & Json; inner: Renderable; session: Json }
type Scrollbox = Renderable & { viewport: Renderable }

/** The scrollbox whose rows are subagent entries, with each row matched to its session. */
function findPicker(node: Renderable, sessions: Json[]): { scrollbox: Scrollbox; rows: Row[] } | undefined {
  if (!node.visible) return
  if (node.id.startsWith("scrollbox-") && "viewport" in node) {
    // Never descend: the transcript is a scrollbox too, and walking it every frame is expensive.
    const scrollbox = node as Scrollbox
    const rows = matchRows(scrollbox.getChildren() as Renderable[], sessions)
    return rows ? { scrollbox, rows } : undefined
  }
  for (const child of node.getChildren() as Renderable[]) {
    const found = findPicker(child, sessions)
    if (found) return found
  }
}

function matchRows(children: Renderable[], sessions: Json[]): Row[] | undefined {
  const rows: Row[] = []
  const used = new Set<string>()
  for (const row of children) {
    const inner = row.getChildren()[0] as Renderable | undefined
    const text = inner?.getChildren()[0] as (Renderable & { plainText?: string }) | undefined
    const content = text?.plainText
    if (!inner || typeof content !== "string") return
    const session = sessions.find((item) => !used.has(item.id) && content.endsWith(`: ${shownTitle(item)}`))
    // Every row must be a subagent, otherwise this is some other list.
    if (!session) return
    used.add(session.id)
    rows.push({ row: row as Renderable & Json, inner, session })
  }
  return rows.length > 0 ? rows : undefined
}

/** The title as the picker shows it, without a leading `@agent subagent` tag. */
function shownTitle(session: Json) {
  const title = String(session.title ?? "")
  const tag = title.match(/@(\w+) subagent/)
  return tag ? title.replace(tag[0], "").trim() || title : title
}

function sameColor(left: unknown, right: unknown) {
  if (left === right) return true
  const a = left as Json | undefined
  const b = right as Json | undefined
  if (!a || !b) return false
  return a.r === b.r && a.g === b.g && a.b === b.b && a.a === b.a
}
