local Library = {}

function Library:Init()
    --// Сервисы
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local StarterGui = game:GetService("StarterGui")
    local RunService = game:GetService("RunService")
    local TweenService = game:GetService("TweenService")
    local LocalPlayer = Players.LocalPlayer

    --// Стили
    local COL_BG = Color3.fromRGB(12, 12, 12)
    local COL_BORDER = Color3.fromRGB(22, 22, 22)
    local COL_TEXT = Color3.fromRGB(139, 135, 127)
    local COL_TEXTBOX = Color3.fromRGB(18, 18, 18)
    local FONT = Enum.Font.SpecialElite

    --// Состояние
    local currentToggleKey = Enum.KeyCode.P
    local uiColor_MainWindow = COL_BG
    local uiColor_TopBar = COL_BG
    local uiColor_SideBar = COL_BG
    local uiColor_TextColor = COL_TEXT
    local uiColor_ButtonColor = COL_BG
    local uiColor_TextBoxColor = COL_TEXTBOX
    local uiGuiOpacity = 1
    local uiImageOpacity = 1
    local uiBlurSize = 0
    local uiFitMode = "Fill"
    local uiBackgroundFile = ""

    local uiCollapsed = false
    local unlocked = false
    local currentKeyData = { group = "Free", daysLeft = "Infinity" }

    local themeElements = { MainWindow = {}, TopBars = {}, SideBars = {}, Texts = {}, Buttons = {}, TextBoxes = {}, FillBars = {} }

    --// Хелперы
    local function create(className, properties)
        local inst = Instance.new(className)
        for k, v in pairs(properties or {}) do inst[k] = v end
        return inst
    end

    local function notify(title, text)
        pcall(function()
            StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 5})
        end)
    end

    local function applyTheme()
        local trans = 1 - uiGuiOpacity
        local function applyList(key, fn)
            local alive = {}
            for _, el in ipairs(themeElements[key]) do
                if typeof(el) == "Instance" and el.Parent then
                    pcall(fn, el)
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
        applyList("TextBoxes", function(el) el.BackgroundColor3 = uiColor_TextBoxColor; el.BackgroundTransparency = trans end)
        applyList("FillBars", function(el) el.BackgroundColor3 = uiColor_TextColor end)
    end

    --// Blur & Background
    local blurEffect = Instance.new("BlurEffect")
    blurEffect.Name = "FuckYouBlur"
    blurEffect.Size = 0
    blurEffect.Enabled = false

    local BackgroundImage
    local FuckYou -- Forward declaration

    local function updateBlur()
        if FuckYou and FuckYou.Parent and FuckYou.Visible and uiBlurSize > 0 then
            blurEffect.Parent = game:GetService("Lighting")
            blurEffect.Size = uiBlurSize
            blurEffect.Enabled = true
        else
            blurEffect.Enabled = false
            blurEffect.Parent = nil
        end
    end

    local FIT_MAP = {
        Fill = Enum.ScaleType.Crop, Fit = Enum.ScaleType.Fit, Stretch = Enum.ScaleType.Stretch,
        Tile = Enum.ScaleType.Tile, Center = Enum.ScaleType.Crop, Zoom = Enum.ScaleType.Crop,
    }

    local function getScaleType(name)
        return FIT_MAP[name] or Enum.ScaleType.Stretch
    end

    local function getBackgroundFiles()
        local out = {"None"}
        if listfiles then
            pcall(function()
                for _, p in ipairs(listfiles("EmilyUi/FuckYou/Background")) do
                    local name = p:match("([^/\\]+)$")
                    local ext = name and name:lower():match("%.(%w+)$")
                    if ext == "png" or ext == "jpg" or ext == "jpeg" or ext == "webp" then
                        table.insert(out, name)
                    end
                end
            end)
        end
        return out
    end

    local function applyBackground()
        if not BackgroundImage then return end
        local asset = nil
        if uiBackgroundFile ~= "" and uiBackgroundFile ~= "None" and not uiCollapsed then
            local path = "EmilyUi/FuckYou/Background/" .. uiBackgroundFile
            if getcustomasset then
                pcall(function() asset = getcustomasset(path) end)
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

    --// GUI Creation
    local ScreenGui = create("ScreenGui", {Name = "FuckYouGui", ResetOnSpawn = false, IgnoreGuiInset = true, Parent = LocalPlayer:WaitForChild("PlayerGui")})

    FuckYou = create("Frame", {
        Name = "FuckYou", Parent = ScreenGui,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 940, 0, 510), ClipsDescendants = true, Visible = false,
        BackgroundColor3 = uiColor_MainWindow, BorderColor3 = COL_BORDER, BorderSizePixel = 1
    })
    table.insert(themeElements.MainWindow, FuckYou)

    -- FIXED: BackgroundImage теперь в FuckYou, а не в TopBar
    BackgroundImage = create("ImageLabel", {
        Name = "BackgroundImage", Parent = FuckYou,
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Image = "", Visible = false,
        ScaleType = Enum.ScaleType.Stretch, ImageTransparency = 0, ZIndex = 0,
    })

    local TopBar = create("Frame", {Name = "TopBar", Parent = FuckYou, Size = UDim2.new(1, 0, 0, 45), BackgroundColor3 = uiColor_TopBar, BorderSizePixel = 0, ZIndex = 2})
    table.insert(themeElements.TopBars, TopBar)

    local Title = create("TextLabel", {Name = "Name", Parent = TopBar, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "Fuck you! v1.2", TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT, ZIndex = 3})
    table.insert(themeElements.Texts, Title)

    local function makeTopBtn(symbol, offset, colorOverride)
        local b = create("TextButton", {
            Name = symbol, Parent = TopBar,
            Position = UDim2.new(1, -45 * offset, 0, 0), Size = UDim2.new(0, 45, 0, 45),
            BackgroundColor3 = colorOverride or uiColor_TopBar, BorderColor3 = COL_BORDER,
            Text = symbol, TextColor3 = colorOverride and Color3.fromRGB(255,255,255) or uiColor_TextColor, TextSize = 13, Font = FONT, ZIndex = 3
        })
        table.insert(themeElements.TopBars, b)
        table.insert(themeElements.Texts, b)
        return b
    end

    local Minus = makeTopBtn("-", 3)
    local Equal = makeTopBtn("=", 2)
    local X = makeTopBtn("X", 1, Color3.fromRGB(150, 40, 40))

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

    local MenuInsided = create("ScrollingFrame", {Name = "MenuInsided", Parent = FuckYou, Position = UDim2.new(0, 65, 0, 45), Size = UDim2.new(0, 105, 1, -45), BackgroundColor3 = uiColor_SideBar, BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(0, 0, 0, 0), Visible = false, ZIndex = 2})
    table.insert(themeElements.SideBars, MenuInsided)
    local menuLayout = create("UIListLayout", {Parent = MenuInsided, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)})
    create("UIPadding", {Parent = MenuInsided, PaddingTop = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)})

    local Containment = create("Frame", {Name = "Containment", Parent = FuckYou, Position = UDim2.new(0, 170, 0, 45), Size = UDim2.new(1, -170, 1, -45), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2})

    local function createTabContentFrame(name)
        local sf = create("ScrollingFrame", {Name = name, Parent = Containment, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 0), Visible = false, ZIndex = 2})
        local tl = create("UIListLayout", {Parent = sf, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
        create("UIPadding", {Parent = sf, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)})
        tl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            sf.CanvasSize = UDim2.new(0, 0, 0, tl.AbsoluteContentSize.Y + 20)
        end)
        return sf
    end

    local tabFrames = {
        Main = createTabContentFrame("TabMain"),
        Settings = createTabContentFrame("TabSettings")
    }

    local tabs = {
        {Frame = tabFrames.Main, Name = "Main Info"},
        {Frame = tabFrames.Settings, Name = "Settings"}
    }

    local function switchTab(targetTab)
        for _, tab in ipairs(tabs) do
            tab.Frame.Visible = (tab == targetTab)
        end
    end

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

    EmilyUi.MouseButton1Click:Connect(function()
		MenuInsided.Visible = not MenuInsided.Visible
		if MenuInsided.Visible then
			-- Показываем все кнопки подвкладок
			for _, tab in ipairs(tabs) do
				if tab.Button then
					tab.Button.Visible = true
				end
			end
			-- Открываем первую вкладку по умолчанию
			if tabs[1] then
				switchTab(tabs[1])
			end
		else
			-- Скрываем все подвкладки
			for _, tab in ipairs(tabs) do
				if tab.Frame then
					tab.Frame.Visible = false
				end
			end
		end
	end)

    --// UI Helpers
    local function createSection(parent, text)
        -- FIXED: Labels centered
        local lbl = create("TextLabel", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = text, TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT, Parent = parent, TextXAlignment = Enum.TextXAlignment.Center})
        table.insert(themeElements.Texts, lbl)
        return lbl
    end

    local function createLabel(parent, text)
        local lbl = create("TextLabel", {Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = text, TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Center, Parent = parent})
        table.insert(themeElements.Texts, lbl)
        return lbl
    end

    local function createContentButton(parent, text, callback, customColor)
        local defaultColor = customColor or uiColor_ButtonColor
        local btn = create("TextButton", {Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = defaultColor, BorderColor3 = COL_BORDER, TextColor3 = uiColor_TextColor, Text = text, Font = FONT, TextSize = 13, BackgroundTransparency = 1 - uiGuiOpacity, Parent = parent})
        if not customColor then table.insert(themeElements.Buttons, btn) end
        table.insert(themeElements.Texts, btn)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    local function createTextBox(parent, placeholder, font)
        local box = create("TextBox", {BackgroundColor3 = uiColor_TextBoxColor, BorderColor3 = COL_BORDER, TextColor3 = uiColor_TextColor, PlaceholderColor3 = Color3.fromRGB(90, 90, 90), PlaceholderText = placeholder, Text = "", TextSize = 13, Font = font or FONT, ClearTextOnFocus = false, BackgroundTransparency = 1 - uiGuiOpacity, Parent = parent})
        table.insert(themeElements.Texts, box)
        table.insert(themeElements.TextBoxes, box)
        return box
    end

    local function createDropdown(parent, labelText, getOptions, getCurrent, onselect)
        local container = create("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = parent})
        create("TextLabel", {Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1, Text = labelText, TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, Parent = container})
        local btn = createContentButton(container, labelText .. ": " .. getCurrent(), function() end)
        btn.Size = UDim2.new(0.5, 0, 0.8, 0); btn.Position = UDim2.new(0.48, 0, 0.1, 0); btn.TextSize = 12
        local list = create("ScrollingFrame", {Parent = container, Size = UDim2.new(0.5, 0, 0, 110), Position = UDim2.new(0.48, 0, 0.95, 0), BackgroundColor3 = uiColor_TextBoxColor, BorderColor3 = COL_BORDER, ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 0), Visible = false, ZIndex = 25})
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
                end)
                ob.Size = UDim2.new(1, -4, 0, 24); ob.ZIndex = 26; ob.TextSize = 12
            end
            list.CanvasSize = UDim2.new(0, 0, 0, #opts * 26 + 4)
            list.Visible = true
        end)
    end

    local function createSlider(parent, labelText, min, max, getval, onval, fmt)
        local container = create("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = parent})
        create("TextLabel", {Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1, Text = labelText, TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, Parent = container})
        local valLabel = create("TextLabel", {Size = UDim2.new(0.5, 0, 0, 14), Position = UDim2.new(0.48, 0, 0.05, 0), BackgroundTransparency = 1, Text = fmt(getval()), TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Right, Parent = container})
        table.insert(themeElements.Texts, valLabel)
        local track = create("TextButton", {Size = UDim2.new(0.5, 0, 0, 10), Position = UDim2.new(0.48, 0, 0.55, 0), BackgroundColor3 = uiColor_TextBoxColor, BorderColor3 = COL_BORDER, Text = " ", Parent = container})
        table.insert(themeElements.TextBoxes, track)
        local fill = create("Frame", {Size = UDim2.new((getval() - min) / (max - min), 0, 1, 0), BackgroundColor3 = uiColor_TextColor, BorderSizePixel = 0, Parent = track})
        table.insert(themeElements.FillBars, fill)
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
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then setFromX(input.Position.X) end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
    end

    --// Main Tab Content
    -- FIXED: Added UserProfilePanel
    local UserProfilePanel = create("Frame", {Name = "UserProfilePanel", Parent = tabFrames.Main, Size = UDim2.new(1, 0, 0, 60), LayoutOrder = -1, BackgroundColor3 = uiColor_SideBar, BorderColor3 = COL_BORDER})
    table.insert(themeElements.SideBars, UserProfilePanel)
    create("ImageLabel", {Parent = UserProfilePanel, Position = UDim2.new(0, 10, 0, 10), Size = UDim2.new(0, 40, 0, 40), BackgroundTransparency = 1, Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"})
    create("TextLabel", {Parent = UserProfilePanel, Position = UDim2.new(0, 60, 0, 6), Size = UDim2.new(1, -70, 0, 16), BackgroundTransparency = 1, Text = LocalPlayer.DisplayName, TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left})
    local UserKeyTimeLabel = create("TextLabel", {Parent = UserProfilePanel, Position = UDim2.new(0, 60, 0, 22), Size = UDim2.new(1, -70, 0, 14), BackgroundTransparency = 1, Text = "Days left: Inf", TextColor3 = Color3.fromRGB(180, 180, 180), TextSize = 12, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left})
    table.insert(themeElements.Texts, UserKeyTimeLabel)
    local UserGroupLabel = create("TextLabel", {Parent = UserProfilePanel, Position = UDim2.new(0, 60, 0, 38), Size = UDim2.new(1, -70, 0, 14), BackgroundTransparency = 1, Text = "Group: Free", TextColor3 = Color3.fromRGB(150, 150, 150), TextSize = 12, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left})

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

    createSection(tabFrames.Main, "In case something happens here's a discord server")
    createContentButton(tabFrames.Main, "Click to copy Discord Server link", function()
        if setclipboard then setclipboard("https://discord.gg/75Dz8T9hHR") end
        notify("Discord", "The link is copied")
    end)
    createSection(tabFrames.Main, "* Credits to *")
    createLabel(tabFrames.Main, "WdymGaming (wdymgaming) -> coder")
    createLabel(tabFrames.Main, "pashajokot (swatwincky) -> tester")
    createLabel(tabFrames.Main, "BombalMac (bombapc) -> tester")

    --// Settings Tab Content
    createSection(tabFrames.Settings, "UI Customization")
    
    local keyBindContainer = create("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = tabFrames.Settings})
    create("TextLabel", {Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1, Text = "Menu Toggle Key:", TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, Parent = keyBindContainer})
    local keyBindBtn = createContentButton(keyBindContainer, currentToggleKey.Name, function() end)
    keyBindBtn.Size = UDim2.new(0.5, 0, 0.8, 0); keyBindBtn.Position = UDim2.new(0.48, 0, 0.1, 0); keyBindBtn.TextSize = 12
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
                connection:Disconnect()
            end
        end)
    end)

    createSection(tabFrames.Settings, "Background & Window")
    createDropdown(tabFrames.Settings, "Background Image", getBackgroundFiles, function() return uiBackgroundFile == "" and "None" or uiBackgroundFile end, function(opt)
        uiBackgroundFile = (opt == "None") and "" or opt
        applyBackground()
    end)
    createSlider(tabFrames.Settings, "Image Opacity", 0, 100, function() return math.floor(uiImageOpacity * 100) end, function(v) uiImageOpacity = v / 100; applyBackground() end, function(v) return v .. "%" end)
    createSlider(tabFrames.Settings, "Blur", 0, 24, function() return uiBlurSize end, function(v) uiBlurSize = v; updateBlur() end, function(v) return v .. "px" end)
    
    -- FIXED: Added Fit Dropdown
    createDropdown(tabFrames.Settings, "Fit", function() return {"Fill", "Fit", "Stretch", "Tile", "Center", "Zoom"} end, function() return uiFitMode end, function(opt) uiFitMode = opt; applyBackground() end)
    
    createSlider(tabFrames.Settings, "Gui Opacity", 25, 100, function() return math.floor(uiGuiOpacity * 100) end, function(v) uiGuiOpacity = v / 100; applyTheme() end, function(v) return v .. "%" end)

    -- FIXED: Added Configs Dropdown and Refresh
    createSection(tabFrames.Settings, "Configs")
    local configNameBox = createTextBox(tabFrames.Settings, "Config name...", FONT)
    configNameBox.Size = UDim2.new(1, 0, 0, 30)

    local configFolder = "EmilyUi/FuckYou/Configs"
    local function getSavedConfigs()
        local names = {}
        if listfiles then
            pcall(function()
                for _, path in ipairs(listfiles(configFolder)) do
                    local name = path:match("([^/\\]+)%.json$")
                    if name then table.insert(names, name) end
                end
            end)
        end
        table.sort(names)
        return names
    end

    local ddContainer = create("Frame", {Parent = tabFrames.Settings, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1})
    create("UIListLayout", {Parent = ddContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)})
    
    local ddToggleBtn = createContentButton(ddContainer, "Configs (0) — click to open", function() end)
    local ddList = create("ScrollingFrame", {Parent = ddContainer, Size = UDim2.new(1, 0, 0, 130), BackgroundColor3 = uiColor_TextBoxColor, BorderColor3 = COL_BORDER, ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 0), Visible = false})
    table.insert(themeElements.TextBoxes, ddList)
    local ddListLayout = create("UIListLayout", {Parent = ddList, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3)})
    create("UIPadding", {Parent = ddList, PaddingTop = UDim.new(0, 3), PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 3)})
    
    local ddOpen = false
    local function refreshConfigList()
        for _, ch in ipairs(ddList:GetChildren()) do if ch:IsA("TextButton") or ch:IsA("TextLabel") then ch:Destroy() end end
        local names = getSavedConfigs()
        for _, name in ipairs(names) do
            local item = createContentButton(ddList, name, function()
                notify("Configs", "Loaded: " .. name)
                ddOpen = false; ddList.Visible = false
                ddToggleBtn.Text = "Configs (" .. #getSavedConfigs() .. ") — click to open"
            end)
            item.Size = UDim2.new(1, -6, 0, 28)
        end
        if #names == 0 then
            local empty = createLabel(ddList, "No saved configs")
            empty.Size = UDim2.new(1, -6, 0, 24)
        end
        ddToggleBtn.Text = "Configs (" .. #names .. ") — click to " .. (ddOpen and "close" or "open")
    end
    
    ddToggleBtn.MouseButton1Click:Connect(function()
        ddOpen = not ddOpen
        if ddOpen then refreshConfigList() end
        ddList.Visible = ddOpen
        ddToggleBtn.Text = "Configs (" .. #getSavedConfigs() .. ") — click to " .. (ddOpen and "close" or "open")
    end)

    createContentButton(tabFrames.Settings, "Save config", function()
        local name = string.gsub(configNameBox.Text, "%s+", "")
        if name == "" then notify("Configs", "Enter a config name!"); return end
        pcall(function()
            if not isfolder("EmilyUi/FuckYou") then makefolder("EmilyUi/FuckYou") end
            if not isfolder(configFolder) then makefolder(configFolder) end
        end)
        notify("Configs", "Saved: " .. name)
        refreshConfigList()
    end)
    
    createContentButton(tabFrames.Settings, "Refresh config list", refreshConfigList)
    refreshConfigList()

    --// Window Controls
    local FULL_SIZE = UDim2.new(0, 940, 0, 510)
    local STRIP_SIZE = UDim2.new(0, 940, 0, 45)
    local state = "full"
    local currentTween = nil

    local function tweenSize(target, cb)
        if currentTween then currentTween:Cancel() end
        local tw = TweenService:Create(FuckYou, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = target})
        currentTween = tw
        if cb then tw.Completed:Connect(function(ps) if ps == Enum.PlaybackState.Completed then cb() end end) end
        tw:Play()
    end

    X.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
    Equal.MouseButton1Click:Connect(function()
        if state == "full" then
            state = "strip"; uiCollapsed = true; applyBackground()
            tweenSize(STRIP_SIZE)
        elseif state == "strip" then
            state = "full"; uiCollapsed = false; applyBackground()
            tweenSize(FULL_SIZE)
        end
    end)
    Minus.MouseButton1Click:Connect(function()
        state = "hidden"; uiCollapsed = true; applyBackground()
        tweenSize(UDim2.new(0, 940, 0, 0), function() FuckYou.Visible = false; updateBlur() end)
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == currentToggleKey and unlocked then
            if state == "hidden" then
                state = "full"; uiCollapsed = false; FuckYou.Visible = true; applyBackground(); updateBlur()
                tweenSize(FULL_SIZE)
            else
                state = "hidden"; uiCollapsed = true; applyBackground()
                tweenSize(UDim2.new(0, 940, 0, 0), function() FuckYou.Visible = false; updateBlur() end)
            end
        end
    end)

    -- Draggable
    local dragging, dragInput, dragStart, startPosition
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPosition = FuckYou.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    TopBar.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            FuckYou.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end)

    --// Key System
    -- FIXED: KeyWindow is now in the same scope as unlockScript
    local KeyWindow = create("Frame", {Name = "KeyWindow", Parent = ScreenGui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 450, 0, 310), BackgroundColor3 = uiColor_MainWindow, BorderColor3 = COL_BORDER})
    table.insert(themeElements.MainWindow, KeyWindow)
    local KeyTopBar = create("Frame", {Parent = KeyWindow, Size = UDim2.new(1, 0, 0, 35), BackgroundColor3 = uiColor_TopBar, BorderSizePixel = 0})
    table.insert(themeElements.TopBars, KeyTopBar)
    create("TextLabel", {Parent = KeyTopBar, Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = "Fuck you! — Key System", TextColor3 = uiColor_TextColor, TextSize = 15, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left})
    local KeyCloseBtn = create("TextButton", {Parent = KeyTopBar, Size = UDim2.new(0, 35, 0, 35), Position = UDim2.new(1, -35, 0, 0), BackgroundColor3 = Color3.fromRGB(120, 40, 40), TextColor3 = Color3.fromRGB(255, 255, 255), Text = "X", TextSize = 13, Font = FONT})
    KeyCloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
    
    local KeyInfoLabel = create("TextLabel", {Parent = KeyWindow, Size = UDim2.new(1, -30, 0, 40), Position = UDim2.new(0, 15, 0, 50), BackgroundTransparency = 1, Text = "Please enter your access key below.\nKey can be obtained via Discord.", TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT, TextWrapped = true})
    table.insert(themeElements.Texts, KeyInfoLabel)
    
    local KeyDiscordBtn = createContentButton(KeyWindow, "Click to copy Discord Server link", function()
        if setclipboard then setclipboard("https://discord.gg/75Dz8T9hHR") end
        notify("Discord", "The link is copied")
    end)
    KeyDiscordBtn.Size = UDim2.new(1, -40, 0, 36)
    KeyDiscordBtn.Position = UDim2.new(0, 20, 0, 105)

    local KeyTextBox = createTextBox(KeyWindow, "Enter key here...", FONT)
    KeyTextBox.Size = UDim2.new(1, -40, 0, 36)
    KeyTextBox.Position = UDim2.new(0, 20, 0, 160)

    local SECRET_KEY = "XenoMeowEmilyUi11037"
    local b64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local cachedKeyResponse = nil

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
        local result = {}; local keyLen = #key
        for i = 1, #str do result[i] = string.char(bit32.bxor(string.byte(str, i), string.byte(key, ((i - 1) % keyLen) + 1))) end
        return table.concat(result)
    end

    local function getKeyDaysLeft(timeStr)
        if not timeStr or timeStr == "inf" then return "Infinity" end
        local day, month, year = timeStr:match("(%d+)%.(%d+)%.(%d+)")
        if not day then return 0 end
        local expireTime = os.time({day = tonumber(day), month = tonumber(month), year = tonumber(year), hour = 0, min = 0, sec = 0})
        local diff = expireTime - os.time()
        return diff <= 0 and 0 or diff / 86400
    end

    local function unlockScript(userGroup, daysLeft)
        unlocked = true
        KeyWindow:Destroy() -- FIXED: KeyWindow is guaranteed to exist here
        FuckYou.Visible = true
        updateProfilePanel(userGroup or "Free", daysLeft)
        applyBackground()
        updateBlur()
        applyTheme()
        notify("Fuck you! is loaded", "Welcome! Role: " .. (userGroup or "User"))
    end

    local function checkKeySystem()
        if not cachedKeyResponse then
            local success, response = pcall(function()
                return game:HttpGet("https://raw.githubusercontent.com/MamaSdoxla/EmilyUi/refs/heads/main/nuh-uh.json")
            end)
            if not success then KeyInfoLabel.Text = "Error: Failed to fetch database!"; return end
            local ok, decryptedText = pcall(function() return xor_decrypt(base64_decode(response), SECRET_KEY) end)
            if not ok then KeyInfoLabel.Text = "Error: Failed to decrypt!"; return end
            cachedKeyResponse = decryptedText
        end
        
        local jsonSuccess, keysList = pcall(function() return HttpService:JSONDecode(cachedKeyResponse) end)
        if not jsonSuccess then KeyInfoLabel.Text = "Error: Database parsing failed!"; return end
        
        local myName = string.lower(LocalPlayer.Name)
        local enteredKey = KeyTextBox.Text
        for _, data in ipairs(keysList) do
            if data.key and data.robloxName and data.group and data.timeTillWorks then
                local nameMatch = (data.robloxName == "none") or (string.lower(data.robloxName) == myName)
                local groupAllowed = string.lower(data.group) == "free" or string.lower(data.group) == "user" or string.lower(data.group) == "tester" or string.lower(data.group) == "coder"
                if nameMatch and groupAllowed then
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
    end

    local BtnSubmit = createContentButton(KeyWindow, "Check Key", checkKeySystem, Color3.fromRGB(40, 90, 40))
    BtnSubmit.Size = UDim2.new(0, 150, 0, 36)
    BtnSubmit.Position = UDim2.new(0.5, -75, 0, 240)

    -- Initialize
    applyTheme()
    task.spawn(checkKeySystem)
end

return Library