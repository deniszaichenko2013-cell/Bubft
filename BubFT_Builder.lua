--[[
    CS Aimbot PC - Fixed
    Меню: Правый Shift
]]

local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local runService = game:GetService("RunService")
local uis = game:GetService("UserInputService")

-- Настройки
local aimbot = true
local triggerbot = false
local bhop = false
local showMenu = true

-- Поиск врага
local function findTarget()
    local best = nil
    local bestDist = 9999
    local myPos = camera.CFrame.Position
    
    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= player and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local head = p.Character:FindFirstChild("Head")
                if head then
                    local dist = (head.Position - myPos).Magnitude
                    if dist < bestDist then
                        bestDist = dist
                        best = head
                    end
                end
            end
        end
    end
    
    return best
end

-- Мгновенный аимбот
local function doAimbot()
    if not aimbot then return end
    local target = findTarget()
    if target then
        camera.CFrame = CFrame.lookAt(camera.CFrame.Position, target.Position)
    end
end

-- Триггербот
local lastShot = 0
local function doTrigger()
    if not triggerbot then return end
    if tick() - lastShot < 0.1 then return end
    
    local char = player.Character
    if not char then return end
    
    local tool = nil
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("Tool") then tool = v; break end
    end
    
    if not tool then return end
    
    local target = findTarget()
    if target then
        local pos, onScreen = camera:WorldToScreenPoint(target.Position)
        if onScreen then
            local cx = camera.ViewportSize.X / 2
            local cy = camera.ViewportSize.Y / 2
            local dist = math.sqrt((pos.X - cx)^2 + (pos.Y - cy)^2)
            if dist < 80 then
                tool:Activate()
                lastShot = tick()
            end
        end
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
        if workspace:FindPartOnRay(ray, char) then
            hum.Jump = true
        end
    end
end

-- === GUI ===
local sg = Instance.new("ScreenGui")
sg.Name = "CS_Menu"
sg.Parent = game:GetService("CoreGui")
sg.ResetOnSpawn = false

local main = Instance.new("Frame")
main.Name = "MainFrame"
main.Size = UDim2.new(0, 200, 0, 180)
main.Position = UDim2.new(0.5, -100, 0.5, -90)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Visible = showMenu
main.Parent = sg

local title = Instance.new("TextLabel")
title.Text = "CS AIMBOT"
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = main

local y = 38

local function addButton(name, default, callback)
    local btn = Instance.new("TextButton")
    btn.Text = name .. ": " .. (default and "ON" or "OFF")
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.Position = UDim2.new(0.05, 0, 0, y)
    btn.BackgroundColor3 = default and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = main
    
    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = name .. ": " .. (state and "ON" or "OFF")
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
        callback(state)
    end)
    
    y = y + 40
end

addButton("Aimbot", true, function(v) aimbot = v end)
addButton("Triggerbot", false, function(v) triggerbot = v end)
addButton("BunnyHop", false, function(v) bhop = v end)

-- Кнопка закрыть
local close = Instance.new("TextButton")
close.Text = "X"
close.Size = UDim2.new(0, 25, 0, 25)
close.Position = UDim2.new(1, -30, 0, 3)
close.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.Font = Enum.Font.GothamBold
close.Parent = main
close.MouseButton1Click:Connect(function()
    showMenu = false
    main.Visible = false
end)

-- Переключение меню на Правый Shift
uis.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        showMenu = not showMenu
        main.Visible = showMenu
    end
end)

-- Главный цикл
runService.RenderStepped:Connect(function()
    pcall(doAimbot)
    pcall(doTrigger)
    pcall(doBHop)
end)

print("CS Aimbot loaded!")
print("Press Right Shift to toggle menu")
