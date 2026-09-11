# Generate migration/adaptation checklist after es-abcd install.
# ASCII-primary for Windows PowerShell 5.1 parser safety.
# Usage:
#   powershell -File .\scripts\New-ESABCDAdaptChecklist.ps1 -TargetRoot <项目根路径> -OutMarkdown
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$TargetRoot,
    [string]$PackageRoot = '',
    [switch]$OutMarkdown,
    [string]$ProjectName = ''
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$TargetRoot = (Resolve-Path -LiteralPath $TargetRoot).Path
if ([string]::IsNullOrWhiteSpace($PackageRoot)) {
    $scriptDir = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
    $PackageRoot = (Resolve-Path (Join-Path $scriptDir '..')).Path
} else {
    $PackageRoot = (Resolve-Path -LiteralPath $PackageRoot).Path
}
if ([string]::IsNullOrWhiteSpace($ProjectName)) {
    $ProjectName = Split-Path -Leaf $TargetRoot
}

function Test-Rel([string]$Rel) {
    return (Test-Path -LiteralPath (Join-Path $TargetRoot $Rel))
}

$checks = New-Object System.Collections.Generic.List[object]
function Add-Check([string]$Id, [string]$Title, [string]$Status, [string]$Action, [string]$Why) {
    [void]$checks.Add([pscustomobject]@{
            id     = $Id
            title  = $Title
            status = $Status
            action = $Action
            why    = $Why
        })
}

$hasHome = Test-Rel 'ES\Automation\ABCD\ESABCDHome.psm1'
$hasUse = Test-Rel 'ES\Automation\ABCD\Use-ESABCD.ps1'
$hasContracts = Test-Rel 'ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json'
$hasSkill = Test-Rel '.agents\skills\es-ai-abc-core\SKILL.md'
$hasInstallReceipt = Test-Rel 'ES\Automation\ABCD\es-abcd-install.receipt.json'
$hasEsFrameworkMarkers = (Test-Rel 'Assets\Plugins\ES') -or (Test-Rel 'AGENTS.md') -or (Test-Rel 'ES\AISpace')
$hasUnity = (Test-Rel 'Assets') -and (Test-Rel 'ProjectSettings')
$hasOut = Test-Rel 'ES\Automation\ABCD\out'

# Load adaptive project profile if present
$profileObj = $null
foreach ($pp in @(
        (Join-Path $TargetRoot 'ES\Automation\ABCD\out\project-profile.json'),
        (Join-Path $TargetRoot '.es-abcd-out\project-profile-preinstall.json')
    )) {
    if (Test-Path -LiteralPath $pp -PathType Leaf) {
        try { $profileObj = Get-Content -LiteralPath $pp -Raw -Encoding UTF8 | ConvertFrom-Json; break } catch { }
    }
}
$primaryKind = if ($profileObj) { [string]$profileObj.primaryKind } else { 'unknown' }
$profileKinds = if ($profileObj) { @($profileObj.kinds | ForEach-Object { [string]$_ }) } else { @() }

Add-Check 'profile.detected' ("Project profile: $primaryKind") $(if ($profileObj) { 'done' } else { 'review' }) `
    'Run get.ps1 (writes project-profile) or Get-ESABCDProjectProfile.ps1' 'Adaptive install depends on project analysis.'

Add-Check 'install.core' 'Core overlay present' $(if ($hasHome -and $hasContracts) { 'done' } else { 'todo' }) `
    'Run get.ps1 -TargetRoot <this project>' 'Without overlay, ABCD APIs are missing.'

Add-Check 'install.shim' 'Daily shim Use-ESABCD.ps1' $(if ($hasUse) { 'done' } else { 'todo' }) `
    'Re-run get.ps1 (writes shim)' 'One-line daily entry for humans and AI.'

Add-Check 'install.receipt' 'Install receipt' $(if ($hasInstallReceipt) { 'done' } else { 'optional' }) `
    'Re-run Install-ESABCD/get.ps1' 'Proves install provenance.'

Add-Check 'verify.smoke' 'Smoke verification' $(if ($hasOut) { 'review' } else { 'todo' }) `
    'powershell -File <es-abcd>/scripts/Invoke-ESABCDSmoke.ps1 -ProjectRoot <target>' 'Static proof Core runs; runtime-not-run is expected.'

Add-Check 'verify.quick' 'Invoke-ESABCDQuick works' 'todo' `
    '. .\ES\Automation\ABCD\Use-ESABCD.ps1; Invoke-ESABCDQuick -Requirement "ping"' 'Daily API acceptance.'

Add-Check 'identity.portable' 'Portable governance default' 'todo' `
    'Keep ES_ABCD_GOVERNANCE_MODE=portable unless host corpus is intentional' 'Independence from native ESFramework AIWarnings corpus.'

Add-Check 'identity.not-es-runtime' 'Do not treat es-abcd as ESFramework runtime' 'info' `
    'Read docs/independence.md' 'es-abcd is orchestration core; ESFramework is optional host/consumer.'

if ($hasEsFrameworkMarkers) {
    Add-Check 'host.esframework-detected' 'ESFramework-like tree detected' 'review' `
        'Prefer single Core via es-abcd overlay; avoid dual ABCD forks' 'Avoid two competing ABCD cores.'
    Add-Check 'host.warnings-corpus' 'Optional host AIWarnings corpus' 'optional' `
        'Set ES_ABCD_GOVERNANCE_MODE=host only when AIWarnings index is fresh' 'Host enhances governance; must fall back to portable on failure.'
}
else {
    Add-Check 'host.esframework-detected' 'No ESFramework host markers' 'done' `
        'No action' 'Pure consumer project - portable path is correct.'
}

if ($hasUnity) {
    Add-Check 'unity.boundary' 'Unity project boundary' 'info' `
        'Do not claim PlayMode from Smoke' 'ABCD Core does not replace Unity test evidence.'
}

if ($hasSkill) {
    Add-Check 'agent.skill' 'Agent skill path present' 'review' `
        'Point agent skill loader to .agents/skills/es-ai-abc-core/SKILL.md' 'Lets AI follow ABCD playbook.'
}
else {
    Add-Check 'agent.skill' 'Agent skill missing' 'todo' `
        'Re-run get.ps1/Install to overlay .agents/skills' 'AI one-liner install relies on skill/playbook.'
}

Add-Check 'ci.optional' 'Optional CI smoke' 'optional' `
    'Add job: Invoke-ESABCDSmoke.ps1 -ProjectRoot repo root' 'Locks install regressions.'

Add-Check 'docs.team' 'Team onboarding note' 'todo' `
    'Paste one-click command + Use-ESABCD two-liner into project README' 'Human discoverability.'

Add-Check 'migrate.old-scripts' 'Retire ad-hoc ABCD copies' 'review' `
    'Search duplicate ES/Automation/ABCD forks; stop editing forks' 'Single Core source of truth.'

Add-Check 'migrate.import-sites' 'Update call sites to Invoke-ESABCDQuick' 'todo' `
    'Replace hand-rolled Import-Module stacks with Use-ESABCD.ps1' 'Reduces agent/human friction.'

if ($profileObj) {
    Add-Check 'adapt.strategy' 'Follow adaptive strategy from profile' 'review' `
        ([string](($profileObj.recommendedActions | ForEach-Object { [string]$_ }) -join ' / ')) `
        ([string]$profileObj.humanSummary)
}

$arr = @($checks.ToArray())
$done = @($arr | Where-Object { $_.status -eq 'done' }).Count
$todo = @($arr | Where-Object { $_.status -eq 'todo' }).Count
$review = @($arr | Where-Object { $_.status -eq 'review' }).Count

$doc = [pscustomobject]@{
    schemaVersion   = 1
    recordType      = 'ESABCDAdaptChecklist'
    projectName     = $ProjectName
    targetRoot      = $TargetRoot
    packageRoot     = $PackageRoot
    generatedUtc    = [DateTime]::UtcNow.ToString('o')
    projectProfile  = [pscustomobject]@{
        primaryKind = $primaryKind
        kinds       = $profileKinds
        humanSummary = $(if ($profileObj) { [string]$profileObj.humanSummary } else { '' })
    }
    summary         = [pscustomobject]@{ total = $arr.Count; done = $done; todo = $todo; review = $review }
    independence    = [pscustomobject]@{
        productId           = 'es-abcd'
        requiresESFramework = $false
        requiresUnity       = $false
        esFrameworkMarkers  = [bool]$hasEsFrameworkMarkers
        unityProject        = [bool]$hasUnity
        anyProjectSupported = $true
    }
    installDetected = [pscustomobject]@{
        core      = $hasHome
        shim      = $hasUse
        contracts = $hasContracts
        skill     = $hasSkill
    }
    dailyUse        = @(
        '. .\ES\Automation\ABCD\Use-ESABCD.ps1',
        'Invoke-ESABCDQuick -Requirement "your goal"'
    )
    aiOneLiner      = '把 es-abcd 装进本项目并刷新适配清单。'
    checks          = $arr
    runtimeStatus   = 'runtime-not-run'
    nonClaims       = @('Unity', 'PlayMode', 'Profiler', 'Player', 'Release')
}

$outDir = Join-Path $TargetRoot 'ES\Automation\ABCD\out'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }
$stamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss')
$jsonPath = Join-Path $outDir ('adapt-checklist-' + $stamp + '.json')
[IO.File]::WriteAllText($jsonPath, ($doc | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))

$mdPath = $null
if ($OutMarkdown) {
    $lines = New-Object System.Collections.Generic.List[string]
    [void]$lines.Add('# es-abcd 迁移 / 适配清单')
    [void]$lines.Add('')
    [void]$lines.Add('- **项目**: ' + $ProjectName)
    [void]$lines.Add('- **项目根**: `' + $TargetRoot + '`')
    [void]$lines.Add('- **生成时间(UTC)**: ' + $doc.generatedUtc)
    [void]$lines.Add('- **独立性**: 不依赖 ESFramework')
    [void]$lines.Add('- **项目类型**: ' + $primaryKind)
    [void]$lines.Add('- **类型标签**: ' + ($profileKinds -join ', '))
    if ($profileObj -and $profileObj.humanSummary) {
        [void]$lines.Add('- **分析摘要**: ' + [string]$profileObj.humanSummary)
    }
    [void]$lines.Add('- **汇总**: 合计=' + $arr.Count + ' 已完成=' + $done + ' 待办=' + $todo + ' 待审=' + $review)
    [void]$lines.Add('')
    [void]$lines.Add('## 日常用法')
    [void]$lines.Add('')
    [void]$lines.Add('```powershell')
    [void]$lines.Add('. .\ES\Automation\ABCD\Use-ESABCD.ps1')
    [void]$lines.Add('Invoke-ESABCDQuick -Requirement "your goal"')
    [void]$lines.Add('```')
    [void]$lines.Add('')
    [void]$lines.Add('## 可对 AI 说（复制）')
    [void]$lines.Add('')
    [void]$lines.Add('> 把 es-abcd 装进本项目并刷新适配清单（路径用我提供的绝对路径）。')
    [void]$lines.Add('')
    [void]$lines.Add('## 检查项')
    [void]$lines.Add('')
    [void]$lines.Add('| 编号 | 状态 | 标题 | 行动 |')
    [void]$lines.Add('|------|------|------|------|')
    foreach ($c in $arr) {
        $action = ([string]$c.action).Replace('|', '/')
        [void]$lines.Add('| `' + $c.id + '` | **' + $c.status + '** | ' + $c.title + ' | ' + $action + ' |')
    }
    [void]$lines.Add('')
    [void]$lines.Add('## 状态说明')
    [void]$lines.Add('')
    [void]$lines.Add('- **done**: 已满足')
    [void]$lines.Add('- **todo**: 必须做')
    [void]$lines.Add('- **review**: 需你或 AI 判断')
    [void]$lines.Add('- **optional**: 可选')
    [void]$lines.Add('- **info**: 边界说明')
    [void]$lines.Add('')
    [void]$lines.Add('## 非声明')
    [void]$lines.Add('')
    [void]$lines.Add('本清单与冒烟 **不等于** Unity PlayMode / 发版验收。runtime-not-run 表示缺少运行时证据，不是静态失败。')
    $mdPath = Join-Path $outDir ('adapt-checklist-' + $stamp + '.md')
    [IO.File]::WriteAllText($mdPath, ($lines -join "`r`n"), [Text.UTF8Encoding]::new($false))
}

Write-Host 'ESABCD adapt checklist written'
Write-Host ('  json: ' + $jsonPath)
if ($mdPath) { Write-Host ('  md  : ' + $mdPath) }

# Avoid StrictMode issues when nothing matched
$result = [pscustomobject]@{
    status   = 'passed'
    jsonPath = $jsonPath
    mdPath   = $(if ($mdPath) { $mdPath } else { '' })
    summary  = $doc.summary
}
$result | ConvertTo-Json -Depth 5 
