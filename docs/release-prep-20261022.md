# FoldPutt 发布准备实施与验收 · 2026-10-22

> 后续授权更新：已通过 Sites 部署 [英文隐私政策](https://foldputt-help-wayne.humble-mite-6617.chatgpt.site/privacy) 与 [英文支持页](https://foldputt-help-wayne.humble-mite-6617.chatgpt.site/support)，另有简体中文版本。五页已无登录验证 HTTPS 200，主内容与本地源一致；托管层重定向及 Cloudflare 安全脚本单独记录。App 内政策、公开联系方式与文档已改为 waynelessdo@gmail.com；旧截图/日志保持历史原件。
>
> 本次邮箱改动后的相关 UI 用例 1/1 通过；新设备 Release 未签名归档 `work/release-contact-20261022/FoldPutt-contact-unsigned.xcarchive` 成功，核对政策/隐私清单与当前源完全一致。证据见同目录 summary、log 和 archive-contact-inspection.json；新政策截图在 `docs/screenshots/release-contact-20261022/`。原80项及多设备结果沿用其覆盖范围，未宣称整套重跑。当前上架语言与步骤见 [操作文档](../release/国际上架语言与操作步骤.md)。

用户确认：开发者会员已开通；首发支持 iPhone 和 iPad，保留 Duo；仅选择合规资料齐全的海外地区，暂不含中国大陆。对外名称 Wayne，支持邮箱 waynelessdo@gmail.com，网站已按后续授权部署。

首轮实施在既有未提交工作上做局部修改，保留用户之前的适配与测试改动，当时未提交、推送、上传、提审或发布网站。后续按用户新授权只部署了公开网页，站点源码在独立托管仓库按流程提交/推送；iOS项目仍未提交、推送、上传或提审。初始备份在 `work/release-20261022/before/`，本次邮箱/网站变更前备份在 `work/release-contact-20261022/before/`。

## 已实施

- `Resources/PrivacyInfo.xcprivacy` 已加入 App Resources：UserDefaults / CA92.1 用于 App 自身偏好和收藏；System Boot Time / 35F9.1 用于 App 内事件间隔。无追踪，数据收集类型和追踪域名为空。
- 包内离线隐私政策已填入 Wayne 与支持邮箱。开局页“隐私政策”和球场选项“隐私政策”均可打开；标准导航关闭，正文支持选择、链接、大字体、深浅色，按当前 safe area 与活跃 reserved regions 布局。
- 阅读政策时暂停对局，并阻止 scene 激活回调把背后的游戏恢复；关闭后继续同一球局。开局画面阅读政策后仍保留选模式状态。
- 继续支持 `UIDeviceFamily=[1,2]`、最低系统 18.0；没有收窄为 iPhone。有效语言声明为简体中文，未把英文商店文案当成英文游戏 UI。新增 `ITSAppUsesNonExemptEncryption=false`，对应当前无自有或非豁免加密业务。
- 生产菜单不再提供 Debug 的“显示安全区域”；Debug 诊断与夹具仍保留供验收。
- 商店字段已拆为中英文独立文本，包含 iPad，英文明确说明中文 UI；另提供图标、审核说明、隐私与年龄问卷建议、公开联系方式。
- `release/web/` 提供可直接托管的隐私和支持 HTML/纯文本，无第三方脚本、统计或外部字体；隐私正文与包内文件同源。`Tools/prepare_store_pages.py` 可重新生成网页。

## 失败用例的原因与修正

| 原用例/问题 | 原因 | 修正方式 |
| --- | --- | --- |
| 半窗切换保留击球 | 通用 Debug 窗口夹具错误限制在 iOS 27.1，18.5 启动参数被忽略 | 去掉夹具不需要的系统限制；仍真实拖杆、切换左右夹具、核对同一杆数；不把夹具当系统 Split View |
| 横/竖屏选项弹层 | 测试仍查找旧“第1关”顶层菜单，地图已改为原生子菜单 | 验收当前真实地图子菜单入口，保留尺寸稳定、外部关闭、触感切换与下一关断言 |
| Q 版首洞文案 | 实际标题已是“WIN! · 到家啦。”，测试仍精确匹配旧短句 | 精确匹配当前完整标题，保留实际入洞、杆数与换关验证 |
| 掌机菜单流程 | 原拖动可能直接进洞，回放时 HUD 隐藏，菜单点击时机不稳定 | 使用真实轻推并等停球，再核对音效切换、手动模式与下一关 |
| 星级奖励/轻残局 | 一杆进洞加入了先回放再结算的流程 | 经真实“跳过回放”入口验收结果，再真实重开获得预测线，继续等待实际超时，不注入惩罚 |
| 反弹课题自动化 | 只等瞬时 `replaying=true`；减少动态效果时短回放可能被轮询错过 | 等待真实可见的“跳过回放”或结算入口，兼容短回放与不同系统的调试属性快照时序；仍核对结算、精通和通关奖励，没有强制结果或删断言 |

原始失败及中断日志保留在 `work/release-20261022/`。首轮工程资源归属错误已修正并用解析后的 pbxproj 核查；最终归档无 `.swift` 源文件混入 Resources。旧测试进程结果收集未退出造成的一轮会话冲突已中止，后续执行确认退出后再继续；中断轮不作为通过证据。后续测试使用 `-collect-test-diagnostics never` 仅停止失败时自动采集 sysdiagnose，全部测试和断言仍执行，显式截图、布局记录及 xcresult 继续保留。

## 验证记录

| 环境 / 验证 | 实际结果 | 原始证据（项目相对路径） |
| --- | --- | --- |
| iPhone 16 Pro / iOS 18.5，全量单元与 UI | **80/80 通过：55 单测 + 25 UI，零失败、零跳过**；覆盖原六条失败用例 | `work/release-20261022/PhoneFinal.xcresult`、`phone-final.log`、`phone-summary.json` |
| iPad Pro 13 英寸 M5 / iPadOS 27.0，九条关键 UI | 首轮 8 通过、1 条反弹课题等待时序失败；修复等待真实可见回放/结算并扩大实际运动等待后，该条单独重跑通过；九条均有通过证据 | `iPad.xcresult`、`ipad-summary.json` + `iPadBankFinal.xcresult`、`ipad-bank-summary.json`（均在上述 work 目录） |
| iPhone SE 3 / iOS 18.5，375pt 小屏 | 隐私两入口、最大字体、反弹精通、花园/语录共 4 条通过；另在 Dark 模式补跑最大字体政策 1 条通过 | `SmallPhone.xcresult`、`SmallPhoneDark.xcresult` 与对应 summary/log |
| Duo 展开 / iOS 27.1 | 反弹精通、隐私两入口、最大字体及真实商店采集流程共 4 条通过；最终原始 framebuffer 采集流程另 1 条通过 | `DuoInner.xcresult`、`DuoStoreNative.xcresult` 与对应 summary/log |
| Duo 原生 Device Hub 姿态操作 | 真实 Open、Closed、Book、Rotate Right；开合/内外屏横竖屏、两种活跃半折区域、重新展开均已采样，按钮区域冲突为空 | `docs/screenshots/release-20261022/duo-continuity/manifest.json` 及七组 PNG/布局 JSON |
| 设备 Release 归档 | **ARCHIVE SUCCEEDED**；未签名；核对包标识、版本、设备家族、最低系统、语言、加密声明、政策与清单，无 Swift 源文件误入 Resources | `work/release-20261022/FoldPutt-final-unsigned.xcarchive`、`archive-final.log`、`archive-final-inspection.json` |

测试为真实执行的 XCTest/XCUITest；截图与静态配置核查另行记录，不与测试数量混加。iPad 首轮失败与修复后的复跑都保留，没有把首轮写成全通过。全量 iPhone 后增加的联系资料/链接显示及 UI 等待修正由小屏、iPad 和 Duo 的相关流程覆盖；最后的局/击球 UUID 诊断仅在 Debug 编译，不影响已通过的 Release 归档，无需因说明文档和 Debug 诊断重跑整套。

### Duo 连续性与区域证据

前六组姿态保留同一 `roundID=D091BE22-2287-45B6-80E6-B09946D91045`、`launchID=7A57512E-3929-41E2-93A6-D21A874B428D`、1 杆与相同世界球位。依次验证外屏横向 678×466pt、内屏 669×951pt、内屏 951×669pt、竖向活跃区域 `{{455.5,0},{40,669}}`、横向活跃区域 `{{0,455.5},{669,40}}`，重新展开后活跃区域清空。第七组补充外屏竖向 466×678pt，四边 inset 为 top=0、left=0、bottom=34、right=84，确认非对称安全区下按钮与拉杆可见。每组实际 traits、安全区和区域均在 JSON 中。

另一次真实水平拖杆后立即 Closed，采样记录到内屏 `rolling` 6 次、外屏 `rolling` 21 次：同一 `roundID=52B86BBA-4BE0-4E67-8067-735CA29CCC33`、`launchID=ADD5631F-B410-419C-AEA1-E2CE6AB26994`，保持 1 杆，球继续运动后自然停稳；没有注入球位、速度或结算。原始只读采样在 `work/release-20261022/duo-inflight-samples.json`。前六张停球后采样中出现轻残局，是工具操作实际超过 60 秒的时间惩罚，不是折叠触发。

### 商店素材

已提供 **19 张不透明 JPEG**：iPhone 6 张（1206×2622）、iPad 6 张（2064×2752）、Duo 内屏 6 张（2007×2853）及外屏 1 张（1398×2034）。均为实际 UIKit 模拟器画面，来自真实入口、击球、通关得种子与种花；没有使用概念图、浏览器原型、诊断叠层或注入奖励。已逐图目视核对。PNG 原件、布局、来源/哈希与系统信息均保留。

Duo 的 XCTest 窗口截图少一像素（2006×2852），未缩放/补边冒充官方规格；改为在真实 UI 稳定时读当前显示屏的原生 framebuffer，获得 2007×2853，再仅编码成 JPEG。被拒绝尺寸的旧采图留在 work 中，没有进入物料包。最终分发工具链如产生可见变化，应更新受影响的商店图。

[当前后台填写清单](../release/App-Store-Connect-填写清单.md) 提供逐字段可复制值；[物料目录](../release/app-store/README.md) 包含中英文独立文本、图标和截图。[完整 ZIP](../release/FoldPutt-AppStore-20261022.zip) 包含清单、物料与网页源码，不包含未签名归档或测试日志。

### 覆盖边界

- 本轮均为模拟器；未进行物理 Duo 的光学折痕、握持、触感、温度与续航验收，未做 Instruments 性能分析或完整 VoiceOver 审核。
- 最低部署版本仍是 18.0；本机最低可用运行时为 18.5，没有宣称实际跑过 18.0。版本保护做静态核查。
- Debug 半窗夹具通过只证明容器重排；本轮未完整验收真实系统左右 Split View、PiP 与全部多窗口组合。
- 归档工具链为 Xcode 27.1（27A9269）/ iOS 27.1 SDK，**beta、未分发签名**；构建成功不代表已满足 App Store 上传资格。没有 TestFlight 安装或后台上传证据。

## 外部待办

- 本机 `27A9269` 为 beta build；苹果已接受的正式 27.1 为 `27A9275`。需正式工具链重建、分发签名及上传验证。本轮没有换用旧 SDK 来绕过 Duo API，也没有全局切换 Xcode。
- 网页部署已完成，不再是阻塞；将上方真实隐私/支持 HTTPS URL 填入后台即可。App内仍可离线读，公开网址和部署记录在 `release/web/hosting.json`，没有将苹果登录账号发布到站点。
- 用户已确认会员开通，尚未登录核对具体 Team、App 记录与 Bundle ID 归属；审核联系人真实姓、名、国际电话未提供。Wayne 作为用户指定公开名称，不代表已核验苹果账号的法定卖方名称。
- 具体海外地区名单与适用地区要求待后台落实。中国大陆已排除，不将大陆审批列为本轮前置。
- 资源已按实际资产与本地生成记录整理来源，见 `release/app-store/asset-provenance.md`；生成账号的适用条款和最终权利确认不能由源码或文件哈希替代，Content Rights 按真实持有权利填写。

依据：[正式 Xcode build](https://developer.apple.com/news/releases/?id=10152026a)、[App Store Connect 接受状态](https://developer.apple.com/help/app-store-connect/release-notes/)、[隐私清单与 Required Reason](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)、[截图规格](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)。
