# FoldPutt 发布交付包 · 2026-10-22

先阅读 [国际上架语言与操作步骤](国际上架语言与操作步骤.md)，再打开 [App Store Connect 逐项填写清单](App-Store-Connect-填写清单.md)：每项有可复制字段、选择或真实资料模板。然后按 [物料说明](app-store/README.md) 选择截图、图标与独立文案；已部署网页及来源在 [web](web/README.md)。

本包已准备19张商店实图（iPhone6、iPad6、Duo内屏6+外屏1）及中文/英文商店文案，公开资料为Wayne / waynelessdo@gmail.com。英文商店描述已同步为实际六语支持，并明确没有英文App界面。

项目内隐私、失败回归与本轮多尺寸验收已完成。尚待正式Xcode分发签名/上传验证、后台真实审核联系人及销售地区。当前没有可直接上传的签名IPA；不代表已提审或保证明日上线。

ZIP保持项目相对目录：`release/` 为可用物料，`docs/release-prep-20261022.md` 为交付报告，`docs/screenshots/` 为游戏原始画面/布局与新邮箱政策验收证据。旧邮箱的政策截图只保留在项目历史目录，不加入本次ZIP。工作区 `work/release-20261022/` 中原始xcresult/日志/未签名归档未装入ZIP；需要完整验证链时回到项目查看。

截图目录的manifest引用项目相对路径，原始PNG和布局文件可在同包docs中找到；截图没有缩放、裁切或叠字。`package-validation.json`记录本地文件/尺寸/配置检查，不等同App Store验证或真实设备验收。

政策：https://foldputt-help-wayne.humble-mite-6617.chatgpt.site/privacy

支持：https://foldputt-help-wayne.humble-mite-6617.chatgpt.site/support

本轮使用Sites部署；苹果登录邮箱只在本地操作步骤中记录，没有进入站点源码。托管层的安全脚本与重定向已单独核验。

本轮 App 语言资源已改为六套 `Resources/Localization/{语言}.lproj/Localizable.strings`（每套195键），设置菜单及启动页均可即时切换，并支持跟随系统。维护与验证说明见 `docs/language-switch-20261022.md`；商店字段仍须在 App Store Connect 单独填写。
