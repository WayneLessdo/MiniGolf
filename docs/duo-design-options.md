# DUO 三套独立布局候选（2026-10-09）

用户已确认：**非 DUO 采用 B；DUO 另给三个不同布局选择**。本轮是 DUO 设计效果交付，未修改正式 Swift 球场、输入或物理。三个方案使用相同展开内屏画幅，不是 B 的三个姿态。

| 候选 | 信息/操作分布 | 适合比较的重点 |
|---|---|---|
| DUO 1 跨屏沉浸 | 左上标题、左下拉杆；右侧工具、右下成绩 | 控件面板最少，跨屏地图最突出 |
| DUO 2 两翼环抱 | 左侧标题/成绩，右侧工具/拉杆 | 左信息、右操作，更明确的双侧分工 |
| DUO 3 边缘收纳 | 顶部信息条，底边两个角落收纳输入与工具 | 信息层级明确，底边留白更少 |

三者都保留全屏草地、同一种拖拉松手输入；拖动时 HUD 隐藏、拉杆保留 14% 轮廓，松手恢复。独立选项弹窗、Reduce Motion 支持沿用已有预览。HUD 为静态示例数据，不定义新计分规则；中缝为运河/桥面构图，不把角度作为玩法或布局输入。

## 画幅来源

从 `docs/screenshots/duo-immersive/duo-open-tee-off.json` 读取历史 DUO 模拟器交付采样：

- view bounds：951 × 669，traits：regular / regular，scale=3。
- safe area：top=0、left=0、bottom=34、right=84，四边分别处理。
- division：x=455.5、y=0、width=40、height=669，采样中 inactive；仍按物理中缝显示并避让。
- occlusion：x=867、y=0、width=84、height=120；图片右上斜纹表示避让范围，不是摄像头实物造型。

归一化依据见 `work/duo-design-options/geometry-source.json`。这些是 **2026-09-30 历史采样作为设计输入**，不是本轮重新从设备读取的值，更不是可缓存到生产代码的屏幕常量。正式实现仍需当前 view/window/scene 的 traits、bounds、safeAreaInsets 与 reservedRegions。

## 验证与成果

- 三个候选按 7 种可用空间 × 2 种文字规格，共 42 次实际浏览器布局检查通过；控件无重叠、越界或保留区冲突。见 `work/duo-design-options/browser-layout-checks.json`。
- 共享布局计算 84 组通过，另有 6 组 inactive camera 忽略检查和 1 组 inactive division 仍避让检查；`node prototype/fullscreen-v1/check-layout.mjs`。
- 三张主效果图及三张拖杆透明状态图：`docs/screenshots/duo-design-options/`。都来自本地 HTML 的真实渲染，明确标记为方案图，非新 UIKit 模拟器截图。
- 主图逐张目视检查，同一画幅、同一地形示例，只有 HUD 布局与容器视觉变化，便于比较。
- 预览入口：`http://127.0.0.1:4183/prototype/fullscreen-v1/?study=duo`。普通入口默认 B，保留旧 A/C 作为参考，不把 B 自动用作 DUO 选定方案。

本轮未运行 DUO 真机/Device Hub 新一轮矩阵，未安装或改造正式游戏。正式 UI 只可按 size classes、容器可用空间和系统保留区适配，不按设备名或姿态分支；两个预览入口是评审上下文，不是生产设备识别规则。
