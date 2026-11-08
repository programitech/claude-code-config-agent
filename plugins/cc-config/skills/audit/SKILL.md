---
description: Audit this project's Claude Code configuration for token cost, correctness, and security, with ranked fixes. Read-only.
argument-hint: "[focus, e.g. 'tokens' or 'permissions']"
disable-model-invocation: true
context: fork
agent: cc-config:config-agent
background: false
---

mode: plan. This is a read-only audit: do not create, edit, or delete any config file (your own memory files, including plan.md, excepted).

Audit the Claude Code configuration that applies to the project in the current directory, including user-level config and enabled plugins. Focus: $ARGUMENTS (if empty, cover everything).

1. Run `cc-config audit` and `cc-config validate`.
2. For enabled plugins with notable cost, run `claude plugin details <name>` if available.
3. Review CLAUDE.md files, rules, settings, hooks, agents, skills, and MCP servers against the golden rules and the anti-patterns in `cc-config ref tokens`. Read only files the helper output points to.
4. Report:
   - **Overhead**: fixed tokens per session (helper estimate), with the 3 biggest contributors.
   - **Issues**: up to 10, ranked by tokens saved or risk. Each: severity, file, problem, fix, estimated saving.
   - **Good**: 1-3 things already done well.
   - Last line: `Run /cc-config:optimize to apply these fixes.`
5. First run (no plan.md): also write the draft plan and add the `## Interview` section from your workflow, so the caller interviews the user right after the audit.
