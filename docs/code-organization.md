# FoldPutt 代码目录

工程按业务功能划分，再按 UIKit MVC 和代码职责分层。磁盘目录与 Xcode 导航器同步；文件名和 Swift 类型名保持不变，资源名称、Bundle 查找和测试 target 也保持原有行为。

```text
App/                                  App 与 UIScene 启动、生命周期
Features/
  Gameplay/
    Model/                            对局会话、关卡、模式呈现、参数
    View/                             球场绘制、拉杆控件、Q 版绘制
    Controller/                       游戏编排、布局容器、模式选择、HUD
    Physics/                          游戏世界与物理接口
  Club/
    Model/                            收藏、课题、花园与语录状态
    Controller/                       收藏业务界面
  Settings/
    Language/
      Model/                          语言列表、资源加载、偏好管理
      Controller/                     原生语言选择页
    Privacy/
      Controller/                     隐私政策页
Core/
  DeviceAdaptation/                   系统安全区和 Reserved Region
  Input/                              通用拖动输入数学
  Feedback/                           音效反馈
  Theme/                              字体、颜色、布局常量
Resources/
  Localization/<语言>.lproj/          六套 Localizable.strings
  Levels/                             关卡 JSON
  Sounds/                             音效文件
  Assets.xcassets                     图片与颜色资产
  PrivacyInfo.xcprivacy               Apple 隐私清单
  PrivacyPolicy.txt                   离线政策备用文本
  tuning.json                         游戏参数
Tests/
  Unit/{Gameplay,Club,Localization}/  单元测试
  UI/{Gameplay,Club,Localization,Release}/ UI 自动化
Tools/                                资源生成与截图工具
```

`Features/Gameplay` 保持现有 MVC 关系：`FPDemoSession` 和关卡/状态在 Model，`FPCourseView` 等绘图与输入视图在 View，`FPAdaptiveController` 等负责界面编排和用户操作。`Club` 与 `Settings` 按功能单独聚合，避免把整个应用的 Controller 挤在一个通用 Views 目录。`Core` 只放跨业务使用的平台适配和基础服务；物理实现归 Gameplay，因为它直接维护本游戏的规则和世界。

新增业务优先放进对应 `Features/<业务>/`，再按 Model、View、Controller 或实际职责建立子目录。测试与被测功能同名归档。共享代码只有被多个功能使用时才放入 Core。添加或移动源码时同步调整 Xcode 文件引用与分组；添加关卡/本地化等 Bundle 资源时保留文件原名及其既有查找方式。
