# es-abcd 与 ESFramework 的独立性说明

## 产品身份

| 项目 | 身份 |
|------|------|
| **es-abcd** | 独立开源产品：ABCD/ABCC **工程编排核心** |
| **ESFramework** | 可选**消费方 / 宿主**（游戏与项目治理仓），**不是** es-abcd 的运行时依赖 |

es-abcd：

- **不是** ES 游戏运行时  
- **不是** Unity 插件  
- **不**要求本机存在 `ESFrameWorkPublish`  
- **不**要求 `Assets/Plugins/ES/AIWarnings` 语料  

## 治理模式

| 模式 | 环境变量 | 含义 |
|------|----------|------|
| **portable（默认）** | `ES_ABCD_GOVERNANCE_MODE=portable` 或不设 | 使用本包自带 `portable/es-abcd-portable-governance-v1.json`，六能力完整 |
| **host（可选）** | `ES_ABCD_GOVERNANCE_MODE=host` | 仅当宿主具备完整 AIWarnings 语料/索引时增强；失败则**回退 portable**，不丢核心能力 |

## 能力对等（禁止“阉割式自主”）

Portable 模式**必须**保留：

1. `bounded-tool-action`  
2. `failure-recovery`  
3. `branch-evaluation`  
4. `state-transition-guard`  
5. `environment-trust-gate`  
6. `audit-evidence-chain`  

以及：发散、候选选择、稳定评分、权威决策、审计摘要投影、合同解析。

## 路径解析

- `Get-ESABCDPackageRoot`：本包根  
- `Resolve-ESABCDContractPath`：优先本包合同；若消费方已 Install 叠加，可读消费方 `ES/Automation/Contracts`  
- **不再**默认假定「必须先有原生 ES 仓」

## 验收

```powershell
powershell -File .\scripts\Invoke-ESABCDAutonomySuite.ps1
```

通过条件：`status=passed` 且 `requiresESFramework=false`。

## 与 ES 的协作关系（可选）

ES 可以：

1. 作为消费方 `Install-ESABCD` 叠加本包；或  
2. 设置 `host` 模式使用自有 AIWarnings 语料增强治理  

ES **不可以**再被描述为「es-abcd 离开它就不能用」。
