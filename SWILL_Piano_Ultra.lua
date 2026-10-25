--============================================================
--  SWILL • Piano Ultra v2
--  Остров (FPS/Ping) • Пиксельная тян • Дудлы-частицы • Автоплей
--  RightShift - открыть/закрыть окно
--============================================================

local Players          = game:GetService("Players")
local UIS              = game:GetService("UserInputService")
local VIM              = game:GetService("VirtualInputManager")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local TweenService     = game:GetService("TweenService")
local Stats            = game:GetService("Stats")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera    = workspace.CurrentCamera

--================ НАСТРОЙКИ =================
local CONFIG = {
    pressDuration  = 0.09,
    noteGap        = 0.05,
    restDuration   = 0.22,
    antiskript     = false,
    antiskriptDelay= 0.07,
    particles      = true,
}
local tempoMs    = 50
local savedSongs = {}
local FILE_NAME  = "SWILL_Piano_Songs.json"

--================ ЦВЕТА =====================
local BG0  = Color3.fromRGB(15, 15, 17)
local BG1  = Color3.fromRGB(28, 28, 32)
local BG2  = Color3.fromRGB(42, 42, 47)
local TXT  = Color3.fromRGB(228, 228, 233)
local DIM  = Color3.fromRGB(140, 140, 150)
local GOLD = Color3.fromRGB(201, 162, 39)
local LINE = Color3.fromRGB(58, 58, 64)

--================ ХЕЛПЕРЫ ===================
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

--=========== КАРТА КЛАВИШ ===========
local keyMap = {}
for _, L in ipairs({"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"}) do
    keyMap[L:lower()] = { key = Enum.KeyCode[L], shift = false }
    keyMap[L]         = { key = Enum.KeyCode[L], shift = true  }
end
local digitNames = {"Zero","One","Two","Three","Four","Five","Six","Seven","Eight","Nine"}
for i = 0, 9 do keyMap[tostring(i)] = { key = Enum.KeyCode[digitNames[i + 1]], shift = false } end
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
keyMap["*"]  = { key = Enum.KeyCode.Eight,        shift = true  }

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

--=========== ПАРСЕР ====================
local function parseSong(str)
    local tokens, i, n = {}, 1, #str
    while i <= n do
        local c = str:sub(i, i)
        if c == "[" then
            local j = str:find("]", i, true)
            if j then
                table.insert(tokens, { chord = str:sub(i + 1, j - 1) })
                i = j + 1
            else
                i = i + 1
            end
        elseif c:match("%s") then
            i = i + 1
        else
            local j = i
            while j <= n and not str:sub(j, j):match("%s") and str:sub(j, j) ~= "[" do j = j + 1 end
            table.insert(tokens, { note = str:sub(i, j - 1) })
            i = j
        end
    end
    return tokens
end

--=========== СОХРАНЕНИЕ ===========
local function saveSongs()
    pcall(function()
        if writefile then writefile(FILE_NAME, HttpService:JSONEncode(savedSongs)) end
    end)
end
local function loadSongs()
    local ok, data = pcall(function()
        if isfile and isfile(FILE_NAME) then return readfile(FILE_NAME) end
    end)
    if ok and data then
        local s, decoded = pcall(function() return HttpService:JSONDecode(data) end)
        if s and type(decoded) == "table" then savedSongs = decoded end
    end
end
loadSongs()

--=========== GUI ROOT ========================
local function guiParent()
    local ok, h = pcall(function() return gethui and gethui() end)
    return (ok and h) or playerGui
end
for _, p in ipairs({ guiParent(), playerGui }) do
    local old = p:FindFirstChild("SWILL_Piano_Ultra")
    if old then old:Destroy() end
end

local gui = new("ScreenGui", {
    Name = "SWILL_Piano_Ultra", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
}, guiParent())

--=========== ОСТРОВ ==========================
local island = new("TextButton", {
    Size = UDim2.fromOffset(190, 34), Position = UDim2.new(0.5, -95, 0, 10),
    BackgroundColor3 = BG0, BorderSizePixel = 0, Text = "FPS: -- | Ping: --",
    Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = TXT,
    AutoButtonColor = false, Active = true, ZIndex = 999,
}, gui)
corner(island, UDim.new(1, 0))
local islandStroke = stroke(island, LINE, 1)

--=========== ГЛАВНОЕ ОКНО ====================
local WIN_W, WIN_H = 620, 430
local main = new("Frame", {
    Size = UDim2.fromOffset(WIN_W, WIN_H), Position = UDim2.fromScale(0.5, 0.55),
    AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = BG0, BorderSizePixel = 0,
    ClipsDescendants = false, Visible = false, ZIndex = 2,
}, gui)
corner(main, 20)
stroke(main, LINE, 1)
new("UIGradient", {
    Color = ColorSequence.new(Color3.fromRGB(26, 26, 29), Color3.fromRGB(12, 12, 14)),
    Rotation = 90,
}, main)
local scaleObj = new("UIScale", { Scale = 1 }, main)

local function baseScale()
    local v = camera.ViewportSize
    return math.clamp(math.min(v.X / 700, v.Y / 600), 0.5, 1)
end

-- Фон с дудлами (обрезается по скруглению)
local bgClip = new("Frame", {
    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
    ClipsDescendants = true, ZIndex = 1,
}, main)
corner(bgClip, 20)

local doodles = {}
local syms = {"★", "♪", "♥", "?", "!", "zzz", "hi", "ok", "hmm...", "✦", "♫", "!?", "✿", "~"}
local rng = Random.new()
for i = 1, 30 do
    local l = new("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.fromOffset(60, 40),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Text = syms[rng:NextInteger(1, #syms)], Font = Enum.Font.PatrickHand,
        TextSize = rng:NextInteger(20, 42), TextColor3 = Color3.fromRGB(95, 95, 105),
        TextTransparency = 0.7, Rotation = rng:NextInteger(-25, 25),
    }, bgClip)
    table.insert(doodles, {
        l = l, x = rng:NextNumber(0.03, 0.97), y = rng:NextNumber(0.1, 0.97),
        s = rng:NextNumber(0.4, 1.1), p = rng:NextNumber(0, 6.28), r = l.Rotation,
    })
end

local lastEmit = 0
local function emitParticle()
    if not CONFIG.particles or not main.Visible then return end
    if os.clock() - lastEmit < 0.1 then return end
    lastEmit = os.clock()
    local x = rng:NextNumber(0.05, 0.95)
    local p = new("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.fromOffset(30, 30),
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(x, 0, 1, 10),
        Text = ({"♪", "♫", "✦", "♥"})[rng:NextInteger(1, 4)], Font = Enum.Font.PatrickHand,
        TextSize = rng:NextInteger(18, 34), TextColor3 = Color3.fromRGB(235, 205, 110),
        TextTransparency = 0.15, ZIndex = 2,
    }, bgClip)
    tween(p, 1.8, {
        Position = UDim2.new(x + rng:NextNumber(-0.08, 0.08), 0, rng:NextNumber(0.2, 0.55), 0),
        TextTransparency = 1, Rotation = rng:NextInteger(-40, 40),
    }, Enum.EasingStyle.Sine).Completed:Connect(function() p:Destroy() end)
end

-- Шапка
local header = new("Frame", {
    Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Active = true, ZIndex = 5,
}, main)
new("TextLabel", {
    Size = UDim2.fromOffset(180, 30), Position = UDim2.fromOffset(18, 8), BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = TXT, Text = "♪ SWILL • Piano",
}, header)
local minBtn = new("TextButton", {
    Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -42, 0, 8), BackgroundColor3 = BG1,
    BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = TXT,
    Text = "–", AutoButtonColor = true,
}, header)
corner(minBtn, UDim.new(1, 0))

-- Перетаскивание
local dragging, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, startPos = true, input.Position, main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = (input.Position - dragStart) / scaleObj.Scale
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

--============================================================
--  ПИКСЕЛЬНАЯ ТЯНОЧКА (сидит на верхнем краю окна)
--============================================================
local PX = 4
local girlPalette = {
    H = Color3.fromRGB(246, 232, 214), h = Color3.fromRGB(214, 190, 176),
    S = Color3.fromRGB(255, 236, 225), E = Color3.fromRGB(70, 130, 250),
    D = Color3.fromRGB(45, 45, 75),    W = Color3.fromRGB(250, 250, 253),
    w = Color3.fromRGB(205, 210, 226), B = Color3.fromRGB(80, 140, 255),
    P = Color3.fromRGB(255, 165, 165),
}
local girlRows = {
    ".........H........",
    "........HH........",
    "......HHHHHH......",
    "....HHHHHHHHHH....",
    "...HBBHHHHHHHHH...",
    "..HHHHHHHHHHHHHH..",
    "..HHHHHHHHHHHHHH..",
    "..HHHHSSHHSSHHHH..",
    ".HHHHSSSSSSSSHHHH.",
    ".HHHSSSSSSSSSSHHH.",
    ".HHHSDDSSSSDDSHHH.",
    ".HHHSEESSSSEESHHH.",
    ".HHHSEESSSSEESHHH.",
    ".HHHPSSSSSSSSPHHH.",
    ".hHHSSSSDDSSSSHHh.",
    ".hHH.SSSSSSSS.HHh.",
    ".hH...SSSSSS...Hh.",
    "....wWWWWWWWWw....",
    "...SWWWBBBBWWWS...",
    "...SWWWWBBWWWWS...",
    "...SWWWWWWWWWWS...",
    "....WWWWWWWWWW....",
    "...wWWWWWWWWWWw...",
    "..wWWWWWWWWWWWWw..",
    "..BBBBBBBBBBBBBB..",
}
local ROWS = #girlRows

local girl = new("Frame", {
    Size = UDim2.fromOffset(18 * PX, ROWS * PX), Position = UDim2.new(1, -200, 0, -ROWS * PX + 2),
    BackgroundTransparency = 1, ZIndex = 20,
}, main)
local girlBaseY = -ROWS * PX + 2

-- ноги (качаются вокруг бедра)
local function makeLeg(col)
    local c = new("Frame", {
        Size = UDim2.fromOffset(3 * PX, 14 * PX), Position = UDim2.fromOffset(col * PX, ROWS * PX - 7 * PX - 2),
        BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1,
    }, girl)
    new("Frame", {
        Position = UDim2.fromOffset(0, 7 * PX), Size = UDim2.fromOffset(3 * PX, 5 * PX),
        BackgroundColor3 = girlPalette.S, BorderSizePixel = 0,
    }, c)
    new("Frame", {
        Position = UDim2.fromOffset(0, 12 * PX), Size = UDim2.fromOffset(3 * PX + 2, 2 * PX),
        BackgroundColor3 = Color3.fromRGB(95, 100, 135), BorderSizePixel = 0,
    }, c)
    return c
end
local legL, legR = makeLeg(6), makeLeg(9)

local sprite = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2 }, girl)
for y, row in ipairs(girlRows) do
    local x = 1
    while x <= #row do
        local ch = row:sub(x, x)
        if ch ~= "." then
            local e = x
            while e < #row and row:sub(e + 1, e + 1) == ch do e = e + 1 end
            new("Frame", {
                Position = UDim2.fromOffset((x - 1) * PX, (y - 1) * PX),
                Size = UDim2.fromOffset((e - x + 1) * PX, PX),
                BackgroundColor3 = girlPalette[ch], BorderSizePixel = 0,
            }, sprite)
            x = e + 1
        else
            x = x + 1
        end
    end
end

-- веки для моргания (глаза в колонках 5-6 и 11-12, строки 11-12)
local function makeLid(col)
    local f = new("Frame", {
        Position = UDim2.fromOffset(col * PX, 11 * PX), Size = UDim2.fromOffset(2 * PX, 2 * PX),
        BackgroundColor3 = girlPalette.S, BorderSizePixel = 0, Visible = false, ZIndex = 3,
    }, sprite)
    new("Frame", {
        Position = UDim2.fromOffset(0, PX + PX / 2), Size = UDim2.fromOffset(2 * PX, PX / 2),
        BackgroundColor3 = girlPalette.D, BorderSizePixel = 0,
    }, f)
    return f
end
local lidL, lidR = makeLid(5), makeLid(11)

--============================================================
--  ТАБЫ И СТРАНИЦЫ
--============================================================
local tabsFrame = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 48),
    Size = UDim2.fromOffset(0, 36), AutomaticSize = Enum.AutomaticSize.X,
    BackgroundColor3 = Color3.fromRGB(22, 22, 25), BorderSizePixel = 0, ZIndex = 5,
}, main)
corner(tabsFrame, UDim.new(1, 0))
stroke(tabsFrame, LINE, 1)
new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4),
    VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
}, tabsFrame)
new("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) }, tabsFrame)

local content = new("Frame", {
    Position = UDim2.fromOffset(16, 96), Size = UDim2.new(1, -32, 1, -110),
    BackgroundTransparency = 1, ZIndex = 5,
}, main)

local tabs, pages, activeTab = {}, {}, nil

local function makePage(name)
    local p = new("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = LINE,
        AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = false,
    }, content)
    new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, p)
    new("UIPadding", { PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }, p)
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
    local b = new("TextButton", {
        Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = BG2, BackgroundTransparency = 1, BorderSizePixel = 0,
        Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = DIM, Text = text,
        LayoutOrder = order, AutoButtonColor = false,
    }, tabsFrame)
    corner(b, UDim.new(1, 0))
    new("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }, b)
    b.Activated:Connect(function() switchTab(name) end)
    tabs[name] = b
end
createTab("home", "Главная", 1)
createTab("ctrl", "Настройки", 2)
createTab("info", "Гайд", 3)

--============================================================
--  ГЛАВНАЯ
--============================================================
local pageHome = makePage("home")

local inputBg = new("Frame", { Size = UDim2.new(1, 0, 0, 96), BackgroundColor3 = BG1, BorderSizePixel = 0, LayoutOrder = 1 }, pageHome)
corner(inputBg, 16)
stroke(inputBg, LINE, 1)
local melodyBox = new("TextBox", {
    Size = UDim2.new(1, -28, 1, -20), Position = UDim2.fromOffset(14, 10), BackgroundTransparency = 1,
    Font = Enum.Font.Code, TextSize = 14, TextColor3 = TXT, MultiLine = true, TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    PlaceholderText = "Мелодия: [*T69ey] - [6u] - * 0 W ...", PlaceholderColor3 = DIM,
    ClearTextOnFocus = false, Text = "",
}, inputBg)

local btnRow = new("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, LayoutOrder = 2 }, pageHome)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }, btnRow)

local function makeBtn(text, color, tColor, parent)
    local b = new("TextButton", {
        Size = UDim2.fromOffset(0, 40), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = color,
        BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = tColor,
        Text = text, AutoButtonColor = true,
    }, parent)
    corner(b, UDim.new(1, 0))
    new("UIPadding", { PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }, b)
    return b
end
local playBtn  = makeBtn("▶ Играть", GOLD, Color3.new(0, 0, 0), btnRow)
local stopBtn  = makeBtn("■ Стоп", BG2, TXT, btnRow)
local clearBtn = makeBtn("Очистить", BG2, TXT, btnRow)

local saveRow = new("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, LayoutOrder = 3 }, pageHome)
local nameBox = new("TextBox", {
    Size = UDim2.new(1, -150, 1, 0), BackgroundColor3 = BG1, BorderSizePixel = 0,
    Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = TXT, PlaceholderText = "Название трека...",
    PlaceholderColor3 = DIM, Text = "", ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
}, saveRow)
corner(nameBox, UDim.new(1, 0))
stroke(nameBox, LINE, 1)
new("UIPadding", { PaddingLeft = UDim.new(0, 16) }, nameBox)
local saveBtn = new("TextButton", {
    Size = UDim2.new(0, 140, 1, 0), Position = UDim2.new(1, -140, 0, 0), BackgroundColor3 = GOLD,
    BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.new(0, 0, 0),
    Text = "Сохранить",
}, saveRow)
corner(saveBtn, UDim.new(1, 0))

local songList = new("ScrollingFrame", {
    Size = UDim2.new(1, 0, 0, 130), BackgroundColor3 = BG1, BorderSizePixel = 0, ScrollBarThickness = 3,
    ScrollBarImageColor3 = LINE, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), LayoutOrder = 4,
}, pageHome)
corner(songList, 14)
stroke(songList, LINE, 1)
new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 8) }, songList)
new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.Name }, songList)

--============================================================
--  ПРОИГРЫВАНИЕ
--============================================================
local playing, playId = false, 0

local function playChord(chars)
    local infos = {}
    for ch in chars:gmatch(".") do
        local k = keyMap[ch]
        if k then infos[#infos + 1] = k end
    end
    if #infos == 0 then return end
    for _, info in ipairs(infos) do
        keyDown(info)
        if CONFIG.antiskript then task.wait(CONFIG.antiskriptDelay) end
    end
    task.wait(CONFIG.pressDuration)
    for _, info in ipairs(infos) do keyUp(info) end
end

local function stopPlay()
    playing = false
    playId = playId + 1
    releaseAll()
end

local function startPlay(text)
    if playing then return end
    local tokens = parseSong(text or "")
    if #tokens == 0 then return end
    playing = true
    playId = playId + 1
    local myId = playId
    task.spawn(function()
        for _, tk in ipairs(tokens) do
            if not playing or playId ~= myId then break end
            if tk.chord then
                emitParticle()
                playChord(tk.chord)
            elseif tk.note == "-" or tk.note == "|" then
                task.wait(CONFIG.restDuration + tempoMs / 1000)
            else
                for ch in tk.note:gmatch(".") do
                    if not playing or playId ~= myId then break end
                    emitParticle()
                    playChord(ch)
                    task.wait(CONFIG.noteGap)
                end
            end
            task.wait(CONFIG.noteGap + tempoMs / 1000)
        end
        if playId == myId then playing = false end
        releaseAll()
    end)
end

--============================================================
--  СПИСОК ПЕСЕН
--============================================================
local function refreshSongs()
    for _, c in ipairs(songList:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    for name, melody in pairs(savedSongs) do
        local row = new("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = BG2, BorderSizePixel = 0, Name = name }, songList)
        corner(row, 8)
        local load = new("TextButton", {
            Size = UDim2.new(1, -76, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium,
            TextSize = 13, TextColor3 = TXT, TextXAlignment = Enum.TextXAlignment.Left, Text = name,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, row)
        new("UIPadding", { PaddingLeft = UDim.new(0, 12) }, load)
        local pb = new("TextButton", {
            Size = UDim2.fromOffset(30, 24), Position = UDim2.new(1, -70, 0, 4), BackgroundColor3 = GOLD,
            BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.new(0, 0, 0), Text = "▶",
        }, row)
        corner(pb, UDim.new(1, 0))
        local db = new("TextButton", {
            Size = UDim2.fromOffset(30, 24), Position = UDim2.new(1, -36, 0, 4), BackgroundColor3 = Color3.fromRGB(70, 40, 44),
            BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = TXT, Text = "✕",
        }, row)
        corner(db, UDim.new(1, 0))
        load.Activated:Connect(function() melodyBox.Text = melody; nameBox.Text = name end)
        pb.Activated:Connect(function() melodyBox.Text = melody; stopPlay(); task.wait(0.05); startPlay(melody) end)
        db.Activated:Connect(function() savedSongs[name] = nil; saveSongs(); refreshSongs() end)
    end
end

playBtn.Activated:Connect(function() startPlay(melodyBox.Text) end)
stopBtn.Activated:Connect(stopPlay)
clearBtn.Activated:Connect(function() melodyBox.Text = "" end)
saveBtn.Activated:Connect(function()
    local n = nameBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
    if n == "" or melodyBox.Text == "" then return end
    savedSongs[n] = melodyBox.Text
    saveSongs()
    refreshSongs()
end)
refreshSongs()

--============================================================
--  НАСТРОЙКИ
--============================================================
local pageCtrl = makePage("ctrl")

local function makeSlider(parent, order, label, min, max, step, init, fmt, cb)
    local f = new("Frame", { Size = UDim2.new(1, 0, 0, 54), BackgroundColor3 = BG1, BorderSizePixel = 0, LayoutOrder = order }, parent)
    corner(f, 12)
    stroke(f, LINE, 1)
    local lbl = new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 6), Size = UDim2.new(1, -28, 0, 18),
        Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = TXT, Text = "",
    }, f)
    local track = new("Frame", { Position = UDim2.new(0, 14, 0, 36), Size = UDim2.new(1, -28, 0, 6), BackgroundColor3 = BG2, BorderSizePixel = 0 }, f)
    corner(track, UDim.new(1, 0))
    local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = GOLD, BorderSizePixel = 0 }, track)
    corner(fill, UDim.new(1, 0))
    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(14, 14), Position = UDim2.fromScale(0, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
    }, track)
    corner(knob, UDim.new(1, 0))

    local function set(v, fire)
        v = math.clamp(math.floor(v / step + 0.5) * step, min, max)
        local a = (v - min) / (max - min)
        fill.Size = UDim2.fromScale(a, 1)
        knob.Position = UDim2.fromScale(a, 0.5)
        lbl.Text = label .. ": " .. string.format(fmt, v)
        if fire then cb(v) end
    end
    set(init, false)

    local drag = false
    local function upd(x)
        local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        set(min + (max - min) * a, true)
    end
    f.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = true
            upd(i.Position.X)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            upd(i.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
end

local function makeToggle(parent, order, label, init, cb)
    local f = new("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = BG1, BorderSizePixel = 0, LayoutOrder = order }, parent)
    corner(f, 12)
    stroke(f, LINE, 1)
    new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -80, 1, 0),
        Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = TXT, Text = label,
    }, f)
    local sw = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(42, 22),
        BackgroundColor3 = init and GOLD or BG2, BorderSizePixel = 0,
    }, f)
    corner(sw, UDim.new(1, 0))
    local kn = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(18, 18),
        Position = init and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
    }, sw)
    corner(kn, UDim.new(1, 0))
    local state = init
    local hit = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, f)
    hit.Activated:Connect(function()
        state = not state
        tween(sw, 0.15, { BackgroundColor3 = state and GOLD or BG2 })
        tween(kn, 0.15, { Position = state and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0) })
        cb(state)
    end)
end

makeSlider(pageCtrl, 1, "Пауза между нотами", 0, 400, 5, tempoMs, "%d мс", function(v) tempoMs = v end)
makeSlider(pageCtrl, 2, "Длительность нажатия", 0.03, 0.30, 0.01, CONFIG.pressDuration, "%.2f с", function(v) CONFIG.pressDuration = v end)
makeSlider(pageCtrl, 3, "Пауза для «-»", 0.05, 1.0, 0.01, CONFIG.restDuration, "%.2f с", function(v) CONFIG.restDuration = v end)
makeToggle(pageCtrl, 4, "Антискрипт (аккорд не одновременно)", CONFIG.antiskript, function(v) CONFIG.antiskript = v end)
makeSlider(pageCtrl, 5, "Задержка антискрипта", 0.01, 0.20, 0.01, CONFIG.antiskriptDelay, "%.2f с", function(v) CONFIG.antiskriptDelay = v end)
makeToggle(pageCtrl, 6, "Частицы при игре", CONFIG.particles, function(v) CONFIG.particles = v end)

--============================================================
--  ГАЙД
--============================================================
local pageInfo = makePage("info")
local infoBox = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = BG1, BorderSizePixel = 0, LayoutOrder = 1 }, pageInfo)
corner(infoBox, 14)
stroke(infoBox, LINE, 1)
new("UIPadding", { PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }, infoBox)
new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
    Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = TXT, TextWrapped = true, RichText = true,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    Text = "<b>Формат мелодии</b>\n"
        .. "• <b>[abc]</b> — аккорд, ноты берутся одновременно\n"
        .. "• <b>a b c</b> — одиночные ноты по очереди\n"
        .. "• <b>-</b> или <b>|</b> — пауза\n"
        .. "• Заглавная буква = нота с Shift, <b>*</b> = Shift+8\n\n"
        .. "<b>Управление</b>\n"
        .. "• Клик по острову или <b>RightShift</b> — открыть/скрыть окно\n"
        .. "• Шапку окна можно таскать мышкой\n"
        .. "• Треки сохраняются в файл (если экзекутор поддерживает writefile)\n\n"
        .. "<b>Советы</b>\n"
        .. "• Если ноты слипаются — увеличь «Паузу между нотами»\n"
        .. "• Если сервер пропускает аккорды — включи «Антискрипт»",
}, infoBox)

switchTab("home")

--============================================================
--  ОТКРЫТИЕ / ЗАКРЫТИЕ ОКНА
--============================================================
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
        tween(scaleObj, 0.3, { Scale = baseScale() }, Enum.EasingStyle.Back, Enum.EasingDirection.Out).Completed:Wait()
    end
    busy = false
end

island.Activated:Connect(toggleWindow)
minBtn.Activated:Connect(toggleWindow)
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then toggleWindow() end
end)
island.MouseEnter:Connect(function() tween(island, 0.15, { Size = UDim2.fromOffset(204, 36), Position = UDim2.new(0.5, -102, 0, 9) }) end)
island.MouseLeave:Connect(function() tween(island, 0.15, { Size = UDim2.fromOffset(190, 34), Position = UDim2.new(0.5, -95, 0, 10) }) end)
camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    if main.Visible and not busy then scaleObj.Scale = baseScale() end
end)

--============================================================
--  FPS / PING (честные значения)
--============================================================
local fps, ping = 0, 0

local function getPing()
    local ok, v = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
    if ok and type(v) == "number" and v > 0 then return math.floor(v + 0.5) end
    local ok2, p = pcall(function() return player:GetNetworkPing() end)
    if ok2 and type(p) == "number" then return math.floor(p * 2000 + 0.5) end
    return 0
end

local function updateIsland()
    island.Text = string.format("%s%d FPS • %d ms", playing and "♪ " or "", fps, ping)
    islandStroke.Color = playing and GOLD or LINE
end

local frames, acc = 0, 0
RunService.RenderStepped:Connect(function(dt)
    frames = frames + 1
    acc = acc + dt
    if acc >= 0.5 then
        fps = math.floor(frames / acc + 0.5)
        frames, acc = 0, 0
        updateIsland()
    end
end)
task.spawn(function()
    while gui.Parent do
        ping = getPing()
        updateIsland()
        task.wait(1)
    end
end)

--============================================================
--  АНИМАЦИИ (дудлы + тян)
--============================================================
local t, phase = 0, 0
RunService.Heartbeat:Connect(function(dt)
    t = t + dt
    if not main.Visible then return end

    for _, d in ipairs(doodles) do
        d.l.Position = UDim2.new(d.x, math.sin(t * d.s + d.p) * 8, d.y, math.cos(t * d.s * 0.8 + d.p) * 8)
        d.l.Rotation = d.r + math.sin(t * d.s + d.p) * 6
        d.l.TextTransparency = 0.7 + math.sin(t * d.s * 1.3 + d.p) * 0.08
    end

    local speed = playing and 6 or 2.2
    phase = phase + dt * speed
    local sw = math.sin(phase) * (playing and 20 or 12)
    legL.Rotation = sw
    legR.Rotation = -sw
    girl.Position = UDim2.new(1, -200, 0, girlBaseY + math.floor(math.sin(phase * 0.9) * 1.5 + 0.5) * (playing and 2 or 1))

    local blink = (t % 3.6) < 0.14
    lidL.Visible = blink
    lidR.Visible = blink
end)

updateIsland()
print("[SWILL] Piano Ultra загружен. Клик по острову / RightShift — открыть окно.")
