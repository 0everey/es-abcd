# T-STA-01 — Extend skill table

> 仅由本场 live 回执生成；禁止手填 cand-*。

## 元数据

| 字段 | 值 |
|------|-----|
| testId | `T-STA-01` |
| title | Extend skill table |
| mode | `stable` |
| status | **passed** |
| entryPoint | `Invoke-ESABCModeDivergence+Select-ESABCGenerationCandidate` |
| packageRoot | `F:\aaProject\es-abcd` |
| trialRoot | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite` |
| contractPath | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite\ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json` |
| sourceHash | `329a0dc2e8374e15f3270533ed22553da0c83106fcf9709d29c69f5598d659de` |
| receiptJson | `C:\Users\asus\AppData\Local\Temp\grok-goal-fcc12249cbbc\implementer\abcd-scenario-runs\receipts\T-STA-01.json` |
| startedUtc | 2026-09-11T02:35:02.6835293Z |
| finishedUtc | 2026-09-11T02:35:02.8550632Z |

## 需求原文

```text
项目 C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite。用稳定模式。目标：技能表扩展10个新技能不改老语义。要求：存档兼容、命名、默认字段、回滚。交付：步骤+回归表。
```

## 选择结果（live）

| 字段 | 值 |
|------|-----|
| directionCount | 5 |
| selectedDirectionId | `cand-2efc8c2dc69e419bc888` |
| selectedAxis | `rollback` |
| selectionStatus | `deterministic-selected` |
| selectionPolicy | `deterministic-ranked-after-visible-tree-search` |
| claimLevel | `design-candidate` |
| divergenceStatus | `stable-candidate` |
| candidateSetHash | `f2d62c2501090f1df70f5e300f89999d9657ef58d888e2fb13d1a55af46f19ec` |
| recommendedDirectionId | `cand-2efc8c2dc69e419bc888` |
| rejectedCandidatesCount | 0 |
| hiddenCandidatesCount | 1 |
| auditDeferred | True |
| qualityStatus | `mode-ready` |
| runtimeStatus | `runtime-not-run` |

## 本场全部方向

| # | directionId | axis |
|---|-------------|------|
| 1 | `cand-f73a2709925661a2e271` | `contract-completeness` |
| 2 | `cand-35d0a3a222a30ec9ae6f` | `integration-fit` |
| 3 | `cand-8c841aa2bdfa692e0588` | `compatibility` |
| 4 | `cand-297d563a88d7e27ea608` | `regression-fixture` |
| 5 | `cand-2efc8c2dc69e419bc888` **SELECTED** | `rollback` |

## ranked

| rank | directionId | axis | score |
|------|-------------|------|-------|
| 1 | `cand-2efc8c2dc69e419bc888` | `rollback` | 85.65 |
| 2 | `cand-f73a2709925661a2e271` | `contract-completeness` | 83.2 |
| 3 | `cand-8c841aa2bdfa692e0588` | `compatibility` | 82.65 |
| 4 | `cand-35d0a3a222a30ec9ae6f` | `integration-fit` | 80.25 |
| 5 | `cand-297d563a88d7e27ea608` | `regression-fixture` | 79.55 |

## 说明

- rejectedCandidatesCount=0（落选在 ranked，不等于否决书）。
- claimLevel=design-candidate；runtime-not-run：非 PlayMode/发版。
