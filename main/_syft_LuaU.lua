SyftLib = {}
SyftLib.__index = SyftLib

local Players = game:GetService("Players")
local Mouse = Players.LocalPlayer:GetMouse()
local drawings = {}
local openDD = nil

local C = {
    base    = Color3.fromRGB(24,24,37),
    mantle  = Color3.fromRGB(18,18,28),
    crust   = Color3.fromRGB(14,14,22),
    surface0= Color3.fromRGB(36,36,54),
    surface1= Color3.fromRGB(44,44,66),
    surface2= Color3.fromRGB(54,54,80),
    overlay0= Color3.fromRGB(108,108,138),
    overlay1= Color3.fromRGB(127,127,159),
    text    = Color3.fromRGB(205,214,244),
    subtext1= Color3.fromRGB(166,173,200),
    subtext0= Color3.fromRGB(147,153,178),
    lavender= Color3.fromRGB(180,190,254),
    mauve   = Color3.fromRGB(203,166,247),
    pink    = Color3.fromRGB(245,194,231),
    red     = Color3.fromRGB(243,139,168),
    peach   = Color3.fromRGB(250,179,135),
    green   = Color3.fromRGB(166,227,161),
    teal    = Color3.fromRGB(148,226,213),
    blue    = Color3.fromRGB(137,180,250),
    wht     = Color3.fromRGB(255,255,255),
}
C.acc=C.mauve; C.brd=C.surface1; C.brd2=C.surface2

local THEMES = {
    Mocha = {
        base=Color3.fromRGB(24,24,37),mantle=Color3.fromRGB(18,18,28),crust=Color3.fromRGB(14,14,22),
        surface0=Color3.fromRGB(36,36,54),surface1=Color3.fromRGB(44,44,66),surface2=Color3.fromRGB(54,54,80),
        overlay0=Color3.fromRGB(108,108,138),overlay1=Color3.fromRGB(127,127,159),
        text=Color3.fromRGB(205,214,244),subtext1=Color3.fromRGB(166,173,200),subtext0=Color3.fromRGB(147,153,178),
        lavender=Color3.fromRGB(180,190,254),acc=Color3.fromRGB(203,166,247),
    },
    Midnight = {
        base=Color3.fromRGB(10,10,20),mantle=Color3.fromRGB(6,6,14),crust=Color3.fromRGB(4,4,10),
        surface0=Color3.fromRGB(20,22,40),surface1=Color3.fromRGB(28,30,52),surface2=Color3.fromRGB(36,40,65),
        overlay0=Color3.fromRGB(90,100,140),overlay1=Color3.fromRGB(110,120,160),
        text=Color3.fromRGB(210,215,255),subtext1=Color3.fromRGB(160,170,210),subtext0=Color3.fromRGB(130,140,180),
        lavender=Color3.fromRGB(160,180,255),acc=Color3.fromRGB(100,140,255),
    },
    Nord = {
        base=Color3.fromRGB(46,52,64),mantle=Color3.fromRGB(36,42,52),crust=Color3.fromRGB(28,34,44),
        surface0=Color3.fromRGB(59,66,82),surface1=Color3.fromRGB(67,76,94),surface2=Color3.fromRGB(76,86,106),
        overlay0=Color3.fromRGB(136,192,208),overlay1=Color3.fromRGB(129,161,193),
        text=Color3.fromRGB(236,239,244),subtext1=Color3.fromRGB(216,222,233),subtext0=Color3.fromRGB(196,202,213),
        lavender=Color3.fromRGB(136,192,208),acc=Color3.fromRGB(136,192,208),
    },
    Dracula = {
        base=Color3.fromRGB(40,42,54),mantle=Color3.fromRGB(30,32,44),crust=Color3.fromRGB(22,24,36),
        surface0=Color3.fromRGB(52,55,70),surface1=Color3.fromRGB(62,65,82),surface2=Color3.fromRGB(72,76,96),
        overlay0=Color3.fromRGB(98,114,164),overlay1=Color3.fromRGB(110,128,180),
        text=Color3.fromRGB(248,248,242),subtext1=Color3.fromRGB(200,200,194),subtext0=Color3.fromRGB(160,160,154),
        lavender=Color3.fromRGB(189,147,249),acc=Color3.fromRGB(189,147,249),
    },
    GruvboxDark = {
        base=Color3.fromRGB(40,40,40),mantle=Color3.fromRGB(30,30,30),crust=Color3.fromRGB(22,22,22),
        surface0=Color3.fromRGB(50,48,47),surface1=Color3.fromRGB(60,56,54),surface2=Color3.fromRGB(80,73,69),
        overlay0=Color3.fromRGB(146,131,116),overlay1=Color3.fromRGB(168,153,132),
        text=Color3.fromRGB(235,219,178),subtext1=Color3.fromRGB(213,196,161),subtext0=Color3.fromRGB(189,174,147),
        lavender=Color3.fromRGB(131,165,152),acc=Color3.fromRGB(214,93,14),
    },
}

local function applyTheme(t)
    C.base=t.base; C.mantle=t.mantle; C.crust=t.crust
    C.surface0=t.surface0; C.surface1=t.surface1; C.surface2=t.surface2
    C.overlay0=t.overlay0; C.overlay1=t.overlay1
    C.text=t.text; C.subtext1=t.subtext1; C.subtext0=t.subtext0
    C.lavender=t.lavender; C.mauve=t.acc; C.acc=t.acc
    C.brd=t.surface1; C.brd2=t.surface2
end


local FONT=Drawing.Fonts.System; local FONTB=Drawing.Fonts.SystemBold
local FS=14; local FSS=13; local FSX=12
local TB=38; local IH=28; local BH=30; local SH=44; local DIH=24; local PAD=12; local CP=8

local KCODES={
    None=0,Space=0x20,Enter=0x0D,Backspace=0x08,Escape=0x1B,Delete=0x2E,Insert=0x2D,
    F1=0x70,F2=0x71,F3=0x72,F4=0x73,F5=0x74,F6=0x75,F7=0x76,F8=0x77,F9=0x78,F10=0x79,F11=0x7A,F12=0x7B,
    A=0x41,B=0x42,C=0x43,D=0x44,E=0x45,F=0x46,G=0x47,H=0x48,I=0x49,J=0x4A,K=0x4B,L=0x4C,M=0x4D,
    N=0x4E,O=0x4F,P=0x50,Q=0x51,R=0x52,S=0x53,T=0x54,U=0x55,V=0x56,W=0x57,X=0x58,Y=0x59,Z=0x5A,
    Num0=0x30,Num1=0x31,Num2=0x32,Num3=0x33,Num4=0x34,Num5=0x35,Num6=0x36,Num7=0x37,Num8=0x38,Num9=0x39,
}
local KNAMES={}; for k,v in pairs(KCODES) do KNAMES[v]=k end

local function D(t,p)
    local o=Drawing.new(t); for k,v in pairs(p) do o[k]=v end
    table.insert(drawings,o); return o
end
local function mp() return Vector2.new(Mouse.X,Mouse.Y) end
local function over(pos,sz)
    local m=mp()
    return m.X>=pos.X and m.X<=pos.X+sz.X and m.Y>=pos.Y and m.Y<=pos.Y+sz.Y
end
local function tw(s,sz) return #s*(sz or FS)*0.52 end
local function lN(a,b,t) return a+(b-a)*t end
local function lC(a,b,t)
    if not a or not b then return a or b or C.surface0 end
    return Color3.new(a.R+(b.R-a.R)*t,a.G+(b.G-a.G)*t,a.B+(b.B-a.B)*t)
end
local function hsv(h,s,v)
    local i=math.floor(h*6)%6; local f=h*6-math.floor(h*6)
    local p=v*(1-s); local q=v*(1-f*s); local t2=v*(1-(1-f)*s)
    if i==0 then return Color3.new(v,t2,p) elseif i==1 then return Color3.new(q,v,p)
    elseif i==2 then return Color3.new(p,v,t2) elseif i==3 then return Color3.new(p,q,v)
    elseif i==4 then return Color3.new(t2,p,v) else return Color3.new(v,p,q) end
end
local function hx(c)
    return string.format("#%02x%02x%02x",math.floor(c.R*255+.5),math.floor(c.G*255+.5),math.floor(c.B*255+.5))
end

function SyftLib.new(title)
    local self=setmetatable({},SyftLib)
    self.title=title or "SyftLib"; self.tabs={}; self.tnames={}
    self.activeTab=1; self.px=200; self.py=100; self.sw=660; self.sh=500
    self.visible=true; self.doSearch=false; self.query=""
    self.sfocus=false; self.kdown={}; self.toggleKey=0x2D; self.scrollY={}
    return self
end
function SyftLib:Search() self.doSearch=true end

function SyftLib:SetTheme(name)
    local t=THEMES[name]
    if t then
        applyTheme(t)
        if self._rebuild then self._rebuild() end
    end
end

function SyftLib:GetThemeNames()
    local r={}; for k in pairs(THEMES) do table.insert(r,k) end; table.sort(r); return r
end


function SyftLib:Tab(name)
    local tab={name=name,sections={}}
    table.insert(self.tabs,tab); table.insert(self.tnames,name)
    if #self.tabs==1 then self.activeTab=1 end
    local lib=self
    function tab:Section(title)
        local sec={title=title,tab=name,items={}}
        table.insert(self.sections,sec)
        function sec:Label(text,tip) table.insert(self.items,{kind="lbl",text=text,tip=tip}) end
        function sec:Divider(lbl) table.insert(self.items,{kind="div",label=lbl or ""}) end
        function sec:Toggle(lbl,def,cb) table.insert(self.items,{kind="tog",label=lbl,val=def==true,cb=cb,_at=def and 1 or 0}) end
        function sec:Slider(lbl,mn,mx,def,sfx,cb)
            table.insert(self.items,{kind="sld",label=lbl,min=mn,max=mx,val=math.clamp(def or mn,mn,mx),sfx=sfx or "",cb=cb,_tx=nil})
        end
        function sec:Button(lbl,cb) table.insert(self.items,{kind="btn",label=lbl,cb=cb,_hc=0}) end
        function sec:Dropdown(lbl,opts,cb) table.insert(self.items,{kind="dd",label=lbl,opts=opts,sel=opts[1] or "",cb=cb,open=false,_hc=0}) end
        function sec:MultiDropdown(lbl,opts,cb) table.insert(self.items,{kind="mdd",label=lbl,opts=opts,sel={},cb=cb,open=false,_hc=0}) end
        function sec:ColorPicker(lbl,def,cb) table.insert(self.items,{kind="cp",label=lbl,col=def or C.acc,cb=cb,ch=0.75,cs=0.4,cv=0.97}) end
        function sec:TextBox(lbl,ph,cb) table.insert(self.items,{kind="tb",label=lbl,placeholder=ph or "",val="",cb=cb,focused=false}) end
        function sec:Keybind(lbl,dk,cb) table.insert(self.items,{kind="kb",label=lbl,kc=KCODES[dk] or 0x58,cb=cb,binding=false}) end
        return sec
    end
    return tab
end

local function iH(it)
    if it.kind=="lbl" then return IH elseif it.kind=="div" then return 18
    elseif it.kind=="tog" then return IH elseif it.kind=="sld" then return SH
    elseif it.kind=="btn" then return BH+6
    elseif it.kind=="dd" or it.kind=="mdd" then return BH+6+(it.open and (#it.opts*DIH+8) or 0)
    elseif it.kind=="cp" then return IH elseif it.kind=="tb" then return IH+BH+4
    elseif it.kind=="kb" then return IH end; return 0
end
local function secVis(sec,q)
    if not q or q=="" then return true end
    for _,it in ipairs(sec.items) do
        local nm=(it.text or it.label or ""):lower()
        if nm:find(q:lower(),1,true) then return true end
    end; return false
end
local function secH(sec,q)
    local h=32; local any=false
    for _,it in ipairs(sec.items) do
        local nm=(it.text or it.label or ""):lower()
        local vis=(not q or q=="") or nm:find(q:lower(),1,true)~=nil
        if vis then h=h+iH(it); any=true end
    end
    return any and h+8 or 0
end

function SyftLib:Open()
    local lib=self

    local winBg =D("Square",{Filled=true,Color=C.base,Size=Vector2.new(lib.sw,lib.sh),Position=Vector2.new(lib.px,lib.py),Corner=10,ZIndex=5,Visible=true})
    local winBrd=D("Square",{Filled=false,Color=C.brd,Size=Vector2.new(lib.sw,lib.sh),Position=Vector2.new(lib.px,lib.py),Corner=10,Thickness=1,ZIndex=6,Visible=true})
    local topBg =D("Square",{Filled=true,Color=C.mantle,Size=Vector2.new(lib.sw,TB),Position=Vector2.new(lib.px,lib.py),Corner=10,ZIndex=6,Visible=true})
    local topFill=D("Square",{Filled=true,Color=C.mantle,Size=Vector2.new(lib.sw,10),Position=Vector2.new(lib.px,lib.py+TB-10),ZIndex=6,Visible=true})
    local topBrd=D("Square",{Filled=true,Color=C.brd,Size=Vector2.new(lib.sw,1),Position=Vector2.new(lib.px,lib.py+TB-1),ZIndex=7,Visible=true})
    local titTxt=D("Text",{Text=lib.title,Size=FS,Color=C.text,Font=FONTB,Position=Vector2.new(lib.px+14,lib.py+11),ZIndex=8,Visible=true})

    -- search icon + bar
    local srW=148; local srBg,srBrd,srIcon,srIconL,srTxt
    if lib.doSearch then
        local sx=lib.px+tw(lib.title,FS)+26
        srBg  =D("Square",{Filled=true,Color=C.surface0,Size=Vector2.new(srW,22),Position=Vector2.new(sx,lib.py+8),Corner=6,ZIndex=7,Visible=true})
        srBrd =D("Square",{Filled=false,Color=C.brd,Size=Vector2.new(srW,22),Position=Vector2.new(sx,lib.py+8),Corner=6,Thickness=1,ZIndex=8,Visible=true})
        -- magnifier: circle + line
        srIcon=D("Circle",{Radius=4,NumSides=10,Thickness=1.2,Color=C.overlay0,Filled=false,Position=Vector2.new(sx+10,lib.py+19),ZIndex=9,Visible=true})
        srIconL=D("Line",{From=Vector2.new(sx+13,lib.py+22),To=Vector2.new(sx+16,lib.py+25),Thickness=1.2,Color=C.overlay0,ZIndex=9,Visible=true})
        srTxt =D("Text",{Text="search...",Size=FSX,Color=C.overlay0,Font=FONT,Position=Vector2.new(sx+20,lib.py+12),ZIndex=9,Visible=true})
    end

    local TITLEW=tw(lib.title,FS)+26+(lib.doSearch and srW+14 or 0)
    local numT=#lib.tnames
    local eTW=math.floor((lib.sw-TITLEW-20)/numT)

    local tabDs={}
    for i,nm in ipairs(lib.tnames) do
        local isA=(i==lib.activeTab)
        local relX=(i-1)*eTW+math.floor(eTW/2-tw(nm,FSX)/2)
        local td=D("Text",{Text=nm,Size=FSX,Color=isA and C.mauve or C.overlay1,Font=isA and FONTB or FONT,
            Position=Vector2.new(lib.px+TITLEW+relX,lib.py+11),ZIndex=9,Visible=true})
        table.insert(tabDs,{td=td,relX=relX,name=nm})
    end

    local slideRelX=(lib.activeTab-1)*eTW+8
    local slideRelXCur=slideRelX
    local slideLine=D("Square",{Filled=true,Color=C.mauve,Size=Vector2.new(eTW-16,2),
        Position=Vector2.new(lib.px+TITLEW+slideRelXCur,lib.py+TB-3),ZIndex=10,Visible=true})



    local function rebuildChrome()
        winBg.Position=Vector2.new(lib.px,lib.py); winBg.Size=Vector2.new(lib.sw,lib.sh)
        winBrd.Position=Vector2.new(lib.px,lib.py); winBrd.Size=Vector2.new(lib.sw,lib.sh)
        topBg.Position=Vector2.new(lib.px,lib.py); topBg.Size=Vector2.new(lib.sw,TB)
        topFill.Position=Vector2.new(lib.px,lib.py+TB-10); topFill.Size=Vector2.new(lib.sw,10)
        topBrd.Position=Vector2.new(lib.px,lib.py+TB-1); topBrd.Size=Vector2.new(lib.sw,1)
        titTxt.Position=Vector2.new(lib.px+14,lib.py+11)
        -- update chrome colors from current theme
        winBg.Color=C.base; winBrd.Color=C.brd; topBg.Color=C.mantle; topFill.Color=C.mantle
        topBrd.Color=C.brd; titTxt.Color=C.text; slideLine.Color=C.acc
        for j,td in ipairs(tabDs) do td.td.Color=(j==lib.activeTab) and C.acc or C.overlay1 end

        if srBg then
            local sx2=lib.px+tw(lib.title,FS)+26
            srBg.Position=Vector2.new(sx2,lib.py+8); srBrd.Position=srBg.Position
            local icX=sx2+10; local icY=lib.py+19
            srIcon.Position=Vector2.new(icX,icY)
            srIconL.From=Vector2.new(icX+3,icY+3); srIconL.To=Vector2.new(icX+6,icY+6)
            srTxt.Position=Vector2.new(sx2+22,lib.py+12)
        end
        for _,td in ipairs(tabDs) do
            td.td.Position=Vector2.new(lib.px+TITLEW+td.relX,lib.py+11)
        end
        slideLine.Position=Vector2.new(lib.px+TITLEW+slideRelXCur,lib.py+TB-3)
        slideLine.Size=Vector2.new(eTW-16,2)
    end

    lib._rebuild=function() rebuildChrome(); buildSecs() end
    local secDs={}; local loops={}

    local function clearSecs()
        for _,d in ipairs(secDs) do d:Remove() end; secDs={}
        for _,h in ipairs(loops) do h.dead=true end; loops={}
    end

    local function mk(t,p)
        local o=Drawing.new(t); for k,v in pairs(p) do o[k]=v end
        table.insert(secDs,o); table.insert(drawings,o); return o
    end

    local function sloop(fn)
        local h={dead=false,wd=false,drag=false,kd={},dH=false,dS=false}
        table.insert(loops,h)
        spawn(function()
            while not h.dead and lib.visible do fn(h); wait() end
        end)
        return h
    end

    local cH=lib.sh-TB-CP*2; local SCSP=24

    local function buildSecs()
        clearSecs(); openDD=nil
        local cur=lib.tabs[lib.activeTab]; if not cur then return end
        if not lib.scrollY[lib.activeTab] then lib.scrollY[lib.activeTab]=0 end
        local sY=lib.scrollY[lib.activeTab]
        local colW=math.floor((lib.sw-CP*3)/2)
        local cx1=lib.px+CP; local cx2=lib.px+CP*2+colW
        local baseY=lib.py+TB+CP
        local q=lib.query
        local c1H=0; local c2H=0; local layouts={}
        local li=0
        for _,sec in ipairs(cur.sections) do
            if secVis(sec,q) then
                local ch=secH(sec,q)
                if ch>0 then
                    li=li+1
                    local isLeft=(li%2==1)
                    local rawY=isLeft and c1H or c2H
                    local cx=isLeft and cx1 or cx2
                    table.insert(layouts,{sec=sec,cx=cx,rawY=rawY,colW=colW,ch=ch})
                    if isLeft then c1H=c1H+ch+CP else c2H=c2H+ch+CP end
                end
            end
        end
        local totH=math.max(c1H,c2H)
        local maxS=math.max(0,totH-cH)
        if sY>maxS then sY=maxS; lib.scrollY[lib.activeTab]=sY end

        -- strict clip: only draw items fully or partially inside window
        local clipT=lib.py+TB+CP
        local clipB=lib.py+lib.sh-CP

        for _,L in ipairs(layouts) do
            local sec=L.sec; local cx=L.cx; local cy=baseY+L.rawY-sY
            local colW2=L.colW; local ch=L.ch

            if cy+ch<clipT or cy>clipB then
            else

            -- section bg
            mk("Square",{Filled=true,Color=C.mantle,Size=Vector2.new(colW2,ch),Position=Vector2.new(cx,cy),Corner=8,ZIndex=10,Visible=true})
            mk("Square",{Filled=false,Color=C.brd,Size=Vector2.new(colW2,ch),Position=Vector2.new(cx,cy),Corner=8,Thickness=1,ZIndex=11,Visible=true})
            mk("Square",{Filled=true,Color=C.surface0,Size=Vector2.new(colW2,28),Position=Vector2.new(cx,cy),Corner=8,ZIndex=11,Visible=true})
            mk("Square",{Filled=true,Color=C.surface0,Size=Vector2.new(colW2-2,12),Position=Vector2.new(cx+1,cy+16),ZIndex=11,Visible=true})
            mk("Square",{Filled=true,Color=C.brd,Size=Vector2.new(colW2,1),Position=Vector2.new(cx,cy+27),ZIndex=12,Visible=true})
            mk("Square",{Filled=true,Color=C.mauve,Size=Vector2.new(3,14),Position=Vector2.new(cx+1,cy+7),Corner=2,ZIndex=13,Visible=true})
            mk("Text",{Text=sec.title,Size=FSS,Color=C.text,Font=FONTB,Position=Vector2.new(cx+PAD,cy+7),ZIndex=13,Visible=true})

            local iy=cy+34

            for _,it in ipairs(sec.items) do
                local nm=(it.text or it.label or ""):lower()
                local vis=(not q or q=="") or nm:find(q:lower(),1,true)~=nil
                if vis then
                    local inV=(iy>=clipT-50 and iy<=clipB+50)

                    if it.kind=="div" then
                        local hasL=(it.label and it.label~="")
                        mk("Square",{Filled=true,Color=C.surface1,Size=Vector2.new(colW2-PAD*2,1),Position=Vector2.new(cx+PAD,iy+8),ZIndex=13,Visible=true})
                        if hasL then
                            local dlw=tw(it.label,FSX)+10
                            local dlx=cx+math.floor(colW2/2)-math.floor(dlw/2)
                            mk("Square",{Filled=true,Color=C.mantle,Size=Vector2.new(dlw,14),Position=Vector2.new(dlx,iy+2),ZIndex=14,Visible=true})
                            mk("Text",{Text=it.label,Size=FSX,Color=C.overlay0,Font=FONT,Position=Vector2.new(dlx+5,iy+4),ZIndex=15,Visible=true})
                        end
                        iy=iy+18

                    elseif it.kind=="lbl" then
                        local lbl=mk("Text",{Text=it.text,Size=FSS,Color=C.subtext1,Font=FONT,Position=Vector2.new(cx+PAD,iy+6),ZIndex=13,Visible=true})
                        if it.tip and inV then
                            local ttW=tw(it.tip,FSX)+20
                            local ttBg =mk("Square",{Filled=true,Color=C.surface2,Size=Vector2.new(ttW,22),Position=Vector2.new(0,0),Corner=5,ZIndex=50,Visible=false})
                            local ttBrd=mk("Square",{Filled=false,Color=C.mauve,Size=Vector2.new(ttW,22),Position=Vector2.new(0,0),Corner=5,Thickness=1,ZIndex=51,Visible=false})
                            local ttT  =mk("Text",{Text=it.tip,Size=FSX,Color=C.text,Font=FONT,Position=Vector2.new(0,0),ZIndex=52,Visible=false})
                            local capCX=cx; local capCW=colW2; local capIY=iy
                            sloop(function(h)
                                local hov=over(Vector2.new(capCX+PAD,capIY),Vector2.new(capCW-PAD*2,IH))
                                if hov then
                                    local m2=mp(); local bx=m2.X+16; local by=m2.Y-28
                                    ttBg.Position=Vector2.new(bx,by); ttBrd.Position=ttBg.Position; ttT.Position=Vector2.new(bx+10,by+5)
                                    ttBg.Visible=true; ttBrd.Visible=true; ttT.Visible=true; lbl.Color=C.lavender
                                else ttBg.Visible=false; ttBrd.Visible=false; ttT.Visible=false; lbl.Color=C.subtext1 end
                            end)
                        end
                        iy=iy+IH

                    elseif it.kind=="tog" then
                        if it._at==nil then it._at=it.val and 1 or 0 end
                        local capIt=it
                        local lblT=mk("Text",{Text=it.label,Size=FSS,Color=C.subtext1,Font=FONT,Position=Vector2.new(cx+PAD,iy+6),ZIndex=13,Visible=true})
                        local cbBg=mk("Square",{Filled=true,Color=lC(C.surface1,C.mauve,it._at),Size=Vector2.new(16,16),Position=Vector2.new(cx+colW2-PAD-16,iy+6),Corner=4,ZIndex=13,Visible=true})
                        local cbBrd=mk("Square",{Filled=false,Color=lC(C.surface1,C.mauve,it._at),Size=Vector2.new(16,16),Position=Vector2.new(cx+colW2-PAD-16,iy+6),Corner=4,Thickness=1,ZIndex=14,Visible=true})
                        local bx2=cx+colW2-PAD-16; local by2=iy+6
                        local ck1=mk("Line",{})
                        ck1.From=Vector2.new(bx2+3,by2+8); ck1.To=Vector2.new(bx2+6,by2+12)
                        ck1.Color=C.base; ck1.Thickness=1.8; ck1.ZIndex=15; ck1.Visible=it._at>0.5
                        local ck2=mk("Line",{})
                        ck2.From=Vector2.new(bx2+5,by2+12); ck2.To=Vector2.new(bx2+13,by2+5)
                        ck2.Color=C.base; ck2.Thickness=1.8; ck2.ZIndex=15; ck2.Visible=it._at>0.5
                        if inV then
                            local capCX=cx; local capCW=colW2; local capIY=iy
                            sloop(function(h)
                                local d=ismouse1pressed()
                                if d and not h.wd then
                                    if over(Vector2.new(capCX,capIY),Vector2.new(capCW,IH)) then
                                        capIt.val=not capIt.val
                                        if capIt.cb then capIt.cb(capIt.val) end
                                        print("[TOGGLE]",capIt.label,capIt.val)
                                    end
                                end
                                local tgt=capIt.val and 1 or 0
                                capIt._at=lN(capIt._at,tgt,0.2)
                                local at=capIt._at
                                local ac=lC(C.surface1,C.mauve,at)
                                cbBg.Color=ac; cbBrd.Color=ac
                                ck1.Visible=at>0.5; ck2.Visible=at>0.5
                                local hov=over(Vector2.new(capCX,capIY),Vector2.new(capCW,IH))
                                lblT.Color=hov and C.text or lC(C.subtext1,C.text,at*0.6)
                                h.wd=d
                            end)
                        end
                        iy=iy+IH

                    elseif it.kind=="sld" then
                        local trkX=cx+PAD; local trkW=colW2-PAD*2
                        local pct=(it.val-it.min)/math.max(1,it.max-it.min)
                        local fw=math.max(8,math.floor(trkW*pct))
                        if it._tx==nil then it._tx=trkX+fw-7 end
                        local capIt=it
                        mk("Text",{Text=it.label,Size=FSS,Color=C.subtext1,Font=FONT,Position=Vector2.new(trkX,iy+4),ZIndex=13,Visible=true})
                        local vs=math.floor(it.val).." "..it.sfx
                        local sVal=mk("Text",{Text=vs,Size=FSX,Color=C.mauve,Font=FONTB,Position=Vector2.new(cx+colW2-PAD-tw(vs,FSX),iy+5),ZIndex=13,Visible=true})
                        -- track bg with rounded ends
                        mk("Square",{Filled=true,Color=C.surface0,Size=Vector2.new(trkW,6),Position=Vector2.new(trkX,iy+27),Corner=3,ZIndex=13,Visible=true})
                        -- fill glow layer (slightly wider, dimmer)
                        local sGl=mk("Square",{Filled=true,Color=Color3.new(C.mauve.R*0.4,C.mauve.G*0.4,C.mauve.B*0.4),Size=Vector2.new(fw+4,10),Position=Vector2.new(trkX-2,iy+25),Corner=5,ZIndex=13,Visible=true})
                        local sF =mk("Square",{Filled=true,Color=C.mauve,Size=Vector2.new(fw,6),Position=Vector2.new(trkX,iy+27),Corner=3,ZIndex=14,Visible=true})
                        -- thumb: outer ring + inner dot
                        local sTh=mk("Square",{Filled=true,Color=C.wht,Size=Vector2.new(16,16),Position=Vector2.new(it._tx,iy+22),Corner=8,ZIndex=15,Visible=true})
                        local sThI=mk("Square",{Filled=true,Color=C.mauve,Size=Vector2.new(8,8),Position=Vector2.new(it._tx+4,iy+26),Corner=4,ZIndex=16,Visible=true})
                        if inV then
                            local capTX=trkX; local capTW=trkW; local capCX=cx; local capCW=colW2; local capIY=iy
                            local targetX=trkX+fw-8
                            sloop(function(h)
                                local d=ismouse1pressed()
                                local hov=over(Vector2.new(capTX-6,capIY+20),Vector2.new(capTW+12,22))
                                if hov and d then h.drag=true end
                                if not d then h.drag=false end
                                if h.drag then
                                    local p2=math.clamp((Mouse.X-capTX)/capTW,0,1)
                                    local nv=math.floor(capIt.min+(capIt.max-capIt.min)*p2+0.5)
                                    capIt.val=nv
                                    local fw2=math.max(8,math.floor(capTW*p2))
                                    sF.Size=Vector2.new(fw2,6)
                                    sGl.Size=Vector2.new(fw2+4,10); sGl.Position=Vector2.new(capTX-2,capIY+25)
                                    targetX=capTX+fw2-8
                                    local vs2=math.floor(nv).." "..capIt.sfx
                                    sVal.Text=vs2; sVal.Position=Vector2.new(capCX+capCW-PAD-tw(vs2,FSX),capIY+5)
                                    if capIt.cb then capIt.cb(nv) end
                                end
                                capIt._tx=lN(capIt._tx,targetX,0.35)
                                local sz2=(hov or h.drag) and 18 or 16
                                local thCenter=capIt._tx+8
                                local thTop=capIY+30
                                sTh.Position=Vector2.new(thCenter-math.floor(sz2/2),thTop-math.floor(sz2/2))
                                sThI.Position=Vector2.new(thCenter-math.floor((sz2-8)/2),thTop-math.floor((sz2-8)/2))
                                sTh.Size=Vector2.new(sz2,sz2); sThI.Size=Vector2.new(sz2-8,sz2-8)
                                sGl.Position=Vector2.new(sF.Position.X-2,capIY+25)
                                h.wd=d
                            end)
                        end
                        iy=iy+SH

                    elseif it.kind=="btn" then
                        iy=iy+2
                        if it._hc==nil then it._hc=0 end
                        local capIt=it
                        local bBg =mk("Square",{Filled=true,Color=lC(C.surface0,C.surface2,it._hc),Size=Vector2.new(colW2-PAD*2,BH),Position=Vector2.new(cx+PAD,iy),Corner=6,ZIndex=13,Visible=true})
                        local bBrd=mk("Square",{Filled=false,Color=lC(C.brd,C.mauve,it._hc),Size=Vector2.new(colW2-PAD*2,BH),Position=Vector2.new(cx+PAD,iy),Corner=6,Thickness=1,ZIndex=14,Visible=true})
                        -- centered text
                        local lw=tw(it.label,FSS)
                        local bTxt=mk("Text",{Text=it.label,Size=FSS,Color=lC(C.subtext1,C.text,it._hc),Font=FONT,
                            Position=Vector2.new(cx+PAD+math.floor((colW2-PAD*2)/2)-math.floor(lw/2),iy+math.floor((BH-FSS)/2)-1),ZIndex=15,Visible=true})
                        if inV then
                            sloop(function(h)
                                local d=ismouse1pressed()
                                local hov=over(bBg.Position,bBg.Size)
                                local tgt=hov and 1 or 0
                                capIt._hc=lN(capIt._hc,tgt,0.2)
                                bBg.Color=lC(C.surface0,C.surface2,capIt._hc)
                                bBrd.Color=lC(C.brd,C.mauve,capIt._hc)
                                bTxt.Color=lC(C.subtext1,C.text,capIt._hc)
                                if hov and d and not h.wd then
                                    bBg.Color=C.mauve; bTxt.Color=C.base
                                    if capIt.cb then capIt.cb() end; print("[BUTTON]",capIt.label)
                                end
                                h.wd=d
                            end)
                        end
                        iy=iy+BH+6

                    elseif it.kind=="dd" or it.kind=="mdd" then
                        iy=iy+2
                        local isM=(it.kind=="mdd"); local sid={}
                        if it._hc==nil then it._hc=0 end
                        local capIt=it
                        local dBg =mk("Square",{Filled=true,Color=lC(C.surface0,C.surface1,it._hc),Size=Vector2.new(colW2-PAD*2,BH),Position=Vector2.new(cx+PAD,iy),Corner=6,ZIndex=13,Visible=true})
                        local dBrd=mk("Square",{Filled=false,Color=lC(C.brd,C.mauve,it._hc),Size=Vector2.new(colW2-PAD*2,BH),Position=Vector2.new(cx+PAD,iy),Corner=6,Thickness=1,ZIndex=14,Visible=true})
                        local selText=isM and (#it.sel==0 and "none selected" or table.concat(it.sel,", ")) or it.sel
                        local dTxt=mk("Text",{Text=selText,Size=FSS,Color=C.subtext1,Font=FONT,Position=Vector2.new(cx+PAD+10,iy+8),ZIndex=15,Visible=true})
                        local dArrX=cx+PAD+(colW2-PAD*2)-16; local dArrY=iy+9
                        local dArr=mk("Triangle",{})
                        dArr.PointA=Vector2.new(dArrX+2,dArrY+1); dArr.PointB=Vector2.new(dArrX+8,dArrY+1); dArr.PointC=Vector2.new(dArrX+5,dArrY+6)
                        dArr.Color=C.overlay0; dArr.Filled=true; dArr.ZIndex=15; dArr.Visible=true
                        local lH=#it.opts*DIH+8
                        local lBg =mk("Square",{Filled=true,Color=C.surface0,Size=Vector2.new(colW2-PAD*2,lH),Position=Vector2.new(cx+PAD,iy+BH+2),Corner=6,ZIndex=20,Visible=false})
                        local lBrd=mk("Square",{Filled=false,Color=C.mauve,Size=Vector2.new(colW2-PAD*2,lH),Position=Vector2.new(cx+PAD,iy+BH+2),Corner=6,Thickness=1,ZIndex=21,Visible=false})
                        local oDs={}
                        for oi,opt in ipairs(it.opts) do
                            local oY=iy+BH+2+4+(oi-1)*DIH
                            local isSel=isM and (function() for _,v in ipairs(it.sel) do if v==opt then return true end end; return false end)() or (opt==it.sel)
                            local oh=mk("Square",{Filled=true,Color=C.surface1,Size=Vector2.new(colW2-PAD*2-6,DIH-3),Position=Vector2.new(cx+PAD+3,oY+1),Corner=4,ZIndex=21,Visible=false})
                            local ot=mk("Text",{Text=opt,Size=FSS,Color=isSel and C.mauve or C.subtext1,Font=isSel and FONTB or FONT,Position=Vector2.new(cx+PAD+(isM and 28 or 10),oY+5),ZIndex=22,Visible=false})
                            local omark=nil
                            if isM then
                                omark=mk("Square",{Filled=isSel,Color=isSel and C.mauve or C.surface2,Size=Vector2.new(12,12),Position=Vector2.new(cx+PAD+10,oY+6),Corner=3,ZIndex=22,Visible=false})
                                mk("Square",{Filled=false,Color=isSel and C.mauve or C.brd2,Size=Vector2.new(12,12),Position=Vector2.new(cx+PAD+10,oY+6),Corner=3,Thickness=1,ZIndex=23,Visible=false})
                            else
                                if isSel then mk("Square",{Filled=true,Color=C.mauve,Size=Vector2.new(3,DIH-8),Position=Vector2.new(cx+PAD+3,oY+4),Corner=2,ZIndex=22,Visible=false}) end
                            end
                            table.insert(oDs,{t=ot,h=oh,v=opt,y=oY,mark=omark})
                        end
                        if inV then
                            sloop(function(h)
                                local d=ismouse1pressed()
                                local hov=over(dBg.Position,dBg.Size)
                                capIt._hc=lN(capIt._hc,hov and 1 or 0,0.2)
                                dBg.Color=lC(C.surface0,C.surface1,capIt._hc)
                                dBrd.Color=lC(C.brd,C.mauve,capIt._hc)
                                dTxt.Color=lC(C.subtext1,C.text,capIt._hc)
                                dArr.Color=lC(C.overlay0,C.mauve,capIt._hc)
                                if d and not h.wd then
                                    if hov then
                                        if openDD==sid then capIt.open=false; openDD=nil
                                        elseif openDD==nil then capIt.open=true; openDD=sid end
                                    elseif capIt.open and not over(lBg.Position,lBg.Size) then
                                        capIt.open=false; if openDD==sid then openDD=nil end
                                    end
                                end
                                if capIt.open then
                                    dArr.PointA=Vector2.new(dArrX+5,dArrY+1); dArr.PointB=Vector2.new(dArrX+2,dArrY+6); dArr.PointC=Vector2.new(dArrX+8,dArrY+6)
                                else
                                    dArr.PointA=Vector2.new(dArrX+2,dArrY+1); dArr.PointB=Vector2.new(dArrX+8,dArrY+1); dArr.PointC=Vector2.new(dArrX+5,dArrY+6)
                                end
                                lBg.Visible=capIt.open; lBrd.Visible=capIt.open
                                for oi,od in ipairs(oDs) do
                                    od.t.Visible=capIt.open
                                    if od.mark then od.mark.Visible=capIt.open end
                                    local hovI=capIt.open and over(Vector2.new(lBg.Position.X+3,od.y+1),Vector2.new(lBg.Size.X-6,DIH-3))
                                    od.h.Visible=hovI or false
                                    if capIt.open and d and not h.wd then
                                        if over(Vector2.new(lBg.Position.X,od.y),Vector2.new(lBg.Size.X,DIH)) then
                                            if isM then
                                                local found=false
                                                for idx,v in ipairs(capIt.sel) do if v==od.v then table.remove(capIt.sel,idx); found=true; break end end
                                                if not found then table.insert(capIt.sel,od.v) end
                                                local t2={}; for _,v in ipairs(capIt.sel) do table.insert(t2,v) end
                                                dTxt.Text=#t2==0 and "none selected" or table.concat(t2,", ")
                                                for _,o2 in ipairs(oDs) do
                                                    local s2=false; for _,v in ipairs(capIt.sel) do if v==o2.v then s2=true end end
                                                    o2.t.Color=s2 and C.mauve or C.subtext1; o2.t.Font=s2 and FONTB or FONT
                                                    if o2.mark then o2.mark.Filled=s2; o2.mark.Color=s2 and C.mauve or C.surface2 end
                                                end
                                                if capIt.cb then capIt.cb(capIt.sel) end; print("[MULTI]",capIt.label)
                                            else
                                                capIt.sel=od.v; dTxt.Text=od.v
                                                for _,o2 in ipairs(oDs) do o2.t.Color=(o2.v==capIt.sel) and C.mauve or C.subtext1; o2.t.Font=(o2.v==capIt.sel) and FONTB or FONT end
                                                capIt.open=false; openDD=nil
                                                if capIt.cb then capIt.cb(od.v) end; print("[SELECT]",capIt.label,od.v)
                                            end
                                        end
                                    end
                                end
                                h.wd=d
                            end)
                        end
                        iy=iy+BH+6

                    elseif it.kind=="cp" then
                        local capIt=it
                        mk("Text",{Text=it.label,Size=FSS,Color=C.subtext1,Font=FONT,Position=Vector2.new(cx+PAD,iy+6),ZIndex=13,Visible=true})
                        local swX=cx+colW2-PAD-26; local swY=iy+4
                        local swBg =mk("Square",{Filled=true,Color=it.col,Size=Vector2.new(24,18),Position=Vector2.new(swX,swY),Corner=5,ZIndex=13,Visible=true})
                        local swBrd=mk("Square",{Filled=false,Color=C.brd2,Size=Vector2.new(24,18),Position=Vector2.new(swX,swY),Corner=5,Thickness=1,ZIndex=14,Visible=true})

                        local cpW=200; local cpH=192
                        local cpX=math.clamp(cx+math.floor(colW2/2)-math.floor(cpW/2),lib.px+4,lib.px+lib.sw-cpW-4)
                        local cpY=iy+IH+2

                        local cpParts={}
                        local function cpMk(t,p)
                            local o=Drawing.new(t); for k,v in pairs(p) do o[k]=v end
                            table.insert(cpParts,o); table.insert(secDs,o); table.insert(drawings,o); return o
                        end

                        local cpBg=cpMk("Square",{Filled=true,Color=C.crust,Size=Vector2.new(cpW,cpH),Position=Vector2.new(cpX,cpY),Corner=8,ZIndex=30,Visible=false})
                        cpMk("Square",{Filled=false,Color=C.mauve,Size=Vector2.new(cpW,cpH),Position=Vector2.new(cpX,cpY),Corner=8,Thickness=1,ZIndex=31,Visible=false})
                        -- header
                        cpMk("Square",{Filled=true,Color=C.surface0,Size=Vector2.new(cpW,24),Position=Vector2.new(cpX,cpY),Corner=8,ZIndex=32,Visible=false})
                        cpMk("Square",{Filled=true,Color=C.surface0,Size=Vector2.new(cpW,10),Position=Vector2.new(cpX,cpY+14),ZIndex=32,Visible=false})
                        cpMk("Square",{Filled=true,Color=C.brd,Size=Vector2.new(cpW,1),Position=Vector2.new(cpX,cpY+23),ZIndex=33,Visible=false})
                        cpMk("Text",{Text="color picker",Size=FSX,Color=C.subtext0,Font=FONTB,Position=Vector2.new(cpX+10,cpY+6),ZIndex=33,Visible=false})
                        local cpPrevHead=cpMk("Square",{Filled=true,Color=it.col,Size=Vector2.new(14,14),Position=Vector2.new(cpX+cpW-22,cpY+5),Corner=3,ZIndex=33,Visible=false})

                        -- hue bar: smooth gradient using many segments
                        local hbX=cpX+8; local hbY=cpY+30; local hbW=cpW-16; local hbH=11
                        local hueSteps=30
                        local hueSegW=hbW/hueSteps
                        for si=0,hueSteps-1 do
                            local h1=si/hueSteps; local h2=(si+1)/hueSteps
                            local c1=hsv(h1,1,1); local c2=hsv(h2,1,1)
                            local mc=Color3.new((c1.R+c2.R)/2,(c1.G+c2.G)/2,(c1.B+c2.B)/2)
                            cpMk("Square",{Filled=true,Color=mc,Size=Vector2.new(math.ceil(hueSegW)+1,hbH),Position=Vector2.new(hbX+si*hueSegW,hbY),ZIndex=33,Visible=false})
                        end
                        cpMk("Square",{Filled=false,Color=C.surface2,Size=Vector2.new(hbW,hbH),Position=Vector2.new(hbX,hbY),Corner=2,Thickness=1,ZIndex=34,Visible=false})
                        local hCur=cpMk("Square",{Filled=true,Color=C.wht,Size=Vector2.new(3,hbH+4),Position=Vector2.new(hbX+math.floor(it.ch*hbW)-1,hbY-2),Corner=2,ZIndex=35,Visible=false})

                        -- SV box: smooth gradient via many segments
                        local svX=cpX+8; local svY=hbY+hbH+6; local svW=cpW-16; local svH=70
                        local svCols=20; local svRows=12; local cells={}
                        local svCW=svW/svCols; local svCH=svH/svRows
                        for ci=0,svCols-1 do
                            for ri=0,svRows-1 do
                                local s2=ci/(svCols-1); local v2=1-ri/(svRows-1)
                                local sc=cpMk("Square",{Filled=true,Color=hsv(it.ch,s2,v2),
                                    Size=Vector2.new(math.ceil(svCW)+1,math.ceil(svCH)+1),
                                    Position=Vector2.new(svX+ci*svCW,svY+ri*svCH),ZIndex=33,Visible=false})
                                table.insert(cells,{d=sc,s=s2,v=v2})
                            end
                        end
                        cpMk("Square",{Filled=false,Color=C.surface2,Size=Vector2.new(svW,svH),Position=Vector2.new(svX,svY),Corner=2,Thickness=1,ZIndex=34,Visible=false})
                        local svCur=cpMk("Square",{Filled=false,Color=C.wht,Size=Vector2.new(10,10),
                            Position=Vector2.new(svX+math.floor(it.cs*svW)-5,svY+math.floor((1-it.cv)*svH)-5),Corner=5,Thickness=2,ZIndex=35,Visible=false})

                        -- bottom row: preview + hex + presets
                        local botY=svY+svH+8
                        local cpPrevBot=cpMk("Square",{Filled=true,Color=it.col,Size=Vector2.new(22,14),Position=Vector2.new(cpX+8,botY),Corner=4,ZIndex=33,Visible=false})
                        cpMk("Square",{Filled=false,Color=C.surface1,Size=Vector2.new(22,14),Position=Vector2.new(cpX+8,botY),Corner=4,Thickness=1,ZIndex=34,Visible=false})
                        local hexLbl=cpMk("Text",{Text=hx(it.col),Size=FSX,Color=C.text,Font=FONT,Position=Vector2.new(cpX+36,botY+2),ZIndex=34,Visible=false})

                        -- presets row: second line below preview+hex
                        local presets={C.mauve,C.blue,C.red,C.green,C.peach,C.pink,C.teal,C.lavender}
                        local psW=14; local psGap=4; local psY2=botY+18
                        local totalPsW=#presets*(psW+psGap)-psGap
                        local psStartX=cpX+math.floor((cpW-totalPsW)/2); local psDs={}
                        for i2,pc in ipairs(presets) do
                            local px2=psStartX+(i2-1)*(psW+psGap)
                            local ps=cpMk("Square",{Filled=true,Color=pc,Size=Vector2.new(psW,psW),Position=Vector2.new(px2,psY2),Corner=3,ZIndex=33,Visible=false})
                            local pb=cpMk("Square",{Filled=false,Color=C.brd,Size=Vector2.new(psW,psW),Position=Vector2.new(px2,psY2),Corner=3,Thickness=1,ZIndex=34,Visible=false})
                            table.insert(psDs,{bg=ps,brd=pb,c=pc,x=px2,y=psY2})
                        end

                        local cpOpen=false
                        local function setCPv(v)
                            for _,o in ipairs(cpParts) do o.Visible=v end
                        end

                        if inV then
                            sloop(function(h)
                                local d=ismouse1pressed(); local m2=mp()
                                if d and not h.wd then
                                    if over(Vector2.new(swX-2,swY-2),Vector2.new(28,22)) then
                                        cpOpen=not cpOpen; h.dH=false; h.dS=false; setCPv(cpOpen)
                                    elseif cpOpen then
                                        if over(Vector2.new(hbX,hbY),Vector2.new(hbW,hbH)) then h.dH=true
                                        elseif over(Vector2.new(svX,svY),Vector2.new(svW,svH)) then h.dS=true
                                        else
                                            for _,ps in ipairs(psDs) do
                                                if over(Vector2.new(ps.x,ps.y),Vector2.new(psW,psW)) then
                                                    capIt.col=ps.c; swBg.Color=ps.c
                                                    cpPrevHead.Color=ps.c; cpPrevBot.Color=ps.c; hexLbl.Text=hx(ps.c)
                                                    if capIt.cb then capIt.cb(ps.c) end; print("[COLOR]",hx(ps.c))
                                                    cpOpen=false; setCPv(false)
                                                end
                                            end
                                            if not over(cpBg.Position,cpBg.Size) then cpOpen=false; setCPv(false) end
                                        end
                                    end
                                end
                                if not d then h.dH=false; h.dS=false end
                                if h.dH and cpOpen then
                                    capIt.ch=math.clamp((m2.X-hbX)/hbW,0,1)
                                    hCur.Position=Vector2.new(hbX+math.floor(capIt.ch*hbW)-1,hbY-2)
                                    for _,cl in ipairs(cells) do cl.d.Color=hsv(capIt.ch,cl.s,cl.v) end
                                    local nc=hsv(capIt.ch,capIt.cs,capIt.cv)
                                    capIt.col=nc; swBg.Color=nc; cpPrevHead.Color=nc; cpPrevBot.Color=nc; hexLbl.Text=hx(nc)
                                    if capIt.cb then capIt.cb(nc) end
                                end
                                if h.dS and cpOpen then
                                    capIt.cs=math.clamp((m2.X-svX)/svW,0,1)
                                    capIt.cv=1-math.clamp((m2.Y-svY)/svH,0,1)
                                    svCur.Position=Vector2.new(svX+math.floor(capIt.cs*svW)-5,svY+math.floor((1-capIt.cv)*svH)-5)
                                    local nc=hsv(capIt.ch,capIt.cs,capIt.cv)
                                    capIt.col=nc; swBg.Color=nc; cpPrevHead.Color=nc; cpPrevBot.Color=nc; hexLbl.Text=hx(nc)
                                    if capIt.cb then capIt.cb(nc) end
                                end
                                swBrd.Color=cpOpen and C.mauve or C.brd2; h.wd=d
                            end)
                        end
                        iy=iy+IH

                    elseif it.kind=="tb" then
                        mk("Text",{Text=it.label,Size=FSS,Color=C.subtext1,Font=FONT,Position=Vector2.new(cx+PAD,iy+6),ZIndex=13,Visible=true})
                        iy=iy+IH+2
                        local capIt=it
                        local tbBg =mk("Square",{Filled=true,Color=C.surface0,Size=Vector2.new(colW2-PAD*2,BH),Position=Vector2.new(cx+PAD,iy),Corner=6,ZIndex=13,Visible=true})
                        local tbBrd=mk("Square",{Filled=false,Color=C.brd,Size=Vector2.new(colW2-PAD*2,BH),Position=Vector2.new(cx+PAD,iy),Corner=6,Thickness=1,ZIndex=14,Visible=true})
                        local tbTxt=mk("Text",{Text=it.placeholder,Size=FSS,Color=C.overlay0,Font=FONT,Position=Vector2.new(cx+PAD+8,iy+8),ZIndex=15,Visible=true})
                        if inV then
                            sloop(function(h)
                                local d=ismouse1pressed()
                                if d and not h.wd then capIt.focused=over(tbBg.Position,tbBg.Size) end
                                tbBrd.Color=capIt.focused and C.mauve or C.brd
                                tbBg.Color=capIt.focused and C.surface1 or C.surface0
                                if capIt.focused then
                                    for kc=8,90 do
                                        if iskeypressed(kc) then
                                            if not h.kd[kc] then
                                                if kc==8 then capIt.val=capIt.val:sub(1,-2)
                                                elseif kc==13 then capIt.focused=false; if capIt.cb then capIt.cb(capIt.val) end; print("[TEXTBOX]",capIt.label,capIt.val)
                                                elseif kc==27 then capIt.focused=false
                                                elseif kc==32 then if #capIt.val<40 then capIt.val=capIt.val.." " end
                                                elseif kc>=48 and kc<=57 then if #capIt.val<40 then capIt.val=capIt.val..string.char(kc) end
                                                elseif kc>=65 and kc<=90 then
                                                    if #capIt.val<40 then capIt.val=capIt.val..(iskeypressed(0x10) and string.char(kc) or string.char(kc+32)) end
                                                end
                                                h.kd[kc]=true
                                            end
                                        else h.kd[kc]=false end
                                    end
                                end
                                tbTxt.Text=capIt.val=="" and capIt.placeholder or (capIt.val..(capIt.focused and "_" or ""))
                                tbTxt.Color=capIt.val=="" and C.overlay0 or C.text
                                h.wd=d
                            end)
                        end
                        iy=iy+BH+2

                    elseif it.kind=="kb" then
                        local capIt=it
                        local kbBg =mk("Square",{Filled=true,Color=C.surface0,Size=Vector2.new(74,22),Position=Vector2.new(cx+colW2-PAD-74,iy+4),Corner=5,ZIndex=13,Visible=true})
                        local kbBrd=mk("Square",{Filled=false,Color=C.brd,Size=Vector2.new(74,22),Position=Vector2.new(cx+colW2-PAD-74,iy+4),Corner=5,Thickness=1,ZIndex=14,Visible=true})
                        mk("Text",{Text=it.label,Size=FSS,Color=C.subtext1,Font=FONT,Position=Vector2.new(cx+PAD,iy+6),ZIndex=13,Visible=true})
                        local kbTxt=mk("Text",{Text="["..(KNAMES[it.kc] or "?").."]",Size=FSX,Color=C.mauve,Font=FONTB,Position=Vector2.new(cx+colW2-PAD-74+8,iy+7),ZIndex=15,Visible=true})
                        if inV then
                            sloop(function(h)
                                local d=ismouse1pressed()
                                local hov=over(kbBg.Position,kbBg.Size)
                                kbBg.Color=hov and C.surface1 or C.surface0
                                if d and not h.wd and hov then capIt.binding=true; kbTxt.Text="[...]"; kbBrd.Color=C.mauve end
                                if capIt.binding then
                                    for kname2,kc2 in pairs(KCODES) do
                                        if kc2~=0 and iskeypressed(kc2) then
                                            capIt.kc=kc2; capIt.binding=false
                                            kbTxt.Text="["..kname2.."]"; kbBrd.Color=C.brd
                                            if capIt.cb then capIt.cb(kc2,kname2) end; print("[KEYBIND]",capIt.label,kname2)
                                        end
                                    end
                                end; h.wd=d
                            end)
                        end
                        iy=iy+IH
                    end
                end
            end
            end
        end

        -- scrollbar
        if totH>cH then
            local sbH=math.max(24,math.floor(cH*(cH/math.max(1,totH))))
            local sbY=lib.py+TB+CP+math.floor((sY/math.max(1,maxS))*math.max(0,cH-sbH))
            mk("Square",{Filled=true,Color=C.surface2,Size=Vector2.new(3,sbH),Position=Vector2.new(lib.px+lib.sw-6,sbY),Corner=2,ZIndex=18,Visible=true})
        end
        if q and q~="" and #layouts==0 then
            local noW=tw("no results",FSS)+24
            mk("Square",{Filled=true,Color=C.mantle,Size=Vector2.new(noW,32),Position=Vector2.new(lib.px+math.floor((lib.sw-noW)/2),lib.py+TB+32),Corner=6,ZIndex=10,Visible=true})
            mk("Text",{Text="no results",Size=FSS,Color=C.overlay0,Font=FONT,Position=Vector2.new(lib.px+math.floor((lib.sw-tw("no results",FSS))/2),lib.py+TB+40),ZIndex=11,Visible=true})
        end
    end

    buildSecs()

    -- tabs
    spawn(function()
        local wd=false
        while true do
            wait(0.016)
            if not lib.visible then wd=false
            else
                local d=ismouse1pressed()
                if d and not wd then
                    local tabAreaX=lib.px+TITLEW
                    for i=1,numT do
                        local tx2=tabAreaX+(i-1)*eTW
                        if Mouse.X>=tx2 and Mouse.X<=tx2+eTW and Mouse.Y>=lib.py and Mouse.Y<=lib.py+TB then
                            if lib.activeTab~=i then
                                lib.activeTab=i; openDD=nil
                                for j,td in ipairs(tabDs) do
                                    td.td.Color=(j==i) and C.mauve or C.overlay1
                                    td.td.Font=(j==i) and FONTB or FONT
                                end
                                slideRelX=(i-1)*eTW+8
                                buildSecs()
                            end
                            break
                        end
                    end
                end
                slideRelXCur=lN(slideRelXCur,slideRelX,0.22)
                slideLine.Position=Vector2.new(lib.px+TITLEW+slideRelXCur,lib.py+TB-3)
                wd=d
            end
        end
    end)

    -- drag
    spawn(function()
        local wd=false; local drag=false; local ds=nil; local spx=0; local spy=0
        while true do
            wait(0.016)
            if not lib.visible then wd=false; drag=false
            else
                local d=ismouse1pressed()
                local mx=Mouse.X; local my=Mouse.Y
                if d and not wd then
                    -- only drag if click is in title area (left of tabs)
                    if mx>=lib.px and mx<=lib.px+TITLEW and my>=lib.py and my<=lib.py+TB then
                        drag=true; ds=Vector2.new(mx,my); spx=lib.px; spy=lib.py
                    end
                end
                if not d then
                    if drag then buildSecs() end
                    drag=false
                end
                if drag and d then
                    local newPX=spx+(mx-ds.X); local newPY=spy+(my-ds.Y)
                    local dv=Vector2.new(newPX-lib.px,newPY-lib.py)
                    lib.px=newPX; lib.py=newPY
                    rebuildChrome()
                    for _,sd in ipairs(secDs) do
                        if sd.Position then sd.Position=sd.Position+dv
                        elseif sd.From then sd.From=sd.From+dv; sd.To=sd.To+dv
                        elseif sd.PointA then sd.PointA=sd.PointA+dv; sd.PointB=sd.PointB+dv; sd.PointC=sd.PointC+dv
                        end
                    end
                end
                wd=d
            end
        end
    end)

    -- search
    if lib.doSearch then
        spawn(function()
            local wd=false; local lastQ=""
            while true do
                wait(0.016)
                if not lib.visible then wd=false
                else
                    local sx2=lib.px+tw(lib.title,FS)+26
                    if srBg then
                        srBg.Position=Vector2.new(sx2,lib.py+8); srBrd.Position=srBg.Position
                        srIcon.Position=Vector2.new(sx2+10,lib.py+19)
                        srIconL.From=Vector2.new(sx2+13,lib.py+22); srIconL.To=Vector2.new(sx2+16,lib.py+25)
                        srTxt.Position=Vector2.new(sx2+20,lib.py+12)
                    end
                    local d=ismouse1pressed()
                    if d and not wd then
                        local mx=Mouse.X; local my=Mouse.Y
                        if mx>=sx2 and mx<=sx2+srW and my>=lib.py+8 and my<=lib.py+30 then
                            lib.sfocus=true
                        else
                            lib.sfocus=false
                        end
                    end
                    if srBrd then srBrd.Color=lib.sfocus and C.mauve or C.brd end
                    if srBg then srBg.Color=lib.sfocus and C.surface1 or C.surface0 end
                    if srIcon then srIcon.Color=lib.sfocus and C.mauve or C.overlay0; srIconL.Color=lib.sfocus and C.mauve or C.overlay0 end
                    if lib.sfocus then
                        for kc=8,90 do
                            if iskeypressed(kc) then
                                if not lib.kdown[kc] then
                                    if kc==8 then lib.query=lib.query:sub(1,-2)
                                    elseif kc==27 then lib.sfocus=false
                                    elseif kc==32 then if #lib.query<20 then lib.query=lib.query.." " end
                                    elseif kc>=48 and kc<=57 then if #lib.query<20 then lib.query=lib.query..string.char(kc) end
                                    elseif kc>=65 and kc<=90 then if #lib.query<20 then lib.query=lib.query..string.char(kc+32) end
                                    end
                                    lib.kdown[kc]=true
                                end
                            else lib.kdown[kc]=false end
                        end
                    end
                    srTxt.Text=lib.query=="" and "search..." or lib.query
                    srTxt.Color=lib.query=="" and C.overlay0 or C.text
                    if lib.query~=lastQ then lastQ=lib.query; buildSecs() end
                    wd=d
                end
            end
        end)
    end

        -- scroll
    spawn(function()
        while true do
            if not lib.visible then wait(0.05) else
            local inC=over(Vector2.new(lib.px,lib.py+TB),Vector2.new(lib.sw,lib.sh-TB))
            if inC then
                local at=lib.activeTab; if not lib.scrollY[at] then lib.scrollY[at]=0 end
                local cur2=lib.tabs[at]
                if cur2 then
                    local q=lib.query; local c1H=0; local c2H=0; local li2=0
                    for _,sec in ipairs(cur2.sections) do
                        if secVis(sec,q) then local ch=secH(sec,q)
                            if ch>0 then li2=li2+1; if li2%2==1 then c1H=c1H+ch+CP else c2H=c2H+ch+CP end end
                        end
                    end
                    local maxS2=math.max(0,math.max(c1H,c2H)-cH)
                    if iskeypressed(0x26) then lib.scrollY[at]=math.max(0,lib.scrollY[at]-SCSP); buildSecs(); wait(0.05)
                    elseif iskeypressed(0x28) then lib.scrollY[at]=math.min(maxS2,lib.scrollY[at]+SCSP); buildSecs(); wait(0.05)
                    else wait(0.016) end
                else wait(0.016) end
            end end
        end
    end)

    -- toggle key
    spawn(function()
        local wd=false
        while true do
            if lib.toggleKey~=0 and iskeypressed(lib.toggleKey) then
                if not wd then
                    lib.visible=not lib.visible; local v=lib.visible
                    winBg.Visible=v; winBrd.Visible=v; topBg.Visible=v; topFill.Visible=v
                    topBrd.Visible=v; titTxt.Visible=v; slideLine.Visible=v
                    if srBg then srBg.Visible=v; srBrd.Visible=v; srIcon.Visible=v; srIconL.Visible=v; srTxt.Visible=v end
                    for _,td in ipairs(tabDs) do td.td.Visible=v end
                    for _,d2 in ipairs(secDs) do d2.Visible=v end
                    if v then rebuildChrome(); buildSecs() end
                    wd=true
                end
            else wd=false end
            wait(0.05)
        end
    end)
end

function SyftLib:Close()
    self.visible=false; for _,d in ipairs(drawings) do d:Remove() end
end

_G.SyftLib=SyftLib
return SyftLib
