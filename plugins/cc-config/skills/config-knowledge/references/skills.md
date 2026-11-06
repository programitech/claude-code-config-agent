# Skills and slash commands

Verified against https://code.claude.com/docs/en/skills.md and env-vars.md for Claude Code 2.1.284 on 2026-11-06.

A skill is a folder with `SKILL.md` (+ optional supporting files). Name + description sit in the skill listing every session; the body loads only when invoked; supporting files load only when read. `.claude/commands/x.md` still works and is merged with skills (`/x`), but new work should use skills.

## Locations

`~/.claude/skills/<name>/SKILL.md` (user), `.claude/skills/<name>/SKILL.md` (project), plugin `skills/<name>/SKILL.md` (as `/<plugin>:<name>`).

## Frontmatter

| Field | Notes |
|---|---|
| `name` | Default = folder name. Lowercase, digits, hyphens, max 64 |
| `description` | What it does + when to use. Listing truncates `description`+`when_to_use` at 1,536 chars. Aim under ~300 |
| `when_to_use` | Extra trigger text (counts toward the cap) |
| `argument-hint` | e.g. `[issue-number]` shown in the `/` menu |
| `arguments` | Named args usable as `$name` |
| `disable-model-invocation` | `true` = only the user can run it (`/name`). Removed from the listing: zero tokens until invoked. Can't be preloaded into subagents |
| `user-invocable` | `false` = hidden from `/` menu; Claude-only background knowledge |
| `allowed-tools` | Pre-approved for the skill's turn (not a restriction) |
| `disallowed-tools` | Removed from the tool pool while the skill is active |
| `model`, `effort` | Override for the skill's turn |
| `context: fork` + `agent: <type>` | Run in a subagent (default `general-purpose`); only the result returns. `background` (bool) controls blocking |
| `hooks` | Registered while the skill runs |
| `paths` | Globs limiting auto-activation to matching files |
| `shell` | `bash` (default) or `powershell` for `!` commands |

## Invocation matrix

| Use case | Settings |
|---|---|
| Side effects (deploy, commit, release, send) or manual workflows | `disable-model-invocation: true` |
| Background knowledge Claude should pull in itself | `user-invocable: false` |
| Both can trigger | omit both |
| Heavy/verbose procedure whose output should not flood the chat | `context: fork` (+ `agent:` a fitting subagent) |

## Substitutions and dynamic context

- `$ARGUMENTS`, `$ARGUMENTS[N]` / `$N`, `$name`; `${CLAUDE_SKILL_DIR}` (the skill's folder), `${CLAUDE_SESSION_ID}`, `${CLAUDE_EFFORT}`, `${CLAUDE_PROJECT_DIR}`; plugin skills also `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PLUGIN_DATA}`. Escape a literal `$` as `\$`.
- Inline `` !`git status --short` `` (at line start or after whitespace) or a ```` ```! ```` block runs before the prompt is sent and inlines the output. Non-zero exit aborts the skill unless `|| true`. Keep output small (it becomes tokens). `"disableSkillShellExecution": true` in settings disables this.

## Structure for token efficiency

```
my-skill/
├── SKILL.md          # < 500 lines; the procedure + links
├── reference.md      # loaded only if SKILL.md tells Claude to read it
├── templates/...     # copied/filled by the procedure
└── scripts/x.py      # executed, not read: output only enters context
```

- Put deterministic work in scripts: running a script costs only its output, reading code costs every line.
- Link supporting files with relative markdown links and say when to read each.
- After compaction, invoked skill bodies are kept (5k tokens each, 25k total): front-load the essentials.

## Writing a good skill

1. Description: third person, concrete triggers ("Use when the user asks to X, Y, or mentions Z"). No marketing.
2. Body: goal, inputs (`$ARGUMENTS`), numbered steps, verification step, output format.
3. One skill = one job. Split when a body covers unrelated flows.
4. Test: invoke it with `/name args` and check it triggers automatically when it should (or not, if user-only).
5. For complex skills, Anthropic's `skill-creator` plugin can run evals; `claude plugin eval` runs suites for plugins.

## Template

`cc-config template skill` (or `--to .claude/skills/<name>/SKILL.md`).
