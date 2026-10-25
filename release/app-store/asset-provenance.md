> 2026-10-24 增补：英文 Duo 槽位采用候选 1.0.0（7）的 6 张真实运行图加玩法排版；[逐图来源、裁剪坐标与 SHA-256](screenshots/duo-campaign/manifest.json)。第 3 张设备外观来自实际 Device Hub 渲染，其余为原生屏幕捕获；没有 AI 重画 UI 或注入奖励。既有 App 草地图仍沿用下表的 AI 来源，不改变其来源声明。英文主商店当前 24 张（iPhone 中/大、iPad、Duo 各 6），下表 25 张为历史批次。

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
| Q版球、花朵、观众与HUD图形 | Features 与 Core 中的UIKit/CoreGraphics绘制代码 | 源码绘制；本轮未新增外部美术库 |
| 字体和SF Symbols | UIKit系统字体/系统字体回退、UIImage(systemName:) | App内没有打包第三方字体文件；系统内容按适用平台许可使用，不声明为自有字体/图标 |
| 25张商店截图 | 各screenshots目录manifest.json及原始运行证据 | 真实模拟器画面，不使用概念画面或网页原型 |

逐文件路径与SHA-256见 asset-inventory.json。哈希可核对素材版本，不能证明服务账号的商业使用条款、是否侵犯他人权利或Wayne的法定主体身份。2026-10-23续办时，用户明确确认“已核实，均有发布及商业使用权”，范围包括上述程序化、系统字体/图标及AI资源。已据此在App Store Connect保存“是，此App拥有对其第三方内容的必要权利”。这是发布者确认记录，不冒称代理独立审核全部适用条款，不虚构额外授权书。

可复制的核对记录模板（替换真实结果后归档）：

```text
FoldPutt 0.2.0资源已对照asset-inventory.json核对；程序化素材来源为项目脚本，草地和概念资源来源为2026-09-29内置imagegen生成记录；生成账号及适用条款核验结果：【真实结果/证据位置】；发布权利持有人及声明：【真实值】。
```
