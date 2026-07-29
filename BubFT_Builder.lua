--[[
    CS Hack for Roblox
    Aimbot | Triggerbot | BunnyHop | WallHack | Third Person
    Fox & Jack Production
]]

-- === КОНФИГ ===
local AIMBOT = true
local TRIGGERBOT = true
local BHOP = true
local WALLHACK = false
local THIRDPERSON = false
local BHOP_SPEED = 50       -- скорость разгона
local AIM_SPEED = 30        -- скорость наводки
local FOV = 360             -- через всю карту

local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local runService = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local lastShot = 0
local currentTarget = nil

-- === ПОЛУЧЕНИЕ ОРУЖИЯ ===
local function getGun()
    local char = player.Character
    if not char then return nil end
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("Tool") then return v end
    end
    return nil
end

-- === ПОЛУЧЕНИЕ ВРАГОВ ===
local function getEnemies()
    local enemies = {}
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                table.insert(enemies, plr)
            end
        end
    end
    return enemies
end

-- === БЛИЖАЙШИЙ ВРАГ ===
local function getClosestEnemy()
    local best = nil
    local bestDist = math.huge
    local myPos = camera.CFrame.Position
    
    for _, enemy in pairs(getEnemies()) do
        local head = enemy.Character:FindFirstChild("Head")
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

-- === AIMBOT ===
local function doAimbot()
    if not AIMBOT then return end
    local target = getClosestEnemy()
    if not target then return end
    
    currentTarget = target
    local targetPos = target.Position
    camera.CFrame = CFrame.new(camera.CFrame.Position, targetPos)
end

-- === TRIGGERBOT ===
local function doTriggerbot()
    if not TRIGGERBOT then return end
    if tick() - lastShot < 0.1 then return end
    
    local target = getClosestEnemy()
    if not target then return end
    
    -- Проверяем что враг в центре экрана
    local screenPos, onScreen = camera:WorldToScreenPoint(target.Position)
    if onScreen then
        local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        
        if dist < 80 then  -- в радиусе 80 пикселей от центра
            local gun = getGun()
            if gun then
                pcall(function()
                    gun:Activate()
                end)
                lastShot = tick()
            end
        end
    end
end

-- === BUNNYHOP ===
local function doBunnyHop()
    if not BHOP then return end
    local char = player.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    
    -- Разгон
    hum.WalkSpeed = BHOP_SPEED
    hum.JumpPower = 50
    
    -- Авто-прыжок
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        local ray = Ray.new(root.Position, Vector3.new(0, -3, 0))
        local hit = workspace:FindPartOnRay(ray, char)
        if hit then
            hum.Jump = true
        end
    end
end

-- === WALLHACK ===
local wallhackObjects = {}

local function doWallHack()
    if WALLHACK then
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and v.Transparency < 0.5 then
                if not wallhackObjects[v] then
                    wallhackObjects[v] = v.Transparency
                end
                v.Transparency = 0.7
            end
        end
    else
        for obj, origTrans in pairs(wallhackObjects) do
            if obj then
                pcall(function() obj.Transparency = origTrans end)
            end
        end
        wallhackObjects = {}
    end
end

-- === THIRD PERSON ===
local function doThirdPerson()
    if THIRDPERSON then
        player.CameraMaxZoomDistance = 15
        player.CameraMinZoomDistance = 10
    else
        player.CameraMaxZoomDistance = 0
        player.CameraMinZoomDistance = 0
    end
end

-- === GUI (простой и рабочий) ===
local function createGUI()
    -- Удаляем старый GUI
    if game:GetService("CoreGui"):FindFirstChild("CS_Hack") then
        game:GetService("CoreGui").CS_Hack:Destroy()
    end
    
    local sg = Instance.new("ScreenGui")
    sg.Name = "CS_Hack"
    sg.Parent = game:GetService("CoreGui")
    sg.ResetOnSpawn = false
    
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 200, 0, 280)
    main.Position = UDim2.new(0.5, -100, 0.5, -140)
    main.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.Parent = sg
    
    local title = Instance.new("TextLabel")
    title.Text = "CS HACK v2"
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Parent = main
    
    local yPos = 40
    
    -- Функция создания кнопки
    local function addButton(name, callback, default)
        local btn = Instance.new("TextButton")
        btn.Text = name .. ": " .. (default and "ON" or "OFF")
        btn.Size = UDim2.new(0.9, 0, 0, 35)
        btn.Position = UDim2.new(0.05, 0, 0, yPos)
        btn.BackgroundColor3 = default and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(180, 0, 0)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.Parent = main
        
        local enabled = default
        btn.MouseButton1Click:Connect(function()
            enabled = not enabled
            btn.Text = name .. ": " .. (enabled and "ON" or "OFF")
            btn.BackgroundColor3 = enabled and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(180, 0, 0)
            callback(enabled)
        end)
        
        yPos = yPos + 40
    end
    
    addButton("Aimbot", function(v) AIMBOT = v end, true)
    addButton("Triggerbot", function(v) TRIGGERBOT = v end, true)
    addButton("BunnyHop", function(v) BHOP = v end, true)
    addButton("WallHack", function(v) WALLHACK = v; doWallHack() end, false)
    addButton("3rd Person", function(v) THIRDPERSON = v; doThirdPerson() end, false)
    
    -- Закрыть
    local close = Instance.new("TextButton")
    close.Text = "X"
    close.Size = UDim2.new(0, 25, 0, 25)
    close.Position = UDim2.new(1, -30, 0, 2)
    close.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
    close.Font = Enum.Font.GothamBold
    close.Parent = main
    close.MouseButton1Click:Connect(function()
        WALLHACK = false
        doWallHack()
        THIRDPERSON = false
        doThirdPerson()
        sg:Destroy()
    end)
end

-- === ЗАПУСК ===
createGUI()

-- Главный цикл
runService.RenderStepped:Connect(function()
    pcall(doAimbot)
    pcall(doTriggerbot)
    pcall(doBunnyHop)
end)

print("CS HACK LOADED!")
print("Aimbot + Triggerbot + BHop + WH + 3rd Person")
print("Press F9 to see this console")
