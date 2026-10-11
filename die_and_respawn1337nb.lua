-- ========================================
-- die and respawn
-- 作者：我已经绷住了
-- 适配：遗落:沙盒（被遗弃同人）
-- 版本：0.3
-- 功能：自动格挡 + 可视化 + 无限体力 + 透视
-- ========================================

local repo = 'https://cdn.jsdelivr.net/gh/deividcomsono/Obsidian@main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

Library.ShowToggleFrameInKeybinds = true
Library.ShowCustomCursor = true
Library.NotifySide = "Right"

local Window = Library:CreateWindow({
    Title = 'die and respawn',
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

local buffer = buffer or require(rs.Buffer)

local NetworkFolder = rs:WaitForChild("Modules"):WaitForChild("Network")
local RemoteEvent = NetworkFolder:FindFirstChild("RemoteEvent")
if not RemoteEvent then
    RemoteEvent = NetworkFolder:WaitForChild("Network"):WaitForChild("RemoteEvent")
end

-- ============================================
-- 自动格挡 ID 表
-- ============================================
local AutoBlockSounds = {
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
}

local AutoBlockAnims = {
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
}

-- ============================================
-- 状态
-- ============================================
local features = {
    autoBlock = {enabled = false},
    infiniteStamina = {enabled = false, running = nil},
    esp = {enabled = false, highlights = {}},
    visualize = {enabled = false},
}

local AB = {
    SoundHooks = {}, AnimHooks = {},
    SoundBlockedUntil = {}, AnimBlockedUntil = {},
    SoundStartTime = {}, AnimStartTime = {},
    lastBlockTime = 0,
    blockCooldown = 0.2,
    MaxSoundAge = 1.2,
    MaxAnimAge = 1.5,
    SenseRange = 18,
    SenseRangeSq = 18 * 18,
    wallCheckEnabled = false,
    FacingCheckEnabled = false,
    PlayerFacingAngle = 90,
    KillerFacingCheckEnabled = false,
    KillerFacingAngle = 90,
    HDPullEnabled = false,
    HDSpeed = 12,
    pulling = false,
    BlockDelay = 0,
    RandomDelay = false,
    RandomRange = 0.3,
    PendingBlock = nil,
}

-- ============================================
-- 工具
-- ============================================
local function getChar(p) return p and p.Character end
local function getRoot(p)
    local c = getChar(p)
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getMyRoot() return getRoot(player) end

local function executeBlock()
    local now = tick()
    if now - AB.lastBlockTime < AB.blockCooldown then return end
    AB.lastBlockTime = now
    pcall(function()
        RemoteEvent:FireServer("UseActorAbility", {
            buffer.fromstring("\3\5\0\0\0Block")
        })
    end)
end

local function getDelay(baseDelay)
    if AB.RandomDelay then
        local offset = (math.random() * 2 - 1) * AB.RandomRange
        return math.clamp(baseDelay + offset, 0, 5.0)
    end
    return math.clamp(baseDelay, 0, 5.0)
end

local function fireBlock()
    if AB.PendingBlock then
        task.cancel(AB.PendingBlock)
        AB.PendingBlock = nil
    end
    local d = getDelay(AB.BlockDelay)
    if d <= 0.01 then
        executeBlock()
    else
        AB.PendingBlock = task.delay(d, function()
            executeBlock()
            AB.PendingBlock = nil
        end)
    end
end

local function hasLineOfSight(targetRoot)
    if not AB.wallCheckEnabled then return true end
    local myRoot = getMyRoot()
    if not myRoot then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    params.FilterDescendantsInstances = {player.Character}
    local result = ws:Raycast(myRoot.Position, targetRoot.Position - myRoot.Position, params)
    return not result or result.Instance:IsDescendantOf(targetRoot.Parent)
end

local function isPlayerFacingKiller(myRoot, killerRoot)
    if not AB.FacingCheckEnabled then return true end
    local dir = (killerRoot.Position - myRoot.Position)
    local flat = Vector3.new(dir.X, 0, dir.Z).Unit
    local look = Vector3.new(myRoot.CFrame.LookVector.X, 0, myRoot.CFrame.LookVector.Z).Unit
    local angle = math.deg(math.acos(math.clamp(look:Dot(flat), -1, 1)))
    return angle <= AB.PlayerFacingAngle
end

local function isKillerFacingPlayer(myRoot, killerRoot)
    if not AB.KillerFacingCheckEnabled then return true end
    local dir = (myRoot.Position - killerRoot.Position)
    local flat = Vector3.new(dir.X, 0, dir.Z).Unit
    local look = Vector3.new(killerRoot.CFrame.LookVector.X, 0, killerRoot.CFrame.LookVector.Z).Unit
    local angle = math.deg(math.acos(math.clamp(look:Dot(flat), -1, 1)))
    return angle <= AB.KillerFacingAngle
end

local function checkAllBlockConditions(myRoot, killerRoot)
    if not myRoot or not killerRoot then return false end
    local dvec = killerRoot.Position - myRoot.Position
    local distSq = dvec.X^2 + dvec.Y^2 + dvec.Z^2
    if distSq > AB.SenseRangeSq then return false end
    if not isKillerFacingPlayer(myRoot, killerRoot) then return false end
    if not hasLineOfSight(killerRoot) then return false end
    if not isPlayerFacingKiller(myRoot, killerRoot) then return false end
    return true
end

local function getSoundId(snd)
    if not snd or not snd.SoundId then return nil end
    return tostring(snd.SoundId):match("%d+")
end

local function getAnimId(anim)
    if not anim or not anim.AnimationId then return nil end
    return tostring(anim.AnimationId):match("%d+")
end

local function getSoundPosition(snd)
    if not snd then return nil end
    if snd.Parent and snd.Parent:IsA("BasePart") then
        return snd.Parent.Position, snd.Parent
    end
    if snd.Parent and snd.Parent:IsA("Attachment") and snd.Parent.Parent and snd.Parent.Parent:IsA("BasePart") then
        return snd.Parent.Parent.Position, snd.Parent.Parent
    end
    local found = snd.Parent and snd.Parent:FindFirstChildWhichIsA("BasePart", true)
    return found and found.Position, found or nil
end

local function getCharFromDescendant(inst)
    if not inst then return nil end
    local mdl = inst:FindFirstAncestorOfClass("Model")
    return mdl and mdl:FindFirstChildOfClass("Humanoid") and mdl or nil
end

local function canUseBlock()
    local gui = player:FindFirstChild("PlayerGui")
    if gui then
        local mainUI = gui:FindFirstChild("MainUI")
        if mainUI then
            local ac = mainUI:FindFirstChild("AbilityContainer")
            if ac then
                local btn = ac:FindFirstChild("Block")
                if btn then
                    local cd = btn:FindFirstChild("CooldownTime")
                    if cd and cd.Text ~= "" then return false end
                end
            end
        end
    end
    return true
end

local function doHDPull(targetPos)
    if AB.pulling or not canUseBlock() then return end
    AB.pulling = true
    local hrp = getMyRoot()
    if not hrp then AB.pulling = false return end
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(50000, 0, 50000)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp
    local startTime = tick()
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not bv.Parent or tick() - startTime > 0.4 then
            if bv.Parent then bv:Destroy() end
            conn:Disconnect()
            AB.pulling = false
            return
        end
        local vec = targetPos - hrp.Position
        if vec.Magnitude < 3 then
            bv:Destroy()
            conn:Disconnect()
            AB.pulling = false
            return
        end
        bv.Velocity = vec.Unit * (AB.HDSpeed * 25)
    end)
end

-- ============================================
-- 可视化圈（只给杀手画）
-- ============================================
local VisualizeFolder = Instance.new("Folder")
VisualizeFolder.Name = "DnR_Visualize"
VisualizeFolder.Parent = ws

local visualCircles = {}

local function createCircleForKiller(killerModel)
    if not killerModel or not killerModel:FindFirstChild("HumanoidRootPart") then return end
    if visualCircles[killerModel] then return end

    local circle = Instance.new("Part")
    circle.Name = "DnR_Circle"
    circle.Shape = Enum.PartType.Cylinder
    circle.Anchored = true
    circle.CanCollide = false
    circle.CastShadow = false
    circle.Material = Enum.Material.Neon
    circle.Color = Color3.fromRGB(255, 0, 0)
    circle.Transparency = 0.7
    circle.Size = Vector3.new(0.1, AB.SenseRange * 2, AB.SenseRange * 2)
    circle.Parent = VisualizeFolder

    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not features.visualize.enabled then
            if circle.Parent then circle.Transparency = 1 end
            return
        end
        if not killerModel.Parent or not killerModel:FindFirstChild("HumanoidRootPart") then
            circle:Destroy()
            conn:Disconnect()
            visualCircles[killerModel] = nil
            return
        end

        local myRoot = getMyRoot()
        if not myRoot then return end
        local killerRoot = killerModel.HumanoidRootPart

        circle.Size = Vector3.new(0.1, AB.SenseRange * 2, AB.SenseRange * 2)
        circle.CFrame = CFrame.new(killerRoot.Position - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90))

        local dist = (myRoot.Position - killerRoot.Position).Magnitude
        if dist <= AB.SenseRange then
            circle.Color = Color3.fromRGB(0, 255, 0)
            circle.Transparency = 0.6
        else
            circle.Color = Color3.fromRGB(255, 0, 0)
            circle.Transparency = 0.8
        end
    end)

    visualCircles[killerModel] = {circle = circle, conn = conn}
end

local function refreshVisualize()
    if not features.visualize.enabled then
        for model, data in pairs(visualCircles) do
            if data.circle then data.circle:Destroy() end
            if data.conn then data.conn:Disconnect() end
        end
        visualCircles = {}
        return
    end

    local playersFolder = ws:FindFirstChild("Players")
    if not playersFolder then return end

    local killersFolder = playersFolder:FindFirstChild("Killers")
    if killersFolder then
        for _, m in ipairs(killersFolder:GetChildren()) do
            createCircleForKiller(m)
        end
    end
end

-- 自动监听杀手文件夹变化
task.spawn(function()
    while task.wait(1) do
        if not features.visualize.enabled then continue end
        local playersFolder = ws:FindFirstChild("Players")
        local killersFolder = playersFolder and playersFolder:FindFirstChild("Killers")
        if not killersFolder then continue end
        for _, m in ipairs(killersFolder:GetChildren()) do
            if not visualCircles[m] then
                createCircleForKiller(m)
            end
        end
    end
end)

-- ============================================
-- 自动格挡触发
-- ============================================
local function attemptBlockSound(snd)
    if not features.autoBlock.enabled then return end
    if not snd or not snd:IsA("Sound") or not snd.IsPlaying then return end
    local id = getSoundId(snd)
    if not id or not AutoBlockSounds[id] then return end

    local now = tick()
    if not AB.SoundStartTime[snd] then AB.SoundStartTime[snd] = now end
    if now - AB.SoundStartTime[snd] > AB.MaxSoundAge then return end
    if AB.SoundBlockedUntil[snd] and now < AB.SoundBlockedUntil[snd] then return end

    local myRoot = getMyRoot()
    if not myRoot then return end
    local pos, part = getSoundPosition(snd)
    if not pos or not part then return end
    local c = getCharFromDescendant(part)
    local plr = c and Players:GetPlayerFromCharacter(c)
    if not plr or plr == player then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if not checkAllBlockConditions(myRoot, hrp) then return end

    fireBlock()
    if AB.HDPullEnabled then
        task.spawn(function() doHDPull(hrp.Position) end)
    end
    AB.SoundBlockedUntil[snd] = now + 0.8
end

local function attemptBlockAnim(animTrack)
    if not features.autoBlock.enabled then return end
    if not animTrack or not animTrack.Animation or not animTrack.IsPlaying then return end
    local id = getAnimId(animTrack.Animation)
    if not id or not AutoBlockAnims[id] then return end

    local now = tick()
    if not AB.AnimStartTime[animTrack] then AB.AnimStartTime[animTrack] = now end
    if now - AB.AnimStartTime[animTrack] > AB.MaxAnimAge then return end
    if AB.AnimBlockedUntil[animTrack] and now < AB.AnimBlockedUntil[animTrack] then return end

    local myRoot = getMyRoot()
    if not myRoot then return end
    local animator = animTrack.Parent
    if not animator or not animator:IsA("Animator") then return end
    local c = getCharFromDescendant(animator)
    if not c then return end
    local plr = Players:GetPlayerFromCharacter(c)
    if not plr or plr == player then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if not checkAllBlockConditions(myRoot, hrp) then return end

    fireBlock()
    if AB.HDPullEnabled then
        task.spawn(function() doHDPull(hrp.Position) end)
    end
    AB.AnimBlockedUntil[animTrack] = now + 0.8
end

local function hookSound(snd)
    if not snd or not snd:IsA("Sound") or AB.SoundHooks[snd] then return end
    local c1 = snd.Played:Connect(function()
        AB.SoundStartTime[snd] = tick()
        task.defer(attemptBlockSound, snd)
    end)
    local c2 = snd:GetPropertyChangedSignal("IsPlaying"):Connect(function()
        if snd.IsPlaying then
            if not AB.SoundStartTime[snd] then AB.SoundStartTime[snd] = tick() end
            task.defer(attemptBlockSound, snd)
        else
            AB.SoundStartTime[snd] = nil
        end
    end)
    local c3
    c3 = snd.Destroying:Connect(function()
        c1:Disconnect(); c2:Disconnect(); c3:Disconnect()
        AB.SoundHooks[snd] = nil
        AB.SoundBlockedUntil[snd] = nil
        AB.SoundStartTime[snd] = nil
    end)
    AB.SoundHooks[snd] = {c1, c2, c3}
    if snd.IsPlaying then
        AB.SoundStartTime[snd] = tick()
        task.defer(attemptBlockSound, snd)
    end
end

local function hookAnimator(animator)
    if not animator or not animator:IsA("Animator") then return end
    animator.AnimationPlayed:Connect(function(animTrack)
        pcall(function()
            AB.AnimStartTime[animTrack] = tick()
            local c = animTrack:GetPropertyChangedSignal("IsPlaying"):Connect(function()
                if animTrack.IsPlaying then
                    if not AB.AnimStartTime[animTrack] then AB.AnimStartTime[animTrack] = tick() end
                    task.defer(attemptBlockAnim, animTrack)
                else
                    AB.AnimStartTime[animTrack] = nil
                end
            end)
            animTrack.Stopped:Connect(function()
                if c.Connected then c:Disconnect() end
                AB.AnimBlockedUntil[animTrack] = nil
                AB.AnimStartTime[animTrack] = nil
            end)
            if animTrack.IsPlaying then
                task.defer(attemptBlockAnim, animTrack)
            end
        end)
    end)
end

local function startAutoBlock()
    for _, d in ipairs(game:GetDescendants()) do
        if d:IsA("Sound") then pcall(hookSound, d) end
        if d:IsA("Animator") then pcall(hookAnimator, d) end
    end
    game.DescendantAdded:Connect(function(d)
        if d:IsA("Sound") then task.defer(hookSound, d) end
        if d:IsA("Animator") then task.defer(hookAnimator, d) end
    end)
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

local function applyInfiniteStamina()
    if not features.infiniteStamina.enabled then
        if features.infiniteStamina.running then
            task.cancel(features.infiniteStamina.running)
            features.infiniteStamina.running = nil
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
    if features.infiniteStamina.running then return end
    features.infiniteStamina.running = task.spawn(function()
        while features.infiniteStamina.enabled do
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
local function createESP(plr)
    if plr == player then return end
    if features.esp.highlights[plr] then return end
    local c = plr.Character
    if not c then return end
    local h = Instance.new("Highlight")
    h.Name = "DnR_ESP"
    h.FillColor = Color3.fromRGB(255, 100, 100)
    h.OutlineColor = Color3.fromRGB(255, 255, 255)
    h.FillTransparency = 0.5
    h.OutlineTransparency = 0
    h.Adornee = c
    h.Parent = c
    features.esp.highlights[plr] = h
end

local function removeESP(plr)
    if features.esp.highlights[plr] then
        features.esp.highlights[plr]:Destroy()
        features.esp.highlights[plr] = nil
    end
end

local function startESP()
    for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
    Players.PlayerAdded:Connect(createESP)
    Players.PlayerRemoving:Connect(removeESP)
end

local function stopESP()
    for _, h in pairs(features.esp.highlights) do h:Destroy() end
    features.esp.highlights = {}
end

-- ============================================
-- UI - 核心功能
-- ============================================
local Main = Tabs.Main:AddLeftGroupbox("核心功能")

Main:AddToggle("AutoBlockToggle", {
    Text = "自动格挡",
    Default = false,
    Callback = function(v)
        features.autoBlock.enabled = v
        if v then startAutoBlock() end
    end,
})

Main:AddToggle("StaminaToggle", {
    Text = "无限体力",
    Default = false,
    Callback = function(v)
        features.infiniteStamina.enabled = v
        pcall(applyInfiniteStamina)
    end,
})

Main:AddToggle("ESPToggle", {
    Text = "透视（高亮所有玩家）",
    Default = false,
    Callback = function(v)
        features.esp.enabled = v
        if v then startESP() else stopESP() end
    end,
})

-- ============================================
-- 格挡设置
-- ============================================
local BlockGroup = Tabs.Main:AddRightGroupbox("格挡设置")

BlockGroup:AddToggle("WallCheckToggle", {
    Text = "穿墙检测", Default = false,
    Callback = function(v) AB.wallCheckEnabled = v end,
})

BlockGroup:AddToggle("FacingCheckToggle", {
    Text = "玩家面向检测", Default = false,
    Callback = function(v) AB.FacingCheckEnabled = v end,
})

BlockGroup:AddSlider("PlayerFacingSlider", {
    Text = "玩家面向角度", Min = 30, Max = 180, Default = 90, Rounding = 1,
    Callback = function(v) AB.PlayerFacingAngle = v end,
})

BlockGroup:AddToggle("KillerFacingToggle", {
    Text = "杀手面向检测", Default = false,
    Callback = function(v) AB.KillerFacingCheckEnabled = v end,
})

BlockGroup:AddSlider("KillerFacingSlider", {
    Text = "杀手面向角度", Min = 30, Max = 180, Default = 90, Rounding = 1,
    Callback = function(v) AB.KillerFacingAngle = v end,
})

BlockGroup:AddSlider("SenseRangeSlider", {
    Text = "格挡范围", Min = 5, Max = 50, Default = 18, Rounding = 1,
    Callback = function(v)
        AB.SenseRange = v
        AB.SenseRangeSq = v * v
        refreshVisualize()
    end,
})

BlockGroup:AddToggle("HDPullToggle", {
    Text = "格挡拉近（HDPull）", Default = false,
    Callback = function(v) AB.HDPullEnabled = v end,
})

BlockGroup:AddSlider("HDSpeedSlider", {
    Text = "拉近速度", Min = 5, Max = 50, Default = 12, Rounding = 1,
    Callback = function(v) AB.HDSpeed = v end,
})

BlockGroup:AddSlider("BlockDelaySlider", {
    Text = "格挡延迟 (秒)", Min = 0, Max = 5, Default = 0, Rounding = 2,
    Callback = function(v) AB.BlockDelay = v end,
})

BlockGroup:AddToggle("RandomDelayToggle", {
    Text = "随机延迟", Default = false,
    Callback = function(v) AB.RandomDelay = v end,
})

BlockGroup:AddSlider("RandomRangeSlider", {
    Text = "随机波动范围 (秒)", Min = 0, Max = 1, Default = 0.3, Rounding = 2,
    Callback = function(v) AB.RandomRange = v end,
})

BlockGroup:AddToggle("VisualizeToggle", {
    Text = "显示格挡范围（仅杀手）", Default = false,
    Callback = function(v)
        features.visualize.enabled = v
        refreshVisualize()
    end,
})

-- ============================================
-- 信息
-- ============================================
local Info = Tabs.Info:AddLeftGroupbox("版本信息")
Info:AddLabel("版本: 0.3")
Info:AddLabel("作者: 我已经绷住了")
Info:AddLabel("适配: 遗落:沙盒")
Info:AddLabel("状态: 💚 稳定")

-- ============================================
-- UI 设置
-- ============================================
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
