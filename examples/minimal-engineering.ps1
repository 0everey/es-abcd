# 最小 engineering 发散示例（请先 Install-ESABCD 到目标项目）
# 用法：
#   powershell -File examples/minimal-engineering.ps1 -ProjectRoot C:\path\to\你的项目

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ProjectRoot
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path

Import-Module "$ProjectRoot\ES\Automation\ABCD\ESABCDDivergence.psm1" -Force
Import-Module "$ProjectRoot\ES\Automation\ABCD\ESABCInnovationRun.psm1" -Force

$contract = "$ProjectRoot\ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json"
$hash = (Get-FileHash -LiteralPath $contract -Algorithm SHA256).Hash.ToLowerInvariant()

$requirement = @'
冻结产品三层架构：
(1) 平台域，(2) 定义表，(3) 物理/查询层。
禁止：用物理层表达阵营；新增第四平台域；绕过唯一执行入口。
'@

$div = Invoke-ESABCModeDivergence `
    -Requirement $requirement `
    -SourceHash $hash `
    -Mode engineering `
    -ProjectRoot $ProjectRoot

$sel = Select-ESABCGenerationCandidate -Candidates $div.directions -Mode engineering

Write-Host "方向数=$($div.directionCount) 选中=$($sel.selectedDirectionId)"
Write-Host "claimLevel=$($sel.claimLevel) selectionStatus=$($sel.selectionStatus)"
Write-Host "candidateSetHash=$($div.candidateSetHash)"
Write-Host "runtimeStatus=runtime-not-run（本示例预期如此）" 
