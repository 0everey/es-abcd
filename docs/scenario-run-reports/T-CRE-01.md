# T-CRE-01 · 近战爆发技能手感发散

> **模式：** 创意模式 · **状态：通过** · **设计候选** · **运行时未验**  
> 本文是给人看的完整解说 + ABCD 思路链；底部为可核对 live 证据。

---

## 一、这场测试在问什么

| 项 | 内容 |
|----|------|
| 编号 | `T-CRE-01` |
| 模式 | **创意模式** (`creative-divergence`) |
| 场景 | **近战爆发技能手感发散** |
| 为什么测 | 要的是多种手感差异，不是微调同一套砍击。 |
| 你真正想问的 | 创意模式下，至少多种手感方向，各有卖点与硬伤。 |

### 输入给 ABCD 的需求原文

```text
项目 <项目根路径>。用创意模式。目标：为近战爆发技能给出至少5种不同手感方向。要求：差异大；每方案卖点+硬伤。交付：多方案列表+尝试顺序。
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
| 主推荐主题 | **表现与节拍** |
| 主推荐 ID | `cand-f28fe0d72897a6ff69be` |
| 怎么选的 | 先排序再**推荐第一**（创意常见；第二名及以后仍可讨论） |
| 场内第 1 名排序分 | **85.5** |
| 比第 2 名高出 | **3.6** |
| 第 1 名与末名分差 | **10.15** |
| 质量状态 | `mode-ready` |
| 审计是否后置 | `True` |
| 否决名单条数 | 0（本场主要是选优） |

### AI 解说

主推「表现与节拍」：手感讨论里演出节奏被排到第一，瞬时手感、反制等仍在榜可对比。

**分差提醒：** 主推领先较明显（+3.6），可先沿主推深化，再扫排名 2–3 名挑刺。

### 你拿结果该做什么

1. 让 AI **按主推荐主题**写成可执行结构（模块、数据、接口、风险）。
2. 用下面排名第 2、第 3 名当备选/挑刺视角。
3. 要求列出你要拍板的 3 件事；并写明 **未实装、未 PlayMode**。
4. 审计时用文末 hash / JSON 核对，禁止手改 cand-*。

---

## 四、全部方向（live）

| # | 角色 | 方向 ID | 轴英文 | 轴中文 |
|---|------|---------|--------|--------|
| 1 | 备选 | `cand-a211f25bc06864c805f0` | `moment-to-moment-feel` | 瞬时手感 |
| 2 | 备选 | `cand-f8e0a3b0df78b3a12e66` | `flow-continuity` | 心流连贯 |
| 3 | **主推** | `cand-f28fe0d72897a6ff69be` | `presentation-beat` | 表现与节拍 |
| 4 | 备选 | `cand-851106fd106bf9538b5b` | `expressive-input` | 表达性输入 |
| 5 | 备选 | `cand-23eef324389e695e2431` | `skill-ceiling` | 技巧上限 / 深度 |
| 6 | 备选 | `cand-0750e804561ab101bfeb` | `novelty-delta` | 新颖增量 |
| 7 | 备选 | `cand-d55c66e5464302c85bc3` | `counterplay-clarity` | 反制清晰度 |

---

## 五、排序与分数（live ranked）

| 名次 | 分数 | 轴中文 | 方向 ID |
|------|------|--------|---------|
| 1 ★ | **85.5** | 表现与节拍 | `cand-f28fe0d72897a6ff69be` |
| 2 | **81.9** | 瞬时手感 | `cand-a211f25bc06864c805f0` |
| 3 | **81.75** | 反制清晰度 | `cand-d55c66e5464302c85bc3` |
| 4 | **80.95** | 新颖增量 | `cand-0750e804561ab101bfeb` |
| 5 | **80.05** | 表达性输入 | `cand-851106fd106bf9538b5b` |
| 6 | **75.6** | 技巧上限 / 深度 | `cand-23eef324389e695e2431` |
| 7 | **75.35** | 心流连贯 | `cand-f8e0a3b0df78b3a12e66` |

### 分数怎么读

- 这是 **本场方向之间的排序分**，用来决定主推，不是「游戏做好了」的分。
- 第 1 名 **85.5**，第 2 名 **81.9**，领先 **3.6**；末名 **75.35**，跨度 **10.15**。
- 与「vs 仅提示词」的 /100 量表不是同一套分；那套在对比文档里。

---

## 六、和仅提示词 AI 的对比（同题）

本场另有 **不加载 ABCD、只丢提示词** 的对照答卷，并用同一 10 维量表打分：

- 分场对比（含仅提示词全文）：[per-case/T-CRE-01.md](../abcd-vs-prompt-only/per-case/T-CRE-01.md)
- 总对比：[abcd-vs-prompt-only/README.md](../abcd-vs-prompt-only/README.md)

人话：仅提示词常写「能开工/能上线」；ABCD 强制多方向 + 设计候选封顶 + 可回执。

---

## 七、建议接着对 AI 说

```text
基于 T-CRE-01（近战爆发技能手感发散 / 创意模式），主推是「表现与节拍」。
请用人话：
1) 按主推主题给出可执行方案结构；
2) 用排名第2、第3方向各挑一个风险或备选；
3) 列出我要拍板的3件事；
4) 明确尚未实装、未做 PlayMode/发版验收。
```

## 八、证据字段（审计）

| 字段 | 值 |
|------|-----|
| testId | `T-CRE-01` |
| status | `passed` |
| entryPoint | `Invoke-ESABCModeDivergence+Select-ESABCGenerationCandidate` |
| packageRoot | `F:\aaProject\es-abcd` |
| trialRoot | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite` |
| contractPath | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite\ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json` |
| sourceHash | `329a0dc2e8374e15f3270533ed22553da0c83106fcf9709d29c69f5598d659de` |
| candidateSetHash | `eff3ec1d6173ee0178e8accf5798a7c57c64c1cfe41113af7e08995ee6836b18` |
| selectedDirectionId | `cand-f28fe0d72897a6ff69be` |
| recommendedDirectionId | `cand-f28fe0d72897a6ff69be` |
| selectionStatus | `ranked-recommended` |
| selectionPolicy | `rank-after-visible-tree-search` |
| divergenceStatus | `creative-candidate` |
| claimLevel | `design-candidate` |
| runtimeStatus | `runtime-not-run` |
| qualityStatus | `mode-ready` |
| auditDeferred | `True` |
| rejectedCandidatesCount | 0 |
| hiddenCandidatesCount | 1 |
| startedUtc | 2026-09-11T02:35:01.6211598Z |
| finishedUtc | 2026-09-11T02:35:01.8700173Z |
| 回执 JSON | [receipts/T-CRE-01.json](./receipts/T-CRE-01.json) |

---

## 九、导航

- [仓库首页 README](../../README.md)
- [12 场对照表](./COMPARISON-modes-live.md)
- [证据目录](./README.md)
- [vs 仅提示词](../abcd-vs-prompt-only/README.md)

> 禁止手改 cand-* / 分数。复跑场景套件后执行：`powershell -File .\\scripts\\Build-ScenarioHumanReports.ps1`
