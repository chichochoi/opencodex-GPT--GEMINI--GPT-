# Architecture

```text
User request
    |
    v
GPT 6 Astra (orchestrator)
  - analyzes the goal
  - defines architecture and constraints
  - creates Flash-sized implementation tasks
    |
    v
Google Antigravity OAuth
Gemini 3.8 Flash (worker)
  - writes code and logic
  - runs commands and tests
    |
    v
GPT 6 Astra (reviewer)
  - checks correctness, security, repository fit, and evidence
  - accepts, or creates a smaller corrected Gemini task
```

OpenCodex supplies the local proxy and model routing. `multi_agent_v2` exposes the agent surface. `agentTaskRecovery` lets the GPT orchestrator recover a readable delegated task before forwarding it to the Antigravity worker when Codex emits an encrypted child payload.

The worker roster contains one exact model and its fallback list is empty. A missing or unavailable Antigravity route therefore becomes an explicit failure instead of silently creating API-key usage or selecting another Gemini model.
