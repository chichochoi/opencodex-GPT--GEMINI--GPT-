#!/usr/bin/env bash
set -euo pipefail

failures=0
pass() {
  printf '[PASS] %s\n' "$1"
}

fail() {
  printf '[FAIL] %s\n' "$1"
  failures=$((failures + 1))
}

if command -v ocx >/dev/null; then pass "ocx is installed"; else fail "ocx is installed"; fi
if command -v codex >/dev/null; then pass "codex is installed"; else fail "codex is installed"; fi
if ocx health --json >/dev/null 2>&1; then pass "OpenCodex proxy is healthy"; else fail "OpenCodex proxy is healthy"; fi

agent_status="$(ocx agent status 2>&1 || true)"
v2_status="$(ocx v2 status 2>&1 || true)"
account_status="$(ocx account current google-antigravity 2>&1 || true)"
codex_home="${CODEX_HOME:-$HOME/.codex}"

if grep -Fq 'google-antigravity/gemini-3.8-flash' <<<"$agent_status"; then pass "Gemini worker is exactly Antigravity Gemini 3.8 Flash"; else fail "Gemini worker is exactly Antigravity Gemini 3.8 Flash"; fi
if grep -Fq 'google-vertex/' <<<"$agent_status"; then fail "Google Vertex is not in the worker route"; else pass "Google Vertex is not in the worker route"; fi
if grep -Eq 'multi_agent_v2:[[:space:]]*ON' <<<"$v2_status"; then pass "multi_agent_v2 is enabled"; else fail "multi_agent_v2 is enabled"; fi
if grep -Eqi 'no active|not found|error' <<<"$account_status"; then fail "Google Antigravity OAuth account is active"; else pass "Google Antigravity OAuth account is active"; fi
if grep -Eq '^model[[:space:]]*=[[:space:]]*"gpt-6-astra"' "$codex_home/config.toml"; then pass "default GPT model is gpt-6-astra"; else fail "default GPT model is gpt-6-astra"; fi
if grep -Fq 'BEGIN OPENCODEX GPT-GEMINI-GPT HARNESS' "$codex_home/AGENTS.md"; then pass "global delegation policy is installed"; else fail "global delegation policy is installed"; fi

if [[ "$(uname -s)" == "Darwin" ]]; then
  if launchctl print "gui/$(id -u)/com.opencodex.gpt-gemini-gpt" >/dev/null 2>&1; then pass "macOS auto-start service is loaded"; else fail "macOS auto-start service is loaded"; fi
else
  if systemctl --user is-enabled opencodex-gpt-gemini-gpt.service >/dev/null 2>&1; then pass "Linux auto-start service is enabled"; else fail "Linux auto-start service is enabled"; fi
fi

(( failures == 0 )) || { echo "$failures verification check(s) failed." >&2; exit 1; }
echo "All harness checks passed."
