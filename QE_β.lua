--!native
-- ============================================================
-- QE V1 (Part 1/2) - UI 框架、加载动画、基础设置、自瞄引擎
-- ============================================================

local function New(className, props, parent)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do inst[k] = v end
	if parent then inst.Parent = parent end
	return inst
end

getgenv()._thrT = getgenv()._thrT or {}
getgenv()._canRun = function(key, interval)
	local n = tick()
	local l = getgenv()._thrT[key]
	if not l or n - l >= interval then
		getgenv()._thrT[key] = n
		return true
	end
	return false
end

local Players       = game:GetService("Players")
local LP            = Players.LocalPlayer
local RS            = game:GetService("ReplicatedStorage")
local WS            = game:GetService("Workspace")
local RunService    = game:GetService("RunService")
local HttpService   = game:GetService("HttpService")
local Lighting      = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local TweenService  = game:GetService("TweenService")

local tick_ = os.clock
local v2new = Vector2.new
local c3rgb = Color3.fromRGB
local c3n = Color3.new

pcall(function()
	if getgenv().QE_CleanupAll then getgenv().QE_CleanupAll() getgenv().QE_CleanupAll = nil end
	local prev = getgenv().QE_Instance
	if prev then
		if prev.ScreenGui then pcall(function() prev.ScreenGui:Destroy() end) end
		if type(prev.Unload) == "function" then pcall(function() prev:Unload() end) end
	end
end)
getgenv().QE_Loaded = true
local __QELoadStart = tick_()

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
getgenv().QE_Instance = Library

local QELogo = "rbxassetid://4483362748"
local __LoadTotal = 100
local Loading = Library:CreateLoading({ Title = "QE V1", Icon = QELogo, IconSize = UDim2.fromOffset(40, 40), CurrentStep = 0,
	TotalSteps = __LoadTotal, ShowSidebar = false, AlwaysOnTop = true, WindowWidth = 460, WindowHeight = 220, ContentWidth = 460
})
Loading:SetMessage("QE V1")
Loading:SetDescription("正在初始化...")
Loading:SetCurrentStep(0)

local function createSnowFX(parent, opts)
	if not parent then return nil end
	opts = opts or {}
	local count = opts.Count or 50
	local color = opts.Color or c3rgb(255, 255, 255)
	local speedMin = opts.SpeedMin or 20
	local speedMax = opts.SpeedMax or 60
	local minSize = opts.MinSize or 2
	local maxSize = opts.MaxSize or 5
	local zIndex = opts.ZIndex or 50
	local transMin = opts.TransMin or 0.2
	local transMax = opts.TransMax or 0.7
	local frame = New("Frame", { Name = "QE_SnowFX", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0), BorderSizePixel = 0, ZIndex = zIndex, Active = false, ClipsDescendants = true }, parent)
	local flakes = {}
	for i = 1, count do
		local size = math.random(minSize, maxSize)
		local flake = New("Frame", { BackgroundColor3 = color, BackgroundTransparency = transMin + math.random() * (transMax - transMin),
			Size = UDim2.fromOffset(size, size), BorderSizePixel = 0, ZIndex = zIndex, Active = false }, frame)
		New("UICorner", { CornerRadius = UDim.new(1, 0) }, flake)
		flakes[i] = { inst = flake, x = math.random() * 100, y = -math.random() * 100,
			speed = speedMin + math.random() * (speedMax - speedMin), sway = math.random() * math.pi * 2, swaySpeed = 0.4 + math.random() * 1.4 }
	end
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		if not frame or not frame.Parent then if conn then pcall(function() conn:Disconnect() end) end return end
		local now = tick_()
		for _, f in ipairs(flakes) do
			f.y = f.y + f.speed * dt
			if f.y > 105 then f.y = -5 f.x = math.random() * 100 end
			local xOffset = math.sin(now * f.swaySpeed + f.sway) * 2
			f.inst.Position = UDim2.fromScale((f.x + xOffset) / 100, f.y / 100)
		end
	end)
	return { Frame = frame, Destroy = function() if conn then pcall(function() conn:Disconnect() end) conn = nil end if frame then pcall(function() frame:Destroy() end) frame = nil end end }
end

do
	local function attachLoadingSnow()
		local sg = Loading and Loading.ScreenGui
		if sg and not getgenv().QE_LoadingSnow then
			getgenv().QE_LoadingSnow = createSnowFX(sg, { Count = 45, SpeedMin = 20, SpeedMax = 55, ZIndex = 200, MinSize = 2, MaxSize = 5, TransMin = 0.15, TransMax = 0.6 })
			return true
		end
		return false
	end
	if not attachLoadingSnow() then task.spawn(function() for _ = 1, 100 do if attachLoadingSnow() then return end task.wait(0.1) end end) end
end

local LOADING_TEXT_WHITE = c3rgb(255, 255, 255)
function __StyleLoadingDesc()
	local sg = Loading and Loading.ScreenGui
	if not sg then return end
	local function style(inst)
		if inst:IsA("TextLabel") then
			pcall(function() inst.TextColor3 = LOADING_TEXT_WHITE inst.TextStrokeTransparency = 0.4 inst.TextStrokeColor3 = c3rgb(15, 15, 20) end)
			if not inst:GetAttribute("QE_DescLock") then
				inst:SetAttribute("QE_DescLock", true)
				inst:GetPropertyChangedSignal("TextColor3"):Connect(function() if inst.TextColor3 ~= LOADING_TEXT_WHITE then pcall(function() inst.TextColor3 = LOADING_TEXT_WHITE end) end end)
			end
		end
	end
	for _, inst in sg:GetDescendants() do style(inst) end
	if not sg:GetAttribute("QE_DescHook") then
		sg:SetAttribute("QE_DescHook", true)
		sg.DescendantAdded:Connect(function(inst) task.defer(function() style(inst) end) end)
	end
end
task.defer(function() pcall(__StyleLoadingDesc) end)

local __loadProgress = 0
local __loadTarget = 90
local __finishStarted = false
task.spawn(function()
	local msgList = { { 0, "QE V1", "正在启动..." }, { 25, "初始化", "准备 UI 资源..." }, { 50, "加载模块", "解析脚本模块..." },
		{ 75, "构建功能", "注册自动化任务..." }, { 90, "收尾", "检查依赖..." } }
	local function setStage(i)
		if i <= #msgList then
			Loading:SetMessage(msgList[i][2])
			Loading:SetDescription(msgList[i][3])
			pcall(__StyleLoadingDesc)
		end
		__loadProgress = i <= #msgList and msgList[i][1] or __loadTarget
		if __loadProgress > __loadTarget then __loadProgress = __loadTarget end
		Loading:SetCurrentStep(__loadProgress)
	end
	for i = 1, #msgList do
		if __finishStarted then break end
		setStage(i)
		task.wait(0.2)
	end
	__loadProgress = __loadTarget
	Loading:SetCurrentStep(90)
end)

task.delay(1.2, function()
	if __finishStarted then return end
	__finishStarted = true
	local function __fadeThroughBlack()
		local overlayGui = New("ScreenGui", { Name = "QE_FadeOverlay", DisplayOrder = 2147483647, IgnoreGuiInset = true, ResetOnSpawn = false })
		pcall(function() overlayGui.Parent = game:GetService("CoreGui") end)
		if not overlayGui.Parent then overlayGui.Parent = LP:WaitForChild("PlayerGui") end
		local blackFrame = New("Frame", { BackgroundColor3 = c3rgb(11, 11, 14), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, ZIndex = 1 }, overlayGui)
		local fadeIn = TweenService:Create(blackFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0 })
		fadeIn:Play() fadeIn.Completed:Wait()
		Loading:Continue()
		task.wait(0.15)
		local fadeOut = TweenService:Create(blackFrame, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 })
		fadeOut:Play() fadeOut.Completed:Wait()
		overlayGui:Destroy()
	end
	task.spawn(function()
		while __loadProgress < __LoadTotal do
			__loadProgress = math.min(__loadProgress + 5, __LoadTotal)
			Loading:SetCurrentStep(__loadProgress)
			task.wait(0.02)
		end
		task.wait(0.2)
		__fadeThroughBlack()
	end)
end)

Library.Scheme = { BackgroundColor = c3rgb(5, 5, 5), MainColor = c3rgb(24, 24, 28), AccentColor = c3rgb(225, 30, 30), OutlineColor = c3rgb(30, 5, 5),
	FontColor = c3n(1, 1, 1), Font = Font.fromEnum(Enum.Font.Code), RedColor = c3rgb(255, 50, 50), DestructiveColor = c3rgb(220, 20, 20), DarkColor = c3n(0, 0, 0),
	WhiteColor = c3n(1, 1, 1), BackgroundImage = ""
}
local Window = Library:CreateWindow({ Title = "QE V1", Footer = "Created by Liuye 安意【Willow leaf】",
	NotifySide = "Right", ShowCustomCursor = true, CornerRadius = 6,
	TabButtonsStyle = { Gap = 6, Padding = 6, CornerRadius = 6, Indicator = true, IndicatorWidth = 2, IndicatorHeight = 20 },
	Icon = QELogo, IconSize = UDim2.fromOffset(44, 44),
	Animations = { ToggleWindow = false, TabSwitch = true, Groupbox = true, Dropdown = true, KeyPicker = true },
	TabTransitionTime = 0.22, TabSwipeOffset = 26, TabSwipeFrom = "Auto"
})
Window:SetBackgroundImage("")

do
	local function getMainFrame()
		local win = Library and Library.Window
		local main = win and win.MainFrame
		if main and main:IsA("GuiObject") then return main end
		local sg = Library and Library.ScreenGui
		if sg then local m = sg:FindFirstChild("Main", true) if m and m:IsA("GuiObject") then return m end end
		return nil
	end
	local function attachMainSnow()
		if getgenv().QE_MainSnow then return true end
		local main = getMainFrame() if not main then return false end
		getgenv().QE_MainSnow = createSnowFX(main, { Count = 55, SpeedMin = 18, SpeedMax = 50, ZIndex = 999999, MinSize = 2, MaxSize = 4, TransMin = 0.35, TransMax = 0.75 })
		return true
	end
	if not attachMainSnow() then task.spawn(function() for _ = 1, 200 do if attachMainSnow() then return end task.wait(0.1) end end) end
end

local Tabs = {}
Tabs.Settings = Window:AddTab("设置", "settings")
Tabs.Character = Window:AddTab("人物", "user")
Tabs.Hitbox = Window:AddTab("打击盒", "box")
Tabs.ESP = Window:AddTab("透视", "eye")
Tabs.Exploit = Window:AddTab("剥削", "user")
Tabs.Aimbot = Window:AddTab("自瞄", "crosshair")

-- ====================================================
-- 核心 ID 库与基础配置
-- ====================================================
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

getgenv().QE_Config = {
    Block = { Enabled = false, Cooldown = 0.1, FacingCheck = false, FacingAngle = 90, WallCheck = false, 
              BoxSize = {X=5, Y=8, Z=5}, BoxForwardOffset = 4, BoxTransparency = 0.5, BoxColor = {255, 0, 0}, BoxLingerTime = 1.0, BlockDelay = 0.02 },
    Aimbot = { Chance = false, Cookidd = false, JohnDoe = false, Jason = false, Distance = 100, Smoothness = 0.8, Mode = "Camera" },
    Visual = { EnlargeHitbox = false, HitboxMultiplier = 3, LocalHitbox = false, Fullbright = false, NoFog = false, CameraNoclip = false, ESP = false },
    Utility = { InfStamina = false, NoStaminaLoss = false, AntiSlow = false, AntiStun = false, Noclip = false, Speed = 16, Jump = 50 },
}

local RemoteEvent
pcall(function() RemoteEvent = RS:WaitForChild("Modules"):WaitForChild("Network"):WaitForChild("RemoteEvent", 5) end)
local lastBlock = 0
local function FireBlock()
    if not RemoteEvent then return false end
    local now = tick()
    if now - lastBlock < getgenv().QE_Config.Block.Cooldown then return false end
    lastBlock = now
    pcall(function() RemoteEvent:FireServer("UseActorAbility", {buffer.fromstring("\3\5\0\0\0Block")}) end)
    return true
end

local function myRoot() local c = LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function getKillersFolder() local pf = WS:FindFirstChild("Players"); return pf and pf:FindFirstChild("Killers") end
local function GetBoxSize() return Vector3.new(getgenv().QE_Config.Block.BoxSize.X, getgenv().QE_Config.Block.BoxSize.Y, getgenv().QE_Config.Block.BoxSize.Z) end
local function IsKillerFacing(root, kRoot) 
    if not getgenv().QE_Config.Block.FacingCheck then return true end 
    if not root or not kRoot then return false end 
    local dir = (root.Position - kRoot.Position) 
    local flat = Vector3.new(dir.X, 0, dir.Z).Unit 
    local look = Vector3.new(kRoot.CFrame.LookVector.X, 0, kRoot.CFrame.LookVector.Z).Unit 
    return math.deg(math.acos(math.clamp(look:Dot(flat), -1, 1))) <= getgenv().QE_Config.Block.FacingAngle 
end
local function HasLOS(targetRoot) 
    if not getgenv().QE_Config.Block.WallCheck then return true end 
    local root = myRoot(); if not root then return false end 
    local params = RaycastParams.new() 
    params.FilterType = Enum.RaycastFilterType.Exclude; params.IgnoreWater = true; params.FilterDescendantsInstances = {LP.Character} 
    local result = WS:Raycast(root.Position, targetRoot.Position - root.Position, params) 
    return not result or result.Instance:IsDescendantOf(targetRoot.Parent) 
end
local function InBox(root, kRoot) 
    if not root or not kRoot then return false end 
    local boxSize = GetBoxSize() 
    local forward = kRoot.CFrame.LookVector 
    local boxPos = kRoot.Position + forward * getgenv().QE_Config.Block.BoxForwardOffset 
    local boxCFrame = CFrame.lookAt(boxPos, boxPos + forward * 100) 
    local rel = root.Position - boxPos 
    local localSpace = boxCFrame:VectorToObjectSpace(rel) 
    return math.abs(localSpace.X) <= (boxSize.X / 2) and math.abs(localSpace.Y) <= (boxSize.Y / 2) and math.abs(localSpace.Z) <= (boxSize.Z / 2) 
end
local function CheckAllConditions(root, kRoot) 
    if not root or not kRoot then return false end 
    return InBox(root, kRoot) and IsKillerFacing(root, kRoot) and HasLOS(kRoot) 
end

local Modules = { Visual = { Boxes = {} } }
local function SpawnBox(killer)
    if not killer or not killer:FindFirstChild("HumanoidRootPart") then return end
    if Modules.Visual.Boxes[killer] then
        Modules.Visual.Boxes[killer].expire = tick() + getgenv().QE_Config.Block.BoxLingerTime
        return
    end
    local folder = Instance.new("Folder"); folder.Name = "QE_Box"; folder.Parent = killer.HumanoidRootPart
    local box = Instance.new("Part"); box.Name = "Box"; box.Material = Enum.Material.ForceField
    box.Anchored = true; box.CanCollide = false; box.CanQuery = false; box.CastShadow = false
    box.Transparency = getgenv().QE_Config.Block.BoxTransparency
    box.Color = Color3.fromRGB(unpack(getgenv().QE_Config.Block.BoxColor))
    box.Size = GetBoxSize(); box.Parent = folder
    Modules.Visual.Boxes[killer] = {folder = folder, box = box, killer = killer, expire = tick() + getgenv().QE_Config.Block.BoxLingerTime}
end

local function UpdateBox(killer)
    local data = Modules.Visual.Boxes[killer]
    if not data or not data.folder or not data.folder.Parent then return end
    local kRoot = killer:FindFirstChild("HumanoidRootPart"); local root = myRoot()
    if not kRoot or not root then return end
    local forward = kRoot.CFrame.LookVector
    local pos = kRoot.Position + forward * getgenv().QE_Config.Block.BoxForwardOffset
    data.box.Size = GetBoxSize(); data.box.CFrame = CFrame.lookAt(pos, pos + forward * 100)
    data.box.Transparency = getgenv().QE_Config.Block.BoxTransparency
    data.box.Color = Color3.fromRGB(unpack(getgenv().QE_Config.Block.BoxColor))
end

local function HookSound(snd)
    if not snd:IsA("Sound") or snd:GetAttribute("QE_Hooked") then return end
    snd:SetAttribute("QE_Hooked", true)
    snd.Played:Connect(function()
        if not getgenv().QE_Config.Block.Enabled then return end
        local id = tostring(snd.SoundId):match("%d+")
        if not id or not AttackSoundIDs[id] then return end
        local parent = snd.Parent
        while parent and not parent:IsA("Model") do parent = parent.Parent end
        if parent then SpawnBox(parent) end
    end)
end
local function HookAnim(animator)
    if not animator:IsA("Animator") or animator:GetAttribute("QE_Hooked") then return end
    animator:SetAttribute("QE_Hooked", true)
    animator.AnimationPlayed:Connect(function(track)
        if not getgenv().QE_Config.Block.Enabled then return end
        local id = track.Animation and track.Animation.AnimationId:match("%d+")
        if not id or not AttackAnimIDs[id] then return end
        local parent = track.Parent
        while parent and not parent:IsA("Model") do parent = parent.Parent end
        if parent then SpawnBox(parent) end
    end)
end

for _, d in ipairs(WS:GetDescendants()) do
    if d:IsA("Sound") then HookSound(d) end
    if d:IsA("Animator") then HookAnim(d) end
end
WS.DescendantAdded:Connect(function(d)
    if d:IsA("Sound") then HookSound(d) end
    if d:IsA("Animator") then HookAnim(d) end
end)

-- 自动格挡 UI
local BlockGroup = Tabs.Hitbox:AddGroupbox({ Side = "Left", Name = "🛡️ 自动格挡设置" })
BlockGroup:AddToggle("AutoBlock", { Text = "启用自动格挡", Default = false, Callback = function(v) getgenv().QE_Config.Block.Enabled = v end })
BlockGroup:AddToggle("FacingCheck", { Text = "杀手面向检测", Default = false, Callback = function(v) getgenv().QE_Config.Block.FacingCheck = v end })
BlockGroup:AddToggle("WallCheck", { Text = "穿墙检测", Default = false, Callback = function(v) getgenv().QE_Config.Block.WallCheck = v end })
BlockGroup:AddSlider("BlockDelay", { Text = "格挡延迟 (秒)", Default = 0.02, Min = 0, Max = 0.5, Rounding = 2, Callback = function(v) getgenv().QE_Config.Block.BlockDelay = v end })

local BoxGroup = Tabs.Hitbox:AddGroupbox({ Side = "Right", Name = "📦 碰撞盒设置" })
BoxGroup:AddSlider("BoxWidth", { Text = "宽度", Default = 5, Min = 1, Max = 20, Rounding = 1, Callback = function(v) getgenv().QE_Config.Block.BoxSize.X = v end })
BoxGroup:AddSlider("BoxHeight", { Text = "高度", Default = 8, Min = 1, Max = 20, Rounding = 1, Callback = function(v) getgenv().QE_Config.Block.BoxSize.Y = v end })
BoxGroup:AddSlider("BoxLength", { Text = "长度", Default = 5, Min = 1, Max = 20, Rounding = 1, Callback = function(v) getgenv().QE_Config.Block.BoxSize.Z = v end })
BoxGroup:AddSlider("BoxOffset", { Text = "前后偏移", Default = 4, Min = -10, Max = 10, Rounding = 1, Callback = function(v) getgenv().QE_Config.Block.BoxForwardOffset = v end })
BoxGroup:AddSlider("BoxTransparency", { Text = "透明度", Default = 0.5, Min = 0, Max = 1, Rounding = 2, Callback = function(v) getgenv().QE_Config.Block.BoxTransparency = v end })
BoxGroup:AddSlider("BoxLingerTime", { Text = "滞留时间 (秒)", Default = 1.0, Min = 0.2, Max = 3.0, Rounding = 2, Callback = function(v) getgenv().QE_Config.Block.BoxLingerTime = v end })
BoxGroup:AddDropdown("BoxColor", { Text = "颜色", Values = {"红色", "绿色", "蓝色", "白色", "黄色"}, Default = "红色", Callback = function(v)
    local colors = { ["红色"]={255,0,0}, ["绿色"]={0,255,0}, ["蓝色"]={0,0,255}, ["白色"]={255,255,255}, ["黄色"]={255,255,0} }
    getgenv().QE_Config.Block.BoxColor = colors[v]
end })

-- 多角色自瞄
local CharacterAimbots = {
    Chance = { Enabled = false, Distance = 100, Smoothness = 0.8, Mode = "Camera", ShootAnims = { ["73921036900313"]=true, ["111384272984267"]=true, ["90499469533503"]=true, ["133491532453922"]=true }, Target = nil, LastAim = 0 },
    Cookidd = { Enabled = false, Distance = 100, Smoothness = 0.9, Mode = "Camera", CastAnims = { ["111033845010938"]=true, ["106484876889079"]=true }, Target = nil, LastAim = 0 },
    JohnDoe = { Enabled = false, Distance = 100, Smoothness = 0.9, Mode = "Camera", CastAnims = { ["109525294317144"]=true }, Target = nil, LastAim = 0 },
    Jason = { Enabled = false, Distance = 100, Smoothness = 0.9, Mode = "Character", CastAnims = { ["112809109188560"]=true, ["102228729296384"]=true }, Target = nil, LastAim = 0 }
}
local function ProcessCharacterAim(config, isLocalRole)
    if not config.Enabled or not isLocalRole then return end
    if tick() - config.LastAim > 0.5 or not config.Target or not config.Target.Parent then return end
    local root = myRoot(); if not root then return end
    local targetCF = CFrame.lookAt(root.Position, Vector3.new(config.Target.Position.X, root.Position.Y, config.Target.Position.Z))
    if config.Mode == "Camera" then workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(targetCF, config.Smoothness)
    else root.CFrame = root.CFrame:Lerp(targetCF, config.Smoothness) end
end
local function WatchCharacterAnims(char)
    local hum = char:FindFirstChildOfClass("Humanoid"); local animator = hum and hum:FindFirstChildOfClass("Animator"); if not animator then return end
    animator.AnimationPlayed:Connect(function(track)
        local id = track.Animation and track.Animation.AnimationId:match("%d+"); if not id then return end
        if CharacterAimbots.Chance.Enabled and CharacterAimbots.Chance.ShootAnims[id] then
            local kf = getKillersFolder()
            if kf then
                local nearest, minDist = nil, CharacterAimbots.Chance.Distance
                for _, k in ipairs(kf:GetChildren()) do
                    local hrp = k:FindFirstChild("HumanoidRootPart")
                    if hrp then local d = (hrp.Position - char.HumanoidRootPart.Position).Magnitude; if d < minDist then nearest, minDist = hrp, d end end
                end
                if nearest then CharacterAimbots.Chance.Target = nearest; CharacterAimbots.Chance.LastAim = tick() end
            end
        end
    end)
end
LP.CharacterAdded:Connect(WatchCharacterAnims)
if LP.Character then WatchCharacterAnims(LP.Character) end

local chanceAimbotEnabled = false
local CAbotConnection = nil
local function chanceAimbot(state)
    chanceAimbotEnabled = state
    if state then
        if not LP.Character or LP.Character.Name ~= "Chance" then
            Library:Notify({Title = "⚠️ 机会自瞄", Description = "你用的角色好像不是机会,无法生效", Time = 3})
            return
        end
        if CAbotConnection then CAbotConnection:Disconnect() CAbotConnection = nil end
        local RemoteEvent = RS:WaitForChild("Modules"):WaitForChild("Network"):WaitForChild("RemoteEvent")
        CAbotConnection = RemoteEvent.OnClientEvent:Connect(function(...)
            local args = {...}
            if not chanceAimbotEnabled then return end
            if args[1] == "UseActorAbility" and args[2] == "Shoot" then 
                local killerContainer = WS:FindFirstChild("Players") and WS.Players:FindFirstChild("Killers")
                if killerContainer then 
                    local nearestKiller, minDist = nil, getgenv().QE_Config.Aimbot.Distance
                    local playerHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    if playerHRP then
                        for _, k in ipairs(killerContainer:GetChildren()) do
                            local hrp = k:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                local d = (hrp.Position - playerHRP.Position).Magnitude
                                if d < minDist then nearestKiller = hrp; minDist = d end
                            end
                        end
                    end
                    if nearestKiller and playerHRP then 
                        local killerHRP = nearestKiller
                        local TMP = 0.35
                        local AMD = 2
                        local originalCFrame = playerHRP.CFrame
                        local endTime = tick() + AMD
                        while tick() < endTime and chanceAimbotEnabled do
                            RunService.RenderStepped:Wait()
                            if not killerHRP.Parent then break end
                            local predictedTarget = killerHRP.Position + (killerHRP.Velocity * TMP)
                            pcall(function() playerHRP.CFrame = CFrame.lookAt(predictedTarget - Vector3.new(0, 0, 2), predictedTarget) end)
                        end
                        pcall(function() if playerHRP and playerHRP.Parent then playerHRP.CFrame = originalCFrame end end)
                    end
                end
            end
        end)
    else
        if CAbotConnection then CAbotConnection:Disconnect() CAbotConnection = nil end
    end
end

local AimbotTab = Tabs.Aimbot:AddGroupbox({ Side = "Right", Name = "🎯 角色专属自瞄" })
AimbotTab:AddToggle("ChanceAimbot", { Text = "机会自瞄 (Chance)", Default = false, Callback = function(v) chanceAimbot(v) end })
AimbotTab:AddSlider("ChanceDistance", { Text = "机会-自瞄距离", Default = 100, Min = 20, Max = 300, Rounding = 0, Callback = function(v) getgenv().QE_Config.Aimbot.Distance = v end })
AimbotTab:AddToggle("CookiddAimbot", { Text = "酷小孩自瞄 (c00lkidd)", Callback = function(v) CharacterAimbots.Cookidd.Enabled = v end })
AimbotTab:AddToggle("JohnDoeAimbot", { Text = "约翰自瞄 (JohnDoe)", Callback = function(v) CharacterAimbots.JohnDoe.Enabled = v end })
AimbotTab:AddToggle("JasonAimbot", { Text = "杰森自瞄 (Slasher)", Callback = function(v) CharacterAimbots.Jason.Enabled = v end })
-- ====================================================
-- QE V1 (Part 2/2) - 实用功能、设置、主循环
-- ====================================================

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

-- 实用功能
local UtilGroup = Tabs.Character:AddGroupbox({ Side = "Left", Name = "🔧 实用功能" })
UtilGroup:AddToggle("InfStamina", { Text = "无限体力", Callback = function(v) getgenv().QE_Config.Utility.InfStamina = v end })
UtilGroup:AddToggle("NoStaminaLoss", { Text = "奔跑不消耗体力", Callback = function(v) getgenv().QE_Config.Utility.NoStaminaLoss = v end })
UtilGroup:AddToggle("AntiSlow", { Text = "无减速", Callback = function(v) getgenv().QE_Config.Utility.AntiSlow = v end })
UtilGroup:AddToggle("Noclip", { Text = "穿墙", Callback = function(v) getgenv().QE_Config.Utility.Noclip = v end })

-- 视觉增强
local VisGroup = Tabs.ESP:AddGroupbox({ Side = "Left", Name = "👁️ 视觉增强" })
VisGroup:AddToggle("ESP", { Text = "ESP 透视", Callback = function(v) 
    getgenv().QE_Config.Visual.ESP = v
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            if v then
                local h = Instance.new("Highlight", plr.Character)
                h.Name = "QE_ESP"
                h.FillColor = Color3.fromRGB(255, 0, 0)
            else
                local h = plr.Character:FindFirstChild("QE_ESP")
                if h then h:Destroy() end
            end
        end
    end
end })
VisGroup:AddToggle("Fullbright", { Text = "全亮", Callback = function(v) getgenv().QE_Config.Visual.Fullbright = v end })
VisGroup:AddToggle("NoFog", { Text = "去雾", Callback = function(v) getgenv().QE_Config.Visual.NoFog = v end })

-- 填补“设置”标签页
local SettingsGroup = Tabs.Settings:AddGroupbox({ Side = "Left", Name = "⚙️ 常规设置" })
SettingsGroup:AddDropdown("AimMode", {
    Text = "自瞄模式", Values = {"相机自瞄 (Camera)", "角色自瞄 (Character)"}, Default = "相机自瞄 (Camera)",
    Callback = function(v) getgenv().QE_Config.Aimbot.Mode = (v == "相机自瞄 (Camera)") and "Camera" or "Character" end
})
SettingsGroup:AddButton("关闭所有功能", function()
    for _, obj in pairs(Toggles) do if obj.Value == true then obj:SetValue(false) end end
    Library:Notify({Title="QE V1", Description="已重置所有功能开关", Time=3})
end)

-- 填补“剥削”标签页
local ExploitGroup = Tabs.Exploit:AddGroupbox({ Side = "Left", Name = "💥 游戏功能" })
ExploitGroup:AddToggle("AutoGen", {
    Text = "自动修机", Default = false,
    Callback = function(v) 
        getgenv().QE_Config.Utility.AutoGen = v 
        if v then
            task.spawn(function()
                while getgenv().QE_Config.Utility.AutoGen do
                    task.wait(1)
                    pcall(function()
                        local root = myRoot(); if not root then return end
                        local map = WS:FindFirstChild("Map") and WS.Map:FindFirstChild("Ingame") and WS.Map.Ingame:FindFirstChild("Map")
                        if not map then return end
                        local puzzleUI = LP.PlayerGui:FindFirstChild("PuzzleUI")
                        if not puzzleUI or not puzzleUI.Enabled then return end
                        for _, gen in ipairs(map:GetChildren()) do
                            if gen.Name == "Generator" and gen:FindFirstChild("Main") and (gen.Main.Position - root.Position).Magnitude < 6.7 then
                                local re = gen:FindFirstChild("Remotes") and gen.Remotes:FindFirstChildOfClass("RemoteEvent")
                                if re then re:FireServer() end
                            end
                        end
                    end)
                end
            end)
        end
    end
})

-- ====================================================
-- 主循环 (含性能优化，降频防卡顿)
-- ====================================================
local boxUpdateCounter = 0
local boxUpdateInterval = 2

RunService.Heartbeat:Connect(function()
    local char = LP.Character
    local root = myRoot()
    if not char or not root then return end
    
    -- 1. 检测框生命周期与更新
    boxUpdateCounter = boxUpdateCounter + 1
    for killer, data in pairs(Modules.Visual.Boxes) do
        if tick() > data.expire or not killer.Parent or not data.box.Parent then
            if data.folder then data.folder:Destroy() end
            Modules.Visual.Boxes[killer] = nil
        else
            if boxUpdateCounter >= boxUpdateInterval then
                local kRoot = killer:FindFirstChild("HumanoidRootPart")
                if kRoot then
                    local forward = kRoot.CFrame.LookVector
                    local pos = kRoot.Position + forward * getgenv().QE_Config.Block.BoxForwardOffset
                    data.box.Size = GetBoxSize()
                    data.box.CFrame = CFrame.lookAt(pos, pos + forward * 100)
                end
            end
        end
    end
    if boxUpdateCounter >= boxUpdateInterval then boxUpdateCounter = 0 end

    -- 2. 自动格挡判定 (框内触发)
    if getgenv().QE_Config.Block.Enabled then
        for killer, data in pairs(Modules.Visual.Boxes) do
            local kRoot = killer:FindFirstChild("HumanoidRootPart")
            if kRoot and CheckAllConditions(root, kRoot) then
                task.delay(getgenv().QE_Config.Block.BlockDelay, function() FireBlock() end)
            end
        end
    end

    -- 3. 自瞄与实用
    ProcessCharacterAim(CharacterAimbots.Chance, (char.Name == "Chance"))
    ProcessCharacterAim(CharacterAimbots.Cookidd, (char.Name == "c00lkidd"))
    ProcessCharacterAim(CharacterAimbots.JohnDoe, (char.Name == "JohnDoe"))
    ProcessCharacterAim(CharacterAimbots.Jason, (char.Name == "Slasher"))
    
    if getgenv().QE_Config.Utility.InfStamina or getgenv().QE_Config.Utility.NoStaminaLoss then
        pcall(function()
            local systems = RS:FindFirstChild("Systems")
            local sprinting = systems and systems:FindFirstChild("Character") and systems.Character:FindFirstChild("Game") and systems.Character.Game:FindFirstChild("Sprinting")
            if sprinting then
                local m = require(sprinting)
                if getgenv().QE_Config.Utility.InfStamina then m.Stamina = m.MaxStamina end
                if getgenv().QE_Config.Utility.InfStamina or getgenv().QE_Config.Utility.NoStaminaLoss then m.StaminaLoss = 0 end
            end
        end)
    end
    if getgenv().QE_Config.Utility.AntiSlow then
        local sm = char:FindFirstChild("SpeedMultipliers")
        if sm then for _, v in ipairs(sm:GetChildren()) do if v:IsA("NumberValue") and v.Value < 1 then v.Value = 1 end end end
    end
    if getgenv().QE_Config.Utility.Noclip then for _, v in ipairs(char:GetChildren()) do if v:IsA("BasePart") then v.CanCollide = false end end end
    if getgenv().QE_Config.Visual.Fullbright then Lighting.Ambient = Color3.fromRGB(255, 255, 255); Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255); Lighting.GlobalShadows = false end
    if getgenv().QE_Config.Visual.NoFog then Lighting.FogEnd = math.huge; Lighting.FogStart = 0 end
end)

-- 启动成功提示
Library:Notify({Title="QE V1", Description="所有模块已成功加载！", Time=5})
