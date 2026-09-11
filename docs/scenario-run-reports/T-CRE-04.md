# T-CRE-04 · 同一 Boss 多种战法

> **模式：** 创意模式 · **状态：通过** · **设计候选** · **运行时未验**  
> 本文是给人看的完整解说 + ABCD 思路链；底部为可核对 live 证据。

---

## 一、这场测试在问什么

| 项 | 内容 |
|----|------|
| 编号 | `T-CRE-04` |
| 模式 | **创意模式** (`creative-divergence`) |
| 场景 | **同一 Boss 多种战法** |
| 为什么测 | 机制/叙事/解谜/配队/Roguelike 等打法要拉开。 |
| 你真正想问的 | 创意模式下，五种战法与失败是否有趣。 |

### 输入给 ABCD 的需求原文

```text
项目 <项目根路径>。用创意模式。目标：同一Boss五种战法。要求：机制/叙事/解谜/配队/Roguelike。交付：5战法卡。
```

---

## 二、ABCD 完整思路链条（本场真实走过）

```text
① 接收需求文本 + 指定模式 = creative-divergence
② 读取生成模式合同 generation-mode（工程/创意/稳定的轴家族与策略）
③ Invoke-ESABCModeDivergence  —— 强制展开多条「方向轴」
      本场可见方向数 = 7
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
| 可见方向数 | **7** |
| 主推荐主题 | **心流连贯** |
| 主推荐 ID | `cand-e1f33204812d14140800` |
| 怎么选的 | 先排序再**推荐第一**（创意常见；第二名及以后仍可讨论） |
| 场内第 1 名排序分 | **92.3** |
| 比第 2 名高出 | **0.35** |
| 第 1 名与末名分差 | **9.45** |
| 质量状态 | `mode-ready` |
| 审计是否后置 | `True` |
| 否决名单条数 | 0（本场主要是选优） |

### AI 解说

主推「心流连贯」，与「新颖」几乎并列——Boss 战既要新鲜也要打得顺。

**分差提醒：** 第 1 名与第 2 名仅差 **0.35**，请把亚军方向一并讨论，不要只盯第一名。

### 你拿结果该做什么

1. 让 AI **按主推荐主题**写成可执行结构（模块、数据、接口、风险）。
2. 用下面排名第 2、第 3 名当备选/挑刺视角。
3. 要求列出你要拍板的 3 件事；并写明 **未实装、未 PlayMode**。
4. 审计时用文末 hash / JSON 核对，禁止手改 cand-*。

---

## 四、全部方向（live）

| # | 角色 | 方向 ID | 轴英文 | 轴中文 |
|---|------|---------|--------|--------|
| 1 | 备选 | `cand-bb1e4b25e5e615c53963` | `moment-to-moment-feel` | 瞬时手感 |
| 2 | **主推** | `cand-e1f33204812d14140800` | `flow-continuity` | 心流连贯 |
| 3 | 备选 | `cand-2eab52203d19cccd3d49` | `presentation-beat` | 表现与节拍 |
| 4 | 备选 | `cand-090f9d2fedddf3b66b4c` | `expressive-input` | 表达性输入 |
| 5 | 备选 | `cand-36953147c6e4bf2755bb` | `skill-ceiling` | 技巧上限 / 深度 |
| 6 | 备选 | `cand-6b1eb70e4fc603646909` | `novelty-delta` | 新颖增量 |
| 7 | 备选 | `cand-3be95969b1860c7ea6de` | `counterplay-clarity` | 反制清晰度 |

---

## 五、排序与分数（live ranked）

| 名次 | 分数 | 轴中文 | 方向 ID |
|------|------|--------|---------|
| 1 ★ | **92.3** | 心流连贯 | `cand-e1f33204812d14140800` |
| 2 | **91.95** | 新颖增量 | `cand-6b1eb70e4fc603646909` |
| 3 | **88** | 表现与节拍 | `cand-2eab52203d19cccd3d49` |
| 4 | **86.65** | 反制清晰度 | `cand-3be95969b1860c7ea6de` |
| 5 | **84.95** | 瞬时手感 | `cand-bb1e4b25e5e615c53963` |
| 6 | **83.15** | 技巧上限 / 深度 | `cand-36953147c6e4bf2755bb` |
| 7 | **82.85** | 表达性输入 | `cand-090f9d2fedddf3b66b4c` |

### 分数怎么读

- 这是 **本场方向之间的排序分**，用来决定主推，不是「游戏做好了」的分。
- 第 1 名 **92.3**，第 2 名 **91.95**，领先 **0.35**；末名 **82.85**，跨度 **9.45**。
- 与「vs 仅提示词」的 /100 量表不是同一套分；那套在对比文档里。

---

## 六、和仅提示词 AI 的对比（同题）

本场另有 **不加载 ABCD、只丢提示词** 的对照答卷，并用同一 10 维量表打分：

- 分场对比（含仅提示词全文）：[per-case/T-CRE-04.md](../abcd-vs-prompt-only/per-case/T-CRE-04.md)
- 总对比：[abcd-vs-prompt-only/README.md](../abcd-vs-prompt-only/README.md)

人话：仅提示词常写「能开工/能上线」；ABCD 强制多方向 + 设计候选封顶 + 可回执。

---

## 七、建议接着对 AI 说

```text
基于 T-CRE-04（同一 Boss 多种战法 / 创意模式），主推是「心流连贯」。
请用人话：
1) 按主推主题给出可执行方案结构；
2) 用排名第2、第3方向各挑一个风险或备选；
3) 列出我要拍板的3件事；
4) 明确尚未实装、未做 PlayMode/发版验收。
```

## 八、证据字段（审计）

| 字段 | 值 |
|------|-----|
| testId | `T-CRE-04` |
| status | `passed` |
| entryPoint | `Invoke-ESABCModeDivergence+Select-ESABCGenerationCandidate` |
| packageRoot | `F:\aaProject\es-abcd` |
| trialRoot | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite` |
| contractPath | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite\ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json` |
| sourceHash | `329a0dc2e8374e15f3270533ed22553da0c83106fcf9709d29c69f5598d659de` |
| candidateSetHash | `15c81a57675ac33a3c2a5448b5028ef313f2361da5046ce411f6e9da32a562b4` |
| selectedDirectionId | `cand-e1f33204812d14140800` |
| recommendedDirectionId | `cand-e1f33204812d14140800` |
| selectionStatus | `ranked-recommended` |
| selectionPolicy | `rank-after-visible-tree-search` |
| divergenceStatus | `creative-candidate` |
| claimLevel | `design-candidate` |
| runtimeStatus | `runtime-not-run` |
| qualityStatus | `mode-ready` |
| auditDeferred | `True` |
| rejectedCandidatesCount | 0 |
| hiddenCandidatesCount | 1 |
| startedUtc | 2026-09-11T02:35:02.4380601Z |
| finishedUtc | 2026-09-11T02:35:02.6721955Z |
| 回执 JSON | [receipts/T-CRE-04.json](./receipts/T-CRE-04.json) |

---

## 九、导航

- [仓库首页 README](../../README.md)
- [12 场对照表](./COMPARISON-modes-live.md)
- [证据目录](./README.md)
- [vs 仅提示词](../abcd-vs-prompt-only/README.md)

> 禁止手改 cand-* / 分数。复跑场景套件后执行：`powershell -File .\\scripts\\Build-ScenarioHumanReports.ps1` 
