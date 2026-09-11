# Delivery levels, template collision, domain brief (L1), built-in SHA256.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ESABCDFileSha256 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$LiteralPath
    )
    if (-not (Test-Path -LiteralPath $LiteralPath -PathType Leaf)) {
        throw "ESABCD_HASH_FILE_MISSING:$LiteralPath"
    }
    $bytes = [IO.File]::ReadAllBytes($LiteralPath)
    return Get-ESABCDBytesSha256 -Bytes $bytes
}

function Get-ESABCDBytesSha256 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][byte[]]$Bytes
    )
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash($Bytes))).Replace('-', '').ToLowerInvariant()
    }
    finally { $sha.Dispose() }
}

function Get-ESABCDStringSha256 {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Text)
    $bytes = [Text.Encoding]::UTF8.GetBytes($Text)
    return Get-ESABCDBytesSha256 -Bytes $bytes
}

function Get-ESABCDCandidateFieldText {
    param($Item, [string]$Name)
    if ($null -eq $Item) { return '' }
    $prop = $Item.PSObject.Properties | Where-Object { $_.Name -ceq $Name } | Select-Object -First 1
    if ($null -eq $prop) { return '' }
    return [string]$prop.Value
}

function Test-ESABCDTemplateCollision {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Candidates,
        # Body templates that are identical across axes (novelMechanism embeds axis name and is excluded).
        [string[]]$Fields = @('concretePlayerScenario', 'inputSequence', 'visibleFeedback')
    )
    $items = @($Candidates)
    $collisions = New-Object System.Collections.Generic.List[object]
    if ($items.Count -lt 2) {
        return [pscustomobject]@{
            hasCollision = $false
            collisionCount = 0
            collisions = @()
            status = 'ok'
        }
    }
    for ($i = 0; $i -lt $items.Count; $i++) {
        for ($j = $i + 1; $j -lt $items.Count; $j++) {
            $a = $items[$i]
            $b = $items[$j]
            $sameAll = $true
            $matchedFields = New-Object System.Collections.Generic.List[string]
            foreach ($f in $Fields) {
                $va = Get-ESABCDCandidateFieldText -Item $a -Name $f
                $vb = Get-ESABCDCandidateFieldText -Item $b -Name $f
                if ($va -cne $vb -or [string]::IsNullOrWhiteSpace($va)) { $sameAll = $false; break }
                [void]$matchedFields.Add($f)
            }
            if ($sameAll) {
                [void]$collisions.Add([pscustomobject]@{
                        left   = [string](Get-ESABCDCandidateFieldText -Item $a -Name 'directionId')
                        right  = [string](Get-ESABCDCandidateFieldText -Item $b -Name 'directionId')
                        fields = @($matchedFields)
                    })
            }
        }
    }
    $has = $collisions.Count -gt 0
    return [pscustomobject]@{
        hasCollision   = $has
        collisionCount = $collisions.Count
        collisions     = @($collisions.ToArray())
        status         = if ($has) { 'LENS_TEMPLATE_COLLISION' } else { 'ok' }
        code           = if ($has) { 'LENS_TEMPLATE_COLLISION' } else { $null }
    }
}

function Test-ESABCDRequirementDomain {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Requirement)
    $t = $Requirement
    $liveOpsHits = 0
    foreach ($k in @('采集', '合成', '战备', '出击', '日活', 'gather', 'craft', 'sortie', 'live-ops', 'liveops', 'daily loop', 'daily-loop', 'prep')) {
        if ($t.IndexOf($k, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $liveOpsHits++ }
    }
    $combatHits = 0
    foreach ($k in @('近战', '手感', '技能爆发', 'melee', 'feel', 'burst', 'Boss', '操作')) {
        if ($t.IndexOf($k, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $combatHits++ }
    }
    $domain = 'generic'
    if ($liveOpsHits -ge 2) { $domain = 'live-ops-loop' }
    elseif ($combatHits -ge 2) { $domain = 'combat-feel' }
    return [pscustomobject]@{
        domain = $domain
        liveOpsHits = $liveOpsHits
        combatHits = $combatHits
    }
}

function New-ESABCDDomainBrief {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Requirement,
        [Parameter(Mandatory)]$RankedLenses,
        [ValidateSet('creative-divergence', 'engineering', 'stable')][string]$Mode = 'creative-divergence'
    )
    $domainInfo = Test-ESABCDRequirementDomain -Requirement $Requirement
    $lensList = New-Object System.Collections.Generic.List[object]
    foreach ($row in @($RankedLenses)) {
        $c = $row
        $nested = $row.PSObject.Properties | Where-Object { $_.Name -ceq 'candidate' } | Select-Object -First 1
        if ($null -ne $nested -and $null -ne $nested.Value) { $c = $nested.Value }
        $axis = Get-ESABCDCandidateFieldText -Item $c -Name 'axis'
        $id = Get-ESABCDCandidateFieldText -Item $c -Name 'directionId'
        $scoreProp = $row.PSObject.Properties | Where-Object { $_.Name -ceq 'rankScore' } | Select-Object -First 1
        $score = if ($null -ne $scoreProp) { $scoreProp.Value } else { $null }
        [void]$lensList.Add([pscustomobject]@{ directionId = $id; axis = $axis; rankScore = $score })
    }
    $lenses = @($lensList.ToArray())
    if ($lenses.Count -lt 1) {
        $lenses = @([pscustomobject]@{ directionId = 'lens-none'; axis = 'unspecified'; rankScore = 0 })
    }

    $brief = $null
    $checklist = $null
    $deliveryKind = 'lens-only'
    $pipelineLevel = 'L0'
    $deliveryStatus = 'DELIVERY_LENS_ONLY'

    if ($domainInfo.domain -eq 'live-ops-loop') {
        # P0: live-ops five loops must be LLM-authored (no fixed card table).
        Import-Module (Join-Path $PSScriptRoot 'ESABCDModelClient.psm1') -Force -Global
        $lensJson = ($lenses | Select-Object -First 7 | ConvertTo-Json -Compress -Depth 4)
        $sys = '你是日活系统设计 AI。只输出严格 JSON，不要 Markdown。必须原创五条「采集-合成-战备-出击」循环，含硬核/休闲/社交倾向与吸引谁/烦谁。禁止套固定模板名。'
        $user = @"
需求：
$Requirement

模式：$Mode
已排序透镜（可引用 groundedAxis，不要照抄英文空话）：
$lensJson

输出 JSON：
{
  "summary": "中文摘要",
  "loops": [
    {
      "loopIndex": 1,
      "name": "环名",
      "tilt": "硬核|休闲|社交|其他",
      "attractWho": "...",
      "annoyWho": "...",
      "gather": "必须含采集语义",
      "craft": "必须含合成语义",
      "prep": "必须含战备语义",
      "sortie": "必须含出击语义",
      "groundedAxis": "对应透镜 axis"
    }
  ]
}
loops 必须恰好 5 条，字段齐全，中文，彼此明显不同。
"@
        $chat = Invoke-ESABCDChatCompletion -SystemPrompt $sys -UserPrompt $user -Temperature 0.75 -MaxTokens 2200
        $doc = ConvertFrom-ESABCDModelJson -Text ([string]$chat.content)
        if ($null -eq $doc.loops) { throw 'ABCD_LLM_LIVEOPS_LOOPS_MISSING' }
        $loopArr = @($doc.loops)
        if ($loopArr.Count -lt 5) { throw 'ABCD_LLM_LIVEOPS_LOOP_COUNT' }
        $norm = New-Object System.Collections.Generic.List[object]
        $li = 0
        foreach ($ln in $loopArr) {
            $li++
            if ($li -gt 5) { break }
            $lens = $lenses[[Math]::Min($li - 1, [Math]::Max(0, $lenses.Count - 1))]
            $gAxis = if ($null -ne $ln.PSObject.Properties['groundedAxis'] -and [string]$ln.groundedAxis) { [string]$ln.groundedAxis } else { [string]$lens.axis }
            [void]$norm.Add([pscustomobject]@{
                    loopIndex      = $li
                    name           = [string]$ln.name
                    tilt           = [string]$ln.tilt
                    attractWho     = [string]$ln.attractWho
                    annoyWho       = [string]$ln.annoyWho
                    gather         = [string]$ln.gather
                    craft          = [string]$ln.craft
                    prep           = [string]$ln.prep
                    sortie         = [string]$ln.sortie
                    groundedAxis   = $gAxis
                    groundedLensId = [string]$lens.directionId
                    contentSource  = 'llm-model'
                })
        }
        $loopArr = @($norm.ToArray())
        $checklist = Test-ESABCDLiveOpsBriefChecklist -Loops $loopArr
        $brief = [pscustomobject]@{
            domain        = 'live-ops-loop'
            language      = 'zh-CN'
            summary       = $(if ($null -ne $doc.summary) { [string]$doc.summary } else { '大模型生成的日活五环领域简报。' })
            loops         = $loopArr
            lensesUsed    = $lenses
            requirement   = $Requirement
            mode          = $Mode
            contentSource = 'llm-model'
        }
        if ([bool]$checklist.passed) {
            $deliveryKind = 'domain-brief'
            $pipelineLevel = 'L1'
            $deliveryStatus = 'domain-brief-closed'
        }
        else {
            throw ('ABCD_LLM_LIVEOPS_CHECKLIST_FAILED:' + (($checklist.missing) -join ','))
        }
    }
    elseif ($domainInfo.domain -eq 'combat-feel') {
        # L1 cards MUST come from ranked LLM candidates (no card-pack fill).
        $cards = New-Object System.Collections.Generic.List[object]
        $ci = 0
        foreach ($row in @($RankedLenses)) {
            $ci++
            if ($ci -gt 5) { break }
            $c = $row
            $nested = $row.PSObject.Properties | Where-Object { $_.Name -ceq 'candidate' } | Select-Object -First 1
            if ($null -ne $nested -and $null -ne $nested.Value) { $c = $nested.Value }
            $axisName = Get-ESABCDCandidateFieldText -Item $c -Name 'axis'
            $axisZh = Get-ESABCDCandidateFieldText -Item $c -Name 'axisZh'
            if ([string]::IsNullOrWhiteSpace($axisZh)) { $axisZh = $axisName }
            $src = Get-ESABCDCandidateFieldText -Item $c -Name 'contentSource'
            if ($src -ne 'llm-model' -and $src -ne '' -and $src -notmatch 'llm') {
                throw "ABCD_CARD_PACK_FORBIDDEN:combat-feel candidate contentSource=$src"
            }
            [void]$cards.Add([pscustomobject]@{
                    title           = "手感方案 $ci · $axisZh"
                    pitch           = Get-ESABCDCandidateFieldText -Item $c -Name 'productPitch'
                    scenario        = Get-ESABCDCandidateFieldText -Item $c -Name 'concretePlayerScenario'
                    inputSequence   = Get-ESABCDCandidateFieldText -Item $c -Name 'inputSequence'
                    visibleFeedback = Get-ESABCDCandidateFieldText -Item $c -Name 'visibleFeedback'
                    novelMechanism  = Get-ESABCDCandidateFieldText -Item $c -Name 'novelMechanism'
                    risk            = Get-ESABCDCandidateFieldText -Item $c -Name 'risk'
                    hardCost        = '需实机组手感与帧数据验证；当前为设计候选'
                    groundedAxis    = $axisName
                    groundedLensId  = Get-ESABCDCandidateFieldText -Item $c -Name 'directionId'
                    contentSource   = 'llm-model'
                })
        }
        if ($cards.Count -lt 3) { throw 'ABCD_LLM_FEEL_CARDS_INSUFFICIENT' }
        $brief = [pscustomobject]@{
            domain      = 'combat-feel'
            language    = 'zh-CN'
            summary     = '近战/手感域 L1：来自大模型按轴发散的方案卡（非预制卡组）。'
            cards       = @($cards.ToArray())
            lensesUsed  = $lenses
            requirement = $Requirement
            mode        = $Mode
            contentSource = 'llm-model'
        }
        $deliveryKind = 'domain-brief'
        $pipelineLevel = 'L1'
        $deliveryStatus = 'domain-brief-closed'
        $checklist = [pscustomobject]@{ passed = ($cards.Count -ge 3); domain = 'combat-feel'; cardCount = $cards.Count }
    }
    else {
        # Generic L1-lite from LLM ranked candidates only
        $cards = New-Object System.Collections.Generic.List[object]
        $ci = 0
        foreach ($row in @($RankedLenses)) {
            $ci++
            if ($ci -gt 7) { break }
            $c = $row
            $nested = $row.PSObject.Properties | Where-Object { $_.Name -ceq 'candidate' } | Select-Object -First 1
            if ($null -ne $nested -and $null -ne $nested.Value) { $c = $nested.Value }
            $axisName = Get-ESABCDCandidateFieldText -Item $c -Name 'axis'
            $axisZh = Get-ESABCDCandidateFieldText -Item $c -Name 'axisZh'
            if ([string]::IsNullOrWhiteSpace($axisZh)) { $axisZh = $axisName }
            [void]$cards.Add([pscustomobject]@{
                    title           = "方案 $ci · $axisZh"
                    pitch           = Get-ESABCDCandidateFieldText -Item $c -Name 'productPitch'
                    scenario        = Get-ESABCDCandidateFieldText -Item $c -Name 'concretePlayerScenario'
                    inputSequence   = Get-ESABCDCandidateFieldText -Item $c -Name 'inputSequence'
                    visibleFeedback = Get-ESABCDCandidateFieldText -Item $c -Name 'visibleFeedback'
                    novelMechanism  = Get-ESABCDCandidateFieldText -Item $c -Name 'novelMechanism'
                    risk            = Get-ESABCDCandidateFieldText -Item $c -Name 'risk'
                    hardCost        = '设计候选；需项目上下文审阅'
                    groundedAxis    = $axisName
                    groundedLensId  = Get-ESABCDCandidateFieldText -Item $c -Name 'directionId'
                    contentSource   = 'llm-model'
                })
        }
        $hasCards = $cards.Count -ge 3
        $brief = [pscustomobject]@{
            domain        = 'generic'
            language      = 'zh-CN'
            summary       = if ($hasCards) { '通用题 L1-lite：大模型按轴发散方案卡。' } else { '通用题 L0（模型方向不足）。' }
            cards         = @($cards.ToArray())
            lensesUsed    = $lenses
            requirement   = $Requirement
            mode          = $Mode
            contentSource = 'llm-model'
        }
        if ($hasCards) {
            $deliveryKind = 'domain-brief'
            $pipelineLevel = 'L1'
            $deliveryStatus = 'domain-brief-closed'
            $checklist = [pscustomobject]@{ passed = $true; domain = 'generic'; cardCount = $cards.Count }
        }
        else {
            $deliveryKind = 'lens-only'
            $pipelineLevel = 'L0'
            $deliveryStatus = 'DELIVERY_LENS_ONLY'
            $checklist = [pscustomobject]@{ passed = $true; domain = 'generic'; notes = 'L0 default' }
        }
    }

    return [pscustomobject]@{
        deliveryKind    = $deliveryKind
        pipelineLevel   = $pipelineLevel
        deliveryStatus  = $deliveryStatus
        domain          = $domainInfo.domain
        domainBrief     = $brief
        checklist       = $checklist
        claimLevel      = 'design-candidate'
        runtimeStatus   = 'runtime-not-run'
        nonClaims       = @('not-shipped', 'not-balanced', 'not-runtime-verified', 'not-playmode-verified')
    }
}

function Test-ESABCDLiveOpsBriefChecklist {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Loops)
    $items = @($Loops)
    $need = @('gather', 'craft', 'prep', 'sortie', 'name', 'tilt', 'attractWho', 'annoyWho')
    $missing = New-Object System.Collections.Generic.List[string]
    if ($items.Count -lt 5) { [void]$missing.Add('LOOP_COUNT_LT_5') }
    $gi = 0
    foreach ($loop in $items) {
        $gi++
        foreach ($f in $need) {
            $v = Get-ESABCDCandidateFieldText -Item $loop -Name $f
            if ([string]::IsNullOrWhiteSpace($v)) { [void]$missing.Add("LOOP${gi}_MISSING_$f") }
        }
    }
    $blob = ($items | ConvertTo-Json -Compress -Depth 6)
    foreach ($k in @('采集', '合成', '战备', '出击')) {
        if ($blob.IndexOf($k, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
            $has = $false
            foreach ($loop in $items) {
                foreach ($f in @('gather', 'craft', 'prep', 'sortie', 'name')) {
                    if ((Get-ESABCDCandidateFieldText -Item $loop -Name $f).Length -gt 0) { $has = $true }
                }
            }
            if (-not $has) { [void]$missing.Add("CORPUS_MISSING_$k") }
        }
    }
    $zhSlots = 0
    foreach ($loop in $items) {
        foreach ($f in @('gather', 'craft', 'prep', 'sortie')) {
            if ((Get-ESABCDCandidateFieldText -Item $loop -Name $f).Length -gt 0) { $zhSlots++ }
        }
    }
    if ($zhSlots -lt 20) { [void]$missing.Add('ZH_SLOT_FILL_INCOMPLETE') }

    return [pscustomobject]@{
        passed    = ($missing.Count -eq 0)
        missing   = @($missing.ToArray())
        loopCount = $items.Count
        domain    = 'live-ops-loop'
    }
}

function Complete-ESABCDSelectionDelivery {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$SelectionResult,
        [Parameter(Mandatory)]$Candidates,
        [Parameter(Mandatory)][string]$Requirement,
        [ValidateSet('creative-divergence', 'engineering', 'stable')][string]$Mode = 'creative-divergence',
        [switch]$FailOnTemplateCollision
    )
    $collision = Test-ESABCDTemplateCollision -Candidates $Candidates
    $delivery = New-ESABCDDomainBrief -Requirement $Requirement -RankedLenses $SelectionResult.ranked -Mode $Mode

    $deliveryKind = [string]$delivery.deliveryKind
    $pipelineLevel = [string]$delivery.pipelineLevel
    $claimLevel = [string]$SelectionResult.claimLevel
    if ([string]::IsNullOrWhiteSpace($claimLevel)) { $claimLevel = 'design-candidate' }

    if ([bool]$collision.hasCollision) {
        # Identical lens body templates must not silently look like differentiated scenarios.
        # Domain-brief L1 is filled from requirement slots + ranked axes (not those templates),
        # so keep L1 when checklist already closed; otherwise force lens-only claim.
        if ($FailOnTemplateCollision) {
            throw ("LENS_TEMPLATE_COLLISION:" + $collision.collisionCount)
        }
        if ($deliveryKind -ne 'domain-brief') {
            $deliveryKind = 'lens-only'
            $pipelineLevel = 'L0'
            if (-not $claimLevel.EndsWith('-template')) {
                $claimLevel = 'design-candidate-lens-template-only'
            }
        }
        else {
            if ($claimLevel -notmatch 'domain-brief') {
                $claimLevel = 'design-candidate-domain-brief'
            }
        }
    }

    $out = [pscustomobject]@{
        schemaVersion          = 1
        mode                   = $SelectionResult.mode
        candidateCount         = $SelectionResult.candidateCount
        ranked                 = $SelectionResult.ranked
        recommendedDirectionId = $SelectionResult.recommendedDirectionId
        selectedDirectionId    = $SelectionResult.selectedDirectionId
        selectionStatus        = $SelectionResult.selectionStatus
        rejectedCandidates     = $SelectionResult.rejectedCandidates
        rejectionReasons       = $SelectionResult.rejectionReasons
        hiddenCandidates       = $SelectionResult.hiddenCandidates
        qualityStatus          = $SelectionResult.qualityStatus
        claimLevel             = $claimLevel
        auditDeferred          = $SelectionResult.auditDeferred
        deliveryKind           = $deliveryKind
        pipelineLevel          = $pipelineLevel
        deliveryStatus         = [string]$delivery.deliveryStatus
        runtimeStatus          = 'runtime-not-run'
        nonClaims              = @($delivery.nonClaims)
        templateCollision      = $collision
        domain                 = [string]$delivery.domain
        domainBrief            = $delivery.domainBrief
        domainChecklist        = $delivery.checklist
        commercialContent      = $true
        contentTier           = 'axis-grounded-v1'
    }
    return $out
}

Export-ModuleMember -Function @(
    'Get-ESABCDFileSha256',
    'Get-ESABCDBytesSha256',
    'Get-ESABCDStringSha256',
    'Test-ESABCDTemplateCollision',
    'Test-ESABCDRequirementDomain',
    'New-ESABCDDomainBrief',
    'Test-ESABCDLiveOpsBriefChecklist',
    'Complete-ESABCDSelectionDelivery'
)