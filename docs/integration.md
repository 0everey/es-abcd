# 接入说明（中文）

## 简单度

对大多数项目：**给齐两个绝对路径 → 对 AI 说安装 / 或跑 `get.ps1`**。  
不依赖原生 ES 游戏仓，不依赖 Unity。

| 检查 | 期望 |
|------|------|
| 布局 | `passed` |
| 项目画像 | 写出 `project-profile.json` |
| 自主套件 | `passed`，不依赖 ES 宿主 |
| 安装 | `installed` |
| 冒烟 | `passed`，`runtime-not-run` |
| 清单 | `adapt-checklist-*.md` |

## 布局约定

安装后目标项目根下会有：

```text
ES/Automation/ABCD/
ES/Automation/Contracts/
ES/Automation/TaskContextRuntime/
ES/Automation/AI/
.agents/skills/es-ai-abc-core/
```

路径一律相对**项目根**。

## 默认治理

`ES_ABCD_GOVERNANCE_MODE=portable`。  
可选 `host`（有完整语料时）；失败回退 portable。

## 升级

1. 更新本开源仓  
2. 对目标再跑 `get.ps1 -Force`  
3. 再冒烟、再刷新清单  

## 不要做

- 假盘符路径、只说「装电脑上」  
- 用冒烟冒充 PlayMode/发版  
- 在消费方再手搓第二套核心  
