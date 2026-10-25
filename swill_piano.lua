--============================================================
--  SWILL • Piano Ultra (Anime Girl UI FINAL FIX)
--============================================================

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--================ НАСТРОЙКИ =================
local CONFIG = {
    pressDuration = 0.09,
    noteGap = 0.05,
    restDuration = 0.22,
    starKey = "shift8",
    antiskript = false,
    antiskriptDelay = 0.07,
}
local tempoMs = 50
local savedSongs = {}
local FILE_NAME = "SWILL_Piano_Songs.json"

--=========== КАРТА КЛАВИШ ===========
local keyMap = {}
local letters = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"}
for _, L in ipairs(letters) do
    keyMap[L:lower()] = { key = Enum.KeyCode[L], shift = false }
    keyMap[L]         = { key = Enum.KeyCode[L], shift = true  }
end
local digitNames = {"Zero","One","Two","Three","Four","Five","Six","Seven","Eight","Nine"}
for i = 0, 9 do keyMap[tostring(i)] = { key = Enum.KeyCode[digitNames[i+1]], shift = false } end
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
if CONFIG.starKey == "numpad" then keyMap["*"] = { key = Enum.KeyCode.KeypadMultiply, shift = false }
else keyMap["*"] = { key = Enum.KeyCode.Eight, shift = true } end

local function sendKey(keyCode, isDown) VIM:SendKeyEvent(isDown, keyCode, false, game) end

--=========== ПАРСЕР ====================
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

--=========== СОХРАНЕНИЕ ===========
local function saveSongs()
    pcall(function() if writefile then writefile(FILE_NAME, HttpService:JSONEncode(savedSongs)) end end)
end
local function loadSongs()
    local ok, data = pcall(function() if isfile and isfile(FILE_NAME) then return readfile(FILE_NAME) end end)
    if ok and data then
        local success, decoded = pcall(function() return HttpService:JSONDecode(data) end)
        if success and type(decoded) == "table" then savedSongs = decoded end
    end
end

--=========== GUI ========================
local gui = Instance.new("ScreenGui")
gui.Name = "SWILL_Piano_Ultra"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999
gui.Parent = playerGui

-- Главное окно (СРАЗУ ВИДИМОЕ)
local main = Instance.new("Frame")
main.Size = UDim2.fromScale(0.9, 0.7)
main.Position = UDim2.fromScale(0.5, 0.5)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
main.BorderSizePixel = 0
main.ClipsDescendants = false
main.Visible = true -- СРАЗУ ОТКРЫТО
main.ZIndex = 1
main.Parent = gui
local m_corner = Instance.new("UICorner"); m_corner.CornerRadius = UDim.new(0, 20); m_corner.Parent = main
local m_stroke = Instance.new("UIStroke"); m_stroke.Color = Color3.fromRGB(60, 60, 65); m_stroke.Thickness = 1; m_stroke.Parent = main

-- Шапка окна (для перетаскивания)
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundTransparency = 1
header.Active = true
header.ZIndex = 2
header.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 150, 0, 30)
title.Position = UDim2.fromOffset(15, 10)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(230, 230, 235)
title.Text = "SWILL • Piano"
title.ZIndex = 3
title.Parent = header

-- Кнопка свернуть
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.fromOffset(30, 30)
minBtn.Position = UDim2.new(1, -40, 0, 10)
minBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 38)
minBtn.BorderSizePixel = 0
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 14
minBtn.TextColor3 = Color3.fromRGB(200, 200, 205)
minBtn.Text = "—"
minBtn.ZIndex = 3
minBtn.Parent = header
local mb_corner = Instance.new("UICorner"); mb_corner.CornerRadius = UDim.new(1, 0); mb_corner.Parent = minBtn

-- Перетаскивание окна
local dragging, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = main.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ==========================================
-- ========== АНИМЕ ТЯНОЧКА (DETAILED) ======
-- ==========================================
local girl = Instance.new("Frame")
girl.Size = UDim2.fromOffset(120, 140)
girl.Position = UDim2.new(0.5, -60, 0, -100)
girl.BackgroundTransparency = 1
girl.ZIndex = 50
girl.Parent = main

-- Задние волосы
local hairBack = Instance.new("Frame")
hairBack.Size = UDim2.fromOffset(80, 90)
hairBack.Position = UDim2.new(0.5, -40, 0, 10)
hairBack.BackgroundColor3 = Color3.fromRGB(240, 200, 220)
hairBack.BorderSizePixel = 0
hairBack.ZIndex = 1
hairBack.Parent = girl
local hbc = Instance.new("UICorner"); hbc.CornerRadius = UDim.new(1, 0); hbc.Parent = hairBack

-- Хвостики
local twintailL = Instance.new("Frame")
twintailL.Size = UDim2.fromOffset(25, 60)
twintailL.Position = UDim2.fromOffset(5, 20)
twintailL.BackgroundColor3 = Color3.fromRGB(240, 200, 220)
twintailL.BorderSizePixel = 0
twintailL.Rotation = 15
twintailL.ZIndex = 2
twintailL.Parent = girl
local tlc = Instance.new("UICorner"); tlc.CornerRadius = UDim.new(1, 0); tlc.Parent = twintailL

local twintailR = twintailL:Clone()
twintailR.Position = UDim2.fromOffset(90, 20)
twintailR.Rotation = -15
twintailR.Parent = girl

-- Лицо
local head = Instance.new("Frame")
head.Size = UDim2.fromOffset(60, 60)
head.Position = UDim2.new(0.5, -30, 0, 15)
head.BackgroundColor3 = Color3.fromRGB(255, 235, 225)
head.BorderSizePixel = 0
head.ZIndex = 3
head.Parent = girl
local hdc = Instance.new("UICorner"); hdc.CornerRadius = UDim.new(1, 0); hdc.Parent = head

-- Челка
local bangs = Instance.new("Frame")
bangs.Size = UDim2.fromOffset(62, 25)
bangs.Position = UDim2.new(0, -1, 0, -2)
bangs.BackgroundColor3 = Color3.fromRGB(240, 200, 220)
bangs.BorderSizePixel = 0
bangs.ZIndex = 4
bangs.Parent = head
local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 10); bc.Parent = bangs

-- Глаза
local eyeL = Instance.new("Frame")
eyeL.Size = UDim2.fromOffset(12, 16)
eyeL.Position = UDim2.fromOffset(12, 25)
eyeL.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
eyeL.BorderSizePixel = 0
eyeL.ZIndex = 5
eyeL.Parent = head
local elc = Instance.new("UICorner"); elc.CornerRadius = UDim.new(1, 0); elc.Parent = eyeL

local eyeR = eyeL:Clone(); eyeR.Position = UDim2.fromOffset(36, 25); eyeR.Parent = head

-- Зрачки
local pupilL = Instance.new("Frame")
pupilL.Size = UDim2.fromOffset(6, 8)
pupilL.Position = UDim2.fromOffset(3, 4)
pupilL.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
pupilL.BorderSizePixel = 0
pupilL.ZIndex = 6
pupilL.Parent = eyeL
local plc = Instance.new("UICorner"); plc.CornerRadius = UDim.new(1, 0); plc.Parent = pupilL
local pupilR = pupilL:Clone(); pupilR.Parent = eyeR

-- Блики
local shineL = Instance.new("Frame")
shineL.Size = UDim2.fromOffset(3, 3)
shineL.Position = UDim2.fromOffset(1, 1)
shineL.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
shineL.BorderSizePixel = 0
shineL.ZIndex = 7
shineL.Parent = pupilL
local slc = Instance.new("UICorner"); slc.CornerRadius = UDim.new(1, 0); slc.Parent = shineL
local shineR = shineL:Clone(); shineR.Parent = pupilR

-- Румянец
local blushL = Instance.new("Frame")
blushL.Size = UDim2.fromOffset(10, 5)
blushL.Position = UDim2.fromOffset(8, 45)
blushL.BackgroundColor3 = Color3.fromRGB(255, 150, 150)
blushL.BackgroundTransparency = 0.3
blushL.BorderSizePixel = 0
blushL.ZIndex = 5
blushL.Parent = head
local blc = Instance.new("UICorner"); blc.CornerRadius = UDim.new(1, 0); blc.Parent = blushL

local blushR = blushL:Clone(); blushR.Position = UDim2.fromOffset(42, 45); blushR.Parent = head

-- Рот
local mouth = Instance.new("Frame")
mouth.Size = UDim2.fromOffset(6, 3)
mouth.Position = UDim2.fromOffset(27, 48)
mouth.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
mouth.BorderSizePixel = 0
mouth.ZIndex = 5
mouth.Parent = head
local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(1, 0); mc.Parent = mouth

-- Бантик
local bow = Instance.new("Frame")
bow.Size = UDim2.fromOffset(20, 15)
bow.Position = UDim2.new(0.5, -10, 0, -2)
bow.BackgroundColor3 = Color3.fromRGB(255, 80, 100)
bow.BorderSizePixel = 0
bow.ZIndex = 6
bow.Parent = head
local bowc = Instance.new("UICorner"); bowc.CornerRadius = UDim.new(0, 4); bowc.Parent = bow

-- Тело
local body = Instance.new("Frame")
body.Size = UDim2.fromOffset(46, 35)
body.Position = UDim2.new(0.5, -23, 0, 65)
body.BackgroundColor3 = Color3.fromRGB(80, 100, 150)
body.BorderSizePixel = 0
body.ZIndex = 2
body.Parent = girl
local bodyc = Instance.new("UICorner"); bodyc.CornerRadius = UDim.new(0, 8); bodyc.Parent = body

-- Руки
local armL = Instance.new("Frame")
armL.Size = UDim2.fromOffset(10, 25)
armL.Position = UDim2.fromOffset(25, 70)
armL.BackgroundColor3 = Color3.fromRGB(255, 235, 225)
armL.BorderSizePixel = 0
armL.Rotation = -15
armL.ZIndex = 3
armL.Parent = girl
local alc = Instance.new("UICorner"); alc.CornerRadius = UDim.new(1, 0); alc.Parent = armL

local armR = armL:Clone(); armR.Position = UDim2.fromOffset(85, 70); armR.Rotation = 15; armR.Parent = girl

-- Ножки
local legL = Instance.new("Frame")
legL.Size = UDim2.fromOffset(8, 40)
legL.Position = UDim2.fromOffset(40, 95)
legL.BackgroundColor3 = Color3.fromRGB(255, 235, 225)
legL.BorderSizePixel = 0
legL.ZIndex = 4
legL.Parent = girl
local llc = Instance.new("UICorner"); llc.CornerRadius = UDim.new(1, 0); llc.Parent = legL

local legR = legL:Clone(); legR.Position = UDim2.fromOffset(72, 95); legR.Parent = girl

-- Анимации (ножки, моргание, покачивание)
local t = 0
RunService.Heartbeat:Connect(function(dt)
    t = t + dt
    local swing = math.sin(t * 3) * 8
    legL.Position = UDim2.fromOffset(40, 95 + swing)
    legR.Position = UDim2.fromOffset(72, 95 - swing)
    
    local eyeSwing = math.sin(t * 1.5) * 1
    pupilL.Position = UDim2.fromOffset(3 + eyeSwing, 4)
    pupilR.Position = UDim2.fromOffset(3 + eyeSwing, 4)

    local blink = math.sin(t * 0.5)
    if blink > 0.95 then
        eyeL.Size = UDim2.fromOffset(12, 2); eyeR.Size = UDim2.fromOffset(12, 2)
    else
        eyeL.Size = UDim2.fromOffset(12, 16); eyeR.Size = UDim2.fromOffset(12, 16)
    end
end)

-- ==========================================
-- ========== ОСТРОВОК (ISLAND) =============
-- ==========================================
local island = Instance.new("TextButton")
island.Size = UDim2.fromOffset(160, 34)
island.Position = UDim2.new(0.5, -80, 0, 10)
island.BackgroundColor3 = Color3.fromRGB(15, 15, 17)
island.BorderSizePixel = 0
island.Text = "FPS: 0 | Ping: 0"
island.Font = Enum.Font.GothamBold
island.TextSize = 12
island.TextColor3 = Color3.fromRGB(200, 200, 205)
island.AutoButtonColor = false
island.Visible = false -- СКРЫТ ИЗНАЧАЛЬНО
island.ZIndex = 20
island.Parent = gui
local i_corner = Instance.new("UICorner"); i_corner.CornerRadius = UDim.new(1, 0); i_corner.Parent = island
local i_stroke = Instance.new("UIStroke"); i_stroke.Color = Color3.fromRGB(50, 50, 55); i_stroke.Thickness = 1; i_stroke.Parent = island

-- Табы (Навигация)
local tabsFrame = Instance.new("Frame")
tabsFrame.Size = UDim2.new(1, -20, 0, 34)
tabsFrame.Position = UDim2.fromOffset(10, 50)
tabsFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
tabsFrame.BorderSizePixel = 0
tabsFrame.ZIndex = 2
tabsFrame.Parent = main
local tf_corner = Instance.new("UICorner"); tf_corner.CornerRadius = UDim.new(1, 0); tf_corner.Parent = tabsFrame
local tf_layout = Instance.new("UIListLayout")
tf_layout.FillDirection = Enum.FillDirection.Horizontal
tf_layout.Padding = UDim.new(0, 5)
tf_layout.VerticalAlignment = Enum.VerticalAlignment.Center
tf_layout.Parent = tabsFrame
local tf_pad = Instance.new("UIPadding"); tf_pad.PaddingLeft = UDim.new(0, 5); tf_pad.Parent = tabsFrame

local tabs, activeTab = {}, nil
local function createTab(name, text, order)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(0, 26); b.AutomaticSize = Enum.AutomaticSize.X
    b.BackgroundTransparency = 1; b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold; b.TextSize = 12; b.TextColor3 = Color3.fromRGB(150, 150, 155)
    b.Text = text; b.LayoutOrder = order; b.ZIndex = 3; b.Parent = tabsFrame
    local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0, 12); p.PaddingRight = UDim.new(0, 12); p.Parent = b
    tabs[name] = b
    return b
end
createTab("home", "Главная", 1)
createTab("ctrl", "Настройки", 2)
createTab("info", "Гайд", 3)

-- Контент
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -20, 1, -100)
content.Position = UDim2.fromOffset(10, 90)
content.BackgroundTransparency = 1
content.ZIndex = 2
content.Parent = main

local pages = {}
local function switchTab(name)
    if activeTab then tabs[activeTab].TextColor3 = Color3.fromRGB(150, 150, 155); tabs[activeTab].BackgroundTransparency = 1; pages[activeTab].Visible = false end
    activeTab = name
    tabs[name].TextColor3 = Color3.fromRGB(0, 0, 0); tabs[name].BackgroundTransparency = 0; tabs[name].BackgroundColor3 = Color3.fromRGB(201, 162, 39); pages[name].Visible = true
end

-- Страница 1: Главная
local pageHome = Instance.new("ScrollingFrame")
pageHome.Size = UDim2.new(1, 0, 1, 0); pageHome.BackgroundTransparency = 1; pageHome.ScrollBarThickness = 2; pageHome.AutomaticCanvasSize = Enum.AutomaticSize.Y; pageHome.CanvasSize = UDim2.new(0,0,0,0); pageHome.ZIndex = 2; pageHome.Parent = content
pages["home"] = pageHome
local hl = Instance.new("UIListLayout"); hl.Padding = UDim.new(0, 10); hl.Parent = pageHome

local inputBg = Instance.new("Frame")
inputBg.Size = UDim2.new(1, 0, 0, 44); inputBg.BackgroundColor3 = Color3.fromRGB(28, 28, 32); inputBg.BorderSizePixel = 0; inputBg.LayoutOrder = 1; inputBg.ZIndex = 3; inputBg.Parent = pageHome
local ibc = Instance.new("UICorner"); ibc.CornerRadius = UDim.new(1, 0); ibc.Parent = inputBg

local melodyBox = Instance.new("TextBox")
melodyBox.Size = UDim2.new(1, -30, 1, 0); melodyBox.Position = UDim2.fromOffset(15, 0); melodyBox.BackgroundTransparency = 1; melodyBox.Font = Enum.Font.Gotham; melodyBox.TextSize = 13; melodyBox.TextColor3 = Color3.fromRGB(220, 220, 225); melodyBox.PlaceholderText = "Мелодия: [*T69ey] - [6u] - * 0 W ..."; melodyBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 125); melodyBox.TextXAlignment = Enum.TextXAlignment.Left; melodyBox.ClearTextOnFocus = false; melodyBox.Text = ""; melodyBox.ZIndex = 4; melodyBox.Parent = inputBg

local btnRow = Instance.new("Frame")
btnRow.Size = UDim2.new(1, 0, 0, 40); btnRow.BackgroundTransparency = 1; btnRow.LayoutOrder = 2; btnRow.ZIndex = 3; btnRow.Parent = pageHome
local bl = Instance.new("UIListLayout"); bl.FillDirection = Enum.FillDirection.Horizontal; bl.Padding = UDim.new(0, 8); bl.Parent = btnRow

local function makeBtn(text, color, tColor, w)
    local b = Instance.new("TextButton")
    b.Size = w and UDim2.fromOffset(w, 40) or UDim2.new(0,0,0,40)
    if not w then b.AutomaticSize = Enum.AutomaticSize.X end
    b.BackgroundColor3 = color; b.BorderSizePixel = 0; b.Font = Enum.Font.GothamBold; b.TextSize = 13; b.TextColor3 = tColor; b.Text = text; b.ZIndex = 4; b.Parent = btnRow
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = b
    if not w then local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0,14); p.PaddingRight = UDim.new(0,14); p.Parent = b end
    return b
end

local playBtn = makeBtn("▶ Играть", Color3.fromRGB(201, 162, 39), Color3.fromRGB(0, 0, 0))
local stopBtn = makeBtn("■ Стоп", Color3.fromRGB(40, 40, 44), Color3.fromRGB(220, 220, 225))
local clearBtn = makeBtn("Очистить", Color3.fromRGB(40, 40, 44), Color3.fromRGB(220, 220, 225))

local nameBox = Instance.new("TextBox")
nameBox.Size = UDim2.new(1, 0, 0, 40); nameBox.BackgroundColor3 = Color3.fromRGB(28, 28, 32); nameBox.BorderSizePixel = 0; nameBox.Font = Enum.Font.Gotham; nameBox.TextSize = 13; nameBox.TextColor3 = Color3.fromRGB(220, 220, 225); nameBox.PlaceholderText = "Название трека..."; nameBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 125); nameBox.Text = ""; nameBox.LayoutOrder = 3; nameBox.ZIndex = 3; nameBox.Parent = pageHome
local nbc = Instance.new("UICorner"); nbc.CornerRadius = UDim.new(1, 0); nbc.Parent = nameBox
local np = Instance.new("UIPadding"); np.PaddingLeft = UDim.new(0, 15); np.Parent = nameBox

local saveBtn = makeBtn("Сохранить в список", Color3.fromRGB(201, 162, 39), Color3.fromRGB(0, 0, 0))
saveBtn.Size = UDim2.new(1, 0, 0, 40); saveBtn.LayoutOrder = 4; saveBtn.ZIndex = 3; saveBtn.Parent = pageHome

local songList = Instance.new("ScrollingFrame")
songList.Size = UDim2.new(1, 0, 0, 150); songList.BackgroundColor3 = Color3.fromRGB(28, 28, 32); songList.BorderSizePixel = 0; songList.ScrollBarThickness = 2; songList.AutomaticCanvasSize = Enum.AutomaticSize.Y; songList.CanvasSize = UDim2.new(0,0,0,0); songList.LayoutOrder = 5; songList.ZIndex = 3; songList.Parent = pageHome
local slc = Instance.new("UICorner"); slc.CornerRadius = UDim.new(0, 12); slc.Parent = songList
local slp = Instance.new("UIPadding"); slp.PaddingAll = UDim.new(0, 6); slp.Parent = songList
local sll = Instance.new("UIListLayout"); sll.Padding = UDim.new(0, 4); sll.Parent = songList

-- Страница 2: Настройки
local pageCtrl = Instance.new("ScrollingFrame")
pageCtrl.Size = UDim2.new(1, 0, 1, 0); pageCtrl.BackgroundTransparency = 1; pageCtrl.ScrollBarThickness = 2; pageCtrl.AutomaticCanvasSize = Enum.AutomaticSize.Y; pageCtrl.CanvasSize = UDim2.new(0,0,0,0); pageCtrl.Visible = false; pageCtrl.ZIndex = 2; pageCtrl.Parent = content
pages["ctrl"] = pageCtrl
local cl = Instance.new("UIListLayout"); cl.Padding = UDim.new(0, 12); cl.Parent = pageCtrl

local tempoFrame = Instance.new("Frame")
tempoFrame.Size = UDim2.new(1, 0, 0, 40); tempoFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 32); tempoFrame.BorderSizePixel = 0; tempoFrame.LayoutOrder = 1; tempoFrame.ZIndex = 3; tempoFrame.Parent = pageCtrl
local tfc = Instance.new("UICorner"); tfc.CornerRadius = UDim.new(1, 0); tfc.Parent = tempoFrame

local tLeft = Instance.new("TextButton"); tLeft.Size = UDim2.fromOffset(40, 40); tLeft.BackgroundTransparency = 1; tLeft.Text = "◀"; tLeft.Font = Enum.Font.GothamBold; tLeft.TextColor3 = Color3.fromRGB(200,200,205); tLeft.TextSize = 16; tLeft.ZIndex = 4; tLeft.Parent = tempoFrame
local tLabel = Instance.new("TextLabel"); tLabel.Size = UDim2.new(1,-80,1,0); tLabel.Position = UDim2.fromOffset(40,0); tLabel.BackgroundTransparency = 1; tLabel.Text = "Темп: 50 мс"; tLabel.Font = Enum.Font.GothamBold; tLabel.TextSize = 13; tLabel.TextColor3 = Color3.fromRGB(220,220,225); tLabel.ZIndex = 4; tLabel.Parent = tempoFrame
local tRight = tLeft:Clone(); tRight.Position = UDim2.new(1,-40,0,0); tRight.Parent = tempoFrame

local antiBtn = makeBtn("Антискрипт: ВЫКЛ", Color3.fromRGB(40, 40, 44), Color3.fromRGB(220, 220, 225))
antiBtn.Size = UDim2.new(1, 0, 0, 40); antiBtn.LayoutOrder = 2; antiBtn.ZIndex = 3; antiBtn.Parent = pageCtrl

local delayFrame = Instance.new("Frame")
delayFrame.Size = UDim2.new(1, 0, 0, 70); delayFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 32); delayFrame.BorderSizePixel = 0; delayFrame.LayoutOrder = 3; delayFrame.ZIndex = 3; delayFrame.Parent = pageCtrl
local dfc = Instance.new("UICorner"); dfc.CornerRadius = UDim.new(0, 12); dfc.Parent = delayFrame
local dfp = Instance.new("UIPadding"); dfp.PaddingAll = UDim.new(0, 12); dfp.Parent = delayFrame

local dTitle = Instance.new("TextLabel"); dTitle.Size = UDim2.new(1,0,0,20); dTitle.BackgroundTransparency = 1; dTitle.Font = Enum.Font.GothamBold; dTitle.TextSize = 13; dTitle.TextColor3 = Color3.fromRGB(220,220,225); dTitle.TextXAlignment = Enum.TextXAlignment.Left; dTitle.Text = "Задержка: 70 мс"; dTitle.ZIndex = 4; dTitle.Parent = delayFrame

local dSlider = Instance.new("TextButton"); dSlider.Size = UDim2.new(1,0,0,6); dSlider.Position = UDim2.fromOffset(0,36); dSlider.BackgroundColor3 = Color3.fromRGB(50,50,55); dSlider.Text = ""; dSlider.AutoButtonColor = false; dSlider.ZIndex = 4; dSlider.Parent = delayFrame
local dsc = Instance.new("UICorner"); dsc.CornerRadius = UDim.new(1,0); dsc.Parent = dSlider

local dFill = Instance.new("Frame"); dFill.Size = UDim2.new(0.5,0,1,0); dFill.BackgroundColor3 = Color3.fromRGB(201,162,39); dFill.BorderSizePixel = 0; dFill.ZIndex = 5; dFill.Parent = dSlider
local dfc2 = Instance.new("UICorner"); dfc2.CornerRadius = UDim.new(1,0); dfc2.Parent = dFill

local dKnob = Instance.new("Frame"); dKnob.Size = UDim2.fromOffset(16,16); dKnob.AnchorPoint = Vector2.new(0.5,0.5); dKnob.Position = UDim2.new(0.5,0,0.5,0); dKnob.BackgroundColor3 = Color3.fromRGB(255,255,255); dKnob.ZIndex = 6; dKnob.Parent = dSlider
local dkc = Instance.new("UICorner"); dkc.CornerRadius = UDim.new(1,0); dkc.Parent = dKnob

local sliderDrag = false
local function updateSlider(x)
    local rel = math.clamp((x - dSlider.AbsolutePosition.X) / dSlider.AbsoluteSize.X, 0, 1)
    local ms = math.floor(20 + rel * 100)
    CONFIG.antiskriptDelay = ms / 1000
    dTitle.Text = "Задержка: " .. ms .. " мс"
    dFill.Size = UDim2.new(rel, 0, 1, 0)
    dKnob.Position = UDim2.new(rel, 0, 0.5, 0)
end
dSlider.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sliderDrag = true; updateSlider(input.Position.X) end end)
UIS.InputChanged:Connect(function(input) if sliderDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then updateSlider(input.Position.X) end end)
UIS.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sliderDrag = false end end)

-- Страница 3: Гайд
local pageInfo = Instance.new("ScrollingFrame")
pageInfo.Size = UDim2.new(1, 0, 1, 0); pageInfo.BackgroundTransparency = 1; pageInfo.ScrollBarThickness = 2; pageInfo.AutomaticCanvasSize = Enum.AutomaticSize.Y; pageInfo.CanvasSize = UDim2.new(0,0,0,0); pageInfo.Visible = false; pageInfo.ZIndex = 2; pageInfo.Parent = content
pages["info"] = pageInfo
local ip = Instance.new("UIPadding"); ip.PaddingAll = UDim.new(0, 10); ip.Parent = pageInfo
local infoText = Instance.new("TextLabel")
infoText.Size = UDim2.new(1,0,0,300); infoText.BackgroundColor3 = Color3.fromRGB(28,28,32); infoText.Font = Enum.Font.Gotham; infoText.TextSize = 13; infoText.TextColor3 = Color3.fromRGB(200,200,205); infoText.TextWrapped = true; infoText.TextXAlignment = Enum.TextXAlignment.Left; infoText.TextYAlignment = Enum.TextYAlignment.Top; infoText.Text = [[Как пользоваться:
1. Вставляй мелодию в поле. Формат: буквы/цифры, аккорды в [скобках], паузы "-".
2. Жми "Играть".
3. Темп и задержку антискрипта крути во вкладке "Настройки".
4. Сохраняй треки.
5. Окно можно тянуть за верхнюю часть. Кнопка "—" сворачивает в островок.]]; infoText.ZIndex = 3; infoText.Parent = pageInfo
local itc = Instance.new("UICorner"); itc.CornerRadius = UDim.new(0,12); itc.Parent = infoText
local itp = Instance.new("UIPadding"); itp.PaddingAll = UDim.new(0,12); itp.Parent = infoText

switchTab("home")

--=========== ЛОГИКА ====================
local isPlaying = false
local function stopPlaying() isPlaying = false end

local function playChord(keysStr)
    local entries, needShift = {}, false
    for i = 1, #keysStr do
        local info = keyMap[keysStr:sub(i,i)]
        if info then table.insert(entries, info); if info.shift then needShift = true end end
    end
    if #entries == 0 then return end
    local pressDur = math.min(CONFIG.pressDuration, CONFIG.noteGap * 0.8)
    
    if CONFIG.antiskript then
        local delay = CONFIG.antiskriptDelay
        if needShift then sendKey(Enum.KeyCode.LeftShift, true); task.wait(delay) end
        for _, e in ipairs(entries) do sendKey(e.key, true); task.wait(delay) end
        task.wait(pressDur)
        for _, e in ipairs(entries) do sendKey(e.key, false); task.wait(delay) end
        if needShift then sendKey(Enum.KeyCode.LeftShift, false); task.wait(delay) end
        task.wait(CONFIG.noteGap)
    else
        if needShift then sendKey(Enum.KeyCode.LeftShift, true) end
        for _, e in ipairs(entries) do sendKey(e.key, true) end
        task.wait(pressDur)
        for _, e in ipairs(entries) do sendKey(e.key, false) end
        if needShift then sendKey(Enum.KeyCode.LeftShift, false) end
        task.wait(CONFIG.noteGap)
    end
end

local function playSong(text)
    if isPlaying then return end
    isPlaying = true
    for _, tok in ipairs(parseSong(text)) do
        if not isPlaying then break end
        if tok.chord then playChord(tok.chord) elseif tok.note == "-" then task.wait(CONFIG.restDuration) else playChord(tok.note) end
    end
    isPlaying = false
end

playBtn.MouseButton1Click:Connect(function() melodyBox:ReleaseFocus(); task.spawn(function() playSong(melodyBox.Text) end) end)
stopBtn.MouseButton1Click:Connect(stopPlaying)
clearBtn.MouseButton1Click:Connect(function() melodyBox.Text = "" end)

antiBtn.MouseButton1Click:Connect(function()
    CONFIG.antiskript = not CONFIG.antiskript
    antiBtn.Text = CONFIG.antiskript and "Антискрипт: ВКЛ" or "Антискрипт: ВЫКЛ"
    antiBtn.BackgroundColor3 = CONFIG.antiskript and Color3.fromRGB(201,162,39) or Color3.fromRGB(40,40,44)
    antiBtn.TextColor3 = CONFIG.antiskript and Color3.fromRGB(0,0,0) or Color3.fromRGB(220,220,225)
end)

local function changeTempo(d)
    tempoMs = math.clamp(tempoMs + d, 10, 500)
    tLabel.Text = "Темп: " .. tempoMs .. " мс"
    CONFIG.noteGap = tempoMs / 1000
end

local function startHold(btn, d)
    local active = false
    btn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then active = true; changeTempo(d); task.spawn(function() while active do task.wait(0.1); if active then changeTempo(d) end end end) end end)
    btn.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then active = false end end)
end
startHold(tLeft, -5)
startHold(tRight, 5)

local function refreshSongList()
    for _, c in ipairs(songList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    for i, s in ipairs(savedSongs) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1,-8,0,32); b.BackgroundColor3 = Color3.fromRGB(20,20,22); b.BorderSizePixel = 0; b.Font = Enum.Font.Gotham; b.TextSize = 13; b.TextColor3 = Color3.fromRGB(220,220,225); b.Text = "  " .. s.name; b.TextXAlignment = Enum.TextXAlignment.Left; b.ZIndex = 4; b.Parent = songList
        local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,6); bc.Parent = b
        local del = Instance.new("TextButton"); del.Size = UDim2.fromOffset(28,28); del.Position = UDim2.new(1,-32,0,2); del.BackgroundColor3 = Color3.fromRGB(60,20,20); del.BorderSizePixel = 0; del.Font = Enum.Font.GothamBold; del.TextSize = 14; del.TextColor3 = Color3.fromRGB(255,150,150); del.Text = "×"; del.ZIndex = 5; del.Parent = b
        local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(0,6); dc.Parent = del
        b.MouseButton1Click:Connect(function() melodyBox.Text = s.text; if s.tempo then tempoMs = s.tempo; changeTempo(0) end; switchTab("home") end)
        del.MouseButton1Click:Connect(function() table.remove(savedSongs, i); saveSongs(); refreshSongList() end)
    end
    songList.CanvasSize = UDim2.new(0,0,0, #savedSongs * 36 + 4)
end

saveBtn.MouseButton1Click:Connect(function()
    local n = nameBox.Text; if n == "" then n = "Трек " .. (#savedSongs + 1) end
    table.insert(savedSongs, {name = n, text = melodyBox.Text, tempo = tempoMs})
    saveSongs(); refreshSongList(); nameBox.Text = ""
end)

tabHome = tabs["home"]; tabCtrl = tabs["ctrl"]; tabInfo = tabs["info"]
tabHome.MouseButton1Click:Connect(function() switchTab("home") end)
tabCtrl.MouseButton1Click:Connect(function() switchTab("ctrl") end)
tabInfo.MouseButton1Click:Connect(function() switchTab("info") end)

-- Сворачивание с анимацией
local function openUI()
    main.Visible = true
    main.Size = UDim2.fromScale(0.1, 0.1) -- Начинаем с маленького
    island.Visible = false
    TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.9, 0.7)}):Play()
end

local function closeUI()
    TweenService:Create(main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.fromScale(0.1, 0.1)}):Play()
    task.delay(0.2, function()
        main.Visible = false
        island.Visible = true
    end)
end

minBtn.MouseButton1Click:Connect(closeUI)
island.MouseButton1Click:Connect(openUI)

-- FPS и Ping (исправлено, теперь всегда обновляется)
local fps = 0; local fc = 0; local lt = tick()
RunService.RenderStepped:Connect(function()
    fc = fc + 1
    local n = tick()
    if n - lt >= 1 then fps = fc; fc = 0; lt = n end
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        local p = 0
        pcall(function() p = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        island.Text = string.format("FPS: %d | Ping: %d", fps, p)
    end
end)

loadSongs()
refreshSongList()
