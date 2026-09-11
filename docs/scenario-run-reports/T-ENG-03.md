# T-ENG-03 — Bulk item pipeline

> 仅由本场 live 回执生成；禁止手填 cand-*。

## 元数据

| 字段 | 值 |
|------|-----|
| testId | `T-ENG-03` |
| title | Bulk item pipeline |
| mode | `engineering` |
| status | **passed** |
| entryPoint | `Invoke-ESABCModeDivergence+Select-ESABCGenerationCandidate` |
| packageRoot | `F:\aaProject\es-abcd` |
| trialRoot | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite` |
| contractPath | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite\ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json` |
| sourceHash | `329a0dc2e8374e15f3270533ed22553da0c83106fcf9709d29c69f5598d659de` |
| receiptJson | `C:\Users\asus\AppData\Local\Temp\grok-goal-fcc12249cbbc\implementer\abcd-scenario-runs\receipts\T-ENG-03.json` |
| startedUtc | 2026-09-11T02:35:01.1657603Z |
| finishedUtc | 2026-09-11T02:35:01.3705671Z |

## 需求原文

```text
项目 C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite。用工程模式。目标：建立大量道具制作与入库管线（模板、命名、表字段、校验、批量生成）。要求：一条正式入口、禁止旁路、坏数据拒绝。交付：管线步骤 + 验收标准。
```

## 选择结果（live）

| 字段 | 值 |
|------|-----|
| directionCount | 5 |
| selectedDirectionId | `cand-be1cfc2e0345a72f7614` |
| selectedAxis | `performance-peak-budget` |
| selectionStatus | `deterministic-selected` |
| selectionPolicy | `deterministic-ranked-after-visible-tree-search` |
| claimLevel | `design-candidate` |
| divergenceStatus | `engineering-candidate` |
| candidateSetHash | `18ada1e9ef5aacc5439bc38728eb66779c47181c361ee52c82e0e9d14665faee` |
| recommendedDirectionId | `cand-be1cfc2e0345a72f7614` |
| rejectedCandidatesCount | 0 |
| hiddenCandidatesCount | 1 |
| auditDeferred | True |
| qualityStatus | `mode-ready` |
| runtimeStatus | `runtime-not-run` |

## 本场全部方向

| # | directionId | axis |
|---|-------------|------|
| 1 | `cand-b9f67984a56196822abb` | `state-machine-integrity` |
| 2 | `cand-bf81289b78df41d13e58` | `ownership-lifecycle` |
| 3 | `cand-08a9f7fbb64a063d13c6` | `determinism` |
| 4 | `cand-be1cfc2e0345a72f7614` **SELECTED** | `performance-peak-budget` |
| 5 | `cand-96b26d364b5b4d25b769` | `failure-recovery` |

## ranked

| rank | directionId | axis | score |
|------|-------------|------|-------|
| 1 | `cand-be1cfc2e0345a72f7614` | `performance-peak-budget` | 90.8 |
| 2 | `cand-bf81289b78df41d13e58` | `ownership-lifecycle` | 88.2 |
| 3 | `cand-08a9f7fbb64a063d13c6` | `determinism` | 87.5 |
| 4 | `cand-96b26d364b5b4d25b769` | `failure-recovery` | 84.95 |
| 5 | `cand-b9f67984a56196822abb` | `state-machine-integrity` | 80.7 |

## 说明

- rejectedCandidatesCount=0（落选在 ranked，不等于否决书）。
- claimLevel=design-candidate；runtime-not-run：非 PlayMode/发版。
