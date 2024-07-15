local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local playerConnections = {}
local LocalPlayer = Players.LocalPlayer

-- Function to create the highlight effect
local function createHighlight(character)
    local highlight = Instance.new("Highlight")
    highlight.Adornee = character:FindFirstChild("HumanoidRootPart")
    highlight.FillColor = Color3.new(1, 0, 0)  -- Red color
    highlight.FillTransparency = 0.2
    highlight.OutlineColor = Color3.new(1, 0, 0)  -- Red outline
    highlight.OutlineTransparency = 0
    highlight.Parent = character
end

-- Function to create the distance label above the HumanoidRootPart
local function createDistanceLabel(character)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Adornee = rootPart
    billboardGui.Size = UDim2.new(0, 100, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 2, 0)
    billboardGui.AlwaysOnTop = true

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.new(1, 1, 1)  -- White color
    textLabel.TextStrokeTransparency = 0.75
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextScaled = true
    textLabel.Parent = billboardGui

    billboardGui.Parent = character

    return textLabel
end

-- Function to create the tracer line from the local player to the character
local function createTracerLine(character)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local line = Drawing.new("Line")
    line.Thickness = 4  -- Adjust thickness as needed
    line.Color = Color3.new(1, 0, 0)  -- Red color

    return line
end

-- Function to update the distance label with the distance to the local player
local function updateDistanceLabel(label, character)
    if not LocalPlayer.Character or not character or not character:FindFirstChild("HumanoidRootPart") then return end

    local distance = (LocalPlayer.Character.HumanoidRootPart.Position - character.HumanoidRootPart.Position).Magnitude
    label.Text = tostring(math.floor(distance)) .. " studs"
end

-- Function to update the tracer line
local function updateTracerLine(line, character)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local screenPosition, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
    local localPlayerPosition, onScreen = Camera:WorldToViewportPoint(LocalPlayer.Character.HumanoidRootPart.Position)

    line.From = Vector2.new(localPlayerPosition.X, localPlayerPosition.Y)
    line.To = Vector2.new(screenPosition.X, screenPosition.Y)
end

-- Function to handle character added
local function onCharacterAdded(character)
    if character:FindFirstChild("Humanoid") then
        createHighlight(character)

        local distanceLabel = createDistanceLabel(character)
        local tracerLine = createTracerLine(character)
        if distanceLabel and tracerLine then
            local connection = RunService.RenderStepped:Connect(function()
                updateDistanceLabel(distanceLabel, character)
                updateTracerLine(tracerLine, character)
            end)

            local player = Players:GetPlayerFromCharacter(character)
            if player then
                if not playerConnections[player] then
                    playerConnections[player] = {}
                end
                table.insert(playerConnections[player], connection)
            end

            character:FindFirstChildOfClass("Humanoid").Died:Connect(function()
                if distanceLabel then
                    distanceLabel:Destroy()
                end
                if tracerLine then
                    tracerLine:Remove()
                end
                if playerConnections[player] then
                    for _, conn in ipairs(playerConnections[player]) do
                        conn:Disconnect()
                    end
                    playerConnections[player] = nil
                end
            end)
        end
    end
end

-- Function to handle player added
local function onPlayerAdded(player)
    player.CharacterAdded:Connect(onCharacterAdded)
end

-- Clean up connections for players who leave the game
local function onPlayerRemoving(player)
    if playerConnections[player] then
        for _, conn in ipairs(playerConnections[player]) do
            conn:Disconnect()
        end
        playerConnections[player] = nil
    end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Connect to existing players
for _, player in pairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end
