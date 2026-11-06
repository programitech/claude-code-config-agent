#!/usr/bin/env bash
# Install the cc-config plugin (Claude Code config agent) into the current project or for your user.
#
#   curl -fsSL https://raw.githubusercontent.com/programitech/claude-code-config-agent/main/install.sh | bash -s -- [options]
#
# Options:
#   --scope project|local|user   project (default): shared with the team via .claude/settings.json
#                                local: only you, this repo (.claude/settings.local.json)
#                                user: you, every project (~/.claude/settings.json)
#   --allow-helper               also allow the plugin's read-only helper command, Bash(cc-config *),
#                                so the agent can measure and validate config without prompting
#   --source <owner/repo|path>   marketplace source (default: programitech/claude-code-config-agent)
set -euo pipefail

SCOPE="project"
ALLOW_HELPER=0
SOURCE="programitech/claude-code-config-agent"
MARKETPLACE="cc-config-agent"
PLUGIN="cc-config"

while [ $# -gt 0 ]; do
  case "$1" in
    --scope) SCOPE="${2:-}"; shift 2 ;;
    --allow-helper) ALLOW_HELPER=1; shift ;;
    --source) SOURCE="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,13p' "$0" 2>/dev/null || true; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done
case "$SCOPE" in project|local|user) ;; *) echo "--scope must be project, local or user" >&2; exit 2 ;; esac

command -v claude >/dev/null 2>&1 || { echo "Claude Code CLI not found. Install it first: https://code.claude.com/docs" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 is required (the plugin's helper uses it)." >&2; exit 1; }

if [ "$SCOPE" != "user" ] && ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "Note: $(pwd) is not a git repository; installing at $SCOPE scope here anyway."
fi

echo "==> Adding marketplace $MARKETPLACE from $SOURCE"
KNOWN=$(claude plugin marketplace list 2>/dev/null || true)
if printf '%s\n' "$KNOWN" | grep -q "$MARKETPLACE"; then
  claude plugin marketplace update "$MARKETPLACE" >/dev/null 2>&1 || true
  echo "    already added (refreshed)"
else
  claude plugin marketplace add "$SOURCE"
fi

echo "==> Installing $PLUGIN@$MARKETPLACE (scope: $SCOPE)"
claude plugin install "$PLUGIN@$MARKETPLACE" --scope "$SCOPE"

case "$SCOPE" in
  user) SETTINGS="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json" ;;
  project) SETTINGS=".claude/settings.json" ;;
  local) SETTINGS=".claude/settings.local.json" ;;
esac

# For project scope, declare the marketplace in the shared settings so teammates are offered it
# when they trust the folder. Optionally allow the helper command.
python3 - "$SETTINGS" "$SCOPE" "$SOURCE" "$MARKETPLACE" "$ALLOW_HELPER" <<'PY'
import json, os, sys
path, scope, source, mkt, allow = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5] == "1"
data = {}
if os.path.exists(path):
    with open(path) as f:
        data = json.load(f)
changed = []
if scope == "project" and not os.path.isdir(source):
    data.setdefault("$schema", "https://json.schemastore.org/claude-code-settings.json")
    mk = data.setdefault("extraKnownMarketplaces", {})
    if mkt not in mk:
        mk[mkt] = {"source": {"source": "github", "repo": source}}
        changed.append(f"extraKnownMarketplaces.{mkt}")
if allow:
    rules = data.setdefault("permissions", {}).setdefault("allow", [])
    if "Bash(cc-config *)" not in rules:
        rules.append("Bash(cc-config *)")
        changed.append("permissions.allow += Bash(cc-config *)")
if changed:
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    print(f"==> Updated {path}: " + "; ".join(changed))
PY

cat <<EOF

Done. Start a new Claude Code session in this project, then try:
  /cc-config:audit                 token + correctness audit (read-only)
  /cc-config:setup <requirements>  set up or overhaul the config
  /cc-config:agent <description>   create a subagent
Or just ask: "create a skill that ...", "make auto-compact cheaper", "add a hook that ...".
EOF
if [ "$SCOPE" = "project" ]; then
  echo "Commit .claude/settings.json so teammates get the plugin (each runs: claude plugin install $PLUGIN@$MARKETPLACE --scope project)."
fi
