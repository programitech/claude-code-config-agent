# Subagents

Verified against https://code.claude.com/docs/en/sub-agents.md and plugins/components.md for Claude Code 2.1.284 on 2026-11-06.

A subagent runs in its own context window with its own prompt, tools, and model. Only its final message returns to the caller. Use them to isolate verbose work, specialize behavior, and route work to cheaper models.

## Locations (priority high → low)

Managed > `--agents` CLI JSON > `.claude/agents/` (project, recursive) > `~/.claude/agents/` (user) > plugin `agents/`. Same name: higher priority wins. List with `claude agents` or `/agents`.

## Frontmatter

| Field | Notes |
|---|---|
| `name` | Required. Lowercase + hyphens. No `:` |
| `description` | Required. Drives auto-delegation. Loaded every session |
| `tools` | Allowlist (comma string or YAML list). Omit = inherit all tools (incl. MCP) |
| `disallowedTools` | Denylist, applied first |
| `model` | `haiku`, `sonnet`, `opus`, `fable`, full ID, or `inherit`. Omit → `CLAUDE_CODE_SUBAGENT_MODEL` → main model |
| `effort` | `low`..`max` |
| `maxTurns` | Cap on agentic turns (cost guard) |
| `autoCompactWindow` | 100000-1000000 |
| `skills` | Skills preloaded into the agent's context at start (max 32). Skills with `disable-model-invocation: true` can't be preloaded |
| `memory` | `user`, `project`, `local`: persistent notes dir, its MEMORY.md injected into this agent |
| `background` | bool: run in background by default |
| `isolation` | `worktree`: run in a temporary git worktree |
| `omitClaudeMd` | bool (2.1.271+): skip CLAUDE.md for this agent (saves tokens for agents that don't need project rules) |
| `color` | `red`, `blue`, `green`, `yellow`, `purple`, `orange`, `pink`, `cyan` |
| `permissionMode`, `hooks`, `mcpServers`, `initialPrompt` | Supported in project/user agents. Ignored in plugin agents |
| `experimental.cacheTtl` | `5m` or `1h` |

Unknown fields are ignored silently: validate spelling.

Built-ins: `Explore` (read-only search), `Plan` (read-only planning), `general-purpose` (all tools), `claude-code-guide`, `statusline-setup`. Don't recreate these.

## What a subagent starts with

- Its own body as system prompt (+ environment details), NOT the Claude Code system prompt. The body must be self-contained.
- The delegation message, the CLAUDE.md hierarchy (unless `omitClaudeMd`), a git status snapshot, preloaded `skills`. No conversation history, no output style, no main auto memory.
- Path-scoped rules and subdirectory CLAUDE.md still load when it touches matching files, even with `omitClaudeMd`.
- It can still invoke skills through the Skill tool, and spawn subagents up to 3 layers deep (`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`, `1` disables). Omit `Agent` from `tools` to stop it.
- Subagents spawned from the main conversation start in the background by default. `maxTurns` stops it with partial output that can be resumed.
- Its context window comes from its own model.

## Writing the description (it costs tokens every session)

- 1-3 sentences, under ~400 chars: what it does + when to use it. Add "Use proactively after X" only if auto-delegation is wanted.
- No `<example>` blocks: they can cost 300+ tokens each, every session.
- Distinct trigger words, so it doesn't compete with other agents.

## Writing the body (system prompt; costs tokens only when the agent runs)

- Role in one line, then: inputs it should expect, step-by-step process, constraints, output format.
- Specify a compact output format (the caller pays for whatever is returned): e.g. "Return at most 15 bullets: file:line, issue, fix".
- Tell it what NOT to do (scope creep, editing when asked to review).
- 30-120 lines is typical. Move long reference material into a skill listed in `skills:` or a file it reads on demand.

## Choosing tools and model (least privilege + cheapest capable model)

| Archetype | tools | model |
|---|---|---|
| Reviewer / auditor (read-only) | `Read, Grep, Glob, Bash` (or no Bash) | `sonnet` |
| Searcher / log digger / test runner | `Read, Grep, Glob, Bash` | `haiku` |
| Implementer | `Read, Edit, Write, Grep, Glob, Bash` | `inherit` or `sonnet` |
| Researcher | `Read, Grep, Glob, WebFetch, WebSearch` | `sonnet` |
| Architect / hard debugging | read tools + Bash | `opus` / `inherit` |

- Don't grant `Write`/`Edit` to reviewers. Don't grant `WebFetch` unless needed (prompt-injection surface).
- Set `maxTurns` (e.g. 20-40) on agents that loop over many files.
- `omitClaudeMd: true` for generic utility agents that don't need project conventions.
- `memory: project` for agents that should learn across sessions (reviewers learning project patterns). Commit `.claude/agent-memory/` if the team should share it.

## When NOT to create an agent

- A short reusable prompt with no isolation need → skill.
- Something that must always happen → hook.
- A one-off task → just ask, or use built-in `general-purpose`/`Explore`.
- More than ~8 custom agents usually means overlap: merge.

## Template

`cc-config template agent` (or `--to .claude/agents/<name>.md`).
