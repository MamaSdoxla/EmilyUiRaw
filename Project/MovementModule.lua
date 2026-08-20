--// MovementModule.lua
local function initMovementModule(Library)
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer

    local movementTabs = {}
    local function addMovementTab(name, builder)
        local frame = Library.create("Frame", {Name = "Tab" .. name, Parent = Library.Containment, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false})
        local sf = Library.create("ScrollingFrame", {Parent = frame, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 0)})
        local tl = Library.create("UIListLayout", {Parent = sf, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
        Library.create("UIPadding", {Parent = sf, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)})
        tl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() sf.CanvasSize = UDim2.new(0, 0, 0, tl.AbsoluteContentSize.Y + 20) end)
        builder(sf)
        local btn = Library.create("TextButton", {Name = "MoveBtn_" .. name, Parent = Library.MenuInsided, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 400 + #movementTabs, Visible = false, BackgroundColor3 = Library.uiColor_ButtonColor, BorderColor3 = Library.COL_BORDER, TextColor3 = Library.uiColor_TextColor, Text = name, Font = Library.FONT, TextSize = 12, TextWrapped = true})
        local entry = {Frame = frame, Name = name, Button = btn}
        table.insert(movementTabs, entry); table.insert(Library.themeElements.Buttons, btn); table.insert(Library.themeElements.Texts, btn)
        return entry
    end

    local Settings = {CircleRadius = 5, CircleThickness = 0.3, CircleHeight = 0.15, CircleTransparency = 0.35, CircleMode = "Solid", PathMode = "Solid", PathTransparency = 0.25, PathPointSize = 0.35, TrailDistance = 10, TrailStep = 0, ShowPathPlayback = true, MinRecordDistance = 0.05, MinRecordTime = 0.08, ShowLabels = true, TextHeight = 4, TextTransparency = 0, TextDistance = 60, LabelMode = "Solid", PromptEnabled = true, PromptDistance = 12, PlaybackSpeed = 1, Loop = false, Legit = true}
    local Keybinds = {Menu = "RightShift", Record = "R", Play = "P", Prompt = "E"}
    local MovementEnabled = false

    local function buildMainTab(parent)
        Library.createSection(parent, "MOVEMENT RECORDER")
        local statusLabel = Library.createLabel(parent, "Ready.")
        Library.createSection(parent, "Recording")
        Library.createContentButton(parent, "Start Recording", function() statusLabel.Text = "Recording..." end)
        Library.createContentButton(parent, "Stop Recording", function() statusLabel.Text = "Stopped." end)
        Library.createSection(parent, "Playback")
        Library.createContentButton(parent, "Play Selected", function() end)
        Library.createContentButton(parent, "Stop Playback", function() end)
        Library.createSection(parent, "Selected")
        Library.createLabel(parent, "Nothing selected.")
    end

    local function buildRecordsTab(parent)
        Library.createSection(parent, "RECORDINGS")
        local recList = Library.create("ScrollingFrame", {Parent = parent, Size = UDim2.new(1, 0, 0, 220), BackgroundColor3 = Library.uiColor_TextBoxColor, BorderColor3 = Library.COL_BORDER, ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 0)})
        table.insert(Library.themeElements.TextBoxes, recList)
        local layout = Library.create("UIListLayout", {Parent = recList, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3)})
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() recList.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8) end)
    end

    local function buildCategoriesTab(parent)
        Library.createSection(parent, "CATEGORIES"); Library.createLabel(parent, "Manage recording categories")
    end

    local function buildColorsTab(parent)
        Library.createSection(parent, "COLORS"); Library.createLabel(parent, "Configure circle/path/label colors")
    end

    local function buildSettingsTab(parent)
        Library.createSection(parent, "RECORDING"); Library.createLabel(parent, "Min Record Distance: " .. Settings.MinRecordDistance)
        Library.createSection(parent, "CIRCLE"); Library.createLabel(parent, "Circle Radius: " .. Settings.CircleRadius)
        Library.createSection(parent, "PLAYBACK"); Library.createLabel(parent, "Playback Speed: " .. Settings.PlaybackSpeed)
    end

    local function buildKeybindsTab(parent)
        Library.createSection(parent, "KEYBINDS")
        Library.createLabel(parent, "Record: " .. Keybinds.Record)
        Library.createLabel(parent, "Play: " .. Keybinds.Play)
        Library.createLabel(parent, "Prompt: " .. Keybinds.Prompt)
    end

    addMovementTab("Main", buildMainTab)
    addMovementTab("Records", buildRecordsTab)
    addMovementTab("Categories", buildCategoriesTab)
    addMovementTab("Colors", buildColorsTab)
    addMovementTab("Settings", buildSettingsTab)
    addMovementTab("Keybinds", buildKeybindsTab)

    local MovementSidebarToggle = Library.create("TextButton", {Name = "MToggle_Movement", Parent = Library.MenuInsided, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 490, Visible = false, BorderColor3 = Library.COL_BORDER, Text = "Movement: OFF", Font = Library.FONT, TextSize = 12, TextWrapped = true, BackgroundTransparency = 1 - Library.uiGuiOpacity})
    table.insert(Library.themeElements.CustomButtons, MovementSidebarToggle); table.insert(Library.moduleToggles, {btn = MovementSidebarToggle, group = "Movement"})
    Library.registerToggle(MovementSidebarToggle, function() return MovementEnabled end)

    local function setMovementEnabled(v)
        MovementEnabled = v and true or false
        MovementSidebarToggle.Text = "Movement: " .. (MovementEnabled and "ON" or "OFF")
        Library.paintToggleBtn(MovementSidebarToggle, MovementEnabled)
    end
    MovementSidebarToggle.MouseButton1Click:Connect(function() setMovementEnabled(not MovementEnabled) end)

    Library.registerKeyListProvider("Movement", function() local rows = {}; if not MovementEnabled then return rows end; table.insert(rows, {"MOVEMENT", "ON"}); return rows end)
    Library.ScreenGui.Destroying:Connect(function() pcall(function() setMovementEnabled(false) end) end)

    return {Tabs = movementTabs, Gather = function() return {Enabled = MovementEnabled, Settings = Settings, Keybinds = Keybinds} end, Apply = function(cfg) if type(cfg) == "table" and cfg.Enabled ~= nil then setMovementEnabled(cfg.Enabled) end end, Reset = function() setMovementEnabled(false) end}
end
return initMovementModule