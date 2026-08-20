-- ============================================================
-- AimModule.lua
-- ============================================================
-- Модуль Aim: LegitBot, Ragebot, ESP, Keybinds.
-- Использует FuckYouLib.
-- ============================================================

local FuckYouLib = _G.FuckYouLib
if not FuckYouLib then error("FuckYouLibrary not loaded") end

local COL_BORDER = FuckYouLib.COL_BORDER
local FONT = FuckYouLib.FONT

local F_R = FONT
local F_B = FONT
local F_S = FONT

local AIM_AUTO_FILE = "EmilyUi/FuckYou/AimSettings.json"

local function ensureAimDirs()
    if makefolder then
        pcall(function()
            if not isfolder("EmilyUi") then makefolder("EmilyUi") end
            if not isfolder("EmilyUi/FuckYou") then makefolder("EmilyUi/FuckYou") end
        end)
    end
end

local Legit = {
    Enabled = false,
    Mode = "Hold",
    AimPart = "All",
    StickToTarget = false,
    WallCheck = false,
    TeamCheck = true,
    DrawFOV = true,
    FOV = 150,
    Smoothness = 0.20,
    Sensitivity = 0.45,
    ActiveToggle = false,
    TriggerMode = "Hold",
    TriggerTime = 0.08,
    TriggerPart = "All",
    TriggerActiveToggle = false,
    Keybind = Enum.UserInputType.MouseButton2,
    TriggerKey = Enum.KeyCode.LeftAlt,
}

local Rage = {
    Enabled = false,
    Mode = "Always",
    AimPart = "Head",
    Priority = "Closest",
    FOV = 360,
    WallCheck = true,
    TeamCheck = true,
    AutoFire = true,
    FireDelay = 0.05,
    FireAngle = 5,
    Smoothness = 0.10,
    Prediction = 0.0,
    MaxDistance = 0,
    ActiveToggle = false,
    Keybind = Enum.UserInputType.MouseButton2,
}

local ESPSettings = {
    Enabled = false,
    Color = Color3.fromRGB(0,255,150),
    ShowName = true,
    ShowUsername = true,
    ShowHP = true,
    ShowDistance = true,
}

local Keybinds = {
    ToggleLegitBot = Enum.KeyCode.G,
    ToggleRagebot = Enum.KeyCode.H,
}

local KEYCODE_BY_NAME = {}
for _, e in ipairs(Enum.KeyCode:GetEnumItems()) do KEYCODE_BY_NAME[e.Name] = e end
local INPUTTYPE_BY_NAME = {}
for _, e in ipairs(Enum.UserInputType:GetEnumItems()) do INPUTTYPE_BY_NAME[e.Name] = e end

local function getEnumByName(name)
    if not name or name == "" then return nil end
    return KEYCODE_BY_NAME[name] or INPUTTYPE_BY_NAME[name]
end

local function enumKeyName(v)
    if typeof(v) == "EnumItem" then return v.Name end
    return ""
end

local function displayKeyName(v)
    if typeof(v) == "EnumItem" then return v.Name end
    return "None"
end

local function gatherAimConfig()
    return {
        Version = 2,
        Legit = {
            Enabled = Legit.Enabled,
            Mode = Legit.Mode,
            AimPart = Legit.AimPart,
            StickToTarget = Legit.StickToTarget,
            WallCheck = Legit.WallCheck,
            TeamCheck = Legit.TeamCheck,
            DrawFOV = Legit.DrawFOV,
            FOV = Legit.FOV,
            Smoothness = Legit.Smoothness,
            Sensitivity = Legit.Sensitivity,
            TriggerMode = Legit.TriggerMode,
            TriggerTime = Legit.TriggerTime,
            TriggerPart = Legit.TriggerPart,
            Keybind = enumKeyName(Legit.Keybind),
            TriggerKey = enumKeyName(Legit.TriggerKey),
        },
        Rage = {
            Enabled = Rage.Enabled,
            Mode = Rage.Mode,
            AimPart = Rage.AimPart,
            Priority = Rage.Priority,
            FOV = Rage.FOV,
            WallCheck = Rage.WallCheck,
            TeamCheck = Rage.TeamCheck,
            AutoFire = Rage.AutoFire,
            FireDelay = Rage.FireDelay,
            FireAngle = Rage.FireAngle,
            Smoothness = Rage.Smoothness,
            Prediction = Rage.Prediction,
            MaxDistance = Rage.MaxDistance,
            Keybind = enumKeyName(Rage.Keybind),
        },
        ESP = {
            Enabled = ESPSettings.Enabled,
            Color = {math.floor(ESPSettings.Color.R*255+0.5), math.floor(ESPSettings.Color.G*255+0.5), math.floor(ESPSettings.Color.B*255+0.5)},
            ShowName = ESPSettings.ShowName,
            ShowUsername = ESPSettings.ShowUsername,
            ShowHP = ESPSettings.ShowHP,
            ShowDistance = ESPSettings.ShowDistance,
        },
        Keybinds = {
            ToggleLegitBot = enumKeyName(Keybinds.ToggleLegitBot),
            ToggleRagebot = enumKeyName(Keybinds.ToggleRagebot),
        },
    }
end

local function saveAimAuto()
    if writefile then
        ensureAimDirs()
        pcall(function() writefile(AIM_AUTO_FILE, HttpService:JSONEncode(gatherAimConfig())) end)
    end
    if FuckYouLib.autoSaveConfig then FuckYouLib.autoSaveConfig() end
end

local fovCircle = nil
if Drawing then
    fovCircle = Drawing.new("Circle")
    fovCircle.Visible = false
    fovCircle.Thickness = 2
    fovCircle.Color = ESPSettings.Color
    fovCircle.Filled = false
end

local ESP_Instances = {}
local currentTargetPart = nil
local triggerTargetPart = nil
local triggerFirstSeen = 0
local lastTriggerShot = 0
local rageTargetPart = nil
local rageFirstSeen = 0
local lastRageFire = 0

local aimInputConnection = nil
local mainLoopConnection = nil

local setESPEnabled
local refreshAimUI
local refreshSidebarTexts

local uiRefreshers = {}
local function addRefresh(fn) table.insert(uiRefreshers, fn) end

-- ESP functions
local function removeESPForPlayer(player)
    local data = ESP_Instances[player]
    if not data then return end
    pcall(function()
        if data.Highlight then data.Highlight:Destroy() end
        if data.BillboardTop then data.BillboardTop:Destroy() end
        if data.BillboardBottom then data.BillboardBottom:Destroy() end
    end)
    ESP_Instances[player] = nil
end

local function cleanESP()
    for player in pairs(ESP_Instances) do
        removeESPForPlayer(player)
    end
end

local function createESP(player)
    if not player or not player.Character then return end
    local character = player.Character
    local root = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then return end
    removeESPForPlayer(player)
    local highlight = Instance.new("Highlight")
    highlight.Name = "AimbotESP_Highlight"
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = ESPSettings.Color
    highlight.FillTransparency = 0.7
    highlight.OutlineColor = Color3.new(1,1,1)
    highlight.OutlineTransparency = 0.5
    highlight.Parent = character
    local billboardTop = Instance.new("BillboardGui")
    billboardTop.Name = "AimbotESP_Top"
    billboardTop.Adornee = root
    billboardTop.Size = UDim2.new(0,200,0,60)
    billboardTop.StudsOffset = Vector3.new(0,3.5,0)
    billboardTop.AlwaysOnTop = true
    billboardTop.Parent = character
    local textTop = Instance.new("TextLabel", billboardTop)
    textTop.Size = UDim2.new(1,0,1,0)
    textTop.BackgroundTransparency = 1
    textTop.TextColor3 = ESPSettings.Color
    textTop.TextSize = 13
    textTop.Font = Enum.Font.GothamBold
    textTop.TextStrokeTransparency = 0.5
    textTop.TextYAlignment = Enum.TextYAlignment.Bottom
    local billboardBottom = Instance.new("BillboardGui")
    billboardBottom.Name = "AimbotESP_Bottom"
    billboardBottom.Adornee = root
    billboardBottom.Size = UDim2.new(0,200,0,40)
    billboardBottom.StudsOffset = Vector3.new(0,-3,0)
    billboardBottom.AlwaysOnTop = true
    billboardBottom.Parent = character
    local textBottom = Instance.new("TextLabel", billboardBottom)
    textBottom.Size = UDim2.new(1,0,1,0)
    textBottom.BackgroundTransparency = 1
    textBottom.TextColor3 = ESPSettings.Color
    textBottom.TextSize = 13
    textBottom.Font = Enum.Font.GothamBold
    textBottom.TextStrokeTransparency = 0.5
    textBottom.TextYAlignment = Enum.TextYAlignment.Top
    ESP_Instances[player] = {
        Highlight = highlight,
        TextTop = textTop,
        TextBottom = textBottom,
        BillboardTop = billboardTop,
        BillboardBottom = billboardBottom,
    }
end

local function updateESP()
    for player, instances in pairs(ESP_Instances) do
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if root and humanoid then
            instances.Highlight.FillColor = ESPSettings.Color
            instances.TextTop.TextColor3 = ESPSettings.Color
            instances.TextBottom.TextColor3 = ESPSettings.Color
            local topInfo = {}
            if ESPSettings.ShowName then table.insert(topInfo, player.DisplayName) end
            if ESPSettings.ShowUsername then table.insert(topInfo, "@" .. player.Name) end
            instances.TextTop.Text = table.concat(topInfo, " | ")
            local bottomInfo = {}
            if ESPSettings.ShowHP then
                table.insert(bottomInfo, string.format("HP: %d/%d", math.max(0, math.floor(humanoid.Health)), math.floor(humanoid.MaxHealth)))
            end
            if ESPSettings.ShowDistance and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local dist = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude)
                table.insert(bottomInfo, dist .. "m")
            end
            instances.TextBottom.Text = table.concat(bottomInfo, " | ")
            local enabled = ESPSettings.Enabled
            instances.Highlight.Enabled = enabled
            instances.BillboardTop.Enabled = enabled and (#topInfo > 0)
            instances.BillboardBottom.Enabled = enabled and (#bottomInfo > 0)
        else
            if instances.BillboardTop then instances.BillboardTop.Enabled = false end
            if instances.BillboardBottom then instances.BillboardBottom.Enabled = false end
            if instances.Highlight then instances.Highlight.Enabled = false end
        end
    end
end

local function hookESPCharacter(player)
    player.CharacterAdded:Connect(function()
        if ESPSettings.Enabled then
            .wait(0.5)
            removeESPForPlayer(player)
            createESP(player)
            updateESP()
        end
    end)
end

for _, plr in ipairs(Players:GetPlayers()) do hookESPCharacter(plr) end
Players.PlayerAdded:Connect(hookESPCharacter)
Players.PlayerRemoving:Connect(removeESPForPlayer)

-- Input helpers
local function sameInput(input, bind)
    if bind == nil or typeof(bind) ~= "EnumItem" then return false end
    if bind.EnumType == Enum.KeyCode then return input.KeyCode == bind end
    if bind.EnumType == Enum.UserInputType then return input.UserInputType == bind end
    return false
end

local function isBindDown(bind)
    if bind == nil or typeof(bind) ~= "EnumItem" then return false end
    if bind.EnumType == Enum.KeyCode then return UserInputService:IsKeyDown(bind) end
    if bind.EnumType == Enum.UserInputType then return UserInputService:IsMouseButtonPressed(bind) end
    return false
end

local function isAlive(player)
    local character = player and player.Character
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    return humanoid and root and humanoid.Health > 0
end

local function isSameTeamAsLocal(player)
    if LocalPlayer.Team ~= nil and player.Team ~= nil then
        return LocalPlayer.Team == player.Team
    end
    return false
end

local function getAimParts(character, mode)
    local parts = {}
    if not character then return parts end
    if mode == "Head" then
        local head = character:FindFirstChild("Head")
        if head then table.insert(parts, head) end
    elseif mode == "RootPart" then
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then table.insert(parts, root) end
    else
        for _, partName in ipairs({"Head", "HumanoidRootPart", "UpperTorso", "Torso", "LowerTorso"}) do
            local part = character:FindFirstChild(partName)
            if part then table.insert(parts, part) end
        end
    end
    return parts
end

local function isVisible(part, targetPos)
    if not part then return false end
    local camera = workspace.CurrentCamera
    if not camera then return true end
    local origin = camera.CFrame.Position
    local pos = targetPos or part.Position
    local direction = pos - origin
    if direction.Magnitude < 0.1 then return true end
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character, camera}
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    local result = workspace:Raycast(origin, direction, params)
    if result and result.Instance then
        return result.Instance:IsDescendantOf(part.Parent or workspace)
    end
    return true
end

local function shouldLegitAim()
    if not Legit.Enabled then return false end
    if Legit.Mode == "Always" then return true
    elseif Legit.Mode == "Toggle" then return Legit.ActiveToggle
    elseif Legit.Mode == "Hold" then return isBindDown(Legit.Keybind) end
    return false
end

local function shouldTrigger()
    if not Legit.Enabled then return false end
    if Legit.TriggerMode == "Always" then return true
    elseif Legit.TriggerMode == "Toggle" then return Legit.TriggerActiveToggle
    elseif Legit.TriggerMode == "Hold" then return isBindDown(Legit.TriggerKey) end
    return false
end

local function shouldRageAim()
    if not Rage.Enabled then return false end
    if Rage.Mode == "Always" then return true
    elseif Rage.Mode == "Toggle" then return Rage.ActiveToggle
    elseif Rage.Mode == "Hold" then return isBindDown(Rage.Keybind) end
    return false
end

local function moveMouseRelative(x, y)
    if mousemoverel then mousemoverel(x, y)
    elseif mousemoveRelative then mousemoveRelative(x, y) end
end

local function getLegitTarget()
    local camera = workspace.CurrentCamera
    if not camera then return nil, nil end
    local mouse = UserInputService:GetMouseLocation()
    if Legit.StickToTarget and currentTargetPart and currentTargetPart.Parent then
        local humanoid = currentTargetPart.Parent:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 then
            local screenPos, onScreen = camera:WorldToViewportPoint(currentTargetPart.Position)
            if onScreen then
                local mag = (Vector2.new(screenPos.X, screenPos.Y) - mouse).Magnitude
                if mag <= Legit.FOV and isVisible(currentTargetPart) then
                    return screenPos, currentTargetPart
                end
            end
        end
        currentTargetPart = nil
    end
    local bestPos = nil
    local bestPart = nil
    local bestDist = Legit.FOV
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isAlive(player) and (not Legit.TeamCheck or not isSameTeamAsLocal(player)) then
            for _, part in ipairs(getAimParts(player.Character, Legit.AimPart)) do
                local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local mag = (Vector2.new(screenPos.X, screenPos.Y) - mouse).Magnitude
                    if mag < bestDist and isVisible(part) then
                        bestDist = mag
                        bestPos = screenPos
                        bestPart = part
                    end
                end
            end
        end
    end
    if bestPart then currentTargetPart = bestPart end
    return bestPos, bestPart
end

local function getTriggerTarget()
    local camera = workspace.CurrentCamera
    if not camera then return nil end
    local mouse = UserInputService:GetMouseLocation()
    local bestPart = nil
    local bestDist = 20
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isAlive(player) and (not Legit.TeamCheck or not isSameTeamAsLocal(player)) then
            for _, part in ipairs(getAimParts(player.Character, Legit.TriggerPart)) do
                local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local mag = (Vector2.new(screenPos.X, screenPos.Y) - mouse).Magnitude
                    if mag < bestDist and isVisible(part) then
                        bestDist = mag
                        bestPart = part
                    end
                end
            end
        end
    end
    return bestPart
end

local function getRageTarget()
    local camera = workspace.CurrentCamera
    if not camera then return nil end
    local camCF = camera.CFrame
    local best = nil
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isAlive(player) and (not Rage.TeamCheck or not isSameTeamAsLocal(player)) then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            for _, part in ipairs(getAimParts(player.Character, Rage.AimPart)) do
                local velocity = Vector3.zero
                pcall(function() velocity = part.AssemblyLinearVelocity or Vector3.zero end)
                local predictedPos = part.Position + velocity * Rage.Prediction
                local offset = predictedPos - camCF.Position
                local dist = offset.Magnitude
                if dist > 0.01 and (Rage.MaxDistance <= 0 or dist <= Rage.MaxDistance) then
                    local dot = math.clamp(camCF.LookVector:Dot(offset.Unit), -1, 1)
                    local angle = math.deg(math.acos(dot))
                    if Rage.FOV >= 360 or angle <= (Rage.FOV / 2) then
                        if (not Rage.WallCheck) or isVisible(part, predictedPos) then
                            local score = angle
                            if Rage.Priority == "Closest" then score = dist
                            elseif Rage.Priority == "Health" then score = humanoid and humanoid.Health or 999999 end
                            if not best or score < best.score then
                                best = { part = part, pos = predictedPos, angle = angle, dist = dist, score = score, humanoid = humanoid }
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

local function setLegitEnabled(v)
    v = v and true or false
    if Legit.Enabled == v then return end
    if v and Rage.Enabled then
        Rage.Enabled = false
        Rage.ActiveToggle = false
    end
    Legit.Enabled = v
    if not Legit.Enabled then
        Legit.ActiveToggle = false
        Legit.TriggerActiveToggle = false
        currentTargetPart = nil
        triggerTargetPart = nil
        triggerFirstSeen = 0
    end
    if refreshAimUI then refreshAimUI() end
    saveAimAuto()
end

local function setRageEnabled(v)
    v = v and true or false
    if Rage.Enabled == v then return end
    if v and Legit.Enabled then
        Legit.Enabled = false
        Legit.ActiveToggle = false
        Legit.TriggerActiveToggle = false
        currentTargetPart = nil
        triggerTargetPart = nil
        triggerFirstSeen = 0
    end
    Rage.Enabled = v
    if not Rage.Enabled then
        Rage.ActiveToggle = false
        rageTargetPart = nil
        rageFirstSeen = 0
    end
    if refreshAimUI then refreshAimUI() end
    saveAimAuto()
end

setESPEnabled = function(state)
    ESPSettings.Enabled = state and true or false
    if ESPSettings.Enabled then
        cleanESP()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then createESP(player) end
        end
        updateESP()
    else
        cleanESP()
    end
    if refreshAimUI then refreshAimUI() end
    saveAimAuto()
end

local function ensureMainLoop()
    if mainLoopConnection then return end
    mainLoopConnection = RunService.RenderStepped:Connect(function()
        local camera = workspace.CurrentCamera
        if fovCircle then
            fovCircle.Visible = Legit.Enabled and Legit.DrawFOV
            fovCircle.Radius = Legit.FOV
            fovCircle.Position = UserInputService:GetMouseLocation()
            fovCircle.Color = ESPSettings.Color
        end
        if ESPSettings.Enabled and tick() % 0.1 < 0.02 then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and not ESP_Instances[player] and player.Character then
                    createESP(player)
                end
            end
            updateESP()
        end
        if Rage.Enabled and Legit.Enabled then
            Legit.Enabled = false
            if refreshSidebarTexts then refreshSidebarTexts() end
        end
        if Legit.Enabled and not Rage.Enabled then
            if shouldLegitAim() then
                local targetPos, targetPart = getLegitTarget()
                if targetPos then
                    currentTargetPart = targetPart
                    local mousePos = UserInputService:GetMouseLocation()
                    local dx = (targetPos.X - mousePos.X) * Legit.Sensitivity
                    local dy = (targetPos.Y - mousePos.Y) * Legit.Sensitivity
                    local divisor = math.clamp(Legit.Smoothness, 0.1, 1) * 10
                    moveMouseRelative(dx / divisor, dy / divisor)
                else
                    currentTargetPart = nil
                end
            else
                currentTargetPart = nil
            end
            if shouldTrigger() then
                local triggerPart = getTriggerTarget()
                if triggerPart and isVisible(triggerPart) then
                    if triggerTargetPart ~= triggerPart then
                        triggerTargetPart = triggerPart
                        triggerFirstSeen = tick()
                    end
                    if tick() - triggerFirstSeen >= Legit.TriggerTime and tick() - lastTriggerShot > 0.05 then
                        if mouse1click then mouse1click() end
                        lastTriggerShot = tick()
                    end
                else
                    triggerTargetPart = nil
                    triggerFirstSeen = 0
                end
            else
                triggerTargetPart = nil
                triggerFirstSeen = 0
            end
        else
            currentTargetPart = nil
            triggerTargetPart = nil
            triggerFirstSeen = 0
        end
        if Rage.Enabled and not Legit.Enabled then
            if shouldRageAim() then
                local target = getRageTarget()
                if target then
                    if camera then
                        local desired = CFrame.lookAt(camera.CFrame.Position, target.pos)
                        local smooth = math.clamp(Rage.Smoothness, 0, 0.95)
                        if smooth <= 0.01 then camera.CFrame = desired
                        else camera.CFrame = camera.CFrame:Lerp(desired, 1 - smooth) end
                    end
                    if Rage.AutoFire then
                        if rageTargetPart ~= target.part then
                            rageTargetPart = target.part
                            rageFirstSeen = tick()
                        end
                        if target.angle <= Rage.FireAngle and tick() - rageFirstSeen >= Rage.FireDelay and tick() - lastRageFire > 0.03 then
                            if mouse1click then mouse1click() end
                            lastRageFire = tick()
                        end
                    end
                else
                    rageTargetPart = nil
                    rageFirstSeen = 0
                end
            else
                rageTargetPart = nil
                rageFirstSeen = 0
            end
        else
            rageTargetPart = nil
            rageFirstSeen = 0
        end
    end)
end

local function startKeybindListener()
    if aimInputConnection then aimInputConnection:Disconnect() end
    aimInputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if sameInput(input, Keybinds.ToggleLegitBot) then
            setLegitEnabled(not Legit.Enabled)
        end
        if sameInput(input, Keybinds.ToggleRagebot) then
            setRageEnabled(not Rage.Enabled)
        end
        if Legit.Mode == "Toggle" and sameInput(input, Legit.Keybind) then
            Legit.ActiveToggle = not Legit.ActiveToggle
        end
        if Legit.TriggerMode == "Toggle" and sameInput(input, Legit.TriggerKey) then
            Legit.TriggerActiveToggle = not Legit.TriggerActiveToggle
        end
        if Rage.Mode == "Toggle" and sameInput(input, Rage.Keybind) then
            Rage.ActiveToggle = not Rage.ActiveToggle
        end
    end)
end

-- UI helpers
local function corner(parent) Instance.new("UICorner", parent).CornerRadius = UDim.new(0,4) end
local function mkLabel(parent, text, size, position, font, textSize)
    local label = Instance.new("TextLabel")
    label.Parent = parent
    label.Text = text
    label.Size = size
    label.Position = position
    label.Font = font or F_S
    label.TextSize = textSize or 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = FuckYouLib.uiColor_TextColor
    label.BackgroundTransparency = 1
    label.TextWrapped = true
    table.insert(FuckYouLib.themeElements.Texts, label)
    return label
end
local function mkBox(parent, text, size, position, textSize)
    local box = Instance.new("TextBox")
    box.Parent = parent
    box.Text = text or ""
    box.Size = size
    box.Position = position
    box.Font = F_R
    box.TextSize = textSize or 13
    box.BackgroundColor3 = FuckYouLib.uiColor_TextBoxColor
    box.TextColor3 = FuckYouLib.uiColor_TextColor
    box.PlaceholderColor3 = Color3.fromRGB(90,90,90)
    box.BorderSizePixel = 0
    box.ClearTextOnFocus = false
    box.BackgroundTransparency = 1 - FuckYouLib.uiGuiOpacity
    table.insert(FuckYouLib.themeElements.TextBoxes, box)
    table.insert(FuckYouLib.themeElements.Texts, box)
    corner(box)
    return box
end
local function mkBtn(parent, text, size, position, font, textSize, themed, bgColor, textColor)
    local button = Instance.new("TextButton")
    button.Parent = parent
    button.Text = text or ""
    button.Size = size
    button.Position = position
    button.Font = font or F_B
    button.TextSize = textSize or 13
    button.TextWrapped = true
    button.BackgroundColor3 = bgColor or FuckYouLib.uiColor_ButtonColor
    button.TextColor3 = textColor or FuckYouLib.uiColor_TextColor
    button.BorderSizePixel = 0
    button.BackgroundTransparency = 1 - FuckYouLib.uiGuiOpacity
    if themed ~= "no" then
        table.insert(FuckYouLib.themeElements.Buttons, button)
        table.insert(FuckYouLib.themeElements.Texts, button)
    else
        table.insert(FuckYouLib.themeElements.CustomButtons, button)
    end
    corner(button)
    return button
end
local function mkPanel(parent, size, position)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Size = size
    frame.Position = position or UDim2.new(0,0,0,0)
    frame.BackgroundColor3 = FuckYouLib.uiColor_SideBar
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    table.insert(FuckYouLib.themeElements.SideBars, frame)
    corner(frame)
    return frame
end

local aimTabs = {}
local function addAimTab(name, builder)
    local frame = FuckYouLib.create("Frame", {Name = "Tab" .. name, Parent = FuckYouLib.Containment, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false})
    builder(frame)
    local button = FuckYouLib.create("TextButton", {Name = "ABtn_" .. name, Parent = FuckYouLib.MenuInsided, Size = UDim2.new(1,0,0,40), LayoutOrder = 300 + #aimTabs, Visible = false, BackgroundColor3 = FuckYouLib.uiColor_ButtonColor, BorderColor3 = COL_BORDER, TextColor3 = FuckYouLib.uiColor_TextColor, Text = name, Font = FONT, TextSize = 12, TextWrapped = true})
    local entry = {Frame = frame, Name = name, Button = button}
    table.insert(aimTabs, entry)
    table.insert(FuckYouLib.themeElements.Buttons, button)
    table.insert(FuckYouLib.themeElements.Texts, button)
    return entry
end

-- Setting rows
local function mkToggleRow(parent, labelText, y, get, set, noSave)
    local button = mkBtn(parent, "", UDim2.new(1,-24,0,28), UDim2.new(0,12,0,y), F_B, 13)
    local function refresh()
        button.Text = labelText .. ": " .. (get() and "ON" or "OFF")
        FuckYouLib.paintToggleBtn(button, get())
    end
    FuckYouLib.registerToggle(button, get)
    button.MouseButton1Click:Connect(function()
        set(not get())
        pcall(refresh)
        if not noSave then saveAimAuto() end
    end)
    addRefresh(refresh)
    refresh()
    return {Button = button, Refresh = refresh}
end

local function mkDropdownRow(parent, labelText, options, y, get, set)
    local button = mkBtn(parent, "", UDim2.new(1,-24,0,28), UDim2.new(0,12,0,y), F_B, 13)
    local function refresh()
        button.Text = labelText .. ": " .. tostring(get())
    end
    button.MouseButton1Click:Connect(function()
        local index = table.find(options, get()) or 0
        set(options[(index % #options) + 1])
        refresh()
        saveAimAuto()
    end)
    addRefresh(refresh)
    refresh()
    return {Button = button, Refresh = refresh}
end

local function mkNumRow(parent, labelText, y, get, set, min, max, decimals)
    local container = FuckYouLib.create("Frame", {Parent = parent, Size = UDim2.new(1,-24,0,46), Position = UDim2.new(0,12,0,y), BackgroundTransparency = 1})
    local label = FuckYouLib.create("TextLabel", {Parent = container, Size = UDim2.new(1,0,0,18), BackgroundTransparency = 1, Text = labelText, TextColor3 = FuckYouLib.uiColor_TextColor, TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true})
    table.insert(FuckYouLib.themeElements.Texts, label)
    local box = FuckYouLib.create("TextBox", {Parent = container, Size = UDim2.new(1,0,0,24), Position = UDim2.new(0,0,0,20), BackgroundColor3 = FuckYouLib.uiColor_TextBoxColor, BorderColor3 = COL_BORDER, TextColor3 = FuckYouLib.uiColor_TextColor, PlaceholderColor3 = Color3.fromRGB(90,90,90), Text = tostring(get()), TextSize = 13, Font = FONT, ClearTextOnFocus = false, BackgroundTransparency = 1 - FuckYouLib.uiGuiOpacity})
    table.insert(FuckYouLib.themeElements.TextBoxes, box)
    table.insert(FuckYouLib.themeElements.Texts, box)
    local function refresh()
        local value = get()
        if decimals and decimals > 0 then
            label.Text = labelText .. " [" .. string.format("%." .. tostring(decimals) .. "f", value) .. "]"
        else
            label.Text = labelText .. " [" .. tostring(value) .. "]"
        end
        box.Text = tostring(value)
    end
    box.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local value = tonumber(box.Text)
            if value then
                if decimals and decimals > 0 then
                    local step = 10 ^ (-decimals)
                    value = math.floor(value / step + 0.5) * step
                end
                set(math.clamp(value, min, max))
            end
        end
        refresh()
        saveAimAuto()
    end)
    addRefresh(refresh)
    refresh()
    return {Frame = container, Refresh = refresh}
end

local function mkBindRow(parent, labelText, y, get, set)
    local button = mkBtn(parent, "", UDim2.new(1,-24,0,28), UDim2.new(0,12,0,y), F_B, 13)
    local waiting = false
    local function refresh()
        button.Text = labelText .. ": [" .. displayKeyName(get()) .. "]"
        button.TextColor3 = FuckYouLib.uiColor_TextColor
    end
    button.MouseButton1Click:Connect(function()
        if waiting then return end
        waiting = true
        button.Text = labelText .. ": [PRESS ANY KEY | BACKSPACE = CLEAR]"
        button.TextColor3 = Color3.fromRGB(255,255,0)
        local connection
        connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if not waiting then return end
            if input.KeyCode == Enum.KeyCode.Backspace then
                set(nil)
                refresh()
                saveAimAuto()
                if FuckYouLib.autoSaveConfig then FuckYouLib.autoSaveConfig(true) end
                waiting = false
                if connection then connection:Disconnect() end
                return
            end
            local newKey = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode or input.UserInputType
            if newKey == Enum.KeyCode.Unknown or newKey == Enum.UserInputType.None then return end
            set(newKey)
            refresh()
            saveAimAuto()
            if FuckYouLib.autoSaveConfig then FuckYouLib.autoSaveConfig(true) end
            waiting = false
            if connection then connection:Disconnect() end
        end)
        .delay(5, function()
            if waiting then
                waiting = false
                refresh()
                if connection then connection:Disconnect() end
            end
        end)
    end)
    addRefresh(refresh)
    refresh()
    return {Button = button, Refresh = refresh}
end

-- Tabs
local function buildLegitTab(parent)
    local scroll = FuckYouLib.create("ScrollingFrame", {Parent = parent, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0,0,0,700)})
    local inner = mkPanel(scroll, UDim2.new(1,0,0,700))
    local y = 10
    mkToggleRow(inner, "LegitBot", y, function() return Legit.Enabled end, function(v) setLegitEnabled(v) end, true)
    y = y + 34
    mkDropdownRow(inner, "Mode", {"Hold","Toggle","Always"}, y, function() return Legit.Mode end, function(v) Legit.Mode = v end)
    y = y + 34
    mkDropdownRow(inner, "Aim Part", {"All","Head","RootPart"}, y, function() return Legit.AimPart end, function(v) Legit.AimPart = v end)
    y = y + 34
    mkToggleRow(inner, "Stick To Target", y, function() return Legit.StickToTarget end, function(v) Legit.StickToTarget = v end)
    y = y + 34
    mkToggleRow(inner, "Wall Check", y, function() return Legit.WallCheck end, function(v) Legit.WallCheck = v end)
    y = y + 34
    mkToggleRow(inner, "Team Check", y, function() return Legit.TeamCheck end, function(v) Legit.TeamCheck = v end)
    y = y + 34
    mkToggleRow(inner, "Draw FOV", y, function() return Legit.DrawFOV end, function(v) Legit.DrawFOV = v end)
    y = y + 34
    mkNumRow(inner, "FOV Radius", y, function() return Legit.FOV end, function(v) Legit.FOV = v end, 10, 1000, 0)
    y = y + 52
    mkNumRow(inner, "Smoothness", y, function() return Legit.Smoothness end, function(v) Legit.Smoothness = v end, 0, 1, 2)
    y = y + 52
    mkNumRow(inner, "Sensitivity", y, function() return Legit.Sensitivity end, function(v) Legit.Sensitivity = v end, 0.05, 2, 2)
    y = y + 56
    mkLabel(inner, "Triggerbot", UDim2.new(1,-24,0,20), UDim2.new(0,12,0,y), F_S, 14)
    y = y + 24
    mkDropdownRow(inner, "Triggerbot Mode", {"Hold","Toggle","Always"}, y, function() return Legit.TriggerMode end, function(v) Legit.TriggerMode = v end)
    y = y + 34
    mkDropdownRow(inner, "Trigger Part", {"All","Head","RootPart"}, y, function() return Legit.TriggerPart end, function(v) Legit.TriggerPart = v end)
    y = y + 34
    mkNumRow(inner, "Triggerbot Time", y, function() return Legit.TriggerTime end, function(v) Legit.TriggerTime = v end, 0, 1, 2)
end

local function buildRageTab(parent)
    local scroll = FuckYouLib.create("ScrollingFrame", {Parent = parent, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0,0,0,780)})
    local inner = mkPanel(scroll, UDim2.new(1,0,0,780))
    local y = 10
    mkToggleRow(inner, "Ragebot", y, function() return Rage.Enabled end, function(v) setRageEnabled(v) end, true)
    y = y + 34
    mkDropdownRow(inner, "Mode", {"Always","Hold","Toggle"}, y, function() return Rage.Mode end, function(v) Rage.Mode = v end)
    y = y + 34
    mkDropdownRow(inner, "Aim Part", {"Head","RootPart","All"}, y, function() return Rage.AimPart end, function(v) Rage.AimPart = v end)
    y = y + 34
    mkDropdownRow(inner, "Priority", {"Closest","Angle","Health"}, y, function() return Rage.Priority end, function(v) Rage.Priority = v end)
    y = y + 34
    mkToggleRow(inner, "Wall Check", y, function() return Rage.WallCheck end, function(v) Rage.WallCheck = v end)
    y = y + 34
    mkToggleRow(inner, "Team Check", y, function() return Rage.TeamCheck end, function(v) Rage.TeamCheck = v end)
    y = y + 34
    mkToggleRow(inner, "Auto Fire", y, function() return Rage.AutoFire end, function(v) Rage.AutoFire = v end)
    y = y + 34
    mkNumRow(inner, "FOV Around Player", y, function() return Rage.FOV end, function(v) Rage.FOV = v end, 0, 360, 0)
    y = y + 52
    mkNumRow(inner, "Fire Angle", y, function() return Rage.FireAngle end, function(v) Rage.FireAngle = v end, 0, 45, 1)
    y = y + 52
    mkNumRow(inner, "Fire Delay", y, function() return Rage.FireDelay end, function(v) Rage.FireDelay = v end, 0, 1, 2)
    y = y + 52
    mkNumRow(inner, "Smoothness", y, function() return Rage.Smoothness end, function(v) Rage.Smoothness = v end, 0, 0.95, 2)
    y = y + 52
    mkNumRow(inner, "Prediction", y, function() return Rage.Prediction end, function(v) Rage.Prediction = v end, 0, 1, 2)
    y = y + 52
    mkNumRow(inner, "Max Distance (0 = unlimited)", y, function() return Rage.MaxDistance end, function(v) Rage.MaxDistance = v end, 0, 100000, 0)
end

local function buildESPTab(parent)
    local scroll = FuckYouLib.create("ScrollingFrame", {Parent = parent, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0,0,0,460)})
    local inner = mkPanel(scroll, UDim2.new(1,0,0,460))
    local y = 10
    local refreshBtn = mkBtn(inner, "Refresh ESP (Update Players)", UDim2.new(1,-24,0,28), UDim2.new(0,12,0,y), F_B, 13)
    refreshBtn.MouseButton1Click:Connect(function()
        setESPEnabled(ESPSettings.Enabled)
        refreshBtn.Text = "Refreshed!"
        .delay(0.5, function() refreshBtn.Text = "Refresh ESP (Update Players)" end)
    end)
    y = y + 34
    mkToggleRow(inner, "Show Name", y, function() return ESPSettings.ShowName end, function(v) ESPSettings.ShowName = v end)
    y = y + 34
    mkToggleRow(inner, "Show Username", y, function() return ESPSettings.ShowUsername end, function(v) ESPSettings.ShowUsername = v end)
    y = y + 34
    mkToggleRow(inner, "Show HP", y, function() return ESPSettings.ShowHP end, function(v) ESPSettings.ShowHP = v end)
    y = y + 34
    mkToggleRow(inner, "Show Distance", y, function() return ESPSettings.ShowDistance end, function(v) ESPSettings.ShowDistance = v end)
    y = y + 38
    mkLabel(inner, "ESP Color (RGB):", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,y), F_S, 14)
    y = y + 22
    local preview = Instance.new("Frame", inner)
    preview.Position = UDim2.new(0,12,0,y)
    preview.Size = UDim2.new(1,-24,0,20)
    preview.BackgroundColor3 = ESPSettings.Color
    preview.BorderSizePixel = 1
    preview.BorderColor3 = Color3.fromRGB(255,255,255)
    corner(preview)
    y = y + 26
    local colorBox = mkBox(inner, string.format("%d,%d,%d", math.floor(ESPSettings.Color.R*255), math.floor(ESPSettings.Color.G*255), math.floor(ESPSettings.Color.B*255)), UDim2.new(1,-24,0,24), UDim2.new(0,12,0,y), 13)
    local function refreshColor()
        preview.BackgroundColor3 = ESPSettings.Color
        colorBox.Text = string.format("%d,%d,%d", math.floor(ESPSettings.Color.R*255+0.5), math.floor(ESPSettings.Color.G*255+0.5), math.floor(ESPSettings.Color.B*255+0.5))
        if fovCircle then fovCircle.Color = ESPSettings.Color end
    end
    colorBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local r, g, b = colorBox.Text:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
            if r and g and b then
                ESPSettings.Color = Color3.fromRGB(math.clamp(tonumber(r),0,255), math.clamp(tonumber(g),0,255), math.clamp(tonumber(b),0,255))
                saveAimAuto()
            end
        end
        refreshColor()
    end)
    addRefresh(refreshColor)
    refreshColor()
end

local function buildKeybindsTab(parent)
    local scroll = FuckYouLib.create("ScrollingFrame", {Parent = parent, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0,0,0,340)})
    local inner = mkPanel(scroll, UDim2.new(1,0,0,340))
    local y = 10
    mkLabel(inner, "LegitBot / Ragebot keybinds", UDim2.new(1,-24,0,20), UDim2.new(0,12,0,y), F_S, 14)
    y = y + 26
    mkBindRow(inner, "Toggle LegitBot", y, function() return Keybinds.ToggleLegitBot end, function(v) Keybinds.ToggleLegitBot = v end)
    y = y + 34
    mkBindRow(inner, "Legit Aim Key", y, function() return Legit.Keybind end, function(v) Legit.Keybind = v end)
    y = y + 34
    mkBindRow(inner, "Legit Trigger Key", y, function() return Legit.TriggerKey end, function(v) Legit.TriggerKey = v end)
    y = y + 34
    mkBindRow(inner, "Toggle Ragebot", y, function() return Keybinds.ToggleRagebot end, function(v) Keybinds.ToggleRagebot = v end)
    y = y + 34
    mkBindRow(inner, "Rage Aim Key", y, function() return Rage.Keybind end, function(v) Rage.Keybind = v end)
end

addAimTab("LegitBot", buildLegitTab)
addAimTab("Ragebot", buildRageTab)
addAimTab("ESP", buildESPTab)
addAimTab("Keybinds", buildKeybindsTab)

-- Sidebar toggles
local LegitSidebarToggle = FuckYouLib.create("TextButton", {
    Name = "MToggle_Legit", Parent = FuckYouLib.MenuInsided,
    Size = UDim2.new(1,0,0,40), LayoutOrder = 390, Visible = false,
    BackgroundColor3 = FuckYouLib.uiColor_ButtonColor, BorderColor3 = COL_BORDER,
    Text = "Legit: OFF", Font = FONT, TextSize = 12, TextWrapped = true,
    BackgroundTransparency = 1 - FuckYouLib.uiGuiOpacity,
})
table.insert(FuckYouLib.themeElements.CustomButtons, LegitSidebarToggle)
table.insert(FuckYouLib.moduleToggles, {btn = LegitSidebarToggle, group = "Aim"})
FuckYouLib.registerToggle(LegitSidebarToggle, function() return Legit.Enabled end)

local RageSidebarToggle = FuckYouLib.create("TextButton", {
    Name = "MToggle_Rage", Parent = FuckYouLib.MenuInsided,
    Size = UDim2.new(1,0,0,40), LayoutOrder = 391, Visible = false,
    BackgroundColor3 = FuckYouLib.uiColor_ButtonColor, BorderColor3 = COL_BORDER,
    Text = "Rage: OFF", Font = FONT, TextSize = 12, TextWrapped = true,
    BackgroundTransparency = 1 - FuckYouLib.uiGuiOpacity,
})
table.insert(FuckYouLib.themeElements.CustomButtons, RageSidebarToggle)
table.insert(FuckYouLib.moduleToggles, {btn = RageSidebarToggle, group = "Aim"})
FuckYouLib.registerToggle(RageSidebarToggle, function() return Rage.Enabled end)

local ESPSidebarToggle = FuckYouLib.create("TextButton", {
    Name = "MToggle_ESP", Parent = FuckYouLib.MenuInsided,
    Size = UDim2.new(1,0,0,40), LayoutOrder = 392, Visible = false,
    BackgroundColor3 = FuckYouLib.uiColor_ButtonColor, BorderColor3 = COL_BORDER,
    Text = "ESP: OFF", Font = FONT, TextSize = 12, TextWrapped = true,
    BackgroundTransparency = 1 - FuckYouLib.uiGuiOpacity,
})
table.insert(FuckYouLib.themeElements.CustomButtons, ESPSidebarToggle)
table.insert(FuckYouLib.moduleToggles, {btn = ESPSidebarToggle, group = "Aim"})
FuckYouLib.registerToggle(ESPSidebarToggle, function() return ESPSettings.Enabled end)

LegitSidebarToggle.MouseButton1Click:Connect(function() setLegitEnabled(not Legit.Enabled) end)
RageSidebarToggle.MouseButton1Click:Connect(function() setRageEnabled(not Rage.Enabled) end)
ESPSidebarToggle.MouseButton1Click:Connect(function() setESPEnabled(not ESPSettings.Enabled) end)

refreshSidebarTexts = function()
    if LegitSidebarToggle then
        LegitSidebarToggle.Text = "Legit: " .. (Legit.Enabled and "ON" or "OFF")
        FuckYouLib.paintToggleBtn(LegitSidebarToggle, Legit.Enabled)
    end
    if RageSidebarToggle then
        RageSidebarToggle.Text = "Rage: " .. (Rage.Enabled and "ON" or "OFF")
        FuckYouLib.paintToggleBtn(RageSidebarToggle, Rage.Enabled)
    end
    if ESPSidebarToggle then
        ESPSidebarToggle.Text = "ESP: " .. (ESPSettings.Enabled and "ON" or "OFF")
        FuckYouLib.paintToggleBtn(ESPSidebarToggle, ESPSettings.Enabled)
    end
end

refreshAimUI = function()
    for _, fn in ipairs(uiRefreshers) do pcall(fn) end
    if refreshSidebarTexts then refreshSidebarTexts() end
    if fovCircle then fovCircle.Color = ESPSettings.Color end
end

local function applyLegitData(data)
    if type(data) ~= "table" then return end
    if data.Enabled ~= nil then Legit.Enabled = data.Enabled and true or false end
    if data.Mode == "Hold" or data.Mode == "Toggle" or data.Mode == "Always" then Legit.Mode = data.Mode end
    if data.AimPart == "All" or data.AimPart == "Head" or data.AimPart == "RootPart" then Legit.AimPart = data.AimPart end
    if data.StickToTarget ~= nil then Legit.StickToTarget = data.StickToTarget and true or false end
    if data.WallCheck ~= nil then Legit.WallCheck = data.WallCheck and true or false end
    if data.TeamCheck ~= nil then Legit.TeamCheck = data.TeamCheck and true or false end
    if data.DrawFOV ~= nil then Legit.DrawFOV = data.DrawFOV and true or false end
    if type(data.FOV) == "number" then Legit.FOV = math.clamp(data.FOV, 10, 1000) end
    if type(data.Smoothness) == "number" then Legit.Smoothness = math.clamp(data.Smoothness, 0, 1) end
    if type(data.Sensitivity) == "number" then Legit.Sensitivity = math.clamp(data.Sensitivity, 0.05, 2) end
    if data.TriggerMode == "Hold" or data.TriggerMode == "Toggle" or data.TriggerMode == "Always" then Legit.TriggerMode = data.TriggerMode end
    if data.TriggerPart == "All" or data.TriggerPart == "Head" or data.TriggerPart == "RootPart" then Legit.TriggerPart = data.TriggerPart end
    if type(data.TriggerTime) == "number" then Legit.TriggerTime = math.clamp(data.TriggerTime, 0, 1) end
    if data.Keybind ~= nil then Legit.Keybind = getEnumByName(data.Keybind) end
    if data.TriggerKey ~= nil then Legit.TriggerKey = getEnumByName(data.TriggerKey) end
end

local function applyRageData(data)
    if type(data) ~= "table" then return end
    if data.Enabled ~= nil then Rage.Enabled = data.Enabled and true or false end
    if data.Mode == "Always" or data.Mode == "Hold" or data.Mode == "Toggle" then Rage.Mode = data.Mode end
    if data.AimPart == "All" or data.AimPart == "Head" or data.AimPart == "RootPart" then Rage.AimPart = data.AimPart end
    if data.Priority == "Closest" or data.Priority == "Angle" or data.Priority == "Health" then Rage.Priority = data.Priority end
    if type(data.FOV) == "number" then Rage.FOV = math.clamp(data.FOV, 0, 360) end
    if data.WallCheck ~= nil then Rage.WallCheck = data.WallCheck and true or false end
    if data.TeamCheck ~= nil then Rage.TeamCheck = data.TeamCheck and true or false end
    if data.AutoFire ~= nil then Rage.AutoFire = data.AutoFire and true or false end
    if type(data.FireDelay) == "number" then Rage.FireDelay = math.clamp(data.FireDelay, 0, 1) end
    if type(data.FireAngle) == "number" then Rage.FireAngle = math.clamp(data.FireAngle, 0, 45) end
    if type(data.Smoothness) == "number" then Rage.Smoothness = math.clamp(data.Smoothness, 0, 0.95) end
    if type(data.Prediction) == "number" then Rage.Prediction = math.clamp(data.Prediction, 0, 1) end
    if type(data.MaxDistance) == "number" then Rage.MaxDistance = math.clamp(data.MaxDistance, 0, 100000) end
    if data.Keybind ~= nil then Rage.Keybind = getEnumByName(data.Keybind) end
end

local function applyESPData(data)
    if type(data) ~= "table" then return end
    if data.Enabled ~= nil then ESPSettings.Enabled = data.Enabled and true or false end
    if type(data.Color) == "table" and data.Color[1] and data.Color[2] and data.Color[3] then
        ESPSettings.Color = Color3.fromRGB(math.clamp(tonumber(data.Color[1]) or 0,0,255), math.clamp(tonumber(data.Color[2]) or 0,0,255), math.clamp(tonumber(data.Color[3]) or 0,0,255))
    end
    if data.ShowName ~= nil then ESPSettings.ShowName = data.ShowName and true or false end
    if data.ShowUsername ~= nil then ESPSettings.ShowUsername = data.ShowUsername and true or false end
    if data.ShowHP ~= nil then ESPSettings.ShowHP = data.ShowHP and true or false end
    if data.ShowDistance ~= nil then ESPSettings.ShowDistance = data.ShowDistance and true or false end
end

local function applyAimConfig(data)
    if type(data) ~= "table" then return end
    if data.Legit then applyLegitData(data.Legit)
    elseif data.Aimbot then applyLegitData(data.Aimbot) end
    if data.Rage then applyRageData(data.Rage) end
    if data.ESP then applyESPData(data.ESP) end
    if type(data.Keybinds) == "table" then
        if data.Keybinds.ToggleLegitBot ~= nil or data.Keybinds.ToggleAimbot ~= nil then
            Keybinds.ToggleLegitBot = getEnumByName(data.Keybinds.ToggleLegitBot or data.Keybinds.ToggleAimbot)
        end
        if data.Keybinds.ToggleRagebot ~= nil then
            Keybinds.ToggleRagebot = getEnumByName(data.Keybinds.ToggleRagebot)
        end
    end
    if Legit.Enabled and Rage.Enabled then Legit.Enabled = false end
    setESPEnabled(ESPSettings.Enabled)
    if refreshAimUI then refreshAimUI() end
    saveAimAuto()
end

local function resetAimDefaults()
    Legit.Enabled = false
    Legit.Mode = "Hold"
    Legit.AimPart = "All"
    Legit.StickToTarget = false
    Legit.WallCheck = false
    Legit.DrawFOV = true
    Legit.FOV = 150
    Legit.Smoothness = 0.20
    Legit.Sensitivity = 0.45
    Legit.ActiveToggle = false
    Legit.TriggerMode = "Hold"
    Legit.TriggerTime = 0.08
    Legit.TriggerPart = "All"
    Legit.TriggerActiveToggle = false
    Legit.Keybind = Enum.UserInputType.MouseButton2
    Legit.TriggerKey = Enum.KeyCode.LeftAlt
    Rage.Enabled = false
    Rage.Mode = "Always"
    Rage.AimPart = "Head"
    Rage.Priority = "Closest"
    Rage.FOV = 360
    Rage.WallCheck = true
    Rage.AutoFire = true
    Rage.FireDelay = 0.05
    Rage.FireAngle = 5
    Rage.Smoothness = 0.10
    Rage.Prediction = 0.0
    Rage.MaxDistance = 0
    Rage.ActiveToggle = false
    Rage.Keybind = Enum.UserInputType.MouseButton2
    ESPSettings.Enabled = false
    ESPSettings.Color = Color3.fromRGB(0,255,150)
    ESPSettings.ShowName = true
    ESPSettings.ShowUsername = true
    ESPSettings.ShowHP = true
    ESPSettings.ShowDistance = true
    Keybinds.ToggleLegitBot = Enum.KeyCode.G
    Keybinds.ToggleRagebot = Enum.KeyCode.H
    cleanESP()
    if fovCircle then fovCircle.Visible = false; fovCircle.Color = ESPSettings.Color end
    refreshAimUI()
    saveAimAuto()
end

ensureMainLoop()
startKeybindListener()

if readfile and isfile and isfile(AIM_AUTO_FILE) then
    local ok, json = pcall(function() return readfile(AIM_AUTO_FILE) end)
    if ok and json then
        local ok2, data = pcall(function() return HttpService:JSONDecode(json) end)
        if ok2 and type(data) == "table" then applyAimConfig(data) end
    end
end
refreshAimUI()

local baseUpdateTabTheme2 = FuckYouLib.updateTabButtonsTheme
FuckYouLib.updateTabButtonsTheme = function()
    baseUpdateTabTheme2()
    for _, tab in ipairs(aimTabs) do
        if tab.Button then
            if tab.Frame.Visible then
                tab.Button.BackgroundColor3 = FuckYouLib.uiColor_ButtonColor
                tab.Button.TextColor3 = Color3.fromRGB(255,255,255)
            else
                tab.Button.BackgroundColor3 = Color3.fromRGB(math.max(FuckYouLib.uiColor_ButtonColor.R*255-10,0), math.max(FuckYouLib.uiColor_ButtonColor.G*255-10,0), math.max(FuckYouLib.uiColor_ButtonColor.B*255-10,0))
                tab.Button.TextColor3 = FuckYouLib.uiColor_TextColor
            end
        end
    end
end

.defer(function()
    local function hideAllFrames()
        for _, t in ipairs(FuckYouLib.tabs) do if t.Frame then t.Frame.Visible = false end end
        for _, t in ipairs(FuckYouLib.desyncTabs or {}) do if t.Frame then t.Frame.Visible = false end end
        for _, t in ipairs(FuckYouLib.musicTabs or {}) do if t.Frame then t.Frame.Visible = false end end
        for _, t in ipairs(aimTabs) do if t.Frame then t.Frame.Visible = false end end
    end
    local function hideAllModuleButtons()
        for _, t in ipairs(FuckYouLib.tabs) do if t.Button then t.Button.Visible = false end end
        for _, t in ipairs(FuckYouLib.desyncTabs or {}) do if t.Button then t.Button.Visible = false end end
        for _, t in ipairs(FuckYouLib.musicTabs or {}) do if t.Button then t.Button.Visible = false end end
        for _, t in ipairs(aimTabs) do if t.Button then t.Button.Visible = false end end
    end
    local function showMainButtons()
        hideAllModuleButtons()
        for _, t in ipairs(FuckYouLib.tabs) do if t.Button then t.Button.Visible = true end end
    end
    local function showDesyncButtons()
        hideAllModuleButtons()
        for _, t in ipairs(FuckYouLib.desyncTabs or {}) do if t.Button then t.Button.Visible = true end end
    end
    local function showMusicButtons()
        hideAllModuleButtons()
        for _, t in ipairs(FuckYouLib.musicTabs or {}) do if t.Button then t.Button.Visible = true end end
    end
    local function showAimButtons()
        hideAllModuleButtons()
        for _, t in ipairs(aimTabs) do if t.Button then t.Button.Visible = true end end
    end
    for _, t in ipairs(aimTabs) do
        if t.Button then
            t.Button.MouseButton1Click:Connect(function()
                hideAllFrames()
                t.Frame.Visible = true
                FuckYouLib.updateTabButtonsTheme()
            end)
        end
    end
    for _, t in ipairs(FuckYouLib.tabs) do
        if t.Button then
            t.Button.MouseButton1Click:Connect(function()
                for _, m in ipairs(FuckYouLib.musicTabs or {}) do if m.Frame then m.Frame.Visible = false end end
                for _, d in ipairs(FuckYouLib.desyncTabs or {}) do if d.Frame then d.Frame.Visible = false end end
                for _, a in ipairs(aimTabs) do if a.Frame then a.Frame.Visible = false end end
                FuckYouLib.updateTabButtonsTheme()
            end)
        end
    end
    for _, t in ipairs(FuckYouLib.desyncTabs or {}) do
        if t.Button then
            t.Button.MouseButton1Click:Connect(function()
                for _, m in ipairs(FuckYouLib.musicTabs or {}) do if m.Frame then m.Frame.Visible = false end end
                for _, a in ipairs(aimTabs) do if a.Frame then a.Frame.Visible = false end end
                FuckYouLib.updateTabButtonsTheme()
            end)
        end
    end
    for _, t in ipairs(FuckYouLib.musicTabs or {}) do
        if t.Button then
            t.Button.MouseButton1Click:Connect(function()
                for _, a in ipairs(aimTabs) do if a.Frame then a.Frame.Visible = false end end
                for _, d in ipairs(FuckYouLib.desyncTabs or {}) do if d.Frame then d.Frame.Visible = false end end
                FuckYouLib.updateTabButtonsTheme()
            end)
        end
    end
    FuckYouLib.EmilyUi.MouseButton1Click:Connect(function()
        showMainButtons()
        hideAllFrames()
        if FuckYouLib.tabs and FuckYouLib.tabs[1] and FuckYouLib.tabs[1].Frame then
            FuckYouLib.tabs[1].Frame.Visible = true
        end
        FuckYouLib.updateTabButtonsTheme()
    end)
    FuckYouLib.Desync.MouseButton1Click:Connect(function()
        showDesyncButtons()
        hideAllFrames()
        if FuckYouLib.desyncTabs and FuckYouLib.desyncTabs[1] and FuckYouLib.desyncTabs[1].Frame then
            FuckYouLib.desyncTabs[1].Frame.Visible = true
        end
        FuckYouLib.updateTabButtonsTheme()
    end)
    FuckYouLib.Music.MouseButton1Click:Connect(function()
        showMusicButtons()
        hideAllFrames()
        if FuckYouLib.musicTabs and FuckYouLib.musicTabs[1] and FuckYouLib.musicTabs[1].Frame then
            FuckYouLib.musicTabs[1].Frame.Visible = true
        end
        FuckYouLib.updateTabButtonsTheme()
    end)
    FuckYouLib.Aim.MouseButton1Click:Connect(function()
        showAimButtons()
        hideAllFrames()
        if aimTabs[1] and aimTabs[1].Frame then
            aimTabs[1].Frame.Visible = true
        end
        FuckYouLib.updateTabButtonsTheme()
    end)
end)

ScreenGui.Destroying:Connect(function()
    pcall(function()
        Legit.Enabled = false
        Rage.Enabled = false
        ESPSettings.Enabled = false
        Legit.ActiveToggle = false
        Legit.TriggerActiveToggle = false
        Rage.ActiveToggle = false
        currentTargetPart = nil
        triggerTargetPart = nil
        triggerFirstSeen = 0
        rageTargetPart = nil
        rageFirstSeen = 0
        cleanESP()
        if fovCircle then pcall(function() fovCircle:Remove() end) end
        if mainLoopConnection then mainLoopConnection:Disconnect(); mainLoopConnection = nil end
        if aimInputConnection then aimInputConnection:Disconnect(); aimInputConnection = nil end
        saveAimAuto()
    end)
end)

FuckYouLib.registerKeyListProvider("Aim", function()
    local rows = {}
    if Legit.Enabled then table.insert(rows, {"LEGIT BOT", "ON"}) end
    if Rage.Enabled then table.insert(rows, {"RAGE BOT", "ON"}) end
    if ESPSettings.Enabled then table.insert(rows, {"ESP", "ON"}) end
    return rows
end)

AimAPI = {
    Tabs = aimTabs,
    Gather = gatherAimConfig,
    Apply = applyAimConfig,
    Reset = resetAimDefaults,
}
_G.AimAPI = AimAPI

print("AimModule loaded")