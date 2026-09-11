# T-STA-02 · 道具表安全批量导入

> **模式：** 稳定模式 · **状态：通过** · **设计候选** · **运行时未验**  
> 本文是给人看的完整解说 + ABCD 思路链；底部为可核对 live 证据。

---

## 一、这场测试在问什么

| 项 | 内容 |
|----|------|
| 编号 | `T-STA-02` |
| 模式 | **稳定模式** (`stable`) |
| 场景 | **道具表安全批量导入** |
| 为什么测 | 导入要校验、隔离坏行、部分成功，不能炸服炸档。 |
| 你真正想问的 | 稳定模式下，导入规程与失败处理。 |

### 输入给 ABCD 的需求原文

```text
项目 <项目根路径>。用稳定模式。目标：安全导入道具表。要求：校验去重失败隔离部分成功。交付：导入规程。
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
| 主推荐主题 | **可回滚** |
| 主推荐 ID | `cand-92b98548daf46acddb45` |
| 怎么选的 | 按规则**确定一个**主推荐（其余方向仍保留在排名里，供对比） |
| 场内第 1 名排序分 | **83.65** |
| 比第 2 名高出 | **2.15** |
| 第 1 名与末名分差 | **5.3** |
| 质量状态 | `mode-ready` |
| 审计是否后置 | `True` |
| 否决名单条数 | 0（本场主要是选优） |

### AI 解说

主推仍是「可回滚」——导入失败/导错必须可退。

### 你拿结果该做什么

1. 让 AI **按主推荐主题**写成可执行结构（模块、数据、接口、风险）。
2. 用下面排名第 2、第 3 名当备选/挑刺视角。
3. 要求列出你要拍板的 3 件事；并写明 **未实装、未 PlayMode**。
4. 审计时用文末 hash / JSON 核对，禁止手改 cand-*。

---

## 四、全部方向（live）

| # | 角色 | 方向 ID | 轴英文 | 轴中文 |
|---|------|---------|--------|--------|
| 1 | 备选 | `cand-961acdf1f052ea27df94` | `contract-completeness` | 契约 / 配置完备 |
| 2 | 备选 | `cand-8e076879fb40d33a1bd9` | `integration-fit` | 贴合现有集成 |
| 3 | 备选 | `cand-27546e53a3232343e143` | `compatibility` | 兼容性 |
| 4 | 备选 | `cand-bba51b6aa656921498a8` | `regression-fixture` | 回归夹具 |
| 5 | **主推** | `cand-92b98548daf46acddb45` | `rollback` | 可回滚 |

---

## 五、排序与分数（live ranked）

| 名次 | 分数 | 轴中文 | 方向 ID |
|------|------|--------|---------|
| 1 ★ | **83.65** | 可回滚 | `cand-92b98548daf46acddb45` |
| 2 | **81.5** | 兼容性 | `cand-27546e53a3232343e143` |
| 3 | **80** | 贴合现有集成 | `cand-8e076879fb40d33a1bd9` |
| 4 | **79.6** | 回归夹具 | `cand-bba51b6aa656921498a8` |
| 5 | **78.35** | 契约 / 配置完备 | `cand-961acdf1f052ea27df94` |

### 分数怎么读

- 这是 **本场方向之间的排序分**，用来决定主推，不是「游戏做好了」的分。
- 第 1 名 **83.65**，第 2 名 **81.5**，领先 **2.15**；末名 **78.35**，跨度 **5.3**。
- 与「vs 仅提示词」的 /100 量表不是同一套分；那套在对比文档里。

---

## 六、和仅提示词 AI 的对比（同题）

本场另有 **不加载 ABCD、只丢提示词** 的对照答卷，并用同一 10 维量表打分：

- 分场对比（含仅提示词全文）：[per-case/T-STA-02.md](../abcd-vs-prompt-only/per-case/T-STA-02.md)
- 总对比：[abcd-vs-prompt-only/README.md](../abcd-vs-prompt-only/README.md)

人话：仅提示词常写「能开工/能上线」；ABCD 强制多方向 + 设计候选封顶 + 可回执。

---

## 七、建议接着对 AI 说

```text
基于 T-STA-02（道具表安全批量导入 / 稳定模式），主推是「可回滚」。
请用人话：
1) 按主推主题给出可执行方案结构；
2) 用排名第2、第3方向各挑一个风险或备选；
3) 列出我要拍板的3件事；
4) 明确尚未实装、未做 PlayMode/发版验收。
```

## 八、证据字段（审计）

| 字段 | 值 |
|------|-----|
| testId | `T-STA-02` |
| status | `passed` |
| entryPoint | `Invoke-ESABCModeDivergence+Select-ESABCGenerationCandidate` |
| packageRoot | `F:\aaProject\es-abcd` |
| trialRoot | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite` |
| contractPath | `C:\Users\asus\AppData\Local\Temp\es-abcd-goal-scenario-suite\ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json` |
| sourceHash | `329a0dc2e8374e15f3270533ed22553da0c83106fcf9709d29c69f5598d659de` |
| candidateSetHash | `574ea1789eecefb4ac5199b6ebcbc60c675035b8179d2f91d33334f195b7ba04` |
| selectedDirectionId | `cand-92b98548daf46acddb45` |
| recommendedDirectionId | `cand-92b98548daf46acddb45` |
| selectionStatus | `deterministic-selected` |
| selectionPolicy | `deterministic-ranked-after-visible-tree-search` |
| divergenceStatus | `stable-candidate` |
| claimLevel | `design-candidate` |
| runtimeStatus | `runtime-not-run` |
| qualityStatus | `mode-ready` |
| auditDeferred | `True` |
| rejectedCandidatesCount | 0 |
| hiddenCandidatesCount | 1 |
| startedUtc | 2026-09-11T02:35:02.8651206Z |
| finishedUtc | 2026-09-11T02:35:03.0327941Z |
| 回执 JSON | [receipts/T-STA-02.json](./receipts/T-STA-02.json) |

---

## 九、导航

- [仓库首页 README](../../README.md)
- [12 场对照表](./COMPARISON-modes-live.md)
- [证据目录](./README.md)
- [vs 仅提示词](../abcd-vs-prompt-only/README.md)

> 禁止手改 cand-* / 分数。复跑场景套件后执行：`powershell -File .\\scripts\\Build-ScenarioHumanReports.ps1`
