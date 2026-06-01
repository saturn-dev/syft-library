local Syft = loadstring(game:HttpGet("https://raw.githubusercontent.com/saturn-dev/syft-library/refs/heads/main/main/syft.lua"))()

local Win = Syft:CreateWindow({ Title = "syft.wtf", Player = true })
Win:SetKeyExpiry("6d 24h")
Win:Toast({ Title = "syft.wtf", Message = "loaded", Duration = 3 })

Win:AddCategory("SHOWCASE")

local Tab = Win:AddTab({
	Title = "Elements", Icon = "rbxassetid://134558401488718",
	Description = "every element in the library", SubTabs = {"Toggles","Sliders","Misc"},
})
local DropTab = Win:AddTab({
	Title = "Dropdowns", Icon = "rbxassetid://121383615519345",
	Description = "single and multi select", SubTabs = {"Single","Multi"},
})

Win:AddCategory("UI SETTINGS")

local ConfigTab = Win:AddTab({
	Title = "Config", Icon = "rbxassetid://122182529860786",
	Description = "save and load your settings", SubTabs = {"Configs"},
})
local UITab = Win:AddTab({
	Title = "Customize", Icon = "rbxassetid://114478374631627",
	Description = "make it look how u want", SubTabs = {"UI","Misc"},
})

Tab.Toggles:AddDivider({ Title = "Toggles" })

Tab.Toggles:AddToggle({
	Title = "Toggle",
	Description = "basic on/off toggle",
	Default = false,
	Callback = function(v)
		print("toggle:", v)
	end,
})

Tab.Toggles:AddToggle({
	Title = "Toggle on by default",
	Description = "starts enabled",
	Default = true,
	Callback = function(v)
		print("toggle2:", v)
	end,
})

Tab.Toggles:AddDivider({ Title = "Buttons" })

Tab.Toggles:AddButton({
	Title = "Button",
	Description = "click to fire callback",
	Callback = function()
		print("button clicked")
	end,
})

Tab.Toggles:AddButton({
	Title = "Button with icon",
	Description = "same thing but with an icon",
	Icon = "rbxassetid://82449380459412",
	Callback = function()
		print("button with icon clicked")
	end,
})

Tab.Sliders:AddDivider({ Title = "Sliders" })

Tab.Sliders:AddSlider({
	Title = "Slider",
	Description = "drag it left and right",
	Min = 0,
	Max = 100,
	Default = 50,
	Callback = function(v)
		print("slider:", v)
	end,
})

Tab.Sliders:AddSlider({
	Title = "Slider with small range",
	Description = "1 to 10",
	Min = 1,
	Max = 10,
	Default = 5,
	Callback = function(v)
		print("slider2:", v)
	end,
})

Tab.Sliders:AddDivider({ Title = "Textboxes" })

Tab.Sliders:AddTextbox({
	Title = "Textbox",
	Description = "type something in",
	Placeholder = "type here...",
	Default = "",
	Callback = function(text, pressedEnter)
		print("textbox:", text, "| enter:", pressedEnter)
	end,
})

Tab.Sliders:AddTextbox({
	Title = "Textbox with default",
	Description = "starts with a value",
	Placeholder = "...",
	Default = "hello",
	Callback = function(text)
		print("textbox2:", text)
	end,
})

Tab.Misc:AddDivider({ Title = "Keybinds" })

Tab.Misc:AddKeybind({
	Title = "Keybind",
	Description = "click the pill to rebind",
	Default = Enum.KeyCode.F,
	Callback = function(key)
		print("keybind set to:", key)
	end,
})

Tab.Misc:AddDivider({ Title = "Dividers" })

Tab.Misc:AddDivider()

Tab.Misc:AddDivider({ Title = "labeled divider" })

Tab.Misc:AddDivider()

Tab.Misc:AddButton({
	Title = "Toast",
	Description = "fires a notification",
	Callback = function()
		Win:Toast({ Title = "Toast", Message = "this is what a toast looks like", Duration = 3 })
	end,
})

DropTab.Single:AddDivider({ Title = "Single Select" })

DropTab.Single:AddDropdown({
	Title = "Dropdown",
	Description = "pick one option",
	Options = {"Option A", "Option B", "Option C", "Option D"},
	Default = "Option A",
	Callback = function(v)
		print("dropdown:", v)
	end,
})

DropTab.Single:AddDropdown({
	Title = "Dropdown long list",
	Description = "scrolls when there are more than 6",
	Options = {"one", "two", "three", "four", "five", "six", "seven", "eight"},
	Default = "one",
	Callback = function(v)
		print("long dropdown:", v)
	end,
})

DropTab.Multi:AddDivider({ Title = "Multi Select" })

DropTab.Multi:AddDropdown({
	Title = "Multi select",
	Description = "pick as many as u want",
	Options = {"Red", "Green", "Blue", "Yellow"},
	Default = "Red",
	SelectMode = true,
	Callback = function(v)
		local picked = {}
		for name, state in pairs(v) do
			if state then table.insert(picked, name) end
		end
		print("multi select:", table.concat(picked, ", "))
	end,
})

local _cfgNameBox
local _savedDropdown

local function _refreshList()
	local configs = Win:ListConfigs()
	if #configs == 0 then configs = {"(none)"} end
	if _savedDropdown then _savedDropdown:SetOptions(configs) end
end

ConfigTab.Configs:AddDivider({ Title = "Save" })

_cfgNameBox = ConfigTab.Configs:AddTextbox({
	Title = "Config name",
	Description = "name it whatever",
	Placeholder = "my_config",
	Default = "",
})

ConfigTab.Configs:AddButton({
	Title = "Save",
	Description = "writes to file",
	Callback = function()
		local name = _cfgNameBox:GetValue()
		if name == "" then
			Win:Toast({ Title = "no name entered", Message = "type a name first", Duration = 2 })
			return
		end
		local ok, err = Win:SaveConfig(name)
		if ok then
			Win:Toast({ Title = "saved", Message = name .. ".json", Duration = 3 })
			_refreshList()
		else
			Win:Toast({ Title = "save failed", Message = tostring(err), Duration = 4 })
		end
	end,
})

ConfigTab.Configs:AddDivider({ Title = "Load" })

local initConfigs = Win:ListConfigs()
if #initConfigs == 0 then initConfigs = {"(none)"} end

_savedDropdown = ConfigTab.Configs:AddDropdown({
	Title = "Saved configs",
	Description = "pick one to load",
	Options = initConfigs,
	Default = initConfigs[1],
})

ConfigTab.Configs:AddButton({
	Title = "Load",
	Description = "applies selected config",
	Callback = function()
		local name = _savedDropdown:GetValue()
		if name == "" or name == "(none)" then
			Win:Toast({ Title = "nothing selected", Message = "save a config first", Duration = 2 })
			return
		end
		local ok, err = Win:LoadConfig(name)
		if ok then
			Win:Toast({ Title = "loaded", Message = name .. " applied", Duration = 3 })
		else
			Win:Toast({ Title = "load failed", Message = tostring(err), Duration = 4 })
		end
	end,
})

ConfigTab.Configs:AddDivider()

ConfigTab.Configs:AddButton({
	Title = "Refresh list",
	Description = "rescans saved configs",
	Callback = function()
		_refreshList()
		local n = #Win:ListConfigs()
		if n == 0 then
			Win:Toast({ Title = "nothing found", Message = "save one first", Duration = 2 })
		else
			Win:Toast({ Title = "refreshed", Message = n .. " config(s)", Duration = 2 })
		end
	end,
})

UITab.UI:AddToggle({
	Title = "Minimap",
	Description = "shows a radar of nearby players",
	Default = false,
	Callback = function(v) Win:SetMapVisible(v) end,
})

UITab.UI:AddSlider({
	Title = "Map zoom",
	Description = "how many studs the radar covers",
	Min = 20, Max = 700, Default = 130,
	Callback = function(v) Win._mapRadius = v end,
})

UITab.UI:AddDropdown({
	Title = "Accent color",
	Description = "changes the ui color",
	Options = {"Purple", "Red", "Green", "Cyan", "Orange", "Pink"},
	Default = "Purple",
	Callback = function(v)
		local colors = {
			Purple = Color3.fromRGB(110, 112, 182),
			Red    = Color3.fromRGB(200, 60,  60),
			Green  = Color3.fromRGB(60,  190, 100),
			Cyan   = Color3.fromRGB(60,  180, 200),
			Orange = Color3.fromRGB(210, 130, 50),
			Pink   = Color3.fromRGB(200, 80,  160),
		}
		if colors[v] then
			Win:SetAccentColor(colors[v])
			Win:Toast({ Title = "theme", Message = v, Duration = 2 })
		end
	end,
})

UITab.UI:AddTextbox({
	Title = "UI scale",
	Description = "60 to 150",
	Placeholder = "100",
	Default = "100",
	Callback = function(text)
		local n = tonumber(text)
		if n then Win:SetUIScale(math.clamp(n, 60, 150) / 100) end
	end,
})

UITab.UI:AddKeybind({
	Title = "Toggle keybind",
	Description = "show/hide the window",
	Default = Enum.KeyCode.RightShift,
	IsToggleKey = true,
	Callback = function(key)
		Win:Toast({ Title = "keybind", Message = tostring(key):gsub("Enum.KeyCode.", ""), Duration = 2 })
	end,
})

UITab.Misc:AddButton({
	Title = "Test toast",
	Description = "fire a notification",
	Callback = function()
		Win:Toast({ Title = "test", Message = "this is a toast", Duration = 3 })
	end,
})

UITab.Misc:AddDivider({ Title = "Danger Zone" })

UITab.Misc:AddButton({
	Title = "Unload",
	Description = "removes the gui completely",
	Icon = "rbxassetid://88930748781568",
	Callback = function()
		Win:Toast({ Title = "unloading", Message = "bye", Duration = 2 })
		task.delay(0.5, function() Win:Destroy() end)
	end,
})
