-- ============================================================
-- NK3Y Bahkruums
-- ============================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer

-- ===== ЛОКАЛИЗАЦИЯ =====
local Locales = {
    ru = {
        window_title = "NK3Y Bahkruums",
        loading_title = "Загрузка...",
        loading_subtitle = "by NK3Y",
        tab_main = "Основное",
        tab_visuals = "Визуал",
        tab_settings = "Настройки",
        auto_hotdog = "Авто-хил хот-догами",
        speed_hack = "Speed Hack",
        speed_value = "Скорость",
        auto_farm = "Автофарм (BHOP + деньги)",
        anti_afk = "Anti-AFK",
        nextbot_esp = "ESP некстботов",
        player_esp = "ESP игроков",
        item_esp = "ESP предметов",
        auto_tp = "Auto-TP к предметам",
        tp_nearest = "TP к ближайшему предмету",
        money_counter = "Счётчик денег",
        language = "Язык",
        notify_hotdog_on = "Авто-хил включён",
        notify_hotdog_off = "Авто-хил выключен",
        notify_farm_on = "Автофарм включён",
        notify_farm_off = "Автофарм выключен",
        notify_esp_on = "ESP включён",
        notify_esp_off = "ESP выключен",
        notify_item_on = "Item ESP включён",
        notify_item_off = "Item ESP выключен",
        notify_autotp_on = "Auto-TP включён",
        notify_autotp_off = "Auto-TP выключен",
        notify_money_on = "Счётчик денег включён",
        notify_money_off = "Счётчик денег выключен",
        notify_loaded = "Загружен. by NK3Y"
    },
    en = {
        window_title = "NK3Y Bahkruums",
        loading_title = "Loading...",
        loading_subtitle = "by NK3Y",
        tab_main = "Main",
        tab_visuals = "Visuals",
        tab_settings = "Settings",
        auto_hotdog = "Auto-heal with hotdogs",
        speed_hack = "Speed Hack",
        speed_value = "Speed",
        auto_farm = "Auto-farm (BHOP + money)",
        anti_afk = "Anti-AFK",
        nextbot_esp = "Nextbot ESP",
        player_esp = "Player ESP",
        item_esp = "Item ESP",
        auto_tp = "Auto-TP to items",
        tp_nearest = "TP to nearest item",
        money_counter = "Money counter",
        language = "Language",
        notify_hotdog_on = "Auto-heal enabled",
        notify_hotdog_off = "Auto-heal disabled",
        notify_farm_on = "Auto-farm enabled",
        notify_farm_off = "Auto-farm disabled",
        notify_esp_on = "ESP enabled",
        notify_esp_off = "ESP disabled",
        notify_item_on = "Item ESP enabled",
        notify_item_off = "Item ESP disabled",
        notify_autotp_on = "Auto-TP enabled",
        notify_autotp_off = "Auto-TP disabled",
        notify_money_on = "Money counter enabled",
        notify_money_off = "Money counter disabled",
        notify_loaded = "Loaded. by NK3Y"
    }
}

local currentLang = "ru"
local function T(key)
    local loc = Locales[currentLang] or Locales.ru
    return loc[key] or key
end

-- ===== СОСТОЯНИЕ =====
local autoHotdogEnabled = false
local autoHotdogThread = nil
local speedEnabled = false
local speedValue = 32
local defaultSpeed = 16
local espEnabled = false
local antiAfkActive = false
local moneyCounterEnabled = false
local moneyCounterGui = nil
local moneyStartBalance = 0
local moneyCurrentBalance = 0

-- ===== АВТО-ХИЛ ХОТ-ДОГАМИ =====
local ShopRemote = game.ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("Shop")
local BUY_WAIT = 0.5
local EQUIP_DELAY = 0.5
local EAT_WAIT = 2

local function getHumanoid()
    local char = player.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function findHotdog()
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        local tool = backpack:FindFirstChild("Hotdog")
        if tool then return tool end
    end
    local char = player.Character
    if char then
        local tool = char:FindFirstChild("Hotdog")
        if tool then return tool end
    end
    return nil
end

local function buyHotdog()
    pcall(function()
        ShopRemote:FireServer("Item", "Hotdog")
    end)
    task.wait(BUY_WAIT)
end

local function eatHotdog()
    local tool = findHotdog()
    if not tool then return false end

    if tool.Parent ~= player.Character then
        pcall(function()
            tool.Parent = player.Character
        end)
        task.wait(EQUIP_DELAY)
    end

    local equipped = player.Character and player.Character:FindFirstChild("Hotdog")
    if equipped then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.new(0, 0))
        end)
        return true
    end
    return false
end

local function startAutoHotdog()
    if autoHotdogEnabled then return end
    autoHotdogEnabled = true
    autoHotdogThread = task.spawn(function()
        while autoHotdogEnabled do
            local humanoid = getHumanoid()
            if humanoid and humanoid.Health > 0 and humanoid.Health < humanoid.MaxHealth then
                if not findHotdog() then
                    buyHotdog()
                end
                if findHotdog() then
                    eatHotdog()
                    task.wait(EAT_WAIT)
                end
            end
            task.wait(0.5)
        end
    end)
end

local function stopAutoHotdog()
    autoHotdogEnabled = false
    if autoHotdogThread then
        task.cancel(autoHotdogThread)
        autoHotdogThread = nil
    end
end

-- ===== SPEED HACK =====
local function setSpeed(value)
    local humanoid = getHumanoid()
    if humanoid then
        humanoid.WalkSpeed = value
    end
end

local function startSpeed()
    if speedEnabled then return end
    speedEnabled = true
    task.spawn(function()
        while speedEnabled do
            setSpeed(speedValue)
            task.wait(0.1)
        end
    end)
end

local function stopSpeed()
    speedEnabled = false
    task.wait(0.2)
    setSpeed(defaultSpeed)
end

-- ===== AUTO BHOP / FARM =====
local BhopRemote = game.ReplicatedStorage:WaitForChild("Assets")
    :WaitForChild("Remotes"):WaitForChild("Player"):WaitForChild("Bhop")

local FARM_POSITION = Vector3.new(486.707275390625, 15.999999046325684, -233.35446166992188)

local FARM_SPEED = 85
local HOP_POWER = 18
local FALL_VEL = -280
local FARM_DIR = Vector3.new(1, 0, 0)
local SPAM_BHOP = true
local SPAM_INTERVAL = 0.05

local autoFarmEnabled = false
local farmX, farmZ = nil, nil
local savedWalkSpeed = 16
local savedJumpPower = 50
local savedUseJumpPower = true
local savedAutoRotate = true
local spamThread = nil

local function disableLocalJumpScripts(character)
    for _, d in ipairs(character:GetDescendants()) do
        if d:IsA("LocalScript") then
            local n = string.lower(d.Name)
            if n:find("jump") or n:find("bhop") then
                d.Disabled = true
            end
        elseif d:IsA("BodyVelocity") and (d.Name == "movementForce" or d.Name == "GMODSETUP") then
            d.MaxForce = Vector3.new()
            d.Velocity = Vector3.new()
        end
    end
end

local function onFloor(hum, hrp, char)
    if hum.FloorMaterial ~= Enum.Material.Air then return true end
    local st = hum:GetState()
    if st == Enum.HumanoidStateType.Running
       or st == Enum.HumanoidStateType.Landed
       or st == Enum.HumanoidStateType.Climbing then
        return true
    end
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = {char}
    local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -3.8, 0), rp)
    return hit ~= nil and hit.Normal.Y > 0.55
end

local function startAutoFarm()
    if autoFarmEnabled then return end

    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not (hum and hrp) then
        warn("Нет персонажа/HumanoidRootPart")
        return
    end

    farmX = FARM_POSITION.X
    farmZ = FARM_POSITION.Z

    hrp.CFrame = CFrame.new(FARM_POSITION)
    hrp.AssemblyLinearVelocity = Vector3.new()
    hrp.AssemblyAngularVelocity = Vector3.new()

    savedWalkSpeed = hum.WalkSpeed
    savedJumpPower = hum.JumpPower or 50
    savedUseJumpPower = hum.UseJumpPower
    savedAutoRotate = hum.AutoRotate

    disableLocalJumpScripts(char)

    hum.WalkSpeed = 0
    hum.AutoRotate = false
    hum.PlatformStand = false
    pcall(function()
        hum.Sit = false
        hum.UseJumpPower = true
        hum.JumpPower = 50
    end)

    autoFarmEnabled = true

    if SPAM_BHOP then
        spamThread = task.spawn(function()
            while autoFarmEnabled do
                pcall(function()
                    BhopRemote:FireServer()
                end)
                task.wait(SPAM_INTERVAL)
            end
        end)
    end

    RunService.Heartbeat:Connect(function()
        if not autoFarmEnabled then return end
        local ch = player.Character
        if not ch then return end
        local h = ch:FindFirstChildOfClass("Humanoid")
        local r = ch:FindFirstChild("HumanoidRootPart")
        if not (h and r) then return end

        h.WalkSpeed = 0
        h.AutoRotate = false
        h.PlatformStand = false
        pcall(function()
            h.Sit = false
            h:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
            h:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        end)

        local function upright(y)
            local p = Vector3.new(farmX, y, farmZ)
            local f = Vector3.new(FARM_DIR.X, 0, FARM_DIR.Z)
            if f.Magnitude < 0.05 then f = Vector3.new(0, 0, -1) else f = f.Unit end
            return CFrame.lookAt(p, p + f, Vector3.yAxis)
        end

        if r.Position.Y < -50 then
            r.CFrame = upright(FARM_POSITION.Y)
            r.AssemblyLinearVelocity = Vector3.new()
            r.AssemblyAngularVelocity = Vector3.new()
            return
        end

        local grounded = onFloor(h, r, ch)
        local y = r.AssemblyLinearVelocity.Y

        h.Jump = true
        pcall(function()
            h.UseJumpPower = true
            h.JumpPower = 50
        end)

        if grounded then
            pcall(function()
                h:ChangeState(Enum.HumanoidStateType.Jumping)
            end)
            pcall(function()
                BhopRemote:FireServer()
                task.wait(0.02)
                BhopRemote:FireServer()
            end)

            local mxh = math.sqrt(math.max(0, 95*95 - HOP_POWER*HOP_POWER))
            local spd = math.min(FARM_SPEED, mxh)

            r.AssemblyAngularVelocity = Vector3.new()
            r.CFrame = upright(r.Position.Y)
            r.AssemblyLinearVelocity = Vector3.new(
                FARM_DIR.X * spd,
                HOP_POWER,
                FARM_DIR.Z * spd
            )
            return
        end

        if y < 18 then
            y = FALL_VEL
        end
        r.AssemblyAngularVelocity = Vector3.new()
        r.CFrame = upright(r.Position.Y)
        r.AssemblyLinearVelocity = Vector3.new(
            FARM_DIR.X * FARM_SPEED,
            y,
            FARM_DIR.Z * FARM_SPEED
        )
    end)
end

local function stopAutoFarm()
    autoFarmEnabled = false
    if spamThread then
        task.cancel(spamThread)
        spamThread = nil
    end
    task.wait(0.2)
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = savedWalkSpeed
        hum.AutoRotate = savedAutoRotate
        pcall(function()
            hum.UseJumpPower = savedUseJumpPower
            hum.JumpPower = savedJumpPower
        end)
    end
    farmX, farmZ = nil, nil
end

-- ===== MONEY COUNTER =====
local function createMoneyCounter()
    if moneyCounterGui then return end

    moneyCounterGui = Instance.new("ScreenGui")
    moneyCounterGui.Name = "NK3Y_MoneyCounter"
    moneyCounterGui.ResetOnSpawn = false
    moneyCounterGui.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 220, 0, 80)
    frame.Position = UDim2.new(0, 20, 0, 100)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = moneyCounterGui

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 255, 100)
    stroke.Thickness = 1
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.3, 0)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "NK3Y Money"
    title.TextColor3 = Color3.fromRGB(0, 255, 100)
    title.TextScaled = true
    title.Font = Enum.Font.Code
    title.Parent = frame

    local sessionLabel = Instance.new("TextLabel")
    sessionLabel.Size = UDim2.new(1, 0, 0.3, 0)
    sessionLabel.Position = UDim2.new(0, 0, 0.3, 0)
    sessionLabel.BackgroundTransparency = 1
    sessionLabel.Text = "+0"
    sessionLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    sessionLabel.TextScaled = true
    sessionLabel.Font = Enum.Font.Code
    sessionLabel.Name = "SessionLabel"
    sessionLabel.Parent = frame

    local totalLabel = Instance.new("TextLabel")
    totalLabel.Size = UDim2.new(1, 0, 0.3, 0)
    totalLabel.Position = UDim2.new(0, 0, 0.6, 0)
    totalLabel.BackgroundTransparency = 1
    totalLabel.Text = "$0"
    totalLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    totalLabel.TextScaled = true
    totalLabel.Font = Enum.Font.Code
    totalLabel.Name = "TotalLabel"
    totalLabel.Parent = frame

    local ls = player:WaitForChild("leaderstats", 10)
    if ls then
        local bal = ls:WaitForChild("Buckarooms", 10)
        if bal then
            moneyCurrentBalance = bal.Value
            moneyStartBalance = bal.Value
            totalLabel.Text = "$" .. tostring(math.floor(bal.Value))

            bal:GetPropertyChangedSignal("Value"):Connect(function()
                moneyCurrentBalance = bal.Value
                local delta = math.max(0, moneyCurrentBalance - moneyStartBalance)
                sessionLabel.Text = "+" .. tostring(math.floor(delta))
                totalLabel.Text = "$" .. tostring(math.floor(moneyCurrentBalance))
            end)
        end
    end
end

local function removeMoneyCounter()
    if moneyCounterGui then
        moneyCounterGui:Destroy()
        moneyCounterGui = nil
    end
end

local function startMoneyCounter()
    if moneyCounterEnabled then return end
    moneyCounterEnabled = true
    createMoneyCounter()
end

local function stopMoneyCounter()
    moneyCounterEnabled = false
    removeMoneyCounter()
end

-- ===== ESP (игроки/некстботы) =====
local espAddConns = {}
local nextbotHighlights = {}
local playerHighlights = {}

local PLAYER_ESP_COLOR = Color3.fromRGB(0, 255, 100)
local NEXTBOT_ESP_COLOR = Color3.fromRGB(255, 50, 50)

local function isNextbot(obj)
    if not obj:IsA("Model") then return false end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character == obj then return false end
    end
    if obj.Parent and obj.Parent.Name == "LiveAI" then return true end
    local hasAiTag = false
    pcall(function()
        for _, tag in ipairs(obj:GetTags()) do
            if string.lower(tag) == "ai" then
                hasAiTag = true
                break
            end
        end
    end)
    return hasAiTag
end

local function addNextbotHighlight(model)
    if not model or nextbotHighlights[model] then return end
    if model:FindFirstChild("NK3Y_ESP_HL") then return end
    local hl = Instance.new("Highlight")
    hl.Name = "NK3Y_ESP_HL"
    hl.FillColor = NEXTBOT_ESP_COLOR
    hl.OutlineColor = NEXTBOT_ESP_COLOR
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = model
    nextbotHighlights[model] = hl
end

local function addPlayerHighlight(character)
    if not character or playerHighlights[character] then return end
    if character:FindFirstChild("NK3Y_ESP_HL") then return end
    local hl = Instance.new("Highlight")
    hl.Name = "NK3Y_ESP_HL"
    hl.FillColor = PLAYER_ESP_COLOR
    hl.OutlineColor = PLAYER_ESP_COLOR
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = character
    playerHighlights[character] = hl
end

local function removeAllEsp()
    for model, hl in pairs(nextbotHighlights) do
        if hl and hl.Parent then hl:Destroy() end
    end
    nextbotHighlights = {}
    for char, hl in pairs(playerHighlights) do
        if hl and hl.Parent then hl:Destroy() end
    end
    playerHighlights = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Highlight") and obj.Name == "NK3Y_ESP_HL" then
            obj:Destroy()
        end
    end
end

local function watchLiveAI(container)
    for _, obj in ipairs(container:GetChildren()) do
        if obj:IsA("Model") and isNextbot(obj) then
            addNextbotHighlight(obj)
        end
    end
    local c1 = container.ChildAdded:Connect(function(obj)
        if not espEnabled then return end
        if obj:IsA("Model") and isNextbot(obj) then
            addNextbotHighlight(obj)
        end
    end)
    local c2 = container.ChildRemoved:Connect(function(obj)
        if nextbotHighlights[obj] then
            pcall(function() nextbotHighlights[obj]:Destroy() end)
            nextbotHighlights[obj] = nil
        end
    end)
    table.insert(espAddConns, c1)
    table.insert(espAddConns, c2)
end

local function watchPlayer(p)
    if p == player then return end
    if p.Character then
        addPlayerHighlight(p.Character)
    end
    local c = p.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if espEnabled then
            addPlayerHighlight(char)
        end
    end)
    table.insert(espAddConns, c)
end

local function startEsp()
    if espEnabled then return end
    espEnabled = true

    local liveAI = workspace:FindFirstChild("LiveAI")
    if liveAI then
        watchLiveAI(liveAI)
    else
        local wsConn
        wsConn = workspace.ChildAdded:Connect(function(obj)
            if obj.Name == "LiveAI" then
                watchLiveAI(obj)
                if wsConn then wsConn:Disconnect() end
            end
        end)
        table.insert(espAddConns, wsConn)
    end

    for _, p in ipairs(Players:GetPlayers()) do
        watchPlayer(p)
    end
    local pc = Players.PlayerAdded:Connect(function(p)
        if espEnabled then
            watchPlayer(p)
        end
    end)
    table.insert(espAddConns, pc)
end

local function stopEsp()
    espEnabled = false
    for _, conn in ipairs(espAddConns) do
        pcall(function() conn:Disconnect() end)
    end
    espAddConns = {}
    removeAllEsp()
end

-- ===== ITEM ESP + AUTO-TP =====
local ITEM_COLOR = Color3.fromRGB(255, 255, 0)
local CASH_COLOR = Color3.fromRGB(0, 255, 100)
local ITEM_MAX_DISTANCE = 1500

local itemEspEnabled = false
local itemBillboards = {}
local itemScanThread = nil

local autoTpEnabled = false
local autoTpThread = nil
local AUTO_TP_INTERVAL = 0.3
local AUTO_TP_COOLDOWN = 0.5

local function createItemBillboard(part, label_text, color)
    if itemBillboards[part] then return end
    if part:FindFirstChild("NK3Y_ItemBB") then
        itemBillboards[part] = part:FindFirstChild("NK3Y_ItemBB")
        return
    end

    local bb = Instance.new("BillboardGui")
    bb.Name = "NK3Y_ItemBB"
    bb.Adornee = part
    bb.AlwaysOnTop = true
    bb.Size = UDim2.fromOffset(160, 28)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.MaxDistance = ITEM_MAX_DISTANCE
    bb.Parent = part

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 0.3
    label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    label.TextColor3 = color
    label.Font = Enum.Font.Code
    label.TextScaled = true
    label.Text = label_text
    label.Parent = bb

    local hl = Instance.new("Highlight")
    hl.Name = "NK3Y_ItemHL"
    hl.FillColor = color
    hl.OutlineColor = color
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = part

    itemBillboards[part] = bb
end

local function isSpawnerItem(part)
    if not part:IsA("BasePart") then return false end
    if part.Name ~= "Item" then return false end
    local full = part:GetFullName()
    if full:find("Spawners") then return true end
    return false
end

local function getItemLabel(part)
    local parent = part.Parent
    if not parent then return "Item" end
    return parent.Name
end

local function scanItems()
    for part, bb in pairs(itemBillboards) do
        if not part.Parent then
            if bb then bb:Destroy() end
            local hl = part:FindFirstChild("NK3Y_ItemHL")
            if hl then hl:Destroy() end
            itemBillboards[part] = nil
        end
    end

    local sys = workspace:FindFirstChild("System")
    local spawners = sys and sys:FindFirstChild("Spawners")
    if spawners then
        for _, item in ipairs(spawners:GetDescendants()) do
            if isSpawnerItem(item) then
                createItemBillboard(item, getItemLabel(item), ITEM_COLOR)
            end
        end
    end

    local map = sys and sys:FindFirstChild("Map")
    if map then
        for _, obj in ipairs(map:GetDescendants()) do
            if obj:IsA("BasePart") then
                local n = string.lower(obj.Name)
                if n:find("cashregister") then
                    createItemBillboard(obj, "CASH", CASH_COLOR)
                end
            end
        end
    end
end

local function startItemEsp()
    if itemEspEnabled then return end
    itemEspEnabled = true
    scanItems()

    itemScanThread = task.spawn(function()
        while itemEspEnabled do
            task.wait(2)
            if itemEspEnabled then
                pcall(scanItems)
            end
        end
    end)
end

local function stopItemEsp()
    itemEspEnabled = false
    if itemScanThread then
        task.cancel(itemScanThread)
        itemScanThread = nil
    end
    for part, bb in pairs(itemBillboards) do
        if bb then bb:Destroy() end
        local hl = part:FindFirstChild("NK3Y_ItemHL")
        if hl then hl:Destroy() end
    end
    itemBillboards = {}
end

local function getNearestItem(onlySpawner)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, nil, nil end
    local myPos = hrp.Position
    local nearest, nearestDist = nil, math.huge
    for part in pairs(itemBillboards) do
        if part.Parent then
            local isSpawner = part.Name == "Item" and part:GetFullName():find("Spawners")
            if not onlySpawner or isSpawner then
                local d = (part.Position - myPos).Magnitude
                if d < nearestDist then
                    nearest = part
                    nearestDist = d
                end
            end
        end
    end
    return nearest, nearestDist, hrp
end

local function teleportToNearestItem()
    local nearest, nearestDist, hrp = getNearestItem(false)
    if not hrp then return end
    if nearest then
        hrp.CFrame = CFrame.new(nearest.Position + Vector3.new(0, 3, 0))
        Rayfield:Notify({Title = "TP", Content = nearest.Name .. " (" .. math.floor(nearestDist) .. "m)", Duration = 2})
    else
        Rayfield:Notify({Title = "TP", Content = "Нет предметов", Duration = 2})
    end
end

local function startAutoTp()
    if autoTpEnabled then return end
    autoTpEnabled = true

    autoTpThread = task.spawn(function()
        while autoTpEnabled do
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local nearest, dist = getNearestItem(true)
                if nearest then
                    hrp.CFrame = CFrame.new(nearest.Position + Vector3.new(0, 2, 0))
                    task.wait(AUTO_TP_COOLDOWN)
                else
                    task.wait(0.5)
                end
            else
                task.wait(0.5)
            end
            task.wait(AUTO_TP_INTERVAL)
        end
    end)
end

local function stopAutoTp()
    autoTpEnabled = false
    if autoTpThread then
        task.cancel(autoTpThread)
        autoTpThread = nil
    end
end

-- ===== ANTI-AFK =====
local function startAntiAfk()
    if antiAfkActive then return end
    antiAfkActive = true
    player.Idled:Connect(function()
        if antiAfkActive then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)
end

local function stopAntiAfk()
    antiAfkActive = false
end

-- ===== WINDOW =====
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

local MainTab = Window:CreateTab(T("tab_main"), 4483362458)
local VisualsTab = Window:CreateTab(T("tab_visuals"), nil)
local SettingsTab = Window:CreateTab(T("tab_settings"), nil)

-- ===== ОСНОВНОЕ =====
MainTab:CreateToggle({
    Name = T("auto_farm"),
    CurrentValue = false,
    Callback = function(value)
        if value then
            startAutoFarm()
            startMoneyCounter()
            Rayfield:Notify({Title = T("auto_farm"), Content = T("notify_farm_on"), Duration = 3})
        else
            stopAutoFarm()
            Rayfield:Notify({Title = T("auto_farm"), Content = T("notify_farm_off"), Duration = 3})
        end
    end
})

MainTab:CreateSlider({
    Name = T("speed_value"),
    Range = {16, 300},
    Increment = 1,
    CurrentValue = speedValue,
    Callback = function(value)
        speedValue = value
    end
})

MainTab:CreateToggle({
    Name = T("auto_hotdog"),
    CurrentValue = false,
    Callback = function(value)
        if value then
            startAutoHotdog()
            Rayfield:Notify({Title = T("auto_hotdog"), Content = T("notify_hotdog_on"), Duration = 3})
        else
            stopAutoHotdog()
            Rayfield:Notify({Title = T("auto_hotdog"), Content = T("notify_hotdog_off"), Duration = 3})
        end
    end
})

-- ===== ВИЗУАЛ =====
VisualsTab:CreateToggle({
    Name = T("nextbot_esp"),
    CurrentValue = false,
    Callback = function(value)
        if value then
            startEsp()
            Rayfield:Notify({Title = T("nextbot_esp"), Content = T("notify_esp_on"), Duration = 3})
        else
            stopEsp()
            Rayfield:Notify({Title = T("nextbot_esp"), Content = T("notify_esp_off"), Duration = 3})
        end
    end
})

VisualsTab:CreateToggle({
    Name = T("player_esp"),
    CurrentValue = false,
    Callback = function(value)
        if value then
            startEsp()
        else
            stopEsp()
        end
    end
})

VisualsTab:CreateToggle({
    Name = T("item_esp"),
    CurrentValue = false,
    Callback = function(value)
        if value then
            startItemEsp()
            Rayfield:Notify({Title = T("item_esp"), Content = T("notify_item_on"), Duration = 3})
        else
            stopItemEsp()
            Rayfield:Notify({Title = T("item_esp"), Content = T("notify_item_off"), Duration = 3})
        end
    end
})

VisualsTab:CreateToggle({
    Name = T("auto_tp"),
    CurrentValue = false,
    Callback = function(value)
        if value then
            if not itemEspEnabled then startItemEsp() end
            startAutoTp()
            Rayfield:Notify({Title = T("auto_tp"), Content = T("notify_autotp_on"), Duration = 3})
        else
            stopAutoTp()
            Rayfield:Notify({Title = T("auto_tp"), Content = T("notify_autotp_off"), Duration = 3})
        end
    end
})

VisualsTab:CreateButton({
    Name = T("tp_nearest"),
    Callback = function()
        teleportToNearestItem()
    end
})

VisualsTab:CreateToggle({
    Name = T("money_counter"),
    CurrentValue = false,
    Callback = function(value)
        if value then
            startMoneyCounter()
            Rayfield:Notify({Title = T("money_counter"), Content = T("notify_money_on"), Duration = 3})
        else
            stopMoneyCounter()
            Rayfield:Notify({Title = T("money_counter"), Content = T("notify_money_off"), Duration = 3})
        end
    end
})

-- ===== НАСТРОЙКИ =====
SettingsTab:CreateToggle({
    Name = T("anti_afk"),
    CurrentValue = false,
    Callback = function(value)
        if value then
            startAntiAfk()
        else
            stopAntiAfk()
        end
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
            Content = (currentLang == "ru") and "Язык изменён. Перезапустите скрипт." or "Language changed. Restart the script.",
            Duration = 5
        })
    end
})

-- ===== РЕСПАВН =====
player.CharacterAdded:Connect(function()
    task.wait(1)
    if autoFarmEnabled then
        task.wait(1)
        stopAutoFarm()
        task.wait(0.3)
        startAutoFarm()
    end
end)

-- ===== УВЕДОМЛЕНИЕ =====
Rayfield:Notify({
    Title = T("window_title"),
    Content = T("notify_loaded"),
    Duration = 5
})
