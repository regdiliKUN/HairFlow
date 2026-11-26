# HairFlow 验收清单

版本 1.6.0  
结果列：✅ = 已由屏幕控制（真实鼠标操作）或运行期回读验证，日期 2026-11-26；☐ = 仍需人工。  
用途：在真实鼠标/数位板环境下，用 10–15 分钟确认插件是否达到交付标准。

---

## A. 安装确认

| # | 检查 | 预期 | 结果 |
|---|---|---|---|
| A1 | ZBrush 2025 启动后 ZPlugin 底部有 HairFlow | 面板存在 | ✅ 2025 屏幕 |
| A2 | ZBrush 2022（先关掉 2025）启动后 ZPlugin 有 HairFlow | 面板存在（自动加载 2022 编译的 .zsc） | ✅ 2022 屏幕 |
| A3 | `C:\HairFlow` 存在 | 目录存在 | ✅ |
| A4 | 点 Diagnostics | 提示写入成功，`HairFlow_diag.txt` 出现 | ✅ 两版命令体回读 |
| A5 | 点 Open Data Folder | Explorer 打开 `C:\HairFlow` | ☐ |

---

## B. 基础交互

| # | 步骤 | 预期 | 结果 |
|---|---|---|---|
| B1 | 无模型时点 Preflight Check | 提示“no SubTool” | ☐ |
| B2 | 载入 PolyMesh，退出 Edit，点 Preflight | 提示“Edit is OFF” | ☐ |
| B3 | 进入 Edit，点 Preflight | 提示“Curve Mode is OFF”（尚未开模式时） | ✅ 2025 屏幕 |
| B4 | 点 Long Strand Curve | 笔触 > 曲线 > **曲线模式**、**捕捉** 亮起，Lazy 关，Curve Step 0.1 | ✅ 2022+2025 屏幕 |
| B5 | 点 Freehand Assist | Curve Mode 关闭；Lazy 开，Radius 10 / Step 0.25 / Smooth 4 | ✅ 两版命令体回读 |
| B6 | 点 Remember Stroke，再点 Restore Stroke | 状态回到记忆值 | ✅ 2025 屏幕 |
| B7 | 未 Remember 直接点 Restore | 只提示“先按 Remember”，不改状态 | ☐ |
| B8 | 依次点 Step Fine / Standard / Medium / Fast | 曲线步进 = 0.1 / 0.25 / 0.5 / 1，HairFlow 滑杆同步 | ✅ 2025 屏幕 |
| B9 | 用鼠标拖动 HairFlow 的 Curve Step 滑杆 | 笔触 > 曲线 > 曲线步进 同步（实测两版均为 0.61538） | ✅ 2022+2025 屏幕 |
| B10 | 点 Curve Off | Curve Mode 关闭，Lazy 状态不变 | ✅ 两版命令体回读 |
| B11 | 点 Open Manual | 默认查看器打开 `C:/HairFlow/docs/README_zh.md` | ☐ |
| B12 | 点 Reset Stroke Defaults | Curve Mode 关、CurveStep 0.25、Snap 关、Lazy 1 / 0.25 / 0；Lazy 开关不变；解除 Shape Lock | ✅ 两版命令体回读 |
| B13 | 有曲线时点 Smooth Curve / Delete Curve | Smooth 只修曲线不雕刻；Delete 去掉曲线、模型保留 | ✅ 2022+2025 屏幕 |
| B14 | 点 Curve Edit Tips | 只显示提示，不改任何设置 | ☐ |
| B15 | 点 Shape Lock | Zadd、Zsub 全灭，状态栏提示；Z 强度不变 | ✅ 2022+2025 屏幕 |
| B16 | 再点一次 Shape Lock，然后 Shape Unlock | 第二次只提示“already ON”；Unlock 恢复原来的 Zadd 或 Zsub | ✅ 2022+2025 屏幕 |
| B17 | Shape Lock 状态下点 Preflight | 提示先 Shape Unlock | ✅ 两版命令体回读 |

---

## C. 长发沟壑核心验收

准备：一个长发型 PolyMesh（至少 2 个头长的发束），选 DamStandard 或自定义发沟笔刷，调好 Size / Z Intensity / Alpha。

| # | 步骤 | 预期 | 结果 |
|---|---|---|---|
| C1 | 点 Remember，再点 Long Strand Curve | Curve Mode 亮起 | ✅ 2022+2025 屏幕 |
| C2 | 从发根一次拖到发梢 | 出现整条曲线（虚线），**不雕刻** | ✅ 2022+2025 屏幕 |
| C3 | Shape Lock 后多步拖动曲线中段调形 | 曲线弯曲，模型上**没有**任何痕迹 | ✅ 2022+2025 屏幕 |
| C3a | 对照：不锁直接多步拖动 | 留下多排点状痕迹（证明锁是必要的） | ✅ 2025 屏幕 |
| C3c | 调形途中旋转视角继续调 | 曲线贴面保持，可继续调 | ☐ |
| C3b | 拖动曲线末端 | 实测：整条曲线被拖走（不是延长）；未锁时同时压笔划 | ✅ 2025 屏幕 |
| C4 | 观察沟壑 | 单条连续，无台阶、无双线 | ✅ 2022+2025 屏幕 |
| C5 | Shape Unlock 后点 Smooth Curve | 折点变顺；不雕刻 | ✅ 2022+2025 屏幕 |
| C6 | 曲线变红时点一下提交 | 生成一条沿弯曲路径、两端收尖的连续沟 | ✅ 2022+2025 屏幕 |
| C7 | 点 Delete Curve | 曲线消失，模型保留 | ✅ 2022+2025 屏幕 |
| C8 | 点 Restore Stroke | Curve/Lazy/Step 回到初始 | ✅ 2025 屏幕 |
| C9 | Ctrl+Z | 一次撤销整次提交 | ✅ 2025 屏幕 |
| C10 | 在真实发型模型上与单笔段对比深度 | 深度一致，发梢可自然收尖 | ☐（球体上已见两端收尖） |
| C11 | 开 Symmetry 后搭曲线并提交 | 两侧镜像成形，镜像侧无接缝 | ☐ |
| C12 | 在 Layer 上 Record 后提交 | Layer 记录到一条连续笔划，隐藏/显示正常 | ☐ |
| C13 | 保存工程、关闭、重开 | 网格结果保留；插件仍加载；旧曲线可重搭 | ☐ |

**通过标准**：C3、C4、C6 已在两版通过；C10 需在真实发型模型上确认；其余允许有操作手感差异，但不能出现接缝或深度突变。

---

## D. 边界与异常

| # | 场景 | 预期 | 结果 |
|---|---|---|---|
| D1 | 在曲线外点击 | 不误提交/不删除曲线 | ☐ |
| D2 | Step 0.25 与 0.1 各提交一条 DamStandard 沟 | 0.25 珠串、0.1 连续（实测） | ✅ 2025 屏幕 |
| D3 | 高面数模型上 Fine 提交 | 记录卡顿程度（52 万面球体无明显卡顿） | ☐ |
| D4 | 切换 SubTool 后再点 Smooth Curve | 不崩溃；曲线可能丢失，需重搭 | ☐ |
| D6 | 笔触 > 曲线函数 > 快照 | 实测 DamStandard 下按钮禁用、无效果 | ✅ 2025 屏幕 |
| D5 | 2022 路径 | 12 条路径与 2025 一致，无缺失 | ✅ 2022 探针 |

---

## E. 签字

- 测试版本：ZBrush ________
- 测试人：________
- 日期：________
- 结论：☐ 通过  ☐ 有条件通过  ☐ 不通过
- 备注：
