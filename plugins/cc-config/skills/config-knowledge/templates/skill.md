---
name: <kebab-case-name>
description: <What it does. Use when the user asks to X, Y, or mentions Z. Under ~300 chars.>
# User-triggered or side effects → zero listing cost:
disable-model-invocation: true
argument-hint: "<args>"
# Optional:
# allowed-tools: Bash(npm run test *), Read
# context: fork
# agent: <subagent-name>
# model: sonnet
# paths: ["src/**/*.ts"]
---

# <Title>

Goal: <one sentence>.

Input: `$ARGUMENTS` (<what it means; what to do if empty>).

## Steps

1. <Step. Prefer running scripts in ${CLAUDE_SKILL_DIR}/scripts/ over reading code.>
2. <Step.>
3. Verify: <check>.

## Output

<Exact, compact format of the final answer.>

<!-- Put long reference material in a sibling file and link it with "Read [reference.md](reference.md) when <condition>". -->
