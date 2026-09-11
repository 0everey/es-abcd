# Commercial markdown formatter only. Axis card-packs REMOVED (P0: LLM divergence only).
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Format-ESABCDCommercialMarkdown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Selection,
        [Parameter(Mandatory)]$Divergence,
        [Parameter(Mandatory)][string]$Requirement
    )
    $sb2 = New-Object System.Text.StringBuilder
    $kind = [string]$Selection.deliveryKind
    $level = [string]$Selection.pipelineLevel
    $domain = [string]$Selection.domain
    $mode = [string]$Selection.mode
    $engine = [string]$Divergence.iterationTraceKind
    $src = [string]$Divergence.contentSource
    if ([string]::IsNullOrWhiteSpace($src)) { $src = 'llm-model' }
    [void]$sb2.AppendLine('# ABCD 商用交付简报（大模型发散 + 编排收口）')
    [void]$sb2.AppendLine('')
    [void]$sb2.AppendLine("> 生成 UTC: $([DateTime]::UtcNow.ToString('o'))")
    [void]$sb2.AppendLine("> deliveryKind=**$kind** · pipelineLevel=**$level** · domain=**$domain** · mode=**$mode**")
    [void]$sb2.AppendLine("> contentSource=**$src** · engine=**$engine**")
    [void]$sb2.AppendLine("> claim=**$([string]$Selection.claimLevel)** · runtime=**runtime-not-run**")
    [void]$sb2.AppendLine('')
    [void]$sb2.AppendLine('## 需求')
    [void]$sb2.AppendLine('')
    [void]$sb2.AppendLine($Requirement)
    [void]$sb2.AppendLine('')
    [void]$sb2.AppendLine('## 怎么读')
    [void]$sb2.AppendLine('')
    [void]$sb2.AppendLine('- 正文来自大模型按轴**自由发散**；ABCD 负责多向、排序、claim、中文回执收口。')
    [void]$sb2.AppendLine('- **禁止**把本文当成已平衡/已实装/可发版证明。')
    [void]$sb2.AppendLine('- 预制卡组路径已删除（P0）；无模型密钥时必须失败，不得静默填肉。')
    [void]$sb2.AppendLine('')

    if ($null -ne $Selection.domainBrief) {
        $db = $Selection.domainBrief
        [void]$sb2.AppendLine('## 领域简报')
        [void]$sb2.AppendLine('')
        if ($null -ne $db.PSObject.Properties['summary']) {
            [void]$sb2.AppendLine([string]$db.summary)
            [void]$sb2.AppendLine('')
        }
        if ($domain -eq 'live-ops-loop' -and $null -ne $db.loops) {
            [void]$sb2.AppendLine('| # | 环名 | 倾向 | 吸引谁 | 烦谁 | 采集 | 合成 | 战备 | 出击 | 透镜 |')
            [void]$sb2.AppendLine('|---|------|------|--------|------|------|------|------|------|------|')
            foreach ($loop in @($db.loops)) {
                $row = '| {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} | {8} | {9} |' -f `
                    $loop.loopIndex, $loop.name, $loop.tilt, $loop.attractWho, $loop.annoyWho, `
                    $loop.gather, $loop.craft, $loop.prep, $loop.sortie, $loop.groundedAxis
                [void]$sb2.AppendLine($row)
            }
            [void]$sb2.AppendLine('')
        }
        if ($null -ne $db.PSObject.Properties['cards'] -and $null -ne $db.cards) {
            $ci = 0
            foreach ($card in @($db.cards)) {
                $ci++
                [void]$sb2.AppendLine("### 方案卡 $ci · $($card.title)")
                [void]$sb2.AppendLine('')
                [void]$sb2.AppendLine("- **卖点**: $($card.pitch)")
                [void]$sb2.AppendLine("- **场景**: $($card.scenario)")
                [void]$sb2.AppendLine("- **输入**: $($card.inputSequence)")
                [void]$sb2.AppendLine("- **反馈**: $($card.visibleFeedback)")
                [void]$sb2.AppendLine("- **机制**: $($card.novelMechanism)")
                [void]$sb2.AppendLine("- **风险**: $($card.risk)")
                [void]$sb2.AppendLine('')
            }
        }
    }

    [void]$sb2.AppendLine('## 透镜排序（模型发散结果）')
    [void]$sb2.AppendLine('')
    [void]$sb2.AppendLine('| 序 | 轴 | 中文 | 分数 | directionId | 一句话 |')
    [void]$sb2.AppendLine('|----|----|------|------|------------|--------|')
    $rank = 0
    foreach ($row in @($Selection.ranked)) {
        $rank++
        $c = if ($null -ne $row.candidate) { $row.candidate } else { $row }
        $axis = [string]$c.axis
        $zh = if ($null -ne $c.PSObject.Properties['axisZh']) { [string]$c.axisZh } else { $axis }
        $pitch = if ($null -ne $c.PSObject.Properties['productPitch']) { [string]$c.productPitch } else { '' }
        $id = [string]$c.directionId
        $score = $row.rankScore
        $mark = if ($rank -eq 1) { '★' } else { '' }
        [void]$sb2.AppendLine("| $rank$mark | $axis | $zh | $score | ``$id`` | $pitch |")
    }
    [void]$sb2.AppendLine('')

    $top = @($Selection.ranked)[0]
    if ($null -ne $top) {
        $tc = if ($null -ne $top.candidate) { $top.candidate } else { $top }
        [void]$sb2.AppendLine('## 主推荐展开')
        [void]$sb2.AppendLine('')
        [void]$sb2.AppendLine("- **轴**: $($tc.axis) / $(if($tc.axisZh){$tc.axisZh}else{''})")
        [void]$sb2.AppendLine("- **内容来源**: $(if($tc.contentSource){$tc.contentSource}else{'llm-model'})")
        [void]$sb2.AppendLine("- **场景**: $($tc.concretePlayerScenario)")
        [void]$sb2.AppendLine("- **输入序列**: $($tc.inputSequence)")
        [void]$sb2.AppendLine("- **可见反馈**: $($tc.visibleFeedback)")
        [void]$sb2.AppendLine("- **新机制**: $($tc.novelMechanism)")
        [void]$sb2.AppendLine("- **假设**: $($tc.assumption)")
        [void]$sb2.AppendLine("- **风险**: $($tc.risk)")
        [void]$sb2.AppendLine('')
        if ($null -ne $tc.keptMutations) {
            [void]$sb2.AppendLine('### 模型分支保留')
            [void]$sb2.AppendLine('')
            foreach ($k in @($tc.keptMutations)) {
                [void]$sb2.AppendLine("- 第$($k.round)轮 **$($k.title)**：$($k.change)（$($k.score)）")
            }
            [void]$sb2.AppendLine('')
        }
    }

    [void]$sb2.AppendLine('## 其它方向')
    [void]$sb2.AppendLine('')
    $ri = 0
    foreach ($row in @($Selection.ranked)) {
        $ri++
        if ($ri -eq 1) { continue }
        $c = if ($null -ne $row.candidate) { $row.candidate } else { $row }
        [void]$sb2.AppendLine("### $ri. $($c.axis) $(if($c.axisZh){'· '+$c.axisZh})")
        [void]$sb2.AppendLine('')
        [void]$sb2.AppendLine("- $($c.productPitch)")
        [void]$sb2.AppendLine("- 场景: $($c.concretePlayerScenario)")
        [void]$sb2.AppendLine("- 机制: $($c.novelMechanism)")
        [void]$sb2.AppendLine('')
    }

    [void]$sb2.AppendLine('## 机器元数据')
    [void]$sb2.AppendLine('')
    [void]$sb2.AppendLine("- directionCount: $($Divergence.directionCount)")
    [void]$sb2.AppendLine("- candidateSetHash: ``$($Divergence.candidateSetHash)``")
    [void]$sb2.AppendLine("- selectedDirectionId: ``$($Selection.selectedDirectionId)``")
    [void]$sb2.AppendLine("- contentSource: $src")
    [void]$sb2.AppendLine("- engine: $engine")
    [void]$sb2.AppendLine('')
    [void]$sb2.AppendLine('---')
    [void]$sb2.AppendLine('*es-abcd · LLM divergence · ABCD audit collapse · design-candidate*')
    return $sb2.ToString()
}

function Invoke-ESABCDCommercial {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Requirement,
        [ValidateSet('engineering','creative-divergence','stable')][string]$Mode = 'creative-divergence',
        [string]$ProjectRoot = '',
        [string]$OutDir = '',
        [scriptblock]$ModelInvoker = $null
    )
    Import-Module (Join-Path $PSScriptRoot 'ESABCDHome.psm1') -Force -Global
    Import-Module (Join-Path $PSScriptRoot 'ESABCDIndex.psm1') -Force -Global
    return Invoke-ESABCD -Requirement $Requirement -Mode $Mode -ProjectRoot $ProjectRoot -OutDir $OutDir -Output brief -ModelInvoker $ModelInvoker
}

Export-ModuleMember -Function @(
    'Format-ESABCDCommercialMarkdown',
    'Invoke-ESABCDCommercial'
)
