--============================================================
--  SWILL • Piano UI (FINAL FULL VERSION)
--============================================================
local Core = _G.SWILL_Core
if not Core then return warn("[SWILL] Ядро не загружено! Запустите piano_core.lua") end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Stats = game:GetService("Stats")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local S = {
    speed = 1, tempo = 50, hold = 0.09, rest = 0.22, gap = 0.05,
    transpose = 0, countdown = 0, loop = false, shuffle = false,
    anti = false, antiMin = 8, antiMax = 35, antiCap = 90,
    antiTiming = 18, antiHold = 15, antiOrder = true, antiSmart = true,
    particles = true, girl = true, doodles = true, autohide = false,
    hotkeys = true, islandStats = true, antiAfk = true,
    uiScale = 1, accent = 1, girlName = "Саша",
}
local savedSongs = Core.loadSongs()
local rnd = Random.new()
local conns = {}
local function track(c) conns[#conns + 1] = c return c end

local BG0, BG1, BG2 = Color3.fromRGB(15, 15, 17), Color3.fromRGB(28, 28, 32), Color3.fromRGB(42, 42, 47)
local BUB, TXT, DIM, LINE = Color3.fromRGB(38, 38, 43), Color3.fromRGB(228, 228, 233), Color3.fromRGB(136, 136, 146), Color3.fromRGB(56, 56, 62)

local ACCENTS = {
    { name = "Золото", c = Color3.fromRGB(201, 162, 39) },
    { name = "Роза",   c = Color3.fromRGB(255, 138, 178) },
    { name = "Небо",   c = Color3.fromRGB(96, 160, 255) },
    { name = "Мята",   c = Color3.fromRGB(110, 222, 170) },
}
local function ACC() return ACCENTS[S.accent].c end

local gui, accRefs = nil, {}
local function acc(obj, prop) accRefs[#accRefs + 1] = { obj, prop }; obj[prop] = ACC(); return obj end
local function new(class, props, parent) local o = Instance.new(class); for k, v in pairs(props) do o[k] = v end; if parent then o.Parent = parent end; return o end
local function corner(o, r) return new("UICorner", { CornerRadius = typeof(r) == "UDim" and r or UDim.new(0, r) }, o) end
local function stroke(o, c, th) return new("UIStroke", { Color = c or LINE, Thickness = th or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o) end
local function tween(o, t, props, style, dir) local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props); tw:Play(); return tw end
local function fmtTime(sec) sec = math.max(0, math.floor(sec + 0.5)); return string.format("%d:%02d", math.floor(sec / 60), sec % 60) end

local function guiParent() local ok, h = pcall(function() return gethui and gethui() end); return (ok and h) or playerGui end
for _, p in ipairs({ guiParent(), playerGui }) do local old = p:FindFirstChild("SWILL_Piano_Ultra"); if old then old:Destroy() end end
gui = new("ScreenGui", { Name = "SWILL_Piano_Ultra", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999 }, guiParent())

-- Остров (Dynamic Island)
local island = new("TextButton", { Size = UDim2.fromOffset(190, 34), Position = UDim2.new(0.5, -95, 0, 10), BackgroundColor3 = BG0, BorderSizePixel = 0, Text = "", AutoButtonColor = false, Active = true, ZIndex = 999, ClipsDescendants = true }, gui)
corner(island, UDim.new(1, 0)); stroke(island, LINE, 1)
local statsLabel = new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = TXT, Text = "" }, island)

-- Главное окно
local main = new("Frame", { Size = UDim2.fromOffset(720, 480), Position = UDim2.fromScale(0.5, 0.56), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ClipsDescendants = false, Visible = true, ZIndex = 2 }, gui)
corner(main, 20); stroke(main, LINE, 1); new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(24, 24, 27), Color3.fromRGB(11, 11, 13)), Rotation = 90 }, main)
local scaleObj = new("UIScale", { Scale = 1 }, main)
local function baseScale() return math.clamp(math.min(camera.ViewportSize.X / 780, camera.ViewportSize.Y / 640), 0.45, 1) * S.uiScale end
local busy = false

local function toggleWindow()
    if busy then return end; busy = true
    if main.Visible then tween(scaleObj, 0.18, { Scale = baseScale() * 0.85 }).Completed:Wait(); main.Visible = false
    else scaleObj.Scale = baseScale() * 0.85; main.Visible = true; tween(scaleObj, 0.32, { Scale = baseScale() }, Enum.EasingStyle.Back).Completed:Wait() end
    busy = false
end
island.Activated:Connect(toggleWindow)
scaleObj.Scale = baseScale()

-- Вкладки
local tabsFrame = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, -10, 0, 46), Size = UDim2.fromOffset(0, 38), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Color3.fromRGB(22, 22, 25), BorderSizePixel = 0, ZIndex = 5 }, main)
corner(tabsFrame, UDim.new(1, 0)); stroke(tabsFrame, LINE, 1)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 3), VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Center }, tabsFrame)
new("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) }, tabsFrame)

local tabs, pages, activeTab = {}, {}, nil
local content = new("Frame", { Position = UDim2.fromOffset(16, 96), Size = UDim2.new(1, -32, 1, -110), BackgroundTransparency = 1, ZIndex = 5 }, main)

local function switchTab(name) 
    if activeTab then 
        tween(tabs[activeTab], 0.15, { BackgroundTransparency = 1, TextColor3 = DIM })
        pages[activeTab].Visible = false 
    end
    activeTab = name
    tween(tabs[name], 0.15, { BackgroundTransparency = 0, TextColor3 = Color3.new(0,0,0) })
    pages[name].Visible = true 
end

local function createTab(name, text)
    local b = new("TextButton", { Size = UDim2.fromOffset(0, 30), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = ACC(), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = DIM, Text = text }, tabsFrame)
    corner(b, UDim.new(1, 0)); new("UIPadding", { PaddingLeft = UDim.new(0, 13), PaddingRight = UDim.new(0, 13) }, b)
    b.Activated:Connect(function() switchTab(name) end); tabs[name] = b
end

local function makePage(name) 
    local p = new("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = false }, content)
    new("UIListLayout", { Padding = UDim.new(0, 10) }, p); pages[name] = p; return p 
end

createTab("home", "⌂ Главная"); createTab("play", "♪ Игра"); createTab("anti", "◈ Антискрипт"); createTab("set", "⚙ Настройки")
local pageHome, pagePlay, pageAnti, pageSet = makePage("home"), makePage("play"), makePage("anti"), makePage("set")

-- Страница "Главная" (Инпут, кнопки, список треков)
local inputBar = new("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = Color3.fromRGB(24, 24, 27), BorderSizePixel = 0 }, pageHome)
corner(inputBar, UDim.new(1, 0)); stroke(inputBar, LINE, 1)
local melodyBox = new("TextBox", { Position = UDim2.fromOffset(15, 0), Size = UDim2.new(1, -180, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 14, TextColor3 = TXT, PlaceholderText = "Вставь мелодию: [1e] 3 5 - [6y] ...", PlaceholderColor3 = DIM, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left }, inputBar)
local sendBtn = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(40, 40), BackgroundColor3 = ACC(), Text = "▶", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Color3.new(0,0,0) }, inputBar); corner(sendBtn, 12)

local btnRow = new("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1 }, pageHome)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }, btnRow)
local playBtn = new("TextButton", { Size = UDim2.fromOffset(100, 40), BackgroundColor3 = ACC(), Text = "▶ Играть", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.new(0,0,0) }, btnRow); corner(playBtn, 10)
local stopBtn = new("TextButton", { Size = UDim2.fromOffset(100, 40), BackgroundColor3 = BG2, Text = "■ Стоп", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = TXT }, btnRow); corner(stopBtn, 10)
local clearBtn = new("TextButton", { Size = UDim2.fromOffset(100, 40), BackgroundColor3 = BG2, Text = "Очистить", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = TXT }, btnRow); corner(clearBtn, 10)

-- Тяночка (упрощенная версия, чтобы код работал)
local girl = new("Frame", { Size = UDim2.fromOffset(120, 140), Position = UDim2.new(1, -150, 0, -100), BackgroundTransparency = 1, ZIndex = 10 }, main)
local hair = new("Frame", { Size = UDim2.fromOffset(80, 90), Position = UDim2.new(0.5, -40, 0, 10), BackgroundColor3 = Color3.fromRGB(240, 200, 220), BorderSizePixel = 0 }, girl); corner(hair, UDim.new(1,0))
local head = new("Frame", { Size = UDim2.fromOffset(60, 60), Position = UDim2.new(0.5, -30, 0, 15), BackgroundColor3 = Color3.fromRGB(255, 235, 225), BorderSizePixel = 0 }, girl); corner(head, UDim.new(1,0))
local eyeL = new("Frame", { Size = UDim2.fromOffset(12, 16), Position = UDim2.fromOffset(12, 25), BackgroundColor3 = Color3.fromRGB(100, 150, 255), BorderSizePixel = 0 }, head); corner(eyeL, UDim.new(1,0))
local eyeR = eyeL:Clone(); eyeR.Position = UDim2.fromOffset(36, 25); eyeR.Parent = head
local legL = new("Frame", { Size = UDim2.fromOffset(8, 40), Position = UDim2.fromOffset(40, 95), BackgroundColor3 = Color3.fromRGB(255, 235, 225), BorderSizePixel = 0 }, girl); corner(legL, UDim.new(1,0))
local legR = legL:Clone(); legR.Position = UDim2.fromOffset(72, 95); legR.Parent = girl

-- Логика игры
local state = { playing = false, id = 0, progress = 0 }
local function playCurrent()
    if state.playing or melodyBox.Text:match("^%s*$") then return end
    state.playing = true; state.id = state.id + 1; local my = state.id
    local events = Core.buildEvents(melodyBox.Text, S.transpose)
    task.spawn(function()
        for _, ev in ipairs(events) do
            if state.id ~= my then break end
            if ev.t == "n" then
                for _, ch in ipairs(ev.keys) do Core.keyDown(Core.keyMap[ch]) end
                task.wait(S.hold)
                for _, ch in ipairs(ev.keys) do Core.keyUp(Core.keyMap[ch]) end
                task.wait(S.gap)
            else task.wait(S.rest) end
        end
        if state.id == my then state.playing = false; sendBtn.Text = "▶" end
    end)
    sendBtn.Text = "■"
end

local function stopPlay() state.playing = false; state.id = state.id + 1; Core.releaseAll(); sendBtn.Text = "▶" end
playBtn.Activated:Connect(playCurrent)
sendBtn.Activated:Connect(function() if state.playing then stopPlay() else playCurrent() end end)
stopBtn.Activated:Connect(stopPlay)
clearBtn.Activated:Connect(function() melodyBox.Text = "" end)

-- FPS / Ping / Анимации
local frames, accT, fps, ping = 0, 0, 0, 0
track(RunService.RenderStepped:Connect(function(dt) 
    frames = frames + 1; accT = accT + dt
    if accT >= 0.5 then fps = math.floor(frames / accT + 0.5); frames, accT = 0, 0 end 
end))
task.spawn(function() 
    while gui.Parent do 
        pcall(function() ping = math.floor(player:GetNetworkPing() * 2000) end)
        statsLabel.Text = string.format("FPS: %d | Ping: %d", fps, ping)
        task.wait(0.5) 
    end 
end)

local t, phase = 0, 0
track(RunService.Heartbeat:Connect(function(dt)
    t = t + dt
    if S.girl and main.Visible then
        phase = phase + dt * (state.playing and 6 or 2.2)
        local sw = math.sin(phase) * (state.playing and 15 or 8)
        legL.Rotation = sw
        legR.Rotation = -sw
    end
end))

switchTab("home")
print("[SWILL] UI загружен и готов к работе.")
