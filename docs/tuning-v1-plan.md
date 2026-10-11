# Tuning v1 实施计划

从 Physics v1 继续；Swift + UIKit，无 SwiftUI/Objective-C、新依赖或设备型号判断。改动前副本位于 work/tuning-v1/before。

1. 新增 Resources/tuning.json 与 Models/FPTuning.swift，校验后载入 compact/regular 输入参数、物理材质、洞口捕获和增益参数。统一两种输入入口，力度环同步三档颜色与语义值。
2. 指数阻尼替代恒定减速；统一镜面反射再衰减整个速度向量，避免斜撞时只缩法向导致反射角变化。草/沙/河岸采用独立阻尼/回弹系数。洞口距离+剩余速度双阈值。
3. 加速线使用真实世界副本生成的限时预测虚线，不永久改变球速；本关有效、结算清零，记录本地 variant 维度的触发/使用/过期计数。星级在结算才出现，触发时机已向用户询问；未回复前先做独立调参与布局工作。
4. regular 分栏显式 UISplitArrangement.axes(.horizontal)，secondary 不可见时采用 overlay 或掌机等价；所有分支依赖 traits/系统 arrangement 状态/regions，而不是方向、idiom 或角度。切换不重置 world、stroke、launch ID。
5. 扩展现有 XCTest / UI 流程，不新建测试框架。Device Hub 检查闭合、横竖全开、Book/台式、开合旋转；尝试系统左右 Split View；不可操作时用明确标注的半窗夹具并列未测项。
6. 参数表、行为说明、变更清单与真实/夹具截图统一写 docs/tuning-v1.md 和 docs/screenshots/tuning-v1/。

新增：Models/FPTuning.swift、Resources/tuning.json、Tests/FPTuningTests.swift、docs/tuning-v1.md、取证脚本/截图。修改：FPPullMath/FPPullControl/FPCourseView、FPPhysicsWorld、FPDemoSession、FPArrangementController、原有测试、工程资源引用及 README/CHANGELOG。
