---@diagnostic disable: undefined-global
local Library = {}

-- Services and constants
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

local DEFAULT = {
    ToggleKey = "P",
    MainWindowColor = {12, 12, 12},
    TopBarColor = {12, 12, 12},
    SideBarColor = {12, 12, 12},
    TextColor = {139, 135, 127},
    ButtonColor = {12, 12, 12},
    TextBoxColor = {18, 18, 18},
    ToggleOnColor = {100, 255, 100},
    ToggleOffColor = {255, 100, 100},
    GuiOpacity = 1,
    ImageOpacity = 1,
    Blur = 0,
    Fit = "Fill",
    BackgroundFile = "",
}

local FONT = Enum.Font.SpecialElite
local BORDER = Color3.fromRGB(22, 22, 22)
local ROOT_FOLDER = "EmilyUi/FuckYou"
local BACKGROUND_FOLDER = ROOT_FOLDER .. "/Background"
local CONFIG_FOLDER = ROOT_FOLDER .. "/Configs"
local SETTINGS_PATH = ROOT_FOLDER .. "/Settings.json"
local SECRET_KEY = "XenoMeowEmilyUi11037"
local DISCORD = "https://discord.gg/75Dz8T9hHR"

local state = {}
local currentToggleKey = Enum.KeyCode.P
local unlocked, cachedKeyResponse = false, nil

local function create(className, properties)
    local instance = Instance.new(className)
    for key, value in pairs(properties or {}) do instance[key] = value end
    return instance
end

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 5})
    end)
end

local function clone(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, item in pairs(value) do copy[key] = clone(item) end
    return copy
end

local function resetState()
    state = clone(DEFAULT)
    currentToggleKey = Enum.KeyCode.P
end

local function color(value)
    return Color3.fromRGB(value[1], value[2], value[3])
end

local function colorArray(value)
    return {
        math.floor(value.R * 255 + 0.5),
        math.floor(value.G * 255 + 0.5),
        math.floor(value.B * 255 + 0.5),
    }
end

local function ensureFolders()
    if not makefolder then return end
    pcall(function()
        if not isfolder("EmilyUi") then makefolder("EmilyUi") end
        if not isfolder(ROOT_FOLDER) then makefolder(ROOT_FOLDER) end
        if not isfolder(BACKGROUND_FOLDER) then makefolder(BACKGROUND_FOLDER) end
        if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
    end)
end

local function applyState(data)
    if type(data) ~= "table" then return end
    for key, default in pairs(DEFAULT) do
        if data[key] ~= nil and type(data[key]) == type(default) then state[key] = data[key] end
    end
    state.GuiOpacity = math.clamp(state.GuiOpacity, 0.25, 1)
    state.ImageOpacity = math.clamp(state.ImageOpacity, 0, 1)
    state.Blur = math.clamp(state.Blur, 0, 24)
    pcall(function()
        local keyCode = Enum.KeyCode[state.ToggleKey]
        if keyCode then currentToggleKey = keyCode else state.ToggleKey = currentToggleKey.Name end
    end)
end

local function readConfig(path)
    if not (readfile and isfile and isfile(path)) then return nil end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
    return ok and data or nil
end

local function writeConfig(path)
    if not writefile then return false end
    ensureFolders()
    state.ToggleKey = currentToggleKey.Name
    local ok, json = pcall(function() return HttpService:JSONEncode(state) end)
    if ok then ok = pcall(function() writefile(path, json) end) end
    return ok
end

resetState()
applyState(readConfig(SETTINGS_PATH))

local function getFiles(folder, extension)
    local names = {}
    if not listfiles then return names end
    local ok, files = pcall(function() return listfiles(folder) end)
    if not ok then return names end
    for _, path in ipairs(files) do
        local name = path:match("([^/\\]+)$")
        if name and (not extension or name:lower():match("%." .. extension .. "$") ) then
            table.insert(names, extension and name:gsub("%." .. extension .. "$", "") or name)
        end
    end
    table.sort(names)
    return names
end

local function customAsset(path)
    local getter = getcustomasset or GetCustomAsset
    if not getter then return nil end
    if isfile and not isfile(path) then return nil end
    local ok, asset = pcall(getter, path)
    return ok and asset or nil
end

local b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function base64Decode(data)
    data = data:gsub("[^" .. b64 .. "=]", "")
    return (data:gsub(".", function(char)
        if char == "=" then return "" end
        local result, value = "", b64:find(char) - 1
        for index = 6, 1, -1 do
            result = result .. (value % 2 ^ index - value % 2 ^ (index - 1) > 0 and "1" or "0")
        end
        return result
    end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(bits)
        if #bits ~= 8 then return "" end
        local value = 0
        for index = 1, 8 do
            if bits:sub(index, index) == "1" then value = value + 2 ^ (8 - index) end
        end
        return string.char(value)
    end))
end

local function xorDecrypt(text, key)
    local output = {}
    for index = 1, #text do
        output[index] = string.char(bit32.bxor(text:byte(index), key:byte((index - 1) % #key + 1)))
    end
    return table.concat(output)
end

local function getKeyDaysLeft(date)
    if not date or date == "inf" then return "Infinity" end
    local day, month, year = date:match("(%d+)%.(%d+)%.(%d+)")
    if not day then return 0 end
    local expires = os.time({day = tonumber(day), month = tonumber(month), year = tonumber(year)})
    return math.max(0, (expires - os.time()) / 86400)
end

local function playUnlockJingle()
    pcall(function()
        local sound = create("Sound", {
            Name = "FuckYouUnlockSound", SoundId = "rbxassetid://115440201770223",
            Volume = 1, Parent = game:GetService("SoundService"),
        })
        sound:Play()
        task.delay(1, function() if sound.Parent then sound:Destroy() end end)
    end)
end

local function createMainGui(screenGui, userGroup, daysLeft)
    local theme = {Main = {}, Top = {}, Side = {}, Text = {}, Button = {}, Box = {}, Fill = {}}
    local function track(kind, instance)
        table.insert(theme[kind], instance)
        return instance
    end

    local window = track("Main", create("Frame", {
        Name = "FuckYou", Parent = screenGui, AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 940, 0, 510),
        ClipsDescendants = true, BackgroundColor3 = color(state.MainWindowColor),
        BorderColor3 = BORDER, BorderSizePixel = 1,
    }))

    local background = create("ImageLabel", {
        Name = "BackgroundImage", Parent = window, Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, Image = "", Visible = false, ZIndex = 0,
    })
    local blur = create("BlurEffect", {Name = "FuckYouBlur", Size = 0, Enabled = false})
    local collapsed, hidden, activeTween = false, false, nil

    local FIT = {
        Fill = Enum.ScaleType.Crop, Fit = Enum.ScaleType.Fit, Stretch = Enum.ScaleType.Stretch,
        Tile = Enum.ScaleType.Tile, Center = Enum.ScaleType.Crop, Zoom = Enum.ScaleType.Crop,
    }

    local function updateBackground()
        local asset = state.BackgroundFile ~= "" and customAsset(BACKGROUND_FOLDER .. "/" .. state.BackgroundFile)
        background.Visible = asset ~= nil and not collapsed
        background.Image = asset or ""
        background.ImageTransparency = 1 - state.ImageOpacity
        background.ScaleType = FIT[state.Fit] or Enum.ScaleType.Crop
    end

    local function updateBlur()
        local enabled = window.Visible and state.Blur > 0
        blur.Size, blur.Enabled, blur.Parent = state.Blur, enabled, enabled and Lighting or nil
    end

    local tabs = {}
    local function applyTheme()
        local transparency = 1 - state.GuiOpacity
        local colors = {
            Main = color(state.MainWindowColor), Top = color(state.TopBarColor),
            Side = color(state.SideBarColor), Text = color(state.TextColor),
            Button = color(state.ButtonColor), Box = color(state.TextBoxColor), Fill = color(state.TextColor),
        }
        for kind, list in pairs(theme) do
            local alive = {}
            for _, item in ipairs(list) do
                if item.Parent then
                    if kind == "Text" then item.TextColor3 = colors[kind]
                    elseif kind == "Fill" then item.BackgroundColor3 = colors[kind]
                    else item.BackgroundColor3, item.BackgroundTransparency = colors[kind], transparency end
                    table.insert(alive, item)
                end
            end
            theme[kind] = alive
        end
        for _, tab in ipairs(tabs) do
            tab.Button.TextColor3 = tab.Frame.Visible and Color3.new(1, 1, 1) or colors.Text
        end
    end

    local function persist()
        writeConfig(SETTINGS_PATH)
        updateBackground()
        updateBlur()
    end

    local topBar = track("Top", create("Frame", {
        Name = "TopBar", Parent = window, Size = UDim2.new(1, 0, 0, 45), BorderSizePixel = 0,
    }))
    track("Text", create("TextLabel", {
        Parent = topBar, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        Text = "Fuck you! v1.2", TextSize = 13, Font = FONT,
    }))

    local function topButton(symbol, offset, customColor)
        local button = create("TextButton", {
            Parent = topBar, Position = UDim2.new(1, -45 * offset, 0, 0), Size = UDim2.new(0, 45, 1, 0),
            BackgroundColor3 = customColor or color(state.TopBarColor), BorderColor3 = BORDER,
            Text = symbol, TextColor3 = customColor and Color3.new(1, 1, 1) or color(state.TextColor),
            TextSize = 13, Font = FONT,
        })
        if not customColor then track("Top", button); track("Text", button) end
        return button
    end

    local minimize = topButton("-", 3)
    local collapse = topButton("=", 2)
    local close = topButton("X", 1, Color3.fromRGB(150, 40, 40))

    local sidebar = track("Side", create("Frame", {
        Parent = window, Position = UDim2.new(0, 0, 0, 45), Size = UDim2.new(0, 65, 1, -45), BorderSizePixel = 0,
    }))
    local uiButton = track("Side", create("TextButton", {
        Parent = sidebar, Size = UDim2.new(1, 0, 0, 59), BorderColor3 = BORDER,
        Text = "Ui", TextSize = 12, Font = FONT,
    }))
    track("Text", uiButton)

    local menu = track("Side", create("ScrollingFrame", {
        Parent = window, Position = UDim2.new(0, 65, 0, 45), Size = UDim2.new(0, 105, 1, -45),
        BorderSizePixel = 0, ScrollBarThickness = 3, Visible = false, CanvasSize = UDim2.new(),
    }))
    local menuLayout = create("UIListLayout", {Parent = menu, Padding = UDim.new(0, 4)})
    create("UIPadding", {Parent = menu, PaddingTop = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)})
    menuLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        menu.CanvasSize = UDim2.new(0, 0, 0, menuLayout.AbsoluteContentSize.Y + 10)
    end)

    local content = create("Frame", {
        Parent = window, Position = UDim2.new(0, 170, 0, 45), Size = UDim2.new(1, -170, 1, -45),
        BackgroundTransparency = 1,
    })

    local function createTab(name)
        local frame = create("ScrollingFrame", {
            Name = name, Parent = content, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
            BorderSizePixel = 0, ScrollBarThickness = 4, Visible = false, CanvasSize = UDim2.new(),
        })
        local layout = create("UIListLayout", {Parent = frame, Padding = UDim.new(0, 6)})
        create("UIPadding", {Parent = frame, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10)})
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            frame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
        end)
        return frame
    end

    local mainTab, settingsTab = createTab("MainInfo"), createTab("Settings")

    local function createSection(parent, text)
        return track("Text", create("TextLabel", {
            Parent = parent, Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1,
            Text = text, TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left,
        }))
    end

    local function createButton(parent, text, callback)
        local button = track("Button", create("TextButton", {
            Parent = parent, Size = UDim2.new(1, 0, 0, 30), BorderColor3 = BORDER,
            Text = text, TextSize = 13, Font = FONT,
        }))
        track("Text", button)
        if callback then button.MouseButton1Click:Connect(callback) end
        return button
    end

    local function createTextBox(parent, placeholder)
        local box = track("Box", create("TextBox", {
            Parent = parent, Size = UDim2.new(1, 0, 0, 30), BorderColor3 = BORDER,
            PlaceholderText = placeholder, PlaceholderColor3 = Color3.fromRGB(90, 90, 90),
            Text = "", TextSize = 12, Font = Enum.Font.Code, ClearTextOnFocus = false,
        }))
        track("Text", box)
        return box
    end

    local function createRow(parent, labelText)
        local row = create("Frame", {Parent = parent, Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1})
        track("Text", create("TextLabel", {
            Parent = row, Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1,
            Text = labelText, TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left,
        }))
        return row
    end

    local function createSettingsInput(parent, labelText, initial, callback)
        local row = createRow(parent, labelText)
        local box = createTextBox(row, initial)
        box.Size, box.Position = UDim2.new(0.5, 0, 0.8, 0), UDim2.new(0.48, 0, 0.1, 0)
        box.FocusLost:Connect(function(enterPressed)
            if enterPressed or box.Text ~= "" then callback(box.Text, box) end
        end)
        return box
    end

    local function createDropdown(parent, labelText, options, current, onSelect)
        local row = createRow(parent, labelText)
        local button = createButton(row, current(), nil)
        button.Size, button.Position = UDim2.new(0.5, 0, 0.8, 0), UDim2.new(0.48, 0, 0.1, 0)
        local list = track("Box", create("ScrollingFrame", {
            Parent = row, Position = UDim2.new(0.48, 0, 1, 0), Size = UDim2.new(0.5, 0, 0, 108),
            BorderColor3 = BORDER, ScrollBarThickness = 3, CanvasSize = UDim2.new(), Visible = false, ZIndex = 20,
        }))
        local layout = create("UIListLayout", {Parent = list, Padding = UDim.new(0, 2)})
        local function closeList() list.Visible, row.Size = false, UDim2.new(1, 0, 0, 36) end
        button.MouseButton1Click:Connect(function()
            if list.Visible then closeList(); return end
            for _, child in ipairs(list:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
            local values = type(options) == "function" and options() or options
            for _, value in ipairs(values) do
                local option = createButton(list, value, function()
                    onSelect(value); button.Text = current(); closeList(); persist()
                end)
                option.Size, option.ZIndex = UDim2.new(1, -3, 0, 24), 21
            end
            list.CanvasSize = UDim2.new(0, 0, 0, #values * 26)
            list.Visible, row.Size = true, UDim2.new(1, 0, 0, 146)
        end)
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
        end)
        return button
    end

    local function createSlider(parent, labelText, minimum, maximum, getValue, onValue, format)
        local row = createRow(parent, labelText)
        local valueLabel = track("Text", create("TextLabel", {
            Parent = row, Position = UDim2.new(0.48, 0, 0, 0), Size = UDim2.new(0.5, 0, 0, 15),
            BackgroundTransparency = 1, Text = format(getValue()), TextSize = 12, Font = FONT,
            TextXAlignment = Enum.TextXAlignment.Right,
        }))
        local trackButton = track("Box", create("TextButton", {
            Parent = row, Position = UDim2.new(0.48, 0, 0, 21), Size = UDim2.new(0.5, 0, 0, 10),
            BorderColor3 = BORDER, Text = "",
        }))
        local fill = track("Fill", create("Frame", {
            Parent = trackButton, Size = UDim2.new((getValue() - minimum) / (maximum - minimum), 0, 1, 0), BorderSizePixel = 0,
        }))
        local dragging = false
        local function setFromX(x)
            local ratio = math.clamp((x - trackButton.AbsolutePosition.X) / trackButton.AbsoluteSize.X, 0, 1)
            local value = math.floor(minimum + (maximum - minimum) * ratio + 0.5)
            onValue(value)
            fill.Size, valueLabel.Text = UDim2.new((value - minimum) / (maximum - minimum), 0, 1, 0), format(value)
            persist()
        end
        trackButton.MouseButton1Down:Connect(function(x) dragging = true; setFromX(x) end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then setFromX(input.Position.X) end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
    end

    -- Main info
    local profile = track("Side", create("Frame", {
        Parent = mainTab, Size = UDim2.new(1, 0, 0, 60), BorderColor3 = BORDER, LayoutOrder = -1,
    }))
    local avatar = create("ImageLabel", {
        Parent = profile, Position = UDim2.new(0, 10, 0, 10), Size = UDim2.new(0, 40, 0, 40),
        BackgroundTransparency = 1, Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150",
    })
    create("UICorner", {Parent = avatar, CornerRadius = UDim.new(1, 0)})
    local profileLines = {
        {LocalPlayer.DisplayName, 6, Color3.new(1, 1, 1)},
        {"Days left: " .. (type(daysLeft) == "number" and string.format("%.1f", daysLeft) or tostring(daysLeft)), 23},
        {"Group: " .. (userGroup or "Free"), 40},
    }
    for _, line in ipairs(profileLines) do
        local label = create("TextLabel", {
            Parent = profile, Position = UDim2.new(0, 60, 0, line[2]), Size = UDim2.new(1, -70, 0, 15),
            BackgroundTransparency = 1, Text = line[1], TextColor3 = line[3] or color(state.TextColor),
            TextSize = 12, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        })
        if not line[3] then track("Text", label) end
    end
    createSection(mainTab, "In case something happens here's a discord server")
    createButton(mainTab, "Click to copy Discord Server link", function()
        if setclipboard then setclipboard(DISCORD) end
        notify("Discord", "The link is copied")
    end)
    createSection(mainTab, "* Credits to *")
    createSection(mainTab, "RobloxId (DiscordUsername) -> role")
    createSection(mainTab, "WdymGaming (wdymgaming) -> coder")
    createSection(mainTab, "pashajokot (swatwincky) -> tester")
    createSection(mainTab, "BombalMac (bombapc) -> tester")

    -- Settings
    createSection(settingsTab, "UI Customization")
    local keyRow = createRow(settingsTab, "Menu Toggle Key:")
    local keyButton = createButton(keyRow, currentToggleKey.Name, nil)
    keyButton.Size, keyButton.Position = UDim2.new(0.5, 0, 0.8, 0), UDim2.new(0.48, 0, 0.1, 0)
    keyButton.MouseButton1Click:Connect(function()
        keyButton.Text = "...Press any Key..."
        local connection
        connection = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                currentToggleKey, keyButton.Text = input.KeyCode, input.KeyCode.Name
                connection:Disconnect(); persist()
            end
        end)
    end)

    local colorFields = {
        {"Main Window Color:", "MainWindowColor"}, {"Top Bar Color:", "TopBarColor"},
        {"Side Bar Color:", "SideBarColor"}, {"Text Color:", "TextColor"},
        {"Button Color:", "ButtonColor"}, {"TextBox Background Color:", "TextBoxColor"},
        {"Toggle ON Color:", "ToggleOnColor"}, {"Toggle OFF Color:", "ToggleOffColor"},
    }
    for _, item in ipairs(colorFields) do
        local values = state[item[2]]
        createSettingsInput(settingsTab, item[1], table.concat(values, ", "), function(text, box)
            local r, g, b = text:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
            r, g, b = tonumber(r), tonumber(g), tonumber(b)
            if not r or r > 255 or g > 255 or b > 255 then box.Text = "Invalid RGB"; return end
            state[item[2]] = {r, g, b}; box.Text = ""; box.PlaceholderText = r .. ", " .. g .. ", " .. b
            applyTheme(); persist()
        end)
    end

    createSection(settingsTab, "Background & Window")
    createDropdown(settingsTab, "Background Image", function()
        local result = {"None"}
        for _, name in ipairs(getFiles(BACKGROUND_FOLDER)) do
            local extension = name:lower():match("%.([%w]+)$")
            if extension == "png" or extension == "jpg" or extension == "jpeg" or extension == "webp" then
                table.insert(result, name)
            end
        end
        return result
    end, function() return state.BackgroundFile == "" and "None" or state.BackgroundFile end,
    function(value) state.BackgroundFile = value == "None" and "" or value; updateBackground() end)

    createSlider(settingsTab, "Image Opacity", 0, 100,
        function() return math.floor(state.ImageOpacity * 100 + 0.5) end,
        function(value) state.ImageOpacity = value / 100; updateBackground() end,
        function(value) return value .. "%" end)
    createSlider(settingsTab, "Blur", 0, 24,
        function() return state.Blur end, function(value) state.Blur = value; updateBlur() end,
        function(value) return value .. "px" end)
    createDropdown(settingsTab, "Fit", {"Fill", "Fit", "Stretch", "Tile", "Center", "Zoom"},
        function() return state.Fit end, function(value) state.Fit = value; updateBackground() end)
    createSlider(settingsTab, "Gui Opacity", 25, 100,
        function() return math.floor(state.GuiOpacity * 100 + 0.5) end,
        function(value) state.GuiOpacity = value / 100; applyTheme() end,
        function(value) return value .. "%" end)

    createSection(settingsTab, "Configs")
    local configName = createTextBox(settingsTab, "Config name...")
    local configPicker
    configPicker = createDropdown(settingsTab, "Saved config", function()
        local result = getFiles(CONFIG_FOLDER, "json")
        if #result == 0 then result = {"No saved configs"} end
        return result
    end, function() return "Click to select" end, function(name)
        if name == "No saved configs" then return end
        local data = readConfig(CONFIG_FOLDER .. "/" .. name .. ".json")
        if data then
            applyState(data); keyButton.Text = currentToggleKey.Name
            applyTheme(); updateBackground(); updateBlur(); writeConfig(SETTINGS_PATH)
            notify("Configs", "Loaded: " .. name)
        end
    end)
    createButton(settingsTab, "Save config", function()
        local name = configName.Text:gsub("[^%w_%-]", "")
        if name == "" then notify("Configs", "Enter a config name"); return end
        if writeConfig(CONFIG_FOLDER .. "/" .. name .. ".json") then
            configName.Text = ""; notify("Configs", "Saved: " .. name)
        else
            notify("Configs", "Executor doesn't support files")
        end
    end)
    createButton(settingsTab, "Refresh config list", function() configPicker.Text = "Click to select" end)
    createButton(settingsTab, "Reset defaults", function()
        resetState(); keyButton.Text = currentToggleKey.Name
        applyTheme(); updateBackground(); updateBlur(); writeConfig(SETTINGS_PATH)
        notify("Configs", "Settings reset to defaults")
    end)

    local function switchTab(target)
        for _, tab in ipairs(tabs) do tab.Frame.Visible = tab.Frame == target end
        applyTheme()
    end
    for index, item in ipairs({{"Main info", mainTab}, {"Settings", settingsTab}}) do
        local tab = {Name = item[1], Frame = item[2]}
        tab.Button = createButton(menu, item[1], function() switchTab(item[2]) end)
        tab.Button.LayoutOrder = index
        table.insert(tabs, tab)
    end

    uiButton.MouseButton1Click:Connect(function()
        menu.Visible = not menu.Visible
        if menu.Visible then switchTab(mainTab) end
    end)

    local function tweenSize(size, callback)
        if activeTween then activeTween:Cancel() end
        activeTween = TweenService:Create(window, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = size})
        if callback then
            local connection
            connection = activeTween.Completed:Connect(function(playbackState)
                connection:Disconnect()
                if playbackState == Enum.PlaybackState.Completed then callback() end
            end)
        end
        activeTween:Play()
    end

    close.MouseButton1Click:Connect(function() screenGui:Destroy() end)
    collapse.MouseButton1Click:Connect(function()
        collapsed = not collapsed
        tweenSize(collapsed and UDim2.new(0, 940, 0, 45) or UDim2.new(0, 940, 0, 510))
        updateBackground()
    end)
    minimize.MouseButton1Click:Connect(function()
        hidden = true
        tweenSize(UDim2.new(0, 940, 0, 0), function() window.Visible = false; updateBlur() end)
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not unlocked or input.KeyCode ~= currentToggleKey then return end
        hidden = not hidden
        if not hidden then
            window.Visible, collapsed = true, false
            tweenSize(UDim2.new(0, 940, 0, 510)); updateBlur()
        else
            tweenSize(UDim2.new(0, 940, 0, 0), function() window.Visible = false; updateBlur() end)
        end
    end)

    local dragging, dragStart, startPosition = false, nil, nil
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging, dragStart, startPosition = true, input.Position, window.Position
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            window.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end)

    screenGui.Destroying:Connect(function()
        blur.Parent = nil
        if unlocked then writeConfig(SETTINGS_PATH) end
    end)
    window:GetPropertyChangedSignal("Visible"):Connect(updateBlur)
    switchTab(mainTab)
    applyTheme(); updateBackground(); updateBlur(); persist()
end

local function createKeyWindow()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local previous = playerGui:FindFirstChild("FuckYouGui")
    if previous then previous:Destroy() end
    local screenGui = create("ScreenGui", {
        Name = "FuckYouGui", ResetOnSpawn = false, IgnoreGuiInset = true, Parent = playerGui,
    })
    local keyWindow = create("Frame", {
        Parent = screenGui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 450, 0, 310), BackgroundColor3 = color(state.MainWindowColor), BorderColor3 = BORDER,
    })
    local top = create("Frame", {Parent = keyWindow, Size = UDim2.new(1, 0, 0, 35), BackgroundColor3 = color(state.TopBarColor), BorderSizePixel = 0})
    create("TextLabel", {
        Parent = top, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -50, 1, 0),
        BackgroundTransparency = 1, Text = "Fuck you! - Key System", TextColor3 = color(state.TextColor),
        TextSize = 15, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left,
    })
    local close = create("TextButton", {
        Parent = top, Position = UDim2.new(1, -35, 0, 0), Size = UDim2.new(0, 35, 1, 0),
        BackgroundColor3 = Color3.fromRGB(120, 40, 40), TextColor3 = Color3.new(1, 1, 1), Text = "X", Font = FONT,
    })
    local info = create("TextLabel", {
        Parent = keyWindow, Position = UDim2.new(0, 15, 0, 50), Size = UDim2.new(1, -30, 0, 40),
        BackgroundTransparency = 1, Text = "Please enter your access key below.\nKey can be obtained via Discord.",
        TextColor3 = color(state.TextColor), TextSize = 13, Font = FONT, TextWrapped = true,
    })
    local discord = create("TextButton", {
        Parent = keyWindow, Position = UDim2.new(0, 20, 0, 105), Size = UDim2.new(1, -40, 0, 36),
        BackgroundColor3 = color(state.ButtonColor), BorderColor3 = BORDER, TextColor3 = color(state.TextColor),
        Text = "Click to copy Discord Server link", TextSize = 13, Font = FONT,
    })
    local keyBox = create("TextBox", {
        Parent = keyWindow, Position = UDim2.new(0, 20, 0, 160), Size = UDim2.new(1, -40, 0, 36),
        BackgroundColor3 = color(state.TextBoxColor), BorderColor3 = BORDER, TextColor3 = color(state.TextColor),
        PlaceholderText = "Enter key here...", PlaceholderColor3 = Color3.fromRGB(90, 90, 90),
        Text = "", TextSize = 13, Font = FONT, ClearTextOnFocus = false,
    })
    local check = create("TextButton", {
        Parent = keyWindow, Position = UDim2.new(0.5, -75, 0, 240), Size = UDim2.new(0, 150, 0, 36),
        BackgroundColor3 = Color3.fromRGB(40, 90, 40), BorderColor3 = BORDER,
        TextColor3 = Color3.new(1, 1, 1), Text = "Check Key", TextSize = 13, Font = FONT,
    })

    close.MouseButton1Click:Connect(function() screenGui:Destroy() end)
    discord.MouseButton1Click:Connect(function()
        if setclipboard then setclipboard(DISCORD) end
        notify("Discord", "The link is copied")
    end)

    local function unlock(group, days)
        unlocked = true
        playUnlockJingle()
        keyWindow:Destroy()
        createMainGui(screenGui, group, days)
        notify("Fuck you! is loaded", "Welcome! Role: " .. (group or "User"))
    end

    local function checkKey()
        if not cachedKeyResponse then
            local ok, response = pcall(function()
                return game:HttpGet("https://raw.githubusercontent.com/MamaSdoxla/EmilyUi/refs/heads/main/nuh-uh.json")
            end)
            if not ok then info.Text = "Error: Failed to fetch database!"; return end
            ok, cachedKeyResponse = pcall(function() return xorDecrypt(base64Decode(response), SECRET_KEY) end)
            if not ok then cachedKeyResponse = nil; info.Text = "Error: Failed to decrypt!"; return end
        end
        local ok, keys = pcall(function() return HttpService:JSONDecode(cachedKeyResponse) end)
        if not ok then info.Text = "Error: Database parsing failed!"; return end
        local playerName = LocalPlayer.Name:lower()
        for _, data in ipairs(keys) do
            local group = tostring(data.group or ""):lower()
            local allowed = group == "free" or group == "user" or group == "tester" or group == "coder"
            local nameMatches = data.robloxName == "none" or tostring(data.robloxName):lower() == playerName
            local days = getKeyDaysLeft(data.timeTillWorks)
            local active = days == "Infinity" or type(days) == "number" and days > 0
            if allowed and nameMatches and active and (data.key == "none" or keyBox.Text == data.key) then
                unlock(data.group, days); return
            end
        end
        info.Text = "Enter key please! You can ask for a key in discord."
    end

    check.MouseButton1Click:Connect(checkKey)
    task.spawn(checkKey)
end

function Library:Init()
    createKeyWindow()
end

return Library
