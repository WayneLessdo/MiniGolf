# FoldPutt App 内本地化 · 2026-10-22

本轮按用户授权实现土耳其语 tr、阿拉伯语 ar、葡萄牙语 pt、法语 fr、西班牙语 es，保留简体中文 zh-Hans。没有加入未实现的英文 App 界面。当前使用 App 内「语言」选择（详见 [语言切换说明](language-switch-20261022.md)），默认跟随系统；未匹配的语言按原有简体中文回退。pt 为通用语言资源，区域偏好由系统匹配到该资源，并非独立的 pt-BR / pt-PT 两套译文。

## 实现范围

- 原生 Resources/Localization/{语言}.lproj/Localizable.strings：195 项键（原有193项及新增2项语言选项），每项都有中文及五种完整译文；包含九张地图的显示名/提示、开局选择、普通/Q版、击球状态、回放、结算、设置、花园、语录、无障碍标签/提示、可见错误及完整离线政策。
- Features/Settings/Language/Model/FPLocalization.swift 统一资源查找、可调整语序的位置占位符和按 App 语言显示的数字。计数主要采用“类别：数字”的标签表达，避免机械套用中文量词或错误复数。
- JSON 中的原始关卡名称和ID、存档字段、花种/语气枚举及物理规则均不翻译；仅通过 localizedName 等显示属性输出译文，不改保存格式。
- 阿语使用原生 RTL 和自然文字对齐；手工 HUD 的工具/拉杆/记分卡与标题按界面方向排布。球场世界坐标、碰撞体、击球向量和回放路径不镜像。系统列表、卡片与导航继续采用 UIKit 的方向语义。
- 非中文手写文字使用系统字体，避免中文楷体回退影响阿语连写和行高。说明文案可换行，回放按钮高度按文字测量；四边 safe area 与实际 reserved regions 继续独立处理。
- 自动化操作使用稳定标识，不依赖界面译文；Debug 证据记录实际语言/方向、窗口尺寸、traits、安全区与区域。

## 维护

请在 Xcode 的 Localizable.strings 语言分组中编辑各语言整句，保留占位符类型/编号；完整政策键为 privacy_policy_body，中文原文以 Resources/PrivacyPolicy.txt 为准，对外联系邮箱保持 waynelessdo@gmail.com。新增文案需同步所有声明语言，不能只改 CFBundleLocalizations 冒充已翻译。App Store Connect 的商店字段与本目录是两套资源，不会自动互相翻译。

本轮译文由代理编写并做资源/上下文及实际界面核对；尚无母语人工审校记录，尤其语气型文案和地区用词仍可在发布前由母语人员润色。该限制不等同于资源缺项。

## 验证与收尾

| 验证 | 实际结果 | 证据（work/localization-20261022/下） |
| --- | --- | --- |
| 首次共享模拟器全量 | 91项中86通过、5失败；日志出现其他应用抢占前台，另有转屏快照过早 | PhoneAll.xcresult、phone-all-summary.json；保留原始失败 |
| 独立iPhone16Pro / iOS18.5全量 | 92项中91通过；剩1项为阿语Q版标题比较漏考虑Foundation自动加入的方向隔离符 | PhoneIsolated.xcresult、phone-isolated-summary.json |
| 阿语Q版断言修复复跑 | 1/1通过；仅比较时忽略不可见隔离控制符，完整可见文案仍精确校验；保留正式输出的方向控制符 | ArabicQFinal.xcresult、arabic-q-final-summary.json |
| iPhone验证合计 | **92条不同用例均已有通过证据**，包含58单测及34 UI；不宣称92项一次运行全过 | 上述独立全量+1项复跑 |
| 独立iPad13英寸 / iPadOS27.0 | 阿语、法语完整流程及两种最大字号/横屏共4/4通过 | iPad.xcresult、ipad-summary.json |
| 375pt小屏 / iOS18.5 / Dark | 阿语真实流程与阿语/法语最大字号共3/3通过 | SmallDark.xcresult、small-dark-summary.json |
| 深色导航栏修复后 | 阿语/法语最大字号横屏2/2通过；原生framebuffer核对标题已从白色改为可读深色 | DarkNavigationFinal.xcresult、dark-navigation-final-summary.json |
| 最终设备Release构建 | **BUILD SUCCEEDED**，六个lproj均实际包含193键，UIDeviceFamily=[1,2]，政策邮箱正确 | release-final.log、release-inspection.json |

已修正阿语HUD镜像后标题宽度仍按左侧工具栏计算的问题，并用LRI/PDI保持比例、百分比和+1奖励的顺序。Foundation本身也会在阿语格式参数周围加入FSI/PDI，测试不能把这些非可见字符当成漏译。深色系统下收藏页固定浅色纸张，导航栏现采用同一浅色外观，防止标题白字落在浅底上。

实际验证包含各语言开局/政策、真实拉杆入洞、回放、结算、花园种植、语录、地图切换，阿语Q版外观切换，以及土语到西语重启后同一杆恢复。没有通过注入奖励或删除断言制造通过。部分beta XCTest旋转窗口截图存在截取异常，因此用真正的显示屏framebuffer另存横屏补证；原图不裁切、不缩放、不改字。

截图与实际bounds、traits、安全区、regions记录位于 [多语证据目录](screenshots/localization-20261022/iphone/manifest.json)。[阿语界面](screenshots/localization-20261022/iphone/l10n-ar-course.png) · [土语界面](screenshots/localization-20261022/iphone/l10n-tr-mode.png) · [葡语界面](screenshots/localization-20261022/iphone/l10n-pt-mode.png) · [法语界面](screenshots/localization-20261022/iphone/l10n-fr-mode.png) · [西语界面](screenshots/localization-20261022/iphone/l10n-es-mode.png) · [深色横屏修复后原生图](screenshots/localization-20261022/dark-navigation-final/fr-largest-landscape.png)。这些是验收图，未自动整理成新增商店本地化的整套上传物料。

## 覆盖边界

- 按用户收尾要求，不再扩展Duo开合矩阵、网站部署或更多采图。Duo API/版本保护和区域逻辑保留，已参与当前SDK构建；**本轮新语言没有做Duo连续开合专项实测**，旧轮证据不冒充本轮结果。
- 当前为Xcode27.1 / 27A9269 beta；设备Release未签名，未上传或提审。最低部署18.0，本轮实际普通设备运行时18.5，未宣称跑过18.0。
- 译文尚无母语人工审校；未执行完整VoiceOver、Instruments或物理设备验证。无障碍文案已翻译，不等于完成全面无障碍认证。
- 线上政策/支持页沿用已部署版本；本轮没有额外部署。App Store元数据的本地文本已列出实际六种App语言，但没有自动生成五套商店译文，英文App界面仍未实现。

本轮没有提交/推送iOS工程或操作发布后台。既有修改、失败日志与截图均保留；备份在work/localization-20261022/before/。

依据：[Apple字符串目录与本地化](https://developer.apple.com/documentation/xcode/localization)、[Apple RTL指南](https://developer.apple.com/design/human-interface-guidelines/right-to-left)。
