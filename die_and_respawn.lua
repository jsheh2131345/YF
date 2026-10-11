-- ========================================
-- die and respawn
-- 作者：我已经绷住了
-- 适配：遗落:沙盒（被遗弃同人）
-- 版本：0.1
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
local uis = game:GetService("UserInputService")
local rs = game:GetService("ReplicatedStorage")
local lighting = game:GetService("Lighting")
local cam = ws.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local buffer = buffer or require(rs.Buffer)
local RemoteEvent = rs:WaitForChild("Modules"):WaitForChild("Network"):WaitForChild("RemoteEvent")

-- ============================================
-- 自动格挡 ID 表（YG 同款）
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
    noStun = {enabled = false},
    speedBoost = {enabled = false, value = 1},
    speed = {enabled = true},
    noclip = {enabled = true, running = nil},
    nightVision = {enabled = true},
    heartbeat = {enabled = true, running = nil},
    infiniteHealth = {enabled = true, running = nil},
    stepFly = {enabled = false, running = nil},
    newFly = {enabled = false, running = nil},
    jumpUnlock = {enabled = false},
    autoFlyUp = {enabled = false, running = nil},
    infiniteStamina = {enabled = false, running = nil},
    speedMultiplier = {enabled = false, value = 1},
    aimbot = {enabled = false, running = nil},
    fullbright = {enabled = false},
    noFog = {enabled = false},
    globalShadows = {enabled = false},
    fov = {enabled = false, value = 70},
    autoBlock = {enabled = false},
    esp = {enabled = false, highlights = {}},
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
-- 自动格挡
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
-- 原有功能
-- ============================================
local function applyNightVision()
    if features.nightVision.enabled then
        lighting.Ambient = Color3.fromRGB(255, 255, 255)
        lighting.Brightness = 2
        lighting.ClockTime = 12
        lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        lighting.GlobalShadows = false
        lighting.FogEnd = 1000
        for _, s in ipairs(lighting:GetDescendants()) do
            if s:IsA("Shadow") or s:IsA("BlurEffect") or s:IsA("BloomEffect") then
                s.Enabled = false
            end
        end
    else
        lighting.Ambient = Color3.fromRGB(0, 0, 0)
        lighting.Brightness = 1
        lighting.ClockTime = 0
        lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
        lighting.GlobalShadows = true
        lighting.FogEnd = 10000
        for _, s in ipairs(lighting:GetDescendants()) do
            if s:IsA("Shadow") or s:IsA("BlurEffect") or s:IsA("BloomEffect") then
                s.Enabled = true
            end
        end
    end
end

local function applyFullbright()
    if features.fullbright.enabled then
        lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        lighting.Brightness = 2
        lighting.GlobalShadows = not features.globalShadows.enabled
        if features.noFog.enabled then
            lighting.FogStart = 0
            lighting.FogEnd = math.huge
            local fog = lighting:FindFirstChildOfClass("Atmosphere")
            if fog then fog.Density = 0 end
        end
    else
        lighting.OutdoorAmbient = Color3.fromRGB(55, 55, 55)
        lighting.Brightness = 0
        lighting.GlobalShadows = true
    end
end

local function applySpeed()
    if features.speed.enabled then
        hum.WalkSpeed = 80
        hum.JumpPower = 150
    else
        hum.WalkSpeed = 16
        hum.JumpPower = 50
    end
end

local function applyNoclip()
    if not features.noclip.enabled then
        if features.noclip.running then
            task.cancel(features.noclip.running)
            features.noclip.running = nil
        end
        if root then root.CanCollide = true end
        return
    end
    if features.noclip.running then return end
    features.noclip.running = task.spawn(function()
        while features.noclip.enabled do
            if char and root then
                root.CanCollide = false
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
            task.wait(0.15)
        end
    end)
end

local function applyHeartbeat()
    if not features.heartbeat.enabled then
        if features.heartbeat.running then task.cancel(features.heartbeat.running); features.heartbeat.running = nil end
        return
    end
    if features.heartbeat.running then return end
    features.heartbeat.running = task.spawn(function()
        while features.heartbeat.enabled do
            pcall(function()
                local h = char:FindFirstChild("心跳") or char:FindFirstChild("心率") or char:FindFirstChild("恐惧值") or char:FindFirstChild("压力值")
                if h and (h:IsA("NumberValue") or h:IsA("IntValue")) and h.Value > 99999 then h.Value = 99999 end
                local ph = player:FindFirstChild("心跳") or player:FindFirstChild("心率") or player:FindFirstChild("恐惧值")
                if ph and (ph:IsA("NumberValue") or ph:IsA("IntValue")) and ph.Value > 99999 then ph.Value = 99999 end
            end)
            task.wait(0.05)
        end
    end)
end

local function applyInfiniteHealth()
    if not features.infiniteHealth.enabled then
        if features.infiniteHealth.running then task.cancel(features.infiniteHealth.running); features.infiniteHealth.running = nil end
        return
    end
    if features.infiniteHealth.running then return end
    features.infiniteHealth.running = task.spawn(function()
        while features.infiniteHealth.enabled do
            pcall(function()
                if hum then
                    hum.Health = hum.MaxHealth
                    hum.BreakJointsOnDeath = false
                end
            end)
            task.wait(0.05)
        end
    end)
end

local function applyInfiniteStamina()
    if not features.infiniteStamina.enabled then
        if features.infiniteStamina.running then task.cancel(features.infiniteStamina.running); features.infiniteStamina.running = nil end
        return
    end
    if features.infiniteStamina.running then return end
    features.infiniteStamina.running = task.spawn(function()
        while features.infiniteStamina.enabled do
            pcall(function()
                local st = char:FindFirstChild("体力值") or char:FindFirstChild("体力") or char:FindFirstChild("耐力值") or char:FindFirstChild("Stamina")
                if st and (st:IsA("NumberValue") or st:IsA("IntValue")) then st.Value = 100 end
                local pst = player:FindFirstChild("体力值") or player:FindFirstChild("体力") or player:FindFirstChild("Stamina")
                if pst and (pst:IsA("NumberValue") or pst:IsA("IntValue")) then pst.Value = 100 end
            end)
            task.wait(0.05)
        end
    end)
end

local function applySpeedMultiplier()
    if not features.speedMultiplier.enabled then
        hum.WalkSpeed = 16
        return
    end
    local mult = features.speedMultiplier.value or 1
    hum.WalkSpeed = 16 * mult
    if hum.WalkSpeed > 800 then hum.WalkSpeed = 800 end
end

local function applyAimbot()
    if not features.aimbot.enabled then
        if features.aimbot.running then task.cancel(features.aimbot.running); features.aimbot.running = nil end
        return
    end
    if features.aimbot.running then return end
    features.aimbot.running = task.spawn(function()
        while features.aimbot.enabled do
            pcall(function()
                local near, nearDist = nil, math.huge
                local killers = ws:FindFirstChild("Players") and ws.Players:FindFirstChild("Killers")
                if killers then
                    for _, k in ipairs(killers:GetChildren()) do
                        local hrp = k:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local d = (root.Position - hrp.Position).Magnitude
                            if d < nearDist then nearDist = d; near = hrp end
                        end
                    end
                end
                if near and nearDist < 50 then
                    cam.CFrame = CFrame.new(cam.CFrame.Position, near.Position - Vector3.new(0, 0.5, 0))
                end
            end)
            task.wait()
        end
    end)
end

local function applyStepFly()
    if not features.stepFly.enabled then
        if features.stepFly.running then task.cancel(features.stepFly.running); features.stepFly.running = nil end
        return
    end
    if features.stepFly.running then return end
    features.stepFly.running = task.spawn(function()
        while features.stepFly.enabled do
            pcall(function()
                if root then
                    local v = root.Velocity
                    if v.Y < 0 then root.Velocity = Vector3.new(v.X, 0, v.Z) end
                end
            end)
            task.wait()
        end
    end)
end

local function applyAutoFlyUp()
    if not features.autoFlyUp.enabled then
        if features.autoFlyUp.running then task.cancel(features.autoFlyUp.running); features.autoFlyUp.running = nil end
        return
    end
    if features.autoFlyUp.running then return end
    features.autoFlyUp.running = task.spawn(function()
        while features.autoFlyUp.enabled do
            pcall(function()
                if root and cam then
                    local look = cam.CFrame.LookVector
                    if look.Y > 0.5 then
                        root.Velocity = Vector3.new(root.Velocity.X, look.Y * 30, root.Velocity.Z)
                    end
                end
            end)
            task.wait()
        end
    end)
end

local function applyNewFly()
    if not features.newFly.enabled then
        if features.newFly.running then task.cancel(features.newFly.running); features.newFly.running = nil end
        if hum then hum.PlatformStand = false end
        return
    end
    if features.newFly.running then return end
    if not char then return end
    local r = root
    if not r then return end
    hum.PlatformStand = true
    local bv = Instance.new("BodyVelocity")
    bv.Parent = r
    bv.MaxForce = Vector3.new(4000, 4000, 4000)
    bv.Velocity = Vector3.new(0, 0, 0)
    features.newFly.running = task.spawn(function()
        while features.newFly.enabled and r do
            local fwd = cam.CFrame.LookVector
            local right = cam.CFrame.RightVector
            local up = cam.CFrame.UpVector
            local vel = Vector3.new(0, 0, 0)
            if uis:IsKeyDown(Enum.KeyCode.W) then vel = vel + fwd * 50 end
            if uis:IsKeyDown(Enum.KeyCode.S) then vel = vel - fwd * 50 end
            if uis:IsKeyDown(Enum.KeyCode.A) then vel = vel - right * 50 end
            if uis:IsKeyDown(Enum.KeyCode.D) then vel = vel + right * 50 end
            if uis:IsKeyDown(Enum.KeyCode.Space) then vel = vel + up * 50 end
            if uis:IsKeyDown(Enum.KeyCode.LeftShift) then vel = vel - up * 50 end
            bv.Velocity = vel
            task.wait()
        end
    end)
end

local function applyJumpUnlock()
    if features.jumpUnlock.enabled then
        hum.JumpPower = 150
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
    else
        hum.JumpPower = 50
    end
end

local function applyFOV()
    if features.fov.enabled then
        ws.Camera.FieldOfView = features.fov.value
    else
        ws.Camera.FieldOfView = 70
    end
end

local function applyNoStun()
    if features.noStun.enabled then
        hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if hum.WalkSpeed < 16 then hum.WalkSpeed = 16 end
        end)
    end
end

local function applySpeedBoost()
    if features.speedBoost.enabled then
        local boost = features.speedBoost.value or 1
        root.CFrame = root.CFrame + hum.MoveDirection * boost
        root.CanCollide = true
    end
end

local function applyAll()
    pcall(applySpeed)
    pcall(applyNoclip)
    pcall(applyNightVision)
    pcall(applyHeartbeat)
    pcall(applyInfiniteHealth)
    pcall(applyInfiniteStamina)
    pcall(applySpeedMultiplier)
    pcall(applyAimbot)
    pcall(applyStepFly)
    pcall(applyAutoFlyUp)
    pcall(applyNewFly)
    pcall(applyJumpUnlock)
    pcall(applyFullbright)
    pcall(applyFOV)
    pcall(applyNoStun)
end

player.CharacterAdded:Connect(function(newChar)
    char = newChar
    root = char:WaitForChild("HumanoidRootPart")
    hum = char:WaitForChild("Humanoid")
    task.wait(0.5)
    applyAll()
end)

applyAll()-- ============================================
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

Main:AddToggle("ESPToggle", {
    Text = "透视（高亮所有玩家）",
    Default = false,
    Callback = function(v)
        features.esp.enabled = v
        if v then startESP() else stopESP() end
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

Main:AddToggle("NoStunToggle", {
    Text = "去除减速",
    Default = false,
    Callback = function(v)
        features.noStun.enabled = v
        pcall(applyNoStun)
    end,
})

Main:AddSlider("SpeedBoostSlider", {
    Text = "速度调节",
    Min = 0, Max = 3, Default = 1,
    Compact = true, Rounding = 1,
    Callback = function(v) features.speedBoost.value = v end,
})

Main:AddToggle("SpeedBoostToggle", {
    Text = "激活速度",
    Default = false,
    Callback = function(v)
        features.speedBoost.enabled = v
        if v then
            task.spawn(function()
                while features.speedBoost.enabled do
                    pcall(applySpeedBoost)
                    task.wait()
                end
            end)
        end
    end,
})

Main:AddToggle("SpeedToggle", {
    Text = "超级速度",
    Default = true,
    Callback = function(v)
        features.speed.enabled = v
        pcall(applySpeed)
    end,
})

Main:AddToggle("NoclipToggle", {
    Text = "穿墙",
    Default = true,
    Callback = function(v)
        features.noclip.enabled = v
        pcall(applyNoclip)
    end,
})

Main:AddToggle("NightVisionToggle", {
    Text = "夜视",
    Default = true,
    Callback = function(v)
        features.nightVision.enabled = v
        pcall(applyNightVision)
    end,
})

Main:AddToggle("HeartbeatToggle", {
    Text = "心跳上限99999",
    Default = true,
    Callback = function(v)
        features.heartbeat.enabled = v
        pcall(applyHeartbeat)
    end,
})

Main:AddToggle("HealthToggle", {
    Text = "无限血量",
    Default = true,
    Callback = function(v)
        features.infiniteHealth.enabled = v
        pcall(applyInfiniteHealth)
    end,
})

Main:AddToggle("StepFlyToggle", {
    Text = "踏空而行",
    Default = false,
    Callback = function(v)
        features.stepFly.enabled = v
        pcall(applyStepFly)
    end,
})

Main:AddToggle("AutoFlyUpToggle", {
    Text = "自动飞升",
    Default = false,
    Callback = function(v)
        features.autoFlyUp.enabled = v
        pcall(applyAutoFlyUp)
    end,
})

Main:AddToggle("NewFlyToggle", {
    Text = "新飞天",
    Default = false,
    Callback = function(v)
        features.newFly.enabled = v
        pcall(applyNewFly)
    end,
})

Main:AddToggle("JumpUnlockToggle", {
    Text = "解锁跳跃",
    Default = false,
    Callback = function(v)
        features.jumpUnlock.enabled = v
        pcall(applyJumpUnlock)
    end,
})

Main:AddSlider("SpeedMultiplierSlider", {
    Text = "速度倍率",
    Min = 1, Max = 50, Default = 1,
    Compact = true, Rounding = 1,
    Callback = function(v)
        features.speedMultiplier.value = v
        features.speedMultiplier.enabled = true
        pcall(applySpeedMultiplier)
    end,
})

Main:AddToggle("AimbotToggle", {
    Text = "自瞄",
    Default = false,
    Callback = function(v)
        features.aimbot.enabled = v
        pcall(applyAimbot)
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

-- ============================================
-- 音乐
-- ============================================
local MusicIds = {
    "109842476936999",
    "122980543341165",
    "114689919641711",
    "86857426956968",
}
local CurrentMusic = nil

local function PlayRandomMusic()
    if CurrentMusic then
        pcall(function() CurrentMusic:Destroy() end)
        CurrentMusic = nil
    end
    local id = MusicIds[math.random(1, #MusicIds)]
    local sound = Instance.new("Sound")
    sound.Name = "DnR_Music"
    sound.SoundId = "rbxassetid://" .. id
    sound.Volume = 1
    sound.Parent = ws
    pcall(function() sound:Play() end)
    CurrentMusic = sound
    Library:Notify({ Title = "die and respawn", Content = "正在播放: " .. id, Time = 3 })
    sound.Ended:Connect(function()
        if CurrentMusic == sound then sound:Destroy(); CurrentMusic = nil end
    end)
end

Main:AddButton({
    Text = "播放音乐",
    Callback = function() pcall(PlayRandomMusic) end,
})

Main:AddButton({
    Text = "停止音乐",
    Callback = function()
        if CurrentMusic then
            pcall(function() CurrentMusic:Destroy() end)
            CurrentMusic = nil
            Library:Notify({ Title = "die and respawn", Content = "已停止", Time = 2 })
        end
    end,
})

-- ============================================
-- 环境
-- ============================================
local Env = Tabs.Main:AddRightGroupbox("环境")

Env:AddSlider("BrightnessSlider", {
    Text = "亮度", Min = 0, Max = 3, Default = 0, Rounding = 1, Compact = true,
    Callback = function(v)
        features.brightness = v
        if features.fullbright.enabled then pcall(applyFullbright) end
    end,
})

Env:AddToggle("GlobalShadowsToggle", {
    Text = "无阴影", Default = false,
    Callback = function(v)
        features.globalShadows.enabled = v
        if features.fullbright.enabled then pcall(applyFullbright) end
    end,
})

Env:AddToggle("NoFogToggle", {
    Text = "除雾", Default = false,
    Callback = function(v)
        features.noFog.enabled = v
        if features.fullbright.enabled then pcall(applyFullbright) end
    end,
})

Env:AddToggle("FullbrightToggle", {
    Text = "启用全亮", Default = false,
    Callback = function(v)
        features.fullbright.enabled = v
        pcall(applyFullbright)
    end,
})

-- ============================================
-- 视野
-- ============================================
local Fov = Tabs.Main:AddRightGroupbox("视野")

Fov:AddSlider("FOVSlider", {
    Text = "视野范围", Min = 70, Max = 120, Default = 70, Rounding = 1, Compact = true,
    Callback = function(v)
        features.fov.value = v
        if features.fov.enabled then pcall(applyFOV) end
    end,
})

Fov:AddToggle("FOVToggle", {
    Text = "启用视野", Default = false,
    Callback = function(v)
        features.fov.enabled = v
        pcall(applyFOV)
    end,
})

-- ============================================
-- 信息
-- ============================================
local Info = Tabs.Info:AddLeftGroupbox("版本信息")
Info:AddLabel("版本: 0.1")
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
