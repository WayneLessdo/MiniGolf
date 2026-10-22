> 当前语言与实操补充：[国际上架语言与操作步骤](国际上架语言与操作步骤.md)。对外邮箱统一waynelessdo@gmail.com；苹果登录账号与公开联系邮箱分开。

# FoldPutt · App Store Connect 逐项填写清单

更新：2026-10-22。首发支持 iPhone、iPad，保留 Duo；仅在合规资料齐全的海外地区销售，暂不含中国大陆。开发者会员已开通；公开名称 Wayne，支持邮箱 waynelessdo@gmail.com。

**项目内阻塞已修复；尚不能直接提审或承诺 10 月 23 日公开下载。** 本机为 Xcode 27.1 beta build 27A9269，已完成未签名 Release 归档；网站已公开部署；正式工具链、分发签名/上传验证和后台真实资料仍待完成。语言规则与实操见 [国际上架语言与操作步骤](国际上架语言与操作步骤.md)。

填写方法：代码框为纯文本可复制值；表格的“可复制值”可粘贴到文本框，选择项按对应文字点选。“留空/不上传”是操作说明，不能把这几个字粘入 URL。`【…】` 必须替换成真实值后使用；附件必须上传对应真实文件，文字说明不能代替附件。优先使用本清单及同目录独立 `.txt`，旧评估文档为历史快照。

## 1. 新建或核对 App 记录

| 后台项目 | 可复制值 / 可复制记录模板 | 状态与用法 |
| --- | --- | --- |
| Platform | `iOS` | iPhone/iPad 由最终构建设备家族决定 |
| Name | `FoldPutt` | 后台检查名称可用性与权利，已有记录则核对 |
| Primary Language | `English (U.S.)`（新建记录建议） | 海外商店默认建议；已有记录先核对变更条件。App内已支持中文及tr/ar/pt/fr/es，英文界面尚未提供 |
| Bundle ID | `com.mavericklab.foldputt` | 选择该 Team 下同名显式 App ID；需核验账号归属 |
| SKU | `foldputt-ios-202610` | 新记录建议；已有 SKU 沿用原值 |
| Team / 发布权限 | `Team 名称：【真实值】；Team ID：【真实值】；发布角色：【真实值】` | 记录模板，不虚构账号状态 |
| 会员状态 | `会员已开通；实际有效期：【后台日期】` | 用户已确认开通，实际 Team 与协议仍在后台核对 |
| User Access | `【按实际团队协作选择完全访问或限制访问】` | 不通过文案自动扩大团队权限 |
| App Apple ID | `【后台自动生成的数字 ID】` | 只记录，不自编 |
| Version | `0.2.0` | 与当前工程一致；不要求首发一定叫 1.0 |
| Build Number | `1` | 本地现值；若后台已占用，工程递增后重建 |
| 选择 Build | `0.2.0（【正式上传且处理完成的构建号】）` | 从后台实际构建列表选，未签名归档不能代替 |
| 支持设备 | `iPhone、iPad；包含 iPhone Duo 适配` | 归档 UIDeviceFamily=[1,2] |
| 最低系统 | `iOS / iPadOS 18.0` | 构建配置；最低实际回归是18.5，见验收限制 |
| App 语言 | `简体中文、土耳其语、阿拉伯语、葡萄牙语、法语、西班牙语` | 来自当前资源与构建声明；英文商店文案不代表英文UI |

## 2. 分类、版权和版本资料

| 后台项目 | 可复制值 / 可复制记录模板 | 说明 |
| --- | --- | --- |
| Primary Category | `Games` | 游戏 |
| Games Subcategory 1 | `Sports` | 迷你高尔夫 |
| Games Subcategory 2 | `Puzzle` | 反弹课题；按后台可选项填写 |
| Secondary Category | `留空` | 可选 |
| Copyright | `2026 Wayne` | 后台自动加 ©；公开名由用户提供 |
| Content Rights | `资源来源清单已整理；权利持有与适用许可确认：【真实结论】` | 先看 app-store/asset-provenance.md；再按真实情况选择对应声明，不能复制模板代替权利确认 |
| License Agreement | `Apple Standard EULA` | 采用标准许可；接受协议属于实际后台操作 |
| Made for Kids | `不选择儿童类别` | 低年龄评级不等于 Kids 类别 |
| Regulated Medical Device | `No` | 当前是游戏 |
| Support URL（必填） | `https://foldputt-help-wayne.humble-mite-6617.chatgpt.site/support` | 已公开部署，无需登录 |
| Privacy Policy URL（必填） | `https://foldputt-help-wayne.humble-mite-6617.chatgpt.site/privacy` | 已公开部署；App内另可离线读 |
| Marketing URL | `留空` | 可选，暂未制作营销首页 |
| Privacy Choices URL | `留空` | 可选，无独立在线数据选择中心 |
| What's New | `首发版本，无需填写更新说明。` | 首版后台不要求时留空，不把本句贴成更新文案 |
| Accessibility Nutrition Labels（如出现） | `暂不声明尚未完整验收的无障碍支持项目。` | 政策大字体等已测不等于整款 App 全面达标 |

## 3. 中文商店字段（zh-Hans）

描述上限4000字符，名称/副标题30字符，宣传文本170字符，关键词100 UTF-8 bytes。独立文本均不带 Markdown，长度报告在 app-store/metadata-lengths.json。

### 名称 / Name

```text
FoldPutt
```

独立文件：[复制文本](app-store/metadata/zh-Hans/name.txt)。

### 副标题 / Subtitle

```text
拉一杆，种一点好心情
```

独立文件：[复制文本](app-store/metadata/zh-Hans/subtitle.txt)。

### 宣传文本 / Promotional Text

```text
拉动、松手，让小球出发。九张地图、六道反弹课题，还有能慢慢种满的小花园。普通与 Q 版随心切换，无广告、无内购，离线也能轻松打一杆。
```

独立文件：[复制文本](app-store/metadata/zh-Hans/promotional_text.txt)。

### 描述 / Description

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
在 iPhone、iPad 上轻松拉杆，在 iPhone Duo 的更大可用空间里欣赏球道。也可手动切换控显分离，不需要特定折叠姿态才能玩。

无需注册，核心玩法可离线进行。游戏进度与收藏保存在设备本地。
无广告、无内购、无付费复活。

需要帮助？请通过 App Store 的“App 支持”联系开发者。

界面支持简体中文、土耳其语、阿拉伯语、葡萄牙语、法语和西班牙语，跟随系统 App 语言设置。
```

独立文件：[复制文本](app-store/metadata/zh-Hans/description.txt)。

### 关键词 / Keywords

```text
高尔夫,推杆,迷你,休闲,益智,反弹,种花,离线,解压
```

独立文件：[复制文本](app-store/metadata/zh-Hans/keywords.txt)。

## 4. 英文商店字段（en-US）

英文描述已列出六种实际支持语言，明确没有英文App界面。海外分发不自动代表已完成英文界面翻译。

### 名称 / Name

```text
FoldPutt
```

独立文件：[复制文本](app-store/metadata/en-US/name.txt)。

### 副标题 / Subtitle

```text
Pull, putt, plant a little joy
```

独立文件：[复制文本](app-store/metadata/en-US/subtitle.txt)。

### 宣传文本 / Promotional Text

```text
Pull back and release. Explore nine courses, tackle six bank-shot puzzles and grow a garden. Offline with no ads or in-app purchases. Six languages; English not included.
```

独立文件：[复制文本](app-store/metadata/en-US/promotional_text.txt)。

### 描述 / Description

```text
A small green. A little moment of joy.

FoldPutt is a relaxed mini golf game. Drag the pull control to set direction and power, then release to take your shot.

Explore three practice courses and six bank-shot puzzles. All puzzles are available from the start. Switch between classic and expressive character visuals while keeping the same round.

Finish courses to earn seeds, then arrange daisies, tulips, and bluebells in your nine-plot garden. Discover short reactions from your golf buddy, or choose a quieter mood.

Play on iPhone and iPad, and enjoy a roomier course on iPhone Duo. A manual separated-control option is also available; no special folding pose is required.

No account is required. Core gameplay works offline. Progress and collections are stored on your device. No ads or in-app purchases.

In-app languages: Simplified Chinese, Turkish, Arabic, Portuguese, French and Spanish. English UI is not included.
For help, use the App Support link on this page.
```

独立文件：[复制文本](app-store/metadata/en-US/description.txt)。

### 关键词 / Keywords

```text
golf,putting,casual,puzzle,offline,garden,relaxing,bankshot
```

独立文件：[复制文本](app-store/metadata/en-US/keywords.txt)。

## 5. 图标、截图及其他附件

| 物料 | 当前文件 / 规格 | 可复制的内容说明 |
| --- | --- | --- |
| App Icon | app-store/AppIcon-1024.png；1024×1024，无 alpha | `FoldPutt 高尔夫主题应用图标母图，由 Xcode 资产编译随分发构建提交。` |
| iPhone 截图 | app-store/screenshots/iphone/；6张1206×2622 JPEG | `普通 iPhone 实际游戏画面：普通球场、Q版、反弹课题、花园、语录和真实通关。` |
| iPad 截图 | app-store/screenshots/ipad/；6张2064×2752 JPEG | `13英寸 iPad 实际游戏画面，使用同一套拖杆操作与本地收藏。` |
| Duo 内屏截图 | app-store/screenshots/duo-inner/；6张2007×2853 JPEG | `Duo 展开内屏原生运行画面，球场和操作控件按实际可用空间显示。` |
| Duo 外屏截图 | app-store/screenshots/duo-outer/；1张1398×2034 JPEG | `合拢外屏实际运行画面，真实击球后保持同一杆，完整玩法无需展开设备。` |
| 截图标题/排序参考 | app-store/screenshot-copy.md | `拉一杆就出发；换一种球场心情；借一面墙的力；这一杆会开花；收集嘴硬的小鼓励；收获真实通关。` |
| App Preview | 可选，当前无视频 | `首发不上传 App Preview。` |
| 审核演示附件 | 当前无成品录像，不虚构视频链接 | `如审核提出要求，补交最终构建的真实击球、开合续玩、手动控显分离与收藏操作录像。` |
| 分发构建 | work 中仅有未签名验证归档 | `使用正式受支持工具链重建，完成分发签名与验证后，上传0.2.0的实际构建。` |
| 资源来源 | app-store/asset-provenance.md、asset-inventory.json | `逐项核对实际打包资源、程序化/AI来源及适用使用权；保留证明，不虚构全部手工原创。` |

截图是模拟器真实 UIKit 画面；原生 framebuffer 仅编码成不透明 JPEG，无缩放、裁切、叠字或伪造球局/奖励。每个目录的 manifest.json 有来源、尺寸和哈希。当前截图取自 Debug，同一发布功能；最终分发包如发生可见变化须更新受影响的图。

## 6. App Privacy 与出口合规

| 项目 | 可复制值 / 选择 | 依据 |
| --- | --- | --- |
| 数据收集 | `No, we do not collect data from this app` | 最终包保持当前离线、本地数据、无广告/第三方统计/运行时上传时适用 |
| Tracking | `No` | 无跨App/网站广告追踪 |
| 数据类型列表 | `不添加数据类型` | 按上述“不收集”路径填写 |
| 政策 URL | `https://foldputt-help-wayne.humble-mite-6617.chatgpt.site/privacy` | 必填，不能填本地路径或邮箱 |
| Advertising Identifier（如询问） | `No` | 当前不使用 IDFA |
| 包内 Required Reason API | `UserDefaults: CA92.1；SystemBootTime: 35F9.1；NSPrivacyTracking=false。` | 已入归档；后台隐私标签和清单是不同事项 |
| 是否含非豁免加密 | `No` | 当前无自研/非豁免加密业务，包内 ITSAppUsesNonExemptEncryption=false；按后台具体问法填写 |
| Encryption 文件 | `当前非豁免文件不适用；最终构建若出现不同的加密实现，重新评估。` | 不把“任何加密”题统一回答No，系统加密与非豁免加密需区分 |

主动发送支持邮件、网页托管服务或 Apple 的独立处理见政策，不把本地进度描述为上传到开发者服务器。隐私标签建议也可直接查阅 [app-privacy.txt](app-store/app-privacy.txt)。

## 7. 年龄评级问卷

以下对应当前发布内容。结果由苹果计算，不手工保证4+；后台出现新题时按真实内容回答。

| 问卷项目 | 可复制选择 / 内容说明 |
| --- | --- |
| Parental Controls | `No`（App 无自建家长控制） |
| Age Assurance | `No`（无自建年龄验证） |
| Unrestricted Web Access | `No` |
| User-Generated Content | `No` |
| Messaging / Chat | `No` |
| Advertising | `No` |
| Profanity / Crude Humor | `None`（固定短句无脏话） |
| Horror / Fear / Mature Themes | `None` |
| Alcohol / Tobacco / Drugs | `None` |
| Medical / Treatment Information | `None` |
| Health / Wellness Topics | `No`（游戏不提供健康/治疗建议） |
| Sexual Content / Nudity / Graphic Sexual Content | `None` |
| Cartoon / Fantasy / Realistic / Prolonged Graphic Violence | `None` |
| Guns / Weapons | `None` |
| Simulated Gambling | `None` |
| Gambling / Loot Boxes | `No` |
| Contests | `None`（仅本地个人成绩；通关种子不售卖、兑奖或随机付费抽取） |
| Age Categories / Override | `Not Applicable`（不主动提高评级，不选Kids） |
| 评级证明（仅适用地区） | `【真实证书编号及证明文件】`（未取得时不得填写） |

## 8. 定价、地区与发布方式

| 项目 | 可复制选择 / 记录模板 | 条件 |
| --- | --- | --- |
| Price | `Free` / `0` | 无广告、无内购、无收费 |
| Distribution | `Public` | 常规App Store分发 |
| Countries / Regions | `【最终合规资料齐全的海外地区列表】` | 具体名单待实际核定，不默认全选 |
| Mainland China | `不选择中国大陆` | 用户已确认暂不纳入首发 |
| Vietnam | `游戏许可核验前暂不启用越南分发。` | 避免未提供许可却勾选 |
| EU | `完成DSA身份声明与适用验证后启用相应地区。` | 免费不等于自动非交易者 |
| Version Release | `Manually release this version` | 建议手动发布；后台操作尚未执行 |
| Pre-order | `不启用` | 不使用预约页面代替已可下载 |
| Phased Release | `首发不适用` | 首次上架不靠分批更新替代验收 |
| Apple Silicon Mac | `首发暂不提供` | 未完成Mac输入/窗口验收 |
| Apple Vision Pro compatibility | `首发暂不提供` | 未完成眼手输入等验收 |
| DSA身份 | `【根据实际经营情况选择 Trader / Non-Trader】` | 使用真实业务事实 |
| DSA公开名称/地址/电话/邮箱（适用） | `名称：【真实可验证主体】；地址：【真实地址或合规邮政信箱】；电话：【国际格式可验证号码】；邮箱：waynelessdo@gmail.com` | Wayne为已提供公开名，法定主体按账号规则核验 |
| 适用地区许可证/证明 | `地区：【值】；真实许可编号：【值】；证明附件：【真实文件】` | 未具备时先不启用该地区；证书不能靠说明替代 |

大陆游戏审批仅作为未来市场事项；本次不选择中国大陆，不把大陆审批作为本轮海外首发前置。

## 9. App Review Information

| 字段 | 可复制值 / 模板 | 状态 |
| --- | --- | --- |
| First Name | `【审核联系人真实名】` | 未提供，不把Wayne擅拆成法定姓/名 |
| Last Name | `【审核联系人真实姓】` | 未提供 |
| Email | `waynelessdo@gmail.com` | 用户提供的支持邮箱，可用于审核联系 |
| Phone | `+【国际区号】【真实可接通电话号码】` | 未提供 |
| Sign-in Required | `No` | 无账号/登录 |
| Username / Password | `留空` | 不需要演示账号 |
| Attachment | `不上传；审核要求时补充最终构建真实操作录像。` | 当前无成品视频 |

### Review Notes（复制下框，独立文件在 app-store/review-notes.txt）

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

The bundled privacy policy can be read offline from the mode-selection screen ("隐私政策") or from the course options menu ("隐私政策"). Reading it pauses the current round; returning resumes the same round.
```

### 加急申请（可选；只有最终构建与元数据都就绪才可使用）

```text
We request an expedited review for the initial release of FoldPutt, a mini golf game adapted for iPhone Duo. We hope to make it available around the iPhone Duo launch on October 23, 2026. The submitted build and metadata are complete and ready for review. The app is also fully playable on standard iPhone and iPad devices. We understand that an expedited review and a specific release date cannot be guaranteed.
```

当前尚不能声称“complete and ready for review”。加急申请不保证受理、通过或发布日期，不代替正式提审。

## 10. 政策与支持网页

已将 [privacy.html](web/privacy.html) 与 [support.html](web/support.html) 公开部署，无需登录。源文件没有引入统计、表单、广告、第三方脚本或外部字体。Privacy Policy URL为 https://foldputt-help-wayne.humble-mite-6617.chatgpt.site/privacy；Support URL为 https://foldputt-help-wayne.humble-mite-6617.chatgpt.site/support。英文为默认网页，另有简体中文切换。独立HTTP验证五页HTTPS200，未使用登录信息。托管层会正常跳转至无.html路径并添加Cloudflare安全脚本，与源码自身的行为分开记录；政策已说明外部托管服务的独立数据处理。

### 隐私政策正文（可复制；与包内同源）

```text
FoldPutt 隐私政策
更新日期：2026 年 10 月 22 日
提供者：Wayne
支持与隐私联系：waynelessdo@gmail.com

一、无需注册，离线打球
FoldPutt 是单人迷你高尔夫游戏，无需注册或登录。核心玩法可离线进行。App 不提供广告、内购、第三方统计或广告追踪，不主动将游戏数据传送至开发者服务器。

二、保存在设备上的数据
为了继续对局，App 在本地保存球位、杆数与对局进度；为了保留你的收藏和选择，App 在本地保存个人成绩、种子与花园、语录收藏，以及画风、声音和触感等偏好。这些数据仅用于提供游戏功能，不用于识别你、建立广告画像或跨 App 追踪。

三、系统信息与权限
App 使用系统提供的窗口空间、安全区和显示保留区域调整界面，使用本地计时判断游戏内操作间隔。上述信息不用于识别用户，也不会由 App 主动发送给开发者。当前版本不请求访问通讯录、位置、照片、相机或麦克风。

四、保存、删除与系统备份
游戏数据随 App 使用保留在设备上。删除 App 可移除其本地数据；仅“卸载 App”并保留文稿与数据不会删除存档。删除之前请确认愿意失去本地进度。系统备份、设备迁移及恢复可能按你的 Apple 设置处理 App 数据，由 Apple 提供。开发者不提供跨设备云同步，也无法从服务器找回你的本地进度。

五、联系与主动反馈
如需支持或反馈隐私问题，请发送邮件至 waynelessdo@gmail.com。你主动发送的邮箱、问题描述和附件仅用于回复与处理请求。请勿发送密码、验证码或无关的敏感信息。支持通信在处理请求所需期间保留；你可通过相同邮箱申请删除，开发者将在适用法律允许的范围内处理。

六、外部服务
当你自行访问支持网页或发送邮件时，浏览器、网页托管方、邮件服务或 Apple 可能依其政策处理访问、通信、备份或诊断数据。这些外部服务不等于游戏主动上传你的游戏进度。

七、儿童与政策更新
App 不要求提供年龄或注册资料，也不以收集儿童个人信息为目的。如认为向开发者提供的信息涉及需要处理的儿童个人信息，可通过上述支持渠道联系。功能或数据处理方式变化时，开发者会更新本政策及日期。

本政策随 App 提供，可在开局画面或球场选项中随时离线阅读。
```

### 支持页正文（可复制）

```text
FoldPutt 用户支持
开发者：Wayne
支持邮箱：waynelessdo@gmail.com

怎么玩？
单指拖拽拉杆，同时确定方向和力度，松手击球。等待停球，再进行下一杆。出现通关结果后点击继续。

支持哪些设备？
支持 iOS/iPadOS 18 或更新版本的 iPhone 和 iPad，保留 iPhone Duo 的窗口与保留区域适配。所有关卡可在普通设备完成，不要求特定折叠姿态。

在哪里选择球场和收藏？
通过球场的地图按钮选择练习地图。点击叶子按钮“玩法与收藏”，进入六道反弹课题、我的花园和语录收藏。

种子和花园是什么？
完成球场获得种子，可在九格花园种花。种子不能购买、兑付或转让；失手不扣生命，不需要付费复活。

声音、触感和动效如何关闭？
在球场选项中分别关闭声音与触感。游戏响应系统“减少动态效果”设置。

如何删除数据或恢复进度？
进度和收藏保存在设备本地。删除 App 可移除本地数据；仅“卸载 App”并保留文稿不会清除存档。系统备份和迁移依 Apple 设置处理，开发者没有云端进度恢复服务。

如何反馈问题？
请发送邮件至 waynelessdo@gmail.com，附上 App 版本、设备型号、系统版本、问题步骤和必要画面。布局问题可说明内外屏、窗口大小及字号设置。不要发送密码、验证码或无关的敏感信息。
```

## 11. 剩余发布动作与可复制验收记录

| 动作 | 当前状态 | 完成后可复制的记录模板 |
| --- | --- | --- |
| 项目隐私与发布配置 | 已完成，未签名归档内核对 | `PrivacyInfo.xcprivacy与离线政策均入包，iPhone/iPad设备家族、中文语言和加密声明已核对。` |
| 回归与Duo核心矩阵 | 已完成本轮范围；边界见发布报告 | `iPhone全量80/80；iPad9条均有通过证据；小屏/深色政策与Duo实际开合、旋转、两种半折和滚动合拢已验证。` |
| 正式工具链 | 未完成 | `Xcode【正式版本/build】，SDK【值】，已对照Apple接受条件。` |
| 分发签名/验证/上传 | 未执行 | `Team【值】，签名验证【结果】，上传构建【版本/build】，处理状态【值】。` |
| 托管政策/支持页 | 已发布，HTTPS公开验证通过 | `隐私URL https://foldputt-help-wayne.humble-mite-6617.chatgpt.site/privacy；支持URL https://foldputt-help-wayne.humble-mite-6617.chatgpt.site/support；无登录可访问，联系方式waynelessdo@gmail.com。` |
| 后台资料与地区 | 部分缺失 | `审核姓名/电话已填真实值；首发地区【列表】；适用资质/DSA【状态】。` |
| TestFlight | 未执行 | `构建【版本/build】，真实安装与关键功能【结果】。` |
| 元数据、评级与内容权利 | 文案已备好，后台未填写 | `必填字段无占位符；年龄评级【结果】；隐私标签【结果】；内容权利确认【证据】。` |
| 正式提审 | 未执行 | `提交时间【值/时区】；审核状态【值】；如补件则记录【要求及回复】。` |
| 审核通过后发布 | 未执行 | `授权发布时间【值/时区】；上线地区【列表】；实际商店链接【真实URL】；下载验证【结果】。` |

原始测试、归档和验收边界详见项目 `docs/release-prep-20261022.md`。本物料包不包含证书私钥、账号凭据或真实身份文件；这些通过苹果官方后台处理。

## 12. 官方依据

规则按2026-10-22核查，提交时以后台和最终构建为准：[App信息](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/)、[版本字段](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/)、[截图规格](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)、[隐私清单](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)、[年龄问卷](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating)、[出口合规](https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance)、[正式Xcode](https://developer.apple.com/news/releases/?id=10152026a)、[App Store接受状态](https://developer.apple.com/help/app-store-connect/release-notes/)。
