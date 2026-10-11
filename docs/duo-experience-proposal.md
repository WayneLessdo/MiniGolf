# DUO 跨屏体验与通用版方案

2026-09-30。用户已确认实施，全屏版已落地，见 [交付记录](duo-immersive.md)。下文保留原方案背景；仍不接入支付。

## 分发结论

Apple 使用设备家族、最低系统版本和 `UIRequiredDeviceCapabilities` 判断兼容性。当前公开资料中未找到可确认的 iPhone Duo／折叠屏专用上架筛选能力键，不能承诺仅在 DUO 可下载，也不能虚构 Info.plist 键。

- [Apple Required Device Capabilities](https://developer.apple.com/support/required-device-capabilities/)
- [Apple iOS Device Compatibility](https://developer.apple.com/library/archive/documentation/DeviceInformation/Reference/iOSDeviceCompatibility/DeviceCompatibilityMatrix/DeviceCompatibilityMatrix.html)

推荐一个通用版本：普通 iPhone/系统 compact 半窗完整可玩，DUO 展开提供增强体验。付费方案是独立产品决定，目前继续遵循无广告、无付费，不做设备型号购买判断。

## 视觉与交互方案

1. 展开时用同一个自定义全屏球道画布贯穿两个区域。背景延伸到边缘，按钮遵守四边独立 safe area 并避开 division、occlusion。
2. 底部浮动拉杆在闲置/松手后保持约 25% 可见度，拖动时提升为不透明；点击热区始终稳定，不把完全不可见的控件作为必需入口。Reduce Motion 下立即切换透明度，不移动控件。
3. 球经过接缝时使用轻遮挡、草地层次与短水纹表达纵深，铰链角只调节动效。场景/窗口变化不修改已出球的速度或坐标。
4. 物理碰撞需另行确认：已有河岸是实体障碍，不能为了穿透效果静默取消碰撞。可设计一个明确的跨缝通行区域，其他河岸继续碰撞；这属于关卡规则变化，确认后才落代码。
5. 半折继续上画面下操控，单屏保留手动掌机等价入口；不按方向、idiom 或设备型号硬编码布局。

## 实施前要确认

- 本轮先完成多任务/恢复/反馈收口，还是一起替换主布局。
- 跨缝通道如何与现有运河碰撞规则协调。
- 付费是否只是后续讨论；未经确认不加 IAP/收费门槛。

实际改造将主要涉及 FPCourseView 的相机/画布映射、FPPlayLayoutController/FPPullControl 的浮层和透明度、FPArrangementController 的模式容器以及对应 UI 回归。仅将当前纵向球场非等比拉宽会破坏圆球和反射角的视觉一致性，因此需要完整映射方案，不能只拉伸图片。
