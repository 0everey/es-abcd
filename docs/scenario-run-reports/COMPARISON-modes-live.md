# 三模式场景实测对比（仅来自 numbered 回执）

> generatedUtc: 2026-09-10T20:15:30.0264265Z
>
> trialRoot: `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite`
>
> packageRoot: `F:\aaProject\es-abcd`
>
> 表中 cand-* 仅来自本场 receipts，禁止手改。

## 汇总表

| testId | mode | status | directionCount | selectedDirectionId | selectedAxis | selectionStatus | selectionPolicy | claimLevel | candidateSetHash |
|--------|------|--------|----------------|---------------------|--------------|-----------------|-----------------|------------|------------------|
| `T-ENG-01` | `engineering` | **passed** | 5 | `cand-1512670ca9b9c3275ce2` | `state-machine-integrity` | `deterministic-selected` | `deterministic-ranked-after-visible-tree-search` | `design-candidate` | `5dad3f4ca65e162588d1f9bdfe80b17d53dae38f8c44ba94dc7c0903670f04c1` |
| `T-ENG-02` | `engineering` | **passed** | 5 | `cand-cdd33ebac2799bc8f03c` | `state-machine-integrity` | `deterministic-selected` | `deterministic-ranked-after-visible-tree-search` | `design-candidate` | `6d543bf5b342a2793779f52695df6c1a3c2d6bda33131f6a1fc6d4bebe8d0b86` |
| `T-ENG-03` | `engineering` | **passed** | 5 | `cand-be1cfc2e0345a72f7614` | `performance-peak-budget` | `deterministic-selected` | `deterministic-ranked-after-visible-tree-search` | `design-candidate` | `18ada1e9ef5aacc5439bc38728eb66779c47181c361ee52c82e0e9d14665faee` |
| `T-ENG-04` | `engineering` | **passed** | 5 | `cand-338d4c85731d7235a14b` | `failure-recovery` | `deterministic-selected` | `deterministic-ranked-after-visible-tree-search` | `design-candidate` | `b4ee0d9d451dc80e935568c80167a07c25b08ffd7006f0c6753f3e55c142cc9c` |
| `T-CRE-01` | `creative-divergence` | **passed** | 7 | `cand-f28fe0d72897a6ff69be` | `presentation-beat` | `ranked-recommended` | `rank-after-visible-tree-search` | `design-candidate` | `eff3ec1d6173ee0178e8accf5798a7c57c64c1cfe41113af7e08995ee6836b18` |
| `T-CRE-02` | `creative-divergence` | **passed** | 7 | `cand-4ec4a0ef0f7ca0968353` | `skill-ceiling` | `ranked-recommended` | `rank-after-visible-tree-search` | `design-candidate` | `46ee993c36095dd70875b2ba2c18984251d85b73a3261758d2c7b9215f48f0f4` |
| `T-CRE-03` | `creative-divergence` | **passed** | 7 | `cand-0848c7565cb237906782` | `flow-continuity` | `ranked-recommended` | `rank-after-visible-tree-search` | `design-candidate` | `3e47918c187e34313efddd2e7b242042d60490bf10bb3b1792768a16bf9c4c5b` |
| `T-CRE-04` | `creative-divergence` | **passed** | 7 | `cand-e1f33204812d14140800` | `flow-continuity` | `ranked-recommended` | `rank-after-visible-tree-search` | `design-candidate` | `15c81a57675ac33a3c2a5448b5028ef313f2361da5046ce411f6e9da32a562b4` |
| `T-STA-01` | `stable` | **passed** | 5 | `cand-2efc8c2dc69e419bc888` | `rollback` | `deterministic-selected` | `deterministic-ranked-after-visible-tree-search` | `design-candidate` | `f2d62c2501090f1df70f5e300f89999d9657ef58d888e2fb13d1a55af46f19ec` |
| `T-STA-02` | `stable` | **passed** | 5 | `cand-92b98548daf46acddb45` | `rollback` | `deterministic-selected` | `deterministic-ranked-after-visible-tree-search` | `design-candidate` | `574ea1789eecefb4ac5199b6ebcbc60c675035b8179d2f91d33334f195b7ba04` |
| `T-STA-03` | `stable` | **passed** | 5 | `cand-17070a1c467afb7c4ec4` | `integration-fit` | `deterministic-selected` | `deterministic-ranked-after-visible-tree-search` | `design-candidate` | `98baf5c176f312f37b8420dc3a93e6a311455cd901750b201665bd0c4041ac07` |
| `T-STA-04` | `stable` | **passed** | 5 | `cand-4bba0192d92567aedf6b` | `compatibility` | `deterministic-selected` | `deterministic-ranked-after-visible-tree-search` | `design-candidate` | `f477679d8d86e0ca084b722f5563946402cfcc8457b26c80b85ac9b00897ac4b` |

## 按模式

### `engineering`

- 场次=4 passed=4 failed=0
- directionCount: 5
- 当选 axis: `state-machine-integrity`, `performance-peak-budget`, `failure-recovery`
- selectionStatus: `deterministic-selected`

### `creative-divergence`

- 场次=4 passed=4 failed=0
- directionCount: 7
- 当选 axis: `presentation-beat`, `skill-ceiling`, `flow-continuity`
- selectionStatus: `ranked-recommended`

### `stable`

- 场次=4 passed=4 failed=0
- directionCount: 5
- 当选 axis: `rollback`, `integration-fit`, `compatibility`
- selectionStatus: `deterministic-selected`

## 证据索引

| testId | receipt | md |
|--------|---------|-----|
| `T-ENG-01` | `C:\Users\asus\AppData\Local\Temp\grok-goal-3e6ad67d1519\implementer\abcd-scenario-runs\receipts\T-ENG-01.json` | `F:\aaProject\es-abcd\docs\scenario-run-reports\T-ENG-01.md` |
| `T-ENG-02` | `C:\Users\asus\AppData\Local\Temp\grok-goal-3e6ad67d1519\implementer\abcd-scenario-runs\receipts\T-ENG-02.json` | `F:\aaProject\es-abcd\docs\scenario-run-reports\T-ENG-02.md` |
| `T-ENG-03` | `C:\Users\asus\AppData\Local\Temp\grok-goal-3e6ad67d1519\implementer\abcd-scenario-runs\receipts\T-ENG-03.json` | `F:\aaProject\es-abcd\docs\scenario-run-reports\T-ENG-03.md` |
| `T-ENG-04` | `C:\Users\asus\AppData\Local\Temp\grok-goal-3e6ad67d1519\implementer\abcd-scenario-runs\receipts\T-ENG-04.json` | `F:\aaProject\es-abcd\docs\scenario-run-reports\T-ENG-04.md` |
| `T-CRE-01` | `C:\Users\asus\AppData\Local\Temp\grok-goal-3e6ad67d1519\implementer\abcd-scenario-runs\receipts\T-CRE-01.json` | `F:\aaProject\es-abcd\docs\scenario-run-reports\T-CRE-01.md` |
| `T-CRE-02` | `C:\Users\asus\AppData\Local\Temp\grok-goal-3e6ad67d1519\implementer\abcd-scenario-runs\receipts\T-CRE-02.json` | `F:\aaProject\es-abcd\docs\scenario-run-reports\T-CRE-02.md` |
| `T-CRE-03` | `C:\Users\asus\AppData\Local\Temp\grok-goal-3e6ad67d1519\implementer\abcd-scenario-runs\receipts\T-CRE-03.json` | `F:\aaProject\es-abcd\docs\scenario-run-reports\T-CRE-03.md` |
| `T-CRE-04` | `C:\Users\asus\AppData\Local\Temp\grok-goal-3e6ad67d1519\implementer\abcd-scenario-runs\receipts\T-CRE-04.json` | `F:\aaProject\es-abcd\docs\scenario-run-reports\T-CRE-04.md` |
| `T-STA-01` | `C:\Users\asus\AppData\Local\Temp\grok-goal-3e6ad67d1519\implementer\abcd-scenario-runs\receipts\T-STA-01.json` | `F:\aaProject\es-abcd\docs\scenario-run-reports\T-STA-01.md` |
| `T-STA-02` | `C:\Users\asus\AppData\Local\Temp\grok-goal-3e6ad67d1519\implementer\abcd-scenario-runs\receipts\T-STA-02.json` | `F:\aaProject\es-abcd\docs\scenario-run-reports\T-STA-02.md` |
| `T-STA-03` | `C:\Users\asus\AppData\Local\Temp\grok-goal-3e6ad67d1519\implementer\abcd-scenario-runs\receipts\T-STA-03.json` | `F:\aaProject\es-abcd\docs\scenario-run-reports\T-STA-03.md` |
| `T-STA-04` | `C:\Users\asus\AppData\Local\Temp\grok-goal-3e6ad67d1519\implementer\abcd-scenario-runs\receipts\T-STA-04.json` | `F:\aaProject\es-abcd\docs\scenario-run-reports\T-STA-04.md` |

## 非声明

- design-candidate / runtime-not-run only
- not Unity PlayMode / release
