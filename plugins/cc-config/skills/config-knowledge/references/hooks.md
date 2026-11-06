# Hooks

Verified against https://code.claude.com/docs/en/hooks.md, hooks-guide.md and costs.md for Claude Code 2.1.284 on 2026-11-06.

Hooks are deterministic: the harness runs them, not Claude. Use them for rules that must always hold (memory is advisory) and to keep noise out of context.

## Shape

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/format.sh", "timeout": 60 }
        ]
      }
    ]
  }
}
```

Lives in any settings file, a plugin's `hooks/hooks.json` (same wrapper), or skill/agent frontmatter `hooks:` (not for plugin agents). Check with `/hooks`. Debug with `claude --debug-file ./debug.txt`.

## Events

SessionStart, Setup, UserPromptSubmit, UserPromptExpansion, PreToolUse, PermissionRequest, PermissionDenied, PostToolUse, PostToolUseFailure, PostToolBatch, Notification, MessageDisplay, SubagentStart, SubagentStop, TaskCreated, TaskCompleted, Stop, StopFailure, TeammateIdle, InstructionsLoaded, ConfigChange, CwdChanged, DirectoryAdded, FileChanged, WorktreeCreate, WorktreeRemove, PreCompact, PostCompact, PreModelSwitch, PostModelSwitch, Elicitation, ElicitationResult, SessionEnd.

## Matchers

- Tool events (PreToolUse, PostToolUse, PostToolUseFailure, PermissionRequest, PermissionDenied) match tool names: `Bash`, `Edit|Write`, `mcp__github__.*`.
- SessionStart: `startup|resume|clear|compact|fork`. SessionEnd: `clear|resume|logout|prompt_input_exit|other`. PreCompact/PostCompact: `manual|auto`.
- No matcher support: UserPromptSubmit, Stop, PostToolBatch, TeammateIdle, TaskCreated, TaskCompleted, WorktreeCreate, WorktreeRemove, MessageDisplay, CwdChanged.
- `*`, empty, or omitted = all. Letters/digits/`_`/`-`/space/`,`/`|` = exact names. Any other character = regex.
- Optional `if` (permission-rule syntax, tool events only), e.g. `"if": "Bash(git commit *)"`.

## Handler types

| Type | Fields | Default timeout |
|---|---|---|
| `command` | `command`, `args`, `async`, `asyncRewake`, `shell`, `onFailure` | 600s (30s on UserPromptSubmit) |
| `http` | `url`, `headers`, `allowedEnvVars` | 600s |
| `mcp_tool` | `server`, `tool`, `input` | 600s |
| `prompt` | `prompt` (`$ARGUMENTS` = input JSON), `model` | 30s |
| `agent` | experimental | 60s |

`prompt`/`agent` hooks call a model on every trigger: they cost tokens. Prefer `command` hooks.

## Input / output

- stdin JSON: `session_id`, `transcript_path`, `cwd`, `permission_mode`, `hook_event_name`, `effort`, `agent_id`/`agent_type` (in subagents). PreToolUse: `tool_name`, `tool_input`, `tool_use_id`. PostToolUse adds `tool_response`. SessionStart: `source`. Stop/SubagentStop: `stop_hook_active` (guard against loops).
- Exit 0: success. Stdout parsed as JSON if it is one object. Plain stdout becomes context for SessionStart/UserPromptSubmit (token cost every time).
- Exit 2: blocking error, stderr goes to Claude (PermissionRequest ignores 2). Other codes: non-blocking. `"onFailure": "block"` blocks on failure/timeout.
- JSON fields: `continue`, `stopReason`, `systemMessage`, `decision: "block"` + `reason`, `hookSpecificOutput` with `hookEventName`, `permissionDecision` (`allow|deny|ask|defer`), `permissionDecisionReason`, `updatedInput`, `additionalContext` (10,000 char cap).
- Env: `$CLAUDE_PROJECT_DIR` (quote it), `$CLAUDE_PLUGIN_ROOT`, `$CLAUDE_PLUGIN_DATA`, `CLAUDE_ENV_FILE` (SessionStart, Setup, CwdChanged, FileChanged only).
- `disableAllHooks: true` turns off non-managed hooks. Individual hooks can only be removed.

## Patterns (copy with `cc-config template hook:<name> --to .claude/hooks/<name>.sh`, then adapt)

| Need | Event / matcher | Template |
|---|---|---|
| Show only test failures (official token-saving example) | PreToolUse `Bash`, rewrites command via `updatedInput` | `hook:filter-test-output` |
| Block edits to secrets, lockfiles, generated files | PreToolUse `Edit\|Write`, exit 2 | `hook:protect-files` |
| Auto-format edited files | PostToolUse `Edit\|Write` | `hook:format-on-edit` |
| Block dangerous shell commands | PreToolUse `Bash`, exit 2 | `hook:block-dangerous-bash` |
| Re-inject state after compaction | SessionStart `compact`, print a short summary | inline: `"command": "cat \"$CLAUDE_PROJECT_DIR\"/.claude/state.md 2>/dev/null \|\| true"` |
| Desktop notification when Claude needs you | Notification | inline `osascript -e 'display notification "Claude needs input" with title "Claude Code"'` (macOS) / `notify-send` (Linux) |

Official filter example (settings):

```json
{ "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/filter-test-output.sh" } ] } ] } }
```

## Rules of thumb

- Always set a `matcher`. Hooks with no matcher on Pre/PostToolUse run on every tool call (latency).
- Keep hook output tiny. Anything printed on SessionStart/UserPromptSubmit costs tokens every time.
- Scripts: `#!/usr/bin/env bash`, `set -euo pipefail` where safe, read stdin once, use `jq` (or `python3 -c`) to parse, `chmod +x`, store in `.claude/hooks/` and reference via `"$CLAUDE_PROJECT_DIR"/.claude/hooks/x.sh`.
- Fail open for convenience hooks (formatters: `|| true`), fail closed for guard hooks (exit 2).
- Stop hooks that force more work must check `stop_hook_active` to avoid infinite loops, and they cost a full extra turn.
- Hooks run with the user's permissions. Never pipe hook input into `eval`/`sh`.
