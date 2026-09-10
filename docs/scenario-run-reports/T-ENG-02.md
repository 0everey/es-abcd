# T-ENG-02 — Growth and economy

> 仅由本场 live 回执生成；禁止手填 cand-*。

## 元数据

| 字段 | 值 |
|------|-----|
| testId | `T-ENG-02` |
| title | Growth and economy |
| mode | `engineering` |
| status | **passed** |
| entryPoint | `Invoke-ESABCModeDivergence+Select-ESABCGenerationCandidate` |
| packageRoot | `F:\aaProject\es-abcd` |
| trialRoot | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite` |
| contractPath | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite\ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json` |
| sourceHash | `329a0dc2e8374e15f3270533ed22553da0c83106fcf9709d29c69f5598d659de` |
| receiptJson | `C:\Users\asus\AppData\Local\Temp\grok-goal-3e6ad67d1519\implementer\abcd-scenario-runs\receipts\T-ENG-02.json` |
| startedUtc | 2026-09-10T20:15:28.1300076Z |
| finishedUtc | 2026-09-10T20:15:28.2763132Z |

## 需求原文

```text
项目 C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite。用工程模式。目标：设计角色成长与货币经济（经验、金币、商店、掉落）。要求：所有权、防刷、存档边界、任务奖励统一。交付：结构 + 失败案例 + 未验证项。
```

## 选择结果（live）

| 字段 | 值 |
|------|-----|
| directionCount | 5 |
| selectedDirectionId | `cand-cdd33ebac2799bc8f03c` |
| selectedAxis | `state-machine-integrity` |
| selectionStatus | `deterministic-selected` |
| selectionPolicy | `deterministic-ranked-after-visible-tree-search` |
| claimLevel | `design-candidate` |
| divergenceStatus | `engineering-candidate` |
| candidateSetHash | `6d543bf5b342a2793779f52695df6c1a3c2d6bda33131f6a1fc6d4bebe8d0b86` |
| recommendedDirectionId | `cand-cdd33ebac2799bc8f03c` |
| rejectedCandidatesCount | 0 |
| hiddenCandidatesCount | 1 |
| auditDeferred | True |
| qualityStatus | `mode-ready` |
| runtimeStatus | `runtime-not-run` |

## 本场全部方向

| # | directionId | axis |
|---|-------------|------|
| 1 | `cand-cdd33ebac2799bc8f03c` **SELECTED** | `state-machine-integrity` |
| 2 | `cand-5621f335553137a10166` | `ownership-lifecycle` |
| 3 | `cand-ede4f7b38f3172d6b87c` | `determinism` |
| 4 | `cand-1af05899a6dae11426ae` | `performance-peak-budget` |
| 5 | `cand-0077dd993841de3c3dc9` | `failure-recovery` |

## ranked

| rank | directionId | axis | score |
|------|-------------|------|-------|
| 1 | `cand-cdd33ebac2799bc8f03c` | `state-machine-integrity` | 88.65 |
| 2 | `cand-5621f335553137a10166` | `ownership-lifecycle` | 87.7 |
| 3 | `cand-1af05899a6dae11426ae` | `performance-peak-budget` | 86.8 |
| 4 | `cand-0077dd993841de3c3dc9` | `failure-recovery` | 86.5 |
| 5 | `cand-ede4f7b38f3172d6b87c` | `determinism` | 81.6 |

## 说明

- rejectedCandidatesCount=0（落选在 ranked，不等于否决书）。
- claimLevel=design-candidate；runtime-not-run：非 PlayMode/发版。
