# 观察者（暂名）

一位靠休眠跨越时代的观察者，在一颗与地球相似的行星上记录物种、地貌和文明。
第一个小样：农业黎明期的一条河谷（现实原型是新月沃地）。

## 运行

1. 安装 [Godot 4.7](https://godotengine.org/download/macos/)（标准版，不需要 .NET 版）。
2. 打开 Godot，点「导入」，选择本目录下的 `project.godot`。
3. 按 F5（Mac 上是 ⌘B）运行。

## 操作

| 操作 | 手柄 | 键盘 |
|---|---|---|
| 选择 | 十字键 / 左摇杆 | 方向键 |
| 确认 / 对话翻页 | A | 回车 / 空格 |
| 手记 | Y | J / Tab |
| 关闭手记 | B | Esc |

## 目录

- `data/`：全部游戏内容。加地点、物种、发现只需要改这里的 JSON。
  - `locations.json`：地点、连线，以及每个地点在哪些季节能观察到什么（季节 0～3 = 春夏秋冬）。
  - `species.json`：物种图鉴，`real_basis` 写它的现实原型。
  - `discoveries.json`：集齐 `requires` 里的观察后，回着陆舱整理笔记得到的发现。
  - `npcs.json`：人物、他们每季所在的地点（`schedule`）和对话。对话可以用 `seasons` 限定季节，用 `requires` 要求先有某条观察、发现或另一段对话，用 `teaches` 让玩家记下一条听来的见闻。
- `scripts/`：游戏规则和界面。
- `scenes/`：场景。
