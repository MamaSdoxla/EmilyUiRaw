-- Library.lua
local Library = {}

local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")

local COL_BG = Color3.fromRGB(12, 12, 12)
local COL_BORDER = Color3.fromRGB(22, 22, 22)
local COL_TEXT = Color3.fromRGB(139, 135, 127)
local COL_TEXTBOX = Color3.fromRGB(18, 18, 18)
local FONT = Enum.Font.SpecialElite

local currentToggleKey = Enum.KeyCode.P
local uiColor_MainWindow = COL_BG
local uiColor_TopBar = COL_BG
local uiColor_SideBar = COL_BG
local uiColor_TextColor = COL_TEXT
local uiColor_ButtonColor = COL_BG
local uiColor_TextBoxColor = COL_TEXTBOX
local uiColor_ToggleOnText = Color3.fromRGB(100, 255, 100)
local uiColor_ToggleOffText = Color3.fromRGB(255, 100, 100)
local uiGuiOpacity = 1
local uiImageOpacity = 1
local uiBlurSize = 0
local uiFitMode = "Fill"
local uiBackgroundFile = ""
local uiCollapsed = false
local unlocked = false
local cachedKeyResponse = nil
local currentKeyData = { group = "Free", daysLeft = "Infinity" }

local themeElements = { MainWindow = {}, TopBars = {}, SideBars = {}, Texts = {}, Buttons = {}, TextBoxes = {}, FillBars = {}, CustomButtons = {} }
local moduleToggles = {}
local toggleRegistry = {}
local VisualsAPI = nil
local AimAPI = nil
local MovementAPI = nil
local KeyListAPI = nil
local MusicKeybinds = { Toggle = "" }
local keyListProviders = {}

local function registerKeyListProvider(group, fn)
    keyListProviders[group] = fn
end

local function scaleColor(c, f)
    return Color3.fromRGB(math.clamp(c.R*255*f,0,255), math.clamp(c.G*255*f,0,255), math.clamp(c.B*255*f,0,255))
end

local function paintToggleBtn(btn, on)
    if on then
        btn.BackgroundColor3 = scaleColor(uiColor_ToggleOnText, 0.35)
        btn.TextColor3 = uiColor_ToggleOnText
    else
        btn.BackgroundColor3 = scaleColor(uiColor_ToggleOffText, 0.35)
        btn.TextColor3 = uiColor_ToggleOffText
    end
end

local function registerToggle(btn, getState)
    toggleRegistry[btn] = getState
    paintToggleBtn(btn, getState() and true or false)
end

local tabs = {}
local updateTabButtonsTheme, applyTheme

local function notify(title, text)
    task.spawn(function()
        local notificationData = { Title = title, Text = text, Duration = 15 }
        local coreSuccess = false
        for _ = 1, 10 do
            coreSuccess = pcall(function() StarterGui:SetCore("SendNotification", notificationData) end)
            if coreSuccess then return end
            task.wait(0.2)
        end
        pcall(function()
            local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)
            if not playerGui then return end
            local gui = Instance.new("ScreenGui")
            gui.Name = "FallbackNotification"
            gui.ResetOnSpawn = false
            gui.IgnoreGuiInset = true
            gui.Parent = playerGui
            local main = Instance.new("Frame")
            main.AnchorPoint = Vector2.new(1, 1)
            main.Position = UDim2.new(1, -16, 1, -16)
            main.Size = UDim2.new(0, 300, 0, 64)
            main.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
            main.BorderColor3 = Color3.fromRGB(22, 22, 22)
            main.BorderSizePixel = 1
            main.Parent = gui
            local titleLabel = Instance.new("TextLabel")
            titleLabel.Size = UDim2.new(1, -16, 0, 20)
            titleLabel.Position = UDim2.new(0, 8, 0, 6)
            titleLabel.BackgroundTransparency = 1
            titleLabel.Text = title
            titleLabel.Font = Enum.Font.SpecialElite
            titleLabel.TextSize = 14
            titleLabel.TextXAlignment = Enum.TextXAlignment.Left
            titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            titleLabel.Parent = main
            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, -16, 0, 30)
            textLabel.Position = UDim2.new(0, 8, 0, 26)
            textLabel.BackgroundTransparency = 1
            textLabel.Text = text
            textLabel.Font = Enum.Font.SpecialElite
            textLabel.TextSize = 12
            textLabel.TextXAlignment = Enum.TextXAlignment.Left
            textLabel.TextYAlignment = Enum.TextYAlignment.Top
            textLabel.TextWrapped = true
            textLabel.TextColor3 = Color3.fromRGB(139, 135, 127)
            textLabel.Parent = main
            task.delay(notificationData.Duration or 15, function() gui:Destroy() end)
        end)
    end)
end

local function create(className, properties)
    local inst = Instance.new(className)
    for k, v in pairs(properties) do inst[k] = v end
    return inst
end

local configPath = "EmilyUi/Config.json"
local lastAutoConfigSave = 0
local configSaveListeners = {}

local function registerConfigSaveListener(fn)
    if typeof(fn) == "function" then table.insert(configSaveListeners, fn) end
end

local function runConfigSaveListeners()
    for _, fn in ipairs(configSaveListeners) do pcall(fn) end
end

local visualSaveQueued = false

local function autoSaveConfig(force)
    if not unlocked then return end
    if not force and os.clock() - lastAutoConfigSave < 0.5 then return end
    lastAutoConfigSave = os.clock()
    pcall(saveConfig)
    runConfigSaveListeners()
end

local function queueVisualSave()
    if visualSaveQueued then return end
    visualSaveQueued = true
    task.delay(1, function()
        visualSaveQueued = false
        if unlocked and autoSaveConfig then autoSaveConfig(true) end
    end)
end

local function saveConfig()
    local config = {
        ToggleKey = currentToggleKey.Name,
        MainWindowColor = {uiColor_MainWindow.R, uiColor_MainWindow.G, uiColor_MainWindow.B},
        TopBarColor = {uiColor_TopBar.R, uiColor_TopBar.G, uiColor_TopBar.B},
        SideBarColor = {uiColor_SideBar.R, uiColor_SideBar.G, uiColor_SideBar.B},
        TextColor = {uiColor_TextColor.R, uiColor_TextColor.G, uiColor_TextColor.B},
        ButtonColor = {uiColor_ButtonColor.R, uiColor_ButtonColor.G, uiColor_ButtonColor.B},
        TextBoxColor = {uiColor_TextBoxColor.R, uiColor_TextBoxColor.G, uiColor_TextBoxColor.B},
        ToggleOnColor = {uiColor_ToggleOnText.R, uiColor_ToggleOnText.G, uiColor_ToggleOnText.B},
        ToggleOffColor = {uiColor_ToggleOffText.R, uiColor_ToggleOffText.G, uiColor_ToggleOffText.B},
        GuiOpacity = uiGuiOpacity, ImageOpacity = uiImageOpacity, Blur = uiBlurSize,
        Fit = uiFitMode, BackgroundFile = uiBackgroundFile,
    }
    if VisualsAPI and VisualsAPI.Gather then config.Visuals = VisualsAPI.Gather() end
    if AimAPI and AimAPI.Gather then config.Aim = AimAPI.Gather() end
    if MovementAPI and MovementAPI.Gather then config.Movement = MovementAPI.Gather() end
    if KeyListAPI and KeyListAPI.Gather then config.KeyList = KeyListAPI.Gather() end
    local success, json = pcall(function() return HttpService:JSONEncode(config) end)
    if success then
        if makefolder then pcall(function() makefolder("EmilyUi") end) end
        if writefile then pcall(function() writefile(configPath, json) end) end
    end
end

local function loadConfig()
    if isfile and isfile(configPath) and readfile then
        local success, json = pcall(function() return readfile(configPath) end)
        if success and json then
            local ok, config = pcall(function() return HttpService:JSONDecode(json) end)
            if ok and config then
                if config.ToggleKey then pcall(function() currentToggleKey = Enum.KeyCode[config.ToggleKey] end) end
                if config.MainWindowColor then uiColor_MainWindow = Color3.new(unpack(config.MainWindowColor)) end
                if config.TopBarColor then uiColor_TopBar = Color3.new(unpack(config.TopBarColor)) end
                if config.SideBarColor then uiColor_SideBar = Color3.new(unpack(config.SideBarColor)) end
                if config.TextColor then uiColor_TextColor = Color3.new(unpack(config.TextColor)) end
                if config.ButtonColor then uiColor_ButtonColor = Color3.new(unpack(config.ButtonColor)) end
                if config.TextBoxColor then uiColor_TextBoxColor = Color3.new(unpack(config.TextBoxColor)) end
                if config.GuiOpacity then uiGuiOpacity = math.clamp(config.GuiOpacity, 0.25, 1) end
                if config.ImageOpacity then uiImageOpacity = math.clamp(config.ImageOpacity, 0, 1) end
                if config.Blur then uiBlurSize = math.clamp(config.Blur, 0, 24) end
                if config.Fit then uiFitMode = config.Fit end
                if config.BackgroundFile ~= nil then uiBackgroundFile = config.BackgroundFile end
                if unlocked then
                    if config.Visuals and VisualsAPI and VisualsAPI.Apply then VisualsAPI.Apply(config.Visuals) end
                    if config.Aim and AimAPI and AimAPI.Apply then AimAPI.Apply(config.Aim) end
                    if config.Movement and MovementAPI and MovementAPI.Apply then MovementAPI.Apply(config.Movement) end
                end
            end
        end
    end
end

updateTabButtonsTheme = function()
    for _, tab in ipairs(tabs) do
        if tab.Button then
            if tab.Frame.Visible then
                tab.Button.BackgroundColor3 = uiColor_ButtonColor
                tab.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                local c = uiColor_ButtonColor
                tab.Button.BackgroundColor3 = Color3.fromRGB(math.max(c.R*255-10, 0), math.max(c.G*255-10, 0), math.max(c.B*255-10, 0))
                tab.Button.TextColor3 = uiColor_TextColor
            end
        end
    end
end

applyTheme = function()
    local trans = 1 - uiGuiOpacity
    local function applyList(key, fn)
        local alive = {}
        for _, el in ipairs(themeElements[key]) do
            if typeof(el) == "Instance" and el.Parent then
                fn(el)
                table.insert(alive, el)
            end
        end
        themeElements[key] = alive
    end
    applyList("MainWindow", function(el) el.BackgroundColor3 = uiColor_MainWindow; el.BackgroundTransparency = trans end)
    applyList("TopBars", function(el) el.BackgroundColor3 = uiColor_TopBar; el.BackgroundTransparency = trans end)
    applyList("SideBars", function(el) el.BackgroundColor3 = uiColor_SideBar; el.BackgroundTransparency = trans end)
    applyList("Texts", function(el) el.TextColor3 = uiColor_TextColor end)
    applyList("Buttons", function(el) el.BackgroundColor3 = uiColor_ButtonColor; el.BackgroundTransparency = trans end)
    applyList("CustomButtons", function(el) el.BackgroundTransparency = trans end)
    applyList("TextBoxes", function(el) el.BackgroundColor3 = uiColor_TextBoxColor; el.BackgroundTransparency = trans end)
    applyList("FillBars", function(el) el.BackgroundColor3 = uiColor_TextColor end)
    for btn, getState in pairs(toggleRegistry) do
        if typeof(btn) == "Instance" and btn.Parent then
            paintToggleBtn(btn, getState() and true or false)
        else
            toggleRegistry[btn] = nil
        end
    end
    updateTabButtonsTheme()
end

local ScreenGui = create("ScreenGui", {Name = "FuckYouGui", ResetOnSpawn = false, Parent = LocalPlayer:WaitForChild("PlayerGui")})

local FuckYou = create("Frame", {
    Name = "FuckYou", Parent = ScreenGui,
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 940, 0, 510),
    ClipsDescendants = true, Visible = false,
    BackgroundColor3 = uiColor_MainWindow, BorderColor3 = COL_BORDER, BorderSizePixel = 1
})
table.insert(themeElements.MainWindow, FuckYou)

local BackgroundImage = create("ImageLabel", {
    Name = "BackgroundImage", Parent = FuckYou,
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1, Image = "", Visible = false,
    ScaleType = Enum.ScaleType.Stretch, ImageTransparency = 0, ZIndex = 0,
})

local BG_FOLDER = "EmilyUi/FuckYou/Background"
if makefolder then pcall(function()
    if not isfolder("EmilyUi/FuckYou") then makefolder("EmilyUi/FuckYou") end
    if not isfolder(BG_FOLDER) then makefolder(BG_FOLDER) end
end) end

local blurEffect = Instance.new("BlurEffect")
blurEffect.Name = "FuckYouBlur"
blurEffect.Size = 0
blurEffect.Enabled = false

local function updateBlur()
    if FuckYou.Parent and FuckYou.Visible and uiBlurSize > 0 then
        blurEffect.Parent = Lighting
        blurEffect.Size = uiBlurSize
        blurEffect.Enabled = true
    else
        blurEffect.Enabled = false
        blurEffect.Parent = nil
    end
end

FuckYou:GetPropertyChangedSignal("Visible"):Connect(updateBlur)
ScreenGui.Destroying:Connect(function() blurEffect.Enabled = false; blurEffect.Parent = nil end)

local function fileExists(path)
    if typeof(isfile) ~= "function" then return true end
    local ok, exists = pcall(isfile, path)
    return ok and exists == true
end

local function customAsset(path)
    if typeof(path) ~= "string" or path == "" then return nil end
    if typeof(isfile) == "function" and not fileExists(path) then return nil end
    if typeof(getcustomasset) == "function" then
        local ok, asset = pcall(getcustomasset, path)
        if ok and typeof(asset) == "string" and asset ~= "" then return asset end
    end
    if typeof(GetCustomAsset) == "function" then
        local ok, asset = pcall(GetCustomAsset, path)
        if ok and typeof(asset) == "string" and asset ~= "" then return asset end
    end
    return nil
end

local function getBackgroundFiles()
    local out = {}
    if listfiles then
        local ok, files = pcall(function() return listfiles(BG_FOLDER) end)
        if ok and files then
            for _, p in ipairs(files) do
                local name = p:match("([^/\\]+)$")
                local ext = name and name:lower():match("%.(%w+)$")
                if ext == "png" or ext == "jpg" or ext == "jpeg" or ext == "webp" then table.insert(out, name) end
            end
            table.sort(out)
        end
    end
    return out
end

local FIT_MAP = {
    Fill = Enum.ScaleType.Crop, Fit = Enum.ScaleType.Fit, Stretch = Enum.ScaleType.Stretch,
    Tile = Enum.ScaleType.Tile, Center = Enum.ScaleType.Crop, Zoom = Enum.ScaleType.Crop,
    Slice = Enum.ScaleType.Slice, Crop = Enum.ScaleType.Crop,
}

local function getScaleType(name)
    if FIT_MAP[name] then return FIT_MAP[name] end
    local ok, val = pcall(function() return Enum.ScaleType[name] end)
    if ok and val then return val end
    return Enum.ScaleType.Stretch
end

local function applyBackground()
    local asset = nil
    if typeof(uiBackgroundFile) ~= "string" then uiBackgroundFile = "" end
    if uiBackgroundFile ~= "" and not uiCollapsed then
        local path = BG_FOLDER .. "/" .. uiBackgroundFile
        if typeof(isfile) == "function" then
            local ok, exists = pcall(isfile, path)
            if ok and not exists then
                uiBackgroundFile = ""
                pcall(function() saveConfig() end)
            else
                asset = customAsset(path)
            end
        else
            asset = customAsset(path)
        end
    end
    if asset and not uiCollapsed then
        BackgroundImage.Image = asset
        BackgroundImage.ScaleType = getScaleType(uiFitMode)
        BackgroundImage.ImageTransparency = 1 - uiImageOpacity
        BackgroundImage.Visible = true
    else
        BackgroundImage.Visible = false
        BackgroundImage.Image = ""
    end
end

applyBackground()
updateBlur()

local TopBar = create("Frame", {Name = "TopBar", Parent = FuckYou, Size = UDim2.new(1, 0, 0, 45), BackgroundColor3 = uiColor_TopBar, BorderSizePixel = 0, ZIndex = 2})
table.insert(themeElements.TopBars, TopBar)

local Title = create("TextLabel", {Name = "Name", Parent = TopBar, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "Fuck you! v1.2", TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT, ZIndex = 3})
table.insert(themeElements.Texts, Title)

local function makeTopBtn(symbol, offset)
    local b = create("TextButton", {
        Name = symbol, Parent = TopBar,
        Position = UDim2.new(1, -45 * offset, 0, 0), Size = UDim2.new(0, 45, 0, 45),
        BackgroundColor3 = uiColor_TopBar, BorderColor3 = COL_BORDER,
        Text = symbol, TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT, ZIndex = 3
    })
    table.insert(themeElements.TopBars, b)
    table.insert(themeElements.Texts, b)
    b.MouseEnter:Connect(function()
        local c = b.BackgroundColor3
        b.BackgroundColor3 = Color3.fromRGB(math.min(c.R*255+10,255), math.min(c.G*255+10,255), math.min(c.B*255+10,255))
    end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = uiColor_TopBar end)
    return b
end

local Minus = makeTopBtn("-", 3)
local Equal = makeTopBtn("=", 2)
local X = makeTopBtn("X", 1)

local SideBard = create("Frame", {Name = "SideBard", Parent = FuckYou, Position = UDim2.new(0, 0, 0, 45), Size = UDim2.new(0, 65, 1, -45), BackgroundColor3 = uiColor_SideBar, BorderSizePixel = 0, ZIndex = 2})
table.insert(themeElements.SideBars, SideBard)

local function makeSideBtn(text, offsetY)
    local b = create("TextButton", {
        Name = text, Parent = SideBard,
        Position = UDim2.new(0, 0, 0, offsetY), Size = UDim2.new(1, 0, 0, 59),
        BackgroundColor3 = uiColor_SideBar, BorderColor3 = COL_BORDER,
        Text = text, TextColor3 = uiColor_TextColor, TextSize = 12, Font = FONT, ZIndex = 3
    })
    table.insert(themeElements.SideBars, b)
    table.insert(themeElements.Texts, b)
    return b
end

local EmilyUi = makeSideBtn("EmilyUi", 0)
local Desync = makeSideBtn("Desync", 59)
local Music = makeSideBtn("Music", 118)
local Aim = makeSideBtn("Aim", 177)

local MenuInsided = create("ScrollingFrame", {Name = "MenuInsided", Parent = FuckYou, Position = UDim2.new(0, 65, 0, 45), Size = UDim2.new(0, 105, 1, -45), BackgroundColor3 = uiColor_SideBar, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = COL_BORDER, CanvasSize = UDim2.new(0, 0, 0, 0), ClipsDescendants = true, ZIndex = 2})
table.insert(themeElements.SideBars, MenuInsided)

local menuLayout = create("UIListLayout", {Parent = MenuInsided, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)})
create("UIPadding", {Parent = MenuInsided, PaddingTop = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)})
menuLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    MenuInsided.CanvasSize = UDim2.new(0, 0, 0, menuLayout.AbsoluteContentSize.Y + 10)
end)

local Containment = create("Frame", {Name = "Containment", Parent = FuckYou, Position = UDim2.new(0, 170, 0, 45), Size = UDim2.new(1, -170, 1, -45), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2})

local function makeLine(name, pos, size)
    return create("Frame", {Name = name, Parent = FuckYou, Position = pos, Size = size, BackgroundColor3 = COL_BORDER, BorderSizePixel = 0, ZIndex = 1})
end
makeLine("SepH", UDim2.new(0, 0, 0, 45), UDim2.new(1, 0, 0, 1))
makeLine("SepV1", UDim2.new(0, 65, 0, 46), UDim2.new(0, 1, 1, -46))
makeLine("SepV2", UDim2.new(0, 170, 0, 46), UDim2.new(0, 1, 1, -46))

local function createTabContentFrame(name)
    local sf = create("ScrollingFrame", {Name = name, Parent = Containment, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = COL_BORDER, CanvasSize = UDim2.new(0, 0, 0, 0), Visible = false, ZIndex = 2})
    local tl = create("UIListLayout", {Parent = sf, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
    create("UIPadding", {Parent = sf, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)})
    tl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sf.CanvasSize = UDim2.new(0, 0, 0, tl.AbsoluteContentSize.Y + 20)
    end)
    return sf
end

local tabFrames = {
    Main = createTabContentFrame("TabMain"),
    Universal = createTabContentFrame("TabUniversal"),
    Character = createTabContentFrame("TabCharacter"),
    Players = createTabContentFrame("TabPlayers"),
    Visuals = createTabContentFrame("TabVisuals"),
    Utilities = createTabContentFrame("TabUtilities"),
    Server = createTabContentFrame("TabServer"),
    Games = createTabContentFrame("TabGames"),
    Scripts = createTabContentFrame("TabScripts"),
    Hubs = createTabContentFrame("TabScriptHubs"),
    Guis = createTabContentFrame("TabGuis"),
    Anims = createTabContentFrame("TabAnimations"),
    KeyList = createTabContentFrame("TabKeyList"),
    Settings = createTabContentFrame("TabSettings")
}

-- ЗАГОЛОВКИ СЕКЦИЙ ПО ЦЕНТРУ
local function createSection(parent, text)
    local lbl = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1,
        Text = text, TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = parent
    })
    table.insert(themeElements.Texts, lbl)
    return lbl
end

local function createLabel(parent, text)
    local lbl = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1,
        Text = text, TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = parent
    })
    table.insert(themeElements.Texts, lbl)
    return lbl
end

local function createContentButton(parent, text, callback, customColor)
    local defaultColor = customColor or uiColor_ButtonColor
    local btn = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = defaultColor, BorderColor3 = COL_BORDER,
        TextColor3 = uiColor_TextColor, Text = text, Font = FONT, TextSize = 13,
        BackgroundTransparency = 1 - uiGuiOpacity, Parent = parent
    })
    if not customColor then table.insert(themeElements.Buttons, btn) end
    table.insert(themeElements.Texts, btn)
    btn.MouseEnter:Connect(function()
        local c = btn.BackgroundColor3
        btn.BackgroundColor3 = Color3.fromRGB(math.min(c.R*255+10,255), math.min(c.G*255+10,255), math.min(c.B*255+10,255))
    end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = customColor or uiColor_ButtonColor end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function createTextBox(parent, placeholder, font)
    local box = create("TextBox", {
        BackgroundColor3 = uiColor_TextBoxColor, BorderColor3 = COL_BORDER,
        TextColor3 = uiColor_TextColor, PlaceholderColor3 = Color3.fromRGB(90, 90, 90),
        PlaceholderText = placeholder, Text = "", TextSize = 13, Font = font or FONT,
        ClearTextOnFocus = false, BackgroundTransparency = 1 - uiGuiOpacity, Parent = parent
    })
    table.insert(themeElements.Texts, box)
    table.insert(themeElements.TextBoxes, box)
    return box
end

local function copyDiscord()
    if setclipboard then setclipboard("https://discord.gg/75Dz8T9hHR") end
    notify("Discord", "The link is copied")
end

-- ПРОФИЛЬ ИГРОКА В MAIN TAB
local UserProfilePanel = create("Frame", {
    Name = "UserProfilePanel", Parent = tabFrames.Main,
    Size = UDim2.new(1, 0, 0, 60), LayoutOrder = -1,
    BackgroundColor3 = uiColor_SideBar, BorderColor3 = COL_BORDER
})
table.insert(themeElements.SideBars, UserProfilePanel)

local UserImage = create("ImageLabel", {
    Parent = UserProfilePanel, Position = UDim2.new(0, 10, 0, 10),
    Size = UDim2.new(0, 40, 0, 40), BackgroundTransparency = 1,
    Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"
})
create("UICorner", {Parent = UserImage, CornerRadius = UDim.new(1, 0)})

create("TextLabel", {
    Parent = UserProfilePanel, Position = UDim2.new(0, 60, 0, 6),
    Size = UDim2.new(1, -70, 0, 16), BackgroundTransparency = 1,
    Text = LocalPlayer.DisplayName, TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd
})

local UserKeyTimeLabel = create("TextLabel", {
    Parent = UserProfilePanel, Position = UDim2.new(0, 60, 0, 22),
    Size = UDim2.new(1, -70, 0, 14), BackgroundTransparency = 1,
    Text = "Days left: Inf", TextColor3 = Color3.fromRGB(180, 180, 180),
    TextSize = 12, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left
})
table.insert(themeElements.Texts, UserKeyTimeLabel)

local UserGroupLabel = create("TextLabel", {
    Parent = UserProfilePanel, Position = UDim2.new(0, 60, 0, 38),
    Size = UDim2.new(1, -70, 0, 14), BackgroundTransparency = 1,
    Text = "Group: Free", TextColor3 = Color3.fromRGB(150, 150, 150),
    TextSize = 12, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left
})

RunService.RenderStepped:Connect(function()
    if not FuckYou.Visible then return end
    local group = currentKeyData.group or "Free"
    local wave = math.sin(tick() * 5)
    if group == "Free" then
        UserGroupLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    elseif group == "User" then
        UserGroupLabel.TextColor3 = Color3.fromHSV(0.3 + wave * 0.05, 0.85, 0.95)
    elseif group == "Tester" then
        UserGroupLabel.TextColor3 = Color3.fromHSV(0.6 + wave * 0.05, 0.85, 0.95)
    elseif group == "Coder" then
        UserGroupLabel.TextColor3 = Color3.fromHSV(0.88 + wave * 0.04, 0.85, 0.95)
    else
        UserGroupLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end)

local function updateProfilePanel(group, daysLeft)
    currentKeyData.group = group
    currentKeyData.daysLeft = daysLeft
    UserGroupLabel.Text = "Group: " .. group
    if type(daysLeft) == "number" then
        UserKeyTimeLabel.Text = "Days left: " .. string.format("%.1f", daysLeft)
    else
        UserKeyTimeLabel.Text = "Days left: " .. tostring(daysLeft)
    end
end

-- MAIN TAB CONTENT
createSection(tabFrames.Main, "In case something happens here's a discord server")
createContentButton(tabFrames.Main, "Click to copy Discord Server link", copyDiscord)
createSection(tabFrames.Main, "* Credits to *")
createSection(tabFrames.Main, "RobloxId (DiscordUsername) -> role")
createSection(tabFrames.Main, "WdymGaming (wdymgaming) -> coder")
createSection(tabFrames.Main, "pashajokot (swatwincky) -> tester")
createSection(tabFrames.Main, "BombalMac (bombapc) -> tester")

-- SETTINGS TAB
createSection(tabFrames.Settings, "UI Customization")

local function createSettingsInput(parent, labelText, placeholder, callback)
    local container = create("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = parent})
    local label = create("TextLabel", {
        Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1,
        Text = labelText, TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = container
    })
    table.insert(themeElements.Texts, label)
    local box = createTextBox(container, placeholder, Enum.Font.Code)
    box.Size = UDim2.new(0.5, 0, 0.8, 0)
    box.Position = UDim2.new(0.48, 0, 0.1, 0)
    box.TextSize = 12
    box.FocusLost:Connect(function(enterPressed)
        if enterPressed or box.Text ~= "" then callback(box.Text, box) end
    end)
    return container
end

local function parseRGB(str)
    local r, g, b = string.match(str, "(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
    return r and Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b)) or nil
end

local keyBindContainer = create("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = tabFrames.Settings})
local bindLabel = create("TextLabel", {
    Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1,
    Text = "Menu Toggle Key:", TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = keyBindContainer
})
table.insert(themeElements.Texts, bindLabel)

local keyBindBtn = createContentButton(keyBindContainer, currentToggleKey.Name, function() end)
keyBindBtn.Size = UDim2.new(0.5, 0, 0.8, 0)
keyBindBtn.Position = UDim2.new(0.48, 0, 0.1, 0)
keyBindBtn.TextSize = 12

local listeningForKey = false
keyBindBtn.MouseButton1Click:Connect(function()
    if listeningForKey then return end
    listeningForKey = true
    keyBindBtn.Text = "...Press any Key..."
    local connection
    connection = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            currentToggleKey = input.KeyCode
            keyBindBtn.Text = currentToggleKey.Name
            listeningForKey = false
            saveConfig()
            connection:Disconnect()
        end
    end)
end)

local function formatColor(c)
    return math.floor(c.R*255)..", "..math.floor(c.G*255)..", "..math.floor(c.B*255)
end

local colorSettings = {
    { "Main Window Color: ", formatColor(uiColor_MainWindow), function(c) uiColor_MainWindow = c end},
    { "Top Bar Color: ", formatColor(uiColor_TopBar), function(c) uiColor_TopBar = c end},
    { "Side Bar Color: ", formatColor(uiColor_SideBar), function(c) uiColor_SideBar = c end},
    { "Text Color: ", formatColor(uiColor_TextColor), function(c) uiColor_TextColor = c end},
    { "Button Color: ", formatColor(uiColor_ButtonColor), function(c) uiColor_ButtonColor = c end},
    { "TextBox Background Color: ", formatColor(uiColor_TextBoxColor), function(c) uiColor_TextBoxColor = c end},
    { "Toggle ON Color: ", formatColor(uiColor_ToggleOnText), function(c) uiColor_ToggleOnText = c end},
    { "Toggle OFF Color: ", formatColor(uiColor_ToggleOffText), function(c) uiColor_ToggleOffText = c end}
}

for _, cfg in ipairs(colorSettings) do
    createSettingsInput(tabFrames.Settings, cfg[1], cfg[2], function(text, box)
        local color = parseRGB(text)
        if color then
            cfg[3](color)
            applyTheme()
            saveConfig()
        else
            box.Text = "Invalid format!"
        end
    end)
end

createSection(tabFrames.Settings, "Background & Window")

local function createDropdown(parent, labelText, getOptions, getCurrent, onselect)
    local container = create("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = parent})
    local label = create("TextLabel", {
        Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1,
        Text = labelText, TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = container
    })
    table.insert(themeElements.Texts, label)
    local btn = createContentButton(container, labelText .. ": " .. getCurrent(), function() end)
    btn.Size = UDim2.new(0.5, 0, 0.8, 0)
    btn.Position = UDim2.new(0.48, 0, 0.1, 0)
    btn.TextSize = 12
    local list = create("ScrollingFrame", {
        Parent = container, Size = UDim2.new(0.5, 0, 0, 110),
        Position = UDim2.new(0.48, 0, 0.95, 0),
        BackgroundColor3 = uiColor_TextBoxColor, BorderColor3 = COL_BORDER,
        ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = false, ZIndex = 25
    })
    table.insert(themeElements.TextBoxes, list)
    create("UIListLayout", {Parent = list, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2)})
    btn.MouseButton1Click:Connect(function()
        if list.Visible then list.Visible = false return end
        for _, ch in ipairs(list:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
        local opts = getOptions()
        for _, opt in ipairs(opts) do
            local ob = createContentButton(list, opt, function()
                onselect(opt)
                list.Visible = false
                btn.Text = labelText .. ": " .. getCurrent()
                saveConfig()
            end)
            ob.Size = UDim2.new(1, -4, 0, 24)
            ob.ZIndex = 26
            ob.TextSize = 12
        end
        list.CanvasSize = UDim2.new(0, 0, 0, #opts * 26 + 4)
        list.Visible = true
    end)
end

local function createSlider(parent, labelText, min, max, getval, onval, fmt)
    local container = create("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = parent})
    local label = create("TextLabel", {
        Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1,
        Text = labelText, TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = container
    })
    table.insert(themeElements.Texts, label)
    local valLabel = create("TextLabel", {
        Size = UDim2.new(0.5, 0, 0, 14), Position = UDim2.new(0.48, 0, 0.05, 0),
        BackgroundTransparency = 1, Text = fmt(getval()), TextColor3 = uiColor_TextColor,
        TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Right, Parent = container
    })
    table.insert(themeElements.Texts, valLabel)
    local track = create("TextButton", {
        Size = UDim2.new(0.5, 0, 0, 10), Position = UDim2.new(0.48, 0, 0.55, 0),
        BackgroundColor3 = uiColor_TextBoxColor, BorderColor3 = COL_BORDER,
        Text = " ", Parent = container
    })
    table.insert(themeElements.TextBoxes, track)
    local fill = create("Frame", {
        Size = UDim2.new((getval() - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = uiColor_TextColor, BorderSizePixel = 0, Parent = track
    })
    table.insert(themeElements.FillBars, fill)
    local dragging = false
    local function setFromX(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = math.floor(min + (max - min) * rel + 0.5)
        onval(v)
        fill.Size = UDim2.new((v - min) / (max - min), 0, 1, 0)
        valLabel.Text = fmt(v)
        if queueVisualSave then queueVisualSave() end
        saveConfig()
    end
    track.MouseButton1Down:Connect(function(x) dragging = true; setFromX(x) end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then setFromX(input.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

createDropdown(tabFrames.Settings, "Background Image",
    function()
        local o = {"None"}
        for _, f in ipairs(getBackgroundFiles()) do table.insert(o, f) end
        return o
    end,
    function() return uiBackgroundFile == "" and "None" or uiBackgroundFile end,
    function(opt)
        uiBackgroundFile = (opt == "None") and "" or opt
        applyBackground()
    end)

createSlider(tabFrames.Settings, "Image Opacity", 0, 100,
    function() return math.floor(uiImageOpacity * 100 + 0.5) end,
    function(v) uiImageOpacity = v / 100; BackgroundImage.ImageTransparency = 1 - uiImageOpacity end,
    function(v) return v .. "%" end)

createSlider(tabFrames.Settings, "Blur", 0, 24,
    function() return uiBlurSize end,
    function(v) uiBlurSize = v; updateBlur() end,
    function(v) return v .. "px" end)

-- FIT DROPDOWN
createDropdown(tabFrames.Settings, "Fit",
    function() return {"Fill", "Fit", "Stretch", "Tile", "Center", "Zoom"} end,
    function() return uiFitMode end,
    function(opt) uiFitMode = opt; applyBackground() end)

createSlider(tabFrames.Settings, "Gui Opacity", 25, 100,
    function() return math.floor(uiGuiOpacity * 100 + 0.5) end,
    function(v) uiGuiOpacity = v / 100; applyTheme() end,
    function(v) return v .. "%" end)

-- CONFIGS SECTION
createSection(tabFrames.Settings, "Configs")

local configFolder = "EmilyUi/FuckYou/Configs"
local lastConfigPath = configFolder .. "/last_config.txt"

local function setLastConfigName(name)
    if writefile then pcall(function() writefile(lastConfigPath, name) end) end
end

local function getLastConfigName()
    if readfile and isfile and isfile(lastConfigPath) then
        local ok, name = pcall(function() return readfile(lastConfigPath) end)
        if ok and name and name ~= "" then return name end
    end
    return nil
end

local configNameBox = createTextBox(tabFrames.Settings, "Config name...", FONT)
configNameBox.Size = UDim2.new(1, 0, 0, 30)

local function filesSupported()
    return writefile ~= nil and readfile ~= nil and makefolder ~= nil
end

local function gatherConfig()
    local cfg = {
        ToggleKey = currentToggleKey.Name,
        MainWindowColor = {uiColor_MainWindow.R, uiColor_MainWindow.G, uiColor_MainWindow.B},
        TopBarColor = {uiColor_TopBar.R, uiColor_TopBar.G, uiColor_TopBar.B},
        SideBarColor = {uiColor_SideBar.R, uiColor_SideBar.G, uiColor_SideBar.B},
        TextColor = {uiColor_TextColor.R, uiColor_TextColor.G, uiColor_TextColor.B},
        ButtonColor = {uiColor_ButtonColor.R, uiColor_ButtonColor.G, uiColor_ButtonColor.B},
        TextBoxColor = {uiColor_TextBoxColor.R, uiColor_TextBoxColor.G, uiColor_TextBoxColor.B},
        ToggleOnColor = {uiColor_ToggleOnText.R, uiColor_ToggleOnText.G, uiColor_ToggleOnText.B},
        ToggleOffColor = {uiColor_ToggleOffText.R, uiColor_ToggleOffText.G, uiColor_ToggleOffText.B},
    }
    if VisualsAPI and VisualsAPI.Gather then cfg.Visuals = VisualsAPI.Gather() end
    if AimAPI and AimAPI.Gather then cfg.Aim = AimAPI.Gather() end
    if MovementAPI and MovementAPI.Gather then cfg.Movement = MovementAPI.Gather() end
    if KeyListAPI and KeyListAPI.Gather then cfg.KeyList = KeyListAPI.Gather() end
    return cfg
end

local function applyConfigValues(cfg)
    if type(cfg.ToggleKey) == "string" then
        pcall(function()
            currentToggleKey = Enum.KeyCode[cfg.ToggleKey]
            keyBindBtn.Text = currentToggleKey.Name
        end)
    end
    if cfg.MainWindowColor then uiColor_MainWindow = Color3.new(unpack(cfg.MainWindowColor)) end
    if cfg.TopBarColor then uiColor_TopBar = Color3.new(unpack(cfg.TopBarColor)) end
    if cfg.SideBarColor then uiColor_SideBar = Color3.new(unpack(cfg.SideBarColor)) end
    if cfg.TextColor then uiColor_TextColor = Color3.new(unpack(cfg.TextColor)) end
    if cfg.ButtonColor then uiColor_ButtonColor = Color3.new(unpack(cfg.ButtonColor)) end
    if cfg.TextBoxColor then uiColor_TextBoxColor = Color3.new(unpack(cfg.TextBoxColor)) end
    if cfg.ToggleOnColor then uiColor_ToggleOnText = Color3.new(unpack(cfg.ToggleOnColor)) end
    if cfg.ToggleOffColor then uiColor_ToggleOffText = Color3.new(unpack(cfg.ToggleOffColor)) end
    applyTheme()
    if unlocked then
        if cfg.Visuals and VisualsAPI and VisualsAPI.Apply then VisualsAPI.Apply(cfg.Visuals) end
        if cfg.Aim and AimAPI and AimAPI.Apply then AimAPI.Apply(cfg.Aim) end
        if cfg.Movement and MovementAPI and MovementAPI.Apply then MovementAPI.Apply(cfg.Movement) end
    end
end

local function loadNamedConfig(name)
    if not filesSupported() then notify("Configs", "Executor doesn't support files") return end
    local path = configFolder .. "/" .. name .. ".json"
    if isfile and isfile(path) then
        local ok, json = pcall(function() return readfile(path) end)
        if ok then
            local ok2, cfg = pcall(function() return HttpService:JSONDecode(json) end)
            if ok2 and type(cfg) == "table" then
                applyConfigValues(cfg)
                setLastConfigName(name)
                notify("Configs", "Loaded: " .. name)
            end
        end
    else
        notify("Configs", "Config not found: " .. name)
    end
end

local function getSavedConfigs()
    local names = {}
    if listfiles then
        local ok, files = pcall(function() return listfiles(configFolder) end)
        if ok and files then
            for _, path in ipairs(files) do
                local name = path:match("([^/\\]+)%.json$")
                if name then table.insert(names, name) end
            end
        end
        table.sort(names)
    end
    return names
end

local ddContainer = create("Frame", {Name = "ConfigDropdown", Parent = tabFrames.Settings, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, BorderSizePixel = 0})
create("UIListLayout", {Parent = ddContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)})

local toggleDropdown
local ddToggleBtn = createContentButton(ddContainer, "Configs (0) — click to open", function() toggleDropdown() end)
ddToggleBtn.LayoutOrder = 0

local ddList = create("ScrollingFrame", {
    Name = "ConfigList", Parent = ddContainer, LayoutOrder = 1,
    Size = UDim2.new(1, 0, 0, 130),
    BackgroundColor3 = uiColor_TextBoxColor, BorderColor3 = COL_BORDER, BorderSizePixel = 1,
    ScrollBarThickness = 4, ScrollBarImageColor3 = COL_BORDER,
    CanvasSize = UDim2.new(0, 0, 0, 0), Visible = false
})
table.insert(themeElements.TextBoxes, ddList)

local ddListLayout = create("UIListLayout", {Parent = ddList, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3)})
create("UIPadding", {Parent = ddList, PaddingTop = UDim.new(0, 3), PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 3)})
ddListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ddList.CanvasSize = UDim2.new(0, 0, 0, ddListLayout.AbsoluteContentSize.Y + 6)
end)

local ddOpen = false

local function setDDToggleText()
    local count = #getSavedConfigs()
    ddToggleBtn.Text = "Configs (" .. count .. ") — click to " .. (ddOpen and "close" or "open")
end

local function refreshConfigList()
    for _, ch in ipairs(ddList:GetChildren()) do
        if ch:IsA("TextButton") or ch:IsA("TextLabel") then ch:Destroy() end
    end
    local names = getSavedConfigs()
    for _, name in ipairs(names) do
        local item = createContentButton(ddList, name, function()
            loadNamedConfig(name)
            ddOpen = false
            ddList.Visible = false
            setDDToggleText()
        end)
        item.Size = UDim2.new(1, -6, 0, 28)
    end
    if #names == 0 then
        local empty = createLabel(ddList, "No saved configs")
        empty.Size = UDim2.new(1, -6, 0, 24)
        empty.TextXAlignment = Enum.TextXAlignment.Center
    end
    setDDToggleText()
end

toggleDropdown = function()
    ddOpen = not ddOpen
    if ddOpen then refreshConfigList() else setDDToggleText() end
    ddList.Visible = ddOpen
end

local function saveNamedConfig()
    local name = string.gsub(configNameBox.Text, "%s+", " ")
    if name == " " then notify("Configs", "Enter a config name!") return end
    if not filesSupported() then notify("Configs", "Executor doesn't support files") return end
    pcall(function()
        if not isfolder("EmilyUi/FuckYou") then makefolder("EmilyUi/FuckYou") end
        if not isfolder(configFolder) then makefolder(configFolder) end
    end)
    local ok, json = pcall(function() return HttpService:JSONEncode(gatherConfig()) end)
    if ok then
        writefile(configFolder .. "/" .. name .. ".json", json)
        setLastConfigName(name)
        notify("Configs", "Saved: " .. name)
        refreshConfigList()
    end
end

local function saveLastNamedConfigSilent()
    if not filesSupported() then return end
    local name = getLastConfigName()
    if not name or name == "" then return end
    pcall(function()
        if not isfolder("EmilyUi/FuckYou") then makefolder("EmilyUi/FuckYou") end
        if not isfolder(configFolder) then makefolder(configFolder) end
    end)
    local ok, json = pcall(function() return HttpService:JSONEncode(gatherConfig()) end)
    if ok and json then
        pcall(function() writefile(configFolder .. "/" .. name .. ".json", json) end)
    end
end

registerConfigSaveListener(saveLastNamedConfigSilent)

ScreenGui.Destroying:Connect(function()
    if unlocked then autoSaveConfig(true) end
end)

createContentButton(tabFrames.Settings, "Save config", saveNamedConfig)
createContentButton(tabFrames.Settings, "Refresh config list", refreshConfigList)
createContentButton(tabFrames.Settings, "Reset defaults", function()
    currentToggleKey = Enum.KeyCode.P
    uiColor_MainWindow = COL_BG
    uiColor_TopBar = COL_BG
    uiColor_SideBar = COL_BG
    uiColor_TextColor = COL_TEXT
    uiColor_ButtonColor = COL_BG
    uiColor_TextBoxColor = COL_TEXTBOX
    uiColor_ToggleOnText = Color3.fromRGB(100, 255, 100)
    uiColor_ToggleOffText = Color3.fromRGB(255, 100, 100)
    uiGuiOpacity = 1
    uiImageOpacity = 1
    uiBlurSize = 0
    uiFitMode = "Fill"
    uiBackgroundFile = ""
    applyBackground()
    updateBlur()
    keyBindBtn.Text = currentToggleKey.Name
    applyTheme()
    saveConfig()
    notify("Configs", "Settings reset to defaults")
    if AimAPI and AimAPI.Reset then AimAPI.Reset() end
    if VisualsAPI and VisualsAPI.Reset then VisualsAPI.Reset() end
    if MovementAPI and MovementAPI.Reset then MovementAPI.Reset() end
    if KeyListAPI and KeyListAPI.Reset then KeyListAPI.Reset() end
end)

refreshConfigList()

-- TABS
local function switchTab(targetTab)
    for _, tab in ipairs(tabs) do tab.Frame.Visible = (tab == targetTab) end
    updateTabButtonsTheme()
end

tabs = {
    {Frame = tabFrames.Main, Name = "Main Info"},
    {Frame = tabFrames.Universal, Name = "Universal"},
    {Frame = tabFrames.Character, Name = "Character"},
    {Frame = tabFrames.Players, Name = "Players"},
    {Frame = tabFrames.Visuals, Name = "Visuals"},
    {Frame = tabFrames.Utilities, Name = "Utilities"},
    {Frame = tabFrames.Server, Name = "Server"},
    {Frame = tabFrames.Games, Name = "Games"},
    {Frame = tabFrames.Scripts, Name = "Scripts"},
    {Frame = tabFrames.Hubs, Name = "Script Hubs"},
    {Frame = tabFrames.Guis, Name = "GUIs"},
    {Frame = tabFrames.Anims, Name = "Animations"},
    {Frame = tabFrames.KeyList, Name = "Key List"},
    {Frame = tabFrames.Settings, Name = "Settings"}
}

for index, tab in ipairs(tabs) do
    local btn = create("TextButton", {
        Name = "Btn_" .. tab.Name, Parent = MenuInsided,
        Size = UDim2.new(1, 0, 0, 30), LayoutOrder = index, Visible = false,
        BackgroundColor3 = uiColor_ButtonColor, BorderColor3 = COL_BORDER,
        TextColor3 = uiColor_TextColor, Text = tab.Name, Font = FONT, TextSize = 12
    })
    tab.Button = btn
    table.insert(themeElements.Buttons, btn)
    table.insert(themeElements.Texts, btn)
    btn.MouseButton1Click:Connect(function() switchTab(tab) end)
end

applyTheme()

local emilyOpen = false
EmilyUi.MouseButton1Click:Connect(function()
    if not emilyOpen then
        emilyOpen = true
        for _, tab in ipairs(tabs) do tab.Button.Visible = true end
        switchTab(tabs[1])
    end
end)

-- WINDOW CONTROLS
local FULL_SIZE = UDim2.new(0, 940, 0, 510)
local STRIP_SIZE = UDim2.new(0, 940, 0, 45)
local state = "full"
local currentTween = nil

local function tweenSize(target, cb)
    if currentTween then currentTween:Cancel() end
    local tw = TweenService:Create(FuckYou, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = target})
    currentTween = tw
    if cb then
        tw.Completed:Connect(function(ps)
            if ps == Enum.PlaybackState.Completed then cb() end
        end)
    end
    tw:Play()
end

local function openFull()
    FuckYou.Visible = true
    uiCollapsed = false
    applyBackground()
    tweenSize(FULL_SIZE)
    state = "full"
end

X.MouseButton1Click:Connect(function() state = "closed"; ScreenGui:Destroy() end)

Equal.MouseButton1Click:Connect(function()
    if state == "full" then
        state = "strip"
        uiCollapsed = true
        applyBackground()
        tweenSize(STRIP_SIZE)
    elseif state == "strip" then
        openFull()
    end
end)

Minus.MouseButton1Click:Connect(function()
    state = "hidden"
    uiCollapsed = true
    applyBackground()
    tweenSize(UDim2.new(0, 940, 0, 0), function() FuckYou.Visible = false end)
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == currentToggleKey and unlocked then
        if state == "hidden" then
            openFull()
        else
            state = "hidden"
            FuckYou.Visible = false
        end
    end
end)

local function makeDraggable(dragFrame, targetFrame)
    local dragging, dragInput, dragStart, startPosition
    dragFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = targetFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    dragFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            targetFrame.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end)
end

makeDraggable(TopBar, FuckYou)

-- KEY SYSTEM
local KeyWindow = create("Frame", {
    Name = "KeyWindow", Parent = ScreenGui,
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 450, 0, 310),
    BackgroundColor3 = uiColor_MainWindow, BorderColor3 = COL_BORDER
})
table.insert(themeElements.MainWindow, KeyWindow)

local KeyTopBar = create("Frame", {Parent = KeyWindow, Size = UDim2.new(1, 0, 0, 35), BackgroundColor3 = uiColor_TopBar, BorderSizePixel = 0})
table.insert(themeElements.TopBars, KeyTopBar)

local KeyTitle = create("TextLabel", {
    Parent = KeyTopBar, Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1, Text = "Fuck you! — Key System",
    TextColor3 = uiColor_TextColor, TextSize = 15, Font = FONT,
    TextXAlignment = Enum.TextXAlignment.Left
})
table.insert(themeElements.Texts, KeyTitle)

local KeyCloseBtn = create("TextButton", {
    Parent = KeyTopBar, Size = UDim2.new(0, 35, 0, 35), Position = UDim2.new(1, -35, 0, 0),
    BackgroundColor3 = Color3.fromRGB(120, 40, 40), BorderColor3 = COL_BORDER,
    TextColor3 = Color3.fromRGB(255, 255, 255), Text = "X", TextSize = 13, Font = FONT
})
KeyCloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local KeyInfoLabel = create("TextLabel", {
    Parent = KeyWindow, Size = UDim2.new(1, -30, 0, 40), Position = UDim2.new(0, 15, 0, 50),
    BackgroundTransparency = 1,
    Text = "Please enter your access key below to load the script.\nKey can be obtained via Discord.",
    TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT, TextWrapped = true
})
table.insert(themeElements.Texts, KeyInfoLabel)

local KeyDiscordBtn = createContentButton(KeyWindow, "Click to copy Discord Server link", copyDiscord)
KeyDiscordBtn.Size = UDim2.new(1, -40, 0, 36)
KeyDiscordBtn.Position = UDim2.new(0, 20, 0, 105)

local KeyTextBox = createTextBox(KeyWindow, "Enter key here...", FONT)
KeyTextBox.Size = UDim2.new(1, -40, 0, 36)
KeyTextBox.Position = UDim2.new(0, 20, 0, 160)

makeDraggable(KeyTopBar, KeyWindow)

KeyWindow:GetPropertyChangedSignal("Visible"):Connect(function()
    if KeyWindow.Visible and uiBlurSize > 0 then
        blurEffect.Parent = Lighting
        blurEffect.Size = uiBlurSize
        blurEffect.Enabled = true
    else
        updateBlur()
    end
end)

local SECRET_KEY = "XenoMeowEmilyUi11037"
local b64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

local function base64_decode(data)
    data = string.gsub(data, '[^'..b64..'=]', '')
    return (data:gsub('.', function(x)
        if x == '=' then return '' end
        local r, f = '', (b64:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2^i - f % 2^(i - 1) > 0 and '1' or '0') end
        return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if #x ~= 8 then return '' end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2^(8 - i) or 0) end
        return string.char(c)
    end))
end

local function xor_decrypt(str, key)
    local result = {}
    local keyLen = #key
    for i = 1, #str do
        result[i] = string.char(bit32.bxor(string.byte(str, i), string.byte(key, ((i - 1) % keyLen) + 1)))
    end
    return table.concat(result)
end

local function decryptData(encryptedBase64, key)
    encryptedBase64 = string.gsub(encryptedBase64, "%s+", "")
    return xor_decrypt(base64_decode(encryptedBase64), key)
end

local function getKeyDaysLeft(timeStr)
    if not timeStr or timeStr == "inf" then return "Infinity" end
    local day, month, year = timeStr:match("(%d+)%.(%d+)%.(%d+)")
    if not day or not month or not year then return 0 end
    local expireTime = os.time({day = tonumber(day), month = tonumber(month), year = tonumber(year), hour = 0, min = 0, sec = 0})
    local diff = expireTime - os.time()
    if diff <= 0 then return 0 else return diff / 86400 end
end

local function playUnlockJingle()
    pcall(function()
        local SoundService = game:GetService("SoundService")
        local s = Instance.new("Sound")
        s.Name = "FuckYouUnlockSound"
        s.SoundId = "rbxassetid://115440201770223"
        s.Volume = 1; s.Looped = false; s.TimePosition = 0
        s.Parent = SoundService
        local done = false
        local conn = nil
        local function cleanup()
            if done then return end
            done = true
            if conn then conn:Disconnect() end
            pcall(function() s:Stop() end)
            pcall(function() s:Destroy() end)
        end
        s.Ended:Connect(cleanup)
        conn = RunService.Heartbeat:Connect(function()
            if not done and s.IsPlaying and s.TimePosition >= 2 then cleanup() end
        end)
        s:Play()
        task.delay(10, cleanup)
    end)
end

local function unlockScript(userGroup, daysLeft)
    unlocked = true
    playUnlockJingle()
    KeyWindow:Destroy()
    FuckYou.Visible = true
    state = "full"
    updateProfilePanel(userGroup or "Free", daysLeft)
    loadConfig()
    applyBackground()
    updateBlur()
    applyTheme()
    local lastCfgName = getLastConfigName()
    if lastCfgName then loadNamedConfig(lastCfgName) end
    if autoSaveConfig then autoSaveConfig(true) end
    notify("Fuck you! is loaded", "Welcome! Role: " .. (userGroup or "User"))
end

local function isGroupAllowed(groupName)
    local g = string.lower(tostring(groupName or ""))
    return g == "free" or g == "user" or g == "tester" or g == "coder"
end

local function checkKeySystem()
    if not cachedKeyResponse then
        local success, response = pcall(function()
            return game:HttpGet("https://raw.githubusercontent.com/MamaSdoxla/EmilyUi/refs/heads/main/nuh-uh.json")
        end)
        if not success or not response or #response < 10 then
            KeyInfoLabel.Text = "Error: Failed to fetch key database!"
            KeyInfoLabel.TextColor3 = Color3.fromRGB(220, 50, 50)
            return
        end
        local ok, decryptedText = pcall(function() return decryptData(response, SECRET_KEY) end)
        if not ok or not decryptedText or #decryptedText < 5 then
            KeyInfoLabel.Text = "Error: Failed to decrypt!\nLen: " .. tostring(decryptedText and #decryptedText or 0)
            KeyInfoLabel.TextColor3 = Color3.fromRGB(220, 50, 50)
            return
        end
        cachedKeyResponse = decryptedText
    end
    local jsonSuccess, keysList = pcall(function() return HttpService:JSONDecode(cachedKeyResponse) end)
    if not jsonSuccess or type(keysList) ~= "table" then
        KeyInfoLabel.Text = "Error: Database parsing failed!\nPreview: " .. string.sub(tostring(cachedKeyResponse), 1, 60)
        KeyInfoLabel.TextColor3 = Color3.fromRGB(220, 50, 50)
        return
    end
    local myName = string.lower(LocalPlayer.Name)
    local enteredKey = KeyTextBox.Text
    for _, data in ipairs(keysList) do
        if data.key and data.robloxName and data.group and data.timeTillWorks then
            local nameMatch = (data.robloxName == "none") or (string.lower(data.robloxName) == myName)
            if nameMatch and isGroupAllowed(data.group) then
                local daysLeft = getKeyDaysLeft(data.timeTillWorks)
                if daysLeft == "Infinity" or (type(daysLeft) == "number" and daysLeft > 0) then
                    if data.key == "none" or (enteredKey == data.key) then
                        unlockScript(data.group, daysLeft)
                        return
                    end
                end
            end
        end
    end
    KeyInfoLabel.Text = "Enter key please! You can ask for a key in discord."
    KeyInfoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
end

local BtnSubmit = createContentButton(KeyWindow, "Check Key", checkKeySystem, Color3.fromRGB(40, 90, 40))
BtnSubmit.Size = UDim2.new(0, 150, 0, 36)
BtnSubmit.Position = UDim2.new(0.5, -75, 0, 240)

applyTheme()

task.spawn(function()
    while true do
        task.wait(600)
        if autoSaveConfig then autoSaveConfig(true) end
    end
end)

task.spawn(checkKeySystem)

function Library:Init()
    -- GUI уже создан при загрузке модуля
end

return Library