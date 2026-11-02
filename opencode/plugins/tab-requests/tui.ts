import { Plugin } from "@opencode/plugin/tui"
import { mkdir, readdir, readFile, realpath, rename, unlink } from "node:fs/promises"
import { homedir } from "node:os"
import { join } from "node:path"

// Lets scripts outside OpenCode open a session as a tab in a running TUI. A
// request is a file `<anything>.json` in the requests directory containing
// `{"directory": "/abs/path", "sessionID": "ses_..."}`. A TUI launched in that
// directory claims it, focuses the session's tab and deletes the file. Write the
// file under another name and rename it into place so it is never read half
// written.

const root = process.env.OPENCODE_TAB_REQUESTS_DIR ?? join(
  process.env.XDG_STATE_HOME ?? join(homedir(), ".local", "state"),
  "opencode-tab-requests",
)

export default Plugin.define({
  id: "tab-requests",
  async setup(context) {
    const directory = (context.location ?? context.data.location.default()).directory
    const own = await realpath(directory).catch(() => directory)
    await mkdir(root, { recursive: true })
    let scanning = false

    async function claim(name: string) {
      const file = join(root, name)
      let request: { directory?: unknown; sessionID?: unknown }
      try {
        request = JSON.parse(await readFile(file, "utf8"))
      } catch {
        return
      }
      if (typeof request.directory !== "string" || typeof request.sessionID !== "string") return
      const target = await realpath(request.directory).catch(() => request.directory)
      if (target !== own) return
      // Several TUIs can share a directory; only the one whose rename wins opens the tab.
      const claimed = `${file}.${process.pid}`
      try {
        await rename(file, claimed)
      } catch {
        return
      }
      await unlink(claimed).catch(() => {})
      await context.data.session.sync(request.sessionID).catch(() => {})
      if (!context.ui.tabs.focus(request.sessionID)) {
        context.ui.router.navigate({ type: "session", sessionID: request.sessionID })
      }
    }

    async function scan() {
      if (scanning) return
      scanning = true
      try {
        for (const name of await readdir(root)) {
          if (name.endsWith(".json")) await claim(name)
        }
      } catch {
        // A missing or unreadable directory just means there is nothing to open.
      } finally {
        scanning = false
      }
    }

    const timer = setInterval(() => void scan(), 1000)
    void scan()
    return () => clearInterval(timer)
  },
})
