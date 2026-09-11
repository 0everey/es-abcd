# LLM-native divergence: model freely writes per-axis candidates; ABCD ranks/claims after.
# Card-pack / mutation-catalog path is intentionally removed (P0).
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ESABCDJsonProp {
    param($Obj, [string]$Name)
    if ($null -eq $Obj) { return $null }
    $p = $Obj.PSObject.Properties | Where-Object { $_.Name -ceq $Name } | Select-Object -First 1
    if ($null -eq $p) { return $null }
    return $p.Value
}
function Get-ESABCDAxisLabelZh {
    param([string]$Axis)
    $map = @{
        'moment-to-moment-feel'='瞬时手感'; 'flow-continuity'='心流连贯'; 'presentation-beat'='表现节拍'
        'expressive-input'='表达型输入'; 'skill-ceiling'='技巧上限'; 'novelty-delta'='新颖度'
        'counterplay-clarity'='反制清晰'; 'mechanic-amplification'='机制放大'
        'state-machine-integrity'='状态机严谨'; 'ownership-lifecycle'='所有权生命周期'; 'determinism'='确定性'
        'performance-peak-budget'='性能峰值预算'; 'failure-recovery'='失败恢复'; 'reuse-surface'='复用面'
        'breakthrough-novelty'='突破点'; 'longevity'='长寿命'; 'counterplay'='对抗与约束'
        'contract-completeness'='合同完备'; 'integration-fit'='集成贴合'; 'compatibility'='兼容性'
        'regression-fixture'='回归夹具'; 'rollback'='可回滚'; 'security-boundary'='安全边界'
        'observability'='可观测'; 'content-throughput'='内容吞吐'; 'complete-loop'='闭环完整'
    }
    $k = $Axis.ToLowerInvariant()
    if ($map.ContainsKey($k)) { return $map[$k] }
    return $Axis
}

function New-ESABCDModelDivergenceSystemPrompt {
    param([string]$Mode)
    $modeZh = switch ($Mode) {
        'creative-divergence' { '创意发散（玩家爽感、表达、上限、反制）' }
        'engineering' { '工程（结构正确、所有权、确定性、恢复、复用）' }
        'stable' { '稳定（兼容、回滚、回归夹具、安全、可观测）' }
        default { $Mode }
    }
    return @"
你是资深游戏系统设计 AI，在 ABCD 编排下做「真实自由发散」。
工作态度模式：$modeZh
硬性要求：
1) 必须针对用户需求与指定设计轴，原创写出具体可讨论方案，禁止空话套模板。
2) 必须输出严格 JSON 对象（不要 Markdown 解释），字段齐全。
3) 每个方向至少给出 4 条真实分支演进（branchTrace），每条含 keep 或 discard 决策与中文理由；keep/discard 必须基于方案质量判断，不能全 keep。
4) 场景、输入、反馈、机制必须互不相同、可执行、贴合需求关键词。
5) claim 只能是设计候选；不要声称已上线/已平衡/已 PlayMode。
6) 全部人读字段用中文。
"@
}

function New-ESABCDModelDivergenceUserPrompt {
    param(
        [string]$Requirement,
        [string]$Mode,
        [string]$Axis,
        [int]$Ordinal,
        [int]$DirectionCount
    )
    $axisZh = Get-ESABCDAxisLabelZh -Axis $Axis
    return @"
【需求】
$Requirement

【本方向】
- ordinal: $Ordinal / $DirectionCount
- axis: $Axis
- axisZhHint: $axisZh
- mode: $Mode

请只输出一个 JSON 对象，schema：
{
  "axis": "$Axis",
  "axisZh": "中文轴名",
  "productPitch": "一句话卖点",
  "concretePlayerScenario": "具体玩家场景（必须回扣需求，禁止空泛）",
  "inputSequence": "输入序列",
  "visibleFeedback": "可见反馈",
  "novelMechanism": "新机制（相对默认做法改了什么）",
  "assumption": "关键假设",
  "risk": "主要风险",
  "acceptabilityScore": 0-100整数,
  "concretenessScore": 0-100整数,
  "modeScores": {
    "delight":0,"smoothness":0,"presentation":0,"skillCeiling":0,"joyLoop":0,"first10sMoment":0,
    "expressionCeiling":0,"noveltyDelta":0,"counterplayClarity":0,
    "depth":0,"breakthrough":0,"reusability":0,"longevity":0,
    "projectFit":0,"completeness":0,"safety":0,"closure":0
  },
  "branchTrace": [
    {
      "roundId": 1,
      "title": "分支标题",
      "concreteChange": "本轮具体改动",
      "decision": "keep|discard",
      "playerAcceptability": 0-100,
      "keepOrDiscardReason": "中文理由"
    }
  ],
  "selfCritique": "两轮内自检与修补要点"
}

branchTrace 至少 4 条，且 keep 与 discard 都要出现。
"@
}

function New-ESABCDModelDirectionCandidate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Requirement,
        [Parameter(Mandatory)][string]$SourceHash,
        [Parameter(Mandatory)][string]$Mode,
        [Parameter(Mandatory)][string]$Axis,
        [Parameter(Mandatory)][int]$Ordinal,
        [Parameter(Mandatory)]$Profile,
        [Parameter(Mandatory)][int]$DirectionCount,
        [scriptblock]$ModelInvoker = $null,
        [object]$ModelConfig = $null
    )
    Import-Module (Join-Path $PSScriptRoot 'ESABCDModelClient.psm1') -Force -Global
    Import-Module (Join-Path $PSScriptRoot 'ESABCDDelivery.psm1') -Force -Global

    $sys = New-ESABCDModelDivergenceSystemPrompt -Mode $Mode
    $user = New-ESABCDModelDivergenceUserPrompt -Requirement $Requirement -Mode $Mode -Axis $Axis -Ordinal $Ordinal -DirectionCount $DirectionCount

    $rawText = $null
    $modelMeta = $null
    if ($null -ne $ModelInvoker) {
        $inv = & $ModelInvoker ([pscustomobject]@{
                phase = 'axis-divergence'
                generationMode = $Mode
                round = $Ordinal
                axis = $Axis
                requirement = $Requirement
                systemPrompt = $sys
                userPrompt = $user
            })
        if ($inv -is [System.Array]) { $inv = $inv[0] }
        if ($inv -is [string]) { $rawText = $inv }
        elseif ($null -ne $inv.PSObject.Properties['content']) { $rawText = [string]$inv.content }
        else { $rawText = ($inv | ConvertTo-Json -Depth 8 -Compress) }
        $modelMeta = [pscustomobject]@{ model = 'invoker'; baseUrl = 'scriptblock'; requestId = $null }
    }
    else {
        $chat = Invoke-ESABCDChatCompletion -SystemPrompt $sys -UserPrompt $user -Temperature 0.8 -MaxTokens 2800 -Config $ModelConfig
        $rawText = [string]$chat.content
        $modelMeta = [pscustomobject]@{ model = $chat.model; baseUrl = $chat.baseUrl; requestId = $chat.requestId }
    }
    if ([string]::IsNullOrWhiteSpace($rawText)) { throw "ABCD_MODEL_AXIS_EMPTY:$Axis" }

    $doc = ConvertFrom-ESABCDModelJson -Text $rawText
    $need = @('concretePlayerScenario','inputSequence','visibleFeedback','novelMechanism','productPitch')
    foreach ($f in $need) {
        $prop = $doc.PSObject.Properties | Where-Object { $_.Name -ceq $f } | Select-Object -First 1
        if ($null -eq $prop -or [string]::IsNullOrWhiteSpace([string]$prop.Value)) {
            throw "ABCD_MODEL_AXIS_FIELD_MISSING:${Axis}:$f"
        }
    }

    $scoresIn = $null
    if ($null -ne ($doc.PSObject.Properties | Where-Object Name -ceq 'modeScores' | Select-Object -First 1)) { $scoresIn = $doc.modeScores }
    $scoreNames = @('delight','smoothness','presentation','skillCeiling','joyLoop','first10sMoment','expressionCeiling','noveltyDelta','counterplayClarity','depth','breakthrough','reusability','longevity','projectFit','completeness','safety','closure')
    $scores = [ordered]@{}
    foreach ($n in $scoreNames) {
        $v = 70
        if ($null -ne $scoresIn -and $null -ne ($scoresIn.PSObject.Properties | Where-Object { $_.Name -ceq $n } | Select-Object -First 1)) {
            try { $v = [int]$scoresIn.$n } catch { $v = 70 }
        }
        if ($v -lt 1) { $v = 1 }
        if ($v -gt 100) { $v = 100 }
        $scores[$n] = $v
    }

    $trace = New-Object System.Collections.Generic.List[object]
    $kept = New-Object System.Collections.Generic.List[object]
    $branches = @()
    if ($null -ne ($doc.PSObject.Properties | Where-Object Name -ceq 'branchTrace' | Select-Object -First 1)) { $branches = @($doc.branchTrace) }
    if ($branches.Count -lt 2) { throw "ABCD_MODEL_BRANCH_TRACE_TOO_SHORT:$Axis" }
    $hasKeep = $false; $hasDiscard = $false
    $ri = 0
    $seed = [ordered]@{ requirement = $Requirement; sourceHash = $SourceHash; mode = $Mode; axis = $Axis; ordinal = $Ordinal; engine = 'llm-v1' }
    $hash = Get-ESABCDStringSha256 -Text (($seed | ConvertTo-Json -Compress -Depth 6))
    $id = 'cand-' + $hash.Substring(0, 20)
    $parentId = $id
    foreach ($b in $branches) {
        $ri++
        $decision = 'keep'
        if ($null -ne (Get-ESABCDJsonProp $b 'decision')) {
            $d = ([string](Get-ESABCDJsonProp $b 'decision')).Trim().ToLowerInvariant()
            if ($d -eq 'discard' -or $d -eq 'drop' -or $d -eq 'reject') { $decision = 'discard' } else { $decision = 'keep' }
        }
        if ($decision -eq 'keep') { $hasKeep = $true } else { $hasDiscard = $true }
        $title = if ($null -ne (Get-ESABCDJsonProp $b 'title')) { [string](Get-ESABCDJsonProp $b 'title') } else { "分支$ri" }
        $change = if ($null -ne (Get-ESABCDJsonProp $b 'concreteChange')) { [string](Get-ESABCDJsonProp $b 'concreteChange') } else { [string]$b }
        $reason = if ($null -ne (Get-ESABCDJsonProp $b 'keepOrDiscardReason')) { [string](Get-ESABCDJsonProp $b 'keepOrDiscardReason') } else { $decision }
        $acc = 70
        if ($null -ne (Get-ESABCDJsonProp $b 'playerAcceptability')) { try { $acc = [int](Get-ESABCDJsonProp $b 'playerAcceptability') } catch { $acc = 70 } }
        $roundId = $ri
        if ($null -ne (Get-ESABCDJsonProp $b 'roundId')) { try { $roundId = [int](Get-ESABCDJsonProp $b 'roundId') } catch { $roundId = $ri } }
        $bid = "$id-r$roundId-" + $decision.Substring(0,1)
        [void]$trace.Add([pscustomobject][ordered]@{
                roundId = $roundId
                parentCandidateId = $parentId
                branchId = $bid
                branchReason = "模型自由发散：轴 $Axis / $title"
                concreteChange = $change
                mutationId = "llm-$roundId"
                mutationTitle = $title
                playerAcceptability = $acc
                keepOrDiscardReason = $reason
                decision = $decision
                language = 'zh-CN'
                source = 'llm-model'
            })
        if ($decision -eq 'keep') {
            [void]$kept.Add([pscustomobject]@{ round = $roundId; title = $title; change = $change; score = $acc })
            $parentId = $bid
        }
    }
    if (-not $hasKeep -or -not $hasDiscard) {
        throw "ABCD_MODEL_BRANCH_TRACE_NEEDS_BOTH_KEEP_AND_DISCARD:$Axis"
    }

    $axisZh = if ($null -ne (Get-ESABCDJsonProp $doc 'axisZh') -and -not [string]::IsNullOrWhiteSpace([string](Get-ESABCDJsonProp $doc 'axisZh'))) { [string](Get-ESABCDJsonProp $doc 'axisZh') } else { Get-ESABCDAxisLabelZh -Axis $Axis }
    $accept = 80
    if ($null -ne (Get-ESABCDJsonProp $doc 'acceptabilityScore')) { try { $accept = [int](Get-ESABCDJsonProp $doc 'acceptabilityScore') } catch { $accept = 80 } }
    $concrete = 80
    if ($null -ne (Get-ESABCDJsonProp $doc 'concretenessScore')) { try { $concrete = [int](Get-ESABCDJsonProp $doc 'concretenessScore') } catch { $concrete = 80 } }

    $playerValue = switch ($Mode) {
        'creative-divergence' { '玩家向：由大模型按轴自由发散' }
        'engineering' { '工程向：由大模型按轴自由发散' }
        default { '稳定向：由大模型按轴自由发散' }
    }
    $chain = "核心动作（$axisZh）-> 关联机制 -> 可见收益 -> 恢复选择；放大环：$([string]$Profile.amplificationLoop)"
    $self = if ($null -ne (Get-ESABCDJsonProp $doc 'selfCritique')) { [string](Get-ESABCDJsonProp $doc 'selfCritique') } else { "最弱轴=$axisZh；由模型自检修补" }

    $cand = [ordered]@{}
    $cand['directionId'] = $id
    $cand['mode'] = $Mode
    $cand['ordinal'] = $Ordinal
    $cand['axis'] = $Axis
    $cand['axisZh'] = $axisZh
    $cand['productPitch'] = [string]$doc.productPitch
    $cand['contentTier'] = 'llm-axis-divergence-v1'
    $cand['contentSource'] = 'llm-model'
    $cand['focus'] = @($Profile.focus | ForEach-Object { [string]$_ })
    $cand['rankingPriority'] = @($Profile.rankingPriority | ForEach-Object { [string]$_ })
    $cand['selfCritiqueLoop'] = [string]$Profile.selfCritiqueLoop
    $cand['noveltyPrompt'] = "大模型沿轴 $axisZh 自由发散，禁止预制卡组"
    $cand['playerValue'] = $playerValue
    $cand['modeScores'] = [pscustomobject]$scores
    $cand['amplificationChain'] = $chain
    $cand['selfCritique'] = $self
    $cand['selfCritiquePasses'] = [int]$kept.Count
    $cand['seedDraft'] = "LLM seed #$Ordinal · $axisZh"
    $cand['expansionSet'] = "LLM 轴发散 · $axisZh"
    $cand['auditFindings'] = '待审计：所有权、反制、恢复、需求贴合、模型幻觉'
    $cand['playabilityBackpressure'] = '首个收益与复杂度由模型给出，仍为设计候选'
    $cand['finalDecision'] = '候选；未定案'
    $cand['deletedAnchors'] = @("default-$Axis-assumption", 'card-pack-fallback-removed')
    $cand['novelMechanism'] = [string]$doc.novelMechanism
    $cand['plausibilityRationale'] = '模型给出的因果需人工复核'
    $cand['counterplayInvariant'] = '对手应有可读反制（若适用）'
    $cand['surpriseScore'] = [int][Math]::Min(95.0, [Math]::Max(50.0, [double]$scores['noveltyDelta']))
    $cand['plausibilityScore'] = [int][Math]::Min(95.0, [Math]::Max(50.0, [double]$concrete))
    $cand['firstUseAffordance'] = "主输入产生与「$axisZh」相关的可见反应"
    $cand['partialUnderstandingPath'] = '基础反应在未掌握全部系统前仍有用'
    $cand['masteryDepth'] = '时机与分支随熟练加深'
    $cand['onboardingBurden'] = [int][Math]::Max(30.0, 100.0 - [double]$accept)
    $cand['firstPayoffSeconds'] = 6
    $cand['firstInputCount'] = 1
    $cand['preservedIdentity'] = '需求主体身份保持'
    $cand['preservedRole'] = '需求角色保持'
    $cand['requestedFormFactor'] = '输入声明的形态'
    $cand['formFactorPreserved'] = $true
    $cand['mechanismDelta'] = '机制由模型提出；身份/角色/形态不变'
    $cand['concretePlayerScenario'] = [string]$doc.concretePlayerScenario
    $cand['inputSequence'] = [string]$doc.inputSequence
    $cand['visibleFeedback'] = [string]$doc.visibleFeedback
    $cand['acceptabilityRationale'] = '模型自评分 + ABCD 后续排序收口'
    $cand['concretenessScore'] = $concrete
    $cand['acceptabilityScore'] = $accept
    $cand['assumption'] = $(if ($null -ne (Get-ESABCDJsonProp $doc 'assumption')) { [string](Get-ESABCDJsonProp $doc 'assumption') } else { "轴 $axisZh 是实质决策变量" })
    $cand['risk'] = $(if ($null -ne (Get-ESABCDJsonProp $doc 'risk')) { [string](Get-ESABCDJsonProp $doc 'risk') } else { "未验证:$Axis" })
    $cand['pruningPolicy'] = [string]$Profile.pruningPolicy
    $cand['hidden'] = $false
    $cand['status'] = 'candidate'
    $cand['verificationPredicate'] = "source-hash-equals:$SourceHash"
    $cand['identityHash'] = $hash
    $cand['lineageRoot'] = $id
    $cand['lineageDepth'] = [int]$trace.Count
    $cand['iterationTrace'] = @($trace.ToArray())
    $cand['keptMutations'] = @($kept.ToArray())
    $cand['divergenceEngine'] = 'llm-axis-divergence-v1'
    $cand['language'] = 'zh-CN'
    $cand['modelMeta'] = $modelMeta
    $cand['modelRawExcerpt'] = if ($rawText.Length -gt 400) { $rawText.Substring(0, 400) } else { $rawText }
    return [pscustomobject]$cand
}

function Invoke-ESABCDModelModeDivergence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Requirement,
        [Parameter(Mandatory)][string]$SourceHash,
        [ValidateSet('creative-divergence','engineering','stable')][string]$Mode = 'creative-divergence',
        [int]$MinimumDirections = 0,
        [string]$ProjectRoot = '',
        [scriptblock]$ModelInvoker = $null
    )
    Import-Module (Join-Path $PSScriptRoot 'ESABCDHome.psm1') -Force -Global
    Import-Module (Join-Path $PSScriptRoot 'ESABCDDivergence.psm1') -Force -Global
    Import-Module (Join-Path $PSScriptRoot 'ESABCDModelClient.psm1') -Force -Global

    if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { $ProjectRoot = Get-ESABCDPackageRoot }
    $profile = Get-ESABCGenerationMode -Mode $Mode -ProjectRoot $ProjectRoot
    $count = if ($MinimumDirections -gt 0) { $MinimumDirections } else { [int]$profile.minimumDirections }
    if ($count -lt $profile.minimumDirections -or $count -gt $profile.maximumDirections) { throw 'ABC_GENERATION_DIRECTION_BUDGET_INVALID' }

    $cfg = $null
    if ($null -eq $ModelInvoker) {
        $cfg = Get-ESABCDModelConfig
    }

    $axes = @($profile.requiredAxes)
    $directions = New-Object System.Collections.Generic.List[object]
    $allRounds = New-Object System.Collections.Generic.List[object]
    for ($i = 0; $i -lt $count; $i++) {
        $axis = [string]$axes[$i % $axes.Count]
        $cand = New-ESABCDModelDirectionCandidate -Requirement $Requirement -SourceHash $SourceHash -Mode $Mode -Axis $axis -Ordinal ($i + 1) -Profile $profile -DirectionCount $count -ModelInvoker $ModelInvoker -ModelConfig $cfg
        [void]$directions.Add($cand)
        foreach ($tr in @($cand.iterationTrace)) { [void]$allRounds.Add($tr) }
    }

    $dirArr = @($directions.ToArray())
    # Collision check on model bodies: if identical, fail closed (no card-pack silent pass)
    Import-Module (Join-Path $PSScriptRoot 'ESABCDDelivery.psm1') -Force -Global
    $collision = Test-ESABCDTemplateCollision -Candidates $dirArr
    if ($null -ne $collision -and [bool]$collision.hasCollision) {
        throw ("ABCD_MODEL_TEMPLATE_COLLISION:" + [int]$collision.collisionCount + ":model produced identical bodies across axes")
    }

    $maxRounds = 0
    foreach ($d in $dirArr) {
        $rc = @($d.iterationTrace).Count
        if ($rc -gt $maxRounds) { $maxRounds = $rc }
    }
    $canonical = [ordered]@{
        requirement = $Requirement
        sourceHash  = $SourceHash
        mode        = $Mode
        ids         = @($dirArr | ForEach-Object { [string]$_.directionId })
        engine      = 'llm-axis-divergence-v1'
    }
    $out = [ordered]@{}
    $out['schemaVersion'] = 1
    $out['contractId'] = 'es://automation/contracts/ai-abc/generation-modes/v1'
    $out['mode'] = $Mode
    $out['profile'] = $profile
    $out['requirement'] = $Requirement
    $out['sourceHash'] = $SourceHash
    $out['directionCount'] = $dirArr.Count
    $out['directions'] = $dirArr
    $out['iterationPolicy'] = [pscustomobject]@{
        engine            = 'llm-axis-divergence-v1'
        selection         = 'model-scores-then-abcd-rank'
        lineageRequired   = $true
        cardPackForbidden = $true
    }
    $out['roundCount'] = [int]$maxRounds
    $out['branchCount'] = [int]$allRounds.Count
    $out['hiddenDirectionCount'] = 0
    $out['selectionPolicy'] = 'rank-after-llm-axis-divergence'
    $out['status'] = [string]$profile.outputStatus
    $out['claimLevel'] = 'candidate'
    $out['auditDeferred'] = $true
    $out['candidateSetHash'] = (Get-ESABCDDivergenceHash $canonical)
    $out['graphAuthority'] = 'candidate-only'
    $out['deliveryKind'] = 'lens-pending'
    $out['pipelineLevel'] = 'L0'
    $out['runtimeStatus'] = 'runtime-not-run'
    $out['iterationTraceKind'] = 'llm-axis-divergence-v1'
    $out['divergenceEngine'] = 'llm-axis-divergence-v1'
    $out['contentSource'] = 'llm-model'
    $out['language'] = 'zh-CN'
    $out['modelConfigSource'] = $(if ($null -ne $cfg) { [string]$cfg.source } else { 'scriptblock-invoker' })
    return [pscustomobject]$out
}

Export-ModuleMember -Function @(
    'Get-ESABCDAxisLabelZh',
    'New-ESABCDModelDirectionCandidate',
    'Invoke-ESABCDModelModeDivergence'
)
