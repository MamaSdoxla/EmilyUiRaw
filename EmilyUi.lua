---@diagnostic disable: undefined-global
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

local cachedKeyResponse = nil

local currentKeyData = {
	group = "Free",
	daysLeft = "Infinity"
}

StarterGui:SetCore("SendNotification", {
	Title = "EmilyUi is loading!",
	Text = "To get key goto discord or ask for a permanent one.",
	Duration = 10
})

local function create(className, properties)
	local instance = Instance.new(className)
	for k, v in pairs(properties) do
		instance[k] = v
	end
	return instance
end

local MyGui = create("ScreenGui", {Name = "MyGuiByWdymGaming", ResetOnSpawn = false, Parent = LocalPlayer:WaitForChild("PlayerGui")})

local themeElements = {
	MainWindow = {},
	TopBars = {},
	SideBars = {},
	Texts = {},
	Buttons = {},
	TextBoxes = {}
}

local tabs = {}

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

local function updateTabButtonsTheme()
	for _, tab in ipairs(tabs) do
		if tab.Button then
			local isTarget = tab.Frame.Visible
			if isTarget then
				tab.Button.BackgroundColor3 = uiColor_ButtonColor
				tab.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
			else
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

loadConfig()

local MainWindow = create("Frame", {Name = "MainWindow", Parent = MyGui, Size = UDim2.new(0, 900, 0, 700), Position = UDim2.new(0.5, -450, 0.4, -150), BackgroundColor3 = uiColor_MainWindow, BorderSizePixel = 0, Visible = false})
table.insert(themeElements.MainWindow, MainWindow)

local TopBar = create("Frame", {Name = "TopBar", Parent = MainWindow, Size = UDim2.new(1, 0, 0, 35), BackgroundColor3 = uiColor_TopBar, BorderSizePixel = 0})
table.insert(themeElements.TopBars, TopBar)

local MainTitle = create("TextLabel", {Name = "Title", Parent = TopBar, Size = UDim2.new(1, -85, 1, 0), Position = UDim2.new(0, 15, 0, 0), BackgroundTransparency = 1, Text = "EmilyUi v1.1", TextColor3 = uiColor_TextColor, TextSize = 24, Font = Enum.Font.SourceSansSemibold, TextXAlignment = Enum.TextXAlignment.Left})
table.insert(themeElements.Texts, MainTitle)

local SideBar = create("Frame", {Name = "SideBar", Parent = MainWindow, Size = UDim2.new(0, 180, 1, -115), Position = UDim2.new(0, 0, 0, 35), BackgroundColor3 = uiColor_SideBar, BorderSizePixel = 0})
table.insert(themeElements.SideBars, SideBar)

create("UIListLayout", {Parent = SideBar, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)})
create("UIPadding", {Parent = SideBar, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)})

local ContentFrame = create("Frame", {Name = "ContentFrame", Parent = MainWindow, Size = UDim2.new(1, -180, 1, -35), Position = UDim2.new(0, 180, 0, 35), BackgroundTransparency = 1, BorderSizePixel = 0})

local UserProfilePanel = create("Frame", {Name = "UserProfilePanel", Parent = MainWindow, Size = UDim2.new(0, 180, 0, 80), Position = UDim2.new(0, 0, 1, -80), BackgroundColor3 = uiColor_SideBar, BorderSizePixel = 0})
table.insert(themeElements.SideBars, UserProfilePanel)

create("Frame", {Parent = UserProfilePanel, Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = Color3.fromRGB(45, 45, 45), BorderSizePixel = 0})

local UserImage = create("ImageLabel", {Parent = UserProfilePanel, Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(0, 10, 0, 15), BackgroundTransparency = 1, Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"})
create("UICorner", {Parent = UserImage, CornerRadius = UDim.new(1, 0)})

local UserNameLabel = create("TextLabel", {Parent = UserProfilePanel, Size = UDim2.new(1, -75, 0, 20), Position = UDim2.new(0, 68, 0, 12), BackgroundTransparency = 1, Text = LocalPlayer.DisplayName, TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 16, Font = Enum.Font.SourceSansBold, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd})

local UserKeyTimeLabel = create("TextLabel", {Parent = UserProfilePanel, Size = UDim2.new(1, -75, 0, 15), Position = UDim2.new(0, 68, 0, 32), BackgroundTransparency = 1, Text = "Days left: Inf", TextColor3 = Color3.fromRGB(180, 180, 180), TextSize = 16, Font = Enum.Font.SourceSans, TextXAlignment = Enum.TextXAlignment.Left})

local UserGroupLabel = create("TextLabel", {Parent = UserProfilePanel, Size = UDim2.new(1, -75, 0, 15), Position = UDim2.new(0, 68, 0, 47), BackgroundTransparency = 1, Text = "Group: Free", TextColor3 = Color3.fromRGB(150, 150, 150), TextSize = 16, Font = Enum.Font.SourceSansSemibold, TextXAlignment = Enum.TextXAlignment.Left})

RunService.RenderStepped:Connect(function()
	if not MainWindow.Visible then return end
	local group = currentKeyData.group or "Free"
	local speed = 5
	local wave = math.sin(tick() * speed)
	
	if group == "Free" then
		UserGroupLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	elseif group == "User" then
		local hue = 0.3 + (wave * 0.05)
		UserGroupLabel.TextColor3 = Color3.fromHSV(hue, 0.85, 0.95)
	elseif group == "Tester" then
		local hue = 0.6 + (wave * 0.05)
		UserGroupLabel.TextColor3 = Color3.fromHSV(hue, 0.85, 0.95)
	elseif group == "Coder" then
		local hue = 0.88 + (wave * 0.04)
		UserGroupLabel.TextColor3 = Color3.fromHSV(hue, 0.85, 0.95)
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

local function createTabContentFrame(name)
	local sf = create("ScrollingFrame", {Name = name, Parent = ContentFrame, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6, CanvasSize = UDim2.new(0, 0, 0, 0), Visible = false})
	local tl = create("UIListLayout", {Parent = sf, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)})
	create("UIPadding", {Parent = sf, PaddingTop = UDim.new(0, 15), PaddingLeft = UDim.new(0, 15), PaddingRight = UDim.new(0, 15)})
	
	tl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		sf.CanvasSize = UDim2.new(0, 0, 0, tl.AbsoluteContentSize.Y + 30)
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
tabFrames.Main.Visible = true

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

local function copyDiscord()
	setclipboard("https://discord.gg/75Dz8T9hHR")
	StarterGui:SetCore("SendNotification", {Title = "EmilyUi discord", Text = "The link is copied", Duration = 6.5})
end

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
	
	{ tab = tabFrames.Scripts, type = "section", text = "Fun Scripts" },
	{ tab = tabFrames.Scripts, type = "button", text = "Ball R6/R15", cb = function() loadstring(game:HttpGet("https://pastebin.com/raw/BZr9bGDy", true))() end },
	{ tab = tabFrames.Scripts, type = "section", text = "Scripts made by WdymGaming"},
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

local filterMode = "All"
local currentPlaceId = tostring(game.PlaceId)

local GamePlaces = {
	["12355337193"] = {
		{ type = "label", text = "Murder vs Sherif 2" },
		{ type = "button", text = "Polo MVS", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/polo242c/mvs/main/mvs"))() end },
		{ type = "button", text = "CyberCoders", cb = function() loadstring(game:HttpGet("https://rawscripts.net/raw/Murderers-VS-Sheriffs-DUELS-CyberCoders-Menu-II-193913"))() end },
	},
	["7041939546"] = {
		{ type = "label", text = "Catalog Avatar Creator" },
		{ type = "button", text = "Avatar stealer", cb = function() loadstring(game:HttpGet("https://pastefy.app/xWdIDQJd/raw"))() end },
	},
	["142823291"] = {
		{ type = "label", text = "Murder Mystery 2" },
		{ type = "button", text = "VisionHub", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/orialdev/VisionHub/refs/heads/main/main.lua"))() end },
		{ type = "button", text = "AutoFarm (40coins/4,5min)", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/tsBelrux/mm2/refs/heads/main/keyless.lua"))() end },
		{ type = "button", text = "FoxnameHub", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/xv3gasx/Murder-Mystery-2/refs/heads/main/Release.lua"))() end },
	},
	["95082159892680"] = {
		{ type = "label", text = "+1 Speed Keyboard Escape" },
		{ type = "button", text = "Luxy Hub", cb = function() loadstring(game:HttpGet("https://www.luxyhub.space/api/loader/luxyhub"))() end },
	}
}

local function renderGamesTab()
	for _, child in ipairs(tabFrames.Games:GetChildren()) do
		if child:IsA("TextLabel") or child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	createContentButton(tabFrames.Games, "Filter: " .. filterMode .. " (Click to switch)", function()
		filterMode = (filterMode == "All") and "Place" or "All"
		renderGamesTab() 
	end)
	
	createSection(tabFrames.Games, "Game Scripts")
	
	for placeId, items in pairs(GamePlaces) do
		local shouldShow = false
		
		if filterMode == "All" then
			shouldShow = true
		elseif filterMode == "Place" then
			if placeId == currentPlaceId then
				shouldShow = true
			end
		end
		
		if shouldShow then
			for _, item in ipairs(items) do
				if item.type == "label" then
					createLabel(tabFrames.Games, item.text)
				elseif item.type == "button" then
					createContentButton(tabFrames.Games, item.text, item.cb)
				elseif item.type == "section" then
					createSection(tabFrames.Games, item.text)
				end
			end
		end
	end
end

renderGamesTab()

local animFilterMode = "All"

local AnimationsSections = {
	{
		title = "Animations client",
		scripts = {
			{ text = "R6 Insanity (client)", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/retpirato/Roblox-Scripts/refs/heads/master/Insanity%20Powers.lua"))() end },
		}
	},
	{
		title = "Animations guis",
		scripts = {
			{ text = "R15 Animations", cb = function() loadstring(game:HttpGet("https://kbauu.neocities.org/animation-hub"))() end },
			{ text = "Uhhhhhh Reanimator (R6)", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/STEVE-916-create/Uhhhhhh/main/source/reanim.lua"))() end },
		}
	},
	{
		title = "Animation exploits",
		scripts = {
			{ text = "R6 Upsidedown (multiple times = glitch)", cb = function() loadstring(game:HttpGet("https://pastebin.com/raw/RJVv7H3K"))() end },
		}
	},
	{
		title = "Animations S3X",
		scripts = {
			{ text = "R6 S3X animations", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/3LD4D0/FE-TROLLING-PLAYER-R6-R15/6eff8792afed57458d5114478b453a6f6bce5799/Fe%20trolling%20Player%20R6%20AND%20R15"))() end },
			{ text = "R6 S3X animations 2", cb = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/ShutUpJamesTheLoserAlt/fes/refs/heads/main/e"))() end },
			{ text = "R6 S3X animations 3", cb = function() loadstring(game:HttpGet("https://pastebin.com/raw/gdQ4mVEy"))() end },
			{ text = "Jerk off tool r6", cb = function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-FE-Jerk-off-240507"))() end },
			{ text = "Jerk off tool r15", cb = function() loadstring(game:HttpGet("https://pastefy.app/YZoglOyJ/raw"))() end },
		}
	}
}

local function getAnimType(text)
	local lowerText = string.lower(text)
	local hasR6 = string.find(lowerText, "r6") ~= nil
	local hasR15 = string.find(lowerText, "r15") ~= nil
	
	if hasR6 and hasR15 then
		return "Universal"
	elseif hasR6 then
		return "R6"
	elseif hasR15 then
		return "R15"
	else
		return "Universal" 
	end
end

local function renderAnimationsTab()
	for _, child in ipairs(tabFrames.Anims:GetChildren()) do
		if child:IsA("TextLabel") or child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	createContentButton(tabFrames.Anims, "Filter: " .. animFilterMode .. " (Click to switch)", function()
		if animFilterMode == "All" then
			animFilterMode = "R6"
		elseif animFilterMode == "R6" then
			animFilterMode = "R15"
		else
			animFilterMode = "All"
		end
		renderAnimationsTab()
	end)
	
	local totalShown = 0
	
	for _, section in ipairs(AnimationsSections) do
		local validScripts = {}
		
		for _, script in ipairs(section.scripts) do
			local scriptType = getAnimType(script.text)
			if animFilterMode == "All" or scriptType == animFilterMode or scriptType == "Universal" then
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

local function formatColor(c)
	return math.floor(c.R*255)..", "..math.floor(c.G*255)..", "..math.floor(c.B*255)
end

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
		updateTabButtonsTheme() 
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
	updateTabButtonsTheme() 
end

for index, tab in ipairs(tabs) do
	local btn = create("TextButton", {Name = "Btn_" .. tab.Name, Parent = SideBar, Size = UDim2.new(1, 0, 0, 35), BackgroundColor3 = Color3.fromRGB(35, 35, 35), TextColor3 = Color3.fromRGB(180, 180, 180), Text = tab.Name, Font = Enum.Font.SourceSansSemibold, TextSize = 16, BorderSizePixel = 0, LayoutOrder = index})
	tab.Button = btn
	table.insert(themeElements.Buttons, btn)
	table.insert(themeElements.Texts, btn)
	btn.MouseButton1Click:Connect(function() switchTab(tab) end)
end

switchTab(tabs[1])

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
	UserProfilePanel.Visible = not isMinimized 
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
-- KEY SYSTEM
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

local KeyDiscordBtn = createContentButton(KeyWindow, "Click to copy Discord Server link", copyDiscord)
KeyDiscordBtn.Name = "KeyDiscordBtn"
KeyDiscordBtn.Size = UDim2.new(1, -40, 0, 40)
KeyDiscordBtn.Position = UDim2.new(0, 20, 0, 105)

local KeyTextBox = createTextBox(KeyWindow, "Enter key here...", Enum.Font.SourceSans)
KeyTextBox.Size = UDim2.new(1, -40, 0, 40)
KeyTextBox.Position = UDim2.new(0, 20, 0, 165)

makeDraggable(KeyTopBar, KeyWindow)

-- ==========================================
-- НАДЁЖНЫЙ ДЕКРИПТОР
-- ==========================================
local SECRET_KEY = "XenoMeowEmilyUi11037"

local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- Самый надёжный pure-Lua base64 decode для Roblox
local function base64_decode(data)
	data = string.gsub(data, '[^'..b..'=]', '')
	return (data:gsub('.', function(x)
		if (x == '=') then return '' end
		local r, f = '', (b:find(x) - 1)
		for i = 6, 1, -1 do
			r = r .. (f % 2^i - f % 2^(i - 1) > 0 and '1' or '0')
		end
		return r
	end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
		if (#x ~= 8) then return '' end
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
		local byte_str = string.byte(str, i)
		local byte_key = string.byte(key, ((i - 1) % keyLen) + 1)
		result[i] = string.char(bit32.bxor(byte_str, byte_key))
	end
	return table.concat(result)
end

local function decryptData(encryptedBase64, key)
	-- Убираем все пробелы, переносы и прочий мусор
	encryptedBase64 = string.gsub(encryptedBase64, "%s+", "")
	local rawEncrypted = base64_decode(encryptedBase64)
	return xor_decrypt(rawEncrypted, key)
end

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
		return diff / 86400 
	end
end

local function unlockScript(userGroup, daysLeft)
	KeyWindow:Destroy()
	MainWindow.Visible = true
	updateProfilePanel(userGroup or "Free", daysLeft)
	StarterGui:SetCore("SendNotification", { 
		Title = "EmilyUi is loaded", 
		Text = "Welcome! Role: " .. (userGroup or "User"),
		Duration = 10
	})
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

		local decryptSuccess, decryptedText = pcall(function()
			return decryptData(response, SECRET_KEY)
		end)
		
		if not decryptSuccess or not decryptedText or #decryptedText < 5 then
			KeyInfoLabel.Text = "Error: Failed to decrypt!\nLen: " .. tostring(decryptedText and #decryptedText or 0)
			KeyInfoLabel.TextColor3 = Color3.fromRGB(220, 50, 50)
			return
		end

		-- Показываем начало расшифрованного текста для отладки (временно)
		-- print("Decrypted start:", string.sub(decryptedText, 1, 80))

		cachedKeyResponse = decryptedText
	end
	
	local jsonSuccess, keysList = pcall(function()
		return HttpService:JSONDecode(cachedKeyResponse)
	end)

	if not jsonSuccess or type(keysList) ~= "table" then
		-- Более информативная ошибка
		local preview = string.sub(tostring(cachedKeyResponse), 1, 60)
		KeyInfoLabel.Text = "Error: Database parsing failed!\nPreview: " .. preview
		KeyInfoLabel.TextColor3 = Color3.fromRGB(220, 50, 50)
		return
	end

	local myName = string.lower(LocalPlayer.Name)
	local enteredKey = KeyTextBox.Text
	
	for _, data in ipairs(keysList) do
		if data.key and data.robloxName and data.group and data.timeTillWorks then
			local nameMatch = (data.robloxName == "none") or (string.lower(data.robloxName) == myName)
			if nameMatch then
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

local BtnSubmit = createContentButton(KeyWindow, "Check Key", checkKeySystem, Color3.fromRGB(50, 120, 50))
BtnSubmit.Size = UDim2.new(0, 150, 0, 40)
BtnSubmit.Position = UDim2.new(0.5, -75, 0, 230)

task.spawn(checkKeySystem)