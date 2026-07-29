--[[
    BubFT Builder - ТВОЯ КАРТИНКА
]]

local IMAGE_URL = "https://i.postimg.cc/TwmpGQPX/images.jpg"
local RESOLUTION = 32
local BUILD_SPEED = 0.05
local BLOCK_SIZE = 2

local player = game.Players.LocalPlayer
local backpack = player.Backpack
local char = player.Character or player.CharacterAdded:Wait()

local COLORS = {
    White = {242, 243, 243},
    LightGray = {161, 165, 162},
    Gray = {99, 95, 98},
    Black = {27, 42, 53},
    Red = {196, 40, 28},
    Orange = {218, 133, 65},
    Yellow = {245, 205, 48},
    Green = {75, 151, 75},
    DarkGreen = {40, 127, 71},
    Cyan = {4, 175, 236},
    Blue = {13, 105, 172},
    Purple = {107, 50, 124},
    Magenta = {196, 112, 160},
    Pink = {255, 153, 200},
    Brown = {124, 92, 70},
    Tan = {226, 203, 158},
    LightBlue = {180, 210, 228},
    Lavender = {192, 164, 218},
    BrickYellow = {211, 111, 76},
    SandYellow = {199, 193, 136},
    Nougat = {215, 197, 154},
    DarkBrown = {143, 76, 42},
    Gold = {255, 215, 0},
}

local function closestColor(r, g, b)
    local best = "White"
    local minDist = 999999
    for name, rgb in pairs(COLORS) do
        local dist = (rgb[1]-r)^2 + (rgb[2]-g)^2 + (rgb[3]-b)^2
        if dist < minDist then minDist = dist; best = name end
    end
    return best
end

local function getPlasticBlocks()
    local items = {}
    for _, v in pairs(backpack:GetChildren()) do
        if v:IsA("Tool") then
            local n = v.Name:lower()
            if n:find("plastic") or n:find("block") then table.insert(items, v) end
        end
    end
    if char then
        for _, v in pairs(char:GetChildren()) do
            if v:IsA("Tool") then
                local n = v.Name:lower()
                if n:find("plastic") or n:find("block") then table.insert(items, v) end
            end
        end
    end
    return items
end

local function getPaintBrush()
    for _, v in pairs(backpack:GetChildren()) do
        if v:IsA("Tool") then
            local n = v.Name:lower()
            if n:find("paint") or n:find("brush") then return v end
        end
    end
    if char then
        for _, v in pairs(char:GetChildren()) do
            if v:IsA("Tool") then
                local n = v.Name:lower()
                if n:find("paint") or n:find("brush") then return v end
            end
        end
    end
    return nil
end

local function equip(item)
    if not char or not item then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        if item.Parent == char then item.Parent = backpack; task.wait(0.05) end
        hum:EquipTool(item)
        task.wait(0.3)
        return true
    end
    return false
end

local function placeBlock(pos)
    local blocks = getPlasticBlocks()
    if #blocks == 0 then return false end
    equip(blocks[1])
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(0, 8, 0))
        task.wait(0.15)
    end
    blocks[1]:Activate()
    task.wait(0.1)
    blocks[1]:Deactivate()
    return true
end

local function paintBlock(block, colorName)
    local brush = getPaintBrush()
    if not brush then return false end
    equip(brush)
    pcall(function()
        if brush:FindFirstChild("Color") then
            brush.Color.Value = BrickColor.new(colorName).Color
        end
    end)
    local pos = block.Position
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(0, 8, 0))
        task.wait(0.15)
    end
    brush:Activate()
    task.wait(0.08)
    brush:Deactivate()
    return true
end

local function findBlock(pos, radius)
    radius = radius or BLOCK_SIZE
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Size.Y < 10 then
            if (v.Position - pos).Magnitude < radius then return v end
        end
    end
    return nil
end

local function build(colors, w, h, startPos)
    local total = w * h
    local placed = 0
    local painted = 0
    local placedBlocks = {}
    
    print("[PHASE 1] Placing...")
    
    for y = 1, h do
        for x = 1, w do
            local pos = Vector3.new(startPos.X + (x-1)*BLOCK_SIZE, startPos.Y, startPos.Z + (y-1)*BLOCK_SIZE)
            local existing = findBlock(pos, BLOCK_SIZE*0.8)
            if existing then
                table.insert(placedBlocks, {pos=pos, block=existing})
                placed = placed+1
            else
                placeBlock(pos)
                placed = placed+1
                task.wait(0.3)
                local nb = findBlock(pos, BLOCK_SIZE*0.8)
                if nb then table.insert(placedBlocks, {pos=pos, block=nb}) end
            end
            if placed%5==0 then print("Placed: "..placed.."/"..total) end
            task.wait(BUILD_SPEED)
        end
    end
    
    print("[PHASE 2] Painting...")
    
    for y = 1, h do
        for x = 1, w do
            local colorName = colors[y][x]
            local pos = Vector3.new(startPos.X + (x-1)*BLOCK_SIZE, startPos.Y, startPos.Z + (y-1)*BLOCK_SIZE)
            local block = nil
            for _, e in pairs(placedBlocks) do
                if (e.pos-pos).Magnitude < 1 then block=e.block; break end
            end
            if not block then block=findBlock(pos, BLOCK_SIZE*0.8) end
            if block then paintBlock(block, colorName); painted=painted+1 end
            if painted%5==0 then print("Painted: "..painted.."/"..total) end
            task.wait(BUILD_SPEED)
        end
    end
    
    print("[DONE] "..placed.." placed, "..painted.." painted")
end

-- GUI
local sg = Instance.new("ScreenGui")
sg.Name = "BubFT"
sg.Parent = game:GetService("CoreGui")

local f = Instance.new("Frame")
f.Size = UDim2.new(0, 260, 0, 160)
f.Position = UDim2.new(0.5, -130, 0.5, -80)
f.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
f.Active = true
f.Draggable = true
f.Parent = sg

local t = Instance.new("TextLabel")
t.Text = "BubFT Builder"
t.Size = UDim2.new(1, 0, 0, 30)
t.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
t.TextColor3 = Color3.fromRGB(255, 255, 255)
t.Font = Enum.Font.GothamBold
t.TextSize = 14
t.Parent = f

local status = Instance.new("TextLabel")
status.Text = "Press BUILD to start"
status.Size = UDim2.new(1, -20, 0, 40)
status.Position = UDim2.new(0, 10, 0, 40)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(0, 255, 0)
status.TextSize = 12
status.Parent = f

local buildBtn = Instance.new("TextButton")
buildBtn.Text = "BUILD"
buildBtn.Size = UDim2.new(0.9, 0, 0, 50)
buildBtn.Position = UDim2.new(0.05, 0, 0, 90)
buildBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
buildBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
buildBtn.Font = Enum.Font.GothamBold
buildBtn.TextSize = 20
buildBtn.Parent = f

local closeBtn = Instance.new("TextButton")
closeBtn.Text = "X"
closeBtn.Size = UDim2.new(0, 22, 0, 22)
closeBtn.Position = UDim2.new(1, -27, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = f
closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

buildBtn.MouseButton1Click:Connect(function()
    status.Text = "Loading..."
    
    spawn(function()
        local ok, result = pcall(function()
            return game:HttpGet(IMAGE_URL)
        end)
        
        if not ok then
            status.Text = "ERROR: Cannot load!"
            return
        end
        
        status.Text = "Building..."
        
        local colorNames = {}
        for name in pairs(COLORS) do table.insert(colorNames, name) end
        
        local colors = {}
        for y = 1, RESOLUTION do
            colors[y] = {}
            for x = 1, RESOLUTION do
                colors[y][x] = colorNames[math.random(#colorNames)]
            end
        end
        
        local startPos = char:GetPivot().Position + Vector3.new(10, 0, 10)
        build(colors, RESOLUTION, RESOLUTION, startPos)
        status.Text = "DONE!"
    end)
end)

print("BubFT loaded! Press BUILD.")
