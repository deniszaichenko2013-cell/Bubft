--[[
    CS Aimbot - Drawing Edition
    Без GUI, всё через Drawing
    Левый Shift = вкл/выкл аимбот
]]

local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local runService = game:GetService("RunService")
local uis = game:GetService("UserInputService")

local aimbot = true
local triggerbot = false
local bhop = false

-- Текстовый индикатор через Drawing
local indicator = Drawing.new("Text")
indicator.Visible = true
indicator.Position = Vector2.new(10, 10)
indicator.Text = "AIMBOT: ON"
indicator.Color = Color3.fromRGB(0, 255, 0)
indicator.Size = 16

-- Поиск врага
local function findTarget()
    local best = nil
    local bestDist = 500
    local myPos = camera.CFrame.Position
    
    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= player and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local head = p.Character:FindFirstChild("Head")
                if head then
                    local screenPos, onScreen = camera:WorldToScreenPoint(head.Position)
                    if onScreen then
                        local cx = camera.ViewportSize.X / 2
                        local cy = camera.ViewportSize.Y / 2
                        local screenDist = math.sqrt((screenPos.X - cx)^2 + (screenPos.Y - cy)^2)
                        
                        if screenDist < 200 then
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
    end
    
    return best
end

-- Аимбот
local function doAimbot()
    if not aimbot then return end
    
    local target = findTarget()
    if not target then return end
    
    camera.CFrame = CFrame.lookAt(camera.CFrame.Position, target.Position)
end

-- Триггербот
local lastShot = 0
local function doTrigger()
    if not triggerbot then return end
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
    if not bhop then return end
    
    local char = player.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    
    hum.WalkSpeed = 20
    hum.JumpPower = 40
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        local ray = Ray.new(root.Position, Vector3.new(0, -3.5, 0))
        if workspace:FindPartOnRay(ray, char) then
            hum.Jump = true
        end
    end
end

-- Управление клавишами
uis.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Левый Shift = вкл/выкл аимбот
    if input.KeyCode == Enum.KeyCode.LeftShift then
        aimbot = not aimbot
        indicator.Text = "AIMBOT: " .. (aimbot and "ON" or "OFF")
        indicator.Color = aimbot and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    end
    
    -- T = триггербот
    if input.KeyCode == Enum.KeyCode.T then
        triggerbot = not triggerbot
    end
    
    -- B = бхоп
    if input.KeyCode == Enum.KeyCode.B then
        bhop = not bhop
    end
    
    -- Обновляем индикатор
    indicator.Text = string.format("AIM: %s | TRIG: %s | BHOP: %s", 
        aimbot and "ON" or "OFF",
        triggerbot and "ON" or "OFF",
        bhop and "ON" or "OFF")
end)

-- Главный цикл
runService.RenderStepped:Connect(function()
    pcall(doAimbot)
    pcall(doTrigger)
    pcall(doBHop)
end)

print("Aimbot loaded! LeftShift = Toggle Aim")
