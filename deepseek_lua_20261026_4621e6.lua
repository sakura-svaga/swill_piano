--============================================================
--  SWILL • Piano Ultra FINAL (TABS EDITION)
--  Вкладки • Слайдер • Адаптив • Локальное сохранение
--============================================================

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--================ НАСТРОЙКИ =================
local CONFIG = {
    pressDuration = 0.09,
    noteGap = 0.05,
    restDuration = 0.22,
    starKey = "shift8", -- "shift8" или "numpad"
    antiskript = false,
    antiskriptDelay = 0.07, -- 70 мс по умолчанию
}
local tempoMs = 50
local savedSongs = {}
local FILE_NAME = "SWILL_Piano_Songs.json"
--============================================

--=========== КАРТА КЛАВИШ ===========
local keyMap = {}
local letters = {"A","B","C","D","E","F","G","H","I","J","K","L","M",
                 "N","O","P","Q","R","S","T","U","V","W","X","Y","Z"}
for _, L in ipairs(letters) do
    keyMap[L:lower()] = { key = Enum.KeyCode[L], shift = false }
    keyMap[L]         = { key = Enum.KeyCode[L], shift = true  }
end
local digitNames = {"Zero","One","Two","Three","Four","Five","Six","Seven","Eight","Nine"}
for i = 0, 9 do
    keyMap[tostring(i)] = { key = Enum.KeyCode[digitNames[i+1]], shift = false }
end
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
if CONFIG.starKey == "numpad" then
    keyMap["*"] = { key = Enum.KeyCode.KeypadMultiply, shift = false }
else
    keyMap["*"] = { key = Enum.KeyCode.Eight, shift = true }
end
--=====================================

--=========== ОТПРАВКА КЛАВИШ ===========
local function sendKey(keyCode, isDown)
    VIM:SendKeyEvent(isDown, keyCode, false, game)
end
--=======================================

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
            while j <= n and not str:sub(j, j):match("%s") and str:sub(j, j) ~= "[" do
                j = j + 1
            end
            table.insert(tokens, { note = str:sub(i, j - 1) })
            i = j
        end
    end
    return tokens
end
--=======================================

--=========== ЛОКАЛЬНОЕ СОХРАНЕНИЕ ===========
local function saveSongs()
    local ok, err = pcall(function()
        if writefile then
            writefile(FILE_NAME, HttpService:JSONEncode(savedSongs))
        else
            error("executor не поддерживает writefile")
        end
    end)
    if ok then return true, "Сохранено на устройство ✔"
    else return false, "Ошибка: " .. tostring(err) end
end

local function loadSongs()
    local ok, data = pcall(function()
        if isfile and isfile(FILE_NAME) then return readfile(FILE_NAME) end
        return nil
    end)
    if ok and data then
        local success, decoded = pcall(function() return HttpService:JSONDecode(data) end)
        if success and type(decoded) == "table" then
            savedSongs = decoded
            return true, "Загружено: " .. #savedSongs .. " песен"
        end
    end
    return false, "Файл не найден, начинаем с пустого"
end
--=======================================

--=========== GUI (MOBILE TABS) ========================
local gui = Instance.new("ScreenGui")
gui.Name = "SWILL_Piano_Ultra"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.fromScale(0.5, 0.5)
main.Size = UDim2.new(0.96, 0, 0.94, 0)
main.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
main.BorderSizePixel = 0
main.Active = true
main.ClipsDescendants = true
main.ZIndex = 1
main.Parent = gui

local uic = Instance.new("UICorner"); uic.CornerRadius = UDim.new(0, 24); uic.Parent = main
local uis = Instance.new("UIStroke"); uis.Color = Color3.fromRGB(65, 65, 70); uis.Thickness = 1; uis.Parent = main
local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 32)), ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 12, 14))})
grad.Rotation = 90
grad.Parent = main

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 60)
header.BackgroundTransparency = 1
header.Parent = main

local minBtn = Instance.new("TextButton")
minBtn.AnchorPoint = Vector2.new(1, 0)
minBtn.Position = UDim2.new(1, -16, 0, 16)
minBtn.Size = UDim2.fromOffset(32, 32)
minBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 44)
minBtn.BorderSizePixel = 0
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.TextColor3 = Color3.fromRGB(200, 200, 205)
minBtn.Text = "—"
minBtn.AutoButtonColor = false
minBtn.Parent = header
local mbc = Instance.new("UICorner"); mbc.CornerRadius = UDim.new(1, 0); mbc.Parent = minBtn

local tabsFrame = Instance.new("Frame")
tabsFrame.Size = UDim2.new(1, -70, 0, 34)
tabsFrame.Position = UDim2.fromOffset(16, 14)
tabsFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
tabsFrame.BorderSizePixel = 0
tabsFrame.Parent = header
local tfc = Instance.new("UICorner"); tfc.CornerRadius = UDim.new(1, 0); tfc.Parent = tabsFrame
local tfl = Instance.new("UIListLayout")
tfl.FillDirection = Enum.FillDirection.Horizontal
tfl.Padding = UDim.new(0, 4)
tfl.VerticalAlignment = Enum.VerticalAlignment.Center
tfl.Parent = tabsFrame
local tfp = Instance.new("UIPadding"); tfp.PaddingLeft = UDim.new(0, 6); tfp.PaddingRight = UDim.new(0, 6); tfp.Parent = tabsFrame

local tabs = {}
local activeTab = nil
local function createTabButton(name, text, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 0, 0, 26)
    btn.AutomaticSize = Enum.AutomaticSize.X
    btn.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.TextColor3 = Color3.fromRGB(150, 150, 155)
    btn.Text = text
    btn.LayoutOrder = order
    btn.Parent = tabsFrame
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = btn
    local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0, 12); p.PaddingRight = UDim.new(0, 12); p.Parent = btn
    tabs[name] = btn
    return btn
end

local tabHome = createTabButton("home", "Главная", 1)
local tabCtrl = createTabButton("ctrl", "Управление", 2)
local tabInfo = createTabButton("info", "Описание", 3)

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -24, 1, -76)
content.Position = UDim2.fromOffset(12, 64)
content.BackgroundTransparency = 1
content.Parent = main

local pages = {}
local function switchTab(name)
    if activeTab then
        tabs[activeTab].TextColor3 = Color3.fromRGB(150, 150, 155)
        tabs[activeTab].BackgroundTransparency = 1
        pages[activeTab].Visible = false
    end
    activeTab = name
    tabs[name].TextColor3 = Color3.fromRGB(230, 230, 235)
    tabs[name].BackgroundTransparency = 0
    tabs[name].BackgroundColor3 = Color3.fromRGB(40, 40, 44)
    pages[name].Visible = true
end

--=========== СТРАНИЦА: ГЛАВНАЯ ===========
local pageHome = Instance.new("ScrollingFrame")
pageHome.Size = UDim2.new(1, 0, 1, 0)
pageHome.BackgroundTransparency = 1
pageHome.BorderSizePixel = 0
pageHome.ScrollBarThickness = 3
pageHome.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 85)
pageHome.CanvasSize = UDim2.new(0, 0, 0, 0)
pageHome.AutomaticCanvasSize = Enum.AutomaticSize.Y
pageHome.Parent = content
pages["home"] = pageHome

local homeLayout = Instance.new("UIListLayout")
homeLayout.Padding = UDim.new(0, 12)
homeLayout.Parent = pageHome

local girl = Instance.new("Frame")
girl.Size = UDim2.new(1, 0, 0, 90)
girl.BackgroundTransparency = 1
girl.LayoutOrder = 1
girl.Parent = pageHome

local hair = Instance.new("Frame")
hair.Size = UDim2.fromOffset(64, 64)
hair.Position = UDim2.new(0.5, -32, 0, 0)
hair.BackgroundColor3 = Color3.fromRGB(70, 45, 35)
hair.BorderSizePixel = 0
hair.ZIndex = 1
hair.Parent = girl
local hc = Instance.new("UICorner"); hc.CornerRadius = UDim.new(1, 0); hc.Parent = hair

local head = Instance.new("Frame")
head.Size = UDim2.fromOffset(46, 46)
head.Position = UDim2.new(0.5, -23, 0, 6)
head.BackgroundColor3 = Color3.fromRGB(255, 225, 205)
head.BorderSizePixel = 0
head.ZIndex = 2
head.Parent = girl
local hdc = Instance.new("UICorner"); hdc.CornerRadius = UDim.new(1, 0); hdc.Parent = head

local eye1 = Instance.new("Frame")
eye1.Size = UDim2.fromOffset(5, 7)
eye1.Position = UDim2.fromOffset(11, 18)
eye1.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
eye1.BorderSizePixel = 0
eye1.ZIndex = 3
eye1.Parent = head
local e1c = Instance.new("UICorner"); e1c.CornerRadius = UDim.new(1, 0); e1c.Parent = eye1
local eye2 = eye1:Clone(); eye2.Position = UDim2.fromOffset(29, 18); eye2.Parent = head

local mouth = Instance.new("Frame")
mouth.Size = UDim2.fromOffset(8, 3)
mouth.Position = UDim2.fromOffset(19, 32)
mouth.BackgroundColor3 = Color3.fromRGB(220, 100, 100)
mouth.BorderSizePixel = 0
mouth.ZIndex = 3
mouth.Parent = head
local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(1, 0); mc.Parent = mouth

local leg1 = Instance.new("Frame")
leg1.Size = UDim2.fromOffset(8, 34)
leg1.Position = UDim2.new(0.5, -12, 0, 50)
leg1.BackgroundColor3 = Color3.fromRGB(255, 225, 205)
leg1.BorderSizePixel = 0
leg1.ZIndex = 3
leg1.Parent = girl
local l1c = Instance.new("UICorner"); l1c.CornerRadius = UDim.new(0, 4); l1c.Parent = leg1
local leg2 = leg1:Clone(); leg2.Position = UDim2.new(0.5, 4, 0, 50); leg2.Parent = girl

local melodyBox = Instance.new("TextBox")
melodyBox.Size = UDim2.new(1, 0, 0, 120)
melodyBox.BackgroundColor3 = Color3.fromRGB(22, 22, 25)
melodyBox.BorderSizePixel = 0
melodyBox.Font = Enum.Font.Code
melodyBox.TextSize = 12
melodyBox.TextColor3 = Color3.fromRGB(220, 220, 225)
melodyBox.PlaceholderColor3 = Color3.fromRGB(90, 90, 95)
melodyBox.PlaceholderText = "Мелодия: [*T69ey] - [6u] - * 0 W ..."
melodyBox.TextXAlignment = Enum.TextXAlignment.Left
melodyBox.TextYAlignment = Enum.TextYAlignment.Top
melodyBox.ClearTextOnFocus = false
melodyBox.MultiLine = true
melodyBox.TextWrapped = true
melodyBox.Text = ""
melodyBox.LayoutOrder = 2
melodyBox.Parent = pageHome
local mbc2 = Instance.new("UICorner"); mbc2.CornerRadius = UDim.new(0, 12); mbc2.Parent = melodyBox
local mp = Instance.new("UIPadding"); mp.PaddingLeft = UDim.new(0, 10); mp.PaddingTop = UDim.new(0, 8); mp.Parent = melodyBox

local btnRow = Instance.new("Frame")
btnRow.Size = UDim2.new(1, 0, 0, 36)
btnRow.BackgroundTransparency = 1
btnRow.LayoutOrder = 3
btnRow.Parent = pageHome
local btnLayout = Instance.new("UIListLayout")
btnLayout.FillDirection = Enum.FillDirection.Horizontal
btnLayout.Padding = UDim.new(0, 8)
btnLayout.Parent = btnRow

local function makePill(parent, text, color, textColor, w)
    local b = Instance.new("TextButton")
    if w then b.Size = UDim2.fromOffset(w, 36) else b.Size = UDim2.new(0, 0, 0, 36); b.AutomaticSize = Enum.AutomaticSize.X end
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.TextColor3 = textColor
    b.Text = text
    b.AutoButtonColor = true
    b.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = b
    if not w then
        local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 14); pad.PaddingRight = UDim.new(0, 14); pad.Parent = b
    end
    return b
end

local playBtn = makePill(btnRow, "▶ Играть", Color3.fromRGB(201, 162, 39), Color3.fromRGB(0, 0, 0))
local stopBtn = makePill(btnRow, "■ Стоп", Color3.fromRGB(40, 40, 44), Color3.fromRGB(220, 220, 225))
local clearBtn = makePill(btnRow, "Очистить", Color3.fromRGB(40, 40, 44), Color3.fromRGB(220, 220, 225))

local nameBox = Instance.new("TextBox")
nameBox.Size = UDim2.new(1, 0, 0, 36)
nameBox.BackgroundColor3 = Color3.fromRGB(22, 22, 25)
nameBox.BorderSizePixel = 0
nameBox.Font = Enum.Font.Gotham
nameBox.TextSize = 13
nameBox.TextColor3 = Color3.fromRGB(220, 220, 225)
nameBox.PlaceholderText = "Название песни"
nameBox.PlaceholderColor3 = Color3.fromRGB(90, 90, 95)
nameBox.Text = ""
nameBox.LayoutOrder = 4
nameBox.Parent = pageHome
local nbc = Instance.new("UICorner"); nbc.CornerRadius = UDim.new(1, 0); nbc.Parent = nameBox
local np = Instance.new("UIPadding"); np.PaddingLeft = UDim.new(0, 14); np.Parent = nameBox

local saveBtn = makePill(pageHome, "Сохранить в список", Color3.fromRGB(201, 162, 39), Color3.fromRGB(0, 0, 0))
saveBtn.Size = UDim2.new(1, 0, 0, 34)
saveBtn.LayoutOrder = 5

local songList = Instance.new("ScrollingFrame")
songList.Size = UDim2.new(1, 0, 0, 140)
songList.BackgroundColor3 = Color3.fromRGB(22, 22, 25)
songList.BorderSizePixel = 0
songList.ScrollBarThickness = 3
songList.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 85)
songList.CanvasSize = UDim2.new(0, 0, 0, 0)
songList.AutomaticCanvasSize = Enum.AutomaticSize.Y
songList.LayoutOrder = 6
songList.Parent = pageHome
local slc = Instance.new("UICorner"); slc.CornerRadius = UDim.new(0, 12); slc.Parent = songList
local listPad = Instance.new("UIPadding"); listPad.PaddingAll = UDim.new(0, 6); listPad.Parent = songList
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent = songList

--=========== СТРАНИЦА: УПРАВЛЕНИЕ ===========
local pageCtrl = Instance.new("ScrollingFrame")
pageCtrl.Size = UDim2.new(1, 0, 1, 0)
pageCtrl.BackgroundTransparency = 1
pageCtrl.BorderSizePixel = 0
pageCtrl.ScrollBarThickness = 3
pageCtrl.CanvasSize = UDim2.new(0, 0, 0, 0)
pageCtrl.AutomaticCanvasSize = Enum.AutomaticSize.Y
pageCtrl.Visible = false
pageCtrl.Parent = content
pages["ctrl"] = pageCtrl

local ctrlLayout = Instance.new("UIListLayout")
ctrlLayout.Padding = UDim.new(0, 14)
ctrlLayout.Parent = pageCtrl

local tempoFrame = Instance.new("Frame")
tempoFrame.Size = UDim2.new(1, 0, 0, 36)
tempoFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 25)
tempoFrame.BorderSizePixel = 0
tempoFrame.LayoutOrder = 1
tempoFrame.Parent = pageCtrl
local tfc2 = Instance.new("UICorner"); tfc2.CornerRadius = UDim.new(1, 0); tfc2.Parent = tempoFrame

local leftArrow = Instance.new("TextButton")
leftArrow.Size = UDim2.fromOffset(36, 36)
leftArrow.Position = UDim2.fromOffset(0, 0)
leftArrow.BackgroundTransparency = 1
leftArrow.Font = Enum.Font.GothamBold
leftArrow.TextSize = 16
leftArrow.TextColor3 = Color3.fromRGB(200, 200, 205)
leftArrow.Text = "◀"
leftArrow.Parent = tempoFrame

local tempoLabel = Instance.new("TextLabel")
tempoLabel.Size = UDim2.new(1, -80, 1, 0)
tempoLabel.Position = UDim2.fromOffset(38, 0)
tempoLabel.BackgroundTransparency = 1
tempoLabel.Font = Enum.Font.GothamBold
tempoLabel.TextSize = 13
tempoLabel.TextColor3 = Color3.fromRGB(220, 220, 225)
tempoLabel.Text = "Темп: 50 мс"
tempoLabel.Parent = tempoFrame

local rightArrow = leftArrow:Clone()
rightArrow.Position = UDim2.new(1, -36, 0, 0)
rightArrow.Parent = tempoFrame

local antiBtn = makePill(pageCtrl, "Антискрипт: ВЫКЛ", Color3.fromRGB(40, 40, 44), Color3.fromRGB(220, 220, 225))
antiBtn.Size = UDim2.new(1, 0, 0, 36)
antiBtn.LayoutOrder = 2

local delayFrame = Instance.new("Frame")
delayFrame.Size = UDim2.new(1, 0, 0, 70)
delayFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 25)
delayFrame.BorderSizePixel = 0
delayFrame.LayoutOrder = 3
delayFrame.Parent = pageCtrl
local dfc = Instance.new("UICorner"); dfc.CornerRadius = UDim.new(0, 12); dfc.Parent = delayFrame
local dfp = Instance.new("UIPadding"); dfp.PaddingAll = UDim.new(0, 12); dfp.Parent = delayFrame

local delayTitle = Instance.new("TextLabel")
delayTitle.Size = UDim2.new(1, 0, 0, 20)
delayTitle.BackgroundTransparency = 1
delayTitle.Font = Enum.Font.GothamBold
delayTitle.TextSize = 13
delayTitle.TextXAlignment = Enum.TextXAlignment.Left
delayTitle.TextColor3 = Color3.fromRGB(220, 220, 225)
delayTitle.Text = "Задержка антискрипта: 70 мс"
delayTitle.Parent = delayFrame

local delaySlider = Instance.new("TextButton")
delaySlider.Size = UDim2.new(1, 0, 0, 6)
delaySlider.Position = UDim2.fromOffset(0, 36)
delaySlider.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
delaySlider.BorderSizePixel = 0
delaySlider.Text = ""
delaySlider.AutoButtonColor = false
delaySlider.Parent = delayFrame
local dsc = Instance.new("UICorner"); dsc.CornerRadius = UDim.new(1, 0); dsc.Parent = delaySlider

local delayFill = Instance.new("Frame")
delayFill.Size = UDim2.new(0.5, 0, 1, 0) -- 70 из 120 мс примерно 0.5
delayFill.BackgroundColor3 = Color3.fromRGB(201, 162, 39)
delayFill.BorderSizePixel = 0
delayFill.Parent = delaySlider
local dfc2 = Instance.new("UICorner"); dfc2.CornerRadius = UDim.new(1, 0); dfc2.Parent = delayFill

local delayKnob = Instance.new("Frame")
delayKnob.Size = UDim2.fromOffset(16, 16)
delayKnob.AnchorPoint = Vector2.new(0.5, 0.5)
delayKnob.Position = UDim2.new(0.5, 0, 0.5, 0)
delayKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
delayKnob.BorderSizePixel = 0
delayKnob.Parent = delaySlider
local dkc = Instance.new("UICorner"); dkc.CornerRadius = UDim.new(1, 0); dkc.Parent = delayKnob

local sliderDragging = false
local function updateDelaySlider(x)
    local relX = math.clamp((x - delaySlider.AbsolutePosition.X) / delaySlider.AbsoluteSize.X, 0, 1)
    local ms = math.floor(20 + relX * 100) -- От 20 до 120 мс
    CONFIG.antiskriptDelay = ms / 1000
    delayTitle.Text = "Задержка антискрипта: " .. ms .. " мс"
    delayFill.Size = UDim2.new(relX, 0, 1, 0)
    delayKnob.Position = UDim2.new(relX, 0, 0.5, 0)
end

delaySlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = true
        updateDelaySlider(input.Position.X)
    end
end)
UIS.InputChanged:Connect(function(input)
    if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateDelaySlider(input.Position.X)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = false
    end
end)

--=========== СТРАНИЦА: ОПИСАНИЕ ===========
local pageInfo = Instance.new("ScrollingFrame")
pageInfo.Size = UDim2.new(1, 0, 1, 0)
pageInfo.BackgroundTransparency = 1
pageInfo.BorderSizePixel = 0
pageInfo.ScrollBarThickness = 3
pageInfo.CanvasSize = UDim2.new(0, 0, 0, 0)
pageInfo.AutomaticCanvasSize = Enum.AutomaticSize.Y
pageInfo.Visible = false
pageInfo.Parent = content
pages["info"] = pageInfo

local infoPad = Instance.new("UIPadding"); infoPad.PaddingAll = UDim.new(0, 12); infoPad.Parent = pageInfo
local infoLayout = Instance.new("UIListLayout"); infoLayout.Padding = UDim.new(0, 10); infoLayout.Parent = pageInfo

local infoTitle = Instance.new("TextLabel")
infoTitle.Size = UDim2.new(1, 0, 0, 24)
infoTitle.BackgroundTransparency = 1
infoTitle.Font = Enum.Font.GothamBold
infoTitle.TextSize = 16
infoTitle.TextXAlignment = Enum.TextXAlignment.Left
infoTitle.TextColor3 = Color3.fromRGB(201, 162, 39)
infoTitle.Text = "📖 Как пользоваться"
infoTitle.Parent = pageInfo

local infoText = Instance.new("TextLabel")
infoText.Size = UDim2.new(1, 0, 0, 400)
infoText.BackgroundColor3 = Color3.fromRGB(22, 22, 25)
infoText.BorderSizePixel = 0
infoText.Font = Enum.Font.Gotham
infoText.TextSize = 13
infoText.TextColor3 = Color3.fromRGB(200, 200, 205)
infoText.TextXAlignment = Enum.TextXAlignment.Left
infoText.TextYAlignment = Enum.TextYAlignment.Top
infoText.TextWrapped = true
infoText.Text = [[1. Вставь мелодию на главной странице. 
Формат: одиночные ноты (буквы/цифры), аккорды в скобках [например], паузы символом "-".

2. Нажми "▶ Играть", зайди в игру, открой пианино и скрипт начнёт нажимать клавиши.

3. Темп и задержку антискрипта настраивай во вкладке "Управление".

4. Антискрипт добавляет задержку между нажатиями клавиш в аккорде (от 20 до 120 мс), чтобы сервер не спалил одновременное нажатие.

5. Сохраняй песни, чтобы не вставлять их каждый раз. Они хранятся на твоём устройстве.

Если скрипт не нажимает клавиши — проверь, что игра в фокусе и клавиатура активна.]]
infoText.Parent = pageInfo
local itc = Instance.new("UICorner"); itc.CornerRadius = UDim.new(0, 12); itc.Parent = infoText
local itp = Instance.new("UIPadding"); itp.PaddingAll = UDim.new(0, 12); itp.Parent = infoText

-- Островок
local pill = Instance.new("Frame")
pill.AnchorPoint = Vector2.new(0.5, 0)
pill.Position = UDim2.new(0.5, 0, 0, 10)
pill.Size = UDim2.fromOffset(140, 34)
pill.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
pill.BorderSizePixel = 0
pill.Visible = false
pill.ZIndex = 20
pill.Parent = gui
local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(1, 0); pc.Parent = pill
local pstroke = Instance.new("UIStroke"); pstroke.Color = Color3.fromRGB(60, 60, 65); pstroke.Thickness = 1; pstroke.Parent = pill
local pillText = Instance.new("TextLabel")
pillText.Size = UDim2.new(1, -10, 1, 0)
pillText.Position = UDim2.fromOffset(5, 0)
pillText.BackgroundTransparency = 1
pillText.Font = Enum.Font.GothamBold
pillText.TextSize = 12
pillText.TextColor3 = Color3.fromRGB(220, 220, 225)
pillText.Text = "FPS: 0 | Ping: 0"
pillText.Parent = pill

switchTab("home")
--=======================================
--=========== ЛОГИКА ====================
--=======================================
local isPlaying = false
local function stopPlaying() isPlaying = false end

local function playChord(keysStr)
    local entries, needShift = {}, false
    for i = 1, #keysStr do
        local info = keyMap[keysStr:sub(i,i)]
        if info then
            table.insert(entries, info)
            if info.shift then needShift = true end
        end
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
    local tokens = parseSong(text)
    for idx, tok in ipairs(tokens) do
        if not isPlaying then break end
        if tok.chord then playChord(tok.chord)
        elseif tok.note == "-" then task.wait(CONFIG.restDuration)
        else playChord(tok.note) end
    end
    isPlaying = false
end

local function updateTempoLabel()
    tempoLabel.Text = "Темп: " .. tempoMs .. " мс"
    CONFIG.noteGap = tempoMs / 1000
end
updateTempoLabel()

playBtn.MouseButton1Click:Connect(function()
    if isPlaying then return end
    melodyBox:ReleaseFocus()
    task.spawn(function() playSong(melodyBox.Text) end)
end)
stopBtn.MouseButton1Click:Connect(function() stopPlaying() end)
clearBtn.MouseButton1Click:Connect(function() melodyBox.Text = "" end)

antiBtn.MouseButton1Click:Connect(function()
    CONFIG.antiskript = not CONFIG.antiskript
    if CONFIG.antiskript then
        antiBtn.BackgroundColor3 = Color3.fromRGB(201, 162, 39)
        antiBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        antiBtn.Text = "Антискрипт: ВКЛ"
    else
        antiBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 44)
        antiBtn.TextColor3 = Color3.fromRGB(220, 220, 225)
        antiBtn.Text = "Антискрипт: ВЫКЛ"
    end
end)

local function changeTempo(delta)
    tempoMs = math.clamp(tempoMs + delta, 10, 500)
    updateTempoLabel()
end

local function startHold(btn, delta)
    local active = false
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            active = true
            changeTempo(delta)
            task.spawn(function()
                while active do
                    task.wait(0.1)
                    if active then changeTempo(delta) end
                end
            end)
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            active = false
        end
    end)
end
startHold(leftArrow, -5)
startHold(rightArrow, 5)

local function refreshSongList()
    for _, child in ipairs(songList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for i, song in ipairs(savedSongs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,-8,0,32)
        btn.BackgroundColor3 = Color3.fromRGB(20,20,22)
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
        btn.TextColor3 = Color3.fromRGB(220,220,225)
        btn.Text = "  " .. song.name
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = songList
        local bc2 = Instance.new("UICorner"); bc2.CornerRadius = UDim.new(0,6); bc2.Parent = btn

        local del = Instance.new("TextButton")
        del.Size = UDim2.fromOffset(28,28)
        del.Position = UDim2.new(1,-32,0,2)
        del.BackgroundColor3 = Color3.fromRGB(60,20,20)
        del.BorderSizePixel = 0
        del.Font = Enum.Font.GothamBold
        del.TextSize = 14
        del.TextColor3 = Color3.fromRGB(255,150,150)
        del.Text = "×"
        del.Parent = btn
        local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(0,6); dc.Parent = del

        btn.MouseButton1Click:Connect(function()
            melodyBox.Text = song.text
            if song.tempo then tempoMs = song.tempo; updateTempoLabel() end
            switchTab("home")
        end)

        del.MouseButton1Click:Connect(function()
            table.remove(savedSongs, i)
            saveSongs()
            refreshSongList()
        end)
    end
    songList.CanvasSize = UDim2.new(0,0,0, #savedSongs * 36 + 4)
end

saveBtn.MouseButton1Click:Connect(function()
    local name = nameBox.Text
    if name == "" then name = "Без названия " .. (#savedSongs + 1) end
    table.insert(savedSongs, {name = name, text = melodyBox.Text, tempo = tempoMs})
    saveSongs()
    refreshSongList()
    nameBox.Text = ""
end)

-- Вкладки
tabHome.MouseButton1Click:Connect(function() switchTab("home") end)
tabCtrl.MouseButton1Click:Connect(function() switchTab("ctrl") end)
tabInfo.MouseButton1Click:Connect(function() switchTab("info") end)

-- Сворачивание
minBtn.MouseButton1Click:Connect(function()
    main.Visible = false
    pill.Visible = true
end)
pill.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        main.Visible = true
        pill.Visible = false
    end
end)

-- FPS / Ping
local fps = 0
local frameCount = 0
local lastTime = tick()
RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = tick()
    if now - lastTime >= 1 then
        fps = frameCount
        frameCount = 0
        lastTime = now
    end
end)

local function getPing()
    local ok, ping = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    if ok then return math.floor(ping) else return 0 end
end

task.spawn(function()
    while true do
        task.wait(0.5)
        if pill.Visible then
            pillText.Text = string.format("FPS: %d | Ping: %d", fps, getPing())
        end
    end
end)

-- Анимация тяночки
local t = 0
RunService.Heartbeat:Connect(function(dt)
    t = t + dt
    local swing = math.sin(t * 3) * 4
    leg1.Position = UDim2.new(0.5, -12, 0, 50 + swing)
    leg2.Position = UDim2.new(0.5, 4, 0, 50 - swing)
    local eyeShift = math.sin(t * 2) * 1.5
    eye1.Position = UDim2.fromOffset(11 + eyeShift, 18)
    eye2.Position = UDim2.fromOffset(29 + eyeShift, 18)
end)

-- Инициализация
loadSongs()
refreshSongList()