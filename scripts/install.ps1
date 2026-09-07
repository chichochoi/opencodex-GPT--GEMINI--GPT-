[CmdletBinding()]
param(
    [string]$OpenCodexVersion = "2.45.0",
    [switch]$SkipOpenCodexInstall,
    [switch]$SkipOAuthLogin,
    [switch]$SkipAutoStart
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$RepoRoot = Split-Path -Parent $PSScriptRoot
$PromptPath = Join-Path $RepoRoot "config\injection-prompt.txt"
$TaskName = "OpenCodex GPT-Gemini-GPT AutoStart"

function Require-Command([string]$Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' was not found in PATH."
    }
}

function Wait-OpenCodex {
    for ($attempt = 0; $attempt -lt 30; $attempt++) {
        & ocx health --json *> $null
        if ($LASTEXITCODE -eq 0) { return }
        Start-Sleep -Seconds 1
    }
    throw "OpenCodex proxy did not become healthy within 30 seconds."
}

Require-Command node
Require-Command npm

if (-not $SkipOpenCodexInstall) {
    & npm install --global "@bitkyc08/opencodex@$OpenCodexVersion"
    if ($LASTEXITCODE -ne 0) { throw "OpenCodex installation failed." }
}
Require-Command ocx

$OpenCodexConfig = Join-Path $HOME ".opencodex\config.json"
if (-not (Test-Path -LiteralPath $OpenCodexConfig)) {
    Write-Host "OpenCodex first-time setup is starting. Complete its interactive prompts."
    & ocx init
    if ($LASTEXITCODE -ne 0) { throw "ocx init failed." }
}

& ocx codex-shim install
if ($LASTEXITCODE -ne 0) { throw "Codex auto-start shim installation failed." }

& ocx health --json *> $null
if ($LASTEXITCODE -ne 0) {
    $OcxLauncher = (Get-Command ocx.cmd -ErrorAction SilentlyContinue).Source
    if (-not $OcxLauncher) { $OcxLauncher = (Get-Command ocx).Source }
    Start-Process -FilePath $OcxLauncher -ArgumentList "start" -WindowStyle Hidden
    Wait-OpenCodex
}

if (-not $SkipOAuthLogin) {
    Write-Host "A browser will open for Google Antigravity OAuth. No Gemini API key is used."
    & ocx login google-antigravity
    if ($LASTEXITCODE -ne 0) { throw "Google Antigravity OAuth login failed." }
}

& node (Join-Path $PSScriptRoot "configure.mjs")
if ($LASTEXITCODE -ne 0) { throw "Codex policy configuration failed." }

$Recovery = '{"enabled":true,"model":"gpt-6-astra","timeoutMs":60000,"cacheEntries":200}'
& ocx config set agentTaskRecovery $Recovery
if ($LASTEXITCODE -ne 0) { throw "Agent task recovery configuration failed." }

$InjectionPrompt = (Get-Content -LiteralPath $PromptPath -Raw).Trim()
& ocx agent subagents set "google-antigravity/gemini-3.8-flash"
if ($LASTEXITCODE -ne 0) { throw "Gemini subagent configuration failed." }
& ocx agent fallback clear
if ($LASTEXITCODE -ne 0) { throw "Subagent fallback could not be cleared." }
& ocx v2 on
if ($LASTEXITCODE -ne 0) { throw "multi_agent_v2 could not be enabled." }
& ocx agent injection set --guidance on --prompt $InjectionPrompt
if ($LASTEXITCODE -ne 0) { throw "Delegation prompt configuration failed." }
& ocx sync
if ($LASTEXITCODE -ne 0) { throw "Codex proxy synchronization failed." }

if (-not $SkipAutoStart) {
    $OcxLauncher = (Get-Command ocx.cmd -ErrorAction SilentlyContinue).Source
    if (-not $OcxLauncher) { $OcxLauncher = (Get-Command ocx).Source }
    $Pwsh = (Get-Command powershell.exe).Source
    $Arguments = "-NoProfile -WindowStyle Hidden -Command `"& '$OcxLauncher' start`""
    $Action = New-ScheduledTaskAction -Execute $Pwsh -Argument $Arguments
    $Trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
    $Principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited
    $Settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit ([TimeSpan]::Zero)
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Force | Out-Null
}

& (Join-Path $PSScriptRoot "verify.ps1")
Write-Host "Installation complete. Restart Codex Desktop before the first real task."
