local TS  = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local PL  = game:GetService("Players")
local RS  = game:GetService("RunService")

local T = {
	BG      = Color3.fromRGB(16,16,20),
	BG2     = Color3.fromRGB(14,14,18),
	BG3     = Color3.fromRGB(22,22,28),
	SEP     = Color3.fromRGB(28,28,36),
	ACC     = Color3.fromRGB(110,112,182),
	ACC_BG  = Color3.fromRGB(55,56,91),
	TEXT    = Color3.fromRGB(200,200,202),
	MUTED   = Color3.fromRGB(65,64,75),
}

local _TQ  = TweenInfo.new(0.2,  Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local _TQS = TweenInfo.new(0.3,  Enum.EasingStyle.Quint,  Enum.EasingDirection.Out)

local _accentObjs   = {}
local _accentBGObjs = {}
local _toggleRefs   = {}

local function regAcc(obj, prop)   table.insert(_accentObjs,   {obj=obj,   prop=prop}) end
local function regAccBG(obj, prop) table.insert(_accentBGObjs, {obj=obj,   prop=prop}) end
local function regToggle(dot, pill, getState)
	table.insert(_toggleRefs, {dot=dot, pill=pill, getState=getState})
end

local _ZTI = TweenInfo.new(0)
local function applyAcc(c)
	T.ACC    = c
	T.ACC_BG = Color3.fromRGB(math.floor(c.R*255*0.5), math.floor(c.G*255*0.5), math.floor(c.B*255*0.55))
	local alive = {}
	for _, r in ipairs(_accentObjs) do
		local ok = pcall(function()
			TS:Create(r.obj, _ZTI, {[r.prop]=c}):Play()
		end)
		if ok then table.insert(alive, r) end
	end
	_accentObjs = alive
	local aliveB = {}
	for _, r in ipairs(_accentBGObjs) do
		local ok = pcall(function()
			TS:Create(r.obj, _ZTI, {[r.prop]=T.ACC_BG}):Play()
		end)
		if ok then table.insert(aliveB, r) end
	end
	_accentBGObjs = aliveB
	local aliveT = {}
	for _, r in ipairs(_toggleRefs) do
		local ok = pcall(function()
			if r.getState() then
				TS:Create(r.dot,  _ZTI, {BackgroundColor3=c}):Play()
				TS:Create(r.pill, _ZTI, {BackgroundColor3=T.ACC_BG}):Play()
			end
		end)
		if ok then table.insert(aliveT, r) end
	end
	_toggleRefs = aliveT
end

local function tw(obj, t, props) TS:Create(obj, t, props):Play() end
local TQ  = TweenInfo.new(0.2,  Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TQS = TweenInfo.new(0.3,  Enum.EasingStyle.Quint,  Enum.EasingDirection.Out)

local function corner(p, r)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 6); c.Parent = p; return c
end
local function newFrame(parent, props)
	local f = Instance.new("Frame"); f.BackgroundTransparency=1; f.BorderSizePixel=0
	for k,v in pairs(props or {}) do f[k]=v end; f.Parent=parent; return f
end
local function newLabel(parent, props)
	local l = Instance.new("TextLabel"); l.BackgroundTransparency=1; l.BorderSizePixel=0
	l.Font=Enum.Font.GothamMedium; l.TextXAlignment=Enum.TextXAlignment.Left
	l.TextTruncate=Enum.TextTruncate.AtEnd
	for k,v in pairs(props or {}) do l[k]=v end; l.Parent=parent; return l
end
local function newImg(parent, props)
	local i = Instance.new("ImageLabel"); i.BackgroundTransparency=1; i.BorderSizePixel=0
	for k,v in pairs(props or {}) do i[k]=v end; i.Parent=parent; return i
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
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
		end
	end)
end

local Lib = {}
Lib.__index = Lib

function Lib:CreateWindow(cfg)
	cfg = cfg or {}
	local self = setmetatable({}, Lib)
	self._tabs      = {}
	self._active    = nil
	self._acc       = T.ACC
	self._keybind   = cfg.ToggleKey or Enum.KeyCode.RightShift
	self._scale     = 1

	local sg = Instance.new("ScreenGui")
	sg.Name = "SyftLib"; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; sg.ResetOnSpawn = false
	local ok, cg = pcall(function() return game:GetService("CoreGui") end)
	sg.Parent = ok and cg or PL.LocalPlayer.PlayerGui
	self._sg = sg

	local tsg = Instance.new("ScreenGui")
	tsg.Name="SyftToasts"; tsg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; tsg.ResetOnSpawn=false
	tsg.Parent = ok and cg or PL.LocalPlayer.PlayerGui
	self._tsg = tsg
	local toastHolder = newFrame(tsg, {
		AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-16,0,16),
		Size=UDim2.new(0,300,1,-32),
	})
	local toastList = Instance.new("UIListLayout"); toastList.SortOrder=Enum.SortOrder.LayoutOrder
	toastList.VerticalAlignment=Enum.VerticalAlignment.Top; toastList.Padding=UDim.new(0,6)
	toastList.Parent=toastHolder
	self._toastHolder = toastHolder
	self._toastCount  = 0

	local root = Instance.new("Frame")
	root.Name="Root"; root.BackgroundColor3=T.BG; root.BorderSizePixel=0
	root.AnchorPoint=Vector2.new(0.5,0.5)
	root.Position=UDim2.new(0.5,0,0.5,0)
	root.Size=UDim2.new(0,800,0,498)
	root.ClipsDescendants=false
	root.Parent=sg
	corner(root,10)
	self._root = root
	local uiScale = Instance.new("UIScale"); uiScale.Scale=1; uiScale.Parent=root
	self._uiScale = uiScale

	local rootClip = Instance.new("Frame")
	rootClip.BackgroundColor3=T.BG; rootClip.BorderSizePixel=0
	rootClip.Size=UDim2.new(1,0,1,0); rootClip.ClipsDescendants=true
	rootClip.Parent=root; corner(rootClip,10)
	self._rootClip = rootClip

	local glow = newImg(root, {
		Name="Glow", Position=UDim2.new(-0.03,-10,-0.06,-10),
		Size=UDim2.new(1.06,20,1.12,20), ZIndex=0,
		Image="rbxassetid://91808965474692",
		ImageColor3=T.ACC, ImageTransparency=0.6,
	})
	self._glow = glow
	regAcc(glow, "ImageColor3")
	corner(glow,20)

	local dragHandle = newFrame(rootClip, {
		Name="DragHandle", Size=UDim2.new(1,0,0,100), ZIndex=10,
		BackgroundColor3=T.BG2, BackgroundTransparency=1,
	})
	self._dragHandle = dragHandle
	makeDraggable(root, dragHandle)

	local sidebar = Instance.new("Frame")
	sidebar.Name="Sidebar"; sidebar.BackgroundColor3=T.BG; sidebar.BorderSizePixel=0
	sidebar.Size=UDim2.new(0,208,1,0); sidebar.ZIndex=2; sidebar.Parent=rootClip

	local sbCorner = corner(sidebar,10)
	local sbPatch = Instance.new("Frame")
	sbPatch.BackgroundColor3=T.BG; sbPatch.BorderSizePixel=0
	sbPatch.Position=UDim2.new(1,-12,0,0); sbPatch.Size=UDim2.new(0,12,1,0); sbPatch.ZIndex=2
	sbPatch.Parent=sidebar

	local sep = Instance.new("Frame")
	sep.BackgroundColor3=T.SEP; sep.BorderSizePixel=0
	sep.Position=UDim2.new(1,-1,0,0); sep.Size=UDim2.new(0,1,1,0); sep.ZIndex=3; sep.Parent=sidebar

	local logoArea = newFrame(sidebar,{Name="Logo",Size=UDim2.new(1,0,0,58),ZIndex=3})
	local logoLbl = Instance.new("TextLabel")
	logoLbl.BackgroundTransparency=1; logoLbl.BorderSizePixel=0
	logoLbl.Position=UDim2.new(0,18,0,14); logoLbl.Size=UDim2.new(1,-36,0,30)
	logoLbl.Font=Enum.Font.GothamBold; logoLbl.RichText=true
	logoLbl.TextSize=22; logoLbl.TextXAlignment=Enum.TextXAlignment.Left
	logoLbl.TextColor3=T.TEXT; logoLbl.ZIndex=4; logoLbl.Parent=logoArea
	self._logoLbl = logoLbl

	local title = cfg.Title or "syft.wtf"
	local dot = title:find("%.")
	if dot then
		local b=title:sub(1,dot-1); local a=title:sub(dot)
		logoLbl.Text=('<font color="rgb(%d,%d,%d)">%s</font><font color="rgb(%d,%d,%d)">%s</font>'):format(
			T.TEXT.R*255,T.TEXT.G*255,T.TEXT.B*255,b, T.ACC.R*255,T.ACC.G*255,T.ACC.B*255,a)
	else logoLbl.Text=title end
	self._logoTitle = title

	local logoLine = Instance.new("Frame")
	logoLine.BackgroundColor3=T.SEP; logoLine.BorderSizePixel=0
	logoLine.Position=UDim2.new(0,0,0,58); logoLine.Size=UDim2.new(1,0,0,1); logoLine.ZIndex=3; logoLine.Parent=sidebar

	local navScroll = Instance.new("ScrollingFrame")
	navScroll.BackgroundTransparency=1; navScroll.BorderSizePixel=0
	navScroll.Position=UDim2.new(0,0,0,60); navScroll.Size=UDim2.new(1,0,1,-122)
	navScroll.CanvasSize=UDim2.new(0,0,0,0); navScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
	navScroll.ScrollBarThickness=0; navScroll.ZIndex=3; navScroll.Parent=sidebar
	self._navScroll=navScroll
	Instance.new("UIListLayout",navScroll).SortOrder=Enum.SortOrder.LayoutOrder
	do local p=Instance.new("UIPadding",navScroll); p.PaddingLeft=UDim.new(0,10); p.PaddingRight=UDim.new(0,10); p.PaddingTop=UDim.new(0,6) end

	local footer = Instance.new("Frame")
	footer.Name="Footer"; footer.BackgroundColor3=T.BG; footer.BorderSizePixel=0
	footer.AnchorPoint=Vector2.new(0,1); footer.Position=UDim2.new(0,0,1,0)
	footer.Size=UDim2.new(1,0,0,64); footer.ZIndex=3; footer.Parent=sidebar
	do local fl=Instance.new("Frame",footer); fl.BackgroundColor3=T.SEP; fl.BorderSizePixel=0; fl.Size=UDim2.new(1,0,0,1); fl.ZIndex=4 end

	local uImg=Instance.new("ImageLabel",footer)
	uImg.BackgroundColor3=T.BG3; uImg.BorderSizePixel=0
	uImg.Position=UDim2.new(0,12,0,12); uImg.Size=UDim2.new(0,38,0,38)
	uImg.Image="rbxassetid://18469380757"; uImg.ZIndex=4; corner(uImg,50)
	self._uImg=uImg

	self._uName=newLabel(footer,{Position=UDim2.new(0,58,0,10),Size=UDim2.new(0,110,0,20),Text="@user",TextColor3=T.TEXT,TextSize=13,Font=Enum.Font.GothamBold,ZIndex=4})
	self._uKey =newLabel(footer,{Position=UDim2.new(0,58,0,30),Size=UDim2.new(0,110,0,16),Text="Key Exp: --",TextColor3=T.MUTED,TextSize=11,ZIndex=4})

	local closeBtn=Instance.new("ImageButton",footer)
	closeBtn.BackgroundTransparency=1; closeBtn.BorderSizePixel=0
	closeBtn.AnchorPoint=Vector2.new(1,0.5); closeBtn.Position=UDim2.new(1,-12,0.5,0)
	closeBtn.Size=UDim2.new(0,20,0,20); closeBtn.Image="rbxassetid://88930748781568"
	TS:Create(closeBtn,_TQ,{ImageColor3=T.MUTED}):Play(); closeBtn.ZIndex=4
	closeBtn.MouseEnter:Connect(function() TS:Create(closeBtn,_TQ,{ImageColor3=T.TEXT}):Play() end)
	closeBtn.MouseLeave:Connect(function() TS:Create(closeBtn,_TQ,{ImageColor3=T.MUTED}):Play() end)
	closeBtn.MouseButton1Click:Connect(function() sg.Enabled=false end)

	if cfg.Player ~= false then
		local lp=PL.LocalPlayer
		task.spawn(function()
			local ok2,c=pcall(function() return PL:GetUserThumbnailAsync(lp.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size420x420) end)
			if ok2 then uImg.Image=c end
			self._uName.Text="@"..lp.Name
		end)
	end

	local content = Instance.new("Frame")
	content.Name="Content"; content.BackgroundColor3=T.BG2; content.BorderSizePixel=0
	content.Position=UDim2.new(0,210,0,0); content.Size=UDim2.new(1,-210,1,0)
	content.ZIndex=1; content.ClipsDescendants=false; content.Parent=rootClip
	corner(content,10)
	local cPatch=Instance.new("Frame",content)
	cPatch.BackgroundColor3=T.BG2; cPatch.BorderSizePixel=0
	cPatch.Size=UDim2.new(0,12,1,0); cPatch.ZIndex=1
	self._content=content

	local header=newFrame(content,{Name="Header",BackgroundColor3=T.BG2,BackgroundTransparency=0,Size=UDim2.new(1,0,0,100),ZIndex=2,ClipsDescendants=false})
	self._header=header
	dragHandle.Parent = header
	dragHandle.Size   = UDim2.new(1,0,0,60)

	self._hTitle=newLabel(header,{Position=UDim2.new(0,20,0,12),Size=UDim2.new(1,-40,0,30),Text="",TextColor3=T.TEXT,TextSize=22,Font=Enum.Font.GothamBold,ZIndex=3})
	self._hDesc =newLabel(header,{Position=UDim2.new(0,20,0,42),Size=UDim2.new(1,-40,0,18),Text="",TextColor3=T.MUTED,TextSize=13,ZIndex=3})

	local stBar=newFrame(header,{Name="SubTabBar",Position=UDim2.new(0,12,1,-46),Size=UDim2.new(1,-12,0,46),ZIndex=3})
	do local l=Instance.new("UIListLayout",stBar); l.FillDirection=Enum.FillDirection.Horizontal; l.SortOrder=Enum.SortOrder.LayoutOrder end
	self._stBar=stBar

	do local hLine=Instance.new("Frame",header); hLine.BackgroundColor3=T.SEP; hLine.BorderSizePixel=0; hLine.Position=UDim2.new(0,0,1,0); hLine.Size=UDim2.new(1,0,0,1); hLine.ZIndex=4 end

	local tabHolder=newFrame(content,{Name="TabHolder",Position=UDim2.new(0,0,0,102),Size=UDim2.new(1,0,1,-102),ZIndex=1,ClipsDescendants=false})
	self._tabHolder=tabHolder

	self:_BuildMap()
	if cfg.Map then self:SetMapVisible(true) end

	self._unlockMouse = false
	self._mouseConn = nil

	local function startMouseUnlock()
		if self._mouseConn then return end
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		UIS.MouseIconEnabled = true
		self._mouseConn = RS.RenderStepped:Connect(function()
			UIS.MouseBehavior = Enum.MouseBehavior.Default
			UIS.MouseIconEnabled = true
		end)
	end

	local function stopMouseUnlock()
		if self._mouseConn then
			self._mouseConn:Disconnect()
			self._mouseConn = nil
		end
	end

	self._keybindIsMouse = false

	UIS.InputBegan:Connect(function(i, gp)
		local triggered = false
		if self._keybindIsMouse then
			triggered = (i.UserInputType == self._keybind)
		else
			if gp then return end
			triggered = (i.KeyCode == self._keybind)
		end
		if triggered then
			sg.Enabled = not sg.Enabled
			if sg.Enabled and self._unlockMouse then
				startMouseUnlock()
			elseif not sg.Enabled then
				stopMouseUnlock()
			end
		end
	end)

	self._startMouseUnlock = startMouseUnlock
	self._stopMouseUnlock  = stopMouseUnlock

	return self
end

function Lib:SetMouseUnlock(enabled)
	self._unlockMouse = enabled
	if enabled and self._sg and self._sg.Enabled then
		self._startMouseUnlock()
	elseif not enabled then
		self._stopMouseUnlock()
	end
end

function Lib:SetAccentColor(c)
	applyAcc(c)
	pcall(function() self._glow.ImageColor3 = c end)
	if self._logoTitle then
		local title = self._logoTitle
		local dot = title:find("%.")
		if dot then
			local b=title:sub(1,dot-1); local a=title:sub(dot)
			self._logoLbl.Text=('<font color="rgb(%d,%d,%d)">%s</font><font color="rgb(%d,%d,%d)">%s</font>'):format(
				T.TEXT.R*255,T.TEXT.G*255,T.TEXT.B*255,b, c.R*255,c.G*255,c.B*255,a)
		end
	end
	if self._active then
		pcall(function() self._active._navIcon.ImageColor3 = c end)
	end
	for _, child in ipairs(self._stBar:GetChildren()) do
		if child:IsA("TextButton") then
			local l = child:FindFirstChildOfClass("Frame")
			if l then l.BackgroundColor3 = c end
		end
	end
	for _, tab in ipairs(self._tabs) do
		local isActive = (self._active == tab)
		pcall(function()
			tab._navIcon.ImageColor3 = isActive and c or T.MUTED
		end)
	end
end

function Lib:SetKeyExpiry(t) self._uKey.Text="Key Exp: "..t end

function Lib:SetUIScale(s)
	s=math.clamp(s,0.6,1.5)
	self._scale=s
	self._uiScale.Scale=s
end

function Lib:SetToggleKey(key)
	self._keybind = key
end

function Lib:Toast(cfg)
	cfg = cfg or {}
	self._toastCount = (self._toastCount or 0) + 1
	local dur = cfg.Duration or 4

	local toast = Instance.new("Frame")
	toast.Name = "Toast_"..self._toastCount
	toast.BackgroundColor3 = T.BG3
	toast.BorderSizePixel = 0
	toast.Size = UDim2.new(1,0,0,0)
	toast.ClipsDescendants = true
	toast.LayoutOrder = self._toastCount
	toast.Parent = self._toastHolder
	corner(toast, 8)

	local bar = Instance.new("Frame",toast)
	bar.BackgroundColor3 = T.ACC; bar.BorderSizePixel=0
	bar.Size=UDim2.new(0,3,1,0); bar.ZIndex=2
	regAcc(bar,"BackgroundColor3")
	corner(bar,3)

	newLabel(toast,{Position=UDim2.new(0,14,0,10),Size=UDim2.new(1,-28,0,20),
		Text=cfg.Title or "Notification",TextColor3=T.TEXT,TextSize=14,Font=Enum.Font.GothamBold,ZIndex=3})
	newLabel(toast,{Position=UDim2.new(0,14,0,30),Size=UDim2.new(1,-28,0,18),
		Text=cfg.Message or "",TextColor3=T.MUTED,TextSize=12,ZIndex=3})

	local prog = Instance.new("Frame",toast)
	prog.BackgroundColor3=T.SEP; prog.BorderSizePixel=0
	prog.AnchorPoint=Vector2.new(0,1); prog.Position=UDim2.new(0,0,1,0)
	prog.Size=UDim2.new(1,0,0,3); prog.ZIndex=3
	local progFill = Instance.new("Frame",prog)
	progFill.BackgroundColor3=T.ACC; progFill.BorderSizePixel=0; progFill.Size=UDim2.new(1,0,1,0); progFill.ZIndex=4
	regAcc(progFill,"BackgroundColor3")
	corner(progFill,2)

	toast.Position = UDim2.new(1,340,0,0)
	TS:Create(toast, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size=UDim2.new(1,0,0,62), Position=UDim2.new(0,0,0,0)}):Play()
	task.delay(0.45, function()
		TS:Create(progFill, TweenInfo.new(dur, Enum.EasingStyle.Linear), {Size=UDim2.new(0,0,1,0)}):Play()
	end)
	task.delay(dur + 0.35, function()
		if not toast or not toast.Parent then return end
		TS:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position=UDim2.new(1,340,0,0)}):Play()
		task.delay(0.30, function()
			if not toast or not toast.Parent then return end
			TS:Create(toast, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size=UDim2.new(1,0,0,0)}):Play()
			task.delay(0.22, function() pcall(function() toast:Destroy() end) end)
		end)
	end)
end

function Lib:AddCategory(title)
	local lbl = Instance.new("TextLabel",self._navScroll)
	lbl.BackgroundTransparency=1; lbl.BorderSizePixel=0
	lbl.LayoutOrder=#self._tabs*20; lbl.Size=UDim2.new(1,0,0,22)
	lbl.Font=Enum.Font.GothamBold; lbl.Text=title:upper()
	lbl.TextColor3=T.MUTED; lbl.TextSize=10; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=3
	do local p=Instance.new("UIPadding",lbl); p.PaddingTop=UDim.new(0,8); p.PaddingLeft=UDim.new(0,4) end
end

function Lib:AddTab(cfg)
	cfg = cfg or {}
	local win = self
	local idx = #self._tabs + 1

	local navBtn=Instance.new("TextButton",self._navScroll)
	navBtn.Name="NavBtn_"..idx; navBtn.BackgroundColor3=T.BG3; navBtn.BackgroundTransparency=1
	navBtn.BorderSizePixel=0; navBtn.LayoutOrder=idx*20+1; navBtn.Size=UDim2.new(1,0,0,38)
	navBtn.Text=""; navBtn.AutoButtonColor=false; navBtn.ZIndex=3
	corner(navBtn,6)

	local navIcon=newImg(navBtn,{Position=UDim2.new(0,10,0.5,-10),Size=UDim2.new(0,20,0,20),Image=cfg.Icon or "",ImageColor3=T.MUTED,ZIndex=4})
	local navLbl=newLabel(navBtn,{Position=UDim2.new(0,38,0,0),Size=UDim2.new(1,-44,1,0),Text=cfg.Title or "Tab",TextColor3=T.MUTED,TextSize=14,TextYAlignment=Enum.TextYAlignment.Center,ZIndex=4})

	local tabFrame=newFrame(self._tabHolder,{Name="TabFrame_"..idx,Size=UDim2.new(1,0,1,0),Visible=false,ClipsDescendants=false})

	local subTabDefs = cfg.SubTabs or {"General","Game","Misc"}
	local subTabs = {}

	for i, stName in ipairs(subTabDefs) do
		local stFrame=newFrame(tabFrame,{Name="ST_"..stName,Size=UDim2.new(1,0,1,0),Visible=false,ClipsDescendants=false})

		local scroll=Instance.new("ScrollingFrame",stFrame)
		scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0
		scroll.Position=UDim2.new(0.012,0,0.01,0); scroll.Size=UDim2.new(0.976,0,0.98,0)
		scroll.CanvasSize=UDim2.new(0,0,0,0); scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
		scroll.ScrollBarThickness=4; scroll.ScrollBarImageColor3=T.ACC
		scroll.BottomImage="rbxassetid://136554681557134"
		scroll.MidImage="rbxassetid://100883556759005"
		scroll.TopImage="rbxassetid://97290610170116"
		scroll.ZIndex=2; scroll.ClipsDescendants=true
		regAcc(scroll,"ScrollBarImageColor3")
		do local l=Instance.new("UIListLayout",scroll); l.SortOrder=Enum.SortOrder.LayoutOrder; l.Padding=UDim.new(0,8) end
		do local p=Instance.new("UIPadding",scroll); p.PaddingLeft=UDim.new(0,12); p.PaddingRight=UDim.new(0,16); p.PaddingTop=UDim.new(0,10); p.PaddingBottom=UDim.new(0,10) end

		local st = { _name=stName, _order=i, _frame=stFrame, _scroll=scroll, _itemCt=0 }

		function st:AddSection(title)
			self._itemCt=self._itemCt+1
			local lbl=Instance.new("TextLabel",self._scroll)
			lbl.BackgroundTransparency=1; lbl.BorderSizePixel=0; lbl.LayoutOrder=self._itemCt
			lbl.Size=UDim2.new(1,0,0,20); lbl.Font=Enum.Font.GothamBold; lbl.Text=title:upper()
			lbl.TextColor3=T.MUTED; lbl.TextSize=10; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=3
			do local p=Instance.new("UIPadding",lbl); p.PaddingTop=UDim.new(0,6) end
		end

		function st:AddToggle(c)
			c=c or {}
			self._itemCt=self._itemCt+1
			local frame=Instance.new("Frame",self._scroll)
			TS:Create(frame,_TQ,{BackgroundColor3=T.BG}):Play(); frame.BorderSizePixel=0
			frame.LayoutOrder=self._itemCt; frame.Size=UDim2.new(1,0,0,64); frame.ZIndex=3
			corner(frame,6)

			local titleLbl=newLabel(frame,{Name="Title",Position=UDim2.new(0,14,0,12),Size=UDim2.new(0.65,0,0,22),
				Text=c.Title or "Toggle",TextColor3=c.Default and T.TEXT or T.MUTED,TextSize=16,Font=Enum.Font.GothamBold,ZIndex=4})
			newLabel(frame,{Position=UDim2.new(0,14,0,36),Size=UDim2.new(0.75,0,0,18),
				Text=c.Description or "",TextColor3=T.MUTED,TextSize=12,ZIndex=4})

			local pill=Instance.new("TextButton",frame)
			pill.BackgroundColor3=c.Default and T.ACC_BG or T.BG3; pill.BorderSizePixel=0
			pill.AnchorPoint=Vector2.new(1,0.5); pill.Position=UDim2.new(1,-14,0.5,0)
			pill.Size=UDim2.new(0,52,0,26); pill.Text=""; pill.AutoButtonColor=false; pill.ZIndex=5
			corner(pill,50)

			local dot=Instance.new("Frame",pill)
			dot.BackgroundColor3=c.Default and T.ACC or T.MUTED; dot.BorderSizePixel=0
			dot.AnchorPoint=Vector2.new(0,0.5)
			dot.Position=c.Default and UDim2.new(1,-22,0.5,0) or UDim2.new(0,4,0.5,0)
			dot.Size=UDim2.new(0,18,0,18); dot.ZIndex=6
			corner(dot,50)

			local toggled = c.Default or false

			local function setToggle(v)
				toggled = v
				local onPos=UDim2.new(1,-22,0.5,0); local offPos=UDim2.new(0,4,0.5,0)
				TS:Create(dot,_TQS,{Position=v and onPos or offPos}):Play()
				dot.BackgroundColor3=v and T.ACC or T.MUTED
				pill.BackgroundColor3=v and T.ACC_BG or T.BG3
				titleLbl.TextColor3=v and T.TEXT or T.MUTED
				if c.Callback then c.Callback(v) end
			end

			regToggle(dot, pill, function() return toggled end)

			pill.Activated:Connect(function() setToggle(not toggled) end)

			frame.MouseEnter:Connect(function() TS:Create(frame,_TQ,{BackgroundColor3=Color3.fromRGB(20,20,26)}):Play() end)
			frame.MouseLeave:Connect(function() TS:Create(frame,_TQ,{BackgroundColor3=T.BG}):Play() end)

			local cfgKey="toggle_"..stName.."_"..self._itemCt
		win:_regConfig(cfgKey, function() return toggled end, function(v) setToggle(v) end)
		return {SetValue=function(_,v) setToggle(v) end, GetValue=function() return toggled end}
		end

		function st:AddSlider(c)
			c=c or {}
			self._itemCt=self._itemCt+1
			local frame=Instance.new("Frame",self._scroll)
			TS:Create(frame,_TQ,{BackgroundColor3=T.BG}):Play(); frame.BorderSizePixel=0
			frame.LayoutOrder=self._itemCt; frame.Size=UDim2.new(1,0,0,64); frame.ZIndex=3
			corner(frame,6)

			newLabel(frame,{Position=UDim2.new(0,14,0,12),Size=UDim2.new(0.5,0,0,22),
				Text=c.Title or "Slider",TextColor3=T.TEXT,TextSize=16,Font=Enum.Font.GothamBold,ZIndex=4})
			newLabel(frame,{Position=UDim2.new(0,14,0,36),Size=UDim2.new(0.55,0,0,18),
				Text=c.Description or "",TextColor3=T.MUTED,TextSize=12,ZIndex=4})

			local minV=c.Min or 0; local maxV=c.Max or 100
			local curV=math.clamp(c.Default or minV,minV,maxV)

			local valLbl=newLabel(frame,{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-14,0,12),Size=UDim2.new(0,55,0,22),
				Text=tostring(curV),TextColor3=T.ACC,TextSize=14,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=5})
			regAcc(valLbl,"TextColor3")

			local track=Instance.new("Frame",frame)
			track.BackgroundColor3=T.SEP; track.BorderSizePixel=0
			track.AnchorPoint=Vector2.new(1,0.5); track.Position=UDim2.new(1,-14,0.72,0)
			track.Size=UDim2.new(0,170,0,6); track.ZIndex=5
			corner(track,3)

			local fill=Instance.new("Frame",track)
			fill.BackgroundColor3=T.ACC; fill.BorderSizePixel=0
			fill.Size=UDim2.new((curV-minV)/(maxV-minV),0,1,0); fill.ZIndex=6
			corner(fill,3); regAcc(fill,"BackgroundColor3")

			local handle=Instance.new("Frame",track)
			handle.BackgroundColor3=T.TEXT; handle.BorderSizePixel=0
			handle.AnchorPoint=Vector2.new(0.5,0.5)
			handle.Size=UDim2.new(0,12,0,12)
			handle.Position=UDim2.new((curV-minV)/(maxV-minV),0,0.5,0); handle.ZIndex=7
			corner(handle,50)

			local dragging=false
			local function updateFromX(x)
				local ap=track.AbsolutePosition.X; local as=track.AbsoluteSize.X
				local pct=math.clamp((x-ap)/as,0,1)
				local v=math.floor(minV+(maxV-minV)*pct)
				TS:Create(fill,TweenInfo.new(0.08,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.new(pct,0,1,0)}):Play()
				TS:Create(handle,TweenInfo.new(0.08,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.new(pct,0,0.5,0)}):Play()
				valLbl.Text=tostring(v); curV=v
				if c.Callback then c.Callback(v) end
			end

			track.InputBegan:Connect(function(i)
				if i.UserInputType==Enum.UserInputType.MouseButton1 then
					dragging=true
					TS:Create(handle,_TQ,{Size=UDim2.new(0,16,0,16)}):Play()
					updateFromX(i.Position.X)
				end
			end)
			UIS.InputEnded:Connect(function(i)
				if i.UserInputType==Enum.UserInputType.MouseButton1 and dragging then
					dragging=false
					TS:Create(handle,_TQ,{Size=UDim2.new(0,12,0,12)}):Play()
				end
			end)
			UIS.InputChanged:Connect(function(i)
				if not dragging then return end
				if i.UserInputType==Enum.UserInputType.MouseMovement then
					updateFromX(i.Position.X)
				end
			end)

			frame.MouseEnter:Connect(function() TS:Create(frame,_TQ,{BackgroundColor3=Color3.fromRGB(20,20,26)}):Play() end)
			frame.MouseLeave:Connect(function() TS:Create(frame,_TQ,{BackgroundColor3=T.BG}):Play() end)

			local sldrKey="slider_"..stName.."_"..self._itemCt
			win:_regConfig(sldrKey, function() return curV end, function(v)
				curV=math.clamp(v,minV,maxV); local p=(curV-minV)/(maxV-minV)
				fill.Size=UDim2.new(p,0,1,0); handle.Position=UDim2.new(p,0,0.5,0); valLbl.Text=tostring(curV)
				if c.Callback then c.Callback(curV) end
			end)
			return {
				SetValue=function(_,v) curV=math.clamp(v,minV,maxV); local p=(curV-minV)/(maxV-minV); fill.Size=UDim2.new(p,0,1,0); handle.Position=UDim2.new(p,0,0.5,0); valLbl.Text=tostring(curV) end,
				GetValue=function() return curV end,
			}
		end

		function st:AddButton(c)
			c=c or {}
			self._itemCt=self._itemCt+1
			local btn=Instance.new("TextButton",self._scroll)
			TS:Create(btn,_TQ,{BackgroundColor3=T.BG}):Play(); btn.BorderSizePixel=0
			btn.LayoutOrder=self._itemCt; btn.Size=UDim2.new(1,0,0,64)
			btn.Text=""; btn.AutoButtonColor=false; btn.ZIndex=3
			corner(btn,6)

			newLabel(btn,{Position=UDim2.new(0,14,0,12),Size=UDim2.new(0.7,0,0,22),Text=c.Title or "Button",TextColor3=T.TEXT,TextSize=16,Font=Enum.Font.GothamBold,ZIndex=4})
			newLabel(btn,{Position=UDim2.new(0,14,0,36),Size=UDim2.new(0.75,0,0,18),Text=c.Description or "",TextColor3=T.MUTED,TextSize=12,ZIndex=4})
			if c.Icon then
				newImg(btn,{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-14,0.5,0),Size=UDim2.new(0,26,0,26),Image=c.Icon,ImageColor3=T.MUTED,ZIndex=4})
			end

			btn.MouseEnter:Connect(function() TS:Create(btn,_TQ,{BackgroundColor3=T.BG3}):Play() end)
			btn.MouseLeave:Connect(function() TS:Create(btn,_TQ,{BackgroundColor3=T.BG}):Play() end)
			btn.MouseButton1Down:Connect(function() TS:Create(btn,TweenInfo.new(0.08),{BackgroundColor3=Color3.fromRGB(30,30,40)}):Play() end)
			btn.MouseButton1Up:Connect(function() TS:Create(btn,_TQ,{BackgroundColor3=T.BG3}):Play() end)
			btn.Activated:Connect(function() if c.Callback then c.Callback() end end)

			return {Frame=btn}
		end

		function st:AddDropdown(c)
			c=c or {}
			self._itemCt=self._itemCt+1
			local isMulti = c.SelectMode == true
			local frame=Instance.new("Frame",self._scroll)
			TS:Create(frame,_TQ,{BackgroundColor3=T.BG}):Play(); frame.BorderSizePixel=0
			frame.LayoutOrder=self._itemCt; frame.Size=UDim2.new(1,0,0,64)
			frame.ZIndex=3; frame.ClipsDescendants=false
			corner(frame,6)

			newLabel(frame,{Position=UDim2.new(0,14,0,12),Size=UDim2.new(0.5,0,0,22),
				Text=c.Title or "Dropdown",TextColor3=T.TEXT,TextSize=16,Font=Enum.Font.GothamBold,ZIndex=4})
			newLabel(frame,{Position=UDim2.new(0,14,0,36),Size=UDim2.new(0.5,0,0,18),
				Text=c.Description or "",TextColor3=T.MUTED,TextSize=12,ZIndex=4})

			local selected      = c.Default or (c.Options and c.Options[1]) or "Select"
			local multiSelected = {}
			if isMulti and type(c.Default)=="table" then
				for _,v in ipairs(c.Default) do multiSelected[v]=true end
			elseif isMulti and type(c.Default)=="string" then
				multiSelected[c.Default]=true
			end

			local function multiLabel()
				local parts={}
				for _,opt in ipairs(c.Options or {}) do
					if multiSelected[opt] then table.insert(parts,opt) end
				end
				return #parts>0 and table.concat(parts,", ") or "None"
			end

			local dd=Instance.new("TextButton",frame)
			dd.BackgroundColor3=T.BG3; dd.BorderSizePixel=0
			dd.AnchorPoint=Vector2.new(1,0.5); dd.Position=UDim2.new(1,-14,0.5,0)
			dd.Size=UDim2.new(0,165,0,32); dd.Text=""; dd.AutoButtonColor=false; dd.ZIndex=5
			corner(dd,6)

			local selLbl=newLabel(dd,{
				Position=UDim2.new(0,10,0,0), Size=UDim2.new(1,-32,1,0),
				Text=isMulti and multiLabel() or selected,
				TextColor3=T.TEXT, TextSize=12, Font=Enum.Font.GothamMedium, ZIndex=6,
				TextYAlignment=Enum.TextYAlignment.Center,
				TextTruncate=Enum.TextTruncate.AtEnd,
			})

			local arrowImg=newImg(dd,{
				Name="DDArrow",
				AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-8,0.5,0),
				Size=UDim2.new(0,14,0,14),
				Image="rbxassetid://75251661334198",
				ImageColor3=T.MUTED, ZIndex=6,
			})

			local isOpen=false
			local optContainer=nil

			local function closeDD()
				if optContainer then
					local oc=optContainer; optContainer=nil
					TS:Create(oc,TweenInfo.new(0.15,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Size=UDim2.new(0,165,0,0)}):Play()
					task.delay(0.22,function() pcall(function() oc:Destroy() end) end)
				end
				TS:Create(arrowImg,_TQ,{Rotation=0}):Play()
				isOpen=false
			end

			dd.Activated:Connect(function()
				if isOpen then closeDD(); return end
				isOpen=true
				TS:Create(arrowImg,_TQ,{Rotation=180}):Play()

				local opts=c.Options or {}
				local optW=165; local optRowH=32

				local sg=win._sg
				optContainer=Instance.new("Frame",sg)
				optContainer.Name="DDOpts"
				optContainer.BackgroundColor3=Color3.fromRGB(24,24,32)
				optContainer.BorderSizePixel=0
				optContainer.Size=UDim2.new(0,optW,0,0)
				optContainer.ClipsDescendants=true
				optContainer.ZIndex=9000
				corner(optContainer,6)
				do local l=Instance.new("UIListLayout",optContainer); l.SortOrder=Enum.SortOrder.LayoutOrder end
				do local p=Instance.new("UIPadding",optContainer)
					p.PaddingTop=UDim.new(0,4); p.PaddingBottom=UDim.new(0,4)
					p.PaddingLeft=UDim.new(0,4); p.PaddingRight=UDim.new(0,4) end

				RS.RenderStepped:Wait()
				if not optContainer or not optContainer.Parent then return end

				local ap=dd.AbsolutePosition; local as=dd.AbsoluteSize
				local baseH=#opts*optRowH+(isMulti and 34 or 0)+8
				local dropH=math.min(baseH, 6*optRowH+(isMulti and 34 or 0)+8)
				local vp=workspace.CurrentCamera.ViewportSize
				local yPos=(ap.Y+as.Y+dropH>vp.Y-20) and (ap.Y-dropH-4) or (ap.Y+as.Y+4)
				optContainer.Position=UDim2.new(0,ap.X,0,yPos)

				for i,opt in ipairs(opts) do
					local ob=Instance.new("TextButton",optContainer)
					local isSel=isMulti and multiSelected[opt] or (not isMulti and opt==selected)
					ob.BackgroundColor3=Color3.fromRGB(32,32,44)
					ob.BackgroundTransparency=isSel and 0.6 or 1
					ob.BorderSizePixel=0; ob.Size=UDim2.new(1,0,0,optRowH)
					ob.Text=""; ob.AutoButtonColor=false; ob.ZIndex=9001; ob.LayoutOrder=i
					corner(ob,4)

					local ol=newLabel(ob,{
						Position=UDim2.new(0,10,0,0), Size=UDim2.new(isMulti and 0.78 or 1,-10,1,0),
						Text=opt, TextColor3=isSel and T.ACC or T.TEXT,
						TextSize=13, Font=Enum.Font.GothamMedium, ZIndex=9002,
						TextYAlignment=Enum.TextYAlignment.Center,
					})

					local checkLbl
					if isMulti then
						checkLbl=newLabel(ob,{
							AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-8,0.5,0),
							Size=UDim2.new(0,16,0,16),
							Text=multiSelected[opt] and "✓" or "",
							TextColor3=T.ACC, TextSize=13, Font=Enum.Font.GothamBold,
							ZIndex=9003, TextXAlignment=Enum.TextXAlignment.Center,
						})
					end

					ob.MouseEnter:Connect(function()
						TS:Create(ob,_TQ,{BackgroundTransparency=0.5,BackgroundColor3=Color3.fromRGB(44,44,60)}):Play()
						TS:Create(ol,_TQ,{TextColor3=T.TEXT}):Play()
					end)
					ob.MouseLeave:Connect(function()
						local s2=isMulti and multiSelected[opt] or (not isMulti and opt==selected)
						TS:Create(ob,_TQ,{BackgroundTransparency=s2 and 0.6 or 1}):Play()
						TS:Create(ol,_TQ,{TextColor3=s2 and T.ACC or T.TEXT}):Play()
					end)
					ob.Activated:Connect(function()
						if isMulti then
							multiSelected[opt]=not multiSelected[opt]
							local s2=multiSelected[opt]
							ob.BackgroundTransparency=s2 and 0.6 or 1
							ol.TextColor3=s2 and T.ACC or T.TEXT
							if checkLbl then checkLbl.Text=s2 and "✓" or "" end
							selLbl.Text=multiLabel()
							if c.Callback then c.Callback(multiSelected) end
						else
							selected=opt; selLbl.Text=opt
							local oc=optContainer
							if oc then
								for _,ch in ipairs(oc:GetChildren()) do
									if ch:IsA("TextButton") then
										local chOl=ch:FindFirstChildOfClass("TextLabel")
										local cur=chOl and chOl.Text==opt
										ch.BackgroundTransparency=cur and 0.6 or 1
										if chOl then chOl.TextColor3=cur and T.ACC or T.TEXT end
									end
								end
							end
							if c.Callback then c.Callback(opt) end
							closeDD()
						end
					end)
				end

				if isMulti then
					local doneBtn=Instance.new("TextButton",optContainer)
					doneBtn.BackgroundColor3=T.ACC_BG; doneBtn.BorderSizePixel=0
					doneBtn.Size=UDim2.new(1,0,0,30); doneBtn.Text="Done"
					doneBtn.Font=Enum.Font.GothamBold; doneBtn.TextSize=13
					doneBtn.TextColor3=T.ACC; doneBtn.AutoButtonColor=false
					doneBtn.ZIndex=9001; doneBtn.LayoutOrder=#opts+1
					corner(doneBtn,4)
					doneBtn.MouseEnter:Connect(function() TS:Create(doneBtn,_TQ,{BackgroundColor3=T.ACC,TextColor3=T.BG}):Play() end)
					doneBtn.MouseLeave:Connect(function() TS:Create(doneBtn,_TQ,{BackgroundColor3=T.ACC_BG,TextColor3=T.ACC}):Play() end)
					doneBtn.Activated:Connect(function() closeDD() end)
				end

				TS:Create(optContainer,TweenInfo.new(0.25,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.new(0,optW,0,dropH)}):Play()
			end)

			UIS.InputBegan:Connect(function(i)
				if not isOpen then return end
				if i.UserInputType==Enum.UserInputType.MouseButton1 then
					task.delay(0.06,function() if isOpen then closeDD() end end)
				end
			end)

			frame.MouseEnter:Connect(function() TS:Create(frame,_TQ,{BackgroundColor3=Color3.fromRGB(20,20,26)}):Play() end)
			frame.MouseLeave:Connect(function() TS:Create(frame,_TQ,{BackgroundColor3=T.BG}):Play() end)

			local cfgKey="dropdown_"..stName.."_"..self._itemCt
			win:_regConfig(cfgKey,
				function() return isMulti and multiSelected or selected end,
				function(v)
					if isMulti and type(v)=="table" then
						multiSelected=v; selLbl.Text=multiLabel()
						if c.Callback then c.Callback(multiSelected) end
					elseif not isMulti and type(v)=="string" then
						selected=v; selLbl.Text=v
						if c.Callback then c.Callback(selected) end
					end
				end)
			return {
				SetValue = function(_,v)
					if isMulti then
						if type(v)=="table" then multiSelected=v end
						selLbl.Text=multiLabel()
					else
						selected=v; selLbl.Text=v
					end
				end,
				GetValue = function()
					return isMulti and multiSelected or selected
				end,
				SetOptions = function(_, newOpts)
					c.Options = newOpts or {}
					local first = newOpts and newOpts[1] or ""
					selected = first
					selLbl.Text = first
				end,
			}
		end

		function st:AddTextbox(c)
			c=c or {}
			self._itemCt=self._itemCt+1
			local frame=Instance.new("Frame",self._scroll)
			TS:Create(frame,_TQ,{BackgroundColor3=T.BG}):Play(); frame.BorderSizePixel=0
			frame.LayoutOrder=self._itemCt; frame.Size=UDim2.new(1,0,0,64); frame.ZIndex=3
			corner(frame,6)

			newLabel(frame,{Position=UDim2.new(0,14,0,12),Size=UDim2.new(0.55,0,0,22),
				Text=c.Title or "Textbox",TextColor3=T.TEXT,TextSize=16,Font=Enum.Font.GothamBold,ZIndex=4})
			newLabel(frame,{Position=UDim2.new(0,14,0,36),Size=UDim2.new(0.55,0,0,18),
				Text=c.Description or "",TextColor3=T.MUTED,TextSize=12,ZIndex=4})

			local inputBg=Instance.new("Frame",frame)
			inputBg.BackgroundColor3=T.BG3; inputBg.BorderSizePixel=0
			inputBg.AnchorPoint=Vector2.new(1,0.5); inputBg.Position=UDim2.new(1,-14,0.5,0)
			inputBg.Size=UDim2.new(0,175,0,32); inputBg.ZIndex=5
			corner(inputBg,6)

			local box=Instance.new("TextBox",inputBg)
			box.BackgroundTransparency=1; box.BorderSizePixel=0
			box.Position=UDim2.new(0,10,0,0); box.Size=UDim2.new(1,-20,1,0)
			box.Font=Enum.Font.GothamMedium; box.TextSize=13
			box.TextColor3=T.TEXT; box.PlaceholderColor3=T.MUTED
			box.PlaceholderText=c.Placeholder or "Type here..."
			box.Text=c.Default or ""; box.ClearTextOnFocus=c.ClearOnFocus or false
			box.ZIndex=6; box.TextXAlignment=Enum.TextXAlignment.Left

			box.Focused:Connect(function()
				inputBg.BackgroundColor3=Color3.fromRGB(30,30,42)
				local stroke=Instance.new("UIStroke",inputBg)
				stroke.Color=T.ACC; stroke.Thickness=1; stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
				regAcc(stroke,"Color")
			end)
			box.FocusLost:Connect(function(enter)
				inputBg.BackgroundColor3=T.BG3
				local stroke=inputBg:FindFirstChildOfClass("UIStroke")
				if stroke then stroke:Destroy() end
				if c.Callback then c.Callback(box.Text, enter) end
			end)

			frame.MouseEnter:Connect(function() TS:Create(frame,_TQ,{BackgroundColor3=Color3.fromRGB(20,20,26)}):Play() end)
			frame.MouseLeave:Connect(function() TS:Create(frame,_TQ,{BackgroundColor3=T.BG}):Play() end)

			return {
				GetValue = function() return box.Text end,
				SetValue = function(_,v) box.Text=v end,
			}
		end

		function st:AddDivider(c)
			c=c or {}
			self._itemCt=self._itemCt+1
			local wrap=Instance.new("Frame",self._scroll)
			wrap.BackgroundTransparency=1; wrap.BorderSizePixel=0
			wrap.LayoutOrder=self._itemCt; wrap.ZIndex=3

			if c.Title and c.Title ~= "" then
				wrap.Size=UDim2.new(1,0,0,28)
				local lineL=Instance.new("Frame",wrap)
				lineL.BackgroundColor3=T.SEP; lineL.BorderSizePixel=0
				lineL.AnchorPoint=Vector2.new(0,0.5); lineL.Position=UDim2.new(0,0,0.5,0)
				lineL.Size=UDim2.new(0.28,-8,0,1); lineL.ZIndex=3
				local lbl=newLabel(wrap,{
					AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,0),
					Size=UDim2.new(0.44,0,1,0),
					Text=c.Title, TextColor3=T.MUTED, TextSize=11,
					Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Center, ZIndex=4,
				})
				local lineR=Instance.new("Frame",wrap)
				lineR.BackgroundColor3=T.SEP; lineR.BorderSizePixel=0
				lineR.AnchorPoint=Vector2.new(1,0.5); lineR.Position=UDim2.new(1,0,0.5,0)
				lineR.Size=UDim2.new(0.28,-8,0,1); lineR.ZIndex=3
			else
				wrap.Size=UDim2.new(1,0,0,16)
				local line=Instance.new("Frame",wrap)
				line.BackgroundColor3=T.SEP; line.BorderSizePixel=0
				line.AnchorPoint=Vector2.new(0,0.5); line.Position=UDim2.new(0,0,0.5,0)
				line.Size=UDim2.new(1,0,0,1); line.ZIndex=3
			end
		end

		function st:AddKeybind(c)
			c=c or {}
			self._itemCt=self._itemCt+1
			local frame=Instance.new("Frame",self._scroll)
			TS:Create(frame,_TQ,{BackgroundColor3=T.BG}):Play(); frame.BorderSizePixel=0
			frame.LayoutOrder=self._itemCt; frame.Size=UDim2.new(1,0,0,64); frame.ZIndex=3
			corner(frame,6)

			newLabel(frame,{Position=UDim2.new(0,14,0,12),Size=UDim2.new(0.65,0,0,22),Text=c.Title or "Keybind",TextColor3=T.TEXT,TextSize=16,Font=Enum.Font.GothamBold,ZIndex=4})
			newLabel(frame,{Position=UDim2.new(0,14,0,36),Size=UDim2.new(0.65,0,0,18),Text=c.Description or "",TextColor3=T.MUTED,TextSize=12,ZIndex=4})

			local curKey = c.Default or Enum.KeyCode.Unknown
			local listening = false

			local keyBtn=Instance.new("TextButton",frame)
			TS:Create(keyBtn,_TQ,{BackgroundColor3=T.BG3}):Play(); keyBtn.BorderSizePixel=0
			keyBtn.AnchorPoint=Vector2.new(1,0.5); keyBtn.Position=UDim2.new(1,-14,0.5,0)
			keyBtn.Size=UDim2.new(0,120,0,32); keyBtn.Font=Enum.Font.GothamMedium
			keyBtn.TextSize=13; keyBtn.AutoButtonColor=false; keyBtn.ZIndex=5
			keyBtn.TextColor3=T.TEXT
			corner(keyBtn,6)

			-- mouse bind name lookup (populated if MouseBinds=true)
			local mouseNames = {
				[Enum.UserInputType.MouseButton1] = "LMB",
				[Enum.UserInputType.MouseButton2] = "RMB",
				[Enum.UserInputType.MouseButton3] = "MMB",
			}
			pcall(function() mouseNames[Enum.UserInputType.MouseButton4] = "Mouse4" end)
			pcall(function() mouseNames[Enum.UserInputType.MouseButton5] = "Mouse5" end)

			local function bindName(k)
				if mouseNames[k] then return mouseNames[k] end
				return tostring(k):gsub("Enum.KeyCode.",""):gsub("Enum.UserInputType.","")
			end
			keyBtn.Text=bindName(curKey)

			local function applyBind(newKey, fromMouse)
				curKey=newKey; listening=false
				keyBtn.Text=bindName(newKey)
				TS:Create(keyBtn,_TQ,{BackgroundColor3=T.BG3}):Play()
				keyBtn.TextColor3=T.TEXT
				if c.IsToggleKey and win then
					win._keybind=newKey
					win._keybindIsMouse=fromMouse
				end
				if c.Callback then c.Callback(newKey) end
			end
			local mouse = PL.LocalPlayer:GetMouse()

			keyBtn.MouseButton1Click:Connect(function()
				if listening then return end
				listening=true
				TS:Create(keyBtn,_TQ,{BackgroundColor3=T.ACC_BG}):Play()
				keyBtn.Text="..."
				keyBtn.TextColor3=T.ACC
			end)

			UIS.InputBegan:Connect(function(i, gp)
				if not listening then return end
				if i.UserInputType==Enum.UserInputType.Keyboard then
					if not gp then applyBind(i.KeyCode, false) end
				end
			end)

			if c.MouseBinds then
				mouse.Button1Up:Connect(function()
					if not listening then return end
					local pos = UIS:GetMouseLocation()
					local ap  = keyBtn.AbsolutePosition
					local as  = keyBtn.AbsoluteSize
					local onBtn = pos.X>=ap.X and pos.X<=ap.X+as.X and pos.Y>=ap.Y and pos.Y<=ap.Y+as.Y
					if not onBtn then
						applyBind(Enum.UserInputType.MouseButton1, true)
					end
				end)
				mouse.Button2Up:Connect(function()
					if not listening then return end
					applyBind(Enum.UserInputType.MouseButton2, true)
				end)
			end



			frame.MouseEnter:Connect(function() TS:Create(frame,_TQ,{BackgroundColor3=Color3.fromRGB(20,20,26)}):Play() end)
			frame.MouseLeave:Connect(function() TS:Create(frame,_TQ,{BackgroundColor3=T.BG}):Play() end)

			local kbKey="keybind_"..stName.."_"..self._itemCt
			win:_regConfig(kbKey,
				function()
					local mn=mouseNames[curKey]
					if mn then return "MOUSE:"..mn end
					return tostring(curKey):gsub("Enum.KeyCode.","")
				end,
				function(v)
					if type(v)=="string" and v:sub(1,6)=="MOUSE:" then
						local mname=v:sub(7)
						for uit,nm in pairs(mouseNames) do
							if nm==mname then
								curKey=uit; keyBtn.Text=nm
								if c.IsToggleKey and win then
									win._keybind=uit
									win._keybindIsMouse=true
								end
								if c.Callback then c.Callback(uit) end
								return
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
				GetValue=function() return curKey end,
				SetValue=function(_,k)
					curKey=k
					keyBtn.Text=bindName(k)
				end,
			}
		end


		-- ── AddColorPicker ──────────────────────────────────────────────
		function st:AddColorPicker(c)
			c=c or {}
			self._itemCt=self._itemCt+1
			local curColor = c.Default or T.ACC
			local frame=Instance.new("Frame",self._scroll)
			TS:Create(frame,_TQ,{BackgroundColor3=T.BG}):Play(); frame.BorderSizePixel=0
			frame.LayoutOrder=self._itemCt; frame.Size=UDim2.new(1,0,0,64); frame.ZIndex=3
			corner(frame,6)
			newLabel(frame,{Position=UDim2.new(0,14,0,12),Size=UDim2.new(0.6,0,0,22),
				Text=c.Title or "Color",TextColor3=T.TEXT,TextSize=16,Font=Enum.Font.GothamBold,ZIndex=4})
			newLabel(frame,{Position=UDim2.new(0,14,0,36),Size=UDim2.new(0.6,0,0,18),
				Text=c.Description or "",TextColor3=T.MUTED,TextSize=12,ZIndex=4})

			local swatch=Instance.new("TextButton",frame)
			swatch.BackgroundColor3=curColor; swatch.BorderSizePixel=0
			swatch.AnchorPoint=Vector2.new(1,0.5); swatch.Position=UDim2.new(1,-14,0.5,0)
			swatch.Size=UDim2.new(0,40,0,28); swatch.Text=""; swatch.AutoButtonColor=false; swatch.ZIndex=5
			corner(swatch,6)
			local swatchStroke=Instance.new("UIStroke",swatch)
			swatchStroke.Color=Color3.fromRGB(50,50,60); swatchStroke.Thickness=1

			-- picker popup (parented to sg so it floats above everything)
			local pickerOpen=false
			local pickerFrame=nil

			local function buildPicker()
				if pickerFrame then pickerFrame:Destroy(); pickerFrame=nil; pickerOpen=false; return end
				pickerOpen=true
				local sg=win._sg
				pickerFrame=Instance.new("Frame",sg)
				pickerFrame.BackgroundColor3=Color3.fromRGB(20,20,26)
				pickerFrame.BorderSizePixel=0; pickerFrame.ZIndex=9500
				pickerFrame.Size=UDim2.new(0,220,0,220)
				corner(pickerFrame,8)
				local stroke2=Instance.new("UIStroke",pickerFrame)
				stroke2.Color=Color3.fromRGB(50,50,60); stroke2.Thickness=1

				RS.RenderStepped:Wait()
				if not pickerFrame or not pickerFrame.Parent then return end
				local ap=swatch.AbsolutePosition; local as=swatch.AbsoluteSize
				local vp=workspace.CurrentCamera.ViewportSize
				local px=math.clamp(ap.X+as.X-220, 0, vp.X-224)
				local py=(ap.Y+as.Y+224>vp.Y) and (ap.Y-224) or (ap.Y+as.Y+4)
				pickerFrame.Position=UDim2.new(0,px,0,py)

				-- SV square (saturation/value)
				local svSize=180
				local svFrame=Instance.new("Frame",pickerFrame)
				svFrame.BackgroundColor3=Color3.fromHSV(select(1,Color3.toHSV(curColor)),1,1)
				svFrame.BorderSizePixel=0; svFrame.Position=UDim2.new(0,10,0,10)
				svFrame.Size=UDim2.new(0,svSize,0,svSize); svFrame.ZIndex=9501
				corner(svFrame,4)
				local wGrad=Instance.new("UIGradient",svFrame); wGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.new(1,1,1))}); wGrad.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})
				local svOver=Instance.new("Frame",svFrame); svOver.BackgroundColor3=Color3.new(0,0,0); svOver.BorderSizePixel=0; svOver.Size=UDim2.new(1,0,1,0); svOver.ZIndex=9502
				local bGrad=Instance.new("UIGradient",svOver); bGrad.Color=ColorSequence.new(Color3.new(0,0,0)); bGrad.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}); bGrad.Rotation=270
				corner(svOver,4)

				local h,s,v=Color3.toHSV(curColor)
				local svDot=Instance.new("Frame",svFrame)
				svDot.BackgroundColor3=Color3.new(1,1,1); svDot.BorderSizePixel=0
				svDot.Size=UDim2.new(0,10,0,10); svDot.AnchorPoint=Vector2.new(0.5,0.5)
				svDot.Position=UDim2.new(s,0,1-v,0); svDot.ZIndex=9504
				corner(svDot,50)
				local svStroke=Instance.new("UIStroke",svDot); svStroke.Color=Color3.new(0,0,0); svStroke.Thickness=1

				-- Hue slider
				local hueTrack=Instance.new("Frame",pickerFrame)
				hueTrack.BackgroundColor3=Color3.new(1,1,1); hueTrack.BorderSizePixel=0
				hueTrack.Position=UDim2.new(0,10,0,svSize+16); hueTrack.Size=UDim2.new(0,svSize,0,12); hueTrack.ZIndex=9501
				corner(hueTrack,6)
				local hueGrad=Instance.new("UIGradient",hueTrack)
				hueGrad.Color=ColorSequence.new({
					ColorSequenceKeypoint.new(0,Color3.fromHSV(0,1,1)),ColorSequenceKeypoint.new(1/6,Color3.fromHSV(1/6,1,1)),
					ColorSequenceKeypoint.new(2/6,Color3.fromHSV(2/6,1,1)),ColorSequenceKeypoint.new(3/6,Color3.fromHSV(3/6,1,1)),
					ColorSequenceKeypoint.new(4/6,Color3.fromHSV(4/6,1,1)),ColorSequenceKeypoint.new(5/6,Color3.fromHSV(5/6,1,1)),
					ColorSequenceKeypoint.new(1,Color3.fromHSV(1,1,1)),
				})
				local hDot=Instance.new("Frame",hueTrack)
				hDot.BackgroundColor3=Color3.new(1,1,1); hDot.BorderSizePixel=0
				hDot.Size=UDim2.new(0,12,0,18); hDot.AnchorPoint=Vector2.new(0.5,0.5)
				hDot.Position=UDim2.new(h,0,0.5,0); hDot.ZIndex=9503
				corner(hDot,50)
				local hDotStroke=Instance.new("UIStroke",hDot); hDotStroke.Color=Color3.new(0,0,0); hDotStroke.Thickness=1

				local function fireColor()
					curColor=Color3.fromHSV(h,s,v)
					swatch.BackgroundColor3=curColor
					if c.Callback then c.Callback(curColor) end
				end

				local function updateHueBar()
					svFrame.BackgroundColor3=Color3.fromHSV(h,1,1)
					hDot.Position=UDim2.new(h,0,0.5,0)
					fireColor()
				end
				local function updateSV()
					svDot.Position=UDim2.new(s,0,1-v,0)
					fireColor()
				end

				local draggingSV=false; local draggingH=false
				svOver.InputBegan:Connect(function(i)
					if i.UserInputType==Enum.UserInputType.MouseButton1 then
						draggingSV=true
						local rel=i.Position-svFrame.AbsolutePosition
						s=math.clamp(rel.X/svSize,0,1); v=1-math.clamp(rel.Y/svSize,0,1)
						updateSV()
					end
				end)
				hueTrack.InputBegan:Connect(function(i)
					if i.UserInputType==Enum.UserInputType.MouseButton1 then
						draggingH=true
						local rel=i.Position-hueTrack.AbsolutePosition
						h=math.clamp(rel.X/svSize,0,1)
						updateHueBar()
					end
				end)
				UIS.InputEnded:Connect(function(i)
					if i.UserInputType==Enum.UserInputType.MouseButton1 then
						draggingSV=false; draggingH=false
					end
				end)
				UIS.InputChanged:Connect(function(i)
					if i.UserInputType~=Enum.UserInputType.MouseMovement then return end
					if draggingSV then
						local rel=i.Position-svFrame.AbsolutePosition
						s=math.clamp(rel.X/svSize,0,1); v=1-math.clamp(rel.Y/svSize,0,1)
						updateSV()
					elseif draggingH then
						local rel=i.Position-hueTrack.AbsolutePosition
						h=math.clamp(rel.X/svSize,0,1)
						updateHueBar()
					end
				end)

				UIS.InputBegan:Connect(function(i)
					if i.UserInputType==Enum.UserInputType.MouseButton1 and pickerFrame then
						task.delay(0.05,function()
							if not pickerFrame then return end
							local mp=UIS:GetMouseLocation()
							local fp=pickerFrame.AbsolutePosition; local fs=pickerFrame.AbsoluteSize
							local sp=swatch.AbsolutePosition; local ss=swatch.AbsoluteSize
							local onPicker=mp.X>=fp.X and mp.X<=fp.X+fs.X and mp.Y>=fp.Y and mp.Y<=fp.Y+fs.Y
							local onSwatch=mp.X>=sp.X and mp.X<=sp.X+ss.X and mp.Y>=sp.Y and mp.Y<=sp.Y+ss.Y
							if not onPicker and not onSwatch then
								pickerFrame:Destroy(); pickerFrame=nil; pickerOpen=false
							end
						end)
					end
				end)
			end

			swatch.MouseButton1Click:Connect(buildPicker)
			frame.MouseEnter:Connect(function() TS:Create(frame,_TQ,{BackgroundColor3=Color3.fromRGB(20,20,26)}):Play() end)
			frame.MouseLeave:Connect(function() TS:Create(frame,_TQ,{BackgroundColor3=T.BG}):Play() end)

			return {
				GetValue=function() return curColor end,
				SetValue=function(_,col) curColor=col; swatch.BackgroundColor3=col end,
			}
		end
		subTabs[i]=st; subTabs[stName]=st
	end

	local tab={_win=win,_navBtn=navBtn,_navIcon=navIcon,_navLbl=navLbl,_frame=tabFrame,_subTabs=subTabs,_subDefs=subTabDefs,_activeST=nil,_title=cfg.Title or "Tab",_desc=cfg.Description or ""}
	setmetatable(tab,{__index=function(t,k) return rawget(t,"_subTabs") and rawget(t,"_subTabs")[k] end})

	tab._activeST=subTabs[1]; subTabs[1]._frame.Visible=true

	navBtn.Activated:Connect(function() win:_SelectTab(tab) end)
	navBtn.MouseEnter:Connect(function()
		if win._active~=tab then
			TS:Create(navBtn,_TQ,{BackgroundTransparency=0.85,BackgroundColor3=T.BG3}):Play()
			TS:Create(navLbl,_TQ,{TextColor3=T.TEXT}):Play()
			navIcon.ImageColor3=T.ACC
		end
	end)
	navBtn.MouseLeave:Connect(function()
		if win._active~=tab then
			TS:Create(navBtn,_TQ,{BackgroundTransparency=1}):Play()
			TS:Create(navLbl,_TQ,{TextColor3=T.MUTED}):Play()
			navIcon.ImageColor3=T.MUTED
		end
	end)

	table.insert(self._tabs,tab)
	if #self._tabs==1 then self:_SelectTab(tab) end
	return tab
end

function Lib:_SelectTab(tab)
	if self._active then
		local p=self._active
		p._frame.Visible=false
		TS:Create(p._navBtn,_TQ,{BackgroundTransparency=1}):Play()
		TS:Create(p._navLbl,_TQ,{TextColor3=T.MUTED}):Play()
		p._navIcon.ImageColor3=T.MUTED
	end
	self._active=tab; tab._frame.Visible=true
	TS:Create(tab._navBtn,_TQ,{BackgroundTransparency=0,BackgroundColor3=T.BG3}):Play()
	TS:Create(tab._navLbl,_TQ,{TextColor3=T.TEXT}):Play()
	tab._navIcon.ImageColor3=T.ACC
	self._hTitle.Text=tab._title; self._hDesc.Text=tab._desc
	for _,child in ipairs(self._stBar:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
	for i,_ in ipairs(tab._subDefs) do self:_BuildSTBtn(tab,tab._subTabs[i],i) end
end

function Lib:_BuildSTBtn(tab,st,order)
	local isActive=(tab._activeST==st)
	local btn=Instance.new("TextButton",self._stBar)
	btn.Name="STBtn_"..st._name; btn.BackgroundTransparency=1; btn.BorderSizePixel=0
	btn.LayoutOrder=order; btn.Size=UDim2.new(0,80,1,0); btn.Text=st._name
	btn.Font=Enum.Font.GothamMedium; btn.TextSize=13
	btn.TextColor3=isActive and T.TEXT or T.MUTED; btn.AutoButtonColor=false; btn.ZIndex=4

	local line=Instance.new("Frame",btn)
	line.BackgroundColor3=T.ACC; line.BorderSizePixel=0
	line.AnchorPoint=Vector2.new(0,1); line.Position=UDim2.new(0,0,1,0)
	line.Size=UDim2.new(1,0,0,2); line.BackgroundTransparency=isActive and 0 or 1; line.ZIndex=5

	btn.Activated:Connect(function()
		if tab._activeST==st then return end
		if tab._activeST then tab._activeST._frame.Visible=false end
		tab._activeST=st; st._frame.Visible=true
		for _,child in ipairs(self._stBar:GetChildren()) do
			if child:IsA("TextButton") then
				local ca=(child.Name=="STBtn_"..st._name)
				TS:Create(child,_TQ,{TextColor3=ca and T.TEXT or T.MUTED}):Play()
				local l=child:FindFirstChildOfClass("Frame")
				if l then
					l.BackgroundColor3=T.ACC
					TS:Create(l,_TQ,{BackgroundTransparency=ca and 0 or 1}):Play()
				end
			end
		end
	end)
	btn.MouseEnter:Connect(function() if tab._activeST~=st then TS:Create(btn,_TQ,{TextColor3=T.TEXT}):Play() end end)
	btn.MouseLeave:Connect(function() if tab._activeST~=st then TS:Create(btn,_TQ,{TextColor3=T.MUTED}):Play() end end)
end

function Lib:_BuildMap()
	self._mapConn=nil; self._mapFrames={}; self._mapPos={}
	local mg=Instance.new("ScreenGui"); mg.Name="SyftMap"; mg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; mg.ResetOnSpawn=false
	local ok,cg=pcall(function() return game:GetService("CoreGui") end)
	mg.Parent=ok and cg or PL.LocalPlayer.PlayerGui; self._mapGui=mg

	local mapFrame=Instance.new("Frame",mg)
	mapFrame.BackgroundColor3=T.BG; mapFrame.BorderSizePixel=0
	mapFrame.Position=UDim2.new(0,10,0.67,0); mapFrame.Size=UDim2.new(0,320,0,320)
	mapFrame.Visible=false; mapFrame.ClipsDescendants=true
	corner(mapFrame,10); self._mapFrame=mapFrame
	makeDraggable(mapFrame)

	local grid=newImg(mapFrame,{Size=UDim2.new(1,0,1,0),Image="rbxassetid://2045685837",ImageTransparency=0.88,ScaleType=Enum.ScaleType.Fit,ZIndex=1})
	corner(grid,10)

	local selfF=newFrame(mapFrame,{
		Name="Self",AnchorPoint=Vector2.new(0.5,0.5),
		Position=UDim2.new(0.5,0,0.5,0),Size=UDim2.new(0,26,0,26),ZIndex=5,
	})
	local arrowFrame=newFrame(selfF,{
		Name="ArrowFrame",
		AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,0),
		Size=UDim2.new(1,0,1,0), ZIndex=5,
	})
	local flash=newImg(arrowFrame,{
		Name="Flash",
		AnchorPoint=Vector2.new(0,0),
		Position=UDim2.new(-2.04,0,-5.88,0),
		Size=UDim2.new(0,133,0,166),
		Image="rbxassetid://96524618744154",
		ImageColor3=T.ACC, ImageTransparency=0.72, ZIndex=4,
	})
	regAcc(flash,"ImageColor3")
	local selfArrowImg=newImg(arrowFrame,{
		AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,0),
		Size=UDim2.new(1,0,1,0),
		Image="rbxassetid://94422631681576",
		ImageColor3=T.ACC, ZIndex=6,
	})
	regAcc(selfArrowImg,"ImageColor3")
	self._selfArrow=arrowFrame

	local pt=newFrame(mapFrame,{Name="PT",AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.new(0,60,0,52),Visible=false,ZIndex=4})
	local ring=Instance.new("Frame",pt); ring.Name="Ring"
	ring.BackgroundColor3=T.ACC; ring.BorderSizePixel=0
	ring.AnchorPoint=Vector2.new(0.5,0.5); ring.Position=UDim2.new(0.5,0,0.5,-4)
	ring.Size=UDim2.new(0,28,0,28); ring.ZIndex=4; corner(ring,50)
	regAcc(ring,"BackgroundColor3")
	local ph=Instance.new("ImageLabel",pt)
	ph.Name="HS"; ph.BackgroundColor3=Color3.fromRGB(30,30,40); ph.BorderSizePixel=0
	ph.AnchorPoint=Vector2.new(0.5,0.5); ph.Position=UDim2.new(0.5,0,0.5,-4)
	ph.Size=UDim2.new(0,24,0,24); ph.ZIndex=5; corner(ph,50)
	newLabel(pt,{Name="PN",AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,-2),Size=UDim2.new(1,0,0,12),TextSize=9,TextColor3=Color3.fromRGB(230,230,230),Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=5})
	local pdLbl=newLabel(pt,{Name="PD",AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,10),Size=UDim2.new(1,0,0,12),TextSize=9,TextColor3=T.ACC,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=5})
	regAcc(pdLbl,"TextColor3")
	self._pt=pt
end

function Lib:SetMapVisible(v)
	self._mapFrame.Visible=v
	if v and not self._mapConn then self:_StartMap()
	elseif not v and self._mapConn then self._mapConn:Disconnect(); self._mapConn=nil end
end

function Lib:_StartMap()
	local M=3; local SM=0.14; local map=self._mapFrame; local lp=PL.LocalPlayer
	if not self._mapRadius then self._mapRadius=130 end
	for _,p in ipairs(PL:GetPlayers()) do if p~=lp then self:_MapAddPlayer(p) end end
	PL.PlayerAdded:Connect(function(p)
		if p~=lp then task.wait(1); self:_MapAddPlayer(p) end
	end)
	PL.PlayerRemoving:Connect(function(p)
		local f=self._mapFrames[p]
		if f then
			pcall(function() f:Destroy() end)
			self._mapFrames[p]=nil
			self._mapPos[p]=nil
		end
	end)
	self._mapConn=RS.RenderStepped:Connect(function()
		local char=lp.Character; if not char then return end
		local root=char:FindFirstChild("HumanoidRootPart"); if not root then return end
		local ms=map.AbsoluteSize; local mp=root.Position; local lv=root.CFrame.LookVector
		local ta=math.deg(math.atan2(-lv.X,lv.Z)); local ca=self._selfArrow.Rotation
		self._selfArrow.Rotation=ca+((ta-ca+180)%360-180)*SM
		for tp,f in pairs(self._mapFrames) do
			local tc=tp.Character
			if tc then
				local tr=tc:FindFirstChild("HumanoidRootPart")
				if tr then
					local tpp=tr.Position; local ox=tpp.X-mp.X; local oz=tpp.Z-mp.Z
					local d=math.sqrt(ox*ox+oz*oz)
					local R=self._mapRadius
					local dl=f:FindFirstChild("PD"); if dl then dl.Text=math.floor(d/M).."m" end
					if d<=R then
						f.Visible=true
						local tx=math.clamp((-ox/R)*(ms.X/2),-ms.X/2,ms.X/2)
						local tz=math.clamp((-oz/R)*(ms.Y/2),-ms.Y/2,ms.Y/2)
						if not self._mapPos[tp] then self._mapPos[tp]={x=tx,z=tz} end
						local pos=self._mapPos[tp]; pos.x=pos.x+(tx-pos.x)*SM; pos.z=pos.z+(tz-pos.z)*SM
						f.Position=UDim2.new(0.5,pos.x,0.5,pos.z)
					else f.Visible=false; self._mapPos[tp]=nil end
				else f.Visible=false end
			else f.Visible=false end
		end
	end)
end

function Lib:_MapAddPlayer(p)
	if self._mapFrames[p] then return end
	local f=self._pt:Clone(); f.Visible=false; f.Name="Player_"..p.Name; f.Parent=self._mapFrame
	local ring2=f:FindFirstChild("Ring")
	if ring2 then regAcc(ring2,"BackgroundColor3") end
	local pd2=f:FindFirstChild("PD")
	if pd2 then regAcc(pd2,"TextColor3") end
	local nl=f:FindFirstChild("PN"); if nl then nl.Text=p.DisplayName end
	local hs=f:FindFirstChild("HS")
	task.spawn(function()
		for attempt=1,5 do
			local ok2,content=pcall(function()
				return PL:GetUserThumbnailAsync(p.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size420x420)
			end)
			if ok2 and content and content~="" and hs then
				hs.Image=content
				break
			end
			task.wait(1)
		end
	end)
	self._mapFrames[p]=f
end

function Lib:_regConfig(key, getFn, setFn)
	if not self._configItems then self._configItems={} end
	self._configItems[key]={get=getFn, set=setFn}
end

local function _enc(t)
	local out={}
	for k,v in pairs(t) do
		local ks='"'..tostring(k)..'"'; local vs
		if type(v)=="number" then vs=tostring(v)
		elseif type(v)=="boolean" then vs=v and "true" or "false"
		elseif type(v)=="string" then vs='"'..v:gsub('"','\\"')..'"'
		elseif type(v)=="table" then
			local inn={}
			for k2,v2 in pairs(v) do if type(v2)=="boolean" then table.insert(inn,'"'..tostring(k2)..'":'..( v2 and "true" or "false")) end end
			vs="{"..table.concat(inn,",").."}"
		end
		if vs then table.insert(out,ks..":"..vs) end
	end
	return "{"..table.concat(out,",").."}"
end

local function _dec(s)
	local t={}; local inner=s:match("^%s*{(.*)}%s*$") or ""
	for k,v in inner:gmatch('"([^"]+)"%s*:%s*(-?%d+%.?%d*)') do t[k]=tonumber(v) end
	for k,v in inner:gmatch('"([^"]+)"%s*:%s*(true)') do if t[k]==nil then t[k]=true end end
	for k,v in inner:gmatch('"([^"]+)"%s*:%s*(false)') do if t[k]==nil then t[k]=false end end
	for k,v in inner:gmatch('"([^"]+)"%s*:%s*"([^"]*)"') do if t[k]==nil then t[k]=v end end
	for k,v in inner:gmatch('"([^"]+)"%s*:%s*({[^}]*})') do
		local sub={}
		for k2,v2 in v:gmatch('"([^"]+)"%s*:%s*(true)') do sub[k2]=true end
		for k2,v2 in v:gmatch('"([^"]+)"%s*:%s*(false)') do if sub[k2]==nil then sub[k2]=false end end
		if next(sub) then t[k]=sub end
	end
	return t
end

function Lib:SaveConfig(name)
	if not self._configItems then return false end
	local data={}
	for k,v in pairs(self._configItems) do local ok2,val=pcall(v.get); if ok2 then data[k]=val end end
	data["__scale"]=self._scale or 1
	local ac=T.ACC
	data["__accR"]=math.floor(ac.R*255)
	data["__accG"]=math.floor(ac.G*255)
	data["__accB"]=math.floor(ac.B*255)
	data["__mapRadius"]=self._mapRadius or 130
	data["__mapVisible"]=self._mapFrame and self._mapFrame.Visible or false
	local folder=(self._logoTitle or "SyftLib"):gsub("[^%w_%-]","_")
	pcall(makefolder,"SyftLib"); pcall(makefolder,"SyftLib/"..folder)
	local ok2,err=pcall(writefile,"SyftLib/"..folder.."/"..name..".json",_enc(data))
	return ok2,err
end

function Lib:LoadConfig(name)
	if not self._configItems then return false end
	local folder=(self._logoTitle or "SyftLib"):gsub("[^%w_%-]","_")
	local ok2,content=pcall(readfile,"SyftLib/"..folder.."/"..name..".json")
	if not ok2 then return false,"Not found" end
	local data=_dec(content)
	for k,entry in pairs(self._configItems) do if data[k]~=nil then pcall(entry.set,data[k]) end end
	if data["__scale"] then pcall(function() self:SetUIScale(data["__scale"]) end) end
	if data["__accR"] then
		pcall(function()
			self:SetAccentColor(Color3.fromRGB(data["__accR"],data["__accG"],data["__accB"]))
		end)
	end
	if data["__mapRadius"] then self._mapRadius=data["__mapRadius"] end
	if data["__mapVisible"]~=nil then pcall(function() self:SetMapVisible(data["__mapVisible"]) end) end
	return true
end

function Lib:DeleteConfig(name)
	local folder=(self._logoTitle or "SyftLib"):gsub("[^%w_%-]","_")
	local ok2,err=pcall(delfile,"SyftLib/"..folder.."/"..name..".json")
	return ok2,err
end

function Lib:ListConfigs()
	local folder=(self._logoTitle or "SyftLib"):gsub("[^%w_%-]","_")
	local ok2,files=pcall(listfiles,"SyftLib/"..folder)
	if not ok2 then return {} end
	local names={}
	for _,f in ipairs(files) do local n=f:match("([^/\\]+)%.json$"); if n then table.insert(names,n) end end
	return names
end

function Lib:Destroy()
	if self._mouseConn then self._mouseConn:Disconnect(); self._mouseConn=nil end
	if self._mapConn then self._mapConn:Disconnect() end
	pcall(function() self._sg:Destroy() end)
	pcall(function() if self._mapGui then self._mapGui:Destroy() end end)
	pcall(function() if self._tsg   then self._tsg:Destroy()   end end)
	for i=#_accentObjs,1,-1   do _accentObjs[i]=nil   end
	for i=#_accentBGObjs,1,-1 do _accentBGObjs[i]=nil end
	for i=#_toggleRefs,1,-1   do _toggleRefs[i]=nil   end
end

return Lib
