Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:MetadataIndexCache = @{}

function Get-ESAIWarningsMetadataField {
    param([string]$Text, [Parameter(Mandatory)][string]$Name)
    $match = [regex]::Match($Text,
        '(?im)^\s*>?\s*`?' + [regex]::Escape($Name) + '`?\s*[:\uFF1A]\s*(.+)$')
    if (-not $match.Success) { return '' }
    return $match.Groups[1].Value.Trim().Trim('`').TrimEnd([char]0x3002)
}

function Get-ESAIWarningsMetadataTextHash {
    param([string]$Text)
    if ($null -eq $Text) { $Text = '' }
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash(
            [Text.Encoding]::UTF8.GetBytes($Text))).Replace('-', '').ToLowerInvariant())
    }
    finally { $sha.Dispose() }
}

function Add-ESAIWarningsSearchTerm {
    param(
        [Collections.Generic.Dictionary[string,int]]$Terms,
        [string]$Value,
        [int]$Weight
    )
    if ([string]::IsNullOrWhiteSpace($Value)) { return }
    $normalized = $Value.Trim().Trim('`').ToLowerInvariant()
    $stopTerms = @(
        'aiwarnings','aiwarning','warning','warnings','current','framework',
        'esframework','project','skill','skills','p0','p1','p2','p3','ai',
        'runtime','editor','key','core','run','command','contract','system','data','manager',
        'validation','verification'
    )
    $stopTerms += @(
        (-join @([char]0x8fb9,[char]0x754c)),
        (-join @([char]0x4fee,[char]0x6539)),
        (-join @([char]0x751f,[char]0x547d,[char]0x5468,[char]0x671f)),
        (-join @([char]0x7cfb,[char]0x7edf)),
        (-join @([char]0x9879,[char]0x76ee)),
        (-join @([char]0x89c4,[char]0x5219)),
        (-join @([char]0x8fd0,[char]0x884c,[char]0x65f6)),
        (-join @([char]0x914d,[char]0x7f6e))
    )
    if ($normalized.Length -lt 2 -or $stopTerms -contains $normalized) { return }
    if (-not $Terms.ContainsKey($normalized) -or $Terms[$normalized] -lt $Weight) {
        $Terms[$normalized] = $Weight
    }
}

function Get-ESAIWarningsMetadataIndex {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ProjectRoot)

    $root = (Resolve-Path -LiteralPath $ProjectRoot).Path
    $warningsRoot = Join-Path $root 'Assets/Plugins/ES/AIWarnings'
    if (-not (Test-Path -LiteralPath $warningsRoot -PathType Container)) {
        throw 'AIWARNINGS_METADATA_ROOT_MISSING'
    }

    $files = @(Get-ChildItem -LiteralPath $warningsRoot -Recurse -File -Filter '*.md' | Sort-Object FullName)
    $fingerprintText = @($files | ForEach-Object {
        $_.FullName.Substring($root.Length).Replace('\','/') + '|' + [string]$_.Length + '|' + [string]$_.LastWriteTimeUtc.Ticks
    }) -join "`n"
    $fingerprint = Get-ESAIWarningsMetadataTextHash $fingerprintText
    $cacheKey = $root.ToLowerInvariant()
    if ($script:MetadataIndexCache.ContainsKey($cacheKey) -and [string]$script:MetadataIndexCache[$cacheKey].fingerprint -ceq $fingerprint) {
        return @($script:MetadataIndexCache[$cacheKey].entries)
    }

    $routeSeparatorPattern = '[,' + [char]0xff0c + [char]0x3001 + ']'
    $entries = [Collections.Generic.List[object]]::new()
    foreach ($file in $files) {
        # Metadata-only bounded read. Rule bodies remain unread until a route matches.
        $head = (Get-Content -LiteralPath $file.FullName -Encoding UTF8 -TotalCount 18) -join "`n"
        $status = Get-ESAIWarningsMetadataField -Text $head -Name 'Status'
        $stableId = Get-ESAIWarningsMetadataField -Text $head -Name 'StableId'
        $routeKeys = Get-ESAIWarningsMetadataField -Text $head -Name 'RouteKeys'
        if ($status -cne 'current' -or [string]::IsNullOrWhiteSpace($stableId) -or
            [string]::IsNullOrWhiteSpace($routeKeys)) { continue }

        $titleMatch = [regex]::Match($head, '(?m)^#\s+(.+)$')
        $title = if ($titleMatch.Success) { $titleMatch.Groups[1].Value.Trim() } else { '' }
        $applicability = Get-ESAIWarningsMetadataField -Text $head -Name 'Applicability'
        $relative = $file.FullName.Substring($root.Length).TrimStart('\','/').Replace('\','/')
        $terms = [Collections.Generic.Dictionary[string,int]]::new([StringComparer]::OrdinalIgnoreCase)

        foreach ($term in @($routeKeys -split $routeSeparatorPattern)) {
            Add-ESAIWarningsSearchTerm -Terms $terms -Value $term -Weight 12
        }
        foreach ($source in @($title,
            [IO.Path]::GetFileNameWithoutExtension($file.Name), $relative)) {
            foreach ($match in [regex]::Matches($source,
                '[A-Za-z][A-Za-z0-9_+*.-]{2,}|[\p{IsCJKUnifiedIdeographs}]{2,12}')) {
                Add-ESAIWarningsSearchTerm -Terms $terms -Value $match.Value -Weight 4
            }
        }
        foreach ($match in [regex]::Matches($applicability,
            '[A-Za-z][A-Za-z0-9_+*.-]{2,}')) {
            Add-ESAIWarningsSearchTerm -Terms $terms -Value $match.Value -Weight 3
        }
        foreach ($term in @($stableId -split '[.\-]')) {
            Add-ESAIWarningsSearchTerm -Terms $terms -Value $term -Weight 2
        }

        $severity = if ($relative -match '(?i)(^|/)10_P0|(^|[.\-])p0([.\-]|$)') { 'P0' }
            elseif ($relative -match '(?i)(^|[.\-_/])p1([.\-_/]|$)') { 'P1' }
            elseif ($relative -match '(?i)(^|[.\-_/])p3([.\-_/]|$)') { 'P3' }
            else { 'P2' }
        [void]$entries.Add([pscustomobject][ordered]@{
            ruleId = $stableId
            severity = $severity
            decision = if ($severity -eq 'P0') { 'claim-cap' } else { 'consume-and-report' }
            title = $title
            sourcePath = $relative
            metadataHeaderHash = Get-ESAIWarningsMetadataTextHash $head
            routeKeys = @($routeKeys -split $routeSeparatorPattern | ForEach-Object {
                    $_.Trim().Trim('`').TrimEnd([char]0x3002)
                } |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
            searchTerms = @($terms.GetEnumerator() | Sort-Object Key | ForEach-Object {
                [pscustomobject]@{ value = $_.Key; weight = $_.Value }
            })
        })
    }
    $result = @($entries | Sort-Object ruleId)
    $script:MetadataIndexCache[$cacheKey] = [pscustomobject][ordered]@{ fingerprint=$fingerprint; entries=$result }
    return $result
}

function Find-ESAIWarningsMetadataRoutes {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$PromptText,
        [Parameter(Mandatory)][object[]]$Index
    )
    $text = $PromptText.ToLowerInvariant()
    $matches = [Collections.Generic.List[object]]::new()
    foreach ($entry in @($Index)) {
        $hitTerms = [Collections.Generic.List[string]]::new()
        $score = 0
        foreach ($term in @($entry.searchTerms)) {
            $value = [string]$term.value
            if ($value.Length -gt 0 -and (Test-ESAIWarningsTextTerm -Text $text -Term $value)) {
                [void]$hitTerms.Add($value)
                $score += [int]$term.weight
            }
        }
        if ($score -lt 8) { continue }
        [void]$matches.Add([pscustomobject][ordered]@{
            ruleId = [string]$entry.ruleId
            severity = [string]$entry.severity
            decision = [string]$entry.decision
            relevanceScore = $score
            matchedTerms = @($hitTerms | Select-Object -Unique)
            mustRead = @([string]$entry.sourcePath)
            source = 'warning-metadata-index'
        })
    }
    return @($matches | Sort-Object @{ Expression = 'relevanceScore'; Descending = $true }, ruleId)
}

function Test-ESAIWarningsTextTerm {
    param([string]$Text, [string]$Term)
    if ([string]::IsNullOrWhiteSpace($Term)) { return $false }
    if ($Term -match '^[A-Za-z0-9_+*.-]+$') {
        $pattern = '(?i)(?<![A-Za-z0-9])' + [regex]::Escape($Term) + '(?![A-Za-z0-9])'
        return [regex]::IsMatch($Text, $pattern)
    }
    return $Text.IndexOf($Term, [StringComparison]::OrdinalIgnoreCase) -ge 0
}

Export-ModuleMember -Function Get-ESAIWarningsMetadataIndex, Find-ESAIWarningsMetadataRoutes, Test-ESAIWarningsTextTerm
