-- ============================================================
-- AutoFarm + Counter Tracker + Config + queue_on_teleport
-- ============================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local HttpService = game:GetService("HttpService")

-- ===== СОСТОЯНИЕ =====
local placeId = 128662368175518
local isFarming = false
local farmThread = nil
local autoReconnect = true
local pointDelay = 5
local teleportPoints = {}
local currentPointIndex = 1

-- Counter Tracker
local trackerGui = nil
local seasonLabel = nil
local totalLabel = nil
local trackerVisible = true
local trackerTransparency = 0.5
local trackerPosition = UDim2.new(0, 10, 0, 10)

-- Anti-AFK
local antiAfkActive = false
local antiAfkThread = nil

-- Ссылки на тогглы (заполняются при создании меню)
local farmToggle, antiAfkToggle, autoRejoinToggle, trackerToggle, trackerTransparencySlider

local CONFIG_FILE = "DummyCounter_Config.json"

-- ===== ФУНКЦИИ ФАРМА =====
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
                if currentPointIndex > #teleportPoints then
                    currentPointIndex = 1
                end
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
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    frame.BackgroundTransparency = trackerTransparency
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = trackerGui

    local seasonTitle = Instance.new("TextLabel")
    seasonTitle.Size = UDim2.new(0.5, 0, 0.4, 0)
    seasonTitle.Position = UDim2.new(0, 5, 0, 5)
    seasonTitle.BackgroundTransparency = 1
    seasonTitle.Text = "Season:"
    seasonTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    seasonTitle.TextScaled = true
    seasonTitle.Font = Enum.Font.GothamBold
    seasonTitle.Parent = frame

    seasonLabel = Instance.new("TextLabel")
    seasonLabel.Size = UDim2.new(0.45, 0, 0.4, 0)
    seasonLabel.Position = UDim2.new(0.5, 0, 0, 5)
    seasonLabel.BackgroundTransparency = 1
    seasonLabel.Text = "0"
    seasonLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    seasonLabel.TextScaled = true
    seasonLabel.Font = Enum.Font.GothamBold
    seasonLabel.Parent = frame

    local totalTitle = Instance.new("TextLabel")
    totalTitle.Size = UDim2.new(0.5, 0, 0.4, 0)
    totalTitle.Position = UDim2.new(0, 5, 0.45, 0)
    totalTitle.BackgroundTransparency = 1
    totalTitle.Text = "Total:"
    totalTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    totalTitle.TextScaled = true
    totalTitle.Font = Enum.Font.GothamBold
    totalTitle.Parent = frame

    totalLabel = Instance.new("TextLabel")
    totalLabel.Size = UDim2.new(0.45, 0, 0.4, 0)
    totalLabel.Position = UDim2.new(0.5, 0, 0.45, 0)
    totalLabel.BackgroundTransparency = 1
    totalLabel.Text = "0"
    totalLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
    totalLabel.TextScaled = true
    totalLabel.Font = Enum.Font.GothamBold
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
        antiAfkActive = antiAfkActive
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
        Rayfield:Notify({Title = "Конфиг", Content = "Сохранён", Duration = 3})
    else
        Rayfield:Notify({Title = "Ошибка", Content = "Не удалось сохранить: " .. tostring(err), Duration = 5})
    end
end

local function loadConfig()
    if not isfile(CONFIG_FILE) then
        Rayfield:Notify({Title = "Конфиг", Content = "Файл не найден", Duration = 3})
        return
    end
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)
    if not success or not data then
        Rayfield:Notify({Title = "Ошибка", Content = "Не удалось загрузить конфиг", Duration = 5})
        return
    end

    -- Точки
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

    -- Настройки
    pointDelay = data.pointDelay or 5
    autoReconnect = data.autoReconnect ~= false
    trackerVisible = data.trackerVisible ~= false
    trackerTransparency = data.trackerTransparency or 0.5
    if data.trackerPosition then
        trackerPosition = UDim2.new(0, data.trackerPosition.x or 10, 0, data.trackerPosition.y or 10)
    end

    -- Фарм
    local shouldFarm = data.isFarming == true
    isFarming = false
    if farmToggle then farmToggle:Set(shouldFarm) end
    if shouldFarm then
        startFarm()
    else
        stopFarm()
    end

    -- Anti-AFK
    local shouldAntiAfk = data.antiAfkActive == true
    if antiAfkToggle then antiAfkToggle:Set(shouldAntiAfk) end
    if shouldAntiAfk then startAntiAfk() else stopAntiAfk() end

    -- Auto Rejoin
    if autoRejoinToggle then autoRejoinToggle:Set(autoReconnect) end

    -- Трекер
    if trackerToggle then trackerToggle:Set(trackerVisible) end
    if trackerTransparencySlider then trackerTransparencySlider:Set(trackerTransparency) end
    if trackerGui then
        updateTrackerVisibility()
        updateTrackerTransparency()
        updateTrackerPosition()
    end

    Rayfield:Notify({Title = "Конфиг", Content = "Загружен (" .. #teleportPoints .. " точек)", Duration = 3})
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
    Name = "AutoFarm by NK3Y",
    LoadingTitle = "Загрузка...",
    LoadingSubtitle = "#grrrrmonday",
    Theme = "Amethyst",
    ConfigurationSaving = { Enabled = false }
})

local MainTab = Window:CreateTab("Фарм", 4483362458)
local PointsTab = Window:CreateTab("Точки", nil)
local TrackerTab = Window:CreateTab("Счётчики", nil)
local ServerTab = Window:CreateTab("Сервер", nil)
local ConfigTab = Window:CreateTab("Конфиг", nil)
local SettingsTab = Window:CreateTab("Настройки", nil)

-- ===== ВКЛАДКА ФАРМ =====
farmToggle = MainTab:CreateToggle({
    Name = "Включить автофарм (по точкам)",
    CurrentValue = false,
    Callback = function(value)
        if value then startFarm() else stopFarm() end
    end
})

MainTab:CreateSlider({
    Name = "Время на точке (сек)",
    Range = {1, 30},
    Increment = 1,
    CurrentValue = pointDelay,
    Callback = function(value) pointDelay = value end
})

-- ===== ВКЛАДКА ТОЧКИ =====
PointsTab:CreateButton({
    Name = "Сохранить текущую позицию",
    Callback = function()
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local cf = char.HumanoidRootPart.CFrame
            table.insert(teleportPoints, {CFrame = cf, Name = "Точка " .. (#teleportPoints + 1)})
            Rayfield:Notify({Title = "Сохранено", Content = "Точка " .. #teleportPoints .. " добавлена", Duration = 3})
        end
    end
})

PointsTab:CreateButton({
    Name = "Очистить все точки",
    Callback = function()
        teleportPoints = {}
        currentPointIndex = 1
        Rayfield:Notify({Title = "Очищено", Content = "Все точки удалены", Duration = 3})
    end
})

-- ===== ВКЛАДКА СЧЁТЧИКИ =====
trackerToggle = TrackerTab:CreateToggle({
    Name = "Показать счётчики",
    CurrentValue = true,
    Callback = function(value)
        trackerVisible = value
        updateTrackerVisibility()
    end
})

trackerTransparencySlider = TrackerTab:CreateSlider({
    Name = "Прозрачность",
    Range = {0, 1},
    Increment = 0.1,
    CurrentValue = trackerTransparency,
    Callback = function(value)
        trackerTransparency = value
        updateTrackerTransparency()
    end
})

TrackerTab:CreateInput({
    Name = "Позиция X",
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
    Name = "Позиция Y",
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
    Name = "Server Hop (случайный)",
    Callback = function()
        saveStateForTeleport()
        serverHop()
        Rayfield:Notify({Title = "Server Hop", Content = "Поиск сервера...", Duration = 3})
    end
})

autoRejoinToggle = ServerTab:CreateToggle({
    Name = "Auto Rejoin (при смерти)",
    CurrentValue = true,
    Callback = function(value) autoReconnect = value end
})

ServerTab:CreateButton({
    Name = "Реконнект сейчас",
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
    Name = "Сохранить конфиг",
    Callback = function() saveConfig() end
})

ConfigTab:CreateButton({
    Name = "Загрузить конфиг",
    Callback = function() loadConfig() end
})

ConfigTab:CreateButton({
    Name = "Удалить конфиг",
    Callback = function()
        if isfile(CONFIG_FILE) then
            delfile(CONFIG_FILE)
            Rayfield:Notify({Title = "Конфиг", Content = "Файл удалён", Duration = 3})
        else
            Rayfield:Notify({Title = "Конфиг", Content = "Файла нет", Duration = 3})
        end
    end
})

-- ===== ВКЛАДКА НАСТРОЙКИ =====
antiAfkToggle = SettingsTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = false,
    Callback = function(value)
        if value then startAntiAfk() else stopAntiAfk() end
    end
})

-- ===== ИНИЦИАЛИЗАЦИЯ =====
createTrackerGui()

-- Автозагрузка конфига — ПОСЛЕ создания всех тогглов
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
    Title = "Скрипт загружен",
    Content = "Counter Tracker + Config активен",
    Duration = 5
})
