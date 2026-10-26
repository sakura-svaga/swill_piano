--============================================================
--  SWILL • Piano Ultra v3 (FIXED FINAL)
--============================================================

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local VIM          = game:GetService("VirtualInputManager")
local RunService   = game:GetService("RunService")
local HttpService  = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Stats        = game:GetService("Stats")
local VirtualUser  = game:GetService("VirtualUser")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera    = workspace.CurrentCamera

pcall(function() if getgenv and getgenv().SWILL_UNLOAD then getgenv().SWILL_UNLOAD() end end)

local conns = {}
local function track(c) conns[#conns + 1] = c return c end
local rnd = Random.new()

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
local function fmtTime(sec)
    sec = math.max(0, math.floor(sec + 0.5))
    return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

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
local function estimate(events)
    local t = 0
    for _, e in ipairs(events) do t = t + (e.t == "r" and restDur() or noteDur()) end
    return t
end

local function readClipboard()
    local fns = {
        function() return getclipboard() end,
        function() return syn.get_clipboard() end,
        function() return get_clipboard() end,
        function() return readclipboard() end,
        function() return fromclipboard() end,
        function() return Clipboard.get() end,
    }
    for _, f in ipairs(fns) do
        local ok, v = pcall(f)
        if ok and type(v) == "string" and v ~= "" then return v end
    end
    return nil
end

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

local function recolor() end

local island = new("TextButton", {
    Size = UDim2.fromOffset(190, 34), Position = UDim2.new(0.5, -95, 0, 10),
    BackgroundColor3 = BG0, BorderSizePixel = 0, Text = "", AutoButtonColor = false,
    Active = true, ZIndex = 999, ClipsDescendants = true,
}, gui)
corner(island, UDim.new(1, 0))
stroke(island, LINE, 1)

local statsLabel = new("TextLabel", {
    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
    TextSize = 12, TextColor3 = TXT, Text = "",
}, island)

local pg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false }, island)
local cover = new("Frame", { Position = UDim2.fromOffset(10, 9), Size = UDim2.fromOffset(32, 32), BorderSizePixel = 0 }, pg)
acc(cover, "BackgroundColor3")
corner(cover, 9)
new("TextLabel", {
    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
    TextSize = 17, TextColor3 = Color3.fromRGB(20, 20, 22), Text = "♪",
}, cover)
local titleClip = new("Frame", {
    Position = UDim2.fromOffset(52, 7), Size = UDim2.fromOffset(186, 18), BackgroundTransparency = 1, ClipsDescendants = true,
}, pg)
local titleLbl = new("TextLabel", {
    Size = UDim2.fromOffset(0, 18), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = TXT, TextXAlignment = Enum.TextXAlignment.Left, Text = "",
}, titleClip)
local subLbl = new("TextLabel", {
    Position = UDim2.fromOffset(52, 25), Size = UDim2.fromOffset(186, 14), BackgroundTransparency = 1,
    Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Left, Text = "",
}, pg)
local eqBars = {}
for i = 1, 4 do
    local b = new("Frame", {
        AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromOffset(264 + (i - 1) * 8, 36),
        Size = UDim2.fromOffset(5, 6), BorderSizePixel = 0,
    }, pg)
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
island.MouseEnter:Connect(function()
    if not islandPlaying then tween(island, 0.15, { Size = UDim2.fromOffset(204, 36), Position = UDim2.new(0.5, -102, 0, 9) }) end
end)
island.MouseLeave:Connect(function()
    if not islandPlaying then tween(island, 0.15, { Size = UDim2.fromOffset(190, 34), Position = UDim2.new(0.5, -95, 0, 10) }) end
end)

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

local bgClip = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 1 }, main)
corner(bgClip, 20)
local doodleFolder = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, bgClip)

local drng = Random.new(11)
local DOOD = Color3.fromRGB(92, 92, 102)
local floaters = {}
local function addFloater(inst, x, y, amp, spd, rot)
    floaters[#floaters + 1] = { i = inst, x = x, y = y, a = amp, s = spd, p = drng:NextNumber(0, 6.28), r = rot }
end

local glyphs = {"♡", "☆", "♪", "?", "!!", "zzz", "hi", "ok", "hmm...", "✧", "♫", "?!", "♡", "☆", "~"}
for _ = 1, 24 do
    local l = new("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.fromOffset(70, 40), AnchorPoint = Vector2.new(0.5, 0.5),
        Text = glyphs[drng:NextInteger(1, #glyphs)], Font = Enum.Font.PatrickHand,
        TextSize = drng:NextInteger(20, 40), TextColor3 = DOOD, TextTransparency = 0.6,
    }, doodleFolder)
    addFloater(l, drng:NextNumber(0.03, 0.97), drng:NextNumber(0.14, 0.97), 7, drng:NextNumber(0.4, 1.0), drng:NextInteger(-25, 25))
end
local function makeSpiral(size)
    local c = new("Frame", { Size = UDim2.fromOffset(size, size), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1 }, doodleFolder)
    local N = 48
    for k = 1, N do
        local a, r = k * 0.42, (k / N) * size * 0.5
        new("Frame", {
            Size = UDim2.fromOffset(2, 2), AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, math.cos(a) * r, 0.5, math.sin(a) * r),
            BackgroundColor3 = DOOD, BackgroundTransparency = 0.5, BorderSizePixel = 0,
        }, c)
    end
    return c
end
local function makeHatch(w, h, n)
    local c = new("Frame", { Size = UDim2.fromOffset(w, h), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1 }, doodleFolder)
    for k = 0, n - 1 do
        new("Frame", {
            Position = UDim2.fromOffset(k * (w / n), 0), Size = UDim2.fromOffset(2, h),
            BackgroundColor3 = DOOD, BackgroundTransparency = 0.55, BorderSizePixel = 0, Rotation = 22,
        }, c)
    end
    return c
end
for _ = 1, 6 do
    addFloater(makeSpiral(drng:NextInteger(50, 90)), drng:NextNumber(0.05, 0.95), drng:NextNumber(0.2, 0.95), 5, drng:NextNumber(0.2, 0.5), drng:NextInteger(-180, 180))
end
for _ = 1, 5 do
    addFloater(makeHatch(drng:NextInteger(40, 70), drng:NextInteger(40, 70), 6), drng:NextNumber(0.05, 0.95), drng:NextNumber(0.2, 0.95), 6, drng:NextNumber(0.3, 0.7), drng:NextInteger(-15, 15))
end

local lastEmit = 0
local function emitParticle()
    if not S.particles or not main.Visible then return end
    if os.clock() - lastEmit < 0.1 then return end
    lastEmit = os.clock()
    local x = rnd:NextNumber(0.05, 0.95)
    local p = new("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.fromOffset(30, 30), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(x, 0, 1, 10), Text = ({"♪", "♫", "✦", "♡"})[rnd:NextInteger(1, 4)],
        Font = Enum.Font.PatrickHand, TextSize = rnd:NextInteger(18, 34), TextColor3 = ACC(),
        TextTransparency = 0.1, ZIndex = 2,
    }, bgClip)
    tween(p, 1.8, {
        Position = UDim2.new(x + rnd:NextNumber(-0.08, 0.08), 0, rnd:NextNumber(0.2, 0.55), 0),
        TextTransparency = 1, Rotation = rnd:NextInteger(-40, 40),
    }, Enum.EasingStyle.Sine).Completed:Connect(function() p:Destroy() end)
end

local header = new("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Active = true, ZIndex = 5 }, main)
new("TextLabel", {
    Size = UDim2.fromOffset(180, 24), Position = UDim2.fromOffset(22, 12), BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = DIM, Text = "SWILL • Piano",
}, header)

local function winBtn(text, xOff)
    local b = new("TextButton", {
        Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, xOff, 0, 12), BackgroundColor3 = BG1,
        BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = DIM, Text = text, AutoButtonColor = true,
    }, header)
    corner(b, UDim.new(1, 0))
    return b
end
local minBtn   = winBtn("–", -114)
local sizeBtn  = winBtn("□", -78)
local closeBtn = winBtn("✕", -42)

local dragging, dragStart, startPos
track(header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, startPos = true, input.Position, main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end))
track(UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = (input.Position - dragStart) / scaleObj.Scale
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end))

local PX = 4
local gp = {
    O = Color3.fromRGB(78, 64, 82),    H = Color3.fromRGB(248, 236, 218),
    h = Color3.fromRGB(222, 200, 184), g = Color3.fromRGB(196, 170, 160),
    S = Color3.fromRGB(255, 232, 220), s = Color3.fromRGB(240, 205, 195),
    E = Color3.fromRGB(92, 150, 255),  e = Color3.fromRGB(170, 212, 255),
    D = Color3.fromRGB(40, 44, 90),    W = Color3.fromRGB(252, 252, 255),
    w = Color3.fromRGB(206, 212, 230), K = Color3.fromRGB(58, 60, 84),
    k = Color3.fromRGB(84, 88, 118),   B = Color3.fromRGB(96, 160, 255),
    P = Color3.fromRGB(255, 160, 160), M = Color3.fromRGB(214, 110, 120),
}
local rep = string.rep
local girlRows = {
    "OO",
    "OHHO",
    rep("O", 8),
    "OO" .. rep("H", 8) .. "OO",
    "O" .. "HH" .. "BB" .. rep("H", 8) .. "O",
    "O" .. rep("H", 14) .. "O",
    "O" .. "HHH" .. "h" .. rep("H", 6) .. "h" .. "HHH" .. "O",
    "O" .. rep("H", 5) .. "SS" .. "HH" .. "SS" .. rep("H", 5) .. "O",
    "O" .. rep("H", 4) .. rep("S", 8) .. rep("H", 4) .. "O",
    "O" .. rep("H", 3) .. rep("S", 10) .. rep("H", 3) .. "O",
    "O" .. rep("H", 3) .. rep("S", 10) .. rep("H", 3) .. "O",
    "O" .. "HHH" .. "SDDDSSDDDS" .. "HHH" .. "O",      -- ресницы
    "O" .. "HHH" .. "SeDESSeDES" .. "HHH" .. "O",      -- глаза
    "O" .. "HHH" .. "SEEESSEEES" .. "HHH" .. "O",
    "O" .. "HHH" .. "PPSSSSSSPP" .. "HHH" .. "O",      -- румянец
    "O" .. "hHH" .. "SSSSMMSSSS" .. "HHh" .. "O",      -- рот
    "O" .. "hHHH" .. "sSSSSSSs" .. "HHHh" .. "O",
    "OhHH" .. "." .. "sSSSSs" .. "." .. "HHhO",
    "OhH" .. "..." .. "sSSs" .. "..." .. "HhO",
    "ghH" .. rep(".", 4) .. "sSSs" .. rep(".", 4) .. "Hhg",
    "wWWWBBWWWw",
    "SwWWWBBWWWwS",
    "S" .. "w" .. rep("W", 8) .. "w" .. "S",
    "sSWWKKKKWWSs",
    "k" .. rep("K", 10) .. "k",
    "k" .. rep("K", 12) .. "k",
    "k" .. rep("K", 14) .. "k",
    "WwWwWwWwWwWwWwWw",
}
local ROWS, COLS = #girlRows, 22
local girlBaseY = -ROWS * PX + 2

local girl = new("Frame", {
    Size = UDim2.fromOffset(COLS * PX, ROWS * PX), Position = UDim2.new(0, WIN_W - 235, 0, girlBaseY),
    BackgroundTransparency = 1, ZIndex = 20,
}, main)

local function makeLeg(col)
    local c = new("Frame", {
        Size = UDim2.fromOffset(3 * PX, 14 * PX), Position = UDim2.fromOffset(col * PX, ROWS * PX - 7 * PX - 2),
        BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1,
    }, girl)
    new("Frame", { Position = UDim2.fromOffset(0, 7 * PX), Size = UDim2.fromOffset(3 * PX, 5 * PX), BackgroundColor3 = gp.S, BorderSizePixel = 0 }, c)
    new("Frame", { Position = UDim2.fromOffset(0, 12 * PX), Size = UDim2.fromOffset(3 * PX + 2, 2 * PX), BackgroundColor3 = gp.k, BorderSizePixel = 0 }, c)
    return c
end
local legL, legR = makeLeg(7), makeLeg(12)

local sprite = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2 }, girl)
for y, row in ipairs(girlRows) do
    local pad = math.floor((COLS - #row) / 2)
    local x = 1
    while x <= #row do
        local ch = row:sub(x, x)
        if ch ~= "." then
            local e = x
            while e < #row and row:sub(e + 1, e + 1) == ch do e = e + 1 end
            new("Frame", {
                Position = UDim2.fromOffset((pad + x - 1) * PX, (y - 1) * PX),
                Size = UDim2.fromOffset((e - x + 1) * PX, PX), BackgroundColor3 = gp[ch], BorderSizePixel = 0,
            }, sprite)
            x = e + 1
        else
            x = x + 1
        end
    end
end
local function makeLid(col)
    local f = new("Frame", {
        Position = UDim2.fromOffset(col * PX, 12 * PX), Size = UDim2.fromOffset(3 * PX, 2 * PX),
        BackgroundColor3 = gp.S, BorderSizePixel = 0, Visible = false, ZIndex = 3,
    }, sprite)
    new("Frame", { Position = UDim2.fromOffset(0, PX + PX / 2), Size = UDim2.fromOffset(3 * PX, PX / 2), BackgroundColor3 = gp.D, BorderSizePixel = 0 }, f)
    return f
end
local lidL, lidR = makeLid(7), makeLid(12)

local tabsFrame = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, -10, 0, 46), Size = UDim2.fromOffset(0, 38),
    AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Color3.fromRGB(22, 22, 25), BorderSizePixel = 0, ZIndex = 5,
}, main)
corner(tabsFrame, UDim.new(1, 0))
stroke(tabsFrame, LINE, 1)
new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 3), VerticalAlignment = Enum.VerticalAlignment.Center,
    HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
}, tabsFrame)
new("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) }, tabsFrame)

local rightPill = new("Frame", {
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -22, 0, 46), Size = UDim2.fromOffset(84, 38),
    BackgroundColor3 = Color3.fromRGB(22, 22, 25), BorderSizePixel = 0, ZIndex = 5,
}, main)
corner(rightPill, UDim.new(1, 0))
stroke(rightPill, LINE, 1)
local function pillIcon(text, x)
    local b = new("TextButton", {
        Position = UDim2.fromOffset(x, 4), Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = TXT, Text = text, AutoButtonColor = false,
    }, rightPill)
    corner(b, UDim.new(1, 0))
    return b
end
local accentBtn = pillIcon("◐", 8)
local doodleBtn = pillIcon("❖", 46)

local content = new("Frame", {
    Position = UDim2.fromOffset(16, 96), Size = UDim2.new(1, -32, 1, -110), BackgroundTransparency = 1, ZIndex = 5,
}, main)

local tabs, pages, activeTab = {}, {}, nil
local orders = {}
local function nextOrder(p) orders[p] = (orders[p] or 0) + 1 return orders[p] end

local function makePage(name)
    local p = new("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
        ScrollBarImageColor3 = LINE, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = false,
    }, content)
    new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, p)
    new("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10) }, p)
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
        Size = UDim2.fromOffset(0, 30), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = BG2, BackgroundTransparency = 1,
        BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = DIM, Text = text,
        LayoutOrder = order, AutoButtonColor = false,
    }, tabsFrame)
    corner(b, UDim.new(1, 0))
    new("UIPadding", { PaddingLeft = UDim.new(0, 13), PaddingRight = UDim.new(0, 13) }, b)
    b.Activated:Connect(function() switchTab(name) end)
    tabs[name] = b
end
createTab("home", "⌂ Главная", 1)
createTab("play", "♪ Игра", 2)
createTab("anti", "◈ Антискрипт", 3)
createTab("set", "⚙ Настройки", 4)
createTab("guide", "? Гайд", 5)

local homePage = new("Frame", {
    Position = UDim2.fromOffset(0, 92), Size = UDim2.new(1, 0, 1, -92), BackgroundTransparency = 1, Visible = false, ZIndex = 5,
}, main)
pages["home"] = homePage

local sideBtns = {}
local function sideBtn(key, text, y)
    local b = new("TextButton", {
        Position = UDim2.fromOffset(24, y), Size = UDim2.fromOffset(40, 40), BackgroundColor3 = BG2, BackgroundTransparency = 1,
        BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = DIM, Text = text, AutoButtonColor = false,
    }, homePage)
    corner(b, 10)
    sideBtns[key] = b
    return b
end
sideBtn("chat", "✦", 8)
sideBtn("lib", "▤", 56)
sideBtn("new", "✎", 104)

local chatArea = new("Frame", { Position = UDim2.fromOffset(84, 0), Size = UDim2.new(1, -118, 1, -100), BackgroundTransparency = 1 }, homePage)
local chatScroll = new("ScrollingFrame", {
    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
    ScrollBarImageColor3 = LINE, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
}, chatArea)
new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, chatScroll)
new("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }, chatScroll)

local msgOrder, msgRows = 0, {}
local function addMsg(who, text)
    msgOrder = msgOrder + 1
    local row = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = msgOrder }, chatScroll)
    new("UIListLayout", { HorizontalAlignment = who == "user" and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left }, row)
    local bub = new("Frame", { Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = BUB, BackgroundTransparency = 1, BorderSizePixel = 0 }, row)
    corner(bub, 16)
    new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }, bub)
    local lbl = new("TextLabel", {
        Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1,
        Font = Enum.Font.Code, TextSize = 14, TextColor3 = TXT, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 1, Text = text,
    }, bub)
    new("UISizeConstraint", { MaxSize = Vector2.new(400, math.huge) }, lbl)
    tween(bub, 0.22, { BackgroundTransparency = 0 })
    tween(lbl, 0.22, { TextTransparency = 0 })
    msgRows[#msgRows + 1] = row
    if #msgRows > 40 then table.remove(msgRows, 1):Destroy() end
    task.delay(0.06, function() chatScroll.CanvasPosition = Vector2.new(0, 99999) end)
    return lbl
end
local function say(text) return addMsg("bot", text) end
local function sayUser(text) return addMsg("user", text) end

local libView = new("Frame", { Position = UDim2.fromOffset(84, 0), Size = UDim2.new(1, -118, 1, -100), BackgroundTransparency = 1, Visible = false }, homePage)
local libTop = new("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1 }, libView)
local nameBox = new("TextBox", {
    Size = UDim2.new(1, -250, 1, 0), BackgroundColor3 = BG1, BorderSizePixel = 0, Font = Enum.Font.Gotham, TextSize = 13,
    TextColor3 = TXT, PlaceholderText = "Название трека...", PlaceholderColor3 = DIM, Text = "", ClearTextOnFocus = false,
    TextXAlignment = Enum.TextXAlignment.Left,
}, libTop)
corner(nameBox, UDim.new(1, 0))
stroke(nameBox, LINE, 1)
new("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 10) }, nameBox)
local function libBtn(text, xOff, w, filled)
    local b = new("TextButton", {
        Position = UDim2.new(1, xOff, 0, 0), Size = UDim2.fromOffset(w, 38), BackgroundColor3 = BG2, BorderSizePixel = 0,
        Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = filled and Color3.new(0, 0, 0) or TXT, Text = text,
    }, libTop)
    corner(b, UDim.new(1, 0))
    if filled then acc(b, "BackgroundColor3") end
    return b
end
local saveBtn    = libBtn("Сохранить", -242, 90, true)
local playAllBtn = libBtn("▶ Все", -146, 62, true)
local shuffleBtn = libBtn("🔀", -78, 36, false)
local songList = new("ScrollingFrame", {
    Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 1, -46), BackgroundColor3 = BG1, BorderSizePixel = 0,
    ScrollBarThickness = 3, ScrollBarImageColor3 = LINE, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
}, libView)
corner(songList, 14)
stroke(songList, LINE, 1)
new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 10) }, songList)
new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.Name }, songList)

local inputBar = new("Frame", {
    Position = UDim2.new(0, 84, 1, -92), Size = UDim2.new(1, -118, 0, 52), BackgroundColor3 = Color3.fromRGB(24, 24, 27), BorderSizePixel = 0,
}, homePage)
corner(inputBar, UDim.new(1, 0))
stroke(inputBar, LINE, 1)

local plusBtn = new("TextButton", {
    Position = UDim2.fromOffset(10, 6), Size = UDim2.fromOffset(40, 40), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium,
    TextSize = 24, TextColor3 = TXT, Text = "+", AutoButtonColor = false,
}, inputBar)
local melodyBox = new("TextBox", {
    Position = UDim2.fromOffset(58, 0), Size = UDim2.new(1, -206, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.Code,
    TextSize = 14, TextColor3 = TXT, PlaceholderText = "Вставь мелодию: [1e] 3 5 - [6y] ...", PlaceholderColor3 = DIM,
    ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, Text = "",
}, inputBar)
local function inBtn(text, xOff, size, fillBg)
    local b = new("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, xOff, 0.5, 0), Size = UDim2.fromOffset(size, size),
        BackgroundColor3 = Color3.fromRGB(46, 46, 52), BackgroundTransparency = fillBg and 0 or 1, BorderSizePixel = 0,
        Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = TXT, Text = text, AutoButtonColor = false,
    }, inputBar)
    corner(b, fillBg and 12 or UDim.new(1, 0))
    return b
end
local sendBtn  = inBtn("▶", -8, 40, true)
local loopBtn  = inBtn("↻", -56, 36, false)
local pasteBtn = inBtn("📋", -98, 36, false)

local plusMenu = new("Frame", {
    AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 84, 1, -100), Size = UDim2.fromOffset(230, 0), AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundColor3 = Color3.fromRGB(26, 26, 30), BorderSizePixel = 0, Visible = false, ZIndex = 30,
}, homePage)
corner(plusMenu, 14)
stroke(plusMenu, LINE, 1)
new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, plusMenu)
new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, plusMenu)
local function menuItem(text, cb)
    local b = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = BG2, BackgroundTransparency = 1, BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = TXT, Text = text, TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = nextOrder(plusMenu), AutoButtonColor = false, ZIndex = 31,
    }, plusMenu)
    corner(b, 8)
    new("UIPadding", { PaddingLeft = UDim.new(0, 12) }, b)
    b.MouseEnter:Connect(function() b.BackgroundTransparency = 0 end)
    b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
    b.Activated:Connect(function() plusMenu.Visible = false; cb() end)
end

local pillRow = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 30, 1, -12), Size = UDim2.fromOffset(0, 26),
    AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1,
}, homePage)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center }, pillRow)
local pills = {}
local function makePill(text, key)
    local b = new("TextButton", {
        Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X, BorderSizePixel = 0, Font = Enum.Font.GothamBold,
        TextSize = 11, Text = text, AutoButtonColor = false,
    }, pillRow)
    corner(b, UDim.new(1, 0))
    new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, b)
    pills[key] = b
    return b
end
makePill("◈ АНТИ", "anti")
makePill("↻ ПОВТОР", "loop")
makePill("✦ ЧАСТИЦЫ", "particles")

local nameLbl = new("TextLabel", {
    AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 22, 1, -14), Size = UDim2.fromOffset(100, 16), BackgroundTransparency = 1,
    Font = Enum.Font.Code, TextSize = 12, TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Left, Text = S.girlName,
}, homePage)

local controls = {}
local applyAll = function() end

local function section(parent, text)
    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = DIM,
        TextXAlignment = Enum.TextXAlignment.Left, Text = "  " .. string.upper(text), LayoutOrder = nextOrder(parent),
    }, parent)
end

local function infoCard(parent, text)
    local f = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = BG1, BorderSizePixel = 0, LayoutOrder = nextOrder(parent),
    }, parent)
    corner(f, 12)
    stroke(f, LINE, 1)
    new("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, f)
    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Font = Enum.Font.Gotham,
        TextSize = 13, TextColor3 = TXT, TextWrapped = true, RichText = true, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top, Text = text,
    }, f)
    return f
end

local function sliderRow(parent, key, label, min, max, step, fmt, hint)
    local h = hint and 72 or 56
    local f = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = BG1, BorderSizePixel = 0, LayoutOrder = nextOrder(parent) }, parent)
    corner(f, 12)
    stroke(f, LINE, 1)
    new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 6), Size = UDim2.new(1, -160, 0, 22), Font = Enum.Font.GothamMedium,
        TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = TXT, Text = label,
    }, f)
    if hint then
        new("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 26), Size = UDim2.new(1, -28, 0, 16), Font = Enum.Font.Gotham,
            TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = DIM, Text = hint, TextTruncate = Enum.TextTruncate.AtEnd,
        }, f)
    end
    local function stepBtn(text, xOff)
        local b = new("TextButton", {
            Position = UDim2.new(1, xOff, 0, 6), Size = UDim2.fromOffset(24, 24), BackgroundColor3 = BG2, BorderSizePixel = 0,
            Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = TXT, Text = text, AutoButtonColor = true,
        }, f)
        corner(b, UDim.new(1, 0))
        return b
    end
    local minus, plus = stepBtn("−", -134), stepBtn("+", -38)
    local valLbl = new("TextLabel", {
        Position = UDim2.new(1, -106, 0, 6), Size = UDim2.fromOffset(64, 24), BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
        TextSize = 12, TextColor3 = TXT, Text = "",
    }, f)
    local bar = new("Frame", { Position = UDim2.new(0, 14, 0, h - 18), Size = UDim2.new(1, -28, 0, 6), BackgroundColor3 = BG2, BorderSizePixel = 0 }, f)
    corner(bar, UDim.new(1, 0))
    local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BorderSizePixel = 0 }, bar)
    acc(fill, "BackgroundColor3")
    corner(fill, UDim.new(1, 0))
    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(14, 14), Position = UDim2.fromScale(0, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
    }, bar)
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

    minus.Activated:Connect(function() setv(S[key] - step) end)
    plus.Activated:Connect(function() setv(S[key] + step) end)

    local hit = new("Frame", { Position = UDim2.new(0, 0, 0, h - 30), Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Active = true }, f)
    local drag = false
    local function upd(x)
        local a = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        setv(min + (max - min) * a)
    end
    hit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = true
            upd(i.Position.X)
        end
    end)
    track(UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then upd(i.Position.X) end
    end))
    track(UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end))
end

local function toggleRow(parent, key, label, hint)
    local h = hint and 58 or 46
    local f = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = BG1, BorderSizePixel = 0, LayoutOrder = nextOrder(parent) }, parent)
    corner(f, 12)
    stroke(f, LINE, 1)
    new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(14, hint and 8 or 0), Size = UDim2.new(1, -120, 0, hint and 20 or h),
        Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = TXT, Text = label,
    }, f)
    if hint then
        new("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 30), Size = UDim2.new(1, -120, 0, 18), Font = Enum.Font.Gotham,
            TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = DIM, Text = hint, TextTruncate = Enum.TextTruncate.AtEnd,
        }, f)
    end
    local sw = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(46, 24), BorderSizePixel = 0 }, f)
    corner(sw, UDim.new(1, 0))
    local kn = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(18, 18), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, sw)
    corner(kn, UDim.new(1, 0))
    local yn = new("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -66, 0.5, 0), Size = UDim2.fromOffset(34, 20), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 11,
    }, f)
    local function refresh()
        local on = S[key]
        sw.BackgroundColor3 = on and ACC() or BG2
        yn.Text = on and "ДА" or "НЕТ"
        yn.TextColor3 = on and ACC() or DIM
        tween(kn, 0.12, { Position = on and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) })
    end
    controls[key] = { refresh = refresh }
    refresh()
    local hit = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, f)
    hit.Activated:Connect(function()
        S[key] = not S[key]
        refresh()
        queueSave()
        applyAll()
    end)
end

local function actionRow(parent, text, color, cb)
    local b = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = color, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 13,
        TextColor3 = TXT, Text = text, LayoutOrder = nextOrder(parent),
    }, parent)
    corner(b, 12)
    b.Activated:Connect(function() cb(b) end)
    return b
end

local pagePlay = makePage("play")
section(pagePlay, "Ритм и звучание")
sliderRow(pagePlay, "speed", "Скорость", 0.5, 2, 0.05, "×%.2f", "Общий множитель темпа: 1.00 = как написано")
sliderRow(pagePlay, "tempo", "Пауза между нотами", 0, 400, 5, "%d мс", "Больше — медленнее и чётче, меньше — быстрее")
sliderRow(pagePlay, "hold", "Длительность нажатия", 0.03, 0.3, 0.01, "%.2f с", "Как долго клавиша удерживается")
sliderRow(pagePlay, "rest", "Длина паузы «-»", 0.05, 1, 0.01, "%.2f с", "Для знаков - и | в мелодии")
section(pagePlay, "Мелодия")
sliderRow(pagePlay, "transpose", "Транспонирование", -12, 12, 1, "%+d", "Сдвиг в полутонах по 61-клавишной раскладке")
sliderRow(pagePlay, "countdown", "Отсчёт перед стартом", 0, 10, 1, "%d с", "Время успеть кликнуть в игру")
toggleRow(pagePlay, "loop", "Повтор", "Играть по кругу, пока не нажмёшь стоп")
toggleRow(pagePlay, "shuffle", "Перемешивать плейлист", "Для кнопки «▶ Все» в библиотеке")

local pageAnti = makePage("anti")
infoCard(pageAnti, "<b>Как работает.</b> Без антискрипта все клавиши аккорда нажимаются в один и тот же момент, а ноты идут с идеальной точностью. С антискриптом клавиши аккорда нажимаются <b>по очереди, в случайном порядке и со случайной задержкой</b>, а время нот слегка «дрожит». Ритм привязан к общему таймлайну, поэтому <b>песня не уезжает</b>, а лишние микро-задержки компенсируются.")
section(pageAnti, "Включение")
toggleRow(pageAnti, "anti", "Антискрипт", "Главный выключатель")
section(pageAnti, "Разброс клавиш в аккорде")
sliderRow(pageAnti, "antiMin", "Минимальная задержка между клавишами", 0, 60, 1, "%d мс")
sliderRow(pageAnti, "antiMax", "Максимальная задержка между клавишами", 1, 120, 1, "%d мс")
sliderRow(pageAnti, "antiCap", "Лимит разброса на весь аккорд", 10, 250, 5, "%d мс", "Большие аккорды не растянутся дольше этого")
toggleRow(pageAnti, "antiSmart", "Умный лимит", "Разброс не больше 35% длительности ноты, быстрые места не портятся")
toggleRow(pageAnti, "antiOrder", "Случайный порядок клавиш", "Иначе клавиши идут как записаны")
section(pageAnti, "Человечность")
sliderRow(pageAnti, "antiTiming", "Дрожание времени ноты", 0, 60, 1, "±%d мс", "Ограничено 30% длительности ноты")
sliderRow(pageAnti, "antiHold", "Дрожание длительности нажатия", 0, 50, 1, "±%d%%")
infoCard(pageAnti, "<b>Подсказка.</b> Лёгкий режим: 5–25 мс, дрожание 10 мс, 10%. Сильный режим: 10–50 мс, лимит 120 мс, дрожание 25 мс, 25%. Если песня звучит «размазанно», уменьши максимум и лимит.")

local pageSet = makePage("set")
section(pageSet, "Интерфейс")
toggleRow(pageSet, "particles", "Частицы при игре", "Ноты и звёздочки поднимаются со дна окна")
toggleRow(pageSet, "doodles", "Фон-дудлы", "Выключи, если телефон тормозит")
toggleRow(pageSet, "girl", "Показывать тяночку")
toggleRow(pageSet, "islandStats", "FPS и ping на островке", "Когда музыка не играет")
toggleRow(pageSet, "autohide", "Прятать окно во время игры", "Окно вернётся после завершения, остров покажет трек")
sliderRow(pageSet, "uiScale", "Масштаб окна", 0.6, 1.2, 0.05, "×%.2f")

local accRow = new("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = BG1, BorderSizePixel = 0, LayoutOrder = nextOrder(pageSet) }, pageSet)
corner(accRow, 12)
stroke(accRow, LINE, 1)
new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -200, 1, 0), Font = Enum.Font.GothamMedium,
    TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = TXT, Text = "Цвет акцента",
}, accRow)
local accHolder = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(0, 30), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1 }, accRow)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center }, accHolder)
local accCircles = {}
for i, a in ipairs(ACCENTS) do
    local c = new("TextButton", { Size = UDim2.fromOffset(28, 28), BackgroundColor3 = a.c, BorderSizePixel = 0, Text = "", LayoutOrder = i, AutoButtonColor = false }, accHolder)
    corner(c, UDim.new(1, 0))
    accCircles[i] = stroke(c, Color3.new(1, 1, 1), 2)
    c.Activated:Connect(function() S.accent = i; queueSave(); applyAll() end)
end
controls.accent = { refresh = function()
    for i, s in ipairs(accCircles) do s.Transparency = (i == S.accent) and 0 or 1 end
end }
controls.accent.refresh()

local nameRow = new("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = BG1, BorderSizePixel = 0, LayoutOrder = nextOrder(pageSet) }, pageSet)
corner(nameRow, 12)
stroke(nameRow, LINE, 1)
new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -200, 1, 0), Font = Enum.Font.GothamMedium,
    TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = TXT, Text = "Имя тяночки",
}, nameRow)
local girlNameBox = new("TextBox", {
    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(160, 30), BackgroundColor3 = BG2,
    BorderSizePixel = 0, Font = Enum.Font.Code, TextSize = 13, TextColor3 = TXT, Text = S.girlName, ClearTextOnFocus = false,
}, nameRow)
corner(girlNameBox, UDim.new(1, 0))
controls.girlName = { refresh = function() girlNameBox.Text = S.girlName end }
girlNameBox.FocusLost:Connect(function()
    local n = girlNameBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
    if n == "" then n = defaults.girlName end
    S.girlName = n:sub(1, 14)
    girlNameBox.Text = S.girlName
    queueSave()
    applyAll()
end)

section(pageSet, "Система")
toggleRow(pageSet, "hotkeys", "Горячие клавиши", "RightShift - окно, F6 - играть/стоп, F7 - вставить из буфера")
toggleRow(pageSet, "antiAfk", "Анти-АФК", "Не кикнет за бездействие во время долгой игры")
local resetBtn = actionRow(pageSet, "Сбросить все настройки", BG2, function() end)
local unloadBtn = actionRow(pageSet, "Выгрузить скрипт", Color3.fromRGB(80, 42, 48), function() end)

local pageGuide = makePage("guide")
local function guide(title, body)
    infoCard(pageGuide, "<b><font size=\"15\">" .. title .. "</font></b>\n" .. body)
end
guide("🚀 Быстрый старт", "1. Подойди к пианино в игре и сядь за него.\n2. Вставь ноты в строку внизу: кнопка 📋 берёт текст из буфера, либо жми Ctrl+V.\n3. Нажми ▶. Окно можно закрыть: на островке сверху появится трек, как в Spotify.\n4. ■ (та же кнопка) останавливает игру, тут же отпускаются все клавиши.")
guide("🎼 Формат нот", "• <b>[abc]</b> — аккорд: клавиши нажимаются вместе.\n• <b>a b c</b> — ноты по очереди. Слитно <b>abc</b> тоже играется по буквам.\n• <b>-</b> или <b>|</b> — пауза (длину задаёт «Длина паузы»).\n• Заглавная буква (<b>T</b>, <b>W</b>) = клавиша с Shift, то есть диез.\n• Символы <b>! @ $ % ^ * (</b> = Shift+цифра (1, 2, 4, 5, 6, 8, 9).\n• Лишние символы пропускаются, их количество видно в чате.\nПример: <font face=\"Code\">[1e] 3 5 [6y] 5 3 - [4w] 6 8 [9o] 8 6</font>")
guide("⏱ Темп и ритм", "• <b>Скорость</b> — общий множитель. Быстро — 1.2–1.5, медленно — 0.7.\n• <b>Пауза между нотами</b> — главный регулятор темпа. Если ноты «слипаются», увеличь.\n• <b>Длительность нажатия</b> — слишком большая заглушает следующую ноту.\n• <b>Отсчёт</b> — секунды до старта, пока окно не скрыто.")
guide("🎹 Транспонирование", "Сдвигает всю мелодию на нужное число полутонов по раскладке на 61 клавишу. Если нота выходит за диапазон, она переносится на октаву. Удобно, когда песня написана выше или ниже, чем нужно.")
guide("◈ Антискрипт", "Включи вкладку «Антискрипт». Аккорд больше не нажимается одним махом: клавиши идут в случайном порядке с задержкой от минимума до максимума, а общий разброс ограничен лимитом (и 35% длительности ноты при «умном лимите»). Время нот и длительность нажатия слегка «дрожат». Таймлайн фиксированный, поэтому песня не замедляется и не уезжает, а сами ноты не меняются и не пропускаются.")
guide("📚 Библиотека", "Кнопка ▤ слева. Введи название, нажми «Сохранить». Клик по треку — загрузить в строку ввода, ▶ — играть, ✕ — удалить. «▶ Все» играет все треки подряд, 🔀 включает перемешивание, ↻ включает повтор. Треки хранятся в файле SWILL_Piano_Songs.json.")
guide("🏝 Остров", "В покое показывает FPS и ping. Когда играет музыка, превращается в плеер: название, прогресс, эквалайзер, пульсирующий в такт нотам. Клик по острову открывает и закрывает окно.")
guide("⌨ Горячие клавиши", "<b>RightShift</b> — окно. <b>F6</b> — играть/стоп. <b>F7</b> — вставить из буфера. Отключаются в настройках.")
guide("🛠 Если что-то не так", "• <b>Кнопка 📋 не работает</b> — экзекутор не отдаёт буфер. Нажми Ctrl+V в строке.\n• <b>Ноты не играются</b> — кликни в игру и убедись, что пианино активно.\n• <b>Пропускает ноты</b> — увеличь «Пауза между нотами» и выключи сильный антискрипт.\n• <b>Настройки не сохраняются</b> — нужен writefile у экзекутора.")

local state = { playing = false, id = 0, title = "", sub = "", progress = 0 }
local beat = 0
local statusLbl = nil
local hiddenByPlay = false
local fps, ping = 0, 0

local function shuffleList(t)
    for i = #t, 2, -1 do
        local j = rnd:NextInteger(1, i)
        t[i], t[j] = t[j], t[i]
    end
end

local function sleepUntil(tm, my)
    while state.id == my do
        local w = tm - os.clock()
        if w <= 0 then return true end
        task.wait(math.min(w, 0.1))
    end
    return false
end

local function pressEvent(keys, dur, my)
    local infos = {}
    for _, ch in ipairs(keys) do infos[#infos + 1] = keyMap[ch] end
    local hold = math.min(S.hold, dur * 0.8)
    if S.anti then
        hold = math.max(0.03, hold * (1 + rnd:NextNumber(-1, 1) * S.antiHold / 100))
        if S.antiOrder then shuffleList(infos) end
        local delays, total = {}, 0
        local lo, hi = S.antiMin, math.max(S.antiMin, S.antiMax)
        for i = 2, #infos do
            local d = rnd:NextNumber(lo, hi) / 1000
            delays[i] = d
            total = total + d
        end
        local cap = S.antiCap / 1000
        if S.antiSmart then cap = math.min(cap, dur * 0.35) end
        if total > cap and total > 0 then
            local k = cap / total
            for i = 2, #infos do delays[i] = delays[i] * k end
        end
        local start = os.clock()
        for i, info in ipairs(infos) do
            if state.id ~= my then break end
            if i > 1 and delays[i] > 0.002 then task.wait(delays[i]) end
            keyDown(info)
        end
        local rem = hold - (os.clock() - start)
        if rem > 0 then task.wait(rem) end
    else
        for _, info in ipairs(infos) do keyDown(info) end
        task.wait(hold)
    end
    for _, info in ipairs(infos) do keyUp(info) end
end

local function updateIslandInfo()
    titleLbl.Text = state.title
    subLbl.Text = state.sub
end

local function playEvents(events, my, titleText)
    local n = #events
    local t0, ideal, lastTick = os.clock(), 0, 0
    for i, ev in ipairs(events) do
        if state.id ~= my then return false end
        local dur = (ev.t == "r") and restDur() or noteDur()
        if ev.t == "n" then
            local onset = ideal
            if S.anti then
                local j = math.min(S.antiTiming / 1000, dur * 0.3)
                onset = onset + rnd:NextNumber(-j, j)
            end
            local target = t0 + onset
            if os.clock() - target > 0.5 then t0 = os.clock() - ideal; target = t0 + onset end
            if not sleepUntil(target, my) then return false end
            pressEvent(ev.keys, dur, my)
            beat = 1
            emitParticle()
        end
        ideal = ideal + dur
        state.progress = i / n
        if os.clock() - lastTick > 0.3 and statusLbl then
            lastTick = os.clock()
            statusLbl.Text = string.format("▶ «%s»  %d%%", titleText, math.floor(state.progress * 100))
        end
    end
    sleepUntil(t0 + ideal, my)
    return state.id == my
end

local function updatePlayBtn()
    sendBtn.Text = state.playing and "■" or "▶"
end

local function startSongs(list)
    if state.playing then return end
    if #list == 0 then say("Нечего играть. Вставь мелодию.") return end
    melodyBox:ReleaseFocus()
    nameBox:ReleaseFocus()
    state.id = state.id + 1
    local my = state.id
    state.playing = true
    state.progress = 0
    updatePlayBtn()

    if #list == 1 then
        local pv = list[1].text
        if #pv > 70 then pv = pv:sub(1, 70) .. "…" end
        sayUser(pv)
    else
        sayUser("▶ Играть все (" .. #list .. ")")
    end
    say("Хорошо. Я всё сделаю.")
    statusLbl = say("…")

    setIslandPlaying(true)
    state.title = list[1].title
    state.sub = S.girlName .. " • SWILL Piano"
    updateIslandInfo()

    if S.autohide and main.Visible and not busy then
        hiddenByPlay = true
        task.spawn(toggleWindow)
    end

    task.spawn(function()
        for c = S.countdown, 1, -1 do
            if state.id ~= my then return end
            statusLbl.Text = "Старт через " .. c .. "…"
            state.sub = "Старт через " .. c .. "…"
            updateIslandInfo()
            task.wait(1)
        end
        local playedAny
        repeat
            playedAny = false
            for idx, item in ipairs(list) do
                if state.id ~= my then break end
                local events, skipped = buildEvents(item.text, S.transpose)
                if #events == 0 then
                    say("«" .. item.title .. "»: нот не нашла, пропускаю.")
                else
                    playedAny = true
                    local notes = 0
                    for _, e in ipairs(events) do if e.t == "n" then notes = notes + 1 end end
                    state.title = item.title
                    state.sub = S.girlName .. " • " .. notes .. " нот • ~" .. fmtTime(estimate(events))
                        .. (#list > 1 and ("  [" .. idx .. "/" .. #list .. "]") or "")
                    updateIslandInfo()
                    statusLbl.Text = "▶ «" .. item.title .. "»  0%"
                    if skipped > 0 then say("Пропущено лишних символов: " .. skipped) end
                    playEvents(events, my, item.title)
                end
            end
        until state.id ~= my or not S.loop or not playedAny

        if state.id == my then
            state.playing = false
            state.progress = 1
            releaseAll()
            setIslandPlaying(false)
            updatePlayBtn()
            if statusLbl then statusLbl.Text = "✓ Готово" end
            if hiddenByPlay then
                hiddenByPlay = false
                if not main.Visible then task.spawn(toggleWindow) end
            end
        end
    end)
end

local function stopPlay()
    if not state.playing then return end
    state.id = state.id + 1
    state.playing = false
    releaseAll()
    setIslandPlaying(false)
    updatePlayBtn()
    if statusLbl then statusLbl.Text = "■ Остановлено" end
    if hiddenByPlay then
        hiddenByPlay = false
        if not main.Visible then task.spawn(toggleWindow) end
    end
end

local function currentTitle()
    local n = nameBox.Text
    if n ~= "" then return n end
    local m = melodyBox.Text
    return (#m > 18 and (m:sub(1, 18) .. "…") or (m ~= "" and m or "Без названия"))
end
local function playCurrent()
    if melodyBox.Text:match("^%s*$") then
        say("Строка пустая. Вставь мелодию (📋 или Ctrl+V).")
        return
    end
    startSongs({ { title = currentTitle(), text = melodyBox.Text } })
end

local function pasteClip()
    local txt = readClipboard()
    if txt then
        txt = txt:gsub("[\r\n\t]+", " "):gsub("^%s+", ""):gsub("%s+$", "")
        melodyBox.Text = txt
        say("Вставила из буфера: " .. #txt .. " симв.")
    else
        say("Экзекутор не отдаёт буфер. Нажми Ctrl+V прямо в строке.")
        melodyBox:CaptureFocus()
    end
end

local function refreshSongs()
    for _, c in ipairs(songList:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    for name, melody in pairs(savedSongs) do
        local row = new("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = BG2, BorderSizePixel = 0, Name = name }, songList)
        corner(row, 8)
        local load = new("TextButton", {
            Size = UDim2.new(1, -80, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = TXT,
            TextXAlignment = Enum.TextXAlignment.Left, Text = name, TextTruncate = Enum.TextTruncate.AtEnd,
        }, row)
        new("UIPadding", { PaddingLeft = UDim.new(0, 12) }, load)
        local pb = new("TextButton", {
            Size = UDim2.fromOffset(30, 26), Position = UDim2.new(1, -72, 0, 4), BorderSizePixel = 0, Font = Enum.Font.GothamBold,
            TextSize = 12, TextColor3 = Color3.new(0, 0, 0), Text = "▶",
        }, row)
        acc(pb, "BackgroundColor3")
        corner(pb, UDim.new(1, 0))
        local db = new("TextButton", {
            Size = UDim2.fromOffset(30, 26), Position = UDim2.new(1, -38, 0, 4), BackgroundColor3 = Color3.fromRGB(80, 42, 48),
            BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = TXT, Text = "✕",
        }, row)
        corner(db, UDim.new(1, 0))
        load.Activated:Connect(function() melodyBox.Text = melody; nameBox.Text = name; say("Загрузила «" .. name .. "» в строку.") end)
        pb.Activated:Connect(function()
            melodyBox.Text = melody
            nameBox.Text = name
            stopPlay()
            task.wait(0.05)
            startSongs({ { title = name, text = melody } })
        end)
        db.Activated:Connect(function() savedSongs[name] = nil; saveSongs(); refreshSongs() end)
    end
end

saveBtn.Activated:Connect(function()
    if melodyBox.Text:match("^%s*$") then say("Сначала вставь мелодию.") return end
    local n = nameBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
    if n == "" then
        local c = 1
        for _ in pairs(savedSongs) do c = c + 1 end
        n = "Трек " .. c
        nameBox.Text = n
    end
    savedSongs[n] = melodyBox.Text
    saveSongs()
    refreshSongs()
    say("Сохранила «" .. n .. "».")
end)
playAllBtn.Activated:Connect(function()
    local list = {}
    for name, melody in pairs(savedSongs) do list[#list + 1] = { title = name, text = melody } end
    table.sort(list, function(a, b) return a.title < b.title end)
    if S.shuffle then shuffleList(list) end
    switchTab("home")
    startSongs(list)
end)
shuffleBtn.Activated:Connect(function()
    S.shuffle = not S.shuffle
    queueSave()
    applyAll()
end)
refreshSongs()

local lastAccent = S.accent
local function refreshHomeButtons()
    for key, b in pairs(pills) do
        local on = S[key]
        b.BackgroundColor3 = on and BG2 or BG1
        b.BackgroundTransparency = on and 0 or 0.35
        b.TextColor3 = on and TXT or DIM
    end
    loopBtn.TextColor3 = S.loop and ACC() or DIM
    shuffleBtn.TextColor3 = S.shuffle and ACC() or DIM
    shuffleBtn.BackgroundColor3 = S.shuffle and BG1 or BG2
end

local function updateStats()
    if islandPlaying then return end
    if S.islandStats then
        statsLabel.Text = string.format("%d FPS  •  %d ms", fps, ping)
    else
        statsLabel.Text = "♪ SWILL Piano"
    end
end

applyAll = function()
    if lastAccent ~= S.accent then
        lastAccent = S.accent
        local live = {}
        for _, r in ipairs(accRefs) do
            if r[1]:IsDescendantOf(gui) then r[1][r[2]] = ACC(); live[#live + 1] = r end
        end
        accRefs = live
    end
    for _, c in pairs(controls) do c.refresh() end
    if main.Visible and not busy then scaleObj.Scale = baseScale() end
    girl.Visible = S.girl
    doodleFolder.Visible = S.doodles
    nameLbl.Text = S.girlName
    refreshHomeButtons()
    updateStats()
end

for key, b in pairs(pills) do
    b.Activated:Connect(function()
        S[key] = not S[key]
        queueSave()
        applyAll()
    end)
end

local view = "chat"
local function showView(v)
    view = v
    chatArea.Visible = (v == "chat")
    libView.Visible = (v == "lib")
    for key, b in pairs(sideBtns) do
        local on = (key == v)
        b.BackgroundTransparency = on and 0 or 1
        b.TextColor3 = on and TXT or DIM
    end
end
sideBtns.chat.Activated:Connect(function() showView("chat") end)
sideBtns.lib.Activated:Connect(function() showView("lib") end)
sideBtns.new.Activated:Connect(function()
    for _, r in ipairs(msgRows) do r:Destroy() end
    msgRows = {}
    melodyBox.Text = ""
    showView("chat")
    say("Новый чат. Вставь мелодию, и я всё сыграю.")
end)

plusBtn.Activated:Connect(function() plusMenu.Visible = not plusMenu.Visible end)
menuItem("📋  Вставить из буфера", pasteClip)
menuItem("🧹  Очистить строку", function() melodyBox.Text = "" end)
menuItem("🎵  Пример мелодии", function() melodyBox.Text = "[1e] 3 5 [6y] 5 3 - [4w] 6 8 [9o] 8 6 - [1e] 3 5 [8u] [6y] [3t] [1e]" end)
menuItem("💾  В библиотеку", function() showView("lib"); nameBox:CaptureFocus() end)

pasteBtn.Activated:Connect(pasteClip)
loopBtn.Activated:Connect(function() S.loop = not S.loop; queueSave(); applyAll() end)
sendBtn.Activated:Connect(function()
    if state.playing then stopPlay() else playCurrent() end
end)
melodyBox.FocusLost:Connect(function(enter)
    if enter and not state.playing then playCurrent() end
end)

minBtn.Activated:Connect(toggleWindow)
local presets, presetIdx = { 1, 0.85, 0.7 }, 1
sizeBtn.Activated:Connect(function()
    presetIdx = presetIdx % #presets + 1
    S.uiScale = presets[presetIdx]
    queueSave()
    applyAll()
end)
accentBtn.Activated:Connect(function() S.accent = S.accent % #ACCENTS + 1; queueSave(); applyAll() end)
doodleBtn.Activated:Connect(function() S.doodles = not S.doodles; queueSave(); applyAll() end)

resetBtn.Activated:Connect(function()
    for k, v in pairs(defaults) do S[k] = v end
    queueSave()
    applyAll()
    say("Настройки сброшены.")
end)

local function unload()
    pcall(function() state.id = state.id + 1; state.playing = false end)
    releaseAll()
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    pcall(function() gui:Destroy() end)
    pcall(function() if getgenv then getgenv().SWILL_UNLOAD = nil end end)
end
local function confirmUnload(btn, idleText, idleColor)
    local armed = false
    return function()
        if armed then unload() return end
        armed = true
        btn.Text = "Нажми ещё раз для подтверждения"
        task.delay(2.5, function()
            armed = false
            if btn.Parent then btn.Text = idleText end
        end)
    end
end
local unloadFn = confirmUnload(unloadBtn, "Выгрузить скрипт")
unloadBtn.Activated:Connect(unloadFn)
local armedClose = false
closeBtn.Activated:Connect(function()
    if armedClose then unload() return end
    armedClose = true
    closeBtn.Text = "?"
    closeBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
    task.delay(2.5, function()
        armedClose = false
        if closeBtn.Parent then closeBtn.Text = "✕"; closeBtn.TextColor3 = DIM end
    end)
end)
pcall(function() if getgenv then getgenv().SWILL_UNLOAD = unload end end)

track(UIS.InputBegan:Connect(function(input, processed)
    if processed or not S.hotkeys then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        toggleWindow()
    elseif input.KeyCode == Enum.KeyCode.F6 then
        if state.playing then stopPlay() else playCurrent() end
    elseif input.KeyCode == Enum.KeyCode.F7 then
        pasteClip()
    end
end))
track(camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    if main.Visible and not busy then scaleObj.Scale = baseScale() end
end))

track(player.Idled:Connect(function()
    if S.antiAfk then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end))

local function getPing()
    local ok, v = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
    if ok and type(v) == "number" and v > 0 then return math.floor(v + 0.5) end
    local ok2, p = pcall(function() return player:GetNetworkPing() end)
    if ok2 and type(p) == "number" then return math.floor(p * 2000 + 0.5) end
    return 0
end
local frames, accT = 0, 0
track(RunService.RenderStepped:Connect(function(dt)
    frames = frames + 1
    accT = accT + dt
    if accT >= 0.5 then
        fps = math.floor(frames / accT + 0.5)
        frames, accT = 0, 0
        updateStats()
    end
end))
task.spawn(function()
    while gui.Parent do
        ping = getPing()
        updateStats()
        task.wait(1)
    end
end)

local t, phase = 0, 0
track(RunService.Heartbeat:Connect(function(dt)
    t = t + dt
    beat = math.max(0, beat - dt * 4)

    if islandPlaying then
        for i, b in ipairs(eqBars) do
            local base = (math.sin(t * (6 + i * 1.7) + i) * 0.5 + 0.5)
            b.Size = UDim2.fromOffset(5, math.floor(4 + base * 6 + beat * (8 + i * 2)))
        end
        progFill.Size = UDim2.fromScale(math.clamp(state.progress, 0, 1), 1)
        local off = titleLbl.TextBounds.X - titleClip.AbsoluteSize.X
        if off > 0 then
            local p = (t * 0.35) % 2
            if p > 1 then p = 2 - p end
            p = math.clamp((p - 0.15) / 0.7, 0, 1)
            titleLbl.Position = UDim2.fromOffset(-off * p, 0)
        else
            titleLbl.Position = UDim2.fromOffset(0, 0)
        end
    end

    if not main.Visible then return end

    if S.doodles then
        for _, d in ipairs(floaters) do
            d.i.Position = UDim2.new(d.x, math.sin(t * d.s + d.p) * d.a, d.y, math.cos(t * d.s * 0.8 + d.p) * d.a)
            d.i.Rotation = d.r + math.sin(t * d.s + d.p) * 5
        end
    end

    if S.girl then
        phase = phase + dt * (state.playing and 6 or 2.2)
        local sw = math.sin(phase) * (state.playing and 20 or 12)
        legL.Rotation = sw
        legR.Rotation = -sw
        girl.Position = UDim2.new(0, WIN_W - 235, 0, girlBaseY + math.floor(math.sin(phase * 0.9) * 1.5 + 0.5) * (state.playing and 2 or 1))
        local blink = (t % 3.6) < 0.14
        lidL.Visible = blink
        lidR.Visible = blink
    end
end))

switchTab("home")
showView("chat")
applyAll()
say("Привет! Я " .. S.girlName .. ". Вставь мелодию, и я всё сыграю.")
task.defer(toggleWindow)
print("[SWILL] Piano Ultra v3 загружен.")
