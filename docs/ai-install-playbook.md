# AI 一句话安装剧本（给 Agent / 协作者）

## 用户可以说的话（示例）

> 把 es-abcd 安装到 `F:\work\MyGame`，并给出迁移适配清单。

等价说法：

- 安装 ABCD 到 XXX 项目  
- 接入 es-abcd 到当前仓库  
- one-click install to `<path>` + checklist  

## Agent 必须执行的固定步骤（不得跳步）

1. **确认本地包**  
   - 优先：用户已下载/克隆的 `es-abcd` 根（含 `get.ps1`、`package/es-abcd-portable.manifest.json`）  
   - 否则：`git clone https://github.com/0everey/es-abcd.git` 到约定缓存或用户指定目录  

2. **确认目标项目根 `TargetRoot`**  
   - 必须是已存在目录，或经用户授权可创建  
   - 不得把 es-abcd 自己的仓根当成业务项目根（除非用户明确要求）  

3. **一键安装（唯一推荐命令）**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<es-abcd>/get.ps1" -TargetRoot "<TargetRoot>" -Force
```

4. **生成迁移/适配清单**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<es-abcd>/scripts/New-ESABCDAdaptChecklist.ps1" -TargetRoot "<TargetRoot>" -OutMarkdown
```

5. **向用户回报（固定结构）**  
   - 安装结果：`passed/failed`  
   - 回执路径：`oneclick-*.json` / `smoke-*.json`  
   - 清单路径：`ES/Automation/ABCD/out/adapt-checklist-*.md`  
   - 日常两行用法  
   - **明确**：`requiresESFramework=false`；`runtime-not-run`；未宣称 PlayMode/发布通过  

## Agent 禁止事项

- 禁止手搓第二套 ABCD / 复制半套模块「差不多就行」  
- 禁止为了安装去改业务玩法代码（除非清单项且用户另授）  
- 禁止把 Smoke 说成运行时验收  
- 禁止索取或写入 API Key  
- 禁止假设必须依赖原生 ESFramework 游戏仓  

## 成功判据

| 项 | 期望 |
|----|------|
| `get.ps1` | 退出码 0，`DONE` |
| `Use-ESABCD.ps1` | 目标项目存在 |
| Smoke | `status=passed` |
| Checklist | 已生成 md/json |
| 身份 | 清单写明与 ESFramework 独立/可选关系 |
