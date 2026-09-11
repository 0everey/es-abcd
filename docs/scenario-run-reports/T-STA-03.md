# T-STA-03 · 运营活动开关与配置

> **模式：** 稳定模式 · **状态：通过** · **设计候选** · **运行时未验**  
> 本文是给人看的完整解说 + ABCD 思路链；底部为可核对 live 证据。

---

## 一、这场测试在问什么

| 项 | 内容 |
|----|------|
| 编号 | `T-STA-03` |
| 模式 | **稳定模式** (`stable`) |
| 场景 | **运营活动开关与配置** |
| 为什么测 | 默认关、可回退、可追查，不影响日常关卡。 |
| 你真正想问的 | 稳定模式下，开关权限与事故预案。 |

### 输入给 ABCD 的需求原文

```text
项目 <项目根路径>。用稳定模式。目标：活动开关配置下发不影响日常关卡。要求：默认关可回退可追日志。交付：开关方案。
```

---

## 二、ABCD 完整思路链条（本场真实走过）

```text
① 接收需求文本 + 指定模式 = stable
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
| 主推荐主题 | **贴合现有集成** |
| 主推荐 ID | `cand-17070a1c467afb7c4ec4` |
| 怎么选的 | 按规则**确定一个**主推荐（其余方向仍保留在排名里，供对比） |
| 场内第 1 名排序分 | **90.75** |
| 比第 2 名高出 | **1.1** |
| 第 1 名与末名分差 | **12.85** |
| 质量状态 | `mode-ready` |
| 审计是否后置 | `True` |
| 否决名单条数 | 0（本场主要是选优） |

### AI 解说

主推「贴合现有集成」：活动要嵌进现有启动/配置管线，而不是另起炉灶。

### 你拿结果该做什么

1. 让 AI **按主推荐主题**写成可执行结构（模块、数据、接口、风险）。
2. 用下面排名第 2、第 3 名当备选/挑刺视角。
3. 要求列出你要拍板的 3 件事；并写明 **未实装、未 PlayMode**。
4. 审计时用文末 hash / JSON 核对，禁止手改 cand-*。

---

## 四、全部方向（live）

| # | 角色 | 方向 ID | 轴英文 | 轴中文 |
|---|------|---------|--------|--------|
| 1 | 备选 | `cand-6cb72c2bfc7a6a62f35e` | `contract-completeness` | 契约 / 配置完备 |
| 2 | **主推** | `cand-17070a1c467afb7c4ec4` | `integration-fit` | 贴合现有集成 |
| 3 | 备选 | `cand-701f66b2ac7c43ae6d2b` | `compatibility` | 兼容性 |
| 4 | 备选 | `cand-e4a5c7d6ce2e595174d8` | `regression-fixture` | 回归夹具 |
| 5 | 备选 | `cand-f556d680cf8d15bd3405` | `rollback` | 可回滚 |

---

## 五、排序与分数（live ranked）

| 名次 | 分数 | 轴中文 | 方向 ID |
|------|------|--------|---------|
| 1 ★ | **90.75** | 贴合现有集成 | `cand-17070a1c467afb7c4ec4` |
| 2 | **89.65** | 回归夹具 | `cand-e4a5c7d6ce2e595174d8` |
| 3 | **85.75** | 兼容性 | `cand-701f66b2ac7c43ae6d2b` |
| 4 | **78.7** | 契约 / 配置完备 | `cand-6cb72c2bfc7a6a62f35e` |
| 5 | **77.9** | 可回滚 | `cand-f556d680cf8d15bd3405` |

### 分数怎么读

- 这是 **本场方向之间的排序分**，用来决定主推，不是「游戏做好了」的分。
- 第 1 名 **90.75**，第 2 名 **89.65**，领先 **1.1**；末名 **77.9**，跨度 **12.85**。
- 与「vs 仅提示词」的 /100 量表不是同一套分；那套在对比文档里。

---

## 六、和仅提示词 AI 的对比（同题）

本场另有 **不加载 ABCD、只丢提示词** 的对照答卷，并用同一 10 维量表打分：

- 分场对比（含仅提示词全文）：[per-case/T-STA-03.md](../abcd-vs-prompt-only/per-case/T-STA-03.md)
- 总对比：[abcd-vs-prompt-only/README.md](../abcd-vs-prompt-only/README.md)

人话：仅提示词常写「能开工/能上线」；ABCD 强制多方向 + 设计候选封顶 + 可回执。

---

## 七、建议接着对 AI 说

```text
基于 T-STA-03（运营活动开关与配置 / 稳定模式），主推是「贴合现有集成」。
请用人话：
1) 按主推主题给出可执行方案结构；
2) 用排名第2、第3方向各挑一个风险或备选；
3) 列出我要拍板的3件事；
4) 明确尚未实装、未做 PlayMode/发版验收。
```

## 八、证据字段（审计）

| 字段 | 值 |
|------|-----|
| testId | `T-STA-03` |
| status | `passed` |
| entryPoint | `Invoke-ESABCModeDivergence+Select-ESABCGenerationCandidate` |
| packageRoot | `F:\aaProject\es-abcd` |
| trialRoot | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite` |
| contractPath | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite\ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json` |
| sourceHash | `329a0dc2e8374e15f3270533ed22553da0c83106fcf9709d29c69f5598d659de` |
| candidateSetHash | `98baf5c176f312f37b8420dc3a93e6a311455cd901750b201665bd0c4041ac07` |
| selectedDirectionId | `cand-17070a1c467afb7c4ec4` |
| recommendedDirectionId | `cand-17070a1c467afb7c4ec4` |
| selectionStatus | `deterministic-selected` |
| selectionPolicy | `deterministic-ranked-after-visible-tree-search` |
| divergenceStatus | `stable-candidate` |
| claimLevel | `design-candidate` |
| runtimeStatus | `runtime-not-run` |
| qualityStatus | `mode-ready` |
| auditDeferred | `True` |
| rejectedCandidatesCount | 0 |
| hiddenCandidatesCount | 1 |
| startedUtc | 2026-09-11T02:35:03.0427835Z |
| finishedUtc | 2026-09-11T02:35:03.2059429Z |
| 回执 JSON | [receipts/T-STA-03.json](./receipts/T-STA-03.json) |

---

## 九、导航

- [仓库首页 README](../../README.md)
- [12 场对照表](./COMPARISON-modes-live.md)
- [证据目录](./README.md)
- [vs 仅提示词](../abcd-vs-prompt-only/README.md)

> 禁止手改 cand-* / 分数。复跑场景套件后执行：`powershell -File .\\scripts\\Build-ScenarioHumanReports.ps1` 
