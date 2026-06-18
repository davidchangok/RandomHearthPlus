# RandomHearthPlus
**RandomHearth Plus（随机炉石增强版）**

[Random Hearthstone](https://github.com/JamienAU/RandomHearthstone) 的增强版，原作者 JamienAU。新增传送玩具支持、修饰键绑定（Shift/Ctrl/Alt × 左/右/中键），完全兼容 WoW 12.0+ API。

*Enhanced version of [Random Hearthstone](https://github.com/JamienAU/RandomHearthstone) by JamienAU. Adds teleport toy support, modifier key bindings (Shift/Ctrl/Alt + click combinations), and full WoW 12.0+ API compatibility.*

---

## 功能特色 | Features

### 随机炉石 | Random Hearthstone
- **随机轮换** — 每次左键点击从已启用的玩具中随机选取一个，不会连续两次选中同一个。
- **传送玩具** — 支持传送玩具（如探索者的虚灵跃迁门、奥秘私钥、探索者的机器人 7001）加入随机轮换。

*Random rotation of enabled toys on each left-click; never repeats the same one. Teleport toys included.*

### 修饰键绑定 | Modifier Key Bindings
- **3×3 网格** — Shift / Ctrl / Alt × 左键 / 右键 / 中键，共 9 种组合可通过下拉菜单独立绑定。
- **绑定目标** — 可绑定任意玩具（直接使用不轮换）、普通炉石、达拉然炉石或要塞炉石。
- **实现方式** — 使用 PreClick 脚本在点击时实时检测修饰键状态并动态切换动作，避免 `/click` 无法传递修饰键状态的已知限制。

*9 combinations (Shift/Ctrl/Alt × Left/Right/Middle Click) via per-binding dropdowns. Uses PreClick script for dynamic routing since /click cannot propagate modifier state to SecureActionButton attributes.*

### 右键/中键快捷操作 | Right/Middle Click Shortcuts
- **右键** → 达拉然炉石（可选，默认开启）
- **中键** → 要塞炉石（可选，默认开启）

*Right-click → Dalaran Hearthstone. Middle-click → Garrison Hearthstone. Both toggleable in options.*

### 其他 | More
- **宏图标** — 可选择"随机"（跟随当前玩具动态变化）、"普通炉石"或任意指定玩具作为宏图标。
- **盟约感知** — 自动检测盟约炉石的声望解锁状态，可选择仅限当前盟约。
- **种族限制** — 德莱尼全息宝石自动限制为德莱尼/光铸德莱尼种族。
- **德鲁伊友好** — 宏中自动插入 `/cancelform`。
- **全面板滚动** — `/rhp` 设置面板中所有控件（玩具列表 + 选项 + 修饰键绑定）统一纵向滚动。
- **中文注释** — `RandomHearthPlus.lua` 全文包含详细中文注释，方便理解和二次开发。

*Macro icon override, covenant awareness, Draenei race check, druid /cancelform support, unified scroll panel, and full Chinese inline code documentation.*

---

## 安装 | Installation

1. 从 [Releases](https://github.com/davidchangok/RandomHearthPlus/releases) 下载或克隆本仓库。
2. 将 `RandomHeathPlus` 文件夹放入 `World of Warcraft\_retail_\Interface\AddOns\` 目录：
   ```
   AddOns\RandomHeathPlus\
       RandomHeathPlus.toc        ← 文件名必须与文件夹名一致
       RandomHearthPlus.lua
       LocalisationPlus.lua
   ```
3. 重启 WoW 或 `/reload`。

> ⚠️ **注意：** `.toc` 文件名必须与文件夹名完全一致（`RandomHeathPlus`），否则 WoW 无法识别插件。这是选择角色界面看不到插件的最常见原因。

*Download and place the RandomHeathPlus folder in AddOns. TOC filename must match the folder name exactly.*

---

## 使用 | Usage

### 快速开始 | Quick Start

1. 输入 `/rhp` 打开设置面板。
2. 确保需要的炉石和传送玩具已勾选。
3. 插件会自动创建一个名为 **"Random Hearth"** 的宏（名称可自定义）。
4. 将宏拖到动作条上点击即可！左键随机炉石，右键达拉然炉石，中键要塞炉石。
5. 按住 Shift/Ctrl/Alt + 点击，触发在设置面板中配置的自定义绑定。

*Type /rhp to open options. Toys are auto-enabled. A macro named "Random Hearth" is auto-created — drag it to your action bar. Left-click for random, right/middle for shortcuts, Shift/Ctrl/Alt+click for custom bindings.*

### 修饰键绑定配置 | Modifier Binding Setup

在设置面板中滚动到 **"修饰键绑定"** 区域。3×3 网格中每个下拉菜单对应一个修饰键+按键组合：

| 选项 | 行为 |
|------|------|
| **随机** | 跟随默认行为（左键=随机玩具，右键/中键=达拉然/要塞） |
| **炉石** | 使用普通炉石 (`item:6948`) |
| **达拉然炉石** | 使用达拉然炉石 (`item:140192`) |
| **要塞炉石** | 使用要塞炉石 (`item:110560`) |
| **指定玩具** | 直接使用该玩具，不参与随机轮换 |

*Choose from Random / Hearthstone / Dalaran Hearthstone / Garrison Hearthstone / any specific toy for each of the 9 modifier+button combinations.*

### 选项面板说明 | Options Panel Reference (`/rhp`)

| 设置项 | 说明 |
|--------|------|
| 玩具复选框 | 启用/禁用单个玩具参与随机轮换 |
| 全选 / 全部取消 | 批量切换所有玩具 |
| 仅允许当前盟约炉石 | 限制盟约炉石只使用当前盟约的 |
| 右键 → 达拉然炉石 | 宏右键点击使用达拉然炉石 |
| 中键 → 要塞炉石 | 宏中键点击使用要塞炉石 |
| 宏图标 | 选择宏显示的图标（随机/炉石/指定玩具） |
| 宏名称 | 自定义自动创建宏的名称（最长16字符） |

---

## 玩具数据库 | Toy Database

### 炉石玩具 | Hearthstone Toys

| Item ID | 名称 | Name |
|---------|------|------|
| 184353 | 格里恩炉石 | Kyrian Hearthstone |
| 183716 | 温西尔罪碑 | Venthyr Sinstone |
| 180290 | 法夜炉石 | Night Fae Hearthstone |
| 182773 | 通灵领主炉石 | Necrolord Hearthstone |
| 54452 | 虚灵之门 | Ethereal Portal |
| 64488 | 旅店老板的女儿 | The Innkeeper's Daughter |
| 93672 | 黑暗之门 | Dark Portal |
| 142542 | 城镇传送之书 | Tome of Town Portal |
| 162973 | 冬幕节炉石 | Greatfather Winter's Hearthstone |
| 163045 | 无头骑士炉石 | Headless Horseman's Hearthstone |
| 165669 | 春节炉石 | Lunar Elder's Hearthstone |
| 165670 | 情人节炉石 | Peddlefeet's Lovely Hearthstone |
| 165802 | 贵族花园炉石 | Noble Gardener's Hearthstone |
| 166746 | 火焰节炉石 | Fire Eater's Hearthstone |
| 166747 | 美酒节炉石 | Brewfest Reveler's Hearthstone |
| 168907 | 全息数字化炉石 | Holographic Digitalization Hearthstone |
| 172179 | 永恒旅者炉石 | Eternal Traveler's Hearthstone |
| 193588 | 时光行者炉石 | Timewalker's Hearthstone |
| 188952 | 统御炉石 | Dominated Hearthstone |
| 200630 | 欧恩伊尔风语者炉石 | Ohn'ir Windsage's Hearthstone |
| 190237 | 经纪人传送矩阵 | Broker Translocation Matrix |
| 190196 | 开悟者炉石 | Enlightened Hearthstone |
| 209035 | 烈焰炉石 | Hearthstone of the Flame |
| 208704 | 深居者土灵炉石 | Deepdweller's Earthen Hearthstone |
| 206195 | 纳鲁之路 | Path of the Naaru |
| 212337 | 炉石之石 | Stone of the Hearth |
| 210455 | 德莱尼全息宝石 | Draenic Hologem |
| 228940 | 恶名线束炉石 | Notorious Thread's Hearthstone |
| 235016 | 重新部署模块 | Redeployment Module |
| 236687 | 爆炸炉石 | Explosive Hearthstone |
| 245970 | P.O.S.T 大师快递炉石 | P.O.S.T Master's Express Hearthstone |
| 246565 | 宇宙炉石 | Cosmic Hearthstone |
| 263489 | 纳鲁之拥 | Naaru's Enfold |
| 257736 | 光召炉石 | Lightcalled Hearthstone |
| 265100 | 核心守望者炉石 | Corewarden's Hearthstone |
| 263933 | 掠猎物者炉石 | Preyseeker's Hearthstone |

### 传送玩具 | Teleport Toys

| Item ID | 名称 | Name |
|---------|------|------|
| 253629 | 奥秘私钥 | Private Key of the Arcanum |
| 243056 | 探索者的虚灵跃迁门 | Delver's Ethereal Warp Gate |
| 230850 | 探索者的机器人 7001 | Delver's Robot 7001 |
| 276371 | 光帷召回道标 | Shrouded Summoner's Beacon |

---

## 添加新玩具 | Adding New Toys

如果暴雪新增了炉石或传送玩具而插件尚未更新，可自行添加：

1. 从 Wowhead 物品页面 URL 找到 ItemID（如 `item=123456` → ID 为 `123456`）。
2. 打开 `RandomHearthPlus.lua`，将 ID 添加到文件顶部附近的 `rhToys` 列表中。
3. `/reload` 重载界面。

```lua
local rhToys = {
    -- 炉石玩具 | Hearthstone Toys
    184353, -- 格里恩炉石 | Kyrian Hearthstone
    ...
    -- 传送玩具 | Teleport Toys
    123456, -- 你的新玩具 | Your New Toy   ← 在此添加
}
```

*Find the ItemID from Wowhead URL, add it to the rhToys list in RandomHearthPlus.lua, and /reload.*

---

## 斜杠命令 | Slash Command

| 命令 | 动作 |
|------|------|
| `/rhp` | 打开设置面板 |

*Opens the options panel.*

---

## 本地化 | Localization

| 语言 | 状态 |
|------|------|
| 简体中文 (`zhCN`) | ✅ 完整 |
| 英文 (`enUS` / `enGB`) | ✅ Complete |

如需添加新语言，在 `LocalisationPlus.lua` 中按 `zhCN` 的模式添加语言块即可。

*Currently supports zhCN and enUS/enGB. Add new locale blocks in LocalisationPlus.lua following the zhCN pattern.*

---

## 技术实现 | Technical Notes

### 宏结构 | Macro Structure

生成的宏简洁明了，修饰键路由由 PreClick 脚本处理：

```lua
#showtooltip 地下堡行者的法缚以太之门
/stopcasting
/click [btn:2]rhpB 2;[btn:3]rhpB 3;rhpB
```

### PreClick 动态路由 | PreClick Dynamic Routing

`/click` 命令的修饰键条件（如 `[mod:shift]`）**不会**将修饰键状态传递给 SecureActionButton。本插件通过在 PreClick 脚本中实时检测 `IsShiftKeyDown()`/`IsControlKeyDown()`/`IsAltKeyDown()` 并动态设置 `type`/`toy`/`item` 属性来正确路由。

*WoW's /click command modifier conditions do not propagate to SecureActionButton attributes. This addon uses a PreClick script that checks IsShiftKeyDown/IsControlKeyDown/IsAltKeyDown at click time to dynamically set the correct action.*

### 保存变量 | Saved Variables

- **变量名：** `rhpDB`
- **修饰键绑定：** `rhpDB.settings.modBinds[修饰键][按键编号]` = `nil` / `"item:XXXXX"` / `ItemID数字`
- **玩具状态：** `rhpDB.L.tList[ItemID]` = `{ name, icon, status }`

---

## 致谢 | Credits

- **原始插件：** [RandomHearthstone](https://github.com/JamienAU/RandomHearthstone) by JamienAU
- **Random Hearthstone Plus：** David W Zhang

## License

与原版 RandomHearthstone 使用相同许可条款。

*Same terms as the original RandomHearthstone addon.*
