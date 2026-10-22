# FoldPutt 商店物料包

首发已确认支持 **iPhone、iPad、iPhone Duo**，仅选择合规资料齐全的海外地区，暂不含中国大陆。用户已确认开发者会员开通；具体团队、App 记录、审核电话与销售国家/地区仍需在后台核对。

## 可直接复制的字段

- 总清单见 [App Store Connect 逐项填写清单](../App-Store-Connect-填写清单.md)，包含字段值、选择项、附件说明和仍需真实资料的项目。
- `metadata/zh-Hans/`：中文名称、副标题、宣传文本、描述、关键词，每项独立 `.txt`。
- `metadata/en-US/`：英文商店元数据，明确说明 App 内界面为简体中文；不冒充已完成英文界面本地化。
- `copyright.txt`：`2026 Wayne`。
- `review-notes.txt`：英文审核说明，包含政策离线入口。
- `app-privacy.txt`：隐私标签填写建议，与包内清单分别处理。
- `age-rating.txt`：年龄问卷填写建议；最终评级由后台计算。
- `contact.json`：公开名称、支持邮箱与尚缺少的真实字段。`null` 不是可粘贴的后台值。
- `metadata-lengths.json`：字段长度与上限检查。

## 需上传的文件

- `AppIcon-1024.png`：已存在的 1024×1024 不透明图标母图。App Store 图标通过构建资产提交；本副本供品牌与物料核对。
- `screenshots/`：19 张真实模拟器运行画面：iPhone 6、iPad 6、Duo 内屏 6、Duo 外屏 1。各目录清单记录原始尺寸、来源和哈希；Duo 采原生 framebuffer，全部仅转不透明 JPEG，无缩放/裁切/叠字。
- `asset-provenance.md` 与 `asset-inventory.json`：当前资源来源与文件哈希；生成使用权仍需结合账号实际条款确认。
- App Preview 目前不提供，是可选物料，不影响基础首发。

政策与支持网页在 `../web/`，已填写 Wayne 与 waynelessdo@gmail.com。已公开部署：隐私政策 https://foldputt-help-wayne.humble-mite-6617.chatgpt.site/privacy；支持页 https://foldputt-help-wayne.humble-mite-6617.chatgpt.site/support。新增 privacy_policy_url.txt / support_url.txt 可直接复制。

## 提交前仍需完成

1. 使用苹果已接受的正式 Xcode/SDK 重新生成最终分发包，完成分发签名和 Organizer 验证；本机 beta build 产生的未签名验证归档不能直接上传。
2. 将已部署的政策/支持真实 URL 填入后台（网页部署已完成）。
3. 填写审核联系人的真实姓、名、国际格式电话号码，核对 Team、Bundle ID 归属及 App 记录。
4. 选择具体海外地区，按适用要求完成 DSA/游戏许可等事项。
5. 以最终包核对截图、描述、隐私及年龄问卷，按约定执行提审。

本轮不自动执行公开托管、上传、提审或发布。验证结果与覆盖限制见项目 `docs/release-prep-20261022.md`。

商店语言及后续实际操作见 [国际上架语言与操作步骤](../国际上架语言与操作步骤.md)。tr/ar/pt/fr/es并非必须全部添加；截图保持当前真实UI，App内多语言按用户决定后续实施。
