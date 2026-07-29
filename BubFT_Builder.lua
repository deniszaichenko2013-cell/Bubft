--[[
    CS Aimbot + Triggerbot for Roblox
    Auto-aim through walls, auto-stop, auto-shoot
    Fox & Jack Production
]]

-- === КОНФИГ ===
local AIMBOT_ENABLED = true
local TRIGGERBOT_ENABLED = true
local FOV = 360                -- угол обзора (360 = вся карта)
local AIM_SPEED = 25           -- скорость наводки
local AIM_PRIORITY = "head"    -- "head", "torso", "closest"
local TRIGGER_DELAY = 0.01     -- задержка между выстрелами
local WALL_CHECK = false       -- true = только видимых, false = через стены
local TEAM_CHECK = true        -- не стрелять по своим
local AUTO_STOP = true         -- останавливаться при стрельбе
local ESP_ENABLED = true       -- показывать врагов

-- === СЛУЖЕБНЫЕ ПЕРЕМЕННЫЕ ===
local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local teams = game:GetService("Teams")

local currentTarget = nil
local isAiming = false
local lastShot = 0

-- === ПОИСК ОРУЖИЯ ===
local function getWeapon()
    local char = player.Character
    if not char then return nil end
    
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("Tool") then
            local name = v.Name:lower()
            if name:find("gun") or name:find("rifle") or name:find("pistol") 
                or name:find("ak") or name:find("m4") or name:find("awp")
                or name:find("deagle") or name:find("weapon") then
                return v
            end
        end
    end
    
    -- Ищем в рюкзаке
    for _, v in pairs(player.Backpack:GetChildren()) do
        if v:IsA("Tool") then
            local name = v.Name:lower()
            if name:find("gun") or name:find("rifle") or name:find("pistol")
                or name:find("ak") or name:find("m4") or name:find("awp")
                or name:find("deagle") or name:find("weapon") then
                return v
            end
        end
    end
    
    return nil
end

-- === ПОЛУЧЕНИЕ ВСЕХ ИГРОКОВ ===
local function getEnemies()
    local enemies = {}
    local myTeam = nil
    
    if TEAM_CHECK and teams then
        for _, team in pairs(teams:GetChildren()) do
            for _, plr in pairs(team:GetPlayers()) do
                if plr == player then
                    myTeam = team
                    break
                end
            end
        end
    end
    
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                -- Проверка команды
                if TEAM_CHECK and myTeam then
                    local inMyTeam = false
                    for _, member in pairs(myTeam:GetPlayers()) do
                        if member == plr then inMyTeam = true; break end
                    end
                    if inMyTeam then continue end
                end
                
                table.insert(enemies, plr)
            end
        end
    end
    
    return enemies
end

-- === ПОЛУЧЕНИЕ ТОЧКИ ПРИЦЕЛИВАНИЯ ===
local function getAimPoint(enemy)
    local char = enemy.Character
    if not char then return nil end
    
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return nil end
    
    if AIM_PRIORITY == "head" then
        local head = char:FindFirstChild("Head")
        if head then return head.Position end
    end
    
    if AIM_PRIORITY == "torso" then
        local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
        if torso then return torso.Position end
    end
    
    -- Closest part
    local closest = nil
    local closestDist = math.huge
    local myPos = camera.CFrame.Position
    
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            local dist = (part.Position - myPos).Magnitude
            if dist < closestDist then
                closestDist = dist
                closest = part
            end
        end
    end
    
    return closest and closest.Position
end

-- === ПРОВЕРКА ВИДИМОСТИ ===
local function isVisible(targetPos)
    local myPos = camera.CFrame.Position
    local ray = Ray.new(myPos, (targetPos - myPos).Unit * 1000)
    local hit, pos = workspace:FindPartOnRay(ray, player.Character, false, true)
    
    if hit then
        -- Проверяем, попали ли в игрока
        local hitPlayer = game.Players:GetPlayerFromCharacter(hit.Parent)
        if hitPlayer then
            return true
        end
        
        -- Проверяем, попали ли в часть тела
        if hit.Parent:FindFirstChildOfClass("Humanoid") then
            return true
        end
    end
    
    return false
end

-- === ПОЛУЧЕНИЕ ЛУЧШЕЙ ЦЕЛИ ===
local function getBestTarget()
    local enemies = getEnemies()
    local bestTarget = nil
    local bestScore = math.huge
    local myPos = camera.CFrame.Position
    
    for _, enemy in pairs(enemies) do
        local aimPoint = getAimPoint(enemy)
        if not aimPoint then continue end
        
        -- Проверка видимости
        if WALL_CHECK and not isVisible(aimPoint) then continue end
        
        -- Проверка FOV
        local screenPos, onScreen = camera:WorldToScreenPoint(aimPoint)
        if not onScreen then continue end
        
        local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
        local fovRadius = (FOV / 360) * camera.ViewportSize.X
        
        if FOV < 360 and screenDist > fovRadius then continue end
        
        -- Приоритет по расстоянию
        local dist = (aimPoint - myPos).Magnitude
        
        -- Приоритет: чем ближе к центру экрана, тем лучше
        local score = screenDist + dist * 0.1
        
        if score < bestScore then
            bestScore = score
            bestTarget = {
                player = enemy,
                position = aimPoint,
                screenPos = Vector2.new(screenPos.X, screenPos.Y)
            }
        end
    end
    
    return bestTarget
end

-- === ПЛАВНЫЙ ПОВОРОТ ===
local function smoothAim(targetPos)
    local myPos = camera.CFrame.Position
    local lookAt = CFrame.new(myPos, targetPos)
    local currentCFrame = camera.CFrame
    local targetCFrame = CFrame.new(myPos, targetPos)
    
    -- Плавная интерполяция
    local smoothFactor = math.min(1, AIM_SPEED * 0.02)
    camera.CFrame = currentCFrame:Lerp(targetCFrame, smoothFactor)
end

-- === ОСТАНОВКА ПЕРСОНАЖА ===
local function stopCharacter()
    local char = player.Character
    if not char then return end
    
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.MoveDirection = Vector3.new(0, 0, 0)
    end
    
    -- Обнуляем скорость
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.Velocity = Vector3.new(0, part.Velocity.Y, 0)
        end
    end
end

-- === ВЫСТРЕЛ ===
local function shoot()
    local weapon = getWeapon()
    if not weapon then return false end
    
    local now = tick()
    if now - lastShot < TRIGGER_DELAY then return false end
    
    -- Авто-стоп
    if AUTO_STOP then
        stopCharacter()
    end
    
    -- Активируем оружие
    pcall(function()
        weapon:Activate()
    end)
    
    -- Ищем функцию выстрела
    pcall(function()
        if weapon.Shoot then
            weapon:Shoot()
        elseif weapon.Fire then
            weapon:Fire()
        elseif weapon.RemoteEvent then
            weapon.RemoteEvent:FireServer()
        elseif weapon:FindFirstChild("Shoot") then
            weapon.Shoot:FireServer()
        end
    end)
    
    lastShot = now
    return true
end

-- === ОСНОВНОЙ ЦИКЛ ===
local function onRenderStep()
    if not AIMBOT_ENABLED and not TRIGGERBOT_ENABLED then return end
    
    local target = getBestTarget()
    currentTarget = target
    
    if not target then
        isAiming = false
        return
    end
    
    isAiming = true
    
    -- Аимбот
    if AIMBOT_ENABLED then
        smoothAim(target.position)
    end
    
    -- Триггербот
    if TRIGGERBOT_ENABLED then
        -- Если враг в центре экрана - стреляем
        local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        local distToCenter = (target.screenPos - screenCenter).Magnitude
        local triggerRadius = 50 -- пикселей от центра
        
        if distToCenter < triggerRadius then
            shoot()
        end
    end
end

-- === ESP (показывает врагов) ===
local espLines = {}

local function updateESP()
    -- Удаляем старые линии
    for _, line in pairs(espLines) do
        if line then line:Remove() end
    end
    espLines = {}
    
    if not ESP_ENABLED then return end
    
    local enemies = getEnemies()
    local myPos = camera.CFrame.Position
    
    for _, enemy in pairs(enemies) do
        local aimPoint = getAimPoint(enemy)
        if not aimPoint then continue end
        
        local screenPos, onScreen = camera:WorldToScreenPoint(aimPoint)
        if not onScreen then continue end
        
        -- Рисуем рамку
        local box = Drawing.new("Square")
        box.Visible = true
        box.Position = Vector2.new(screenPos.X - 10, screenPos.Y - 10)
        box.Size = Vector2.new(20, 20)
        box.Color = Color3.new(1, 0, 0)
        box.Thickness = 2
        box.Filled = false
        table.insert(espLines, box)
        
        -- Линия к врагу
        local line = Drawing.new("Line")
        line.Visible = true
        line.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
        line.To = Vector2.new(screenPos.X, screenPos.Y)
        line.Color = Color3.new(1, 0.5, 0)
        line.Thickness = 1
        table.insert(espLines, line)
        
        -- Имя врага
        local name = Drawing.new("Text")
        name.Visible = true
        name.Position = Vector2.new(screenPos.X, screenPos.Y - 20)
        name.Text = enemy.Name
        name.Color = Color3.new(1, 1, 1)
        name.Size = 14
        table.insert(espLines, name)
    end
end

-- === GUI ===
local function createGUI()
    local sg = Instance.new("ScreenGui")
    sg.Name = "CS_Aimbot"
    sg.Parent = game:GetService("CoreGui")
    
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 250, 0, 320)
    f.Position = UDim2.new(0.5, -125, 0.5, -160)
    f.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    f.Active = true
    f.Draggable = true
    f.Parent = sg
    
    local title = Instance.new("TextLabel")
    title.Text = "CS Aimbot | Fox & Jack"
    title.Size = UDim2.new(1, 0, 0, 35)
    title.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.Parent = f
    
    local aimToggle = Instance.new("TextButton")
    aimToggle.Text = "Aimbot: ON"
    aimToggle.Size = UDim2.new(0.9, 0, 0, 35)
    aimToggle.Position = UDim2.new(0.05, 0, 0, 45)
    aimToggle.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    aimToggle.TextColor3 = Color3.fromRGB(0, 0, 0)
    aimToggle.Font = Enum.Font.GothamBold
    aimToggle.Parent = f
    aimToggle.MouseButton1Click:Connect(function()
        AIMBOT_ENABLED = not AIMBOT_ENABLED
        aimToggle.Text = "Aimbot: " .. (AIMBOT_ENABLED and "ON" or "OFF")
        aimToggle.BackgroundColor3 = AIMBOT_ENABLED and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
    end)
    
    local trigToggle = Instance.new("TextButton")
    trigToggle.Text = "Triggerbot: ON"
    trigToggle.Size = UDim2.new(0.9, 0, 0, 35)
    trigToggle.Position = UDim2.new(0.05, 0, 0, 85)
    trigToggle.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    trigToggle.TextColor3 = Color3.fromRGB(0, 0, 0)
    trigToggle.Font = Enum.Font.GothamBold
    trigToggle.Parent = f
    trigToggle.MouseButton1Click:Connect(function()
        TRIGGERBOT_ENABLED = not TRIGGERBOT_ENABLED
        trigToggle.Text = "Triggerbot: " .. (TRIGGERBOT_ENABLED and "ON" or "OFF")
        trigToggle.BackgroundColor3 = TRIGGERBOT_ENABLED and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
    end)
    
    local espToggle = Instance.new("TextButton")
    espToggle.Text = "ESP: ON"
    espToggle.Size = UDim2.new(0.9, 0, 0, 35)
    espToggle.Position = UDim2.new(0.05, 0, 0, 125)
    espToggle.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    espToggle.TextColor3 = Color3.fromRGB(0, 0, 0)
    espToggle.Font = Enum.Font.GothamBold
    espToggle.Parent = f
    espToggle.MouseButton1Click:Connect(function()
        ESP_ENABLED = not ESP_ENABLED
        espToggle.Text = "ESP: " .. (ESP_ENABLED and "ON" or "OFF")
        espToggle.BackgroundColor3 = ESP_ENABLED and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
    end)
    
    local wallToggle = Instance.new("TextButton")
    wallToggle.Text = "WallCheck: OFF"
    wallToggle.Size = UDim2.new(0.9, 0, 0, 35)
    wallToggle.Position = UDim2.new(0.05, 0, 0, 165)
    wallToggle.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    wallToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    wallToggle.Font = Enum.Font.GothamBold
    wallToggle.Parent = f
    wallToggle.MouseButton1Click:Connect(function()
        WALL_CHECK = not WALL_CHECK
        wallToggle.Text = "WallCheck: " .. (WALL_CHECK and "ON" or "OFF")
        wallToggle.BackgroundColor3 = WALL_CHECK and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
    end)
    
    local priorityBtn = Instance.new("TextButton")
    priorityBtn.Text = "Priority: " .. AIM_PRIORITY
    priorityBtn.Size = UDim2.new(0.9, 0, 0, 35)
    priorityBtn.Position = UDim2.new(0.05, 0, 0, 205)
    priorityBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    priorityBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    priorityBtn.Font = Enum.Font.GothamBold
    priorityBtn.Parent = f
    priorityBtn.MouseButton1Click:Connect(function()
        if AIM_PRIORITY == "head" then
            AIM_PRIORITY = "torso"
        elseif AIM_PRIORITY == "torso" then
            AIM_PRIORITY = "closest"
        else
            AIM_PRIORITY = "head"
        end
        priorityBtn.Text = "Priority: " .. AIM_PRIORITY
    end)
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "X"
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    closeBtn.Position = UDim2.new(1, -30, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = f
    closeBtn.MouseButton1Click:Connect(function()
        sg:Destroy()
        for _, line in pairs(espLines) do
            if line then line:Remove() end
        end
    end)
end

-- === ЗАПУСК ===
if game:GetService("CoreGui"):FindFirstChild("CS_Aimbot") then
    game:GetService("CoreGui").CS_Aimbot:Destroy()
end

createGUI()

-- Главный цикл
runService.RenderStepped:Connect(function()
    onRenderStep()
    updateESP()
end)

print("CS Aimbot + Triggerbot loaded!")
print("Made by Fox & Jack")
print("Press INSERT to toggle GUI")
