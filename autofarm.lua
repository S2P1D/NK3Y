-- ============================================================
-- Silent AKA NK3Y Autofarm v3.0
-- ============================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local HttpService = game:GetService("HttpService")

-- ===== ЛОКАЛИЗАЦИЯ =====
local Locales = {
    ru = {
        window_title = "Silent AKA NK3Y Autofarm v3.0",
        loading_title = "Загрузка...",
        loading_subtitle = "by NK3Y",
        tab_farm = "Фарм",
        tab_points = "Точки",
        tab_tracker = "Счётчики",
        tab_server = "Сервер",
        tab_config = "Конфиг",
        tab_settings = "Настройки",
        farm_toggle = "Включить автофарм (по точкам)",
        farm_delay = "Время на точке (сек)",
        save_position = "Сохранить текущую позицию",
        clear_points = "Очистить все точки",
        tracker_show = "Показать счётчики",
        tracker_transparency = "Прозрачность",
        tracker_pos_x = "Позиция X",
        tracker_pos_y = "Позиция Y",
        server_hop = "Server Hop (случайный)",
        auto_rejoin = "Auto Rejoin (при смерти)",
        reconnect_now = "Реконнект сейчас",
        config_save = "Сохранить конфиг",
        config_load = "Загрузить конфиг",
        config_delete = "Удалить конфиг",
        anti_afk = "Anti-AFK",
        language = "Язык",
        notify_saved = "Сохранено",
        notify_point_added = "Точка %d добавлена",
        notify_cleared = "Очищено",
        notify_all_points_deleted = "Все точки удалены",
        notify_config_saved = "Сохранён",
        notify_config_loaded = "Загружен (%d точек)",
        notify_config_deleted = "Файл удалён",
        notify_config_not_found = "Файл не найден",
        notify_config_no_file = "Файла нет",
        notify_error = "Ошибка",
        notify_error_save = "Не удалось сохранить: ",
        notify_error_load = "Не удалось загрузить конфиг",
        notify_server_hop = "Поиск сервера...",
        notify_loaded = "Загружен. by NK3Y"
    },
    en = {
        window_title = "Silent AKA NK3Y Autofarm v3.0",
        loading_title = "Loading...",
        loading_subtitle = "by NK3Y",
        tab_farm = "Farm",
        tab_points = "Points",
        tab_tracker = "Counters",
        tab_server = "Server",
        tab_config = "Config",
        tab_settings = "Settings",
        farm_toggle = "Enable autofarm (by points)",
        farm_delay = "Time per point (sec)",
        save_position = "Save current position",
        clear_points = "Clear all points",
        tracker_show = "Show counters",
        tracker_transparency = "Transparency",
        tracker_pos_x = "Position X",
        tracker_pos_y = "Position Y",
        server_hop = "Server Hop (random)",
        auto_rejoin = "Auto Rejoin (on death)",
        reconnect_now = "Reconnect now",
        config_save = "Save config",
        config_load = "Load config",
        config_delete = "Delete config",
        anti_afk = "Anti-AFK",
        language = "Language",
        notify_saved = "Saved",
        notify_point_added = "Point %d added",
        notify_cleared = "Cleared",
        notify_all_points_deleted = "All points deleted",
        notify_config_saved = "Saved",
        notify_config_loaded = "Loaded (%d points)",
        notify_config_deleted = "File deleted",
        notify_config_not_found = "File not found",
        notify_config_no_file = "No file",
        notify_error = "Error",
        notify_error_save = "Failed to save: ",
        notify_error_load = "Failed to load config",
        notify_server_hop = "Searching for server...",
        notify_loaded = "Loaded. by NK3Y"
    }
}

local currentLang = "ru"

local function T(key)
    local loc = Locales[currentLang] or Locales.ru
    return loc[key] or key
end

-- ===== СОСТОЯНИЕ =====
local placeId = 128662368175518
local isFarming = false
local farmThread = nil
local autoReconnect = true
local pointDelay = 5
local teleportPoints = {}
local currentPointIndex = 1

local trackerGui = nil
local seasonLabel = nil
local totalLabel = nil
local trackerVisible = true
local trackerTransparency = 0.5
local trackerPosition = UDim2.new(0, 10, 0, 10)

local antiAfkActive = false
local antiAfkThread = nil

local farmToggle, antiAfkToggle, autoRejoinToggle, trackerToggle, trackerTransparencySlider
local windowRef = nil

local CONFIG_FILE = "DummyCounter_Config.json"

-- ===== ФАРМ =====
local function startFarm()
    if farmThread then task.cancel(farmThread) end
    isFarming = true
    farmThread = task.spawn(function()
        while isFarming do
            if #teleportPoints > 0 then
                local point = teleportPoints[currentPointIndex]
                pcall(function()
                    local char = game.Players.LocalPlayer.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        char.HumanoidRootPart.CFrame = point.CFrame
                    end
                end)
                currentPointIndex = currentPointIndex + 1
                if currentPointIndex > #teleportPoints then currentPointIndex = 1 end
            end
            task.wait(pointDelay)
        end
    end)
end

local function stopFarm()
    isFarming = false
    if farmThread then task.cancel(farmThread) end
end

-- ===== SERVER HOP =====
local function getServers()
    local servers = {}
    local cursor = ""
    repeat
        local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?limit=100&cursor=" .. cursor
        local success, response = pcall(function() return game:HttpGet(url) end)
        if success then
            local data = HttpService:JSONDecode(response)
            if data and data.data then
                for _, server in ipairs(data.data) do
                    if server.playing < server.maxPlayers and server.id ~= game.JobId then
                        table.insert(servers, server)
                    end
                end
                cursor = data.nextPageCursor or ""
            else cursor = "" end
        else cursor = "" end
        task.wait(0.5)
    until cursor == "" or #servers >= 100
    return servers
end

local function serverHop()
    local servers = getServers()
    if #servers > 0 then
        local randomServer = servers[math.random(1, #servers)]
        pcall(function()
            game:GetService("TeleportService"):TeleportToPlaceInstance(placeId, randomServer.id, game.Players.LocalPlayer)
        end)
    end
end

-- ===== ANTI-AFK =====
local function startAntiAfk()
    if antiAfkThread then task.cancel(antiAfkThread) end
    antiAfkActive = true
    antiAfkThread = task.spawn(function()
        while antiAfkActive do
            pcall(function()
                local vu = game:GetService("VirtualUser")
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
            task.wait(60)
        end
    end)
end

local function stopAntiAfk()
    antiAfkActive = false
    if antiAfkThread then task.cancel(antiAfkThread) end
end

-- ===== COUNTER TRACKER =====
local function createTrackerGui()
    if trackerGui then trackerGui:Destroy() end

    trackerGui = Instance.new("ScreenGui")
    trackerGui.Name = "CounterTracker"
    trackerGui.ResetOnSpawn = false
    trackerGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 220, 0, 70)
    frame.Position = trackerPosition
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = trackerTransparency
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = trackerGui

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 255, 100)
    stroke.Thickness = 1
    stroke.Parent = frame

    local seasonTitle = Instance.new("TextLabel")
    seasonTitle.Size = UDim2.new(0.5, 0, 0.4, 0)
    seasonTitle.Position = UDim2.new(0, 5, 0, 5)
    seasonTitle.BackgroundTransparency = 1
    seasonTitle.Text = "Season:"
    seasonTitle.TextColor3 = Color3.fromRGB(0, 255, 100)
    seasonTitle.TextScaled = true
    seasonTitle.Font = Enum.Font.Code
    seasonTitle.Parent = frame

    seasonLabel = Instance.new("TextLabel")
    seasonLabel.Size = UDim2.new(0.45, 0, 0.4, 0)
    seasonLabel.Position = UDim2.new(0.5, 0, 0, 5)
    seasonLabel.BackgroundTransparency = 1
    seasonLabel.Text = "0"
    seasonLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    seasonLabel.TextScaled = true
    seasonLabel.Font = Enum.Font.Code
    seasonLabel.Parent = frame

    local totalTitle = Instance.new("TextLabel")
    totalTitle.Size = UDim2.new(0.5, 0, 0.4, 0)
    totalTitle.Position = UDim2.new(0, 5, 0.45, 0)
    totalTitle.BackgroundTransparency = 1
    totalTitle.Text = "Total:"
    totalTitle.TextColor3 = Color3.fromRGB(0, 255, 100)
    totalTitle.TextScaled = true
    totalTitle.Font = Enum.Font.Code
    totalTitle.Parent = frame

    totalLabel = Instance.new("TextLabel")
    totalLabel.Size = UDim2.new(0.45, 0, 0.4, 0)
    totalLabel.Position = UDim2.new(0.5, 0, 0.45, 0)
    totalLabel.BackgroundTransparency = 1
    totalLabel.Text = "0"
    totalLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
    totalLabel.TextScaled = true
    totalLabel.Font = Enum.Font.Code
    totalLabel.Parent = frame

    frame.Visible = trackerVisible

    local function bindStats()
        local player = game.Players.LocalPlayer
        local ls = player:FindFirstChild("leaderstats")
        if ls then
            local stats = ls:GetChildren()
            if #stats >= 1 then
                seasonLabel.Text = tostring(stats[1].Value)
                stats[1]:GetPropertyChangedSignal("Value"):Connect(function()
                    seasonLabel.Text = tostring(stats[1].Value)
                end)
            end
            if #stats >= 2 then
                totalLabel.Text = tostring(stats[2].Value)
                stats[2]:GetPropertyChangedSignal("Value"):Connect(function()
                    totalLabel.Text = tostring(stats[2].Value)
                end)
            end
        end
    end

    bindStats()
end

local function updateTrackerVisibility()
    if trackerGui then
        for _, v in ipairs(trackerGui:GetChildren()) do
            if v:IsA("Frame") then v.Visible = trackerVisible end
        end
    end
end

local function updateTrackerTransparency()
    if trackerGui then
        for _, v in ipairs(trackerGui:GetChildren()) do
            if v:IsA("Frame") then v.BackgroundTransparency = trackerTransparency end
        end
    end
end

local function updateTrackerPosition()
    if trackerGui then
        for _, v in ipairs(trackerGui:GetChildren()) do
            if v:IsA("Frame") then v.Position = trackerPosition end
        end
    end
end

-- ===== КОНФИГ =====
local function saveConfig()
    local data = {
        teleportPoints = {},
        isFarming = isFarming,
        pointDelay = pointDelay,
        autoReconnect = autoReconnect,
        trackerVisible = trackerVisible,
        trackerTransparency = trackerTransparency,
        trackerPosition = { x = trackerPosition.X.Offset, y = trackerPosition.Y.Offset },
        antiAfkActive = antiAfkActive,
        language = currentLang
    }
    for _, point in ipairs(teleportPoints) do
        table.insert(data.teleportPoints, {
            x = point.CFrame.X, y = point.CFrame.Y, z = point.CFrame.Z, name = point.Name
        })
    end
    local success, err = pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(data))
    end)
    if success then
        Rayfield:Notify({Title = T("notify_saved"), Content = T("notify_config_saved"), Duration = 3})
    else
        Rayfield:Notify({Title = T("notify_error"), Content = T("notify_error_save") .. tostring(err), Duration = 5})
    end
end

local function loadConfig()
    if not isfile(CONFIG_FILE) then
        Rayfield:Notify({Title = T("notify_saved"), Content = T("notify_config_not_found"), Duration = 3})
        return
    end
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)
    if not success or not data then
        Rayfield:Notify({Title = T("notify_error"), Content = T("notify_error_load"), Duration = 5})
        return
    end

    teleportPoints = {}
    if data.teleportPoints then
        for _, p in ipairs(data.teleportPoints) do
            table.insert(teleportPoints, {
                CFrame = CFrame.new(p.x, p.y, p.z),
                Name = p.name or "Точка"
            })
        end
    end
    currentPointIndex = 1

    pointDelay = data.pointDelay or 5
    autoReconnect = data.autoReconnect ~= false
    trackerVisible = data.trackerVisible ~= false
    trackerTransparency = data.trackerTransparency or 0.5
    if data.trackerPosition then
        trackerPosition = UDim2.new(0, data.trackerPosition.x or 10, 0, data.trackerPosition.y or 10)
    end
    if data.language then
        currentLang = data.language
    end

    local shouldFarm = data.isFarming == true
    isFarming = false
    if farmToggle then farmToggle:Set(shouldFarm) end
    if shouldFarm then startFarm() else stopFarm() end

    local shouldAntiAfk = data.antiAfkActive == true
    if antiAfkToggle then antiAfkToggle:Set(shouldAntiAfk) end
    if shouldAntiAfk then startAntiAfk() else stopAntiAfk() end

    if autoRejoinToggle then autoRejoinToggle:Set(autoReconnect) end
    if trackerToggle then trackerToggle:Set(trackerVisible) end
    if trackerTransparencySlider then trackerTransparencySlider:Set(trackerTransparency) end
    if trackerGui then
        updateTrackerVisibility()
        updateTrackerTransparency()
        updateTrackerPosition()
    end

    Rayfield:Notify({Title = T("notify_saved"), Content = string.format(T("notify_config_loaded"), #teleportPoints), Duration = 3})
end

-- ===== QUEUE_ON_TELEPORT =====
local function saveStateForTeleport()
    local data = {
        teleportPoints = {},
        isFarming = isFarming,
        pointDelay = pointDelay,
        autoReconnect = autoReconnect,
        trackerVisible = trackerVisible,
        trackerTransparency = trackerTransparency,
        trackerPosition = {x = trackerPosition.X.Offset, y = trackerPosition.Y.Offset},
        antiAfkActive = antiAfkActive
    }
    for _, point in ipairs(teleportPoints) do
        table.insert(data.teleportPoints, {
            x = point.CFrame.X, y = point.CFrame.Y, z = point.CFrame.Z, name = point.Name
        })
    end
    pcall(function()
        writefile("DummyCounter_TeleportState.json", HttpService:JSONEncode(data))
    end)
end

if queue_on_teleport then
    queue_on_teleport([[
        repeat task.wait() until game:IsLoaded()
        local HttpService = game:GetService("HttpService")
        local stateFile = "DummyCounter_TeleportState.json"
        local state = nil
        if isfile(stateFile) then
            local ok, data = pcall(function() return HttpService:JSONDecode(readfile(stateFile)) end)
            if ok then state = data end
        end
        if state then
            local points = {}
            if state.teleportPoints then
                for _, p in ipairs(state.teleportPoints) do
                    table.insert(points, {CFrame = CFrame.new(p.x, p.y, p.z), Name = p.name or "Точка"})
                end
            end
            if state.isFarming and #points > 0 then
                local pointDelay = state.pointDelay or 5
                local currentIndex = 1
                task.spawn(function()
                    while true do
                        local point = points[currentIndex]
                        pcall(function()
                            local char = game.Players.LocalPlayer.Character
                            if char and char:FindFirstChild("HumanoidRootPart") then
                                char.HumanoidRootPart.CFrame = point.CFrame
                            end
                        end)
                        currentIndex = currentIndex + 1
                        if currentIndex > #points then currentIndex = 1 end
                        task.wait(pointDelay)
                    end
                end)
            end
        end
    ]])
end

-- ===== СОЗДАНИЕ ОКНА =====
local Window = Rayfield:CreateWindow({
    Name = T("window_title"),
    LoadingTitle = T("loading_title"),
    LoadingSubtitle = T("loading_subtitle"),
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

windowRef = Window

local MainTab = Window:CreateTab(T("tab_farm"), 4483362458)
local PointsTab = Window:CreateTab(T("tab_points"), nil)
local TrackerTab = Window:CreateTab(T("tab_tracker"), nil)
local ServerTab = Window:CreateTab(T("tab_server"), nil)
local ConfigTab = Window:CreateTab(T("tab_config"), nil)
local SettingsTab = Window:CreateTab(T("tab_settings"), nil)

-- ===== ВКЛАДКА ФАРМ =====
farmToggle = MainTab:CreateToggle({
    Name = T("farm_toggle"),
    CurrentValue = false,
    Callback = function(value)
        if value then startFarm() else stopFarm() end
    end
})

MainTab:CreateSlider({
    Name = T("farm_delay"),
    Range = {1, 30},
    Increment = 1,
    CurrentValue = pointDelay,
    Callback = function(value) pointDelay = value end
})

-- ===== ВКЛАДКА ТОЧКИ =====
PointsTab:CreateButton({
    Name = T("save_position"),
    Callback = function()
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local cf = char.HumanoidRootPart.CFrame
            table.insert(teleportPoints, {CFrame = cf, Name = "Точка " .. (#teleportPoints + 1)})
            Rayfield:Notify({Title = T("notify_saved"), Content = string.format(T("notify_point_added"), #teleportPoints), Duration = 3})
        end
    end
})

PointsTab:CreateButton({
    Name = T("clear_points"),
    Callback = function()
        teleportPoints = {}
        currentPointIndex = 1
        Rayfield:Notify({Title = T("notify_cleared"), Content = T("notify_all_points_deleted"), Duration = 3})
    end
})

-- ===== ВКЛАДКА СЧЁТЧИКИ =====
trackerToggle = TrackerTab:CreateToggle({
    Name = T("tracker_show"),
    CurrentValue = true,
    Callback = function(value)
        trackerVisible = value
        updateTrackerVisibility()
    end
})

trackerTransparencySlider = TrackerTab:CreateSlider({
    Name = T("tracker_transparency"),
    Range = {0, 1},
    Increment = 0.1,
    CurrentValue = trackerTransparency,
    Callback = function(value)
        trackerTransparency = value
        updateTrackerTransparency()
    end
})

TrackerTab:CreateInput({
    Name = T("tracker_pos_x"),
    CurrentValue = "10",
    PlaceholderText = "X",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        local x = tonumber(text) or 10
        trackerPosition = UDim2.new(0, x, 0, trackerPosition.Y.Offset)
        updateTrackerPosition()
    end
})

TrackerTab:CreateInput({
    Name = T("tracker_pos_y"),
    CurrentValue = "10",
    PlaceholderText = "Y",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        local y = tonumber(text) or 10
        trackerPosition = UDim2.new(0, trackerPosition.X.Offset, 0, y)
        updateTrackerPosition()
    end
})

-- ===== ВКЛАДКА СЕРВЕР =====
ServerTab:CreateButton({
    Name = T("server_hop"),
    Callback = function()
        saveStateForTeleport()
        serverHop()
        Rayfield:Notify({Title = T("server_hop"), Content = T("notify_server_hop"), Duration = 3})
    end
})

autoRejoinToggle = ServerTab:CreateToggle({
    Name = T("auto_rejoin"),
    CurrentValue = true,
    Callback = function(value) autoReconnect = value end
})

ServerTab:CreateButton({
    Name = T("reconnect_now"),
    Callback = function()
        saveStateForTeleport()
        local jobId = game.JobId
        pcall(function()
            game:GetService("TeleportService"):TeleportToPlaceInstance(placeId, jobId, game.Players.LocalPlayer)
        end)
    end
})

-- ===== ВКЛАДКА КОНФИГ =====
ConfigTab:CreateButton({
    Name = T("config_save"),
    Callback = function() saveConfig() end
})

ConfigTab:CreateButton({
    Name = T("config_load"),
    Callback = function() loadConfig() end
})

ConfigTab:CreateButton({
    Name = T("config_delete"),
    Callback = function()
        if isfile(CONFIG_FILE) then
            delfile(CONFIG_FILE)
            Rayfield:Notify({Title = T("notify_saved"), Content = T("notify_config_deleted"), Duration = 3})
        else
            Rayfield:Notify({Title = T("notify_saved"), Content = T("notify_config_no_file"), Duration = 3})
        end
    end
})

-- ===== ВКЛАДКА НАСТРОЙКИ =====
antiAfkToggle = SettingsTab:CreateToggle({
    Name = T("anti_afk"),
    CurrentValue = false,
    Callback = function(value)
        if value then startAntiAfk() else stopAntiAfk() end
    end
})

SettingsTab:CreateDropdown({
    Name = T("language"),
    Options = {"Русский", "English"},
    CurrentOption = (currentLang == "ru") and "Русский" or "English",
    Callback = function(option)
        if option == "Русский" then
            currentLang = "ru"
        elseif option == "English" then
            currentLang = "en"
        end
        Rayfield:Notify({
            Title = T("language"),
            Content = (currentLang == "ru") and "Язык изменён. Перезапустите скрипт для полного применения." or "Language changed. Restart the script to apply fully.",
            Duration = 5
        })
    end
})

-- ===== ИНИЦИАЛИЗАЦИЯ =====
createTrackerGui()

if isfile(CONFIG_FILE) then
    loadConfig()
end

game.Players.LocalPlayer.CharacterAdded:Connect(function()
    task.wait(3)
    if autoReconnect and isFarming then
        startFarm()
    end
end)

Rayfield:Notify({
    Title = T("window_title"),
    Content = T("notify_loaded"),
    Duration = 5
})
