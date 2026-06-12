# Random Hearthstone Plus

Enhanced version of [Random Hearthstone](https://github.com/JamienAU/RandomHearthstone) by JamienAU.

Adds teleport toy support, modifier key bindings (Shift/Ctrl/Alt + click combinations), and full WoW 12.0+ API compatibility.

## Features

- **Random Hearthstone Toys** — On each left-click, randomly selects one of your enabled hearthstone toys to use. Never cast the same one twice in a row.
- **Teleport Toy Support** — Includes teleport toys (e.g. Delver's Warp Gate, Private Key of the Arcanum) in the random rotation alongside hearthstone toys.
- **Modifier Key Bindings** — 3×3 grid: bind any toy, item, or hearthstone to **Shift/Ctrl/Alt + Left/Right/Middle Click** via per-binding dropdowns.
- **Right-Click: Dalaran Hearthstone** — Option to cast Dalaran Hearthstone (`item:140192`) on right-click.
- **Middle-Click: Garrison Hearthstone** — Option to cast Garrison Hearthstone (`item:110560`) on middle-click.
- **Macro Icon Override** — Choose any toy's icon (or the default Hearthstone icon) as your macro's display icon. Defaults to random rotation.
- **Covenant Awareness** — Detects covenant-locked hearthstones and optionally restricts to only your active covenant's toy.
- **Draenei Check** — Draenic Hologem restricted to Draenei/Lightforged Draenei races.
- **Druid Friendly** — Automatically inserts `/cancelform` in macros for druid players.
- **Multi-Locale** — English (`enUS`/`enGB`) and Simplified Chinese (`zhCN`) localization included.
- **Settings Persistence** — All toy selections and options persist across sessions via `rhpDB` saved variable.

## Installation

1. Download the latest version from [Releases](https://github.com/davidchangok/RandomHearthPlus/releases) or clone this repository.
2. Place the `RandomHeathPlus` folder inside your WoW `Interface/AddOns/` directory:
   ```
   World of Warcraft\_retail_\Interface\AddOns\RandomHeathPlus\
       RandomHearthPlus.toc
       RandomHearthPlus.lua
       LocalisationPlus.lua
   ```
3. Restart WoW or reload your UI (`/reload`).

## Usage

### Quick Start

1. Type `/rhp` to open the options panel.
2. Ensure your desired hearthstone and teleport toys are checked.
3. Create or locate a macro using `/macro` — the addon auto-creates one named **"Random Hearth"**.
4. Drag the macro to your action bar and click it!

### Modifier Key Bindings

In the options panel, scroll to **Modifier Key Bindings**. For each combination of modifier (`Shift`, `Ctrl`, `Alt`) and mouse button (`Left`, `Right`, `Middle`), choose a binding:

| Option | Behavior |
|--------|----------|
| **Random** | Falls through to default behavior (random toy on left-click, Dalaran/Garrison on right/middle if enabled) |
| **Hearthstone** | Uses the standard Hearthstone (`item:6948`) |
| **Dalaran Hearthstone** | Uses Dalaran Hearthstone (`item:140192`) |
| **Garrison Hearthstone** | Uses Garrison Hearthstone (`item:110560`) |
| **Any Toy** | Uses the selected toy directly — bypasses random rotation |

The macro's click-condition logic routes each modifier+button combination to the SecureActionButton with the configured action.

### Options Panel Reference (`/rhp`)

| Setting | Description |
|---------|-------------|
| Toy checkboxes | Enable/disable individual toys from the random rotation |
| Select All / Deselect All | Bulk toggle all toys |
| Allow current Covenant only | Restrict covenant hearthstones to your active covenant |
| Dalaran Hearth on right-click | Right-click the macro → Dalaran Hearthstone |
| Garrison Hearth on middle-click | Middle-click the macro → Garrison Hearthstone |
| Macro icon | Choose the icon shown on the macro |
| Macro name | Customize the auto-created macro's name |

## Toy Database

### Hearthstone Toys

| Item ID | Name |
|---------|------|
| 184353 | Kyrian Hearthstone |
| 183716 | Venthyr Sinstone |
| 180290 | Night Fae Hearthstone |
| 182773 | Necrolord Hearthstone |
| 54452 | Ethereal Portal |
| 64488 | The Innkeeper's Daughter |
| 93672 | Dark Portal |
| 142542 | Tome of Town Portal |
| 162973 | Greatfather Winter's Hearthstone |
| 163045 | Headless Horseman's Hearthstone |
| 165669 | Lunar Elder's Hearthstone |
| 165670 | Peddlefeet's Lovely Hearthstone |
| 165802 | Noble Gardener's Hearthstone |
| 166746 | Fire Eater's Hearthstone |
| 166747 | Brewfest Reveler's Hearthstone |
| 168907 | Holographic Digitalization Hearthstone |
| 172179 | Eternal Traveler's Hearthstone |
| 193588 | Timewalker's Hearthstone |
| 188952 | Dominated Hearthstone |
| 200630 | Ohn'ir Windsage's Hearthstone |
| 190237 | Broker Translocation Matrix |
| 190196 | Enlightened Hearthstone |
| 209035 | Hearthstone of the Flame |
| 208704 | Deepdweller's Earthen Hearthstone |
| 206195 | Path of the Naaru |
| 212337 | Stone of the Hearth |
| 210455 | Draenic Hologem |
| 228940 | Notorious Thread's Hearthstone |
| 235016 | Redeployment Module |
| 236687 | Explosive Hearthstone |
| 245970 | P.O.S.T Master's Express Hearthstone |
| 246565 | Cosmic Hearthstone |
| 263489 | Naaru's Enfold |
| 257736 | Lightcalled Hearthstone |
| 265100 | Corewarden's Hearthstone |
| 263933 | Preyseeker's Hearthstone |

### Teleport Toys

| Item ID | Name |
|---------|------|
| 253629 | Private Key of the Arcanum |
| 243056 | Delver's Ethereal Warp Gate |
| 230850 | Delver's Robot 7001 |

## Adding New Toys

If Blizzard adds a new hearthstone or teleport toy and the addon hasn't been updated yet, you can add it yourself:

1. Find the ItemID from the item's Wowhead page URL (e.g. `https://www.wowhead.com/item=123456` → ID is `123456`).
2. Open `RandomHearthPlus.lua` and add the ID to the `rhToys` list near the top of the file.
3. Reload your UI (`/reload`).

```lua
local rhToys = {
    -- Hearthstone Toys
    184353, -- Kyrian Hearthstone
    ...
    -- Teleport Toys
    123456, -- Your New Toy  <-- add here
}
```

## Slash Commands

| Command | Action |
|---------|--------|
| `/rhp` | Open the options panel |

## Localization

Currently supported locales:

- `enUS` / `enGB` — English (default)
- `zhCN` — Simplified Chinese

To add a new locale, edit `LocalisationPlus.lua` and add a new locale block following the `zhCN` pattern.

## Credits

- **Original addon:** [RandomHearthstone](https://github.com/JamienAU/RandomHearthstone) by JamienAU
- **Random Hearthstone Plus:** David W Zhang

## License

This project is released under the same terms as the original RandomHearthstone addon.
