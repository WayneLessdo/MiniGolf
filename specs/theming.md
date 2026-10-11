# UI 提示词 → Swift 设计令牌草案

Swift + UIKit。下表是设计数据，尚未创建任何 Swift/JSON/xcassets 资源。P §9/15 的颜色保留，U 的四项时长覆盖原文。前缀建议 FP，后续统一集中定义，组件禁止硬编码。

## 色彩映射

| Prompt 语义 | HEX | Swift 令牌草案 | 角色/来源 |
|---|---|---|---|
| 薄荷绿草地 | #9BD4B8 | FPColors.mint | 主色/草地，P |
| 深薄荷 | #5FB98F | FPColors.mintDeep | 草地层次，P |
| 奶油白 | #FBF7F0 | FPColors.cream | 明亮基础面板，P |
| 日落橙 | #F5A25D | FPColors.sunset | 有限强调/力度，P |
| 树莓粉 | #F0A7B9 | FPColors.pink | 收集/主题点缀，P |
| 蜜金 | #E8B96A | FPColors.gold | 奖励，P |
| 清水蓝 | #6FB4D6 | FPColors.water | 水面/运河，P |
| 午夜 | #101218 | FPColors.midnight | 深色面板/远期星空，P |
| 警示红 | #E06B5C | FPColors.penalty | 惩罚边缘，需文字/形状冗余，P |
| 冰蓝 | #A9D8EA | FPColors.ice | 延后主题资源，P §15.3 |
| 深草墨文字 | #26362D | FPColors.ink | 明亮面板正文，D 补充可读性 |

语义层：FPTheme.surface / textPrimary / textSecondary / accent / warning / reward / controlStroke。明亮基础对为 cream/ink，深色基础对为 midnight/cream。粉彩色不直接作为浅底正文。力度绿→金→橙→红只作装饰辅助；同时显示环形填充长度与可读百分比，颜色不是唯一反馈。

原文“透明度 72%”有歧义，不当作 UIKit 官方材质属性。D 草案将其解释为面板 tint 的 opacity 0.72，最终值须在真实草地背景下复核；系统材质优先 UIVisualEffectView，开启 Reduce Transparency 或对比不足时使用不透明语义 surface。

## 形状、字体、间距

| Prompt 描述 | 令牌 | 草案/限制 |
|---|---|---|
| 软圆角面板 | FPLayout.panelCornerRadius | 24pt；大面板 28pt（原文 px 转为 UIKit 设计建议，不宣称等值换算） |
| 胶囊按钮 | FPLayout.controlCornerRadius | 根据实际高度取半径 |
| 面板留白 | FPLayout.spacing | 4/8/12/16/24/32pt，D |
| 内外屏边距 | FPLayout.contentGutter | compact 16pt、regular 24pt 为设计建议；叠加各自容器安全布局，不代表系统 inset |
| 热区 | FPLayout.minimumTarget | 44pt；主拉杆代理/主要操作优先 56pt，空间不够缩装饰不缩热区 |
| 清晰无衬线 | FPFonts.body / title / caption | 系统字体与 UIFont.TextStyle，UIFontMetrics / adjustsFontForContentSizeCategory |
| 杆数/计时 | FPFonts.score | 等宽数字样式、Dynamic Type；不固定原文 34px |
| 图标 | FPIcons.* | 经 SDK 核实可用的 SF Symbols；独立按钮有 accessibilityLabel，不用 emoji 充当导航 |

## 动效令牌

| 事件 | Swift 令牌 | 正常值 | Reduce Motion | 来源 |
|---|---|---|---|---|
| 开球草皮 | FPMotion.teeGrassDuration | 0.6s | 静态已铺开状态，无展开镜头 | U 强制 |
| 旗杆生长 | FPMotion.flagGrowDuration | 0.4s | 静态旗杆 | U 强制 |
| 入洞粒子 | FPMotion.holeParticlesDuration | 0.8s | 无粒子，静态星级/结果 | U 强制 |
| 惩罚红边 | FPMotion.penaltyBorderDuration | 0.3s | 不闪烁不抖动，静态原因提示 | U 强制 |
| 球速度拖尾 | FPMotion.trailLifetime | 0.4s | 关闭运动拖尾 | P |
| 面板入场 | FPMotion.panelEntranceDuration | 0.42s | 立即显示或弱化淡入，后续实测 | P |
| 按压反馈 | FPMotion.pressDuration / pressScale | 0.09s / 0.94 | 仅高光/颜色状态变化 | P |
| 切镜 | FPMotion.cameraTransitionDuration | 0.18s 候选 | 固定可读视角 | P，M3 评估 |

四项强制时长不可因铰链角度、刷新率、动画工具默认值而变化。角度可修饰正在播放的装饰，但不让用户必须完成开合才结束动效；松手/跳过与可交互状态不等待动画收尾。开球草皮与旗杆可重叠编排（D），不把附件 1.6s 总时长当不可跳过的门槛。

原文 spring(damping 20, stiffness 260) 不是 UIKit dampingRatio 的直接取值；UIKit 动画实现时使用语义 spring 预设并实测，禁止把 20 填进 0…1 比例。Reduce Motion 读 UIAccessibility.isReduceMotionEnabled 并监听其变更；触感偏好与 Reduce Motion 分开，音/触感均不能作为唯一结果提示。

## 配色/无障碍验收

基础不透明色对已按 sRGB 相对亮度计算：ink/cream 为 11.93:1，cream/midnight 为 17.53:1。此检查不涵盖半透明最终合成画面。

正文对比目标 ≥4.5:1；有意义的图标/边界 ≥3:1。在实际 blur、场景与主题背景上逐个复测，基础色对合格不等于最终面板合格。最大字号下 HUD 减少辅助项，主拉杆、杆数与确认/重开继续可达。深色模式单独配色和截图，不简单倒转草地。

ui-ux-pro-max 检索未得到经验证的迷你高尔夫专属设计系统：首次返回偏通用网页设计，收窄 mobile game 产品检索为零结果。因此不导入其字体/网页断点/GSAP 建议；这里只使用其通用可访问性检查与附件色板，所有新增令牌标为 D。

## 2026-10-09 用户交互覆盖

- 每局地图完整显示，关卡数据在 session 初始化时已加载；球场共用图片预解码并复用，不以草皮遮罩逐步展示新地图。手动“重播开球”仍使用草皮 0.6s / 旗杆 0.4s；铰链动效仍只装饰，不阻塞输入。
- 入洞一次轻微反馈：画面横向最大 2pt，0.18s；原生 light impact 强度 0.35。此组数值为实现建议，待真机手感抽样，非附件事实。触感开关独立于音效，Reduce Motion 时禁用抖动及此次运动触感，使用静态结果。
- WIN 提供“点击屏幕进入下一关”与同名原生按钮，常规热区 48pt，支持 Dynamic Type；列表使用原生纵向滚动并允许按钮触摸交给滚动识别器。

- 字体沿用 UIFont.preferredFont 的系统描述符并设置字重；禁止对已缩放的 pointSize 再调用 UIFontMetrics 缩放。

## 全屏 HUD 方案评审补充

三套预览以全屏地图背景、周边标签/操作为共同方向；拖杆期间 HUD 静态隐藏、拉杆留 14% 轮廓，松手恢复，过渡令牌 150ms；Reduce Motion 无过渡。这些值是规划建议，尚未写入正式 UIKit HUD。示例保留区仅为布局测试输入，不是系统 API 结果或硬件尺寸。
