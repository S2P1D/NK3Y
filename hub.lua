-- ============================================================
-- NK3Y HUB - Loader + Remote Key System
-- ============================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local HttpService = game:GetService("HttpService")

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
-- OWNER KEY HASH (djb2)
-- ============================================================
-- Твой ключ: NK3Y_OWNER_2026
local OWNER_HASH = 1574169149

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
-- KEY SCREEN
-- ============================================================
local function showKeyScreen(callback)
    local keyGui = Instance.new("ScreenGui")
    keyGui.Name = "NK3Y_KeyScreen"
    keyGui.ResetOnSpawn = false
    keyGui.IgnoreGuiInset = true
    keyGui.DisplayOrder = 999
    keyGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

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

    local MainTab = Window:CreateTab("Скрипты", 4483362458)
    local InfoTab = Window:CreateTab("Инфо", nil)

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

    InfoTab:CreateParagraph({
        Title = "NK3Y HUB",
        Content = "Версия: 2.0\nАвтор: NK3Y\nСтатус: " .. (isOwner and "OWNER" or "USER") .. "\nКлюч: " .. string.sub(userKey, 1, 4) .. "***"
    })

    InfoTab:CreateButton({
        Name = "Сменить ключ",
        Callback = function()
            if delfile and isfile(KEY_FILE) then
                delfile(KEY_FILE)
            end
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
