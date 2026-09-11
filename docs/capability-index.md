# es-abcd 能力快速索引

## 唯一入口

| 层级 | 命令 |
|------|------|
| 安装 | `get.ps1` / `scripts/Start-ESABCDTrial.ps1` |
| 日常 | `. .\ES\Automation\ABCD\Use-ESABCD.ps1` → **`Invoke-ESABCD`** |

```powershell
Invoke-ESABCD -Requirement '…'                 # brief（默认）
Invoke-ESABCD -Requirement '…' -Output select  # 只要对象
Get-ESABCDIndexCatalog                         # 能力表
Import-ESABCDCapability patch -WithDeps        # 深路径按需
```

## 能力分散（按 tier）

机器可读权威表：`ES/Automation/ABCD/es-abcd-capability-index.json`

| tier | 含义 | 默认 brief 是否加载 |
|------|------|---------------------|
| boot | Home + Index | 是 |
| core | hash/delivery/divergence | 是 |
| content | 轴内容包 + MD 格式化 | 是 |
| deep | InnovationRun/Orchestrator/patch | **否**（按需） |
| host | Authority / portable governance | **否**（smoke/host 用） |

## 旧名

`Invoke-ESABCDQuick` / `Invoke-ESABCDCommercialBrief` / `Invoke-ESABCDCommercial` → 均转到 `Invoke-ESABCD`。

不要再手写 `Import-Module` 五件套。