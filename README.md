# FoldPutt 项目结构

Swift/UIKit 工程按业务功能分目录，功能内按 MVC 职责放置。Gameplay 和 Club 各自包含 Model、View 或 Controller；公共设备适配、输入、反馈和主题收在 Core；单测和 UI 测试按功能归档。Xcode 导航器与磁盘目录保持一致。

[目录结构和文件职责](docs/code-organization.md)

---

# App 内五语适配（2026-10-22）

已接入 tr、ar、pt、fr、es，保留简体中文；包含195项文案、离线政策、RTL与长文本适配。iPhone92条不同用例均有通过证据，iPad4条、小屏深色3条及导航修复补测2条通过，最终Release构建成功。

[实现、真实截图与验证边界](docs/localization-20261022.md) · [本地化资源](Resources/Localization/) · [切换与维护说明](docs/language-switch-20261022.md)

---

# 发布准备（2026-10-22）

政策与支持页已公开部署，联系方式统一为 `waynelessdo@gmail.com`。[隐私政策](https://foldputt-help-wayne.humble-mite-6617.chatgpt.site/privacy) · [用户支持](https://foldputt-help-wayne.humble-mite-6617.chatgpt.site/support) · [国际上架语言规则与操作步骤](release/国际上架语言与操作步骤.md)。商店语言不等于 App 内语言，现已加入五语与简体中文切换。

已补齐隐私清单与离线政策入口，修复发布回归失败，保留 iPhone、iPad 与 Duo。iPhone 全量 80 项通过；iPad 关键流程、Duo 实际开合/旋转/两种半折及滚动中合拢续球已验证。提供 19 张商店实图、中英文文案和可托管的政策/支持页。

[后台逐项填写清单](release/App-Store-Connect-填写清单.md) · [完整物料 ZIP](release/FoldPutt-AppStore-20261022.zip) · [实施、验证与剩余阻塞](docs/release-prep-20261022.md)

正式 Xcode 分发签名/上传验证和后台真实资料仍需完成，当前不承诺明天公开上架。以下为历史交付。

---

# DUO 适配更新（2026-10-11）

修复未激活折痕挤压内容、系统区域重复留白，以及窗口变化后收藏阅读位置丢失。非 DUO 两种画风基准截图保持像素一致，54 单测、普通 iPhone 5 条课题/收藏流程与 DUO 展开内屏 5 条流程通过。[适配报告与验证边界](docs/duo-fit-20261011.md)

---

> 仓库目录已更名为 `MiniGolf`；Xcode 工程与 Scheme 仍为 `FoldPutt`。历史记录中的旧绝对路径需替换为当前项目根目录。

# 三个新玩法已接入原生 App（2026-10-11）

点击球场工具栏叶子按钮 **“玩法与收藏”**：六张反弹课题、九格三花种花园、六类事件十二句语录。真实通关得种子，收藏自动保存；普通/Q 共九张地图，继续使用单指拉杆。

[交付与操作](docs/club-native-delivery.md) · [玩法规格](specs/club-native.md) · [真实 UIKit 截图](docs/screenshots/club-native/manifest.json)

50 单测、四条 iPhone UI 流程、最大字号横竖屏补测、DUO 当前屏幕真实反弹流程与 Release 构建通过。DUO 开合/转折受锁屏限制未测。以下为历史交付。

---

# 12 个方向可玩体验馆（2026-10-10）

直接打开 [FoldPutt · 好玩研究所](prototype/play-club/FoldPutt-好玩研究所.html)：实际拉杆击球，体验种花、明信片、双人赛、个人幽灵和地图编辑器等 12 个方向。喜欢的玩法可加入候选、评分并导出下一版清单。

[打开与操作说明](prototype/play-club/README.md) · [12 个体验循环与验证边界](docs/play-club-delivery.md) · [真实浏览器截图](docs/screenshots/play-club/manifest.json)

本轮是独立浏览器交互方案，正式 Swift/UIKit 功能等待体验后选择。93 项完整流程＋18 项补测通过。以下为此前交付记录。

---

# 地图选择与一杆精彩回放（2026-10-10）

普通/Q 两种模式均可直接选择三张地图，选图即重新开局。拉杆时展示安全区内的真实墙壁边界；滚动时拉杆半透明锁定，停球后恢复。一杆进洞先播放真实轨迹慢放＋烟花，再展示 WIN，支持减少动态效果和 scene 恢复。

[交付与验证](docs/map-replay-delivery.md) · [12 个新增功能方向](docs/feature-directions.md) · [实际截图清单](docs/screenshots/map-replay/manifest.json)

42 单测、5 条 UI 流程和 Release 构建通过。DUO 实际开合验证本轮受 Mac 锁屏限制。下方为历史交付记录。

---

# 非 DUO 已选 B，DUO 三套独立候选（2026-10-09）

DUO 1 跨屏沉浸 / DUO 2 两翼环抱 / DUO 3 边缘收纳，采用同一展开内屏历史采样画幅比较。[方案与依据](docs/duo-design-options.md) · [效果图清单](docs/screenshots/duo-design-options/manifest.json)

当前仍为设计预览，未替换正式游戏。

---

# 独立选项弹窗与三套全屏地图方案（2026-10-09）

正式工程的选项现用系统弹出菜单，不再挤占拉杆面板。A/B/C 全屏地图、周边 HUD 与拖杆显隐交互已制作成独立方案预览，等选定后再落地正式界面。

[交付与验证](docs/fullscreen-options.md) · [预览启动方式](prototype/fullscreen-v1/README.md) · [效果图清单](docs/screenshots/fullscreen-options/manifest.json)

---

# 对局交互优化（2026-10-09）

WIN 后点击屏幕或结果卡进入下一关；地图换关即完整展示；选项可上下滚动、点外部关闭；入洞新增轻抖动和独立触感开关。支持 Reduce Motion，并修复 Dynamic Type 字体重复缩放。

[变更与验证](docs/interaction-polish.md) · [实际运行截图](docs/screenshots/interaction-polish/manifest.json)

以下为历史交付记录，其中“拖杆进入下一关”已由本轮用户指令覆盖。

---

# DUO 全屏增强（2026-09-30）

DUO 展开默认全屏球道；底部浮动拉杆闲置 25%、拖动全显；中缝桥面可穿过，两侧河岸碰撞。半折掌机、普通 iPhone、WIN/音效和进度恢复保留。

[交付与验证](docs/duo-immersive.md) · [截图清单](docs/screenshots/duo-immersive/manifest.json)

设置中的“沉浸球道”可开关；包名仍为 com.mavericklab.foldputt。以下为历史记录。

---

# 多任务与真机反馈（2026-09-30）

已加入按 UISceneSession 隔离的进度恢复、WIN 得分卡、可关闭挥杆/入洞音效，以及入洞后拖杆进入下一关。最新 22 单测＋4 通用 UI 测试通过，iPhone 12 已签名安装最终版。

[本轮变更与验收](docs/duo-multitask.md) · [真实截图清单](docs/screenshots/duo-multitask/manifest.json) · [真机手感抽样](docs/feel-sampling.md) · [DUO 跨屏与通用分发方案](docs/duo-experience-proposal.md)

本轮新的右側系统 Split View 链路因 27.1 模拟器迁移失败未完成；不冒充通过。物理 tuning.json 保持 easy-v1-A。跨屏主布局和商业化仍是待确认方案。

以下为历史记录。

---

# Tuning v1（2026-09-29）

Swift + UIKit。已加入易上手参数、指数摩擦、材质回弹、快慢球捕获和同关重试预测线。Xcode 27.1 / iOS 27.1 SDK 构建通过，最终 16 项单测、4 项 UI 测试通过。

完整参数表、变更文件树、奖励语义和截图矩阵见 [Tuning v1 交付](docs/tuning-v1.md)。截图见 [目录清单](docs/screenshots/tuning-v1/manifest.json)。解锁后已修复半折冷启动和展开遮挡，补测真实左 Split View 与开合结算连续性；真实右半窗和真机长时间测试仍未完成，半窗夹具不等于系统 Split View。

以下为历史记录。

---

# Physics v1（2026-09-29）

当前版本已从 mock 升级为简化 2D 可玩物理：3 个 JSON 关卡、摩擦/反弹/静态障碍/洞口捕获、出界回安全点与一次轻残局；仍为 Swift + UIKit / UIArrangementViewController，无广告无付费。

本轮文件、资源与截图见 [Physics v1 交付](docs/physics-v1.md)。工程仍为 FoldPutt.xcodeproj / Scheme FoldPutt，iOS 27.1 SDK，最低部署 iOS 18。

下方 mock/空骨架内容为历史版本记录，不代表当前实现。

---

# 当前可运行原型（2026-09-29）

Swift + UIKit，禁用 SwiftUI / Objective-C 实现。Xcode 27.1 + iOS 27.1 SDK，最低 iOS 18.0。

打开 `FoldPutt.xcodeproj`，选择共享 Scheme `FoldPutt` 和 iPhone Duo。27.1 导航根已升级为 `UIArrangementViewController`；primary 球道，secondary 操控。compact 单栏、regular 双区与系统折叠区域/手动掌机共用会话。

本轮只有 mock 出球与空物理接口（速度/角度输出），没有完整关卡/碰撞物理。资源和三态证据见 [本轮交付](docs/arrangement-delivery.md)；构建命令见 [运行手册](docs/prototype-runbook.md)。下方空骨架说明是 M0 历史记录。

---

# FoldPutt

迷你高尔夫 iPhone / iPhone Duo 应用规划工程。根目录：/Users/cws/Desktop/FoldPutt。

**当前只有文档与空目录，没有可运行 Xcode 工程，也没有游戏物理。** 默认技术栈已按用户后续修订改为 **Swift + UIKit**；不使用 Objective-C、不使用 SwiftUI。完成本轮后等待用户确认进入开发阶段。

## 阅读顺序

1. [AGENTS.md](AGENTS.md)：语言、输入、DUO、交付硬约束。
2. [产品与冲突处理](docs/product.md)：附件内容与用户要求的取舍。
3. [单手势映射](specs/input-control.md)：机制难度与简化替代。
4. [UI 提示词库](docs/ui-prompt-library.md) / [设计令牌](specs/theming.md)。
5. [DUO 适配](docs/duo-adaptation.md) / [页面状态与截图计划](docs/screens.md)。
6. [物理奖惩](specs/physics-rewards.md) / [MVP 三阶段](specs/milestones.md)。

## 已完成

- 桌面实际写入/删除探针通过；初检工程不存在，创建过程中不覆盖现有文件。
- 11 份 Markdown 文档与指定空目录；本轮不生成 .swift/.m/.h/.xcodeproj，不安装引擎。
- 附件已按本次约束归纳，删除付费/广告、旋球多控件、角度改规则/布局等冲突内容。
- 核实 Xcode 27.1 (27A9269)、iOS 27.1 SDK/runtime 与 iPhone Duo 模拟器存在；尚未运行 App、截图或验证开合动作。

## 后续入口

M1：可启动 Swift UIKit 壳 + 单拉杆输入 + DUO 适配；M2：最小可玩闭环与轻量奖惩；M3：沉浸/无障碍/真实截图验收。正式开发前确定最低 iOS、渲染层与尚未明确的奖励参数。

本文与 specs 中出现的未来文件名只是计划，不表示文件已创建。空目录不会被 Git 自动追踪；本轮未初始化 Git，也未放置 .gitkeep，以满足“源码空目录”。

## 当前目录树

```text
FoldPutt/
├── App/
├── Models/
├── Resources/
│   ├── Colors/
│   ├── Fonts/
│   ├── Levels/
│   └── Motion/
├── Systems/
│   ├── FoldAdaptation/
│   ├── Input/
│   ├── Physics/
│   └── Rewards/
├── Views/
├── docs/
│   ├── duo-adaptation.md
│   ├── product.md
│   ├── screens.md
│   └── ui-prompt-library.md
├── specs/
│   ├── input-control.md
│   ├── milestones.md
│   ├── physics-rewards.md
│   └── theming.md
├── AGENTS.md
├── CHANGELOG.md
└── README.md
```
