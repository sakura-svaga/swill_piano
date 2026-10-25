--============================================================
--  SWILL • Piano Ultra FINAL (Roblox / mobile)
--  Тяночка • Островок • Темп • Антискрипт • Локальное сохранение
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
    antiskriptDelay = 0.07,
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
    if ok then
        return true, "Сохранено на устройство ✔"
    else
        return false, "Ошибка: " .. tostring(err)
    end
end

local function loadSongs()
    local ok, data = pcall(function()
        if isfile and isfile(FILE_NAME) then
            return readfile(FILE_NAME)
        end
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

--=========== GUI ========================
local gui = Instance.new("ScreenGui")
gui.Name = "SWILL_Piano_Ultra"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(320, 570)
main.Position = UDim2.new(0.5, -160, 0.5, -285)
main.BackgroundColor3 = Color3.fromRGB(18,18,18)
main.BorderSizePixel = 0
main.Active = true
main.ClipsDescendants = false
main.ZIndex = 1
main.Parent = gui

local uic = Instance.new("UICorner"); uic.CornerRadius = UDim.new(0,20); uic.Parent = main
local uis = Instance.new("UIStroke"); uis.Color = Color3.fromRGB(201,162,39); uis.Thickness = 1.5; uis.Parent = main
local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(30,30,30)), ColorSequenceKeypoint.new(1, Color3.fromRGB(10,10,10))})
grad.Rotation = 90
grad.Parent = main

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.fromOffset(30,30)
minBtn.Position = UDim2.new(1,-38,0,6)
minBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
minBtn.BorderSizePixel = 0
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.TextColor3 = Color3.fromRGB(200,200,200)
minBtn.Text = "—"
minBtn.Parent = main
local mbc = Instance.new("UICorner"); mbc.CornerRadius = UDim.new(0,8); mbc.Parent = minBtn

-- Тяночка
local girl = Instance.new("Frame")
girl.Size = UDim2.fromOffset(150, 130)
girl.Position = UDim2.new(0.5, -75, 0, -110)
girl.BackgroundTransparency = 1
girl.ZIndex = 10
girl.Parent = main

local hair = Instance.new("Frame")
hair.Size = UDim2.fromOffset(80,80)
hair.Position = UDim2.new(0.5,-40,0,10)
hair.BackgroundColor3 = Color3.fromRGB(60,40,30)
hair.BorderSizePixel = 0
hair.ZIndex = 1
hair.Parent = girl
local hc = Instance.new("UICorner"); hc.CornerRadius = UDim.new(1,0); hc.Parent = hair

local head = Instance.new("Frame")
head.Size = UDim2.fromOffset(60,60)
head.Position = UDim2.new(0.5,-30,0,20)
head.BackgroundColor3 = Color3.fromRGB(255,220,200)
head.BorderSizePixel = 0
head.ZIndex = 2
head.Parent = girl
local hdc = Instance.new("UICorner"); hdc.CornerRadius = UDim.new(1,0); hdc.Parent = head

local eye1 = Instance.new("Frame")
eye1.Size = UDim2.fromOffset(6,8)
eye1.Position = UDim2.fromOffset(15,22)
eye1.BackgroundColor3 = Color3.fromRGB(20,20,20)
eye1.BorderSizePixel = 0
eye1.ZIndex = 3
eye1.Parent = head
local e1c = Instance.new("UICorner"); e1c.CornerRadius = UDim.new(1,0); e1c.Parent = eye1
local eye2 = eye1:Clone(); eye2.Position = UDim2.fromOffset(39,22); eye2.Parent = head

local blush1 = Instance.new("Frame")
blush1.Size = UDim2.fromOffset(10,6)
blush1.Position = UDim2.fromOffset(8,38)
blush1.BackgroundColor3 = Color3.fromRGB(255,150,170)
blush1.BackgroundTransparency = 0.4
blush1.BorderSizePixel = 0
blush1.ZIndex = 3
blush1.Parent = head
local b1c = Instance.new("UICorner"); b1c.CornerRadius = UDim.new(1,0); b1c.Parent = blush1
local blush2 = blush1:Clone(); blush2.Position = UDim2.fromOffset(42,38); blush2.Parent = head

local mouth = Instance.new("Frame")
mouth.Size = UDim2.fromOffset(10,4)
mouth.Position = UDim2.fromOffset(25,44)
mouth.BackgroundColor3 = Color3.fromRGB(200,80,80)
mouth.BorderSizePixel = 0
mouth.ZIndex = 3
mouth.Parent = head
local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(1,0); mc.Parent = mouth

local body = Instance.new("Frame")
body.Size = UDim2.fromOffset(50,45)
body.Position = UDim2.new(0.5,-25,0,70)
body.BackgroundColor3 = Color3.fromRGB(255,150,200)
body.BorderSizePixel = 0
body.ZIndex = 2
body.Parent = girl
local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,10); bc.Parent = body

local arm1 = Instance.new("Frame")
arm1.Size = UDim2.fromOffset(8,30)
arm1.Position = UDim2.fromOffset(47,75)
arm1.BackgroundColor3 = Color3.fromRGB(255,220,200)
arm1.BorderSizePixel = 0
arm1.ZIndex = 2
arm1.Parent = girl
local a1c = Instance.new("UICorner"); a1c.CornerRadius = UDim.new(0,4); a1c.Parent = arm1
local arm2 = arm1:Clone(); arm2.Position = UDim2.fromOffset(95,75); arm2.Parent = girl

local leg1 = Instance.new("Frame")
leg1.Size = UDim2.fromOffset(10,50)
leg1.Position = UDim2.fromOffset(60,110)
leg1.BackgroundColor3 = Color3.fromRGB(255,220,200)
leg1.BorderSizePixel = 0
leg1.ZIndex = 3
leg1.Parent = girl
local l1c = Instance.new("UICorner"); l1c.CornerRadius = UDim.new(0,5); l1c.Parent = leg1
local leg2 = leg1:Clone(); leg2.Position = UDim2.fromOffset(80,110); leg2.Parent = girl

-- Островок
local pill = Instance.new("Frame")
pill.Size = UDim2.fromOffset(160,36)
pill.Position = UDim2.new(0.5,-80,0,10)
pill.BackgroundColor3 = Color3.fromRGB(20,20,20)
pill.BorderSizePixel = 0
pill.Visible = false
pill.ZIndex = 20
pill.Parent = gui
local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0,18); pc.Parent = pill
local pstroke = Instance.new("UIStroke"); pstroke.Color = Color3.fromRGB(201,162,39); pstroke.Thickness = 1; pstroke.Parent = pill
local pillText = Instance.new("TextLabel")
pillText.Size = UDim2.new(1,-10,1,0)
pillText.Position = UDim2.fromOffset(5,0)
pillText.BackgroundTransparency = 1
pillText.Font = Enum.Font.GothamBold
pillText.TextSize = 13
pillText.TextColor3 = Color3.fromRGB(220,220,220)
pillText.Text = "FPS: 0 | Ping: 0"
pillText.Parent = pill

-- Заголовок
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-60,0,30)
title.Position = UDim2.fromOffset(12,8)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(201,162,39)
title.Text = "SWILL • Piano Ultra"
title.Parent = main

-- Поле мелодии
local melodyBox = Instance.new("TextBox")
melodyBox.Size = UDim2.new(1,-24,0,130)
melodyBox.Position = UDim2.fromOffset(12,48)
melodyBox.BackgroundColor3 = Color3.fromRGB(10,10,10)
melodyBox.BorderSizePixel = 0
melodyBox.Font = Enum.Font.Code
melodyBox.TextSize = 12
melodyBox.TextColor3 = Color3.fromRGB(220,220,220)
melodyBox.PlaceholderColor3 = Color3.fromRGB(90,90,90)
melodyBox.PlaceholderText = "Мелодия: [*T69ey] - [6u] - * 0 W ..."
melodyBox.TextXAlignment = Enum.TextXAlignment.Left
melodyBox.TextYAlignment = Enum.TextYAlignment.Top
melodyBox.ClearTextOnFocus = false
melodyBox.MultiLine = true
melodyBox.TextWrapped = true
melodyBox.Text = ""
melodyBox.Parent = main
local mbc2 = Instance.new("UICorner"); mbc2.CornerRadius = UDim.new(0,8); mbc2.Parent = melodyBox

local function makeButton(parent, text, x, y, w, h, color, textColor)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(w,h)
    b.Position = UDim2.fromOffset(x,y)
    b.BackgroundColor3 = color or Color3.fromRGB(201,162,39)
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.TextColor3 = textColor or Color3.fromRGB(0,0,0)
    b.Text = text
    b.AutoButtonColor = true
    b.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = b
    return b
end

local playBtn = makeButton(main, "▶ Играть", 12, 188, 68, 32, Color3.fromRGB(201,162,39))
local stopBtn = makeButton(main, "■ Стоп", 88, 188, 68, 32, Color3.fromRGB(40,40,40), Color3.fromRGB(230,230,230))
local clearBtn = makeButton(main, "Очистить", 164, 188, 68, 32, Color3.fromRGB(40,40,40), Color3.fromRGB(230,230,230))
local antiBtn = makeButton(main, "Антискрипт", 240, 188, 68, 32, Color3.fromRGB(40,40,40), Color3.fromRGB(230,230,230))

-- Темп
local tempoFrame = Instance.new("Frame")
tempoFrame.Size = UDim2.fromOffset(200,34)
tempoFrame.Position = UDim2.new(0.5,-100,0,228)
tempoFrame.BackgroundTransparency = 1
tempoFrame.Parent = main

local leftArrow = makeButton(tempoFrame, "◀", 0, 2, 34, 30, Color3.fromRGB(40,40,40), Color3.fromRGB(230,230,230))
local tempoLabel = Instance.new("TextLabel")
tempoLabel.Size = UDim2.fromOffset(100,30)
tempoLabel.Position = UDim2.fromOffset(50,2)
tempoLabel.BackgroundTransparency = 1
tempoLabel.Font = Enum.Font.GothamBold
tempoLabel.TextSize = 13
tempoLabel.TextColor3 = Color3.fromRGB(220,220,220)
tempoLabel.Text = "Темп: 50 мс"
tempoLabel.Parent = tempoFrame
local rightArrow = makeButton(tempoFrame, "▶", 166, 2, 34, 30, Color3.fromRGB(40,40,40), Color3.fromRGB(230,230,230))

-- Сохранение
local nameBox = Instance.new("TextBox")
nameBox.Size = UDim2.fromOffset(150,30)
nameBox.Position = UDim2.fromOffset(12,268)
nameBox.BackgroundColor3 = Color3.fromRGB(10,10,10)
nameBox.BorderSizePixel = 0
nameBox.Font = Enum.Font.Gotham
nameBox.TextSize = 13
nameBox.TextColor3 = Color3.fromRGB(220,220,220)
nameBox.PlaceholderText = "Название песни"
nameBox.PlaceholderColor3 = Color3.fromRGB(90,90,90)
nameBox.Text = ""
nameBox.Parent = main
local nbc = Instance.new("UICorner"); nbc.CornerRadius = UDim.new(0,8); nbc.Parent = nameBox

local saveBtn = makeButton(main, "Сохранить", 170, 268, 138, 30, Color3.fromRGB(201,162,39))
local loadBtn = makeButton(main, "Загрузить", 12, 304, 140, 30, Color3.fromRGB(40,40,40), Color3.fromRGB(230,230,230))
local delAllBtn = makeButton(main, "Удалить все", 160, 304, 148, 30, Color3.fromRGB(40,40,40), Color3.fromRGB(230,230,230))

-- Список песен
local songList = Instance.new("ScrollingFrame")
songList.Size = UDim2.new(1,-24,0,140)
songList.Position = UDim2.fromOffset(12,344)
songList.BackgroundColor3 = Color3.fromRGB(12,12,12)
songList.BorderSizePixel = 0
songList.ScrollBarThickness = 4
songList.CanvasSize = UDim2.new(0,0,0,0)
songList.Parent = main
local slc = Instance.new("UICorner"); slc.CornerRadius = UDim.new(0,8); slc.Parent = songList
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0,4)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = songList

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1,-24,0,36)
statusLabel.Position = UDim2.fromOffset(12,490)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.TextWrapped = true
statusLabel.TextColor3 = Color3.fromRGB(140,140,140)
statusLabel.Text = "Готов к работе"
statusLabel.Parent = main

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
        statusLabel.Text = string.format("▶ %d / %d", idx, #tokens)
        if tok.chord then playChord(tok.chord)
        elseif tok.note == "-" then task.wait(CONFIG.restDuration)
        else playChord(tok.note) end
    end
    isPlaying = false
    statusLabel.Text = "Готово ✔"
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
stopBtn.MouseButton1Click:Connect(function() stopPlaying(); statusLabel.Text = "Остановлено" end)
clearBtn.MouseButton1Click:Connect(function() melodyBox.Text = "" end)

antiBtn.MouseButton1Click:Connect(function()
    CONFIG.antiskript = not CONFIG.antiskript
    if CONFIG.antiskript then
        antiBtn.BackgroundColor3 = Color3.fromRGB(201,162,39)
        antiBtn.TextColor3 = Color3.fromRGB(0,0,0)
        antiBtn.Text = "Антискрипт ON"
    else
        antiBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
        antiBtn.TextColor3 = Color3.fromRGB(230,230,230)
        antiBtn.Text = "Антискрипт"
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
        btn.BackgroundColor3 = Color3.fromRGB(20,20,20)
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
        btn.TextColor3 = Color3.fromRGB(220,220,220)
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
            statusLabel.Text = "Загружена: " .. song.name
        end)

        del.MouseButton1Click:Connect(function()
            table.remove(savedSongs, i)
            saveSongs()
            refreshSongList()
            statusLabel.Text = "Удалена: " .. song.name
        end)
    end
    songList.CanvasSize = UDim2.new(0,0,0, #savedSongs * 36 + 4)
end

saveBtn.MouseButton1Click:Connect(function()
    local name = nameBox.Text
    if name == "" then name = "Без названия " .. (#savedSongs + 1) end
    table.insert(savedSongs, {name = name, text = melodyBox.Text, tempo = tempoMs})
    local ok, msg = saveSongs()
    refreshSongList()
    nameBox.Text = ""
    statusLabel.Text = msg
end)

loadBtn.MouseButton1Click:Connect(function()
    local ok, msg = loadSongs()
    refreshSongList()
    statusLabel.Text = msg
end)

delAllBtn.MouseButton1Click:Connect(function()
    savedSongs = {}
    saveSongs()
    refreshSongList()
    statusLabel.Text = "Все песни удалены"
end)

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
    local swing = math.sin(t * 3) * 5
    leg1.Position = UDim2.fromOffset(60, 110 + swing)
    leg2.Position = UDim2.fromOffset(80, 110 - swing)
    local eyeShift = math.sin(t * 2) * 2
    eye1.Position = UDim2.fromOffset(15 + eyeShift, 22)
    eye2.Position = UDim2.fromOffset(39 + eyeShift, 22)
    arm1.Position = UDim2.fromOffset(47, 75 + math.sin(t*1.5)*1)
    arm2.Position = UDim2.fromOffset(95, 75 - math.sin(t*1.5)*1)
end)

-- Инициализация
loadSongs()
refreshSongList()
