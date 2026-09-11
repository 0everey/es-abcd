# P0: Multi-layer AI divergence only. Single-layer / fast judgment deleted.
# Layers (mandatory): seed -> expand(x2+) -> audit -> self-critique. Fail => score 0.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ESABCDStringSha256 {
    param([Parameter(Mandatory)][string]$Text)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text)))).Replace('-','').ToLowerInvariant() }
    finally { $sha.Dispose() }
}

function ConvertFrom-ESABCDModelJsonLocal {
    param([Parameter(Mandatory)][string]$Text)
    Import-Module (Join-Path $PSScriptRoot 'ESABCDModelClient.psm1') -Force -Global
    return ConvertFrom-ESABCDModelJson -Text $Text
}

function Invoke-ESABCDLayerModel {
    param(
        [Parameter(Mandatory)][string]$Phase,
        [Parameter(Mandatory)][string]$SystemPrompt,
        [Parameter(Mandatory)][string]$UserPrompt,
        [scriptblock]$ModelInvoker = $null,
        $ModelConfig = $null,
        [string]$Mode = 'creative-divergence',
        [string]$Requirement = '',
        [int]$Round = 1
    )
    Import-Module (Join-Path $PSScriptRoot 'ESABCDModelClient.psm1') -Force -Global
    if ($null -ne $ModelInvoker) {
        $inv = & $ModelInvoker ([pscustomobject]@{
                phase = $Phase; generationMode = $Mode; round = $Round
                requirement = $Requirement; systemPrompt = $SystemPrompt; userPrompt = $UserPrompt
            })
        if ($inv -is [System.Array]) { $inv = $inv[0] }
        if ($inv -is [string]) { return [pscustomobject]@{ content = $inv; model = 'invoker' } }
        if ($null -ne $inv.PSObject.Properties['content']) { return [pscustomobject]@{ content = [string]$inv.content; model = 'invoker' } }
        return [pscustomobject]@{ content = ($inv | ConvertTo-Json -Depth 10 -Compress); model = 'invoker' }
    }
    if ($null -eq $ModelConfig) { $ModelConfig = Get-ESABCDModelConfig }
    return Invoke-ESABCDChatCompletion -SystemPrompt $SystemPrompt -UserPrompt $UserPrompt -Temperature 0.75 -MaxTokens 3200 -Config $ModelConfig
}

function Test-ESABCDMultiLayerEvidence {
    <#
    .SYNOPSIS
      Score multi-layer divergence. Missing any mandatory layer => totalScore=0.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Run)
    $missing = New-Object System.Collections.Generic.List[string]
    $layers = @()
    if ($null -ne $Run.PSObject.Properties['layers']) { $layers = @($Run.layers) }
    $need = @('seed','expand','audit','self-critique')
    $have = @{}
    foreach ($L in $layers) {
        $id = [string]$L.layerId
        if (-not [string]::IsNullOrWhiteSpace($id)) { $have[$id] = $L }
    }
    foreach ($n in $need) {
        if (-not $have.ContainsKey($n)) { [void]$missing.Add("LAYER_MISSING:$n") }
        else {
            $L = $have[$n]
            $calls = 0
            if ($null -ne $L.PSObject.Properties['modelCalls']) { $calls = [int]$L.modelCalls }
            if ($calls -lt 1) { [void]$missing.Add("LAYER_NO_MODEL_CALL:$n") }
            $out = ''
            if ($null -ne $L.PSObject.Properties['outputSummary']) { $out = [string]$L.outputSummary }
            if ([string]::IsNullOrWhiteSpace($out) -or $out.Length -lt 20) { [void]$missing.Add("LAYER_EMPTY_OUTPUT:$n") }
        }
    }
    # expand must show depth >= 2 rounds
    if ($have.ContainsKey('expand')) {
        $depth = 0
        if ($null -ne $have['expand'].PSObject.Properties['expandDepth']) { $depth = [int]$have['expand'].expandDepth }
        if ($depth -lt 2) { [void]$missing.Add('EXPAND_DEPTH_LT_2') }
    }
    # seed must have >= 3 candidates
    if ($have.ContainsKey('seed')) {
        $sc = 0
        if ($null -ne $have['seed'].PSObject.Properties['seedCount']) { $sc = [int]$have['seed'].seedCount }
        if ($sc -lt 3) { [void]$missing.Add('SEED_COUNT_LT_3') }
    }
    # forbid single-layer markers
    if ($null -ne $Run.PSObject.Properties['divergenceEngine']) {
        $eng = [string]$Run.divergenceEngine
        if ($eng -match 'single-layer|llm-axis-divergence-v1$|fast-judgment') {
            [void]$missing.Add("FORBIDDEN_ENGINE:$eng")
        }
    }
    if ($null -ne $Run.PSObject.Properties['judgmentKind']) {
        $jk = [string]$Run.judgmentKind
        if ($jk -match 'fast|single-layer|shallow') { [void]$missing.Add("FORBIDDEN_JUDGMENT:$jk") }
    }

    $ok = ($missing.Count -eq 0)
    $totalScore = 0
    if ($ok) {
        # non-zero only when multi-layer closed
        $base = 60.0
        $base += [Math]::Min(20.0, [double](@($Run.directions).Count * 2))
        if ($have.ContainsKey('expand') -and [int]$have['expand'].expandDepth -ge 3) { $base += 10.0 }
        if ($have.ContainsKey('audit')) { $base += 5.0 }
        if ($have.ContainsKey('self-critique')) { $base += 5.0 }
        $totalScore = [int][Math]::Min(100.0, $base)
    }
    return [pscustomobject]@{
        passed           = $ok
        totalScore       = $totalScore   # 0 if any mandatory layer missing
        missing          = @($missing)
        requiredLayers   = $need
        judgmentKind     = if ($ok) { 'multi-layer-audit-self-critique' } else { 'rejected-single-or-incomplete' }
        scorePolicy      = 'incomplete-multi-layer-is-hard-zero'
        claimLevel       = if ($ok) { 'design-candidate' } else { 'invalid-divergence-depth' }
    }
}

function Invoke-ESABCDMultiLayerDivergence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Requirement,
        [Parameter(Mandatory)][string]$SourceHash,
        [ValidateSet('creative-divergence','engineering','stable')][string]$Mode = 'creative-divergence',
        [int]$MinimumSeeds = 3,
        [ValidateRange(2, 6)][int]$ExpandDepth = 2,
        [string]$ProjectRoot = '',
        [scriptblock]$ModelInvoker = $null
    )
    Import-Module (Join-Path $PSScriptRoot 'ESABCDDivergence.psm1') -Force -Global
    Import-Module (Join-Path $PSScriptRoot 'ESABCDModelClient.psm1') -Force -Global

    if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
        $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
    }
    if ([string]::IsNullOrWhiteSpace($Requirement)) { throw 'ABC_GENERATION_REQUIREMENT_REQUIRED' }
    if ($SourceHash -notmatch '^[a-f0-9]{64}$') { throw 'ABC_GENERATION_SOURCE_HASH_INVALID' }
    if ($null -eq $ModelInvoker) { $null = Get-ESABCDModelConfig }

    $cfg = $null
    if ($null -eq $ModelInvoker) { $cfg = Get-ESABCDModelConfig }
    $profile = Get-ESABCGenerationMode -Mode $Mode -ProjectRoot $ProjectRoot
    $layers = New-Object System.Collections.Generic.List[object]
    $modelCallLog = New-Object System.Collections.Generic.List[object]

    # -------- Layer 1: SEED (multi independent seeds) --------
    $sysSeed = @"
你是 ABCD 多层发散的第1层（seed）。必须原创多个互不雷同的机制种子。
禁止单层敷衍；禁止套模板。只输出 JSON。
模式：$Mode
"@
    $userSeed = @"
需求：
$Requirement

输出 JSON：
{
  "seeds": [
    {
      "seedId": "s1",
      "axisHint": "机制轴英文短名",
      "axisZh": "中文轴名",
      "productPitch": "一句话",
      "concretePlayerScenario": "具体场景",
      "novelMechanism": "新机制",
      "assumption": "假设",
      "risk": "风险"
    }
  ],
  "selfNote": "为何这些种子彼此独立"
}
seeds 至少 $MinimumSeeds 条，场景/机制必须明显不同。
"@
    $seedChat = Invoke-ESABCDLayerModel -Phase 'seed' -SystemPrompt $sysSeed -UserPrompt $userSeed -ModelInvoker $ModelInvoker -ModelConfig $cfg -Mode $Mode -Requirement $Requirement -Round 1
    [void]$modelCallLog.Add([pscustomobject]@{ phase = 'seed'; model = $seedChat.model })
    $seedDoc = ConvertFrom-ESABCDModelJsonLocal -Text ([string]$seedChat.content)
    $seeds = @()
    if ($null -ne $seedDoc.seeds) { $seeds = @($seedDoc.seeds) }
    if ($seeds.Count -lt $MinimumSeeds) {
        # hard fail path still returns structure with score 0
        $failed = [pscustomobject]@{
            schemaVersion = 1
            divergenceEngine = 'multi-layer-v1'
            judgmentKind = 'single-or-incomplete'
            contentSource = 'llm-model'
            layers = @([pscustomobject]@{ layerId = 'seed'; modelCalls = 1; seedCount = $seeds.Count; outputSummary = 'seed-count-insufficient'; expandDepth = 0 })
            directions = @()
            directionCount = 0
            mode = $Mode
            requirement = $Requirement
            sourceHash = $SourceHash
        }
        $gate = Test-ESABCDMultiLayerEvidence -Run $failed
        $failed | Add-Member -NotePropertyName depthGate -NotePropertyValue $gate -Force
        $failed | Add-Member -NotePropertyName totalScore -NotePropertyValue 0 -Force
        $failed | Add-Member -NotePropertyName status -NotePropertyValue 'MULTI_LAYER_FAILED' -Force
        $failed | Add-Member -NotePropertyName claimLevel -NotePropertyValue 'invalid-divergence-depth' -Force
        return $failed
    }
    [void]$layers.Add([pscustomobject]@{
            layerId = 'seed'; modelCalls = 1; seedCount = $seeds.Count
            outputSummary = ("seeds=" + $seeds.Count + " " + [string]$seedDoc.selfNote)
            expandDepth = 0
        })

    # -------- Layer 2: EXPAND recursive (depth >= 2) --------
    $beam = New-Object System.Collections.Generic.List[object]
    $si = 0
    foreach ($s in $seeds) {
        $si++
        $sid = if ($s.seedId) { [string]$s.seedId } else { "s$si" }
        [void]$beam.Add([pscustomobject]@{
                seedId = $sid
                parentId = $sid
                depth = 0
                axis = $(if ($s.axisHint) { [string]$s.axisHint } else { "axis-$si" })
                axisZh = $(if ($s.axisZh) { [string]$s.axisZh } else { "轴$si" })
                productPitch = [string]$s.productPitch
                concretePlayerScenario = [string]$s.concretePlayerScenario
                novelMechanism = [string]$s.novelMechanism
                assumption = [string]$s.assumption
                risk = [string]$s.risk
                inputSequence = '确认目标 -> 主操作 -> 观察反馈 -> 恢复或加深'
                visibleFeedback = '可见状态、证据与可逆反馈'
                keptTrace = @()
                discardedTrace = @()
            })
    }

    $expandCalls = 0
    for ($d = 1; $d -le $ExpandDepth; $d++) {
        $nextBeam = New-Object System.Collections.Generic.List[object]
        $beamSnap = @($beam.ToArray()); foreach ($node in $beamSnap) {
            $sysEx = @"
你是 ABCD 多层发散第2层（expand depth=$d/$ExpandDepth）。
对给定 parent 产出 2 个具体子分支，必须 keep 1 个 discard 1 个，并说明理由。
禁止与 parent 同句复读。只输出 JSON。
"@
            $userEx = @"
需求：$Requirement
模式：$Mode
Parent：
$(($node | ConvertTo-Json -Depth 6 -Compress))

输出：
{
  "children": [
    {"branchId":"b1","title":"...","concreteChange":"...","decision":"keep|discard","playerAcceptability":0-100,"reason":"...","concretePlayerScenario":"...","novelMechanism":"...","productPitch":"..."}
  ]
}
children 必须恰好 2 条，且一个 keep 一个 discard。
"@
            $exChat = Invoke-ESABCDLayerModel -Phase 'expand' -SystemPrompt $sysEx -UserPrompt $userEx -ModelInvoker $ModelInvoker -ModelConfig $cfg -Mode $Mode -Requirement $Requirement -Round $d
            $expandCalls++
            [void]$modelCallLog.Add([pscustomobject]@{ phase = 'expand'; depth = $d; parent = $node.parentId; model = $exChat.model })
            $exDoc = ConvertFrom-ESABCDModelJsonLocal -Text ([string]$exChat.content)
            $children = @()
            if ($null -ne $exDoc.children) { $children = @($exDoc.children) }
            $keep = $null; $drop = $null
            foreach ($ch in $children) {
                $dec = ([string]$ch.decision).ToLowerInvariant()
                if ($dec -eq 'keep') { $keep = $ch }
                elseif ($dec -eq 'discard' -or $dec -eq 'drop') { $drop = $ch }
            }
            if ($null -eq $keep -and $children.Count -ge 1) { $keep = $children[0] }
            if ($null -eq $drop -and $children.Count -ge 2) { $drop = $children[1] }
            if ($null -eq $keep) { throw "MULTI_LAYER_EXPAND_NO_KEEP:depth=$d:parent=$($node.parentId)" }

            $keptTrace = @($node.keptTrace) + @([pscustomobject]@{
                    depth = $d; title = [string]$keep.title; change = [string]$keep.concreteChange
                    reason = [string]$keep.reason; score = $(if ($keep.playerAcceptability) { [int]$keep.playerAcceptability } else { 80 })
                })
            $discardedTrace = @($node.discardedTrace)
            if ($null -ne $drop) {
                $discardedTrace += [pscustomobject]@{
                    depth = $d; title = [string]$drop.title; change = [string]$drop.concreteChange
                    reason = [string]$drop.reason
                }
            }
            $newNode = [pscustomobject]@{
                seedId = $node.seedId
                parentId = "$( $node.parentId )-d$d"
                depth = $d
                axis = $node.axis
                axisZh = $node.axisZh
                productPitch = $(if ($keep.productPitch) { [string]$keep.productPitch } else { $node.productPitch })
                concretePlayerScenario = $(if ($keep.concretePlayerScenario) { [string]$keep.concretePlayerScenario } else { $node.concretePlayerScenario + ' | ' + [string]$keep.concreteChange })
                novelMechanism = $(if ($keep.novelMechanism) { [string]$keep.novelMechanism } else { $node.novelMechanism + ' ; ' + [string]$keep.concreteChange })
                assumption = $node.assumption
                risk = $node.risk
                inputSequence = $node.inputSequence
                visibleFeedback = $node.visibleFeedback
                keptTrace = $keptTrace
                discardedTrace = $discardedTrace
            }
            [void]$nextBeam.Add($newNode)
        }
        $beam = $nextBeam
    }
    [void]$layers.Add([pscustomobject]@{
            layerId = 'expand'; modelCalls = $expandCalls; expandDepth = $ExpandDepth
            outputSummary = ("expandDepth=" + $ExpandDepth + " calls=" + $expandCalls + " beam=" + $beam.Count)
            seedCount = $seeds.Count
        })

    # -------- Layer 3: AUDIT --------
    $sysAu = '你是 ABCD 第3层（audit）。对候选做反制/权威/失败恢复/未验诚实审计。只输出 JSON。'
    $beamJson = ($beam.ToArray() | ConvertTo-Json -Depth 8 -Compress)
    $userAu = @"
需求：$Requirement
候选集：
$beamJson

输出：
{
  "audits": [
    {"seedId":"...","pass":true|false,"findings":["..."],"requiredFix":"...","counterplay":"..."}
  ],
  "globalFindings": ["..."]
}
"@
    $auChat = Invoke-ESABCDLayerModel -Phase 'audit' -SystemPrompt $sysAu -UserPrompt $userAu -ModelInvoker $ModelInvoker -ModelConfig $cfg -Mode $Mode -Requirement $Requirement -Round 1
    [void]$modelCallLog.Add([pscustomobject]@{ phase = 'audit'; model = $auChat.model })
    $auDoc = ConvertFrom-ESABCDModelJsonLocal -Text ([string]$auChat.content)
    [void]$layers.Add([pscustomobject]@{
            layerId = 'audit'; modelCalls = 1
            outputSummary = ($(if ($auDoc.globalFindings) { ($auDoc.globalFindings -join '; ') } else { 'audit-done' }))
            expandDepth = $ExpandDepth
            seedCount = $seeds.Count
            raw = $auDoc
        })

    # -------- Layer 4: SELF-CRITIQUE / correction --------
    $sysSc = '你是 ABCD 第4层（self-critique）。针对审计发现修正最弱候选，输出修正后的最终方向集。只输出 JSON。'
    $beamJson2 = ($beam.ToArray() | ConvertTo-Json -Depth 8 -Compress)
    $auJson = ($auDoc | ConvertTo-Json -Depth 6 -Compress)
    $userSc = @"
需求：$Requirement
当前 beam：
$beamJson2
审计：
$auJson

输出：
{
  "directions": [
    {
      "directionId": "cand-...",
      "axis": "...",
      "axisZh": "...",
      "productPitch": "...",
      "concretePlayerScenario": "...",
      "inputSequence": "...",
      "visibleFeedback": "...",
      "novelMechanism": "...",
      "assumption": "...",
      "risk": "...",
      "acceptabilityScore": 0-100,
      "concretenessScore": 0-100,
      "modeScores": {"delight":80,"smoothness":80,"presentation":80,"skillCeiling":80,"joyLoop":80,"first10sMoment":80,"expressionCeiling":80,"noveltyDelta":80,"counterplayClarity":80,"depth":80,"breakthrough":80,"reusability":80,"longevity":80,"projectFit":80,"completeness":80,"safety":80,"closure":80},
      "correctionApplied": "本层自纠做了什么",
      "keptTrace": [],
      "discardedTrace": []
    }
  ],
  "critiqueSummary": "..."
}
directions 至少 3 条。
"@
    $scChat = Invoke-ESABCDLayerModel -Phase 'self-critique' -SystemPrompt $sysSc -UserPrompt $userSc -ModelInvoker $ModelInvoker -ModelConfig $cfg -Mode $Mode -Requirement $Requirement -Round 1
    [void]$modelCallLog.Add([pscustomobject]@{ phase = 'self-critique'; model = $scChat.model })
    $scDoc = ConvertFrom-ESABCDModelJsonLocal -Text ([string]$scChat.content)
    [void]$layers.Add([pscustomobject]@{
            layerId = 'self-critique'; modelCalls = 1
            outputSummary = $(if ($scDoc.critiqueSummary) { [string]$scDoc.critiqueSummary } else { 'self-critique-done' })
            expandDepth = $ExpandDepth
            seedCount = $seeds.Count
        })

    # Build direction candidates for Select
    $directions = New-Object System.Collections.Generic.List[object]
    $dirDocs = @()
    if ($null -ne $scDoc.directions) { $dirDocs = @($scDoc.directions) }
    if ($dirDocs.Count -lt 3) {
        # fallback assemble from beam + critique mark (still must pass gate via layers present)
        foreach ($n in @($beam)) {
            $dirDocs += [pscustomobject]@{
                directionId = 'cand-' + (Get-ESABCDStringSha256 -Text ($n.parentId + $n.novelMechanism)).Substring(0, 20)
                axis = $n.axis; axisZh = $n.axisZh; productPitch = $n.productPitch
                concretePlayerScenario = $n.concretePlayerScenario; inputSequence = $n.inputSequence
                visibleFeedback = $n.visibleFeedback; novelMechanism = $n.novelMechanism
                assumption = $n.assumption; risk = $n.risk
                acceptabilityScore = 80; concretenessScore = 80
                modeScores = [pscustomobject]@{ delight=80;smoothness=80;presentation=80;skillCeiling=80;joyLoop=80;first10sMoment=80;expressionCeiling=80;noveltyDelta=80;counterplayClarity=80;depth=80;breakthrough=80;reusability=80;longevity=80;projectFit=80;completeness=80;safety=80;closure=80 }
                correctionApplied = 'assembled-from-beam'
                keptTrace = $n.keptTrace; discardedTrace = $n.discardedTrace
            }
        }
    }

    $oi = 0
    foreach ($d in $dirDocs) {
        $oi++
        $id = if ($d.directionId) { [string]$d.directionId } else { 'cand-' + (Get-ESABCDStringSha256 -Text ($Requirement + $oi + [string]$d.axis)).Substring(0, 20) }
        $scores = $d.modeScores
        if ($null -eq $scores) {
            $scores = [pscustomobject]@{ delight=80;smoothness=80;presentation=80;skillCeiling=80;joyLoop=80;first10sMoment=80;expressionCeiling=80;noveltyDelta=80;counterplayClarity=80;depth=80;breakthrough=80;reusability=80;longevity=80;projectFit=80;completeness=80;safety=80;closure=80 }
        }
        $trace = New-Object System.Collections.Generic.List[object]
        $kt = @()
        if ($null -ne $d.keptTrace) { $kt = @($d.keptTrace) }
        foreach ($k in $kt) {
            [void]$trace.Add([pscustomobject]@{
                    roundId = $(if ($k.depth) { [int]$k.depth } else { 1 })
                    decision = 'keep'; mutationTitle = [string]$k.title; concreteChange = [string]$k.change
                    keepOrDiscardReason = [string]$k.reason; playerAcceptability = $(if ($k.score) { [int]$k.score } else { 80 })
                    language = 'zh-CN'; source = 'multi-layer-expand'
                })
        }
        $dt = @()
        if ($null -ne $d.discardedTrace) { $dt = @($d.discardedTrace) }
        foreach ($k in $dt) {
            [void]$trace.Add([pscustomobject]@{
                    roundId = $(if ($k.depth) { [int]$k.depth } else { 1 })
                    decision = 'discard'; mutationTitle = [string]$k.title; concreteChange = [string]$k.change
                    keepOrDiscardReason = [string]$k.reason; playerAcceptability = 50
                    language = 'zh-CN'; source = 'multi-layer-expand'
                })
        }
        [void]$directions.Add([pscustomobject]@{
                directionId = $id; mode = $Mode; ordinal = $oi
                axis = [string]$d.axis; axisZh = [string]$d.axisZh
                productPitch = [string]$d.productPitch
                contentTier = 'multi-layer-v1'
                contentSource = 'llm-model'
                focus = @( @($profile.focus) | ForEach-Object { [string]$_ } )
                rankingPriority = @( @($profile.rankingPriority) | ForEach-Object { [string]$_ } )
                modeScores = $scores
                concretePlayerScenario = [string]$d.concretePlayerScenario
                inputSequence = [string]$d.inputSequence
                visibleFeedback = [string]$d.visibleFeedback
                novelMechanism = [string]$d.novelMechanism
                assumption = [string]$d.assumption
                risk = [string]$d.risk
                amplificationChain = ('seed->expandx' + $ExpandDepth + '->audit->self-critique')
                selfCritique = [string]$d.correctionApplied
                acceptabilityScore = $(if ($null -ne $d.PSObject.Properties['acceptabilityScore'] -and $null -ne $d.acceptabilityScore) { [int]$d.acceptabilityScore } else { 80 })
                concretenessScore = $(if ($null -ne $d.PSObject.Properties['concretenessScore'] -and $null -ne $d.concretenessScore) { [int]$d.concretenessScore } else { 80 })
                iterationTrace = @($trace.ToArray())
                keptMutations = @( $kt | ForEach-Object { [pscustomobject]@{ round = $_.depth; title = $_.title; change = $_.change; score = $_.score } } )
                divergenceEngine = 'multi-layer-v1'
                language = 'zh-CN'
                status = 'candidate'
                pruningPolicy = [string]$profile.pruningPolicy
                hidden = $false
                identityHash = Get-ESABCDStringSha256 -Text $id
                verificationPredicate = ("source-hash-equals:" + $SourceHash)
            })
    }

    $dirArrFinal = @($directions.ToArray())
    $layerArr = @($layers.ToArray())
    $logArr = @($modelCallLog.ToArray())
    $run = [pscustomobject]@{
        schemaVersion = 1
        contractId = 'es://automation/contracts/ai-abc/generation-modes/v1'
        mode = $Mode
        profile = $profile
        requirement = $Requirement
        sourceHash = $SourceHash
        directionCount = $dirArrFinal.Count
        directions = $dirArrFinal
        layers = $layerArr
        modelCallLog = $logArr
        iterationPolicy = [pscustomobject]@{
            engine = 'multi-layer-v1'
            requiredLayers = @('seed','expand','audit','self-critique')
            expandDepth = $ExpandDepth
            singleLayerForbidden = $true
            fastJudgmentForbidden = $true
            incompleteScore = 0
        }
        roundCount = $ExpandDepth
        branchCount = $logArr.Count
        selectionPolicy = 'rank-after-multi-layer'
        status = 'running-depth-gate'
        claimLevel = 'candidate'
        auditDeferred = $false
        candidateSetHash = Get-ESABCDStringSha256 -Text (($dirArrFinal | ForEach-Object { [string]$_.directionId }) -join '|')
        graphAuthority = 'candidate-only'
        deliveryKind = 'lens-pending'
        pipelineLevel = 'L0'
        runtimeStatus = 'runtime-not-run'
        iterationTraceKind = 'multi-layer-v1'
        divergenceEngine = 'multi-layer-v1'
        contentSource = 'llm-model'
        judgmentKind = 'multi-layer-audit-self-critique'
        language = 'zh-CN'
    }

    $gate = Test-ESABCDMultiLayerEvidence -Run $run
    $outHash = [ordered]@{}
    foreach ($p in $run.PSObject.Properties) { $outHash[$p.Name] = $p.Value }
    $outHash['depthGate'] = $gate
    $outHash['totalScore'] = [int]$gate.totalScore
    if (-not [bool]$gate.passed) {
        $outHash['status'] = 'MULTI_LAYER_FAILED'
        $outHash['claimLevel'] = 'invalid-divergence-depth'
        $outHash['totalScore'] = 0
        $zeroDirs = @()
        foreach ($dir in $dirArrFinal) {
            $z = [ordered]@{}
            if ($null -ne $dir.modeScores) {
                foreach ($sp in $dir.modeScores.PSObject.Properties) { $z[$sp.Name] = 0 }
            }
            $zeroDirs += ,[pscustomobject]@{
                directionId = $dir.directionId; mode = $dir.mode; ordinal = $dir.ordinal
                axis = $dir.axis; axisZh = $dir.axisZh; productPitch = $dir.productPitch
                contentTier = $dir.contentTier; contentSource = $dir.contentSource
                focus = $dir.focus; rankingPriority = $dir.rankingPriority
                modeScores = [pscustomobject]$z
                concretePlayerScenario = $dir.concretePlayerScenario
                inputSequence = $dir.inputSequence; visibleFeedback = $dir.visibleFeedback
                novelMechanism = $dir.novelMechanism; assumption = $dir.assumption; risk = $dir.risk
                amplificationChain = $dir.amplificationChain; selfCritique = $dir.selfCritique
                acceptabilityScore = 0; concretenessScore = 0
                iterationTrace = $dir.iterationTrace; keptMutations = $dir.keptMutations
                divergenceEngine = $dir.divergenceEngine; language = $dir.language
                status = 'score-zero-incomplete-multi-layer'
                pruningPolicy = $dir.pruningPolicy; hidden = $false
                identityHash = $dir.identityHash; verificationPredicate = $dir.verificationPredicate
            }
        }
        $outHash['directions'] = $zeroDirs
    }
    else {
        $outHash['status'] = [string]$profile.outputStatus
        $outHash['claimLevel'] = 'design-candidate'
    }
    return [pscustomobject]$outHash
}

Export-ModuleMember -Function @(
    'Test-ESABCDMultiLayerEvidence',
    'Invoke-ESABCDMultiLayerDivergence'
)
