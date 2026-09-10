# ABCD 命名机器落点（es-abcd）

本页供测试与 Agent 引用；用户说明见 [concepts.md](concepts.md)。

## 环境边界（勿与 ES 宿主混绑）

| | **es-abcd（本仓）** | **ESFrameWorkPublish（宿主）** |
|--|--|--|
| 运行前提 | **脱离 ES**：无 Unity、无 AIWarnings 语料、无 AGENTS 超级语义也必须能验 | 项目内可用 AIWarnings / AGENTS / SuperSemantics / AISpace |
| 单义锁 P0 id | `es.abcd.p0.abcd-identity-mono-semantic.v1`（portable governance） | `es.aiwarning.p0.abcd-identity-no-engineering-acronym.v1` |
| Mono 测试 | `Test-ESABCDMonoSemanticAuthority.ps1` **portable 版**（查 portable 治理 + docs） | **宿主版**（查 P0 文件、RouteCatalog、AGENTS、超级语义） |
| 可共享且应同逻辑 | `Resolve-ESABCDMonoSemantic.ps1`、`Resolve-ESABCDGenerationMode.ps1`、`Test-ESABCDModeFunctionLevelMapping.ps1`（只读合同，不绑宿主） | 同左 |
| 禁止 | 为“对齐”把 mono 测试改成依赖 `Assets/Plugins/ES/AIWarnings` | 为“对齐”删掉宿主 P0/超级语义门，或要求 portable-only |

**原则：语义合同可对齐；宿主门禁各走各的。不要把两仓 mono 测试强行字节相同。**

## 裸词 ABCD（架构身份）

- 锁：`namingAuthority.monoSemanticLock`
- `semanticCardinality=1`
- `possibleModeIds=["ABCD.Dynamic"]`
- 解析：`ES/Automation/ABCD/Resolve-ESABCDMonoSemantic.ps1`
- 测试：`ES/Automation/ABCD/Test-ESABCDMonoSemanticAuthority.ps1`
- 工程四字母永非正确语义：`neverValidAsCorrectSemantic.engineering-four-letter-ABCD`

## ABCD 模式 / 功能 / 级（生成三目标）

- 合同字段：`abcdModeFunctionLevelMapping`
- 只映射：`creative-divergence` | `engineering` | `stable`
- 解析：`ES/Automation/ABCD/Resolve-ESABCDGenerationMode.ps1`
- 测试：`ES/Automation/ABCD/Test-ESABCDModeFunctionLevelMapping.ps1`
- **禁止**把 `ABCD.Dynamic` / `ABCC.Core` / `ABCP.Part` 叫成 ABCD 模式

## 合同路径

- `ES/Automation/Contracts/es-ai-abc-mode.registry.json`
- `ES/Automation/Contracts/es-ai-abc-generation-mode-v1.json`
