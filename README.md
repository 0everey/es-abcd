# ES ABCD 可移植核心

**面向任意项目的工程协作编排内核（与具体游戏/业务解耦）。**

把「目标 → 多方案发散 → 评分门禁 → 回执」做成可复用能力。  
**不是**游戏引擎，**不是** Unity 插件，**也不是**自动写业务代码的黑盒。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![仓库](https://img.shields.io/badge/GitHub-0everey%2Fes--abcd-blue.svg)](https://github.com/0everey/es-abcd)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](#环境要求)

**仓库：** https://github.com/0everey/es-abcd  
**本地目录（若你从本机构建）：** `F:\aaProject\es-abcd`（与远程同内容）

---

## 一句话说明

| 你想做什么 | 用不用本仓库 |
|---|---|
| 给 AI/协作流程一套可验证的工程决策骨架 | ✅ 用 |
| 直接驱动 Unity 场景、Prefab、战斗数值 | ❌ 不用（那是业务仓的事） |
| 把密钥、模型 Provider 写进开源包 | ❌ 禁止 |

---

## 接入简单度评估（结论：简单）

| 维度 | 评级 | 说明 |
|---|---|---|
| 安装步骤 | **简单** | 克隆 → 一条 Install → 一条 Smoke，通常 **3 条命令** |
| 对目标项目侵入 | **低** | 只叠加 `ES/Automation/...` 与 `.agents/skills/...`，不改你业务源码 |
| 运行时依赖 | **低** | 只要 Windows PowerShell 5.1+（或 pwsh 7+），**不需要 Unity** |
| 路径约定 | **固定、可抄** | 一律相对「项目根」：`ES/Automation/Contracts/...` |
| 验证反馈 | **明确** | Smoke 输出 `status=passed` + JSON 回执；失败路径清晰 |
| 学习成本 | **中低** | 先跑通 Smoke 即可用；概念见 [docs/concepts.md](docs/concepts.md) |
| 不适合谁 | — | 期望「装上就能自动写完游戏」的用户会失望（本核刻意不做） |

**推荐接入路径（最小）：** 只跑安装 + Smoke，确认 `runtime-not-run` 与 `passed` 后，再在自己的脚本里调用 `Invoke-ESABCModeDivergence`。

---

## 60 秒上手

> Windows 若没有 `pwsh`，把下面的 `pwsh` 全部换成 `powershell` 即可。

```powershell
# 1) 克隆
git clone https://github.com/0everey/es-abcd.git
cd es-abcd

# 2) 检查本包是否完整
powershell -File .\scripts\Test-ESABCDPackageLayout.ps1

# 3) 安装到你的项目根目录（会创建 ES/Automation 等目录）
powershell -File .\scripts\Install-ESABCD.ps1 -TargetRoot 'C:\path\to\你的项目'

# 4) 冒烟（纯静态，不启动 Unity）
powershell -File .\scripts\Invoke-ESABCDSmoke.ps1 -ProjectRoot 'C:\path\to\你的项目' -Mode engineering
```

成功时应看到：

- 控制台：`ABCD smoke PASSED`
- 回执：`你的项目\ES\Automation\ABCD\out\smoke-*.json`
- 字段：`status=passed`，`runtimeStatus=runtime-not-run`（**正常**，表示未做运行时验收）

升级已安装项目：

```powershell
powershell -File .\scripts\Install-ESABCD.ps1 -TargetRoot 'C:\path\to\你的项目' -Force
powershell -File .\scripts\Invoke-ESABCDSmoke.ps1 -ProjectRoot 'C:\path\to\你的项目'
```

---

## 你得到什么

| 模块 | 内容 |
|---|---|
| **ABCD 核心** | 发散、评分、InnovationRun、权威内核、编排、门禁、补丁规划辅助 |
| **合同 Contracts** | `es-ai-abc-*.json` 及评分/生成模式注册表 |
| **TaskContextRuntime** | 任务绑定与上下文运行时（ABC 绑定会用到） |
| **最小 AI 辅助** | 权威决策策略与投影辅助（Smoke 不依赖你项目的 AIWarnings 语料） |
| **Skills** | `es-ai-abc-core`（可选：`es-agent-mechanism-replication` 作溯源） |
| **脚本** | 布局检查、安装叠加、冒烟测试 |

**业务无关（business-free）：** 不含场景、Prefab、武器、密钥、项目私有 AIWarnings 语料。

---

## 环境要求

- **PowerShell 5.1+**（推荐 PowerShell 7+ / `pwsh`，没有也能用系统 `powershell`）
- **Git**（克隆用）
- 可选：能加载 `.agents/skills/*/SKILL.md` 的 Agent 宿主

安装与 Smoke **不需要** Unity Editor。

---

## 核心概念（30 秒）

| 符号 | 中文 | 含义 |
|---|---|---|
| **A** | 智能体 | 提出目标、发出意图、消费归一化结果 |
| **B** | 机制/能力 | 可协商、可验证的能力（不专指行为树） |
| **C** | 协作者 | 你（人或 AI）授权目标并做最终接受 |
| **ABCD.Dynamic** | 动态编排 | 完整 InnovationRun 阶段流 |
| **ABCC.Core** | 适配核心 | A↔B 稳定合同 + 六项内核能力 |
| **ABCP.Part** | 领域部件 | 写在**你的业务仓**里，引用 Core，不复制 Core 正文 |

六项内核能力（缺一不可）：

`bounded-tool-action` · `failure-recovery` · `branch-evaluation` · `state-transition-guard` · `environment-trust-gate` · `audit-evidence-chain`

更多说明：[docs/concepts.md](docs/concepts.md)

---

## 装进任意项目之后长什么样

安装脚本会把文件**叠加**到目标项目根目录：

```text
你的项目/
  ES/Automation/ABCD/              # 核心模块
  ES/Automation/Contracts/         # es-ai-abc-* 合同
  ES/Automation/TaskContextRuntime/
  ES/Automation/AI/                # 最小辅助
  ES/Automation/Workers/PowerShell/  # 可选
  .agents/skills/es-ai-abc-core/
```

目标可以是 Unity、.NET、Node、纯文档仓——只要保持上述相对路径（或你自己改解析路径）。

详细接入：[docs/integration.md](docs/integration.md)

---

## 最小调用示例

```powershell
$root = 'C:\path\to\你的项目'
Import-Module "$root\ES\Automation\ABCD\ESABCDDivergence.psm1" -Force
Import-Module "$root\ES\Automation\ABCD\ESABCInnovationRun.psm1" -Force

$contract = "$root\ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json"
$hash = (Get-FileHash $contract -Algorithm SHA256).Hash.ToLowerInvariant()

$div = Invoke-ESABCModeDivergence `
  -Requirement '冻结三层架构：平台域 / 定义表 / 物理查询层，禁止用物理层表达阵营' `
  -SourceHash $hash `
  -Mode engineering `
  -ProjectRoot $root

$sel = Select-ESABCGenerationCandidate -Candidates $div.directions -Mode engineering
Write-Host "选中:" $sel.selectedDirectionId "状态:" $sel.selectionStatus
```

也可直接跑示例：

```powershell
powershell -File .\examples\minimal-engineering.ps1 -ProjectRoot 'C:\path\to\你的项目'
```

---

## 生成模式怎么选

| 模式 | 适用场景 |
|---|---|
| `engineering` | 架构冻结、所有权、生命周期、可复用（**默认推荐**） |
| `creative-divergence` | 需要多方案创新、偏体验/新颖性 |
| `stable` | 强调贴合现有项目、完整闭环、安全收口 |

---

## 证据规则（必读）

| 你想声称… | 需要什么证据 |
|---|---|
| 包布局完整 | `Test-ESABCDPackageLayout.ps1` 通过 |
| 核心可调用 | `Invoke-ESABCDSmoke.ps1` 回执 `status=passed` |
| 正式架构竞赛 `completed` | Provider 回执 + 实现证据（见 ABCD 模块，门槛更高） |
| Unity / PlayMode / 发布通过 | **另外的**新鲜回执，**绝不能**用 Smoke 代替 |

未跑运行时时，回执必须保留 `runtimeStatus: runtime-not-run`。  
**缺少运行时证据 ≠ 静态失败**，只是不能宣称运行时验收通过。

---

## 仓库结构

```text
es-abcd/
  README.md                 # 本文件（中文）
  LICENSE
  package/es-abcd-portable.manifest.json
  scripts/
    Install-ESABCD.ps1      # 安装到目标项目
    Invoke-ESABCDSmoke.ps1  # 冒烟
    Test-ESABCDPackageLayout.ps1
  docs/
    concepts.md             # 概念（中文）
    integration.md          # 接入（中文）
  examples/
    minimal-engineering.ps1
  ES/Automation/...
  .agents/skills/...
```

---

## 给 Agent 宿主

1. 克隆本仓，或 Install 叠加进 monorepo。  
2. 技能路径：`.agents/skills/es-ai-abc-core/SKILL.md`  
3. **披露 Skill ≠ 授权写盘 / 启 Unity / 联网 / 发布**。  
4. 架构冻结优先 `engineering`；先有 Smoke 回执再声称「ABCD 已跑」。

---

## 非目标（明确不做）

- 附带游戏内容、武器、场景、项目 AIWarnings 语料  
- 无回执就宣称 CI「全绿」  
- 打包模型 API Key 或 Provider 密钥  
- 在未配置 Provider 时保证完整 InnovationRun `final-decision` 正式 completed  

---

## 来源说明

由 ESFramework 自动化核心中 **business-free 可移植切片** 整理公开（去掉领域武器 Part 与项目私有 AI 流量）。  
本地与 GitHub 应保持同一套文件；本 README 以中文为主说明。

---

## 许可证

MIT — 见 [LICENSE](LICENSE)。

---

## 贡献约定

1. 保持 `businessFree: true`，禁止提交玩法资产。  
2. 破坏性合同变更视为 major。  
3. PR 前跑通布局检查 + Smoke。  
4. 禁止提交密钥与本机绝对路径（文档示例用占位路径）。
