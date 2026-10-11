# 地图与击球反馈优化 · 2026-10-10

本轮在现有 Swift + UIKit 正式工程上实现四项优化，并给出 12 个后续功能方向。没有引入第三方引擎或新的默认击球操作。

## 四项变化

1. **地图按钮**原本只打开当前球道的缩略图；现在打开“选择地图”菜单。普通与 Q 版均可选 **青草练习 / 运河回响 / 沙地余韵**，分别突出开阔草坪、运河挡板、沙地短墙。选图后立即重新开局，重选当前地图也会重开。三图沿用现有真实关卡数据，本轮增加的是明确可达的选择体验。
2. **墙壁与安全区**：可玩边界位于四边安全区内，再留至少 16pt 视觉间距；保留等比投影。拉杆时显出碰撞外墙、球心边界及范围外遮罩，普通/Q 共用同一物理投影。不是新增玩家调参滑块。
3. **一杆进洞**：中央卡片按真实录制轨迹 0.5× 回放，四周烟花；完整播放后再显示 WIN。可跳过演出，跳过后仍先看到 WIN。Reduce Motion 使用静态完整轨迹，运行中开启立即生效。
4. **停球反馈**：滚动时拉杆 35% 不透明度、锁标识且禁止输入；真实物理 stopped 后恢复全显与操作。Reduce Transparency 下以锁标识保留可读性。

回放过程中暂停周边 HUD 展示，防止工具栏盖住卡片。回放不会再模拟一局、重复计杆或再次奖励；切后台时暂停并保存，恢复继续该回放。顺便修复原有 sinking/resetting 计时器可能减成负数，导致合法结算快照被拒绝的问题。

## 入口和修改

- `Models/FPDemoSession.swift`：回放采样/时钟/门控、scene 保存恢复、同图重置、计时器归零。
- `Models/FPLevel.swift`：三张地图的可读说明与原生符号。
- `Views/FPControlsController.swift` / `Views/FPPullControl.swift`：地图菜单、滚动禁用视觉、WIN/回放排布及自适应。
- `Views/FPCourseView.swift`：四边安全区投影、瞄准墙线、原生轨迹卡片和烟花。
- `Views/FPAdaptiveController.swift` / `Views/FPArrangementController.swift`：移除旧缩略图入口、减少动态效果联动。
- `Resources/Motion/FPTheme.swift`：墙距、禁用透明度、采样/播放/静态停留等令牌。
- [行为规格](../specs/map-replay.md) · [12 个功能建议与参考来源](feature-directions.md)。

所有修改前原件在 `work/map-replay-20261010/before/`，差异记录在同目录 `changes.diff`；没有提交、推送或发布。

## 检查与证据

- Xcode 27.1 (27A9269)，iOS Simulator 27.1 SDK，iPhone 16 Pro / iOS 18.5 实际运行。
- **42 个单元测试通过**：`AccessibleFinal.xcresult`；包含旧输入/物理/恢复回归及新增地图、回放、停球、安全区检查。
- **普通动效 3 条 UI 测试**：两模式三图＋真实拉杆/停球/一杆回放/换关，瞄准边界夹具，以及最大字号横屏/保留区回放夹具。最终结果：`Final.xcresult`。
- **减少动态效果 2 条 UI 测试通过**：最大字号横屏/保留区静态回放、普通模式真实首洞/换关。普通模式还覆盖系统深色外观；Q 版继续沿用自身浅色主题。`AccessibleFinal.xcresult`。
- Release 模拟器构建通过；仅有未链接 AppIntents 的元数据提取提示，无编译错误。
- 截图为真实 UIKit 模拟器图像，详见 [清单](screenshots/map-replay/manifest.json)。每张保留对应 traits、四边 safe-area、regions、模式、阶段、拉杆状态和 Reduce Motion 诊断。`fixture` 文件是明确注入起始条件/暂停时间的截图夹具，不冒充真实用户击球或硬件折叠状态。
- 初次测试暴露并修复了成功局负计时恢复、大字号左右安全区遗漏和横屏回放文字相互覆盖。失败日志保留在 `work/map-replay-20261010/`，最终截图与结果覆盖修正版本。

## 本轮未测

Device Hub 的电脑 UI 访问因 Mac 锁屏、自动解锁失败而不可用，因此未完成 DUO 本轮实际展开/合拢/转折、系统分屏及真机安装。模拟保留区只证明注入几何下的避让，不证明 DUO 硬件读数。真机光学、握持、触觉、温度、完整 VoiceOver 操作和 375pt 小屏实际运行未验收；已有单元布局覆盖不能替代这些设备检查。
