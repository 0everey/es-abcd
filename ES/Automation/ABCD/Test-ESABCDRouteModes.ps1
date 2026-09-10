[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ProjectRoot,
    [string]$ReportPath = ''
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$root = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
$resolver = Join-Path $root '.agents/skills/es-skill-governance/scripts/Resolve-ESChineseSkillRoute.ps1'
$modeRegistryPath = Join-Path $root 'ES/Automation/Contracts/es-ai-abc-mode.registry.json'
if (-not (Test-Path -LiteralPath $resolver -PathType Leaf)) { throw "Route resolver missing: $resolver" }
if (-not (Test-Path -LiteralPath $modeRegistryPath -PathType Leaf)) { throw "Mode registry missing: $modeRegistryPath" }

$registry = Get-Content -LiteralPath $modeRegistryPath -Raw -Encoding UTF8 | ConvertFrom-Json
$coreSkill = 'es-ai-abc-core'
$replicationSkill = 'es-agent-mechanism-replication'
$partSkill = 'es-weapon-abc-part'
$cases = @(
    [pscustomobject]@{ id = 'abcd-shorthand'; objective = 'ABCD'; expectedStatus = 'Matched'; expectedSkill = $coreSkill },
    [pscustomobject]@{ id = 'abcd-dynamic'; objective = 'ABCD.Dynamic'; expectedStatus = 'Matched'; expectedSkill = $coreSkill },
    [pscustomobject]@{ id = 'abcc-core'; objective = 'ABCC.Core'; expectedStatus = 'Matched'; expectedSkill = $coreSkill },
    [pscustomobject]@{ id = 'abcp-part'; objective = 'ABCP.Part'; expectedStatus = 'Matched'; expectedSkill = $coreSkill },
    [pscustomobject]@{ id = 'abcd-chinese'; objective = 'ABCD动态协作'; expectedStatus = 'Matched'; expectedSkill = $coreSkill },
    [pscustomobject]@{ id = 'abcc-chinese'; objective = 'ABCC核心'; expectedStatus = 'Matched'; expectedSkill = $coreSkill },
    [pscustomobject]@{ id = 'abcp-domain'; objective = '武器 ABCP部件'; expectedStatus = 'Matched'; expectedSkill = $partSkill },
    [pscustomobject]@{ id = 'mechanism-replication'; objective = '帮我做机制复刻'; expectedStatus = 'Matched'; expectedSkill = $replicationSkill },
    [pscustomobject]@{ id = 'abcd-mechanism-replication'; objective = 'ABCD机制复刻'; expectedStatus = 'Matched'; expectedSkill = $replicationSkill },
    [pscustomobject]@{ id = 'abcd-negated'; objective = '不要使用ABCD'; expectedStatus = 'NoSkillRoute'; expectedSkill = '' }
)

$checks = [Collections.Generic.List[object]]::new()
$issues = [Collections.Generic.List[string]]::new()
foreach ($case in $cases) {
    $result = (& $resolver -ProjectRoot $root -Objective $case.objective | Out-String | ConvertFrom-Json)
    $skills = @($result.matches | ForEach-Object { [string]$_.skillName })
    $passed = [string]$result.status -eq $case.expectedStatus
    if ([string]::IsNullOrWhiteSpace($case.expectedSkill)) {
        $passed = $passed -and $skills.Count -eq 0
    } else {
        $passed = $passed -and $skills.Count -eq 1 -and $skills[0] -ceq $case.expectedSkill
    }
    if (-not $passed) { [void]$issues.Add("$($case.id): expected $($case.expectedStatus)/$($case.expectedSkill), got $($result.status)/$($skills -join ',')") }
    [void]$checks.Add([pscustomobject]@{ id = $case.id; objective = $case.objective; expectedStatus = $case.expectedStatus; expectedSkill = $case.expectedSkill; actualStatus = [string]$result.status; actualSkills = $skills; passed = $passed })
}

$requiredModes = @('ABCD.Dynamic', 'ABCC.Core', 'ABCP.Part')
$registeredModes = @($registry.modes | ForEach-Object { [string]$_.modeId })
foreach ($mode in $requiredModes) {
    $passed = $registeredModes -contains $mode
    if (-not $passed) { [void]$issues.Add("mode-registry-missing:$mode") }
    [void]$checks.Add([pscustomobject]@{ id = "mode-registry:$mode"; objective = $mode; expectedStatus = 'Registered'; expectedSkill = $coreSkill; actualStatus = if ($passed) { 'Registered' } else { 'Missing' }; actualSkills = @(); passed = $passed })
}

$report = [ordered]@{
    schemaVersion = 1
    validator = 'Test-ESABCDRouteModes'
    status = if ($issues.Count -eq 0) { 'passed' } else { 'failed' }
    checkedUtc = [DateTime]::UtcNow.ToString('o')
    canonicalExecutionSkill = $coreSkill
    checkedModeIds = $requiredModes
    checkCount = $checks.Count
    passedCount = @($checks | Where-Object { $_.passed }).Count
    failedCount = $issues.Count
    checks = @($checks)
    issues = @($issues)
    claimsNotProven = @('Unity Runtime behavior', 'external model/provider behavior', 'release acceptance')
}
if (-not [string]::IsNullOrWhiteSpace($ReportPath)) {
    $reportFull = Join-Path $root $ReportPath.Replace('/', '\')
    $parent = Split-Path -Parent $reportFull
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    [IO.File]::WriteAllText($reportFull, ($report | ConvertTo-Json -Depth 10), [Text.UTF8Encoding]::new($false))
}
$report | ConvertTo-Json -Depth 10
if ($issues.Count -gt 0) { exit 1 }
exit 0
