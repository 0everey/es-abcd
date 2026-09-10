# es-abcd v1.0.0 发布说明

可移植 ABCD/ABCC 工程编排核心 · 首个正式版（GA）。

## 怎么装（说人话）

把路径换成你自己的绝对路径，对 AI 说：

```text
es-abcd 在 <es-abcd根路径>，装到项目 <项目根路径>，先分析项目再按情况接入，出适配清单，用人话汇报。
```

或自己执行：

```powershell
powershell -File <es-abcd根路径>\get.ps1 -TargetRoot <项目根路径>
```

## 你会得到

- 项目画像：`project-profile.json`（自动识别项目类型）
- 叠加安装 + 冒烟 + 适配清单
- README 内 15 组可复制真实场景（工程/创意/稳定）
- 默认可移植治理（不需要旧 ES 宿主）

## 自检（可选）

```powershell
powershell -File .\scripts\Test-ESABCDPackageLayout.ps1
powershell -File .\scripts\Invoke-ESABCDAutonomySuite.ps1
```

## 边界（请对外说清楚）

冒烟 / 自主验收通过 ≠ Unity 场景已测 ≠ 游戏内容可发版。  
未跑真实运行时，回执会写 `runtime-not-run`。
