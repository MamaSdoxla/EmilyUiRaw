--// AimModule.lua
local function initAimModule(Library)
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer

    local aimTabs = {}
    local function addAimTab(name, builder)
        local frame = Library.create("Frame", {Name = "Tab" .. name, Parent = Library.Containment, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false})
        builder(frame)
        local button = Library.create("TextButton", {Name = "ABtn_" .. name, Parent = Library.MenuInsided, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 300 + #aimTabs, Visible = false, BackgroundColor3 = Library.uiColor_ButtonColor, BorderColor3 = Library.COL_BORDER, TextColor3 = Library.uiColor_TextColor, Text = name, Font = Library.FONT, TextSize = 12, TextWrapped = true})
        local entry = {Frame = frame, Name = name, Button = button}
        table.insert(aimTabs, entry); table.insert(Library.themeElements.Buttons, button); table.insert(Library.themeElements.Texts, button)
        return entry
    end

    local Legit = {Enabled = false, Mode = "Hold", AimPart = "All", WallCheck = false, TeamCheck = true, DrawFOV = true, FOV = 150, Smoothness = 0.20, Sensitivity = 0.45}
    local Rage = {Enabled = false, Mode = "Always", AimPart = "Head", Priority = "Closest", FOV = 360, WallCheck = true, AutoFire = true, FireDelay = 0.05, Smoothness = 0.10, Prediction = 0.0}
    local ESPSettings = {Enabled = false, Color = Color3.fromRGB(0, 255, 150), ShowName = true, ShowUsername = true, ShowHP = true, ShowDistance = true}
    local fovCircle = Library.getFOVCircle()
    local ESP_Instances = {}

    local function isAlive(player)
        local character = player and player.Character; if not character then return false end
        local humanoid = character:FindFirstChildOfClass("Humanoid"); local root = character:FindFirstChild("HumanoidRootPart")
        return humanoid and root and humanoid.Health > 0
    end

    local function createESP(player)
        if not player or not player.Character then return end
        local character = player.Character; local root = character:FindFirstChild("HumanoidRootPart"); local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid then return end
        local highlight = Instance.new("Highlight"); highlight.Name = "AimbotESP_Highlight"; highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillColor = ESPSettings.Color; highlight.FillTransparency = 0.7; highlight.OutlineColor = Color3.new(1, 1, 1); highlight.OutlineTransparency = 0.5; highlight.Parent = character
        local billboardTop = Instance.new("BillboardGui"); billboardTop.Name = "AimbotESP_Top"; billboardTop.Adornee = root; billboardTop.Size = UDim2.new(0, 200, 0, 60)
        billboardTop.StudsOffset = Vector3.new(0, 3.5, 0); billboardTop.AlwaysOnTop = true; billboardTop.Parent = character
        local textTop = Instance.new("TextLabel", billboardTop); textTop.Size = UDim2.new(1, 0, 1, 0); textTop.BackgroundTransparency = 1; textTop.TextColor3 = ESPSettings.Color
        textTop.TextSize = 13; textTop.Font = Enum.Font.GothamBold; textTop.TextStrokeTransparency = 0.5; textTop.TextYAlignment = Enum.TextYAlignment.Bottom
        ESP_Instances[player] = {Highlight = highlight, TextTop = textTop, BillboardTop = billboardTop}
    end

    local function cleanESP() for player in pairs(ESP_Instances) do local d = ESP_Instances[player]; if d then pcall(function() d.Highlight:Destroy(); d.BillboardTop:Destroy() end) end end; ESP_Instances = {} end

    local function buildLegitTab(parent)
        local sf = Library.create("ScrollingFrame", {Parent = parent, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 0)})
        local inner = Library.create("Frame", {Parent = sf, Size = UDim2.new(1, 0, 0, 500), BackgroundTransparency = 1})
        local layout = Library.create("UIListLayout", {Parent = inner, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
        Library.create("UIPadding", {Parent = inner, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 10)})
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() inner.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y + 20); sf.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20) end)
        
        Library.createSection(inner, "LegitBot")
        Library.createToggle(inner, "LegitBot", Legit.Enabled, function(v) Legit.Enabled = v end)
        Library.createDropdown(inner, "Mode", function() return {"Hold", "Toggle", "Always"} end, function() return Legit.Mode end, function(v) Legit.Mode = v end)
        Library.createDropdown(inner, "Aim Part", function() return {"All", "Head", "RootPart"} end, function() return Legit.AimPart end, function(v) Legit.AimPart = v end)
        Library.createToggle(inner, "Wall Check", Legit.WallCheck, function(v) Legit.WallCheck = v end)
        Library.createToggle(inner, "Team Check", Legit.TeamCheck, function(v) Legit.TeamCheck = v end)
        Library.createToggle(inner, "Draw FOV", Legit.DrawFOV, function(v) Legit.DrawFOV = v end)
        Library.createSlider(inner, "FOV Radius", 10, 1000, function() return Legit.FOV end, function(v) Legit.FOV = v end, function(v) return tostring(v) end)
        Library.createSlider(inner, "Smoothness", 0, 1, function() return Legit.Smoothness end, function(v) Legit.Smoothness = v end, function(v) return string.format("%.2f", v) end)
        Library.createSlider(inner, "Sensitivity", 0.05, 2, function() return Legit.Sensitivity end, function(v) Legit.Sensitivity = v end, function(v) return string.format("%.2f", v) end)
    end

    local function buildRageTab(parent)
        local sf = Library.create("ScrollingFrame", {Parent = parent, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 0)})
        local inner = Library.create("Frame", {Parent = sf, Size = UDim2.new(1, 0, 0, 500), BackgroundTransparency = 1})
        local layout = Library.create("UIListLayout", {Parent = inner, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
        Library.create("UIPadding", {Parent = inner, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 10)})
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() inner.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y + 20); sf.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20) end)
        
        Library.createSection(inner, "Ragebot")
        Library.createToggle(inner, "Ragebot", Rage.Enabled, function(v) Rage.Enabled = v end)
        Library.createDropdown(inner, "Mode", function() return {"Always", "Hold", "Toggle"} end, function() return Rage.Mode end, function(v) Rage.Mode = v end)
        Library.createDropdown(inner, "Aim Part", function() return {"Head", "RootPart", "All"} end, function() return Rage.AimPart end, function(v) Rage.AimPart = v end)
        Library.createDropdown(inner, "Priority", function() return {"Closest", "Angle", "Health"} end, function() return Rage.Priority end, function(v) Rage.Priority = v end)
        Library.createToggle(inner, "Auto Fire", Rage.AutoFire, function(v) Rage.AutoFire = v end)
        Library.createSlider(inner, "FOV", 0, 360, function() return Rage.FOV end, function(v) Rage.FOV = v end, function(v) return tostring(v) end)
        Library.createSlider(inner, "Smoothness", 0, 0.95, function() return Rage.Smoothness end, function(v) Rage.Smoothness = v end, function(v) return string.format("%.2f", v) end)
        Library.createSlider(inner, "Prediction", 0, 1, function() return Rage.Prediction end, function(v) Rage.Prediction = v end, function(v) return string.format("%.2f", v) end)
    end

    local function buildESPTab(parent)
        local sf = Library.create("ScrollingFrame", {Parent = parent, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 0)})
        local inner = Library.create("Frame", {Parent = sf, Size = UDim2.new(1, 0, 0, 300), BackgroundTransparency = 1})
        local layout = Library.create("UIListLayout", {Parent = inner, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
        Library.create("UIPadding", {Parent = inner, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 10)})
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() inner.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y + 20); sf.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20) end)
        
        Library.createSection(inner, "ESP")
        Library.createToggle(inner, "ESP Enabled", ESPSettings.Enabled, function(v)
            ESPSettings.Enabled = v
            if ESPSettings.Enabled then cleanESP(); for _, player in ipairs(Players:GetPlayers()) do if player ~= LocalPlayer and player.Character then createESP(player) end end
            else cleanESP() end
        end)
        Library.createToggle(inner, "Show Name", ESPSettings.ShowName, function(v) ESPSettings.ShowName = v end)
        Library.createToggle(inner, "Show Username", ESPSettings.ShowUsername, function(v) ESPSettings.ShowUsername = v end)
        Library.createToggle(inner, "Show HP", ESPSettings.ShowHP, function(v) ESPSettings.ShowHP = v end)
        Library.createToggle(inner, "Show Distance", ESPSettings.ShowDistance, function(v) ESPSettings.ShowDistance = v end)
        Library.createColorInput(inner, "ESP Color (RGB)", function() return ESPSettings.Color end, function(c) ESPSettings.Color = c; if fovCircle then fovCircle.Color = c end end)
    end

    local function buildKeybindsTab(parent)
        local sf = Library.create("ScrollingFrame", {Parent = parent, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 0)})
        local inner = Library.create("Frame", {Parent = sf, Size = UDim2.new(1, 0, 0, 200), BackgroundTransparency = 1})
        local layout = Library.create("UIListLayout", {Parent = inner, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
        Library.create("UIPadding", {Parent = inner, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 10)})
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() inner.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y + 20); sf.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20) end)
        Library.createSection(inner, "Keybinds"); Library.createLabel(inner, "Configure aim keybinds")
    end

    addAimTab("LegitBot", buildLegitTab)
    addAimTab("Ragebot", buildRageTab)
    addAimTab("ESP", buildESPTab)
    addAimTab("Keybinds", buildKeybindsTab)

    local LegitSidebarToggle = Library.create("TextButton", {Name = "MToggle_Legit", Parent = Library.MenuInsided, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 390, Visible = false, BackgroundColor3 = Library.uiColor_ButtonColor, BorderColor3 = Library.COL_BORDER, Text = "Legit: OFF", Font = Library.FONT, TextSize = 12, TextWrapped = true, BackgroundTransparency = 1 - Library.uiGuiOpacity})
    local RageSidebarToggle = Library.create("TextButton", {Name = "MToggle_Rage", Parent = Library.MenuInsided, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 391, Visible = false, BackgroundColor3 = Library.uiColor_ButtonColor, BorderColor3 = Library.COL_BORDER, Text = "Rage: OFF", Font = Library.FONT, TextSize = 12, TextWrapped = true, BackgroundTransparency = 1 - Library.uiGuiOpacity})
    local ESPSidebarToggle = Library.create("TextButton", {Name = "MToggle_ESP", Parent = Library.MenuInsided, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 392, Visible = false, BackgroundColor3 = Library.uiColor_ButtonColor, BorderColor3 = Library.COL_BORDER, Text = "ESP: OFF", Font = Library.FONT, TextSize = 12, TextWrapped = true, BackgroundTransparency = 1 - Library.uiGuiOpacity})
    
    for _, btn in ipairs({LegitSidebarToggle, RageSidebarToggle, ESPSidebarToggle}) do
        table.insert(Library.themeElements.CustomButtons, btn); table.insert(Library.moduleToggles, {btn = btn, group = "Aim"})
    end
    Library.registerToggle(LegitSidebarToggle, function() return Legit.Enabled end)
    Library.registerToggle(RageSidebarToggle, function() return Rage.Enabled end)
    Library.registerToggle(ESPSidebarToggle, function() return ESPSettings.Enabled end)

    LegitSidebarToggle.MouseButton1Click:Connect(function() Legit.Enabled = not Legit.Enabled; LegitSidebarToggle.Text = "Legit: " .. (Legit.Enabled and "ON" or "OFF"); Library.paintToggleBtn(LegitSidebarToggle, Legit.Enabled) end)
    RageSidebarToggle.MouseButton1Click:Connect(function() Rage.Enabled = not Rage.Enabled; RageSidebarToggle.Text = "Rage: " .. (Rage.Enabled and "ON" or "OFF"); Library.paintToggleBtn(RageSidebarToggle, Rage.Enabled) end)
    ESPSidebarToggle.MouseButton1Click:Connect(function()
        ESPSettings.Enabled = not ESPSettings.Enabled
        ESPSidebarToggle.Text = "ESP: " .. (ESPSettings.Enabled and "ON" or "OFF"); Library.paintToggleBtn(ESPSidebarToggle, ESPSettings.Enabled)
        if ESPSettings.Enabled then cleanESP(); for _, player in ipairs(Players:GetPlayers()) do if player ~= LocalPlayer and player.Character then createESP(player) end end
        else cleanESP() end
    end)

    RunService.RenderStepped:Connect(function()
        if fovCircle then fovCircle.Visible = Legit.Enabled and Legit.DrawFOV; fovCircle.Radius = Legit.FOV; fovCircle.Position = UserInputService:GetMouseLocation(); fovCircle.Color = ESPSettings.Color end
    end)

    Library.ScreenGui.Destroying:Connect(function() pcall(function() Legit.Enabled = false; Rage.Enabled = false; ESPSettings.Enabled = false; cleanESP(); if fovCircle then pcall(function() fovCircle:Remove() end) end end) end)

    return {Tabs = aimTabs, Gather = function() return {Legit = {Enabled = Legit.Enabled, FOV = Legit.FOV}, Rage = {Enabled = Rage.Enabled, FOV = Rage.FOV}, ESP = {Enabled = ESPSettings.Enabled, Color = {math.floor(ESPSettings.Color.R*255), math.floor(ESPSettings.Color.G*255), math.floor(ESPSettings.Color.B*255)}}} end, Apply = function(d) if type(d) == "table" then if d.Legit and d.Legit.FOV then Legit.FOV = d.Legit.FOV end; if d.ESP and d.ESP.Color then ESPSettings.Color = Color3.fromRGB(d.ESP.Color[1], d.ESP.Color[2], d.ESP.Color[3]) end end end, Reset = function() Legit.Enabled = false; Rage.Enabled = false; ESPSettings.Enabled = false; cleanESP(); if fovCircle then fovCircle.Visible = false end end}
end
return initAimModule