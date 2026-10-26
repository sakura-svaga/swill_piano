--============================================================
--  SWILL • Piano Ultra v5 (FULL ABSOLUTE)
--  Всё в одном файле. Остров как в Spotify. Все функции.
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

-- ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
conns = {}
rnd = Random.new()
SETTINGS_FILE = "SWILL_Piano_Settings.json"
SONGS_FILE    = "SWILL_Piano_Songs.json"

defaults = {
    speed = 1, tempo = 50, hold = 0.09, rest = 0.22, gap = 0.05,
    transpose = 0, countdown = 0, loop = false, shuffle = false,
    anti = false, antiMin = 8, antiMax = 35, antiCap = 90,
    antiTiming = 18, antiHold = 15, antiOrder = true, antiSmart = true,
    particles = true, girl = true, doodles = true, autohide = false,
    hotkeys = true, islandStats = true, antiAfk = true,
    uiScale = 1, accent = 1, girlName = "Саша",
}
S = {}
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

saveQueued = false
function queueSave()
    if saveQueued then return end; saveQueued = true
    task.delay(0.6, function()
        saveQueued = false
        pcall(function() if writefile then writefile(SETTINGS_FILE, HttpService:JSONEncode(S)) end end)
    end)
end

savedSongs = {}
pcall(function()
    if isfile and isfile(SONGS_FILE) then
        local d = HttpService:JSONDecode(readfile(SONGS_FILE))
        if type(d) == "table" then savedSongs = d end
    end
end)
function saveSongs() pcall(function() if writefile then writefile(SONGS_FILE, HttpService:JSONEncode(savedSongs)) end end) end

BG0, BG1, BG2 = Color3.fromRGB(15, 15, 17), Color3.fromRGB(28, 28, 32), Color3.fromRGB(42, 42, 47)
BUB, TXT, DIM, LINE = Color3.fromRGB(38, 38, 43), Color3.fromRGB(228, 228, 233), Color3.fromRGB(136, 136, 146), Color3.fromRGB(56, 56, 62)
ACCENTS = { { name = "Золото", c = Color3.fromRGB(201, 162, 39) }, { name = "Роза", c = Color3.fromRGB(255, 138, 178) }, { name = "Небо", c = Color3.fromRGB(96, 160, 255) }, { name = "Мята", c = Color3.fromRGB(110, 222, 170) } }
function ACC() return ACCENTS[S.accent].c end

accRefs = {}
function acc(obj, prop) accRefs[#accRefs + 1] = { obj, prop }; obj[prop] = ACC(); return obj end
function new(class, props, parent) local o = Instance.new(class); for k, v in pairs(props) do o[k] = v end; if parent then o.Parent = parent end; return o end
function corner(o, r) return new("UICorner", { CornerRadius = typeof(r) == "UDim" and r or UDim.new(0, r) }, o) end
function stroke(o, c, th) return new("UIStroke", { Color = c or LINE, Thickness = th or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o) end
function tween(o, t, props, style, dir) local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props); tw:Play(); return tw end
function fmtTime(sec) sec = math.max(0, math.floor(sec + 0.5)); return string.format("%d:%02d", math.floor(sec / 60), sec % 60) end

keyMap = {}
for _, L in ipairs({"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"}) do
    keyMap[L:lower()] = { key = Enum.KeyCode[L], shift = false }
    keyMap[L]         = { key = Enum.KeyCode[L], shift = true  }
end
local digitNames = {"Zero","One","Two","Three","Four","Five","Six","Seven","Eight","Nine"}
for i = 0, 9 do keyMap[tostring(i)] = { key = Enum.KeyCode[digitNames[i + 1]], shift = false } end
keyMap["!"] = { key = Enum.KeyCode.One, shift = true }; keyMap["@"] = { key = Enum.KeyCode.Two, shift = true }
keyMap["$"] = { key = Enum.KeyCode.Four, shift = true }; keyMap["%"] = { key = Enum.KeyCode.Five, shift = true }
keyMap["^"] = { key = Enum.KeyCode.Six, shift = true }; keyMap["*"] = { key = Enum.KeyCode.Eight, shift = true }
keyMap["("] = { key = Enum.KeyCode.Nine, shift = true }; keyMap["-"] = { key = Enum.KeyCode.Minus, shift = false }
keyMap["="] = { key = Enum.KeyCode.Equals, shift = false }; keyMap["["] = { key = Enum.KeyCode.LeftBracket, shift = false }
keyMap["]"] = { key = Enum.KeyCode.RightBracket, shift = false }; keyMap[";"] = { key = Enum.KeyCode.Semicolon, shift = false }
keyMap["'"] = { key = Enum.KeyCode.Quote, shift = false }; keyMap[","] = { key = Enum.KeyCode.Comma, shift = false }
keyMap["."] = { key = Enum.KeyCode.Period, shift = false }; keyMap["/"] = { key = Enum.KeyCode.Slash, shift = false }
keyMap["\\"] = { key = Enum.KeyCode.BackSlash, shift = false }; keyMap["`"] = { key = Enum.KeyCode.Backquote, shift = false }

SEQ = "1!2@34$5%6^78*9(0qQwWeErtTyYuiIoOpPasSdDfgGhHjJklLzZxcCvVbBnm"
SEQ_IDX = {}
for i = 1, #SEQ do SEQ_IDX[SEQ:sub(i, i)] = i end
function transposeChars(str, n)
    if n == 0 then return str end
    return (str:gsub(".", function(ch) local i = SEQ_IDX[ch]; if not i then return ch end; local j = i + n; while j < 1 do j = j + 12 end; while j > #SEQ do j = j - 12 end; return SEQ:sub(j, j) end))
end

held = {}
function keyDown(info) if info.shift then VIM:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game) end; VIM:SendKeyEvent(true, info.key, false, game); if info.shift then VIM:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game) end; held[info.key] = true end
function keyUp(info) VIM:SendKeyEvent(false, info.key, false, game); held[info.key] = nil end
function releaseAll() for k in pairs(held) do VIM:SendKeyEvent(false, k, false, game) end; held = {} end

function parseSong(str)
    local tokens, i, n = {}, 1, #str
    while i <= n do
        local c = str:sub(i, i)
        if c == "[" then local j = str:find("]", i, true); if j then table.insert(tokens, { chord = str:sub(i + 1, j - 1) }); i = j + 1 else i = i + 1 end
        elseif c:match("%s") then i = i + 1
        else local j = i; while j <= n and not str:sub(j, j):match("%s") and str:sub(j, j) ~= "[" do j = j + 1 end; table.insert(tokens, { note = str:sub(i, j - 1) }); i = j end
    end
    return tokens
end

function buildEvents(text, trans)
    local events, skipped = {}, 0
    for _, tk in ipairs(parseSong(text)) do
        if tk.chord then local s, valid = transposeChars(tk.chord, trans), {}; for ch in s:gmatch(".") do if keyMap[ch] then valid[#valid + 1] = ch else skipped = skipped + 1 end end; if #valid > 0 then events[#events + 1] = { t = "n", keys = valid } end
        elseif tk.note == "-" or tk.note == "|" then events[#events + 1] = { t = "r" }
        else for ch in transposeChars(tk.note, trans):gmatch(".") do if ch == "-" or ch == "|" then events[#events + 1] = { t = "r" } elseif keyMap[ch] then events[#events + 1] = { t = "n", keys = { ch } } else skipped = skipped + 1 end end end
    end
    return events, skipped
end

function noteDur() return (S.hold + S.gap + S.tempo / 1000) / S.speed end
function restDur() return (S.rest + S.gap + S.tempo / 1000) / S.speed end

function readClipboard()
    local fns = { getclipboard, function() return syn.get_clipboard() end, readclipboard, fromclipboard }
    for _, f in ipairs(fns) do local ok, v = pcall(f); if ok and type(v) == "string" and v ~= "" then return v end end
    return nil
end

function guiParent() local ok, h = pcall(function() return gethui and gethui() end); return (ok and h) or playerGui end
for _, p in ipairs({ guiParent(), playerGui }) do local old = p:FindFirstChild("SWILL_Piano_Ultra"); if old then old:Destroy() end end
gui = new("ScreenGui", { Name = "SWILL_Piano_Ultra", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999 }, guiParent())

-- ============================================================
-- ОСТРОВ (SPOTIFY MODE)
-- ============================================================
island = new("TextButton", { Size = UDim2.fromOffset(190, 34), Position = UDim2.new(0.5, -95, 0, 10), BackgroundColor3 = BG0, Text = "", AutoButtonColor = false, Active = true, ZIndex = 999, ClipsDescendants = true }, gui)
corner(island, UDim.new(1, 0)); stroke(island, LINE, 1)
statsLabel = new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = TXT }, island)
pg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false }, island)
cover = new("Frame", { Position = UDim2.fromOffset(10, 9), Size = UDim2.fromOffset(32, 32) }, pg); acc(cover, "BackgroundColor3"); corner(cover, 9)
new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 17, TextColor3 = Color3.fromRGB(20, 20, 22), Text = "♪" }, cover)
titleClip = new("Frame", { Position = UDim2.fromOffset(52, 7), Size = UDim2.fromOffset(186, 18), BackgroundTransparency = 1, ClipsDescendants = true }, pg)
titleLbl = new("TextLabel", { Size = UDim2.fromOffset(0, 18), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = TXT, TextXAlignment = Enum.TextXAlignment.Left }, titleClip)
subLbl = new("TextLabel", { Position = UDim2.fromOffset(52, 25), Size = UDim2.fromOffset(186, 14), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Left }, pg)
eqBars = {}
for i = 1, 4 do local b = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromOffset(264 + (i - 1) * 8, 36), Size = UDim2.fromOffset(5, 6) }, pg); acc(b, "BackgroundColor3"); corner(b, 2); eqBars[i] = b end
progTrack = new("Frame", { Position = UDim2.fromOffset(52, 43), Size = UDim2.fromOffset(244, 3), BackgroundColor3 = BG2 }, pg); corner(progTrack, UDim.new(1, 0))
progFill = new("Frame", { Size = UDim2.fromScale(0, 1) }, progTrack); acc(progFill, "BackgroundColor3"); corner(progFill, UDim.new(1, 0))

islandPlaying = false
function setIslandPlaying(on)
    if on == islandPlaying then return end; islandPlaying = on
    if on then statsLabel.Visible = false; pg.Visible = true; tween(island, 0.38, { Size = UDim2.fromOffset(310, 50), Position = UDim2.new(0.5, -155, 0, 8) }, Enum.EasingStyle.Back)
    else pg.Visible = false; statsLabel.Visible = true; tween(island, 0.25, { Size = UDim2.fromOffset(190, 34), Position = UDim2.new(0.5, -95, 0, 10) }) end
end

-- ============================================================
-- ГЛАВНОЕ ОКНО
-- ============================================================
WIN_W, WIN_H = 720, 480
main = new("Frame", { Size = UDim2.fromOffset(WIN_W, WIN_H), Position = UDim2.fromScale(0.5, 0.56), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), Visible = false, ZIndex = 2 }, gui)
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
drng = Random.new(11); DOOD = Color3.fromRGB(92, 92, 102); floaters = {}
function addFloater(inst, x, y, amp, spd, rot) floaters[#floaters + 1] = { i = inst, x = x, y = y, a = amp, s = spd, p = drng:NextNumber(0, 6.28), r = rot } end
glyphs = {"♡", "☆", "♪", "?", "!!", "zzz", "hi", "ok", "hmm...", "✧", "♫", "?!", "♡", "☆", "~"}
for _ = 1, 24 do local l = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(70, 40), AnchorPoint = Vector2.new(0.5, 0.5), Text = glyphs[drng:NextInteger(1, #glyphs)], Font = Enum.Font.PatrickHand, TextSize = drng:NextInteger(20, 40), TextColor3 = DOOD, TextTransparency = 0.6 }, doodleFolder); addFloater(l, drng:NextNumber(0.03, 0.97), drng:NextNumber(0.14, 0.97), 7, drng:NextNumber(0.4, 1.0), drng:NextInteger(-25, 25)) end
function makeSpiral(size) local c = new("Frame", { Size = UDim2.fromOffset(size, size), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1 }, doodleFolder); local N = 48; for k = 1, N do local a, r = k * 0.42, (k / N) * size * 0.5; new("Frame", { Size = UDim2.fromOffset(2, 2), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, math.cos(a) * r, 0.5, math.sin(a) * r), BackgroundColor3 = DOOD, BackgroundTransparency = 0.5 }, c) end return c end
function makeHatch(w, h, n) local c = new("Frame", { Size = UDim2.fromOffset(w, h), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1 }, doodleFolder); for k = 0, n - 1 do new("Frame", { Position = UDim2.fromOffset(k * (w / n), 0), Size = UDim2.fromOffset(2, h), BackgroundColor3 = DOOD, BackgroundTransparency = 0.55, Rotation = 22 }, c) end return c end
for _ = 1, 6 do addFloater(makeSpiral(drng:NextInteger(50, 90)), drng:NextNumber(0.05, 0.95), drng:NextNumber(0.2, 0.95), 5, drng:NextNumber(0.2, 0.5), drng:NextInteger(-180, 180)) end
for _ = 1, 5 do addFloater(makeHatch(drng:NextInteger(40, 70), drng:NextInteger(40, 70), 6), drng:NextNumber(0.05, 0.95), drng:NextNumber(0.2, 0.95), 6, drng:NextNumber(0.3, 0.7), drng:NextInteger(-15, 15)) end

lastEmit = 0
function emitParticle()
    if not S.particles or not main.Visible then return end
    if os.clock() - lastEmit < 0.1 then return end; lastEmit = os.clock()
    local x = rnd:NextNumber(0.05, 0.95)
    local p = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(30, 30), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(x, 0, 1, 10), Text = ({"♪", "♫", "✦", "♡"})[rnd:NextInteger(1, 4)], Font = Enum.Font.PatrickHand, TextSize = rnd:NextInteger(18, 34), TextColor3 = ACC(), ZIndex = 2 }, bgClip)
    tween(p, 1.8, { Position = UDim2.new(x + rnd:NextNumber(-0.08, 0.08), 0, rnd:NextNumber(0.2, 0.55), 0), TextTransparency = 1, Rotation = rnd:NextInteger(-40, 40) }, Enum.EasingStyle.Sine).Completed:Connect(function() p:Destroy() end)
end

header = new("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Active = true, ZIndex = 5 }, main)
new("TextLabel", { Size = UDim2.fromOffset(180, 24), Position = UDim2.fromOffset(22, 12), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = DIM, Text = "SWILL • Piano" }, header)
function winBtn(text, xOff) local b = new("TextButton", { Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, xOff, 0, 12), BackgroundColor3 = BG1, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = DIM, Text = text }, header); corner(b, UDim.new(1, 0)); return b end
minBtn = winBtn("–", -114); sizeBtn = winBtn("□", -78); closeBtn = winBtn("✕", -42)
dragging, dragStart, startPos = false, nil, nil
header.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging, dragStart, startPos = true, input.Position, main.Position; input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end) end end)
UIS.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local d = (input.Position - dragStart) / scaleObj.Scale; main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y) end end)
minBtn.Activated:Connect(toggleWindow); closeBtn.Activated:Connect(toggleWindow)

-- Тяночка
PX = 4; gp = { O = Color3.fromRGB(78, 64, 82), H = Color3.fromRGB(248, 236, 218), h = Color3.fromRGB(222, 200, 184), g = Color3.fromRGB(196, 170, 160), S = Color3.fromRGB(255, 232, 220), s = Color3.fromRGB(240, 205, 195), E = Color3.fromRGB(92, 150, 255), e = Color3.fromRGB(170, 212, 255), D = Color3.fromRGB(40, 44, 90), W = Color3.fromRGB(252, 252, 255), w = Color3.fromRGB(206, 212, 230), K = Color3.fromRGB(58, 60, 84), k = Color3.fromRGB(84, 88, 118), B = Color3.fromRGB(96, 160, 255), P = Color3.fromRGB(255, 160, 160), M = Color3.fromRGB(214, 110, 120) }
rep = string.rep
girlRows = { "OO", "OHHO", rep("O", 8), "OO"..rep("H", 8).."OO", "O".."HH".."BB"..rep("H", 8).."O", "O"..rep("H", 14).."O", "O".."HHH".."h"..rep("H", 6).."h".."HHH".."O", "O"..rep("H", 5).."SS".."HH".."SS"..rep("H", 5).."O", "O"..rep("H", 4)..rep("S", 8)..rep("H", 4).."O", "O"..rep("H", 3)..rep("S", 10)..rep("H", 3).."O", "O"..rep("H", 3)..rep("S", 10)..rep("H", 3).."O", "O".."HHH".."SDDDSSDDDS".."HHH".."O", "O".."HHH".."SeDESSeDES".."HHH".."O", "O".."HHH".."SEEESSEEES".."HHH".."O", "O".."HHH".."PPSSSSSSPP".."HHH".."O", "O".."hHH".."SSSSMMSSSS".."HHh".."O", "O".."hHHH".."sSSSSSSs".."HHHh".."O", "OhHH"..".".."sSSSSs"..".".."HHhO", "OhH".."...".."sSSs".."...".."HhO", "ghH"..rep(".", 4).."sSSs"..rep(".", 4).."Hhg", "wWWWBBWWWw", "SwWWWBBWWWwS", "S".."w"..rep("W", 8).."w".."S", "sSWWKKKKWWSs", "k"..rep("K", 10).."k", "k"..rep("K", 12).."k", "k"..rep("K", 14).."k", "WwWwWwWwWwWwWwWw" }
ROWS, COLS = #girlRows, 22
girlBaseY = -ROWS * PX + 2
girl = new("Frame", { Size = UDim2.fromOffset(COLS * PX, ROWS * PX), Position = UDim2.new(0, WIN_W - 235, 0, girlBaseY), BackgroundTransparency = 1, ZIndex = 20 }, main)
function makeLeg(col) local c = new("Frame", { Size = UDim2.fromOffset(3 * PX, 14 * PX), Position = UDim2.fromOffset(col * PX, ROWS * PX - 7 * PX - 2), BackgroundTransparency = 1, ZIndex = 1 }, girl); new("Frame", { Position = UDim2.fromOffset(0, 7 * PX), Size = UDim2.fromOffset(3 * PX, 5 * PX), BackgroundColor3 = gp.S }, c); new("Frame", { Position = UDim2.fromOffset(0, 12 * PX), Size = UDim2.fromOffset(3 * PX + 2, 2 * PX), BackgroundColor3 = gp.k }, c); return c end
legL, legR = makeLeg(7), makeLeg(12)
sprite = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2 }, girl)
for y, row in ipairs(girlRows) do local pad = math.floor((COLS - #row) / 2); local x = 1; while x <= #row do local ch = row:sub(x, x); if ch ~= "." then local e = x; while e < #row and row:sub(e + 1, e + 1) == ch do e = e + 1 end; new("Frame", { Position = UDim2.fromOffset((pad + x - 1) * PX, (y - 1) * PX), Size = UDim2.fromOffset((e - x + 1) * PX, PX), BackgroundColor3 = gp[ch] }, sprite); x = e + 1 else x = x + 1 end end end
function makeLid(col) local f = new("Frame", { Position = UDim2.fromOffset(col * PX, 12 * PX), Size = UDim2.fromOffset(3 * PX, 2 * PX), BackgroundColor3 = gp.S, Visible = false, ZIndex = 3 }, sprite); new("Frame", { Position = UDim2.fromOffset(0, PX + PX / 2), Size = UDim2.fromOffset(3 * PX, PX / 2), BackgroundColor3 = gp.D }, f); return f end
lidL, lidR = makeLid(7), makeLid(12)

-- Вкладки
tabsFrame = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, -10, 0, 46), Size = UDim2.fromOffset(0, 38), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Color3.fromRGB(22, 22, 25), ZIndex = 5 }, main)
corner(tabsFrame, UDim.new(1, 0)); stroke(tabsFrame, LINE, 1)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 3), VerticalAlignment = Enum.VerticalAlignment.Center }, tabsFrame)
new("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) }, tabsFrame)
rightPill = new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -22, 0, 46), Size = UDim2.fromOffset(84, 38), BackgroundColor3 = Color3.fromRGB(22, 22, 25), ZIndex = 5 }, main); corner(rightPill, UDim.new(1, 0)); stroke(rightPill, LINE, 1)
function pillIcon(text, x) local b = new("TextButton", { Position = UDim2.fromOffset(x, 4), Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = TXT, Text = text }, rightPill); corner(b, UDim.new(1, 0)); return b end
accentBtn = pillIcon("◐", 8); doodleBtn = pillIcon("❖", 46)

content = new("Frame", { Position = UDim2.fromOffset(16, 96), Size = UDim2.new(1, -32, 1, -110), BackgroundTransparency = 1, ZIndex = 5 }, main)
tabs, pages, activeTab = {}, {}, nil
orders = {}
function nextOrder(p) orders[p] = (orders[p] or 0) + 1 return orders[p] end

function switchTab(name)
    if activeTab then tween(tabs[activeTab], 0.15, { BackgroundTransparency = 1, TextColor3 = DIM }); pages[activeTab].Visible = false end
    activeTab = name; tween(tabs[name], 0.15, { BackgroundTransparency = 0, TextColor3 = TXT }); pages[name].Visible = true
end
function createTab(name, text, order)
    local b = new("TextButton", { Size = UDim2.fromOffset(0, 30), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = BG2, BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = DIM, Text = text, LayoutOrder = order, AutoButtonColor = false }, tabsFrame)
    corner(b, UDim.new(1, 0)); new("UIPadding", { PaddingLeft = UDim.new(0, 13), PaddingRight = UDim.new(0, 13) }, b)
    b.Activated:Connect(function() switchTab(name) end); tabs[name] = b
end
function makePage(name)
    local p = new("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = false }, content)
    new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, p); pages[name] = p; return p
end
createTab("home", "Главная", 1); createTab("play", "Игра", 2); createTab("anti", "Антискрипт", 3); createTab("set", "Настройки", 4); createTab("guide", "Гайд", 5)

-- Главная: сайдбар + чат + ввод + пилюли
homePage = new("Frame", { Position = UDim2.fromOffset(0, 92), Size = UDim2.new(1, 0, 1, -92), BackgroundTransparency = 1, Visible = false, ZIndex = 5 }, main); pages["home"] = homePage
sideBtns = {}
function sideBtn(key, text, y) local b = new("TextButton", { Position = UDim2.fromOffset(24, y), Size = UDim2.fromOffset(40, 40), BackgroundColor3 = BG2, BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = DIM, Text = text }, homePage); corner(b, 10); sideBtns[key] = b; return b end
sideBtn("chat", "✦", 8); sideBtn("lib", "▤", 56); sideBtn("new", "✎", 104)

chatArea = new("Frame", { Position = UDim2.fromOffset(84, 0), Size = UDim2.new(1, -118, 1, -100), BackgroundTransparency = 1 }, homePage)
chatScroll = new("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, chatArea)
new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, chatScroll)
new("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }, chatScroll)

msgOrder, msgRows = 0, {}
function addMsg(who, text)
    msgOrder = msgOrder + 1
    local row = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = msgOrder }, chatScroll)
    new("UIListLayout", { HorizontalAlignment = who == "user" and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left }, row)
    local bub = new("Frame", { Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = BUB }, row)
    corner(bub, 16); new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }, bub)
    local lbl = new("TextLabel", { Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 14, TextColor3 = TXT, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Text = text }, bub)
    new("UISizeConstraint", { MaxSize = Vector2.new(400, math.huge) }, lbl)
    msgRows[#msgRows + 1] = row; if #msgRows > 40 then table.remove(msgRows, 1):Destroy() end
    task.delay(0.06, function() chatScroll.CanvasPosition = Vector2.new(0, 99999) end)
    return lbl
end
function say(text) return addMsg("bot", text) end
function sayUser(text) return addMsg("user", text) end

libView = new("Frame", { Position = UDim2.fromOffset(84, 0), Size = UDim2.new(1, -118, 1, -100), BackgroundTransparency = 1, Visible = false }, homePage)
libTop = new("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1 }, libView)
nameBox = new("TextBox", { Size = UDim2.new(1, -250, 1, 0), BackgroundColor3 = BG1, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = TXT, PlaceholderText = "Название трека...", PlaceholderColor3 = DIM }, libTop)
corner(nameBox, UDim.new(1, 0)); stroke(nameBox, LINE, 1); new("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 10) }, nameBox)
function libBtn(text, xOff, w, filled) local b = new("TextButton", { Position = UDim2.new(1, xOff, 0, 0), Size = UDim2.fromOffset(w, 38), BackgroundColor3 = BG2, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = filled and Color3.new(0, 0, 0) or TXT, Text = text }, libTop); corner(b, UDim.new(1, 0)); if filled then acc(b, "BackgroundColor3") end; return b end
saveBtn = libBtn("Сохранить", -242, 90, true); playAllBtn = libBtn("▶ Все", -146, 62, true); shuffleBtn = libBtn("🔀", -78, 36, false)
songList = new("ScrollingFrame", { Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 1, -46), BackgroundColor3 = BG1, ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, libView)
corner(songList, 14); stroke(songList, LINE, 1); new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 10) }, songList)
new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.Name }, songList)

inputBar = new("Frame", { Position = UDim2.new(0, 84, 1, -92), Size = UDim2.new(1, -118, 0, 52), BackgroundColor3 = Color3.fromRGB(24, 24, 27) }, homePage)
corner(inputBar, UDim.new(1, 0)); stroke(inputBar, LINE, 1)
plusBtn = new("TextButton", { Position = UDim2.fromOffset(10, 6), Size = UDim2.fromOffset(40, 40), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 24, TextColor3 = TXT, Text = "+" }, inputBar)
melodyBox = new("TextBox", { Position = UDim2.fromOffset(58, 0), Size = UDim2.new(1, -206, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 14, TextColor3 = TXT, PlaceholderText = "Мелодия...", PlaceholderColor3 = DIM, ClearTextOnFocus = false }, inputBar)
function inBtn(text, xOff, size, fillBg) local b = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, xOff, 0.5, 0), Size = UDim2.fromOffset(size, size), BackgroundColor3 = Color3.fromRGB(46, 46, 52), BackgroundTransparency = fillBg and 0 or 1, Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = TXT, Text = text }, inputBar); corner(b, fillBg and 12 or UDim.new(1, 0)); return b end
sendBtn = inBtn("▶", -8, 40, true); loopBtn = inBtn("↻", -56, 36, false); pasteBtn = inBtn("📋", -98, 36, false)

plusMenu = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 84, 1, -100), Size = UDim2.fromOffset(230, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Color3.fromRGB(26, 26, 30), Visible = false, ZIndex = 30 }, homePage)
corner(plusMenu, 14); stroke(plusMenu, LINE, 1); new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, plusMenu)
new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, plusMenu)
function menuItem(text, cb) local b = new("TextButton", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = BG2, BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = TXT, Text = text, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = nextOrder(plusMenu), ZIndex = 31 }, plusMenu); corner(b, 8); new("UIPadding", { PaddingLeft = UDim.new(0, 12) }, b); b.MouseEnter:Connect(function() b.BackgroundTransparency = 0 end); b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end); b.Activated:Connect(function() plusMenu.Visible = false; cb() end) end
menuItem("📋 Вставить", function() local txt = readClipboard(); if txt then melodyBox.Text = txt; say("Вставлено") end end)
menuItem("🧹 Очистить", function() melodyBox.Text = "" end)
menuItem("💾 Библиотека", function() showView("lib") end)

pillRow = new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 30, 1, -12), Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1 }, homePage)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center }, pillRow)
pills = {}
function makePill(text, key) local b = new("TextButton", { Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X, Font = Enum.Font.GothamBold, TextSize = 11, Text = text }, pillRow); corner(b, UDim.new(1, 0)); new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, b); pills[key] = b; return b end
makePill("◈ АНТИ", "anti"); makePill("↻ ПОВТОР", "loop"); makePill("✦ ЧАСТИЦЫ", "particles")
nameLbl = new("TextLabel", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 22, 1, -14), Size = UDim2.fromOffset(100, 16), BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 12, TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Left, Text = S.girlName }, homePage)

-- Настройки (Спиннеры)
pagePlay = pages["play"]; pageAnti = pages["anti"]; pageSet = pages["set"]; pageGuide = pages["guide"]
function makeSpinner(parent, key, label, min, max, step)
    local f = new("Frame", { Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = BG1, LayoutOrder = nextOrder(parent) }, parent); corner(f, 10)
    new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 15), Size = UDim2.new(1, -120, 0, 20), Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = TXT, Text = label }, f)
    local val = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(1, -100, 0, 15), Size = UDim2.fromOffset(40, 20), Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = ACC(), Text = tostring(S[key]) }, f)
    local minus = new("TextButton", { Position = UDim2.new(1, -55, 0, 10), Size = UDim2.fromOffset(24, 30), BackgroundColor3 = BG2, Text = "-", TextColor3 = TXT, Font = Enum.Font.GothamBold }, f); corner(minus, 6)
    local plus = new("TextButton", { Position = UDim2.new(1, -25, 0, 10), Size = UDim2.fromOffset(24, 30), BackgroundColor3 = BG2, Text = "+", TextColor3 = TXT, Font = Enum.Font.GothamBold }, f); corner(plus, 6)
    minus.MouseButton1Click:Connect(function() S[key] = math.max(min, S[key] - step); val.Text = tostring(S[key]); queueSave() end)
    plus.MouseButton1Click:Connect(function() S[key] = math.min(max, S[key] + step); val.Text = tostring(S[key]); queueSave() end)
end
makeSpinner(pagePlay, "tempo", "Темп (мс)", 10, 300, 10)
makeSpinner(pagePlay, "speed", "Скорость", 0.5, 2, 0.1)
makeSpinner(pagePlay, "transpose", "Транспонирование", -12, 12, 1)

function makeToggle(parent, key, label)
    local f = new("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = BG1, LayoutOrder = nextOrder(parent) }, parent); corner(f, 10)
    new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -80, 1, 0), Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = TXT, Text = label }, f)
    local btn = new("TextButton", { Position = UDim2.new(1, -70, 0, 5), Size = UDim2.fromOffset(60, 30), BackgroundColor3 = S[key] and ACC() or BG2, Text = S[key] and "ДА" or "НЕТ", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = S[key] and Color3.new(0,0,0) or TXT }, f); corner(btn, 6)
    btn.MouseButton1Click:Connect(function() S[key] = not S[key]; btn.Text = S[key] and "ДА" or "НЕТ"; btn.BackgroundColor3 = S[key] and ACC() or BG2; btn.TextColor3 = S[key] and Color3.new(0,0,0) or TXT; queueSave(); if key == "girl" then girl.Visible = S.girl end end)
end
makeToggle(pageSet, "girl", "Показывать тяночку")
makeToggle(pageSet, "particles", "Частицы")
makeToggle(pageSet, "doodles", "Фон-дудлы")

local antiBtn = new("TextButton", { Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = S.anti and ACC() or BG2, Text = S.anti and "Антискрипт: ВКЛ" or "Антискрипт: ВЫКЛ", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = S.anti and Color3.new(0,0,0) or TXT, LayoutOrder = nextOrder(pageAnti) }, pageAnti); corner(antiBtn, 10)
antiBtn.MouseButton1Click:Connect(function() S.anti = not S.anti; antiBtn.Text = S.anti and "Антискрипт: ВКЛ" or "Антискрипт: ВЫКЛ"; antiBtn.BackgroundColor3 = S.anti and ACC() or BG2; antiBtn.TextColor3 = S.anti and Color3.new(0,0,0) or TXT; queueSave() end)

-- Логика плеера
state = { playing = false, id = 0, progress = 0 }
function playEvents(events, my)
    local t0 = os.clock(); local ideal = 0
    for i, ev in ipairs(events) do
        if state.id ~= my then break end
        local dur = (ev.t == "r") and restDur() or noteDur()
        ideal = ideal + dur; local target = t0 + ideal; local w = target - os.clock()
        if w > 0 then task.wait(w) end
        state.progress = i / #events
        if ev.t == "n" then
            for _, ch in ipairs(ev.keys) do keyDown(keyMap[ch]) end
            task.wait(math.min(S.hold, dur * 0.8))
            for _, ch in ipairs(ev.keys) do keyUp(keyMap[ch]) end
        end
    end
    if state.id == my then state.playing = false; sendBtn.Text = "▶" end
end
function playCurrent()
    if state.playing or melodyBox.Text:match("^%s*$") then return end
    state.playing = true; state.id = state.id + 1; local my = state.id
    local events = buildEvents(melodyBox.Text, S.transpose)
    setIslandPlaying(true); titleLbl.Text = "Мелодия"; subLbl.Text = "Играет..."
    task.spawn(function() playEvents(events, my) end); sendBtn.Text = "■"
end
function stopPlay() state.playing = false; state.id = state.id + 1; releaseAll(); setIslandPlaying(false); sendBtn.Text = "▶" end
sendBtn.MouseButton1Click:Connect(function() if state.playing then stopPlay() else playCurrent() end end)
melodyBox.FocusLost:Connect(function(enter) if enter and not state.playing then playCurrent() end end)

view = "chat"
function showView(v) view = v; chatArea.Visible = (v == "chat"); libView.Visible = (v == "lib"); for key, b in pairs(sideBtns) do local on = (key == v); b.BackgroundTransparency = on and 0 or 1; b.TextColor3 = on and TXT or DIM end end
sideBtns.chat.Activated:Connect(function() showView("chat") end)
sideBtns.lib.Activated:Connect(function() showView("lib") end)
sideBtns.new.Activated:Connect(function() for _, r in ipairs(msgRows) do r:Destroy() end; msgRows = {}; melodyBox.Text = ""; showView("chat"); say("Новый чат.") end)
plusBtn.MouseButton1Click:Connect(function() plusMenu.Visible = not plusMenu.Visible end)
pasteBtn.MouseButton1Click:Connect(function() local txt = readClipboard(); if txt then melodyBox.Text = txt end end)
loopBtn.MouseButton1Click:Connect(function() S.loop = not S.loop; loopBtn.TextColor3 = S.loop and ACC() or DIM end)
accentBtn.MouseButton1Click:Connect(function() S.accent = S.accent % #ACCENTS + 1; queueSave(); for _, r in ipairs(accRefs) do if r[1]:IsDescendantOf(gui) then r[1][r[2]] = ACC() end end end)
doodleBtn.MouseButton1Click:Connect(function() S.doodles = not S.doodles; doodleFolder.Visible = S.doodles end)
minBtn.MouseButton1Click:Connect(toggleWindow); closeBtn.MouseButton1Click:Connect(toggleWindow)

for key, b in pairs(pills) do b.MouseButton1Click:Connect(function() S[key] = not S[key]; b.BackgroundColor3 = S[key] and BG2 or BG1; b.TextColor3 = S[key] and TXT or DIM end) end

local frames, accT, fps, ping = 0, 0, 0, 0
RunService.Heartbeat:Connect(function(dt)
    frames = frames + 1; accT = accT + dt
    if accT >= 0.5 then fps = math.floor(frames / accT + 0.5); frames, accT = 0, 0; pcall(function() ping = math.floor(player:GetNetworkPing() * 2000) end); if not islandPlaying then statsLabel.Text = string.format("FPS: %d | Ping: %d", fps, ping) end end
    if islandPlaying then for i, b in ipairs(eqBars) do b.Size = UDim2.fromOffset(5, math.random(4, 15)) end; progFill.Size = UDim2.fromScale(math.clamp(state.progress, 0, 1), 1) end
    if S.girl and main.Visible then local swing = math.sin(tick() * 3) * 10; legL.Rotation = swing; legR.Rotation = -swing; lidL.Visible = (tick() % 3) < 0.1; lidR.Visible = (tick() % 3) < 0.1 end
end)

switchTab("home"); scaleObj.Scale = baseScale(); say("Привет! Я " .. S.girlName .. ". Вставь мелодию, и я всё сыграю.")