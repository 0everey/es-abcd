# Real battle test for portable es-abcd commercial path.
[CmdletBinding()]
param(
    [string]$PackageRoot = '',
    [string]$BattleRoot = ''
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ([string]::IsNullOrWhiteSpace($PackageRoot)) {
    $PackageRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
}
if ([string]::IsNullOrWhiteSpace($BattleRoot)) {
    $BattleRoot = Join-Path $env:TEMP ('es-abcd-battle-' + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss'))
}
New-Item -ItemType Directory -Force -Path $BattleRoot | Out-Null
$trial = Join-Path $BattleRoot 'consumer-project'
New-Item -ItemType Directory -Force -Path $trial | Out-Null
$reportPath = Join-Path $BattleRoot 'BATTLE-REPORT.md'
$lines = New-Object System.Collections.Generic.List[string]
function L([string]$m) { [void]$lines.Add($m); Write-Host $m }
function Prop($obj, [string]$name) {
    $p = $obj.PSObject.Properties | Where-Object { $_.Name -eq $name } | Select-Object -First 1
    if ($null -eq $p) { return $null }
    return $p.Value
}

L '# es-abcd battle test report'
L ''
L ('> UTC: ' + [DateTime]::UtcNow.ToString('o'))
L ('> package: ' + $PackageRoot)
L ('> scratch: ' + $BattleRoot)
L ''

L '## 1. Clean install'
$sw = [Diagnostics.Stopwatch]::StartNew()
$installOut = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PackageRoot 'get.ps1') -TargetRoot $trial -Force 2>&1 | Out-String
$sw.Stop()
if ($LASTEXITCODE -ne 0) { throw ('install failed: ' + $installOut) }
$hasUse = Test-Path (Join-Path $trial 'ES\Automation\ABCD\Use-ESABCD.ps1')
$hasReal = Test-Path (Join-Path $trial 'ES\Automation\ABCD\ESABCDModelDivergence.psm1')
$testCount = @(Get-ChildItem (Join-Path $trial 'ES\Automation\ABCD') -Filter 'Test-*.ps1' -File -ErrorAction SilentlyContinue).Count
L ('- status: PASS (' + $sw.ElapsedMilliseconds + ' ms)')
L ('- Use-ESABCD=' + $hasUse + ' ModelDivergence=' + $hasReal + ' TestCount=' + $testCount)
if (-not ($hasUse -and $hasReal)) { throw 'core files missing after install' }

$cases = @(
    [pscustomobject]@{ id='B-CRE-01'; mode='creative-divergence'; title='melee-feel'; req='melee burst skill feel, at least 5 directions, counterplay and hitstop feedback, Chinese design OK' },
    [pscustomobject]@{ id='B-CRE-02'; mode='creative-divergence'; title='live-ops'; req='Design daily live-ops loop: gather-craft-prep-sortie five loops hardcore casual social who attracts who annoys' },
    [pscustomobject]@{ id='B-ENG-01'; mode='engineering'; title='skill-system'; req='Design extensible skill system active passive cooldown cost level single entry no dual systems' }
)
# Prefer Chinese requirements via unicode construction for realism
function U([int[]]$cp) { -join ($cp | ForEach-Object { [char]$_ }) }
$cases[0].req = (U 0x8FD1,0x6218,0x7206,0x53D1,0x6280,0x80FD,0x624B,0x611F) + (U 0xFF0C,0x81F3,0x5C11,0x35,0x79CD,0x65B9,0x5411,0xFF0C,0x8981,0x53EF,0x53CD,0x5236,0x3001,0x6709,0x987F,0x5E27,0x4E0E,0x547D,0x4E2D,0x53CD,0x9988)
$cases[1].req = (U 0x8BBE,0x8BA1,0x65E5,0x6D3B,0xFF1A) + (U 0x91C7,0x96C6) + '-' + (U 0x5408,0x6210) + '-' + (U 0x6218,0x5907) + '-' + (U 0x51FA,0x51FB) + ' ' + (U 0x4E94,0x6761,0x5FAA,0x73AF) + (U 0xFF0C,0x542B,0x786C,0x6838,0x002F,0x4F11,0x95F2,0x002F,0x793E,0x4EA4)
$cases[2].req = (U 0x8BBE,0x8BA1,0x53EF,0x6269,0x5C55,0x6280,0x80FD,0x7CFB,0x7EDF) + (U 0xFF1A,0x4E3B,0x52A8,0x002F,0x88AB,0x52A8,0x002F,0x51B7,0x5374,0x002F,0x6D88,0x8017,0x002F,0x7B49,0x7EA7) + (U 0xFF0C,0x552F,0x4E00,0x5165,0x53E3,0xFF0C,0x7981,0x6B62,0x53CC,0x7CFB,0x7EDF)

L ''
L '## 2. Three live scenarios'
$summary = New-Object System.Collections.Generic.List[object]
foreach ($c in $cases) {
    L ''
    L ('### ' + $c.id + ' / ' + $c.title + ' / ' + $c.mode)
    $caseOut = Join-Path $BattleRoot $c.id
    New-Item -ItemType Directory -Force -Path $caseOut | Out-Null
    $run = Join-Path $caseOut 'run.ps1'
    $reqLiteral = $c.req.Replace("'", "''")
    $runBody = @(
        '$ErrorActionPreference=''Stop'''
        ('. ''' + $trial.Replace('''','''''') + '\ES\Automation\ABCD\Use-ESABCD.ps1''')
        ('$r = Invoke-ESABCD -Requirement ''' + $reqLiteral + ''' -Mode ' + $c.mode + ' -ProjectRoot ''' + $trial.Replace('''','''''') + ''' -OutDir ''' + $caseOut.Replace('''','''''') + ''' -Output brief')
        '$zh = [string]$r.chineseReceiptPath'
        'if ([string]::IsNullOrWhiteSpace($zh)) { $zh = [string]$r.''中文回执路径'' }'
        'if (-not (Test-Path -LiteralPath $zh)) { throw ''missing zh receipt'' }'
        '$md = [string]$r.markdownPath'
        'Write-Output (''OK|'' + [string]$r.divergenceEngine + ''|'' + $zh + ''|'' + $md + ''|'' + [string]$r.deliveryKind + ''|'' + [string]$r.pipelineLevel + ''|'' + [int]$r.directionCount)'
    ) -join "`r`n"
    [IO.File]::WriteAllText($run, $runBody, [Text.UTF8Encoding]::new($true))
    $swc = [Diagnostics.Stopwatch]::StartNew()
    $raw = & powershell -NoProfile -ExecutionPolicy Bypass -File $run 2>&1 | Out-String
    $swc.Stop()
    if ($LASTEXITCODE -ne 0) { throw ($c.id + ' failed: ' + $raw) }
    $okLine = @($raw -split "`r?`n" | Where-Object { $_ -match '^OK\|' } | Select-Object -Last 1)[0]
    if ([string]::IsNullOrWhiteSpace($okLine)) { throw ($c.id + ' no OK line') }
    $p = $okLine.Split('|')
    $engine=$p[1]; $zhPath=$p[2]; $mdPath=$p[3]; $kind=$p[4]; $level=$p[5]; $dcount=[int]$p[6]
    $zh = Get-Content -LiteralPath $zhPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $dirs = @(Prop $zh '方向列表')
    $top = $dirs | Where-Object { [bool](Prop $_ '是否主推荐') } | Select-Object -First 1
    if ($null -eq $top) { $top = $dirs[0] }
    $keeps = @(Prop $top '真实分支保留摘要')
    $fails = New-Object System.Collections.Generic.List[string]
    if ($engine -cne 'llm-axis-divergence-v1') { [void]$fails.Add('engine='+$engine) }
    if ([string](Prop $zh '记录类型') -cne 'ESABCD中文回执') { [void]$fails.Add('record') }
    if ($dirs.Count -lt 5) { [void]$fails.Add('dirs='+$dirs.Count) }
    if ($keeps.Count -lt 2) { [void]$fails.Add('keeps='+$keeps.Count) }
    $scene = [string](Prop $top '玩家场景')
    if ($scene -notmatch '第[0-9]+轮') { [void]$fails.Add('no-round-mark') }
    if (-not (Test-Path -LiteralPath $mdPath)) { [void]$fails.Add('md-missing') }
    if ($c.id -eq 'B-CRE-02') {
        $brief = Prop $zh '领域简报'
        $loops = @(Prop $brief '日活环')
        if ($kind -cne 'domain-brief' -or $loops.Count -lt 5) { [void]$fails.Add('liveops') }
        $blob = Get-Content -LiteralPath $zhPath -Raw -Encoding UTF8
        foreach ($w in @((U 0x91C7,0x96C6),(U 0x5408,0x6210),(U 0x6218,0x5907),(U 0x51FA,0x51FB))) {
            if ($blob.IndexOf($w) -lt 0) { [void]$fails.Add('slot-missing') }
        }
    }
    $status = if ($fails.Count -eq 0) { 'PASS' } else { 'FAIL:' + ($fails -join ',') }
    L ('- status: **' + $status + '** (' + $swc.ElapsedMilliseconds + ' ms)')
    L ('- engine: `' + $engine + '` / ' + [string](Prop $zh '发散引擎中文'))
    L ('- delivery: ' + [string](Prop $zh '交付种类中文') + ' | ' + [string](Prop $zh '流水线中文') + ' | ' + [string](Prop $zh '声明级别中文'))
    L ('- directions: ' + $dirs.Count + ' | top: **' + [string](Prop $top '轴中文') + '** score=' + (Prop $top '排序分'))
    L ('- pitch: ' + [string](Prop $top '一句话卖点'))
    L ('- keep traces: ' + $keeps.Count)
    if ($keeps.Count -gt 0) { L ('  1) ' + [string]$keeps[0]) }
    if ($keeps.Count -gt 1) { L ('  2) ' + [string]$keeps[1]) }
    L ('- zh receipt: `' + $zhPath + '` (' + (Get-Item $zhPath).Length + ' bytes)')
    L ('- md brief: `' + $mdPath + '` (' + (Get-Item $mdPath).Length + ' bytes)')
    if ($fails.Count -gt 0) { throw ($c.id + ' ' + $status) }
    [void]$summary.Add([pscustomobject]@{ id=$c.id; status=$status; ms=$swc.ElapsedMilliseconds; engine=$engine; dirs=$dirs.Count; top=[string](Prop $top '轴中文') })
}

L ''
L '## 3. Axis body difference check'
$diffOut = Join-Path $BattleRoot 'diff-check'
New-Item -ItemType Directory -Force -Path $diffOut | Out-Null
$diffRun = Join-Path $diffOut 'run.ps1'
$diffBody = @(
    '$ErrorActionPreference=''Stop'''
    ('. ''' + $trial.Replace('''','''''') + '\ES\Automation\ABCD\Use-ESABCD.ps1''')
    ('$r = Invoke-ESABCD -Requirement ''diff-check'' -Mode creative-divergence -ProjectRoot ''' + $trial.Replace('''','''''') + ''' -OutDir ''' + $diffOut.Replace('''','''''') + ''' -Output select')
    '$a=[string]$r.divergence.directions[0].concretePlayerScenario'
    '$b=[string]$r.divergence.directions[1].concretePlayerScenario'
    '$coll=[bool]$r.selection.templateCollision.hasCollision'
    'Write-Output (''DIFF|'' + ($a -cne $b) + ''|'' + $coll + ''|'' + $r.divergenceEngine)'
) -join "`r`n"
[IO.File]::WriteAllText($diffRun, $diffBody, [Text.UTF8Encoding]::new($true))
$diffRaw = & powershell -NoProfile -ExecutionPolicy Bypass -File $diffRun 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) { throw ('diff failed ' + $diffRaw) }
$diffLine = @($diffRaw -split "`r?`n" | Where-Object { $_ -match '^DIFF\|' } | Select-Object -Last 1)[0]
$dp = $diffLine.Split('|')
L ('- scenarios differ: **' + $dp[1] + '**')
L ('- templateCollision: **' + $dp[2] + '** (expect False)')
L ('- engine: ' + $dp[3])
if ($dp[1] -ne 'True') { throw 'scenarios identical' }
if ($dp[2] -ne 'False') { throw 'unexpected collision' }

L ''
L '## 4. Consumer smoke'
$sws = [Diagnostics.Stopwatch]::StartNew()
$smokeOut = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PackageRoot 'scripts\Invoke-ESABCDSmoke.ps1') -ProjectRoot $trial -Mode engineering 2>&1 | Out-String
$sws.Stop()
if ($LASTEXITCODE -ne 0) { throw ('smoke failed ' + $smokeOut) }
$smokeFile = Get-ChildItem (Join-Path $trial 'ES\Automation\ABCD\out') -Filter 'smoke-*.json' | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
$smoke = Get-Content $smokeFile.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
L ('- status: PASS (' + $sws.ElapsedMilliseconds + ' ms)')
L ('- deliveryKind=' + $smoke.deliveryKind + ' pipelineLevel=' + $smoke.pipelineLevel + ' runtime=' + $smoke.runtimeStatus)

L ''
L '## 5. Summary table'
L ''
L '| case | status | ms | engine | dirs | top axis |'
L '|------|--------|----|--------|------|----------|'
foreach ($s in $summary) {
    L ('| ' + $s.id + ' | ' + $s.status + ' | ' + $s.ms + ' | `' + $s.engine + '` | ' + $s.dirs + ' | ' + $s.top + ' |')
}
L '| install | PASS | - | - | - | - |'
L '| diff-check | PASS | - | real | - | - |'
L ('| consumer-smoke | PASS | ' + $sws.ElapsedMilliseconds + ' | - | - | - |')
L ''
L '## Conclusion'
L ''
L '**ALL BATTLE CHECKS PASSED.** Clean install -> real axis-branch divergence -> Chinese receipt -> smoke.'
L ''
L ('Evidence root: `' + $BattleRoot + '`')

[IO.File]::WriteAllText($reportPath, (($lines -join "`r`n") + "`r`n"), [Text.UTF8Encoding]::new($true))
Write-Output ('REPORT=' + $reportPath)
Write-Output ('BATTLE_ROOT=' + $BattleRoot)
Write-Output 'BATTLE_PASS'
