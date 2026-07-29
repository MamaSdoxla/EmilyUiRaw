local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- // Configuration & State
local SETTINGS = {
    MenuOpen = true,
    Aimbot = {
        Enabled = true,
        Mode = "Hold",
        AimPart = "All",
        StickToTarget = false,
        WallCheck = false,
        AutoFire = false,
        FOV = 150,
        Smoothness = 0.2,
        Sensitivity = 0.45,
        ActiveToggle = false,
        Keybind = Enum.UserInputType.MouseButton2
    },
    ESP = {
        Enabled = true,
        Color = Color3.fromRGB(0, 255, 150),
        ShowName = true,
        ShowUsername = true,
        ShowHP = true,
        ShowDistance = true
    },
    Keybinds = {
        ToggleMenu = Enum.KeyCode.RightShift,
        ToggleAimbot = Enum.KeyCode.G,
        ToggleESP = Enum.KeyCode.H,
        WaitingForBind = nil
    }
}

-- // --- Save & Load System ---
local function SaveSettings()
    if not isfolder or not writefile then return end
    if not isfolder("EmilyUi") then makefolder("EmilyUi") end
    
    local data = {
        Aimbot = {
            Mode = SETTINGS.Aimbot.Mode,
            AimPart = SETTINGS.Aimbot.AimPart,
            StickToTarget = SETTINGS.Aimbot.StickToTarget,
            WallCheck = SETTINGS.Aimbot.WallCheck,
            AutoFire = SETTINGS.Aimbot.AutoFire,
            FOV = SETTINGS.Aimbot.FOV,
            Smoothness = SETTINGS.Aimbot.Smoothness,
            Keybind = SETTINGS.Aimbot.Keybind.Name
        },
        ESP = {
            Enabled = SETTINGS.ESP.Enabled,
            Color = {R = SETTINGS.ESP.Color.R, G = SETTINGS.ESP.Color.G, B = SETTINGS.ESP.Color.B},
            ShowName = SETTINGS.ESP.ShowName,
            ShowUsername = SETTINGS.ESP.ShowUsername,
            ShowHP = SETTINGS.ESP.ShowHP,
            ShowDistance = SETTINGS.ESP.ShowDistance
        },
        Keybinds = {
            ToggleMenu = SETTINGS.Keybinds.ToggleMenu.Name,
            ToggleAimbot = SETTINGS.Keybinds.ToggleAimbot.Name,
            ToggleESP = SETTINGS.Keybinds.ToggleESP.Name,
        }
    }
    writefile("EmilyUi/Aimbot settings.json", HttpService:JSONEncode(data))
end

local function GetEnum(name)
    if Enum.KeyCode[name] then return Enum.KeyCode[name] end
    if Enum.UserInputType[name] then return Enum.UserInputType[name] end
    return nil
end

local function LoadSettings()
    if not isfile or not readfile then return end
    if isfile("EmilyUi/Aimbot settings.json") then
        local success, json = pcall(function() return readfile("EmilyUi/Aimbot settings.json") end)
        if success and json then
            local data = HttpService:JSONDecode(json)
            if data.Aimbot then
                SETTINGS.Aimbot.Mode = data.Aimbot.Mode or SETTINGS.Aimbot.Mode
                SETTINGS.Aimbot.AimPart = data.Aimbot.AimPart or SETTINGS.Aimbot.AimPart
                SETTINGS.Aimbot.StickToTarget = data.Aimbot.StickToTarget
                if data.Aimbot.WallCheck ~= nil then SETTINGS.Aimbot.WallCheck = data.Aimbot.WallCheck end
                if data.Aimbot.AutoFire ~= nil then SETTINGS.Aimbot.AutoFire = data.Aimbot.AutoFire end
                SETTINGS.Aimbot.FOV = data.Aimbot.FOV or SETTINGS.Aimbot.FOV
                SETTINGS.Aimbot.Smoothness = data.Aimbot.Smoothness or SETTINGS.Aimbot.Smoothness
                if data.Aimbot.Keybind then SETTINGS.Aimbot.Keybind = GetEnum(data.Aimbot.Keybind) or SETTINGS.Aimbot.Keybind end
            end
            if data.ESP then
                if data.ESP.Enabled ~= nil then SETTINGS.ESP.Enabled = data.ESP.Enabled end
                if data.ESP.Color then SETTINGS.ESP.Color = Color3.new(data.ESP.Color.R, data.ESP.Color.G, data.ESP.Color.B) end
                if data.ESP.ShowName ~= nil then SETTINGS.ESP.ShowName = data.ESP.ShowName end
                if data.ESP.ShowUsername ~= nil then SETTINGS.ESP.ShowUsername = data.ESP.ShowUsername end
                if data.ESP.ShowHP ~= nil then SETTINGS.ESP.ShowHP = data.ESP.ShowHP end
                if data.ESP.ShowDistance ~= nil then SETTINGS.ESP.ShowDistance = data.ESP.ShowDistance end
            end
            if data.Keybinds then
                if data.Keybinds.ToggleMenu then SETTINGS.Keybinds.ToggleMenu = GetEnum(data.Keybinds.ToggleMenu) or SETTINGS.Keybinds.ToggleMenu end
                if data.Keybinds.ToggleAimbot then SETTINGS.Keybinds.ToggleAimbot = GetEnum(data.Keybinds.ToggleAimbot) or SETTINGS.Keybinds.ToggleAimbot end
                if data.Keybinds.ToggleESP then SETTINGS.Keybinds.ToggleESP = GetEnum(data.Keybinds.ToggleESP) or SETTINGS.Keybinds.ToggleESP end
            end
        end
    end
end

LoadSettings()

-- // --- FOV Circle ---
local fovCircle = nil
if Drawing then
    fovCircle = Drawing.new("Circle")
    fovCircle.Visible = false
    fovCircle.Thickness = 2
    fovCircle.Color = SETTINGS.ESP.Color
    fovCircle.Filled = false
end

-- // --- ESP Storage ---
local ESP_Instances = {}

local function createESP(player)
    if not player.Character then return end
    local character = player.Character
    local root = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not root or not humanoid then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "MasterHighlight"
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = SETTINGS.ESP.Color
    highlight.FillTransparency = 0.7
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.OutlineTransparency = 0.5
    highlight.Parent = character

    local billboardTop = Instance.new("BillboardGui")
    billboardTop.Name = "MasterESP_Top"
    billboardTop.Adornee = root
    billboardTop.Size = UDim2.new(0, 200, 0, 60)
    billboardTop.StudsOffset = Vector3.new(0, 3.5, 0)
    billboardTop.AlwaysOnTop = true
    billboardTop.Parent = character

    local textTop = Instance.new("TextLabel", billboardTop)
    textTop.Size = UDim2.new(1, 0, 1, 0)
    textTop.BackgroundTransparency = 1
    textTop.TextColor3 = SETTINGS.ESP.Color
    textTop.TextSize = 14
    textTop.Font = Enum.Font.GothamBold
    textTop.TextStrokeTransparency = 0.5
    textTop.TextYAlignment = Enum.TextYAlignment.Bottom 

    local billboardBottom = Instance.new("BillboardGui")
    billboardBottom.Name = "MasterESP_Bottom"
    billboardBottom.Adornee = root
    billboardBottom.Size = UDim2.new(0, 200, 0, 40)
    billboardBottom.StudsOffset = Vector3.new(0, -3, 0)
    billboardBottom.AlwaysOnTop = true
    billboardBottom.Parent = character

    local textBottom = Instance.new("TextLabel", billboardBottom)
    textBottom.Size = UDim2.new(1, 0, 1, 0)
    textBottom.BackgroundTransparency = 1
    textBottom.TextColor3 = SETTINGS.ESP.Color
    textBottom.TextSize = 13
    textBottom.Font = Enum.Font.GothamBold
    textBottom.TextStrokeTransparency = 0.5
    textBottom.TextYAlignment = Enum.TextYAlignment.Top 

    ESP_Instances[player] = { 
        Highlight = highlight, 
        TextTop = textTop, 
        TextBottom = textBottom,
        BillboardTop = billboardTop,
        BillboardBottom = billboardBottom
    }
end

local function cleanESP()
    for player, instances in pairs(ESP_Instances) do
        if instances.Highlight then instances.Highlight:Destroy() end
        if instances.BillboardTop then instances.BillboardTop:Destroy() end
        if instances.BillboardBottom then instances.BillboardBottom:Destroy() end
        ESP_Instances[player] = nil
    end
    ESP_Instances = {}
end

local function updateESP()
    for player, instances in pairs(ESP_Instances) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local root = player.Character.HumanoidRootPart
            local humanoid = player.Character.Humanoid
            
            instances.Highlight.FillColor = SETTINGS.ESP.Color
            instances.TextTop.TextColor3 = SETTINGS.ESP.Color
            instances.TextBottom.TextColor3 = SETTINGS.ESP.Color

            local topInfo = {}
            if SETTINGS.ESP.ShowName then table.insert(topInfo, player.DisplayName) end
            if SETTINGS.ESP.ShowUsername then table.insert(topInfo, "@" .. player.Name) end
            instances.TextTop.Text = table.concat(topInfo, " | ")
            
            local bottomInfo = {}
            if SETTINGS.ESP.ShowHP then
                local hpText = string.format("HP: %d/%d", math.max(0, humanoid.Health), humanoid.MaxHealth)
                table.insert(bottomInfo, hpText)
            end
            if SETTINGS.ESP.ShowDistance and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local dist = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude)
                table.insert(bottomInfo, dist .. "m")
            end
            instances.TextBottom.Text = table.concat(bottomInfo, " | ")

            local enabled = SETTINGS.ESP.Enabled
            instances.BillboardTop.Enabled = enabled
            instances.BillboardBottom.Enabled = enabled
            instances.Highlight.Enabled = enabled
            
            if not SETTINGS.ESP.ShowName and not SETTINGS.ESP.ShowUsername then
                instances.BillboardTop.Enabled = false
            end
            if not SETTINGS.ESP.ShowHP and not SETTINGS.ESP.ShowDistance then
                instances.BillboardBottom.Enabled = false
            end
        else
            if instances.BillboardTop then instances.BillboardTop.Enabled = false end
            if instances.BillboardBottom then instances.BillboardBottom.Enabled = false end
            if instances.Highlight then instances.Highlight.Enabled = false end
        end
    end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        if SETTINGS.ESP.Enabled then
            task.wait(0.5)
            createESP(p)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(p)
    if ESP_Instances[p] then
        if ESP_Instances[p].Highlight then ESP_Instances[p].Highlight:Destroy() end
        if ESP_Instances[p].BillboardTop then ESP_Instances[p].BillboardTop:Destroy() end
        if ESP_Instances[p].BillboardBottom then ESP_Instances[p].BillboardBottom:Destroy() end
        ESP_Instances[p] = nil
    end
end)

-- // --- Aimbot Logic ---
local currentTargetPart = nil

local function isVisible(targetPart)
    if not SETTINGS.Aimbot.WallCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true
    
    local result = workspace:Raycast(origin, direction, raycastParams)
    if result and result.Instance then
        if result.Instance:IsDescendantOf(targetPart.Parent) then
            return true
        end
        return false
    end
    return true
end

local function getTarget()
    if not SETTINGS.Aimbot.Enabled then return nil, nil end
    local mouse = UserInputService:GetMouseLocation()
    
    if SETTINGS.Aimbot.StickToTarget and currentTargetPart then
        if currentTargetPart.Parent and currentTargetPart.Parent:FindFirstChild("Humanoid") and currentTargetPart.Parent.Humanoid.Health > 0 then
            local screenPos, onScreen = Camera:WorldToViewportPoint(currentTargetPart.Position)
            if onScreen then
                local mag = (Vector2.new(screenPos.X, screenPos.Y) - mouse).Magnitude
                if mag <= SETTINGS.Aimbot.FOV and isVisible(currentTargetPart) then
                    return screenPos, currentTargetPart
                end
            end
        end
        currentTargetPart = nil 
    end

    local closestPos = nil
    local closestPart = nil
    local dist = SETTINGS.Aimbot.FOV
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            
            local partsToCheck = {}
            if SETTINGS.Aimbot.AimPart == "Head" then
                table.insert(partsToCheck, p.Character:FindFirstChild("Head"))
            elseif SETTINGS.Aimbot.AimPart == "RootPart" then
                table.insert(partsToCheck, p.Character:FindFirstChild("HumanoidRootPart"))
            elseif SETTINGS.Aimbot.AimPart == "All" then
                for _, partName in ipairs({"Head", "HumanoidRootPart", "UpperTorso", "Torso", "LowerTorso"}) do
                    table.insert(partsToCheck, p.Character:FindFirstChild(partName))
                end
            end
            
            for _, part in ipairs(partsToCheck) do
                if part then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local mag = (Vector2.new(screenPos.X, screenPos.Y) - mouse).Magnitude
                        if mag < dist and isVisible(part) then
                            dist = mag
                            closestPos = screenPos
                            closestPart = part
                        end
                    end
                end
            end
        end
    end
    
    if closestPart then
        currentTargetPart = closestPart
    end
    
    return closestPos, closestPart
end

-- // --- Main Loop ---
local lastFire = 0

local renderSteppedConnection
renderSteppedConnection = RunService.RenderStepped:Connect(function()
    if fovCircle then
        fovCircle.Visible = (SETTINGS.MenuOpen or SETTINGS.Aimbot.Enabled) and SETTINGS.Aimbot.Mode ~= "Always"
        fovCircle.Radius = SETTINGS.Aimbot.FOV
        fovCircle.Position = UserInputService:GetMouseLocation()
        fovCircle.Color = SETTINGS.ESP.Color
    end

    if tick() % 0.1 < 0.02 then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and not ESP_Instances[p] and p.Character then
                createESP(p)
            end
        end
        updateESP()
    end

    local shouldAim = false
    if SETTINGS.Aimbot.Mode == "Always" then
        shouldAim = true
    elseif SETTINGS.Aimbot.Mode == "Toggle" then
        shouldAim = SETTINGS.Aimbot.ActiveToggle
    elseif SETTINGS.Aimbot.Mode == "Hold" then
        local bind = SETTINGS.Aimbot.Keybind
        if typeof(bind) == "EnumItem" then
            if bind.EnumType == Enum.KeyCode then
                shouldAim = UserInputService:IsKeyDown(bind)
            elseif bind.EnumType == Enum.UserInputType then
                shouldAim = UserInputService:IsMouseButtonPressed(bind)
            end
        end
    end

    if shouldAim then
        local targetPos, targetPart = getTarget()
        if targetPos then
            local mousePos = UserInputService:GetMouseLocation()
            local dx = (targetPos.X - mousePos.X) * SETTINGS.Aimbot.Sensitivity
            local dy = (targetPos.Y - mousePos.Y) * SETTINGS.Aimbot.Sensitivity
            if mousemoverel then
                mousemoverel(dx / (SETTINGS.Aimbot.Smoothness * 10), dy / (SETTINGS.Aimbot.Smoothness * 10))
            end
            
            if SETTINGS.Aimbot.AutoFire and mouse1click then
                if tick() - lastFire > 0.05 then
                    mouse1click()
                    lastFire = tick()
                end
            end
        else
            currentTargetPart = nil
        end
    else
        currentTargetPart = nil
    end
end)

-- // --- Modern UI System (Square Style) ---
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "WdymGamingAimbotUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 280, 0, 480)
MainFrame.Position = UDim2.new(0.02, 0, 0.5, -240)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BackgroundTransparency = 0.1
MainFrame.BorderSizePixel = 1
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 150)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true

local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundTransparency = 1
TopBar.BorderSizePixel = 0

local Title = Instance.new("TextLabel", TopBar)
Title.Name = "Title"
Title.Size = UDim2.new(1, -70, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.Text = "WdymGaming's Aimbot"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1

local CollapseBtn = Instance.new("TextButton", TopBar)
CollapseBtn.Size = UDim2.new(0, 30, 0, 30)
CollapseBtn.Position = UDim2.new(1, -65, 0, 5)
CollapseBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
CollapseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CollapseBtn.Font = Enum.Font.GothamBold
CollapseBtn.TextSize = 16
CollapseBtn.Text = "-"
CollapseBtn.BorderSizePixel = 0

local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Text = "X"
CloseBtn.BorderSizePixel = 0

local ScrollFrame = Instance.new("ScrollingFrame", MainFrame)
ScrollFrame.Size = UDim2.new(1, 0, 1, -40)
ScrollFrame.Position = UDim2.new(0, 0, 0, 40)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 150)

-- // UI Functionality
local isCollapsed = false
CollapseBtn.MouseButton1Click:Connect(function()
    isCollapsed = not isCollapsed
    CollapseBtn.Text = isCollapsed and "+" or "-"
    local targetSize = isCollapsed and UDim2.new(0, 280, 0, 40) or UDim2.new(0, 280, 0, 480)
    
    local tween = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize})
    tween:Play()
end)

local inputConnection
CloseBtn.MouseButton1Click:Connect(function()
    -- Полное отключение всех функций, аимбота, есп и биндов
    SETTINGS.Aimbot.Enabled = false
    SETTINGS.ESP.Enabled = false
    SETTINGS.Aimbot.AutoFire = false
    SETTINGS.Aimbot.WallCheck = false
    SETTINGS.Aimbot.StickToTarget = false
    
    cleanESP()
    
    if renderSteppedConnection then 
        renderSteppedConnection:Disconnect() 
    end
    if inputConnection then 
        inputConnection:Disconnect() 
    end
    if fovCircle then 
        fovCircle:Remove() 
    end
    
    ScreenGui:Destroy()
end)

local yPos = 10
local function updateScroll()
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPos + 20)
end

local function addSection(titleText)
    local section = Instance.new("TextLabel", ScrollFrame)
    section.Position = UDim2.new(0, 15, 0, yPos)
    section.Size = UDim2.new(1, -30, 0, 20)
    section.Text = titleText
    section.TextColor3 = Color3.fromRGB(150, 150, 150)
    section.Font = Enum.Font.GothamBold
    section.TextSize = 12
    section.TextXAlignment = Enum.TextXAlignment.Left
    section.BackgroundTransparency = 1
    yPos = yPos + 25
    updateScroll()
end

local function addButton(name, callback)
    local btn = Instance.new("TextButton", ScrollFrame)
    btn.Position = UDim2.new(0, 15, 0, yPos)
    btn.Size = UDim2.new(1, -30, 0, 25)
    btn.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
    btn.TextColor3 = Color3.fromRGB(15, 15, 20)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Text = name
    btn.BorderSizePixel = 0
    btn.MouseButton1Click:Connect(callback)
    yPos = yPos + 30
    updateScroll()
    return btn
end

local function addToggle(name, state, callback)
    local btn = Instance.new("TextButton", ScrollFrame)
    btn.Position = UDim2.new(0, 15, 0, yPos)
    btn.Size = UDim2.new(1, -30, 0, 25)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Text = "  " .. name
    btn.BorderSizePixel = 0
    
    local indicator = Instance.new("Frame", btn)
    indicator.Size = UDim2.new(0, 15, 0, 15)
    indicator.Position = UDim2.new(1, -25, 0.5, -7.5)
    indicator.BackgroundColor3 = state and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(255, 50, 50)
    indicator.BorderSizePixel = 0

    btn.MouseButton1Click:Connect(function()
        state = not state
        indicator.BackgroundColor3 = state and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(255, 50, 50)
        callback(state)
        SaveSettings()
    end)
    yPos = yPos + 30
    updateScroll()
    return btn
end

local function addDropdown(name, options, default, callback)
    local container = Instance.new("Frame", ScrollFrame)
    container.Position = UDim2.new(0, 15, 0, yPos)
    container.Size = UDim2.new(1, -30, 0, 25)
    container.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    container.BorderSizePixel = 0

    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Text = "  " .. name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1

    local current = default
    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(0.5, -10, 0.8, 0)
    btn.Position = UDim2.new(0.5, 5, 0.1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    btn.TextColor3 = Color3.fromRGB(0, 255, 150)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Text = current
    btn.BorderSizePixel = 0

    btn.MouseButton1Click:Connect(function()
        local nextIdx = table.find(options, current) % #options + 1
        current = options[nextIdx]
        btn.Text = current
        callback(current)
        SaveSettings()
    end)

    yPos = yPos + 30
    updateScroll()
end

local function addSlider(name, min, max, default, callback)
    local container = Instance.new("Frame", ScrollFrame)
    container.Position = UDim2.new(0, 15, 0, yPos)
    container.Size = UDim2.new(1, -30, 0, 45)
    container.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    container.BorderSizePixel = 0

    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(1, -10, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 2)
    label.Text = name .. ": " .. tostring(default)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1

    local inputBox = Instance.new("TextBox", container)
    inputBox.Size = UDim2.new(1, -20, 0, 18)
    inputBox.Position = UDim2.new(0, 10, 0, 22)
    inputBox.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    inputBox.TextColor3 = Color3.fromRGB(0, 255, 150)
    inputBox.Font = Enum.Font.GothamBold
    inputBox.TextSize = 12
    inputBox.Text = tostring(default)
    inputBox.ClearTextOnFocus = false
    inputBox.BorderSizePixel = 0

    inputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local val = tonumber(inputBox.Text)
            if val then
                val = math.clamp(val, min, max)
                inputBox.Text = tostring(val)
                callback(val)
                label.Text = name .. ": " .. val
                SaveSettings()
            end
        end
    end)

    yPos = yPos + 50
    updateScroll()
end

local function addCustomColorPicker()
    addSection("ESP Color (Custom RGB)")
    
    local colorPreview = Instance.new("Frame", ScrollFrame)
    colorPreview.Position = UDim2.new(0, 15, 0, yPos)
    colorPreview.Size = UDim2.new(1, -30, 0, 30)
    colorPreview.BackgroundColor3 = SETTINGS.ESP.Color
    colorPreview.BorderSizePixel = 1
    colorPreview.BorderColor3 = Color3.fromRGB(255, 255, 255)
    yPos = yPos + 35
    
    local function createColorSlider(labelTxt, defaultColor, colorUI, yOffset)
        local cLabel = Instance.new("TextLabel", ScrollFrame)
        cLabel.Position = UDim2.new(0, 15, 0, yOffset)
        cLabel.Size = UDim2.new(0.2, 0, 0, 20)
        cLabel.Text = labelTxt
        cLabel.TextColor3 = colorUI
        cLabel.Font = Enum.Font.GothamBold
        cLabel.TextSize = 12
        cLabel.BackgroundTransparency = 1
        cLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local cSlider = Instance.new("TextBox", ScrollFrame)
        cSlider.Position = UDim2.new(0.25, 0, 0, yOffset)
        cSlider.Size = UDim2.new(0.7, -20, 0, 20)
        cSlider.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        cSlider.TextColor3 = colorUI
        cSlider.Font = Enum.Font.GothamBold
        cSlider.TextSize = 12
        cSlider.Text = tostring(defaultColor)
        cSlider.BorderSizePixel = 0
        return cSlider
    end

    local rSlider = createColorSlider("R:", math.floor(SETTINGS.ESP.Color.R * 255), Color3.fromRGB(255, 100, 100), yPos)
    yPos = yPos + 25
    local gSlider = createColorSlider("G:", math.floor(SETTINGS.ESP.Color.G * 255), Color3.fromRGB(100, 255, 100), yPos)
    yPos = yPos + 25
    local bSlider = createColorSlider("B:", math.floor(SETTINGS.ESP.Color.B * 255), Color3.fromRGB(100, 100, 255), yPos)
    yPos = yPos + 30
    
    local function updateColor()
        local r = math.clamp(tonumber(rSlider.Text) or 0, 0, 255) / 255
        local g = math.clamp(tonumber(gSlider.Text) or 0, 0, 255) / 255
        local b = math.clamp(tonumber(bSlider.Text) or 0, 0, 255) / 255
        local newColor = Color3.new(r, g, b)
        SETTINGS.ESP.Color = newColor
        colorPreview.BackgroundColor3 = newColor
        if fovCircle then 
            fovCircle.Color = newColor 
        end
        SaveSettings()
    end
    
    rSlider.FocusLost:Connect(function(enter) if enter then updateColor() end end)
    gSlider.FocusLost:Connect(function(enter) if enter then updateColor() end end)
    bSlider.FocusLost:Connect(function(enter) if enter then updateColor() end end)
    updateScroll()
end

local function addBindButton(name, currentKey, callback)
    local btn = Instance.new("TextButton", ScrollFrame)
    btn.Position = UDim2.new(0, 15, 0, yPos)
    btn.Size = UDim2.new(1, -30, 0, 25)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Text = name .. ": [" .. tostring(currentKey):gsub("Enum.KeyCode.", ""):gsub("Enum.UserInputType.", "") .. "]"
    btn.BorderSizePixel = 0
    
    local waitingForBind = false

    btn.MouseButton1Click:Connect(function()
        if waitingForBind then return end
        waitingForBind = true
        local originalText = btn.Text
        btn.Text = name .. ": [PRESS ANY KEY]"
        btn.TextColor3 = Color3.fromRGB(255, 255, 0)
        
        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if not waitingForBind then return end
            
            if input.KeyCode == Enum.KeyCode.Unknown and input.UserInputType == Enum.UserInputType.None then
                return
            end
            
            local newKey = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode or input.UserInputType
            callback(newKey)
            SaveSettings()
            
            local keyName = tostring(newKey):gsub("Enum.KeyCode.", ""):gsub("Enum.UserInputType.", "")
            btn.Text = name .. ": [" .. keyName .. "]"
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            waitingForBind = false
            conn:Disconnect()
        end)
        
        task.delay(5, function()
            if waitingForBind then
                btn.Text = originalText
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                waitingForBind = false
                if conn then conn:Disconnect() end
            end
        end)
    end)
    yPos = yPos + 30
    updateScroll()
end

-- // --- Build UI ---
addSection("Aimbot Settings")
addDropdown("Mode", {"Hold", "Toggle", "Always"}, SETTINGS.Aimbot.Mode, function(val)
    SETTINGS.Aimbot.Mode = val
    SETTINGS.Aimbot.ActiveToggle = false
end)
addDropdown("Aim Part", {"Head", "RootPart", "All"}, SETTINGS.Aimbot.AimPart, function(val)
    SETTINGS.Aimbot.AimPart = val
end)
addToggle("Stick To Target", SETTINGS.Aimbot.StickToTarget, function(state) SETTINGS.Aimbot.StickToTarget = state end)
addToggle("Wall Check", SETTINGS.Aimbot.WallCheck, function(state) SETTINGS.Aimbot.WallCheck = state end)
addToggle("Auto Fire", SETTINGS.Aimbot.AutoFire, function(state) SETTINGS.Aimbot.AutoFire = state end)
addSlider("FOV Radius", 10, 500, SETTINGS.Aimbot.FOV, function(val)
    SETTINGS.Aimbot.FOV = val
end)
addSlider("Smoothness", 0.1, 1.0, SETTINGS.Aimbot.Smoothness, function(val)
    SETTINGS.Aimbot.Smoothness = val
end)

addSection("ESP Settings")
addButton("Refresh ESP (Update Players)", function()
    cleanESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            createESP(p)
        end
    end
end)
addToggle("Enable ESP", SETTINGS.ESP.Enabled, function(state) SETTINGS.ESP.Enabled = state end)
addToggle("Show Name", SETTINGS.ESP.ShowName, function(state) SETTINGS.ESP.ShowName = state end)
addToggle("Show Username", SETTINGS.ESP.ShowUsername, function(state) SETTINGS.ESP.ShowUsername = state end)
addToggle("Show HP", SETTINGS.ESP.ShowHP, function(state) SETTINGS.ESP.ShowHP = state end)
addToggle("Show Distance", SETTINGS.ESP.ShowDistance, function(state) SETTINGS.ESP.ShowDistance = state end)
addCustomColorPicker()

addSection("Keybinds (Click to rebind)")
addBindButton("Aimbot Key", SETTINGS.Aimbot.Keybind, function(key) SETTINGS.Aimbot.Keybind = key end)
addBindButton("Toggle Aimbot", SETTINGS.Keybinds.ToggleAimbot, function(key) SETTINGS.Keybinds.ToggleAimbot = key end)
addBindButton("Toggle ESP", SETTINGS.Keybinds.ToggleESP, function(key) SETTINGS.Keybinds.ToggleESP = key end)
addBindButton("Toggle Menu", SETTINGS.Keybinds.ToggleMenu, function(key) SETTINGS.Keybinds.ToggleMenu = key end)

MainFrame.Visible = SETTINGS.MenuOpen

-- // --- Global Keybind Listener ---
inputConnection = UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    if input.KeyCode == SETTINGS.Keybinds.ToggleMenu then
        SETTINGS.MenuOpen = not SETTINGS.MenuOpen
        MainFrame.Visible = SETTINGS.MenuOpen
    end

    if input.KeyCode == SETTINGS.Keybinds.ToggleAimbot then
        SETTINGS.Aimbot.Enabled = not SETTINGS.Aimbot.Enabled
    end

    if input.KeyCode == SETTINGS.Keybinds.ToggleESP then
        SETTINGS.ESP.Enabled = not SETTINGS.ESP.Enabled
    end

    if SETTINGS.Aimbot.Mode == "Toggle" then
        local aimKey = SETTINGS.Aimbot.Keybind
        if input.KeyCode == aimKey or input.UserInputType == aimKey then
            SETTINGS.Aimbot.ActiveToggle = not SETTINGS.Aimbot.ActiveToggle
        end
    end
end)

-- Initialize ESP
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer and p.Character then
        createESP(p)
    end
end