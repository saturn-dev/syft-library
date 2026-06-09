SyftLib = {}
SyftLib.__index = SyftLib

local Players = game:GetService("Players")
local Mouse = Players.LocalPlayer:GetMouse()
local drawings = {}
local openDD = nil

local C = {
    base    = Color3.fromRGB(24, 24, 37),
    mantle  = Color3.fromRGB(18, 18, 28),
    crust   = Color3.fromRGB(14, 14, 22),
    surface0= Color3.fromRGB(36, 36, 54),
    surface1= Color3.fromRGB(44, 44, 66),
    surface2= Color3.fromRGB(54, 54, 80),
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
C.acc  = C.mauve
C.brd  = C.surface1
C.brd2 = C.surface2

local FONT  = Drawing.Fonts.System
local FONTB = Drawing.Fonts.SystemBold
local FS    = 14
local FSS   = 13
local FSX   = 12

local TB    = 38
local IH    = 28
local BH    = 30
local SH    = 42
local DIH   = 24
local PAD   = 12
local CP    = 8

local KCODES = {
    None=0, Space=0x20, Enter=0x0D, Backspace=0x08, Escape=0x1B,
    Delete=0x2E, Insert=0x2D,
    F1=0x70,F2=0x71,F3=0x72,F4=0x73,F5=0x74,F6=0x75,
    F7=0x76,F8=0x77,F9=0x78,F10=0x79,F11=0x7A,F12=0x7B,
    A=0x41,B=0x42,C=0x43,D=0x44,E=0x45,F=0x46,G=0x47,H=0x48,
    I=0x49,J=0x4A,K=0x4B,L=0x4C,M=0x4D,N=0x4E,O=0x4F,P=0x50,
    Q=0x51,R=0x52,S=0x53,T=0x54,U=0x55,V=0x56,W=0x57,X=0x58,
    Y=0x59,Z=0x5A,
    Num0=0x30,Num1=0x31,Num2=0x32,Num3=0x33,Num4=0x34,
    Num5=0x35,Num6=0x36,Num7=0x37,Num8=0x38,Num9=0x39,
}
local KNAMES = {}
for k,v in pairs(KCODES) do KNAMES[v]=k end

local function D(t,p)
    local o=Drawing.new(t)
    for k,v in pairs(p) do o[k]=v end
    table.insert(drawings,o)
    return o
end

local function mp() return Vector2.new(Mouse.X,Mouse.Y) end

local function over(pos,sz)
    local m=mp()
    return m.X>=pos.X and m.X<=pos.X+sz.X and m.Y>=pos.Y and m.Y<=pos.Y+sz.Y
end

local function tw(s,sz) return #s*(sz or FS)*0.52 end

local function lerpC(a,b,t)
    return Color3.new(a.R+(b.R-a.R)*t,a.G+(b.G-a.G)*t,a.B+(b.B-a.B)*t)
end

local function lerp(a,b,t) return a+(b-a)*t end

local function hsv(h,s,v)
    local i=math.floor(h*6)%6
    local f=h*6-math.floor(h*6)
    local p=v*(1-s); local q=v*(1-f*s); local t2=v*(1-(1-f)*s)
    if i==0 then return Color3.new(v,t2,p)
    elseif i==1 then return Color3.new(q,v,p)
    elseif i==2 then return Color3.new(p,v,t2)
    elseif i==3 then return Color3.new(p,q,v)
    elseif i==4 then return Color3.new(t2,p,v)
    else return Color3.new(v,p,q) end
end

local function hexStr(c)
    return string.format("#%02x%02x%02x",
        math.floor(c.R*255+.5),math.floor(c.G*255+.5),math.floor(c.B*255+.5))
end

function SyftLib.new(title)
    local self=setmetatable({},SyftLib)
    self.title     = title or "SyftLib"
    self.tabs      = {}
    self.tnames    = {}
    self.activeTab = 1
    self.px        = 200
    self.py        = 100
    self.sw        = 650
    self.sh        = 500
    self.visible   = true
    self.doSearch  = false
    self.query     = ""
    self.sfocus    = false
    self.kdown     = {}
    self.toggleKey = 0x2D
    self.scrollY   = {}
    return self
end

function SyftLib:Search() self.doSearch=true end

function SyftLib:Tab(name)
    local tab={name=name,sections={}}
    table.insert(self.tabs,tab)
    table.insert(self.tnames,name)
    if #self.tabs==1 then self.activeTab=1 end
    local lib=self
    function tab:Section(title)
        local sec={title=title,tab=name,items={}}
        table.insert(self.sections,sec)
        function sec:Label(text,tip)
            table.insert(self.items,{kind="lbl",text=text,tip=tip})
        end
        function sec:Divider(label)
            table.insert(self.items,{kind="div",label=label or ""})
        end
        function sec:Toggle(lbl,def,cb)
            table.insert(self.items,{kind="tog",label=lbl,val=def==true,cb=cb})
        end
        function sec:Slider(lbl,mn,mx,def,sfx,cb)
            table.insert(self.items,{kind="sld",label=lbl,min=mn,max=mx,
                val=math.clamp(def or mn,mn,mx),sfx=sfx or "",cb=cb})
        end
        function sec:Button(lbl,cb)
            table.insert(self.items,{kind="btn",label=lbl,cb=cb})
        end
        function sec:Dropdown(lbl,opts,cb)
            table.insert(self.items,{kind="dd",label=lbl,
                opts=opts,sel=opts[1] or "",cb=cb,open=false})
        end
        function sec:ColorPicker(lbl,def,cb)
            table.insert(self.items,{kind="cp",label=lbl,
                col=def or C.acc,cb=cb,ch=0.75,cs=0.4,cv=0.97})
        end
        function sec:TextBox(lbl,placeholder,cb)
            table.insert(self.items,{kind="tb",label=lbl,
                placeholder=placeholder or "",val="",cb=cb,focused=false})
        end
        function sec:Keybind(lbl,defaultKey,cb)
            local kc=KCODES[defaultKey] or 0x58
            table.insert(self.items,{kind="kb",label=lbl,kc=kc,cb=cb,binding=false})
        end
        return sec
    end
    return tab
end

local function itemH(it)
    if it.kind=="lbl" then return IH
    elseif it.kind=="div" then return 18
    elseif it.kind=="tog" then return IH
    elseif it.kind=="sld" then return SH
    elseif it.kind=="btn" then return BH+6
    elseif it.kind=="dd" then
        return BH+6+(it.open and #it.opts*DIH+6 or 0)
    elseif it.kind=="cp" then return IH
    elseif it.kind=="tb" then return IH+BH+4
    elseif it.kind=="kb" then return IH
    end
    return 0
end

local function secVisible(sec,q)
    if not q or q=="" then return true end
    for _,it in ipairs(sec.items) do
        local nm=(it.text or it.label or ""):lower()
        if nm:find(q:lower(),1,true) then return true end
    end
    return false
end

local function secH(sec,q)
    local h=32
    local anyVisible=false
    for _,it in ipairs(sec.items) do
        local nm=(it.text or it.label or ""):lower()
        local vis=(not q or q=="") or nm:find(q:lower(),1,true)~=nil
        if vis then h=h+itemH(it); anyVisible=true end
    end
    if not anyVisible and q and q~="" then return 0 end
    return h+8
end

function SyftLib:Open()
    local lib=self

    local winBg  =D("Square",{Filled=true,Color=C.base,Size=Vector2.new(lib.sw,lib.sh),Position=Vector2.new(lib.px,lib.py),Corner=10,ZIndex=5,Visible=true})
    local winBrd =D("Square",{Filled=false,Color=C.brd,Size=Vector2.new(lib.sw,lib.sh),Position=Vector2.new(lib.px,lib.py),Corner=10,Thickness=1,ZIndex=6,Visible=true})
    local topBg  =D("Square",{Filled=true,Color=C.mantle,Size=Vector2.new(lib.sw,TB),Position=Vector2.new(lib.px,lib.py),Corner=10,ZIndex=6,Visible=true})
    local topFill=D("Square",{Filled=true,Color=C.mantle,Size=Vector2.new(lib.sw,10),Position=Vector2.new(lib.px,lib.py+TB-10),ZIndex=6,Visible=true})
    local topBrd =D("Square",{Filled=true,Color=C.brd,Size=Vector2.new(lib.sw,1),Position=Vector2.new(lib.px,lib.py+TB-1),ZIndex=7,Visible=true})
    local titTxt =D("Text",{Text=lib.title,Size=FS,Color=C.text,Font=FONTB,Position=Vector2.new(lib.px+14,lib.py+11),ZIndex=8,Visible=true})

    local srW=140
    local srBg,srBrd,srTxt
    if lib.doSearch then
        local sx=lib.px+tw(lib.title,FS)+26
        srBg  =D("Square",{Filled=true,Color=C.surface0,Size=Vector2.new(srW,22),Position=Vector2.new(sx,lib.py+8),Corner=6,ZIndex=7,Visible=true})
        srBrd =D("Square",{Filled=false,Color=C.brd,Size=Vector2.new(srW,22),Position=Vector2.new(sx,lib.py+8),Corner=6,Thickness=1,ZIndex=8,Visible=true})
        srTxt =D("Text",{Text="  search...",Size=FSX,Color=C.overlay0,Font=FONT,Position=Vector2.new(sx+8,lib.py+12),ZIndex=9,Visible=true})
    end

    local TITLE_AREA = tw(lib.title,FS)+26+(lib.doSearch and srW+16 or 0)
    local TAB_AREA_X = lib.px+TITLE_AREA+10
    local TAB_AREA_W = lib.sw-TITLE_AREA-20
    local numT=#lib.tnames
    local eachTW=math.floor(TAB_AREA_W/numT)

    local tabDs={}
    for i,nm in ipairs(lib.tnames) do
        local isA=(i==lib.activeTab)
        local tx=TAB_AREA_X+(i-1)*eachTW+math.floor(eachTW/2-tw(nm,FSX)/2)
        local td=D("Text",{Text=nm,Size=FSX,Color=isA and C.mauve or C.overlay1,Font=isA and FONTB or FONT,Position=Vector2.new(tx,lib.py+11),ZIndex=9,Visible=true})
        table.insert(tabDs,{td=td,name=nm,tx=tx})
    end

    local slideX=TAB_AREA_X+(lib.activeTab-1)*eachTW+8
    local slideTargX=slideX
    local slideLine=D("Square",{Filled=true,Color=C.mauve,Size=Vector2.new(eachTW-16,2),Position=Vector2.new(slideX,lib.py+TB-3),ZIndex=10,Visible=true})

    local function rebuildChrome()
        winBg.Position=Vector2.new(lib.px,lib.py)
        winBrd.Position=Vector2.new(lib.px,lib.py)
        topBg.Position=Vector2.new(lib.px,lib.py)
        topFill.Position=Vector2.new(lib.px,lib.py+TB-10)
        topBrd.Position=Vector2.new(lib.px,lib.py+TB-1)
        titTxt.Position=Vector2.new(lib.px+14,lib.py+11)
        winBg.Size=Vector2.new(lib.sw,lib.sh)
        winBrd.Size=Vector2.new(lib.sw,lib.sh)
        topBg.Size=Vector2.new(lib.sw,TB)
        topFill.Size=Vector2.new(lib.sw,10)
        topBrd.Size=Vector2.new(lib.sw,1)
        if srBg then
            local sx2=lib.px+tw(lib.title,FS)+26
            srBg.Position=Vector2.new(sx2,lib.py+8)
            srBrd.Position=Vector2.new(sx2,lib.py+8)
            srTxt.Position=Vector2.new(sx2+8,lib.py+12)
        end
        local taX=lib.px+TITLE_AREA+10
        local etw2=math.floor(TAB_AREA_W/numT)
        for i,td in ipairs(tabDs) do
            local tx2=taX+(i-1)*etw2+math.floor(etw2/2-tw(lib.tnames[i],FSX)/2)
            td.td.Position=Vector2.new(tx2,lib.py+11)
            td.tx=tx2
        end
        slideTargX=lib.px+TITLE_AREA+10+(lib.activeTab-1)*etw2+8
        slideLine.Size=Vector2.new(etw2-16,2)
        slideLine.Position=Vector2.new(slideX,lib.py+TB-3)
    end

    local secDs={}
    local spawnedLoops={}

    local function clearSecs()
        for _,d in ipairs(secDs) do d:Remove() end
        secDs={}
        for _,h in ipairs(spawnedLoops) do h.dead=true end
        spawnedLoops={}
    end

    local function mk(t,p)
        local o=Drawing.new(t)
        for k,v in pairs(p) do o[k]=v end
        table.insert(secDs,o)
        table.insert(drawings,o)
        return o
    end

    local function spawnLoop(fn)
        local handle={dead=false,wd=false,drag=false,kd={},dH=false,dS=false}
        table.insert(spawnedLoops,handle)
        spawn(function()
            while not handle.dead and lib.visible do
                fn(handle)
                wait()
            end
        end)
        return handle
    end

    local contentH=lib.sh-TB-CP*2
    local SCROLL_SPEED=22

    local function buildSecs()
        clearSecs()
        openDD=nil
        local cur=lib.tabs[lib.activeTab]
        if not cur then return end

        if not lib.scrollY[lib.activeTab] then lib.scrollY[lib.activeTab]=0 end
        local sY=lib.scrollY[lib.activeTab]

        local colW=math.floor((lib.sw-CP*3)/2)
        local cx1=lib.px+CP
        local cx2=lib.px+CP*2+colW
        local baseY=lib.py+TB+CP

        local col1H=0; local col2H=0
        local layouts={}
        local q=lib.query

        for si,sec in ipairs(cur.sections) do
            if secVisible(sec,q) then
                local ch=secH(sec,q)
                if ch>0 then
                    local isLeft=(si%2==1)
                    local cx=isLeft and cx1 or cx2
                    local rawY=isLeft and col1H or col2H
                    table.insert(layouts,{sec=sec,cx=cx,rawY=rawY,colW=colW,ch=ch,isLeft=isLeft})
                    if isLeft then col1H=col1H+ch+CP else col2H=col2H+ch+CP end
                end
            end
        end
        local totalH=math.max(col1H,col2H)
        local maxScroll=math.max(0,totalH-contentH)
        if sY>maxScroll then sY=maxScroll; lib.scrollY[lib.activeTab]=sY end

        local clipTop=lib.py+TB
        local clipBot=lib.py+lib.sh-CP

        for _,L in ipairs(layouts) do
            local sec=L.sec
            local cx=L.cx
            local cy=baseY+L.rawY-sY
            local colW2=L.colW
            local ch=L.ch

            local visible=(cy+ch>=clipTop and cy<=clipBot)
            if visible then
                mk("Square",{Filled=true,Color=C.mantle,Size=Vector2.new(colW2,ch),Position=Vector2.new(cx,cy),Corner=8,ZIndex=10,Visible=true})
                mk("Square",{Filled=false,Color=C.brd,Size=Vector2.new(colW2,ch),Position=Vector2.new(cx,cy),Corner=8,Thickness=1,ZIndex=11,Visible=true})
                mk("Square",{Filled=true,Color=C.surface0,Size=Vector2.new(colW2,28),Position=Vector2.new(cx,cy),Corner=8,ZIndex=11,Visible=true})
                mk("Square",{Filled=true,Color=C.surface0,Size=Vector2.new(colW2,10),Position=Vector2.new(cx,cy+18),ZIndex=11,Visible=true})
                mk("Square",{Filled=true,Color=C.brd,Size=Vector2.new(colW2,1),Position=Vector2.new(cx,cy+27),ZIndex=12,Visible=true})
                mk("Square",{Filled=true,Color=C.mauve,Size=Vector2.new(3,16),Position=Vector2.new(cx+1,cy+6),Corner=2,ZIndex=13,Visible=true})
                mk("Text",{Text=sec.title,Size=FSS,Color=C.text,Font=FONTB,Position=Vector2.new(cx+PAD,cy+7),ZIndex=13,Visible=true})

                local iy=cy+34

                for _,it in ipairs(sec.items) do
                    local nm=(it.text or it.label or ""):lower()
                    local vis=(not q or q=="") or nm:find(q:lower(),1,true)~=nil
                    if vis then
                        local inView=(iy>=clipTop-40 and iy<=clipBot+20)
                        if it.kind=="div" then
                            local hasLbl=(it.label and it.label~="")
                            mk("Square",{Filled=true,Color=C.surface1,Size=Vector2.new(colW2-PAD*2,1),Position=Vector2.new(cx+PAD,iy+8),ZIndex=13,Visible=true})
                            if hasLbl then
                                mk("Square",{Filled=true,Color=C.mantle,Size=Vector2.new(tw(it.label,FSX)+10,14),Position=Vector2.new(cx+PAD+12,iy+1),ZIndex=14,Visible=true})
                                mk("Text",{Text=it.label,Size=FSX,Color=C.overlay0,Font=FONT,Position=Vector2.new(cx+PAD+17,iy+3),ZIndex=15,Visible=true})
                            end
                            iy=iy+18

                        elseif it.kind=="lbl" then
                            local lbl=mk("Text",{Text=it.text,Size=FSS,Color=C.subtext1,Font=FONT,Position=Vector2.new(cx+PAD,iy+6),ZIndex=13,Visible=true})
                            if it.tip and inView then
                                local ttW=tw(it.tip,FSX)+20
                                local ttBg =mk("Square",{Filled=true,Color=C.surface2,Size=Vector2.new(ttW,22),Position=Vector2.new(0,0),Corner=5,ZIndex=50,Visible=false})
                                local ttBrd=mk("Square",{Filled=false,Color=C.mauve,Size=Vector2.new(ttW,22),Position=Vector2.new(0,0),Corner=5,Thickness=1,ZIndex=51,Visible=false})
                                local ttT  =mk("Text",{Text=it.tip,Size=FSX,Color=C.text,Font=FONT,Position=Vector2.new(0,0),ZIndex=52,Visible=false})
                                local capCX=cx; local capCW=colW2; local capIY=iy
                                spawnLoop(function(h)
                                    local hov=over(Vector2.new(capCX+PAD,capIY),Vector2.new(capCW-PAD*2,IH))
                                    if hov and lib.visible then
                                        local m2=mp()
                                        local bx=m2.X+16; local by=m2.Y-28
                                        ttBg.Position=Vector2.new(bx,by)
                                        ttBrd.Position=Vector2.new(bx,by)
                                        ttT.Position=Vector2.new(bx+10,by+5)
                                        ttBg.Visible=true; ttBrd.Visible=true; ttT.Visible=true
                                        lbl.Color=C.lavender
                                    else
                                        ttBg.Visible=false; ttBrd.Visible=false; ttT.Visible=false
                                        lbl.Color=C.subtext1
                                    end
                                end)
                            end
                            iy=iy+IH

                        elseif it.kind=="tog" then
                            if not it._animT then it._animT=it.val and 1 or 0 end
                            local capIt=it
                            local lblT=mk("Text",{Text=it.label,Size=FSS,Color=C.subtext1,Font=FONT,Position=Vector2.new(cx+PAD,iy+6),ZIndex=13,Visible=true})
                            local cbBg=mk("Square",{Filled=true,Color=it.val and C.mauve or C.surface1,Size=Vector2.new(16,16),Position=Vector2.new(cx+colW2-PAD-16,iy+6),Corner=4,ZIndex=13,Visible=true})
                            local cbBrd=mk("Square",{Filled=false,Color=it.val and C.mauve or C.brd2,Size=Vector2.new(16,16),Position=Vector2.new(cx+colW2-PAD-16,iy+6),Corner=4,Thickness=1,ZIndex=14,Visible=true})
                            local ck1=mk("Line",{})
                            local ck2=mk("Line",{})
                            local bx=cx+colW2-PAD-16
                            local by=iy+6
                            ck1.From=Vector2.new(bx+3,by+9); ck1.To=Vector2.new(bx+6,by+12)
                            ck2.From=Vector2.new(bx+6,by+12); ck2.To=Vector2.new(bx+13,by+4)
                            ck1.Color=C.base; ck1.Thickness=2; ck1.ZIndex=15; ck1.Visible=it.val
                            ck2.Color=C.base; ck2.Thickness=2; ck2.ZIndex=15; ck2.Visible=it.val
                            if inView then
                                local capLbl=lblT; local capCbBg=cbBg; local capCbBrd=cbBrd
                                local capCX=cx; local capCW=colW2; local capIY=iy
                                spawnLoop(function(h)
                                    local d=ismouse1pressed()
                                    if d and not h.wd then
                                        if over(Vector2.new(capCX,capIY),Vector2.new(capCW,IH)) then
                                            capIt.val=not capIt.val
                                            capIt._animT=capIt.val and 0.6 or 0.4
                                            if capIt.cb then capIt.cb(capIt.val) end
                                            print("[TOGGLE]",capIt.label,capIt.val)
                                        end
                                    end
                                    local tgt=capIt.val and 1 or 0
                                    capIt._animT=capIt._animT+(tgt-capIt._animT)*0.22
                                    local at=capIt._animT
                                    local ac=lerpC(C.surface1,C.mauve,at)
                                    capCbBg.Color=ac; capCbBrd.Color=ac
                                    ck1.Visible=at>0.5; ck2.Visible=at>0.5
                                    local hov=over(Vector2.new(capCX,capIY),Vector2.new(capCW,IH))
                                    capLbl.Color=hov and C.text or lerpC(C.subtext1,C.text,at)
                                    h.wd=d
                                end)
                            end
                            iy=iy+IH

                        elseif it.kind=="sld" then
                            local trkX=cx+PAD; local trkW=colW2-PAD*2
                            local pct=(it.val-it.min)/math.max(1,it.max-it.min)
                            local fw=math.max(8,math.floor(trkW*pct))
                            mk("Text",{Text=it.label,Size=FSS,Color=C.subtext1,Font=FONT,Position=Vector2.new(trkX,iy+4),ZIndex=13,Visible=true})
                            local vs=math.floor(it.val).." "..it.sfx
                            local sVal=mk("Text",{Text=vs,Size=FSX,Color=C.mauve,Font=FONTB,Position=Vector2.new(cx+colW2-PAD-tw(vs,FSX),iy+5),ZIndex=13,Visible=true})
                            mk("Square",{Filled=true,Color=C.surface0,Size=Vector2.new(trkW,5),Position=Vector2.new(trkX,iy+26),Corner=3,ZIndex=13,Visible=true})
                            local sF=mk("Square",{Filled=true,Color=C.mauve,Size=Vector2.new(fw,5),Position=Vector2.new(trkX,iy+26),Corner=3,ZIndex=14,Visible=true})
                            local sGl=mk("Square",{Filled=true,Color=lerpC(C.mauve,C.surface0,0.5),Size=Vector2.new(fw,5),Position=Vector2.new(trkX,iy+26),Corner=3,ZIndex=13,Visible=true})
                            local sTh=mk("Square",{Filled=true,Color=C.wht,Size=Vector2.new(15,15),Position=Vector2.new(trkX+fw-7,iy+21),Corner=8,ZIndex=15,Visible=true})
                            local sThI=mk("Square",{Filled=true,Color=C.mauve,Size=Vector2.new(7,7),Position=Vector2.new(trkX+fw-3,iy+25),Corner=4,ZIndex=16,Visible=true})
                            if inView then
                                local capIt=it; local capTX=trkX; local capTW=trkW
                                local capCX=cx; local capCW=colW2; local capIY=iy
                                if not it._thumbX then it._thumbX=trkX+fw-7 end
                                local targetThX=trkX+fw-7
                                spawnLoop(function(h)
                                    local d=ismouse1pressed()
                                    local hov=over(Vector2.new(capTX-4,capIY+20),Vector2.new(capTW+8,20))
                                    if hov and d then h.drag=true end
                                    if not d then h.drag=false end
                                    if h.drag then
                                        local p2=math.clamp((Mouse.X-capTX)/capTW,0,1)
                                        local nv=math.floor(capIt.min+(capIt.max-capIt.min)*p2+0.5)
                                        capIt.val=nv
                                        local fw2=math.max(8,math.floor(capTW*p2))
                                        sF.Size=Vector2.new(fw2,5); sGl.Size=Vector2.new(fw2,5)
                                        targetThX=capTX+fw2-7
                                        local vs2=math.floor(nv).." "..capIt.sfx
                                        sVal.Text=vs2
                                        sVal.Position=Vector2.new(capCX+capCW-PAD-tw(vs2,FSX),capIY+5)
                                        if capIt.cb then capIt.cb(nv) end
                                    end
                                    it._thumbX=lerp(it._thumbX,targetThX,0.35)
                                    sTh.Position=Vector2.new(it._thumbX,capIY+21)
                                    sThI.Position=Vector2.new(it._thumbX+4,capIY+25)
                                    local sz2=(hov or h.drag) and 17 or 15
                                    sTh.Size=Vector2.new(sz2,sz2); sThI.Size=Vector2.new(sz2-8,sz2-8)
                                    h.wd=d
                                end)
                            end
                            iy=iy+SH

                        elseif it.kind=="btn" then
                            iy=iy+2
                            if not it._hovC then it._hovC=C.surface0 end
                            local capIt=it
                            local bBg =mk("Square",{Filled=true,Color=it._hovC,Size=Vector2.new(colW2-PAD*2,BH),Position=Vector2.new(cx+PAD,iy),Corner=6,ZIndex=13,Visible=true})
                            local bBrd=mk("Square",{Filled=false,Color=C.brd,Size=Vector2.new(colW2-PAD*2,BH),Position=Vector2.new(cx+PAD,iy),Corner=6,Thickness=1,ZIndex=14,Visible=true})
                            local lw=tw(it.label,FSS)
                            local bTxt=mk("Text",{Text=it.label,Size=FSS,Color=C.subtext1,Font=FONT,Position=Vector2.new(cx+PAD+math.floor((colW2-PAD*2-lw)/2),iy+8),ZIndex=15,Visible=true})
                            if inView then
                                spawnLoop(function(h)
                                    local d=ismouse1pressed()
                                    local hov=over(bBg.Position,bBg.Size)
                                    if hov then
                                        capIt._hovC=lerpC(capIt._hovC,C.surface2,0.18)
                                        bBrd.Color=lerpC(bBrd.Color,C.mauve,0.25)
                                        bTxt.Color=lerpC(bTxt.Color,C.text,0.25)
                                        if d and not h.wd then
                                            capIt._hovC=C.mauve
                                            bBrd.Color=C.mauve; bTxt.Color=C.base
                                            if capIt.cb then capIt.cb() end
                                            print("[BUTTON]",capIt.label)
                                        end
                                    else
                                        capIt._hovC=lerpC(capIt._hovC,C.surface0,0.15)
                                        bBrd.Color=lerpC(bBrd.Color,C.brd,0.15)
                                        bTxt.Color=lerpC(bTxt.Color,C.subtext1,0.15)
                                    end
                                    bBg.Color=capIt._hovC
                                    h.wd=d
                                end)
                            end
                            iy=iy+BH+6

                        elseif it.kind=="dd" then
                            iy=iy+2
                            local sid={}
                            local capIt=it
                            if not it._hovC then it._hovC=C.surface0 end
                            local dBg =mk("Square",{Filled=true,Color=it._hovC,Size=Vector2.new(colW2-PAD*2,BH),Position=Vector2.new(cx+PAD,iy),Corner=6,ZIndex=13,Visible=true})
                            local dBrd=mk("Square",{Filled=false,Color=C.brd,Size=Vector2.new(colW2-PAD*2,BH),Position=Vector2.new(cx+PAD,iy),Corner=6,Thickness=1,ZIndex=14,Visible=true})
                            local dTxt=mk("Text",{Text=it.sel,Size=FSS,Color=C.subtext1,Font=FONT,Position=Vector2.new(cx+PAD+10,iy+8),ZIndex=15,Visible=true})
                            local dArr=mk("Text",{Text="v",Size=FSX,Color=C.overlay0,Font=FONT,Position=Vector2.new(cx+PAD+(colW2-PAD*2)-16,iy+9),ZIndex=15,Visible=true})
                            local lH=#it.opts*DIH+8
                            local lBg =mk("Square",{Filled=true,Color=C.surface0,Size=Vector2.new(colW2-PAD*2,lH),Position=Vector2.new(cx+PAD,iy+BH+2),Corner=6,ZIndex=20,Visible=false})
                            local lBrd=mk("Square",{Filled=false,Color=C.mauve,Size=Vector2.new(colW2-PAD*2,lH),Position=Vector2.new(cx+PAD,iy+BH+2),Corner=6,Thickness=1,ZIndex=21,Visible=false})
                            local lDiv=mk("Square",{Filled=true,Color=C.surface1,Size=Vector2.new(colW2-PAD*2-8,1),Position=Vector2.new(cx+PAD+4,iy+BH+2),ZIndex=21,Visible=false})
                            local oDs={}
                            for oi,opt in ipairs(it.opts) do
                                local oY=iy+BH+2+4+(oi-1)*DIH
                                local oh=mk("Square",{Filled=true,Color=C.surface1,Size=Vector2.new(colW2-PAD*2-6,DIH-3),Position=Vector2.new(cx+PAD+3,oY+1),Corner=4,ZIndex=21,Visible=false})
                                local ot=mk("Text",{Text=opt,Size=FSS,Color=(opt==it.sel) and C.mauve or C.subtext1,Font=(opt==it.sel) and FONTB or FONT,Position=Vector2.new(cx+PAD+10,oY+5),ZIndex=22,Visible=false})
                                local osel=nil
                                if opt==it.sel then
                                    osel=mk("Square",{Filled=true,Color=C.mauve,Size=Vector2.new(3,DIH-8),Position=Vector2.new(cx+PAD+3,oY+4),Corner=2,ZIndex=22,Visible=false})
                                end
                                table.insert(oDs,{t=ot,h=oh,v=opt,y=oY,sel=osel})
                            end
                            if inView then
                                spawnLoop(function(h)
                                    local d=ismouse1pressed()
                                    local hov=over(dBg.Position,dBg.Size)
                                    if hov then
                                        capIt._hovC=lerpC(capIt._hovC,C.surface1,0.2)
                                    else
                                        capIt._hovC=lerpC(capIt._hovC,C.surface0,0.15)
                                    end
                                    dBg.Color=capIt._hovC
                                    if d and not h.wd then
                                        if hov then
                                            if openDD==sid then capIt.open=false; openDD=nil
                                            elseif openDD==nil then capIt.open=true; openDD=sid end
                                        elseif capIt.open and not over(lBg.Position,lBg.Size) then
                                            capIt.open=false
                                            if openDD==sid then openDD=nil end
                                        end
                                    end
                                    dBrd.Color=(capIt.open or hov) and C.mauve or C.brd
                                    dTxt.Color=(capIt.open or hov) and C.text or C.subtext1
                                    dArr.Text=capIt.open and "^" or "v"
                                    lBg.Visible=capIt.open; lBrd.Visible=capIt.open; lDiv.Visible=capIt.open
                                    for oi,od in ipairs(oDs) do
                                        od.t.Visible=capIt.open
                                        if od.sel then od.sel.Visible=capIt.open end
                                        local hovItem=capIt.open and over(Vector2.new(lBg.Position.X+3,od.y+1),Vector2.new(lBg.Size.X-6,DIH-3))
                                        od.h.Visible=hovItem or false
                                        if capIt.open and d and not h.wd then
                                            if over(Vector2.new(lBg.Position.X,od.y),Vector2.new(lBg.Size.X,DIH)) then
                                                capIt.sel=od.v; dTxt.Text=od.v
                                                for _,o2 in ipairs(oDs) do
                                                    o2.t.Color=(o2.v==capIt.sel) and C.mauve or C.subtext1
                                                    o2.t.Font=(o2.v==capIt.sel) and FONTB or FONT
                                                end
                                                capIt.open=false; openDD=nil
                                                if capIt.cb then capIt.cb(od.v) end
                                                print("[SELECT]",capIt.label,od.v)
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
                            local cpW=200; local cpH=190
                            local cpX=cx+math.floor(colW2/2)-math.floor(cpW/2)
                            local cpY=iy+IH+4
                            local cpBg  =mk("Square",{Filled=true,Color=C.crust,Size=Vector2.new(cpW,cpH),Position=Vector2.new(cpX,cpY),Corner=10,ZIndex=30,Visible=false})
                            local cpBrd =mk("Square",{Filled=false,Color=C.mauve,Size=Vector2.new(cpW,cpH),Position=Vector2.new(cpX,cpY),Corner=10,Thickness=1,ZIndex=31,Visible=false})
                            local cpHead=mk("Square",{Filled=true,Color=C.surface0,Size=Vector2.new(cpW,26),Position=Vector2.new(cpX,cpY),Corner=10,ZIndex=32,Visible=false})
                            local cpHeadFill=mk("Square",{Filled=true,Color=C.surface0,Size=Vector2.new(cpW,12),Position=Vector2.new(cpX,cpY+14),ZIndex=32,Visible=false})
                            local cpHexT=mk("Text",{Text="color picker",Size=FSX,Color=C.subtext0,Font=FONTB,Position=Vector2.new(cpX+10,cpY+6),ZIndex=33,Visible=false})

                            local hbX=cpX+8; local hbY=cpY+34; local hbW=cpW-16; local hbH=12
                            local hues={Color3.fromRGB(255,0,0),Color3.fromRGB(255,255,0),Color3.fromRGB(0,255,0),Color3.fromRGB(0,255,255),Color3.fromRGB(0,0,255),Color3.fromRGB(255,0,255)}
                            local sw2=math.floor(hbW/6)
                            local hueSegs={}
                            for i2,hc in ipairs(hues) do
                                local hs=mk("Square",{Filled=true,Color=hc,Size=Vector2.new(sw2+1,hbH),Position=Vector2.new(hbX+(i2-1)*sw2,hbY),ZIndex=33,Visible=false})
                                if i2==1 then hs.Corner=3 end
                                table.insert(hueSegs,hs)
                            end
                            mk("Square",{Filled=false,Color=C.surface1,Size=Vector2.new(hbW,hbH),Position=Vector2.new(hbX,hbY),Corner=3,Thickness=1,ZIndex=34,Visible=false})
                            local hCur=mk("Square",{Filled=true,Color=C.wht,Size=Vector2.new(3,hbH+6),Position=Vector2.new(hbX+math.floor(it.ch*hbW)-1,hbY-3),Corner=2,ZIndex=35,Visible=false})

                            local svX=cpX+8; local svY=hbY+hbH+10; local svW=cpW-16; local svH=80
                            local c2=16; local r2=10; local cells={}
                            for ci2=0,c2-1 do
                                for ri2=0,r2-1 do
                                    local s2=ci2/(c2-1); local v2=1-ri2/(r2-1)
                                    local cw3=svW/c2; local ch3=svH/r2
                                    local sc=mk("Square",{Filled=true,Color=hsv(it.ch,s2,v2),Size=Vector2.new(math.ceil(cw3)+1,math.ceil(ch3)+1),Position=Vector2.new(svX+ci2*cw3,svY+ri2*ch3),ZIndex=33,Visible=false})
                                    table.insert(cells,{d=sc,s=s2,v=v2})
                                end
                            end
                            mk("Square",{Filled=false,Color=C.surface1,Size=Vector2.new(svW,svH),Position=Vector2.new(svX,svY),Corner=3,Thickness=1,ZIndex=34,Visible=false})
                            local svCur=mk("Square",{Filled=false,Color=C.wht,Size=Vector2.new(10,10),Position=Vector2.new(svX+math.floor(it.cs*svW)-5,svY+math.floor((1-it.cv)*svH)-5),Corner=5,Thickness=2,ZIndex=35,Visible=false})

                            local prevY2=svY+svH+8
                            local prevSw=mk("Square",{Filled=true,Color=it.col,Size=Vector2.new(28,18),Position=Vector2.new(cpX+8,prevY2),Corner=5,ZIndex=33,Visible=false})
                            local prevBrd=mk("Square",{Filled=false,Color=C.surface1,Size=Vector2.new(28,18),Position=Vector2.new(cpX+8,prevY2),Corner=5,Thickness=1,ZIndex=34,Visible=false})
                            local hexLabel=mk("Text",{Text=hexStr(it.col),Size=FSX,Color=C.text,Font=FONT,Position=Vector2.new(cpX+42,prevY2+4),ZIndex=34,Visible=false})

                            local presets={C.mauve,C.blue,C.red,C.green,C.peach,C.pink,C.teal,C.lavender}
                            local psY2=prevY2; local psDs={}
                            local psStartX=cpX+80
                            for i2,pc in ipairs(presets) do
                                local col=math.floor((i2-1)/2); local row=(i2-1)%2
                                local ps=mk("Square",{Filled=true,Color=pc,Size=Vector2.new(14,14),Position=Vector2.new(psStartX+col*18,psY2+row*16),Corner=3,ZIndex=33,Visible=false})
                                local pb=mk("Square",{Filled=false,Color=C.brd,Size=Vector2.new(14,14),Position=Vector2.new(psStartX+col*18,psY2+row*16),Corner=3,Thickness=1,ZIndex=34,Visible=false})
                                table.insert(psDs,{bg=ps,brd=pb,c=pc})
                            end

                            local cpOpen=false
                            local function setCPvis(v)
                                cpBg.Visible=v; cpBrd.Visible=v; cpHead.Visible=v
                                cpHeadFill.Visible=v; cpHexT.Visible=v
                                hCur.Visible=v; svCur.Visible=v; prevSw.Visible=v
                                prevBrd.Visible=v; hexLabel.Visible=v
                                for _,hs in ipairs(hueSegs) do hs.Visible=v end
                                for _,cl in ipairs(cells) do cl.d.Visible=v end
                                for _,ps in ipairs(psDs) do ps.bg.Visible=v; ps.brd.Visible=v end
                                for _,bd in ipairs(secDs) do
                                    if bd==mk then end
                                end
                                local startShow=false
                                for j=#secDs,1,-1 do
                                    local obj=secDs[j]
                                    if obj==cpBg then startShow=true end
                                    if startShow then obj.Visible=v end
                                    if startShow and j<=#secDs-2 and secDs[j]==hexLabel then break end
                                end
                            end

                            if inView then
                                spawnLoop(function(h)
                                    local d=ismouse1pressed(); local m2=mp()
                                    if d and not h.wd then
                                        if over(Vector2.new(swX-2,swY-2),Vector2.new(28,22)) then
                                            cpOpen=not cpOpen; h.dH=false; h.dS=false
                                            setCPvis(cpOpen)
                                        elseif cpOpen then
                                            if over(Vector2.new(hbX,hbY),Vector2.new(hbW,hbH)) then h.dH=true
                                            elseif over(Vector2.new(svX,svY),Vector2.new(svW,svH)) then h.dS=true
                                            elseif not over(cpBg.Position,cpBg.Size) then
                                                cpOpen=false; setCPvis(false)
                                            end
                                            for _,ps in ipairs(psDs) do
                                                if over(ps.bg.Position,ps.bg.Size) then
                                                    capIt.col=ps.c; swBg.Color=ps.c
                                                    prevSw.Color=ps.c; hexLabel.Text=hexStr(ps.c)
                                                    if capIt.cb then capIt.cb(ps.c) end
                                                    print("[COLOR]",hexStr(ps.c))
                                                    cpOpen=false; setCPvis(false)
                                                end
                                            end
                                        end
                                    end
                                    if not d then h.dH=false; h.dS=false end
                                    if h.dH and cpOpen then
                                        capIt.ch=math.clamp((m2.X-hbX)/hbW,0,1)
                                        hCur.Position=Vector2.new(hbX+math.floor(capIt.ch*hbW)-1,hbY-3)
                                        for _,cl in ipairs(cells) do cl.d.Color=hsv(capIt.ch,cl.s,cl.v) end
                                        local nc=hsv(capIt.ch,capIt.cs,capIt.cv)
                                        capIt.col=nc; swBg.Color=nc; prevSw.Color=nc; hexLabel.Text=hexStr(nc)
                                        if capIt.cb then capIt.cb(nc) end
                                    end
                                    if h.dS and cpOpen then
                                        capIt.cs=math.clamp((m2.X-svX)/svW,0,1)
                                        capIt.cv=1-math.clamp((m2.Y-svY)/svH,0,1)
                                        svCur.Position=Vector2.new(svX+math.floor(capIt.cs*svW)-5,svY+math.floor((1-capIt.cv)*svH)-5)
                                        local nc=hsv(capIt.ch,capIt.cs,capIt.cv)
                                        capIt.col=nc; swBg.Color=nc; prevSw.Color=nc; hexLabel.Text=hexStr(nc)
                                        if capIt.cb then capIt.cb(nc) end
                                    end
                                    swBrd.Color=cpOpen and C.mauve or C.brd2
                                    h.wd=d
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
                            if inView then
                                spawnLoop(function(h)
                                    local d=ismouse1pressed()
                                    if d and not h.wd then
                                        capIt.focused=over(tbBg.Position,tbBg.Size)
                                    end
                                    tbBrd.Color=capIt.focused and C.mauve or C.brd
                                    tbBg.Color=capIt.focused and C.surface1 or C.surface0
                                    if capIt.focused then
                                        for kc=8,90 do
                                            if iskeypressed(kc) then
                                                if not h.kd[kc] then
                                                    if kc==8 then capIt.val=capIt.val:sub(1,-2)
                                                    elseif kc==13 then
                                                        capIt.focused=false
                                                        if capIt.cb then capIt.cb(capIt.val) end
                                                        print("[TEXTBOX]",capIt.label,capIt.val)
                                                    elseif kc==27 then capIt.focused=false
                                                    elseif kc==32 then if #capIt.val<40 then capIt.val=capIt.val.." " end
                                                    elseif kc>=48 and kc<=57 then if #capIt.val<40 then capIt.val=capIt.val..string.char(kc) end
                                                    elseif kc>=65 and kc<=90 then
                                                        if #capIt.val<40 then
                                                            local ch3=iskeypressed(0x10) and string.char(kc) or string.char(kc+32)
                                                            capIt.val=capIt.val..ch3
                                                        end
                                                    end
                                                    h.kd[kc]=true
                                                end
                                            else h.kd[kc]=false end
                                        end
                                    end
                                    local disp=capIt.val=="" and capIt.placeholder or capIt.val
                                    local cursor=capIt.focused and "_" or ""
                                    tbTxt.Text=capIt.val=="" and capIt.placeholder or (capIt.val..cursor)
                                    tbTxt.Color=capIt.val=="" and C.overlay0 or C.text
                                    h.wd=d
                                end)
                            end
                            iy=iy+BH+2

                        elseif it.kind=="kb" then
                            local capIt=it
                            local kbBg =mk("Square",{Filled=true,Color=C.surface0,Size=Vector2.new(74,22),Position=Vector2.new(cx+colW2-PAD-74,iy+4),Corner=5,ZIndex=13,Visible=true})
                            local kbBrd=mk("Square",{Filled=false,Color=C.brd,Size=Vector2.new(74,22),Position=Vector2.new(cx+colW2-PAD-74,iy+4),Corner=5,Thickness=1,ZIndex=14,Visible=true})
                            local kbLbl=mk("Text",{Text=it.label,Size=FSS,Color=C.subtext1,Font=FONT,Position=Vector2.new(cx+PAD,iy+6),ZIndex=13,Visible=true})
                            local kname=KNAMES[it.kc] or "None"
                            local kbTxt=mk("Text",{Text="["..kname.."]",Size=FSX,Color=C.mauve,Font=FONTB,Position=Vector2.new(cx+colW2-PAD-74+8,iy+7),ZIndex=15,Visible=true})
                            if inView then
                                spawnLoop(function(h)
                                    local d=ismouse1pressed()
                                    if d and not h.wd then
                                        if over(kbBg.Position,kbBg.Size) then
                                            capIt.binding=true; kbTxt.Text="[...]"; kbBrd.Color=C.mauve
                                        end
                                    end
                                    if capIt.binding then
                                        kbBg.Color=C.surface1
                                        for kname2,kc2 in pairs(KCODES) do
                                            if kc2~=0 and iskeypressed(kc2) then
                                                capIt.kc=kc2; capIt.binding=false
                                                kbTxt.Text="["..kname2.."]"; kbBrd.Color=C.brd
                                                kbBg.Color=C.surface0
                                                if capIt.cb then capIt.cb(kc2,kname2) end
                                                print("[KEYBIND]",capIt.label,kname2)
                                            end
                                        end
                                    else
                                        local hov=over(kbBg.Position,kbBg.Size)
                                        kbBg.Color=hov and C.surface1 or C.surface0
                                    end
                                    h.wd=d
                                end)
                            end
                            iy=iy+IH
                        end
                    end
                end
            end
        end

        if totalH>contentH then
            local sbH=math.max(24,math.floor(contentH*(contentH/math.max(1,totalH))))
            local sbMaxY=contentH-sbH
            local sbY=lib.py+TB+CP+math.floor((sY/math.max(1,maxScroll))*sbMaxY)
            mk("Square",{Filled=true,Color=C.surface2,Size=Vector2.new(3,sbH),Position=Vector2.new(lib.px+lib.sw-5,sbY),Corner=2,ZIndex=18,Visible=true})
        end

        if q and q~="" and #layouts==0 then
            local noW=tw("no results",FSS)+20
            mk("Square",{Filled=true,Color=C.mantle,Size=Vector2.new(noW,30),Position=Vector2.new(lib.px+math.floor(lib.sw/2)-math.floor(noW/2),lib.py+TB+30),Corner=6,ZIndex=10,Visible=true})
            mk("Text",{Text="no results",Size=FSS,Color=C.overlay0,Font=FONT,Position=Vector2.new(lib.px+math.floor(lib.sw/2)-math.floor(tw("no results",FSS)/2),lib.py+TB+38),ZIndex=11,Visible=true})
        end
    end

    buildSecs()

    if lib.doSearch then
        spawn(function()
            local lastQ=""
            while lib.visible do
                local sx2=lib.px+tw(lib.title,FS)+26
                if srBg then
                    srBg.Position=Vector2.new(sx2,lib.py+8)
                    srBrd.Position=Vector2.new(sx2,lib.py+8)
                    srTxt.Position=Vector2.new(sx2+8,lib.py+12)
                end
                local d=ismouse1pressed()
                if d then
                    lib.sfocus=over(Vector2.new(sx2,lib.py+8),Vector2.new(srW,22))
                end
                if srBrd then srBrd.Color=lib.sfocus and C.mauve or C.brd end
                if srBg then srBg.Color=lib.sfocus and C.surface1 or C.surface0 end
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
                if srTxt then
                    srTxt.Text=lib.query=="" and "search..." or lib.query
                    srTxt.Color=lib.query=="" and C.overlay0 or C.text
                end
                if lib.query~=lastQ then lastQ=lib.query; buildSecs() end
                wait(0.016)
            end
        end)
    end

    spawn(function()
        local wd=false
        while lib.visible do
            local d=ismouse1pressed()
            local etw3=math.floor(TAB_AREA_W/numT)
            for i=1,numT do
                local tp=Vector2.new(TAB_AREA_X+(i-1)*etw3,lib.py)
                if over(tp,Vector2.new(etw3,TB)) and d and not wd and not openDD and not lib.sfocus then
                    if lib.activeTab~=i then
                        lib.activeTab=i
                        openDD=nil
                        for j,td in ipairs(tabDs) do
                            local isA2=(j==i)
                            td.td.Color=isA2 and C.mauve or C.overlay1
                            td.td.Font=isA2 and FONTB or FONT
                        end
                        slideTargX=TAB_AREA_X+(i-1)*etw3+8
                        buildSecs()
                    end
                end
            end
            slideX=lerp(slideX,slideTargX,0.2)
            slideLine.Position=Vector2.new(slideX,lib.py+TB-3)
            wd=d; wait(0.016)
        end
    end)

    spawn(function()
        local drag=false; local ds=nil; local spx=0; local spy=0; local wd=false
        while lib.visible do
            local d=ismouse1pressed(); local m2=mp()
            local topPos=Vector2.new(lib.px,lib.py)
            local topSz=Vector2.new(lib.sw,TB)
            if d and not wd and over(topPos,topSz) and not openDD and not lib.sfocus then
                drag=true; ds=m2; spx=lib.px; spy=lib.py
            end
            if not d then drag=false end
            if drag then
                lib.px=spx+(m2.X-ds.X)
                lib.py=spy+(m2.Y-ds.Y)
                rebuildChrome(); buildSecs()
            end
            wd=d; wait(0.016)
        end
    end)

    spawn(function()
        while lib.visible do
            local inContent=over(Vector2.new(lib.px,lib.py+TB),Vector2.new(lib.sw,lib.sh-TB))
            if inContent then
                local at=lib.activeTab
                if not lib.scrollY[at] then lib.scrollY[at]=0 end
                local cur2=lib.tabs[at]
                if cur2 then
                    local col1H=0; local col2H=0
                    local q=lib.query
                    for si,sec in ipairs(cur2.sections) do
                        if secVisible(sec,q) then
                            local ch=secH(sec,q)
                            if ch>0 then
                                if si%2==1 then col1H=col1H+ch+CP else col2H=col2H+ch+CP end
                            end
                        end
                    end
                    local totalH2=math.max(col1H,col2H)
                    local maxS=math.max(0,totalH2-contentH)
                    if iskeypressed(0x26) then
                        lib.scrollY[at]=math.max(0,lib.scrollY[at]-SCROLL_SPEED)
                        buildSecs(); wait(0.05)
                    elseif iskeypressed(0x28) then
                        lib.scrollY[at]=math.min(maxS,lib.scrollY[at]+SCROLL_SPEED)
                        buildSecs(); wait(0.05)
                    else wait(0.016) end
                else wait(0.016) end
            else wait(0.05) end
        end
    end)

    spawn(function()
        local wd=false
        while true do
            if iskeypressed(lib.toggleKey) then
                if not wd then
                    lib.visible=not lib.visible
                    local v=lib.visible
                    winBg.Visible=v; winBrd.Visible=v; topBg.Visible=v
                    topFill.Visible=v; topBrd.Visible=v; titTxt.Visible=v
                    slideLine.Visible=v
                    if srBg then srBg.Visible=v; srBrd.Visible=v; srTxt.Visible=v end
                    for _,td in ipairs(tabDs) do td.td.Visible=v end
                    for _,d2 in ipairs(secDs) do d2.Visible=v end
                    wd=true
                end
            else wd=false end
            wait(0.05)
        end
    end)
end

function SyftLib:Close()
    self.visible=false
    for _,d in ipairs(drawings) do d:Remove() end
end

_G.SyftLib=SyftLib
return SyftLib
