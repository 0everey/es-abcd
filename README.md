# ES ABCD 可移植核心

**面向任意项目的工程协作编排内核（与具体游戏/业务解耦）。**

把「目标 → 多方案发散 → 评分门禁 → 回执」做成可复用能力。  
**不是**游戏引擎，**不是** Unity 插件，**也不是**自动写业务代码的黑盒。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![仓库](https://img.shields.io/badge/GitHub-0everey%2Fes--abcd-blue.svg)](https://github.com/0everey/es-abcd)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](#环境要求)

**仓库：** https://github.com/0everey/es-abcd  

---

## 推荐用法（请直接照做）

### 一句话概括

> **本机下载一次 es-abcd → 对 AI 说「安装到 XXX 项目并给适配清单」→ 按清单勾完即可。**

这是本仓库的**主推接入路径**，比手敲多条脚本更省心。

---

### 步骤 1：本机准备包（只需一次）

任选其一：

```powershell
git clone https://github.com/0everey/es-abcd.git
# 例如放到：C:\tools\es-abcd  或  F:\aaProject\es-abcd
```

或下载 GitHub 源码 ZIP 并解压。  
确认目录里有：`get.ps1`、`package\es-abcd-portable.manifest.json`。

---

### 步骤 2：对 AI 说一句话（复制即用）

把路径换成你的真实项目根：

```text
把 es-abcd 安装到 D:\work\MyProject，并给出迁移适配清单。
```

等价英文：

```text
Install es-abcd to D:\work\MyProject and refresh the adapt checklist.
```

其它可识别说法：

- 接入 ABCD 到当前仓库，并输出适配清单  
- one-click install es-abcd to `<path>` + checklist  
- 用本地 es-abcd 装到 XXX，装完把清单路径发我  

**AI 必须遵守的剧本：** [docs/ai-install-playbook.md](docs/ai-install-playbook.md)

AI 应执行的核心命令（你可自检）：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<本地es-abcd>\get.ps1" -TargetRoot "<你的项目根>" -Force
```

`get.ps1` 会自动：布局检查 → 安装叠加 → Smoke → 写日常入口 → **生成适配清单**。

---

### 步骤 3：你只收这三样

| 交付物 | 典型路径 | 用途 |
|--------|----------|------|
| 一键回执 | `ES\Automation\ABCD\out\oneclick-*.json` | 证明装上了 |
| Smoke 回执 | `ES\Automation\ABCD\out\smoke-*.json` | 证明 Core 能跑（静态） |
| **迁移/适配清单** | `ES\Automation\ABCD\out\adapt-checklist-*.md` | **你要勾的 todo/review** |

另外会生成日常入口：

`ES\Automation\ABCD\Use-ESABCD.ps1`

---

### 步骤 4：装完当天两行 + 勾清单

```powershell
cd D:\work\MyProject
. .\ES\Automation\ABCD\Use-ESABCD.ps1
Invoke-ESABCDQuick -Requirement "你的目标（例如：冻结三层架构并写清所有权）"
```

然后打开：

```text
D:\work\MyProject\ES\Automation\ABCD\out\adapt-checklist-*.md
```

按状态处理：

| 状态 | 含义 |
|------|------|
| **done** | 已满足，可忽略 |
| **todo** | 必须做 |
| **review** | 需你或 AI 判断（如是否 ES 双核、Skill 是否挂上） |
| **optional** | 可选（如 CI Smoke） |
| **info** | 边界说明（如 Unity 证据不能用 Smoke 代替） |

清单也可单独重生成：

```powershell
powershell -File "<本地es-abcd>\scripts\New-ESABCDAdaptChecklist.ps1" -TargetRoot "D:\work\MyProject" -OutMarkdown
```

---

### 这一条路径明确「是 / 否」

| 是 | 否 |
|----|----|
| 下载一次，多项目反复「对 AI 说安装」 | 每个项目都要重新理解十个脚本 |
| 安装 + Smoke + **结构化适配清单** | 黑盒自动改完所有业务代码 |
| 不依赖原生 ESFramework 游戏仓 | Smoke = PlayMode / 发布通过 |
| 清单告诉还要审什么 | 替你保管 API Key / Provider |

**迁移适配 = 清单驱动的有界工作，不是一句话自动改业务。** 业务改动仍按清单项单独授权。

---

## 不经过 AI：自己一键

在项目根执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (irm https://raw.githubusercontent.com/0everey/es-abcd/main/get.ps1)"
```

指定目录：

```powershell
$get = irm https://raw.githubusercontent.com/0everey/es-abcd/main/get.ps1
& ([scriptblock]::Create($get)) -TargetRoot 'C:\work\MyApp' -Force
```

本地已有克隆：

```powershell
powershell -File C:\tools\es-abcd\get.ps1 -TargetRoot 'C:\work\MyApp' -Force
# 或
powershell -File C:\tools\es-abcd\scripts\OneClick-Install.ps1 -TargetRoot 'C:\work\MyApp' -Force
```

一键自动完成：缓存/本地包 → 布局 → 安装 → Smoke → `Use-ESABCD.ps1` → **adapt-checklist**。

---

## 与原生 ESFramework 的独立性（重要）

| | **es-abcd（本仓库）** | **ESFramework（原游戏/项目仓）** |
|---|---|---|
| 身份 | 独立开源 **ABCD/ABCC 工程编排产品** | 可选 **消费方 / 宿主** |
| 是否互为运行时依赖 | **Core 不依赖 ESFramework** | 可选用本包，非必须 |
| 默认治理 | `portable` 自带治理合同 | 可选 `host` 使用其 AIWarnings 语料 |
| 六项内核能力 | **完整保留**（禁止阉割式“假自主”） | 不替代本包能力表 |

- **默认**不需要本机存在 `ESFrameWorkPublish`，不需要 `Assets/Plugins/ES/AIWarnings`。  
- 强自主验收：`powershell -File .\scripts\Invoke-ESABCDAutonomySuite.ps1`  
- **ABCD 单义锁**：裸词 `ABCD` 仅表示 `ABCD.Dynamic`；禁止把 ABCD 当成「工程四字母清单」等第二含义（见 [docs/concepts.md](docs/concepts.md)）。  
- 详细说明：[docs/independence.md](docs/independence.md)

若目标项目**本身就是 ESFramework 树**，清单会标 `host.esframework-detected = review`：应避免双核并存，优先以本包 overlay 为唯一 Core。

---

## 一句话说明

| 你想做什么 | 用不用本仓库 |
|---|---|
| 给 AI/协作流程一套可验证的工程决策骨架 | ✅ 用 |
| 下载后对 AI 说「装到 XXX + 清单」 | ✅ **主推** |
| 直接驱动 Unity 场景、Prefab、战斗数值 | ❌ 不用（业务仓的事） |
| 必须安装原生 ES 游戏框架才能跑 | ❌ **不需要** |
| 把密钥、模型 Provider 写进开源包 | ❌ 禁止 |

---

## 接入简单度评估

| 维度 | 评级 | 说明 |
|---|---|---|
| 人机协作 | **最简单** | 下载一次 + 对 AI 一句话 + 勾清单 |
| 纯手动 | **简单** | 一条 `get.ps1` / `irm` |
| 侵入性 | **低** | 只叠加 `ES/Automation/...` 与 `.agents/skills/...` |
| 运行时依赖 | **低** | PowerShell；无 Unity；无原生 ES 仓 |
| 验证 | **明确** | Smoke / oneclick / checklist 回执 |
| 不适合谁 | — | 期望「一句话自动改完游戏」的用户 |

---

## 分步上手（需要细控时）

```powershell
git clone https://github.com/0everey/es-abcd.git
cd es-abcd
powershell -File .\scripts\Test-ESABCDPackageLayout.ps1
powershell -File .\scripts\Invoke-ESABCDAutonomySuite.ps1
powershell -File .\get.ps1 -TargetRoot 'C:\path\to\你的项目' -Force
```

仅刷新清单：

```powershell
powershell -File .\scripts\New-ESABCDAdaptChecklist.ps1 -TargetRoot 'C:\path\to\你的项目' -OutMarkdown
```

---

## 你得到什么

| 模块 | 内容 |
|---|---|
| **ABCD 核心** | 发散、评分、InnovationRun、权威内核、编排、门禁 |
| **合同 Contracts** | `es-ai-abc-*.json` 及评分/生成模式注册表 |
| **TaskContextRuntime** | 任务绑定与上下文运行时 |
| **Portable 治理** | 不依赖宿主 AIWarnings 语料的默认治理 |
| **Skills** | `es-ai-abc-core` 等 |
| **一键脚本** | `get.ps1`、Install、Smoke、Autonomy、**AdaptChecklist** |
| **AI 剧本** | [docs/ai-install-playbook.md](docs/ai-install-playbook.md) |

**业务无关（business-free）：** 不含场景、Prefab、武器、密钥、项目私有 AIWarnings 语料。

---

## 环境要求

- **PowerShell 5.1+**（可用系统自带 `powershell`）  
- **Git**（克隆 / 一键缓存拉包）  
- 可选：能加载 `.agents/skills/*/SKILL.md` 的 Agent 宿主  

安装与 Smoke **不需要** Unity Editor。

---

## 核心概念（30 秒）

| 符号 | 中文 | 含义 |
|---|---|---|
| **A** | 智能体 | 提出目标、发出意图、消费归一化结果 |
| **B** | 机制/能力 | 可协商、可验证的能力 |
| **C** | 协作者 | 你（人或 AI）授权目标并最终接受 |
| **ABCD.Dynamic** | 动态编排 | 完整 InnovationRun（**ABCD 唯一合法语义**） |
| **ABCC.Core** | 适配核心 | A↔B 合同 + 六项内核能力 |
| **ABCP.Part** | 领域部件 | 写在业务仓，只引用 Core |

六项内核能力：

`bounded-tool-action` · `failure-recovery` · `branch-evaluation` · `state-transition-guard` · `environment-trust-gate` · `audit-evidence-chain`

更多：[docs/concepts.md](docs/concepts.md)

---

## 装进项目后的目录

```text
你的项目/
  ES/Automation/ABCD/
    Use-ESABCD.ps1              # 日常入口（一键生成）
    out/
      oneclick-*.json
      smoke-*.json
      adapt-checklist-*.md      # 迁移适配清单（请勾）
      adapt-checklist-*.json
  ES/Automation/Contracts/
  ES/Automation/TaskContextRuntime/
  ES/Automation/AI/
  .agents/skills/es-ai-abc-core/
```

---

## 日常调用（推荐）

```powershell
cd <你的项目>
. .\ES\Automation\ABCD\Use-ESABCD.ps1
Invoke-ESABCDQuick -Requirement "冻结三层架构并写清所有权"
```

底层模块示例见 `examples/minimal-engineering.ps1`。

---

## 生成模式

| 模式 | 适用 |
|---|---|
| `engineering` | 架构冻结、所有权、生命周期（默认） |
| `creative-divergence` | 多方案创新 |
| `stable` | 贴合现有项目、安全收口 |

---

## 证据规则（必读）

| 声称 | 需要 |
|---|---|
| 已安装 | `oneclick-*.json` 或 install receipt |
| Core 可调用 | `smoke-*.json` 且 `status=passed` |
| 适配工作清楚 | `adapt-checklist-*.md` |
| 自主无 ES 宿主 | Autonomy Suite 回执 `requiresESFramework=false` |
| Unity / PlayMode / 发布 | **另备**运行时回执，**禁止**用 Smoke 代替 |

未跑运行时时必须保留 `runtimeStatus: runtime-not-run`。  
**缺少运行时证据 ≠ 静态失败。**

---

## 给 Agent / AI 宿主

1. 本机或 monorepo 中具备 es-abcd 包。  
2. 用户说「安装到 XXX + 清单」时，**严格按** [docs/ai-install-playbook.md](docs/ai-install-playbook.md) 执行。  
3. 技能路径（安装后）：`.agents/skills/es-ai-abc-core/SKILL.md`  
4. **披露 Skill ≠ 授权写盘 / 启 Unity / 联网 / 发布。**  
5. 回报必须包含：回执路径、清单路径、日常两行、非声明（runtime-not-run）。

---

## 仓库结构

```text
es-abcd/
  README.md                          # 本文件
  get.ps1                            # 一键安装（含清单）
  LICENSE
  package/es-abcd-portable.manifest.json
  scripts/
    OneClick-Install.ps1
    Install-ESABCD.ps1
    Invoke-ESABCDSmoke.ps1
    Invoke-ESABCDAutonomySuite.ps1
    New-ESABCDAdaptChecklist.ps1     # 迁移适配清单
    Test-ESABCDPackageLayout.ps1
  docs/
    ai-install-playbook.md           # AI 一句话安装剧本
    one-click.md
    independence.md
    concepts.md
    integration.md
  examples/
  ES/Automation/...
  .agents/skills/...
```

---

## 非目标

- 附带游戏内容、武器、场景、项目 AIWarnings 语料  
- 无回执宣称 CI 全绿或 PlayMode 通过  
- 打包模型 API Key  
- 一句话自动完成全部业务迁移代码（清单之后仍是有界、需授权的工作）  

---

## 相关文档

| 文档 | 内容 |
|------|------|
| [docs/ai-install-playbook.md](docs/ai-install-playbook.md) | AI 一句话安装固定步骤 |
| [docs/one-click.md](docs/one-click.md) | 一键设计说明 |
| [docs/independence.md](docs/independence.md) | 与 ESFramework 独立性 |
| [docs/integration.md](docs/integration.md) | 接入细节 |
| [docs/concepts.md](docs/concepts.md) | 概念与单义锁 |

---

## 来源说明

由 ESFramework 自动化核心中 **business-free 可移植切片** 整理公开。  
**es-abcd 是独立产品**；ESFramework 是可选消费者，不是 Core 运行时依赖。

---

## 许可证

MIT — 见 [LICENSE](LICENSE)。

---

## 贡献约定

1. 保持 `businessFree: true`。  
2. 破坏性合同变更视为 major。  
3. PR 前跑通布局检查 + Smoke（及 Autonomy，若改独立性）。  
4. 禁止提交密钥与本机绝对路径。  
5. 用户「安装到 XXX」类请求，以 `ai-install-playbook.md` 为准，不得手搓半套 Core。
