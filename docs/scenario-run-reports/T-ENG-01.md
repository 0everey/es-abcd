# T-ENG-01 · 设计可扩展技能系统

> **模式：** 工程模式 · **状态：通过** · **设计候选** · **运行时未验**  
> 本文是给人看的完整解说 + ABCD 思路链；底部为可核对 live 证据。

---

## 一、这场测试在问什么

| 项 | 内容 |
|----|------|
| 编号 | `T-ENG-01` |
| 模式 | **工程模式** (`engineering`) |
| 场景 | **设计可扩展技能系统** |
| 为什么测 | 要把主动/被动、冷却消耗、等级和战斗结算接清楚，还不能搞出两套技能并行。 |
| 你真正想问的 | 工程模式下，技能系统怎么拆模块、数据归谁、怎么进战斗。 |

### 输入给 ABCD 的需求原文

```text
项目 <项目根路径>。用工程模式。目标：设计一套可扩展的技能系统（主动/被动/冷却/消耗/等级）。要求：说清模块边界、数据归谁管、和战斗结算怎么接、禁止两套技能并行。交付：方案要点 + 风险 + 还不能宣称已实装/已平衡。
```

---

## 二、ABCD 完整思路链条（本场真实走过）

```text
① 接收需求文本 + 指定模式 = engineering
② 读取生成模式合同 generation-mode（工程/创意/稳定的轴家族与策略）
③ Invoke-ESABCModeDivergence  —— 强制展开多条「方向轴」
      本场可见方向数 = 5
④ Select-ESABCGenerationCandidate —— 对可见方向打分、排序、选出主推荐
⑤ 写出 claimLevel / runtimeStatus 等封顶字段（防吹成已可玩）
      claimLevel = design-candidate
      runtimeStatus = runtime-not-run
```

### 链条上每一步在干什么

1. **模式合同**：决定本场关心哪些轴（工程偏状态/所有权/恢复；创意偏手感/表现/新颖；稳定偏回滚/兼容）。
2. **发散 Divergence**：不是只写一篇散文，而是长出多条可并列的方向。
3. **选择 Select**：在多条里排序；落选仍在 ranked 里，不是拉黑。
4. **封顶**：本场明确只能当设计候选，且运行时未验——讨论方案可以，宣称已上线不行。

---

## 三、本场结论（先看懂）

| 项 | 结果 |
|----|------|
| 是否跑通 | **是（passed）** |
| 可见方向数 | **5** |
| 主推荐主题 | **状态机 / 流程严谨性** |
| 主推荐 ID | `cand-1512670ca9b9c3275ce2` |
| 怎么选的 | 按规则**确定一个**主推荐（其余方向仍保留在排名里，供对比） |
| 场内第 1 名排序分 | **87.5** |
| 比第 2 名高出 | **1.5** |
| 第 1 名与末名分差 | **5.2** |
| 质量状态 | `mode-ready` |
| 审计是否后置 | `True` |
| 否决名单条数 | 0（本场主要是选优） |

### AI 解说

主推「流程/状态是否严谨」，说明系统先关心技能从释放到结算的状态是否闭环、有没有非法跳转。

### 你拿结果该做什么

1. 让 AI **按主推荐主题**写成可执行结构（模块、数据、接口、风险）。
2. 用下面排名第 2、第 3 名当备选/挑刺视角。
3. 要求列出你要拍板的 3 件事；并写明 **未实装、未 PlayMode**。
4. 审计时用文末 hash / JSON 核对，禁止手改 cand-*。

---

## 四、全部方向（live）

| # | 角色 | 方向 ID | 轴英文 | 轴中文 |
|---|------|---------|--------|--------|
| 1 | **主推** | `cand-1512670ca9b9c3275ce2` | `state-machine-integrity` | 状态机 / 流程严谨性 |
| 2 | 备选 | `cand-3e01b3f23b45dbf4da76` | `ownership-lifecycle` | 所有权与生命周期 |
| 3 | 备选 | `cand-eec6bd9960ab8d24715d` | `determinism` | 确定性与可复现 |
| 4 | 备选 | `cand-e90300a3d127320a0dd5` | `performance-peak-budget` | 性能峰值与预算 |
| 5 | 备选 | `cand-1d6efcdd2a0d1a8fcc2a` | `failure-recovery` | 失败恢复 |

---

## 五、排序与分数（live ranked）

| 名次 | 分数 | 轴中文 | 方向 ID |
|------|------|--------|---------|
| 1 ★ | **87.5** | 状态机 / 流程严谨性 | `cand-1512670ca9b9c3275ce2` |
| 2 | **86** | 性能峰值与预算 | `cand-e90300a3d127320a0dd5` |
| 3 | **85.1** | 失败恢复 | `cand-1d6efcdd2a0d1a8fcc2a` |
| 4 | **84.45** | 所有权与生命周期 | `cand-3e01b3f23b45dbf4da76` |
| 5 | **82.3** | 确定性与可复现 | `cand-eec6bd9960ab8d24715d` |

### 分数怎么读

- 这是 **本场方向之间的排序分**，用来决定主推，不是「游戏做好了」的分。
- 第 1 名 **87.5**，第 2 名 **86**，领先 **1.5**；末名 **82.3**，跨度 **5.2**。
- 与「vs 仅提示词」的 /100 量表不是同一套分；那套在对比文档里。

---

## 六、和仅提示词 AI 的对比（同题）

本场另有 **不加载 ABCD、只丢提示词** 的对照答卷，并用同一 10 维量表打分：

- 分场对比（含仅提示词全文）：[per-case/T-ENG-01.md](../abcd-vs-prompt-only/per-case/T-ENG-01.md)
- 总对比：[abcd-vs-prompt-only/README.md](../abcd-vs-prompt-only/README.md)

人话：仅提示词常写「能开工/能上线」；ABCD 强制多方向 + 设计候选封顶 + 可回执。

---

## 七、建议接着对 AI 说

```text
基于 T-ENG-01（设计可扩展技能系统 / 工程模式），主推是「状态机 / 流程严谨性」。
请用人话：
1) 按主推主题给出可执行方案结构；
2) 用排名第2、第3方向各挑一个风险或备选；
3) 列出我要拍板的3件事；
4) 明确尚未实装、未做 PlayMode/发版验收。
```

## 八、证据字段（审计）

| 字段 | 值 |
|------|-----|
| testId | `T-ENG-01` |
| status | `passed` |
| entryPoint | `Invoke-ESABCModeDivergence+Select-ESABCGenerationCandidate` |
| packageRoot | `F:\aaProject\es-abcd` |
| trialRoot | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite` |
| contractPath | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite\ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json` |
| sourceHash | `329a0dc2e8374e15f3270533ed22553da0c83106fcf9709d29c69f5598d659de` |
| candidateSetHash | `5dad3f4ca65e162588d1f9bdfe80b17d53dae38f8c44ba94dc7c0903670f04c1` |
| selectedDirectionId | `cand-1512670ca9b9c3275ce2` |
| recommendedDirectionId | `cand-1512670ca9b9c3275ce2` |
| selectionStatus | `deterministic-selected` |
| selectionPolicy | `deterministic-ranked-after-visible-tree-search` |
| divergenceStatus | `engineering-candidate` |
| claimLevel | `design-candidate` |
| runtimeStatus | `runtime-not-run` |
| qualityStatus | `mode-ready` |
| auditDeferred | `True` |
| rejectedCandidatesCount | 0 |
| hiddenCandidatesCount | 1 |
| startedUtc | 2026-09-11T02:35:00.1819415Z |
| finishedUtc | 2026-09-11T02:35:00.9253705Z |
| 回执 JSON | [receipts/T-ENG-01.json](./receipts/T-ENG-01.json) |

---

## 九、导航

- [仓库首页 README](../../README.md)
- [12 场对照表](./COMPARISON-modes-live.md)
- [证据目录](./README.md)
- [vs 仅提示词](../abcd-vs-prompt-only/README.md)

> 禁止手改 cand-* / 分数。复跑场景套件后执行：`powershell -File .\\scripts\\Build-ScenarioHumanReports.ps1` 
