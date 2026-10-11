# Physics v1 计划与文件清单

Swift + UIKit，继续使用现有 UIArrangementViewController。按用户本轮要求从 mock 升级为简化可玩物理；禁止 SwiftUI/Objective-C。

1. 复用 Assets 和生成器，补星星 1024 RGBA PNG；已有三态概念进独立 Image Set 作为美术预览，草地背景继续用于球道，概念图不作点击界面。
2. 新建 FPLevel（JSON 校验/载入）与 FPPhysicsWorld（固定步长、摩擦、反弹、矩形碰撞、水域回安全点、低速洞口吸入）。沿用 FPLaunch 输入；屏幕 y-down 与发射 y-up 在边界明确转换。
3. 3 个 JSON 分别设计为 compact 直线、regular 中缝反弹、folded 沙坑残局；三关均可在任何姿态选玩，不按设备/角度锁定。
4. division 在当前球道坐标映射为可见的边缘河岸；系统缝若位于球道外，取距其最近的球道边界并保留 JSON 走廊。每次出球前提交静态快照，运动中冻结，绘制与碰撞用同一数据。无区域时用 JSON fallback。
5. 奖惩：<par 3星、=par 2星、>par 1星；标准杆内金色加速线仅作奖励反馈，不永久强化球速。水域回最近合法停球点；超时/独立多次碰障进入一次残局，加一个经合法性检查的障碍，无可用位置则安全回退；始终免费重开。
6. 正常拖拽验证 + 自动化物理边界测试。三态各保存开球、瞄准、入洞、出界回退、中缝碰撞、惩罚截图。难以稳定自然触发的取证采用明确标注的 Debug 初始条件夹具，仍运行真实物理/规则，不直接伪造结果状态。

新增：Models/FPLevel.swift、Systems/Physics/FPPhysicsWorld.swift、Resources/Levels/01-meadow.json / 02-canal.json / 03-sand.json、Resources/Exports/star-1024.png、对应 Image Sets、Tests/FPPhysicsTests.swift、docs/physics-v1.md、docs/screenshots/physics-v1/*。

修改：FPDemoSession、FPCourseView、FPControlsController、两个适配容器的菜单/诊断、SceneDelegate、FPPhysicsPort、工程文件、现有测试、资源生成器、README/CHANGELOG。改动前副本在 work/physics-v1/before。

不做完整 3D、动态平台、多玩家、商城、付费/广告、联网账号或扩展关卡编辑器。所有阈值写入 JSON；物理只处理圆球与静态矩形，不宣称通用物理引擎。
