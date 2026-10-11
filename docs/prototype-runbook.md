# FoldPutt 原型运行手册

本轮目标：可编译运行、基础切图、DUO 三态演示。Swift + UIKit，没有 SwiftUI、Objective-C 源文件或桥接头，无第三方运行依赖。Swift 中的 @objc 仅用于 UIKit selector，不是 Objective-C 实现。

## 工程与环境

- 工程：/Users/cws/Desktop/FoldPutt/FoldPutt.xcodeproj；共享 Scheme：FoldPutt。
- 本机：Xcode 27.1（27A9269），iPhoneOS/iPhoneSimulator 27.1 SDK。
- 最低部署：iOS 18.0；27.1 reserved regions/hinge API 用 availability 保护。
- Bundle ID：com.foldputt.prototype。模拟器无需配置开发团队；真机签名由用户后续选择团队。
- iPhone Duo UDID：2B7D0712-AB02-4854-86C5-7FC76DD406F5；iOS 27.1 runtime。

## 构建和运行

```sh
cd /Users/cws/Desktop/FoldPutt
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
FP_DUO_UDID=2B7D0712-AB02-4854-86C5-7FC76DD406F5

xcodebuild -project FoldPutt.xcodeproj -scheme FoldPutt \
  -sdk iphonesimulator27.1 \
  -destination "platform=iOS Simulator,id=$FP_DUO_UDID" \
  -derivedDataPath work/DerivedData CODE_SIGNING_ALLOWED=NO build

# 设备未启动时执行 boot；已 Booted 时跳过。
xcrun simctl boot "$FP_DUO_UDID"
xcrun simctl bootstatus "$FP_DUO_UDID" -b
xcrun simctl install "$FP_DUO_UDID" \
  work/DerivedData/Build/Products/Debug-iphonesimulator/FoldPutt.app
xcrun simctl launch "$FP_DUO_UDID" com.foldputt.prototype

xcodebuild -project FoldPutt.xcodeproj -scheme FoldPutt \
  -destination "platform=iOS Simulator,id=$FP_DUO_UDID" \
  -derivedDataPath work/DerivedData -parallel-testing-enabled NO test
```

Xcode 也可直接打开工程选择 iPhone Duo 运行。Device Hub 的实际路径是 /Applications/Xcode.app/Contents/Applications/DeviceHub.app；选择该设备，使用 Closed / Open / Book / Rotate Right 控件。不得把其他名字含 Duo 的自定义设备当作 DUO 硬件类型。

## 手动演示

1. Closed：外屏 compact，球道铺底，底部控制卡覆盖在安全区内。只从球或拉杆圆心开始拖拽；向后拉产生方向/力度，松手演示出球，杆数只加一次。轻触/死区内松手不计杆。
2. 点地图图标：打开可收小地图 sheet，支持中/大 detent，拖动关闭。
3. Open：regular 使用 UISplitViewController。primary 为右侧球道，secondary 为左侧控制区；标题、按钮和手势区域避开转换到各自坐标的系统保留区。
4. Book + Rotate：真实活跃 division 提供区域；水平 division 使用上下结构。书本式纵向 division 保留可用的两侧区域，点“设置与演示 → 掌机模式”可手动切到上画面下控件。
5. 设置与演示菜单：重播开球、演示入洞、演示回安全点、显示安全区域。所有反馈是原型路径，不暗示碰撞/入洞物理已完成。
6. 重开清球位/杆数；切换布局取消未释放拖动，不重复发射。已提交的一杆沿同一个 mock 状态继续；scene 失活暂停，恢复再继续。
7. 开启系统 Reduce Motion 后重播：不播放大动效，保留静态成功/惩罚信息；Light/Dark 使用同一品牌色与自适应面板/文字。
8. 普通 iPhone 无新 API 时默认 compact，手动掌机、开球重播、地图与演示仍可用。

## 截图/诊断

```sh
# 先列出 display，不能假定所有设备都只有 display 1。
xcrun simctl io "$FP_DUO_UDID" enumerate
# 本机本次外屏为 1，内屏为 3；姿态以 Device Hub 操作为准。
xcrun simctl io "$FP_DUO_UDID" screenshot --display=1 docs/screenshots/compact.png
xcrun simctl io "$FP_DUO_UDID" screenshot --display=3 docs/screenshots/regular.png
# 存在同名文件时先确认或使用新文件名。
```

Debug 构建会向自身 app Documents/layout-diagnostics.json 写 mode、traits、bounds、scale、四边 insets、division/occlusion、手动开关与对局状态。取证时将对应文件复制至 docs/screenshots，使用 simctl get_app_container 查询当前 sandbox，不硬编码安装 UUID。

## 本轮边界

- 出球是直线插值 mock，尚无摩擦、边界反弹、运河碰撞、真实洞口吸入或完整关卡系统。
- 运河纹理、河岸/洞杯/沙坑仅用于视觉；不可把本原型当已完成可玩性验收的游戏。
- 入洞/回安全点可由演示菜单触发；截图明确记录来自演示操作。
- 不含商店、账号、社交、广告、付费。AI 图生成不可调用，交付 docs/ai-image-prompts.md，不使用程序化图冒充 AI 素材。
- 截图与验证结果在 docs/screenshots/manifest.json 和本文件末尾记录；没有执行的项不能视为已通过。

## 已有文档保护

原始 README / CHANGELOG / AGENTS 的更新文本在 docs/existing-document-updates.md，按用户要求等待确认后再追加，不静默覆盖旧文。其他旧规格保留，最新原型范围以本轮用户要求和本手册为准。

## 本轮实测结果（2026-09-29）

- `work/build-delivery.log`：BUILD SUCCEEDED，iOS Simulator 27.1；没有应用源码编译警告，仅系统 AppIntents 元数据提取跳过提示（本 App 不依赖 AppIntents）。
- `work/FinalTests.xcresult` / `work/final-tests.log`：3 个单元测试 + 1 个 UI 流程测试通过。覆盖死区、最大力度、重复提交、非对称矩形/中缝避让，以及实际拖拽计杆、掌机开关、入洞与回安全点演示。
- 测试之后仅修正底部 overlay 给球道预留空间的布局值，再次编译通过，并通过最终外屏/旧 iPhone 截图人工复核；没有声称每个系统矩阵都由自动化测完。
- DUO Closed/Open/Book/Rotate 均在真实 Device Hub 执行。Book 的 vertical division 激活时仍为两侧可用区域；Book 旋转为 horizontal division 后自动显示上球道下控件，诊断中 handheldSwitch=false。
- iPhone 16 Pro / iOS 18.5 启动成功，compact 回退，无 division/occlusion API；深色主题显示正常，球不被底部控制卡遮挡。
- 三态截图不是概念图，也没有采用虚构 division。保留区域与四边安全区详见每张图的 JSON。

| 截图 | 证据 |
|---|---|
| docs/screenshots/duo-compact-delivery.png | DUO 外屏，compact 宽，四边安全区非对称 |
| docs/screenshots/duo-regular.png | DUO 全展开，regular/regular，左控制右球道 |
| docs/screenshots/duo-folded.png | DUO 真实 Book + 旋转，活跃水平 division，自动上下布局 |
| docs/screenshots/duo-book.png | 活跃垂直 division 的书本式补充证据 |
| docs/screenshots/iphone16pro-ios18-final.png | 非 DUO、iOS 18.5、深色主题回退 |
| docs/screenshots/overview-delivery.png | 三态实拍截图汇总板（仅排版合成） |

`docs/screenshots/manifest.json` 汇总 5 个取证状态；`docs/new-files.txt` 列出本轮新增源码、工程、资源、文档（不含 work 构建中间物）。

未决/未测：完整物理与运河碰撞尚未接入；AI 图片需外部生成；分屏多任务、最大 Dynamic Type、Reduce Motion 系统开关的完整视觉矩阵仍需后续验证；真机触觉/光学折痕/散热不在模拟器验收范围。
