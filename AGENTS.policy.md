<!-- BEGIN OPENCODEX GPT-GEMINI-GPT HARNESS -->
## OpenCodex GPT-Gemini-GPT Harness

### Provider Policy

- Gemini work MUST use `google-antigravity/gemini-3.8-flash` through Google Antigravity OAuth.
- Never use the `google` or `google-vertex` providers for Gemini work.
- Never request, store, or configure a Gemini API key for this harness.
- Do not fall back to another Gemini model or provider. Stop and report the routing failure instead.

### Delegation Policy

- GPT is the orchestrator. GPT owns goal interpretation, problem analysis, architecture, constraints, risk analysis, decomposition, acceptance criteria, final integration, and user-facing conclusions.
- Before implementation, GPT divides the work into small, bounded tasks that a Flash model can complete independently. Each task must include relevant files, constraints, expected output, and a concrete verification target.
- Gemini is the implementation worker. Delegate coding, business logic, tests, refactors, command execution, and other direct implementation work to `google-antigravity/gemini-3.8-flash`.
- GPT must review every Gemini result against the original goal, repository conventions, correctness, security, and tests. Gemini output is never accepted without GPT review.
- When review finds a defect or missing evidence, GPT creates a smaller corrected task and delegates it to Gemini again. Repeat until acceptance criteria pass or a real blocker is reported.
- GPT may directly inspect files, run verification, and make a minimal emergency correction only when delegation is unavailable. GPT must disclose that exception in the final response.
<!-- END OPENCODEX GPT-GEMINI-GPT HARNESS -->
