# T-CRE-01 — Melee skill feel

> 仅由本场 live 回执生成；禁止手填 cand-*。

## 元数据

| 字段 | 值 |
|------|-----|
| testId | `T-CRE-01` |
| title | Melee skill feel |
| mode | `creative-divergence` |
| status | **passed** |
| entryPoint | `Invoke-ESABCModeDivergence+Select-ESABCGenerationCandidate` |
| packageRoot | `F:\aaProject\es-abcd` |
| trialRoot | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite` |
| contractPath | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite\ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json` |
| sourceHash | `329a0dc2e8374e15f3270533ed22553da0c83106fcf9709d29c69f5598d659de` |
| receiptJson | `C:\Users\asus\AppData\Local\Temp\grok-goal-3e6ad67d1519\implementer\abcd-scenario-runs\receipts\T-CRE-01.json` |
| startedUtc | 2026-09-10T20:15:28.6981345Z |
| finishedUtc | 2026-09-10T20:15:28.9261239Z |

## 需求原文

```text
项目 C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite。用创意模式。目标：为近战爆发技能给出至少5种不同手感方向。要求：差异大；每方案卖点+硬伤。交付：多方案列表+尝试顺序。
```

## 选择结果（live）

| 字段 | 值 |
|------|-----|
| directionCount | 7 |
| selectedDirectionId | `cand-f28fe0d72897a6ff69be` |
| selectedAxis | `presentation-beat` |
| selectionStatus | `ranked-recommended` |
| selectionPolicy | `rank-after-visible-tree-search` |
| claimLevel | `design-candidate` |
| divergenceStatus | `creative-candidate` |
| candidateSetHash | `eff3ec1d6173ee0178e8accf5798a7c57c64c1cfe41113af7e08995ee6836b18` |
| recommendedDirectionId | `cand-f28fe0d72897a6ff69be` |
| rejectedCandidatesCount | 0 |
| hiddenCandidatesCount | 1 |
| auditDeferred | True |
| qualityStatus | `mode-ready` |
| runtimeStatus | `runtime-not-run` |

## 本场全部方向

| # | directionId | axis |
|---|-------------|------|
| 1 | `cand-a211f25bc06864c805f0` | `moment-to-moment-feel` |
| 2 | `cand-f8e0a3b0df78b3a12e66` | `flow-continuity` |
| 3 | `cand-f28fe0d72897a6ff69be` **SELECTED** | `presentation-beat` |
| 4 | `cand-851106fd106bf9538b5b` | `expressive-input` |
| 5 | `cand-23eef324389e695e2431` | `skill-ceiling` |
| 6 | `cand-0750e804561ab101bfeb` | `novelty-delta` |
| 7 | `cand-d55c66e5464302c85bc3` | `counterplay-clarity` |

## ranked

| rank | directionId | axis | score |
|------|-------------|------|-------|
| 1 | `cand-f28fe0d72897a6ff69be` | `presentation-beat` | 85.5 |
| 2 | `cand-a211f25bc06864c805f0` | `moment-to-moment-feel` | 81.9 |
| 3 | `cand-d55c66e5464302c85bc3` | `counterplay-clarity` | 81.75 |
| 4 | `cand-0750e804561ab101bfeb` | `novelty-delta` | 80.95 |
| 5 | `cand-851106fd106bf9538b5b` | `expressive-input` | 80.05 |
| 6 | `cand-23eef324389e695e2431` | `skill-ceiling` | 75.6 |
| 7 | `cand-f8e0a3b0df78b3a12e66` | `flow-continuity` | 75.35 |

## 说明

- rejectedCandidatesCount=0（落选在 ranked，不等于否决书）。
- claimLevel=design-candidate；runtime-not-run：非 PlayMode/发版。
