# FoldPutt 语言资源与 App 内切换

已按本轮要求改为原生 `Localizable.strings`，不再使用 String Catalog。只参考 Lito 的分语言 Bundle、偏好保存和通知刷新方式；没有改动 Lito，也没有引入其第三方依赖、登录接口或手机号国家码判断。

## 使用入口

- 球场右侧设置按钮（滑杆图标）→「语言」。启动模式选择页底部也有同一入口。
- 可选：跟随系统、简体中文、Türkçe、العربية、Português、Français、Español。
- 点选立即生效，点「完成」返回。选择保存在 App 自身的 `FoldPutt.language`，重启继续使用；「跟随系统」清除该覆盖，不改系统的 AppleLanguages。
- 首次使用跟随系统。支持的地区变体匹配基础资源（如 pt-BR / pt-PT → pt），不匹配时沿用简体中文回退；没有新增英文 App 界面。
- 阿语采用 RTL；其他五种采用 LTR。数字和完整句子都使用当前选择的语言。语言名称使用各自本名，便于切错后找回。

## 文件与维护

| 语言 | 文件 |
| --- | --- |
| 简体中文 | `Resources/Localization/zh-Hans.lproj/Localizable.strings` |
| 土耳其语 | `Resources/Localization/tr.lproj/Localizable.strings` |
| 阿拉伯语 | `Resources/Localization/ar.lproj/Localizable.strings` |
| 葡萄牙语 | `Resources/Localization/pt.lproj/Localizable.strings` |
| 法语 | `Resources/Localization/fr.lproj/Localizable.strings` |
| 西班牙语 | `Resources/Localization/es.lproj/Localizable.strings` |

Xcode 中为一个 `Localizable.strings` 语言分组。每种语言 **195 个相同的稳定 key**：原有 193 项译文逐项无损迁移，新增「语言」「跟随系统」。调用示例：

```swift
// 六个语言文件使用同一个 key，分别填写各自译文。
// zh-Hans.lproj/Localizable.strings
"settings_language" = "语言";
"settings_language_system" = "跟随系统";

// tr.lproj/Localizable.strings
"settings_language" = "Dil";
"settings_language_system" = "Sistemi takip et";

// UIKit 调用
let title = FPL10n.text("settings_language")
```

修改译文时保留 `%@`、`%1$@`、`%%` 等占位符。保留阿语模板中的方向隔离字符，以免比例、百分比和奖励显示倒序。完整离线政策键是 `privacy_policy_body`；对外邮箱继续为 `waynelessdo@gmail.com`。新增文案同步六套资源，不把原始关卡 JSON 名称、存档字段或业务 ID 翻译掉。

`Features/Settings/Language/Model/FPLocalization.swift` 管理显式 Bundle、偏好及通知；`Features/Settings/Language/Controller/FPLanguageController.swift` 是原生可滚动语言列表。`Features/Gameplay/Controller/FPModeSelectionController.swift（FPGameRootController）` 收到通知后只重建界面，保留同一个 session、球局、击球身份和物理世界。选择期间暂停物理；切到后台再回来仍不在语言页面后方继续滚动。收藏/隐私等其他页面若因另一场景切换而过期，会关闭并回到保留中的球局。

原有课题名称/提示从静态缓存改为读取时本地化，避免换语言后仍显示旧文案。拉杆及球场物理坐标不镜像；仍以实际容器、安全区和系统保留区域布局。

## 验证证据

详见 `work/language-switch-20261022/` 日志、xcresult 和 `resource-validation.json`。真实运行截图与包含系统 traits、安全区、保留区域的布局记录在 `docs/screenshots/language-switch-20261022/`；这是测试截图，不是自动生成的新商店截图集。

- 六套源文件语法、195 个键、全部原有译文逐项一致及代码 key 引用检查通过。
- iPhone 16 Pro / iOS 18.5：5 条本地化单测及 1 条完整 App 内切换流程通过。覆盖土语→阿语→法语→重启保留→跟随系统，实际击球后保持同一 launch、杆数和关卡。
- iPad 13 英寸 / iPadOS 27.0：同样的 5 条单测及 1 条完整切换流程通过。
- iPhone 最大辅助字号及横屏语言列表：最终用例通过（`LargestDirectionFinal.xcresult`），选择可滚动、完成按钮可点、换语言后返回对应译文；修正完成按钮对比度、RTL 列表对齐及导航栏方向即时刷新。原生横屏截图为 `iphone/fr-largest-landscape-native.png`，没有裁切或缩放。
- 最终资源/偏好/暂停连续性等5条单测通过（`AccessibilityFinal.xcresult` 的单测部分）；同次新增的大字号 UI 夹具用了错误的滚动方向，修正后单独复跑通过，保留失败结果，不宣称该 xcresult 全过。
- 最终未签名设备 Release 构建通过（`release.log`），编译后六套语言文件各195键，device families 为 iPhone+iPad；并发检查没有新增 Swift Sendable 警告。`release-inspection.json` 记录当前源资源哈希。

快速查看：[最大字号阿语语言页](screenshots/language-switch-20261022/iphone/l10n-switch-ar-largest-language.png) · [最终法语横屏原生截图](screenshots/language-switch-20261022/iphone/fr-largest-landscape-native.png) · [iPad 切换语言页](screenshots/language-switch-20261022/ipad/l10n-switch-ar-language.png)。iPad/普通字号流程图采于对比度小修之前，最后的大字号图包含该修正。

首次测试有两处测试夹具错误：模拟击球漏了 aim，及误把系统继承的 AppleLanguages 当作应为空；均修正为真实发球流程及比较原值未被修改，保留首次失败日志，没有削弱生产行为或断言目标。

本轮不扩展网站部署、App Store 翻译录入或完整 Duo 连续开合矩阵；原有 Duo API 和兼容回退保留。没有提交、推送、上传或提审；母语审校和物理设备专项仍未覆盖。
