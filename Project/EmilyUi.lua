--// EmilyUi.lua
return function(Library)
    local create = Library.create
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local HttpService = game:GetService("HttpService")
    local RunService = game:GetService("RunService")
    local Marketplace = game:GetService("MarketplaceService")
    local TeleportService = game:GetService("TeleportService")
    local FONT = Enum.Font.SpecialElite

    local window, topBar, sideBar, menuInsided, containment = Library.CreateWindow("Fuck you! v1.2")
    
    local function makeTopBtn(symbol, offset, callback)
        local b = Library.CreateButton(topBar, symbol, callback)
        b.Size = UDim2.new(0, 45, 0, 45); b.Position = UDim2.new(1, -45 * offset, 0, 0)
        return b
    end
    makeTopBtn("-", 3, function() window.Size = UDim2.new(0, 940, 0, 0); task.wait(0.22); window.Visible = false end)
    local stripState = false
    makeTopBtn("=", 2, function()
        if not stripState then window.Size = UDim2.new(0, 940, 0, 45); stripState = true
        else window.Size = UDim2.new(0, 940, 0, 510); stripState = false end
    end)
    makeTopBtn("X", 1, function() window:Destroy() end)

    local EmilyUiBtn = Library.CreateButton(sideBar, "EmilyUi", function() end)
    EmilyUiBtn.Size = UDim2.new(1, 0, 0, 59)

    local tabs = {}
    local function addTab(name, order)
        local btn, frame = Library.CreateTabButton(name, menuInsided, containment, order)
        table.insert(tabs, {Name = name, Button = btn, Frame = frame})
        btn.MouseButton1Click:Connect(function()
            for _, t in ipairs(tabs) do t.Frame.Visible = (t.Name == name) end
            Library.applyTheme()
        end)
        return frame, btn
    end

    local tabMain = addTab("Main Info", 1)
    local tabUniversal = addTab("Universal", 2)
    local tabCharacter = addTab("Character", 3)
    local tabPlayers = addTab("Players", 4)
    local tabVisuals = addTab("Visuals", 5)
    local tabUtilities = addTab("Utilities", 6)
    local tabServer = addTab("Server", 7)
    local tabGames = addTab("Games", 8)
    local tabScripts = addTab("Scripts", 9)
    local tabHubs = addTab("Script Hubs", 10)
    local tabGuis = addTab("GUIs", 11)
    local tabAnims = addTab("Animations", 12)
    local tabKeyList = addTab("Key List", 13)
    local tabSettings = addTab("Settings", 14)

    -- Main Info
    Library.CreateSection(tabMain, "In case something happens here's a discord server")
    Library.CreateButton(tabMain, "Click to copy Discord Server link", function() if setclipboard then setclipboard("https://discord.gg/75Dz8T9hHR") end; Library.notify("Discord", "The link is copied") end)
    Library.CreateSection(tabMain, "* Credits to *")
    Library.CreateLabel(tabMain, "RobloxId (DiscordUsername) -> role")
    Library.CreateLabel(tabMain, "WdymGaming (wdymgaming) -> coder")
    Library.CreateLabel(tabMain, "pashajokot (swatwincky) -> tester")
    Library.CreateLabel(tabMain, "BombalMac (bombapc) -> tester")

    -- Universal
    Library.CreateSection(tabUniversal, "Admin Commands")
    Library.CreateButton(tabUniversal, "Infinite Yield", function() loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))() end)
    Library.CreateButton(tabUniversal, "FE Admin Commands", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/lxte/cmd/main/main.lua"))() end)
    Library.CreateSection(tabUniversal, "For exploiting")
    Library.CreateButton(tabUniversal, "Dex Explorer++", function() loadstring(game:HttpGet("https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua"))() end)
    Library.CreateButton(tabUniversal, "Cobalt", function() loadstring(game:HttpGet("https://gitlab.com/upio/cobalt/-/releases/permalink/latest/downloads/Cobalt.luau"))() end)
    Library.CreateButton(tabUniversal, "Rem v1.2", function() loadstring(game:HttpGet("https://e-vil.com/anbu/rem.lua"))() end)
    Library.CreateButton(tabUniversal, "VEX (better DEX)", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Vezise/2026/main/Vez/VexExplorer/VEXExplorer.lua"))() end)
    Library.CreateButton(tabUniversal, "Executor Tester | v2.6", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/GmilerlolYT/ExecutorTester/refs/heads/main/Hi"))() end)

    -- Scripts
    Library.CreateSection(tabScripts, "Fun Scripts")
    Library.CreateButton(tabScripts, "Ball R6/R15", function() loadstring(game:HttpGet("https://pastebin.com/raw/BZr9bGDy", true))() end)
    Library.CreateSection(tabScripts, "Scripts made by WdymGaming (outdated, no longer support)")
    Library.CreateButton(tabScripts, "Wdymgaming's Music Gui (client)", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/MamaSdoxla/EmilyUi/refs/heads/main/HomeMade/WdymGamingMusic.lua", true))() end)
    Library.CreateButton(tabScripts, "R6/R15 Animator by WdymGaming", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/MamaSdoxla/EmilyUi/refs/heads/main/HomeMade/WdymGamingAnimator.lua", true))() end)
    Library.CreateButton(tabScripts, "Aimbot + ESP", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/MamaSdoxla/EmilyUi/refs/heads/main/HomeMade/WdymGamingAimbot.lua", true))() end)

    -- Hubs
    Library.CreateSection(tabHubs, "Script hubs")
    Library.CreateButton(tabHubs, "Axe Hub for Natural Disaster Survival", function() loadstring(game:HttpGet('https://raw.githubusercontent.com/zeroidxx/axe-hub/refs/heads/main/axehub%20nds.txt'))() end)
    Library.CreateButton(tabHubs, "FE Trolling GUI", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/yofriendfromschool1/Sky-Hub/main/FE%20Trolling%20GUI.luau"))() end)
    Library.CreateButton(tabHubs, "Ultimate Trolling Gui V5", function() loadstring(game:HttpGet("https://pastefy.app/rmdi1m55/raw"))() end)
    Library.CreateButton(tabHubs, "Yameme Hub", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/MBHubRoblox/YamemeHub/refs/heads/main/selllemons.lua"))() end)
    Library.CreateButton(tabHubs, "Slicer FE V6", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Ahma174/Slicer/refs/heads/main/Slicer%20Fe%20V6"))() end)

    -- Guis
    Library.CreateSection(tabGuis, "Guis")
    Library.CreateButton(tabGuis, "Super ring v6", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/chesslovers69/Super-ring-parts-v6/refs/heads/main/Bylukaslol"))() end)
    Library.CreateButton(tabGuis, "Touch Fling", function() loadstring(game:HttpGet(('https://raw.githubusercontent.com/0Ben1/fe/main/obf_rf6iQURzu1fqrytcnLBAvW34C9N55kS9g9G3CKz086rC47M6632sEd4ZZYB0AYgV.lua.txt'),true))() end)
    Library.CreateButton(tabGuis, "R6 Crashout GUN", function() loadstring(game:HttpGet('https://pastebin.com/raw/k4dFFDfw'))() end)
    Library.CreateButton(tabGuis, "DEV Hud", function() loadstring(game:HttpGet("https://robloxscripts.com/raw/claude-opus-48-dev-hud-v3-script"))() end)
    Library.CreateButton(tabGuis, "Urban1's universal stuffs", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/pwnmaster99/Scripts/refs/heads/main/US"))() end)
    Library.CreateButton(tabGuis, "R15 Drop kick", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/gsm231/Fe-DropKick/refs/heads/main/V0.1"))() end)

    -- Games
    local filterMode = "All"
    local currentPlaceId = tostring(game.PlaceId)
    local GamePlaces = {
        ["12355337193"] = { {type="label", text="Murder vs Sherif 2"}, {type="button", text="Polo MVS", cb=function() loadstring(game:HttpGet("https://raw.githubusercontent.com/polo242c/mvs/main/mvs"))() end}, {type="button", text="CyberCoders", cb=function() loadstring(game:HttpGet("https://rawscripts.net/raw/Murderers-VS-Sheriffs-DUELS-CyberCoders-Menu-II-193913"))() end}, {type="button", text="Wic1k", cb=function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Wic1k/Scripts/refs/heads/main/mvsd.txt"))() end} },
        ["7041939546"] = { {type="label", text="Catalog Avatar Creator"}, {type="button", text="Avatar stealer", cb=function() loadstring(game:HttpGet("https://pastefy.app/xWdIDQJd/raw"))() end} },
        ["142823291"] = { {type="label", text="Murder Mystery 2"}, {type="button", text="VisionHub", cb=function() loadstring(game:HttpGet("https://raw.githubusercontent.com/orialdev/VisionHub/refs/heads/main/main.lua"))() end}, {type="button", text="AutoFarm (40coins/4,5min)", cb=function() loadstring(game:HttpGet("https://raw.githubusercontent.com/tsBelrux/mm2/refs/heads/main/keyless.lua"))() end}, {type="button", text="FoxnameHub", cb=function() loadstring(game:HttpGet("https://foxname.top/loader"))() end} },
        ["95082159892680"] = { {type="label", text="+1 Speed Keyboard Escape"}, {type="button", text="Luxy Hub", cb=function() loadstring(game:HttpGet("https://www.luxyhub.space/api/loader/luxyhub"))() end} }
    }
    local function renderGamesTab()
        for _, child in ipairs(tabGames:GetChildren()) do if child:IsA("TextLabel") or child:IsA("TextButton") then child:Destroy() end end
        Library.CreateButton(tabGames, "Filter: " .. filterMode .. " (Click to switch)", function() filterMode = (filterMode == "All") and "Place" or "All"; renderGamesTab() end)
        Library.CreateSection(tabGames, "Game Scripts")
        for placeId, items in pairs(GamePlaces) do
            local shouldShow = (filterMode == "All") or (filterMode == "Place" and placeId == currentPlaceId)
            if shouldShow then
                for _, item in ipairs(items) do
                    if item.type == "label" then Library.CreateLabel(tabGames, item.text)
                    elseif item.type == "button" then Library.CreateButton(tabGames, item.text, item.cb) end
                end
            end
        end
    end
    renderGamesTab()

    -- Animations
    local animFilterMode = "All"
    local AnimationsSections = {
        { title = "Animations client", scripts = { { text = "R6 Insanity (client)", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/retpirato/Roblox-Scripts/refs/heads/master/Insanity%20Powers.lua"))() end } } },
        { title = "Animations guis", scripts = { { text = "R15 Animations", cb = function() loadstring(game:HttpGet("https://kbauu.neocities.org/animation-hub"))() end }, { text = "Uhhhhhh Reanimator (R6)", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/STEVE-916-create/Uhhhhhh/main/source/reanim.lua"))() end } } },
        { title = "Animation exploits", scripts = { { text = "R6 Upsidedown (multiple times = glitch)", cb = function() loadstring(game:HttpGet("https://pastebin.com/raw/RJVv7H3K"))() end } } },
        { title = "Animations S3X", scripts = { { text = "R6 S3X animations", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/3LD4D0/FE-TROLLING-PLAYER-R6-R15/6eff8792afed57458d5114478b453a6f6bce5799/Fe%20trolling%20Player%20R6%20AND%20R15"))() end }, { text = "R6 S3X animations 2", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/ShutUpJamesTheLoserAlt/fes/refs/heads/main/e"))() end }, { text = "R6 S3X animations 3", cb = function() loadstring(game:HttpGet("https://pastebin.com/raw/gdQ4mVEy"))() end }, { text = "Jerk off tool r6", cb = function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-FE-Jerk-off-240507"))() end }, { text = "Jerk off tool r15", cb = function() loadstring(game:HttpGet("https://pastefy.app/YZoglOyJ/raw"))() end } } }
    }
    local function getAnimType(text)
        local lower = string.lower(text)
        if string.find(lower, "r6") and string.find(lower, "r15") then return "Universal"
        elseif string.find(lower, "r6") then return "R6"
        elseif string.find(lower, "r15") then return "R15"
        else return "Universal" end
    end
    local function renderAnimationsTab()
        for _, child in ipairs(tabAnims:GetChildren()) do if child:IsA("TextLabel") or child:IsA("TextButton") then child:Destroy() end end
        Library.CreateButton(tabAnims, "Filter: " .. animFilterMode .. " (Click to switch)", function()
            if animFilterMode == "All" then animFilterMode = "R6"
            elseif animFilterMode == "R6" then animFilterMode = "R15"
            else animFilterMode = "All" end
            renderAnimationsTab()
        end)
        local totalShown = 0
        for _, section in ipairs(AnimationsSections) do
            local validScripts = {}
            for _, script in ipairs(section.scripts) do
                local t = getAnimType(script.text)
                if animFilterMode == "All" or t == animFilterMode or t == "Universal" then table.insert(validScripts, script) end
            end
            if #validScripts > 0 then
                Library.CreateSection(tabAnims, section.title)
                for _, script in ipairs(validScripts) do Library.CreateButton(tabAnims, script.text, script.cb); totalShown = totalShown + 1 end
            end
        end
        if totalShown == 0 then Library.CreateLabel(tabAnims, "No scripts found for filter: " .. animFilterMode) end
    end
    renderAnimationsTab()

    -- Utilities & Server
    Library.CreateSection(tabUtilities, "Utilities")
    Library.CreateButton(tabUtilities, "Server Hop", function()
        Library.notify("Server Hop", "Searching for a new server...")
        local ok, res = pcall(function() return game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100") end)
        if not ok then Library.notify("Server Hop", "Failed to get server list"); return end
        local ok2, data = pcall(function() return HttpService:JSONDecode(res) end)
        if not ok2 or type(data) ~= "table" or type(data.data) ~= "table" then Library.notify("Server Hop", "Failed to parse server list"); return end
        local candidates = {}
        for _, s in ipairs(data.data) do if s.id and s.id ~= game.JobId and type(s.playing) == "number" and s.playing < (s.maxPlayers or 999) then table.insert(candidates, s.id) end end
        if #candidates == 0 then Library.notify("Server Hop", "No other servers found"); return end
        local pick = candidates[math.random(1, #candidates)]
        pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, pick, LocalPlayer) end)
    end)
    Library.CreateButton(tabUtilities, "Rejoin", function()
        Library.notify("Rejoin", "Rejoining...")
        pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
        task.wait(0.5)
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    end)

    local sessionStart = os.clock()
    local sessionDeaths, sessionWalked, lastRootPos = 0, 0, nil
    Library.CreateSection(tabServer, "This Server")
    local srvPlaceL = Library.CreateLabel(tabServer, "Place: " .. game.PlaceId)
    local srvJobL = Library.CreateLabel(tabServer, "Job: " .. (game.JobId ~= "" and game.JobId or "none"))
    local srvUsersL = Library.CreateLabel(tabServer, "Users: --")
    local srvUptimeL = Library.CreateLabel(tabServer, "Uptime: 00:00:00")
    local srvPingL = Library.CreateLabel(tabServer, "Ping: --")
    Library.CreateSection(tabServer, "Session")
    local sesPlayL = Library.CreateLabel(tabServer, "Playtime: 00:00:00")
    local sesDeathsL = Library.CreateLabel(tabServer, "Deaths: 0")
    local sesWalkL = Library.CreateLabel(tabServer, "Walked: 0 studs")
    
    task.spawn(function()
        local ok, info = pcall(function() return Marketplace:GetProductInfo(game.PlaceId) end)
        if ok and info and info.Name then srvPlaceL.Text = "Place: " .. game.PlaceId .. " (" .. info.Name .. ")" end
    end)
    LocalPlayer.CharacterAdded:Connect(function(char)
        local h = char:WaitForChild("Humanoid", 5)
        if h then h.Died:Connect(function() sessionDeaths = sessionDeaths + 1 end) end
    end)
    RunService.Heartbeat:Connect(function()
        local r = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if r then
            if lastRootPos then local d = (r.Position - lastRootPos).Magnitude; if d < 50 then sessionWalked = sessionWalked + d end end
            lastRootPos = r.Position
        else lastRootPos = nil end
    end)
    task.spawn(function()
        while true do
            task.wait(1)
            pcall(function()
                srvUsersL.Text = "Users: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers
                srvPingL.Text = "Ping: " .. math.floor(game:GetService("Stats").PerformanceStats.Ping:GetValue()) .. " ms"
                local uptime = os.clock() - sessionStart
                srvUptimeL.Text = string.format("Uptime: %02d:%02d:%02d", math.floor(uptime/3600), math.floor((uptime%3600)/60), uptime%60)
                sesPlayL.Text = string.format("Playtime: %02d:%02d:%02d", math.floor((os.clock()-sessionStart)/3600), math.floor(((os.clock()-sessionStart)%3600)/60), (os.clock()-sessionStart)%60)
                sesDeathsL.Text = "Deaths: " .. sessionDeaths
                sesWalkL.Text = "Walked: " .. math.floor(sessionWalked) .. " studs"
            end)
        end
    end)

    -- Settings
    Library.CreateSection(tabSettings, "UI Customization")
    
    local function parseRGB(str) local r,g,b = string.match(str, "(%d+)%s*,%s*(%d+)%s*,%s*(%d+)"); return r and Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b)) or nil end
    local function formatColor(c) return math.floor(c.R*255)..", "..math.floor(c.G*255)..", "..math.floor(c.B*255) end
    
    local colorSettings = {
        { "Main Window Color: ", formatColor(Library.getColor("MainWindow")), function(c) Library.setColor("MainWindow", c); Library.applyTheme(); Library.autoSaveConfig(true) end},
        { "Top Bar Color: ", formatColor(Library.getColor("TopBar")), function(c) Library.setColor("TopBar", c); Library.applyTheme(); Library.autoSaveConfig(true) end},
        { "Side Bar Color: ", formatColor(Library.getColor("SideBar")), function(c) Library.setColor("SideBar", c); Library.applyTheme(); Library.autoSaveConfig(true) end},
        { "Text Color: ", formatColor(Library.getColor("Text")), function(c) Library.setColor("Text", c); Library.applyTheme(); Library.autoSaveConfig(true) end},
        { "Button Color: ", formatColor(Library.getColor("Button")), function(c) Library.setColor("Button", c); Library.applyTheme(); Library.autoSaveConfig(true) end},
        { "TextBox Background Color: ", formatColor(Library.getColor("TextBox")), function(c) Library.setColor("TextBox", c); Library.applyTheme(); Library.autoSaveConfig(true) end},
        { "Toggle ON Color: ", formatColor(Library.getColor("ToggleOn")), function(c) Library.setColor("ToggleOn", c); Library.applyTheme(); Library.autoSaveConfig(true) end},
        { "Toggle OFF Color: ", formatColor(Library.getColor("ToggleOff")), function(c) Library.setColor("ToggleOff", c); Library.applyTheme(); Library.autoSaveConfig(true) end}
    }
    for _, cfg in ipairs(colorSettings) do
        local container = create("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = tabSettings})
        create("TextLabel", {Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1, Text = cfg[1], TextColor3 = Library.getColor("Text"), TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, Parent = container})
        local box = Library.CreateTextBox(container, cfg[2], Enum.Font.Code)
        box.Size = UDim2.new(0.5, 0, 0.8, 0); box.Position = UDim2.new(0.48, 0, 0.1, 0); box.TextSize = 12
        box.FocusLost:Connect(function(enterPressed)
            if enterPressed or box.Text ~= "" then
                local color = parseRGB(box.Text)
                if color then cfg[3](color); box.Text = formatColor(color)
                else box.Text = "Invalid format!" end
            end
        end)
    end

    Library.CreateSection(tabSettings, "Background & Window")
    local keyBindBtn = Library.CreateButton(tabSettings, "Menu Toggle Key: " .. Library.getToggleKey().Name, function()
        keyBindBtn.Text = "...Press any Key..."
        local conn; conn = game:GetService("UserInputService").InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                Library.setToggleKey(input.KeyCode); keyBindBtn.Text = "Menu Toggle Key: " .. input.KeyCode.Name
                Library.autoSaveConfig(true); conn:Disconnect()
            end
        end)
    end)

    Library.CreateDropdown(tabSettings, "Background Image", function() local o = {"None"}; for _, f in ipairs(Library.getBackgroundFiles()) do table.insert(o, f) end; return o end, function() return Library.getBackgroundFile() == "" and "None" or Library.getBackgroundFile() end, function(opt) Library.setBackgroundFile((opt == "None") and "" or opt); Library.applyTheme() end)
    
    Library.CreateSlider(tabSettings, "Image Opacity", 0, 100, function() return math.floor(Library.getImageOpacity() * 100 + 0.5) end, function(v) Library.setImageOpacity(v / 100); Library.applyTheme() end, function(v) return v .. "%" end)
    Library.CreateSlider(tabSettings, "Blur", 0, 24, function() return Library.getBlurSize() end, function(v) Library.setBlurSize(v); Library.applyTheme() end, function(v) return v .. "px" end)
    Library.CreateDropdown(tabSettings, "Fit", function() return {"Fill", "Fit", "Stretch", "Tile", "Center", "Zoom"} end, function() return Library.getFitMode() end, function(opt) Library.setFitMode(opt); Library.applyTheme() end)
    Library.CreateSlider(tabSettings, "Gui Opacity", 25, 100, function() return math.floor(Library.getGuiOpacity() * 100 + 0.5) end, function(v) Library.setGuiOpacity(v / 100); Library.applyTheme() end, function(v) return v .. "%" end)
    
    -- Конфиги
    Library.CreateSection(tabSettings, "Configs")
    local configFolder = "EmilyUi/FuckYou/Configs"
    local configNameBox = Library.CreateTextBox(tabSettings, "Config name...", FONT)
    configNameBox.Size = UDim2.new(1, 0, 0, 30)
    
    Library.CreateButton(tabSettings, "Save config", function()
        local name = string.gsub(configNameBox.Text, "%s+", " ")
        if name == "" then Library.notify("Configs", "Enter a config name!"); return end
        pcall(function() if not isfolder("EmilyUi/FuckYou") then makefolder("EmilyUi/FuckYou") end; if not isfolder(configFolder) then makefolder(configFolder) end end)
        local ok, json = pcall(function() return HttpService:JSONEncode(Library.saveConfig()) end)
        if ok then writefile(configFolder .. "/" .. name .. ".json", json); Library.notify("Configs", "Saved: " .. name) end
    end)
    
    Library.CreateButton(tabSettings, "Reset defaults", function()
        Library.setToggleKey(Enum.KeyCode.P); keyBindBtn.Text = "P"
        Library.setColor("MainWindow", Color3.fromRGB(12, 12, 12))
        Library.setColor("TopBar", Color3.fromRGB(12, 12, 12))
        Library.setColor("SideBar", Color3.fromRGB(12, 12, 12))
        Library.setColor("Text", Color3.fromRGB(139, 135, 127))
        Library.setColor("Button", Color3.fromRGB(12, 12, 12))
        Library.setColor("TextBox", Color3.fromRGB(18, 18, 18))
        Library.setColor("ToggleOn", Color3.fromRGB(100, 255, 100))
        Library.setColor("ToggleOff", Color3.fromRGB(255, 100, 100))
        Library.setGuiOpacity(1); Library.setImageOpacity(1); Library.setBlurSize(0)
        Library.setFitMode("Fill"); Library.setBackgroundFile("")
        Library.applyTheme(); Library.autoSaveConfig(true); Library.notify("Configs", "Settings reset to defaults")
    end)

    -- Инициализация ключей
    Library.initKeySystem(window, topBar, sideBar, menuInsided, containment, function(group, daysLeft)
        Library.notify("Fuck you! is loaded", "Welcome! Role: " .. (group or "User"))
        local cfg = Library.loadConfig()
        if cfg then Library.applyTheme() end
        
        -- Профиль
        local UserProfilePanel = create("Frame", {Name = "UserProfilePanel", Parent = tabMain, Size = UDim2.new(1, 0, 0, 60), LayoutOrder = -1, BackgroundColor3 = Library.getColor("SideBar"), BorderColor3 = COL_BORDER})
        table.insert(themeElements.SideBars, UserProfilePanel)
        create("ImageLabel", {Parent = UserProfilePanel, Position = UDim2.new(0, 10, 0, 10), Size = UDim2.new(0, 40, 0, 40), BackgroundTransparency = 1, Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"})
        create("TextLabel", {Parent = UserProfilePanel, Position = UDim2.new(0, 60, 0, 6), Size = UDim2.new(1, -70, 0, 16), BackgroundTransparency = 1, Text = LocalPlayer.DisplayName, TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left})
        local UserKeyTimeLabel = create("TextLabel", {Parent = UserProfilePanel, Position = UDim2.new(0, 60, 0, 22), Size = UDim2.new(1, -70, 0, 14), BackgroundTransparency = 1, Text = "Days left: " .. tostring(daysLeft), TextColor3 = Color3.fromRGB(180, 180, 180), TextSize = 12, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left})
        local UserGroupLabel = create("TextLabel", {Parent = UserProfilePanel, Position = UDim2.new(0, 60, 0, 38), Size = UDim2.new(1, -70, 0, 14), BackgroundTransparency = 1, Text = "Group: " .. group, TextColor3 = Color3.fromRGB(150, 150, 150), TextSize = 12, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left})
        RunService.RenderStepped:Connect(function()
            if not window.Visible then return end
            local wave = math.sin(tick() * 5)
            if group == "Free" then UserGroupLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            elseif group == "User" then UserGroupLabel.TextColor3 = Color3.fromHSV(0.3 + wave * 0.05, 0.85, 0.95)
            elseif group == "Tester" then UserGroupLabel.TextColor3 = Color3.fromHSV(0.6 + wave * 0.05, 0.85, 0.95)
            elseif group == "Coder" then UserGroupLabel.TextColor3 = Color3.fromHSV(0.88 + wave * 0.04, 0.85, 0.95)
            else UserGroupLabel.TextColor3 = Color3.fromRGB(255, 255, 255) end
        end)
    end)

    -- Автозапуск первой вкладки
    EmilyUiBtn.MouseButton1Click:Connect(function()
        for _, t in ipairs(tabs) do t.Frame.Visible = (t.Name == "Main Info") end
        Library.applyTheme()
    end)

    return { Window = window, SideBar = sideBar, Menu = menuInsided, Containment = containment, Tabs = tabs }
end