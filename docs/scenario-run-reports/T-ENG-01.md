# T-ENG-01 — Design skill system

> 仅由本场 live 回执生成；禁止手填 cand-*。

## 元数据

| 字段 | 值 |
|------|-----|
| testId | `T-ENG-01` |
| title | Design skill system |
| mode | `engineering` |
| status | **passed** |
| entryPoint | `Invoke-ESABCModeDivergence+Select-ESABCGenerationCandidate` |
| packageRoot | `F:\aaProject\es-abcd` |
| trialRoot | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite` |
| contractPath | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite\ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json` |
| sourceHash | `329a0dc2e8374e15f3270533ed22553da0c83106fcf9709d29c69f5598d659de` |
| receiptJson | `C:\Users\asus\AppData\Local\Temp\grok-goal-3e6ad67d1519\implementer\abcd-scenario-runs\receipts\T-ENG-01.json` |
| startedUtc | 2026-09-10T20:15:27.6324960Z |
| finishedUtc | 2026-09-10T20:15:28.0946987Z |

## 需求原文

```text
项目 C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite。用工程模式。目标：设计一套可扩展的技能系统（主动/被动/冷却/消耗/等级）。要求：说清模块边界、数据归谁管、和战斗结算怎么接、禁止两套技能并行。交付：方案要点 + 风险 + 还不能宣称已实装/已平衡。
```

## 选择结果（live）

| 字段 | 值 |
|------|-----|
| directionCount | 5 |
| selectedDirectionId | `cand-1512670ca9b9c3275ce2` |
| selectedAxis | `state-machine-integrity` |
| selectionStatus | `deterministic-selected` |
| selectionPolicy | `deterministic-ranked-after-visible-tree-search` |
| claimLevel | `design-candidate` |
| divergenceStatus | `engineering-candidate` |
| candidateSetHash | `5dad3f4ca65e162588d1f9bdfe80b17d53dae38f8c44ba94dc7c0903670f04c1` |
| recommendedDirectionId | `cand-1512670ca9b9c3275ce2` |
| rejectedCandidatesCount | 0 |
| hiddenCandidatesCount | 1 |
| auditDeferred | True |
| qualityStatus | `mode-ready` |
| runtimeStatus | `runtime-not-run` |

## 本场全部方向

| # | directionId | axis |
|---|-------------|------|
| 1 | `cand-1512670ca9b9c3275ce2` **SELECTED** | `state-machine-integrity` |
| 2 | `cand-3e01b3f23b45dbf4da76` | `ownership-lifecycle` |
| 3 | `cand-eec6bd9960ab8d24715d` | `determinism` |
| 4 | `cand-e90300a3d127320a0dd5` | `performance-peak-budget` |
| 5 | `cand-1d6efcdd2a0d1a8fcc2a` | `failure-recovery` |

## ranked

| rank | directionId | axis | score |
|------|-------------|------|-------|
| 1 | `cand-1512670ca9b9c3275ce2` | `state-machine-integrity` | 87.5 |
| 2 | `cand-e90300a3d127320a0dd5` | `performance-peak-budget` | 86 |
| 3 | `cand-1d6efcdd2a0d1a8fcc2a` | `failure-recovery` | 85.1 |
| 4 | `cand-3e01b3f23b45dbf4da76` | `ownership-lifecycle` | 84.45 |
| 5 | `cand-eec6bd9960ab8d24715d` | `determinism` | 82.3 |

## 说明

- rejectedCandidatesCount=0（落选在 ranked，不等于否决书）。
- claimLevel=design-candidate；runtime-not-run：非 PlayMode/发版。
