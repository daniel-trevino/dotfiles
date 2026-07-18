---
name: work-brain
description: Use when reading, writing, or navigating the user's persistent knowledge base via the `work-brain` MCP server (tools like `mcp__work-brain__read_file`, `write_file`, `edit_file`, `list_files`, `grep`, `delete`, `mkdir`, `file_stat`). Covers directory structure, frontmatter conventions, naming rules, when to save knowledge, and how to update `log.md` and `_index.md`.
---

# Work Brain (Knowledge Base)

You have access to a persistent knowledge base via the `work-brain` MCP server. It's a filesystem graph of markdown files — folders are categories, files are nodes, links between files are edges. Use the MCP tools (`read_file`, `write_file`, `edit_file`, `list_files`, `grep`, `delete`, `mkdir`, `file_stat`) to read and write to it.

**Important:** Use `/` as root path, not `.` (S3 backend rejects `.`).

## Directory structure

| Path | Purpose |
|------|---------|
| `_index.md` | Root index — start here to navigate |
| `log.md` | Append-only changelog of all knowledge operations |
| `SOUL.md` | The agent identity (not relevant to you) |
| `me/` | About the user: profile, preferences, goals |
| `people/` | People the user works with |
| `projects/` | Active and past projects |
| `meetings/` | Meeting notes and summaries |
| `topics/` | Research topics and domain knowledge |
| `decisions/` | Important cross-project decisions |
| `integrations/` | Connected services and usage patterns |
| `activity/` | Daily work logs, one file per day at `activity/<year>/<month>/<day>.md` (zero-padded, e.g. `2026/06/12.md`): work done, Slack conversations, decisions, project progress, links to other brain docs. Format doc in `activity/_index.md` |
| `raw/` | Unprocessed content awaiting compilation |
| `plans/` | Implementation plans organized by project |

## How to use it

- **Read `_index.md` first** when you need to orient yourself in the knowledge base
- **Use `grep`** to search across files before creating new ones — avoid duplicates
- **Update over create** — if relevant info exists, edit the file rather than making a new one
- **Update `_index.md`** — always update the parent directory's `_index.md` when creating or modifying files
- **Cross-reference** — link related files bidirectionally (e.g., a person mentioned in a meeting should be linked from both the meeting file and the person file)

## Frontmatter

Every file (except `_index.md`) has YAML frontmatter:

```yaml
---
type: meeting | person | project | decision | topic | integration
visibility: private | team
tags: [lowercase-kebab-case]
date: YYYY-MM-DD  # for temporal content
participants: [kebab-case-names]  # matching people/ filenames
project: project-name  # matching projects/ directory
---
```

## When to save knowledge

- The user shares facts about themselves, their work, or preferences
- A decision is made and the rationale matters
- You learn about a project, person, or recurring task
- The user corrects you — save it so neither you nor the Slack agent repeats the mistake
- You produce a valuable synthesized answer worth persisting

## log.md

After significant writes, append to `log.md`:

```
## [YYYY-MM-DD HH:MM] operation | Title

One-line description.
Pages affected: [file1.md](./file1.md), [file2.md](./file2.md)
```

Operations: `ingest`, `update`, `create`, `query`, `lint`, `correction`.

## Naming conventions

- Files: `kebab-case.md`
- Activity: `activity/<year>/<month>/<day>.md`, zero-padded (`2026/06/12.md`); update the month's `_index.md` when adding a day
- Meetings: `YYYY-MM-DD-title.md`
- Decisions: `YYYY-MM-DD-topic.md`
- People: `firstname-lastname.md`
- Keep names consistent across files — same person, same project name, same tags everywhere
