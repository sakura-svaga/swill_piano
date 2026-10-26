--============================================================
--  SWILL • Piano Ultra v3 (FIXED)
--  Исправлены ошибки слайдера, FPS и зависаний
--============================================================

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local VIM          = game:GetService("VirtualInputManager")
local RunService   = game:GetService("RunService")
local HttpService  = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Stats        = game:GetService("Stats")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera    = workspace.CurrentCamera

pcall(function() if getgenv and getgenv().SWILL_UNLOAD then getgenv().SWILL_UNLOAD() end end)

local conns = {}
local function track(c) conns[#conns + 1] = c return c end
local rnd = Random.new()

--============================================================
--  НАСТРОЙКИ
--============================================================
local SETTINGS_FILE = "SWILL_Piano_Settings.json"
local SONGS_FILE    = "SWILL_Piano_Songs.json"

local defaults = {
    speed = 1, tempo = 50, hold = 0.09, rest = 0.22, gap = 0.05,
    transpose = 0, countdown = 0, loop = false, shuffle = false,
    anti = false, antiMin = 8, antiMax = 35, antiCap = 90,
    antiTiming = 18, antiHold = 15, antiOrder = true, antiSmart = true,
    particles = true, girl = true, doodles = true, autohide = false,
    hotkeys = true, islandStats = true, antiAfk = true,
    uiScale = 1, accent = 1, girlName = "Саша",
}
local S = {}
for k, v in pairs(defaults) do S[k] = v end
pcall(function()
    if isfile and isfile(SETTINGS_FILE) then
        local d = HttpService:JSONDecode(readfile(SETTINGS_FILE))
        if type(d) == "table" then
            for k, v in pairs(d) do
                if defaults[k] ~= nil and type(v) == type(defaults[k]) then S[k] = v end
            end
        end
    end
end)
S.accent = math.clamp(math.floor(S.accent), 1, 4)

local saveQueued = false
local function queueSave()
    if saveQueued then return end
    saveQueued = true
    task.delay(0.6, function()
        saveQueued = false
        pcall(function() if writefile then writefile(SETTINGS_FILE, HttpService:JSONEncode(S)) end end)
    end)
end

local savedSongs = {}
pcall(function()
    if isfile and isfile(SONGS_FILE) then
        local d = HttpService:JSONDecode(readfile(SONGS_FILE))
        if type(d) == "table" then savedSongs = d end
    end
end)
local function saveSongs()
    pcall(function() if writefile then writefile(SONGS_FILE, HttpService:JSONEncode(savedSongs)) end end)
end

--============================================================
--  ЦВЕТА И ХЕЛПЕРЫ
--============================================================
local BG0  = Color3.fromRGB(15, 15, 17)
local BG1  = Color3.fromRGB(28, 28, 32)
local BG2  = Color3.fromRGB(42, 42, 47)
local BUB  = Color3.fromRGB(38, 38, 43)
local TXT  = Color3.fromRGB(228, 228, 233)
local DIM  = Color3.fromRGB(136, 136, 146)
local LINE = Color3.fromRGB(56, 56, 62)

local ACCENTS = {
    { name = "Золото", c = Color3.fromRGB(201, 162, 39) },
    { name = "Роза",   c = Color3.fromRGB(255, 138, 178) },
    { name = "Небо",   c = Color3.fromRGB(96, 160, 255) },
    { name = "Мята",   c = Color3.fromRGB(110, 222, 170) },
}
local function ACC() return ACCENTS[S.accent].c end

local gui
local accRefs = {}
local function acc(obj, prop)
    accRefs[#accRefs + 1] = { obj, prop }
    obj[prop] = ACC()
    return obj
end

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end
local function corner(o, r)
    return new("UICorner", { CornerRadius = typeof(r) == "UDim" and r or UDim.new(0, r) }, o)
end
local function stroke(o, c, th)
    return new("UIStroke", { Color = c or LINE, Thickness = th or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
end
local function tween(o, t, props, style, dir)
    local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

--============================================================
--  КЛАВИШИ И ПАРСЕР
--============================================================
local keyMap = {}
for _, L in ipairs({"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"}) do
    keyMap[L:lower()] = { key = Enum.KeyCode[L], shift = false }
    keyMap[L]         = { key = Enum.KeyCode[L], shift = true  }
end
local digitNames = {"Zero","One","Two","Three","Four","Five","Six","Seven","Eight","Nine"}
for i = 0, 9 do keyMap[tostring(i)] = { key = Enum.KeyCode[digitNames[i + 1]], shift = false } end
keyMap["!"] = { key = Enum.KeyCode.One,   shift = true }
keyMap["@"] = { key = Enum.KeyCode.Two,   shift = true }
keyMap["$"] = { key = Enum.KeyCode.Four,  shift = true }
keyMap["%"] = { key = Enum.KeyCode.Five,  shift = true }
keyMap["^"] = { key = Enum.KeyCode.Six,   shift = true }
keyMap["*"] = { key = Enum.KeyCode.Eight, shift = true }
keyMap["("] = { key = Enum.KeyCode.Nine,  shift = true }
keyMap["-"]  = { key = Enum.KeyCode.Minus,        shift = false }
keyMap["="]  = { key = Enum.KeyCode.Equals,       shift = false }
keyMap["["]  = { key = Enum.KeyCode.LeftBracket,  shift = false }
keyMap["]"]  = { key = Enum.KeyCode.RightBracket, shift = false }
keyMap[";"]  = { key = Enum.KeyCode.Semicolon,    shift = false }
keyMap["'"]  = { key = Enum.KeyCode.Quote,        shift = false }
keyMap[","]  = { key = Enum.KeyCode.Comma,        shift = false }
keyMap["."]  = { key = Enum.KeyCode.Period,       shift = false }
keyMap["/"]  = { key = Enum.KeyCode.Slash,        shift = false }
keyMap["\\"] = { key = Enum.KeyCode.BackSlash,    shift = false }
keyMap["`"]  = { key = Enum.KeyCode.Backquote,    shift = false }

local SEQ = "1!2@34$5%6^78*9(0qQwWeErtTyYuiIoOpPasSdDfgGhHjJklLzZxcCvVbBnm"
local SEQ_IDX = {}
for i = 1, #SEQ do SEQ_IDX[SEQ:sub(i, i)] = i end

local function transposeChars(str, n)
    if n == 0 then return str end
    return (str:gsub(".", function(ch)
        local i = SEQ_IDX[ch]
        if not i then return ch end
        local j = i + n
        while j < 1 do j = j + 12 end
        while j > #SEQ do j = j - 12 end
        return SEQ:sub(j, j)
    end))
end

local held = {}
local function keyDown(info)
    if info.shift then VIM:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game) end
    VIM:SendKeyEvent(true, info.key, false, game)
    if info.shift then VIM:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game) end
    held[info.key] = true
end
local function keyUp(info)
    VIM:SendKeyEvent(false, info.key, false, game)
    held[info.key] = nil
end
local function releaseAll()
    for k in pairs(held) do VIM:SendKeyEvent(false, k, false, game) end
    held = {}
end

local function parseSong(str)
    local tokens, i, n = {}, 1, #str
    while i <= n do
        local c = str:sub(i, i)
        if c == "[" then
            local j = str:find("]", i, true)
            if j then table.insert(tokens, { chord = str:sub(i + 1, j - 1) }); i = j + 1
            else i = i + 1 end
        elseif c:match("%s") then i = i + 1
        else
            local j = i
            while j <= n and not str:sub(j, j):match("%s") and str:sub(j, j) ~= "[" do j = j + 1 end
            table.insert(tokens, { note = str:sub(i, j - 1) })
            i = j
        end
    end
    return tokens
end

local function buildEvents(text, trans)
    local events, skipped = {}, 0
    for _, tk in ipairs(parseSong(text)) do
        if tk.chord then
            local s, valid = transposeChars(tk.chord, trans), {}
            for ch in s:gmatch(".") do
                if keyMap[ch] then valid[#valid + 1] = ch else skipped = skipped + 1 end
            end
            if #valid > 0 then events[#events + 1] = { t = "n", keys = valid } end
        elseif tk.note == "-" or tk.note == "|" then
            events[#events + 1] = { t = "r" }
        else
            for ch in transposeChars(tk.note, trans):gmatch(".") do
                if ch == "-" or ch == "|" then events[#events + 1] = { t = "r" }
                elseif keyMap[ch] then events[#events + 1] = { t = "n", keys = { ch } }
                else skipped = skipped + 1 end
            end
        end
    end
    return events, skipped
end

local function noteDur() return (S.hold + S.gap + S.tempo / 1000) / S.speed end
local function restDur() return (S.rest + S.gap + S.tempo / 1000) / S.speed end

local function readClipboard()
    local fns = {
        function() return getclipboard() end,
        function() return syn.get_clipboard() end,
        function() return get_clipboard() end,
        function() return readclipboard() end,
    }
    for _, f in ipairs(fns) do
        local ok, v = pcall(f)
        if ok and type(v) == "string" and v ~= "" then return v end
    end
    return nil
end

--============================================================
--  GUI ROOT
--============================================================
local function guiParent()
    local ok, h = pcall(function() return gethui and gethui() end)
    return (ok and h) or playerGui
end
for _, p in ipairs({ guiParent(), playerGui }) do
    local old = p:FindFirstChild("SWILL_Piano_Ultra")
    if old then old:Destroy() end
end
gui = new("ScreenGui", {
    Name = "SWILL_Piano_Ultra", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
}, guiParent())

--============================================================
--  ОСТРОВ
--============================================================
local island = new("TextButton", {
    Size = UDim2.fromOffset(190, 34), Position = UDim2.new(0.5, -95, 0, 10),
    BackgroundColor3 = BG0, BorderSizePixel = 0, Text = "", AutoButtonColor = false,
    Active = true, ZIndex = 999, ClipsDescendants = true,
}, gui)
corner(island, UDim.new(1, 0))
stroke(island, LINE, 1)

local statsLabel = new("TextLabel", {
    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
    TextSize = 12, TextColor3 = TXT, Text = "FPS: 0 | Ping: 0",
}, island)

local pg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false }, island)
local cover = new("Frame", { Position = UDim2.fromOffset(10, 9), Size = UDim2.fromOffset(32, 32), BorderSizePixel = 0 }, pg)
acc(cover, "BackgroundColor3")
corner(cover, 9)
new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 17, TextColor3 = Color3.fromRGB(20, 20, 22), Text = "♪" }, cover)

local titleClip = new("Frame", { Position = UDim2.fromOffset(52, 7), Size = UDim2.fromOffset(186, 18), BackgroundTransparency = 1, ClipsDescendants = true }, pg)
local titleLbl = new("TextLabel", { Size = UDim2.fromOffset(0, 18), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = TXT, TextXAlignment = Enum.TextXAlignment.Left, Text = "" }, titleClip)
local subLbl = new("TextLabel", { Position = UDim2.fromOffset(52, 25), Size = UDim2.fromOffset(186, 14), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Left, Text = "" }, pg)

local eqBars = {}
for i = 1, 4 do
    local b = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromOffset(264 + (i - 1) * 8, 36), Size = UDim2.fromOffset(5, 6), BorderSizePixel = 0 }, pg)
    acc(b, "BackgroundColor3")
    corner(b, 2)
    eqBars[i] = b
end

local progTrack = new("Frame", { Position = UDim2.fromOffset(52, 43), Size = UDim2.fromOffset(244, 3), BackgroundColor3 = BG2, BorderSizePixel = 0 }, pg)
corner(progTrack, UDim.new(1, 0))
local progFill = new("Frame", { Size = UDim2.fromScale(0, 1), BorderSizePixel = 0 }, progTrack)
acc(progFill, "BackgroundColor3")
corner(progFill, UDim.new(1, 0))

local islandPlaying = false
local function setIslandPlaying(on)
    if on == islandPlaying then return end
    islandPlaying = on
    if on then
        statsLabel.Visible = false
        pg.Visible = true
        tween(island, 0.38, { Size = UDim2.fromOffset(310, 50), Position = UDim2.new(0.5, -155, 0, 8) }, Enum.EasingStyle.Back)
    else
        pg.Visible = false
        statsLabel.Visible = true
        tween(island, 0.25, { Size = UDim2.fromOffset(190, 34), Position = UDim2.new(0.5, -95, 0, 10) })
    end
end

--============================================================
--  ГЛАВНОЕ ОКНО
--============================================================
local WIN_W, WIN_H = 720, 480
local main = new("Frame", {
    Size = UDim2.fromOffset(WIN_W, WIN_H), Position = UDim2.fromScale(0.5, 0.56),
    AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
    ClipsDescendants = false, Visible = false, ZIndex = 2,
}, gui)
corner(main, 20)
stroke(main, LINE, 1)
new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(24, 24, 27), Color3.fromRGB(11, 11, 13)), Rotation = 90 }, main)
local scaleObj = new("UIScale", { Scale = 1 }, main)

local function baseScale()
    local v = camera.ViewportSize
    return math.clamp(math.min(v.X / 780, v.Y / 640), 0.45, 1) * S.uiScale
end

local busy = false
local function toggleWindow()
    if busy then return end
    busy = true
    if main.Visible then
        tween(scaleObj, 0.18, { Scale = baseScale() * 0.85 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In).Completed:Wait()
        main.Visible = false
    else
        scaleObj.Scale = baseScale() * 0.85
        main.Visible = true
        tween(scaleObj, 0.32, { Scale = baseScale() }, Enum.EasingStyle.Back, Enum.EasingDirection.Out).Completed:Wait()
    end
    busy = false
end
island.Activated:Connect(toggleWindow)

--============================================================
--  ФОН И ЧАСТИЦЫ
--============================================================
local bgClip = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 1 }, main)
corner(bgClip, 20)
local doodleFolder = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, bgClip)
local DOOD = Color3.fromRGB(92, 92, 102)
local glyphs = {"♡", "☆", "♪", "?", "!!", "zzz", "hi", "ok", "hmm...", "✧", "♫", "?!", "♡", "☆", "~"}
for _ = 1, 24 do
    local l = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(70, 40), AnchorPoint = Vector2.new(0.5, 0.5), Text = glyphs[rnd:NextInteger(1, #glyphs)], Font = Enum.Font.PatrickHand, TextSize = rnd:NextInteger(20, 40), TextColor3 = DOOD, TextTransparency = 0.6 }, doodleFolder)
    l.Position = UDim2.new(rnd:NextNumber(0.05, 0.95), 0, rnd:NextNumber(0.15, 0.95), 0)
end

--============================================================
--  ШАПКА
--============================================================
local header = new("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Active = true, ZIndex = 5 }, main)
new("TextLabel", { Size = UDim2.fromOffset(180, 24), Position = UDim2.fromOffset(22, 12), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = DIM, Text = "SWILL • Piano" }, header)

local function winBtn(text, xOff)
    local b = new("TextButton", { Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, xOff, 0, 12), BackgroundColor3 = BG1, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = DIM, Text = text, AutoButtonColor = true }, header)
    corner(b, UDim.new(1, 0))
    return b
end
local minBtn   = winBtn("–", -114)
local closeBtn = winBtn("✕", -42)
closeBtn.Activated:Connect(toggleWindow)

--============================================================
--  ПИКСЕЛЬНАЯ ТЯНОЧКА (Упрощенная для стабильности)
--============================================================
local girl = new("Frame", { Size = UDim2.fromOffset(60, 70), Position = UDim2.new(0, WIN_W - 120, 0, -65), BackgroundTransparency = 1, ZIndex = 20 }, main)
local hair = new("Frame", { Size = UDim2.fromOffset(50, 50), Position = UDim2.new(0.5, -25, 0, 0), BackgroundColor3 = Color3.fromRGB(240, 200, 220), BorderSizePixel = 0 }, girl)
corner(hair, UDim.new(1,0))
local face = new("Frame", { Size = UDim2.fromOffset(40, 40), Position = UDim2.new(0.5, -20, 0, 6), BackgroundColor3 = Color3.fromRGB(255, 225, 205), BorderSizePixel = 0 }, girl)
corner(face, UDim.new(1,0))
local legL = new("Frame", { Size = UDim2.fromOffset(8, 30), Position = UDim2.new(0.5, -12, 0, 50), BackgroundColor3 = Color3.fromRGB(255, 225, 205), BorderSizePixel = 0 }, girl)
local legR = new("Frame", { Size = UDim2.fromOffset(8, 30), Position = UDim2.new(0.5, 4, 0, 50), BackgroundColor3 = Color3.fromRGB(255, 225, 205), BorderSizePixel = 0 }, girl)
corner(legL, 4); corner(legR, 4)

--============================================================
--  ТАБЫ
--============================================================
local tabsFrame = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, -10, 0, 46), Size = UDim2.fromOffset(0, 38), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Color3.fromRGB(22, 22, 25), BorderSizePixel = 0, ZIndex = 5 }, main)
corner(tabsFrame, UDim.new(1, 0))
stroke(tabsFrame, LINE, 1)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 3), VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Center }, tabsFrame)
new("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) }, tabsFrame)

local content = new("Frame", { Position = UDim2.fromOffset(16, 96), Size = UDim2.new(1, -32, 1, -110), BackgroundTransparency = 1, ZIndex = 5 }, main)
local tabs, pages, activeTab = {}, {}, nil
local orders = {}
local function nextOrder(p) orders[p] = (orders[p] or 0) + 1 return orders[p] end

local function makePage(name)
    local p = new("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = LINE, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = false }, content)
    new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, p)
    pages[name] = p
    return p
end

local function switchTab(name)
    if activeTab then
        tween(tabs[activeTab], 0.15, { BackgroundTransparency = 1, TextColor3 = DIM })
        pages[activeTab].Visible = false
    end
    activeTab = name
    tween(tabs[name], 0.15, { BackgroundTransparency = 0, TextColor3 = TXT })
    pages[name].Visible = true
end

local function createTab(name, text, order)
    local b = new("TextButton", { Size = UDim2.fromOffset(0, 30), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = BG2, BackgroundTransparency = 1, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = DIM, Text = text, LayoutOrder = order, AutoButtonColor = false }, tabsFrame)
    corner(b, UDim.new(1, 0))
    new("UIPadding", { PaddingLeft = UDim.new(0, 13), PaddingRight = UDim.new(0, 13) }, b)
    b.Activated:Connect(function() switchTab(name) end)
    tabs[name] = b
end
createTab("home", "⌂ Главная", 1)
createTab("play", "♪ Игра", 2)
createTab("anti", "◈ Антискрипт", 3)
createTab("set", "⚙ Настройки", 4)

--============================================================
--  НАСТРОЙКИ (КОНТРОЛЫ)
--============================================================
local controls = {}
local applyAll = function() end

local function section(parent, text)
    new("TextLabel", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Left, Text = "  " .. string.upper(text), LayoutOrder = nextOrder(parent) }, parent)
end

local function sliderRow(parent, key, label, min, max, step, fmt, hint)
    local h = hint and 72 or 56
    local f = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = BG1, BorderSizePixel = 0, LayoutOrder = nextOrder(parent) }, parent)
    corner(f, 12)
    stroke(f, LINE, 1)
    new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 6), Size = UDim2.new(1, -160, 0, 22), Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = TXT, Text = label }, f)
    if hint then
        new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 26), Size = UDim2.new(1, -28, 0, 16), Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = DIM, Text = hint }, f)
    end
    local valLbl = new("TextLabel", { Position = UDim2.new(1, -106, 0, 6), Size = UDim2.fromOffset(64, 24), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = TXT, Text = "" }, f)
    
    local bar = new("Frame", { Position = UDim2.new(0, 14, 0, h - 18), Size = UDim2.new(1, -28, 0, 6), BackgroundColor3 = BG2, BorderSizePixel = 0 }, f)
    corner(bar, UDim.new(1, 0))
    local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BorderSizePixel = 0 }, bar)
    acc(fill, "BackgroundColor3")
    corner(fill, UDim.new(1, 0))
    local knob = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(14, 14), Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, bar)
    corner(knob, UDim.new(1, 0))

    local function refresh()
        local v = S[key]
        local a = (v - min) / (max - min)
        fill.Size = UDim2.fromScale(a, 1)
        knob.Position = UDim2.fromScale(a, 0.5)
        valLbl.Text = string.format(fmt, v)
    end
    local function setv(v)
        v = math.clamp(math.floor(v / step + 0.5) * step, min, max)
        S[key] = tonumber(string.format("%.4f", v))
        refresh()
        queueSave()
        applyAll()
    end
    controls[key] = { refresh = refresh }
    refresh()

    local hit = new("Frame", { Position = UDim2.new(0, 0, 0, h - 30), Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Active = true }, f)
    local drag = false
    local function upd(x)
        local a = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        setv(min + (max - min) * a)
    end
    hit.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = true; upd(i.Position.X) end end)
    track(UIS.InputChanged:Connect(function(i) if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then upd(i.Position.X) end end))
    track(UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end end))
end

local function toggleRow(parent, key, label, hint)
    local h = hint and 58 or 46
    local f = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = BG1, BorderSizePixel = 0, LayoutOrder = nextOrder(parent) }, parent)
    corner(f, 12)
    stroke(f, LINE, 1)
    new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(14, hint and 8 or 0), Size = UDim2.new(1, -120, 0, hint and 20 or h), Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = TXT, Text = label }, f)
    if hint then
        new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 30), Size = UDim2.new(1, -120, 0, 18), Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = DIM, Text = hint }, f)
    end
    local sw = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(46, 24), BorderSizePixel = 0 }, f)
    corner(sw, UDim.new(1, 0))
    local kn = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(18, 18), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, sw)
    corner(kn, UDim.new(1, 0))
    local yn = new("TextLabel", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1
