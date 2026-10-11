# MVP 三阶段文件与验收

当前：M0 文档/空骨架交付。用户已将默认栈修订为 Swift + UIKit；不使用 Objective-C/SwiftUI。仍遵守“本轮只规划，确认后再开工”。以下所有 .swift/.json/.xcodeproj/测试文件均为未来清单，尚未创建。

## M1 — 可启动 UIKit 壳与交互/适配验证

目标：在 iPhone Duo 和普通 iPhone 上验证唯一拉杆与布局，不实现完整对局物理。渲染层先使用占位球场；最低系统版本、bundle identifier 与渲染路径开工时确定。

| 计划文件 | 职责 |
|---|---|
| FoldPutt.xcodeproj/project.pbxproj | Swift UIKit app/test targets，iOS 27.1 SDK，deployment target 待定 |
| App/AppDelegate.swift、SceneDelegate.swift、Info.plist | UIScene 生命周期与启动 |
| App/RootViewController.swift | 标准容器与导航组合 |
| Views/HomeViewController.swift、LevelListViewController.swift、GameViewController.swift | 开始/关卡/占位球场页面 |
| Views/PullControlView.swift、HUDView.swift、ResultViewController.swift、PenaltyView.swift、SettingsViewController.swift | 单拉杆、五状态与必要出口 |
| Models/GameSession.swift、GamePhase.swift、ShotIntent.swift | UI 状态、会话、不可变击球意图 |
| Systems/Input/PullInputController.swift | 单指方向/力度/取消/唯一提交 |
| Systems/FoldAdaptation/LayoutContext.swift、ReservedRegionProvider.swift、AdaptiveContainerController.swift | traits/scene/四边安全区/区域/标准容器 |
| Resources/Colors/FPColors.swift、Fonts/FPFonts.swift、Motion/FPMotion.swift | 语义令牌、字体、四项强制时长 |
| Tests/PullInputTests.swift、LayoutContractTests.swift | 有意义的提交/取消边界与不对称避让测试 |

验收：两类设备可启动；一次拉杆松手产生一个 ShotIntent，零力度/取消零事件；default/aiming/charging/success/penalty 可由开发状态夹具显示；无多滑块/PUTT/旋球；Xcode build 与针对性测试通过。所有按钮热区避开活跃 region 与潜在缝中心；字号扩大后不丢主操作。Device Hub 真实开合转折并保留状态。M1 无可玩物理，不用假运动展示冒充 M2。

## M2 — 最小可玩闭环与轻量规则

目标：让附件已有的直线、一次反弹、沙坑/出界安全点题型组成短练习集，完成拉杆→球滚动→入洞/回安全点→结果。不扩展高级机关。

| 计划文件 | 职责 |
|---|---|
| Models/LevelDefinition.swift、BallState.swift、HoleResult.swift | 关卡、球与结果数据 |
| Systems/Physics/PhysicsWorld.swift、CollisionResolver.swift、TrajectoryPreview.swift | 运动/碰撞/短预测线（实现方式随渲染层评审） |
| Systems/Rewards/RewardRules.swift、PenaltyRules.swift | 星级/轻残局与幂等奖励 |
| Systems/SessionStore.swift | 本地存档/迁移，单个权威会话 |
| Resources/Levels/meadow-straight.json、meadow-bank.json、meadow-sand.json | 三类关卡草案；数值经试玩定稿 |
| Views/CourseView.swift | 接入已确认的渲染路径；不预先承诺完整 3D 引擎 |
| Tests/PhysicsScenarioTests.swift、RewardRulesTests.swift、SessionContinuityTests.swift | 安全点、事件顺序、重复奖励与切屏持续性 |

开工依赖：确认加速线语义、额外球用途、星级分档、限时/多碰障阈值。未确认时保持明确待定，不悄悄新增养成/消费机制。

验收：有效松手恰好计一杆，球可停止并合法入洞；出界回最近安全点；超时/多碰障进入轻残局，继续仍是同一拉杆；星级/加速线/额外球按确认规则验证，奖励不成为生命墙。暂停/恢复与切屏不丢状态；同一结果不重复奖励。普通 iPhone 与 DUO 的同一世界场景规则一致，无角度到物理/计分依赖。无广告/付费依赖与网络必需链路。

## M3 — 沉浸、动效、无障碍与验收包

目标：打磨草地、镜头与入洞；完成真实三态证据，不扩大玩法系统。

| 计划文件/交付物 | 职责 |
|---|---|
| Systems/FoldAdaptation/HingeEffectsController.swift | 角度只修饰演出，nil/无能力回退 |
| Systems/Presentation/MotionCoordinator.swift、FeedbackController.swift、CameraDirector.swift | 时序、声音/触感、镜头与 Reduce Motion |
| Views/ReplayView.swift（可选） | 若时间允许加入球路回放；不阻塞基础结果页 |
| Resources/Colors/Assets.xcassets、Resources/Motion/motion-notes.md | 真实主题素材及演出编排 |
| Tests/MotionPolicyTests.swift、UITests/AdaptiveFlowUITests.swift | Reduce Motion 状态、手动等价入口和关键 UI 流程 |
| docs/verification/screenshots/、manifest.json、acceptance.md | 24 张基准截图、转态录像索引、实测与未测清单 |

验收：草皮 0.6s/旗杆 0.4s/粒子 0.8s/红边 0.3s 统一令牌；Reduce Motion 在运行中切换也生效；无背景运动依赖的关键反馈。完成 docs/screens.md 的三态/旋转/分屏/非对称/内摄区域矩阵（不可触发的项如实留缺口）。10 人首次拉杆与教学洞目标做实测记录。设备不支持铰链仍能手动重播、控显分离、完整玩。性能记录真值与测试条件，不用模拟器宣称真机 120fps/温度达标。

## 阶段交付共同要求

每阶段更新 CHANGELOG、记录 SDK/build/commit、运行相应测试，列出失败与未测项。只对实际改动补必要测试，不为文档/常量逐字镜像写测试。若追加引擎或变更语言先按用户明确选择调整计划。排期当前按依赖顺序，不给未经评估的工日承诺。
