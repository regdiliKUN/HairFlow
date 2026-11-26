# HairFlow FAQ

## 1. 为什么不做成“画两段自动焊在一起”？

因为“焊”仍然要猜两段的深度、taper、法线和重叠量；猜错就把接缝换成补丁。  
HairFlow 用原生 Curve 把“段”变成同一条曲线的控制段，最终只提交一条笔划，接缝没有机会出现。

## 2. 2022 面板里找不到 HairFlow / 2022 启动就退出？

1.6.0 起安装脚本会给 2022 装它自己编译的 `HairFlow.zsc`（49204 字节），不需要再手动 Load。本机实测：**2025 开着时启动 2022 会报 Unable To Open File 并退出**，先关掉 2025 即可。

以下为旧说明（仅在你改了源码时需要）：


ZBrush 只自动加载 `.zsc`，不会自动加载 `.txt`。  
在 2022 中打开 **ZScript > Load**，选择 `ZStartup\ZPlugs64\HairFlow.txt`，生成 `.zsc` 后重启。  
如果 2022 启动就报 `Unable To Open File`，先确认 ZBrush 2025 没有在运行。

## 3. 点了 Long Strand Curve，但画不出曲线？

按顺序检查：

1. 是否加载了 PolyMesh3D 并进入 Edit（按 T）；
2. 当前笔刷是否为 3D 雕刻笔刷（不是 Move/Transpose）；
3. Stroke > Curve 子面板里 **Curve Mode** 是否亮起（1.4 及以前的版本不会把它打开，请升级）；
4. 是否只在模型表面点击/拖动。

可以直接点 **Preflight Check** 看前两项。

## 4. 以前的 Add Curve Point 按钮去哪了？

ZBrush 里没有“给曲线加点”的原生按钮，也没有 `Stroke > Curve Functions` 子面板。  
1.4 及以前的 Add 按钮写的是 `Stroke:Curve Functions:Add`，ZBrush 的路径查找把它解析成了 **`Stroke:Inventory:Add`**（笔划库的“添加”）——按下去并不会给曲线加点。1.5.0 删除了它，换成只显示提示的 **Curve Edit Tips**。  
正确做法：一次拖出整条路径；要改形状先 **Shape Lock** 再拖动曲线弯曲，**Shape Unlock** 后点一下曲线提交（见第 17 题）。

## 5. 调形后沟壑出现台阶/折角？

- 点 **Smooth Curve** 1–3 次；
- 确认 **Curve Snap On**；
- 每次拖动幅度不要太大，宁可多调几处；
- Curve Step 保持 Standard（0.25）或 Fine（0.1）；Step 太大也会让沟看起来一节一节的。

## 5.1 为什么 1.4 的“Long Strand Curve”好像没用？

1.4 写的是 `Stroke:Curve`——那是 Curve **子面板**本身，写 1 只是把子面板展开，**Curve Mode 仍然是关的**（2025.0.1 回读：写入后 Curve Mode=0）。1.5.0 改为 `Stroke:Curve:Curve Mode`，回读为 1。

## 6. 接缝还是看得见？

如果你用的是 **Freehand Assist**，接缝是自由手绘的固有问题：  
重叠扩大到 15%，保持 Z Intensity 稳定，接缝处按住 Shift 用 Smooth 轻扫 2–3 次。  
要彻底消除，改用 **Long Strand Curve**。

## 7. 为什么不能调“沟壑深度”？

深度由笔刷的 **Z Intensity / Imbed** 决定。插件再乘一个系数，会破坏你已经调好的手感，也让接缝深度不可预测。  
HairFlow 只改 Stroke 状态，不改笔刷深度。

## 8. 长曲线很卡怎么办？

- 降低密度：用 **Step Medium**（0.5），必要时 **Step Fast**（1），提交前检查点状；
- 先搭完整条发流，再局部细化；
- 暂时隐藏不相关 SubTool；
- 提交后点 **Delete Curve**，不要让旧曲线一直参与重算。

## 9. 提交后想反悔？

ZBrush 自身 Undo 可以回退提交。  
插件不接管 Undo，也不做隐藏历史；提交前建议先 **Remember Stroke**，方便恢复 Stroke 状态。

## 10. 可以用于 DynaMesh / 高模吗？

可以，只要它是可雕刻的 PolyMesh3D。  
高模上 Curve 的每次调整都会重算整条笔划，建议调形时用 Medium，提交前切回 Standard。

## 11. 为什么插件界面是英文？

ZScript 编译器对非 ASCII 字面量不稳定，中文可能被吞掉。  
插件保持 ASCII 英文短标签，中文说明放在文档里；按钮含义见 README 第 3 节对照表。

## 12. 插件会改我的笔刷预设吗？

不会写回笔刷预设。  
`Remember / Restore` 只临时改 Curve / Lazy Mouse 等 Stroke 状态；Draw Size、Z Intensity、Alpha、Focal Shift 均不修改。

## 13. 可以配合 Symmetry 吗？

可以。先开好 Symmetry，再搭曲线；提交时会按对称轴生成镜像沟壑。  
建议先用短曲线确认两侧落点，再延伸到发梢；两侧表面曲率差异大时，镜像侧可能需要单独补一次。

## 14. 可以记录到 Layer 吗？

可以。Curve 提交仍然是一条普通笔划，提交前在 Layer 面板点 Record 即可。  
插件不碰 Layer，也不会替你新建/合并层；分层策略仍由你控制。

## 15. 为什么 Curve Step 预设改成了 0.1 / 0.25 / 0.5 / 1？

2025.0.1 实测：Curve Step 原生范围 0–10，**默认 0.25**，数值是笔刷点之间的间距——越小越密。1.4 把 1 当“最细”、10 当“最快”，实际上 1 已经比默认稀 4 倍，10 基本是一串断开的点。

## 16. Reset Stroke Defaults 为什么不再把 Lazy Mouse 打开？

Lazy Mouse 开关是跟着笔刷走的（不同笔刷出厂设置不同），统一改成 ON 反而会覆盖你的笔刷习惯。1.5.0 起只把 Lazy Radius / Step / Smooth 恢复为 2025.0.1 启动实测值 1 / 0.25 / 0。

## 17. 为什么要 Shape Lock？不能直接拖曲线调形吗？

屏幕实测：Curve Mode 下拖曲线时，**每个鼠标移动事件都会沿曲线压一次笔划**，多步拖动会留下多排点状痕迹。Shape Lock 临时关掉 Zadd/Zsub（Z 强度不动），拖动只改曲线形状；Shape Unlock 把 Zadd/Zsub 恢复成原样，再在曲线上点一下，只压一次。

## 18. 忘了 Shape Unlock 会怎样？

笔刷什么都画不出来（Zadd/Zsub 都关着）。点 **Shape Unlock** 或 **Restore Stroke**（会顺便解锁）；Preflight 也会提醒。Shape Lock 连按两次不会覆盖记住的原值。

## 19. 点了曲线但没压出沟？

先确认 Shape Lock 已解除；然后等曲线变红高亮再点。实测完全静止的点击不提交、按下后移动 1 像素就提交，真人点击通常没问题，偶尔不行就按住轻轻一动再松开。

## 20. Curve Off 和 Delete Curve 有什么区别？

- **Curve Off**：只把 Curve 模式关掉，曲线可能还在，Lazy 状态不变；
- **Delete Curve**：删除当前曲线本身，模型上的已提交结果保留。

提交完建议先 Delete Curve，再决定是否 Curve Off。
