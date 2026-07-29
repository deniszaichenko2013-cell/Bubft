--[[
    CS Hack v4 for Roblox
    Aimbot | Triggerbot | BunnyHop | WallHack | Third Person | Flat Textures
    Fox & Jack Production
]]

local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local runService = game:GetService("RunService")
local lighting = game:GetService("Lighting")

-- === НАСТРОЙКИ ===
local settings = {
    aimbot = true,
    triggerbot = true,
    bhop = true,
    wallhack = false,
    thirdperson = false,
    flatTextures = false,
    bhopSpeed = 50,
    aimSpeed = 30,
    fov = 360
}

local lastShot = 0
local originalData = {}
local whData = {}

-- === FLAT TEXTURES ===
local function applyFlatTextures()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Union") or obj:IsA("MeshPart") then
            if not originalData[obj] then
                originalData[obj] = {
                    Color = obj.Color,
                    Material = obj.Material,
                    Transparency = obj.Transparency,
                    TextureID = pcall(function() return obj.TextureID end) and obj.TextureID or ""
                }
            end
            obj.Material = "SmoothPlastic"
            obj.Color = Color3.fromRGB(255, 150, 50)
            obj.Transparency = 0
            pcall(function() obj.TextureID = "" end)
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            pcall(function() obj.Transparency = 1 end)
        end
    end
    
    lighting.GlobalShadows = false
    lighting.Brightness = 3
    lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    lighting.ClockTime = 14
end

local function removeFlatTextures()
    for obj, data in pairs(originalData) do
        if obj and obj.Parent then
            pcall(function()
                obj.Color = data.Color
                obj.Material = data.Material
                obj.Transparency = data.Transparency
                if data.TextureID ~= "" then
                    obj.TextureID = data.TextureID
                end
            end)
        end
    end
    originalData = {}
    
    lighting.GlobalShadows = true
    lighting.Brightness = 1
    lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
end

-- === ОРУЖИЕ ===
local function getTool()
    local char = player.Character
    if char then
        for _, v in pairs(char:GetChildren()) do
            if v:IsA("Tool") then return v end
        end
    end
    return nil
end

-- === ВРАГИ ===
local function getEnemies()
    local list = {}
    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= player and p.Character then
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then
                table.insert(list, p.Character)
            end
        end
    end
    return list
end

-- === БЛИЖАЙШИЙ ===
local function getTarget()
    local best = nil
    local minDist = math.huge
    local myPos = camera.CFrame.Position
    
    for _, char in pairs(getEnemies()) do
        local head = char:FindFirstChild("Head")
        if head then
            local d = (head.Position - myPos).Magnitude
            if d < minDist then
                minDist = d
                best = head
            end
        end
    end
    
    return best
end

-- === AIMBOT ===
local function aimbot()
    if not settings.aimbot then return end
    local target = getTarget()
    if target then
        camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position)
    end
end

-- === TRIGGERBOT ===
local function triggerbot()
    if not settings.triggerbot then return end
    if tick() - lastShot < 0.08 then return end
    
    local target = getTarget()
    if not target then return end
    
    local pos, onScreen = camera:WorldToScreenPoint(target.Position)
    if onScreen then
        local cx = camera.ViewportSize.X / 2
        local cy = camera.ViewportSize.Y / 2
        local dx = pos.X - cx
        local dy = pos.Y - cy
        local dist = math.sqrt(dx*dx + dy*dy)
        
        if dist < 80 then
            local tool = getTool()
            if tool then
                tool:Activate()
                lastShot = tick()
            end
        end
    end
end

-- === BUNNYHOP ===
local function bhop()
    if not settings.bhop then return end
    
    local char = player.Character
    if not char then return end
    
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    humanoid.WalkSpeed = settings.bhopSpeed
    humanoid.JumpPower = 50
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        local ray = Ray.new(root.Position, Vector3.new(0, -3.5, 0))
        local hit = workspace:FindPartOnRay(ray, char)
        if hit then
            humanoid.Jump = true
        end
    end
end

-- === WALLHACK ===
local function wallhack()
    if settings.wallhack then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Transparency < 0.3 and not whData[obj] then
                whData[obj] = obj.Transparency
                obj.Transparency = 0.6
            end
        end
    else
        for obj, val in pairs(whData) do
            if obj then
                pcall(function() obj.Transparency = val end)
            end
        end
        whData = {}
    end
end

-- === THIRD PERSON ===
local function thirdperson()
    if settings.thirdperson then
        player.CameraMaxZoomDistance = 20
        player.CameraMinZoomDistance = 10
    else
        player.CameraMaxZoomDistance = 0
        player.CameraMinZoomDistance = 0
    end
end

-- === GUI ===
local function makeGUI()
    local core = game:GetService("CoreGui")
    if core:FindFirstChild("CS_Hack") then
        core.CS_Hack:Destroy()
    end
    
    -- Сброс при перезапуске
    settings.flatTextures = false
    removeFlatTextures()
    settings.wallhack = false
    wallhack()
    settings.thirdperson = false
    thirdperson()
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "CS_Hack"
    gui.Parent = core
    
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0, 200, 0, 310)
    bg.Position = UDim2.new(0.5, -100, 0.3, -100)
    bg.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    bg.BorderSizePixel = 0
    bg.Active = true
    bg.Draggable = true
    bg.Parent = gui
    
    local head = Instance.new("TextLabel")
    head.Text = "CS HACK v4"
    head.Size = UDim2.new(1, 0, 0, 30)
    head.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    head.TextColor3 = Color3.fromRGB(255, 255, 255)
    head.Font = Enum.Font.SourceSansBold
    head.TextSize = 16
    head.Parent = bg
    
    local y = 38
    
    local buttons = {
        {"Aimbot", "aimbot"},
        {"Triggerbot", "triggerbot"},
        {"BunnyHop", "bhop"},
        {"WallHack", "wallhack"},
        {"3rd Person", "thirdperson"},
        {"Flat Textures", "flatTextures"},
    }
    
    for _, btn in pairs(buttons) do
        local name = btn[1]
        local key = btn[2]
        
        local b = Instance.new("TextButton")
        b.Text = name .. ": " .. (settings[key] and "ON" or "OFF")
        b.Size = UDim2.new(0.9, 0, 0, 35)
        b.Position = UDim2.new(0.05, 0, 0, y)
        b.BackgroundColor3 = settings[key] and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.Font = Enum.Font.SourceSansBold
        b.TextSize = 14
        b.Parent = bg
        
        b.MouseButton1Click:Connect(function()
            settings[key] = not settings[key]
            b.Text = name .. ": " .. (settings[key] and "ON" or "OFF")
            b.BackgroundColor3 = settings[key] and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
            
            if key == "wallhack" then wallhack() end
            if key == "thirdperson" then thirdperson() end
            if key == "flatTextures" then
                if settings[key] then applyFlatTextures() else removeFlatTextures() end
            end
        end)
        
        y = y + 40
    end
    
    local close = Instance.new("TextButton")
    close.Text = "X"
    close.Size = UDim2.new(0, 25, 0, 25)
    close.Position = UDim2.new(1, -30, 0, 3)
    close.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
    close.Font = Enum.Font.SourceSansBold
    close.Parent = bg
    close.MouseButton1Click:Connect(function()
        settings.wallhack = false; wallhack()
        settings.thirdperson = false; thirdperson()
        settings.flatTextures = false; removeFlatTextures()
        gui:Destroy()
    end)
end

-- === СТАРТ ===
makeGUI()

runService.RenderStepped:Connect(function()
    pcall(aimbot)
    pcall(triggerbot)
    pcall(bhop)
end)

print("CS HACK v4 LOADED!")
