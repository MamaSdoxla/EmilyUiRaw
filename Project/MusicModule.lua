-- ============================================================
-- MusicModule.lua
-- ============================================================
-- Модуль Music: плеер, библиотека, визуализация, grabber.
-- Использует FuckYouLib.
-- ============================================================

local FuckYouLib = _G.FuckYouLib
if not FuckYouLib then error("FuckYouLibrary not loaded") end

local COL_BORDER = FuckYouLib.COL_BORDER
local FONT = FuckYouLib.FONT

local SoundService = game:GetService("SoundService")
local F_R = FONT
local F_B = FONT
local F_S = FONT

local FOLDER = "EmilyUi/Music"
local FILE_MUSIC = FOLDER .. "/EmilyUiMusic.json"
local FILE_SETTINGS = FOLDER .. "/EmilyUiMusicSettings.json"
local FILE_GRABBER = FOLDER .. "/EmilyUiMusicGrabber.json"
local FILE_BLACKLIST = FOLDER .. "/EmilyUiMusicGrabberBlackList.json"

local function ensureDirs()
    if makefolder then pcall(function()
        if not isfolder("EmilyUi") then makefolder("EmilyUi") end
        if not isfolder(FOLDER) then makefolder(FOLDER) end
    end) end
end
local function saveJson(path, data)
    if writefile then ensureDirs()
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
    StaticColor = Color3.new(1,1,1), Transparency = 0
}
local DataStructure = { Categories = { ["Default"] = {} } }
local grabbedIds = {}
local blacklistedIds = {}

local function saveSettings()
    saveJson(FILE_SETTINGS, {
        Body = Settings.Body, Angle = Settings.Angle, Goal = Settings.Goal,
        Split = Settings.Split, Parts = Settings.Parts, Disposition = Settings.Disposition,
        Power = Settings.Power, Material = Settings.Material, Rainbow = Settings.Rainbow,
        Transparency = Settings.Transparency,
        StaticColor = {Settings.StaticColor.R*255, Settings.StaticColor.G*255, Settings.StaticColor.B*255}
    })
end
local function loadSettings()
    local d = loadJson(FILE_SETTINGS)
    if not d then return end
    Settings.Body = d.Body or Settings.Body
    Settings.Angle = d.Angle or Settings.Angle
    Settings.Goal = d.Goal or Settings.Goal
    Settings.Split = d.Split or Settings.Split
    Settings.Parts = d.Parts or Settings.Parts
    Settings.Disposition = d.Disposition or Settings.Disposition
    Settings.Power = d.Power or Settings.Power
    Settings.Material = d.Material or Settings.Material
    if d.Rainbow ~= nil then Settings.Rainbow = d.Rainbow end
    Settings.Transparency = d.Transparency or Settings.Transparency
    if d.StaticColor then Settings.StaticColor = Color3.fromRGB(d.StaticColor[1], d.StaticColor[2], d.StaticColor[3]) end
end
local function saveMusicData() saveJson(FILE_MUSIC, DataStructure) end
local function loadMusicData()
    local d = loadJson(FILE_MUSIC)
    if d and d.Categories then DataStructure = d else saveMusicData() end
end
local function saveGrabber() saveJson(FILE_GRABBER, grabbedIds) end
local function saveBlacklist()
    local arr = {}
    for id, _ in pairs(blacklistedIds) do table.insert(arr, id) end
    saveJson(FILE_BLACKLIST, arr)
end
local function loadGrabber()
    local d = loadJson(FILE_GRABBER); if d then grabbedIds = d end
    local b = loadJson(FILE_BLACKLIST)
    if b then for _, id in ipairs(b) do blacklistedIds[tonumber(id) or id] = true end end
end

loadMusicData(); loadSettings(); loadGrabber()

local C_BG = Color3.fromRGB(31,31,31)
local C_BORDER = Color3.fromRGB(60,60,60)
local C_TEXT = Color3.fromRGB(200,200,200)
local C_TEXT2 = Color3.fromRGB(220,220,220)
local C_SEL = Color3.fromRGB(50,50,80)
local C_GRN = Color3.fromRGB(100,220,100)
local C_RED = Color3.fromRGB(220,100,100)
local C_DARKGRN = Color3.fromRGB(40,70,40)
local C_DARKRED = Color3.fromRGB(70,40,40)
local C_DARKBLUE = Color3.fromRGB(40,55,70)

local function corner(p) Instance.new("UICorner", p).CornerRadius = UDim.new(0,4) end
local function lighter(c, amt)
    return Color3.fromRGB(math.min(c.R*255+amt,255), math.min(c.G*255+amt,255), math.min(c.B*255+amt,255))
end
local brokenIds = {}

local function mkPanel(p, sz, pos)
    local f = Instance.new("Frame")
    f.Parent = p; f.Size = sz; f.Position = pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3 = FuckYouLib.uiColor_SideBar
    f.BorderSizePixel = 0; f.ClipsDescendants = true
    table.insert(FuckYouLib.themeElements.SideBars, f)
    return f
end
local function mkBox(p, txt, sz, pos, ph, ts)
    local b = Instance.new("TextBox")
    b.Parent = p; b.Size = sz; b.Position = pos or UDim2.new(0,0,0,0)
    b.Font = F_R; b.TextSize = 13; b.Text = txt or ""
    b.PlaceholderText = ph or ""
    b.BackgroundColor3 = FuckYouLib.uiColor_TextBoxColor
    b.TextColor3 = FuckYouLib.uiColor_TextColor
    b.PlaceholderColor3 = Color3.fromRGB(90,90,90)
    b.BorderSizePixel = 0; b.ClearTextOnFocus = false
    table.insert(FuckYouLib.themeElements.TextBoxes, b)
    table.insert(FuckYouLib.themeElements.Texts, b)
    if p:IsA("GuiObject") and p.ZIndex > 1 then b.ZIndex = p.ZIndex + 1 end
    corner(b)
    return b
end
local function mkLabel(p, txt, sz, pos, font, ts, col, ta)
    local l = Instance.new("TextLabel")
    l.Parent = p; l.Size = sz; l.Position = pos or UDim2.new(0,0,0,0)
    l.Font = font or F_S; l.TextSize = 13
    l.Text = txt or ""; l.TextColor3 = col or FuckYouLib.uiColor_TextColor
    l.BackgroundTransparency = 1
    if ta then l.TextXAlignment = ta end
    table.insert(FuckYouLib.themeElements.Texts, l)
    if p:IsA("GuiObject") and p.ZIndex > 1 then l.ZIndex = p.ZIndex + 1 end
    return l
end
local function mkBtn(p, txt, sz, pos, font, ts, themed, bg, tc)
    local b = Instance.new("TextButton")
    b.Parent = p
    local hh = sz.Y.Offset
    if sz.Y.Scale == 0 and hh >= 24 and hh <= 34 then hh = 30 end
    b.Size = UDim2.new(sz.X.Scale, sz.X.Offset, sz.Y.Scale, hh)
    b.Position = pos or UDim2.new(0,0,0,0)
    b.Font = font or F_B; b.TextSize = 13
    b.Text = txt or ""; b.TextWrapped = true
    b.BackgroundColor3 = bg or FuckYouLib.uiColor_ButtonColor
    b.TextColor3 = tc or FuckYouLib.uiColor_TextColor
    b.BorderColor3 = C_BORDER; b.BorderSizePixel = 1
    if themed ~= "no" then
        table.insert(FuckYouLib.themeElements.Buttons, b)
        table.insert(FuckYouLib.themeElements.Texts, b)
    else
        table.insert(FuckYouLib.themeElements.CustomButtons, b)
    end
    b.BackgroundTransparency = 1 - FuckYouLib.uiGuiOpacity
    if p:IsA("GuiObject") and p.ZIndex > 1 then b.ZIndex = p.ZIndex + 1 end
    corner(b)
    return b
end

local musicSound = nil
local Parts = Instance.new("Model"); Parts.Name = "MusicParts"
local timelineLoop = nil
local isInteractingWithSlider = false

local function getRoot()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end
local function updatePartsParent()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        Parts.Parent = LocalPlayer.Character
    else
        Parts.Parent = workspace
    end
end
local function rebuildParts(n)
    Settings.Parts = tonumber(n) or 2
    Parts:ClearAllChildren()
    if ToggleState then updatePartsParent() end
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
        p.Locked = true
    end
end
local function makeMusicSound(id)
    local s = Instance.new("Sound", FuckYouLib.ScreenGui)
    s.Name = "Music"; s.SoundId = "rbxassetid://" .. (id or "1")
    s.Looped = true; s.PlaybackSpeed = 1; s.Volume = 1
    return s
end

local soundIdBox, volumeBox, pitchBox, playingLabel
local timePosLabel, timeLenLabel, lineProgress
local currentSelectedId = ""
local currentCategory = "Default"
local MusicKeybinds = { Toggle = "" }

local function runTimelineLoop()
    if timelineLoop then .cancel(timelineLoop) end
    timelineLoop = .spawn(function()
        while ScriptActive do
            if ToggleState and musicSound and musicSound.Parent and musicSound.IsPlaying and not isInteractingWithSlider then
                local tracks = DataStructure.Categories[currentCategory] or {}
                local cur = tracks[currentSelectedId]
                if cur and tonumber(cur.end_time) and cur.end_time > 0 then
                    if musicSound.TimePosition >= cur.end_time then
                        musicSound.TimePosition = cur.start_time or 0
                    end
                end
                if timePosLabel and musicSound.TimeLength > 0 then
                    lineProgress.Size = UDim2.new(math.clamp(musicSound.TimePosition / musicSound.TimeLength, 0, 1), 0, 0, 6)
                    timeLenLabel.Text = string.format("%02i:%02i", math.floor(musicSound.TimeLength/60)%60, math.floor(musicSound.TimeLength)%60)
                    timePosLabel.Text = string.format("%02i:%02i", math.floor(musicSound.TimePosition/60)%60, math.floor(musicSound.TimePosition)%60)
                end
            end
            .wait(0.3)
        end
    end)
end

local Rad, mRad, LastB, LastL = 0, math.random(0,100), 0, 0
RunService:BindToRenderStep("musicVisualRender", 0, function()
    if not ScriptActive or not ToggleState then return end
    local loudness = (musicSound and musicSound.Parent) and musicSound.PlaybackLoudness or 0
    local target = Settings.StaticColor
    local beat = math.abs(math.floor(loudness) - LastL)
    if beat > LastB then LastB = beat else LastB = math.max(0, LastB - 10) end
    mRad = (mRad + beat / 250) % 100
    LastL = math.floor(loudness)
    if Settings.Rainbow then
        target = Color3.fromHSV(mRad / 200, 1, math.min(1 + LastB / 9e5, 10))
    end
    for _, c in ipairs(Parts:GetChildren()) do
        if c:IsA("BasePart") then c.Color = target end
    end
end)

.spawn(function()
    while ScriptActive do
        .wait()
        if ToggleState then
            local root = getRoot()
            if root then
                Rad = (Rad + 1) % 360
                for i, v in ipairs(Parts:GetChildren()) do
                    if v:IsA("BasePart") then
                        local sideCount = Settings.Parts > 0 and Settings.Parts or 1
                        local splitVal = Settings.Split > 0 and Settings.Split or 1
                        local goalVal = Settings.Goal > 0 and Settings.Goal or 0.3
                        pcall(function()
                            v.CFrame = v.CFrame:Lerp(
                                CFrame.new(root.CFrame.X, root.CFrame.Y + Settings.Body, root.CFrame.Z)
                                * CFrame.Angles(0, math.rad((360 / sideCount) * ((i + (i * Settings.Angle)) / splitVal) + Rad), 0)
                                * CFrame.new(0, 0, Settings.Disposition + v.Size.Z),
                                goalVal)
                        end)
                    end
                end
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not ToggleState then return end
    local loudness = (musicSound and musicSound.Parent) and musicSound.PlaybackLoudness or 0
    local pList = Parts:GetChildren()
    if #pList > 0 and loudness > 0 then
        local powerVal = Settings.Power > 0 and Settings.Power or 1
        local goalVal = Settings.Goal > 0 and Settings.Goal or 0.3
        for _, v in ipairs(pList) do
            if v:IsA("BasePart") then
                pcall(function()
                    v.Size = v.Size:Lerp(Vector3.new(0.8, 0.2, (loudness / powerVal) * math.random(4, 8)), goalVal)
                end)
            end
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    if ToggleState then
        .wait(0.1)
        updatePartsParent()
        rebuildParts(Settings.Parts)
    end
end)

local musicTabs = {}
local toggleStateBtn
local updateMusicList, updateCategoryList, updateGrabberList
local materialBtnRef

local function addMusicTab(name, builder)
    local frame = FuckYouLib.create("Frame", {Name = "Tab" .. name, Parent = FuckYouLib.Containment, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false})
    builder(frame)
    local btn = FuckYouLib.create("TextButton", {Name = "MBtn_" .. name, Parent = FuckYouLib.MenuInsided, Size = UDim2.new(1,0,0,40), LayoutOrder = 200 + #musicTabs, Visible = false, BackgroundColor3 = FuckYouLib.uiColor_ButtonColor, BorderColor3 = COL_BORDER, TextColor3 = FuckYouLib.uiColor_TextColor, Text = name, Font = FONT, TextSize = 12, TextWrapped = true})
    local entry = {Frame = frame, Name = name, Button = btn}
    table.insert(musicTabs, entry)
    table.insert(FuckYouLib.themeElements.Buttons, btn)
    table.insert(FuckYouLib.themeElements.Texts, btn)
    return entry
end

-- 1. HOME
local function buildHome(parent)
    local inner = mkPanel(parent, UDim2.new(1,0,1,0))
    mkLabel(inner, "HOME", UDim2.new(1,-20,0,24), UDim2.new(0,10,0,8), F_S, 18)
    soundIdBox = mkBox(inner, "", UDim2.new(1,-20,0,30), UDim2.new(0,10,0,38), "Sound ID", 16)
    local playBtn = mkBtn(inner, "PLAY", UDim2.new(0.23,-8,0,30), UDim2.new(0,10,0,76), F_S, 14, false, C_BG, C_TEXT)
    volumeBox = mkBox(inner, "1", UDim2.new(0.23,-8,0,30), UDim2.new(0.25,4,0,76), "Volume", 14)
    pitchBox = mkBox(inner, "1", UDim2.new(0.23,-8,0,30), UDim2.new(0.5,4,0,76), "Pitch", 14)
    local stopBtn = mkBtn(inner, "STOP", UDim2.new(0.23,-8,0,30), UDim2.new(0.75,4,0,76), F_S, 14, false, C_BG, C_TEXT)
    local sp = FuckYouLib.create("Frame", {Parent = inner, Size = UDim2.new(1,-20,0,35), Position = UDim2.new(0,10,0,120), BackgroundTransparency = 1})
    timePosLabel = mkLabel(sp, "0:00", UDim2.new(0,45,0,20), UDim2.new(0,0,0,5), F_S, 14)
    timeLenLabel = mkLabel(sp, "0:00", UDim2.new(0,45,0,20), UDim2.new(1,-45,0,5), F_S, 14, nil, Enum.TextXAlignment.Right)
    local line = Instance.new("TextButton"); line.Parent = sp
    line.BackgroundColor3 = FuckYouLib.uiColor_TextBoxColor; line.BorderSizePixel = 0
    line.Position = UDim2.new(0,50,0,10); line.Size = UDim2.new(1,-100,0,6)
    line.Text = ""; table.insert(FuckYouLib.themeElements.TextBoxes, line); corner(line)
    lineProgress = FuckYouLib.create("Frame", {Parent = line, Size = UDim2.new(0,0,0,6), Position = UDim2.new(0,0,0,0), BackgroundColor3 = FuckYouLib.uiColor_TextColor, BorderSizePixel = 0})
    playingLabel = mkLabel(sp, "Script Disabled", UDim2.new(1,-100,0,15), UDim2.new(0,50,0,20), F_S, 12)
    playingLabel.TextWrapped = true
    local function sliderToMouse()
        if not musicSound or musicSound.TimeLength <= 0 or not ToggleState then return end
        local mousePos = UserInputService:GetMouseLocation()
        local rel = mousePos.X - line.AbsolutePosition.X
        local pct = math.clamp(rel / line.AbsoluteSize.X, 0, 1)
        lineProgress.Size = UDim2.new(pct, 0, 0, 6)
        musicSound.TimePosition = musicSound.TimeLength * pct
    end
    line.MouseButton1Down:Connect(function() isInteractingWithSlider = true; sliderToMouse() end)
    UserInputService.InputChanged:Connect(function(input)
        if isInteractingWithSlider and input.UserInputType == Enum.UserInputType.MouseMovement then sliderToMouse() end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then isInteractingWithSlider = false end
    end)
    playBtn.MouseButton1Click:Connect(function()
        if not ToggleState then return end
        if not musicSound or musicSound.Parent ~= FuckYouLib.ScreenGui then
            musicSound = makeMusicSound(soundIdBox.Text ~= "" and soundIdBox.Text or "1")
            runTimelineLoop()
        end
        musicSound.SoundId = "rbxassetid://" .. (soundIdBox.Text ~= "" and soundIdBox.Text or "1")
        musicSound.Volume = tonumber(volumeBox.Text) or 1
        musicSound.PlaybackSpeed = tonumber(pitchBox.Text) or 1
        musicSound.TimePosition = 0
        musicSound:Play()
        playingLabel.Text = "Playing ID: " .. soundIdBox.Text
    end)
    stopBtn.MouseButton1Click:Connect(function() if musicSound then musicSound:Stop() end end)
end

-- 2. MUSIC
local searchQuery = ""
local PAGE_SIZE = 50
local musicPage, grabPage = 1, 1
local musicPageLbl, grabPageLbl
local addMenuFrame, catMenuFrame

local function buildMusic(parent)
    local inner = mkPanel(parent, UDim2.new(1,0,1,0))
    mkLabel(inner, "MUSIC LIBRARY", UDim2.new(1,-20,0,24), UDim2.new(0,10,0,8), F_S, 18)
    local searchBox = mkBox(inner, "", UDim2.new(1,-20,0,24), UDim2.new(0,10,0,36), "Search ID / Name...", 14)
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        searchQuery = searchBox.Text:lower()
        if updateMusicList then updateMusicList() end
    end)
    local catFrame = FuckYouLib.create("ScrollingFrame", {Parent = inner, Size = UDim2.new(0,95,1,-100), Position = UDim2.new(0,10,0,66), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, CanvasSize = UDim2.new(0,0,0,0)})
    local musFrame = FuckYouLib.create("ScrollingFrame", {Parent = inner, Size = UDim2.new(1,-115,1,-100), Position = UDim2.new(0,105,0,66), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0,0,0,0)})
    local controls = FuckYouLib.create("Frame", {Parent = inner, Size = UDim2.new(1,-10,0,35), Position = UDim2.new(0,5,1,-35), BackgroundTransparency = 1})
    local addB = mkBtn(controls, "ADD", UDim2.new(0,75,0,26), UDim2.new(0,5,0,4), F_S, 13, false, C_DARKGRN, C_TEXT)
    local editB = mkBtn(controls, "EDIT", UDim2.new(0,75,0,26), UDim2.new(0,85,0,4), F_S, 13, false, Color3.fromRGB(50,50,70), C_TEXT)
    local delB = mkBtn(controls, "DELETE", UDim2.new(0,75,0,26), UDim2.new(0,165,0,4), F_S, 13, false, C_DARKRED, C_TEXT)
    local newCatB = mkBtn(controls, "+ CAT", UDim2.new(0,70,0,26), UDim2.new(0,245,0,4), F_S, 13, false, Color3.fromRGB(60,60,60), C_TEXT)
    local delCatB = mkBtn(controls, "- CAT", UDim2.new(0,70,0,26), UDim2.new(0,320,0,4), F_S, 13, false, Color3.fromRGB(45,45,45), C_TEXT)
    local CHECK_BG = Color3.fromRGB(60,60,60)
    local checkB = mkBtn(controls, "CHECK", UDim2.new(0,75,0,26), UDim2.new(0,395,0,4), F_S, 13)
    local isChecking = false
    checkB.MouseButton1Click:Connect(function()
        if isChecking then return end
        isChecking = true
        checkB.Text = "PREPARING..."
        .spawn(function()
            local seen, list = {}, {}
            for _, catData in pairs(DataStructure.Categories) do
                for id, _ in pairs(catData) do
                    local k = tostring(id)
                    if not seen[k] then seen[k] = true; table.insert(list, k) end
                end
            end
            local broken = 0
            for i, id in ipairs(list) do
                checkB.Text = string.format("CHECK %d/%d", i, #list)
                local temp = Instance.new("Sound")
                temp.SoundId = "rbxassetid://" .. id
                temp.Volume = 0
                temp.Parent = SoundService
                pcall(function() temp:Play() end)
                local ok = false
                local el = 0
                while el < 5 do
                    if temp.TimeLength > 0 then ok = true; break end
                    .wait(0.25); el = el + 0.25
                end
                temp:Stop(); temp:Destroy()
                if ok then brokenIds[id] = nil else brokenIds[id] = true; broken = broken + 1 end
                .wait(0.1)
            end
            updateMusicList()
            checkB.Text = "CHECK"
            isChecking = false
            FuckYouLib.notify("Check", "Done! Broken tracks marked red: " .. broken)
        end)
    end)
    local mPrevB = mkBtn(controls, "<", UDim2.new(0,30,0,26), UDim2.new(0,480,0,4), F_S, 13, "no", Color3.fromRGB(60,60,60), C_TEXT)
    musicPageLbl = mkLabel(controls, "1/1", UDim2.new(0,70,0,26), UDim2.new(0,515,0,4), F_S, 13, C_TEXT2, Enum.TextXAlignment.Center)
    local mNextB = mkBtn(controls, ">", UDim2.new(0,30,0,26), UDim2.new(0,590,0,4), F_S, 13, "no", Color3.fromRGB(60,60,60), C_TEXT)
    mPrevB.MouseButton1Click:Connect(function() if musicPage > 1 then musicPage = musicPage - 1; updateMusicList() end end)
    mNextB.MouseButton1Click:Connect(function() musicPage = musicPage + 1; updateMusicList() end)

    addMenuFrame = FuckYouLib.create("Frame", {Parent = inner, Size = UDim2.new(0.9,0,0.75,0), Position = UDim2.new(0.05,0,0.1,0), BackgroundColor3 = Color3.fromRGB(25,25,25), BorderColor3 = C_BORDER, BorderSizePixel = 1, Visible = false, ZIndex = 20})
    corner(addMenuFrame)
    mkLabel(addMenuFrame, "TRACK EDITOR", UDim2.new(1,0,0.12,0), UDim2.new(0,0,0,0), F_S, 15, C_TEXT2, Enum.TextXAlignment.Center)
    local inId = mkBox(addMenuFrame, "", UDim2.new(0.45,0,0.15,0), UDim2.new(0.04,0,0.15,0), "Sound ID", 14)
    local inName = mkBox(addMenuFrame, "", UDim2.new(0.45,0,0.15,0), UDim2.new(0.51,0,0.15,0), "Track Name", 14)
    local inVol = mkBox(addMenuFrame, "1", UDim2.new(0.45,0,0.15,0), UDim2.new(0.04,0,0.35,0), "Volume (e.g. 1)", 14)
    local inPitch = mkBox(addMenuFrame, "1", UDim2.new(0.45,0,0.15,0), UDim2.new(0.51,0,0.35,0), "Pitch (e.g. 1)", 14)
    local inStart = mkBox(addMenuFrame, "0", UDim2.new(0.45,0,0.15,0), UDim2.new(0.04,0,0.55,0), "Start Time (sec)", 14)
    local inEnd = mkBox(addMenuFrame, "0", UDim2.new(0.45,0,0.15,0), UDim2.new(0.51,0,0.55,0), "End Time (0 = Max)", 14)
    local saveB = mkBtn(addMenuFrame, "SAVE", UDim2.new(0.45,0,0.15,0), UDim2.new(0.04,0,0.78,0), F_S, 14, false, Color3.fromRGB(40,80,40), Color3.fromRGB(250,250,250))
    local cancelB = mkBtn(addMenuFrame, "CANCEL", UDim2.new(0.45,0,0.15,0), UDim2.new(0.51,0,0.78,0), F_S, 14, false, Color3.fromRGB(80,40,40), Color3.fromRGB(250,250,250))

    catMenuFrame = FuckYouLib.create("Frame", {Parent = inner, Size = UDim2.new(0.7,0,0.4,0), Position = UDim2.new(0.15,0,0.3,0), BackgroundColor3 = Color3.fromRGB(30,30,30), BorderColor3 = C_BORDER, BorderSizePixel = 1, Visible = false, ZIndex = 22})
    corner(catMenuFrame)
    mkLabel(catMenuFrame, "NEW CATEGORY NAME:", UDim2.new(1,0,0.3,0), UDim2.new(0,0,0,0), F_S, 14, C_TEXT2, Enum.TextXAlignment.Center)
    local inCatName = mkBox(catMenuFrame, "", UDim2.new(0.9,0,0.3,0), UDim2.new(0.05,0,0.35,0), "", 14)
    local saveCatB = mkBtn(catMenuFrame, "CREATE", UDim2.new(0.45,0,0.2,0), UDim2.new(0.05,0,0.7,0), F_S, 14, false, Color3.fromRGB(40,80,40), Color3.fromRGB(250,250,250))
    local cancelCatB = mkBtn(catMenuFrame, "CANCEL", UDim2.new(0.45,0,0.2,0), UDim2.new(0.5,0,0.7,0), F_S, 14, false, Color3.fromRGB(80,40,40), Color3.fromRGB(250,250,250))

    updateCategoryList = function()
        for _, c in ipairs(catFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        local y = 5
        for catName, _ in pairs(DataStructure.Categories) do
            local b = mkBtn(catFrame, catName, UDim2.new(1,-10,0,25), UDim2.new(0,5,0,y), F_B, 13, "no",
                currentCategory == catName and lighter(FuckYouLib.uiColor_ButtonColor, 40) or FuckYouLib.uiColor_ButtonColor, FuckYouLib.uiColor_TextColor)
            b.MouseButton1Click:Connect(function()
                currentCategory = catName
                updateCategoryList(); updateMusicList()
            end)
            y = y + 28
        end
        catFrame.CanvasSize = UDim2.new(0,0,0, y + 10)
    end

    updateMusicList = function()
        for _, c in ipairs(musFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        local tracks = DataStructure.Categories[currentCategory] or {}
        local list = {}
        for id, td in pairs(tracks) do
            local nm = (td.name or ""):lower()
            local idL = tostring(id):lower()
            if searchQuery == "" or nm:find(searchQuery, 1, true) or idL:find(searchQuery, 1, true) then
                table.insert(list, {id = tostring(id), td = td})
            end
        end
        table.sort(list, function(a, b) return (a.td.name or a.id):lower() < (b.td.name or b.id):lower() end)
        local totalPages = math.max(1, math.ceil(#list / PAGE_SIZE))
        if musicPage < 1 then musicPage = 1 end
        if musicPage > totalPages then musicPage = totalPages end
        if musicPageLbl then musicPageLbl.Text = musicPage .. "/" .. totalPages end
        local first = (musicPage - 1) * PAGE_SIZE + 1
        local last = math.min(#list, musicPage * PAGE_SIZE)
        local sx, sy, px, py = 6, 5, 4, 6
        local tw, th = 88, 45
        local col, row = 0, 0
        for i = first, last do
            local id, td = list[i].id, list[i].td
            local isBroken = brokenIds[id] == true
            local bgCol = isBroken and C_DARKRED or (currentSelectedId == id and lighter(FuckYouLib.uiColor_ButtonColor, 40) or FuckYouLib.uiColor_ButtonColor)
            local txCol = isBroken and C_RED or FuckYouLib.uiColor_TextColor
            local b = mkBtn(musFrame, td.name or id, UDim2.new(0,tw,0,th),
                UDim2.new(0, sx + col*(tw+px), 0, sy + row*(th+py)), F_R, 12, "no", bgCol, txCol)
            b.MouseButton1Click:Connect(function()
                if not ToggleState then return end
                currentSelectedId = id
                soundIdBox.Text = id
                volumeBox.Text = tostring(td.volume or 1)
                pitchBox.Text = tostring(td.pitch or 1)
                updateMusicList()
                if not musicSound or musicSound.Parent ~= FuckYouLib.ScreenGui then
                    musicSound = makeMusicSound(id)
                    runTimelineLoop()
                end
                musicSound.SoundId = "rbxassetid://" .. id
                musicSound.Volume = tonumber(td.volume) or 1
                musicSound.PlaybackSpeed = tonumber(td.pitch) or 1
                musicSound.TimePosition = tonumber(td.start_time) or 0
                musicSound:Play()
                playingLabel.Text = "[" .. currentCategory .. "] " .. (td.name or id)
            end)
            col = col + 1
            if col >= 7 then col = 0; row = row + 1 end
        end
        local totalRows = col > 0 and (row + 1) or row
        musFrame.CanvasSize = UDim2.new(0,0,0, sy + totalRows * (th + py) + 10)
    end

    updateCategoryList(); updateMusicList()

    newCatB.MouseButton1Click:Connect(function() inCatName.Text = ""; catMenuFrame.Visible = true end)
    saveCatB.MouseButton1Click:Connect(function()
        local n = inCatName.Text:gsub("%s+","")
        if n ~= "" and not DataStructure.Categories[n] then
            DataStructure.Categories[n] = {}
            currentCategory = n
            saveMusicData(); updateCategoryList(); updateMusicList()
        end
        catMenuFrame.Visible = false
    end)
    cancelCatB.MouseButton1Click:Connect(function() catMenuFrame.Visible = false end)
    delCatB.MouseButton1Click:Connect(function()
        if currentCategory ~= "Default" then
            DataStructure.Categories[currentCategory] = nil
            currentCategory = "Default"
            saveMusicData(); updateCategoryList(); updateMusicList()
        end
    end)
    addB.MouseButton1Click:Connect(function()
        inId.Text = ""; inName.Text = ""; inVol.Text = "1"; inPitch.Text = "1"; inStart.Text = "0"; inEnd.Text = "0"
        addMenuFrame.Visible = true
    end)
    editB.MouseButton1Click:Connect(function()
        local tr = DataStructure.Categories[currentCategory] and DataStructure.Categories[currentCategory][currentSelectedId]
        if tr then
            inId.Text = currentSelectedId; inName.Text = tr.name or ""
            inVol.Text = tostring(tr.volume or 1); inPitch.Text = tostring(tr.pitch or 1)
            inStart.Text = tostring(tr.start_time or 0); inEnd.Text = tostring(tr.end_time or 0)
            addMenuFrame.Visible = true
        end
    end)
    saveB.MouseButton1Click:Connect(function()
        local id = inId.Text:gsub("%s+","")
        local nm = inName.Text
        if id ~= "" and nm ~= "" then
            DataStructure.Categories[currentCategory][id] = {
                name = nm, volume = tonumber(inVol.Text) or 1, pitch = tonumber(inPitch.Text) or 1,
                start_time = tonumber(inStart.Text) or 0, end_time = tonumber(inEnd.Text) or 0
            }
            saveMusicData(); updateMusicList()
            addMenuFrame.Visible = false
        end
    end)
    cancelB.MouseButton1Click:Connect(function() addMenuFrame.Visible = false end)
    delB.MouseButton1Click:Connect(function()
        if DataStructure.Categories[currentCategory] and DataStructure.Categories[currentCategory][currentSelectedId] then
            DataStructure.Categories[currentCategory][currentSelectedId] = nil
            saveMusicData(); updateMusicList()
            currentSelectedId = ""
        end
    end)
end

-- 3. SETTINGS
local function buildSettings(parent)
    local inner = mkPanel(parent, UDim2.new(1,0,1,0))
    mkLabel(inner, "SETTINGS", UDim2.new(1,-20,0,24), UDim2.new(0,10,0,8), F_S, 18)
    local function mkSetBox(ph, col, row)
        local sx, sy, px, py, w, h = 10, 40, 10, 10, 170, 34
        return mkBox(inner, "", UDim2.new(0,w,0,h), UDim2.new(0, sx + (col-1)*(w+px), 0, sy + (row-1)*(h+py)), ph, 15)
    end
    local partsSetting = mkSetBox("Parts", 1, 1)
    local colorSetting = mkSetBox("Color (255,255,255)", 2, 1); colorSetting.Text = "255,255,255"
    local angleSetting2 = mkSetBox("Goal", 3, 1)
    local transSetting = mkSetBox("Trans", 1, 2); transSetting.Text = "0"
    local splitSetting = mkSetBox("Split", 2, 2)
    local angleSetting = mkSetBox("Angle", 3, 2)
    local disposSetting = mkSetBox("Disposition", 1, 3)
    local bodySetting = mkSetBox("Body", 2, 3)
    local powerSetting = mkSetBox("Power", 3, 3)

    partsSetting.Text = tostring(Settings.Parts)
    colorSetting.Text = string.format("%d,%d,%d", Settings.StaticColor.R*255, Settings.StaticColor.G*255, Settings.StaticColor.B*255)
    angleSetting2.Text = tostring(Settings.Goal)
    transSetting.Text = tostring(Settings.Transparency)
    splitSetting.Text = tostring(Settings.Split)
    angleSetting.Text = tostring(Settings.Angle)
    disposSetting.Text = tostring(Settings.Disposition)
    bodySetting.Text = tostring(Settings.Body)
    powerSetting.Text = tostring(Settings.Power)

    local rainbowToggleBtn = mkBtn(inner, "RAINBOW: " .. (Settings.Rainbow and "ON" or "OFF"),
        UDim2.new(0,170,0,34), UDim2.new(0,10,0,170), F_S, 14, "no",
        Settings.Rainbow and C_DARKGRN or C_DARKRED,
        Settings.Rainbow and C_GRN or C_RED)
    materialBtnRef = mkBtn(inner, "MATERIALS", UDim2.new(0,170,0,34), UDim2.new(0,190,0,170), F_S, 14)

    rainbowToggleBtn.MouseButton1Click:Connect(function()
        Settings.Rainbow = not Settings.Rainbow
        if Settings.Rainbow then
            rainbowToggleBtn.Text = "RAINBOW: ON"; rainbowToggleBtn.TextColor3 = C_GRN; rainbowToggleBtn.BackgroundColor3 = C_DARKGRN
        else
            rainbowToggleBtn.Text = "RAINBOW: OFF"; rainbowToggleBtn.TextColor3 = C_RED; rainbowToggleBtn.BackgroundColor3 = C_DARKRED
            for _, c in ipairs(Parts:GetChildren()) do
                if c:IsA("BasePart") then c.Color = Settings.StaticColor end
            end
        end
        saveSettings()
    end)

    partsSetting.FocusLost:Connect(function()
        local v = tonumber(partsSetting.Text); if not v then return end
        Settings.Parts = math.clamp(v, 1, 200); rebuildParts(Settings.Parts); saveSettings()
    end)
    colorSetting.FocusLost:Connect(function()
        local r, g, b = colorSetting.Text:match("(%d+),%s*(%d+),%s*(%d+)")
        if r and g and b then
            Settings.StaticColor = Color3.fromRGB(math.clamp(tonumber(r),0,255), math.clamp(tonumber(g),0,255), math.clamp(tonumber(b),0,255))
            if not Settings.Rainbow then
                for _, c in ipairs(Parts:GetChildren()) do
                    if c:IsA("BasePart") then c.Color = Settings.StaticColor end
                end
            end
            saveSettings()
        end
    end)
    angleSetting2.FocusLost:Connect(function()
        local v = tonumber(angleSetting2.Text); if v then Settings.Goal = math.clamp(v, 0.01, 1); saveSettings() end
    end)
    transSetting.FocusLost:Connect(function()
        local v = tonumber(transSetting.Text); if v then
            Settings.Transparency = math.clamp(v, 0, 1)
            for _, c in ipairs(Parts:GetChildren()) do
                if c:IsA("BasePart") then c.Transparency = Settings.Transparency end
            end
            saveSettings()
        end
    end)
    splitSetting.FocusLost:Connect(function()
        local v = tonumber(splitSetting.Text); if v then Settings.Split = v == 0 and 1 or v; saveSettings() end
    end)
    angleSetting.FocusLost:Connect(function()
        local v = tonumber(angleSetting.Text); if v then Settings.Angle = v; saveSettings() end
    end)
    disposSetting.FocusLost:Connect(function()
        local v = tonumber(disposSetting.Text); if v then Settings.Disposition = v; saveSettings() end
    end)
    bodySetting.FocusLost:Connect(function()
        local v = tonumber(bodySetting.Text); if v then Settings.Body = v; saveSettings() end
    end)
    powerSetting.FocusLost:Connect(function()
        local v = tonumber(powerSetting.Text); if v then Settings.Power = v == 0 and 1 or v; saveSettings() end
    end)
end

-- 4. MATERIALS
local function buildMaterials(parent)
    local inner = mkPanel(parent, UDim2.new(1,0,1,0))
    mkLabel(inner, "MATERIALS", UDim2.new(1,-20,0,24), UDim2.new(0,10,0,8), F_S, 18)
    local picker = FuckYouLib.create("ScrollingFrame", {Parent = inner, Size = UDim2.new(1,-20,1,-40), Position = UDim2.new(0,10,0,34), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0,0,0,0)})
    local materialsList = {
        "Neon", "Plastic", "Glass", "ForceField", "Wood", "WoodPlanks",
        "Marble", "Slate", "Granite", "Brick", "Cobblestone", "Concrete",
        "Metal", "DiamondPlate", "CorrodedMetal", "Ice", "Sand", "Fabric"
    }
    local col, row = 0, 0
    for _, matName in ipairs(materialsList) do
        local b = mkBtn(picker, matName:upper(), UDim2.new(0,140,0,34), UDim2.new(0, 5 + col*148, 0, 5 + row*42), F_B, 13, false, C_BG, C_TEXT)
        b.MouseButton1Click:Connect(function()
            Settings.Material = matName
            for _, c in ipairs(Parts:GetChildren()) do
                if c:IsA("Part") then c.Material = Enum.Material[matName] or Enum.Material.Neon end
            end
            saveSettings()
        end)
        col = col + 1
        if col >= 5 then col = 0; row = row + 1 end
    end
    picker.CanvasSize = UDim2.new(0,0,0, 5 + (row+1)*42 + 10)
end

-- 5. GRABBER
local selectedGrabbedId = ""
local isGrabberScanning = false
local scanConnection = nil
local scanCycleThread = nil

local function buildGrabber(parent)
    local inner = mkPanel(parent, UDim2.new(1,0,1,0))
    mkLabel(inner, "GRABBER", UDim2.new(1,-20,0,24), UDim2.new(0,10,0,8), F_S, 18)
    local grabFrame = FuckYouLib.create("ScrollingFrame", {Parent = inner, Size = UDim2.new(1,-20,1,-85), Position = UDim2.new(0,10,0,40), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0,0,0,0)})
    local controls = FuckYouLib.create("Frame", {Parent = inner, Size = UDim2.new(1,-10,0,35), Position = UDim2.new(0,5,1,-35), BackgroundTransparency = 1})
    local gStartB = mkBtn(controls, "START", UDim2.new(0,90,0,26), UDim2.new(0,5,0,4), F_S, 13, "no", C_DARKGRN, C_TEXT)
    local gScanB = mkBtn(controls, "SCAN", UDim2.new(0,100,0,26), UDim2.new(0,105,0,4), F_S, 13, false, C_DARKBLUE, C_TEXT)
    local gDelB = mkBtn(controls, "DELETE", UDim2.new(0,90,0,26), UDim2.new(0,215,0,4), F_S, 13, false, C_DARKRED, C_TEXT)
    local gBlackB = mkBtn(controls, "BLACKLIST", UDim2.new(0,95,0,26), UDim2.new(0,315,0,4), F_S, 13, false, Color3.fromRGB(45,45,45), C_TEXT)
    local gPrevB = mkBtn(controls, "<", UDim2.new(0,30,0,26), UDim2.new(0,480,0,4), F_S, 13, "no", Color3.fromRGB(60,60,60), C_TEXT)
    grabPageLbl = mkLabel(controls, "1/1", UDim2.new(0,70,0,26), UDim2.new(0,515,0,4), F_S, 13, C_TEXT2, Enum.TextXAlignment.Center)
    local gNextB = mkBtn(controls, ">", UDim2.new(0,30,0,26), UDim2.new(0,590,0,4), F_S, 13, "no", Color3.fromRGB(60,60,60), C_TEXT)
    gPrevB.MouseButton1Click:Connect(function() if grabPage > 1 then grabPage = grabPage - 1; updateGrabberList() end end)
    gNextB.MouseButton1Click:Connect(function() grabPage = grabPage + 1; updateGrabberList() end)

    local function checkAndAddSound(snd)
        if snd:IsA("Sound") and snd.IsPlaying and snd.SoundId ~= "" then
            local rawId = snd.SoundId:match("%d+")
            if rawId then
                local n = tonumber(rawId)
                if n and not table.find(grabbedIds, n) and not blacklistedIds[n] then
                    table.insert(grabbedIds, n)
                    updateGrabberList(); saveGrabber()
                end
            end
        end
    end

    updateGrabberList = function()
        for _, c in ipairs(grabFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        local total = #grabbedIds
        local totalPages = math.max(1, math.ceil(total / PAGE_SIZE))
        if grabPage < 1 then grabPage = 1 end
        if grabPage > totalPages then grabPage = totalPages end
        if grabPageLbl then grabPageLbl.Text = grabPage .. "/" .. totalPages end
        local first = (grabPage - 1) * PAGE_SIZE + 1
        local last = math.min(total, grabPage * PAGE_SIZE)
        local col, row = 0, 0
        local w, h, gap = 100, 40, 5
        for i = first, last do
            local id = grabbedIds[i]
            local b = mkBtn(grabFrame, tostring(id), UDim2.new(0,w,0,h),
                UDim2.new(0, 5 + col*(w+gap), 0, 5 + row*(h+gap)), F_R, 12, "no",
                selectedGrabbedId == tostring(id) and lighter(FuckYouLib.uiColor_ButtonColor, 40) or FuckYouLib.uiColor_ButtonColor, FuckYouLib.uiColor_TextColor)
            b.MouseButton1Click:Connect(function()
                if not ToggleState then return end
                selectedGrabbedId = tostring(id)
                soundIdBox.Text = tostring(id)
                updateGrabberList()
                if setclipboard then setclipboard(tostring(id)) end
                if not musicSound or musicSound.Parent ~= FuckYouLib.ScreenGui then
                    musicSound = makeMusicSound(tostring(id))
                    runTimelineLoop()
                end
                musicSound.SoundId = "rbxassetid://" .. id
                musicSound.TimePosition = 0
                musicSound:Play()
                playingLabel.Text = "Grabbed ID: " .. id
            end)
            col = col + 1
            if col >= 7 then col = 0; row = row + 1 end
        end
        grabFrame.CanvasSize = UDim2.new(0,0,0, 5 + (row+1)*(h+gap) + 10)
    end
    updateGrabberList()

    local function fullSweep()
        pcall(function()
            for _, v in ipairs(game:GetDescendants()) do
                if v:IsA("Sound") then checkAndAddSound(v) end
            end
        end)
    end
    local function startSmartScanning()
        fullSweep()
        scanConnection = game.DescendantAdded:Connect(function(desc)
            pcall(function()
                if desc:IsA("Sound") then
                    checkAndAddSound(desc)
                    desc:GetPropertyChangedSignal("IsPlaying"):Connect(function() checkAndAddSound(desc) end)
                end
            end)
        end)
        if scanCycleThread then .cancel(scanCycleThread) end
        scanCycleThread = .spawn(function()
            while isGrabberScanning do
                .wait(10)
                if not isGrabberScanning then break end
                fullSweep()
            end
        end)
    end
    local function stopSmartScanning()
        if scanConnection then scanConnection:Disconnect(); scanConnection = nil end
        if scanCycleThread then .cancel(scanCycleThread); scanCycleThread = nil end
    end

    gStartB.MouseButton1Click:Connect(function()
        isGrabberScanning = not isGrabberScanning
        if isGrabberScanning then
            gStartB.Text = "STOP"; gStartB.BackgroundColor3 = C_DARKRED
            startSmartScanning()
        else
            gStartB.Text = "START"; gStartB.BackgroundColor3 = C_DARKGRN
            stopSmartScanning()
        end
    end)

    local isScanningLogicRunning = false
    gScanB.MouseButton1Click:Connect(function()
        if isScanningLogicRunning then return end
        isScanningLogicRunning = true
        local ScanGui = FuckYouLib.create("Frame", {
            Name = "ScanProgressGui", Parent = inner,
            AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0.5,0,0.5,0),
            Size = UDim2.new(0,280,0,90),
            BackgroundColor3 = Color3.fromRGB(20,20,20), BorderColor3 = Color3.fromRGB(60,60,60),
            ZIndex = 20,
        })
        local ScanTitle = FuckYouLib.create("TextLabel", {Parent = ScanGui, Size = UDim2.new(1,0,0,30), BackgroundTransparency = 1, Text = "VALIDATING GRABBER LIST...", TextColor3 = Color3.fromRGB(220,220,220), TextSize = 13, Font = FONT, ZIndex = 21})
        local ScanStatus = FuckYouLib.create("TextLabel", {Parent = ScanGui, Position = UDim2.new(0,0,0,30), Size = UDim2.new(1,0,0,20), BackgroundTransparency = 1, Text = "Initializing...", TextColor3 = Color3.fromRGB(160,160,160), TextSize = 12, Font = FONT, ZIndex = 21})
        local BarBack = FuckYouLib.create("Frame", {Parent = ScanGui, Position = UDim2.new(0.05,0,0,60), Size = UDim2.new(0.9,0,0,10), BackgroundColor3 = Color3.fromRGB(40,40,40), BorderSizePixel = 0, ZIndex = 21})
        local BarFill = FuckYouLib.create("Frame", {Parent = BarBack, Size = UDim2.new(0,0,1,0), BackgroundColor3 = Color3.fromRGB(100,200,100), BorderSizePixel = 0, ZIndex = 22})
        .spawn(function()
            pcall(function()
                .wait(0.2)
                ScanStatus.Text = "Removing duplicates..."
                local uniq, seen = {}, {}
                for _, id in ipairs(grabbedIds) do
                    local k = tostring(id)
                    if not seen[k] then seen[k] = true; table.insert(uniq, id) end
                end
                grabbedIds = uniq
                ScanStatus.Text = "Cross-referencing with Music library..."
                .wait(0.2)
                local musicIdSet = {}
                for _, catData in pairs(DataStructure.Categories) do
                    for id, _ in pairs(catData) do musicIdSet[tostring(id)] = true end
                end
                local filtered = {}
                for _, id in ipairs(grabbedIds) do
                    if not musicIdSet[tostring(id)] then table.insert(filtered, id) end
                end
                grabbedIds = filtered
                saveGrabber()
                local total = #grabbedIds
                local valid = {}
                for index, id in ipairs(grabbedIds) do
                    ScanStatus.Text = string.format("Testing playback: %d / %d (ID: %s)", index, total, tostring(id))
                    if total > 0 then BarFill.Size = UDim2.new(index / total, 0, 1, 0) end
                    local temp = Instance.new("Sound")
                    temp.SoundId = "rbxassetid://" .. tostring(id)
                    temp.Volume = 0
                    temp.Parent = SoundService
                    pcall(function() temp:Play() end)
                    local el = 0
                    while el < 5 do
                        if temp.TimeLength > 0 then table.insert(valid, id); break end
                        .wait(0.25); el = el + 0.25
                    end
                    temp:Stop(); temp:Destroy()
                    .wait(0.2)
                end
                grabbedIds = valid
                saveGrabber(); updateGrabberList()
                selectedGrabbedId = ""
                ScanStatus.Text = string.format("Complete! %d / %d IDs are valid.", #valid, total)
                BarFill.Size = UDim2.new(1, 0, 1, 0)
                .wait(2)
            end)
            ScanGui:Destroy()
            isScanningLogicRunning = false
            FuckYouLib.notify("Grabber", "Scan complete")
        end)
    end)

    gDelB.MouseButton1Click:Connect(function()
        local n = tonumber(selectedGrabbedId)
        if n then
            local idx = table.find(grabbedIds, n)
            if idx then table.remove(grabbedIds, idx) end
            selectedGrabbedId = ""
            saveGrabber(); updateGrabberList()
        end
    end)
    gBlackB.MouseButton1Click:Connect(function()
        local n = tonumber(selectedGrabbedId)
        if n then
            blacklistedIds[n] = true
            local idx = table.find(grabbedIds, n)
            if idx then table.remove(grabbedIds, idx) end
            selectedGrabbedId = ""
            saveGrabber(); saveBlacklist(); updateGrabberList()
        end
    end)
end

addMusicTab("Home", buildHome)
addMusicTab("Music", buildMusic)
addMusicTab("Settings", buildSettings)
addMusicTab("Materials", buildMaterials)
addMusicTab("Grabber", buildGrabber)

if materialBtnRef then
    materialBtnRef.MouseButton1Click:Connect(function()
        for _, t in ipairs(musicTabs) do t.Frame.Visible = (t.Name == "Materials") end
        FuckYouLib.updateTabButtonsTheme()
    end)
end

local baseApplyTheme = FuckYouLib.applyTheme
FuckYouLib.applyTheme = function()
    baseApplyTheme()
    if lineProgress and lineProgress.Parent then
        lineProgress.BackgroundColor3 = FuckYouLib.uiColor_TextColor
    end
    if updateCategoryList then pcall(updateCategoryList) end
    if updateMusicList then pcall(updateMusicList) end
    if updateGrabberList then pcall(updateGrabberList) end
end

local baseUpdateTabTheme = FuckYouLib.updateTabButtonsTheme
FuckYouLib.updateTabButtonsTheme = function()
    baseUpdateTabTheme()
    for _, tab in ipairs(musicTabs) do
        if tab.Button then
            if tab.Frame.Visible then
                tab.Button.BackgroundColor3 = FuckYouLib.uiColor_ButtonColor
                tab.Button.TextColor3 = Color3.fromRGB(255,255,255)
            else
                tab.Button.BackgroundColor3 = Color3.fromRGB(math.max(FuckYouLib.uiColor_ButtonColor.R*255-10,0), math.max(FuckYouLib.uiColor_ButtonColor.G*255-10,0), math.max(FuckYouLib.uiColor_ButtonColor.B*255-10,0))
                tab.Button.TextColor3 = FuckYouLib.uiColor_TextColor
            end
        end
    end
end

.defer(function()
    local function hideAllFrames()
        for _, t in ipairs(FuckYouLib.tabs) do t.Frame.Visible = false end
        for _, t in ipairs(FuckYouLib.desyncTabs or {}) do t.Frame.Visible = false end
        for _, t in ipairs(musicTabs) do t.Frame.Visible = false end
    end
    local function showMainButtons()
        for _, t in ipairs(FuckYouLib.tabs) do if t.Button then t.Button.Visible = true end end
        for _, t in ipairs(FuckYouLib.desyncTabs or {}) do t.Button.Visible = false end
        for _, t in ipairs(musicTabs) do t.Button.Visible = false end
    end
    local function showDesyncButtons()
        for _, t in ipairs(FuckYouLib.tabs) do if t.Button then t.Button.Visible = false end end
        for _, t in ipairs(FuckYouLib.desyncTabs or {}) do t.Button.Visible = true end
        for _, t in ipairs(musicTabs) do t.Button.Visible = false end
    end
    local function showMusicButtons()
        for _, t in ipairs(FuckYouLib.tabs) do if t.Button then t.Button.Visible = false end end
        for _, t in ipairs(FuckYouLib.desyncTabs or {}) do t.Button.Visible = false end
        for _, t in ipairs(musicTabs) do t.Button.Visible = true end
    end
    for _, t in ipairs(musicTabs) do
        t.Button.MouseButton1Click:Connect(function()
            hideAllFrames()
            t.Frame.Visible = true
            FuckYouLib.updateTabButtonsTheme()
        end)
    end
    for _, t in ipairs(FuckYouLib.tabs) do
        if t.Button then
            t.Button.MouseButton1Click:Connect(function()
                for _, m in ipairs(musicTabs) do m.Frame.Visible = false end
                for _, d in ipairs(FuckYouLib.desyncTabs or {}) do d.Frame.Visible = false end
                FuckYouLib.updateTabButtonsTheme()
            end)
        end
    end
    for _, t in ipairs(FuckYouLib.desyncTabs or {}) do
        t.Button.MouseButton1Click:Connect(function()
            for _, m in ipairs(musicTabs) do m.Frame.Visible = false end
            FuckYouLib.updateTabButtonsTheme()
        end)
    end
    FuckYouLib.EmilyUi.MouseButton1Click:Connect(function()
        showMainButtons(); hideAllFrames()
        if FuckYouLib.tabs[1] then FuckYouLib.tabs[1].Frame.Visible = true end
        FuckYouLib.updateTabButtonsTheme()
    end)
    FuckYouLib.Desync.MouseButton1Click:Connect(function()
        showDesyncButtons(); hideAllFrames()
        if FuckYouLib.desyncTabs and FuckYouLib.desyncTabs[1] then FuckYouLib.desyncTabs[1].Frame.Visible = true end
        FuckYouLib.updateTabButtonsTheme()
    end)
    FuckYouLib.Music.MouseButton1Click:Connect(function()
        showMusicButtons(); hideAllFrames()
        if musicTabs[1] then musicTabs[1].Frame.Visible = true end
        FuckYouLib.updateTabButtonsTheme()
    end)
end)

local MusicSidebarToggle = FuckYouLib.create("TextButton", {
    Name = "MToggle_Music", Parent = FuckYouLib.MenuInsided,
    Size = UDim2.new(1,0,0,40), LayoutOrder = 290, Visible = false,
    BorderColor3 = COL_BORDER, Text = "Music: OFF", Font = FONT, TextSize = 12, TextWrapped = true,
    BackgroundTransparency = 1 - FuckYouLib.uiGuiOpacity,
})
table.insert(FuckYouLib.themeElements.CustomButtons, MusicSidebarToggle)
table.insert(FuckYouLib.moduleToggles, {btn = MusicSidebarToggle, group = "Music"})
FuckYouLib.registerToggle(MusicSidebarToggle, function() return ToggleState end)
local function refreshMusicToggleText()
    MusicSidebarToggle.Text = "Music: " .. (ToggleState and "ON" or "OFF")
    FuckYouLib.paintToggleBtn(MusicSidebarToggle, ToggleState)
end
local function setMusicState(st)
    ToggleState = st and true or false
    if ToggleState then
        rebuildParts(Settings.Parts)
        if musicSound then musicSound:Play() end
        if playingLabel then playingLabel.Text = "Script Enabled" end
    else
        if musicSound then musicSound:Stop() end
        Parts:ClearAllChildren()
        if lineProgress then lineProgress.Size = UDim2.new(0,0,0,6) end
        if timePosLabel then timePosLabel.Text = "0:00" end
        if playingLabel then playingLabel.Text = "Script Disabled" end
    end
    refreshMusicToggleText()
end
refreshMusicToggleText()
MusicSidebarToggle.MouseButton1Click:Connect(function() setMusicState(not ToggleState) end)

UserInputService.InputBegan:Connect(function(inp, processed)
    if processed then return end
    if inp.UserInputType == Enum.UserInputType.Keyboard then
        local name = inp.KeyCode.Name
        if unlocked and MusicKeybinds.Toggle ~= "" and name == MusicKeybinds.Toggle then
            setMusicState(not ToggleState)
        end
    end
end)

ScreenGui.Destroying:Connect(function()
    pcall(function()
        setMusicState(false)
    end)
end)

FuckYouLib.registerKeyListProvider("Music", function()
    local rows = {}
    if not ToggleState then return rows end
    local label = "ON"
    if musicSound and musicSound.Parent and musicSound.IsPlaying then
        local tr = DataStructure.Categories[currentCategory] and DataStructure.Categories[currentCategory][currentSelectedId]
        if tr and tr.name then label = tr.name
        elseif currentSelectedId ~= "" then label = currentSelectedId
        elseif soundIdBox and soundIdBox.Text ~= "" then label = soundIdBox.Text end
    end
    table.insert(rows, {"MUSIC", label})
    return rows
end)

print("MusicModule loaded")