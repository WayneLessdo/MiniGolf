> 后续更新：本记录的 build4 是历史。Duo 首发补充修复并上传 **1.0.0（7）**，真实输入已补充验证；此前合成拖拽失败记录仍有效。网站 v3 已部署。见[Duo 首发实施与证据](duo-launch-20261024.md)和[当前上架进度](../release/上架进度-2026-10-24.md)。

# MiniGolf 玩家反馈修订 · 2026-10-24

本轮按用户六项反馈修改现有 Swift / UIKit App，使用指定的 game-ui-ux 技能；不再适用早期“只交空骨架”的停点。保留所有原有工作区修改，未提交或推送 Git。

## 行为

- 新增完整 English 资源及选择项，共七语、每语198个 key。跟随系统时尊重可用语言偏好；全部不匹配则使用英文。显式选择持久化，不写系统 AppleLanguages，不重置当前对局。
- 开局页“隐私政策 / 语言”组成间距12pt的主题绿色按钮组，描边、圆角及3pt底部阴影提供轻微立体感；按压减小阴影。常规横排、窄窗口及辅助字号纵排，最小热区48pt；沿用真实四边安全区与系统保留区域。
- “震动+生效”按上下文理解为“触感+音效”。保留已有挥杆/入洞音效及独立设置，新增挥杆 soft impact（强度0.22）。两个开关全新安装默认开启，保留用户已存的关闭选择。Reduce Motion 抑制运动和触感，运行中更改设置仍沿用既有通知处理。
- 新增累计积分，完成一洞按同一结算的星级增加1–3分，入口为“我的花园”。原种子、花园、成绩、精通、语录和结算凭据整体迁移到 Keychain，保留本地恢复副本。重播同一结算不重复加分，换关、重开不清积分，种花只扣种子。
- **旧版没有累计星数账本，不能准确还原历史累计星级**：无新积分字段的旧存档按已完成地图数补记基础分，不推算不存在的历史明细；种子及已有收藏原样保留。
- Keychain 使用应用自己的 generic password service/account、AfterFirstUnlockThisDeviceOnly，不进行 iCloud 同步，也不随备份迁至其他设备。先成功读取“无记录”才迁移；锁定/损坏时不让旧缓存覆盖安全存档，写入失败回滚此次变更并显示存档失败信息。不得承诺抹机、换机后的永久保留。七语离线政策与网页源已同步这一变化。
- 普通模式按同一拉杆方向越过障碍：依据球路和障碍实际进出位置，使用抛物线视觉高度与地面阴影，落地后继续按材质减速；场外回最后安全点、不反弹。Reduce Motion 只取消抬升视觉，不改变规则。Q版及六道明确以反弹为目标的课题保留原物理；场景快照保存跃起过程。

## 后续积分市场

已记录产品方向：可评估用本地积分兑换游戏内装饰或工具。兑换对象、扣分、退款、权益恢复和防篡改需另行定义；本版没有市场、购买、兑付或付费解锁。Keychain 是本地保存，不等于可信的服务器交易账本。

## 截图与审核依据

中文截图本身不足以推断必然被拒审；Apple要求截图真实呈现App使用情况，并允许各语言各尺寸独立素材。后台原英语（美国）页面的截图全部中文，且说明明确写“不含英文”，与此次新版本不符，需同步替换并关联新版。海外页面以英文真实UI作为通用素材；原简体中文本地化保留。

依据：

- [Apple：商店信息本地化](https://developer.apple.com/help/app-store-connect/manage-app-information/localize-app-information)
- [Apple：截图规格](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)
- [Apple：截图真实展示App](https://developer.apple.com/jp/help/app-review/guideline-reference/2-3-3-screenshots)

新版1.0.0（4）使用正式Xcode27.1（27A9275）、iOS27.1SDK归档，七语/版本/签名/隐私清单检查通过。2026-10-24 11:32:01北京时间上传成功，Apple开始处理，不能把上传完成等同于处理完成或公开发布。

后台已保存19张英语实图（iPhone中/大屏各6、iPad6、Duo外屏1），并更新英语说明和审核备注；Apple处理完成后关联build4，11:46生成仅含build4的“可供审核”草稿。TestFlight原验收组已加入build4并显示“正在测试”；未正式送审或发布。

## 已执行验证

| 检查 | 结果与证据 |
| --- | --- |
| 单元测试 | 67项全部通过，`work/player-update-20261024/FinalPhone.xcresult`；覆盖真实系统Keychain、迁移、写入失败、读取锁定、重复结算、普通越障/边界、Q版与六课题可玩路线、恢复、语言完整性及反馈偏好 |
| 普通iPhone英文 | 英语选择、底部间距与热区、反馈独立开关、积分展示、真实拉杆/入洞/两画风/课题/种花/语录均通过 |
| 中屏iPhone | iPhone16Pro/iOS18.5，真实英文截图流程通过，1206×2622 |
| 大屏iPhone | Store Large/iOS18.5，440×956pt，compact/regular，safe area top62/left0/bottom34/right0，regions为空；实图1320×2868 |
| iPad | 13英寸M4/iPadOS18.5，真实英文流程通过，1032×1376pt，regular/regular，safe area top24/left0/bottom25/right0，regions为空，2064×2752 |
| 最大字号与旋转 | 初轮测试使用固定方向滚动找不到法语卡片；改为按当前目标位置判断滚动方向，原断言保留，`LargeTextFinal.xcresult`最终通过。`FooterFinal.xcresult`保留初次失败与已通过的最终圆角按钮/英文设置用例 |
| Duo本轮 | 正式工具链、Duo27.1（24A94401）外屏可启动和进入英文球场。自动拖动未登记击球（0杆、launch=none），未完成入洞截图流程；保留失败`DuoStable.xcresult`，仅使用失败发生前正常采集的球场图。不把此前的全姿势矩阵冒充本轮通过 |
| Release | 正式归档、签名验证及App Store导出/上传成功；`archive-inspection.json`、`archive-final.log`、`export.log`、`upload.log` |

真实截图：[底部按钮](screenshots/player-update-20261024/store-updated-footer.png)、[English选择](screenshots/player-update-20261024/store-updated-language.png)、[积分](screenshots/player-update-20261024/store-updated-points.png)。商店英文源图、布局证据及哈希位于 `docs/screenshots/player-update-20261024/en/` 和 `release/app-store/screenshots/en/`，仅做PNG至不透明JPEG转换，没有裁切、文字覆盖或伪造游戏状态。

## 实际限制

没有物理手机触感、外放音量、温升验证；本轮Duo完整开合/旋转/半折回归未通过，不能仅凭模拟器截图确认真实握持或光学折痕。Keychain实际系统读写已测，但真实卸载/重装、抹机、换机未实测。网页源已更新，公开网站是否部署须以部署结果为准。

后台凭证：[构建4正在测试](screenshots/player-update-20261024/connect-testflight-build4.jpg)。公开网站本轮源文件未部署。

商店凭证：[英语截图已保存](screenshots/player-update-20261024/connect-english-media.jpg)，只读列表核对中屏6/大屏6/Duo1，iPad上传后确认6。结构化记录：`work/player-update-20261024/backend-status.json`。
