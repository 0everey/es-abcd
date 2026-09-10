# ABCD / ABCC concepts

## Roles

| Role | Name | Meaning |
|------|------|---------|
| **A** | Agent | States goals, emits intent, consumes normalized results |
| **B** | Behavior | Provides negotiable, verifiable capabilities (not BehaviorTree-only) |
| **C** | Collaborator | Human or AI that authorizes goals and final acceptance |

## Modes

| Mode | Independent? | Role |
|------|--------------|------|
| **ABCD.Dynamic** | Yes | Full dynamic orchestration (InnovationRun stages) |
| **ABCC.Core** | Yes | A↔B semantic adapter contracts + six kernel capabilities |
| **ABCP.Part** | No | Domain part that references Core by ID; never copies Core text |

## Six kernel capabilities (parity)

1. `bounded-tool-action`
2. `failure-recovery`
3. `branch-evaluation`
4. `state-transition-guard`
5. `environment-trust-gate`
6. `audit-evidence-chain`

## Generation modes

| Mode | Objective |
|------|-----------|
| `creative-divergence` | Novel mechanism candidates with player delight |
| `engineering` | Deep, reusable technical systems with ownership/lifecycle |
| `stable` | Project-fit, complete, safe, repeatable loops |

## Evidence boundary

| Layer | Means |
|-------|--------|
| Static / contract | Scripts, schemas, smoke receipts |
| Runtime | Unity/PlayMode/Profiler/Player — **only with fresh receipts** |

`runtime-not-run` is missing evidence, not a static failure.
