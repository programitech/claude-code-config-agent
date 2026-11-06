---
description: Maintainers only. Re-verify the cc-config plugin's reference files against the latest Claude Code docs and changelog, update them, and prepare a release.
disable-model-invocation: true
argument-hint: "[topic to focus on, optional]"
---

# Refresh cc-config references

Focus: $ARGUMENTS (default: all references).

Files: `plugins/cc-config/skills/config-knowledge/references/*.md`, `plugins/cc-config/skills/config-knowledge/SKILL.md`, `plugins/cc-config/bin/cc-config` (known hook events, model aliases, thresholds), templates.

1. Current verified version and date: `grep -h "Verified" plugins/cc-config/skills/config-knowledge/references/*.md | sort -u`. Installed version: `claude --version`.
2. What changed since then: `curl -sL https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md | head -300` and keep only entries newer than the verified version that touch settings, permissions, hooks, subagents, skills, memory, compaction, MCP, plugins, env vars, or costs.
3. For each affected reference, verify against the live page with the cheap method in `plugins/cc-config/skills/config-knowledge/references/docs-index.md` (curl + headings + `sed -n` ranges). Never read whole pages.
4. Update the references in place. Keep them dense; one fact per line; cite nothing you didn't verify. Update the "Verified ..." line (version + today's date) in every file you re-checked, and the version in `config-knowledge/SKILL.md`.
5. If hook events, model aliases, or settings keys changed, update the constants in `plugins/cc-config/bin/cc-config`.
6. Run: `claude plugin validate . --strict && claude plugin validate plugins/cc-config --strict`, `python3 -m py_compile plugins/cc-config/bin/cc-config`, `plugins/cc-config/bin/cc-config audit`.
7. Bump `version` in `plugins/cc-config/.claude-plugin/plugin.json` (patch for reference updates, minor for new features) and add a `CHANGELOG.md` entry.
8. Report: what changed upstream, what you updated, new version. Don't commit or push unless asked.
