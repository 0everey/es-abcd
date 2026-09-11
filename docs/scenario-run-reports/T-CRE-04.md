# T-CRE-04 — Boss fight variants

> 仅由本场 live 回执生成；禁止手填 cand-*。

## 元数据

| 字段 | 值 |
|------|-----|
| testId | `T-CRE-04` |
| title | Boss fight variants |
| mode | `creative-divergence` |
| status | **passed** |
| entryPoint | `Invoke-ESABCModeDivergence+Select-ESABCGenerationCandidate` |
| packageRoot | `F:\aaProject\es-abcd` |
| trialRoot | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite` |
| contractPath | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite\ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json` |
| sourceHash | `329a0dc2e8374e15f3270533ed22553da0c83106fcf9709d29c69f5598d659de` |
| receiptJson | `C:\Users\asus\AppData\Local\Temp\grok-goal-fcc12249cbbc\implementer\abcd-scenario-runs\receipts\T-CRE-04.json` |
| startedUtc | 2026-09-11T02:35:02.4380601Z |
| finishedUtc | 2026-09-11T02:35:02.6721955Z |

## 需求原文

```text
项目 C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite。用创意模式。目标：同一Boss五种战法。要求：机制/叙事/解谜/配队/Roguelike。交付：5战法卡。
```

## 选择结果（live）

| 字段 | 值 |
|------|-----|
| directionCount | 7 |
| selectedDirectionId | `cand-e1f33204812d14140800` |
| selectedAxis | `flow-continuity` |
| selectionStatus | `ranked-recommended` |
| selectionPolicy | `rank-after-visible-tree-search` |
| claimLevel | `design-candidate` |
| divergenceStatus | `creative-candidate` |
| candidateSetHash | `15c81a57675ac33a3c2a5448b5028ef313f2361da5046ce411f6e9da32a562b4` |
| recommendedDirectionId | `cand-e1f33204812d14140800` |
| rejectedCandidatesCount | 0 |
| hiddenCandidatesCount | 1 |
| auditDeferred | True |
| qualityStatus | `mode-ready` |
| runtimeStatus | `runtime-not-run` |

## 本场全部方向

| # | directionId | axis |
|---|-------------|------|
| 1 | `cand-bb1e4b25e5e615c53963` | `moment-to-moment-feel` |
| 2 | `cand-e1f33204812d14140800` **SELECTED** | `flow-continuity` |
| 3 | `cand-2eab52203d19cccd3d49` | `presentation-beat` |
| 4 | `cand-090f9d2fedddf3b66b4c` | `expressive-input` |
| 5 | `cand-36953147c6e4bf2755bb` | `skill-ceiling` |
| 6 | `cand-6b1eb70e4fc603646909` | `novelty-delta` |
| 7 | `cand-3be95969b1860c7ea6de` | `counterplay-clarity` |

## ranked

| rank | directionId | axis | score |
|------|-------------|------|-------|
| 1 | `cand-e1f33204812d14140800` | `flow-continuity` | 92.3 |
| 2 | `cand-6b1eb70e4fc603646909` | `novelty-delta` | 91.95 |
| 3 | `cand-2eab52203d19cccd3d49` | `presentation-beat` | 88 |
| 4 | `cand-3be95969b1860c7ea6de` | `counterplay-clarity` | 86.65 |
| 5 | `cand-bb1e4b25e5e615c53963` | `moment-to-moment-feel` | 84.95 |
| 6 | `cand-36953147c6e4bf2755bb` | `skill-ceiling` | 83.15 |
| 7 | `cand-090f9d2fedddf3b66b4c` | `expressive-input` | 82.85 |

## 说明

- rejectedCandidatesCount=0（落选在 ranked，不等于否决书）。
- claimLevel=design-candidate；runtime-not-run：非 PlayMode/发版。
