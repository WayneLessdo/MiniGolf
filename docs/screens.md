# 页面、状态与截图计划

## 页面清单（D 的 MVP 裁剪；来源 P §9/15）

| 页面 ID | 页面/最高优先信息 | compact | regular | 范围 |
|---|---|---|---|---|
| home | 开始/继续一洞 | 单栏，球道预览+主要入口 | 可搭配关卡详情分栏 | M1 |
| levels | 关卡与星级 | 列表 → 详情 | UISplitViewController sidebar+详情 | M1 占位、M2 数据 |
| game | 球、洞、方向/力度、杆数/标准杆 | 球旁拉杆或控制托盘 | 球场+控制区，优先 arrangement | M1 状态夹具、M2 可玩 |
| result | 本洞结果/星级/下一洞/重试 | 安全区内紧凑结算 | 结果和球路画面分区 | M1 静态、M2 真实 |
| penalty | 原因、继续/重试 | 小提示，不遮洞/拉杆 | 原控制区承载出口 | M1 静态、M2 真实 |
| settings | 暂停、声音/触感、控显分离、重播开球 | 标准列表/sheet | 标准容器中呈现 | M1/M3 |
| appearance | 免费外观预览 | 同等入口 | 内容与预览可分栏 | 延后，不是商店 |
| clock / multiplayer | 深夜场景/传机计分 | 手动入口 | 同功能 | 延后，非 MVP 承诺 |

HUD 只保留必要杆数/标准杆与拉杆反馈，距离按可读性决定是否显示；工具收进标准菜单。页面及导航栏不按方向或 DUO 名称决定位置。

## 对局五状态（页面不是五套副本）

| 状态 | 进入 | 视觉/信息 | 可操作 | 离开 |
|---|---|---|---|---|
| default | 开始洞/停球/安全点恢复 | 球与洞清楚，简短拉杆提示 | 开始拖拉、暂停 | aiming |
| aiming | 拉杆区按下，尚在死区 | 方向指示，力度为零或很低 | 同一手指改变向量、取消 | charging/default |
| charging | 拉距超过死区 | 方向线+环形力度，不加滑块 | 同一拖动微调；松手 | rolling；取消回 default |
| success | 合法入洞一次 | 星级、杆数、粒子 0.8s | 下一洞/重试；可跳过装饰 | default/levels |
| penalty | 超时或有效碰障达阈值 | 原因、红边 0.3s、残局出口 | 同一拉杆继续、重试/退出 | default/rolling/success |

补充 rolling 为物理进行态，paused 为暂停覆盖层；teeOff 是 default 前的可跳过表现，不另设输入系统。penalty 是规则上下文，内部仍可经历 aiming/charging/rolling；不要把它做成只能等待的失败弹窗。出界本身走安全点恢复，不强制升级到残局。

## 三态截图主矩阵（计划，尚未截图）

基线：Xcode 27.1 (27A9269)、iOS 27.1、Device Hub iPhone Duo。先固定同一洞/同一球位/同一杆数/固定随机种子；用测试状态夹具进入各状态，禁止为截图临时改变产品规则。

| 编号 | Device Hub 设置 | 必拍状态 | 验收重点 |
|---|---|---|---|
| C | 闭合外屏 | default/aiming/charging/success/penalty，5 张 | compact 宽，四边 safe area，拇指拉杆，重开与确认可达 |
| R | 展开全平内屏 | 同上，5 张 | regular/regular，分栏与开阔球道，缝中心无按钮，无硬编码半屏宽 |
| F | 半折内屏（模拟器可用控制） | 同上，5 张 | division 活跃时避让，控制与内容在系统适宜区域，玩法和输入与 C/R 一致 |

至少 15 张对局基准图；再拍 home/levels/settings 三态，共 9 张；合计 24 张基准截图。结果截图记录自己的实际像素尺寸，不使用附件未经验证的 1398×2034 或 2007×2853 当运行尺寸。

后续文件名建议 C-default.png、R-charging.png、F-penalty.png，保存在工程 docs/verification/screenshots/（本轮不创建该目录）。伴随 manifest.json 记录 build/commit、设备/runtime、状态/洞号、view/scene bounds、displayScale、horizontal/vertical size class、四边 inset、division/occlusion frame 与 active 状态、Reduce Motion 和字号。不存在的像素/帧率数据不得填写。

## 转换与边界取证

1. default/charging/rolling/success 各走一次开→折→合→开，录短视频与前后状态日志；charging 取消不误击，rolling 状态不重置，success 不重复奖励。
2. 外屏与内屏分别旋转 90°/180°，再测分屏/窗口尺寸变化；核对不以方向分支，非对称 inset 不裁控件。
3. 内摄 occlusion inactive→active→inactive：若 Device Hub/系统可触发则拍真实证据；否则以标注“注入夹具”的布局测试补覆盖，真实内摄变化记未测。游戏不为测试新增摄像头权限。
4. F 状态加 Reduce Motion、最大辅助字号、较长中文/英文文案，检查按钮不跨缝、不截断核心信息；草皮/粒子/抖动已弱化。
5. 普通 iPhone 和可调整尺寸的 regular 容器分别验证手动开球、控显分离、重播、继续/重试；没有铰链仍全功能。
6. 成功/重开确认优先用系统呈现；自定义提示须保证按钮热区整体不与保留区相交。

如 DUO runtime 后续不可用，普通 iPhone compact + iPad/容器 trait regular + 非对称 inset/region 注入验证“布局逻辑”，截图标为替代夹具，不能声称 DUO 开合实测。光学折痕、触觉、握持/热量仍需真机。
