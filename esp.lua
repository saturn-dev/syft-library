local Syft = loadstring(game:HttpGet("https://raw.githubusercontent.com/saturn-dev/syft-library/refs/heads/main/main/syft.lua"))()

local Win = Syft:CreateWindow({ Title = "syft.wtf", Player = true })
Win:SetKeyExpiry("6d 24h")
Win:Toast({ Title = "syft.wtf", Message = "loaded", Duration = 3 })

Win:AddCategory("COMBAT")
local ESPTab = Win:AddTab({
	Title = "Visuals", Icon = "rbxassetid://121383615519345",
	Description = "ESP, Chams and Tracers",
	SubTabs = {"ESP", "Chams", "Tracers"},
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

-- ════════════════════════════════════════════════════════════════════════════
-- SERVICES
-- ════════════════════════════════════════════════════════════════════════════
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera     = workspace.CurrentCamera
local LP         = Players.LocalPlayer

-- ════════════════════════════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════════════════════════════
local S = {
	ESPEnabled=false, TeamCheck=false, DeathCheck=true, ESPDistance=500,
	BoxType="Box 2D", FillBox=false, FillTransparency=0.7,
	ShowHealth=true, ShowDamage=true, ShowNames=true, NameType="Display",
	ShowDistance=true, ShowOutline=true,
	BoxColor=Color3.fromRGB(110,112,182), HealthColor=Color3.fromRGB(100,220,120),
	DamageColor=Color3.fromRGB(220,60,60), NameColor=Color3.fromRGB(180,180,200),
	DistColor=Color3.fromRGB(150,150,175), OutlineColor=Color3.fromRGB(0,0,0),
	ChamsEnabled=false, ChamsTrans=0.4, ChamsColor=Color3.fromRGB(70,72,130),
	SkeletonEnabled=false, SkeletonTrans=0.5, SkeletonColor=Color3.fromRGB(200,200,255),
	TracerEnabled=false, TracerOrigin="Bottom", TracerColor=Color3.fromRGB(110,112,182),
}

-- ════════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════════════════════
local function isSameTeam(plr)
	if not S.TeamCheck then return false end
	local ok, same = pcall(function() return plr.Team ~= nil and plr.Team == LP.Team end)
	return ok and same
end

local function isDead(plr)
	if not S.DeathCheck then return false end
	local char = plr.Character
	if not char then return true end
	local hum = char:FindFirstChildOfClass("Humanoid")
	return hum == nil or hum.Health <= 0
end

local function getCharParts(plr)
	local char = plr.Character
	if not char then return nil end
	local root = char:FindFirstChild("HumanoidRootPart")
	local head = char:FindFirstChild("Head")
	local hum  = char:FindFirstChildOfClass("Humanoid")
	if not root or not head or not hum then return nil end
	return char, root, head, hum
end

local function w2s(pos)
	local sp, on = Camera:WorldToViewportPoint(pos)
	return Vector2.new(sp.X, sp.Y), on, sp.Z
end

local function getBoundingBox(char)
	local min = Vector3.new(math.huge,math.huge,math.huge)
	local max = Vector3.new(-math.huge,-math.huge,-math.huge)
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			local cf, sz = part.CFrame, part.Size/2
			for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
				local c = (cf * CFrame.new(sz.X*x, sz.Y*y, sz.Z*z)).Position
				min = Vector3.new(math.min(min.X,c.X),math.min(min.Y,c.Y),math.min(min.Z,c.Z))
				max = Vector3.new(math.max(max.X,c.X),math.max(max.Y,c.Y),math.max(max.Z,c.Z))
			end end end
		end
	end
	return min, max
end

local function newLine(props)
	local d = Drawing.new("Line")
	for k,v in pairs(props or {}) do d[k]=v end
	return d
end
local function newSquare(props)
	local d = Drawing.new("Square")
	for k,v in pairs(props or {}) do d[k]=v end
	return d
end
local function newText(props)
	local d = Drawing.new("Text")
	for k,v in pairs(props or {}) do d[k]=v end
	return d
end

-- ════════════════════════════════════════════════════════════════════════════
-- ESP OBJECTS
-- ════════════════════════════════════════════════════════════════════════════
local espObjs = {}

local function createESP(plr)
	if espObjs[plr] then return end
	local o = {}
	o.lines   = {}; for i=1,4  do o.lines[i]   = newLine({Visible=false,Thickness=1,ZIndex=5}) end
	o.corners = {}; for i=1,8  do o.corners[i]  = newLine({Visible=false,Thickness=1,ZIndex=5}) end
	o.lines3d = {}; for i=1,12 do o.lines3d[i]  = newLine({Visible=false,Thickness=1,ZIndex=5}) end
	o.outline = {}; for i=1,4  do o.outline[i]  = newLine({Visible=false,Thickness=3,ZIndex=4}) end
	o.fill       = newSquare({Visible=false,Filled=true,ZIndex=4})
	o.fill3d     = newSquare({Visible=false,Filled=true,ZIndex=3})
	o.healthBg   = newSquare({Visible=false,Filled=true,Color=Color3.new(0,0,0),ZIndex=5})
	o.healthFill = newSquare({Visible=false,Filled=true,ZIndex=6})
	o.nameLbl    = newText({Visible=false,Size=13,Center=true,Outline=true,ZIndex=7,Font=2})
	o.distLbl    = newText({Visible=false,Size=11,Center=true,Outline=true,ZIndex=7,Font=2})
	o.tracer     = newLine({Visible=false,Thickness=1,ZIndex=3})
	o.dmgLabels  = {}
	o.lastHealth = 100
	espObjs[plr] = o
end

local function removeESP(plr)
	local o = espObjs[plr]; if not o then return end
	for _,l in ipairs(o.lines)   do pcall(function() l:Remove() end) end
	for _,l in ipairs(o.corners) do pcall(function() l:Remove() end) end
	for _,l in ipairs(o.lines3d) do pcall(function() l:Remove() end) end
	for _,l in ipairs(o.outline) do pcall(function() l:Remove() end) end
	for _,d in ipairs(o.dmgLabels) do pcall(function() d:Remove() end) end
	pcall(function() o.fill:Remove() end)
	pcall(function() o.fill3d:Remove() end)
	pcall(function() o.healthBg:Remove() end)
	pcall(function() o.healthFill:Remove() end)
	pcall(function() o.nameLbl:Remove() end)
	pcall(function() o.distLbl:Remove() end)
	pcall(function() o.tracer:Remove() end)
	espObjs[plr] = nil
end

local function hideESP(plr)
	local o = espObjs[plr]; if not o then return end
	for _,l in ipairs(o.lines)   do l.Visible=false end
	for _,l in ipairs(o.corners) do l.Visible=false end
	for _,l in ipairs(o.lines3d) do l.Visible=false end
	for _,l in ipairs(o.outline) do l.Visible=false end
	o.fill.Visible=false; o.fill3d.Visible=false
	o.healthBg.Visible=false; o.healthFill.Visible=false
	o.nameLbl.Visible=false; o.distLbl.Visible=false; o.tracer.Visible=false
end

local function spawnDmg(o, pos, amt)
	local dmg = newText({Visible=true,Size=15,Center=true,Outline=true,ZIndex=8,Font=2,
		Color=S.DamageColor, Text="-"..math.floor(amt), Position=pos})
	table.insert(o.dmgLabels, dmg)
	local t=0; local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		t=t+dt
		dmg.Position=Vector2.new(pos.X, pos.Y-t*40)
		dmg.Transparency=math.clamp(t/1.2,0,1)
		if t>=1.2 then
			pcall(function() dmg:Remove() end)
			for i,d in ipairs(o.dmgLabels) do if d==dmg then table.remove(o.dmgLabels,i) break end end
			conn:Disconnect()
		end
	end)
end

-- ════════════════════════════════════════════════════════════════════════════
-- CHAMS  (Highlight on each part, not SelectionBox)
-- ════════════════════════════════════════════════════════════════════════════
local chamsObjs = {}  -- [plr] = {Highlight, ...}

local function createCham(plr)
	if chamsObjs[plr] then return end
	local char = plr.Character; if not char then return end
	local highlights = {}
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			local hl = Instance.new("SelectionBox")
			hl.Adornee = part
			hl.SurfaceTransparency = S.ChamsTrans
			hl.SurfaceColor3 = S.ChamsColor
			hl.LineThickness = 0
			hl.Parent = part
			table.insert(highlights, hl)
		end
	end
	chamsObjs[plr] = highlights
end

local function removeCham(plr)
	if not chamsObjs[plr] then return end
	for _, hl in ipairs(chamsObjs[plr]) do pcall(function() hl:Destroy() end) end
	chamsObjs[plr] = nil
end

-- ════════════════════════════════════════════════════════════════════════════
-- SKELETON
-- ════════════════════════════════════════════════════════════════════════════
local R15 = {
	{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
	{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
	{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
	{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
	{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
}
local R6 = {
	{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},
	{"Torso","Left Leg"},{"Torso","Right Leg"},
}
local skelLines = {}  -- [plr] = {Line, ...}  (14 lines max)

local function createSkeleton(plr)
	if skelLines[plr] then return end
	local lines = {}
	for i=1,14 do lines[i]=newLine({Visible=false,Thickness=1,ZIndex=4}) end
	skelLines[plr] = lines
end

local function removeSkeleton(plr)
	if not skelLines[plr] then return end
	for _,l in ipairs(skelLines[plr]) do pcall(function() l:Remove() end) end
	skelLines[plr] = nil
end

local function updateSkeleton(plr)
	local lines = skelLines[plr]; if not lines then return end
	local char = plr.Character
	if not char then for _,l in ipairs(lines) do l.Visible=false end return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then for _,l in ipairs(lines) do l.Visible=false end return end
	local joints = hum.RigType==Enum.HumanoidRigType.R6 and R6 or R15
	for i=1,14 do
		local l = lines[i]; if not l then break end
		local pair = joints[i]
		if not pair then l.Visible=false; break end
		local pA = char:FindFirstChild(pair[1])
		local pB = char:FindFirstChild(pair[2])
		if pA and pB then
			local sA,onA = w2s(pA.Position)
			local sB,onB = w2s(pB.Position)
			if onA and onB then
				l.From=sA; l.To=sB
				l.Color=S.SkeletonColor; l.Transparency=S.SkeletonTrans; l.Visible=true
			else l.Visible=false end
		else l.Visible=false end
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- RENDER LOOP
-- ════════════════════════════════════════════════════════════════════════════
local function setLine(l,from,to,color,thick)
	l.From=from; l.To=to; l.Color=color; l.Thickness=thick or 1; l.Visible=true
end

RunService.RenderStepped:Connect(function()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr==LP then
		elseif isSameTeam(plr) or isDead(plr) then
			hideESP(plr)
			if S.SkeletonEnabled and skelLines[plr] then
				for _,l in ipairs(skelLines[plr]) do l.Visible=false end
			end
		else
			repeat
				local o = espObjs[plr]; if not o then break end
				local char,root,head,hum = getCharParts(plr)
				if not char or not S.ESPEnabled then hideESP(plr); break end

				local lpChar = LP.Character
				local dist = (lpChar and lpChar:FindFirstChild("HumanoidRootPart"))
					and math.floor((lpChar.HumanoidRootPart.Position - root.Position).Magnitude) or 0
				if dist > S.ESPDistance then hideESP(plr); break end

				-- Bounding box
				local minW,maxW = getBoundingBox(char)
				local pts3d = {
					Vector3.new(minW.X,minW.Y,minW.Z), Vector3.new(maxW.X,minW.Y,minW.Z),
					Vector3.new(maxW.X,maxW.Y,minW.Z), Vector3.new(minW.X,maxW.Y,minW.Z),
					Vector3.new(minW.X,minW.Y,maxW.Z), Vector3.new(maxW.X,minW.Y,maxW.Z),
					Vector3.new(maxW.X,maxW.Y,maxW.Z), Vector3.new(minW.X,maxW.Y,maxW.Z),
				}
				local c2d = {}; local minDepth = math.huge
				for _,wp in ipairs(pts3d) do
					local sp,on,depth = w2s(wp)
					table.insert(c2d, sp)
					if depth < minDepth then minDepth=depth end
				end
				if minDepth < 0 then hideESP(plr); break end

				local minX,minY,maxX,maxY = math.huge,math.huge,-math.huge,-math.huge
				for _,p in ipairs(c2d) do
					minX=math.min(minX,p.X); minY=math.min(minY,p.Y)
					maxX=math.max(maxX,p.X); maxY=math.max(maxY,p.Y)
				end
				local bx,by,bw,bh = minX,minY,maxX-minX,maxY-minY
				local bc = S.BoxColor

				for _,l in ipairs(o.lines)   do l.Visible=false end
				for _,l in ipairs(o.corners) do l.Visible=false end
				for _,l in ipairs(o.lines3d) do l.Visible=false end
				for _,l in ipairs(o.outline) do l.Visible=false end
				o.fill.Visible=false; o.fill3d.Visible=false

				local tl=Vector2.new(bx,by); local tr=Vector2.new(bx+bw,by)
				local bl=Vector2.new(bx,by+bh); local br=Vector2.new(bx+bw,by+bh)

				if S.BoxType=="Box 2D" then
					setLine(o.lines[1],tl,tr,bc); setLine(o.lines[2],tr,br,bc)
					setLine(o.lines[3],br,bl,bc); setLine(o.lines[4],bl,tl,bc)
					if S.ShowOutline then
						local oc=S.OutlineColor
						setLine(o.outline[1],tl,tr,oc,3); setLine(o.outline[2],tr,br,oc,3)
						setLine(o.outline[3],br,bl,oc,3); setLine(o.outline[4],bl,tl,oc,3)
					end
					if S.FillBox then
						o.fill.Position=tl; o.fill.Size=Vector2.new(bw,bh)
						o.fill.Color=bc; o.fill.Transparency=S.FillTransparency; o.fill.Visible=true
					end
				elseif S.BoxType=="Corners" then
					local cL=math.min(bw,bh)*0.25
					setLine(o.corners[1],tl,tl+Vector2.new(cL,0),bc)
					setLine(o.corners[2],tl,tl+Vector2.new(0,cL),bc)
					setLine(o.corners[3],tr,tr+Vector2.new(-cL,0),bc)
					setLine(o.corners[4],tr,tr+Vector2.new(0,cL),bc)
					setLine(o.corners[5],bl,bl+Vector2.new(cL,0),bc)
					setLine(o.corners[6],bl,bl+Vector2.new(0,-cL),bc)
					setLine(o.corners[7],br,br+Vector2.new(-cL,0),bc)
					setLine(o.corners[8],br,br+Vector2.new(0,-cL),bc)
				elseif S.BoxType=="Box 3D" then
					local edges={{1,2},{2,3},{3,4},{4,1},{5,6},{6,7},{7,8},{8,5},{1,5},{2,6},{3,7},{4,8}}
					for i,e in ipairs(edges) do
						if o.lines3d[i] then setLine(o.lines3d[i],c2d[e[1]],c2d[e[2]],bc) end
					end
					if S.FillBox then
						o.fill.Position=tl; o.fill.Size=Vector2.new(bw,bh)
						o.fill.Color=bc; o.fill.Transparency=S.FillTransparency; o.fill.Visible=true
					end
				end

				-- Health bar
				local hp = math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1)
				if S.ShowHealth then
					local hbX=bx-6
					o.healthBg.Position=Vector2.new(hbX-2,by); o.healthBg.Size=Vector2.new(4,bh); o.healthBg.Visible=true
					o.healthFill.Position=Vector2.new(hbX-2,by+bh*(1-hp))
					o.healthFill.Size=Vector2.new(4,bh*hp)
					o.healthFill.Color=S.HealthColor; o.healthFill.Visible=true
				else o.healthBg.Visible=false; o.healthFill.Visible=false end

				-- Damage
				if S.ShowDamage then
					local curHp=hum.Health
					if o.lastHealth-curHp > 0.5 then
						local hs,_ = w2s(head.Position)
						spawnDmg(o, hs-Vector2.new(0,bh*0.4), o.lastHealth-curHp)
					end
					o.lastHealth=curHp
				end

				-- Name
				if S.ShowNames then
					o.nameLbl.Text=(S.NameType=="Display") and plr.DisplayName or plr.Name
					o.nameLbl.Color=S.NameColor
					o.nameLbl.Position=Vector2.new(bx+bw/2,by-16); o.nameLbl.Visible=true
				else o.nameLbl.Visible=false end

				-- Distance
				if S.ShowDistance then
					o.distLbl.Text=dist.."m"; o.distLbl.Color=S.DistColor
					o.distLbl.Position=Vector2.new(bx+bw/2,by+bh+4); o.distLbl.Visible=true
				else o.distLbl.Visible=false end

				-- Tracer
				if S.TracerEnabled then
					local vp=Camera.ViewportSize
					local oy = S.TracerOrigin=="Top" and 0 or (S.TracerOrigin=="Middle" and vp.Y/2 or vp.Y)
					o.tracer.From=Vector2.new(vp.X/2,oy); o.tracer.To=Vector2.new(bx+bw/2,by+bh/2)
					o.tracer.Color=S.TracerColor; o.tracer.Visible=true
				else o.tracer.Visible=false end

				-- Skeleton (per-player update each frame)
				if S.SkeletonEnabled then updateSkeleton(plr)
				elseif skelLines[plr] then
					for _,l in ipairs(skelLines[plr]) do l.Visible=false end
				end

			until true
		end
	end
end)

-- ════════════════════════════════════════════════════════════════════════════
-- PLAYER LIFECYCLE
-- ════════════════════════════════════════════════════════════════════════════
local function setupPlayer(plr)
	createESP(plr)
	if S.ChamsEnabled then createCham(plr) end
	if S.SkeletonEnabled then createSkeleton(plr) end
	plr.CharacterAdded:Connect(function()
		task.wait(1)
		removeESP(plr); removeCham(plr); removeSkeleton(plr)
		createESP(plr)
		if S.ChamsEnabled then createCham(plr) end
		if S.SkeletonEnabled then createSkeleton(plr) end
	end)
end

for _, plr in ipairs(Players:GetPlayers()) do
	if plr~=LP then setupPlayer(plr) end
end
Players.PlayerAdded:Connect(function(plr)
	if plr~=LP then setupPlayer(plr) end
end)
Players.PlayerRemoving:Connect(function(plr)
	removeESP(plr); removeCham(plr); removeSkeleton(plr)
end)

-- ════════════════════════════════════════════════════════════════════════════
-- ESP UI
-- ════════════════════════════════════════════════════════════════════════════
ESPTab.ESP:AddToggle({ Title="Enable ESP", Description="show player boxes", Default=false,
	Callback=function(v) S.ESPEnabled=v; if not v then for _,p in ipairs(Players:GetPlayers()) do hideESP(p) end end end })
ESPTab.ESP:AddToggle({ Title="Team Check", Description="skip teammates", Default=false,
	Callback=function(v) S.TeamCheck=v end })
ESPTab.ESP:AddToggle({ Title="Death Check", Description="hide esp on dead players", Default=true,
	Callback=function(v) S.DeathCheck=v end })
ESPTab.ESP:AddSlider({ Title="ESP Distance", Description="max stud range", Min=50, Max=2000, Default=500,
	Callback=function(v) S.ESPDistance=v end })
ESPTab.ESP:AddDivider({ Title="Box" })
ESPTab.ESP:AddDropdown({ Title="Box Type", Options={"Box 2D","Box 3D","Corners","None"}, Default="Box 2D",
	Callback=function(v) S.BoxType=v end })
ESPTab.ESP:AddToggle({ Title="Fill Box", Description="fill inside the box", Default=false,
	Callback=function(v) S.FillBox=v end })
ESPTab.ESP:AddSlider({ Title="Fill Transparency", Description="1=solid 10=invisible", Min=1, Max=10, Default=7,
	Callback=function(v) S.FillTransparency=v/10 end })
ESPTab.ESP:AddDivider({ Title="Extra" })
ESPTab.ESP:AddToggle({ Title="Show Health", Description="vertical bar on left", Default=true,
	Callback=function(v) S.ShowHealth=v end })
ESPTab.ESP:AddToggle({ Title="Show Damage", Description="floating damage numbers", Default=true,
	Callback=function(v) S.ShowDamage=v end })
ESPTab.ESP:AddToggle({ Title="Show Names", Default=true,
	Callback=function(v) S.ShowNames=v end })
ESPTab.ESP:AddDropdown({ Title="Name Type", Options={"Display","Username"}, Default="Display",
	Callback=function(v) S.NameType=v end })
ESPTab.ESP:AddToggle({ Title="Show Distance", Default=true,
	Callback=function(v) S.ShowDistance=v end })
ESPTab.ESP:AddDivider({ Title="Colors" })
ESPTab.ESP:AddColorPicker({ Title="Box Color", Default=S.BoxColor, Callback=function(c) S.BoxColor=c end })
ESPTab.ESP:AddColorPicker({ Title="Health Color", Default=S.HealthColor, Callback=function(c) S.HealthColor=c end })
ESPTab.ESP:AddColorPicker({ Title="Damage Color", Default=S.DamageColor, Callback=function(c) S.DamageColor=c end })
ESPTab.ESP:AddColorPicker({ Title="Name Color", Default=S.NameColor, Callback=function(c) S.NameColor=c end })
ESPTab.ESP:AddColorPicker({ Title="Distance Color", Default=S.DistColor, Callback=function(c) S.DistColor=c end })
ESPTab.ESP:AddToggle({ Title="Show Outline", Default=true, Callback=function(v) S.ShowOutline=v end })
ESPTab.ESP:AddColorPicker({ Title="Outline Color", Default=S.OutlineColor, Callback=function(c) S.OutlineColor=c end })

-- ════════════════════════════════════════════════════════════════════════════
-- CHAMS UI
-- ════════════════════════════════════════════════════════════════════════════
ESPTab.Chams:AddToggle({ Title="Enable Chams", Description="highlight each body part", Default=false,
	Callback=function(v)
		S.ChamsEnabled=v
		if v then for _,p in ipairs(Players:GetPlayers()) do if p~=LP then createCham(p) end end
		else for p in pairs(chamsObjs) do removeCham(p) end end
	end })
ESPTab.Chams:AddSlider({ Title="Chams Transparency", Min=1, Max=9, Default=4,
	Callback=function(v)
		S.ChamsTrans=v/10
		for _,hls in pairs(chamsObjs) do for _,hl in ipairs(hls) do hl.SurfaceTransparency=S.ChamsTrans end end
	end })
ESPTab.Chams:AddColorPicker({ Title="Chams Color", Default=S.ChamsColor,
	Callback=function(c)
		S.ChamsColor=c
		for _,hls in pairs(chamsObjs) do for _,hl in ipairs(hls) do hl.SurfaceColor3=c end end
	end })
ESPTab.Chams:AddDivider()
ESPTab.Chams:AddToggle({ Title="Enable Skeleton", Description="draw bones on players", Default=false,
	Callback=function(v)
		S.SkeletonEnabled=v
		if v then for _,p in ipairs(Players:GetPlayers()) do if p~=LP then createSkeleton(p) end end
		else
			for p,lines in pairs(skelLines) do
				for _,l in ipairs(lines) do l.Visible=false end
			end
		end
	end })
ESPTab.Chams:AddSlider({ Title="Skeleton Transparency", Min=1, Max=9, Default=5,
	Callback=function(v) S.SkeletonTrans=v/10 end })
ESPTab.Chams:AddColorPicker({ Title="Skeleton Color", Default=S.SkeletonColor,
	Callback=function(c) S.SkeletonColor=c end })

-- ════════════════════════════════════════════════════════════════════════════
-- TRACERS UI
-- ════════════════════════════════════════════════════════════════════════════
ESPTab.Tracers:AddToggle({ Title="Enable Tracers", Default=false, Callback=function(v) S.TracerEnabled=v end })
ESPTab.Tracers:AddDropdown({ Title="Tracer Origin", Options={"Top","Middle","Bottom"}, Default="Bottom",
	Callback=function(v) S.TracerOrigin=v end })
ESPTab.Tracers:AddColorPicker({ Title="Tracer Color", Default=S.TracerColor, Callback=function(c) S.TracerColor=c end })

-- ════════════════════════════════════════════════════════════════════════════
-- CONFIG TAB
-- ════════════════════════════════════════════════════════════════════════════
local _cfgNameBox, _savedDropdown
local function _refreshList()
	local configs = Win:ListConfigs()
	if #configs==0 then configs={"(none)"} end
	if _savedDropdown then _savedDropdown:SetOptions(configs) end
end
ConfigTab.Configs:AddDivider({ Title="Save" })
_cfgNameBox = ConfigTab.Configs:AddTextbox({ Title="Config name", Placeholder="my_config", Default="" })
ConfigTab.Configs:AddButton({ Title="Save", Description="writes to file",
	Callback=function()
		local name=_cfgNameBox:GetValue()
		if name=="" then Win:Toast({Title="no name",Message="type a name first",Duration=2}); return end
		local ok,err=Win:SaveConfig(name)
		if ok then Win:Toast({Title="saved",Message=name..".json",Duration=3}); _refreshList()
		else Win:Toast({Title="save failed",Message=tostring(err),Duration=4}) end
	end })
ConfigTab.Configs:AddDivider({ Title="Load" })
local initC=Win:ListConfigs(); if #initC==0 then initC={"(none)"} end
_savedDropdown=ConfigTab.Configs:AddDropdown({Title="Saved configs",Options=initC,Default=initC[1]})
ConfigTab.Configs:AddButton({ Title="Load",
	Callback=function()
		local name=_savedDropdown:GetValue()
		if name==""or name=="(none)" then Win:Toast({Title="nothing selected",Duration=2}); return end
		local ok,err=Win:LoadConfig(name)
		if ok then Win:Toast({Title="loaded",Message=name.." applied",Duration=3})
		else Win:Toast({Title="load failed",Message=tostring(err),Duration=4}) end
	end })
ConfigTab.Configs:AddDivider()
ConfigTab.Configs:AddButton({ Title="Refresh list",
	Callback=function()
		_refreshList()
		local n=#Win:ListConfigs()
		Win:Toast({Title=n==0 and "nothing found" or "refreshed",Message=n.." config(s)",Duration=2})
	end })
ConfigTab.Configs:AddButton({ Title="Delete",
	Callback=function()
		local name=_savedDropdown:GetValue()
		if name==""or name=="(none)" then Win:Toast({Title="nothing selected",Duration=2}); return end
		local ok,err=Win:DeleteConfig(name)
		if ok then Win:Toast({Title="deleted",Message=name.." removed",Duration=3}); _refreshList()
		else Win:Toast({Title="delete failed",Message=tostring(err),Duration=4}) end
	end })

-- ════════════════════════════════════════════════════════════════════════════
-- CUSTOMIZE TAB
-- ════════════════════════════════════════════════════════════════════════════
UITab.UI:AddToggle({ Title="Unlock mouse", Description="frees cursor when ui is open", Default=false,
	Callback=function(v) Win:SetMouseUnlock(v) end })
UITab.UI:AddToggle({ Title="Minimap", Description="radar of nearby players", Default=false,
	Callback=function(v) Win:SetMapVisible(v) end })
UITab.UI:AddSlider({ Title="Map zoom", Min=20, Max=700, Default=130,
	Callback=function(v) Win._mapRadius=v end })
UITab.UI:AddDropdown({ Title="Accent color",
	Options={"Purple","Red","Green","Cyan","Orange","Pink"}, Default="Purple",
	Callback=function(v)
		local colors={Purple=Color3.fromRGB(110,112,182),Red=Color3.fromRGB(200,60,60),
			Green=Color3.fromRGB(60,190,100),Cyan=Color3.fromRGB(60,180,200),
			Orange=Color3.fromRGB(210,130,50),Pink=Color3.fromRGB(200,80,160)}
		if colors[v] then Win:SetAccentColor(colors[v]); Win:Toast({Title="theme",Message=v,Duration=2}) end
	end })
UITab.UI:AddTextbox({ Title="UI scale", Description="60-150", Placeholder="100", Default="100",
	Callback=function(text)
		local n=tonumber(text)
		if n then Win:SetUIScale(math.clamp(n,60,150)/100) end
	end })
UITab.UI:AddKeybind({ Title="Toggle keybind", Default=Enum.KeyCode.RightShift,
	IsToggleKey=true, MouseBinds=true,
	Callback=function(key)
		Win:Toast({Title="keybind",Message=tostring(key):gsub("Enum.KeyCode.",""):gsub("Enum.UserInputType.",""),Duration=2})
	end })
UITab.Misc:AddButton({ Title="Test toast",
	Callback=function() Win:Toast({Title="test",Message="this is a toast",Duration=3}) end })
UITab.Misc:AddDivider({ Title="Danger Zone" })
UITab.Misc:AddButton({ Title="Unload", Icon="rbxassetid://88930748781568",
	Callback=function()
		Win:Toast({Title="unloading",Message="bye",Duration=2})
		task.delay(0.5,function() Win:Destroy() end)
	end })
