---
name: <kebab-case-name>
description: <What it does + when to use it, 1-3 sentences, under ~400 chars. Add "Use proactively after X" only if auto-delegation is wanted.>
tools: Read, Grep, Glob
model: sonnet
maxTurns: 30
# Optional, add only when needed:
# disallowedTools: Write, Edit
# effort: medium
# memory: project
# omitClaudeMd: true
# skills: [<skill-to-preload>]
# isolation: worktree
# color: blue
---

You are <role in one line>.

## Inputs

<What the delegation message will contain and what to assume when something is missing.>

## Process

1. <Step.>
2. <Step.>
3. Verify: <how it checks its own work.>

## Constraints

- <Scope limits: what it must not do.>
- Read only the files you need. Don't paste large file contents into your answer.

## Output

Return only:
- <Compact, structured format, e.g. "Up to 15 bullets: file:line, problem, fix.">
- A one-line verdict.
