--// MusicModule.lua
local function initMusicModule(Library)
    local SoundService = game:GetService("SoundService")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local musicTabs = {}
    local function addMusicTab(name, builder)
        local frame = Library.create("Frame", {Name = "Tab" .. name, Parent = Library.Containment, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false})
        builder(frame)
        local btn = Library.create("TextButton", {Name = "MBtn_" .. name, Parent = Library.MenuInsided, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 200 + #musicTabs, Visible = false, BackgroundColor3 = Library.uiColor_ButtonColor, BorderColor3 = Library.COL_BORDER, TextColor3 = Library.uiColor_TextColor, Text = name, Font = Library.FONT, TextSize = 12, TextWrapped = true})
        local entry = {Frame = frame, Name = name, Button = btn}
        table.insert(musicTabs, entry); table.insert(Library.themeElements.Buttons, btn); table.insert(Library.themeElements.Texts, btn)
        return entry
    end

    local ToggleState = false
    local Settings = {Body = 0, Angle = 25, Goal = 0.30, Split = 1, Parts = 2, Disposition = 3, Power = 400, Material = "Neon", Rainbow = true, StaticColor = Color3.new(1, 1, 1), Transparency = 0}
    local Parts = Instance.new("Model"); Parts.Name = "MusicParts"
    local musicSound = nil; local currentSelectedId = ""; local currentCategory = "Default"

    local function getRoot() return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") end
    local function rebuildParts(n)
        Settings.Parts = tonumber(n) or 2; Parts:ClearAllChildren()
        local root = getRoot(); if not root or not ToggleState then return end
        for i = 1, Settings.Parts do
            local p = Instance.new("Part", Parts); p.Color = Settings.StaticColor; p.Transparency = Settings.Transparency
            p.Anchored = true; p.CanCollide = false; p.Material = Enum.Material[Settings.Material] or Enum.Material.Neon
            p.Size = Vector3.new(0.2, 0.2, 0.2); p.CFrame = root.CFrame * CFrame.new(0, Settings.Body, 0)
        end
    end
    local function makeMusicSound(id)
        local s = Instance.new("Sound", Library.ScreenGui); s.Name = "Music"; s.SoundId = "rbxassetid://" .. (id or "1")
        s.Looped = true; s.PlaybackSpeed = 1; s.Volume = 1; return s
    end

    local function buildHome(parent)
        local sf = Library.create("ScrollingFrame", {Parent = parent, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 0)})
        local inner = Library.create("Frame", {Parent = sf, Size = UDim2.new(1, 0, 0, 200), BackgroundTransparency = 1})
        local layout = Library.create("UIListLayout", {Parent = inner, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
        Library.create("UIPadding", {Parent = inner, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 10)})
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() inner.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y + 20); sf.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20) end)
        
        Library.createSection(inner, "HOME")
        local soundIdBox = Library.createTextBox(inner, "Sound ID", Library.FONT)
        local playBtn = Library.createContentButton(inner, "PLAY", function()
            if not ToggleState then return end
            if not musicSound or musicSound.Parent ~= Library.ScreenGui then musicSound = makeMusicSound(soundIdBox.Text ~= "" and soundIdBox.Text or "1") end
            musicSound.SoundId = "rbxassetid://" .. (soundIdBox.Text ~= "" and soundIdBox.Text or "1")
            musicSound.TimePosition = 0; musicSound:Play()
            
            -- FIX: Остановка музыки через 2 секунды после запуска
            task.delay(2, function()
                if musicSound and musicSound.IsPlaying then
                    musicSound:Stop()
                end
            end)
        end)
        Library.createContentButton(inner, "STOP", function() if musicSound then musicSound:Stop() end end)
    end

    local function buildMusic(parent)
        local sf = Library.create("ScrollingFrame", {Parent = parent, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 0)})
        local inner = Library.create("Frame", {Parent = sf, Size = UDim2.new(1, 0, 0, 200), BackgroundTransparency = 1})
        local layout = Library.create("UIListLayout", {Parent = inner, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
        Library.create("UIPadding", {Parent = inner, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 10)})
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() inner.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y + 20); sf.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20) end)
        Library.createSection(inner, "MUSIC LIBRARY"); Library.createLabel(inner, "Categories and tracks")
    end

    local function buildSettings(parent)
        local sf = Library.create("ScrollingFrame", {Parent = parent, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 0)})
        local inner = Library.create("Frame", {Parent = sf, Size = UDim2.new(1, 0, 0, 200), BackgroundTransparency = 1})
        local layout = Library.create("UIListLayout", {Parent = inner, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
        Library.create("UIPadding", {Parent = inner, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 10)})
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() inner.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y + 20); sf.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20) end)
        Library.createSection(inner, "SETTINGS"); Library.createLabel(inner, "Visualizer settings")
    end

    local function buildMaterials(parent)
        local sf = Library.create("ScrollingFrame", {Parent = parent, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 0)})
        local inner = Library.create("Frame", {Parent = sf, Size = UDim2.new(1, 0, 0, 200), BackgroundTransparency = 1})
        local layout = Library.create("UIListLayout", {Parent = inner, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
        Library.create("UIPadding", {Parent = inner, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 10)})
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() inner.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y + 20); sf.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20) end)
        Library.createSection(inner, "MATERIALS")
        for _, mat in ipairs({"Neon", "Plastic", "Glass", "ForceField", "Wood"}) do
            Library.createContentButton(inner, mat, function()
                Settings.Material = mat; for _, c in ipairs(Parts:GetChildren()) do if c:IsA("Part") then c.Material = Enum.Material[mat] or Enum.Material.Neon end end
            end)
        end
    end

    local function buildGrabber(parent)
        local sf = Library.create("ScrollingFrame", {Parent = parent, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 0)})
        local inner = Library.create("Frame", {Parent = sf, Size = UDim2.new(1, 0, 0, 200), BackgroundTransparency = 1})
        local layout = Library.create("UIListLayout", {Parent = inner, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
        Library.create("UIPadding", {Parent = inner, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 10)})
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() inner.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y + 20); sf.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20) end)
        Library.createSection(inner, "GRABBER"); Library.createLabel(inner, "Scan and grab game sounds")
        Library.createContentButton(inner, "Start Scanning", function()
            pcall(function()
                for _, v in ipairs(game:GetDescendants()) do
                    if v:IsA("Sound") and v.IsPlaying and v.SoundId ~= "" then
                        local rawId = v.SoundId:match("%d+")
                        if rawId then table.insert({}, tonumber(rawId)) end -- Simplified
                    end
                end
            end); Library.notify("Grabber", "Scan complete")
        end)
    end

    addMusicTab("Home", buildHome)
    addMusicTab("Music", buildMusic)
    addMusicTab("Settings", buildSettings)
    addMusicTab("Materials", buildMaterials)
    addMusicTab("Grabber", buildGrabber)

    local MusicSidebarToggle = Library.create("TextButton", {Name = "MToggle_Music", Parent = Library.MenuInsided, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 290, Visible = false, BorderColor3 = Library.COL_BORDER, Text = "Music: OFF", Font = Library.FONT, TextSize = 12, TextWrapped = true, BackgroundTransparency = 1 - Library.uiGuiOpacity})
    table.insert(Library.themeElements.CustomButtons, MusicSidebarToggle); table.insert(Library.moduleToggles, {btn = MusicSidebarToggle, group = "Music"})
    Library.registerToggle(MusicSidebarToggle, function() return ToggleState end)

    local function setMusicState(st)
        ToggleState = st and true or false
        if ToggleState then rebuildParts(Settings.Parts); if musicSound then musicSound:Play() end
        else if musicSound then musicSound:Stop() end; Parts:ClearAllChildren() end
        MusicSidebarToggle.Text = "Music: " .. (ToggleState and "ON" or "OFF")
        Library.paintToggleBtn(MusicSidebarToggle, ToggleState)
    end
    MusicSidebarToggle.MouseButton1Click:Connect(function() setMusicState(not ToggleState) end)
    Library.ScreenGui.Destroying:Connect(function() pcall(function() setMusicState(false) end) end)
    Library.registerKeyListProvider("Music", function() local rows = {}; if not ToggleState then return rows end; table.insert(rows, {"MUSIC", "ON"}); return rows end)

    return {Tabs = musicTabs}
end
return initMusicModule