# T-CRE-03 — Item category matrix

> 仅由本场 live 回执生成；禁止手填 cand-*。

## 元数据

| 字段 | 值 |
|------|-----|
| testId | `T-CRE-03` |
| title | Item category matrix |
| mode | `creative-divergence` |
| status | **passed** |
| entryPoint | `Invoke-ESABCModeDivergence+Select-ESABCGenerationCandidate` |
| packageRoot | `F:\aaProject\es-abcd` |
| trialRoot | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite` |
| contractPath | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite\ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json` |
| sourceHash | `329a0dc2e8374e15f3270533ed22553da0c83106fcf9709d29c69f5598d659de` |
| receiptJson | `C:\Users\asus\AppData\Local\Temp\grok-goal-3e6ad67d1519\implementer\abcd-scenario-runs\receipts\T-CRE-03.json` |
| startedUtc | 2026-09-10T20:15:29.1449721Z |
| finishedUtc | 2026-09-10T20:15:29.3133580Z |

## 需求原文

```text
项目 C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite。用创意模式。目标：5套道具品类矩阵（不改底层背包）。要求：命名、稀有度、经济钩子。交付：5矩阵+样例建议。
```

## 选择结果（live）

| 字段 | 值 |
|------|-----|
| directionCount | 7 |
| selectedDirectionId | `cand-0848c7565cb237906782` |
| selectedAxis | `flow-continuity` |
| selectionStatus | `ranked-recommended` |
| selectionPolicy | `rank-after-visible-tree-search` |
| claimLevel | `design-candidate` |
| divergenceStatus | `creative-candidate` |
| candidateSetHash | `3e47918c187e34313efddd2e7b242042d60490bf10bb3b1792768a16bf9c4c5b` |
| recommendedDirectionId | `cand-0848c7565cb237906782` |
| rejectedCandidatesCount | 0 |
| hiddenCandidatesCount | 1 |
| auditDeferred | True |
| qualityStatus | `mode-ready` |
| runtimeStatus | `runtime-not-run` |

## 本场全部方向

| # | directionId | axis |
|---|-------------|------|
| 1 | `cand-23f05acd0beb4134fadd` | `moment-to-moment-feel` |
| 2 | `cand-0848c7565cb237906782` **SELECTED** | `flow-continuity` |
| 3 | `cand-b44e22f3056743de13bf` | `presentation-beat` |
| 4 | `cand-d77184c1243bd9e183f0` | `expressive-input` |
| 5 | `cand-d8585ec1c42225e01efc` | `skill-ceiling` |
| 6 | `cand-e3603a452f7605188b52` | `novelty-delta` |
| 7 | `cand-870a15645351573089b4` | `counterplay-clarity` |

## ranked

| rank | directionId | axis | score |
|------|-------------|------|-------|
| 1 | `cand-0848c7565cb237906782` | `flow-continuity` | 95.75 |
| 2 | `cand-870a15645351573089b4` | `counterplay-clarity` | 86.95 |
| 3 | `cand-d77184c1243bd9e183f0` | `expressive-input` | 86.65 |
| 4 | `cand-b44e22f3056743de13bf` | `presentation-beat` | 86.55 |
| 5 | `cand-e3603a452f7605188b52` | `novelty-delta` | 84.85 |
| 6 | `cand-d8585ec1c42225e01efc` | `skill-ceiling` | 83.55 |
| 7 | `cand-23f05acd0beb4134fadd` | `moment-to-moment-feel` | 80.25 |

## 说明

- rejectedCandidatesCount=0（落选在 ranked，不等于否决书）。
- claimLevel=design-candidate；runtime-not-run：非 PlayMode/发版。
