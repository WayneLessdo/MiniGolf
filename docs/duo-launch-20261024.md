> 后续：当前候选 **1.0.0（11）**，真实手机反馈后的轻触感、普通球杆和最终顶栏见[本轮记录](phone-feedback-20261024.md)。本报告构建7营销图和姿势覆盖为真实历史，不冒充11重跑。

# Duo 首发文案、玩法截图与候选 7

更新：2026-10-24。当前发布状态以[上架进度](../release/上架进度-2026-10-24.md)为准。本记录区分真实运行证据、营销排版与物理真机覆盖。

## 本轮交付

- 英文和中文副标题、推广文本、描述围绕 Duo 展开空间、合拢续局、手动 Handheld 控显分离来写；保留普通 iPhone/iPad 可玩、七语、离线、无广告/内购及 Keychain 本机保存边界。没有“首款”“独家”“Apple 推荐”或兑换承诺。
- 6 张英文 Duo 玩法说明图，原生真实画面加主题色标题，按展开、合拢续局、Handheld、拉杆、两种画风、种花排序。[成品与来源清单](../release/app-store/screenshots/duo-campaign/README.md) · [下载 ZIP](../release/MiniGolf-Duo商店图-20261024.zip)。普通 iPhone/iPad 的英文截图保留，中文商店本地化仍可独立使用中文图。
- 同一帮助站点部署版本 3，英文/中文支持与隐私共五页同步七语、Duo 与 Keychain。成功部署凭据见[hosting.json](../release/web/hosting.json)。站点状态 active、access_mode public；部署成功与本机链接可达性分开记录。本机 Chrome 最终打开 /support 显示 ERR_CONNECTION_CLOSED，命令行 HTTP403，网页读取工具不可达，Worker 日志无错误事件；原因尚未确定，不能声称 v3 的公开 HTTP200 验收通过。待独立网络核对后再最终送审。未另买域名、改套餐或迁移 URL。
- 实际 Device Hub 操作发现未激活中缝装饰覆盖 WIN/操控区域：装饰只绘制 active division，裁剪在真实球场范围内；不再使用虚构最小厚度。
- 窄屏 Handheld 杆数避免英文拆成多行：可见卡片使用本地化数字，辅助功能保留完整杆数、标准杆与星级。英文计数统一 label:value，避免“1 strokes / 1 seeds”。不更改普通模式、Q版及课题的既定玩法。
- 最终归档 **1.0.0（7）**，正式 Xcode 27.1（27A9275）/iOS 27.1 SDK；2026-10-24 13:57:22 上传成功。构建 5、6 是过程中修正后的历史上传，候选以 7 为准。

## 实际验证

| 类型 | 证据及范围 |
| --- | --- |
| 全量单元 | `work/duo-launch-20261024/Unit.xcresult`，67 项通过，覆盖已有物理、Keychain、迁移、重复结算、语言等；执行于中缝修复后 |
| 英文专项 | `EnglishFinal.xcresult`，6 项本地化测试与英文商店流程通过，执行于英文计数修复后 |
| 最终 HUD | `HUDFinal.xcresult`，新增窄区杆数可读性/完整辅助标签回归与英文真实导航通过，执行于最终构建 7。共 68 项不同单元用例有有效通过证据，不把重复执行累加为新用例 |
| 同局姿势矩阵 | 本轮修复前的 01—08 原图/JSON：实际一杆后外屏横竖、内屏横竖、两种 active 半折、重新展开，同局/球位/杆数/launch 不变，按钮与保留区相交列表为空；09 在同局实际第二杆进洞 |
| 最终 7 实际击球 | 30—33 原图/JSON：真实拉杆一杆进洞，inactive 与 active division 下 WIN 可见，窄卡片杆数可读，按钮相交列表为空 |
| 最终 7 同局续玩 | 37 外屏、38 内屏原图/JSON：同一 round `CBF2C287-B2ED-4B1C-AE53-E3E019C0F855`、launch `E065F93A-B129-4F3F-AA6F-7FC3AB8BF235`、1 杆、球位 `{0.5,0.73953987100442276}`、ready。用作图 2 和图 1 的事实依据 |
| Handheld/花园 | 40 为实际 Q 版手动 Handheld、部分展开、0 杆待击；35 为实际通关后种下雏菊，种子 0、已种 1/9、积分 3。花园画面独立人工核对，不把其后台暂停球局 JSON 当花园几何诊断 |

Duo 运行：iOS 27.1（24A94401），display scale 3。完整逐次 bounds、四边 safeArea、horizontal/vertical size classes、active/inactive division、occlusion、控件 frame 与按钮违规列表见[原图和 JSON](screenshots/duo-launch-20261024/)。使用真实容器、traits 与系统 reserved regions，营销图不改变布局或替换游戏内容。

保留前一轮 build4 的 XCTest 合成拖拽未登记击球失败；本轮手工真实输入补充可观察覆盖，不能把此前自动测试标绿。build7 复核的是关键姿势与同局续玩，不把早期八姿势矩阵假称全部重跑于 build7。物理 Duo/手机的触觉、握持、光学、发热和能耗尚未测试；Keychain 不承诺抹机、换机或服务器恢复。

## 图片来源及复现

[六图总览](screenshots/duo-launch-20261024/marketing/overview.jpg)。第 3 张使用实际 Device Hub 设备渲染截图的局部，裁剪坐标及原图哈希在 manifest，去掉桌面和检查器，未重新绘制应用或伪造 Apple 官方背书。其他图为 simctl 原始原生画面，只添加营销标题/底色/边框。实际通关、奖励、球位均未注入。

制作文件在 `work/duo-launch-20261024/marketing/`，`card.html?id=1…6`；原始输入在 raw，输出在 release/app-store/screenshots/duo-campaign/en。浏览器 clip 按成品精确尺寸导出以避免首帧全页截图绘制缺失。最终六图逐一目视核对，JPEG 无透明，规格与 SHA-256 已登记；截图排版 HTML 副本也留在本报告截图目录。

Apple 依据：[准确元数据与实际 App 画面](https://developer.apple.com/app-store/review/guidelines/) · [Duo 截图尺寸](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications) · [Duo 官方适配入口](https://developer.apple.com/iphone-duo/)。英文作为主商店回退能避免非中文用户首先看到中文；中文截图本身不必然导致拒审，关键是对应语言展示准确、与实际功能一致。

没有提交/推送 iOS 工程 Git，没有最终送审或公开发布。Sites 源码单独按部署流程保存并发布版本 3，不与 App 仓库提交混淆。
