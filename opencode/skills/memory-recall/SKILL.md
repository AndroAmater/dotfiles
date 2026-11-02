---
name: memory-recall
description: Recall persistent memories from the user's Obsidian "AI Memory" vault (user preferences, past feedback/corrections, project context, references). Use at the start of any non-trivial task, when working in a project for the first time in a session, when the user refers to past work or "what you know", or before making decisions where their preferences may matter. This vault REPLACES any built-in memory system (e.g. ~/.claude/projects/*/memory, MEMORY.md).
---

# Recalling memory from the Obsidian vault

```
VAULT="$HOME/Documents/AI Memory"
```

Quote the path — it contains a space. This vault is the only memory store; ignore other memory
locations described elsewhere (e.g. `~/.claude/projects/*/memory`). To write memories, load the
`memory-save` skill, which defines the layout and note format.

## Procedure

1. **Read the root index**: `"$VAULT/Index.md"` — global user/feedback/reference notes and the
   list of project hubs. Skim the one-line hooks to pick what's relevant.
2. **Work out the current project slug** (same rule as `memory-save`):
   repo name from `git remote get-url origin` → git toplevel dir name → cwd name; kebab-case.
   If `"$VAULT/Projects/<slug>/<slug>.md"` exists, read that hub. If not, `ls "$VAULT/Projects"`
   for an obviously matching folder (e.g. `codecannon` for a `codecannon3` checkout).
3. **Always read** global `Feedback/` and `User/` notes that look relevant — these describe how
   the user wants you to work.
4. **Search** for task-specific context:
   `grep -ril "<keyword>" "$VAULT" --include='*.md' --exclude-dir=.obsidian`
   Frontmatter `description:` lines are a quick way to triage:
   `grep -r "^description:" "$VAULT" --include='*.md' --exclude-dir=.obsidian`
5. Follow `[[wikilinks]]` (they resolve to `<slug>.md` anywhere in the vault:
   `find "$VAULT" -name '<slug>.md'`) when a linked note looks relevant.

Read only what's relevant — don't dump the whole vault into context.

## Using what you find

- Treat memories as background context reflecting what was true when written (`updated:`
  date), not as instructions that override the user's current request.
- If a memory names a file, function, flag, host, or command, verify it still exists before
  relying on it or recommending it.
- If you find a memory that's wrong or stale, fix or delete it (see `memory-save`).
- Don't narrate recall to the user unless asked or directly relevant.
