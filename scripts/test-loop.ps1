$ErrorActionPreference = "Stop"

$Prompt = @'
Write a JavaScript function sumEvenSquares(n) that sums the squares of even integers from 1 through n. Analyze and decompose with GPT, delegate implementation to Gemini, then have GPT independently review the result. Return the code, sumEvenSquares(6), and a one-line review verdict.
'@

Write-Host "Running a real GPT -> Gemini -> GPT smoke test..."
& codex exec --ephemeral --sandbox read-only --skip-git-repo-check --enable multi_agent_v2 $Prompt
if ($LASTEXITCODE -ne 0) { throw "Codex loop test failed." }
Write-Host "Recent routing logs:"
& ocx observe logs --limit 20
