-- ============================================================
-- NK3Y Bahkruums (Halloween Doors + Safe UI)
-- ============================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local userKey = getgenv().NK3Y_Key or "Unknown"

-- ============================================================
-- БЕЗОПАСНАЯ ЗАГРУЗКА РЕМОУТОВ
-- ============================================================
local ShopRemote, BhopRemote
task.spawn(function()
    pcall(function()
        ShopRemote = game.ReplicatedStorage:WaitForChild("Assets", 10):WaitForChild("Remotes", 10):WaitForChild("Shop", 10)
    end)
    pcall(function()
        BhopRemote = game.ReplicatedStorage:WaitForChild("Assets", 10):WaitForChild("Remotes", 10):WaitForChild("Player", 10):WaitForChild("Bhop", 10)
    end)
end)

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
    if s.IsLoaded and s.TimeLength > 0 then s:Play(); return true, "успешно!" else s:Stop(); s.SoundId = ""; return false, "заблокирован" end
end

-- ============================================================
-- ФУНКЦИИ АВТОФАРМА
-- ============================================================
local function getHumanoid() 
    local c = player.Character
    return c and c:FindFirstChildOfClass("Humanoid") 
end

-- АВТОФАРМ ДЕНЕГ (BHOP)
local FARM_POS = Vector3.new(486.707275390625, 15.999999046325684, -233.35446166992188)
local autoFarmEnabled = false
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
local function stopAutoFarm() 
    autoFarmEnabled = false
    task.wait(0.2)
    local h = getHumanoid()
    if h then h.WalkSpeed = 16 end 
end

-- АВТО-ХИЛ
local autoHotdogEnabled = false
local function startAutoHotdog()
    if autoHotdogEnabled then return end
    autoHotdogEnabled = true
    task.spawn(function()
        while autoHotdogEnabled do
            local hum = getHumanoid()
            if hum and hum.Health > 0 and hum.Health < hum.MaxHealth and ShopRemote then
                local b = player:FindFirstChild("Backpack")
                local dog = (b and b:FindFirstChild("Hotdog")) or (player.Character and player.Character:FindFirstChild("Hotdog"))
                if not dog then pcall(function() ShopRemote:FireServer("Item", "Hotdog") end) end
                task.wait(0.5)
                local dog2 = (b and b:FindFirstChild("Hotdog")) or (player.Character and player.Character:FindFirstChild("Hotdog"))
                if dog2 then
                    if dog2.Parent ~= player.Character then dog2.Parent = player.Character; task.wait(0.5) end
                    pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton1(Vector2.new(0,0)) end)
                    task.wait(2)
                end
            end
            task.wait(0.5)
        end
    end)
end

-- АВТОФАРМ ДВЕРЕЙ (HALLOWEEN DOOR)
local doorFarmEnabled = false
local doorDelay = 1.5
local ignoredDoors = {}
local function startDoorFarm()
    if doorFarmEnabled then return end
    doorFarmEnabled = true
    
    -- Врубаем Instant PP
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then obj.HoldDuration = 0 end
    end
    
    task.spawn(function()
        while doorFarmEnabled do
            local doors = {}
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and string.lower(obj.Name) == "halloween door" then
                    table.insert(doors, {model = obj, pos = obj:GetPivot().Position})
                end
            end
            
            -- Чистим игнор
            for model, time in pairs(ignoredDoors) do
                if tick() - time > 5 or not model.Parent then ignoredDoors[model] = nil end
            end

            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if #doors > 0 and hrp then
                local nearest, nearestDist = nil, math.huge
                for _, door in ipairs(doors) do
                    if not ignoredDoors[door.model] then
                        local dist = (door.pos - hrp.Position).Magnitude
                        if dist < nearestDist then nearest = door; nearestDist = dist end
                    end
                end
                
                -- Если все в игноре
                if not nearest then
                    for _, door in ipairs(doors) do
                        local dist = (door.pos - hrp.Position).Magnitude
                        if dist < nearestDist then nearest = door; nearestDist = dist end
                    end
                end

                if nearest then
                    hrp.CFrame = CFrame.new(nearest.pos + Vector3.new(0, 3, 0))
                    ignoredDoors[nearest.model] = tick()
                    task.wait(doorDelay)
                end
            end
            task.wait(0.2)
        end
    end)
end
local function stopDoorFarm() 
    doorFarmEnabled = false 
end

-- ============================================================
-- СОЗДАНИЕ ОКНА RAYFIELD
-- ============================================================
local Window = Rayfield:CreateWindow({
    Name = "NK3Y Bahkruums", LoadingTitle = "Загрузка...", LoadingSubtitle = "by NK3Y",
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

local MainTab = Window:CreateTab("Основное", 4483362458)
local DoorsTab = Window:CreateTab("Двери", 4483362458)
local BoomboxTab = Window:CreateTab("Бумбокс", 4483362458)
local InfoTab = Window:CreateTab("Инфо", 4483362458)

-- ===== ОСНОВНОЕ =====
MainTab:CreateSection("Автоматизация")
MainTab:CreateToggle({Name = "Автофарм (BHOP)", CurrentValue = false, Callback = function(v) if v then startAutoFarm() else stopAutoFarm() end end})
MainTab:CreateToggle({Name = "Авто-хил хот-догами", CurrentValue = false, Callback = function(v) if v then startAutoHotdog() else autoHotdogEnabled = false end end})

-- ===== ДВЕРИ =====
DoorsTab:CreateSection("Хэллоуинские двери")
DoorsTab:CreateToggle({Name = "Автофарм Halloween Door", CurrentValue = false, Callback = function(v) if v then startDoorFarm() else stopDoorFarm() end end})
DoorsTab:CreateSlider({Name = "Задержка у двери (сек)", Range = {0.5, 5}, Increment = 0.5, CurrentValue = doorDelay, Callback = function(v) doorDelay = v end})
DoorsTab:CreateButton({Name = "Врубить InstantPP (мгновенно)", Callback = function()
    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then 
            obj.HoldDuration = 0 
            count = count + 1
        end
    end
    Rayfield:Notify({Title = "InstantPP", Content = "Обработано кнопок: " .. count, Duration = 3})
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

-- ===== ИНФО =====
InfoTab:CreateSection("Информация")
InfoTab:CreateButton({Name = "Твой ключ: " .. string.sub(tostring(userKey), 1, 8) .. "***", Callback = function() end})

Rayfield:Notify({Title = "NK3Y Bahkruums", Content = "Загружен. by NK3Y", Duration = 5})
