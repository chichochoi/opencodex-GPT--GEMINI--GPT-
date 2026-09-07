$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$Failures = [System.Collections.Generic.List[string]]::new()
function Check([bool]$Condition, [string]$Message) {
    if ($Condition) { Write-Host "[PASS] $Message" }
    else { Write-Host "[FAIL] $Message"; $Failures.Add($Message) }
}

Check ([bool](Get-Command ocx -ErrorAction SilentlyContinue)) "ocx is installed"
Check ([bool](Get-Command codex -ErrorAction SilentlyContinue)) "codex is installed"

if (Get-Command ocx -ErrorAction SilentlyContinue) {
    & ocx health --json *> $null
    Check ($LASTEXITCODE -eq 0) "OpenCodex proxy is healthy"

    $AgentStatus = (& ocx agent status 2>&1 | Out-String)
    Check ($AgentStatus -match [regex]::Escape("google-antigravity/gemini-3.8-flash")) "Gemini worker is exactly Antigravity Gemini 3.8 Flash"
    Check ($AgentStatus -notmatch "google-vertex/") "Google Vertex is not in the worker route"

    $V2Status = (& ocx v2 status 2>&1 | Out-String)
    Check ($V2Status -match "multi_agent_v2:\s*ON") "multi_agent_v2 is enabled"

    $Account = (& ocx account current google-antigravity 2>&1 | Out-String)
    Check ($LASTEXITCODE -eq 0 -and $Account -notmatch "no active|not found|error") "Google Antigravity OAuth account is active"
}

$CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }
$ConfigPath = Join-Path $CodexHome "config.toml"
$AgentsPath = Join-Path $CodexHome "AGENTS.md"
$Config = if (Test-Path -LiteralPath $ConfigPath) { Get-Content -LiteralPath $ConfigPath -Raw } else { "" }
$Agents = if (Test-Path -LiteralPath $AgentsPath) { Get-Content -LiteralPath $AgentsPath -Raw } else { "" }
Check ($Config -match '(?m)^model\s*=\s*"gpt-6-astra"') "default GPT model is gpt-6-astra"
Check ($Agents -match "BEGIN OPENCODEX GPT-GEMINI-GPT HARNESS") "global delegation policy is installed"
Check ([bool](Get-ScheduledTask -TaskName "OpenCodex GPT-Gemini-GPT AutoStart" -ErrorAction SilentlyContinue)) "Windows logon auto-start task exists"

if ($Failures.Count -gt 0) {
    throw "Verification failed: $($Failures -join '; ')"
}
Write-Host "All harness checks passed."
