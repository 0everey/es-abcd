[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
$module=Join-Path $PSScriptRoot 'ESABCInnovationRun.psm1'
Import-Module $module -Force
$hash=([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes('fixture'))|ForEach-Object ToString x2)-join ''
$start=[DateTime]::UtcNow.AddSeconds(-2).ToString('o');$end=[DateTime]::UtcNow.ToString('o')
$provider=[pscustomobject]@{status='passed';executionId='provider-1';executionKind='provider-api';outputHash=$hash;startedUtc=$start;endedUtc=$end;providerId='fixture-provider';requestHash=$hash;responseHash=$hash;transportStatus='passed'}
$script=[pscustomobject]@{status='passed';executionId='script-1';executionKind='script';outputHash=$hash;startedUtc=$start;endedUtc=$end;command='PowerShell scriptblock';exitCode=0}
$badProvider=[pscustomobject]@{status='passed';executionId='provider-2';executionKind='provider-api';outputHash=$hash;startedUtc=$start;endedUtc=$end;providerId='fixture-provider';requestHash=$hash;responseHash=$hash}
if(-not (Test-ESABCRealExecutionReceipt $provider).valid){throw 'provider receipt rejected'}
if(-not (Test-ESABCRealExecutionReceipt $script).valid){throw 'script receipt rejected'}
if((Test-ESABCRealExecutionReceipt $badProvider).valid){throw 'missing transport status accepted'}
[pscustomobject]@{status='passed';provider='passed';script='passed';invalidProvider='rejected'} | ConvertTo-Json -Compress
