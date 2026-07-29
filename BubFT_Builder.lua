--[[
    CS HACK v5 - Instant Aimbot
    Мгновенная наводка + меню
]]

local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local runService = game:GetService("RunService")
local uis = game:GetService("UserInputService")

-- Настройки
local aimbot = true
local triggerbot = false
local bhop = false
local fov = 9999  -- бесконечная дистанция
local smoothness = 1  -- 1 = мгновенно, 2+ = плавнее

-- Быстрый поиск врага
local function findTarget()
    local best = nil
    local bestDist = fov
    local myPos = camera.CFrame.Position
    
    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= player and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local head = p.Character:FindFirstChild("Head")
                if head then
                    local screenPos, onScreen = camera:WorldToScreenPoint(head.Position)
                    if onScreen then
                        local dist = (head.Position - myPos).Magnitude
                        if dist < bestDist then
                            bestDist = dist
                            best = head
                        end
                    end
                end
            end
        end
    end
    
    return best
end

-- Мгновенный аимбот
local function instantAim()
    if not aimbot then return end
    
    local target = findTarget()
    if not target then return end
    
    -- Мгновенный поворот без плавности
    camera.CFrame = CFrame.lookAt(camera.CFrame.Position, target.Position)
end

-- Триггербот
local lastShot = 0
local function doTrigger()
    if not triggerbot then return end
    if tick() - lastShot < 0.05 then return end
    
    local char = player.Character
    if not char then return end
    
    local tool = nil
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("Tool") then tool = v; break end
    end
    
    if not tool then return end
    
    local target = findTarget()
    if target then
        tool:Activate()
        lastShot = tick()
    end
end

-- BunnyHop
local function doBHop()
    if not bhop then return end
    
    local char = player.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    
    hum.WalkSpeed = 50
    hum.JumpPower = 50
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        local ray = Ray.new(root.Position, Vector3.new(0, -3.5, 0))
        local hit = workspace:FindPartOnRay(ray, char)
        if hit then
            hum.Jump = true
        end
    end
end

-- GUI
local function createGUI()
    local core = game:GetService("CoreGui")
    if core:FindFirstChild("CS_Instant") then
        core.CS_Instant:Destroy()
    end
    
    local sg = Instance.new("ScreenGui")
    sg.Name = "CS_Instant"
    sg.Parent = core
    
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 200, 0, 180)
    f.Position = UDim2.new(0.5, -100, 0.4, -90)
    f.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    f.BorderSizePixel = 0
    f.Active = true
    f.Draggable = true
    f.Parent = sg
    
    local t = Instance.new("TextLabel")
    t.Text = "CS INSTANT AIM"
    t.Size = UDim2.new(1, 0, 0, 30)
    t.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    t.TextColor3 = Color3.fromRGB(255, 255, 255)
    t.Font = Enum.Font.SourceSansBold
    t.TextSize = 16
    t.Parent = f
    
    local y = 38
    
    local function addBtn(name, default, callback)
        local b = Instance.new("TextButton")
        b.Text = name .. ": " .. (default and "ON" or "OFF")
        b.Size = UDim2.new(0.9, 0, 0, 35)
        b.Position = UDim2.new(0.05, 0, 0, y)
        b.BackgroundColor3 = default and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(180, 0, 0)
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.Font = Enum.Font.SourceSansBold
        b.TextSize = 14
        b.Parent = f
        
        local state = default
        b.MouseButton1Click:Connect(function()
            state = not state
            b.Text = name .. ": " .. (state and "ON" or "OFF")
            b.BackgroundColor3 = state and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(180, 0, 0)
            callback(state)
        end)
        
        y = y + 40
    end
    
    addBtn("Instant Aim", true, function(v) aimbot = v end)
    addBtn("Triggerbot", false, function(v) triggerbot = v end)
    addBtn("BunnyHop", false, function(v) bhop = v end)
    
    -- Закрыть
    local close = Instance.new("TextButton")
    close.Text = "X"
    close.Size = UDim2.new(0, 25, 0, 25)
    close.Position = UDim2.new(1, -30, 0, 3)
    close.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
    close.Font = Enum.Font.SourceSansBold
    close.Parent = f
    close.MouseButton1Click:Connect(function() sg:Destroy() end)
end

-- СТАРТ
createGUI()

runService.RenderStepped:Connect(function()
    pcall(instantAim)
    pcall(doTrigger)
    pcall(doBHop)
end)

print("INSTANT AIMBOT LOADED!")
print("Мгновенная наводка на голову")
