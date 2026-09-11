# T-CRE-02 — Daily play loops

> 仅由本场 live 回执生成；禁止手填 cand-*。

## 元数据

| 字段 | 值 |
|------|-----|
| testId | `T-CRE-02` |
| title | Daily play loops |
| mode | `creative-divergence` |
| status | **passed** |
| entryPoint | `Invoke-ESABCModeDivergence+Select-ESABCGenerationCandidate` |
| packageRoot | `F:\aaProject\es-abcd` |
| trialRoot | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite` |
| contractPath | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite\ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json` |
| sourceHash | `329a0dc2e8374e15f3270533ed22553da0c83106fcf9709d29c69f5598d659de` |
| receiptJson | `C:\Users\asus\AppData\Local\Temp\grok-goal-fcc12249cbbc\implementer\abcd-scenario-runs\receipts\T-CRE-02.json` |
| startedUtc | 2026-09-11T02:35:01.8864526Z |
| finishedUtc | 2026-09-11T02:35:02.1627974Z |

## 需求原文

```text
项目 C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite。用创意模式。目标：采集-合成-战备-出击的5种日活循环。要求：硬核/休闲/社交；吸引谁烦谁。交付：5循环。
```

## 选择结果（live）

| 字段 | 值 |
|------|-----|
| directionCount | 7 |
| selectedDirectionId | `cand-4ec4a0ef0f7ca0968353` |
| selectedAxis | `skill-ceiling` |
| selectionStatus | `ranked-recommended` |
| selectionPolicy | `rank-after-visible-tree-search` |
| claimLevel | `design-candidate` |
| divergenceStatus | `creative-candidate` |
| candidateSetHash | `46ee993c36095dd70875b2ba2c18984251d85b73a3261758d2c7b9215f48f0f4` |
| recommendedDirectionId | `cand-4ec4a0ef0f7ca0968353` |
| rejectedCandidatesCount | 0 |
| hiddenCandidatesCount | 1 |
| auditDeferred | True |
| qualityStatus | `mode-ready` |
| runtimeStatus | `runtime-not-run` |

## 本场全部方向

| # | directionId | axis |
|---|-------------|------|
| 1 | `cand-73e89d5e86cb1aae60ce` | `moment-to-moment-feel` |
| 2 | `cand-454c80705b38c47e79de` | `flow-continuity` |
| 3 | `cand-cbb554a94f57efd5140f` | `presentation-beat` |
| 4 | `cand-516b76857460caf0f987` | `expressive-input` |
| 5 | `cand-4ec4a0ef0f7ca0968353` **SELECTED** | `skill-ceiling` |
| 6 | `cand-0111602c30f57e3da668` | `novelty-delta` |
| 7 | `cand-8c4760c48622a0afd11a` | `counterplay-clarity` |

## ranked

| rank | directionId | axis | score |
|------|-------------|------|-------|
| 1 | `cand-4ec4a0ef0f7ca0968353` | `skill-ceiling` | 93.9 |
| 2 | `cand-454c80705b38c47e79de` | `flow-continuity` | 89.75 |
| 3 | `cand-73e89d5e86cb1aae60ce` | `moment-to-moment-feel` | 89.35 |
| 4 | `cand-516b76857460caf0f987` | `expressive-input` | 88.35 |
| 5 | `cand-0111602c30f57e3da668` | `novelty-delta` | 88.2 |
| 6 | `cand-8c4760c48622a0afd11a` | `counterplay-clarity` | 80.5 |
| 7 | `cand-cbb554a94f57efd5140f` | `presentation-beat` | 78.35 |

## 说明

- rejectedCandidatesCount=0（落选在 ranked，不等于否决书）。
- claimLevel=design-candidate；runtime-not-run：非 PlayMode/发版。
