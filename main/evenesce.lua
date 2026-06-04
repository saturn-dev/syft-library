-- EVENESCE UI Library
-- Matches your existing design language: dark BG, red accent, fluent sidebar, subtabs, search
-- Features: Window, Sidebar Nav, SubTabs, Toggle, Slider, Button, Dropdown, Textbox, Keybind, ColorPicker, Divider, Section, Toast, Search

local TS  = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local PL  = game:GetService("Players")
local RS  = game:GetService("RunService")
local LP  = PL.LocalPlayer

-- ══════════════════════════════════════════════════
-- THEME
-- ══════════════════════════════════════════════════
local T = {
	BG      = Color3.fromRGB(17, 16, 21),   -- outer window
	SIDEBAR = Color3.fromRGB(13, 13, 17),   -- sidebar panel
	PANEL   = Color3.fromRGB(22, 22, 28),   -- content area
	ITEM    = Color3.fromRGB(27, 27, 34),   -- row background
	ITEM_H  = Color3.fromRGB(32, 32, 41),   -- row hover
	TOPBAR  = Color3.fromRGB(19, 19, 25),   -- topbar
	SEP     = Color3.fromRGB(35, 35, 45),   -- dividers / separators
	ACC     = Color3.fromRGB(220, 40,  40), -- red accent
	ACC_DIM = Color3.fromRGB(90,  18,  18), -- dimmed accent for pill bg
	TEXT    = Color3.fromRGB(200, 200, 202),
	MUTED   = Color3.fromRGB(65,  63,  76),
	PILL_ON = Color3.fromRGB(70,  18,  18), -- toggle pill on bg
}

local TQ  = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TQS = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TF  = TweenInfo.new(0)

-- ══════════════════════════════════════════════════
-- ACCENT REGISTRY  (for live recolor)
-- ══════════════════════════════════════════════════
local _accObjs   = {}
local _accBGObjs = {}
local _togRefs   = {}

local function regAcc(o, p)   table.insert(_accObjs,   {o=o, p=p}) end
local function regAccBG(o, p) table.insert(_accBGObjs, {o=o, p=p}) end
local function regTog(dot, pill, gs)
	table.insert(_togRefs, {dot=dot, pill=pill, gs=gs})
end

local function applyAcc(c)
	T.ACC     = c
	T.ACC_DIM = Color3.fromRGB(math.floor(c.R*255*0.38), math.floor(c.G*255*0.38), math.floor(c.B*255*0.38))
	T.PILL_ON = Color3.fromRGB(math.floor(c.R*255*0.32), math.floor(c.G*255*0.32), math.floor(c.B*255*0.32))
	local alive={}
	for _,r in ipairs(_accObjs) do
		if pcall(function() TS:Create(r.o, TF, {[r.p]=c}):Play() end) then table.insert(alive,r) end
	end
	_accObjs=alive
	local aliveB={}
	for _,r in ipairs(_accBGObjs) do
		if pcall(function() TS:Create(r.o, TF, {[r.p]=T.ACC_DIM}):Play() end) then table.insert(aliveB,r) end
	end
	_accBGObjs=aliveB
	local aliveT={}
	for _,r in ipairs(_togRefs) do
		if pcall(function()
			if r.gs() then
				TS:Create(r.dot,  TF, {BackgroundColor3=c}):Play()
				TS:Create(r.pill, TF, {BackgroundColor3=T.PILL_ON}):Play()
			end
		end) then table.insert(aliveT,r) end
	end
	_togRefs=aliveT
end

-- ══════════════════════════════════════════════════
-- HELPERS
-- ══════════════════════════════════════════════════
local function tw(o, ti, props) TS:Create(o, ti, props):Play() end

local function corner(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 6)
	c.Parent = p
	return c
end

local function newFrame(parent, props)
	local f = Instance.new("Frame")
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	for k,v in pairs(props or {}) do f[k]=v end
	f.Parent = parent
	return f
end

local function newLabel(parent, props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.BorderSizePixel = 0
	l.Font = Enum.Font.GothamMedium
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextTruncate = Enum.TextTruncate.AtEnd
	for k,v in pairs(props or {}) do l[k]=v end
	l.Parent = parent
	return l
end

local function newImg(parent, props)
	local i = Instance.new("ImageLabel")
	i.BackgroundTransparency = 1
	i.BorderSizePixel = 0
	for k,v in pairs(props or {}) do i[k]=v end
	i.Parent = parent
	return i
end

local function makeDraggable(frame, handle)
	handle = handle or frame
	local drag, dragInput, startPos, startMouse
	handle.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		drag = true
		startPos   = frame.Position
		startMouse = i.Position
		i.Changed:Connect(function()
			if i.UserInputState == Enum.UserInputState.End then drag = false end
		end)
	end)
	handle.InputChanged:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseMovement then dragInput = i end
	end)
	UIS.InputChanged:Connect(function(i)
		if drag and i == dragInput then
			local d = i.Position - startMouse
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y
			)
		end
	end)
end

-- ══════════════════════════════════════════════════
-- LIBRARY
-- ══════════════════════════════════════════════════
local Lib = {}
Lib.__index = Lib

function Lib:CreateWindow(cfg)
	cfg = cfg or {}
	local self  = setmetatable({}, Lib)
	self._tabs       = {}
	self._active     = nil
	self._keybind    = cfg.ToggleKey or Enum.KeyCode.RightShift
	self._keybindMouse = false
	self._scale      = 1
	self._configItems= {}
	self._toastCount = 0

	-- ── ScreenGuis ──────────────────────────────
	local ok, cg = pcall(function() return game:GetService("CoreGui") end)
	local guiParent = ok and cg or LP.PlayerGui

	local sg = Instance.new("ScreenGui")
	sg.Name = "EVENESCE"; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.ResetOnSpawn = false; sg.Parent = guiParent
	self._sg = sg

	local tsg = Instance.new("ScreenGui")
	tsg.Name = "EVENESCEToasts"; tsg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	tsg.ResetOnSpawn = false; tsg.Parent = guiParent
	self._tsg = tsg

	local toastHolder = newFrame(tsg, {
		AnchorPoint = Vector2.new(1,0),
		Position    = UDim2.new(1,-16,0,16),
		Size        = UDim2.new(0,300,1,-32),
	})
	local toastList = Instance.new("UIListLayout", toastHolder)
	toastList.SortOrder = Enum.SortOrder.LayoutOrder
	toastList.VerticalAlignment = Enum.VerticalAlignment.Top
	toastList.Padding = UDim.new(0,6)
	self._toastHolder = toastHolder

	-- ── Root window ────────────────────────────
	local root = Instance.new("Frame")
	root.Name = "Root"
	root.BackgroundColor3 = T.BG
	root.BorderSizePixel  = 0
	root.AnchorPoint = Vector2.new(0.5,0.5)
	root.Position    = UDim2.new(0.5,0,0.5,0)
	root.Size        = UDim2.new(0,841,0,531)
	root.ClipsDescendants = false
	root.Parent = sg
	corner(root, 14)

	local uiScale = Instance.new("UIScale")
	uiScale.Scale = 1; uiScale.Parent = root
	self._uiScale = uiScale

	-- glow behind window
	local glow = newImg(root, {
		AnchorPoint = Vector2.new(0.5,0.5),
		Position    = UDim2.new(0.5,0,0.5,0),
		Size        = UDim2.new(1.08,40,1.14,40),
		ZIndex      = 0,
		Image       = "rbxassetid://6014261993",
		ImageColor3 = T.ACC,
		ImageTransparency = 0.72,
		ScaleType   = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49,49,450,450),
	})
	self._glow = glow
	regAcc(glow, "ImageColor3")

	-- clip container
	local rootClip = Instance.new("Frame")
	rootClip.BackgroundColor3 = T.BG
	rootClip.BorderSizePixel  = 0
	rootClip.Size = UDim2.new(1,0,1,0)
	rootClip.ClipsDescendants = true
	rootClip.Parent = root
	corner(rootClip, 14)

	-- ── Sidebar ─────────────────────────────────
	local sidebar = Instance.new("Frame")
	sidebar.Name             = "Sidebar"
	sidebar.BackgroundColor3 = T.SIDEBAR
	sidebar.BorderSizePixel  = 0
	sidebar.Size             = UDim2.new(0,243,1,0)
	sidebar.ZIndex           = 2
	sidebar.Parent           = rootClip
	corner(sidebar, 14)

	-- right-patch to square off right corners of sidebar
	local sbPatch = Instance.new("Frame", sidebar)
	sbPatch.BackgroundColor3 = T.SIDEBAR
	sbPatch.BorderSizePixel  = 0
	sbPatch.Position = UDim2.new(1,-14,0,0)
	sbPatch.Size     = UDim2.new(0,14,1,0)
	sbPatch.ZIndex   = 2

	-- separator line
	local sbSep = Instance.new("Frame", sidebar)
	sbSep.BackgroundColor3 = T.SEP
	sbSep.BorderSizePixel  = 0
	sbSep.Position = UDim2.new(1,-1,0,0)
	sbSep.Size     = UDim2.new(0,1,1,0)
	sbSep.ZIndex   = 3

	-- ── Logo area ───────────────────────────────
	local logoArea = newFrame(sidebar, {
		Name   = "LogoArea",
		Size   = UDim2.new(1,0,0,70),
		ZIndex = 3,
	})

	local logoTitle = cfg.Title or "EVENESCE"
	local logoLbl = Instance.new("TextLabel", logoArea)
	logoLbl.BackgroundTransparency = 1
	logoLbl.BorderSizePixel = 0
	logoLbl.Position = UDim2.new(0,18,0,18)
	logoLbl.Size     = UDim2.new(1,-36,0,30)
	logoLbl.Font     = Enum.Font.GothamBold
	logoLbl.TextSize = 20
	logoLbl.RichText = true
	logoLbl.TextColor3 = T.TEXT
	logoLbl.TextXAlignment = Enum.TextXAlignment.Left
	logoLbl.ZIndex = 4
	logoLbl.Text   = logoTitle
	self._logoLbl  = logoLbl
	self._logoTitle= logoTitle

	-- underline bar with gradient
	local underlineFrame = Instance.new("Frame", logoArea)
	underlineFrame.BackgroundColor3 = Color3.fromRGB(232,232,232)
	underlineFrame.BorderSizePixel  = 0
	underlineFrame.Position = UDim2.new(0,18,0,54)
	underlineFrame.Size     = UDim2.new(0,144,0,2)
	underlineFrame.ZIndex   = 4
	local underGrad = Instance.new("UIGradient", underlineFrame)
	underGrad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0,    T.SIDEBAR),
		ColorSequenceKeypoint.new(0.08, T.SIDEBAR),
		ColorSequenceKeypoint.new(0.48, T.ACC),
		ColorSequenceKeypoint.new(0.92, T.SIDEBAR),
		ColorSequenceKeypoint.new(1,    T.SIDEBAR),
	}
	self._underGrad = underGrad

	local logoSep = Instance.new("Frame", sidebar)
	logoSep.BackgroundColor3 = T.SEP
	logoSep.BorderSizePixel  = 0
	logoSep.Position = UDim2.new(0,0,0,70)
	logoSep.Size     = UDim2.new(1,0,0,1)
	logoSep.ZIndex   = 3

	-- ── Nav scroll ──────────────────────────────
	local navScroll = Instance.new("ScrollingFrame", sidebar)
	navScroll.BackgroundTransparency = 1
	navScroll.BorderSizePixel = 0
	navScroll.Position = UDim2.new(0,0,0,72)
	navScroll.Size     = UDim2.new(1,0,1,-130)
	navScroll.CanvasSize = UDim2.new(0,0,0,0)
	navScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	navScroll.ScrollBarThickness = 0
	navScroll.ZIndex = 3
	self._navScroll = navScroll

	local navList = Instance.new("UIListLayout", navScroll)
	navList.SortOrder = Enum.SortOrder.LayoutOrder

	local navPad = Instance.new("UIPadding", navScroll)
	navPad.PaddingLeft  = UDim.new(0,10)
	navPad.PaddingRight = UDim.new(0,10)
	navPad.PaddingTop   = UDim.new(0,8)

	-- ── Footer (username + close) ────────────────
	local footer = Instance.new("Frame", sidebar)
	footer.BackgroundColor3 = T.SIDEBAR
	footer.BorderSizePixel  = 0
	footer.AnchorPoint = Vector2.new(0,1)
	footer.Position    = UDim2.new(0,0,1,0)
	footer.Size        = UDim2.new(1,0,0,58)
	footer.ZIndex      = 3

	local footLine = Instance.new("Frame", footer)
	footLine.BackgroundColor3 = T.SEP
	footLine.BorderSizePixel  = 0
	footLine.Size = UDim2.new(1,0,0,1)
	footLine.ZIndex = 4

	local uAvatar = Instance.new("ImageLabel", footer)
	uAvatar.BackgroundColor3 = T.SEP
	uAvatar.BorderSizePixel  = 0
	uAvatar.Position = UDim2.new(0,12,0,10)
	uAvatar.Size     = UDim2.new(0,36,0,36)
	uAvatar.Image    = "rbxassetid://18469380757"
	uAvatar.ZIndex   = 4
	corner(uAvatar, 50)
	self._uAvatar = uAvatar

	local uName = newLabel(footer, {
		Position  = UDim2.new(0,56,0,8),
		Size      = UDim2.new(0,120,0,20),
		Text      = "@"..LP.Name,
		TextColor3= T.TEXT,
		TextSize  = 13,
		Font      = Enum.Font.GothamBold,
		ZIndex    = 4,
	})

	local uKey = newLabel(footer, {
		Position  = UDim2.new(0,56,0,28),
		Size      = UDim2.new(0,120,0,16),
		Text      = "Key Exp: --",
		TextColor3= T.MUTED,
		TextSize  = 11,
		ZIndex    = 4,
	})
	self._uKey = uKey

	local closeBtn = Instance.new("ImageButton", footer)
	closeBtn.BackgroundTransparency = 1
	closeBtn.BorderSizePixel = 0
	closeBtn.AnchorPoint = Vector2.new(1,0.5)
	closeBtn.Position    = UDim2.new(1,-12,0.5,0)
	closeBtn.Size        = UDim2.new(0,20,0,20)
	closeBtn.Image       = "rbxassetid://88930748781568"
	closeBtn.ImageColor3 = T.MUTED
	closeBtn.ZIndex      = 4
	closeBtn.MouseEnter:Connect(function() tw(closeBtn, TQ, {ImageColor3=T.TEXT}) end)
	closeBtn.MouseLeave:Connect(function() tw(closeBtn, TQ, {ImageColor3=T.MUTED}) end)
	closeBtn.MouseButton1Click:Connect(function() sg.Enabled = false end)

	-- Load avatar
	if cfg.Player ~= false then
		task.spawn(function()
			local ok2, img = pcall(function()
				return PL:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
			end)
			if ok2 and img then uAvatar.Image = img end
		end)
	end

	-- ── Content area ────────────────────────────
	local content = Instance.new("Frame", rootClip)
	content.Name             = "Content"
	content.BackgroundColor3 = T.PANEL
	content.BorderSizePixel  = 0
	content.Position = UDim2.new(0,244,0,0)
	content.Size     = UDim2.new(1,-244,1,0)
	content.ZIndex   = 1
	content.ClipsDescendants = false
	corner(content, 14)

	-- left-patch to square off left corners of content
	local cPatch = Instance.new("Frame", content)
	cPatch.BackgroundColor3 = T.PANEL
	cPatch.BorderSizePixel  = 0
	cPatch.Size = UDim2.new(0,14,1,0)
	cPatch.ZIndex = 1

	-- ── Topbar ──────────────────────────────────
	local topbar = Instance.new("Frame", content)
	topbar.Name             = "Topbar"
	topbar.BackgroundColor3 = T.TOPBAR
	topbar.BackgroundTransparency = 0
	topbar.BorderSizePixel  = 0
	topbar.Size   = UDim2.new(1,0,0,50)
	topbar.ZIndex = 4
	corner(topbar, 14)
	-- square bottom corners
	local topPatch = Instance.new("Frame", topbar)
	topPatch.BackgroundColor3 = T.TOPBAR
	topPatch.BorderSizePixel  = 0
	topPatch.Position = UDim2.new(0,0,0.5,0)
	topPatch.Size     = UDim2.new(1,0,0.5,0)
	topPatch.ZIndex   = 3

	local topSep = Instance.new("Frame", content)
	topSep.BackgroundColor3 = T.SEP
	topSep.BorderSizePixel  = 0
	topSep.Position = UDim2.new(0,0,0,50)
	topSep.Size     = UDim2.new(1,0,0,1)
	topSep.ZIndex   = 4

	-- settings icon (left of search)
	local settingsBtn = Instance.new("TextButton", topbar)
	settingsBtn.BackgroundColor3 = T.ITEM
	settingsBtn.BorderSizePixel  = 0
	settingsBtn.Position = UDim2.new(0,12,0.5,-15)
	settingsBtn.Size     = UDim2.new(0,30,0,30)
	settingsBtn.Text     = ""; settingsBtn.AutoButtonColor = false
	settingsBtn.ZIndex   = 5
	corner(settingsBtn, 8)
	local settingsImg = newImg(settingsBtn, {
		AnchorPoint = Vector2.new(0.5,0.5),
		Position    = UDim2.new(0.5,0,0.5,0),
		Size        = UDim2.new(0,18,0,18),
		Image       = "rbxassetid://129551114477965",
		ImageColor3 = T.MUTED,
		ZIndex      = 6,
	})
	settingsBtn.MouseEnter:Connect(function()
		tw(settingsBtn, TQ, {BackgroundColor3=T.ITEM_H})
		tw(settingsImg, TQ, {ImageColor3=T.TEXT})
	end)
	settingsBtn.MouseLeave:Connect(function()
		tw(settingsBtn, TQ, {BackgroundColor3=T.ITEM})
		tw(settingsImg, TQ, {ImageColor3=T.MUTED})
	end)

	-- Search container
	local searchBg = Instance.new("Frame", topbar)
	searchBg.BackgroundColor3 = T.ITEM
	searchBg.BorderSizePixel  = 0
	searchBg.Position = UDim2.new(0,50,0.5,-15)
	searchBg.Size     = UDim2.new(1,-90,0,30)
	searchBg.ZIndex   = 5
	corner(searchBg, 8)

	local searchIcon = newImg(searchBg, {
		Position = UDim2.new(0,8,0.5,-8),
		Size     = UDim2.new(0,16,0,16),
		Image    = "rbxassetid://135303032443857",
		ImageColor3 = T.MUTED,
		ZIndex   = 6,
	})

	local searchBox = Instance.new("TextBox", searchBg)
	searchBox.BackgroundTransparency = 1
	searchBox.BorderSizePixel = 0
	searchBox.Position = UDim2.new(0,30,0,0)
	searchBox.Size     = UDim2.new(1,-38,1,0)
	searchBox.Font     = Enum.Font.GothamMedium
	searchBox.TextSize = 13
	searchBox.TextColor3      = T.TEXT
	searchBox.PlaceholderColor3 = T.MUTED
	searchBox.PlaceholderText = "Search type..."
	searchBox.Text    = ""
	searchBox.ZIndex  = 7
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.ClearTextOnFocus = false
	self._searchBox = searchBox

	-- clear search button (×)
	local clearBtn = Instance.new("TextButton", searchBg)
	clearBtn.BackgroundTransparency = 1
	clearBtn.BorderSizePixel = 0
	clearBtn.AnchorPoint = Vector2.new(1,0.5)
	clearBtn.Position    = UDim2.new(1,-6,0.5,0)
	clearBtn.Size        = UDim2.new(0,18,0,18)
	clearBtn.Text        = "×"
	clearBtn.Font        = Enum.Font.GothamBold
	clearBtn.TextSize    = 16
	clearBtn.TextColor3  = T.MUTED
	clearBtn.AutoButtonColor = false
	clearBtn.ZIndex      = 7
	clearBtn.Visible     = false
	clearBtn.MouseButton1Click:Connect(function()
		searchBox.Text = ""
		clearBtn.Visible = false
		self:_ApplySearch("")
	end)

	-- grip icon (right side)
	local gripImg = newImg(topbar, {
		AnchorPoint = Vector2.new(1,0.5),
		Position    = UDim2.new(1,-12,0.5,0),
		Size        = UDim2.new(0,26,0,26),
		Image       = "rbxassetid://132741033476143",
		ImageColor3 = T.MUTED,
		ZIndex      = 5,
	})
	corner(gripImg, 8)

	makeDraggable(root, topbar)

	-- ── SubTab bar ──────────────────────────────
	local stBarBg = Instance.new("Frame", content)
	stBarBg.Name             = "SubTabBg"
	stBarBg.BackgroundColor3 = T.TOPBAR
	stBarBg.BorderSizePixel  = 0
	stBarBg.Position = UDim2.new(0,0,0,51)
	stBarBg.Size     = UDim2.new(1,0,0,42)
	stBarBg.ZIndex   = 3

	local stBarSep = Instance.new("Frame", content)
	stBarSep.BackgroundColor3 = T.SEP
	stBarSep.BorderSizePixel  = 0
	stBarSep.Position = UDim2.new(0,0,0,93)
	stBarSep.Size     = UDim2.new(1,0,0,1)
	stBarSep.ZIndex   = 4

	local stBar = newFrame(stBarBg, {
		Name     = "SubTabBar",
		Size     = UDim2.new(1,-14,1,0),
		Position = UDim2.new(0,14,0,0),
		ZIndex   = 4,
	})
	local stList = Instance.new("UIListLayout", stBar)
	stList.FillDirection = Enum.FillDirection.Horizontal
	stList.SortOrder = Enum.SortOrder.LayoutOrder
	self._stBar = stBar

	-- ── Tab content holder ───────────────────────
	local tabHolder = newFrame(content, {
		Name     = "TabHolder",
		Position = UDim2.new(0,0,0,94),
		Size     = UDim2.new(1,0,1,-94),
		ZIndex   = 1,
		ClipsDescendants = false,
	})
	self._tabHolder = tabHolder

	-- ── Search results overlay ───────────────────
	local searchOverlay = newFrame(content, {
		Name     = "SearchOverlay",
		Position = UDim2.new(0,0,0,94),
		Size     = UDim2.new(1,0,1,-94),
		ZIndex   = 10,
		Visible  = false,
	})
	local searchScroll = Instance.new("ScrollingFrame", searchOverlay)
	searchScroll.BackgroundTransparency = 1
	searchScroll.BorderSizePixel = 0
	searchScroll.Position = UDim2.new(0.01,0,0.008,0)
	searchScroll.Size     = UDim2.new(0.98,0,0.984,0)
	searchScroll.CanvasSize = UDim2.new(0,0,0,0)
	searchScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	searchScroll.ScrollBarThickness = 4
	searchScroll.ScrollBarImageColor3 = T.ACC
	searchScroll.BottomImage = "rbxassetid://136554681557134"
	searchScroll.MidImage    = "rbxassetid://100883556759005"
	searchScroll.TopImage    = "rbxassetid://97290610170116"
	searchScroll.ZIndex = 11
	regAcc(searchScroll, "ScrollBarImageColor3")
	do
		local l=Instance.new("UIListLayout",searchScroll)
		l.SortOrder=Enum.SortOrder.LayoutOrder; l.Padding=UDim.new(0,6)
		local p=Instance.new("UIPadding",searchScroll)
		p.PaddingLeft=UDim.new(0,12); p.PaddingRight=UDim.new(0,16)
		p.PaddingTop=UDim.new(0,10); p.PaddingBottom=UDim.new(0,10)
	end
	self._searchOverlay = searchOverlay
	self._searchScroll  = searchScroll
	self._searchItems   = {} -- {title, frame, cloneFunc}

	-- Search logic
	searchBox.Changed:Connect(function(prop)
		if prop ~= "Text" then return end
		local q = searchBox.Text
		clearBtn.Visible = q ~= ""
		self:_ApplySearch(q)
	end)

	-- ── Toggle keybind ───────────────────────────
	self._keybindIsMouse = false
	UIS.InputBegan:Connect(function(i, gp)
		local hit = false
		if self._keybindIsMouse then
			hit = (i.UserInputType == self._keybind)
		else
			if gp then return end
			hit = (i.KeyCode == self._keybind)
		end
		if hit then sg.Enabled = not sg.Enabled end
	end)

	return self
end

-- ══════════════════════════════════════════════════
-- SEARCH IMPLEMENTATION
-- ══════════════════════════════════════════════════
function Lib:_regSearchItem(title, cloneFunc)
	table.insert(self._searchItems, {title=title:lower(), label=title, clone=cloneFunc})
end

function Lib:_ApplySearch(q)
	q = q:lower():match("^%s*(.-)%s*$")
	if q == "" then
		self._searchOverlay.Visible = false
		self._tabHolder.Visible = true
		self._stBar.Visible = true
		return
	end
	self._searchOverlay.Visible = true
	self._tabHolder.Visible = false
	self._stBar.Visible = false

	-- clear old results
	for _, c in ipairs(self._searchScroll:GetChildren()) do
		if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
			c:Destroy()
		end
	end

	local found = 0
	for _, item in ipairs(self._searchItems) do
		if item.title:find(q, 1, true) then
			local clone = item.clone()
			if clone then
				clone.Parent = self._searchScroll
				clone.LayoutOrder = found
				found = found + 1
			end
		end
	end

	if found == 0 then
		local noResult = Instance.new("TextLabel", self._searchScroll)
		noResult.BackgroundTransparency = 1
		noResult.BorderSizePixel = 0
		noResult.Size = UDim2.new(1,0,0,50)
		noResult.Font = Enum.Font.GothamMedium
		noResult.TextSize = 14
		noResult.TextColor3 = T.MUTED
		noResult.Text = "No results for \""..searchBox.Text.."\""
		noResult.TextXAlignment = Enum.TextXAlignment.Center
		noResult.ZIndex = 12
	end
end

-- ══════════════════════════════════════════════════
-- TOAST
-- ══════════════════════════════════════════════════
function Lib:Toast(cfg)
	cfg = cfg or {}
	self._toastCount = self._toastCount + 1
	local dur = cfg.Duration or 4
	local icon = cfg.Icon

	local toast = Instance.new("Frame", self._toastHolder)
	toast.Name = "Toast_"..self._toastCount
	toast.BackgroundColor3 = Color3.fromRGB(20,20,26)
	toast.BorderSizePixel  = 0
	toast.Size        = UDim2.new(1,0,0,0)
	toast.LayoutOrder = self._toastCount
	toast.ClipsDescendants = true
	corner(toast, 10)

	-- accent left bar
	local bar = Instance.new("Frame", toast)
	bar.BackgroundColor3 = T.ACC
	bar.BorderSizePixel  = 0
	bar.Size = UDim2.new(0,3,1,0)
	bar.ZIndex = 2
	corner(bar, 3)
	regAcc(bar, "BackgroundColor3")

	-- icon (optional)
	local textOffX = 16
	if icon then
		local ic = newImg(toast, {
			Position = UDim2.new(0,14,0,14),
			Size     = UDim2.new(0,24,0,24),
			Image    = icon,
			ImageColor3 = T.ACC,
			ZIndex   = 3,
		})
		regAcc(ic, "ImageColor3")
		textOffX = 46
	end

	newLabel(toast, {
		Position  = UDim2.new(0,textOffX,0,10),
		Size      = UDim2.new(1,-textOffX-10,0,20),
		Text      = cfg.Title or "Notification",
		TextColor3= T.TEXT,
		TextSize  = 14,
		Font      = Enum.Font.GothamBold,
		ZIndex    = 3,
	})
	newLabel(toast, {
		Position  = UDim2.new(0,textOffX,0,30),
		Size      = UDim2.new(1,-textOffX-10,0,18),
		Text      = cfg.Message or "",
		TextColor3= T.MUTED,
		TextSize  = 12,
		ZIndex    = 3,
	})

	-- progress bar
	local prog = Instance.new("Frame", toast)
	prog.BackgroundColor3 = T.SEP
	prog.BorderSizePixel  = 0
	prog.AnchorPoint = Vector2.new(0,1)
	prog.Position    = UDim2.new(0,0,1,0)
	prog.Size        = UDim2.new(1,0,0,3)
	prog.ZIndex      = 3
	local progFill = Instance.new("Frame", prog)
	progFill.BackgroundColor3 = T.ACC
	progFill.BorderSizePixel  = 0
	progFill.Size   = UDim2.new(1,0,1,0)
	progFill.ZIndex = 4
	corner(progFill, 2)
	regAcc(progFill, "BackgroundColor3")

	-- slide in from right
	toast.Position = UDim2.new(1,340,0,0)
	tw(toast, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size     = UDim2.new(1,0,0,58),
		Position = UDim2.new(0,0,0,0),
	})

	task.delay(0.4, function()
		tw(progFill, TweenInfo.new(dur, Enum.EasingStyle.Linear), {Size=UDim2.new(0,0,1,0)})
	end)

	task.delay(dur + 0.3, function()
		if not toast or not toast.Parent then return end
		tw(toast, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(1,340,0,0),
		})
		task.delay(0.25, function()
			if not toast or not toast.Parent then return end
			tw(toast, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size=UDim2.new(1,0,0,0)})
			task.delay(0.2, function() pcall(function() toast:Destroy() end) end)
		end)
	end)
end

-- ══════════════════════════════════════════════════
-- CATEGORY LABEL
-- ══════════════════════════════════════════════════
function Lib:AddCategory(title)
	local lbl = Instance.new("TextLabel", self._navScroll)
	lbl.BackgroundTransparency = 1
	lbl.BorderSizePixel = 0
	lbl.LayoutOrder = #self._tabs * 20
	lbl.Size = UDim2.new(1,0,0,22)
	lbl.Font = Enum.Font.GothamBold
	lbl.Text = title:upper()
	lbl.TextColor3 = T.MUTED
	lbl.TextSize = 10
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 3
	local p = Instance.new("UIPadding", lbl)
	p.PaddingTop  = UDim.new(0,8)
	p.PaddingLeft = UDim.new(0,4)
end

-- ══════════════════════════════════════════════════
-- ADD TAB
-- ══════════════════════════════════════════════════
function Lib:AddTab(cfg)
	cfg = cfg or {}
	local win = self
	local idx = #self._tabs + 1

	-- sidebar nav button
	local navBtn = Instance.new("TextButton", self._navScroll)
	navBtn.Name = "NavBtn_"..idx
	navBtn.BackgroundColor3 = T.ITEM
	navBtn.BackgroundTransparency = 1
	navBtn.BorderSizePixel  = 0
	navBtn.LayoutOrder = idx * 20 + 1
	navBtn.Size = UDim2.new(1,0,0,38)
	navBtn.Text = ""; navBtn.AutoButtonColor = false
	navBtn.ZIndex = 3
	corner(navBtn, 8)

	local navIcon = newImg(navBtn, {
		Position = UDim2.new(0,10,0.5,-10),
		Size     = UDim2.new(0,20,0,20),
		Image    = cfg.Icon or "",
		ImageColor3 = T.MUTED,
		ZIndex   = 4,
	})
	local navLbl = newLabel(navBtn, {
		Position  = UDim2.new(0,36,0,0),
		Size      = UDim2.new(1,-42,1,0),
		Text      = cfg.Title or "Tab",
		TextColor3= T.MUTED,
		TextSize  = 14,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex    = 4,
	})

	-- tab frame
	local tabFrame = newFrame(self._tabHolder, {
		Name   = "TabFrame_"..idx,
		Size   = UDim2.new(1,0,1,0),
		Visible= false,
		ClipsDescendants = false,
	})

	-- sub-tabs
	local subTabDefs = cfg.SubTabs or {"General"}
	local subTabs    = {}

	for i, stName in ipairs(subTabDefs) do
		local stFrame = newFrame(tabFrame, {
			Name   = "ST_"..stName,
			Size   = UDim2.new(1,0,1,0),
			Visible= false,
			ClipsDescendants = false,
		})

		local scroll = Instance.new("ScrollingFrame", stFrame)
		scroll.BackgroundTransparency = 1
		scroll.BorderSizePixel = 0
		scroll.Position = UDim2.new(0.01,0,0.008,0)
		scroll.Size     = UDim2.new(0.98,0,0.984,0)
		scroll.CanvasSize = UDim2.new(0,0,0,0)
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.ScrollBarThickness = 4
		scroll.ScrollBarImageColor3 = T.ACC
		scroll.BottomImage = "rbxassetid://136554681557134"
		scroll.MidImage    = "rbxassetid://100883556759005"
		scroll.TopImage    = "rbxassetid://97290610170116"
		scroll.ZIndex = 2
		regAcc(scroll, "ScrollBarImageColor3")

		do
			local l = Instance.new("UIListLayout", scroll)
			l.SortOrder = Enum.SortOrder.LayoutOrder
			l.Padding   = UDim.new(0,6)
			local p = Instance.new("UIPadding", scroll)
			p.PaddingLeft   = UDim.new(0,12)
			p.PaddingRight  = UDim.new(0,16)
			p.PaddingTop    = UDim.new(0,10)
			p.PaddingBottom = UDim.new(0,10)
		end

		local st = {_name=stName, _order=i, _frame=stFrame, _scroll=scroll, _itemCt=0}

		-- ── item hover helpers ─────────────────
		local function itemHover(frame)
			frame.MouseEnter:Connect(function() tw(frame, TQ, {BackgroundColor3=T.ITEM_H}) end)
			frame.MouseLeave:Connect(function() tw(frame, TQ, {BackgroundColor3=T.ITEM}) end)
		end

		-- ── SECTION ──────────────────────────────
		function st:AddSection(title)
			self._itemCt = self._itemCt + 1
			local lbl = Instance.new("TextLabel", self._scroll)
			lbl.BackgroundTransparency = 1
			lbl.BorderSizePixel = 0
			lbl.LayoutOrder = self._itemCt
			lbl.Size = UDim2.new(1,0,0,20)
			lbl.Font = Enum.Font.GothamBold
			lbl.Text = title:upper()
			lbl.TextColor3 = T.MUTED
			lbl.TextSize = 10
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.ZIndex = 3
			local p = Instance.new("UIPadding", lbl)
			p.PaddingTop = UDim.new(0,6)
		end

		-- ── DIVIDER ───────────────────────────────
		function st:AddDivider(c)
			c = c or {}
			self._itemCt = self._itemCt + 1
			local wrap = Instance.new("Frame", self._scroll)
			wrap.BackgroundTransparency = 1
			wrap.BorderSizePixel = 0
			wrap.LayoutOrder = self._itemCt
			wrap.ZIndex = 3

			if c.Title and c.Title ~= "" then
				wrap.Size = UDim2.new(1,0,0,28)
				local lineL = Instance.new("Frame", wrap)
				lineL.BackgroundColor3 = T.SEP; lineL.BorderSizePixel=0
				lineL.AnchorPoint = Vector2.new(0,0.5)
				lineL.Position = UDim2.new(0,0,0.5,0)
				lineL.Size     = UDim2.new(0.26,-6,0,1); lineL.ZIndex=3
				newLabel(wrap, {
					AnchorPoint    = Vector2.new(0.5,0.5),
					Position       = UDim2.new(0.5,0,0.5,0),
					Size           = UDim2.new(0.48,0,1,0),
					Text           = c.Title,
					TextColor3     = T.MUTED,
					TextSize       = 10,
					Font           = Enum.Font.GothamBold,
					TextXAlignment = Enum.TextXAlignment.Center,
					ZIndex         = 4,
				})
				local lineR = Instance.new("Frame", wrap)
				lineR.BackgroundColor3 = T.SEP; lineR.BorderSizePixel=0
				lineR.AnchorPoint = Vector2.new(1,0.5)
				lineR.Position = UDim2.new(1,0,0.5,0)
				lineR.Size     = UDim2.new(0.26,-6,0,1); lineR.ZIndex=3
			else
				wrap.Size = UDim2.new(1,0,0,14)
				local line = Instance.new("Frame", wrap)
				line.BackgroundColor3 = T.SEP; line.BorderSizePixel=0
				line.AnchorPoint = Vector2.new(0,0.5)
				line.Position = UDim2.new(0,0,0.5,0)
				line.Size     = UDim2.new(1,0,0,1); line.ZIndex=3
			end
		end

		-- ── TOGGLE ────────────────────────────────
		function st:AddToggle(c)
			c = c or {}
			self._itemCt = self._itemCt + 1
			local lo = self._itemCt

			local frame = Instance.new("Frame", self._scroll)
			frame.BackgroundColor3 = T.ITEM
			frame.BorderSizePixel  = 0
			frame.LayoutOrder = lo
			frame.Size  = UDim2.new(1,0,0,56)
			frame.ZIndex= 3
			corner(frame, 8)
			itemHover(frame)

			newLabel(frame, {
				Name      = "Title",
				Position  = UDim2.new(0,14,0,10),
				Size      = UDim2.new(0.62,0,0,22),
				Text      = c.Title or "Toggle",
				TextColor3= c.Default and T.TEXT or T.MUTED,
				TextSize  = 15,
				Font      = Enum.Font.GothamBold,
				ZIndex    = 4,
			})
			newLabel(frame, {
				Position  = UDim2.new(0,14,0,32),
				Size      = UDim2.new(0.72,0,0,16),
				Text      = c.Description or "",
				TextColor3= T.MUTED,
				TextSize  = 11,
				ZIndex    = 4,
			})

			local pill = Instance.new("TextButton", frame)
			pill.BackgroundColor3 = c.Default and T.PILL_ON or T.SEP
			pill.BorderSizePixel  = 0
			pill.AnchorPoint = Vector2.new(1,0.5)
			pill.Position    = UDim2.new(1,-14,0.5,0)
			pill.Size        = UDim2.new(0,50,0,24)
			pill.Text = ""; pill.AutoButtonColor = false
			pill.ZIndex = 5
			corner(pill, 50)

			local dot = Instance.new("Frame", pill)
			dot.BackgroundColor3 = c.Default and T.ACC or T.MUTED
			dot.BorderSizePixel  = 0
			dot.AnchorPoint = Vector2.new(0,0.5)
			dot.Position = c.Default and UDim2.new(1,-20,0.5,0) or UDim2.new(0,4,0.5,0)
			dot.Size     = UDim2.new(0,16,0,16)
			dot.ZIndex   = 6
			corner(dot, 50)

			local toggled = c.Default or false
			local titleLbl = frame:FindFirstChild("Title")

			local function setToggle(v)
				toggled = v
				local onPos  = UDim2.new(1,-20,0.5,0)
				local offPos = UDim2.new(0,4,0.5,0)
				tw(dot,  TQS, {Position = v and onPos or offPos, BackgroundColor3 = v and T.ACC or T.MUTED})
				tw(pill, TQS, {BackgroundColor3 = v and T.PILL_ON or T.SEP})
				if titleLbl then titleLbl.TextColor3 = v and T.TEXT or T.MUTED end
				if c.Callback then c.Callback(v) end
			end

			regTog(dot, pill, function() return toggled end)
			pill.Activated:Connect(function() setToggle(not toggled) end)

			local cfgKey = "toggle_"..stName.."_"..lo
			win:_regConfig(cfgKey, function() return toggled end, function(v) setToggle(v) end)

			-- register for search
			local function makeClone()
				local cl = frame:Clone(); cl.Parent = nil; return cl
			end
			win:_regSearchItem(c.Title or "Toggle", makeClone)

			return {
				SetValue = function(_, v) setToggle(v) end,
				GetValue = function()     return toggled end,
			}
		end

		-- ── SLIDER ────────────────────────────────
		function st:AddSlider(c)
			c = c or {}
			self._itemCt = self._itemCt + 1
			local lo = self._itemCt
			local minV = c.Min or 0
			local maxV = c.Max or 100
			local curV = math.clamp(c.Default or minV, minV, maxV)

			local frame = Instance.new("Frame", self._scroll)
			frame.BackgroundColor3 = T.ITEM
			frame.BorderSizePixel  = 0
			frame.LayoutOrder = lo
			frame.Size  = UDim2.new(1,0,0,64)
			frame.ZIndex= 3
			corner(frame, 8)
			itemHover(frame)

			newLabel(frame, {
				Position  = UDim2.new(0,14,0,10),
				Size      = UDim2.new(0.5,0,0,22),
				Text      = c.Title or "Slider",
				TextColor3= T.TEXT,
				TextSize  = 15,
				Font      = Enum.Font.GothamBold,
				ZIndex    = 4,
			})
			newLabel(frame, {
				Position  = UDim2.new(0,14,0,32),
				Size      = UDim2.new(0.5,0,0,16),
				Text      = c.Description or "",
				TextColor3= T.MUTED,
				TextSize  = 11,
				ZIndex    = 4,
			})

			local valLbl = newLabel(frame, {
				AnchorPoint    = Vector2.new(1,0),
				Position       = UDim2.new(1,-14,0,10),
				Size           = UDim2.new(0,55,0,22),
				Text           = tostring(curV),
				TextColor3     = T.ACC,
				TextSize       = 13,
				Font           = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex         = 5,
			})
			regAcc(valLbl, "TextColor3")

			local track = Instance.new("Frame", frame)
			track.BackgroundColor3 = T.SEP
			track.BorderSizePixel  = 0
			track.AnchorPoint = Vector2.new(1,0.5)
			track.Position    = UDim2.new(1,-14,0.72,0)
			track.Size        = UDim2.new(0,175,0,5)
			track.ZIndex      = 5
			corner(track, 3)

			local fill = Instance.new("Frame", track)
			fill.BackgroundColor3 = T.ACC
			fill.BorderSizePixel  = 0
			fill.Size   = UDim2.new((curV-minV)/(maxV-minV),0,1,0)
			fill.ZIndex = 6
			corner(fill, 3)
			regAcc(fill, "BackgroundColor3")

			local handle = Instance.new("Frame", track)
			handle.BackgroundColor3 = T.TEXT
			handle.BorderSizePixel  = 0
			handle.AnchorPoint = Vector2.new(0.5,0.5)
			handle.Size        = UDim2.new(0,11,0,11)
			handle.Position    = UDim2.new((curV-minV)/(maxV-minV),0,0.5,0)
			handle.ZIndex      = 7
			corner(handle, 50)

			local dragging = false
			local function updateFromX(x)
				local ap  = track.AbsolutePosition.X
				local as  = track.AbsoluteSize.X
				local pct = math.clamp((x-ap)/as, 0, 1)
				local v   = math.floor(minV + (maxV-minV)*pct)
				local ti2 = TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				tw(fill,   ti2, {Size=UDim2.new(pct,0,1,0)})
				tw(handle, ti2, {Position=UDim2.new(pct,0,0.5,0)})
				valLbl.Text = tostring(v); curV = v
				if c.Callback then c.Callback(v) end
			end

			track.InputBegan:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = true
					tw(handle, TQ, {Size=UDim2.new(0,14,0,14)})
					updateFromX(i.Position.X)
				end
			end)
			UIS.InputEnded:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
					dragging = false
					tw(handle, TQ, {Size=UDim2.new(0,11,0,11)})
				end
			end)
			UIS.InputChanged:Connect(function(i)
				if not dragging then return end
				if i.UserInputType == Enum.UserInputType.MouseMovement then
					updateFromX(i.Position.X)
				end
			end)

			local cfgKey = "slider_"..stName.."_"..lo
			win:_regConfig(cfgKey,
				function() return curV end,
				function(v)
					curV = math.clamp(v,minV,maxV)
					local p = (curV-minV)/(maxV-minV)
					fill.Size = UDim2.new(p,0,1,0)
					handle.Position = UDim2.new(p,0,0.5,0)
					valLbl.Text = tostring(curV)
					if c.Callback then c.Callback(curV) end
				end)

			win:_regSearchItem(c.Title or "Slider", function() return frame:Clone() end)

			return {
				SetValue = function(_, v)
					curV = math.clamp(v,minV,maxV)
					local p = (curV-minV)/(maxV-minV)
					fill.Size = UDim2.new(p,0,1,0)
					handle.Position = UDim2.new(p,0,0.5,0)
					valLbl.Text = tostring(curV)
				end,
				GetValue = function() return curV end,
			}
		end

		-- ── BUTTON ────────────────────────────────
		function st:AddButton(c)
			c = c or {}
			self._itemCt = self._itemCt + 1

			local btn = Instance.new("TextButton", self._scroll)
			btn.BackgroundColor3 = T.ITEM
			btn.BorderSizePixel  = 0
			btn.LayoutOrder = self._itemCt
			btn.Size = UDim2.new(1,0,0,56)
			btn.Text = ""; btn.AutoButtonColor = false
			btn.ZIndex = 3
			corner(btn, 8)

			newLabel(btn, {
				Position  = UDim2.new(0,14,0,10),
				Size      = UDim2.new(0.7,0,0,22),
				Text      = c.Title or "Button",
				TextColor3= T.TEXT,
				TextSize  = 15,
				Font      = Enum.Font.GothamBold,
				ZIndex    = 4,
			})
			newLabel(btn, {
				Position  = UDim2.new(0,14,0,32),
				Size      = UDim2.new(0.75,0,0,16),
				Text      = c.Description or "",
				TextColor3= T.MUTED,
				TextSize  = 11,
				ZIndex    = 4,
			})

			if c.Icon then
				newImg(btn, {
					AnchorPoint = Vector2.new(1,0.5),
					Position    = UDim2.new(1,-14,0.5,0),
					Size        = UDim2.new(0,22,0,22),
					Image       = c.Icon,
					ImageColor3 = T.MUTED,
					ZIndex      = 4,
				})
			else
				-- chevron arrow
				newImg(btn, {
					AnchorPoint = Vector2.new(1,0.5),
					Position    = UDim2.new(1,-12,0.5,0),
					Size        = UDim2.new(0,16,0,16),
					Image       = "rbxassetid://75251661334198",
					ImageColor3 = T.MUTED,
					Rotation    = -90,
					ZIndex      = 4,
				})
			end

			btn.MouseEnter:Connect(function()    tw(btn, TQ, {BackgroundColor3=T.ITEM_H}) end)
			btn.MouseLeave:Connect(function()    tw(btn, TQ, {BackgroundColor3=T.ITEM})   end)
			btn.MouseButton1Down:Connect(function() tw(btn, TweenInfo.new(0.06), {BackgroundColor3=T.SEP}) end)
			btn.MouseButton1Up:Connect(function()   tw(btn, TQ, {BackgroundColor3=T.ITEM_H})               end)
			btn.Activated:Connect(function() if c.Callback then c.Callback() end end)

			win:_regSearchItem(c.Title or "Button", function() return btn:Clone() end)

			return {Frame=btn}
		end

		-- ── DROPDOWN ─────────────────────────────
		function st:AddDropdown(c)
			c = c or {}
			self._itemCt = self._itemCt + 1
			local lo = self._itemCt
			local isMulti   = c.SelectMode == true
			local selected  = c.Default or (c.Options and c.Options[1]) or "Select"
			local multiSel  = {}
			if isMulti and type(c.Default) == "table" then
				for _,v in ipairs(c.Default) do multiSel[v]=true end
			elseif isMulti and type(c.Default) == "string" then
				multiSel[c.Default]=true
			end

			local frame = Instance.new("Frame", self._scroll)
			frame.BackgroundColor3 = T.ITEM
			frame.BorderSizePixel  = 0
			frame.LayoutOrder = lo
			frame.Size  = UDim2.new(1,0,0,56)
			frame.ZIndex= 3
			frame.ClipsDescendants = false
			corner(frame, 8)
			itemHover(frame)

			newLabel(frame, {
				Position  = UDim2.new(0,14,0,10),
				Size      = UDim2.new(0.5,0,0,22),
				Text      = c.Title or "Dropdown",
				TextColor3= T.TEXT,
				TextSize  = 15,
				Font      = Enum.Font.GothamBold,
				ZIndex    = 4,
			})
			newLabel(frame, {
				Position  = UDim2.new(0,14,0,32),
				Size      = UDim2.new(0.5,0,0,16),
				Text      = c.Description or "",
				TextColor3= T.MUTED,
				TextSize  = 11,
				ZIndex    = 4,
			})

			local function multiLabel()
				local p={}
				for _,opt in ipairs(c.Options or {}) do
					if multiSel[opt] then table.insert(p,opt) end
				end
				return #p>0 and table.concat(p,", ") or "None"
			end

			local dd = Instance.new("TextButton", frame)
			dd.BackgroundColor3 = T.SEP
			dd.BorderSizePixel  = 0
			dd.AnchorPoint = Vector2.new(1,0.5)
			dd.Position    = UDim2.new(1,-14,0.5,0)
			dd.Size        = UDim2.new(0,160,0,30)
			dd.Text = ""; dd.AutoButtonColor = false
			dd.ZIndex = 5
			corner(dd, 6)

			local selLbl = newLabel(dd, {
				Position  = UDim2.new(0,10,0,0),
				Size      = UDim2.new(1,-30,1,0),
				Text      = isMulti and multiLabel() or selected,
				TextColor3= T.TEXT,
				TextSize  = 12,
				Font      = Enum.Font.GothamMedium,
				ZIndex    = 6,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate   = Enum.TextTruncate.AtEnd,
			})

			local arrowImg = newImg(dd, {
				Name        = "DDArrow",
				AnchorPoint = Vector2.new(1,0.5),
				Position    = UDim2.new(1,-8,0.5,0),
				Size        = UDim2.new(0,13,0,13),
				Image       = "rbxassetid://75251661334198",
				ImageColor3 = T.MUTED,
				ZIndex      = 6,
			})

			local isOpen = false
			local optContainer = nil

			local function closeDD()
				if optContainer then
					local oc = optContainer; optContainer = nil
					tw(oc, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size=UDim2.new(0,160,0,0)})
					task.delay(0.15, function() pcall(function() oc:Destroy() end) end)
				end
				tw(arrowImg, TQ, {Rotation=0})
				isOpen = false
			end

			dd.Activated:Connect(function()
				if isOpen then closeDD(); return end
				isOpen = true
				tw(arrowImg, TQ, {Rotation=180})

				local opts    = c.Options or {}
				local optW    = 160
				local optRowH = 30

				optContainer = Instance.new("Frame", win._sg)
				optContainer.Name = "DDOpts"
				optContainer.BackgroundColor3 = Color3.fromRGB(20,20,28)
				optContainer.BorderSizePixel  = 0
				optContainer.Size = UDim2.new(0,optW,0,0)
				optContainer.ClipsDescendants = true
				optContainer.ZIndex = 9000
				corner(optContainer, 8)
				do
					local l = Instance.new("UIListLayout", optContainer)
					l.SortOrder = Enum.SortOrder.LayoutOrder
					local p = Instance.new("UIPadding", optContainer)
					p.PaddingTop=UDim.new(0,4); p.PaddingBottom=UDim.new(0,4)
					p.PaddingLeft=UDim.new(0,4); p.PaddingRight=UDim.new(0,4)
				end

				RS.RenderStepped:Wait()
				if not optContainer or not optContainer.Parent then return end
				local ap = dd.AbsolutePosition; local as = dd.AbsoluteSize
				local dropH = math.min(#opts*optRowH + (isMulti and 34 or 0) + 8, 6*optRowH+8)
				local vp = workspace.CurrentCamera.ViewportSize
				local yPos = (ap.Y+as.Y+dropH > vp.Y-10) and (ap.Y-dropH-2) or (ap.Y+as.Y+4)
				optContainer.Position = UDim2.new(0,ap.X,0,yPos)

				for i, opt in ipairs(opts) do
					local ob = Instance.new("TextButton", optContainer)
					local isSel = isMulti and multiSel[opt] or (not isMulti and opt==selected)
					ob.BackgroundColor3 = Color3.fromRGB(28,28,40)
					ob.BackgroundTransparency = isSel and 0.5 or 1
					ob.BorderSizePixel = 0
					ob.Size = UDim2.new(1,0,0,optRowH)
					ob.Text = ""; ob.AutoButtonColor=false; ob.ZIndex=9001; ob.LayoutOrder=i
					corner(ob, 4)

					local ol = newLabel(ob, {
						Position  = UDim2.new(0,10,0,0),
						Size      = UDim2.new(isMulti and 0.78 or 1,-10,1,0),
						Text      = opt,
						TextColor3= isSel and T.ACC or T.TEXT,
						TextSize  = 12,
						Font      = Enum.Font.GothamMedium,
						ZIndex    = 9002,
						TextYAlignment = Enum.TextYAlignment.Center,
					})

					local checkLbl
					if isMulti then
						checkLbl = newLabel(ob, {
							AnchorPoint    = Vector2.new(1,0.5),
							Position       = UDim2.new(1,-8,0.5,0),
							Size           = UDim2.new(0,16,0,16),
							Text           = multiSel[opt] and "✓" or "",
							TextColor3     = T.ACC,
							TextSize       = 13,
							Font           = Enum.Font.GothamBold,
							ZIndex         = 9003,
							TextXAlignment = Enum.TextXAlignment.Center,
						})
					end

					ob.MouseEnter:Connect(function()
						tw(ob, TQ, {BackgroundTransparency=0.4, BackgroundColor3=Color3.fromRGB(38,38,55)})
						tw(ol, TQ, {TextColor3=T.TEXT})
					end)
					ob.MouseLeave:Connect(function()
						local s2 = isMulti and multiSel[opt] or (not isMulti and opt==selected)
						tw(ob, TQ, {BackgroundTransparency=s2 and 0.5 or 1})
						tw(ol, TQ, {TextColor3=s2 and T.ACC or T.TEXT})
					end)
					ob.Activated:Connect(function()
						if isMulti then
							multiSel[opt] = not multiSel[opt]
							local s2 = multiSel[opt]
							ob.BackgroundTransparency = s2 and 0.5 or 1
							ol.TextColor3 = s2 and T.ACC or T.TEXT
							if checkLbl then checkLbl.Text = s2 and "✓" or "" end
							selLbl.Text = multiLabel()
							if c.Callback then c.Callback(multiSel) end
						else
							selected = opt; selLbl.Text = opt
							local oc = optContainer
							if oc then
								for _,ch in ipairs(oc:GetChildren()) do
									if ch:IsA("TextButton") then
										local chOl = ch:FindFirstChildOfClass("TextLabel")
										local cur = chOl and chOl.Text==opt
										ch.BackgroundTransparency = cur and 0.5 or 1
										if chOl then chOl.TextColor3 = cur and T.ACC or T.TEXT end
									end
								end
							end
							if c.Callback then c.Callback(opt) end
							closeDD()
						end
					end)
				end

				if isMulti then
					local doneBtn = Instance.new("TextButton", optContainer)
					doneBtn.BackgroundColor3 = T.ACC_DIM
					doneBtn.BorderSizePixel  = 0
					doneBtn.Size    = UDim2.new(1,0,0,28)
					doneBtn.Text    = "Done"
					doneBtn.Font    = Enum.Font.GothamBold
					doneBtn.TextSize= 12
					doneBtn.TextColor3 = T.ACC
					doneBtn.AutoButtonColor = false
					doneBtn.ZIndex  = 9001
					doneBtn.LayoutOrder = #opts+1
					corner(doneBtn, 4)
					doneBtn.MouseEnter:Connect(function() tw(doneBtn, TQ, {BackgroundColor3=T.ACC, TextColor3=T.PANEL}) end)
					doneBtn.MouseLeave:Connect(function() tw(doneBtn, TQ, {BackgroundColor3=T.ACC_DIM, TextColor3=T.ACC}) end)
					doneBtn.Activated:Connect(function() closeDD() end)
				end

				tw(optContainer, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					Size = UDim2.new(0,optW,0,math.min(#opts*optRowH+(isMulti and 34 or 0)+8,6*optRowH+8))
				})
			end)

			UIS.InputBegan:Connect(function(i)
				if not isOpen then return end
				if i.UserInputType == Enum.UserInputType.MouseButton1 then
					task.delay(0.05, function() if isOpen then closeDD() end end)
				end
			end)

			local cfgKey = "dropdown_"..stName.."_"..lo
			win:_regConfig(cfgKey,
				function() return isMulti and multiSel or selected end,
				function(v)
					if isMulti and type(v)=="table" then
						multiSel=v; selLbl.Text=multiLabel()
						if c.Callback then c.Callback(multiSel) end
					elseif not isMulti and type(v)=="string" then
						selected=v; selLbl.Text=v
						if c.Callback then c.Callback(selected) end
					end
				end)

			win:_regSearchItem(c.Title or "Dropdown", function() return frame:Clone() end)

			return {
				GetValue  = function() return isMulti and multiSel or selected end,
				SetValue  = function(_, v)
					if isMulti then
						if type(v)=="table" then multiSel=v end
						selLbl.Text=multiLabel()
					else selected=v; selLbl.Text=v end
				end,
				SetOptions= function(_, newOpts)
					c.Options = newOpts or {}
					local f = newOpts and newOpts[1] or ""
					selected = f; selLbl.Text = f
				end,
			}
		end

		-- ── TEXTBOX ───────────────────────────────
		function st:AddTextbox(c)
			c = c or {}
			self._itemCt = self._itemCt + 1

			local frame = Instance.new("Frame", self._scroll)
			frame.BackgroundColor3 = T.ITEM
			frame.BorderSizePixel  = 0
			frame.LayoutOrder = self._itemCt
			frame.Size  = UDim2.new(1,0,0,56)
			frame.ZIndex= 3
			corner(frame, 8)
			itemHover(frame)

			newLabel(frame, {
				Position  = UDim2.new(0,14,0,10),
				Size      = UDim2.new(0.5,0,0,22),
				Text      = c.Title or "Textbox",
				TextColor3= T.TEXT,
				TextSize  = 15,
				Font      = Enum.Font.GothamBold,
				ZIndex    = 4,
			})
			newLabel(frame, {
				Position  = UDim2.new(0,14,0,32),
				Size      = UDim2.new(0.5,0,0,16),
				Text      = c.Description or "",
				TextColor3= T.MUTED,
				TextSize  = 11,
				ZIndex    = 4,
			})

			local inputBg = Instance.new("Frame", frame)
			inputBg.BackgroundColor3 = T.SEP
			inputBg.BorderSizePixel  = 0
			inputBg.AnchorPoint = Vector2.new(1,0.5)
			inputBg.Position    = UDim2.new(1,-14,0.5,0)
			inputBg.Size        = UDim2.new(0,175,0,30)
			inputBg.ZIndex      = 5
			corner(inputBg, 6)

			local box = Instance.new("TextBox", inputBg)
			box.BackgroundTransparency = 1
			box.BorderSizePixel = 0
			box.Position = UDim2.new(0,10,0,0)
			box.Size     = UDim2.new(1,-20,1,0)
			box.Font     = Enum.Font.GothamMedium
			box.TextSize = 12
			box.TextColor3       = T.TEXT
			box.PlaceholderColor3= T.MUTED
			box.PlaceholderText  = c.Placeholder or "Type here..."
			box.Text    = c.Default or ""
			box.ClearTextOnFocus = c.ClearOnFocus or false
			box.ZIndex  = 6
			box.TextXAlignment = Enum.TextXAlignment.Left

			box.Focused:Connect(function()
				tw(inputBg, TQ, {BackgroundColor3=Color3.fromRGB(28,28,42)})
				local stroke = Instance.new("UIStroke", inputBg)
				stroke.Color = T.ACC; stroke.Thickness = 1
				stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				regAcc(stroke, "Color")
			end)
			box.FocusLost:Connect(function(enter)
				tw(inputBg, TQ, {BackgroundColor3=T.SEP})
				local stroke = inputBg:FindFirstChildOfClass("UIStroke")
				if stroke then stroke:Destroy() end
				if c.Callback then c.Callback(box.Text, enter) end
			end)

			win:_regSearchItem(c.Title or "Textbox", function() return frame:Clone() end)

			return {
				GetValue = function() return box.Text end,
				SetValue = function(_, v) box.Text = v end,
			}
		end

		-- ── KEYBIND ───────────────────────────────
		function st:AddKeybind(c)
			c = c or {}
			self._itemCt = self._itemCt + 1

			local frame = Instance.new("Frame", self._scroll)
			frame.BackgroundColor3 = T.ITEM
			frame.BorderSizePixel  = 0
			frame.LayoutOrder = self._itemCt
			frame.Size  = UDim2.new(1,0,0,56)
			frame.ZIndex= 3
			corner(frame, 8)
			itemHover(frame)

			newLabel(frame, {
				Position  = UDim2.new(0,14,0,10),
				Size      = UDim2.new(0.6,0,0,22),
				Text      = c.Title or "Keybind",
				TextColor3= T.TEXT,
				TextSize  = 15,
				Font      = Enum.Font.GothamBold,
				ZIndex    = 4,
			})
			newLabel(frame, {
				Position  = UDim2.new(0,14,0,32),
				Size      = UDim2.new(0.6,0,0,16),
				Text      = c.Description or "",
				TextColor3= T.MUTED,
				TextSize  = 11,
				ZIndex    = 4,
			})

			local curKey   = c.Default or Enum.KeyCode.Unknown
			local listening= false
			local mouseNames = {
				[Enum.UserInputType.MouseButton1] = "LMB",
				[Enum.UserInputType.MouseButton2] = "RMB",
				[Enum.UserInputType.MouseButton3] = "MMB",
			}
			pcall(function() mouseNames[Enum.UserInputType.MouseButton4]="Mouse4" end)
			pcall(function() mouseNames[Enum.UserInputType.MouseButton5]="Mouse5" end)

			local function bindName(k)
				if mouseNames[k] then return mouseNames[k] end
				return tostring(k):gsub("Enum%.KeyCode%.",""):gsub("Enum%.UserInputType%.","")
			end

			local keyBtn = Instance.new("TextButton", frame)
			keyBtn.BackgroundColor3 = T.SEP
			keyBtn.BorderSizePixel  = 0
			keyBtn.AnchorPoint = Vector2.new(1,0.5)
			keyBtn.Position    = UDim2.new(1,-14,0.5,0)
			keyBtn.Size        = UDim2.new(0,115,0,30)
			keyBtn.Font        = Enum.Font.GothamMedium
			keyBtn.TextSize    = 12
			keyBtn.AutoButtonColor = false
			keyBtn.TextColor3  = T.TEXT
			keyBtn.ZIndex      = 5
			keyBtn.Text        = bindName(curKey)
			corner(keyBtn, 6)

			local function applyBind(newKey, fromMouse)
				curKey=newKey; listening=false
				keyBtn.Text = bindName(newKey)
				tw(keyBtn, TQ, {BackgroundColor3=T.SEP})
				keyBtn.TextColor3 = T.TEXT
				if c.IsToggleKey and win then
					win._keybind = newKey
					win._keybindIsMouse = fromMouse
				end
				if c.Callback then c.Callback(newKey) end
			end

			local mouse = LP:GetMouse()

			keyBtn.MouseButton1Click:Connect(function()
				if listening then return end
				listening = true
				tw(keyBtn, TQ, {BackgroundColor3=T.PILL_ON})
				keyBtn.Text = "..."
				keyBtn.TextColor3 = T.ACC
			end)

			UIS.InputBegan:Connect(function(i, gp)
				if not listening then return end
				if i.UserInputType == Enum.UserInputType.Keyboard then
					if not gp then applyBind(i.KeyCode, false) end
				end
			end)
			if c.MouseBinds then
				mouse.Button1Up:Connect(function()
					if not listening then return end
					local pos = UIS:GetMouseLocation()
					local ap  = keyBtn.AbsolutePosition
					local as  = keyBtn.AbsoluteSize
					if not (pos.X>=ap.X and pos.X<=ap.X+as.X and pos.Y>=ap.Y and pos.Y<=ap.Y+as.Y) then
						applyBind(Enum.UserInputType.MouseButton1, true)
					end
				end)
				mouse.Button2Up:Connect(function()
					if not listening then return end
					applyBind(Enum.UserInputType.MouseButton2, true)
				end)
			end

			win:_regSearchItem(c.Title or "Keybind", function() return frame:Clone() end)

			local cfgKey = "keybind_"..stName.."_"..self._itemCt
			win:_regConfig(cfgKey,
				function()
					local mn=mouseNames[curKey]
					if mn then return "MOUSE:"..mn end
					return tostring(curKey):gsub("Enum%.KeyCode%.","")
				end,
				function(v)
					if type(v)=="string" and v:sub(1,6)=="MOUSE:" then
						local mname=v:sub(7)
						for uit,nm in pairs(mouseNames) do
							if nm==mname then
								curKey=uit; keyBtn.Text=nm
								if c.IsToggleKey and win then win._keybind=uit; win._keybindIsMouse=true end
								if c.Callback then c.Callback(uit) end; return
							end
						end
					else
						local ok2,k=pcall(function() return Enum.KeyCode[v] end)
						if ok2 and k then
							curKey=k; keyBtn.Text=bindName(k)
							if c.IsToggleKey and win then win._keybind=k end
							if c.Callback then c.Callback(k) end
						end
					end
				end)

			return {
				GetValue = function() return curKey end,
				SetValue = function(_, k) curKey=k; keyBtn.Text=bindName(k) end,
			}
		end

		-- ── COLOR PICKER ─────────────────────────
		function st:AddColorPicker(c)
			c = c or {}
			self._itemCt = self._itemCt + 1
			local curColor = c.Default or T.ACC

			local frame = Instance.new("Frame", self._scroll)
			frame.BackgroundColor3 = T.ITEM
			frame.BorderSizePixel  = 0
			frame.LayoutOrder = self._itemCt
			frame.Size  = UDim2.new(1,0,0,56)
			frame.ZIndex= 3
			corner(frame, 8)
			itemHover(frame)

			newLabel(frame, {
				Position  = UDim2.new(0,14,0,10),
				Size      = UDim2.new(0.6,0,0,22),
				Text      = c.Title or "Color",
				TextColor3= T.TEXT,
				TextSize  = 15,
				Font      = Enum.Font.GothamBold,
				ZIndex    = 4,
			})
			newLabel(frame, {
				Position  = UDim2.new(0,14,0,32),
				Size      = UDim2.new(0.6,0,0,16),
				Text      = c.Description or "",
				TextColor3= T.MUTED,
				TextSize  = 11,
				ZIndex    = 4,
			})

			local swatch = Instance.new("TextButton", frame)
			swatch.BackgroundColor3 = curColor
			swatch.BorderSizePixel  = 0
			swatch.AnchorPoint = Vector2.new(1,0.5)
			swatch.Position    = UDim2.new(1,-14,0.5,0)
			swatch.Size        = UDim2.new(0,38,0,26)
			swatch.Text = ""; swatch.AutoButtonColor = false
			swatch.ZIndex = 5
			corner(swatch, 6)
			local swStroke = Instance.new("UIStroke", swatch)
			swStroke.Color = Color3.fromRGB(50,50,62); swStroke.Thickness = 1

			local pickerFrame = nil

			local function buildPicker()
				if pickerFrame then
					pickerFrame:Destroy(); pickerFrame=nil; return
				end

				local sg = win._sg
				pickerFrame = Instance.new("Frame", sg)
				pickerFrame.BackgroundColor3 = Color3.fromRGB(18,18,24)
				pickerFrame.BorderSizePixel  = 0
				pickerFrame.ZIndex = 9500
				pickerFrame.Size   = UDim2.new(0,220,0,252)
				corner(pickerFrame, 10)
				do
					local stroke = Instance.new("UIStroke", pickerFrame)
					stroke.Color = Color3.fromRGB(44,44,58); stroke.Thickness = 1
				end

				RS.RenderStepped:Wait()
				if not pickerFrame or not pickerFrame.Parent then return end
				local ap = swatch.AbsolutePosition; local as = swatch.AbsoluteSize
				local vp = workspace.CurrentCamera.ViewportSize
				local px = math.clamp(ap.X+as.X-220, 0, vp.X-224)
				local py = (ap.Y+as.Y+256>vp.Y) and (ap.Y-256) or (ap.Y+as.Y+4)
				pickerFrame.Position = UDim2.new(0,px,0,py)

				local svSize = 182
				local h,s,v = Color3.toHSV(curColor)

				-- SV square
				local svFrame = Instance.new("Frame", pickerFrame)
				svFrame.BackgroundColor3 = Color3.fromHSV(h,1,1)
				svFrame.BorderSizePixel  = 0
				svFrame.Position = UDim2.new(0,10,0,10)
				svFrame.Size     = UDim2.new(0,svSize,0,svSize)
				svFrame.ZIndex   = 9501
				corner(svFrame, 4)

				local wGrad = Instance.new("UIGradient", svFrame)
				wGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
					ColorSequenceKeypoint.new(1, Color3.new(1,1,1)),
				})
				wGrad.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0,0),
					NumberSequenceKeypoint.new(1,1),
				})

				local svOver = Instance.new("Frame", svFrame)
				svOver.BackgroundColor3 = Color3.new(0,0,0)
				svOver.BorderSizePixel  = 0
				svOver.Size = UDim2.new(1,0,1,0)
				svOver.ZIndex = 9502
				corner(svOver, 4)
				local bGrad = Instance.new("UIGradient", svOver)
				bGrad.Color = ColorSequence.new(Color3.new(0,0,0))
				bGrad.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0,1),
					NumberSequenceKeypoint.new(1,0),
				})

				local svDot = Instance.new("Frame", svFrame)
				svDot.BackgroundColor3 = Color3.new(1,1,1)
				svDot.BorderSizePixel  = 0
				svDot.Size = UDim2.new(0,10,0,10)
				svDot.AnchorPoint = Vector2.new(0.5,0.5)
				svDot.Position = UDim2.new(s,0,1-v,0)
				svDot.ZIndex = 9506
				corner(svDot, 50)
				do local sk=Instance.new("UIStroke",svDot); sk.Color=Color3.new(0,0,0); sk.Thickness=1 end

				-- hue bar
				local hueTrack = Instance.new("Frame", pickerFrame)
				hueTrack.BackgroundColor3 = Color3.new(1,1,1)
				hueTrack.BorderSizePixel  = 0
				hueTrack.Position = UDim2.new(0,10,0,svSize+16)
				hueTrack.Size     = UDim2.new(0,svSize,0,11)
				hueTrack.ZIndex   = 9501
				corner(hueTrack, 6)
				local hueGrad = Instance.new("UIGradient", hueTrack)
				hueGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0,    Color3.fromHSV(0,1,1)),
					ColorSequenceKeypoint.new(1/6,  Color3.fromHSV(1/6,1,1)),
					ColorSequenceKeypoint.new(2/6,  Color3.fromHSV(2/6,1,1)),
					ColorSequenceKeypoint.new(3/6,  Color3.fromHSV(3/6,1,1)),
					ColorSequenceKeypoint.new(4/6,  Color3.fromHSV(4/6,1,1)),
					ColorSequenceKeypoint.new(5/6,  Color3.fromHSV(5/6,1,1)),
					ColorSequenceKeypoint.new(1,    Color3.fromHSV(1,1,1)),
				})

				local hDot = Instance.new("Frame", hueTrack)
				hDot.BackgroundColor3 = Color3.new(1,1,1)
				hDot.BorderSizePixel  = 0
				hDot.Size = UDim2.new(0,11,0,17)
				hDot.AnchorPoint = Vector2.new(0.5,0.5)
				hDot.Position    = UDim2.new(h,0,0.5,0)
				hDot.ZIndex = 9503
				corner(hDot, 50)
				do local sk=Instance.new("UIStroke",hDot); sk.Color=Color3.new(0,0,0); sk.Thickness=1 end

				-- hex input
				local hexBg = Instance.new("Frame", pickerFrame)
				hexBg.BackgroundColor3 = Color3.fromRGB(24,24,32)
				hexBg.BorderSizePixel  = 0
				hexBg.Position = UDim2.new(0,10,0,svSize+34)
				hexBg.Size     = UDim2.new(0,svSize,0,24)
				hexBg.ZIndex   = 9501
				corner(hexBg, 4)

				local hexBox = Instance.new("TextBox", hexBg)
				hexBox.BackgroundTransparency = 1
				hexBox.BorderSizePixel = 0
				hexBox.Position = UDim2.new(0,8,0,0)
				hexBox.Size     = UDim2.new(1,-16,1,0)
				hexBox.Font     = Enum.Font.GothamMedium
				hexBox.TextSize = 11
				hexBox.TextColor3       = T.TEXT
				hexBox.PlaceholderColor3= T.MUTED
				hexBox.Text = string.format("#%02X%02X%02X",
					math.floor(curColor.R*255), math.floor(curColor.G*255), math.floor(curColor.B*255))
				hexBox.ZIndex = 9502
				hexBox.TextXAlignment = Enum.TextXAlignment.Left
				hexBox.ClearTextOnFocus = false

				local function fireColor()
					curColor = Color3.fromHSV(h,s,v)
					swatch.BackgroundColor3 = curColor
					hexBox.Text = string.format("#%02X%02X%02X",
						math.floor(curColor.R*255), math.floor(curColor.G*255), math.floor(curColor.B*255))
					if c.Callback then c.Callback(curColor) end
				end

				local function updateHue()
					svFrame.BackgroundColor3 = Color3.fromHSV(h,1,1)
					hDot.Position = UDim2.new(h,0,0.5,0)
					fireColor()
				end
				local function updateSV()
					svDot.Position = UDim2.new(s,0,1-v,0)
					fireColor()
				end

				hexBox.FocusLost:Connect(function()
					local hex = hexBox.Text:gsub("#",""):gsub("%s","")
					if #hex == 6 then
						local r=tonumber(hex:sub(1,2),16)
						local g=tonumber(hex:sub(3,4),16)
						local b=tonumber(hex:sub(5,6),16)
						if r and g and b then
							curColor = Color3.fromRGB(r,g,b)
							h,s,v = Color3.toHSV(curColor)
							svFrame.BackgroundColor3 = Color3.fromHSV(h,1,1)
							svDot.Position = UDim2.new(s,0,1-v,0)
							hDot.Position  = UDim2.new(h,0,0.5,0)
							swatch.BackgroundColor3 = curColor
							if c.Callback then c.Callback(curColor) end
						end
					end
					hexBox.Text = string.format("#%02X%02X%02X",
						math.floor(curColor.R*255), math.floor(curColor.G*255), math.floor(curColor.B*255))
				end)

				local draggingSV=false; local draggingH=false

				svOver.InputBegan:Connect(function(i)
					if i.UserInputType==Enum.UserInputType.MouseButton1 then
						draggingSV=true
						local rel=Vector2.new(i.Position.X,i.Position.Y)-svFrame.AbsolutePosition
						s=math.clamp(rel.X/svSize,0,1); v=1-math.clamp(rel.Y/svSize,0,1)
						updateSV()
					end
				end)
				hueTrack.InputBegan:Connect(function(i)
					if i.UserInputType==Enum.UserInputType.MouseButton1 then
						draggingH=true
						local rel=Vector2.new(i.Position.X,i.Position.Y)-hueTrack.AbsolutePosition
						h=math.clamp(rel.X/svSize,0,1)
						updateHue()
					end
				end)
				UIS.InputEnded:Connect(function(i)
					if i.UserInputType==Enum.UserInputType.MouseButton1 then
						draggingSV=false; draggingH=false
					end
				end)
				UIS.InputChanged:Connect(function(i)
					if i.UserInputType~=Enum.UserInputType.MouseMovement then return end
					local mp = Vector2.new(i.Position.X,i.Position.Y)
					if draggingSV then
						local rel=mp-svFrame.AbsolutePosition
						s=math.clamp(rel.X/svSize,0,1); v=1-math.clamp(rel.Y/svSize,0,1)
						updateSV()
					elseif draggingH then
						local rel=mp-hueTrack.AbsolutePosition
						h=math.clamp(rel.X/svSize,0,1)
						updateHue()
					end
				end)

				-- close on outside click
				local closeConn
				closeConn = UIS.InputBegan:Connect(function(i)
					if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
					if not pickerFrame then closeConn:Disconnect(); return end
					task.delay(0.07, function()
						if not pickerFrame then return end
						local mp = UIS:GetMouseLocation()
						local fp = pickerFrame.AbsolutePosition; local fs = pickerFrame.AbsoluteSize
						local sp = swatch.AbsolutePosition;   local ss = swatch.AbsoluteSize
						local onP = mp.X>=fp.X and mp.X<=fp.X+fs.X and mp.Y>=fp.Y and mp.Y<=fp.Y+fs.Y
						local onS = mp.X>=sp.X and mp.X<=sp.X+ss.X and mp.Y>=sp.Y and mp.Y<=sp.Y+ss.Y
						if not onP and not onS then
							pcall(function() pickerFrame:Destroy() end)
							pickerFrame=nil
							closeConn:Disconnect()
						end
					end)
				end)
			end

			swatch.MouseButton1Click:Connect(buildPicker)
			win:_regSearchItem(c.Title or "Color", function() return frame:Clone() end)

			return {
				GetValue = function() return curColor end,
				SetValue = function(_, col) curColor=col; swatch.BackgroundColor3=col end,
			}
		end

		-- ── register ──────────────────────────────
		subTabs[i]     = st
		subTabs[stName]= st
	end

	local tab = {
		_win     = win,
		_navBtn  = navBtn,
		_navIcon = navIcon,
		_navLbl  = navLbl,
		_frame   = tabFrame,
		_subTabs = subTabs,
		_subDefs = subTabDefs,
		_activeST= nil,
		_title   = cfg.Title or "Tab",
		_desc    = cfg.Description or "",
	}
	setmetatable(tab, {
		__index = function(t, k)
			return rawget(t,"_subTabs") and rawget(t,"_subTabs")[k]
		end,
	})

	tab._activeST = subTabs[1]
	subTabs[1]._frame.Visible = true

	navBtn.Activated:Connect(function() win:_SelectTab(tab) end)
	navBtn.MouseEnter:Connect(function()
		if win._active ~= tab then
			tw(navBtn, TQ, {BackgroundTransparency=0.82, BackgroundColor3=T.ITEM})
			tw(navLbl, TQ, {TextColor3=T.TEXT})
			navIcon.ImageColor3 = T.ACC
		end
	end)
	navBtn.MouseLeave:Connect(function()
		if win._active ~= tab then
			tw(navBtn, TQ, {BackgroundTransparency=1})
			tw(navLbl, TQ, {TextColor3=T.MUTED})
			navIcon.ImageColor3 = T.MUTED
		end
	end)

	table.insert(self._tabs, tab)
	if #self._tabs == 1 then self:_SelectTab(tab) end
	return tab
end

-- ══════════════════════════════════════════════════
-- TAB SELECTION
-- ══════════════════════════════════════════════════
function Lib:_SelectTab(tab)
	if self._active then
		local p = self._active
		p._frame.Visible = false
		tw(p._navBtn, TQ, {BackgroundTransparency=1})
		tw(p._navLbl, TQ, {TextColor3=T.MUTED})
		p._navIcon.ImageColor3 = T.MUTED
	end
	self._active = tab
	tab._frame.Visible = true
	tw(tab._navBtn, TQ, {BackgroundTransparency=0, BackgroundColor3=T.ITEM})
	tw(tab._navLbl, TQ, {TextColor3=T.TEXT})
	tab._navIcon.ImageColor3 = T.ACC

	-- rebuild subtab bar
	for _, child in ipairs(self._stBar:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	for i, _ in ipairs(tab._subDefs) do
		self:_BuildSTBtn(tab, tab._subTabs[i], i)
	end
end

-- ══════════════════════════════════════════════════
-- SUBTAB BUTTON
-- ══════════════════════════════════════════════════
function Lib:_BuildSTBtn(tab, st, order)
	local isActive = (tab._activeST == st)

	local btn = Instance.new("TextButton", self._stBar)
	btn.Name = "STBtn_"..st._name
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel = 0
	btn.LayoutOrder = order
	btn.Size        = UDim2.new(0,88,1,0)
	btn.Text        = st._name
	btn.Font        = Enum.Font.GothamMedium
	btn.TextSize    = 13
	btn.TextColor3  = isActive and T.TEXT or T.MUTED
	btn.AutoButtonColor = false
	btn.ZIndex = 4

	local line = Instance.new("Frame", btn)
	line.BackgroundColor3 = T.ACC
	line.BorderSizePixel  = 0
	line.AnchorPoint = Vector2.new(0,1)
	line.Position    = UDim2.new(0.1,0,1,0)
	line.Size        = UDim2.new(0.8,0,0,2)
	line.BackgroundTransparency = isActive and 0 or 1
	line.ZIndex = 5
	regAcc(line, "BackgroundColor3")

	btn.Activated:Connect(function()
		if tab._activeST == st then return end
		if tab._activeST then tab._activeST._frame.Visible = false end
		tab._activeST = st; st._frame.Visible = true
		for _, child in ipairs(self._stBar:GetChildren()) do
			if child:IsA("TextButton") then
				local ca = (child.Name == "STBtn_"..st._name)
				tw(child, TQ, {TextColor3 = ca and T.TEXT or T.MUTED})
				local l = child:FindFirstChildOfClass("Frame")
				if l then
					l.BackgroundColor3 = T.ACC
					tw(l, TQ, {BackgroundTransparency = ca and 0 or 1})
				end
			end
		end
	end)
	btn.MouseEnter:Connect(function()
		if tab._activeST ~= st then tw(btn, TQ, {TextColor3=T.TEXT}) end
	end)
	btn.MouseLeave:Connect(function()
		if tab._activeST ~= st then tw(btn, TQ, {TextColor3=T.MUTED}) end
	end)
end

-- ══════════════════════════════════════════════════
-- EXTRA API
-- ══════════════════════════════════════════════════
function Lib:SetKeyExpiry(t)
	self._uKey.Text = "Key Exp: "..t
end

function Lib:SetUIScale(s)
	s = math.clamp(s, 0.6, 1.5)
	self._scale = s
	self._uiScale.Scale = s
end

function Lib:SetAccentColor(c)
	applyAcc(c)
	-- update glow
	pcall(function() self._glow.ImageColor3 = c end)
	-- update underline gradient
	if self._underGrad then
		self._underGrad.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0,    T.SIDEBAR),
			ColorSequenceKeypoint.new(0.08, T.SIDEBAR),
			ColorSequenceKeypoint.new(0.48, c),
			ColorSequenceKeypoint.new(0.92, T.SIDEBAR),
			ColorSequenceKeypoint.new(1,    T.SIDEBAR),
		}
	end
	-- update active nav icon
	if self._active then
		pcall(function() self._active._navIcon.ImageColor3 = c end)
	end
	-- update all tab nav icons to correct state
	for _, tab in ipairs(self._tabs) do
		local isActive = (self._active == tab)
		pcall(function() tab._navIcon.ImageColor3 = isActive and c or T.MUTED end)
	end
	-- update subtab underlines
	for _, child in ipairs(self._stBar:GetChildren()) do
		if child:IsA("TextButton") then
			local l = child:FindFirstChildOfClass("Frame")
			if l then l.BackgroundColor3 = c end
		end
	end
end

function Lib:SetMouseUnlock(enabled)
	self._unlockMouse = enabled
	if enabled then
		if self._mouseConn then return end
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		UIS.MouseIconEnabled = true
		self._mouseConn = RS.RenderStepped:Connect(function()
			UIS.MouseBehavior = Enum.MouseBehavior.Default
			UIS.MouseIconEnabled = true
		end)
	else
		if self._mouseConn then
			self._mouseConn:Disconnect()
			self._mouseConn = nil
		end
	end
end

function Lib:SetToggleKey(key)
	self._keybind = key
end

-- ══════════════════════════════════════════════════
-- CONFIG SYSTEM
-- ══════════════════════════════════════════════════
function Lib:_regConfig(key, getFn, setFn)
	self._configItems[key] = {get=getFn, set=setFn}
end

local function _enc(t)
	local out={}
	for k,v in pairs(t) do
		local ks = '"'..tostring(k)..'"'
		local vs
		if type(v)=="number" then vs=tostring(v)
		elseif type(v)=="boolean" then vs=v and "true" or "false"
		elseif type(v)=="string" then vs='"'..v:gsub('"','\\"')..'"'
		elseif type(v)=="table" then
			local inn={}
			for k2,v2 in pairs(v) do
				if type(v2)=="boolean" then
					table.insert(inn, '"'..tostring(k2)..'":'.. (v2 and "true" or "false"))
				end
			end
			vs = "{"..table.concat(inn,",").."}"
		end
		if vs then table.insert(out, ks..":"..vs) end
	end
	return "{"..table.concat(out,",").."}"
end

local function _dec(s)
	local t={}
	local inner = s:match("^%s*{(.*)}%s*$") or ""
	for k,v in inner:gmatch('"([^"]+)"%s*:%s*(-?%d+%.?%d*)') do t[k]=tonumber(v) end
	for k,_ in inner:gmatch('"([^"]+)"%s*:%s*(true)')  do if t[k]==nil then t[k]=true  end end
	for k,_ in inner:gmatch('"([^"]+)"%s*:%s*(false)') do if t[k]==nil then t[k]=false end end
	for k,v in inner:gmatch('"([^"]+)"%s*:%s*"([^"]*)"') do if t[k]==nil then t[k]=v end end
	for k,v in inner:gmatch('"([^"]+)"%s*:%s*({[^}]*})') do
		local sub={}
		for k2,_ in v:gmatch('"([^"]+)"%s*:%s*(true)')  do sub[k2]=true  end
		for k2,_ in v:gmatch('"([^"]+)"%s*:%s*(false)') do if sub[k2]==nil then sub[k2]=false end end
		if next(sub) then t[k]=sub end
	end
	return t
end

function Lib:SaveConfig(name)
	local data = {}
	for k,v in pairs(self._configItems) do
		local ok2, val = pcall(v.get)
		if ok2 then data[k]=val end
	end
	data["__scale"]    = self._scale or 1
	data["__accR"]     = math.floor(T.ACC.R*255)
	data["__accG"]     = math.floor(T.ACC.G*255)
	data["__accB"]     = math.floor(T.ACC.B*255)
	local folder = (self._logoTitle or "EVENESCE"):gsub("[^%w_%-]","_")
	pcall(makefolder, "EVENESCELib")
	pcall(makefolder, "EVENESCELib/"..folder)
	local ok2, err = pcall(writefile, "EVENESCELib/"..folder.."/"..name..".json", _enc(data))
	return ok2, err
end

function Lib:LoadConfig(name)
	local folder = (self._logoTitle or "EVENESCE"):gsub("[^%w_%-]","_")
	local ok2, content = pcall(readfile, "EVENESCELib/"..folder.."/"..name..".json")
	if not ok2 then return false, "Not found" end
	local data = _dec(content)
	for k, entry in pairs(self._configItems) do
		if data[k] ~= nil then pcall(entry.set, data[k]) end
	end
	if data["__scale"] then pcall(function() self:SetUIScale(data["__scale"]) end) end
	if data["__accR"] then
		pcall(function()
			self:SetAccentColor(Color3.fromRGB(data["__accR"], data["__accG"], data["__accB"]))
		end)
	end
	return true
end

function Lib:DeleteConfig(name)
	local folder = (self._logoTitle or "EVENESCE"):gsub("[^%w_%-]","_")
	local ok2, err = pcall(delfile, "EVENESCELib/"..folder.."/"..name..".json")
	return ok2, err
end

function Lib:ListConfigs()
	local folder = (self._logoTitle or "EVENESCE"):gsub("[^%w_%-]","_")
	local ok2, files = pcall(listfiles, "EVENESCELib/"..folder)
	if not ok2 then return {} end
	local names={}
	for _, f in ipairs(files) do
		local n = f:match("([^/\\]+)%.json$")
		if n then table.insert(names, n) end
	end
	return names
end

function Lib:Destroy()
	if self._mouseConn then self._mouseConn:Disconnect(); self._mouseConn=nil end
	pcall(function() self._sg:Destroy() end)
	pcall(function() if self._tsg then self._tsg:Destroy() end end)
	for i=#_accObjs,1,-1   do _accObjs[i]=nil   end
	for i=#_accBGObjs,1,-1 do _accBGObjs[i]=nil end
	for i=#_togRefs,1,-1   do _togRefs[i]=nil   end
end

return Lib
