# ES ABCD Portable Core

**Project-neutral engineering orchestration for agents and collaborators.**

ABCD/ABCC turns goals into **bounded, evidence-gated decisions**: divergence → scoring → gates → receipts.  
It is **not** a game engine, **not** a Unity plugin, and **not** an automatic code writer.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B%20%7C%207%2B-blue.svg)](#requirements)

---

## Why this exists

Teams repeatedly need the same engineering loop:

1. State a goal and hard constraints  
2. Generate multiple mechanism axes (not one silent answer)  
3. Rank with explicit scores and counter-arguments  
4. Refuse fake completion when evidence is missing  
5. Keep domain gameplay/Unity out of the core  

This repository packages that loop so **any conforming project** can overlay it and call the same APIs.

---

## What you get

| Area | Contents |
|------|----------|
| **ABCD modules** | InnovationRun, divergence, scoring, authority kernel, orchestrator, gates, patch planning helpers |
| **Contracts** | `es-ai-abc-*.json` schemas + scoring/generation/mode registries |
| **TaskContextRuntime** | Task binding / context runtime used by ABC bindings |
| **Minimal AI helpers** | Authority decision policy + warning projection helpers (no project corpus required for smoke) |
| **Skills** | `es-ai-abc-core` (+ mechanism-replication as provenance) |
| **Scripts** | Install overlay, layout check, smoke test |

**Business-free:** no scenes, prefabs, weapons, credentials, or project AIWarnings corpus.

---

## Requirements

- Windows or any OS with **PowerShell 5.1+** (PowerShell 7+ recommended: `pwsh`)
- Git (to clone)
- Optional: an agent host that can load `.agents/skills/*/SKILL.md`

No Unity Editor is required for install or smoke.

---

## 60-second quick start

```powershell
# 1) Clone
git clone https://github.com/<YOUR_USER>/es-abcd.git
cd es-abcd

# 2) Verify package layout
pwsh -File .\scripts\Test-ESABCDPackageLayout.ps1

# 3) Install into your project (creates/ overlays ES/Automation/...)
pwsh -File .\scripts\Install-ESABCD.ps1 -TargetRoot 'C:\path\to\YourProject'

# 4) Smoke (static only)
pwsh -File .\scripts\Invoke-ESABCDSmoke.ps1 -ProjectRoot 'C:\path\to\YourProject' -Mode engineering
```

On success you get:

- `status=passed`
- receipt file under `YourProject/ES/Automation/ABCD/out/smoke-*.json`
- `runtimeStatus=runtime-not-run` (expected)

---

## Concepts (30 seconds)

| Symbol | Meaning |
|--------|---------|
| **A** Agent | Emits intent, consumes normalized results |
| **B** Behavior | Capabilities with schemas, preconditions, evidence |
| **C** Collaborator | You (human/AI) authorize goals and final acceptance |
| **ABCD.Dynamic** | Full orchestration mode |
| **ABCC.Core** | Stable A↔B adapter + six kernel capabilities |
| **ABCP.Part** | Optional domain part in *your* repo (not shipped as game content here) |

Six capabilities every conforming core must expose:

`bounded-tool-action` · `failure-recovery` · `branch-evaluation` · `state-transition-guard` · `environment-trust-gate` · `audit-evidence-chain`

More detail: [docs/concepts.md](docs/concepts.md)

---

## Integrate into any project

### Layout contract

Install overlays files under the **target project root**:

```text
YourProject/
  ES/Automation/ABCD/
  ES/Automation/Contracts/          # es-ai-abc-* (+ support contracts)
  ES/Automation/TaskContextRuntime/
  ES/Automation/AI/                 # minimal helpers
  ES/Automation/Workers/PowerShell/ # optional
  .agents/skills/es-ai-abc-core/
```

Your app can be Unity, Node, .NET, pure docs — as long as you keep this relative layout (or adjust path resolution yourself).

### Install / upgrade

```powershell
pwsh -File .\scripts\Install-ESABCD.ps1 -TargetRoot 'D:\work\MyApp'
pwsh -File .\scripts\Install-ESABCD.ps1 -TargetRoot 'D:\work\MyApp' -Force   # upgrade
```

### Call from scripts

```powershell
$root = 'D:\work\MyApp'
Import-Module "$root\ES\Automation\ABCD\ESABCDDivergence.psm1" -Force
Import-Module "$root\ES\Automation\ABCD\ESABCInnovationRun.psm1" -Force

$contract = "$root\ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json"
$hash = (Get-FileHash $contract -Algorithm SHA256).Hash.ToLowerInvariant()

$div = Invoke-ESABCModeDivergence `
  -Requirement 'Freeze a three-layer architecture with clear ownership' `
  -SourceHash $hash `
  -Mode engineering `
  -ProjectRoot $root

$sel = Select-ESABCGenerationCandidate -Candidates $div.directions -Mode engineering
Write-Host "selected:" $sel.selectedDirectionId "status:" $sel.selectionStatus
```

Full guide: [docs/integration.md](docs/integration.md)

---

## Generation modes

| Mode | Use when |
|------|----------|
| `engineering` | Architecture freeze, ownership, lifecycle, reuse |
| `creative-divergence` | Novel mechanism candidates (player-delight weighted) |
| `stable` | Fit, completeness, safety, closure |

---

## Evidence rules (read this)

| Claim | Required evidence |
|-------|-------------------|
| Package layout OK | `Test-ESABCDPackageLayout.ps1` |
| Core callable | `Invoke-ESABCDSmoke.ps1` receipt |
| Formal architecture competition `completed` | Provider receipts + implementation evidence (see ABCD modules) |
| Unity / PlayMode / Release | **Separate** fresh receipts — never inferred from smoke |

If runtime was not executed, receipts must keep `runtimeStatus: runtime-not-run`.

---

## Repository map

```text
es-abcd/
  README.md
  LICENSE
  package/es-abcd-portable.manifest.json
  scripts/
    Install-ESABCD.ps1
    Invoke-ESABCDSmoke.ps1
    Test-ESABCDPackageLayout.ps1
  docs/
    concepts.md
    integration.md
  ES/Automation/
    ABCD/                 # core modules
    Contracts/            # JSON contracts
    TaskContextRuntime/
    AI/                   # minimal support
    Workers/PowerShell/
  .agents/skills/
    es-ai-abc-core/
    es-agent-mechanism-replication/
  examples/
    minimal-engineering.ps1
```

---

## Agent host wiring

1. Clone or submodule this repo (or install overlay into your monorepo).  
2. Register skill path: `.agents/skills/es-ai-abc-core/SKILL.md`  
3. Instruct agents: Skill disclosure ≠ write/Unity/network permission.  
4. Prefer `engineering` mode for architecture freezes; require smoke receipt before claiming “ABCD ran”.

---

## Non-goals

- Shipping game content, weapons, scenes, or AIWarnings corpora  
- Replacing your CI with silent “all green” without receipts  
- Bundling model API keys or provider credentials  
- Guaranteeing a full InnovationRun `final-decision` without configured providers  

---

## Provenance

Extracted as a **business-free portable slice** of the ESFramework automation core (`es-abcd-generic-portable` lineage), trimmed for public use (domain weapon parts and project-private AI traffic removed).

---

## License

MIT — see [LICENSE](LICENSE).

---

## Contributing

1. Keep `businessFree: true` — no gameplay assets.  
2. Contract changes are semver-major if they break consumers.  
3. Run layout + smoke before PR.  
4. Do not commit secrets or machine-local absolute paths in docs/examples.
