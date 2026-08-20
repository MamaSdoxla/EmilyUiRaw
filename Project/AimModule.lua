--// AimModule.lua — Aim Module
--// Вкладки: LegitBot, Ragebot, ESP, Keybinds

local function initAimModule(Library)
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer

    local AIM_AUTO_FILE = "EmilyUi/FuckYou/AimSettings.json"

    local function ensureAimDirs()
        if makefolder then
            pcall(function()
                if not isfolder("EmilyUi") then makefolder("EmilyUi") end
                if not isfolder("EmilyUi/FuckYou") then makefolder("EmilyUi/FuckYou") end
            end)
        end
    end

    --// LegitBot
    local Legit = {
        Enabled = false, Mode = "Hold", AimPart = "All",
        StickToTarget = false, WallCheck = false, TeamCheck = true,
        DrawFOV = true, FOV = 150, Smoothness = 0.20, Sensitivity = 0.45,
        ActiveToggle = false, TriggerMode = "Hold", TriggerTime = 0.08,
        TriggerPart = "All", TriggerActiveToggle = false,
        Keybind = Enum.UserInputType.MouseButton2,
        TriggerKey = Enum.KeyCode.LeftAlt,
    }

    --// Ragebot
    local Rage = {
        Enabled = false, Mode = "Always", AimPart = "Head",
        Priority = "Closest", FOV = 360, WallCheck = true,
        AutoFire = true, FireDelay = 0.05, FireAngle = 5,
        Smoothness = 0.10, Prediction = 0.0, MaxDistance = 0,
        ActiveToggle = false,
        Keybind = Enum.UserInputType.MouseButton2,
    }

    --// ESP
    local ESPSettings = {
        Enabled = false, Color = Color3.fromRGB(0, 255, 150),
        ShowName = true, ShowUsername = true,
        ShowHP = true, ShowDistance = true,
    }

    --// Keybinds
    local Keybinds = {
        ToggleLegitBot = Enum.KeyCode.G,
        ToggleRagebot = Enum.KeyCode.H,
    }

    --// FOV Circle
    local fovCircle = Library.getFOVCircle()

    --// ESP storage
    local ESP_Instances = {}

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

    --// ESP FUNCTIONS
    local function removeESPForPlayer(player)
        local data = ESP_Instances[player]
        if not data then return end
        pcall(function() if data.Highlight then data.Highlight:Destroy() end end)
        pcall(function() if data.BillboardTop then data.BillboardTop:Destroy() end end)
        pcall(function() if data.BillboardBottom then data.BillboardBottom:Destroy() end end)
        ESP_Instances[player] = nil
    end

    local function cleanESP()
        for player in pairs(ESP_Instances) do removeESPForPlayer(player) end
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
        highlight.OutlineColor = Color3.new(1, 1, 1)
        highlight.OutlineTransparency = 0.5
        highlight.Parent = character
        local billboardTop = Instance.new("BillboardGui")
        billboardTop.Name = "AimbotESP_Top"
        billboardTop.Adornee = root
        billboardTop.Size = UDim2.new(0, 200, 0, 60)
        billboardTop.StudsOffset = Vector3.new(0, 3.5, 0)
        billboardTop.AlwaysOnTop = true
        billboardTop.Parent = character
        local textTop = Instance.new("TextLabel", billboardTop)
        textTop.Size = UDim2.new(1, 0, 1, 0)
        textTop.BackgroundTransparency = 1
        textTop.TextColor3 = ESPSettings.Color
        textTop.TextSize = 13
        textTop.Font = Enum.Font.GothamBold
        textTop.TextStrokeTransparency = 0.5
        textTop.TextYAlignment = Enum.TextYAlignment.Bottom
        ESP_Instances[player] = {
            Highlight = highlight, TextTop = textTop,
            BillboardTop = billboardTop,
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
                local topInfo = {}
                if ESPSettings.ShowName then table.insert(topInfo, player.DisplayName) end
                if ESPSettings.ShowUsername then table.insert(topInfo, "@" .. player.Name) end
                instances.TextTop.Text = table.concat(topInfo, " | ")
                local enabled = ESPSettings.Enabled
                instances.Highlight.Enabled = enabled
                instances.BillboardTop.Enabled = enabled and (#topInfo > 0)
            else
                if instances.BillboardTop then instances.BillboardTop.Enabled = false end
                if instances.Highlight then instances.Highlight.Enabled = false end
            end
        end
    end

    local function hookESPCharacter(player)
        player.CharacterAdded:Connect(function()
            if ESPSettings.Enabled then
                task.wait(0.5)
                removeESPForPlayer(player)
                createESP(player)
                updateESP()
            end
        end)
    end

    for _, plr in ipairs(Players:GetPlayers()) do hookESPCharacter(plr) end
    Players.PlayerAdded:Connect(hookESPCharacter)
    Players.PlayerRemoving:Connect(removeESPForPlayer)

    --// AIM TABS
    local aimTabs = {}
    local function addAimTab(name, builder)
        local frame = Library.create("Frame", {
            Name = "Tab" .. name, Parent = Library.Containment,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1, BorderSizePixel = 0,
            Visible = false
        })
        builder(frame)
        local button = Library.create("TextButton", {
            Name = "ABtn_" .. name, Parent = Library.MenuInsided,
            Size = UDim2.new(1, 0, 0, 40),
            LayoutOrder = 300 + #aimTabs, Visible = false,
            BackgroundColor3 = Library.uiColor_ButtonColor,
            BorderColor3 = Library.COL_BORDER,
            TextColor3 = Library.uiColor_TextColor,
            Text = name, Font = Library.FONT, TextSize = 12,
            TextWrapped = true
        })
        local entry = {Frame = frame, Name = name, Button = button}
        table.insert(aimTabs, entry)
        table.insert(Library.themeElements.Buttons, button)
        table.insert(Library.themeElements.Texts, button)
        return entry
    end

    --// HELPERS
    local function mkToggleRow(parent, labelText, get, set)
        local button = Library.createContentButton(parent, "", function()
            set(not get())
            button.Text = labelText .. ": " .. (get() and "ON" or "OFF")
            Library.paintToggleBtn(button, get())
        end)
        button.Text = labelText .. ": " .. (get() and "ON" or "OFF")
        Library.paintToggleBtn(button, get())
        Library.registerToggle(button, get)
        return button
    end

    local function mkDropdownRow(parent, labelText, options, get, set)
        local button = Library.createContentButton(parent, "", function()
            local index = table.find(options, get()) or 0
            set(options[(index % #options) + 1])
            button.Text = labelText .. ": " .. tostring(get())
        end)
        button.Text = labelText .. ": " .. tostring(get())
        return button
    end

    local function mkNumRow(parent, labelText, get, set, min, max, decimals)
        local container = Library.create("Frame", {
            Parent = parent,
            Size = UDim2.new(1, -24, 0, 46),
            BackgroundTransparency = 1
        })
        local label = Library.createLabel(container, labelText .. " [" .. tostring(get()) .. "]")
        label.Size = UDim2.new(1, 0, 0, 18)
        local box = Library.createTextBox(container, tostring(get()), Library.FONT)
        box.Size = UDim2.new(1, 0, 0, 24)
        box.Position = UDim2.new(0, 0, 0, 20)
        box.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                local value = tonumber(box.Text)
                if value then set(math.clamp(value, min, max)) end
            end
            label.Text = labelText .. " [" .. tostring(get()) .. "]"
            box.Text = tostring(get())
        end)
        return container
    end

    --// LEGIT TAB
    local function buildLegitTab(parent)
        Library.createSection(parent, "LegitBot")
        mkToggleRow(parent, "LegitBot",
            function() return Legit.Enabled end,
            function(v) Legit.Enabled = v end)
        mkDropdownRow(parent, "Mode", {"Hold", "Toggle", "Always"},
            function() return Legit.Mode end,
            function(v) Legit.Mode = v end)
        mkDropdownRow(parent, "Aim Part", {"All", "Head", "RootPart"},
            function() return Legit.AimPart end,
            function(v) Legit.AimPart = v end)
        mkToggleRow(parent, "Wall Check",
            function() return Legit.WallCheck end,
            function(v) Legit.WallCheck = v end)
        mkToggleRow(parent, "Team Check",
            function() return Legit.TeamCheck end,
            function(v) Legit.TeamCheck = v end)
        mkToggleRow(parent, "Draw FOV",
            function() return Legit.DrawFOV end,
            function(v) Legit.DrawFOV = v end)
        mkNumRow(parent, "FOV Radius",
            function() return Legit.FOV end,
            function(v) Legit.FOV = v end, 10, 1000, 0)
        mkNumRow(parent, "Smoothness",
            function() return Legit.Smoothness end,
            function(v) Legit.Smoothness = v end, 0, 1, 2)
        mkNumRow(parent, "Sensitivity",
            function() return Legit.Sensitivity end,
            function(v) Legit.Sensitivity = v end, 0.05, 2, 2)
    end

    --// RAGE TAB
    local function buildRageTab(parent)
        Library.createSection(parent, "Ragebot")
        mkToggleRow(parent, "Ragebot",
            function() return Rage.Enabled end,
            function(v) Rage.Enabled = v end)
        mkDropdownRow(parent, "Mode", {"Always", "Hold", "Toggle"},
            function() return Rage.Mode end,
            function(v) Rage.Mode = v end)
        mkDropdownRow(parent, "Aim Part", {"Head", "RootPart", "All"},
            function() return Rage.AimPart end,
            function(v) Rage.AimPart = v end)
        mkDropdownRow(parent, "Priority", {"Closest", "Angle", "Health"},
            function() return Rage.Priority end,
            function(v) Rage.Priority = v end)
        mkToggleRow(parent, "Auto Fire",
            function() return Rage.AutoFire end,
            function(v) Rage.AutoFire = v end)
        mkNumRow(parent, "FOV",
            function() return Rage.FOV end,
            function(v) Rage.FOV = v end, 0, 360, 0)
        mkNumRow(parent, "Smoothness",
            function() return Rage.Smoothness end,
            function(v) Rage.Smoothness = v end, 0, 0.95, 2)
        mkNumRow(parent, "Prediction",
            function() return Rage.Prediction end,
            function(v) Rage.Prediction = v end, 0, 1, 2)
    end

    --// ESP TAB
    local function buildESPTab(parent)
        Library.createSection(parent, "ESP")
        mkToggleRow(parent, "ESP Enabled",
            function() return ESPSettings.Enabled end,
            function(v)
                ESPSettings.Enabled = v
                if ESPSettings.Enabled then
                    cleanESP()
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.Character then
                            createESP(player)
                        end
                    end
                    updateESP()
                else
                    cleanESP()
                end
            end)
        mkToggleRow(parent, "Show Name",
            function() return ESPSettings.ShowName end,
            function(v) ESPSettings.ShowName = v end)
        mkToggleRow(parent, "Show Username",
            function() return ESPSettings.ShowUsername end,
            function(v) ESPSettings.ShowUsername = v end)
        mkToggleRow(parent, "Show HP",
            function() return ESPSettings.ShowHP end,
            function(v) ESPSettings.ShowHP = v end)
        mkToggleRow(parent, "Show Distance",
            function() return ESPSettings.ShowDistance end,
            function(v) ESPSettings.ShowDistance = v end)
        Library.createColorInput(parent, "ESP Color (RGB)",
            function() return ESPSettings.Color end,
            function(c)
                ESPSettings.Color = c
                if fovCircle then fovCircle.Color = c end
            end)
    end

    --// KEYBINDS TAB
    local function buildKeybindsTab(parent)
        Library.createSection(parent, "Keybinds")
        Library.createLabel(parent, "Configure aim keybinds")
    end

    addAimTab("LegitBot", buildLegitTab)
    addAimTab("Ragebot", buildRageTab)
    addAimTab("ESP", buildESPTab)
    addAimTab("Keybinds", buildKeybindsTab)

    --// SIDEBAR TOGGLES
    local LegitSidebarToggle = Library.create("TextButton", {
        Name = "MToggle_Legit", Parent = Library.MenuInsided,
        Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 390, Visible = false,
        BackgroundColor3 = Library.uiColor_ButtonColor,
        BorderColor3 = Library.COL_BORDER,
        Text = "Legit: OFF", Font = Library.FONT,
        TextSize = 12, TextWrapped = true,
        BackgroundTransparency = 1 - Library.uiGuiOpacity,
    })
    table.insert(Library.themeElements.CustomButtons, LegitSidebarToggle)
    table.insert(Library.moduleToggles, {btn = LegitSidebarToggle, group = "Aim"})
    Library.registerToggle(LegitSidebarToggle, function() return Legit.Enabled end)

    local RageSidebarToggle = Library.create("TextButton", {
        Name = "MToggle_Rage", Parent = Library.MenuInsided,
        Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 391, Visible = false,
        BackgroundColor3 = Library.uiColor_ButtonColor,
        BorderColor3 = Library.COL_BORDER,
        Text = "Rage: OFF", Font = Library.FONT,
        TextSize = 12, TextWrapped = true,
        BackgroundTransparency = 1 - Library.uiGuiOpacity,
    })
    table.insert(Library.themeElements.CustomButtons, RageSidebarToggle)
    table.insert(Library.moduleToggles, {btn = RageSidebarToggle, group = "Aim"})
    Library.registerToggle(RageSidebarToggle, function() return Rage.Enabled end)

    local ESPSidebarToggle = Library.create("TextButton", {
        Name = "MToggle_ESP", Parent = Library.MenuInsided,
        Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 392, Visible = false,
        BackgroundColor3 = Library.uiColor_ButtonColor,
        BorderColor3 = Library.COL_BORDER,
        Text = "ESP: OFF", Font = Library.FONT,
        TextSize = 12, TextWrapped = true,
        BackgroundTransparency = 1 - Library.uiGuiOpacity,
    })
    table.insert(Library.themeElements.CustomButtons, ESPSidebarToggle)
    table.insert(Library.moduleToggles, {btn = ESPSidebarToggle, group = "Aim"})
    Library.registerToggle(ESPSidebarToggle, function() return ESPSettings.Enabled end)

    LegitSidebarToggle.MouseButton1Click:Connect(function()
        Legit.Enabled = not Legit.Enabled
        LegitSidebarToggle.Text = "Legit: " .. (Legit.Enabled and "ON" or "OFF")
        Library.paintToggleBtn(LegitSidebarToggle, Legit.Enabled)
    end)
    RageSidebarToggle.MouseButton1Click:Connect(function()
        Rage.Enabled = not Rage.Enabled
        RageSidebarToggle.Text = "Rage: " .. (Rage.Enabled and "ON" or "OFF")
        Library.paintToggleBtn(RageSidebarToggle, Rage.Enabled)
    end)
    ESPSidebarToggle.MouseButton1Click:Connect(function()
        ESPSettings.Enabled = not ESPSettings.Enabled
        ESPSidebarToggle.Text = "ESP: " .. (ESPSettings.Enabled and "ON" or "OFF")
        Library.paintToggleBtn(ESPSidebarToggle, ESPSettings.Enabled)
        if ESPSettings.Enabled then
            cleanESP()
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then createESP(player) end
            end
            updateESP()
        else
            cleanESP()
        end
    end)

    --// MAIN LOOP
    RunService.RenderStepped:Connect(function()
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
    end)

    --// KEY LIST PROVIDER
    Library.registerKeyListProvider("Aim", function()
        local rows = {}
        if Legit.Enabled then table.insert(rows, {"LEGIT BOT", "ON"}) end
        if Rage.Enabled then table.insert(rows, {"RAGE BOT", "ON"}) end
        if ESPSettings.Enabled then table.insert(rows, {"ESP", "ON"}) end
        return rows
    end)

    --// CONFIG API
    local function gatherAimConfig()
        return {
            Legit = {
                Enabled = Legit.Enabled, Mode = Legit.Mode,
                AimPart = Legit.AimPart, FOV = Legit.FOV,
                Smoothness = Legit.Smoothness, Sensitivity = Legit.Sensitivity,
            },
            Rage = {
                Enabled = Rage.Enabled, Mode = Rage.Mode,
                AimPart = Rage.AimPart, Priority = Rage.Priority,
                FOV = Rage.FOV, Smoothness = Rage.Smoothness,
                Prediction = Rage.Prediction,
            },
            ESP = {
                Enabled = ESPSettings.Enabled,
                Color = {
                    math.floor(ESPSettings.Color.R * 255),
                    math.floor(ESPSettings.Color.G * 255),
                    math.floor(ESPSettings.Color.B * 255),
                },
                ShowName = ESPSettings.ShowName,
                ShowUsername = ESPSettings.ShowUsername,
                ShowHP = ESPSettings.ShowHP,
                ShowDistance = ESPSettings.ShowDistance,
            },
        }
    end

    local function applyAimConfig(data)
        if type(data) ~= "table" then return end
        if data.Legit then
            for k, v in pairs(data.Legit) do
                if Legit[k] ~= nil then Legit[k] = v end
            end
        end
        if data.Rage then
            for k, v in pairs(data.Rage) do
                if Rage[k] ~= nil then Rage[k] = v end
            end
        end
        if data.ESP then
            if data.ESP.Enabled ~= nil then ESPSettings.Enabled = data.ESP.Enabled end
            if type(data.ESP.Color) == "table" then
                ESPSettings.Color = Color3.fromRGB(
                    math.clamp(tonumber(data.ESP.Color[1]) or 0, 0, 255),
                    math.clamp(tonumber(data.ESP.Color[2]) or 0, 0, 255),
                    math.clamp(tonumber(data.ESP.Color[3]) or 0, 0, 255)
                )
            end
        end
    end

    local function resetAimDefaults()
        Legit.Enabled = false; Legit.FOV = 150
        Rage.Enabled = false; Rage.FOV = 360
        ESPSettings.Enabled = false
        ESPSettings.Color = Color3.fromRGB(0, 255, 150)
        cleanESP()
        if fovCircle then fovCircle.Visible = false end
    end

    --// LOAD CONFIG
    if readfile and isfile and isfile(AIM_AUTO_FILE) then
        local ok, json = pcall(function() return readfile(AIM_AUTO_FILE) end)
        if ok and json then
            local ok2, data = pcall(function() return HttpService:JSONDecode(json) end)
            if ok2 and type(data) == "table" then applyAimConfig(data) end
        end
    end

    --// CLEANUP
    Library.ScreenGui.Destroying:Connect(function()
        pcall(function()
            Legit.Enabled = false; Rage.Enabled = false
            ESPSettings.Enabled = false
            cleanESP()
            if fovCircle then pcall(function() fovCircle:Remove() end) end
        end)
    end)

    return {
        Tabs = aimTabs,
        Gather = gatherAimConfig,
        Apply = applyAimConfig,
        Reset = resetAimDefaults,
    }
end

return initAimModule