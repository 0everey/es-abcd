# es-abcd battle test report

> UTC: 2026-09-11T15:36:56.2348595Z
> package: F:\aaProject\es-abcd
> scratch: C:\Users\asus\AppData\Local\Temp\es-abcd-battle-20260911-153655

## 1. Clean install
- status: PASS (51020 ms)
- Use-ESABCD=True RealDivergence=True TestCount=2

## 2. Three live scenarios

### B-CRE-01 / melee-feel / creative-divergence
- status: **PASS** (5211 ms)
- engine: `real-axis-branch-v1` / 真实轴分支搜索
- delivery: 领域简报 | L1 领域交付层 | 设计候选 候选
- directions: 7 | top: **新颖度** score=76.55
- pitch: 有新意但不教不会
- keep traces: 6
  1) 第1轮保留：命中变据点（72分）
  2) 第2轮保留：目标交换（76分）
- zh receipt: `C:\Users\asus\AppData\Local\Temp\es-abcd-battle-20260911-153655\B-CRE-01\receipt-zh-20260911-153751.json` (35518 bytes)
- md brief: `C:\Users\asus\AppData\Local\Temp\es-abcd-battle-20260911-153655\B-CRE-01\commercial-brief-20260911-153751.md` (15847 bytes)

### B-CRE-02 / live-ops / creative-divergence
- status: **PASS** (6297 ms)
- engine: `real-axis-branch-v1` / 真实轴分支搜索
- delivery: 领域简报 | L1 领域交付层 | 设计候选 候选
- directions: 7 | top: **技巧上限** score=80.8
- pitch: 能练、练了有回报
- keep traces: 6
  1) 第1轮保留：完美取消（77分）
  2) 第2轮保留：位移技（79分）
- zh receipt: `C:\Users\asus\AppData\Local\Temp\es-abcd-battle-20260911-153655\B-CRE-02\receipt-zh-20260911-153757.json` (34012 bytes)
- md brief: `C:\Users\asus\AppData\Local\Temp\es-abcd-battle-20260911-153655\B-CRE-02\commercial-brief-20260911-153757.md` (13555 bytes)

### B-ENG-01 / skill-system / engineering
- status: **PASS** (3777 ms)
- engine: `real-axis-branch-v1` / 真实轴分支搜索
- delivery: 领域简报 | L1 领域交付层 | 设计候选 候选
- directions: 5 | top: **性能峰值预算** score=67.75
- pitch: 量大也不炸帧
- keep traces: 6
  1) 第1轮保留：帧预算（64分）
  2) 第2轮保留：预算探针（65分）
- zh receipt: `C:\Users\asus\AppData\Local\Temp\es-abcd-battle-20260911-153655\B-ENG-01\receipt-zh-20260911-153802.json` (25302 bytes)
- md brief: `C:\Users\asus\AppData\Local\Temp\es-abcd-battle-20260911-153655\B-ENG-01\commercial-brief-20260911-153802.md` (11352 bytes)

## 3. Axis body difference check
- scenarios differ: **True**
- templateCollision: **False** (expect False)
- engine: real-axis-branch-v1

## 4. Consumer smoke
- status: PASS (16228 ms)
- deliveryKind=domain-brief pipelineLevel=L1 runtime=runtime-not-run

## 5. Summary table

| case | status | ms | engine | dirs | top axis |
|------|--------|----|--------|------|----------|
| B-CRE-01 | PASS | 5211 | `real-axis-branch-v1` | 7 | 新颖度 |
| B-CRE-02 | PASS | 6297 | `real-axis-branch-v1` | 7 | 技巧上限 |
| B-ENG-01 | PASS | 3777 | `real-axis-branch-v1` | 5 | 性能峰值预算 |
| install | PASS | - | - | - | - |
| diff-check | PASS | - | real | - | - |
| consumer-smoke | PASS | 16228 | - | - | - |

## Conclusion

**ALL BATTLE CHECKS PASSED.** Clean install -> real axis-branch divergence -> Chinese receipt -> smoke.

Evidence root: `C:\Users\asus\AppData\Local\Temp\es-abcd-battle-20260911-153655`
