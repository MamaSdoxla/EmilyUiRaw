--// FuckYouLibrary.lua — Core Library
--// Отвечает за GUI, темы, конфиги, ключи, базовые UI-компоненты
---@diagnostic disable: undefined-global

local Library = {}
Library._VERSION = "1.2"

--// ==================== СЕРВИСЫ ====================
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

--// ==================== СТИЛЬ ====================
Library.COL_BG = Color3.fromRGB(12, 12, 12)
Library.COL_BORDER = Color3.fromRGB(22, 22, 22)
Library.COL_TEXT = Color3.fromRGB(139, 135, 127)
Library.COL_TEXTBOX = Color3.fromRGB(18, 18, 18)
Library.FONT = Enum.Font.SpecialElite

--// ==================== СОСТОЯНИЕ ====================
Library.currentToggleKey = Enum.KeyCode.P
Library.uiColor_MainWindow = Library.COL_BG
Library.uiColor_TopBar = Library.COL_BG
Library.uiColor_SideBar = Library.COL_BG
Library.uiColor_TextColor = Library.COL_TEXT
Library.uiColor_ButtonColor = Library.COL_BG
Library.uiColor_TextBoxColor = Library.COL_TEXTBOX
Library.uiColor_ToggleOnText = Color3.fromRGB(100, 255, 100)
Library.uiColor_ToggleOffText = Color3.fromRGB(255, 100, 100)
Library.uiGuiOpacity = 1
Library.uiImageOpacity = 1
Library.uiBlurSize = 0
Library.uiFitMode = "Fill"
Library.uiBackgroundFile = ""
Library.uiCollapsed = false
Library.unlocked = false
Library.beta = false

--// ==================== РЕЕСТРЫ ====================
Library.themeElements = {
    MainWindow = {}, TopBars = {}, SideBars = {},
    Texts = {}, Buttons = {}, TextBoxes = {},
    FillBars = {}, CustomButtons = {}
}
Library.moduleToggles = {}
Library.toggleRegistry = {}
Library.keyListProviders = {}
Library.configSaveListeners = {}

--// ==================== ССЫЛКИ НА МОДУЛИ ====================
Library.VisualsAPI = nil
Library.AimAPI = nil
Library.MovementAPI = nil
Library.KeyListAPI = nil

--// ==================== ГЛОБАЛЬНЫЕ UI-ОБЪЕКТЫ ====================
Library.ScreenGui = nil
Library.FuckYou = nil
Library.TopBar = nil
Library.SideBard = nil
Library.MenuInsided = nil
Library.Containment = nil
Library.BackgroundImage = nil
Library.blurEffect = nil
Library.KeyWindow = nil
Library.tabs = {}

--// ==================== УТИЛИТЫ ====================
function Library.create(className, properties)
    local inst = Instance.new(className)
    for k, v in pairs(properties) do inst[k] = v end
    return inst
end

function Library.scaleColor(c, f)
    return Color3.fromRGB(
        math.clamp(c.R*255*f,0,255),
        math.clamp(c.G*255*f,0,255),
        math.clamp(c.B*255*f,0,255)
    )
end

function Library.lighter(c, amt)
    return Color3.fromRGB(
        math.min(c.R*255+amt, 255),
        math.min(c.G*255+amt, 255),
        math.min(c.B*255+amt, 255)
    )
end

function Library.darker(c, amt)
    return Color3.fromRGB(
        math.max(c.R*255-amt, 0),
        math.max(c.G*255-amt, 0),
        math.max(c.B*255-amt, 0)
    )
end

function Library.parseRGB(str)
    local r, g, b = string.match(str, "(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
    return r and Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b)) or nil
end

function Library.formatColor(c)
    return math.floor(c.R*255)..", "..math.floor(c.G*255)..", "..math.floor(c.B*255)
end

--// ==================== УВЕДОМЛЕНИЯ ====================
function Library.notify(title, text)
    task.spawn(function()
        local notificationData = {Title = title, Text = text, Duration = 15}
        local coreSuccess = false
        for _ = 1, 10 do
            coreSuccess = pcall(function()
                StarterGui:SetCore("SendNotification", notificationData)
            end)
            if coreSuccess then return end
            task.wait(0.2)
        end
        pcall(function()
            local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
                or LocalPlayer:WaitForChild("PlayerGui", 5)
            if not playerGui then return end
            local gui = Library.create("ScreenGui", {
                Name = "FallbackNotification", ResetOnSpawn = false,
                IgnoreGuiInset = true, Parent = playerGui
            })
            local main = Library.create("Frame", {
                AnchorPoint = Vector2.new(1, 1),
                Position = UDim2.new(1, -16, 1, -16),
                Size = UDim2.new(0, 300, 0, 64),
                BackgroundColor3 = Library.COL_BG,
                BorderColor3 = Library.COL_BORDER,
                BorderSizePixel = 1, Parent = gui
            })
            Library.create("TextLabel", {
                Size = UDim2.new(1, -16, 0, 20),
                Position = UDim2.new(0, 8, 0, 6),
                BackgroundTransparency = 1, Text = title,
                Font = Library.FONT, TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = Color3.fromRGB(255, 255, 255), Parent = main
            })
            Library.create("TextLabel", {
                Size = UDim2.new(1, -16, 0, 30),
                Position = UDim2.new(0, 8, 0, 26),
                BackgroundTransparency = 1, Text = text,
                Font = Library.FONT, TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true, TextColor3 = Library.COL_TEXT, Parent = main
            })
            task.delay(notificationData.Duration or 15, function() gui:Destroy() end)
        end)
    end)
end

--// ==================== TOGGLE СИСТЕМА ====================
function Library.paintToggleBtn(btn, on)
    if on then
        btn.BackgroundColor3 = Library.scaleColor(Library.uiColor_ToggleOnText, 0.35)
        btn.TextColor3 = Library.uiColor_ToggleOnText
    else
        btn.BackgroundColor3 = Library.scaleColor(Library.uiColor_ToggleOffText, 0.35)
        btn.TextColor3 = Library.uiColor_ToggleOffText
    end
end

function Library.registerToggle(btn, getState)
    Library.toggleRegistry[btn] = getState
    Library.paintToggleBtn(btn, getState() and true or false)
end

--// ==================== KEY LIST PROVIDERS ====================
function Library.registerKeyListProvider(group, fn)
    Library.keyListProviders[group] = fn
end

--// ==================== DRAG ====================
function Library.makeDraggable(dragFrame, targetFrame)
    local dragging, dragInput, dragStart, startPosition
    dragFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = targetFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    dragFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            targetFrame.Position = UDim2.new(
                startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
            )
        end
    end)
end

--// ==================== БАЗОВЫЕ UI КОМПОНЕНТЫ ====================
function Library.createSection(parent, text)
    local lbl = Library.create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1,
        Text = text, TextColor3 = Library.uiColor_TextColor,
        TextSize = 13, Font = Library.FONT, Parent = parent
    })
    table.insert(Library.themeElements.Texts, lbl)
    return lbl
end

function Library.createLabel(parent, text)
    local lbl = Library.create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1,
        Text = text, TextColor3 = Library.uiColor_TextColor,
        TextSize = 13, Font = Library.FONT,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = parent
    })
    table.insert(Library.themeElements.Texts, lbl)
    return lbl
end

function Library.createContentButton(parent, text, callback, customColor)
    local defaultColor = customColor or Library.uiColor_ButtonColor
    local btn = Library.create("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = defaultColor,
        BorderColor3 = Library.COL_BORDER,
        TextColor3 = Library.uiColor_TextColor,
        Text = text, Font = Library.FONT, TextSize = 13,
        BackgroundTransparency = 1 - Library.uiGuiOpacity,
        Parent = parent
    })
    if not customColor then
        table.insert(Library.themeElements.Buttons, btn)
    end
    table.insert(Library.themeElements.Texts, btn)
    btn.MouseEnter:Connect(function()
        local c = btn.BackgroundColor3
        btn.BackgroundColor3 = Color3.fromRGB(
            math.min(c.R*255+10,255),
            math.min(c.G*255+10,255),
            math.min(c.B*255+10,255)
        )
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = customColor or Library.uiColor_ButtonColor
    end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

function Library.createTextBox(parent, placeholder, font)
    local box = Library.create("TextBox", {
        BackgroundColor3 = Library.uiColor_TextBoxColor,
        BorderColor3 = Library.COL_BORDER,
        TextColor3 = Library.uiColor_TextColor,
        PlaceholderColor3 = Color3.fromRGB(90, 90, 90),
        PlaceholderText = placeholder, Text = "",
        TextSize = 13, Font = font or Library.FONT,
        ClearTextOnFocus = false,
        BackgroundTransparency = 1 - Library.uiGuiOpacity,
        Parent = parent
    })
    table.insert(Library.themeElements.Texts, box)
    table.insert(Library.themeElements.TextBoxes, box)
    return box
end

function Library.createSlider(parent, labelText, min, max, getval, onval, fmt)
    local container = Library.create("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1, Parent = parent
    })
    local label = Library.create("TextLabel", {
        Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1,
        Text = labelText, TextColor3 = Library.uiColor_TextColor,
        TextSize = 13, Font = Library.FONT,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = container
    })
    table.insert(Library.themeElements.Texts, label)
    local valLabel = Library.create("TextLabel", {
        Size = UDim2.new(0.5, 0, 0, 14),
        Position = UDim2.new(0.48, 0, 0.05, 0),
        BackgroundTransparency = 1, Text = fmt(getval()),
        TextColor3 = Library.uiColor_TextColor,
        TextSize = 13, Font = Library.FONT,
        TextXAlignment = Enum.TextXAlignment.Right, Parent = container
    })
    table.insert(Library.themeElements.Texts, valLabel)
    local track = Library.create("TextButton", {
        Size = UDim2.new(0.5, 0, 0, 10),
        Position = UDim2.new(0.48, 0, 0.55, 0),
        BackgroundColor3 = Library.uiColor_TextBoxColor,
        BorderColor3 = Library.COL_BORDER,
        Text = "", Parent = container
    })
    table.insert(Library.themeElements.TextBoxes, track)
    local fill = Library.create("Frame", {
        Size = UDim2.new((getval() - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = Library.uiColor_TextColor,
        BorderSizePixel = 0, Parent = track
    })
    table.insert(Library.themeElements.FillBars, fill)
    local dragging = false
    local function setFromX(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = math.floor(min + (max - min) * rel + 0.5)
        onval(v)
        fill.Size = UDim2.new((v - min) / (max - min), 0, 1, 0)
        valLabel.Text = fmt(v)
    end
    track.MouseButton1Down:Connect(function(x) dragging = true; setFromX(x) end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    return container
end

function Library.createDropdown(parent, labelText, getOptions, getCurrent, onselect)
    local container = Library.create("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1, Parent = parent
    })
    local label = Library.create("TextLabel", {
        Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1,
        Text = labelText, TextColor3 = Library.uiColor_TextColor,
        TextSize = 13, Font = Library.FONT,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = container
    })
    table.insert(Library.themeElements.Texts, label)
    local btn = Library.createContentButton(container, labelText .. ": " .. getCurrent(), function() end)
    btn.Size = UDim2.new(0.5, 0, 0.8, 0)
    btn.Position = UDim2.new(0.48, 0, 0.1, 0)
    btn.TextSize = 12
    local list = Library.create("ScrollingFrame", {
        Parent = container,
        Size = UDim2.new(0.5, 0, 0, 110),
        Position = UDim2.new(0.48, 0, 0.95, 0),
        BackgroundColor3 = Library.uiColor_TextBoxColor,
        BorderColor3 = Library.COL_BORDER,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = false, ZIndex = 25
    })
    table.insert(Library.themeElements.TextBoxes, list)
    Library.create("UIListLayout", {
        Parent = list, SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2)
    })
    btn.MouseButton1Click:Connect(function()
        if list.Visible then list.Visible = false return end
        for _, ch in ipairs(list:GetChildren()) do
            if ch:IsA("TextButton") then ch:Destroy() end
        end
        local opts = getOptions()
        for _, opt in ipairs(opts) do
            local ob = Library.createContentButton(list, opt, function()
                onselect(opt)
                list.Visible = false
                btn.Text = labelText .. ": " .. getCurrent()
            end)
            ob.Size = UDim2.new(1, -4, 0, 24)
            ob.ZIndex = 26
            ob.TextSize = 12
        end
        list.CanvasSize = UDim2.new(0, 0, 0, #opts * 26 + 4)
        list.Visible = true
    end)
    return container
end

function Library.createColorInput(parent, labelText, getcol, oncol)
    local container = Library.create("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1, Parent = parent
    })
    local label = Library.create("TextLabel", {
        Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1,
        Text = labelText, TextColor3 = Library.uiColor_TextColor,
        TextSize = 13, Font = Library.FONT,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = container
    })
    table.insert(Library.themeElements.Texts, label)
    local c = getcol()
    local box = Library.createTextBox(container, "R,G,B", Library.FONT)
    box.Size = UDim2.new(0.5, 0, 0.8, 0)
    box.Position = UDim2.new(0.48, 0, 0.1, 0)
    box.TextSize = 12
    box.Text = math.floor(c.R * 255) .. ", " .. math.floor(c.G * 255) .. ", " .. math.floor(c.B * 255)
    box.FocusLost:Connect(function()
        local r, g, b = box.Text:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
        if r and g and b then
            oncol(Color3.fromRGB(
                math.clamp(tonumber(r), 0, 255),
                math.clamp(tonumber(g), 0, 255),
                math.clamp(tonumber(b), 0, 255)
            ))
        else
            box.Text = "Invalid!"
        end
    end)
    return container
end

function Library.createToggle(parent, labelText, initial, callback)
    local obj = {State = initial and true or false}
    local btn = Library.create("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Library.uiColor_ButtonColor,
        BorderColor3 = Library.COL_BORDER,
        BackgroundTransparency = 1 - Library.uiGuiOpacity,
        TextColor3 = Library.uiColor_TextColor,
        Text = "", Font = Library.FONT, TextSize = 13,
        Parent = parent
    })
    obj.Button = btn
    table.insert(Library.themeElements.CustomButtons, btn)
    table.insert(Library.themeElements.Texts, btn)
    local function paint()
        btn.Text = labelText .. ": " .. (obj.State and "ON" or "OFF")
        Library.paintToggleBtn(btn, obj.State)
    end
    function obj:Get() return self.State end
    function obj:Set(v)
        self.State = v and true or false
        paint()
        if callback then callback(self.State) end
    end
    paint()
    Library.registerToggle(btn, function() return obj.State end)
    btn.MouseButton1Click:Connect(function()
        obj:Set(not obj.State)
    end)
    return obj
end

--// ==================== СОЗДАНИЕ ГЛАВНОГО GUI ====================
function Library.initGUI()
    Library.ScreenGui = Library.create("ScreenGui", {
        Name = "FuckYouGui", ResetOnSpawn = false,
        Parent = LocalPlayer:WaitForChild("PlayerGui")
    })

    Library.FuckYou = Library.create("Frame", {
        Name = "FuckYou", Parent = Library.ScreenGui,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 940, 0, 510),
        ClipsDescendants = true, Visible = false,
        BackgroundColor3 = Library.uiColor_MainWindow,
        BorderColor3 = Library.COL_BORDER, BorderSizePixel = 1
    })
    table.insert(Library.themeElements.MainWindow, Library.FuckYou)

    -- Background Image
    Library.BackgroundImage = Library.create("ImageLabel", {
        Name = "BackgroundImage", Parent = Library.FuckYou,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, Image = "", Visible = false,
        ScaleType = Enum.ScaleType.Stretch,
        ImageTransparency = 0, ZIndex = 0,
    })

    -- Blur
    Library.blurEffect = Instance.new("BlurEffect")
    Library.blurEffect.Name = "FuckYouBlur"
    Library.blurEffect.Size = 0
    Library.blurEffect.Enabled = false

    -- Top Bar
    Library.TopBar = Library.create("Frame", {
        Name = "TopBar", Parent = Library.FuckYou,
        Size = UDim2.new(1, 0, 0, 45),
        BackgroundColor3 = Library.uiColor_TopBar, BorderSizePixel = 0
    })
    table.insert(Library.themeElements.TopBars, Library.TopBar)

    Library.create("TextLabel", {
        Name = "Name", Parent = Library.TopBar,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "Fuck you! v" .. Library._VERSION,
        TextColor3 = Library.uiColor_TextColor,
        TextSize = 13, Font = Library.FONT
    })

    -- Side Bar
    Library.SideBard = Library.create("Frame", {
        Name = "SideBard", Parent = Library.FuckYou,
        Position = UDim2.new(0, 0, 0, 45),
        Size = UDim2.new(0, 65, 1, -45),
        BackgroundColor3 = Library.uiColor_SideBar, BorderSizePixel = 0
    })
    table.insert(Library.themeElements.SideBars, Library.SideBard)

    -- Menu (вкладки)
    Library.MenuInsided = Library.create("ScrollingFrame", {
        Name = "MenuInsided", Parent = Library.FuckYou,
        Position = UDim2.new(0, 65, 0, 45),
        Size = UDim2.new(0, 105, 1, -45),
        BackgroundColor3 = Library.uiColor_SideBar, BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Library.COL_BORDER,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ClipsDescendants = true
    })
    table.insert(Library.themeElements.SideBars, Library.MenuInsided)

    -- Containment
    Library.Containment = Library.create("Frame", {
        Name = "Containment", Parent = Library.FuckYou,
        Position = UDim2.new(0, 170, 0, 45),
        Size = UDim2.new(1, -170, 1, -45),
        BackgroundTransparency = 1, BorderSizePixel = 0
    })

    -- Разделители
    Library.create("Frame", {
        Name = "SepH", Parent = Library.FuckYou,
        Position = UDim2.new(0, 0, 0, 45),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Library.COL_BORDER, BorderSizePixel = 0
    })
    Library.create("Frame", {
        Name = "SepV1", Parent = Library.FuckYou,
        Position = UDim2.new(0, 65, 0, 46),
        Size = UDim2.new(0, 1, 1, -46),
        BackgroundColor3 = Library.COL_BORDER, BorderSizePixel = 0
    })
    Library.create("Frame", {
        Name = "SepV2", Parent = Library.FuckYou,
        Position = UDim2.new(0, 170, 0, 46),
        Size = UDim2.new(0, 1, 1, -46),
        BackgroundColor3 = Library.COL_BORDER, BorderSizePixel = 0
    })
end

--// ==================== СОЗДАНИЕ КНОПОК САЙДБАРА ====================
function Library.makeSideBtn(text, offsetY)
    local b = Library.create("TextButton", {
        Name = text, Parent = Library.SideBard,
        Position = UDim2.new(0, 0, 0, offsetY),
        Size = UDim2.new(1, 0, 0, 59),
        BackgroundColor3 = Library.uiColor_SideBar,
        BorderColor3 = Library.COL_BORDER,
        Text = text, TextColor3 = Library.uiColor_TextColor,
        TextSize = 12, Font = Library.FONT
    })
    table.insert(Library.themeElements.SideBars, b)
    table.insert(Library.themeElements.Texts, b)
    return b
end

function Library.makeTopBtn(symbol, offset)
    local b = Library.create("TextButton", {
        Name = symbol, Parent = Library.TopBar,
        Position = UDim2.new(1, -45 * offset, 0, 0),
        Size = UDim2.new(0, 45, 0, 45),
        BackgroundColor3 = Library.uiColor_TopBar,
        BorderColor3 = Library.COL_BORDER,
        Text = symbol, TextColor3 = Library.uiColor_TextColor,
        TextSize = 13, Font = Library.FONT
    })
    table.insert(Library.themeElements.TopBars, b)
    table.insert(Library.themeElements.Texts, b)
    b.MouseEnter:Connect(function()
        local c = b.BackgroundColor3
        b.BackgroundColor3 = Color3.fromRGB(
            math.min(c.R*255+10,255),
            math.min(c.G*255+10,255),
            math.min(c.B*255+10,255)
        )
    end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = Library.uiColor_TopBar end)
    return b
end

--// ==================== СОЗДАНИЕ ТАБОВ ====================
function Library.createTabContentFrame(name)
    local sf = Library.create("ScrollingFrame", {
        Name = name, Parent = Library.Containment,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Library.COL_BORDER,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = false
    })
    local tl = Library.create("UIListLayout", {
        Parent = sf, SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6)
    })
    Library.create("UIPadding", {
        Parent = sf,
        PaddingTop = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10)
    })
    tl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sf.CanvasSize = UDim2.new(0, 0, 0, tl.AbsoluteContentSize.Y + 20)
    end)
    return sf
end

--// ==================== ТЕМА ====================
function Library.updateTabButtonsTheme()
    for _, tab in ipairs(Library.tabs) do
        if tab.Button then
            if tab.Frame.Visible then
                tab.Button.BackgroundColor3 = Library.uiColor_ButtonColor
                tab.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                local c = Library.uiColor_ButtonColor
                tab.Button.BackgroundColor3 = Color3.fromRGB(
                    math.max(c.R*255-10, 0),
                    math.max(c.G*255-10, 0),
                    math.max(c.B*255-10, 0)
                )
                tab.Button.TextColor3 = Library.uiColor_TextColor
            end
        end
    end
    -- Обновление тем модулей (вызывается через коллбэки)
    if Library._moduleThemeUpdaters then
        for _, fn in ipairs(Library._moduleThemeUpdaters) do
            pcall(fn)
        end
    end
end

Library._moduleThemeUpdaters = {}
function Library.registerThemeUpdater(fn)
    table.insert(Library._moduleThemeUpdaters, fn)
end

function Library.applyTheme()
    local trans = 1 - Library.uiGuiOpacity
    local function applyList(key, fn)
        local alive = {}
        for _, el in ipairs(Library.themeElements[key]) do
            if typeof(el) == "Instance" and el.Parent then
                fn(el)
                table.insert(alive, el)
            end
        end
        Library.themeElements[key] = alive
    end
    applyList("MainWindow", function(el)
        el.BackgroundColor3 = Library.uiColor_MainWindow
        el.BackgroundTransparency = trans
    end)
    applyList("TopBars", function(el)
        el.BackgroundColor3 = Library.uiColor_TopBar
        el.BackgroundTransparency = trans
    end)
    applyList("SideBars", function(el)
        el.BackgroundColor3 = Library.uiColor_SideBar
        el.BackgroundTransparency = trans
    end)
    applyList("Texts", function(el)
        el.TextColor3 = Library.uiColor_TextColor
    end)
    applyList("Buttons", function(el)
        el.BackgroundColor3 = Library.uiColor_ButtonColor
        el.BackgroundTransparency = trans
    end)
    applyList("CustomButtons", function(el)
        el.BackgroundTransparency = trans
    end)
    applyList("TextBoxes", function(el)
        el.BackgroundColor3 = Library.uiColor_TextBoxColor
        el.BackgroundTransparency = trans
    end)
    applyList("FillBars", function(el)
        el.BackgroundColor3 = Library.uiColor_TextColor
    end)
    for btn, getState in pairs(Library.toggleRegistry) do
        if typeof(btn) == "Instance" and btn.Parent then
            Library.paintToggleBtn(btn, getState() and true or false)
        else
            Library.toggleRegistry[btn] = nil
        end
    end
    Library.updateTabButtonsTheme()
end

--// ==================== ФАЙЛЫ ====================
function Library.fileExists(path)
    if typeof(isfile) ~= "function" then return true end
    local ok, exists = pcall(isfile, path)
    return ok and exists == true
end

function Library.customAsset(path)
    if typeof(path) ~= "string" or path == "" then return nil end
    if typeof(isfile) == "function" and not Library.fileExists(path) then return nil end
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

Library.BG_FOLDER = "EmilyUi/FuckYou/Background"
function Library.getBackgroundFiles()
    local out = {}
    if listfiles then
        local ok, files = pcall(function() return listfiles(Library.BG_FOLDER) end)
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

Library.FIT_MAP = {
    Fill = Enum.ScaleType.Crop, Fit = Enum.ScaleType.Fit,
    Stretch = Enum.ScaleType.Stretch, Tile = Enum.ScaleType.Tile,
    Center = Enum.ScaleType.Crop, Zoom = Enum.ScaleType.Crop,
    Slice = Enum.ScaleType.Slice, Crop = Enum.ScaleType.Crop,
}

function Library.getScaleType(name)
    if Library.FIT_MAP[name] then return Library.FIT_MAP[name] end
    local ok, val = pcall(function() return Enum.ScaleType[name] end)
    if ok and val then return val end
    return Enum.ScaleType.Stretch
end

function Library.updateBlur()
    if Library.FuckYou and Library.FuckYou.Parent and Library.FuckYou.Visible and Library.uiBlurSize > 0 then
        Library.blurEffect.Parent = game:GetService("Lighting")
        Library.blurEffect.Size = Library.uiBlurSize
        Library.blurEffect.Enabled = true
    else
        Library.blurEffect.Enabled = false
        Library.blurEffect.Parent = nil
    end
end

function Library.applyBackground()
    local asset = nil
    if typeof(Library.uiBackgroundFile) ~= "string" then
        Library.uiBackgroundFile = ""
    end
    if Library.uiBackgroundFile ~= "" and not Library.uiCollapsed then
        local path = Library.BG_FOLDER .. "/" .. Library.uiBackgroundFile
        if typeof(isfile) == "function" then
            local ok, exists = pcall(isfile, path)
            if ok and not exists then
                Library.uiBackgroundFile = ""
            else
                asset = Library.customAsset(path)
            end
        else
            asset = Library.customAsset(path)
        end
    end
    if asset and not Library.uiCollapsed then
        Library.BackgroundImage.Image = asset
        Library.BackgroundImage.ScaleType = Library.getScaleType(Library.uiFitMode)
        Library.BackgroundImage.ImageTransparency = 1 - Library.uiImageOpacity
        Library.BackgroundImage.Visible = true
    else
        Library.BackgroundImage.Visible = false
        Library.BackgroundImage.Image = ""
    end
end

--// ==================== КОНФИГИ ====================
Library.configPath = "EmilyUi/Config.json"

function Library.saveConfig()
    local config = {
        ToggleKey = Library.currentToggleKey.Name,
        MainWindowColor = {Library.uiColor_MainWindow.R, Library.uiColor_MainWindow.G, Library.uiColor_MainWindow.B},
        TopBarColor = {Library.uiColor_TopBar.R, Library.uiColor_TopBar.G, Library.uiColor_TopBar.B},
        SideBarColor = {Library.uiColor_SideBar.R, Library.uiColor_SideBar.G, Library.uiColor_SideBar.B},
        TextColor = {Library.uiColor_TextColor.R, Library.uiColor_TextColor.G, Library.uiColor_TextColor.B},
        ButtonColor = {Library.uiColor_ButtonColor.R, Library.uiColor_ButtonColor.G, Library.uiColor_ButtonColor.B},
        TextBoxColor = {Library.uiColor_TextBoxColor.R, Library.uiColor_TextBoxColor.G, Library.uiColor_TextBoxColor.B},
        ToggleOnColor = {Library.uiColor_ToggleOnText.R, Library.uiColor_ToggleOnText.G, Library.uiColor_ToggleOnText.B},
        ToggleOffColor = {Library.uiColor_ToggleOffText.R, Library.uiColor_ToggleOffText.G, Library.uiColor_ToggleOffText.B},
        GuiOpacity = Library.uiGuiOpacity,
        ImageOpacity = Library.uiImageOpacity,
        Blur = Library.uiBlurSize,
        Fit = Library.uiFitMode,
        BackgroundFile = Library.uiBackgroundFile,
    }
    if Library.VisualsAPI and Library.VisualsAPI.Gather then config.Visuals = Library.VisualsAPI.Gather() end
    if Library.AimAPI and Library.AimAPI.Gather then config.Aim = Library.AimAPI.Gather() end
    if Library.MovementAPI and Library.MovementAPI.Gather then config.Movement = Library.MovementAPI.Gather() end
    if Library.KeyListAPI and Library.KeyListAPI.Gather then config.KeyList = Library.KeyListAPI.Gather() end
    local success, json = pcall(function() return HttpService:JSONEncode(config) end)
    if success then
        if makefolder then pcall(function() makefolder("EmilyUi") end) end
        if writefile then pcall(function() writefile(Library.configPath, json) end) end
    end
end

function Library.loadConfig()
    if isfile and isfile(Library.configPath) and readfile then
        local success, json = pcall(function() return readfile(Library.configPath) end)
        if success and json then
            local ok, config = pcall(function() return HttpService:JSONDecode(json) end)
            if ok and config then
                if config.ToggleKey then
                    pcall(function() Library.currentToggleKey = Enum.KeyCode[config.ToggleKey] end)
                end
                if config.MainWindowColor then Library.uiColor_MainWindow = Color3.new(unpack(config.MainWindowColor)) end
                if config.TopBarColor then Library.uiColor_TopBar = Color3.new(unpack(config.TopBarColor)) end
                if config.SideBarColor then Library.uiColor_SideBar = Color3.new(unpack(config.SideBarColor)) end
                if config.TextColor then Library.uiColor_TextColor = Color3.new(unpack(config.TextColor)) end
                if config.ButtonColor then Library.uiColor_ButtonColor = Color3.new(unpack(config.ButtonColor)) end
                if config.TextBoxColor then Library.uiColor_TextBoxColor = Color3.new(unpack(config.TextBoxColor)) end
                if config.GuiOpacity then Library.uiGuiOpacity = math.clamp(config.GuiOpacity, 0.25, 1) end
                if config.ImageOpacity then Library.uiImageOpacity = math.clamp(config.ImageOpacity, 0, 1) end
                if config.Blur then Library.uiBlurSize = math.clamp(config.Blur, 0, 24) end
                if config.Fit then Library.uiFitMode = config.Fit end
                if config.BackgroundFile ~= nil then Library.uiBackgroundFile = config.BackgroundFile end
                if Library.unlocked then
                    if config.Visuals and Library.VisualsAPI and Library.VisualsAPI.Apply then
                        Library.VisualsAPI.Apply(config.Visuals)
                    end
                    if config.Aim and Library.AimAPI and Library.AimAPI.Apply then
                        Library.AimAPI.Apply(config.Aim)
                    end
                    if config.Movement and Library.MovementAPI and Library.MovementAPI.Apply then
                        Library.MovementAPI.Apply(config.Movement)
                    end
                end
            end
        end
    end
end

function Library.registerConfigSaveListener(fn)
    if typeof(fn) == "function" then
        table.insert(Library.configSaveListeners, fn)
    end
end

function Library.runConfigSaveListeners()
    for _, fn in ipairs(Library.configSaveListeners) do pcall(fn) end
end

Library.lastAutoConfigSave = 0
function Library.autoSaveConfig(force)
    if not Library.unlocked then return end
    if not force and os.clock() - Library.lastAutoConfigSave < 0.5 then return end
    Library.lastAutoConfigSave = os.clock()
    pcall(Library.saveConfig)
    Library.runConfigSaveListeners()
end

--// ==================== KEY SYSTEM ====================
Library.SECRET_KEY = "XenoMeowEmilyUi11037"
Library.b64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

function Library.base64_decode(data)
    data = string.gsub(data, '[^'..Library.b64..'=]', '')
    return (data:gsub('.', function(x)
        if x == '=' then return '' end
        local r, f = '', (Library.b64:find(x) - 1)
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

function Library.xor_decrypt(str, key)
    local result = {}
    local keyLen = #key
    for i = 1, #str do
        result[i] = string.char(bit32.bxor(
            string.byte(str, i),
            string.byte(key, ((i - 1) % keyLen) + 1)
        ))
    end
    return table.concat(result)
end

function Library.decryptData(encryptedBase64, key)
    encryptedBase64 = string.gsub(encryptedBase64, "%s+", "")
    return Library.xor_decrypt(Library.base64_decode(encryptedBase64), key)
end

function Library.getKeyDaysLeft(timeStr)
    if not timeStr or timeStr == "inf" then return "Infinity" end
    local day, month, year = timeStr:match("(%d+)%.(%d+)%.(%d+)")
    if not day or not month or not year then return 0 end
    local expireTime = os.time({
        day = tonumber(day), month = tonumber(month),
        year = tonumber(year), hour = 0, min = 0, sec = 0
    })
    local diff = expireTime - os.time()
    if diff <= 0 then return 0 else return diff / 86400 end
end

function Library.playUnlockJingle()
    pcall(function()
        local SoundService = game:GetService("SoundService")
        local s = Instance.new("Sound")
        s.Name = "FuckYouUnlockSound"
        s.SoundId = "rbxassetid://115440201770223"
        s.Volume = 1
        s.Looped = false
        s.TimePosition = 0
        s.Parent = SoundService
        task.delay(10, function() pcall(function() s:Destroy() end) end)
        s:Play()
    end)
end

Library.cachedKeyResponse = nil
Library.currentKeyData = { group = "Free", daysLeft = "Infinity" }

function Library.isGroupAllowed(groupName)
    local g = string.lower(tostring(groupName or ""))
    if Library.beta then
        return g == "tester" or g == "coder"
    else
        return g == "free" or g == "user" or g == "tester" or g == "coder"
    end
end

function Library.unlockScript(userGroup, daysLeft)
    Library.unlocked = true
    Library.playUnlockJingle()
    if Library.KeyWindow then Library.KeyWindow:Destroy() end
    Library.FuckYou.Visible = true
    Library.currentKeyData.group = userGroup
    Library.currentKeyData.daysLeft = daysLeft
    Library.loadConfig()
    Library.applyBackground()
    Library.updateBlur()
    Library.applyTheme()
    Library.notify("Fuck you! is loaded", "Welcome! Role: " .. (userGroup or "User"))
    -- Сигнал модулям что скрипт разблокирован
    if Library._onUnlockCallbacks then
        for _, fn in ipairs(Library._onUnlockCallbacks) do pcall(fn) end
    end
end

Library._onUnlockCallbacks = {}
function Library.onUnlock(fn)
    table.insert(Library._onUnlockCallbacks, fn)
end

function Library.checkKeySystem(KeyTextBox, KeyInfoLabel)
    if not Library.cachedKeyResponse then
        local success, response = pcall(function()
            return game:HttpGet("https://raw.githubusercontent.com/MamaSdoxla/EmilyUi/refs/heads/main/nuh-uh.json")
        end)
        if not success or not response or #response < 10 then
            if KeyInfoLabel then
                KeyInfoLabel.Text = "Error: Failed to fetch key database!"
                KeyInfoLabel.TextColor3 = Color3.fromRGB(220, 50, 50)
            end
            return
        end
        local ok, decryptedText = pcall(function()
            return Library.decryptData(response, Library.SECRET_KEY)
        end)
        if not ok or not decryptedText or #decryptedText < 5 then
            if KeyInfoLabel then
                KeyInfoLabel.Text = "Error: Failed to decrypt!"
                KeyInfoLabel.TextColor3 = Color3.fromRGB(220, 50, 50)
            end
            return
        end
        Library.cachedKeyResponse = decryptedText
    end
    local jsonSuccess, keysList = pcall(function()
        return HttpService:JSONDecode(Library.cachedKeyResponse)
    end)
    if not jsonSuccess or type(keysList) ~= "table" then
        if KeyInfoLabel then
            KeyInfoLabel.Text = "Error: Database parsing failed!"
            KeyInfoLabel.TextColor3 = Color3.fromRGB(220, 50, 50)
        end
        return
    end
    local myName = string.lower(LocalPlayer.Name)
    local enteredKey = KeyTextBox and KeyTextBox.Text or ""
    for _, data in ipairs(keysList) do
        if data.key and data.robloxName and data.group and data.timeTillWorks then
            local nameMatch = (data.robloxName == "none") or (string.lower(data.robloxName) == myName)
            if nameMatch and Library.isGroupAllowed(data.group) then
                local daysLeft = Library.getKeyDaysLeft(data.timeTillWorks)
                if daysLeft == "Infinity" or (type(daysLeft) == "number" and daysLeft > 0) then
                    if data.key == "none" or (enteredKey == data.key) then
                        Library.unlockScript(data.group, daysLeft)
                        return
                    end
                end
            end
        end
    end
    if KeyInfoLabel then
        if Library.beta then
            KeyInfoLabel.Text = "Beta mode: only Tester/Coder keys are allowed."
        else
            KeyInfoLabel.Text = "Enter key please! You can ask for a key in discord."
        end
        KeyInfoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end

--// ==================== KEY WINDOW ====================
function Library.createKeyWindow()
    Library.KeyWindow = Library.create("Frame", {
        Name = "KeyWindow", Parent = Library.ScreenGui,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 450, 0, 310),
        BackgroundColor3 = Library.uiColor_MainWindow,
        BorderColor3 = Library.COL_BORDER
    })
    table.insert(Library.themeElements.MainWindow, Library.KeyWindow)

    local KeyTopBar = Library.create("Frame", {
        Parent = Library.KeyWindow,
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = Library.uiColor_TopBar, BorderSizePixel = 0
    })
    table.insert(Library.themeElements.TopBars, KeyTopBar)

    local KeyTitle = Library.create("TextLabel", {
        Parent = KeyTopBar,
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = "Fuck you! — Key System",
        TextColor3 = Library.uiColor_TextColor,
        TextSize = 15, Font = Library.FONT,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    table.insert(Library.themeElements.Texts, KeyTitle)

    local KeyCloseBtn = Library.create("TextButton", {
        Parent = KeyTopBar,
        Size = UDim2.new(0, 35, 0, 35),
        Position = UDim2.new(1, -35, 0, 0),
        BackgroundColor3 = Color3.fromRGB(120, 40, 40),
        BorderColor3 = Library.COL_BORDER,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Text = "X", TextSize = 13, Font = Library.FONT
    })
    KeyCloseBtn.MouseButton1Click:Connect(function() Library.ScreenGui:Destroy() end)

    local KeyInfoLabel = Library.create("TextLabel", {
        Parent = Library.KeyWindow,
        Size = UDim2.new(1, -30, 0, 40),
        Position = UDim2.new(0, 15, 0, 50),
        BackgroundTransparency = 1,
        Text = "Please enter your access key below to load the script.\nKey can be obtained via Discord.",
        TextColor3 = Library.uiColor_TextColor,
        TextSize = 13, Font = Library.FONT, TextWrapped = true
    })
    table.insert(Library.themeElements.Texts, KeyInfoLabel)

    local function copyDiscord()
        if setclipboard then setclipboard("https://discord.gg/75Dz8T9hHR") end
        Library.notify("Discord", "The link is copied")
    end

    local KeyDiscordBtn = Library.createContentButton(
        Library.KeyWindow, "Click to copy Discord Server link", copyDiscord
    )
    KeyDiscordBtn.Size = UDim2.new(1, -40, 0, 36)
    KeyDiscordBtn.Position = UDim2.new(0, 20, 0, 105)

    local KeyTextBox = Library.createTextBox(Library.KeyWindow, "Enter key here...", Library.FONT)
    KeyTextBox.Size = UDim2.new(1, -40, 0, 36)
    KeyTextBox.Position = UDim2.new(0, 20, 0, 160)

    Library.makeDraggable(KeyTopBar, Library.KeyWindow)

    local BtnSubmit = Library.createContentButton(
        Library.KeyWindow, "Check Key",
        function() Library.checkKeySystem(KeyTextBox, KeyInfoLabel) end,
        Color3.fromRGB(40, 90, 40)
    )
    BtnSubmit.Size = UDim2.new(0, 150, 0, 36)
    BtnSubmit.Position = UDim2.new(0.5, -75, 0, 240)

    return KeyTextBox, KeyInfoLabel
end

--// ==================== FOV CIRCLE ====================
Library.fovCircle = nil
function Library.getFOVCircle()
    if not Library.fovCircle and Drawing then
        Library.fovCircle = Drawing.new("Circle")
        Library.fovCircle.Visible = false
        Library.fovCircle.Thickness = 2
        Library.fovCircle.Filled = false
    end
    return Library.fovCircle
end

--// ==================== DISCORD COPY ====================
function Library.copyDiscord()
    if setclipboard then setclipboard("https://discord.gg/75Dz8T9hHR") end
    Library.notify("Discord", "The link is copied")
end

--// ==================== ЭКСПОРТ ====================
return Library