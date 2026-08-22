-- Library.lua
local Library = {}

--// Сервисы
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")

--// Стили
local COL_BG = Color3.fromRGB(12, 12, 12)
local COL_BORDER = Color3.fromRGB(22, 22, 22)
local COL_TEXT = Color3.fromRGB(139, 135, 127)
local COL_TEXTBOX = Color3.fromRGB(18, 18, 18)
local FONT = Enum.Font.SpecialElite

--// Переменные
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
local unlocked = false
local isHidden = false
local isCollapsed = false
local cachedKeyResponse = nil
local currentKeyData = { group = "Free", daysLeft = "Infinity" }

--// Реестр элементов для темы
local themeElements = { MainWindow = {}, TopBars = {}, SideBars = {}, Texts = {}, Buttons = {}, TextBoxes = {}, FillBars = {}, CustomButtons = {} }
local BG_FOLDER = "EmilyUi/FuckYou/Background"
local configFolder = "EmilyUi/FuckYou/Configs"
local lastConfigPath = configFolder .. "/last_config.txt"

local function create(className, properties)
    local inst = Instance.new(className)
    for k, v in pairs(properties) do inst[k] = v end
    return inst
end

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 5})
    end)
end

--// Blur Effect
local blurEffect = Instance.new("BlurEffect")
blurEffect.Name = "FuckYouBlur"
blurEffect.Size = 0
blurEffect.Enabled = false

local function updateBlur()
    if uiBlurSize > 0 then
        blurEffect.Size = uiBlurSize
        blurEffect.Enabled = true
        if blurEffect.Parent ~= Lighting then
            blurEffect.Parent = Lighting
        end
    else
        blurEffect.Enabled = false
        blurEffect.Parent = nil
    end
end

--// Theme Apply
local function applyTheme()
    local trans = 1 - uiGuiOpacity
    for _, el in ipairs(themeElements.MainWindow) do
        if el.Parent then el.BackgroundColor3 = uiColor_MainWindow; el.BackgroundTransparency = trans end
    end
    for _, el in ipairs(themeElements.TopBars) do
        if el.Parent then el.BackgroundColor3 = uiColor_TopBar; el.BackgroundTransparency = trans end
    end
    for _, el in ipairs(themeElements.SideBars) do
        if el.Parent then el.BackgroundColor3 = uiColor_SideBar; el.BackgroundTransparency = trans end
    end
    for _, el in ipairs(themeElements.Texts) do
        if el.Parent then el.TextColor3 = uiColor_TextColor end
    end
    for _, el in ipairs(themeElements.Buttons) do
        if el.Parent then el.BackgroundColor3 = uiColor_ButtonColor; el.BackgroundTransparency = trans end
    end
    for _, el in ipairs(themeElements.TextBoxes) do
        if el.Parent then el.BackgroundColor3 = uiColor_TextBoxColor; el.BackgroundTransparency = trans end
    end
    for _, el in ipairs(themeElements.FillBars) do
        if el.Parent then el.BackgroundColor3 = uiColor_TextColor end
    end
    updateBlur()
end

--// Background
local function getBackgroundFiles()
    local out = {"None"}
    if listfiles then
        pcall(function()
            for _, p in ipairs(listfiles(BG_FOLDER)) do
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

local function applyBackground(bgImage)
    if not bgImage then return end
    local asset = nil
    if uiBackgroundFile ~= "" and uiBackgroundFile ~= "None" then
        local path = BG_FOLDER .. "/" .. uiBackgroundFile
        if getcustomasset then
            pcall(function() asset = getcustomasset(path) end)
        end
    end
    if asset then
        bgImage.Image = asset
        bgImage.ScaleType = Enum.ScaleType[uiFitMode] or Enum.ScaleType.Stretch
        bgImage.ImageTransparency = 1 - uiImageOpacity
        bgImage.Visible = true
    else
        bgImage.Visible = false
        bgImage.Image = ""
    end
end

--// Config System
local function filesSupported()
    return writefile ~= nil and readfile ~= nil and makefolder ~= nil and isfile ~= nil and isfolder ~= nil
end

local function ensureFolders()
    if not filesSupported() then return end
    pcall(function()
        if not isfolder("EmilyUi") then makefolder("EmilyUi") end
        if not isfolder("EmilyUi/FuckYou") then makefolder("EmilyUi/FuckYou") end
        if not isfolder(BG_FOLDER) then makefolder(BG_FOLDER) end
        if not isfolder(configFolder) then makefolder(configFolder) end
    end)
end

local function getSavedConfigs()
    local names = {}
    if listfiles and filesSupported() then
        pcall(function()
            for _, path in ipairs(listfiles(configFolder)) do
                local name = path:match("([^/\\]+)%.json$")
                if name then table.insert(names, name) end
            end
        end)
        table.sort(names)
    end
    return names
end

local function getLastConfigName()
    if filesSupported() and isfile(lastConfigPath) then
        local ok, name = pcall(function() return readfile(lastConfigPath) end)
        if ok and name and name ~= "" then return name end
    end
    return nil
end

local function setLastConfigName(name)
    if filesSupported() then
        pcall(function() writefile(lastConfigPath, name) end)
    end
end

local function gatherConfig()
    return {
        ToggleKey = currentToggleKey.Name,
        MainWindowColor = {uiColor_MainWindow.R, uiColor_MainWindow.G, uiColor_MainWindow.B},
        TopBarColor = {uiColor_TopBar.R, uiColor_TopBar.G, uiColor_TopBar.B},
        SideBarColor = {uiColor_SideBar.R, uiColor_SideBar.G, uiColor_SideBar.B},
        TextColor = {uiColor_TextColor.R, uiColor_TextColor.G, uiColor_TextColor.B},
        ButtonColor = {uiColor_ButtonColor.R, uiColor_ButtonColor.G, uiColor_ButtonColor.B},
        TextBoxColor = {uiColor_TextBoxColor.R, uiColor_TextBoxColor.G, uiColor_TextBoxColor.B},
        ToggleOnColor = {uiColor_ToggleOnText.R, uiColor_ToggleOnText.G, uiColor_ToggleOnText.B},
        ToggleOffColor = {uiColor_ToggleOffText.R, uiColor_ToggleOffText.G, uiColor_ToggleOffText.B},
        GuiOpacity = uiGuiOpacity,
        ImageOpacity = uiImageOpacity,
        Blur = uiBlurSize,
        Fit = uiFitMode,
        BackgroundFile = uiBackgroundFile,
    }
end

local function applyConfigValues(cfg)
    if type(cfg.ToggleKey) == "string" then
        pcall(function() currentToggleKey = Enum.KeyCode[cfg.ToggleKey] end)
    end
    if cfg.MainWindowColor then uiColor_MainWindow = Color3.new(unpack(cfg.MainWindowColor)) end
    if cfg.TopBarColor then uiColor_TopBar = Color3.new(unpack(cfg.TopBarColor)) end
    if cfg.SideBarColor then uiColor_SideBar = Color3.new(unpack(cfg.SideBarColor)) end
    if cfg.TextColor then uiColor_TextColor = Color3.new(unpack(cfg.TextColor)) end
    if cfg.ButtonColor then uiColor_ButtonColor = Color3.new(unpack(cfg.ButtonColor)) end
    if cfg.TextBoxColor then uiColor_TextBoxColor = Color3.new(unpack(cfg.TextBoxColor)) end
    if cfg.ToggleOnColor then uiColor_ToggleOnText = Color3.new(unpack(cfg.ToggleOnColor)) end
    if cfg.ToggleOffColor then uiColor_ToggleOffText = Color3.new(unpack(cfg.ToggleOffColor)) end
    if cfg.GuiOpacity then uiGuiOpacity = math.clamp(cfg.GuiOpacity, 0.25, 1) end
    if cfg.ImageOpacity then uiImageOpacity = math.clamp(cfg.ImageOpacity, 0, 1) end
    if cfg.Blur then uiBlurSize = math.clamp(cfg.Blur, 0, 24) end
    if cfg.Fit then uiFitMode = cfg.Fit end
    if cfg.BackgroundFile ~= nil then uiBackgroundFile = cfg.BackgroundFile end
    applyTheme()
end

local function loadNamedConfig(name)
    if not filesSupported() then notify("Configs", "Executor doesn't support files") return end
    local path = configFolder .. "/" .. name .. ".json"
    if isfile(path) then
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

local function saveNamedConfig(name)
    if not filesSupported() then notify("Configs", "Executor doesn't support files") return end
    if name == "" then notify("Configs", "Enter a config name!") return end
    ensureFolders()
    local ok, json = pcall(function() return HttpService:JSONEncode(gatherConfig()) end)
    if ok then
        writefile(configFolder .. "/" .. name .. ".json", json)
        setLastConfigName(name)
        notify("Configs", "Saved: " .. name)
    end
end

--// Key System
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
    if not day then return 0 end
    local expireTime = os.time({day = tonumber(day), month = tonumber(month), year = tonumber(year), hour = 0, min = 0, sec = 0})
    local diff = expireTime - os.time()
    return diff <= 0 and 0 or diff / 86400
end

local function isGroupAllowed(groupName)
    local g = string.lower(tostring(groupName or ""))
    return g == "free" or g == "user" or g == "tester" or g == "coder"
end

local function checkKeySystem(keyWindow, keyTextBox, keyInfoLabel)
    if not cachedKeyResponse then
        local success, response = pcall(function()
            return game:HttpGet("https://raw.githubusercontent.com/MamaSdoxla/EmilyUi/refs/heads/main/nuh-uh.json")
        end)
        if not success or not response or #response < 10 then
            keyInfoLabel.Text = "Error: Failed to fetch key database!"
            keyInfoLabel.TextColor3 = Color3.fromRGB(220, 50, 50)
            return
        end
        local ok, decryptedText = pcall(function() return decryptData(response, SECRET_KEY) end)
        if not ok or not decryptedText or #decryptedText < 5 then
            keyInfoLabel.Text = "Error: Failed to decrypt!"
            keyInfoLabel.TextColor3 = Color3.fromRGB(220, 50, 50)
            return
        end
        cachedKeyResponse = decryptedText
    end
    
    local jsonSuccess, keysList = pcall(function() return HttpService:JSONDecode(cachedKeyResponse) end)
    if not jsonSuccess or type(keysList) ~= "table" then
        keyInfoLabel.Text = "Error: Database parsing failed!"
        keyInfoLabel.TextColor3 = Color3.fromRGB(220, 50, 50)
        return
    end
    
    local myName = string.lower(LocalPlayer.Name)
    local enteredKey = keyTextBox.Text
    
    for _, data in ipairs(keysList) do
        if data.key and data.robloxName and data.group and data.timeTillWorks then
            local nameMatch = (data.robloxName == "none") or (string.lower(data.robloxName) == myName)
            if nameMatch and isGroupAllowed(data.group) then
                local daysLeft = getKeyDaysLeft(data.timeTillWorks)
                if daysLeft == "Infinity" or (type(daysLeft) == "number" and daysLeft > 0) then
                    if data.key == "none" or (enteredKey == data.key) then
                        return data.group, daysLeft
                    end
                end
            end
        end
    end
    
    keyInfoLabel.Text = "Enter key please! You can ask for a key in discord."
    keyInfoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    return nil
end

--// MAIN INIT
function Library:Init()
    ensureFolders()
    
    local ScreenGui = create("ScreenGui", {Name = "FuckYouGui", ResetOnSpawn = false, IgnoreGuiInset = true, Parent = LocalPlayer:WaitForChild("PlayerGui")})
    
    --// Key Window
    local KeyWindow = create("Frame", {
        Name = "KeyWindow", Parent = ScreenGui,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 450, 0, 310),
        BackgroundColor3 = uiColor_MainWindow, BorderColor3 = COL_BORDER, BorderSizePixel = 1
    })
    table.insert(themeElements.MainWindow, KeyWindow)
    
    local KeyTopBar = create("Frame", {
        Parent = KeyWindow, Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = uiColor_TopBar, BorderSizePixel = 0
    })
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
        Text = "Please enter your access key below.\nKey can be obtained via Discord.",
        TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT, TextWrapped = true
    })
    table.insert(themeElements.Texts, KeyInfoLabel)
    
    local KeyDiscordBtn = create("TextButton", {
        Parent = KeyWindow, Size = UDim2.new(1, -40, 0, 36), Position = UDim2.new(0, 20, 0, 105),
        BackgroundColor3 = uiColor_ButtonColor, BorderColor3 = COL_BORDER,
        TextColor3 = uiColor_TextColor, Text = "Click to copy Discord Server link",
        Font = FONT, TextSize = 13, BackgroundTransparency = 1 - uiGuiOpacity
    })
    table.insert(themeElements.Buttons, KeyDiscordBtn)
    table.insert(themeElements.Texts, KeyDiscordBtn)
    KeyDiscordBtn.MouseButton1Click:Connect(function()
        if setclipboard then setclipboard("https://discord.gg/75Dz8T9hHR") end
        notify("Discord", "The link is copied")
    end)
    
    local KeyTextBox = create("TextBox", {
        Parent = KeyWindow, Size = UDim2.new(1, -40, 0, 36), Position = UDim2.new(0, 20, 0, 160),
        BackgroundColor3 = uiColor_TextBoxColor, BorderColor3 = COL_BORDER,
        TextColor3 = uiColor_TextColor, PlaceholderColor3 = Color3.fromRGB(90, 90, 90),
        PlaceholderText = "Enter key here...", Text = "", TextSize = 13, Font = FONT,
        ClearTextOnFocus = false, BackgroundTransparency = 1 - uiGuiOpacity
    })
    table.insert(themeElements.TextBoxes, KeyTextBox)
    table.insert(themeElements.Texts, KeyTextBox)
    
    local BtnSubmit = create("TextButton", {
        Parent = KeyWindow, Size = UDim2.new(0, 150, 0, 36), Position = UDim2.new(0.5, -75, 0, 240),
        BackgroundColor3 = Color3.fromRGB(40, 90, 40), BorderColor3 = COL_BORDER,
        TextColor3 = Color3.fromRGB(255, 255, 255), Text = "Check Key", Font = FONT, TextSize = 13,
        BackgroundTransparency = 1 - uiGuiOpacity
    })
    table.insert(themeElements.Buttons, BtnSubmit)
    table.insert(themeElements.Texts, BtnSubmit)
    
    applyTheme()
    
    --// Main GUI (скрыто до разблокировки)
    local FuckYou = create("Frame", {
        Name = "FuckYou", Parent = ScreenGui,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 940, 0, 510), ClipsDescendants = true, Visible = false,
        BackgroundColor3 = uiColor_MainWindow, BorderColor3 = COL_BORDER, BorderSizePixel = 1
    })
    table.insert(themeElements.MainWindow, FuckYou)
    
    --// Background Image (ZIndex = 0, чтобы не просвечивать через TopBar)
    local BackgroundImage = create("ImageLabel", {
        Name = "BackgroundImage", Parent = FuckYou,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, Image = "", Visible = false,
        ScaleType = Enum.ScaleType.Stretch, ImageTransparency = 0, ZIndex = 0
    })
    
    --// TopBar (ZIndex = 2, чтобы быть поверх фона)
    local TopBar = create("Frame", {
        Name = "TopBar", Parent = FuckYou,
        Size = UDim2.new(1, 0, 0, 45),
        BackgroundColor3 = uiColor_TopBar, BorderSizePixel = 0, ZIndex = 2
    })
    table.insert(themeElements.TopBars, TopBar)
    
    local Title = create("TextLabel", {
        Name = "Name", Parent = TopBar,
        Size = UDim2.new(1, -135, 1, 0),
        BackgroundTransparency = 1, Text = "Fuck you! v1.2",
        TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT, ZIndex = 3
    })
    table.insert(themeElements.Texts, Title)
    
    --// Кнопки управления
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
            b.BackgroundColor3 = Color3.fromRGB(math.min(uiColor_TopBar.R*255+10,255), math.min(uiColor_TopBar.G*255+10,255), math.min(uiColor_TopBar.B*255+10,255))
        end)
        b.MouseLeave:Connect(function() b.BackgroundColor3 = uiColor_TopBar end)
        return b
    end
    
    local MinusBtn = makeTopBtn("-", 3)
    local EqualBtn = makeTopBtn("=", 2)
    local XBtn = makeTopBtn("X", 1)
    
    --// Анимация сворачивания
    local currentTween = nil
    local function tweenSize(target, cb)
        if currentTween then currentTween:Cancel() end
        local tw = TweenService:Create(FuckYou, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = target})
        currentTween = tw
        if cb then tw.Completed:Connect(function(ps) if ps == Enum.PlaybackState.Completed then cb() end end) end
        tw:Play()
    end
    
    XBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
    EqualBtn.MouseButton1Click:Connect(function()
        if not isCollapsed then
            isCollapsed = true
            tweenSize(UDim2.new(0, 940, 0, 45))
        else
            isCollapsed = false
            tweenSize(UDim2.new(0, 940, 0, 510))
        end
    end)
    MinusBtn.MouseButton1Click:Connect(function()
        isHidden = true
        tweenSize(UDim2.new(0, 940, 0, 0), function() FuckYou.Visible = false end)
    end)
    
    --// SideBar
    local SideBard = create("Frame", {
        Name = "SideBard", Parent = FuckYou,
        Position = UDim2.new(0, 0, 0, 45), Size = UDim2.new(0, 65, 1, -45),
        BackgroundColor3 = uiColor_SideBar, BorderSizePixel = 0, ZIndex = 2
    })
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
    
    local UiBtn = makeSideBtn("Ui", 0)
    
    --// MenuInsided
    local MenuInsided = create("ScrollingFrame", {
        Name = "MenuInsided", Parent = FuckYou,
        Position = UDim2.new(0, 65, 0, 45), Size = UDim2.new(0, 105, 1, -45),
        BackgroundColor3 = uiColor_SideBar, BorderSizePixel = 0,
        ScrollBarThickness = 3, Visible = false, ZIndex = 2
    })
    table.insert(themeElements.SideBars, MenuInsided)
    create("UIListLayout", {Parent = MenuInsided, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)})
    
    --// Containment
    local Containment = create("Frame", {
        Name = "Containment", Parent = FuckYou,
        Position = UDim2.new(0, 170, 0, 45), Size = UDim2.new(1, -170, 1, -45),
        BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2
    })
    
    --// Tab Frames
    local function createTabContentFrame(name)
        local sf = create("ScrollingFrame", {
            Name = name, Parent = Containment,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 4, Visible = false
        })
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
    
    --// Helper functions
    local function createSection(parent, text)
        local lbl = create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = 1, Text = text,
            TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT,
            TextXAlignment = Enum.TextXAlignment.Center,
            Parent = parent
        })
        table.insert(themeElements.Texts, lbl)
        return lbl
    end
    
    local function createLabel(parent, text)
        local lbl = create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 22),
            BackgroundTransparency = 1, Text = text,
            TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = parent
        })
        table.insert(themeElements.Texts, lbl)
        return lbl
    end
    
    local function createContentButton(parent, text, callback)
        local btn = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = uiColor_ButtonColor, BorderColor3 = COL_BORDER,
            TextColor3 = uiColor_TextColor, Text = text, Font = FONT, TextSize = 13,
            BackgroundTransparency = 1 - uiGuiOpacity,
            Parent = parent
        })
        table.insert(themeElements.Buttons, btn)
        table.insert(themeElements.Texts, btn)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end
    
    local function createTextBox(parent, placeholder)
        local box = create("TextBox", {
            BackgroundColor3 = uiColor_TextBoxColor, BorderColor3 = COL_BORDER,
            TextColor3 = uiColor_TextColor, PlaceholderColor3 = Color3.fromRGB(90, 90, 90),
            PlaceholderText = placeholder, Text = "", TextSize = 13, Font = FONT,
            ClearTextOnFocus = false, BackgroundTransparency = 1 - uiGuiOpacity,
            Parent = parent
        })
        table.insert(themeElements.Texts, box)
        table.insert(themeElements.TextBoxes, box)
        return box
    end
    
    local function createSlider(parent, labelText, min, max, getval, onval, fmt)
        local container = create("Frame", {
            Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = parent
        })
        local label = create("TextLabel", {
            Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1,
            Text = labelText, TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = container
        })
        table.insert(themeElements.Texts, label)
        
        local valLabel = create("TextLabel", {
            Size = UDim2.new(0.5, 0, 0, 14), Position = UDim2.new(0.48, 0, 0.05, 0),
            BackgroundTransparency = 1, Text = fmt(getval()),
            TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT,
            TextXAlignment = Enum.TextXAlignment.Right, Parent = container
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
        end
        track.MouseButton1Down:Connect(function(x) dragging = true; setFromX(x) end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then setFromX(input.Position.X) end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
    end
    
    local function createDropdown(parent, labelText, getOptions, getCurrent, onselect)
        local container = create("Frame", {
            Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = parent
        })
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
            Parent = container, Size = UDim2.new(0.5, 0, 0, 110), Position = UDim2.new(0.48, 0, 0.95, 0),
            BackgroundColor3 = uiColor_TextBoxColor, BorderColor3 = COL_BORDER,
            ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 0), Visible = false, ZIndex = 25
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
                end)
                ob.Size = UDim2.new(1, -4, 0, 24)
                ob.ZIndex = 26
                ob.TextSize = 12
            end
            list.CanvasSize = UDim2.new(0, 0, 0, #opts * 26 + 4)
            list.Visible = true
        end)
    end
    
    local function createColorInput(parent, labelText, getcol, oncol)
        local container = create("Frame", {
            Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = parent
        })
        local label = create("TextLabel", {
            Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1,
            Text = labelText, TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = container
        })
        table.insert(themeElements.Texts, label)
        
        local c = getcol()
        local box = createTextBox(container, "R,G,B")
        box.Size = UDim2.new(0.5, 0, 0.8, 0)
        box.Position = UDim2.new(0.48, 0, 0.1, 0)
        box.TextSize = 12
        box.Text = math.floor(c.R * 255) .. "," .. math.floor(c.G * 255) .. "," .. math.floor(c.B * 255)
        
        box.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                local r, g, b = box.Text:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
                if r and g and b then
                    oncol(Color3.fromRGB(math.clamp(tonumber(r), 0, 255), math.clamp(tonumber(g), 0, 255), math.clamp(tonumber(b), 0, 255)))
                    applyTheme()
                else
                    box.Text = "Invalid!"
                end
            end
        end)
    end
    
    --// Tab Switching
    local function switchTab(targetTab)
        for _, tab in pairs(tabFrames) do tab.Visible = (tab == targetTab) end
    end
    
    local function addMenuButton(text, targetTab)
        local btn = create("TextButton", {
            Parent = MenuInsided, Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = uiColor_ButtonColor, BorderColor3 = COL_BORDER,
            TextColor3 = uiColor_TextColor, Text = text, Font = FONT, TextSize = 12
        })
        table.insert(themeElements.Buttons, btn)
        table.insert(themeElements.Texts, btn)
        btn.MouseButton1Click:Connect(function() switchTab(targetTab) end)
    end
    
    addMenuButton("Main info", tabFrames.Main)
    addMenuButton("Settings", tabFrames.Settings)
    
    UiBtn.MouseButton1Click:Connect(function()
        MenuInsided.Visible = not MenuInsided.Visible
        if MenuInsided.Visible then switchTab(tabFrames.Main) end
    end)
    
    --// MAIN INFO TAB
    -- UserProfilePanel
    local UserProfilePanel = create("Frame", {
        Name = "UserProfilePanel", Parent = tabFrames.Main,
        Size = UDim2.new(1, 0, 0, 60), LayoutOrder = -1,
        BackgroundColor3 = uiColor_SideBar, BorderColor3 = COL_BORDER
    })
    table.insert(themeElements.SideBars, UserProfilePanel)
    
    local UserImage = create("ImageLabel", {
        Parent = UserProfilePanel,
        Position = UDim2.new(0, 10, 0, 10), Size = UDim2.new(0, 40, 0, 40),
        BackgroundTransparency = 1,
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"
    })
    create("UICorner", {Parent = UserImage, CornerRadius = UDim.new(1, 0)})
    
    create("TextLabel", {
        Parent = UserProfilePanel,
        Position = UDim2.new(0, 60, 0, 6), Size = UDim2.new(1, -70, 0, 16),
        BackgroundTransparency = 1, Text = LocalPlayer.DisplayName,
        TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 13, Font = FONT,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd
    })
    
    local UserKeyTimeLabel = create("TextLabel", {
        Parent = UserProfilePanel,
        Position = UDim2.new(0, 60, 0, 22), Size = UDim2.new(1, -70, 0, 14),
        BackgroundTransparency = 1, Text = "Days left: Inf",
        TextColor3 = Color3.fromRGB(180, 180, 180), TextSize = 12, Font = FONT,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    table.insert(themeElements.Texts, UserKeyTimeLabel)
    
    local UserGroupLabel = create("TextLabel", {
        Parent = UserProfilePanel,
        Position = UDim2.new(0, 60, 0, 38), Size = UDim2.new(1, -70, 0, 14),
        BackgroundTransparency = 1, Text = "Group: Free",
        TextColor3 = Color3.fromRGB(150, 150, 150), TextSize = 12, Font = FONT,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    table.insert(themeElements.Texts, UserGroupLabel)
    
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
    
    createSection(tabFrames.Main, "In case something happens here's a discord server")
    createContentButton(tabFrames.Main, "Click to copy Discord Server link", function()
        if setclipboard then setclipboard("https://discord.gg/75Dz8T9hHR") end
        notify("Discord", "The link is copied")
    end)
    createSection(tabFrames.Main, "* Credits to *")
    createLabel(tabFrames.Main, "WdymGaming (wdymgaming) -> coder")
    createLabel(tabFrames.Main, "pashajokot (swatwincky) -> tester")
    createLabel(tabFrames.Main, "BombalMac (bombapc) -> tester")
    
    --// SETTINGS TAB
    createSection(tabFrames.Settings, "UI Customization")
    
    -- Key Bind
    local keyBindContainer = create("Frame", {
        Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = tabFrames.Settings
    })
    create("TextLabel", {
        Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1,
        Text = "Menu Toggle Key:", TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = keyBindContainer
    })
    
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
                connection:Disconnect()
            end
        end)
    end)
    
    -- Colors
    createColorInput(tabFrames.Settings, "Main Window Color:", function() return uiColor_MainWindow end, function(c) uiColor_MainWindow = c end)
    createColorInput(tabFrames.Settings, "Top Bar Color:", function() return uiColor_TopBar end, function(c) uiColor_TopBar = c end)
    createColorInput(tabFrames.Settings, "Side Bar Color:", function() return uiColor_SideBar end, function(c) uiColor_SideBar = c end)
    createColorInput(tabFrames.Settings, "Text Color:", function() return uiColor_TextColor end, function(c) uiColor_TextColor = c end)
    createColorInput(tabFrames.Settings, "Button Color:", function() return uiColor_ButtonColor end, function(c) uiColor_ButtonColor = c end)
    createColorInput(tabFrames.Settings, "TextBox Color:", function() return uiColor_TextBoxColor end, function(c) uiColor_TextBoxColor = c end)
    createColorInput(tabFrames.Settings, "Toggle ON Color:", function() return uiColor_ToggleOnText end, function(c) uiColor_ToggleOnText = c end)
    createColorInput(tabFrames.Settings, "Toggle OFF Color:", function() return uiColor_ToggleOffText end, function(c) uiColor_ToggleOffText = c end)
    
    -- Background & Window
    createSection(tabFrames.Settings, "Background & Window")
    
    createDropdown(tabFrames.Settings, "Background Image",
        function() return getBackgroundFiles() end,
        function() return uiBackgroundFile == "" and "None" or uiBackgroundFile end,
        function(opt)
            uiBackgroundFile = (opt == "None") and "" or opt
            applyBackground(BackgroundImage)
        end
    )
    
    createSlider(tabFrames.Settings, "Image Opacity:", 0, 100,
        function() return math.floor(uiImageOpacity * 100 + 0.5) end,
        function(v) uiImageOpacity = v / 100; applyBackground(BackgroundImage) end,
        function(v) return v .. "%" end
    )
    
    createSlider(tabFrames.Settings, "Blur:", 0, 24,
        function() return uiBlurSize end,
        function(v) uiBlurSize = v; updateBlur() end,
        function(v) return v .. "px" end
    )
    
    -- Fit Dropdown
    createDropdown(tabFrames.Settings, "Fit:",
        function() return {"Fill", "Fit", "Stretch", "Tile", "Center", "Zoom"} end,
        function() return uiFitMode end,
        function(opt)
            uiFitMode = opt
            applyBackground(BackgroundImage)
        end
    )
    
    createSlider(tabFrames.Settings, "Gui Opacity:", 25, 100,
        function() return math.floor(uiGuiOpacity * 100 + 0.5) end,
        function(v) uiGuiOpacity = v / 100; applyTheme() end,
        function(v) return v .. "%" end
    )
    
    -- Configs
    createSection(tabFrames.Settings, "Configs")
    
    local configNameBox = createTextBox(tabFrames.Settings, "Config name...")
    configNameBox.Size = UDim2.new(1, 0, 0, 30)
    
    -- Configs Dropdown
    local ddContainer = create("Frame", {
        Name = "ConfigDropdown", Parent = tabFrames.Settings,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, BorderSizePixel = 0
    })
    create("UIListLayout", {Parent = ddContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)})
    
    local ddToggleBtn = createContentButton(ddContainer, "Configs (0) — click to open", function() end)
    ddToggleBtn.LayoutOrder = 0
    
    local ddList = create("ScrollingFrame", {
        Name = "ConfigList", Parent = ddContainer, LayoutOrder = 1,
        Size = UDim2.new(1, 0, 0, 130),
        BackgroundColor3 = uiColor_TextBoxColor, BorderColor3 = COL_BORDER, BorderSizePixel = 1,
        ScrollBarThickness = 4, ScrollBarImageColor3 = COL_BORDER,
        CanvasSize = UDim2.new(0, 0, 0, 0), Visible = false
    })
    table.insert(themeElements.TextBoxes, ddList)
    create("UIListLayout", {Parent = ddList, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3)})
    create("UIPadding", {Parent = ddList, PaddingTop = UDim.new(0, 3), PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 3)})
    
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
    
    ddToggleBtn.MouseButton1Click:Connect(function()
        ddOpen = not ddOpen
        if ddOpen then refreshConfigList() else setDDToggleText() end
        ddList.Visible = ddOpen
    end)
    
    createContentButton(tabFrames.Settings, "Save config", function()
        saveNamedConfig(configNameBox.Text)
        refreshConfigList()
    end)
    
    createContentButton(tabFrames.Settings, "Refresh config list", function()
        refreshConfigList()
    end)
    
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
        applyBackground(BackgroundImage)
        updateBlur()
        keyBindBtn.Text = currentToggleKey.Name
        applyTheme()
        notify("Configs", "Settings reset to defaults")
    end)
    
    refreshConfigList()
    switchTab(tabFrames.Main)
    
    --// Toggle Key Handler
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == currentToggleKey and unlocked then
            if isHidden then
                isHidden = false
                FuckYou.Visible = true
                isCollapsed = false
                tweenSize(UDim2.new(0, 940, 0, 510))
            else
                isHidden = true
                tweenSize(UDim2.new(0, 940, 0, 0), function() FuckYou.Visible = false end)
            end
        end
    end)
    
    --// Draggable
    local dragging, dragInput, dragStart, startPosition
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPosition = FuckYou.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            FuckYou.Position = UDim2.new(
                startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
            )
        end
    end)
    
    --// Key System Check
    BtnSubmit.MouseButton1Click:Connect(function()
        local group, daysLeft = checkKeySystem(KeyWindow, KeyTextBox, KeyInfoLabel)
        if group then
            unlocked = true
            KeyWindow:Destroy()
            FuckYou.Visible = true
            updateProfilePanel(group, daysLeft)
            applyBackground(BackgroundImage)
            updateBlur()
            applyTheme()
            
            -- Load last config
            local lastCfgName = getLastConfigName()
            if lastCfgName then
                loadNamedConfig(lastCfgName)
            end
            
            notify("Fuck you! is loaded", "Welcome! Role: " .. group)
        end
    end)
    
    -- Auto check
    task.spawn(function()
        task.wait(1)
        local group, daysLeft = checkKeySystem(KeyWindow, KeyTextBox, KeyInfoLabel)
        if group then
            unlocked = true
            KeyWindow:Destroy()
            FuckYou.Visible = true
            updateProfilePanel(group, daysLeft)
            applyBackground(BackgroundImage)
            updateBlur()
            applyTheme()
            
            local lastCfgName = getLastConfigName()
            if lastCfgName then
                loadNamedConfig(lastCfgName)
            end
            
            notify("Fuck you! is loaded", "Welcome! Role: " .. group)
        end
    end)
end

return Library