# Arrangement 三态原型补齐计划

本轮只补可运行原型，不做完整关卡/碰撞物理。默认 Swift + UIKit；没有 SwiftUI、Objective-C 实现或第三方运行依赖。

已有：SceneDelegate、导航单栏、UISplitViewController 双区、真实 DUO 截图、11 Color Sets、9 PDF 游戏件、球旗透明 PNG、运河纹理和 AppIcon。本轮复用这些成果。

实施顺序：

1. 将 iOS 27.1+ 的 scene 导航根改为 UIArrangementViewController 子类。regular 使用 UISplitArrangement，primary 球道、secondary 操控。compact 使用 arrangement 主视图承载 UINavigationController 单栏；旧系统继续既有降级容器。
2. arrangement 依据 size classes、用户掌机偏好和真实 division 几何配置轴；不读取方向/idiom/屏幕全局尺寸/铰链角布局。保留四边 safe area 和 occlusion 避让。
3. 新建空物理协议、发射数据（速度、角度、唯一 ID）与可检查的记录型 mock 实现；会话只消费 mock 动画，不引入真实关卡系统。保留未来运河碰撞区域接口。
4. 铰链状态变化只触发开球/波纹/当前惩罚表现。Reduce Motion 关闭大动效。所有特性保留手动入口。
5. 新增草边平铺纹理及 Image Set；资源颜色沿用文档。没有图像生成工具，标明外部生图待导入，不生成伪 AI 图。
6. 构建与针对性测试；Device Hub 开/合/折/旋转实际采集三态截图，检查容器类型、放置关系、按钮与保留区域交集；普通 iPhone 降级复核。

修改：App/SceneDelegate.swift、Views/FPAdaptiveController.swift、Models/FPDemoSession.swift、Views/FPCourseView.swift、Tests/FPPrototypeTests.swift、FoldPutt.xcodeproj/project.pbxproj、README.md、CHANGELOG.md、docs/ai-image-prompts.md。

新增：Views/FPArrangementController.swift、Systems/Physics/FPPhysicsPort.swift、Tools/generate_grass_edge.swift、Resources/Backgrounds/grass-edge-tile.png、Resources/Assets.xcassets/GrassEdgeTile.imageset、docs/arrangement-delivery.md、docs/screenshots/arrangement-v2/*。

原有源码/文档副本及哈希保存在 work/arrangement-v2/before 和 baseline.json，旧截图不覆盖。开发中依据实际 SDK 和布局表现进行必要小修，并在交付文档中记录实际结果。
