# Arrangement 原型交付

工程：`/Users/cws/Desktop/FoldPutt/FoldPutt.xcodeproj`；Scheme：`FoldPutt`；bundle ID：`com.foldputt.prototype`。

## 本轮实现

- Swift + UIKit，iOS 27.1 SDK，最低部署 iOS 18。没有 SwiftUI、Objective-C 实现或外部运行依赖。
- 27.1 导航根为 `FPArrangementController: UIArrangementViewController`，放在 UINavigationController 中。regular 的 primary 为球道、secondary 为操控区；使用系统 `UISplitArrangement` 排列，子视图按真实 division/occlusion 避让。
- compact 只显示主 placement 承载的单栏对局；手动掌机复用现有上下布局。旧系统继续现有单栏/掌机回退。
- primary/secondary 的布局次序用 UIKit layoutDirection trait 配置，子控制器恢复自己的阅读方向；不读取设备方向、idiom 或铰链角来判断布局。系统 arrangement 自己使用可用空间和保留区域排布。
- 单手势松手调用 `FPPhysicsPort.launch`，输出唯一 ID、world-space 速度、弧度角、力度。`FPMockPhysicsPort` 只记录，屏幕运动仍为直线插值演示。运河/桥区域留在 `FPCanalCollisionReservation`，未接真实碰撞。
- UIHingeInteraction 的角度/状态只影响开球或水纹及当前惩罚表现，不决定页面结构、计分或物理。大动效遵守 Reduce Motion。
- 设置/演示选项改为操控面板内展开的按钮，避免系统浮动菜单跨中缝；原有地图使用系统 sheet。

## 新增文件树

```text
FoldPutt/
├── Views/FPArrangementController.swift
├── Systems/Physics/FPPhysicsPort.swift
├── Tools/generate_grass_edge.swift
├── Resources/
│   ├── Backgrounds/grass-edge-tile.png
│   ├── Backgrounds/fp-bg-grass-compact-portrait-v001.png / .jpg
│   ├── Backgrounds/fp-bg-grass-regular-landscape-v001.png / .jpg
│   ├── AIConcepts/fp-ui-compact-game-compact-portrait-default-v001.png
│   ├── AIConcepts/fp-ui-separated-game-regular-landscape-aiming-v001.png
│   ├── AIConcepts/fp-ui-pull-charge-folded-l-charging-v001.png
│   └── Assets.xcassets/{GrassEdgeTile,GrassCompact,GrassRegular}.imageset/
├── docs/arrangement-upgrade-plan.md
├── docs/arrangement-delivery.md
└── docs/screenshots/arrangement-v2/
```

修改已有 scene 入口、mock 会话、球道资源绘制、控制面板、测试和工程引用；已有源码/文档副本在 `work/arrangement-v2/before/`，旧截图保留。完整变更清单在 `work/arrangement-v2/changes.json`。

## 资源与用途

| 内容 | 数量/规格 | 用途 |
|---|---|---|
| 原有 Light/Dark Color Sets | 11 | grass、sand、gold、red、water、深浅文字与 surface；沿用原配色 |
| 原有 PDF Image Sets | 9 | 球、旗、洞杯、沙坑边、力度环、箭头、星、加速线、惩罚红边；Single Scale / Preserve Vector Data |
| 原有球/旗 PNG | 各 1024×1024，真实 alpha | 备用游戏件 |
| 原有 AppIcon | 1024×1024，无 alpha | Xcode universal iOS AppIcon 编译入口 |
| 运河纹理 | 256×256，原有 | 独立平铺视觉，非按钮/碰撞数据 |
| 草边纹理 | 256×256，新增程序化 PNG | 草地边缘平铺视觉，不依赖 AI |
| AI 纯草地背景 | 竖版/横版各一，PNG 母版 + JPG 运行副本 | 低透明度画在球道内，未烘焙球、洞、按钮、运河或规则 |
| AI 三态对局概念 | 三张 | 仅在 AIConcepts 保存，不进入 app 资源编译，不冒充运行截图 |

AI 使用内置 imagegen，而非 CLI/API 脚本；提示词依据 `docs/ai-image-prompts.md` 的 compact default、regular aiming、folded charging 与纯背景条目，实际归档见 `docs/ai-generation-record.md`。生成图中的颜色是美术近似；UIKit Color Sets 的十六进制值保持原规范。没有新增商店或皮肤业务。

## 构建/验证命令

```sh
cd /Users/cws/Desktop/FoldPutt
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
FP_DUO_UDID=2B7D0712-AB02-4854-86C5-7FC76DD406F5
xcodebuild -project FoldPutt.xcodeproj -scheme FoldPutt \
  -sdk iphonesimulator27.1 -destination "platform=iOS Simulator,id=$FP_DUO_UDID" \
  -derivedDataPath work/DerivedData CODE_SIGNING_ALLOWED=NO build
xcrun simctl install "$FP_DUO_UDID" work/DerivedData/Build/Products/Debug-iphonesimulator/FoldPutt.app
xcrun simctl launch "$FP_DUO_UDID" com.foldputt.prototype
xcodebuild -project FoldPutt.xcodeproj -scheme FoldPutt \
  -destination "platform=iOS Simulator,id=$FP_DUO_UDID" \
  -derivedDataPath work/DerivedData -parallel-testing-enabled NO test
```

Device Hub 使用 Closed、Open、Book、Rotate 控件；截图前用 `simctl io … enumerate` 核对显示 ID。用户正常拖动拉杆即 mock 出球，演示选项可触发开球、入洞、安全点回退，地图按钮打开可收 sheet。

本轮不实现完整物理/关卡，不以 mock 穿越运河宣称碰撞有效。真机触觉、散热、光学折痕和完整多任务窗口矩阵仍不在当前模拟器验证范围。


## 本轮真实截图与验证记录

截图目录：`/Users/cws/Desktop/FoldPutt/docs/screenshots/arrangement-v2/`。

| 文件 | 实测条件 |
|---|---|
| compact-final.png | DUO Closed，compact，466×678pt，完整单栏；四边安全区分别读取 |
| regular.png | DUO Open，regular/regular；primary 球道在右、secondary 操控在左 |
| folded.png | DUO Book 后旋转，真实水平 division 激活；系统 arrangement 自动上下排列，handheldSwitch=false |
| iphone18-fallback.png | iPhone 16 Pro / iOS 18.5，compact 降级，深色主题 |
| overview.png | 三态真实截图汇总，非 AI 图 |
| manifest.json | 对应 traits、scene bounds、安全区、division/occlusion 与容器诊断 |

三个 DUO 状态的 buttonRegionViolations 均为空；没有采用模拟 division。半折仍由 UIArrangementViewController 排布，没有通过铰链角做页面分支。系统栏占用区域和中缝区域分别处理。

构建结果记录：`work/arrangement-v2/compact-fix.log` 中 BUILD SUCCEEDED。4 个单元测试涵盖输入取消/限幅/重复提交、安全区和发射速度角度；UI 用真实触摸拖动，再验证手动掌机/成功/回退。调试阶段有一次 compact 自动化拖动未提交；记录触摸后复测正常，最终结果以 `work/arrangement-v2/delivery-tests.log` 为准，不删除失败日志。

残余限制：草皮/旗杆为轻量原型演出，未做完整 3D；碰撞区域仅预留，不能宣称球已与运河物理交互。图片颜色是美术近似，品牌 Color Set 保持原值。真机、完整多任务、最大字号和运行中 Reduce Motion 的全矩阵还需后续测试。

最终验收：`work/arrangement-v2/DeliveryTests.xcresult`，4 个单元测试 + 1 条 UI 流程全部通过；运行日志为 `delivery-tests.log`。
