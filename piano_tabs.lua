-- piano_tabs.lua
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

-- Вкладка Игра (Слайдеры)
function UI.addSlider(parent, key, label, min, max)
    local f = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = UI.BG1 }, parent); UI.corner(f, 10)
    UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 5), Size = UDim2.new(1, 0, 0, 20), Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UI.TXT, Text = label }, f)
    local val = UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(1, -80, 0, 5), Size = UDim2.fromOffset(70, 20), Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = UI.ACC(), Text = tostring(UI.S[key]) }, f)
    local bar = UI.new("TextButton", { Position = UDim2.fromOffset(10, 35), Size = UDim2.new(1, -20, 0, 6), BackgroundColor3 = UI.BG2, Text = "" }, f); UI.corner(bar, UDim.new(1,0))
    local fill = UI.new("Frame", { Size = UDim2.fromScale((UI.S[key] - min) / (max - min), 1), BackgroundColor3 = UI.ACC() }, bar); UI.corner(fill, UDim.new(1,0))
    bar.MouseButton1Click:Connect(function() UI.S[key] = math.floor(min + (max - min) * 0.5); val.Text = tostring(UI.S[key]); fill.Size = UDim2.fromScale(0.5, 1) end)
end
UI.addSlider(UI.pagePlay, "tempo", "Темп (мс)", 10, 300)
UI.addSlider(UI.pagePlay, "speed", "Скорость", 0.5, 2)
UI.addSlider(UI.pagePlay, "transpose", "Транспонирование", -12, 12)

-- Вкладка Антискрипт
UI.antiBtn = UI.new("TextButton", { Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = UI.BG2, Text = "Антискрипт: ВЫКЛ", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = UI.TXT }, UI.pageAnti); UI.corner(UI.antiBtn, 10)
UI.antiBtn.Activated:Connect(function()
    UI.S.anti = not UI.S.anti
    UI.antiBtn.Text = UI.S.anti and "Антискрипт: ВКЛ" or "Антискрипт: ВЫКЛ"
    UI.antiBtn.BackgroundColor3 = UI.S.anti and UI.ACC() or UI.BG2
end)

-- Вкладка Настройки (Смена цвета)
UI.colorFrame = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = UI.BG1 }, UI.pageSet); UI.corner(UI.colorFrame, 10)
UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 15), Size = UDim2.fromOffset(150, 20), Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = UI.TXT, Text = "Цвет акцента:" }, UI.colorFrame)
for i, acc in ipairs(UI.ACCENTS) do
    local btn = UI.new("TextButton", { Size = UDim2.fromOffset(30, 30), Position = UDim2.fromOffset(150 + (i-1)*40, 10), BackgroundColor3 = acc.c, Text = "" }, UI.colorFrame); UI.corner(btn, UDim.new(1,0))
    btn.Activated:Connect(function() UI.S.accent = i; UI.cover.BackgroundColor3 = UI.ACC(); for _, b in ipairs(UI.eqBars) do b.BackgroundColor3 = UI.ACC() end end)
end

-- Логика плеера
UI.state = { playing = false, id = 0, progress = 0 }
function UI.playCurrent()
    if UI.state.playing or UI.melodyBox.Text:match("^%s*$") then return end
    UI.state.playing = true; UI.state.id = UI.state.id + 1; local my = UI.state.id
    local events = Core.buildEvents(UI.melodyBox.Text, UI.S.transpose)
    UI.setIslandPlaying(true)
    UI.titleLbl.Text = "Мелодия"; UI.subLbl.Text = "Играет..."
    task.spawn(function()
        for i, ev in ipairs(events) do
            if UI.state.id ~= my then break end
            UI.state.progress = i / #events
            if ev.t == "n" then
                for _, ch in ipairs(ev.keys) do Core.keyDown(Core.keyMap[ch]) end
                task.wait(UI.S.hold)
                for _, ch in ipairs(ev.keys) do Core.keyUp(Core.keyMap[ch]) end
                task.wait(UI.S.gap)
            else task.wait(UI.S.rest) end
        end
        if UI.state.id == my then UI.state.playing = false; UI.setIslandPlaying(false); UI.sendBtn.Text = "▶" end
    end)
    UI.sendBtn.Text = "■"
end

function UI.stopPlay() UI.state.playing = false; UI.state.id = UI.state.id + 1; Core.releaseAll(); UI.setIslandPlaying(false); UI.sendBtn.Text = "▶" end
UI.playBtn.Activated:Connect(UI.playCurrent); UI.stopBtn.Activated:Connect(UI.stopPlay)
UI.sendBtn.Activated:Connect(function() if UI.state.playing then UI.stopPlay() else UI.playCurrent() end end)
UI.clearBtn.Activated:Connect(function() UI.melodyBox.Text = "" end)

-- Циклы анимаций и пинга
local frames, accT, fps, ping = 0, 0, 0, 0
local t, phase = 0, 0
local RunService = game:GetService("RunService")
RunService.Heartbeat:Connect(function(dt)
    t = t + dt; frames = frames + 1; accT = accT + dt
    if accT >= 0.5 then fps = math.floor(frames / accT + 0.5); frames, accT = 0, 0; pcall(function() ping = math.floor(game:GetService("Players").LocalPlayer:GetNetworkPing() * 2000) end); if not UI.islandPlaying then UI.statsLabel.Text = string.format("FPS: %d | Ping: %d", fps, ping) end end
    
    if UI.islandPlaying then
        for i, b in ipairs(UI.eqBars) do local base = (math.sin(t * (6 + i * 1.7) + i) * 0.5 + 0.5); b.Size = UDim2.fromOffset(5, math.floor(4 + base * 6)) end
        UI.progFill.Size = UDim2.fromScale(math.clamp(UI.state.progress, 0, 1), 1)
    end

    if UI.S.girl and UI.main.Visible then
        phase = phase + dt * (UI.state.playing and 6 or 2.2)
        local sw = math.sin(phase) * (UI.state.playing and 15 or 8)
        UI.legL.Rotation = sw; UI.legR.Rotation = -sw
    end
end)

UI.switchTab("home")
UI.scaleObj.Scale = UI.baseScale()
UI.say("Привет! Я " .. UI.S.girlName .. ". Вставь мелодию, и я всё сыграю.")
