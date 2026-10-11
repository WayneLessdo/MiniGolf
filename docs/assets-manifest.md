# 原型切图与资产清单

全部由 Tools/generate_assets.swift 使用 macOS 系统 AppKit/Core Graphics 生成，无 AI 图、无下载素材、无第三方运行依赖。

| 资源 | 位置 | 用途/格式 |
|---|---|---|
| Grass / GrassDeep | Resources/Assets.xcassets/*.colorset | #9BD4B8 / #5FB98F 草地；Light/Dark 保留原品牌值 |
| Sand | 同上 | #FBF7F0 沙白 |
| RewardGold / PenaltyRed / Water | 同上 | #E8B96A / #E06B5C / #6FB4D6 奖励、警示、运河 |
| Surface / TextPrimary / TextSecondary | 同上 | Light 奶油白/深草墨，Dark 午夜底/奶油白/薄荷；只复用既有色值 |
| TextLight / TextDark | 同上 | 浅/深文字独立语义色 |
| GolfBall / Flag | Resources/Assets.xcassets/*.imageset | 全彩 PDF 单比例矢量，实际球道/小地图使用 |
| Cup / SandEdge | 同上 | 洞杯和沙坑边 PDF 矢量备用；主视图采用同类程序化路径 |
| PowerRing | 同上 | PDF 备用；交互时由 CAShapeLayer 实时画圆环、弧长和手柄 |
| DirectionArrow | 同上 | PDF 模板图，Single Scale、Preserve Vector Data；实际瞄准路径动态绘制 |
| Star / SpeedLine | 同上 | PDF 模板图，可 tint；星级实际使用 SF Symbols，速度线为后续表现备用 |
| PenaltyBorder | 同上 | PDF 红边备用；运行时 CAShapeLayer 按 view bounds 描边 |
| golf-ball-1024.png / flag-1024.png | Resources/Exports/ | 1024×1024，有 alpha 透明通道的备用切图 |
| canal-tile.png | Resources/Backgrounds/ 与 CanalTile.imageset | 256×256 不透明周期波纹，可双向平铺；仅装饰，不承载按钮/碰撞规则 |
| AppIcon.png | Resources/Assets.xcassets/AppIcon.appiconset/ | 1024×1024 无 alpha；现代 universal iOS AppIcon，由 actool 编译所需变体 |

系统图标使用 arrow.counterclockwise（重开）、map（小地图）、slider.horizontal.3（设置/演示菜单）、star/star.fill（星级）、gamecontroller（掌机）、flag（开球）、arrow.uturn.backward（回安全点）。力度以程序化圆环为主，无额外力度滑块。

主题入口：Resources/Motion/FPTheme.swift。字体使用系统字阶并支持 Dynamic Type；圆角、阴影、间距集中。动效时长为草皮 0.6s、旗杆 0.4s、成功粒子 0.8s、惩罚红边 0.3s；Reduce Motion 使用静态反馈。

运行中的运河是视觉占位；本轮 mock 出球不执行边界/运河/障碍碰撞。PDF 不代表点击热区，真正交互区域来自 UIKit/CAShapeLayer 的视图与手势。

图像生成工具不可调用：Resources/AIConcepts 保持空目录，docs/ai-image-prompts.md 提供英文 prompts。程序化纹理不标记为 AI 生成。

生成工具首次运行创建资产，已有项应保留。若需要整体重新生成，先确认替换范围，不向用户已有资源静默写入。
