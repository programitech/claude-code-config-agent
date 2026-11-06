#!/usr/bin/env bash
# PostToolUse hook (matcher: "Edit|Write"). Formats the edited file with the project's formatter.
# Silent and fail-open: prints nothing, so it costs no context tokens. Remove formatters you don't use.
input=$(cat)
if command -v jq >/dev/null 2>&1; then
  f=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
else
  f=$(printf '%s' "$input" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' 2>/dev/null)
fi
[ -n "$f" ] && [ -f "$f" ] || exit 0
root="${CLAUDE_PROJECT_DIR:-$PWD}"

case "$f" in
  *.js|*.jsx|*.ts|*.tsx|*.mjs|*.cjs|*.json|*.css|*.scss|*.md|*.html|*.vue|*.svelte|*.yml|*.yaml)
    [ -x "$root/node_modules/.bin/prettier" ] && "$root/node_modules/.bin/prettier" --write "$f" ;;
  *.py)
    if command -v ruff >/dev/null 2>&1; then ruff format -q "$f"; elif command -v black >/dev/null 2>&1; then black -q "$f"; fi ;;
  *.go) command -v gofmt >/dev/null 2>&1 && gofmt -w "$f" ;;
  *.rs) command -v rustfmt >/dev/null 2>&1 && rustfmt -q "$f" ;;
  *.php) [ -x "$root/vendor/bin/pint" ] && "$root/vendor/bin/pint" -q "$f" ;;
esac >/dev/null 2>&1
exit 0
