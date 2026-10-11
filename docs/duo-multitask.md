# 多任务、恢复与真机反馈收口

2026-09-30，Swift + UIKit。参数仍是 `easy-v1-A`；无 SwiftUI、Objective-C、广告、支付或第三方依赖。

## 本轮实现

- **空白图核查**：`tuning-v1/continuity-05-table.png` 是旧单 pane 被父级 arrangement 隐藏的失败图，根 view 上的运河仍显示。不是 reservedRegions 读取时删除了背景。该图保留并标记 `failed/superseded`，后续已修复图见 `verified-table-boost.png`。本轮补充 window/祖先 hidden、alpha、裁剪交集、courseField、primaryHidden/secondaryHidden 诊断，以及拉杆实际可点击断言。
- **scene 恢复**：以 `UISceneSession.persistentIdentifier` 隔离进度，通过 `stateRestorationActivity` 和 Application Support 中同 ID 的原子检查点恢复关卡、杆数、launch UUID、球位/速度、安全点、碰撞接触、增益剩余时间/计数、残局与阶段计时。系统丢弃 session 时删除对应文件。断连停止 display link，重连不重复发球或领奖。
- **异常快照**：版本、参数/关卡匹配、长度、范围及状态一致性校验通过后才修改现场；无关 activity 忽略，损坏快照安全回退并提示。后台不推进球或增益计时，未释放拖动恢复为 ready/penalty。
- **用户追加反馈**：入洞出现奖杯图标、WIN!、杆数/星级提示；浮层不拦截拉杆。再次有效拖动直接进入下一关并准备第一杆，死区轻触不跳关。重开本关仍可领取原预测线，跨关不携带。
- **音效**：原生 AVAudioPlayer 播放程序化生成的短挥杆声和入洞声；设置中可关闭，遵循静音开关。音频加载/激活在串行后台队列，避免卡住主线程。Reduce Motion 关闭浮层的大动效，得分文字仍显示。

## 变更文件

```text
App/SceneDelegate.swift                    生命周期保存、恢复、计时器清理
App/AppDelegate.swift                      丢弃 scene 时清理同 ID 检查点
Models/FPDemoSession.swift                 快照校验、恢复幂等、胜利后拖杆进下一关
Systems/Physics/FPPhysicsWorld.swift       可序列化世界、恢复边界校验
Systems/Physics/FPPhysicsPort.swift        序列化原 launch UUID/向量
Systems/FoldAdaptation/FPRegions.swift      真实可见性检查
Systems/Rewards/FPSound.swift              新增原生音效与设置项
Views/FPArrangementController.swift        可见性/恢复/音效诊断
Views/FPAdaptiveController.swift           通用版设置与相同 UI 检查
Views/FPControlsController.swift           WIN 得分提示卡
Resources/Sounds/{putt,hole}.wav            新增原创 PCM 短音效
Tools/generate_feedback_sounds.py          可重复生成音效，拒绝覆盖已有文件
Tools/capture_tuning.py                    指定输出目录、读取当前 bundle、可见性检查
Tests/FPTuningTests.swift                  恢复、安全区、双阈值、胜利继续测试
UITests/FPPrototypeUITests.swift            进程重启恢复、WIN 继续、音效开关
FoldPutt.xcodeproj/project.pbxproj          注册新增音效源文件/资源
docs/screenshots/duo-multitask/             本轮图像和来源清单
```

保留外部 Xcode 更新的签名团队与 `com.mavericklab.foldputt` bundle，不回滚为历史 prototype 标识。基线和备份在 `work/duo-multitask/before`。

## 测试结果

| 检查 | 结果 | 证据 |
|---|---|---|
| Release 编译 | iOS 27.1 SDK 通用模拟器构建通过 | `work/duo-multitask/release-final.log` |
| 最终单测 | 22/22 通过，iOS 18.5 模拟器 | `work/duo-multitask/FinalUnit.xcresult` |
| 通用版 UI | 4/4 通过：WIN 后拖杆进下一关、音效开关与掌机、后台终止重启同杆、正常增益/真实超时残局 | `work/duo-multitask/UniversalUI.xcresult` |
| DUO 恢复 UI | 运行时故障前已通过一次真实后台→终止→重启验证 | `work/duo-multitask/RestoreBackground.xcresult`；其截图含系统账号弹窗，不作为干净界面截图交付 |
| DUO WIN/继续 | 运行时故障前已通过真实拉杆入洞与下一关 | `work/duo-multitask/Feedback.xcresult` |
| 真机编译与安装 | iPhone 12 Debug 签名构建、安装成功 | `work/duo-multitask/device-final-build.log`；包名 `com.mavericklab.foldputt` |
| 右侧真实分屏完整链路 | 本轮未完成，保留手动步骤 | 两个 27.1 DUO 实例迁移失败；没有拿 Debug 半窗替代 |

最新通用版 UI 测试明确排除了只能在 27.1 上运行的 `testHalfWindowKeepsShot`；右侧非对称安全区仍有单测。不要将 4 项通用 UI 结果描述成完整 DUO 矩阵通过。

## 截图路径

目录：`/Users/cws/Desktop/FoldPutt/docs/screenshots/duo-multitask/`。

- `iphone12-native.png`：iPhone 12 真机第三关 WIN。
- `universal-win.png`：正常一杆入洞与 WIN 卡。
- `universal-scene-restored.png`：终止重启后同一杆继续滚动。
- `universal-boost.png`：达标同关重试的预测线。
- `universal-penalty.png`：真实 60 秒规则产生的残局。
- `universal-handheld.png`：通用版手动掌机与换关。
- `manifest.json` / 对应 JSON：真机/模拟器、系统版本、XCTest 来源与非夹具标记。

以上图像已逐张目视检查，没有空白/黑图或系统账号弹窗。除了第一张，其余为 iPhone 16 Pro / iOS 18.5 自动化运行截图，不能称为 DUO 右半窗截图。

## 真机抽样与参数

已在 iPhone 12「测试机^_^」、iOS 26.6.1 签名安装并实际启动更新版。`iphone12-native.png` 是真机屏幕捕获，显示第三关 2 杆 3 星及完整 WIN 提示；非概念图、非模拟器、非初始条件夹具。

用户实际试玩反馈指出结算后拉杆无响应，并提出 WIN/音效/下一关需求，本轮已处理。这是状态与反馈问题，没有证据要求改变拉力或摩擦，所以 **tuning.json 未改**。

5 次抽样的入洞率、3 秒完成率、轻重拉死区和主观触感仍待用户填写，见 `feel-sampling.md`。不能将自动化耗时或一张真机截图冒充主观矩阵通过。

## 右侧真实 Split View 手动复测

本轮原 DUO 实例及新建独立实例均报告 `Data Migration Failed`，随后 Device Hub 设备画面黑屏，无法可靠完成新的右侧拖入/截图。这与已经定位的 App 旧空白图是两类问题。保留原设备数据，没有 erase/reset。

环境恢复后执行：

1. 在 Device Hub 选择 iPhone Duo / iOS 27.1，展开，启动正常对局（不要带 `--half-window` 或 `--simulate-division`）。
2. 拖杆轻推，记下诊断中的 level、strokes、lastLaunch.id；不要重开。
3. 按 Apple 的方式，从底部 Home Indicator 拖到右侧落点。需要看到 App 位于真实右半窗、另一侧为系统/其他 App；仅 frame 缩小不算通过。
4. 核对系统 horizontalSizeClass=compact 时单栏、若为 regular 则双区；四边 safeAreaInsets 分别处理，按钮/拉杆不与 division、occlusion 相交。
5. 比对同杆 UUID/杆数；继续入洞，点击重开本关获预测线，使用一次后按真实 60 秒规则进入残局。若入洞后直接拖杆，应进下一关且清除本关增益。
6. 关闭/展开/转动/书本/台式，再切到后台终止进程并重启；检查恢复同关/杆/球/增益，截图和 JSON 分别记录真实姿态、真实窗口位置和状态。

参考：[Apple — Prepare your app for iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111461/)。Debug 半窗仍只作替代回归，不作为量产模式或真实右分屏证据。

## 命令与证据

```sh
cd /Users/cws/Desktop/FoldPutt
xcodebuild -project FoldPutt.xcodeproj -scheme FoldPutt \
  -destination 'platform=iOS Simulator,id=3996447A-B8B5-4A58-BFC8-8C3B879E3AB9' \
  -derivedDataPath work/DerivedData -parallel-testing-enabled NO -only-testing:FoldPuttTests test
python3 Tools/capture_tuning.py right-live --live --display 3 \
  --output-dir docs/screenshots/duo-multitask --require-visible
```

恢复依据：[Apple — Restoring your app’s state](https://developer.apple.com/documentation/uikit/restoring-your-app-s-state)。UI 恢复测试通过打开系统设置确认进入后台，再终止重启；DUO 的通用 Home 测试按钮曾没有让当前对局进入后台，已排除这种无效测试路径。

前台崩溃/直接强杀只能恢复最近一次后台检查点；系统明确丢弃 scene 后是新会话。高速滚动中反复折叠、长时间散热/功耗和真实右分屏的新一轮完整链路仍未验证。

## DUO 专属体验与上架

公开资料未找到可确认的 DUO 专用上架筛选键，采用通用版＋DUO 增强方案。跨屏大画布、浮动拉杆和跨缝效果是下一步布局大改，方案与碰撞规则待确认；本轮未替换现有分栏，未加入支付。见 `duo-experience-proposal.md`。
