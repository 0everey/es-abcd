# T-STA-03 — Event config switch

> 仅由本场 live 回执生成；禁止手填 cand-*。

## 元数据

| 字段 | 值 |
|------|-----|
| testId | `T-STA-03` |
| title | Event config switch |
| mode | `stable` |
| status | **passed** |
| entryPoint | `Invoke-ESABCModeDivergence+Select-ESABCGenerationCandidate` |
| packageRoot | `F:\aaProject\es-abcd` |
| trialRoot | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite` |
| contractPath | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite\ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json` |
| sourceHash | `329a0dc2e8374e15f3270533ed22553da0c83106fcf9709d29c69f5598d659de` |
| receiptJson | `C:\Users\asus\AppData\Local\Temp\grok-goal-fcc12249cbbc\implementer\abcd-scenario-runs\receipts\T-STA-03.json` |
| startedUtc | 2026-09-11T02:35:03.0427835Z |
| finishedUtc | 2026-09-11T02:35:03.2059429Z |

## 需求原文

```text
项目 C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite。用稳定模式。目标：活动开关配置下发不影响日常关卡。要求：默认关可回退可追日志。交付：开关方案。
```

## 选择结果（live）

| 字段 | 值 |
|------|-----|
| directionCount | 5 |
| selectedDirectionId | `cand-17070a1c467afb7c4ec4` |
| selectedAxis | `integration-fit` |
| selectionStatus | `deterministic-selected` |
| selectionPolicy | `deterministic-ranked-after-visible-tree-search` |
| claimLevel | `design-candidate` |
| divergenceStatus | `stable-candidate` |
| candidateSetHash | `98baf5c176f312f37b8420dc3a93e6a311455cd901750b201665bd0c4041ac07` |
| recommendedDirectionId | `cand-17070a1c467afb7c4ec4` |
| rejectedCandidatesCount | 0 |
| hiddenCandidatesCount | 1 |
| auditDeferred | True |
| qualityStatus | `mode-ready` |
| runtimeStatus | `runtime-not-run` |

## 本场全部方向

| # | directionId | axis |
|---|-------------|------|
| 1 | `cand-6cb72c2bfc7a6a62f35e` | `contract-completeness` |
| 2 | `cand-17070a1c467afb7c4ec4` **SELECTED** | `integration-fit` |
| 3 | `cand-701f66b2ac7c43ae6d2b` | `compatibility` |
| 4 | `cand-e4a5c7d6ce2e595174d8` | `regression-fixture` |
| 5 | `cand-f556d680cf8d15bd3405` | `rollback` |

## ranked

| rank | directionId | axis | score |
|------|-------------|------|-------|
| 1 | `cand-17070a1c467afb7c4ec4` | `integration-fit` | 90.75 |
| 2 | `cand-e4a5c7d6ce2e595174d8` | `regression-fixture` | 89.65 |
| 3 | `cand-701f66b2ac7c43ae6d2b` | `compatibility` | 85.75 |
| 4 | `cand-6cb72c2bfc7a6a62f35e` | `contract-completeness` | 78.7 |
| 5 | `cand-f556d680cf8d15bd3405` | `rollback` | 77.9 |

## 说明

- rejectedCandidatesCount=0（落选在 ranked，不等于否决书）。
- claimLevel=design-candidate；runtime-not-run：非 PlayMode/发版。
