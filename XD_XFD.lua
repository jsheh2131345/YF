-- ============================================================
-- XD - 终极完整版 (检测框判定机制 | 全功能)
-- 核心：只要杀手放技能就出框，玩家在框内才格挡
-- ============================================================

local Players    = game:GetService("Players")
local LP         = Players.LocalPlayer
local PlayerGui  = LP:WaitForChild("PlayerGui")
local RS         = game:GetService("ReplicatedStorage")
local WS         = game:GetService("Workspace")
local RunService = game:GetService("RunService")

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
    -- 格挡 (核心机制)
    Enabled = false,
    TriggerRadius = 35, -- 检测框半径
    BoxLingerTime = 1.5, -- 框停留时间
    BlockDelay = 0.05,
    Cooldown = 0.1,
    ShowBox = true,
    -- 调节
    PresetMode = "普通",
    -- 体力
    InfiniteStamina = false,
    NoStaminaLoss = false,
    -- 机会自瞄
    ChanceAimbot = false,
    ChanceAimDistance = 100,
    ChanceAimSmoothness = 0.8,
    -- 两次自动背刺
    TwoTimeBackstab = false,
    TwoTimeDistance = 8,
    TwoTimeKey = Enum.KeyCode.E,
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
-- 3. 完整 ID 库 (动画 + 音效)
-- ============================================================
local AttackAnimIDs = {
    ["100725497418533"]=true,["89448354637442"]=true,["120950360130737"]=true,["18885909645"]=true,["130958529065375"]=true,
    ["125403313786645"]=true,["138938529389204"]=true,["121293883585738"]=true,["88451353906104"]=true,["113281145948084"]=true,
    ["119021310055322"]=true,["109725460050273"]=true,["76052034966793"]=true,["94165438815708"]=true,["133738204715506"]=true,
    ["110467441332666"]=true,["127916769733604"]=true,["72623347581545"]=true,["129001498040521"]=true,["102776026072549"]=true,
    ["95721871543232"]=true,["116888521321180"]=true,["128939901497877"]=true,["78078652940310"]=true,["128072729691985"]=true,
    ["121138069766020"]=true,["83274568292003"]=true,["99865700633726"]=true,["97208348928006"]=true,["129919777481535"]=true,
    ["121982888855786"]=true,["106334382305365"]=true,["100972794726219"]=true,["95029865702251"]=true,["88346839287070"]=true,
    ["98105697395689"]=true,["100926346851492"]=true,["140671644163156"]=true,["72182155407310"]=true,["72722244508749"]=true,
    ["95802026624883"]=true,["88557287105521"]=true,["123548100869928"]=true,["82605295530067"]=true,["120748030255574"]=true,
    ["88287038085804"]=true,["96959123077498"]=true,["115706752305794"]=true,["82036084568393"]=true,["127040663332045"]=true,
    ["138407964761603"]=true,["102517104852347"]=true,["133292581373127"]=true,["113899931890882"]=true,["90970641235403"]=true,
}
local AttackSoundIDs = {
    ["83065883766992"]=true,["135033589919052"]=true,["129416978844337"]=true,["71052520996586"]=true,["71393863442839"]=true,
    ["77169942069536"]=true,["116242849765791"]=true,["98571846622815"]=true,["138272065054122"]=true,["90524931201518"]=true,
    ["94864487166343"]=true,["87322397689332"]=true,["123000863931753"]=true,["124423797300262"]=true,["127683480517891"]=true,
    ["74891693479380"]=true,["102228729296384"]=true,["140242176732868"]=true,["112809109188560"]=true,["136323728355613"]=true,
    ["115026634746636"]=true,["84116622032112"]=true,["108907358619313"]=true,["127793641088496"]=true,["86174610237192"]=true,
    ["95079963655241"]=true,["101199185291628"]=true,["119942598489800"]=true,["84307400688050"]=true,["113037804008732"]=true,
    ["105200830849301"]=true,["75330693422988"]=true,["82221759983649"]=true,["81702359653578"]=true,["108610718831698"]=true,
    ["112395455254818"]=true,["109431876587852"]=true,["109348678063422"]=true,["85853080745515"]=true,["87259391926321"]=true,
    ["140703210927645"]=true,["136007065400978"]=true,["129843313690921"]=true,["86709774283672"]=true,["108807732150251"]=true,
    ["138040001965654"]=true,["86096387000557"]=true,["81905101227053"]=true,["127777649118195"]=true,["99100240941590"]=true,
    ["92831180929659"]=true,["112081768119093"]=true,["117587689359268"]=true,["91830732867282"]=true,["91730605416216"]=true,
    ["100184164753080"]=true,["108911997126897"]=true,["138936949998619"]=true,["116427323741607"]=true,["72007882634344"]=true,
    ["91522546229765"]=true,["111270184603402"]=true,["82137285150006"]=true,["119850211147676"]=true,
}
local DynamicAnimIDs, DynamicSoundIDs = {}, {}
local function isAnimKnown(id) return AttackAnimIDs[id] or DynamicAnimIDs[id] end
local function isSoundKnown(id) return AttackSoundIDs[id] or DynamicSoundIDs[id] end

-- ============================================================
-- 4. 核心工具
-- ============================================================
local function myRoot() local c = LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function getKillersFolder() local pf = WS:FindFirstChild("Players"); return pf and pf:FindFirstChild("Killers") end

local function getBlockButton()
    local pg = LP:FindFirstChild("PlayerGui")
    local main = pg and pg:FindFirstChild("MainUI")
    local container = main and main:FindFirstChild("AbilityContainer", true)
    if not container then return nil end
    for _, obj in ipairs(container:GetDescendants()) do
        if obj:IsA("TextButton") or obj:IsA("ImageButton") then
            local n = obj.Name:lower()
            if n:find("block") or n:find("guard") or n:find("parry") then return obj end
        end
    end
    return nil
end

local function executeBlock()
    local btn = getBlockButton()
    if not btn then return false end
    local cd = btn:FindFirstChild("CooldownTime", true) or btn:FindFirstChild("Cooldown", true)
    if cd and cd:IsA("TextLabel") and tonumber(cd.Text) and tonumber(cd.Text) > 0 then return false end
    
    pcall(function() btn:Activate() end)
    pcall(function() if firesignal then firesignal(btn.MouseButton1Click) end end)
    pcall(function()
        if getconnections then
            for _, conn in ipairs(getconnections(btn.MouseButton1Click) or {}) do conn:Fire() end
        end
    end)
    return true
end

-- ============================================================
-- 5. 核心机制：框的生成 与 范围内格挡
-- ============================================================
local activeBoxes = {}
local lastBlockAt = 0

local function SpawnBox(killer, reason)
    if not Settings.ShowBox then return end
    local hrp = killer:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    if activeBoxes[killer] then
        activeBoxes[killer].expire = tick() + Settings.BoxLingerTime
        return
    end

    -- 创建可视化框（球体以中心判定）
    local box = Instance.new("Part")
    box.Name = "XD_Hitbox"
    box.Shape = Enum.PartType.Ball
    box.Size = Vector3.new(Settings.TriggerRadius * 2, Settings.TriggerRadius * 2, Settings.TriggerRadius * 2)
    box.Material = Enum.Material.ForceField
    box.Color = Color3.fromRGB(255, 0, 50)
    box.Transparency = 0.7
    box.CanCollide = false
    box.CanTouch = false
    box.CanQuery = false
    box.Anchored = false
    box.CFrame = hrp.CFrame
    
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = hrp
    weld.Part1 = box
    weld.Parent = box
    box.Parent = hrp

    activeBoxes[killer] = {part = box, expire = tick() + Settings.BoxLingerTime}
end

-- 每帧检测：如果我在框里，就格挡
RunService.Heartbeat:Connect(function()
    local root = myRoot()
    if not root then return end
    
    for killer, data in pairs(activeBoxes) do
        if tick() > data.expire or not killer.Parent or not data.part.Parent then
            if data.part then data.part:Destroy() end
            activeBoxes[killer] = nil
        else
            if Settings.Enabled then
                local kRoot = killer:FindFirstChild("HumanoidRootPart")
                if kRoot then
                    local dist = (root.Position - kRoot.Position).Magnitude
                    if dist <= Settings.TriggerRadius then
                        if tick() - lastBlockAt >= Settings.Cooldown then
                            lastBlockAt = tick()
                            task.delay(Settings.BlockDelay, function() executeBlock() end)
                        end
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- 6. 攻击监听 (触发框)
-- ============================================================
local hookedKillers = setmetatable({}, {__mode="k"})
local function hookKillerAnims(model)
    if hookedKillers[model] then return end
    hookedKillers[model] = true
    local hum = model:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if not animator then return end
    
    animator.AnimationPlayed:Connect(function(track)
        local id = track.Animation and track.Animation.AnimationId:match("%d+")
        if id and isAnimKnown(id) then
            SpawnBox(model, "动画:"..id)
        end
    end)
end

local hookedSounds = setmetatable({}, {__mode="k"})
local function hookSound(s)
    if not s:IsA("Sound") or hookedSounds[s] then return end
    hookedSounds[s] = true
    local function onPlay()
        if not s.IsPlaying then return end
        local id = tostring(s.SoundId):match("%d+")
        if id and isSoundKnown(id) then
            local parent = s.Parent
            while parent and not parent:IsA("Model") do parent = parent.Parent end
            local kf = getKillersFolder()
            if kf and parent and parent:IsDescendantOf(kf) then
                SpawnBox(parent, "音效:"..id)
            end
        end
    end
    s.Played:Connect(onPlay)
    s:GetPropertyChangedSignal("IsPlaying"):Connect(function() if s.IsPlaying then onPlay() end end)
end

-- ============================================================
-- 7. 两次自动背刺 & 距离指示线
-- ============================================================
local lastBackstabTime = 0
local function isLocalPlayerTwoTime()
    local char = LP.Character; if not char then return false end
    local surv = WS:FindFirstChild("Players") and WS.Players:FindFirstChild("Survivors")
    if not surv then return false end
    for _, s in ipairs(surv:GetChildren()) do if s == char and s.Name == "TwoTime" then return true end end
    return false
end

local beamPart1 = Instance.new("Part")
beamPart1.Anchored = true; beamPart1.CanCollide = false; beamPart1.Transparency = 1; beamPart1.Parent = WS
local beamPart2 = Instance.new("Part")
beamPart2.Anchored = true; beamPart2.CanCollide = false; beamPart2.Transparency = 1; beamPart2.Parent = WS
local backstabBeam = Instance.new("Beam")
backstabBeam.FaceCamera = true; backstabBeam.Width0 = 0.1; backstabBeam.Width1 = 0.1
backstabBeam.LightEmission = 1; backstabBeam.LightInfluence = 0; backstabBeam.Enabled = false; backstabBeam.Parent = beamPart1
local a1 = Instance.new("Attachment", beamPart1)
local a2 = Instance.new("Attachment", beamPart2)
backstabBeam.Attachment0 = a1; backstabBeam.Attachment1 = a2

RunService.RenderStepped:Connect(function()
    backstabBeam.Enabled = false
    if not Settings.TwoTimeBackstab or not isLocalPlayerTwoTime() then return end
    if tick() - lastBackstabTime < 1 then return end
    
    local myRoot = myRoot(); local myHum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if not myRoot or not myHum or myHum.Health <= 0 then return end
    local kf = getKillersFolder(); if not kf then return end
    
    local nearestKiller, nearestDist = nil, math.huge
    for _, killer in ipairs(kf:GetChildren()) do
        if killer:IsA("Model") then
            local kRoot = killer:FindFirstChild("HumanoidRootPart")
            local kHum = killer:FindFirstChildOfClass("Humanoid")
            if kRoot and kHum and kHum.Health > 0 then
                local dist = (kRoot.Position - myRoot.Position).Magnitude
                if dist < nearestDist then nearestDist = dist; nearestKiller = killer end
                
                local dot = kRoot.CFrame.LookVector:Dot((myRoot.Position - kRoot.Position).Unit)
                local isBehind = dot < -0.2
                local inDistance = dist <= Settings.TwoTimeDistance

                if killer == nearestKiller then
                    beamPart1.Position = myRoot.Position; beamPart2.Position = kRoot.Position
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
end)

-- ============================================================
-- 8. 机会专属开枪自瞄
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
    end)
end

RunService.RenderStepped:Connect(function()
    if not Settings.ChanceAimbot or not chanceAimTarget or tick() - lastAimTime > 0.5 or not chanceAimTarget.Parent then return end
    local root = myRoot(); if not root then return end
    local targetCF = CFrame.lookAt(root.Position, Vector3.new(chanceAimTarget.Position.X, root.Position.Y, chanceAimTarget.Position.Z))
    root.CFrame = Settings.ChanceAimSmoothness >= 0.99 and targetCF or root.CFrame:Lerp(targetCF, Settings.ChanceAimSmoothness)
end)

-- ============================================================
-- 9. 体力系统
-- ============================================================
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

-- ============================================================
-- 10. 主循环启动
-- ============================================================
task.spawn(function()
    for _, d in ipairs(WS:GetDescendants()) do if d:IsA("Sound") then hookSound(d) end end
    WS.DescendantAdded:Connect(function(d) if d:IsA("Sound") then hookSound(d) end end)
    
    while task.wait(1) do
        local kf = getKillersFolder()
        if kf then 
            for _, m in ipairs(kf:GetChildren()) do 
                if m:IsA("Model") then hookKillerAnims(m) end 
            end 
        end
    end
end)

LP.CharacterAdded:Connect(function()
    task.wait(1)
    hookChanceAnims()
end)
if LP.Character then hookChanceAnims() end

-- ============================================================
-- 11. UI 构建 (完整版)
-- ============================================================
local HomeGroup = Tabs.Main:AddLeftGroupbox("欢迎使用 XD", "home")
HomeGroup:AddLabel("脚本名: XD - 终极完整版")
HomeGroup:AddLabel("机制: 只要检测到攻击就出框，在框内自动格挡。")

-- 自动格挡 UI
local BlockGroup = Tabs.Block:AddLeftGroupbox("Auto Block", "shield")
BlockGroup:AddToggle("AutoBlock", { Text = "启用自动格挡", Default = Settings.Enabled, Callback = function(v) Settings.Enabled = v; saveConfig(); notify("格挡", v and "已开启" or "已关闭") end })
BlockGroup:AddSlider("TriggerRadius", { Text = "检测框半径", Default = 35, Min = 5, Max = 100, Rounding = 0, Callback = function(v) Settings.TriggerRadius = v; saveConfig() end })
BlockGroup:AddSlider("BoxLingerTime", { Text = "框停留时间(秒)", Default = 1.5, Min = 0.5, Max = 5, Rounding = 1, Callback = function(v) Settings.BoxLingerTime = v; saveConfig() end })
BlockGroup:AddToggle("ShowBox", { Text = "显示 Hitbox 框", Default = true, Callback = function(v) Settings.ShowBox = v; saveConfig() end })

-- 调节 UI
local AdjustLeft = Tabs.Adjust:AddLeftGroupbox("模式预设", "sliders")
local AdjustRight = Tabs.Adjust:AddRightGroupbox("参数微调", "settings")
local Presets = {
    ["伪装"] = { Delay = 0.18, Note = "伪装模式：模拟人类的平均反应速度。如果你不想被看出来，请使用此模式。" },
    ["普通"] = { Delay = 0.10, Note = "普通模式：略微快速的反应。如果你比较大胆，觉得稍微快一点也没关系，可以使用此模式。" },
    ["暴力"] = { Delay = 0.02, Note = "暴力模式：极速反应。仅限测试使用，如不想账号被重点关注，请勿长期开启。" }
}
AdjustLeft:AddDropdown("PresetMode", { Text = "选择反应速度", Values = {"伪装", "普通", "暴力"}, Default = Settings.PresetMode, Callback = function(v) Settings.PresetMode = v; Settings.BlockDelay = Presets[v].Delay; if Library.Options.BlockDelay then Library.Options.BlockDelay:SetValue(Presets[v].Delay) end; saveConfig() end })
AdjustLeft:AddLabel({ Text = Presets[Settings.PresetMode].Note, DoesWrap = true })
AdjustRight:AddSlider("BlockDelay", { Text = "格挡延迟 (秒)", Default = 0.05, Min = 0, Max = 1, Rounding = 2, Callback = function(v) Settings.BlockDelay = v; saveConfig() end })

-- 开枪自瞄 UI
local AimGroup = Tabs.Aimbot:AddLeftGroupbox("机会专属 (Chance)", "crosshair")
AimGroup:AddToggle("ChanceAimbot", { Text = "开枪自动瞄准杀手", Default = Settings.ChanceAimbot, Callback = function(v) Settings.ChanceAimbot = v; saveConfig() end })
AimGroup:AddSlider("ChanceAimDistance", { Text = "自瞄最大距离", Default = 100, Min = 20, Max = 300, Rounding = 0, Callback = function(v) Settings.ChanceAimDistance = v; saveConfig() end })
AimGroup:AddSlider("ChanceAimSmoothness", { Text = "锁头平滑度", Default = 0.8, Min = 0.1, Max = 1, Rounding = 2, Callback = function(v) Settings.ChanceAimSmoothness = v; saveConfig() end })

-- 背刺 UI
local BackstabGroup = Tabs.Backstab:AddLeftGroupbox("两次专属 (Two Time)", "sword")
BackstabGroup:AddToggle("TwoTimeBackstab", { Text = "启用自动背刺", Default = Settings.TwoTimeBackstab, Callback = function(v) Settings.TwoTimeBackstab = v; saveConfig(); notify("背刺", v and "已开启" or "已关闭") end })
BackstabGroup:AddSlider("TwoTimeDistance", { Text = "背刺触发距离 (格)", Default = 8, Min = 2, Max = 20, Rounding = 1, Callback = function(v) Settings.TwoTimeDistance = v; saveConfig() end })
BackstabGroup:AddLabel("视觉提示：绿线代表在距离内且可背刺，红线代表不可背刺。", true)

-- 实用 UI
local UtilGroup = Tabs.Utility:AddLeftGroupbox("实用功能", "wrench")
UtilGroup:AddToggle("InfiniteStamina", { Text = "无限体力", Default = Settings.InfiniteStamina, Callback = function(v) Settings.InfiniteStamina = v; saveConfig() end })
UtilGroup:AddToggle("NoStaminaLoss", { Text = "奔跑不消耗体力", Default = Settings.NoStaminaLoss, Callback = function(v) Settings.NoStaminaLoss = v; saveConfig() end })

-- ID 管理
local IDGroup = Tabs.IDs:AddLeftGroupbox("动态 ID 管理", "database")
IDGroup:AddInput("AddSoundID", { Text = "添加音效 ID", Default = "", Numeric = true, Finished = true, Callback = function(v) if v ~= "" then DynamicSoundIDs[v]=true end end })
IDGroup:AddInput("AddAnimID", { Text = "添加动画 ID", Default = "", Numeric = true, Finished = true, Callback = function(v) if v ~= "" then DynamicAnimIDs[v]=true end end })

-- 设置
local SettingsGroup = Tabs.Settings:AddLeftGroupbox("配置管理", "settings")
SettingsGroup:AddButton({ Text = "手动保存配置", Func = function() saveConfig(); notify("设置", "已保存") end })
SettingsGroup:AddButton({ Text = "卸载脚本", Func = function() Library:Unload() end })

notify("XD", "终极完整版已加载 | 出框检测机制已激活")
