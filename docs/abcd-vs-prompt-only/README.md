# ABCD 实跑 vs 仅提示词 AI · 全维度对比

> 面向用户阅读。数字来自 **真实 ABCD Divergence/Select 回执** + **未调用 ABCD 的提示词对照答卷** + **同一套 10 维量表**。
>
> 生成 UTC: 2026-09-11T02:51:19.0677098Z

## 一句话结论

12 场同题对比（**过程偏重量表 · 弱提示词对照**）：ABCD 平均 **85.33**/100，仅提示词平均 **41.42**/100，平均差值 **+43.91**（ABCD − 仅提示词）。

ABCD 多出来的分，主要来自 **过程栏**：**多方向强制发散、模式轴贴合、结构可核对、设计候选/运行时未验的诚实封顶**；不是「文笔更华丽」，也**不是**「内容栏全面碾压任意 AI」。

### 双栏读法（必读）

| 栏 | 含义 | 本仓库 12 场证据能说明什么 |
|----|------|---------------------------|
| **过程栏** | 发散、claim、hash、可复核结构、不夸大上线 | 弱对照下 ABCD 明显更高（上表） |
| **内容栏** | 领域槽位覆盖、可写稿深度、业务贴合 | **不保证碾压**；更强纯 AI 写稿可打平/反超；勿用弱样本当唯一 wipeout 叙事 |

默认交付是 **`deliveryKind=lens-only` / `pipelineLevel=L0`**（透镜排序）。识别到 live-ops 等已接线领域时才升 **`domain-brief` / L1**。

## 对比怎么做的（避免自嗨）

| 臂 | 怎么跑 | 输入 |
|----|--------|------|
| **ABCD** | 已落盘 live：`Invoke-ESABCModeDivergence` + `Select-ESABCGenerationCandidate` | 与套件相同的场景需求 |
| **仅提示词** | **不** Import 任何 ABCD 模块；只根据需求写一版自由答（典型「能开工」聊天风） | 同一场景意图 |
| **量表** | 两边同一 10 维 0–10，合计 /100；规则写在脚本里可复跑 | — |

仅提示词答卷路径：构建机 `prompt-only-answers/`（构建日志）；仓库 per-case 文内嵌全文。

## 总表（一眼看）

| 编号 | 场景 | 模式 | ABCD主推 | ABCD场内第1分 | 量表ABCD | 量表仅提示词 | 差值 |
|------|------|------|----------|---------------|----------|--------------|------|
| [T-ENG-01](./per-case/T-ENG-01.md) | 设计技能系统 | 工程 | 状态机/流程 | 87.5 | **88** | 49 | **+39** |
| [T-ENG-02](./per-case/T-ENG-02.md) | 成长与经济 | 工程 | 状态机/流程 | 88.65 | **86** | 37 | **+49** |
| [T-ENG-03](./per-case/T-ENG-03.md) | 批量道具管线 | 工程 | 性能预算 | 90.8 | **86** | 49 | **+37** |
| [T-ENG-04](./per-case/T-ENG-04.md) | 战斗结算闭环 | 工程 | 失败恢复 | 89.9 | **88** | 44 | **+44** |
| [T-CRE-01](./per-case/T-CRE-01.md) | 近战技能手感 | 创意 | 表现节拍 | 85.5 | **82** | 48 | **+34** |
| [T-CRE-02](./per-case/T-CRE-02.md) | 日活玩法循环 | 创意 | 技巧上限 | 93.9 | **82** | 46 | **+36** |
| [T-CRE-03](./per-case/T-CRE-03.md) | 道具品类矩阵 | 创意 | 心流 | 95.75 | **82** | 33 | **+49** |
| [T-CRE-04](./per-case/T-CRE-04.md) | Boss战花样 | 创意 | 心流 | 92.3 | **82** | 41 | **+41** |
| [T-STA-01](./per-case/T-STA-01.md) | 技能表安全扩展 | 稳定 | 回滚 | 85.65 | **87** | 38 | **+49** |
| [T-STA-02](./per-case/T-STA-02.md) | 道具批量导入 | 稳定 | 回滚 | 83.65 | **87** | 37 | **+50** |
| [T-STA-03](./per-case/T-STA-03.md) | 活动开关配置 | 稳定 | 集成贴合 | 90.75 | **87** | 37 | **+50** |
| [T-STA-04](./per-case/T-STA-04.md) | 老关卡修bug不毁档 | 稳定 | 兼容 | 88.1 | **87** | 38 | **+49** |

| **平均** | — | — | — | — | **85.33** | **41.42** | **+43.91** |

## 分维平均（12 场）

| 维度 | ABCD均分 | 仅提示词均分 | 差值 |
|------|----------|--------------|------|
| 多方案发散 | 8.67 | 3.92 | 4.75 |
| 模式贴合 | 9 | 6 | 3 |
| 边界/所有权 | 7.33 | 4.67 | 2.66 |
| 失败/回滚 | 7.33 | 3.17 | 4.16 |
| 诚实不夸大 | 10 | 1.83 | 8.17 |
| 可执行性 | 8 | 4.83 | 3.17 |
| 风险覆盖 | 8 | 5.42 | 2.58 |
| 结构清晰 | 9 | 4.5 | 4.5 |
| 可验证性 | 9 | 2.92 | 6.08 |
| 一致性/少空话 | 9 | 4.17 | 4.83 |

## 按模式汇总

### 工程
- 场次: 4
- ABCD 平均: **87** / 仅提示词平均: **44.75** / 差: **+42.25**

### 创意
- 场次: 4
- ABCD 平均: **82** / 仅提示词平均: **42** / 差: **+40**

### 稳定
- 场次: 4
- ABCD 平均: **87** / 仅提示词平均: **37.5** / 差: **+49.5**

## 说明（避免误解）

1. **场内第1分**（约 83–96）是 ABCD 在多方向里的排序分，和 **量表 /100** 不是同一套分数。
2. 仅提示词样本代表「无模式机器、无 claim 封顶、常写能开工/能上线」的**弱对照**聊天输出；不是攻击某具体厂商模型，也**不能**单独证明「全面碾压任意 AI」。
3. 两边都未替代 Unity PlayMode；ABCD 侧明确 runtime-not-run；默认多为 L0 lens-only，L1 domain-brief 仅已接线领域。
4. 外部反馈中更强 plain-AI 臂在内容覆盖上可能 ~77 vs ABCD ~73：请按**双栏**读，不要把过程分当成内容垄断。

## 证据索引

| 编号 | 分场对比 | ABCD报告 | ABCD回执 |
|------|----------|----------|----------|
| T-ENG-01 | [对比](./per-case/T-ENG-01.md) | [md](../scenario-run-reports/T-ENG-01.md) | [json](../scenario-run-reports/receipts/T-ENG-01.json) |
| T-ENG-02 | [对比](./per-case/T-ENG-02.md) | [md](../scenario-run-reports/T-ENG-02.md) | [json](../scenario-run-reports/receipts/T-ENG-02.json) |
| T-ENG-03 | [对比](./per-case/T-ENG-03.md) | [md](../scenario-run-reports/T-ENG-03.md) | [json](../scenario-run-reports/receipts/T-ENG-03.json) |
| T-ENG-04 | [对比](./per-case/T-ENG-04.md) | [md](../scenario-run-reports/T-ENG-04.md) | [json](../scenario-run-reports/receipts/T-ENG-04.json) |
| T-CRE-01 | [对比](./per-case/T-CRE-01.md) | [md](../scenario-run-reports/T-CRE-01.md) | [json](../scenario-run-reports/receipts/T-CRE-01.json) |
| T-CRE-02 | [对比](./per-case/T-CRE-02.md) | [md](../scenario-run-reports/T-CRE-02.md) | [json](../scenario-run-reports/receipts/T-CRE-02.json) |
| T-CRE-03 | [对比](./per-case/T-CRE-03.md) | [md](../scenario-run-reports/T-CRE-03.md) | [json](../scenario-run-reports/receipts/T-CRE-03.json) |
| T-CRE-04 | [对比](./per-case/T-CRE-04.md) | [md](../scenario-run-reports/T-CRE-04.md) | [json](../scenario-run-reports/receipts/T-CRE-04.json) |
| T-STA-01 | [对比](./per-case/T-STA-01.md) | [md](../scenario-run-reports/T-STA-01.md) | [json](../scenario-run-reports/receipts/T-STA-01.json) |
| T-STA-02 | [对比](./per-case/T-STA-02.md) | [md](../scenario-run-reports/T-STA-02.md) | [json](../scenario-run-reports/receipts/T-STA-02.json) |
| T-STA-03 | [对比](./per-case/T-STA-03.md) | [md](../scenario-run-reports/T-STA-03.md) | [json](../scenario-run-reports/receipts/T-STA-03.json) |
| T-STA-04 | [对比](./per-case/T-STA-04.md) | [md](../scenario-run-reports/T-STA-04.md) | [json](../scenario-run-reports/receipts/T-STA-04.json) |

复跑 ABCD 场景：`scripts/Run-ESABCDScenarioReportSuite.ps1`  
复跑本对比：`（本构建脚本在 CI/本地 scratch，对比结果已写入 docs/abcd-vs-prompt-only/）` 
