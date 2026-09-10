# es-abcd v1.0.0

Portable ABCD/ABCC engineering core — first GA release.

## Install (natural language)

Tell your AI (use **your** absolute paths):

```text
es-abcd 在 <es-abcd根路径>，装到项目 <项目根路径>，先分析项目再按情况接入，出适配清单，用人话汇报。
```

Or:

```powershell
powershell -File <es-abcd>\get.ps1 -TargetRoot <项目根路径>
```

## What you get

- Adaptive project analysis (`project-profile.json`)
- Overlay install + smoke + adapt checklist
- Three modes with 15 copy-paste real scenarios in README
- Portable governance (no ESFramework host required)

## Verify

```powershell
powershell -File .\scripts\Test-ESABCDPackageLayout.ps1
powershell -File .\scripts\Invoke-ESABCDAutonomySuite.ps1
```

## Non-claims

Smoke/autonomy ≠ Unity PlayMode ≠ ship-ready game content.
