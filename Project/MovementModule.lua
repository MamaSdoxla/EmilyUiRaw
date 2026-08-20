--// MovementModule.lua — Movement Module
--// Вкладки: Main, Records, Categories, Colors, Settings, Keybinds

local function initMovementModule(Library)
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer

    local Movement = Library.makeSideBtn("Movement", 236)
    Movement.TextSize = 11
    Movement.TextWrapped = true

    local SETTINGS_PATH = "EmilyUi/Movement/Keybinds/settings.json"
    local RECORDS_FOLDER = "EmilyUi/Movement/Records"
    local CATEGORY_INDEX_PATH = RECORDS_FOLDER .. "/_categories.json"

    local Settings = {
        CircleRadius = 5, CircleThickness = 0.3,
        CircleHeight = 0.15, CircleTransparency = 0.35,
        CircleMode = "Solid",
        CircleColorA = {0, 140, 255},
        CircleColorB = {80, 255, 120},
        CircleColorC = {255, 170, 0},
        PathMode = "Solid",
        PathColorA = {80, 200, 255},
        PathColorB = {80, 255, 120},
        PathColorC = {255, 170, 0},
        PathTransparency = 0.25, PathPointSize = 0.35,
        TrailDistance = 10, TrailStep = 0,
        ShowPathPlayback = true,
        MinRecordDistance = 0.05, MinRecordTime = 0.08,
        ShowLabels = true, TextHeight = 4,
        TextTransparency = 0, TextDistance = 60,
        LabelMode = "Solid",
        LabelColorA = {255, 255, 255},
        LabelColorB = {80, 255, 120},
        LabelColorC = {255, 170, 0},
        PromptEnabled = true, PromptDistance = 12,
        PlaybackSpeed = 1, Loop = false, Legit = true,
    }

    local Keybinds = {
        Menu = "RightShift", Record = "R",
        Play = "P", Prompt = "E",
    }

    local MovementEnabled = false

    local function filesOK()
        return typeof(writefile) == "function"
            and typeof(readfile) == "function"
            and typeof(makefolder) == "function"
            and typeof(isfolder) == "function"
    end

    local function ensureFolders()
        if not filesOK() then return end
        pcall(function()
            if not isfolder("EmilyUi") then makefolder("EmilyUi") end
            if not isfolder("EmilyUi/Movement") then makefolder("EmilyUi/Movement") end
            if not isfolder("EmilyUi/Movement/Records") then makefolder("EmilyUi/Movement/Records") end
            if not isfolder("EmilyUi/Movement/Keybinds") then makefolder("EmilyUi/Movement/Keybinds") end
        end)
    end

    local function writeJSON(path, data)
        if not filesOK() then return end
        ensureFolders()
        local ok, json = pcall(function() return HttpService:JSONEncode(data) end)
        if ok then pcall(function() writefile(path, json) end) end
    end

    local function readJSON(path)
        if typeof(readfile) ~= "function" then return nil end
        local ok, json = pcall(function() return readfile(path) end)
        if not ok or type(json) ~= "string" or json == "" then return nil end
        local ok2, data = pcall(function() return HttpService:JSONDecode(json) end)
        if ok2 and type(data) == "table" then return data end
        return nil
    end

    local function saveSettings()
        writeJSON(SETTINGS_PATH, {Settings = Settings, Keybinds = Keybinds})
    end

    local function loadSettings()
        local d = readJSON(SETTINGS_PATH)
        if not d then return end
        if type(d.Settings) == "table" then
            for k, v in pairs(d.Settings) do
                if Settings[k] ~= nil and type(v) == type(Settings[k]) then
                    Settings[k] = v
                end
            end
        end
        if type(d.Keybinds) == "table" then
            for k, v in pairs(d.Keybinds) do
                if Keybinds[k] ~= nil and type(v) == "string" then
                    Keybinds[k] = v
                end
            end
        end
    end
    loadSettings()

    --// LIBRARY
    local library = {categories = {Default = {}}}
    local selectedCategory = "Default"
    local selectedRecording = nil

    local function sanitize(name)
        return tostring(name):gsub('[\\/:*?"<>|]', "_")
    end

    local function categoryPath(catName)
        return RECORDS_FOLDER .. "/" .. sanitize(catName)
    end

    local function ensureCategoryFolder(catName)
        if not filesOK() then return end
        pcall(function()
            if not isfolder(categoryPath(catName)) then
                makefolder(categoryPath(catName))
            end
        end)
    end

    local function generateRecordId()
        local ok, guid = pcall(function() return HttpService:GenerateGUID(false) end)
        if ok and type(guid) == "string" and guid ~= "" then return guid end
        return string.format("rec_%s_%d_%d",
            os.date("%Y%m%d%H%M%S"),
            math.floor(os.clock() * 1000),
            math.random(1000, 999999)
        )
    end

    local function serCF(cf)
        if typeof(cf) ~= "CFrame" then return {0, 0, 0} end
        return {cf:GetComponents()}
    end

    local function deCF(t)
        if type(t) ~= "table" then return CFrame.new() end
        if #t >= 12 then
            local ok, cf = pcall(function() return CFrame.new(unpack(t, 1, 12)) end)
            if ok then return cf end
        end
        if #t >= 3 then return CFrame.new(t[1], t[2], t[3]) end
        return CFrame.new()
    end

    local function serializeRecord(e)
        local frames = {}
        for _, f in ipairs(e.Frames or {}) do
            table.insert(frames, {f.time, serCF(f.cframe)})
        end
        return {
            N = e.Name, S = serCF(e.StartCFrame),
            F = frames, Id = e.Id
        }
    end

    local function deEntry(d)
        local frames = {}
        for _, f in ipairs(d.F or {}) do
            if type(f) == "table" and f[2] then
                table.insert(frames, {
                    time = tonumber(f[1]) or 0,
                    cframe = deCF(f[2])
                })
            end
        end
        return {
            Name = tostring(d.N or "Recording"),
            StartCFrame = deCF(d.S),
            Frames = frames,
            Id = tostring(d.Id or generateRecordId()),
        }
    end

    local function recordFilePath(catName, entry)
        return categoryPath(catName) .. "/" .. tostring(entry.Id or "record") .. ".json"
    end

    local function saveCategoryFile(catName)
        if not filesOK() then return end
        ensureFolders()
        ensureCategoryFolder(catName)
        for _, entry in ipairs(library.categories[catName] or {}) do
            if not entry.Id then entry.Id = generateRecordId() end
            writeJSON(recordFilePath(catName, entry), serializeRecord(entry))
        end
    end

    local function loadCategoryRecords(catName)
        local list = {}
        local path = categoryPath(catName)
        if typeof(isfolder) == "function" then
            local ok, exists = pcall(function() return isfolder(path) end)
            if ok and exists and typeof(listfiles) == "function" then
                local ok2, files = pcall(function() return listfiles(path) end)
                if ok2 and files then
                    for _, raw in ipairs(files) do
                        if raw:match("%.json$") and not raw:match("_") then
                            local data = readJSON(raw)
                            if type(data) == "table" then
                                local e = deEntry(data)
                                table.insert(list, e)
                            end
                        end
                    end
                end
            end
        end
        table.sort(list, function(a, b)
            return tostring(a.Name) < tostring(b.Name)
        end)
        return list
    end

    local function loadLibrary()
        library = {categories = {Default = {}}}
        if filesOK() and typeof(listfiles) == "function" then
            local ok, items = pcall(function() return listfiles(RECORDS_FOLDER) end)
            if ok and items then
                for _, raw in ipairs(items) do
                    local name = raw:match("([^/\\]+)$")
                    if name and not name:match("^_") then
                        if typeof(isfolder) == "function" then
                            local ok2, isDir = pcall(function() return isfolder(raw) end)
                            if ok2 and isDir then
                                library.categories[name] = loadCategoryRecords(name)
                            end
                        end
                    end
                end
            end
        end
        if not library.categories.Default then
            library.categories.Default = {}
        end
    end
    loadLibrary()

    --// STATE
    local State = {Idle = 0, Recording = 1, Aligning = 2, Playing = 3}
    local state = State.Idle
    local recorded = {}
    local recordStartTime = 0
    local playbackStart = 0
    local playbackIndex = 1
    local currentPlayback = nil
    local MAX_POINTS = 12000

    local character = LocalPlayer.Character
    local humanoid = nil
    local rootPart = nil

    local function isCharacterAlive()
        return humanoid and humanoid.Parent and rootPart and rootPart.Parent and humanoid.Health > 0
    end

    local function bindCharacter(newChar)
        character = newChar
        humanoid = newChar:FindFirstChildOfClass("Humanoid") or newChar:WaitForChild("Humanoid", 5)
        rootPart = newChar:FindFirstChild("HumanoidRootPart") or newChar:WaitForChild("HumanoidRootPart", 5)
    end

    LocalPlayer.CharacterAdded:Connect(bindCharacter)
    if LocalPlayer.Character then bindCharacter(LocalPlayer.Character) end

    --// MOVERS
    local movers = {kind = nil, attachment = nil, position = nil, orientation = nil}

    local function clearMovers()
        for _, key in ipairs({"attachment", "position", "orientation"}) do
            local o = movers[key]
            if o then pcall(function() o:Destroy() end) end
            movers[key] = nil
        end
        movers.kind = nil
    end

    local function createMovers()
        clearMovers()
        if not rootPart or not rootPart.Parent then return end
        pcall(function()
            local att = Instance.new("Attachment")
            att.Parent = rootPart
            local ap = Instance.new("AlignPosition")
            ap.Attachment0 = att
            ap.Mode = Enum.PositionAlignmentMode.OneAttachment
            ap.Position = rootPart.CFrame.Position
            ap.MaxForce = 100000
            ap.MaxVelocity = 5000
            ap.Responsiveness = 170
            ap.Parent = rootPart
            local ao = Instance.new("AlignOrientation")
            ao.Attachment0 = att
            ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
            ao.CFrame = rootPart.CFrame
            ao.MaxTorque = 100000
            ao.Responsiveness = 170
            ao.Parent = rootPart
            movers.kind = "Align"
            movers.attachment = att
            movers.position = ap
            movers.orientation = ao
        end)
    end

    local function setMoversTarget(cf)
        if movers.kind == "Align" then
            if movers.position then movers.position.Position = cf.Position end
            if movers.orientation then movers.orientation.CFrame = cf end
        end
    end

    --// RECORDING
    local function startRecording()
        if not MovementEnabled or state ~= State.Idle then return end
        if not isCharacterAlive() then return end
        recorded = {}
        recordStartTime = os.clock()
        state = State.Recording
    end

    local function stopRecording(save)
        if state ~= State.Recording then return end
        state = State.Idle
        if save == nil then save = true end
        if save and #recorded >= 2 then
            if not library.categories[selectedCategory] then
                library.categories[selectedCategory] = {}
            end
            local entry = {
                Id = generateRecordId(),
                Name = "Recording " .. os.date("%H:%M:%S"),
                StartCFrame = recorded[1].cframe,
                Frames = recorded,
            }
            table.insert(library.categories[selectedCategory], entry)
            selectedRecording = entry
            saveCategoryFile(selectedCategory)
        end
        recorded = {}
    end

    --// PLAYBACK
    local function beginPlayback(entry)
        state = State.Playing
        playbackStart = os.clock()
        playbackIndex = 1
        currentPlayback = entry
        if humanoid then humanoid.AutoRotate = false end
        if not Settings.Legit then clearMovers() end
    end

    local function stopPlayback()
        if state ~= State.Playing and state ~= State.Aligning then return end
        state = State.Idle
        currentPlayback = nil
        clearMovers()
        if humanoid then humanoid.AutoRotate = true end
    end

    local function requestPlayback(entry)
        if not MovementEnabled or state ~= State.Idle then return end
        entry = entry or selectedRecording
        if not entry or not entry.Frames or #entry.Frames < 2 then return end
        if not isCharacterAlive() then return end
        if Settings.Legit then
            state = State.Aligning
            currentPlayback = entry
            createMovers()
        else
            if rootPart then rootPart.CFrame = entry.Frames[1].cframe end
            beginPlayback(entry)
        end
    end

    --// HEARTBEAT
    RunService.Heartbeat:Connect(function()
        if state == State.Recording then
            if not isCharacterAlive() then
                stopRecording(false); return
            end
            local cf = rootPart.CFrame
            local now = os.clock() - recordStartTime
            local last = recorded[#recorded]
            if not last then
                table.insert(recorded, {time = now, cframe = cf})
            else
                local moved = (cf.Position - last.cframe.Position).Magnitude >= Settings.MinRecordDistance
                local timePassed = (now - last.time) >= Settings.MinRecordTime
                if moved or timePassed then
                    table.insert(recorded, {time = now, cframe = cf})
                end
            end
            if #recorded >= MAX_POINTS then stopRecording(true) end
        elseif state == State.Playing then
            if not isCharacterAlive() or not currentPlayback then
                stopPlayback(); return
            end
            local frames = currentPlayback.Frames
            local speed = tonumber(Settings.PlaybackSpeed) or 1
            if speed <= 0 then speed = 1 end
            local elapsed = (os.clock() - playbackStart) * speed
            local last = frames[#frames]
            if not last or last.time <= 0 then
                stopPlayback(); return
            end
            if elapsed >= last.time then
                if Settings.Loop then
                    playbackStart = os.clock()
                    playbackIndex = 1
                    elapsed = 0
                else
                    stopPlayback(); return
                end
            end
            while playbackIndex < #frames and frames[playbackIndex + 1].time <= elapsed do
                playbackIndex = playbackIndex + 1
            end
            local a = frames[playbackIndex]
            local b = frames[playbackIndex + 1] or a
            local target = a.cframe
            if b ~= a and b.time > a.time then
                local alpha = math.clamp((elapsed - a.time) / (b.time - a.time), 0, 1)
                target = a.cframe:Lerp(b.cframe, alpha)
            end
            if Settings.Legit then
                setMoversTarget(target)
            else
                if rootPart then rootPart.CFrame = target end
            end
        elseif state == State.Aligning then
            if not isCharacterAlive() or not currentPlayback then
                stopPlayback(); return
            end
            local first = currentPlayback.Frames[1]
            if first then setMoversTarget(first.cframe) end
            if rootPart and first then
                local d = (rootPart.Position - first.cframe.Position).Magnitude
                if d < 0.2 then beginPlayback(currentPlayback) end
            end
        end
    end)

    --// MOVEMENT TABS
    local movementTabs = {}
    local function addMovementTab(name, builder)
        local frame = Library.create("Frame", {
            Name = "Tab" .. name, Parent = Library.Containment,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1, BorderSizePixel = 0,
            Visible = false
        })
        local sf = Library.create("ScrollingFrame", {
            Parent = frame, Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 4,
            CanvasSize = UDim2.new(0, 0, 0, 0)
        })
        local tl = Library.create("UIListLayout", {
            Parent = sf, SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6)
        })
        Library.create("UIPadding", {
            Parent = sf, PaddingTop = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10)
        })
        tl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            sf.CanvasSize = UDim2.new(0, 0, 0, tl.AbsoluteContentSize.Y + 20)
        end)
        builder(sf)
        local btn = Library.create("TextButton", {
            Name = "MoveBtn_" .. name, Parent = Library.MenuInsided,
            Size = UDim2.new(1, 0, 0, 40),
            LayoutOrder = 400 + #movementTabs, Visible = false,
            BackgroundColor3 = Library.uiColor_ButtonColor,
            BorderColor3 = Library.COL_BORDER,
            TextColor3 = Library.uiColor_TextColor,
            Text = name, Font = Library.FONT, TextSize = 12,
            TextWrapped = true
        })
        local entry = {Frame = frame, Name = name, Button = btn}
        table.insert(movementTabs, entry)
        table.insert(Library.themeElements.Buttons, btn)
        table.insert(Library.themeElements.Texts, btn)
        return entry
    end

    --// MAIN TAB
    local statusLabel, infoLabel
    addMovementTab("Main", function(p)
        Library.createSection(p, "MOVEMENT RECORDER")
        statusLabel = Library.createLabel(p, "Ready.")
        Library.createSection(p, "Recording")
        Library.createContentButton(p, "Start Recording", function()
            startRecording()
            if statusLabel then statusLabel.Text = "Recording..." end
        end)
        Library.createContentButton(p, "Stop Recording", function()
            stopRecording(true)
            if statusLabel then statusLabel.Text = "Stopped." end
        end)
        Library.createSection(p, "Playback")
        Library.createContentButton(p, "Play Selected", function()
            requestPlayback(selectedRecording)
        end)
        Library.createContentButton(p, "Stop Playback", function()
            stopPlayback()
        end)
        Library.createSection(p, "Selected")
        infoLabel = Library.createLabel(p, "Nothing selected.")
    end)

    --// RECORDS TAB
    local recList
    addMovementTab("Records", function(p)
        Library.createSection(p, "RECORDINGS")
        recList = Library.create("ScrollingFrame", {
            Parent = p, Size = UDim2.new(1, 0, 0, 220),
            BackgroundColor3 = Library.uiColor_TextBoxColor,
            BorderColor3 = Library.COL_BORDER,
            ScrollBarThickness = 4,
            CanvasSize = UDim2.new(0, 0, 0, 0)
        })
        table.insert(Library.themeElements.TextBoxes, recList)
        local layout = Library.create("UIListLayout", {
            Parent = recList, SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 3)
        })
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            recList.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
        end)
    end)

    --// CATEGORIES TAB
    addMovementTab("Categories", function(p)
        Library.createSection(p, "CATEGORIES")
        Library.createLabel(p, "Manage recording categories")
    end)

    --// COLORS TAB
    addMovementTab("Colors", function(p)
        Library.createSection(p, "COLORS")
        Library.createLabel(p, "Configure circle/path/label colors")
    end)

    --// SETTINGS TAB
    addMovementTab("Settings", function(p)
        Library.createSection(p, "RECORDING")
        Library.createLabel(p, "Min Record Distance: " .. Settings.MinRecordDistance)
        Library.createSection(p, "CIRCLE")
        Library.createLabel(p, "Circle Radius: " .. Settings.CircleRadius)
        Library.createSection(p, "PLAYBACK")
        Library.createLabel(p, "Playback Speed: " .. Settings.PlaybackSpeed)
    end)

    --// KEYBINDS TAB
    addMovementTab("Keybinds", function(p)
        Library.createSection(p, "KEYBINDS")
        Library.createLabel(p, "Record: " .. Keybinds.Record)
        Library.createLabel(p, "Play: " .. Keybinds.Play)
        Library.createLabel(p, "Prompt: " .. Keybinds.Prompt)
    end)

    --// SIDEBAR TOGGLE
    local MovementSidebarToggle = Library.create("TextButton", {
        Name = "MToggle_Movement", Parent = Library.MenuInsided,
        Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 490, Visible = false,
        BorderColor3 = Library.COL_BORDER,
        Text = "Movement: OFF", Font = Library.FONT,
        TextSize = 12, TextWrapped = true,
        BackgroundTransparency = 1 - Library.uiGuiOpacity,
    })
    table.insert(Library.themeElements.CustomButtons, MovementSidebarToggle)
    table.insert(Library.moduleToggles, {btn = MovementSidebarToggle, group = "Movement"})
    Library.registerToggle(MovementSidebarToggle, function() return MovementEnabled end)

    local function setMovementEnabled(v)
        MovementEnabled = v and true or false
        MovementSidebarToggle.Text = "Movement: " .. (MovementEnabled and "ON" or "OFF")
        Library.paintToggleBtn(MovementSidebarToggle, MovementEnabled)
    end

    MovementSidebarToggle.MouseButton1Click:Connect(function()
        setMovementEnabled(not MovementEnabled)
    end)

    --// KEY LIST PROVIDER
    Library.registerKeyListProvider("Movement", function()
        local rows = {}
        if not MovementEnabled then return rows end
        if state == State.Recording then
            table.insert(rows, {"RECORD", "RECORDING..."})
        elseif (state == State.Playing or state == State.Aligning) and currentPlayback then
            table.insert(rows, {"PLAY", currentPlayback.Name or "ON"})
        end
        return rows
    end)

    --// CONFIG API
    local function gatherMovementConfig()
        return {
            Enabled = MovementEnabled,
            Settings = Settings,
            Keybinds = Keybinds,
            SelectedCategory = selectedCategory,
        }
    end

    local function applyMovementConfig(cfg)
        if type(cfg) ~= "table" then return end
        if type(cfg.Settings) == "table" then
            for k, v in pairs(cfg.Settings) do
                if Settings[k] ~= nil and type(v) == type(Settings[k]) then
                    Settings[k] = v
                end
            end
        end
        if type(cfg.Keybinds) == "table" then
            for k, v in pairs(cfg.Keybinds) do
                if Keybinds[k] ~= nil and type(v) == "string" then
                    Keybinds[k] = v
                end
            end
        end
        if cfg.Enabled ~= nil then setMovementEnabled(cfg.Enabled) end
    end

    local function resetMovementConfig()
        selectedCategory = "Default"
        selectedRecording = nil
        setMovementEnabled(false)
    end

    --// CLEANUP
    Library.ScreenGui.Destroying:Connect(function()
        pcall(function()
            setMovementEnabled(false)
            stopRecording(false)
            stopPlayback()
        end)
    end)

    return {
        Tabs = movementTabs,
        Gather = gatherMovementConfig,
        Apply = applyMovementConfig,
        Reset = resetMovementConfig,
    }
end

return initMovementModule