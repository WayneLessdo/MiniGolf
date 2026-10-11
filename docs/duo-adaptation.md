# DUO 适配基线（Swift + UIKit）

2026-09-28 核对。本文按用户最新指令使用 Swift + UIKit，不使用 SwiftUI 或 Objective-C。布局规则来自用户要求与 Apple 官方资料，不能从附件的硬编码画布推导设备能力。

## 官方依据

| 编号 | 官方来源 | 本项目对应范围 |
|---|---|---|
| A1 | [Prepare your app for iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111461/) | size classes、scene 尺寸、独立安全区、Device Hub 开合转折 |
| A2 | [Strike a pose with adaptive layouts on iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111463/) | division / occlusion、active/inactive、系统容器与 arrangement |
| A3 | [Leverage multiple displays and scenes on iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111464/) | scene 迁移与折叠交互；布局使用区域/容器 |
| A4 | [Design for iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111466/) | 保持功能、层级与可调整尺寸布局 |
| A5 | [Positioning content relative to the safe area](https://developer.apple.com/documentation/uikit/positioning-content-relative-to-the-safe-area) | safeAreaLayoutGuide 与四边 safeAreaInsets |
| A6 | [Transitioning to the UIKit scene-based life cycle](https://developer.apple.com/documentation/uikit/transitioning-to-the-uikit-scene-based-life-cycle) | UIScene 生命周期 |

Apple 基线：以 traits 和当前空间表达布局；内屏全屏为 regular 宽高，外屏宽为 compact。安全区可能非对称。中缝是 division region，内摄为 occlusion region；平放时 division 可 inactive，内摄区域随激活状态变化。使用标准容器优先处理适配，再为自定义内容查询区域。[A1–A5]

“角度只做动效、不能改物理/奖励”是用户对 FoldPutt 的更严格产品约束，不声称 Apple 禁止所有角度玩法。

## 本机核验记录

| 项目 | 实测结果 |
|---|---|
| 桌面 | /Users/cws/Desktop 可写，临时写入/删除探针通过 |
| 工程 | 初检 /Users/cws/Desktop/FoldPutt 不存在 |
| selected developer | /Applications/Xcode.app/Contents/Developer |
| Xcode | 27.1，Build 27A9269 |
| SDK | iphoneos27.1、iphonesimulator27.1 均列出 |
| Runtime | com.apple.CoreSimulator.SimRuntime.iOS-27-1 |
| 模拟器 | iPhone Duo，available，初检 Shutdown |
| UDID | 2B7D0712-AB02-4854-86C5-7FC76DD406F5 |
| Device type | com.apple.CoreSimulator.SimDeviceType.iPhone-Duo |

证据命令：xcode-select -p、xcodebuild -version、xcodebuild -showsdks、xcrun simctl list devices available --json、xcrun simctl list devicetypes。本轮没有可运行 App，未启动/安装 App，未执行开合转折测试；“模拟器存在”不等于“适配通过”。名称带 Duo 的其他自定义测试设备不作为本次 DUO 证据。

在 iPhoneOS27.1.sdk/System/Library/Frameworks/UIKit.framework/Headers 中确认 UIViewReservedRegion.h、UIView.h、UIArrangementViewController.h、UIHingeInteraction.h、UIHinge.h 的公开声明与 iOS 27.1 availability。头文件的底层声明语言不是本项目实现语言；后续代码仅 Swift。正式 M1 要对使用的 Swift API 做一次实际编译核对，不凭翻译名称编造方法。

## 布局决策合同

| 输入 | 使用方式 | 不允许 |
|---|---|---|
| horizontal/verticalSizeClass | 选择紧凑层级或分栏内容密度 | isDuo、idiom、portrait/landscape 判断 |
| 当前 view.bounds / windowScene 的空间 | 满足最少宽度、布局重算、投影 | 固定像素画布、全局宽高、按宽高比识别姿态 |
| traitCollection.displayScale | 局部绘制清晰度/像素对齐 | UIScreen.main、缓存一份 scale |
| safeAreaInsets 与 layoutMargins | 四边独立，Auto Layout 优先 | 左右镜像、left×2、固定“安全区 24pt” |
| division/occlusion 的 frames | 内容避让、group displacement | 默认中缝位于 width/2、默认永远只有一个 region |
| UIHingeInteraction 状态/角度 | 装饰性演出强度或进度 | 布局切换、方向输入、机关开关、风力、奖励 |
| 手动偏好“控显分离” | 任意设备可请求同一功能，由可用空间排布 | 仅 DUO 可见入口或新增角度滑块 |

外屏 compact 高度可能变化（例如更矮空间）；内屏 regular/regular 也可能受窗口化影响。永远读实际 trait，不把“外/内/半折”枚举传给布局函数。半折截图只是测试条件，不是代码分支。控显分离是一个球场视图与一个控制视图的组织方式，不假设两块物理显示各自对应一个独立游戏进程。

## 容器与区域职责

- 开始/关卡/设置导航优先 UIKit 标准导航、UISplitViewController，若产品实际需要多顶级目的地再用 UITabBarController；系统负责栏位迁移，不能固定“所有状态侧边 88pt”。
- 球场与控制托盘优先 UIArrangementViewController 的分区/覆盖组织。视图按用途声明优先位置，让系统根据区域安排；不在 hinge 回调写“左/右”或“上/下”约束。
- Swift 查询名称为 view.reservedRegions(kind: .division, options: .includeInactive) 及 occlusion 查询；仅 iOS 27.1+ 可用。类型 UIViewReservedRegion。先用可用性保护；旧系统回退到标准容器+安全区，绝不模拟不存在的硬件角度。
- 默认 active 查询处理当前遮挡；includeInactive 仅作提前稳定布置与避免把关键按钮放到潜在缝中心。不能把 inactive 的零宽区域当作实体碰撞墙。
- SDK 说明 frame 在被查询 view 坐标内且已含 margins。不得把 margins 再加一遍作为硬件安全距离。跨视图时转换坐标；额外视觉留白若需要，单独标为产品间距而非官方缝宽。
- 自定义球场背景可以延伸；球/洞/关键方向反馈应持续可见，点击热区整体须留在可交互区域。把相关的控制组一起移到合适区域，不能只挪一个按钮造成手势断裂。
- 布局/trait/safe-area/scene 几何改变后重新查询，跟随 UIKit 更新周期；不能只在启动时查询一次。处理多个区域、未知/空区域、控制组可用空间不足（折叠辅助信息/标准菜单，保持主拉杆）。
- 确认/重开优先系统 alert/sheet；自定义层同样检测区域。当前无购买功能；若未来产品增加购买也不得落在缝中心。

## 中缝视觉与关卡公平性

FoldAdaptation 输出视口和可视安全区域，不输出物理参数。世界中的运河、桥或圆角墙由关卡数据定义；可在当前投影中呼应中缝，但不能因 region 移动而新增碰撞、搬球、删通路。单屏展示同一世界内容。铰链只调水纹、草叶展开、旗杆生长或非 Reduce Motion 的轻微惩罚表现。

## 生命周期与手动回退（D）

业务状态由独立会话模型保存：levelID、球位/速度、杆数、lastSafePosition、规则状态、已结算 shotID、奖励记录、随机种子与暂停计时。场景连接/断开重建视图而非重建一局。前台有效会话只有一个权威输入所有者，防止外/内屏切换双重提交。

切换时取消尚未释放的拖动，已经释放的一杆保持；scene inactive 暂停并保存，恢复不重复计时/奖励。铰链缺失、回调 nil、能力不支持时保持静态表现；开球/重播/继续/结算/控制托盘都有按钮入口，缺少传感器不影响玩法。

## 验证与替代

按 docs/screens.md 的 24 张截图及转换矩阵执行 Device Hub 开、合、转、折。普通 iPhone 负责 compact 与无铰链回退；regular 容器负责窗口化与大字测试。注入非对称 inset 和多个 regions 只验证布局算法，必须标注夹具。模拟器不能验证真实折痕光学、握持、触感和散热。

本机目前已有目标 SDK/runtime，无需下载、替换 Xcode 或额外安装。若后续不可用，采用上述替代组合并将 DUO 真正开合验证记为缺口，不编造官方设备规则。
