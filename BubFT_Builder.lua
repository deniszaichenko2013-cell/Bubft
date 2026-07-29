--[[
    CS Hack v3 for Roblox
    Aimbot | Triggerbot | BunnyHop | WallHack | Third Person | Flat Textures
    Fox & Jack Production
]]

-- === КОНФИГ ===
local AIMBOT = true
local TRIGGERBOT = true
local BHOP = true
local WALLHACK = false
local THIRDPERSON = false
local FLAT_TEXTURES = false
local BHOP_SPEED = 50
local AIM_SPEED = 30
local FOV = 360

local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local runService = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local lighting = game:GetService("Lighting")
local lastShot = 0
local currentTarget = nil

-- === FLAT TEXTURES (оптимизация) ===
local originalTextures = {}
local flatColor = Color3.fromRGB(255, 100, 0)  -- ярко-оранжевый, всё в одном цвете

local function enableFlatTextures()
    if FLAT_TEXTURES then
        -- Отключаем всё лишнее для производительности
        lighting.GlobalShadows = false
        lighting.FogEnd = 999999
        lighting.Brightness = 2
        lighting.ClockTime = 14
        lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        lighting.Outlines = false
        
        -- Убираем текстуры со всех частей
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") or v:IsA("Union") or v:IsA("MeshPart") then
                -- Сохраняем оригинальный цвет
                if not originalTextures[v] then
                    originalTextures[v] = {
                        color = v.Color,
                        material = v.Material,
                        texture = v.TextureID or "",
                        reflectance = v.Reflectance
                    }
                end
                
                -- Делаем всё ярким
                v.Material = "SmoothPlastic"
                v.Reflectance = 0
                
                -- Самый яркий цвет на текстуре (берём доминирующий)
                local r, g, b = v.Color.R, v.Color.G, v.Color.B
                local maxColor = math.max(r, g, b)
                if maxColor > 0.5 then
                    v.Color = Color3.fromRGB(255, 150, 0)  -- ярко-оранжевый для тёмных
                else
                    v.Color = Color3.fromRGB(255, 255, 100)  -- ярко-жёлтый для светлых
                end
                
                -- Убираем текстуры
                pcall(function() v.TextureID = "" end)
                pcall(function() v.Transparency = 0 end)
            end
        end
        
        -- Убираем декали и текстуры
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("Decal") or v:IsA("Texture") then
                pcall(function() v:Destroy() end)
            end
            if v:IsA("ParticleEmitter") or v:IsA("Fire") or v:IsA("Smoke") then
                pcall(function() v.Enabled = false end)
            end
        end
    end
end

local function disableFlatTextures()
    -- Восстанавливаем оригинальные текстуры
    for obj, orig in pairs(originalTextures) do
        if obj then
            pcall(function()
                obj.Color = orig.color
                obj.Material = orig.material
                obj.Reflectance = orig.reflectance
                if orig.texture ~= "" then
                    obj.TextureID = orig.texture
                end
            end)
        end
    end
    originalTextures = {}
    
    -- Восстанавливаем освещение
    lighting.GlobalShadows = true
    lighting.Brightness = 1
    lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    lighting.Outlines = true
end

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
    camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position)
end

-- === TRIGGERBOT ===
local function doTriggerbot()
    if not TRIGGERBOT then return end
    if tick() - lastShot < 0.05 then return end
    
    local target = getClosestEnemy()
    if not target then return end
    
    local screenPos, onScreen = camera:WorldToScreenPoint(target.Position)
    if onScreen then
        local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        
        if dist < 60 then
            local gun = getGun()
            if gun then
                pcall(function() gun:Activate() end)
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
    
    hum.WalkSpeed = BHOP_SPEED
    hum.JumpPower = 50
    
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
            if v:IsA("BasePart") and v.Transparency < 0.3 then
                if not wallhackObjects[v] then
                    wallhackObjects[v] = v.Transparency
                end
                v.Transparency = 0.6
            end
        end
    else
        for obj, orig in pairs(wallhackObjects) do
            if obj then
                pcall(function() obj.Transparency = orig end)
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

-- === GUI ===
local function createGUI()
    if game:GetService("CoreGui"):FindFirstChild("CS_Hack") then
        game:GetService("CoreGui").CS_Hack:Destroy()
    end
    
    -- Восстанавливаем текстуры если GUI пересоздаётся
    FLAT_TEXTURES = false
    disableFlatTextures()
    
    local sg = Instance.new("ScreenGui")
    sg.Name = "CS_Hack"
    sg.Parent = game:GetService("CoreGui")
    sg.ResetOnSpawn = false
    
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 220, 0, 320)
    main.Position = UDim2.new(0.5, -110, 0.3, -100)
    main.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.Parent = sg
    
    local title = Instance.new("TextLabel")
    title.Text = "CS HACK v3 | Fox & Jack"
    title.Size = UDim2.new(1, 0, 0, 35)
    title.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.Parent = main
    
    local yPos = 45
    
    local function addButton(name, callback, default)
        local btn = Instance.new("TextButton")
        btn.Text = name .. ": " .. (default and "ON" or "OFF")
        btn.Size = UDim2.new(0.9, 0, 0, 35)
        btn.Position = UDim2.new(0.05, 0, 0, yPos)
        btn.BackgroundColor3 = default and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(180, 0, 0)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.Parent = main
        
        local enabled = default
        btn.MouseButton1Click:Connect(function()
            enabled = not enabled
            btn.Text = name .. ": " .. (enabled and "ON" or "OFF")
            btn.BackgroundColor3 = enabled and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(180, 0, 0)
            callback(enabled)
        end)
        
        yPos = yPos + 42
    end
    
    addButton("Aimbot", function(v) AIMBOT = v end, true)
    addButton("Triggerbot", function(v) TRIGGERBOT = v end, true)
    addButton("BunnyHop", function(v) BHOP = v end, true)
    addButton("WallHack", function(v) WALLHACK = v; doWallHack() end, false)
    addButton("3rd Person", function(v) THIRDPERSON = v; doThirdPerson() end, false)
    addButton("Flat Textures", function(v)
        FLAT_TEXTURES = v
        if v then
            enableFlatTextures()
        else
            disableFlatTextures()
        end
    end, false)
    
    -- Закрыть
    local close = Instance.new("TextButton")
    close.Text = "X"
    close.Size = UDim2.new(0, 28, 0, 28)
    close.Position = UDim2.new(1, -33, 0, 3)
    close.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
    close.Font = Enum.Font.GothamBold
    close.Parent = main
    close.MouseButton1Click:Connect(function()
        WALLHACK = false
        doWallHack()
        THIRDPERSON = false
        doThirdPerson()
        FLAT_TEXTURES = false
        disableFlatTextures()
        sg:Destroy()
    end)
end

-- === ЗАПУСК ===
createGUI()

runService.RenderStepped:Connect(function()
    pcall(doAimbot)
    pcall(doTriggerbot)
    pcall(doBunnyHop)
end)

print("CS HACK v3 LOADED!")
print("Aimbot | Triggerbot | BHop | WH | 3rd Person | Flat Textures")
