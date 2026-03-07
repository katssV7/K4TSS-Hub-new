--[[
    K4TSS HUB V3.0
    Tabs: Waypoints | Players | Speed | Settings
    Hotkey: G = Toggle GUI
]]

-- ══════════════════════════════════════════════
--  SERVICES (semua via pcall agar tidak crash)
-- ══════════════════════════════════════════════
local Players          = game:GetService("Players")
local UIS              = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local LocalPlayer      = Players.LocalPlayer

-- Tunggu karakter siap
if not LocalPlayer.Character then
    LocalPlayer.CharacterAdded:Wait()
end

-- ══════════════════════════════════════════════
--  HELPER: karakter
-- ══════════════════════════════════════════════
local function GetHRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function GetHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- ══════════════════════════════════════════════
--  DATA (in-memory, opsional simpan ke file)
-- ══════════════════════════════════════════════
local Folders = {}          -- { name, waypoints={}, loopDelay=3, loopActive=false }
local canFile = typeof(writefile)=="function" and typeof(readfile)=="function"
local FILE    = "K4TSS_v3.json"

-- JSON sederhana (pure Lua, tanpa HttpService)
local function jsonEncode(v)
    local t = type(v)
    if t=="nil"     then return "null" end
    if t=="boolean" then return tostring(v) end
    if t=="number"  then return tostring(v) end
    if t=="string"  then return '"'..v:gsub('\\','\\\\'):gsub('"','\\"')..'"' end
    if t=="table"   then
        if #v>0 then
            local a={}; for _,x in ipairs(v) do a[#a+1]=jsonEncode(x) end
            return "["..table.concat(a,",").."]"
        else
            local a={}
            for k,x in pairs(v) do
                if type(k)=="string" then a[#a+1]=jsonEncode(k)..":"..jsonEncode(x) end
            end
            return "{"..table.concat(a,",").."}"
        end
    end
    return "null"
end
local function jsonDecode(s)
    if not s or s=="" then return nil end
    -- coba HttpService kalau tersedia
    local ok,res = pcall(function()
        return game:GetService("HttpService"):JSONDecode(s)
    end)
    return ok and res or nil
end

local function saveData()
    if not canFile then return end
    pcall(function() writefile(FILE, jsonEncode(Folders)) end)
end
local function loadData()
    if not canFile then return end
    local ok,s = pcall(function() return readfile(FILE) end)
    if not ok or not s or s=="" then return end
    local d = jsonDecode(s)
    if type(d)=="table" then
        Folders = d
        for _,f in ipairs(Folders) do
            f.loopActive = false
            f.loopDelay  = f.loopDelay or 3
        end
    end
end
loadData()
task.spawn(function() while task.wait(30) do saveData() end end)

-- ══════════════════════════════════════════════
--  TELEPORT
-- ══════════════════════════════════════════════
local function tpTo(x,y,z)
    local hrp = GetHRP()
    if hrp then hrp.CFrame = CFrame.new(x,y,z) end
end

-- ══════════════════════════════════════════════
--  LOOP MANAGER
-- ══════════════════════════════════════════════
local loopThreads = {}
local function stopLoop(idx)
    if loopThreads[idx] then task.cancel(loopThreads[idx]); loopThreads[idx]=nil end
    if Folders[idx] then Folders[idx].loopActive=false end
end
local function startLoop(idx, onStep)
    stopLoop(idx)
    local f = Folders[idx]
    if not f or #f.waypoints<2 then return end
    f.loopActive = true
    loopThreads[idx] = task.spawn(function()
        local i=1
        while f.loopActive do
            local wp = f.waypoints[i]
            if wp then tpTo(wp.x,wp.y,wp.z); if onStep then onStep(i) end end
            task.wait(f.loopDelay or 3)
            i = i<#f.waypoints and i+1 or 1
        end
    end)
end

-- ══════════════════════════════════════════════
--  GUI SETUP
-- ══════════════════════════════════════════════
-- Hapus GUI lama
pcall(function()
    local old = LocalPlayer.PlayerGui:FindFirstChild("K4TSSv3")
    if old then old:Destroy() end
end)
pcall(function()
    local old = game:GetService("CoreGui"):FindFirstChild("K4TSSv3")
    if old then old:Destroy() end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "K4TSSv3"
ScreenGui.ResetOnSpawn   = false
ScreenGui.DisplayOrder   = 999
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local parented = false
pcall(function() ScreenGui.Parent = LocalPlayer.PlayerGui; parented=true end)
if not parented then
    pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
end

-- ══════════════════════════════════════════════
--  WARNA
-- ══════════════════════════════════════════════
local C = {
    BG      = Color3.fromRGB(24,24,24),
    SIDEBAR = Color3.fromRGB(32,32,32),
    CONTENT = Color3.fromRGB(20,20,20),
    TITLEBAR= Color3.fromRGB(36,36,36),
    ROW     = Color3.fromRGB(30,30,30),
    ROWALT  = Color3.fromRGB(26,26,26),
    DIVIDER = Color3.fromRGB(48,48,48),
    ACCENT  = Color3.fromRGB(220,50,50),
    ACCENT2 = Color3.fromRGB(150,15,15),
    GREEN   = Color3.fromRGB(60,200,90),
    GREEND  = Color3.fromRGB(35,130,55),
    BLUE    = Color3.fromRGB(50,130,255),
    BLUED   = Color3.fromRGB(25,80,200),
    GOLD    = Color3.fromRGB(255,185,50),
    TW      = Color3.fromRGB(225,225,225),
    TG      = Color3.fromRGB(130,130,130),
    TD      = Color3.fromRGB(70,70,70),
    STATUS  = Color3.fromRGB(28,28,28),
}

-- ══════════════════════════════════════════════
--  WINDOW
-- ══════════════════════════════════════════════
local WIN_FULL = UDim2.new(0,520,0,350)
local WIN_MINI = UDim2.new(0,150,0,28)

local Window = Instance.new("Frame", ScreenGui)
Window.Name             = "Window"
Window.Size             = WIN_FULL
Window.Position         = UDim2.new(0.5,-260,0.5,-175)
Window.BackgroundColor3 = C.BG
Window.BorderSizePixel  = 0
Window.ClipsDescendants = true
Instance.new("UICorner",Window).CornerRadius = UDim.new(0,6)
local ws = Instance.new("UIStroke",Window); ws.Color=Color3.fromRGB(55,55,55); ws.Thickness=1

-- TITLEBAR
local TBar = Instance.new("Frame",Window)
TBar.Size=UDim2.new(1,0,0,32); TBar.BackgroundColor3=C.TITLEBAR; TBar.BorderSizePixel=0; TBar.ZIndex=10
Instance.new("UICorner",TBar).CornerRadius=UDim.new(0,5)
-- fix radius bawah
local fix=Instance.new("Frame",TBar); fix.Size=UDim2.new(1,0,0,6); fix.Position=UDim2.new(0,0,1,-6)
fix.BackgroundColor3=C.TITLEBAR; fix.BorderSizePixel=0; fix.ZIndex=10
-- accent bar kiri
local acc=Instance.new("Frame",TBar); acc.Size=UDim2.new(0,3,0.65,0); acc.Position=UDim2.new(0,0,0.175,0)
acc.BackgroundColor3=C.ACCENT; acc.BorderSizePixel=0; acc.ZIndex=11
-- title text
local TTitle=Instance.new("TextLabel",TBar)
TTitle.Text="K4TSS  V3.0  ·  Hub"; TTitle.Size=UDim2.new(1,-80,1,0); TTitle.Position=UDim2.new(0,12,0,0)
TTitle.BackgroundTransparency=1; TTitle.TextColor3=C.TW; TTitle.Font=Enum.Font.GothamBold
TTitle.TextSize=11; TTitle.TextXAlignment=Enum.TextXAlignment.Left; TTitle.ZIndex=11

-- Tombol titlebar
local function makeTBtn(txt, xOff, col)
    local b=Instance.new("TextButton",TBar)
    b.Text=txt; b.Size=UDim2.new(0,26,0,22); b.Position=UDim2.new(1,xOff,0.5,-11)
    b.BackgroundColor3=col or Color3.fromRGB(55,55,55); b.BackgroundTransparency=0.4
    b.TextColor3=C.TW; b.Font=Enum.Font.GothamBold; b.TextSize=14
    b.BorderSizePixel=0; b.ZIndex=12
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,4)
    b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(0.08),{BackgroundTransparency=0.1}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(0.08),{BackgroundTransparency=0.4}):Play() end)
    return b
end
local BtnClose = makeTBtn("×",-30, Color3.fromRGB(180,40,40))
local BtnMin   = makeTBtn("–",-60)

-- DRAG
do
    local drag,ds,ws2=false,Vector2.zero,UDim2.new()
    TBar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            drag=true; ds=Vector2.new(i.Position.X,i.Position.Y); ws2=Window.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if not drag then return end
        if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
            local d=Vector2.new(i.Position.X,i.Position.Y)-ds
            Window.Position=UDim2.new(ws2.X.Scale,ws2.X.Offset+d.X,ws2.Y.Scale,ws2.Y.Offset+d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
end

-- BODY
local Body=Instance.new("Frame",Window)
Body.Name="Body"; Body.Size=UDim2.new(1,0,1,-32); Body.Position=UDim2.new(0,0,0,32)
Body.BackgroundTransparency=1; Body.ClipsDescendants=true

-- SIDEBAR
local Sidebar=Instance.new("Frame",Body)
Sidebar.Size=UDim2.new(0,110,1,-28); Sidebar.BackgroundColor3=C.SIDEBAR; Sidebar.BorderSizePixel=0
local SLL=Instance.new("UIListLayout",Sidebar)
SLL.FillDirection=Enum.FillDirection.Vertical; SLL.SortOrder=Enum.SortOrder.LayoutOrder

-- CONTENT
local Content=Instance.new("Frame",Body)
Content.Size=UDim2.new(1,-110,1,-28); Content.Position=UDim2.new(0,110,0,0)
Content.BackgroundColor3=C.CONTENT; Content.BorderSizePixel=0; Content.ClipsDescendants=true
local cdiv=Instance.new("Frame",Content); cdiv.Size=UDim2.new(0,1,1,0); cdiv.BackgroundColor3=C.DIVIDER; cdiv.BorderSizePixel=0

-- STATUSBAR
local StatusBar=Instance.new("Frame",Body)
StatusBar.Size=UDim2.new(1,0,0,28); StatusBar.Position=UDim2.new(0,0,1,-28)
StatusBar.BackgroundColor3=C.STATUS; StatusBar.BorderSizePixel=0
local sl=Instance.new("Frame",StatusBar); sl.Size=UDim2.new(1,0,0,1); sl.BackgroundColor3=C.DIVIDER; sl.BorderSizePixel=0

local StatusLbl=Instance.new("TextLabel",StatusBar)
StatusLbl.Size=UDim2.new(0.6,0,1,0); StatusLbl.Position=UDim2.new(0,10,0,0)
StatusLbl.BackgroundTransparency=1; StatusLbl.TextColor3=C.TG
StatusLbl.Font=Enum.Font.Gotham; StatusLbl.TextSize=10
StatusLbl.TextXAlignment=Enum.TextXAlignment.Left
StatusLbl.Text="👤 "..LocalPlayer.Name

local SaveLbl=Instance.new("TextLabel",StatusBar)
SaveLbl.Size=UDim2.new(0.4,-8,1,0); SaveLbl.Position=UDim2.new(0.6,0,0,0)
SaveLbl.BackgroundTransparency=1; SaveLbl.TextColor3=C.TG
SaveLbl.Font=Enum.Font.Gotham; SaveLbl.TextSize=10
SaveLbl.TextXAlignment=Enum.TextXAlignment.Right
SaveLbl.Text=canFile and "💾 file" or "💾 sesi"

-- ══════════════════════════════════════════════
--  TAB SYSTEM
-- ══════════════════════════════════════════════
local tabBtns={} local tabPages={} local activeTab=nil

local function switchTab(name)
    if activeTab==name then return end
    activeTab=name
    for n,p in pairs(tabPages) do p.Visible=(n==name) end
    for n,b in pairs(tabBtns) do
        local on=(n==name)
        local bar=b:FindFirstChild("Bar"); if bar then bar.Visible=on end
        local lbl=b:FindFirstChild("Lbl")
        if lbl then lbl.TextColor3=on and C.TW or C.TG; lbl.Font=on and Enum.Font.GothamSemibold or Enum.Font.Gotham end
        TweenService:Create(b,TweenInfo.new(0.1),{BackgroundColor3=on and Color3.fromRGB(40,40,40) or C.SIDEBAR}):Play()
    end
end

local function newTab(name, lo)
    local btn=Instance.new("TextButton",Sidebar)
    btn.Name="T_"..name; btn.Size=UDim2.new(1,0,0,34); btn.BackgroundColor3=C.SIDEBAR
    btn.BorderSizePixel=0; btn.Text=""; btn.LayoutOrder=lo; btn.ZIndex=7
    local bar=Instance.new("Frame",btn); bar.Name="Bar"
    bar.Size=UDim2.new(0,3,0.6,0); bar.Position=UDim2.new(0,0,0.2,0)
    bar.BackgroundColor3=C.ACCENT; bar.BorderSizePixel=0; bar.Visible=false
    local lbl=Instance.new("TextLabel",btn); lbl.Name="Lbl"; lbl.Text=name
    lbl.Size=UDim2.new(1,-14,1,0); lbl.Position=UDim2.new(0,14,0,0)
    lbl.BackgroundTransparency=1; lbl.TextColor3=C.TG; lbl.Font=Enum.Font.Gotham
    lbl.TextSize=11; lbl.TextXAlignment=Enum.TextXAlignment.Left
    btn.MouseEnter:Connect(function() if activeTab~=name then TweenService:Create(btn,TweenInfo.new(0.08),{BackgroundColor3=Color3.fromRGB(38,38,38)}):Play() end end)
    btn.MouseLeave:Connect(function() if activeTab~=name then TweenService:Create(btn,TweenInfo.new(0.08),{BackgroundColor3=C.SIDEBAR}):Play() end end)
    btn.MouseButton1Click:Connect(function() switchTab(name) end)

    local page=Instance.new("ScrollingFrame",Content)
    page.Name="P_"..name; page.Size=UDim2.new(1,-2,1,0); page.Position=UDim2.new(0,2,0,0)
    page.BackgroundTransparency=1; page.BorderSizePixel=0; page.Visible=false
    page.ScrollBarThickness=3; page.ScrollBarImageColor3=C.ACCENT
    page.CanvasSize=UDim2.new(0,0,0,0); page.AutomaticCanvasSize=Enum.AutomaticSize.Y; page.ZIndex=7
    local pl=Instance.new("UIListLayout",page)
    pl.Padding=UDim.new(0,0); pl.SortOrder=Enum.SortOrder.LayoutOrder
    Instance.new("UIPadding",page).PaddingTop=UDim.new(0,4)
    tabPages[name]=page; tabBtns[name]=btn
    return page
end

-- ══════════════════════════════════════════════
--  UI HELPERS
-- ══════════════════════════════════════════════
local function makeRow(parent, lo, h)
    local f=Instance.new("Frame",parent)
    f.Size=UDim2.new(1,0,0,h or 44); f.BackgroundColor3=C.ROW; f.BorderSizePixel=0; f.LayoutOrder=lo; f.ZIndex=8
    local line=Instance.new("Frame",f); line.Size=UDim2.new(1,0,0,1); line.Position=UDim2.new(0,0,1,-1)
    line.BackgroundColor3=C.DIVIDER; line.BorderSizePixel=0
    return f
end

local function makeHeader(parent, lo, txt)
    local f=Instance.new("Frame",parent)
    f.Size=UDim2.new(1,0,0,20); f.BackgroundTransparency=1; f.BorderSizePixel=0; f.LayoutOrder=lo
    local l=Instance.new("TextLabel",f); l.Text=txt; l.Size=UDim2.new(1,-10,1,0); l.Position=UDim2.new(0,10,0,0)
    l.BackgroundTransparency=1; l.TextColor3=C.TD; l.Font=Enum.Font.Gotham; l.TextSize=9; l.TextXAlignment=Enum.TextXAlignment.Left
    return f
end

local function makeBtn(parent, txt, bg, pos, w, h)
    local b=Instance.new("TextButton",parent)
    b.Text=txt; b.Size=UDim2.new(0,w or 50,0,h or 24); b.Position=pos or UDim2.new(0,0,0,0)
    b.BackgroundColor3=bg; b.TextColor3=C.TW; b.Font=Enum.Font.GothamBold; b.TextSize=11
    b.BorderSizePixel=0; b.ZIndex=9
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,4)
    local dk=Color3.fromRGB(math.max(0,bg.R*255-25),math.max(0,bg.G*255-25),math.max(0,bg.B*255-25))
    b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(0.07),{BackgroundColor3=dk}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(0.07),{BackgroundColor3=bg}):Play() end)
    return b
end

local function makeInput(parent, ph, pos, w, h)
    local b=Instance.new("TextBox",parent)
    b.PlaceholderText=ph or ""; b.Text=""
    b.Size=UDim2.new(0,w or 100,0,h or 24); b.Position=pos or UDim2.new(0,0,0,0)
    b.BackgroundColor3=Color3.fromRGB(18,18,18); b.TextColor3=C.TW
    b.PlaceholderColor3=C.TD; b.Font=Enum.Font.Gotham; b.TextSize=11
    b.BorderSizePixel=0; b.ClearTextOnFocus=false; b.ZIndex=9
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,4)
    local st=Instance.new("UIStroke",b); st.Color=C.DIVIDER; st.Thickness=1
    return b
end

-- ══════════════════════════════════════════════
--  TAB: WAYPOINTS
-- ══════════════════════════════════════════════
local WPTab = newTab("Waypoints",1)
local selFolder = nil
local RefreshFolders, RefreshWP  -- forward declare

-- Header folder
local fhRow=makeRow(WPTab,1,42); fhRow.BackgroundColor3=Color3.fromRGB(26,26,26)
local fhLbl=Instance.new("TextLabel",fhRow); fhLbl.Text="📁  Folders"
fhLbl.Size=UDim2.new(0.5,0,1,0); fhLbl.Position=UDim2.new(0,8,0,0)
fhLbl.BackgroundTransparency=1; fhLbl.TextColor3=C.TW; fhLbl.Font=Enum.Font.GothamBold; fhLbl.TextSize=11; fhLbl.TextXAlignment=Enum.TextXAlignment.Left
local fInput=makeInput(fhRow,"Nama folder...",UDim2.new(0,96,0.5,-11),108,22)
local fAddBtn=makeBtn(fhRow,"+Folder",C.GREEND,UDim2.new(1,-72,0.5,-11),62,22)

-- Folder list container
local FolderList=Instance.new("Frame",WPTab); FolderList.Name="FL"
FolderList.Size=UDim2.new(1,0,0,0); FolderList.AutomaticSize=Enum.AutomaticSize.Y
FolderList.BackgroundTransparency=1; FolderList.BorderSizePixel=0; FolderList.LayoutOrder=2; FolderList.ZIndex=8
local FLL=Instance.new("UIListLayout",FolderList); FLL.SortOrder=Enum.SortOrder.LayoutOrder

-- Separator
local sep=Instance.new("Frame",WPTab); sep.Size=UDim2.new(1,0,0,5)
sep.BackgroundColor3=Color3.fromRGB(20,20,20); sep.BorderSizePixel=0; sep.LayoutOrder=3

-- Header WP
local wphRow=makeRow(WPTab,4,42); wphRow.BackgroundColor3=Color3.fromRGB(26,26,26)
local wphLbl=Instance.new("TextLabel",wphRow); wphLbl.Text="📍  Waypoints"
wphLbl.Size=UDim2.new(0.45,0,1,0); wphLbl.Position=UDim2.new(0,8,0,0)
wphLbl.BackgroundTransparency=1; wphLbl.TextColor3=C.TG; wphLbl.Font=Enum.Font.GothamBold; wphLbl.TextSize=11; wphLbl.TextXAlignment=Enum.TextXAlignment.Left
local wpInput=makeInput(wphRow,"Nama waypoint...",UDim2.new(0,96,0.5,-11),104,22)
local wpAddBtn=makeBtn(wphRow,"+WP",C.BLUED,UDim2.new(1,-52,0.5,-11),44,22)

-- Loop row
local loopRow=makeRow(WPTab,5,34); loopRow.BackgroundColor3=Color3.fromRGB(22,22,22)
local loopLbl=Instance.new("TextLabel",loopRow); loopLbl.Text="🔁 Loop TP"
loopLbl.Size=UDim2.new(0.3,0,1,0); loopLbl.Position=UDim2.new(0,8,0,0)
loopLbl.BackgroundTransparency=1; loopLbl.TextColor3=C.TG; loopLbl.Font=Enum.Font.GothamSemibold; loopLbl.TextSize=10; loopLbl.TextXAlignment=Enum.TextXAlignment.Left
local loopStepLbl=Instance.new("TextLabel",loopRow); loopStepLbl.Text="—"
loopStepLbl.Size=UDim2.new(0.25,0,1,0); loopStepLbl.Position=UDim2.new(0.28,0,0,0)
loopStepLbl.BackgroundTransparency=1; loopStepLbl.TextColor3=C.GOLD; loopStepLbl.Font=Enum.Font.GothamBold; loopStepLbl.TextSize=10; loopStepLbl.TextXAlignment=Enum.TextXAlignment.Center
local delayLbl=Instance.new("TextLabel",loopRow); delayLbl.Text="Delay:"
delayLbl.Size=UDim2.new(0,36,1,0); delayLbl.Position=UDim2.new(0.54,0,0,0)
delayLbl.BackgroundTransparency=1; delayLbl.TextColor3=C.TG; delayLbl.Font=Enum.Font.Gotham; delayLbl.TextSize=9; delayLbl.TextXAlignment=Enum.TextXAlignment.Right
local delayInput=makeInput(loopRow,"3",UDim2.new(0.54,40,0.5,-10),30,20); delayInput.Text="3"
local loopStartBtn=makeBtn(loopRow,"▶",C.GREEND,UDim2.new(1,-78,0.5,-11),34,22)
local loopStopBtn =makeBtn(loopRow,"■",C.ACCENT2,UDim2.new(1,-40,0.5,-11),34,22)

-- WP list container
local WPList=Instance.new("Frame",WPTab); WPList.Name="WL"
WPList.Size=UDim2.new(1,0,0,0); WPList.AutomaticSize=Enum.AutomaticSize.Y
WPList.BackgroundTransparency=1; WPList.BorderSizePixel=0; WPList.LayoutOrder=6; WPList.ZIndex=8
local WLL=Instance.new("UIListLayout",WPList); WLL.SortOrder=Enum.SortOrder.LayoutOrder

-- Refresh folder list
RefreshFolders = function()
    for _,c in ipairs(FolderList:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
    if #Folders==0 then
        local e=makeRow(FolderList,1,28); e.BackgroundColor3=C.ROWALT
        local el=Instance.new("TextLabel",e); el.Text="Belum ada folder"
        el.Size=UDim2.new(1,0,1,0); el.BackgroundTransparency=1; el.TextColor3=C.TD; el.Font=Enum.Font.Gotham; el.TextSize=10
        return
    end
    for i,folder in ipairs(Folders) do
        local r=makeRow(FolderList,i,32)
        r.BackgroundColor3 = (selFolder==i) and Color3.fromRGB(40,40,40) or C.ROW
        local sb=Instance.new("Frame",r); sb.Size=UDim2.new(0,3,0.65,0); sb.Position=UDim2.new(0,0,0.175,0)
        sb.BackgroundColor3=C.GOLD; sb.BorderSizePixel=0; sb.Visible=(selFolder==i)
        local fl=Instance.new("TextLabel",r); fl.Text="📁 "..folder.name
        fl.Size=UDim2.new(1,-90,1,0); fl.Position=UDim2.new(0,14,0,0)
        fl.BackgroundTransparency=1; fl.TextColor3=(selFolder==i) and C.GOLD or C.TW
        fl.Font=(selFolder==i) and Enum.Font.GothamSemibold or Enum.Font.Gotham; fl.TextSize=11; fl.TextXAlignment=Enum.TextXAlignment.Left
        local wc=Instance.new("TextLabel",r); wc.Text=tostring(#folder.waypoints).."wp"
        wc.Size=UDim2.new(0,28,1,0); wc.Position=UDim2.new(1,-56,0,0)
        wc.BackgroundTransparency=1; wc.TextColor3=C.TD; wc.Font=Enum.Font.Gotham; wc.TextSize=9; wc.TextXAlignment=Enum.TextXAlignment.Right
        if folder.loopActive then
            local li=Instance.new("TextLabel",r); li.Text="🔁"
            li.Size=UDim2.new(0,18,1,0); li.Position=UDim2.new(1,-76,0,0)
            li.BackgroundTransparency=1; li.TextColor3=C.GREEN; li.Font=Enum.Font.Gotham; li.TextSize=11; li.TextXAlignment=Enum.TextXAlignment.Center
        end
        local db=makeBtn(r,"✕",C.ACCENT2,UDim2.new(1,-26,0.5,-9),22,18)
        db.TextSize=9
        db.MouseButton1Click:Connect(function()
            stopLoop(i)
            if selFolder==i then selFolder=nil; RefreshWP()
            elseif selFolder and selFolder>i then selFolder=selFolder-1 end
            table.remove(Folders,i); RefreshFolders(); saveData()
        end)
        local sb2=Instance.new("TextButton",r); sb2.Size=UDim2.new(1,-28,1,0); sb2.BackgroundTransparency=1; sb2.Text=""; sb2.ZIndex=9
        sb2.MouseButton1Click:Connect(function() selFolder=i; RefreshFolders(); RefreshWP() end)
        sb2.MouseEnter:Connect(function() if selFolder~=i then TweenService:Create(r,TweenInfo.new(0.07),{BackgroundColor3=Color3.fromRGB(36,36,36)}):Play() end end)
        sb2.MouseLeave:Connect(function() if selFolder~=i then TweenService:Create(r,TweenInfo.new(0.07),{BackgroundColor3=C.ROW}):Play() end end)
    end
end

RefreshWP = function()
    for _,c in ipairs(WPList:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
    if not selFolder or not Folders[selFolder] then
        wphLbl.Text="📍  Waypoints  —  pilih folder"; wphLbl.TextColor3=C.TG; return
    end
    local folder=Folders[selFolder]
    wphLbl.Text="📍  "..folder.name; wphLbl.TextColor3=C.TW
    delayInput.Text=tostring(folder.loopDelay or 3)
    if #folder.waypoints==0 then
        local e=makeRow(WPList,1,30); e.BackgroundColor3=C.ROWALT
        local el=Instance.new("TextLabel",e); el.Text="Belum ada waypoint di folder ini"
        el.Size=UDim2.new(1,0,1,0); el.BackgroundTransparency=1; el.TextColor3=C.TD; el.Font=Enum.Font.Gotham; el.TextSize=10
        return
    end
    for i,wp in ipairs(folder.waypoints) do
        local r=makeRow(WPList,i,34)
        r.BackgroundColor3=(i%2==0) and C.ROWALT or C.ROW
        local nl=Instance.new("TextLabel",r); nl.Text=tostring(i)
        nl.Size=UDim2.new(0,20,1,0); nl.BackgroundTransparency=1; nl.TextColor3=C.TD; nl.Font=Enum.Font.GothamBold; nl.TextSize=9; nl.TextXAlignment=Enum.TextXAlignment.Center
        local wl=Instance.new("TextLabel",r); wl.Text="📍 "..wp.name
        wl.Size=UDim2.new(1,-138,0,18); wl.Position=UDim2.new(0,22,0,3)
        wl.BackgroundTransparency=1; wl.TextColor3=C.TW; wl.Font=Enum.Font.Gotham; wl.TextSize=11; wl.TextXAlignment=Enum.TextXAlignment.Left
        local cl=Instance.new("TextLabel",r); cl.Text=string.format("%.0f,%.0f,%.0f",wp.x,wp.y,wp.z)
        cl.Size=UDim2.new(1,-138,0,13); cl.Position=UDim2.new(0,22,1,-15)
        cl.BackgroundTransparency=1; cl.TextColor3=C.TD; cl.Font=Enum.Font.Gotham; cl.TextSize=9; cl.TextXAlignment=Enum.TextXAlignment.Left
        local tpb=makeBtn(r,"TP",C.BLUED,UDim2.new(1,-130,0.5,-10),34,20)
        tpb.MouseButton1Click:Connect(function() tpTo(wp.x,wp.y,wp.z) end)
        local ub=makeBtn(r,"▲",Color3.fromRGB(60,60,60),UDim2.new(1,-92,0.5,-10),20,20); ub.TextSize=8
        ub.MouseButton1Click:Connect(function()
            if i>1 then folder.waypoints[i],folder.waypoints[i-1]=folder.waypoints[i-1],folder.waypoints[i]; RefreshWP(); saveData() end
        end)
        local db2=makeBtn(r,"▼",Color3.fromRGB(60,60,60),UDim2.new(1,-70,0.5,-10),20,20); db2.TextSize=8
        db2.MouseButton1Click:Connect(function()
            if i<#folder.waypoints then folder.waypoints[i],folder.waypoints[i+1]=folder.waypoints[i+1],folder.waypoints[i]; RefreshWP(); saveData() end
        end)
        local xb=makeBtn(r,"✕",C.ACCENT2,UDim2.new(1,-46,0.5,-10),40,20); xb.TextSize=10
        xb.MouseButton1Click:Connect(function() table.remove(folder.waypoints,i); RefreshWP(); saveData() end)
        local hb=Instance.new("TextButton",r); hb.Size=UDim2.new(1,-140,1,0); hb.BackgroundTransparency=1; hb.Text=""; hb.ZIndex=7
        hb.MouseEnter:Connect(function() TweenService:Create(r,TweenInfo.new(0.07),{BackgroundColor3=Color3.fromRGB(40,40,40)}):Play() end)
        hb.MouseLeave:Connect(function() TweenService:Create(r,TweenInfo.new(0.07),{BackgroundColor3=(i%2==0) and C.ROWALT or C.ROW}):Play() end)
    end
end

-- Callbacks Waypoints
fAddBtn.MouseButton1Click:Connect(function()
    local n=fInput.Text; if n=="" then return end
    table.insert(Folders,{name=n,waypoints={},loopActive=false,loopDelay=3})
    fInput.Text=""; RefreshFolders(); saveData()
end)
wpAddBtn.MouseButton1Click:Connect(function()
    if not selFolder or not Folders[selFolder] then return end
    local n=wpInput.Text; if n=="" then return end
    local hrp=GetHRP(); if not hrp then return end
    local p=hrp.Position
    table.insert(Folders[selFolder].waypoints,{name=n,x=math.floor(p.X),y=math.floor(p.Y),z=math.floor(p.Z)})
    wpInput.Text=""; RefreshFolders(); RefreshWP(); saveData()
end)
loopStartBtn.MouseButton1Click:Connect(function()
    if not selFolder or not Folders[selFolder] then return end
    local f=Folders[selFolder]; if #f.waypoints<2 then return end
    f.loopDelay=math.clamp(tonumber(delayInput.Text) or 3, 0.5, 60)
    startLoop(selFolder,function(si)
        local wp=f.waypoints[si]
        if wp then loopStepLbl.Text="→"..si.."/"..#f.waypoints end
        RefreshFolders()
    end)
    loopStepLbl.Text="▶ Running"; RefreshFolders()
end)
loopStopBtn.MouseButton1Click:Connect(function()
    if not selFolder then return end
    stopLoop(selFolder); loopStepLbl.Text="—"; RefreshFolders()
end)

-- ══════════════════════════════════════════════
--  TAB: PLAYERS
-- ══════════════════════════════════════════════
local PLTab=newTab("Players",2)

local plHRow=makeRow(PLTab,1,42); plHRow.BackgroundColor3=Color3.fromRGB(26,26,26)
local plHLbl=Instance.new("TextLabel",plHRow); plHLbl.Text="👤  Player Teleport"
plHLbl.Size=UDim2.new(0.6,0,1,0); plHLbl.Position=UDim2.new(0,8,0,0)
plHLbl.BackgroundTransparency=1; plHLbl.TextColor3=C.TW; plHLbl.Font=Enum.Font.GothamBold; plHLbl.TextSize=11; plHLbl.TextXAlignment=Enum.TextXAlignment.Left
local scanBtn=makeBtn(plHRow,"🔍 Scan",C.BLUED,UDim2.new(1,-72,0.5,-11),62,22)

local plInfoRow=makeRow(PLTab,2,26); plInfoRow.BackgroundColor3=Color3.fromRGB(22,22,22)
local plInfoLbl=Instance.new("TextLabel",plInfoRow); plInfoLbl.Text="Klik Scan untuk memuat daftar player"
plInfoLbl.Size=UDim2.new(1,-10,1,0); plInfoLbl.Position=UDim2.new(0,8,0,0)
plInfoLbl.BackgroundTransparency=1; plInfoLbl.TextColor3=C.TG; plInfoLbl.Font=Enum.Font.Gotham; plInfoLbl.TextSize=10; plInfoLbl.TextXAlignment=Enum.TextXAlignment.Left

local PLList=Instance.new("Frame",PLTab); PLList.Name="PLL"
PLList.Size=UDim2.new(1,0,0,0); PLList.AutomaticSize=Enum.AutomaticSize.Y
PLList.BackgroundTransparency=1; PLList.BorderSizePixel=0; PLList.LayoutOrder=3; PLList.ZIndex=8
local PLLL=Instance.new("UIListLayout",PLList); PLLL.SortOrder=Enum.SortOrder.LayoutOrder

local function refreshPlayers()
    for _,c in ipairs(PLList:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
    local list=Players:GetPlayers()
    local count=0
    for i,plr in ipairs(list) do
        if plr==LocalPlayer then continue end
        count=count+1
        local r=makeRow(PLList,count,38)
        r.BackgroundColor3=(count%2==0) and C.ROWALT or C.ROW
        -- avatar
        local av=Instance.new("Frame",r); av.Size=UDim2.new(0,26,0,26); av.Position=UDim2.new(0,8,0.5,-13)
        av.BackgroundColor3=Color3.fromRGB(45,45,45); av.BorderSizePixel=0
        Instance.new("UICorner",av).CornerRadius=UDim.new(1,0)
        local img=Instance.new("ImageLabel",av); img.Size=UDim2.new(1,0,1,0); img.BackgroundTransparency=1
        Instance.new("UICorner",img).CornerRadius=UDim.new(1,0)
        task.spawn(function()
            local ok,url=pcall(function() return Players:GetUserThumbnailAsync(plr.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size48x48) end)
            if ok then img.Image=url end
        end)
        local nl=Instance.new("TextLabel",r); nl.Text=plr.Name
        nl.Size=UDim2.new(1,-120,0,18); nl.Position=UDim2.new(0,40,0,4)
        nl.BackgroundTransparency=1; nl.TextColor3=C.TW; nl.Font=Enum.Font.GothamSemibold; nl.TextSize=11; nl.TextXAlignment=Enum.TextXAlignment.Left
        local tpb2=makeBtn(r,"TP →",C.BLUED,UDim2.new(1,-76,0.5,-11),66,22)
        tpb2.MouseButton1Click:Connect(function()
            tpb2.Text="..."; tpb2.BackgroundColor3=Color3.fromRGB(60,60,60)
            task.spawn(function()
                -- coba langsung
                local c2=plr.Character; local h2=c2 and c2:FindFirstChild("HumanoidRootPart")
                if h2 then
                    local cf=h2.CFrame*CFrame.new(4,0,0); tpTo(cf.X,cf.Y,cf.Z)
                    tpb2.Text="TP →"; tpb2.BackgroundColor3=C.BLUED
                    plInfoLbl.Text="✅ TP ke "..plr.Name; plInfoLbl.TextColor3=C.GREEN
                    task.delay(2,function() plInfoLbl.Text="🟢 "..count.." player ditemukan"; plInfoLbl.TextColor3=C.GREEN end)
                    return
                end
                -- step TP
                for s=1,15 do
                    local c3=plr.Character; local h3=c3 and c3:FindFirstChild("HumanoidRootPart")
                    if h3 then
                        local cf2=h3.CFrame*CFrame.new(4,0,0); tpTo(cf2.X,cf2.Y,cf2.Z)
                        tpb2.Text="TP →"; tpb2.BackgroundColor3=C.BLUED
                        plInfoLbl.Text="✅ TP ke "..plr.Name; plInfoLbl.TextColor3=C.GREEN
                        task.delay(2,function() plInfoLbl.Text="🟢 "..count.." player ditemukan"; plInfoLbl.TextColor3=C.GREEN end)
                        return
                    end
                    local myH=GetHRP()
                    if myH then local fwd=myH.CFrame.LookVector; tpTo(myH.Position.X+fwd.X*300,myH.Position.Y,myH.Position.Z+fwd.Z*300) end
                    task.wait(0.35)
                end
                tpb2.Text="TP →"; tpb2.BackgroundColor3=C.BLUED
                plInfoLbl.Text="⚠ "..plr.Name.." terlalu jauh"; plInfoLbl.TextColor3=C.ACCENT
                task.delay(3,function() plInfoLbl.Text="🟢 "..count.." player ditemukan"; plInfoLbl.TextColor3=C.GREEN end)
            end)
        end)
        local hb2=Instance.new("TextButton",r); hb2.Size=UDim2.new(1,-78,1,0); hb2.BackgroundTransparency=1; hb2.Text=""; hb2.ZIndex=7
        hb2.MouseEnter:Connect(function() TweenService:Create(r,TweenInfo.new(0.07),{BackgroundColor3=Color3.fromRGB(40,40,40)}):Play() end)
        hb2.MouseLeave:Connect(function() TweenService:Create(r,TweenInfo.new(0.07),{BackgroundColor3=(count%2==0) and C.ROWALT or C.ROW}):Play() end)
    end
    if count==0 then
        local e=makeRow(PLList,1,36); e.BackgroundColor3=C.ROWALT
        local el=Instance.new("TextLabel",e); el.Text="Tidak ada player lain di server ini"
        el.Size=UDim2.new(1,0,1,0); el.BackgroundTransparency=1; el.TextColor3=C.TD; el.Font=Enum.Font.Gotham; el.TextSize=10
        plInfoLbl.Text="Server kosong"; plInfoLbl.TextColor3=C.TD
    else
        plInfoLbl.Text="🟢 "..count.." player ditemukan"; plInfoLbl.TextColor3=C.GREEN
    end
end

scanBtn.MouseButton1Click:Connect(function()
    plInfoLbl.Text="⏳ Scanning..."; plInfoLbl.TextColor3=C.GOLD
    task.wait(0.2); refreshPlayers()
end)
Players.PlayerAdded:Connect(function() if tabPages["Players"].Visible then refreshPlayers() end end)
Players.PlayerRemoving:Connect(function() if tabPages["Players"].Visible then refreshPlayers() end end)

-- ══════════════════════════════════════════════
--  TAB: SPEED
-- ══════════════════════════════════════════════
local SPTab=newTab("Speed",3)

local DEFAULT_SPEED=16

local function applySpeed(v) local h=GetHum(); if h then h.WalkSpeed=v end end
LocalPlayer.CharacterAdded:Connect(function(ch)
    task.wait(0.5)
    local h=ch:WaitForChild("Humanoid",5); if h then h.WalkSpeed=DEFAULT_SPEED end
end)

-- Speed header
local spHRow=makeRow(SPTab,1,38); spHRow.BackgroundColor3=Color3.fromRGB(26,26,26)
local spHLbl=Instance.new("TextLabel",spHRow); spHLbl.Text="⚡  Speed & Jump & Fly"
spHLbl.Size=UDim2.new(1,-10,1,0); spHLbl.Position=UDim2.new(0,8,0,0)
spHLbl.BackgroundTransparency=1; spHLbl.TextColor3=C.TW; spHLbl.Font=Enum.Font.GothamBold; spHLbl.TextSize=11; spHLbl.TextXAlignment=Enum.TextXAlignment.Left

-- Speed slider row
local spRow=makeRow(SPTab,2,52)
local spLbl=Instance.new("TextLabel",spRow); spLbl.Text="🏃 WalkSpeed"
spLbl.Size=UDim2.new(0,95,0,18); spLbl.Position=UDim2.new(0,8,0,4)
spLbl.BackgroundTransparency=1; spLbl.TextColor3=C.TW; spLbl.Font=Enum.Font.GothamSemibold; spLbl.TextSize=11; spLbl.TextXAlignment=Enum.TextXAlignment.Left
local spValLbl=Instance.new("TextLabel",spRow); spValLbl.Text="16"
spValLbl.Size=UDim2.new(0,36,0,18); spValLbl.Position=UDim2.new(0,103,0,4)
spValLbl.BackgroundTransparency=1; spValLbl.TextColor3=C.GOLD; spValLbl.Font=Enum.Font.GothamBold; spValLbl.TextSize=12; spValLbl.TextXAlignment=Enum.TextXAlignment.Left
local spInp=makeInput(spRow,"16",UDim2.new(0,147,0,4),40,20); spInp.Text="16"
local spSetBtn=makeBtn(spRow,"Set",C.BLUE,UDim2.new(0,191,0,5),30,18)
local spResetBtn=makeBtn(spRow,"R",Color3.fromRGB(55,55,55),UDim2.new(0,225,0,5),20,18)

local spTrack=Instance.new("Frame",spRow); spTrack.Size=UDim2.new(1,-16,0,6); spTrack.Position=UDim2.new(0,8,0,34)
spTrack.BackgroundColor3=Color3.fromRGB(45,45,45); spTrack.BorderSizePixel=0
Instance.new("UICorner",spTrack).CornerRadius=UDim.new(1,0)
local spFill=Instance.new("Frame",spTrack); spFill.Size=UDim2.new(16/200,0,1,0)
spFill.BackgroundColor3=C.BLUE; spFill.BorderSizePixel=0
Instance.new("UICorner",spFill).CornerRadius=UDim.new(1,0)
local spThumb=Instance.new("TextButton",spTrack); spThumb.Size=UDim2.new(0,14,0,14); spThumb.AnchorPoint=Vector2.new(0.5,0.5)
spThumb.Position=UDim2.new(16/200,0,0.5,0); spThumb.BackgroundColor3=C.TW; spThumb.Text=""; spThumb.BorderSizePixel=0; spThumb.ZIndex=10
Instance.new("UICorner",spThumb).CornerRadius=UDim.new(1,0)

local spDrag=false
spThumb.MouseButton1Down:Connect(function() spDrag=true end)
spThumb.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then spDrag=true end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then spDrag=false end end)
UIS.InputChanged:Connect(function(i)
    if not spDrag then return end
    if i.UserInputType~=Enum.UserInputType.MouseMovement and i.UserInputType~=Enum.UserInputType.Touch then return end
    local rel=math.clamp((i.Position.X-spTrack.AbsolutePosition.X)/spTrack.AbsoluteSize.X,0,1)
    local val=math.max(1,math.floor(rel*200))
    spFill.Size=UDim2.new(rel,0,1,0); spThumb.Position=UDim2.new(rel,0,0.5,0)
    spValLbl.Text=tostring(val); spInp.Text=tostring(val); DEFAULT_SPEED=val; applySpeed(val)
end)
spSetBtn.MouseButton1Click:Connect(function()
    local val=math.clamp(tonumber(spInp.Text) or 16,1,1000)
    DEFAULT_SPEED=val; spValLbl.Text=tostring(val)
    local rel=math.clamp(val/200,0,1); spFill.Size=UDim2.new(rel,0,1,0); spThumb.Position=UDim2.new(rel,0,0.5,0)
    applySpeed(val)
end)
spResetBtn.MouseButton1Click:Connect(function()
    DEFAULT_SPEED=16; spInp.Text="16"; spValLbl.Text="16"
    spFill.Size=UDim2.new(16/200,0,1,0); spThumb.Position=UDim2.new(16/200,0,0.5,0); applySpeed(16)
end)

-- Preset buttons
local preRow=makeRow(SPTab,3,34); preRow.BackgroundColor3=Color3.fromRGB(22,22,22)
local preLbl=Instance.new("TextLabel",preRow); preLbl.Text="Preset:"
preLbl.Size=UDim2.new(0,44,1,0); preLbl.Position=UDim2.new(0,8,0,0)
preLbl.BackgroundTransparency=1; preLbl.TextColor3=C.TG; preLbl.Font=Enum.Font.Gotham; preLbl.TextSize=10; preLbl.TextXAlignment=Enum.TextXAlignment.Left
local function applyPreset(v)
    DEFAULT_SPEED=v; spInp.Text=tostring(v); spValLbl.Text=tostring(v)
    local rel=math.clamp(v/200,0,1); spFill.Size=UDim2.new(rel,0,1,0); spThumb.Position=UDim2.new(rel,0,0.5,0); applySpeed(v)
end
makeBtn(preRow,"Normal",Color3.fromRGB(55,55,55),UDim2.new(0,54,0.5,-10),52,20).MouseButton1Click:Connect(function() applyPreset(16) end)
makeBtn(preRow,"Fast",C.BLUED,UDim2.new(0,110,0.5,-10),44,20).MouseButton1Click:Connect(function() applyPreset(50) end)
makeBtn(preRow,"Super",Color3.fromRGB(110,40,190),UDim2.new(0,158,0.5,-10),44,20).MouseButton1Click:Connect(function() applyPreset(100) end)
makeBtn(preRow,"MAX",C.ACCENT2,UDim2.new(0,206,0.5,-10),38,20).MouseButton1Click:Connect(function() applyPreset(500) end)

-- Infinite Jump
local ijRow=makeRow(SPTab,4,40); ijRow.BackgroundColor3=Color3.fromRGB(22,22,22)
local ijLbl=Instance.new("TextLabel",ijRow); ijLbl.Text="🦘  Infinite Jump"
ijLbl.Size=UDim2.new(0.55,0,1,0); ijLbl.Position=UDim2.new(0,8,0,0)
ijLbl.BackgroundTransparency=1; ijLbl.TextColor3=C.TW; ijLbl.Font=Enum.Font.GothamBold; ijLbl.TextSize=11; ijLbl.TextXAlignment=Enum.TextXAlignment.Left
local ijStat=Instance.new("TextLabel",ijRow); ijStat.Text="OFF"
ijStat.Size=UDim2.new(0,36,1,0); ijStat.Position=UDim2.new(0.55,0,0,0)
ijStat.BackgroundTransparency=1; ijStat.TextColor3=C.TD; ijStat.Font=Enum.Font.GothamBold; ijStat.TextSize=11; ijStat.TextXAlignment=Enum.TextXAlignment.Left
local ijBtn=makeBtn(ijRow,"▶ ON",C.GREEND,UDim2.new(1,-82,0.5,-12),74,24)

local ijOn=false; local ijConn=nil
local function ijStart()
    ijOn=true; ijBtn.Text="■ OFF"; ijBtn.BackgroundColor3=C.ACCENT2
    ijStat.Text="ON ✔"; ijStat.TextColor3=C.GREEN
    ijConn=UIS.InputBegan:Connect(function(inp,proc)
        if proc or not ijOn then return end
        if inp.KeyCode~=Enum.KeyCode.Space then return end
        local h=GetHum(); if not h then return end
        local st=h:GetState()
        if st==Enum.HumanoidStateType.Freefall or st==Enum.HumanoidStateType.Jumping then
            h:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end
local function ijStop()
    ijOn=false; if ijConn then ijConn:Disconnect(); ijConn=nil end
    ijBtn.Text="▶ ON"; ijBtn.BackgroundColor3=C.GREEND
    ijStat.Text="OFF"; ijStat.TextColor3=C.TD
end
ijBtn.MouseButton1Click:Connect(function() if ijOn then ijStop() else ijStart() end end)
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5); if ijOn then if ijConn then ijConn:Disconnect() end; ijStart() end
end)

-- FLY
local flyRow=makeRow(SPTab,5,40); flyRow.BackgroundColor3=Color3.fromRGB(22,22,22)
local flyLbl=Instance.new("TextLabel",flyRow); flyLbl.Text="✈  Fly"
flyLbl.Size=UDim2.new(0,50,1,0); flyLbl.Position=UDim2.new(0,8,0,0)
flyLbl.BackgroundTransparency=1; flyLbl.TextColor3=C.TW; flyLbl.Font=Enum.Font.GothamBold; flyLbl.TextSize=11; flyLbl.TextXAlignment=Enum.TextXAlignment.Left
local flyStat=Instance.new("TextLabel",flyRow); flyStat.Text="OFF"
flyStat.Size=UDim2.new(0,36,1,0); flyStat.Position=UDim2.new(0,56,0,0)
flyStat.BackgroundTransparency=1; flyStat.TextColor3=C.TD; flyStat.Font=Enum.Font.GothamBold; flyStat.TextSize=11; flyStat.TextXAlignment=Enum.TextXAlignment.Left
local flySpLbl=Instance.new("TextLabel",flyRow); flySpLbl.Text="Speed:"
flySpLbl.Size=UDim2.new(0,44,1,0); flySpLbl.Position=UDim2.new(0,100,0,0)
flySpLbl.BackgroundTransparency=1; flySpLbl.TextColor3=C.TG; flySpLbl.Font=Enum.Font.Gotham; flySpLbl.TextSize=10; flySpLbl.TextXAlignment=Enum.TextXAlignment.Left
local flySpInp=makeInput(flyRow,"50",UDim2.new(0,146,0.5,-11),38,22); flySpInp.Text="50"
local flyBtn=makeBtn(flyRow,"▶ Fly",C.BLUED,UDim2.new(1,-82,0.5,-12),74,24)

local flyOn=false; local flyThread=nil
local flyBV=nil; local flyBG=nil

local function flyStop()
    flyOn=false
    if flyThread then task.cancel(flyThread); flyThread=nil end
    pcall(function() if flyBV and flyBV.Parent then flyBV:Destroy() end end)
    pcall(function() if flyBG and flyBG.Parent then flyBG:Destroy() end end)
    flyBV=nil; flyBG=nil
    local h=GetHum(); if h then h.PlatformStand=false end
    flyBtn.Text="▶ Fly"; flyBtn.BackgroundColor3=C.BLUED
    flyStat.Text="OFF"; flyStat.TextColor3=C.TD
end

local function flyStart()
    local hrp=GetHRP(); local hum=GetHum()
    if not hrp or not hum then return end
    flyOn=true; hum.PlatformStand=true
    -- Coba LinearVelocity (API baru) dulu
    local usedNew=false
    pcall(function()
        local a0=Instance.new("Attachment",hrp)
        local lv=Instance.new("LinearVelocity",hrp)
        lv.Attachment0=a0; lv.MaxForce=1e5
        lv.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector
        lv.VectorVelocity=Vector3.zero
        local ag=Instance.new("AlignOrientation",hrp)
        ag.Attachment0=a0; ag.MaxTorque=1e5; ag.Responsiveness=200
        ag.RigidityEnabled=true; ag.Mode=Enum.OrientationAlignmentMode.OneAttachment
        ag.CFrame=hrp.CFrame
        flyBV=lv; flyBG=ag; usedNew=true
    end)
    -- Fallback BodyVelocity
    if not usedNew then
        pcall(function()
            flyBV=Instance.new("BodyVelocity",hrp); flyBV.Velocity=Vector3.zero; flyBV.MaxForce=Vector3.new(1e5,1e5,1e5)
            flyBG=Instance.new("BodyGyro",hrp); flyBG.MaxTorque=Vector3.new(1e5,1e5,1e5); flyBG.P=1e4; flyBG.CFrame=hrp.CFrame
        end)
    end
    flyBtn.Text="■ Stop"; flyBtn.BackgroundColor3=C.ACCENT2
    flyStat.Text="ON ✈"; flyStat.TextColor3=C.BLUE
    flyThread=task.spawn(function()
        local cam=workspace.CurrentCamera
        while flyOn do
            local hrp2=GetHRP(); if not hrp2 then flyStop(); break end
            local speed=tonumber(flySpInp.Text) or 50
            local dir=Vector3.zero; local cf=cam.CFrame
            if UIS:IsKeyDown(Enum.KeyCode.W) then dir=dir+cf.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then dir=dir-cf.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then dir=dir-cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then dir=dir+cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space)     then dir=dir+Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir=dir-Vector3.new(0,1,0) end
            local vel=dir.Magnitude>0 and dir.Unit*speed or Vector3.zero
            local tCF=CFrame.new(hrp2.Position,hrp2.Position+cf.LookVector)
            pcall(function()
                if flyBV and flyBV.Parent then
                    if flyBV:IsA("LinearVelocity") then flyBV.VectorVelocity=vel else flyBV.Velocity=vel end
                end
                if flyBG and flyBG.Parent then
                    if flyBG:IsA("AlignOrientation") then flyBG.CFrame=tCF else flyBG.CFrame=tCF end
                end
            end)
            task.wait()
        end
    end)
end

flyBtn.MouseButton1Click:Connect(function() if flyOn then flyStop() else flyStart() end end)
LocalPlayer.CharacterAdded:Connect(function() if flyOn then flyStop() end end)

-- ══════════════════════════════════════════════
--  TAB: SETTINGS
-- ══════════════════════════════════════════════
local STTab=newTab("Settings",4)

makeHeader(STTab,1,"DATA")
local svRow=makeRow(STTab,2,36)
local svLbl=Instance.new("TextLabel",svRow); svLbl.Text="Manual save data waypoint"
svLbl.Size=UDim2.new(0.65,0,1,0); svLbl.Position=UDim2.new(0,8,0,0)
svLbl.BackgroundTransparency=1; svLbl.TextColor3=C.TW; svLbl.Font=Enum.Font.Gotham; svLbl.TextSize=11; svLbl.TextXAlignment=Enum.TextXAlignment.Left
local svBtn=makeBtn(svRow,"💾 Save",C.GREEND,UDim2.new(1,-78,0.5,-11),68,22)
svBtn.MouseButton1Click:Connect(function()
    saveData(); SaveLbl.Text="💾 Tersimpan!"; SaveLbl.TextColor3=C.GREEN
    task.delay(2,function() SaveLbl.Text=canFile and "💾 file" or "💾 sesi"; SaveLbl.TextColor3=C.TG end)
end)

local clRow=makeRow(STTab,3,36)
local clLbl=Instance.new("TextLabel",clRow); clLbl.Text="Hapus SEMUA waypoint"
clLbl.Size=UDim2.new(0.65,0,1,0); clLbl.Position=UDim2.new(0,8,0,0)
clLbl.BackgroundTransparency=1; clLbl.TextColor3=C.TW; clLbl.Font=Enum.Font.Gotham; clLbl.TextSize=11; clLbl.TextXAlignment=Enum.TextXAlignment.Left
local clBtn=makeBtn(clRow,"🗑 Hapus",C.ACCENT2,UDim2.new(1,-78,0.5,-11),68,22)
clBtn.MouseButton1Click:Connect(function()
    for i in pairs(loopThreads) do stopLoop(i) end
    Folders={}; selFolder=nil; RefreshFolders(); RefreshWP(); saveData()
end)

makeHeader(STTab,4,"INFO")
local infoRow=makeRow(STTab,5,110)
local infoLbl=Instance.new("TextLabel",infoRow)
infoLbl.Text="Hotkey: G = Toggle GUI\n\nFly: WASD + Space (naik) + Shift (turun)\n\nAuto-save: "..(canFile and "file lokal (K4TSS_v3.json)" or "in-memory (sesi ini)").."\nInterval: tiap 30 detik\n\nK4TSS HUB V3.0"
infoLbl.Size=UDim2.new(1,-10,1,0); infoLbl.Position=UDim2.new(0,10,0,6)
infoLbl.BackgroundTransparency=1; infoLbl.TextColor3=C.TG; infoLbl.Font=Enum.Font.Gotham; infoLbl.TextSize=10
infoLbl.TextXAlignment=Enum.TextXAlignment.Left; infoLbl.TextYAlignment=Enum.TextYAlignment.Top

-- ══════════════════════════════════════════════
--  MINIMIZE & CLOSE
-- ══════════════════════════════════════════════
local minimized=false
BtnMin.MouseButton1Click:Connect(function()
    minimized=not minimized
    if minimized then
        BtnMin.Text="+"; Body.Visible=false
        TweenService:Create(Window,TweenInfo.new(0.18,Enum.EasingStyle.Quint),{Size=WIN_MINI}):Play()
    else
        BtnMin.Text="–"; Body.Visible=true
        TweenService:Create(Window,TweenInfo.new(0.18,Enum.EasingStyle.Quint),{Size=WIN_FULL}):Play()
    end
end)

BtnClose.MouseButton1Click:Connect(function()
    saveData()
    for i in pairs(loopThreads) do stopLoop(i) end
    if flyOn then flyStop() end
    if ijOn then ijStop() end
    TweenService:Create(Window,TweenInfo.new(0.15),{Size=UDim2.new(0,520,0,0)}):Play()
    task.wait(0.16); Window.Visible=false
end)

-- ══════════════════════════════════════════════
--  HOTKEY G = TOGGLE
-- ══════════════════════════════════════════════
local guiOpen=true
UIS.InputBegan:Connect(function(inp,proc)
    if proc then return end
    if inp.UserInputType~=Enum.UserInputType.Keyboard then return end
    if inp.KeyCode==Enum.KeyCode.G then
        guiOpen=not guiOpen
        if guiOpen then
            Window.Visible=true; Body.Visible=not minimized
            TweenService:Create(Window,TweenInfo.new(0.18,Enum.EasingStyle.Quint),{Size=WIN_FULL}):Play()
        else
            TweenService:Create(Window,TweenInfo.new(0.18,Enum.EasingStyle.Quint),{Size=UDim2.new(0,520,0,0)}):Play()
            task.wait(0.2); Window.Visible=false
        end
    end
end)

-- ══════════════════════════════════════════════
--  INIT
-- ══════════════════════════════════════════════
switchTab("Waypoints")
RefreshFolders()
RefreshWP()

-- Notifikasi sukses
task.spawn(function()
    task.wait(0.5)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification",{
            Title="K4TSS V3.0", Text="Hub loaded! G = toggle GUI", Duration=4
        })
    end)
end)

print("[K4TSS V3.0] Loaded! G = Toggle GUI")
