# T-CRE-02 · 日活玩法循环变体

> **模式：** 创意模式 · **状态：通过** · **设计候选** · **运行时未验**  
> 本文是给人看的完整解说 + ABCD 思路链；底部为可核对 live 证据。

---

## 一、这场测试在问什么

| 项 | 内容 |
|----|------|
| 编号 | `T-CRE-02` |
| 模式 | **创意模式** (`creative-divergence`) |
| 场景 | **日活玩法循环变体** |
| 为什么测 | 采集-合成-战备-出击要多套循环，服务不同玩家。 |
| 你真正想问的 | 创意模式下，硬核/休闲/社交等循环怎么分、谁会烦。 |

### 输入给 ABCD 的需求原文

```text
项目 <项目根路径>。用创意模式。目标：采集-合成-战备-出击的5种日活循环。要求：硬核/休闲/社交；吸引谁烦谁。交付：5循环。
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
| 主推荐主题 | **技巧上限 / 深度** |
| 主推荐 ID | `cand-4ec4a0ef0f7ca0968353` |
| 怎么选的 | 先排序再**推荐第一**（创意常见；第二名及以后仍可讨论） |
| 场内第 1 名排序分 | **93.9** |
| 比第 2 名高出 | **4.15** |
| 第 1 名与末名分差 | **15.55** |
| 质量状态 | `mode-ready` |
| 审计是否后置 | `True` |
| 否决名单条数 | 0（本场主要是选优） |

### AI 解说

主推「技巧上限」：日活深度与玩家成长天花板成为推荐焦点。

**分差提醒：** 主推领先较明显（+4.15），可先沿主推深化，再扫排名 2–3 名挑刺。

### 你拿结果该做什么

1. 让 AI **按主推荐主题**写成可执行结构（模块、数据、接口、风险）。
2. 用下面排名第 2、第 3 名当备选/挑刺视角。
3. 要求列出你要拍板的 3 件事；并写明 **未实装、未 PlayMode**。
4. 审计时用文末 hash / JSON 核对，禁止手改 cand-*。

---

## 四、全部方向（live）

| # | 角色 | 方向 ID | 轴英文 | 轴中文 |
|---|------|---------|--------|--------|
| 1 | 备选 | `cand-73e89d5e86cb1aae60ce` | `moment-to-moment-feel` | 瞬时手感 |
| 2 | 备选 | `cand-454c80705b38c47e79de` | `flow-continuity` | 心流连贯 |
| 3 | 备选 | `cand-cbb554a94f57efd5140f` | `presentation-beat` | 表现与节拍 |
| 4 | 备选 | `cand-516b76857460caf0f987` | `expressive-input` | 表达性输入 |
| 5 | **主推** | `cand-4ec4a0ef0f7ca0968353` | `skill-ceiling` | 技巧上限 / 深度 |
| 6 | 备选 | `cand-0111602c30f57e3da668` | `novelty-delta` | 新颖增量 |
| 7 | 备选 | `cand-8c4760c48622a0afd11a` | `counterplay-clarity` | 反制清晰度 |

---

## 五、排序与分数（live ranked）

| 名次 | 分数 | 轴中文 | 方向 ID |
|------|------|--------|---------|
| 1 ★ | **93.9** | 技巧上限 / 深度 | `cand-4ec4a0ef0f7ca0968353` |
| 2 | **89.75** | 心流连贯 | `cand-454c80705b38c47e79de` |
| 3 | **89.35** | 瞬时手感 | `cand-73e89d5e86cb1aae60ce` |
| 4 | **88.35** | 表达性输入 | `cand-516b76857460caf0f987` |
| 5 | **88.2** | 新颖增量 | `cand-0111602c30f57e3da668` |
| 6 | **80.5** | 反制清晰度 | `cand-8c4760c48622a0afd11a` |
| 7 | **78.35** | 表现与节拍 | `cand-cbb554a94f57efd5140f` |

### 分数怎么读

- 这是 **本场方向之间的排序分**，用来决定主推，不是「游戏做好了」的分。
- 第 1 名 **93.9**，第 2 名 **89.75**，领先 **4.15**；末名 **78.35**，跨度 **15.55**。
- 与「vs 仅提示词」的 /100 量表不是同一套分；那套在对比文档里。

---

## 六、和仅提示词 AI 的对比（同题）

本场另有 **不加载 ABCD、只丢提示词** 的对照答卷，并用同一 10 维量表打分：

- 分场对比（含仅提示词全文）：[per-case/T-CRE-02.md](../abcd-vs-prompt-only/per-case/T-CRE-02.md)
- 总对比：[abcd-vs-prompt-only/README.md](../abcd-vs-prompt-only/README.md)

人话：仅提示词常写「能开工/能上线」；ABCD 强制多方向 + 设计候选封顶 + 可回执。

---

## 七、建议接着对 AI 说

```text
基于 T-CRE-02（日活玩法循环变体 / 创意模式），主推是「技巧上限 / 深度」。
请用人话：
1) 按主推主题给出可执行方案结构；
2) 用排名第2、第3方向各挑一个风险或备选；
3) 列出我要拍板的3件事；
4) 明确尚未实装、未做 PlayMode/发版验收。
```

## 八、证据字段（审计）

| 字段 | 值 |
|------|-----|
| testId | `T-CRE-02` |
| status | `passed` |
| entryPoint | `Invoke-ESABCModeDivergence+Select-ESABCGenerationCandidate` |
| packageRoot | `F:\aaProject\es-abcd` |
| trialRoot | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite` |
| contractPath | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite\ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json` |
| sourceHash | `329a0dc2e8374e15f3270533ed22553da0c83106fcf9709d29c69f5598d659de` |
| candidateSetHash | `46ee993c36095dd70875b2ba2c18984251d85b73a3261758d2c7b9215f48f0f4` |
| selectedDirectionId | `cand-4ec4a0ef0f7ca0968353` |
| recommendedDirectionId | `cand-4ec4a0ef0f7ca0968353` |
| selectionStatus | `ranked-recommended` |
| selectionPolicy | `rank-after-visible-tree-search` |
| divergenceStatus | `creative-candidate` |
| claimLevel | `design-candidate` |
| runtimeStatus | `runtime-not-run` |
| qualityStatus | `mode-ready` |
| auditDeferred | `True` |
| rejectedCandidatesCount | 0 |
| hiddenCandidatesCount | 1 |
| startedUtc | 2026-09-11T02:35:01.8864526Z |
| finishedUtc | 2026-09-11T02:35:02.1627974Z |
| 回执 JSON | [receipts/T-CRE-02.json](./receipts/T-CRE-02.json) |

---

## 九、导航

- [仓库首页 README](../../README.md)
- [12 场对照表](./COMPARISON-modes-live.md)
- [证据目录](./README.md)
- [vs 仅提示词](../abcd-vs-prompt-only/README.md)

> 禁止手改 cand-* / 分数。复跑场景套件后执行：`powershell -File .\\scripts\\Build-ScenarioHumanReports.ps1`
