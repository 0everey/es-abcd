# T-STA-04 — Old level bugfix

> 仅由本场 live 回执生成；禁止手填 cand-*。

## 元数据

| 字段 | 值 |
|------|-----|
| testId | `T-STA-04` |
| title | Old level bugfix |
| mode | `stable` |
| status | **passed** |
| entryPoint | `Invoke-ESABCModeDivergence+Select-ESABCGenerationCandidate` |
| packageRoot | `F:\aaProject\es-abcd` |
| trialRoot | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite` |
| contractPath | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite\ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json` |
| sourceHash | `329a0dc2e8374e15f3270533ed22553da0c83106fcf9709d29c69f5598d659de` |
| receiptJson | `C:\Users\asus\AppData\Local\Temp\grok-goal-fcc12249cbbc\implementer\abcd-scenario-runs\receipts\T-STA-04.json` |
| startedUtc | 2026-09-11T02:35:03.2195384Z |
| finishedUtc | 2026-09-11T02:35:03.3818552Z |

## 需求原文

```text
项目 C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite。用稳定模式。目标：修老关卡卡死不毁档。要求：最小改动兼容中途玩家。交付：修复+风险。
```

## 选择结果（live）

| 字段 | 值 |
|------|-----|
| directionCount | 5 |
| selectedDirectionId | `cand-4bba0192d92567aedf6b` |
| selectedAxis | `compatibility` |
| selectionStatus | `deterministic-selected` |
| selectionPolicy | `deterministic-ranked-after-visible-tree-search` |
| claimLevel | `design-candidate` |
| divergenceStatus | `stable-candidate` |
| candidateSetHash | `f477679d8d86e0ca084b722f5563946402cfcc8457b26c80b85ac9b00897ac4b` |
| recommendedDirectionId | `cand-4bba0192d92567aedf6b` |
| rejectedCandidatesCount | 0 |
| hiddenCandidatesCount | 1 |
| auditDeferred | True |
| qualityStatus | `mode-ready` |
| runtimeStatus | `runtime-not-run` |

## 本场全部方向

| # | directionId | axis |
|---|-------------|------|
| 1 | `cand-317760306dec58e93057` | `contract-completeness` |
| 2 | `cand-f352cfa98fc23c15d829` | `integration-fit` |
| 3 | `cand-4bba0192d92567aedf6b` **SELECTED** | `compatibility` |
| 4 | `cand-b5b868c9f6b037e93815` | `regression-fixture` |
| 5 | `cand-088b8d04528b746e6be7` | `rollback` |

## ranked

| rank | directionId | axis | score |
|------|-------------|------|-------|
| 1 | `cand-4bba0192d92567aedf6b` | `compatibility` | 88.1 |
| 2 | `cand-088b8d04528b746e6be7` | `rollback` | 87.75 |
| 3 | `cand-f352cfa98fc23c15d829` | `integration-fit` | 85.6 |
| 4 | `cand-b5b868c9f6b037e93815` | `regression-fixture` | 78 |
| 5 | `cand-317760306dec58e93057` | `contract-completeness` | 77.95 |

## 说明

- rejectedCandidatesCount=0（落选在 ranked，不等于否决书）。
- claimLevel=design-candidate；runtime-not-run：非 PlayMode/发版。
