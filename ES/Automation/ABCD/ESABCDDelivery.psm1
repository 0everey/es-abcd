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
                $loopNames = @(
            [ordered]@{ name = '晨采急袭环'; tilt = '硬核'; attract = '追求效率的肝党'; annoy = '休闲玩家（时间压迫）'; gather = '限时采集高风险点'; craft = '战场边角急合成'; prep = '战备轻装速配'; sortie = '短线出击清日常' }
            [ordered]@{ name = '稳产工坊环'; tilt = '休闲'; attract = '碎片时间玩家'; annoy = '硬核竞速党（节奏慢）'; gather = '安全区挂机采集'; craft = '工坊批量合成'; prep = '战备一键套装'; sortie = '低压力出击领奖' }
            [ordered]@{ name = '社交拼单环'; tilt = '社交'; attract = '公会/组队玩家'; annoy = '独狼（等待成本）'; gather = '组队共享采集'; craft = '拼单合成分红'; prep = '战备队内配装检查'; sortie = '小队联合作战' }
            [ordered]@{ name = '风险勘探环'; tilt = '硬核'; attract = '探索向玩家'; annoy = '怕亏资源的玩家'; gather = '未知点勘探采集'; craft = '高失败率实验合成'; prep = '战备带保险消耗品'; sortie = '高风险高回报出击' }
            [ordered]@{ name = '赛季冲刺环'; tilt = '硬核'; attract = '冲榜党'; annoy = '追进度焦虑者'; gather = '赛季限定点'; craft = '冲榜配方'; prep = '战备极限配装'; sortie = '排行榜本' }
        )
        $loopList = New-Object System.Collections.Generic.List[object]
        $li = 0
        foreach ($ln in $loopNames) {
            $lens = $lenses[[Math]::Min($li, $lenses.Count - 1)]
            [void]$loopList.Add([pscustomobject]@{
                    loopIndex      = ($li + 1)
                    name           = [string]$ln['name']
                    tilt           = [string]$ln['tilt']
                    attractWho     = [string]$ln['attract']
                    annoyWho       = [string]$ln['annoy']
                    gather         = [string]$ln['gather']
                    craft          = [string]$ln['craft']
                    prep           = [string]$ln['prep']
                    sortie         = [string]$ln['sortie']
                    groundedAxis   = [string]$lens.axis
                    groundedLensId = [string]$lens.directionId
                })
            $li++
        }
        $loopArr = @($loopList.ToArray())
        $checklist = Test-ESABCDLiveOpsBriefChecklist -Loops $loopArr
        $brief = [pscustomobject]@{
            domain      = 'live-ops-loop'
            language    = 'zh-CN'
            summary     = '基于 ranked 透镜生成的日活五环领域简报（确定性槽位填充，非外部大模型）。'
            loops       = $loopArr
            lensesUsed  = $lenses
            requirement = $Requirement
            mode        = $Mode
        }
        if ([bool]$checklist.passed) {
            $deliveryKind = 'domain-brief'
            $pipelineLevel = 'L1'
            $deliveryStatus = 'domain-brief-closed'
        }
        else {
            $deliveryKind = 'lens-only'
            $pipelineLevel = 'L0'
            $deliveryStatus = 'REQUIREMENT_NOT_GROUNDED'
        }
    }
    elseif ($domainInfo.domain -eq 'combat-feel') {
        # L1 feel cards from ranked lenses (commercial content, still design-candidate)
        Import-Module (Join-Path $PSScriptRoot 'ESABCDCommercialContent.psm1') -Force -Global
        $cards = New-Object System.Collections.Generic.List[object]
        $ci = 0
        foreach ($lens in $lenses) {
            $ci++
            if ($ci -gt 5) { break }
            $axisName = if ([string]::IsNullOrWhiteSpace([string]$lens.axis)) { 'moment-to-moment-feel' } else { [string]$lens.axis }
            $body = Get-ESABCDAxisBodyFields -Axis $axisName -Mode $Mode -Requirement $Requirement -Ordinal $ci
            [void]$cards.Add([pscustomobject]@{
                    title          = "手感方案 $ci · $($body.axisZh)"
                    pitch          = [string]$body.productPitch
                    scenario       = [string]$body.concretePlayerScenario
                    inputSequence  = [string]$body.inputSequence
                    visibleFeedback= [string]$body.visibleFeedback
                    novelMechanism = [string]$body.novelMechanism
                    risk           = [string]$body.risk
                    hardCost       = '需实机组手感与帧数据验证；当前为设计候选'
                    groundedAxis   = $axisName
                    groundedLensId = [string]$lens.directionId
                })
        }
        while ($cards.Count -lt 5) {
            $n = $cards.Count + 1
            $body = Get-ESABCDAxisBodyFields -Axis 'moment-to-moment-feel' -Mode $Mode -Requirement $Requirement -Ordinal $n
            [void]$cards.Add([pscustomobject]@{
                    title = "手感方案 $n · $($body.axisZh)"; pitch = $body.productPitch; scenario = $body.concretePlayerScenario
                    inputSequence = $body.inputSequence; visibleFeedback = $body.visibleFeedback; novelMechanism = $body.novelMechanism
                    risk = $body.risk; hardCost = '需实机验证'; groundedAxis = 'moment-to-moment-feel'; groundedLensId = ''
                })
        }
        $brief = [pscustomobject]@{
            domain     = 'combat-feel'
            language   = 'zh-CN'
            summary    = '近战/手感域 L1：按透镜展开的 5 张可讨论手感方案卡（含场景/输入/反馈/机制/硬伤）。'
            cards      = @($cards.ToArray())
            lensesUsed = $lenses
            requirement= $Requirement
            mode       = $Mode
        }
        $deliveryKind = 'domain-brief'
        $pipelineLevel = 'L1'
        $deliveryStatus = 'domain-brief-closed'
        $checklist = [pscustomobject]@{ passed = ($cards.Count -ge 5); domain = 'combat-feel'; cardCount = $cards.Count }
    }
    else {
        # Generic commercial: still emit ranked axis cards as L1-lite content pack when we have grounded bodies
        Import-Module (Join-Path $PSScriptRoot 'ESABCDCommercialContent.psm1') -Force -Global
        $cards = New-Object System.Collections.Generic.List[object]
        $ci = 0
        foreach ($lens in $lenses) {
            $ci++
            if ($ci -gt 7) { break }
            $axisName = if ([string]::IsNullOrWhiteSpace([string]$lens.axis)) { 'integration-fit' } else { [string]$lens.axis }
            $body = Get-ESABCDAxisBodyFields -Axis $axisName -Mode $Mode -Requirement $Requirement -Ordinal $ci
            [void]$cards.Add([pscustomobject]@{
                    title          = "方案 $ci · $($body.axisZh)"
                    pitch          = [string]$body.productPitch
                    scenario       = [string]$body.concretePlayerScenario
                    inputSequence  = [string]$body.inputSequence
                    visibleFeedback= [string]$body.visibleFeedback
                    novelMechanism = [string]$body.novelMechanism
                    risk           = [string]$body.risk
                    hardCost       = '设计候选；需项目上下文审阅'
                    groundedAxis   = $axisName
                    groundedLensId = [string]$lens.directionId
                })
        }
        $hasCards = $cards.Count -ge 3
        $brief = [pscustomobject]@{
            domain      = 'generic'
            language    = 'zh-CN'
            summary     = if ($hasCards) { '通用题商用 L1-lite：按模式轴展开的可讨论方案卡（非特定域槽位）。' } else { '通用题 L0 透镜排序。' }
            cards       = @($cards.ToArray())
            lensesUsed  = $lenses
            requirement = $Requirement
            mode        = $Mode
        }
        if ($hasCards) {
            $deliveryKind = 'domain-brief'
            $pipelineLevel = 'L1'
            $deliveryStatus = 'domain-brief-closed'
            $checklist = [pscustomobject]@{ passed = $true; domain = 'generic'; cardCount = $cards.Count; notes = 'L1-lite axis cards' }
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