-- ============================================================
-- NK3Y HUB - GitHub keys.json Key System
-- ============================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

-- ============================================================
-- НАСТРОЙКИ
-- ============================================================
local KEYS_URL = "https://raw.githubusercontent.com/S2P1D/NK3Y/main/keys.json"
local PLACES = { DCYF = 128662368175518, Bahkruums = 91698952875688 }
local SCRIPTS = {
    dcyf = { name = "DCYF Autofarm", url = "https://raw.githubusercontent.com/S2P1D/NK3Y/main/autofarm.lua" },
    bahkruums = { name = "Bahkruums Farm", url = "https://raw.githubusercontent.com/S2P1D/NK3Y/main/bahkruums.lua" }
}

-- ============================================================
-- ФИКС МАСШТАБА
-- ============================================================
local function getOptimalScale()
    local w = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 800
    if w < 800 then return 0.7 elseif w < 1000 then return 0.8 elseif w < 1300 then return 0.85 else return 1.0 end
end

local function applyScaleFix(scale)
    local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
    task.spawn(function()
        for i = 1, 40 do
            for _, gui in ipairs(pg:GetChildren()) do
                local n = string.lower(gui.Name)
                if gui:IsA("ScreenGui") and (n:find("rayfield") or n:find("ray_")) then
                    local us = gui:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", gui)
                    us.Scale = scale; return
                end
            end
            task.wait(0.25)
        end
    end)
end

-- ============================================================
-- СИСТЕМА КЛЮЧЕЙ (GitHub JSON)
-- ============================================================
local OWNER_HASH = 1574169149 -- Твой ключ NK3Y_OWNER_2026

local function djb2(str)
    local h = 5381
    for i = 1, #str do
        h = (h * 33 + string.byte(str, i)) % 4294967296
    end
    return h
end

local function checkRemoteKey(key)
    local success, response = pcall(function()
        return game:HttpGet(KEYS_URL .. "?t=" .. tick(), true) -- ?t=... чтобы не кэшировало
    end)
    if not success or not response then return false, "Ошибка загрузки keys.json" end
    
    local ok, data = pcall(function() return HttpService:JSONDecode(response) end)
    if not ok or not data or not data.user_keys then return false, "Неверный формат keys.json" end
    
    for _, entry in ipairs(data.user_keys) do
        if entry.key == key then
            if entry.expires then
                if os.time() > entry.expires then
                    return false, "Ключ истёк"
                end
            end
            return true, "OK"
        end
    end
    return false, "Ключ не найден в базе"
end

local function validateKey(key)
    if not key or key == "" then return false, "Пустой ключ", nil end
    if djb2(key) == OWNER_HASH then return true, "OK", { owner = true } end
    local ok, msg = checkRemoteKey(key)
    if ok then return true, "OK", { owner = false } end
    return false, msg, nil
end

-- Инфо о ключе (парсим дату из JSON)
local function fetchKeyInfo(key)
    if djb2(key) == OWNER_HASH then return "Бессрочный (Владелец)" end
    
    local success, response = pcall(function()
        return game:HttpGet(KEYS_URL .. "?t=" .. tick(), true)
    end)
    if not success or not response then return "Ошибка загрузки keys.json" end
    
    local ok, data = pcall(function() return HttpService:JSONDecode(response) end)
    if not ok or not data or not data.user_keys then return "Неверный формат" end
    
    for _, entry in ipairs(data.user_keys) do
        if entry.key == key then
            if entry.expires then
                return "Истекает: " .. os.date("%d.%m.%Y %H:%M", entry.expires)
            else
                return "Бессрочный"
            end
        end
    end
    return "Ключ не найден"
end

-- ============================================================
-- СОХРАНЕНИЕ КЛЮЧА
-- ============================================================
local KEY_FILE = "NK3Y_HUB_KEY.txt"
local function loadSavedKey() if isfile and isfile(KEY_FILE) then return readfile(KEY_FILE):gsub("%s+","") end return nil end
local function saveKey(key) if writefile then writefile(KEY_FILE, key) end end

-- ============================================================
-- ЗВУКИ И БУМБОКС
-- ============================================================
local KB = { enabled = false, volume = 0.4, walkEnabled = true, jumpEnabled = true, landEnabled = true, walkInterval = 0.35, lastWalk = 0, conns = {}, threads = {} }
local KB_DEFAULT_WALK = "rbxassetid://7494098965"
local KB_DEFAULT_JUMP = "rbxassetid://7494098965"
local KB_DEFAULT_LAND = "rbxassetid://7494098965"

local function playKbSound(id)
    if not id then return end
    local s = Instance.new("Sound", SoundService)
    s.SoundId = id; s.Volume = KB.volume; s:Play()
    s.Ended:Connect(function() s:Destroy() end)
end

local function startKeyboardSounds()
    if KB.enabled then return end
    KB.enabled = true
    KB.walkSound = KB.walkSound or KB_DEFAULT_WALK
    KB.jumpSound = KB.jumpSound or KB_DEFAULT_JUMP
    KB.landSound = KB.landSound or KB_DEFAULT_LAND

    table.insert(KB.threads, task.spawn(function()
        while KB.enabled do
            task.wait(0.05)
            if KB.walkEnabled then
                local char = Players.LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum and hum.MoveDirection.Magnitude > 0.1 and hum.FloorMaterial ~= Enum.Material.Air and (tick() - KB.lastWalk) >= KB.walkInterval then
                    KB.lastWalk = tick(); playKbSound(KB.walkSound)
                end
            end
        end
    end))

    local function hookHumanoid(hum)
        table.insert(KB.conns, hum.StateChanged:Connect(function(_, newState)
            if not KB.enabled then return end
            if newState == Enum.HumanoidStateType.Jumping and KB.jumpEnabled then playKbSound(KB.jumpSound)
            elseif newState == Enum.HumanoidStateType.Landed and KB.landEnabled then playKbSound(KB.landSound) end
        end))
    end
    local function hookChar(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then hookHumanoid(hum) end
    end
    if Players.LocalPlayer.Character then hookChar(Players.LocalPlayer.Character) end
    table.insert(KB.conns, Players.LocalPlayer.CharacterAdded:Connect(hookChar))
end

local function stopKeyboardSounds()
    KB.enabled = false
    for _, c in ipairs(KB.conns) do pcall(function() c:Disconnect() end) end
    for _, t in ipairs(KB.threads) do pcall(function() task.cancel(t) end) end
    KB.conns, KB.threads = {}, {}
end

local Boombox = { sound = nil, volume = 0.5, loop = false }
local function normalizeTrackId(text)
    if not text then return nil end
    text = text:gsub("%s+", "")
    if text:find("rbxassetid://") then return text end
    if text:match("^%d+$") then return "rbxassetid://" .. text end
    local num = text:match("(%d+)")
    if num then return "rbxassetid://" .. num end
    return nil
end

local function tryPlayBoombox(idText)
    local id = normalizeTrackId(idText)
    if not id then return false, "неверный ID" end
    if not Boombox.sound then Boombox.sound = Instance.new("Sound", SoundService) end
    local s = Boombox.sound
    s:Stop(); s.SoundId = id; s.Volume = Boombox.volume; s.Looped = Boombox.loop
    pcall(function() game:GetService("ContentProvider"):PreloadAsync({s}) end)
    local waited = 0
    while waited < 3 and not (s.IsLoaded and s.TimeLength > 0) do task.wait(0.1); waited = waited + 0.1 end
    if s.IsLoaded and s.TimeLength > 0 then s:Play(); return true, "успешно!" else s:Stop(); s.SoundId = ""; return false, "заблокирован/удалён" end
end

local function createBoomboxTab(Window)
    local BTab = Window:CreateTab("Бумбокс", 4483362458)
    local trackInput
    BTab:CreateInput({Name = "ID трека", PlaceholderText = "rbxassetid://...", RemoveTextAfterFocusLost = false, Callback = function(t) trackInput = t end})
    BTab:CreateButton({Name = "▶ Воспроизвести", Callback = function()
        if not trackInput then return end
        Rayfield:Notify({Title = "Бумбокс", Content = "Загрузка...", Duration = 2})
        task.spawn(function() local ok, msg = tryPlayBoombox(trackInput); Rayfield:Notify({Title = "Бумбокс", Content = (ok and "✓ " or "✗ ") .. msg, Duration = 4}) end)
    end})
    BTab:CreateButton({Name = "⏹ Стоп", Callback = function() if Boombox.sound then Boombox.sound:Stop() end end})
    BTab:CreateSlider({Name = "Громкость", Range = {0, 100}, Increment = 5, CurrentValue = 50, Callback = function(v) Boombox.volume = v / 100; if Boombox.sound then Boombox.sound.Volume = Boombox.volume end end})
end

-- ============================================================
-- ЭКРАН ВВОДА КЛЮЧА
-- ============================================================
local function showKeyScreen(callback)
    local keyGui = Instance.new("ScreenGui", Players.LocalPlayer:WaitForChild("PlayerGui"))
    keyGui.Name, keyGui.IgnoreGuiInset, keyGui.DisplayOrder = "NK3Y_Key", true, 999

    local frame = Instance.new("Frame", keyGui)
    frame.Size, frame.Position = UDim2.new(0, 420, 0, 240), UDim2.new(0.5, -210, 0.5, -120)
    frame.BackgroundColor3, frame.BorderSizePixel = Color3.fromRGB(0, 0, 0), 0
    Instance.new("UIStroke", frame).Color = Color3.fromRGB(0, 255, 100)

    local title = Instance.new("TextLabel", frame)
    title.Size, title.Position, title.BackgroundTransparency = UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0, 20), 1
    title.Text, title.TextColor3, title.TextScaled, title.Font = "NK3Y HUB", Color3.fromRGB(0, 255, 100), true, Enum.Font.Code

    local input = Instance.new("TextBox", frame)
    input.Size, input.Position = UDim2.new(0.85, 0, 0, 44), UDim2.new(0.075, 0, 0, 80)
    input.BackgroundColor3, input.BorderSizePixel, input.Text = Color3.fromRGB(15, 15, 15), 0, ""
    input.PlaceholderText, input.TextColor3, input.TextScaled, input.Font = "вставь ключ...", Color3.fromRGB(255, 255, 255), true, Enum.Font.Code

    local status = Instance.new("TextLabel", frame)
    status.Size, status.Position, status.BackgroundTransparency = UDim2.new(0.9, 0, 0, 20), UDim2.new(0.05, 0, 0, 130), 1
    status.Text, status.TextColor3, status.TextScaled, status.Font = "", Color3.fromRGB(255, 80, 80), true, Enum.Font.Code

    local btn = Instance.new("TextButton", frame)
    btn.Size, btn.Position = UDim2.new(0.85, 0, 0, 44), UDim2.new(0.075, 0, 0, 160)
    btn.BackgroundColor3, btn.BorderSizePixel, btn.Text = Color3.fromRGB(0, 180, 70), 0, "ВОЙТИ"
    btn.TextColor3, btn.TextScaled, btn.Font = Color3.fromRGB(255, 255, 255), true, Enum.Font.Code

    local checking = false
    btn.MouseButton1Click:Connect(function()
        if checking then return end; checking = true
        local key = input.Text:gsub("%s+", "")
        if key == "" then status.Text = "введи ключ"; checking = false; return end
        
        status.TextColor3, status.Text = Color3.fromRGB(180, 180, 180), "проверка..."
        task.spawn(function()
            local ok, msg, data = validateKey(key)
            if ok then
                status.TextColor3, status.Text = Color3.fromRGB(0, 255, 100), "ключ принят..."
                saveKey(key); task.wait(0.5); keyGui:Destroy(); callback(key, data)
            else
                status.TextColor3, status.Text = Color3.fromRGB(255, 80, 80), msg; checking = false
            end
        end)
    end)
end

-- ============================================================
-- ГЛАВНОЕ МЕНЮ
-- ============================================================
local function showHubMenu(userKey, userData)
    local isOwner = userData and userData.owner or false

    local Window = Rayfield:CreateWindow({
        Name = "NK3Y HUB" .. (isOwner and " | OWNER" or ""),
        LoadingTitle = "Загрузка...", LoadingSubtitle = "by NK3Y",
        Theme = {
            TextColor = Color3.fromRGB(0, 255, 100), Background = Color3.fromRGB(0, 0, 0), Topbar = Color3.fromRGB(5, 5, 5),
            Shadow = Color3.fromRGB(0, 10, 0), NotificationBackground = Color3.fromRGB(0, 20, 5), NotificationActionsBackground = Color3.fromRGB(0, 40, 15),
            TabBackground = Color3.fromRGB(0, 20, 0), TabStroke = Color3.fromRGB(0, 255, 100), TabBackgroundSelected = Color3.fromRGB(0, 80, 30),
            TabTextColor = Color3.fromRGB(0, 200, 80), SelectedTabTextColor = Color3.fromRGB(0, 255, 100),
            ElementBackground = Color3.fromRGB(5, 15, 5), ElementBackgroundHover = Color3.fromRGB(0, 40, 15), SecondaryElementBackground = Color3.fromRGB(0, 10, 0),
            ElementStroke = Color3.fromRGB(0, 200, 80), SecondaryElementStroke = Color3.fromRGB(0, 100, 40),
            SliderBackground = Color3.fromRGB(0, 50, 20), SliderProgress = Color3.fromRGB(0, 255, 100), SliderStroke = Color3.fromRGB(0, 255, 100),
            ToggleBackground = Color3.fromRGB(0, 30, 10), ToggleEnabled = Color3.fromRGB(0, 255, 100), ToggleDisabled = Color3.fromRGB(40, 40, 40),
            ToggleEnabledStroke = Color3.fromRGB(0, 255, 100), ToggleDisabledStroke = Color3.fromRGB(80, 80, 80), ToggleEnabledOuterStroke = Color3.fromRGB(0, 150, 60),
            ToggleDisabledOuterStroke = Color3.fromRGB(60, 60, 60), DropdownSelected = Color3.fromRGB(0, 40, 15), DropdownUnselected = Color3.fromRGB(0, 20, 5),
            InputBackground = Color3.fromRGB(5, 10, 5), InputStroke = Color3.fromRGB(0, 180, 70), PlaceholderColor = Color3.fromRGB(0, 100, 40)
        },
        ConfigurationSaving = { Enabled = false }
    })
    applyScaleFix(getOptimalScale())

    local MainTab = Window:CreateTab("Скрипты", 4483362458)
    local SoundTab = Window:CreateTab("Звуки", 4483362458)
    local InfoTab = Window:CreateTab("Ключ / Инфо", 4483362458)

    -- ===== СКРИПТЫ =====
    MainTab:CreateSection("DCYF")
    MainTab:CreateButton({Name = "Загрузить " .. SCRIPTS.dcyf.name, Callback = function()
        Rayfield:Notify({Title = "Загрузка", Content = SCRIPTS.dcyf.name, Duration = 3})
        task.spawn(function() getgenv().NK3Y_Key = userKey; pcall(function() loadstring(game:HttpGet(SCRIPTS.dcyf.url))() end); createBoomboxTab(Window) end)
    end})

    MainTab:CreateSection("Bahkruums")
    MainTab:CreateButton({Name = "Загрузить " .. SCRIPTS.bahkruums.name, Callback = function()
        Rayfield:Notify({Title = "Загрузка", Content = SCRIPTS.bahkruums.name, Duration = 3})
        task.spawn(function() getgenv().NK3Y_Key = userKey; pcall(function() loadstring(game:HttpGet(SCRIPTS.bahkruums.url))() end); createBoomboxTab(Window) end)
    end})

    -- ===== ЗВУКИ =====
    SoundTab:CreateSection("Клавиатура")
    SoundTab:CreateToggle({Name = "Включить звуки", CurrentValue = false, Callback = function(v) if v then startKeyboardSounds() else stopKeyboardSounds() end end})
    SoundTab:CreateSlider({Name = "Громкость", Range = {0, 100}, CurrentValue = 40, Callback = function(v) KB.volume = v / 100 end})
    SoundTab:CreateInput({Name = "ID звука ходьбы", CurrentValue = KB_DEFAULT_WALK, PlaceholderText = "rbxassetid://...", RemoveTextAfterFocusLost = false, Callback = function(t) KB.walkSound = t end})
    SoundTab:CreateInput({Name = "ID звука прыжка", CurrentValue = KB_DEFAULT_JUMP, PlaceholderText = "rbxassetid://...", RemoveTextAfterFocusLost = false, Callback = function(t) KB.jumpSound = t end})
    SoundTab:CreateInput({Name = "ID звука приземления", CurrentValue = KB_DEFAULT_LAND, PlaceholderText = "rbxassetid://...", RemoveTextAfterFocusLost = false, Callback = function(t) KB.landSound = t end})

    -- ===== ИНФО И КЛЮЧ =====
    InfoTab:CreateSection("Информация")
    InfoTab:CreateButton({Name = "Твой статус: " .. (isOwner and "Владелец" or "Пользователь"), Callback = function() end})
    InfoTab:CreateButton({Name = "Твой ключ: " .. string.sub(tostring(userKey), 1, 8) .. "***", Callback = function() end})
    InfoTab:CreateButton({
        Name = "Узнать время ключа",
        Callback = function()
            Rayfield:Notify({Title = "Запрос", Content = "Читаем keys.json...", Duration = 2})
            task.spawn(function()
                local info = fetchKeyInfo(userKey)
                Rayfield:Notify({Title = "Инфо о ключе", Content = info, Duration = 5})
            end)
        end
    })
    InfoTab:CreateButton({Name = "Скопировать мой ключ", Callback = function() if setclipboard then setclipboard(userKey); Rayfield:Notify({Title = "Успех", Content = "Скопировано", Duration = 3}) end end})
    InfoTab:CreateButton({Name = "Сбросить ключ", Callback = function() if delfile and isfile(KEY_FILE) then pcall(function() delfile(KEY_FILE) end); Rayfield:Notify({Title = "Сброс", Content = "Ключ удален", Duration = 5}) end end})
end

-- ============================================================
-- СТАРТ
-- ============================================================
local savedKey = loadSavedKey()

if savedKey then
    local ok, msg, data = validateKey(savedKey)
    if ok then showHubMenu(savedKey, data)
    else showKeyScreen(function(key, data) showHubMenu(key, data) end) end
else
    showKeyScreen(function(key, data) showHubMenu(key, data) end)
end
