# 一键试验沙箱：让路人 5 分钟体验「分析 → 接入 → 可复制场景」
# 用法：
#   powershell -File .\scripts\Start-ESABCDTrial.ps1
#   powershell -File .\scripts\Start-ESABCDTrial.ps1 -TrialRoot <试验目录>
[CmdletBinding()]
param(
    [string]$TrialRoot = '',
    [string]$PackageRoot = ''
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ([string]::IsNullOrWhiteSpace($PackageRoot)) {
    $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
    $PackageRoot = (Resolve-Path (Join-Path $scriptDir '..')).Path
} else {
    $PackageRoot = (Resolve-Path -LiteralPath $PackageRoot).Path
}

$get = Join-Path $PackageRoot 'get.ps1'
if (-not (Test-Path -LiteralPath $get)) {
    throw "找不到 get.ps1，请在 es-abcd 仓库内运行。PackageRoot=$PackageRoot"
}

if ([string]::IsNullOrWhiteSpace($TrialRoot)) {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $TrialRoot = Join-Path $env:LOCALAPPDATA ("es-abcd\trial-" + $stamp)
}
$TrialRoot = [IO.Path]::GetFullPath($TrialRoot)
if (-not (Test-Path -LiteralPath $TrialRoot)) {
    New-Item -ItemType Directory -Force -Path $TrialRoot | Out-Null
}

Write-Host ''
Write-Host '======== es-abcd 试验沙箱 ========' -ForegroundColor White
Write-Host ('  包目录   : ' + $PackageRoot)
Write-Host ('  试验项目 : ' + $TrialRoot)
Write-Host '==================================' -ForegroundColor White
Write-Host ''

& powershell -NoProfile -ExecutionPolicy Bypass -File $get -TargetRoot $TrialRoot -Force
if ($LASTEXITCODE -ne 0) {
    throw "试验安装失败，exit=$LASTEXITCODE"
}

$outDir = Join-Path $TrialRoot 'ES\Automation\ABCD\out'
$profilePath = Join-Path $outDir 'project-profile.json'
$checklist = @(Get-ChildItem -LiteralPath $outDir -Filter 'adapt-checklist-*.md' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1)
$oneclick = @(Get-ChildItem -LiteralPath $outDir -Filter 'oneclick-*.json' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1)

$kind = 'unknown'
if (Test-Path -LiteralPath $profilePath) {
    try {
        $prof = Get-Content -LiteralPath $profilePath -Raw -Encoding UTF8 | ConvertFrom-Json
        $kind = [string]$prof.primaryKind
    } catch { }
}

# 路径已填好的「下一段给 AI」话术
$aiNext = @"
试验项目已经装好 es-abcd。

es-abcd 根路径：$PackageRoot
项目根路径：$TrialRoot
项目类型（画像）：$kind

请用人话确认安装结果，并打开适配清单说明还要我拍板什么。
然后用**工程模式**跑下面场景（不要改我的路径）：

项目 $TrialRoot。用工程模式。
目标：设计一套可扩展的技能系统（主动/被动/冷却/消耗/等级）。
要求：说清模块边界、数据归谁管、和战斗结算怎么接、禁止两套技能并行。
交付：方案要点 + 风险 + 还不能宣称已实装/已平衡。
"@

$aiPath = Join-Path $outDir '下一步-发给AI.txt'
$utf8bom = New-Object System.Text.UTF8Encoding $true
[IO.File]::WriteAllText($aiPath, $aiNext.Trim() + "`r`n", $utf8bom)

Write-Host ''
Write-Host '======== 试验完成：把下面整段复制给 AI ========' -ForegroundColor Green
Write-Host $aiNext
Write-Host '================================================' -ForegroundColor Green
Write-Host ''
Write-Host ('已写入: ' + $aiPath)
if ($checklist) { Write-Host ('清单  : ' + $checklist.FullName) }
if ($oneclick) { Write-Host ('回执  : ' + $oneclick.FullName) }
Write-Host ('画像  : ' + $profilePath)
Write-Host ''
Write-Host '完整场景表见仓库 README；试用说明见 开始试用.md'
Write-Host ''

[pscustomobject]@{
    status           = 'passed'
    packageRoot      = $PackageRoot
    trialRoot        = $TrialRoot
    projectKind      = $kind
    pasteToAiFile    = $aiPath
    checklistPath    = $(if ($checklist) { $checklist.FullName } else { $null })
    profilePath      = $profilePath
    runtimeStatus    = 'runtime-not-run'
} | ConvertTo-Json -Depth 5 
