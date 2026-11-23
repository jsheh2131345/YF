-- ============================================================
-- XD Ultimate - Part 1 (核心逻辑与底层架构)
-- 请与 Part 2 在同一个执行器中运行，或者拼接在一起
-- ============================================================

local Players       = game:GetService("Players")
local LP            = Players.LocalPlayer
local PlayerGui     = LP:WaitForChild("PlayerGui")
local RS            = game:GetService("ReplicatedStorage")
local WS            = game:GetService("Workspace")
local RunService    = game:GetService("RunService")
local UIS           = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")
local HttpService   = game:GetService("HttpService")

-- 清理旧连接
if getgenv().XD_Connections then
    for _, conn in ipairs(getgenv().XD_Connections) do
        pcall(function() conn:Disconnect() end)
    end
end
getgenv().XD_Connections = {}

local function AddConnection(conn)
    if conn then table.insert(getgenv().XD_Connections, conn) end
    return conn
end

-- ============================================================
-- 1. UI 库与主题 (先加载，后面 Part 2 要用)
-- ============================================================
local repo = "https://cdn.jsdelivr.net/gh/deividcomsono/Obsidian@main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
Library.ShowCustomCursor = true
Library.NotifySide = "Right"

Library.Theme = {
    Name = "XD Ultimate",
    AccentColor = Color3.fromRGB(255, 100, 150),
    BackgroundColor = Color3.fromRGB(18, 18, 22),
    OutlineColor = Color3.fromRGB(45, 45, 50),
    FontColor = Color3.fromRGB(230, 230, 235),
    TextDarkTheme = true
}

local Window = Library:CreateWindow({
    Title = "XD Ultimate",
    Footer = "Forsaken | v3.0 | " .. LP.Name,
    Icon = "rbxassetid://4483362748",
    Center = true,
    AutoShow = true,
    Resizable = true,
    NotifySide = "Right",
    ToggleKeybind = Enum.KeyCode.RightShift
})

local Tabs = {
    Main      = Window:AddTab("主页", "home"),
    Block     = Window:AddTab("自动格挡", "shield"),
    Adjust    = Window:AddTab("调节", "sliders"),
    Aimbot    = Window:AddTab("开枪自瞄", "crosshair"),
    Backstab  = Window:AddTab("自动背刺", "sword"),
    Visual    = Window:AddTab("视觉", "eye"),
    Utility   = Window:AddTab("实用功能", "wrench"),
    Logs      = Window:AddTab("运行日志", "terminal"),
    Settings  = Window:AddTab("设置", "settings"),
}

local function Notify(title, desc, time)
    pcall(function() Library:Notify({Title=title, Description=desc, Time=time or 3}) end)
end

-- ============================================================
-- 2. 配置系统
-- ============================================================
local Config = {
    Block = {
        Enabled = false, TriggerRadius = 20, BoxScale = 1.0,
        BoxForwardOffset = 4, BoxTransparency = 0.5,
        BoxSafeColor = {0, 255, 0}, BoxDangerColor = {255, 0, 0},
        FacingCheck = false, FacingAngle = 90, WallCheck = false,
        BlockDelay = 0.02, Cooldown = 0.2,
        MaxSoundAge = 1.2, MaxAnimAge = 1.5,
        ShowBox = true,
    },
    Aimbot = { ChanceEnabled = false, Distance = 100, Smoothness = 0.8, AimMode = "Camera" },
    Backstab = { Enabled = false, Distance = 8, Key = Enum.KeyCode.E, Mode = "Teleport" },
    Visual = { EnlargeHitbox = false, HitboxMultiplier = 3, LocalHitbox = false, ShowChat = false },
    Utility = { InfiniteStamina = false, NoStaminaLoss = false },
    Preset = "普通",
}

local CONFIG_FILE = "XD_Ultimate_Config.json"
local function SaveConfig()
    pcall(function()
        if writefile then writefile(CONFIG_FILE, HttpService:JSONEncode(Config)) end
    end)
end
local function LoadConfig()
    pcall(function()
        if readfile and isfile and isfile(CONFIG_FILE) then
            local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
            for k, v in pairs(data) do if Config[k] ~= nil then Config[k] = v end end
        end
    end)
end
LoadConfig()

-- ============================================================
-- 3. 日志系统
-- ============================================================
local Logger = { Logs = {}, MaxLogs = 100, UIFrame = nil, UILayout = nil }
function Logger:Add(level, message)
    local timestamp = os.date("%H:%M:%S")
    local entry = string.format("[%s] [%s] %s", timestamp, level, message)
    table.insert(self.Logs, 1, entry)
    if #self.Logs > self.MaxLogs then table.remove(self.Logs) end
    print("[XD]", entry)
    self:Render()
end
function Logger:Render()
    if not self.UIFrame then return end
    for _, child in ipairs(self.UIFrame:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end
    for i, log in ipairs(self.Logs) do
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -10, 0, 20)
        lbl.BackgroundTransparency = 1
        lbl.Text = log
        lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        lbl.TextSize = 11
        lbl.Font = Enum.Font.Code
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.LayoutOrder = i
        lbl.Parent = self.UIFrame
    end
end
function Logger:InitUI()
    local group = Tabs.Logs:AddLeftGroupbox("日志控制", "terminal")
    group:AddButton({ Text = "清空日志", Func = function() self.Logs = {}; self:Render() end })
    local frame = Instance.new("ScrollingFrame")
    frame.Size = UDim2.new(0, 400, 0, 400)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    frame.BorderSizePixel = 0
    frame.CanvasSize = UDim2.new(0, 0, 0, 0)
    frame.ScrollBarThickness = 4
    frame.Parent = group.Container or group.Frame or group
    local layout = Instance.new("UIListLayout")
    layout.Parent = frame
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    self.UIFrame = frame
    self.UILayout = layout
    AddConnection(RunService.Heartbeat:Connect(function()
        if frame.Parent then frame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10) end
    end))
end

-- ============================================================
-- 4. 网络与底层
-- ============================================================
local RemoteEvent
pcall(function() RemoteEvent = RS:WaitForChild("Modules"):WaitForChild("Network"):WaitForChild("RemoteEvent", 5) end)

local lastBlockTime = 0
local function FireBlockRemote()
    if not RemoteEvent then return false end
    local now = tick()
    if now - lastBlockTime < Config.Block.Cooldown then return false end
    lastBlockTime = now
    local args = {"UseActorAbility", {buffer.fromstring("\3\5\0\0\0Block")}}
    pcall(function() RemoteEvent:FireServer(unpack(args)) end)
    return true
end

-- ============================================================
-- 5. ID 库
-- ============================================================
local AttackAnimIDs = {
    ["126830014841198"]=true, ["126355327951215"]=true, ["121086746534252"]=true, ["101736016625776"]=true,
    ["18885909645"]=true, ["98456918873918"]=true, ["18885937766"]=true, ["18885940850"]=true,
    ["105458270463374"]=true, ["106538427162796"]=true, ["139835501933932"]=true, ["126896426760253"]=true,
    ["114356208094580"]=true, ["135884061951801"]=true, ["83829782357897"]=true, ["99050723653468"]=true,
    ["119181003138006"]=true, ["122709416391891"]=true, ["87989533095285"]=true, ["133363345661032"]=true,
    ["128414736976503"]=true, ["139309647473555"]=true, ["88451353906104"]=true, ["91628732643385"]=true,
    ["115403107018365"]=true, ["124619925708292"]=true,
}
local AttackSoundIDs = {
    ["112809109188560"]=true, ["102228729296384"]=true, ["80516583309685"]=true, ["111261564982886"]=true,
    ["75467546215199"]=true, ["80919153988550"]=true, ["86451559088289"]=true, ["140242176732868"]=true,
    ["136323728355613"]=true, ["115026634746636"]=true, ["84116622032112"]=true, ["108907358619313"]=true,
    ["127793641088496"]=true, ["86174610237192"]=true, ["95079963655241"]=true, ["101199185291628"]=true,
    ["119942598489800"]=true, ["84307400688050"]=true, ["113037804008732"]=true, ["105200830849301"]=true,
    ["75330693422988"]=true, ["82221759983649"]=true, ["81702359653578"]=true, ["108610718831698"]=true,
    ["112395455254818"]=true, ["109431876587852"]=true, ["109348678063422"]=true, ["85853080745515"]=true,
    ["90819435118493"]=true, ["117173212095661"]=true, ["100321250424257"]=true, ["77100821793542"]=true,
    ["81989261113189"]=true, ["129108619555351"]=true, ["119583605486352"]=true, ["79980897195554"]=true,
    ["110877859670130"]=true, ["104910828105172"]=true, ["110126546193799"]=true, ["104388455240670"]=true,
    ["85544168523099"]=true, ["103736328206432"]=true, ["128307808203038"]=true, ["111104117703814"]=true,
    ["97100466324703"]=true, ["74000375845213"]=true, ["111502315377475"]=true, ["84340345572285"]=true,
    ["120394605928086"]=true, ["134973085112081"]=true, ["79554277951408"]=true, ["115476331903507"]=true,
    ["18885940850"]=true, ["18885937766"]=true,
}

-- ============================================================
-- 6. 工具函数
-- ============================================================
local function myRoot() local c = LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function getKillersFolder() local pf = WS:FindFirstChild("Players"); return pf and pf:FindFirstChild("Killers") end
local function GetBoxSize() return Vector3.new(4.8 * Config.Block.BoxScale, 8 * Config.Block.BoxScale, 5 * Config.Block.BoxScale) end

local function IsKillerFacingPlayer(root, kRoot)
    if not Config.Block.FacingCheck then return true end
    if not root or not kRoot then return false end
    local dir = (root.Position - kRoot.Position)
    local flat = Vector3.new(dir.X, 0, dir.Z).Unit
    local look = Vector3.new(kRoot.CFrame.LookVector.X, 0, kRoot.CFrame.LookVector.Z).Unit
    local dot = look:Dot(flat)
    local angle = math.deg(math.acos(math.clamp(dot, -1, 1)))
    return angle <= Config.Block.FacingAngle
end

local function HasLineOfSight(targetRoot)
    if not Config.Block.WallCheck then return true end
    local root = myRoot(); if not root then return false end
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true
    rayParams.FilterDescendantsInstances = {LP.Character}
    local result = WS:Raycast(root.Position, targetRoot.Position - root.Position, rayParams)
    return not result or result.Instance:IsDescendantOf(targetRoot.Parent)
end

local function IsPlayerInBox(root, kRoot)
    if not root or not kRoot then return false end
    local boxSize = GetBoxSize()
    local forward = kRoot.CFrame.LookVector
    local boxPos = kRoot.Position + forward * Config.Block.BoxForwardOffset
    local boxCFrame = CFrame.lookAt(boxPos, boxPos + forward * 100)
    local relative = root.Position - boxPos
    local localSpace = boxCFrame:VectorToObjectSpace(relative)
    return math.abs(localSpace.X) <= (boxSize.X / 2) and math.abs(localSpace.Y) <= (boxSize.Y / 2) and math.abs(localSpace.Z) <= (boxSize.Z / 2)
end

local function CheckAllBlockConditions(root, kRoot)
    if not root or not kRoot then return false end
    if not IsPlayerInBox(root, kRoot) then return false end
    if not IsKillerFacingPlayer(root, kRoot) then return false end
    if not HasLineOfSight(kRoot) then return false end
    return true
end

-- ============================================================
-- 7. 格挡模块核心
-- ============================================================
local BlockModule = { SoundBlockedUntil = {}, AnimBlockedUntil = {}, SoundStartTime = {}, AnimStartTime = {} }

function BlockModule:AttemptBlockSound(snd)
    if not Config.Block.Enabled or not snd or not snd:IsA("Sound") or not snd.IsPlaying then return end
    local id = tostring(snd.SoundId):match("%d+")
    if not id or not AttackSoundIDs[id] then return end
    local now = tick()
    if not self.SoundStartTime[snd] then self.SoundStartTime[snd] = now end
    if now - self.SoundStartTime[snd] > Config.Block.MaxSoundAge then return end
    if self.SoundBlockedUntil[snd] and now < self.SoundBlockedUntil[snd] then return end
    local root = myRoot(); if not root then return end
    local parent = snd.Parent
    while parent and not parent:IsA("Model") do parent = parent.Parent end
    if not parent then return end
    local kRoot = parent:FindFirstChild("HumanoidRootPart")
    if kRoot and CheckAllBlockConditions(root, kRoot) then
        if FireBlockRemote() then
            self.SoundBlockedUntil[snd] = now + 0.8
            Logger:Add("BLOCK", "音效格挡触发: " .. id)
        end
    end
end

function BlockModule:AttemptBlockAnim(animTrack)
    if not Config.Block.Enabled or not animTrack or not animTrack.Animation or not animTrack.IsPlaying then return end
    local id = tostring(animTrack.Animation.AnimationId):match("%d+")
    if not id or not AttackAnimIDs[id] then return end
    local now = tick()
    if not self.AnimStartTime[animTrack] then self.AnimStartTime[animTrack] = now end
    if now - self.AnimStartTime[animTrack] > Config.Block.MaxAnimAge then return end
    if self.AnimBlockedUntil[animTrack] and now < self.AnimBlockedUntil[animTrack] then return end
    local root = myRoot(); if not root then return end
    local parent = animTrack.Parent
    while parent and not parent:IsA("Model") do parent = parent.Parent end
    if not parent then return end
    local kRoot = parent:FindFirstChild("HumanoidRootPart")
    if kRoot and CheckAllBlockConditions(root, kRoot) then
        if FireBlockRemote() then
            self.AnimBlockedUntil[animTrack] = now + 0.8
            Logger:Add("BLOCK", "动画格挡触发: " .. id)
        end
    end
end

function BlockModule:HookSound(snd)
    if not snd:IsA("Sound") then return end
    if snd:GetAttribute("XD_Hooked") then return end
    snd:SetAttribute("XD_Hooked", true)
    AddConnection(snd.Played:Connect(function()
        self.SoundStartTime[snd] = tick()
        task.defer(function() self:AttemptBlockSound(snd) end)
    end))
    if snd.IsPlaying then
        self.SoundStartTime[snd] = tick()
        task.defer(function() self:AttemptBlockSound(snd) end)
    end
end

function BlockModule:HookAnimator(animator)
    if not animator:IsA("Animator") then return end
    if animator:GetAttribute("XD_Hooked") then return end
    animator:SetAttribute("XD_Hooked", true)
    AddConnection(animator.AnimationPlayed:Connect(function(track)
        self.AnimStartTime[track] = tick()
        task.defer(function() self:AttemptBlockAnim(track) end)
    end))
end

-- ============================================================
-- 8. 自瞄 & 背刺 & 体力 & 聊天 (核心逻辑)
-- ============================================================
local Aimbot = { Target = nil, LastAimTime = 0, ChanceAnims = { ["73921036900313"]=true, ["111384272984267"]=true, ["90499469533503"]=true, ["133491532453922"]=true } }
function Aimbot:IsLocalPlayerChance()
    local char = LP.Character; if not char then return false end
    local surv = WS:FindFirstChild("Players") and WS.Players:FindFirstChild("Survivors")
    if not surv then return false end
    for _, s in ipairs(surv:GetChildren()) do if s == char and s.Name == "Chance" then return true end end
    return false
end
function Aimbot:HookChanceAnim()
    local char = LP.Character; if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    local animator = hum:FindFirstChildOfClass("Animator"); if not animator then return end
    AddConnection(animator.AnimationPlayed:Connect(function(track)
        if not Config.Aimbot.ChanceEnabled or not self:IsLocalPlayerChance() then return end
        local id = track.Animation and track.Animation.AnimationId:match("%d+")
        if id and self.ChanceAnims[id] then
            local root = myRoot(); local kf = getKillersFolder()
            if not root or not kf then return end
            local nearest, minDist = nil, Config.Aimbot.Distance
            for _, k in ipairs(kf:GetChildren()) do
                if k:IsA("Model") then
                    local hrp = k:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local d = (hrp.Position - root.Position).Magnitude
                        if d < minDist then nearest, minDist = hrp, d end
                    end
                end
            end
            if nearest then self.Target = nearest; self.LastAimTime = tick(); Logger:Add("AIM", "自瞄锁定: " .. nearest.Parent.Name) end
        end
    end))
end
function Aimbot:Update()
    if not Config.Aimbot.ChanceEnabled or not self.Target then return end
    if tick() - self.LastAimTime > 0.5 or not self.Target.Parent then return end
    local root = myRoot(); if not root then return end
    local targetCF = CFrame.lookAt(root.Position, Vector3.new(self.Target.Position.X, root.Position.Y, self.Target.Position.Z))
    if Config.Aimbot.AimMode == "Camera" then
        workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(targetCF, Config.Aimbot.Smoothness)
    else
        root.CFrame = Config.Aimbot.Smoothness >= 0.99 and targetCF or root.CFrame:Lerp(targetCF, Config.Aimbot.Smoothness)
    end
end

local Backstab = { LastTime = 0, BeamPart1 = Instance.new("Part"), BeamPart2 = Instance.new("Part"), Beam = Instance.new("Beam") }
Backstab.BeamPart1.Anchored = true; Backstab.BeamPart1.CanCollide = false; Backstab.BeamPart1.Transparency = 1; Backstab.BeamPart1.Parent = WS
Backstab.BeamPart2.Anchored = true; Backstab.BeamPart2.CanCollide = false; Backstab.BeamPart2.Transparency = 1; Backstab.BeamPart2.Parent = WS
Backstab.Beam.FaceCamera = true; Backstab.Beam.Width0 = 0.1; Backstab.Beam.Width1 = 0.1; Backstab.Beam.LightEmission = 1; Backstab.Beam.LightInfluence = 0; Backstab.Beam.Enabled = false; Backstab.Beam.Parent = Backstab.BeamPart1
local att1 = Instance.new("Attachment", Backstab.BeamPart1); local att2 = Instance.new("Attachment", Backstab.BeamPart2); Backstab.Beam.Attachment0 = att1; Backstab.Beam.Attachment1 = att2

function Backstab:IsLocalPlayerTwoTime()
    local char = LP.Character; if not char then return false end
    local surv = WS:FindFirstChild("Players") and WS.Players:FindFirstChild("Survivors")
    if not surv then return false end
    for _, s in ipairs(surv:GetChildren()) do if s == char and s.Name == "TwoTime" then return true end end
    return false
end
function Backstab:Update()
    self.Beam.Enabled = false
    if not Config.Backstab.Enabled or not self:IsLocalPlayerTwoTime() then return end
    if tick() - self.LastTime < 1 then return end
    local root = myRoot(); local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return end
    local kf = getKillersFolder(); if not kf then return end
    local nearest, nearestDist = nil, math.huge
    for _, killer in ipairs(kf:GetChildren()) do
        if killer:IsA("Model") then
            local kRoot = killer:FindFirstChild("HumanoidRootPart"); local kHum = killer:FindFirstChildOfClass("Humanoid")
            if kRoot and kHum and kHum.Health > 0 then
                local dist = (kRoot.Position - root.Position).Magnitude
                if dist < nearestDist then nearestDist = dist; nearest = killer end
                local dot = kRoot.CFrame.LookVector:Dot((root.Position - kRoot.Position).Unit)
                local isBehind = dot < -0.2; local inDistance = dist <= Config.Backstab.Distance
                if killer == nearest then
                    self.BeamPart1.Position = root.Position; self.BeamPart2.Position = kRoot.Position
                    self.Beam.Enabled = true
                    self.Beam.Color = (inDistance and isBehind) and ColorSequence.new(Color3.fromRGB(0, 255, 0)) or ColorSequence.new(Color3.fromRGB(255, 0, 0))
                end
                if inDistance and isBehind and tick() - self.LastTime >= 1 then
                    pcall(function() game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game) end)
                    task.wait(0.1)
                    pcall(function() game:GetService("VirtualInputManager"):SendKeyEvent(true, Config.Backstab.Key, false, game); task.wait(0.05); game:GetService("VirtualInputManager"):SendKeyEvent(false, Config.Backstab.Key, false, game) end)
                    pcall(function() game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game) end)
                    self.LastTime = tick(); Logger:Add("BACKSTAB", "背刺触发: " .. killer.Name); break
                end
            end
        end
    end
end

local Chat = { Conn = nil }
function Chat:Toggle(enabled)
    Config.Visual.ShowChat = enabled
    pcall(function()
        local chatWindow = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
        if chatWindow then chatWindow.Enabled = enabled end
    end)
    if enabled then
        if self.Conn then self.Conn:Disconnect() end
        self.Conn = RunService.Heartbeat:Connect(function() pcall(function() local cw = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration"); if cw then cw.Enabled = true end end) end)
    else
        if self.Conn then self.Conn:Disconnect(); self.Conn = nil end
    end
end

local Stamina = { Running = false }
function Stamina:Apply()
    if not Config.Utility.InfiniteStamina and not Config.Utility.NoStaminaLoss then self.Running = false; return end
    if self.Running then return end
    self.Running = true
    task.spawn(function()
        while self.Running do
            pcall(function()
                local systems = RS:FindFirstChild("Systems")
                local sprinting = systems and systems:FindFirstChild("Character") and systems.Character:FindFirstChild("Game") and systems.Character.Game:FindFirstChild("Sprinting")
                if sprinting then
                    local m = require(sprinting)
                    if Config.Utility.InfiniteStamina then m.Stamina = m.MaxStamina end
                    if Config.Utility.InfiniteStamina or Config.Utility.NoStaminaLoss then m.StaminaLoss = 0 end
                end
            end)
            task.wait(0.2)
        end
    end)
end

-- 预先定义可视化和UI相关的占位，Part 2 会接管
local Visual = { Boxes = {}, ProcessedKillers = {}, LocalHitbox = nil, LocalConn = nil }
-- ============================================================
-- XD Ultimate - Part 2 (UI 界面与主循环)
-- ============================================================

-- 初始化日志界面
Logger:InitUI()

-- ============================================================
-- 9. 视觉模块详细实现 (接 Part 1)
-- ============================================================
function Visual:CreateBoxVisualization(killer)
    if not killer or not killer:FindFirstChild("HumanoidRootPart") then return end
    if self.Boxes[killer] then return end
    local folder = Instance.new("Folder"); folder.Name = "XD_BoxVisual"; folder.Parent = killer.HumanoidRootPart
    local box = Instance.new("Part"); box.Name = "DetectionBox"; box.Material = Enum.Material.ForceField
    box.Anchored = true; box.CanCollide = false; box.CanQuery = false
    box.Transparency = Config.Block.BoxTransparency
    box.Color = Color3.fromRGB(unpack(Config.Block.BoxDangerColor))
    box.Size = GetBoxSize(); box.Parent = folder
    self.Boxes[killer] = {folder = folder, box = box, killer = killer}
end

function Visual:UpdateBoxVisualization(visData, root)
    if not visData or not visData.folder or not visData.folder.Parent then return end
    if not root or not visData.killer or not visData.killer:FindFirstChild("HumanoidRootPart") then return end
    local kRoot = visData.killer.HumanoidRootPart
    local forward = kRoot.CFrame.LookVector
    local boxPos = kRoot.Position + forward * Config.Block.BoxForwardOffset
    visData.box.Size = GetBoxSize()
    visData.box.CFrame = CFrame.lookAt(boxPos, boxPos + forward * 100)
    visData.box.Transparency = Config.Block.BoxTransparency
    local shouldBlock = CheckAllBlockConditions(root, kRoot)
    visData.box.Color = shouldBlock and Color3.fromRGB(unpack(Config.Block.BoxSafeColor)) or Color3.fromRGB(unpack(Config.Block.BoxDangerColor))
end

function Visual:EnlargeHitbox(hitbox, multiplier)
    if hitbox and hitbox:IsA("BasePart") then
        if not self.ProcessedKillers[hitbox] then
            self.ProcessedKillers[hitbox] = { originalSize = hitbox.Size, originalColor = hitbox.Color }
            hitbox.Size = hitbox.Size * multiplier; hitbox.Color = Color3.fromRGB(255, 255, 255)
            Logger:Add("INFO", "放大 Hitbox: " .. hitbox.Name)
        end
    end
end

function Visual:ResetKillerHitboxes()
    for hitbox, data in pairs(self.ProcessedKillers) do
        if hitbox and hitbox.Parent then hitbox.Size = data.originalSize; hitbox.Color = data.originalColor end
    end
    self.ProcessedKillers = {}
    Logger:Add("INFO", "已重置所有杀手 Hitbox")
end

function Visual:CleanupLocalHitbox()
    if self.LocalConn then self.LocalConn:Disconnect(); self.LocalConn = nil end
    if self.LocalHitbox then self.LocalHitbox:Destroy(); self.LocalHitbox = nil end
end

function Visual:CreateLocalHitbox()
    self:CleanupLocalHitbox()
    if not Config.Visual.LocalHitbox then return end
    local hitboxesFolder = WS:FindFirstChild("Hitboxes")
    if not hitboxesFolder then hitboxesFolder = Instance.new("Folder"); hitboxesFolder.Name = "Hitboxes"; hitboxesFolder.Parent = WS end
    self.LocalHitbox = Instance.new("Part"); self.LocalHitbox.Name = "XD_LocalHitbox"
    self.LocalHitbox.Size = Vector3.new(4.8, 8, 5); self.LocalHitbox.Anchored = true
    self.LocalHitbox.CanCollide = false; self.LocalHitbox.Transparency = 0.5
    self.LocalHitbox.Material = Enum.Material.ForceField; self.LocalHitbox.Color = Color3.fromRGB(255, 255, 200)
    self.LocalHitbox.Parent = hitboxesFolder
    self.LocalConn = RunService.RenderStepped:Connect(function()
        local char = LP.Character
        if char and char:FindFirstChild("HumanoidRootPart") and self.LocalHitbox then
            local root = char.HumanoidRootPart
            local offset = root.CFrame.LookVector * 4
            self.LocalHitbox.CFrame = CFrame.new(root.Position + offset, root.Position + root.CFrame.LookVector)
        end
    end)
    Logger:Add("INFO", "已创建本地 Hitbox 可视化")
end

-- ============================================================
-- 10. 主循环与 Hook
-- ============================================================
AddConnection(RunService.Heartbeat:Connect(function()
    local root = myRoot()
    if not root then return end
    if Config.Visual.EnlargeHitbox then
        local killerNames = {}
        local kf = getKillersFolder()
        if kf then for _, k in ipairs(kf:GetChildren()) do local p = Players:GetPlayerFromCharacter(k); table.insert(killerNames, p and p.Name or k.Name) end end
        local hitboxesFolder = WS:FindFirstChild("Hitboxes")
        if hitboxesFolder then
            for _, child in ipairs(hitboxesFolder:GetChildren()) do
                if child:IsA("BasePart") and string.find(child.Name, "Hitbox") then
                    for _, kName in ipairs(killerNames) do
                        if string.find(child.Name, kName) then Visual:EnlargeHitbox(child, Config.Visual.HitboxMultiplier); break end
                    end
                end
            end
        end
    end
    for killer, visData in pairs(Visual.Boxes) do
        if killer:FindFirstChild("HumanoidRootPart") then pcall(function() Visual:UpdateBoxVisualization(visData, root) end) end
    end
    if Config.Block.Enabled then
        local kf = getKillersFolder()
        if kf then
            for _, killer in ipairs(kf:GetChildren()) do
                local kRoot = killer:FindFirstChild("HumanoidRootPart")
                if kRoot and CheckAllBlockConditions(root, kRoot) then FireBlockRemote() end
            end
        end
    end
end))

AddConnection(RunService.RenderStepped:Connect(function()
    Aimbot:Update()
    Backstab:Update()
end))

for _, d in ipairs(WS:GetDescendants()) do
    if d:IsA("Sound") then BlockModule:HookSound(d) end
    if d:IsA("Animator") then BlockModule:HookAnimator(d) end
end
AddConnection(WS.DescendantAdded:Connect(function(d)
    if d:IsA("Sound") then BlockModule:HookSound(d) end
    if d:IsA("Animator") then BlockModule:HookAnimator(d) end
end))

AddConnection(RunService.RenderStepped:Connect(function()
    if not Config.Block.Enabled then return end
    local kf = getKillersFolder()
    if kf then for _, m in ipairs(kf:GetChildren()) do if m:IsA("Model") and m:FindFirstChild("HumanoidRootPart") then Visual:CreateBoxVisualization(m) end end end
end))

LP.CharacterAdded:Connect(function()
    task.wait(1)
    Aimbot:HookChanceAnim()
    if Config.Visual.LocalHitbox then Visual:CreateLocalHitbox() end
    Logger:Add("INFO", "角色重生，模块重新初始化")
end)
if LP.Character then Aimbot:HookChanceAnim() end
if Config.Visual.LocalHitbox then Visual:CreateLocalHitbox() end

-- ============================================================
-- 11. UI 构建
-- ============================================================
local HomeGroup = Tabs.Main:AddLeftGroupbox("欢迎使用 XD Ultimate", "home")
HomeGroup:AddLabel("脚本名: XD Ultimate v3.0")
HomeGroup:AddLabel("架构: 模块化插件系统")
HomeGroup:AddLabel("机制: 真实碰撞盒 + 底层封包")

local BlockGroup = Tabs.Block:AddLeftGroupbox("主开关", "shield")
BlockGroup:AddToggle("AutoBlock", { Text = "启用自动格挡", Default = Config.Block.Enabled, Callback = function(v) Config.Block.Enabled = v; Logger:Add("INFO", "自动格挡: " .. tostring(v)); SaveConfig() end })
BlockGroup:AddToggle("FacingCheck", { Text = "杀手面向检测", Default = Config.Block.FacingCheck, Callback = function(v) Config.Block.FacingCheck = v; SaveConfig() end })
BlockGroup:AddSlider("FacingAngle", { Text = "杀手面向角度", Default = Config.Block.FacingAngle, Min = 30, Max = 180, Rounding = 1, Callback = function(v) Config.Block.FacingAngle = v; SaveConfig() end })
BlockGroup:AddToggle("WallCheck", { Text = "穿墙检测", Default = Config.Block.WallCheck, Callback = function(v) Config.Block.WallCheck = v; SaveConfig() end })

local BoxGroup = Tabs.Block:AddRightGroupbox("碰撞盒设置", "box")
BoxGroup:AddSlider("BoxScale", { Text = "整体缩放", Default = Config.Block.BoxScale, Min = 0.5, Max = 2, Rounding = 2, Callback = function(v) Config.Block.BoxScale = v; SaveConfig() end })
BoxGroup:AddSlider("BoxForwardOffset", { Text = "前后偏移", Default = Config.Block.BoxForwardOffset, Min = -10, Max = 10, Rounding = 1, Callback = function(v) Config.Block.BoxForwardOffset = v; SaveConfig() end })
BoxGroup:AddSlider("BoxTransparency", { Text = "透明度", Default = Config.Block.BoxTransparency, Min = 0, Max = 1, Rounding = 2, Callback = function(v) Config.Block.BoxTransparency = v; SaveConfig() end })

local AdjustLeft = Tabs.Adjust:AddLeftGroupbox("模式预设", "sliders")
local AdjustRight = Tabs.Adjust:AddRightGroupbox("参数微调", "settings")
local Presets = {
    ["伪装"] = { Delay = 0.18, Note = "【伪装模式】：模拟人类的平均反应速度。\n如果你不想被看出来，请使用此模式。" },
    ["普通"] = { Delay = 0.10, Note = "【普通模式】：略微快速的反应。\n如果你比较大胆，觉得稍微快一点也没关系，可以使用此模式。" },
    ["暴力"] = { Delay = 0.02, Note = "【暴力模式】：极速反应。\n仅限测试使用，如不想账号被重点关注，请勿长期开启。" }
}
local noteLabel = AdjustLeft:AddLabel({ Text = Presets[Config.Preset].Note, DoesWrap = true })
AdjustLeft:AddDropdown("PresetMode", { Text = "选择反应速度", Values = {"伪装", "普通", "暴力"}, Default = Config.Preset, Callback = function(v)
    Config.Preset = v; Config.Block.Cooldown = Presets[v].Delay; SaveConfig()
    if noteLabel and noteLabel.SetText then noteLabel:SetText(Presets[v].Note) elseif noteLabel and noteLabel.TextLabel then noteLabel.TextLabel.Text = Presets[v].Note end
    if Library.Options and Library.Options.Cooldown then Library.Options.Cooldown:SetValue(Presets[v].Delay) end
end })
AdjustRight:AddSlider("Cooldown", { Text = "封包冷却 (秒)", Default = Config.Block.Cooldown, Min = 0.02, Max = 1, Rounding = 2, Callback = function(v) Config.Block.Cooldown = v; SaveConfig() end })

local VisualGroup = Tabs.Visual:AddLeftGroupbox("Hitbox 视觉", "eye")
VisualGroup:AddToggle("EnlargeHitbox", { Text = "放大杀手 Hitbox", Default = Config.Visual.EnlargeHitbox, Callback = function(v) Config.Visual.EnlargeHitbox = v; if not v then Visual:ResetKillerHitboxes() end; SaveConfig() end })
VisualGroup:AddSlider("HitboxMultiplier", { Text = "放大倍数", Default = Config.Visual.HitboxMultiplier, Min = 1, Max = 10, Rounding = 1, Callback = function(v) Config.Visual.HitboxMultiplier = v; SaveConfig() end })
VisualGroup:AddToggle("LocalHitbox", { Text = "显示自身 Hitbox", Default = Config.Visual.LocalHitbox, Callback = function(v) Config.Visual.LocalHitbox = v; if v then Visual:CreateLocalHitbox() else Visual:CleanupLocalHitbox() end; SaveConfig() end })

local AimGroup = Tabs.Aimbot:AddLeftGroupbox("机会专属 (Chance)", "crosshair")
AimGroup:AddToggle("ChanceAimbot", { Text = "开枪自动瞄准杀手", Default = Config.Aimbot.ChanceEnabled, Callback = function(v) Config.Aimbot.ChanceEnabled = v; Logger:Add("INFO", "机会自瞄: " .. tostring(v)); SaveConfig() end })
AimGroup:AddSlider("AimDistance", { Text = "自瞄最大距离", Default = Config.Aimbot.Distance, Min = 20, Max = 300, Rounding = 0, Callback = function(v) Config.Aimbot.Distance = v; SaveConfig() end })
AimGroup:AddDropdown("AimMode", { Text = "自瞄模式", Values = {"Camera", "Character"}, Default = Config.Aimbot.AimMode, Callback = function(v) Config.Aimbot.AimMode = v; SaveConfig() end })

local BackstabGroup = Tabs.Backstab:AddLeftGroupbox("两次专属 (Two Time)", "sword")
BackstabGroup:AddToggle("TwoTimeBackstab", { Text = "启用自动背刺", Default = Config.Backstab.Enabled, Callback = function(v) Config.Backstab.Enabled = v; Logger:Add("INFO", "两次背刺: " .. tostring(v)); SaveConfig() end })
BackstabGroup:AddSlider("BackstabDistance", { Text = "背刺触发距离 (格)", Default = Config.Backstab.Distance, Min = 2, Max = 20, Rounding = 1, Callback = function(v) Config.Backstab.Distance = v; SaveConfig() end })

local UtilGroup = Tabs.Utility:AddLeftGroupbox("实用功能", "wrench")
UtilGroup:AddToggle("InfiniteStamina", { Text = "无限体力", Default = Config.Utility.InfiniteStamina, Callback = function(v) Config.Utility.InfiniteStamina = v; Stamina:Apply(); SaveConfig() end })
UtilGroup:AddToggle("NoStaminaLoss", { Text = "奔跑不消耗体力", Default = Config.Utility.NoStaminaLoss, Callback = function(v) Config.Utility.NoStaminaLoss = v; Stamina:Apply(); SaveConfig() end })
UtilGroup:AddToggle("ShowChat", { Text = "显示聊天框", Default = Config.Visual.ShowChat, Callback = function(v) Chat:Toggle(v); SaveConfig() end })

local SettingsGroup = Tabs.Settings:AddLeftGroupbox("配置管理", "settings")
SettingsGroup:AddButton({ Text = "保存配置", Func = function() SaveConfig(); Notify("设置", "配置已保存") end })
SettingsGroup:AddButton({ Text = "重置配置", Func = function()
    Config.Block.Enabled = false; Config.Aimbot.ChanceEnabled = false; Config.Backstab.Enabled = false
    Config.Utility.InfiniteStamina = false; Config.Utility.NoStaminaLoss = false
    Config.Visual.EnlargeHitbox = false; Config.Visual.LocalHitbox = false; Config.Visual.ShowChat = false
    Visual:ResetKillerHitboxes(); Visual:CleanupLocalHitbox(); SaveConfig(); Notify("设置", "配置已重置")
end })
SettingsGroup:AddButton({ Text = "卸载脚本", Func = function()
    if getgenv().XD_Connections then for _, conn in ipairs(getgenv().XD_Connections) do pcall(function() conn:Disconnect() end) end end
    Visual:ResetKillerHitboxes(); Visual:CleanupLocalHitbox(); if Chat.Conn then Chat.Conn:Disconnect() end
    Logger:Add("INFO", "脚本已卸载"); Library:Unload()
end })

-- ============================================================
-- 12. 启动
-- ============================================================
Logger:Add("INFO", "XD Ultimate v3.0 已加载")
Logger:Add("INFO", "模块初始化完成: Block, Aimbot, Backstab, Visual, Chat, Stamina")
Notify("XD Ultimate", "v3.0 已加载 | 所有模块就绪", 5)
