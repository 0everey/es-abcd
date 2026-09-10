# ABCD / ABCC 概念说明

## 三角色

| 角色 | 英文 | 含义 |
|------|------|------|
| **A** | Agent（智能体） | 提出目标、发出意图、消费归一化结果 |
| **B** | Behavior（机制/能力） | 提供可协商、可验证的能力；**不**等同于行为树专用 |
| **C** | Collaborator（协作者） | 人或 AI，授权目标并做最终接受 |

## 三种模式

| 模式 | 是否独立 | 作用 |
|------|----------|------|
| **ABCD.Dynamic** | 是 | 完整动态编排（InnovationRun 多阶段） |
| **ABCC.Core** | 是 | A↔B 语义适配合同 + 六项内核能力 |
| **ABCP.Part** | 否 | 领域部件：只引用 Core 的 ID/合同，**禁止复制 Core 正文** |

## 六项内核能力（对等要求）

1. `bounded-tool-action` — 有界、授权下的动作与变更证据  
2. `failure-recovery` — 可观察失败、修订与有界重试/停止  
3. `branch-evaluation` — 有限候选、标准与排序决策  
4. `state-transition-guard` — 仅允许合法生命周期/所有权转移  
5. `environment-trust-gate` — 外部工具/运行时声明前的环境信任门  
6. `audit-evidence-chain` — 源哈希、回执、非声明与完成边界  

缺任一能力 → 不得宣称「完整 ABCC 对等」。

## 生成模式

| 模式 | 目标 |
|------|------|
| `creative-divergence` | 多机制创新候选，偏体验与新颖 |
| `engineering` | 深、可复用、带所有权/生命周期的技术体系（架构冻结常用） |
| `stable` | 贴合现有项目、完整、安全、可重复闭环 |

## 证据边界

| 层级 | 含义 |
|------|------|
| 静态 / 合同 | 脚本、Schema、Smoke 回执 |
| 运行时 | Unity / PlayMode / Profiler / Player — **必须有新鲜回执** |

`runtime-not-run` = **缺少运行时证据**，不是静态失败，也不能拿来冒充运行时通过。
