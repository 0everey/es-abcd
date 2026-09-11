# 一键接入说明

## 目标

把「分析项目 → 安装 → 冒烟 → 清单」收成一次执行或一句对 AI 的话。

## 推荐话术

```text
es-abcd 在 <es-abcd根路径>，装到项目 <项目根路径>，先分析再按情况接入，出适配清单，用人话汇报。
```

## 一键脚本会做

1. 解析目标根（默认当前目录，**路径须真实**）  
2. 分析项目画像（空目录 / 已装 / Unity / 类 ES / Node / .NET 等）  
3. 按画像调整（如已装则刷新；禁止装进 es-abcd 自身）  
4. 布局检查 → 叠加安装 → 冒烟  
5. 写日常入口与适配清单  
6. 写出回执（`runtime-not-run`）

## 不做

- 不启动 Unity  
- 不写密钥  
- 不把冒烟说成 PlayMode 通过  
- 不自动改完业务代码  

## 成功长什么样

- 控制台出现完成提示  
- 存在 `project-profile.json`、`adapt-checklist-*.md`、`oneclick-*.json`  
- 画像里 `requiresESFramework` 语义为不依赖宿主 
