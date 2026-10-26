local UI = _G.SWILL_UI
local Core = _G.SWILL_Core
if not UI or not Core then return warn("Ошибка: UI или Core не загружены") end

-- Главная вкладка
UI.chatScroll = UI.new("ScrollingFrame", { Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 1, -60), BackgroundTransparency = 1, ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, UI.pageHome)
UI.new("UIListLayout", { Padding = UDim.new(0, 10) }, UI.chatScroll)
UI.msgOrder, UI.msgRows = 0, {}
function UI.say(text)
    UI.msgOrder = UI.msgOrder + 1
    local row = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = UI.msgOrder }, UI.chatScroll)
    UI.new("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Left }, row)
    local bub = UI.new("Frame", { Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = UI.BUB }, row)
    UI.corner(bub, 16); UI.new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }, bub)
    local lbl = UI.new("TextLabel", { Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 14, TextColor3 = UI.TXT, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Text = text }, bub)
    UI.new("UISizeConstraint", { MaxSize = Vector2.new(400, math.huge) }, lbl)
    UI.msgRows[#UI.msgRows + 1] = row; if #UI.msgRows > 40 then table.remove(UI.msgRows, 1):Destroy() end
    task.delay(0.06, function() UI.chatScroll.CanvasPosition = Vector2.new(0, 99999) end)
    return lbl
end

UI.inputBar = UI.new("Frame", { Position = UDim2.new(0, 0, 1, -52), Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = Color3.fromRGB(24, 24, 27) }, UI.pageHome)
UI.corner(UI.inputBar, UDim.new(1, 0)); UI.stroke(UI.inputBar, UI.LINE, 1)
UI.melodyBox = UI.new("TextBox", { Position = UDim2.fromOffset(15, 0), Size = UDim2.new(1, -180, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 14, TextColor3 = UI.TXT, PlaceholderText = "Вставь мелодию...", PlaceholderColor3 = UI.DIM, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left }, UI.inputBar)
UI.sendBtn = UI.new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(40, 40), BackgroundColor3 = UI.ACC(), Text = "▶", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Color3.new(0,0,0) }, UI.inputBar); UI.corner(UI.sendBtn, 12)
UI.playBtn = UI.new("TextButton", { Size = UDim2.fromOffset(100, 40), BackgroundColor3 = UI.ACC(), Text = "▶ Играть", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.new(0,0,0) }, UI.pageHome); UI.corner(UI.playBtn, 10)
UI.stopBtn = UI.new("TextButton", { Size = UDim2.fromOffset(100, 40), BackgroundColor3 = UI.BG2, Text = "■ Стоп", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = UI.TXT }, UI.pageHome); UI.corner(UI.stopBtn, 10)
UI.clearBtn = UI.new("TextButton", { Size = UDim2.fromOffset(100, 40), BackgroundColor3 = UI.BG2, Text = "Очистить", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = UI.TXT }, UI.pageHome); UI.corner(UI.clearBtn, 10)

-- Вкладка Игра (Кнопки вместо слайдеров)
function UI.makeSpinner(parent, key, label, min, max, step)
    local f = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = UI.BG1 }, parent); UI.corner(f, 10)
    UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 15), Size = UDim2.new(1, -120, 0, 20), Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UI.TXT, Text = label }, f)
    local val = UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(1, -100, 0, 15), Size = UDim2.fromOffset(40, 20), Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = UI.ACC(), Text = tostring(UI.S[key]) }, f)
    local minus = UI.new("TextButton", { Position = UDim2.new(1, -55, 0, 10), Size = UDim2.fromOffset(24, 30), BackgroundColor3 = UI.BG2, Text = "-", TextColor3 = UI.TXT, Font = Enum.Font.GothamBold }, f); UI.corner(minus, 6)
    local plus = UI.new("TextButton", { Position = UDim2.new(1, -25, 0, 10), Size = UDim2.fromOffset(24, 30), BackgroundColor3 = UI.BG2, Text = "+", TextColor3 = UI.TXT, Font = Enum.Font.GothamBold }, f); UI.corner(plus, 6)
    minus.MouseButton1Click:Connect(function() UI.S[key] = math.max(min, UI.S[key] - step); val.Text = tostring(UI.S[key]) end)
    plus.MouseButton1Click:Connect(function() UI.S[key] = math.min(max, UI.S[key] + step); val.Text = tostring(UI.S[key]) end)
end
UI.makeSpinner(UI.pagePlay, "tempo", "Темп (мс)", 10, 300, 10)
UI.makeSpinner(UI.pagePlay, "speed", "Скорость", 0.5, 2, 0.1)
UI.makeSpinner(UI.pagePlay, "transpose", "Транспонирование", -12, 12, 1)

-- Вкладка Антискрипт
UI.antiBtn = UI.new("TextButton", { Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = UI.S.anti and UI.ACC() or UI.BG2, Text = UI.S.anti and "Антискрипт: ВКЛ" or "Антискрипт: ВЫКЛ", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = UI.S.anti and Color3.new(0,0,0) or UI.TXT }, UI.pageAnti); UI.corner(UI.antiBtn, 10)
UI.antiBtn.MouseButton1Click:Connect(function()
    UI.S.anti = not UI.S.anti
    UI.antiBtn.Text = UI.S.anti and "Антискрипт: ВКЛ" or "Антискрипт: ВЫКЛ"
    UI.antiBtn.BackgroundColor3 = UI.S.anti and UI.ACC() or UI.BG2
    UI.antiBtn.TextColor3 = UI.S.anti and Color3.new(0,0,0) or UI.TXT
end)

-- Вкладка Настройки
function UI.makeToggle(parent, key, label)
    local f = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = UI.BG1 }, parent); UI.corner(f, 10)
    UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -80, 1, 0), Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UI.TXT, Text = label }, f)
    local btn = UI.new("TextButton", { Position = UDim2.new(1, -70, 0, 5), Size = UDim2.fromOffset(60, 30), BackgroundColor3 = UI.S[key] and UI.ACC() or UI.BG2, Text = UI.S[key] and "ДА" or "НЕТ", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = UI.S[key] and Color3.new(0,0,0) or UI.TXT }, f); UI.corner(btn, 6)
    btn.MouseButton1Click:Connect(function()
        UI.S[key] = not UI.S[key]
        btn.Text = UI.S[key] and "ДА" or "НЕТ"
        btn.BackgroundColor3 = UI.S[key] and UI.ACC() or UI.BG2
        btn.TextColor3 = UI.S[key] and Color3.new(0,0,0) or UI.TXT
        if key == "girl" then UI.girl.Visible = UI.S.girl end
    end)
end
UI.makeToggle(UI.pageSet, "girl", "Показывать тяночку")
UI.makeToggle(UI.pageSet, "particles", "Частицы")
UI.makeToggle(UI.pageSet, "doodles", "Фон-дудлы")

-- Логика
UI.state = { playing = false, id = 0, progress = 0 }
function UI.playEvents(events, my)
    local t0 = os.clock()
    local ideal = 0
    for i, ev in ipairs(events) do
        if UI.state.id ~= my then break end
        local dur = (ev.t == "r") and ((UI.S.rest + UI.S.gap + UI.S.tempo / 1000) / UI.S.speed) or ((UI.S.hold + UI.S.gap + UI.S.tempo / 1000) / UI.S.speed)
        ideal = ideal + dur
        local target = t0 + ideal
        local w = target - os.clock()
        if w > 0 then task.wait(w) end
        UI.state.progress = i / #events
        if ev.t == "n" then
            for _, ch in ipairs(ev.keys) do Core.keyDown(Core.keyMap[ch]) end
            task.wait(math.min(UI.S.hold, dur * 0.8))
            for _, ch in ipairs(ev.keys) do Core.keyUp(Core.keyMap[ch]) end
        end
    end
    if UI.state.id == my then UI.state.playing = false; UI.sendBtn.Text = "▶" end
end
function UI.playCurrent()
    if UI.state.playing or UI.melodyBox.Text:match("^%s*$") then return end
    UI.state.playing = true; UI.state.id = UI.state.id + 1; local my = UI.state.id
    local events = Core.buildEvents(UI.melodyBox.Text, UI.S.transpose)
    UI.setIslandPlaying(true)
    UI.titleLbl.Text = "Мелодия"; UI.subLbl.Text = "Играет..."
    task.spawn(function() UI.playEvents(events, my) end)
    UI.sendBtn.Text = "■"
end
function UI.stopPlay() UI.state.playing = false; UI.state.id = UI.state.id + 1; Core.releaseAll(); UI.setIslandPlaying(false); UI.sendBtn.Text = "▶" end
UI.playBtn.MouseButton1Click:Connect(UI.playCurrent); UI.stopBtn.MouseButton1Click:Connect(UI.stopPlay)
UI.sendBtn.MouseButton1Click:Connect(function() if UI.state.playing then UI.stopPlay() else UI.playCurrent() end end)
UI.clearBtn.MouseButton1Click:Connect(function() UI.melodyBox.Text = "" end)

UI.switchTab("home")
UI.scaleObj.Scale = UI.baseScale()
UI.say("Привет! Я " .. UI.S.girlName .. ". Вставь мелодию, и я всё сыграю.")
