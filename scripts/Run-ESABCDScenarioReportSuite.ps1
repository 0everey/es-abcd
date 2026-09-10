# Live multi-mode scenario runner (PS 5.1 safe). UTF-8 BOM required.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$PackageRoot = 'F:\aaProject\es-abcd'
$ScratchRoot = 'C:\Users\asus\AppData\Local\Temp\grok-goal-3e6ad67d1519\implementer\abcd-scenario-runs'
$ReceiptDir = Join-Path $ScratchRoot 'receipts'
$TranscriptDir = Join-Path $ScratchRoot 'transcripts'
$MdOut = 'F:\aaProject\es-abcd\docs\scenario-run-reports'
$TrialRoot = Join-Path $env:TEMP 'es-abcd-goal-scenario-suite'
$utf8 = New-Object System.Text.UTF8Encoding $false

New-Item -ItemType Directory -Force -Path $ReceiptDir, $TranscriptDir, $MdOut | Out-Null
$logPath = Join-Path $TranscriptDir ('suite-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.log')

function Log([string]$m) {
    $line = '[{0}] {1}' -f (Get-Date -Format 'o'), $m
    Add-Content -LiteralPath $logPath -Value $line -Encoding UTF8
    Write-Host $line
}

function Write-JsonFile([string]$Path, $Object) {
    $json = $Object | ConvertTo-Json -Depth 12
    [IO.File]::WriteAllText($Path, $json, $utf8)
}

function Write-MdFile([string]$Path, [string]$Text) {
    [IO.File]::WriteAllText($Path, $Text, $utf8)
}

Log "BEGIN package=$PackageRoot trial=$TrialRoot"

# Install if needed
$divPath = Join-Path $TrialRoot 'ES\Automation\ABCD\ESABCDDivergence.psm1'
if (-not (Test-Path -LiteralPath $divPath)) {
    if (Test-Path -LiteralPath $TrialRoot) { Remove-Item -LiteralPath $TrialRoot -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $TrialRoot | Out-Null
    Log 'INSTALL get.ps1'
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PackageRoot 'get.ps1') -TargetRoot $TrialRoot -Force *>&1 |
        ForEach-Object { Log ('GET ' + $_); $_ } | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "get.ps1 failed $LASTEXITCODE" }
} else {
    Log 'REUSE trial'
}

$homeMod = Join-Path $TrialRoot 'ES\Automation\ABCD\ESABCDHome.psm1'
$divMod = Join-Path $TrialRoot 'ES\Automation\ABCD\ESABCDDivergence.psm1'
$runMod = Join-Path $TrialRoot 'ES\Automation\ABCD\ESABCInnovationRun.psm1'
$contract = Join-Path $TrialRoot 'ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json'
Import-Module $homeMod -Force -Global
Import-Module $divMod -Force -Global
Import-Module $runMod -Force -Global
$env:ES_ABCD_GOVERNANCE_MODE = 'portable'
$sourceHash = (Get-FileHash -LiteralPath $contract -Algorithm SHA256).Hash.ToLowerInvariant()
Log "sourceHash=$sourceHash"

$P = $TrialRoot
$scenarios = @(
    [pscustomobject]@{ id = 'T-ENG-01'; mode = 'engineering'; title = 'Design skill system'; requirement = "项目 $P。用工程模式。目标：设计一套可扩展的技能系统（主动/被动/冷却/消耗/等级）。要求：说清模块边界、数据归谁管、和战斗结算怎么接、禁止两套技能并行。交付：方案要点 + 风险 + 还不能宣称已实装/已平衡。" }
    [pscustomobject]@{ id = 'T-ENG-02'; mode = 'engineering'; title = 'Growth and economy'; requirement = "项目 $P。用工程模式。目标：设计角色成长与货币经济（经验、金币、商店、掉落）。要求：所有权、防刷、存档边界、任务奖励统一。交付：结构 + 失败案例 + 未验证项。" }
    [pscustomobject]@{ id = 'T-ENG-03'; mode = 'engineering'; title = 'Bulk item pipeline'; requirement = "项目 $P。用工程模式。目标：建立大量道具制作与入库管线（模板、命名、表字段、校验、批量生成）。要求：一条正式入口、禁止旁路、坏数据拒绝。交付：管线步骤 + 验收标准。" }
    [pscustomobject]@{ id = 'T-ENG-04'; mode = 'engineering'; title = 'Combat settle loop'; requirement = "项目 $P。用工程模式。目标：收口攻击到命中到伤害到死亡到复用的唯一闭环。要求：唯一入口、禁旁路扣血、重复命中策略、池化重置。交付：链路 + 缺口 + 运行时未验。" }
    [pscustomobject]@{ id = 'T-CRE-01'; mode = 'creative-divergence'; title = 'Melee skill feel'; requirement = "项目 $P。用创意模式。目标：为近战爆发技能给出至少5种不同手感方向。要求：差异大；每方案卖点+硬伤。交付：多方案列表+尝试顺序。" }
    [pscustomobject]@{ id = 'T-CRE-02'; mode = 'creative-divergence'; title = 'Daily play loops'; requirement = "项目 $P。用创意模式。目标：采集-合成-战备-出击的5种日活循环。要求：硬核/休闲/社交；吸引谁烦谁。交付：5循环。" }
    [pscustomobject]@{ id = 'T-CRE-03'; mode = 'creative-divergence'; title = 'Item category matrix'; requirement = "项目 $P。用创意模式。目标：5套道具品类矩阵（不改底层背包）。要求：命名、稀有度、经济钩子。交付：5矩阵+样例建议。" }
    [pscustomobject]@{ id = 'T-CRE-04'; mode = 'creative-divergence'; title = 'Boss fight variants'; requirement = "项目 $P。用创意模式。目标：同一Boss五种战法。要求：机制/叙事/解谜/配队/Roguelike。交付：5战法卡。" }
    [pscustomobject]@{ id = 'T-STA-01'; mode = 'stable'; title = 'Extend skill table'; requirement = "项目 $P。用稳定模式。目标：技能表扩展10个新技能不改老语义。要求：存档兼容、命名、默认字段、回滚。交付：步骤+回归表。" }
    [pscustomobject]@{ id = 'T-STA-02'; mode = 'stable'; title = 'Bulk item import'; requirement = "项目 $P。用稳定模式。目标：安全导入道具表。要求：校验去重失败隔离部分成功。交付：导入规程。" }
    [pscustomobject]@{ id = 'T-STA-03'; mode = 'stable'; title = 'Event config switch'; requirement = "项目 $P。用稳定模式。目标：活动开关配置下发不影响日常关卡。要求：默认关可回退可追日志。交付：开关方案。" }
    [pscustomobject]@{ id = 'T-STA-04'; mode = 'stable'; title = 'Old level bugfix'; requirement = "项目 $P。用稳定模式。目标：修老关卡卡死不毁档。要求：最小改动兼容中途玩家。交付：修复+风险。" }
)

$all = New-Object System.Collections.ArrayList

foreach ($sc in $scenarios) {
    $id = [string]$sc.id
    $mode = [string]$sc.mode
    $title = [string]$sc.title
    $req = [string]$sc.requirement
    Log "RUN $id $mode"

    $status = 'failed'
    $errorText = $null
    $directionCount = $null
    $selectedDirectionId = $null
    $selectedAxis = $null
    $selectionStatus = $null
    $selectionPolicy = $null
    $claimLevel = $null
    $divergenceStatus = $null
    $candidateSetHash = $null
    $recommendedDirectionId = $null
    $rejectedCount = $null
    $hiddenCount = $null
    $auditDeferred = $null
    $qualityStatus = $null
    $dirRows = New-Object System.Collections.ArrayList
    $rankRows = New-Object System.Collections.ArrayList
    $started = [DateTime]::UtcNow.ToString('o')

    try {
        $div = Invoke-ESABCModeDivergence -Requirement $req -SourceHash $sourceHash -Mode $mode -ProjectRoot $TrialRoot
        $sel = Select-ESABCGenerationCandidate -Candidates $div.directions -Mode $mode

        $directionCount = [int]$div.directionCount
        $selectedDirectionId = [string]$sel.selectedDirectionId
        $selectionStatus = [string]$sel.selectionStatus
        $claimLevel = [string]$sel.claimLevel
        $divergenceStatus = [string]$div.status
        $candidateSetHash = [string]$div.candidateSetHash
        if ($null -ne $div.PSObject.Properties['selectionPolicy']) {
            $selectionPolicy = [string]$div.selectionPolicy
        }
        if ($null -ne $sel.PSObject.Properties['recommendedDirectionId']) {
            $recommendedDirectionId = [string]$sel.recommendedDirectionId
        }
        $rejectedCount = @($sel.rejectedCandidates).Count
        $hiddenCount = @($sel.hiddenCandidates).Count
        if ($null -ne $sel.PSObject.Properties['auditDeferred']) {
            $auditDeferred = [bool]$sel.auditDeferred
        }
        if ($null -ne $sel.PSObject.Properties['qualityStatus']) {
            $qualityStatus = [string]$sel.qualityStatus
        }

        foreach ($d in @($div.directions)) {
            $did = [string]$d.directionId
            $ax = [string]$d.axis
            [void]$dirRows.Add([pscustomobject]@{ directionId = $did; axis = $ax })
            if ($did -eq $selectedDirectionId) { $selectedAxis = $ax }
        }

        $ri = 0
        foreach ($r in @($sel.ranked)) {
            $ri++
            $c = $r
            if ($null -ne $r.PSObject.Properties['candidate'] -and $null -ne $r.candidate) { $c = $r.candidate }
            $scv = $null
            if ($null -ne $r.PSObject.Properties['totalScore']) { $scv = $r.totalScore }
            elseif ($null -ne $r.PSObject.Properties['rankScore']) { $scv = $r.rankScore }
            [void]$rankRows.Add([pscustomobject]@{
                    rank         = $ri
                    directionId  = [string]$c.directionId
                    axis         = [string]$c.axis
                    score        = $scv
                })
        }

        $status = 'passed'
        Log "OK $id selected=$selectedDirectionId axis=$selectedAxis n=$directionCount"
    }
    catch {
        $errorText = $_.Exception.Message
        if ($_.Exception.InnerException) {
            $errorText = $errorText + ' | inner=' + $_.Exception.InnerException.Message
        }
        $errorText = $errorText + ' | ' + $_.ScriptStackTrace
        Log "FAIL $id $errorText"
    }

    $finished = [DateTime]::UtcNow.ToString('o')
    $receipt = [pscustomobject]@{
        schemaVersion            = 1
        testId                   = $id
        title                    = $title
        mode                     = $mode
        requirement              = $req
        packageRoot              = $PackageRoot
        trialRoot                = $TrialRoot
        contractPath             = $contract
        sourceHash               = $sourceHash
        startedUtc               = $started
        finishedUtc              = $finished
        status                   = $status
        error                    = $errorText
        entryPoint               = 'Invoke-ESABCModeDivergence+Select-ESABCGenerationCandidate'
        directionCount           = $directionCount
        directions               = @($dirRows.ToArray())
        selectedDirectionId      = $selectedDirectionId
        selectedAxis             = $selectedAxis
        selectionStatus          = $selectionStatus
        selectionPolicy          = $selectionPolicy
        claimLevel               = $claimLevel
        divergenceStatus         = $divergenceStatus
        candidateSetHash         = $candidateSetHash
        recommendedDirectionId   = $recommendedDirectionId
        ranked                   = @($rankRows.ToArray())
        rejectedCandidatesCount  = $rejectedCount
        hiddenCandidatesCount    = $hiddenCount
        auditDeferred            = $auditDeferred
        qualityStatus            = $qualityStatus
        runtimeStatus            = 'runtime-not-run'
    }
    [void]$all.Add($receipt)

    $jsonPath = Join-Path $ReceiptDir ($id + '.json')
    Write-JsonFile $jsonPath $receipt

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("# $id — $title")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('> 仅由本场 live 回执生成；禁止手填 cand-*。')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## 元数据')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| 字段 | 值 |')
    [void]$sb.AppendLine('|------|-----|')
    [void]$sb.AppendLine("| testId | ``$id`` |")
    [void]$sb.AppendLine("| title | $title |")
    [void]$sb.AppendLine("| mode | ``$mode`` |")
    [void]$sb.AppendLine("| status | **$status** |")
    [void]$sb.AppendLine("| entryPoint | ``Invoke-ESABCModeDivergence+Select-ESABCGenerationCandidate`` |")
    [void]$sb.AppendLine("| packageRoot | ``$PackageRoot`` |")
    [void]$sb.AppendLine("| trialRoot | ``$TrialRoot`` |")
    [void]$sb.AppendLine("| contractPath | ``$contract`` |")
    [void]$sb.AppendLine("| sourceHash | ``$sourceHash`` |")
    [void]$sb.AppendLine("| receiptJson | ``$jsonPath`` |")
    [void]$sb.AppendLine("| startedUtc | $started |")
    [void]$sb.AppendLine("| finishedUtc | $finished |")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## 需求原文')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('```text')
    [void]$sb.AppendLine($req)
    [void]$sb.AppendLine('```')
    [void]$sb.AppendLine('')

    if ($status -ne 'passed') {
        [void]$sb.AppendLine('## 失败（真实错误）')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('```text')
        [void]$sb.AppendLine([string]$errorText)
        [void]$sb.AppendLine('```')
    }
    else {
        [void]$sb.AppendLine('## 选择结果（live）')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('| 字段 | 值 |')
        [void]$sb.AppendLine('|------|-----|')
        [void]$sb.AppendLine("| directionCount | $directionCount |")
        [void]$sb.AppendLine("| selectedDirectionId | ``$selectedDirectionId`` |")
        [void]$sb.AppendLine("| selectedAxis | ``$selectedAxis`` |")
        [void]$sb.AppendLine("| selectionStatus | ``$selectionStatus`` |")
        [void]$sb.AppendLine("| selectionPolicy | ``$selectionPolicy`` |")
        [void]$sb.AppendLine("| claimLevel | ``$claimLevel`` |")
        [void]$sb.AppendLine("| divergenceStatus | ``$divergenceStatus`` |")
        [void]$sb.AppendLine("| candidateSetHash | ``$candidateSetHash`` |")
        [void]$sb.AppendLine("| recommendedDirectionId | ``$recommendedDirectionId`` |")
        [void]$sb.AppendLine("| rejectedCandidatesCount | $rejectedCount |")
        [void]$sb.AppendLine("| hiddenCandidatesCount | $hiddenCount |")
        [void]$sb.AppendLine("| auditDeferred | $auditDeferred |")
        [void]$sb.AppendLine("| qualityStatus | ``$qualityStatus`` |")
        [void]$sb.AppendLine("| runtimeStatus | ``runtime-not-run`` |")
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('## 本场全部方向')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('| # | directionId | axis |')
        [void]$sb.AppendLine('|---|-------------|------|')
        $di = 0
        foreach ($d in $dirRows) {
            $di++
            $mark = ''
            if ([string]$d.directionId -eq $selectedDirectionId) { $mark = ' **SELECTED**' }
            [void]$sb.AppendLine("| $di | ``$($d.directionId)``$mark | ``$($d.axis)`` |")
        }
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('## ranked')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('| rank | directionId | axis | score |')
        [void]$sb.AppendLine('|------|-------------|------|-------|')
        foreach ($r in $rankRows) {
            [void]$sb.AppendLine("| $($r.rank) | ``$($r.directionId)`` | ``$($r.axis)`` | $($r.score) |")
        }
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('## 说明')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine("- rejectedCandidatesCount=$rejectedCount（落选在 ranked，不等于否决书）。")
        [void]$sb.AppendLine('- claimLevel=design-candidate；runtime-not-run：非 PlayMode/发版。')
    }

    $mdPath = Join-Path $MdOut ($id + '.md')
    Write-MdFile $mdPath $sb.ToString()
    Log "WROTE $mdPath"
}

# Comparison from $all only
$cmp = New-Object System.Text.StringBuilder
[void]$cmp.AppendLine('# 三模式场景实测对比（仅来自 numbered 回执）')
[void]$cmp.AppendLine('')
[void]$cmp.AppendLine('> generatedUtc: ' + [DateTime]::UtcNow.ToString('o'))
[void]$cmp.AppendLine('>')
[void]$cmp.AppendLine('> trialRoot: `' + $TrialRoot + '`')
[void]$cmp.AppendLine('>')
[void]$cmp.AppendLine('> packageRoot: `' + $PackageRoot + '`')
[void]$cmp.AppendLine('>')
[void]$cmp.AppendLine('> 表中 cand-* 仅来自本场 receipts，禁止手改。')
[void]$cmp.AppendLine('')
[void]$cmp.AppendLine('## 汇总表')
[void]$cmp.AppendLine('')
[void]$cmp.AppendLine('| testId | mode | status | directionCount | selectedDirectionId | selectedAxis | selectionStatus | selectionPolicy | claimLevel | candidateSetHash |')
[void]$cmp.AppendLine('|--------|------|--------|----------------|---------------------|--------------|-----------------|-----------------|------------|------------------|')
foreach ($r in $all) {
    [void]$cmp.AppendLine("| ``$($r.testId)`` | ``$($r.mode)`` | **$($r.status)** | $($r.directionCount) | ``$($r.selectedDirectionId)`` | ``$($r.selectedAxis)`` | ``$($r.selectionStatus)`` | ``$($r.selectionPolicy)`` | ``$($r.claimLevel)`` | ``$($r.candidateSetHash)`` |")
}
[void]$cmp.AppendLine('')
[void]$cmp.AppendLine('## 按模式')
[void]$cmp.AppendLine('')
foreach ($g in ($all | Group-Object mode)) {
    [void]$cmp.AppendLine('### `' + $g.Name + '`')
    [void]$cmp.AppendLine('')
    $pc = @($g.Group | Where-Object { $_.status -eq 'passed' }).Count
    $fc = @($g.Group | Where-Object { $_.status -ne 'passed' }).Count
    [void]$cmp.AppendLine("- 场次=$($g.Count) passed=$pc failed=$fc")
    $counts = @($g.Group | Where-Object { $null -ne $_.directionCount } | ForEach-Object { $_.directionCount } | Select-Object -Unique)
    if ($counts.Count -gt 0) { [void]$cmp.AppendLine('- directionCount: ' + ($counts -join ', ')) }
    $axes = @($g.Group | Where-Object { $_.selectedAxis } | ForEach-Object { $_.selectedAxis } | Select-Object -Unique)
    if ($axes.Count -gt 0) { [void]$cmp.AppendLine('- 当选 axis: ' + (($axes | ForEach-Object { '`' + $_ + '`' }) -join ', ')) }
    $ss = @($g.Group | Where-Object { $_.selectionStatus } | ForEach-Object { $_.selectionStatus } | Select-Object -Unique)
    if ($ss.Count -gt 0) { [void]$cmp.AppendLine('- selectionStatus: ' + (($ss | ForEach-Object { '`' + $_ + '`' }) -join ', ')) }
    [void]$cmp.AppendLine('')
}
[void]$cmp.AppendLine('## 证据索引')
[void]$cmp.AppendLine('')
[void]$cmp.AppendLine('| testId | receipt | md |')
[void]$cmp.AppendLine('|--------|---------|-----|')
foreach ($r in $all) {
    $jp = Join-Path $ReceiptDir ($r.testId + '.json')
    $mp = Join-Path $MdOut ($r.testId + '.md')
    [void]$cmp.AppendLine("| ``$($r.testId)`` | ``$jp`` | ``$mp`` |")
}
[void]$cmp.AppendLine('')
[void]$cmp.AppendLine('## 非声明')
[void]$cmp.AppendLine('')
[void]$cmp.AppendLine('- design-candidate / runtime-not-run only')
[void]$cmp.AppendLine('- not Unity PlayMode / release')

$cmpPath = Join-Path $MdOut 'COMPARISON-modes-live.md'
Write-MdFile $cmpPath $cmp.ToString()
Log "WROTE $cmpPath"

$passN = @($all | Where-Object { $_.status -eq 'passed' }).Count
$failN = @($all | Where-Object { $_.status -ne 'passed' }).Count
$index = [pscustomobject]@{
    generatedUtc  = [DateTime]::UtcNow.ToString('o')
    trialRoot     = $TrialRoot
    packageRoot   = $PackageRoot
    logPath       = $logPath
    comparisonMd  = $cmpPath
    passedCount   = $passN
    failedCount   = $failN
    tests         = @($all | ForEach-Object {
            [pscustomobject]@{
                testId              = $_.testId
                status              = $_.status
                mode                = $_.mode
                selectedDirectionId = $_.selectedDirectionId
                selectedAxis        = $_.selectedAxis
                directionCount      = $_.directionCount
                selectionStatus     = $_.selectionStatus
                claimLevel          = $_.claimLevel
                candidateSetHash    = $_.candidateSetHash
                receipt             = (Join-Path $ReceiptDir ($_.testId + '.json'))
                md                  = (Join-Path $MdOut ($_.testId + '.md'))
            }
        })
}
Write-JsonFile (Join-Path $ScratchRoot 'suite-index.json') $index
Log "DONE passed=$passN failed=$failN"
$index | ConvertTo-Json -Depth 6
if ($failN -gt 0) { exit 2 }
