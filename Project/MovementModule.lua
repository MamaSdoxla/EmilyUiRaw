-- ============================================================
-- MovementModule.lua
-- ============================================================
-- Модуль Movement: запись/воспроизведение, маркеры, категории.
-- Использует FuckYouLib.
-- ============================================================

local FuckYouLib = _G.FuckYouLib
if not FuckYouLib then error("FuckYouLibrary not loaded") end

local COL_BORDER = FuckYouLib.COL_BORDER
local FONT = FuckYouLib.FONT

local C_GRN = Color3.fromRGB(100,255,100)
local C_ROFF = Color3.fromRGB(255,100,100)
local C_REDD = Color3.fromRGB(150,40,40)

local SETTINGS_PATH = "EmilyUi/Movement/Keybinds/settings.json"
local RECORDS_FOLDER = "EmilyUi/Movement/Records"
local CATEGORY_INDEX_PATH = RECORDS_FOLDER .. "/_categories.json"
local OLD_INDEX_PATH = RECORDS_FOLDER .. "/_index.json"

local COLOR_MODES = {"Solid", "TwoWay", "ThreeWay", "Rainbow"}

local Settings = {
    CircleRadius = 5,
    CircleThickness = 0.3,
    CircleHeight = 0.15,
    CircleTransparency = 0.35,
    CircleMode = "Solid",
    CircleColorA = {0, 140, 255},
    CircleColorB = {80, 255, 120},
    CircleColorC = {255, 170, 0},
    PathMode = "Solid",
    PathColorA = {80, 200, 255},
    PathColorB = {80, 255, 120},
    PathColorC = {255, 170, 0},
    PathTransparency = 0.25,
    PathPointSize = 0.35,
    TrailDistance = 10,
    TrailStep = 0,
    ShowPathPlayback = true,
    MinRecordDistance = 0.05,
    MinRecordTime = 0.08,
    ShowLabels = true,
    TextHeight = 4,
    TextTransparency = 0,
    TextDistance = 60,
    LabelMode = "Solid",
    LabelColorA = {255, 255, 255},
    LabelColorB = {80, 255, 120},
    LabelColorC = {255, 170, 0},
    PromptEnabled = true,
    PromptDistance = 12,
    PlaybackSpeed = 1,
    Loop = false,
    Legit = true,
}

local Keybinds = {
    Menu = "RightShift",
    Record = "R",
    Play = "P",
    Prompt = "E",
}

local MovementEnabled = false

local function keyCodeByName(n)
    if not n or n == "" then return Enum.KeyCode.Unknown end
    local ok, e = pcall(function() return Enum.KeyCode[n] end)
    if ok and e then return e end
    return Enum.KeyCode.Unknown
end

local function movementKeyName(v)
    if type(v) == "string" and v ~= "" then return v end
    return "None"
end

local function lighter(c, amt)
    return Color3.fromRGB(math.min(c.R*255+amt,255), math.min(c.G*255+amt,255), math.min(c.B*255+amt,255))
end
local function darker(c, amt)
    return Color3.fromRGB(math.max(c.R*255-amt,0), math.max(c.G*255-amt,0), math.max(c.B*255-amt,0))
end
local function trim(s)
    return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

-- File helpers
local function filesOK()
    return typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(makefolder) == "function" and typeof(isfolder) == "function"
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

local function sanitize(name)
    return tostring(name):gsub('[\\/:*?"<>|]', "_")
end

local function saveSettings()
    writeJSON(SETTINGS_PATH, {Settings = Settings, Keybinds = Keybinds})
    if FuckYouLib.autoSaveConfig then FuckYouLib.autoSaveConfig() end
end

local function loadSettings()
    local d = readJSON(SETTINGS_PATH)
    if not d then return end
    local raw = d.Settings
    if type(raw) == "table" then
        for _, k in ipairs({"CircleMode", "PathMode", "LabelMode"}) do
            if raw[k] == "Gradient" then raw[k] = "TwoWay" end
            if raw[k] == "TriColor" then raw[k] = "ThreeWay" end
        end
        if type(raw.TextColor) == "table" and type(raw.LabelColorA) ~= "table" then
            raw.LabelColorA = raw.TextColor
        end
        for k, v in pairs(raw) do
            if Settings[k] ~= nil and type(v) == type(Settings[k]) then
                Settings[k] = v
            end
        end
    end
    for _, k in ipairs({"CircleMode", "PathMode", "LabelMode"}) do
        if not table.find(COLOR_MODES, Settings[k]) then Settings[k] = "Solid" end
    end
    if type(d.Keybinds) == "table" then
        for k, v in pairs(d.Keybinds) do
            if Keybinds[k] ~= nil and type(v) == "string" then Keybinds[k] = v end
        end
    end
end
loadSettings()

-- Serialization
local function serCF(cf)
    if typeof(cf) ~= "CFrame" then return {0,0,0} end
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
local function serEntry(e)
    local frames = {}
    for _, f in ipairs(e.Frames or {}) do
        table.insert(frames, {f.time, serCF(f.cframe)})
    end
    return {N = e.Name, S = serCF(e.StartCFrame), F = frames}
end
local function deEntry(d)
    local frames = {}
    for _, f in ipairs(d.F or {}) do
        if type(f) == "table" and f[2] then
            table.insert(frames, {time = tonumber(f[1]) or 0, cframe = deCF(f[2])})
        end
    end
    local e = {Name = tostring(d.N or "Recording"), StartCFrame = deCF(d.S), Frames = frames}
    if #frames > 0 and not d.S then e.StartCFrame = frames[1].cframe end
    return e
end

-- Library
local library = {categories = {Default = {}}}
local selectedCategory = "Default"
local selectedRecording = nil

local function normalizeChildPath(base, child)
    child = tostring(child)
    if child:find("[/\\]") or child:match("^%a:") then return child end
    return base .. "/" .. child
end

local function categoryPath(catName)
    return RECORDS_FOLDER .. "/" .. sanitize(catName)
end

local function ensureCategoryFolder(catName)
    if not filesOK() then return end
    pcall(function()
        if not isfolder(categoryPath(catName)) then makefolder(categoryPath(catName)) end
    end)
end

local function generateRecordId()
    local ok, guid = pcall(function() return HttpService:GenerateGUID(false) end)
    if ok and type(guid) == "string" and guid ~= "" then return guid end
    return string.format("rec_%s_%d_%d", os.date("%Y%m%d%H%M%S"), math.floor(os.clock()*1000), math.random(1000,999999))
end

local function serializeRecord(e)
    local d = serEntry(e)
    d.Id = e.Id
    return d
end

local function recordFilePath(catName, entry)
    return categoryPath(catName) .. "/" .. tostring(entry.Id or "record") .. ".json"
end

local function sortCategoryNames(names)
    table.sort(names, function(a,b)
        if a == "Default" then return true end
        if b == "Default" then return false end
        return tostring(a) < tostring(b)
    end)
end

local function getCategoryNames()
    local names = {}
    local function addName(n)
        n = tostring(n or "")
        if n == "" then return end
        if n:find("^_") then return end
        if not table.find(names, n) then table.insert(names, n) end
    end
    local indexData = readJSON(CATEGORY_INDEX_PATH)
    local hasIndex = false
    if indexData and type(indexData.categories) == "table" then
        hasIndex = true
        for _, n in ipairs(indexData.categories) do addName(n) end
    end
    if not hasIndex then
        local oldIndex = readJSON(OLD_INDEX_PATH)
        if oldIndex and type(oldIndex.categories) == "table" then
            for _, n in ipairs(oldIndex.categories) do addName(n) end
        end
        if typeof(listfiles) == "function" then
            local ok, items = pcall(function() return listfiles(RECORDS_FOLDER) end)
            if ok and items then
                for _, raw in ipairs(items) do
                    local p = normalizeChildPath(RECORDS_FOLDER, raw)
                    local base = p:match("([^/\\]+)$") or ""
                    local isDir = false
                    if typeof(isfolder) == "function" then
                        local ok2, val = pcall(function() return isfolder(p) end)
                        isDir = ok2 and val
                    end
                    if isDir then
                        if not base:find("^_") then addName(base) end
                    else
                        local name = base:match("^(.*)%.json$")
                        if name and name ~= "_index" and name ~= "_categories" then addName(name) end
                    end
                end
            end
        end
    end
    addName("Default")
    sortCategoryNames(names)
    return names
end

local function saveCategoryIndex()
    local names = {}
    for n in pairs(library.categories) do table.insert(names, n) end
    sortCategoryNames(names)
    writeJSON(CATEGORY_INDEX_PATH, {categories = names})
end

local function deleteFilesInFolder(path)
    if typeof(listfiles) ~= "function" or typeof(delfile) ~= "function" then return end
    local ok, items = pcall(function() return listfiles(path) end)
    if not ok or not items then return end
    for _, raw in ipairs(items) do
        local p = normalizeChildPath(path, raw)
        if p:match("%.json$") then pcall(function() delfile(p) end) end
    end
end

local function saveCategoryFile(catName)
    if not filesOK() then return end
    ensureFolders()
    ensureCategoryFolder(catName)
    local path = categoryPath(catName)
    deleteFilesInFolder(path)
    for _, entry in ipairs(library.categories[catName] or {}) do
        if not entry.Id then entry.Id = generateRecordId() end
        writeJSON(recordFilePath(catName, entry), serializeRecord(entry))
    end
    saveCategoryIndex()
end

local function deleteCategoryFile(catName)
    if filesOK() then
        local path = categoryPath(catName)
        deleteFilesInFolder(path)
        if typeof(delfolder) == "function" then pcall(function() delfolder(path) end) end
    end
    saveCategoryIndex()
end

local function migrateOldCategory(catName)
    local list = {}
    local oldFile = RECORDS_FOLDER .. "/" .. sanitize(catName) .. ".json"
    local data = readJSON(oldFile)
    if data ~= nil then
        if type(data) == "table" then
            for _, d in ipairs(data) do
                local e = deEntry(d)
                if not e.Id then e.Id = generateRecordId() end
                table.insert(list, e)
            end
        end
        if filesOK() and typeof(delfile) == "function" then pcall(function() delfile(oldFile) end) end
    end
    if #list > 0 and filesOK() then
        ensureCategoryFolder(catName)
        for _, e in ipairs(list) do
            writeJSON(recordFilePath(catName, e), serializeRecord(e))
        end
    end
    return list
end

local function loadCategoryRecords(catName)
    local list = {}
    local path = categoryPath(catName)
    local folderExists = false
    if typeof(isfolder) == "function" then
        local ok, exists = pcall(function() return isfolder(path) end)
        folderExists = ok and exists
    end
    if folderExists then
        if typeof(listfiles) == "function" then
            local ok, files = pcall(function() return listfiles(path) end)
            if ok and files then
                for _, raw in ipairs(files) do
                    local fp = normalizeChildPath(path, raw)
                    if fp:match("%.json$") then
                        local data = readJSON(fp)
                        if type(data) == "table" then
                            local e = deEntry(data)
                            e.Id = tostring(data.Id or fp:match("([^/\\]+)%.json$") or generateRecordId())
                            table.insert(list, e)
                        end
                    end
                end
            end
        end
        table.sort(list, function(a,b) return tostring(a.Name) < tostring(b.Name) end)
    else
        list = migrateOldCategory(catName)
    end
    return list
end

local function loadLibrary()
    library = {categories = {}}
    local names = getCategoryNames()
    for _, n in ipairs(names) do
        library.categories[n] = loadCategoryRecords(n)
    end
    if not library.categories.Default then library.categories.Default = {} end
    if not library.categories[selectedCategory] then selectedCategory = "Default" end
    selectedRecording = nil
    if filesOK() then
        for n in pairs(library.categories) do ensureCategoryFolder(n) end
    end
    saveCategoryIndex()
end

-- Character
local character = LocalPlayer.Character
local humanoid = nil
local rootPart = nil
local characterDiedConnection = nil

local function isFiniteNumber(v)
    return typeof(v) == "number" and v == v and math.abs(v) ~= math.huge
end
local function isFiniteCFrame(cf)
    if typeof(cf) ~= "CFrame" then return false end
    for _, v in ipairs({cf:GetComponents()}) do
        if not isFiniteNumber(v) then return false end
    end
    return true
end
local function isCharacterAlive()
    return humanoid and humanoid.Parent and rootPart and rootPart.Parent and humanoid.Health > 0
end

-- Color helpers
local function cArr(a)
    return Color3.fromRGB(a[1] or 255, a[2] or 255, a[3] or 255)
end
local function cycle3(a, b, c, t)
    t = t % 1
    if t < 1/3 then return a:Lerp(b, t*3)
    elseif t < 2/3 then return b:Lerp(c, (t-1/3)*3)
    end
    return c:Lerp(a, (t-2/3)*3)
end
local function pathColorAt(t)
    local mode = Settings.PathMode
    local a = cArr(Settings.PathColorA)
    local b = cArr(Settings.PathColorB)
    local c = cArr(Settings.PathColorC)
    if mode == "TwoWay" then return a:Lerp(b, t) end
    if mode == "ThreeWay" then return cycle3(a,b,c,t) end
    if mode == "Rainbow" then return Color3.fromHSV(t%1,1,1) end
    return a
end
local function timeColorAt(mode, arrA, arrB, arrC, t)
    local a = cArr(arrA); local b = cArr(arrB); local c = cArr(arrC)
    if mode == "TwoWay" then return a:Lerp(b, (math.sin(t*1.6)+1)/2)
    elseif mode == "ThreeWay" then return cycle3(a,b,c,t*0.25)
    elseif mode == "Rainbow" then return Color3.fromHSV((t*0.12)%1,1,1) end
    return a
end
local function circleColorAt(t)
    return timeColorAt(Settings.CircleMode, Settings.CircleColorA, Settings.CircleColorB, Settings.CircleColorC, t)
end
local function labelColorAt(t)
    return timeColorAt(Settings.LabelMode, Settings.LabelColorA, Settings.LabelColorB, Settings.LabelColorC, t)
end

-- Connections
local movementConnections = {}
local function mConnect(sig, cb)
    local cn = sig:Connect(cb)
    table.insert(movementConnections, cn)
    return cn
end

local setStatus, updateButtons, refreshMainInfo
local refreshRecordings, refreshCategories
local rebuildMarkers
local requestPlayback, stopPlayback, stopRecording, startRecording
local movementBindCapture = nil
local nameBox = nil

-- Markers
local markersFolder = Instance.new("Folder")
markersFolder.Name = "MovementRecorderMarkers"
pcall(function() markersFolder.Parent = nil end)
local markerData = {}

local function createTrajectory(entry, model)
    local frames = entry.Frames
    if not frames or #frames < 2 then return end
    local step
    if Settings.TrailStep > 0 then step = math.max(1, math.floor(Settings.TrailStep))
    else step = math.max(1, math.floor(#frames / 140)) end
    local total = math.floor((#frames - 1) / step) + 1
    local idx = 0
    for i = 1, #frames, step do
        local f = frames[i]
        if f and f.cframe then
            local p = Instance.new("Part")
            p.Anchored = true; p.CanCollide = false
            pcall(function() p.CanTouch = false; p.CanQuery = false end)
            p.Size = Vector3.new(Settings.PathPointSize, Settings.PathPointSize, Settings.PathPointSize)
            p.Material = Enum.Material.Neon
            p.Color = pathColorAt(total > 1 and (idx / (total - 1)) or 0)
            p.Transparency = Settings.PathTransparency
            p.CFrame = CFrame.new(f.cframe.Position)
            p.Parent = model
            idx = idx + 1
        end
    end
end

local function createMarker(entry)
    if not entry then return end
    if markerData[entry] then
        pcall(function() markerData[entry].Model:Destroy() end)
        markerData[entry] = nil
    end
    if not entry.StartCFrame and entry.Frames and entry.Frames[1] then
        entry.StartCFrame = entry.Frames[1].cframe
    end
    if not entry.StartCFrame then return end
    local model = Instance.new("Model")
    model.Name = "MovementMarker"
    local circle = Instance.new("Part")
    circle.Name = "Circle"
    circle.Shape = Enum.PartType.Cylinder
    circle.Size = Vector3.new(Settings.CircleThickness, Settings.CircleRadius * 2, Settings.CircleRadius * 2)
    circle.Anchored = true; circle.CanCollide = false
    pcall(function() circle.CanTouch = false; circle.CanQuery = false end)
    circle.Material = Enum.Material.Neon
    circle.Color = circleColorAt(0)
    circle.Transparency = Settings.CircleTransparency
    local pos = entry.StartCFrame.Position
    circle.CFrame = CFrame.new(pos.X, pos.Y + Settings.CircleHeight, pos.Z) * CFrame.Angles(0,0,math.rad(90))
    circle.Parent = model
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = circle
    billboard.Size = UDim2.new(0,260,0,44)
    billboard.StudsOffset = Vector3.new(0, Settings.TextHeight, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = Settings.TextDistance
    billboard.Enabled = Settings.ShowLabels
    billboard.Parent = model
    local label = FuckYouLib.create("TextLabel", {
        Parent = billboard, Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1, Text = entry.Name,
        TextColor3 = labelColorAt(0), TextTransparency = Settings.TextTransparency,
        TextSize = 16, Font = FONT,
    })
    local traj = Instance.new("Model")
    traj.Name = "Trajectory"
    createTrajectory(entry, traj)
    traj.Parent = nil
    local prompt = Instance.new("ProximityPrompt")
    prompt.Parent = circle
    prompt.Enabled = Settings.PromptEnabled and Keybinds.Prompt ~= ""
    prompt.MaxActivationDistance = Settings.PromptDistance
    prompt.RequiresLineOfSight = false
    prompt.HoldDuration = 0
    prompt.ActionText = "Play"
    prompt.ObjectText = entry.Name
    prompt.KeyboardKeyCode = keyCodeByName(Keybinds.Prompt)
    prompt.Triggered:Connect(function()
        if not MovementEnabled then return end
        requestPlayback(entry)
    end)
    model.Parent = markersFolder
    markerData[entry] = {
        Model = model, Circle = circle, Label = label, Billboard = billboard,
        Trajectory = traj, Prompt = prompt, StartPos = pos, TrailShown = false,
    }
end

rebuildMarkers = function()
    for _, data in pairs(markerData) do
        pcall(function() data.Model:Destroy() end)
    end
    markerData = {}
    for _, entry in ipairs(library.categories[selectedCategory] or {}) do
        createMarker(entry)
    end
end

-- Movers
local movers = { kind = nil, attachment = nil, position = nil, orientation = nil, bodyPos = nil, bodyGyro = nil }
local canUseAlign = pcall(function()
    return Enum.PositionAlignmentMode.OneAttachment and Enum.OrientationAlignmentMode.OneAttachment
end)

local function clearMovers()
    for _, key in ipairs({"attachment","position","orientation","bodyPos","bodyGyro"}) do
        local o = movers[key]
        if o then pcall(function() o:Destroy() end) end
        movers[key] = nil
    end
    movers.kind = nil
end

local function createMovers()
    clearMovers()
    if not rootPart or not rootPart.Parent then return end
    local ok = false
    if canUseAlign then
        ok = pcall(function()
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
    if not ok then
        clearMovers()
        pcall(function()
            local bp = Instance.new("BodyPosition")
            bp.MaxForce = Vector3.new(50000,50000,50000)
            bp.P = 15000
            bp.D = 1200
            bp.Position = rootPart.CFrame.Position
            bp.Parent = rootPart
            local bg = Instance.new("BodyGyro")
            bg.MaxTorque = Vector3.new(50000,50000,50000)
            bg.P = 18000
            bg.D = 1200
            bg.CFrame = rootPart.CFrame
            bg.Parent = rootPart
            movers.kind = "Body"
            movers.bodyPos = bp
            movers.bodyGyro = bg
        end)
    end
end

local function setMoversTarget(cf)
    if not isFiniteCFrame(cf) then return end
    if movers.kind == "Align" then
        if movers.position then movers.position.Position = cf.Position end
        if movers.orientation then movers.orientation.CFrame = cf end
    elseif movers.kind == "Body" then
        if movers.bodyPos then movers.bodyPos.Position = cf.Position end
        if movers.bodyGyro then movers.bodyGyro.CFrame = cf end
    end
end

-- State
local State = {Idle = 0, Recording = 1, Aligning = 2, Playing = 3}
local state = State.Idle
local recorded = {}
local recordStartTime = 0
local playbackStart = 0
local playbackIndex = 1
local currentPlayback = nil
local alignStart = 0
local MAX_POINTS = 12000

local function isPlayerInside(entry)
    local data = markerData[entry]
    if not data or not rootPart or not rootPart.Parent then return false end
    local p = rootPart.Position
    local s = data.StartPos
    if math.abs(p.Y - s.Y) > 12 then return false end
    return Vector2.new(p.X - s.X, p.Z - s.Z).Magnitude <= Settings.CircleRadius
end

local function beginPlayback(entry)
    state = State.Playing
    playbackStart = os.clock()
    playbackIndex = 1
    currentPlayback = entry
    if humanoid then humanoid.AutoRotate = false end
    if not Settings.Legit then clearMovers() end
    if updateButtons then updateButtons() end
    if setStatus then setStatus("Playing: " .. entry.Name) end
end

stopPlayback = function()
    if state ~= State.Playing and state ~= State.Aligning then return end
    state = State.Idle
    currentPlayback = nil
    clearMovers()
    if humanoid then humanoid.AutoRotate = true end
    if updateButtons then updateButtons() end
    if setStatus then setStatus("Playback stopped.") end
end

requestPlayback = function(entry)
    if not MovementEnabled then
        if setStatus then setStatus("Movement is disabled.") end
        return
    end
    if not unlocked then
        if setStatus then setStatus("Script is locked.") end
        return
    end
    if state ~= State.Idle then return end
    entry = entry or selectedRecording
    if not entry or not entry.Frames or #entry.Frames < 2 then
        if setStatus then setStatus("No recording selected.") end
        return
    end
    if not isCharacterAlive() then
        if setStatus then setStatus("Character unavailable.") end
        return
    end
    if not markerData[entry] then createMarker(entry) end
    if not isPlayerInside(entry) then
        if setStatus then setStatus("Stand inside the circle of this recording first.") end
        return
    end
    if not Settings.Legit then
        if rootPart and isFiniteCFrame(entry.Frames[1].cframe) then
            rootPart.CFrame = entry.Frames[1].cframe
        end
        beginPlayback(entry)
    else
        state = State.Aligning
        currentPlayback = entry
        alignStart = os.clock()
        createMovers()
        if updateButtons then updateButtons() end
        if setStatus then setStatus("Aligning to start position...") end
    end
end

stopRecording = function(save)
    if state ~= State.Recording then return end
    state = State.Idle
    if save == nil then save = true end
    if save and #recorded >= 2 then
        if not library.categories[selectedCategory] then
            library.categories[selectedCategory] = {}
        end
        local customName = trim(nameBox and nameBox.Text or "")
        if customName == "" then customName = "Recording " .. os.date("%H:%M:%S") end
        local entry = { Id = generateRecordId(), Name = customName, StartCFrame = recorded[1].cframe, Frames = recorded }
        table.insert(library.categories[selectedCategory], entry)
        selectedRecording = entry
        createMarker(entry)
        saveCategoryFile(selectedCategory)
        if refreshRecordings then refreshRecordings() end
        if refreshMainInfo then refreshMainInfo() end
        if setStatus then setStatus("Saved: " .. customName) end
        if nameBox then nameBox.Text = "" end
    else
        if setStatus then setStatus("Recording stopped.") end
    end
    recorded = {}
    if updateButtons then updateButtons() end
end

startRecording = function()
    if not MovementEnabled then
        if setStatus then setStatus("Movement is disabled.") end
        return
    end
    if not unlocked then
        if setStatus then setStatus("Script is locked.") end
        return
    end
    if state ~= State.Idle then return end
    if not isCharacterAlive() then
        if setStatus then setStatus("Character unavailable.") end
        return
    end
    recorded = {}
    recordStartTime = os.clock()
    state = State.Recording
    if updateButtons then updateButtons() end
    if setStatus then setStatus("Recording... move now.") end
end

-- Main heartbeat
mConnect(RunService.Heartbeat, function()
    if state == State.Recording then
        if not isCharacterAlive() then stopRecording(false); return end
        local cf = rootPart.CFrame
        if not isFiniteCFrame(cf) then return end
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
    elseif state == State.Aligning then
        if not isCharacterAlive() or not currentPlayback then stopPlayback(); return end
        local first = currentPlayback.Frames[1]
        if not first then stopPlayback(); return end
        setMoversTarget(first.cframe)
        local d = (rootPart.Position - first.cframe.Position).Magnitude
        local dot = rootPart.CFrame.LookVector:Dot(first.cframe.LookVector)
        if (d < 0.2 and dot > 0.97) or (os.clock() - alignStart > 6) then
            beginPlayback(currentPlayback)
        end
    elseif state == State.Playing then
        if not isCharacterAlive() or not currentPlayback then stopPlayback(); return end
        local frames = currentPlayback.Frames
        local speed = tonumber(Settings.PlaybackSpeed) or 1
        if speed <= 0 then speed = 1 end
        local elapsed = (os.clock() - playbackStart) * speed
        local last = frames[#frames]
        if not last or last.time <= 0 then stopPlayback(); return end
        if elapsed >= last.time then
            if Settings.Loop then
                playbackStart = os.clock()
                playbackIndex = 1
                elapsed = 0
            else
                stopPlayback()
                return
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
            if rootPart and isFiniteCFrame(target) then rootPart.CFrame = target end
        end
    end
end)

-- Proximity / trail animation
local lastProx = 0
mConnect(RunService.Heartbeat, function()
    local animCircle = Settings.CircleMode ~= "Solid"
    local animLabel = Settings.LabelMode ~= "Solid"
    if animCircle or animLabel then
        local t = tick()
        local cCol = animCircle and circleColorAt(t) or nil
        local lCol = animLabel and labelColorAt(t) or nil
        for _, data in pairs(markerData) do
            if cCol then data.Circle.Color = cCol end
            if lCol then data.Label.TextColor3 = lCol end
        end
    end
    if os.clock() - lastProx < 0.15 then return end
    lastProx = os.clock()
    if not rootPart or not rootPart.Parent then return end
    local pos = rootPart.Position
    for entry, data in pairs(markerData) do
        local distXZ = Vector2.new(pos.X - data.StartPos.X, pos.Z - data.StartPos.Z).Magnitude
        local yOk = math.abs(pos.Y - data.StartPos.Y) <= 12
        local trailVisible
        if state == State.Playing and currentPlayback == entry then
            trailVisible = Settings.ShowPathPlayback and true or false
        else
            trailVisible = yOk and distXZ <= Settings.TrailDistance
        end
        if trailVisible ~= data.TrailShown then
            data.TrailShown = trailVisible
            data.Trajectory.Parent = trailVisible and data.Model or nil
        end
    end
end)

-- UI helpers
local buttonBase = setmetatable({}, {__mode = "k"})
local function setButtonBaseColor(b, c) buttonBase[b] = c end

local function mvLabel(parent, text, height)
    local l = FuckYouLib.create("TextLabel", {Parent = parent, Size = UDim2.new(1,0,0, height or 22), BackgroundTransparency = 1, Text = text, TextColor3 = FuckYouLib.uiColor_TextColor, TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true})
    table.insert(FuckYouLib.themeElements.Texts, l)
    return l
end
local function mvBox(parent, placeholder, height)
    local b = FuckYouLib.create("TextBox", {Parent = parent, Size = UDim2.new(1,0,0, height or 26), BackgroundColor3 = FuckYouLib.uiColor_TextBoxColor, BorderColor3 = COL_BORDER, TextColor3 = FuckYouLib.uiColor_TextColor, PlaceholderColor3 = Color3.fromRGB(90,90,90), PlaceholderText = placeholder, Text = "", TextSize = 13, Font = FONT, ClearTextOnFocus = false})
    b.BackgroundTransparency = 1 - FuckYouLib.uiGuiOpacity
    table.insert(FuckYouLib.themeElements.TextBoxes, b)
    table.insert(FuckYouLib.themeElements.Texts, b)
    return b
end
local function mvButton(parent, text, callback, customBg, customTc, height)
    local b = FuckYouLib.create("TextButton", {Parent = parent, Size = UDim2.new(1,0,0, height or 30), BackgroundColor3 = customBg or FuckYouLib.uiColor_ButtonColor, BorderColor3 = COL_BORDER, TextColor3 = customTc or FuckYouLib.uiColor_TextColor, Text = text, Font = FONT, TextSize = 13, TextWrapped = true})
    if not customBg and not customTc then
        table.insert(FuckYouLib.themeElements.Buttons, b)
        table.insert(FuckYouLib.themeElements.Texts, b)
    else
        table.insert(FuckYouLib.themeElements.CustomButtons, b)
    end
    b.BackgroundTransparency = 1 - FuckYouLib.uiGuiOpacity
    b.MouseEnter:Connect(function()
        local c = b.BackgroundColor3
        b.BackgroundColor3 = lighter(c, 10)
    end)
    if customBg == nil then
        b.MouseLeave:Connect(function() b.BackgroundColor3 = FuckYouLib.uiColor_ButtonColor end)
    else
        buttonBase[b] = customBg
        b.MouseLeave:Connect(function() b.BackgroundColor3 = buttonBase[b] or customBg end)
    end
    if callback then b.MouseButton1Click:Connect(callback) end
    return b
end
local function mvList(parent, height)
    local f = FuckYouLib.create("ScrollingFrame", {Parent = parent, Size = UDim2.new(1,0,0, height or 180), BackgroundColor3 = FuckYouLib.uiColor_TextBoxColor, BorderColor3 = COL_BORDER, ScrollBarThickness = 4, ScrollBarImageColor3 = COL_BORDER, CanvasSize = UDim2.new(0,0,0,0)})
    f.BackgroundTransparency = 1 - FuckYouLib.uiGuiOpacity
    table.insert(FuckYouLib.themeElements.TextBoxes, f)
    local l = FuckYouLib.create("UIListLayout", {Parent = f, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,3)})
    FuckYouLib.create("UIPadding", {Parent = f, PaddingTop = UDim.new(0,3), PaddingLeft = UDim.new(0,3), PaddingRight = UDim.new(0,3)})
    l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        f.CanvasSize = UDim2.new(0,0,0, l.AbsoluteContentSize.Y + 8)
    end)
    return f
end
local function clearList(f)
    for _, ch in ipairs(f:GetChildren()) do
        if ch:IsA("TextButton") or ch:IsA("TextLabel") then ch:Destroy() end
    end
end
local function mvListItem(parent, text, selected, callback, height)
    local bg = selected and lighter(FuckYouLib.uiColor_ButtonColor,30) or FuckYouLib.uiColor_ButtonColor
    local tc = selected and Color3.fromRGB(255,255,255) or FuckYouLib.uiColor_TextColor
    local b = FuckYouLib.create("TextButton", {Parent = parent, Size = UDim2.new(1,0,0, height or 26), BackgroundColor3 = bg, BorderColor3 = COL_BORDER, TextColor3 = tc, Text = text, Font = FONT, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true})
    b.BackgroundTransparency = 1 - FuckYouLib.uiGuiOpacity
    b.MouseEnter:Connect(function()
        local c = b.BackgroundColor3
        b.BackgroundColor3 = lighter(c, 10)
    end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = bg end)
    b.MouseButton1Click:Connect(callback)
    return b
end

-- Movement tabs
local movementTabs = {}
local function addMovementTab(name, builder)
    local frame = FuckYouLib.create("Frame", {Name = "Tab" .. name, Parent = FuckYouLib.Containment, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false})
    local sf = FuckYouLib.create("ScrollingFrame", {Parent = frame, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = COL_BORDER, CanvasSize = UDim2.new(0,0,0,0)})
    local tl = FuckYouLib.create("UIListLayout", {Parent = sf, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,6)})
    FuckYouLib.create("UIPadding", {Parent = sf, PaddingTop = UDim.new(0,10), PaddingLeft = UDim.new(0,10), PaddingRight = UDim.new(0,10)})
    tl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() sf.CanvasSize = UDim2.new(0,0,0, tl.AbsoluteContentSize.Y + 20) end)
    builder(sf)
    local btn = FuckYouLib.create("TextButton", {Name = "MoveBtn_" .. name, Parent = FuckYouLib.MenuInsided, Size = UDim2.new(1,0,0,40), LayoutOrder = 400 + #movementTabs, Visible = false, BackgroundColor3 = FuckYouLib.uiColor_ButtonColor, BorderColor3 = COL_BORDER, TextColor3 = FuckYouLib.uiColor_TextColor, Text = name, Font = FONT, TextSize = 12, TextWrapped = true})
    table.insert(FuckYouLib.themeElements.Buttons, btn)
    table.insert(FuckYouLib.themeElements.Texts, btn)
    local entry = {Frame = frame, Name = name, Button = btn}
    table.insert(movementTabs, entry)
    return entry
end

-- Tab: Main
local statusLabel, infoLabel, movementToggleBtn
local startRecBtn, stopRecBtn, playBtn, stopPlayBtn

addMovementTab("Main", function(p)
    FuckYouLib.createSection(p, "MOVEMENT RECORDER")
    statusLabel = mvLabel(p, "Ready.", 40)
    FuckYouLib.createSection(p, "Recording")
    nameBox = mvBox(p, "Recording name (optional)", 26)
    startRecBtn = mvButton(p, "Start Recording", function() startRecording() end, Color3.fromRGB(30,60,30), C_GRN)
    stopRecBtn = mvButton(p, "Stop Recording", function() stopRecording(true) end, C_REDD, C_ROFF)
    FuckYouLib.createSection(p, "Playback")
    playBtn = mvButton(p, "Play Selected", function() requestPlayback(selectedRecording) end)
    stopPlayBtn = mvButton(p, "Stop Playback", function() stopPlayback() end)
    FuckYouLib.createSection(p, "Selected")
    infoLabel = mvLabel(p, "Nothing selected.", 40)
end)

-- Tab: Records
local recList, renameBox
addMovementTab("Records", function(p)
    FuckYouLib.createSection(p, "RECORDINGS")
    recList = mvList(p, 220)
    local renameRow = FuckYouLib.create("Frame", {Parent = p, Size = UDim2.new(1,0,0,30), BackgroundTransparency = 1})
    renameBox = FuckYouLib.create("TextBox", {Parent = renameRow, Size = UDim2.new(0.6,-4,1,0), BackgroundColor3 = FuckYouLib.uiColor_TextBoxColor, BorderColor3 = COL_BORDER, TextColor3 = FuckYouLib.uiColor_TextColor, PlaceholderColor3 = Color3.fromRGB(90,90,90), PlaceholderText = "New name...", Text = "", TextSize = 13, Font = FONT, ClearTextOnFocus = false})
    renameBox.BackgroundTransparency = 1 - FuckYouLib.uiGuiOpacity
    table.insert(FuckYouLib.themeElements.TextBoxes, renameBox)
    table.insert(FuckYouLib.themeElements.Texts, renameBox)
    local renameBtn = mvButton(renameRow, "Rename", function()
        if not selectedRecording then setStatus("Select a recording first."); return end
        local n = trim(renameBox.Text)
        if n == "" then setStatus("Enter a new name."); return end
        selectedRecording.Name = n
        saveCategoryFile(selectedCategory)
        rebuildMarkers()
        refreshRecordings()
        refreshMainInfo()
        setStatus("Renamed to: " .. n)
    end)
    renameBtn.Size = UDim2.new(0.4,0,1,0); renameBtn.Position = UDim2.new(0.6,0,0,0)
    local delBtn = mvButton(p, "Delete Selected", function()
        if not selectedRecording then return end
        if state ~= State.Idle and currentPlayback == selectedRecording then stopPlayback() end
        local entries = library.categories[selectedCategory]
        if entries then
            for i, e in ipairs(entries) do
                if e == selectedRecording then table.remove(entries, i); break end
            end
        end
        if markerData[selectedRecording] then
            pcall(function() markerData[selectedRecording].Model:Destroy() end)
            markerData[selectedRecording] = nil
        end
        selectedRecording = nil
        saveCategoryFile(selectedCategory)
        refreshRecordings()
        refreshMainInfo()
        setStatus("Recording deleted.")
    end, C_REDD, C_ROFF)
    local tpBtn = mvButton(p, "Teleport To Circle", function()
        if not MovementEnabled then if setStatus then setStatus("Movement is disabled.") end; return end
        if not selectedRecording or not rootPart then return end
        local s = selectedRecording.StartCFrame
        if s then rootPart.CFrame = s + Vector3.new(0,3,0) end
    end)
    local playSel = mvButton(p, "Play Selected", function() requestPlayback(selectedRecording) end)
end)

-- Tab: Categories
local catList, newCatBox
addMovementTab("Categories", function(p)
    FuckYouLib.createSection(p, "CATEGORIES")
    catList = mvList(p, 240)
    newCatBox = mvBox(p, "New category name", 26)
    local addBtn = mvButton(p, "Add Category", function()
        local n = trim(newCatBox.Text)
        if n == "" then setStatus("Enter a category name."); return end
        if library.categories[n] then setStatus("Category already exists."); return end
        library.categories[n] = {}
        selectedCategory = n
        selectedRecording = nil
        newCatBox.Text = ""
        saveCategoryFile(n)
        refreshCategories()
        refreshRecordings()
        setStatus("Category added: " .. n)
    end, Color3.fromRGB(30,60,30), C_GRN)
    local delBtn = mvButton(p, "Delete Category", function()
        if selectedCategory == "Default" then setStatus("Default cannot be deleted."); return end
        library.categories[selectedCategory] = nil
        deleteCategoryFile(selectedCategory)
        selectedCategory = "Default"
        selectedRecording = nil
        rebuildMarkers()
        refreshCategories()
        refreshRecordings()
        refreshMainInfo()
        setStatus("Category deleted.")
    end, C_REDD, C_ROFF)
end)

-- Settings rows helpers
local function numRow(parent, label, key, min, max, rebuild)
    local rowF = FuckYouLib.create("Frame", {Parent = parent, Size = UDim2.new(1,0,0,26), BackgroundTransparency = 1})
    local lbl = FuckYouLib.create("TextLabel", {Parent = rowF, Size = UDim2.new(0.55,0,1,0), BackgroundTransparency = 1, Text = label, TextColor3 = FuckYouLib.uiColor_TextColor, TextSize = 12, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left})
    table.insert(FuckYouLib.themeElements.Texts, lbl)
    local box = FuckYouLib.create("TextBox", {Parent = rowF, Size = UDim2.new(0.45,-4,0,22), Position = UDim2.new(0.55,0,0.5,-11), BackgroundColor3 = FuckYouLib.uiColor_TextBoxColor, BorderColor3 = COL_BORDER, TextColor3 = FuckYouLib.uiColor_TextColor, Text = tostring(Settings[key]), TextSize = 12, Font = FONT, ClearTextOnFocus = false})
    box.BackgroundTransparency = 1 - FuckYouLib.uiGuiOpacity
    table.insert(FuckYouLib.themeElements.TextBoxes, box)
    table.insert(FuckYouLib.themeElements.Texts, box)
    box.FocusLost:Connect(function()
        local v = tonumber(box.Text)
        if not v then box.Text = tostring(Settings[key]); return end
        Settings[key] = math.clamp(v, min, max)
        box.Text = tostring(Settings[key])
        saveSettings()
        if rebuild then rebuildMarkers() end
    end)
    return rowF
end
local function colorRow(parent, label, key, rebuild)
    local rowF = FuckYouLib.create("Frame", {Parent = parent, Size = UDim2.new(1,0,0,26), BackgroundTransparency = 1})
    local lbl = FuckYouLib.create("TextLabel", {Parent = rowF, Size = UDim2.new(0.55,0,1,0), BackgroundTransparency = 1, Text = label, TextColor3 = FuckYouLib.uiColor_TextColor, TextSize = 12, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left})
    table.insert(FuckYouLib.themeElements.Texts, lbl)
    local arr = Settings[key]
    local box = FuckYouLib.create("TextBox", {Parent = rowF, Size = UDim2.new(0.45,-4,0,22), Position = UDim2.new(0.55,0,0.5,-11), BackgroundColor3 = FuckYouLib.uiColor_TextBoxColor, BorderColor3 = COL_BORDER, TextColor3 = FuckYouLib.uiColor_TextColor, Text = string.format("%d,%d,%d", arr[1], arr[2], arr[3]), TextSize = 12, Font = FONT, ClearTextOnFocus = false})
    box.BackgroundTransparency = 1 - FuckYouLib.uiGuiOpacity
    table.insert(FuckYouLib.themeElements.TextBoxes, box)
    table.insert(FuckYouLib.themeElements.Texts, box)
    box.FocusLost:Connect(function()
        local r, g, bVal = box.Text:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
        if r and g and bVal then
            Settings[key] = { math.clamp(tonumber(r),0,255), math.clamp(tonumber(g),0,255), math.clamp(tonumber(bVal),0,255) }
            saveSettings()
            if rebuild then rebuildMarkers() end
        end
    end)
    return rowF
end
local function toggleRow(parent, label, key, rebuild)
    local stateVal = Settings[key] and true or false
    local bg = stateVal and Color3.fromRGB(30,60,30) or C_REDD
    local tc = stateVal and C_GRN or C_ROFF
    local b
    b = mvButton(parent, label .. ": " .. (stateVal and "ON" or "OFF"), function()
        stateVal = not stateVal
        Settings[key] = stateVal
        bg = stateVal and Color3.fromRGB(30,60,30) or C_REDD
        tc = stateVal and C_GRN or C_ROFF
        if b then
            b.Text = label .. ": " .. (stateVal and "ON" or "OFF")
            b.BackgroundColor3 = bg
            b.TextColor3 = tc
            setButtonBaseColor(b, bg)
        end
        saveSettings()
        if rebuild then rebuildMarkers() end
    end, bg, tc, 26)
    return b
end

local function colorSection(parent, title, modeKey, keyA, keyB, keyC)
    FuckYouLib.createSection(parent, title)
    local updateVis
    local modeBtn = mvButton(parent, "Color Mode: " .. Settings[modeKey], function()
        local idx = table.find(COLOR_MODES, Settings[modeKey]) or 1
        Settings[modeKey] = COLOR_MODES[(idx % #COLOR_MODES) + 1]
        saveSettings()
        rebuildMarkers()
        if updateVis then updateVis() end
    end, nil, nil, 26)
    local rowA = colorRow(parent, "Color A (R,G,B)", keyA, true)
    local rowB = colorRow(parent, "Color B (R,G,B)", keyB, true)
    local rowC = colorRow(parent, "Color C (R,G,B)", keyC, true)
    updateVis = function()
        local m = Settings[modeKey]
        rowA.Visible = (m ~= "Rainbow")
        rowB.Visible = (m == "TwoWay" or m == "ThreeWay")
        rowC.Visible = (m == "ThreeWay")
        modeBtn.Text = "Color Mode: " .. m
    end
    updateVis()
end

-- Tab: Colors
addMovementTab("Colors", function(p)
    FuckYouLib.createSection(p, "COLORS")
    colorSection(p, "CIRCLE COLORS", "CircleMode", "CircleColorA", "CircleColorB", "CircleColorC")
    colorSection(p, "PATH COLORS", "PathMode", "PathColorA", "PathColorB", "PathColorC")
    colorSection(p, "LABEL COLORS", "LabelMode", "LabelColorA", "LabelColorB", "LabelColorC")
end)

-- Tab: Settings
addMovementTab("Settings", function(p)
    FuckYouLib.createSection(p, "RECORDING")
    numRow(p, "Min Record Distance", "MinRecordDistance", 0, 1, false)
    numRow(p, "Min Record Time (sec)", "MinRecordTime", 0, 1, false)
    FuckYouLib.createSection(p, "CIRCLE")
    numRow(p, "Circle Width (Radius)", "CircleRadius", 2, 20, true)
    numRow(p, "Circle Thickness", "CircleThickness", 0.1, 2, true)
    numRow(p, "Circle Height Offset", "CircleHeight", -10, 10, true)
    numRow(p, "Circle Transparency", "CircleTransparency", 0, 1, true)
    FuckYouLib.createSection(p, "PATH")
    numRow(p, "Path Transparency", "PathTransparency", 0, 1, true)
    numRow(p, "Path Point Size", "PathPointSize", 0.1, 2, true)
    numRow(p, "Trail Show Distance", "TrailDistance", 1, 100, false)
    numRow(p, "Trail Step (0 = auto)", "TrailStep", 0, 50, true)
    toggleRow(p, "Show Path In Playback", "ShowPathPlayback", false)
    FuckYouLib.createSection(p, "LABEL (NAME ABOVE CIRCLE)")
    toggleRow(p, "Show Labels", "ShowLabels", true)
    numRow(p, "Text Height", "TextHeight", 1, 20, true)
    numRow(p, "Text Transparency", "TextTransparency", 0, 1, true)
    numRow(p, "Text Visible Distance", "TextDistance", 10, 300, true)
    FuckYouLib.createSection(p, "PROXIMITY PROMPT")
    toggleRow(p, "Proximity Prompt", "PromptEnabled", true)
    numRow(p, "Prompt Distance", "PromptDistance", 4, 60, true)
    FuckYouLib.createSection(p, "PLAYBACK")
    numRow(p, "Playback Speed", "PlaybackSpeed", 0.1, 5, false)
    toggleRow(p, "Loop Playback", "Loop", false)
    toggleRow(p, "Legit Movement", "Legit", false)
end)

-- Tab: Keybinds
local function applyPromptKey()
    local kc = keyCodeByName(Keybinds.Prompt)
    for _, data in pairs(markerData) do
        if data.Prompt then
            data.Prompt.KeyboardKeyCode = kc
            data.Prompt.Enabled = Settings.PromptEnabled and Keybinds.Prompt ~= ""
        end
    end
end

local function bindRow(parent, label, key, onSet)
    local b
    local function paint()
        if b then b.Text = label .. ": [" .. movementKeyName(Keybinds[key]) .. "]" end
    end
    b = mvButton(parent, label .. ": [" .. movementKeyName(Keybinds[key]) .. "]", function()
        if movementBindCapture then return end
        movementBindCapture = function(name)
            if name == nil or name == "" then Keybinds[key] = ""
            else Keybinds[key] = name end
            paint()
            saveSettings()
            if FuckYouLib.autoSaveConfig then FuckYouLib.autoSaveConfig(true) end
            if onSet then onSet() end
            if setStatus then
                if Keybinds[key] == "" then setStatus("Keybind cleared: " .. label)
                else setStatus("Keybind set: " .. label .. " -> " .. Keybinds[key]) end
            end
        end
        if b then b.Text = label .. ": [press any key | Backspace = clear]" end
    end, nil, nil, 28)
    paint()
    return b
end

addMovementTab("Keybinds", function(p)
    FuckYouLib.createSection(p, "KEYBINDS")
    mvLabel(p, "Menu toggle uses the main FuckYou toggle key.", 22)
    mvLabel(p, "Click a row, then press any key.", 22)
    bindRow(p, "Start / Stop Recording", "Record")
    bindRow(p, "Play / Stop Playback", "Play")
    bindRow(p, "Proximity Prompt Key", "Prompt", applyPromptKey)
end)

-- Refreshers
setStatus = function(text) if statusLabel then statusLabel.Text = text end end
updateButtons = function()
    if not startRecBtn then return end
    startRecBtn.Text = (state == State.Recording) and "Recording..." or "Start Recording"
    stopRecBtn.Text = "Stop Recording"
    playBtn.Text = (state == State.Playing) and "Playing..." or (state == State.Aligning) and "Aligning..." or "Play Selected"
    stopPlayBtn.Text = "Stop Playback"
end
refreshMainInfo = function()
    if not infoLabel then return end
    if selectedRecording then
        local n = #selectedRecording.Frames
        infoLabel.Text = string.format("%s | frames: %d | category: %s", selectedRecording.Name, n, selectedCategory)
    else
        infoLabel.Text = "Nothing selected."
    end
end
refreshRecordings = function()
    if not recList then return end
    clearList(recList)
    local entries = library.categories[selectedCategory] or {}
    if #entries == 0 then mvLabel(recList, "No recordings in this category yet.", 24) end
    for _, entry in ipairs(entries) do
        local sel = entry == selectedRecording
        mvListItem(recList, string.format("%s | frames: %d", entry.Name, entry.Frames and #entry.Frames or 0), sel, function()
            selectedRecording = entry
            refreshRecordings()
            refreshMainInfo()
            setStatus("Selected: " .. entry.Name .. ". Stand in its circle or use prompt key.")
        end, 28)
    end
end
refreshCategories = function()
    if not catList then return end
    clearList(catList)
    local names = {}
    for n in pairs(library.categories) do table.insert(names, n) end
    table.sort(names, function(a,b) if a == "Default" then return true end; if b == "Default" then return false end; return a < b end)
    for _, name in ipairs(names) do
        local sel = name == selectedCategory
        mvListItem(catList, name, sel, function()
            selectedCategory = name
            selectedRecording = nil
            refreshCategories()
            refreshRecordings()
            refreshMainInfo()
            rebuildMarkers()
        end, 26)
    end
end

-- Theme hooks
local baseUpdateTabButtonsTheme = FuckYouLib.updateTabButtonsTheme
FuckYouLib.updateTabButtonsTheme = function()
    baseUpdateTabButtonsTheme()
    for _, tab in ipairs(movementTabs) do
        if tab.Button then
            if tab.Frame.Visible then
                tab.Button.BackgroundColor3 = FuckYouLib.uiColor_ButtonColor
                tab.Button.TextColor3 = Color3.fromRGB(255,255,255)
            else
                tab.Button.BackgroundColor3 = darker(FuckYouLib.uiColor_ButtonColor, 10)
                tab.Button.TextColor3 = FuckYouLib.uiColor_TextColor
            end
        end
    end
end

local baseApplyTheme = FuckYouLib.applyTheme
FuckYouLib.applyTheme = function()
    baseApplyTheme()
    pcall(function() if refreshCategories then refreshCategories() end end)
    pcall(function() if refreshRecordings then refreshRecordings() end end)
end

-- Character binding
local function bindCharacter(newChar)
    if characterDiedConnection then characterDiedConnection:Disconnect(); characterDiedConnection = nil end
    character = newChar
    humanoid = newChar:FindFirstChildOfClass("Humanoid") or newChar:WaitForChild("Humanoid", 5)
    rootPart = newChar:FindFirstChild("HumanoidRootPart") or newChar:WaitForChild("HumanoidRootPart", 5)
    if humanoid then
        characterDiedConnection = humanoid.Died:Connect(function()
            pcall(stopRecording, false)
            pcall(stopPlayback)
        end)
    end
end
mConnect(LocalPlayer.CharacterAdded, bindCharacter)
mConnect(LocalPlayer.CharacterRemoving, function()
    pcall(stopRecording, false)
    pcall(stopPlayback)
end)
if LocalPlayer.Character then bindCharacter(LocalPlayer.Character) end

-- Global key handler
mConnect(UserInputService.InputBegan, function(input, processed)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local name = input.KeyCode.Name
    if movementBindCapture then
        if input.KeyCode == Enum.KeyCode.Backspace then movementBindCapture(nil)
        elseif name ~= "Unknown" then movementBindCapture(name) end
        movementBindCapture = nil
        return
    end
    if not unlocked or processed or not MovementEnabled then return end
    if name == Keybinds.Record then
        if state == State.Recording then stopRecording(true) else startRecording() end
        return
    end
    if name == Keybinds.Play then
        if state == State.Playing or state == State.Aligning then stopPlayback()
        else requestPlayback(selectedRecording) end
        return
    end
end)

-- Init
loadLibrary()
rebuildMarkers()
refreshCategories()
refreshRecordings()
refreshMainInfo()
updateButtons()
if not filesOK() then
    setStatus("File saving not supported by executor - session only. Ready.")
else
    setStatus("File saving is supported by executor. Ready.")
end

-- Cleanup
local cleaned = false
local function cleanupMovement()
    if cleaned then return end
    cleaned = true
    pcall(stopRecording, false)
    pcall(stopPlayback)
    if characterDiedConnection then pcall(function() characterDiedConnection:Disconnect() end); characterDiedConnection = nil end
    for i = #movementConnections, 1, -1 do
        local cn = movementConnections[i]
        if cn and cn.Connected then cn:Disconnect() end
        movementConnections[i] = nil
    end
    pcall(function() markersFolder:Destroy() end)
end
pcall(function()
    local old = shared["EmilyUiMovementCleanup"]
    if typeof(old) == "function" then pcall(old) end
    shared["EmilyUiMovementCleanup"] = cleanupMovement
end)

-- Sidebar toggle
local MovementSidebarToggle = FuckYouLib.create("TextButton", {
    Name = "MToggle_Movement", Parent = FuckYouLib.MenuInsided,
    Size = UDim2.new(1,0,0,40), LayoutOrder = 490, Visible = false,
    BorderColor3 = COL_BORDER, Text = "Movement: OFF", Font = FONT, TextSize = 12, TextWrapped = true,
    BackgroundTransparency = 1 - FuckYouLib.uiGuiOpacity,
})
table.insert(FuckYouLib.themeElements.CustomButtons, MovementSidebarToggle)
table.insert(FuckYouLib.moduleToggles, {btn = MovementSidebarToggle, group = "Movement"})
FuckYouLib.registerToggle(MovementSidebarToggle, function() return MovementEnabled end)
local function refreshMovementToggleText()
    MovementSidebarToggle.Text = "Movement: " .. (MovementEnabled and "ON" or "OFF")
    FuckYouLib.paintToggleBtn(MovementSidebarToggle, MovementEnabled)
end
refreshMovementToggleText()
local function setMovementEnabled(v)
    MovementEnabled = v and true or false
    if MovementEnabled then
        pcall(function() markersFolder.Parent = workspace end)
        if setStatus then setStatus("Movement enabled.") end
    else
        pcall(stopRecording, false)
        pcall(stopPlayback)
        pcall(function() markersFolder.Parent = nil end)
        if setStatus then setStatus("Movement disabled.") end
    end
    refreshMovementToggleText()
    if FuckYouLib.autoSaveConfig then FuckYouLib.autoSaveConfig(true) end
end
MovementSidebarToggle.MouseButton1Click:Connect(function() setMovementEnabled(not MovementEnabled) end)

ScreenGui.Destroying:Connect(function()
    pcall(function() setMovementEnabled(false) end)
    pcall(cleanupMovement)
end)

-- Tab switching integration
.defer(function()
    local function hideAllFrames()
        for _, t in ipairs(FuckYouLib.tabs) do if t.Frame then t.Frame.Visible = false end end
        for _, t in ipairs(FuckYouLib.desyncTabs or {}) do if t.Frame then t.Frame.Visible = false end end
        for _, t in ipairs(FuckYouLib.musicTabs or {}) do if t.Frame then t.Frame.Visible = false end end
        for _, t in ipairs(FuckYouLib.aimTabs or {}) do if t.Frame then t.Frame.Visible = false end end
        for _, t in ipairs(movementTabs) do if t.Frame then t.Frame.Visible = false end end
    end
    local function hideAllModuleButtons()
        for _, t in ipairs(FuckYouLib.tabs) do if t.Button then t.Button.Visible = false end end
        for _, t in ipairs(FuckYouLib.desyncTabs or {}) do if t.Button then t.Button.Visible = false end end
        for _, t in ipairs(FuckYouLib.musicTabs or {}) do if t.Button then t.Button.Visible = false end end
        for _, t in ipairs(FuckYouLib.aimTabs or {}) do if t.Button then t.Button.Visible = false end end
        for _, t in ipairs(movementTabs) do if t.Button then t.Button.Visible = false end end
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
        for _, t in ipairs(FuckYouLib.aimTabs or {}) do if t.Button then t.Button.Visible = true end end
    end
    local function showMovementButtons()
        hideAllModuleButtons()
        for _, t in ipairs(movementTabs) do if t.Button then t.Button.Visible = true end end
    end
    for _, t in ipairs(movementTabs) do
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
                for _, m in ipairs(movementTabs) do if m.Frame then m.Frame.Visible = false end end
                FuckYouLib.updateTabButtonsTheme()
            end)
        end
    end
    for _, t in ipairs(FuckYouLib.desyncTabs or {}) do
        if t.Button then
            t.Button.MouseButton1Click:Connect(function()
                for _, m in ipairs(movementTabs) do if m.Frame then m.Frame.Visible = false end end
                FuckYouLib.updateTabButtonsTheme()
            end)
        end
    end
    for _, t in ipairs(FuckYouLib.musicTabs or {}) do
        if t.Button then
            t.Button.MouseButton1Click:Connect(function()
                for _, m in ipairs(movementTabs) do if m.Frame then m.Frame.Visible = false end end
                FuckYouLib.updateTabButtonsTheme()
            end)
        end
    end
    for _, t in ipairs(FuckYouLib.aimTabs or {}) do
        if t.Button then
            t.Button.MouseButton1Click:Connect(function()
                for _, m in ipairs(movementTabs) do if m.Frame then m.Frame.Visible = false end end
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
        if FuckYouLib.aimTabs and FuckYouLib.aimTabs[1] and FuckYouLib.aimTabs[1].Frame then
            FuckYouLib.aimTabs[1].Frame.Visible = true
        end
        FuckYouLib.updateTabButtonsTheme()
    end)
    FuckYouLib.Movement.MouseButton1Click:Connect(function()
        showMovementButtons()
        hideAllFrames()
        if movementTabs[1] and movementTabs[1].Frame then
            movementTabs[1].Frame.Visible = true
        end
        FuckYouLib.updateTabButtonsTheme()
    end)
    local function updateModuleTogglesVisibility(group)
        for _, t in ipairs(FuckYouLib.moduleToggles) do
            t.btn.Visible = (t.group == group)
        end
    end
    FuckYouLib.EmilyUi.MouseButton1Click:Connect(function() updateModuleTogglesVisibility("Main") end)
    FuckYouLib.Desync.MouseButton1Click:Connect(function() updateModuleTogglesVisibility("Desync") end)
    FuckYouLib.Music.MouseButton1Click:Connect(function() updateModuleTogglesVisibility("Music") end)
    FuckYouLib.Aim.MouseButton1Click:Connect(function() updateModuleTogglesVisibility("Aim") end)
    FuckYouLib.Movement.MouseButton1Click:Connect(function() updateModuleTogglesVisibility("Movement") end)
    updateModuleTogglesVisibility("Main")
end)

-- Config gather/apply
local function deepCopyMovement(t)
    local ok, json = pcall(function() return HttpService:JSONEncode(t) end)
    if not ok then return {} end
    local ok2, out = pcall(function() return HttpService:JSONDecode(json) end)
    if ok2 and type(out) == "table" then return out end
    return {}
end
local MovementDefaults = { Settings = deepCopyMovement(Settings), Keybinds = deepCopyMovement(Keybinds) }
local function gatherMovementConfig()
    return {
        Enabled = MovementEnabled,
        Settings = deepCopyMovement(Settings),
        Keybinds = deepCopyMovement(Keybinds),
        SelectedCategory = selectedCategory,
        SelectedRecording = selectedRecording and selectedRecording.Name or "",
    }
end
local function applyMovementConfig(cfg)
    if type(cfg) ~= "table" then return end
    if type(cfg.Settings) == "table" then
        local s = cfg.Settings
        for _, k in ipairs({"CircleMode","PathMode","LabelMode"}) do
            if s[k] == "Gradient" then s[k] = "TwoWay" end
            if s[k] == "TriColor" then s[k] = "ThreeWay" end
        end
        for k, v in pairs(s) do
            if Settings[k] ~= nil and type(v) == type(Settings[k]) then Settings[k] = v end
        end
        for _, k in ipairs({"CircleMode","PathMode","LabelMode"}) do
            if not table.find(COLOR_MODES, Settings[k]) then Settings[k] = "Solid" end
        end
    end
    if type(cfg.Keybinds) == "table" then
        for k, v in pairs(cfg.Keybinds) do
            if Keybinds[k] ~= nil and type(v) == "string" then Keybinds[k] = v end
        end
    end
    if type(cfg.SelectedCategory) == "string" and library.categories[cfg.SelectedCategory] then
        selectedCategory = cfg.SelectedCategory
    end
    selectedRecording = nil
    if type(cfg.SelectedRecording) == "string" and cfg.SelectedRecording ~= "" then
        for _, e in ipairs(library.categories[selectedCategory] or {}) do
            if e.Name == cfg.SelectedRecording then selectedRecording = e; break end
        end
    end
    saveSettings()
    if applyPromptKey then applyPromptKey() end
    if refreshCategories then refreshCategories() end
    if refreshRecordings then refreshRecordings() end
    if refreshMainInfo then refreshMainInfo() end
    if rebuildMarkers then rebuildMarkers() end
    if updateButtons then updateButtons() end
    if cfg.Enabled ~= nil then setMovementEnabled(cfg.Enabled and true or false) end
end
local function resetMovementConfig()
    Settings = deepCopyMovement(MovementDefaults.Settings)
    Keybinds = deepCopyMovement(MovementDefaults.Keybinds)
    selectedCategory = "Default"
    selectedRecording = nil
    saveSettings()
    if applyPromptKey then applyPromptKey() end
    if refreshCategories then refreshCategories() end
    if refreshRecordings then refreshRecordings() end
    if refreshMainInfo then refreshMainInfo() end
    if rebuildMarkers then rebuildMarkers() end
    if updateButtons then updateButtons() end
    setMovementEnabled(false)
end

FuckYouLib.registerKeyListProvider("Movement", function()
    local rows = {}
    if not MovementEnabled then return rows end
    if state == State.Recording then table.insert(rows, {"RECORD", "RECORDING..."})
    elseif (state == State.Playing or state == State.Aligning) and currentPlayback then
        table.insert(rows, {"PLAY", currentPlayback.Name or "ON"})
    end
    return rows
end)

MovementAPI = {
    Tabs = movementTabs,
    Gather = gatherMovementConfig,
    Apply = applyMovementConfig,
    Reset = resetMovementConfig,
}
_G.MovementAPI = MovementAPI

print("MovementModule loaded")