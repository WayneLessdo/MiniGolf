# 独立选项弹窗与三套全屏地图方案（2026-10-09）

## 授权范围与依据

用户指出选项和拉杆在同一滚动面板中，要求改为弹窗列表；同时要求三套“全屏地图＋周边标题/杆数/拉杆”的效果图，拖杆时透明、松手恢复，并适配不同空间。

附件截图只作为视觉与问题定位参考。查看现有代码确认，options 原先被追加为 stack 的 arrangedSubview，打开后还把 scroll.contentOffset 移到列表位置，导致拉杆被推出视口。

本轮正式代码只改选项弹窗与对应 UI 验收；全屏地图/HUD 显隐交互交付为独立可交互方案，未擅自替换现有正式球场或物理。原始文件保存在 `work/fullscreen-options/before/`。没有 Git，不创建提交；未改变签名、关卡、调参、恢复格式或引擎。

## 正式 UIKit 改动

`Views/FPControlsController.swift` 使用 UIButton.showsMenuAsPrimaryAction、UIMenu、UIDeferredMenuElement.uncached，每次打开动态读取最新关卡/音效/触感状态。删除内嵌 options、展开列表后的 scroll offset 修改和自定义列表关闭路径；点击列表外由系统弹层关闭。普通拉杆面板不再因为加入列表而增长，关闭动画完成后拉杆可操作。

短高度容器中，UIKit 可滚动原控制面板以露出菜单锚点；这与列表展开改变布局是两件事。UI 测试比较输入尺寸、弹窗前后锚定状态及关闭后可操作性，没有声称任何空间下 scroll offset 都恒定。

WIN 阶段打开菜单后，第一次外部点击只关闭菜单、不换关；下一次屏幕点击才进入下一关，已通过真实一杆入洞流程验证。

## 三套方案

| 方案 | 周边 HUD | 比较重点 |
|---|---|---|
| A 四角悬浮 | 左上标题、右上成绩；左下工具、右下拉杆 | 画面最开阔，最接近“球场占满屏幕” |
| B 双侧轻栏 | 左上标题、右侧工具；左下拉杆、右下成绩 | 信息分散在边缘，适合偏左手操作的评审 |
| C 边缘一体 | 顶部信息条、底部操作条；拉杆在底部中间 | 信息更规整；遇保留区会移开中心操作热区 |

三者使用同一全屏草地层和同一地形示例，避免旧地图卡片与大控制卡片。HUD 数据为静态构图示例，不代表新的计分规则或真实关卡加载；正式实施须绑定现有 session 数据。绘制按可用空间构图，圆球保持圆形；不是原物理场地直接拉伸。素材来自现有 `GrassRegular.imageset/grass.jpg`，未调用 AI 生图。

拖杆时周边 HUD/面板透明，拉杆保持 14% 轮廓以保留操作定位，松手恢复；150ms 使用 CSS 动效令牌。Reduce Motion 无过渡，保留静态显隐；没有新增默认力度面板、PUTT 确认或角度滑块。

方案预览里的系统栏、traits/safe area、division/occlusion 是明确的评审输入。最终 UIKit 实施须使用当前 window/view/scene 与系统 reserved regions；不能把示例 seam 宽度当硬件常量，不能用此预览冒充 DUO 实测。

## 验证

| 项目 | 结果 | 证据 |
|---|---|---|
| UIKit 单测 | 27/27 通过，生产源码随后未更改行为 | `work/fullscreen-options/Popup.xcresult` |
| 正式菜单竖/横屏 | 2/2 通过：系统列表选项、外部关闭、触感状态、下一关及拉杆恢复 | `PopupFinal.xcresult` |
| 掌机菜单链路 | 通过 | `PopupVerified.xcresult` 中 testPullAndHandheldMenu |
| WIN 菜单与下一关 | 通过；关闭菜单不同时换关 | `WinMenu.xcresult` |
| Release 构建 | iOS Simulator 27.1 SDK 通过 | `release.log` |
| 布局计算 | 36 组＋3 组 inactive 区域检查通过 | `node prototype/fullscreen-v1/check-layout.mjs` |
| 实际浏览器渲染 | 3 方案 × 6 空间 × 2 文字规格，无重叠、越界；设计坐标的操作热区至少 44（缩放评审图不代表实体屏幕 pt） | `browser-layout-checks.json` |
| 保留区示例 | 三方案的球与操作热区避让，无遮住球的情况 | `preview-image-proof-final.json`；不是 Apple 系统读数 |
| 拖动/显隐 | 实际拖动后恢复，静态拖杆态 HUD=0、拉杆=0.14；外部关闭 dialog、减弱动效过渡为 0s | `transparency-check.json` 与浏览器交互观察 |

浏览器预览检查：320×640、375×812、812×375、1024×768、1024×768 含保留区、528×678 右安全区 84；较大文字约 140%。它们是设计验证，不能代替原生 Dynamic Type 或 Device Hub。

正式验证使用 Xcode 27.1（27A9269）、iPhone 16 Pro / iOS 18.5 模拟器；原生系统 SDK 27.1。原生截图与概念预览在截图清单中分别标明。

## 交付与限制

- 交互预览：`prototype/fullscreen-v1/index.html`，启动方式见该目录 README。
- 主效果图：`docs/screenshots/fullscreen-options/variant-{a,b,c}.jpg`。
- 每个方案另有 `*-landscape.jpg`、`*-reserved.jpg`、`*-aiming.jpg`。
- UIKit 实际弹窗：`options-popup.png`；关闭后：`options-closed-pull-visible.png`；对应 TXT 记录实际 traits、safe area 和 regions。
- 未在实体设备安装本轮更新，未完成真实 DUO 开合、分屏、摄像头遮挡与握持矩阵；没有将概念图称为模拟器截图。
- 正式全屏场地、原生拖杆时 HUD 显隐、完整 VoiceOver/Dynamic Type 验收，待用户选择 A/B/C 后实施；不将此停点作为其他任务的永久审批门槛。
