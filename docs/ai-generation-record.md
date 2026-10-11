# 本轮 AI 图像生成记录

2026-09-29，使用内置 `imagegen` 工具；没有 CLI 或额外付费 API 脚本。原始提示词基于 `docs/ai-image-prompts.md`。生成图已逐一视觉检查：概念图无文字/广告/购买，折痕只作运河；背景无球/旗/洞/按钮，保持装饰用途。美术图不是像素准确的交互规格或运行截图。

输出均为不透明 PNG。草地背景另导出 JPG，放入 `GrassCompact` / `GrassRegular` Image Set，运行时只按 horizontalSizeClass 选图，以 0.34 alpha 绘于球道内，不决定布局/碰撞。概念图不加入 App target。

| 类型 | 最终保存路径（工程相对） | 实际尺寸 |
|---|---|---|
| 外屏概念 | Resources/AIConcepts/fp-ui-compact-game-compact-portrait-default-v001.png | 1024×1536 |
| 内屏概念 | Resources/AIConcepts/fp-ui-separated-game-regular-landscape-aiming-v001.png | 1536×1024 |
| 半折概念 | Resources/AIConcepts/fp-ui-pull-charge-folded-l-charging-v001.png | 1024×1536 |
| 外屏背景 | Resources/Backgrounds/fp-bg-grass-compact-portrait-v001.png；同名 .jpg | 1024×1536 |
| 内屏背景 | Resources/Backgrounds/fp-bg-grass-regular-landscape-v001.png；同名 .jpg | 1536×1024 |

## 使用的英文 prompts

### 外屏背景

Generate a UI image: An opaque portrait 1024x1536 pure decorative grass background for FoldPutt compact mini golf. Friendly Physics, tactile fine short grass in FPColors.mint #9BD4B8 and mintDeep #5FB98F, very subtle cream #FBF7F0 fine sand grain at far outer corners only. Diffuse soft light, even low contrast across entire canvas, no dominant object. Preserve quiet independent safe areas on all four edges and a quiet lower thumb control zone. NO ball, flag, cup, holes, obstacles, canal, buttons, text, frames, logos or watermarks. This is background texture only, full bleed.

### 内屏背景

Generate a UI image: Opaque landscape 1536x1024 decorative background for FoldPutt mini golf. Friendly Physics fine short-pile grass in mint #9BD4B8 and deep mint #5FB98F, subtle cream #FBF7F0 fine sand at far corners only. Even soft diffuse lighting. Low contrast quiet left control zone, quiet center division corridor and independent edge safe zones. No baked canal or crease, ball, flag, cup, obstacle, UI, text, buttons, logos or watermark. Full bleed texture only.

### 外屏概念

Generate a UI image: FoldPutt mini golf default state, portrait compact outer display UI concept 1024x1536. Friendly Physics rounded tactile mint #9BD4B8 short grass and cream #FBF7F0 fine-grain sand, a pearl ball and flag, soft shadows. Single column course, bottom thumb pull ring, collapsed minimap sheet affordance. Independent unequal safe insets on four sides. Only one drag gesture, no shoot button or slider. Gold #E8B96A star status. No text/logo/ad/prices, no outer-screen hinge. Static keyframe at end of grass reveal 0.6s and flag 0.4s. Concept art not screenshot.

### 内屏概念

Generate a UI image: FoldPutt mini golf aiming state, landscape regular inner display concept 1536x1024. Friendly Physics tactile mint #9BD4B8 short grass, cream #FBF7F0 sand, gold #E8B96A stars, water #6FB4D6 canal. Left control panel: minimap, one pull ring, star status; right unobstructed ball course with short direction arrow and pearl ball. Central fold only a canal with rounded banks, no buttons or essential text on fold; safe independent outer margins, camera clearance. Soft rounded glass panel, diffuse light. No text/logo/ads/prices/shoot button/multiple sliders. Static aiming keyframe.

### 半折概念

Generate a UI image: FoldPutt mini golf charging state, folded L layout concept 1024x1536, straight-on UI artwork without device bezel. Upper region complete course with short-grass mint #9BD4B8 and cream #FBF7F0 sand, pearl ball and arrow. Lower region minimap, one pulled-back power ring, gold #E8B96A star status; power red #E06B5C used sparingly. Middle horizontal fold only a water #6FB4D6 canal/crease transition, no buttons at fold. Friendly Physics rounded materials, soft light, calm. Independent four edge safe zones. No text/logo/ads/prices/shoot button/joystick/angle gauge. Static charging keyframe, same single drag input.

只有这 5 张属于本轮已生成素材；其余页面仍保留“待外部生图后拖入”，不会宣称整套提示词都已生成。
