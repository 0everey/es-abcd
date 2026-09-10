# Integration guide

## Layout contract

After install, the consumer project root must contain:

```text
<project>/
  ES/Automation/ABCD/           # modules + scripts
  ES/Automation/Contracts/      # es-ai-abc-*.json (+ support contracts)
  ES/Automation/TaskContextRuntime/
  ES/Automation/AI/             # minimal authority / projection helpers
  ES/Automation/Workers/PowerShell/   # optional workers
  .agents/skills/es-ai-abc-core/
  .agents/skills/es-agent-mechanism-replication/
```

Paths are relative to the **project root**, matching ESFramework conventions so existing scripts resolve `ES/Automation/Contracts/...` without path rewrites.

## Install

```powershell
# From the es-abcd clone:
pwsh -File .\scripts\Install-ESABCD.ps1 -TargetRoot 'C:\path\to\YourProject'
# If hashes differ and you intend to upgrade:
pwsh -File .\scripts\Install-ESABCD.ps1 -TargetRoot 'C:\path\to\YourProject' -Force
```

## Smoke

```powershell
pwsh -File .\scripts\Invoke-ESABCDSmoke.ps1 -ProjectRoot 'C:\path\to\YourProject' -Mode engineering
```

Expect `status=passed` and a receipt under `ES/Automation/ABCD/out/`.

## Minimal API usage

```powershell
$root = 'C:\path\to\YourProject'
Import-Module "$root\ES\Automation\ABCD\ESABCDDivergence.psm1" -Force
Import-Module "$root\ES\Automation\ABCD\ESABCInnovationRun.psm1" -Force

$hash = (Get-FileHash "$root\ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json" -Algorithm SHA256).Hash.ToLowerInvariant()
$div = Invoke-ESABCModeDivergence -Requirement 'Design a freeze for three architecture layers' -SourceHash $hash -Mode engineering -ProjectRoot $root
$sel = Select-ESABCGenerationCandidate -Candidates $div.directions -Mode engineering
$sel.selectedDirectionId
```

## Agent / Skill hosts

Point your agent skill loader at:

- `.agents/skills/es-ai-abc-core/SKILL.md`

Do **not** treat Skill disclosure as authorization to write, run Unity, or publish.

## Adding a domain Part (ABCP)

1. Keep Core untouched.
2. Author a Part JSON against `es-ai-abc-part-v1.schema.json`.
3. Reference Core capability IDs; never copy Core text into the Part.
4. Register Part only in the consumer project.

## Upgrading

1. Pull newer `es-abcd`.
2. Re-run `Install-ESABCD.ps1 -Force`.
3. Re-run smoke.
4. Diff contract hashes before claiming compatibility.

## What not to do

- Do not put API keys in this package or the overlay.
- Do not claim PlayMode success from smoke receipts.
- Do not invent a second InnovationRun state machine in the consumer.
