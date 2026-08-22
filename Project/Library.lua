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

--// Стили
local COL_BG = Color3.fromRGB(12, 12, 12)
local COL_BORDER = Color3.fromRGB(22, 22, 22)
local COL_TEXT = Color3.fromRGB(139, 135, 127)
local COL_TEXTBOX = Color3.fromRGB(18, 18, 18)
local FONT = Enum.Font.SpecialElite

--// Переменные состояния
local currentToggleKey = Enum.KeyCode.P
local isHidden = false
local isCollapsed = false
local unlocked = false
local cachedKeyResponse = nil

--// Хелперы
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

--// =========================================
--// СИСТЕМА КЛЮЧЕЙ (Key System)
--// =========================================
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

local function getKeyDaysLeft(timeStr)
    if not timeStr or timeStr == "inf" then return "Infinity" end
    local day, month, year = timeStr:match("(%d+)%.(%d+)%.(%d+)")
    if not day then return 0 end
    local expireTime = os.time({day = tonumber(day), month = tonumber(month), year = tonumber(year), hour = 0, min = 0, sec = 0})
    local diff = expireTime - os.time()
    return diff <= 0 and 0 or diff / 86400
end

local function playUnlockJingle()
    pcall(function()
        local s = Instance.new("Sound")
        s.Name = "FuckYouUnlockSound"
        s.SoundId = "rbxassetid://115440201770223"
        s.Volume = 1; s.Looped = false; s.TimePosition = 0
        s.Parent = game:GetService("SoundService")
        s:Play()
        task.delay(3, function() pcall(function() s:Destroy() end) end)
    end)
end

--// =========================================
--// СОЗДАНИЕ GUI (Вызывается после успешного ввода ключа)
--// =========================================
local function createFuckYouGui()
    local ScreenGui = create("ScreenGui", {Name = "FuckYouGui", ResetOnSpawn = false, IgnoreGuiInset = true, Parent = LocalPlayer:WaitForChild("PlayerGui")})
    
    local FuckYou = create("Frame", {
        Name = "FuckYou", Parent = ScreenGui,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 940, 0, 510), ClipsDescendants = true, Visible = true,
        BackgroundColor3 = COL_BG, BorderColor3 = COL_BORDER, BorderSizePixel = 1
    })

    local TopBar = create("Frame", {Name = "TopBar", Parent = FuckYou, Size = UDim2.new(1, 0, 0, 45), BackgroundColor3 = COL_BG, BorderSizePixel = 0})
    local Title = create("TextLabel", {Name = "Name", Parent = TopBar, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "Fuck you! v1.2", TextColor3 = COL_TEXT, TextSize = 13, Font = FONT})

    -- Кнопки управления
    local function makeTopBtn(symbol, offset, colorOverride)
        local b = create("TextButton", {
            Name = symbol, Parent = TopBar,
            Position = UDim2.new(1, -45 * offset, 0, 0), Size = UDim2.new(0, 45, 0, 45),
            BackgroundColor3 = colorOverride or COL_BG, BorderColor3 = COL_BORDER,
            Text = symbol, TextColor3 = colorOverride and Color3.fromRGB(255,255,255) or COL_TEXT, TextSize = 13, Font = FONT
        })
        b.MouseEnter:Connect(function() b.BackgroundColor3 = colorOverride or Color3.fromRGB(30, 30, 30) end)
        b.MouseLeave:Connect(function() b.BackgroundColor3 = colorOverride or COL_BG end)
        return b
    end

    local MinusBtn = makeTopBtn("-", 3)
    local EqualBtn = makeTopBtn("=", 2)
    local XBtn = makeTopBtn("X", 1, Color3.fromRGB(150, 40, 40))

    -- Анимация сворачивания
    local currentTween = nil
    local function tweenSize(target, cb)
        if currentTween then currentTween:Cancel() end
        local tw = TweenService:Create(FuckYou, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = target})
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

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == currentToggleKey and unlocked then
            if isHidden then
                isHidden = false; FuckYou.Visible = true; isCollapsed = false
                tweenSize(UDim2.new(0, 940, 0, 510))
            else
                isHidden = true
                tweenSize(UDim2.new(0, 940, 0, 0), function() FuckYou.Visible = false end)
            end
        end
    end)

    -- Боковая панель и Контент
    local SideBard = create("Frame", {Name = "SideBard", Parent = FuckYou, Position = UDim2.new(0, 0, 0, 45), Size = UDim2.new(0, 65, 1, -45), BackgroundColor3 = COL_BG, BorderSizePixel = 0})
    local UiBtn = create("TextButton", {Name = "Ui", Parent = SideBard, Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 0, 59), BackgroundColor3 = COL_BG, BorderColor3 = COL_BORDER, Text = "Ui", TextColor3 = COL_TEXT, TextSize = 12, Font = FONT})

    local MenuInsided = create("ScrollingFrame", {Name = "MenuInsided", Parent = FuckYou, Position = UDim2.new(0, 65, 0, 45), Size = UDim2.new(0, 105, 1, -45), BackgroundColor3 = COL_BG, BorderSizePixel = 0, ScrollBarThickness = 3, Visible = false})
    create("UIListLayout", {Parent = MenuInsided, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)})

    local Containment = create("Frame", {Name = "Containment", Parent = FuckYou, Position = UDim2.new(0, 170, 0, 45), Size = UDim2.new(1, -170, 1, -45), BackgroundTransparency = 1, BorderSizePixel = 0})

    local function createTabFrame(name)
        local sf = create("ScrollingFrame", {Name = name, Parent = Containment, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, ScrollBarThickness = 4})
        local tl = create("UIListLayout", {Parent = sf, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
        create("UIPadding", {Parent = sf, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10)})
        tl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            sf.CanvasSize = UDim2.new(0, 0, 0, tl.AbsoluteContentSize.Y + 20)
        end)
        return sf
    end

    local tabFrames = {
        Main = createTabFrame("TabMain"),
        Settings = createTabFrame("TabSettings")
    }

    local function switchTab(targetTab)
        for _, tab in pairs(tabFrames) do tab.Visible = (tab == targetTab) end
    end

    local function addMenuButton(text, targetTab)
        local btn = create("TextButton", {Parent = MenuInsided, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = COL_BG, BorderColor3 = COL_BORDER, TextColor3 = COL_TEXT, Text = text, Font = FONT, TextSize = 12})
        btn.MouseButton1Click:Connect(function() switchTab(targetTab) end)
    end

    addMenuButton("Main info", tabFrames.Main)
    addMenuButton("Settings", tabFrames.Settings)

    UiBtn.MouseButton1Click:Connect(function()
        MenuInsided.Visible = not MenuInsided.Visible
        if MenuInsided.Visible then switchTab(tabFrames.Main) end
    end)

    --// Наполнение Main Info
    local function createSection(parent, text)
        return create("TextLabel", {Parent = parent, Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = text, TextColor3 = COL_TEXT, TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left})
    end
    local function createButton(parent, text, cb)
        local btn = create("TextButton", {Parent = parent, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = COL_BG, BorderColor3 = COL_BORDER, TextColor3 = COL_TEXT, Text = text, Font = FONT, TextSize = 13})
        btn.MouseButton1Click:Connect(cb)
        return btn
    end

    createSection(tabFrames.Main, "In case something happens here's a discord server")
    createButton(tabFrames.Main, "Click to copy Discord Server link", function()
        if setclipboard then setclipboard("https://discord.gg/75Dz8T9hHR") end
        notify("Discord", "The link is copied")
    end)
    createSection(tabFrames.Main, "* Credits to *")
    createSection(tabFrames.Main, "WdymGaming (wdymgaming) -> coder")
    createSection(tabFrames.Main, "pashajokot (swatwincky) -> tester")
    createSection(tabFrames.Main, "BombalMac (bombapc) -> tester")

    --// Наполнение Settings
    createSection(tabFrames.Settings, "UI Customization")
    
    local keyBindBtn = createButton(tabFrames.Settings, "Menu Toggle Key: [" .. currentToggleKey.Name .. "]", function()
        keyBindBtn.Text = "...Press any Key..."
        local conn
        conn = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                currentToggleKey = input.KeyCode
                keyBindBtn.Text = "Menu Toggle Key: [" .. currentToggleKey.Name .. "]"
                conn:Disconnect()
            end
        end)
    end)

    createSection(tabFrames.Settings, "Background & Window")
    createSection(tabFrames.Settings, "(Здесь будут слайдеры и дропдауны для фона, блюра и прозрачности)")
    
    createSection(tabFrames.Settings, "Configs")
    createButton(tabFrames.Settings, "Save config", function() notify("Configs", "Saved!") end)
    createButton(tabFrames.Settings, "Reset defaults", function() notify("Configs", "Reset!") end)

    -- Перетаскивание окна
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

    switchTab(tabFrames.Main)
end

--// =========================================
--// ОКНО ВВОДА КЛЮЧА (KeyWindow)
--// =========================================
local function createKeyWindow()
    local ScreenGui = game:GetService("CoreGui"):FindFirstChild("FuckYouGui") or create("ScreenGui", {Name = "FuckYouGui", ResetOnSpawn = false, IgnoreGuiInset = true, Parent = LocalPlayer:WaitForChild("PlayerGui")})
    
    local KeyWindow = create("Frame", {Name = "KeyWindow", Parent = ScreenGui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 450, 0, 310), BackgroundColor3 = COL_BG, BorderColor3 = COL_BORDER})
    local KeyTopBar = create("Frame", {Parent = KeyWindow, Size = UDim2.new(1, 0, 0, 35), BackgroundColor3 = COL_BG, BorderSizePixel = 0})
    create("TextLabel", {Parent = KeyTopBar, Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = "Fuck you! — Key System", TextColor3 = COL_TEXT, TextSize = 15, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left})
    
    local KeyCloseBtn = create("TextButton", {Parent = KeyTopBar, Size = UDim2.new(0, 35, 0, 35), Position = UDim2.new(1, -35, 0, 0), BackgroundColor3 = Color3.fromRGB(120, 40, 40), TextColor3 = Color3.fromRGB(255, 255, 255), Text = "X", TextSize = 13, Font = FONT})
    KeyCloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    local KeyInfoLabel = create("TextLabel", {Parent = KeyWindow, Size = UDim2.new(1, -30, 0, 40), Position = UDim2.new(0, 15, 0, 50), BackgroundTransparency = 1, Text = "Please enter your access key below.\nKey can be obtained via Discord.", TextColor3 = COL_TEXT, TextSize = 13, Font = FONT, TextWrapped = true})
    
    create("TextButton", {Parent = KeyWindow, Size = UDim2.new(1, -40, 0, 36), Position = UDim2.new(0, 20, 0, 105), BackgroundColor3 = COL_BG, BorderColor3 = COL_BORDER, TextColor3 = COL_TEXT, Text = "Click to copy Discord Server link", Font = FONT, TextSize = 13}).MouseButton1Click:Connect(function()
        if setclipboard then setclipboard("https://discord.gg/75Dz8T9hHR") end
        notify("Discord", "The link is copied")
    end)

    local KeyTextBox = create("TextBox", {Parent = KeyWindow, Size = UDim2.new(1, -40, 0, 36), Position = UDim2.new(0, 20, 0, 160), BackgroundColor3 = COL_TEXTBOX, BorderColor3 = COL_BORDER, TextColor3 = COL_TEXT, PlaceholderColor3 = Color3.fromRGB(90, 90, 90), PlaceholderText = "Enter key here...", Text = "", TextSize = 13, Font = FONT, ClearTextOnFocus = false})

    local function unlockScript(userGroup)
        unlocked = true
        playUnlockJingle()
        KeyWindow:Destroy()
        createFuckYouGui()
        notify("Fuck you! is loaded", "Welcome! Role: " .. (userGroup or "User"))
    end

    local function checkKeySystem()
        if not cachedKeyResponse then
            local success, response = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/MamaSdoxla/EmilyUi/refs/heads/main/nuh-uh.json") end)
            if not success then KeyInfoLabel.Text = "Error: Failed to fetch database!"; return end
            local ok, decryptedText = pcall(function() return xor_decrypt(base64_decode(response), SECRET_KEY) end)
            if not ok then KeyInfoLabel.Text = "Error: Failed to decrypt!"; return end
            cachedKeyResponse = decryptedText
        end
        
        local jsonSuccess, keysList = pcall(function() return HttpService:JSONDecode(cachedKeyResponse) end)
        if not jsonSuccess then KeyInfoLabel.Text = "Error: Database parsing failed!"; return end
        
        local myName = string.lower(LocalPlayer.Name)
        for _, data in ipairs(keysList) do
            if data.key and data.robloxName and data.group and data.timeTillWorks then
                local nameMatch = (data.robloxName == "none") or (string.lower(data.robloxName) == myName)
                local groupAllowed = string.lower(data.group) == "free" or string.lower(data.group) == "user" or string.lower(data.group) == "tester" or string.lower(data.group) == "coder"
                if nameMatch and groupAllowed then
                    local daysLeft = getKeyDaysLeft(data.timeTillWorks)
                    if daysLeft == "Infinity" or (type(daysLeft) == "number" and daysLeft > 0) then
                        if data.key == "none" or (KeyTextBox.Text == data.key) then
                            unlockScript(data.group)
                            return
                        end
                    end
                end
            end
        end
        KeyInfoLabel.Text = "Enter key please! You can ask for a key in discord."
    end

    create("TextButton", {Parent = KeyWindow, Size = UDim2.new(0, 150, 0, 36), Position = UDim2.new(0.5, -75, 0, 240), BackgroundColor3 = Color3.fromRGB(40, 90, 40), BorderColor3 = COL_BORDER, TextColor3 = Color3.fromRGB(255, 255, 255), Text = "Check Key", Font = FONT, TextSize = 13}).MouseButton1Click:Connect(checkKeySystem)
    
    task.spawn(checkKeySystem)
end

--// =========================================
--// ТОЧКА ВХОДА (Init)
--// =========================================
function Library:Init()
    -- При запуске сразу создаем окно ввода ключа
    createKeyWindow()
end

return Library