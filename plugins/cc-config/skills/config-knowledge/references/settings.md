# Settings, permissions, env vars, model, compaction, status line, output styles

Verified against code.claude.com docs (settings, settings-reference, permissions, env-vars, model-config, statusline, output-styles) for Claude Code 2.1.284 on 2026-11-06.

## Files and precedence (highest first)

1. Managed: `managed-settings.json` (macOS `/Library/Application Support/ClaudeCode/`, Linux `/etc/claude-code/`), MDM, server-managed
2. CLI: `--settings <file-or-json>`, `--model`, etc.
3. `.claude/settings.local.json` (personal, gitignored automatically)
4. `.claude/settings.json` (team, committed)
5. `~/.claude/settings.json` (user)

- Arrays (e.g. `permissions.allow`) merge across files. Scalars: higher wins.
- Strict JSON (no comments, no trailing commas). Add `"$schema": "https://json.schemastore.org/claude-code-settings.json"`.
- `~/.claude.json` is a different file: user/local MCP servers, project trust, some UI prefs. Don't hand-edit it while sessions run; use `claude mcp ...` and `/config`.
- Verify with `/status` (Setting sources) and `claude doctor` (rejected entries). Most edits hot-reload.
- Some keys are ignored in project/local files (e.g. `defaultMode` `auto`/`bypassPermissions`; `CLAUDE_CONFIG_DIR`), and some wait for folder trust (`enableAllProjectMcpServers`).

## Scope choice

| Setting is... | Put it in |
|---|---|
| Team policy (permissions, hooks, plugins, env for the repo) | `.claude/settings.json` |
| Personal for this repo (model, extra allows, disabling a team plugin) | `.claude/settings.local.json` |
| Personal everywhere (model, effort, status line, output style) | `~/.claude/settings.json` |

## Keys that matter

| Key | Notes |
|---|---|
| `permissions` | `allow`, `ask`, `deny` arrays; `additionalDirectories`; `defaultMode` (`default`/`manual`, `acceptEdits`, `plan`, `auto`, `dontAsk`, `bypassPermissions`); `disableBypassPermissionsMode`/`disableAutoMode`: `"disable"` |
| `env` | Env vars for every session (see below) |
| `hooks` | See hooks.md. `disableAllHooks: true` disables non-managed hooks |
| `model` | Alias (`sonnet`, `opus`, `haiku`, `fable`, `opusplan`, `opus[1m]`) or full ID |
| `availableModels`, `modelSettings` | Restrict picker; per-model settings e.g. `{"claude-opus-5-5": {"effortLevel": "high"}}` |
| `effortLevel` | `low`, `medium`, `high`, `xhigh` (`max` only via env or `/effort`) |
| `alwaysThinkingEnabled` | bool |
| `autoCompactEnabled` | bool, default true |
| `autoCompactWindow` | 100000-1000000 tokens: when to compact |
| `outputStyle` | Name of a built-in or custom style |
| `statusLine`, `subagentStatusLine` | See below |
| `attribution` | `{ "commit": "...", "pr": "...", "sessionUrl": bool }` (`includeCoAuthoredBy` is deprecated) |
| `includeGitInstructions` | bool |
| `cleanupPeriodDays` | Transcript retention (default 30) |
| `sandbox` | `enabled`, `failIfUnavailable`, `autoAllowBashIfSandboxed`, `excludedCommands`, `filesystem.*`, `network.*` |
| `enableAllProjectMcpServers`, `enabledMcpjsonServers`, `disabledMcpjsonServers` | Approval of `.mcp.json` servers |
| `enabledPlugins`, `extraKnownMarketplaces` | See plugins.md |
| `autoMemoryEnabled`, `autoMemoryDirectory`, `claudeMdExcludes` | See memory.md |
| `plansDirectory`, `language`, `spinnerTipsEnabled`, `spinnerTipsOverride` | UX |

## Permissions

Order: deny → ask → allow (first match wins in that order). Rules: `Tool` or `Tool(specifier)`.

- Bash: `Bash(npm run build)` exact. `Bash(npm run *)` prefix family (`*` anywhere; trailing ` *` also matches the bare command). Put `*` after the subcommand: `Bash(git log *)` not `Bash(git *)`. `Bash(ls:*)` legacy form = `Bash(ls *)`. Compound commands are split and each part must match.
- Read/Edit (gitignore patterns): `//abs/path`, `~/home/path`, `/path` (relative to the settings file's root: project dir for project/local, `~/.claude` for user!), `path` or `./path` (relative to cwd). `Read` deny also covers Grep/Glob best-effort. `.claudeignore` has no effect.
- `WebFetch(domain:example.com)`, `WebFetch(domain:*.example.com)`.
- MCP: `mcp__server`, `mcp__server__*`, `mcp__server__tool`. Plugin server: `mcp__plugin_<plugin>_<server>__*`. `mcp__` rules with parentheses are skipped.
- `Agent(Explore)`, `Agent(my-agent)`; parameter rules for deny/ask: `Agent(model:opus)`, `Bash(run_in_background:true)`.
- `Skill(skill:<name>)` deny.
- Tool-name globs in deny/ask: `"mcp__*"`, `"*"`. A bare-tool deny removes the tool from context (saves tokens).

Baseline secret protection (project settings):

```json
{
  "permissions": {
    "deny": [
      "Read(./.env)", "Read(./.env.*)", "Read(./**/.env)", "Read(./**/.env.*)",
      "Read(./secrets/**)", "Read(./**/*.pem)", "Read(./**/*.key)",
      "Bash(rm -rf *)", "Bash(git push --force *)", "Bash(curl * | sh)"
    ]
  }
}
```

Allow-list only commands that are safe and frequent (`Bash(npm run test *)`, `Bash(git status)`, `Bash(git diff *)`). Never allow `Bash` or `Bash(*)` wholesale in team settings.

## Token-related env vars (`env` in settings or shell)

| Var | Effect |
|---|---|
| `CLAUDE_CODE_AUTO_COMPACT_WINDOW` | Compaction window (`200000`, `300k`, `1M`); overrides `/autocompact` and `autoCompactWindow` |
| `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` | 1-100; lowers the % of window at which compaction triggers (also subagents) |
| `DISABLE_AUTO_COMPACT` / `DISABLE_COMPACT` | Disable auto (and idle) compaction / all compaction |
| `CLAUDE_CODE_DISABLE_1M_CONTEXT` | Force 200K windows |
| `MAX_THINKING_TOKENS` | Fixed thinking budget (ignored on adaptive models unless `CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING=1`; 5.5-generation and Fable can't disable thinking) |
| `CLAUDE_CODE_EFFORT_LEVEL` | `low`..`max`, `auto`; highest precedence |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | Max output per request; higher values shrink the pre-compaction window |
| `BASH_MAX_OUTPUT_LENGTH` | Bash output chars (default 30000, max 150000) |
| `MAX_MCP_OUTPUT_TOKENS` | MCP result cap (default 25000) |
| `ENABLE_TOOL_SEARCH` | Unset/`true` defers MCP tool schemas; `auto`, `auto:N`; `false` loads all upfront (costly) |
| `CLAUDE_CODE_SUBAGENT_MODEL` | Default model for subagents without `model:` (`CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` overrides frontmatter) |
| `ANTHROPIC_DEFAULT_{OPUS,SONNET,HAIKU,FABLE}_MODEL` | Pin what aliases resolve to |
| `SLASH_COMMAND_TOOL_CHAR_BUDGET` | Skill listing budget (default 1% of window, fallback 8000 chars) |
| `CLAUDE_CODE_DISABLE_AUTO_MEMORY` | `1` disables auto memory |
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` | Disables autoupdate, telemetry, feature flags, Remote Control |
| `CLAUDE_CODE_GOAL_CHECKIN_MINUTES` | `0` disables goal idle check-ins |
| `DISABLE_PROMPT_CACHING` (+ `_HAIKU`, `_SONNET`, `_OPUS`, `_FABLE`) | Do not set unless debugging |

Model resolution: `/model` > `--model` > `ANTHROPIC_MODEL` > `model` setting > `ANTHROPIC_DEFAULT_MODEL`. Effort: `CLAUDE_CODE_EFFORT_LEVEL` > session pick > `--effort` > `modelSettings`/`effortLevel` > model default.

## Status line

```json
{ "statusLine": { "type": "command", "command": "~/.claude/statusline.sh", "padding": 0 } }
```

Script reads JSON on stdin, prints lines to stdout, must exit 0. Useful fields: `model.display_name`, `context_window.used_percentage`, `context_window.context_window_size`, `cost.total_cost_usd`, `effort.level`, `prompt_cache.hit_ratio`, `rate_limits.five_hour.used_percentage`, `workspace.current_dir`. Optional `refreshInterval` (seconds). Template: `cc-config template statusline --to ~/.claude/statusline.sh`. Status line output costs no model tokens: it is the cheapest way to keep context usage visible.

## Output styles

- Files: `~/.claude/output-styles/*.md`, `.claude/output-styles/*.md`. Frontmatter: `name`, `description`, `keep-coding-instructions` (default false: replaces the coding part of the system prompt).
- Built-ins: Default, Proactive, Concise, Explanatory, Learning. Select with `/output-style`, `/config`, or `"outputStyle"` (case-sensitive; `/output-style` writes settings.local.json).
- Every style adds input tokens each request; Explanatory/Learning add output tokens. Prefer Default/Concise.
