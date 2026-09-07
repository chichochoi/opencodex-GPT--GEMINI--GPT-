# Security

This repository contains configuration logic only. Never commit the following:

- `~/.opencodex/` or `~/.codex/`
- OAuth tokens, browser authorization codes, account exports, or admin tokens
- `GEMINI_API_KEY`, `GOOGLE_API_KEY`, or any provider API key

The harness routes Gemini work only through Google Antigravity OAuth. Review changes to the installer and workflow before running a fork.

Report vulnerabilities through GitHub's private vulnerability reporting for this repository.
