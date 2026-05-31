<div align="center">

<img src="https://img.shields.io/badge/version-3.0-blueviolet?style=for-the-badge&logo=roblox" alt="version">
<img src="https://img.shields.io/badge/platform-Roblox-red?style=for-the-badge&logo=roblox" alt="platform">
<img src="https://img.shields.io/badge/language-Lua-blue?style=for-the-badge" alt="language">
<img src="https://img.shields.io/badge/license-MIT-green?style=for-the-badge" alt="license">

# syft.wtf UI Library

**A sleek, dark Roblox executor GUI library.**  
Toggles · Sliders · Dropdowns · Keybinds · Textboxes · Minimap · Config saving · Toast notifications

</div>

---

## ✨ Features

- 🎨 **Fully themeable** — change accent color at runtime, updates every element live
- 📦 **Tabbed sidebar** with icon support, categories, and sub-tabs (General / Game / Misc etc.)
- 🗺️ **Minimap** with player tracking, headshots, zoom control, and smooth rotation
- 💾 **Config system** — save/load all toggle, slider, and dropdown states to JSON files
- 🔔 **Toast notifications** — slide in from top-right with progress bar, auto-dismiss
- ⌨️ **Keybind listener** — in-UI key capture widget, supports window toggle keybind
- 📐 **UIScale** — resize the entire window at runtime
- 🖱️ **Draggable** window and minimap
- ✅ **Multi-select dropdowns** — select multiple options, displays as comma-separated list

---

## 📦 Installation

```lua
local Syft = loadstring(game:HttpGet("YOUR_RAW_URL"))()
```
---

## 🚀 Quick Start

```lua
local Syft = loadstring(game:HttpGet("YOUR_RAW_URL"))()

-- Create the window
local Win = Syft:CreateWindow({
    Title  = "syft.wtf",   -- dot splits into accent color automatically
    Player = true,          -- auto-loads local player avatar & username
})

Win:SetKeyExpiry("6d 24h")

-- Sidebar categories
Win:AddCategory("GENERAL")

-- Add a tab with sub-tabs
local PlayerTab = Win:AddTab({
    Title       = "Local Player",
    Icon        = "rbxassetid://134558401488718",
    Description = "Modify your local character.",
    SubTabs     = {"General", "Game", "Misc"},
})

-- Add elements to a sub-tab
PlayerTab.General:AddToggle({
    Title       = "Speed Hack",
    Description = "Walk really fast",
    Default     = false,
    Callback    = function(enabled)
        -- your code here
    end,
})

PlayerTab.General:AddSlider({
    Title    = "Walk Speed",
    Min      = 0,
    Max      = 100,
    Default  = 16,
    Callback = function(value)
        game:GetService("Players").LocalPlayer.Character
            :FindFirstChildOfClass("Humanoid").WalkSpeed = value
    end,
})
```

---

## 🪟 Window API

### `Syft:CreateWindow(cfg)`

Creates and returns the main window. Call this once at the top of your script.

| Property | Type | Default | Description |
|---|---|---|---|
| `Title` | `string` | `"syft.wtf"` | Window title. If it contains a `.`, the part after it is accent-colored |
| `Player` | `boolean` | `true` | Auto-loads local player avatar and username in the footer |
| `Map` | `boolean` | `false` | Show the minimap on startup |
| `ToggleKey` | `Enum.KeyCode` | `RightShift` | Key to show/hide the window |

```lua
local Win = Syft:CreateWindow({
    Title     = "syft.wtf",
    Player    = true,
    Map       = false,
    ToggleKey = Enum.KeyCode.RightShift,
})
```

---

### Window Methods

| Method | Description |
|---|---|
| `Win:AddCategory(title)` | Adds a muted uppercase label in the sidebar nav |
| `Win:AddTab(cfg)` | Adds a sidebar tab — returns a tab object |
| `Win:SetAccentColor(Color3)` | Changes the accent color globally and live-updates all elements |
| `Win:SetKeyExpiry(text)` | Sets the key expiry text in the footer (e.g. `"6d 24h"`) |
| `Win:SetUIScale(number)` | Scales the entire window. Range: `0.6` – `1.5` (i.e. 60–150%) |
| `Win:SetToggleKey(Enum.KeyCode)` | Changes the window show/hide hotkey |
| `Win:SetMapVisible(bool)` | Shows or hides the minimap |
| `Win:Toast(cfg)` | Fires a toast notification |
| `Win:SaveConfig(name)` | Saves all registered element states to `SyftLib/<title>/<name>.json` |
| `Win:LoadConfig(name)` | Loads and applies a saved config by name |
| `Win:ListConfigs()` | Returns a table of saved config names (strings) |
| `Win:Destroy()` | Completely removes all GUIs from CoreGui and cleans up |

---

### `Win:AddTab(cfg)`

| Property | Type | Required | Description |
|---|---|---|---|
| `Title` | `string` | ✅ | Tab name shown in the sidebar |
| `Icon` | `string` | ❌ | Roblox asset ID for the nav icon |
| `Description` | `string` | ❌ | Subtitle shown in the content header |
| `SubTabs` | `table` | ❌ | List of sub-tab names. Default: `{"General","Game","Misc"}` |

```lua
local MyTab = Win:AddTab({
    Title       = "Visuals",
    Icon        = "rbxassetid://121383615519345",
    Description = "ESP, highlights and drawings.",
    SubTabs     = {"General", "ESP", "Misc"},
})

-- Access sub-tabs by name:
MyTab.General:AddToggle({ ... })
MyTab.ESP:AddSlider({ ... })
```

---

### `Win:Toast(cfg)`

Slides in from the top-right with a progress bar that drains over `Duration` seconds, then slides back out.

| Property | Type | Default | Description |
|---|---|---|---|
| `Title` | `string` | `"Notification"` | Bold heading |
| `Message` | `string` | `""` | Sub-text body |
| `Duration` | `number` | `4` | Seconds before auto-dismiss |

```lua
Win:Toast({
    Title    = "Config Saved",
    Message  = "my_config.json written.",
    Duration = 3,
})
```

---

## 🧩 Element API

All elements are added via a sub-tab reference:

```lua
MyTab.General:AddToggle(...)
MyTab.General:AddSlider(...)
MyTab.General:AddButton(...)
MyTab.General:AddDropdown(...)
MyTab.General:AddTextbox(...)
MyTab.General:AddKeybind(...)
MyTab.General:AddDivider(...)
MyTab.General:AddSection("Label")
```

---

### Toggle

```lua
local toggle = MyTab.General:AddToggle({
    Title       = "Feature Name",
    Description = "What it does",
    Default     = false,
    Callback    = function(enabled)
        print("Toggle is now:", enabled)
    end,
})

-- Programmatic control:
toggle:SetValue(true)
toggle:GetValue()  -- returns bool
```

> ✅ Saved and loaded by the config system automatically.

---

### Slider

```lua
local slider = MyTab.General:AddSlider({
    Title       = "Walk Speed",
    Description = "Player movement speed",
    Min         = 0,
    Max         = 100,
    Default     = 16,
    Callback    = function(value)
        print("Value:", value)
    end,
})

slider:SetValue(50)
slider:GetValue()  -- returns number
```

> ✅ Saved and loaded by the config system automatically.

---

### Button

```lua
MyTab.General:AddButton({
    Title       = "Reset Character",
    Description = "Respawns your character",
    Icon        = "rbxassetid://82449380459412",  -- optional
    Callback    = function()
        -- fires on click
    end,
})
```

> ⚠️ Buttons are **not** saved by the config system (no state to save).

---

### Dropdown

Single-select and multi-select modes are both supported.

**Single select:**
```lua
local dd = MyTab.General:AddDropdown({
    Title       = "Team",
    Description = "Choose your team",
    Options     = {"Red", "Blue", "Green"},
    Default     = "Red",
    Callback    = function(selected)
        print("Selected:", selected)  -- returns string
    end,
})

dd:SetValue("Blue")
dd:GetValue()  -- returns string
```

**Multi-select** (`SelectMode = true`):
```lua
local dd = MyTab.General:AddDropdown({
    Title      = "Abilities",
    Options    = {"Speed", "Jump", "Fly", "Noclip"},
    Default    = {"Speed"},   -- table of pre-selected options
    SelectMode = true,
    Callback   = function(selected)
        -- selected is a table: { Speed=true, Jump=false, ... }
        if selected.Speed then print("Speed enabled") end
    end,
})

dd:GetValue()  -- returns { OptionName = bool, ... }
```

> The pill button shows selected values as a comma-separated list: `Speed, Jump`  
> A **Done** button closes the list when you're finished selecting.  
> ✅ Saved and loaded by the config system automatically.

---

### Textbox

```lua
local box = MyTab.General:AddTextbox({
    Title         = "Player Name",
    Description   = "Search for a player",
    Placeholder   = "Enter name...",
    Default       = "",
    ClearOnFocus  = false,
    Callback      = function(text, pressedEnter)
        print("Input:", text, "| Enter pressed:", pressedEnter)
    end,
})

box:SetValue("Builderman")
box:GetValue()  -- returns string
```

> Callback fires when the textbox loses focus. `pressedEnter` is `true` if the user pressed Enter.

---

### Keybind

```lua
local kb = MyTab.General:AddKeybind({
    Title        = "Toggle ESP",
    Description  = "Click to rebind",
    Default      = Enum.KeyCode.F,
    IsToggleKey  = false,  -- set true to also update Win._keybind
    Callback     = function(newKey)
        print("Bound to:", newKey)
    end,
})

kb:GetValue()      -- returns Enum.KeyCode
kb:SetValue(Enum.KeyCode.G)
```

> Clicking the pill enters **listening mode** — it pulses accent and shows `...` until a key is pressed.  
> Set `IsToggleKey = true` to make this keybind control the window show/hide hotkey.

---

### Divider

```lua
-- Plain horizontal line:
MyTab.General:AddDivider()

-- Line with centered label:
MyTab.General:AddDivider({ Title = "Advanced Settings" })
```

---

### Section Label

```lua
MyTab.General:AddSection("Combat")
```

> Renders a small muted uppercase label above the next element. No lines, just text.

---

## 🗺️ Minimap

The minimap is a draggable overlay that tracks all players within a configurable stud radius.

```lua
-- Toggle visibility
Win:SetMapVisible(true)
Win:SetMapVisible(false)

-- Change zoom (stud radius)
Win._mapRadius = 250   -- default is 130

-- In a slider callback:
MyTab.UI:AddSlider({
    Title    = "Map Zoom",
    Min      = 20,
    Max      = 700,
    Default  = 130,
    Callback = function(v) Win._mapRadius = v end,
})
```

**What the minimap shows:**
- Your position as a glowing directional arrow that follows your camera look direction
- Nearby players with their headshot, display name, and distance in metres
- A grid overlay on a dark rounded background

---

## 💾 Config System

Configs are saved as JSON files at `SyftLib/<title>/<name>.json` using the executor's `writefile` / `readfile` / `listfiles` functions.

**What gets saved:** every Toggle, Slider, and Dropdown value.  
**What doesn't:** Buttons (no state), Textboxes (intentional).

```lua
-- Save current state
Win:SaveConfig("pvp_preset")

-- Load a config by name
Win:LoadConfig("pvp_preset")

-- Get a list of saved config names
local configs = Win:ListConfigs()
-- returns: {"pvp_preset", "farm_preset", ...}
```

**Example Config tab setup:**

```lua
local ConfigTab = Win:AddTab({
    Title   = "Config",
    SubTabs = {"Configs"},
})

local nameBox = ConfigTab.Configs:AddTextbox({
    Title       = "Config Name",
    Placeholder = "my_config",
})

ConfigTab.Configs:AddButton({
    Title    = "Save",
    Callback = function()
        Win:SaveConfig(nameBox:GetValue())
    end,
})

local savedDrop = ConfigTab.Configs:AddDropdown({
    Title   = "Saved Configs",
    Options = Win:ListConfigs(),
})

ConfigTab.Configs:AddButton({
    Title    = "Load",
    Callback = function()
        Win:LoadConfig(savedDrop:GetValue())
    end,
})
```

---

## 🎨 Theming

```lua
-- Change accent color (updates all elements live, no restart needed)
Win:SetAccentColor(Color3.fromRGB(110, 112, 182))  -- purple (default)
Win:SetAccentColor(Color3.fromRGB(200, 60,  60))   -- red
Win:SetAccentColor(Color3.fromRGB(60,  190, 100))  -- green
Win:SetAccentColor(Color3.fromRGB(60,  180, 200))  -- cyan
Win:SetAccentColor(Color3.fromRGB(210, 130, 50))   -- orange
Win:SetAccentColor(Color3.fromRGB(200, 80,  160))  -- pink
```

The following elements update immediately on color change:
- Toggle pill and dot (when ON)
- Slider fill and value label
- Sub-tab underline indicator
- Active nav icon
- Minimap arrow and flash
- Minimap player rings
- Scrollbar color
- Toast progress bar and left accent bar
- Glow behind the window

---

## 📐 UI Scale

```lua
-- Via method (clamped to 60%–150%):
Win:SetUIScale(1.0)   -- 100% (default)
Win:SetUIScale(0.8)   -- 80%
Win:SetUIScale(1.25)  -- 125%

-- Via textbox in your UI (recommended):
MyTab.UI:AddTextbox({
    Title       = "UI Scale",
    Placeholder = "100",
    Default     = "100",
    Callback    = function(text)
        local n = tonumber(text)
        if n then Win:SetUIScale(math.clamp(n, 60, 150) / 100) end
    end,
})
```

---

## 🔑 Window Toggle Keybind

```lua
-- Set via CreateWindow:
local Win = Syft:CreateWindow({
    Title     = "syft.wtf",
    ToggleKey = Enum.KeyCode.RightShift,
})

-- Change at runtime:
Win:SetToggleKey(Enum.KeyCode.Insert)

-- Or via a Keybind element with IsToggleKey = true:
MyTab.UI:AddKeybind({
    Title       = "Toggle UI",
    Default     = Enum.KeyCode.RightShift,
    IsToggleKey = true,
    Callback    = function(key)
        Win:Toast({ Title = "Keybind updated", Message = tostring(key):gsub("Enum.KeyCode.","") })
    end,
})
```

---

## 🗑️ Unloading

```lua
Win:Destroy()
```

Removes all three ScreenGuis (`SyftLib`, `SyftToasts`, `SyftMap`) from CoreGui, disconnects the minimap render loop, and clears all internal registries so Lua's garbage collector can reclaim everything.

---

## 📋 Full Example

```lua
local Syft = loadstring(game:HttpGet("YOUR_RAW_URL"))()

local Win = Syft:CreateWindow({ Title = "syft.wtf", Player = true })
Win:SetKeyExpiry("6d 24h")
Win:Toast({ Title = "Loaded", Message = "Welcome back.", Duration = 3 })

Win:AddCategory("GENERAL")

local Tab = Win:AddTab({
    Title    = "Local Player",
    Icon     = "rbxassetid://134558401488718",
    SubTabs  = {"General", "Game"},
})

Tab.General:AddDivider({ Title = "Movement" })

Tab.General:AddSlider({
    Title    = "Walk Speed",
    Min      = 0, Max = 100, Default = 16,
    Callback = function(v)
        local char = game:GetService("Players").LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = v end
        end
    end,
})

Tab.General:AddToggle({
    Title    = "Infinite Jump",
    Default  = false,
    Callback = function(v)
        game:GetService("UserInputService").JumpRequest:Connect(function()
            if not v then return end
            local char = game:GetService("Players").LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end)
    end,
})

Tab.General:AddDropdown({
    Title   = "Game Mode",
    Options = {"PvP", "PvE", "Farming"},
    Default = "PvP",
    Callback = function(v)
        Win:Toast({ Title = "Mode changed", Message = v, Duration = 2 })
    end,
})

Win:AddCategory("UI SETTINGS")

local UITab = Win:AddTab({
    Title   = "Settings",
    SubTabs = {"UI"},
})

UITab.UI:AddToggle({
    Title    = "Minimap",
    Default  = false,
    Callback = function(v) Win:SetMapVisible(v) end,
})

UITab.UI:AddSlider({
    Title    = "Map Zoom",
    Min      = 20, Max = 700, Default = 130,
    Callback = function(v) Win._mapRadius = v end,
})

UITab.UI:AddDropdown({
    Title   = "Accent Color",
    Options = {"Purple","Red","Green","Cyan","Orange","Pink"},
    Default = "Purple",
    Callback = function(v)
        local colors = {
            Purple=Color3.fromRGB(110,112,182), Red=Color3.fromRGB(200,60,60),
            Green=Color3.fromRGB(60,190,100),   Cyan=Color3.fromRGB(60,180,200),
            Orange=Color3.fromRGB(210,130,50),  Pink=Color3.fromRGB(200,80,160),
        }
        if colors[v] then Win:SetAccentColor(colors[v]) end
    end,
})
```

---

## 📁 File Structure

```
SyftLib/
├── SyftLib.lua          ← the library
├── SyftLib_Example.lua  ← full working example script
└── README.md            ← this file

Saved configs (written by executor):
SyftLib/
└── syft_wtf/
    ├── pvp_preset.json
    └── farm_preset.json
```

---

## ⚠️ Requirements

- A Roblox script executor with `loadstring`, `writefile`, `readfile`, `listfiles`, and `makefolder` support
- `game:HttpGet` enabled

---

<div align="center">

Made with 🖤 by **syft.wtf**

</div>
