-- DesyncModule.lua
local Core=_G.FuckYouCore; assert(Core,"Run FuckYouLibrary.lua first")
local create=Core.create; local themeElements=Core.themeElements; local FONT=Core.FONT; local COL_BORDER=Core.COL_BORDER
local LocalPlayer=Core.LocalPlayer; local Players=Core.Players; local RunService=Core.RunService; local HttpService=Core.HttpService; local UserInputService=Core.UserInputService
local ScreenGui=Core.ScreenGui; local MenuInsided=Core.MenuInsided; local Containment=Core.Containment; local tabs=Core.tabs; local tabFrames=Core.tabFrames
local notify=Core.notify; local paintToggleBtn=Core.paintToggleBtn; local registerToggle=Core.registerToggle; local registerKeyListProvider=Core.registerKeyListProvider; local applyTheme=Core.applyTheme; local updateTabButtonsTheme=Core.UpdateTabButtonsTheme; local autoSaveConfig=Core.autoSaveConfig
local Desync=Core.SideButtons.Desync
local createSection=Core.createSection; local createLabel=Core.createLabel; local createContentButton=Core.createContentButton; local createTextBox=Core.createTextBox

-- ========== DESYNC MODULE v4 =============================
-- =========================================================
local function initDesyncModule()
    local C_GRN = Color3.fromRGB(100, 255, 100)
    local C_ROFF = Color3.fromRGB(255, 100, 100)
    local C_REDD = Color3.fromRGB(150, 40, 40)
    local C_WHT = Color3.fromRGB(255, 255, 255)
    local F_R = FONT
    local F_B = FONT
    local F_S = FONT
    local F_I = FONT
    local FOLDER = "EmilyUi/Animator"
    local FILE_DESYNC = FOLDER .. "/animations_saved.json"
    local FILE_R6 = FOLDER .. "/AnimationManagerJsonR6.json"
    local FILE_R15 = FOLDER .. "/AnimationManagerJsonR15.json"
    local FILE_KEYS = FOLDER .. "/keybinds.json"
    local function ensureDirs()
        if makefolder then
            pcall(
                function()
                    if not isfolder("EmilyUi") then
                        makefolder("EmilyUi")
                    end
                    if not isfolder(FOLDER) then
                        makefolder(FOLDER)
                    end
                end
            )
        end
    end
    local function loadMgr(mode)
        local p = (mode == "R6") and FILE_R6 or FILE_R15
        if isfile and isfile(p) then
            local ok, r =
                pcall(
                function()
                    return HttpService:JSONDecode(readfile(p))
                end
            )
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
            pcall(
                function()
                    writefile((mode == "R6") and FILE_R6 or FILE_R15, HttpService:JSONEncode(data))
                end
            )
        end
    end
    local function loadDesyncAnims()
        if isfile and isfile(FILE_DESYNC) then
            local ok, r =
                pcall(
                function()
                    return HttpService:JSONDecode(readfile(FILE_DESYNC))
                end
            )
            if ok and type(r) == "table" then
                return r
            end
        end
        return {}
    end
    local function saveDesyncAnims(d)
        if writefile then
            ensureDirs()
            pcall(
                function()
                    writefile(FILE_DESYNC, HttpService:JSONEncode(d))
                end
            )
        end
    end
    local function loadKeys()
        local b = {}
        if isfile and isfile(FILE_KEYS) then
            local ok, r =
                pcall(
                function()
                    return HttpService:JSONDecode(readfile(FILE_KEYS))
                end
            )
            if ok and type(r) == "table" then
                b = r
            end
        end
        if not b.Animations then
            b.Animations = {}
        end
        if b.Animations and not b.Animations[1] then
            local old = b.Animations
            b.Animations = {}
            if old.Desync and old.Desync.key then
                table.insert(
                    b.Animations,
                    {
                        key = old.Desync.key,
                        type = "Desync",
                        animName = old.Desync.animName,
                        speed = old.Desync.speed or 1,
                        looped = old.Desync.looped or false,
                        reversed = old.Desync.reversed or false
                    }
                )
            end
            if old.Normal and old.Normal.key then
                table.insert(
                    b.Animations,
                    {
                        key = old.Normal.key,
                        type = "Normal",
                        animName = old.Normal.animName,
                        bodyType = old.Normal.bodyType or "R6",
                        speed = old.Normal.speed or 1,
                        looped = old.Normal.looped or false,
                        reversed = old.Normal.reversed or false
                    }
                )
            end
        end
        return b
    end
    local function saveKeys(d)
        if writefile then
            ensureDirs()
            pcall(
                function()
                    writefile(FILE_KEYS, HttpService:JSONEncode(d))
                end
            )
        end
    end
    local savedDesyncAnimations = loadDesyncAnims()
    local managerDataCache = {R6 = loadMgr("R6"), R15 = loadMgr("R15")}
    local keybinds = loadKeys()
    local OffsetPos = Vector3.new(0, 0, 0)
    local OffsetRot = Vector3.new(0, 0, 0)
    local isRunning = true
    local IsDesynced = false
    local DesyncLoop, VisualChar, CharDeathConn = nil, nil, nil
    local realCF = CFrame.new()
    local partMap = {}
    local RENDER_NAME = "DesyncPreCamera"
    local desyncChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local DesyncToggleBtn, OrientationInput, PositionInput = nil, nil, nil
    local keybindWaitForInput = false
    local onKeybindPressed = nil
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
                if ch:IsA("BasePart") and vc:IsA("BasePart") then
                    m[ch] = vc
                end
                buildPartMap(ch, vc, m)
            end
        end
    end
    local function lighter(c, amt)
        return Color3.fromRGB(
            math.min(c.R * 255 + amt, 255),
            math.min(c.G * 255 + amt, 255),
            math.min(c.B * 255 + amt, 255)
        )
    end
    local function darker(c, amt)
        return Color3.fromRGB(math.max(c.R * 255 - amt, 0), math.max(c.G * 255 - amt, 0), math.max(c.B * 255 - amt, 0))
    end
    local function stopDesync()
        IsDesynced = false
        if DesyncToggleBtn then
            DesyncToggleBtn.Text = "Desync: OFF"
            paintToggleBtn(DesyncToggleBtn, false)
        end
        OffsetPos = Vector3.new(0, 0, 0)
        OffsetRot = Vector3.new(0, 0, 0)
        if OrientationInput then
            OrientationInput.Text = "0,0,0"
        end
        if PositionInput then
            PositionInput.Text = "0,0,0"
        end
        if DesyncLoop then
            DesyncLoop:Disconnect()
            DesyncLoop = nil
        end
        pcall(
            function()
                RunService:UnbindFromRenderStep(RENDER_NAME)
            end
        )
        if VisualChar then
            VisualChar:Destroy()
            VisualChar = nil
        end
        table.clear(partMap)
    end
    local function startDesync()
        if not DesyncSectionEnabled then
            return
        end
        if IsDesynced then
            stopDesync()
        end
        local char = LocalPlayer.Character
        if not char then
            return
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then
            return
        end
        char.Archivable = true
        VisualChar = char:Clone()
        for _, v in pairs(VisualChar:GetDescendants()) do
            if v:IsA("Script") or v:IsA("LocalScript") then
                v:Destroy()
            elseif v:IsA("BasePart") then
                v.CanCollide = false
                v.CastShadow = false
                v.Anchored = true
                if v.Transparency < 0.5 then
                    v.Transparency = 0.5
                end
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
        if DesyncToggleBtn then
            DesyncToggleBtn.Text = "Desync: ON"
            paintToggleBtn(DesyncToggleBtn, true)
        end
        realCF = hrp.CFrame
        DesyncLoop =
            RunService.Heartbeat:Connect(
            function()
                if not IsDesynced or not char.Parent or not hrp.Parent then
                    stopDesync()
                    return
                end
                realCF = hrp.CFrame
                local dCF =
                    realCF * CFrame.new(OffsetPos) *
                    CFrame.Angles(math.rad(OffsetRot.X), math.rad(OffsetRot.Y), math.rad(OffsetRot.Z))
                local rel = {}
                for op, _ in pairs(partMap) do
                    if op.Parent then
                        rel[op] = realCF:ToObjectSpace(op.CFrame)
                    end
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
            end
        )
        RunService:BindToRenderStep(
            RENDER_NAME,
            Enum.RenderPriority.Camera.Value - 1,
            function()
                if not IsDesynced or not hrp.Parent then
                    return
                end
                hrp.CFrame = realCF
                if workspace.CurrentCamera then
                    workspace.CurrentCamera.CameraSubject = hum
                end
            end
        )
    end
    local function reloadDesync()
        stopDesync()
        task.wait(0.1)
        startDesync()
    end
    local curDesyncName, curDesyncPlaying, desyncThread = nil, false, nil
    local function stopDesyncAnim()
        if desyncThread then
            task.cancel(desyncThread)
            desyncThread = nil
        end
        curDesyncPlaying = false
        curDesyncName = nil
        OffsetRot = Vector3.new(0, 0, 0)
        OffsetPos = Vector3.new(0, 0, 0)
        if OrientationInput then
            OrientationInput.Text = "0,0,0"
        end
        if PositionInput then
            PositionInput.Text = "0,0,0"
        end
    end
    local function playDesyncAnim(name, loop, speed, reversed)
        if not DesyncSectionEnabled then
            return
        end
        stopDesyncAnim()
        local d = savedDesyncAnimations[name]
        if not d or not d.frames then
            return
        end
        curDesyncName = name
        curDesyncPlaying = true
        local frames = d.frames
        if reversed then
            local r = {}
            for i = #frames, 1, -1 do
                table.insert(r, frames[i])
            end
            frames = r
        end
        desyncThread =
            task.spawn(
            function()
                while curDesyncPlaying and isRunning do
                    for _, f in ipairs(frames) do
                        if not curDesyncPlaying then
                            break
                        end
                        local tR, tP = strToV3(f.rot), strToV3(f.pos)
                        local dur = (f.time or 1) / (speed or 1)
                        local sR, sP = OffsetRot, OffsetPos
                        local el = 0
                        while el < dur and curDesyncPlaying and isRunning do
                            el = el + RunService.Heartbeat:Wait()
                            local t = math.min(el / dur, 1)
                            OffsetRot = sR:Lerp(tR, t)
                            OffsetPos = sP:Lerp(tP, t)
                        end
                    end
                    if not loop then
                        break
                    end
                end
                curDesyncPlaying = false
                curDesyncName = nil
                desyncThread = nil
            end
        )
    end
    local curNormTrack, curNormName = nil, nil
    local function stopNormAnim()
        if curNormTrack then
            pcall(
                function()
                    curNormTrack:Stop()
                end
            )
            curNormTrack = nil
        end
        curNormName = nil
    end
    local function playNormAnim(bt, name, speed, looped, reversed)
        if not DesyncSectionEnabled then
            return
        end
        stopNormAnim()
        local data = managerDataCache[bt]
        if not data then
            return
        end
        local id = data[name]
        if not id then
            for _, st in pairs(data._subcategories or {}) do
                if st[name] then
                    id = st[name]
                    break
                end
            end
        end
        if not id then
            return
        end
        local clean = string.match(tostring(id), "%d+") or id
        if desyncChar and desyncChar:FindFirstChildOfClass("Humanoid") then
            local a = Instance.new("Animation")
            a.AnimationId = "rbxassetid://" .. clean
            local hum = desyncChar:FindFirstChildOfClass("Humanoid")
            local an = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
            local ok, tr =
                pcall(
                function()
                    return an:LoadAnimation(a)
                end
            )
            if ok and tr then
                curNormTrack = tr
                curNormName = name
                tr.Looped = looped or false
                local sp = speed or 1
                if reversed then
                    sp = -sp
                end
                tr:Play()
                tr:AdjustSpeed(sp)
                if reversed and tr.Length > 0 then
                    tr.TimePosition = tr.Length
                end
            end
        end
    end
    local function handleKeybind(key)
        if not key then
            return
        end
        if not DesyncSectionEnabled then
            return
        end
        if keybinds.Desync and keybinds.Desync.key == key then
            if IsDesynced then
                stopDesync()
            else
                startDesync()
            end
            return
        end
        if keybinds.Animations then
            for _, b in ipairs(keybinds.Animations) do
                if b.key == key then
                    if b.type == "Desync" then
                        if curDesyncPlaying and curDesyncName == b.animName then
                            stopDesyncAnim()
                        else
                            playDesyncAnim(b.animName, b.looped, b.speed, b.reversed)
                        end
                    elseif b.type == "Normal" then
                        if curNormTrack and curNormName == b.animName then
                            stopNormAnim()
                        else
                            playNormAnim(b.bodyType, b.animName, b.speed, b.looped, b.reversed)
                        end
                    end
                end
            end
        end
    end
    UserInputService.InputBegan:Connect(
        function(inp, processed)
            if processed then
                return
            end
            if inp.UserInputType == Enum.UserInputType.Keyboard then
                local k = inp.KeyCode.Name
                if keybindWaitForInput then
                    if onKeybindPressed then
                        onKeybindPressed(k)
                    end
                    keybindWaitForInput = false
                    return
                end
                handleKeybind(k)
            end
        end
    )
    local function corner(p)
        Instance.new("UICorner", p).CornerRadius = UDim.new(0, 4)
    end
    local function mkLabel(p, txt, sz, pos, font, ts)
        local l = Instance.new("TextLabel")
        l.Parent = p
        l.Text = txt
        l.Size = sz
        l.Position = pos
        l.Font = font or F_S
        l.TextSize = 13
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextColor3 = uiColor_TextColor
        l.BackgroundTransparency = 1
        table.insert(themeElements.Texts, l)
        return l
    end
    local function mkBox(p, txt, sz, pos, ts)
        local b = Instance.new("TextBox")
        b.Parent = p
        b.Text = txt or ""
        b.Size = sz
        b.Position = pos
        b.Font = F_R
        b.TextSize = ts or 16
        b.BackgroundColor3 = uiColor_TextBoxColor
        b.TextColor3 = uiColor_TextColor
        b.PlaceholderColor3 = Color3.fromRGB(90, 90, 90)
        b.BorderSizePixel = 0
        b.ClearTextOnFocus = false
        b.BackgroundTransparency = 1 - uiGuiOpacity -- FIX
        table.insert(themeElements.TextBoxes, b)
        table.insert(themeElements.Texts, b)
        corner(b)
        return b
    end
    local function mkBtn(p, txt, sz, pos, font, ts, themed)
        local b = Instance.new("TextButton")
        b.Parent = p
        b.Text = txt
        b.Size = sz
        b.Position = pos
        b.Font = font or F_B
        b.TextSize = 13
        b.BackgroundColor3 = uiColor_ButtonColor
        b.TextColor3 = uiColor_TextColor
        b.BorderSizePixel = 0
        if themed ~= "no" then
            table.insert(themeElements.Buttons, b)
            table.insert(themeElements.Texts, b)
        else
            table.insert(themeElements.CustomButtons, b)
        end
        b.BackgroundTransparency = 1 - uiGuiOpacity
        corner(b)
        return b
    end
    local function mkPanel(p, sz, pos)
        local f = Instance.new("Frame")
        f.Parent = p
        f.Size = sz
        f.Position = pos or UDim2.new(0, 0, 0, 0)
        f.BackgroundColor3 = uiColor_SideBar
        f.BorderSizePixel = 0
        f.ClipsDescendants = true
        table.insert(themeElements.SideBars, f)
        corner(f)
        return f
    end
    local function mkListBG(p, sz, pos)
        local f =
            create(
            "ScrollingFrame",
            {
                Parent = p,
                Size = sz,
                Position = pos,
                BackgroundColor3 = uiColor_TextBoxColor,
                BorderSizePixel = 0,
                ScrollBarThickness = 4,
                CanvasSize = UDim2.new(0, 0, 0, 0)
            }
        )
        table.insert(themeElements.TextBoxes, f)
        corner(f)
        return f
    end
    --// FIX: реестр динамически создаваемых элементов — на них тоже действует Gui Opacity
    local dynamicOpacity = {}
    local function trackOpacity(inst)
        inst.BackgroundTransparency = 1 - uiGuiOpacity
        table.insert(dynamicOpacity, inst)
        return inst
    end
    --// 1. DESYNC
    local function buildDesyncTab(parent)
        local sf =
            create(
            "ScrollingFrame",
            {
                Parent = parent,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 4,
                CanvasSize = UDim2.new(0, 0, 0, 260)
            }
        )
        local inner = mkPanel(sf, UDim2.new(1, 0, 0, 260))
        mkLabel(inner, "Orientation", UDim2.new(1, -24, 0, 18), UDim2.new(0, 12, 0, 8), F_S, 20)
        OrientationInput = mkBox(inner, "0,0,0", UDim2.new(1, -24, 0, 24), UDim2.new(0, 12, 0, 26), 20)
        mkLabel(inner, "Position", UDim2.new(1, -24, 0, 18), UDim2.new(0, 12, 0, 56), F_S, 20)
        PositionInput = mkBox(inner, "0,0,0", UDim2.new(1, -24, 0, 24), UDim2.new(0, 12, 0, 74), 20)
        local applyBtn = mkBtn(inner, "Apply Changes", UDim2.new(1, -24, 0, 28), UDim2.new(0, 12, 0, 110), F_B, 20)
        DesyncToggleBtn =
		    mkBtn(inner, "Desync: OFF", UDim2.new(0.5, -16, 0, 28), UDim2.new(0, 12, 0, 150), F_B, 15, false)
	    registerToggle(DesyncToggleBtn, function() return IsDesynced end)
        local reloadBtn = mkBtn(inner, "Desync Reload", UDim2.new(0.5, -16, 0, 28), UDim2.new(0.5, 4, 0, 150), F_B, 14)
        applyBtn.MouseButton1Click:Connect(
            function()
                OffsetRot = parseV3(OrientationInput.Text)
                OffsetPos = parseV3(PositionInput.Text)
                applyBtn.Text = "Applied!"
                task.wait(0.4)
                applyBtn.Text = "Apply Changes"
            end
        )
        DesyncToggleBtn.MouseButton1Click:Connect(
            function()
                if IsDesynced then
                    stopDesync()
                else
                    startDesync()
                end
            end
        )
        reloadBtn.MouseButton1Click:Connect(reloadDesync)
    end
    --// 2. ANIM EDITOR
    local function buildEditorTab(parent)
        local sf =
            create(
            "ScrollingFrame",
            {
                Parent = parent,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 4,
                CanvasSize = UDim2.new(0, 0, 0, 280)
            }
        )
        local inner = mkPanel(sf, UDim2.new(1, 0, 0, 280))
        local left =
            create(
            "Frame",
            {
                Parent = inner,
                Size = UDim2.new(0.5, -4, 1, 0),
                Position = UDim2.new(0, 2, 0, 0),
                BackgroundTransparency = 1
            }
        )
        local right = mkListBG(inner, UDim2.new(0.5, -6, 1, -10), UDim2.new(0.5, 4, 0, 5))
        local rLayout = create("UIListLayout", {Parent = right, Padding = UDim.new(0, 2)})
        rLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(
            function()
                right.CanvasSize = UDim2.new(0, 0, 0, rLayout.AbsoluteContentSize.Y + 6)
            end
        )
        local function field(lbl, def, y)
            mkLabel(left, lbl, UDim2.new(1, -20, 0, 16), UDim2.new(0, 10, 0, y), F_S, 14)
            return mkBox(left, def, UDim2.new(1, -20, 0, 22), UDim2.new(0, 10, 0, y + 16), 14)
        end
        local edO = field("Orientation", "0,0,0", 5)
        local edP = field("Position", "0,0,0", 45)
        local edT = field("Time (seconds)", "1.0", 85)
        local edN = field("Animation Name", "MyAnimation", 125)
        local loadBtn = mkBtn(left, "Load Animation", UDim2.new(1, -20, 0, 22), UDim2.new(0, 10, 0, 165), F_B, 12)
        local loadDD = mkListBG(left, UDim2.new(1, -20, 0, 60), UDim2.new(0, 10, 0, 190))
        loadDD.ZIndex = 5
        create("UIListLayout", {Parent = loadDD})
        local addB = mkBtn(left, "Add", UDim2.new(0, 40, 0, 24), UDim2.new(0, 10, 0, 215), F_B, 14)
        local remB = mkBtn(left, "Remove", UDim2.new(0, 50, 0, 24), UDim2.new(0, 55, 0, 215), F_B, 14)
        local editB = mkBtn(left, "Edit", UDim2.new(0, 50, 0, 24), UDim2.new(0, 110, 0, 215), F_B, 14)
        local saveB = mkBtn(left, "Save", UDim2.new(0, 40, 0, 24), UDim2.new(1, -50, 0, 215), F_B, 14)
        local editing, selIdx = {}, nil
        local function refresh()
            for _, ch in ipairs(right:GetChildren()) do
                if ch:IsA("TextButton") then
                    ch:Destroy()
                end
            end
            for i, fd in ipairs(editing) do
                local b =
                    create(
                    "TextButton",
                    {
                        Parent = right,
                        Size = UDim2.new(1, 0, 0, 20),
                        BackgroundColor3 = (selIdx == i) and lighter(uiColor_ButtonColor, 40) or uiColor_ButtonColor,
                        TextColor3 = uiColor_TextColor,
                        Text = string.format("[%d] P:%s O:%s T:%s", i, fd.pos, fd.rot, tostring(fd.time)),
                        Font = F_R,
                        TextSize = 13,
                        BorderSizePixel = 0
                    }
                )
                corner(b)
                trackOpacity(b) -- FIX
                b.MouseButton1Click:Connect(
                    function()
                        selIdx = i
                        edO.Text = fd.rot
                        edP.Text = fd.pos
                        edT.Text = tostring(fd.time)
                        refresh()
                    end
                )
            end
        end
        local function refreshDD()
            for _, ch in ipairs(loadDD:GetChildren()) do
                if ch:IsA("TextButton") then
                    ch:Destroy()
                end
            end
            local c = 0
            for name, d in pairs(savedDesyncAnimations) do
                if d.frames then
                    c = c + 1
                    local b = mkBtn(loadDD, name, UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 0), F_R, 12)
                    b.ZIndex = 6
                    b.MouseButton1Click:Connect(
                        function()
                            local ld = savedDesyncAnimations[name]
                            if ld and ld.frames and #ld.frames > 0 then
                                editing = {}
                                for _, fr in ipairs(ld.frames) do
                                    table.insert(editing, {rot = fr.rot, pos = fr.pos, time = fr.time or 1})
                                end
                                edN.Text = name
                                refresh()
                                loadDD.Visible = false
                                loadBtn.Text = "Loaded: " .. name
                            end
                        end
                    )
                end
            end
            loadDD.CanvasSize = UDim2.new(0, 0, 0, c * 22)
        end
        loadBtn.MouseButton1Click:Connect(
            function()
                savedDesyncAnimations = loadDesyncAnims()
                refreshDD()
                loadDD.Visible = not loadDD.Visible
            end
        )
        addB.MouseButton1Click:Connect(
            function()
                table.insert(editing, {rot = edO.Text, pos = edP.Text, time = tonumber(edT.Text) or 1})
                refresh()
            end
        )
        remB.MouseButton1Click:Connect(
            function()
                if selIdx and editing[selIdx] then
                    table.remove(editing, selIdx)
                    selIdx = nil
                    refresh()
                end
            end
        )
        editB.MouseButton1Click:Connect(
            function()
                if selIdx then
                    editing[selIdx] = {rot = edO.Text, pos = edP.Text, time = tonumber(edT.Text) or 1}
                    refresh()
                    editB.Text = "Updated!"
                    task.wait(0.3)
                    editB.Text = "Edit"
                end
            end
        )
        saveB.MouseButton1Click:Connect(
            function()
                if edN.Text ~= "" and #editing > 0 then
                    savedDesyncAnimations[edN.Text] = {frames = editing}
                    saveDesyncAnims(savedDesyncAnimations)
                    saveB.Text = "Saved!"
                    task.wait(0.5)
                    saveB.Text = "Save"
                end
            end
        )
        refresh()
    end
    --// 3. DESYNC ANIMATIONS
    local function buildDesyncAnimsTab(parent)
        local sf =
            create(
            "ScrollingFrame",
            {
                Parent = parent,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 4,
                CanvasSize = UDim2.new(0, 0, 0, 260)
            }
        )
        local inner = mkPanel(sf, UDim2.new(1, 0, 0, 260))
        local ddBtn = mkBtn(inner, "Select Animation v", UDim2.new(1, -24, 0, 30), UDim2.new(0, 12, 0, 10), F_B, 16)
        local ddList = mkListBG(inner, UDim2.new(1, -24, 0, 80), UDim2.new(0, 12, 0, 42))
        ddList.ZIndex = 5
        create("UIListLayout", {Parent = ddList})
        local selected = nil
        local function updateDD()
            for _, ch in ipairs(ddList:GetChildren()) do
                if ch:IsA("TextButton") then
                    ch:Destroy()
                end
            end
            savedDesyncAnimations = loadDesyncAnims()
            local c = 0
            for name, d in pairs(savedDesyncAnimations) do
                if d.frames then
                    c = c + 1
                    local b = mkBtn(ddList, name, UDim2.new(1, 0, 0, 22), UDim2.new(0, 0, 0, 0), F_R, 14)
                    b.ZIndex = 6
                    b.MouseButton1Click:Connect(
                        function()
                            selected = name
                            ddBtn.Text = name .. " v"
                            ddList.Visible = false
                        end
                    )
                end
            end
            ddList.CanvasSize = UDim2.new(0, 0, 0, c * 22)
        end
        ddBtn.MouseButton1Click:Connect(
            function()
                updateDD()
                ddList.Visible = not ddList.Visible
            end
        )
        local loopBox = mkBtn(inner, "", UDim2.new(0, 20, 0, 20), UDim2.new(0, 12, 0, 87), F_B, 14, false)
        local looped = false
        loopBox.MouseButton1Click:Connect(
            function()
                looped = not looped
                loopBox.Text = looped and "X" or ""
                loopBox.TextColor3 = uiColor_TextColor
            end
        )
        mkLabel(inner, "Loop Animation", UDim2.new(1, -30, 0, 24), UDim2.new(0, 42, 0, 85), F_S, 16)
        mkLabel(inner, "Speed:", UDim2.new(0, 50, 0, 24), UDim2.new(0, 12, 0, 115), F_S, 16)
        local spdIn = mkBox(inner, "1.0", UDim2.new(1, -67, 0, 24), UDim2.new(0, 67, 0, 115), 16)
        local playBtn = mkBtn(inner, "Play", UDim2.new(0, 90, 0, 30), UDim2.new(0, 12, 0, 155), F_B, 16)
        local remBtn = mkBtn(inner, "Remove", UDim2.new(0, 90, 0, 30), UDim2.new(1, -102, 0, 155), F_B, 16, "no")
        remBtn.BackgroundColor3 = C_REDD
        remBtn.TextColor3 = C_WHT
        local playing = false
        playBtn.MouseButton1Click:Connect(
            function()
                if playing then
                    stopDesyncAnim()
                    playing = false
                    playBtn.Text = "Play"
                    return
                end
                if not selected or not savedDesyncAnimations[selected] then
                    return
                end
                local sp = tonumber(spdIn.Text) or 1
                if sp <= 0 then
                    sp = 1
                end
                playing = true
                playBtn.Text = "Stop"
                playDesyncAnim(selected, looped, sp, false)
            end
        )
        remBtn.MouseButton1Click:Connect(
            function()
                if selected then
                    savedDesyncAnimations[selected] = nil
                    saveDesyncAnims(savedDesyncAnimations)
                    selected = nil
                    ddBtn.Text = "Select Animation v"
                    updateDD()
                end
            end
        )
    end
    --// 4. ANIM MANAGER
    local function buildManagerTab(parent)
        local sf =
            create(
            "ScrollingFrame",
            {
                Parent = parent,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 4,
                CanvasSize = UDim2.new(0, 0, 0, 500)
            }
        )
        local inner = mkPanel(sf, UDim2.new(1, 0, 0, 500))
        local cat, sub, search = "R6", "[Main]", ""
        local spd, looped, reversed, activeTrack = 1.0, false, false, nil
        local r6B = mkBtn(inner, "R6", UDim2.new(0.5, -6, 0, 26), UDim2.new(0, 10, 0, 8), F_B, 16, "no")
        local r15B = mkBtn(inner, "R15", UDim2.new(0.5, -6, 0, 26), UDim2.new(0.5, 2, 0, 8), F_B, 16, "no")
        local subDD = mkBtn(inner, "Category: [Main] v", UDim2.new(1, -95, 0, 24), UDim2.new(0, 10, 0, 40), F_R, 14)
        local subList = mkListBG(inner, UDim2.new(1, -20, 0, 80), UDim2.new(0, 10, 0, 66))
        subList.ZIndex = 10
        subList.Visible = false
        local subListLayout = create("UIListLayout", {Parent = subList})
        subListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(
            function()
                subList.CanvasSize = UDim2.new(0, 0, 0, subListLayout.AbsoluteContentSize.Y + 4)
            end
        )
        local delSub = mkBtn(inner, "Del Sub", UDim2.new(0, 70, 0, 24), UDim2.new(1, -80, 0, 40), F_B, 12, "no")
        delSub.BackgroundColor3 = C_REDD
        delSub.TextColor3 = C_WHT
        delSub.Visible = false
        local newSub = mkBox(inner, "", UDim2.new(1, -90, 0, 22), UDim2.new(0, 10, 0, 70), 14)
        newSub.PlaceholderText = "New subcategory..."
        local addSub = mkBtn(inner, "Add", UDim2.new(0, 70, 0, 22), UDim2.new(1, -80, 0, 70), F_B, 14)
        local searchB = mkBox(inner, "", UDim2.new(1, -20, 0, 24), UDim2.new(0, 10, 0, 100), 14)
        searchB.PlaceholderText = "Search..."
        local list = mkListBG(inner, UDim2.new(1, -20, 0, 200), UDim2.new(0, 10, 0, 130))
        create("UIListLayout", {Parent = list, Padding = UDim.new(0, 2)})
        local nameIn = mkBox(inner, "", UDim2.new(0.5, -12, 0, 24), UDim2.new(0, 10, 0, 340), 14)
        nameIn.PlaceholderText = "Animation Name"
        local idIn = mkBox(inner, "", UDim2.new(0.5, -12, 0, 24), UDim2.new(0.5, 2, 0, 340), 14)
        idIn.PlaceholderText = "Animation ID"
        local setP = mkPanel(inner, UDim2.new(1, -20, 0, 50), UDim2.new(0, 10, 0, 370))
        mkLabel(setP, "Speed:", UDim2.new(0, 45, 0, 20), UDim2.new(0, 8, 0, 4), F_S, 14)
        local spdIn = mkBox(setP, "1.0", UDim2.new(0, 40, 0, 18), UDim2.new(0, 55, 0, 5), 14)
        spdIn.FocusLost:Connect(
            function()
                spd = tonumber(spdIn.Text) or 1
                if activeTrack and activeTrack.IsPlaying then
                    activeTrack:AdjustSpeed(spd * (reversed and -1 or 1))
                end
            end
        )
        local loopB = mkBtn(setP, "Loop: OFF", UDim2.new(0, 80, 0, 20), UDim2.new(0, 110, 0, 4), F_B, 13, false)
        loopB.TextColor3 = C_ROFF
        loopB.MouseButton1Click:Connect(
            function()
                looped = not looped
                loopB.Text = looped and "Loop: ON" or "Loop: OFF"
                loopB.TextColor3 = looped and C_GRN or C_ROFF
                if activeTrack then
                    activeTrack.Looped = looped
                end
            end
        )
        local revB = mkBtn(setP, "Reverse: OFF", UDim2.new(0, 95, 0, 20), UDim2.new(1, -103, 0, 4), F_B, 13, false)
        revB.TextColor3 = C_ROFF
        revB.MouseButton1Click:Connect(
            function()
                reversed = not reversed
                revB.Text = reversed and "Reverse: ON" or "Reverse: OFF"
                revB.TextColor3 = reversed and C_GRN or C_ROFF
                if activeTrack and activeTrack.IsPlaying then
                    activeTrack:AdjustSpeed(spd * (reversed and -1 or 1))
                end
            end
        )
        mkLabel(
            setP,
            "*Reverse changes direction on play/live adjust",
            UDim2.new(1, -16, 0, 16),
            UDim2.new(0, 8, 0, 28),
            F_I,
            12
        )
        local addAnim = mkBtn(inner, "Add Anim", UDim2.new(0.5, -12, 0, 30), UDim2.new(0, 10, 0, 430), F_B, 16)
        local stopAnim = mkBtn(inner, "Stop Playing", UDim2.new(0.5, -12, 0, 30), UDim2.new(0.5, 2, 0, 430), F_B, 16)
        local updateList, updateSubDD
        updateList = function()
            for _, ch in ipairs(list:GetChildren()) do
                if ch:IsA("Frame") then
                    ch:Destroy()
                end
            end
            local data = managerDataCache[cat]
            local target = (sub == "[Main]") and data or data._subcategories[sub]
            delSub.Visible = (sub ~= "[Main]")
            if not target then
                return
            end
            local c = 0
            for name, id in pairs(target) do
                if
                    name ~= "_subcategories" and
                        (search == "" or string.find(string.lower(name), string.lower(search), 1, true))
                 then
                    c = c + 1
                    local row =
                        create("Frame", {Parent = list, Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1})
                    local pb = mkBtn(row, "▶ " .. name, UDim2.new(1, -30, 1, 0), UDim2.new(0, 0, 0, 0), F_R, 14)
                    pb.TextXAlignment = Enum.TextXAlignment.Left
                    local db = mkBtn(row, "X", UDim2.new(0, 26, 1, 0), UDim2.new(1, -26, 0, 0), F_B, 12, "no")
                    db.BackgroundColor3 = C_REDD
                    db.TextColor3 = C_WHT
                    pb.MouseButton1Click:Connect(
                        function()
                            if activeTrack then
                                activeTrack:Stop()
                            end
                            if desyncChar and desyncChar:FindFirstChildOfClass("Humanoid") then
                                local clean = string.match(tostring(id), "%d+") or id
                                local a = Instance.new("Animation")
                                a.AnimationId = "rbxassetid://" .. clean
                                local hum = desyncChar:FindFirstChildOfClass("Humanoid")
                                local an = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
                                local ok, tr =
                                    pcall(
                                    function()
                                        return an:LoadAnimation(a)
                                    end
                                )
                                if ok and tr then
                                    activeTrack = tr
                                    tr.Looped = looped
                                    tr:Play()
                                    tr:AdjustSpeed(spd * (reversed and -1 or 1))
                                    if reversed then
                                        tr.TimePosition = tr.Length > 0 and tr.Length or 0.1
                                    end
                                end
                            end
                        end
                    )
                    db.MouseButton1Click:Connect(
                        function()
                            target[name] = nil
                            saveMgr(cat, data)
                            updateList()
                        end
                    )
                end
            end
            list.CanvasSize = UDim2.new(0, 0, 0, c * 28)
        end
        searchB:GetPropertyChangedSignal("Text"):Connect(
            function()
                search = searchB.Text
                updateList()
            end
        )
        updateSubDD = function()
            for _, ch in ipairs(subList:GetChildren()) do
                if ch:IsA("TextButton") then
                    ch:Destroy()
                end
            end
            local count = 0
            local function item(t)
                local b = mkBtn(subList, t, UDim2.new(1, 0, 0, 22), UDim2.new(0, 0, 0, 0), F_R, 14)
                b.ZIndex = 11
                b.MouseButton1Click:Connect(
                    function()
                        sub = t
                        subDD.Text = "Category: " .. t .. " v"
                        subList.Visible = false
                        updateList()
                    end
                )
                count = count + 1
            end
            item("[Main]")
            for sn, _ in pairs(managerDataCache[cat]._subcategories or {}) do
                item(sn)
            end
            subList.Size = UDim2.new(1, -20, 0, math.clamp(count * 22 + 4, 44, 176))
        end
        local function selectCat(c2)
            cat = c2
            sub = "[Main]"
            subDD.Text = "Category: [Main] v"
            if c2 == "R6" then
                r6B.BackgroundColor3 = uiColor_ButtonColor
                r6B.TextColor3 = Color3.fromRGB(255, 255, 255)
                r15B.BackgroundColor3 = darker(uiColor_ButtonColor, 15)
                r15B.TextColor3 = uiColor_TextColor
            else
                r15B.BackgroundColor3 = uiColor_ButtonColor
                r15B.TextColor3 = Color3.fromRGB(255, 255, 255)
                r6B.BackgroundColor3 = darker(uiColor_ButtonColor, 15)
                r6B.TextColor3 = uiColor_TextColor
            end
            managerDataCache[c2] = loadMgr(c2)
            updateSubDD()
            updateList()
        end
        r6B.MouseButton1Click:Connect(
            function()
                selectCat("R6")
            end
        )
        r15B.MouseButton1Click:Connect(
            function()
                selectCat("R15")
            end
        )
        subDD.MouseButton1Click:Connect(
            function()
                subList.Visible = not subList.Visible
            end
        )
        delSub.MouseButton1Click:Connect(
            function()
                if sub ~= "[Main]" then
                    local d = managerDataCache[cat]
                    d._subcategories[sub] = nil
                    saveMgr(cat, d)
                    sub = "[Main]"
                    subDD.Text = "Category: [Main] v"
                    updateSubDD()
                    updateList()
                end
            end
        )
        addSub.MouseButton1Click:Connect(
            function()
                local sn = newSub.Text
                if sn ~= "" and sn ~= "[Main]" then
                    local d = managerDataCache[cat]
                    if not d._subcategories[sn] then
                        d._subcategories[sn] = {}
                        saveMgr(cat, d)
                        newSub.Text = ""
                        updateSubDD()
                    end
                end
            end
        )
        addAnim.MouseButton1Click:Connect(
            function()
                local n, id = nameIn.Text, idIn.Text
                if n ~= "" and id ~= "" then
                    local clean = string.match(id, "%d+") or id
                    local d = managerDataCache[cat]
                    if sub == "[Main]" then
                        d[n] = clean
                    else
                        d._subcategories[sub][n] = clean
                    end
                    saveMgr(cat, d)
                    nameIn.Text = ""
                    idIn.Text = ""
                    updateList()
                end
            end
        )
        stopAnim.MouseButton1Click:Connect(
            function()
                if activeTrack then
                    activeTrack:Stop()
                    activeTrack = nil
                end
            end
        )
        selectCat("R6")
    end
    --// 5. KEYBINDS
    local function buildKeybindsTab(parent)
        local sf =
            create(
            "ScrollingFrame",
            {
                Parent = parent,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 4,
                CanvasSize = UDim2.new(0, 0, 0, 400)
            }
        )
        local inner = mkPanel(sf, UDim2.new(1, 0, 0, 400))
        local curType, curAnimType, curBody = "Animations", "Desync", "R6"
        local selDesync, selNormal, tempDesync, tempNormal = nil, nil, nil, nil
        mkLabel(inner, "Category:", UDim2.new(0, 80, 0, 20), UDim2.new(0, 12, 0, 10), F_S, 16)
        local typeDD = mkBtn(inner, curType .. " v", UDim2.new(0, 150, 0, 24), UDim2.new(0, 100, 0, 8), F_R, 16)
        local typeList = mkListBG(inner, UDim2.new(0, 150, 0, 100), UDim2.new(0, 100, 0, 32))
        typeList.ZIndex = 15
        typeList.Visible = false -- FIX: закрыт при первом входе
        create("UIListLayout", {Parent = typeList})
        local refresh
        for _, cn in ipairs({"Animations", "Desync", "Menu", "View all keybinds"}) do
            local b = mkBtn(typeList, cn, UDim2.new(1, 0, 0, 22), UDim2.new(0, 0, 0, 0), F_R, 14)
            b.ZIndex = 16
            b.MouseButton1Click:Connect(
                function()
                    curType = cn
                    typeDD.Text = cn .. " v"
                    typeList.Visible = false
                    refresh()
                end
            )
        end
        typeDD.MouseButton1Click:Connect(
            function()
                typeList.Visible = not typeList.Visible
            end
        )
        local function bindRow(y, getTemp, setTemp, onSave)
            local bindB =
                mkBtn(
                inner,
                "Bind: " .. (getTemp() or "None"),
                UDim2.new(0, 120, 0, 28),
                UDim2.new(0, 12, 0, y),
                F_B,
                14
            )
            local saveB = mkBtn(inner, "Save Bind", UDim2.new(0, 100, 0, 28), UDim2.new(0, 140, 0, y), F_B, 14)
            bindB.MouseButton1Click:Connect(
                function()
                    keybindWaitForInput = true
                    bindB.Text = "Press any key..."
                    onKeybindPressed = function(k)
                        keybindWaitForInput = false
                        if k then
                            bindB.Text = "Bind: " .. k
                            setTemp(k)
                        else
                            bindB.Text = "Bind: None"
                            setTemp(nil)
                        end
                        onKeybindPressed = nil
                    end
                end
            )
            saveB.MouseButton1Click:Connect(
                function()
                    if onSave(saveB) then
                        setTemp(nil)
                        bindB.Text = "Bind: None"
                    end
                end
            )
            return bindB, saveB
        end
        refresh = function()
            for _, ch in ipairs(inner:GetChildren()) do
                if ch ~= typeDD and ch ~= typeList then
                    ch:Destroy()
                end
            end
            mkLabel(inner, "Category:", UDim2.new(0, 80, 0, 20), UDim2.new(0, 12, 0, 10), F_S, 16)
            local y = 40
            if curType == "Animations" then
                local selLbl = nil
                local sBox = nil
                local updateDL = nil

                mkLabel(inner, "Animation type:", UDim2.new(0, 120, 0, 20), UDim2.new(0, 12, 0, y), F_S, 16)
                local atDD =
                    mkBtn(inner, curAnimType .. " v", UDim2.new(0, 120, 0, 24), UDim2.new(0, 140, 0, y - 2), F_R, 16)
                local atList = mkListBG(inner, UDim2.new(0, 120, 0, 50), UDim2.new(0, 140, 0, y + 24))
                atList.ZIndex = 10
                atList.Visible = false -- FIX: после refresh() не должен торчать открытым
                create("UIListLayout", {Parent = atList})
                for _, t in ipairs({"Desync", "Normal"}) do
                    local b = mkBtn(atList, t, UDim2.new(1, 0, 0, 22), UDim2.new(0, 0, 0, 0), F_R, 14)
                    b.ZIndex = 11
                    b.MouseButton1Click:Connect(
                        function()
                            curAnimType = t
                            atDD.Text = t .. " v"
                            atList.Visible = false
                            refresh()
                        end
                    )
                end
                atDD.MouseButton1Click:Connect(
                    function()
                        atList.Visible = not atList.Visible
                    end
                )
                y = y + 32

                --// FIX: Body type — отдельной строкой сразу после Animation type, тот же layout
                if curAnimType == "Normal" then
                    mkLabel(inner, "Body type:", UDim2.new(0, 120, 0, 20), UDim2.new(0, 12, 0, y), F_S, 16)
                    local btDD =
                        mkBtn(inner, curBody .. " v", UDim2.new(0, 120, 0, 24), UDim2.new(0, 140, 0, y - 2), F_R, 16)
                    local btList = mkListBG(inner, UDim2.new(0, 120, 0, 50), UDim2.new(0, 140, 0, y + 24))
                    btList.ZIndex = 10
                    btList.Visible = false -- FIX
                    create("UIListLayout", {Parent = btList})
                    for _, t in ipairs({"R6", "R15"}) do
                        local b = mkBtn(btList, t, UDim2.new(1, 0, 0, 22), UDim2.new(0, 0, 0, 0), F_R, 14)
                        b.ZIndex = 11
                        b.MouseButton1Click:Connect(
                            function()
                                curBody = t
                                btDD.Text = t .. " v"
                                btList.Visible = false
                                selNormal = nil
                                if selLbl then
                                    selLbl.Text = "Selected: none"
                                end
                                if updateDL and sBox then
                                    updateDL(sBox.Text)
                                end
                            end
                        )
                    end
                    btDD.MouseButton1Click:Connect(
                        function()
                            btList.Visible = not btList.Visible
                        end
                    )
                    y = y + 32
                end

                sBox = mkBox(inner, "", UDim2.new(1, -24, 0, 24), UDim2.new(0, 12, 0, y), 14)
                sBox.PlaceholderText = "Search animation..."
                y = y + 28
                local aList = mkListBG(inner, UDim2.new(1, -24, 0, 90), UDim2.new(0, 12, 0, y))
                create("UIListLayout", {Parent = aList, Padding = UDim.new(0, 2)})
                updateDL = function(filter)
                    for _, ch in ipairs(aList:GetChildren()) do
                        if ch:IsA("TextButton") then
                            ch:Destroy()
                        end
                    end
                    local c = 0
                    local pool = {}
                    if curAnimType == "Desync" then
                        for n, d in pairs(savedDesyncAnimations) do
                            if d.frames then
                                pool[n] = true
                            end
                        end
                    else
                        local data = managerDataCache[curBody] or {}
                        for n, _ in pairs(data) do
                            if n ~= "_subcategories" then
                                pool[n] = true
                            end
                        end
                        for _, st in pairs(data._subcategories or {}) do
                            for n, _ in pairs(st) do
                                pool[n] = true
                            end
                        end
                    end
                    for n, _ in pairs(pool) do
                        if filter == "" or string.find(string.lower(n), string.lower(filter), 1, true) then
                            c = c + 1
                            local isSel =
                                (curAnimType == "Desync" and selDesync == n) or
                                (curAnimType ~= "Desync" and selNormal == n)
                            local b =
                                create(
                                "TextButton",
                                {
                                    Parent = aList,
                                    Size = UDim2.new(1, 0, 0, 22),
                                    BackgroundColor3 = isSel and lighter(uiColor_ButtonColor, 40) or uiColor_ButtonColor,
                                    TextColor3 = uiColor_TextColor,
                                    Text = n,
                                    Font = F_R,
                                    TextSize = 13,
                                    BorderSizePixel = 0
                                }
                            )
                            corner(b)
                            trackOpacity(b) -- FIX: прозрачность как у остальных кнопок темы
                            b.TextXAlignment = Enum.TextXAlignment.Left
                            b.MouseButton1Click:Connect(
                                function()
                                    if curAnimType == "Desync" then
                                        selDesync = n
                                    else
                                        selNormal = n
                                    end
                                    updateDL(sBox.Text)
                                    if selLbl then
                                        selLbl.Text = "Selected: " .. n
                                    end
                                end
                            )
                        end
                    end
                    aList.CanvasSize = UDim2.new(0, 0, 0, c * 24)
                end
                sBox:GetPropertyChangedSignal("Text"):Connect(
                    function()
                        updateDL(sBox.Text)
                    end
                )
                selLbl =
                    mkLabel(inner, "Selected: none", UDim2.new(1, -24, 0, 20), UDim2.new(0, 12, 0, y + 95), F_S, 14)
                y = y + 120
                if curAnimType == "Desync" then
                    bindRow(
                        y,
                        function()
                            return tempDesync
                        end,
                        function(v)
                            tempDesync = v
                        end,
                        function(saveB)
                            if tempDesync and selDesync then
                                keybinds.Animations = keybinds.Animations or {}
                                table.insert(
                                    keybinds.Animations,
                                    {
                                        key = tempDesync,
                                        type = "Desync",
                                        animName = selDesync,
                                        speed = 1,
                                        looped = false,
                                        reversed = false
                                    }
                                )
                                saveKeys(keybinds)
                                saveB.Text = "Saved!"
                                task.wait(0.5)
                                saveB.Text = "Save Bind"
                                return true
                            else
                                saveB.Text = "Error: Key & Anim"
                                task.wait(1)
                                saveB.Text = "Save Bind"
                                return false
                            end
                        end
                    )
                else
                    bindRow(
                        y,
                        function()
                            return tempNormal
                        end,
                        function(v)
                            tempNormal = v
                        end,
                        function(saveB)
                            if tempNormal and selNormal then
                                keybinds.Animations = keybinds.Animations or {}
                                table.insert(
                                    keybinds.Animations,
                                    {
                                        key = tempNormal,
                                        type = "Normal",
                                        animName = selNormal,
                                        bodyType = curBody,
                                        speed = 1,
                                        looped = false,
                                        reversed = false
                                    }
                                )
                                saveKeys(keybinds)
                                saveB.Text = "Saved!"
                                task.wait(0.5)
                                saveB.Text = "Save Bind"
                                return true
                            else
                                saveB.Text = "Error: Key & Anim"
                                task.wait(1)
                                saveB.Text = "Save Bind"
                                return false
                            end
                        end
                    )
                end
                updateDL("")
            elseif curType == "Desync" or curType == "Menu" then
                mkLabel(
                    inner,
                    curType == "Desync" and "Toggle Desync mode" or "Show/Hide Main Menu",
                    UDim2.new(1, -24, 0, 20),
                    UDim2.new(0, 12, 0, y),
                    F_S,
                    16
                )
                y = y + 28
                local curKey =
                    (curType == "Desync") and (keybinds.Desync and keybinds.Desync.key) or
                    (keybinds.Menu and keybinds.Menu.key)
                local bindB =
                    mkBtn(
                    inner,
                    "Bind: " .. (curKey or "None"),
                    UDim2.new(0, 120, 0, 28),
                    UDim2.new(0, 12, 0, y),
                    F_B,
                    14
                )
                local saveB = mkBtn(inner, "Save Bind", UDim2.new(0, 100, 0, 28), UDim2.new(0, 140, 0, y), F_B, 14)
                bindB.MouseButton1Click:Connect(
                    function()
                        keybindWaitForInput = true
                        bindB.Text = "Press any key..."
                        onKeybindPressed = function(k)
                            keybindWaitForInput = false
                            if k then
                                bindB.Text = "Bind: " .. k
                                if curType == "Desync" then
                                    keybinds.Desync = keybinds.Desync or {}
                                    keybinds.Desync.key = k
                                else
                                    keybinds.Menu = keybinds.Menu or {}
                                    keybinds.Menu.key = k
                                end
                            else
                                bindB.Text = "Bind: None"
                            end
                            onKeybindPressed = nil
                        end
                    end
                )
                saveB.MouseButton1Click:Connect(
                    function()
                        saveKeys(keybinds)
                        saveB.Text = "Saved!"
                        task.wait(0.5)
                        saveB.Text = "Save Bind"
                    end
                )
            elseif curType == "View all keybinds" then
                mkLabel(inner, "Assigned Keybinds:", UDim2.new(1, -24, 0, 20), UDim2.new(0, 12, 0, y), F_S, 16)
                y = y + 24
                local scroll = mkListBG(inner, UDim2.new(1, -24, 0, 280), UDim2.new(0, 12, 0, y))
                create("UIListLayout", {Parent = scroll, Padding = UDim.new(0, 4)})
                local all = {}
                if keybinds.Desync and keybinds.Desync.key then
                    table.insert(
                        all,
                        {type = "Desync", key = keybinds.Desync.key, path = {"Desync"}, data = keybinds.Desync}
                    )
                end
                if keybinds.Menu and keybinds.Menu.key then
                    table.insert(all, {type = "Menu", key = keybinds.Menu.key, path = {"Menu"}, data = keybinds.Menu})
                end
                for i, b in ipairs(keybinds.Animations or {}) do
                    if b.key then
                        table.insert(
                            all,
                            {
                                type = "Anim " .. b.type,
                                key = b.key,
                                animName = b.animName,
                                bodyType = b.bodyType,
                                path = {"Animations", i},
                                data = b
                            }
                        )
                    end
                end
                local th = 0
                for _, kb in ipairs(all) do
                    local rh = kb.type:find("Anim") and 46 or 24
                    local row =
                        create(
                        "Frame",
                        {
                            Parent = scroll,
                            Size = UDim2.new(1, -10, 0, rh),
                            BackgroundColor3 = uiColor_ButtonColor,
                            BorderSizePixel = 0
                        }
                    )
                    table.insert(themeElements.Buttons, row)
                    corner(row)
                    local desc = string.format("%s [%s]", kb.type, kb.key)
                    if kb.animName then
                        desc = desc .. " -> " .. kb.animName .. (kb.bodyType and (" (" .. kb.bodyType .. ")") or "")
                    end
                    local dl = mkLabel(row, desc, UDim2.new(1, -60, 0, 20), UDim2.new(0, 5, 0, 2), F_R, 14)
                    dl.TextTruncate = Enum.TextTruncate.AtEnd
                    local del = mkBtn(row, "Delete", UDim2.new(0, 50, 0, 18), UDim2.new(1, -55, 0, 3), F_B, 12, "no")
                    del.BackgroundColor3 = C_REDD
                    del.TextColor3 = C_WHT
                    del.MouseButton1Click:Connect(
                        function()
                            local t = keybinds
                            for i = 1, #kb.path - 1 do
                                t = t[kb.path[i]]
                            end
                            local lk = kb.path[#kb.path]
                            if type(lk) == "number" then
                                table.remove(t, lk)
                            else
                                t[lk] = nil
                            end
                            saveKeys(keybinds)
                            refresh()
                        end
                    )
                    if kb.type:find("Anim") then
                        mkLabel(row, "Spd:", UDim2.new(0, 30, 0, 18), UDim2.new(0, 5, 0, 24), F_R, 12)
                        local si =
                            mkBox(
                            row,
                            tostring(kb.data.speed or 1),
                            UDim2.new(0, 35, 0, 18),
                            UDim2.new(0, 35, 0, 24),
                            12
                        )
                        si.FocusLost:Connect(
                            function()
                                local v = tonumber(si.Text)
                                if v then
                                    kb.data.speed = v
                                    saveKeys(keybinds)
                                end
                            end
                        )
                        local lb = mkBtn(row, "Loop", UDim2.new(0, 45, 0, 18), UDim2.new(0, 75, 0, 24), F_B, 12, false)
                        local ls = kb.data.looped or false
                        lb.TextColor3 = ls and C_GRN or C_ROFF
                        lb.MouseButton1Click:Connect(
                            function()
                                ls = not ls
                                kb.data.looped = ls
                                lb.TextColor3 = ls and C_GRN or C_ROFF
                                saveKeys(keybinds)
                            end
                        )
                        local rb = mkBtn(row, "Rev", UDim2.new(0, 45, 0, 18), UDim2.new(0, 125, 0, 24), F_B, 12, false)
                        local rs = kb.data.reversed or false
                        rb.TextColor3 = rs and C_GRN or C_ROFF
                        rb.MouseButton1Click:Connect(
                            function()
                                rs = not rs
                                kb.data.reversed = rs
                                rb.TextColor3 = rs and C_GRN or C_ROFF
                                saveKeys(keybinds)
                            end
                        )
                    end
                    th = th + rh + 4
                end
                scroll.CanvasSize = UDim2.new(0, 0, 0, th)
            end
        end
        refresh()
    end
    --// 6. ANIM LOGGER
    local loggedAnims = {}
    local refreshLoggerList = nil
    local function trackAnimator(an)
        an.AnimationPlayed:Connect(
            function(tr)
                if not isRunning then
                    return
                end
                if not DesyncSectionEnabled then
                    return
                end
                local id, nm = nil, nil
                pcall(
                    function()
                        id = tr.Animation.AnimationId
                    end
                )
                pcall(
                    function()
                        nm = tr.Animation.Name
                    end
                )
                if not id or id == "" then
                    return
                end
                for _, e in ipairs(loggedAnims) do
                    if e.id == id then
                        return
                    end
                end
                table.insert(loggedAnims, 1, {id = id, name = (nm and nm ~= "") and nm or "Unknown"})
                while #loggedAnims > 20 do
                    table.remove(loggedAnims)
                end
                if refreshLoggerList then
                    refreshLoggerList()
                end
            end
        )
    end
    local function buildLoggerTab(parent)
        local sf =
            create(
            "ScrollingFrame",
            {
                Parent = parent,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 4,
                CanvasSize = UDim2.new(0, 0, 0, 300)
            }
        )
        local inner = mkPanel(sf, UDim2.new(1, 0, 0, 300))
        mkLabel(inner, "Anim Logger (click to copy link):", UDim2.new(1, -24, 0, 20), UDim2.new(0, 12, 0, 8), F_S, 16)
        local list = mkListBG(inner, UDim2.new(1, -24, 1, -40), UDim2.new(0, 12, 0, 34))
        local lay = create("UIListLayout", {Parent = list, Padding = UDim.new(0, 2)})
        lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(
            function()
                list.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 4)
            end
        )
        refreshLoggerList = function()
            for _, ch in ipairs(list:GetChildren()) do
                if ch:IsA("TextButton") then
                    ch:Destroy()
                end
            end
            for _, e in ipairs(loggedAnims) do
                local b = mkBtn(list, e.id .. " - " .. e.name, UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 0), F_R, 12)
                b.TextXAlignment = Enum.TextXAlignment.Left
                b.TextTruncate = Enum.TextTruncate.AtEnd
                b.MouseButton1Click:Connect(
                    function()
                        if setclipboard then
                            setclipboard(e.id)
                        end
                        notify("Anim Logger", "Copied: " .. e.id)
                    end
                )
            end
        end
        refreshLoggerList()
    end
    --// Регистрация в боковом меню
    local desyncTabs = {}
    local function addDesyncTab(name, builder)
        local frame =
            create(
            "Frame",
            {
                Name = "Tab" .. name,
                Parent = Containment,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Visible = false
            }
        )
        builder(frame)
        local btn =
            create(
            "TextButton",
            {
                Name = "DBtn_" .. name,
                Parent = MenuInsided,
                Size = UDim2.new(1, 0, 0, 40),
                LayoutOrder = 100 + #desyncTabs,
                Visible = false,
                BackgroundColor3 = uiColor_ButtonColor,
                BorderColor3 = COL_BORDER,
                TextColor3 = uiColor_TextColor,
                Text = name,
                Font = FONT,
                TextSize = 12,
                TextWrapped = true
            }
        )
        local entry = {Frame = frame, Name = name, Button = btn}
        table.insert(desyncTabs, entry)
        table.insert(themeElements.Buttons, btn)
        table.insert(themeElements.Texts, btn)
        return entry
    end
    addDesyncTab("Desync", buildDesyncTab)
    addDesyncTab("Desync Anim Editor", buildEditorTab)
    addDesyncTab("Desync Animations", buildDesyncAnimsTab)
    addDesyncTab("Anim Manager", buildManagerTab)
    addDesyncTab("Keybinds", buildKeybindsTab)
    addDesyncTab("Anim Logger", buildLoggerTab)
    local baseUpdateTabTheme = updateTabButtonsTheme
    updateTabButtonsTheme = function()
        baseUpdateTabTheme()
        for _, tab in ipairs(desyncTabs) do
            if tab.Button then
                if tab.Frame.Visible then
                    tab.Button.BackgroundColor3 = uiColor_ButtonColor
                    tab.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
                else
                    tab.Button.BackgroundColor3 = darker(uiColor_ButtonColor, 10)
                    tab.Button.TextColor3 = uiColor_TextColor
                end
            end
        end
    end
    --// FIX: прозрачность динамических элементов при смене Gui Opacity
    local baseApplyThemeDesync = applyTheme
    applyTheme = function()
        baseApplyThemeDesync()
        local trans = 1 - uiGuiOpacity
        local alive = {}
        for _, el in ipairs(dynamicOpacity) do
            if el.Parent then
                el.BackgroundTransparency = trans
                table.insert(alive, el)
            end
        end
        dynamicOpacity = alive
    end
    local function onChar(char)
        desyncChar = char
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            if CharDeathConn then
                CharDeathConn:Disconnect()
            end
            CharDeathConn = hum.Died:Connect(stopDesync)
        end
        if IsDesynced then
            stopDesync()
            task.wait(0.15)
            startDesync()
        end
        local h2 = char:WaitForChild("Humanoid", 10)
        if h2 then
            local an = h2:WaitForChild("Animator", 10)
            if an then
                trackAnimator(an)
            end
        end
    end
    LocalPlayer.CharacterAdded:Connect(onChar)
    if LocalPlayer.Character then
        onChar(LocalPlayer.Character)
    end
    task.defer(
        function()
            local function hideAllFrames()
                for _, t in ipairs(tabs) do
                    t.Frame.Visible = false
                end
                for _, t in ipairs(desyncTabs) do
                    t.Frame.Visible = false
                end
            end
            local function showMainButtons()
                for _, t in ipairs(tabs) do
                    if t.Button then
                        t.Button.Visible = true
                    end
                end
                for _, t in ipairs(desyncTabs) do
                    t.Button.Visible = false
                end
            end
            local function showDesyncButtons()
                for _, t in ipairs(tabs) do
                    if t.Button then
                        t.Button.Visible = false
                    end
                end
                for _, t in ipairs(desyncTabs) do
                    t.Button.Visible = true
                end
            end
            for _, t in ipairs(desyncTabs) do
                t.Button.MouseButton1Click:Connect(
                    function()
                        hideAllFrames()
                        t.Frame.Visible = true
                        updateTabButtonsTheme()
                    end
                )
            end
            for _, t in ipairs(tabs) do
                if t.Button then
                    t.Button.MouseButton1Click:Connect(
                        function()
                            for _, d in ipairs(desyncTabs) do
                                d.Frame.Visible = false
                            end
                            updateTabButtonsTheme()
                        end
                    )
                end
            end
            EmilyUi.MouseButton1Click:Connect(
                function()
                    showMainButtons()
                    hideAllFrames()
                    if tabs[1] then
                        tabs[1].Frame.Visible = true
                    end
                    updateTabButtonsTheme()
                end
            )
            Desync.MouseButton1Click:Connect(
                function()
                    showDesyncButtons()
                    hideAllFrames()
                    if desyncTabs[1] then
                        desyncTabs[1].Frame.Visible = true
                    end
                    updateTabButtonsTheme()
                end
            )
        end
    )

    local DesyncSidebarToggle = create("TextButton", {
		Name = "MToggle_Desync", Parent = MenuInsided,
		Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 190, Visible = false,
		BorderColor3 = COL_BORDER, Text = "Desync: OFF", Font = FONT, TextSize = 12, TextWrapped = true,
		BackgroundTransparency = 1 - uiGuiOpacity,
	})
	table.insert(themeElements.CustomButtons, DesyncSidebarToggle)
	table.insert(moduleToggles, {btn = DesyncSidebarToggle, group = "Desync"})
	registerToggle(DesyncSidebarToggle, function() return DesyncSectionEnabled end)
	local function refreshDesyncToggleText()
		DesyncSidebarToggle.Text = "Desync: " .. (DesyncSectionEnabled and "ON" or "OFF")
		paintToggleBtn(DesyncSidebarToggle, DesyncSectionEnabled)
	end
	refreshDesyncToggleText()
	DesyncSidebarToggle.MouseButton1Click:Connect(function()
		DesyncSectionEnabled = not DesyncSectionEnabled
		if not DesyncSectionEnabled then
			if IsDesynced then stopDesync() end
			stopDesyncAnim()
			stopNormAnim()
		end
		refreshDesyncToggleText()
	end)

    ScreenGui.Destroying:Connect(function()
        pcall(function()
            DesyncSectionEnabled = false

            if IsDesynced then
                stopDesync()
            end

            stopDesyncAnim()
            stopNormAnim()
        end)
    end)

    registerKeyListProvider("Desync", function()
	    local rows = {}
	    if not DesyncSectionEnabled then return rows end
	    if IsDesynced then table.insert(rows, {"DESYNC", "ON"}) end
	    if curDesyncPlaying and curDesyncName then table.insert(rows, {"DESYNC ANIM", curDesyncName}) end
	    if curNormTrack and curNormName and curNormTrack.IsPlaying then table.insert(rows, {"ANIM MANAGER", curNormName}) end
	    return rows
    end)

    return desyncTabs, keybinds
end
local desyncTabs, DesyncKeybinds = initDesyncModule()
Core.DesyncTabs=desyncTabs
Core.DesyncKeybinds=DesyncKeybinds

Core.RegisterModule("Desync",Desync,Core.DesyncTabs,Core.DesyncTabs and Core.DesyncTabs[1])
