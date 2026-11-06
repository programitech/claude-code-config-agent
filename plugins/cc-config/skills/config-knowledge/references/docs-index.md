# Verifying against the live docs (cheaply)

The references in this folder were verified for Claude Code 2.1.284 on 2026-11-06. Claude Code ships often. Verify before relying on a detail when:
- `claude --version` is newer than 2.1.284 and the task depends on a specific field, key, event, or default;
- a field/key/env var is not in these references;
- the user asks for "latest"/"best practice";
- a validation or runtime error contradicts the references.

## Cheapest method: curl + extract a section

Doc pages are large (the subagents page is ~116 KB ≈ 29k tokens). WebFetch returns whole pages. Never read a whole page; extract the section you need:

```bash
U=https://code.claude.com/docs/en/sub-agents.md
curl -sL "$U" | grep -n '^##'                                # 1) headings with line numbers (~100 tokens)
curl -sL "$U" | sed -n '287,330p'                            # 2) only the lines you need
curl -sL "$U" | grep -n -i -A3 'omitClaudeMd' | head -40     # or grep a keyword
```

Find a page: `curl -sL https://code.claude.com/docs/llms.txt | grep -i '<topic>'`.
Recent changes: `curl -sL https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md | head -150`.
Local truth beats docs for flags: `claude --help`, `claude plugin --help`, `claude mcp --help`.
Use WebFetch only if curl is unavailable, and say so (it costs ~10-30k tokens per page).

Cite the URL of any doc you relied on in your report.

## Page map (append `.md` to the path for raw markdown)

| Topic | URL |
|---|---|
| Docs index | https://code.claude.com/docs/llms.txt |
| Memory / CLAUDE.md / rules / auto memory | https://code.claude.com/docs/en/memory.md |
| Settings overview / all keys | https://code.claude.com/docs/en/settings.md, https://code.claude.com/docs/en/settings-reference.md |
| Permissions | https://code.claude.com/docs/en/permissions.md, https://code.claude.com/docs/en/permission-modes.md |
| Env vars | https://code.claude.com/docs/en/env-vars.md |
| Models, effort, auto-compact window | https://code.claude.com/docs/en/model-config.md |
| Context window & compaction | https://code.claude.com/docs/en/context-window.md |
| Prompt caching | https://code.claude.com/docs/en/prompt-caching.md |
| Costs / reducing tokens | https://code.claude.com/docs/en/costs.md |
| Hooks reference / guide | https://code.claude.com/docs/en/hooks.md, https://code.claude.com/docs/en/hooks-guide.md |
| Subagents | https://code.claude.com/docs/en/sub-agents.md |
| Skills | https://code.claude.com/docs/en/skills.md |
| Slash commands (built-in) | https://code.claude.com/docs/en/commands.md |
| MCP | https://code.claude.com/docs/en/mcp.md |
| Plugins: manifest / components / marketplace / install | https://code.claude.com/docs/en/plugins/manifest-reference.md, .../plugins/components.md, .../plugins/marketplace-reference.md, .../plugins/install.md |
| Output styles | https://code.claude.com/docs/en/output-styles.md |
| Status line | https://code.claude.com/docs/en/statusline.md |
| Sandboxing | https://code.claude.com/docs/en/sandboxing.md |
| Official plugins (examples) | https://github.com/anthropics/claude-plugins-official |
