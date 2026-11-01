--[[
    ╔══════════════════════════════════════════════╗
    ║         K4TSS V2.1 - WAYPOINT HUB           ║
    ║  Fitur: Folder, Loop TP, Player TP,          ║
    ║         Auto-Save + Backup, Export/Import    ║
    ║  Hotkey: G = Toggle GUI (HP: tombol K4)      ║
    ╚══════════════════════════════════════════════╝
]]

-- ════════════════════════════════════════
--    SERVICES
-- ════════════════════════════════════════
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local StarterGui        = game:GetService("StarterGui")
local HttpService       = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()

-- ════════════════════════════════════════
--    SAVE SYSTEM (file + backup otomatis)
-- ════════════════════════════════════════
local SAVE_FILE   = "K4TSS_Waypoints.json"
local BACKUP_FILE = "K4TSS_Waypoints_backup.json"
local canSaveFile = (typeof(writefile) == "function" and typeof(readfile) == "function")

local Folders    = {}
local loadFailed = false  -- true kalau file ada tapi rusak (mencegah menimpa data lama)

local function EncodeJSON(data)
    local ok, result = pcall(function() return HttpService:JSONEncode(data) end)
    return ok and result or nil
end

local function DecodeJSON(str)
    local ok, result = pcall(function() return HttpService:JSONDecode(str) end)
    return ok and result or nil
end

local function FileExists(path)
    if typeof(isfile) == "function" then
        local ok, r = pcall(isfile, path)
        return ok and r == true
    end
    local ok = pcall(readfile, path)
    return ok
end

-- Bersihkan & validasi data (dari file / import)
local function Sanitize(data)
    local out = {}
    if type(data) ~= "table" then return out end
    for _, f in ipairs(data) do
        if type(f) == "table" then
            local folder = {
                name       = tostring(f.name or "Folder"),
                waypoints  = {},
                loopActive = false,
                loopDelay  = tonumber(f.loopDelay) or 3,
            }
            if type(f.waypoints) == "table" then
                for _, wp in ipairs(f.waypoints) do
                    if type(wp) == "table" and tonumber(wp.x) and tonumber(wp.y) and tonumber(wp.z) then
                        table.insert(folder.waypoints, {
                            name = tostring(wp.name or "WP"),
                            x = tonumber(wp.x), y = tonumber(wp.y), z = tonumber(wp.z),
                        })
                    end
                end
            end
            table.insert(out, folder)
        end
    end
    return out
end

local function SaveData(force)
    if not canSaveFile then return false end
    if loadFailed and not force then return false end
    local encoded = EncodeJSON(Folders)
    if not encoded then return false end

    -- Simpan cadangan dari file sebelumnya (hanya kalau valid & tidak kosong)
    if FileExists(SAVE_FILE) then
        local ok, old = pcall(readfile, SAVE_FILE)
        if ok and old and old ~= "" and old ~= "[]" and old ~= encoded and DecodeJSON(old) then
            pcall(writefile, BACKUP_FILE, old)
        end
    end

    local ok = pcall(writefile, SAVE_FILE, encoded)
    return ok
end

local function LoadData()
    if not canSaveFile or not FileExists(SAVE_FILE) then return end
    local ok, content = pcall(readfile, SAVE_FILE)
    if not ok or not content or content == "" then return end

    local decoded = DecodeJSON(content)
    if decoded then
        Folders = Sanitize(decoded)
        return
    end

    -- File utama rusak -> coba backup
    loadFailed = true
    if FileExists(BACKUP_FILE) then
        local okb, bc = pcall(readfile, BACKUP_FILE)
        local d = okb and bc and DecodeJSON(bc)
        if d then
            Folders = Sanitize(d)
            loadFailed = false
        end
    end
end

LoadData()

task.spawn(function()
    while task.wait(30) do SaveData() end
end)

-- ════════════════════════════════════════
--    TELEPORT HELPER
-- ════════════════════════════════════════
local function GetHRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function TeleportTo(x, y, z)
    local hrp = GetHRP()
    if hrp then
        hrp.CFrame = CFrame.new(x, y, z)
    end
end

local function GetCurrentPos()
    local hrp = GetHRP()
    if hrp then
        local p = hrp.Position
        return p.X, p.Y, p.Z
    end
    return 0, 0, 0
end

local function R2(n) return math.floor(n * 100 + 0.5) / 100 end

-- ════════════════════════════════════════
--    LOOP MANAGER
-- ════════════════════════════════════════
local loopThreads = {}

local function StopLoop(folderIdx)
    if loopThreads[folderIdx] then
        task.cancel(loopThreads[folderIdx])
        loopThreads[folderIdx] = nil
    end
    if Folders[folderIdx] then Folders[folderIdx].loopActive = false end
end

local function StopAllLoops()
    for k in pairs(loopThreads) do StopLoop(k) end
    for _, f in ipairs(Folders) do f.loopActive = false end
end

local function StartLoop(folderIdx, onStep)
    StopLoop(folderIdx)
    local folder = Folders[folderIdx]
    if not folder or #folder.waypoints < 2 then return end
    folder.loopActive = true
    loopThreads[folderIdx] = task.spawn(function()
        local i = 1
        while folder.loopActive do
            local wp = folder.waypoints[i]
            if wp then
                TeleportTo(wp.x, wp.y, wp.z)
                if onStep then onStep(i) end
            end
            task.wait(folder.loopDelay or 3)
            i = i + 1
            if i > #folder.waypoints then i = 1 end
        end
    end)
end

-- Forward declare (dipakai dialog tutup)
local flyActive = false
local StopFly

-- ════════════════════════════════════════
--    GUI BUILD
-- ════════════════════════════════════════
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
if PlayerGui:FindFirstChild("K4TSSHub") then
    PlayerGui.K4TSSHub:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "K4TSSHub"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder   = 999
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

-- ─── COLORS ───
local BG       = Color3.fromRGB(30, 30, 30)
local SIDEBAR  = Color3.fromRGB(38, 38, 38)
local CONTENT  = Color3.fromRGB(26, 26, 26)
local TITLEBAR = Color3.fromRGB(42, 42, 42)
local ROW      = Color3.fromRGB(34, 34, 34)
local ROWALT   = Color3.fromRGB(30, 30, 30)
local ACCENT   = Color3.fromRGB(220, 50, 50)
local ACCENT2  = Color3.fromRGB(160, 20, 20)
local STATUSBG = Color3.fromRGB(33, 33, 33)
local DIVIDER  = Color3.fromRGB(50, 50, 50)
local TEXTW    = Color3.fromRGB(230, 230, 230)
local TEXTG    = Color3.fromRGB(140, 140, 140)
local TEXTD    = Color3.fromRGB(80, 80, 80)
local GREEN    = Color3.fromRGB(80, 220, 100)
local GREENDK  = Color3.fromRGB(40, 160, 60)
local GOLD     = Color3.fromRGB(255, 185, 50)
local BLUE     = Color3.fromRGB(50, 140, 255)
local BLUEDK   = Color3.fromRGB(30, 90, 200)

local SIZE_NORMAL = UDim2.new(0, 540, 0, 360)
local SIZE_MINI   = UDim2.new(0, 160, 0, 28)

-- ─── WINDOW ───
local Window = Instance.new("Frame")
Window.Name             = "Window"
Window.Size             = SIZE_NORMAL
Window.Position         = UDim2.new(0.5, -270, 0.5, -180)
Window.BackgroundColor3 = BG
Window.BorderSizePixel  = 0
Window.ClipsDescendants = true
Window.Parent           = ScreenGui
Instance.new("UICorner", Window).CornerRadius = UDim.new(0, 6)
local ws = Instance.new("UIStroke", Window)
ws.Color = Color3.fromRGB(60,60,60); ws.Thickness = 1

-- ─── TOMBOL BUKA (untuk HP / setelah ditutup) ───
local guiOpen = true
local OpenBtn = Instance.new("TextButton", ScreenGui)
OpenBtn.Name = "OpenBtn"; OpenBtn.Text = "K4"
OpenBtn.Size = UDim2.new(0,40,0,40); OpenBtn.Position = UDim2.new(0,10,0.35,0)
OpenBtn.BackgroundColor3 = ACCENT; OpenBtn.TextColor3 = TEXTW
OpenBtn.Font = Enum.Font.GothamBold; OpenBtn.TextSize = 14
OpenBtn.BorderSizePixel = 0; OpenBtn.Visible = false; OpenBtn.ZIndex = 50
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(1,0)

local function SetOpen(v)
    guiOpen = v
    Window.Visible = v
    OpenBtn.Visible = not v
end
OpenBtn.MouseButton1Click:Connect(function() SetOpen(true) end)

-- ─── TITLEBAR ───
local TBar = Instance.new("Frame", Window)
TBar.Name = "TitleBar"; TBar.Size = UDim2.new(1,0,0,36)
TBar.BackgroundColor3 = TITLEBAR; TBar.BorderSizePixel = 0; TBar.ZIndex = 10
Instance.new("UICorner", TBar).CornerRadius = UDim.new(0,4)
local tfix = Instance.new("Frame", TBar)
tfix.Size = UDim2.new(1,0,0,6); tfix.Position = UDim2.new(0,0,1,-6)
tfix.BackgroundColor3 = TITLEBAR; tfix.BorderSizePixel = 0; tfix.ZIndex = 10
local tacc = Instance.new("Frame", TBar)
tacc.Size = UDim2.new(0,3,0.7,0); tacc.Position = UDim2.new(0,0,0.15,0)
tacc.BackgroundColor3 = ACCENT; tacc.BorderSizePixel = 0; tacc.ZIndex = 11
local TTitle = Instance.new("TextLabel", TBar)
TTitle.Text = "K4TSS V2.1  ·  Waypoint Hub"
TTitle.Size = UDim2.new(1,-90,1,0); TTitle.Position = UDim2.new(0,12,0,0)
TTitle.BackgroundTransparency = 1; TTitle.TextColor3 = TEXTW
TTitle.Font = Enum.Font.GothamBold; TTitle.TextSize = 12
TTitle.TextXAlignment = Enum.TextXAlignment.Left; TTitle.ZIndex = 11

local function MakeTBarBtn(text, xOff)
    local btn = Instance.new("TextButton", TBar)
    btn.Text = text; btn.Size = UDim2.new(0,30,0,26)
    btn.Position = UDim2.new(1,xOff,0.5,-13)
    btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
    btn.BackgroundTransparency = 0.5
    btn.TextColor3 = TEXTW; btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16; btn.BorderSizePixel = 0; btn.ZIndex = 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
    btn.MouseEnter:Connect(function() TweenService:Create(btn,TweenInfo.new(0.1),{BackgroundTransparency=0.2}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn,TweenInfo.new(0.1),{BackgroundTransparency=0.5}):Play() end)
    return btn
end
local CloseBtn = MakeTBarBtn("×", -34); CloseBtn.TextColor3 = Color3.fromRGB(255,100,100)
local MinBtn   = MakeTBarBtn("–", -68)

-- ─── DRAG ───
do
    local dragging = false
    local dragStart = Vector2.zero
    local winStart  = UDim2.new()
    TBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = Vector2.new(input.Position.X, input.Position.Y)
            winStart  = Window.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
            Window.Position = UDim2.new(
                winStart.X.Scale, winStart.X.Offset + delta.X,
                winStart.Y.Scale, winStart.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- ─── BODY ───
local Body = Instance.new("Frame", Window)
Body.Name = "Body"; Body.Size = UDim2.new(1,0,1,-36); Body.Position = UDim2.new(0,0,0,36)
Body.BackgroundTransparency = 1; Body.ClipsDescendants = true; Body.ZIndex = 5

-- ─── SIDEBAR ───
local Sidebar = Instance.new("Frame", Body)
Sidebar.Size = UDim2.new(0,120,1,-30)
Sidebar.BackgroundColor3 = SIDEBAR; Sidebar.BorderSizePixel = 0; Sidebar.ZIndex = 6
local SL = Instance.new("UIListLayout", Sidebar)
SL.FillDirection = Enum.FillDirection.Vertical
SL.HorizontalAlignment = Enum.HorizontalAlignment.Left
SL.SortOrder = Enum.SortOrder.LayoutOrder

-- ─── CONTENT AREA ───
local ContentArea = Instance.new("Frame", Body)
ContentArea.Size = UDim2.new(1,-120,1,-30); ContentArea.Position = UDim2.new(0,120,0,0)
ContentArea.BackgroundColor3 = CONTENT; ContentArea.BorderSizePixel = 0
ContentArea.ClipsDescendants = true; ContentArea.ZIndex = 6
local cborder = Instance.new("Frame", ContentArea)
cborder.Size = UDim2.new(0,1,1,0); cborder.BackgroundColor3 = DIVIDER; cborder.BorderSizePixel = 0

-- ─── STATUS BAR ───
local StatusBar = Instance.new("Frame", Body)
StatusBar.Size = UDim2.new(1,0,0,30); StatusBar.Position = UDim2.new(0,0,1,-30)
StatusBar.BackgroundColor3 = STATUSBG; StatusBar.BorderSizePixel = 0; StatusBar.ZIndex = 6
local sline = Instance.new("Frame", StatusBar)
sline.Size = UDim2.new(1,0,0,1); sline.BackgroundColor3 = DIVIDER; sline.BorderSizePixel = 0

local AvatarFrame = Instance.new("Frame", StatusBar)
AvatarFrame.Size = UDim2.new(0,22,0,22); AvatarFrame.Position = UDim2.new(0,6,0.5,-11)
AvatarFrame.BackgroundColor3 = Color3.fromRGB(50,50,50); AvatarFrame.BorderSizePixel = 0
Instance.new("UICorner", AvatarFrame).CornerRadius = UDim.new(1,0)
local AvatarImg = Instance.new("ImageLabel", AvatarFrame)
AvatarImg.Size = UDim2.new(1,0,1,0); AvatarImg.BackgroundTransparency = 1; AvatarImg.BorderSizePixel = 0
Instance.new("UICorner", AvatarImg).CornerRadius = UDim.new(1,0)
task.spawn(function()
    local ok, img = pcall(function()
        return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    end)
    if ok and img then AvatarImg.Image = img else AvatarFrame.BackgroundColor3 = ACCENT end
end)

local WelcomeL = Instance.new("TextLabel", StatusBar)
WelcomeL.Text = "Welcome, " .. LocalPlayer.Name
WelcomeL.Size = UDim2.new(0.35,0,1,0); WelcomeL.Position = UDim2.new(0,34,0,0)
WelcomeL.BackgroundTransparency = 1; WelcomeL.TextColor3 = TEXTG
WelcomeL.Font = Enum.Font.Gotham; WelcomeL.TextSize = 10
WelcomeL.TextXAlignment = Enum.TextXAlignment.Left

local baseStatusText = canSaveFile and "💾 Auto-save (file)" or "💾 Auto-save (sesi)"
local SaveStatusL = Instance.new("TextLabel", StatusBar)
SaveStatusL.Text = baseStatusText
SaveStatusL.Size = UDim2.new(0.65,-8,1,0); SaveStatusL.Position = UDim2.new(0.35,0,0,0)
SaveStatusL.BackgroundTransparency = 1; SaveStatusL.TextColor3 = TEXTG
SaveStatusL.Font = Enum.Font.Gotham; SaveStatusL.TextSize = 10
SaveStatusL.TextXAlignment = Enum.TextXAlignment.Right

local toastToken = 0
local function Toast(msg, color)
    toastToken = toastToken + 1
    local mine = toastToken
    SaveStatusL.Text = msg
    SaveStatusL.TextColor3 = color or GREEN
    task.delay(3, function()
        if mine == toastToken then
            SaveStatusL.Text = baseStatusText
            SaveStatusL.TextColor3 = TEXTG
        end
    end)
end

-- ─── CLOSE DIALOG ───
local Dialog = Instance.new("Frame", ScreenGui)
Dialog.Name = "CloseDialog"; Dialog.Size = UDim2.new(0,240,0,110)
Dialog.Position = UDim2.new(0.5,-120,0.5,-55)
Dialog.BackgroundColor3 = Color3.fromRGB(38,38,38); Dialog.BorderSizePixel = 0
Dialog.ZIndex = 100; Dialog.Visible = false
Instance.new("UICorner", Dialog).CornerRadius = UDim.new(0,6)
local dStroke = Instance.new("UIStroke", Dialog); dStroke.Color = ACCENT; dStroke.Thickness = 1.5
local DTitle = Instance.new("TextLabel", Dialog)
DTitle.Text = "Simpan & Tutup K4TSS?"
DTitle.Size = UDim2.new(1,0,0,30); DTitle.Position = UDim2.new(0,0,0,12)
DTitle.BackgroundTransparency = 1; DTitle.TextColor3 = TEXTW
DTitle.Font = Enum.Font.GothamBold; DTitle.TextSize = 13; DTitle.ZIndex = 101
local DSub = Instance.new("TextLabel", Dialog)
DSub.Text = "Semua waypoint akan disimpan"
DSub.Size = UDim2.new(1,0,0,16); DSub.Position = UDim2.new(0,0,0,38)
DSub.BackgroundTransparency = 1; DSub.TextColor3 = TEXTG
DSub.Font = Enum.Font.Gotham; DSub.TextSize = 10; DSub.ZIndex = 101
local DYes = Instance.new("TextButton", Dialog)
DYes.Text = "Simpan & Tutup"; DYes.Size = UDim2.new(0,114,0,28); DYes.Position = UDim2.new(0,8,0,68)
DYes.BackgroundColor3 = ACCENT; DYes.TextColor3 = TEXTW
DYes.Font = Enum.Font.GothamBold; DYes.TextSize = 11; DYes.BorderSizePixel = 0; DYes.ZIndex = 101
Instance.new("UICorner", DYes).CornerRadius = UDim.new(0,4)
local DNo = Instance.new("TextButton", Dialog)
DNo.Text = "Batal"; DNo.Size = UDim2.new(0,90,0,28); DNo.Position = UDim2.new(1,-98,0,68)
DNo.BackgroundColor3 = Color3.fromRGB(60,60,60); DNo.TextColor3 = TEXTW
DNo.Font = Enum.Font.GothamBold; DNo.TextSize = 11; DNo.BorderSizePixel = 0; DNo.ZIndex = 101
Instance.new("UICorner", DNo).CornerRadius = UDim.new(0,4)
CloseBtn.MouseButton1Click:Connect(function() Dialog.Visible = true end)
DNo.MouseButton1Click:Connect(function() Dialog.Visible = false end)
DYes.MouseButton1Click:Connect(function()
    SaveData()
    StopAllLoops()
    if flyActive and StopFly then StopFly() end
    Dialog.Visible = false
    SetOpen(false)
end)

-- ─── MINIMIZE ───
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        MinBtn.Text = "+"
        TweenService:Create(Window, TweenInfo.new(0.2,Enum.EasingStyle.Quint), {Size=SIZE_MINI}):Play()
        task.wait(0.2); Body.Visible = false
    else
        MinBtn.Text = "–"; Body.Visible = true
        TweenService:Create(Window, TweenInfo.new(0.2,Enum.EasingStyle.Quint), {Size=SIZE_NORMAL}):Play()
    end
end)

-- ─── RESIZE HANDLE ───
local MIN_W, MIN_H = 400, 280
local MAX_W, MAX_H = 900, 700

local ResizeHandle = Instance.new("TextButton", Window)
ResizeHandle.Size              = UDim2.new(0, 18, 0, 18)
ResizeHandle.Position          = UDim2.new(1, -18, 1, -18)
ResizeHandle.BackgroundColor3  = Color3.fromRGB(70, 70, 70)
ResizeHandle.BackgroundTransparency = 0.4
ResizeHandle.BorderSizePixel   = 0
ResizeHandle.Text              = ""
ResizeHandle.ZIndex            = 20
ResizeHandle.AutoButtonColor   = false
Instance.new("UICorner", ResizeHandle).CornerRadius = UDim.new(0, 3)

local ResizeIcon = Instance.new("TextLabel", ResizeHandle)
ResizeIcon.Size = UDim2.new(1,0,1,0)
ResizeIcon.BackgroundTransparency = 1
ResizeIcon.Text = "⠿"
ResizeIcon.TextColor3 = Color3.fromRGB(160,160,160)
ResizeIcon.Font = Enum.Font.Gotham
ResizeIcon.TextSize = 11
ResizeIcon.ZIndex = 21

ResizeHandle.MouseEnter:Connect(function()
    ResizeHandle.BackgroundTransparency = 0.1
    ResizeIcon.TextColor3 = TEXTW
end)
ResizeHandle.MouseLeave:Connect(function()
    ResizeHandle.BackgroundTransparency = 0.4
    ResizeIcon.TextColor3 = Color3.fromRGB(160,160,160)
end)

do
    local resizing    = false
    local resizeStart = Vector2.zero
    local startSize   = Vector2.zero

    ResizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            resizing    = true
            resizeStart = Vector2.new(input.Position.X, input.Position.Y)
            startSize   = Vector2.new(Window.AbsoluteSize.X, Window.AbsoluteSize.Y)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not resizing then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end

        local delta = Vector2.new(input.Position.X, input.Position.Y) - resizeStart
        local newW  = math.clamp(startSize.X + delta.X, MIN_W, MAX_W)
        local newH  = math.clamp(startSize.Y + delta.Y, MIN_H, MAX_H)

        Window.Size = UDim2.new(0, newW, 0, newH)
        SIZE_NORMAL = UDim2.new(0, newW, 0, newH)
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            resizing = false
        end
    end)
end

-- ════════════════════════════════════════
--    TAB SYSTEM
-- ════════════════════════════════════════
local tabPages  = {}
local tabBtns   = {}
local activeTab = nil

local function SwitchTab(name)
    if activeTab == name then return end
    activeTab = name
    for n,p in pairs(tabPages) do p.Visible = (n==name) end
    for n,b in pairs(tabBtns) do
        local isA = (n==name)
        local bar = b:FindFirstChild("ABar"); if bar then bar.Visible = isA end
        local lbl = b:FindFirstChild("TLbl")
        if lbl then
            lbl.TextColor3 = isA and TEXTW or TEXTG
            lbl.Font = isA and Enum.Font.GothamSemibold or Enum.Font.Gotham
        end
        b.BackgroundColor3 = isA and Color3.fromRGB(44,44,44) or SIDEBAR
    end
end

local function NewTab(name, lo)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Name = "Tab_"..name; btn.Size = UDim2.new(1,0,0,36)
    btn.BackgroundColor3 = SIDEBAR; btn.BorderSizePixel = 0; btn.Text = ""; btn.LayoutOrder = lo; btn.ZIndex = 7
    local abar = Instance.new("Frame", btn); abar.Name = "ABar"
    abar.Size = UDim2.new(0,3,0.6,0); abar.Position = UDim2.new(0,0,0.2,0)
    abar.BackgroundColor3 = ACCENT; abar.BorderSizePixel = 0; abar.Visible = false
    local lbl = Instance.new("TextLabel", btn); lbl.Name = "TLbl"; lbl.Text = name
    lbl.Size = UDim2.new(1,-12,1,0); lbl.Position = UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency = 1; lbl.TextColor3 = TEXTG
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left
    btn.MouseEnter:Connect(function() if activeTab~=name then btn.BackgroundColor3 = Color3.fromRGB(44,44,44) end end)
    btn.MouseLeave:Connect(function() if activeTab~=name then btn.BackgroundColor3 = SIDEBAR end end)
    btn.MouseButton1Click:Connect(function() SwitchTab(name) end)

    local page = Instance.new("ScrollingFrame", ContentArea)
    page.Name = "Page_"..name; page.Size = UDim2.new(1,-2,1,0); page.Position = UDim2.new(0,2,0,0)
    page.BackgroundTransparency = 1; page.BorderSizePixel = 0
    page.ScrollBarThickness = 3; page.ScrollBarImageColor3 = ACCENT
    page.CanvasSize = UDim2.new(0,0,0,0); page.AutomaticCanvasSize = Enum.AutomaticSize.Y; page.Visible = false
    page.ZIndex = 7
    local pl = Instance.new("UIListLayout", page)
    pl.Padding = UDim.new(0,0); pl.FillDirection = Enum.FillDirection.Vertical; pl.SortOrder = Enum.SortOrder.LayoutOrder
    Instance.new("UIPadding", page).PaddingTop = UDim.new(0,4)
    tabPages[name] = page; tabBtns[name] = btn
    return page
end

-- ════════════════════════════════════════
--    UI HELPERS
-- ════════════════════════════════════════
local function MakeSecHeader(parent, text, lo)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1,0,0,22); f.BackgroundTransparency = 1; f.BorderSizePixel = 0; f.LayoutOrder = lo
    local l = Instance.new("TextLabel", f)
    l.Text = text; l.Size = UDim2.new(1,-10,1,0); l.Position = UDim2.new(0,10,0,0)
    l.BackgroundTransparency = 1; l.TextColor3 = TEXTD
    l.Font = Enum.Font.Gotham; l.TextSize = 10; l.TextXAlignment = Enum.TextXAlignment.Left
    return f
end

local function MakeRow(parent, lo, h)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,0,0,h or 48); row.BackgroundColor3 = ROW
    row.BorderSizePixel = 0; row.LayoutOrder = lo; row.ZIndex = 8
    local line = Instance.new("Frame", row)
    line.Size = UDim2.new(1,0,0,1); line.Position = UDim2.new(0,0,1,-1)
    line.BackgroundColor3 = DIVIDER; line.BorderSizePixel = 0
    return row
end

local function MakeSmallBtn(parent, text, bgColor, xPos, yPos, w, h)
    local btn = Instance.new("TextButton", parent)
    btn.Text = text; btn.Size = UDim2.new(0,w or 44,0,h or 30)
    btn.Position = xPos or UDim2.new(0,0,0,0)
    btn.AnchorPoint = yPos or Vector2.new(0,0)
    btn.BackgroundColor3 = bgColor; btn.TextColor3 = TEXTW
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 11; btn.BorderSizePixel = 0; btn.ZIndex = 9
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
    local darker = Color3.fromRGB(
        math.max(0, bgColor.R*255-30),
        math.max(0, bgColor.G*255-30),
        math.max(0, bgColor.B*255-30)
    )
    btn.MouseEnter:Connect(function() TweenService:Create(btn,TweenInfo.new(0.08),{BackgroundColor3=darker}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn,TweenInfo.new(0.08),{BackgroundColor3=bgColor}):Play() end)
    return btn
end

local function MakeInlineInput(parent, placeholder, xPos, size)
    local inp = Instance.new("TextBox", parent)
    inp.PlaceholderText = placeholder or "..."
    inp.Text = ""
    inp.Size = size or UDim2.new(0,120,0,30)
    inp.Position = xPos or UDim2.new(0,0,0,0)
    inp.BackgroundColor3 = Color3.fromRGB(22,22,22)
    inp.TextColor3 = TEXTW; inp.PlaceholderColor3 = TEXTD
    inp.Font = Enum.Font.Gotham; inp.TextSize = 12
    inp.BorderSizePixel = 0; inp.ClearTextOnFocus = false; inp.ZIndex = 9
    Instance.new("UICorner", inp).CornerRadius = UDim.new(0,4)
    local st = Instance.new("UIStroke", inp); st.Color = DIVIDER; st.Thickness = 1
    return inp
end

-- Konfirmasi 2x tap: tombol berubah "Yakin?" lalu eksekusi di tap kedua
local function ConfirmBtn(btn, normalText, action)
    local armed = false
    btn.MouseButton1Click:Connect(function()
        if armed then
            armed = false
            btn.Text = normalText
            action()
        else
            armed = true
            btn.Text = "Yakin?"
            task.delay(2.5, function()
                if armed then armed = false; btn.Text = normalText end
            end)
        end
    end)
end

-- ════════════════════════════════════════
--    EXPORT / IMPORT / COPY
-- ════════════════════════════════════════
-- Kotak salin manual (cadangan kalau executor tidak punya setclipboard)
local ExportBox = Instance.new("Frame", ScreenGui)
ExportBox.Name = "ExportBox"; ExportBox.Size = UDim2.new(0,420,0,260)
ExportBox.Position = UDim2.new(0.5,-210,0.5,-130)
ExportBox.BackgroundColor3 = Color3.fromRGB(34,34,34); ExportBox.BorderSizePixel = 0
ExportBox.ZIndex = 150; ExportBox.Visible = false
Instance.new("UICorner", ExportBox).CornerRadius = UDim.new(0,6)
local ebStroke = Instance.new("UIStroke", ExportBox); ebStroke.Color = BLUE; ebStroke.Thickness = 1.5

local ebTitle = Instance.new("TextLabel", ExportBox)
ebTitle.Text = "Salin manual: tekan lama teks → Select All → Copy"
ebTitle.Size = UDim2.new(1,-50,0,28); ebTitle.Position = UDim2.new(0,10,0,2)
ebTitle.BackgroundTransparency = 1; ebTitle.TextColor3 = TEXTW
ebTitle.Font = Enum.Font.GothamBold; ebTitle.TextSize = 11; ebTitle.ZIndex = 151
ebTitle.TextXAlignment = Enum.TextXAlignment.Left

local ebClose = MakeSmallBtn(ExportBox, "✕", ACCENT2, UDim2.new(1,-36,0,4), nil, 28, 22)
ebClose.ZIndex = 152
ebClose.MouseButton1Click:Connect(function() ExportBox.Visible = false end)

local ebScroll = Instance.new("ScrollingFrame", ExportBox)
ebScroll.Size = UDim2.new(1,-20,1,-44); ebScroll.Position = UDim2.new(0,10,0,34)
ebScroll.BackgroundColor3 = Color3.fromRGB(22,22,22); ebScroll.BorderSizePixel = 0
ebScroll.ScrollBarThickness = 4; ebScroll.CanvasSize = UDim2.new(0,0,0,0)
ebScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; ebScroll.ZIndex = 151
Instance.new("UICorner", ebScroll).CornerRadius = UDim.new(0,4)

local ebText = Instance.new("TextBox", ebScroll)
ebText.Size = UDim2.new(1,-8,0,0); ebText.AutomaticSize = Enum.AutomaticSize.Y
ebText.Position = UDim2.new(0,4,0,4)
ebText.BackgroundTransparency = 1; ebText.TextColor3 = TEXTW
ebText.Font = Enum.Font.Code; ebText.TextSize = 12
ebText.TextXAlignment = Enum.TextXAlignment.Left; ebText.TextYAlignment = Enum.TextYAlignment.Top
ebText.MultiLine = true; ebText.TextWrapped = true; ebText.ClearTextOnFocus = false
ebText.Text = ""; ebText.ZIndex = 152

local function ShowExportBox(text)
    ebText.Text = text
    ExportBox.Visible = true
end

local function CopyText(text, okMsg)
    if not text or text == "" then
        Toast("⚠ Belum ada waypoint", GOLD)
        return false
    end
    local fn
    if typeof(setclipboard) == "function" then fn = setclipboard
    elseif typeof(toclipboard) == "function" then fn = toclipboard
    elseif Clipboard and typeof(Clipboard.set) == "function" then fn = Clipboard.set end

    if fn then
        local ok = pcall(fn, text)
        if ok then
            Toast(okMsg or "📋 Tercopy!", GREEN)
            return true
        end
    end
    ShowExportBox(text)
    Toast("⚠ Tidak ada clipboard — salin dari kotak", GOLD)
    return false
end

local function FolderSet(idx)
    if idx then
        if Folders[idx] then return { Folders[idx] } end
        return {}
    end
    return Folders
end

local function BuildText(list)
    if #list == 0 then return "" end
    local lines = {}
    for _, folder in ipairs(list) do
        table.insert(lines, string.format("[%s] (%d WP)", folder.name, #folder.waypoints))
        for wi, wp in ipairs(folder.waypoints) do
            table.insert(lines, string.format("  %d. %s = %.2f, %.2f, %.2f", wi, wp.name, wp.x, wp.y, wp.z))
        end
        table.insert(lines, "")
    end
    return table.concat(lines, "\n")
end

local function BuildLua(list)
    if #list == 0 then return "" end
    local out = { "-- K4TSS Waypoints", "local Waypoints = {" }
    for _, folder in ipairs(list) do
        table.insert(out, string.format("    [%q] = {", folder.name))
        for _, wp in ipairs(folder.waypoints) do
            table.insert(out, string.format("        {name = %q, pos = Vector3.new(%.2f, %.2f, %.2f)},", wp.name, wp.x, wp.y, wp.z))
        end
        table.insert(out, "    },")
    end
    table.insert(out, "}")
    table.insert(out, "return Waypoints")
    return table.concat(out, "\n")
end

local function BuildJSON(list)
    if #list == 0 then return "" end
    local clean = {}
    for _, f in ipairs(list) do
        local c = { name = f.name, loopDelay = f.loopDelay or 3, waypoints = {} }
        for _, wp in ipairs(f.waypoints) do
            table.insert(c.waypoints, { name = wp.name, x = wp.x, y = wp.y, z = wp.z })
        end
        table.insert(clean, c)
    end
    return EncodeJSON(clean) or ""
end

-- ════════════════════════════════════════
--    WAYPOINTS TAB
-- ════════════════════════════════════════
local WPTab = NewTab("Waypoints", 1)

local selectedFolder = nil
local RefreshFolderList
local RefreshWaypointPanel

local topRow = MakeRow(WPTab, 1, 46)
topRow.BackgroundColor3 = Color3.fromRGB(28,28,28)
local topLabel = Instance.new("TextLabel", topRow)
topLabel.Text = "📁  Folders"; topLabel.Size = UDim2.new(0.55,0,1,0); topLabel.Position = UDim2.new(0,10,0,0)
topLabel.BackgroundTransparency = 1; topLabel.TextColor3 = TEXTW
topLabel.Font = Enum.Font.GothamBold; topLabel.TextSize = 11; topLabel.TextXAlignment = Enum.TextXAlignment.Left
local folderInput = MakeInlineInput(topRow, "Nama folder...", UDim2.new(0,100,0.5,-11), UDim2.new(0,118,0,22))
local addFolderBtn = MakeSmallBtn(topRow, "+ Folder", GREEN, UDim2.new(1,-70,0.5,-11), nil, 60, 22)

local FolderListContainer = Instance.new("Frame", WPTab)
FolderListContainer.Name = "FolderList"
FolderListContainer.Size = UDim2.new(1,0,0,0)
FolderListContainer.BackgroundTransparency = 1
FolderListContainer.BorderSizePixel = 0
FolderListContainer.LayoutOrder = 2
FolderListContainer.AutomaticSize = Enum.AutomaticSize.Y
FolderListContainer.ZIndex = 8
local FolderListLayout = Instance.new("UIListLayout", FolderListContainer)
FolderListLayout.Padding = UDim.new(0,0)
FolderListLayout.FillDirection = Enum.FillDirection.Vertical
FolderListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local midDivRow = Instance.new("Frame", WPTab)
midDivRow.Size = UDim2.new(1,0,0,6); midDivRow.BackgroundColor3 = Color3.fromRGB(24,24,24)
midDivRow.BorderSizePixel = 0; midDivRow.LayoutOrder = 3

local wpHeaderRow = MakeRow(WPTab, 4, 46)
wpHeaderRow.BackgroundColor3 = Color3.fromRGB(28,28,28)
local wpHeaderLabel = Instance.new("TextLabel", wpHeaderRow)
wpHeaderLabel.Text = "📍  Waypoints  —  pilih folder dulu"
wpHeaderLabel.Size = UDim2.new(0.55,0,1,0); wpHeaderLabel.Position = UDim2.new(0,10,0,0)
wpHeaderLabel.BackgroundTransparency = 1; wpHeaderLabel.TextColor3 = TEXTG
wpHeaderLabel.Font = Enum.Font.GothamBold; wpHeaderLabel.TextSize = 11; wpHeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
local wpNameInput = MakeInlineInput(wpHeaderRow, "Nama waypoint...", UDim2.new(0,100,0.5,-11), UDim2.new(0,110,0,22))
local addWPBtn = MakeSmallBtn(wpHeaderRow, "+ WP", BLUE, UDim2.new(1,-58,0.5,-11), nil, 48, 22)

-- ─── BARIS SALIN WAYPOINT ───
local copyRow = MakeRow(WPTab, 5, 36)
copyRow.BackgroundColor3 = Color3.fromRGB(24,24,24)
local copyLabel = Instance.new("TextLabel", copyRow)
copyLabel.Text = "📋  Salin posisi"
copyLabel.Size = UDim2.new(0,100,1,0); copyLabel.Position = UDim2.new(0,10,0,0)
copyLabel.BackgroundTransparency = 1; copyLabel.TextColor3 = TEXTG
copyLabel.Font = Enum.Font.GothamSemibold; copyLabel.TextSize = 10; copyLabel.TextXAlignment = Enum.TextXAlignment.Left
local copyFolderBtn = MakeSmallBtn(copyRow, "Folder ini", BLUEDK, UDim2.new(1,-166,0.5,-11), nil, 74, 22)
local copyAllBtn    = MakeSmallBtn(copyRow, "Semua",      GREENDK, UDim2.new(1,-86,0.5,-11),  nil, 76, 22)

copyFolderBtn.MouseButton1Click:Connect(function()
    if not selectedFolder or not Folders[selectedFolder] then
        Toast("⚠ Pilih folder dulu", GOLD); return
    end
    CopyText(BuildText(FolderSet(selectedFolder)), "📋 Folder tercopy!")
end)
copyAllBtn.MouseButton1Click:Connect(function()
    CopyText(BuildText(FolderSet(nil)), "📋 Semua waypoint tercopy!")
end)

local loopRow = MakeRow(WPTab, 6, 36)
loopRow.BackgroundColor3 = Color3.fromRGB(24,24,24)
local loopLabel = Instance.new("TextLabel", loopRow)
loopLabel.Text = "🔁  Loop TP"; loopLabel.Size = UDim2.new(0.3,0,1,0); loopLabel.Position = UDim2.new(0,10,0,0)
loopLabel.BackgroundTransparency = 1; loopLabel.TextColor3 = TEXTG
loopLabel.Font = Enum.Font.GothamSemibold; loopLabel.TextSize = 10; loopLabel.TextXAlignment = Enum.TextXAlignment.Left
local loopStepLabel = Instance.new("TextLabel", loopRow)
loopStepLabel.Text = "—"; loopStepLabel.Size = UDim2.new(0.25,0,1,0); loopStepLabel.Position = UDim2.new(0.3,0,0,0)
loopStepLabel.BackgroundTransparency = 1; loopStepLabel.TextColor3 = GOLD
loopStepLabel.Font = Enum.Font.GothamBold; loopStepLabel.TextSize = 10; loopStepLabel.TextXAlignment = Enum.TextXAlignment.Center
local delayLabel = Instance.new("TextLabel", loopRow)
delayLabel.Text = "Delay(s):"; delayLabel.Size = UDim2.new(0,50,1,0); delayLabel.Position = UDim2.new(0.55,0,0,0)
delayLabel.BackgroundTransparency = 1; delayLabel.TextColor3 = TEXTG
delayLabel.Font = Enum.Font.Gotham; delayLabel.TextSize = 9; delayLabel.TextXAlignment = Enum.TextXAlignment.Right
local delayInput = MakeInlineInput(loopRow, "3", UDim2.new(0.55,54,0.5,-10), UDim2.new(0,32,0,20))
delayInput.Text = "3"
local loopStartBtn = MakeSmallBtn(loopRow, "▶ Start", GREENDK, UDim2.new(1,-86,0.5,-11), nil, 38, 22)
local loopStopBtn  = MakeSmallBtn(loopRow, "■ Stop",  ACCENT2, UDim2.new(1,-44,0.5,-11), nil, 38, 22)

local WPListContainer = Instance.new("Frame", WPTab)
WPListContainer.Name = "WPList"
WPListContainer.Size = UDim2.new(1,0,0,0)
WPListContainer.BackgroundTransparency = 1
WPListContainer.BorderSizePixel = 0
WPListContainer.LayoutOrder = 7
WPListContainer.AutomaticSize = Enum.AutomaticSize.Y
WPListContainer.ZIndex = 8
local WPListLayout = Instance.new("UIListLayout", WPListContainer)
WPListLayout.Padding = UDim.new(0,0)
WPListLayout.FillDirection = Enum.FillDirection.Vertical
WPListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- ════════════════════════════════════════
--    REFRESH WAYPOINTS
-- ════════════════════════════════════════
RefreshWaypointPanel = function()
    for _, c in ipairs(WPListContainer:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
    if not selectedFolder or not Folders[selectedFolder] then
        wpHeaderLabel.Text = "📍  Waypoints  —  pilih folder dulu"
        wpHeaderLabel.TextColor3 = TEXTG
        return
    end
    local folder = Folders[selectedFolder]
    wpHeaderLabel.Text = "📍  " .. folder.name
    wpHeaderLabel.TextColor3 = TEXTW
    delayInput.Text = tostring(folder.loopDelay or 3)
    local wps = folder.waypoints
    if #wps == 0 then
        local empty = Instance.new("Frame", WPListContainer)
        empty.Size = UDim2.new(1,0,0,34); empty.BackgroundColor3 = ROWALT
        empty.BorderSizePixel = 0; empty.LayoutOrder = 1
        local el = Instance.new("TextLabel", empty)
        el.Text = "Belum ada waypoint di folder ini"
        el.Size = UDim2.new(1,0,1,0); el.BackgroundTransparency = 1
        el.TextColor3 = TEXTD; el.Font = Enum.Font.Gotham; el.TextSize = 10
        return
    end
    for i, wp in ipairs(wps) do
        local wrow = Instance.new("Frame", WPListContainer)
        wrow.Name = "WP_"..i; wrow.Size = UDim2.new(1,0,0,36)
        wrow.BackgroundColor3 = (i%2==0) and ROWALT or ROW
        wrow.BorderSizePixel = 0; wrow.LayoutOrder = i; wrow.ZIndex = 8
        local wline = Instance.new("Frame", wrow)
        wline.Size = UDim2.new(1,0,0,1); wline.Position = UDim2.new(0,0,1,-1)
        wline.BackgroundColor3 = DIVIDER; wline.BorderSizePixel = 0
        local numL = Instance.new("TextLabel", wrow)
        numL.Text = tostring(i); numL.Size = UDim2.new(0,24,1,0); numL.Position = UDim2.new(0,0,0,0)
        numL.BackgroundTransparency = 1; numL.TextColor3 = TEXTD
        numL.Font = Enum.Font.GothamBold; numL.TextSize = 10; numL.TextXAlignment = Enum.TextXAlignment.Center
        local numDiv = Instance.new("Frame", wrow)
        numDiv.Size = UDim2.new(0,1,0.6,0); numDiv.Position = UDim2.new(0,24,0.2,0)
        numDiv.BackgroundColor3 = DIVIDER; numDiv.BorderSizePixel = 0
        local wl = Instance.new("TextLabel", wrow)
        wl.Text = "📍 " .. wp.name; wl.Size = UDim2.new(1,-140,0,18); wl.Position = UDim2.new(0,30,0,4)
        wl.BackgroundTransparency = 1; wl.TextColor3 = TEXTW
        wl.Font = Enum.Font.Gotham; wl.TextSize = 11; wl.TextXAlignment = Enum.TextXAlignment.Left
        local coordL = Instance.new("TextLabel", wrow)
        coordL.Text = string.format("%.1f, %.1f, %.1f", wp.x, wp.y, wp.z)
        coordL.Size = UDim2.new(1,-140,0,14); coordL.Position = UDim2.new(0,30,1,-16)
        coordL.BackgroundTransparency = 1; coordL.TextColor3 = TEXTD
        coordL.Font = Enum.Font.Gotham; coordL.TextSize = 9; coordL.TextXAlignment = Enum.TextXAlignment.Left
        local tpB = MakeSmallBtn(wrow, "TP", BLUEDK, UDim2.new(1,-132,0.5,-11), nil, 36, 22)
        tpB.MouseButton1Click:Connect(function() TeleportTo(wp.x, wp.y, wp.z) end)
        local upB = MakeSmallBtn(wrow, "▲", Color3.fromRGB(70,70,70), UDim2.new(1,-92,0.5,-11), nil, 22, 22)
        upB.TextSize = 9
        upB.MouseButton1Click:Connect(function()
            if i > 1 then
                folder.waypoints[i], folder.waypoints[i-1] = folder.waypoints[i-1], folder.waypoints[i]
                RefreshWaypointPanel(); SaveData()
            end
        end)
        local dnB = MakeSmallBtn(wrow, "▼", Color3.fromRGB(70,70,70), UDim2.new(1,-68,0.5,-11), nil, 22, 22)
        dnB.TextSize = 9
        dnB.MouseButton1Click:Connect(function()
            if i < #folder.waypoints then
                folder.waypoints[i], folder.waypoints[i+1] = folder.waypoints[i+1], folder.waypoints[i]
                RefreshWaypointPanel(); SaveData()
            end
        end)
        local delB = MakeSmallBtn(wrow, "✕", ACCENT2, UDim2.new(1,-42,0.5,-11), nil, 36, 22)
        ConfirmBtn(delB, "✕", function()
            table.remove(folder.waypoints, i)
            RefreshFolderList(); RefreshWaypointPanel(); SaveData()
        end)
        local hBtn = Instance.new("TextButton", wrow)
        hBtn.Size = UDim2.new(1,0,1,0); hBtn.BackgroundTransparency = 1; hBtn.Text = ""; hBtn.ZIndex = 7
        hBtn.MouseEnter:Connect(function()
            TweenService:Create(wrow,TweenInfo.new(0.08),{BackgroundColor3=Color3.fromRGB(42,42,42)}):Play()
        end)
        hBtn.MouseLeave:Connect(function()
            TweenService:Create(wrow,TweenInfo.new(0.08),{BackgroundColor3=(i%2==0) and ROWALT or ROW}):Play()
        end)
    end
end

RefreshFolderList = function()
    for _, c in ipairs(FolderListContainer:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
    if #Folders == 0 then
        local empty = Instance.new("Frame", FolderListContainer)
        empty.Size = UDim2.new(1,0,0,30); empty.BackgroundColor3 = ROWALT
        empty.BorderSizePixel = 0; empty.LayoutOrder = 1
        local el = Instance.new("TextLabel", empty)
        el.Text = "Belum ada folder — buat folder dulu"
        el.Size = UDim2.new(1,0,1,0); el.BackgroundTransparency = 1
        el.TextColor3 = TEXTD; el.Font = Enum.Font.Gotham; el.TextSize = 10
        return
    end
    for i, folder in ipairs(Folders) do
        local frow = Instance.new("Frame", FolderListContainer)
        frow.Name = "Folder_"..i; frow.Size = UDim2.new(1,0,0,34)
        frow.BorderSizePixel = 0; frow.LayoutOrder = i; frow.ZIndex = 8
        local isSelected = (selectedFolder == i)
        frow.BackgroundColor3 = isSelected and Color3.fromRGB(44,44,44) or ROW
        local fline = Instance.new("Frame", frow)
        fline.Size = UDim2.new(1,0,0,1); fline.Position = UDim2.new(0,0,1,-1)
        fline.BackgroundColor3 = DIVIDER; fline.BorderSizePixel = 0
        local selBar = Instance.new("Frame", frow)
        selBar.Size = UDim2.new(0,3,0.7,0); selBar.Position = UDim2.new(0,0,0.15,0)
        selBar.BackgroundColor3 = GOLD; selBar.BorderSizePixel = 0; selBar.Visible = isSelected
        local numL = Instance.new("TextLabel", frow)
        numL.Text = tostring(i); numL.Size = UDim2.new(0,20,1,0); numL.Position = UDim2.new(0,6,0,0)
        numL.BackgroundTransparency = 1; numL.TextColor3 = TEXTD
        numL.Font = Enum.Font.GothamBold; numL.TextSize = 9; numL.TextXAlignment = Enum.TextXAlignment.Center
        local ficon = Instance.new("TextLabel", frow)
        ficon.Text = "📁 " .. folder.name; ficon.Size = UDim2.new(1,-90,1,0); ficon.Position = UDim2.new(0,28,0,0)
        ficon.BackgroundTransparency = 1
        ficon.TextColor3 = isSelected and GOLD or TEXTW
        ficon.Font = isSelected and Enum.Font.GothamSemibold or Enum.Font.Gotham
        ficon.TextSize = 11; ficon.TextXAlignment = Enum.TextXAlignment.Left
        local wcount = Instance.new("TextLabel", frow)
        wcount.Text = tostring(#folder.waypoints) .. " WP"; wcount.Size = UDim2.new(0,30,1,0); wcount.Position = UDim2.new(1,-86,0,0)
        wcount.BackgroundTransparency = 1; wcount.TextColor3 = TEXTD
        wcount.Font = Enum.Font.Gotham; wcount.TextSize = 9; wcount.TextXAlignment = Enum.TextXAlignment.Right
        local loopInd = Instance.new("TextLabel", frow)
        loopInd.Text = folder.loopActive and "🔁" or ""; loopInd.Size = UDim2.new(0,20,1,0); loopInd.Position = UDim2.new(1,-54,0,0)
        loopInd.BackgroundTransparency = 1; loopInd.TextColor3 = GREEN
        loopInd.Font = Enum.Font.Gotham; loopInd.TextSize = 11; loopInd.TextXAlignment = Enum.TextXAlignment.Center
        local delFBtn = MakeSmallBtn(frow, "✕", ACCENT2, UDim2.new(1,-30,0.5,-10), nil, 24, 20)
        delFBtn.ZIndex = 10
        ConfirmBtn(delFBtn, "✕", function()
            StopAllLoops()
            loopStepLabel.Text = "—"
            table.remove(Folders, i)
            if selectedFolder == i then selectedFolder = nil
            elseif selectedFolder and selectedFolder > i then selectedFolder = selectedFolder - 1 end
            RefreshFolderList(); RefreshWaypointPanel(); SaveData()
        end)
        local selBtn = Instance.new("TextButton", frow)
        selBtn.Size = UDim2.new(1,-30,1,0); selBtn.BackgroundTransparency = 1; selBtn.Text = ""; selBtn.ZIndex = 9
        selBtn.MouseButton1Click:Connect(function()
            selectedFolder = i; RefreshFolderList(); RefreshWaypointPanel()
        end)
        selBtn.MouseEnter:Connect(function()
            if selectedFolder ~= i then TweenService:Create(frow,TweenInfo.new(0.08),{BackgroundColor3=Color3.fromRGB(40,40,40)}):Play() end
        end)
        selBtn.MouseLeave:Connect(function()
            if selectedFolder ~= i then TweenService:Create(frow,TweenInfo.new(0.08),{BackgroundColor3=ROW}):Play() end
        end)
    end
end

-- ════════════════════════════════════════
--    WAYPOINTS BUTTON CALLBACKS
-- ════════════════════════════════════════
addFolderBtn.MouseButton1Click:Connect(function()
    local name = folderInput.Text
    if name == "" then return end
    table.insert(Folders, { name=name, waypoints={}, loopActive=false, loopDelay=3 })
    folderInput.Text = ""; RefreshFolderList(); SaveData()
end)

addWPBtn.MouseButton1Click:Connect(function()
    if not selectedFolder or not Folders[selectedFolder] then return end
    local name = wpNameInput.Text
    if name == "" then return end
    local x, y, z = GetCurrentPos()
    table.insert(Folders[selectedFolder].waypoints, { name=name, x=R2(x), y=R2(y), z=R2(z) })
    wpNameInput.Text = ""; RefreshFolderList(); RefreshWaypointPanel(); SaveData()
end)

loopStartBtn.MouseButton1Click:Connect(function()
    if not selectedFolder or not Folders[selectedFolder] then return end
    local folder = Folders[selectedFolder]
    if #folder.waypoints < 2 then return end
    local delay = tonumber(delayInput.Text) or 3
    delay = math.clamp(delay, 0.5, 60)
    folder.loopDelay = delay
    StartLoop(selectedFolder, function(stepIdx)
        local wp = folder.waypoints[stepIdx]
        if wp then loopStepLabel.Text = "→ " .. stepIdx .. "/" .. #folder.waypoints .. "  " .. wp.name end
        RefreshFolderList()
    end)
    loopStepLabel.Text = "▶ Running..."; RefreshFolderList()
end)

loopStopBtn.MouseButton1Click:Connect(function()
    if not selectedFolder then return end
    StopLoop(selectedFolder); loopStepLabel.Text = "—"; RefreshFolderList()
end)

-- ════════════════════════════════════════
--    PLAYER TELEPORT TAB
-- ════════════════════════════════════════
local PlayersTab = NewTab("Players", 2)

local plrHeaderRow = MakeRow(PlayersTab, 1, 46)
plrHeaderRow.BackgroundColor3 = Color3.fromRGB(28,28,28)

local plrHeaderLabel = Instance.new("TextLabel", plrHeaderRow)
plrHeaderLabel.Text = "👤  Player Teleport"
plrHeaderLabel.Size = UDim2.new(0.6,0,1,0); plrHeaderLabel.Position = UDim2.new(0,10,0,0)
plrHeaderLabel.BackgroundTransparency = 1; plrHeaderLabel.TextColor3 = TEXTW
plrHeaderLabel.Font = Enum.Font.GothamBold; plrHeaderLabel.TextSize = 11
plrHeaderLabel.TextXAlignment = Enum.TextXAlignment.Left

local scanBtn = MakeSmallBtn(plrHeaderRow, "🔍 Scan", BLUEDK, UDim2.new(1,-76,0.5,-11), nil, 66, 22)

local plrInfoRow = MakeRow(PlayersTab, 2, 28)
plrInfoRow.BackgroundColor3 = Color3.fromRGB(24,24,24)

local plrCountLabel = Instance.new("TextLabel", plrInfoRow)
plrCountLabel.Text = "Klik  🔍 Scan  untuk memuat daftar player"
plrCountLabel.Size = UDim2.new(1,-10,1,0); plrCountLabel.Position = UDim2.new(0,10,0,0)
plrCountLabel.BackgroundTransparency = 1; plrCountLabel.TextColor3 = TEXTG
plrCountLabel.Font = Enum.Font.Gotham; plrCountLabel.TextSize = 10
plrCountLabel.TextXAlignment = Enum.TextXAlignment.Left

local streamRow = MakeRow(PlayersTab, 3, 28)
streamRow.BackgroundColor3 = Color3.fromRGB(22,22,22)
local streamLabel = Instance.new("TextLabel", streamRow)
streamLabel.Text = "⚡ Mode: Step TP (anti-streaming) — otomatis mendekati player"
streamLabel.Size = UDim2.new(1,-10,1,0); streamLabel.Position = UDim2.new(0,10,0,0)
streamLabel.BackgroundTransparency = 1; streamLabel.TextColor3 = TEXTD
streamLabel.Font = Enum.Font.Gotham; streamLabel.TextSize = 9
streamLabel.TextXAlignment = Enum.TextXAlignment.Left

local PlrListContainer = Instance.new("Frame", PlayersTab)
PlrListContainer.Name = "PlrList"
PlrListContainer.Size = UDim2.new(1,0,0,0)
PlrListContainer.BackgroundTransparency = 1
PlrListContainer.BorderSizePixel = 0
PlrListContainer.LayoutOrder = 4
PlrListContainer.AutomaticSize = Enum.AutomaticSize.Y
PlrListContainer.ZIndex = 8

local PlrListLayout = Instance.new("UIListLayout", PlrListContainer)
PlrListLayout.Padding = UDim.new(0,0)
PlrListLayout.FillDirection = Enum.FillDirection.Vertical
PlrListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function RefreshPlayerList()
    for _, c in ipairs(PlrListContainer:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end

    local playerList = Players:GetPlayers()
    local count = 0

    for _, player in ipairs(playerList) do
        if player == LocalPlayer then continue end
        count = count + 1
        local idx = count

        local prow = Instance.new("Frame", PlrListContainer)
        prow.Name = "Plr_"..player.Name
        prow.Size = UDim2.new(1,0,0,46)
        prow.BackgroundColor3 = (idx%2==0) and ROWALT or ROW
        prow.BorderSizePixel = 0; prow.LayoutOrder = idx; prow.ZIndex = 8

        local pline = Instance.new("Frame", prow)
        pline.Size = UDim2.new(1,0,0,1); pline.Position = UDim2.new(0,0,1,-1)
        pline.BackgroundColor3 = DIVIDER; pline.BorderSizePixel = 0

        local avFrame = Instance.new("Frame", prow)
        avFrame.Size = UDim2.new(0,26,0,26); avFrame.Position = UDim2.new(0,8,0.5,-13)
        avFrame.BackgroundColor3 = Color3.fromRGB(50,50,50); avFrame.BorderSizePixel = 0
        Instance.new("UICorner", avFrame).CornerRadius = UDim.new(1,0)
        local avImg = Instance.new("ImageLabel", avFrame)
        avImg.Size = UDim2.new(1,0,1,0); avImg.BackgroundTransparency = 1; avImg.BorderSizePixel = 0
        Instance.new("UICorner", avImg).CornerRadius = UDim.new(1,0)
        task.spawn(function()
            local ok, img = pcall(function()
                return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
            end)
            if ok and img then avImg.Image = img end
        end)

        local dot = Instance.new("Frame", prow)
        dot.Size = UDim2.new(0,8,0,8); dot.Position = UDim2.new(0,28,0,8)
        dot.BackgroundColor3 = GREEN; dot.BorderSizePixel = 0
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)

        local pname = Instance.new("TextLabel", prow)
        pname.Text = player.Name
        pname.Size = UDim2.new(1,-160,0,18); pname.Position = UDim2.new(0,42,0,4)
        pname.BackgroundTransparency = 1; pname.TextColor3 = TEXTW
        pname.Font = Enum.Font.GothamSemibold; pname.TextSize = 11
        pname.TextXAlignment = Enum.TextXAlignment.Left

        local pdisplay = Instance.new("TextLabel", prow)
        pdisplay.Text = player.DisplayName ~= player.Name and ("@"..player.DisplayName) or ""
        pdisplay.Size = UDim2.new(1,-160,0,14); pdisplay.Position = UDim2.new(0,42,0,22)
        pdisplay.BackgroundTransparency = 1; pdisplay.TextColor3 = TEXTD
        pdisplay.Font = Enum.Font.Gotham; pdisplay.TextSize = 9
        pdisplay.TextXAlignment = Enum.TextXAlignment.Left

        local myHRP2   = GetHRP()
        local tgtChar  = player.Character
        local tgtHRP   = tgtChar and tgtChar:FindFirstChild("HumanoidRootPart")
        local distText = "? studs"
        local distColor = TEXTD
        if myHRP2 and tgtHRP then
            local dist = math.floor((myHRP2.Position - tgtHRP.Position).Magnitude)
            distText  = dist .. " studs"
            distColor = dist < 100 and GREEN or (dist < 500 and GOLD or ACCENT)
        elseif not tgtHRP then
            distText  = "out of range"
            distColor = ACCENT
        end

        local distLabel = Instance.new("TextLabel", prow)
        distLabel.Text = distText
        distLabel.Size = UDim2.new(1,-160,0,13); distLabel.Position = UDim2.new(0,42,1,-15)
        distLabel.BackgroundTransparency = 1; distLabel.TextColor3 = distColor
        distLabel.Font = Enum.Font.Gotham; distLabel.TextSize = 9
        distLabel.TextXAlignment = Enum.TextXAlignment.Left

        local tpPlrBtn = MakeSmallBtn(prow, "TP →", BLUEDK, UDim2.new(1,-78,0.5,-13), nil, 68, 26)

        tpPlrBtn.MouseButton1Click:Connect(function()
            local char = player.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local targetCF = hrp.CFrame * CFrame.new(4, 0, 0)
                TeleportTo(targetCF.X, targetCF.Y, targetCF.Z)
                plrCountLabel.Text = "✅ Teleport ke " .. player.Name
                plrCountLabel.TextColor3 = GREEN
                task.delay(2, function()
                    plrCountLabel.Text = "🟢  Ditemukan: " .. count .. " player"
                    plrCountLabel.TextColor3 = GREEN
                end)
            else
                tpPlrBtn.Text = "..."
                tpPlrBtn.BackgroundColor3 = GOLD
                plrCountLabel.Text = "⏳ Mendekati " .. player.Name .. "..."
                plrCountLabel.TextColor3 = GOLD

                local stepSize   = 400
                local maxSteps   = 20
                local stepCount  = 0

                task.spawn(function()
                    while stepCount < maxSteps do
                        stepCount = stepCount + 1

                        local c2  = player.Character
                        local h2  = c2 and c2:FindFirstChild("HumanoidRootPart")
                        if h2 then
                            local cf2 = h2.CFrame * CFrame.new(4, 0, 0)
                            TeleportTo(cf2.X, cf2.Y, cf2.Z)
                            tpPlrBtn.Text = "TP →"
                            tpPlrBtn.BackgroundColor3 = BLUEDK
                            plrCountLabel.Text = "✅ Teleport ke " .. player.Name
                            plrCountLabel.TextColor3 = GREEN
                            task.delay(2, function()
                                plrCountLabel.Text = "🟢  Ditemukan: " .. count .. " player"
                                plrCountLabel.TextColor3 = GREEN
                            end)
                            return
                        end

                        local myH = GetHRP()
                        if myH then
                            local fwd = myH.CFrame.LookVector
                            local pos = myH.Position + (fwd * stepSize)
                            TeleportTo(pos.X, pos.Y, pos.Z)
                        end

                        plrCountLabel.Text = "⏳ Step " .. stepCount .. "/" .. maxSteps .. " — " .. player.Name
                        task.wait(0.4)
                    end

                    tpPlrBtn.Text = "TP →"
                    tpPlrBtn.BackgroundColor3 = BLUEDK
                    plrCountLabel.Text = "⚠ " .. player.Name .. " terlalu jauh / streaming"
                    plrCountLabel.TextColor3 = ACCENT
                    task.delay(3, function()
                        plrCountLabel.Text = "🟢  Ditemukan: " .. count .. " player"
                        plrCountLabel.TextColor3 = GREEN
                    end)
                end)
            end
        end)

        local hBtn = Instance.new("TextButton", prow)
        hBtn.Size = UDim2.new(1,-80,1,0); hBtn.BackgroundTransparency = 1; hBtn.Text = ""; hBtn.ZIndex = 7
        hBtn.MouseEnter:Connect(function()
            TweenService:Create(prow,TweenInfo.new(0.08),{BackgroundColor3=Color3.fromRGB(42,42,42)}):Play()
        end)
        hBtn.MouseLeave:Connect(function()
            TweenService:Create(prow,TweenInfo.new(0.08),{BackgroundColor3=(idx%2==0) and ROWALT or ROW}):Play()
        end)
    end

    if count == 0 then
        plrCountLabel.Text = "Tidak ada player lain di server ini"
        plrCountLabel.TextColor3 = TEXTD

        local empty = Instance.new("Frame", PlrListContainer)
        empty.Size = UDim2.new(1,0,0,40); empty.BackgroundColor3 = ROWALT
        empty.BorderSizePixel = 0; empty.LayoutOrder = 1
        local el = Instance.new("TextLabel", empty)
        el.Text = "Kamu sendirian di server ini 😢"
        el.Size = UDim2.new(1,0,1,0); el.BackgroundTransparency = 1
        el.TextColor3 = TEXTD; el.Font = Enum.Font.Gotham; el.TextSize = 10
    else
        plrCountLabel.Text = "🟢  Ditemukan: " .. count .. " player"
        plrCountLabel.TextColor3 = GREEN
    end
end

scanBtn.MouseButton1Click:Connect(function()
    plrCountLabel.Text = "⏳ Scanning..."
    plrCountLabel.TextColor3 = GOLD
    task.wait(0.3)
    RefreshPlayerList()
end)

Players.PlayerAdded:Connect(function()
    if tabPages["Players"] and tabPages["Players"].Visible then RefreshPlayerList() end
end)
Players.PlayerRemoving:Connect(function()
    if tabPages["Players"] and tabPages["Players"].Visible then RefreshPlayerList() end
end)

-- ════════════════════════════════════════
--    SPEED & JUMP TAB
-- ════════════════════════════════════════
local SpeedTab = NewTab("Speed", 3)

local DEFAULT_SPEED = 16
local speedEnabled  = true

local function ApplySpeed(val)
    local hum = GetHumanoid()
    if not hum then return end
    hum.WalkSpeed = speedEnabled and val or 16
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    hum.WalkSpeed = speedEnabled and DEFAULT_SPEED or 16
end)

local spHeaderRow = MakeRow(SpeedTab, 1, 40)
spHeaderRow.BackgroundColor3 = Color3.fromRGB(28,28,28)
local spHeaderLabel = Instance.new("TextLabel", spHeaderRow)
spHeaderLabel.Text = "⚡  Speed & Jump"
spHeaderLabel.Size = UDim2.new(1,-10,1,0); spHeaderLabel.Position = UDim2.new(0,10,0,0)
spHeaderLabel.BackgroundTransparency = 1; spHeaderLabel.TextColor3 = TEXTW
spHeaderLabel.Font = Enum.Font.GothamBold; spHeaderLabel.TextSize = 11
spHeaderLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Slider generik
local function MakeSliderRow(parent, lo, icon, label, defaultVal, maxVal, fillColor, onChange)
    local row = MakeRow(parent, lo, 54)

    local nameLbl = Instance.new("TextLabel", row)
    nameLbl.Text = icon .. "  " .. label
    nameLbl.Size = UDim2.new(0,100,0,18); nameLbl.Position = UDim2.new(0,10,0,5)
    nameLbl.BackgroundTransparency = 1; nameLbl.TextColor3 = TEXTW
    nameLbl.Font = Enum.Font.GothamSemibold; nameLbl.TextSize = 11
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left

    local valLbl = Instance.new("TextLabel", row)
    valLbl.Text = tostring(defaultVal)
    valLbl.Size = UDim2.new(0,40,0,18); valLbl.Position = UDim2.new(0,112,0,5)
    valLbl.BackgroundTransparency = 1; valLbl.TextColor3 = GOLD
    valLbl.Font = Enum.Font.GothamBold; valLbl.TextSize = 12
    valLbl.TextXAlignment = Enum.TextXAlignment.Left

    local track = Instance.new("Frame", row)
    track.Size = UDim2.new(1,-24,0,6); track.Position = UDim2.new(0,12,0,36)
    track.BackgroundColor3 = Color3.fromRGB(50,50,50); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)

    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new(defaultVal/maxVal,0,1,0)
    fill.BackgroundColor3 = fillColor; fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

    local thumb = Instance.new("TextButton", track)
    thumb.Size = UDim2.new(0,16,0,16); thumb.AnchorPoint = Vector2.new(0.5,0.5)
    thumb.Position = UDim2.new(defaultVal/maxVal,0,0.5,0)
    thumb.BackgroundColor3 = TEXTW; thumb.Text = ""; thumb.BorderSizePixel = 0; thumb.ZIndex = 10
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1,0)

    local inp = MakeInlineInput(row, tostring(defaultVal), UDim2.new(0,155,0,3), UDim2.new(0,44,0,20))
    inp.Text = tostring(defaultVal)

    local setBtn   = MakeSmallBtn(row, "Set",   fillColor,                UDim2.new(0,203,0,5), nil, 32, 20)
    local resetBtn = MakeSmallBtn(row, "Reset", Color3.fromRGB(55,55,55), UDim2.new(1,-40,0,5), nil, 32, 20)

    local function setVal(val)
        val = math.clamp(math.floor(tonumber(val) or defaultVal), 1, 1000)
        local rel = math.clamp(val / maxVal, 0, 1)
        fill.Size = UDim2.new(rel,0,1,0)
        thumb.Position = UDim2.new(rel,0,0.5,0)
        valLbl.Text = tostring(val); inp.Text = tostring(val)
        if onChange then onChange(val) end
    end

    local dragging = false
    thumb.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then dragging = true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType ~= Enum.UserInputType.MouseMovement
        and i.UserInputType ~= Enum.UserInputType.Touch then return end
        local rel = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        setVal(rel * maxVal)
    end)

    setBtn.MouseButton1Click:Connect(function() setVal(inp.Text) end)
    resetBtn.MouseButton1Click:Connect(function() setVal(defaultVal) end)

    return row, setVal
end

local speedRow, SetSpeedValue = MakeSliderRow(SpeedTab, 2, "🏃", "WalkSpeed", 16, 200, BLUE, function(v)
    DEFAULT_SPEED = v
    ApplySpeed(v)
end)

-- ─── SPEED TOGGLE ON/OFF ───
local speedToggleRow = MakeRow(SpeedTab, 3, 36)
speedToggleRow.BackgroundColor3 = Color3.fromRGB(26,26,26)

local speedToggleLbl = Instance.new("TextLabel", speedToggleRow)
speedToggleLbl.Text = "Custom Speed:"
speedToggleLbl.Size = UDim2.new(0,110,1,0); speedToggleLbl.Position = UDim2.new(0,10,0,0)
speedToggleLbl.BackgroundTransparency = 1; speedToggleLbl.TextColor3 = TEXTG
speedToggleLbl.Font = Enum.Font.Gotham; speedToggleLbl.TextSize = 11
speedToggleLbl.TextXAlignment = Enum.TextXAlignment.Left

local speedToggleStatus = Instance.new("TextLabel", speedToggleRow)
speedToggleStatus.Text = "ON"
speedToggleStatus.Size = UDim2.new(0,35,1,0); speedToggleStatus.Position = UDim2.new(0,118,0,0)
speedToggleStatus.BackgroundTransparency = 1; speedToggleStatus.TextColor3 = GREEN
speedToggleStatus.Font = Enum.Font.GothamBold; speedToggleStatus.TextSize = 11
speedToggleStatus.TextXAlignment = Enum.TextXAlignment.Left

local speedToggleBtn = MakeSmallBtn(speedToggleRow, "✔ Aktif", GREENDK, UDim2.new(1,-86,0.5,-13), nil, 78, 26)
speedToggleBtn.MouseButton1Click:Connect(function()
    speedEnabled = not speedEnabled
    if speedEnabled then
        speedToggleBtn.Text = "✔ Aktif"
        speedToggleBtn.BackgroundColor3 = GREENDK
        speedToggleStatus.Text = "ON"; speedToggleStatus.TextColor3 = GREEN
        ApplySpeed(DEFAULT_SPEED)
    else
        speedToggleBtn.Text = "✖ Nonaktif"
        speedToggleBtn.BackgroundColor3 = Color3.fromRGB(80,30,30)
        speedToggleStatus.Text = "OFF"; speedToggleStatus.TextColor3 = TEXTD
        ApplySpeed(16)
    end
end)

-- ─── INFINITE JUMP ───
local ijRow = MakeRow(SpeedTab, 4, 44)
ijRow.BackgroundColor3 = Color3.fromRGB(24,24,24)

local ijLabel = Instance.new("TextLabel", ijRow)
ijLabel.Text = "🦘  Infinite Jump"
ijLabel.Size = UDim2.new(0.55,0,1,0); ijLabel.Position = UDim2.new(0,10,0,0)
ijLabel.BackgroundTransparency = 1; ijLabel.TextColor3 = TEXTW
ijLabel.Font = Enum.Font.GothamBold; ijLabel.TextSize = 11
ijLabel.TextXAlignment = Enum.TextXAlignment.Left

local ijStatusLabel = Instance.new("TextLabel", ijRow)
ijStatusLabel.Text = "OFF"
ijStatusLabel.Size = UDim2.new(0,40,1,0); ijStatusLabel.Position = UDim2.new(0.55,0,0,0)
ijStatusLabel.BackgroundTransparency = 1; ijStatusLabel.TextColor3 = TEXTD
ijStatusLabel.Font = Enum.Font.GothamBold; ijStatusLabel.TextSize = 11
ijStatusLabel.TextXAlignment = Enum.TextXAlignment.Left

local ijToggleBtn = MakeSmallBtn(ijRow, "▶ ON", GREENDK, UDim2.new(1,-86,0.5,-13), nil, 78, 26)

local infiniteJumpActive = false

-- Koneksi tunggal (tidak perlu reconnect saat respawn)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed or not infiniteJumpActive then return end
    if input.KeyCode ~= Enum.KeyCode.Space
    and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local hum = GetHumanoid()
    if not hum then return end
    local state = hum:GetState()
    if state == Enum.HumanoidStateType.Freefall
    or state == Enum.HumanoidStateType.Jumping then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

ijToggleBtn.MouseButton1Click:Connect(function()
    infiniteJumpActive = not infiniteJumpActive
    if infiniteJumpActive then
        ijToggleBtn.Text = "■ OFF"; ijToggleBtn.BackgroundColor3 = ACCENT2
        ijStatusLabel.Text = "ON ✔"; ijStatusLabel.TextColor3 = GREEN
    else
        ijToggleBtn.Text = "▶ ON"; ijToggleBtn.BackgroundColor3 = GREENDK
        ijStatusLabel.Text = "OFF"; ijStatusLabel.TextColor3 = TEXTD
    end
end)

-- ─── PRESET BUTTONS ───
local presetRow = MakeRow(SpeedTab, 5, 36)
presetRow.BackgroundColor3 = Color3.fromRGB(24,24,24)
local presetLbl = Instance.new("TextLabel", presetRow)
presetLbl.Text = "Preset:"; presetLbl.Size = UDim2.new(0,46,1,0); presetLbl.Position = UDim2.new(0,10,0,0)
presetLbl.BackgroundTransparency = 1; presetLbl.TextColor3 = TEXTG
presetLbl.Font = Enum.Font.Gotham; presetLbl.TextSize = 10; presetLbl.TextXAlignment = Enum.TextXAlignment.Left

local p1 = MakeSmallBtn(presetRow, "Normal", Color3.fromRGB(60,60,60),  UDim2.new(0, 58,0.5,-11), nil, 58, 22)
local p2 = MakeSmallBtn(presetRow, "Fast",   BLUEDK,                    UDim2.new(0,120,0.5,-11), nil, 48, 22)
local p3 = MakeSmallBtn(presetRow, "Super",  Color3.fromRGB(120,50,200),UDim2.new(0,172,0.5,-11), nil, 48, 22)
local p4 = MakeSmallBtn(presetRow, "MAX",    ACCENT2,                   UDim2.new(0,224,0.5,-11), nil, 40, 22)
p1.MouseButton1Click:Connect(function() SetSpeedValue(16)  end)
p2.MouseButton1Click:Connect(function() SetSpeedValue(50)  end)
p3.MouseButton1Click:Connect(function() SetSpeedValue(100) end)
p4.MouseButton1Click:Connect(function() SetSpeedValue(500) end)

-- ─── FLY TOGGLE ───
local flyRow = MakeRow(SpeedTab, 6, 44)
flyRow.BackgroundColor3 = Color3.fromRGB(24,24,24)

local flyLabel = Instance.new("TextLabel", flyRow)
flyLabel.Text = "🕊  Fly"
flyLabel.Size = UDim2.new(0,60,1,0); flyLabel.Position = UDim2.new(0,10,0,0)
flyLabel.BackgroundTransparency = 1; flyLabel.TextColor3 = TEXTW
flyLabel.Font = Enum.Font.GothamBold; flyLabel.TextSize = 11
flyLabel.TextXAlignment = Enum.TextXAlignment.Left

local flyStatusLabel = Instance.new("TextLabel", flyRow)
flyStatusLabel.Text = "OFF"
flyStatusLabel.Size = UDim2.new(0,40,1,0); flyStatusLabel.Position = UDim2.new(0,62,0,0)
flyStatusLabel.BackgroundTransparency = 1; flyStatusLabel.TextColor3 = TEXTD
flyStatusLabel.Font = Enum.Font.GothamBold; flyStatusLabel.TextSize = 11
flyStatusLabel.TextXAlignment = Enum.TextXAlignment.Left

local flySpeedLabel = Instance.new("TextLabel", flyRow)
flySpeedLabel.Text = "Fly Speed:"
flySpeedLabel.Size = UDim2.new(0,60,1,0); flySpeedLabel.Position = UDim2.new(0,110,0,0)
flySpeedLabel.BackgroundTransparency = 1; flySpeedLabel.TextColor3 = TEXTG
flySpeedLabel.Font = Enum.Font.Gotham; flySpeedLabel.TextSize = 10
flySpeedLabel.TextXAlignment = Enum.TextXAlignment.Left

local flySpeedInput = MakeInlineInput(flyRow, "50", UDim2.new(0,172,0.5,-11), UDim2.new(0,38,0,22))
flySpeedInput.Text = "50"

local flyToggleBtn = MakeSmallBtn(flyRow, "▶ Fly ON", Color3.fromRGB(50,120,200), UDim2.new(1,-86,0.5,-13), nil, 78, 26)

local flyThread    = nil
local flyBodyVel   = nil
local flyBodyGyro  = nil
local flyJumpHeld  = false

UserInputService.JumpRequest:Connect(function()
    if not flyActive then return end
    flyJumpHeld = true
    task.delay(0.2, function() flyJumpHeld = false end)
end)

StopFly = function()
    flyActive = false
    if flyThread then task.cancel(flyThread); flyThread = nil end
    if flyBodyVel  and flyBodyVel.Parent  then flyBodyVel:Destroy()  end
    if flyBodyGyro and flyBodyGyro.Parent then flyBodyGyro:Destroy() end
    flyBodyVel = nil; flyBodyGyro = nil
    local hum = GetHumanoid()
    if hum then hum.PlatformStand = false end
    flyToggleBtn.Text = "▶ Fly ON"
    flyToggleBtn.BackgroundColor3 = Color3.fromRGB(50,120,200)
    flyStatusLabel.Text = "OFF"; flyStatusLabel.TextColor3 = TEXTD
end

local function StartFly()
    local hrp = GetHRP()
    local hum = GetHumanoid()
    if not hrp or not hum then return end

    flyActive = true
    hum.PlatformStand = true

    flyBodyVel = Instance.new("BodyVelocity", hrp)
    flyBodyVel.Velocity = Vector3.zero
    flyBodyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)

    flyBodyGyro = Instance.new("BodyGyro", hrp)
    flyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flyBodyGyro.P         = 1e4
    flyBodyGyro.CFrame    = hrp.CFrame

    flyToggleBtn.Text = "■ Fly OFF"
    flyToggleBtn.BackgroundColor3 = ACCENT2
    flyStatusLabel.Text = "ON ✈"; flyStatusLabel.TextColor3 = BLUE

    flyThread = task.spawn(function()
        local cam = workspace.CurrentCamera
        while flyActive do
            local hrp2 = GetHRP()
            local hum2 = GetHumanoid()
            if not hrp2 or not flyBodyVel or not flyBodyVel.Parent then
                StopFly(); break
            end

            local speed = tonumber(flySpeedInput.Text) or 50
            local dir   = Vector3.zero
            local camCF = cam.CFrame

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - camCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + camCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end

            if hum2 then
                local moveDir = hum2.MoveDirection
                if moveDir.Magnitude > 0.1 then
                    local flatLook  = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
                    local flatRight = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)
                    local fwdAmt   = flatLook.Magnitude  > 0.01 and flatLook.Unit:Dot(moveDir)  or 0
                    local rightAmt = flatRight.Magnitude > 0.01 and flatRight.Unit:Dot(moveDir) or 0
                    dir = dir + (camCF.LookVector * fwdAmt) + (camCF.RightVector * rightAmt)
                end
            end

            if flyJumpHeld then dir = dir + Vector3.new(0,1,0) end

            if dir.Magnitude > 0 then
                flyBodyVel.Velocity = dir.Unit * speed
            else
                flyBodyVel.Velocity = Vector3.zero
            end

            flyBodyGyro.CFrame = CFrame.new(Vector3.zero, camCF.LookVector) + hrp2.Position

            task.wait()
        end
    end)
end

flyToggleBtn.MouseButton1Click:Connect(function()
    if flyActive then StopFly() else StartFly() end
end)

LocalPlayer.CharacterAdded:Connect(function()
    if flyActive then StopFly() end
end)

-- ════════════════════════════════════════
--    SETTINGS TAB
-- ════════════════════════════════════════
local SettingsTab = NewTab("Settings", 4)

local function MakeActionRow(lo, labelText, btnText, color, btnW)
    local row = MakeRow(SettingsTab, lo, 38)
    local lbl = Instance.new("TextLabel", row)
    lbl.Text = labelText
    lbl.Size = UDim2.new(0.55,0,1,0); lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1; lbl.TextColor3 = TEXTW
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local w = btnW or 80
    local btn = MakeSmallBtn(row, btnText, color, UDim2.new(1,-(w+10),0.5,-11), nil, w, 22)
    return row, btn
end

-- ── DATA ──
MakeSecHeader(SettingsTab, "DATA", 1)

local _, manualSaveBtn = MakeActionRow(2, "Manual Save sekarang", "💾 Save", GREENDK)
manualSaveBtn.MouseButton1Click:Connect(function()
    local ok = SaveData(true)
    if ok then Toast("💾 Tersimpan!", GREEN)
    else Toast("⚠ Gagal simpan (executor tanpa writefile?)", GOLD) end
end)

-- ── EXPORT ──
MakeSecHeader(SettingsTab, "SALIN / EXPORT WAYPOINT", 3)

local _, copyTxtBtn = MakeActionRow(4, "Salin semua posisi (teks)", "📋 Teks", BLUEDK)
copyTxtBtn.MouseButton1Click:Connect(function()
    CopyText(BuildText(FolderSet(nil)), "📋 Teks tercopy!")
end)

local _, copyLuaBtn = MakeActionRow(5, "Salin sebagai tabel Lua", "📋 Lua", Color3.fromRGB(120,50,200))
copyLuaBtn.MouseButton1Click:Connect(function()
    CopyText(BuildLua(FolderSet(nil)), "📋 Lua tercopy!")
end)

local _, copyJsonBtn = MakeActionRow(6, "Salin backup (JSON)", "📋 JSON", GREENDK)
copyJsonBtn.MouseButton1Click:Connect(function()
    CopyText(BuildJSON(FolderSet(nil)), "📋 JSON tercopy!")
end)

-- ── IMPORT ──
MakeSecHeader(SettingsTab, "IMPORT WAYPOINT (tempel JSON backup)", 7)

local importRow = MakeRow(SettingsTab, 8, 42)
local importInput = MakeInlineInput(importRow, "Tempel JSON di sini...", UDim2.new(0,10,0.5,-12), UDim2.new(1,-100,0,24))
local importBtn = MakeSmallBtn(importRow, "⬇ Import", BLUEDK, UDim2.new(1,-80,0.5,-11), nil, 70, 22)
importBtn.MouseButton1Click:Connect(function()
    local text = importInput.Text
    if text == "" then Toast("⚠ Isi JSON dulu", GOLD); return end
    local d = DecodeJSON(text)
    if not d then Toast("⚠ JSON tidak valid", ACCENT); return end
    local list = Sanitize(d)
    if #list == 0 then Toast("⚠ Tidak ada data valid", GOLD); return end
    for _, f in ipairs(list) do table.insert(Folders, f) end
    importInput.Text = ""
    RefreshFolderList(); RefreshWaypointPanel(); SaveData(true)
    Toast("✅ " .. #list .. " folder diimport", GREEN)
end)

-- ── DANGER ──
MakeSecHeader(SettingsTab, "BAHAYA", 9)

local _, clearBtn = MakeActionRow(10, "Hapus SEMUA data (tap 2x)", "🗑 Hapus", ACCENT2)
ConfirmBtn(clearBtn, "🗑 Hapus", function()
    StopAllLoops()
    loopStepLabel.Text = "—"
    Folders = {}; selectedFolder = nil
    RefreshFolderList(); RefreshWaypointPanel(); SaveData(true)
    Toast("🗑 Semua data dihapus (backup tersimpan)", GOLD)
end)

-- ── INFO ──
MakeSecHeader(SettingsTab, "INFO", 11)
local infoRow = MakeRow(SettingsTab, 12, 130)
local infoL = Instance.new("TextLabel", infoRow)
local saveType = canSaveFile and "writefile (file lokal)" or "in-memory (sesi ini saja)"
infoL.Text = "G = Toggle GUI  (HP: tombol K4 setelah ditutup)\n\nAuto-save: " .. saveType ..
    "\nFile: " .. SAVE_FILE ..
    "\nBackup otomatis: " .. BACKUP_FILE ..
    "\nAuto-save tiap 30 detik + setiap perubahan." ..
    "\n\nTombol 📋 Salin ada di tab Waypoints & Settings." ..
    "\nKalau executor tak punya clipboard, muncul kotak untuk salin manual."
infoL.Size = UDim2.new(1,-20,1,0); infoL.Position = UDim2.new(0,10,0,6)
infoL.BackgroundTransparency = 1; infoL.TextColor3 = TEXTG
infoL.Font = Enum.Font.Gotham; infoL.TextSize = 10; infoL.TextXAlignment = Enum.TextXAlignment.Left
infoL.TextYAlignment = Enum.TextYAlignment.Top; infoL.TextWrapped = true

-- ════════════════════════════════════════
--    HOTKEY G = TOGGLE GUI
-- ════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, proc)
    if proc then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode == Enum.KeyCode.G then
        if Dialog.Visible then return end
        SetOpen(not guiOpen)
        if guiOpen then Body.Visible = not minimized end
    end
end)

-- Simpan saat game ditutup
Players.PlayerRemoving:Connect(function(p)
    if p == LocalPlayer then SaveData() end
end)

-- ─── INIT ───
SwitchTab("Waypoints")
RefreshFolderList()
RefreshWaypointPanel()

task.spawn(function()
    task.wait(0.5)
    pcall(function()
        local msg = canSaveFile and "Auto-save aktif (file + backup)." or "Auto-save: in-memory."
        if loadFailed then msg = "⚠ File rusak, data lama dilindungi!" end
        StarterGui:SetCore("SendNotification", {
            Title    = "K4TSS V2.1",
            Text     = "Waypoint Hub loaded! " .. msg,
            Duration = 5,
        })
    end)
end)

print("[K4TSS V2.1] Waypoint Hub Loaded! | G = Toggle GUI | Salin waypoint: tab Waypoints / Settings")
