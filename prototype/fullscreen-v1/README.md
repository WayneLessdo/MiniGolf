# FoldPutt 三套全屏地图方案

非 DUO 已确定 B；DUO 的 1/2/3 独立候选见 `?study=duo`。

用于用户选择布局的独立 HTML 交互预览。A 四角悬浮、B 双侧轻栏、C 边缘一体均复用已有草地素材；不是 Swift 游戏，不含正式击球物理。

在项目根目录运行：

```sh
python3 -m http.server 4183 --bind 127.0.0.1
```

打开 http://127.0.0.1:4183/prototype/fullscreen-v1/ 。也可用其他空闲端口，保持 URL 中的路径。

- 选择 A/B/C 和六种可用容器空间；可勾选较大文字、减弱动态效果。
- 单指或鼠标拖动拉杆，HUD 隐藏、操作轮廓保留 14%，松手恢复。也可用评审按钮查看静态透明状态。
- 选项用独立 dialog，列表可滚动，点外部或按 Escape 关闭。
- 尺寸、四边 safe area、traits、division/occlusion 均为评审输入，不是 Apple 硬件/API 读数。布局按实际空间避让；按钮不落在保留区。
- 球与洞口在概念构图中避让保留区；这不代表真实对局会在转屏时移动球或重置关卡。
- 正式实现需保留世界坐标与视图坐标分离、圆球等比投影及当前一局连续性，不能把原场地直接拉伸成截图。

本轮已在正式 UIKit 工程中修复选项弹出菜单；全屏布局与隐藏 HUD 交互仅存在于本预览，非 DUO B 已选定，DUO 另待选择后实施。

检查：`node check-layout.mjs`；更多证据见 ../../docs/fullscreen-options.md。
