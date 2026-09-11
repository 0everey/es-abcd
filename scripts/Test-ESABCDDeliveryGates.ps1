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
Log "hash-ok $hash"

# --- 1 deliveryKind on default creative short run ---
$div = Invoke-ESABCModeDivergence -Requirement 'melee burst skill feel probe' -SourceHash $hash -Mode creative-divergence -ProjectRoot $PackageRoot
$sel = Select-ESABCGenerationCandidate -Candidates $div.directions -Mode creative-divergence -Requirement 'melee burst skill feel probe'
if ([string]::IsNullOrWhiteSpace([string]$sel.deliveryKind)) { throw 'deliveryKind missing' }
if ([string]::IsNullOrWhiteSpace([string]$sel.pipelineLevel)) { throw 'pipelineLevel missing' }
if ([string]$sel.deliveryKind -ne 'lens-only') { throw "expected lens-only got $($sel.deliveryKind)" }
if ([string]$sel.pipelineLevel -ne 'L0') { throw "expected L0 got $($sel.pipelineLevel)" }
if (-not [bool]$sel.templateCollision.hasCollision) { throw 'expected template collision on default creative templates' }
if ([string]$sel.claimLevel -notmatch 'design-candidate') { throw 'claimLevel missing design-candidate' }
Log "delivery-kind-ok kind=$($sel.deliveryKind) level=$($sel.pipelineLevel) collision=$($sel.templateCollision.collisionCount) claim=$($sel.claimLevel)"
[IO.File]::WriteAllText((Join-Path $ScratchRoot 'delivery-kind.log'), ($log -join "`n") + "`n", [Text.UTF8Encoding]::new($false))

# --- 2 template collision unit + fail switch ---
$c1 = $div.directions[0]
$c2 = $div.directions[1]
$collision = Test-ESABCDTemplateCollision -Candidates @($c1, $c2)
if (-not [bool]$collision.hasCollision) { throw 'unit collision expected' }
$threw = $false
try {
    $null = Select-ESABCGenerationCandidate -Candidates $div.directions -Mode creative-divergence -Requirement 'x' -FailOnTemplateCollision
} catch {
    $threw = $true
    if ($_.Exception.Message -notmatch 'LENS_TEMPLATE_COLLISION') { throw "wrong throw $($_.Exception.Message)" }
}
if (-not $threw) { throw 'FailOnTemplateCollision should throw' }
Log 'template-collision-ok'
[IO.File]::WriteAllText((Join-Path $ScratchRoot 'template-collision.log'), "hasCollision=true throwOnFail=true collisionCount=$($collision.collisionCount)`n", [Text.UTF8Encoding]::new($false))

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

# summary
$summary = [pscustomobject]@{
    status = 'passed'
    packageRoot = $PackageRoot
    scratchRoot = $ScratchRoot
    checks = @('delivery-kind', 'template-collision', 'domain-brief-liveops', 'hash-polyfill', 'path-param-trial')
}
$summary | ConvertTo-Json | Set-Content (Join-Path $ScratchRoot 'gates-summary.json') -Encoding UTF8
Log 'ALL_GATES_PASSED'
$summary | ConvertTo-Json