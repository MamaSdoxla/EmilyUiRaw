--// MusicModule.lua — Music Module
--// Вкладки: Home, Music, Settings, Materials, Grabber

local function initMusicModule(Library)
    local SoundService = game:GetService("SoundService")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local LocalPlayer = Players.LocalPlayer

    local FOLDER = "EmilyUi/Music"
    local FILE_MUSIC = FOLDER .. "/EmilyUiMusic.json"
    local FILE_SETTINGS = FOLDER .. "/EmilyUiMusicSettings.json"
    local FILE_GRABBER = FOLDER .. "/EmilyUiMusicGrabber.json"
    local FILE_BLACKLIST = FOLDER .. "/EmilyUiMusicGrabberBlackList.json"

    local function ensureDirs()
        if makefolder then
            pcall(function()
                if not isfolder("EmilyUi") then makefolder("EmilyUi") end
                if not isfolder(FOLDER) then makefolder(FOLDER) end
            end)
        end
    end

    local function saveJson(path, data)
        if writefile then
            ensureDirs()
            local ok, enc = pcall(function() return HttpService:JSONEncode(data) end)
            if ok then writefile(path, enc) end
        end
    end

    local function loadJson(path)
        if readfile and isfile and isfile(path) then
            local ok, dec = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
            if ok and type(dec) == "table" then return dec end
        end
    end

    local ScriptActive = true
    local ToggleState = false
    local Settings = {
        Body = 0, Angle = 25, Goal = 0.30, Split = 1,
        Parts = 2, Disposition = 3, Power = 400,
        Material = "Neon", Rainbow = true,
        StaticColor = Color3.new(1, 1, 1), Transparency = 0
    }
    local DataStructure = { Categories = { ["Default"] = {} } }
    local grabbedIds = {}
    local blacklistedIds = {}

    local function saveSettings()
        saveJson(FILE_SETTINGS, {
            Body = Settings.Body, Angle = Settings.Angle,
            Goal = Settings.Goal, Split = Settings.Split,
            Parts = Settings.Parts, Disposition = Settings.Disposition,
            Power = Settings.Power, Material = Settings.Material,
            Rainbow = Settings.Rainbow, Transparency = Settings.Transparency,
            StaticColor = {Settings.StaticColor.R*255, Settings.StaticColor.G*255, Settings.StaticColor.B*255}
        })
    end

    local function loadSettings()
        local d = loadJson(FILE_SETTINGS)
        if not d then return end
        for k, v in pairs(d) do
            if Settings[k] ~= nil then Settings[k] = v end
        end
    end

    local function saveMusicData() saveJson(FILE_MUSIC, DataStructure) end
    local function loadMusicData()
        local d = loadJson(FILE_MUSIC)
        if d and d.Categories then DataStructure = d else saveMusicData() end
    end
    local function saveGrabber() saveJson(FILE_GRABBER, grabbedIds) end
    local function loadGrabber()
        local d = loadJson(FILE_GRABBER)
        if d then grabbedIds = d end
        local b = loadJson(FILE_BLACKLIST)
        if b then
            for _, id in ipairs(b) do
                blacklistedIds[tonumber(id) or id] = true
            end
        end
    end

    loadMusicData(); loadSettings(); loadGrabber()

    --// Parts
    local Parts = Instance.new("Model")
    Parts.Name = "MusicParts"
    local musicSound = nil
    local currentSelectedId = ""
    local currentCategory = "Default"

    local function getRoot()
        return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    end

    local function rebuildParts(n)
        Settings.Parts = tonumber(n) or 2
        Parts:ClearAllChildren()
        local root = getRoot()
        if not root or not ToggleState then return end
        for i = 1, Settings.Parts do
            local p = Instance.new("Part", Parts)
            p.Color = Settings.StaticColor
            p.Transparency = Settings.Transparency
            p.Anchored = true; p.CanCollide = false
            p.Material = Enum.Material[Settings.Material] or Enum.Material.Neon
            p.Size = Vector3.new(0.2, 0.2, 0.2)
            p.CFrame = root.CFrame * CFrame.new(0, Settings.Body, 0)
        end
    end

    local function makeMusicSound(id)
        local s = Instance.new("Sound", Library.ScreenGui)
        s.Name = "Music"
        s.SoundId = "rbxassetid://" .. (id or "1")
        s.Looped = true; s.PlaybackSpeed = 1; s.Volume = 1
        return s
    end

    --// MUSIC TABS
    local musicTabs = {}
    local function addMusicTab(name, builder)
        local frame = Library.create("Frame", {
            Name = "Tab" .. name, Parent = Library.Containment,
            Size = UDim2.new(1,0,1,0),
            BackgroundTransparency = 1, BorderSizePixel = 0,
            Visible = false
        })
        builder(frame)
        local btn = Library.create("TextButton", {
            Name = "MBtn_" .. name, Parent = Library.MenuInsided,
            Size = UDim2.new(1, 0, 0, 40),
            LayoutOrder = 200 + #musicTabs, Visible = false,
            BackgroundColor3 = Library.uiColor_ButtonColor,
            BorderColor3 = Library.COL_BORDER,
            TextColor3 = Library.uiColor_TextColor,
            Text = name, Font = Library.FONT, TextSize = 12,
            TextWrapped = true
        })
        local entry = {Frame = frame, Name = name, Button = btn}
        table.insert(musicTabs, entry)
        table.insert(Library.themeElements.Buttons, btn)
        table.insert(Library.themeElements.Texts, btn)
        return entry
    end

    --// HOME TAB
    local function buildHome(parent)
        Library.createSection(parent, "HOME")
        local soundIdBox = Library.createTextBox(parent, "Sound ID", Library.FONT)
        soundIdBox.Size = UDim2.new(1, 0, 0, 30)
        Library.createContentButton(parent, "PLAY", function()
            if not ToggleState then return end
            if not musicSound or musicSound.Parent ~= Library.ScreenGui then
                musicSound = makeMusicSound(soundIdBox.Text ~= "" and soundIdBox.Text or "1")
            end
            musicSound.SoundId = "rbxassetid://" .. (soundIdBox.Text ~= "" and soundIdBox.Text or "1")
            musicSound:Play()
        end)
        Library.createContentButton(parent, "STOP", function()
            if musicSound then musicSound:Stop() end
        end)
    end

    --// MUSIC TAB
    local function buildMusic(parent)
        Library.createSection(parent, "MUSIC LIBRARY")
        Library.createLabel(parent, "Categories and tracks")
    end

    --// SETTINGS TAB
    local function buildSettings(parent)
        Library.createSection(parent, "SETTINGS")
        Library.createLabel(parent, "Visualizer settings")
    end

    --// MATERIALS TAB
    local function buildMaterials(parent)
        Library.createSection(parent, "MATERIALS")
        local materialsList = {"Neon", "Plastic", "Glass", "ForceField", "Wood"}
        for _, mat in ipairs(materialsList) do
            Library.createContentButton(parent, mat, function()
                Settings.Material = mat
                for _, c in ipairs(Parts:GetChildren()) do
                    if c:IsA("Part") then
                        c.Material = Enum.Material[mat] or Enum.Material.Neon
                    end
                end
                saveSettings()
            end)
        end
    end

    --// GRABBER TAB
    local function buildGrabber(parent)
        Library.createSection(parent, "GRABBER")
        Library.createLabel(parent, "Scan and grab game sounds")
        Library.createContentButton(parent, "Start Scanning", function()
            pcall(function()
                for _, v in ipairs(game:GetDescendants()) do
                    if v:IsA("Sound") and v.IsPlaying and v.SoundId ~= "" then
                        local rawId = v.SoundId:match("%d+")
                        if rawId then
                            local n = tonumber(rawId)
                            if n and not table.find(grabbedIds, n) and not blacklistedIds[n] then
                                table.insert(grabbedIds, n)
                            end
                        end
                    end
                end
            end)
            Library.notify("Grabber", "Scan complete")
        end)
    end

    addMusicTab("Home", buildHome)
    addMusicTab("Music", buildMusic)
    addMusicTab("Settings", buildSettings)
    addMusicTab("Materials", buildMaterials)
    addMusicTab("Grabber", buildGrabber)

    --// SIDEBAR TOGGLE
    local MusicSidebarToggle = Library.create("TextButton", {
        Name = "MToggle_Music", Parent = Library.MenuInsided,
        Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 290, Visible = false,
        BorderColor3 = Library.COL_BORDER,
        Text = "Music: OFF", Font = Library.FONT,
        TextSize = 12, TextWrapped = true,
        BackgroundTransparency = 1 - Library.uiGuiOpacity,
    })
    table.insert(Library.themeElements.CustomButtons, MusicSidebarToggle)
    table.insert(Library.moduleToggles, {btn = MusicSidebarToggle, group = "Music"})
    Library.registerToggle(MusicSidebarToggle, function() return ToggleState end)

    local function setMusicState(st)
        ToggleState = st and true or false
        if ToggleState then
            rebuildParts(Settings.Parts)
            if musicSound then musicSound:Play() end
        else
            if musicSound then musicSound:Stop() end
            Parts:ClearAllChildren()
        end
        MusicSidebarToggle.Text = "Music: " .. (ToggleState and "ON" or "OFF")
        Library.paintToggleBtn(MusicSidebarToggle, ToggleState)
    end

    MusicSidebarToggle.MouseButton1Click:Connect(function()
        setMusicState(not ToggleState)
    end)

    --// KEY LIST PROVIDER
    Library.registerKeyListProvider("Music", function()
        local rows = {}
        if not ToggleState then return rows end
        table.insert(rows, {"MUSIC", "ON"})
        return rows
    end)

    --// CLEANUP
    Library.ScreenGui.Destroying:Connect(function()
        pcall(function() setMusicState(false) end)
    end)

    return {
        Tabs = musicTabs,
    }
end

return initMusicModule