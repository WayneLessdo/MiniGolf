# Tuning v1：易上手参数与 DUO 回归

工程 `/Users/cws/Desktop/FoldPutt`；Swift + UIKit，Xcode 27.1 / iOS 27.1 SDK。没有 SwiftUI/Objective-C 或第三方依赖。改动前副本在 `work/tuning-v1/before`。

## 参数表

运行时参数源是 `Resources/tuning.json`，版本键 `easy-v1-A`。关卡中的 v1 friction/restitution/capture 数值保留为历史数据，运行中的运动/捕获参数统一以 tuning.json 为准；关卡继续提供地形、标准杆、60 秒/5 次碰障等规则。

| 参数 | compact | regular | 说明 |
|---|---:|---:|---|
| 拖拽死区 | 6pt | 5pt | 不超过死区就取消 |
| 最大拉距上限 | 100pt | 130pt | 再按控件可用短边 ×0.42 缩小，不按设备型号 |
| 力度曲线指数 | 1.45 | 1.35 | `power = clamp((distance-dead)/(max-dead),0,1)^exponent` |
| 三档色阶阈值 | 33% / 72% | 33% / 72% | 精准绿 / 标准金 / 强力红；同时有环长与可访问性数值 |

物理世界尺度在所有 size class 相同，切屏不偷偷改变球速。

| 物理参数 | 值 | 用途 |
|---|---:|---|
| 最大初速度 | 1.55 world units/s | 大拉力封顶 |
| 草地阻尼 / 回弹 | 0.9 s⁻¹ / 0.82 | 普通慢滚 |
| 沙地阻尼 / 回弹 | 2.5 s⁻¹ / 0.45 | 更强减速与较软反弹 |
| 河岸阻尼 / 回弹 | 1.3 s⁻¹ / 0.72 | 靠岸材质单独调 |
| 普通墙回弹 | 0.82 | 和普通障碍同公式 |
| 近岸材质范围 | 0.028 + 球半径 | 非碰撞体本身的地面摩擦区 |
| 停球阈值 / 稳定时长 | 0.006 / 0.18s | 指数末段慢滚后停止，避免高速硬切零 |
| 捕获容错半径 | 0.085 | world units，球半径仍为 0.022 |
| 半径边缘 / 杯心允许速度 | 0.24 / 0.52 | 距离越近允许速度越高，快球从杯口飞过 |

每步速度按 `v *= exp(-drag × dt)` 衰减。反射使用 `v' = restitution × (v − 2(v·normal)normal)`：整个反射向量等比衰减，墙/障碍/河岸不因只缩法向而改变反射角。固定步长和防穿墙子步保留。

## 加速线增益

本轮向用户询问了“星级只在入洞时确定”和“本关有效、结算清零”的时序冲突；未收到回复时按已说明的推荐方案实现：

1. 正常入洞，达到至少 2 星。
2. 点击重开同一关，获得 **下一杆 15 秒预测虚线**。没有跨关携带，不永久强化速度。
3. 瞄准时复制当前物理世界，模拟最多 2.5 秒轨迹，以静态金色虚线显示。模拟副本不能移动实际球、计杆或发奖励。
4. 有效松手消费一次；死区取消不消费；15 秒有效前台时间到期、结算、换关或普通重开都会清除。
5. 再次获得星级后可以重新触发，但对一次达标重试只计一次，布局重排不触发奖励。

本地 `UserDefaults` 按 `FoldPutt.tuning.<variant>` 保存 `triggers` / `uses` / `expired`。修改 JSON 的 variant 即可分开对比 A/B；不上传、不建账号。UI 自动化和截图夹具用独立内存计数，避免污染正常试玩计数。诊断 JSON 同时导出 variant、活跃秒数和计数。

无广告、无付费、无商店。≤标准杆星级、出界回安全点、超时/碰障轻残局仍沿用 v1；旧“入洞后金色速度线装饰”由可消费预测线取代。

## 布局与状态连续性

- 外屏 compact：导航单栏和底部拉杆；四边安全区分别计算。
- 内屏 regular：UIArrangementViewController，primary 球道、secondary 操控，默认 `UISplitArrangement().axes(.horizontal)`。
- 系统实际布局后 secondary 无法显示，或出现水平 active division 时，使用 UIOverlayArrangement：水平 active division 时 primary 球道在上、secondary 控件在下；无水平 active division 的窄窗则在 primary 内复用 FPPlayLayoutController 上下控显容器。窄窗不再依赖两块重叠的系统 wrapper 透传触摸；恢复足够宽的空间后重新采用横向 split。窄窗回退模式 primary 是组合容器、secondary 为空，双区正常模式仍为 primary 球道 / secondary 操控。
- 手动掌机是等价入口，不依赖铰链角。角度/状态仍只影响 0.6s 草皮、0.4s 旗杆、水纹和 0.3s 惩罚反馈；入洞粒子 0.8s，Reduce Motion 保留静态提示。
- 背景可延伸，按钮避开 division/occlusion；自定义球道仍读取真实保留区域。不会读取 UIScreen.main、UIDevice.orientation 或 idiom。
- 每次布局变化仅取消未释放的拖动，不清 strokes、lastLaunch ID、world position/velocity、增益或当前关卡。已出球时 canal 快照冻结。

## 文件变化

```text
Resources/tuning.json                     新增：运行时参数和 A/B variant
Models/FPTuning.swift                     新增：参数载入/校验
Tests/FPTuningTests.swift                 新增：曲线、阻尼、反射、快慢捕获、增益、转换
Tools/capture_tuning.py                   新增：真实姿态事件/实时状态取证
Systems/Input/FPPullMath.swift            非线性输入
Systems/Physics/FPPhysicsWorld.swift      指数阻尼、统一反射、双阈值捕获
Models/FPDemoSession.swift                预测增益、计数、输入档位
Views/FPPullControl.swift                 三档颜色与非线性环形反馈
Views/FPCourseView.swift                  同源输入、预测线
Views/FPControlsController.swift          输入档位与安全控制卡
Views/FPArrangementController.swift       horizontal split / 掌机回退 / 诊断
App/SceneDelegate.swift                   测试计数隔离 / Debug 半窗夹具
Systems/FoldAdaptation/FPRegions.swift    Debug 模拟保留区
FoldPutt.xcodeproj/project.pbxproj         注册参数模型与 JSON
Tests/FPPrototypeTests.swift              测试计数隔离
README.md / CHANGELOG.md                   版本入口与变更记录
Tests/FPPhysicsTests.swift                原物理回归
UITests/FPPrototypeUITests.swift           正常通关→增益→真实超时残局
docs/screenshots/tuning-v1/                本轮截图和逐图证明
```

原有资源和 Physics v1 截图保留。

## 复现命令

```sh
cd /Users/cws/Desktop/FoldPutt
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
FP_DUO=2B7D0712-AB02-4854-86C5-7FC76DD406F5
xcodebuild -project FoldPutt.xcodeproj -scheme FoldPutt -sdk iphonesimulator27.1 \
  -destination "platform=iOS Simulator,id=$FP_DUO" -derivedDataPath work/DerivedData \
  CODE_SIGNING_ALLOWED=NO build
xcodebuild -project FoldPutt.xcodeproj -scheme FoldPutt \
  -destination "platform=iOS Simulator,id=$FP_DUO" -derivedDataPath work/DerivedData \
  -parallel-testing-enabled NO test
```

在 Device Hub 切换目标姿态后执行 UI 流程 `testTuningWinBoostPenaltyFlow`：从正常起点完成第一关，重开获预测线，使用一次，再按正常 60 秒规则等待残局，无计时器注入。截图夹具的 `boost` 也先由真实物理入洞达标再重试，画面明确标注夹具，不能代替正常 UI 流程。

实时取证命令 `python3 Tools/capture_tuning.py <name> --live --display <id>` 不重启/重置会话，适用于开合旋转前后比较 launch ID 与杆数。事件快照 `--scenario aiming|boost|penalty` 会重启到标注的初始条件。

## 未决

真机手感、热量和实际握持仍需设备验证。系统多任务若无法从当前 Device Hub 操作完成，不把半窗夹具声称为真实 Split View；实际矩阵与残留问题在文末记录。


## 解锁后最终回归（2026-09-29）

本次续测发现并修复两个容器问题，物理、拉力和奖惩参数不变：

1. 半折冷启动时，单栏 split 的 minimum=1 无法放入折痕两侧可用区域，内容被系统隐藏。已改用标准 UIOverlayArrangement 承载单栏回退。
2. 台式半折展开时，两个区域曾重叠遮住操控。现根据真实 division 的几何处理：水平 active division 使用 primary.edge=.top / secondary.edge=.bottom；横向 inactive division 则使用单栏掌机回退。全开横向/书本仍是 horizontal split，primary 球道、secondary 操控。不根据方向、idiom、型号或铰链角做布局。

源码本次只改 `Views/FPArrangementController.swift`；改前副本 `work/tuning-v1/unlocked-before/`。其余为截图、日志、README/CHANGELOG 和本文更新。

最终代码完整测试：`work/tuning-v1/UnlockedFinalSuite.xcresult`，**16 项单测＋4 项 UI 测试全部通过**。运行姿态为内屏竖向全开，含正常通关、掌机切换、左右半窗夹具和真实超时残局。最终 Release 构建：`work/tuning-v1/unlocked-complete-release.log`，BUILD SUCCEEDED。`verified-portrait-final-boost.png` 已目视确认球道、拉杆和按钮均显示且可用。

### 验证证据

| 项目 | 结果与证据 |
|---|---|
| 半折冷启动完整流程 | `UnlockedFoldedFinal.xcresult` 通过：真实拖杆入洞→同关重试预测线→消费→实际 60 秒超时残局 |
| 外屏完整流程 | `UnlockedCompactFinal.xcresult` 通过同一流程 |
| 真实系统左 Split View | `verified-split-left-shot.png`；实际拖杆计 1 杆，系统报告 compact，自动单栏，按钮不进入 division/occlusion |
| 普通开合与旋转 | `continuity-01-open` 至 `continuity-06-book` 保持同一已停止击球 ID、1 杆和球位；这组先于本次容器修复 |
| 修复后的结算连续性 | `verified-user-closed/open/book/table` 均保留同一击球 ID、2 杆、3 星与 success；没有按钮侵入保留区 |
| 左/右半窗夹具 | 正常拖杆后左右切换保持 1 杆；这是 Debug 强制 regular＋模拟保留区，不能替代真实系统右半窗 |

`verified-table-boost.png` 是修复后的真实 Device Hub 台式半折窗口渲染图，明确标注初始条件夹具；完整正常 UI 流程证据在 xcresult。系统多屏截图曾导出黑图、主屏或旧布局，已移到 `work/tuning-v1/`，未纳入交付图片。逐图来源/阶段见 `docs/screenshots/tuning-v1/manifest.json`。

在实际左分屏之后，手动交互记录了第 2 杆并入洞；因此没有把“第 1 杆左分屏”与“第 2 杆结算”拼接为同杆连续性证明。后续 `verified-user-*` 仅比较同一个第 2 杆 ID。

### 操作与复现

实际左 Split View 通过从全开窗口底部 Home Indicator 拖向左侧进入。依据：[Apple — Prepare your app for iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111461/)，约 6:06 安全区/多任务章节。向右拖动的自动化尝试落入主屏/另一侧应用切换器，未获得可靠的真实右半窗证据。

```sh
# 保持当前会话取证，不重开
python3 Tools/capture_tuning.py new-live-name --live --display 3
# 明确的半窗替代夹具，禁止冒充 OS Split View
python3 Tools/capture_tuning.py half-left-new --half-window left --scenario aiming
python3 Tools/capture_tuning.py half-right-new --half-window right --scenario aiming
```

### 仍未覆盖

- **真实系统右半窗及左→右同杆换位**：尚未完成，右半窗只有替代夹具。用户回复后实际看到的是外屏闭合状态，随后完成展开复测；没有假定用户已进入右半窗。
- 高速滚动中连续开合的长期压力、系统销毁 scene 后恢复、长时间多任务残留。
- 真机握持手感、触觉、热量/功耗。模拟器结果不代表这些项目通过。
