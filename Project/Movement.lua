--// Movement.lua
return function(Library, ui)
    local create = Library.create
    local themeElements = Library.themeElements
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local HttpService = game:GetService("HttpService")
    local LocalPlayer = Players.LocalPlayer
    local FONT = Enum.Font.SpecialElite

    local MovementBtn = Library.CreateButton(ui.SideBar, "Movement", function() end)
    MovementBtn.Size = UDim2.new(1, 0, 0, 59); MovementBtn.Position = UDim2.new(0, 0, 0, 236)

    local movementTabs = {}
    local function addMovementTab(name, order, builder)
        local btn = Library.CreateButton(ui.Menu, name, function() end)
        btn.Size = UDim2.new(1, 0, 0, 40); btn.LayoutOrder = 400 + order; btn.Visible = false
        local frame = create("Frame", {Name = "Tab"..name, Parent = ui.Containment, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false})
        table.insert(movementTabs, {Name = name, Button = btn, Frame = frame})
        btn.MouseButton1Click:Connect(function()
            for _, t in ipairs(movementTabs) do t.Frame.Visible = (t.Name == name) end
            Library.applyTheme()
        end)
        builder(frame)
    end

    local FOLDER = "EmilyUi/Movement/Records"
    local SETTINGS_PATH = "EmilyUi/Movement/Keybinds/settings.json"
    local function ensureDirs() if makefolder then pcall(function() if not isfolder("EmilyUi/Movement") then makefolder("EmilyUi/Movement") end; if not isfolder(FOLDER) then makefolder(FOLDER) end end) end end
    local function loadJson(path) if isfile and isfile(path) then local ok, r = pcall(function() return HttpService:JSONDecode(readfile(path)) end); if ok and type(r) == "table" then return r end end; return {} end
    local function saveJson(path, data) if writefile then ensureDirs(); pcall(function() writefile(path, HttpService:JSONEncode(data)) end) end end

    local Settings = { CircleRadius = 5, CircleThickness = 0.3, CircleHeight = 0.15, CircleTransparency = 0.35, CircleMode = "Solid", PathPointSize = 0.35, TrailDistance = 10, ShowLabels = true, TextDistance = 60, Legit = true, PlaybackSpeed = 1, Loop = false }
    local loadedSettings = loadJson(SETTINGS_PATH)
    if loadedSettings.Settings then for k,v in pairs(loadedSettings.Settings) do Settings[k] = v end end

    local MovementEnabled = false
    local State = { Idle = 0, Recording = 1, Aligning = 2, Playing = 3 }
    local state = State.Idle
    local recorded = {}
    local recordStartTime = 0
    local playbackStart = 0
    local playbackIndex = 1
    local currentPlayback = nil
    local libraryData = { categories = { Default = {} } }
    local selectedCategory = "Default"
    local selectedRecording = nil

    local markersFolder = create("Folder", {Name = "MovementRecorderMarkers"})
    local markerData = {}

    local function createMarker(entry)
        if not entry or not entry.Frames or #entry.Frames < 1 then return end
        local model = create("Model", {Name = "MovementMarker"})
        local circle = create("Part", {Shape = Enum.PartType.Cylinder, Size = Vector3.new(Settings.CircleThickness, Settings.CircleRadius * 2, Settings.CircleRadius * 2), Anchored = true, CanCollide = false, Material = Enum.Material.Neon, Transparency = Settings.CircleTransparency})
        local pos = entry.Frames[1].cframe.Position
        circle.CFrame = CFrame.new(pos.X, pos.Y + Settings.CircleHeight, pos.Z) * CFrame.Angles(0, 0, math.rad(90))
        circle.Parent = model
        
        local billboard = create("BillboardGui", {Adornee = circle, Size = UDim2.new(0, 260, 0, 44), StudsOffset = Vector3.new(0, 4, 0), AlwaysOnTop = true, MaxDistance = Settings.TextDistance, Enabled = Settings.ShowLabels, Parent = model})
        create("TextLabel", { Parent = billboard, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = entry.Name, TextColor3 = Color3.fromRGB(255,255,255), TextSize = 16, Font = FONT })
        
        model.Parent = markersFolder
        markerData[entry] = { Model = model, Circle = circle, StartPos = pos }
    end

    local function rebuildMarkers()
        for _, data in pairs(markerData) do pcall(function() data.Model:Destroy() end) end
        markerData = {}
        for _, entry in ipairs(libraryData.categories[selectedCategory] or {}) do createMarker(entry) end
    end

    local function startRecording()
        if state ~= State.Idle or not MovementEnabled then return end
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        recorded = {}; recordStartTime = os.clock(); state = State.Recording
    end

    local function stopRecording(save)
        if state ~= State.Recording then return end
        state = State.Idle
        if save and #recorded >= 2 then
            local entry = { Name = "Recording_"..os.time(), Frames = recorded }
            table.insert(libraryData.categories[selectedCategory], entry)
            selectedRecording = entry
            createMarker(entry)
            saveJson(FOLDER .. "/" .. selectedCategory .. ".json", libraryData.categories[selectedCategory])
        end
        recorded = {}
    end

    local function requestPlayback(entry)
        if state ~= State.Idle or not MovementEnabled or not entry then return end
        state = State.Playing; playbackStart = os.clock(); playbackIndex = 1; currentPlayback = entry
        if not Settings.Legit and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = entry.Frames[1].cframe
        end
    end

    local function stopPlayback()
        if state ~= State.Playing and state ~= State.Aligning then return end
        state = State.Idle; currentPlayback = nil
    end

    RunService.Heartbeat:Connect(function()
        if state == State.Recording then
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local now = os.clock() - recordStartTime
                local last = recorded[#recorded]
                if not last or (root.Position - last.cframe.Position).Magnitude >= 0.05 or (now - last.time) >= 0.08 then
                    table.insert(recorded, {time = now, cframe = root.CFrame})
                end
            end
        elseif state == State.Playing and currentPlayback then
            local frames = currentPlayback.Frames
            local speed = tonumber(Settings.PlaybackSpeed) or 1
            local elapsed = (os.clock() - playbackStart) * speed
            local last = frames[#frames]
            if elapsed >= last.time then
                if Settings.Loop then playbackStart = os.clock(); playbackIndex = 1; elapsed = 0
                else stopPlayback(); return end
            end
            while playbackIndex < #frames and frames[playbackIndex + 1].time <= elapsed do playbackIndex = playbackIndex + 1 end
            local a = frames[playbackIndex]
            local b = frames[playbackIndex + 1] or a
            local target = a.cframe
            if b ~= a and b.time > a.time then
                local alpha = math.clamp((elapsed - a.time) / (b.time - a.time), 0, 1)
                target = a.cframe:Lerp(b.cframe, alpha)
            end
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame = target end
        end
    end)

    addMovementTab("Main", 1, function(parent)
        Library.CreateSection(parent, "MOVEMENT RECORDER")
        Library.CreateButton(parent, "Start Recording", function() startRecording() end)
        Library.CreateButton(parent, "Stop Recording", function() stopRecording(true) end)
        Library.CreateButton(parent, "Play Selected", function() requestPlayback(selectedRecording) end)
        Library.CreateButton(parent, "Stop Playback", function() stopPlayback() end)
    end)

    addMovementTab("Records", 2, function(parent)
        Library.CreateSection(parent, "RECORDINGS")
        for _, entry in ipairs(libraryData.categories[selectedCategory] or {}) do
            Library.CreateButton(parent, entry.Name, function() selectedRecording = entry end)
        end
    end)

    addMovementTab("Settings", 3, function(parent)
        Library.CreateSection(parent, "SETTINGS")
        Library.CreateToggle(parent, "Movement Enabled", MovementEnabled, function(v)
            MovementEnabled = v
            if MovementEnabled then markersFolder.Parent = workspace else markersFolder.Parent = nil; stopRecording(false); stopPlayback() end
        end)
        Library.CreateToggle(parent, "Legit Movement", Settings.Legit, function(v) Settings.Legit = v end)
        Library.CreateToggle(parent, "Loop Playback", Settings.Loop, function(v) Settings.Loop = v end)
        Library.CreateButton(parent, "Save Settings", function() saveJson(SETTINGS_PATH, {Settings = Settings}) end)
    end)

    MovementBtn.MouseButton1Click:Connect(function()
        for _, t in ipairs(movementTabs) do t.Button.Visible = true end
        if movementTabs[1] then movementTabs[1].Frame.Visible = true end
        Library.applyTheme()
    end)

    local catData = loadJson(FOLDER .. "/Default.json")
    if catData and type(catData) == "table" then libraryData.categories.Default = catData end
    rebuildMarkers()

    Library.registerKeyListProvider("Movement", function()
        local rows = {}
        if not MovementEnabled then return rows end
        if state == State.Recording then table.insert(rows, {"RECORD", "RECORDING..."})
        elseif (state == State.Playing or state == State.Aligning) and currentPlayback then table.insert(rows, {"PLAY", currentPlayback.Name or "ON"}) end
        return rows
    end)

    return { Tabs = movementTabs, Gather = function() return { Settings = Settings, Enabled = MovementEnabled } end, Apply = function(data) if data.Settings then for k,v in pairs(data.Settings) do Settings[k] = v end end; MovementEnabled = data.Enabled or false end, Reset = function() MovementEnabled = false; Settings.Legit = true; Settings.Loop = false end }
end