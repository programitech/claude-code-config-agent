# Interviewing the user (first run)

Verified against https://code.claude.com/docs/en/sub-agents.md (available tools) for Claude Code 2.1.284 on 2026-11-08.

Subagents can't ask the user directly (`AskUserQuestion` is removed from every subagent), so the agent returns the questions and the caller asks them.

## Rules

- Ask on the first run in a project (no `plan.md`), and later only when a request leaves a requirement open.
- At most 4 questions per round, at most 2 rounds. Round 1 covers the basics. Round 2 is only for what round 1 opened up.
- Skip anything the brief, the existing config, or the repo already answers. Say what you inferred under Requirements instead.
- Tailor the options to the analysis: name the detected stack, commands and tools ("Run `pnpm test` without asking").
- Each question: header of at most 12 characters, 2-4 options, a label of 1-5 words plus a one-line description, your recommendation first with "(Recommended)". Mark multi-select where choices combine. Users can always type their own answer, so don't add an "Other" option.

## Output format (inside the report)

```
## Interview
Caller: ask the user these with AskUserQuestion exactly as written, then send the answers back (resume this agent, or call cc-config:config-agent again with the original task plus `answers:`).
1. [Audience] Who will use this Claude Code setup?
   - Whole team (Recommended): shared files committed to the repo
   - Only me, this repo: personal files, gitignored
   - Me, every project: user-level files in ~/.claude
2. [Guardrails] Which safety checks should run automatically? (multi-select)
   - ...
```

## Question bank

| Topic | Round | Ask unless | Question | Options | Maps to |
|---|---|---|---|---|---|
| Audience | 1 | scope is obvious | Who will use this setup? | whole team / only me here / me everywhere | file scope |
| Cost | 1 | the user stated a budget | What matters most for cost? | balanced / lowest tokens / max capability | model, effortLevel, autoCompactWindow, subagent models |
| Permissions | 1 | allow/deny rules exist and fit | How much may Claude do without asking? | safe read-only + detected test/lint commands / ask for most / most commands (personal scope only) | permissions allow/deny |
| Guardrails | 1 | equivalent hooks/deny rules exist | Which automatic safety checks? (multi) | protect secrets + lockfiles / block destructive commands / format on edit / trim noisy test output | deny rules, hook templates |
| Workflows | 2 | none detected | Which repeated tasks should get a command? (multi) | detected scripts: test, release, deploy, migrations... | skills (`disable-model-invocation: true`) |
| Specialists | 2 | agents already cover it | Which helper agents? (multi) | code reviewer / test runner / docs writer / none | subagents (cheapest capable model) |
| Integrations | 2 | none needed | Which outside tools does Claude need? (multi) | GitHub / database / issue tracker / browser testing | CLI first, else MCP at the right scope |
| Knowledge | 2 | CLAUDE.md covers it | What must Claude always know that the code doesn't show? | conventions / deploy and env notes / gotchas / nothing more | CLAUDE.md, path rules |
| Extras | 2 | already set | Which extras? (multi) | status line with context and cost / compact earlier / none | statusLine, autoCompactWindow |

## After the answers

- Record each answer under `## Requirements` as "topic: answer (interview)".
- Turn answers into numbered steps with the "Where does a requirement go?" table in config-knowledge. Each step names file, scope and token impact.
- Set `Status: awaiting approval` and return the plan. Change no config until the caller sends approved step numbers.
