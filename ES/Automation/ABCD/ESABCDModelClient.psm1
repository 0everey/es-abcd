# Live LLM client for ABCD. Fail-closed when no model credentials.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ESABCDModelConfig {
    [CmdletBinding()]
    param()
    $base = [string]$env:ES_ABCD_MODEL_BASE_URL
    $key = [string]$env:ES_ABCD_MODEL_API_KEY
    if ([string]::IsNullOrWhiteSpace($key)) { $key = [string]$env:XAI_API_KEY }
    if ([string]::IsNullOrWhiteSpace($key)) { $key = [string]$env:OPENAI_API_KEY }
    $model = [string]$env:ES_ABCD_MODEL_NAME
    $backend = [string]$env:ES_ABCD_MODEL_BACKEND
    if ([string]::IsNullOrWhiteSpace($backend)) { $backend = 'chat' }

    # Optional local grok config (never log key)
    $cfg = Join-Path $env:USERPROFILE '.grok\config.toml'
    if (([string]::IsNullOrWhiteSpace($key) -or [string]::IsNullOrWhiteSpace($base)) -and (Test-Path -LiteralPath $cfg)) {
        $raw = Get-Content -LiteralPath $cfg -Raw -Encoding UTF8
        if ([string]::IsNullOrWhiteSpace($base) -and $raw -match 'base_url\s*=\s*"([^"]+)"') { $base = $Matches[1].Trim() }
        if ([string]::IsNullOrWhiteSpace($key) -and $raw -match 'api_key\s*=\s*"([^"]+)"') { $key = $Matches[1].Trim() }
        if ([string]::IsNullOrWhiteSpace($model)) {
            if ($raw -match '\[models\][\s\S]*?default\s*=\s*"([^"]+)"') { $model = $Matches[1].Trim() }
        }
    }
    if ([string]::IsNullOrWhiteSpace($base)) { $base = 'https://api.x.ai' }
    if ([string]::IsNullOrWhiteSpace($model)) { $model = 'grok-4.5' }
    if ([string]::IsNullOrWhiteSpace($key)) {
        throw 'ABCD_MODEL_REQUIRED: set ES_ABCD_MODEL_API_KEY (or XAI_API_KEY/OPENAI_API_KEY) or configure ~/.grok/config.toml api_key. Card-pack fallback is removed (P0).'
    }
    return [pscustomobject]@{
        baseUrl = $base.TrimEnd('/')
        apiKey  = $key
        model   = $model
        backend = $backend
        source  = if ($env:ES_ABCD_MODEL_API_KEY) { 'env:ES_ABCD_MODEL_API_KEY' } elseif ($env:XAI_API_KEY) { 'env:XAI_API_KEY' } elseif ($env:OPENAI_API_KEY) { 'env:OPENAI_API_KEY' } else { 'file:grok-config' }
    }
}

function Invoke-ESABCDChatCompletion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SystemPrompt,
        [Parameter(Mandatory)][string]$UserPrompt,
        [double]$Temperature = 0.7,
        [int]$MaxTokens = 2500,
        [object]$Config = $null
    )
    if ($null -eq $Config) { $Config = Get-ESABCDModelConfig }
    $uri = $Config.baseUrl + '/v1/chat/completions'
    $payload = [ordered]@{
        model       = [string]$Config.model
        temperature = $Temperature
        max_tokens  = $MaxTokens
        messages    = @(
            [ordered]@{ role = 'system'; content = $SystemPrompt }
            [ordered]@{ role = 'user'; content = $UserPrompt }
        )
    }
    $json = ($payload | ConvertTo-Json -Depth 8 -Compress)
    $headers = @{
        Authorization  = 'Bearer ' + [string]$Config.apiKey
        'Content-Type' = 'application/json'
    }
    try {
        $resp = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body ([Text.Encoding]::UTF8.GetBytes($json)) -TimeoutSec 180
    }
    catch {
        $detail = $_.Exception.Message
        if ($_.ErrorDetails -and $_.ErrorDetails.Message) { $detail = $_.ErrorDetails.Message }
        throw ("ABCD_MODEL_HTTP_FAILED:" + $detail)
    }
    $text = $null
    if ($null -ne $resp.choices -and @($resp.choices).Count -gt 0) {
        $c0 = @($resp.choices)[0]
        if ($null -ne $c0.message -and $null -ne $c0.message.content) { $text = [string]$c0.message.content }
        elseif ($null -ne $c0.text) { $text = [string]$c0.text }
    }
    if ([string]::IsNullOrWhiteSpace($text)) {
        throw 'ABCD_MODEL_EMPTY_CONTENT'
    }
    return [pscustomobject]@{
        content   = $text.Trim()
        model     = [string]$Config.model
        baseUrl   = [string]$Config.baseUrl
        rawUsage  = $(if ($null -ne $resp.usage) { $resp.usage } else { $null })
        requestId = $(if ($null -ne $resp.id) { [string]$resp.id } else { $null })
    }
}

function ConvertFrom-ESABCDModelJson {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Text)
    $t = $Text.Trim()
    if ($t -match '(?s)```(?:json)?\s*(.*?)```') { $t = $Matches[1].Trim() }
    $start = $t.IndexOf('{')
    $end = $t.LastIndexOf('}')
    if ($start -lt 0 -or $end -le $start) { throw 'ABCD_MODEL_JSON_NOT_FOUND' }
    $t = $t.Substring($start, $end - $start + 1)
    try {
        return ($t | ConvertFrom-Json)
    }
    catch {
        throw ("ABCD_MODEL_JSON_PARSE_FAILED:" + $_.Exception.Message)
    }
}

Export-ModuleMember -Function @(
    'Get-ESABCDModelConfig',
    'Invoke-ESABCDChatCompletion',
    'ConvertFrom-ESABCDModelJson'
)
