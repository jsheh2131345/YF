-- ========================================
-- LnvAutoBlock 主功能
-- 包含：自动格挡、自动修机、无限体力/锁体力、深红判定框
-- ========================================

local Players      = game:GetService("Players")
local LP           = Players.LocalPlayer
local PlayerGui    = LP:WaitForChild("PlayerGui")
local RS           = game:GetService("ReplicatedStorage")
local WS           = game:GetService("Workspace")

local repo    = "https://cdn.jsdelivr.net/gh/deividcomsono/Obsidian@main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
Library.ShowCustomCursor = true
Library.NotifySide = "Right"

local MainWindow = Library:CreateWindow({
    Title = "LnvAutoBlock",
    Footer = "Forsaken Edition",
    Icon = "rbxassetid://4483362748",
    Center = true,
    AutoShow = true,
    Resizable = true,
    NotifySide = "Right",
    ToggleKeybind = Enum.KeyCode.RightShift
})

local Tabs = {
    ["自动格挡"] = MainWindow:AddTab("自动格挡", "shield"),
    ["功能"]     = MainWindow:AddTab("功能",     "zap"),
}

local function notify(t, d) pcall(function() Library:Notify({Title=t, Description=d, Time=2}) end) end

-- 核心设置
local Settings = {
    Enabled = false,
    ShowBox = true,
    BoxWidth = 5, BoxLength = 8, BoxHeight = 7, 
    BoxLingerTime = 0.4, 
    TriggerRadius = 20, 
    BlockDelay = 0.1,   
    KillerPause = true,
    -- 功能设置
    AutoGen = false,
    GenCooldown = 3,
    InfiniteStamina = false,
    LockStamina = false,
    TargetStamina = 50,
}

-- 全量动画 ID
local ATTACK_ANIM_IDS = {
    ["100725497418533"] = true, ["89448354637442"] = true, 
    ["120950360130737"] = true, ["18885909645"] = true, ["130958529065375"] = true,
    ["125403313786645"] = true, ["138938529389204"] = true, ["121293883585738"] = true,
    ["88451353906104"] = true, ["113281145948084"] = true, ["119021310055322"] = true,
    ["109725460050273"] = true, ["76052034966793"] = true, ["94165438815708"] = true,
    ["133738204715506"] = true, ["110467441332666"] = true, ["127916769733604"] = true,
    ["72623347581545"] = true, ["129001498040521"] = true, ["102776026072549"] = true,
    ["95721871543232"] = true, ["116888521321180"] = true, ["128939901497877"] = true,
    ["78078652940310"] = true, ["128072729691985"] = true, ["121138069766020"] = true,
    ["83274568292003"] = true, ["99865700633726"] = true, ["97208348928006"] = true,
    ["129919777481535"] = true, ["121982888855786"] = true, ["106334382305365"] = true,
    ["100972794726219"] = true, ["95029865702251"] = true, ["88346839287070"] = true,
}

-- 全量音效 ID
local ATTACK_SOUND_IDS = {
    ["92869747208256"] = true, ["95166423060976"] = true,
    ["81177941300998"] = true, ["124759000002143"] = true, ["100454448660396"] = true,
    ["80378074560573"] = true, ["71581509593817"] = true, ["137608690172310"] = true,
    ["111156341720353"] = true, ["103770659190361"] = true, ["120096209419889"] = true,
    ["138470027130522"] = true, ["126187132064750"] = true, ["114123828853081"] = true,
    ["113947388190071"] = true, ["135441171877786"] = true, ["97208348928006"] = true,
}

local function myRoot() local c = LP.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function getKillers() local pf = WS:FindFirstChild("Players") return pf and pf:FindFirstChild("Killers") end
local function getBlockButton()
    local pg = LP:FindFirstChild("PlayerGui")
    local main = pg and pg:FindFirstChild("MainUI")
    local container = main and main:FindFirstChild("AbilityContainer", true)
    return container and (container:FindFirstChild("Block") or container:FindFirstChild("Guard") or container:FindFirstChild("Parry"))
end

local function executeBlock()
    local btn = getBlockButton()
    if not btn then return end
    local cd = btn:FindFirstChild("CooldownTime", true)
    if cd and cd:IsA("TextLabel") and tostring(cd.Text) ~= "" and tostring(cd.Text) ~= "0" then return end
    pcall(function() btn:Activate() end)
end

local function amKiller()
    local c = LP.Character; local kf = getKillers(); return c and kf and c:IsDescendantOf(kf)
end

-- ============================================
-- 判定框逻辑
-- ============================================
local activeBoxes = {} 
local function spawnHitboxOnKiller(killer)
    if not Settings.ShowBox or not killer then return end
    for _, boxData in ipairs(activeBoxes) do
        if boxData.killer == killer then
            boxData.expire = tick() + Settings.BoxLingerTime
            return
        end
    end

    local box = Instance.new("Part")
    box.Name = "Inv_Hitbox"
    box.Size = Vector3.new(Settings.BoxWidth, Settings.BoxHeight, Settings.BoxLength)
    box.Anchored = true
    box.CanCollide = false; box.CanTouch = false; box.CanQuery = false; box.CastShadow = false
    box.Material = Enum.Material.ForceField
    box.Color = Color3.fromRGB(200, 30, 30) 
    box.Transparency = 0.5
    box.Parent = WS
    
    local boxOutline = Instance.new("SelectionBox")
    boxOutline.Adornee = box
    boxOutline.LineThickness = 0.1
    boxOutline.Color3 = Color3.fromRGB(255, 0, 0)
    boxOutline.SurfaceTransparency = 0.8
    boxOutline.Parent = box
    
    table.insert(activeBoxes, {killer = killer, part = box, expire = tick() + Settings.BoxLingerTime})
end

game:GetService("RunService").RenderStepped:Connect(function()
    for i = #activeBoxes, 1, -1 do
        local data = activeBoxes[i]
        if tick() > data.expire or not data.killer.Parent then
            data.part:Destroy()
            table.remove(activeBoxes, i)
        else
            local hrp = data.killer:FindFirstChild("HumanoidRootPart")
            if hrp then data.part.CFrame = hrp.CFrame end
        end
    end
end)

-- ============================================
-- 格挡触发逻辑
-- ============================================
local lastBlockAt = 0
local function tryBlock()
    if not Settings.Enabled then return end
    if Settings.KillerPause and amKiller() then return end
    if tick() - lastBlockAt < 0.1 then return end
    lastBlockAt = tick()
    local d = math.clamp(Settings.BlockDelay, 0, 3)
    if d <= 0.01 then executeBlock() else task.delay(d, executeBlock) end
end

local hookedKillers = setmetatable({}, {__mode="k"})
local lastAnimAt = setmetatable({}, {__mode="k"})
local function hookKillerAnims(model)
    if hookedKillers[model] then return end
    hookedKillers[model] = true
    local hum = model:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if not animator then return end
    
    animator.AnimationPlayed:Connect(function(track)
        if not Settings.Enabled then return end
        local id = track.Animation and track.Animation.AnimationId:match("%d+")
        local isAttack = false
        if id and ATTACK_ANIM_IDS[id] then isAttack = true
        else
            local name = track.Animation and track.Animation.Name:lower() or ""
            if not track.Looped and track.Length < 3.0 and not name:find("idle") and not name:find("walk") and not name:find("run") then isAttack = true end
        end
        
        if isAttack then
            local root = myRoot()
            local hrp = model:FindFirstChild("HumanoidRootPart")
            if hrp and root and (hrp.Position - root.Position).Magnitude <= Settings.TriggerRadius then
                if tick() - (lastAnimAt[model] or 0) > 0.1 then
                    lastAnimAt[model] = tick()
                    spawnHitboxOnKiller(model)
                    tryBlock()
                end
            end
        end
    end)
end

local hookedSounds = setmetatable({}, {__mode="k"})
local lastSoundAt = {}
local function onAnySound(s)
    if not Settings.Enabled or not s.IsPlaying then return end
    local id = tostring(s.SoundId):match("%d+")
    if not id or not ATTACK_SOUND_IDS[id] then return end
    if tick() - (lastSoundAt[id] or 0) < 0.1 then return end
    lastSoundAt[id] = tick()
    
    local root = myRoot(); if not root then return end
    local kf = getKillers(); if not kf then return end
    for _, k in ipairs(kf:GetChildren()) do
        if k:IsA("Model") then
            local hrp = k:FindFirstChild("HumanoidRootPart")
            if hrp and (hrp.Position - root.Position).Magnitude <= Settings.TriggerRadius then
                spawnHitboxOnKiller(k)
                tryBlock()
                break
            end
        end
    end
end

task.spawn(function()
    for _, d in ipairs(WS:GetDescendants()) do if d:IsA("Sound") then onAnySound(d) end end
    WS.DescendantAdded:Connect(function(d) if d:IsA("Sound") then onAnySound(d) end end)
    while task.wait(1) do
        local kf = getKillers()
        if kf then for _, m in ipairs(kf:GetChildren()) do if m:IsA("Model") then hookKillerAnims(m) end end end
    end
end)

-- ============================================
-- 自动修机 & 体力逻辑
-- ============================================
local GenState = { Solving = false, LastEnd = -math.huge }
local function puzzleOpen() return PlayerGui:FindFirstChild("PuzzleUI") ~= nil end
local function getGameMap() local map = WS:FindFirstChild("Map") return map and map:FindFirstChild("Ingame") and map.Ingame:FindFirstChild("Map") end

task.spawn(function()
    while task.wait(0.25) do
        pcall(function()
            if not Settings.AutoGen or GenState.Solving then return end
            if tick() - GenState.LastEnd < 2 or not puzzleOpen() then return end
            local root = myRoot(); local map = getGameMap()
            if not (root and map) then return end
            for _, gen in ipairs(map:GetChildren()) do
                if gen:IsA("Model") and gen.Name:find("Generator") and gen:FindFirstChild("Main") then
                    if (gen.Main.Position - root.Position).Magnitude < 6.7 then
                        GenState.Solving = true
                        task.spawn(function()
                            pcall(function()
                                local re = gen:FindFirstChild("Remotes") and gen.Remotes:FindFirstChildOfClass("RemoteEvent")
                                local progress = gen:FindFirstChild("Progress")
                                if not re then return end
                                local lastProgress = progress and progress.Value or 0
                                local stalled = 0
                                while Settings.AutoGen and gen.Parent and puzzleOpen() do
                                    if progress and progress.Value >= 100 then break end
                                    task.wait(Settings.GenCooldown + math.random() * 0.2 - 0.1)
                                    if not Settings.AutoGen or not gen.Parent or not puzzleOpen() then break end
                                    pcall(function() re:FireServer() end)
                                    if progress then
                                        if progress.Value > lastProgress then lastProgress = progress.Value; stalled = 0
                                        else stalled = stalled + 1; if stalled >= 8 then break end end
                                    end
                                end
                            end)
                            GenState.LastEnd = tick(); GenState.Solving = false
                        end)
                        break
                    end
                end
            end
        end)
    end
end)

local StaminaModule = nil
local StaminaRunning = nil
local function GetStaminaModule()
    if StaminaModule then return StaminaModule end
    local ok, module = pcall(function() return require(RS:WaitForChild("Systems", 3).Character.Game.Sprinting) end)
    if ok and module then StaminaModule = module; return module end
    return nil
end

local function applyInfiniteStamina()
    if not Settings.InfiniteStamina and not Settings.LockStamina then
        if StaminaRunning then task.cancel(StaminaRunning); StaminaRunning = nil end
        return
    end
    if StaminaRunning then return end
    StaminaRunning = task.spawn(function()
        while Settings.InfiniteStamina or Settings.LockStamina do
            pcall(function()
                local m = GetStaminaModule()
                if m then
                    if Settings.InfiniteStamina then m.StaminaLoss = 0; m.StaminaGain = 9999
                    elseif Settings.LockStamina then
                        local cur = rawget(m, "Stamina") or 0
                        if cur < Settings.TargetStamina then rawset(m, "Stamina", Settings.TargetStamina) end
                        m.StaminaLoss = 1; m.StaminaGain = 25
                    end
                end
            end)
            task.wait(0.1)
        end
    end)
end

-- ============================================
-- UI 部分
-- ============================================
local AutoBlockGroup = Tabs["自动格挡"]:AddLeftGroupbox("Auto Block", "shield")
AutoBlockGroup:AddToggle("AutoBlock", {
    Text = "自动格挡（原版专用）", Default = false,
    Callback = function(v)
        Settings.Enabled = v
        notify("自动格挡", v and "已开启" or "已关闭")
        if _G.InvFloatBtn then
            if v then
                _G.InvFloatBtn.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
                _G.InvFloatBtn.Text = "Auto Block\nON"
            else
                _G.InvFloatBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
                _G.InvFloatBtn.Text = "Auto Block\nOFF"
            end
        end
    end,
})

AutoBlockGroup:AddSlider("TriggerRadius", { Text = "触发距离", Default = 20, Min = 5, Max = 50, Rounding = 1, Callback = function(v) Settings.TriggerRadius = v end })
AutoBlockGroup:AddDivider()
AutoBlockGroup:AddSlider("BoxWidth", { Text = "框宽度", Default = 5, Min = 2, Max = 20, Rounding = 1, Callback = function(v) Settings.BoxWidth = v end })
AutoBlockGroup:AddSlider("BoxLength", { Text = "框长度", Default = 8, Min = 2, Max = 20, Rounding = 1, Callback = function(v) Settings.BoxLength = v end })
AutoBlockGroup:AddSlider("BoxHeight", { Text = "框高度", Default = 7, Min = 2, Max = 20, Rounding = 1, Callback = function(v) Settings.BoxHeight = v end })

local GenGroup = Tabs["功能"]:AddLeftGroupbox("自动修机", "zap")
GenGroup:AddToggle("AutoGen", { Text = "自动修机", Default = false, Callback = function(v) Settings.AutoGen = v end })
GenGroup:AddSlider("GenCooldown", { Text = "修机间隔", Default = 3, Min = 1, Max = 8, Rounding = 1, Callback = function(v) Settings.GenCooldown = v end })

local StaminaGroup = Tabs["功能"]:AddRightGroupbox("体力控制", "heart")
StaminaGroup:AddToggle("InfiniteStamina", { Text = "无限体力", Default = false, Callback = function(v) Settings.InfiniteStamina = v; if v then Settings.LockStamina = false end; applyInfiniteStamina() end })
StaminaGroup:AddToggle("LockStamina", { Text = "锁定指定体力值", Default = false, Callback = function(v) Settings.LockStamina = v; if v then Settings.InfiniteStamina = false end; applyInfiniteStamina() end })
StaminaGroup:AddSlider("TargetStamina", { Text = "目标体力值", Default = 50, Min = 1, Max = 200, Rounding = 0, Callback = function(v) Settings.TargetStamina = v end })

-- ============================================
-- 悬浮按钮
-- ============================================
local invGui = Instance.new("ScreenGui")
invGui.Name = "Inv_UI"; invGui.ResetOnSpawn = false; invGui.DisplayOrder = 999; invGui.Parent = PlayerGui
_G.InvGui = invGui

local floatBtn = Instance.new("TextButton")
floatBtn.Size = UDim2.new(0, 90, 0, 90) 
floatBtn.Position = UDim2.new(0, 20, 0, 150)
floatBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50) 
floatBtn.Text = "Auto Block\nOFF"
floatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
floatBtn.Font = Enum.Font.GothamBlack
floatBtn.TextSize = 14
floatBtn.AutoButtonColor = false
floatBtn.Parent = invGui
_G.InvFloatBtn = floatBtn

local fCorner = Instance.new("UICorner"); fCorner.CornerRadius = UDim.new(1, 0); fCorner.Parent = floatBtn
local fStroke = Instance.new("UIStroke"); fStroke.Color = Color3.fromRGB(255, 255, 255); fStroke.Thickness = 3; fStroke.Parent = floatBtn

local dragging, dragStart, startPos, wasDragged = false, nil, nil, false
floatBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; wasDragged = false; dragStart = input.Position; startPos = floatBtn.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if dragging then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then wasDragged = true end
            floatBtn.Position = UDim2.new(0, startPos.X.Offset + delta.X, 0, startPos.Y.Offset + delta.Y)
        end
    end
end)

floatBtn.MouseButton1Click:Connect(function()
    if wasDragged then return end
    Settings.Enabled = not Settings.Enabled
    if Settings.Enabled then
        floatBtn.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
        floatBtn.Text = "Auto Block\nON"
    else
        floatBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        floatBtn.Text = "Auto Block\nOFF"
    end
    if Library.Options.AutoBlock then
        pcall(function() Library.Options.AutoBlock:SetValue(Settings.Enabled) end)
    end
end)

notify("LnvAutoBlock", "已加载 | 主功能已就绪")
