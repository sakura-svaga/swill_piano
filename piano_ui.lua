--============================================================
-- SWILL Piano UI
--============================================================
local Core = _G.SWILL_Core
if not Core then return warn("Ядро не загружено!") end

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

local BG0 = Color3.fromRGB(15, 15, 17)
local BG1 = Color3.fromRGB(28, 28, 32)
local BG2 = Color3.fromRGB(42, 42, 47)
local BUB = Color3.fromRGB(38, 38, 43)
local TXT = Color3.fromRGB(228, 228, 233)
local DIM = Color3.fromRGB(136, 136, 146)
local LINE = Color3.fromRGB(56, 56, 62)
local ACCENTS = {
    { name = "Золото", c = Color3.fromRGB(201, 162, 39) },
    { name = "Роза",   c = Color3.fromRGB(255, 138, 178) },
    { name = "Небо",   c = Color3.fromRGB(96, 160, 255) },
    { name = "Мята",   c = Color3.fromRGB(110, 222, 170) },
}
local function ACC() return ACCENTS[S.accent].c end

local gui, accRefs = nil, {}
local function acc(obj, prop) accRefs[#accRefs + 1] = { obj, prop }; obj[prop] = ACC(); return obj end
local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end
local function corner(o, r) return new("UICorner", { CornerRadius = typeof(r) == "UDim" and r or UDim.new(0, r) }, o) end
local function stroke(o, c, th) return new("UIStroke", { Color = c or LINE, Thickness = th or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o) end
local function tween(o, t, props, style, dir) local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props); tw:Play(); return tw end
local function fmtTime(sec) sec = math.max(0, math.floor(sec + 0.5)); return string.format("%d:%02d", math.floor(sec / 60), sec % 60) end
local function noteDur() return (S.hold + S.gap + S.tempo / 1000) / S.speed end
local function restDur() return (S.rest + S.gap + S.tempo / 1000) / S.speed end

local function guiParent() local ok, h = pcall(function() return gethui and gethui() end); return (ok and h) or playerGui end
for _, p in ipairs({ guiParent(), playerGui }) do local old = p:FindFirstChild("SWILL_Piano_Ultra"); if old then old:Destroy() end end
gui = new("ScreenGui", { Name = "SWILL_Piano_Ultra", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999 }, guiParent())

local island = new("TextButton", { Size = UDim2.fromOffset(190, 34), Position = UDim2.new(0.5, -95, 0, 10), BackgroundColor3 = BG0, BorderSizePixel = 0, Text = "", AutoButtonColor = false, Active = true, ZIndex = 999, ClipsDescendants = true }, gui)
corner(island, UDim.new(1, 0)); stroke(island, LINE, 1)

local statsLabel = new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = TXT, Text = "" }, island)

local pg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false }, island)
local cover = new("Frame", { Position = UDim2.fromOffset(10, 9), Size = UDim2.fromOffset(32, 32), BorderSizePixel = 0 }, pg); acc(cover, "BackgroundColor3"); corner(cover, 9)
new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 17, TextColor3 = Color3.fromRGB(20, 20, 22), Text = "♪" }, cover)
local titleClip = new("Frame", { Position = UDim2.fromOffset(52, 7), Size = UDim2.fromOffset(186, 18), BackgroundTransparency = 1, ClipsDescendants = true }, pg)
local titleLbl = new("TextLabel", { Size = UDim2.fromOffset(0, 18), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = TXT, TextXAlignment = Enum.TextXAlignment.Left, Text = "" }, titleClip)
local subLbl = new("TextLabel", { Position = UDim2.fromOffset(52, 25), Size = UDim2.fromOffset(186, 14), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Left, Text = "" }, pg)
local eqBars = {}
for i = 1, 4 do local b = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromOffset(264 + (i - 1) * 8, 36), Size = UDim2.fromOffset(5, 6), BorderSizePixel = 0 }, pg); acc(b, "BackgroundColor3"); corner(b, 2); eqBars[i] = b end
local progTrack = new("Frame", { Position = UDim2.fromOffset(52, 43), Size = UDim2.fromOffset(244, 3), BackgroundColor3 = BG2, BorderSizePixel = 0 }, pg); corner(progTrack, UDim.new(1, 0))
local progFill = new("Frame", { Size = UDim2.fromScale(0, 1), BorderSizePixel = 0 }, progTrack); acc(progFill, "BackgroundColor3"); corner(progFill, UDim.new(1, 0))

local islandPlaying = false
local function setIslandPlaying(on)
    if on == islandPlaying then return end; islandPlaying = on
    if on then statsLabel.Visible = false; pg.Visible = true; tween(island, 0.38, { Size = UDim2.fromOffset(310, 50), Position = UDim2.new(0.5, -155, 0, 8) }, Enum.EasingStyle.Back)
    else pg.Visible = false; statsLabel.Visible = true; tween(island, 0.25, { Size = UDim2.fromOffset(190, 34), Position = UDim2.new(0.5, -95, 0, 10) }) end
end

local WIN_W, WIN_H = 720, 480
local main = new("Frame", { Size = UDim2.fromOffset(WIN_W, WIN_H), Position = UDim2.fromScale(0.5, 0.56), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ClipsDescendants = false, Visible = false, ZIndex = 2 }, gui)
corner(main, 20); stroke(main, LINE, 1); new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(24, 24, 27), Color3.fromRGB(11, 11, 13)), Rotation = 90 }, main)
local scaleObj = new("UIScale", { Scale = 1 }, main)

local function baseScale() local v = camera.ViewportSize; return math.clamp(math.min(v.X / 780, v.Y / 640), 0.45, 1) * S.uiScale end
local busy = false
local function toggleWindow()
    if busy then return end; busy = true
    if main.Visible then tween(scaleObj, 0.18, { Scale = baseScale() * 0.85 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In).Completed:Wait(); main.Visible = false
    else scaleObj.Scale = baseScale() * 0.85; main.Visible = true; tween(scaleObj, 0.32, { Scale = baseScale() }, Enum.EasingStyle.Back, Enum.EasingDirection.Out).Completed:Wait() end
    busy = false
end
island.Activated:Connect(toggleWindow)
-- Далее стандартный код интерфейса, но вместо своих функций используем Core.*
-- (Вставь остатки кода из предыдущего файла вплоть до конца, но используй Core.parseSong и т.д.)
