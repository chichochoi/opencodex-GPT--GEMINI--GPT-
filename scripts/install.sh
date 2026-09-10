#!/usr/bin/env bash
set -euo pipefail

OPEN_CODEX_VERSION="${OPEN_CODEX_VERSION:-2.45.0}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROMPT="$(tr '\n' ' ' < "$REPO_ROOT/config/injection-prompt.txt")"

command -v node >/dev/null || { echo "Node.js 20+ is required." >&2; exit 1; }
command -v npm >/dev/null || { echo "npm is required." >&2; exit 1; }

npm install --global "@bitkyc08/opencodex@$OPEN_CODEX_VERSION"
command -v ocx >/dev/null || { echo "ocx is not available in PATH." >&2; exit 1; }

if [[ ! -f "$HOME/.opencodex/config.json" ]]; then
  echo "Complete the interactive OpenCodex setup."
  ocx init
fi

ocx codex-shim install
if ! ocx health --json >/dev/null 2>&1; then
  nohup ocx start >"${TMPDIR:-/tmp}/opencodex-start.log" 2>&1 &
  for _ in {1..30}; do
    ocx health --json >/dev/null 2>&1 && break
    sleep 1
  done
fi
ocx health --json >/dev/null

echo "A browser will open for Google Antigravity OAuth. No Gemini API key is used."
ocx login google-antigravity
node "$SCRIPT_DIR/configure.mjs"
ocx config set agentTaskRecovery '{"enabled":true,"model":"gpt-6-astra","timeoutMs":60000,"cacheEntries":200}'
ocx agent subagents set 'google-antigravity/gemini-3.8-flash,korea-llm/gemini-3.8-flash,korea-llm/gpt-5.6-luna,gpt-5.6-luna'
ocx agent fallback clear
ocx v2 on
ocx agent injection set --guidance on --prompt "$PROMPT"
ocx sync

OCX_PATH="$(command -v ocx)"
if [[ "$(uname -s)" == "Darwin" ]]; then
  mkdir -p "$HOME/Library/LaunchAgents"
  sed "s|__OCX_PATH__|$OCX_PATH|g" "$REPO_ROOT/config/com.opencodex.gpt-gemini-gpt.plist" > "$HOME/Library/LaunchAgents/com.opencodex.gpt-gemini-gpt.plist"
  launchctl bootout "gui/$(id -u)/com.opencodex.gpt-gemini-gpt" >/dev/null 2>&1 || true
  launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.opencodex.gpt-gemini-gpt.plist"
else
  mkdir -p "$HOME/.config/systemd/user"
  sed "s|__OCX_PATH__|$OCX_PATH|g" "$REPO_ROOT/config/opencodex-gpt-gemini-gpt.service" > "$HOME/.config/systemd/user/opencodex-gpt-gemini-gpt.service"
  systemctl --user daemon-reload
  systemctl --user enable --now opencodex-gpt-gemini-gpt.service
fi

bash "$SCRIPT_DIR/verify.sh"
echo "Installation complete. Restart Codex Desktop before the first real task."
