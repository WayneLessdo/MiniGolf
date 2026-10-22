# FoldPutt 已部署的政策与支持页

已通过 Sites 公开部署，HTTPS，无需登录；本次使用现有托管服务，没有购买域名或开通额外付费套餐，不承诺无限额度或永久免费。

| 页面 | 真实地址 |
| --- | --- |
| Privacy Policy（英文默认） | https://foldputt-help-wayne.humble-mite-6617.chatgpt.site/privacy |
| Support（英文默认） | https://foldputt-help-wayne.humble-mite-6617.chatgpt.site/support |
| 隐私政策（简体中文） | https://foldputt-help-wayne.humble-mite-6617.chatgpt.site/privacy-zh-Hans |
| 用户支持（简体中文） | https://foldputt-help-wayne.humble-mite-6617.chatgpt.site/support-zh-Hans |

对外名称 Wayne，邮箱 waynelessdo@gmail.com。网页不包含苹果登录账号。英文网页不代表 App 内已完成英文或其他语言适配。

`privacy.txt` 与包内 Resources/PrivacyPolicy.txt 同源；`privacy-en.txt` 和 `support-en.txt` 为英文网页正文。`Tools/prepare_store_pages.py` 生成五份HTML，并从 hosting.json 读取已部署网址，避免再次生成时把联系方式网址清空。

源文件没有统计、广告、表单、外部字体或自行添加的第三方脚本。线上托管层会将 `.html` 正常重定向到不带扩展名的网址，并添加 Cloudflare 安全防护脚本；已区分托管层行为与本地源码，未将整份响应哈希误写成与源码完全相同。五页可见正文、标题、导航和联系方式均核对一致，见 public-url-check.json。政策已说明托管/外部服务独立处理访问数据。

站点ID、版本、部署和来源提交见 hosting.json；站点源码checkout位于工作区 `work/sites/foldputt-help/`，只含公开网页。后续修改后沿用同一个Site重新部署，不重复创建站点。仅重新生成本地文件不会更新线上内容。

后台的英文及新增语言本地化可以使用英文默认网址；简体中文可使用中文网址。是否需要更多翻译还应结合最终市场和适用要求判断，App Store Connect 并不强制每种语言有独立域名。
