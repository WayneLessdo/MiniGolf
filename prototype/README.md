# FoldPutt DUO Lab

本地交互概念网页，用于比较 5 个 iPhone DUO 专属玩法方向。它是产品/交互评审原型，不是 FoldPutt 的 Swift 游戏工程，也不实现真实物理引擎。

## 打开

```bash
cd /Users/cws/Desktop/FoldPutt/prototype
python3 -m http.server 4173
```

然后打开 `http://localhost:4173`。也可以直接双击 `index.html`，但本地服务器能保证 SVG 资源在所有浏览器中正常加载。

## 交互

- 左侧 A–E 切换玩法，中央舞台会同步替换设备形态与控制逻辑。
- A：拖动风场节点、调节拉力环、PUTT。
- B：点击拉力环体验折痕反弹。
- C：点击中缝桥梁，展开可通行路线。
- D：点击策略按钮、SHOT，模拟外屏快推到内屏策略连续性。
- E：查看现实/镜像双球同步场景。
- 右上角减少动效按钮提供静态评审模式。

资源采用本地生成的 SVG（`assets/`），没有引入第三方游戏引擎或外部图片依赖。
