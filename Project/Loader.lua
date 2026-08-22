--// Loader.lua
-- Инициализация библиотеки (как запрошено)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/MamaSdoxla/EmilyUiRaw/refs/heads/main/Project/Library.lua"))()

--// Сервисы
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

--// Конфигурация и стили FuckYou
local COL_BG = Color3.fromRGB(12, 12, 12)
local COL_BORDER = Color3.fromRGB(22, 22, 22)
local COL_TEXT = Color3.fromRGB(139, 135, 127)
local FONT = Enum.Font.SpecialElite

--// Переменные состояния UI
local currentToggleKey = Enum.KeyCode.P
local isHidden = false
local isCollapsed = false
local unlocked = false

-- ==========================================
-- 1. СИСТЕМА КЛЮЧЕЙ (Key System)
-- ==========================================
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
	if not day or not month or not year then return 0 end
	local expireTime = os.time({day = tonumber(day), month = tonumber(month), year = tonumber(year), hour = 0, min = 0, sec = 0})
	local diff = expireTime - os.time()
	return diff <= 0 and 0 or diff / 86400
end

local function createNotification(title, text)
	-- Простое уведомление Roblox
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = title, Text = text, Duration = 5
		})
	end)
end

local function checkKeySystem()
	local success, response = pcall(function()
		return game:HttpGet("https://raw.githubusercontent.com/MamaSdoxla/EmilyUi/refs/heads/main/nuh-uh.json")
	end)
	
	if not success or not response or #response < 10 then
		createNotification("Error", "Failed to fetch key database!")
		return
	end

	local ok, decryptedText = pcall(function() return decryptData(response, SECRET_KEY) end)
	if not ok or not decryptedText then
		createNotification("Error", "Failed to decrypt key database!")
		return
	end

	local jsonSuccess, keysList = pcall(function() return HttpService:JSONDecode(decryptedText) end)
	if not jsonSuccess or type(keysList) ~= "table" then
		createNotification("Error", "Database parsing failed!")
		return
	end

	local myName = string.lower(LocalPlayer.Name)
	
	-- Проверка ключей
	for _, data in ipairs(keysList) do
		if data.key and data.robloxName and data.group and data.timeTillWorks then
			local nameMatch = (data.robloxName == "none") or (string.lower(data.robloxName) == myName)
			local groupAllowed = string.lower(data.group) == "free" or string.lower(data.group) == "user" or string.lower(data.group) == "tester" or string.lower(data.group) == "coder"
			
			if nameMatch and groupAllowed then
				local daysLeft = getKeyDaysLeft(data.timeTillWorks)
				if daysLeft == "Infinity" or (type(daysLeft) == "number" and daysLeft > 0) then
					-- Ключ найден и валиден
					unlocked = true
					createNotification("Success", "Welcome! Role: " .. data.group)
					loadUI() -- Загружаем интерфейс
					return
				end
			end
		end
	end
	
	-- Если ключ не найден, показываем окно ввода (упрощенно через уведомление или можно расширить до GUI)
	createNotification("Access Denied", "Invalid or expired key. Join Discord to get one.")
end

-- ==========================================
-- 2. СОЗДАНИЕ FUCKYOU GUI
-- ==========================================
function loadUI()
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "FuckYouGui"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.IgnoreGuiInset = true
	ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

	-- Главное окно
	local FuckYou = Instance.new("Frame")
	FuckYou.Name = "FuckYou"
	FuckYou.Parent = ScreenGui
	FuckYou.AnchorPoint = Vector2.new(0.5, 0.5)
	FuckYou.Position = UDim2.new(0.5, 0, 0.5, 0)
	FuckYou.Size = UDim2.new(0, 940, 0, 510)
	FuckYou.BackgroundColor3 = COL_BG
	FuckYou.BorderColor3 = COL_BORDER
	FuckYou.BorderSizePixel = 1
	FuckYou.Visible = true

	-- Верхняя панель (TopBar)
	local TopBar = Instance.new("Frame")
	TopBar.Name = "TopBar"
	TopBar.Parent = FuckYou
	TopBar.Size = UDim2.new(1, 0, 0, 45)
	TopBar.BackgroundColor3 = COL_BG
	TopBar.BorderSizePixel = 0

	local Title = Instance.new("TextLabel")
	Title.Parent = TopBar
	Title.Size = UDim2.new(1, -135, 1, 0)
	Title.Position = UDim2.new(0, 10, 0, 0)
	Title.BackgroundTransparency = 1
	Title.Text = "Fuck you! v1.2"
	Title.TextColor3 = COL_TEXT
	Title.TextSize = 14
	Title.Font = FONT
	Title.TextXAlignment = Enum.TextXAlignment.Left

	-- Функция создания кнопок в правом верхнем углу
	local function makeTopBtn(symbol, offset, colorOverride)
		local btn = Instance.new("TextButton")
		btn.Parent = TopBar
		btn.Position = UDim2.new(1, -45 * offset, 0, 0)
		btn.Size = UDim2.new(0, 45, 0, 45)
		btn.BackgroundColor3 = colorOverride or COL_BG
		btn.BorderColor3 = COL_BORDER
		btn.Text = symbol
		btn.TextColor3 = colorOverride and Color3.fromRGB(255,255,255) or COL_TEXT
		btn.TextSize = 16
		btn.Font = FONT
		
		btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = colorOverride or Color3.fromRGB(30, 30, 30)
		end)
		btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = colorOverride or COL_BG
		end)
		return btn
	end

	-- Кнопки управления окном
	local MinusBtn = makeTopBtn("-", 3)
	local EqualBtn = makeTopBtn("=", 2)
	local XBtn = makeTopBtn("X", 1, Color3.fromRGB(150, 40, 40))

	-- Логика кнопок
	XBtn.MouseButton1Click:Connect(function()
		ScreenGui:Destroy()
	end)

	EqualBtn.MouseButton1Click:Connect(function()
		if not isCollapsed then
			isCollapsed = true
			FuckYou.Size = UDim2.new(0, 940, 0, 45) -- Свернуть до полоски
		else
			isCollapsed = false
			FuckYou.Size = UDim2.new(0, 940, 0, 510) -- Развернуть
		end
	end)

	MinusBtn.MouseButton1Click:Connect(function()
		isHidden = true
		FuckYou.Visible = false
	end)

	-- Глобальный бинд для разворачивания из скрытого состояния (из Settings)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == currentToggleKey and isHidden then
			isHidden = false
			FuckYou.Visible = true
			isCollapsed = false
			FuckYou.Size = UDim2.new(0, 940, 0, 510)
		end
	end)

	-- Боковая панель (SideBar)
	local SideBar = Instance.new("Frame")
	SideBar.Name = "SideBar"
	SideBar.Parent = FuckYou
	SideBar.Position = UDim2.new(0, 0, 0, 45)
	SideBar.Size = UDim2.new(0, 65, 1, -45)
	SideBar.BackgroundColor3 = COL_BG
	SideBar.BorderSizePixel = 0

	local function makeSideBtn(text, offsetY)
		local btn = Instance.new("TextButton")
		btn.Parent = SideBar
		btn.Position = UDim2.new(0, 0, 0, offsetY)
		btn.Size = UDim2.new(1, 0, 0, 59)
		btn.BackgroundColor3 = COL_BG
		btn.BorderColor3 = COL_BORDER
		btn.Text = text
		btn.TextColor3 = COL_TEXT
		btn.TextSize = 12
		btn.Font = FONT
		
		btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(30,30,30) end)
		btn.MouseLeave:Connect(function() btn.BackgroundColor3 = COL_BG end)
		return btn
	end

	-- Запрошенная боковая кнопка "Ui"
	local UiBtn = makeSideBtn("Ui", 0)

	-- Контейнер для вкладок внутри "Ui"
	local MenuInsided = Instance.new("ScrollingFrame")
	MenuInsided.Name = "MenuInsided"
	MenuInsided.Parent = FuckYou
	MenuInsided.Position = UDim2.new(0, 65, 0, 45)
	MenuInsided.Size = UDim2.new(0, 105, 1, -45)
	MenuInsided.BackgroundColor3 = COL_BG
	MenuInsided.BorderSizePixel = 0
	MenuInsided.ScrollBarThickness = 3
	MenuInsided.Visible = false -- Скрыто по умолчанию, пока не нажата "Ui"

	local menuLayout = Instance.new("UIListLayout")
	menuLayout.Parent = MenuInsided
	menuLayout.SortOrder = Enum.SortOrder.LayoutOrder
	menuLayout.Padding = UDim.new(0, 4)

	-- Контентная область
	local Containment = Instance.new("Frame")
	Containment.Name = "Containment"
	Containment.Parent = FuckYou
	Containment.Position = UDim2.new(0, 170, 0, 45)
	Containment.Size = UDim2.new(1, -170, 1, -45)
	Containment.BackgroundTransparency = 1
	Containment.BorderSizePixel = 0

	-- Вкладки
	local tabs = {}
	local function createTabFrame(name)
		local frame = Instance.new("ScrollingFrame")
		frame.Name = name
		frame.Parent = Containment
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundTransparency = 1
		frame.BorderSizePixel = 0
		frame.Visible = false
		frame.ScrollBarThickness = 4
		
		local layout = Instance.new("UIListLayout")
		layout.Parent = frame
		layout.Padding = UDim.new(0, 6)
		Instance.new("UIPadding", {Parent = frame, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10)})
		
		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			frame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
		end)
		return frame
	end

	local tabFrames = {
		MainInfo = createTabFrame("MainInfo"),
		Settings = createTabFrame("Settings")
	}

	-- Логика переключения вкладок
	local function switchTab(targetTab)
		for _, frame in pairs(tabFrames) do
			frame.Visible = (frame == targetTab)
		end
		-- Подсветка кнопок (упрощенно)
		for _, child in ipairs(MenuInsided:GetChildren()) do
			if child:IsA("TextButton") then
				child.TextColor3 = (child.Name == targetTab.Name .. "Btn") and Color3.fromRGB(255,255,255) or COL_TEXT
			end
		end
	end

	local function addMenuButton(text, targetTab)
		local btn = Instance.new("TextButton")
		btn.Name = targetTab.Name .. "Btn"
		btn.Parent = MenuInsided
		btn.Size = UDim2.new(1, 0, 0, 30)
		btn.BackgroundColor3 = COL_BG
		btn.Text = text
		btn.TextColor3 = COL_TEXT
		btn.Font = FONT
		btn.TextSize = 12
		btn.MouseButton1Click:Connect(function()
			switchTab(targetTab)
		end)
	end

	addMenuButton("Main info", tabFrames.MainInfo)
	addMenuButton("Settings", tabFrames.Settings)

	-- Открытие меню при нажатии на "Ui"
	UiBtn.MouseButton1Click:Connect(function()
		MenuInsided.Visible = not MenuInsided.Visible
		if MenuInsided.Visible and not tabFrames.MainInfo.Visible and not tabFrames.Settings.Visible then
			switchTab(tabFrames.MainInfo)
		end
	end)

	-- ==========================================
	-- 3. НАПОЛНЕНИЕ ВКЛАДОК
	-- ==========================================
	
	-- Вкладка Main info
	local infoLabel = Instance.new("TextLabel")
	infoLabel.Parent = tabFrames.MainInfo
	infoLabel.Size = UDim2.new(1, -20, 0, 100)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = "Welcome to FuckYou Gui!\n\nThis UI is loaded via Loader.lua.\nUse the 'Ui' tab to configure settings."
	infoLabel.TextColor3 = COL_TEXT
	infoLabel.Font = FONT
	infoLabel.TextSize = 14
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.TextYAlignment = Enum.TextYAlignment.Top

	-- Вкладка Settings
	local settingsHeader = Instance.new("TextLabel")
	settingsHeader.Parent = tabFrames.Settings
	settingsHeader.Size = UDim2.new(1, -20, 0, 30)
	settingsHeader.BackgroundTransparency = 1
	settingsHeader.Text = "UI Settings"
	settingsHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
	settingsHeader.Font = FONT
	settingsHeader.TextSize = 16
	settingsHeader.TextXAlignment = Enum.TextXAlignment.Left

	local keyBindBtn = Instance.new("TextButton")
	keyBindBtn.Parent = tabFrames.Settings
	keyBindBtn.Size = UDim2.new(1, -20, 0, 36)
	keyBindBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	keyBindBtn.BorderColor3 = COL_BORDER
	keyBindBtn.Text = "Toggle UI Key: [" .. currentToggleKey.Name .. "]"
	keyBindBtn.TextColor3 = COL_TEXT
	keyBindBtn.Font = FONT
	keyBindBtn.TextSize = 13

	local listeningForKey = false
	keyBindBtn.MouseButton1Click:Connect(function()
		if listeningForKey then return end
		listeningForKey = true
		keyBindBtn.Text = "Press any key..."
		
		local conn
		conn = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				currentToggleKey = input.KeyCode
				keyBindBtn.Text = "Toggle UI Key: [" .. currentToggleKey.Name .. "]"
				listeningForKey = false
				conn:Disconnect()
				createNotification("Settings", "Toggle key updated to: " .. currentToggleKey.Name)
			end
		end)
		
		-- Таймаут на случай, если пользователь передумал
		task.delay(5, function()
			if listeningForKey then
				listeningForKey = false
				keyBindBtn.Text = "Toggle UI Key: [" .. currentToggleKey.Name .. "]"
				conn:Disconnect()
			end
		end)
	end)

	-- Делаем главное окно перетаскиваемым (Draggable)
	local dragging, dragInput, dragStart, startPosition
	TopBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPosition = FuckYou.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	TopBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then 
			dragInput = input 
		end
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

	-- Инициализация: открываем первую вкладку
	switchTab(tabFrames.MainInfo)
end

-- ==========================================
-- 4. ЗАПУСК
-- ==========================================
-- Проверяем ключ при загрузке. Если успешно, вызывается loadUI()
checkKeySystem()