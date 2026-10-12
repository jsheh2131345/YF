-- ========================================
-- CN SCRIRT
-- 作者：我已经绷住了
-- 适配：被遗弃
-- 版本：1.4
-- 功能：自动格挡 + 出拳自瞄 + Anti系列 + 透视 + 无限体力
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
    Main = Window:AddTab('主功能', 'house'),
    Punch = Window:AddTab('出拳', 'hand'),
    Anti = Window:AddTab('免疫', 'shield'),
    Info = Window:AddTab('信息', 'info'),
    ["UI设置"] = Window:AddTab('UI设置', 'settings')
}

local player = game:GetService("Players").LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local ws = game:GetService("Workspace")
local rs = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- ============================================
-- 自动格挡设置
-- ============================================
local BlockSettings = {
    Enabled = false,
    TriggerDistance = 20,
    ShowRangeVisual = false,
    FacingCheck = true,
    WallCheck = true,
    BlockDelay = 0.02,
    RandomDelay = false,
    RandomRange = 0.05,
}

local AttackSoundIDs = {
    ["12222216"] = true, ["71805956520207"] = true, ["71834552297085"] = true,
    ["72425554233832"] = true, ["75330693422988"] = true, ["76467993976301"] = true,
    ["76959687420003"] = true, ["77245770579014"] = true, ["78298577002481"] = true,
    ["79391273191671"] = true, ["79980897195554"] = true, ["80516583309685"] = true,
    ["81702359653578"] = true, ["82221759983649"] = true, ["84116622032112"] = true,
    ["84307400688050"] = true, ["85810983952228"] = true, ["85853080745515"] = true,
    ["86174610237192"] = true, ["86494585504534"] = true, ["86833981571073"] = true,
    ["89004992452376"] = true, ["89315669689903"] = true, ["90878551190839"] = true,
    ["94043596324983"] = true, ["95079963655241"] = true, ["97894923442490"] = true,
    ["98675142200448"] = true, ["99829427721752"] = true, ["101199185291628"] = true,
    ["101553872555606"] = true, ["101698569375359"] = true, ["102228729296384"] = true,
    ["103684883268194"] = true, ["104910828105172"] = true, ["105200830849301"] = true,
    ["105840448036441"] = true, ["106300477136129"] = true, ["107444859834748"] = true,
    ["108610718831698"] = true, ["108907358619313"] = true, ["109348678063422"] = true,
    ["109431876587852"] = true, ["110115912768379"] = true, ["110372418055226"] = true,
    ["112395455254818"] = true, ["112809109188560"] = true, ["113037804008732"] = true,
    ["114742322778642"] = true, ["115026634746636"] = true, ["116581754553533"] = true,
    ["117173212095661"] = true, ["117231507259853"] = true, ["119089145505438"] = true,
    ["119583605486352"] = true, ["119942598489800"] = true, ["121954639447247"] = true,
    ["124330645976935"] = true, ["124397369810639"] = true, ["124903763333174"] = true,
    ["125213046326879"] = true, ["127793641088496"] = true, ["128856426573270"] = true,
    ["131123355704017"] = true, ["131406927389838"] = true, ["135448067174226"] = true,
    ["136323728355613"] = true, ["136841625231863"] = true, ["140242176732868"] = true,
    ["128367348686124"] = true, ["116527305931161"] = true,
    ["111261564982886"] = true, ["75467546215199"] = true, ["80919153988550"] = true,
    ["86451559088289"] = true, ["90819435118493"] = true, ["100321250424257"] = true,
    ["77100821793542"] = true, ["81989261113189"] = true, ["129108619555351"] = true,
    ["110877859670130"] = true, ["110126546193799"] = true, ["104388455240670"] = true,
    ["85544168523099"] = true, ["103736328206432"] = true, ["128307808203038"] = true,
    ["111104117703814"] = true, ["97100466324703"] = true, ["74000375845213"] = true,
    ["111502315377475"] = true, ["84340345572285"] = true, ["120394605928086"] = true,
    ["134973085112081"] = true, ["79554277951408"] = true, ["115476331903507"] = true,
    ["18885940850"] = true, ["18885937766"] = true,
}

local AttackAnimIDs = {
    ["18885909645"] = true, ["70371667919898"] = true, ["70447634862911"] = true,
    ["99135633258223"] = true, ["74707328554358"] = true, ["81299297965542"] = true,
    ["81639435858902"] = true, ["82113744478546"] = true, ["83251433279852"] = true,
    ["83685305553364"] = true, ["83829782357897"] = true, ["86204001129974"] = true,
    ["87989533095285"] = true, ["88451353906104"] = true, ["88970503168421"] = true,
    ["92173139187970"] = true, ["93069721274110"] = true, ["94162446513587"] = true,
    ["96571077893813"] = true, ["97167027849946"] = true, ["97433060861952"] = true,
    ["98456918873918"] = true, ["99829427721752"] = true, ["100592913030351"] = true,
    ["105458270463374"] = true, ["106538427162796"] = true, ["106776364623742"] = true,
    ["106847695270773"] = true, ["109230267448394"] = true, ["109667959938617"] = true,
    ["114356208094580"] = true, ["114506382930939"] = true, ["118298475669935"] = true,
    ["120112897026015"] = true, ["121086746534252"] = true, ["121293883585738"] = true,
    ["122709416391891"] = true, ["124705663396411"] = true, ["125403313786645"] = true,
    ["126171487400618"] = true, ["126355327951215"] = true, ["126681776859538"] = true,
    ["126830014841198"] = true, ["126896426760253"] = true, ["128414736976503"] = true,
    ["129976080405072"] = true, ["131430497821198"] = true, ["131543461321709"] = true,
    ["133336594357903"] = true, ["133363345661032"] = true, ["137314737492715"] = true,
    ["138938529389204"] = true, ["139309647473555"] = true, ["139835501033932"] = true,
    ["109700476007435"] = true, ["93366464803829"] = true, ["98590570796574"] = true,
    ["101736016625776"] = true, ["18885937766"] = true, ["18885940850"] = true,
    ["135884061951801"] = true, ["99050723653468"] = true, ["119181003138006"] = true,
    ["91628732643385"] = true, ["115403107018365"] = true, ["124619925708292"] = true,
}

local function getBlockButton()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local main = pg:FindFirstChild("MainUI")
    if not main then return nil end
    local container = main:FindFirstChild("AbilityContainer")
    if not container then return nil end
    return container:FindFirstChild("Block") or container:FindFirstChild("Guard")
end

local function getBlockDelay()
    if BlockSettings.RandomDelay then
        local offset = (math.random() * 2 - 1) * BlockSettings.RandomRange
        return math.clamp(BlockSettings.BlockDelay + offset, 0, 1.0)
    end
    return math.clamp(BlockSettings.BlockDelay, 0, 1.0)
end

local function executeBlock()
    local btn = getBlockButton()
    if not btn then return false end
    local cd = btn:FindFirstChild("CooldownTime")
    if cd and cd.Text ~= "" then return false end
    pcall(function() btn:Activate() end)
    pcall(function()
        for _, conn in ipairs(getconnections(btn.MouseButton1Click) or {}) do
            conn:Fire()
        end
    end)
    return true
end

local pendingBlock = nil
local function pressBlock()
    if pendingBlock then
        task.cancel(pendingBlock)
        pendingBlock = nil
    end
    local d = getBlockDelay()
    if d <= 0.01 then
        executeBlock()
    else
        pendingBlock = task.delay(d, function()
            executeBlock()
            pendingBlock = nil
        end)
    end
end

local function isKillerFacingPlayer(killerRoot)
    if not BlockSettings.FacingCheck then return true end
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot or not killerRoot then return false end
    local toPlayer = (myRoot.Position - killerRoot.Position).Unit
    local killerLook = killerRoot.CFrame.LookVector
    local dot = killerLook:Dot(toPlayer)
    local angle = math.deg(math.acos(math.clamp(dot, -1, 1)))
    return angle <= 85
end

local function hasLineOfSight(killerRoot)
    if not BlockSettings.WallCheck then return true end
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot or not killerRoot then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    params.FilterDescendantsInstances = {player.Character}
    local result = ws:Raycast(myRoot.Position, killerRoot.Position - myRoot.Position, params)
    return not result or result.Instance:IsDescendantOf(killerRoot.Parent)
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

    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local killerRoot = getKillerRootFromSound(sound)
    if killerRoot then
        if (killerRoot.Position - myRoot.Position).Magnitude > BlockSettings.TriggerDistance then return end
        if not isKillerFacingPlayer(killerRoot) then return end
        if not hasLineOfSight(killerRoot) then return end
    end

    pressBlock()
    soundBlockedUntil[sound] = t + 0.05
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

        local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end

        local killerRoot = killerModel:FindFirstChild("HumanoidRootPart")
        if killerRoot then
            if (killerRoot.Position - myRoot.Position).Magnitude > BlockSettings.TriggerDistance then return end
            if not isKillerFacingPlayer(killerRoot) then return end
            if not hasLineOfSight(killerRoot) then return end
        end

        pressBlock()
        animBlockedUntil[killerModel] = t + 0.05
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
end)

for _, sound in ipairs(ws:GetDescendants()) do
    if sound:IsA("Sound") then pcall(hookSound, sound) end
end
ws.DescendantAdded:Connect(function(obj)
    if obj:IsA("Sound") then pcall(hookSound, obj) end
end)
-- ============================================
-- 出拳自瞄（Guest 1337）
-- ============================================
local PunchSettings = {
    AutoPunch = false,
    AutoAim = true,
    AimMode = "Character",
    AimSpeed = 0.5,
    Range = 15,
    Visible = false,
}

local punchAura = nil
local punchRunning = false
local punchConn = nil

local function getPunchButton()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local main = pg:FindFirstChild("MainUI")
    if not main then return nil end
    local container = main:FindFirstChild("AbilityContainer")
    if not container then return nil end
    return container:FindFirstChild("Punch") or container:FindFirstChild("Attack")
end

local function doPunch()
    local btn = getPunchButton()
    if not btn then return false end
    local charges = btn:FindFirstChild("Charges")
    if charges then
        local c = tonumber(charges.Text) or 0
        if c < 1 then return false end
    end
    pcall(function() btn:Activate() end)
    pcall(function()
        for _, conn in ipairs(getconnections(btn.MouseButton1Click) or {}) do
            conn:Fire()
        end
    end)
    return true
end

local function getNearestKiller()
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local killersFolder = ws:FindFirstChild("Players") and ws.Players:FindFirstChild("Killers")
    if not killersFolder then return nil end
    local best, bestDist = nil, math.huge
    for _, k in ipairs(killersFolder:GetChildren()) do
        local hrp = k:FindFirstChild("HumanoidRootPart")
        local h = k:FindFirstChildOfClass("Humanoid")
        if hrp and h and h.Health > 0 then
            local d = (hrp.Position - myRoot.Position).Magnitude
            if d < bestDist and d <= PunchSettings.Range then
                bestDist = d
                best = hrp
            end
        end
    end
    return best
end

local function createPunchAura()
    if punchAura then punchAura:Destroy() end
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local part = Instance.new("Part")
    part.Name = "CN_PunchAura"
    part.Shape = Enum.PartType.Ball
    part.Size = Vector3.new(PunchSettings.Range * 2, PunchSettings.Range * 2, PunchSettings.Range * 2)
    part.Color = Color3.fromRGB(255, 100, 255)
    part.Material = Enum.Material.ForceField
    part.Transparency = 0.85
    part.Anchored = true
    part.CanCollide = false
    part.Parent = ws
    punchAura = part
end

local function updatePunchAura()
    if not punchAura or not punchAura.Parent then return end
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if myRoot then
        punchAura.CFrame = myRoot.CFrame
        punchAura.Size = Vector3.new(PunchSettings.Range * 2, PunchSettings.Range * 2, PunchSettings.Range * 2)
    end
end

local function startPunch()
    if punchRunning then return end
    punchRunning = true

    punchConn = RunService.RenderStepped:Connect(function()
        if not PunchSettings.AutoPunch then return end

        local target = getNearestKiller()

        if target and PunchSettings.AutoAim then
            local myChar = player.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myRoot then
                local cam = ws.CurrentCamera
                if PunchSettings.AimMode == "Character" then
                    local lerpCF = CFrame.lookAt(myRoot.Position, Vector3.new(target.Position.X, myRoot.Position.Y, target.Position.Z))
                    myRoot.CFrame = myRoot.CFrame:Lerp(lerpCF, PunchSettings.AimSpeed)
                elseif PunchSettings.AimMode == "Camera" and cam then
                    local camLook = CFrame.lookAt(cam.CFrame.Position, target.Position)
                    cam.CFrame = cam.CFrame:Lerp(camLook, PunchSettings.AimSpeed)
                else
                    local lerpCF = CFrame.lookAt(myRoot.Position, Vector3.new(target.Position.X, myRoot.Position.Y, target.Position.Z))
                    myRoot.CFrame = myRoot.CFrame:Lerp(lerpCF, PunchSettings.AimSpeed)
                    if cam then
                        local camLook = CFrame.lookAt(cam.CFrame.Position, target.Position)
                        cam.CFrame = cam.CFrame:Lerp(camLook, PunchSettings.AimSpeed)
                    end
                end
            end
        end

        if target then
            doPunch()
        end
    end)

    if PunchSettings.Visible then
        createPunchAura()
    end
end

local function stopPunch()
    punchRunning = false
    if punchConn then
        punchConn:Disconnect()
        punchConn = nil
    end
    if punchAura then
        punchAura:Destroy()
        punchAura = nil
    end
end

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
-- Anti 系列
-- ============================================
local AntiSettings = {
    AntiSlow = false,
    AntiStun = false,
    AntiAcid = false,
    AntiJohnDoeTrap = false,
    AntiJohnDoeTrail = false,
}

local antiConns = {}

local function startAntiSlow()
    if antiConns.AntiSlow then return end
    antiConns.AntiSlow = RunService.Heartbeat:Connect(function()
        if not AntiSettings.AntiSlow then return end
        local c = player.Character
        if not c then return end
        local sm = c:FindFirstChild("SpeedMultipliers")
        if sm then
            for _, v in ipairs(sm:GetChildren()) do
                if v:IsA("NumberValue") and v.Value < 1 then
                    v.Value = 1
                end
            end
        end
    end)
end

local function stopAntiSlow()
    if antiConns.AntiSlow then
        antiConns.AntiSlow:Disconnect()
        antiConns.AntiSlow = nil
    end
end

local function startAntiStun()
    if antiConns.AntiStun then return end
    antiConns.AntiStun = RunService.Heartbeat:Connect(function()
        if not AntiSettings.AntiStun then return end
        local c = player.Character
        if not c then return end
        local sm = c:FindFirstChild("SpeedMultipliers")
        if sm then
            local stun = sm:FindFirstChild("Stunned")
            if stun then stun.Value = 1 end
        end
    end)
end

local function stopAntiStun()
    if antiConns.AntiStun then
        antiConns.AntiStun:Disconnect()
        antiConns.AntiStun = nil
    end
end

local function startAntiAcid()
    if antiConns.AntiAcid then return end
    antiConns.AntiAcid = task.spawn(function()
        while AntiSettings.AntiAcid do
            pcall(function()
                local map = ws:FindFirstChild("Map")
                local ingame = map and map:FindFirstChild("Ingame")
                local innerMap = ingame and ingame:FindFirstChild("Map")
                if innerMap then
                    for _, v in ipairs(innerMap:GetChildren()) do
                        if v.Name == "AcidContainer" then
                            for _, acid in ipairs(v:GetChildren()) do
                                if acid:IsA("BasePart") then
                                    acid.CanTouch = false
                                end
                            end
                        end
                    end
                end
            end)
            task.wait(0.5)
        end
    end)
end

local function stopAntiAcid()
    if antiConns.AntiAcid then
        task.cancel(antiConns.AntiAcid)
        antiConns.AntiAcid = nil
    end
end

local function startAntiJohnDoeTrap()
    if antiConns.AntiJohnDoeTrap then return end
    antiConns.AntiJohnDoeTrap = task.spawn(function()
        while AntiSettings.AntiJohnDoeTrap do
            pcall(function()
                local map = ws:FindFirstChild("Map")
                local ingame = map and map:FindFirstChild("Ingame")
                if ingame then
                    for _, obj in ipairs(ingame:GetChildren()) do
                        if obj:IsA("Model") and obj.Name:lower():find("trap") then
                            for _, p in ipairs(obj:GetDescendants()) do
                                if p:IsA("BasePart") then p.CanTouch = false end
                            end
                        end
                    end
                end
            end)
            task.wait(0.5)
        end
    end)
end

local function stopAntiJohnDoeTrap()
    if antiConns.AntiJohnDoeTrap then
        task.cancel(antiConns.AntiJohnDoeTrap)
        antiConns.AntiJohnDoeTrap = nil
    end
end

local function startAntiJohnDoeTrail()
    if antiConns.AntiJohnDoeTrail then return end
    antiConns.AntiJohnDoeTrail = task.spawn(function()
        while AntiSettings.AntiJohnDoeTrail do
            pcall(function()
                local map = ws:FindFirstChild("Map")
                local ingame = map and map:FindFirstChild("Ingame")
                if ingame then
                    for _, obj in ipairs(ingame:GetChildren()) do
                        if obj:IsA("Folder") and obj.Name:find("JohnDoeTrail") then
                            for _, p in ipairs(obj:GetChildren()) do
                                if p:IsA("BasePart") then p.CanTouch = false end
                            end
                        end
                    end
                end
            end)
            task.wait(0.5)
        end
    end)
end

local function stopAntiJohnDoeTrail()
    if antiConns.AntiJohnDoeTrail then
        task.cancel(antiConns.AntiJohnDoeTrail)
        antiConns.AntiJohnDoeTrail = nil
    end
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

-- ============================================
-- 可视化
-- ============================================
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

RunService.RenderStepped:Connect(function()
    if RangeVisual and RangeVisual.Parent then
        local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if r then RangeVisual.CFrame = r.CFrame end
    end
    updatePunchAura()
end)

-- ============================================
-- UI - 主功能
-- ============================================
local BlockGroup = Tabs.Main:AddLeftGroupbox("自动格挡 [Auto Block]")

BlockGroup:AddToggle("AutoBlockToggle", {
    Text = "启用自动格挡",
    Default = false,
    Callback = function(s)
        BlockSettings.Enabled = s
        Library:Notify({Title="Auto Block", Description = s and "已开启" or "已关闭", Time=1})
    end,
})

BlockGroup:AddSlider("TriggerDistance", {
    Text = "触发距离",
    Default = 20, Min = 5, Max = 50, Rounding = 0,
    Callback = function(v)
        BlockSettings.TriggerDistance = v
        UpdateRangeVisual()
    end,
})

BlockGroup:AddSlider("BlockDelaySlider", {
    Text = "格挡延迟 (秒)",
    Default = 0.02, Min = 0, Max = 0.5, Rounding = 2,
    Callback = function(v) BlockSettings.BlockDelay = v end,
})

BlockGroup:AddToggle("RandomDelayToggle", {
    Text = "随机延迟",
    Default = false,
    Callback = function(s) BlockSettings.RandomDelay = s end,
})

BlockGroup:AddSlider("RandomRangeSlider", {
    Text = "随机波动 (秒)",
    Default = 0.05, Min = 0, Max = 0.2, Rounding = 2,
    Callback = function(v) BlockSettings.RandomRange = v end,
})

BlockGroup:AddToggle("FacingCheck", {
    Text = "杀手面向检测 (85°)",
    Default = true,
    Callback = function(s) BlockSettings.FacingCheck = s end,
})

BlockGroup:AddToggle("WallCheck", {
    Text = "穿墙检测 (Wall Check)",
    Default = true,
    Callback = function(s) BlockSettings.WallCheck = s end,
})

BlockGroup:AddToggle("ShowRangeVisual", {
    Text = "显示触发范围",
    Default = false,
    Callback = function(s)
        BlockSettings.ShowRangeVisual = s
        UpdateRangeVisual()
    end,
})

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
-- UI - 出拳
-- ============================================
local PunchGroup = Tabs.Punch:AddLeftGroupbox("出拳自瞄 [Guest 1337 Punch]")

PunchGroup:AddToggle("AutoPunchToggle", {
    Text = "自动出拳",
    Default = false,
    Callback = function(v)
        PunchSettings.AutoPunch = v
        if v then startPunch() else stopPunch() end
    end,
})

PunchGroup:AddToggle("AutoAimToggle", {
    Text = "出拳自瞄",
    Default = true,
    Callback = function(v) PunchSettings.AutoAim = v end,
})

PunchGroup:AddToggle("PunchVisibleToggle", {
    Text = "出拳范围可视化",
    Default = false,
    Callback = function(v)
        PunchSettings.Visible = v
        if v and PunchSettings.AutoPunch then
            createPunchAura()
        elseif punchAura then
            punchAura:Destroy()
            punchAura = nil
        end
    end,
})

PunchGroup:AddSlider("PunchRangeSlider", {
    Text = "出拳范围",
    Default = 15, Min = 1, Max = 50, Rounding = 1,
    Callback = function(v) PunchSettings.Range = v end,
})

PunchGroup:AddDropdown("AimModeDropdown", {
    Text = "自瞄模式",
    Values = {"角色", "相机", "角色+相机"},
    Default = "角色",
    Multi = false,
    Callback = function(v)
        if v == "角色" then PunchSettings.AimMode = "Character"
        elseif v == "相机" then PunchSettings.AimMode = "Camera"
        else PunchSettings.AimMode = "Both" end
    end,
})

PunchGroup:AddSlider("AimSpeedSlider", {
    Text = "自瞄平滑度",
    Default = 0.5, Min = 0.1, Max = 1, Rounding = 2,
    Callback = function(v) PunchSettings.AimSpeed = v end,
})

-- ============================================
-- UI - Anti 系列
-- ============================================
local AntiGroup = Tabs.Anti:AddLeftGroupbox("免疫功能 [Anti Effects]")

AntiGroup:AddToggle("AntiSlowToggle", {
    Text = "防减速 (Anti-Slow)",
    Default = false,
    Callback = function(v)
        AntiSettings.AntiSlow = v
        if v then startAntiSlow() else stopAntiSlow() end
    end,
})

AntiGroup:AddToggle("AntiStunToggle", {
    Text = "防眩晕 (Anti-Stun)",
    Default = false,
    Callback = function(v)
        AntiSettings.AntiStun = v
        if v then startAntiStun() else stopAntiStun() end
    end,
})

AntiGroup:AddToggle("AntiAcidToggle", {
    Text = "防酸液 (Anti-Acid)",
    Default = false,
    Callback = function(v)
        AntiSettings.AntiAcid = v
        if v then startAntiAcid() else stopAntiAcid() end
    end,
})

AntiGroup:AddDivider()

AntiGroup:AddToggle("AntiJohnDoeTrapToggle", {
    Text = "防约翰多陷阱 (Anti-JohnDoe Trap)",
    Default = false,
    Callback = function(v)
        AntiSettings.AntiJohnDoeTrap = v
        if v then startAntiJohnDoeTrap() else stopAntiJohnDoeTrap() end
    end,
})

AntiGroup:AddToggle("AntiJohnDoeTrailToggle", {
    Text = "防约翰多脚气 (Anti-JohnDoe Trail)",
    Default = false,
    Callback = function(v)
        AntiSettings.AntiJohnDoeTrail = v
        if v then startAntiJohnDoeTrail() else stopAntiJohnDoeTrail() end
    end,
})

-- ============================================
-- 信息
-- ============================================
local Info = Tabs.Info:AddLeftGroupbox("版本信息")
Info:AddLabel("版本: 1.4")
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
