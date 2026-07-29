-- Минимальный тест
local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Ждём появления персонажа
repeat task.wait() until player.Character
print("Я в игре!")

-- Создаём GUI
local sg = Instance.new("ScreenGui")
sg.Parent = game:GetService("CoreGui")

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0, 200, 0, 50)
btn.Position = UDim2.new(0.5, -100, 0.5, -25)
btn.Text = "AIMBOT ON/OFF"
btn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
btn.TextColor3 = Color3.fromRGB(0, 0, 0)
btn.Font = Enum.Font.SourceSansBold
btn.TextSize = 20
btn.Parent = sg

local aimbot = false

btn.MouseButton1Click:Connect(function()
    aimbot = not aimbot
    btn.Text = "AIMBOT " .. (aimbot and "ON" or "OFF")
    btn.BackgroundColor3 = aimbot and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
end)

-- Цикл аимбота
game:GetService("RunService").RenderStepped:Connect(function()
    if not aimbot then return end
    
    local closest = nil
    local minDist = 9999
    
    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= player and p.Character then
            local head = p.Character:FindFirstChild("Head")
            if head then
                local dist = (head.Position - camera.CFrame.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = head
                end
            end
        end
    end
    
    if closest then
        camera.CFrame = CFrame.new(camera.CFrame.Position, closest.Position)
    end
end)

print("ГОТОВО! Жми кнопку на экране!")
