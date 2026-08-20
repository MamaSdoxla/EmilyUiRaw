--// Aim.lua
return function(Library, mainSideBar, mainMenu, mainContainment)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local LocalPlayer = Players.LocalPlayer
    local FONT = Enum.Font.SpecialElite

    local AimBtn = Library.CreateButton(mainSideBar, "Aim", function() end)
    AimBtn.Size = UDim2.new(1, 0, 0, 59); AimBtn.Position = UDim2.new(0, 0, 0, 177)

    local aimTabs = {}
    local function addAimTab(name, order, builder)
        local btn = Library.CreateButton(mainMenu, name, function() end)
        btn.Size = UDim2.new(1, 0, 0, 40); btn.LayoutOrder = 300 + order; btn.Visible = false
        local frame = create("Frame", {Name = "Tab"..name, Parent = mainContainment, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false})
        table.insert(aimTabs, {Name = name, Button = btn, Frame = frame})
        btn.MouseButton1Click:Connect(function()
            for _, t in ipairs(aimTabs) do t.Frame.Visible = (t.Name == name) end
            Library.applyTheme()
        end)
        builder(frame)
    end

    local Legit = { Enabled = false, Mode = "Hold", AimPart = "All", FOV = 150, Smoothness = 0.20, Sensitivity = 0.45, Keybind = Enum.UserInputType.MouseButton2 }
    local Rage = { Enabled = false, Mode = "Always", AimPart = "Head", Priority = "Closest", FOV = 360, AutoFire = true, FireDelay = 0.05 }
    local ESPSettings = { Enabled = false, Color = Color3.fromRGB(0, 255, 150), ShowName = true, ShowHP = true, ShowDistance = true }
    local ESP_Instances = {}

    local function createESP(player)
        if not player or not player.Character then return end
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local highlight = Instance.new("Highlight"); highlight.Name = "AimbotESP_Highlight"; highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillColor = ESPSettings.Color; highlight.FillTransparency = 0.7; highlight.OutlineColor = Color3.new(1, 1, 1); highlight.Parent = player.Character
        ESP_Instances[player] = { Highlight = highlight }
    end

    local function updateESP()
        for player, instances in pairs(ESP_Instances) do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                instances.Highlight.FillColor = ESPSettings.Color
                instances.Highlight.Enabled = ESPSettings.Enabled
            else
                instances.Highlight.Enabled = false
            end
        end
    end

    Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function() if ESPSettings.Enabled then task.wait(0.5); createESP(p); updateESP() end end) end)
    Players.PlayerRemoving:Connect(function(p) if ESP_Instances[p] then ESP_Instances[p].Highlight:Destroy(); ESP_Instances[p] = nil end end)

    --// LegitBot Tab
    addAimTab("LegitBot", 1, function(parent)
        Library.CreateSection(parent, "LegitBot Settings")
        Library.CreateToggle(parent, "LegitBot", Legit.Enabled, function(v) Legit.Enabled = v end)
        Library.CreateDropdown(parent, "Mode", {"Hold", "Toggle", "Always"}, function() return Legit.Mode end, function(v) Legit.Mode = v end)
        Library.CreateDropdown(parent, "Aim Part", {"All", "Head", "RootPart"}, function() return Legit.AimPart end, function(v) Legit.AimPart = v end)
    end)

    --// Ragebot Tab
    addAimTab("Ragebot", 2, function(parent)
        Library.CreateSection(parent, "Ragebot Settings")
        Library.CreateToggle(parent, "Ragebot", Rage.Enabled, function(v) Rage.Enabled = v end)
        Library.CreateDropdown(parent, "Mode", {"Always", "Hold", "Toggle"}, function() return Rage.Mode end, function(v) Rage.Mode = v end)
        Library.CreateToggle(parent, "Auto Fire", Rage.AutoFire, function(v) Rage.AutoFire = v end)
    end)

    --// ESP Tab
    addAimTab("ESP", 3, function(parent)
        Library.CreateSection(parent, "ESP Settings")
        Library.CreateToggle(parent, "ESP", ESPSettings.Enabled, function(v)
            ESPSettings.Enabled = v
            if ESPSettings.Enabled then for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then createESP(p) end end end
            updateESP()
        end)
        Library.CreateToggle(parent, "Show Name", ESPSettings.ShowName, function(v) ESPSettings.ShowName = v end)
        Library.CreateToggle(parent, "Show HP", ESPSettings.ShowHP, function(v) ESPSettings.ShowHP = v end)
        Library.CreateToggle(parent, "Show Distance", ESPSettings.ShowDistance, function(v) ESPSettings.ShowDistance = v end)
    end)

    --// Main Loop
    RunService.RenderStepped:Connect(function()
        updateESP()
        if Legit.Enabled and Legit.Mode == "Always" then
            -- Упрощенная логика аимбота для краткости, использует mousemoverel если есть
            local camera = workspace.CurrentCamera
            local mouse = UserInputService:GetMouseLocation()
            local bestDist = Legit.FOV
            local bestPos = nil
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local part = Legit.AimPart == "Head" and player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart")
                    if part then
                        local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
                        if onScreen then
                            local mag = (Vector2.new(screenPos.X, screenPos.Y) - mouse).Magnitude
                            if mag < bestDist then bestDist = mag; bestPos = screenPos end
                        end
                    end
                end
            end
            if bestPos then
                local dx = (bestPos.X - mouse.X) * Legit.Sensitivity
                local dy = (bestPos.Y - mouse.Y) * Legit.Sensitivity
                if mousemoverel then mousemoverel(dx / (Legit.Smoothness * 10), dy / (Legit.Smoothness * 10)) end
            end
        end
    end)

    AimBtn.MouseButton1Click:Connect(function()
        for _, t in ipairs(aimTabs) do t.Button.Visible = true end
        if aimTabs[1] then aimTabs[1].Frame.Visible = true end
        Library.applyTheme()
    end)

    Library.registerKeyListProvider("Aim", function()
        local rows = {}
        if Legit.Enabled then table.insert(rows, {"LEGIT BOT", "ON"}) end
        if Rage.Enabled then table.insert(rows, {"RAGE BOT", "ON"}) end
        if ESPSettings.Enabled then table.insert(rows, {"ESP", "ON"}) end
        return rows
    end)

    return {
        Tabs = aimTabs,
        Gather = function() return { Legit = Legit, Rage = Rage, ESP = ESPSettings } end,
        Apply = function(data)
            if data.Legit then for k,v in pairs(data.Legit) do Legit[k] = v end end
            if data.Rage then for k,v in pairs(data.Rage) do Rage[k] = v end end
            if data.ESP then for k,v in pairs(data.ESP) do ESPSettings[k] = v end end
        end,
        Reset = function() Legit.Enabled = false; Rage.Enabled = false; ESPSettings.Enabled = false end
    }
end