--// EmilyUiLib.lua
local Library = {}
Library.BASE_URL = "https://raw.githubusercontent.com/MamaSdoxla/EmilyUiRaw/refs/heads/main/Project"

-- ВАЖНО: Инициализируем таблицу напрямую в Library, чтобы все модули могли к ней обратиться
Library.themeElements = { 
    MainWindow = {}, 
    TopBars = {}, 
    SideBars = {}, 
    Texts = {}, 
    Buttons = {}, 
    TextBoxes = {}, 
    FillBars = {}, 
    CustomButtons = {} 
}
local themeElements = Library.themeElements

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local COL_BG = Color3.fromRGB(12, 12, 12)
local COL_BORDER = Color3.fromRGB(22, 22, 22)
local COL_TEXT = Color3.fromRGB(139, 135, 127)
local COL_TEXTBOX = Color3.fromRGB(18, 18, 18)
local FONT = Enum.Font.SpecialElite

local uiColor_MainWindow, uiColor_TopBar, uiColor_SideBar = COL_BG, COL_BG, COL_BG
local uiColor_TextColor, uiColor_ButtonColor, uiColor_TextBoxColor = COL_TEXT, COL_BG, COL_TEXTBOX
local uiColor_ToggleOnText = Color3.fromRGB(100, 255, 100)
local uiColor_ToggleOffText = Color3.fromRGB(255, 100, 100)
local uiGuiOpacity, uiImageOpacity, uiBlurSize = 1, 1, 0
local uiFitMode, uiBackgroundFile = "Fill", ""
local currentToggleKey = Enum.KeyCode.P
local unlocked = false
local beta = false

local toggleRegistry = {}

function Library.create(className, properties)
    local inst = Instance.new(className)
    for k, v in pairs(properties or {}) do inst[k] = v end
    return inst
end

local function scaleColor(c, f) return Color3.fromRGB(math.clamp(c.R*255*f,0,255), math.clamp(c.G*255*f,0,255), math.clamp(c.B*255*f,0,255)) end
local function fileExists(path)
    if typeof(isfile) ~= "function" then return true end
    local ok, exists = pcall(isfile, path)
    return ok and exists == true
end
local function customAsset(path)
    if typeof(path) ~= "string" or path == "" then return nil end
    if typeof(isfile) == "function" and not fileExists(path) then return nil end
    if typeof(getcustomasset) == "function" then local ok, asset = pcall(getcustomasset, path); if ok and typeof(asset) == "string" and asset ~= "" then return asset end end
    if typeof(GetCustomAsset) == "function" then local ok, asset = pcall(GetCustomAsset, path); if ok and typeof(asset) == "string" and asset ~= "" then return asset end end
    return nil
end

function Library.notify(title, text)
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
            local gui = Library.create("ScreenGui", {Name = "FallbackNotification", ResetOnSpawn = false, IgnoreGuiInset = true, Parent = playerGui})
            local main = Library.create("Frame", {AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.new(0, 300, 0, 64), BackgroundColor3 = COL_BG, BorderColor3 = COL_BORDER, BorderSizePixel = 1, Parent = gui})
            Library.create("TextLabel", {Size = UDim2.new(1, -16, 0, 20), Position = UDim2.new(0, 8, 0, 6), BackgroundTransparency = 1, Text = title, Font = FONT, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 255, 255), Parent = main})
            Library.create("TextLabel", {Size = UDim2.new(1, -16, 0, 30), Position = UDim2.new(0, 8, 0, 26), BackgroundTransparency = 1, Text = text, Font = FONT, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, TextColor3 = COL_TEXT, Parent = main})
            task.delay(15, function() gui:Destroy() end)
        end)
    end)
end

local ScreenGui = Library.create("ScreenGui", {Name = "FuckYouGui", ResetOnSpawn = false, Parent = LocalPlayer:WaitForChild("PlayerGui")})

function Library.CreateWindow(title)
    local window = Library.create("Frame", {Name = "FuckYou", Parent = ScreenGui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 940, 0, 510), ClipsDescendants = true, Visible = false, BackgroundColor3 = uiColor_MainWindow, BorderColor3 = COL_BORDER, BorderSizePixel = 1})
    table.insert(themeElements.MainWindow, window)
    
    local topBar = Library.create("Frame", {Name = "TopBar", Parent = window, Size = UDim2.new(1, 0, 0, 45), BackgroundColor3 = uiColor_TopBar, BorderSizePixel = 0})
    table.insert(themeElements.TopBars, topBar)
    
    local sideBar = Library.create("Frame", {Name = "SideBar", Parent = window, Position = UDim2.new(0, 0, 0, 45), Size = UDim2.new(0, 65, 1, -45), BackgroundColor3 = uiColor_SideBar, BorderSizePixel = 0})
    table.insert(themeElements.SideBars, sideBar)
    
    local menuInsided = Library.create("ScrollingFrame", {Name = "MenuInsided", Parent = window, Position = UDim2.new(0, 65, 0, 45), Size = UDim2.new(0, 105, 1, -45), BackgroundColor3 = uiColor_SideBar, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = COL_BORDER, CanvasSize = UDim2.new(0, 0, 0, 0), ClipsDescendants = true})
    table.insert(themeElements.SideBars, menuInsided)
    local menuLayout = Library.create("UIListLayout", {Parent = menuInsided, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)})
    Library.create("UIPadding", {Parent = menuInsided, PaddingTop = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)})
    menuLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() menuInsided.CanvasSize = UDim2.new(0, 0, 0, menuLayout.AbsoluteContentSize.Y + 10) end)
    
    local containment = Library.create("Frame", {Name = "Containment", Parent = window, Position = UDim2.new(0, 170, 0, 45), Size = UDim2.new(1, -170, 1, -45), BackgroundTransparency = 1, BorderSizePixel = 0})
    
    local dragging, dragInput, dragStart, startPosition
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPosition = window.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    topBar.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            window.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end)
    
    return window, topBar, sideBar, menuInsided, containment
end

function Library.CreateTabButton(name, parentMenu, containment, order)
    local btn = Library.create("TextButton", {Name = "Btn_"..name, Parent = parentMenu, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = order, Visible = false, BackgroundColor3 = uiColor_ButtonColor, BorderColor3 = COL_BORDER, TextColor3 = uiColor_TextColor, Text = name, Font = FONT, TextSize = 12})
    table.insert(themeElements.Buttons, btn); table.insert(themeElements.Texts, btn)
    local frame = Library.create("ScrollingFrame", {Name = "Tab_"..name, Parent = containment, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = COL_BORDER, CanvasSize = UDim2.new(0, 0, 0, 0), Visible = false})
    local tl = Library.create("UIListLayout", {Parent = frame, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
    Library.create("UIPadding", {Parent = frame, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)})
    tl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() frame.CanvasSize = UDim2.new(0, 0, 0, tl.AbsoluteContentSize.Y + 20) end)
    return btn, frame
end

function Library.CreateSection(parent, text)
    local lbl = Library.create("TextLabel", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = text, TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT, Parent = parent})
    table.insert(themeElements.Texts, lbl); return lbl
end

function Library.CreateLabel(parent, text)
    local lbl = Library.create("TextLabel", {Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = text, TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, Parent = parent})
    table.insert(themeElements.Texts, lbl); return lbl
end

function Library.CreateButton(parent, text, callback, customColor)
    local defaultColor = customColor or uiColor_ButtonColor
    local btn = Library.create("TextButton", {Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = defaultColor, BorderColor3 = COL_BORDER, TextColor3 = uiColor_TextColor, Text = text, Font = FONT, TextSize = 13, BackgroundTransparency = 1 - uiGuiOpacity, Parent = parent})
    if not customColor then table.insert(themeElements.Buttons, btn) else table.insert(themeElements.CustomButtons, btn) end
    table.insert(themeElements.Texts, btn)
    btn.MouseEnter:Connect(function() local c = btn.BackgroundColor3; btn.BackgroundColor3 = Color3.fromRGB(math.min(c.R*255+10,255), math.min(c.G*255+10,255), math.min(c.B*255+10,255)) end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = customColor or uiColor_ButtonColor end)
    btn.MouseButton1Click:Connect(callback); return btn
end

function Library.CreateTextBox(parent, placeholder, font)
    local box = Library.create("TextBox", {BackgroundColor3 = uiColor_TextBoxColor, BorderColor3 = COL_BORDER, TextColor3 = uiColor_TextColor, PlaceholderColor3 = Color3.fromRGB(90, 90, 90), PlaceholderText = placeholder, Text = "", TextSize = 13, Font = font or FONT, ClearTextOnFocus = false, BackgroundTransparency = 1 - uiGuiOpacity, Parent = parent})
    table.insert(themeElements.Texts, box); table.insert(themeElements.TextBoxes, box); return box
end

function Library.CreateToggle(parent, labelText, initial, callback)
    local obj = {State = initial and true or false}
    local btn = Library.create("TextButton", {Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = uiColor_ButtonColor, BorderColor3 = COL_BORDER, BackgroundTransparency = 1 - uiGuiOpacity, TextColor3 = uiColor_TextColor, Text = "", Font = FONT, TextSize = 13, Parent = parent})
    table.insert(themeElements.CustomButtons, btn); table.insert(themeElements.Texts, btn)
    local function paint()
        btn.Text = labelText .. ": " .. (obj.State and "ON" or "OFF")
        if obj.State then btn.BackgroundColor3 = scaleColor(uiColor_ToggleOnText, 0.35); btn.TextColor3 = uiColor_ToggleOnText
        else btn.BackgroundColor3 = scaleColor(uiColor_ToggleOffText, 0.35); btn.TextColor3 = uiColor_ToggleOffText end
    end
    toggleRegistry[btn] = function() return obj.State end
    paint()
    btn.MouseButton1Click:Connect(function() obj.State = not obj.State; paint(); if callback then callback(obj.State) end end)
    return obj
end

function Library.CreateDropdown(parent, labelText, getOptions, getCurrent, onselect)
    local container = Library.create("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = parent})
    Library.create("TextLabel", {Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1, Text = labelText, TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, Parent = container})
    local btn = Library.CreateButton(container, labelText .. ": " .. getCurrent(), function() end)
    btn.Size = UDim2.new(0.5, 0, 0.8, 0); btn.Position = UDim2.new(0.48, 0, 0.1, 0); btn.TextSize = 12
    local list = Library.create("ScrollingFrame", {Parent = container, Size = UDim2.new(0.5, 0, 0, 110), Position = UDim2.new(0.48, 0, 0.95, 0), BackgroundColor3 = uiColor_TextBoxColor, BorderColor3 = COL_BORDER, ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 0), Visible = false, ZIndex = 25})
    table.insert(themeElements.TextBoxes, list)
    Library.create("UIListLayout", {Parent = list, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2)})
    btn.MouseButton1Click:Connect(function()
        if list.Visible then list.Visible = false; return end
        for _, ch in ipairs(list:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
        local opts = getOptions()
        for _, opt in ipairs(opts) do
            local ob = Library.CreateButton(list, opt, function() onselect(opt); list.Visible = false; btn.Text = labelText .. ": " .. getCurrent() end)
            ob.Size = UDim2.new(1, -4, 0, 24); ob.ZIndex = 26; ob.TextSize = 12
        end
        list.CanvasSize = UDim2.new(0, 0, 0, #opts * 26 + 4); list.Visible = true
    end)
end

function Library.CreateSlider(parent, labelText, min, max, getval, onval, fmt)
    local container = Library.create("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = parent})
    Library.create("TextLabel", {Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1, Text = labelText, TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, Parent = container})
    local valLabel = Library.create("TextLabel", {Size = UDim2.new(0.5, 0, 0, 14), Position = UDim2.new(0.48, 0, 0.05, 0), BackgroundTransparency = 1, Text = fmt(getval()), TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Right, Parent = container})
    local track = Library.create("TextButton", {Size = UDim2.new(0.5, 0, 0, 10), Position = UDim2.new(0.48, 0, 0.55, 0), BackgroundColor3 = uiColor_TextBoxColor, BorderColor3 = COL_BORDER, Text = "", Parent = container})
    table.insert(themeElements.TextBoxes, track)
    local fill = Library.create("Frame", {Size = UDim2.new((getval() - min) / (max - min), 0, 1, 0), BackgroundColor3 = uiColor_TextColor, BorderSizePixel = 0, Parent = track})
    table.insert(themeElements.FillBars, fill)
    local dragging = false
    local function setFromX(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = math.floor(min + (max - min) * rel + 0.5)
        onval(v)
        fill.Size = UDim2.new((v - min) / (max - min), 0, 1, 0)
        valLabel.Text = fmt(v)
        Library.autoSaveConfig(true)
    end
    track.MouseButton1Down:Connect(function(x) dragging = true; setFromX(x) end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then setFromX(input.Position.X) end
    end)
    game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    return container
end

local configPath = "EmilyUi/Config.json"
local lastAutoConfigSave = 0
local configSaveListeners = {}
function Library.registerConfigSaveListener(fn) table.insert(configSaveListeners, fn) end
local function runConfigSaveListeners() for _, fn in ipairs(configSaveListeners) do pcall(fn) end end

function Library.saveConfig(extraData)
    local config = { ToggleKey = currentToggleKey.Name, MainWindowColor = {uiColor_MainWindow.R, uiColor_MainWindow.G, uiColor_MainWindow.B}, TopBarColor = {uiColor_TopBar.R, uiColor_TopBar.G, uiColor_TopBar.B}, SideBarColor = {uiColor_SideBar.R, uiColor_SideBar.G, uiColor_SideBar.B}, TextColor = {uiColor_TextColor.R, uiColor_TextColor.G, uiColor_TextColor.B}, ButtonColor = {uiColor_ButtonColor.R, uiColor_ButtonColor.G, uiColor_ButtonColor.B}, TextBoxColor = {uiColor_TextBoxColor.R, uiColor_TextBoxColor.G, uiColor_TextBoxColor.B}, ToggleOnColor = {uiColor_ToggleOnText.R, uiColor_ToggleOnText.G, uiColor_ToggleOnText.B}, ToggleOffColor = {uiColor_ToggleOffText.R, uiColor_ToggleOffText.G, uiColor_ToggleOffText.B}, GuiOpacity = uiGuiOpacity, ImageOpacity = uiImageOpacity, Blur = uiBlurSize, Fit = uiFitMode, BackgroundFile = uiBackgroundFile }
    if extraData then for k,v in pairs(extraData) do config[k] = v end end
    local success, json = pcall(function() return HttpService:JSONEncode(config) end)
    if success then if makefolder then pcall(function() makefolder("EmilyUi") end) end; if writefile then pcall(function() writefile(configPath, json) end) end end
end

function Library.loadConfig()
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
                return config
            end
        end
    end
    return nil
end

function Library.autoSaveConfig(force, extraData)
    if not unlocked and not force then return end
    if not force and os.clock() - lastAutoConfigSave < 0.5 then return end
    lastAutoConfigSave = os.clock()
    Library.saveConfig(extraData)
    runConfigSaveListeners()
end

function Library.applyTheme()
    local trans = 1 - uiGuiOpacity
    local function applyList(key, fn)
        local alive = {}
        for _, el in ipairs(themeElements[key]) do
            if typeof(el) == "Instance" and el.Parent then fn(el); table.insert(alive, el) end
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
            if getState() then btn.BackgroundColor3 = scaleColor(uiColor_ToggleOnText, 0.35); btn.TextColor3 = uiColor_ToggleOnText
            else btn.BackgroundColor3 = scaleColor(uiColor_ToggleOffText, 0.35); btn.TextColor3 = uiColor_ToggleOffText end
        else toggleRegistry[btn] = nil end
    end
end

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
    for i = 1, #str do result[i] = string.char(bit32.bxor(string.byte(str, i), string.byte(key, ((i - 1) % keyLen) + 1))) end
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
        local s = Library.create("Sound", {Name = "FuckYouUnlockSound", SoundId = "rbxassetid://115440201770223", Volume = 1, Looped = false, TimePosition = 0, Parent = SoundService})
        local done = false; local conn = nil
        local function cleanup() if done then return end; done = true; if conn then conn:Disconnect() end; pcall(function() s:Stop() end); pcall(function() s:Destroy() end) end
        s.Ended:Connect(cleanup)
        conn = RunService.Heartbeat:Connect(function() if not done and s.IsPlaying and s.TimePosition >= 2 then cleanup() end end)
        s:Play(); task.delay(10, cleanup)
    end)
end

function Library.initKeySystem(window, topBar, sideBar, menuInsided, containment, onUnlock)
    local KeyWindow = Library.create("Frame", {Name = "KeyWindow", Parent = ScreenGui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 450, 0, 310), BackgroundColor3 = uiColor_MainWindow, BorderColor3 = COL_BORDER})
    table.insert(themeElements.MainWindow, KeyWindow)
    local KeyTopBar = Library.create("Frame", {Parent = KeyWindow, Size = UDim2.new(1, 0, 0, 35), BackgroundColor3 = uiColor_TopBar, BorderSizePixel = 0})
    table.insert(themeElements.TopBars, KeyTopBar)
    Library.create("TextLabel", {Parent = KeyTopBar, Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = "Fuck you! — Key System", TextColor3 = uiColor_TextColor, TextSize = 15, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left})
    local KeyCloseBtn = Library.CreateButton(KeyTopBar, "X", function() ScreenGui:Destroy() end, Color3.fromRGB(120, 40, 40))
    KeyCloseBtn.Size = UDim2.new(0, 35, 0, 35); KeyCloseBtn.Position = UDim2.new(1, -35, 0, 0)
    
    local KeyInfoLabel = Library.create("TextLabel", {Parent = KeyWindow, Size = UDim2.new(1, -30, 0, 40), Position = UDim2.new(0, 15, 0, 50), BackgroundTransparency = 1, Text = "Please enter your access key below to load the script.\nKey can be obtained via Discord.", TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT, TextWrapped = true})
    table.insert(themeElements.Texts, KeyInfoLabel)
    
    Library.CreateButton(KeyWindow, "Click to copy Discord Server link", function() if setclipboard then setclipboard("https://discord.gg/75Dz8T9hHR") end; Library.notify("Discord", "The link is copied") end).Size = UDim2.new(1, -40, 0, 36)
    
    local KeyTextBox = Library.CreateTextBox(KeyWindow, "Enter key here...", FONT)
    KeyTextBox.Size = UDim2.new(1, -40, 0, 36)
    
    local cachedKeyResponse = nil
    local function checkKeySystem()
        if not cachedKeyResponse then
            local success, response = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/MamaSdoxla/EmilyUi/refs/heads/main/nuh-uh.json") end)
            if not success or not response or #response < 10 then KeyInfoLabel.Text = "Ошибка загрузки базы ключей!"; KeyInfoLabel.TextColor3 = Color3.fromRGB(220, 50, 50); return end
            local ok, decryptedText = pcall(function() return decryptData(response, SECRET_KEY) end)
            if not ok or not decryptedText or #decryptedText < 5 then KeyInfoLabel.Text = "Ошибка расшифровки ключей!"; KeyInfoLabel.TextColor3 = Color3.fromRGB(220, 50, 50); return end
            cachedKeyResponse = decryptedText
        end
        local jsonSuccess, keysList = pcall(function() return HttpService:JSONDecode(cachedKeyResponse) end)
        if not jsonSuccess or type(keysList) ~= "table" then KeyInfoLabel.Text = "Ошибка парсинга базы данных!"; KeyInfoLabel.TextColor3 = Color3.fromRGB(220, 50, 50); return end
        
        local myName = string.lower(LocalPlayer.Name)
        local enteredKey = KeyTextBox.Text
        for _, data in ipairs(keysList) do
            if data.key and data.robloxName and data.group and data.timeTillWorks then
                local nameMatch = (data.robloxName == "none") or (string.lower(data.robloxName) == myName)
                local g = string.lower(tostring(data.group or ""))
                local groupAllowed = beta and (g == "tester" or g == "coder") or (g == "free" or g == "user" or g == "tester" or g == "coder")
                if nameMatch and groupAllowed then
                    local daysLeft = getKeyDaysLeft(data.timeTillWorks)
                    if daysLeft == "Infinity" or (type(daysLeft) == "number" and daysLeft > 0) then
                        if data.key == "none" or (enteredKey == data.key) then
                            unlocked = true
                            playUnlockJingle()
                            KeyWindow:Destroy()
                            window.Visible = true
                            onUnlock(data.group, daysLeft)
                            return
                        end
                    end
                end
            end
        end
        KeyInfoLabel.Text = beta and "Beta mode: only Tester/Coder keys are allowed." or "Enter key please! You can ask for a key in discord."
        KeyInfoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
    
    local BtnSubmit = Library.CreateButton(KeyWindow, "Check Key", checkKeySystem, Color3.fromRGB(40, 90, 40))
    BtnSubmit.Size = UDim2.new(0, 150, 0, 36); BtnSubmit.Position = UDim2.new(0.5, -75, 0, 240)
    
    task.spawn(checkKeySystem)
end

local keyListProviders = {}
function Library.registerKeyListProvider(group, fn) keyListProviders[group] = fn end
local KL = { Enabled = true, ShowEmily = true, ShowDesync = true, ShowMusic = true, ShowAim = true, ShowMovement = true }
local overlay = Library.create("Frame", { Name = "FYKeyList", Parent = ScreenGui, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.new(0, 250, 0, 60), BackgroundColor3 = uiColor_MainWindow, BorderColor3 = COL_BORDER, BorderSizePixel = 1, Visible = false, ZIndex = 5 })
table.insert(themeElements.MainWindow, overlay)
local topLine = Library.create("Frame", {Parent = overlay, Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, ZIndex = 6})
Library.create("UIGradient", {Parent = topLine, Color = ColorSequence.new({ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0, 170, 255)), ColorSequenceKeypoint.new(0.25, Color3.fromRGB(170, 80, 255)), ColorSequenceKeypoint.new(0.50, Color3.fromRGB(255, 90, 160)), ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 190, 60)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(150, 255, 80))})})
local titleBar = Library.create("TextLabel", {Parent = overlay, Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0, 0, 0, 2), BackgroundTransparency = 1, Text = "KEYBINDS", TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT, ZIndex = 6})
table.insert(themeElements.Texts, titleBar)
local rowsFrame = Library.create("Frame", {Parent = overlay, Size = UDim2.new(1, 0, 1, -26), Position = UDim2.new(0, 0, 0, 26), BackgroundTransparency = 1, ZIndex = 6})
local rowsLayout = Library.create("UIListLayout", {Parent = rowsFrame, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)})
Library.create("UIPadding", {Parent = rowsFrame, PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 8)})

local GROUP_MAP = { {"ShowEmily", "EmilyUi", "EMILYUI"}, {"ShowDesync", "Desync", "DESYNC"}, {"ShowMusic", "Music", "MUSIC"}, {"ShowAim", "Aim", "AIM"}, {"ShowMovement", "Movement", "MOVEMENT"} }
local function collectRows()
    local out = {}
    for _, g in ipairs(GROUP_MAP) do
        if KL[g[1]] and keyListProviders[g[2]] then
            local ok, rows = pcall(keyListProviders[g[2]])
            rows = (ok and type(rows) == "table") and rows or {}
            if #rows > 0 then
                table.insert(out, {"h", g[3]})
                for _, r in ipairs(rows) do table.insert(out, {"r", tostring(r[1]), tostring(r[2])}) end
            end
        end
    end
    return out
end
local function rebuildKL()
    for _, ch in ipairs(rowsFrame:GetChildren()) do if ch:IsA("Frame") or ch:IsA("TextLabel") then ch:Destroy() end end
    for i, it in ipairs(collectRows()) do
        if it[1] == "h" then
            local h = Library.create("TextLabel", { Parent = rowsFrame, LayoutOrder = i, Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Text = it[2], TextColor3 = uiColor_TextColor, TextSize = 11, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6 })
            table.insert(themeElements.Texts, h)
        else
            local r = Library.create("Frame", {Parent = rowsFrame, LayoutOrder = i, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, ZIndex = 6})
            Library.create("TextLabel", {Parent = r, Size = UDim2.new(0.62, 0, 1, 0), BackgroundTransparency = 1, Text = it[2], TextColor3 = uiColor_TextColor, TextSize = 12, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6})
            Library.create("TextLabel", {Parent = r, Size = UDim2.new(0.38, 0, 1, 0), Position = UDim2.new(0.62, 0, 0, 0), BackgroundTransparency = 1, Text = it[3], TextColor3 = uiColor_ToggleOnText, TextSize = 12, Font = FONT, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6})
        end
    end
    if overlay.Parent then overlay.Size = UDim2.new(0, 250, 0, 26 + rowsLayout.AbsoluteContentSize.Y + 8) end
end
local lastSnap = ""
function Library.refreshKL(force)
    if not overlay or not overlay.Parent then return end
    local vis = (KL.Enabled and unlocked) and true or false
    overlay.Visible = vis
    if not vis then return end
    local t = {}
    for _, it in ipairs(collectRows()) do table.insert(t, table.concat(it, "|")) end
    local snap = table.concat(t, "#")
    if force or snap ~= lastSnap then lastSnap = snap; rebuildKL() end
end
task.spawn(function() while true do task.wait(0.5); pcall(Library.refreshKL) end end)

function Library.getColor(name)
    if name == "MainWindow" then return uiColor_MainWindow
    elseif name == "TopBar" then return uiColor_TopBar
    elseif name == "SideBar" then return uiColor_SideBar
    elseif name == "Text" then return uiColor_TextColor
    elseif name == "Button" then return uiColor_ButtonColor
    elseif name == "TextBox" then return uiColor_TextBoxColor
    elseif name == "ToggleOn" then return uiColor_ToggleOnText
    elseif name == "ToggleOff" then return uiColor_ToggleOffText
    end
end
function Library.setColor(name, color)
    if name == "MainWindow" then uiColor_MainWindow = color
    elseif name == "TopBar" then uiColor_TopBar = color
    elseif name == "SideBar" then uiColor_SideBar = color
    elseif name == "Text" then uiColor_TextColor = color
    elseif name == "Button" then uiColor_ButtonColor = color
    elseif name == "TextBox" then uiColor_TextBoxColor = color
    elseif name == "ToggleOn" then uiColor_ToggleOnText = color
    elseif name == "ToggleOff" then uiColor_ToggleOffText = color
    end
end
function Library.getToggleKey() return currentToggleKey end
function Library.setToggleKey(key) currentToggleKey = key end
function Library.getBackgroundFile() return uiBackgroundFile end
function Library.setBackgroundFile(file) uiBackgroundFile = file end
function Library.getFitMode() return uiFitMode end
function Library.setFitMode(mode) uiFitMode = mode end
function Library.getGuiOpacity() return uiGuiOpacity end
function Library.setGuiOpacity(op) uiGuiOpacity = op end
function Library.getImageOpacity() return uiImageOpacity end
function Library.setImageOpacity(op) uiImageOpacity = op end
function Library.getBlurSize() return uiBlurSize end
function Library.setBlurSize(size) uiBlurSize = size end

local function getBackgroundFiles()
    local out = {}
    if listfiles then
        local ok, files = pcall(function() return listfiles("EmilyUi/FuckYou/Background") end)
        if ok and files then for _, p in ipairs(files) do local name = p:match("([^/\\]+)$"); local ext = name and name:lower():match("%.(%w+)$"); if ext == "png" or ext == "jpg" or ext == "jpeg" or ext == "webp" then table.insert(out, name) end end; table.sort(out) end
    end
    return out
end
Library.getBackgroundFiles = getBackgroundFiles

return Library