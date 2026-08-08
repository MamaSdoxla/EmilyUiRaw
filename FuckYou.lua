---@diagnostic disable: undefined-global
--// Сервисы
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

--// Стиль FuckYou
local COL_BG = Color3.fromRGB(12, 12, 12)
local COL_BORDER = Color3.fromRGB(22, 22, 22)
local COL_TEXT = Color3.fromRGB(139, 135, 127)
local COL_TEXTBOX = Color3.fromRGB(18, 18, 18)
local FONT = Enum.Font.SpecialElite

--// Настройки по умолчанию
local currentToggleKey = Enum.KeyCode.P
local uiColor_MainWindow = COL_BG
local uiColor_TopBar = COL_BG
local uiColor_SideBar = COL_BG
local uiColor_TextColor = COL_TEXT
local uiColor_ButtonColor = COL_BG
local uiColor_TextBoxColor = COL_TEXTBOX
local uiGuiOpacity = 1      -- 0.25..1
local uiImageOpacity = 1    -- 0..1
local uiBlurSize = 0        -- 0..24
local uiFitMode = "Fill"
local uiBackgroundFile = "" -- "" = None
local uiCollapsed = false

local cachedKeyResponse = nil
local currentKeyData = { group = "Free", daysLeft = "Infinity" }
local unlocked = false
local beta = true -- true: только Tester и Coder; false: Free, User, Tester, Coder

local function notify(title, text)
	StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 5})
end

notify("Fuck you! v1.2", "To get key goto discord or ask for a permanent one.")

local function create(className, properties)
	local inst = Instance.new(className)
	for k, v in pairs(properties) do inst[k] = v end
	return inst
end

local ScreenGui = create("ScreenGui", {Name = "FuckYouGui", ResetOnSpawn = false, Parent = LocalPlayer:WaitForChild("PlayerGui")})

local themeElements = { MainWindow = {}, TopBars = {}, SideBars = {}, Texts = {}, Buttons = {}, TextBoxes = {}, FillBars = {}, CustomButtons = {} }
local tabs = {}
local updateTabButtonsTheme, applyTheme

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
	for _, el in ipairs(themeElements.MainWindow) do el.BackgroundColor3 = uiColor_MainWindow; el.BackgroundTransparency = trans end
	for _, el in ipairs(themeElements.TopBars) do el.BackgroundColor3 = uiColor_TopBar; el.BackgroundTransparency = trans end
	for _, el in ipairs(themeElements.SideBars) do el.BackgroundColor3 = uiColor_SideBar; el.BackgroundTransparency = trans end
	for _, el in ipairs(themeElements.Texts) do el.TextColor3 = uiColor_TextColor end
	for _, el in ipairs(themeElements.Buttons) do el.BackgroundColor3 = uiColor_ButtonColor; el.BackgroundTransparency = trans end
	for _, el in ipairs(themeElements.CustomButtons) do el.BackgroundTransparency = trans end
	for _, el in ipairs(themeElements.TextBoxes) do el.BackgroundColor3 = uiColor_TextBoxColor; el.BackgroundTransparency = trans end
	for _, el in ipairs(themeElements.FillBars) do el.BackgroundColor3 = uiColor_TextColor end
	updateTabButtonsTheme()
end

--// Автосохранение текущей темы
local configPath = "EmilyUi/Config.json"

local function saveConfig()
	local config = {
		ToggleKey = currentToggleKey.Name,
		MainWindowColor = {uiColor_MainWindow.R, uiColor_MainWindow.G, uiColor_MainWindow.B},
		TopBarColor = {uiColor_TopBar.R, uiColor_TopBar.G, uiColor_TopBar.B},
		SideBarColor = {uiColor_SideBar.R, uiColor_SideBar.G, uiColor_SideBar.B},
		TextColor = {uiColor_TextColor.R, uiColor_TextColor.G, uiColor_TextColor.B},
		ButtonColor = {uiColor_ButtonColor.R, uiColor_ButtonColor.G, uiColor_ButtonColor.B},
		TextBoxColor = {uiColor_TextBoxColor.R, uiColor_TextBoxColor.G, uiColor_TextBoxColor.B},
		GuiOpacity = uiGuiOpacity,
		ImageOpacity = uiImageOpacity,
		Blur = uiBlurSize,
		Fit = uiFitMode,
		BackgroundFile = uiBackgroundFile,
	}
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
			end
		end
	end
end

loadConfig()

--// ===== ГЛАВНОЕ ОКНО =====
local FuckYou = create("Frame", {
	Name = "FuckYou", Parent = ScreenGui,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.new(0, 940, 0, 510),
	ClipsDescendants = true, Visible = false,
	BackgroundColor3 = uiColor_MainWindow, BorderColor3 = COL_BORDER, BorderSizePixel = 1
})
table.insert(themeElements.MainWindow, FuckYou)
--// ===== ФОН / БЛЮР / ПРОЗРАЧНОСТЬ =====
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
		blurEffect.Parent = game:GetService("Lighting")
		blurEffect.Size = uiBlurSize
		blurEffect.Enabled = true
	else
		blurEffect.Enabled = false
		blurEffect.Parent = nil
	end
end
FuckYou:GetPropertyChangedSignal("Visible"):Connect(updateBlur)
ScreenGui.Destroying:Connect(function() blurEffect.Enabled = false; blurEffect.Parent = nil end)

local function customAsset(path)
	if getcustomasset then return getcustomasset(path) end
	if GetCustomAsset then return GetCustomAsset(path) end
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
				if ext == "png" or ext == "jpg" or ext == "jpeg" or ext == "webp" then
					table.insert(out, name)
				end
			end
			table.sort(out)
		end
	end
	return out
end

--// Соответствие названий из списка реальным Enum.ScaleType (Fill/Center/Zoom в Roblox нет)
local FIT_MAP = {
	Fill = Enum.ScaleType.Crop,     -- заполнить с обрезкой краёв
	Fit = Enum.ScaleType.Fit,       -- вписать целиком
	Stretch = Enum.ScaleType.Stretch, -- растянуть по размеру окна
	Tile = Enum.ScaleType.Tile,     -- замостить плиткой
	Center = Enum.ScaleType.Crop,   -- (ближайший аналог центра)
	Zoom = Enum.ScaleType.Crop,     -- (ближайший аналог зума)
	Slice = Enum.ScaleType.Slice,
	Crop = Enum.ScaleType.Crop,
}
local function getScaleType(name)
	if FIT_MAP[name] then return FIT_MAP[name] end
	local ok, val = pcall(function() return Enum.ScaleType[name] end)
	if ok and val then return val end
	return Enum.ScaleType.Stretch
end

local function applyBackground()
	local asset = (uiBackgroundFile ~= "") and customAsset(BG_FOLDER .. "/" .. uiBackgroundFile) or nil
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

local TopBar = create("Frame", {Name = "TopBar", Parent = FuckYou, Size = UDim2.new(1, 0, 0, 45), BackgroundColor3 = uiColor_TopBar, BorderSizePixel = 0})
table.insert(themeElements.TopBars, TopBar)

local Title = create("TextLabel", {Name = "Name", Parent = TopBar, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "Fuck you! v1.2", TextColor3 = uiColor_TextColor, TextSize = 14, Font = FONT})
table.insert(themeElements.Texts, Title)

local function makeTopBtn(symbol, offset)
	local b = create("TextButton", {
		Name = symbol, Parent = TopBar,
		Position = UDim2.new(1, -45 * offset, 0, 0), Size = UDim2.new(0, 45, 0, 45),
		BackgroundColor3 = uiColor_TopBar, BorderColor3 = COL_BORDER,
		Text = symbol, TextColor3 = uiColor_TextColor, TextSize = 14, Font = FONT
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

--// Левый сайдбар
local SideBard = create("Frame", {Name = "SideBard", Parent = FuckYou, Position = UDim2.new(0, 0, 0, 45), Size = UDim2.new(0, 65, 1, -45), BackgroundColor3 = uiColor_SideBar, BorderSizePixel = 0})
table.insert(themeElements.SideBars, SideBard)

local function makeSideBtn(text, offsetY)
	local b = create("TextButton", {
		Name = text, Parent = SideBard,
		Position = UDim2.new(0, 0, 0, offsetY), Size = UDim2.new(1, 0, 0, 59),
		BackgroundColor3 = uiColor_SideBar, BorderColor3 = COL_BORDER,
		Text = text, TextColor3 = uiColor_TextColor, TextSize = 12, Font = FONT
	})
	table.insert(themeElements.SideBars, b)
	table.insert(themeElements.Texts, b)
	return b
end

local EmilyUi = makeSideBtn("EmilyUi", 0)
local Desync = makeSideBtn("Desync", 59)
local Music = makeSideBtn("Music", 118)
local Aim = makeSideBtn("Aim", 177)

--// Меню вкладок
local MenuInsided = create("Frame", {Name = "MenuInsided", Parent = FuckYou, Position = UDim2.new(0, 65, 0, 45), Size = UDim2.new(0, 105, 1, -45), BackgroundColor3 = uiColor_SideBar, BorderSizePixel = 0})
table.insert(themeElements.SideBars, MenuInsided)
create("UIListLayout", {Parent = MenuInsided, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)})
create("UIPadding", {Parent = MenuInsided, PaddingTop = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)})

--// Containment
local Containment = create("Frame", {Name = "Containment", Parent = FuckYou, Position = UDim2.new(0, 170, 0, 45), Size = UDim2.new(1, -170, 1, -45), BackgroundTransparency = 1, BorderSizePixel = 0})

local function makeLine(name, pos, size)
	return create("Frame", {Name = name, Parent = FuckYou, Position = pos, Size = size, BackgroundColor3 = COL_BORDER, BorderSizePixel = 0})
end

makeLine("SepH", UDim2.new(0, 0, 0, 45), UDim2.new(1, 0, 0, 1))
makeLine("SepV1", UDim2.new(0, 65, 0, 46), UDim2.new(0, 1, 1, -46))
makeLine("SepV2", UDim2.new(0, 170, 0, 46), UDim2.new(0, 1, 1, -46))

--// ===== КОНТЕНТ =====
local function createTabContentFrame(name)
	local sf = create("ScrollingFrame", {Name = name, Parent = Containment, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = COL_BORDER, CanvasSize = UDim2.new(0, 0, 0, 0), Visible = false})
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
	Games = createTabContentFrame("TabGames"),
	Scripts = createTabContentFrame("TabScripts"),
	Hubs = createTabContentFrame("TabScriptHubs"),
	Guis = createTabContentFrame("TabGuis"),
	Anims = createTabContentFrame("TabAnimations"),
	Settings = createTabContentFrame("TabSettings")
}

local function createSection(parent, text)
	local lbl = create("TextLabel", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = text, TextColor3 = uiColor_TextColor, TextSize = 14, Font = FONT, Parent = parent})
	table.insert(themeElements.Texts, lbl)
	return lbl
end

local function createLabel(parent, text)
	local lbl = create("TextLabel", {Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = text, TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, Parent = parent})
	table.insert(themeElements.Texts, lbl)
	return lbl
end

local function createContentButton(parent, text, callback, customColor)
	local defaultColor = customColor or uiColor_ButtonColor
	local btn = create("TextButton", {Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = defaultColor, BorderColor3 = COL_BORDER, TextColor3 = uiColor_TextColor, Text = text, Font = FONT, TextSize = 13, Parent = parent})
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
	local box = create("TextBox", {BackgroundColor3 = uiColor_TextBoxColor, BorderColor3 = COL_BORDER, TextColor3 = uiColor_TextColor, PlaceholderColor3 = Color3.fromRGB(90, 90, 90), PlaceholderText = placeholder, Text = "", TextSize = 13, Font = font or FONT, ClearTextOnFocus = false, Parent = parent})
	table.insert(themeElements.Texts, box)
	table.insert(themeElements.TextBoxes, box)
	return box
end

local function copyDiscord()
	if setclipboard then setclipboard("https://discord.gg/75Dz8T9hHR") end
	notify("Discord", "The link is copied")
end

--// Профиль
local UserProfilePanel = create("Frame", {Name = "UserProfilePanel", Parent = tabFrames.Main, Size = UDim2.new(1, 0, 0, 60), LayoutOrder = -1, BackgroundColor3 = uiColor_SideBar, BorderColor3 = COL_BORDER})
table.insert(themeElements.SideBars, UserProfilePanel)

local UserImage = create("ImageLabel", {Parent = UserProfilePanel, Position = UDim2.new(0, 10, 0, 10), Size = UDim2.new(0, 40, 0, 40), BackgroundTransparency = 1, Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"})
create("UICorner", {Parent = UserImage, CornerRadius = UDim.new(1, 0)})

create("TextLabel", {Parent = UserProfilePanel, Position = UDim2.new(0, 60, 0, 6), Size = UDim2.new(1, -70, 0, 16), BackgroundTransparency = 1, Text = LocalPlayer.DisplayName, TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 14, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd})

local UserKeyTimeLabel = create("TextLabel", {Parent = UserProfilePanel, Position = UDim2.new(0, 60, 0, 22), Size = UDim2.new(1, -70, 0, 14), BackgroundTransparency = 1, Text = "Days left: Inf", TextColor3 = Color3.fromRGB(180, 180, 180), TextSize = 12, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left})
table.insert(themeElements.Texts, UserKeyTimeLabel)

local UserGroupLabel = create("TextLabel", {Parent = UserProfilePanel, Position = UDim2.new(0, 60, 0, 38), Size = UDim2.new(1, -70, 0, 14), BackgroundTransparency = 1, Text = "Group: Free", TextColor3 = Color3.fromRGB(150, 150, 150), TextSize = 12, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left})

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

--// Наполнение вкладок
local uiStructure = {
	{ tab = tabFrames.Main, type = "section", text = "In case something happens here's a discord server" },
	{ tab = tabFrames.Main, type = "button", text = "Click to copy Discord Server link", cb = copyDiscord },
	{ tab = tabFrames.Main, type = "section", text = "* Credits to *" },
	{ tab = tabFrames.Main, type = "section", text = "RobloxId (DiscordUsername) -> role" },
	{ tab = tabFrames.Main, type = "section", text = "WdymGaming (wdymgaming) -> coder" },
	{ tab = tabFrames.Main, type = "section", text = "pashajokot (swatwincky) -> tester" },
    { tab = tabFrames.Main, type = "section", text = "BombalMac (bombapc) -> tester" },

	{ tab = tabFrames.Universal, type = "section", text = "Admin Commands" },
	{ tab = tabFrames.Universal, type = "button", text = "Infinite Yield", cb = function() loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))() end },
	{ tab = tabFrames.Universal, type = "button", text = "FE Admin Commands", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/lxte/cmd/main/main.lua"))() end },
	{ tab = tabFrames.Universal, type = "section", text = "For exploiting" },
	{ tab = tabFrames.Universal, type = "button", text = "Dex Explorer++", cb = function() loadstring(game:HttpGet("https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua"))() end },
	{ tab = tabFrames.Universal, type = "button", text = "Rem v1.2", cb = function() loadstring(game:HttpGet("https://e-vil.com/anbu/rem.lua"))() end },
	{ tab = tabFrames.Universal, type = "button", text = "VEX (better DEX)", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Vezise/2026/main/Vez/VexExplorer/VEXExplorer.lua"))() end },
	{ tab = tabFrames.Universal, type = "button", text = "Executor Tester | v2.6", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/GmilerlolYT/ExecutorTester/refs/heads/main/Hi"))() end },

	{ tab = tabFrames.Scripts, type = "section", text = "Fun Scripts" },
	{ tab = tabFrames.Scripts, type = "button", text = "Ball R6/R15", cb = function() loadstring(game:HttpGet("https://pastebin.com/raw/BZr9bGDy", true))() end },
	{ tab = tabFrames.Scripts, type = "section", text = "Scripts made by WdymGaming (outdated, no longer support)" },
	{ tab = tabFrames.Scripts, type = "button", text = "Wdymgaming's Music Gui (client)", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/MamaSdoxla/EmilyUi/refs/heads/main/HomeMade/WdymGamingMusic.lua", true))() end },
	{ tab = tabFrames.Scripts, type = "button", text = "R6/R15 Animator by WdymGaming", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/MamaSdoxla/EmilyUi/refs/heads/main/HomeMade/WdymGamingAnimator.lua", true))() end },
	{ tab = tabFrames.Scripts, type = "button", text = "Aimbot + ESP", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/MamaSdoxla/EmilyUi/refs/heads/main/HomeMade/WdymGamingAimbot.lua", true))() end },

	{ tab = tabFrames.Hubs, type = "section", text = "Script hubs" },
	{ tab = tabFrames.Hubs, type = "button", text = "Axe Hub for Natural Disaster Survival", cb = function() loadstring(game:HttpGet('https://raw.githubusercontent.com/zeroidxx/axe-hub/refs/heads/main/axehub%20nds.txt'))() end },
	{ tab = tabFrames.Hubs, type = "button", text = "FE Trolling GUI", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/yofriendfromschool1/Sky-Hub/main/FE%20Trolling%20GUI.luau"))() end },
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
}

for _, item in ipairs(uiStructure) do
	if item.type == "section" then createSection(item.tab, item.text)
	elseif item.type == "label" then createLabel(item.tab, item.text)
	elseif item.type == "button" then createContentButton(item.tab, item.text, item.cb) end
end

--// Games
local filterMode = "All"
local currentPlaceId = tostring(game.PlaceId)

local GamePlaces = {
	["12355337193"] = {
		{ type = "label", text = "Murder vs Sherif 2" },
		{ type = "button", text = "Polo MVS", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/polo242c/mvs/main/mvs"))() end },
		{ type = "button", text = "CyberCoders", cb = function() loadstring(game:HttpGet("https://rawscripts.net/raw/Murderers-VS-Sheriffs-DUELS-CyberCoders-Menu-II-193913"))() end },
		{ type = "button", text = "Wic1k", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Wic1k/Scripts/refs/heads/main/mvsd.txt"))() end },
	},
	["7041939546"] = {
		{ type = "label", text = "Catalog Avatar Creator" },
		{ type = "button", text = "Avatar stealer", cb = function() loadstring(game:HttpGet("https://pastefy.app/xWdIDQJd/raw"))() end },
	},
	["142823291"] = {
		{ type = "label", text = "Murder Mystery 2" },
		{ type = "button", text = "VisionHub", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/orialdev/VisionHub/refs/heads/main/main.lua"))() end },
		{ type = "button", text = "AutoFarm (40coins/4,5min)", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/tsBelrux/mm2/refs/heads/main/keyless.lua"))() end },
		{ type = "button", text = "FoxnameHub", cb = function() loadstring(game:HttpGet("https://foxname.top/loader"))() end },
	},
	["95082159892680"] = {
		{ type = "label", text = "+1 Speed Keyboard Escape" },
		{ type = "button", text = "Luxy Hub", cb = function() loadstring(game:HttpGet("https://www.luxyhub.space/api/loader/luxyhub"))() end },
	}
}

local function renderGamesTab()
	for _, child in ipairs(tabFrames.Games:GetChildren()) do
		if child:IsA("TextLabel") or child:IsA("TextButton") then child:Destroy() end
	end
	createContentButton(tabFrames.Games, "Filter: " .. filterMode .. " (Click to switch)", function()
		filterMode = (filterMode == "All") and "Place" or "All"
		renderGamesTab()
	end)
	createSection(tabFrames.Games, "Game Scripts")
	for placeId, items in pairs(GamePlaces) do
		local shouldShow = (filterMode == "All") or (filterMode == "Place" and placeId == currentPlaceId)
		if shouldShow then
			for _, item in ipairs(items) do
				if item.type == "label" then createLabel(tabFrames.Games, item.text)
				elseif item.type == "button" then createContentButton(tabFrames.Games, item.text, item.cb)
				elseif item.type == "section" then createSection(tabFrames.Games, item.text) end
			end
		end
	end
end
renderGamesTab()

--// Animations
local animFilterMode = "All"

local AnimationsSections = {
	{ title = "Animations client", scripts = {
		{ text = "R6 Insanity (client)", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/retpirato/Roblox-Scripts/refs/heads/master/Insanity%20Powers.lua"))() end },
	}},
	{ title = "Animations guis", scripts = {
		{ text = "R15 Animations", cb = function() loadstring(game:HttpGet("https://kbauu.neocities.org/animation-hub"))() end },
		{ text = "Uhhhhhh Reanimator (R6)", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/STEVE-916-create/Uhhhhhh/main/source/reanim.lua"))() end },
	}},
	{ title = "Animation exploits", scripts = {
		{ text = "R6 Upsidedown (multiple times = glitch)", cb = function() loadstring(game:HttpGet("https://pastebin.com/raw/RJVv7H3K"))() end },
	}},
	{ title = "Animations S3X", scripts = {
		{ text = "R6 S3X animations", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/3LD4D0/FE-TROLLING-PLAYER-R6-R15/6eff8792afed57458d5114478b453a6f6bce5799/Fe%20trolling%20Player%20R6%20AND%20R15"))() end },
		{ text = "R6 S3X animations 2", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/ShutUpJamesTheLoserAlt/fes/refs/heads/main/e"))() end },
		{ text = "R6 S3X animations 3", cb = function() loadstring(game:HttpGet("https://pastebin.com/raw/gdQ4mVEy"))() end },
		{ text = "Jerk off tool r6", cb = function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-FE-Jerk-off-240507"))() end },
		{ text = "Jerk off tool r15", cb = function() loadstring(game:HttpGet("https://pastefy.app/YZoglOyJ/raw"))() end },
	}}
}

local function getAnimType(text)
	local lower = string.lower(text)
	local hasR6 = string.find(lower, "r6") ~= nil
	local hasR15 = string.find(lower, "r15") ~= nil
	if hasR6 and hasR15 then return "Universal"
	elseif hasR6 then return "R6"
	elseif hasR15 then return "R15"
	else return "Universal" end
end

local function renderAnimationsTab()
	for _, child in ipairs(tabFrames.Anims:GetChildren()) do
		if child:IsA("TextLabel") or child:IsA("TextButton") then child:Destroy() end
	end
	createContentButton(tabFrames.Anims, "Filter: " .. animFilterMode .. " (Click to switch)", function()
		if animFilterMode == "All" then animFilterMode = "R6"
		elseif animFilterMode == "R6" then animFilterMode = "R15"
		else animFilterMode = "All" end
		renderAnimationsTab()
	end)
	local totalShown = 0
	for _, section in ipairs(AnimationsSections) do
		local validScripts = {}
		for _, script in ipairs(section.scripts) do
			local t = getAnimType(script.text)
			if animFilterMode == "All" or t == animFilterMode or t == "Universal" then
				table.insert(validScripts, script)
			end
		end
		if #validScripts > 0 then
			createSection(tabFrames.Anims, section.title)
			for _, script in ipairs(validScripts) do
				createContentButton(tabFrames.Anims, script.text, script.cb)
				totalShown = totalShown + 1
			end
		end
	end
	if totalShown == 0 then
		createLabel(tabFrames.Anims, "No scripts found for filter: " .. animFilterMode)
	end
end
renderAnimationsTab()

-- =========================================================
-- ========== DESYNC MODULE v4 =============================
-- =========================================================
local function initDesyncModule()
	local C_GRN = Color3.fromRGB(100, 255, 100)
	local C_ROFF = Color3.fromRGB(255, 100, 100)
	local C_REDD = Color3.fromRGB(150, 40, 40)
	local C_WHT = Color3.fromRGB(255, 255, 255)
	local F_R = Enum.Font.SourceSans
	local F_B = Enum.Font.SourceSansBold
	local F_S = Enum.Font.SourceSansSemibold
	local F_I = Enum.Font.SourceSansItalic

	local FOLDER = "EmilyUi/Animator"
	local FILE_DESYNC = FOLDER .. "/animations_saved.json"
	local FILE_R6 = FOLDER .. "/AnimationManagerJsonR6.json"
	local FILE_R15 = FOLDER .. "/AnimationManagerJsonR15.json"
	local FILE_KEYS = FOLDER .. "/keybinds.json"

	local function ensureDirs()
		if makefolder then pcall(function()
			if not isfolder("EmilyUi") then makefolder("EmilyUi") end
			if not isfolder(FOLDER) then makefolder(FOLDER) end
		end) end
	end
	local function loadMgr(mode)
		local p = (mode == "R6") and FILE_R6 or FILE_R15
		if isfile and isfile(p) then
			local ok, r = pcall(function() return HttpService:JSONDecode(readfile(p)) end)
			if ok and type(r) == "table" then r._subcategories = r._subcategories or {}; return r end
		end
		return { _subcategories = {} }
	end
	local function saveMgr(mode, data)
		if writefile then ensureDirs()
			pcall(function() writefile((mode == "R6") and FILE_R6 or FILE_R15, HttpService:JSONEncode(data)) end)
		end
	end
	local function loadDesyncAnims()
		if isfile and isfile(FILE_DESYNC) then
			local ok, r = pcall(function() return HttpService:JSONDecode(readfile(FILE_DESYNC)) end)
			if ok and type(r) == "table" then return r end
		end
		return {}
	end
	local function saveDesyncAnims(d)
		if writefile then ensureDirs(); pcall(function() writefile(FILE_DESYNC, HttpService:JSONEncode(d)) end) end
	end
	local function loadKeys()
		local b = {}
		if isfile and isfile(FILE_KEYS) then
			local ok, r = pcall(function() return HttpService:JSONDecode(readfile(FILE_KEYS)) end)
			if ok and type(r) == "table" then b = r end
		end
		if not b.Animations then b.Animations = {} end
		if b.Animations and not b.Animations[1] then
			local old = b.Animations; b.Animations = {}
			if old.Desync and old.Desync.key then table.insert(b.Animations, {key=old.Desync.key,type="Desync",animName=old.Desync.animName,speed=old.Desync.speed or 1,looped=old.Desync.looped or false,reversed=old.Desync.reversed or false}) end
			if old.Normal and old.Normal.key then table.insert(b.Animations, {key=old.Normal.key,type="Normal",animName=old.Normal.animName,bodyType=old.Normal.bodyType or "R6",speed=old.Normal.speed or 1,looped=old.Normal.looped or false,reversed=old.Normal.reversed or false}) end
		end
		return b
	end
	local function saveKeys(d)
		if writefile then ensureDirs(); pcall(function() writefile(FILE_KEYS, HttpService:JSONEncode(d)) end) end
	end

	local savedDesyncAnimations = loadDesyncAnims()
	local managerDataCache = { R6 = loadMgr("R6"), R15 = loadMgr("R15") }
	local keybinds = loadKeys()

	local OffsetPos = Vector3.new(0,0,0)
	local OffsetRot = Vector3.new(0,0,0)
	local isRunning = true
	local IsDesynced = false
	local DesyncLoop, VisualChar, CharDeathConn = nil, nil, nil
	local realCF = CFrame.new()
	local partMap = {}
	local RENDER_NAME = "DesyncPreCamera"
	local desyncChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local DesyncToggleBtn, OrientationInput, PositionInput = nil, nil, nil
	local keybindWaitForInput = false
    local onKeybindPressed = nil
    local DesyncSectionEnabled = false

	local function parseV3(s)
		local p = string.split(string.gsub(s, " ", ""), ",")
		return Vector3.new(tonumber(p[1]) or 0, tonumber(p[2]) or 0, tonumber(p[3]) or 0)
	end
	local function strToV3(s)
		local t = {}
		for n in string.gmatch(s, "[^,]+") do table.insert(t, tonumber(n) or 0) end
		return Vector3.new(t[1] or 0, t[2] or 0, t[3] or 0)
	end
	local function buildPartMap(o, v, m)
		for _, ch in ipairs(o:GetChildren()) do
			local vc = v:FindFirstChild(ch.Name)
			if vc then
				if ch:IsA("BasePart") and vc:IsA("BasePart") then m[ch] = vc end
				buildPartMap(ch, vc, m)
			end
		end
	end
	local function lighter(c, amt)
		return Color3.fromRGB(math.min(c.R*255+amt,255), math.min(c.G*255+amt,255), math.min(c.B*255+amt,255))
	end
	local function darker(c, amt)
		return Color3.fromRGB(math.max(c.R*255-amt,0), math.max(c.G*255-amt,0), math.max(c.B*255-amt,0))
	end

	local function stopDesync()
		IsDesynced = false
		if DesyncToggleBtn then DesyncToggleBtn.Text = "Desync: OFF"; DesyncToggleBtn.TextColor3 = C_ROFF end
		OffsetPos = Vector3.new(0,0,0); OffsetRot = Vector3.new(0,0,0)
		if OrientationInput then OrientationInput.Text = "0,0,0" end
		if PositionInput then PositionInput.Text = "0,0,0" end
		if DesyncLoop then DesyncLoop:Disconnect(); DesyncLoop = nil end
		pcall(function() RunService:UnbindFromRenderStep(RENDER_NAME) end)
		if VisualChar then VisualChar:Destroy(); VisualChar = nil end
		table.clear(partMap)
	end

	local function startDesync()
	    if not DesyncSectionEnabled then return end
	    if IsDesynced then stopDesync() end
		local char = LocalPlayer.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum then return end
		char.Archivable = true
		VisualChar = char:Clone()
		for _, v in pairs(VisualChar:GetDescendants()) do
			if v:IsA("Script") or v:IsA("LocalScript") then v:Destroy()
			elseif v:IsA("BasePart") then
				v.CanCollide = false; v.CastShadow = false; v.Anchored = true
				if v.Transparency < 0.5 then v.Transparency = 0.5 end
			elseif v:IsA("Humanoid") then
				v.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
				v.PlatformStand = true; v.Name = "FakeHumanoid"
			end
		end
		if not VisualChar.PrimaryPart then VisualChar.PrimaryPart = VisualChar:FindFirstChild("HumanoidRootPart") end
		table.clear(partMap); buildPartMap(char, VisualChar, partMap)
		VisualChar.Parent = workspace
		IsDesynced = true
		if DesyncToggleBtn then DesyncToggleBtn.Text = "Desync: ON"; DesyncToggleBtn.TextColor3 = C_GRN end
		realCF = hrp.CFrame
		DesyncLoop = RunService.Heartbeat:Connect(function()
			if not IsDesynced or not char.Parent or not hrp.Parent then stopDesync(); return end
			realCF = hrp.CFrame
			local dCF = realCF * CFrame.new(OffsetPos) * CFrame.Angles(math.rad(OffsetRot.X), math.rad(OffsetRot.Y), math.rad(OffsetRot.Z))
			local rel = {}
			for op, _ in pairs(partMap) do
				if op.Parent then rel[op] = realCF:ToObjectSpace(op.CFrame) end
			end
			hrp.CFrame = dCF
			if VisualChar and VisualChar.Parent then
				for op, r in pairs(rel) do
					local vp = partMap[op]
					if vp and vp.Parent then vp.CFrame = dCF * r end
				end
			end
		end)
		RunService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.Camera.Value - 1, function()
			if not IsDesynced or not hrp.Parent then return end
			hrp.CFrame = realCF
			if workspace.CurrentCamera then workspace.CurrentCamera.CameraSubject = hum end
		end)
	end

	local function reloadDesync() stopDesync(); task.wait(0.1); startDesync() end

	local curDesyncName, curDesyncPlaying, desyncThread = nil, false, nil
	local function stopDesyncAnim()
		if desyncThread then task.cancel(desyncThread); desyncThread = nil end
		curDesyncPlaying = false; curDesyncName = nil
		OffsetRot = Vector3.new(0,0,0); OffsetPos = Vector3.new(0,0,0)
		if OrientationInput then OrientationInput.Text = "0,0,0" end
		if PositionInput then PositionInput.Text = "0,0,0" end
	end
	local function playDesyncAnim(name, loop, speed, reversed)
	    if not DesyncSectionEnabled then return end
	    stopDesyncAnim()
		local d = savedDesyncAnimations[name]
		if not d or not d.frames then return end
		curDesyncName = name; curDesyncPlaying = true
		local frames = d.frames
		if reversed then local r = {}; for i = #frames, 1, -1 do table.insert(r, frames[i]) end; frames = r end
		desyncThread = task.spawn(function()
			while curDesyncPlaying and isRunning do
				for _, f in ipairs(frames) do
					if not curDesyncPlaying then break end
					local tR, tP = strToV3(f.rot), strToV3(f.pos)
					local dur = (f.time or 1) / (speed or 1)
					local sR, sP = OffsetRot, OffsetPos
					local el = 0
					while el < dur and curDesyncPlaying and isRunning do
						el = el + RunService.Heartbeat:Wait()
						local t = math.min(el / dur, 1)
						OffsetRot = sR:Lerp(tR, t); OffsetPos = sP:Lerp(tP, t)
					end
				end
				if not loop then break end
			end
			curDesyncPlaying = false; curDesyncName = nil; desyncThread = nil
		end)
	end
	local curNormTrack, curNormName = nil, nil
	local function stopNormAnim()
		if curNormTrack then pcall(function() curNormTrack:Stop() end); curNormTrack = nil end
		curNormName = nil
	end
	local function playNormAnim(bt, name, speed, looped, reversed)
	    if not DesyncSectionEnabled then return end
	    stopNormAnim()
		local data = managerDataCache[bt]
		if not data then return end
		local id = data[name]
		if not id then
			for _, st in pairs(data._subcategories or {}) do if st[name] then id = st[name]; break end end
		end
		if not id then return end
		local clean = string.match(tostring(id), "%d+") or id
		if desyncChar and desyncChar:FindFirstChildOfClass("Humanoid") then
			local a = Instance.new("Animation"); a.AnimationId = "rbxassetid://" .. clean
			local hum = desyncChar:FindFirstChildOfClass("Humanoid")
			local an = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
			local ok, tr = pcall(function() return an:LoadAnimation(a) end)
			if ok and tr then
				curNormTrack = tr; curNormName = name
				tr.Looped = looped or false
				local sp = speed or 1
				if reversed then sp = -sp end
				tr:Play(); tr:AdjustSpeed(sp)
				if reversed and tr.Length > 0 then tr.TimePosition = tr.Length end
			end
		end
	end

	local function handleKeybind(key)
	    if not key then return end
	    if not DesyncSectionEnabled then return end
		if keybinds.Desync and keybinds.Desync.key == key then
			if IsDesynced then stopDesync() else startDesync() end
			return
		end
		if keybinds.Animations then
			for _, b in ipairs(keybinds.Animations) do
				if b.key == key then
					if b.type == "Desync" then
						if curDesyncPlaying and curDesyncName == b.animName then stopDesyncAnim()
						else playDesyncAnim(b.animName, b.looped, b.speed, b.reversed) end
					elseif b.type == "Normal" then
						if curNormTrack and curNormName == b.animName then stopNormAnim()
						else playNormAnim(b.bodyType, b.animName, b.speed, b.looped, b.reversed) end
					end
				end
			end
		end
	end

	UserInputService.InputBegan:Connect(function(inp, processed)
		if processed then return end
		if inp.UserInputType == Enum.UserInputType.Keyboard then
			local k = inp.KeyCode.Name
			if keybindWaitForInput then
				if onKeybindPressed then onKeybindPressed(k) end
				keybindWaitForInput = false
				return
			end
			handleKeybind(k)
		end
	end)

	local function corner(p) Instance.new("UICorner", p).CornerRadius = UDim.new(0, 4) end
	local function mkLabel(p, txt, sz, pos, font, ts)
		local l = Instance.new("TextLabel")
		l.Parent = p; l.Text = txt; l.Size = sz; l.Position = pos
		l.Font = font or F_S; l.TextSize = ts or 16
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextColor3 = uiColor_TextColor; l.BackgroundTransparency = 1
		table.insert(themeElements.Texts, l)
		return l
	end
	local function mkBox(p, txt, sz, pos, ts)
		local b = Instance.new("TextBox")
		b.Parent = p; b.Text = txt or ""; b.Size = sz; b.Position = pos
		b.Font = F_R; b.TextSize = ts or 14
		b.BackgroundColor3 = uiColor_TextBoxColor; b.TextColor3 = uiColor_TextColor
		b.PlaceholderColor3 = Color3.fromRGB(90, 90, 90)
		b.BorderSizePixel = 0; b.ClearTextOnFocus = false
		table.insert(themeElements.TextBoxes, b)
		table.insert(themeElements.Texts, b)
		corner(b); return b
	end
	local function mkBtn(p, txt, sz, pos, font, ts, themed)
		local b = Instance.new("TextButton")
		b.Parent = p; b.Text = txt; b.Size = sz; b.Position = pos
		b.Font = font or F_B; b.TextSize = ts or 14
		b.BackgroundColor3 = uiColor_ButtonColor; b.TextColor3 = uiColor_TextColor
		b.BorderSizePixel = 0
		if themed ~= "no" then
    		table.insert(themeElements.Buttons, b)
    		table.insert(themeElements.Texts, b)
		else
    		table.insert(themeElements.CustomButtons, b)   -- новое
		end
		b.BackgroundTransparency = 1 - uiGuiOpacity        -- новое: списки пересозаются динамически,
		corner(b); return b                                -- чтобы новые кнопки сразу брали текущую прозрачность
	end
	local function mkPanel(p, sz, pos)
 		local f = Instance.new("Frame")
 		f.Parent = p; f.Size = sz; f.Position = pos or UDim2.new(0,0,0,0)
 		f.BackgroundColor3 = uiColor_SideBar; f.BorderSizePixel = 0
 		f.ClipsDescendants = true -- не выпускаем кнопки за пределы панели при сворачивании
 		table.insert(themeElements.SideBars, f)
 		corner(f); return f
	end
	local function mkListBG(p, sz, pos)
		local f = create("ScrollingFrame", {Parent = p, Size = sz, Position = pos, BackgroundColor3 = uiColor_TextBoxColor, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0,0,0,0)})
		table.insert(themeElements.TextBoxes, f)
		corner(f); return f
	end

	--// 1. DESYNC
	local function buildDesyncTab(parent)
		local sf = create("ScrollingFrame", {Parent = parent, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0,0,0,260)})
		local inner = mkPanel(sf, UDim2.new(1,0,0,260))
		mkLabel(inner, "Orientation", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,8), F_S, 20)
		OrientationInput = mkBox(inner, "0,0,0", UDim2.new(1,-24,0,24), UDim2.new(0,12,0,26), 20)
		mkLabel(inner, "Position", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,56), F_S, 20)
		PositionInput = mkBox(inner, "0,0,0", UDim2.new(1,-24,0,24), UDim2.new(0,12,0,74), 20)
		local applyBtn = mkBtn(inner, "Apply Changes", UDim2.new(1,-24,0,28), UDim2.new(0,12,0,110), F_B, 20)
		DesyncToggleBtn = mkBtn(inner, "Desync: OFF", UDim2.new(0.5,-16,0,28), UDim2.new(0,12,0,150), F_B, 15, false)
		DesyncToggleBtn.TextColor3 = C_ROFF
		local reloadBtn = mkBtn(inner, "Desync Reload", UDim2.new(0.5,-16,0,28), UDim2.new(0.5,4,0,150), F_B, 14)
		applyBtn.MouseButton1Click:Connect(function()
			OffsetRot = parseV3(OrientationInput.Text); OffsetPos = parseV3(PositionInput.Text)
			applyBtn.Text = "Applied!"; task.wait(0.4); applyBtn.Text = "Apply Changes"
		end)
			DesyncToggleBtn.MouseButton1Click:Connect(function() if IsDesynced then stopDesync() else startDesync() end end)
	    reloadBtn.MouseButton1Click:Connect(reloadDesync)

	    local desyncSectionToggleBtn = mkBtn(inner, "Main Toggle: OFF", UDim2.new(1,-24,0,28), UDim2.new(0,12,0,190), F_B, 16, "no")
	    desyncSectionToggleBtn.BackgroundColor3 = Color3.fromRGB(70, 40, 40)
	    desyncSectionToggleBtn.TextColor3 = C_ROFF

	    desyncSectionToggleBtn.MouseButton1Click:Connect(function()
		    DesyncSectionEnabled = not DesyncSectionEnabled

		    if DesyncSectionEnabled then
			    desyncSectionToggleBtn.Text = "Main Toggle: ON"
			    desyncSectionToggleBtn.TextColor3 = C_GRN
			    desyncSectionToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
		    else
    			desyncSectionToggleBtn.Text = "Main Toggle: OFF"
			    desyncSectionToggleBtn.TextColor3 = C_ROFF
			    desyncSectionToggleBtn.BackgroundColor3 = Color3.fromRGB(70, 40, 40)

			    if IsDesynced then stopDesync() end
			    stopDesyncAnim()
			    stopNormAnim()
		    end
	    end)
    end

	--// 2. ANIM EDITOR
	local function buildEditorTab(parent)
		local sf = create("ScrollingFrame", {Parent = parent, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0,0,0,280)})
		local inner = mkPanel(sf, UDim2.new(1,0,0,280))
		local left = create("Frame", {Parent = inner, Size = UDim2.new(0.5,-4,1,0), Position = UDim2.new(0,2,0,0), BackgroundTransparency = 1})
		local right = mkListBG(inner, UDim2.new(0.5,-6,1,-10), UDim2.new(0.5,4,0,5))
		local rLayout = create("UIListLayout", {Parent = right, Padding = UDim.new(0,2)})
		rLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			right.CanvasSize = UDim2.new(0,0,0, rLayout.AbsoluteContentSize.Y + 6)
		end)
		local function field(lbl, def, y)
			mkLabel(left, lbl, UDim2.new(1,-20,0,16), UDim2.new(0,10,0,y), F_S, 14)
			return mkBox(left, def, UDim2.new(1,-20,0,22), UDim2.new(0,10,0,y+16), 14)
		end
		local edO = field("Orientation", "0,0,0", 5)
		local edP = field("Position", "0,0,0", 45)
		local edT = field("Time (seconds)", "1.0", 85)
		local edN = field("Animation Name", "MyAnimation", 125)
		local loadBtn = mkBtn(left, "Load Animation", UDim2.new(1,-20,0,22), UDim2.new(0,10,0,165), F_B, 12)
		local loadDD = mkListBG(left, UDim2.new(1,-20,0,60), UDim2.new(0,10,0,190))
		loadDD.ZIndex = 5
		create("UIListLayout", {Parent = loadDD})
		local addB = mkBtn(left, "Add", UDim2.new(0,40,0,24), UDim2.new(0,10,0,215), F_B, 14)
		local remB = mkBtn(left, "Remove", UDim2.new(0,50,0,24), UDim2.new(0,55,0,215), F_B, 14)
		local editB = mkBtn(left, "Edit", UDim2.new(0,50,0,24), UDim2.new(0,110,0,215), F_B, 14)
		local saveB = mkBtn(left, "Save", UDim2.new(0,40,0,24), UDim2.new(1,-50,0,215), F_B, 14)
		local editing, selIdx = {}, nil
		local function refresh()
			for _, ch in ipairs(right:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
			for i, fd in ipairs(editing) do
				local b = create("TextButton", {Parent = right, Size = UDim2.new(1,0,0,20), BackgroundColor3 = (selIdx == i) and lighter(uiColor_ButtonColor, 40) or uiColor_ButtonColor, TextColor3 = uiColor_TextColor, Text = string.format("[%d] P:%s O:%s T:%s", i, fd.pos, fd.rot, tostring(fd.time)), Font = F_R, TextSize = 11, BorderSizePixel = 0})
				corner(b)
				b.MouseButton1Click:Connect(function()
					selIdx = i; edO.Text = fd.rot; edP.Text = fd.pos; edT.Text = tostring(fd.time); refresh()
				end)
			end
		end
		local function refreshDD()
			for _, ch in ipairs(loadDD:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
			local c = 0
			for name, d in pairs(savedDesyncAnimations) do
				if d.frames then
					c = c + 1
					local b = mkBtn(loadDD, name, UDim2.new(1,0,0,20), UDim2.new(0,0,0,0), F_R, 12)
					b.ZIndex = 6
					b.MouseButton1Click:Connect(function()
						local ld = savedDesyncAnimations[name]
						if ld and ld.frames and #ld.frames > 0 then
							editing = {}
							for _, fr in ipairs(ld.frames) do table.insert(editing, {rot=fr.rot, pos=fr.pos, time=fr.time or 1}) end
							edN.Text = name; refresh(); loadDD.Visible = false; loadBtn.Text = "Loaded: " .. name
						end
					end)
				end
			end
			loadDD.CanvasSize = UDim2.new(0,0,0, c*22)
		end
		loadBtn.MouseButton1Click:Connect(function() savedDesyncAnimations = loadDesyncAnims(); refreshDD(); loadDD.Visible = not loadDD.Visible end)
		addB.MouseButton1Click:Connect(function() table.insert(editing, {rot=edO.Text, pos=edP.Text, time=tonumber(edT.Text) or 1}); refresh() end)
		remB.MouseButton1Click:Connect(function() if selIdx and editing[selIdx] then table.remove(editing, selIdx); selIdx = nil; refresh() end end)
		editB.MouseButton1Click:Connect(function() if selIdx then editing[selIdx] = {rot=edO.Text, pos=edP.Text, time=tonumber(edT.Text) or 1}; refresh(); editB.Text="Updated!"; task.wait(0.3); editB.Text="Edit" end end)
		saveB.MouseButton1Click:Connect(function()
			if edN.Text ~= "" and #editing > 0 then
				savedDesyncAnimations[edN.Text] = { frames = editing }
				saveDesyncAnims(savedDesyncAnimations)
				saveB.Text = "Saved!"; task.wait(0.5); saveB.Text = "Save"
			end
		end)
		refresh()
	end

	--// 3. DESYNC ANIMATIONS
	local function buildDesyncAnimsTab(parent)
		local sf = create("ScrollingFrame", {Parent = parent, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0,0,0,260)})
		local inner = mkPanel(sf, UDim2.new(1,0,0,260))
		local ddBtn = mkBtn(inner, "Select Animation v", UDim2.new(1,-24,0,30), UDim2.new(0,12,0,10), F_B, 16)
		local ddList = mkListBG(inner, UDim2.new(1,-24,0,80), UDim2.new(0,12,0,42))
		ddList.ZIndex = 5
		create("UIListLayout", {Parent = ddList})
		local selected = nil
		local function updateDD()
			for _, ch in ipairs(ddList:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
			savedDesyncAnimations = loadDesyncAnims()
			local c = 0
			for name, d in pairs(savedDesyncAnimations) do
				if d.frames then
					c = c + 1
					local b = mkBtn(ddList, name, UDim2.new(1,0,0,22), UDim2.new(0,0,0,0), F_R, 14)
					b.ZIndex = 6
					b.MouseButton1Click:Connect(function()
						selected = name
						ddBtn.Text = name .. " v"
						ddList.Visible = false
					end)
				end
			end
			ddList.CanvasSize = UDim2.new(0,0,0, c*22)
		end
		ddBtn.MouseButton1Click:Connect(function() updateDD(); ddList.Visible = not ddList.Visible end)
		local loopBox = mkBtn(inner, "", UDim2.new(0,20,0,20), UDim2.new(0,12,0,87), F_B, 14, false)
		local looped = false
		loopBox.MouseButton1Click:Connect(function()
			looped = not looped
			loopBox.Text = looped and "X" or ""
			loopBox.TextColor3 = uiColor_TextColor
		end)
		mkLabel(inner, "Loop Animation", UDim2.new(1,-30,0,24), UDim2.new(0,42,0,85), F_S, 16)
		mkLabel(inner, "Speed:", UDim2.new(0,50,0,24), UDim2.new(0,12,0,115), F_S, 16)
		local spdIn = mkBox(inner, "1.0", UDim2.new(1,-67,0,24), UDim2.new(0,67,0,115), 16)
		local playBtn = mkBtn(inner, "Play", UDim2.new(0,90,0,30), UDim2.new(0,12,0,155), F_B, 16)
		local remBtn = mkBtn(inner, "Remove", UDim2.new(0,90,0,30), UDim2.new(1,-102,0,155), F_B, 16, "no")
		remBtn.BackgroundColor3 = C_REDD; remBtn.TextColor3 = C_WHT
		local playing = false
		playBtn.MouseButton1Click:Connect(function()
			if playing then
				stopDesyncAnim()
				playing = false
				playBtn.Text = "Play"
				return
			end
			if not selected or not savedDesyncAnimations[selected] then return end
			local sp = tonumber(spdIn.Text) or 1
			if sp <= 0 then sp = 1 end
			playing = true
			playBtn.Text = "Stop"
			playDesyncAnim(selected, looped, sp, false)
		end)
		remBtn.MouseButton1Click:Connect(function()
			if selected then
				savedDesyncAnimations[selected] = nil
				saveDesyncAnims(savedDesyncAnimations)
				selected = nil
				ddBtn.Text = "Select Animation v"
				updateDD()
			end
		end)
	end

	--// 4. ANIM MANAGER
	local function buildManagerTab(parent)
		local sf = create("ScrollingFrame", {Parent = parent, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0,0,0,500)})
		local inner = mkPanel(sf, UDim2.new(1,0,0,500))
		local cat, sub, search = "R6", "[Main]", ""
		local spd, looped, reversed, activeTrack = 1.0, false, false, nil
		local r6B = mkBtn(inner, "R6", UDim2.new(0.5,-6,0,26), UDim2.new(0,10,0,8), F_B, 16, "no")
		local r15B = mkBtn(inner, "R15", UDim2.new(0.5,-6,0,26), UDim2.new(0.5,2,0,8), F_B, 16, "no")
		local subDD = mkBtn(inner, "Category: [Main] v", UDim2.new(1,-95,0,24), UDim2.new(0,10,0,40), F_R, 14)
        local subList = mkListBG(inner, UDim2.new(1,-20,0,80), UDim2.new(0,10,0,66))
        subList.ZIndex = 10
        subList.Visible = false -- опционально: чтобы список не наезжал на New subcategory/Search, пока закрыт
        local subListLayout = create("UIListLayout", {Parent = subList})
        subListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        	subList.CanvasSize = UDim2.new(0, 0, 0, subListLayout.AbsoluteContentSize.Y + 4)
        end)
		local delSub = mkBtn(inner, "Del Sub", UDim2.new(0,70,0,24), UDim2.new(1,-80,0,40), F_B, 12, "no"); delSub.BackgroundColor3 = C_REDD; delSub.TextColor3 = C_WHT; delSub.Visible = false
		local newSub = mkBox(inner, "", UDim2.new(1,-90,0,22), UDim2.new(0,10,0,70), 14); newSub.PlaceholderText = "New subcategory..."
		local addSub = mkBtn(inner, "Add", UDim2.new(0,70,0,22), UDim2.new(1,-80,0,70), F_B, 14)
		local searchB = mkBox(inner, "", UDim2.new(1,-20,0,24), UDim2.new(0,10,0,100), 14); searchB.PlaceholderText = "Search..."
		local list = mkListBG(inner, UDim2.new(1,-20,0,200), UDim2.new(0,10,0,130))
		create("UIListLayout", {Parent = list, Padding = UDim.new(0,2)})
		local nameIn = mkBox(inner, "", UDim2.new(0.5,-12,0,24), UDim2.new(0,10,0,340), 14); nameIn.PlaceholderText = "Animation Name"
		local idIn = mkBox(inner, "", UDim2.new(0.5,-12,0,24), UDim2.new(0.5,2,0,340), 14); idIn.PlaceholderText = "Animation ID"
		local setP = mkPanel(inner, UDim2.new(1,-20,0,50), UDim2.new(0,10,0,370))
		mkLabel(setP, "Speed:", UDim2.new(0,45,0,20), UDim2.new(0,8,0,4), F_S, 14)
		local spdIn = mkBox(setP, "1.0", UDim2.new(0,40,0,18), UDim2.new(0,55,0,5), 14)
		spdIn.FocusLost:Connect(function()
			spd = tonumber(spdIn.Text) or 1
			if activeTrack and activeTrack.IsPlaying then activeTrack:AdjustSpeed(spd * (reversed and -1 or 1)) end
		end)
		local loopB = mkBtn(setP, "Loop: OFF", UDim2.new(0,80,0,20), UDim2.new(0,110,0,4), F_B, 13, false); loopB.TextColor3 = C_ROFF
		loopB.MouseButton1Click:Connect(function() looped = not looped; loopB.Text = looped and "Loop: ON" or "Loop: OFF"; loopB.TextColor3 = looped and C_GRN or C_ROFF; if activeTrack then activeTrack.Looped = looped end end)
		local revB = mkBtn(setP, "Reverse: OFF", UDim2.new(0,95,0,20), UDim2.new(1,-103,0,4), F_B, 13, false); revB.TextColor3 = C_ROFF
		revB.MouseButton1Click:Connect(function() reversed = not reversed; revB.Text = reversed and "Reverse: ON" or "Reverse: OFF"; revB.TextColor3 = reversed and C_GRN or C_ROFF; if activeTrack and activeTrack.IsPlaying then activeTrack:AdjustSpeed(spd * (reversed and -1 or 1)) end end)
		mkLabel(setP, "*Reverse changes direction on play/live adjust", UDim2.new(1,-16,0,16), UDim2.new(0,8,0,28), F_I, 12)
		local addAnim = mkBtn(inner, "Add Anim", UDim2.new(0.5,-12,0,30), UDim2.new(0,10,0,430), F_B, 16)
		local stopAnim = mkBtn(inner, "Stop Playing", UDim2.new(0.5,-12,0,30), UDim2.new(0.5,2,0,430), F_B, 16)
		local updateList, updateSubDD
		updateList = function()
			for _, ch in ipairs(list:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end
			local data = managerDataCache[cat]
			local target = (sub == "[Main]") and data or data._subcategories[sub]
			delSub.Visible = (sub ~= "[Main]")
			if not target then return end
			local c = 0
			for name, id in pairs(target) do
				if name ~= "_subcategories" and (search == "" or string.find(string.lower(name), string.lower(search), 1, true)) then
					c = c + 1
					local row = create("Frame", {Parent = list, Size = UDim2.new(1,0,0,26), BackgroundTransparency = 1})
					local pb = mkBtn(row, "▶ " .. name, UDim2.new(1,-30,1,0), UDim2.new(0,0,0,0), F_R, 14)
					pb.TextXAlignment = Enum.TextXAlignment.Left
					local db = mkBtn(row, "X", UDim2.new(0,26,1,0), UDim2.new(1,-26,0,0), F_B, 12, "no"); db.BackgroundColor3 = C_REDD; db.TextColor3 = C_WHT
					pb.MouseButton1Click:Connect(function()
						if activeTrack then activeTrack:Stop() end
						if desyncChar and desyncChar:FindFirstChildOfClass("Humanoid") then
							local clean = string.match(tostring(id), "%d+") or id
							local a = Instance.new("Animation"); a.AnimationId = "rbxassetid://" .. clean
							local hum = desyncChar:FindFirstChildOfClass("Humanoid")
							local an = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
							local ok, tr = pcall(function() return an:LoadAnimation(a) end)
							if ok and tr then activeTrack = tr; tr.Looped = looped; tr:Play(); tr:AdjustSpeed(spd * (reversed and -1 or 1)); if reversed then tr.TimePosition = tr.Length > 0 and tr.Length or 0.1 end end
						end
					end)
					db.MouseButton1Click:Connect(function() target[name] = nil; saveMgr(cat, data); updateList() end)
				end
			end
			list.CanvasSize = UDim2.new(0,0,0, c*28)
		end
		searchB:GetPropertyChangedSignal("Text"):Connect(function() search = searchB.Text; updateList() end)
		updateSubDD = function()
	        for _, ch in ipairs(subList:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
	        local count = 0
	        local function item(t)
    		    local b = mkBtn(subList, t, UDim2.new(1,0,0,22), UDim2.new(0,0,0,0), F_R, 14); b.ZIndex = 11
		        b.MouseButton1Click:Connect(function() sub = t; subDD.Text = "Category: " .. t .. " v"; subList.Visible = false; updateList() end)
    		    count = count + 1
	        end
	        item("[Main]")
	        for sn, _ in pairs(managerDataCache[cat]._subcategories or {}) do item(sn) end
	        -- высота подстраивается под кол-во пунктов (минимум 44, максимум 176px), остальное — скроллом
	        subList.Size = UDim2.new(1, -20, 0, math.clamp(count * 22 + 4, 44, 176))
        end
		local function selectCat(c2)
			cat = c2; sub = "[Main]"; subDD.Text = "Category: [Main] v"
			if c2 == "R6" then
				r6B.BackgroundColor3 = uiColor_ButtonColor; r6B.TextColor3 = Color3.fromRGB(255,255,255)
				r15B.BackgroundColor3 = darker(uiColor_ButtonColor, 15); r15B.TextColor3 = uiColor_TextColor
			else
				r15B.BackgroundColor3 = uiColor_ButtonColor; r15B.TextColor3 = Color3.fromRGB(255,255,255)
				r6B.BackgroundColor3 = darker(uiColor_ButtonColor, 15); r6B.TextColor3 = uiColor_TextColor
			end
			managerDataCache[c2] = loadMgr(c2); updateSubDD(); updateList()
		end
		r6B.MouseButton1Click:Connect(function() selectCat("R6") end)
		r15B.MouseButton1Click:Connect(function() selectCat("R15") end)
		subDD.MouseButton1Click:Connect(function() subList.Visible = not subList.Visible end)
		delSub.MouseButton1Click:Connect(function() if sub ~= "[Main]" then local d = managerDataCache[cat]; d._subcategories[sub] = nil; saveMgr(cat, d); sub = "[Main]"; subDD.Text = "Category: [Main] v"; updateSubDD(); updateList() end end)
		addSub.MouseButton1Click:Connect(function()
			local sn = newSub.Text
			if sn ~= "" and sn ~= "[Main]" then
				local d = managerDataCache[cat]
				if not d._subcategories[sn] then d._subcategories[sn] = {}; saveMgr(cat, d); newSub.Text = ""; updateSubDD() end
			end
		end)
		addAnim.MouseButton1Click:Connect(function()
			local n, id = nameIn.Text, idIn.Text
			if n ~= "" and id ~= "" then
				local clean = string.match(id, "%d+") or id
				local d = managerDataCache[cat]
				if sub == "[Main]" then d[n] = clean else d._subcategories[sub][n] = clean end
				saveMgr(cat, d); nameIn.Text = ""; idIn.Text = ""; updateList()
			end
		end)
		stopAnim.MouseButton1Click:Connect(function() if activeTrack then activeTrack:Stop(); activeTrack = nil end end)
		selectCat("R6")
	end

	--// 5. KEYBINDS
	local function buildKeybindsTab(parent)
		local sf = create("ScrollingFrame", {
			Parent = parent,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 4,
			CanvasSize = UDim2.new(0, 0, 0, 400)
		})
		local inner = mkPanel(sf, UDim2.new(1, 0, 0, 400))

		local curType, curAnimType, curBody = "Animations", "Desync", "R6"
		local selDesync, selNormal, tempDesync, tempNormal = nil, nil, nil, nil

		mkLabel(inner, "Category:", UDim2.new(0, 80, 0, 20), UDim2.new(0, 12, 0, 10), F_S, 16)
		local typeDD = mkBtn(inner, curType .. " v", UDim2.new(0, 150, 0, 24), UDim2.new(0, 100, 0, 8), F_R, 16)
		local typeList = mkListBG(inner, UDim2.new(0, 150, 0, 100), UDim2.new(0, 100, 0, 32))
		typeList.ZIndex = 15
		create("UIListLayout", { Parent = typeList })

		local refresh

		for _, cn in ipairs({ "Animations", "Desync", "Menu", "View all keybinds" }) do
			local b = mkBtn(typeList, cn, UDim2.new(1, 0, 0, 22), UDim2.new(0, 0, 0, 0), F_R, 14)
			b.ZIndex = 16
			b.MouseButton1Click:Connect(function()
				curType = cn
				typeDD.Text = cn .. " v"
				typeList.Visible = false
				refresh()
			end)
		end
		typeDD.MouseButton1Click:Connect(function()
			typeList.Visible = not typeList.Visible
		end)

		local function bindRow(y, getTemp, setTemp, onSave)
			local bindB = mkBtn(inner, "Bind: " .. (getTemp() or "None"), UDim2.new(0, 120, 0, 28), UDim2.new(0, 12, 0, y), F_B, 14)
			local saveB = mkBtn(inner, "Save Bind", UDim2.new(0, 100, 0, 28), UDim2.new(0, 140, 0, y), F_B, 14)

			bindB.MouseButton1Click:Connect(function()
				keybindWaitForInput = true
				bindB.Text = "Press any key..."
				onKeybindPressed = function(k)
					keybindWaitForInput = false
					if k then
						bindB.Text = "Bind: " .. k
						setTemp(k)
					else
						bindB.Text = "Bind: None"
						setTemp(nil)
					end
					onKeybindPressed = nil
				end
			end)

			saveB.MouseButton1Click:Connect(function()
				if onSave(saveB) then
					setTemp(nil)
					bindB.Text = "Bind: None"
				end
			end)
			return bindB, saveB
		end

		refresh = function()
			for _, ch in ipairs(inner:GetChildren()) do
				if ch ~= typeDD and ch ~= typeList then ch:Destroy() end
			end
			mkLabel(inner, "Category:", UDim2.new(0, 80, 0, 20), UDim2.new(0, 12, 0, 10), F_S, 16)
			local y = 40

			if curType == "Animations" then
				mkLabel(inner, "Animation type:", UDim2.new(0, 120, 0, 20), UDim2.new(0, 12, 0, y), F_S, 16)
				local atDD = mkBtn(inner, curAnimType .. " v", UDim2.new(0, 120, 0, 24), UDim2.new(0, 140, 0, y - 2), F_R, 16)
				local atList = mkListBG(inner, UDim2.new(0, 120, 0, 50), UDim2.new(0, 140, 0, y + 24))
				atList.ZIndex = 10
				create("UIListLayout", { Parent = atList })

				for _, t in ipairs({ "Desync", "Normal" }) do
					local b = mkBtn(atList, t, UDim2.new(1, 0, 0, 22), UDim2.new(0, 0, 0, 0), F_R, 14)
					b.ZIndex = 11
					b.MouseButton1Click:Connect(function()
						curAnimType = t
						atDD.Text = t .. " v"
						atList.Visible = false
						refresh()
					end)
				end
				atDD.MouseButton1Click:Connect(function() atList.Visible = not atList.Visible end)
				y = y + 32

				local selLbl = nil
				local sBox = mkBox(inner, "", UDim2.new(1, -24, 0, 24), UDim2.new(0, 12, 0, y), 14)
				sBox.PlaceholderText = "Search animation..."
				y = y + 28

				local aList = mkListBG(inner, UDim2.new(1, -24, 0, 90), UDim2.new(0, 12, 0, y))
				create("UIListLayout", { Parent = aList, Padding = UDim.new(0, 2) })

				local function updateDL(filter)
					for _, ch in ipairs(aList:GetChildren()) do
						if ch:IsA("TextButton") then ch:Destroy() end
					end
					local c = 0
					local pool = {}
					if curAnimType == "Desync" then
						for n, d in pairs(savedDesyncAnimations) do
							if d.frames then pool[n] = true end
						end
					else
						local data = managerDataCache[curBody] or {}
						for n, _ in pairs(data) do
							if n ~= "_subcategories" then pool[n] = true end
						end
						for _, st in pairs(data._subcategories or {}) do
							for n, _ in pairs(st) do pool[n] = true end
						end
					end
					for n, _ in pairs(pool) do
						if filter == "" or string.find(string.lower(n), string.lower(filter), 1, true) then
							c = c + 1
							local isSel = (curAnimType == "Desync" and selDesync == n) or (curAnimType ~= "Desync" and selNormal == n)
							local b = create("TextButton", {
								Parent = aList,
								Size = UDim2.new(1, 0, 0, 22),
								BackgroundColor3 = isSel and lighter(uiColor_ButtonColor, 40) or uiColor_ButtonColor,
								TextColor3 = uiColor_TextColor,
								Text = n,
								Font = F_R,
								TextSize = 14,
								BorderSizePixel = 0
							})
							corner(b)
							b.TextXAlignment = Enum.TextXAlignment.Left
							b.MouseButton1Click:Connect(function()
								if curAnimType == "Desync" then selDesync = n else selNormal = n end
								updateDL(sBox.Text)
								if selLbl then selLbl.Text = "Selected: " .. n end
							end)
						end
					end
					aList.CanvasSize = UDim2.new(0, 0, 0, c * 24)
				end

				sBox:GetPropertyChangedSignal("Text"):Connect(function() updateDL(sBox.Text) end)
				selLbl = mkLabel(inner, "Selected: none", UDim2.new(1, -24, 0, 20), UDim2.new(0, 12, 0, y + 95), F_S, 14)
				y = y + 120

				if curAnimType == "Desync" then
					bindRow(y,
						function() return tempDesync end,
						function(v) tempDesync = v end,
						function(saveB)
							if tempDesync and selDesync then
								keybinds.Animations = keybinds.Animations or {}
								table.insert(keybinds.Animations, { key = tempDesync, type = "Desync", animName = selDesync, speed = 1, looped = false, reversed = false })
								saveKeys(keybinds)
								saveB.Text = "Saved!"
								task.wait(0.5)
								saveB.Text = "Save Bind"
								return true
							else
								saveB.Text = "Error: Key & Anim"
								task.wait(1)
								saveB.Text = "Save Bind"
								return false
							end
						end)
				else
					mkLabel(inner, "Body type:", UDim2.new(0, 100, 0, 20), UDim2.new(0, 260, 0, y - 32), F_S, 14)
					bindRow(y,
						function() return tempNormal end,
						function(v) tempNormal = v end,
						function(saveB)
							if tempNormal and selNormal then
								keybinds.Animations = keybinds.Animations or {}
								table.insert(keybinds.Animations, { key = tempNormal, type = "Normal", animName = selNormal, bodyType = curBody, speed = 1, looped = false, reversed = false })
								saveKeys(keybinds)
								saveB.Text = "Saved!"
								task.wait(0.5)
								saveB.Text = "Save Bind"
								return true
							else
								saveB.Text = "Error: Key & Anim"
								task.wait(1)
								saveB.Text = "Save Bind"
								return false
							end
						end)
				end
				updateDL("")

			elseif curType == "Desync" or curType == "Menu" then
				mkLabel(inner, curType == "Desync" and "Toggle Desync mode" or "Show/Hide Main Menu", UDim2.new(1, -24, 0, 20), UDim2.new(0, 12, 0, y), F_S, 16)
				y = y + 28
				local curKey = (curType == "Desync") and (keybinds.Desync and keybinds.Desync.key) or (keybinds.Menu and keybinds.Menu.key)
				local bindB = mkBtn(inner, "Bind: " .. (curKey or "None"), UDim2.new(0, 120, 0, 28), UDim2.new(0, 12, 0, y), F_B, 14)
				local saveB = mkBtn(inner, "Save Bind", UDim2.new(0, 100, 0, 28), UDim2.new(0, 140, 0, y), F_B, 14)

				bindB.MouseButton1Click:Connect(function()
					keybindWaitForInput = true
					bindB.Text = "Press any key..."
					onKeybindPressed = function(k)
						keybindWaitForInput = false
						if k then
							bindB.Text = "Bind: " .. k
							if curType == "Desync" then
								keybinds.Desync = keybinds.Desync or {}
								keybinds.Desync.key = k
							else	
								keybinds.Menu = keybinds.Menu or {}
								keybinds.Menu.key = k
							end
						else
							bindB.Text = "Bind: None"
						end
						onKeybindPressed = nil
					end
				end)
				saveB.MouseButton1Click:Connect(function()
					saveKeys(keybinds)
					saveB.Text = "Saved!"
					task.wait(0.5)
					saveB.Text = "Save Bind"
				end)

			elseif curType == "View all keybinds" then
				mkLabel(inner, "Assigned Keybinds:", UDim2.new(1, -24, 0, 20), UDim2.new(0, 12, 0, y), F_S, 16)
				y = y + 24
				local scroll = mkListBG(inner, UDim2.new(1, -24, 0, 280), UDim2.new(0, 12, 0, y))
				create("UIListLayout", { Parent = scroll, Padding = UDim.new(0, 4) })

				local all = {}
				if keybinds.Desync and keybinds.Desync.key then
					table.insert(all, { type = "Desync", key = keybinds.Desync.key, path = { "Desync" }, data = keybinds.Desync })
				end
				if keybinds.Menu and keybinds.Menu.key then
					table.insert(all, { type = "Menu", key = keybinds.Menu.key, path = { "Menu" }, data = keybinds.Menu })
				end
				for i, b in ipairs(keybinds.Animations or {}) do
					if b.key then
						table.insert(all, { type = "Anim " .. b.type, key = b.key, animName = b.animName, bodyType = b.bodyType, path = { "Animations", i }, data = b })
					end
				end

				local th = 0
				for _, kb in ipairs(all) do
					local rh = kb.type:find("Anim") and 46 or 24
					local row = create("Frame", { Parent = scroll, Size = UDim2.new(1, -10, 0, rh), BackgroundColor3 = uiColor_ButtonColor, BorderSizePixel = 0 })
					table.insert(themeElements.Buttons, row)
					corner(row)

					local desc = string.format("%s [%s]", kb.type, kb.key)
					if kb.animName then
						desc = desc .. " -> " .. kb.animName .. (kb.bodyType and (" (" .. kb.bodyType .. ")") or "")
					end
					local dl = mkLabel(row, desc, UDim2.new(1, -60, 0, 20), UDim2.new(0, 5, 0, 2), F_R, 14)
					dl.TextTruncate = Enum.TextTruncate.AtEnd

					local del = mkBtn(row, "Delete", UDim2.new(0, 50, 0, 18), UDim2.new(1, -55, 0, 3), F_B, 12, "no")
					del.BackgroundColor3 = C_REDD
					del.TextColor3 = C_WHT
					del.MouseButton1Click:Connect(function()
						local t = keybinds
						for i = 1, #kb.path - 1 do
							t = t[kb.path[i]]
						end
						local lk = kb.path[#kb.path]
						if type(lk) == "number" then table.remove(t, lk) else t[lk] = nil end
						saveKeys(keybinds)
						refresh()
					end)

					if kb.type:find("Anim") then
						mkLabel(row, "Spd:", UDim2.new(0, 30, 0, 18), UDim2.new(0, 5, 0, 24), F_R, 12)
						local si = mkBox(row, tostring(kb.data.speed or 1), UDim2.new(0, 35, 0, 18), UDim2.new(0, 35, 0, 24), 12)
						si.FocusLost:Connect(function()
							local v = tonumber(si.Text)
							if v then
								kb.data.speed = v
								saveKeys(keybinds)
							end
						end)

						local lb = mkBtn(row, "Loop", UDim2.new(0, 45, 0, 18), UDim2.new(0, 75, 0, 24), F_B, 12, false)
						local ls = kb.data.looped or false
						lb.TextColor3 = ls and C_GRN or C_ROFF
						lb.MouseButton1Click:Connect(function()
							ls = not ls
							kb.data.looped = ls
							lb.TextColor3 = ls and C_GRN or C_ROFF
							saveKeys(keybinds)
						end)

						local rb = mkBtn(row, "Rev", UDim2.new(0, 45, 0, 18), UDim2.new(0, 125, 0, 24), F_B, 12, false)
						local rs = kb.data.reversed or false
						rb.TextColor3 = rs and C_GRN or C_ROFF
						rb.MouseButton1Click:Connect(function()
							rs = not rs
							kb.data.reversed = rs
							rb.TextColor3 = rs and C_GRN or C_ROFF
							saveKeys(keybinds)
						end)
					end
					th = th + rh + 4
				end
				scroll.CanvasSize = UDim2.new(0, 0, 0, th)
			end
		end
		refresh()
	end

	--// 6. ANIM LOGGER
	local loggedAnims = {}
	local refreshLoggerList = nil
	local function trackAnimator(an)
	    an.AnimationPlayed:Connect(function(tr)
    		if not isRunning then return end
		    if not DesyncSectionEnabled then return end
			local id, nm = nil, nil
			pcall(function() id = tr.Animation.AnimationId end)
			pcall(function() nm = tr.Animation.Name end)
			if not id or id == "" then return end
			for _, e in ipairs(loggedAnims) do
				if e.id == id then return end
			end
			table.insert(loggedAnims, 1, { id = id, name = (nm and nm ~= "") and nm or "Unknown" })
			while #loggedAnims > 20 do table.remove(loggedAnims) end
			if refreshLoggerList then refreshLoggerList() end
		end)
	end
	local function buildLoggerTab(parent)
		local sf = create("ScrollingFrame", { Parent = parent, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0,0,0,300) })
		local inner = mkPanel(sf, UDim2.new(1,0,0,300))
		mkLabel(inner, "Anim Logger (click to copy link):", UDim2.new(1,-24,0,20), UDim2.new(0,12,0,8), F_S, 16)
		local list = mkListBG(inner, UDim2.new(1,-24,1,-40), UDim2.new(0,12,0,34))
		local lay = create("UIListLayout", { Parent = list, Padding = UDim.new(0,2) })
		lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			list.CanvasSize = UDim2.new(0,0,0, lay.AbsoluteContentSize.Y + 4)
		end)
		refreshLoggerList = function()
			for _, ch in ipairs(list:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
			for _, e in ipairs(loggedAnims) do
				local b = mkBtn(list, e.id .. " - " .. e.name, UDim2.new(1,0,0,24), UDim2.new(0,0,0,0), F_R, 12)
				b.TextXAlignment = Enum.TextXAlignment.Left
				b.TextTruncate = Enum.TextTruncate.AtEnd
				b.MouseButton1Click:Connect(function()
					if setclipboard then setclipboard(e.id) end
					notify("Anim Logger", "Copied: " .. e.id)
				end)
			end
		end
		refreshLoggerList()
	end

	--// Регистрация в боковом меню
	local desyncTabs = {}
	local function addDesyncTab(name, builder)
		local frame = create("Frame", { Name = "Tab" .. name, Parent = Containment, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false })
		builder(frame)
		local btn = create("TextButton", {
			Name = "DBtn_" .. name, Parent = MenuInsided,
			Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 100 + #desyncTabs, Visible = false,
			BackgroundColor3 = uiColor_ButtonColor, BorderColor3 = COL_BORDER,
			TextColor3 = uiColor_TextColor, Text = name, Font = FONT, TextSize = 12,
			TextWrapped = true
		})
		local entry = { Frame = frame, Name = name, Button = btn }
		table.insert(desyncTabs, entry)
		table.insert(themeElements.Buttons, btn)
		table.insert(themeElements.Texts, btn)
		return entry
	end
	addDesyncTab("Desync", buildDesyncTab)
	addDesyncTab("Desync Anim Editor", buildEditorTab)
	addDesyncTab("Desync Animations", buildDesyncAnimsTab)
	addDesyncTab("Anim Manager", buildManagerTab)
	addDesyncTab("Keybinds", buildKeybindsTab)
	addDesyncTab("Anim Logger", buildLoggerTab)

	local baseUpdateTabTheme = updateTabButtonsTheme
	updateTabButtonsTheme = function()
		baseUpdateTabTheme()
		for _, tab in ipairs(desyncTabs) do
			if tab.Button then
				if tab.Frame.Visible then
					tab.Button.BackgroundColor3 = uiColor_ButtonColor
					tab.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
				else
					tab.Button.BackgroundColor3 = darker(uiColor_ButtonColor, 10)
					tab.Button.TextColor3 = uiColor_TextColor
				end
			end
		end
	end

	local function onChar(char)
		desyncChar = char
		local hum = char:WaitForChild("Humanoid", 5)
		if hum then
			if CharDeathConn then CharDeathConn:Disconnect() end
			CharDeathConn = hum.Died:Connect(stopDesync)
		end
		if IsDesynced then stopDesync(); task.wait(0.15); startDesync() end
		local h2 = char:WaitForChild("Humanoid", 10)
		if h2 then
			local an = h2:WaitForChild("Animator", 10)
			if an then trackAnimator(an) end
		end
	end
	LocalPlayer.CharacterAdded:Connect(onChar)
	if LocalPlayer.Character then onChar(LocalPlayer.Character) end

	task.defer(function()
		local function hideAllFrames()
			for _, t in ipairs(tabs) do t.Frame.Visible = false end
			for _, t in ipairs(desyncTabs) do t.Frame.Visible = false end
		end
		local function showMainButtons()
			for _, t in ipairs(tabs) do if t.Button then t.Button.Visible = true end end
			for _, t in ipairs(desyncTabs) do t.Button.Visible = false end
		end
		local function showDesyncButtons()
			for _, t in ipairs(tabs) do if t.Button then t.Button.Visible = false end end
			for _, t in ipairs(desyncTabs) do t.Button.Visible = true end
		end
		for _, t in ipairs(desyncTabs) do
			t.Button.MouseButton1Click:Connect(function()
				hideAllFrames()
				t.Frame.Visible = true
				updateTabButtonsTheme()
			end)
		end
		for _, t in ipairs(tabs) do
			if t.Button then
				t.Button.MouseButton1Click:Connect(function()
					for _, d in ipairs(desyncTabs) do d.Frame.Visible = false end
					updateTabButtonsTheme()
				end)
			end
		end
		EmilyUi.MouseButton1Click:Connect(function()
			showMainButtons()
			hideAllFrames()
			if tabs[1] then tabs[1].Frame.Visible = true end
			updateTabButtonsTheme()
		end)
		Desync.MouseButton1Click:Connect(function()
			showDesyncButtons()
			hideAllFrames()
			if desyncTabs[1] then desyncTabs[1].Frame.Visible = true end
			updateTabButtonsTheme()
		end)
	end)

	return desyncTabs
	end   -- ← этот end закрывает initDesyncModule

local desyncTabs = initDesyncModule()

-- =========================================================
-- ========== MUSIC MODULE =================================
-- =========================================================
local function initMusicModule(desyncTabs)
	local SoundService = game:GetService("SoundService")
	local F_R = Enum.Font.SourceSans
	local F_B = Enum.Font.SourceSansBold
	local F_S = Enum.Font.SourceSansSemibold

	local FOLDER = "EmilyUi/Music"
	local FILE_MUSIC = FOLDER .. "/EmilyUiMusic.json"
	local FILE_SETTINGS = FOLDER .. "/EmilyUiMusicSettings.json"
	local FILE_GRABBER = FOLDER .. "/EmilyUiMusicGrabber.json"
	local FILE_BLACKLIST = FOLDER .. "/EmilyUiMusicGrabberBlackList.json"

	local function ensureDirs()
		if makefolder then pcall(function()
			if not isfolder("EmilyUi") then makefolder("EmilyUi") end
			if not isfolder(FOLDER) then makefolder(FOLDER) end
		end) end
	end
	local function saveJson(path, data)
		if writefile then ensureDirs()
			local ok, enc = pcall(function() return HttpService:JSONEncode(data) end)
			if ok then writefile(path, enc) end
		end
	end
	local function loadJson(path)
		if readfile and isfile and isfile(path) then
			local ok, dec = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
			if ok and type(dec) == "table" then return dec end
		end
	end

	local ScriptActive = true
	local ToggleState = false -- ВЫКЛЮЧЕНО при запуске

	local Settings = {
		Body = 0, Angle = 25, Goal = 0.30, Split = 1,
		Parts = 2, Disposition = 3, Power = 400,
		Material = "Neon", Rainbow = true,
		StaticColor = Color3.new(1, 1, 1), Transparency = 0
	}
	local DataStructure = { Categories = { ["Default"] = {} } }
	local grabbedIds = {}
	local blacklistedIds = {}

	local function saveSettings()
		saveJson(FILE_SETTINGS, {
			Body = Settings.Body, Angle = Settings.Angle, Goal = Settings.Goal,
			Split = Settings.Split, Parts = Settings.Parts, Disposition = Settings.Disposition,
			Power = Settings.Power, Material = Settings.Material, Rainbow = Settings.Rainbow,
			Transparency = Settings.Transparency,
			StaticColor = {Settings.StaticColor.R*255, Settings.StaticColor.G*255, Settings.StaticColor.B*255}
		})
	end
	local function loadSettings()
		local d = loadJson(FILE_SETTINGS)
		if not d then return end
		Settings.Body = d.Body or Settings.Body
		Settings.Angle = d.Angle or Settings.Angle
		Settings.Goal = d.Goal or Settings.Goal
		Settings.Split = d.Split or Settings.Split
		Settings.Parts = d.Parts or Settings.Parts
		Settings.Disposition = d.Disposition or Settings.Disposition
		Settings.Power = d.Power or Settings.Power
		Settings.Material = d.Material or Settings.Material
		if d.Rainbow ~= nil then Settings.Rainbow = d.Rainbow end
		Settings.Transparency = d.Transparency or Settings.Transparency
		if d.StaticColor then Settings.StaticColor = Color3.fromRGB(d.StaticColor[1], d.StaticColor[2], d.StaticColor[3]) end
	end
	local function saveMusicData() saveJson(FILE_MUSIC, DataStructure) end
	local function loadMusicData()
		local d = loadJson(FILE_MUSIC)
		if d and d.Categories then DataStructure = d else saveMusicData() end
	end
	local function saveGrabber() saveJson(FILE_GRABBER, grabbedIds) end
	local function saveBlacklist()
		local arr = {}
		for id, _ in pairs(blacklistedIds) do table.insert(arr, id) end
		saveJson(FILE_BLACKLIST, arr)
	end
	local function loadGrabber()
		local d = loadJson(FILE_GRABBER); if d then grabbedIds = d end
		local b = loadJson(FILE_BLACKLIST)
		if b then for _, id in ipairs(b) do blacklistedIds[tonumber(id) or id] = true end end
	end

	loadMusicData(); loadSettings(); loadGrabber()

	-- Цвета в стиле WdymGaming
	local C_BG = Color3.fromRGB(31, 31, 31)
	local C_BORDER = Color3.fromRGB(60, 60, 60)
	local C_TEXT = Color3.fromRGB(200, 200, 200)
	local C_TEXT2 = Color3.fromRGB(220, 220, 220)
	local C_SEL = Color3.fromRGB(50, 50, 80)
	local C_GRN = Color3.fromRGB(100, 220, 100)
	local C_RED = Color3.fromRGB(220, 100, 100)
	local C_DARKGRN = Color3.fromRGB(40, 70, 40)
	local C_DARKRED = Color3.fromRGB(70, 40, 40)
	local C_DARKBLUE = Color3.fromRGB(40, 55, 70)

	local function corner(p) Instance.new("UICorner", p).CornerRadius = UDim.new(0, 4) end
 	local function lighter(c, amt)
	 	return Color3.fromRGB(math.min(c.R*255+amt,255), math.min(c.G*255+amt,255), math.min(c.B*255+amt,255))
 	end
 	local brokenIds = {}
	local function mkPanel(p, sz, pos)
    	local f = Instance.new("Frame"); f.Parent = p
    	f.Size = sz; f.Position = pos or UDim2.new(0,0,0,0)
    	f.BackgroundColor3 = uiColor_SideBar; f.BorderSizePixel = 0
    	f.ClipsDescendants = true   -- ← добавить
    	table.insert(themeElements.SideBars, f); return f
	end
	local function mkBox(p, txt, sz, pos, ph, ts)
		local b = Instance.new("TextBox"); b.Parent = p
		b.Size = sz; b.Position = pos or UDim2.new(0,0,0,0)
		b.Font = F_R; b.TextSize = ts or 14; b.Text = txt or ""
		b.PlaceholderText = ph or ""
		b.BackgroundColor3 = uiColor_TextBoxColor; b.TextColor3 = uiColor_TextColor
		b.PlaceholderColor3 = Color3.fromRGB(90,90,90)
		b.BorderSizePixel = 0; b.ClearTextOnFocus = false
		table.insert(themeElements.TextBoxes, b)
		table.insert(themeElements.Texts, b)
		corner(b); return b
	end
	local function mkLabel(p, txt, sz, pos, font, ts, col, ta)
		local l = Instance.new("TextLabel"); l.Parent = p
		l.Size = sz; l.Position = pos or UDim2.new(0,0,0,0)
		l.Font = font or F_S; l.TextSize = ts or 14
		l.Text = txt or ""; l.TextColor3 = col or uiColor_TextColor
		l.BackgroundTransparency = 1
		if ta then l.TextXAlignment = ta end
		table.insert(themeElements.Texts, l); return l
	end
	local function mkBtn(p, txt, sz, pos, font, ts, themed, bg, tc)
		local b = Instance.new("TextButton"); b.Parent = p
		b.Size = sz; b.Position = pos or UDim2.new(0,0,0,0)
		b.Font = font or F_B; b.TextSize = ts or 14
		b.Text = txt or ""; b.TextWrapped = true
		b.BackgroundColor3 = bg or uiColor_ButtonColor
		b.TextColor3 = tc or uiColor_TextColor
		b.BorderColor3 = C_BORDER; b.BorderSizePixel = 1
		if themed ~= "no" then
    		table.insert(themeElements.Buttons, b)
    		table.insert(themeElements.Texts, b)
		else
    		table.insert(themeElements.CustomButtons, b)   -- новое
		end
		b.BackgroundTransparency = 1 - uiGuiOpacity        -- новое: списки пересозаются динамически,
		corner(b); return b                                -- чтобы новые кнопки сразу брали текущую прозрачность
	end

	--// Звук и частицы
	local musicSound = nil
	local Parts = Instance.new("Model"); Parts.Name = "MusicParts"
	local timelineLoop = nil
	local isInteractingWithSlider = false

	local function getRoot()
	 	return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
 	end
 	local function updatePartsParent()
	 	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
	 		Parts.Parent = LocalPlayer.Character
 		else
 			Parts.Parent = workspace
	 	end
 	end
 	local function rebuildParts(n)
 		Settings.Parts = tonumber(n) or 2
 		Parts:ClearAllChildren()
 		if ToggleState then updatePartsParent() end
 		local root = getRoot()
 		if not root or not ToggleState then return end
		for i = 1, Settings.Parts do
			local p = Instance.new("Part", Parts)
			p.Color = Settings.StaticColor
			p.Transparency = Settings.Transparency
			p.Anchored = true; p.CanCollide = false
			p.Material = Enum.Material[Settings.Material] or Enum.Material.Neon
			p.Size = Vector3.new(0.2, 0.2, 0.2)
			p.CFrame = root.CFrame * CFrame.new(0, Settings.Body, 0)
			p.Locked = true
		end
	end
	local function makeMusicSound(id)
		local s = Instance.new("Sound", ScreenGui)
		s.Name = "Music"; s.SoundId = "rbxassetid://" .. (id or "1")
		s.Looped = true; s.PlaybackSpeed = 1; s.Volume = 1
		return s
	end

	-- Ссылки на элементы Home (для timeline)
	local soundIdBox, volumeBox, pitchBox, playingLabel
	local timePosLabel, timeLenLabel, lineProgress
	local currentSelectedId = ""
	local currentCategory = "Default"

	local function runTimelineLoop()
		if timelineLoop then task.cancel(timelineLoop) end
		timelineLoop = task.spawn(function()
			while ScriptActive do
				if ToggleState and musicSound and musicSound.Parent and musicSound.IsPlaying and not isInteractingWithSlider then
					local tracks = DataStructure.Categories[currentCategory] or {}
					local cur = tracks[currentSelectedId]
					if cur and tonumber(cur.end_time) and cur.end_time > 0 then
						if musicSound.TimePosition >= cur.end_time then
							musicSound.TimePosition = cur.start_time or 0
						end
					end
					if timePosLabel and musicSound.TimeLength > 0 then
						lineProgress.Size = UDim2.new(math.clamp(musicSound.TimePosition / musicSound.TimeLength, 0, 1), 0, 0, 6)
						timeLenLabel.Text = string.format("%02i:%02i", math.floor(musicSound.TimeLength/60)%60, math.floor(musicSound.TimeLength)%60)
						timePosLabel.Text = string.format("%02i:%02i", math.floor(musicSound.TimePosition/60)%60, math.floor(musicSound.TimePosition)%60)
					end
				end
				task.wait(0.3)
			end
		end)
	end

	local Rad, mRad, LastB, LastL = 0, math.random(0, 100), 0, 0
	RunService:BindToRenderStep("musicVisualRender", 0, function()
		if not ScriptActive or not ToggleState then return end
		local loudness = (musicSound and musicSound.Parent) and musicSound.PlaybackLoudness or 0
		local target = Settings.StaticColor
		local beat = math.abs(math.floor(loudness) - LastL)
		if beat > LastB then LastB = beat else LastB = math.max(0, LastB - 10) end
		mRad = (mRad + beat / 250) % 100
		LastL = math.floor(loudness)
		if Settings.Rainbow then
			target = Color3.fromHSV(mRad / 200, 1, math.min(1 + LastB / 9e5, 10))
		end
		for _, c in ipairs(Parts:GetChildren()) do
			if c:IsA("BasePart") then c.Color = target end
		end
	end)

	task.spawn(function()
		while ScriptActive do
			task.wait()
			if ToggleState then
				local root = getRoot()
				if root then
					Rad = (Rad + 1) % 360
					for i, v in ipairs(Parts:GetChildren()) do
						if v:IsA("BasePart") then
							local sideCount = Settings.Parts > 0 and Settings.Parts or 1
							local splitVal = Settings.Split > 0 and Settings.Split or 1
							local goalVal = Settings.Goal > 0 and Settings.Goal or 0.3
							pcall(function()
								v.CFrame = v.CFrame:Lerp(
									CFrame.new(root.CFrame.X, root.CFrame.Y + Settings.Body, root.CFrame.Z)
									* CFrame.Angles(0, math.rad((360 / sideCount) * ((i + (i * Settings.Angle)) / splitVal) + Rad), 0)
									* CFrame.new(0, 0, Settings.Disposition + v.Size.Z),
									goalVal)
							end)
						end
					end
				end
			end
		end
	end)

	RunService.Heartbeat:Connect(function()
		if not ToggleState then return end
		local loudness = (musicSound and musicSound.Parent) and musicSound.PlaybackLoudness or 0
		local pList = Parts:GetChildren()
		if #pList > 0 and loudness > 0 then
			local powerVal = Settings.Power > 0 and Settings.Power or 1
			local goalVal = Settings.Goal > 0 and Settings.Goal or 0.3
			for _, v in ipairs(pList) do
				if v:IsA("BasePart") then
					pcall(function()
						v.Size = v.Size:Lerp(Vector3.new(0.8, 0.2, (loudness / powerVal) * math.random(4, 8)), goalVal)
					end)
				end
			end
		end
	end)
	LocalPlayer.CharacterAdded:Connect(function()
 		if ToggleState then
 			task.wait(0.1)
 			updatePartsParent()
 			rebuildParts(Settings.Parts)
 		end
 	end)
	--// Вкладки
	local musicTabs = {}
	local toggleStateBtn
	local updateMusicList, updateCategoryList, updateGrabberList
	local materialBtnRef

	local function addMusicTab(name, builder)
		local frame = create("Frame", {Name = "Tab" .. name, Parent = Containment, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false})
		builder(frame)
		local btn = create("TextButton", {
			Name = "MBtn_" .. name, Parent = MenuInsided,
			Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 200 + #musicTabs, Visible = false,
			BackgroundColor3 = uiColor_ButtonColor, BorderColor3 = COL_BORDER,
			TextColor3 = uiColor_TextColor, Text = name, Font = FONT, TextSize = 12,
			TextWrapped = true
		})
		local entry = {Frame = frame, Name = name, Button = btn}
		table.insert(musicTabs, entry)
		table.insert(themeElements.Buttons, btn)
		table.insert(themeElements.Texts, btn)
		return entry
	end

	--// 1. HOME
	local function buildHome(parent)
		local inner = mkPanel(parent, UDim2.new(1,0,1,0))
		mkLabel(inner, "HOME", UDim2.new(1,-20,0,24), UDim2.new(0,10,0,8), F_S, 18)
		soundIdBox = mkBox(inner, "", UDim2.new(1,-20,0,30), UDim2.new(0,10,0,38), "Sound ID", 16)
		local playBtn = mkBtn(inner, "PLAY", UDim2.new(0.23,-8,0,30), UDim2.new(0,10,0,76), F_S, 14, false, C_BG, C_TEXT)
		volumeBox = mkBox(inner, "1", UDim2.new(0.23,-8,0,30), UDim2.new(0.25,4,0,76), "Volume", 14)
		pitchBox = mkBox(inner, "1", UDim2.new(0.23,-8,0,30), UDim2.new(0.5,4,0,76), "Pitch", 14)
		local stopBtn = mkBtn(inner, "STOP", UDim2.new(0.23,-8,0,30), UDim2.new(0.75,4,0,76), F_S, 14, false, C_BG, C_TEXT)

		local sp = create("Frame", {Parent = inner, Size = UDim2.new(1,-20,0,35), Position = UDim2.new(0,10,0,120), BackgroundTransparency = 1})
		timePosLabel = mkLabel(sp, "0:00", UDim2.new(0,45,0,20), UDim2.new(0,0,0,5), F_S, 14)
		timeLenLabel = mkLabel(sp, "0:00", UDim2.new(0,45,0,20), UDim2.new(1,-45,0,5), F_S, 14, nil, Enum.TextXAlignment.Right)
		local line = Instance.new("TextButton"); line.Parent = sp
		line.BackgroundColor3 = uiColor_TextBoxColor; line.BorderSizePixel = 0
		line.Position = UDim2.new(0,50,0,10); line.Size = UDim2.new(1,-100,0,6)
		line.Text = ""; table.insert(themeElements.TextBoxes, line); corner(line)
		lineProgress = create("Frame", {Parent = line, Size = UDim2.new(0,0,0,6), Position = UDim2.new(0,0,0,0), BackgroundColor3 = uiColor_TextColor, BorderSizePixel = 0})
		playingLabel = mkLabel(sp, "Script Disabled", UDim2.new(1,-100,0,15), UDim2.new(0,50,0,20), F_S, 12)
		playingLabel.TextWrapped = true

		toggleStateBtn = mkBtn(inner, "TOGGLE: OFF", UDim2.new(1,-20,0,30), UDim2.new(0,10,0,165), F_S, 14, "no", C_DARKRED, C_RED)

		local function sliderToMouse()
			if not musicSound or musicSound.TimeLength <= 0 or not ToggleState then return end
			local mousePos = UserInputService:GetMouseLocation()
			local rel = mousePos.X - line.AbsolutePosition.X
			local pct = math.clamp(rel / line.AbsoluteSize.X, 0, 1)
			lineProgress.Size = UDim2.new(pct, 0, 0, 6)
			musicSound.TimePosition = musicSound.TimeLength * pct
		end
		line.MouseButton1Down:Connect(function() isInteractingWithSlider = true; sliderToMouse() end)
		UserInputService.InputChanged:Connect(function(input)
			if isInteractingWithSlider and input.UserInputType == Enum.UserInputType.MouseMovement then sliderToMouse() end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then isInteractingWithSlider = false end
		end)

		playBtn.MouseButton1Click:Connect(function()
			if not ToggleState then return end
			if not musicSound or musicSound.Parent ~= ScreenGui then
				musicSound = makeMusicSound(soundIdBox.Text ~= "" and soundIdBox.Text or "1")
				runTimelineLoop()
			end
			musicSound.SoundId = "rbxassetid://" .. (soundIdBox.Text ~= "" and soundIdBox.Text or "1")
			musicSound.Volume = tonumber(volumeBox.Text) or 1
			musicSound.PlaybackSpeed = tonumber(pitchBox.Text) or 1
			musicSound.TimePosition = 0
			musicSound:Play()
			playingLabel.Text = "Playing ID: " .. soundIdBox.Text
		end)
		stopBtn.MouseButton1Click:Connect(function() if musicSound then musicSound:Stop() end end)

		toggleStateBtn.MouseButton1Click:Connect(function()
			ToggleState = not ToggleState
			if ToggleState then
				toggleStateBtn.Text = "TOGGLE: ON"; toggleStateBtn.TextColor3 = C_GRN; toggleStateBtn.BackgroundColor3 = C_DARKGRN
				rebuildParts(Settings.Parts)
				if musicSound then musicSound:Play() end
				playingLabel.Text = "Script Enabled"
			else
				toggleStateBtn.Text = "TOGGLE: OFF"; toggleStateBtn.TextColor3 = C_RED; toggleStateBtn.BackgroundColor3 = C_DARKRED
				if musicSound then musicSound:Stop() end
				Parts:ClearAllChildren()
				lineProgress.Size = UDim2.new(0,0,0,6)
				timePosLabel.Text = "0:00"
				playingLabel.Text = "Script Disabled"
			end
		end)
	end

	--// 2. MUSIC
	local searchQuery = ""
	local addMenuFrame, catMenuFrame
	local function buildMusic(parent)
		local inner = mkPanel(parent, UDim2.new(1,0,1,0))
		mkLabel(inner, "MUSIC LIBRARY", UDim2.new(1,-20,0,24), UDim2.new(0,10,0,8), F_S, 18)
		local searchBox = mkBox(inner, "", UDim2.new(1,-20,0,24), UDim2.new(0,10,0,36), "Search ID / Name...", 14)
		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			searchQuery = searchBox.Text:lower()
			if updateMusicList then updateMusicList() end
		end)
		local catFrame = create("ScrollingFrame", {Parent = inner, Size = UDim2.new(0,95,1,-100), Position = UDim2.new(0,10,0,66), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, CanvasSize = UDim2.new(0,0,0,0)})
		local musFrame = create("ScrollingFrame", {Parent = inner, Size = UDim2.new(1,-115,1,-100), Position = UDim2.new(0,105,0,66), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0,0,0,0)})
		local controls = create("Frame", {Parent = inner, Size = UDim2.new(1,-10,0,35), Position = UDim2.new(0,5,1,-35), BackgroundTransparency = 1})
		local addB = mkBtn(controls, "ADD", UDim2.new(0,75,0,26), UDim2.new(0,5,0,4), F_S, 13, false, C_DARKGRN, C_TEXT)
		local editB = mkBtn(controls, "EDIT", UDim2.new(0,75,0,26), UDim2.new(0,85,0,4), F_S, 13, false, Color3.fromRGB(50,50,70), C_TEXT)
		local delB = mkBtn(controls, "DELETE", UDim2.new(0,75,0,26), UDim2.new(0,165,0,4), F_S, 13, false, C_DARKRED, C_TEXT)
		local newCatB = mkBtn(controls, "+ CAT", UDim2.new(0,70,0,26), UDim2.new(0,245,0,4), F_S, 13, false, Color3.fromRGB(60,60,60), C_TEXT)
		local delCatB = mkBtn(controls, "- CAT", UDim2.new(0,70,0,26), UDim2.new(0,320,0,4), F_S, 13, false, Color3.fromRGB(45,45,45), C_TEXT)
				local CHECK_BG = Color3.fromRGB(60,60,60)
	 	local checkB = mkBtn(controls, "CHECK", UDim2.new(0,75,0,26), UDim2.new(0,395,0,4), F_S, 13)
 		local isChecking = false
 		checkB.MouseButton1Click:Connect(function()
 			if isChecking then return end
 			isChecking = true
 			checkB.Text = "PREPARING..."
 			task.spawn(function()
 				local seen, list = {}, {}
 				for _, catData in pairs(DataStructure.Categories) do
 					for id, _ in pairs(catData) do
 						local k = tostring(id)
 						if not seen[k] then seen[k] = true; table.insert(list, k) end
	 				end
 				end
 				local broken = 0
 				for i, id in ipairs(list) do
 					checkB.Text = string.format("CHECK %d/%d", i, #list)
 					local temp = Instance.new("Sound")
 					temp.SoundId = "rbxassetid://" .. id
 					temp.Volume = 0
 					temp.Parent = SoundService
 					pcall(function() temp:Play() end)
 					local ok = false
 					local el = 0
 					while el < 5 do
 						if temp.TimeLength > 0 then ok = true; break end
	 					task.wait(0.25); el = el + 0.25
 					end
 					temp:Stop(); temp:Destroy()
 					if ok then brokenIds[id] = nil else brokenIds[id] = true; broken = broken + 1 end
	 				task.wait(0.1)
 				end
 				updateMusicList()
 				checkB.Text = "CHECK"
 				isChecking = false
 				notify("Check", "Done! Broken tracks marked red: " .. broken)
	 		end)
 		end)

		addMenuFrame = create("Frame", {Parent = inner, Size = UDim2.new(0.9,0,0.75,0), Position = UDim2.new(0.05,0,0.1,0), BackgroundColor3 = Color3.fromRGB(25,25,25), BorderColor3 = C_BORDER, BorderSizePixel = 1, Visible = false, ZIndex = 20})
		corner(addMenuFrame)
		mkLabel(addMenuFrame, "TRACK EDITOR", UDim2.new(1,0,0.12,0), UDim2.new(0,0,0,0), F_S, 15, C_TEXT2, Enum.TextXAlignment.Center)
		local inId = mkBox(addMenuFrame, "", UDim2.new(0.45,0,0.15,0), UDim2.new(0.04,0,0.15,0), "Sound ID", 14)
		local inName = mkBox(addMenuFrame, "", UDim2.new(0.45,0,0.15,0), UDim2.new(0.51,0,0.15,0), "Track Name", 14)
		local inVol = mkBox(addMenuFrame, "1", UDim2.new(0.45,0,0.15,0), UDim2.new(0.04,0,0.35,0), "Volume (e.g. 1)", 14)
		local inPitch = mkBox(addMenuFrame, "1", UDim2.new(0.45,0,0.15,0), UDim2.new(0.51,0,0.35,0), "Pitch (e.g. 1)", 14)
		local inStart = mkBox(addMenuFrame, "0", UDim2.new(0.45,0,0.15,0), UDim2.new(0.04,0,0.55,0), "Start Time (sec)", 14)
		local inEnd = mkBox(addMenuFrame, "0", UDim2.new(0.45,0,0.15,0), UDim2.new(0.51,0,0.55,0), "End Time (0 = Max)", 14)
		local saveB = mkBtn(addMenuFrame, "SAVE", UDim2.new(0.45,0,0.15,0), UDim2.new(0.04,0,0.78,0), F_S, 14, false, Color3.fromRGB(40,80,40), Color3.fromRGB(250,250,250))
		local cancelB = mkBtn(addMenuFrame, "CANCEL", UDim2.new(0.45,0,0.15,0), UDim2.new(0.51,0,0.78,0), F_S, 14, false, Color3.fromRGB(80,40,40), Color3.fromRGB(250,250,250))

		catMenuFrame = create("Frame", {Parent = inner, Size = UDim2.new(0.7,0,0.4,0), Position = UDim2.new(0.15,0,0.3,0), BackgroundColor3 = Color3.fromRGB(30,30,30), BorderColor3 = C_BORDER, BorderSizePixel = 1, Visible = false, ZIndex = 22})
		corner(catMenuFrame)
		mkLabel(catMenuFrame, "NEW CATEGORY NAME:", UDim2.new(1,0,0.3,0), UDim2.new(0,0,0,0), F_S, 14, C_TEXT2, Enum.TextXAlignment.Center)
		local inCatName = mkBox(catMenuFrame, "", UDim2.new(0.9,0,0.3,0), UDim2.new(0.05,0,0.35,0), "", 14)
		local saveCatB = mkBtn(catMenuFrame, "CREATE", UDim2.new(0.45,0,0.2,0), UDim2.new(0.05,0,0.7,0), F_S, 14, false, Color3.fromRGB(40,80,40), Color3.fromRGB(250,250,250))
		local cancelCatB = mkBtn(catMenuFrame, "CANCEL", UDim2.new(0.45,0,0.2,0), UDim2.new(0.5,0,0.7,0), F_S, 14, false, Color3.fromRGB(80,40,40), Color3.fromRGB(250,250,250))

		updateCategoryList = function()
			for _, c in ipairs(catFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
			local y = 5
			for catName, _ in pairs(DataStructure.Categories) do
				local b = mkBtn(catFrame, catName, UDim2.new(1,-10,0,25), UDim2.new(0,5,0,y), F_B, 13, "no",
 					currentCategory == catName and lighter(uiColor_ButtonColor, 40) or uiColor_ButtonColor, uiColor_TextColor)
				b.MouseButton1Click:Connect(function()
					currentCategory = catName
					updateCategoryList(); updateMusicList()
				end)
				y = y + 28
			end
			catFrame.CanvasSize = UDim2.new(0,0,0, y + 10)
		end

		updateMusicList = function()
			for _, c in ipairs(musFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
			local sx, sy, px, py = 6, 5, 4, 6
			local tw, th = 88, 45
			local col, row = 0, 0
			local tracks = DataStructure.Categories[currentCategory] or {}
			for id, td in pairs(tracks) do
				local nm = (td.name or ""):lower()
				local idL = tostring(id):lower()
				if searchQuery == "" or nm:find(searchQuery, 1, true) or idL:find(searchQuery, 1, true) then
	 				local isBroken = brokenIds[tostring(id)] == true
 					local bgCol = isBroken and C_DARKRED or (currentSelectedId == tostring(id) and lighter(uiColor_ButtonColor, 40) or uiColor_ButtonColor)
 					local txCol = isBroken and C_RED or uiColor_TextColor
 					local b = mkBtn(musFrame, td.name or tostring(id), UDim2.new(0,tw,0,th),
 						UDim2.new(0, sx + col*(tw+px), 0, sy + row*(th+py)), F_R, 12, "no", bgCol, txCol)
					b.MouseButton1Click:Connect(function()
						if not ToggleState then return end
						currentSelectedId = tostring(id)
						soundIdBox.Text = tostring(id)
						volumeBox.Text = tostring(td.volume or 1)
						pitchBox.Text = tostring(td.pitch or 1)
						updateMusicList()
						if not musicSound or musicSound.Parent ~= ScreenGui then
							musicSound = makeMusicSound(tostring(id))
							runTimelineLoop()
						end
						musicSound.SoundId = "rbxassetid://" .. id
						musicSound.Volume = tonumber(td.volume) or 1
						musicSound.PlaybackSpeed = tonumber(td.pitch) or 1
						musicSound.TimePosition = tonumber(td.start_time) or 0
						musicSound:Play()
						playingLabel.Text = "[" .. currentCategory .. "] " .. (td.name or tostring(id))
					end)
					col = col + 1
					if col >= 7 then col = 0; row = row + 1 end -- 7 В СТРОКУ
				end
			end
			local totalRows = col > 0 and (row + 1) or row
			musFrame.CanvasSize = UDim2.new(0,0,0, sy + totalRows * (th + py) + 10)
		end

		updateCategoryList(); updateMusicList()

		newCatB.MouseButton1Click:Connect(function() inCatName.Text = ""; catMenuFrame.Visible = true end)
		saveCatB.MouseButton1Click:Connect(function()
			local n = inCatName.Text:gsub("%s+","")
			if n ~= "" and not DataStructure.Categories[n] then
				DataStructure.Categories[n] = {}
				currentCategory = n
				saveMusicData(); updateCategoryList(); updateMusicList()
			end
			catMenuFrame.Visible = false
		end)
		cancelCatB.MouseButton1Click:Connect(function() catMenuFrame.Visible = false end)
		delCatB.MouseButton1Click:Connect(function()
			if currentCategory ~= "Default" then
				DataStructure.Categories[currentCategory] = nil
				currentCategory = "Default"
				saveMusicData(); updateCategoryList(); updateMusicList()
			end
		end)
		addB.MouseButton1Click:Connect(function()
			inId.Text = ""; inName.Text = ""; inVol.Text = "1"; inPitch.Text = "1"; inStart.Text = "0"; inEnd.Text = "0"
			addMenuFrame.Visible = true
		end)
		editB.MouseButton1Click:Connect(function()
			local tr = DataStructure.Categories[currentCategory] and DataStructure.Categories[currentCategory][currentSelectedId]
			if tr then
				inId.Text = currentSelectedId; inName.Text = tr.name or ""
				inVol.Text = tostring(tr.volume or 1); inPitch.Text = tostring(tr.pitch or 1)
				inStart.Text = tostring(tr.start_time or 0); inEnd.Text = tostring(tr.end_time or 0)
				addMenuFrame.Visible = true
			end
		end)
		saveB.MouseButton1Click:Connect(function()
			local id = inId.Text:gsub("%s+","")
			local nm = inName.Text
			if id ~= "" and nm ~= "" then
				DataStructure.Categories[currentCategory][id] = {
					name = nm, volume = tonumber(inVol.Text) or 1, pitch = tonumber(inPitch.Text) or 1,
					start_time = tonumber(inStart.Text) or 0, end_time = tonumber(inEnd.Text) or 0
				}
				saveMusicData(); updateMusicList()
				addMenuFrame.Visible = false
			end
		end)
		cancelB.MouseButton1Click:Connect(function() addMenuFrame.Visible = false end)
		delB.MouseButton1Click:Connect(function()
			if DataStructure.Categories[currentCategory] and DataStructure.Categories[currentCategory][currentSelectedId] then
				DataStructure.Categories[currentCategory][currentSelectedId] = nil
				saveMusicData(); updateMusicList()
				currentSelectedId = ""
			end
		end)
	end

	--// 3. SETTINGS
	local function buildSettings(parent)
		local inner = mkPanel(parent, UDim2.new(1,0,1,0))
		mkLabel(inner, "SETTINGS", UDim2.new(1,-20,0,24), UDim2.new(0,10,0,8), F_S, 18)
		local function mkSetBox(ph, col, row)
			local sx, sy, px, py, w, h = 10, 40, 10, 10, 170, 34
			return mkBox(inner, "", UDim2.new(0,w,0,h), UDim2.new(0, sx + (col-1)*(w+px), 0, sy + (row-1)*(h+py)), ph, 15)
		end
		local partsSetting = mkSetBox("Parts", 1, 1)
		local colorSetting = mkSetBox("Color (255,255,255)", 2, 1); colorSetting.Text = "255,255,255"
		local angleSetting2 = mkSetBox("Goal", 3, 1)
		local transSetting = mkSetBox("Trans", 1, 2); transSetting.Text = "0"
		local splitSetting = mkSetBox("Split", 2, 2)
		local angleSetting = mkSetBox("Angle", 3, 2)
		local disposSetting = mkSetBox("Disposition", 1, 3)
		local bodySetting = mkSetBox("Body", 2, 3)
		local powerSetting = mkSetBox("Power", 3, 3)

		partsSetting.Text = tostring(Settings.Parts)
		colorSetting.Text = string.format("%d,%d,%d", Settings.StaticColor.R*255, Settings.StaticColor.G*255, Settings.StaticColor.B*255)
		angleSetting2.Text = tostring(Settings.Goal)
		transSetting.Text = tostring(Settings.Transparency)
		splitSetting.Text = tostring(Settings.Split)
		angleSetting.Text = tostring(Settings.Angle)
		disposSetting.Text = tostring(Settings.Disposition)
		bodySetting.Text = tostring(Settings.Body)
		powerSetting.Text = tostring(Settings.Power)

		local rainbowToggleBtn = mkBtn(inner, "RAINBOW: " .. (Settings.Rainbow and "ON" or "OFF"),
 			UDim2.new(0,170,0,34), UDim2.new(0,10,0,170), F_S, 14, "no",
			Settings.Rainbow and C_DARKGRN or C_DARKRED,
			Settings.Rainbow and C_GRN or C_RED)
		materialBtnRef = mkBtn(inner, "MATERIALS", UDim2.new(0,170,0,34), UDim2.new(0,190,0,170), F_S, 14)

		rainbowToggleBtn.MouseButton1Click:Connect(function()
			Settings.Rainbow = not Settings.Rainbow
			if Settings.Rainbow then
				rainbowToggleBtn.Text = "RAINBOW: ON"; rainbowToggleBtn.TextColor3 = C_GRN; rainbowToggleBtn.BackgroundColor3 = C_DARKGRN
			else
				rainbowToggleBtn.Text = "RAINBOW: OFF"; rainbowToggleBtn.TextColor3 = C_RED; rainbowToggleBtn.BackgroundColor3 = C_DARKRED
				for _, c in ipairs(Parts:GetChildren()) do
					if c:IsA("BasePart") then c.Color = Settings.StaticColor end
				end
			end
			saveSettings()
		end)

		partsSetting.FocusLost:Connect(function()
			local v = tonumber(partsSetting.Text); if not v then return end
			Settings.Parts = math.clamp(v, 1, 200); rebuildParts(Settings.Parts); saveSettings()
		end)
		colorSetting.FocusLost:Connect(function()
			local r, g, b = colorSetting.Text:match("(%d+),%s*(%d+),%s*(%d+)")
			if r and g and b then
				Settings.StaticColor = Color3.fromRGB(math.clamp(tonumber(r),0,255), math.clamp(tonumber(g),0,255), math.clamp(tonumber(b),0,255))
				if not Settings.Rainbow then
					for _, c in ipairs(Parts:GetChildren()) do
						if c:IsA("BasePart") then c.Color = Settings.StaticColor end
					end
				end
				saveSettings()
			end
		end)
		angleSetting2.FocusLost:Connect(function()
			local v = tonumber(angleSetting2.Text); if v then Settings.Goal = math.clamp(v, 0.01, 1); saveSettings() end
		end)
		transSetting.FocusLost:Connect(function()
			local v = tonumber(transSetting.Text); if v then
				Settings.Transparency = math.clamp(v, 0, 1)
				for _, c in ipairs(Parts:GetChildren()) do
					if c:IsA("BasePart") then c.Transparency = Settings.Transparency end
				end
				saveSettings()
			end
		end)
		splitSetting.FocusLost:Connect(function()
			local v = tonumber(splitSetting.Text); if v then Settings.Split = v == 0 and 1 or v; saveSettings() end
		end)
		angleSetting.FocusLost:Connect(function()
			local v = tonumber(angleSetting.Text); if v then Settings.Angle = v; saveSettings() end
		end)
		disposSetting.FocusLost:Connect(function()
			local v = tonumber(disposSetting.Text); if v then Settings.Disposition = v; saveSettings() end
		end)
		bodySetting.FocusLost:Connect(function()
			local v = tonumber(bodySetting.Text); if v then Settings.Body = v; saveSettings() end
		end)
		powerSetting.FocusLost:Connect(function()
			local v = tonumber(powerSetting.Text); if v then Settings.Power = v == 0 and 1 or v; saveSettings() end
		end)
	end

	--// 4. MATERIALS
	local function buildMaterials(parent)
		local inner = mkPanel(parent, UDim2.new(1,0,1,0))
		mkLabel(inner, "MATERIALS", UDim2.new(1,-20,0,24), UDim2.new(0,10,0,8), F_S, 18)
		local picker = create("ScrollingFrame", {Parent = inner, Size = UDim2.new(1,-20,1,-40), Position = UDim2.new(0,10,0,34), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0,0,0,0)})
		local materialsList = {
			"Neon", "Plastic", "Glass", "ForceField", "Wood", "WoodPlanks",
			"Marble", "Slate", "Granite", "Brick", "Cobblestone", "Concrete",
			"Metal", "DiamondPlate", "CorrodedMetal", "Ice", "Sand", "Fabric"
		}
		local col, row = 0, 0
		for _, matName in ipairs(materialsList) do
			local b = mkBtn(picker, matName:upper(), UDim2.new(0,140,0,34), UDim2.new(0, 5 + col*148, 0, 5 + row*42), F_B, 13, false, C_BG, C_TEXT)
			b.MouseButton1Click:Connect(function()
				Settings.Material = matName
				for _, c in ipairs(Parts:GetChildren()) do
					if c:IsA("Part") then c.Material = Enum.Material[matName] or Enum.Material.Neon end
				end
				saveSettings()
			end)
			col = col + 1
			if col >= 5 then col = 0; row = row + 1 end
		end
		picker.CanvasSize = UDim2.new(0,0,0, 5 + (row+1)*42 + 10)
	end

	--// 5. GRABBER
	local selectedGrabbedId = ""
	local isGrabberScanning = false
	local scanConnection = nil
	local function buildGrabber(parent)
		local inner = mkPanel(parent, UDim2.new(1,0,1,0))
		mkLabel(inner, "GRABBER", UDim2.new(1,-20,0,24), UDim2.new(0,10,0,8), F_S, 18)
		local grabFrame = create("ScrollingFrame", {Parent = inner, Size = UDim2.new(1,-20,1,-85), Position = UDim2.new(0,10,0,40), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0,0,0,0)})
		local controls = create("Frame", {Parent = inner, Size = UDim2.new(1,-10,0,35), Position = UDim2.new(0,5,1,-35), BackgroundTransparency = 1})
	 	local gStartB = mkBtn(controls, "START", UDim2.new(0,90,0,26), UDim2.new(0,5,0,4), F_S, 13, "no", C_DARKGRN, C_TEXT)
		local gScanB = mkBtn(controls, "SCAN", UDim2.new(0,100,0,26), UDim2.new(0,105,0,4), F_S, 13, false, C_DARKBLUE, C_TEXT)
		local gDelB = mkBtn(controls, "DELETE", UDim2.new(0,90,0,26), UDim2.new(0,215,0,4), F_S, 13, false, C_DARKRED, C_TEXT)
		local gBlackB = mkBtn(controls, "BLACKLIST", UDim2.new(0,95,0,26), UDim2.new(0,315,0,4), F_S, 13, false, Color3.fromRGB(45,45,45), C_TEXT)

		local function checkAndAddSound(snd)
			if snd:IsA("Sound") and snd.IsPlaying and snd.SoundId ~= "" then
				local rawId = snd.SoundId:match("%d+")
				if rawId then
					local n = tonumber(rawId)
					if n and not table.find(grabbedIds, n) and not blacklistedIds[n] then
						table.insert(grabbedIds, n)
						updateGrabberList(); saveGrabber()
					end
				end
			end
		end

		updateGrabberList = function()
			for _, c in ipairs(grabFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
			local col, row = 0, 0
			local w, h, gap = 100, 40, 5
			for _, id in ipairs(grabbedIds) do
				local b = mkBtn(grabFrame, "ID: " .. tostring(id), UDim2.new(0,w,0,h),
 					UDim2.new(0, 5 + col*(w+gap), 0, 5 + row*(h+gap)), F_R, 12, "no",
 					selectedGrabbedId == tostring(id) and lighter(uiColor_ButtonColor, 40) or uiColor_ButtonColor, uiColor_TextColor)
				b.MouseButton1Click:Connect(function()
					if not ToggleState then return end
					selectedGrabbedId = tostring(id)
					soundIdBox.Text = tostring(id)
					updateGrabberList()
					if setclipboard then setclipboard(tostring(id)) end
					if not musicSound or musicSound.Parent ~= ScreenGui then
						musicSound = makeMusicSound(tostring(id))
						runTimelineLoop()
					end
					musicSound.SoundId = "rbxassetid://" .. id
					musicSound.TimePosition = 0
					musicSound:Play()
					playingLabel.Text = "Grabbed ID: " .. id
				end)
				col = col + 1
				if col >= 7 then col = 0; row = row + 1 end -- 7 В СТРОКУ
			end
			grabFrame.CanvasSize = UDim2.new(0,0,0, 5 + (row+1)*(h+gap) + 10)
		end
		updateGrabberList()

		local function startSmartScanning()
			for _, serviceName in ipairs({"Workspace", "SoundService", "Players"}) do
				local srv = game:GetService(serviceName)
				if srv then
					for _, v in ipairs(srv:GetDescendants()) do pcall(checkAndAddSound, v) end
				end
			end
			scanConnection = game.DescendantAdded:Connect(function(desc)
				pcall(function()
					if desc:IsA("Sound") then
						checkAndAddSound(desc)
						desc:GetPropertyChangedSignal("IsPlaying"):Connect(function() checkAndAddSound(desc) end)
					end
				end)
			end)
		end

		gStartB.MouseButton1Click:Connect(function()
			if not ToggleState then return end
			isGrabberScanning = not isGrabberScanning
			if isGrabberScanning then
				gStartB.Text = "STOP"; gStartB.BackgroundColor3 = C_DARKRED
				startSmartScanning()
			else
				gStartB.Text = "START"; gStartB.BackgroundColor3 = C_DARKGRN
				if scanConnection then scanConnection:Disconnect(); scanConnection = nil end
			end
		end)

		gScanB.MouseButton1Click:Connect(function()
			if not ToggleState then return end
			local seen, uniq = {}, {}
			for _, id in ipairs(grabbedIds) do
				local k = tostring(id)
				if not seen[k] then seen[k] = true; table.insert(uniq, id) end
			end
			grabbedIds = uniq
			local musicIdSet = {}
			for _, catData in pairs(DataStructure.Categories) do
				for id, _ in pairs(catData) do musicIdSet[tostring(id)] = true end
			end
			local filtered = {}
			for _, id in ipairs(grabbedIds) do
				if not musicIdSet[tostring(id)] then table.insert(filtered, id) end
			end
			grabbedIds = filtered
			local valid = {}
			for _, id in ipairs(grabbedIds) do
				local temp = Instance.new("Sound"); temp.SoundId = "rbxassetid://" .. id
				temp.Volume = 0; temp.Parent = SoundService
				pcall(function() temp:Play() end)
				local el = 0
				while el < 5 do
					if temp.TimeLength > 0 then table.insert(valid, id); break end
					task.wait(0.25); el = el + 0.25
				end
				temp:Stop(); temp:Destroy()
				task.wait(0.2)
			end
			grabbedIds = valid
			saveGrabber(); updateGrabberList()
			selectedGrabbedId = ""
			notify("Grabber", "Scan complete: " .. #valid .. " valid IDs")
		end)

		gDelB.MouseButton1Click:Connect(function()
			local n = tonumber(selectedGrabbedId)
			if n then
				local idx = table.find(grabbedIds, n)
				if idx then table.remove(grabbedIds, idx) end
				selectedGrabbedId = ""
				saveGrabber(); updateGrabberList()
			end
		end)
		gBlackB.MouseButton1Click:Connect(function()
			local n = tonumber(selectedGrabbedId)
			if n then
				blacklistedIds[n] = true
				local idx = table.find(grabbedIds, n)
				if idx then table.remove(grabbedIds, idx) end
				selectedGrabbedId = ""
				saveGrabber(); saveBlacklist(); updateGrabberList()
			end
		end)
	end

	addMusicTab("Home", buildHome)
	addMusicTab("Music", buildMusic)
	addMusicTab("Settings", buildSettings)
	addMusicTab("Materials", buildMaterials)
	addMusicTab("Grabber", buildGrabber)

	-- Кнопка MATERIALS переключает на вкладку Materials
	if materialBtnRef then
		materialBtnRef.MouseButton1Click:Connect(function()
			for _, t in ipairs(musicTabs) do t.Frame.Visible = (t.Name == "Materials") end
			updateTabButtonsTheme()
		end)
	end
	local baseApplyTheme = applyTheme
 	applyTheme = function()
 		baseApplyTheme()
 		if lineProgress and lineProgress.Parent then
	 		lineProgress.BackgroundColor3 = uiColor_TextColor
	 	end
	 	if updateCategoryList then pcall(updateCategoryList) end
	 	if updateMusicList then pcall(updateMusicList) end
	 	if updateGrabberList then pcall(updateGrabberList) end
 	end
	local baseUpdateTabTheme = updateTabButtonsTheme
	updateTabButtonsTheme = function()
		baseUpdateTabTheme()
		for _, tab in ipairs(musicTabs) do
			if tab.Button then
				if tab.Frame.Visible then
					tab.Button.BackgroundColor3 = uiColor_ButtonColor
					tab.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
				else
					tab.Button.BackgroundColor3 = Color3.fromRGB(math.max(uiColor_ButtonColor.R*255-10,0), math.max(uiColor_ButtonColor.G*255-10,0), math.max(uiColor_ButtonColor.B*255-10,0))
					tab.Button.TextColor3 = uiColor_TextColor
				end
			end
		end
	end

	task.defer(function()
		local function hideAllFrames()
			for _, t in ipairs(tabs) do t.Frame.Visible = false end
			for _, t in ipairs(desyncTabs) do t.Frame.Visible = false end
			for _, t in ipairs(musicTabs) do t.Frame.Visible = false end
		end
		local function showMainButtons()
			for _, t in ipairs(tabs) do if t.Button then t.Button.Visible = true end end
			for _, t in ipairs(desyncTabs) do t.Button.Visible = false end
			for _, t in ipairs(musicTabs) do t.Button.Visible = false end
		end
		local function showDesyncButtons()
			for _, t in ipairs(tabs) do if t.Button then t.Button.Visible = false end end
			for _, t in ipairs(desyncTabs) do t.Button.Visible = true end
			for _, t in ipairs(musicTabs) do t.Button.Visible = false end
		end
		local function showMusicButtons()
			for _, t in ipairs(tabs) do if t.Button then t.Button.Visible = false end end
			for _, t in ipairs(desyncTabs) do t.Button.Visible = false end
			for _, t in ipairs(musicTabs) do t.Button.Visible = true end
		end

		for _, t in ipairs(musicTabs) do
			t.Button.MouseButton1Click:Connect(function()
				hideAllFrames()
				t.Frame.Visible = true
				updateTabButtonsTheme()
			end)
		end
		for _, t in ipairs(tabs) do
			if t.Button then
				t.Button.MouseButton1Click:Connect(function()
					for _, m in ipairs(musicTabs) do m.Frame.Visible = false end
					for _, d in ipairs(desyncTabs) do d.Frame.Visible = false end
					updateTabButtonsTheme()
				end)
			end
		end
		for _, t in ipairs(desyncTabs) do
			t.Button.MouseButton1Click:Connect(function()
				for _, m in ipairs(musicTabs) do m.Frame.Visible = false end
				updateTabButtonsTheme()
			end)
		end

		EmilyUi.MouseButton1Click:Connect(function()
			showMainButtons(); hideAllFrames()
			if tabs[1] then tabs[1].Frame.Visible = true end
			updateTabButtonsTheme()
		end)
		Desync.MouseButton1Click:Connect(function()
			showDesyncButtons(); hideAllFrames()
			if desyncTabs[1] then desyncTabs[1].Frame.Visible = true end
			updateTabButtonsTheme()
		end)
		Music.MouseButton1Click:Connect(function()
			showMusicButtons(); hideAllFrames()
			if musicTabs[1] then musicTabs[1].Frame.Visible = true end
				updateTabButtonsTheme()
		end)
	end)
		return musicTabs
end

local musicTabs = initMusicModule(desyncTabs)
-- =========================================================

-- =========================================================
-- ========== AIMBOT MODULE ================================
-- =========================================================
local function initAimbotModule(desyncTabs, musicTabs)
	desyncTabs = desyncTabs or {}
	musicTabs = musicTabs or {}   -- ← страховка от nil
	local Camera = workspace.CurrentCamera
    local F_R = Enum.Font.SourceSans
    local F_B = Enum.Font.SourceSansBold
    local F_S = Enum.Font.SourceSansSemibold

    --// Настройки аимбота (по умолчанию ВЫКЛЮЧЕНО)
    local AimSettings = {
        Enabled = false,
        Mode = "Hold",
        AimPart = "All",
        StickToTarget = false,
        WallCheck = false,
        AutoFire = false,
        DrawFOV = true,
        FOV = 150,
        Smoothness = 0.2,
        Sensitivity = 0.45,
        ActiveToggle = false,
        Keybind = Enum.UserInputType.MouseButton2
    }

    local ESPSettings = {
        Enabled = false,
        Color = Color3.fromRGB(0, 255, 150),
        ShowName = true,
        ShowUsername = true,
        ShowHP = true,
        ShowDistance = true
    }

    local AimKeybinds = {
        ToggleAimbot = Enum.KeyCode.G,
        ToggleESP = Enum.KeyCode.H,
        ToggleMenu = Enum.KeyCode.RightShift
    }

	--// Refs на UI-элементы (для apply/reset)
	local uiRefs = {}
	--// Автосохранение настроек аимбота
	local AIM_AUTO_FILE = "EmilyUi/FuckYou/AimSettings.json"
	local function ensureAimDirs()
    	if makefolder then pcall(function()
        	if not isfolder("EmilyUi") then makefolder("EmilyUi") end
        	if not isfolder("EmilyUi/FuckYou") then makefolder("EmilyUi/FuckYou") end
	    end) end
	end
	local function enumKeyName(v)
	    return tostring(v):gsub("Enum.KeyCode.", ""):gsub("Enum.UserInputType.", "")
	end
	--// Безопасный поиск Enum по имени (Enum.KeyCode["MouseButton2"] кидает ошибку, поэтому делаем таблицы)
	local KEYCODE_BY_NAME = {}
	for _, e in ipairs(Enum.KeyCode:GetEnumItems()) do
		KEYCODE_BY_NAME[e.Name] = e
	end
	local INPUTTYPE_BY_NAME = {}
	for _, e in ipairs(Enum.UserInputType:GetEnumItems()) do
		INPUTTYPE_BY_NAME[e.Name] = e
	end

	local function getEnumByName(name)
		if not name or name == "" then return nil end
		return KEYCODE_BY_NAME[name] or INPUTTYPE_BY_NAME[name]
	end
	--// Сбор данных аимбота для конфига
	local function gatherAimConfig()
    	return {
        	Aimbot = {
            	Enabled = AimSettings.Enabled,
            	Mode = AimSettings.Mode,
            	AimPart = AimSettings.AimPart,
            	StickToTarget = AimSettings.StickToTarget,
            	WallCheck = AimSettings.WallCheck,
            	AutoFire = AimSettings.AutoFire,
            	DrawFOV = AimSettings.DrawFOV,
            	FOV = AimSettings.FOV,
            	Smoothness = AimSettings.Smoothness,
            	Sensitivity = AimSettings.Sensitivity,
	            Keybind = enumKeyName(AimSettings.Keybind),
        	},
        	ESP = {
            	Enabled = ESPSettings.Enabled,
            	Color = {
                	math.floor(ESPSettings.Color.R * 255 + 0.5),
                	math.floor(ESPSettings.Color.G * 255 + 0.5),
	                math.floor(ESPSettings.Color.B * 255 + 0.5),
            	},
            	ShowName = ESPSettings.ShowName,
            	ShowUsername = ESPSettings.ShowUsername,
            	ShowHP = ESPSettings.ShowHP,
	            ShowDistance = ESPSettings.ShowDistance,
        	},
        	Keybinds = {
            	ToggleAimbot = enumKeyName(AimKeybinds.ToggleAimbot),
            	ToggleESP = enumKeyName(AimKeybinds.ToggleESP),
	            ToggleMenu = enumKeyName(AimKeybinds.ToggleMenu),
        	},
	    }
	end
	local function saveAimAuto()
    	if writefile then
        	ensureAimDirs()
        	pcall(function() writefile(AIM_AUTO_FILE, HttpService:JSONEncode(gatherAimConfig())) end)
	    end
	end

    --// FOV Circle
    local fovCircle = nil
    if Drawing then
        fovCircle = Drawing.new("Circle")
        fovCircle.Visible = false
        fovCircle.Thickness = 2
        fovCircle.Color = ESPSettings.Color
        fovCircle.Filled = false
    end

    --// ESP Storage
    local ESP_Instances = {}
    local currentTargetPart = nil
    local lastFire = 0
    local renderConnection = nil
    local aimInputConnection = nil

    local function createESP(player)
        if not player.Character then return end
        local character = player.Character
        local root = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")
        if not root or not humanoid then return end

        local highlight = Instance.new("Highlight")
        highlight.Name = "AimbotESP_Highlight"
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillColor = ESPSettings.Color
        highlight.FillTransparency = 0.7
        highlight.OutlineColor = Color3.new(1, 1, 1)
        highlight.OutlineTransparency = 0.5
        highlight.Parent = character

        local billboardTop = Instance.new("BillboardGui")
        billboardTop.Name = "AimbotESP_Top"
        billboardTop.Adornee = root
        billboardTop.Size = UDim2.new(0, 200, 0, 60)
        billboardTop.StudsOffset = Vector3.new(0, 3.5, 0)
        billboardTop.AlwaysOnTop = true
        billboardTop.Parent = character

        local textTop = Instance.new("TextLabel", billboardTop)
        textTop.Size = UDim2.new(1, 0, 1, 0)
        textTop.BackgroundTransparency = 1
        textTop.TextColor3 = ESPSettings.Color
        textTop.TextSize = 14
        textTop.Font = Enum.Font.GothamBold
        textTop.TextStrokeTransparency = 0.5
        textTop.TextYAlignment = Enum.TextYAlignment.Bottom

        local billboardBottom = Instance.new("BillboardGui")
        billboardBottom.Name = "AimbotESP_Bottom"
        billboardBottom.Adornee = root
        billboardBottom.Size = UDim2.new(0, 200, 0, 40)
        billboardBottom.StudsOffset = Vector3.new(0, -3, 0)
        billboardBottom.AlwaysOnTop = true
        billboardBottom.Parent = character

        local textBottom = Instance.new("TextLabel", billboardBottom)
        textBottom.Size = UDim2.new(1, 0, 1, 0)
        textBottom.BackgroundTransparency = 1
        textBottom.TextColor3 = ESPSettings.Color
        textBottom.TextSize = 13
        textBottom.Font = Enum.Font.GothamBold
        textBottom.TextStrokeTransparency = 0.5
        textBottom.TextYAlignment = Enum.TextYAlignment.Top

        ESP_Instances[player] = {
            Highlight = highlight,
            TextTop = textTop,
            TextBottom = textBottom,
            BillboardTop = billboardTop,
            BillboardBottom = billboardBottom
        }
    end

    local function cleanESP()
        for player, instances in pairs(ESP_Instances) do
            if instances.Highlight then instances.Highlight:Destroy() end
            if instances.BillboardTop then instances.BillboardTop:Destroy() end
            if instances.BillboardBottom then instances.BillboardBottom:Destroy() end
            ESP_Instances[player] = nil
        end
        ESP_Instances = {}
    end

    local function updateESP()
        for player, instances in pairs(ESP_Instances) do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local root = player.Character.HumanoidRootPart
                local humanoid = player.Character:FindFirstChild("Humanoid")

                instances.Highlight.FillColor = ESPSettings.Color
                instances.TextTop.TextColor3 = ESPSettings.Color
                instances.TextBottom.TextColor3 = ESPSettings.Color

                local topInfo = {}
                if ESPSettings.ShowName then table.insert(topInfo, player.DisplayName) end
                if ESPSettings.ShowUsername then table.insert(topInfo, "@" .. player.Name) end
                instances.TextTop.Text = table.concat(topInfo, " | ")

                local bottomInfo = {}
                if ESPSettings.ShowHP and humanoid then
                    local hpText = string.format("HP: %d/%d", math.max(0, humanoid.Health), humanoid.MaxHealth)
                    table.insert(bottomInfo, hpText)
                end
                if ESPSettings.ShowDistance and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude)
                    table.insert(bottomInfo, dist .. "m")
                end
                instances.TextBottom.Text = table.concat(bottomInfo, " | ")

                local enabled = ESPSettings.Enabled
                instances.BillboardTop.Enabled = enabled
                instances.BillboardBottom.Enabled = enabled
                instances.Highlight.Enabled = enabled

                if not ESPSettings.ShowName and not ESPSettings.ShowUsername then
                    instances.BillboardTop.Enabled = false
                end
                if not ESPSettings.ShowHP and not ESPSettings.ShowDistance then
                    instances.BillboardBottom.Enabled = false
                end
            else
                if instances.BillboardTop then instances.BillboardTop.Enabled = false end
                if instances.BillboardBottom then instances.BillboardBottom.Enabled = false end
                if instances.Highlight then instances.Highlight.Enabled = false end
            end
        end
    end

    --// Aimbot Logic
    local function isVisible(targetPart)
        if not AimSettings.WallCheck then return true end
        local origin = Camera.CFrame.Position
        local direction = (targetPart.Position - origin)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.IgnoreWater = true
        local result = workspace:Raycast(origin, direction, raycastParams)
        if result and result.Instance then
            if result.Instance:IsDescendantOf(targetPart.Parent) then
                return true
            end
            return false
        end
        return true
    end

    local function getTarget()
        if not AimSettings.Enabled then return nil, nil end
        local mouse = UserInputService:GetMouseLocation()

        if AimSettings.StickToTarget and currentTargetPart then
            if currentTargetPart.Parent and currentTargetPart.Parent:FindFirstChild("Humanoid") and currentTargetPart.Parent.Humanoid.Health > 0 then
                local screenPos, onScreen = Camera:WorldToViewportPoint(currentTargetPart.Position)
                if onScreen then
                    local mag = (Vector2.new(screenPos.X, screenPos.Y) - mouse).Magnitude
                    if mag <= AimSettings.FOV and isVisible(currentTargetPart) then
                        return screenPos, currentTargetPart
                    end
                end
            end
            currentTargetPart = nil
        end

        local closestPos = nil
        local closestPart = nil
        local dist = AimSettings.FOV

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                local partsToCheck = {}
                if AimSettings.AimPart == "Head" then
                    table.insert(partsToCheck, p.Character:FindFirstChild("Head"))
                elseif AimSettings.AimPart == "RootPart" then
                    table.insert(partsToCheck, p.Character:FindFirstChild("HumanoidRootPart"))
                elseif AimSettings.AimPart == "All" then
                    for _, partName in ipairs({"Head", "HumanoidRootPart", "UpperTorso", "Torso", "LowerTorso"}) do
                        table.insert(partsToCheck, p.Character:FindFirstChild(partName))
                    end
                end

                for _, part in ipairs(partsToCheck) do
                    if part then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                        if onScreen then
                            local mag = (Vector2.new(screenPos.X, screenPos.Y) - mouse).Magnitude
                            if mag < dist and isVisible(part) then
                                dist = mag
                                closestPos = screenPos
                                closestPart = part
                            end
                        end
                    end
                end
            end
        end

        if closestPart then
            currentTargetPart = closestPart
        end
        return closestPos, closestPart
    end

    --// Main Aimbot Loop
    local function startAimbotLoop()
        if renderConnection then renderConnection:Disconnect() end
        renderConnection = RunService.RenderStepped:Connect(function()
            -- FOV Circle
            if fovCircle then
                fovCircle.Visible = AimSettings.DrawFOV and AimSettings.Enabled
                fovCircle.Radius = AimSettings.FOV
                fovCircle.Position = UserInputService:GetMouseLocation()
                fovCircle.Color = ESPSettings.Color
            end

            -- ESP Update (throttled)
            if tick() % 0.1 < 0.02 then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and not ESP_Instances[p] and p.Character then
                        createESP(p)
                    end
                end
                updateESP()
            end

            -- Aimbot
            local shouldAim = false
            if AimSettings.Mode == "Always" then
                shouldAim = true
            elseif AimSettings.Mode == "Toggle" then
                shouldAim = AimSettings.ActiveToggle
            elseif AimSettings.Mode == "Hold" then
                local bind = AimSettings.Keybind
                if typeof(bind) == "EnumItem" then
                    if bind.EnumType == Enum.KeyCode then
                        shouldAim = UserInputService:IsKeyDown(bind)
                    elseif bind.EnumType == Enum.UserInputType then
                        shouldAim = UserInputService:IsMouseButtonPressed(bind)
                    end
                end
            end

            if shouldAim and AimSettings.Enabled then
                local targetPos, targetPart = getTarget()
                if targetPos then
                    local mousePos = UserInputService:GetMouseLocation()
                    local dx = (targetPos.X - mousePos.X) * AimSettings.Sensitivity
                    local dy = (targetPos.Y - mousePos.Y) * AimSettings.Sensitivity
                    if mousemoverel then
                        mousemoverel(dx / (AimSettings.Smoothness * 10), dy / (AimSettings.Smoothness * 10))
                    end
                    if AimSettings.AutoFire and mouse1click then
                        if tick() - lastFire > 0.05 then
                            mouse1click()
                            lastFire = tick()
                        end
                    end
                else
                    currentTargetPart = nil
                end
            else
                currentTargetPart = nil
            end
        end)
    end

    local function stopAimbotLoop()
        if renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end
        if fovCircle then
            fovCircle.Visible = false
        end
        currentTargetPart = nil
    end

    --// Keybind Listener
    local function startKeybindListener()
        if aimInputConnection then aimInputConnection:Disconnect() end
        aimInputConnection = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == AimKeybinds.ToggleAimbot then
                AimSettings.Enabled = not AimSettings.Enabled
                if AimSettings.Enabled then
                    startAimbotLoop()
                else
                    stopAimbotLoop()
                end
            end
            if input.KeyCode == AimKeybinds.ToggleESP then
                ESPSettings.Enabled = not ESPSettings.Enabled
            end
            if AimSettings.Mode == "Toggle" then
                local aimKey = AimSettings.Keybind
                if input.KeyCode == aimKey or input.UserInputType == aimKey then
                    AimSettings.ActiveToggle = not AimSettings.ActiveToggle
                end
            end
        end)
    end

    --// ESP Player Events
    Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function()
            if ESPSettings.Enabled then
                task.wait(0.5)
                createESP(p)
            end
        end)
    end)

    Players.PlayerRemoving:Connect(function(p)
        if ESP_Instances[p] then
            if ESP_Instances[p].Highlight then ESP_Instances[p].Highlight:Destroy() end
            if ESP_Instances[p].BillboardTop then ESP_Instances[p].BillboardTop:Destroy() end
            if ESP_Instances[p].BillboardBottom then ESP_Instances[p].BillboardBottom:Destroy() end
            ESP_Instances[p] = nil
        end
    end)

    --// UI Helpers (FuckYou style)
    local C_GRN = Color3.fromRGB(100, 255, 100)
    local C_ROFF = Color3.fromRGB(255, 100, 100)
    local C_REDD = Color3.fromRGB(150, 40, 40)
    local C_WHT = Color3.fromRGB(255, 255, 255)

    local function corner(p) Instance.new("UICorner", p).CornerRadius = UDim.new(0, 4) end

    local function lighter(c, amt)
        return Color3.fromRGB(math.min(c.R*255+amt,255), math.min(c.G*255+amt,255), math.min(c.B*255+amt,255))
    end

    local function mkLabel(p, txt, sz, pos, font, ts)
        local l = Instance.new("TextLabel")
        l.Parent = p; l.Text = txt; l.Size = sz; l.Position = pos
        l.Font = font or F_S; l.TextSize = ts or 16
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextColor3 = uiColor_TextColor; l.BackgroundTransparency = 1
        table.insert(themeElements.Texts, l)
        return l
    end

    local function mkBox(p, txt, sz, pos, ts)
        local b = Instance.new("TextBox")
        b.Parent = p; b.Text = txt or ""; b.Size = sz; b.Position = pos
        b.Font = F_R; b.TextSize = ts or 14
        b.BackgroundColor3 = uiColor_TextBoxColor; b.TextColor3 = uiColor_TextColor
        b.PlaceholderColor3 = Color3.fromRGB(90, 90, 90)
        b.BorderSizePixel = 0; b.ClearTextOnFocus = false
        table.insert(themeElements.TextBoxes, b)
        table.insert(themeElements.Texts, b)
        corner(b); return b
    end

    local function mkBtn(p, txt, sz, pos, font, ts, themed, bg, tc)
        local b = Instance.new("TextButton")
        b.Parent = p; b.Text = txt; b.Size = sz; b.Position = pos
        b.Font = font or F_B; b.TextSize = ts or 14
        b.Text = txt or ""; b.TextWrapped = true
        b.BackgroundColor3 = bg or uiColor_ButtonColor
        b.TextColor3 = tc or uiColor_TextColor
        b.BorderSizePixel = 0
        if themed ~= "no" then
            table.insert(themeElements.Buttons, b)
            table.insert(themeElements.Texts, b)
        else
            table.insert(themeElements.CustomButtons, b)
        end
        b.BackgroundTransparency = 1 - uiGuiOpacity
        corner(b); return b
    end

    local function mkPanel(p, sz, pos)
        local f = Instance.new("Frame")
        f.Parent = p; f.Size = sz; f.Position = pos or UDim2.new(0,0,0,0)
        f.BackgroundColor3 = uiColor_SideBar; f.BorderSizePixel = 0
        f.ClipsDescendants = true
        table.insert(themeElements.SideBars, f)
        corner(f); return f
    end

    local function mkToggle(p, name, state, sz, pos, callback)
    	local btn = mkBtn(p, "", sz, pos, F_B, 14, "no", C_REDD, C_ROFF)
    	local function paint()
	        btn.Text = name .. ": " .. (state and "ON" or "OFF")
        	btn.BackgroundColor3 = state and Color3.fromRGB(40, 70, 40) or C_REDD
        	btn.TextColor3 = state and C_GRN or C_ROFF
    	end
    	paint()
    	btn.MouseButton1Click:Connect(function()
	        state = not state
        	paint()
        	if callback then callback(state) end
    	end)
	    return {
    	    Button = btn,
        	Get = function() return state end,
        	Set = function(v) state = v and true or false; paint() end,
    	}
	end

    local function mkDropdown(p, name, options, default, sz, pos, callback)
    	local current = default
    	local btn = mkBtn(p, name .. ": " .. tostring(current), sz, pos, F_B, 13)
    	local function paint() btn.Text = name .. ": " .. tostring(current) end
    	btn.MouseButton1Click:Connect(function()
	        local idx = table.find(options, current)
        	idx = idx and (idx % #options + 1) or 1
        	current = options[idx]
        	paint()
        	if callback then callback(current) end
    	end)
    	return {
	        Button = btn,
        	Get = function() return current end,
        	Set = function(v) if table.find(options, v) then current = v; paint() end end,
    	}
	end

    --// Build Aim Tabs
    local aimTabs = {}

    local function addAimTab(name, builder)
        local frame = create("Frame", {Name = "Tab" .. name, Parent = Containment, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false})
        builder(frame)
        local btn = create("TextButton", {
            Name = "ABtn_" .. name, Parent = MenuInsided,
            Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 300 + #aimTabs, Visible = false,
            BackgroundColor3 = uiColor_ButtonColor, BorderColor3 = COL_BORDER,
            TextColor3 = uiColor_TextColor, Text = name, Font = FONT, TextSize = 12,
            TextWrapped = true
        })
        local entry = {Frame = frame, Name = name, Button = btn}
        table.insert(aimTabs, entry)
        table.insert(themeElements.Buttons, btn)
        table.insert(themeElements.Texts, btn)
        return entry
    end

    --// TAB 1: AIM
    local function buildAimTab(parent)
    	local sf = create("ScrollingFrame", {Parent = parent, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0,0,0,420)})
    	local inner = mkPanel(sf, UDim2.new(1,0,0,420))
    	local y = 10
    	uiRefs.aimToggle = mkToggle(inner, "Aimbot", AimSettings.Enabled, UDim2.new(1,-24,0,30), UDim2.new(0,12,0,y), function(state)
	        AimSettings.Enabled = state
        	if state then startAimbotLoop(); startKeybindListener() else stopAimbotLoop() end
        	saveAimAuto()
    	end)
    	y = y + 38
	    uiRefs.modeDD = mkDropdown(inner, "Mode", {"Hold", "Toggle", "Always"}, AimSettings.Mode, UDim2.new(1,-24,0,28), UDim2.new(0,12,0,y), function(val)
        	AimSettings.Mode = val; AimSettings.ActiveToggle = false; saveAimAuto()
	    end)
    	y = y + 34
    	uiRefs.aimPartDD = mkDropdown(inner, "Aim Part", {"Head", "RootPart", "All"}, AimSettings.AimPart, UDim2.new(1,-24,0,28), UDim2.new(0,12,0,y), function(val)
	        AimSettings.AimPart = val; saveAimAuto()
	    end)
	    y = y + 34
    	uiRefs.stickToggle = mkToggle(inner, "Stick To Target", AimSettings.StickToTarget, UDim2.new(1,-24,0,28), UDim2.new(0,12,0,y), function(state)
	        AimSettings.StickToTarget = state; saveAimAuto()
	    end)
	    y = y + 34
	    uiRefs.wallToggle = mkToggle(inner, "Wall Check", AimSettings.WallCheck, UDim2.new(1,-24,0,28), UDim2.new(0,12,0,y), function(state)
        	AimSettings.WallCheck = state; saveAimAuto()
    	end)
    	y = y + 34
    	uiRefs.autoFireToggle = mkToggle(inner, "Auto Fire", AimSettings.AutoFire, UDim2.new(1,-24,0,28), UDim2.new(0,12,0,y), function(state)
	        AimSettings.AutoFire = state; saveAimAuto()
	    end)
	    y = y + 34
    	uiRefs.drawFovToggle = mkToggle(inner, "Draw FOV", AimSettings.DrawFOV, UDim2.new(1,-24,0,28), UDim2.new(0,12,0,y), function(state)
	        AimSettings.DrawFOV = state
        	if fovCircle then fovCircle.Visible = state and AimSettings.Enabled end
        	saveAimAuto()
    	end)
    	y = y + 34
    	uiRefs.fovLabel = mkLabel(inner, "FOV Radius: " .. AimSettings.FOV, UDim2.new(1,-24,0,18), UDim2.new(0,12,0,y), F_S, 14)
    	y = y + 20
    	uiRefs.fovBox = mkBox(inner, tostring(AimSettings.FOV), UDim2.new(1,-24,0,24), UDim2.new(0,12,0,y), 14)
    	uiRefs.fovBox.FocusLost:Connect(function(enter)
	        if enter then
            	local val = tonumber(uiRefs.fovBox.Text)
            	if val then
	                val = math.clamp(val, 10, 500)
                	uiRefs.fovBox.Text = tostring(val)
                	AimSettings.FOV = val
                	uiRefs.fovLabel.Text = "FOV Radius: " .. val
                	saveAimAuto()
            	end
        	end
	    end)
    	y = y + 32
    	uiRefs.smoothLabel = mkLabel(inner, "Smoothness: " .. AimSettings.Smoothness, UDim2.new(1,-24,0,18), UDim2.new(0,12,0,y), F_S, 14)
    	y = y + 20
    	uiRefs.smoothBox = mkBox(inner, tostring(AimSettings.Smoothness), UDim2.new(1,-24,0,24), UDim2.new(0,12,0,y), 14)
	    uiRefs.smoothBox.FocusLost:Connect(function(enter)
        	if enter then
	            local val = tonumber(uiRefs.smoothBox.Text)
            	if val then
	                val = math.clamp(val, 0.1, 1.0)
                	uiRefs.smoothBox.Text = tostring(val)
                	AimSettings.Smoothness = val
                	uiRefs.smoothLabel.Text = "Smoothness: " .. val
                	saveAimAuto()
            	end
        	end
    	end)
	end

    --// TAB 2: ESP
    local function setESPEnabled(state)
    	ESPSettings.Enabled = state
    	if state then
	        for _, p in ipairs(Players:GetPlayers()) do
            	if p ~= LocalPlayer and not ESP_Instances[p] and p.Character then createESP(p) end
        	end
    	end
    	if uiRefs.espToggle then uiRefs.espToggle.Set(state) end
    	if uiRefs.enableESPToggle then uiRefs.enableESPToggle.Set(state) end
    	saveAimAuto()
	end
	local function buildESPTab(parent)
	    local sf = create("ScrollingFrame", {Parent = parent, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0,0,0,400)})
	    local inner = mkPanel(sf, UDim2.new(1,0,0,400))
	    local y = 10
	    uiRefs.espToggle = mkToggle(inner, "ESP", ESPSettings.Enabled, UDim2.new(1,-24,0,30), UDim2.new(0,12,0,y), function(state) setESPEnabled(state) end)
    	y = y + 38
    	local refreshBtn = mkBtn(inner, "Refresh ESP (Update Players)", UDim2.new(1,-24,0,28), UDim2.new(0,12,0,y), F_B, 13)
    	refreshBtn.MouseButton1Click:Connect(function()
	        cleanESP()
        	for _, p in ipairs(Players:GetPlayers()) do
	            if p ~= LocalPlayer and p.Character then createESP(p) end
        	end
	        refreshBtn.Text = "Refreshed!"
        	task.delay(0.5, function() refreshBtn.Text = "Refresh ESP (Update Players)" end)
    	end)
	    y = y + 34
	    uiRefs.enableESPToggle = mkToggle(inner, "Enable ESP", ESPSettings.Enabled, UDim2.new(1,-24,0,28), UDim2.new(0,12,0,y), function(state) setESPEnabled(state) end)
    	y = y + 34
    	uiRefs.showNameToggle = mkToggle(inner, "Show Name", ESPSettings.ShowName, UDim2.new(1,-24,0,28), UDim2.new(0,12,0,y), function(state)
	        ESPSettings.ShowName = state; saveAimAuto()
	    end)
	    y = y + 34
	    uiRefs.showUsernameToggle = mkToggle(inner, "Show Username", ESPSettings.ShowUsername, UDim2.new(1,-24,0,28), UDim2.new(0,12,0,y), function(state)
        	ESPSettings.ShowUsername = state; saveAimAuto()
    	end)
    	y = y + 34
    	uiRefs.showHPToggle = mkToggle(inner, "Show HP", ESPSettings.ShowHP, UDim2.new(1,-24,0,28), UDim2.new(0,12,0,y), function(state)
	        ESPSettings.ShowHP = state; saveAimAuto()
	    end)
	    y = y + 34
	    uiRefs.showDistanceToggle = mkToggle(inner, "Show Distance", ESPSettings.ShowDistance, UDim2.new(1,-24,0,28), UDim2.new(0,12,0,y), function(state)
        	ESPSettings.ShowDistance = state; saveAimAuto()
    	end)
    	y = y + 34
    	mkLabel(inner, "ESP Color (RGB):", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,y), F_S, 14)
    	y = y + 20
    	uiRefs.colorPreview = Instance.new("Frame", inner)
    	uiRefs.colorPreview.Position = UDim2.new(0,12,0,y)
    	uiRefs.colorPreview.Size = UDim2.new(1,-24,0,20)
    	uiRefs.colorPreview.BackgroundColor3 = ESPSettings.Color
    	uiRefs.colorPreview.BorderSizePixel = 1
	    uiRefs.colorPreview.BorderColor3 = Color3.fromRGB(255,255,255)
	    corner(uiRefs.colorPreview)
	    y = y + 26
	    uiRefs.colorBox = mkBox(inner, string.format("%d,%d,%d", math.floor(ESPSettings.Color.R*255), math.floor(ESPSettings.Color.G*255), math.floor(ESPSettings.Color.B*255)), UDim2.new(1,-24,0,24), UDim2.new(0,12,0,y), 13)
	    uiRefs.colorBox.FocusLost:Connect(function(enter)
        	if enter then
	            local r, g, b = uiRefs.colorBox.Text:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
            	if r and g and b then
	                ESPSettings.Color = Color3.fromRGB(math.clamp(tonumber(r),0,255), math.clamp(tonumber(g),0,255), math.clamp(tonumber(b),0,255))
                	uiRefs.colorPreview.BackgroundColor3 = ESPSettings.Color
                	if fovCircle then fovCircle.Color = ESPSettings.Color end
                	saveAimAuto()
            	end
        	end
    	end)
	end

    --// TAB 3: KEYBINDS
	local function buildKeybindsTab(parent)
		local sf = create("ScrollingFrame", {
			Parent = parent,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 4,
			CanvasSize = UDim2.new(0, 0, 0, 220)
		})
		local inner = mkPanel(sf, UDim2.new(1, 0, 0, 220))
		local y = 10

		local function keyName(k)
			return tostring(k):gsub("Enum.KeyCode.", ""):gsub("Enum.UserInputType.", "")
		end

		local function addBindRow(name, currentKey, yOffset, callback)
			local btn = mkBtn(inner, name .. ": [" .. keyName(currentKey) .. "]", UDim2.new(1, -24, 0, 28), UDim2.new(0, 12, 0, yOffset), F_B, 13)
			local waiting = false

			btn.MouseButton1Click:Connect(function()
				if waiting then return end
				waiting = true
				local origText = btn.Text
				btn.Text = name .. ": [PRESS ANY KEY]"
				btn.TextColor3 = Color3.fromRGB(255, 255, 0)

				local conn
				conn = UserInputService.InputBegan:Connect(function(input, gpe)
					if gpe then return end
					if not waiting then return end
					if input.KeyCode == Enum.KeyCode.Unknown and input.UserInputType == Enum.UserInputType.None then return end

					local newKey = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode or input.UserInputType
					callback(newKey)
					saveAimAuto()
					btn.Text = name .. ": [" .. keyName(newKey) .. "]"
					btn.TextColor3 = uiColor_TextColor
					waiting = false
					conn:Disconnect()
				end)

				task.delay(5, function()
					if waiting then
						btn.Text = origText
						btn.TextColor3 = uiColor_TextColor
						waiting = false
						if conn then conn:Disconnect() end
					end
				end)
			end)

			return {
				Button = btn,
				Set = function(k)
					btn.Text = name .. ": [" .. keyName(k) .. "]"
				end
			}
		end

		uiRefs.bindAimKey      = addBindRow("Aimbot Key",    AimSettings.Keybind,        y, function(key) AimSettings.Keybind = key end)
		y = y + 34
		uiRefs.bindToggleAimbot = addBindRow("Toggle Aimbot", AimKeybinds.ToggleAimbot,  y, function(key) AimKeybinds.ToggleAimbot = key end)
		y = y + 34
		uiRefs.bindToggleESP    = addBindRow("Toggle ESP",    AimKeybinds.ToggleESP,     y, function(key) AimKeybinds.ToggleESP = key end)
		y = y + 34
		uiRefs.bindToggleMenu   = addBindRow("Toggle Menu",   AimKeybinds.ToggleMenu,    y, function(key) AimKeybinds.ToggleMenu = key end)
	end

    --// Register Tabs
    addAimTab("Aim", buildAimTab)
    addAimTab("ESP", buildESPTab)
    addAimTab("Keybinds", buildKeybindsTab)

	--// ===== SAVE / LOAD / RESET AIM SETTINGS =====
	local function refreshAimUI()
	    if uiRefs.aimToggle then uiRefs.aimToggle.Set(AimSettings.Enabled) end
	    if uiRefs.modeDD then uiRefs.modeDD.Set(AimSettings.Mode) end
	    if uiRefs.aimPartDD then uiRefs.aimPartDD.Set(AimSettings.AimPart) end
	    if uiRefs.stickToggle then uiRefs.stickToggle.Set(AimSettings.StickToTarget) end
	    if uiRefs.wallToggle then uiRefs.wallToggle.Set(AimSettings.WallCheck) end
	    if uiRefs.autoFireToggle then uiRefs.autoFireToggle.Set(AimSettings.AutoFire) end
	    if uiRefs.drawFovToggle then uiRefs.drawFovToggle.Set(AimSettings.DrawFOV) end
	    if uiRefs.fovLabel then uiRefs.fovLabel.Text = "FOV Radius: " .. tostring(AimSettings.FOV) end
	    if uiRefs.fovBox then uiRefs.fovBox.Text = tostring(AimSettings.FOV) end
	    if uiRefs.smoothLabel then uiRefs.smoothLabel.Text = "Smoothness: " .. tostring(AimSettings.Smoothness) end
	    if uiRefs.smoothBox then uiRefs.smoothBox.Text = tostring(AimSettings.Smoothness) end
	    if uiRefs.espToggle then uiRefs.espToggle.Set(ESPSettings.Enabled) end
	    if uiRefs.enableESPToggle then uiRefs.enableESPToggle.Set(ESPSettings.Enabled) end
	    if uiRefs.showNameToggle then uiRefs.showNameToggle.Set(ESPSettings.ShowName) end
	    if uiRefs.showUsernameToggle then uiRefs.showUsernameToggle.Set(ESPSettings.ShowUsername) end
	    if uiRefs.showHPToggle then uiRefs.showHPToggle.Set(ESPSettings.ShowHP) end
	    if uiRefs.showDistanceToggle then uiRefs.showDistanceToggle.Set(ESPSettings.ShowDistance) end
	    if uiRefs.colorPreview then uiRefs.colorPreview.BackgroundColor3 = ESPSettings.Color end
	    if uiRefs.colorBox then
    	    uiRefs.colorBox.Text = string.format("%d,%d,%d",
            	math.floor(ESPSettings.Color.R*255+0.5), math.floor(ESPSettings.Color.G*255+0.5), math.floor(ESPSettings.Color.B*255+0.5))
    	end
    	if uiRefs.bindAimKey then uiRefs.bindAimKey.Set(AimSettings.Keybind) end
    	if uiRefs.bindToggleAimbot then uiRefs.bindToggleAimbot.Set(AimKeybinds.ToggleAimbot) end
    	if uiRefs.bindToggleESP then uiRefs.bindToggleESP.Set(AimKeybinds.ToggleESP) end
    	if uiRefs.bindToggleMenu then uiRefs.bindToggleMenu.Set(AimKeybinds.ToggleMenu) end
	end
	local function applyAimConfig(data)
	    if type(data) ~= "table" then return end
    	local a = data.Aimbot
    	if type(a) == "table" then
	        if a.Enabled ~= nil then AimSettings.Enabled = a.Enabled and true or false end
        	if a.Mode == "Hold" or a.Mode == "Toggle" or a.Mode == "Always" then AimSettings.Mode = a.Mode end
        	if a.AimPart == "Head" or a.AimPart == "RootPart" or a.AimPart == "All" then AimSettings.AimPart = a.AimPart end
        	if a.StickToTarget ~= nil then AimSettings.StickToTarget = a.StickToTarget and true or false end
        	if a.WallCheck ~= nil then AimSettings.WallCheck = a.WallCheck and true or false end
        	if a.AutoFire ~= nil then AimSettings.AutoFire = a.AutoFire and true or false end
        	if a.DrawFOV ~= nil then AimSettings.DrawFOV = a.DrawFOV and true or false end
        	if type(a.FOV) == "number" then AimSettings.FOV = math.clamp(a.FOV, 10, 500) end
        	if type(a.Smoothness) == "number" then AimSettings.Smoothness = math.clamp(a.Smoothness, 0.1, 1) end
        	if type(a.Sensitivity) == "number" then AimSettings.Sensitivity = math.clamp(a.Sensitivity, 0.05, 1) end
        	local kb = getEnumByName(a.Keybind) if kb then AimSettings.Keybind = kb end
    	end
    	local e = data.ESP
    	if type(e) == "table" then
	        if e.Enabled ~= nil then ESPSettings.Enabled = e.Enabled and true or false end
        	if type(e.Color) == "table" and e.Color[1] and e.Color[2] and e.Color[3] then
	            ESPSettings.Color = Color3.fromRGB(
                	math.clamp(tonumber(e.Color[1]) or 0, 0, 255),
                	math.clamp(tonumber(e.Color[2]) or 0, 0, 255),
                	math.clamp(tonumber(e.Color[3]) or 0, 0, 255))
        	end
        	if e.ShowName ~= nil then ESPSettings.ShowName = e.ShowName and true or false end
        	if e.ShowUsername ~= nil then ESPSettings.ShowUsername = e.ShowUsername and true or false end
        	if e.ShowHP ~= nil then ESPSettings.ShowHP = e.ShowHP and true or false end
        	if e.ShowDistance ~= nil then ESPSettings.ShowDistance = e.ShowDistance and true or false end
    	end
    	local k = data.Keybinds
    	if type(k) == "table" then
	        local v1 = getEnumByName(k.ToggleAimbot) if v1 then AimKeybinds.ToggleAimbot = v1 end
        	local v2 = getEnumByName(k.ToggleESP) if v2 then AimKeybinds.ToggleESP = v2 end
        	local v3 = getEnumByName(k.ToggleMenu) if v3 then AimKeybinds.ToggleMenu = v3 end
    	end
    	if AimSettings.Enabled then startAimbotLoop(); startKeybindListener() else stopAimbotLoop() end
	    if fovCircle then
        	fovCircle.Color = ESPSettings.Color
        	fovCircle.Visible = AimSettings.DrawFOV and AimSettings.Enabled
    	end	
    	if ESPSettings.Enabled then
        	for _, p in ipairs(Players:GetPlayers()) do
	            if p ~= LocalPlayer and not ESP_Instances[p] and p.Character then createESP(p) end
    	    end
    	end
    	refreshAimUI()
    	saveAimAuto()
	end
	local function resetAimDefaults()
    	stopAimbotLoop(); cleanESP()
    	AimSettings.Enabled = false; AimSettings.Mode = "Hold"; AimSettings.AimPart = "All"
    	AimSettings.StickToTarget = false; AimSettings.WallCheck = false; AimSettings.AutoFire = false
    	AimSettings.DrawFOV = true; AimSettings.FOV = 150; AimSettings.Smoothness = 0.2
    	AimSettings.Sensitivity = 0.45; AimSettings.ActiveToggle = false
    	AimSettings.Keybind = Enum.UserInputType.MouseButton2
    	ESPSettings.Enabled = false; ESPSettings.Color = Color3.fromRGB(0, 255, 150)
    	ESPSettings.ShowName = true; ESPSettings.ShowUsername = true
    	ESPSettings.ShowHP = true; ESPSettings.ShowDistance = true
    	AimKeybinds.ToggleAimbot = Enum.KeyCode.G; AimKeybinds.ToggleESP = Enum.KeyCode.H
    	AimKeybinds.ToggleMenu = Enum.KeyCode.RightShift
    	if fovCircle then fovCircle.Color = ESPSettings.Color; fovCircle.Visible = false end
    	refreshAimUI()
    	saveAimAuto()
	end
	--// Авто-восстановление сохранённых настроек при запуске
	if readfile and isfile and isfile(AIM_AUTO_FILE) then
	    local ok, json = pcall(function() return readfile(AIM_AUTO_FILE) end)
	    if ok and json then
        	local ok2, data = pcall(function() return HttpService:JSONDecode(json) end)
        	if ok2 and type(data) == "table" then applyAimConfig(data) end
    	end
	end

    --// Theme update
    local baseUpdateTabTheme2 = updateTabButtonsTheme
    updateTabButtonsTheme = function()
        baseUpdateTabTheme2()
        for _, tab in ipairs(aimTabs) do
            if tab.Button then
                if tab.Frame.Visible then
                    tab.Button.BackgroundColor3 = uiColor_ButtonColor
                    tab.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
                else
                    tab.Button.BackgroundColor3 = Color3.fromRGB(math.max(uiColor_ButtonColor.R*255-10,0), math.max(uiColor_ButtonColor.G*255-10,0), math.max(uiColor_ButtonColor.B*255-10,0))
                    tab.Button.TextColor3 = uiColor_TextColor
                end
            end
        end
    end

    --// Sidebar switching
    task.defer(function()
        local function hideAllFrames()
            for _, t in ipairs(tabs) do t.Frame.Visible = false end
            for _, t in ipairs(desyncTabs) do t.Frame.Visible = false end
            for _, t in ipairs(musicTabs) do t.Frame.Visible = false end
            for _, t in ipairs(aimTabs) do t.Frame.Visible = false end
        end

        local function showMainButtons()
            for _, t in ipairs(tabs) do if t.Button then t.Button.Visible = true end end
            for _, t in ipairs(desyncTabs) do t.Button.Visible = false end
            for _, t in ipairs(musicTabs) do t.Button.Visible = false end
            for _, t in ipairs(aimTabs) do t.Button.Visible = false end
        end

        local function showDesyncButtons()
            for _, t in ipairs(tabs) do if t.Button then t.Button.Visible = false end end
            for _, t in ipairs(desyncTabs) do t.Button.Visible = true end
            for _, t in ipairs(musicTabs) do t.Button.Visible = false end
            for _, t in ipairs(aimTabs) do t.Button.Visible = false end
        end

        local function showMusicButtons()
            for _, t in ipairs(tabs) do if t.Button then t.Button.Visible = false end end
            for _, t in ipairs(desyncTabs) do t.Button.Visible = false end
            for _, t in ipairs(musicTabs) do t.Button.Visible = true end
            for _, t in ipairs(aimTabs) do t.Button.Visible = false end
        end

        local function showAimButtons()
            for _, t in ipairs(tabs) do if t.Button then t.Button.Visible = false end end
            for _, t in ipairs(desyncTabs) do t.Button.Visible = false end
            for _, t in ipairs(musicTabs) do t.Button.Visible = false end
            for _, t in ipairs(aimTabs) do t.Button.Visible = true end
        end

        for _, t in ipairs(aimTabs) do
            t.Button.MouseButton1Click:Connect(function()
                hideAllFrames()
                t.Frame.Visible = true
                updateTabButtonsTheme()
            end)
        end

        for _, t in ipairs(tabs) do
            if t.Button then
                t.Button.MouseButton1Click:Connect(function()
                    for _, m in ipairs(musicTabs) do m.Frame.Visible = false end
                    for _, d in ipairs(desyncTabs) do d.Frame.Visible = false end
                    for _, a in ipairs(aimTabs) do a.Frame.Visible = false end
                    updateTabButtonsTheme()
                end)
            end
        end

        for _, t in ipairs(desyncTabs) do
            t.Button.MouseButton1Click:Connect(function()
                for _, m in ipairs(musicTabs) do m.Frame.Visible = false end
                for _, a in ipairs(aimTabs) do a.Frame.Visible = false end
                updateTabButtonsTheme()
            end)
        end

        for _, t in ipairs(musicTabs) do
            t.Button.MouseButton1Click:Connect(function()
                for _, a in ipairs(aimTabs) do a.Frame.Visible = false end
                for _, d in ipairs(desyncTabs) do d.Frame.Visible = false end
                updateTabButtonsTheme()
            end)
        end

        EmilyUi.MouseButton1Click:Connect(function()
            showMainButtons(); hideAllFrames()
            if tabs[1] then tabs[1].Frame.Visible = true end
            updateTabButtonsTheme()
        end)

        Desync.MouseButton1Click:Connect(function()
            showDesyncButtons(); hideAllFrames()
            if desyncTabs[1] then desyncTabs[1].Frame.Visible = true end
            updateTabButtonsTheme()
        end)

        Music.MouseButton1Click:Connect(function()
            showMusicButtons(); hideAllFrames()
            if musicTabs[1] then musicTabs[1].Frame.Visible = true end
            updateTabButtonsTheme()
        end)

        Aim.MouseButton1Click:Connect(function()
            showAimButtons(); hideAllFrames()
            if aimTabs[1] then aimTabs[1].Frame.Visible = true end
            updateTabButtonsTheme()
        end)
    end)

    return { Tabs = aimTabs, Gather = gatherAimConfig, Apply = applyAimConfig, Reset = resetAimDefaults }
end
local AimAPI = initAimbotModule(desyncTabs, musicTabs)

-- =========================================================
-- ========== MOVEMENT RECORDER MODULE =====================
-- =========================================================

local function initMovementModule(desyncTabs, musicTabs, aimTabs)
	desyncTabs = desyncTabs or {}
	musicTabs = musicTabs or {}
	aimTabs = aimTabs or {}

	--// Кнопка в левом сайдбаре
	local Movement = makeSideBtn("Movement", 236)
	Movement.TextSize = 11
	Movement.TextWrapped = true

	local C_GRN = Color3.fromRGB(100, 255, 100)
	local C_ROFF = Color3.fromRGB(255, 100, 100)
	local C_REDD = Color3.fromRGB(150, 40, 40)

	local SETTINGS_PATH = "EmilyUi/Movement/Keybinds/settings.json"
	local RECORDS_FOLDER = "EmilyUi/Movement/Records"
	local INDEX_PATH = RECORDS_FOLDER .. "/_index.json"

	local COLOR_MODES = {"Solid", "TwoWay", "ThreeWay", "Rainbow"}

	local Settings = {
		CircleRadius = 5,
		CircleThickness = 0.3,
		CircleHeight = 0.15,
		CircleTransparency = 0.35,
		CircleMode = "Solid",
		CircleColorA = {0, 140, 255},
		CircleColorB = {80, 255, 120},
		CircleColorC = {255, 170, 0},

		PathMode = "Solid",
		PathColorA = {80, 200, 255},
		PathColorB = {80, 255, 120},
		PathColorC = {255, 170, 0},
		PathTransparency = 0.25,
		PathPointSize = 0.35,
		TrailDistance = 10,
		TrailStep = 0,
		ShowPathPlayback = true,

		MinRecordDistance = 0.05,
		MinRecordTime = 0.08,

		ShowLabels = true,
		TextHeight = 4,
		TextTransparency = 0,
		TextDistance = 60,
		LabelMode = "Solid",
		LabelColorA = {255, 255, 255},
		LabelColorB = {80, 255, 120},
		LabelColorC = {255, 170, 0},

		PromptEnabled = true,
		PromptDistance = 12,

		PlaybackSpeed = 1,
		Loop = false,
		Legit = true,
	}

	local Keybinds = {
	    Menu = "RightShift",
	    Record = "R",
	    Play = "P",
	    Prompt = "E",
    }

    local MovementEnabled = false

	local function keyCodeByName(n)
		local ok, e = pcall(function() return Enum.KeyCode[n] end)
		if ok and e then return e end
		return Enum.KeyCode.E
	end

	local function lighter(c, amt)
		return Color3.fromRGB(
			math.min(c.R * 255 + amt, 255),
			math.min(c.G * 255 + amt, 255),
			math.min(c.B * 255 + amt, 255)
		)
	end

	local function darker(c, amt)
		return Color3.fromRGB(
			math.max(c.R * 255 - amt, 0),
			math.max(c.G * 255 - amt, 0),
			math.max(c.B * 255 - amt, 0)
		)
	end

	local function trim(s)
		return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
	end

	------------------------------------------------------------
	-- FILES
	------------------------------------------------------------

	local function filesOK()
		return typeof(writefile) == "function"
			and typeof(readfile) == "function"
			and typeof(makefolder) == "function"
			and typeof(isfolder) == "function"
	end

	local function ensureFolders()
		if not filesOK() then return end
		pcall(function()
			if not isfolder("EmilyUi") then makefolder("EmilyUi") end
			if not isfolder("EmilyUi/Movement") then makefolder("EmilyUi/Movement") end
			if not isfolder("EmilyUi/Movement/Records") then makefolder("EmilyUi/Movement/Records") end
			if not isfolder("EmilyUi/Movement/Keybinds") then makefolder("EmilyUi/Movement/Keybinds") end
		end)
	end

	local function writeJSON(path, data)
		if not filesOK() then return end
		ensureFolders()
		local ok, json = pcall(function() return HttpService:JSONEncode(data) end)
		if ok then
			pcall(function() writefile(path, json) end)
		end
	end

	local function readJSON(path)
		if typeof(readfile) ~= "function" then return nil end
		local ok, json = pcall(function() return readfile(path) end)
		if not ok or type(json) ~= "string" or json == "" then return nil end
		local ok2, data = pcall(function() return HttpService:JSONDecode(json) end)
		if ok2 and type(data) == "table" then return data end
		return nil
	end

	local function sanitize(name)
		return tostring(name):gsub('[\\/:*?"<>|]', "_")
	end

	local function saveSettings()
		writeJSON(SETTINGS_PATH, {Settings = Settings, Keybinds = Keybinds})
	end

	local function loadSettings()
		local d = readJSON(SETTINGS_PATH)
		if not d then return end

		local raw = d.Settings
		if type(raw) == "table" then
			for _, k in ipairs({"CircleMode", "PathMode", "LabelMode"}) do
				if raw[k] == "Gradient" then raw[k] = "TwoWay" end
				if raw[k] == "TriColor" then raw[k] = "ThreeWay" end
			end

			if type(raw.TextColor) == "table" and type(raw.LabelColorA) ~= "table" then
				raw.LabelColorA = raw.TextColor
			end

			for k, v in pairs(raw) do
				if Settings[k] ~= nil and type(v) == type(Settings[k]) then
					Settings[k] = v
				end
			end
		end

		for _, k in ipairs({"CircleMode", "PathMode", "LabelMode"}) do
			if not table.find(COLOR_MODES, Settings[k]) then
				Settings[k] = "Solid"
			end
		end

		if type(d.Keybinds) == "table" then
			for k, v in pairs(d.Keybinds) do
				if Keybinds[k] ~= nil and type(v) == "string" then
					Keybinds[k] = v
				end
			end
		end
	end

	loadSettings()

	------------------------------------------------------------
	-- SERIALIZATION
	------------------------------------------------------------

	local function serCF(cf)
		if typeof(cf) ~= "CFrame" then return {0, 0, 0} end
		return {cf:GetComponents()}
	end

	local function deCF(t)
		if type(t) ~= "table" then return CFrame.new() end
		if #t >= 12 then
			local ok, cf = pcall(function() return CFrame.new(unpack(t, 1, 12)) end)
			if ok then return cf end
		end
		if #t >= 3 then return CFrame.new(t[1], t[2], t[3]) end
		return CFrame.new()
	end

	local function serEntry(e)
		local frames = {}
		for _, f in ipairs(e.Frames or {}) do
			table.insert(frames, {f.time, serCF(f.cframe)})
		end
		return {N = e.Name, S = serCF(e.StartCFrame), F = frames}
	end

	local function deEntry(d)
		local frames = {}
		for _, f in ipairs(d.F or {}) do
			if type(f) == "table" and f[2] then
				table.insert(frames, {time = tonumber(f[1]) or 0, cframe = deCF(f[2])})
			end
		end

		local e = {
			Name = tostring(d.N or "Recording"),
			StartCFrame = deCF(d.S),
			Frames = frames,
		}

		if #frames > 0 and not d.S then
			e.StartCFrame = frames[1].cframe
		end

		return e
	end

	------------------------------------------------------------
	-- LIBRARY
	------------------------------------------------------------

	local library = {categories = {Default = {}}}
    local selectedCategory = "Default"
    local selectedRecording = nil

    local CATEGORY_INDEX_PATH = RECORDS_FOLDER .. "/_categories.json"
    local OLD_INDEX_PATH = INDEX_PATH or (RECORDS_FOLDER .. "/_index.json")

    local function normalizeChildPath(base, child)
	    child = tostring(child)
	    if child:find("[/\\]") or child:match("^%a:") then
    		return child
    	end
    	return base .. "/" .. child
    end

    local function categoryPath(catName)
    	return RECORDS_FOLDER .. "/" .. sanitize(catName)
    end

    local function ensureCategoryFolder(catName)
    	if not filesOK() then return end
    	pcall(function()
		    if not isfolder(categoryPath(catName)) then
    			makefolder(categoryPath(catName))
		    end
	    end)
    end

    local function generateRecordId()
    	local ok, guid = pcall(function() return HttpService:GenerateGUID(false) end)
    	if ok and type(guid) == "string" and guid ~= "" then
		    return guid
	    end

    	return string.format(
		    "rec_%s_%d_%d",
		    os.date("%Y%m%d%H%M%S"),
		    math.floor(os.clock() * 1000),
		    math.random(1000, 999999)
	    )
    end

    local function serializeRecord(e)
    	local d = serEntry(e)
    	d.Id = e.Id
    	return d
    end

    local function recordFilePath(catName, entry)
    	return categoryPath(catName) .. "/" .. tostring(entry.Id or "record") .. ".json"
    end

    local function sortCategoryNames(names)
    	table.sort(names, function(a, b)
		    if a == "Default" then return true end
		    if b == "Default" then return false end
		    return tostring(a) < tostring(b)
	    end)
    end

    local function getCategoryNames()
    	local names = {}

	    local function addName(n)
    		n = tostring(n or "")
		    if n == "" then return end
		    if n:find("^_") then return end
		    if not table.find(names, n) then
    			table.insert(names, n)
		    end
	    end

	    local indexData = readJSON(CATEGORY_INDEX_PATH)
	    local hasIndex = false

	    if indexData and type(indexData.categories) == "table" then
    		hasIndex = true
		    for _, n in ipairs(indexData.categories) do
    			addName(n)
		    end
	    end

	    -- Если нового индекса нет, пытаемся найти категории по старым файлам/папкам
	    if not hasIndex then
    		local oldIndex = readJSON(OLD_INDEX_PATH)
		    if oldIndex and type(oldIndex.categories) == "table" then
    			for _, n in ipairs(oldIndex.categories) do
				    addName(n)
			    end
		    end

		    if typeof(listfiles) == "function" then
    			local ok, items = pcall(function() return listfiles(RECORDS_FOLDER) end)
			    if ok and items then
    				for _, raw in ipairs(items) do
					    local p = normalizeChildPath(RECORDS_FOLDER, raw)
					    local base = p:match("([^/\\]+)$") or ""

					    local isDir = false
					    if typeof(isfolder) == "function" then
    						local ok2, val = pcall(function() return isfolder(p) end)
						    isDir = ok2 and val
					    end

					    if isDir then
    						if not base:find("^_") then
							    addName(base)
						    end
					    else
    						local name = base:match("^(.*)%.json$")
						    if name and name ~= "_index" and name ~= "_categories" then
    							addName(name)
						    end
					    end
				    end
			    end
		    end
	    end

	    addName("Default")
	    sortCategoryNames(names)
	    return names
    end

    local function saveCategoryIndex()
    	local names = {}
    	for n in pairs(library.categories) do
		    table.insert(names, n)
	    end
	    sortCategoryNames(names)
	    writeJSON(CATEGORY_INDEX_PATH, {categories = names})
    end

    local function deleteFilesInFolder(path)
    	if typeof(listfiles) ~= "function" or typeof(delfile) ~= "function" then
		    return
	    end

    	local ok, items = pcall(function() return listfiles(path) end)
    	if not ok or not items then return end

    	for _, raw in ipairs(items) do
		    local p = normalizeChildPath(path, raw)
		    if p:match("%.json$") then
    			pcall(function() delfile(p) end)
		    end
	    end
    end

    local function saveCategoryFile(catName)
    	if not filesOK() then return end

    	ensureFolders()
    	ensureCategoryFolder(catName)

	    local path = categoryPath(catName)

	    -- Удаляем старые файлы записей в папке категории и перезаписываем актуальные
	    deleteFilesInFolder(path)

	    for _, entry in ipairs(library.categories[catName] or {}) do
    		if not entry.Id then
			    entry.Id = generateRecordId()
		    end
		    writeJSON(recordFilePath(catName, entry), serializeRecord(entry))
	    end

	    saveCategoryIndex()
    end

    local function deleteCategoryFile(catName)
    	if filesOK() then
		    local path = categoryPath(catName)
		    deleteFilesInFolder(path)

		    if typeof(delfolder) == "function" then
    			pcall(function() delfolder(path) end)
		    end
	    end

	    saveCategoryIndex()
    end

    local function migrateOldCategory(catName)
    	local list = {}
    	local oldFile = RECORDS_FOLDER .. "/" .. sanitize(catName) .. ".json"
    	local data = readJSON(oldFile)

	    if data ~= nil then
    		if type(data) == "table" then
	    		for _, d in ipairs(data) do
				    local e = deEntry(d)
				    if not e.Id then
					    e.Id = generateRecordId()
				    end
				    table.insert(list, e)
			    end
		    end

		    -- После миграции удаляем старый формат категории
		    if filesOK() and typeof(delfile) == "function" then
			    pcall(function() delfile(oldFile) end)
		    end
	    end

	    if #list > 0 and filesOK() then
    		ensureCategoryFolder(catName)
		    for _, e in ipairs(list) do
    			writeJSON(recordFilePath(catName, e), serializeRecord(e))
		    end
	    end

	    return list
    end

    local function loadCategoryRecords(catName)
    	local list = {}
    	local path = categoryPath(catName)

    	local folderExists = false
    	if typeof(isfolder) == "function" then
		    local ok, exists = pcall(function() return isfolder(path) end)
		    folderExists = ok and exists
	    end

	    if folderExists then
    		if typeof(listfiles) == "function" then
			    local ok, files = pcall(function() return listfiles(path) end)
			    if ok and files then
    				for _, raw in ipairs(files) do
					    local fp = normalizeChildPath(path, raw)

					    if fp:match("%.json$") then
    						local data = readJSON(fp)
						    if type(data) == "table" then
    							local e = deEntry(data)
							    e.Id = tostring(data.Id or fp:match("([^/\\]+)%.json$") or generateRecordId())
							    table.insert(list, e)
						    end
					    end
				    end
			    end
		    end

		    table.sort(list, function(a, b)
    			return tostring(a.Name) < tostring(b.Name)
		    end)
	    else
    		list = migrateOldCategory(catName)
    	end

    	return list
    end

    local function loadLibrary()
    	library = {categories = {}}

    	local names = getCategoryNames()

	    for _, n in ipairs(names) do
    		library.categories[n] = loadCategoryRecords(n)
    	end

    	if not library.categories.Default then
		    library.categories.Default = {}
	    end

	    if not library.categories[selectedCategory] then
    		selectedCategory = "Default"
    	end

    	selectedRecording = nil

    	if filesOK() then
		    for n in pairs(library.categories) do
    			ensureCategoryFolder(n)
		    end
	    end

	    saveCategoryIndex()
    end

	------------------------------------------------------------
	-- CHARACTER
	------------------------------------------------------------

	local character = LocalPlayer.Character
	local humanoid = nil
	local rootPart = nil
	local characterDiedConnection = nil

	local function isFiniteNumber(v)
		return typeof(v) == "number" and v == v and math.abs(v) ~= math.huge
	end

	local function isFiniteCFrame(cf)
		if typeof(cf) ~= "CFrame" then return false end
		for _, v in ipairs({cf:GetComponents()}) do
			if not isFiniteNumber(v) then return false end
		end
		return true
	end

	local function isCharacterAlive()
		return humanoid and humanoid.Parent and rootPart and rootPart.Parent and humanoid.Health > 0
	end

	------------------------------------------------------------
	-- COLOR HELPERS
	------------------------------------------------------------

	local function cArr(a)
		return Color3.fromRGB(a[1] or 255, a[2] or 255, a[3] or 255)
	end

	local function cycle3(a, b, c, t)
		t = t % 1
		if t < 1 / 3 then
			return a:Lerp(b, t * 3)
		elseif t < 2 / 3 then
			return b:Lerp(c, (t - 1 / 3) * 3)
		end
		return c:Lerp(a, (t - 2 / 3) * 3)
	end

	local function pathColorAt(t)
		local mode = Settings.PathMode
		local a = cArr(Settings.PathColorA)
		local b = cArr(Settings.PathColorB)
		local c = cArr(Settings.PathColorC)

		if mode == "TwoWay" then return a:Lerp(b, t) end
		if mode == "ThreeWay" then return cycle3(a, b, c, t) end
		if mode == "Rainbow" then return Color3.fromHSV(t % 1, 1, 1) end
		return a
	end

	local function timeColorAt(mode, arrA, arrB, arrC, t)
		local a = cArr(arrA)
		local b = cArr(arrB)
		local c = cArr(arrC)

		if mode == "TwoWay" then
			return a:Lerp(b, (math.sin(t * 1.6) + 1) / 2)
		elseif mode == "ThreeWay" then
			return cycle3(a, b, c, t * 0.25)
		elseif mode == "Rainbow" then
			return Color3.fromHSV((t * 0.12) % 1, 1, 1)
		end

		return a
	end

	local function circleColorAt(t)
		return timeColorAt(Settings.CircleMode, Settings.CircleColorA, Settings.CircleColorB, Settings.CircleColorC, t)
	end

	local function labelColorAt(t)
		return timeColorAt(Settings.LabelMode, Settings.LabelColorA, Settings.LabelColorB, Settings.LabelColorC, t)
	end

	------------------------------------------------------------
	-- CONNECTIONS / FORWARD DECLARATIONS
	------------------------------------------------------------

	local movementConnections = {}
	local function mConnect(sig, cb)
		local cn = sig:Connect(cb)
		table.insert(movementConnections, cn)
		return cn
	end

	local setStatus, updateButtons, refreshMainInfo
	local refreshRecordings, refreshCategories
	local rebuildMarkers
	local requestPlayback, stopPlayback, stopRecording, startRecording
	local movementBindCapture = nil
	local nameBox = nil

	------------------------------------------------------------
	-- MARKERS
	------------------------------------------------------------

	local markersFolder = Instance.new("Folder")
    markersFolder.Name = "MovementRecorderMarkers"
    pcall(function() markersFolder.Parent = nil end)

	local markerData = {}

	local function createTrajectory(entry, model)
		local frames = entry.Frames
		if not frames or #frames < 2 then return end

		local step
		if Settings.TrailStep > 0 then
			step = math.max(1, math.floor(Settings.TrailStep))
		else
			step = math.max(1, math.floor(#frames / 140))
		end

		local total = math.floor((#frames - 1) / step) + 1
		local idx = 0

		for i = 1, #frames, step do
			local f = frames[i]
			if f and f.cframe then
				local p = Instance.new("Part")
				p.Anchored = true
				p.CanCollide = false
				pcall(function()
					p.CanTouch = false
					p.CanQuery = false
				end)
				p.Size = Vector3.new(Settings.PathPointSize, Settings.PathPointSize, Settings.PathPointSize)
				p.Material = Enum.Material.Neon
				p.Color = pathColorAt(total > 1 and (idx / (total - 1)) or 0)
				p.Transparency = Settings.PathTransparency
				p.CFrame = CFrame.new(f.cframe.Position)
				p.Parent = model
				idx = idx + 1
			end
		end
	end

	local function createMarker(entry)
		if not entry then return end

		if markerData[entry] then
			pcall(function() markerData[entry].Model:Destroy() end)
			markerData[entry] = nil
		end

		if not entry.StartCFrame and entry.Frames and entry.Frames[1] then
			entry.StartCFrame = entry.Frames[1].cframe
		end

		if not entry.StartCFrame then return end

		local model = Instance.new("Model")
		model.Name = "MovementMarker"

		local circle = Instance.new("Part")
		circle.Name = "Circle"
		circle.Shape = Enum.PartType.Cylinder
		circle.Size = Vector3.new(Settings.CircleThickness, Settings.CircleRadius * 2, Settings.CircleRadius * 2)
		circle.Anchored = true
		circle.CanCollide = false
		pcall(function()
			circle.CanTouch = false
			circle.CanQuery = false
		end)
		circle.Material = Enum.Material.Neon
		circle.Color = circleColorAt(0)
		circle.Transparency = Settings.CircleTransparency

		local pos = entry.StartCFrame.Position
		circle.CFrame = CFrame.new(pos.X, pos.Y + Settings.CircleHeight, pos.Z) * CFrame.Angles(0, 0, math.rad(90))
		circle.Parent = model

		local billboard = Instance.new("BillboardGui")
		billboard.Adornee = circle
		billboard.Size = UDim2.new(0, 260, 0, 44)
		billboard.StudsOffset = Vector3.new(0, Settings.TextHeight, 0)
		billboard.AlwaysOnTop = true
		billboard.MaxDistance = Settings.TextDistance
		billboard.Enabled = Settings.ShowLabels
		billboard.Parent = model

		local label = create("TextLabel", {
			Parent = billboard,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = entry.Name,
			TextColor3 = labelColorAt(0),
			TextTransparency = Settings.TextTransparency,
			TextSize = 16,
			Font = FONT,
		})

		local traj = Instance.new("Model")
		traj.Name = "Trajectory"
		createTrajectory(entry, traj)
		traj.Parent = nil

		local prompt = Instance.new("ProximityPrompt")
		prompt.Parent = circle
		prompt.Enabled = Settings.PromptEnabled
		prompt.MaxActivationDistance = Settings.PromptDistance
		prompt.RequiresLineOfSight = false
		prompt.HoldDuration = 0
		prompt.ActionText = "Play"
		prompt.ObjectText = entry.Name
		prompt.KeyboardKeyCode = keyCodeByName(Keybinds.Prompt)
		prompt.Triggered:Connect(function()
    		if not MovementEnabled then return end
		    requestPlayback(entry)
	    end)

		model.Parent = markersFolder

		markerData[entry] = {
			Model = model,
			Circle = circle,
			Label = label,
			Billboard = billboard,
			Trajectory = traj,
			Prompt = prompt,
			StartPos = pos,
			TrailShown = false,
		}
	end

	rebuildMarkers = function()
		for _, data in pairs(markerData) do
			pcall(function() data.Model:Destroy() end)
		end
		markerData = {}

		for _, entries in pairs(library.categories) do
			for _, entry in ipairs(entries) do
				createMarker(entry)
			end
		end
	end

	------------------------------------------------------------
	-- MOVERS
	------------------------------------------------------------

	local movers = {
		kind = nil,
		attachment = nil,
		position = nil,
		orientation = nil,
		bodyPos = nil,
		bodyGyro = nil,
	}

	local canUseAlign = pcall(function()
		return Enum.PositionAlignmentMode.OneAttachment and Enum.OrientationAlignmentMode.OneAttachment
	end)

	local function clearMovers()
		for _, key in ipairs({"attachment", "position", "orientation", "bodyPos", "bodyGyro"}) do
			local o = movers[key]
			if o then pcall(function() o:Destroy() end) end
			movers[key] = nil
		end
		movers.kind = nil
	end

	local function createMovers()
		clearMovers()
		if not rootPart or not rootPart.Parent then return end

		local ok = false

		if canUseAlign then
			ok = pcall(function()
				local att = Instance.new("Attachment")
				att.Parent = rootPart

				local ap = Instance.new("AlignPosition")
				ap.Attachment0 = att
				ap.Mode = Enum.PositionAlignmentMode.OneAttachment
				ap.Position = rootPart.CFrame.Position
				ap.MaxForce = 100000
				ap.MaxVelocity = 5000
				ap.Responsiveness = 170
				ap.Parent = rootPart

				local ao = Instance.new("AlignOrientation")
				ao.Attachment0 = att
				ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
				ao.CFrame = rootPart.CFrame
				ao.MaxTorque = 100000
				ao.Responsiveness = 170
				ao.Parent = rootPart

				movers.kind = "Align"
				movers.attachment = att
				movers.position = ap
				movers.orientation = ao
			end)
		end

		if not ok then
			clearMovers()
			pcall(function()
				local bp = Instance.new("BodyPosition")
				bp.MaxForce = Vector3.new(50000, 50000, 50000)
				bp.P = 15000
				bp.D = 1200
				bp.Position = rootPart.CFrame.Position
				bp.Parent = rootPart

				local bg = Instance.new("BodyGyro")
				bg.MaxTorque = Vector3.new(50000, 50000, 50000)
				bg.P = 18000
				bg.D = 1200
				bg.CFrame = rootPart.CFrame
				bg.Parent = rootPart

				movers.kind = "Body"
				movers.bodyPos = bp
				movers.bodyGyro = bg
			end)
		end
	end

	local function setMoversTarget(cf)
		if not isFiniteCFrame(cf) then return end

		if movers.kind == "Align" then
			if movers.position then movers.position.Position = cf.Position end
			if movers.orientation then movers.orientation.CFrame = cf end
		elseif movers.kind == "Body" then
			if movers.bodyPos then movers.bodyPos.Position = cf.Position end
			if movers.bodyGyro then movers.bodyGyro.CFrame = cf end
		end
	end

	------------------------------------------------------------
	-- STATE MACHINE
	------------------------------------------------------------

	local State = {Idle = 0, Recording = 1, Aligning = 2, Playing = 3}
	local state = State.Idle

	local recorded = {}
	local recordStartTime = 0
	local playbackStart = 0
	local playbackIndex = 1
	local currentPlayback = nil
	local alignStart = 0

	local MAX_POINTS = 12000

	local function isPlayerInside(entry)
		local data = markerData[entry]
		if not data or not rootPart or not rootPart.Parent then return false end

		local p = rootPart.Position
		local s = data.StartPos

		if math.abs(p.Y - s.Y) > 12 then return false end
		return Vector2.new(p.X - s.X, p.Z - s.Z).Magnitude <= Settings.CircleRadius
	end

	local function beginPlayback(entry)
		state = State.Playing
		playbackStart = os.clock()
		playbackIndex = 1
		currentPlayback = entry

		if humanoid then humanoid.AutoRotate = false end
		if not Settings.Legit then clearMovers() end

		if updateButtons then updateButtons() end
		if setStatus then setStatus("Playing: " .. entry.Name) end
	end

	stopPlayback = function()
		if state ~= State.Playing and state ~= State.Aligning then return end

		state = State.Idle
		currentPlayback = nil
		clearMovers()

		if humanoid then humanoid.AutoRotate = true end

		if updateButtons then updateButtons() end
		if setStatus then setStatus("Playback stopped.") end
	end

	requestPlayback = function(entry)
	    if not MovementEnabled then
    		if setStatus then setStatus("Movement is disabled.") end
		    return
	    end 

	    if not unlocked then
    		if setStatus then setStatus("Script is locked.") end
		    return
	    end

	    if state ~= State.Idle then return end

		entry = entry or selectedRecording
		if not entry or not entry.Frames or #entry.Frames < 2 then
			if setStatus then setStatus("No recording selected.") end
			return
		end

		if not isCharacterAlive() then
			if setStatus then setStatus("Character unavailable.") end
			return
		end

		if not markerData[entry] then
			createMarker(entry)
		end

		if not isPlayerInside(entry) then
			if setStatus then setStatus("Stand inside the circle of this recording first.") end
			return
		end

		if not Settings.Legit then
			if rootPart and isFiniteCFrame(entry.Frames[1].cframe) then
				rootPart.CFrame = entry.Frames[1].cframe
			end
			beginPlayback(entry)
		else
			state = State.Aligning
			currentPlayback = entry
			alignStart = os.clock()
			createMovers()

			if updateButtons then updateButtons() end
			if setStatus then setStatus("Aligning to start position...") end
		end
	end

	stopRecording = function(save)
		if state ~= State.Recording then return end

		state = State.Idle
		if save == nil then save = true end

		if save and #recorded >= 2 then
			if not library.categories[selectedCategory] then
				library.categories[selectedCategory] = {}
			end

			local customName = trim(nameBox and nameBox.Text or "")
			if customName == "" then
				customName = "Recording " .. os.date("%H:%M:%S")
			end

			local entry = {
	            Id = generateRecordId(),
	            Name = customName,
	            StartCFrame = recorded[1].cframe,
	            Frames = recorded,
            }

			table.insert(library.categories[selectedCategory], entry)
			selectedRecording = entry

			createMarker(entry)
			saveCategoryFile(selectedCategory)

			if refreshRecordings then refreshRecordings() end
			if refreshMainInfo then refreshMainInfo() end
			if setStatus then setStatus("Saved: " .. customName) end
			if nameBox then nameBox.Text = "" end
		else
			if setStatus then setStatus("Recording stopped.") end
		end

		recorded = {}
		if updateButtons then updateButtons() end
	end

	startRecording = function()
	    if not MovementEnabled then
		    if setStatus then setStatus("Movement is disabled.") end
    		return
	    end

	    if not unlocked then
		    if setStatus then setStatus("Script is locked.") end
    		return
	    end

	    if state ~= State.Idle then return end

		if not isCharacterAlive() then
			if setStatus then setStatus("Character unavailable.") end
			return
		end

		recorded = {}
		recordStartTime = os.clock()
		state = State.Recording

		if updateButtons then updateButtons() end
		if setStatus then setStatus("Recording... move now.") end
	end

	------------------------------------------------------------
	-- MAIN HEARTBEAT
	------------------------------------------------------------

	mConnect(RunService.Heartbeat, function()
		if state == State.Recording then
			if not isCharacterAlive() then
				stopRecording(false)
				return
			end

			local cf = rootPart.CFrame
			if not isFiniteCFrame(cf) then return end

			local now = os.clock() - recordStartTime
			local last = recorded[#recorded]

			if not last then
				table.insert(recorded, {time = now, cframe = cf})
			else
				local moved = (cf.Position - last.cframe.Position).Magnitude >= Settings.MinRecordDistance
				local timePassed = (now - last.time) >= Settings.MinRecordTime
				if moved or timePassed then
					table.insert(recorded, {time = now, cframe = cf})
				end
			end

			if #recorded >= MAX_POINTS then
				stopRecording(true)
			end

		elseif state == State.Aligning then
			if not isCharacterAlive() or not currentPlayback then
				stopPlayback()
				return
			end

			local first = currentPlayback.Frames[1]
			if not first then
				stopPlayback()
				return
			end

			setMoversTarget(first.cframe)

			local d = (rootPart.Position - first.cframe.Position).Magnitude
			local dot = rootPart.CFrame.LookVector:Dot(first.cframe.LookVector)

			if (d < 0.2 and dot > 0.97) or (os.clock() - alignStart > 6) then
				beginPlayback(currentPlayback)
			end

		elseif state == State.Playing then
			if not isCharacterAlive() or not currentPlayback then
				stopPlayback()
				return
			end

			local frames = currentPlayback.Frames
			local speed = tonumber(Settings.PlaybackSpeed) or 1
			if speed <= 0 then speed = 1 end

			local elapsed = (os.clock() - playbackStart) * speed
			local last = frames[#frames]

			if not last or last.time <= 0 then
				stopPlayback()
				return
			end

			if elapsed >= last.time then
				if Settings.Loop then
					playbackStart = os.clock()
					playbackIndex = 1
					elapsed = 0
				else
					stopPlayback()
					return
				end
			end

			while playbackIndex < #frames and frames[playbackIndex + 1].time <= elapsed do
				playbackIndex = playbackIndex + 1
			end

			local a = frames[playbackIndex]
			local b = frames[playbackIndex + 1] or a
			local target = a.cframe

			if b ~= a and b.time > a.time then
				local alpha = math.clamp((elapsed - a.time) / (b.time - a.time), 0, 1)
				target = a.cframe:Lerp(b.cframe, alpha)
			end

			if Settings.Legit then
				setMoversTarget(target)
			else
				if rootPart and isFiniteCFrame(target) then
					rootPart.CFrame = target
				end
			end
		end
	end)

	------------------------------------------------------------
	-- PROXIMITY / TRAIL / COLOR ANIMATION
	------------------------------------------------------------

	local lastProx = 0

	mConnect(RunService.Heartbeat, function()
		local animCircle = Settings.CircleMode ~= "Solid"
		local animLabel = Settings.LabelMode ~= "Solid"

		if animCircle or animLabel then
			local t = tick()
			local cCol = animCircle and circleColorAt(t) or nil
			local lCol = animLabel and labelColorAt(t) or nil

			for _, data in pairs(markerData) do
				if cCol then data.Circle.Color = cCol end
				if lCol then data.Label.TextColor3 = lCol end
			end
		end

		if os.clock() - lastProx < 0.15 then return end
		lastProx = os.clock()

		if not rootPart or not rootPart.Parent then return end
		local pos = rootPart.Position

		for entry, data in pairs(markerData) do
			local distXZ = Vector2.new(pos.X - data.StartPos.X, pos.Z - data.StartPos.Z).Magnitude
			local yOk = math.abs(pos.Y - data.StartPos.Y) <= 12

			local trailVisible
			if state == State.Playing and currentPlayback == entry then
				trailVisible = Settings.ShowPathPlayback and true or false
			else
				trailVisible = yOk and distXZ <= Settings.TrailDistance
			end

			if trailVisible ~= data.TrailShown then
				data.TrailShown = trailVisible
				data.Trajectory.Parent = trailVisible and data.Model or nil
			end
		end
	end)

	------------------------------------------------------------
	-- UI HELPERS
	------------------------------------------------------------

	local buttonBase = setmetatable({}, {__mode = "k"})

	local function setButtonBaseColor(b, c)
		buttonBase[b] = c
	end

	local function mvLabel(parent, text, height)
		local l = create("TextLabel", {
			Parent = parent,
			Size = UDim2.new(1, 0, 0, height or 22),
			BackgroundTransparency = 1,
			Text = text,
			TextColor3 = uiColor_TextColor,
			TextSize = 13,
			Font = FONT,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
		})
		table.insert(themeElements.Texts, l)
		return l
	end

	local function mvBox(parent, placeholder, height)
		local b = create("TextBox", {
			Parent = parent,
			Size = UDim2.new(1, 0, 0, height or 26),
			BackgroundColor3 = uiColor_TextBoxColor,
			BorderColor3 = COL_BORDER,
			TextColor3 = uiColor_TextColor,
			PlaceholderColor3 = Color3.fromRGB(90, 90, 90),
			PlaceholderText = placeholder,
			Text = "",
			TextSize = 13,
			Font = FONT,
			ClearTextOnFocus = false,
		})
		b.BackgroundTransparency = 1 - uiGuiOpacity
		table.insert(themeElements.TextBoxes, b)
		table.insert(themeElements.Texts, b)
		return b
	end

	local function mvButton(parent, text, callback, customBg, customTc, height)
		local b = create("TextButton", {
			Parent = parent,
			Size = UDim2.new(1, 0, 0, height or 30),
			BackgroundColor3 = customBg or uiColor_ButtonColor,
			BorderColor3 = COL_BORDER,
			TextColor3 = customTc or uiColor_TextColor,
			Text = text,
			Font = FONT,
			TextSize = 13,
			TextWrapped = true,
		})

		if not customBg and not customTc then
			table.insert(themeElements.Buttons, b)
			table.insert(themeElements.Texts, b)
		else
			table.insert(themeElements.CustomButtons, b)
		end

		b.BackgroundTransparency = 1 - uiGuiOpacity

		b.MouseEnter:Connect(function()
			local c = b.BackgroundColor3
			b.BackgroundColor3 = lighter(c, 10)
		end)

		if customBg == nil then
			b.MouseLeave:Connect(function()
				b.BackgroundColor3 = uiColor_ButtonColor
			end)
		else
			buttonBase[b] = customBg
			b.MouseLeave:Connect(function()
				b.BackgroundColor3 = buttonBase[b] or customBg
			end)
		end

		if callback then
			b.MouseButton1Click:Connect(callback)
		end

		return b
	end

	local function mvList(parent, height)
		local f = create("ScrollingFrame", {
			Parent = parent,
			Size = UDim2.new(1, 0, 0, height or 180),
			BackgroundColor3 = uiColor_TextBoxColor,
			BorderColor3 = COL_BORDER,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = COL_BORDER,
			CanvasSize = UDim2.new(0, 0, 0, 0),
		})
		f.BackgroundTransparency = 1 - uiGuiOpacity
		table.insert(themeElements.TextBoxes, f)

		local l = create("UIListLayout", {
			Parent = f,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 3),
		})

		create("UIPadding", {
			Parent = f,
			PaddingTop = UDim.new(0, 3),
			PaddingLeft = UDim.new(0, 3),
			PaddingRight = UDim.new(0, 3),
		})

		l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			f.CanvasSize = UDim2.new(0, 0, 0, l.AbsoluteContentSize.Y + 8)
		end)

		return f
	end

	local function clearList(f)
		for _, ch in ipairs(f:GetChildren()) do
			if ch:IsA("TextButton") or ch:IsA("TextLabel") then
				ch:Destroy()
			end
		end
	end

	local function mvListItem(parent, text, selected, callback, height)
		local bg = selected and lighter(uiColor_ButtonColor, 30) or uiColor_ButtonColor
		local tc = selected and Color3.fromRGB(255, 255, 255) or uiColor_TextColor

		local b = create("TextButton", {
			Parent = parent,
			Size = UDim2.new(1, 0, 0, height or 26),
			BackgroundColor3 = bg,
			BorderColor3 = COL_BORDER,
			TextColor3 = tc,
			Text = text,
			Font = FONT,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
		})

		b.BackgroundTransparency = 1 - uiGuiOpacity

		b.MouseEnter:Connect(function()
			local c = b.BackgroundColor3
			b.BackgroundColor3 = lighter(c, 10)
		end)

		b.MouseLeave:Connect(function()
			b.BackgroundColor3 = bg
		end)

		b.MouseButton1Click:Connect(callback)
		return b
	end

	------------------------------------------------------------
	-- MOVEMENT TABS
	------------------------------------------------------------

	local movementTabs = {}

	local function addMovementTab(name, builder)
		local frame = create("Frame", {
			Name = "Tab" .. name,
			Parent = Containment,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Visible = false,
		})

		local sf = create("ScrollingFrame", {
			Parent = frame,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = COL_BORDER,
			CanvasSize = UDim2.new(0, 0, 0, 0),
		})

		local tl = create("UIListLayout", {
			Parent = sf,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
		})

		create("UIPadding", {
			Parent = sf,
			PaddingTop = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		})

		tl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			sf.CanvasSize = UDim2.new(0, 0, 0, tl.AbsoluteContentSize.Y + 20)
		end)

		builder(sf)

		local btn = create("TextButton", {
			Name = "MoveBtn_" .. name,
			Parent = MenuInsided,
			Size = UDim2.new(1, 0, 0, 40),
			LayoutOrder = 400 + #movementTabs,
			Visible = false,
			BackgroundColor3 = uiColor_ButtonColor,
			BorderColor3 = COL_BORDER,
			TextColor3 = uiColor_TextColor,
			Text = name,
			Font = FONT,
			TextSize = 12,
			TextWrapped = true,
		})

		table.insert(themeElements.Buttons, btn)
		table.insert(themeElements.Texts, btn)

		local entry = {
			Frame = frame,
			Name = name,
			Button = btn,
		}

		table.insert(movementTabs, entry)
		return entry
	end

	------------------------------------------------------------
	-- TAB: MAIN
	------------------------------------------------------------

	local statusLabel, infoLabel, movementToggleBtn
    local startRecBtn, stopRecBtn, playBtn, stopPlayBtn

	addMovementTab("Main", function(p)
	    createSection(p, "MOVEMENT RECORDER")
	    statusLabel = mvLabel(p, "Ready.", 40)

	    movementToggleBtn = mvButton(p, "TOGGLE: OFF", function()
		    MovementEnabled = not MovementEnabled

		    if MovementEnabled then
			    movementToggleBtn.Text = "TOGGLE: ON"
			    movementToggleBtn.TextColor3 = C_GRN
			    movementToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
			    setButtonBaseColor(movementToggleBtn, Color3.fromRGB(40, 70, 40))

			    pcall(function() markersFolder.Parent = workspace end)

    			if setStatus then setStatus("Movement enabled.") end
		    else
			    movementToggleBtn.Text = "TOGGLE: OFF"
			    movementToggleBtn.TextColor3 = C_ROFF
			    movementToggleBtn.BackgroundColor3 = Color3.fromRGB(70, 40, 40)
			    setButtonBaseColor(movementToggleBtn, Color3.fromRGB(70, 40, 40))

			    pcall(stopRecording, false)
			    pcall(stopPlayback)

			    pcall(function() markersFolder.Parent = nil end)

    			if setStatus then setStatus("Movement disabled.") end
		    end
	    end, Color3.fromRGB(70, 40, 40), C_ROFF)

	    createSection(p, "Recording")
		nameBox = mvBox(p, "Recording name (optional)", 26)
		startRecBtn = mvButton(p, "Start Recording", function()
			startRecording()
		end, Color3.fromRGB(30, 60, 30), C_GRN)

		stopRecBtn = mvButton(p, "Stop Recording", function()
			stopRecording(true)
		end, C_REDD, C_ROFF)

		createSection(p, "Playback")
		playBtn = mvButton(p, "Play Selected", function()
			requestPlayback(selectedRecording)
		end, Color3.fromRGB(30, 45, 70), Color3.fromRGB(150, 200, 255))

		stopPlayBtn = mvButton(p, "Stop Playback", function()
			stopPlayback()
		end, Color3.fromRGB(70, 45, 20), Color3.fromRGB(255, 200, 120))

		createSection(p, "Selected")
		infoLabel = mvLabel(p, "Nothing selected.", 40)
	end)

	------------------------------------------------------------
	-- TAB: RECORDINGS
	------------------------------------------------------------

	local recList, renameBox

	addMovementTab("Records", function(p)
		createSection(p, "RECORDINGS")
		recList = mvList(p, 220)

		local renameRow = create("Frame", {
			Parent = p,
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundTransparency = 1,
		})

		renameBox = create("TextBox", {
			Parent = renameRow,
			Size = UDim2.new(0.6, -4, 1, 0),
			BackgroundColor3 = uiColor_TextBoxColor,
			BorderColor3 = COL_BORDER,
			TextColor3 = uiColor_TextColor,
			PlaceholderColor3 = Color3.fromRGB(90, 90, 90),
			PlaceholderText = "New name...",
			Text = "",
			TextSize = 13,
			Font = FONT,
			ClearTextOnFocus = false,
		})
		renameBox.BackgroundTransparency = 1 - uiGuiOpacity
		table.insert(themeElements.TextBoxes, renameBox)
		table.insert(themeElements.Texts, renameBox)

		local renameBtn = mvButton(renameRow, "Rename", function()
			if not selectedRecording then
				setStatus("Select a recording first.")
				return
			end

			local n = trim(renameBox.Text)
			if n == "" then
				setStatus("Enter a new name.")
				return
			end

			selectedRecording.Name = n
			saveCategoryFile(selectedCategory)
			rebuildMarkers()
			refreshRecordings()
			refreshMainInfo()
			setStatus("Renamed to: " .. n)
		end)

		renameBtn.Size = UDim2.new(0.4, 0, 1, 0)
		renameBtn.Position = UDim2.new(0.6, 0, 0, 0)

		local delBtn = mvButton(p, "Delete Selected", function()
			if not selectedRecording then return end

			if state ~= State.Idle and currentPlayback == selectedRecording then
				stopPlayback()
			end

			local entries = library.categories[selectedCategory]
			if entries then
				for i, e in ipairs(entries) do
					if e == selectedRecording then
						table.remove(entries, i)
						break
					end
				end
			end

			if markerData[selectedRecording] then
				pcall(function() markerData[selectedRecording].Model:Destroy() end)
				markerData[selectedRecording] = nil
			end

			selectedRecording = nil
			saveCategoryFile(selectedCategory)
			refreshRecordings()
			refreshMainInfo()
			setStatus("Recording deleted.")
		end, C_REDD, C_ROFF)

		local tpBtn = mvButton(p, "Teleport To Circle", function()
			if not MovementEnabled then
				if setStatus then setStatus("Movement is disabled.") end
				return
			end

			if not selectedRecording or not rootPart then return end
			local s = selectedRecording.StartCFrame
			if s then
				rootPart.CFrame = s + Vector3.new(0, 3, 0)
			end
		end)

		local playSel = mvButton(p, "Play Selected", function()
			requestPlayback(selectedRecording)
		end, Color3.fromRGB(30, 45, 70), Color3.fromRGB(150, 200, 255))
	end)

	------------------------------------------------------------
	-- TAB: CATEGORIES
	------------------------------------------------------------

	local catList, newCatBox

	addMovementTab("Categories", function(p)
		createSection(p, "CATEGORIES")
		catList = mvList(p, 240)
		newCatBox = mvBox(p, "New category name", 26)

		local addBtn = mvButton(p, "Add Category", function()
			local n = trim(newCatBox.Text)
			if n == "" then
				setStatus("Enter a category name.")
				return
			end

			if library.categories[n] then
				setStatus("Category already exists.")
				return
			end

			library.categories[n] = {}
			selectedCategory = n
			selectedRecording = nil
			newCatBox.Text = ""

			saveCategoryFile(n)
			refreshCategories()
			refreshRecordings()
			setStatus("Category added: " .. n)
		end, Color3.fromRGB(30, 60, 30), C_GRN)

		local delBtn = mvButton(p, "Delete Category", function()
			if selectedCategory == "Default" then
				setStatus("Default cannot be deleted.")
				return
			end

			library.categories[selectedCategory] = nil
			deleteCategoryFile(selectedCategory)

			selectedCategory = "Default"
			selectedRecording = nil

			rebuildMarkers()
			refreshCategories()
			refreshRecordings()
			refreshMainInfo()
			setStatus("Category deleted.")
		end, C_REDD, C_ROFF)
	end)

	------------------------------------------------------------
	-- SETTINGS ROW HELPERS
	------------------------------------------------------------

	local function numRow(parent, label, key, min, max, rebuild)
		local rowF = create("Frame", {
			Parent = parent,
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundTransparency = 1,
		})

		local lbl = create("TextLabel", {
			Parent = rowF,
			Size = UDim2.new(0.55, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = label,
			TextColor3 = uiColor_TextColor,
			TextSize = 12,
			Font = FONT,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		table.insert(themeElements.Texts, lbl)

		local box = create("TextBox", {
			Parent = rowF,
			Size = UDim2.new(0.45, -4, 0, 22),
			Position = UDim2.new(0.55, 0, 0.5, -11),
			BackgroundColor3 = uiColor_TextBoxColor,
			BorderColor3 = COL_BORDER,
			TextColor3 = uiColor_TextColor,
			Text = tostring(Settings[key]),
			TextSize = 12,
			Font = FONT,
			ClearTextOnFocus = false,
		})
		box.BackgroundTransparency = 1 - uiGuiOpacity
		table.insert(themeElements.TextBoxes, box)
		table.insert(themeElements.Texts, box)

		box.FocusLost:Connect(function()
			local v = tonumber(box.Text)
			if not v then
				box.Text = tostring(Settings[key])
				return
			end

			Settings[key] = math.clamp(v, min, max)
			box.Text = tostring(Settings[key])
			saveSettings()

			if rebuild then
				rebuildMarkers()
			end
		end)

		return rowF
	end

	local function colorRow(parent, label, key, rebuild)
		local rowF = create("Frame", {
			Parent = parent,
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundTransparency = 1,
		})

		local lbl = create("TextLabel", {
			Parent = rowF,
			Size = UDim2.new(0.55, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = label,
			TextColor3 = uiColor_TextColor,
			TextSize = 12,
			Font = FONT,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		table.insert(themeElements.Texts, lbl)

		local arr = Settings[key]
		local box = create("TextBox", {
			Parent = rowF,
			Size = UDim2.new(0.45, -4, 0, 22),
			Position = UDim2.new(0.55, 0, 0.5, -11),
			BackgroundColor3 = uiColor_TextBoxColor,
			BorderColor3 = COL_BORDER,
			TextColor3 = uiColor_TextColor,
			Text = string.format("%d,%d,%d", arr[1], arr[2], arr[3]),
			TextSize = 12,
			Font = FONT,
			ClearTextOnFocus = false,
		})
		box.BackgroundTransparency = 1 - uiGuiOpacity
		table.insert(themeElements.TextBoxes, box)
		table.insert(themeElements.Texts, box)

		box.FocusLost:Connect(function()
			local r, g, bVal = box.Text:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
			if r and g and bVal then
				Settings[key] = {
					math.clamp(tonumber(r), 0, 255),
					math.clamp(tonumber(g), 0, 255),
					math.clamp(tonumber(bVal), 0, 255),
				}
				saveSettings()

				if rebuild then
					rebuildMarkers()
				end
			end
		end)

		return rowF
	end

	local function toggleRow(parent, label, key, rebuild)
		local stateVal = Settings[key] and true or false

		local bg = stateVal and Color3.fromRGB(30, 60, 30) or C_REDD
		local tc = stateVal and C_GRN or C_ROFF

		local b = mvButton(parent, label .. ": " .. (stateVal and "ON" or "OFF"), function()
			stateVal = not stateVal
			Settings[key] = stateVal

			bg = stateVal and Color3.fromRGB(30, 60, 30) or C_REDD
			tc = stateVal and C_GRN or C_ROFF

			b.Text = label .. ": " .. (stateVal and "ON" or "OFF")
			b.BackgroundColor3 = bg
			b.TextColor3 = tc
			setButtonBaseColor(b, bg)

			saveSettings()

			if rebuild then
				rebuildMarkers()
			end
		end, bg, tc, 26)

		return b
	end

	------------------------------------------------------------
	-- TAB: COLORS
	------------------------------------------------------------

	local function colorSection(parent, title, modeKey, keyA, keyB, keyC)
		createSection(parent, title)

		local modeBtn = mvButton(parent, "Color Mode: " .. Settings[modeKey], function()
			local idx = table.find(COLOR_MODES, Settings[modeKey]) or 1
			Settings[modeKey] = COLOR_MODES[(idx % #COLOR_MODES) + 1]
			saveSettings()
			rebuildMarkers()
			updateVis()
		end, nil, nil, 26)

		local rowA = colorRow(parent, "Color A (R,G,B)", keyA, true)
		local rowB = colorRow(parent, "Color B (R,G,B)", keyB, true)
		local rowC = colorRow(parent, "Color C (R,G,B)", keyC, true)

		updateVis = function()
			local m = Settings[modeKey]
			rowA.Visible = (m ~= "Rainbow")
			rowB.Visible = (m == "TwoWay" or m == "ThreeWay")
			rowC.Visible = (m == "ThreeWay")
			modeBtn.Text = "Color Mode: " .. m
		end

		updateVis()
	end

	addMovementTab("Colors", function(p)
		createSection(p, "COLORS")

		colorSection(p, "CIRCLE COLORS", "CircleMode", "CircleColorA", "CircleColorB", "CircleColorC")
		colorSection(p, "PATH COLORS", "PathMode", "PathColorA", "PathColorB", "PathColorC")
		colorSection(p, "LABEL COLORS", "LabelMode", "LabelColorA", "LabelColorB", "LabelColorC")
	end)

	------------------------------------------------------------
	-- TAB: Settings
	------------------------------------------------------------

	addMovementTab("Settings", function(p)
		createSection(p, "RECORDING")
		numRow(p, "Min Record Distance", "MinRecordDistance", 0, 1, false)
		numRow(p, "Min Record Time (sec)", "MinRecordTime", 0, 1, false)

		createSection(p, "CIRCLE")
		numRow(p, "Circle Width (Radius)", "CircleRadius", 2, 20, true)
		numRow(p, "Circle Thickness", "CircleThickness", 0.1, 2, true)
		numRow(p, "Circle Height Offset", "CircleHeight", -10, 10, true)
		numRow(p, "Circle Transparency", "CircleTransparency", 0, 1, true)

		createSection(p, "PATH")
		numRow(p, "Path Transparency", "PathTransparency", 0, 1, true)
		numRow(p, "Path Point Size", "PathPointSize", 0.1, 2, true)
		numRow(p, "Trail Show Distance", "TrailDistance", 1, 100, false)
		numRow(p, "Trail Step (0 = auto)", "TrailStep", 0, 50, true)
		toggleRow(p, "Show Path In Playback", "ShowPathPlayback", false)

		createSection(p, "LABEL (NAME ABOVE CIRCLE)")
		toggleRow(p, "Show Labels", "ShowLabels", true)
		numRow(p, "Text Height", "TextHeight", 1, 20, true)
		numRow(p, "Text Transparency", "TextTransparency", 0, 1, true)
		numRow(p, "Text Visible Distance", "TextDistance", 10, 300, true)

		createSection(p, "PROXIMITY PROMPT")
		toggleRow(p, "Proximity Prompt", "PromptEnabled", true)
		numRow(p, "Prompt Distance", "PromptDistance", 4, 60, true)

		createSection(p, "PLAYBACK")
		numRow(p, "Playback Speed", "PlaybackSpeed", 0.1, 5, false)
		toggleRow(p, "Loop Playback", "Loop", false)
		toggleRow(p, "Legit Movement", "Legit", false)
	end)

	------------------------------------------------------------
	-- TAB: KEYBINDS
	------------------------------------------------------------

	local function applyPromptKey()
		local kc = keyCodeByName(Keybinds.Prompt)
		for _, data in pairs(markerData) do
			if data.Prompt then
				data.Prompt.KeyboardKeyCode = kc
			end
		end
	end

	local function bindRow(parent, label, key, onSet)
		local b = mvButton(parent, label .. ": [" .. Keybinds[key] .. "]", function()
			if movementBindCapture then return end

			movementBindCapture = function(name)
				Keybinds[key] = name
				b.Text = label .. ": [" .. name .. "]"
				saveSettings()

				if onSet then onSet() end
				setStatus("Keybind set: " .. label .. " -> " .. name)
			end

			b.Text = label .. ": [press any key]"
		end, nil, nil, 28)

		return b
	end

	addMovementTab("Keybinds", function(p)
		createSection(p, "KEYBINDS")
		mvLabel(p, "Menu toggle uses the main FuckYou toggle key.", 22)
		mvLabel(p, "Click a row, then press any key.", 22)

		bindRow(p, "Start / Stop Recording", "Record")
		bindRow(p, "Play / Stop Playback", "Play")
		bindRow(p, "Proximity Prompt Key", "Prompt", applyPromptKey)
	end)

	------------------------------------------------------------
	-- REFRESH / STATUS
	------------------------------------------------------------

	setStatus = function(text)
		if statusLabel then statusLabel.Text = text end
	end

	updateButtons = function()
		if not startRecBtn then return end

		startRecBtn.Text = (state == State.Recording) and "Recording..." or "Start Recording"
		stopRecBtn.Text = "Stop Recording"

		playBtn.Text = (state == State.Playing) and "Playing..."
			or (state == State.Aligning) and "Aligning..."
			or "Play Selected"

		stopPlayBtn.Text = "Stop Playback"
	end

	refreshMainInfo = function()
		if not infoLabel then return end

		if selectedRecording then
			local n = #selectedRecording.Frames
			infoLabel.Text = string.format("%s | frames: %d | category: %s", selectedRecording.Name, n, selectedCategory)
		else
			infoLabel.Text = "Nothing selected."
		end
	end

	refreshRecordings = function()
		if not recList then return end

		clearList(recList)

		local entries = library.categories[selectedCategory] or {}
		if #entries == 0 then
			mvLabel(recList, "No recordings in this category yet.", 24)
		end

		for _, entry in ipairs(entries) do
			local sel = entry == selectedRecording
			mvListItem(recList, string.format("%s | frames: %d", entry.Name, entry.Frames and #entry.Frames or 0), sel, function()
				selectedRecording = entry
				refreshRecordings()
				refreshMainInfo()
				setStatus("Selected: " .. entry.Name .. ". Stand in its circle or use prompt key.")
			end, 28)
		end
	end

	refreshCategories = function()
		if not catList then return end

		clearList(catList)

		local names = {}
		for n in pairs(library.categories) do
			table.insert(names, n)
		end

		table.sort(names, function(a, b)
			if a == "Default" then return true end
			if b == "Default" then return false end
			return a < b
		end)

		for _, name in ipairs(names) do
			local sel = name == selectedCategory
			mvListItem(catList, name, sel, function()
				selectedCategory = name
				selectedRecording = nil
				refreshCategories()
				refreshRecordings()
				refreshMainInfo()
			end, 26)
		end
	end

	------------------------------------------------------------
	-- THEME HOOKS
	------------------------------------------------------------

	local baseUpdateTabButtonsTheme = updateTabButtonsTheme
	updateTabButtonsTheme = function()
		baseUpdateTabButtonsTheme()

		for _, tab in ipairs(movementTabs) do
			if tab.Button then
				if tab.Frame.Visible then
					tab.Button.BackgroundColor3 = uiColor_ButtonColor
					tab.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
				else
					tab.Button.BackgroundColor3 = darker(uiColor_ButtonColor, 10)
					tab.Button.TextColor3 = uiColor_TextColor
				end
			end
		end
	end

	local baseApplyTheme = applyTheme
	applyTheme = function()
		baseApplyTheme()

		pcall(function()
			if refreshCategories then refreshCategories() end
		end)

		pcall(function()
			if refreshRecordings then refreshRecordings() end
		end)
	end

	------------------------------------------------------------
	-- CHARACTER BIND
	------------------------------------------------------------

	local function bindCharacter(newChar)
		if characterDiedConnection then
			characterDiedConnection:Disconnect()
			characterDiedConnection = nil
		end

		character = newChar
		humanoid = newChar:FindFirstChildOfClass("Humanoid") or newChar:WaitForChild("Humanoid", 5)
		rootPart = newChar:FindFirstChild("HumanoidRootPart") or newChar:WaitForChild("HumanoidRootPart", 5)

		if humanoid then
			characterDiedConnection = humanoid.Died:Connect(function()
				pcall(stopRecording, false)
				pcall(stopPlayback)
			end)
		end
	end

	mConnect(LocalPlayer.CharacterAdded, bindCharacter)

	mConnect(LocalPlayer.CharacterRemoving, function()
		pcall(stopRecording, false)
		pcall(stopPlayback)
	end)

	if LocalPlayer.Character then
		bindCharacter(LocalPlayer.Character)
	end

	------------------------------------------------------------
	-- GLOBAL KEY HANDLER
	------------------------------------------------------------

	mConnect(UserInputService.InputBegan, function(input, processed)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

		local name = input.KeyCode.Name

		if movementBindCapture then
			if name ~= "Unknown" then
				movementBindCapture(name)
			end
			movementBindCapture = nil
			return
		end

		if not unlocked then return end
	    if processed then return end
	    if not MovementEnabled then return end

	    if name == Keybinds.Record then
			if state == State.Recording then
				stopRecording(true)
			else
				startRecording()
			end
			return
		end

		if name == Keybinds.Play then
			if state == State.Playing or state == State.Aligning then
				stopPlayback()
			else
				requestPlayback(selectedRecording)
			end
			return
		end
	end)

	------------------------------------------------------------
	-- INIT
	------------------------------------------------------------

	loadLibrary()
	rebuildMarkers()
	refreshCategories()
	refreshRecordings()
	refreshMainInfo()
	updateButtons()

	if not filesOK() then
		setStatus("File saving not supported by executor - session only. Ready.")
	else
		setStatus("File saving is supported by executor. Ready.")
	end

	------------------------------------------------------------
	-- CLEANUP
	------------------------------------------------------------

	local cleaned = false

	local function cleanupMovement()
		if cleaned then return end
		cleaned = true

		pcall(stopRecording, false)
		pcall(stopPlayback)

		if characterDiedConnection then
			pcall(function() characterDiedConnection:Disconnect() end)
			characterDiedConnection = nil
		end

		for i = #movementConnections, 1, -1 do
			local cn = movementConnections[i]
			if cn and cn.Connected then
				cn:Disconnect()
			end
			movementConnections[i] = nil
		end

		pcall(function() markersFolder:Destroy() end)
	end

	ScreenGui.Destroying:Connect(cleanupMovement)

	pcall(function()
		local old = shared["EmilyUiMovementCleanup"]
		if typeof(old) == "function" then
			pcall(old)
		end
		shared["EmilyUiMovementCleanup"] = cleanupMovement
	end)

	------------------------------------------------------------
	-- SIDEBAR / TAB SWITCHING
	------------------------------------------------------------

	task.defer(function()
		local function hideAllFrames()
			for _, t in ipairs(tabs or {}) do
				if t.Frame then t.Frame.Visible = false end
			end
			for _, t in ipairs(desyncTabs) do
				if t.Frame then t.Frame.Visible = false end
			end
			for _, t in ipairs(musicTabs) do
				if t.Frame then t.Frame.Visible = false end
			end
			for _, t in ipairs(aimTabs) do
				if t.Frame then t.Frame.Visible = false end
			end
			for _, t in ipairs(movementTabs) do
				if t.Frame then t.Frame.Visible = false end
			end
		end

		local function hideAllModuleButtons()
			for _, t in ipairs(tabs or {}) do
				if t.Button then t.Button.Visible = false end
			end
			for _, t in ipairs(desyncTabs) do
				if t.Button then t.Button.Visible = false end
			end
			for _, t in ipairs(musicTabs) do
				if t.Button then t.Button.Visible = false end
			end
			for _, t in ipairs(aimTabs) do
				if t.Button then t.Button.Visible = false end
			end
			for _, t in ipairs(movementTabs) do
				if t.Button then t.Button.Visible = false end
			end
		end

		local function showMainButtons()
			hideAllModuleButtons()
			for _, t in ipairs(tabs or {}) do
				if t.Button then t.Button.Visible = true end
			end
		end

		local function showDesyncButtons()
			hideAllModuleButtons()
			for _, t in ipairs(desyncTabs) do
				if t.Button then t.Button.Visible = true end
			end
		end

		local function showMusicButtons()
			hideAllModuleButtons()
			for _, t in ipairs(musicTabs) do
				if t.Button then t.Button.Visible = true end
			end
		end

		local function showAimButtons()
			hideAllModuleButtons()
			for _, t in ipairs(aimTabs) do
				if t.Button then t.Button.Visible = true end
			end
		end

		local function showMovementButtons()
			hideAllModuleButtons()
			for _, t in ipairs(movementTabs) do
				if t.Button then t.Button.Visible = true end
			end
		end

		for _, t in ipairs(movementTabs) do
			if t.Button then
				t.Button.MouseButton1Click:Connect(function()
					hideAllFrames()
					t.Frame.Visible = true
					updateTabButtonsTheme()
				end)
			end
		end

		for _, t in ipairs(tabs or {}) do
			if t.Button then
				t.Button.MouseButton1Click:Connect(function()
					for _, m in ipairs(movementTabs) do
						if m.Frame then m.Frame.Visible = false end
					end
					updateTabButtonsTheme()
				end)
			end
		end

		for _, t in ipairs(desyncTabs) do
			if t.Button then
				t.Button.MouseButton1Click:Connect(function()
					for _, m in ipairs(movementTabs) do
						if m.Frame then m.Frame.Visible = false end
					end
					updateTabButtonsTheme()
				end)
			end
		end

		for _, t in ipairs(musicTabs) do
			if t.Button then
				t.Button.MouseButton1Click:Connect(function()
					for _, m in ipairs(movementTabs) do
						if m.Frame then m.Frame.Visible = false end
					end
					updateTabButtonsTheme()
				end)
			end
		end

		for _, t in ipairs(aimTabs) do
			if t.Button then
				t.Button.MouseButton1Click:Connect(function()
					for _, m in ipairs(movementTabs) do
						if m.Frame then m.Frame.Visible = false end
					end
					updateTabButtonsTheme()
				end)
			end
		end

		EmilyUi.MouseButton1Click:Connect(function()
			showMainButtons()
			hideAllFrames()
			if tabs and tabs[1] and tabs[1].Frame then
				tabs[1].Frame.Visible = true
			end
			updateTabButtonsTheme()
		end)

		Desync.MouseButton1Click:Connect(function()
			showDesyncButtons()
			hideAllFrames()
			if desyncTabs[1] and desyncTabs[1].Frame then
				desyncTabs[1].Frame.Visible = true
			end
			updateTabButtonsTheme()
		end)

		Music.MouseButton1Click:Connect(function()
			showMusicButtons()
			hideAllFrames()
			if musicTabs[1] and musicTabs[1].Frame then
				musicTabs[1].Frame.Visible = true
			end
			updateTabButtonsTheme()
		end)

		Aim.MouseButton1Click:Connect(function()
			showAimButtons()
			hideAllFrames()
			if aimTabs[1] and aimTabs[1].Frame then
				aimTabs[1].Frame.Visible = true
			end
			updateTabButtonsTheme()
		end)

		Movement.MouseButton1Click:Connect(function()
			showMovementButtons()
			hideAllFrames()
			if movementTabs[1] and movementTabs[1].Frame then
				movementTabs[1].Frame.Visible = true
			end
			updateTabButtonsTheme()
		end)
	end)

	return movementTabs
end

local movementTabs = initMovementModule(desyncTabs, musicTabs, AimAPI.Tabs)

-- =========================================================
-- ========= MOVEMENT RECORDER MODULE END ==================
-- =========================================================


--// Settings
createSection(tabFrames.Settings, "UI Customization")

local function createSettingsInput(parent, labelText, placeholder, callback)
	local container = create("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = parent})
	local label = create("TextLabel", {Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1, Text = labelText, TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, Parent = container})
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
local bindLabel = create("TextLabel", {Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1, Text = "Menu Toggle Key:", TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, Parent = keyBindContainer})
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
	{"Main Window Color:", formatColor(uiColor_MainWindow), function(c) uiColor_MainWindow = c end},
	{"Top Bar Color:", formatColor(uiColor_TopBar), function(c) uiColor_TopBar = c end},
	{"Side Bar Color:", formatColor(uiColor_SideBar), function(c) uiColor_SideBar = c end},
	{"Text Color:", formatColor(uiColor_TextColor), function(c) uiColor_TextColor = c end},
	{"Button Color:", formatColor(uiColor_ButtonColor), function(c) uiColor_ButtonColor = c end},
	{"TextBox Background Color:", formatColor(uiColor_TextBoxColor), function(c) uiColor_TextBoxColor = c end}
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

--// ===== BACKGROUND & WINDOW =====
createSection(tabFrames.Settings, "Background & Window")

local function createDropdown(parent, labelText, getOptions, getCurrent, onselect)
	local container = create("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = parent})
	local label = create("TextLabel", {Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1, Text = labelText, TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, Parent = container})
	table.insert(themeElements.Texts, label)
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
				saveConfig()
			end)
			ob.Size = UDim2.new(1, -4, 0, 24); ob.ZIndex = 26; ob.TextSize = 12
		end
		list.CanvasSize = UDim2.new(0, 0, 0, #opts * 26 + 4)
		list.Visible = true
	end)
end

local function createSlider(parent, labelText, min, max, getval, onval, fmt)
	local container = create("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = parent})
	local label = create("TextLabel", {Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1, Text = labelText, TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, Parent = container})
	table.insert(themeElements.Texts, label)
	local valLabel = create("TextLabel", {Size = UDim2.new(0.5, 0, 0, 14), Position = UDim2.new(0.48, 0, 0.05, 0), BackgroundTransparency = 1, Text = fmt(getval()), TextColor3 = uiColor_TextColor, TextSize = 11, Font = FONT, TextXAlignment = Enum.TextXAlignment.Right, Parent = container})
	table.insert(themeElements.Texts, valLabel)
	local track = create("TextButton", {Size = UDim2.new(0.5, 0, 0, 10), Position = UDim2.new(0.48, 0, 0.55, 0), BackgroundColor3 = uiColor_TextBoxColor, BorderColor3 = COL_BORDER, Text = "", Parent = container})
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

createDropdown(tabFrames.Settings, "Fit",
	function() return {"Fill", "Fit", "Stretch", "Tile", "Center", "Zoom"} end,
	function() return uiFitMode end,
	function(opt) uiFitMode = opt; applyBackground() end)

createSlider(tabFrames.Settings, "Gui Opacity", 25, 100,
	function() return math.floor(uiGuiOpacity * 100 + 0.5) end,
	function(v) uiGuiOpacity = v / 100; applyTheme() end,
	function(v) return v .. "%" end)

--// ===== КОНФИГИ =====
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
        TextBoxColor = {uiColor_TextBoxColor.R, uiColor_TextBoxColor.G, uiColor_TextBoxColor.B}
    }
    if AimAPI and AimAPI.Gather then cfg.Aim = AimAPI.Gather() end
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
	applyTheme()
	if cfg.Aim and AimAPI and AimAPI.Apply then
    	AimAPI.Apply(cfg.Aim)
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

local ddList = create("ScrollingFrame", {Name = "ConfigList", Parent = ddContainer, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 130), BackgroundColor3 = uiColor_TextBoxColor, BorderColor3 = COL_BORDER, BorderSizePixel = 1, ScrollBarThickness = 4, ScrollBarImageColor3 = COL_BORDER, CanvasSize = UDim2.new(0, 0, 0, 0), Visible = false})
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
	local name = string.gsub(configNameBox.Text, "%s+", "")
	if name == "" then notify("Configs", "Enter a config name!") return end
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
end)

refreshConfigList()

--// ===== ВКЛАДКИ =====
local function switchTab(targetTab)
	for _, tab in ipairs(tabs) do
		tab.Frame.Visible = (tab == targetTab)
	end
	updateTabButtonsTheme()
end

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

--// ===== УПРАВЛЕНИЕ ОКНОМ =====
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

X.MouseButton1Click:Connect(function()
	state = "closed"
	ScreenGui:Destroy()
end)

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
    tweenSize(UDim2.new(0, 940, 0, 0), function()
        FuckYou.Visible = false
    end)
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

--// ===== СИСТЕМА КЛЮЧЕЙ =====
local KeyWindow = create("Frame", {Name = "KeyWindow", Parent = ScreenGui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 450, 0, 310), BackgroundColor3 = uiColor_MainWindow, BorderColor3 = COL_BORDER})
table.insert(themeElements.MainWindow, KeyWindow)

local KeyTopBar = create("Frame", {Parent = KeyWindow, Size = UDim2.new(1, 0, 0, 35), BackgroundColor3 = uiColor_TopBar, BorderSizePixel = 0})
table.insert(themeElements.TopBars, KeyTopBar)

local KeyTitle = create("TextLabel", {Parent = KeyTopBar, Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = "Fuck you! — Key System", TextColor3 = uiColor_TextColor, TextSize = 15, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left})
table.insert(themeElements.Texts, KeyTitle)

local KeyCloseBtn = create("TextButton", {Parent = KeyTopBar, Size = UDim2.new(0, 35, 0, 35), Position = UDim2.new(1, -35, 0, 0), BackgroundColor3 = Color3.fromRGB(120, 40, 40), BorderColor3 = COL_BORDER, TextColor3 = Color3.fromRGB(255, 255, 255), Text = "X", TextSize = 14, Font = FONT})
KeyCloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local KeyInfoLabel = create("TextLabel", {Parent = KeyWindow, Size = UDim2.new(1, -30, 0, 40), Position = UDim2.new(0, 15, 0, 50), BackgroundTransparency = 1, Text = "Please enter your access key below to load the script.\nKey can be obtained via Discord.", TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT, TextWrapped = true})
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
		blurEffect.Parent = game:GetService("Lighting")
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

			if conn then
				conn:Disconnect()
			end

			pcall(function() s:Stop() end)
			pcall(function() s:Destroy() end)
		end

		s.Ended:Connect(cleanup)

		conn = RunService.Heartbeat:Connect(function()
			if not done and s.IsPlaying and s.TimePosition >= 2 then
				cleanup()
			end
		end)

		s:Play()

		-- страховка, если звук так и не смог нормально загрузиться/заиграть
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
	notify("Fuck you! is loaded", "Welcome! Role: " .. (userGroup or "User"))
end

local function isGroupAllowed(groupName)
    local g = string.lower(tostring(groupName or ""))

    if beta then
        -- Бета-режим: пускаем только Tester и Coder
        return g == "tester" or g == "coder"
    else
        -- Обычный режим: пускаем Free, User, Tester, Coder
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

	if beta then
    	KeyInfoLabel.Text = "Beta mode: only Tester/Coder keys are allowed."
	else
	    KeyInfoLabel.Text = "Enter key please! You can ask for a key in discord."
	end

	KeyInfoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
end

local BtnSubmit = createContentButton(KeyWindow, "Check Key", checkKeySystem, Color3.fromRGB(40, 90, 40))
BtnSubmit.Size = UDim2.new(0, 150, 0, 36)
BtnSubmit.Position = UDim2.new(0.5, -75, 0, 240)

--// Автозагрузка последнего выбранного конфига (теперь ПОСЛЕ создания окна ключей,
--// чтобы applyTheme() перекрасил и его)
local lastCfgName = getLastConfigName()
if lastCfgName then loadNamedConfig(lastCfgName) end

--// Принудительно применяем текущую тему (цвета + прозрачность) ко всему, включая KeyWindow
applyTheme()

task.spawn(checkKeySystem)