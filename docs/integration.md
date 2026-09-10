# 接入指南（中文）

## 接入简单度

对大多数项目：**三步即可**——克隆本仓 → 自主验收 →（可选）Install 到业务仓。  
**不依赖原生 ESFramework 游戏仓**；不依赖 Unity。

| 检查项 | 期望 |
|--------|------|
| 布局脚本 | `status=passed` |
| **自主套件** | `Invoke-ESABCDAutonomySuite.ps1` → `passed`，`requiresESFramework=false` |
| 安装脚本 | `status=installed`，生成 `es-abcd-install.receipt.json` |
| 冒烟脚本 | `status=passed`，`runtimeStatus=runtime-not-run` |

默认治理：`ES_ABCD_GOVERNANCE_MODE=portable`（自带治理合同）。  
可选宿主：`host`（仅当具备完整 AIWarnings 语料时增强，失败回退 portable）。  
独立性说明见 [independence.md](independence.md)。

## 布局约定

安装后，**目标项目根目录**应包含：

```text
<项目根>/
  ES/Automation/ABCD/                 # 模块与脚本
  ES/Automation/Contracts/            # es-ai-abc-*.json（+ 少量支撑合同）
  ES/Automation/TaskContextRuntime/
  ES/Automation/AI/                   # 最小权威/投影辅助
  ES/Automation/Workers/PowerShell/   # 可选
  .agents/skills/es-ai-abc-core/
  .agents/skills/es-agent-mechanism-replication/
```

路径一律相对**项目根**，以便脚本解析 `ES/Automation/Contracts/...` 时无需改盘符。

## 安装

在 **es-abcd 克隆目录** 下执行（没有 `pwsh` 就用 `powershell`）：

```powershell
powershell -File .\scripts\Install-ESABCD.ps1 -TargetRoot 'C:\path\to\你的项目'

# 内容有哈希差异、需要覆盖升级时：
powershell -File .\scripts\Install-ESABCD.ps1 -TargetRoot 'C:\path\to\你的项目' -Force
```

## 冒烟

```powershell
powershell -File .\scripts\Invoke-ESABCDSmoke.ps1 -ProjectRoot 'C:\path\to\你的项目' -Mode engineering
```

期望：

- 控制台出现 `ABCD smoke PASSED`
- 回执目录：`ES/Automation/ABCD/out/smoke-*.json`

## 最小 API

```powershell
$root = 'C:\path\to\你的项目'
Import-Module "$root\ES\Automation\ABCD\ESABCDDivergence.psm1" -Force
Import-Module "$root\ES\Automation\ABCD\ESABCInnovationRun.psm1" -Force

$hash = (Get-FileHash "$root\ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json" -Algorithm SHA256).Hash.ToLowerInvariant()
$div = Invoke-ESABCModeDivergence `
  -Requirement '为三层架构做工程冻结方案' `
  -SourceHash $hash `
  -Mode engineering `
  -ProjectRoot $root
$sel = Select-ESABCGenerationCandidate -Candidates $div.directions -Mode engineering
$sel.selectedDirectionId
```

## Agent / Skill 宿主

技能入口：

- `.agents/skills/es-ai-abc-core/SKILL.md`

**注意：** 展示/加载 Skill ≠ 授权写入、启动 Unity、联网或发布。

## 增加领域部件（ABCP）

1. **不要改** 开源 Core 目录来塞业务。  
2. 在你的业务仓按 `es-ai-abc-part-v1.schema.json` 写 Part。  
3. 只引用 Core 能力 ID，禁止复制 Core 正文。  
4. Part 只注册在消费方项目。

## 升级

1. `git pull` 本开源仓。  
2. 对目标项目再跑 `Install-ESABCD.ps1 -Force`。  
3. 再跑 Smoke。  
4. 对比合同文件哈希后再声称兼容。

## 不要做的事

- 不要把 API Key 放进本包或叠加目录。  
- 不要用 Smoke 回执声称 PlayMode/发布通过。  
- 不要在消费方再写第二套 InnovationRun 状态机。
