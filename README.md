# es-abcd

**跟 AI 一起做系统设计时用的协作工具。** 本页即可完整预览：怎么用、会得到什么、每种模式的真实场景与实测结果。

不是游戏引擎 · 不必先装旧 ES · 路径请用你自己的绝对路径

**版本 1.0.0** · [Release](https://github.com/0everey/es-abcd/releases/tag/v1.0.0) · MIT

> 下方「本场实测」数字均来自仓库内 live 回执（`docs/scenario-run-reports/receipts/`），**不是编的**。文末可点开完整证据。

---

## 1. 一分钟看懂

| 你要做的事 | 选模式 | 实测常见表现 |
|------------|--------|--------------|
| 把系统**做对**（技能/经济/管线/战斗） | **工程** | 约 **5** 向，**定一个**主推荐 |
| 要**多方案**（手感/循环/品类/Boss） | **创意** | 约 **7** 向，**排序推荐**第一 |
| **别翻车**（扩表/导入/活动/修关） | **稳定** | 约 **5** 向，**定一个**偏兼容/回滚 |

**成功** = 装上了 + AI 给出可讨论方案 + 能对上证据。  
**不等于** 编辑器已玩通 / 已平衡 / 可发版。全部 live 均为 **设计候选** + **运行时未验**。

### 交付层级（必读，避免把透镜当领域方案）

| 字段 | 含义 |
|------|------|
| `pipelineLevel=L0` / `deliveryKind=lens-only` | 默认停点：多轴透镜排序与 claim 封顶，**不是**闭合领域简报 |
| `pipelineLevel=L1` / `deliveryKind=domain-brief` | 识别到领域（如日活 live-ops）后产出槽位齐全的领域简报 |
| `templateCollision` | 多候选正文模板完全相同时会诚实降级 claim 或 fail-closed，不会 silently 当成差异方案 |

读回执时**必须先看** `deliveryKind` / `pipelineLevel`，再谈内容好坏。

### 双栏诚实评分（过程 vs 内容）

| 栏 | 量什么 | ABCD 默认强项 | 说明 |
|----|--------|---------------|------|
| **过程栏** | 多向发散、模式轴、hash/claim、可复核结构、不夸大 | 通常明显 | 体系强制：方向数、选择状态、runtime-not-run |
| **内容栏** | 领域槽位覆盖、可写稿深度、是否贴业务 | **不保证碾压** | 强提示词 / 领域熟手模型可在内容栏打平或反超；弱对照样本不能当「全面碾压任意 AI」唯一证据 |

当前 **商用默认** 会尽量给出 **L1 可讨论方案卡**（轴差异化正文 + 领域槽位/手感卡）；读回执仍以 `deliveryKind` / `pipelineLevel` 为准。这不是「万能内容生成器」，也不是已平衡可发版。

### 商用一键（推荐）

装好后在项目根：

```powershell
. .\ES\Automation\ABCD\Use-ESABCD.ps1
# 写出中文 Markdown 简报 + JSON（out/commercial-brief-*.md）
Invoke-ESABCDCommercialBrief -Requirement '采集-合成-战备-出击 五条日活循环，硬核/休闲/社交' -Mode creative-divergence
# 或
Invoke-ESABCDQuick -Requirement '近战爆发技能手感，至少5向' -Mode creative-divergence -Commercial
```

你会得到：

| 产物 | 用途 |
|------|------|
| `commercial-brief-*.md` | 给人读的方案简报（需求、领域表/方案卡、透镜排序、主推荐展开） |
| `commercial-brief-*.json` | 机器回执（deliveryKind、domainBrief、rankedSummaries） |

**商用成功** = 有简报文件 + `deliveryKind` 可读 + claim 仍是设计候选。  
**不需要**先跑仓库里那一大坨 `Test-*.ps1`（安装时已默认不拷贝，只保留冒烟必需的两项静态检查）。

---

## 2. 完整使用流程

```text
① 两个真实路径：es-abcd 根 + 项目根
② 安装（对 AI 说 或 跑试验脚本）
③ 看清单，确认装上了
④ 复制本页某一场景（改路径）发给 AI
⑤ 听人话方案；需要时点文末证据核对
```

### 安装话术

```text
es-abcd 在 <es-abcd根路径>，装到项目 <项目根路径>，
先分析项目再按情况接入，出适配清单，用人话汇报。
```

### 本机试验

```powershell
powershell -File .\scripts\Start-ESABCDTrial.ps1
```

装好后应看到：`项目/ES/Automation/ABCD/out/adapt-checklist-*.md` 等。只有聊天没有清单 = 没装上。

### 结果怎么读

| 词 | 人话 |
|----|------|
| 通过 | 这场编排跑通了 |
| 方向数 5 / 7 | 给了几条思考主轴 |
| 主推荐主题 | 默认讨论焦点（见下表中文） |
| 定一个 / 排序推荐 | 工程稳定定一个；创意先排再荐 |
| deliveryKind / pipelineLevel | **L0 lens-only** = 透镜排序；**L1 domain-brief** = 领域槽位简报 |
| 设计候选 | 只能讨论，不是定案上线 |
| 运行时未验 | 没做编辑器/真机验收 |
| 其它方向 | 落选推荐，不是判死刑 |

---

## 3. 本批 live 一览（一眼看懂）

| 编号 | 模式 | 场景 | 方向数 | 主推荐（人话） | 怎么选的 | 级别 |
|------|------|------|--------|----------------|----------|------|
| [T-ENG-01 完整解说](./docs/scenario-run-reports/T-ENG-01.md) | 工程 | 设计技能系统 | **5** | **状态机/流程严谨性** | 按规则定一个主推荐 | 设计候选 · 运行时未验 |
| [T-ENG-02 完整解说](./docs/scenario-run-reports/T-ENG-02.md) | 工程 | 成长与经济 | **5** | **状态机/流程严谨性** | 按规则定一个主推荐 | 设计候选 · 运行时未验 |
| [T-ENG-03 完整解说](./docs/scenario-run-reports/T-ENG-03.md) | 工程 | 批量道具管线 | **5** | **性能峰值预算** | 按规则定一个主推荐 | 设计候选 · 运行时未验 |
| [T-ENG-04 完整解说](./docs/scenario-run-reports/T-ENG-04.md) | 工程 | 战斗结算闭环 | **5** | **失败恢复** | 按规则定一个主推荐 | 设计候选 · 运行时未验 |
| [T-CRE-01 完整解说](./docs/scenario-run-reports/T-CRE-01.md) | 创意 | 近战技能手感发散 | **7** | **表现与节拍** | 排序后推荐第一（其余仍可看） | 设计候选 · 运行时未验 |
| [T-CRE-02 完整解说](./docs/scenario-run-reports/T-CRE-02.md) | 创意 | 日活玩法循环 | **7** | **技巧上限** | 排序后推荐第一（其余仍可看） | 设计候选 · 运行时未验 |
| [T-CRE-03 完整解说](./docs/scenario-run-reports/T-CRE-03.md) | 创意 | 道具品类矩阵 | **7** | **心流连贯** | 排序后推荐第一（其余仍可看） | 设计候选 · 运行时未验 |
| [T-CRE-04 完整解说](./docs/scenario-run-reports/T-CRE-04.md) | 创意 | Boss 战花样 | **7** | **心流连贯** | 排序后推荐第一（其余仍可看） | 设计候选 · 运行时未验 |
| [T-STA-01 完整解说](./docs/scenario-run-reports/T-STA-01.md) | 稳定 | 技能表安全扩展 | **5** | **可回滚** | 按规则定一个主推荐 | 设计候选 · 运行时未验 |
| [T-STA-02 完整解说](./docs/scenario-run-reports/T-STA-02.md) | 稳定 | 道具批量导入 | **5** | **可回滚** | 按规则定一个主推荐 | 设计候选 · 运行时未验 |
| [T-STA-03 完整解说](./docs/scenario-run-reports/T-STA-03.md) | 稳定 | 活动开关配置 | **5** | **贴合现有集成** | 按规则定一个主推荐 | 设计候选 · 运行时未验 |
| [T-STA-04 完整解说](./docs/scenario-run-reports/T-STA-04.md) | 稳定 | 老关卡修 bug 不毁档 | **5** | **兼容性** | 按规则定一个主推荐 | 设计候选 · 运行时未验 |

同一批 12 场 **全部通过**。证据对照表：[COMPARISON-modes-live.md](./docs/scenario-run-reports/COMPARISON-modes-live.md)

---

## 3.5 ABCD vs 仅提示词 · 全维度对比（真实同题）

**问题：** 不用这套体系、只丢提示词给 AI，和接上 ABCD 差在哪？

**怎么比（可复跑）：**

| 臂 | 做法 |
|----|------|
| ABCD | live `Divergence + Select` 回执（上表 12 场） |
| 仅提示词 | **不**加载任何 ABCD 模块，同题写一版「能开工」聊天风答卷 |
| 量表 | 同一 10 维（各 0–10，合计 /100），规则在脚本里 |

**总结果（12 场 · 过程偏重量表 · 弱提示词对照）：**

| | 分数 /100 |
|--|-----------|
| **ABCD** | **85.33** |
| **仅提示词（弱对照样本）** | **41.42** |
| **差值（ABCD − 仅提示词）** | **+43.91** |

这组数字量的是 **过程栏**（结构、claim、可验证、多向）为主；**不是**「内容栏碾压任意强 AI」的证明。

**分模式平均差值：** 工程约 +42 · 创意约 +40 · 稳定约 **+49.5**（稳定拉开最大）

**分维上 ABCD 多出来的，主要不是文笔，而是过程纪律：**

| 维度 | ABCD均 | 仅提示词均 | 差 |
|------|--------|------------|-----|
| 诚实不夸大 | 10 | 1.83 | **+8.2** |
| 可验证性 | 9 | 2.92 | **+6.1** |
| 多方案发散 | 8.67 | 3.92 | **+4.8** |
| 结构清晰 | 9 | 4.5 | **+4.5** |
| 失败/回滚 | 7.33 | 3.17 | **+4.2** |
| 一致性/少空话 | 9 | 4.17 | **+4.8** |

**单场量表差值（ABCD 高多少 · 仍属弱对照）：**

| 场景 | 差值 | 场景 | 差值 |
|------|------|------|------|
| 技能系统 | +39 | 近战手感 | +34 |
| 成长经济 | +49 | 日活循环 | +36 |
| 道具管线 | +37 | 品类矩阵 | +49 |
| 战斗闭环 | +44 | Boss 战法 | +41 |
| 技能表扩展 | +49 | 道具导入 | **+50** |
| 活动开关 | **+50** | 修关不毁档 | +49 |

完整分场答卷 + 10 维表 + 证据链 → **[docs/abcd-vs-prompt-only/README.md](./docs/abcd-vs-prompt-only/README.md)**  
复跑对比：`powershell -File .\scripts\Build-AbcdVsPromptOnlyComparison.ps1`

> **诚实边界：**  
> 1) 仅提示词臂是「无 ABCD 模块的弱对照答卷」（脚本固化、可复跑），用来量「有没有这套过程纪律」；**不是**云厂商模型排行榜，也**不能**单独推出「全面碾压任意 AI」。  
> 2) 外部更强的纯 AI 写稿在 **内容覆盖** 上可能接近甚至反超 ABCD；ABCD 的护城河是过程栏 + L0/L1 交付声明，不是文笔垄断。  
> 3) 两边都未替代 Unity PlayMode；默认 live 多为 **L0 lens-only**，日活等已接线域才到 **L1 domain-brief**。

---

## 4. 工程模式 · 典型场景（可复制 + 本场实测）

适合：边界清楚、能落地。实测：**5 向 · 定一个主推荐**。

### 场景 1 · 设计技能系统

**本场实测（live）** · 证据 [T-ENG-01 完整解说](./docs/scenario-run-reports/T-ENG-01.md) · 回执 [json](./docs/scenario-run-reports/receipts/T-ENG-01.json)

- 状态：**通过**
- 方向数：**5**
- 主推荐：**状态机/流程严谨性**（`state-machine-integrity`）
- 选择方式：**按规则定一个主推荐**
- 级别：设计候选 · 运行时未验
- 你该得到：技能生命周期、模块边界、和战斗怎么接、禁止双系统

**复制发给 AI（改路径）：**

```text
项目 <项目根路径>。用工程模式。目标：设计一套可扩展的技能系统（主动/被动/冷却/消耗/等级）。要求：说清模块边界、数据归谁管、和战斗结算怎么接、禁止两套技能并行。交付：方案要点 + 风险 + 还不能宣称已实装/已平衡。
用人话讲，不要只丢英文轴名。
```

### 场景 2 · 成长与经济

**本场实测（live）** · 证据 [T-ENG-02 完整解说](./docs/scenario-run-reports/T-ENG-02.md) · 回执 [json](./docs/scenario-run-reports/receipts/T-ENG-02.json)

- 状态：**通过**
- 方向数：**5**
- 主推荐：**状态机/流程严谨性**（`state-machine-integrity`）
- 选择方式：**按规则定一个主推荐**
- 级别：设计候选 · 运行时未验
- 你该得到：经验/金币/商店/掉落的所有权、防刷、存档边界

**复制发给 AI（改路径）：**

```text
项目 <项目根路径>。用工程模式。目标：设计角色成长与货币经济（经验、金币、商店、掉落）。要求：所有权、防刷、存档边界、任务奖励统一。交付：结构 + 失败案例 + 未验证项。
用人话讲，不要只丢英文轴名。
```

### 场景 3 · 批量道具管线

**本场实测（live）** · 证据 [T-ENG-03 完整解说](./docs/scenario-run-reports/T-ENG-03.md) · 回执 [json](./docs/scenario-run-reports/receipts/T-ENG-03.json)

- 状态：**通过**
- 方向数：**5**
- 主推荐：**性能峰值预算**（`performance-peak-budget`）
- 选择方式：**按规则定一个主推荐**
- 级别：设计候选 · 运行时未验
- 你该得到：模板→校验→入库的正式入口，禁旁路

**复制发给 AI（改路径）：**

```text
项目 <项目根路径>。用工程模式。目标：建立大量道具制作与入库管线（模板、命名、表字段、校验、批量生成）。要求：一条正式入口、禁止旁路、坏数据拒绝。交付：管线步骤 + 验收标准。
用人话讲，不要只丢英文轴名。
```

### 场景 4 · 战斗结算闭环

**本场实测（live）** · 证据 [T-ENG-04 完整解说](./docs/scenario-run-reports/T-ENG-04.md) · 回执 [json](./docs/scenario-run-reports/receipts/T-ENG-04.json)

- 状态：**通过**
- 方向数：**5**
- 主推荐：**失败恢复**（`failure-recovery`）
- 选择方式：**按规则定一个主推荐**
- 级别：设计候选 · 运行时未验
- 你该得到：攻击→命中→伤害→死亡→复用，唯一入口

**复制发给 AI（改路径）：**

```text
项目 <项目根路径>。用工程模式。目标：收口攻击到命中到伤害到死亡到复用的唯一闭环。要求：唯一入口、禁旁路扣血、重复命中策略、池化重置。交付：链路 + 缺口 + 运行时未验。
用人话讲，不要只丢英文轴名。
```

---

## 5. 创意模式 · 典型场景（可复制 + 本场实测）

适合：多方案、差异大。实测：**7 向 · 排序推荐第一**。

### 场景 1 · 近战技能手感发散

**本场实测（live）** · 证据 [T-CRE-01 完整解说](./docs/scenario-run-reports/T-CRE-01.md) · 回执 [json](./docs/scenario-run-reports/receipts/T-CRE-01.json)

- 状态：**通过**
- 方向数：**7**
- 主推荐：**表现与节拍**（`presentation-beat`）
- 选择方式：**排序后推荐第一（其余仍可看）**
- 级别：设计候选 · 运行时未验
- 你该得到：多种手感方向：节奏/风险/反制/表现

**复制发给 AI（改路径）：**

```text
项目 <项目根路径>。用创意模式。目标：为近战爆发技能给出至少5种不同手感方向。要求：差异大；每方案卖点+硬伤。交付：多方案列表+尝试顺序。
用人话讲。
```

### 场景 2 · 日活玩法循环

**本场实测（live）** · 证据 [T-CRE-02 完整解说](./docs/scenario-run-reports/T-CRE-02.md) · 回执 [json](./docs/scenario-run-reports/receipts/T-CRE-02.json)

- 状态：**通过**
- 方向数：**7**
- 主推荐：**技巧上限**（`skill-ceiling`）
- 选择方式：**排序后推荐第一（其余仍可看）**
- 级别：设计候选 · 运行时未验
- 你该得到：采集—合成—战备—出击的多种循环变体

**复制发给 AI（改路径）：**

```text
项目 <项目根路径>。用创意模式。目标：采集-合成-战备-出击的5种日活循环。要求：硬核/休闲/社交；吸引谁烦谁。交付：5循环。
用人话讲。
```

### 场景 3 · 道具品类矩阵

**本场实测（live）** · 证据 [T-CRE-03 完整解说](./docs/scenario-run-reports/T-CRE-03.md) · 回执 [json](./docs/scenario-run-reports/receipts/T-CRE-03.json)

- 状态：**通过**
- 方向数：**7**
- 主推荐：**心流连贯**（`flow-continuity`）
- 选择方式：**排序后推荐第一（其余仍可看）**
- 级别：设计候选 · 运行时未验
- 你该得到：不改底层背包的多套品类结构

**复制发给 AI（改路径）：**

```text
项目 <项目根路径>。用创意模式。目标：5套道具品类矩阵（不改底层背包）。要求：命名、稀有度、经济钩子。交付：5矩阵+样例建议。
用人话讲。
```

### 场景 4 · Boss 战花样

**本场实测（live）** · 证据 [T-CRE-04 完整解说](./docs/scenario-run-reports/T-CRE-04.md) · 回执 [json](./docs/scenario-run-reports/receipts/T-CRE-04.json)

- 状态：**通过**
- 方向数：**7**
- 主推荐：**心流连贯**（`flow-continuity`）
- 选择方式：**排序后推荐第一（其余仍可看）**
- 级别：设计候选 · 运行时未验
- 你该得到：同一 Boss 多种战法定位

**复制发给 AI（改路径）：**

```text
项目 <项目根路径>。用创意模式。目标：同一Boss五种战法。要求：机制/叙事/解谜/配队/Roguelike。交付：5战法卡。
用人话讲。
```

---

## 6. 稳定模式 · 典型场景（可复制 + 本场实测）

适合：贴现状、少翻车。实测：**5 向 · 定一个主推荐（常偏回滚/兼容）**。

### 场景 1 · 技能表安全扩展

**本场实测（live）** · 证据 [T-STA-01 完整解说](./docs/scenario-run-reports/T-STA-01.md) · 回执 [json](./docs/scenario-run-reports/receipts/T-STA-01.json)

- 状态：**通过**
- 方向数：**5**
- 主推荐：**可回滚**（`rollback`）
- 选择方式：**按规则定一个主推荐**
- 级别：设计候选 · 运行时未验
- 你该得到：加新技能不毁旧语义/旧档

**复制发给 AI（改路径）：**

```text
项目 <项目根路径>。用稳定模式。目标：技能表扩展10个新技能不改老语义。要求：存档兼容、命名、默认字段、回滚。交付：步骤+回归表。
用人话讲。
```

### 场景 2 · 道具批量导入

**本场实测（live）** · 证据 [T-STA-02 完整解说](./docs/scenario-run-reports/T-STA-02.md) · 回执 [json](./docs/scenario-run-reports/receipts/T-STA-02.json)

- 状态：**通过**
- 方向数：**5**
- 主推荐：**可回滚**（`rollback`）
- 选择方式：**按规则定一个主推荐**
- 级别：设计候选 · 运行时未验
- 你该得到：校验、失败隔离、部分成功

**复制发给 AI（改路径）：**

```text
项目 <项目根路径>。用稳定模式。目标：安全导入道具表。要求：校验去重失败隔离部分成功。交付：导入规程。
用人话讲。
```

### 场景 3 · 活动开关配置

**本场实测（live）** · 证据 [T-STA-03 完整解说](./docs/scenario-run-reports/T-STA-03.md) · 回执 [json](./docs/scenario-run-reports/receipts/T-STA-03.json)

- 状态：**通过**
- 方向数：**5**
- 主推荐：**贴合现有集成**（`integration-fit`）
- 选择方式：**按规则定一个主推荐**
- 级别：设计候选 · 运行时未验
- 你该得到：默认关、可回退、可追查

**复制发给 AI（改路径）：**

```text
项目 <项目根路径>。用稳定模式。目标：活动开关配置下发不影响日常关卡。要求：默认关可回退可追日志。交付：开关方案。
用人话讲。
```

### 场景 4 · 老关卡修 bug 不毁档

**本场实测（live）** · 证据 [T-STA-04 完整解说](./docs/scenario-run-reports/T-STA-04.md) · 回执 [json](./docs/scenario-run-reports/receipts/T-STA-04.json)

- 状态：**通过**
- 方向数：**5**
- 主推荐：**兼容性**（`compatibility`）
- 选择方式：**按规则定一个主推荐**
- 级别：设计候选 · 运行时未验
- 你该得到：最小改动、中途玩家兼容

**复制发给 AI（改路径）：**

```text
项目 <项目根路径>。用稳定模式。目标：修老关卡卡死不毁档。要求：最小改动兼容中途玩家。交付：修复+风险。
用人话讲。
```

---

## 7. 边界

| 算成功 | 不算 |
|--------|------|
| 装上、有清单 | 编辑器已玩通 |
| AI 给出可讨论方案 | 已平衡、已实装 |
| 能对上 live 证据 | 可发版 |

```text
请用人话总结主推方向、原因、我还要拍板什么；不要宣称已实装或 PlayMode 已过。
```

---

## 8. 完整解说与证据链（文末）

每场单独一篇长文：问题是什么、ABCD 怎么走、主推为何、方向表、分数、对照仅提示词、你可继续对 AI 说的话、审计字段。

本批 ABCD 入口：真实 `Invoke-ESABCModeDivergence` + `Select-ESABCGenerationCandidate`。  
复跑场景：`powershell -File .\scripts\Run-ESABCDScenarioReportSuite.ps1`  
复跑 vs 提示词：`powershell -File .\scripts\Build-AbcdVsPromptOnlyComparison.ps1`

### 总览

| 项 | 链接 |
|----|------|
| **vs 仅提示词全文** | [abcd-vs-prompt-only/](./docs/abcd-vs-prompt-only/README.md) |
| 场景对照表 | [COMPARISON-modes-live.md](./docs/scenario-run-reports/COMPARISON-modes-live.md) |
| 场景证据目录 | [scenario-run-reports/](./docs/scenario-run-reports/README.md) |
| 场景回执 JSON | [receipts/](./docs/scenario-run-reports/receipts/) |

### 逐场证据（报告 MD + 回执 JSON）

| 编号 | 报告 | 回执 | selectedDirectionId | candidateSetHash |
|------|------|------|---------------------|------------------|
| T-ENG-01 | [T-ENG-01.md](./docs/scenario-run-reports/T-ENG-01.md) | [json](./docs/scenario-run-reports/receipts/T-ENG-01.json) | `cand-1512670ca9b9c3275ce2` | `5dad3f4ca65e162588d1f9bdfe80b17d53dae38f8c44ba94dc7c0903670f04c1` |
| T-ENG-02 | [T-ENG-02.md](./docs/scenario-run-reports/T-ENG-02.md) | [json](./docs/scenario-run-reports/receipts/T-ENG-02.json) | `cand-cdd33ebac2799bc8f03c` | `6d543bf5b342a2793779f52695df6c1a3c2d6bda33131f6a1fc6d4bebe8d0b86` |
| T-ENG-03 | [T-ENG-03.md](./docs/scenario-run-reports/T-ENG-03.md) | [json](./docs/scenario-run-reports/receipts/T-ENG-03.json) | `cand-be1cfc2e0345a72f7614` | `18ada1e9ef5aacc5439bc38728eb66779c47181c361ee52c82e0e9d14665faee` |
| T-ENG-04 | [T-ENG-04.md](./docs/scenario-run-reports/T-ENG-04.md) | [json](./docs/scenario-run-reports/receipts/T-ENG-04.json) | `cand-338d4c85731d7235a14b` | `b4ee0d9d451dc80e935568c80167a07c25b08ffd7006f0c6753f3e55c142cc9c` |
| T-CRE-01 | [T-CRE-01.md](./docs/scenario-run-reports/T-CRE-01.md) | [json](./docs/scenario-run-reports/receipts/T-CRE-01.json) | `cand-f28fe0d72897a6ff69be` | `eff3ec1d6173ee0178e8accf5798a7c57c64c1cfe41113af7e08995ee6836b18` |
| T-CRE-02 | [T-CRE-02.md](./docs/scenario-run-reports/T-CRE-02.md) | [json](./docs/scenario-run-reports/receipts/T-CRE-02.json) | `cand-4ec4a0ef0f7ca0968353` | `46ee993c36095dd70875b2ba2c18984251d85b73a3261758d2c7b9215f48f0f4` |
| T-CRE-03 | [T-CRE-03.md](./docs/scenario-run-reports/T-CRE-03.md) | [json](./docs/scenario-run-reports/receipts/T-CRE-03.json) | `cand-0848c7565cb237906782` | `3e47918c187e34313efddd2e7b242042d60490bf10bb3b1792768a16bf9c4c5b` |
| T-CRE-04 | [T-CRE-04.md](./docs/scenario-run-reports/T-CRE-04.md) | [json](./docs/scenario-run-reports/receipts/T-CRE-04.json) | `cand-e1f33204812d14140800` | `15c81a57675ac33a3c2a5448b5028ef313f2361da5046ce411f6e9da32a562b4` |
| T-STA-01 | [T-STA-01.md](./docs/scenario-run-reports/T-STA-01.md) | [json](./docs/scenario-run-reports/receipts/T-STA-01.json) | `cand-2efc8c2dc69e419bc888` | `f2d62c2501090f1df70f5e300f89999d9657ef58d888e2fb13d1a55af46f19ec` |
| T-STA-02 | [T-STA-02.md](./docs/scenario-run-reports/T-STA-02.md) | [json](./docs/scenario-run-reports/receipts/T-STA-02.json) | `cand-92b98548daf46acddb45` | `574ea1789eecefb4ac5199b6ebcbc60c675035b8179d2f91d33334f195b7ba04` |
| T-STA-03 | [T-STA-03.md](./docs/scenario-run-reports/T-STA-03.md) | [json](./docs/scenario-run-reports/receipts/T-STA-03.json) | `cand-17070a1c467afb7c4ec4` | `98baf5c176f312f37b8420dc3a93e6a311455cd901750b201665bd0c4041ac07` |
| T-STA-04 | [T-STA-04.md](./docs/scenario-run-reports/T-STA-04.md) | [json](./docs/scenario-run-reports/receipts/T-STA-04.json) | `cand-4bba0192d92567aedf6b` | `f477679d8d86e0ca084b722f5563946402cfcc8457b26c80b85ac9b00897ac4b` |

其它：[开始试用](./开始试用.md) · [流程细文](./docs/真实流程与结果解说.md) · [AI 安装剧本](./docs/ai-install-playbook.md) 
