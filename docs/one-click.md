# 极简一键接入设计

## 目标

把「克隆 → 检查 → 安装 → 冒烟 → 日常调用」收成 **一条命令 + 两行日常用法**。

## 用户心智（唯一路径）

```text
在项目根执行 get.ps1
        │
        ▼
  缓存 es-abcd 包（或用本地仓）
        │
        ▼
  Install 叠加到当前项目
        │
        ▼
  Smoke 证明 Core 可调用
        │
        ▼
  Use-ESABCD.ps1 → Invoke-ESABCDQuick
```

## 为什么以前不够「一键」

| 旧步骤 | 摩擦 |
|--------|------|
| 先 clone 再 cd | 多一步目录心智 |
| Install / Smoke / Autonomy 三个脚本 | 不知道最小集是哪个 |
| 还要手写 Import-Module | 日常调用成本高 |
| 路径/ES 依赖叙事混杂 | 不敢在非 ES 项目试 |

## 一键脚本职责边界

`get.ps1` **只做**：

1. 解析 TargetRoot（默认 cwd）  
2. 准备 package（本地仓优先，否则 git cache）  
3. layout → install → smoke  
4. 写 `Use-ESABCD.ps1` 日常 shim  
5. 写 oneclick 回执（`runtime-not-run`）

`get.ps1` **不做**：

- 不启动 Unity  
- 不写密钥  
- 不改业务源码（只叠加 `ES/Automation` 与 skills）  
- 不把 Smoke 说成 PlayMode 通过  

## 命令形态

| 场景 | 命令 |
|------|------|
| 零基础远程 | `iex (irm https://raw.githubusercontent.com/0everey/es-abcd/main/get.ps1)` |
| 已有克隆 | `powershell -File .\get.ps1 -TargetRoot .` |
| 升级覆盖 | 同上加 `-Force` |
| 只要装不要测 | `-SkipSmoke`（不推荐） |

## 成功判据

- 控制台：`DONE` + `ESFramework host: NOT required`  
- 存在：`ES/Automation/ABCD/Use-ESABCD.ps1`  
- 存在：`ES/Automation/ABCD/out/oneclick-*.json` 且 `status=passed`  
- `Invoke-ESABCDQuick` 能返回 `selectedDirectionId`  

## 非目标

- 图形化安装向导  
- 无 Git 的纯 zip 通道（可二期加 `-SourceZip`）  
- 自动配置模型 Provider  
