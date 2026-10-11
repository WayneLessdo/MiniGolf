# 本轮原型实现计划

2026-09-29；用户已授权“继续”。Swift + UIKit，无 SwiftUI/Objective-C，无第三方运行依赖。

1. 新建 iOS App、共享 scheme、SceneDelegate；最低 iOS 18，使用本机 27.1 SDK。
2. compact 使用 UINavigationController 单栏；regular 使用 UISplitViewController，球道在右、操控在左；掌机以同一模型上画面下控制。读取真实 traits、安全区、division/occlusion，角度只做演出。
3. 单拉杆输入提交 mock 出球；可从菜单演示入洞和惩罚，无完整物理、关卡系统或商店。原型明确标注演示。
4. 用 Swift/AppKit 生成 PDF 矢量、透明球/旗 PNG、周期运河纹理、无透明 AppIcon。Color Sets 和令牌沿用文档。
5. 无可用内置生图工具，按用户指定退路提供 docs/ai-image-prompts.md；AIConcepts 目录不放伪造的 AI 图。
6. 编译、单元/UI 行为检查、模拟器三态截图。真实 DUO 操作若有环境限制，明确标注手动/夹具，不冒充真机/Device Hub 实测。

新增文件：App/*.swift + Info.plist，Models/FPDemoSession.swift，Views/FP*.swift，Systems/Input/FPPullMath.swift，Systems/FoldAdaptation/FPRegions.swift，Resources/Motion/FPTheme.swift，Resources/Assets.xcassets，Resources/Exports，Resources/Backgrounds，Tools/generate_assets.swift，Tools/create_project.py，FoldPutt.xcodeproj，Tests、UITests、docs/prototype-runbook.md、docs/assets-manifest.md、docs/ai-image-prompts.md、docs/screenshots。

已有 11 份 Markdown 文件暂不修改；完成后提供 README/CHANGELOG 的具体更新内容供确认。当前计划与本次用户要求优先于旧 M0 停点。
