# T-ENG-04 — Combat settle loop

> 仅由本场 live 回执生成；禁止手填 cand-*。

## 元数据

| 字段 | 值 |
|------|-----|
| testId | `T-ENG-04` |
| title | Combat settle loop |
| mode | `engineering` |
| status | **passed** |
| entryPoint | `Invoke-ESABCModeDivergence+Select-ESABCGenerationCandidate` |
| packageRoot | `F:\aaProject\es-abcd` |
| trialRoot | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite` |
| contractPath | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite\ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json` |
| sourceHash | `329a0dc2e8374e15f3270533ed22553da0c83106fcf9709d29c69f5598d659de` |
| receiptJson | `C:\Users\asus\AppData\Local\Temp\grok-goal-fcc12249cbbc\implementer\abcd-scenario-runs\receipts\T-ENG-04.json` |
| startedUtc | 2026-09-11T02:35:01.3856386Z |
| finishedUtc | 2026-09-11T02:35:01.6096964Z |

## 需求原文

```text
项目 C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite。用工程模式。目标：收口攻击到命中到伤害到死亡到复用的唯一闭环。要求：唯一入口、禁旁路扣血、重复命中策略、池化重置。交付：链路 + 缺口 + 运行时未验。
```

## 选择结果（live）

| 字段 | 值 |
|------|-----|
| directionCount | 5 |
| selectedDirectionId | `cand-338d4c85731d7235a14b` |
| selectedAxis | `failure-recovery` |
| selectionStatus | `deterministic-selected` |
| selectionPolicy | `deterministic-ranked-after-visible-tree-search` |
| claimLevel | `design-candidate` |
| divergenceStatus | `engineering-candidate` |
| candidateSetHash | `b4ee0d9d451dc80e935568c80167a07c25b08ffd7006f0c6753f3e55c142cc9c` |
| recommendedDirectionId | `cand-338d4c85731d7235a14b` |
| rejectedCandidatesCount | 0 |
| hiddenCandidatesCount | 1 |
| auditDeferred | True |
| qualityStatus | `mode-ready` |
| runtimeStatus | `runtime-not-run` |

## 本场全部方向

| # | directionId | axis |
|---|-------------|------|
| 1 | `cand-42aa84c27198baccce77` | `state-machine-integrity` |
| 2 | `cand-f781dc3c640fa733e185` | `ownership-lifecycle` |
| 3 | `cand-7267fc57f4dead3097c1` | `determinism` |
| 4 | `cand-e2341f95f9d4f1798c3d` | `performance-peak-budget` |
| 5 | `cand-338d4c85731d7235a14b` **SELECTED** | `failure-recovery` |

## ranked

| rank | directionId | axis | score |
|------|-------------|------|-------|
| 1 | `cand-338d4c85731d7235a14b` | `failure-recovery` | 89.9 |
| 2 | `cand-7267fc57f4dead3097c1` | `determinism` | 89.75 |
| 3 | `cand-42aa84c27198baccce77` | `state-machine-integrity` | 83.15 |
| 4 | `cand-e2341f95f9d4f1798c3d` | `performance-peak-budget` | 81.75 |
| 5 | `cand-f781dc3c640fa733e185` | `ownership-lifecycle` | 78.85 |

## 说明

- rejectedCandidatesCount=0（落选在 ranked，不等于否决书）。
- claimLevel=design-candidate；runtime-not-run：非 PlayMode/发版。
