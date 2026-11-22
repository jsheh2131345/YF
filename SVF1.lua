-- ============================================================
-- XD - 终极完全体 (真实碰撞盒 + 发包格挡 + Hitbox视觉)
-- ============================================================

local Players    = game:GetService("Players")
local LP         = Players.LocalPlayer
local PlayerGui  = LP:WaitForChild("PlayerGui")
local RS         = game:GetService("ReplicatedStorage")
local WS         = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")

-- 清理旧连接
if getgenv().XD_Connections then
    for _, conn in ipairs(getgenv().XD_Connections) do
        pcall(function() conn:Disconnect() end)
    end
end
getgenv().XD_Connections = {}

-- ============================================================
-- 1. UI 库与主题配置
-- ============================================================
local repo = "https://cdn.jsdelivr.net/gh/deividcomsono/Obsidian@main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
Library.ShowCustomCursor = true
Library.NotifySide = "Right"

Library.Theme = {
    Name = "XD Theme",
    AccentColor = Color3.fromRGB(255, 100, 150),
    BackgroundColor = Color3.fromRGB(20, 20, 20),
    OutlineColor = Color3.fromRGB(50, 50, 50),
    FontColor = Color3.fromRGB(230, 230, 230),
    TextDarkTheme = true
}

local Window = Library:CreateWindow({
    Title = "XD - 终极版",
    Footer = "Forsaken | " .. LP.Name,
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
    Settings  = Window:AddTab("设置", "settings"),
}

local function notify(t, d) pcall(function() Library:Notify({Title=t, Description=d, Time=3}) end) end

-- ============================================================
-- 2. 核心配置
-- ============================================================
local Settings = {
    Enabled = false,
    TriggerRadius = 20,
    BoxLingerTime = 1.0,
    IsFlashing = false,
    BlockDelay = 0.02,
    Cooldown = 0.2,
    ShowBox = true,
    FacingCheck = false,
    WallCheck = false,
    KillerFacingAngle = 90,
    BoxScale = 1.0,
    BoxForwardOffset = 4,
    BoxTransparency = 0.5,
    BoxSafeColor = {0, 255, 0},
    BoxDangerColor = {255, 0, 0},
    MaxSoundAge = 1.2,
    MaxAnimAge = 1.5,
    PresetMode = "普通",
    InfiniteStamina = false,
    NoStaminaLoss = false,
    ChanceAimbot = false,
    ChanceAimDistance = 100,
    ChanceAimSmoothness = 0.8,
    TwoTimeBackstab = false,
    TwoTimeDistance = 8,
    TwoTimeKey = Enum.KeyCode.E,
    -- Hitbox视觉
    EnlargeHitbox = false,
    HitboxMultiplier = 3,
    LocalHitboxVisual = false,
}

local CONFIG_FILE = "XD_Config.json"
local function saveConfig() pcall(function() if writefile then writefile(CONFIG_FILE, game:GetService("HttpService"):JSONEncode(Settings)) end end) end
local function loadConfig()
    local ok, data = pcall(function()
        if readfile and isfile and isfile(CONFIG_FILE) then return game:GetService("HttpService"):JSONDecode(readfile(CONFIG_FILE)) end
        return nil
    end)
    if ok and data then for k, v in pairs(data) do if Settings[k] ~= nil then Settings[k] = v end end end
end
loadConfig()

local RemoteEvent = RS:WaitForChild("Modules"):WaitForChild("Network"):WaitForChild("RemoteEvent")
local lastBlockTime = 0
local function FireBlockRemote()
    local now = tick()
    if now - lastBlockTime < Settings.Cooldown then return false end
    lastBlockTime = now
    local args = {"UseActorAbility", {buffer.fromstring("\3\5\0\0\0Block")}}
    pcall(function() RemoteEvent:FireServer(unpack(args)) end)
    return true
end

-- ============================================================
-- 3. 完整 ID 库
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
-- 4. 判定工具函数
-- ============================================================
local function myRoot() local c = LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function getKillersFolder() local pf = WS:FindFirstChild("Players"); return pf and pf:FindFirstChild("Killers") end

local function GetBoxSize() return Vector3.new(4.8 * Settings.BoxScale, 8 * Settings.BoxScale, 5 * Settings.BoxScale) end

local function IsKillerFacingPlayer(root, kRoot)
    if not Settings.FacingCheck then return true end
    if not root or not kRoot then return false end
    local dir = (root.Position - kRoot.Position)
    local flat = Vector3.new(dir.X, 0, dir.Z).Unit
    local look = Vector3.new(kRoot.CFrame.LookVector.X, 0, kRoot.CFrame.LookVector.Z).Unit
    local dot = look:Dot(flat)
    local angle = math.deg(math.acos(math.clamp(dot, -1, 1)))
    return angle <= Settings.KillerFacingAngle
end

local function HasLineOfSight(targetRoot)
    if not Settings.WallCheck then return true end
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
    local boxPos = kRoot.Position + forward * Settings.BoxForwardOffset
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
-- 5. 视觉框与 Hitbox 功能
-- ============================================================
local BoxVisualizations = {}
local processedHitboxes = {}
local LocalHitboxPart = nil
local LocalHitboxConnection = nil

-- 杀手碰撞盒
local function CreateBoxVisualization(killer)
    if not killer or not killer:FindFirstChild("HumanoidRootPart") then return end
    if BoxVisualizations[killer] then return end
    local folder = Instance.new("Folder")
    folder.Name = "XD_BoxVisual"
    folder.Parent = killer.HumanoidRootPart
    local box = Instance.new("Part")
    box.Name = "DetectionBox"
    box.Material = Enum.Material.ForceField
    box.Anchored = true
    box.CanCollide = false
    box.CanQuery = false
    box.Transparency = Settings.BoxTransparency
    box.Color = Color3.fromRGB(unpack(Settings.BoxDangerColor))
    box.Size = GetBoxSize()
    box.Parent = folder
    BoxVisualizations[killer] = {folder = folder, box = box, killer = killer}
end

local function UpdateBoxVisualization(visData, root)
    if not visData or not visData.folder or not visData.folder.Parent then return end
    if not root or not visData.killer or not visData.killer:FindFirstChild("HumanoidRootPart") then return end
    local kRoot = visData.killer.HumanoidRootPart
    local forward = kRoot.CFrame.LookVector
    local boxPos = kRoot.Position + forward * Settings.BoxForwardOffset
    visData.box.Size = GetBoxSize()
    visData.box.CFrame = CFrame.lookAt(boxPos, boxPos + forward * 100)
    visData.box.Transparency = Settings.BoxTransparency
    local shouldBlock = CheckAllBlockConditions(root, kRoot)
    visData.box.Color = shouldBlock and Color3.fromRGB(unpack(Settings.BoxSafeColor)) or Color3.fromRGB(unpack(Settings.BoxDangerColor))
end

-- 杀手 Hitbox 放大
local function enlargeHitboxFast(hitbox, multiplier)
    if hitbox and hitbox:IsA("BasePart") then
        if not processedHitboxes[hitbox] then
            processedHitboxes[hitbox] = { originalSize = hitbox.Size, originalColor = hitbox.Color }
            hitbox.Size = hitbox.Size * multiplier
            hitbox.Color = Color3.fromRGB(255, 255, 255)
        end
    end
end

local function resetKillerHitboxes()
    for hitbox, originalData in pairs(processedHitboxes) do
        if hitbox and hitbox.Parent then
            hitbox.Size = originalData.originalSize
            hitbox.Color = originalData.originalColor
        end
    end
    processedHitboxes = {}
end

-- 本地玩家 Hitbox 可视化
local function cleanupLocalHitbox()
    if LocalHitboxConnection then
        LocalHitboxConnection:Disconnect()
        LocalHitboxConnection = nil
    end
    if LocalHitboxPart then
        LocalHitboxPart:Destroy()
        LocalHitboxPart = nil
    end
end

local function createLocalHitboxVisual()
    cleanupLocalHitbox()
    if not Settings.LocalHitboxVisual then return end

    local hitboxesFolder = WS:FindFirstChild("Hitboxes")
    if not hitboxesFolder then
        hitboxesFolder = Instance.new("Folder")
        hitboxesFolder.Name = "Hitboxes"
        hitboxesFolder.Parent = WS
    end

    LocalHitboxPart = Instance.new("Part")
    LocalHitboxPart.Name = "XD_LocalHitbox" -- 防止被其他脚本误认
    LocalHitboxPart.Size = Vector3.new(4.8, 8, 5)
    LocalHitboxPart.Anchored = true
    LocalHitboxPart.CanCollide = false
    LocalHitboxPart.Transparency = 0.5
    LocalHitboxPart.Material = Enum.Material.ForceField
    LocalHitboxPart.Color = Color3.fromRGB(255, 255, 200)
    LocalHitboxPart.Parent = hitboxesFolder

    LocalHitboxConnection = RunService.RenderStepped:Connect(function()
        local char = LP.Character
        if char and char:FindFirstChild("HumanoidRootPart") and LocalHitboxPart then
            local root = char.HumanoidRootPart
            local offset = root.CFrame.LookVector * 4
            LocalHitboxPart.CFrame = CFrame.new(root.Position + offset, root.Position + root.CFrame.LookVector)
        end
    end)
end

-- ============================================================
-- 6. 攻击监听与格挡
-- ============================================================
local SoundBlockedUntil = {}
local AnimBlockedUntil = {}
local SoundStartTime = {}
local AnimStartTime = {}

local function AttemptBlockSound(snd)
    if not Settings.Enabled or not snd or not snd:IsA("Sound") or not snd.IsPlaying then return end
    local id = tostring(snd.SoundId):match("%d+")
    if not id or not AttackSoundIDs[id] then return end
    local now = tick()
    if not SoundStartTime[snd] then SoundStartTime[snd] = now end
    if now - SoundStartTime[snd] > Settings.MaxSoundAge then return end
    if SoundBlockedUntil[snd] and now < SoundBlockedUntil[snd] then return end
    local root = myRoot(); if not root then return end
    local parent = snd.Parent
    while parent and not parent:IsA("Model") do parent = parent.Parent end
    if not parent then return end
    local kRoot = parent:FindFirstChild("HumanoidRootPart")
    if kRoot and CheckAllBlockConditions(root, kRoot) then
        if FireBlockRemote() then SoundBlockedUntil[snd] = now + 0.8 end
    end
end

local function AttemptBlockAnim(animTrack)
    if not Settings.Enabled or not animTrack or not animTrack.Animation or not animTrack.IsPlaying then return end
    local id = tostring(animTrack.Animation.AnimationId):match("%d+")
    if not id or not AttackAnimIDs[id] then return end
    local now = tick()
    if not AnimStartTime[animTrack] then AnimStartTime[animTrack] = now end
    if now - AnimStartTime[animTrack] > Settings.MaxAnimAge then return end
    if AnimBlockedUntil[animTrack] and now < AnimBlockedUntil[animTrack] then return end
    local root = myRoot(); if not root then return end
    local parent = animTrack.Parent
    while parent and not parent:IsA("Model") do parent = parent.Parent end
    if not parent then return end
    local kRoot = parent:FindFirstChild("HumanoidRootPart")
    if kRoot and CheckAllBlockConditions(root, kRoot) then
        if FireBlockRemote() then AnimBlockedUntil[animTrack] = now + 0.8 end
    end
end

local hookedSounds = setmetatable({}, {__mode="k"})
local function HookSound(snd)
    if not snd:IsA("Sound") or hookedSounds[snd] then return end
    hookedSounds[snd] = true
    table.insert(getgenv().XD_Connections, snd.Played:Connect(function()
        SoundStartTime[snd] = tick()
        task.defer(AttemptBlockSound, snd)
    end))
    if snd.IsPlaying then SoundStartTime[snd] = tick(); task.defer(AttemptBlockSound, snd) end
end

local hookedAnims = setmetatable({}, {__mode="k"})
local function HookAnimator(animator)
    if not animator:IsA("Animator") or hookedAnims[animator] then return end
    hookedAnims[animator] = true
    table.insert(getgenv().XD_Connections, animator.AnimationPlayed:Connect(function(track)
        AnimStartTime[track] = tick()
        task.defer(AttemptBlockAnim, track)
    end))
end

-- ============================================================
-- 7. 心跳循环
-- ============================================================
table.insert(getgenv().XD_Connections, RunService.Heartbeat:Connect(function()
    local root = myRoot()
    if not root then return end
    
    -- 杀手 Hitbox 放大逻辑
    if Settings.EnlargeHitbox then
        local killerNames = {}
        local kf = getKillersFolder()
        if kf then
            for _, k in ipairs(kf:GetChildren()) do
                local p = Players:GetPlayerFromCharacter(k)
                table.insert(killerNames, p and p.Name or k.Name)
            end
        end
        local hitboxesFolder = WS:FindFirstChild("Hitboxes")
        if hitboxesFolder then
            for _, child in ipairs(hitboxesFolder:GetChildren()) do
                if child:IsA("BasePart") and string.find(child.Name, "Hitbox") then
                    for _, kName in ipairs(killerNames) do
                        if string.find(child.Name, kName) then
                            enlargeHitboxFast(child, Settings.HitboxMultiplier)
                            break
                        end
                    end
                end
            end
        end
    end

    -- 框更新
    for killer, visData in pairs(BoxVisualizations) do
        if killer:FindFirstChild("HumanoidRootPart") then
            pcall(UpdateBoxVisualization, visData, root)
        end
    end
    
    -- 持续检测格挡
    if Settings.Enabled then
        local kf = getKillersFolder()
        if kf then
            for _, killer in ipairs(kf:GetChildren()) do
                local kRoot = killer:FindFirstChild("HumanoidRootPart")
                if kRoot and CheckAllBlockConditions(root, kRoot) then
                    FireBlockRemote()
                end
            end
        end
    end
end))

-- ============================================================
-- 8. 其他功能 (自瞄 / 背刺 / 体力)
-- ============================================================
local ChanceShootAnims = { ["73921036900313"]=true, ["111384272984267"]=true, ["90499469533503"]=true, ["133491532453922"]=true }
local chanceAimTarget, lastAimTime = nil, 0

local function isLocalPlayerChance()
    local char = LP.Character; if not char then return false end
    local surv = WS:FindFirstChild("Players") and WS.Players:FindFirstChild("Survivors")
    if not surv then return false end
    for _, s in ipairs(surv:GetChildren()) do if s == char and s.Name == "Chance" then return true end end
    return false
end

local function hookChanceAnims()
    local char = LP.Character; if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    local animator = hum:FindFirstChildOfClass("Animator"); if not animator then return end
    table.insert(getgenv().XD_Connections, animator.AnimationPlayed:Connect(function(track)
        if not Settings.ChanceAimbot or not isLocalPlayerChance() then return end
        local id = track.Animation and track.Animation.AnimationId:match("%d+")
        if id and ChanceShootAnims[id] then
            local root = myRoot(); local kf = getKillersFolder(); if not root or not kf then return end
            local nearest, minDist = nil, Settings.ChanceAimDistance
            for _, k in ipairs(kf:GetChildren()) do
                if k:IsA("Model") then
                    local hrp = k:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local d = (hrp.Position - root.Position).Magnitude
                        if d < minDist then nearest, minDist = hrp, d end
                    end
                end
            end
            if nearest then chanceAimTarget = nearest; lastAimTime = tick() end
        end
    end))
end

table.insert(getgenv().XD_Connections, RunService.RenderStepped:Connect(function()
    if not Settings.ChanceAimbot or not chanceAimTarget or tick() - lastAimTime > 0.5 or not chanceAimTarget.Parent then return end
    local root = myRoot(); if not root then return end
    local targetCF = CFrame.lookAt(root.Position, Vector3.new(chanceAimTarget.Position.X, root.Position.Y, chanceAimTarget.Position.Z))
    root.CFrame = Settings.ChanceAimSmoothness >= 0.99 and targetCF or root.CFrame:Lerp(targetCF, Settings.ChanceAimSmoothness)
end))

task.spawn(function()
    while task.wait(0.2) do
        if Settings.InfiniteStamina or Settings.NoStaminaLoss then
            pcall(function()
                local systems = RS:FindFirstChild("Systems")
                local sprinting = systems and systems:FindFirstChild("Character") and systems.Character:FindFirstChild("Game") and systems.Character.Game:FindFirstChild("Sprinting")
                if sprinting then
                    local m = require(sprinting)
                    if Settings.InfiniteStamina then m.Stamina = m.MaxStamina end
                    if Settings.InfiniteStamina or Settings.NoStaminaLoss then m.StaminaLoss = 0 end
                end
            end)
        end
    end
end)

-- 两次背刺
local lastBackstabTime = 0
local function isLocalPlayerTwoTime()
    local char = LP.Character; if not char then return false end
    local surv = WS:FindFirstChild("Players") and WS.Players:FindFirstChild("Survivors")
    if not surv then return false end
    for _, s in ipairs(surv:GetChildren()) do if s == char and s.Name == "TwoTime" then return true end end
    return false
end

local beamPart1 = Instance.new("Part"); beamPart1.Anchored = true; beamPart1.CanCollide = false; beamPart1.Transparency = 1; beamPart1.Parent = WS
local beamPart2 = Instance.new("Part"); beamPart2.Anchored = true; beamPart2.CanCollide = false; beamPart2.Transparency = 1; beamPart2.Parent = WS
local backstabBeam = Instance.new("Beam"); backstabBeam.FaceCamera = true; backstabBeam.Width0 = 0.1; backstabBeam.Width1 = 0.1; backstabBeam.LightEmission = 1; backstabBeam.LightInfluence = 0; backstabBeam.Enabled = false; backstabBeam.Parent = beamPart1
local a1 = Instance.new("Attachment", beamPart1); local a2 = Instance.new("Attachment", beamPart2); backstabBeam.Attachment0 = a1; backstabBeam.Attachment1 = a2

table.insert(getgenv().XD_Connections, RunService.RenderStepped:Connect(function()
    backstabBeam.Enabled = false
    if not Settings.TwoTimeBackstab or not isLocalPlayerTwoTime() then return end
    if tick() - lastBackstabTime < 1 then return end
    local root = myRoot(); local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return end
    local kf = getKillersFolder(); if not kf then return end
    local nearestKiller, nearestDist = nil, math.huge
    for _, killer in ipairs(kf:GetChildren()) do
        if killer:IsA("Model") then
            local kRoot = killer:FindFirstChild("HumanoidRootPart")
            local kHum = killer:FindFirstChildOfClass("Humanoid")
            if kRoot and kHum and kHum.Health > 0 then
                local dist = (kRoot.Position - root.Position).Magnitude
                if dist < nearestDist then nearestDist = dist; nearestKiller = killer end
                local dot = kRoot.CFrame.LookVector:Dot((root.Position - kRoot.Position).Unit)
                local isBehind = dot < -0.2
                local inDistance = dist <= Settings.TwoTimeDistance
                if killer == nearestKiller then
                    beamPart1.Position = root.Position; beamPart2.Position = kRoot.Position
                    backstabBeam.Enabled = true
                    backstabBeam.Color = (inDistance and isBehind) and ColorSequence.new(Color3.fromRGB(0, 255, 0)) or ColorSequence.new(Color3.fromRGB(255, 0, 0))
                end
                if inDistance and isBehind and tick() - lastBackstabTime >= 1 then
                    pcall(function() game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game) end)
                    task.wait(0.1)
                    pcall(function()
                        game:GetService("VirtualInputManager"):SendKeyEvent(true, Settings.TwoTimeKey, false, game)
                        task.wait(0.05)
                        game:GetService("VirtualInputManager"):SendKeyEvent(false, Settings.TwoTimeKey, false, game)
                    end)
                    pcall(function() game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game) end)
                    lastBackstabTime = tick()
                    break
                end
            end
        end
    end
end))

-- ============================================================
-- 9. 初始化与 UI
-- ============================================================
for _, d in ipairs(WS:GetDescendants()) do
    if d:IsA("Sound") then HookSound(d) end
    if d:IsA("Animator") then HookAnimator(d) end
end
table.insert(getgenv().XD_Connections, WS.DescendantAdded:Connect(function(d)
    if d:IsA("Sound") then HookSound(d) end
    if d:IsA("Animator") then HookAnimator(d) end
end))

table.insert(getgenv().XD_Connections, RunService.RenderStepped:Connect(function()
    if not Settings.Enabled then return end
    local kf = getKillersFolder()
    if kf then
        for _, m in ipairs(kf:GetChildren()) do
            if m:IsA("Model") and m:FindFirstChild("HumanoidRootPart") then
                CreateBoxVisualization(m)
            end
        end
    end
end))

LP.CharacterAdded:Connect(function()
    task.wait(1)
    hookChanceAnims()
    if Settings.LocalHitboxVisual then createLocalHitboxVisual() end
end)
if LP.Character then hookChanceAnims() end
if Settings.LocalHitboxVisual then createLocalHitboxVisual() end

-- UI 构建
local HomeGroup = Tabs.Main:AddLeftGroupbox("欢迎使用 XD", "home")
HomeGroup:AddLabel("脚本名: XD - 终极完全体")
HomeGroup:AddLabel("机制: 真实碰撞盒，底层封包直接格挡。")

local BlockGroup = Tabs.Block:AddLeftGroupbox("主开关", "shield")
BlockGroup:AddToggle("AutoBlock", { Text = "启用自动格挡", Default = Settings.Enabled, Callback = function(v) Settings.Enabled = v; saveConfig() end })
BlockGroup:AddToggle("FacingCheck", { Text = "杀手面向检测", Default = false, Callback = function(v) Settings.FacingCheck = v; saveConfig() end })
BlockGroup:AddSlider("KillerFacingAngle", { Text = "杀手面向角度", Default = 90, Min = 30, Max = 180, Rounding = 1, Callback = function(v) Settings.KillerFacingAngle = v; saveConfig() end })
BlockGroup:AddToggle("WallCheck", { Text = "穿墙检测", Default = false, Callback = function(v) Settings.WallCheck = v; saveConfig() end })

local BoxGroup = Tabs.Block:AddRightGroupbox("碰撞盒设置", "box")
BoxGroup:AddSlider("BoxScale", { Text = "整体缩放", Default = 1.0, Min = 0.5, Max = 2, Rounding = 2, Callback = function(v) Settings.BoxScale = v; saveConfig() end })
BoxGroup:AddSlider("BoxForwardOffset", { Text = "前后偏移", Default = 4, Min = -10, Max = 10, Rounding = 1, Callback = function(v) Settings.BoxForwardOffset = v; saveConfig() end })
BoxGroup:AddSlider("BoxTransparency", { Text = "透明度", Default = 0.5, Min = 0, Max = 1, Rounding = 2, Callback = function(v) Settings.BoxTransparency = v; saveConfig() end })

local AdjustLeft = Tabs.Adjust:AddLeftGroupbox("模式预设", "sliders")
local AdjustRight = Tabs.Adjust:AddRightGroupbox("参数微调", "settings")
local Presets = {
    ["伪装"] = { Delay = 0.18, Note = "伪装模式：模拟人类的平均反应速度。" },
    ["普通"] = { Delay = 0.10, Note = "普通模式：略微快速的反应。" },
    ["暴力"] = { Delay = 0.02, Note = "暴力模式：极速反应。仅限测试使用。" }
}
AdjustLeft:AddDropdown("PresetMode", { Text = "选择反应速度", Values = {"伪装", "普通", "暴力"}, Default = Settings.PresetMode, Callback = function(v) Settings.PresetMode = v; Settings.Cooldown = Presets[v].Delay; saveConfig() end })
AdjustLeft:AddLabel({ Text = Presets[Settings.PresetMode].Note, DoesWrap = true })
AdjustRight:AddSlider("Cooldown", { Text = "封包冷却 (秒)", Default = 0.2, Min = 0.02, Max = 1, Rounding = 2, Callback = function(v) Settings.Cooldown = v; saveConfig() end })

local VisualGroup = Tabs.Visual:AddLeftGroupbox("Hitbox 视觉", "eye")
VisualGroup:AddToggle("EnlargeHitbox", { Text = "放大杀手 Hitbox", Default = false, Callback = function(v) Settings.EnlargeHitbox = v; saveConfig(); if not v then resetKillerHitboxes() end end })
VisualGroup:AddSlider("HitboxMultiplier", { Text = "放大倍数", Default = 3, Min = 1, Max = 10, Rounding = 1, Callback = function(v) Settings.HitboxMultiplier = v; saveConfig() end })
VisualGroup:AddToggle("LocalHitboxVisual", { Text = "显示自身 Hitbox", Default = false, Callback = function(v) Settings.LocalHitboxVisual = v; saveConfig(); if v then createLocalHitboxVisual() else cleanupLocalHitbox() end end })

local AimGroup = Tabs.Aimbot:AddLeftGroupbox("机会专属 (Chance)", "crosshair")
AimGroup:AddToggle("ChanceAimbot", { Text = "开枪自动瞄准杀手", Default = Settings.ChanceAimbot, Callback = function(v) Settings.ChanceAimbot = v; saveConfig() end })
AimGroup:AddSlider("ChanceAimDistance", { Text = "自瞄最大距离", Default = 100, Min = 20, Max = 300, Rounding = 0, Callback = function(v) Settings.ChanceAimDistance = v; saveConfig() end })

local BackstabGroup = Tabs.Backstab:AddLeftGroupbox("两次专属 (Two Time)", "sword")
BackstabGroup:AddToggle("TwoTimeBackstab", { Text = "启用自动背刺", Default = Settings.TwoTimeBackstab, Callback = function(v) Settings.TwoTimeBackstab = v; saveConfig() end })
BackstabGroup:AddSlider("TwoTimeDistance", { Text = "背刺触发距离 (格)", Default = 8, Min = 2, Max = 20, Rounding = 1, Callback = function(v) Settings.TwoTimeDistance = v; saveConfig() end })

local UtilGroup = Tabs.Utility:AddLeftGroupbox("实用功能", "wrench")
UtilGroup:AddToggle("InfiniteStamina", { Text = "无限体力", Default = Settings.InfiniteStamina, Callback = function(v) Settings.InfiniteStamina = v; saveConfig() end })
UtilGroup:AddToggle("NoStaminaLoss", { Text = "奔跑不消耗体力", Default = Settings.NoStaminaLoss, Callback = function(v) Settings.NoStaminaLoss = v; saveConfig() end })

local SettingsGroup = Tabs.Settings:AddLeftGroupbox("配置管理", "settings")
SettingsGroup:AddButton({ Text = "卸载脚本", Func = function() 
    if getgenv().XD_Connections then
        for _, conn in ipairs(getgenv().XD_Connections) do pcall(function() conn:Disconnect() end) end
    end
    resetKillerHitboxes()
    cleanupLocalHitbox()
    Library:Unload() 
end })

notify("XD", "终极完全体已加载 | 底层发包格挡已就绪")
