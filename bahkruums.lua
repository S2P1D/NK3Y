-- ============================================================
-- NK3Y Bahkruums + Door Farm + InstantPP
-- ============================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer

-- ============================================================
-- БЛОК КЛЮЧА
-- ============================================================
local userKey = getgenv().NK3Y_Key or (isfile("NK3Y_HUB_KEY.txt") and readfile("NK3Y_HUB_KEY.txt") or "Unknown")
local OWNER_HASH = 1574169149
local function djb2(str) local h = 5381 for i=1,#str do h=(h*33+string.byte(str,i))%4294967296 end return h end
local function fetchKeyInfo(key)
    if djb2(key) == OWNER_HASH then return "Бессрочный (Владелец)\nЛимит HWID: Безлимит" end
    local url = "https://pandadevelopment.net/v2_keyinfo?service=nk3yhub&hwid=" .. tostring(player.UserId) .. "&key=" .. key
    local success, response = pcall(function() return game:HttpGet(url, true) end)
    if not success or not response then return "Ошибка соединения." end
    local ok, data = pcall(function() return HttpService:JSONDecode(response) end)
    if not ok or not data or not data.Key_Information then return "Ошибка данных." end
    local info = data.Key_Information
    local exp = info.Days_Left and (info.Days_Left .. " дн.") or "Бессрочный"
    return string.format("Время: %s\nHWID: %s / %s", exp, info.HWID_Usage or "?", info.HWID_Limit or "?")
end

-- ============================================================
-- БУМБОКС
-- ============================================================
local Boombox = { sound = nil, volume = 0.5, loop = false }
local function tryPlayBoombox(idText)
    if not idText or idText == "" then return false, "Пустой ID" end
    local id = idText:gsub("%s+", "")
    if not id:find("rbxassetid://") then id = "rbxassetid://" .. (id:match("(%d+)") or id) end
    if not Boombox.sound then Boombox.sound = Instance.new("Sound", SoundService) end
    local s = Boombox.sound
    s:Stop(); s.SoundId = id; s.Volume = Boombox.volume; s.Looped = Boombox.loop
    pcall(function() game:GetService("ContentProvider"):PreloadAsync({s}) end)
    local waited = 0
    while waited < 3 and not (s.IsLoaded and s.TimeLength > 0) do task.wait(0.1); waited = waited + 0.1 end
    if s.IsLoaded and s.TimeLength > 0 then s:Play(); return true, "успешно!" else s:Stop(); s.SoundId = ""; return false, "заблокирован/удалён" end
end

-- ============================================================
-- ЛОКАЛИЗАЦИЯ
-- ============================================================
local Locales = {
    ru = {
        window_title = "NK3Y Bahkruums", loading_title = "Загрузка...", loading_subtitle = "by NK3Y",
        tab_main = "Основное", tab_visuals = "Визуал", tab_doors = "Двери", tab_boombox = "Бумбокс", tab_info = "Ключ / Инфо", tab_settings = "Настройки",
        auto_hotdog = "Авто-хил хот-догами", speed_hack = "Speed Hack", speed_value = "Скорость",
        auto_farm = "Автофарм (BHOP + деньги)", anti_afk = "Anti-AFK", nextbot_esp = "ESP некстботов",
        player_esp = "ESP игроков", item_esp = "ESP предметов", auto_tp = "Auto-TP к предметам",
        money_counter = "Счётчик денег", door_farm = "Автофарм дверей", door_delay = "Задержка у двери (сек)",
        notify_loaded = "Загружен. by NK3Y"
    }
}
local currentLang = "ru"
local function T(key) return (Locales[currentLang] or Locales.ru)[key] or key end

-- ============================================================
-- ПЕРЕМЕННЫЕ
-- ============================================================
local autoHotdogEnabled, speedEnabled, espEnabled = false, false, false
local moneyCounterEnabled, itemEspEnabled = false, false
local speedValue, defaultSpeed = 32, 16
local autoFarmEnabled = false
local doorFarmEnabled, doorFarmThread = false, nil
local doorDelay = 1.5
local instantPPApplied = false

-- ============================================================
-- INSTANT PP (МГНОВЕННОЕ ОТКРЫТИЕ ДВЕРЕЙ)
-- ============================================================
local function applyInstantPP()
    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            obj.HoldDuration = 0
            count = count + 1
        end
    end
    if count > 0 then
        Rayfield:Notify({Title = "InstantPP", Content = "Установлено для " .. count .. " дверей", Duration = 2})
    end
    instantPPApplied = true
end

local function maintainInstantPP()
    task.spawn(function()
        while doorFarmEnabled do
            task.wait(3)
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") and obj.HoldDuration > 0 then
                    obj.HoldDuration = 0
                end
            end
        end
    end)
end

-- ============================================================
-- ПОИСК ДВЕРЕЙ
-- ============================================================
local function findDoors()
    local doors = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local name = string.lower(obj.Name)
            if name:find("door") or name:find("gate") or name:find("дверь") then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    table.insert(doors, part)
                end
            else
                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt")
                if prompt then
                    local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                    if part then table.insert(doors, part) end
                end
            end
        end
    end
    return doors
end

local function getNearestDoor()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, nil end
    local doors = findDoors()
    local nearest, nearestDist = nil, math.huge
    for _, part in ipairs(doors) do
        if part and part.Parent then
            local dist = (part.Position - hrp.Position).Magnitude
            if dist < nearestDist then
                nearest = part
                nearestDist = dist
            end
        end
    end
    return nearest, nearestDist
end

-- ============================================================
-- АВТОФАРМ ДВЕРЕЙ
-- ============================================================
local function startDoorFarm()
    if doorFarmEnabled then return end
    doorFarmEnabled = true
    
    if not instantPPApplied then
        applyInstantPP()
        maintainInstantPP()
    end
    
    doorFarmThread = task.spawn(function()
        while doorFarmEnabled do
            local door, dist = getNearestDoor()
            if door then
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = CFrame.new(door.Position + Vector3.new(0, 3, 0))
                    task.wait(doorDelay)
                end
            end
            task.wait(0.5)
        end
    end)
end

local function stopDoorFarm()
    doorFarmEnabled = false
    if doorFarmThread then
        task.cancel(doorFarmThread)
        doorFarmThread = nil
    end
    instantPPApplied = false
end

-- ============================================================
-- СТАРЫЕ ФУНКЦИИ (ХОТДОГИ, СПИД, АВТОФАРМ, ESP)
-- ============================================================
local ShopRemote = game.ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("Shop")
local function getHumanoid() local c = player.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function findHotdog() local b = player:FindFirstChild("Backpack"); return (b and b:FindFirstChild("Hotdog")) or (player.Character and player.Character:FindFirstChild("Hotdog")) end
local function startAutoHotdog() if autoHotdogEnabled then return end autoHotdogEnabled = true task.spawn(function() while autoHotdogEnabled do local hum = getHumanoid() if hum and hum.Health > 0 and hum.Health < hum.MaxHealth then if not findHotdog() then pcall(function() ShopRemote:FireServer("Item", "Hotdog") end) end task.wait(0.5) local dog = findHotdog() if dog then if dog.Parent ~= player.Character then dog.Parent = player.Character; task.wait(0.5) end pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton1(Vector2.new(0,0)) end) task.wait(2) end end task.wait(0.5) end end) end
local function startSpeed() speedEnabled = true; task.spawn(function() while speedEnabled do pcall(function() local h = getHumanoid(); if h then h.WalkSpeed = speedValue end end); task.wait(0.1) end) end end
local function stopSpeed() speedEnabled = false; task.wait(0.2); local h = getHumanoid(); if h then h.WalkSpeed = defaultSpeed end end

local BhopRemote = game.ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("Player"):WaitForChild("Bhop")
local FARM_POS = Vector3.new(486.707275390625, 15.999999046325684, -233.35446166992188)
local function startAutoFarm()
    if autoFarmEnabled then return end
    autoFarmEnabled = true
    local hum = getHumanoid()
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not (hum and hrp) then return end
    hrp.CFrame = CFrame.new(FARM_POS)
    hum.WalkSpeed = 0
    task.spawn(function()
        while autoFarmEnabled do
            pcall(function()
                local h = getHumanoid()
                local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if h and r and BhopRemote then
                    h.WalkSpeed = 0
                    h:ChangeState(Enum.HumanoidStateType.Jumping)
                    BhopRemote:FireServer()
                    r.CFrame = CFrame.lookAt(Vector3.new(FARM_POS.X, r.Position.Y, FARM_POS.Z), Vector3.new(FARM_POS.X + 1, r.Position.Y, FARM_POS.Z))
                    r.AssemblyLinearVelocity = Vector3.new(85, 18, 0)
                end
            end)
            task.wait(0.1)
        end
    end)
end
local function stopAutoFarm() autoFarmEnabled = false; task.wait(0.2); local h = getHumanoid(); if h then h.WalkSpeed = defaultSpeed end end

local moneyGui, moneyLabel, moneyStart = nil, nil, 0
local function startMoneyCounter()
    if moneyCounterEnabled then return end
    moneyCounterEnabled = true
    if moneyGui then moneyGui:Destroy() end
    moneyGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
    local f = Instance.new("Frame", moneyGui)
    f.Size, f.Position = UDim2.new(0, 200, 0, 60), UDim2.new(0, 20, 0, 100)
    f.BackgroundColor3, f.BackgroundTransparency = Color3.new(0,0,0), 0.3
    f.Active, f.Draggable = true, true
    local s = Instance.new("UIStroke", f); s.Color = Color3.fromRGB(0, 255, 100)
    moneyLabel = Instance.new("TextLabel", f)
    moneyLabel.Size, moneyLabel.BackgroundTransparency = UDim2.new(1,0,1,0), 1
    moneyLabel.TextColor3, moneyLabel.Font, moneyLabel.TextScaled = Color3.fromRGB(0,255,100), Enum.Font.Code, true
    local ls = player:FindFirstChild("leaderstats")
    local bal = ls and ls:FindFirstChild("Buckarooms")
    if bal then
        moneyStart = bal.Value
        moneyLabel.Text = "+0 | $" .. math.floor(bal.Value)
        bal:GetPropertyChangedSignal("Value"):Connect(function()
            local diff = math.max(0, bal.Value - moneyStart)
            moneyLabel.Text = "+" .. math.floor(diff) .. " | $" .. math.floor(bal.Value)
        end)
    end
end
local function stopMoneyCounter() moneyCounterEnabled = false; if moneyGui then moneyGui:Destroy(); moneyGui = nil end end

local pColor, nColor = Color3.fromRGB(0, 255, 100), Color3.fromRGB(255, 50, 50)
local hlBag = {}
local function addHl(obj, col) if not obj or hlBag[obj] then return end local h = Instance.new("Highlight", obj); h.FillColor, h.OutlineColor = col, col; h.FillTransparency, h.DepthMode = 0.5, Enum.HighlightDepthMode.AlwaysOnTop; hlBag[obj] = h end
local function startEsp()
    if espEnabled then return end
    espEnabled = true
    task.spawn(function()
        while espEnabled do
            for _, p in ipairs(Players:GetPlayers()) do if p ~= player and p.Character then addHl(p.Character, pColor) end end
            local live = workspace:FindFirstChild("LiveAI")
            if live then for _, m in ipairs(live:GetChildren()) do if m:IsA("Model") then addHl(m, nColor) end end end
            task.wait(1)
        end
    end)
end
local function stopEsp() espEnabled = false; for o, h in pairs(hlBag) do h:Destroy() end; hlBag = {} end

local function startItemEsp()
    if itemEspEnabled then return end
    itemEspEnabled = true
    task.spawn(function()
        while itemEspEnabled do
            local sys = workspace:FindFirstChild("System")
            local sp = sys and sys:FindFirstChild("Spawners")
            if sp then
                for _, obj in ipairs(sp:GetDescendants()) do
                    if obj:IsA("BasePart") and obj.Name == "Item" and not obj:FindFirstChild("NK3Y_ItemBB") then
                        local bb = Instance.new("BillboardGui", obj)
                        bb.Name, bb.Size, bb.AlwaysOnTop = "NK3Y_ItemBB", UDim2.new(0,100,0,30), true
                        local t = Instance.new("TextLabel", bb)
                        t.Size, t.BackgroundTransparency = UDim2.new(1,0,1,0), 1
                        t.Text, t.TextColor3, t.TextScaled = obj.Parent.Name, Color3.fromRGB(255,255,0), true
                        t.Font = Enum.Font.Code
                    end
                end
            end
            task.wait(2)
        end
    end)
end
local function stopItemEsp() itemEspEnabled = false; for _, obj in ipairs(workspace:GetDescendants()) do if obj.Name == "NK3Y_ItemBB" then obj:Destroy() end end end

-- ============================================================
-- ОКНО
-- ============================================================
local Window = Rayfield:CreateWindow({
    Name = T("window_title"), LoadingTitle = T("loading_title"), LoadingSubtitle = T("loading_subtitle"),
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

local MainTab = Window:CreateTab(T("tab_main"), 4483362458)
local VisualsTab = Window:CreateTab(T("tab_visuals"), 4483362458)
local DoorsTab = Window:CreateTab(T("tab_doors"), 4483362458)
local BoomboxTab = Window:CreateTab(T("tab_boombox"), 4483362458)
local InfoTab = Window:CreateTab(T("tab_info"), 4483362458)
local SettingsTab = Window:CreateTab(T("tab_settings"), 4483362458)

-- ===== ВКЛАДКА ДВЕРИ =====
DoorsTab:CreateSection("Автофарм дверей")
DoorsTab:CreateToggle({Name = T("door_farm"), CurrentValue = false, Callback = function(v)
    if v then startDoorFarm() else stopDoorFarm() end
end})
DoorsTab:CreateSlider({Name = T("door_delay"), Range = {0.5, 5}, Increment = 0.5, CurrentValue = doorDelay, Callback = function(v) doorDelay = v end})
DoorsTab:CreateButton({Name = "Принудительно включить InstantPP", Callback = function()
    applyInstantPP()
end})

-- ===== БУМБОКС =====
local trackInput
BoomboxTab:CreateInput({Name = "ID трека", PlaceholderText = "rbxassetid://... или число", RemoveTextAfterFocusLost = false, Callback = function(t) trackInput = t end})
BoomboxTab:CreateButton({Name = "▶ Воспроизвести", Callback = function()
    if not trackInput then return end
    Rayfield:Notify({Title = "Бумбокс", Content = "Загрузка...", Duration = 2})
    task.spawn(function() local ok, msg = tryPlayBoombox(trackInput); Rayfield:Notify({Title = "Бумбокс", Content = (ok and "✓ " or "✗ ") .. msg, Duration = 4}) end)
end})
BoomboxTab:CreateButton({Name = "⏸ Пауза", Callback = function() if Boombox.sound then Boombox.sound:Pause() end end})
BoomboxTab:CreateButton({Name = "⏹ Стоп", Callback = function() if Boombox.sound then Boombox.sound:Stop() end end})
BoomboxTab:CreateSlider({Name = "Громкость", Range = {0, 100}, Increment = 5, CurrentValue = 50, Callback = function(v) Boombox.volume = v / 100; if Boombox.sound then Boombox.sound.Volume = Boombox.volume end end})
BoomboxTab:CreateToggle({Name = "Повтор (loop)", CurrentValue = false, Callback = function(v) Boombox.loop = v; if Boombox.sound then Boombox.sound.Looped = v end end})

-- ===== КЛЮЧ / ИНФО =====
InfoTab:CreateSection("Информация о ключе")
InfoTab:CreateButton({Name = "Твой ключ: " .. string.sub(tostring(userKey), 1, 8) .. "***", Callback = function() end})
InfoTab:CreateButton({Name = "Узнать время и HWID", Callback = function()
    Rayfield:Notify({Title = "Pandauth", Content = "Запрос данных...", Duration = 2})
    task.spawn(function()
        local info = fetchKeyInfo(userKey)
        for line in info:gmatch("[^\r\n]+") do Rayfield:Notify({Title = "Инфо", Content = line, Duration = 5}); task.wait(0.3) end
    end)
end})

-- ===== ОСНОВНОЕ =====
MainTab:CreateSection("Автоматизация")
MainTab:CreateToggle({Name = T("auto_farm"), CurrentValue = false, Callback = function(v) if v then startAutoFarm() else stopAutoFarm() end end})
MainTab:CreateToggle({Name = T("auto_hotdog"), CurrentValue = false, Callback = function(v) if v then startAutoHotdog() else autoHotdogEnabled = false end end})
MainTab:CreateToggle({Name = T("speed_hack"), CurrentValue = false, Callback = function(v) if v then startSpeed() else stopSpeed() end end})
MainTab:CreateSlider({Name = T("speed_value"), Range = {16, 300}, Increment = 1, CurrentValue = speedValue, Callback = function(v) speedValue = v end})
MainTab:CreateToggle({Name = T("money_counter"), CurrentValue = false, Callback = function(v) if v then startMoneyCounter() else stopMoneyCounter() end end})

-- ===== ВИЗУАЛ =====
VisualsTab:CreateSection("ESP")
VisualsTab:CreateToggle({Name = T("player_esp"), CurrentValue = false, Callback = function(v) if v then startEsp() else stopEsp() end end})
VisualsTab:CreateToggle({Name = T("item_esp"), CurrentValue = false, Callback = function(v) if v then startItemEsp() else stopItemEsp() end end})

-- ===== НАСТРОЙКИ =====
SettingsTab:CreateSection("Разное")
SettingsTab:CreateToggle({Name = T("anti_afk"), CurrentValue = false, Callback = function(v)
    if v then player.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end) end
end})

Rayfield:Notify({Title = T("window_title"), Content = T("notify_loaded"), Duration = 5})
