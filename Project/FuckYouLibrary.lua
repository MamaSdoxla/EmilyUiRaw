-- ============================================================
-- FuckYouLibrary.lua
-- ============================================================
-- Библиотека ядра: UI, темы, конфиги, ключи, утилиты.
-- Экспортирует FuckYouLib в _G.
-- ============================================================

local FuckYouLib = {}
_G.FuckYouLib = FuckYouLib

--// Сервисы
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

--// Стиль
FuckYouLib.COL_BG = Color3.fromRGB(12, 12, 12)
FuckYouLib.COL_BORDER = Color3.fromRGB(22, 22, 22)
FuckYouLib.COL_TEXT = Color3.fromRGB(139, 135, 127)
FuckYouLib.COL_TEXTBOX = Color3.fromRGB(18, 18, 18)
FuckYouLib.FONT = Enum.Font.SpecialElite

local COL_BG = FuckYouLib.COL_BG
local COL_BORDER = FuckYouLib.COL_BORDER
local COL_TEXT = FuckYouLib.COL_TEXT
local COL_TEXTBOX = FuckYouLib.COL_TEXTBOX
local FONT = FuckYouLib.FONT

--// Настройки UI (глобальные)
FuckYouLib.currentToggleKey = Enum.KeyCode.P
FuckYouLib.uiColor_MainWindow = COL_BG
FuckYouLib.uiColor_TopBar = COL_BG
FuckYouLib.uiColor_SideBar = COL_BG
FuckYouLib.uiColor_TextColor = COL_TEXT
FuckYouLib.uiColor_ButtonColor = COL_BG
FuckYouLib.uiColor_TextBoxColor = COL_TEXTBOX
FuckYouLib.uiGuiOpacity = 1
FuckYouLib.uiImageOpacity = 1
FuckYouLib.uiBlurSize = 0
FuckYouLib.uiFitMode = "Fill"
FuckYouLib.uiBackgroundFile = ""
FuckYouLib.uiColor_ToggleOnText = Color3.fromRGB(100, 255, 100)
FuckYouLib.uiColor_ToggleOffText = Color3.fromRGB(255, 100, 100)
FuckYouLib.uiCollapsed = false

--// Система уведомлений
function FuckYouLib.notify(title, text)
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
            main.BackgroundColor3 = COL_BG
            main.BorderColor3 = COL_BORDER
            main.BorderSizePixel = 1
            main.Parent = gui
            local titleLabel = Instance.new("TextLabel")
            titleLabel.Size = UDim2.new(1, -16, 0, 20)
            titleLabel.Position = UDim2.new(0, 8, 0, 6)
            titleLabel.BackgroundTransparency = 1
            titleLabel.Text = title
            titleLabel.Font = FONT
            titleLabel.TextSize = 14
            titleLabel.TextXAlignment = Enum.TextXAlignment.Left
            titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            titleLabel.Parent = main
            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, -16, 0, 30)
            textLabel.Position = UDim2.new(0, 8, 0, 26)
            textLabel.BackgroundTransparency = 1
            textLabel.Text = text
            textLabel.Font = FONT
            textLabel.TextSize = 12
            textLabel.TextXAlignment = Enum.TextXAlignment.Left
            textLabel.TextYAlignment = Enum.TextYAlignment.Top
            textLabel.TextWrapped = true
            textLabel.TextColor3 = COL_TEXT
            textLabel.Parent = main
            task.delay(notificationData.Duration or 15, function() gui:Destroy() end)
        end)
    end)
end

FuckYouLib.notify("Fuck you! v1.2", "To get key goto discord or ask for a permanent one.")

--// Вспомогательная функция создания Instance
function FuckYouLib.create(className, properties)
    local inst = Instance.new(className)
    for k, v in pairs(properties) do inst[k] = v end
    return inst
end

--// Хранилища
FuckYouLib.themeElements = { MainWindow = {}, TopBars = {}, SideBars = {}, Texts = {}, Buttons = {}, TextBoxes = {}, FillBars = {}, CustomButtons = {} }
FuckYouLib.moduleToggles = {}
FuckYouLib.toggleRegistry = {}
FuckYouLib.tabs = {}
FuckYouLib.keyListProviders = {}

--// Вспомогательные функции
local function scaleColor(c, f)
    return Color3.fromRGB(math.clamp(c.R*255*f,0,255), math.clamp(c.G*255*f,0,255), math.clamp(c.B*255*f,0,255))
end

function FuckYouLib.paintToggleBtn(btn, on)
    if on then
        btn.BackgroundColor3 = scaleColor(FuckYouLib.uiColor_ToggleOnText, 0.35)
        btn.TextColor3 = FuckYouLib.uiColor_ToggleOnText
    else
        btn.BackgroundColor3 = scaleColor(FuckYouLib.uiColor_ToggleOffText, 0.35)
        btn.TextColor3 = FuckYouLib.uiColor_ToggleOffText
    end
end

function FuckYouLib.registerToggle(btn, getState)
    FuckYouLib.toggleRegistry[btn] = getState
    FuckYouLib.paintToggleBtn(btn, getState() and true or false)
end

function FuckYouLib.registerKeyListProvider(group, fn)
    FuckYouLib.keyListProviders[group] = fn
end

--// Функция обновления цвета кнопок вкладок
function FuckYouLib.updateTabButtonsTheme()
    for _, tab in ipairs(FuckYouLib.tabs) do
        if tab.Button then
            if tab.Frame.Visible then
                tab.Button.BackgroundColor3 = FuckYouLib.uiColor_ButtonColor
                tab.Button.TextColor3 = Color3.fromRGB(255,255,255)
            else
                local c = FuckYouLib.uiColor_ButtonColor
                tab.Button.BackgroundColor3 = Color3.fromRGB(math.max(c.R*255-10,0), math.max(c.G*255-10,0), math.max(c.B*255-10,0))
                tab.Button.TextColor3 = FuckYouLib.uiColor_TextColor
            end
        end
    end
end

--// Применение темы
function FuckYouLib.applyTheme()
    local trans = 1 - FuckYouLib.uiGuiOpacity
    local function applyList(key, fn)
        local alive = {}
        for _, el in ipairs(FuckYouLib.themeElements[key]) do
            if typeof(el) == "Instance" and el.Parent then
                fn(el)
                table.insert(alive, el)
            end
        end
        FuckYouLib.themeElements[key] = alive
    end
    applyList("MainWindow", function(el) el.BackgroundColor3 = FuckYouLib.uiColor_MainWindow; el.BackgroundTransparency = trans end)
    applyList("TopBars", function(el) el.BackgroundColor3 = FuckYouLib.uiColor_TopBar; el.BackgroundTransparency = trans end)
    applyList("SideBars", function(el) el.BackgroundColor3 = FuckYouLib.uiColor_SideBar; el.BackgroundTransparency = trans end)
    applyList("Texts", function(el) el.TextColor3 = FuckYouLib.uiColor_TextColor end)
    applyList("Buttons", function(el) el.BackgroundColor3 = FuckYouLib.uiColor_ButtonColor; el.BackgroundTransparency = trans end)
    applyList("CustomButtons", function(el) el.BackgroundTransparency = trans end)
    applyList("TextBoxes", function(el) el.BackgroundColor3 = FuckYouLib.uiColor_TextBoxColor; el.BackgroundTransparency = trans end)
    applyList("FillBars", function(el) el.BackgroundColor3 = FuckYouLib.uiColor_TextColor end)
    for btn, getState in pairs(FuckYouLib.toggleRegistry) do
        if typeof(btn) == "Instance" and btn.Parent then
            FuckYouLib.paintToggleBtn(btn, getState() and true or false)
        else
            FuckYouLib.toggleRegistry[btn] = nil
        end
    end
    FuckYouLib.updateTabButtonsTheme()
end

--// Система конфигов
FuckYouLib.configPath = "EmilyUi/Config.json"
FuckYouLib.configSaveListeners = {}
FuckYouLib.visualSaveQueued = false
FuckYouLib.lastAutoConfigSave = 0

function FuckYouLib.registerConfigSaveListener(fn)
    if typeof(fn) == "function" then
        table.insert(FuckYouLib.configSaveListeners, fn)
    end
end

function FuckYouLib.runConfigSaveListeners()
    for _, fn in ipairs(FuckYouLib.configSaveListeners) do
        pcall(fn)
    end
end

function FuckYouLib.saveConfig()
    local config = {
        ToggleKey = FuckYouLib.currentToggleKey.Name,
        MainWindowColor = {FuckYouLib.uiColor_MainWindow.R, FuckYouLib.uiColor_MainWindow.G, FuckYouLib.uiColor_MainWindow.B},
        TopBarColor = {FuckYouLib.uiColor_TopBar.R, FuckYouLib.uiColor_TopBar.G, FuckYouLib.uiColor_TopBar.B},
        SideBarColor = {FuckYouLib.uiColor_SideBar.R, FuckYouLib.uiColor_SideBar.G, FuckYouLib.uiColor_SideBar.B},
        TextColor = {FuckYouLib.uiColor_TextColor.R, FuckYouLib.uiColor_TextColor.G, FuckYouLib.uiColor_TextColor.B},
        ButtonColor = {FuckYouLib.uiColor_ButtonColor.R, FuckYouLib.uiColor_ButtonColor.G, FuckYouLib.uiColor_ButtonColor.B},
        TextBoxColor = {FuckYouLib.uiColor_TextBoxColor.R, FuckYouLib.uiColor_TextBoxColor.G, FuckYouLib.uiColor_TextBoxColor.B},
        ToggleOnColor = {FuckYouLib.uiColor_ToggleOnText.R, FuckYouLib.uiColor_ToggleOnText.G, FuckYouLib.uiColor_ToggleOnText.B},
        ToggleOffColor = {FuckYouLib.uiColor_ToggleOffText.R, FuckYouLib.uiColor_ToggleOffText.G, FuckYouLib.uiColor_ToggleOffText.B},
        GuiOpacity = FuckYouLib.uiGuiOpacity,
        ImageOpacity = FuckYouLib.uiImageOpacity,
        Blur = FuckYouLib.uiBlurSize,
        Fit = FuckYouLib.uiFitMode,
        BackgroundFile = FuckYouLib.uiBackgroundFile,
    }
    if VisualsAPI and VisualsAPI.Gather then config.Visuals = VisualsAPI.Gather() end
    if AimAPI and AimAPI.Gather then config.Aim = AimAPI.Gather() end
    if MovementAPI and MovementAPI.Gather then config.Movement = MovementAPI.Gather() end
    if KeyListAPI and KeyListAPI.Gather then config.KeyList = KeyListAPI.Gather() end
    local success, json = pcall(function() return HttpService:JSONEncode(config) end)
    if success then
        if makefolder then pcall(function() makefolder("EmilyUi") end) end
        if writefile then pcall(function() writefile(FuckYouLib.configPath, json) end) end
    end
end

function FuckYouLib.loadConfig()
    if isfile and isfile(FuckYouLib.configPath) and readfile then
        local success, json = pcall(function() return readfile(FuckYouLib.configPath) end)
        if success and json then
            local ok, config = pcall(function() return HttpService:JSONDecode(json) end)
            if ok and config then
                if config.ToggleKey then pcall(function() FuckYouLib.currentToggleKey = Enum.KeyCode[config.ToggleKey] end) end
                if config.MainWindowColor then FuckYouLib.uiColor_MainWindow = Color3.new(unpack(config.MainWindowColor)) end
                if config.TopBarColor then FuckYouLib.uiColor_TopBar = Color3.new(unpack(config.TopBarColor)) end
                if config.SideBarColor then FuckYouLib.uiColor_SideBar = Color3.new(unpack(config.SideBarColor)) end
                if config.TextColor then FuckYouLib.uiColor_TextColor = Color3.new(unpack(config.TextColor)) end
                if config.ButtonColor then FuckYouLib.uiColor_ButtonColor = Color3.new(unpack(config.ButtonColor)) end
                if config.TextBoxColor then FuckYouLib.uiColor_TextBoxColor = Color3.new(unpack(config.TextBoxColor)) end
                if config.GuiOpacity then FuckYouLib.uiGuiOpacity = math.clamp(config.GuiOpacity, 0.25, 1) end
                if config.ImageOpacity then FuckYouLib.uiImageOpacity = math.clamp(config.ImageOpacity, 0, 1) end
                if config.Blur then FuckYouLib.uiBlurSize = math.clamp(config.Blur, 0, 24) end
                if config.Fit then FuckYouLib.uiFitMode = config.Fit end
                if config.BackgroundFile ~= nil then FuckYouLib.uiBackgroundFile = config.BackgroundFile end
                if unlocked then
                    if config.Visuals and VisualsAPI and VisualsAPI.Apply then VisualsAPI.Apply(config.Visuals) end
                    if config.Aim and AimAPI and AimAPI.Apply then AimAPI.Apply(config.Aim) end
                    if config.Movement and MovementAPI and MovementAPI.Apply then MovementAPI.Apply(config.Movement) end
                    if config.KeyList and KeyListAPI and KeyListAPI.Apply then KeyListAPI.Apply(config.KeyList) end
                end
            end
        end
    end
end

function FuckYouLib.autoSaveConfig(force)
    if not unlocked then return end
    if not force and os.clock() - FuckYouLib.lastAutoConfigSave < 0.5 then return end
    FuckYouLib.lastAutoConfigSave = os.clock()
    pcall(FuckYouLib.saveConfig)
    FuckYouLib.runConfigSaveListeners()
end

function FuckYouLib.queueVisualSave()
    if FuckYouLib.visualSaveQueued then return end
    FuckYouLib.visualSaveQueued = true
    task.delay(1, function()
        FuckYouLib.visualSaveQueued = false
        if unlocked and FuckYouLib.autoSaveConfig then
            FuckYouLib.autoSaveConfig(true)
        end
    end)
end

--// Создание основного окна и GUI
local ScreenGui = FuckYouLib.create("ScreenGui", {Name = "FuckYouGui", ResetOnSpawn = false, Parent = LocalPlayer:WaitForChild("PlayerGui")})
FuckYouLib.ScreenGui = ScreenGui

local FuckYou = FuckYouLib.create("Frame", {
    Name = "FuckYou", Parent = ScreenGui,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 940, 0, 510),
    ClipsDescendants = true, Visible = false,
    BackgroundColor3 = FuckYouLib.uiColor_MainWindow, BorderColor3 = COL_BORDER, BorderSizePixel = 1
})
table.insert(FuckYouLib.themeElements.MainWindow, FuckYou)
FuckYouLib.FuckYou = FuckYou

-- Фон / Блюр / Прозрачность
local BackgroundImage = FuckYouLib.create("ImageLabel", {
    Name = "BackgroundImage", Parent = FuckYou,
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1, Image = "", Visible = false,
    ScaleType = Enum.ScaleType.Stretch, ImageTransparency = 0, ZIndex = 0,
})
FuckYouLib.BackgroundImage = BackgroundImage

local BG_FOLDER = "EmilyUi/FuckYou/Background"
if makefolder then pcall(function()
    if not isfolder("EmilyUi/FuckYou") then makefolder("EmilyUi/FuckYou") end
    if not isfolder(BG_FOLDER) then makefolder(BG_FOLDER) end
end) end

local blurEffect = Instance.new("BlurEffect")
blurEffect.Name = "FuckYouBlur"
blurEffect.Size = 0
blurEffect.Enabled = false
FuckYouLib.blurEffect = blurEffect

local function updateBlur()
    if FuckYou.Parent and FuckYou.Visible and FuckYouLib.uiBlurSize > 0 then
        blurEffect.Parent = game:GetService("Lighting")
        blurEffect.Size = FuckYouLib.uiBlurSize
        blurEffect.Enabled = true
    else
        blurEffect.Enabled = false
        blurEffect.Parent = nil
    end
end
FuckYou:GetPropertyChangedSignal("Visible"):Connect(updateBlur)
ScreenGui.Destroying:Connect(function() blurEffect.Enabled = false; blurEffect.Parent = nil end)
FuckYouLib.updateBlur = updateBlur

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
        if ok and typeof(asset) == "string" and asset ~= "" then return asset
    end
    if typeof(GetCustomAsset) == "function" then
        local ok, asset = pcall(GetCustomAsset, path)
        if ok and typeof(asset) == "string" and asset ~= "" then return asset
    end
    return nil
end

function FuckYouLib.getBackgroundFiles()
    local out = {}
    if listfiles then
        local ok, files = pcall(function() return listfiles(BG_FOLDER) end)
        if ok and files then
            for _, p in ipairs(files) do
                local name = p:match("([^/\\]+)$")
                local ext = name and name:lower():match("%.(%w+)$")
                if ext == "png" or ext == "jpg" or ext == "jpeg" or ext == "webp" then
                    table.insert(out, name)
                end
            end
            table.sort(out)
        end
    end
    return out
end

local FIT_MAP = {
    Fill = Enum.ScaleType.Crop,
    Fit = Enum.ScaleType.Fit,
    Stretch = Enum.ScaleType.Stretch,
    Tile = Enum.ScaleType.Tile,
    Center = Enum.ScaleType.Crop,
    Zoom = Enum.ScaleType.Crop,
    Slice = Enum.ScaleType.Slice,
    Crop = Enum.ScaleType.Crop,
}
local function getScaleType(name)
    if FIT_MAP[name] then return FIT_MAP[name] end
    local ok, val = pcall(function() return Enum.ScaleType[name] end)
    if ok and val then return val end
    return Enum.ScaleType.Stretch
end

function FuckYouLib.applyBackground()
    local asset = nil
    if typeof(FuckYouLib.uiBackgroundFile) ~= "string" then FuckYouLib.uiBackgroundFile = "" end
    if FuckYouLib.uiBackgroundFile ~= "" and not FuckYouLib.uiCollapsed then
        local path = BG_FOLDER .. "/" .. FuckYouLib.uiBackgroundFile
        if typeof(isfile) == "function" then
            local ok, exists = pcall(isfile, path)
            if ok and not exists then
                FuckYouLib.uiBackgroundFile = ""
                pcall(function() FuckYouLib.saveConfig() end)
            else
                asset = customAsset(path)
            end
        else
            asset = customAsset(path)
        end
    end
    if asset and not FuckYouLib.uiCollapsed then
        BackgroundImage.Image = asset
        BackgroundImage.ScaleType = getScaleType(FuckYouLib.uiFitMode)
        BackgroundImage.ImageTransparency = 1 - FuckYouLib.uiImageOpacity
        BackgroundImage.Visible = true
    else
        BackgroundImage.Visible = false
        BackgroundImage.Image = ""
    end
end

FuckYouLib.applyBackground()
FuckYouLib.updateBlur()

-- TopBar
local TopBar = FuckYouLib.create("Frame", {Name = "TopBar", Parent = FuckYou, Size = UDim2.new(1, 0, 0, 45), BackgroundColor3 = FuckYouLib.uiColor_TopBar, BorderSizePixel = 0})
table.insert(FuckYouLib.themeElements.TopBars, TopBar)
FuckYouLib.TopBar = TopBar

local Title = FuckYouLib.create("TextLabel", {Name = "Name", Parent = TopBar, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "Fuck you! v1.2", TextColor3 = FuckYouLib.uiColor_TextColor, TextSize = 13, Font = FONT})
table.insert(FuckYouLib.themeElements.Texts, Title)

local function makeTopBtn(symbol, offset)
    local b = FuckYouLib.create("TextButton", {
        Name = symbol, Parent = TopBar,
        Position = UDim2.new(1, -45 * offset, 0, 0), Size = UDim2.new(0, 45, 0, 45),
        BackgroundColor3 = FuckYouLib.uiColor_TopBar, BorderColor3 = COL_BORDER,
        Text = symbol, TextColor3 = FuckYouLib.uiColor_TextColor, TextSize = 13, Font = FONT
    })
    table.insert(FuckYouLib.themeElements.TopBars, b)
    table.insert(FuckYouLib.themeElements.Texts, b)
    b.MouseEnter:Connect(function()
        local c = b.BackgroundColor3
        b.BackgroundColor3 = Color3.fromRGB(math.min(c.R*255+10,255), math.min(c.G*255+10,255), math.min(c.B*255+10,255))
    end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = FuckYouLib.uiColor_TopBar end)
    return b
end

local Minus = makeTopBtn("-", 3)
local Equal = makeTopBtn("=", 2)
local X = makeTopBtn("X", 1)
FuckYouLib.Minus = Minus
FuckYouLib.Equal = Equal
FuckYouLib.X = X

-- SideBar
local SideBard = FuckYouLib.create("Frame", {Name = "SideBard", Parent = FuckYou, Position = UDim2.new(0, 0, 0, 45), Size = UDim2.new(0, 65, 1, -45), BackgroundColor3 = FuckYouLib.uiColor_SideBar, BorderSizePixel = 0})
table.insert(FuckYouLib.themeElements.SideBars, SideBard)
FuckYouLib.SideBard = SideBard

function FuckYouLib.makeSideBtn(text, offsetY)
    local b = FuckYouLib.create("TextButton", {
        Name = text, Parent = SideBard,
        Position = UDim2.new(0, 0, 0, offsetY), Size = UDim2.new(1, 0, 0, 59),
        BackgroundColor3 = FuckYouLib.uiColor_SideBar, BorderColor3 = COL_BORDER,
        Text = text, TextColor3 = FuckYouLib.uiColor_TextColor, TextSize = 12, Font = FONT
    })
    table.insert(FuckYouLib.themeElements.SideBars, b)
    table.insert(FuckYouLib.themeElements.Texts, b)
    return b
end

local EmilyUi = FuckYouLib.makeSideBtn("EmilyUi", 0)
local Desync = FuckYouLib.makeSideBtn("Desync", 59)
local Music = FuckYouLib.makeSideBtn("Music", 118)
local Aim = FuckYouLib.makeSideBtn("Aim", 177)
FuckYouLib.EmilyUi = EmilyUi
FuckYouLib.Desync = Desync
FuckYouLib.Music = Music
FuckYouLib.Aim = Aim

-- MenuInsided (левое подменю)
local MenuInsided = FuckYouLib.create("ScrollingFrame", {
    Name = "MenuInsided", Parent = FuckYou,
    Position = UDim2.new(0, 65, 0, 45), Size = UDim2.new(0, 105, 1, -45),
    BackgroundColor3 = FuckYouLib.uiColor_SideBar, BorderSizePixel = 0,
    ScrollBarThickness = 3, ScrollBarImageColor3 = COL_BORDER,
    CanvasSize = UDim2.new(0, 0, 0, 0), ClipsDescendants = true
})
table.insert(FuckYouLib.themeElements.SideBars, MenuInsided)
FuckYouLib.MenuInsided = MenuInsided
local menuLayout = FuckYouLib.create("UIListLayout", {Parent = MenuInsided, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)})
FuckYouLib.create("UIPadding", {Parent = MenuInsided, PaddingTop = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)})
menuLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    MenuInsided.CanvasSize = UDim2.new(0, 0, 0, menuLayout.AbsoluteContentSize.Y + 10)
end)

-- Containment (основная область)
local Containment = FuckYouLib.create("Frame", {Name = "Containment", Parent = FuckYou, Position = UDim2.new(0, 170, 0, 45), Size = UDim2.new(1, -170, 1, -45), BackgroundTransparency = 1, BorderSizePixel = 0})
FuckYouLib.Containment = Containment

-- Разделительные линии
local function makeLine(name, pos, size)
    return FuckYouLib.create("Frame", {Name = name, Parent = FuckYou, Position = pos, Size = size, BackgroundColor3 = COL_BORDER, BorderSizePixel = 0})
end
makeLine("SepH", UDim2.new(0, 0, 0, 45), UDim2.new(1, 0, 0, 1))
makeLine("SepV1", UDim2.new(0, 65, 0, 46), UDim2.new(0, 1, 1, -46))
makeLine("SepV2", UDim2.new(0, 170, 0, 46), UDim2.new(0, 1, 1, -46))

--// Функции создания UI-элементов (экспортируются)
function FuckYouLib.createSection(parent, text)
    local lbl = FuckYouLib.create("TextLabel", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = text, TextColor3 = FuckYouLib.uiColor_TextColor, TextSize = 13, Font = FONT, Parent = parent})
    table.insert(FuckYouLib.themeElements.Texts, lbl)
    return lbl
end

function FuckYouLib.createLabel(parent, text)
    local lbl = FuckYouLib.create("TextLabel", {Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = text, TextColor3 = FuckYouLib.uiColor_TextColor, TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, Parent = parent})
    table.insert(FuckYouLib.themeElements.Texts, lbl)
    return lbl
end

function FuckYouLib.createContentButton(parent, text, callback, customColor)
    local defaultColor = customColor or FuckYouLib.uiColor_ButtonColor
    local btn = FuckYouLib.create("TextButton", {Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = defaultColor, BorderColor3 = COL_BORDER, TextColor3 = FuckYouLib.uiColor_TextColor, Text = text, Font = FONT, TextSize = 13, BackgroundTransparency = 1 - FuckYouLib.uiGuiOpacity, Parent = parent})
    if not customColor then table.insert(FuckYouLib.themeElements.Buttons, btn) end
    table.insert(FuckYouLib.themeElements.Texts, btn)
    btn.MouseEnter:Connect(function()
        local c = btn.BackgroundColor3
        btn.BackgroundColor3 = Color3.fromRGB(math.min(c.R*255+10,255), math.min(c.G*255+10,255), math.min(c.B*255+10,255))
    end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = customColor or FuckYouLib.uiColor_ButtonColor end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

function FuckYouLib.createTextBox(parent, placeholder, font)
    local box = FuckYouLib.create("TextBox", {BackgroundColor3 = FuckYouLib.uiColor_TextBoxColor, BorderColor3 = COL_BORDER, TextColor3 = FuckYouLib.uiColor_TextColor, PlaceholderColor3 = Color3.fromRGB(90,90,90), PlaceholderText = placeholder, Text = "", TextSize = 13, Font = font or FONT, ClearTextOnFocus = false, BackgroundTransparency = 1 - FuckYouLib.uiGuiOpacity, Parent = parent})
    table.insert(FuckYouLib.themeElements.Texts, box)
    table.insert(FuckYouLib.themeElements.TextBoxes, box)
    return box
end

--// Tab Frames (создаются здесь, заполняются модулями)
local function createTabContentFrame(name)
    local sf = FuckYouLib.create("ScrollingFrame", {Name = name, Parent = Containment, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = COL_BORDER, CanvasSize = UDim2.new(0, 0, 0, 0), Visible = false})
    local tl = FuckYouLib.create("UIListLayout", {Parent = sf, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
    FuckYouLib.create("UIPadding", {Parent = sf, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)})
    tl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sf.CanvasSize = UDim2.new(0, 0, 0, tl.AbsoluteContentSize.Y + 20)
    end)
    return sf
end

FuckYouLib.tabFrames = {
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
local tabFrames = FuckYouLib.tabFrames

--// Регистрация основных вкладок (EmilyUi)
local function switchTab(targetTab)
    for _, tab in ipairs(FuckYouLib.tabs) do
        tab.Frame.Visible = (tab == targetTab)
    end
    FuckYouLib.updateTabButtonsTheme()
end

local tabs = {}
for index, name in ipairs({"Main Info","Universal","Character","Players","Visuals","Utilities","Server","Games","Scripts","Script Hubs","GUIs","Animations","Key List","Settings"}) do
    local frame = tabFrames[name:gsub(" ","")]
    if not frame then
        local key = name:gsub(" ","")
        frame = tabFrames[key] or tabFrames.Main
    end
    local btn = FuckYouLib.create("TextButton", {
        Name = "Btn_" .. name, Parent = MenuInsided,
        Size = UDim2.new(1, 0, 0, 30), LayoutOrder = index, Visible = false,
        BackgroundColor3 = FuckYouLib.uiColor_ButtonColor, BorderColor3 = COL_BORDER,
        TextColor3 = FuckYouLib.uiColor_TextColor, Text = name, Font = FONT, TextSize = 12
    })
    table.insert(FuckYouLib.themeElements.Buttons, btn)
    table.insert(FuckYouLib.themeElements.Texts, btn)
    btn.MouseButton1Click:Connect(function() switchTab({Frame = frame, Button = btn, Name = name}) end)
    table.insert(tabs, {Frame = frame, Name = name, Button = btn})
end
FuckYouLib.tabs = tabs

-- По умолчанию показываем первую вкладку
switchTab(tabs[1])

--// Управление окном (сворачивание, закрытие)
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
    FuckYouLib.uiCollapsed = false
    FuckYouLib.applyBackground()
    tweenSize(FULL_SIZE)
    state = "full"
end

X.MouseButton1Click:Connect(function()
    state = "closed"
    ScreenGui:Destroy()
end)

Equal.MouseButton1Click:Connect(function()
    if state == "full" then
        state = "strip"
        FuckYouLib.uiCollapsed = true
        FuckYouLib.applyBackground()
        tweenSize(STRIP_SIZE)
    elseif state == "strip" then
        openFull()
    end
end)

Minus.MouseButton1Click:Connect(function()
    state = "hidden"
    FuckYouLib.uiCollapsed = true
    FuckYouLib.applyBackground()
    tweenSize(UDim2.new(0, 940, 0, 0), function()
        FuckYou.Visible = false
    end)
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == FuckYouLib.currentToggleKey and unlocked then
        if state == "hidden" then
            openFull()
        else
            state = "hidden"
            FuckYou.Visible = false
        end
    end
end)

-- Drag механизм для главного окна
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

--// Система ключей (Key System)
local KeyWindow = FuckYouLib.create("Frame", {Name = "KeyWindow", Parent = ScreenGui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 450, 0, 310), BackgroundColor3 = FuckYouLib.uiColor_MainWindow, BorderColor3 = COL_BORDER})
table.insert(FuckYouLib.themeElements.MainWindow, KeyWindow)

local KeyTopBar = FuckYouLib.create("Frame", {Parent = KeyWindow, Size = UDim2.new(1, 0, 0, 35), BackgroundColor3 = FuckYouLib.uiColor_TopBar, BorderSizePixel = 0})
table.insert(FuckYouLib.themeElements.TopBars, KeyTopBar)

local KeyTitle = FuckYouLib.create("TextLabel", {Parent = KeyTopBar, Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = "Fuck you! — Key System", TextColor3 = FuckYouLib.uiColor_TextColor, TextSize = 15, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left})
table.insert(FuckYouLib.themeElements.Texts, KeyTitle)

local KeyCloseBtn = FuckYouLib.create("TextButton", {Parent = KeyTopBar, Size = UDim2.new(0, 35, 0, 35), Position = UDim2.new(1, -35, 0, 0), BackgroundColor3 = Color3.fromRGB(120,40,40), BorderColor3 = COL_BORDER, TextColor3 = Color3.fromRGB(255,255,255), Text = "X", TextSize = 13, Font = FONT})
KeyCloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local KeyInfoLabel = FuckYouLib.create("TextLabel", {Parent = KeyWindow, Size = UDim2.new(1, -30, 0, 40), Position = UDim2.new(0, 15, 0, 50), BackgroundTransparency = 1, Text = "Please enter your access key below to load the script.\nKey can be obtained via Discord.", TextColor3 = FuckYouLib.uiColor_TextColor, TextSize = 13, Font = FONT, TextWrapped = true})
table.insert(FuckYouLib.themeElements.Texts, KeyInfoLabel)

local function copyDiscord()
    if setclipboard then setclipboard("https://discord.gg/75Dz8T9hHR") end
    FuckYouLib.notify("Discord", "The link is copied")
end

local KeyDiscordBtn = FuckYouLib.createContentButton(KeyWindow, "Click to copy Discord Server link", copyDiscord)
KeyDiscordBtn.Size = UDim2.new(1, -40, 0, 36)
KeyDiscordBtn.Position = UDim2.new(0, 20, 0, 105)

local KeyTextBox = FuckYouLib.createTextBox(KeyWindow, "Enter key here...", FONT)
KeyTextBox.Size = UDim2.new(1, -40, 0, 36)
KeyTextBox.Position = UDim2.new(0, 20, 0, 160)

makeDraggable(KeyTopBar, KeyWindow)

KeyWindow:GetPropertyChangedSignal("Visible"):Connect(function()
    if KeyWindow.Visible and FuckYouLib.uiBlurSize > 0 then
        blurEffect.Parent = game:GetService("Lighting")
        blurEffect.Size = FuckYouLib.uiBlurSize
        blurEffect.Enabled = true
    else
        FuckYouLib.updateBlur()
    end
end)

-- Крипто-функции
local SECRET_KEY = "XenoMeowEmilyUi11037"
local b64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

local function base64_decode(data)
    data = string.gsub(data, '[^'..b64..'=]', '')
    return (data:gsub('.', function(x)
        if x == '=' then return '' end
        local r, f = '', (b64:find(x) - 1)
        for i = 6, 1, -1 do
            r = r .. (f % 2^i - f % 2^(i - 1) > 0 and '1' or '0')
        end
        return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if #x ~= 8 then return '' end
        local c = 0
        for i = 1, 8 do
            c = c + (x:sub(i, i) == '1' and 2^(8 - i) or 0)
        end
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
        s.Volume = 1
        s.Looped = false
        s.TimePosition = 0
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

local cachedKeyResponse = nil
local currentKeyData = { group = "Free", daysLeft = "Infinity" }
local unlocked = false
local beta = false

function FuckYouLib.unlockScript(userGroup, daysLeft)
    unlocked = true
    playUnlockJingle()
    KeyWindow:Destroy()
    FuckYou.Visible = true
    state = "full"
    -- обновим профиль позже через EmilyUi
    FuckYouLib.loadConfig()
    FuckYouLib.applyBackground()
    FuckYouLib.updateBlur()
    FuckYouLib.applyTheme()
    local lastCfgName = FuckYouLib.getLastConfigName()
    if lastCfgName then
        FuckYouLib.loadNamedConfig(lastCfgName)
    end
    if FuckYouLib.autoSaveConfig then FuckYouLib.autoSaveConfig(true) end
    FuckYouLib.notify("Fuck you! is loaded", "Welcome! Role: " .. (userGroup or "User"))
end

local function isGroupAllowed(groupName)
    local g = string.lower(tostring(groupName or ""))
    if beta then
        return g == "tester" or g == "coder"
    else
        return g == "free" or g == "user" or g == "tester" or g == "coder"
    end
end

local function checkKeySystem()
    if not cachedKeyResponse then
        local success, response = pcall(function()
            return game:HttpGet("https://raw.githubusercontent.com/MamaSdoxla/EmilyUi/refs/heads/main/nuh-uh.json")
        end)
        if not success or not response or #response < 10 then
            KeyInfoLabel.Text = "Error: Failed to fetch key database!"
            KeyInfoLabel.TextColor3 = Color3.fromRGB(220,50,50)
            return
        end
        local ok, decryptedText = pcall(function() return decryptData(response, SECRET_KEY) end)
        if not ok or not decryptedText or #decryptedText < 5 then
            KeyInfoLabel.Text = "Error: Failed to decrypt!\nLen: " .. tostring(decryptedText and #decryptedText or 0)
            KeyInfoLabel.TextColor3 = Color3.fromRGB(220,50,50)
            return
        end
        cachedKeyResponse = decryptedText
    end
    local jsonSuccess, keysList = pcall(function() return HttpService:JSONDecode(cachedKeyResponse) end)
    if not jsonSuccess or type(keysList) ~= "table" then
        KeyInfoLabel.Text = "Error: Database parsing failed!\nPreview: " .. string.sub(tostring(cachedKeyResponse), 1, 60)
        KeyInfoLabel.TextColor3 = Color3.fromRGB(220,50,50)
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
                        FuckYouLib.unlockScript(data.group, daysLeft)
                        return
                    end
                end
            end
        end
    end
    if beta then
        KeyInfoLabel.Text = "Beta mode: only Tester/Coder keys are allowed."
    else
        KeyInfoLabel.Text = "Enter key please! You can ask for a key in discord."
    end
    KeyInfoLabel.TextColor3 = Color3.fromRGB(255,255,255)
end

local BtnSubmit = FuckYouLib.createContentButton(KeyWindow, "Check Key", checkKeySystem, Color3.fromRGB(40,90,40))
BtnSubmit.Size = UDim2.new(0, 150, 0, 36)
BtnSubmit.Position = UDim2.new(0.5, -75, 0, 240)

task.spawn(checkKeySystem)

--// Key List Module (встроен в библиотеку)
local KL_FILE = "EmilyUi/FuckYou/KeyListSettings.json"
local KL = {
    Enabled = true,
    ShowEmily = true,
    ShowDesync = true,
    ShowMusic = true,
    ShowAim = true,
    ShowMovement = true,
}
local function ensureDirsKL()
    if makefolder then pcall(function()
        if not isfolder("EmilyUi") then makefolder("EmilyUi") end
        if not isfolder("EmilyUi/FuckYou") then makefolder("EmilyUi/FuckYou") end
    end) end
end
local function saveKL()
    if writefile then
        ensureDirsKL()
        pcall(function() writefile(KL_FILE, HttpService:JSONEncode(KL)) end)
    end
    if FuckYouLib.autoSaveConfig then FuckYouLib.autoSaveConfig() end
end
local function applyKL(d)
    if type(d) ~= "table" then return end
    local function bb(v, def) if v == nil then return def end return v and true or false end
    KL.Enabled = bb(d.Enabled, KL.Enabled)
    KL.ShowEmily = bb(d.ShowEmily, KL.ShowEmily)
    KL.ShowDesync = bb(d.ShowDesync, KL.ShowDesync)
    KL.ShowMusic = bb(d.ShowMusic, KL.ShowMusic)
    KL.ShowAim = bb(d.ShowAim, KL.ShowAim)
    KL.ShowMovement = bb(d.ShowMovement, KL.ShowMovement)
end
local function loadKL()
    if isfile and isfile(KL_FILE) and readfile then
        local ok, json = pcall(function() return readfile(KL_FILE) end)
        if ok and json then
            local ok2, d = pcall(function() return HttpService:JSONDecode(json) end)
            if ok2 and type(d) == "table" then applyKL(d) end
        end
    end
end
loadKL()

local overlay = FuckYouLib.create("Frame", {
    Name = "FYKeyList", Parent = ScreenGui,
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -16, 1, -16),
    Size = UDim2.new(0, 250, 0, 60),
    BackgroundColor3 = FuckYouLib.uiColor_MainWindow,
    BorderColor3 = COL_BORDER, BorderSizePixel = 1,
    Visible = false, ZIndex = 5,
})
table.insert(FuckYouLib.themeElements.MainWindow, overlay)
local topLine = FuckYouLib.create("Frame", {Parent = overlay, Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0, ZIndex = 6})
FuckYouLib.create("UIGradient", {Parent = topLine, Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0,170,255)),
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(170,80,255)),
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(255,90,160)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255,190,60)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(150,255,80)),
})})
local titleBar = FuckYouLib.create("TextLabel", {Parent = overlay, Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0, 0, 0, 2), BackgroundTransparency = 1, Text = "KEYBINDS", TextColor3 = FuckYouLib.uiColor_TextColor, TextSize = 13, Font = FONT, ZIndex = 6})
table.insert(FuckYouLib.themeElements.Texts, titleBar)
local rowsFrame = FuckYouLib.create("Frame", {Parent = overlay, Size = UDim2.new(1, 0, 1, -26), Position = UDim2.new(0, 0, 0, 26), BackgroundTransparency = 1, ZIndex = 6})
local rowsLayout = FuckYouLib.create("UIListLayout", {Parent = rowsFrame, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)})
FuckYouLib.create("UIPadding", {Parent = rowsFrame, PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 8)})

local GROUP_MAP = {
    {"ShowEmily", "EmilyUi", "EMILYUI"},
    {"ShowDesync", "Desync", "DESYNC"},
    {"ShowMusic", "Music", "MUSIC"},
    {"ShowAim", "Aim", "AIM"},
    {"ShowMovement", "Movement", "MOVEMENT"},
}

local function collectRows()
    local out = {}
    for _, g in ipairs(GROUP_MAP) do
        if KL[g[1]] then
            local fn = FuckYouLib.keyListProviders[g[2]]
            if fn then
                local ok, rows = pcall(fn)
                rows = (ok and type(rows) == "table") and rows or {}
                if #rows > 0 then
                    table.insert(out, {"h", g[3]})
                    for _, r in ipairs(rows) do
                        table.insert(out, {"r", tostring(r[1]), tostring(r[2])})
                    end
                end
            end
        end
    end
    return out
end

local function rebuildKL()
    for _, ch in ipairs(rowsFrame:GetChildren()) do
        if ch:IsA("Frame") or ch:IsA("TextLabel") then ch:Destroy() end
    end
    for i, it in ipairs(collectRows()) do
        if it[1] == "h" then
            local h = FuckYouLib.create("TextLabel", {Parent = rowsFrame, LayoutOrder = i, Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Text = it[2], TextColor3 = FuckYouLib.uiColor_TextColor, TextSize = 11, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6})
            table.insert(FuckYouLib.themeElements.Texts, h)
        else
            local r = FuckYouLib.create("Frame", {Parent = rowsFrame, LayoutOrder = i, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, ZIndex = 6})
            local l = FuckYouLib.create("TextLabel", {Parent = r, Size = UDim2.new(0.62, 0, 1, 0), BackgroundTransparency = 1, Text = it[2], TextColor3 = FuckYouLib.uiColor_TextColor, TextSize = 12, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6})
            table.insert(FuckYouLib.themeElements.Texts, l)
            FuckYouLib.create("TextLabel", {Parent = r, Size = UDim2.new(0.38, 0, 1, 0), Position = UDim2.new(0.62, 0, 0, 0), BackgroundTransparency = 1, Text = it[3], TextColor3 = FuckYouLib.uiColor_ToggleOnText, TextSize = 12, Font = FONT, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6})
        end
    end
    local function fitSize()
        if overlay.Parent then
            overlay.Size = UDim2.new(0, 250, 0, 26 + rowsLayout.AbsoluteContentSize.Y + 8)
        end
    end
    fitSize()
    task.defer(fitSize)
end

local lastSnap = ""
local function refreshKL(force)
    if not overlay or not overlay.Parent then return end
    local vis = (KL.Enabled and unlocked) and true or false
    overlay.Visible = vis
    if not vis then return end
    local t = {}
    for _, it in ipairs(collectRows()) do table.insert(t, table.concat(it, "|")) end
    local snap = table.concat(t, "#")
    if force or snap ~= lastSnap then
        lastSnap = snap
        rebuildKL()
    end
end

local baseApplyThemeKL = FuckYouLib.applyTheme
FuckYouLib.applyTheme = function()
    baseApplyThemeKL()
    lastSnap = ""
    refreshKL(true)
end

-- Drag для оверлея
local draggingO, dragInputO, dragStartO, startPositionO
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingO = true
        dragStartO = input.Position
        startPositionO = overlay.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then draggingO = false end
        end)
    end
end)
titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInputO = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInputO and draggingO then
        local delta = input.Position - dragStartO
        overlay.Position = UDim2.new(startPositionO.X.Scale, startPositionO.X.Offset + delta.X, startPositionO.Y.Scale, startPositionO.Y.Offset + delta.Y)
    end
end)

-- Вкладка Key List (настройки оверлея) добавляется в tabFrames.KeyList
local kltab = tabFrames.KeyList
FuckYouLib.createSection(kltab, "Key List Overlay")
local function klToggle(labelText, get, set)
    local btn = FuckYouLib.create("TextButton", {
        Parent = kltab, Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = FuckYouLib.uiColor_ButtonColor, BorderColor3 = COL_BORDER,
        BackgroundTransparency = 1 - FuckYouLib.uiGuiOpacity,
        TextColor3 = FuckYouLib.uiColor_TextColor, Text = "", Font = FONT, TextSize = 13,
    })
    table.insert(FuckYouLib.themeElements.CustomButtons, btn)
    table.insert(FuckYouLib.themeElements.Texts, btn)
    local function paint()
        btn.Text = labelText .. ": " .. (get() and "ON" or "OFF")
        FuckYouLib.paintToggleBtn(btn, get())
    end
    FuckYouLib.registerToggle(btn, get)
    btn.MouseButton1Click:Connect(function()
        set(not get())
        paint()
        saveKL()
        refreshKL(true)
    end)
    paint()
    return btn
end
klToggle("Show Key List", function() return KL.Enabled end, function(v) KL.Enabled = v end)
klToggle("Show: EmilyUi", function() return KL.ShowEmily end, function(v) KL.ShowEmily = v end)
klToggle("Show: Desync", function() return KL.ShowDesync end, function(v) KL.ShowDesync = v end)
klToggle("Show: Music", function() return KL.ShowMusic end, function(v) KL.ShowMusic = v end)
klToggle("Show: Aim", function() return KL.ShowAim end, function(v) KL.ShowAim = v end)
klToggle("Show: Movement", function() return KL.ShowMovement end, function(v) KL.ShowMovement = v end)
FuckYouLib.createContentButton(kltab, "Refresh Key List", function() refreshKL(true) end)

task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(refreshKL)
    end
end)
refreshKL(true)

-- Экспорт API для KeyList
KeyListAPI = {
    Gather = function()
        local out = {}
        for k, v in pairs(KL) do out[k] = v end
        return out
    end,
    Apply = function(d)
        applyKL(d)
        saveKL()
        refreshKL(true)
    end,
    Reset = function()
        KL.Enabled = true
        KL.ShowEmily = true
        KL.ShowDesync = true
        KL.ShowMusic = true
        KL.ShowAim = true
        KL.ShowMovement = true
        saveKL()
        refreshKL(true)
    end,
}
_G.KeyListAPI = KeyListAPI

--// Функции для сохранения/загрузки конфигов (общие)
function FuckYouLib.getLastConfigName()
    local lastPath = "EmilyUi/FuckYou/Configs/last_config.txt"
    if readfile and isfile and isfile(lastPath) then
        local ok, name = pcall(function() return readfile(lastPath) end)
        if ok and name and name ~= "" then return name end
    end
    return nil
end

function FuckYouLib.setLastConfigName(name)
    local lastPath = "EmilyUi/FuckYou/Configs/last_config.txt"
    if writefile then pcall(function() writefile(lastPath, name) end) end
end

function FuckYouLib.loadNamedConfig(name)
    if not writefile or not readfile then
        FuckYouLib.notify("Configs", "Executor doesn't support files")
        return
    end
    local configFolder = "EmilyUi/FuckYou/Configs"
    local path = configFolder .. "/" .. name .. ".json"
    if isfile and isfile(path) then
        local ok, json = pcall(function() return readfile(path) end)
        if ok then
            local ok2, cfg = pcall(function() return HttpService:JSONDecode(json) end)
            if ok2 and type(cfg) == "table" then
                FuckYouLib.applyConfigValues(cfg)
                FuckYouLib.setLastConfigName(name)
                FuckYouLib.notify("Configs", "Loaded: " .. name)
            end
        end
    else
        FuckYouLib.notify("Configs", "Config not found: " .. name)
    end
end

function FuckYouLib.applyConfigValues(cfg)
    if type(cfg.ToggleKey) == "string" then
        pcall(function()
            FuckYouLib.currentToggleKey = Enum.KeyCode[cfg.ToggleKey]
            if keyBindBtn then keyBindBtn.Text = FuckYouLib.currentToggleKey.Name end
        end)
    end
    if cfg.MainWindowColor then FuckYouLib.uiColor_MainWindow = Color3.new(unpack(cfg.MainWindowColor)) end
    if cfg.TopBarColor then FuckYouLib.uiColor_TopBar = Color3.new(unpack(cfg.TopBarColor)) end
    if cfg.SideBarColor then FuckYouLib.uiColor_SideBar = Color3.new(unpack(cfg.SideBarColor)) end
    if cfg.TextColor then FuckYouLib.uiColor_TextColor = Color3.new(unpack(cfg.TextColor)) end
    if cfg.ButtonColor then FuckYouLib.uiColor_ButtonColor = Color3.new(unpack(cfg.ButtonColor)) end
    if cfg.TextBoxColor then FuckYouLib.uiColor_TextBoxColor = Color3.new(unpack(cfg.TextBoxColor)) end
    if cfg.ToggleOnColor then FuckYouLib.uiColor_ToggleOnText = Color3.new(unpack(cfg.ToggleOnColor)) end
    if cfg.ToggleOffColor then FuckYouLib.uiColor_ToggleOffText = Color3.new(unpack(cfg.ToggleOffColor)) end
    FuckYouLib.applyTheme()
    if unlocked then
        if cfg.Visuals and VisualsAPI and VisualsAPI.Apply then VisualsAPI.Apply(cfg.Visuals) end
        if cfg.Aim and AimAPI and AimAPI.Apply then AimAPI.Apply(cfg.Aim) end
        if cfg.Movement and MovementAPI and MovementAPI.Apply then MovementAPI.Apply(cfg.Movement) end
        if cfg.KeyList and KeyListAPI and KeyListAPI.Apply then KeyListAPI.Apply(cfg.KeyList) end
    end
end

-- Применяем тему один раз в конце
FuckYouLib.applyTheme()

-- Автосохранение каждые 10 минут
task.spawn(function()
    while true do
        task.wait(600)
        if FuckYouLib.autoSaveConfig then FuckYouLib.autoSaveConfig(true) end
    end
end)

return FuckYouLib