--// DesyncModule.lua
local function initDesyncModule(Library)
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer

    local desyncTabs = {}
    local function addDesyncTab(name, builder)
        local frame = Library.create("Frame", {Name = "Tab" .. name, Parent = Library.Containment, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false})
        builder(frame)
        local btn = Library.create("TextButton", {Name = "DBtn_" .. name, Parent = Library.MenuInsided, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 100 + #desyncTabs, Visible = false, BackgroundColor3 = Library.uiColor_ButtonColor, BorderColor3 = Library.COL_BORDER, TextColor3 = Library.uiColor_TextColor, Text = name, Font = Library.FONT, TextSize = 12, TextWrapped = true})
        local entry = {Frame = frame, Name = name, Button = btn}
        table.insert(desyncTabs, entry); table.insert(Library.themeElements.Buttons, btn); table.insert(Library.themeElements.Texts, btn)
        return entry
    end

    local OffsetPos = Vector3.new(0, 0, 0); local OffsetRot = Vector3.new(0, 0, 0)
    local IsDesynced = false; local DesyncLoop, VisualChar = nil, nil; local realCF = CFrame.new(); local partMap = {}
    local RENDER_NAME = "DesyncPreCamera"; local DesyncSectionEnabled = false

    local function stopDesync()
        IsDesynced = false; OffsetPos = Vector3.new(0, 0, 0); OffsetRot = Vector3.new(0, 0, 0)
        if DesyncLoop then DesyncLoop:Disconnect(); DesyncLoop = nil end
        pcall(function() RunService:UnbindFromRenderStep(RENDER_NAME) end)
        if VisualChar then VisualChar:Destroy(); VisualChar = nil end
        table.clear(partMap)
    end

    local function startDesync()
        if not DesyncSectionEnabled then return end
        if IsDesynced then stopDesync() end
        local char = LocalPlayer.Character; if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart"); local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        char.Archivable = true; VisualChar = char:Clone()
        for _, v in pairs(VisualChar:GetDescendants()) do
            if v:IsA("Script") or v:IsA("LocalScript") then v:Destroy()
            elseif v:IsA("BasePart") then v.CanCollide = false; v.CastShadow = false; v.Anchored = true; if v.Transparency < 0.5 then v.Transparency = 0.5 end
            elseif v:IsA("Humanoid") then v.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None; v.PlatformStand = true; v.Name = "FakeHumanoid" end
        end
        if not VisualChar.PrimaryPart then VisualChar.PrimaryPart = VisualChar:FindFirstChild("HumanoidRootPart") end
        table.clear(partMap)
        -- Build part map simplified
        VisualChar.Parent = workspace; IsDesynced = true; realCF = hrp.CFrame
        DesyncLoop = RunService.Heartbeat:Connect(function()
            if not IsDesynced or not char.Parent or not hrp.Parent then stopDesync(); return end
            realCF = hrp.CFrame
            local dCF = realCF * CFrame.new(OffsetPos) * CFrame.Angles(math.rad(OffsetRot.X), math.rad(OffsetRot.Y), math.rad(OffsetRot.Z))
            hrp.CFrame = dCF
        end)
        RunService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.Camera.Value - 1, function()
            if not IsDesynced or not hrp.Parent then return end
            hrp.CFrame = realCF; if workspace.CurrentCamera then workspace.CurrentCamera.CameraSubject = hum end
        end)
    end

    local function buildDesyncTab(parent)
        local sf = Library.create("ScrollingFrame", {Parent = parent, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 260)})
        local inner = Library.create("Frame", {Parent = sf, Size = UDim2.new(1, 0, 0, 260), BackgroundTransparency = 1})
        local layout = Library.create("UIListLayout", {Parent = inner, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
        Library.create("UIPadding", {Parent = inner, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 10)})
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() inner.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y + 20); sf.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20) end)
        
        Library.createSection(inner, "Desync Controls")
        local orientationBox = Library.createTextBox(inner, "0,0,0", Library.FONT)
        local positionBox = Library.createTextBox(inner, "0,0,0", Library.FONT)
        Library.createContentButton(inner, "Apply Changes", function()
            local function parseV3(s) local p = string.split(string.gsub(s, " ", ""), ","); return Vector3.new(tonumber(p[1]) or 0, tonumber(p[2]) or 0, tonumber(p[3]) or 0) end
            OffsetRot = parseV3(orientationBox.Text); OffsetPos = parseV3(positionBox.Text)
        end)
        local toggleBtn = Library.createContentButton(inner, "Desync: OFF", function()
            if IsDesynced then stopDesync() else startDesync() end
            toggleBtn.Text = "Desync: " .. (IsDesynced and "ON" or "OFF")
        end)
        Library.registerToggle(toggleBtn, function() return IsDesynced end)
    end

    local function buildEditorTab(parent)
        local sf = Library.create("ScrollingFrame", {Parent = parent, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 200)})
        local inner = Library.create("Frame", {Parent = sf, Size = UDim2.new(1, 0, 0, 200), BackgroundTransparency = 1})
        local layout = Library.create("UIListLayout", {Parent = inner, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
        Library.create("UIPadding", {Parent = inner, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 10)})
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() inner.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y + 20); sf.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20) end)
        Library.createSection(inner, "Desync Animation Editor")
        Library.createLabel(inner, "Create and edit desync animations here")
    end

    addDesyncTab("Desync", buildDesyncTab)
    addDesyncTab("Desync Anim Editor", buildEditorTab)
    addDesyncTab("Desync Animations", function(p) Library.createSection(p, "Desync Animations"); Library.createLabel(p, "Play saved desync animations") end)
    addDesyncTab("Anim Manager", function(p) Library.createSection(p, "Animation Manager"); Library.createLabel(p, "Manage R6/R15 animations") end)
    addDesyncTab("Keybinds", function(p) Library.createSection(p, "Keybinds"); Library.createLabel(p, "Bind keys to animations") end)
    addDesyncTab("Anim Logger", function(p) Library.createSection(p, "Animation Logger"); Library.createLabel(p, "Logs played animations") end)

    local DesyncSidebarToggle = Library.create("TextButton", {Name = "MToggle_Desync", Parent = Library.MenuInsided, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 190, Visible = false, BorderColor3 = Library.COL_BORDER, Text = "Desync: OFF", Font = Library.FONT, TextSize = 12, TextWrapped = true, BackgroundTransparency = 1 - Library.uiGuiOpacity})
    table.insert(Library.themeElements.CustomButtons, DesyncSidebarToggle); table.insert(Library.moduleToggles, {btn = DesyncSidebarToggle, group = "Desync"})
    Library.registerToggle(DesyncSidebarToggle, function() return DesyncSectionEnabled end)
    DesyncSidebarToggle.MouseButton1Click:Connect(function()
        DesyncSectionEnabled = not DesyncSectionEnabled
        if not DesyncSectionEnabled and IsDesynced then stopDesync() end
        DesyncSidebarToggle.Text = "Desync: " .. (DesyncSectionEnabled and "ON" or "OFF")
        Library.paintToggleBtn(DesyncSidebarToggle, DesyncSectionEnabled)
    end)

    Library.ScreenGui.Destroying:Connect(function() pcall(function() DesyncSectionEnabled = false; if IsDesynced then stopDesync() end end) end)
    Library.registerKeyListProvider("Desync", function() local rows = {}; if not DesyncSectionEnabled then return rows end; if IsDesynced then table.insert(rows, {"DESYNC", "ON"}) end; return rows end)

    return {Tabs = desyncTabs}
end
return initDesyncModule