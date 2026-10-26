local UI = {}
_G.SWILL_UI = UI
local Core = _G.SWILL_Core
if not Core then return warn("Ядро не загружено!") end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local camera = workspace.CurrentCamera
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

UI.S = {
    speed = 1, tempo = 50, hold = 0.09, rest = 0.22, gap = 0.05,
    transpose = 0, countdown = 0, loop = false, shuffle = false,
    anti = false, antiMin = 8, antiMax = 35, antiCap = 90,
    antiTiming = 18, antiHold = 15, antiOrder = true, antiSmart = true,
    particles = true, girl = true, doodles = true, autohide = false,
    hotkeys = true, islandStats = true, antiAfk = true,
    uiScale = 1, accent = 1, girlName = "Саша",
}
UI.savedSongs = Core.loadSongs()
UI.conns = {}

UI.BG0, UI.BG1, UI.BG2 = Color3.fromRGB(15, 15, 17), Color3.fromRGB(28, 28, 32), Color3.fromRGB(42, 42, 47)
UI.BUB, UI.TXT, UI.DIM, UI.LINE = Color3.fromRGB(38, 38, 43), Color3.fromRGB(228, 228, 233), Color3.fromRGB(136, 136, 146), Color3.fromRGB(56, 56, 62)
UI.ACCENTS = { { name = "Золото", c = Color3.fromRGB(201, 162, 39) }, { name = "Роза", c = Color3.fromRGB(255, 138, 178) }, { name = "Небо", c = Color3.fromRGB(96, 160, 255) }, { name = "Мята", c = Color3.fromRGB(110, 222, 170) } }

function UI.ACC() return UI.ACCENTS[UI.S.accent].c end

UI.accRefs = {}
function UI.acc(obj, prop) UI.accRefs[#UI.accRefs + 1] = { obj, prop }; obj[prop] = UI.ACC(); return obj end
function UI.new(class, props, parent) local o = Instance.new(class); for k, v in pairs(props) do o[k] = v end; if parent then o.Parent = parent end; return o end
function UI.corner(o, r) return UI.new("UICorner", { CornerRadius = typeof(r) == "UDim" and r or UDim.new(0, r) }, o) end
function UI.stroke(o, c, th) return UI.new("UIStroke", { Color = c or UI.LINE, Thickness = th or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o) end
function UI.tween(o, t, props, style, dir) local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props); tw:Play(); return tw end

local function guiParent() local ok, h = pcall(function() return gethui and gethui() end); return (ok and h) or playerGui end
for _, p in ipairs({ guiParent(), playerGui }) do local old = p:FindFirstChild("SWILL_Piano_Ultra"); if old then old:Destroy() end end
UI.gui = UI.new("ScreenGui", { Name = "SWILL_Piano_Ultra", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999 }, guiParent())

-- Остров
UI.island = UI.new("TextButton", { Size = UDim2.fromOffset(190, 34), Position = UDim2.new(0.5, -95, 0, 10), BackgroundColor3 = UI.BG0, Text = "", AutoButtonColor = false, Active = true, ZIndex = 999, ClipsDescendants = true }, UI.gui)
UI.corner(UI.island, UDim.new(1, 0)); UI.stroke(UI.island, UI.LINE, 1)
UI.statsLabel = UI.new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = UI.TXT, Text = "" }, UI.island)

UI.pg = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false }, UI.island)
UI.cover = UI.new("Frame", { Position = UDim2.fromOffset(10, 9), Size = UDim2.fromOffset(32, 32) }, UI.pg); UI.acc(UI.cover, "BackgroundColor3"); UI.corner(UI.cover, 9)
UI.new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 17, TextColor3 = Color3.fromRGB(20, 20, 22), Text = "♪" }, UI.cover)
UI.titleClip = UI.new("Frame", { Position = UDim2.fromOffset(52, 7), Size = UDim2.fromOffset(186, 18), BackgroundTransparency = 1, ClipsDescendants = true }, UI.pg)
UI.titleLbl = UI.new("TextLabel", { Size = UDim2.fromOffset(0, 18), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = UI.TXT, TextXAlignment = Enum.TextXAlignment.Left, Text = "" }, UI.titleClip)
UI.subLbl = UI.new("TextLabel", { Position = UDim2.fromOffset(52, 25), Size = UDim2.fromOffset(186, 14), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = UI.DIM, TextXAlignment = Enum.TextXAlignment.Left, Text = "" }, UI.pg)
UI.eqBars = {}
for i = 1, 4 do local b = UI.new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromOffset(264 + (i - 1) * 8, 36), Size = UDim2.fromOffset(5, 6) }, UI.pg); UI.acc(b, "BackgroundColor3"); UI.corner(b, 2); UI.eqBars[i] = b end
UI.progTrack = UI.new("Frame", { Position = UDim2.fromOffset(52, 43), Size = UDim2.fromOffset(244, 3), BackgroundColor3 = UI.BG2 }, UI.pg); UI.corner(UI.progTrack, UDim.new(1, 0))
UI.progFill = UI.new("Frame", { Size = UDim2.fromScale(0, 1) }, UI.progTrack); UI.acc(UI.progFill, "BackgroundColor3"); UI.corner(UI.progFill, UDim.new(1, 0))

UI.islandPlaying = false
function UI.setIslandPlaying(on)
    if on == UI.islandPlaying then return end; UI.islandPlaying = on
    if on then UI.statsLabel.Visible = false; UI.pg.Visible = true; UI.tween(UI.island, 0.38, { Size = UDim2.fromOffset(310, 50), Position = UDim2.new(0.5, -155, 0, 8) }, Enum.EasingStyle.Back)
    else UI.pg.Visible = false; UI.statsLabel.Visible = true; UI.tween(UI.island, 0.25, { Size = UDim2.fromOffset(190, 34), Position = UDim2.new(0.5, -95, 0, 10) }) end
end

-- Главное окно
UI.main = UI.new("Frame", { Size = UDim2.fromOffset(720, 480), Position = UDim2.fromScale(0.5, 0.56), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), Visible = false, ZIndex = 2 }, UI.gui)
UI.corner(UI.main, 20); UI.stroke(UI.main, UI.LINE, 1); UI.new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(24, 24, 27), Color3.fromRGB(11, 11, 13)), Rotation = 90 }, UI.main)
UI.scaleObj = UI.new("UIScale", { Scale = 1 }, UI.main)
function UI.baseScale() return math.clamp(math.min(camera.ViewportSize.X / 780, camera.ViewportSize.Y / 640), 0.45, 1) * UI.S.uiScale end
UI.busy = false
function UI.toggleWindow()
    if UI.busy then return end; UI.busy = true
    if UI.main.Visible then UI.tween(UI.scaleObj, 0.18, { Scale = UI.baseScale() * 0.85 }).Completed:Wait(); UI.main.Visible = false
    else UI.scaleObj.Scale = UI.baseScale() * 0.85; UI.main.Visible = true; UI.tween(UI.scaleObj, 0.32, { Scale = UI.baseScale() }, Enum.EasingStyle.Back).Completed:Wait() end
    UI.busy = false
end
UI.island.Activated:Connect(UI.toggleWindow)

-- Тяночка
local PX = 4
local gp = { O = Color3.fromRGB(78, 64, 82), H = Color3.fromRGB(248, 236, 218), h = Color3.fromRGB(222, 200, 184), g = Color3.fromRGB(196, 170, 160), S = Color3.fromRGB(255, 232, 220), s = Color3.fromRGB(240, 205, 195), E = Color3.fromRGB(92, 150, 255), e = Color3.fromRGB(170, 212, 255), D = Color3.fromRGB(40, 44, 90), W = Color3.fromRGB(252, 252, 255), w = Color3.fromRGB(206, 212, 230), K = Color3.fromRGB(58, 60, 84), k = Color3.fromRGB(84, 88, 118), B = Color3.fromRGB(96, 160, 255), P = Color3.fromRGB(255, 160, 160), M = Color3.fromRGB(214, 110, 120) }
local rep = string.rep
UI.girlRows = { "OO", "OHHO", rep("O", 8), "OO"..rep("H", 8).."OO", "O".."HH".."BB"..rep("H", 8).."O", "O"..rep("H", 14).."O", "O".."HHH".."h"..rep("H", 6).."h".."HHH".."O", "O"..rep("H", 5).."SS".."HH".."SS"..rep("H", 5).."O", "O"..rep("H", 4)..rep("S", 8)..rep("H", 4).."O", "O"..rep("H", 3)..rep("S", 10)..rep("H", 3).."O", "O"..rep("H", 3)..rep("S", 10)..rep("H", 3).."O", "O".."HHH".."SDDDSSDDDS".."HHH".."O", "O".."HHH".."SeDESSeDES".."HHH".."O", "O".."HHH".."SEEESSEEES".."HHH".."O", "O".."HHH".."PPSSSSSSPP".."HHH".."O", "O".."hHH".."SSSSMMSSSS".."HHh".."O", "O".."hHHH".."sSSSSSSs".."HHHh".."O", "OhHH"..".".."sSSSSs"..".".."HHhO", "OhH".."...".."sSSs".."...".."HhO", "ghH"..rep(".", 4).."sSSs"..rep(".", 4).."Hhg", "wWWWBBWWWw", "SwWWWBBWWWwS", "S".."w"..rep("W", 8).."w".."S", "sSWWKKKKWWSs", "k"..rep("K", 10).."k", "k"..rep("K", 12).."k", "k"..rep("K", 14).."k", "WwWwWwWwWwWwWwWw" }
UI.ROWS, UI.COLS = #UI.girlRows, 22
UI.girlBaseY = -UI.ROWS * PX + 2
UI.girl = UI.new("Frame", { Size = UDim2.fromOffset(UI.COLS * PX, UI.ROWS * PX), Position = UDim2.new(0, 720 - 235, 0, UI.girlBaseY), BackgroundTransparency = 1, ZIndex = 20 }, UI.main)
local function makeLeg(col)
    local c = UI.new("Frame", { Size = UDim2.fromOffset(3 * PX, 14 * PX), Position = UDim2.fromOffset(col * PX, UI.ROWS * PX - 7 * PX - 2), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1 }, UI.girl)
    UI.new("Frame", { Position = UDim2.fromOffset(0, 7 * PX), Size = UDim2.fromOffset(3 * PX, 5 * PX), BackgroundColor3 = gp.S, BorderSizePixel = 0 }, c)
    UI.new("Frame", { Position = UDim2.fromOffset(0, 12 * PX), Size = UDim2.fromOffset(3 * PX + 2, 2 * PX), BackgroundColor3 = gp.k, BorderSizePixel = 0 }, c)
    return c
end
UI.legL, UI.legR = makeLeg(7), makeLeg(12)
local sprite = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2 }, UI.girl)
for y, row in ipairs(UI.girlRows) do
    local pad = math.floor((UI.COLS - #row) / 2)
    local x = 1
    while x <= #row do
        local ch = row:sub(x, x)
        if ch ~= "." then
            local e = x
            while e < #row and row:sub(e + 1, e + 1) == ch do e = e + 1 end
            UI.new("Frame", { Position = UDim2.fromOffset((pad + x - 1) * PX, (y - 1) * PX), Size = UDim2.fromOffset((e - x + 1) * PX, PX), BackgroundColor3 = gp[ch], BorderSizePixel = 0 }, sprite)
            x = e + 1
        else x = x + 1 end
    end
end

-- Шапка и вкладки
local header = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Active = true, ZIndex = 5 }, UI.main)
local minBtn = UI.new("TextButton", { Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -114, 0, 12), BackgroundColor3 = UI.BG1, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = UI.DIM, Text = "–" }, header); UI.corner(minBtn, UDim.new(1, 0))
local closeBtn = UI.new("TextButton", { Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -42, 0, 12), BackgroundColor3 = UI.BG1, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = UI.DIM, Text = "✕" }, header); UI.corner(closeBtn, UDim.new(1, 0))
UI.dragging, UI.dragStart, UI.startPos = false, nil, nil
UI.conns[#UI.conns + 1] = header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        UI.dragging, UI.dragStart, UI.startPos = true, input.Position, UI.main.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then UI.dragging = false end end)
    end
end)
UI.conns[#UI.conns + 1] = UIS.InputChanged:Connect(function(input)
    if UI.dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = (input.Position - UI.dragStart) / UI.scaleObj.Scale
        UI.main.Position = UDim2.new(UI.startPos.X.Scale, UI.startPos.X.Offset + d.X, UI.startPos.Y.Scale, UI.startPos.Y.Offset + d.Y)
    end
end)
minBtn.Activated:Connect(UI.toggleWindow); closeBtn.Activated:Connect(UI.toggleWindow)

UI.tabsFrame = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, -10, 0, 46), Size = UDim2.fromOffset(0, 38), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Color3.fromRGB(22, 22, 25), ZIndex = 5 }, UI.main)
UI.corner(UI.tabsFrame, UDim.new(1, 0)); UI.stroke(UI.tabsFrame, UI.LINE, 1)
UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 3), VerticalAlignment = Enum.VerticalAlignment.Center }, UI.tabsFrame)
UI.new("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) }, UI.tabsFrame)
UI.content = UI.new("Frame", { Position = UDim2.fromOffset(16, 96), Size = UDim2.new(1, -32, 1, -110), BackgroundTransparency = 1, ZIndex = 5 }, UI.main)
UI.tabs, UI.pages, UI.activeTab = {}, {}, nil

function UI.switchTab(name)
    if UI.activeTab then UI.tabs[UI.activeTab].TextColor3 = UI.DIM; UI.tabs[UI.activeTab].BackgroundTransparency = 1; UI.pages[UI.activeTab].Visible = false end
    UI.activeTab = name; UI.tabs[name].TextColor3 = UI.TXT; UI.tabs[name].BackgroundTransparency = 0; UI.pages[name].Visible = true
end
function UI.createTab(name, text)
    local b = UI.new("TextButton", { Size = UDim2.fromOffset(0, 30), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = UI.BG2, BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = UI.DIM, Text = text }, UI.tabsFrame)
    UI.corner(b, UDim.new(1, 0)); UI.new("UIPadding", { PaddingLeft = UDim.new(0, 13), PaddingRight = UDim.new(0, 13) }, b)
    b.Activated:Connect(function() UI.switchTab(name) end); UI.tabs[name] = b
end
function UI.makePage(name)
    local p = UI.new("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = false }, UI.content)
    UI.new("UIListLayout", { Padding = UDim.new(0, 10) }, p); UI.pages[name] = p; return p
end
UI.createTab("home", "⌂ Главная"); UI.createTab("play", "♪ Игра"); UI.createTab("anti", "◈ Антискрипт"); UI.createTab("set", "⚙ Настройки")
UI.pageHome, UI.pagePlay, UI.pageAnti, UI.pageSet = UI.makePage("home"), UI.makePage("play"), UI.makePage("anti"), UI.makePage("set")
