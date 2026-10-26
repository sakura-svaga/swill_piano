--============================================================
--  SWILL • Piano UI (FULL UNLIMITED)
--============================================================
local Core = _G.SWILL_Core
if not Core then return warn("Ядро не загружено! Запустите piano_core.lua") end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Stats = game:GetService("Stats")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

-- Глобальные настройки
S = {
    speed = 1, tempo = 50, hold = 0.09, rest = 0.22, gap = 0.05,
    transpose = 0, countdown = 0, loop = false, shuffle = false,
    anti = false, antiMin = 8, antiMax = 35, antiCap = 90,
    antiTiming = 18, antiHold = 15, antiOrder = true, antiSmart = true,
    particles = true, girl = true, doodles = true, autohide = false,
    hotkeys = true, islandStats = true, antiAfk = true,
    uiScale = 1, accent = 1, girlName = "Саша",
}
savedSongs = Core.loadSongs()
rnd = Random.new()
conns = {}
function track(c) conns[#conns + 1] = c return c end

BG0, BG1, BG2 = Color3.fromRGB(15, 15, 17), Color3.fromRGB(28, 28, 32), Color3.fromRGB(42, 42, 47)
BUB, TXT, DIM, LINE = Color3.fromRGB(38, 38, 43), Color3.fromRGB(228, 228, 233), Color3.fromRGB(136, 136, 146), Color3.fromRGB(56, 56, 62)

ACCENTS = {
    { name = "Золото", c = Color3.fromRGB(201, 162, 39) },
    { name = "Роза",   c = Color3.fromRGB(255, 138, 178) },
    { name = "Небо",   c = Color3.fromRGB(96, 160, 255) },
    { name = "Мята",   c = Color3.fromRGB(110, 222, 170) },
}
function ACC() return ACCENTS[S.accent].c end

gui = nil
accRefs = {}
function acc(obj, prop) accRefs[#accRefs + 1] = { obj, prop }; obj[prop] = ACC(); return obj end
function new(class, props, parent) local o = Instance.new(class); for k, v in pairs(props) do o[k] = v end; if parent then o.Parent = parent end; return o end
function corner(o, r) return new("UICorner", { CornerRadius = typeof(r) == "UDim" and r or UDim.new(0, r) }, o) end
function stroke(o, c, th) return new("UIStroke", { Color = c or LINE, Thickness = th or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o) end
function tween(o, t, props, style, dir) local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props); tw:Play(); return tw end

function guiParent() local ok, h = pcall(function() return gethui and gethui() end); return (ok and h) or playerGui end
for _, p in ipairs({ guiParent(), playerGui }) do local old = p:FindFirstChild("SWILL_Piano_Ultra"); if old then old:Destroy() end end
gui = new("ScreenGui", { Name = "SWILL_Piano_Ultra", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999 }, guiParent())

--============================================================
-- ОСТРОВ (Dynamic Island)
--============================================================
island = new("TextButton", { Size = UDim2.fromOffset(190, 34), Position = UDim2.new(0.5, -95, 0, 10), BackgroundColor3 = BG0, BorderSizePixel = 0, Text = "", AutoButtonColor = false, Active = true, ZIndex = 999, ClipsDescendants = true }, gui)
corner(island, UDim.new(1, 0)); stroke(island, LINE, 1)
statsLabel = new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = TXT, Text = "" }, island)

pg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false }, island)
cover = new("Frame", { Position = UDim2.fromOffset(10, 9), Size = UDim2.fromOffset(32, 32), BorderSizePixel = 0 }, pg); acc(cover, "BackgroundColor3"); corner(cover, 9)
new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 17, TextColor3 = Color3.fromRGB(20, 20, 22), Text = "♪" }, cover)
titleClip = new("Frame", { Position = UDim2.fromOffset(52, 7), Size = UDim2.fromOffset(186, 18), BackgroundTransparency = 1, ClipsDescendants = true }, pg)
titleLbl = new("TextLabel", { Size = UDim2.fromOffset(0, 18), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = TXT, TextXAlignment = Enum.TextXAlignment.Left, Text = "" }, titleClip)
subLbl = new("TextLabel", { Position = UDim2.fromOffset(52, 25), Size = UDim2.fromOffset(186, 14), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Left, Text = "" }, pg)
eqBars = {}
for i = 1, 4 do local b = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromOffset(264 + (i - 1) * 8, 36), Size = UDim2.fromOffset(5, 6), BorderSizePixel = 0 }, pg); acc(b, "BackgroundColor3"); corner(b, 2); eqBars[i] = b end
progTrack = new("Frame", { Position = UDim2.fromOffset(52, 43), Size = UDim2.fromOffset(244, 3), BackgroundColor3 = BG2, BorderSizePixel = 0 }, pg); corner(progTrack, UDim.new(1, 0))
progFill = new("Frame", { Size = UDim2.fromScale(0, 1), BorderSizePixel = 0 }, progTrack); acc(progFill, "BackgroundColor3"); corner(progFill, UDim.new(1, 0))

islandPlaying = false
function setIslandPlaying(on)
    if on == islandPlaying then return end; islandPlaying = on
    if on then statsLabel.Visible = false; pg.Visible = true; tween(island, 0.38, { Size = UDim2.fromOffset(310, 50), Position = UDim2.new(0.5, -155, 0, 8) }, Enum.EasingStyle.Back)
    else pg.Visible = false; statsLabel.Visible = true; tween(island, 0.25, { Size = UDim2.fromOffset(190, 34), Position = UDim2.new(0.5, -95, 0, 10) }) end
end

--============================================================
-- ГЛАВНОЕ ОКНО
--============================================================
WIN_W, WIN_H = 720, 480
main = new("Frame", { Size = UDim2.fromOffset(WIN_W, WIN_H), Position = UDim2.fromScale(0.5, 0.56), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ClipsDescendants = false, Visible = false, ZIndex = 2 }, gui)
corner(main, 20); stroke(main, LINE, 1); new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(24, 24, 27), Color3.fromRGB(11, 11, 13)), Rotation = 90 }, main)
scaleObj = new("UIScale", { Scale = 1 }, main)
function baseScale() return math.clamp(math.min(camera.ViewportSize.X / 780, camera.ViewportSize.Y / 640), 0.45, 1) * S.uiScale end
busy = false
function toggleWindow()
    if busy then return end; busy = true
    if main.Visible then tween(scaleObj, 0.18, { Scale = baseScale() * 0.85 }).Completed:Wait(); main.Visible = false
    else scaleObj.Scale = baseScale() * 0.85; main.Visible = true; tween(scaleObj, 0.32, { Scale = baseScale() }, Enum.EasingStyle.Back).Completed:Wait() end
    busy = false
end
island.Activated:Connect(toggleWindow)

bgClip = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 1 }, main); corner(bgClip, 20)
doodleFolder = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, bgClip)

header = new("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Active = true, ZIndex = 5 }, main)
new("TextLabel", { Size = UDim2.fromOffset(180, 24), Position = UDim2.fromOffset(22, 12), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = DIM, Text = "SWILL • Piano" }, header)
function winBtn(text, xOff)
    local b = new("TextButton", { Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, xOff, 0, 12), BackgroundColor3 = BG1, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = DIM, Text = text, AutoButtonColor = true }, header)
    corner(b, UDim.new(1, 0)); return b
end
minBtn = winBtn("–", -114); sizeBtn = winBtn("□", -78); closeBtn = winBtn("✕", -42)

dragging, dragStart, startPos = false, nil, nil
track(header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, startPos = true, input.Position, main.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end))
track(UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = (input.Position - dragStart) / scaleObj.Scale
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end))
minBtn.Activated:Connect(toggleWindow); closeBtn.Activated:Connect(toggleWindow)

--============================================================
-- ТЯНОЧКА (Пиксельная)
--============================================================
PX = 4
gp = { O = Color3.fromRGB(78, 64, 82), H = Color3.fromRGB(248, 236, 218), h = Color3.fromRGB(222, 200, 184), g = Color3.fromRGB(196, 170, 160), S = Color3.fromRGB(255, 232, 220), s = Color3.fromRGB(240, 205, 195), E = Color3.fromRGB(92, 150, 255), e = Color3.fromRGB(170, 212, 255), D = Color3.fromRGB(40, 44, 90), W = Color3.fromRGB(252, 252, 255), w = Color3.fromRGB(206, 212, 230), K = Color3.fromRGB(58, 60, 84), k = Color3.fromRGB(84, 88, 118), B = Color3.fromRGB(96, 160, 255), P = Color3.fromRGB(255, 160, 160), M = Color3.fromRGB(214, 110, 120) }
rep = string.rep
girlRows = { "OO", "OHHO", rep("O", 8), "OO"..rep("H", 8).."OO", "O".."HH".."BB"..rep("H", 8).."O", "O"..rep("H", 14).."O", "O".."HHH".."h"..rep("H", 6).."h".."HHH".."O", "O"..rep("H", 5).."SS".."HH".."SS"..rep("H", 5).."O", "O"..rep("H", 4)..rep("S", 8)..rep("H", 4).."O", "O"..rep("H", 3)..rep("S", 10)..rep("H", 3).."O", "O"..rep("H", 3)..rep("S", 10)..rep("H", 3).."O", "O".."HHH".."SDDDSSDDDS".."HHH".."O", "O".."HHH".."SeDESSeDES".."HHH".."O", "O".."HHH".."SEEESSEEES".."HHH".."O", "O".."HHH".."PPSSSSSSPP".."HHH".."O", "O".."hHH".."SSSSMMSSSS".."HHh".."O", "O".."hHHH".."sSSSSSSs".."HHHh".."O", "OhHH"..".".."sSSSSs"..".".."HHhO", "OhH".."...".."sSSs".."...".."HhO", "ghH"..rep(".", 4).."sSSs"..rep(".", 4).."Hhg", "wWWWBBWWWw", "SwWWWBBWWWwS", "S".."w"..rep("W", 8).."w".."S", "sSWWKKKKWWSs", "k"..rep("K", 10).."k", "k"..rep("K", 12).."k", "k"..rep("K", 14).."k", "WwWwWwWwWwWwWwWw" }
ROWS, COLS = #girlRows, 22
girlBaseY = -ROWS * PX + 2
girl = new("Frame", { Size = UDim2.fromOffset(COLS * PX, ROWS * PX), Position = UDim2.new(0, WIN_W - 235, 0, girlBaseY), BackgroundTransparency = 1, ZIndex = 20 }, main)
function makeLeg(col)
    local c = new("Frame", { Size = UDim2.fromOffset(3 * PX, 14 * PX), Position = UDim2.fromOffset(col * PX, ROWS * PX - 7 * PX - 2), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1 }, girl)
    new("Frame", { Position = UDim2.fromOffset(0, 7 * PX), Size = UDim2.fromOffset(3 * PX, 5 * PX), BackgroundColor3 = gp.S, BorderSizePixel = 0 }, c)
    new("Frame", { Position = UDim2.fromOffset(0, 12 * PX), Size = UDim2.fromOffset(3 * PX + 2, 2 * PX), BackgroundColor3 = gp.k, BorderSizePixel = 0 }, c)
    return c
end
legL, legR = makeLeg(7), makeLeg(12)
sprite = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2 }, girl)
for y, row in ipairs(girlRows) do
    local pad = math.floor((COLS - #row) / 2)
    local x = 1
    while x <= #row do
        local ch = row:sub(x, x)
        if ch ~= "." then
            local e = x
            while e < #row and row:sub(e + 1, e + 1) == ch do e = e + 1 end
            new("Frame", { Position = UDim2.fromOffset((pad + x - 1) * PX, (y - 1) * PX), Size = UDim2.fromOffset((e - x + 1) * PX, PX), BackgroundColor3 = gp[ch], BorderSizePixel = 0 }, sprite)
            x = e + 1
        else x = x + 1 end
    end
end

--============================================================
-- ТАБЫ
--============================================================
tabsFrame = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, -10, 0, 46), Size = UDim2.fromOffset(0, 38), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Color3.fromRGB(22, 22, 25), BorderSizePixel = 0, ZIndex = 5 }, main)
corner(tabsFrame, UDim.new(1, 0)); stroke(tabsFrame, LINE, 1)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 3), VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Center }, tabsFrame)
new("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) }, tabsFrame)

content = new("Frame", { Position = UDim2.fromOffset(16, 96), Size = UDim2.new(1, -32, 1, -110), BackgroundTransparency = 1, ZIndex = 5 }, main)
tabs, pages, activeTab = {}, {}, nil
function switchTab(name)
    if activeTab then tabs[activeTab].TextColor3 = DIM; tabs[activeTab].BackgroundTransparency = 1; pages[activeTab].Visible = false end
    activeTab = name; tabs[name].TextColor3 = TXT; tabs[name].BackgroundTransparency = 0; pages[name].Visible = true
end
function createTab(name, text)
    local b = new("TextButton", { Size = UDim2.fromOffset(0, 30), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = BG2, BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = DIM, Text = text }, tabsFrame)
    corner(b, UDim.new(1, 0)); new("UIPadding", { PaddingLeft = UDim.new(0, 13), PaddingRight = UDim.new(0, 13) }, b)
    b.Activated:Connect(function() switchTab(name) end); tabs[name] = b
end
function makePage(name)
    local p = new("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = false }, content)
    new("UIListLayout", { Padding = UDim.new(0, 10) }, p); pages[name] = p; return p
end
createTab("home", "⌂ Главная"); createTab("play", "♪ Игра"); createTab("anti", "◈ Антискрипт"); createTab("set", "⚙ Настройки")
pageHome, pagePlay, pageAnti, pageSet = makePage("home"), makePage("play"), makePage("anti"), makePage("set")

-- Главная (Чат)
chatArea = new("Frame", { Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 1, -100), BackgroundTransparency = 1 }, pageHome)
chatScroll = new("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = LINE, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, chatArea)
new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, chatScroll)
msgOrder, msgRows = 0, {}
function addMsg(who, text)
    msgOrder = msgOrder + 1
    local row = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = msgOrder }, chatScroll)
    new("UIListLayout", { HorizontalAlignment = who == "user" and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left }, row)
    local bub = new("Frame", { Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = BUB, BackgroundTransparency = 1, BorderSizePixel = 0 }, row)
    corner(bub, 16); new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }, bub)
    local lbl = new("TextLabel", { Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 14, TextColor3 = TXT, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, Text = text }, bub)
    tween(bub, 0.22, { BackgroundTransparency = 0 }); tween(lbl, 0.22, { TextTransparency = 0 })
    msgRows[#msgRows + 1] = row; if #msgRows > 40 then table.remove(msgRows, 1):Destroy() end
    task.delay(0.06, function() chatScroll.CanvasPosition = Vector2.new(0, 99999) end)
    return lbl
end
function say(text) return addMsg("bot", text) end

inputBar = new("Frame", { Position = UDim2.new(0, 0, 1, -52), Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = Color3.fromRGB(24, 24, 27), BorderSizePixel = 0 }, pageHome)
corner(inputBar, UDim.new(1, 0)); stroke(inputBar, LINE, 1)
melodyBox = new("TextBox", { Position = UDim2.fromOffset(15, 0), Size = UDim2.new(1, -180, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 14, TextColor3 = TXT, PlaceholderText = "Вставь мелодию...", PlaceholderColor3 = DIM, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left }, inputBar)
sendBtn = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(40, 40), BackgroundColor3 = ACC(), Text = "▶", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Color3.new(0,0,0) }, inputBar); corner(sendBtn, 12)
playBtn = new("TextButton", { Size = UDim2.fromOffset(100, 40), BackgroundColor3 = ACC(), Text = "▶ Играть", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.new(0,0,0) }, pageHome); corner(playBtn, 10)
stopBtn = new("TextButton", { Size = UDim2.fromOffset(100, 40), BackgroundColor3 = BG2, Text = "■ Стоп", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = TXT }, pageHome); corner(stopBtn, 10)
clearBtn = new("TextButton", { Size = UDim2.fromOffset(100, 40), BackgroundColor3 = BG2, Text = "Очистить", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = TXT }, pageHome); corner(clearBtn, 10)
clearBtn.Activated:Connect(function() melodyBox.Text = "" end)

-- Страница "Игра"
function addSlider(parent, key, label, min, max)
    local f = new("Frame", { Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = BG1, BorderSizePixel = 0 }, parent); corner(f, 10)
    local lbl = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 5), Size = UDim2.new(1, 0, 0, 20), Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = TXT, Text = label }, f)
    local val = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(1, -80, 0, 5), Size = UDim2.fromOffset(70, 20), Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = ACC(), Text = tostring(S[key]) }, f)
    local bar = new("TextButton", { Position = UDim2.fromOffset(10, 35), Size = UDim2.new(1, -20, 0, 6), BackgroundColor3 = BG2, Text = "" }, f); corner(bar, UDim.new(1,0))
    local fill = new("Frame", { Size = UDim2.fromScale((S[key] - min) / (max - min), 1), BackgroundColor3 = ACC() }, bar); corner(fill, UDim.new(1,0))
    bar.MouseButton1Click:Connect(function() S[key] = math.floor(min + (max - min) * 0.5); val.Text = tostring(S[key]); fill.Size = UDim2.fromScale(0.5, 1) end)
end
addSlider(pagePlay, "tempo", "Темп (мс)", 10, 300)
addSlider(pagePlay, "speed", "Скорость", 0.5, 2)
addSlider(pagePlay, "transpose", "Транспонирование", -12, 12)

-- Запуск игры
state = { playing = false, id = 0, progress = 0 }
function playCurrent()
    if state.playing or melodyBox.Text:match("^%s*$") then return end
    state.playing = true; state.id = state.id + 1; local my = state.id
    local events = Core.buildEvents(melodyBox.Text, S.transpose)
    setIslandPlaying(true)
    titleLbl.Text = "Мелодия"; subLbl.Text = "Играет..."
    task.spawn(function()
        for i, ev in ipairs(events) do
            if state.id ~= my then break end
            state.progress = i / #events
            if ev.t == "n" then
                for _, ch in ipairs(ev.keys) do Core.keyDown(Core.keyMap[ch]) end
                task.wait(S.hold)
                for _, ch in ipairs(ev.keys) do Core.keyUp(Core.keyMap[ch]) end
                task.wait(S.gap)
            else task.wait(S.rest) end
        end
        if state.id == my then state.playing = false; setIslandPlaying(false); sendBtn.Text = "▶" end
    end)
    sendBtn.Text = "■"
end
function stopPlay() state.playing = false; state.id = state.id + 1; Core.releaseAll(); setIslandPlaying(false); sendBtn.Text = "▶" end
playBtn.Activated:Connect(playCurrent); stopBtn.Activated:Connect(stopPlay); sendBtn.Activated:Connect(function() if state.playing then stopPlay() else playCurrent() end end)

-- Анимации
t, phase = 0, 0
track(RunService.Heartbeat:Connect(function(dt)
    t = t + dt
    if S.girl and main.Visible then
        phase = phase + dt * (state.playing and 6 or 2.2)
        local sw = math.sin(phase) * (state.playing and 15 or 8)
        legL.Rotation = sw; legR.Rotation = -sw
    end
end))

switchTab("home")
scaleObj.Scale = baseScale()
say("Привет! Я " .. S.girlName .. ". Вставь мелодию, и я всё сыграю.")
print("[SWILL] UI Полностью загружен. Все вкладки на месте.")
