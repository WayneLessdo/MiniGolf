# DUO 多任务收口计划

2026-09-30。Swift + UIKit；不扩新玩法。

1. 标记历史空白图，并以 window/祖先可见性/field/实际命中补充布局诊断。
2. 将当前完整世界与奖惩进度保存到 UISceneSession 的 NSUserActivity；采用 Codable 版本快照、长度/数值/关卡校验和恢复幂等。未释放拖拽只恢复成 ready/penalty。断连停 display link。
3. 扩展现有 FPTuningTests 与 UI 流程；真实右侧 Split View 拖动不稳定时明确记录手工步骤，不用 Debug 半窗冒充。
4. iPhone 12 测试机客观验证与人工握持抽样分开。没有真实反馈不改 tuning.json。
5. 截图、诊断、日志及未决写入 docs/duo-multitask.md、docs/screenshots/duo-multitask。

修改文件：Models/FPDemoSession.swift；Systems/Physics/FPPhysicsWorld.swift、FPPhysicsPort.swift；App/SceneDelegate.swift；Views/FPArrangementController.swift；Tests/FPTuningTests.swift；UITests/FPPrototypeUITests.swift；Tools/capture_tuning.py；README.md；CHANGELOG.md；旧截图 manifest。备份在 work/duo-multitask/before。

用户真机反馈追加：WIN! 得分浮层＋SF Symbol、挥杆与入洞原生音效、设置开关；用户选择入洞后再拖直接进入下一关。增加 Systems/Rewards/FPSound.swift、Resources/Sounds/{putt,hole}.wav 和生成脚本；修改 FPCourseController、两套设置菜单、工程资源引用。保留外部 Xcode 配置的 com.mavericklab.foldputt 与开发团队。

跨屏大画布与商业化暂列 docs/duo-experience-proposal.md，未确认前不替换原有分栏，不接支付。
