# FoldPutt 上线可行性与 App Store Connect 填写包

核查日期：2026-10-22（北京时间）。目标窗口：2026-10-23 iPhone Duo 首批开售。

> 网站后续更新：[隐私政策](https://foldputt-help-wayne.humble-mite-6617.chatgpt.site/privacy) 和 [支持页](https://foldputt-help-wayne.humble-mite-6617.chatgpt.site/support) 已公开部署，联系邮箱统一 waynelessdo@gmail.com。按新要求补充 [国际语言与实际提审步骤](../release/国际上架语言与操作步骤.md)；下文关于未建站/未开通会员等属于原始快照，不再作为当前阻塞。

> 已完成实施更新：开发者会员已开通；首发支持 iPhone、iPad 并保留 Duo，海外首发不含中国大陆；公开名称 Wayne，支持邮箱 waynelessdo@gmail.com。隐私清单、离线政策、失败回归及 19 张商店实图已交付，完整验证见 [发布准备报告](release-prep-20261022.md)。**当前填写请直接使用 [最新逐字段清单](../release/App-Store-Connect-填写清单.md)**；以下保留首轮评估和初版草稿，旧的“会员未开通/隐私入口缺失/未制作素材”等叙述仅对应实施前快照。政策/支持网页已有源码，公开 URL 仍待托管。

本文是基于当前工作区的发布评估与填写草稿，不表示已经上传、通过审核或上线。已读取现有未提交修改；本次不改游戏代码、签名、版本或销售地区，不提交、不推送。后台账号状态尚未核验。

### 用户已确认的首发方向（2026-10-22 补充）

- **首发仅选择合规资料齐全的海外地区，暂不含中国大陆。** 具体国家/地区名单仍待确定，不默认全球全选；下方大陆材料仅供后续进入该市场参考，不阻塞本轮海外首发。
- Apple Developer 付费会员：用户后续确认 **已开通**。App 记录、实际 Team 与发布权限仍需核对；不再把会员注册当作当前阻塞。
- 当前账号工作是核对对应 Team、App 记录及分发签名，不是要求重复开通会员。下方注册说明仅保留供需要时参考。

## 1. 结论：已有产品基础，当前不具备直接上线条件

**总体判断：后续上线有条件可行；明天公开上线风险高，不应承诺。**

你提供的日期正确：苹果公告写明首批地区（包括中国）于 **2026-10-23** 开售，另有地区在 10 月 30 日开售。[苹果发布公告](https://www.apple.com/newsroom/2026/09/apple-unveils-iphone-duo/)

当前不是空骨架：已有 Swift/UIKit 游戏、三张练习地图、六道反弹课题、普通/Q 版表现、花园/语录、本地保存和 Duo 布局处理。但“可运行游戏”和“可提交的分发包”仍有明确距离。

| 目标 | 当前判断 | 达成条件 |
| --- | --- | --- |
| 10 月 23 日在 App Store 公开下载 | 高风险，目前不能给 Go | 先解决下列阻塞，再经历上传处理、审核和上架传播；都不能保证当天完成 |
| 尽快准备可提审版本 | 有条件可行 | 正式工具链、隐私、平台范围、回归、素材和账号资料齐备 |
| 中国大陆首发 | 用户已明确暂不纳入本轮 | 后续进入该市场时再核验游戏审批与后台要求的真实材料 |
| 先在资料齐全的海外地区首发 | 用户已确认方向，有条件可行 | 完成会员、工程发布与所选地区要求；具体名单未定，不能把“海外”理解为自动全部合规 |

苹果公布的平均数据是 90% 的提交在 24 小时内完成审核，**审核完成可能是拒绝，也不等于指定时刻可下载**。首次发布还包括账号、构建处理、补件和商店传播时间。加急审核可申请，但不保证受理、通过或时效。[App Review](https://developer.apple.com/app-store/review/)

### 已核实的项目基础

| 项目 | 当前事实 | 本地依据 |
| --- | --- | --- |
| 技术栈 | Swift + UIKit；当前最低 iOS 18.0 | `FoldPutt.xcodeproj/project.pbxproj` |
| Bundle ID | `com.mavericklab.foldputt` | 工程 Debug/Release 配置 |
| 版本/构建号 | `0.2.0` / `1` | `App/Info.plist`；现有 Release 模拟器产物 |
| 支持设备 | `TARGETED_DEVICE_FAMILY = "1,2"`，含 iPhone 和 iPad | 工程及现有产物 `UIDeviceFamily=[1,2]` |
| 玩法内容 | 3 张练习图 + 6 张课题图，共 9 张；两种外观共用规则 | `Resources/Levels/`、`Models/FPClubProgress.swift`、收藏页 |
| 收费与账号 | 当前源码未见内购、广告、登录或运行时联网模块 | App/Models/Systems/Views 的 import 与调用扫描；仍须复核最终包 |
| 保存 | UserDefaults 保存偏好/收藏；Application Support 保存对局 checkpoint | `Models/FPClubProgress.swift`、`App/SceneDelegate.swift` |
| 图标 | 已有 1024×1024、无 alpha 的 PNG | `Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png`；本次 sips 核验 |
| 历史单测 | 2026-10-11 的 54 项通过 | `work/duo-fit-20261011/unit-after-calibration.log` |
| 历史 UI 回归 | 全量 22 条中 **6 条用例失败、共 8 处断言失败** | `work/duo-fit-20261011/phone-full-ui.log` |
| Duo 历史证据 | 有 compact/regular 实际模拟器运行与收藏/课题证据；受控连续折叠矩阵未完 | [适配报告](duo-fit-20261011.md) |
| 发布包 | 仓库和本地 work 中未发现 `.xcarchive` / `.ipa` | 本次目录检查；不能据此推断其他目录或后台没有包 |

**测试口径纠正：**旧交付文档把 8 个 failures 写成了 8 条失败测试。原始日志中实际失败用例为 `testHalfWindowKeepsShot`、`testOptionsInLandscape`、`testOptionsScrollOutsideDismissAndHapticsToggle`、`testPullAndHandheldMenu`、`testQModePickerRealPuttAndNextLevel`、`testTuningWinBoostPenaltyFlow`。因此是 16 条通过、6 条失败、8 处断言失败。此前已在基线复现，不代表本次适配引入；但发布仍需区分真实缺陷、过期测试或自动化限制，并补齐证据。不能因为“既有失败”就视为发布已验收。

### 发布前必须闭环的事项

| 优先级 | 缺口与影响 | 完成标准 |
| --- | --- | --- |
| P0 | **本机工具链是 beta build**：`xcodebuild -version` 为 27.1 / `27A9269`，官方将该 build 列为 beta；正式版为 `27A9275` | 使用官方已接受的正式/获准 RC 工具链重建、归档、验证上传；当前不能把历史 Release 模拟器构建当分发资格证明 |
| P0 | **缺少隐私清单**：生产源码和所查现有 Release 包均没有 `.xcprivacy`，但实际调用 UserDefaults 和 systemUptime | 补充正确的 Required Reason 声明并进入 App target 的最终包；检查归档隐私报告 |
| P0 | **缺少公开隐私政策与 App 内入口**：源码未发现相关页面/链接 | 公布真实 HTTPS 隐私政策；App 内容易找到；内容与最终包一致 |
| P0 | **会员/记录待核验，用户反馈“尚未开通或不确定”**：工程 Team ID 不能证明付费会员、协议、Bundle ID 归属或发布权限有效 | 先核验所选 Team；未开通则完成注册、身份验证、付费及激活，再核对协议、App 记录、签名与上传 |
| P0 | **支持网址、审核联系人、权利主体尚未提供** | 填入真实主体、邮箱、电话及可访问的支持页；清理全部占位符 |
| P0（按地区） | 海外具体名单未定，适用的越南游戏许可、欧盟 DSA 等条件未知 | 按最终地区满足要求；中国大陆已排除，相关审批不作为本次海外首发前置 |
| P1 | 全量 UI 失败未关闭，覆盖主操作、换关与奖惩 | 逐条诊断；修产品或修过期测试；自动化受限的场景提供可复现人工验收记录，不能删断言制造通过 |
| P1 | Duo 连续开合/旋转/两种半折/实际左右分屏未完整验收 | 在最终候选版本完成 Device Hub 场景；确认不丢球局、按钮可达、区域避让正常；记录实际 bounds/traits/四边 safe area/regions |
| P1 | 当前包包含 iPad，却未见完整 iPad 发布验收/商店图 | 二选一：保留并补 iPad 测试和 13 英寸截图；或明确决定首发仅 iPhone 后重建并核对最终 UIDeviceFamily；Duo 本身属于 iPhone |
| P1 | 最低 iOS 18.0，但现有普通手机证据主要为 18.5 | 补最低版本及当前正式系统冒烟；不能把 availability 静态检查写成 iOS 18.0 实测 |
| P1 | 现有图是交付/诊断截图，未整理成最终发布素材包 | 从最终候选包采图；确认尺寸、无透明、无测试夹具/诊断字、无未发布功能 |
| P1 | 素材权利记录有历史出入：初期清单写“无 AI”，后续有 AI 图像记录 | 核对实际打包资源、字体、声音及生成服务使用权；不要直接声明全部手工原创或无第三方内容 |

工具链依据：[27A9269 beta 记录](https://developer.apple.com/news/releases/?id=10132026d)、[正式版 Xcode 27.1（27A9275）](https://developer.apple.com/news/releases/?id=10152026a)、[App Store Connect 10 月 15 日起接受 27.1 正式版](https://developer.apple.com/help/app-store-connect/release-notes/)。本次没有安装/切换工具链或尝试上传。

隐私依据：[UserDefaults 声明要求](https://developer.apple.com/documentation/foundation/userdefaults)、[Required Reason API](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)、[审核指南 5.1.1](https://developer.apple.com/app-store/review/guidelines/#privacy)。本项目至少需评估 `NSPrivacyAccessedAPICategoryUserDefaults / CA92.1`（App 自身数据）和 `NSPrivacyAccessedAPICategorySystemBootTime / 35F9.1`（App 内事件间隔）；完整 API 扫描与归档校验仍需做。它们是包内工程声明，不能靠在后台填“不收集数据”替代。

### 推荐推进范围与时间

建议冻结当前九张地图及收藏内容，不再加新玩法。首发候选范围为免费、无广告、离线、本地保存的 iPhone 游戏，保留普通机型完整可玩。销售方向已确认为合规资料齐全的海外地区、不含中国大陆；具体名单及是否收窄 iPad 仍待决定，本次没有修改后台或工程配置。

在“会员有效、主体资料现成、正式工具链可用、没有重大玩法缺陷”的假设下，发布准备粗估 **2–4 人日，单人约 2–5 个工作日**，置信度低：隐私与发布配置约 0.5–1 日，失败场景诊断和多尺寸回归约 1–2 日，截图/网页/元数据/签名上传约 0.5–1 日，部分可并行。另加会员注册/身份验证/激活、苹果审核、构建处理与适用地区资质等待，这些不包含在上述区间。**用户补充后，“会员有效”这一前提尚未成立，因此该区间仅是条件性工程估算，不能当总上线工期。** 即使今天完成开通，也不能承诺明天公开下载。

### 第一步：核验或开通开发者会员

先在 [Apple Developer 账号](https://developer.apple.com/account/) 查看 Membership，确认当前选择的 Team；再检查 [App Store Connect](https://appstoreconnect.apple.com/) 是否能访问对应团队的 Apps。仅有免费开发者账号、Personal Team、真机调试安装或能打开登录页面，都不能证明已具备商店分发资格。已有有效会员时复用，避免重复注册。

如尚未开通，按[苹果官方注册入口](https://developer.apple.com/programs/enroll/)与[会员注册说明](https://developer.apple.com/help/account/membership/program-enrollment/)完成流程。个人以真实法定姓名注册，商店卖方通常显示个人姓名；组织需要合法实体、签约权限及适用的 D-U-N-S 等资料。不要为了赶日期选择不符合实际的主体。身份验证、付款和激活的完成时间以苹果处理为准，不保证当天；此等待与 App 内容审核是两条流程。

| 核验/开通项目 | 可复制的记录或填写模板 | 完成证据 |
| --- | --- | --- |
| 所属 Team | `团队名称：【实际名称】；Team ID：【实际值】` | Membership 与 App Store Connect 对应同一发布团队；不默认采用代码中的 Team ID |
| 会员状态 | `会员状态：【Active / Pending / 未注册】；到期日：【后台日期或不适用】` | Active 且有效；待处理不能写已激活 |
| 注册主体 | `注册类型：【Individual / Organization】；法定名称：【真实姓名或实体名称】` | 与真实发布主体及验证文件一致 |
| 联系资料 | `邮箱：【真实邮箱】；电话：【国际格式电话】；地址：【真实联系地址】` | 按注册流程验证；注册地址规则与 DSA 公开邮政信箱规则不同 |
| Apple Account 双重认证 | `双重认证：【已开启 / 待开启】` | 账号设置与注册要求一致 |
| 组织补充资料（适用时） | `D-U-N-S：【真实编号】；签约授权人：【姓名/职务】；工作邮箱：【组织域名邮箱】` | 按苹果组织验证要求提供，个人注册不硬套该项 |
| 协议/付费/激活 | `协议：【状态】；会员付款：【状态】；激活：【状态】` | 以后台激活与有效会员状态为准；费用按当地官方结账显示 |
| FoldPutt App 记录 | `App Apple ID：【后台值】；Bundle ID：【账号下注册值】；记录状态：【状态】` | 没有记录时，在会员就绪后按第 4 节建立；上传包 ID 一致 |

在账号处理期间可以继续完成隐私、工程回归、网页正文和截图准备，不必等会员审核结束才做这些工作。仍需在账号就绪后验证实际签名与上传链路。

## 2. 怎么使用这份填写包

- **【可复制】**：与当前已知实现一致的文案；发布前仍应对照最终候选版本。
- **【替换后复制】**：先把 `【…】` 替换为真实资料，再粘贴。没有真实值就保留待办，不能提交占位符。
- **【条件成立后复制】**：对应验证或法律/资质事实成立后才能使用。
- 表格中的选择项可按所列文字在后台点选；它们通常不是自由文本输入框。
- “留空”“不适用”“不上传”表示不填写或不提供，不要把这几个字粘贴进 URL、账号或附件字段。
- 图片、视频、构建包、营业执照、审批证明必须上传真实文件。每项已提供可复制的制作说明/标题，但文字不能代替附件。

### 先补齐的真实资料

| 资料 | 可复制模板 | 用途 |
| --- | --- | --- |
| 权利主体 | `【个人真实姓名或公司法定名称】` | 版权、政策、账号身份；不要默认工程反域名就是公司名称 |
| 开发者展示名 | `【账号允许使用的开发者名称】` | 受个人/组织账号规则约束，不是任意品牌签名 |
| 支持邮箱 | `【可持续收信的支持邮箱】` | 支持页、隐私联系 |
| 审核联系人姓/名 | `【审核联系人姓】` / `【审核联系人名】` | App Review Information |
| 审核邮箱 | `【可及时回复审核问题的邮箱】` | 可与支持邮箱相同 |
| 审核电话 | `+【国家或地区代码】【电话号码】` | 真实、可接通，使用国际格式 |
| 网站根地址 | `https://【实际可访问域名或托管站点】` | 没有站点先发布网页；本地 .md 路径不能填 URL |
| 隐私政策 URL | `https://【实际域名】/foldputt/privacy` | 路径为建议，发布后以真实地址替换 |
| 支持 URL | `https://【实际域名】/foldputt/support` | 必填，必须有真实联系方式 |
| 营销 URL | `https://【实际域名】/foldputt` | 可选；未建可留空 |
| 生效日期 | `【政策实际生效日期，YYYY-MM-DD】` | 不自动把评估日当生效日 |
| DSA 公开联系资料 | `【公开地址或合规邮政信箱】` / `【公开联系电话】` / `【公开联系邮箱】` | 若在欧盟以交易者身份分发，完成真实验证 |

不需要把密码、验证码、证书私钥、身份证或银行卡放进此 Markdown。通过苹果官方后台提交敏感身份材料。

## 3. 需要准备的物料

截图规范按 2026-10-22 官网核对：每设备尺寸至少 1 张、最多 10 张，PNG/JPEG 且不含 alpha。当前必需普通 iPhone Dynamic Island 中尺寸截图；支持 iPad 时需 13 英寸截图。Duo 图目前可提交，2027 年 4 月起对相应 SDK 提交变为要求；提交合格 Duo 图可展示优化徽章。为本次 Duo 首发目标，建议本轮就提供 Duo 内外屏实图。[苹果截图规范](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)

| 物料 | 是否需要 / 当前状态 | 交付规格或用法 | 可复制的制作说明/描述 |
| --- | --- | --- | --- |
| 分发构建 | 必需；未见现成归档 | 正式工具链 Archive，经 Organizer/Transporter 上传并处理完成；不是模拟器 `.app` | `FoldPutt 首发候选版本；Bundle ID com.mavericklab.foldputt；版本与后台一致；使用 Release 分发归档。` |
| App Icon | 必需；已有母图 | 现有 1024×1024 不透明图经资产编译随构建提交；还需目视确认最终品牌效果 | `FoldPutt 应用图标：高尔夫球与球洞主题；使用现有 AppIcon，不预裁圆角，不含透明像素。` |
| 普通 iPhone 截图 | 必需；已有历史实图待筛选重采 | 推荐直接采 iPhone 16 Pro：1206×2622，横图 2622×1206；官网也接受 1179×2556 及横向 | `展示正式版单指拖拽拉杆、完整球道和清晰的杆数信息。` |
| Duo 外屏截图 | 本次推荐 | 1398×2034 或 2034×1398 | `合上也能轻松打一杆。展示实际外屏运行画面与可操作拉杆。` |
| Duo 内屏截图 | 本次推荐 | 2007×2853 或 2853×2007；推荐横向游戏实图 | `展开，球场更开阔。展示实际内屏球道与位于可用区域的操作按钮。` |
| iPad 截图 | 保留 iPad 支持则必需 | 13 英寸：2064×2752 或 2048×2732；可横向交换宽高 | `在 iPad 上查看完整球道，用同一套单指拉杆操作完成击球。`（仅在实际验收后使用） |
| App Preview | 可选，首发可留空 | 真实运行录像，15–30 秒、≤500MB、最高 30fps；建议 H.264；对应设备接受分辨率按官网导出 | `拉一杆，松手出发。挑战反弹课题，把通关收获种进自己的小花园。` |
| 审核演示视频 | 非通用必填；Duo 行为难复现时建议 | 普通击球、展开/合拢续玩、手动控显分离、结算与收藏；向审核提供可访问附件/链接 | `演示 FoldPutt 的实际击球流程、Duo 尺寸变化下的球局连续性及普通 iPhone 的等价操作入口。` |
| 隐私政策网页 | 必需；待发布 | 公开可访问，无登录；App 内入口指向同页；正文见第 8 节 | `FoldPutt 隐私政策` |
| 用户支持网页 | 必需；待发布 | 能找到真实邮箱/联系方法；正文见第 8 节 | `FoldPutt 用户支持` |
| 营销网页 | 可选 | 介绍当前已发布功能；可先不用 | `FoldPutt：拉一杆，种一点好心情。` |
| 资源权利证据 | 需具备，必要时应审核要求提供 | 图像/音效/字体来源、生成记录、适用许可；不等于必须上架公开 | `FoldPutt 发布资源权利清单：逐项记录实际打包文件、来源、许可依据与持有人。` |
| 大陆审批材料 | 本轮海外首发不需要；未来大陆分发时核验 | 真实游戏批准/ISBN 证明、营业执照及适用授权/备案材料 | `FoldPutt 中国大陆游戏发布证明材料，信息与审批主体及后台元数据一致。` |
| 欧盟交易者证明 | 适用时必需 | 真实主体/地址证明、电话及邮箱验证；以后台要求为准 | `FoldPutt 欧盟分发主体联系资料及身份/地址核验材料。` |
| Product Page Header 等 Creative Assets | 可选，可延期 | 属于额外商店展示物料；按当前后台规格制作，不阻塞基础首发 | `FoldPutt：一片小草坪，一次轻松的迷你高尔夫。` |

App Preview 的尺寸、编码及播放要求请对照[苹果视频规范](https://developer.apple.com/help/app-store-connect/reference/app-information/app-preview-specifications/)。本次没有制作发布图/视频，也没有把历史截图标成最终发布物料。

### 建议的截图顺序与可复制文案

这些是叠在真实运行图外的可选宣传字，不是后台必填的截图描述字段。首发可先做 4–6 张；普通 iPhone 与 Duo 以真实对应尺寸分别上传。

| 顺序 | 对应实际画面 | 主标题（可复制） | 副文案（可复制） |
| --- | --- | --- | --- |
| 01 | 拖杆瞄准的完整球道 | `拉一杆，松手就出发` | `一个手势，同时掌握方向与力度。` |
| 02 | Duo 展开内屏 | `展开，球场更开阔` | `让球道随可用空间舒展。` |
| 03 | 普通与 Q 版相同球场 | `同一片球场，两种心情` | `熟悉的草坪，也能遇见有表情的小球。` |
| 04 | 反弹课题选择/实际通关 | `借一面墙的力` | `六道反弹课题，先打通，再打漂亮。` |
| 05 | 已实际种花的花园 | `把通关收获种进花园` | `九格花圃，三种小花，慢慢布置。` |
| 06 | 语录册或入洞结果 | `失手，也有一句好心情` | `收集球友短句，按自己的节奏再来一杆。` |

不要在图片中写“苹果官方推荐”“首发独占”“全姿态零中断”“完整 VoiceOver 支持”，当前没有这些证据。不要用 `prototype/` 网页或 `Resources/AIConcepts/` 概念图当运行截图。不要把 951×669pt 当上传像素尺寸；pt 与像素按实际采图 scale 区分。

## 4. 新建 App 与 App 信息：逐项可复制

后台字段可能随账号、地区、App 状态显示不同；以下对应本项目。规则依据：[新建 App](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app)、[App 信息字段](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/)。

| 字段 | 建议填写 / 可复制值 | 条件或说明 |
| --- | --- | --- |
| Platforms | `iOS` | 设备家族从构建决定；新建页面选 iOS 不代表仅支持 iPhone |
| Name / 名称 | `FoldPutt` | 8 字符；需后台确认可用与权利，无需为赶日期强行改名 |
| Primary Language | `Chinese (Simplified)` / `简体中文` | 与当前中文 UI 对齐；这是元数据语言，不会自动生成 App 翻译 |
| Bundle ID | `com.mavericklab.foldputt` | 选择账号下同 ID 的显式 App ID；必须与包一致；不能杜撰已注册状态 |
| SKU | `foldputt-ios-202610` | 新建时的内部追踪值建议；若已有 App 记录，沿用已有 SKU |
| User Access | `Full Access` / `完全访问权限` | 仅在该团队内部访问范围符合你的意图时选择，否则限定人员 |
| Apple ID | `【后台自动生成的数字 Apple ID】` | 只记录，不自编；不是登录 Apple Account |
| Subtitle / 副标题 | `拉一杆，种一点好心情` | 10 字符；上限 30 |
| Primary Category | `Games` / `游戏` | 按真实玩法选择 |
| Games Subcategory 1 | `Sports` / `体育` | 迷你高尔夫主玩法 |
| Games Subcategory 2 | `Puzzle` / `益智解谜` | 反弹课题；若后台不适用可只留一个子类 |
| Secondary Category | `留空` | 可选，不为了凑字段选择不相关分类 |
| Content Rights | `【按实际打包内容选择无第三方内容，或已获得所需权利】` | 必须完成资源清查后点选，不能直接照初期“全部生成”文档选无第三方 |
| License Agreement | `Apple Standard EULA` / `使用 Apple 标准许可协议` | 无需提交自定义 EULA；政策和 EULA 是不同内容 |
| Made for Kids | `不选择儿童类别` | 本项目未按 Kids 类别设计；低年龄评级不等于儿童专用 App |
| Privacy Policy URL | `https://【实际域名】/foldputt/privacy` | 替换为已上线页面；必须可访问 |
| Privacy Choices URL（如出现） | `留空` | 可选；当前没有在线账号或数据选择中心，不捏造入口 |
| Regulated Medical Device（如出现） | `No` / `否` | 当前为游戏；不是医疗器械 |

## 5. iOS 版本页面：可复制商店文案

长度限制与字段含义依据[平台版本信息](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/)。描述用纯文本，不粘贴 Markdown 标题/代码围栏。

### 中文名称

```text
FoldPutt
```

### 中文副标题

```text
拉一杆，种一点好心情
```

### 宣传文本 / Promotional Text（可选，上限 170 字符）

```text
拉动、松手，让小球出发。九张地图、六道反弹课题，还有能慢慢种满的小花园。普通与 Q 版随心切换，无广告、无内购，离线也能轻松打一杆。
```

### 描述 / Description（必填，上限 4000 字符）

```text
一片小草坪，一次小小出发。

FoldPutt 是一款轻松的迷你高尔夫游戏。单指拖拽拉杆，同时决定方向与力度，松手就能击球。绕过沙地，借一面墙的力，把球送进球洞。

【九张地图，按自己的节奏挑战】
三张练习地图与六道反弹课题，随时选择想玩的球场。所有课题直接开放，失手可以继续，不需要等待解锁。

【普通与 Q 版，两种球场心情】
喜欢清爽的草坪，或想让小球多一点表情，都可以随时切换。外观改变，同一局的挑战继续。

【通关之后，种一点好心情】
每次完成球场都能获得种子。在九格花园里种下小雏菊、郁金香或蓝风铃，慢慢布置自己的小角落。

【收集球友的短句】
击球、碰墙、擦洞或入洞时，遇见一点温柔或一点嘴硬。喜欢安静，也可以切换语气、关闭声音与触感。

【球场随空间舒展】
在普通 iPhone 上轻松拉杆，在 iPhone Duo 的更大可用空间里欣赏球道。也可手动切换控显分离，不需要特定折叠姿态才能玩。

无需注册，核心玩法可离线进行。游戏进度与收藏保存在设备本地。
无广告、无内购、无付费复活。

需要帮助？请通过 App Store 的“App 支持”联系开发者。
```

此文案未承诺联机、地图编辑器、每日新图、云同步或无限关卡。它们不能因为浏览器体验馆中存在就写进原生商店描述。“球场随空间舒展”一节需在最终 Duo 回归完成后保留；否则先删去该节，不宣称尚未验收的能力。

### 关键词 / Keywords（必填；按官网保守控制在 100 UTF-8 bytes 内）

```text
高尔夫,推杆,迷你,休闲,益智,反弹,种花,离线,解压
```

上面为 19 个汉字加 8 个逗号，共 **65 UTF-8 bytes**；不添加空格、竞品名或未经允许的品牌名。若后台对中文分词有不同提示，以实际校验为准。

### 其他版本字段

| 字段 | 可复制值 / 动作 | 说明 |
| --- | --- | --- |
| Version | `0.2.0` | 与现有 Info.plist 对齐，首发不强制叫 1.0；如决定 1.0.0，必须同步修改工程并重建，本次未改 |
| Build | `【上传且处理完成的 0.2.0（实际构建号）】` | 从后台选择，不能输入文案替代；已有构建号占用时递增 |
| 当前 Build Number | `1` | 仅为本地现值；后台是否已使用未知 |
| Copyright | `2026 【实际权利主体】` | 替换主体；后台自动加 ©，不用重复写 |
| Support URL | `https://【实际域名】/foldputt/support` | 必填，需真实联系信息 |
| Marketing URL | `https://【实际域名】/foldputt` | 可选，没建站就留空 |
| What's New in This Version | `首发版本不填写此字段` | 苹果首次发布不提供该字段；不能把它当首发必填 |
| Routing App Coverage File | `不适用，不上传` | 不是地图导航 App；游戏球场不需要 GeoJSON |
| Game Center | `关闭 / 不启用` | 当前是本地个人成绩，无 Game Center 接入 |
| In-App Purchases / Subscriptions | `无，不创建商品` | 符合当前无付费产品约束 |
| App Clip / iMessage / Watch 等 | `不适用，不创建` | 当前没有对应扩展 |

若实际是在更新已有公开版本，可使用以下“更新说明”草稿，**仅在相对线上版本确实新增这些内容时使用**：

```text
新增六道反弹课题，以及可用通关种子布置的九格花园。
新增球友短句收藏，支持切换语气与安静打球。
优化不同窗口尺寸下的布局、区域避让与收藏阅读位置恢复。
```

### 英文商店本地化（可选）

若首发面向英文用户，可以添加英文商店元数据，但当前未核验到完整英文 App UI。下列描述明确告知中文界面；它不能代替代码本地化，也不应把二进制语言列表标成已支持英文。

名称：

```text
FoldPutt
```

副标题（不超过 30 字符）：

```text
Pull, putt, plant a little joy
```

宣传文本：

```text
Pull back and release. Explore nine courses, tackle six bank-shot puzzles, and grow a tiny garden. Play offline with no ads or in-app purchases. UI in Simplified Chinese.
```

描述：

```text
A small green. A little moment of joy.

FoldPutt is a relaxed mini golf game. Drag the pull control to set direction and power, then release to take your shot.

Explore three practice courses and six bank-shot puzzles. All puzzles are available from the start. Switch between classic and expressive character visuals while keeping the same round.

Finish courses to earn seeds, then arrange daisies, tulips, and bluebells in your nine-plot garden. Discover short reactions from your golf buddy, or choose a quieter mood.

Play on iPhone and enjoy a roomier course on iPhone Duo. A manual separated-control option is also available; no special folding pose is required.

No account is required. Core gameplay works offline. Progress and collections are stored on your device. No ads or in-app purchases.

The current in-app interface is in Simplified Chinese.
For help, use the App Support link on this page.
```

关键词：

```text
golf,putting,casual,puzzle,offline,garden,relaxing,bankshot
```

## 6. 隐私、年龄分级、合规与分发选项

### App Privacy：按最终构建确认后填写

当前源代码支持“不把游戏数据发送给开发者”的初步判断；这不是已经完成网络审计。公开网页托管商日志、用户主动发来的邮件、Apple 自身诊断与 App 主动上传数据应区分描述。隐私标签以最终 App 和集成 SDK 的实际行为为准。[后台隐私填写说明](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy)

| 后台项目 | 条件成立后的可复制选择 / 描述 | 核验条件 |
| --- | --- | --- |
| 是否收集数据 | `No, we do not collect data from this app` / `否，我们不从此 App 中收集数据` | 最终包无埋点上传、广告 SDK、第三方收集或其他传出业务 |
| 跟踪 / Tracking | `No` / `否` | 无跨 App/网站广告追踪；当前未见相关实现 |
| 数据类型 | `不添加数据类型` | 仅限上一项确实不收集；不是把本地收藏误填为服务器收集 |
| 隐私政策 URL | `https://【实际域名】/foldputt/privacy` | 已公开且 App 内可达 |
| 解释本地保存（审核备注可用） | `游戏进度、个人成绩、花园、语录收藏及偏好在设备本地保存，App 不主动将其传送至开发者服务器。` | 对照最终实现；不要写成“系统备份永远不会备份” |

提交前还需在工程内补 Required Reason 清单。可复制给发布开发工作的说明：

```text
为 FoldPutt 的最终分发包补充 PrivacyInfo.xcprivacy，声明实际使用的 Required Reason API。UserDefaults 用于 App 自身偏好与本地收藏，评估 CA92.1；systemUptime 用于本 App 内点击事件时长判定，评估 35F9.1。核查其他 API 类别及所有依赖，并确认清单实际打入归档。App Store 隐私标签与包内清单分别完成。
```

### 年龄分级问卷

按当前内容建议如下，**最终年龄等级由苹果问卷生成，不能手工保证 4+**。不选 Kids 类别，不凭“体育”二字选择暴力。碰墙、落水和表情球不等于人物暴力，但仍需查看最终视听内容。[年龄分级问卷](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating)

| 问卷内容（按后台显示的对应项） | 可复制选择 / 判断 |
| --- | --- |
| 家长控制 / Parental Controls | `No`（App 无自建家长控制；不表示关闭系统限制） |
| 年龄验证 / Age Assurance | `No`（无自建年龄验证） |
| 无限制网页浏览 | `No`（支持/政策链接不构成无限制内置浏览器） |
| 用户生成内容 | `No` |
| 消息/聊天 | `No` |
| 广告 | `No` |
| 脏话/粗俗幽默 | `None` / `无`（发布前核对全部短句；“嘴硬”本身不是粗口） |
| 恐怖/惊吓、成人/性暗示主题 | `None` / `无` |
| 酒精/烟草/毒品 | `None` / `无` |
| 医疗/治疗信息、健康养生建议 | `None / No`（按字段类型选择；“放松”不提供治疗承诺） |
| 裸露/性内容/露骨性内容 | `None` / `无` |
| 卡通/幻想暴力、写实暴力、持续写实暴力 | `None` / `无`（以最终内容复核为准） |
| 枪械/武器 | `None` / `无` |
| 模拟赌博、赌博、战利品箱 | `None / No`；种子通关奖励和直接选花不是付费抽取 |
| 竞赛 / Contests | `None`（当前只有本地课题/个人成绩，无组织竞赛或兑奖；若上线内容不同则重新判断） |
| 年龄类别及提高评级 | `Not Applicable` / `不适用`；通常不主动提高评级 |
| 官方分级证书/区域覆盖 | `【仅在确实取得相关地区证书时填写编号并上传证明】` |

如果后台新增了本表未涵盖的问题，按真实内容回答，不能批量全选 No。评级最终结果与各地区特有显示一并核对。

### 出口合规 / Encryption

当前未见自研加密、VPN、加密通信或 CryptoKit 等业务；后续增加 HTTPS 支持链接也不能简单推导成“没有任何加密”。苹果对“无加密”和“仅使用系统加密/符合豁免”的问题有区别。[出口合规说明](https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance)

可复制给发布者的判断记录（不是后台全题统一填 No）：

```text
FoldPutt 为本地迷你高尔夫游戏，当前不实现自有加密算法或加密通信业务。请依据最终分发构建逐题确认出口合规；如仅使用 Apple 操作系统提供的加密，按系统加密/适用豁免路径填写。仅在确认不含非豁免加密后，将 ITSAppUsesNonExemptEncryption 设为 NO，并核对后台构建不再缺少合规信息。
```

需要非豁免文件时，必须提供真实文件和后台许可，不能使用本段替代。

### 定价、销售与兼容平台

| 项目 | 可复制选择 / 方案 | 说明 |
| --- | --- | --- |
| Price | `Free` / `免费（0）` | 当前无商业收费入口；不创建内购 |
| Distribution | `Public` / `公开分发` | 常规 App Store，不是企业/定制 App |
| Countries or Regions | `【合规资料齐全的海外首发地区列表，不含中国大陆】` | 方向已确认，具体国家/地区仍待核定，不能默认全球全选 |
| 中国大陆 | `不选择中国大陆` | 用户已确认本轮不含中国大陆；未来进入时再完成所需资料 |
| 越南 | `游戏许可核验前不启用越南分发`（候选方案） | 苹果当前 App 信息说明游戏在越南分发需许可证 |
| 欧盟 | `完成 DSA 身份声明与适用验证后启用` | 免费不自动等于非交易者 |
| 发布方式 | `Manually release this version` / `手动发布此版本` | 推荐先拿到审核通过，再执行已授权的公开发布；若追求最快自动上线，可明确改选审核后自动发布 |
| 首发预约 / Pre-order | `不启用` | 对争取明天直接下载无必要；不使用预约页面冒充已可下载 |
| Phased Release | `首发不使用` | 这是版本更新的分批自动更新机制，不是首次上架验收替代 |
| Apple Silicon Mac 可用性 | `首发暂不提供（待实际验收）` | App 触控玩法尚未完成 Mac 输入/窗口测试；后台选项与现有记录为准 |
| Apple Vision Pro 兼容分发 | `首发暂不提供（待实际验收）` | 没有沉浸空间或眼手输入验收，不默认扩大平台 |
| 最低版本 | `iOS 18.0` | 从最终构建读取，不能只在商店文案里调整 |
| iPad 支持 | `保留 iPad 支持并提供对应验收与截图` | 用户已明确首发支持 iPhone 与 iPad，并保留 Duo 适配 |
| 应用语言 | `简体中文（对照最终二进制的语言声明）` | 当前主要 UI 为中文；检查 CFBundleDevelopmentRegion/本地化资源，勿把英文商店文案当完整英文 UI |

### 按地区准备的真实资质

**中国大陆（未来市场参考，本轮不启用）：**苹果的现行说明明确要求游戏取得 NPPA 批准编号，并提供证明；某些 App 还需适用的 ICP 备案信息。免费、离线或无内购不是本次自行认定的豁免依据。游戏审批与 App/ICP 备案不是同一事项。还应核对主体与元数据一致性。[苹果大陆要求](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/)

| 资料 | 替换后可复制值 | 附件要求 |
| --- | --- | --- |
| 游戏批准编号/ISBN | `【主管机关真实核发且适用于本游戏的编号】` | ISBN 核发函或审批回复，以后台要求为准 |
| 审批游戏名 | `【审批文件中的游戏名称】` | 与提交资料对应；品牌改名不能破坏一致性 |
| 运营/出版主体 | `【审批文件中的主体法定名称】` | 不由代码包名推断 |
| 营业执照 | `【真实主体营业执照文件名】` | 上传真实有效文件 |
| 授权协议（适用时） | `【出版/运营方对本次分发的真实授权文件名】` | 后台要求时提供 |
| App/ICP 备案号（适用时） | `【已核验适用并真实取得的备案编号】` | 使用正确类型的编号，不以网站备案号随意代替 |
| 中国大陆组织身份 | `【组织中文法定名称】` / `【统一社会信用代码】` | 中国大陆组织账号按后台 D-U-N-S 关联信息核验 |

这些编号/证书无法用营销文案代替。本轮已明确不在中国大陆分发，因此不把上述大陆审批作为海外首发的阻塞；未来计划进入时重新核验。

**欧盟 DSA：**先判断是否作为交易者提供 App，再如实选择；即使不在欧盟分发，后台仍可能要求完成交易者状态声明。交易者需验证公开地址（个人可用符合要求的邮政信箱）、电话和邮箱等；组织资料与 D-U-N-S 信息关联，适用流程还可能要求支付账户资料。不能为了省资料选择“非交易者”。[DSA 官方流程](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/)

```text
交易者身份：【根据实际经营情况选择 Trader / Non-Trader】
公开名称：【真实主体名称】
公开地址：【真实且可核验的地址或合规邮政信箱】
公开电话：【含国际区号的可验证电话号码】
公开邮箱：【可验证的电子邮箱】
证明材料：【后台要求的真实主体及地址证明】
```

其他地区按其后台出现的分级、税务、主体或许可要求处理；本表不是全球法律意见。免费且无内购时，不把付费协议/收款银行资料误列成所有人的统一前置条件；账号协议、DSA 等具体流程若实际要求仍须完成。

## 7. App Review Information：可复制审核材料

### 审核联系人与账号

| 字段 | 替换后可复制值 |
| --- | --- |
| First Name | `【联系人名】` |
| Last Name | `【联系人姓】` |
| Email | `【审核联系邮箱】` |
| Phone | `+【国家或地区代码】【真实电话号码】` |
| Sign-in required | `No` / `不需要登录` |
| Username / Password | `留空（当前 App 无登录）` |
| Attachment | `【最终版本真实操作演示文件，若需要】` |

### Notes / 审核备注（英文，可复制；上限 4000 bytes）

以下仅在最终构建功能保持一致，且政策链接与隐私清单已补齐后使用。不要把内部未完成项写成已修复。

```text
FoldPutt is a single-player mini golf game. No account, sign-in, subscription, in-app purchase, or advertising is required. Core gameplay works offline. The current in-app interface is in Simplified Chinese.

How to play:
1. On launch, choose the classic mode or the character mode (Q version).
2. Drag the pull control to set both direction and power. Release to putt; there is no separate confirmation button.
3. Wait for the ball to stop before taking another shot. After the win result appears, tap to continue.
4. Use the course-selection control to choose any of the three practice courses.
5. Tap the leaf button labeled "玩法与收藏" to open six bank-shot puzzles, the nine-plot garden, and the quote collection. Completing a course earns a seed. These rewards have no monetary value and cannot be purchased or exchanged for money.

iPhone Duo:
The game adapts to the available window space. A manual "掌机模式" option is available from the options menu for separated course and control areas. All courses can also be played on a standard iPhone; folding is not required to unlock or complete content.

Progress, collections, and preferences are stored locally. No developer account or remote game server is needed. Sound and haptics can be switched off independently. Reduced Motion is respected.
```

补齐 App 内隐私入口后，另加下面一句，并替换为实际导航名称；**当前不能原样声称已存在**：

```text
The privacy policy is available in the app at 【exact menu path and label】 and at 【live HTTPS privacy policy URL】.
```

审核若需要 Duo 特殊场景说明，可复制下面的附件说明并替换地址：

```text
Optional demonstration of the submitted build: 【review-accessible video URL or attached filename】. The video shows real gameplay and window transitions. Standard iPhone gameplay does not require iPhone Duo hardware.
```

### 加急审核申请（可选，只有提交就绪后再申请）

不能保证加急，也不能谎称严重事故。若选择为真实硬件发布事件申请，可复制：

```text
We request an expedited review for the initial release of FoldPutt, a mini golf game adapted for iPhone Duo. We hope to make it available around the iPhone Duo launch on October 23, 2026. The submitted build and metadata are complete and ready for review. The app is also fully playable on standard iPhone devices. We understand that an expedited review and a specific release date cannot be guaranteed.
```

只有完成全套发布检查后才能保留 “complete and ready for review”。加急申请不替代正式提审，不保证审核通过。[申请入口及说明](https://developer.apple.com/app-store/review/)

## 8. 可发布到网页的隐私与支持正文

下面是供你发布的正文草稿。须替换真实主体、邮箱、日期，复核最终 App 及站点行为。**本次只写入此 .md，没有创建网站、政策入口或公开 URL。**

### 隐私政策正文（替换并核实后复制到网页）

```text
FoldPutt 隐私政策

生效日期：【实际生效日期】
提供者：【实际权利主体/运营者】
联系邮箱：【支持邮箱】

1. 游戏数据
FoldPutt 无需注册账号。核心游戏可离线进行。游戏进度、个人成绩、花园、语录收藏、声音与触感等偏好保存在设备本地。App 不主动将这些游戏数据传送至开发者服务器，不使用广告追踪或第三方广告服务。

2. 设备功能与权限
当前版本不请求访问你的通讯录、照片、麦克风、相机或位置。游戏依据系统提供的可用窗口空间与显示保留区域调整界面，不将这些信息用于识别或追踪你。

3. 保留、删除与系统备份
本地游戏数据随 App 使用保留。你可以通过删除 App（不是仅“卸载 App”保留文稿）移除其本地数据；操作前请确认你愿意丢失本地进度。系统备份、设备迁移及备份恢复可能按你的 Apple 设置处理 App 数据，相关功能由 Apple 提供。开发者不提供跨设备云同步，也无法从服务器找回本地进度。

4. 联系支持
如果你主动通过电子邮件联系支持，我们会收到你提供的邮箱、问题描述及附件，并仅用于回复和处理该请求。请勿发送密码、验证码或不必要的敏感信息。支持通信在处理请求所需期间保留；你可通过上述邮箱申请删除，我们会在适用法律要求允许的范围内处理。

5. 外部网页
打开 App 的支持或隐私网页时，浏览器、网页托管方或邮件服务可能按各自政策处理访问或通信数据。本政策不把这些外部服务的处理描述为游戏主动上传游戏进度。站点如额外使用统计或收集工具，应在此明确披露并更新适用告知。

6. 儿童与变更
FoldPutt 不要求用户提供年龄或注册资料，不以收集儿童个人信息为目的。若你认为向我们提供的信息涉及需要处理的儿童个人信息，请联系上述邮箱。功能或数据处理方式发生变化时，我们会更新本政策及生效日期。
```

发布前检查网页托管是否有统计/表单/广告 Cookie；有则补具体披露，不保留模糊条件句代替真实说明。联系支持的数据保留应遵循你实际执行的制度，如已确定具体期限可替换成真实期限；不要承诺无法执行的删除时效。

### 用户支持正文（替换后复制到网页）

```text
FoldPutt 用户支持

开发者：【实际权利主体】
支持邮箱：【支持邮箱】

怎么玩？
单指拖拽拉杆，同时确定方向和力度，松手击球。球滚动时等待停球，再进行下一杆。出现通关结果后，点击继续。

在哪里切换球场？
通过球场选择控件切换练习地图。点击叶子按钮“玩法与收藏”，可以进入六道反弹课题、我的花园和语录收藏。

种子和花园是什么？
完成球场会获得种子，可在九格花园中种花。种子没有货币价值，不能购买、兑付或转让。失手不会耗尽生命，也不需要付费复活。

必须使用 iPhone Duo 吗？
不需要。普通 iPhone 也能完成全部关卡。控显分离可以通过选项中的“掌机模式”手动切换。

声音和触感怎么关闭？
在游戏选项中分别关闭声音与触感。游戏会响应系统“减少动态效果”设置。

进度存在哪里？
进度与收藏保存在设备本地，无需注册。开发者没有云端进度恢复服务。删除 App 可能丢失本地数据；系统备份及迁移按 Apple 设置处理。

如何反馈问题？
请发送邮件至【支持邮箱】，并附上 App 版本、设备型号、系统版本、操作步骤和问题画面。遇到布局问题时，可说明当时窗口大小、内外屏状态及是否开启大字体。请不要发送密码、验证码或不必要的私人资料。

隐私政策：【实际隐私政策 URL】
```

## 9. 发布执行顺序与最终勾选表

以下是后续发布工作的清单，不表示本次授权执行提交或发布。每项附上可复制记录格式，便于交接。

| 顺序 | 必须完成的动作 | 完成后的可复制记录模板 |
| --- | --- | --- |
| 1 | 核对付费会员、最新协议、App 记录、Bundle ID 归属与操作角色 | `账号已核验：会员有效至【日期】；协议【状态】；Bundle ID【值】；App Apple ID【值】。` |
| 2 | 确定平台和首发地区 | `首发设备：【iPhone / iPhone+iPad】；首发地区：【列表】；暂不分发地区：【列表及原因】。` |
| 3 | 使用已接受的发布工具链 | `发布工具链：Xcode【版本】（【build】），SDK【版本】；已对照 Apple 接受条件。` |
| 4 | 完成隐私工程与网页 | `隐私清单已入包；政策 URL【地址】可访问；App 内入口【路径】；支持页【地址】可联系。` |
| 5 | 关闭已知失败与完成适用矩阵 | `验证版本【版本/build】；测试【结果】；失败场景【关闭证据】；Duo 连续变化【证据】；最低系统/iPad【结果或不适用原因】。` |
| 6 | 核对本地数据恢复与无障碍基本可达 | `实际击球、换关、回放、收藏、前后台/重启、声音/触感、最大字体与 Reduce Motion 已在【环境】验证。` |
| 7 | 核对素材及商店图 | `截图来自【版本/build/设备】，尺寸【列表】；无测试夹具与未发布功能；资源许可清单【位置】。` |
| 8 | Release Archive、验证和上传 | `Archive【文件位置】；验证【结果】；上传构建【版本/build】；后台处理【状态】；合规信息【状态】。` |
| 9 | 填元数据、隐私与年龄问卷、审核备注 | `全部必填信息完成；无占位符；分级【后台结果】；隐私【结果】；联系人【已验证】。` |
| 10 | 适当使用 TestFlight 验证安装分发包 | `TestFlight 构建【版本/build】；实际安装与关键流程【结果】。` |
| 11 | 正式提审；必要时申请加急 | `提交时间【时间/时区】；提交 ID【值】；状态【值】；加急申请【无/已申请及结果】。` |
| 12 | 审核通过后按约定发布，并核对商店 | `上线地区【列表】；发布时间【时间/时区】；App Store 链接【真实链接】；实际下载检查【结果】。` |

- [ ] 当前发布候选不再使用未获准 beta 工具链。
- [ ] 归档隐私清单、政策、App Privacy 三者一致。
- [ ] 原 6 条失败用例已有解释与覆盖证据；Duo 核心连续变化验收完成。
- [ ] 每个支持的平台都有对应真实验证与必需截图。
- [ ] 所有 `【…】` 占位符已替换；URL 公开可访问；联系方式有效。
- [ ] 不再出现“完整 VoiceOver 已支持”“全部真机验证”等无证据声明。
- [ ] 素材权利、各销售地区资质与账号协议已确认。
- [ ] 最终分发版本号、构建号、商店截图、描述与上传包一致。
- [ ] 已明确谁负责在后台提交、回应审核及执行最终公开发布。

无障碍 Nutrition Labels 是独立的商店声明；仅在按苹果相应标准验证后勾选支持。当前不能因为控件有 accessibility label 就声明完整 VoiceOver/Voice Control 支持。大字体、Reduce Motion 也应对最终版本按标准核对。[苹果提审准备与无障碍说明](https://developer.apple.com/app-store/submitting/)

| 无障碍资料 | 当前可复制选择 / 描述 |
| --- | --- |
| VoiceOver / Voice Control | `暂不声明支持，待完成完整玩法的等价操作验证` |
| Larger Text / Reduced Motion | `已有实现及部分历史验证，待按最终构建和苹果标准完成确认后勾选` |
| Differentiate Without Color / Sufficient Contrast | `待逐场景检查，不凭视觉印象勾选` |
| Dark Interface / Captions / Audio Descriptions | `按实际功能与适用标准评估，当前不默认声明` |
| Accessibility URL（可选） | `留空，待有真实无障碍支持说明页面后提供` |

TestFlight 适合验证，不等于 App Store 上线。内部测试者需要符合团队角色要求，外部测试可能另需 Beta App Review；它不是保证明天免审公开分发的替代通道。

## 10. 本次检查与未覆盖范围

本次实际执行：目录及 Git 工作区检查；读取工程、Info.plist、相关生产代码、素材记录和最新适配报告；查阅历史测试原始日志；读取现有 Release 模拟器产物 Info.plist 并检查无隐私清单；运行 `xcodebuild -version` / `-showsdks`；用 sips 核验现有图标尺寸/alpha；联网核验上述苹果公告、版本接受状态和后台要求。另核对 Markdown 本地链接、差异空白及文案长度：中文名称 8、副标题 10、宣传文本 66、描述 487 字符，关键词 65 bytes；英文副标题 30、宣传文本 170、描述 907 字符，关键词 59 bytes；英文审核主体备注 1313 UTF-8 bytes，均在所列限制内。现有工作区包含此前未提交源码修改，本次予以保留。

本次没有运行新的单元/UI 测试、重新编译、真机或 Device Hub 场景、Archive 签名/验证上传、网络行为实测、全球资质审查，未登录 App Store Connect，因此“后台没有 App”“会员已到期”“没有证书”均不能作为本次已知事实。历史通过结果只证明对应日期与测试条件，不能替代正式工具链生成的新候选包验证。

本文附带的是填写文案和素材要求，不是已完成的隐私网页、最终截图或可上传安装包。**当前发布结论为 No-Go；以上阻塞闭环后重新作 Go/No-Go 决策。**
