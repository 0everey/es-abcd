# Chinese final receipt. No card-pack generation.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
function ConvertTo-ESABCDChineseReceipt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Selection,
        [Parameter(Mandatory)]$Divergence,
        [Parameter(Mandatory)][string]$Requirement,
        [string]$Entry = 'Invoke-ESABCD'
    )
    $modeZh = switch ([string]$Divergence.mode) {
        'creative-divergence' { '创意发散' }; 'engineering' { '工程' }; 'stable' { '稳定' }; default { [string]$Divergence.mode }
    }
    $deliveryZh = switch ([string]$Selection.deliveryKind) {
        'domain-brief' { '领域简报' }; 'lens-only' { '仅透镜排序' }; default { [string]$Selection.deliveryKind }
    }
    $levelZh = switch ([string]$Selection.pipelineLevel) {
        'L0' { 'L0 透镜层' }; 'L1' { 'L1 领域交付层' }; default { [string]$Selection.pipelineLevel }
    }
    $claimZh = switch -Regex ([string]$Selection.claimLevel) {
        'domain-brief' { '设计候选·领域简报' }
        'template' { '设计候选·透镜模板（正文曾碰撞）' }
        'design-candidate' { '设计候选' }
        'candidate' { '候选' }
        default { [string]$Selection.claimLevel }
    }
    $selZh = switch ([string]$Selection.selectionStatus) {
        'deterministic-selected' { '按规则选定主推荐' }
        'ranked-recommended' { '排序后推荐第一' }
        'collaborator-selected' { '协作者指定' }
        default { [string]$Selection.selectionStatus }
    }
    $engineZh = switch ([string]$Divergence.iterationTraceKind) {
        'llm-axis-divergence-v1' { '大模型轴发散' }
        'real-axis-branch-v1' { '已废除卡组分支（非法）' }
        'synthetic-trace' { '合成轨迹（旧）' }
        default { [string]$Divergence.iterationTraceKind }
    }

    $directionsZh = @()
    $rank = 0
    foreach ($row in @($Selection.ranked)) {
        $rank++
        $c = if ($null -ne $row.candidate) { $row.candidate } else { $row }
        $kept = @()
        if ($null -ne $c.PSObject.Properties['keptMutations'] -and $null -ne $c.keptMutations) {
            $kept = @($c.keptMutations | ForEach-Object { "第$($_.round)轮保留「$($_.title)」：$($_.change)（分=$($_.score)）" })
        }
        $traceSummary = @()
        if ($null -ne $c.iterationTrace) {
            foreach ($tr in @($c.iterationTrace | Where-Object { $_.decision -eq 'keep' })) {
                $title = if ($tr.PSObject.Properties['mutationTitle']) { [string]$tr.mutationTitle } else { [string]$tr.concreteChange }
                $traceSummary += "第$($tr.roundId)轮保留：$title（$($tr.playerAcceptability)分）"
            }
        }
        $directionsZh += [pscustomobject][ordered]@{
            排名 = $rank; 是否主推荐 = ($rank -eq 1); 方向编号 = [string]$c.directionId
            轴 = [string]$c.axis; 轴中文 = [string]$c.axisZh; 一句话卖点 = [string]$c.productPitch
            排序分 = $row.rankScore; 玩家场景 = [string]$c.concretePlayerScenario
            输入序列 = [string]$c.inputSequence; 可见反馈 = [string]$c.visibleFeedback
            新机制 = [string]$c.novelMechanism; 假设 = [string]$c.assumption; 风险 = [string]$c.risk
            可接受性分 = $c.acceptabilityScore; 具体性分 = $c.concretenessScore
            真实分支保留摘要 = $traceSummary; 保留变更列表 = $kept
            发散引擎 = [string]$c.divergenceEngine
        }
    }

    $domainBriefZh = $null
    if ($null -ne $Selection.domainBrief) {
        $db = $Selection.domainBrief
        $loopsZh = $null
        if ($null -ne $db.PSObject.Properties['loops'] -and $null -ne $db.loops) {
            $loopsZh = @($db.loops | ForEach-Object {
                    [pscustomobject][ordered]@{ 序号=$_.loopIndex; 名称=$_.name; 倾向=$_.tilt; 吸引谁=$_.attractWho; 烦谁=$_.annoyWho; 采集=$_.gather; 合成=$_.craft; 战备=$_.prep; 出击=$_.sortie; 接地轴=$_.groundedAxis }
                })
        }
        $cardsZh = $null
        if ($null -ne $db.PSObject.Properties['cards'] -and $null -ne $db.cards) {
            $cardsZh = @($db.cards | ForEach-Object {
                    [pscustomobject][ordered]@{ 标题=$_.title; 卖点=$_.pitch; 场景=$_.scenario; 输入=$_.inputSequence; 反馈=$_.visibleFeedback; 机制=$_.novelMechanism; 风险=$_.risk; 硬伤=$_.hardCost }
                })
        }
        $domainBriefZh = [pscustomobject][ordered]@{ 领域=[string]$db.domain; 摘要=[string]$db.summary; 语言=[string]$db.language; 日活环=$loopsZh; 方案卡=$cardsZh }
    }

    $collisionZh = $null
    if ($null -ne $Selection.templateCollision) {
        $collision = $Selection.templateCollision
        $collisionZh = [pscustomobject][ordered]@{
            是否碰撞 = [bool]$collision.hasCollision
            碰撞对数 = [int]$collision.collisionCount
            状态 = if ([bool]$collision.hasCollision) { '正文模板完全相同（已降级或失败）' } else { '无全文模板碰撞' }
        }
    }

    return [pscustomobject][ordered]@{
        规格版本 = 1; 记录类型 = 'ESABCD中文回执'; 入口 = $Entry
        需求 = $Requirement; 模式 = [string]$Divergence.mode; 模式中文 = $modeZh
        交付种类 = [string]$Selection.deliveryKind; 交付种类中文 = $deliveryZh
        流水线层级 = [string]$Selection.pipelineLevel; 流水线中文 = $levelZh
        领域 = [string]$Selection.domain
        声明级别 = [string]$Selection.claimLevel; 声明级别中文 = $claimZh
        选择状态 = [string]$Selection.selectionStatus; 选择状态中文 = $selZh
        主推荐方向 = [string]$Selection.selectedDirectionId
        方向数量 = [int]$Divergence.directionCount; 候选集哈希 = [string]$Divergence.candidateSetHash
        发散引擎 = [string]$Divergence.iterationTraceKind; 发散引擎中文 = $engineZh
        内容来源 = $(if ($null -ne $Divergence.PSObject.Properties['contentSource']) { [string]$Divergence.contentSource } else { 'llm-model' })
        内容来源中文 = '大模型自由发散'
        真实轮次 = [int]$Divergence.roundCount; 分支次数 = [int]$Divergence.branchCount
        运行时状态 = '运行时未验'
        非声称 = @('未发版','未平衡','未PlayMode','非全面碾压任意AI')
        模板碰撞 = $collisionZh; 领域简报 = $domainBriefZh; 方向列表 = $directionsZh
        说明 = '本回执为中文最终可读层。发散必须来自大模型（contentSource=llm-model）；ABCD 负责排序/claim/审计收口。预制卡组已废除。'
        捕获UTC = [DateTime]::UtcNow.ToString('o')
    }
}


Export-ModuleMember -Function @('ConvertTo-ESABCDChineseReceipt')