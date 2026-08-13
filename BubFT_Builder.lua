--[[
    CS HACK PC EDITION
    Для Solara / Delta (Windows)
    Instant Aimbot | Triggerbot | BunnyHop | ESP | WallHack
]]

local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local runService = game:GetService("RunService")
local uis = game:GetService("UserInputService")

-- Настройки
local settings = {
    aimbot = true,
    triggerbot = false,
    bhop = false,
    esp = false,
    wallhack = false,
    aimSpeed = 1, -- 1 = мгновенно
    fov = 9999
}

local lastShot = 0
local whData = {}

-- === ПОЛУЧЕНИЕ ОРУЖИЯ ===
local function getTool()
    local char = player.Character
    if char then
        for _, v in pairs(char:GetChildren()) do
            if v:IsA("Tool") then return v end
        end
    end
    return nil
end

-- === ПОЛУЧЕНИЕ ВРАГОВ ===
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

-- === БЛИЖАЙШИЙ ВРАГ ===
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

-- === INSTANT AIMBOT ===
local function doAimbot()
    if not settings.aimbot then return end
    local target = findTarget()
    if target then
        camera.CFrame = CFrame.lookAt(camera.CFrame.Position, target.Position)
    end
end

-- === TRIGGERBOT ===
local function doTriggerbot()
    if not settings.triggerbot then return end
    if tick() - lastShot < 0.1 then return end
    
    local target = findTarget()
    if not target then return end
    
    local screenPos, onScreen = camera:WorldToScreenPoint(target.Position)
    if onScreen then
        local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        
        if dist < 70 then
            local tool = getTool()
            if tool then
                tool:Activate()
                lastShot = tick()
            end
        end
    end
end

-- === BUNNYHOP ===
local function doBHop()
    if not settings.bhop then return end
    
    local char = player.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    
    hum.WalkSpeed = 50
    hum.JumpPower = 50
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        local ray = Ray.new(root.Position, Vector3.new(0, -3.5, 0))
        if workspace:FindPartOnRay(ray, char) then
            hum.Jump = true
        end
    end
end

-- === ESP ===
local espObjects = {}

local function updateESP()
    for _, obj in pairs(espObjects) do
        if obj then pcall(function() obj:Remove() end) end
    end
    espObjects = {}
    
    if not settings.esp then return end
    
    for _, p in pairs(getEnemies()) do
        local head = p.Character:FindFirstChild("Head")
        if head then
            local pos, onScreen = camera:WorldToScreenPoint(head.Position)
            if onScreen then
                -- Рамка
                local box = Drawing.new("Square")
                box.Visible = true
                box.Position = Vector2.new(pos.X - 15, pos.Y - 15)
                box.Size = Vector2.new(30, 30)
                box.Color = Color3.fromRGB(255, 0, 0)
                box.Thickness = 2
                box.Filled = false
                table.insert(espObjects, box)
                
                -- Имя
                local name = Drawing.new("Text")
                name.Visible = true
                name.Position = Vector2.new(pos.X - 20, pos.Y - 35)
                name.Text = p.Name
                name.Color = Color3.fromRGB(255, 255, 255)
                name.Size = 14
                name.Center = true
                table.insert(espObjects, name)
            end
        end
    end
end

-- === WALLHACK ===
local function doWallHack()
    if settings.wallhack then
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and v.Transparency < 0.3 and not whData[v] then
                whData[v] = v.Transparency
                v.Transparency = 0.7
            end
        end
    else
        for obj, orig in pairs(whData) do
            if obj then pcall(function() obj.Transparency = orig end) end
        end
        whData = {}
    end
end

-- === GUI ===
local function createGUI()
    local core = game:GetService("CoreGui")
    if core:FindFirstChild("CS_Hack_PC") then
        core.CS_Hack_PC:Destroy()
        for _, obj in pairs(espObjects) do
            if obj then pcall(function() obj:Remove() end) end
        end
        settings.wallhack = false
        doWallHack()
    end
    
    local sg = Instance.new("ScreenGui")
    sg.Name = "CS_Hack_PC"
    sg.Parent = core
    sg.ResetOnSpawn = false
    
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 220, 0, 270)
    main.Position = UDim2.new(0.5, -110, 0.5, -135)
    main.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.Parent = sg
    
    local title = Instance.new("TextLabel")
    title.Text = "CS HACK PC"
    title.Size = UDim2.new(1, 0, 0, 32)
    title.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Parent = main
    
    local yPos = 40
    
    local buttons = {
        {"Instant Aimbot", "aimbot", true},
        {"Triggerbot", "triggerbot", false},
        {"BunnyHop", "bhop", false},
        {"ESP", "esp", false},
        {"WallHack", "wallhack", false},
    }
    
    for _, btn in pairs(buttons) do
        local name = btn[1]
        local key = btn[2]
        local default = btn[3]
        
        local b = Instance.new("TextButton")
        b.Text = name .. ": " .. (default and "ON" or "OFF")
        b.Size = UDim2.new(0.9, 0, 0, 35)
        b.Position = UDim2.new(0.05, 0, 0, yPos)
        b.BackgroundColor3 = default and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 14
        b.Parent = main
        
        b.MouseButton1Click:Connect(function()
            settings[key] = not settings[key]
            b.Text = name .. ": " .. (settings[key] and "ON" or "OFF")
            b.BackgroundColor3 = settings[key] and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
            
            if key == "wallhack" then doWallHack() end
            if key == "esp" then updateESP() end
        end)
        
        yPos = yPos + 40
    end
    
    local close = Instance.new("TextButton")
    close.Text = "X"
    close.Size = UDim2.new(0, 25, 0, 25)
    close.Position = UDim2.new(1, -30, 0, 3)
    close.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
    close.Font = Enum.Font.GothamBold
    close.Parent = main
    close.MouseButton1Click:Connect(function()
        settings.wallhack = false
        doWallHack()
        settings.esp = false
        updateESP()
        sg:Destroy()
    end)
end

-- === СТАРТ ===
createGUI()

runService.RenderStepped:Connect(function()
    pcall(doAimbot)
    pcall(doTriggerbot)
    pcall(doBHop)
    pcall(updateESP)
end)

print("CS HACK PC LOADED!")
print("Aimbot | Triggerbot | BHop | ESP | WallHack")
