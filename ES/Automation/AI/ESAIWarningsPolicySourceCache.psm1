Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:PolicySourceCache = @{}

function Get-ESAIWarningsPolicyFileStamp([string]$Path) {
    $item = Get-Item -LiteralPath $Path -ErrorAction Stop
    return $item.FullName.ToLowerInvariant() + '|' + [string]$item.Length + '|' + [string]$item.LastWriteTimeUtc.Ticks
}

function Get-ESAIWarningsPolicySources {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ProjectRoot)

    $root = (Resolve-Path -LiteralPath $ProjectRoot).Path
    $cacheKey = $root.ToLowerInvariant()
    if ($script:PolicySourceCache.ContainsKey($cacheKey)) {
        $cached = $script:PolicySourceCache[$cacheKey]
        try {
            $stamp = @($cached.paths | ForEach-Object { Get-ESAIWarningsPolicyFileStamp $_ }) -join "`n"
            if ($stamp -ceq [string]$cached.stamp) {
                return [pscustomobject][ordered]@{cacheHit=$true;generationId=[string]$cached.generationId;data=$cached.data}
            }
        }
        catch { }
    }

    $contractPath = Join-Path $root 'ES/Automation/Contracts/es-aiwarnings-global-authority-v1.json'
    $catalogPath = (Get-ChildItem -LiteralPath (Join-Path $root 'Assets/Plugins/ES/AIWarnings') -Recurse -File -Filter 'AIWarningsRouteCatalog.json' | Select-Object -First 1).FullName
    foreach ($path in @($contractPath,$catalogPath)) { if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "AIWARNINGS_GLOBAL_AUTHORITY_SOURCE_MISSING:$path" } }
    $contract = Get-Content -LiteralPath $contractPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $metadataIndexPath = Join-Path $root ([string]$contract.metadataRoutingPolicy.generatedIndexPath)
    if (-not (Test-Path -LiteralPath $metadataIndexPath -PathType Leaf)) { throw 'AIWARNINGS_METADATA_INDEX_MISSING' }
    $catalog = Get-Content -LiteralPath $catalogPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $metadataIndex = Get-Content -LiteralPath $metadataIndexPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $paths = @($contractPath,$catalogPath,$metadataIndexPath)
    $data = [pscustomobject][ordered]@{
        contract=$contract; catalog=$catalog; metadataIndex=$metadataIndex
        contractPath=$contractPath; catalogPath=$catalogPath; metadataIndexPath=$metadataIndexPath
        contractHash=(Get-FileHash -LiteralPath $contractPath -Algorithm SHA256).Hash.ToLowerInvariant()
        catalogHash=(Get-FileHash -LiteralPath $catalogPath -Algorithm SHA256).Hash.ToLowerInvariant()
        metadataIndexHash=(Get-FileHash -LiteralPath $metadataIndexPath -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    $entry = [pscustomobject][ordered]@{
        generationId=[Guid]::NewGuid().ToString('N'); paths=$paths
        stamp=(@($paths | ForEach-Object { Get-ESAIWarningsPolicyFileStamp $_ }) -join "`n")
        data=$data
    }
    $script:PolicySourceCache[$cacheKey]=$entry
    return [pscustomobject][ordered]@{cacheHit=$false;generationId=[string]$entry.generationId;data=$data}
}

Export-ModuleMember -Function Get-ESAIWarningsPolicySources 
