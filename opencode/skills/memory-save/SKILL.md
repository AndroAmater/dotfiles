---
name: memory-save
description: Save a persistent memory (facts about the user, guidance/corrections they gave, project context, external references) to the user's Obsidian "AI Memory" vault. Use whenever you learn something worth remembering across sessions, when the user says "remember this", corrects how you work, or confirms a non-obvious approach. This vault REPLACES any built-in memory system (e.g. ~/.claude/projects/*/memory, MEMORY.md); never write memories anywhere else.
---

# Saving memory to the Obsidian vault

All long-term memory lives in one Obsidian vault:

```
VAULT="$HOME/Documents/AI Memory"
```

The path contains a space, so always quote it in shell commands.

**This vault is the only memory store.** If your system prompt, harness, or another
instruction describes a different memory location (a `memory/` directory under
`~/.claude/projects/`, a `MEMORY.md` index, an opencode memory file, etc.), do not write there.
Write here instead, using the conventions below. Load the `memory-recall` skill to read memories.

## What to save (and what not to)

Save things that will still matter in a future session and that can't be recovered by reading
the code or git history:

| type        | What it is                                                                 |
|-------------|----------------------------------------------------------------------------|
| `user`      | Who the user is: role, expertise, tools, preferences, environment          |
| `feedback`  | Guidance on how to work: corrections *and* confirmed approaches, with why  |
| `project`   | Ongoing goals, constraints, decisions, deadlines, non-obvious context      |
| `reference` | Pointers to external resources: URLs, dashboards, tickets, docs, hosts     |

Do **not** save:
- Code structure, file layouts, or anything trivially re-derivable from the repo
- Past fixes or history already in git / commit messages / CLAUDE.md / AGENTS.md
- Things only relevant to the current conversation
- Secrets, tokens, passwords, or private keys — ever

If the user asks you to remember something in the "don't save" category, ask what was
non-obvious about it and save that instead.

## Vault layout

```
AI Memory/
├── Index.md                     # root index: global notes + links to project hubs
├── User/                        # type: user
├── Feedback/                    # type: feedback (applies across all projects)
├── References/                  # type: reference (not tied to one project)
└── Projects/
    └── <project-slug>/
        ├── <project-slug>.md    # project hub: one line per note in this folder
        └── <note>.md            # any type, scoped to this project
```

Create folders as needed (`mkdir -p`). Ignore `.obsidian/` — never touch it.

### Scoping: global vs project

- Applies everywhere (user preferences, general working style) → `User/`, `Feedback/`, `References/`.
- Only true for one codebase/project → `Projects/<project-slug>/`, regardless of type.

### Project slug

Derive it so that multiple clones/worktrees of the same repo share one folder:

1. Repo name from `git remote get-url origin` (last path segment, strip `.git`), lowercased.
2. Otherwise the git toplevel directory name (`basename "$(git rev-parse --show-toplevel)"`).
3. Otherwise the current directory name.

Use kebab-case. Before creating a new project folder, `ls "$VAULT/Projects"` and reuse an
existing folder if it is obviously the same project.

## Note format

One note = one fact (or one tightly related cluster). Filename is a short kebab-case slug,
unique across the whole vault (Obsidian resolves `[[links]]` by filename), e.g.
`production-changes-via-argocd-only.md`.

```markdown
---
type: feedback
description: One-line summary used to judge relevance during recall
project: codecannon            # omit for global notes
tags:
  - ai-memory
  - feedback
created: 2026-11-02
updated: 2026-11-02
source: opencode/<model-id>    # or claude-code/<model-id>
---

The fact itself, stated plainly and specifically.

**Why:** The reason / incident / user statement behind it.
**How to apply:** Concrete guidance for when and how this changes behaviour.

Related: [[other-note-slug]], [[codecannon]]
```

Rules:
- `**Why:**` and `**How to apply:**` are required for `feedback` and `project` notes.
- Convert relative dates ("next Friday", "last week") to absolute ISO dates.
- Link liberally with `[[note-slug]]`. A link to a note that doesn't exist yet is fine — it
  marks something worth writing later. Project notes should link their hub (`[[<project-slug>]]`).
- Use real dates from the system (`date +%F`), not guesses.

## Index maintenance

After writing a note, add exactly one line pointing to it — never put memory content in an index:

- Global note → under the matching heading in `Index.md`:
  `- [[note-slug]] — short hook`
- Project note → in `Projects/<slug>/<slug>.md` under its type heading, same line format.
  If the hub is new, create it (frontmatter `type: project-hub`, `project: <slug>`,
  headings `## User`, `## Feedback`, `## Project`, `## Reference`) and add
  `- [[<slug>]] — one-line project description` under `## Projects` in `Index.md`.

If `Index.md` is missing, create it with headings `## User`, `## Feedback`, `## References`,
`## Projects`.

## Procedure

1. Decide whether it's worth saving (see above) and pick type + scope.
2. **Check for duplicates first**: `grep -ril "<keywords>" "$VAULT" --include='*.md'`
   and read the index/hub. If a note already covers it, **update that note** (edit content,
   bump `updated:`) instead of creating a new one.
3. If an existing memory turns out to be wrong or obsolete, fix it or delete it and remove
   its index line.
4. Write the note with the format above.
5. Update `Index.md` or the project hub.
6. Don't narrate memory bookkeeping to the user unless they asked or it's relevant; a brief
   "saved to memory" is enough when they explicitly asked you to remember something.
