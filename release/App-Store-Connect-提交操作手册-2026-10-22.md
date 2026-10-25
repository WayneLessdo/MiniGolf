# MiniGolf: Putt & Bloom：提交 App Store Connect 操作手册

初次核查：2026-10-22；最近执行更新：2026-10-23，北京时间。项目：`/Users/cws/Desktop/MiniGolf`。本手册按实际执行顺序排列。**正式构建0.2.0（1）已上传并关联，25张截图已上传；尚未提审或发布。**

> 续办状态覆盖表：步骤1–12已完成首发所需的后台准备；步骤11为四国非EU首发，DSA有效；步骤13已建内部验收群组并加入最终构建，邀请已发出，用户自行真机验收未完成；步骤14已关联构建；步骤15已添加到审核草稿，尚未最终提交；步骤16未执行。付费协议已接受、等待用户信息；税表姓名更正申请已提交，银行添加仍受认证加载阻塞，810号信息及2026-11-23的0.99美元调价尚未完成。当前状态以[最新进度](上架进度-2026-10-23.md)为准。

> 10月23日最新状态见[本次执行进度](上架进度-2026-10-23.md)。MiniGolf名称已被占用；已按用户选择保存为MiniGolf: Putt & Bloom，桌面名MiniGolf。工程/Scheme/Bundle ID仍沿用FoldPutt，存档键不变。

## 先看结论

正式Xcode27.1（27A9275）、分发签名、归档上传、25张截图和四国范围均已完成；DSA已处理。当前待 **最终包真机验收与送审检查**；收费准备先等法律姓名更正，再完成两份美国税表及银行处理，具备条件后预约调价。银行资料已提供，无需重复索取；810号属于独立税务报送要求，不仅限于收费。详见[收款、税务与地址隐私核查](收款税务与地址隐私核查-2026-10-23.md)。

本次通过已登录的 Chrome 读取了真实 Apple Developer / App Store Connect 页面，看到以下状态；并非仅从旧文档推测：

| 事项 | 实际结果 | 下一步 |
| --- | --- | --- |
| 开发者会员 | 已有个人会员；Team `62FH5J6694`，与工程一致；后台显示续订日期2027-09-10 | 不必重新购买会员 |
| 新版许可协议 | 2026-10-23已接受；2026-10-14签发；Connect告警消失 | 已完成步骤1 |
| App 记录 | 已创建；Apple ID `6826044808`，当前商店名MiniGolf: Putt & Bloom | 已完成步骤3 |
| Bundle ID | 已在Team `62FH5J6694`注册 `com.mavericklab.foldputt` | 已完成步骤2 |
| Xcode | 正式27.1，build `27A9275`已安装，原beta保留 | 已完成正式归档 |
| 签名 | Apple Distribution云端托管签名，导出成功 | 已上传并处理完成 |
| 版本 | 工程是 `0.2.0 (1)`，最低iOS18，iPhone+iPad | 后台保持一致；后续构建号按上传历史递增 |
| 商店截图 | 原19张加6张1320×2868大屏图，共25张已上传 | 数量与顺序已核对 |
| 网站 | 隐私、支持URL本轮独立HTTPS请求均200 | 步骤8和10直接填写 |
| App语言 | 简中、土语、阿语、葡语、法语、西语，195键/语言；有App内切换；没有英文UI | 商店英文描述已明确说明，勿勾称英文界面已支持 |
| 地区和DSA | 四国非EU首发已保存；DSA有效 | 首发免费；11月23日0.99美元调价尚未预约 |
| 审核联系人 | 经用户授权，已保存Wayne Chen、会员手机号和支持邮箱 | 已完成联系资料填写，不在文档公开完整手机号 |
| 最终分发验收 | 正式包上传及处理完成；TestFlight有构建，尚无实际安装验收 | 完成步骤13真机验收 |

**早期准备已完成：**后台只读核查、官方规则核对、大屏实图补拍与逐张目视检查、真实击球/通关/种花采集测试、公开URL检查、审核说明及过期语言描述修正、元数据长度重新计算、截图尺寸/哈希检查。续办阶段另已完成正式包上传、截图上传，并按用户逐项确认处理版权与付费协议，详见最新进度。

主文件就是本手册；可复制长文见[字段填写清单](App-Store-Connect-填写清单.md)，独立文本见[商店物料目录](app-store/README.md)。**旧 `FoldPutt-AppStore-20261022.zip` 保持原样，不含本轮新增截图与修正；这次使用当前目录文件，且物料ZIP不是可上传的App安装包。**

## 步骤1：接受更新协议，确认团队和操作权限

**状态：已完成。10月23日核实新版协议已接受，Team一致；以下操作保留供查阅。**

1. 打开 [Apple Developer 账户](https://developer.apple.com/account/)，使用现有会员账户。
2. 在“会员资格详细信息”确认团队ID为 `62FH5J6694`，注册身份为“个人”。若切换到其他团队，先停止后续创建，避免把App建错主体。
3. 页面顶部目前有“计划许可协议已更新”提示，点 **查看协议**，阅读后由账户持有人勾选所需确认并接受。
4. 返回 [App Store Connect](https://appstoreconnect.apple.com/)，刷新“App”页面，确认许可协议告警消失。
5. 若仍提示合同问题，进顶部 **商务（Business）→ 协议（Agreements）** 查看具体待处理项；不要重复购买会员。
6. 顶部 **用户和访问（Users and Access）** 可检查角色。创建和提交需要 Account Holder、Admin 或 App Manager；单纯Developer角色可以上传但不能替代送审权限。

**完成标志：**协议已生效、团队正确，创建/提交所需权限具备。免费且没有内购的本版本不为上架而新增付费业务；如后续EU交易商验证要求付款账户资料，按该独立要求处理。

接受法律协议会产生真实约束，工具规则要求在执行时确认；本轮已请你自行阅读并接受，没有代点。官方[新建App说明](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/)也列明最新协议是前置条件。

## 步骤2：注册 FoldPutt 的 Bundle ID

**状态：已完成。10月23日注册显式ID，并在Connect选择成功；以下操作保留供查阅。**

1. 在 [开发者账户](https://developer.apple.com/account/) 的“证书、标识符和描述文件”点 **标识符（Identifiers）**。
2. 搜索 `com.mavericklab.foldputt`。若存在，打开核对Team与完整拼写；若不存在，再点左上 **＋**。
3. 选择 **App IDs → Continue → App → Continue**。
4. Description 填 `FoldPutt`。
5. Bundle ID 选 **Explicit**，填 `com.mavericklab.foldputt`。
6. 本游戏没有登录、推送、iCloud、内购等对应业务，不额外勾选相关Capabilities。保留系统必需默认项。
7. 点 **Continue**，核对Team、完整ID，点 **Register**。
8. 回Connect刷新新建App页面，目标ID应出现。

**完成标志：**同一Team下有显式ID `com.mavericklab.foldputt`。若提示已占用，先查当前Team/已有标识符归属，不随意更改工程包名，也不使用下拉中其他项目的ID。

## 步骤3：创建 App Store Connect 的 App 记录

**状态：已完成。Apple ID为6826044808，SKU为foldputt-ios-202610，主要语言en-US，平台iOS。**

1. 进入 **App → 左上“＋ / 新建App”→ 新建App**。不要选“新建App套装”。
2. 按下表填写，然后点右下 **创建（Create）**。

| 字段 | 本项目填写 |
| --- | --- |
| 平台 | 只勾 `iOS`；同一记录承载iPhone、iPad、Duo |
| 名称 | `MiniGolf: Putt & Bloom`，10月23日已保存成功；单独的MiniGolf已被占用 |
| 主要语言 | 沿用已有海外物料建议 `English (U.S.)`；这是商店默认文案，不代表App有英文界面 |
| 套装ID | 选择 `com.mavericklab.foldputt` |
| SKU | `foldputt-ios-202610`；作为内部记录标识，创建后不随意更改 |
| 用户访问权限 | 当前实际弹窗为“完全访问权限”，有限访问不可选；无需额外邀请用户 |

3. 进入App后记下自动生成的数字 **Apple ID**，之后审核和支持查询会用到。
4. 打开侧栏iOS版本；本次版本应为 `0.2.0`。新记录若默认显示1.0，在可编辑版本字段改为0.2.0并保存，与包内版本保持一致；无需为了首发强行修改工程为1.0。
5. 先保存记录。图标最终随构建上传，不在此弹窗上传1024图标文件。

**完成标志：**Apps中有FoldPutt，状态“准备提交”，Bundle ID正确。个人会员的商店开发者/销售者名称按Apple账户规则展示，不能把资料里的公开称呼“Wayne”当作可任意修改的法定销售者名。

## 步骤4：准备 Apple 接受的 Xcode 版本

**状态：已完成。正式Xcode27.1（27A9275）已安装，与原beta并存；后文工具链风险说明保留供查阅。**

1. 使用 [Apple官方Xcode下载入口](https://developer.apple.com/download/all/?q=Xcode)，选择当前明确接受App Store上传、且包含本工程Duo API的27.1发行构建或适用后续版本。
2. 本次官方发布页列出的27.1发行构建为 **27A9275**。同为“27.1”也可能是不同build，必须在 **Xcode → About Xcode** 看完整编号。[官方发布记录](https://developer.apple.com/news/releases/?id=10052026a)
3. 保留现有开发环境，把所需发行版准备到独立路径后再使用；已有Xcode工程先保存，避免替换运行中的开发工具。
4. 用该Xcode打开 `/Users/cws/Desktop/MiniGolf/FoldPutt.xcodeproj`；共享Scheme选 `FoldPutt`。
5. 命令行如需指定版本，使用该工具链的 `DEVELOPER_DIR`；不要仅看到终端输出27.1就判为合规。
6. 先完成编译及受工具链变化影响的必要检查，再制作分发归档。不要用旧beta归档重签来冒充新工具链编译。

**完成标志：**发行build已核对，工程能在其上构建。Apple于2026-10-15公告接受Xcode27.1上传；这不证明本机9月beta build被接受。[Connect发布说明](https://developer.apple.com/help/app-store-connect/release-notes/)

本轮没有下载或替换整套Xcode；只完成现有安装及接受版本核验。正式工具链、账号签约与最终签名构建仍待完成。

## 步骤5：配置自动签名并核对版本

**状态：已完成。0.2.0（1）已通过Cloud Managed Apple Distribution导出。**

1. Xcode **Settings → Accounts** 选已有Apple账户，确认能看到Team `62FH5J6694`，不要选Personal Team或其他团队。
2. 左侧点蓝色工程 → **TARGETS → FoldPutt → Signing & Capabilities**。
3. 核对 **Automatically manage signing** 已勾选；Team为正确会员团队；Bundle Identifier为 `com.mavericklab.foldputt`。检查Release配置也相同。
4. **General → Identity** 核对Version `0.2.0`、Build `1`；设备支持保留iPhone+iPad；Deployment Target保持18.0。
5. 本项目版本数字直接写在 `App/Info.plist` 的 `CFBundleShortVersionString` / `CFBundleVersion`；若增加Build，要检查实际归档里的值，不能只新增一个未被引用的Build Setting。
6. 若1尚未上传，首包可用1；以后每个重新上传的候选包使用未占用的新Build号，例如2、3。修改后重新Archive。
7. 让Xcode按正常自动签名流程配置描述文件。遇到缺证书/权限，在Accounts的团队证书管理或Organizer错误详情中处理；不撤销其他项目证书。云端托管签名可能不显示成本地Apple Distribution identity，因此本次“本地未找到”不是断言账户没有证书。

**完成标志：**无签名红字；Archive及分发验证能正确使用该Team和App ID。开发证书安装运行成功并不等于App Store分发已成功。

## 步骤6：Archive、Validate、上传

**状态：已完成。正式归档、导出及上传成功，日志时间2026-10-23 13:02。**

1. Xcode顶部选Scheme `FoldPutt`，运行目标选 **Any iOS Device (arm64)** 或当前版本等价的通用iOS设备，不能选模拟器。
2. 菜单 **Product → Scheme → Edit Scheme → Archive** 确认Build Configuration为 **Release**。
3. **Product → Archive**。等待成功后打开 **Window → Organizer → Archives**，选择最新FoldPutt归档。
4. 核对版本、Build、Team、Bundle ID、图标；点 **Validate App**（如该版本提供独立入口），按App Store Connect分发验证完成检查。若新版直接整合进Distribute流程，以验证结果页为准。
5. 有报错时先看具体错误；修复后用新候选归档再验证，保留日志。
6. 点 **Distribute App → App Store Connect → Upload**（界面如改为直接Distribute，选择对应上传路径）。本次要可用于正式App Store提交，**不要选择“TestFlight Internal Only”**。
7. 选择正确团队、正常自动签名；保留必要符号文件上传，检查摘要和警告后上传。
8. 等到Organizer显示上传成功；记录日期、Version、Build和归档位置。不要上传本项目的素材ZIP、未签名`.app`或模拟器包。

**完成标志：**Organizer报告上传成功，下一步后台能看到处理中的构建。此时仍不等于提审。[Apple上传构建说明](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)

常见阻塞：`Invalid Binary`看邮件/上传日志；签名错看Team/描述文件；重复Build号递增重建；SDK不支持换被接受的发行版重新编译。不能靠删后台记录重复上传同一Build号解决。

## 步骤7：等待构建处理，处理出口合规

**状态：已完成。Apple处理完成且可选；包内非豁免加密为false，当前未显示出口合规阻塞。**

1. Connect **App → FoldPutt → TestFlight → iOS**，查看刚上传的 `0.2.0 (实际Build号)`。
2. Processing时等待；必要时刷新，查看Apple处理邮件。没有固定分钟数保证，不因短时没显示而盲目重复上传。
3. 若出现 **Missing Compliance / 缺少合规信息**，点 **Manage / 管理** 回答加密问题。
4. 当前包内 `ITSAppUsesNonExemptEncryption=false`，游戏无自研或非豁免加密业务；按题目的实际措辞申报。题目若问“是否使用任何加密”，不能把“无需非豁免申报”直接套为“一律没有加密”。
5. 本版本代码/依赖未变时沿用[隐私与出口建议](app-store/app-privacy.txt)；如最终包增加网络或加密SDK需重新判断。
6. 确认构建处理完成、没有Invalid Binary/缺失合规阻塞，才进入选Build步骤。

**完成标志：**构建可供测试，并能在版本页选择。上传成功、TestFlight审核通过和App Store审核通过是不同状态。

## 步骤8：填写 App 信息、分类、年龄分级与权利

**状态：已完成。名称、副标题、分类、4+评级、经用户权利确认的版权声明已保存。**

1. Connect **App → FoldPutt → 分发（Distribution，如显示）→ 通用 → App信息（App Information）**。
2. 在语言下拉选择English (U.S.)，名称填 `FoldPutt`，副标题复制[英文副标题](app-store/metadata/en-US/subtitle.txt)。保存。
3. 主类别选 **Games**；游戏子类别建议 **Sports、Puzzle**；次类别可留空。使用标准Apple许可协议，无需编造自定义EULA。
4. **内容版权（Content Rights）→ 设置/编辑**：先核对[来源清单](app-store/asset-provenance.md)和[资源清单](app-store/asset-inventory.json)，再按实际是否包含/访问第三方内容、是否持有所需权利回答。AI草地确有使用，不能声明全为手绘；本轮未代替持有人确认授权。
5. **年龄分级（Age Ratings）→ 设置年龄分级（Set Up Age Ratings）**。逐屏回答并点Next，最后保存。当前参考如下：

| 题目组 | 按当前游戏建议 |
| --- | --- |
| 家长控制、年龄验证 | 无自建能力，No |
| 无限制网页、用户生成内容、消息聊天、社交媒体、广告 | No；本地固定语录不是用户聊天 |
| 粗俗、恐怖、成人、酒精烟草毒品、医疗、性裸露、暴力、武器 | 无对应内容，None/No，按实际题型 |
| 赌博、模拟赌博、付费开箱 | No/None |
| 竞赛 | 当前无对人比赛、现金/实物奖项；本地成绩与不可交易种子按现状回答 |
| Kids / 提高分级 | 不选择儿童类别；无提高分级需求时Not Applicable |

6. 最终分级由Apple生成，不手写保证4+。实际后台可能新增问题，本次首页已提示社交媒体问题，应完整查看。
7. 如出现“受监管医疗器械”题，本游戏选No。无障碍标签只勾经过完整验证的能力；已有局部大字体/减少动态效果支持不等于所有辅助技术均达标。
8. 如出现 **Digital Goods and Services in Your Apps → Get Started**，按免费游戏、无IAP/订阅/外部付款/付费解锁的实际业务填写。不要因游戏包含数字内容就声称使用IAP，也不要因免费就不读题一律No。若问的是客户能否消费数字内容，需阅读该页面定义再区分；若选项与免费模式不符，先联系Apple澄清，不选择虚构付款方式。该问卷未出现则无需补填；EU选择可能锁定12个月。[官方问卷说明](https://developer.apple.com/help/app-store-connect/manage-app-information/complete-the-digital-goods-and-services-questionnaire)

**完成标志：**App信息无待填警告，年龄结果已生成，权利按实际确认。[年龄设置官方步骤](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/)

## 步骤9：填写版本文案，上传各设备截图

**状态：已完成。中英文版本文案已保存；25张截图全部上传至主要语言草稿。**

1. 左侧打开 **iOS App → 0.2.0**，右上语言选 **English (U.S.)**。
2. 在 **产品页信息（Product Page Information）** 填宣传文本、描述、关键词和支持URL；按下表复制文件内容，不把文件路径粘进文本字段。

| 字段 | 英文物料 | 中文物料 | 注意 |
| --- | --- | --- | --- |
| 名称 | [name.txt](app-store/metadata/en-US/name.txt) | [name.txt](app-store/metadata/zh-Hans/name.txt) | 通常在App信息中编辑，30字符内 |
| 副标题 | [subtitle.txt](app-store/metadata/en-US/subtitle.txt) | [subtitle.txt](app-store/metadata/zh-Hans/subtitle.txt) | 30字符内 |
| 宣传文本 | [promotional_text.txt](app-store/metadata/en-US/promotional_text.txt) | [promotional_text.txt](app-store/metadata/zh-Hans/promotional_text.txt) | 170字符内，可选 |
| 描述 | [description.txt](app-store/metadata/en-US/description.txt) | [description.txt](app-store/metadata/zh-Hans/description.txt) | 4000字符内，已有实际功能和语言说明 |
| 关键词 | [keywords.txt](app-store/metadata/en-US/keywords.txt) | [keywords.txt](app-store/metadata/zh-Hans/keywords.txt) | 已按UTF-8 100字节保守校验，后台计数最终把关 |
| 支持URL | [support_url.txt](app-store/support_url.txt) | 同一URL可用 | 必填HTTPS，不能填邮箱/本地文件 |
| 营销URL | 留空 | 留空 | 当前没有独立营销页，非必填 |
| 版权 | `2026 Wayne` | 同一值 | 版权主体须与实际权利相符 |
| 此版本新增内容 | 首次发布时按页面要求留空 | 同左 | 不粘贴“首发无需填写”这种说明文字 |

3. **产品页信息 → App预览和截屏（App Previews and Screenshots）→ 选择设备标签 → Upload/拖入图片**。需其他尺寸时点 **在媒体管理器中查看所有尺寸（View All Sizes in Media Manager）**。
4. 对照下表选槽位；文件名01至06就是排序。每个设备/语言通常提供1至10张，现有每组6张；Duo外屏为1张。

| 文件目录（相对本手册） | 数量/像素 | 上传位置和用途 |
| --- | --- | --- |
| [iphone-large](app-store/screenshots/iphone-large/) | **6张，1320×2868** | **优先上传普通iPhone大屏**；当前官方标签为iPhone with Dynamic Island (large display)，部分界面仍以尺寸命名 |
| [iphone](app-store/screenshots/iphone/) | 6张，1206×2622 | 普通iPhone中屏补充，不能当大屏必需图 |
| [ipad](app-store/screenshots/ipad/) | 6张，2064×2752 | 13英寸iPad槽位；本App支持iPad，不能只交iPhone图 |
| [duo-inner](app-store/screenshots/duo-inner/) | 6张，2007×2853 | iPhone Duo内屏对应槽位 |
| [duo-outer](app-store/screenshots/duo-outer/) | 1张，1398×2034 | iPhone Duo外屏对应槽位 |

5. 截图顺序：普通球场 → Q版 → 反弹课题 → 花园 → 语录 → 真实通关。等待上传/处理完成，确认预览没报尺寸、格式或透明度错误。
6. 版本页直接上传即可。若先经 **素材库（Asset Library）→ ＋ → Previews and Screenshots → Upload** 入库，仍须回版本页使用 **Browse Assets** 把图片关联到正确设备与语言；仅入库不等于版本已有截图。
7. 切换语言下拉的 **＋/添加语言 → 简体中文**，填中文文案，保存；截图可复用同一真实中文界面，在预览中确认语言回退和设备显示正确。必要时显式关联同一组图。
8. App内部六种语言和商店本地化是两件事。首发可以只使用现成en-US/zh-Hans商店页；不为每个销售国家机械创建一套商店语言，也不添加未准备完整的空语言。
9. 英文商店描述已明确没有英文UI；当前截图为真实中文界面。若以后添加tr/ar/pt/fr/es商店页，再使用实际翻译和相应界面截图，不能在中文图上伪造外语UI。
10. App预览视频、产品页Header/Search Results创意资产本次可不做；它们不能替代真实App截图。最后点 **Save**，检查每个保留语言都完整。

**完成标志：**版本页能预览普通iPhone大屏和iPad必需图，Duo图片落到正确位置，所有现用语言无缺项。参考[当前截图规格](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)与[素材管理步骤](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-your-app-store-assets/)。

本轮大屏图来自当前源码在iPhone16 Pro Max/iOS18.5模拟器的真实运行；仅PNG转不透明JPEG，没有缩放、裁切、叠字或伪造奖励。旧iPad/Duo图片是此前运行结果，最终分发包如有可见变化必须重拍受影响图片，不能仅凭尺寸合格就认为内容最新。

## 步骤10：填写并发布 App 隐私标签

**状态：已完成。经明确确认发布“未收集数据”；中英文政策URL及已发布状态已复查。**

1. 左侧点 **App隐私（App Privacy）**。
2. 在隐私政策URL旁 **编辑（Edit）**，填：

```text
https://foldputt-help-wayne.humble-mite-6617.chatgpt.site/privacy
```

3. Privacy Choices URL没有独立页面则留空。保存URL。
4. 数据收集区点 **Get Started / 开始**；当前离线游戏、无账号/广告/第三方统计/运行时上传的实现对应 **No, we do not collect data from this app**，保存。
5. 预览应显示 **Data Not Collected / 未收集数据**。不添加不存在的数据类型；若实际增加SDK、遥测或其他收集行为，应先改答案和政策。
6. 点右上 **Publish / 发布**；阅读准确性确认后确认发布。仅保存草稿不等于隐私标签已发布。这一步发布的是隐私声明，不是让App直接上架。
7. 最后用未登录浏览器打开政策与支持链接，确认正文与联系邮箱可见。支持URL为：

```text
https://foldputt-help-wayne.humble-mite-6617.chatgpt.site/support
```

**完成标志：**隐私URL已保存，声明已发布且预览正确。[官方隐私填写与发布步骤](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy)

包内 `PrivacyInfo.xcprivacy` 当前为不追踪、无收集类型，Required Reason API为UserDefaults `CA92.1`、SystemBootTime `35F9.1`。它与后台隐私标签不同，两者都要准确；用户主动发支持邮件及外部托管方处理也应与政策一致。

## 步骤11：设置免费、具体国家/地区、DSA与其他设备分发

**状态：已完成当前首发设置。免费，土耳其、阿联酋、巴西、墨西哥四国已保存，暂缓EU；DSA有效，按没有EU分发计划处理。Mac/Vision兼容分发关闭。未来EU扩区须补Trader公开资料，不能把收费计划伪称为无商业化意图。**

### 11.1 定价与地区

1. 左侧 **定价与销售范围（Pricing and Availability）**。
2. 定价区域点设置/添加价格；按当前表单选择价格 **Free / 0** 并保存。若先要求基础国家/地区，选用于价格基准的地区，再确认最终价格是0，不建立内购/订阅。
3. **App Availability → Set Up Availability**，选 **Specific Countries or Regions**，Next。
4. 逐项勾最终决定的海外地区；**不勾中国大陆**。游戏许可尚未准备好时不启用越南；其他地区若后台提示专门资质，也先解决对应材料。[Apple越南游戏许可说明](https://developer.apple.com/news/?id=06h4gf33)
5. 不勾“未来新增国家/地区自动开放”，避免无意扩大范围。Next → 核对列表 → Confirm。
6. 已设置过地区时，路径为 **App Availability → Manage → Manage Availability**，调整勾选后Next并确认。
7. 不启用Pre-order。语言支持不是地区资质，不应按六种语言自动全选对应国家，也不自动全球全选。

**完成标志：**明确的地区清单已保存、价格0。[Apple地区设置说明](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/manage-availability-for-your-app-on-the-app-store)

### 11.2 DSA身份与验证

1. 顶部 **商务（Business）→ 协议（Agreements）→ Compliance**。
2. **Digital Services Act → Complete Compliance Requirements**。
3. 根据实际经营情况选Trader或Non-Trader。个人账户、免费游戏均不能单独证明Non-Trader；不要为了过表单随机选择。
4. Trader：按页面提交真实姓名/地址或适用邮政信箱、电话、邮箱，完成邮箱与电话验证，上传要求的主体/地址证明，核对后Confirm。后台要求的付款账户等资料也要真实补齐。
5. Non-Trader：实际符合该身份才选择并Done。Apple官方说明即使不在EU分发，也需声明交易商状态。
6. 回App信息检查应用级DSA信息；如发行EU国家，确认适用验证已完成再启用该范围。

**完成标志：**声明与实际身份一致，适用验证无未解决项。Trader联系信息会在EU产品页展示，审核私有联系人是另一组字段；不要未经确认把会员资料里的私人住址复制为公开商店信息。[Apple DSA说明](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements)

### 11.3 Mac、Vision Pro与分发方式

1. 同页检查 **iPhone and iPad Apps on Apple Silicon Macs**，本轮尚未验证，首发建议取消在Mac提供。
2. 检查 **Apple Vision Pro Availability**，本轮尚未验证，首发建议取消兼容分发。页面有独立管理入口时进入对应页再取消并保存。
3. 分发方式选常规 **Public / App Store公开分发**，不用Custom/Unlisted企业分发。
4. 不去Xcode里删掉iPad设备家族；iPad是已确定支持的平台。

## 步骤12：填写审核联系人、操作说明和发布方式

**状态：新名称审核说明、已授权联系人、无需登录和手动发布已在后台保存。**

1. 回 **iOS App → 0.2.0 → App Review Information / App审核信息**。
2. **Sign-in Required / 需要登录**不勾。Username和Password留空；游戏无需注册，不造测试账号。
3. 填真实审核联系人First Name、Last Name、Email、Phone。邮箱可用 `waynelessdo@gmail.com`；电话使用带国际区号、能接通的号码。
4. 账户中已看到姓名及会员电话，可由你确认是否复用。页面显示名“Wayne Chen”不自动等于必须使用的审核姓/名，也不把未确认的私人电话复制到公开网页。本手册不重复写入私人住址/电话号码。
5. **Notes / 备注**复制[完整审核说明](app-store/review-notes.txt)。内容已覆盖：无登录/广告/IAP、离线、拉杆操作、三练习地图+六课题、种子无货币价值、收藏、手动控显分离、政策入口、六语切换与无英文UI。
6. **Attachment / 附件**当前可留空；如审核要求演示，再提供最终构建的真实录像。没有视频不要粘虚构链接，素材ZIP也不是演示录像。
7. **App Store Version Release** 选 **Manually release this version / 手动发布此版本**，点Save。这是建议的首发控制方式；审核通过后仍需步骤16发布。
8. 首次上架无需设置Phased Release渐进式更新。联系信息与Notes保存后再读一遍，确认无`【待填】`/`null`占位。

**完成标志：**可联系到真人、无登录要求、Notes与实际版本一致、发布方式已保存。[Apple发布方式说明](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/select-an-app-store-version-release-option/)

## 步骤13：用最终上传构建完成最小发布验收

**状态：内部群组“MiniGolf 0.2.0 首发验收”已创建并加入0.2.0（1），构建准备测试；邀请已发出；用户选择自行安装验收，尚未完成。正式27A9275下5条本地化单测和1条隐私/续球UI测试结果复用，不能替代真实安装验收。**

1. **App → FoldPutt → TestFlight → Internal Testing → ＋创建内部组**，填写组名，选择自己的有权限账户；在组内添加已处理完成的最终构建。
2. 不为测试而随意给外人Admin权限。普通外部测试者走External Testing及其适用Beta审核；内部测试不要求把App设为Internal Only上传。
3. 在真实iPhone和iPad安装TestFlight，接受自己的测试邀请并安装该Build；确认显示的Version/Build和待审包一致。
4. 按下面清单记录结果，至少完成核心烟雾验证；失败就修复、递增Build并回步骤6。

| 场景 | 验收动作 |
| --- | --- |
| 冷启动与离线 | 新安装启动，断网仍能选模式、击球、通关，无登录/网络等待 |
| 核心玩法 | 普通/Q版、三练习地图、至少一道真实反弹课题；松手出球，停球可再打，结算只出现一次 |
| 奖励与保存 | 真实通关得种子，种花，退出重开后收藏保留；后台切回不重置当前一局 |
| 多语言 | 切换六语，阿语RTL、长文本、语言持久化；换语言保持当前球局 |
| 隐私与设置 | 启动页/球场打开离线政策，返回续玩；声音/触感可独立关闭 |
| 布局和辅助设置 | iPhone/iPad横竖屏、最大字号、深色、运行中切换Reduce Motion；关键控件可见可点 |
| Duo适配 | 在可用Device Hub/Duo环境验证开合、旋转、横竖半折与同一杆连续性；记录traits、安全区、regions |
| 真机反馈 | 触感、音量、持握、耗电发热与较长时间游玩；模拟器结果不能代替 |

5. 原有通过结果在代码/资源/运行条件相同时复用，不为填表重跑全套；本次换发行工具链、重新签名和安装渠道变化必须验证最终候选。最低声明iOS18.0，历史最低实测18.5，18.0本身未被覆盖。
6. 无可用真Duo时如实记录Device Hub/模拟器验证，不声称完成光学/握持/温度验证。母语人工审校、整款VoiceOver可玩性目前也没有完整验收证据。

**完成标志：**实际安装的最终候选核心流程通过，已有证据可追溯；残余覆盖缺口由发布者明确评估。TestFlight不是Apple强制要求每个App都走的送审前置，但它能验证真正上传的那一包，不能用Debug截图流程代替。

## 步骤14：选择最终Build，做送审前检查

**状态：构建0.2.0（1）已选择并保存；最终包验收等剩余门禁尚未完成。**

1. Connect **App → FoldPutt → iOS App → 0.2.0**。
2. 向下找到 **Build / 构建版本 → ＋/Select a build**。
3. 选步骤13实际验收过的 `0.2.0 (Build号)`，点Done，再Save。不是默认选列表最上方而不核对。
4. 若没有可选项，依次核对：上传处理是否完成、Bundle ID是否同一App、版本号是否0.2.0、是否误传Internal Only、是否存在合规/二进制错误。
5. 逐项确认下面条件全部成立，再进入步骤15：

- [ ] 最新协议有效，Team及Bundle ID一致，App记录正确。
- [ ] 正式发行工具链Archive与上传成功，最终Build可选且已验收。
- [ ] iPhone大屏与iPad截图已上传，Duo图放在对应槽位；内容符合最终包。
- [ ] 所有已添加商店语言的必填字段完整；没有未完成的空本地化。
- [ ] 支持URL可访问，隐私URL与Data Not Collected声明已保存/发布且真实。
- [ ] 年龄问卷完整、权利声明准确、出口合规无阻塞。
- [ ] 免费、海外具体地区、适用DSA/地区要求已处理；中国大陆未选。
- [ ] 真正可接通的审核联系人、当前Notes、无登录要求均正确。
- [ ] 手动发布已保存，没有意外开启Mac/Vision兼容分发。

**完成标志：**版本页Build区域显示准确候选包，所需资料无红色缺项。检查表是执行清单；本手册中的空框不表示已经完成。

## 步骤15：添加到审核草稿，并真正提交审核

**状态：已成功添加到审核草稿，版本为“可供审核”，仅包含0.2.0（1）；尚未点击最终“提交以供审核”，等待最终包验收。**

1. 在版本页右上点击 **Add for Review / 添加以供审核**。
2. 按当前新版弹窗选择创建新submission，或加入你明确准备的已有草稿；首次通常建新草稿。
3. 如果页面提示缺字段，按提示回到对应页补齐并保存，再重复添加。
4. 添加成功只会进入 **Ready for Review / 可供审核**。此时还没有送到审核队列。
5. 点右下 **Draft Submissions / 草稿提交**，选择此次submission；也可从左侧 **App Review / App审核** 进入。
6. 查看提交项目，确认包含iOS App `0.2.0`，Build正确，相关素材关联正确，没有混入未完成的可选活动/资产项目。
7. 点 **Submit for Review / 提交以供审核**，完成页面要求的最终确认。
8. 返回审核详情，看到Waiting for Review等实际提交状态并记录提交时间；进入审核后显示In Review。若仍停留Draft/Ready for Review，检查是否漏了最后的Submit。

**完成标志：**后台审核记录确认已提交，而不只是元数据Saved或Ready for Review。Apple现行流程明确区分Add与Submit。[官方提交步骤](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app/)

## 步骤16：跟踪审核、处理问题，通过后手动发布

**状态：需先完成真实提审。**

1. 进入 **App → FoldPutt → App Review** 查看提交和消息，并留意审核联系邮箱。
2. 如被拒，打开具体问题，记录指南条款、复现步骤与附件。仅文案/截图问题修正元数据；二进制问题修代码并递增Build重新上传，替换旧候选。
3. 在该审核问题的消息区回复具体修改和复现路径；如页面要求，重新Add for Review并在submission详情Resubmit/Submit。不要只回复“已改”而未保存或未重新提交。
4. 审核通过且步骤12选择手动发布时，状态通常为 **Pending Developer Release / 等待开发者发布**。
5. 再确认上架地区、免费价格、政策链接和最终版本，在该版本右上点 **Release This Version / 发布此版本 → Confirm**。
6. 发布后查看 **Pricing and Availability → App Availability → Manage** 中各目标地区状态，打开真实商店产品页核查名称、截图、隐私和获取按钮。
7. 用目标地区Apple账户实际下载安装，测试启动、击球、保存和支持链接。后台发布成功不等于所有地区立刻可下载；Apple说明传播可能需最多24小时。[手动发布说明](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/select-an-app-store-version-release-option/)
8. 记录最终Version/Build、Apple ID、审核通过时间、发布时间和已上线地区，保存归档、符号文件及验收证据。没有收到审核结论前不承诺具体上线日期。

**完成标志：**目标地区真实App Store可下载且安装验证通过。加急审核是可选申请，不替代资料、验收或正常审核，也不保证指定日期。

## 早期准备交付与验证范围（历史记录）

以下保留首次核查和截图准备时的证据，后台状态已由文首概览及最新进度覆盖。

| 已执行事项 | 证据/结果 |
| --- | --- |
| 真实后台核查 | 当前账户无App；协议更新提示；新建弹窗目标Bundle ID缺失；Developer会员Team一致，个人会员续订日期2027-09-10 |
| 工具链与签名只读检查 | `xcode-select -p`、`xcodebuild -version`、安装目录、Keychain签名identity；仅确认本地状态，没有修改或撤销证书 |
| 大屏UI流程 | `work/release-20261022/LargePhoneSubmission.xcresult`，1条 `FPReleaseUITests/testStoreScreenshotsFromRealNavigation` 通过；真实击球、通关后种花 |
| 商店截图 | [大屏清单](app-store/screenshots/iphone-large/manifest.json)，6张1320×2868 JPEG无alpha；源PNG与布局文本在 `docs/screenshots/release-20261022/iphone-large/`；逐张目视检查完成 |
| 采集环境 | Xcode27.1 beta/27A9269、Simulator SDK27.1、iPhone16 Pro Max运行iOS18.5；440×956pt、横compact/竖regular；球场safe-area按top/left/bottom/right为62/0/34/0，division/occlusion为空；其他页以各布局记录为准 |
| 采集异常与恢复 | 原生framebuffer辅助脚本在一次4秒截图命令超时；底层XCTest继续完成并通过。最终6张统一采用该成功测试的原始XCTest附件，尺寸合规，没有靠缩放或重跑伪造成功 |
| 文案 | 审核说明加入六语/回退/语言切换；修复旧清单“只有中文”陈述；10项中英文商店字段长度重新检查通过 |
| 网站 | 本轮无鉴权、正常TLS的独立HTTP请求：privacy与support均200；不是把历史部署记录当本次访问结果 |
| 静态检查 | [package-validation.json](package-validation.json)更新截图与本轮后台观察；文件存在性、尺寸、hash、plist与语言资源检查记录在本轮报告 |
| 既有结果复用 | [语言切换报告](../docs/language-switch-20261022.md)、[多语言报告](../docs/localization-20261022.md)、[发布准备报告](../docs/release-prep-20261022.md)；旧结果保留其原始范围，不冒称最终分发包已全测 |

**当前尚未完成：**最终TestFlight/真实设备验收、正式提审与发布；收费所需税务银行与调价预约，以及独立的810号税务合规信息。正式工具链、签名归档上传、25张截图、中英文资料、年龄/版权/隐私声明、四国范围和DSA均已完成。付费协议已接受，等待用户信息。未提交或推送Git；没有向审核团队发送消息。

本次没有修改用户原有ZIP。原始失败日志、历史归档和测试证据均保留。任何本文建议值都不等于已在后台保存；只有表格明确标注“已核实/已执行”的事项具有本次执行证据。

## 你需要补充或确认的最少信息

1. 银行资料已齐，不必再发账号；请向95555或开户支行核实当前卡可接收Apple软件销售收入的CNY付款及适用要求，询问模板见[核查说明](收款税务与地址隐私核查-2026-10-23.md)。
2. 姓名更正等待Apple回复；证明直接交Apple，获批后核实税表适用字段并确认最终声明。两个美国身份/商业活动回答已保存，不重复询问。
3. 810号证件信息直接在保留的Apple页面填写，无需在聊天发送身份证号。
4. 在手机接受已发送的TestFlight邀请，完成最终包验收并回传设备、系统、版本及结果。

0.99美元收费计划、素材商业权利、付费协议同意、审核姓名和电话授权均已确认，不重复索取；首发四国已按用户选择保存。

## 每一步一句话速览

1接受协议；2注册ID；3创建App；4准备Xcode。
5配置签名；6归档上传；7处理合规；8填写信息。
9上传文图；10发布隐私；11设置地区；12填审核资料。
13验证最终包；14选Build；15正式送审；16通过后发布。
