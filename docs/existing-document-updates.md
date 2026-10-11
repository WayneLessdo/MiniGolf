# 待确认的已有文件更新

只向下列文件顶部追加对应内容，原文完整保留。

## README.md

```markdown
# 当前状态：可运行原型（2026-09-29）

本轮已进入 Swift + UIKit 原型实现，旧文中的“只有文档与空目录”是 M0 历史记录。新增 Xcode 工程、Light/Dark 资源、单拉杆 mock 出球、DUO 分栏与手动掌机演示；未实现完整物理和关卡系统。

运行命令、实际验证和限制见 [原型运行手册](docs/prototype-runbook.md)；资产用途见 [切图清单](docs/assets-manifest.md)；真实截图在 docs/screenshots/；AI 生图不可调用，英文 prompt 见 docs/ai-image-prompts.md。

---

```

## CHANGELOG.md

```markdown
# 2026-09-29 — 0.2.0 UIKit 原型

- 用户授权从空骨架继续；新建 Swift + UIKit App、SceneDelegate、标准分栏与单栏导航、手动掌机入口。
- 新增 mock 拉杆/出球、入洞与回安全点演示，未实现完整物理/关卡。
- 新增 Light/Dark 色板、PDF 游戏件、透明 PNG、运河纹理、AppIcon 与可复现生成工具。
- 提供 AI prompt 降级清单；模拟器验证、截图与构建测试实际结果见 docs/prototype-runbook.md。

---

```

## AGENTS.md

```markdown
# 当前阶段补充（2026-09-29，优先于下方 M0 历史范围）

用户已确认 Swift + UIKit 并授权可运行三态原型开发。禁用 SwiftUI、禁用 Objective-C 源码（桥接头仅在用户要求且必要时例外）；当前没有桥接头。原型允许 mock 出球与演示反馈，不实现完整物理/关卡系统。下方“仅空骨架/等待技术栈确认”属于已完成 M0 的历史范围，不再阻止已授权原型工作。

所有新建文件位于 /Users/cws/Desktop/FoldPutt。修改会话开始前已有文件时先列目录并征求确认；当前任务内新增文件的编译修复与必要迭代属于已授权工作。大改动先出计划。DUO 布局、单手势、配色与动效硬约束继续有效。

---

```

