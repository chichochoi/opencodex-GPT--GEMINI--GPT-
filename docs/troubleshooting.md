# Troubleshooting

## OAuth login does not complete

Run `ocx account cancel google-antigravity`, close stale authorization tabs, and retry `ocx login google-antigravity`. Only one authorization flow should be active.

## Proxy is not healthy

Run `ocx health --json`, then `ocx restart`. On Windows, also check the `OpenCodex GPT-Gemini-GPT AutoStart` scheduled task. On macOS use `launchctl print gui/$(id -u)/com.opencodex.gpt-gemini-gpt`. On Linux use `systemctl --user status opencodex-gpt-gemini-gpt.service`.

## Gemini is not delegated work

Run the platform verification script, restart Codex Desktop, and run `scripts/test-loop.ps1` on Windows. Check that routing logs contain `google-antigravity/gemini-3.8-flash` between GPT requests.

## Separate Gemini billing must not occur

Do not add a `google` or `google-vertex` provider and do not set `GEMINI_API_KEY` or `GOOGLE_API_KEY` for this harness. The installer only invokes `ocx login google-antigravity`, which is an OAuth flow. Availability and quota remain subject to the signed-in Google account and Google's terms.
