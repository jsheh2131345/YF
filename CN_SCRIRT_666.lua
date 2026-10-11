-- ========================================
-- CN SCRIRT
-- 作者：我已经绷住了
-- 适配：被遗弃
-- 版本：1.1
-- 功能：按钮式自动格挡 + 透视 + 无限体力 + 可视化
-- ========================================

local repo = 'https://cdn.jsdelivr.net/gh/deividcomsono/Obsidian@main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

Library.ShowToggleFrameInKeybinds = true
Library.ShowCustomCursor = true
Library.NotifySide = "Right"

local Window = Library:CreateWindow({
    Title = 'CN SCRIRT',
    Footer = "我已经绷住了",
    Icon = "rbxassetid://4483362748",
    Center = true,
    AutoShow = true,
    Resizable = true,
    ShowCustomCursor = true,
    NotifySide = "Right",
    TabPadding = 8,
    MenuFadeTime = 0
})

local Tabs = {
    Main = Window:AddTab('功能', 'house'),
    Info = Window:AddTab('信息', 'info'),
    ["UI设置"] = Window:AddTab('UI设置', 'settings')
}

local player = game:GetService("Players").LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")
local hum = char:WaitForChild("Humanoid")
local ws = game:GetService("Workspace")
local rs = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- ============================================
-- 自动格挡（按钮式）
-- ============================================
local BlockGroup = Tabs.Main:AddLeftGroupbox("自动格挡 [Auto Block]")

local BlockSettings = {
    Enabled = false,
    TriggerDistance = 20,
    ShowRangeVisual = false,
    FacingCheck = true,
}

local AttackSoundIDs = {
    ["112809109188560"] = true, ["102228729296384"] = true, ["80516583309685"] = true,
    ["111261564982886"] = true, ["75467546215199"] = true, ["80919153988550"] = true,
    ["86451559088289"] = true, ["140242176732868"] = true, ["136323728355613"] = true,
    ["115026634746636"] = true, ["84116622032112"] = true, ["108907358619313"] = true,
    ["127793641088496"] = true, ["86174610237192"] = true, ["95079963655241"] = true,
    ["101199185291628"] = true, ["119942598489800"] = true, ["84307400688050"] = true,
    ["113037804008732"] = true, ["105200830849301"] = true, ["75330693422988"] = true,
    ["82221759983649"] = true, ["81702359653578"] = true, ["108610718831698"] = true,
    ["112395455254818"] = true, ["109431876587852"] = true, ["109348678063422"] = true,
    ["85853080745515"] = true, ["90819435118493"] = true, ["117173212095661"] = true,
    ["100321250424257"] = true, ["77100821793542"] = true, ["81989261113189"] = true,
    ["129108619555351"] = true, ["119583605486352"] = true, ["79980897195554"] = true,
    ["110877859670130"] = true, ["104910828105172"] = true, ["110126546193799"] = true,
    ["104388455240670"] = true, ["85544168523099"] = true, ["103736328206432"] = true,
    ["128307808203038"] = true, ["111104117703814"] = true, ["97100466324703"] = true,
    ["74000375845213"] = true, ["111502315377475"] = true, ["84340345572285"] = true,
    ["120394605928086"] = true, ["134973085112081"] = true, ["79554277951408"] = true,
    ["115476331903507"] = true, ["18885940850"] = true, ["18885937766"] = true,
}

local AttackAnimIDs = {
    ["126830014841198"] = true, ["126355327951215"] = true, ["121086746534252"] = true,
    ["101736016625776"] = true, ["18885909645"] = true, ["98456918873918"] = true,
    ["18885937766"] = true, ["18885940850"] = true, ["105458270463374"] = true,
    ["106538427162796"] = true, ["139835501033932"] = true, ["126896426760253"] = true,
    ["114356208094580"] = true, ["135884061951801"] = true, ["83829782357897"] = true,
    ["99050723653468"] = true, ["119181003138006"] = true, ["122709416391891"] = true,
    ["87989533095285"] = true, ["133363345661032"] = true, ["128414736976503"] = true,
    ["139309647473555"] = true, ["88451353906104"] = true, ["91628732643385"] = true,
    ["115403107018365"] = true, ["124619925708292"] = true,
}

local RangeVisual = nil
local function UpdateRangeVisual()
    if RangeVisual then RangeVisual:Destroy(); RangeVisual = nil end
    if not BlockSettings.ShowRangeVisual or not player.Character then return end
    local r = player.Character:FindFirstChild("HumanoidRootPart")
    if not r then return end
    local part = Instance.new("Part")
    part.Name = "BlockRangeVisual"
    part.Shape = Enum.PartType.Ball
    part.Size = Vector3.new(BlockSettings.TriggerDistance * 2, 1, BlockSettings.TriggerDistance * 2)
    part.Color = Color3.fromRGB(255, 50, 50)
    part.Material = Enum.Material.ForceField
    part.Transparency = 0.7
    part.Anchored = false
    part.CanCollide = false
    part.CFrame = r.CFrame
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = r
    weld.Part1 = part
    weld.Parent = part
    part.Parent = r
    RangeVisual = part
end

local function getBlockButton()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local main = pg:FindFirstChild("MainUI")
    if not main then return nil end
    local container = main:FindFirstChild("AbilityContainer")
    if not container then return nil end
    return container:FindFirstChild("Block") or container:FindFirstChild("Guard")
end

local function pressBlock()
    local btn = getBlockButton()
    if not btn then return false end
    pcall(function() btn:Activate() end)
    pcall(function()
        for _, conn in ipairs(getconnections(btn.MouseButton1Click) or {}) do
            conn:Fire()
        end
    end)
    return true
end

local function isKillerFacingPlayer(killerRoot)
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot or not killerRoot then return false end
    local toPlayer = (myRoot.Position - killerRoot.Position).Unit
    local killerLook = killerRoot.CFrame.LookVector
    local dot = killerLook:Dot(toPlayer)
    local angle = math.deg(math.acos(math.clamp(dot, -1, 1)))
    return angle <= 85
end

local soundHooks = {}
local soundBlockedUntil = {}
local animConns = {}
local animBlockedUntil = {}

local function getSoundIdNumber(sound)
    local sid = tostring(sound.SoundId)
    return sid:match("%d+")
end

local function getKillerRootFromSound(sound)
    local soundModel = sound.Parent
    while soundModel and not soundModel:IsA("Model") do
        soundModel = soundModel.Parent
    end
    if soundModel then
        return soundModel:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function attemptBlockFromSound(sound)
    if not BlockSettings.Enabled then return end
    if not sound or not sound:IsA("Sound") or not sound.IsPlaying then return end

    local id = getSoundIdNumber(sound)
    if not id or not AttackSoundIDs[id] then return end

    local t = tick()
    if soundBlockedUntil[sound] and t < soundBlockedUntil[sound] then return end

    local blockBtn = getBlockButton()
    if blockBtn then
        local cd = blockBtn:FindFirstChild("CooldownTime")
        if cd and cd.Text ~= "" then return end
    end

    local myChar = player.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local killerRoot = getKillerRootFromSound(sound)
    if killerRoot then
        if (killerRoot.Position - myRoot.Position).Magnitude > BlockSettings.TriggerDistance then return end
        if BlockSettings.FacingCheck and not isKillerFacingPlayer(killerRoot) then return end
    end

    pressBlock()
    soundBlockedUntil[sound] = t + 0.1
end

local function hookSound(sound)
    if not sound:IsA("Sound") or soundHooks[sound] then return end

    local playedConn = sound.Played:Connect(function()
        pcall(attemptBlockFromSound, sound)
    end)
    local propConn = sound:GetPropertyChangedSignal("IsPlaying"):Connect(function()
        if sound.IsPlaying then pcall(attemptBlockFromSound, sound) end
    end)
    local destroyConn = sound.Destroying:Connect(function()
        playedConn:Disconnect()
        propConn:Disconnect()
        destroyConn:Disconnect()
        soundHooks[sound] = nil
        soundBlockedUntil[sound] = nil
    end)

    soundHooks[sound] = {playedConn, propConn, destroyConn}

    if sound.IsPlaying then
        task.spawn(function() pcall(attemptBlockFromSound, sound) end)
    end
end

local function watchKillerAnimations(killerModel)
    if animConns[killerModel] then return end
    local h = killerModel:FindFirstChildOfClass("Humanoid")
    if not h then return end
    local animator = h:FindFirstChildOfClass("Animator")
    if not animator then return end

    local conn = animator.AnimationPlayed:Connect(function(track)
        if not BlockSettings.Enabled then return end

        local animId = track.Animation.AnimationId:match("%d+")
        if not animId or not AttackAnimIDs[animId] then return end

        local t = tick()
        if animBlockedUntil[killerModel] and t < animBlockedUntil[killerModel] then return end

        local blockBtn = getBlockButton()
        if blockBtn then
            local cd = blockBtn:FindFirstChild("CooldownTime")
            if cd and cd.Text ~= "" then return end
        end

        local myChar = player.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end

        local killerRoot = killerModel:FindFirstChild("HumanoidRootPart")
        if killerRoot then
            if (killerRoot.Position - myRoot.Position).Magnitude > BlockSettings.TriggerDistance then return end
            if BlockSettings.FacingCheck and not isKillerFacingPlayer(killerRoot) then return end
        end

        pressBlock()
        animBlockedUntil[killerModel] = t + 0.1
    end)

    animConns[killerModel] = conn
    killerModel.AncestryChanged:Connect(function()
        if not killerModel.Parent then
            if animConns[killerModel] then
                animConns[killerModel]:Disconnect()
                animConns[killerModel] = nil
            end
            animBlockedUntil[killerModel] = nil
        end
    end)
end

local function bindExistingKillers()
    local killersFolder = ws:FindFirstChild("Players") and ws.Players:FindFirstChild("Killers")
    if not killersFolder then return end
    for _, model in ipairs(killersFolder:GetChildren()) do
        if model:IsA("Model") then watchKillerAnimations(model) end
    end
end

local killersFolder = ws:FindFirstChild("Players") and ws.Players:FindFirstChild("Killers")
if killersFolder then
    killersFolder.ChildAdded:Connect(function(model)
        if model:IsA("Model") then
            task.wait(0.5)
            watchKillerAnimations(model)
        end
    end)
    bindExistingKillers()
end

player.CharacterAdded:Connect(function()
    task.wait(1)
    bindExistingKillers()
    if BlockSettings.ShowRangeVisual then UpdateRangeVisual() end
end)

for _, sound in ipairs(ws:GetDescendants()) do
    if sound:IsA("Sound") then pcall(hookSound, sound) end
end
ws.DescendantAdded:Connect(function(obj)
    if obj:IsA("Sound") then pcall(hookSound, obj) end
end)

RunService.RenderStepped:Connect(function()
    if RangeVisual and RangeVisual.Parent then
        local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if r then RangeVisual.CFrame = r.CFrame end
    end
end)

BlockGroup:AddToggle("AutoBlockToggle", {
    Text = "启用自动格挡",
    Default = false,
    Callback = function(s)
        BlockSettings.Enabled = s
        Library:Notify({Title="Auto Block", Description = s and "已开启" or "已关闭", Time=1})
    end
})

BlockGroup:AddSlider("TriggerDistance", {
    Text = "触发距离",
    Default = 20, Min = 5, Max = 50, Rounding = 0,
    Callback = function(v)
        BlockSettings.TriggerDistance = v
        UpdateRangeVisual()
    end,
})

BlockGroup:AddToggle("FacingCheck", {
    Text = "杀手面向检测",
    Default = true,
    Callback = function(s) BlockSettings.FacingCheck = s end,
})

BlockGroup:AddToggle("ShowRangeVisual", {
    Text = "显示触发范围",
    Default = false,
    Callback = function(s)
        BlockSettings.ShowRangeVisual = s
        UpdateRangeVisual()
    end,
})

-- ============================================
-- 无限体力（Feng-Yu 同款）
-- ============================================
local StaminaModule = nil
local StaminaDefaults = nil

local function GetStaminaModule()
    if StaminaModule then return StaminaModule end
    local ok, module = pcall(function()
        return require(rs:WaitForChild("Systems")
            :WaitForChild("Character")
            :WaitForChild("Game")
            :WaitForChild("Sprinting"))
    end)
    if ok and module then
        StaminaModule = module
        if not StaminaDefaults then
            StaminaDefaults = {
                MaxStamina = module.MaxStamina,
                StaminaGain = module.StaminaGain,
                StaminaLoss = module.StaminaLoss,
                SprintSpeed = module.SprintSpeed,
            }
        end
        return module
    end
    return nil
end

local StaminaEnabled = false
local StaminaRunning = nil

local function applyInfiniteStamina()
    if not StaminaEnabled then
        if StaminaRunning then
            task.cancel(StaminaRunning)
            StaminaRunning = nil
        end
        local m = GetStaminaModule()
        if m and StaminaDefaults then
            pcall(function()
                m.StaminaLoss = StaminaDefaults.StaminaLoss
                m.StaminaGain = StaminaDefaults.StaminaGain
            end)
        end
        return
    end
    if StaminaRunning then return end
    StaminaRunning = task.spawn(function()
        while StaminaEnabled do
            pcall(function()
                local m = GetStaminaModule()
                if m then
                    m.StaminaLoss = 0
                    m.StaminaGain = 9999
                end
            end)
            task.wait(0.1)
        end
    end)
end

-- ============================================
-- 透视 ESP
-- ============================================
local espHighlights = {}
local espEnabled = false

local function createESP(plr)
    if plr == player then return end
    if espHighlights[plr] then return end
    local c = plr.Character
    if not c then return end
    local h = Instance.new("Highlight")
    h.Name = "CN_ESP"
    h.FillColor = Color3.fromRGB(255, 100, 100)
    h.OutlineColor = Color3.fromRGB(255, 255, 255)
    h.FillTransparency = 0.5
    h.OutlineTransparency = 0
    h.Adornee = c
    h.Parent = c
    espHighlights[plr] = h
end

local function removeESP(plr)
    if espHighlights[plr] then
        espHighlights[plr]:Destroy()
        espHighlights[plr] = nil
    end
end

local function startESP()
    espEnabled = true
    for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
end

local function stopESP()
    espEnabled = false
    for _, h in pairs(espHighlights) do h:Destroy() end
    espHighlights = {}
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.5)
        if espEnabled then createESP(p) end
    end)
    if espEnabled then createESP(p) end
end)
Players.PlayerRemoving:Connect(removeESP)

local MiscGroup = Tabs.Main:AddRightGroupbox("其他功能")

MiscGroup:AddToggle("StaminaToggle", {
    Text = "无限体力",
    Default = false,
    Callback = function(v)
        StaminaEnabled = v
        pcall(applyInfiniteStamina)
    end,
})

MiscGroup:AddToggle("ESPToggle", {
    Text = "透视（高亮所有玩家）",
    Default = false,
    Callback = function(v)
        if v then startESP() else stopESP() end
    end,
})

-- ============================================
-- 信息
-- ============================================
local Info = Tabs.Info:AddLeftGroupbox("版本信息")
Info:AddLabel("版本: 1.1")
Info:AddLabel("作者: 我已经绷住了")
Info:AddLabel("适配: 被遗弃")
Info:AddLabel("状态: 💚 稳定")

local UIGroup = Tabs["UI设置"]:AddLeftGroupbox("UI设置")
UIGroup:AddButton({
    Text = "关闭窗口",
    Callback = function() Window:Close() end,
})

ThemeManager:SetTheme("Dark")
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
ThemeManager:SetLibrary(Library)
SaveManager:Load()
