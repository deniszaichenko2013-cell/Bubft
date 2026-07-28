--[[
    BubFT Builder for Build A Boat For Treasure
    Запуск: loadstring(game:HttpGet("ССЫЛКА"))()
]]

local IMAGE_NAME = "image.bmp"
local BUILD_SPEED = 0.03
local PAINT_SPEED = 0.03
local BLOCK_SIZE = 2

local function parseBMP(data)
    if not data or #data < 54 then return nil end
    if string.sub(data, 1, 2) ~= "BM" then return nil end
    
    local pixelOffset = string.unpack("<I4", data, 11)
    local width = string.unpack("<I4", data, 19)
    local height = string.unpack("<i4", data, 23)
    local bitsPerPixel = string.unpack("<I2", data, 29)
    local compression = string.unpack("<I4", data, 31)
    
    if bitsPerPixel ~= 24 or compression ~= 0 then return nil end
    
    local absHeight = math.abs(height)
    local topDown = (height < 0)
    local rowSize = math.floor((width * 3 + 3) / 4) * 4
    local pixels = {}
    
    for y = 0, absHeight - 1 do
        local row = {}
        local rowOffset = pixelOffset + 1 + y * rowSize
        for x = 0, width - 1 do
            local pOff = rowOffset + x * 3
            local b = string.byte(data, pOff)
            local g = string.byte(data, pOff + 1)
            local r = string.byte(data, pOff + 2)
            row[x] = {r, g, b}
        end
        if topDown then pixels[y] = row
        else pixels[absHeight - 1 - y] = row end
    end
    
    return pixels, width, absHeight
end

local BRICK_COLORS = {
    {r=242,g=243,b=243, name="White"},
    {r=161,g=165,b=162, name="Medium stone grey"},
    {r=99,g=95,b=98, name="Dark stone grey"},
    {r=27,g=42,b=53, name="Black"},
    {r=196,g=40,b=28, name="Bright red"},
    {r=218,g=133,b=65, name="Bright orange"},
    {r=245,g=205,b=48, name="Bright yellow"},
    {r=75,g=151,b=75, name="Bright green"},
    {r=40,g=127,b=71, name="Dark green"},
    {r=4,g=175,b=236, name="Cyan"},
    {r=13,g=105,b=172, name="Bright blue"},
    {r=107,g=50,b=124, name="Bright violet"},
    {r=196,g=112,b=160, name="Magenta"},
    {r=255,g=153,b=200, name="Bright pink"},
    {r=124,g=92,b=70, name="Brown"},
    {r=226,g=203,b=158, name="Light orange"},
    {r=180,g=210,b=228, name="Pastel Blue"},
    {r=192,g=164,b=218, name="Lavender"},
    {r=159,g=161,b=172, name="Smoky grey"},
    {r=211,g=111,b=76, name="Brick yellow"},
    {r=58,g=125,b=52, name="Earth green"},
    {r=199,g=193,b=136, name="Sand yellow"},
    {r=215,g=197,b=154, name="Nougat"},
    {r=143,g=76,b=42, name="Reddish brown"},
    {r=255,g=255,b=255, name="Institutional white"},
    {r=128,g=187,b=219, name="Light blue"},
    {r=150,g=150,b=150, name="Mid gray"},
    {r=255,g=89,b=89, name="Persimmon"},
    {r=255,g=176,b=0, name="Deep orange"},
    {r=255,g=215,b=0, name="Gold"},
    {r=255,g=255,b=0, name="New Yeller"},
}

local function findClosestColor(r, g, b)
    local closest = BRICK_COLORS[1]
    local minDist = math.huge
    for _, c in ipairs(BRICK_COLORS) do
        local dist = (c.r-r)^2 + (c.g-g)^2 + (c.b-b)^2
        if dist < minDist then minDist = dist; closest = c end
    end
    return closest
end

local player = game.Players.LocalPlayer
local backpack = player.Backpack
local character = player.Character or player.CharacterAdded:Wait()

local function findPlasticBlocks()
    local blocks = {}
    for _, item in pairs(backpack:GetChildren()) do
        if item:IsA("Tool") and (item.Name:lower():find("plastic") or item.Name:lower():find("block")) then
            table.insert(blocks, item)
        end
    end
    if character then
        for _, item in pairs(character:GetChildren()) do
            if item:IsA("Tool") and (item.Name:lower():find("plastic") or item.Name:lower():find("block")) then
                table.insert(blocks, item)
            end
        end
    end
    return blocks
end

local function findPaintBrush()
    for _, item in pairs(backpack:GetChildren()) do
        if item:IsA("Tool") and (item.Name:lower():find("paint") or item.Name:lower():find("brush")) then
            return item
        end
    end
    if character then
        for _, item in pairs(character:GetChildren()) do
            if item:IsA("Tool") and (item.Name:lower():find("paint") or item.Name:lower():find("brush")) then
                return item
            end
        end
    end
    return nil
end

local function equipTool(tool)
    if not character or not tool then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        if tool.Parent == character then
            tool.Parent = backpack
            task.wait(0.05)
        end
        humanoid:EquipTool(tool)
        task.wait(0.3)
        return true
    end
    return false
end

local function placeBlock(worldPos)
    local blocks = findPlasticBlocks()
    if #blocks == 0 then return false end
    
    equipTool(blocks[1])
    
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(worldPos + Vector3.new(0, 8, 0))
        task.wait(0.15)
        root.CFrame = CFrame.lookAt(worldPos + Vector3.new(0, 3, 0), worldPos)
        task.wait(0.1)
    end
    
    blocks[1]:Activate()
    task.wait(0.1)
    blocks[1]:Deactivate()
    return true
end

local function paintBlock(block, colorName)
    local brush = findPaintBrush()
    if not brush then return false end
    
    equipTool(brush)
    
    pcall(function()
        if brush:FindFirstChild("Color") then
            brush.Color.Value = BrickColor.new(colorName).Color
        end
    end)
    
    local pos = block.Position
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(pos + Vector3.new(0, 8, 0))
        task.wait(0.15)
        root.CFrame = CFrame.lookAt(pos + Vector3.new(0, 3, 0), pos)
        task.wait(0.1)
    end
    
    brush:Activate()
    task.wait(0.08)
    brush:Deactivate()
    return true
end

local function findBlockAt(worldPos, radius)
    radius = radius or BLOCK_SIZE
    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and part.Size.Y < 10 then
            if (part.Position - worldPos).Magnitude < radius then
                return part
            end
        end
    end
    return nil
end

local function buildPixelArt(pixels, width, height, startPos)
    local total = width * height
    local placed = 0
    local painted = 0
    local placedPositions = {}
    
    print("[PHASE 1] Placing blocks...")
    
    for y = 0, height - 1 do
        for x = 0, width - 1 do
            local pos = Vector3.new(startPos.X + x * BLOCK_SIZE, startPos.Y, startPos.Z + y * BLOCK_SIZE)
            local existing = findBlockAt(pos, BLOCK_SIZE * 0.8)
            
            if existing then
                placedPositions[#placedPositions + 1] = {pos = pos, block = existing}
                placed = placed + 1
            else
                if placeBlock(pos) then
                    placed = placed + 1
                    task.wait(0.5)
                    local newBlock = findBlockAt(pos, BLOCK_SIZE * 0.8)
                    if newBlock then
                        placedPositions[#placedPositions + 1] = {pos = pos, block = newBlock}
                    end
                end
            end
            
            if placed % 10 == 0 then
                print(string.format("Placing: %d/%d", placed, total))
            end
            task.wait(BUILD_SPEED)
        end
    end
    
    print(string.format("[PHASE 1 DONE] Placed: %d", placed))
    task.wait(1)
    
    print("[PHASE 2] Painting...")
    
    for y = 0, height - 1 do
        for x = 0, width - 1 do
            local pixel = pixels[y] and pixels[y][x]
            if not pixel then goto continue_paint end
            
            local color = findClosestColor(pixel[1], pixel[2], pixel[3])
            local pos = Vector3.new(startPos.X + x * BLOCK_SIZE, startPos.Y, startPos.Z + y * BLOCK_SIZE)
            
            local block = nil
            for _, entry in ipairs(placedPositions) do
                if (entry.pos - pos).Magnitude < 1 then
                    block = entry.block
                    break
                end
            end
            
            if not block then
                block = findBlockAt(pos, BLOCK_SIZE * 0.8)
            end
            
            if block then
                paintBlock(block, color.name)
                painted = painted + 1
            end
            
            if painted % 10 == 0 then
                print(string.format("Painting: %d/%d", painted, total))
            end
            task.wait(PAINT_SPEED)
            ::continue_paint::
        end
    end
    
    print(string.format("[DONE] Placed: %d, Painted: %d", placed, painted))
end

-- GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BubFT"
screenGui.Parent = game:GetService("CoreGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 220)
frame.Position = UDim2.new(0.5, -125, 0.5, -110)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Text = "BubFT Builder"
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = frame

local status = Instance.new("TextLabel")
status.Name = "Status"
status.Text = "Put image.bmp in workspace"
status.Size = UDim2.new(1, -20, 0, 40)
status.Position = UDim2.new(0, 10, 0, 40)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.TextSize = 11
status.TextWrapped = true
status.Parent = frame

local loadBtn = Instance.new("TextButton")
loadBtn.Text = "LOAD BMP"
loadBtn.Size = UDim2.new(0.9, 0, 0, 35)
loadBtn.Position = UDim2.new(0.05, 0, 0, 90)
loadBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
loadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
loadBtn.Font = Enum.Font.GothamBold
loadBtn.Parent = frame

local buildBtn = Instance.new("TextButton")
buildBtn.Text = "BUILD"
buildBtn.Size = UDim2.new(0.9, 0, 0, 45)
buildBtn.Position = UDim2.new(0.05, 0, 0, 135)
buildBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
buildBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
buildBtn.Font = Enum.Font.GothamBold
buildBtn.TextSize = 18
buildBtn.Parent = frame

local closeBtn = Instance.new("TextButton")
closeBtn.Text = "X"
closeBtn.Size = UDim2.new(0, 22, 0, 22)
closeBtn.Position = UDim2.new(1, -27, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = frame
closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

local loadedPixels = nil
local loadedW, loadedH = 0, 0

loadBtn.MouseButton1Click:Connect(function()
    status.Text = "Loading..."
    local data = readfile("image.bmp")
    if not data then data = readfile("workspace/image.bmp") end
    
    if not data then
        status.Text = "ERROR: image.bmp not found!"
        return
    end
    
    local pixels, w, h = parseBMP(data)
    if not pixels then
        status.Text = "ERROR: Use 24-bit BMP!"
        return
    end
    
    loadedPixels = pixels
    loadedW = w
    loadedH = h
    status.Text = string.format("OK: %dx%d pixels", w, h)
end)

buildBtn.MouseButton1Click:Connect(function()
    if not loadedPixels then
        status.Text = "Load BMP first!"
        return
    end
    
    status.Text = "Building..."
    
    spawn(function()
        local startPos = character and character:GetPivot().Position + Vector3.new(10, 0, 10) or Vector3.new(0, 5, 0)
        buildPixelArt(loadedPixels, loadedW, loadedH, startPos)
        status.Text = "DONE!"
    end)
end)

print("BubFT Builder loaded!")
print("loadstring(game:HttpGet('ВАША_ССЫЛКА'))()")
