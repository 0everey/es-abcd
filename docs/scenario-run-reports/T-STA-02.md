# T-STA-02 — Bulk item import

> 仅由本场 live 回执生成；禁止手填 cand-*。

## 元数据

| 字段 | 值 |
|------|-----|
| testId | `T-STA-02` |
| title | Bulk item import |
| mode | `stable` |
| status | **passed** |
| entryPoint | `Invoke-ESABCModeDivergence+Select-ESABCGenerationCandidate` |
| packageRoot | `F:\aaProject\es-abcd` |
| trialRoot | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite` |
| contractPath | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite\ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json` |
| sourceHash | `329a0dc2e8374e15f3270533ed22553da0c83106fcf9709d29c69f5598d659de` |
| receiptJson | `C:\Users\asus\AppData\Local\Temp\grok-goal-3e6ad67d1519\implementer\abcd-scenario-runs\receipts\T-STA-02.json` |
| startedUtc | 2026-09-10T20:15:29.6297374Z |
| finishedUtc | 2026-09-10T20:15:29.7571053Z |

## 需求原文

```text
项目 C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite。用稳定模式。目标：安全导入道具表。要求：校验去重失败隔离部分成功。交付：导入规程。
```

## 选择结果（live）

| 字段 | 值 |
|------|-----|
| directionCount | 5 |
| selectedDirectionId | `cand-92b98548daf46acddb45` |
| selectedAxis | `rollback` |
| selectionStatus | `deterministic-selected` |
| selectionPolicy | `deterministic-ranked-after-visible-tree-search` |
| claimLevel | `design-candidate` |
| divergenceStatus | `stable-candidate` |
| candidateSetHash | `574ea1789eecefb4ac5199b6ebcbc60c675035b8179d2f91d33334f195b7ba04` |
| recommendedDirectionId | `cand-92b98548daf46acddb45` |
| rejectedCandidatesCount | 0 |
| hiddenCandidatesCount | 1 |
| auditDeferred | True |
| qualityStatus | `mode-ready` |
| runtimeStatus | `runtime-not-run` |

## 本场全部方向

| # | directionId | axis |
|---|-------------|------|
| 1 | `cand-961acdf1f052ea27df94` | `contract-completeness` |
| 2 | `cand-8e076879fb40d33a1bd9` | `integration-fit` |
| 3 | `cand-27546e53a3232343e143` | `compatibility` |
| 4 | `cand-bba51b6aa656921498a8` | `regression-fixture` |
| 5 | `cand-92b98548daf46acddb45` **SELECTED** | `rollback` |

## ranked

| rank | directionId | axis | score |
|------|-------------|------|-------|
| 1 | `cand-92b98548daf46acddb45` | `rollback` | 83.65 |
| 2 | `cand-27546e53a3232343e143` | `compatibility` | 81.5 |
| 3 | `cand-8e076879fb40d33a1bd9` | `integration-fit` | 80 |
| 4 | `cand-bba51b6aa656921498a8` | `regression-fixture` | 79.6 |
| 5 | `cand-961acdf1f052ea27df94` | `contract-completeness` | 78.35 |

## 说明

- rejectedCandidatesCount=0（落选在 ranked，不等于否决书）。
- claimLevel=design-candidate；runtime-not-run：非 PlayMode/发版。
