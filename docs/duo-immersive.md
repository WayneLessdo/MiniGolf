# DUO 全屏增强交付

2026-09-30。Swift + UIKit，Xcode 27.1 / iOS 27.1 SDK。本轮落实用户已确认的跨屏方案，无广告、付费或第三方依赖。

## 当前行为

- **展开 regular 默认全屏球道**：一个画布覆盖整个内屏，两侧不再各占一个独立面板。草地背景覆盖 100% 视口；等比球场在本轮横版 DUO 上覆盖约 95% 宽、96% 高，余量是球场边缘。
- **浮动拉杆**：底部控件选择安全区内不穿过 division/occlusion 的连续区域。闲置/松手后圆环为 25% 可见度，瞄准时 100%；背景随之变淡/清晰。分数、文字与按钮维持可读。VoiceOver/Reduce Transparency 下保持清晰，Reduce Motion 不使用淡入淡出。
- **中缝桥面**：系统返回的真实中缝区域绘制为运河，中央通行区可穿过，两侧河岸仍是实体障碍，原关卡运河也保留。球过缝有轻微遮挡、缩放与水纹；这些效果不改球速、得分或输入。
- **半折**：书本式仍可用跨屏画布；水平 active division 对应上画面下操控。手动“掌机模式”保留。
- **通用版**：compact 默认原单栏；“设置与演示 → 沉浸球道”可手动体验全屏，关闭可回普通布局。没有按设备型号锁功能。
- WIN、音效、入洞后拖杆进下一关、增益、残局与 scene 恢复继续保留。

## 投影和状态规则

世界仍为原关卡的 1×1.4 坐标，不因展开而重置。竖向 division 对应四分之一转的等比投影，使球从一侧打到另一侧；横向 division 使用直立等比投影。这里只读取保留区几何，不读取设备方向或 idiom。

球、洞、障碍、箭头、预测线共用同一 scale；拉杆与直接拖球使用逆映射，避免非等比拉伸改变反射角。桥面通行宽度 0.32 是游戏世界尺寸，不是虚构硬件中缝宽度。硬件区域大小来自 reservedRegions。

保留区碰撞在一杆滚动期间冻结。切换布局仅取消未释放拖动；不会清杆数、launch UUID 或世界状态。移除旧保留区后清理旧接触 ID，避免合法存档被误判；也兼容旧版停球累计多出一个积分步的快照。

全屏球场采用 `UINavigationController + FPPlayLayoutController` 的自定义画布路径，避免标准分栏把一个全屏球场裁在单侧。退出沉浸模式仍可用标准 `UISplitViewController`；原 `FPArrangementController` 文件保留，但不再是全屏主路径。这是用户本轮确认的布局替换。

## 修改文件

```text
App/SceneDelegate.swift
Views/FPAdaptiveController.swift
Views/FPControlsController.swift
Views/FPCourseView.swift
Views/FPPullControl.swift
Systems/FoldAdaptation/FPRegions.swift
Systems/Physics/FPPhysicsWorld.swift
Models/FPDemoSession.swift
Resources/Motion/FPTheme.swift
Tests/FPTuningTests.swift
UITests/FPPrototypeUITests.swift
Tools/capture_tuning.py
README.md / CHANGELOG.md
docs/duo-immersive-plan.md / duo-immersive.md
docs/screenshots/duo-immersive/
```

备份：`work/duo-immersive/before/`。物理调参文件 `Resources/tuning.json` 未改变。

## 验证

- **24 单测通过**：`work/duo-immersive/FinalUnit.xcresult`，含等比/逆映射、桥面通行、河岸反弹、滚动冻结与保存恢复。
- **6 条 UI 流程分次复核通过**：沉浸切换、真实拉杆跨缝入洞/下一关、半窗夹具保持杆数、音效/掌机菜单、正常增益→真实超时残局、后台终止重启同杆恢复。
- 沉浸切换见 `duo.log` 的对应通过用例；入洞/半窗/菜单见 `duo-regression.log` 的对应通过用例；增益残局修复后通过见 `DuoFlow.xcresult`；恢复复测通过见 `verified.log`。部分旧整包含失败尝试，不能笼统称每个历史包全绿。
- 全屏空闲时不再反复重绘整片草地，布局和诊断也减少重复工作。第一次真实超时 UI 失败后，这一项已修复并复测通过。
- Release 与真机签名构建通过：`release-delivery.log`、`device-delivery.log`。
- 截图中所有可见按钮均未与系统保留区相交。

## 截图

目录：`/Users/cws/Desktop/FoldPutt/docs/screenshots/duo-immersive/`。

| 文件 | 说明 |
|---|---|
| duo-fullscreen-live.png | 正常新对局的真实内屏全屏截图，无初始条件夹具 |
| duo-open-tee-off.png | 开球/闲置拉杆 25% |
| duo-open-aiming.png | 蓄力/拉杆全显 |
| duo-seam-crossing.png | 真正物理步进过桥，球位在中缝内，有遮挡与水纹 |
| duo-seam-collision.png | 河岸碰撞事件 |
| duo-win-final-hole-success.png | 入洞结果 |
| duo-book-aiming.png | 真实书本半折、跨屏画布 |
| duo-table-tee-off.png | 真实台式半折、上下控显 |
| duo-portrait-final-aiming.png | 竖向全开，同样覆盖两侧区域 |

除 live 图外，其余使用明确标注的初始条件夹具，物理事件由实际引擎产生；设备姿态和 reserved regions 来自真实 DUO 模拟器。逐图 JSON 保存 mode、field、activeDivision、reservedBanks、pullAlpha、ballUnderFold 和按钮越界检查。不能将这些图声称为 DUO 真机照片。

## 剩余验证

DUO 真机折痕观感、长期发热/功耗、超大字体以及实际系统右半窗压力测试仍未覆盖。本轮完成全屏体验，未新增收费逻辑或完整关卡系统。
