-- ============================================================
-- XD - 最终完整定制版 (格挡 | 自瞄 | 背刺 | 体力 | 视觉指示)
-- ============================================================

local Players    = game:GetService("Players")
local LP         = Players.LocalPlayer
local PlayerGui  = LP:WaitForChild("PlayerGui")
local RS         = game:GetService("ReplicatedStorage")
local WS         = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Lighting   = game:GetService("Lighting")
local UIS        = game:GetService("UserInputService")

-- ============================================================
-- 1. UI 库与主题配置
-- ============================================================
local repo = "https://cdn.jsdelivr.net/gh/deividcomsono/Obsidian@main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
Library.ShowCustomCursor = true
Library.NotifySide = "Right"

-- 暗黑+粉色主题
Library.Theme = {
    Name = "XD Theme",
    AccentColor = Color3.fromRGB(255, 100, 150),
    BackgroundColor = Color3.fromRGB(20, 20, 20),
    OutlineColor = Color3.fromRGB(50, 50, 50),
    FontColor = Color3.fromRGB(230, 230, 230),
    TextDarkTheme = true
}

local Window = Library:CreateWindow({
    Title = "XD",
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
    Utility   = Window:AddTab("实用功能", "wrench"),
    IDs       = Window:AddTab("ID 管理", "database"),
    Settings  = Window:AddTab("设置", "settings"),
}

local function notify(t, d) pcall(function() Library:Notify({Title=t, Description=d, Time=3}) end) end

-- ============================================================
-- 2. 配置与持久化
-- ============================================================
local Settings = {
    -- 格挡
    Enabled = false,
    TriggerRadius = 25,
    FacingCheck = true,
    FacingConeDegrees = 60,
    BlockDelay = 0.05,
    Cooldown = 0.1,
    -- 调节
    PresetMode = "普通",
    -- 体力
    InfiniteStamina = false,
    NoStaminaLoss = false,
    CustomStaminaGain = 25,
    -- 机会自瞄
    ChanceAimbot = false,
    ChanceAimDistance = 100,
    ChanceAimSmoothness = 0.8,
    -- 两次自动背刺
    TwoTimeBackstab = false,
    TwoTimeDistance = 8,
    TwoTimeKey = Enum.KeyCode.E, -- 刺击按键
    -- 调试
    DebugSound = false, DebugAnim = false, AutoLearn = false
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

-- ============================================================
-- 3. ID 库与变量 (整合最新补充版)
-- ============================================================
local AttackAnimIDs = {
    -- 基础通用动画
    ["100725497418533"]=true,["89448354637442"]=true,["120950360130737"]=true,["18885909645"]=true,["130958529065375"]=true,
    ["125403313786645"]=true,["138938529389204"]=true,["121293883585738"]=true,["88451353906104"]=true,["113281145948084"]=true,
    ["119021310055322"]=true,["109725460050273"]=true,["76052034966793"]=true,["94165438815708"]=true,["133738204715506"]=true,
    ["110467441332666"]=true,["127916769733604"]=true,["72623347581545"]=true,["129001498040521"]=true,["102776026072549"]=true,
    ["95721871543232"]=true,["116888521321180"]=true,["128939901497877"]=true,["78078652940310"]=true,["128072729691985"]=true,
    ["121138069766020"]=true,["83274568292003"]=true,["99865700633726"]=true,["97208348928006"]=true,["129919777481535"]=true,
    ["121982888855786"]=true,["106334382305365"]=true,["100972794726219"]=true,["95029865702251"]=true,["88346839287070"]=true,
    
    -- HDT_BLOCK_LOOKUP (你补充的19个)
    ["98105697395689"]=true,["100926346851492"]=true,["140671644163156"]=true,
    ["72182155407310"]=true,["72722244508749"]=true,["95802026624883"]=true,
    ["88557287105521"]=true,["123548100869928"]=true,["82605295530067"]=true,
    ["120748030255574"]=true,["88287038085804"]=true,["96959123077498"]=true,
    ["115706752305794"]=true,["82036084568393"]=true,["127040663332045"]=true,
    ["138407964761603"]=true,["102517104852347"]=true,["133292581373127"]=true,
    ["113899931890882"]=true,["90970641235403"]=true,
}

local AttackSoundIDs = {
    -- 基础通用音效
    ["83065883766992"]=true,["135033589919052"]=true,["129416978844337"]=true,["71052520996586"]=true,["71393863442839"]=true,
    ["77169942069536"]=true,["116242849765791"]=true,["98571846622815"]=true,["138272065054122"]=true,["90524931201518"]=true,
    ["94864487166343"]=true,["87322397689332"]=true,["123000863931753"]=true,["124423797300262"]=true,["127683480517891"]=true,
    ["74891693479380"]=true,["102228729296384"]=true,["140242176732868"]=true,["112809109188560"]=true,["136323728355613"]=true,
    ["115026634746636"]=true,["84116622032112"]=true,["108907358619313"]=true,["127793641088496"]=true,["86174610237192"]=true,
    ["95079963655241"]=true,["101199185291628"]=true,["119942598489800"]=true,["84307400688050"]=true,["113037804008732"]=true,
    ["105200830849301"]=true,["75330693422988"]=true,["82221759983649"]=true,["81702359653578"]=true,["108610718831698"]=true,
    ["112395455254818"]=true,["109431876587852"]=true,["109348678063422"]=true,["85853080745515"]=true,
    
    -- 你补充的25个音效
    ["87259391926321"]=true,["140703210927645"]=true,["136007065400978"]=true,["129843313690921"]=true,["86709774283672"]=true,
    ["108807732150251"]=true,["138040001965654"]=true,["86096387000557"]=true,["81905101227053"]=true,["127777649118195"]=true,
    ["99100240941590"]=true,["92831180929659"]=true,["112081768119093"]=true,["117587689359268"]=true,["91830732867282"]=true,
    ["91730605416216"]=true,["100184164753080"]=true,["108911997126897"]=true,["138936949998619"]=true,["116427323741607"]=true,
    ["72007882634344"]=true,["91522546229765"]=true,["111270184603402"]=true,["82137285150006"]=true,["119850211147676"]=true,
}
local DynamicAnimIDs, DynamicSoundIDs = {}, {}
local function isAnimKnown(id) return AttackAnimIDs[id] or DynamicAnimIDs[id] end
local function isSoundKnown(id) return AttackSoundIDs[id] or DynamicSoundIDs[id] end

-- ============================================================
-- 4. 核心工具函数
-- ============================================================
local function myRoot() local c = LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function getKillersFolder() local pf = WS:FindFirstChild("Players"); return pf and pf:FindFirstChild("Killers") end

local function getBlockButton()
    local pg = LP:FindFirstChild("PlayerGui")
    local main = pg and pg:FindFirstChild("MainUI")
    local container = main and main:FindFirstChild("AbilityContainer", true)
    if not container then return nil end
    return container:FindFirstChild("Block") or container:FindFirstChild("Guard") or container:FindFirstChild("Parry")
end

local function isButtonOnCooldown(btn)
    if not btn then return true end
    local cd = btn:FindFirstChild("CooldownTime", true) or btn:FindFirstChild("Cooldown", true)
    if not cd then return false end
    local val
    if cd:IsA("TextLabel") then val = tonumber(cd.Text)
    elseif cd:IsA("NumberValue") or cd:IsA("StringValue") then val = tonumber(cd.Value) end
    return val ~= nil and val > 0
end

local function executeBlock()
    local btn = getBlockButton()
    if not btn or isButtonOnCooldown(btn) then return false end
    pcall(function() btn:Activate() end)
    return true
end

local function amKiller()
    local c = LP.Character; local kf = getKillersFolder()
    return c and kf and c:IsDescendantOf(kf)
end

local function isKillerFacingMe(killerRoot, myRootPart)
    if not killerRoot or not myRootPart then return true end
    local toPlayer = (myRootPart.Position - killerRoot.Position)
    if toPlayer.Magnitude < 0.01 then return true end
    local dot = killerRoot.CFrame.LookVector:Dot(toPlayer.Unit)
    return math.deg(math.acos(math.clamp(dot, -1, 1))) <= Settings.FacingConeDegrees
end

-- ============================================================
-- 5. 自动格挡逻辑 (双轨检测)
-- ============================================================
local lastBlockAt = 0
local function tryBlock()
    if not Settings.Enabled or amKiller() then return end
    if tick() - lastBlockAt < Settings.Cooldown then return end
    lastBlockAt = tick()
    task.delay(Settings.BlockDelay, function() executeBlock() end)
end

local hookedKillers = setmetatable({}, {__mode="k"})
local function hookKillerAnims(model)
    if hookedKillers[model] then return end
    hookedKillers[model] = true
    local hum = model:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if not animator then return end
    animator.AnimationPlayed:Connect(function(track)
        if not Settings.Enabled then return end
        local id = track.Animation and track.Animation.AnimationId:match("%d+")
        if not id then return end
        if Settings.AutoLearn and not isAnimKnown(id) then DynamicAnimIDs[id] = true end
        if isAnimKnown(id) then
            local root = myRoot(); local hrp = model:FindFirstChild("HumanoidRootPart")
            if root and hrp and (hrp.Position - root.Position).Magnitude <= Settings.TriggerRadius then
                if not Settings.FacingCheck or isKillerFacingMe(hrp, root) then tryBlock() end
            end
        end
    end)
end

local hookedSounds = setmetatable({}, {__mode="k"})
local function hookSound(s)
    if not s:IsA("Sound") or hookedSounds[s] then return end
    hookedSounds[s] = true
    s.Played:Connect(function()
        if not Settings.Enabled or not s.IsPlaying then return end
        local id = tostring(s.SoundId):match("%d+")
        if not id then return end
        if Settings.AutoLearn and not isSoundKnown(id) then DynamicSoundIDs[id] = true end
        if isSoundKnown(id) then
            local root = myRoot(); if not root then return end
            local pos = s.Parent and (s.Parent:IsA("BasePart") and s.Parent.Position or s.Parent:FindFirstChild("HumanoidRootPart") and s.Parent.HumanoidRootPart.Position)
            if pos and (pos - root.Position).Magnitude <= Settings.TriggerRadius then tryBlock() end
        end
    end)
end

-- ============================================================
-- 6. 两次自动背刺 & 距离指示线
-- ============================================================
local lastBackstabTime = 0
local backstabCooldown = 1

local function isLocalPlayerTwoTime()
    local char = LP.Character
    if not char then return false end
    local survFolder = WS:FindFirstChild("Players") and WS.Players:FindFirstChild("Survivors")
    if not survFolder then return false end
    for _, s in ipairs(survFolder:GetChildren()) do
        if s == char and s.Name == "TwoTime" then return true end
    end
    return false
end

-- 创建画线部件
local beamPart1 = Instance.new("Part")
beamPart1.Name = "XD_BackstabBeam_P1"
beamPart1.Anchored = true
beamPart1.CanCollide = false
beamPart1.CanQuery = false
beamPart1.Transparency = 1
beamPart1.Parent = WS

local beamPart2 = Instance.new("Part")
beamPart2.Name = "XD_BackstabBeam_P2"
beamPart2.Anchored = true
beamPart2.CanCollide = false
beamPart2.CanQuery = false
beamPart2.Transparency = 1
beamPart2.Parent = WS

local backstabBeam = Instance.new("Beam")
backstabBeam.Name = "XD_BackstabBeam"
backstabBeam.FaceCamera = true
backstabBeam.Width0 = 0.1
backstabBeam.Width1 = 0.1
backstabBeam.LightEmission = 1
backstabBeam.LightInfluence = 0
backstabBeam.Enabled = false
backstabBeam.Parent = beamPart1

local a1 = Instance.new("Attachment", beamPart1)
local a2 = Instance.new("Attachment", beamPart2)
backstabBeam.Attachment0 = a1
backstabBeam.Attachment1 = a2

RunService.RenderStepped:Connect(function()
    backstabBeam.Enabled = false

    if not Settings.TwoTimeBackstab or not isLocalPlayerTwoTime() then return end
    if tick() - lastBackstabTime < backstabCooldown then return end
    
    local myChar = LP.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myRoot or not myHum or myHum.Health <= 0 then return end
    
    local kf = getKillersFolder()
    if not kf then return end
    
    local nearestKiller, nearestDist = nil, math.huge
    
    for _, killer in ipairs(kf:GetChildren()) do
        if killer:IsA("Model") then
            local kRoot = killer:FindFirstChild("HumanoidRootPart")
            local kHum = killer:FindFirstChildOfClass("Humanoid")
            
            if kRoot and kHum and kHum.Health > 0 then
                local dist = (kRoot.Position - myRoot.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearestKiller = killer
                end
                
                -- 判定是否在背后 (点积 < -0.2)
                local killerToMe = (myRoot.Position - kRoot.Position).Unit
                local dot = kRoot.CFrame.LookVector:Dot(killerToMe)
                local isBehind = dot < -0.2
                local inDistance = dist <= Settings.TwoTimeDistance

                if killer == nearestKiller then
                    beamPart1.Position = myRoot.Position
                    beamPart2.Position = kRoot.Position
                    backstabBeam.Enabled = true
                    
                    if inDistance and isBehind then
                        backstabBeam.Color = ColorSequence.new(Color3.fromRGB(0, 255, 0)) -- 绿色：可背刺
                    else
                        backstabBeam.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0)) -- 红色：不可背刺
                    end
                end

                -- 满足条件，触发背刺
                if inDistance and isBehind and tick() - lastBackstabTime >= backstabCooldown then
                    -- 蹲下
                    pcall(function()
                        game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
                    end)
                    task.wait(0.1)
                    -- 刺击
                    pcall(function()
                        game:GetService("VirtualInputManager"):SendKeyEvent(true, Settings.TwoTimeKey, false, game)
                        task.wait(0.05)
                        game:GetService("VirtualInputManager"):SendKeyEvent(false, Settings.TwoTimeKey, false, game)
                    end)
                    -- 站起
                    pcall(function()
                        game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
                    end)
                    
                    lastBackstabTime = tick()
                    break
                end
            end
        end
    end
end)

-- ============================================================
-- 7. 机会专属开枪自瞄
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
    animator.AnimationPlayed:Connect(function(track)
        if not Settings.ChanceAimbot or not isLocalPlayerChance() then return end
        local id = track.Animation and track.Animation.AnimationId:match("%d+")
        if id and ChanceShootAnims[id] then
            local root = myRoot(); if not root then return end
            local kf = getKillersFolder(); if not kf then return end
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
    end)
end

RunService.RenderStepped:Connect(function()
    if not Settings.ChanceAimbot or not chanceAimTarget or tick() - lastAimTime > 0.5 or not chanceAimTarget.Parent then return end
    local root = myRoot(); if not root then return end
    local targetCF = CFrame.lookAt(root.Position, Vector3.new(chanceAimTarget.Position.X, root.Position.Y, chanceAimTarget.Position.Z))
    root.CFrame = Settings.ChanceAimSmoothness >= 0.99 and targetCF or root.CFrame:Lerp(targetCF, Settings.ChanceAimSmoothness)
end)

-- ============================================================
-- 8. 体力系统
-- ============================================================
task.spawn(function()
    while task.wait(0.2) do
        if Settings.InfiniteStamina or Settings.NoStaminaLoss or Settings.CustomStaminaGain ~= 25 then
            pcall(function()
                local systems = RS:FindFirstChild("Systems")
                local sprinting = systems and systems:FindFirstChild("Character") and systems.Character:FindFirstChild("Game") and systems.Character.Game:FindFirstChild("Sprinting")
                if sprinting then
                    local m = require(sprinting)
                    if Settings.InfiniteStamina then m.Stamina = m.MaxStamina; m.StaminaLoss = 0 end
                    if Settings.NoStaminaLoss then m.StaminaLoss = 0 end
                    if Settings.CustomStaminaGain ~= 25 then m.StaminaGain = Settings.CustomStaminaGain end
                end
            end)
        end
    end
end)

-- ============================================================
-- 9. 主循环与生命周期
-- ============================================================
task.spawn(function()
    for _, d in ipairs(WS:GetDescendants()) do
        if d:IsA("Sound") then hookSound(d) end
    end
    WS.DescendantAdded:Connect(function(d) if d:IsA("Sound") then hookSound(d) end end)
    while task.wait(1) do
        local kf = getKillersFolder()
        if kf then for _, m in ipairs(kf:GetChildren()) do if m:IsA("Model") then hookKillerAnims(m) end end end
    end
end)

LP.CharacterAdded:Connect(function()
    task.wait(1)
    hookChanceAnims()
end)
if LP.Character then hookChanceAnims() end

-- ============================================================
-- 10. UI 界面构建
-- ============================================================
-- 主页
local HomeGroup = Tabs.Main:AddLeftGroupbox("欢迎使用 XD", "home")
HomeGroup:AddLabel("脚本名: XD - 最终完整定制版")
HomeGroup:AddLabel("当前用户名: " .. LP.Name)
HomeGroup:AddLabel("当前游戏: Forsaken")

-- 自动格挡
local BlockGroup = Tabs.Block:AddLeftGroupbox("Auto Block", "shield")
BlockGroup:AddToggle("AutoBlock", { Text = "启用自动格挡", Default = Settings.Enabled, Callback = function(v) Settings.Enabled = v; saveConfig(); notify("格挡", v and "已开启" or "已关闭") end })
BlockGroup:AddSlider("TriggerRadius", { Text = "触发距离", Default = 25, Min = 5, Max = 50, Rounding = 0, Callback = function(v) Settings.TriggerRadius = v; saveConfig() end })
BlockGroup:AddToggle("FacingCheck", { Text = "杀手面向检测", Default = true, Callback = function(v) Settings.FacingCheck = v; saveConfig() end })

-- 调节
local AdjustLeft = Tabs.Adjust:AddLeftGroupbox("模式预设", "sliders")
local AdjustRight = Tabs.Adjust:AddRightGroupbox("参数微调", "settings")
local Presets = {
    ["伪装"] = { Delay = 0.18, Note = "伪装模式：模拟人类的平均反应速度。如果你不想被看出来，请使用此模式。" },
    ["普通"] = { Delay = 0.10, Note = "普通模式：略微快速的反应。如果你比较大胆，觉得稍微快一点也没关系，可以使用此模式。" },
    ["暴力"] = { Delay = 0.02, Note = "暴力模式：极速反应。仅限测试使用，如不想账号被重点关注，请勿长期开启。" }
}
AdjustLeft:AddDropdown("PresetMode", { Text = "选择反应速度", Values = {"伪装", "普通", "暴力"}, Default = Settings.PresetMode, Callback = function(v) Settings.PresetMode = v; Settings.BlockDelay = Presets[v].Delay; if Library.Options.BlockDelay then Library.Options.BlockDelay:SetValue(Presets[v].Delay) end; saveConfig() end })
local noteLabel = AdjustLeft:AddLabel({ Text = Presets[Settings.PresetMode].Note, DoesWrap = true })
AdjustRight:AddSlider("BlockDelay", { Text = "格挡延迟 (秒)", Default = 0.05, Min = 0, Max = 1, Rounding = 2, Callback = function(v) Settings.BlockDelay = v; saveConfig() end })

-- 开枪自瞄
local AimGroup = Tabs.Aimbot:AddLeftGroupbox("机会专属 (Chance)", "crosshair")
AimGroup:AddToggle("ChanceAimbot", { Text = "开枪自动瞄准杀手", Default = Settings.ChanceAimbot, Callback = function(v) Settings.ChanceAimbot = v; saveConfig() end })
AimGroup:AddSlider("ChanceAimDistance", { Text = "自瞄最大距离", Default = 100, Min = 20, Max = 300, Rounding = 0, Callback = function(v) Settings.ChanceAimDistance = v; saveConfig() end })
AimGroup:AddSlider("ChanceAimSmoothness", { Text = "锁头平滑度", Default = 0.8, Min = 0.1, Max = 1, Rounding = 2, Callback = function(v) Settings.ChanceAimSmoothness = v; saveConfig() end })

-- 自动背刺
local BackstabGroup = Tabs.Backstab:AddLeftGroupbox("两次专属 (Two Time)", "sword")
BackstabGroup:AddToggle("TwoTimeBackstab", { Text = "启用自动背刺", Default = Settings.TwoTimeBackstab, Callback = function(v) Settings.TwoTimeBackstab = v; saveConfig(); notify("背刺", v and "已开启" or "已关闭") end })
BackstabGroup:AddSlider("TwoTimeDistance", { Text = "背刺触发距离 (格)", Default = 8, Min = 2, Max = 20, Rounding = 1, Callback = function(v) Settings.TwoTimeDistance = v; saveConfig() end })
BackstabGroup:AddLabel("视觉提示：绿线代表在距离内且可背刺，红线代表不可背刺。", true)

-- 实用功能
local UtilGroup = Tabs.Utility:AddLeftGroupbox("实用功能", "wrench")
UtilGroup:AddToggle("InfiniteStamina", { Text = "无限体力", Default = Settings.InfiniteStamina, Callback = function(v) Settings.InfiniteStamina = v; if v then Settings.NoStaminaLoss = false end; saveConfig() end })
UtilGroup:AddToggle("NoStaminaLoss", { Text = "奔跑不消耗体力", Default = Settings.NoStaminaLoss, Callback = function(v) Settings.NoStaminaLoss = v; if v then Settings.InfiniteStamina = false end; saveConfig() end })
UtilGroup:AddSlider("CustomStaminaGain", { Text = "体力恢复速度", Default = 25, Min = 0, Max = 100, Rounding = 0, Callback = function(v) Settings.CustomStaminaGain = v; saveConfig() end })

-- ID 管理
local IDGroup = Tabs.IDs:AddLeftGroupbox("动态 ID 管理", "database")
IDGroup:AddInput("AddSoundID", { Text = "添加音效 ID", Default = "", Numeric = true, Finished = true, Callback = function(v) if v ~= "" then DynamicSoundIDs[v]=true end end })
IDGroup:AddInput("AddAnimID", { Text = "添加动画 ID", Default = "", Numeric = true, Finished = true, Callback = function(v) if v ~= "" then DynamicAnimIDs[v]=true end end })

-- 设置
local SettingsGroup = Tabs.Settings:AddLeftGroupbox("配置管理", "settings")
SettingsGroup:AddButton({ Text = "手动保存配置", Func = function() saveConfig(); notify("设置", "已保存") end })
SettingsGroup:AddButton({ Text = "卸载脚本", Func = function() Library:Unload() end })

notify("XD", "脚本已加载 | 包含背刺指示线与最新 ID 库")
