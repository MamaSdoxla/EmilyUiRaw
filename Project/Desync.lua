--// Desync.lua
return function(Library, ui)
    local create = Library.create
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer
    local FONT = Enum.Font.SpecialElite

    local DesyncBtn = Library.CreateButton(ui.SideBar, "Desync", function() end)
    DesyncBtn.Size = UDim2.new(1, 0, 0, 59); DesyncBtn.Position = UDim2.new(0, 0, 0, 59)

    local desyncTabs = {}
    local function addDesyncTab(name, order, builder)
        local btn = Library.CreateButton(ui.Menu, name, function() end)
        btn.Size = UDim2.new(1, 0, 0, 40); btn.LayoutOrder = 100 + order; btn.Visible = false
        local frame = create("Frame", {Name = "Tab"..name, Parent = ui.Containment, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false})
        table.insert(desyncTabs, {Name = name, Button = btn, Frame = frame})
        btn.MouseButton1Click:Connect(function()
            for _, t in ipairs(desyncTabs) do t.Frame.Visible = (t.Name == name) end
            Library.applyTheme()
        end)
        builder(frame)
        return frame
    end

    local FOLDER = "EmilyUi/Animator"
    local FILE_DESYNC = FOLDER .. "/animations_saved.json"
    local FILE_KEYS = FOLDER .. "/keybinds.json"
    
    local function ensureDirs() if makefolder then pcall(function() if not isfolder("EmilyUi") then makefolder("EmilyUi") end; if not isfolder(FOLDER) then makefolder(FOLDER) end end) end end
    local function loadJson(path) if isfile and isfile(path) then local ok, r = pcall(function() return HttpService:JSONDecode(readfile(path)) end); if ok and type(r) == "table" then return r end end; return {} end
    local function saveJson(path, data) if writefile then ensureDirs(); pcall(function() writefile(path, HttpService:JSONEncode(data)) end) end end

    local savedDesyncAnimations = loadJson(FILE_DESYNC)
    local keybinds = loadJson(FILE_KEYS)
    if not keybinds.Animations then keybinds.Animations = {} end

    local OffsetPos, OffsetRot = Vector3.new(0, 0, 0), Vector3.new(0, 0, 0)
    local IsDesynced, DesyncLoop, VisualChar = false, nil, nil
    local partMap = {}
    local DesyncSectionEnabled = false

    local function stopDesync()
        IsDesynced = false
        OffsetPos, OffsetRot = Vector3.new(0, 0, 0), Vector3.new(0, 0, 0)
        if DesyncLoop then DesyncLoop:Disconnect(); DesyncLoop = nil end
        pcall(function() RunService:UnbindFromRenderStep("DesyncPreCamera") end)
        if VisualChar then VisualChar:Destroy(); VisualChar = nil end
        table.clear(partMap)
    end

    local function startDesync()
        if not DesyncSectionEnabled then return end
        stopDesync()
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        char.Archivable = true
        VisualChar = char:Clone()
        for _, v in pairs(VisualChar:GetDescendants()) do
            if v:IsA("Script") or v:IsA("LocalScript") then v:Destroy()
            elseif v:IsA("BasePart") then v.CanCollide = false; v.CastShadow = false; v.Anchored = true; if v.Transparency < .5 then v.Transparency = 0.5 end
            elseif v:IsA("Humanoid") then v.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None; v.PlatformStand = true; v.Name = "FakeHumanoid" end
        end
        if not VisualChar.PrimaryPart then VisualChar.PrimaryPart = VisualChar:FindFirstChild("HumanoidRootPart") end
        table.clear(partMap)
        for _, ch in ipairs(char:GetChildren()) do
            local vc = VisualChar:FindFirstChild(ch.Name)
            if ch:IsA("BasePart") and vc and vc:IsA("BasePart") then partMap[ch] = vc end
        end
        VisualChar.Parent = workspace
        IsDesynced = true
        local realCF = hrp.CFrame
        DesyncLoop = RunService.Heartbeat:Connect(function()
            if not IsDesynced or not char.Parent or not hrp.Parent then stopDesync(); return end
            realCF = hrp.CFrame
            local dCF = realCF * CFrame.new(OffsetPos) * CFrame.Angles(math.rad(OffsetRot.X), math.rad(OffsetRot.Y), math.rad(OffsetRot.Z))
            local rel = {}
            for op, _ in pairs(partMap) do if op.Parent then rel[op] = realCF:ToObjectSpace(op.CFrame) end end
            hrp.CFrame = dCF
            if VisualChar and VisualChar.Parent then
                for realPart, visualPart in pairs(partMap) do
                    local relativeCFrame = rel[realPart]
                    if relativeCFrame and visualPart and visualPart.Parent then visualPart.CFrame = dCF * relativeCFrame end
                end
            end
        end)
        RunService:BindToRenderStep("DesyncPreCamera", Enum.RenderPriority.Camera.Value - 1, function()
            if not IsDesynced or not hrp.Parent then return end
            hrp.CFrame = realCF
            if workspace.CurrentCamera then workspace.CurrentCamera.CameraSubject = char:FindFirstChildOfClass("Humanoid") end
        end)
    end

    addDesyncTab("Desync", 1, function(parent)
        Library.CreateSection(parent, "Desync Controls")
        local orientBox = Library.CreateTextBox(parent, "0,0,0", FONT)
        local posBox = Library.CreateTextBox(parent, "0,0,0", FONT)
        Library.CreateButton(parent, "Apply Changes", function()
            local function parseV3(s) local p = string.split(string.gsub(s, " ", ""), ","); return Vector3.new(tonumber(p[1]) or 0, tonumber(p[2]) or 0, tonumber(p[3]) or 0) end
            OffsetRot = parseV3(orientBox.Text); OffsetPos = parseV3(posBox.Text)
        end)
        Library.CreateToggle(parent, "Desync", false, function(on) if on then startDesync() else stopDesync() end end)
        Library.CreateButton(parent, "Desync Reload", function() stopDesync(); task.wait(0.1); startDesync() end)
    end)

    addDesyncTab("Anim Editor", 2, function(parent)
        Library.CreateSection(parent, "Animation Editor")
        local nameBox = Library.CreateTextBox(parent, "Animation Name", FONT)
        Library.CreateButton(parent, "Save Animation", function()
            savedDesyncAnimations[nameBox.Text] = {frames = {}} 
            saveJson(FILE_DESYNC, savedDesyncAnimations)
            Library.notify("Editor", "Saved!")
        end)
    end)

    addDesyncTab("Desync Animations", 3, function(parent)
        Library.CreateSection(parent, "Saved Animations")
        for name, data in pairs(savedDesyncAnimations) do
            Library.CreateButton(parent, name, function() Library.notify("Anim", "Playing: " .. name) end)
        end
    end)

    addDesyncTab("Keybinds", 4, function(parent)
        Library.CreateSection(parent, "Desync Keybinds")
        Library.CreateButton(parent, "Bind Desync Toggle", function() Library.notify("Keybind", "Press any key...") end)
    end)

    DesyncBtn.MouseButton1Click:Connect(function()
        for _, t in ipairs(desyncTabs) do t.Button.Visible = true end
        if desyncTabs[1] then desyncTabs[1].Frame.Visible = true end
        Library.applyTheme()
    end)

    Library.registerKeyListProvider("Desync", function()
        local rows = {}
        if not DesyncSectionEnabled then return rows end
        if IsDesynced then table.insert(rows, {"DESYNC", "ON"}) end
        return rows
    end)

    return { Tabs = desyncTabs, Gather = function() return {} end, Apply = function() end, Reset = function() end }
end