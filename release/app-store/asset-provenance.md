# 发布资源来源记录 · 2026-10-22

当前工程不是“全部无AI”。初期 docs/assets-manifest.md 只对应早期程序化原型；后续已有AI生成草地和概念资源。本清单按当前资产目录、生成脚本、实际引用和历史记录整理，不替代账号适用条款或权利证明。

| 资源 | 本地来源证据 | 当前用途 / 权利核对 |
| --- | --- | --- |
| AppIcon、GolfBall、Flag、Cup、SandEdge、PowerRing、DirectionArrow、Star、SpeedLine、PenaltyBorder、CanalTile | Tools/generate_assets.swift、docs/assets-manifest.md | 程序化绘制的现有母图/矢量/纹理；图标仍为现有1024母图 |
| GrassEdgeTile | Tools/generate_grass_edge.swift | 程序化纹理 |
| RewardStarSprite | Tools/generate_assets.swift（star-1024.png，已核对副本哈希一致） | 程序化星星备用资产 |
| GrassCompact、GrassRegular | docs/ai-generation-record.md、Resources/Backgrounds/ 的PNG母图/JPG副本 | 2026-09-29内置imagegen生成；草地确实用于正式球场/开局预览。不能声明全部手工原创 |
| ConceptCompact、ConceptRegular、ConceptFolded | 同一图像生成记录及Resources/AIConcepts | 后续进入资产目录，供美术预览；正式球场未引用概念画面。编译资产目录含这些Image Sets，不将其当运行截图 |
| putt.wav、hole.wav | Tools/generate_feedback_sounds.py；docs/duo-multitask.md | 本地程序化PCM音效；没有下载商业曲库的证据 |
| Q版球、花朵、观众与HUD图形 | Views中的UIKit/CoreGraphics绘制代码 | 源码绘制；本轮未新增外部美术库 |
| 字体和SF Symbols | UIKit系统字体/系统字体回退、UIImage(systemName:) | App内没有打包第三方字体文件；系统内容按适用平台许可使用，不声明为自有字体/图标 |
| 19张商店截图 | 各screenshots目录manifest.json及原始运行证据 | 真实模拟器画面，不使用概念画面或网页原型 |

逐文件路径与SHA-256见 asset-inventory.json。哈希可核对素材版本，不能证明服务账号的商业使用条款、是否侵犯他人权利或Wayne的法定主体身份。发布者仍须确认生成时/使用时适用条款、账号有权使用这些输出，及全部已知素材权利；后台Content Rights据此作真实声明。当前仓库未提供独立签署的许可确认文件，不虚构已取得的授权书。

可复制的核对记录模板（替换真实结果后归档）：

```text
FoldPutt 0.2.0资源已对照asset-inventory.json核对；程序化素材来源为项目脚本，草地和概念资源来源为2026-09-29内置imagegen生成记录；生成账号及适用条款核验结果：【真实结果/证据位置】；发布权利持有人及声明：【真实值】。
```
