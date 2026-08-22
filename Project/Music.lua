--// Music.lua
return function(Library, ui)
    local create = Library.create
    local themeElements = Library.themeElements -- ИСПРАВЛЕНИЕ
    local SoundService = game:GetService("SoundService")
    local RunService = game:GetService("RunService")
    local HttpService = game:GetService("HttpService")
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local FONT = Enum.Font.SpecialElite

    local MusicBtn = Library.CreateButton(ui.SideBar, "Music", function() end)
    MusicBtn.Size = UDim2.new(1, 0, 0, 59); MusicBtn.Position = UDim2.new(0, 0, 0, 118)

    local musicTabs = {}
    local function addMusicTab(name, order, builder)
        local btn = Library.CreateButton(ui.Menu, name, function() end)
        btn.Size = UDim2.new(1, 0, 0, 40); btn.LayoutOrder = 200 + order; btn.Visible = false
        local frame = create("Frame", {Name = "Tab"..name, Parent = ui.Containment, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false})
        table.insert(musicTabs, {Name = name, Button = btn, Frame = frame})
        btn.MouseButton1Click:Connect(function()
            for _, t in ipairs(musicTabs) do t.Frame.Visible = (t.Name == name) end
            Library.applyTheme()
        end)
        builder(frame)
    end

    local FOLDER = "EmilyUi/Music"
    local FILE_MUSIC = FOLDER .. "/EmilyUiMusic.json"
    local FILE_SETTINGS = FOLDER .. "/EmilyUiMusicSettings.json"
    local function ensureDirs() if makefolder then pcall(function() if not isfolder("EmilyUi") then makefolder("EmilyUi") end; if not isfolder(FOLDER) then makefolder(FOLDER) end end) end end
    local function loadJson(path) if isfile and isfile(path) then local ok, r = pcall(function() return HttpService:JSONDecode(readfile(path)) end); if ok and type(r) == "table" then return r end end; return {Categories = {Default = {}}} end
    local function saveJson(path, data) if writefile then ensureDirs(); pcall(function() writefile(path, HttpService:JSONEncode(data)) end) end end

    local DataStructure = loadJson(FILE_MUSIC)
    local Settings = { Parts = 2, Rainbow = true, StaticColor = Color3.new(1,1,1), Transparency = 0, Body = 0, Angle = 25, Goal = 0.30, Split = 1, Disposition = 3, Power = 400, Material = "Neon" }
    local loadedSettings = loadJson(FILE_SETTINGS)
    if loadedSettings then for k,v in pairs(loadedSettings) do Settings[k] = v end end

    local ToggleState = false
    local musicSound = nil
    local Parts = create("Model", {Name = "MusicParts"})

    local function rebuildParts(n)
        Settings.Parts = tonumber(n) or 2
        Parts:ClearAllChildren()
        if not ToggleState then return end
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        for i = 1, Settings.Parts do
            local p = create("Part", {Parent = Parts, Color = Settings.StaticColor, Transparency = Settings.Transparency, Anchored = true, CanCollide = false, Material = Enum.Material[Settings.Material] or Enum.Material.Neon, Size = Vector3.new(0.2, 0.2, 0.2), CFrame = root.CFrame * CFrame.new(0, Settings.Body, 0)})
        end
    end

    local function makeMusicSound(id)
        local s = create("Sound", {Parent = game:GetService("CoreGui"), Name = "Music", SoundId = "rbxassetid://" .. (id or "1"), Looped = true, PlaybackSpeed = 1, Volume = 1})
        local conn; conn = RunService.Heartbeat:Connect(function()
            if s.IsPlaying and s.TimePosition >= 2 then
                s:Stop(); conn:Disconnect(); s:Destroy()
            end
        end)
        return s
    end

    addMusicTab("Home", 1, function(parent)
        Library.CreateSection(parent, "HOME")
        local idBox = Library.CreateTextBox(parent, "Sound ID", FONT)
        local volBox = Library.CreateTextBox(parent, "Volume (1)", FONT)
        local pitchBox = Library.CreateTextBox(parent, "Pitch (1)", FONT)
        Library.CreateButton(parent, "PLAY", function()
            if not ToggleState then return end
            if musicSound then musicSound:Destroy() end
            musicSound = makeMusicSound(idBox.Text ~= "" and idBox.Text or "1")
            musicSound.Volume = tonumber(volBox.Text) or 1
            musicSound.PlaybackSpeed = tonumber(pitchBox.Text) or 1
            musicSound:Play()
        end)
        Library.CreateButton(parent, "STOP", function() if musicSound then musicSound:Stop(); musicSound:Destroy(); musicSound = nil end end)
    end)

    addMusicTab("Music", 2, function(parent)
        Library.CreateSection(parent, "MUSIC LIBRARY")
        local searchBox = Library.CreateTextBox(parent, "Search ID / Name...", FONT)
        for catName, tracks in pairs(DataStructure.Categories) do
            Library.CreateSection(parent, catName)
            for id, td in pairs(tracks) do
                Library.CreateButton(parent, td.name or id, function()
                    if not ToggleState then return end
                    if musicSound then musicSound:Destroy() end
                    musicSound = makeMusicSound(id)
                    musicSound:Play()
                end)
            end
        end
    end)

    addMusicTab("Settings", 3, function(parent)
        Library.CreateSection(parent, "SETTINGS")
        Library.CreateToggle(parent, "Music Visualizer", ToggleState, function(v)
            ToggleState = v
            if ToggleState then Parts.Parent = LocalPlayer.Character or workspace; rebuildParts(Settings.Parts)
            else Parts:ClearAllChildren(); if musicSound then musicSound:Stop() end end
        end)
        Library.CreateButton(parent, "Save Settings", function() saveJson(FILE_SETTINGS, Settings) end)
    end)

    addMusicTab("Materials", 4, function(parent)
        Library.CreateSection(parent, "MATERIALS")
        local materialsList = {"Neon", "Plastic", "Glass", "ForceField", "Wood", "Marble", "Slate", "Granite", "Brick", "Metal", "Ice", "Sand", "Fabric"}
        for _, mat in ipairs(materialsList) do
            Library.CreateButton(parent, mat, function()
                Settings.Material = mat
                for _, c in ipairs(Parts:GetChildren()) do if c:IsA("Part") then c.Material = Enum.Material[mat] or Enum.Material.Neon end end
            end)
        end
    end)

    addMusicTab("Grabber", 5, function(parent)
        Library.CreateSection(parent, "GRABBER")
        Library.CreateButton(parent, "START SCAN", function()
            Library.notify("Grabber", "Scanning workspace for sounds...")
            local count = 0
            for _, v in ipairs(game:GetDescendants()) do
                if v:IsA("Sound") and v.IsPlaying and v.SoundId ~= "" then
                    local rawId = v.SoundId:match("%d+")
                    if rawId then
                        if not DataStructure.Categories["Grabbed"] then DataStructure.Categories["Grabbed"] = {} end
                        DataStructure.Categories["Grabbed"][rawId] = {name = "Grabbed_"..rawId, volume = 1, pitch = 1}
                        count = count + 1
                    end
                end
            end
            saveJson(FILE_MUSIC, DataStructure)
            Library.notify("Grabber", "Found and saved " .. count .. " sounds.")
        end)
    end)

    MusicBtn.MouseButton1Click:Connect(function()
        for _, t in ipairs(musicTabs) do t.Button.Visible = true end
        if musicTabs[1] then musicTabs[1].Frame.Visible = true end
        Library.applyTheme()
    end)

    Library.registerKeyListProvider("Music", function()
        local rows = {}
        if ToggleState then table.insert(rows, {"MUSIC", "ON"}) end
        return rows
    end)

    return { Tabs = musicTabs, Gather = function() return {} end, Apply = function() end, Reset = function() end }
end