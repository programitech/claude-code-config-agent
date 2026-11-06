# Memory: CLAUDE.md, rules, auto memory

Verified against https://code.claude.com/docs/en/memory.md for Claude Code 2.1.284 on 2026-11-06.

## Files and load order (broad to specific)

| File | Scope | Shared? |
|---|---|---|
| macOS `/Library/Application Support/ClaudeCode/CLAUDE.md`, Linux `/etc/claude-code/CLAUDE.md`, Windows `C:\Program Files\ClaudeCode\CLAUDE.md` | Managed policy | Org (IT) |
| `~/.claude/CLAUDE.md` | User, all projects | No |
| `~/.claude/rules/**/*.md` | User rules | No |
| `./CLAUDE.md` or `./.claude/CLAUDE.md` | Project | Yes (commit) |
| `./.claude/rules/**/*.md` | Project rules | Yes |
| `./CLAUDE.local.md` | Personal project notes, appended after CLAUDE.md in the same dir | No (gitignore it) |

- CLAUDE.md files in the working directory and every ancestor load at launch, root first.
- CLAUDE.md files in subdirectories load lazily when Claude reads/writes/edits a file there.
- `AGENTS.md` is read only when no CLAUDE.md/CLAUDE.local.md exists in cwd or above (2.1.277+). To reuse an existing AGENTS.md, create CLAUDE.md containing `@AGENTS.md`.
- CLAUDE.md is delivered as a user message and is advisory. Guaranteed behavior needs hooks or permissions.
- Block-level HTML comments (`<!-- ... -->`) are stripped before injection: use them for maintainer notes at zero token cost.
- Files over 4 MiB are skipped. Lazily loaded files are capped per file (40,000 chars at a 200K window).

## Imports

- `@path/to/file` anywhere in a memory file. Relative paths resolve from the importing file. `~/` works.
- Max depth: four hops. Code spans and fenced blocks are skipped. Quoted paths are not imported. Escape spaces with `\ `.
- Imports outside the project need one-time approval.
- Imports do NOT reduce cost: imported files load at launch with their parent. Use them for organization or to share a personal file (`@~/.claude/my-project-notes.md`), not to save tokens.

## Rules (`.claude/rules/`)

- Any `.md` under `.claude/rules/` (recursive). Only frontmatter key read: `paths`.
- No `paths` → loads at launch with the same priority as `.claude/CLAUDE.md`.
- With `paths` → loads when Claude reads/writes/edits a matching file. Brace expansion works. YAML list or comma string.

```markdown
---
paths:
  - "src/api/**/*.ts"
  - "src/**/*.{test,spec}.ts"
---
# API rules
- Validate input with zod at the handler boundary.
```

- Ideal for language/framework/module conventions that only matter for some files.

## Auto memory

- Claude writes notes for itself in `~/.claude/projects/<project>/memory/`. The project key comes from the git repo, so worktrees share it. `CLAUDE_CODE_PROJECT_DIR_NAME` overrides the key.
- `MEMORY.md` is the index: first 200 lines or 25 KB load every session. Topic files load on demand.
- Settings: `"autoMemoryEnabled": false` to disable (the `/memory` toggle writes this to user settings). `"autoMemoryDirectory": "~/notes/claude"` to relocate (absolute or `~/`).
- Env: `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1` disables, `0` forces on.
- Keep MEMORY.md one line per entry pointing at topic files.

## Agent memory

Subagents can persist their own notes with `memory:` frontmatter: `user` → `~/.claude/agent-memory/<name>/`, `project` → `.claude/agent-memory/<name>/` (commit to share), `local` → `.claude/agent-memory-local/<name>/` (gitignore). Its MEMORY.md is injected into that agent only.

## `claudeMdExcludes`

Settings array of absolute-path globs for CLAUDE.md files to skip (e.g. other teams' files in a monorepo). Arrays merge across settings layers. Managed CLAUDE.md cannot be excluded.

```json
{ "claudeMdExcludes": ["/abs/path/monorepo/legacy/**/CLAUDE.md"] }
```

## Writing a CLAUDE.md that earns its tokens

Include (only what Claude can't infer quickly from the code):
- Exact commands: install, dev, build, test (single test too), lint, typecheck, format.
- A 5-10 line architecture map: where things live, entry points, data flow.
- Conventions that differ from defaults or that Claude got wrong before.
- Gotchas: env setup, generated files not to edit, flaky tests, required services.
- Workflow: branch naming, commit style, PR checklist, what "done" means.
- A `# Compact instructions` section (what summaries must keep).

Exclude:
- Things obvious from code or config (framework names, folder listings).
- Long docs, API references, style guides → link to the file or put it in a skill.
- Generic advice ("write clean code", "be careful").
- Secrets, URLs with tokens, frequently changing data.
- Duplicates of rules/skills content.

Style: imperative bullets, specific ("Use pnpm, not npm"), group under short headings, emphasis (`IMPORTANT`, `NEVER`) only for the 1-3 rules that truly must hold.

Placement:
- Applies to every task in this repo → project CLAUDE.md.
- Applies to some file types/dirs → `.claude/rules/x.md` with `paths:`.
- Applies to one module → that module's `CLAUDE.md`.
- A procedure run sometimes → a skill.
- Personal preference across projects → `~/.claude/CLAUDE.md`.
- Personal, this repo only → `CLAUDE.local.md`.
- Must never be violated → hook or permission deny rule (memory is advisory).

## Commands

`/memory` (list files, toggle auto memory, open folder), `/context all`, `/init` (draft CLAUDE.md; `CLAUDE_CODE_NEW_INIT=1` for the interactive flow), `/doctor prompt-audit` (2.1.283+).
