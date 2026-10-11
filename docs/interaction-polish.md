# 对局与选项交互优化（2026-10-09）

本轮按用户最新指令修改现有 Swift + UIKit 工程，覆盖历史“WIN 后拖杆换关”行为。原始文件保存在 `work/interaction-polish/before/`；目录没有 Git，不创建提交。未修改物理参数、关卡、资源文件或 Xcode 签名配置。

## 行为与核实依据

| 用户要求 | 本轮实现 | 代码核实 |
|---|---|---|
| WIN 后点击进入下一局 | 球场/空白处点击或结果卡原生按钮进入下一关；WIN 时禁止瞄准；拖动不当作点击；重复点击不重复换关 | FPDemoSession.canAim / continueAfterWin；共享屏幕点击识别器；FPCourseController 的继续按钮 |
| 进入一局直接展示地图 | 关卡 JSON 原本已由 session 一次性加载；新增共享图片预解码，换关取消草皮遮罩及旗杆生长，直接绘制完整球场 | FPLevel.loadAll；FPCourseView.images / refresh；两套根控制器不再在出现时自动播放 teeOff |
| 非 DUO 选项可滚动 | UIButton 触摸可被原生 UIScrollView 接管；打开选项时暂停拉杆识别，从列表顶部开始展示 | FPControlsScrollView.touchesShouldCancel；FPControlsController.toggleOptions |
| 点击列表外关闭 | 首次外部点击只收起列表，恢复控制；不同时击球或继续下一关 | FPControlsController.screenTapped / dismissOptions |
| 入洞轻微震动 | 唯一 hole-capture 事件触发原生轻触感；球场显示轻微横向抖动；触感与音效独立开关，菜单显示开关状态 | SceneDelegate.eventObserved；FPHaptics；FPCourseView.showHoleFeedback |

通过大字体截图发现并修复 FPTheme.font 的二次缩放：沿用系统 UIFont.preferredFont 的已缩放描述符，只修改字重，不再次缩放。默认字号保持一致，支持系统 Dynamic Type。

轻震参数为本轮实现建议：画面 2pt / 0.18s，light impact 强度 0.35；仍待真机手感确认，不能当作附件事实。Reduce Motion 时取消抖动与此次触感，保留静态结果；运行中设置变化会立即清理球场动画。手动“重播开球”保留草皮 0.6s、旗杆 0.4s；入洞粒子仍为 0.8s。

## 验证与证据

使用 Xcode 27.1（27A9269）、iOS / Simulator 27.1 SDK；通用回归使用 iPhone 16 Pro / iOS 18.5。

- `work/interaction-polish/Verified.xcresult`：26 项单测与 3 条正常字号、深色 UI 流程通过，覆盖 WIN 后拖动无换关、屏幕点击进入下一关零杆、列表上下滚动、外部关闭、触感独立开关及掌机模式。
- `work/interaction-polish/Final.xcresult`：最终 27/27 单测、3/3 普通字号深色 UI 流程通过。
- `work/interaction-polish/AccessibilityChecked.xcresult`：27/27 单测、2/2 最大辅助字号浅色 UI 流程（横屏/竖屏）通过，实际诊断确认 Reduce Motion=true。
- `work/interaction-polish/release.log`：Release 通用模拟器构建通过。没有第三方依赖；源码未引入 UIScreen.main、设备型号/方向/idiom 布局分支。
- 最终交付 6 张实际竖屏截图已目视检查；横屏测试截图存在黑区/裁切异常，移至 `work/interaction-polish/partial-observations/`，无法据其确认横屏视觉质量，不冒充通过。
- 模拟器已恢复原先的 dark / large / Reduce Motion=false；未修改实体设备设置。
- 单测还覆盖重复继续、非成功态点击无效、入洞事件唯一、画面反馈不改变球位置/杆数、换关无草皮遮罩、非对称四边安全区及恢复同一杆。
- DUO 当前 compact 场景的一杆入洞与点击下一关曾通过；早期列表测试的单次滑动未滚到底，随后 XCTest 结果收集停滞，主动中断并保留日志与结果。其记录为部分观察，不算完整 DUO 矩阵通过；未重置/清空模拟器。

## 截图与限制

`docs/screenshots/interaction-polish/manifest.json` 标明真实模拟器、系统/SDK、来源测试、traits、四边 safe area、系统 regions 与 Reduce Motion。正常对局与选项流程均从自动化实际触摸和实际物理产生，不使用初始位置夹具。`*-layout.txt` 为截图时根视图的调试诊断；独立 JSON 仅代表其文件的取样时刻。

本轮没有真机触感、光学/握持/温度抽样，没有完成 DUO 开合/转折/真实系统分屏矩阵，也没有把图片预解码描述为测得的帧率提升。375pt 和平板的完整视觉矩阵、VoiceOver 逐项朗读仍未验收。结果继续按钮为原生可访问按钮，默认击球仍是单指拉杆。

本轮改动清单及前后 SHA-256：`work/interaction-polish/changes.json`。未做真机安装/发布；现有关卡数据与 physics tuning 保持原样。

## 续接回归记录（2026-10-09）

本次续接针对“优化关卡衔接和选项列表”完成回归核对。`FPAdaptiveController` 已恢复按当前容器的 size classes、active horizontal division、手动掌机入口和沉浸偏好判定模式；regular 容器重新使用 `UISplitViewController`，compact/handheld/immersive 保留原有路径。未增加设备名、方向或 userInterfaceIdiom 布局分支，也未改变关卡、物理和奖励参数。

选项菜单 UI 测试在系统弹层关闭后等待弹层消失，并在菜单项点击后等待收起，降低 UIKit 原生菜单动画与下一次打开之间的时序误判。实际运行截图确认菜单底部“下一关”可见；iOS 18.5 XCTest 的系统 `UICollectionView` 可访问树仍不能稳定定位该项，因此这条自动化定位限制不作为产品缺陷结论。

本次核对结果：Xcode 27.1 / iOS 27.1 SDK Release 构建通过，29/29 单元测试通过，首洞真实拖拽、WIN 后拖动不换关、触感菜单切换两次通过。DUO 真机开合/转折/分屏、真机触感及 Device Hub 光学/握持/温度验证仍未完成。

续接后的 iOS 18.5 UI 重跑补充：三条高相关流程未能形成新的通过证据；系统原生菜单的 `UICollectionView` 可访问树无法稳定定位“下一关”和“掌机模式”，单独首洞重跑随后在 XCTest 结果收集阶段停滞并已终止。此前已保存的 `work/interaction-polish/*.xcresult` 通过结果仍是本轮行为验证依据；本次重跑只作为工具限制记录，不改变产品缺陷判断。
