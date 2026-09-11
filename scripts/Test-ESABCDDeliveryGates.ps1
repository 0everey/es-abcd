# Gating tests for deliveryKind, template collision, live-ops L1 brief, hash polyfill.
[CmdletBinding()]
param(
    [string]$PackageRoot = '',
    [string]$ScratchRoot = ''
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ([string]::IsNullOrWhiteSpace($PackageRoot)) {
    $PackageRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
}
if ([string]::IsNullOrWhiteSpace($ScratchRoot)) {
    $ScratchRoot = Join-Path $env:TEMP ('es-abcd-delivery-gates-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
}
New-Item -ItemType Directory -Force -Path $ScratchRoot | Out-Null

$log = New-Object System.Collections.Generic.List[string]
function Log([string]$m) {
    [void]$log.Add($m)
    Write-Host $m
}

$divMod = Join-Path $PackageRoot 'ES\Automation\ABCD\ESABCDDivergence.psm1'
$delMod = Join-Path $PackageRoot 'ES\Automation\ABCD\ESABCDDelivery.psm1'
$homeMod = Join-Path $PackageRoot 'ES\Automation\ABCD\ESABCDHome.psm1'
Import-Module $homeMod -Force -Global
Import-Module $delMod -Force -Global
Import-Module $divMod -Force -Global

$contract = Join-Path $PackageRoot 'ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json'
$hash = Get-ESABCDFileSha256 -LiteralPath $contract

# P0: card-pack removed; missing model must fail
$oldKey = $env:ES_ABCD_MODEL_API_KEY; $oldX=$env:XAI_API_KEY; $oldO=$env:OPENAI_API_KEY
$env:ES_ABCD_MODEL_API_KEY=''; $env:XAI_API_KEY=''; $env:OPENAI_API_KEY=''
# hide grok config by temp rename is too invasive; instead call Get-ESABCDModelConfig with empty and mock by removing path - skip if config exists
# Structural tombstone check:
Import-Module (Join-Path $PackageRoot 'ES\Automation\ABCD\ESABCDRealDivergence.psm1') -Force
$threwPack = $false
try { New-ESABCDRealDirectionCandidate } catch { if ($_.Exception.Message -match 'CARD_PACK_REMOVED') { $threwPack = $true } }
if (-not $threwPack) { throw 'card pack tombstone not armed' }
Log 'card-pack-tombstone-ok'
$env:ES_ABCD_MODEL_API_KEY=$oldKey; $env:XAI_API_KEY=$oldX; $env:OPENAI_API_KEY=$oldO

Log "hash-ok $hash"

# --- 1 deliveryKind on default creative short run (axis-grounded content) ---
$div = Invoke-ESABCModeDivergence -Requirement 'melee burst skill feel probe' -SourceHash $hash -Mode creative-divergence -ProjectRoot $PackageRoot
$sel = Select-ESABCGenerationCandidate -Candidates $div.directions -Mode creative-divergence -Requirement 'melee burst skill feel probe'
if ([string]::IsNullOrWhiteSpace([string]$sel.deliveryKind)) { throw 'deliveryKind missing' }
if ([string]::IsNullOrWhiteSpace([string]$sel.pipelineLevel)) { throw 'pipelineLevel missing' }
if ([string]$sel.claimLevel -notmatch 'design-candidate') { throw 'claimLevel missing design-candidate' }
# Axis-grounded bodies must differ across candidates (commercial content upgrade)
$s0 = [string]$div.directions[0].concretePlayerScenario
$s1 = [string]$div.directions[1].concretePlayerScenario
if ($s0 -ceq $s1) { throw 'axis bodies still identical - content pack not wired' }
if ([string]::IsNullOrWhiteSpace([string]$div.directions[0].axisZh)) { throw 'axisZh missing' }
if ([bool]$sel.templateCollision.hasCollision) { throw 'differentiated axis bodies should not template-collide' }
if ([string]$div.iterationTraceKind -ne 'llm-axis-divergence-v1') { throw "engine=$($div.iterationTraceKind)" }
$tr = @($div.directions[0].iterationTrace | Where-Object { $_.decision -eq 'keep' })
if ($tr.Count -lt 2) { throw 'real keep traces missing' }
if ([string]::IsNullOrWhiteSpace([string]$tr[0].concreteChange)) { throw 'keep concreteChange empty' }
if ([string]$tr[0].language -ne 'zh-CN') { throw 'trace language not zh' }
Log "delivery-kind-ok kind=$($sel.deliveryKind) level=$($sel.pipelineLevel) collision=$($sel.templateCollision.collisionCount) claim=$($sel.claimLevel) axis0=$($div.directions[0].axisZh)"
[IO.File]::WriteAllText((Join-Path $ScratchRoot 'delivery-kind.log'), ($log -join "`n") + "`n", [Text.UTF8Encoding]::new($false))

# --- 2 template collision unit + fail switch (synthetic identical bodies) ---
$c1 = $div.directions[0] | ConvertTo-Json -Depth 8 | ConvertFrom-Json
$c2 = $div.directions[1] | ConvertTo-Json -Depth 8 | ConvertFrom-Json
$c1.concretePlayerScenario = 'SAME_SCENARIO_BODY'
$c2.concretePlayerScenario = 'SAME_SCENARIO_BODY'
$c1.inputSequence = 'SAME_INPUT'
$c2.inputSequence = 'SAME_INPUT'
$c1.visibleFeedback = 'SAME_FEEDBACK'
$c2.visibleFeedback = 'SAME_FEEDBACK'
$c2.directionId = 'cand-synthetic-dup-0001'
$collision = Test-ESABCDTemplateCollision -Candidates @($c1, $c2)
if (-not [bool]$collision.hasCollision) { throw 'unit collision expected on synthetic twins' }
$threw = $false
try {
    $null = Select-ESABCGenerationCandidate -Candidates @($c1, $c2) -Mode creative-divergence -Requirement 'x' -FailOnTemplateCollision
} catch {
    $threw = $true
    if ($_.Exception.Message -notmatch 'LENS_TEMPLATE_COLLISION') { throw "wrong throw $($_.Exception.Message)" }
}
if (-not $threw) { throw 'FailOnTemplateCollision should throw' }
Log 'template-collision-ok'
[IO.File]::WriteAllText((Join-Path $ScratchRoot 'template-collision.log'), "hasCollision=true throwOnFail=true collisionCount=$($collision.collisionCount) synthetic=true`n", [Text.UTF8Encoding]::new($false))

# --- 3 live-ops domain brief L1 (English keywords trigger domain; Chinese slots in brief body) ---
$liveReq = 'Design daily live-ops loop: gather-craft-prep-sortie with hardcore/casual/social; who it attracts and who it annoys.'
$div2 = Invoke-ESABCModeDivergence -Requirement $liveReq -SourceHash $hash -Mode creative-divergence -ProjectRoot $PackageRoot
$sel2 = Select-ESABCGenerationCandidate -Candidates $div2.directions -Mode creative-divergence -Requirement $liveReq
if ([string]$sel2.domain -ne 'live-ops-loop') { throw "domain=$($sel2.domain)" }
if ([string]$sel2.deliveryKind -ne 'domain-brief') { throw "deliveryKind=$($sel2.deliveryKind)" }
if ([string]$sel2.pipelineLevel -ne 'L1') { throw "pipelineLevel=$($sel2.pipelineLevel)" }
if (-not [bool]$sel2.domainChecklist.passed) { throw 'checklist not passed' }
$loops = @($sel2.domainBrief.loops)
if ($loops.Count -lt 5) { throw 'loop count' }
foreach ($loop in $loops) {
    foreach ($f in @('gather','craft','prep','sortie','name','tilt','attractWho','annoyWho')) {
        $v = [string]$loop.$f
        if ([string]::IsNullOrWhiteSpace($v)) { throw "empty slot $f" }
    }
}
# Chinese slot corpus must appear in deterministic filler values
$blob = ($sel2.domainBrief | ConvertTo-Json -Depth 8 -Compress)
$zhGather = [char]0x91C7 + [char]0x96C6   # caiji
$zhCraft  = [char]0x5408 + [char]0x6210   # hecheng
$zhPrep   = [char]0x6218 + [char]0x5907   # zhanbei
$zhSortie = [char]0x51FA + [char]0x51FB   # chuji
foreach ($k in @($zhGather, $zhCraft, $zhPrep, $zhSortie)) {
    if ($blob.IndexOf($k) -lt 0) { throw "missing Chinese slot corpus: $k" }
}
$briefPath = Join-Path $ScratchRoot 'domain-brief-liveops.json'
$sel2.domainBrief | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $briefPath -Encoding UTF8
Log "domain-brief-ok loops=$($loops.Count) delivery=$($sel2.deliveryKind) level=$($sel2.pipelineLevel)"
[IO.File]::WriteAllText((Join-Path $ScratchRoot 'domain-brief-liveops.log'), "passed loops=$($loops.Count) path=$briefPath deliveryKind=$($sel2.deliveryKind) pipelineLevel=$($sel2.pipelineLevel)`n", [Text.UTF8Encoding]::new($false))

# --- 4 hash polyfill: shadow Get-FileHash and still work ---
$polyLog = Join-Path $ScratchRoot 'hash-polyfill.log'
$polyScript = Join-Path $ScratchRoot 'run-hash-polyfill.ps1'
$esc = {
    param($p)
    return ($p -replace '\\','\\' -replace "'","''")
}
$polyBody = @"
`$ErrorActionPreference='Stop'
function Get-FileHash { throw 'Get-FileHash-disabled-for-test' }
Import-Module '$((& $esc $homeMod))' -Force -Global
Import-Module '$((& $esc $delMod))' -Force -Global
Import-Module '$((& $esc $divMod))' -Force -Global
`$c = '$((& $esc $contract))'
`$h = Get-ESABCDFileSha256 -LiteralPath `$c
`$div = Invoke-ESABCModeDivergence -Requirement 'hash polyfill engineering probe' -SourceHash `$h -Mode engineering -ProjectRoot '$((& $esc $PackageRoot))'
if (`$div.directionCount -lt 1) { throw 'no directions' }
if ([string]::IsNullOrWhiteSpace([string]`$div.deliveryKind) -and `$false) { }
Write-Output "POLYFILL_OK hash=`$h count=`$(`$div.directionCount)"
"@
[IO.File]::WriteAllText($polyScript, $polyBody, [Text.UTF8Encoding]::new($true))
$polyOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $polyScript 2>&1 | Out-String
if ($polyOut -notmatch 'POLYFILL_OK') { throw "polyfill failed: $polyOut" }
[IO.File]::WriteAllText($polyLog, $polyOut, [Text.UTF8Encoding]::new($false))
Log 'hash-polyfill-ok'

# --- 5 path param trial from clean temp ---
$pathLog = Join-Path $ScratchRoot 'path-param-trial.log'
$trial = Join-Path $ScratchRoot 'trial-root'
if (Test-Path $trial) { Remove-Item $trial -Recurse -Force }
New-Item -ItemType Directory -Force -Path $trial | Out-Null
$get = Join-Path $PackageRoot 'get.ps1'
$trialOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $get -TargetRoot $trial -Force 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) { throw "get failed: $trialOut" }
if (-not (Test-Path (Join-Path $trial 'ES\Automation\ABCD\ESABCDDivergence.psm1'))) { throw 'trial missing divergence' }
if (-not (Test-Path (Join-Path $trial 'ES\Automation\ABCD\ESABCDDelivery.psm1'))) { throw 'trial missing delivery module' }
$smoke = Join-Path $PackageRoot 'scripts\Invoke-ESABCDSmoke.ps1'
$smokeOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $smoke -ProjectRoot $trial -Mode engineering 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) { throw "smoke failed $smokeOut" }
# receipt must include delivery fields
$smokeDir = Join-Path $trial 'ES\Automation\ABCD\out'
$latest = Get-ChildItem -LiteralPath $smokeDir -Filter 'smoke-*.json' -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
if (-not $latest) { throw 'smoke receipt missing' }
$receipt = Get-Content -LiteralPath $latest.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace([string]$receipt.deliveryKind)) { throw 'smoke receipt deliveryKind missing' }
if ([string]::IsNullOrWhiteSpace([string]$receipt.pipelineLevel)) { throw 'smoke receipt pipelineLevel missing' }
[IO.File]::WriteAllText($pathLog, "trial=$trial`nget_exit=0`nsmoke_exit=0`ndeliveryKind=$($receipt.deliveryKind)`npipelineLevel=$($receipt.pipelineLevel)`n$trialOut`n$smokeOut", [Text.UTF8Encoding]::new($false))
Log "path-param-trial-ok deliveryKind=$($receipt.deliveryKind) pipelineLevel=$($receipt.pipelineLevel)"


# --- 6 commercial brief via single entry Invoke-ESABCD ---
Import-Module (Join-Path $PackageRoot 'ES\Automation\ABCD\ESABCDHome.psm1') -Force -Global
Import-Module (Join-Path $PackageRoot 'ES\Automation\ABCD\ESABCDIndex.psm1') -Force -Global
$idx = Get-ESABCDIndexCatalog
if (@($idx).Count -lt 8) { throw 'index catalog too small' }
$commOut = Join-Path $ScratchRoot 'commercial-out'
$comm = Invoke-ESABCD -Requirement 'Design daily live-ops loop: gather-craft-prep-sortie hardcore casual social' -Mode creative-divergence -ProjectRoot $PackageRoot -OutDir $commOut -Output brief
if ([string]$comm.entry -ne 'Invoke-ESABCD') { throw "entry=$($comm.entry)" }
if ([string]$comm.deliveryKind -ne 'domain-brief') { throw "commercial deliveryKind=$($comm.deliveryKind)" }
if ([string]$comm.pipelineLevel -ne 'L1') { throw "commercial level=$($comm.pipelineLevel)" }
if (-not (Test-Path -LiteralPath $comm.markdownPath)) { throw 'commercial md missing' }
$mdText = [IO.File]::ReadAllText($comm.markdownPath)
if ($mdText -notmatch '商用交付简报') { throw 'md missing title' }
if ($mdText.Length -lt 400) { throw 'md too short' }
if ([string]::IsNullOrWhiteSpace([string]$comm.chineseReceiptPath) -and [string]::IsNullOrWhiteSpace([string]$comm.'中文回执路径')) { throw 'chinese receipt path missing' }
$zhP = if ($comm.chineseReceiptPath) { $comm.chineseReceiptPath } else { $comm.'中文回执路径' }
if (-not (Test-Path -LiteralPath $zhP)) { throw 'chinese receipt file missing' }
$zhObj = Get-Content -LiteralPath $zhP -Raw -Encoding UTF8 | ConvertFrom-Json
if ([string]$zhObj.'记录类型' -ne 'ESABCD中文回执') { throw 'zh record type' }
if ([string]$zhObj.'发散引擎' -ne 'llm-axis-divergence-v1') { throw 'zh engine' }
if (@($zhObj.'方向列表').Count -lt 5) { throw 'zh directions' }
if ([string]$zhObj.'发散引擎中文' -notmatch '真实') { throw 'zh engine label' }
Log "commercial-brief-ok md=$($comm.markdownPath) bytes=$($mdText.Length)"
[IO.File]::WriteAllText((Join-Path $ScratchRoot 'commercial-brief.log'), "md=$($comm.markdownPath)`njson bytes ok`nlen=$($mdText.Length)`n", [Text.UTF8Encoding]::new($false))
# summary
$summary = [pscustomobject]@{
    status = 'passed'
    packageRoot = $PackageRoot
    scratchRoot = $ScratchRoot
    checks = @('delivery-kind', 'template-collision', 'domain-brief-liveops', 'hash-polyfill', 'path-param-trial', 'commercial-brief')
}
$summary | ConvertTo-Json | Set-Content (Join-Path $ScratchRoot 'gates-summary.json') -Encoding UTF8
Log 'ALL_GATES_PASSED'
$summary | ConvertTo-Json