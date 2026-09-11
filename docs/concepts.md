# ABCD / ABCC 概念说明

## 三角色

| 角色 | 英文 | 含义 |
|------|------|------|
| **A** | Agent（智能体） | 提出目标、发出意图、消费归一化结果 |
| **B** | Behavior（机制/能力） | 提供可协商、可验证的能力；**不**等同于行为树专用 |
| **C** | Collaborator（协作者） | 人或 AI，授权目标并做最终接受 |

## ABCD 模式 / 功能 / 级（生成三目标）

**口语里的「ABCD 模式 / ABCD 功能 / ABCD 级」只映射下面三个生成 modeId，不映射 Dynamic/Core/Part。**

| 生成 modeId | 中文常用叫法 | 作用 |
|-------------|--------------|------|
| **`creative-divergence`** | 创意 / 创意模式 | 多机制创新、体验与新颖 |
| **`engineering`** | 工程 / 工程模式（默认） | 深度、可复用、架构竞赛 |
| **`stable`** | 稳定 / 稳定模式 | 贴合项目、完整闭环、安全吞吐 |

- 机器合同：`es-ai-abc-generation-mode-v1.json` → `abcdModeFunctionLevelMapping`  
- 解析：`Resolve-ESABCDGenerationMode.ps1`  
- **禁止**把 `ABCD.Dynamic` / `ABCC.Core` / `ABCP.Part` 说成「ABCD 模式」

## 架构栈身份（不是 ABCD 模式）

| 栈身份 stackId | 是否独立 | 作用 |
|----------------|----------|------|
| **ABCD.Dynamic** | 是 | 动态协作体编排（InnovationRun）；裸词 `ABCD` 的架构身份 |
| **ABCC.Core** | 是 | A↔B 语义适配合同 + 六项内核能力 |
| **ABCP.Part** | 否 | 领域部件：只引用 Core 的 ID/合同，**禁止复制 Core 正文** |

关系：跑 ABCD 时栈身份通常是 **Dynamic**；在其上再选 **创意/工程/稳定** 之一作为生成模式。

## 单义锁（拒绝 ABCD 意义偏差）

机器权威：`namingAuthority.monoSemanticLock`（`semanticCardinality=1`）。

| 规则 | 说明 |
|------|------|
| 裸词 `ABCD` | **只**允许 `modeId=ABCD.Dynamic`；`possibleModeIds` 仅此一项 |
| 工程四字母 | `A架构/B行为/C成本/D证据`、`engineering ABCD` 属 `neverValidAsCorrectSemantic`：`isCorrectSemantic=false`（永久），**不得**当正确 ABCD 语义 |
| 改称 | 工程检查只能叫 **engineering-method / 五阶段 / 四层验证 / StaticReview**，**不得叫 ABCD** |
| 解析器 | `ES/Automation/ABCD/Resolve-ESABCDMonoSemantic.ps1`；污染 → `claim-cap`，resolved 仍只能是 `ABCD.Dynamic` |
| 可移植 P0 | `es.abcd.p0.abcd-identity-mono-semantic.v1`（不依赖 ESFramework AIWarnings 语料） |
| 静态证明 | `Test-ESABCDMonoSemanticAuthority.ps1` |

上下文、任务类型、报告模板都**不能**改写身份；无 InnovationRun 回执不得 ABCD Accepted。

## 六项内核能力（对等要求）

1. `bounded-tool-action` — 有界、授权下的动作与变更证据  
2. `failure-recovery` — 可观察失败、修订与有界重试/停止  
3. `branch-evaluation` — 有限候选、标准与排序决策  
4. `state-transition-guard` — 仅允许合法生命周期/所有权转移  
5. `environment-trust-gate` — 外部工具/运行时声明前的环境信任门  
6. `audit-evidence-chain` — 源哈希、回执、非声明与完成边界  

缺任一能力 → 不得宣称「完整 ABCC 对等」。

## 生成模式（= 上文「ABCD 模式/功能/级」）

| 模式 | 目标 |
|------|------|
| `creative-divergence` | 多机制创新候选，偏体验与新颖 |
| `engineering` | 深、可复用、带所有权/生命周期的技术体系（架构冻结常用） |
| `stable` | 贴合现有项目、完整、安全、可重复闭环 |

勿把 Dynamic/Core/Part 称作生成模式或 ABCD 模式。

## 证据边界

| 层级 | 含义 |
|------|------|
| 静态 / 合同 | 脚本、Schema、Smoke 回执 |
| 运行时 | Unity / PlayMode / Profiler / Player — **必须有新鲜回执** |

`runtime-not-run` = **缺少运行时证据**，不是静态失败，也不能拿来冒充运行时通过。 
