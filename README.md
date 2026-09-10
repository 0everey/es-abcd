# es-abcd

独立的 **ABCD/ABCC 工程编排核心**：目标 → 发散 → 评分门禁 → 回执。  
不是游戏引擎，不是 Unity 插件，不依赖原生 ESFramework。

**仓库：** https://github.com/0everey/es-abcd  
**许可：** MIT

---

## 核心用法（推荐）

1. 本机准备一次：`git clone https://github.com/0everey/es-abcd.git`
2. 对 AI 说：

```text
把 es-abcd 安装到 <你的项目根>，并给出迁移适配清单。
```

3. 打开项目里的清单并勾完：

`ES/Automation/ABCD/out/adapt-checklist-*.md`

4. 日常两行：

```powershell
. .\ES\Automation\ABCD\Use-ESABCD.ps1
Invoke-ESABCDQuick -Requirement "你的目标"
```

AI 剧本：[docs/ai-install-playbook.md](docs/ai-install-playbook.md)

---

## 自己一键

```powershell
# 在项目根，或指定 -TargetRoot
powershell -File <es-abcd>\get.ps1 -TargetRoot .
```

远程：

```powershell
iex (irm https://raw.githubusercontent.com/0everey/es-abcd/main/get.ps1)
```

`get.ps1` 会：安装叠加 → Smoke → `Use-ESABCD.ps1` → 适配清单。

---

## 装完有什么

```text
你的项目/
  ES/Automation/ABCD/          # 核心 + Use-ESABCD.ps1
  ES/Automation/ABCD/out/      # oneclick / smoke / adapt-checklist
  ES/Automation/Contracts/
  .agents/skills/es-ai-abc-core/
```

---

## 身份与边界

| | 说明 |
|--|------|
| **是** | 可移植编排核；默认 `portable` 治理；六项能力完整 |
| **不是** | ESFramework 运行时、Unity 验收、自动改完业务代码 |
| **与 ES** | ES 可选消费本包；Core **不要求** 本机有 ES 仓 |
| **ABCD 词义** | 仅 `ABCD.Dynamic`，禁止第二含义（见 docs/concepts） |

未跑 Unity/PlayMode 时回执为 `runtime-not-run`（缺运行时证据，不是静态失败）。

---

## 验收（可选）

```powershell
powershell -File .\scripts\Invoke-ESABCDAutonomySuite.ps1   # 无 ES 宿主自主
powershell -File .\scripts\Invoke-ESABCDSmoke.ps1           # 装后冒烟
```

---

## 概念（极简）

- **A** 智能体 · **B** 机制 · **C** 协作者  
- **ABCD.Dynamic** 动态编排 · **ABCC.Core** 适配核 · **ABCP.Part** 业务部件（你的仓）  
- 能力：`bounded-tool-action` / `failure-recovery` / `branch-evaluation` / `state-transition-guard` / `environment-trust-gate` / `audit-evidence-chain`

---

## 文档

| 文档 | 用途 |
|------|------|
| [ai-install-playbook.md](docs/ai-install-playbook.md) | AI 一句话安装 |
| [independence.md](docs/independence.md) | 与 ES 独立 |
| [one-click.md](docs/one-click.md) | 一键设计 |
| [integration.md](docs/integration.md) | 接入细节 |
| [concepts.md](docs/concepts.md) | 概念与单义锁 |
