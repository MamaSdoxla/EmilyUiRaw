-- EmilyUiModule.lua
local Core=_G.FuckYouCore
assert(Core,"Run FuckYouLibrary.lua first")
local create=Core.create; local themeElements=Core.themeElements; local FONT=Core.FONT; local COL_BORDER=Core.COL_BORDER
local tabFrames=Core.tabFrames; local MenuInsided=Core.MenuInsided; local Containment=Core.Containment; local ScreenGui=Core.ScreenGui
local LocalPlayer=Core.LocalPlayer; local Players=Core.Players; local RunService=Core.RunService; local HttpService=Core.HttpService
local notify=Core.notify; local applyTheme=Core.applyTheme; local updateTabButtonsTheme=Core.UpdateTabButtonsTheme
local makeSideBtn=Core.makeSideBtn; local createSection=Core.createSection; local createLabel=Core.createLabel; local createContentButton=Core.createContentButton; local createTextBox=Core.createTextBox
local saveConfig=Core.saveConfig; local autoSaveConfig=Core.autoSaveConfig; local registerConfigSaveListener=Core.registerConfigSaveListener
local uiColor_TextColor=Core.Theme.TextColor; local uiColor_ButtonColor=Core.Theme.ButtonColor; local uiColor_TextBoxColor=Core.Theme.TextBoxColor; local uiColor_SideBar=Core.Theme.SideBar; local uiGuiOpacity=Core.Theme.GuiOpacity
local currentToggleKey=Core.currentToggleKey
local tabs=Core.tabs
local function syncTheme() uiColor_TextColor=Core.Theme.TextColor; uiColor_ButtonColor=Core.Theme.ButtonColor; uiColor_TextBoxColor=Core.Theme.TextBoxColor; uiColor_SideBar=Core.Theme.SideBar; uiGuiOpacity=Core.Theme.GuiOpacity end

local function createSection(parent, text)
	local lbl = create("TextLabel", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = text, TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT, Parent = parent})
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
	local btn = create("TextButton", {Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = defaultColor, BorderColor3 = COL_BORDER, TextColor3 = uiColor_TextColor, Text = text, Font = FONT, TextSize = 13, BackgroundTransparency = 1 - uiGuiOpacity, Parent = parent})
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
	local box = create("TextBox", {BackgroundColor3 = uiColor_TextBoxColor, BorderColor3 = COL_BORDER, TextColor3 = uiColor_TextColor, PlaceholderColor3 = Color3.fromRGB(90, 90, 90), PlaceholderText = placeholder, Text = "", TextSize = 13, Font = font or FONT, ClearTextOnFocus = false, BackgroundTransparency = 1 - uiGuiOpacity, Parent = parent})
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

create("TextLabel", {Parent = UserProfilePanel, Position = UDim2.new(0, 60, 0, 6), Size = UDim2.new(1, -70, 0, 16), BackgroundTransparency = 1, Text = LocalPlayer.DisplayName, TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd})

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

do -- контент-блок (вкладки/Games/Animations)
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
    { tab = tabFrames.Universal, type = "button", text = "Cobalt", cb = function() loadstring(game:HttpGet("https://gitlab.com/upio/cobalt/-/releases/permalink/latest/downloads/Cobalt.luau"))() end },
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
end -- конец контент-блока
-- =========================================================
-- ========== CHARACTER / PLAYERS / VISUALS / UTILS / SERVER
-- =========================================================
do
local TeleportService = game:GetService("TeleportService")
local LightingService = game:GetService("Lighting")
local StatsService = game:GetService("Stats")
local Marketplace = game:GetService("MarketplaceService")

local function getMyChar() return LocalPlayer.Character end
local function getMyHum() local c = getMyChar() return c and c:FindFirstChildOfClass("Humanoid") end
local function getMyRoot() local c = getMyChar() return c and c:FindFirstChild("HumanoidRootPart") end

------------------------------------------------------------
-- UI HELPERS
------------------------------------------------------------
local function extraSlider(parent, labelText, min, max, decimals, default, getval, onval, fmt)
	local container = create("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = parent})
	local label = create("TextLabel", {Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1, Text = labelText, TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, Parent = container})
	table.insert(themeElements.Texts, label)
	local rightEnd = default and 0.85 or 0.99
	local valLabel = create("TextLabel", {Size = UDim2.new(rightEnd - 0.48, 0, 0, 14), Position = UDim2.new(0.48, 0, 0.05, 0), BackgroundTransparency = 1, Text = fmt(getval()), TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Right, Parent = container})
	table.insert(themeElements.Texts, valLabel)
	local track = create("TextButton", {Size = UDim2.new(rightEnd - 0.48, 0, 0, 10), Position = UDim2.new(0.48, 0, 0.55, 0), BackgroundColor3 = uiColor_TextBoxColor, BorderColor3 = COL_BORDER, BackgroundTransparency = 1 - uiGuiOpacity, Text = "", Parent = container})
	table.insert(themeElements.TextBoxes, track)
	local fill = create("Frame", {Size = UDim2.new(math.clamp((getval() - min) / (max - min), 0, 1), 0, 1, 0), BackgroundColor3 = uiColor_TextColor, BorderSizePixel = 0, Parent = track})
	table.insert(themeElements.FillBars, fill)
	local dragging = false
	local function setFromX(x)
		local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		local raw = min + (max - min) * rel
		local v
		if decimals > 0 then
			local step = 10 ^ (-decimals)
			v = math.floor(raw / step + 0.5) * step
		else
			v = math.floor(raw + 0.5)
		end
		v = math.clamp(v, min, max)
		onval(v)
		fill.Size = UDim2.new(math.clamp((v - min) / (max - min), 0, 1), 0, 1, 0)
		valLabel.Text = fmt(v)
	end
	track.MouseButton1Down:Connect(function(x)
		dragging = true
		setFromX(x)
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then setFromX(input.Position.X) end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
	if default then
		local defBtn = create("TextButton", {Size = UDim2.new(0.13, 0, 0.7, 0), Position = UDim2.new(0.86, 0, 0.15, 0), BackgroundColor3 = uiColor_ButtonColor, BorderColor3 = COL_BORDER, BackgroundTransparency = 1 - uiGuiOpacity, TextColor3 = uiColor_TextColor, Text = "Default", Font = FONT, TextSize = 10, Parent = container})
		table.insert(themeElements.Buttons, defBtn)
		table.insert(themeElements.Texts, defBtn)
		defBtn.MouseButton1Click:Connect(function()
            local v = default
            onval(v)
            fill.Size = UDim2.new(math.clamp((v - min) / (max - min), 0, 1), 0, 1, 0)
            valLabel.Text = fmt(v)

            if queueVisualSave then
                queueVisualSave()
            end
        end)
	end
	return container
end

local function extraToggle(parent, labelText, initial, callback)
	local obj = {State = initial and true or false}

	local btn = create("TextButton", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = uiColor_ButtonColor,
		BorderColor3 = COL_BORDER,
		BackgroundTransparency = 1 - uiGuiOpacity,
		TextColor3 = uiColor_TextColor,
		Text = "",
		Font = FONT,
		TextSize = 13,
		Parent = parent
	})

	obj.Button = btn

	table.insert(themeElements.CustomButtons, btn)
	table.insert(themeElements.Texts, btn)

	local function paint()
		btn.Text = labelText .. ": " .. (obj.State and "ON" or "OFF")
		paintToggleBtn(btn, obj.State)
	end

	function obj:Get()
		return self.State
	end

	function obj:Set(v)
		self.State = v and true or false
		paint()
		if callback then
			callback(self.State)
		end
	end

	paint()
	registerToggle(btn, function() return obj.State end)

	btn.MouseButton1Click:Connect(function()
        obj:Set(not obj.State)
        if queueVisualSave then
            queueVisualSave()
        end
    end)

	return obj
end

local function extraDropdown(parent, labelText, options, getcur, onselect)
	local container = create("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = parent})
	local label = create("TextLabel", {Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1, Text = labelText, TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, Parent = container})
	table.insert(themeElements.Texts, label)
	local btn = createContentButton(container, labelText .. ": " .. getcur(), function() end)
	btn.Size = UDim2.new(0.5, 0, 0.8, 0)
	btn.Position = UDim2.new(0.48, 0, 0.1, 0)
	btn.TextSize = 12
	local list = create("ScrollingFrame", {Parent = container, Size = UDim2.new(0.5, 0, 0, 110), Position = UDim2.new(0.48, 0, 0.95, 0), BackgroundColor3 = uiColor_TextBoxColor, BorderColor3 = COL_BORDER, ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 0), Visible = false, ZIndex = 25})
	table.insert(themeElements.TextBoxes, list)
	create("UIListLayout", {Parent = list, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2)})
	btn.MouseButton1Click:Connect(function()
		if list.Visible then list.Visible = false return end
		for _, ch in ipairs(list:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
		for _, opt in ipairs(options) do
			local ob = createContentButton(list, opt, function()
                onselect(opt)
                list.Visible = false
                btn.Text = labelText .. ": " .. getcur()

                if queueVisualSave then
                    queueVisualSave()
                end
            end)
			ob.Size = UDim2.new(1, -4, 0, 24)
			ob.ZIndex = 26
			ob.TextSize = 12
		end
		list.CanvasSize = UDim2.new(0, 0, 0, #options * 26 + 4)
		list.Visible = true
	end)
end

local function extraColorInput(parent, labelText, getcol, oncol)
	local container = create("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = parent})
	local label = create("TextLabel", {Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1, Text = labelText, TextColor3 = uiColor_TextColor, TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, Parent = container})
	table.insert(themeElements.Texts, label)
	local c = getcol()
	local box = createTextBox(container, "R,G,B", FONT)
	box.Size = UDim2.new(0.5, 0, 0.8, 0)
	box.Position = UDim2.new(0.48, 0, 0.1, 0)
	box.TextSize = 12
	box.Text = math.floor(c.R * 255) .. ", " .. math.floor(c.G * 255) .. ", " .. math.floor(c.B * 255)
	box.FocusLost:Connect(function()
        local r, g, b = box.Text:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
        if r and g and b then
            oncol(Color3.fromRGB(math.clamp(tonumber(r), 0, 255), math.clamp(tonumber(g), 0, 255), math.clamp(tonumber(b), 0, 255)))

            if queueVisualSave then
                queueVisualSave()
            end
        else
            box.Text = "Invalid!"
        end
    end)
	return container
end

------------------------------------------------------------
-- 1) CHARACTER
------------------------------------------------------------
local CharSettings = {Speed = 16, Jump = 50, Gravity = 196.2}
local VisualSettings = {FOV = 70, DoF = 0, Saturation = 100, Contrast = 100, AspectH = 100, AspectV = 100}
local visToggles = {}

do -- CHARACTER
local SpinSettings = { Enabled = false, Speed = 180 }

local CharacterKeybinds = {
    SpinToggle = Enum.KeyCode.V,
}

local CHARACTER_SETTINGS_PATH = "EmilyUi/FuckYou/CharacterSettings.json"

local function ensureCharacterDirs()
    if makefolder then
        pcall(function()
            if not isfolder("EmilyUi") then makefolder("EmilyUi") end
            if not isfolder("EmilyUi/FuckYou") then makefolder("EmilyUi/FuckYou") end
        end)
    end
end

local charSaveQueued = false

local function saveCharacterSettingsNow()
    if writefile then
        ensureCharacterDirs()

        pcall(function()
            writefile(CHARACTER_SETTINGS_PATH, HttpService:JSONEncode({
                SpinSpeed = SpinSettings.Speed,
                SpinKey = CharacterKeybinds.SpinToggle and CharacterKeybinds.SpinToggle.Name or "",
            }))
        end)
    end

    if autoSaveConfig then
        autoSaveConfig(true)
    end
end

local function queueCharacterSave()
    if charSaveQueued then return end

    charSaveQueued = true

    task.delay(1, function()
        charSaveQueued = false
        saveCharacterSettingsNow()
    end)
end

local function loadCharacterSettings()
    if readfile and isfile and isfile(CHARACTER_SETTINGS_PATH) then
        local ok, json = pcall(function()
            return readfile(CHARACTER_SETTINGS_PATH)
        end)

        if ok and json then
            local ok2, data = pcall(function()
                return HttpService:JSONDecode(json)
            end)

            if ok2 and type(data) == "table" then
                if type(data.SpinSpeed) == "number" then
                    SpinSettings.Speed = math.clamp(data.SpinSpeed, 0, 360)
                end

                if type(data.SpinKey) == "string" and data.SpinKey ~= "" then
                    local ok3, key = pcall(function()
                        return Enum.KeyCode[data.SpinKey]
                    end)

                    if ok3 and key then
                        CharacterKeybinds.SpinToggle = key
                    else
                        CharacterKeybinds.SpinToggle = nil
                    end
                else
                    CharacterKeybinds.SpinToggle = nil
                end

                -- При запуске спин держим выключенным
                SpinSettings.Enabled = false
            end
        end
    end
end

loadCharacterSettings()

local function charKeyName(v)
    if typeof(v) == "EnumItem" then
        return v.Name
    end
    return "None"
end

local infJumpConn, afkConn = nil, nil
local spinConn = nil
local spinToggleObj = nil

local function applyCharStats()
	local h = getMyHum()
	if h then
		pcall(function() h.WalkSpeed = CharSettings.Speed end)
		pcall(function() h.UseJumpPower = true h.JumpPower = CharSettings.Jump end)
	end
	pcall(function() workspace.Gravity = CharSettings.Gravity end)
end

local function setInfiniteJump(on)
	if on and not infJumpConn then
		infJumpConn = UserInputService.JumpRequest:Connect(function()
			local h = getMyHum()
			if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
		end)
	elseif not on and infJumpConn then
		infJumpConn:Disconnect()
		infJumpConn = nil
	end
end

local function updateSpin()
if SpinSettings.Enabled and spinConn == nil then
spinConn = RunService.Heartbeat:Connect(function(dt)
local root = getMyRoot()
if root then
local angle = math.rad(SpinSettings.Speed) * dt
root.CFrame = root.CFrame * CFrame.Angles(0, angle, 0)
end
end)
elseif not SpinSettings.Enabled and spinConn then
spinConn:Disconnect()
spinConn = nil
end
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    if CharacterKeybinds.SpinToggle ~= nil and input.KeyCode == CharacterKeybinds.SpinToggle then
        SpinSettings.Enabled = not SpinSettings.Enabled
        updateSpin()

        if spinToggleObj then
            spinToggleObj:Set(SpinSettings.Enabled)
        end

        queueCharacterSave()
    end
end)

local function setAntiAFK(on)
	if on and not afkConn then
		afkConn = LocalPlayer.Idled:Connect(function()
			pcall(function()
				local VirtualUser = game:GetService("VirtualUser")
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
		end)
	elseif not on and afkConn then
		afkConn:Disconnect()
		afkConn = nil
	end
end

createSection(tabFrames.Character, "Character")
extraSlider(tabFrames.Character, "Speed", 1, 500, 0, 16,
	function() return CharSettings.Speed end,
	function(v) CharSettings.Speed = v applyCharStats() end,
	function(v) return tostring(v) end)
extraSlider(tabFrames.Character, "Jump", 1, 500, 0, 50,
	function() return CharSettings.Jump end,
	function(v) CharSettings.Jump = v applyCharStats() end,
	function(v) return tostring(v) end)
extraSlider(tabFrames.Character, "Gravity", 0, 3000, 1, 196.2,
	function() return CharSettings.Gravity end,
	function(v) CharSettings.Gravity = v applyCharStats() end,
	function(v) return string.format("%.1f", v) end)
extraToggle(tabFrames.Character, "Infinite Jump", false, setInfiniteJump)
extraToggle(tabFrames.Character, "Anti-AFK", false, setAntiAFK)

spinToggleObj = extraToggle(tabFrames.Character, "Spin", SpinSettings.Enabled, function(on)
    SpinSettings.Enabled = on
    updateSpin()
    queueCharacterSave()
end)

extraSlider(tabFrames.Character, "Spin Speed (0-360)", 0, 360, 0, SpinSettings.Speed,
function() return SpinSettings.Speed end,
function(v)
    SpinSettings.Speed = v
    queueCharacterSave()
end,
function(v) return v .. "°" end)

local spinBindBtn = createContentButton(tabFrames.Character, "Spin Key: [" .. charKeyName(CharacterKeybinds.SpinToggle) .. "]", function()
    spinBindBtn.Text = "Spin Key: [PRESS ANY KEY | BACKSPACE = CLEAR]"

    local conn
    conn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end

        if input.KeyCode == Enum.KeyCode.Backspace then
            CharacterKeybinds.SpinToggle = nil
            spinBindBtn.Text = "Spin Key: [None]"
            queueCharacterSave()

            if conn then
                conn:Disconnect()
            end
            return
        end

        if input.KeyCode ~= Enum.KeyCode.Unknown then
            CharacterKeybinds.SpinToggle = input.KeyCode
            spinBindBtn.Text = "Spin Key: [" .. input.KeyCode.Name .. "]"
            queueCharacterSave()

            if conn then
                conn:Disconnect()
            end
        end
    end)

    task.delay(5, function()
        if conn and conn.Connected then
            conn:Disconnect()
            spinBindBtn.Text = "Spin Key: [" .. charKeyName(CharacterKeybinds.SpinToggle) .. "]"
        end
    end)
end)

ScreenGui.Destroying:Connect(function()
    pcall(function()
        SpinSettings.Enabled = false

        if spinToggleObj then
            spinToggleObj:Set(false)
        end

        updateSpin()
        saveCharacterSettingsNow()
    end)
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.1)
    applyCharStats()
end)
end -- конец блока CHARACTER

do -- PLAYERS

------------------------------------------------------------
-- 2) PLAYERS
------------------------------------------------------------
local hiddenPlayers = {}
local markedPlayers = {}
local spectateTarget = nil
local playerCards = {}
local refreshPlayersList

local function applyMark(plr, on)
	local char = plr.Character
	if not char then return end
	local old = char:FindFirstChild("FY_Mark")
	if old then old:Destroy() end
	if on then
		local hl = Instance.new("Highlight")
		hl.Name = "FY_Mark"
		hl.FillColor = Color3.fromRGB(255, 80, 80)
		hl.FillTransparency = 0.6
		hl.OutlineColor = Color3.fromRGB(255, 255, 255)
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Parent = char
	end
end

local function updateViewButtons()
	for plr, cardData in pairs(playerCards) do
		if cardData.ViewBtn then cardData.ViewBtn.Text = (spectateTarget == plr) and "Stop" or "View" end
	end
end

local function stopSpectate()
	spectateTarget = nil
	local h = getMyHum()
	if h then workspace.CurrentCamera.CameraSubject = h end
	updateViewButtons()
end

local function startSpectate(plr)
	spectateTarget = plr
	local h = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
	if h then workspace.CurrentCamera.CameraSubject = h end
	updateViewButtons()
end

local function gotoPlayer(plr)
	local r = getMyRoot()
	local t = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if r and t then
		r.CFrame = t.CFrame + Vector3.new(3, 0, 0)
		notify("Players", "Teleported to " .. plr.Name)
	else
		notify("Players", "Target unavailable")
	end
end

createSection(tabFrames.Players, "Players")
local pStopBtn = createContentButton(tabFrames.Players, "Stop Spectating", function() stopSpectate() end)
pStopBtn.LayoutOrder = -3
local pRefreshBtn = createContentButton(tabFrames.Players, "Refresh List", function() refreshPlayersList() end)
pRefreshBtn.LayoutOrder = -2
local pUnhideBtn = createContentButton(tabFrames.Players, "Unhide All", function() hiddenPlayers = {} refreshPlayersList() end)
pUnhideBtn.LayoutOrder = -1

local function buildPlayerCard(plr)
	-- FIX: плашка полностью прозрачная (не видна), кнопки берут прозрачность темы
	local card = create("Frame", {Name = "PlayerCard", Parent = tabFrames.Players, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, BorderSizePixel = 0})
	create("UIListLayout", {Parent = card, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
	create("UIPadding", {Parent = card, PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8)})

	local header = create("Frame", {Parent = card, Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1})
	local avatar = create("ImageLabel", {Parent = header, Position = UDim2.new(0, 0, 0, 2), Size = UDim2.new(0, 40, 0, 40), BackgroundTransparency = 1, Image = "rbxthumb://type=AvatarHeadShot&id=" .. plr.UserId .. "&w=150&h=150"})
	create("UICorner", {Parent = avatar, CornerRadius = UDim.new(1, 0)})
	create("TextLabel", {Parent = header, Position = UDim2.new(0, 48, 0, 3), Size = UDim2.new(0.55, -48, 0, 18), BackgroundTransparency = 1, Text = plr.DisplayName, TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd})
	create("TextLabel", {Parent = header, Position = UDim2.new(0, 48, 0, 23), Size = UDim2.new(0.55, -48, 0, 16), BackgroundTransparency = 1, Text = "@" .. plr.Name, TextColor3 = Color3.fromRGB(140, 140, 140), TextSize = 11, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd})
	local distL = create("TextLabel", {Parent = header, Position = UDim2.new(0.6, 0, 0, 6), Size = UDim2.new(0.4, 0, 0, 16), BackgroundTransparency = 1, Text = "--", TextColor3 = Color3.fromRGB(160, 160, 160), TextSize = 11, Font = FONT, TextXAlignment = Enum.TextXAlignment.Right})

	local row = create("Frame", {Parent = card, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1})
	local function cardBtn(text, i)
		local b = create("TextButton", {Parent = row, Size = UDim2.new(0.2, -4, 1, 0), Position = UDim2.new(0.2 * i, 0, 0, 0), BackgroundColor3 = uiColor_ButtonColor, BorderColor3 = COL_BORDER, BackgroundTransparency = 1 - uiGuiOpacity, TextColor3 = uiColor_TextColor, Text = text, Font = FONT, TextSize = 11, TextWrapped = true})
		table.insert(themeElements.Buttons, b)
		table.insert(themeElements.Texts, b)
		return b
	end
	local gotoB = cardBtn("Goto", 0)
	local viewB = cardBtn("View", 1)
	local hideB = cardBtn("Hide", 2)
	local markB = cardBtn(markedPlayers[plr] and "Unmark" or "Mark", 3)
	local infoB = cardBtn("Info", 4)

	local infoF = create("Frame", {Parent = card, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false})
	create("UIListLayout", {Parent = infoF, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2)})
	local function infoRow(t)
		local l = create("TextLabel", {Parent = infoF, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = t, TextColor3 = uiColor_TextColor, TextSize = 12, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left})
		table.insert(themeElements.Texts, l)
		return l
	end
	local idL = infoRow("User ID: " .. plr.UserId)
	local ageL = infoRow("Account Age: " .. tostring(plr.AccountAge) .. " days")
	local teamL = infoRow("Team: --")
	local rigL = infoRow("Rig: --")
	local hpL = infoRow("Health: --")
	local wsL = infoRow("Walk speed: --")
	local dL = infoRow("Distance: --")
	local posL = infoRow("Position: --")

	local function updateCard()
		local myRoot = getMyRoot()
		local tRoot = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		local dist = nil
		if myRoot and tRoot then dist = math.floor((tRoot.Position - myRoot.Position).Magnitude) end
		distL.Text = dist and (dist .. " studs") or "--"
		if infoF.Visible then
			local h = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
			idL.Text = "User ID: " .. plr.UserId
			ageL.Text = "Account Age: " .. tostring(plr.AccountAge) .. " days"
			teamL.Text = "Team: " .. (plr.Team and plr.Team.Name or "None")
			local rig = "None"
			if plr.Character then
				if plr.Character:FindFirstChild("LeftHand") or plr.Character:FindFirstChild("UpperTorso") then rig = "R15"
				elseif plr.Character:FindFirstChild("Torso") then rig = "R6" end
			end
			rigL.Text = "Rig: " .. rig
			if h then
				hpL.Text = "Health: " .. math.max(0, math.floor(h.Health)) .. " / " .. math.floor(h.MaxHealth)
				wsL.Text = "Walk speed: " .. math.floor(h.WalkSpeed)
			else
				hpL.Text = "Health: --"
				wsL.Text = "Walk speed: --"
			end
			dL.Text = dist and ("Distance: " .. dist .. " studs") or "Distance: --"
			posL.Text = tRoot and ("Position: " .. math.floor(tRoot.Position.X) .. ", " .. math.floor(tRoot.Position.Y) .. ", " .. math.floor(tRoot.Position.Z)) or "Position: --"
		end
	end

	gotoB.MouseButton1Click:Connect(function() gotoPlayer(plr) end)
	viewB.MouseButton1Click:Connect(function()
		if spectateTarget == plr then stopSpectate() else startSpectate(plr) end
	end)
	hideB.MouseButton1Click:Connect(function()
		hiddenPlayers[plr] = true
		refreshPlayersList()
	end)
	markB.MouseButton1Click:Connect(function()
		markedPlayers[plr] = not markedPlayers[plr]
		applyMark(plr, markedPlayers[plr])
		markB.Text = markedPlayers[plr] and "Unmark" or "Mark"
	end)
	infoB.MouseButton1Click:Connect(function()
		infoF.Visible = not infoF.Visible
		infoB.Text = infoF.Visible and "Close" or "Info"
		if infoF.Visible then updateCard() end
	end)

	playerCards[plr] = {ViewBtn = viewB, Update = updateCard}
	updateCard()
end

refreshPlayersList = function()
	for _, ch in ipairs(tabFrames.Players:GetChildren()) do
		if ch.Name == "PlayerCard" then ch:Destroy() end
	end
	playerCards = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and not hiddenPlayers[plr] then
			buildPlayerCard(plr)
		end
	end
	updateViewButtons()
end
refreshPlayersList()

Players.PlayerRemoving:Connect(function(plr)
	hiddenPlayers[plr] = nil
	markedPlayers[plr] = nil
	if spectateTarget == plr then stopSpectate() end
	refreshPlayersList()
end)
Players.PlayerAdded:Connect(function()
	task.wait(1)
	refreshPlayersList()
end)
local function hookPlayerChar(plr)
	plr.CharacterAdded:Connect(function(char)
		task.wait(0.1)
		if markedPlayers[plr] then applyMark(plr, true) end
		if spectateTarget == plr then
			local h = char:FindFirstChildOfClass("Humanoid")
			if h then workspace.CurrentCamera.CameraSubject = h end
		end
	end)
end
for _, plr in ipairs(Players:GetPlayers()) do hookPlayerChar(plr) end
Players.PlayerAdded:Connect(hookPlayerChar)

task.spawn(function()
	while true do
		task.wait(0.5)
		if spectateTarget then
			local h = spectateTarget.Character and spectateTarget.Character:FindFirstChildOfClass("Humanoid")
			if h and h.Health > 0 then
				workspace.CurrentCamera.CameraSubject = h
			else
				stopSpectate()
			end
		end
		for plr, cardData in pairs(playerCards) do
			if plr.Parent then cardData.Update() end
		end
	end
end)

end -- конец блока PLAYERS

do -- VISUALS
------------------------------------------------------------
-- 3) VISUALS
------------------------------------------------------------
local TrailSettings = {
	Enabled = false,
	Mode = "Solid",
	Source = "All",
	ColorA = Color3.fromRGB(255, 255, 255),
	ColorB = Color3.fromRGB(80, 255, 120),
	ColorC = Color3.fromRGB(255, 170, 0),
	Length = 0.6,
	FadeSpeed = 1,
	ColorSpeed = 1,
}
local crosshairGui = nil
local activeTrails = {}
local updateTrailVis

local function setCrosshair(on)
	if on and not crosshairGui then
		crosshairGui = create("ScreenGui", {Name = "FYCrosshair", ResetOnSpawn = false, IgnoreGuiInset = true, Parent = LocalPlayer:WaitForChild("PlayerGui")})
		local geo = {{2, 8, 0, -9}, {2, 8, 0, 9}, {8, 2, -9, 0}, {8, 2, 9, 0}}
		for _, g in ipairs(geo) do
			local f = create("Frame", {Parent = crosshairGui, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, g[1], 0, g[2]), Position = UDim2.new(0.5, g[3], 0.5, g[4]), BackgroundColor3 = uiColor_TextColor, BorderSizePixel = 0})
			table.insert(themeElements.FillBars, f)
		end
	elseif not on and crosshairGui then
		crosshairGui:Destroy()
		crosshairGui = nil
	end
end

local function applyFOV(v)
	VisualSettings.FOV = v
	pcall(function() workspace.CurrentCamera.FieldOfView = v end)
end

--// Aspect Ratio: независимое сжатие осей камеры (100% = выключено)
local aspectConn = nil
local function updateAspectLoop()
	if aspectConn then aspectConn:Disconnect() aspectConn = nil end
	if VisualSettings.AspectH >= 100 and VisualSettings.AspectV >= 100 then return end
	aspectConn = RunService.RenderStepped:Connect(function()
		local cam = workspace.CurrentCamera
		local h = VisualSettings.AspectH / 100
		local v = VisualSettings.AspectV / 100
		cam.CFrame = cam.CFrame * CFrame.new(0, 0, 0, h, 0, 0, 0, v, 0, 0, 0, 1)
	end)
end

local fullbrightOn = false
local fbSaved = nil
local function setFullbright(on)
	local L = LightingService
	if on and not fullbrightOn then
		fbSaved = {Brightness = L.Brightness, ClockTime = L.ClockTime, FogEnd = L.FogEnd, GlobalShadows = L.GlobalShadows, Ambient = L.Ambient, OutdoorAmbient = L.OutdoorAmbient}
		fullbrightOn = true
		L.Brightness = 2
		L.ClockTime = 14
		L.FogEnd = 100000
		L.GlobalShadows = false
		L.Ambient = Color3.fromRGB(180, 180, 180)
		L.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
	elseif not on and fullbrightOn then
		fullbrightOn = false
		if fbSaved then
			for k, v in pairs(fbSaved) do L[k] = v end
			fbSaved = nil
		end
	end
end

--// Trails: выбор источника (у Trail нет свойства Material, поэтому его нет)
local TRAIL_PARTS = {
	Body = {"HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"},
	Arms = {"LeftHand", "RightHand", "Left Arm", "Right Arm"},
	Legs = {"LeftFoot", "RightFoot", "Left Leg", "Right Leg"},
}
local function getTrailPartNames(source)
	local out = {}
	local function add(list)
		for _, n in ipairs(list) do table.insert(out, n) end
	end
	if source == "All" then
		add(TRAIL_PARTS.Body) add(TRAIL_PARTS.Arms) add(TRAIL_PARTS.Legs)
	elseif source == "Legs+Arms" then
		add(TRAIL_PARTS.Arms) add(TRAIL_PARTS.Legs)
	elseif TRAIL_PARTS[source] then
		add(TRAIL_PARTS[source])
	end
	return out
end

local function cycle3(a, b, c, t)
	t = t % 1
	if t < 1 / 3 then return a:Lerp(b, t * 3)
	elseif t < 2 / 3 then return b:Lerp(c, (t - 1 / 3) * 3)
	end
	return c:Lerp(a, (t - 2 / 3) * 3)
end
local function trailColorAt(t)
	local mode = TrailSettings.Mode
	local tt = t * TrailSettings.ColorSpeed
	if mode == "TwoWay" then
		return TrailSettings.ColorA:Lerp(TrailSettings.ColorB, (math.sin(tt * 1.6) + 1) / 2)
	elseif mode == "ThreeWay" then
		return cycle3(TrailSettings.ColorA, TrailSettings.ColorB, TrailSettings.ColorC, tt * 0.25)
	elseif mode == "Rainbow" then
		return Color3.fromHSV((tt * 0.12) % 1, 1, 1)
	end
	return TrailSettings.ColorA
end

local function buildTrails(char)
	if not char then return end
	for _, d in ipairs(char:GetDescendants()) do
		if d.Name == "FY_Trail" or d.Name == "FY_TrailAtt0" or d.Name == "FY_TrailAtt1" then d:Destroy() end
	end
	activeTrails = {}
	if not TrailSettings.Enabled then return end
	local fadePos = math.clamp(1 / TrailSettings.FadeSpeed, 0.05, 1)
	local ns
	if fadePos >= 1 then
		ns = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
	else
		ns = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(fadePos, 1), NumberSequenceKeypoint.new(1, 1)})
	end
	for _, pn in ipairs(getTrailPartNames(TrailSettings.Source)) do
		local limb = char:FindFirstChild(pn)
		if limb and limb:IsA("BasePart") then
			local a0 = Instance.new("Attachment", limb)
			a0.Name = "FY_TrailAtt0"
			a0.Position = Vector3.new(0, limb.Size.Y / 2, 0)
			local a1 = Instance.new("Attachment", limb)
			a1.Name = "FY_TrailAtt1"
			a1.Position = Vector3.new(0, -limb.Size.Y / 2, 0)
			local tr = Instance.new("Trail", limb)
			tr.Name = "FY_Trail"
			tr.Attachment0 = a0
			tr.Attachment1 = a1
			tr.Color = ColorSequence.new(trailColorAt(tick()))
			tr.Transparency = ns
			tr.Lifetime = TrailSettings.Length
			tr.LightEmission = 1
			table.insert(activeTrails, tr)
		end
	end
end
local function rebuildTrails() buildTrails(getMyChar()) end

RunService.RenderStepped:Connect(function()
	if not TrailSettings.Enabled or #activeTrails == 0 then return end
	local col = ColorSequence.new(trailColorAt(tick()))
	for _, tr in ipairs(activeTrails) do
		if tr.Parent then tr.Color = col end
	end
end)

local worldColorEff = Instance.new("ColorCorrectionEffect", LightingService)
worldColorEff.Name = "FYWorldColor"
worldColorEff.Enabled = false
worldColorEff.TintColor = Color3.fromRGB(255, 255, 255)
local WorldColorVal = Color3.fromRGB(255, 255, 255)
local WorldColorStrength = 100
local function applyWorldColor()
worldColorEff.TintColor = Color3.new(1, 1, 1):Lerp(WorldColorVal, math.clamp(WorldColorStrength, 0, 100) / 100)
end
local dofEff = Instance.new("DepthOfFieldEffect", LightingService)
dofEff.Enabled = false
dofEff.InFocusRadius = 8
local ccEff = Instance.new("ColorCorrectionEffect", LightingService)
ccEff.Saturation = 0
ccEff.Contrast = 0
createSection(tabFrames.Visuals, "Visuals")
visToggles.Crosshair = extraToggle(tabFrames.Visuals, "Crosshair", false, setCrosshair)
extraSlider(tabFrames.Visuals, "FOV", 30, 120, 0, nil,
	function() return VisualSettings.FOV end,
	function(v) applyFOV(v) end,
	function(v) return tostring(v) end)
visToggles.Fullbright = extraToggle(tabFrames.Visuals, "Fullbright", false, setFullbright)
visToggles.Trails = extraToggle(tabFrames.Visuals, "Trails", false, function(on)
	TrailSettings.Enabled = on
	rebuildTrails()
end)
local trailModeBtn = createContentButton(tabFrames.Visuals, "Trail Color Mode: " .. TrailSettings.Mode, function() end)
trailModeBtn.MouseButton1Click:Connect(function()
	local opts = {"Solid", "TwoWay", "ThreeWay", "Rainbow"}
	local idx = table.find(opts, TrailSettings.Mode) or 1
	TrailSettings.Mode = opts[(idx % #opts) + 1]
	trailModeBtn.Text = "Trail Color Mode: " .. TrailSettings.Mode
	if updateTrailVis then updateTrailVis() end
end)
extraDropdown(tabFrames.Visuals, "Trail Source", {"All", "Body", "Arms", "Legs", "Legs+Arms"},
	function() return TrailSettings.Source end,
	function(s) TrailSettings.Source = s rebuildTrails() end)
local trailRowA = extraColorInput(tabFrames.Visuals, "Trail Color A", function() return TrailSettings.ColorA end, function(c) TrailSettings.ColorA = c end)
local trailRowB = extraColorInput(tabFrames.Visuals, "Trail Color B", function() return TrailSettings.ColorB end, function(c) TrailSettings.ColorB = c end)
local trailRowC = extraColorInput(tabFrames.Visuals, "Trail Color C", function() return TrailSettings.ColorC end, function(c) TrailSettings.ColorC = c end)
updateTrailVis = function()
	trailRowA.Visible = (TrailSettings.Mode ~= "Rainbow")
	trailRowB.Visible = (TrailSettings.Mode == "TwoWay" or TrailSettings.Mode == "ThreeWay")
	trailRowC.Visible = (TrailSettings.Mode == "ThreeWay")
end
updateTrailVis()
extraSlider(tabFrames.Visuals, "Trail Length", 0.1, 5, 1, nil,
	function() return TrailSettings.Length end,
	function(v) TrailSettings.Length = v rebuildTrails() end,
	function(v) return string.format("%.1f", v) .. "s" end)
extraSlider(tabFrames.Visuals, "Trail Fade Speed", 0.2, 10, 1, nil,
	function() return TrailSettings.FadeSpeed end,
	function(v) TrailSettings.FadeSpeed = v rebuildTrails() end,
	function(v) return string.format("%.1f", v) end)
extraSlider(tabFrames.Visuals, "Trail Color Speed", 0.1, 10, 1, nil,
	function() return TrailSettings.ColorSpeed end,
	function(v) TrailSettings.ColorSpeed = v end,
	function(v) return string.format("%.1f", v) end)
extraSlider(tabFrames.Visuals, "Aspect Horizontal", 10, 100, 0, 100,
	function() return VisualSettings.AspectH end,
	function(v) VisualSettings.AspectH = v updateAspectLoop() end,
	function(v) return v .. "%" end)
extraSlider(tabFrames.Visuals, "Aspect Vertical", 10, 100, 0, 100,
	function() return VisualSettings.AspectV end,
	function(v) VisualSettings.AspectV = v updateAspectLoop() end,
	function(v) return v .. "%" end)
visToggles.WorldColor = extraToggle(tabFrames.Visuals, "World Color", false, function(on)
	worldColorEff.Enabled = on
end)
extraColorInput(tabFrames.Visuals, "World Color", function() return WorldColorVal end, function(c)
    WorldColorVal = c
    applyWorldColor()
end)
extraSlider(tabFrames.Visuals, "World Color Strength", 0, 100, 0, 100,
    function() return WorldColorStrength end,
    function(v) WorldColorStrength = v applyWorldColor() end,
    function(v) return v .. "%" end)
extraSlider(tabFrames.Visuals, "Depth of Field", 0, 200, 0, 0,
	function() return VisualSettings.DoF end,
	function(v) VisualSettings.DoF = v dofEff.Enabled = v > 0 dofEff.FarIntensity = v / 100 dofEff.NearIntensity = v / 200 end,
	function(v) return tostring(v) end)
extraSlider(tabFrames.Visuals, "Saturation", 0, 200, 0, 100,
	function() return VisualSettings.Saturation end,
	function(v) VisualSettings.Saturation = v ccEff.Saturation = (v - 100) / 100 end,
	function(v) return v .. "%" end)
extraSlider(tabFrames.Visuals, "Contrast", 0, 200, 0, 100,
	function() return VisualSettings.Contrast end,
	function(v) VisualSettings.Contrast = v ccEff.Contrast = (v - 100) / 100 end,
	function(v) return v .. "%" end)

LocalPlayer.CharacterAdded:Connect(function(char)
	if TrailSettings.Enabled then
		task.wait(0.1)
		buildTrails(char)
	end
end)

RunService.Heartbeat:Connect(function(dt)
	if dofEff.Enabled then
		local cam = workspace.CurrentCamera
		local r = getMyRoot()
		if cam and r then dofEff.FocusDistance = (cam.CFrame.Position - r.Position).Magnitude end
	end
end)

Core.VisualsAPI = {
	Gather = function()
		return {
			Crosshair = (visToggles.Crosshair and visToggles.Crosshair:Get()) or (crosshairGui ~= nil),
			Fullbright = (visToggles.Fullbright and visToggles.Fullbright:Get()) or fullbrightOn,
			FOV = VisualSettings.FOV,
			AspectH = VisualSettings.AspectH,
			AspectV = VisualSettings.AspectV,

			Trails = {
				Enabled = TrailSettings.Enabled,
				Mode = TrailSettings.Mode,
				Source = TrailSettings.Source,
				ColorA = {
					math.floor(TrailSettings.ColorA.R * 255 + 0.5),
					math.floor(TrailSettings.ColorA.G * 255 + 0.5),
					math.floor(TrailSettings.ColorA.B * 255 + 0.5)
				},
				ColorB = {
					math.floor(TrailSettings.ColorB.R * 255 + 0.5),
					math.floor(TrailSettings.ColorB.G * 255 + 0.5),
					math.floor(TrailSettings.ColorB.B * 255 + 0.5)
				},
				ColorC = {
					math.floor(TrailSettings.ColorC.R * 255 + 0.5),
					math.floor(TrailSettings.ColorC.G * 255 + 0.5),
					math.floor(TrailSettings.ColorC.B * 255 + 0.5)
				},
				Length = TrailSettings.Length,
				FadeSpeed = TrailSettings.FadeSpeed,
				ColorSpeed = TrailSettings.ColorSpeed,
			},

			WorldColorEnabled = (visToggles.WorldColor and visToggles.WorldColor:Get()) or worldColorEff.Enabled,
			WorldColor = {
				math.floor(WorldColorVal.R * 255 + 0.5),
				math.floor(WorldColorVal.G * 255 + 0.5),
				math.floor(WorldColorVal.B * 255 + 0.5)
			},
			WorldColorStrength = WorldColorStrength,

			DoF = VisualSettings.DoF,
			Saturation = VisualSettings.Saturation,
			Contrast = VisualSettings.Contrast,
		}
	end,

	Apply = function(d)
		if type(d) ~= "table" then return end

		local function clampNum(v, min, max, def)
			v = tonumber(v)
			if v == nil then return def end
			return math.clamp(v, min, max)
		end

		local function colFromArr(arr, def)
			if type(arr) ~= "table" then return def end
			return Color3.fromRGB(
				math.clamp(tonumber(arr[1]) or math.floor(def.R * 255), 0, 255),
				math.clamp(tonumber(arr[2]) or math.floor(def.G * 255), 0, 255),
				math.clamp(tonumber(arr[3]) or math.floor(def.B * 255), 0, 255)
			)
		end

		VisualSettings.FOV = clampNum(d.FOV, 30, 120, 70)
		applyFOV(VisualSettings.FOV)

		VisualSettings.AspectH = clampNum(d.AspectH, 10, 100, 100)
		VisualSettings.AspectV = clampNum(d.AspectV, 10, 100, 100)
		updateAspectLoop()

		VisualSettings.DoF = clampNum(d.DoF, 0, 200, 0)
		dofEff.Enabled = VisualSettings.DoF > 0
		dofEff.FarIntensity = VisualSettings.DoF / 100
		dofEff.NearIntensity = VisualSettings.DoF / 200

		VisualSettings.Saturation = clampNum(d.Saturation, 0, 200, 100)
		ccEff.Saturation = (VisualSettings.Saturation - 100) / 100

		VisualSettings.Contrast = clampNum(d.Contrast, 0, 200, 100)
		ccEff.Contrast = (VisualSettings.Contrast - 100) / 100

		if type(d.Trails) == "table" then
			local t = d.Trails

			TrailSettings.Enabled = t.Enabled and true or false

			if t.Mode == "Solid" or t.Mode == "TwoWay" or t.Mode == "ThreeWay" or t.Mode == "Rainbow" then
				TrailSettings.Mode = t.Mode
			end

			if t.Source == "All" or t.Source == "Body" or t.Source == "Arms" or t.Source == "Legs" or t.Source == "Legs+Arms" then
				TrailSettings.Source = t.Source
			end

			TrailSettings.ColorA = colFromArr(t.ColorA, Color3.fromRGB(255, 255, 255))
			TrailSettings.ColorB = colFromArr(t.ColorB, Color3.fromRGB(80, 255, 120))
			TrailSettings.ColorC = colFromArr(t.ColorC, Color3.fromRGB(255, 170, 0))

			TrailSettings.Length = clampNum(t.Length, 0.1, 5, 0.6)
			TrailSettings.FadeSpeed = clampNum(t.FadeSpeed, 0.2, 10, 1)
			TrailSettings.ColorSpeed = clampNum(t.ColorSpeed, 0.1, 10, 1)

			if trailModeBtn then
				trailModeBtn.Text = "Trail Color Mode: " .. TrailSettings.Mode
			end
		end

		if d.Crosshair ~= nil then
			if visToggles.Crosshair then
				visToggles.Crosshair:Set(d.Crosshair and true or false)
			else
				setCrosshair(d.Crosshair and true or false)
			end
		end

		if d.Fullbright ~= nil then
			if visToggles.Fullbright then
				visToggles.Fullbright:Set(d.Fullbright and true or false)
			else
				setFullbright(d.Fullbright and true or false)
			end
		end

		if type(d.WorldColor) == "table" then
			WorldColorVal = colFromArr(d.WorldColor, Color3.fromRGB(255, 255, 255))
		end

		if d.WorldColorStrength ~= nil then
			WorldColorStrength = clampNum(d.WorldColorStrength, 0, 100, 100)
		end

		applyWorldColor()

		if d.WorldColorEnabled ~= nil then
			if visToggles.WorldColor then
				visToggles.WorldColor:Set(d.WorldColorEnabled and true or false)
			else
				worldColorEff.Enabled = d.WorldColorEnabled and true or false
			end
		end

		if type(d.Trails) == "table" then
			if visToggles.Trails then
				visToggles.Trails:Set(TrailSettings.Enabled)
			else
				rebuildTrails()
			end
		end

		if updateTrailVis then
			updateTrailVis()
		end
	end,

	Reset = function()
		VisualSettings.FOV = 70
		VisualSettings.DoF = 0
		VisualSettings.Saturation = 100
		VisualSettings.Contrast = 100
		VisualSettings.AspectH = 100
		VisualSettings.AspectV = 100

		applyFOV(70)
		updateAspectLoop()

		dofEff.Enabled = false
		dofEff.FarIntensity = 0
		dofEff.NearIntensity = 0

		ccEff.Saturation = 0
		ccEff.Contrast = 0

		TrailSettings.Enabled = false
		TrailSettings.Mode = "Solid"
		TrailSettings.Source = "All"
		TrailSettings.ColorA = Color3.fromRGB(255, 255, 255)
		TrailSettings.ColorB = Color3.fromRGB(80, 255, 120)
		TrailSettings.ColorC = Color3.fromRGB(255, 170, 0)
		TrailSettings.Length = 0.6
		TrailSettings.FadeSpeed = 1
		TrailSettings.ColorSpeed = 1

		if trailModeBtn then
			trailModeBtn.Text = "Trail Color Mode: Solid"
		end

		if visToggles.Crosshair then
			visToggles.Crosshair:Set(false)
		else
			setCrosshair(false)
		end

		if visToggles.Fullbright then
			visToggles.Fullbright:Set(false)
		else
			setFullbright(false)
		end

		if visToggles.Trails then
			visToggles.Trails:Set(false)
		else
			rebuildTrails()
		end

		WorldColorVal = Color3.fromRGB(255, 255, 255)
		WorldColorStrength = 100
		applyWorldColor()

		if visToggles.WorldColor then
			visToggles.WorldColor:Set(false)
		else
			worldColorEff.Enabled = false
		end

		if updateTrailVis then
			updateTrailVis()
		end
	    end,
    Shutdown = function()
        pcall(function()
            if visToggles.Crosshair then
                visToggles.Crosshair.State = false
                setCrosshair(false)
            end

            if visToggles.Fullbright then
                visToggles.Fullbright.State = false
                setFullbright(false)
            end

            if visToggles.Trails then
                visToggles.Trails.State = false
                TrailSettings.Enabled = false
                rebuildTrails()
            end

            if visToggles.WorldColor then
                visToggles.WorldColor.State = false
                worldColorEff.Enabled = false
            end

            dofEff.Enabled = false
            ccEff.Saturation = 0
            ccEff.Contrast = 0

            if aspectConn then
                aspectConn:Disconnect()
                aspectConn = nil
            end

            pcall(function()
                workspace.CurrentCamera.FieldOfView = 70
            end)
        end)
    end
}


ScreenGui.Destroying:Connect(function()
pcall(function()
if Core.VisualsAPI and Core.VisualsAPI.Reset then
Core.VisualsAPI.Reset()
end
end)
end)
end -- конец блока VISUALS

do -- UTILITIES + SERVER

------------------------------------------------------------
-- 4) UTILITIES
------------------------------------------------------------
local function serverHop()
	notify("Server Hop", "Searching for a new server...")
	local ok, res = pcall(function()
		return game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
	end)
	if not ok then notify("Server Hop", "Failed to get server list") return end
	local ok2, data = pcall(function() return HttpService:JSONDecode(res) end)
	if not ok2 or type(data) ~= "table" or type(data.data) ~= "table" then
		notify("Server Hop", "Failed to parse server list")
		return
	end
	local candidates = {}
	for _, s in ipairs(data.data) do
		if s.id and s.id ~= game.JobId and type(s.playing) == "number" and s.playing < (s.maxPlayers or 999) then
			table.insert(candidates, s.id)
		end
	end
	if #candidates == 0 then notify("Server Hop", "No other servers found") return end
	local pick = candidates[math.random(1, #candidates)]
	local ok3, err = pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, pick, LocalPlayer)
	end)
	if not ok3 then notify("Server Hop", "Teleport failed: " .. tostring(err)) end
end

local function rejoin()
	notify("Rejoin", "Rejoining...")
	pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
	task.wait(0.5)
	pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
end

createSection(tabFrames.Utilities, "Utilities")
createContentButton(tabFrames.Utilities, "Server Hop", serverHop)
createContentButton(tabFrames.Utilities, "Rejoin", rejoin)

------------------------------------------------------------
-- 5) SERVER
------------------------------------------------------------
local sessionStart = os.clock()
local sessionDeaths = 0
local sessionWalked = 0
local lastRootPos = nil

local function fmtHMS(sec)
	sec = math.floor(sec)
	return string.format("%02d:%02d:%02d", math.floor(sec / 3600), math.floor((sec % 3600) / 60), sec % 60)
end

local function getServerUptime()
	local ok, t = pcall(function()
		return workspace.DistributedGameTime
	end)

	if ok and typeof(t) == "number" and t >= 0 then
		return t
	end

	return os.clock() - sessionStart
end

createSection(tabFrames.Server, "This Server")
local srvPlaceL = createLabel(tabFrames.Server, "Place: " .. game.PlaceId)
local srvJobL = createLabel(tabFrames.Server, "Job: " .. (game.JobId ~= "" and game.JobId or "none"))
local srvUsersL = createLabel(tabFrames.Server, "Users: --")
local srvUptimeL = createLabel(tabFrames.Server, "Uptime: 00:00:00")
local srvPingL = createLabel(tabFrames.Server, "Ping: --")
createSection(tabFrames.Server, "Session")
local sesPlayL = createLabel(tabFrames.Server, "Playtime: 00:00:00")
local sesDeathsL = createLabel(tabFrames.Server, "Deaths: 0")
local sesWalkL = createLabel(tabFrames.Server, "Walked: 0 studs")

task.spawn(function()
	local ok, info = pcall(function() return Marketplace:GetProductInfo(game.PlaceId) end)
	if ok and info and info.Name then
		srvPlaceL.Text = "Place: " .. game.PlaceId .. " (" .. info.Name .. ")"
	end
end)

local function hookSessionChar(char)
	local h = char:WaitForChild("Humanoid", 5)
	if h then
		h.Died:Connect(function() sessionDeaths = sessionDeaths + 1 end)
	end
end
LocalPlayer.CharacterAdded:Connect(hookSessionChar)
if LocalPlayer.Character then hookSessionChar(LocalPlayer.Character) end

RunService.Heartbeat:Connect(function()
	local r = getMyRoot()
	if r then
		if lastRootPos then
			local d = (r.Position - lastRootPos).Magnitude
			if d < 50 then sessionWalked = sessionWalked + d end
		end
		lastRootPos = r.Position
	else
		lastRootPos = nil
	end
end)

task.spawn(function()
	while true do
		task.wait(1)
		pcall(function()
			srvUsersL.Text = "Users: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers
			srvPingL.Text = "Ping: " .. math.floor(StatsService.PerformanceStats.Ping:GetValue()) .. " ms"
			srvUptimeL.Text = "Uptime: " .. fmtHMS(getServerUptime())
			sesPlayL.Text = "Playtime: " .. fmtHMS(os.clock() - sessionStart)
			sesDeathsL.Text = "Deaths: " .. sessionDeaths
			sesWalkL.Text = "Walked: " .. math.floor(sessionWalked) .. " studs"
		end)
	end
end)
registerKeyListProvider("EmilyUi", function()
	local rows = {}
	if CharSettings.Speed ~= 16 then table.insert(rows, {"SPEED", tostring(CharSettings.Speed)}) end
	if CharSettings.Jump ~= 50 then table.insert(rows, {"JUMP", tostring(CharSettings.Jump)}) end
	if math.abs(CharSettings.Gravity - 196.2) > 0.05 then table.insert(rows, {"GRAVITY", string.format("%.1f", CharSettings.Gravity)}) end
	if visToggles.Crosshair and visToggles.Crosshair:Get() then table.insert(rows, {"CROSSHAIR", "ON"}) end
	if VisualSettings.FOV ~= 70 then table.insert(rows, {"FOV", tostring(VisualSettings.FOV)}) end
	if visToggles.Fullbright and visToggles.Fullbright:Get() then table.insert(rows, {"FULLBRIGHT", "ON"}) end
	if visToggles.Trails and visToggles.Trails:Get() then table.insert(rows, {"TRAILS", "ON"}) end
	if visToggles.WorldColor and visToggles.WorldColor:Get() then table.insert(rows, {"WORLD COLOR", "ON"}) end
	return rows
end)
end -- конец блока UTILITIES + SERVER
end -- конец большого do-блока
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
        TextBoxColor = {uiColor_TextBoxColor.R, uiColor_TextBoxColor.G, uiColor_TextBoxColor.B},
        ToggleOnColor = {uiColor_ToggleOnText.R, uiColor_ToggleOnText.G, uiColor_ToggleOnText.B},
        ToggleOffColor = {uiColor_ToggleOffText.R, uiColor_ToggleOffText.G, uiColor_ToggleOffText.B},
    }
    if Core.VisualsAPI and Core.VisualsAPI.Gather then
	    cfg.Visuals = Core.VisualsAPI.Gather()
    end

    if Core.AimAPI and Core.AimAPI.Gather then
	    cfg.Aim = Core.AimAPI.Gather()
    end

    if Core.MovementAPI and Core.MovementAPI.Gather then
	    cfg.Movement = Core.MovementAPI.Gather()
    end

    if Core.KeyListAPI and Core.KeyListAPI.Gather then
	    cfg.KeyList = Core.KeyListAPI.Gather()
    end

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
    if cfg.ToggleOnColor then uiColor_ToggleOnText = Color3.new(unpack(cfg.ToggleOnColor)) end
	if cfg.ToggleOffColor then uiColor_ToggleOffText = Color3.new(unpack(cfg.ToggleOffColor)) end
	applyTheme()
	if unlocked then
	    if cfg.Visuals and Core.VisualsAPI and Core.VisualsAPI.Apply then
		    Core.VisualsAPI.Apply(cfg.Visuals)
	    end

	    if cfg.Aim and Core.AimAPI and Core.AimAPI.Apply then
		    Core.AimAPI.Apply(cfg.Aim)
	    end

	    if cfg.Movement and Core.MovementAPI and Core.MovementAPI.Apply then
		    Core.MovementAPI.Apply(cfg.Movement)
	    end
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

local function saveLastNamedConfigSilent()
    if not filesSupported() then return end

    local name = getLastConfigName()
    if not name or name == "" then return end

    pcall(function()
        if not isfolder("EmilyUi/FuckYou") then makefolder("EmilyUi/FuckYou") end
        if not isfolder(configFolder) then makefolder(configFolder) end
    end)

    local ok, json = pcall(function()
        return HttpService:JSONEncode(gatherConfig())
    end)

    if ok and json then
        pcall(function()
            writefile(configFolder .. "/" .. name .. ".json", json)
        end)
    end
end

registerConfigSaveListener(saveLastNamedConfigSilent)

ScreenGui.Destroying:Connect(function()
    if unlocked then
        autoSaveConfig(true)
    end
end)

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
    uiColor_ToggleOnText = Color3.fromRGB(100, 255, 100)
	uiColor_ToggleOffText = Color3.fromRGB(255, 100, 100)
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
	if Core.AimAPI and Core.AimAPI.Reset then Core.AimAPI.Reset() end

    if Core.VisualsAPI and Core.VisualsAPI.Reset then
	    Core.VisualsAPI.Reset()
    end

    if Core.MovementAPI and Core.MovementAPI.Reset then
	    Core.MovementAPI.Reset()
    end

    if Core.KeyListAPI and Core.KeyListAPI.Reset then Core.KeyListAPI.Reset() end
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
	{Frame = tabFrames.Character, Name = "Character"},
	{Frame = tabFrames.Players, Name = "Players"},
	{Frame = tabFrames.Visuals, Name = "Visuals"},
	{Frame = tabFrames.Utilities, Name = "Utilities"},
	{Frame = tabFrames.Server, Name = "Server"},
	{Frame = tabFrames.Games, Name = "Games"},
	{Frame = tabFrames.Scripts, Name = "Scripts"},
	{Frame = tabFrames.Hubs, Name = "Script Hubs"},
	{Frame = tabFrames.Guis, Name = "GUIs"},
	{Frame = tabFrames.Anims, Name = "Animations"},
    {Frame = tabFrames.KeyList, Name = "Key List"},
	{Frame = tabFrames.Settings, Name = "Settings"}
}
Core.tabs=tabs
Core.RegisterModule("EmilyUi",Core.SideButtons.EmilyUi,tabs,tabs[1])

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

Core.GetLastConfigName=getLastConfigName
Core.LoadNamedConfig=loadNamedConfig
Core.GatherNamedConfig=gatherConfig

Core.SideButtons.EmilyUi=Core.SideButtons.EmilyUi

Core._UpdateProfilePanel=updateProfilePanel
