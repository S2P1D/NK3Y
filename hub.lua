-- ============================================================
-- NK3Y HUB - Strict Pandauth Only
-- ============================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local PLACES = { DCYF = 128662368175518, Bahkruums = 91698952875688 }
local SCRIPTS = {
    dcyf = { name = "DCYF Autofarm", url = "https://raw.githubusercontent.com/S2P1D/NK3Y/main/autofarm.lua" },
    bahkruums = { name = "Bahkruums Farm", url = "https://raw.githubusercontent.com/S2P1D/NK3Y/main/bahkruums.lua" }
}

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
-- СИСТЕМА КЛЮЧЕЙ (ТОЛЬКО PANDAUTH)
-- ============================================================
local function checkRemoteKey(key)
    local hwid = tostring(Players.LocalPlayer.UserId)
    local service = "nk3yhub"
    
    -- URL-кодирование
    local encodedKey = HttpService:UrlEncode(key)
    local encodedService = HttpService:UrlEncode(service)
    local encodedHwid = HttpService:UrlEncode(hwid)
    
    local url = "https://pandadevelopment.net/v2_validation?service=" .. encodedService .. "&hwid=" .. encodedHwid .. "&key=" .. encodedKey
    
    local success, response = pcall(function() return game:HttpGet(url, true) end)
    
    if not success or not response then 
        return false, "СЕТЬ: " .. tostring(response) 
    end
    
    local ok, data = pcall(function() return HttpService:JSONDecode(response) end)
    if not ok or not data then 
        return false, "JSON ERR: " .. tostring(response) 
    end
    
    -- Если сервер вернул success = false (например, неверный ключ или сервис)
    if data.success == false then
        return false, "Panda: " .. tostring(data.message)
    end
    
    if data.V2_Authentication == "success" then
        return true, "OK"
    else
        return false, "Отклонен: " .. tostring(data.reason or data.message)
    end
end

local function validateKey(key)
    if not key or key == "" then return false, "Пустой ключ" end
    local ok, msg = checkRemoteKey(key)
    if ok then return true, "OK" end
    return false, msg
end

local function fetchKeyInfo(key)
    local hwid = tostring(Players.LocalPlayer.UserId)
    local url = "https://pandadevelopment.net/v2_keyinfo?service=nk3yhub&hwid=" .. hwid .. "&key=" .. key
    local success, response = pcall(function() return game:HttpGet(url, true) end)
    if not success or not response then return "Ошибка соединения." end
    
    local ok, data = pcall(function() return HttpService:JSONDecode(response) end)
    if not ok or not data or not data.Key_Information then return "Ошибка данных." end
    
    local info = data.Key_Information
    local exp = info.Days_Left and (info.Days_Left .. " дн.") or "Бессрочный"
    return string.format("Время: %s\nHWID: %s / %s", exp, info.HWID_Usage or "?", info.HWID_Limit or "?")
end

-- ============================================================
-- СОХРАНЕНИЕ И ЭКРАН
-- ============================================================
local KEY_FILE = "NK3Y_HUB_KEY.txt"
local function loadSavedKey() if isfile and isfile(KEY_FILE) then return readfile(KEY_FILE):gsub("%s+","") end return nil end
local function saveKey(key) if writefile then writefile(KEY_FILE, key) end end

local function showKeyScreen(callback)
    local keyGui = Instance.new("ScreenGui", Players.LocalPlayer:WaitForChild("PlayerGui"))
    keyGui.Name, keyGui.IgnoreGuiInset, keyGui.DisplayOrder = "NK3Y_Key", true, 999

    local frame = Instance.new("Frame", keyGui)
    frame.Size, frame.Position = UDim2.new(0, 420, 0, 260), UDim2.new(0.5, -210, 0.5, -130)
    frame.BackgroundColor3, frame.BorderSizePixel = Color3.fromRGB(0, 0, 0), 0
    Instance.new("UIStroke", frame).Color = Color3.fromRGB(0, 255, 100)

    local title = Instance.new("TextLabel", frame)
    title.Size, title.Position, title.BackgroundTransparency = UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0, 20), 1
    title.Text, title.TextColor3, title.TextScaled, title.Font = "NK3Y HUB (Panda)", Color3.fromRGB(0, 255, 100), true, Enum.Font.Code

    local input = Instance.new("TextBox", frame)
    input.Size, input.Position = UDim2.new(0.85, 0, 0, 44), UDim2.new(0.075, 0, 0, 80)
    input.BackgroundColor3, input.BorderSizePixel, input.Text = Color3.fromRGB(15, 15, 15), 0, ""
    input.PlaceholderText, input.TextColor3, input.TextScaled, input.Font = "вставь ключ...", Color3.fromRGB(255, 255, 255), true, Enum.Font.Code

    local status = Instance.new("TextLabel", frame)
    status.Size, status.Position, status.BackgroundTransparency = UDim2.new(0.9, 0, 0, 40), UDim2.new(0.05, 0, 0, 130), 1
    status.Text, status.TextColor3, status.TextScaled, status.TextWrapped, status.Font = "", Color3.fromRGB(255, 80, 80), true, true, Enum.Font.Code

    local btn = Instance.new("TextButton", frame)
    btn.Size, btn.Position = UDim2.new(0.85, 0, 0, 44), UDim2.new(0.075, 0, 0, 180)
    btn.BackgroundColor3, btn.BorderSizePixel, btn.Text = Color3.fromRGB(0, 180, 70), 0, "ВОЙТИ"
    btn.TextColor3, btn.TextScaled, btn.Font = Color3.fromRGB(255, 255, 255), true, Enum.Font.Code

    local checking = false
    btn.MouseButton1Click:Connect(function()
        if checking then return end; checking = true
        local key = input.Text:gsub("%s+", "")
        if key == "" then status.Text = "введи ключ"; checking = false; return end
        
        status.TextColor3, status.Text = Color3.fromRGB(180, 180, 180), "проверка..."
        task.spawn(function()
            local ok, msg = validateKey(key)
            if ok then
                status.TextColor3, status.Text = Color3.fromRGB(0, 255, 100), "ключ принят..."
                saveKey(key); task.wait(0.5); keyGui:Destroy(); callback(key)
            else
                status.TextColor3, status.Text = Color3.fromRGB(255, 80, 80), msg; checking = false
            end
        end)
    end)
end

-- ============================================================
-- ГЛАВНОЕ МЕНЮ
-- ============================================================
local function showHubMenu(userKey)
    local Window = Rayfield:CreateWindow({
        Name = "NK3Y HUB",
        LoadingTitle = "Загрузка...", LoadingSubtitle = "by NK3Y",
        Theme = { TextColor = Color3.fromRGB(0,255,100), Background = Color3.fromRGB(0,0,0), Topbar = Color3.fromRGB(5,5,5), Shadow = Color3.fromRGB(0,10,0), NotificationBackground = Color3.fromRGB(0,20,5), NotificationActionsBackground = Color3.fromRGB(0,40,15), TabBackground = Color3.fromRGB(0,20,0), TabStroke = Color3.fromRGB(0,255,100), TabBackgroundSelected = Color3.fromRGB(0,80,30), TabTextColor = Color3.fromRGB(0,200,80), SelectedTabTextColor = Color3.fromRGB(0,255,100), ElementBackground = Color3.fromRGB(5,15,5), ElementBackgroundHover = Color3.fromRGB(0,40,15), SecondaryElementBackground = Color3.fromRGB(0,10,0), ElementStroke = Color3.fromRGB(0,200,80), SecondaryElementStroke = Color3.fromRGB(0,100,40), SliderBackground = Color3.fromRGB(0,50,20), SliderProgress = Color3.fromRGB(0,255,100), SliderStroke = Color3.fromRGB(0,255,100), ToggleBackground = Color3.fromRGB(0,30,10), ToggleEnabled = Color3.fromRGB(0,255,100), ToggleDisabled = Color3.fromRGB(40,40,40), ToggleEnabledStroke = Color3.fromRGB(0,255,100), ToggleDisabledStroke = Color3.fromRGB(80,80,80), ToggleEnabledOuterStroke = Color3.fromRGB(0,150,60), ToggleDisabledOuterStroke = Color3.fromRGB(60,60,60), DropdownSelected = Color3.fromRGB(0,40,15), DropdownUnselected = Color3.fromRGB(0,20,5), InputBackground = Color3.fromRGB(5,10,5), InputStroke = Color3.fromRGB(0,180,70), PlaceholderColor = Color3.fromRGB(0,100,40) },
        ConfigurationSaving = { Enabled = false }
    })
    applyScaleFix(getOptimalScale())

    local MainTab = Window:CreateTab("Скрипты", 4483362458)
    local InfoTab = Window:CreateTab("Ключ / Инфо", 4483362458)

    MainTab:CreateButton({Name = "Загрузить DCYF", Callback = function()
        Rayfield:Notify({Title="Загрузка", Content="DCYF...", Duration=2})
        task.spawn(function() getgenv().NK3Y_Key = userKey; loadstring(game:HttpGet(SCRIPTS.dcyf.url))() end)
    end})
    
    MainTab:CreateButton({Name = "Загрузить Bahkruums", Callback = function()
        Rayfield:Notify({Title="Загрузка", Content="Bahkruums...", Duration=2})
        task.spawn(function() getgenv().NK3Y_Key = userKey; loadstring(game:HttpGet(SCRIPTS.bahkruums.url))() end)
    end})

    InfoTab:CreateButton({Name = "Твой ключ: " .. string.sub(userKey, 1, 8) .. "***", Callback = function() end})
    InfoTab:CreateButton({Name = "Узнать время и HWID ключа", Callback = function()
        task.spawn(function()
            local info = fetchKeyInfo(userKey)
            for line in info:gmatch("[^\r\n]+") do
                Rayfield:Notify({Title="Инфо", Content=line, Duration=5}); task.wait(0.3)
            end
        end)
    end})
    InfoTab:CreateButton({Name = "Сбросить ключ", Callback = function()
        if delfile and isfile(KEY_FILE) then delfile(KEY_FILE); Rayfield:Notify({Title="Сброс", Content="Перезапусти скрипт", Duration=5}) end
    end})
end

local savedKey = loadSavedKey()
if savedKey then
    local ok, msg = validateKey(savedKey)
    if ok then showHubMenu(savedKey) else showKeyScreen(function(k) showHubMenu(k) end) end
else
    showKeyScreen(function(k) showHubMenu(k) end)
end
