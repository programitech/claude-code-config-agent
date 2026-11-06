#!/usr/bin/env bash
# PreToolUse hook (matcher: "Edit|Write"). Blocks edits to protected files.
# Exit 2 blocks the tool call; stderr is shown to Claude so it can choose another approach.
input=$(cat)
if command -v jq >/dev/null 2>&1; then
  path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty')
else
  path=$(printf '%s' "$input" | python3 -c 'import sys,json;t=json.load(sys.stdin).get("tool_input",{});print(t.get("file_path") or t.get("path") or "")' 2>/dev/null)
fi
[ -z "$path" ] && exit 0

rel="${path#"${CLAUDE_PROJECT_DIR:-$PWD}"/}"
base="${path##*/}"

# Edit for the project. Globs match the repo-relative path or the file name.
protected=(
  ".env" ".env.*" "*.pem" "*.key" "*.p12"
  "package-lock.json" "pnpm-lock.yaml" "yarn.lock" "composer.lock" "poetry.lock" "Cargo.lock"
  ".git/*"
)

for p in "${protected[@]}"; do
  # shellcheck disable=SC2053
  if [[ "$rel" == $p || "$base" == $p ]]; then
    echo "Blocked: $rel is protected by .claude/hooks/protect-files.sh. Ask the user to change it, or use the package manager for lockfiles." >&2
    exit 2
  fi
done
exit 0
