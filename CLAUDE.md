# claude-code-config-agent

Marketplace repo for the `cc-config` Claude Code plugin: a token-efficient config agent installed into other projects.

## Layout

- `.claude-plugin/marketplace.json`: marketplace `cc-config-agent`, lists `plugins/cc-config`.
- `plugins/cc-config/agents/config-agent.md`: the agent (always-loaded description: keep it short).
- `plugins/cc-config/skills/config-knowledge/`: preloaded knowledge (SKILL.md index, `references/`, `templates/`).
- `plugins/cc-config/skills/<name>/SKILL.md`: user-only slash commands (`disable-model-invocation: true`).
- `plugins/cc-config/bin/cc-config`: stdlib Python helper on the Bash PATH (`audit`, `validate`, `ref`, `template`, `list`).

## Commands

- Validate: `claude plugin validate . --strict && claude plugin validate plugins/cc-config --strict`
- Try locally: `claude --plugin-dir ./plugins/cc-config`, then `/context` to check the always-on cost.
- Helper: `plugins/cc-config/bin/cc-config audit --project <dir>`

## Rules

- Every always-loaded token counts: agent description under 400 chars, model-invocable skill descriptions under 300, new slash commands get `disable-model-invocation: true`.
- Plugin agents ignore `hooks`, `mcpServers`, `permissionMode`, `initialPrompt`.
- Plugin names can't start with `claude-`.
- Facts in `references/` must be verified against code.claude.com (use `/refresh-references`). Update the "Verified" line when you re-check a file.
- Bump `version` in `plugins/cc-config/.claude-plugin/plugin.json` for every release (users only update on a version change) and add a CHANGELOG entry.
