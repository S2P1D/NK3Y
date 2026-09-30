-- ============================================================
-- NK3Y HUB - Loader + Key System + Keyboard Sounds + Boombox
-- ============================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

-- ============================================================
-- ССЫЛКИ
-- ============================================================
local KEYS_URL = "https://raw.githubusercontent.com/S2P1D/NK3Y/main/keys.json"

local SCRIPTS = {
    dcyf = {
        name = "DCYF Autofarm",
        url = "https://raw.githubusercontent.com/S2P1D/NK3Y/main/autofarm.lua",
        description = "Silent AKA NK3Y Autofarm v3.0"
    },
    bahkruums = {
        name = "Bahkruums Farm",
        url = "https://raw.githubusercontent.com/S2P1D/NK3Y/main/bahkruums.lua",
        description = "NK3Y Bahkruums Auto-farm + Auto-TP"
    }
}

-- ============================================================
-- ФИКС МАСШТАБА RAYFIELD
-- ============================================================
local function applyScaleFix(scale)
    local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
    local function tryFix()
        for _, gui in ipairs(pg:GetChildren()) do
            local n = string.lower(gui.Name)
            if gui:IsA("ScreenGui") and (n:find("rayfield") or n:find("ray_")) then
                local us = gui:FindFirstChildOfClass("UIScale")
                if not us then
                    us = Instance.new("UIScale")
                    us.Parent = gui
                end
                us.Scale = scale
                return true
            end
        end
        return false
    end
    task.spawn(function()
        for i = 1, 40 do
            if tryFix() then break end
            task.wait(0.25)
        end
    end)
end

local function getOptimalScale()
    local cam = workspace.CurrentCamera
    if not cam then return 0.85 end
    local vp = cam.ViewportSize
    local w = vp.X
    if w < 800 then return 0.7
    elseif w < 1000 then return 0.8
    elseif w < 1300 then return 0.85
    else return 1.0 end
end

-- ============================================================
-- OWNER KEY HASH
-- ============================================================
local OWNER_HASH = 1574169149 -- NK3Y_OWNER_2026

local function djb2(str)
    local h = 5381
    for i = 1, #str do
        h = (h * 33 + string.byte(str, i)) % 4294967296
    end
    return h
end

-- ============================================================
-- REMOTE KEY CHECK
-- ============================================================
local function fetchRemoteKeys()
    local ok, response = pcall(function()
        return game:HttpGet(KEYS_URL, true)
    end)
    if not ok or not response then return nil end
    local ok2, data = pcall(function()
        return HttpService:JSONDecode(response)
    end)
    if not ok2 or not data then return nil end
    return data.user_keys or {}
end

local function checkRemoteKey(key)
    local keys = fetchRemoteKeys()
    if not keys then return false, "Не удалось проверить ключ" end
    for _, entry in ipairs(keys) do
        if entry.key == key then
            if entry.expires then
                if os.time() > entry.expires then
                    return false, "Ключ истёк"
                end
            end
            return true, "OK"
        end
    end
    return false, "Ключ не найден"
end

local function validateKey(key)
    if not key or key == "" then return false, "Пустой ключ", nil end
    if djb2(key) == OWNER_HASH then
        return true, "OK", { owner = true }
    end
    local ok, msg = checkRemoteKey(key)
    if ok then return true, "OK", { owner = false } end
    return false, msg or "Неверный ключ", nil
end

-- ============================================================
-- SAVE KEY
-- ============================================================
local KEY_FILE = "NK3Y_HUB_KEY.txt"

local function loadSavedKey()
    if isfile and isfile(KEY_FILE) then
        local ok, data = pcall(function() return readfile(KEY_FILE) end)
        if ok and data then return data:gsub("%s+", "") end
    end
    return nil
end

local function saveKey(key)
    if writefile then
        pcall(function() writefile(KEY_FILE, key) end)
    end
end

-- ============================================================
-- KEYBOARD SOUNDS
-- ============================================================
local KB = {
    enabled = false,
    volume = 0.4,
    walkEnabled = true,
    jumpEnabled = true,
    landEnabled = true,
    walkInterval = 0.35,
    lastWalk = 0,
    walkSound = nil,
    jumpSound = nil,
    landSound = nil,
    conns = {},
    threads = {},
}

local KB_DEFAULT_WALK = "rbxassetid://512442625"
local KB_DEFAULT_JUMP = "rbxassetid://512442625"
local KB_DEFAULT_LAND = "rbxassetid://512442625"

local function createKbSound(name, id)
    local s = Instance.new("Sound")
    s.Name = "NK3Y_KB_" .. name
    s.SoundId = id
    s.Volume = KB.volume
    s.Parent = SoundService
    return s
end

local function playKbSound(sound)
    if not sound then return end
    if not sound.IsLoaded then return end
    sound:Stop()
    sound:Play()
end

local function startKeyboardSounds()
    if KB.enabled then return end
    KB.enabled = true

    KB.walkSound = KB.walkSound or createKbSound("Walk", KB_DEFAULT_WALK)
    KB.jumpSound = KB.jumpSound or createKbSound("Jump", KB_DEFAULT_JUMP)
    KB.landSound = KB.landSound or createKbSound("Land", KB_DEFAULT_LAND)

    local walkThread = task.spawn(function()
        while KB.enabled do
            task.wait(0.05)
            if KB.walkEnabled then
                local char = Players.LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then
                    local isMoving = hum.MoveDirection.Magnitude > 0.1
                    local isOnFloor = hum.FloorMaterial ~= Enum.Material.Air
                    local now = tick()
                    if isMoving and isOnFloor and (now - KB.lastWalk) >= KB.walkInterval then
                        KB.lastWalk = now
                        playKbSound(KB.walkSound)
                    end
                end
            end
        end
    end)
    table.insert(KB.threads, walkThread)

    local function hookHumanoid(hum)
        local c = hum.StateChanged:Connect(function(_, newState)
            if not KB.enabled then return end
            if newState == Enum.HumanoidStateType.Jumping and KB.jumpEnabled then
                playKbSound(KB.jumpSound)
            elseif newState == Enum.HumanoidStateType.Landed and KB.landEnabled then
                playKbSound(KB.landSound)
            end
        end)
        table.insert(KB.conns, c)
    end

    local function hookChar(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then hookHumanoid(hum) end
    end

    if Players.LocalPlayer.Character then
        hookChar(Players.LocalPlayer.Character)
    end
    local charConn = Players.LocalPlayer.CharacterAdded:Connect(hookChar)
    table.insert(KB.conns, charConn)
end

local function stopKeyboardSounds()
    KB.enabled = false
    for _, c in ipairs(KB.conns) do
        pcall(function() c:Disconnect() end)
    end
    KB.conns = {}
    for _, t in ipairs(KB.threads) do
        pcall(function() task.cancel(t) end)
    end
    KB.threads = {}
    if KB.walkSound then KB.walkSound:Stop() end
    if KB.jumpSound then KB.jumpSound:Stop() end
    if KB.landSound then KB.landSound:Stop() end
end

-- ============================================================
-- BOOMBOX
-- ============================================================
local Boombox = {
    sound = nil,
    volume = 0.5,
    isPlaying = false,
    currentId = nil,
    loop = false,
}

local function getBoomboxSound()
    if Boombox.sound and Boombox.sound.Parent then return Boombox.sound end
    local s = Instance.new("Sound")
    s.Name = "NK3Y_Boombox"
    s.Volume = Boombox.volume
    s.Looped = Boombox.loop
    s.Parent = SoundService
    Boombox.sound = s
    return s
end

local function normalizeTrackId(text)
    if not text then return nil end
    text = text:gsub("%s+", "")
    if text == "" then return nil end
    if text:find("rbxassetid://") then return text end
    if text:match("^%d+$") then return "rbxassetid://" .. text end
    local num = text:match("(%d+)")
    if num then return "rbxassetid://" .. num end
    return nil
end

local function tryPlayBoombox(idText)
    local id = normalizeTrackId(idText)
    if not id then
        return false, "неверный ID"
    end

    local s = getBoomboxSound()
    s:Stop()
    s.SoundId = id
    s.Volume = Boombox.volume
    s.Looped = Boombox.loop

    -- Форсируем загрузку ассета
    pcall(function()
        game:GetService("ContentProvider"):PreloadAsync({s})
    end)

    -- Проверяем загрузку в течение 3 секунд
    local waited = 0
    while waited < 3 do
        if s.IsLoaded and s.TimeLength > 0 then break end
        task.wait(0.1)
        waited = waited + 0.1
    end

    if s.IsLoaded and s.TimeLength > 0 then
        s:Play()
        Boombox.isPlaying = true
        Boombox.currentId = id
        return true, "успешно загружен!"
    else
        s:Stop()
        s.SoundId = ""
        Boombox.isPlaying = false
        Boombox.currentId = nil
        return false, "трек заблокирован/удалён"
    end
end

local function stopBoombox()
    if Boombox.sound then
        Boombox.sound:Stop()
    end
    Boombox.isPlaying = false
end

local function pauseBoombox()
    if Boombox.sound then
        Boombox.sound:Pause()
        Boombox.isPlaying = false
    end
end

-- ============================================================
-- KEY SCREEN
-- ============================================================
local function showKeyScreen(callback)
    local keyGui = Instance.new("ScreenGui")
    keyGui.Name = "NK3Y_KeyScreen"
    keyGui.ResetOnSpawn = false
    keyGui.IgnoreGuiInset = true
    keyGui.DisplayOrder = 999
    keyGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 0.3
    bg.BorderSizePixel = 0
    bg.Parent = keyGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 420, 0, 260)
    frame.Position = UDim2.new(0.5, -210, 0.5, -130)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BorderSizePixel = 0
    frame.Parent = keyGui

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 255, 100)
    stroke.Thickness = 2
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 60)
    title.Position = UDim2.new(0, 0, 0, 15)
    title.BackgroundTransparency = 1
    title.Text = "NK3Y HUB"
    title.TextColor3 = Color3.fromRGB(0, 255, 100)
    title.TextScaled = true
    title.Font = Enum.Font.Code
    title.Parent = frame

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, 0, 0, 24)
    sub.Position = UDim2.new(0, 0, 0, 70)
    sub.BackgroundTransparency = 1
    sub.Text = "введи ключ доступа"
    sub.TextColor3 = Color3.fromRGB(180, 180, 180)
    sub.TextScaled = true
    sub.Font = Enum.Font.Code
    sub.Parent = frame

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(0.85, 0, 0, 44)
    input.Position = UDim2.new(0.075, 0, 0, 110)
    input.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    input.BorderSizePixel = 0
    input.Text = ""
    input.PlaceholderText = "вставь ключ..."
    input.TextColor3 = Color3.fromRGB(255, 255, 255)
    input.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
    input.TextScaled = true
    input.Font = Enum.Font.Code
    input.ClearTextOnFocus = false
    input.Parent = frame

    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = Color3.fromRGB(0, 200, 80)
    inputStroke.Thickness = 1
    inputStroke.Parent = input

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 20)
    status.Position = UDim2.new(0, 0, 0, 160)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = Color3.fromRGB(255, 80, 80)
    status.TextScaled = true
    status.Font = Enum.Font.Code
    status.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.85, 0, 0, 44)
    btn.Position = UDim2.new(0.075, 0, 0, 190)
    btn.BackgroundColor3 = Color3.fromRGB(0, 180, 70)
    btn.BorderSizePixel = 0
    btn.Text = "ВОЙТИ"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.Code
    btn.Parent = frame

    local keyScale = getOptimalScale()
    if keyScale < 1 then
        local us = Instance.new("UIScale")
        us.Scale = math.max(0.6, keyScale)
        us.Parent = keyGui
    end

    local checking = false
    btn.MouseButton1Click:Connect(function()
        if checking then return end
        checking = true
        local key = input.Text:gsub("%s+", "")
        if key == "" then
            status.Text = "введи ключ"
            checking = false
            return
        end
        status.TextColor3 = Color3.fromRGB(180, 180, 180)
        status.Text = "проверка..."
        task.spawn(function()
            local ok, msg, data = validateKey(key)
            if ok then
                status.TextColor3 = Color3.fromRGB(0, 255, 100)
                status.Text = "ключ принят, загрузка..."
                saveKey(key)
                task.wait(0.5)
                keyGui:Destroy()
                callback(key, data)
            else
                status.TextColor3 = Color3.fromRGB(255, 80, 80)
                status.Text = msg
                checking = false
            end
        end)
    end)
end

-- ============================================================
-- HUB MENU
-- ============================================================
local function showHubMenu(userKey, userData)
    local isOwner = userData and userData.owner or false

    local Window = Rayfield:CreateWindow({
        Name = "NK3Y HUB" .. (isOwner and " | OWNER" or ""),
        LoadingTitle = "Загрузка...",
        LoadingSubtitle = "by NK3Y",
        Theme = {
            TextColor = Color3.fromRGB(0, 255, 100),
            Background = Color3.fromRGB(0, 0, 0),
            Topbar = Color3.fromRGB(5, 5, 5),
            Shadow = Color3.fromRGB(0, 10, 0),
            NotificationBackground = Color3.fromRGB(0, 20, 5),
            NotificationActionsBackground = Color3.fromRGB(0, 40, 15),
            TabBackground = Color3.fromRGB(0, 20, 0),
            TabStroke = Color3.fromRGB(0, 255, 100),
            TabBackgroundSelected = Color3.fromRGB(0, 80, 30),
            TabTextColor = Color3.fromRGB(0, 200, 80),
            SelectedTabTextColor = Color3.fromRGB(0, 255, 100),
            ElementBackground = Color3.fromRGB(5, 15, 5),
            ElementBackgroundHover = Color3.fromRGB(0, 40, 15),
            SecondaryElementBackground = Color3.fromRGB(0, 10, 0),
            ElementStroke = Color3.fromRGB(0, 200, 80),
            SecondaryElementStroke = Color3.fromRGB(0, 100, 40),
            SliderBackground = Color3.fromRGB(0, 50, 20),
            SliderProgress = Color3.fromRGB(0, 255, 100),
            SliderStroke = Color3.fromRGB(0, 255, 100),
            ToggleBackground = Color3.fromRGB(0, 30, 10),
            ToggleEnabled = Color3.fromRGB(0, 255, 100),
            ToggleDisabled = Color3.fromRGB(40, 40, 40),
            ToggleEnabledStroke = Color3.fromRGB(0, 255, 100),
            ToggleDisabledStroke = Color3.fromRGB(80, 80, 80),
            ToggleEnabledOuterStroke = Color3.fromRGB(0, 150, 60),
            ToggleDisabledOuterStroke = Color3.fromRGB(60, 60, 60),
            DropdownSelected = Color3.fromRGB(0, 40, 15),
            DropdownUnselected = Color3.fromRGB(0, 20, 5),
            InputBackground = Color3.fromRGB(5, 10, 5),
            InputStroke = Color3.fromRGB(0, 180, 70),
            PlaceholderColor = Color3.fromRGB(0, 100, 40)
        },
        ConfigurationSaving = { Enabled = false }
    })

    applyScaleFix(getOptimalScale())

    local MainTab = Window:CreateTab("Скрипты", 4483362458)
    local SoundTab = Window:CreateTab("Звуки", 4483362458)
    local BoomboxTab = Window:CreateTab("Бумбокс", 4483362458)
    local InfoTab = Window:CreateTab("Инфо", nil)

    -- ===== СКРИПТЫ =====
    MainTab:CreateSection("DCYF")
    MainTab:CreateButton({
        Name = "Загрузить " .. SCRIPTS.dcyf.name,
        Callback = function()
            Rayfield:Notify({Title = "Загрузка", Content = SCRIPTS.dcyf.name, Duration = 3})
            task.wait(0.5)
            local ok, err = pcall(function()
                loadstring(game:HttpGet(SCRIPTS.dcyf.url))()
            end)
            if not ok then
                Rayfield:Notify({Title = "Ошибка", Content = tostring(err), Duration = 5})
            end
        end
    })

    MainTab:CreateSection("Bahkruums")
    MainTab:CreateButton({
        Name = "Загрузить " .. SCRIPTS.bahkruums.name,
        Callback = function()
            Rayfield:Notify({Title = "Загрузка", Content = SCRIPTS.bahkruums.name, Duration = 3})
            task.wait(0.5)
            local ok, err = pcall(function()
                loadstring(game:HttpGet(SCRIPTS.bahkruums.url))()
            end)
            if not ok then
                Rayfield:Notify({Title = "Ошибка", Content = tostring(err), Duration = 5})
            end
        end
    })

    -- ===== ЗВУКИ =====
    SoundTab:CreateSection("Клавиатура")

    SoundTab:CreateToggle({
        Name = "Включить звуки клавиатуры",
        CurrentValue = false,
        Callback = function(value)
            if value then
                startKeyboardSounds()
                Rayfield:Notify({Title = "Звуки", Content = "Включены", Duration = 3})
            else
                stopKeyboardSounds()
                Rayfield:Notify({Title = "Звуки", Content = "Выключены", Duration = 3})
            end
        end
    })

    SoundTab:CreateSlider({
        Name = "Громкость",
        Range = {0, 100},
        Increment = 5,
        CurrentValue = 40,
        Callback = function(value)
            KB.volume = value / 100
            if KB.walkSound then KB.walkSound.Volume = KB.volume end
            if KB.jumpSound then KB.jumpSound.Volume = KB.volume end
            if KB.landSound then KB.landSound.Volume = KB.volume end
        end
    })

    SoundTab:CreateSlider({
        Name = "Частота кликов при ходьбе (сек)",
        Range = {0.1, 1},
        Increment = 0.05,
        CurrentValue = 0.35,
        Callback = function(value)
            KB.walkInterval = value
        end
    })

    SoundTab:CreateSection("Что играть")

    SoundTab:CreateToggle({
        Name = "Звук при ходьбе",
        CurrentValue = true,
        Callback = function(value)
            KB.walkEnabled = value
        end
    })

    SoundTab:CreateToggle({
        Name = "Звук при прыжке",
        CurrentValue = true,
        Callback = function(value)
            KB.jumpEnabled = value
        end
    })

    SoundTab:CreateToggle({
        Name = "Звук при приземлении",
        CurrentValue = true,
        Callback = function(value)
            KB.landEnabled = value
        end
    })

    SoundTab:CreateSection("Свои звуки (rbxassetid://)")

    SoundTab:CreateInput({
        Name = "ID звука ходьбы",
        CurrentValue = KB_DEFAULT_WALK,
        PlaceholderText = "rbxassetid://...",
        RemoveTextAfterFocusLost = false,
        Callback = function(text)
            if KB.walkSound then
                KB.walkSound.SoundId = text
            end
        end
    })

    SoundTab:CreateInput({
        Name = "ID звука прыжка",
        CurrentValue = KB_DEFAULT_JUMP,
        PlaceholderText = "rbxassetid://...",
        RemoveTextAfterFocusLost = false,
        Callback = function(text)
            if KB.jumpSound then
                KB.jumpSound.SoundId = text
            end
        end
    })

    SoundTab:CreateInput({
        Name = "ID звука приземления",
        CurrentValue = KB_DEFAULT_LAND,
        PlaceholderText = "rbxassetid://...",
        RemoveTextAfterFocusLost = false,
        Callback = function(text)
            if KB.landSound then
                KB.landSound.SoundId = text
            end
        end
    })

    -- ===== БУМБОКС =====
    BoomboxTab:CreateSection("Ввод трека")
    BoomboxTab:CreateParagraph({
        Title = "Как вводить ID:",
        Content = "• rbxassetid://1234567890\n• или просто число: 1234567890\n• или ссылку из Roblox library"
    })

    local trackInputRef = nil
    local statusRef = nil

    trackInputRef = BoomboxTab:CreateInput({
        Name = "ID трека",
        CurrentValue = "",
        PlaceholderText = "rbxassetid://... или число",
        RemoveTextAfterFocusLost = false,
        Callback = function(text)
            trackInputRef.Value = text
        end
    })

    BoomboxTab:CreateButton({
        Name = "▶ Воспроизвести",
        Callback = function()
            local txt = trackInputRef and trackInputRef.Value or ""
            if txt == "" then
                Rayfield:Notify({Title = "Бумбокс", Content = "Введи ID трека", Duration = 3})
                return
            end
            Rayfield:Notify({Title = "Бумбокс", Content = "Загрузка...", Duration = 2})
            task.spawn(function()
                local ok, msg = tryPlayBoombox(txt)
                if ok then
                    Rayfield:Notify({
                        Title = "Бумбокс",
                        Content = "✓ " .. msg,
                        Duration = 4
                    })
                else
                    Rayfield:Notify({
                        Title = "Бумбокс",
                        Content = "✗ " .. msg,
                        Duration = 4
                    })
                end
            end)
        end
    })

    BoomboxTab:CreateButton({
        Name = "⏸ Пауза",
        Callback = function()
            pauseBoombox()
            Rayfield:Notify({Title = "Бумбокс", Content = "Пауза", Duration = 2})
        end
    })

    BoomboxTab:CreateButton({
        Name = "⏹ Стоп",
        Callback = function()
            stopBoombox()
            Rayfield:Notify({Title = "Бумбокс", Content = "Стоп", Duration = 2})
        end
    })

    BoomboxTab:CreateSection("Настройки")

    BoomboxTab:CreateSlider({
        Name = "Громкость",
        Range = {0, 100},
        Increment = 5,
        CurrentValue = 50,
        Callback = function(value)
            Boombox.volume = value / 100
            if Boombox.sound then
                Boombox.sound.Volume = Boombox.volume
            end
        end
    })

    BoomboxTab:CreateToggle({
        Name = "Повтор трека (loop)",
        CurrentValue = false,
        Callback = function(value)
            Boombox.loop = value
            if Boombox.sound then
                Boombox.sound.Looped = value
            end
        end
    })

    -- ===== ИНФО =====
    InfoTab:CreateParagraph({
        Title = "NK3Y HUB",
        Content = "Версия: 2.4\nАвтор: NK3Y\nСтатус: " .. (isOwner and "OWNER" or "USER") .. "\nКлюч: " .. string.sub(userKey, 1, 4) .. "***"
    })

    InfoTab:CreateButton({
        Name = "Сменить ключ",
        Callback = function()
            if delfile and isfile(KEY_FILE) then
                delfile(KEY_FILE)
            end
            stopKeyboardSounds()
            stopBoombox()
            Rayfield:Notify({Title = "Ключ сброшен", Content = "Перезапусти скрипт", Duration = 3})
        end
    })

    Rayfield:Notify({
        Title = "NK3Y HUB",
        Content = isOwner and "Добро пожаловать, создатель!" or "Добро пожаловать!",
        Duration = 5
    })
end

-- ============================================================
-- START
-- ============================================================
local savedKey = loadSavedKey()

if savedKey then
    local ok, msg, data = validateKey(savedKey)
    if ok then
        showHubMenu(savedKey, data)
    else
        showKeyScreen(function(key, data)
            showHubMenu(key, data)
        end)
    end
else
    showKeyScreen(function(key, data)
        showHubMenu(key, data)
    end)
end
