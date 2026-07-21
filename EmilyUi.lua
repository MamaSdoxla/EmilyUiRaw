-- Сервисы
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- Настройки по умолчанию
local currentToggleKey = Enum.KeyCode.P
local uiColor_MainWindow = Color3.fromRGB(30, 30, 30)
local uiColor_TopBar = Color3.fromRGB(40, 40, 40)
local uiColor_SideBar = Color3.fromRGB(25, 25, 25)
local uiColor_TextColor = Color3.fromRGB(230, 230, 230)
local uiColor_ButtonColor = Color3.fromRGB(45, 45, 45)
local uiColor_TextBoxColor = Color3.fromRGB(45, 45, 45)

local cachedKeyResponse = nil -- Кэш для HTTP-запроса

-- Данные текущего ключа для плашки профиля
local currentKeyData = {
    group = "Free",
    daysLeft = "Infinity"
}

-- Уведомление
StarterGui:SetCore("SendNotification", {
   Title = "EmilyUi is loading!",
   Text = "To get key goto discord or ask for a permanent one.",
   Duration = 10
})

-- Функция для быстрого создания объектов
local function create(className, properties)
    local instance = Instance.new(className)
    for k, v in pairs(properties) do
        instance[k] = v
    end
    return instance
end

-- Создаем экран
local MyGui = create("ScreenGui", {Name = "MyGuiByWdymGaming", ResetOnSpawn = false, Parent = LocalPlayer:WaitForChild("PlayerGui")})

-- Списки для динамической смены темы
local themeElements = { 
    MainWindow = {}, 
    TopBars = {}, 
    SideBars = {},
    Texts = {},
    Buttons = {},
    TextBoxes = {}
}

-- Глобальная ссылка на вкладки для функции switchTab
local tabs = {}

-- ==========================================
-- СИСТЕМА КОНФИГОВ (JSON)
-- ==========================================
local configPath = "EmilyUi/Config.json"

local function saveConfig()
    local config = {
        ToggleKey = currentToggleKey.Name,
        MainWindowColor = {uiColor_MainWindow.R, uiColor_MainWindow.G, uiColor_MainWindow.B},
        TopBarColor = {uiColor_TopBar.R, uiColor_TopBar.G, uiColor_TopBar.B},
        SideBarColor = {uiColor_SideBar.R, uiColor_SideBar.G, uiColor_SideBar.B},
        TextColor = {uiColor_TextColor.R, uiColor_TextColor.G, uiColor_TextColor.B},
        ButtonColor = {uiColor_ButtonColor.R, uiColor_ButtonColor.G, uiColor_ButtonColor.B},
        TextBoxColor = {uiColor_TextBoxColor.R, uiColor_TextBoxColor.G, uiColor_TextBoxColor.B}
    }
    
    local success, json = pcall(function() return HttpService:JSONEncode(config) end)
    if success then
        if makefolder then pcall(function() makefolder("EmilyUi") end) end
        if writefile then pcall(function() writefile(configPath, json) end) end
    end
end

-- Функция обновления цветов вкладок на лету при изменении темы
local function updateTabButtonsTheme()
    for _, tab in ipairs(tabs) do
        if tab.Button then
            local isTarget = tab.Frame.Visible
            if isTarget then
                tab.Button.BackgroundColor3 = uiColor_ButtonColor
                tab.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                -- Делаем неактивную вкладку чуть темнее выбранного цвета кнопок
                local r = math.max((uiColor_ButtonColor.R * 255) - 10, 0)
                local g = math.max((uiColor_ButtonColor.G * 255) - 10, 0)
                local b = math.max((uiColor_ButtonColor.B * 255) - 10, 0)
                tab.Button.BackgroundColor3 = Color3.fromRGB(r, g, b)
                tab.Button.TextColor3 = Color3.fromRGB(180, 180, 180)
            end
        end
    end
end

local function loadConfig()
    if isfile and isfile(configPath) and readfile then
        local success, json = pcall(function() return readfile(configPath) end)
        if success and json then
            local decodedSuccess, config = pcall(function() return HttpService:JSONDecode(json) end)
            if decodedSuccess and config then
                if config.ToggleKey then currentToggleKey = Enum.KeyCode[config.ToggleKey] end
                if config.MainWindowColor then uiColor_MainWindow = Color3.new(unpack(config.MainWindowColor)) end
                if config.TopBarColor then uiColor_TopBar = Color3.new(unpack(config.TopBarColor)) end
                if config.SideBarColor then uiColor_SideBar = Color3.new(unpack(config.SideBarColor)) end
                if config.TextColor then uiColor_TextColor = Color3.new(unpack(config.TextColor)) end
                if config.ButtonColor then uiColor_ButtonColor = Color3.new(unpack(config.ButtonColor)) end
                if config.TextBoxColor then uiColor_TextBoxColor = Color3.new(unpack(config.TextBoxColor)) end
            end
        end
    end
end

-- Загружаем конфиг до создания UI элементов
loadConfig()

-- ==========================================
-- ОСНОВНОЕ МЕНЮ
-- ==========================================
local MainWindow = create("Frame", {Name = "MainWindow", Parent = MyGui, Size = UDim2.new(0, 900, 0, 700), Position = UDim2.new(0.5, -450, 0.4, -150), BackgroundColor3 = uiColor_MainWindow, BorderSizePixel = 0, Visible = false})
table.insert(themeElements.MainWindow, MainWindow)

local TopBar = create("Frame", {Name = "TopBar", Parent = MainWindow, Size = UDim2.new(1, 0, 0, 35), BackgroundColor3 = uiColor_TopBar, BorderSizePixel = 0})
table.insert(themeElements.TopBars, TopBar)

local MainTitle = create("TextLabel", {Name = "Title", Parent = TopBar, Size = UDim2.new(1, -85, 1, 0), Position = UDim2.new(0, 15, 0, 0), BackgroundTransparency = 1, Text = "EmilyUi v1.1", TextColor3 = uiColor_TextColor, TextSize = 24, Font = Enum.Font.SourceSansSemibold, TextXAlignment = Enum.TextXAlignment.Left})
table.insert(themeElements.Texts, MainTitle)

-- Сайдбар изменен: высота уменьшена на 115 (35 топбар + 80 плашка), чтобы оставить место снизу под профиль
local SideBar = create("Frame", {Name = "SideBar", Parent = MainWindow, Size = UDim2.new(0, 180, 1, -115), Position = UDim2.new(0, 0, 0, 35), BackgroundColor3 = uiColor_SideBar, BorderSizePixel = 0})
table.insert(themeElements.SideBars, SideBar)

create("UIListLayout", {Parent = SideBar, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)})
create("UIPadding", {Parent = SideBar, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)})

local ContentFrame = create("Frame", {Name = "ContentFrame", Parent = MainWindow, Size = UDim2.new(1, -180, 1, -35), Position = UDim2.new(0, 180, 0, 35), BackgroundTransparency = 1, BorderSizePixel = 0})

-- ==========================================
-- ПЛАШКА ИНФОРМАЦИИ О ИГРОКЕ
-- ==========================================
local UserProfilePanel = create("Frame", {Name = "UserProfilePanel", Parent = MainWindow, Size = UDim2.new(0, 180, 0, 80), Position = UDim2.new(0, 0, 1, -80), BackgroundColor3 = uiColor_SideBar, BorderSizePixel = 0})
table.insert(themeElements.SideBars, UserProfilePanel)

-- Разделительная линия сверху плашки
create("Frame", {Parent = UserProfilePanel, Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = Color3.fromRGB(45, 45, 45), BorderSizePixel = 0})

-- Аватар игрока
local UserImage = create("ImageLabel", {Parent = UserProfilePanel, Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(0, 10, 0, 15), BackgroundTransparency = 1, Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"})
create("UICorner", {Parent = UserImage, CornerRadius = UDim.new(1, 0)}) -- Круглая аватарка

-- Никнейм
local UserNameLabel = create("TextLabel", {Parent = UserProfilePanel, Size = UDim2.new(1, -75, 0, 20), Position = UDim2.new(0, 68, 0, 12), BackgroundTransparency = 1, Text = LocalPlayer.DisplayName, TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 16, Font = Enum.Font.SourceSansBold, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd})

-- Срок действия ключа
local UserKeyTimeLabel = create("TextLabel", {Parent = UserProfilePanel, Size = UDim2.new(1, -75, 0, 15), Position = UDim2.new(0, 68, 0, 32), BackgroundTransparency = 1, Text = "Days left: Inf", TextColor3 = Color3.fromRGB(180, 180, 180), TextSize = 16, Font = Enum.Font.SourceSans, TextXAlignment = Enum.TextXAlignment.Left})

-- Группа ключа
local UserGroupLabel = create("TextLabel", {Parent = UserProfilePanel, Size = UDim2.new(1, -75, 0, 15), Position = UDim2.new(0, 68, 0, 47), BackgroundTransparency = 1, Text = "Group: Free", TextColor3 = Color3.fromRGB(150, 150, 150), TextSize = 16, Font = Enum.Font.SourceSansSemibold, TextXAlignment = Enum.TextXAlignment.Left})

-- Логика переливающихся цветов (Радуга на основе фазы/цветового тона)
RunService.RenderStepped:Connect(function()
    if not MainWindow.Visible then return end
    
    local group = currentKeyData.group or "Free"
    local speed = 5 -- Скорость изменения цвета (чем выше, тем быстрее)
    local wave = math.sin(tick() * speed) -- Плавная волна от -1 до 1
    
    if group == "Free" then
        UserGroupLabel.TextColor3 = Color3.fromRGB(150, 150, 150) -- Серый
    elseif group == "User" then
        -- Плавный зеленый (колеблется в зеленых оттенках)
        local hue = 0.3 + (wave * 0.05) -- Диапазон примерно от 0.25 до 0.35
        UserGroupLabel.TextColor3 = Color3.fromHSV(hue, 0.85, 0.95)
    elseif group == "Tester" then
        -- Плавный синий (колеблется в синих оттенках)
        local hue = 0.6 + (wave * 0.05) -- Диапазон примерно от 0.55 до 0.65
        UserGroupLabel.TextColor3 = Color3.fromHSV(hue, 0.85, 0.95)
    elseif group == "Coder" then
        -- Плавный розовый (колеблется в розовых/маджента оттенках)
        local hue = 0.88 + (wave * 0.04) -- Диапазон примерно от 0.84 до 0.92
        UserGroupLabel.TextColor3 = Color3.fromHSV(hue, 0.85, 0.95)
    else
        UserGroupLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end)

-- Функция обновления данных в плашке
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

-- Хелпер вкладок
local function createTabContentFrame(name)
    local sf = create("ScrollingFrame", {Name = name, Parent = ContentFrame, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6, CanvasSize = UDim2.new(0, 0, 0, 0), Visible = false})
    local tl = create("UIListLayout", {Parent = sf, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)})
    create("UIPadding", {Parent = sf, PaddingTop = UDim.new(0, 15), PaddingLeft = UDim.new(0, 15), PaddingRight = UDim.new(0, 15)})
    
    tl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sf.CanvasSize = UDim2.new(0, 0, 0, tl.AbsoluteContentSize.Y + 30)
    end)
    return sf
end

-- Инициализация вкладок через словарь
local tabFrames = {
    Main = createTabContentFrame("TabMain"),
    Universal = createTabContentFrame("TabUniversal"),
    Games = createTabContentFrame("TabGames"),
    Scripts = createTabContentFrame("TabScripts"),
    Hubs = createTabContentFrame("TabScriptHubs"),
    Guis = createTabContentFrame("TabGuis"),
    Anims = createTabContentFrame("TabAnimations"),
    Settings = createTabContentFrame("TabSettings")
}
tabFrames.Main.Visible = true

-- ==========================================
-- ХЕЛПЕРЫ ЭЛЕМЕНТОВ
-- ==========================================
local function createSection(parent, text)
    local lbl = create("TextLabel", {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Text = text, TextColor3 = uiColor_TextColor, TextSize = 16, Font = Enum.Font.SourceSansBold, TextXAlignment = Enum.TextXAlignment.Center, Parent = parent})
    table.insert(themeElements.Texts, lbl)
    return lbl
end

local function createLabel(parent, text)
    local lbl = create("TextLabel", {Size = UDim2.new(1, 0, 0, 25), BackgroundTransparency = 1, Text = text, TextColor3 = uiColor_TextColor, TextSize = 16, Font = Enum.Font.SourceSansItalic, TextXAlignment = Enum.TextXAlignment.Left, Parent = parent})
    table.insert(themeElements.Texts, lbl)
    return lbl
end

local function createContentButton(parent, text, callback, customColor)
    local defaultColor = customColor or uiColor_ButtonColor
    local btn = create("TextButton", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = defaultColor, TextColor3 = uiColor_TextColor, Text = text, Font = Enum.Font.SourceSans, TextSize = 16, BorderSizePixel = 0, Parent = parent})
    
    if not customColor then
        table.insert(themeElements.Buttons, btn)
    end
    table.insert(themeElements.Texts, btn)
    
    local function updateHover()
        local c = btn.BackgroundColor3
        local r, g, b = c.R * 255, c.G * 255, c.B * 255
        return Color3.fromRGB(math.min(r + 10, 255), math.min(g + 10, 255), math.min(b + 10, 255))
    end
    
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = updateHover() end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = customColor or uiColor_ButtonColor end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function createTextBox(parent, placeholder, font)
    local box = create("TextBox", {BackgroundColor3 = uiColor_TextBoxColor, TextColor3 = uiColor_TextColor, PlaceholderColor3 = Color3.fromRGB(120, 120, 120), PlaceholderText = placeholder, Text = "", TextSize = 16, Font = font or Enum.Font.SourceSans, BorderSizePixel = 0, Parent = parent, ClearTextOnFocus = false})
    table.insert(themeElements.Texts, box)
    table.insert(themeElements.TextBoxes, box)
    return box
end

-- Функция копирования Дискорда
local function copyDiscord()
    setclipboard("https://discord.gg/75Dz8T9hHR")
    StarterGui:SetCore("SendNotification", {Title = "EmilyUi discord", Text = "The link is copied", Duration = 6.5})
end

-- ==========================================
-- ДИНАМИЧЕСКОЕ НАПОЛНЕНИЕ ИНТЕРФЕЙСА
-- ==========================================
local uiStructure = {
    { tab = tabFrames.Main, type = "section", text = "In case something happens here's a discord server" },
    { tab = tabFrames.Main, type = "button", text = "Click to copy Discord Server link", cb = copyDiscord },
    { tab = tabFrames.Main, type = "section", text = "* Credits to *" },
    { tab = tabFrames.Main, type = "section", text = "RobloxId (DiscordUsername) -> role" },
    { tab = tabFrames.Main, type = "section", text = "WdymGaming (wdymgaming) -> coder" },
    { tab = tabFrames.Main, type = "section", text = "pashajokot (swatwincky) -> tester" },

    { tab = tabFrames.Universal, type = "section", text = "Admin Commands" },
    { tab = tabFrames.Universal, type = "button", text = "Infinite Yield", cb = function() loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))() end },
    { tab = tabFrames.Universal, type = "button", text = "FE Admin Commands", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/lxte/cmd/main/main.lua"))() end },


    { tab = tabFrames.Universal, type = "section", text = "For exploiting" },
    { tab = tabFrames.Universal, type = "button", text = "Dex Explorer++", cb = function() loadstring(game:HttpGet("https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua"))() end },
    { tab = tabFrames.Universal, type = "button", text = "Rem v1.2", cb = function() loadstring(game:HttpGet("https://e-vil.com/anbu/rem.lua"))() end },
    { tab = tabFrames.Universal, type = "button", text = "Cobalt", cb = function() loadstring(game:HttpGet("https://github.com/notpoiu/cobalt/releases/latest/download/Cobalt.luau"))() end },
    { tab = tabFrames.Universal, type = "button", text = "VEX (better DEX)", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Vezise/2026/main/Vez/VexExplorer/VEXExplorer.lua"))() end },
    { tab = tabFrames.Universal, type = "button", text = "Executor Tester | v2.6", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/GmilerlolYT/ExecutorTester/refs/heads/main/Hi"))() end },

    { tab = tabFrames.Universal, type = "section", text = "Click TP" },

    { tab = tabFrames.Games, type = "section", text = "Game Scripts" },
    { tab = tabFrames.Games, type = "label", text = "BackDoor (?)" },
    { tab = tabFrames.Games, type = "button", text = "Backdoor v3.2.6", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Pack-a-PunchSCRIPTS/Backdoor-v3/refs/heads/main/Backdoor%20v3-obfuscated.lua"))() end },
    { tab = tabFrames.Games, type = "label", text = "Murder vs Sherif 2" },
    { tab = tabFrames.Games, type = "button", text = "Polo MVS", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/polo242c/mvs/main/mvs"))() end },
    { tab = tabFrames.Games, type = "button", text = "CyberCoders", cb = function() loadstring(game:HttpGet("https://rawscripts.net/raw/Murderers-VS-Sheriffs-DUELS-CyberCoders-Menu-II-193913"))() end },
    { tab = tabFrames.Games, type = "label", text = "Catalog Avatar Creator" },
    { tab = tabFrames.Games, type = "button", text = "Avatar stealer", cb = function() loadstring(game:HttpGet("https://pastefy.app/xWdIDQJd/raw"))() end },
    { tab = tabFrames.Games, type = "label", text = "Murder Mystery 2" },
    { tab = tabFrames.Games, type = "button", text = "VisionHub", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/orialdev/VisionHub/refs/heads/main/main.lua"))() end },
    { tab = tabFrames.Games, type = "button", text = "AutoFarm (40coins/4,5min)", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/tsBelrux/mm2/refs/heads/main/keyless.lua"))() end },
    
    { tab = tabFrames.Scripts, type = "section", text = "Fun Scripts" },
    { tab = tabFrames.Scripts, type = "button", text = "Ball R6/R15", cb = function() loadstring(game:HttpGet("https://pastebin.com/raw/BZr9bGDy", true))() end },

    { tab = tabFrames.Scripts, type = "section", text = "Scripts made by WdymGaming"},
    { tab = tabFrames.Scripts, type = "button", text = "Wdymgaming's Music Gui (client)", cb = function() loadstring(game:HttpGet("https://pastebin.com/raw/RBVQFbqH", true))() end },
    { tab = tabFrames.Scripts, type = "button", text = "R6/R15 Animator by WdymGaming", cb = function() loadstring(game:HttpGet("https://pastebin.com/raw/P9hSFKpA"))() end },

    { tab = tabFrames.Hubs, type = "section", text = "Script hubs" },
    { tab = tabFrames.Hubs, type = "button", text = "Axe Hub for Natural Disaster Survival", cb = function() loadstring(game:HttpGet('https://raw.githubusercontent.com/zeroidxx/axe-hub/refs/heads/main/axehub%20nds.txt'))() end },
    { tab = tabFrames.Hubs, type = "button", text = "FE Trolling GUI", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/yofriendfromschool1/Sky-Hub/main/FE%20Trolling%20GUI.luau"))() end },
    { tab = tabFrames.Hubs, type = "button", text = "Wisl Universal", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/WislUniversal/script/refs/heads/main/Universal.lua", true))() end },
    { tab = tabFrames.Hubs, type = "button", text = "Ultimate Trolling Gui V5", cb = function() loadstring(game:HttpGet("https://pastefy.app/rmdi1m55/raw"))() end },
    { tab = tabFrames.Hubs, type = "button", text = "Yameme Hub", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/MBHubRoblox/YamemeHub/refs/heads/main/selllemons.lua"))() end },
    { tab = tabFrames.Hubs, type = "button", text = "Slicer FE V6", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Ahma174/Slicer/refs/heads/main/Slicer%20Fe%20V6"))() end },

    { tab = tabFrames.Guis, type = "section", text = "Guis" },
    { tab = tabFrames.Guis, type = "button", text = "Super ring v6", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/chesslovers69/Super-ring-parts-v6/refs/heads/main/Bylukaslol"))() end },
    { tab = tabFrames.Guis, type = "button", text = "Touch Fling", cb = function() loadstring(game:HttpGet(('https://raw.githubusercontent.com/0Ben1/fe/main/obf_rf6iQURzu1fqrytcnLBAvW34C9N55kS9g9G3CKz086rC47M6632sEd4ZZYB0AYgV.lua.txt'),true))() end },
    { tab = tabFrames.Guis, type = "button", text = "R6 Crashout GUN", cb = function() loadstring(game:HttpGet('https://pastebin.com/raw/k4dFFDfw'))() end },
    { tab = tabFrames.Guis, type = "button", text = "DEV Hud", cb = function() loadstring(game:HttpGet("https://robloxscripts.com/raw/claude-opus-48-dev-hud-v3-script"))() end },
    { tab = tabFrames.Guis, type = "button", text = "Urban1's universal stuffs", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/pwnmaster99/Scripts/refs/heads/main/US"))() end },
    { tab = tabFrames.Guis, type = "button", text = "R15 Drop kick", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/gsm231/Fe-DropKick/refs/heads/main/V0.1"))() end },

    { tab = tabFrames.Anims, type = "section", text = "Animations client" },
    { tab = tabFrames.Anims, type = "button", text = "R6 Insanity (client)", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/retpirato/Roblox-Scripts/refs/heads/master/Insanity%20Powers.lua"))() end },

    { tab = tabFrames.Anims, type = "section", text = "Animations guis" },
    { tab = tabFrames.Anims, type = "button", text = "R6 Animations", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Eazvy/public-scripts/main/Universal_Animations_Emotes.lua"))() end },
    { tab = tabFrames.Anims, type = "button", text = "AquaMatrix", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/ExploitFin/AquaMatrix/refs/heads/AquaMatrix/AquaMatrix"))() end },
    { tab = tabFrames.Anims, type = "button", text = "R15 Animations", cb = function() loadstring(game:HttpGet("https://kbauu.neocities.org/animation-hub"))() end },
    { tab = tabFrames.Anims, type = "button", text = "Uhhhhhh Reanimator (R6)", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/STEVE-916-create/Uhhhhhh/main/source/reanim.lua"))() end },

    { tab = tabFrames.Anims, type = "section", text = "Animation exploits" },
    { tab = tabFrames.Anims, type = "button", text = "R6 Upsidedown (multiple times = glitch)", cb = function() loadstring(game:HttpGet("https://pastebin.com/raw/RJVv7H3K"))() end },
    { tab = tabFrames.Anims, type = "button", text = "R6/R15 Ball", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/KaterHub-Inc/scripts/refs/heads/maind/unofficial-Projects/FEHamsterBall.lua"))() end },

    { tab = tabFrames.Anims, type = "section", text = "Animations S3X" },
    { tab = tabFrames.Anims, type = "button", text = "R6 S3X animations", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/3LD4D0/FE-TROLLING-PLAYER-R6-R15/6eff8792afed57458d5114478b453a6f6bce5799/Fe%20trolling%20Player%20R6%20AND%20R15"))() end },
    { tab = tabFrames.Anims, type = "button", text = "R6 S3X animations 2", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/ShutUpJamesTheLoserAlt/fes/refs/heads/main/e"))() end},
    { tab = tabFrames.Anims, type = "button", text = "R6 S3X animations 3", cb = function() loadstring(game:HttpGet("https://pastebin.com/raw/gdQ4mVEy"))() end },
    { tab = tabFrames.Anims, type = "button", text = "Jerk off tool r6", cb = function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-FE-Jerk-off-240507"))() end },
}

for _, item in ipairs(uiStructure) do
    if item.type == "section" then createSection(item.tab, item.text)
    elseif item.type == "label" then createLabel(item.tab, item.text)
    elseif item.type == "button" then createContentButton(item.tab, item.text, item.cb) end
end

-- Click TP
local clickTpActive = false
createContentButton(tabFrames.Universal, "Click TP", function()
    if clickTpActive then return end
    clickTpActive = true
    local Mouse = LocalPlayer:GetMouse()
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.UserInputType == Enum.UserInputType.MouseButton1 and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then 
                LocalPlayer.Character:MoveTo(Mouse.Hit.Position) 
            end
        end
    end)
end)

-- ==========================================
-- НАСТРОЙКИ (Settings)
-- ==========================================
createSection(tabFrames.Settings, "UI Customization")

local function createSettingsInput(parent, labelText, placeholder, callback)
    local container = create("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = parent})
    local label = create("TextLabel", {Size = UDim2.new(0.4, 0, 1, 0), BackgroundTransparency = 1, Text = labelText, TextColor3 = uiColor_TextColor, TextSize = 16, Font = Enum.Font.SourceSans, TextXAlignment = Enum.TextXAlignment.Left, Parent = container})
    table.insert(themeElements.Texts, label)
    
    local box = createTextBox(container, placeholder, Enum.Font.Code)
    box.Size = UDim2.new(0.55, 0, 0.8, 0)
    box.Position = UDim2.new(0.45, 0, 0.1, 0)
    box.TextSize = 14
    
    box.FocusLost:Connect(function(enterPressed)
        if enterPressed or box.Text ~= "" then callback(box.Text, box) end
    end)
    return container
end

local function parseRGB(str)
    local r, g, b = string.match(str, "(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
    return r and Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b)) or nil
end

-- Бинд кнопки
local keyBindContainer = create("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = tabFrames.Settings})
local bindLabel = create("TextLabel", {Size = UDim2.new(0.4, 0, 1, 0), BackgroundTransparency = 1, Text = "Menu Toggle Key:", TextColor3 = uiColor_TextColor, TextSize = 16, Font = Enum.Font.SourceSans, TextXAlignment = Enum.TextXAlignment.Left, Parent = keyBindContainer})
table.insert(themeElements.Texts, bindLabel)

local keyBindBtn = createContentButton(keyBindContainer, currentToggleKey.Name, function() end)
keyBindBtn.Size = UDim2.new(0.55, 0, 0.8, 0)
keyBindBtn.Position = UDim2.new(0.45, 0, 0.1, 0)
keyBindBtn.TextSize = 14

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

-- Форматирование цвета для плейсхолдеров
local function formatColor(c)
    return math.floor(c.R*255)..", "..math.floor(c.G*255)..", "..math.floor(c.B*255)
end

-- Список настроек цветов
local colorSettings = {
    {"Main Window Color:", formatColor(uiColor_MainWindow), function(color)
        uiColor_MainWindow = color
        for _, el in ipairs(themeElements.MainWindow) do el.BackgroundColor3 = color end
    end},
    {"Top Bar Color:", formatColor(uiColor_TopBar), function(color)
        uiColor_TopBar = color
        for _, el in ipairs(themeElements.TopBars) do el.BackgroundColor3 = color end
    end},
    {"Side Bar Color:", formatColor(uiColor_SideBar), function(color)
        uiColor_SideBar = color
        for _, el in ipairs(themeElements.SideBars) do el.BackgroundColor3 = color end
    end},
    {"Text Color:", formatColor(uiColor_TextColor), function(color)
        uiColor_TextColor = color
        for _, el in ipairs(themeElements.Texts) do el.TextColor3 = color end
    end},
    {"Button Color:", formatColor(uiColor_ButtonColor), function(color)
        uiColor_ButtonColor = color
        for _, el in ipairs(themeElements.Buttons) do el.BackgroundColor3 = color end
        updateTabButtonsTheme() -- Синхронизируем тему вкладок
    end},
    {"TextBox Background Color:", formatColor(uiColor_TextBoxColor), function(color)
        uiColor_TextBoxColor = color
        for _, el in ipairs(themeElements.TextBoxes) do el.BackgroundColor3 = color end
    end}
}

for _, cfg in ipairs(colorSettings) do
    createSettingsInput(tabFrames.Settings, cfg[1], cfg[2], function(text, box)
        local color = parseRGB(text)
        if color then
            cfg[3](color)
            saveConfig()
        else
            box.Text = "Invalid format!"
        end
    end)
end

-- ==========================================
-- ЛОГИКА ВКЛАДОК И НАВИГАЦИИ
-- ==========================================
tabs = {
    {Frame = tabFrames.Main, Name = "Main Info"},
    {Frame = tabFrames.Universal, Name = "Universal"},
    {Frame = tabFrames.Games, Name = "Games"},
    {Frame = tabFrames.Scripts, Name = "Scripts"},
    {Frame = tabFrames.Hubs, Name = "Script Hubs"},
    {Frame = tabFrames.Guis, Name = "GUIs"},
    {Frame = tabFrames.Anims, Name = "Animations"},
    {Frame = tabFrames.Settings, Name = "Settings"}
}

local function switchTab(targetTab)
    for _, tab in ipairs(tabs) do
        tab.Frame.Visible = (tab == targetTab)
    end
    updateTabButtonsTheme() -- Динамически перерисовываем кнопки с учетом новой темы
end

for index, tab in ipairs(tabs) do
    local btn = create("TextButton", {Name = "Btn_" .. tab.Name, Parent = SideBar, Size = UDim2.new(1, 0, 0, 35), BackgroundColor3 = Color3.fromRGB(35, 35, 35), TextColor3 = Color3.fromRGB(180, 180, 180), Text = tab.Name, Font = Enum.Font.SourceSansSemibold, TextSize = 16, BorderSizePixel = 0, LayoutOrder = index})
    tab.Button = btn
    
    table.insert(themeElements.Buttons, btn)
    table.insert(themeElements.Texts, btn)
    
    btn.MouseButton1Click:Connect(function() switchTab(tab) end)
end
switchTab(tabs[1])

-- Окна управления (Close / Minimize)
local CloseBtn = create("TextButton", {Name = "ButtonClose", Parent = TopBar, Size = UDim2.new(0, 35, 0, 35), Position = UDim2.new(1, -35, 0, 0), BackgroundColor3 = Color3.fromRGB(180, 50, 50), TextColor3 = Color3.fromRGB(255, 255, 255), Text = "X", TextSize = 16, Font = Enum.Font.SourceSansBold, BorderSizePixel = 0})
CloseBtn.MouseButton1Click:Connect(function() MyGui:Destroy() end)
table.insert(themeElements.Texts, CloseBtn)

local ButtonMinimize = create("TextButton", {
    Name = "ButtonMinimize",
    Parent = TopBar,
    Size = UDim2.new(0, 35, 0, 35),
    Position = UDim2.new(1, -70, 0, 0),
    BackgroundColor3 = uiColor_ButtonColor,
    TextColor3 = uiColor_TextColor,
    Text = "-",
    TextSize = 16,
    Font = Enum.Font.SourceSansBold,
    BorderSizePixel = 0
})
table.insert(themeElements.Buttons, ButtonMinimize)
table.insert(themeElements.Texts, ButtonMinimize)

local isMinimized = false
ButtonMinimize.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    ButtonMinimize.Text = isMinimized and "+" or "-"
    MainWindow:TweenSize(
        isMinimized and UDim2.new(0, 250, 0, 35) or UDim2.new(0, 900, 0, 700), 
        "InOut", "Quad", .2, true
    )
    SideBar.Visible = not isMinimized
    UserProfilePanel.Visible = not isMinimized -- Сворачиваем/разворачиваем плашку вместе с меню
    ContentFrame.Visible = not isMinimized
end)
ButtonMinimize.MouseEnter:Connect(function()
    local c = uiColor_ButtonColor
    ButtonMinimize.BackgroundColor3 = Color3.fromRGB(
        math.min((c.R * 255) + 10, 255), 
        math.min((c.G * 255) + 10, 255), 
        math.min((c.B * 255) + 10, 255)
    )
end)
ButtonMinimize.MouseLeave:Connect(function()
    ButtonMinimize.BackgroundColor3 = uiColor_ButtonColor
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == currentToggleKey then
        MainWindow.Visible = not MainWindow.Visible
        if MainWindow.Visible then
            isMinimized = false
            ButtonMinimize.Text = "-"
            MainWindow:TweenSize(UDim2.new(0, 900, 0, 700), "InOut", "Quad", .2, true)
            SideBar.Visible = true
            UserProfilePanel.Visible = true
            ContentFrame.Visible = true
        end
    end
end)

-- Драг
local function makeDraggable(dragFrame, targetFrame)
    local dragging, dragInput, dragStart, startPosition
    dragFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = targetFrame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    dragFrame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            targetFrame.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end)
end
makeDraggable(TopBar, MainWindow)

-- ==========================================
-- СИСТЕМА КЛЮЧЕЙ (KEY SYSTEM GUI)
-- ==========================================
local KeyWindow = create("Frame", {Name = "KeyWindow", Parent = MyGui, Size = UDim2.new(0, 450, 0, 310), Position = UDim2.new(0.5, -225, 0.5, -155), BackgroundColor3 = uiColor_MainWindow, BorderSizePixel = 0})
table.insert(themeElements.MainWindow, KeyWindow)

local KeyTopBar = create("Frame", {Name = "KeyTopBar", Parent = KeyWindow, Size = UDim2.new(1, 0, 0, 35), BackgroundColor3 = uiColor_TopBar, BorderSizePixel = 0})
table.insert(themeElements.TopBars, KeyTopBar)

local KeyTitle = create("TextLabel", {Parent = KeyTopBar, Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 15, 0, 0), BackgroundTransparency = 1, Text = "EmilyUi — Key System", TextColor3 = uiColor_TextColor, TextSize = 18, Font = Enum.Font.SourceSansSemibold, TextXAlignment = Enum.TextXAlignment.Left})
table.insert(themeElements.Texts, KeyTitle)

local KeyCloseBtn = create("TextButton", {Parent = KeyTopBar, Size = UDim2.new(0, 35, 0, 35), Position = UDim2.new(1, -35, 0, 0), BackgroundColor3 = Color3.fromRGB(180, 50, 50), TextColor3 = Color3.fromRGB(255, 255, 255), Text = "X", TextSize = 16, Font = Enum.Font.SourceSansBold, BorderSizePixel = 0})
KeyCloseBtn.MouseButton1Click:Connect(function() MyGui:Destroy() end)
table.insert(themeElements.Texts, KeyCloseBtn)

local KeyInfoLabel = create("TextLabel", {Parent = KeyWindow, Size = UDim2.new(1, -30, 0, 40), Position = UDim2.new(0, 15, 0, 50), BackgroundTransparency = 1, Text = "Please enter your access key below to load the script.\nKey can be obtained via Discord.", TextColor3 = uiColor_TextColor, TextSize = 15, Font = Enum.Font.SourceSans, TextWrapped = true})
table.insert(themeElements.Texts, KeyInfoLabel)

-- Кастомная кнопка дискорда в окне ключей
local KeyDiscordBtn = createContentButton(KeyWindow, "Click to copy Discord Server link", copyDiscord)
KeyDiscordBtn.Name = "KeyDiscordBtn"
KeyDiscordBtn.Size = UDim2.new(1, -40, 0, 40)
KeyDiscordBtn.Position = UDim2.new(0, 20, 0, 105)

local KeyTextBox = createTextBox(KeyWindow, "Enter key here...", Enum.Font.SourceSans)
KeyTextBox.Size = UDim2.new(1, -40, 0, 40)
KeyTextBox.Position = UDim2.new(0, 20, 0, 165)

makeDraggable(KeyTopBar, KeyWindow)

-- Хелперы для новой системы ключей
local function parseKeyLine(line)
    local parts = {}
    for part in string.gmatch(line, "[^:]+") do
        table.insert(parts, part)
    end
    return {
        key = parts[1],
        robloxName = parts[2],
        group = parts[3],
        timeTillWorks = parts[4]
    }
end

-- Функция подсчета оставшихся дней и валидации
local function getKeyDaysLeft(timeStr)
    if not timeStr or timeStr == "inf" then 
        return "Infinity" 
    end
    
    local day, month, year = timeStr:match("(%d+)%.(%d+)%.(%d+)")
    if not day or not month or not year then
        return 0
    end
    
    local expireTime = os.time({
        day = tonumber(day),
        month = tonumber(month),
        year = tonumber(year),
        hour = 0,
        min = 0,
        sec = 0
    })
    
    local diff = expireTime - os.time()
    if diff <= 0 then
        return 0
    else
        return diff / 86400 -- Секунды в дни
    end
end

local function unlockScript(userGroup, daysLeft)
    KeyWindow:Destroy()
    MainWindow.Visible = true
    
    -- Обновляем плашку при загрузке
    updateProfilePanel(userGroup or "Free", daysLeft)
    
    StarterGui:SetCore("SendNotification", { 
        Title = "EmilyUi is loaded", 
        Text = "Welcome! Role: " .. (userGroup or "User"),
        Duration = 10
    })
end

local function checkKeySystem()
    if not cachedKeyResponse then
        local success, response = pcall(function() return game:HttpGet("https://pastebin.com/raw/mLxHwYSH") end)
        if success and response then 
            cachedKeyResponse = response 
        else
            KeyInfoLabel.Text = "Error: Failed to fetch key database!"
            KeyInfoLabel.TextColor3 = Color3.fromRGB(220, 50, 50)
            return
        end
    end

    local response = cachedKeyResponse
    local lines = string.split(response, "\n")
    local myName = string.lower(LocalPlayer.Name)
    local enteredKey = KeyTextBox.Text

    for _, line in ipairs(lines) do
        line = string.gsub(line, "\r", "")
        if line ~= "" then
            local data = parseKeyLine(line)
            
            if data.key and data.robloxName and data.group and data.timeTillWorks then
                local nameMatch = (data.robloxName == "none") or (string.lower(data.robloxName) == myName)
                
                if nameMatch then
                    local daysLeft = getKeyDaysLeft(data.timeTillWorks)
                    
                    -- Если дней больше нуля или это бесконечный ключ ("Infinity")
                    if daysLeft == "Infinity" or daysLeft > 0 then
                        if data.key == "none" or (enteredKey == data.key) then
                            unlockScript(data.group, daysLeft)
                            return
                        end
                    end
                end
            end
        end
    end

    KeyInfoLabel.Text = "Enter key please! You can ask for a key in discord."
    KeyInfoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
end

local BtnSubmit = createContentButton(KeyWindow, "Check Key", checkKeySystem, Color3.fromRGB(50, 120, 50))
BtnSubmit.Size = UDim2.new(0, 150, 0, 40)
BtnSubmit.Position = UDim2.new(0.5, -75, 0, 230)

task.spawn(checkKeySystem)