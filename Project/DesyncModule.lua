--// DesyncModule.lua — Desync Module
--// Вкладки: Desync, Desync Anim Editor, Desync Animations, Anim Manager, Keybinds, Anim Logger

local function initDesyncModule(Library)
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer

    local FOLDER = "EmilyUi/Animator"
    local FILE_DESYNC = FOLDER .. "/animations_saved.json"
    local FILE_R6 = FOLDER .. "/AnimationManagerJsonR6.json"
    local FILE_R15 = FOLDER .. "/AnimationManagerJsonR15.json"
    local FILE_KEYS = FOLDER .. "/keybinds.json"

    local function ensureDirs()
        if makefolder then
            pcall(function()
                if not isfolder("EmilyUi") then makefolder("EmilyUi") end
                if not isfolder(FOLDER) then makefolder(FOLDER) end
            end)
        end
    end

    local function loadMgr(mode)
        local p = (mode == "R6") and FILE_R6 or FILE_R15
        if isfile and isfile(p) then
            local ok, r = pcall(function()
                return HttpService:JSONDecode(readfile(p))
            end)
            if ok and type(r) == "table" then
                r._subcategories = r._subcategories or {}
                return r
            end
        end
        return {_subcategories = {}}
    end

    local function saveMgr(mode, data)
        if writefile then
            ensureDirs()
            pcall(function()
                writefile((mode == "R6") and FILE_R6 or FILE_R15, HttpService:JSONEncode(data))
            end)
        end
    end

    local function loadDesyncAnims()
        if isfile and isfile(FILE_DESYNC) then
            local ok, r = pcall(function()
                return HttpService:JSONDecode(readfile(FILE_DESYNC))
            end)
            if ok and type(r) == "table" then return r end
        end
        return {}
    end

    local function saveDesyncAnims(d)
        if writefile then
            ensureDirs()
            pcall(function() writefile(FILE_DESYNC, HttpService:JSONEncode(d)) end)
        end
    end

    local function loadKeys()
        local b = {}
        if isfile and isfile(FILE_KEYS) then
            local ok, r = pcall(function()
                return HttpService:JSONDecode(readfile(FILE_KEYS))
            end)
            if ok and type(r) == "table" then b = r end
        end
        if not b.Animations then b.Animations = {} end
        return b
    end

    local function saveKeys(d)
        if writefile then
            ensureDirs()
            pcall(function() writefile(FILE_KEYS, HttpService:JSONEncode(d)) end)
        end
    end

    local savedDesyncAnimations = loadDesyncAnims()
    local managerDataCache = {R6 = loadMgr("R6"), R15 = loadMgr("R15")}
    local keybinds = loadKeys()

    local OffsetPos = Vector3.new(0, 0, 0)
    local OffsetRot = Vector3.new(0, 0, 0)
    local IsDesynced = false
    local DesyncLoop, VisualChar = nil, nil
    local realCF = CFrame.new()
    local partMap = {}
    local RENDER_NAME = "DesyncPreCamera"
    local desyncChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local DesyncSectionEnabled = false

    local function parseV3(s)
        local p = string.split(string.gsub(s, " ", ""), ",")
        return Vector3.new(tonumber(p[1]) or 0, tonumber(p[2]) or 0, tonumber(p[3]) or 0)
    end

    local function strToV3(s)
        local t = {}
        for n in string.gmatch(s, "[^,]+") do
            table.insert(t, tonumber(n) or 0)
        end
        return Vector3.new(t[1] or 0, t[2] or 0, t[3] or 0)
    end

    local function buildPartMap(o, v, m)
        for _, ch in ipairs(o:GetChildren()) do
            local vc = v:FindFirstChild(ch.Name)
            if vc then
                if ch:IsA("BasePart") and vc:IsA("BasePart") then m[ch] = vc end
                buildPartMap(ch, vc, m)
            end
        end
    end

    local function stopDesync()
        IsDesynced = false
        OffsetPos = Vector3.new(0, 0, 0)
        OffsetRot = Vector3.new(0, 0, 0)
        if DesyncLoop then DesyncLoop:Disconnect(); DesyncLoop = nil end
        pcall(function() RunService:UnbindFromRenderStep(RENDER_NAME) end)
        if VisualChar then VisualChar:Destroy(); VisualChar = nil end
        table.clear(partMap)
    end

    local function startDesync()
        if not DesyncSectionEnabled then return end
        if IsDesynced then stopDesync() end
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        char.Archivable = true
        VisualChar = char:Clone()
        for _, v in pairs(VisualChar:GetDescendants()) do
            if v:IsA("Script") or v:IsA("LocalScript") then v:Destroy()
            elseif v:IsA("BasePart") then
                v.CanCollide = false; v.CastShadow = false; v.Anchored = true
                if v.Transparency < 0.5 then v.Transparency = 0.5 end
            elseif v:IsA("Humanoid") then
                v.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                v.PlatformStand = true
                v.Name = "FakeHumanoid"
            end
        end
        if not VisualChar.PrimaryPart then
            VisualChar.PrimaryPart = VisualChar:FindFirstChild("HumanoidRootPart")
        end
        table.clear(partMap)
        buildPartMap(char, VisualChar, partMap)
        VisualChar.Parent = workspace
        IsDesynced = true
        realCF = hrp.CFrame
        DesyncLoop = RunService.Heartbeat:Connect(function()
            if not IsDesynced or not char.Parent or not hrp.Parent then
                stopDesync(); return
            end
            realCF = hrp.CFrame
            local dCF = realCF * CFrame.new(OffsetPos) *
                CFrame.Angles(math.rad(OffsetRot.X), math.rad(OffsetRot.Y), math.rad(OffsetRot.Z))
            local rel = {}
            for op, _ in pairs(partMap) do
                if op.Parent then rel[op] = realCF:ToObjectSpace(op.CFrame) end
            end
            hrp.CFrame = dCF
            if VisualChar and VisualChar.Parent then
                for realPart, visualPart in pairs(partMap) do
                    local relativeCFrame = rel[realPart]
                    if relativeCFrame and visualPart and visualPart.Parent then
                        visualPart.CFrame = dCF * relativeCFrame
                    end
                end
            end
        end)
        RunService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.Camera.Value - 1, function()
            if not IsDesynced or not hrp.Parent then return end
            hrp.CFrame = realCF
            if workspace.CurrentCamera then
                workspace.CurrentCamera.CameraSubject = hum
            end
        end)
    end

    --// DESYNC TABS
    local desyncTabs = {}
    local function addDesyncTab(name, builder)
        local frame = Library.create("Frame", {
            Name = "Tab" .. name, Parent = Library.Containment,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1, BorderSizePixel = 0,
            Visible = false
        })
        builder(frame)
        local btn = Library.create("TextButton", {
            Name = "DBtn_" .. name, Parent = Library.MenuInsided,
            Size = UDim2.new(1, 0, 0, 40),
            LayoutOrder = 100 + #desyncTabs, Visible = false,
            BackgroundColor3 = Library.uiColor_ButtonColor,
            BorderColor3 = Library.COL_BORDER,
            TextColor3 = Library.uiColor_TextColor,
            Text = name, Font = Library.FONT, TextSize = 12,
            TextWrapped = true
        })
        local entry = {Frame = frame, Name = name, Button = btn}
        table.insert(desyncTabs, entry)
        table.insert(Library.themeElements.Buttons, btn)
        table.insert(Library.themeElements.Texts, btn)
        return entry
    end

    --// DESYNC TAB
    local function buildDesyncTab(parent)
        local sf = Library.create("ScrollingFrame", {
            Parent = parent, Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 4,
            CanvasSize = UDim2.new(0, 0, 0, 260)
        })
        local inner = Library.create("Frame", {
            Parent = sf, Size = UDim2.new(1, 0, 0, 260),
            BackgroundColor3 = Library.uiColor_SideBar,
            BorderSizePixel = 0, ClipsDescendants = true
        })
        table.insert(Library.themeElements.SideBars, inner)
        Library.createSection(inner, "Desync Controls")
        local orientationBox = Library.createTextBox(inner, "0,0,0", Library.FONT)
        orientationBox.Size = UDim2.new(1, -24, 0, 24)
        orientationBox.Position = UDim2.new(0, 12, 0, 50)
        local positionBox = Library.createTextBox(inner, "0,0,0", Library.FONT)
        positionBox.Size = UDim2.new(1, -24, 0, 24)
        positionBox.Position = UDim2.new(0, 12, 0, 100)
        local applyBtn = Library.createContentButton(inner, "Apply Changes", function()
            OffsetRot = parseV3(orientationBox.Text)
            OffsetPos = parseV3(positionBox.Text)
        end)
        applyBtn.Position = UDim2.new(0, 12, 0, 140)
        local toggleBtn = Library.createContentButton(inner, "Desync: OFF", function()
            if IsDesynced then stopDesync() else startDesync() end
            toggleBtn.Text = "Desync: " .. (IsDesynced and "ON" or "OFF")
        end)
        toggleBtn.Position = UDim2.new(0, 12, 0, 180)
        Library.registerToggle(toggleBtn, function() return IsDesynced end)
    end

    --// EDITOR TAB
    local function buildEditorTab(parent)
        Library.createSection(parent, "Desync Animation Editor")
        Library.createLabel(parent, "Create and edit desync animations here")
    end

    --// ANIMATIONS TAB
    local function buildDesyncAnimsTab(parent)
        Library.createSection(parent, "Desync Animations")
        Library.createLabel(parent, "Play saved desync animations")
    end

    --// MANAGER TAB
    local function buildManagerTab(parent)
        Library.createSection(parent, "Animation Manager")
        Library.createLabel(parent, "Manage R6/R15 animations")
    end

    --// KEYBINDS TAB
    local function buildKeybindsTab(parent)
        Library.createSection(parent, "Keybinds")
        Library.createLabel(parent, "Bind keys to animations")
    end

    --// LOGGER TAB
    local function buildLoggerTab(parent)
        Library.createSection(parent, "Animation Logger")
        Library.createLabel(parent, "Logs played animations")
    end

    addDesyncTab("Desync", buildDesyncTab)
    addDesyncTab("Desync Anim Editor", buildEditorTab)
    addDesyncTab("Desync Animations", buildDesyncAnimsTab)
    addDesyncTab("Anim Manager", buildManagerTab)
    addDesyncTab("Keybinds", buildKeybindsTab)
    addDesyncTab("Anim Logger", buildLoggerTab)

    --// SIDEBAR TOGGLE
    local DesyncSidebarToggle = Library.create("TextButton", {
        Name = "MToggle_Desync", Parent = Library.MenuInsided,
        Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 190, Visible = false,
        BorderColor3 = Library.COL_BORDER,
        Text = "Desync: OFF", Font = Library.FONT,
        TextSize = 12, TextWrapped = true,
        BackgroundTransparency = 1 - Library.uiGuiOpacity,
    })
    table.insert(Library.themeElements.CustomButtons, DesyncSidebarToggle)
    table.insert(Library.moduleToggles, {btn = DesyncSidebarToggle, group = "Desync"})
    Library.registerToggle(DesyncSidebarToggle, function() return DesyncSectionEnabled end)

    DesyncSidebarToggle.MouseButton1Click:Connect(function()
        DesyncSectionEnabled = not DesyncSectionEnabled
        if not DesyncSectionEnabled and IsDesynced then stopDesync() end
        DesyncSidebarToggle.Text = "Desync: " .. (DesyncSectionEnabled and "ON" or "OFF")
        Library.paintToggleBtn(DesyncSidebarToggle, DesyncSectionEnabled)
    end)

    --// KEY LIST PROVIDER
    Library.registerKeyListProvider("Desync", function()
        local rows = {}
        if not DesyncSectionEnabled then return rows end
        if IsDesynced then table.insert(rows, {"DESYNC", "ON"}) end
        return rows
    end)

    --// CLEANUP
    Library.ScreenGui.Destroying:Connect(function()
        pcall(function()
            DesyncSectionEnabled = false
            if IsDesynced then stopDesync() end
        end)
    end)

    return {
        Tabs = desyncTabs,
        Keybinds = keybinds,
    }
end

return initDesyncModule