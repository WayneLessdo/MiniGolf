# DUO 全屏增强实施计划

本轮授权跨屏方案。Swift + UIKit，不接支付。

1. regular 默认自定义全屏画布；compact 保持旧单栏，提供沉浸球道开关；水平 active division 保留上下掌机。复用 FPAdaptiveController/FPPlayLayoutController，不把全屏内容塞进被折痕裁切的单个 arrangement 栏位。
2. 世界坐标不变，按 division 几何选择等比直立/四分之一转投影；背景铺满，球/洞/障碍同源，输入逆映射。
3. 中缝桥面可通行，两侧河岸碰撞；原有运河保留。滚动中冻结保留区碰撞。遮挡/水纹仅视觉。
4. 浮动拉杆 idle .25、aim 1；控件独立安全区避开 division/occlusion；设置与辅助功能保持清晰。
5. 测试投影/逆映射/桥面/反弹/状态连续性；结果 docs/duo-immersive.md，截图 docs/screenshots/duo-immersive。

修改 App/SceneDelegate.swift、Views/FPAdaptiveController.swift、FPControlsController.swift、FPCourseView.swift、Systems/FoldAdaptation/FPRegions.swift、Systems/Physics/FPPhysicsWorld.swift、Models/FPDemoSession.swift、Resources/Motion/FPTheme.swift、既有测试和 README/CHANGELOG。备份 work/duo-immersive/before。
