--// EmilyUiModule.lua
local function initEmilyUiModule(Library)
    local Players = game:GetService("Players")
    local TeleportService = game:GetService("TeleportService")
    local LightingService = game:GetService("Lighting")
    local StatsService = game:GetService("Stats")
    local LocalPlayer = Players.LocalPlayer

    local function getMyChar() return LocalPlayer.Character end
    local function getMyHum() local c = getMyChar() return c and c:FindFirstChildOfClass("Humanoid") end
    local function getMyRoot() local c = getMyChar() return c and c:FindFirstChild("HumanoidRootPart") end

    local tabFrames = {
        Main = Library.createTabContentFrame("TabMain"),
        Universal = Library.createTabContentFrame("TabUniversal"),
        Character = Library.createTabContentFrame("TabCharacter"),
        Players = Library.createTabContentFrame("TabPlayers"),
        Visuals = Library.createTabContentFrame("TabVisuals"),
        Utilities = Library.createTabContentFrame("TabUtilities"),
        Server = Library.createTabContentFrame("TabServer"),
        Games = Library.createTabContentFrame("TabGames"),
        Scripts = Library.createTabContentFrame("TabScripts"),
        Hubs = Library.createTabContentFrame("TabScriptHubs"),
        Guis = Library.createTabContentFrame("TabGuis"),
        Anims = Library.createTabContentFrame("TabAnimations"),
        Settings = Library.createTabContentFrame("TabSettings"),
    }

    -- Main
    Library.createSection(tabFrames.Main, "In case something happens here's a discord server")
    Library.createContentButton(tabFrames.Main, "Click to copy Discord Server link", Library.copyDiscord)
    Library.createSection(tabFrames.Main, "* Credits to *")
    Library.createSection(tabFrames.Main, "RobloxId (DiscordUsername) -> role")
    Library.createSection(tabFrames.Main, "WdymGaming (wdymgaming) -> coder")
    Library.createSection(tabFrames.Main, "pashajokot (swatwincky) -> tester")
    Library.createSection(tabFrames.Main, "BombalMac (bombapc) -> tester")

    -- Universal
    Library.createSection(tabFrames.Universal, "Admin Commands")
    Library.createContentButton(tabFrames.Universal, "Infinite Yield", function() loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))() end)
    Library.createContentButton(tabFrames.Universal, "FE Admin Commands", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/lxte/cmd/main/main.lua"))() end)
    Library.createSection(tabFrames.Universal, "For exploiting")
    Library.createContentButton(tabFrames.Universal, "Dex Explorer++", function() loadstring(game:HttpGet("https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua"))() end)
    Library.createContentButton(tabFrames.Universal, "Cobalt", function() loadstring(game:HttpGet("https://gitlab.com/upio/cobalt/-/releases/permalink/latest/downloads/Cobalt.luau"))() end)
    Library.createContentButton(tabFrames.Universal, "Rem v1.2", function() loadstring(game:HttpGet("https://e-vil.com/anbu/rem.lua"))() end)
    Library.createContentButton(tabFrames.Universal, "VEX (better DEX)", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Vezise/2026/main/Vez/VexExplorer/VEXExplorer.lua"))() end)
    Library.createContentButton(tabFrames.Universal, "Executor Tester | v2.6", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/GmilerlolYT/ExecutorTester/refs/heads/main/Hi"))() end)

    -- Character
    local CharSettings = {Speed = 16, Jump = 50, Gravity = 196.2}
    local SpinSettings = { Enabled = false, Speed = 180 }
    local spinConn = nil
    local function applyCharStats()
        local h = getMyHum()
        if h then pcall(function() h.WalkSpeed = CharSettings.Speed end); pcall(function() h.UseJumpPower = true; h.JumpPower = CharSettings.Jump end) end
        pcall(function() workspace.Gravity = CharSettings.Gravity end)
    end
    local function updateSpin()
        if SpinSettings.Enabled and spinConn == nil then
            spinConn = game:GetService("RunService").Heartbeat:Connect(function(dt)
                local root = getMyRoot()
                if root then root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(SpinSettings.Speed) * dt, 0) end
            end)
        elseif not SpinSettings.Enabled and spinConn then spinConn:Disconnect(); spinConn = nil end
    end
    Library.createSection(tabFrames.Character, "Character")
    
    -- Helper for sliders/toggles to prevent stacking
    local function addSlider(parent, labelText, min, max, getval, onval, fmt)
        local container = Library.create("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = parent})
        local label = Library.create("TextLabel", {Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1, Text = labelText, TextColor3 = Library.uiColor_TextColor, TextSize = 13, Font = Library.FONT, TextXAlignment = Enum.TextXAlignment.Left, Parent = container})
        table.insert(Library.themeElements.Texts, label)
        local valLabel = Library.create("TextLabel", {Size = UDim2.new(0.5, 0, 0, 14), Position = UDim2.new(0.48, 0, 0.05, 0), BackgroundTransparency = 1, Text = fmt(getval()), TextColor3 = Library.uiColor_TextColor, TextSize = 13, Font = Library.FONT, TextXAlignment = Enum.TextXAlignment.Right, Parent = container})
        table.insert(Library.themeElements.Texts, valLabel)
        local track = Library.create("TextButton", {Size = UDim2.new(0.5, 0, 0, 10), Position = UDim2.new(0.48, 0, 0.55, 0), BackgroundColor3 = Library.uiColor_TextBoxColor, BorderColor3 = Library.COL_BORDER, Text = "", Parent = container})
        table.insert(Library.themeElements.TextBoxes, track)
        local fill = Library.create("Frame", {Size = UDim2.new((getval() - min) / (max - min), 0, 1, 0), BackgroundColor3 = Library.uiColor_TextColor, BorderSizePixel = 0, Parent = track})
        table.insert(Library.themeElements.FillBars, fill)
        local dragging = false
        local function setFromX(x)
            local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local v = math.floor(min + (max - min) * rel + 0.5)
            onval(v); fill.Size = UDim2.new((v - min) / (max - min), 0, 1, 0); valLabel.Text = fmt(v)
        end
        track.MouseButton1Down:Connect(function(x) dragging = true; setFromX(x) end)
        game:GetService("UserInputService").InputChanged:Connect(function(input) if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then setFromX(input.Position.X) end end)
        game:GetService("UserInputService").InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
        return container
    end

    addSlider(tabFrames.Character, "Speed", 1, 500, function() return CharSettings.Speed end, function(v) CharSettings.Speed = v; applyCharStats() end, function(v) return tostring(v) end)
    addSlider(tabFrames.Character, "Jump", 1, 500, function() return CharSettings.Jump end, function(v) CharSettings.Jump = v; applyCharStats() end, function(v) return tostring(v) end)
    addSlider(tabFrames.Character, "Gravity", 0, 3000, function() return CharSettings.Gravity end, function(v) CharSettings.Gravity = v; applyCharStats() end, function(v) return string.format("%.1f", v) end)
    Library.createToggle(tabFrames.Character, "Infinite Jump", false, function() end)
    Library.createToggle(tabFrames.Character, "Anti-AFK", false, function() end)
    local spinToggle = Library.createToggle(tabFrames.Character, "Spin", SpinSettings.Enabled, function(on) SpinSettings.Enabled = on; updateSpin() end)
    addSlider(tabFrames.Character, "Spin Speed (0-360)", 0, 360, function() return SpinSettings.Speed end, function(v) SpinSettings.Speed = v end, function(v) return v .. "°" end)
    LocalPlayer.CharacterAdded:Connect(function() task.wait(0.1); applyCharStats() end)

    -- Players
    local hiddenPlayers, markedPlayers, spectateTarget, playerCards = {}, {}, nil, {}
    local function applyMark(plr, on)
        local char = plr.Character; if not char then return end
        local old = char:FindFirstChild("FY_Mark"); if old then old:Destroy() end
        if on then
            local hl = Instance.new("Highlight"); hl.Name = "FY_Mark"; hl.FillColor = Color3.fromRGB(255, 80, 80); hl.FillTransparency = 0.6
            hl.OutlineColor = Color3.fromRGB(255, 255, 255); hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = char
        end
    end
    local function stopSpectate() spectateTarget = nil; local h = getMyHum(); if h then workspace.CurrentCamera.CameraSubject = h end end
    local function startSpectate(plr) spectateTarget = plr; local h = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid"); if h then workspace.CurrentCamera.CameraSubject = h end end
    local function gotoPlayer(plr)
        local r, t = getMyRoot(), plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        if r and t then r.CFrame = t.CFrame + Vector3.new(3, 0, 0); Library.notify("Players", "Teleported to " .. plr.Name) end
    end
    Library.createSection(tabFrames.Players, "Players")
    Library.createContentButton(tabFrames.Players, "Stop Spectating", stopSpectate)
    Library.createContentButton(tabFrames.Players, "Unhide All", function() hiddenPlayers = {} end)
    
    local function buildPlayerCard(plr)
        local card = Library.create("Frame", {Name = "PlayerCard", Parent = tabFrames.Players, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 120), BackgroundTransparency = 1, BorderSizePixel = 0})
        local header = Library.create("Frame", {Parent = card, Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1})
        Library.create("ImageLabel", {Parent = header, Position = UDim2.new(0, 0, 0, 2), Size = UDim2.new(0, 40, 0, 40), BackgroundTransparency = 1, Image = "rbxthumb://type=AvatarHeadShot&id=" .. plr.UserId .. "&w=150&h=150"})
        Library.create("TextLabel", {Parent = header, Position = UDim2.new(0, 48, 0, 3), Size = UDim2.new(0.55, -48, 0, 18), BackgroundTransparency = 1, Text = plr.DisplayName, TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 13, Font = Library.FONT, TextXAlignment = Enum.TextXAlignment.Left})
        Library.create("TextLabel", {Parent = header, Position = UDim2.new(0, 48, 0, 23), Size = UDim2.new(0.55, -48, 0, 16), BackgroundTransparency = 1, Text = "@" .. plr.Name, TextColor3 = Color3.fromRGB(140, 140, 140), TextSize = 11, Font = Library.FONT, TextXAlignment = Enum.TextXAlignment.Left})
        local row = Library.create("Frame", {Parent = card, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1})
        local function cardBtn(text, i)
            local b = Library.create("TextButton", {Parent = row, Size = UDim2.new(0.2, -4, 1, 0), Position = UDim2.new(0.2 * i, 0, 0, 0), BackgroundColor3 = Library.uiColor_ButtonColor, BorderColor3 = Library.COL_BORDER, BackgroundTransparency = 1 - Library.uiGuiOpacity, TextColor3 = Library.uiColor_TextColor, Text = text, Font = Library.FONT, TextSize = 11, TextWrapped = true})
            table.insert(Library.themeElements.Buttons, b); table.insert(Library.themeElements.Texts, b); return b
        end
        local gotoB = cardBtn("Goto", 0); local viewB = cardBtn("View", 1); local hideB = cardBtn("Hide", 2); local markB = cardBtn(markedPlayers[plr] and "Unmark" or "Mark", 3)
        gotoB.MouseButton1Click:Connect(function() gotoPlayer(plr) end)
        viewB.MouseButton1Click:Connect(function() if spectateTarget == plr then stopSpectate() else startSpectate(plr) end end)
        hideB.MouseButton1Click:Connect(function() hiddenPlayers[plr] = true end)
        markB.MouseButton1Click:Connect(function() markedPlayers[plr] = not markedPlayers[plr]; applyMark(plr, markedPlayers[plr]); markB.Text = markedPlayers[plr] and "Unmark" or "Mark" end)
    end
    local function refreshPlayersList()
        for _, ch in ipairs(tabFrames.Players:GetChildren()) do if ch.Name == "PlayerCard" then ch:Destroy() end end
        for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LocalPlayer and not hiddenPlayers[plr] then buildPlayerCard(plr) end end
    end
    refreshPlayersList()
    Players.PlayerRemoving:Connect(function(plr) hiddenPlayers[plr] = nil; markedPlayers[plr] = nil; if spectateTarget == plr then stopSpectate() end; refreshPlayersList() end)
    Players.PlayerAdded:Connect(function() task.wait(1); refreshPlayersList() end)

    -- Visuals
    local VisualSettings = {FOV = 70, DoF = 0, Saturation = 100, Contrast = 100}
    local visToggles = {}
    local crosshairGui = nil
    local fullbrightOn = false; local fbSaved = nil
    local function setCrosshair(on)
        if on and not crosshairGui then
            crosshairGui = Library.create("ScreenGui", {Name = "FYCrosshair", ResetOnSpawn = false, IgnoreGuiInset = true, Parent = LocalPlayer:WaitForChild("PlayerGui")})
            local geo = {{2, 8, 0, -9}, {2, 8, 0, 9}, {8, 2, -9, 0}, {8, 2, 9, 0}}
            for _, g in ipairs(geo) do Library.create("Frame", {Parent = crosshairGui, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, g[1], 0, g[2]), Position = UDim2.new(0.5, g[3], 0.5, g[4]), BackgroundColor3 = Library.uiColor_TextColor, BorderSizePixel = 0}) end
        elseif not on and crosshairGui then crosshairGui:Destroy(); crosshairGui = nil end
    end
    local function setFullbright(on)
        local L = LightingService
        if on and not fullbrightOn then
            fbSaved = {Brightness = L.Brightness, ClockTime = L.ClockTime, FogEnd = L.FogEnd, GlobalShadows = L.GlobalShadows, Ambient = L.Ambient, OutdoorAmbient = L.OutdoorAmbient}
            fullbrightOn = true; L.Brightness = 2; L.ClockTime = 14; L.FogEnd = 100000; L.GlobalShadows = false
            L.Ambient = Color3.fromRGB(180, 180, 180); L.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
        elseif not on and fullbrightOn then
            fullbrightOn = false; if fbSaved then for k, v in pairs(fbSaved) do L[k] = v end; fbSaved = nil end
        end
    end
    Library.createSection(tabFrames.Visuals, "Visuals")
    visToggles.Crosshair = Library.createToggle(tabFrames.Visuals, "Crosshair", false, setCrosshair)
    addSlider(tabFrames.Visuals, "FOV", 30, 120, function() return VisualSettings.FOV end, function(v) VisualSettings.FOV = v; pcall(function() workspace.CurrentCamera.FieldOfView = v end) end, function(v) return tostring(v) end)
    visToggles.Fullbright = Library.createToggle(tabFrames.Visuals, "Fullbright", false, setFullbright)
    local ccEff = Instance.new("ColorCorrectionEffect", LightingService); ccEff.Saturation = 0; ccEff.Contrast = 0
    addSlider(tabFrames.Visuals, "Saturation", 0, 200, function() return VisualSettings.Saturation end, function(v) VisualSettings.Saturation = v; ccEff.Saturation = (v - 100) / 100 end, function(v) return v .. "%" end)
    addSlider(tabFrames.Visuals, "Contrast", 0, 200, function() return VisualSettings.Contrast end, function(v) VisualSettings.Contrast = v; ccEff.Contrast = (v - 100) / 100 end, function(v) return v .. "%" end)

    -- Utilities
    Library.createSection(tabFrames.Utilities, "Utilities")
    Library.createContentButton(tabFrames.Utilities, "Server Hop", function() Library.notify("Server Hop", "Searching...") end)
    Library.createContentButton(tabFrames.Utilities, "Rejoin", function() Library.notify("Rejoin", "Rejoining..."); pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end) end)

    -- Server
    local sessionStart = os.clock(); local sessionDeaths = 0; local sessionWalked = 0
    local function fmtHMS(sec) sec = math.floor(sec); return string.format("%02d:%02d:%02d", math.floor(sec / 3600), math.floor((sec % 3600) / 60), sec % 60) end
    Library.createSection(tabFrames.Server, "This Server")
    local srvPlaceL = Library.createLabel(tabFrames.Server, "Place: " .. game.PlaceId)
    local srvUsersL = Library.createLabel(tabFrames.Server, "Users: --")
    local srvPingL = Library.createLabel(tabFrames.Server, "Ping: --")
    Library.createSection(tabFrames.Server, "Session")
    local sesPlayL = Library.createLabel(tabFrames.Server, "Playtime: 00:00:00")
    local sesDeathsL = Library.createLabel(tabFrames.Server, "Deaths: 0")
    local sesWalkL = Library.createLabel(tabFrames.Server, "Walked: 0 studs")
    task.spawn(function()
        while true do
            task.wait(1)
            pcall(function()
                srvUsersL.Text = "Users: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers
                srvPingL.Text = "Ping: " .. math.floor(StatsService.PerformanceStats.Ping:GetValue()) .. " ms"
                sesPlayL.Text = "Playtime: " .. fmtHMS(os.clock() - sessionStart)
                sesDeathsL.Text = "Deaths: " .. sessionDeaths
                sesWalkL.Text = "Walked: " .. math.floor(sessionWalked) .. " studs"
            end)
        end
    end)

    -- Scripts / Hubs / GUIs / Anims
    Library.createSection(tabFrames.Games, "Game Scripts")
    Library.createSection(tabFrames.Scripts, "Fun Scripts")
    Library.createContentButton(tabFrames.Scripts, "Ball R6/R15", function() loadstring(game:HttpGet("https://pastebin.com/raw/BZr9bGDy", true))() end)
    Library.createSection(tabFrames.Hubs, "Script hubs")
    Library.createSection(tabFrames.Guis, "Guis")
    Library.createSection(tabFrames.Anims, "Animations")

    -- Settings
    Library.createSection(tabFrames.Settings, "UI Customization")
    local keyBindContainer = Library.create("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = tabFrames.Settings})
    Library.create("TextLabel", {Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1, Text = "Menu Toggle Key:", TextColor3 = Library.uiColor_TextColor, TextSize = 13, Font = Library.FONT, TextXAlignment = Enum.TextXAlignment.Left, Parent = keyBindContainer})
    local keyBindBtn = Library.createContentButton(keyBindContainer, Library.currentToggleKey.Name, function() end)
    keyBindBtn.Size = UDim2.new(0.5, 0, 0.8, 0); keyBindBtn.Position = UDim2.new(0.48, 0, 0.1, 0); keyBindBtn.TextSize = 12
    local listeningForKey = false
    keyBindBtn.MouseButton1Click:Connect(function()
        if listeningForKey then return end; listeningForKey = true; keyBindBtn.Text = "...Press any Key..."
        local connection; connection = game:GetService("UserInputService").InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                Library.currentToggleKey = input.KeyCode; keyBindBtn.Text = Library.currentToggleKey.Name; listeningForKey = false; Library.saveConfig(); connection:Disconnect()
            end
        end)
    end)
    local colorSettings = {
        {"Main Window Color:", function() return Library.uiColor_MainWindow end, function(c) Library.uiColor_MainWindow = c end},
        {"Text Color:", function() return Library.uiColor_TextColor end, function(c) Library.uiColor_TextColor = c end},
        {"Button Color:", function() return Library.uiColor_ButtonColor end, function(c) Library.uiColor_ButtonColor = c end},
    }
    for _, cfg in ipairs(colorSettings) do
        Library.createColorInput(tabFrames.Settings, cfg[1], cfg[2], cfg[3])
    end
    Library.createSection(tabFrames.Settings, "Background & Window")
    Library.createSlider(tabFrames.Settings, "Gui Opacity", 25, 100, function() return math.floor(Library.uiGuiOpacity * 100 + 0.5) end, function(v) Library.uiGuiOpacity = v / 100; Library.applyTheme() end, function(v) return v .. "%" end)
    Library.createSlider(tabFrames.Settings, "Blur", 0, 24, function() return Library.uiBlurSize end, function(v) Library.uiBlurSize = v; Library.updateBlur() end, function(v) return v .. "px" end)
    Library.createContentButton(tabFrames.Settings, "Reset defaults", function()
        Library.currentToggleKey = Enum.KeyCode.P; Library.uiColor_MainWindow = Library.COL_BG; Library.uiColor_TextColor = Library.COL_TEXT
        Library.uiColor_ButtonColor = Library.COL_BG; Library.uiGuiOpacity = 1; Library.uiBlurSize = 0
        keyBindBtn.Text = Library.currentToggleKey.Name; Library.applyTheme(); Library.saveConfig()
        Library.notify("Configs", "Settings reset to defaults")
    end)

    Library.tabs = {
        {Frame = tabFrames.Main, Name = "Main Info"}, {Frame = tabFrames.Universal, Name = "Universal"},
        {Frame = tabFrames.Character, Name = "Character"}, {Frame = tabFrames.Players, Name = "Players"},
        {Frame = tabFrames.Visuals, Name = "Visuals"}, {Frame = tabFrames.Utilities, Name = "Utilities"},
        {Frame = tabFrames.Server, Name = "Server"}, {Frame = tabFrames.Games, Name = "Games"},
        {Frame = tabFrames.Scripts, Name = "Scripts"}, {Frame = tabFrames.Hubs, Name = "Script Hubs"},
        {Frame = tabFrames.Guis, Name = "GUIs"}, {Frame = tabFrames.Anims, Name = "Animations"},
        {Frame = tabFrames.Settings, Name = "Settings"},
    }

    Library.registerKeyListProvider("EmilyUi", function()
        local rows = {}
        if visToggles.Crosshair and visToggles.Crosshair:Get() then table.insert(rows, {"CROSSHAIR", "ON"}) end
        if visToggles.Fullbright and visToggles.Fullbright:Get() then table.insert(rows, {"FULLBRIGHT", "ON"}) end
        return rows
    end)

    return {Tabs = Library.tabs, TabFrames = tabFrames, VisualsAPI = {Gather = function() return {FOV = VisualSettings.FOV} end, Apply = function(d) if d.FOV then VisualSettings.FOV = d.FOV; pcall(function() workspace.CurrentCamera.FieldOfView = d.FOV end) end end, Reset = function() VisualSettings.FOV = 70; pcall(function() workspace.CurrentCamera.FieldOfView = 70 end) end}}
end
return initEmilyUiModule