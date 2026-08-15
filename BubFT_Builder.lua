--[[
    Universal CS Hack - GUI Edition
    Полное меню с кнопками
    Fox & Jack Production
]]

local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local runService = game:GetService("RunService")
local uis = game:GetService("UserInputService")

-- Настройки
local settings = {
    aimbot = false,
    spinbot = false,
    triggerbot = false,
    bhop = false,
    esp = false,
    fov = 500,
    spinSpeed = 5,
}

-- ESP
local espObjects = {}

-- Враги
local function getEnemies()
    local list = {}
    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= player and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                table.insert(list, p)
            end
        end
    end
    return list
end

-- Цель
local function findTarget()
    local best = nil
    local bestDist = settings.fov
    local myPos = camera.CFrame.Position
    
    for _, p in pairs(getEnemies()) do
        local head = p.Character:FindFirstChild("Head")
        if head then
            local dist = (head.Position - myPos).Magnitude
            if dist < bestDist then
                bestDist = dist
                best = head
            end
        end
    end
    
    return best
end

-- Aimbot
local function doAimbot()
    if not settings.aimbot then return end
    local target = findTarget()
    if target then
        camera.CFrame = CFrame.lookAt(camera.CFrame.Position, target.Position)
    end
end

-- SpinBot
local function doSpinBot()
    if not settings.spinbot then return end
    local char = player.Character
    if not char then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(settings.spinSpeed * 3), 0)
    end
    camera.CFrame = camera.CFrame * CFrame.Angles(0, math.rad(settings.spinSpeed), 0)
end

-- Triggerbot
local lastShot = 0
local function doTriggerbot()
    if not settings.triggerbot then return end
    if tick() - lastShot < 0.15 then return end
    
    local char = player.Character
    if not char then return end
    
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("Tool") then
            local target = findTarget()
            if target then
                v:Activate()
                lastShot = tick()
                break
            end
        end
    end
end

-- BHop
local function doBHop()
    if not settings.bhop then return end
    
    local char = player.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    
    hum.WalkSpeed = 25
    hum.JumpPower = 45
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        local ray = Ray.new(root.Position, Vector3.new(0, -3.5, 0))
        if workspace:FindPartOnRay(ray, char) then
            hum.Jump = true
        end
    end
end

-- ESP
local function updateESP()
    for _, obj in pairs(espObjects) do
        if obj then pcall(function() obj:Remove() end) end
    end
    espObjects = {}
    
    if not settings.esp then return end
    
    for _, p in pairs(getEnemies()) do
        local head = p.Character:FindFirstChild("Head")
        local torso = p.Character:FindFirstChild("UpperTorso") or p.Character:FindFirstChild("Torso")
        
        if head and torso then
            local headPos, headOn = camera:WorldToScreenPoint(head.Position)
            local torsoPos, torsoOn = camera:WorldToScreenPoint(torso.Position)
            
            if headOn and torsoOn then
                local box = Drawing.new("Square")
                box.Visible = true
                box.Position = Vector2.new(torsoPos.X - 15, torsoPos.Y - 10)
                box.Size = Vector2.new(30, math.abs(headPos.Y - torsoPos.Y) + 20)
                box.Color = Color3.fromRGB(255, 0, 0)
                box.Thickness = 1
                box.Filled = false
                table.insert(espObjects, box)
                
                local name = Drawing.new("Text")
                name.Visible = true
                name.Position = Vector2.new(torsoPos.X, torsoPos.Y - 25)
                name.Text = p.Name
                name.Color = Color3.fromRGB(255, 255, 255)
                name.Size = 12
                name.Center = true
                table.insert(espObjects, name)
            end
        end
    end
end

-- === GUI ===
local function createGUI()
    local core = game:GetService("CoreGui")
    if core:FindFirstChild("UniversalHack") then
        core.UniversalHack:Destroy()
    end
    
    local sg = Instance.new("ScreenGui")
    sg.Name = "UniversalHack"
    sg.Parent = core
    sg.ResetOnSpawn = false
    
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 260, 0, 320)
    main.Position = UDim2.new(0.5, -130, 0.5, -160)
    main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.Parent = sg
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Text = "UNIVERSAL HACK"
    title.Size = UDim2.new(1, 0, 0, 35)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Parent = main
    
    local yPos = 45
    
    local function createToggle(name, default)
        local btn = Instance.new("TextButton")
        btn.Text = name .. ": " .. (default and "ON" or "OFF")
        btn.Size = UDim2.new(0.85, 0, 0, 35)
        btn.Position = UDim2.new(0.075, 0, 0, yPos)
        btn.BackgroundColor3 = default and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.Parent = main
        
        local state = default
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.Text = name .. ": " .. (state and "ON" or "OFF")
            btn.BackgroundColor3 = state and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
        end)
        
        yPos = yPos + 40
        return function() return state end
    end
    
    local getAimbot = createToggle("Aimbot", false)
    local getSpinbot = createToggle("SpinBot", false)
    local getTrigger = createToggle("Triggerbot", false)
    local getBhop = createToggle("BunnyHop", false)
    local getESP = createToggle("ESP", false)
    
    -- Подключаем к настройкам
    spawn(function()
        while task.wait(0.1) do
            settings.aimbot = getAimbot()
            settings.spinbot = getSpinbot()
            settings.triggerbot = getTrigger()
            settings.bhop = getBhop()
            settings.esp = getESP()
        end
    end)
    
    -- Закрыть
    local close = Instance.new("TextButton")
    close.Text = "X"
    close.Size = UDim2.new(0, 28, 0, 28)
    close.Position = UDim2.new(1, -33, 0, 4)
    close.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
    close.Font = Enum.Font.GothamBold
    close.Parent = main
    close.MouseButton1Click:Connect(function()
        settings.esp = false
        updateESP()
        sg:Destroy()
    end)
    
    -- Подсказка
    local hint = Instance.new("TextLabel")
    hint.Text = "Нажимай на кнопки!"
    hint.Size = UDim2.new(1, 0, 0, 20)
    hint.Position = UDim2.new(0, 0, 0, 295)
    hint.BackgroundTransparency = 1
    hint.TextColor3 = Color3.fromRGB(100, 100, 100)
    hint.Font = Enum.Font.Gotham
    hint.TextSize = 11
    hint.Parent = main
end

-- Запуск
createGUI()

-- Главный цикл
runService.RenderStepped:Connect(function()
    pcall(doSpinBot)
    pcall(doAimbot)
    pcall(doTriggerbot)
    pcall(doBHop)
    pcall(updateESP)
end)

print("Universal Hack GUI loaded!")
