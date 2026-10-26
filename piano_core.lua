local Core = {}
Core.held = {}
Core.keyMap = {}
for _, L in ipairs({"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"}) do
    Core.keyMap[L:lower()] = { key = Enum.KeyCode[L], shift = false }
    Core.keyMap[L]         = { key = Enum.KeyCode[L], shift = true  }
end
local digitNames = {"Zero","One","Two","Three","Four","Five","Six","Seven","Eight","Nine"}
for i = 0, 9 do Core.keyMap[tostring(i)] = { key = Enum.KeyCode[digitNames[i + 1]], shift = false } end
Core.keyMap["!"] = { key = Enum.KeyCode.One, shift = true }; Core.keyMap["@"] = { key = Enum.KeyCode.Two, shift = true }
Core.keyMap["$"] = { key = Enum.KeyCode.Four, shift = true }; Core.keyMap["%"] = { key = Enum.KeyCode.Five, shift = true }
Core.keyMap["^"] = { key = Enum.KeyCode.Six, shift = true }; Core.keyMap["*"] = { key = Enum.KeyCode.Eight, shift = true }
Core.keyMap["("] = { key = Enum.KeyCode.Nine, shift = true }; Core.keyMap["-"] = { key = Enum.KeyCode.Minus, shift = false }
Core.keyMap["="] = { key = Enum.KeyCode.Equals, shift = false }; Core.keyMap["["] = { key = Enum.KeyCode.LeftBracket, shift = false }
Core.keyMap["]"] = { key = Enum.KeyCode.RightBracket, shift = false }; Core.keyMap[";"] = { key = Enum.KeyCode.Semicolon, shift = false }
Core.keyMap["'"] = { key = Enum.KeyCode.Quote, shift = false }; Core.keyMap[","] = { key = Enum.KeyCode.Comma, shift = false }
Core.keyMap["."] = { key = Enum.KeyCode.Period, shift = false }; Core.keyMap["/"] = { key = Enum.KeyCode.Slash, shift = false }
Core.keyMap["\\"] = { key = Enum.KeyCode.BackSlash, shift = false }; Core.keyMap["`"] = { key = Enum.KeyCode.Backquote, shift = false }

local SEQ = "1!2@34$5%6^78*9(0qQwWeErtTyYuiIoOpPasSdDfgGhHjJklLzZxcCvVbBnm"
local SEQ_IDX = {}
for i = 1, #SEQ do SEQ_IDX[SEQ:sub(i, i)] = i end

function Core.transposeChars(str, n)
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

function Core.keyDown(info)
    local VIM = game:GetService("VirtualInputManager")
    if info.shift then VIM:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game) end
    VIM:SendKeyEvent(true, info.key, false, game)
    if info.shift then VIM:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game) end
    Core.held[info.key] = true
end

function Core.keyUp(info)
    local VIM = game:GetService("VirtualInputManager")
    VIM:SendKeyEvent(false, info.key, false, game)
    Core.held[info.key] = nil
end

function Core.releaseAll()
    local VIM = game:GetService("VirtualInputManager")
    for k in pairs(Core.held) do VIM:SendKeyEvent(false, k, false, game) end
    Core.held = {}
end

function Core.parseSong(str)
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

function Core.buildEvents(text, trans)
    local events, skipped = {}, 0
    for _, tk in ipairs(Core.parseSong(text)) do
        if tk.chord then
            local s, valid = Core.transposeChars(tk.chord, trans), {}
            for ch in s:gmatch(".") do
                if Core.keyMap[ch] then valid[#valid + 1] = ch else skipped = skipped + 1 end
            end
            if #valid > 0 then events[#events + 1] = { t = "n", keys = valid } end
        elseif tk.note == "-" or tk.note == "|" then
            events[#events + 1] = { t = "r" }
        else
            for ch in Core.transposeChars(tk.note, trans):gmatch(".") do
                if ch == "-" or ch == "|" then events[#events + 1] = { t = "r" }
                elseif Core.keyMap[ch] then events[#events + 1] = { t = "n", keys = { ch } }
                else skipped = skipped + 1 end
            end
        end
    end
    return events, skipped
end

function Core.readClipboard()
    local fns = { getclipboard, function() return syn.get_clipboard() end, readclipboard, fromclipboard }
    for _, f in ipairs(fns) do
        local ok, v = pcall(f)
        if ok and type(v) == "string" and v ~= "" then return v end
    end
    return nil
end

function Core.saveSongs(songs)
    pcall(function() if writefile then writefile("SWILL_Piano_Songs.json", game:GetService("HttpService"):JSONEncode(songs)) end end)
end

function Core.loadSongs()
    local songs = {}
    pcall(function()
        if isfile and isfile("SWILL_Piano_Songs.json") then
            local d = game:GetService("HttpService"):JSONDecode(readfile("SWILL_Piano_Songs.json"))
            if type(d) == "table" then songs = d end
        end
    end)
    return songs
end

_G.SWILL_Core = Core
