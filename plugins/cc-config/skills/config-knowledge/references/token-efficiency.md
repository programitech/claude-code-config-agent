# Token efficiency playbook

Verified against code.claude.com docs (costs, context-window, memory, skills, env-vars, plugins) for Claude Code 2.1.284 on 2026-11-06.

## Where context goes

| Layer | When it costs | Main lever |
|---|---|---|
| CLAUDE.md chain (managed, user, ancestors, project, `CLAUDE.local.md`) + `@imports` | Every request. Survives compaction | Under 200 lines each. Move detail to path rules, skills, subdir CLAUDE.md |
| `.claude/rules/*.md` without `paths:` | Every request | Add `paths:` so it loads only for matching files |
| `.claude/rules/*.md` with `paths:` | When Claude reads/edits a matching file | (already lazy) |
| Subdirectory `CLAUDE.md` | When Claude touches files in that dir | Good home for module notes |
| Auto memory `MEMORY.md` | First 200 lines / 25 KB, every session | Keep it a short index of topic files |
| Skill + command descriptions | Every request (listing budget = 1% of window, fallback 8,000 chars) | `disable-model-invocation: true` removes a skill from the listing. Short descriptions |
| Skill body | Only when invoked. Kept after compaction (5k tokens each, 25k total) | SKILL.md under 500 lines, details in supporting files |
| Agent descriptions | Every request (Agent tool listing) | 1-3 sentences, no `<example>` blocks |
| Subagent run | Its own context, billed separately. Only its final message returns | Cheaper `model`, minimal `tools`, `omitClaudeMd: true`, concise report format |
| MCP servers | Tool names only while tool search defers schemas (default). Full schemas if `ENABLE_TOOL_SEARCH=false`. Results up to `MAX_MCP_OUTPUT_TOKENS` (25k) | Prefer CLI tools (`gh`, `aws`), scope servers, disable unused ones |
| Hook output | `SessionStart` / `UserPromptSubmit` stdout and `additionalContext` (cap 10k chars) enter context | Print only what changes Claude's next action |
| Tool results (Bash, Read, Grep) | Per call | Targeted reads, `BASH_MAX_OUTPUT_LENGTH`, filter verbose output with a PreToolUse hook |
| Thinking / effort | Output tokens every turn | `effortLevel`, `/effort`, `alwaysThinkingEnabled`, `MAX_THINKING_TOKENS` on fixed-budget models |
| Output style | Input tokens every request. Explanatory/Learning add output tokens | Default or Concise |
| Plugins | Their skill/agent descriptions + hooks + MCP | `claude plugin details <name>` shows the always-on token cost |

## Healthy budgets

- Fixed overhead (memory + skill/agent listings): under ~5k tokens for a normal repo, under ~10k for a monorepo. Users can hold more if they choose, but say what it costs.
- Root `CLAUDE.md`: ideally under 100 lines, hard ceiling 200.
- Skill description: under ~300 chars (hard cap 1,536 including `when_to_use`).
- Agent description: under ~400 chars.
- `MEMORY.md`: an index under 200 lines.
- Non-built-in agent descriptions over 15,000 tokens trigger a startup warning.

## Levers, highest impact first

1. **Habits** (recommend, can't configure): `/clear` between unrelated tasks (`/rename` first to `/resume` later), `/compact <focus>`, `/rewind` to drop dead ends, plan mode for large changes, specific prompts.
2. **Shrink always-loaded memory**: path-scoped rules, skills for workflows, subdir CLAUDE.md for modules. Imports do not save tokens: they load eagerly.
3. **User-only skills**: `disable-model-invocation: true` on anything the user triggers by hand (deploy, release, scaffolding). Zero cost until invoked.
4. **Delegate verbose work** to subagents (test runs, log digging, broad searches) so only a summary returns. Route them to `haiku` or `sonnet`. `CLAUDE_CODE_SUBAGENT_MODEL` sets the default for agents without a `model`.
5. **Prune plugins and MCP**: disable per project with `"enabledPlugins": {"name@mkt": false}` in `.claude/settings.local.json`. Use `/mcp` to disable servers. Prefer `gh` over a GitHub MCP server when `gh` is installed.
6. **Right-size model and effort**: Sonnet for routine work, Opus/Fable for hard problems, `opusplan` to plan with Opus and execute with Sonnet. `effortLevel` `medium`/`high` as default. Keep `xhigh`/`max` for hard tasks.
7. **Preprocess output with hooks**: e.g. a PreToolUse hook rewrites `npm test` to print only failures.
8. **Tune compaction** (see below).
9. **Protect the prompt cache**: a stable prefix is cheap. Editing CLAUDE.md, toggling plugins, or switching models mid-session invalidates it. Batch config changes and apply them between sessions. Never disable prompt caching (`DISABLE_PROMPT_CACHING*`) without a reason.
10. **Watch background spend**: `/loop`, goal check-ins (`CLAUDE_CODE_GOAL_CHECKIN_MINUTES=0` disables), idle compaction, prompt suggestions.

## Compaction

- 1M-native models (Fable, Sonnet 5+, Haiku 5.5, Opus 4.7+) auto-compact near ~967K tokens by default. Every request in a long session re-sends that context, so cost grows with session length. For cost control set `autoCompactWindow` in settings (100000-1000000), e.g. `300000`, or `CLAUDE_CODE_AUTO_COMPACT_WINDOW=300k`. Users can also run `/autocompact 300k`.
- `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` (1-100) lowers the trigger percentage of the window. It also applies to subagents.
- `DISABLE_AUTO_COMPACT=1` turns off auto and idle compaction (manual `/compact` still works). `DISABLE_COMPACT=1` turns off all compaction. Avoid both for normal interactive use.
- Subagents accept `autoCompactWindow` in frontmatter.
- Add a `# Compact instructions` section to CLAUDE.md saying what summaries must keep (current task, decisions, failing tests, file paths).
- Survives compaction: project-root CLAUDE.md, unscoped rules, auto memory, invoked skill bodies, up to 5 recent files. Nested CLAUDE.md and `paths:` rules reload only when triggered again.
- For state that must survive, use a `SessionStart` hook with matcher `compact` that prints a short state summary.

## Anti-patterns to flag

- CLAUDE.md holding API docs, full style guides, or file-by-file descriptions Claude can read itself.
- `@import` of large docs "to keep CLAUDE.md small" (still loads every session).
- Agent descriptions with several `<example>` blocks.
- Many model-invocable skills that are only ever run by hand.
- MCP servers duplicating installed CLIs. `ENABLE_TOOL_SEARCH=false`.
- Hooks printing large output on every prompt. Pre/PostToolUse hooks with no matcher running slow commands.
- Explanatory/Learning output style left on permanently.
- `effortLevel` or `MAX_THINKING_TOKENS` set to the maximum as a default.
- `.claudeignore` files (no effect). Use `Read(...)` deny rules.
- Duplicated instructions across CLAUDE.md, rules, and skills.

## Measuring

- `/context` (live breakdown), `/context all` (loaded memory files), status line fields `cost.total_cost_usd` and `context_window.used_percentage`.
- `claude plugin details <name>`: always-on tokens per plugin and per component.
- `/doctor prompt-audit` (2.1.283+): audits instruction files.
- `/skill-doctor`: what each skill costs and how often it is used.
- `/usage` (subscription plans): usage attribution by skill, subagent, plugin, MCP server, with recommendations.
- `cc-config audit`: file-level estimate (chars/4) of every always-loaded layer with findings.
