-- ========================================
-- LnvAutoBlock 鉴权网关
-- ========================================

local Players      = game:GetService("Players")
local LP           = Players.LocalPlayer

local repo    = "https://cdn.jsdelivr.net/gh/deividcomsono/Obsidian@main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
Library.ShowCustomCursor = true

local AuthWindow = Library:CreateWindow({
    Title = "LnvAutoBlock 登录",
    Footer = "请完成验证",
    Icon = "rbxassetid://4483362748",
    Center = true,
    AutoShow = true,
    Resizable = false,
    NotifySide = "Right",
    ToggleKeybind = Enum.KeyCode.RightShift
})

local AuthTab = AuthWindow:AddTab("验证", "lock")

local isAuthorized = false
_G.InvAuth = _G.InvAuth or { NormalKey = nil, ExpireTime = 0 }

-- 永久卡密
local PermanentKeys = {
    ["LNV_7b3a80daa6a87f7a0385aa4485894526"] = true,
    ["LNV_9f2c4e1a7b3d8056c9e2f4a1b7d36085"] = true,
}

-- 50 个普通卡密池
local NormalKeyPool = {
    "ARSD_4a1b2c3d4e5f6g7h8i9j", "ARSD_9x8y7z6w5v4u3t2s1r0q", "ARSD_m1n2b3v4c5x6z7l8k9j",
    "ARSD_q1w2e3r4t5y6u7i8o9p", "ARSD_z1x2c3v4b5n6m7a8s9d", "ARSD_p0o9i8u7y6t5r4e3w2q",
    "ARSD_a1s2d3f4g5h6j7k8l9z", "ARSD_l9k8j7h6g5f4d3s2a1q", "ARSD_m9n8b7v6c5x4z3l2k1j",
    "ARSD_q9w8e7r6t5y4u3i2o1p", "ARSD_1a2b3c4d5e6f7g8h9i0j", "ARSD_9z8x7c6v5b4n3m2a1s",
    "ARSD_1q2w3e4r5t6y7u8i9o0", "ARSD_0p9o8i7u6y5t4r3e2w1", "ARSD_1a2s3d4f5g6h7j8k9l",
    "ARSD_9l8k7j6h5g4f3d2s1a", "ARSD_1m2n3b4v5c6x7z8l9k", "ARSD_9k8l7z6x5c4v3b2n1m",
    "ARSD_1q2w3e4r5t6y7u8i9o", "ARSD_9o8i7u6y5t4r3e2w1q", "ARSD_1z2x3c4v5b6n7m8a9s",
    "ARSD_9s8a7m6n5b4v3c2x1z", "ARSD_1p2o3i4u5y6t7r8e9w", "ARSD_9w8e7r6t5y4u3i2o1p",
    "ARSD_1a2b3c4d5e6f7g8h9i", "ARSD_9i8h7g6f5e4d3c2b1a", "ARSD_1x2y3z4a5b6c7d8e9f",
    "ARSD_9f8e7d6c5b4a3z2y1x", "ARSD_1m2n3o4p5q6r7s8t9u", "ARSD_9u8t7s6r5q4p3o2n1m",
    "ARSD_1v2w3x4y5z6a7b8c9d", "ARSD_9d8c7b6a5z4y3x2w1v", "ARSD_1e2f3g4h5i6j7k8l9m",
    "ARSD_9m8l7k6j5i4h3g2f1e", "ARSD_1n2o3p4q5r6s7t8u9v", "ARSD_9v8u7t6s5r4q3p2o1n",
    "ARSD_1w2x3y4z5a6b7c8d9e", "ARSD_9e8d7c6b5a4z3y2x1w", "ARSD_1f2g3h4i5j6k7l8m9n",
    "ARSD_9n8m7l6k5j4i3h2g1f", "ARSD_1o2p3q4r5s6t7u8v9w", "ARSD_9w8v7u6t5s4r3q2p1o",
    "ARSD_1x2y3z4a5b6c7d8e9f", "ARSD_9f8e7d6c5b4a3z2y1x", "ARSD_1g2h3i4j5k6l7m8n9o",
    "ARSD_9o8n7m6l5k4j3i2h1g", "ARSD_1p2q3r4s5t6u7v8w9x", "ARSD_9x8w7v6u5t4s3r2q1p",
    "ARSD_1y2z3a4b5c6d7e8f9g", "ARSD_9g8f7e6d5c4b3a2z1y"
}

local function validateKey(input)
    if type(input) == "string" then input = input:gsub("^%s*(.-)%s*$", "%1") else return false, "Invalid" end
    if PermanentKeys[input] then return true, "Permanent" end
    if _G.InvAuth.NormalKey and input == _G.InvAuth.NormalKey then
        if os.time() < _G.InvAuth.ExpireTime then return true, "Normal" else return false, "Expired" end
    end
    return false, "Invalid"
end

local AuthGroup = AuthTab:AddLeftGroupbox("卡密验证", "key")
AuthGroup:AddInput("KeyInput", { Text = "输入卡密", Default = "", Placeholder = "在此粘贴卡密...", ClearTextOnFocus = false, Finished = true })

AuthGroup:AddButton("确认并解锁", function()
    local isValid, keyType = validateKey(Library.Options.KeyInput.Value)
    if isValid then
        isAuthorized = true
        Library:Notify({Title = "授权成功", Description = "正在加载主功能...", Time = 3})
        
        -- 【核心改动】先加载主脚本，延迟销毁验证界面
        task.spawn(function()
            -- 1. 先执行主脚本
            local ok, err = pcall(function()
                loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/jsheh2131345/YF@main/LnvAutoBlock_SRIRT.lua"))()
            end)
            
            -- 2. 如果加载成功，等待主界面渲染完毕后，再销毁验证窗口
            if ok then
                task.wait(0.2)
                pcall(function() Library:Unload() end)
            else
                Library:Notify({Title = "加载失败", Description = tostring(err), Time = 5})
            end
        end)
    else
        if keyType == "Expired" then
            Library:Notify({Title = "卡密过期", Description = "普通卡密已过期，请答题获取新卡密！", Time = 4})
        else
            Library:Notify({Title = "授权失败", Description = "卡密错误！", Time = 3})
        end
    end
end)

AuthGroup:AddDivider()
AuthGroup:AddButton("不想答题？复制官方 QQ 群", function()
    if setclipboard then setclipboard("1136413909") Library:Notify({Title = "已复制", Description = "QQ群号: 1136413909", Time = 3})
    else Library:Notify({Title = "复制失败", Description = "执行器不支持", Time = 3}) end
end)

-- 答题区
local QuizGroup = AuthTab:AddRightGroupbox("答题续命 (普通卡密)", "help-circle")
local quizState = { progress = 0, questions = {} }
local ProgressLabel = QuizGroup:AddLabel("进度: 0 / 10", true)
local MathLabel = QuizGroup:AddLabel("题目: 点击下方按钮开始", true)
local AnswerInput = QuizGroup:AddInput("MathInput", { Text = "答案", Default = "", Placeholder = "输入数字...", Finished = false })

local function generateQuiz()
    quizState.questions = {}
    for i = 1, 5 do
        local a, b = math.random(10, 50), math.random(10, 50)
        table.insert(quizState.questions, { text = a .. " + " .. b .. " = ?", answer = a + b })
    end
    for i = 1, 5 do
        local x = math.random(1, 20)
        local mult = math.random(2, 9)
        local constant = math.random(1, 20)
        local result = x * mult + constant
        table.insert(quizState.questions, { text = "解方程: " .. mult .. "x + " .. constant .. " = " .. result .. " (x=?)", answer = x })
    end
    for i = #quizState.questions, 2, -1 do
        local j = math.random(1, i)
        quizState.questions[i], quizState.questions[j] = quizState.questions[j], quizState.questions[i]
    end
end

local CopyBtn = QuizGroup:AddButton("已生成卡密，点此复制", function()
    if _G.InvAuth.NormalKey then
        if setclipboard then setclipboard(_G.InvAuth.NormalKey) end
        Library:Notify({Title = "已复制", Description = _G.InvAuth.NormalKey, Time = 3})
    end
end)
CopyBtn:SetVisible(false)

QuizGroup:AddButton("提交答案", function()
    if quizState.progress >= 10 or MathLabel.Text == "题目: 点击下方按钮开始" then return end
    local userAns = tonumber(AnswerInput.Value)
    local currentQuestion = quizState.questions[quizState.progress + 1]
    if userAns and currentQuestion and userAns == currentQuestion.answer then
        quizState.progress = quizState.progress + 1
        ProgressLabel:SetText("进度: " .. quizState.progress .. " / 10")
        Library:Notify({Title = "回答正确", Description = "继续下一题！", Time = 1})
        if quizState.progress >= 10 then
            local newKey = NormalKeyPool[math.random(1, #NormalKeyPool)]
            _G.InvAuth.NormalKey = newKey
            _G.InvAuth.ExpireTime = os.time() + 86400
            MathLabel:SetText("题目: 答题完成！卡密已生成")
            AnswerInput:SetVisible(false)
            CopyBtn:SetVisible(true)
            if setclipboard then setclipboard(newKey) end
            Library:Notify({Title = "生成成功", Description = "新卡密已复制，有效期24小时！", Time = 5})
        else
            MathLabel:SetText("题目: " .. quizState.questions[quizState.progress + 1].text)
            AnswerInput:SetValue("")
        end
    else
        Library:Notify({Title = "回答错误", Description = "重新思考一下吧！", Time = 2})
    end
end)

QuizGroup:AddButton("获取普通卡密 (答题)", function()
    quizState.progress = 0
    ProgressLabel:SetText("进度: 0 / 10")
    generateQuiz()
    MathLabel:SetText("题目: " .. quizState.questions[1].text)
    AnswerInput:SetVisible(true)
    CopyBtn:SetVisible(false)
    Library:Notify({Title = "开始答题", Description = "答对10道题即可获得卡密！", Time = 3})
end)

if _G.InvAuth.NormalKey and os.time() < _G.InvAuth.ExpireTime then
    local remainingHours = math.floor((_G.InvAuth.ExpireTime - os.time()) / 3600)
    Library:Notify({Title = "检测到有效卡密", Description = "你的普通卡密还剩 " .. remainingHours .. " 小时", Time = 5})
    AuthGroup:AddLabel("当前可用普通卡密: " .. _G.InvAuth.NormalKey, true)
end
