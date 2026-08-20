---@diagnostic disable: undefined-global
if not game:GetService("Players").LocalPlayer then
	game:GetService("Players"):GetPropertyChangedSignal("LocalPlayer"):Wait()
end
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- ПУТИ К ФАЙЛАМ
local FOLDER_PATH = "EmilyUi/Animator"
local FILE_DESYNC = FOLDER_PATH .. "/animations_saved.json"
local FILE_R6 = FOLDER_PATH .. "/AnimationManagerJsonR6.json"
local FILE_R15 = FOLDER_PATH .. "/AnimationManagerJsonR15.json"
local KEYBINDS_FILE = FOLDER_PATH .. "/keybinds.json"

local function getDefaultStructure()
	return { _subcategories = {} }
end

local function ensureDirectories()
	if makefolder then
		pcall(function()
			if not isfolder("EmilyUi") then makefolder("EmilyUi") end
			if not isfolder(FOLDER_PATH) then makefolder(FOLDER_PATH) end
		end)
	end
end

local function loadManagerData(mode)
	local filePath = (mode == "R6") and FILE_R6 or FILE_R15
	if isfile and isfile(filePath) then
		local status, result = pcall(function()
			return HttpService:JSONDecode(readfile(filePath))
		end)
		if status and type(result) == "table" then
			if not result._subcategories then result._subcategories = {} end
			return result
		end
	end
	return getDefaultStructure()
end

local function saveManagerData(mode, data)
	if writefile then
		ensureDirectories()
		local filePath = (mode == "R6") and FILE_R6 or FILE_R15
		pcall(function()
			writefile(filePath, HttpService:JSONEncode(data))
		end)
	end
end

local function loadDesyncAnimations()
	if isfile and isfile(FILE_DESYNC) then
		local status, result = pcall(function()
			return HttpService:JSONDecode(readfile(FILE_DESYNC))
		end)
		if status and type(result) == "table" then
			return result
		end
	end
	return {}
end

local function saveDesyncAnimations(data)
	if writefile then
		ensureDirectories()
		pcall(function()
			writefile(FILE_DESYNC, HttpService:JSONEncode(data))
		end)
	end
end

local function loadKeybinds()
	local binds = {}
	if isfile and isfile(KEYBINDS_FILE) then
		local status, result = pcall(function()
			return HttpService:JSONDecode(readfile(KEYBINDS_FILE))
		end)
		if status and type(result) == "table" then
			binds = result
		end
	end
	if not binds.Animations then binds.Animations = {} end
	if binds.Animations and not binds.Animations[1] then
		local oldAnims = binds.Animations
		binds.Animations = {}
		if oldAnims.Desync and oldAnims.Desync.key then
			table.insert(binds.Animations, {
				key = oldAnims.Desync.key,
				type = "Desync",
				animName = oldAnims.Desync.animName,
				speed = oldAnims.Desync.speed or 1.0,
				looped = oldAnims.Desync.looped or false,
				reversed = oldAnims.Desync.reversed or false
			})
		end
		if oldAnims.Normal and oldAnims.Normal.key then
			table.insert(binds.Animations, {
				key = oldAnims.Normal.key,
				type = "Normal",
				animName = oldAnims.Normal.animName,
				bodyType = oldAnims.Normal.bodyType or "R6",
				speed = oldAnims.Normal.speed or 1.0,
				looped = oldAnims.Normal.looped or false,
				reversed = oldAnims.Normal.reversed or false
			})
		end
	end
	return binds
end

local function saveKeybinds(data)
	if writefile then
		ensureDirectories()
		pcall(function()
			writefile(KEYBINDS_FILE, HttpService:JSONEncode(data))
		end)
	end
end

local savedDesyncAnimations = loadDesyncAnimations()
local managerDataCache = {
	R6 = loadManagerData("R6"),
	R15 = loadManagerData("R15")
}
local keybinds = loadKeybinds()

local lp = Players.LocalPlayer
local h = RunService.Heartbeat

-- ======================== DESYNC VARIABLES ========================
local OffsetPos = Vector3.new(0, 0, 0)
local OffsetRot = Vector3.new(0, 0, 0)
local isRunning = true
local animationPlaying = false
local IsDesynced = false
local DesyncLoop = nil
local VisualChar = nil
local CharDeathConn = nil
local realCF = CFrame.new()
local partMap = {}
local RENDER_NAME = "DesyncPreCamera"

local interceptedIdText = "Waiting for animation..."
local c = lp.Character or lp.CharacterAdded:Wait()

local DesyncToggleBtn
local OrientationInput, PositionInput
local ReloadBtn

local function ParseVector3(str)
	local parts = string.split(string.gsub(str, " ", ""), ",")
	local x = tonumber(parts[1]) or 0
	local y = tonumber(parts[2]) or 0
	local z = tonumber(parts[3]) or 0
	return Vector3.new(x, y, z)
end

local function BuildPartMap(orig, vis, map)
	for _, child in ipairs(orig:GetChildren()) do
		local visChild = vis:FindFirstChild(child.Name)
		if visChild then
			if child:IsA("BasePart") and visChild:IsA("BasePart") then
				map[child] = visChild
			end
			BuildPartMap(child, visChild, map)
		end
	end
end

local function StopDesync()
	IsDesynced = false
	if DesyncToggleBtn then
		DesyncToggleBtn.Text = "Desync: OFF"
		DesyncToggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
	end

	OffsetPos = Vector3.new(0, 0, 0)
	OffsetRot = Vector3.new(0, 0, 0)
	if OrientationInput then OrientationInput.Text = "0,0,0" end
	if PositionInput then PositionInput.Text = "0,0,0" end

	if DesyncLoop then
		DesyncLoop:Disconnect()
		DesyncLoop = nil
	end

	pcall(function()
		RunService:UnbindFromRenderStep(RENDER_NAME)
	end)

	if VisualChar then
		VisualChar:Destroy()
		VisualChar = nil
	end

	table.clear(partMap)
end

local function StartDesync()
	if IsDesynced then StopDesync() end

	local char = lp.Character
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	-- Создание прозрачной копии (фантом)
	char.Archivable = true
	VisualChar = char:Clone()

	for _, v in pairs(VisualChar:GetDescendants()) do
		if v:IsA("Script") or v:IsA("LocalScript") then
			v:Destroy()
		elseif v:IsA("BasePart") then
			v.CanCollide = false
			v.CastShadow = false
			v.Anchored = true
			if v.Transparency < 0.5 then
				v.Transparency = 0.5
			end
		elseif v:IsA("Humanoid") then
			v.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			v.PlatformStand = true
			v.Name = "FakeHumanoid"
		end
	end

	if not VisualChar.PrimaryPart then
		VisualChar.PrimaryPart = VisualChar:FindFirstChild("HumanoidRootPart")
	end

	table.clear(partMap)
	BuildPartMap(char, VisualChar, partMap)

	VisualChar.Parent = workspace

	IsDesynced = true
	if DesyncToggleBtn then
		DesyncToggleBtn.Text = "Desync: ON"
		DesyncToggleBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
	end

	realCF = hrp.CFrame

	-- Heartbeat: серверная позиция + полное копирование позы
	DesyncLoop = RunService.Heartbeat:Connect(function()
		if not IsDesynced or not char or not char.Parent or not hrp or not hrp.Parent then
			StopDesync()
			return
		end

		realCF = hrp.CFrame

		local desyncCF = realCF
			* CFrame.new(OffsetPos)
			* CFrame.Angles(
				math.rad(OffsetRot.X),
				math.rad(OffsetRot.Y),
				math.rad(OffsetRot.Z)
			)

		-- 1. Сначала снимаем позу (пока всё ещё на realCF)
		local relatives = {}
		for origPart, visPart in pairs(partMap) do
			if origPart.Parent and visPart.Parent then
				relatives[origPart] = realCF:ToObjectSpace(origPart.CFrame)
			end
		end

		-- 2. Отправляем смещённый CFrame на сервер
		hrp.CFrame = desyncCF

		-- 3. Применяем сохранённые относительные CFrame к фантому
		if VisualChar and VisualChar.Parent then
			for origPart, relative in pairs(relatives) do
				local visPart = partMap[origPart]
				if visPart and visPart.Parent then
					visPart.CFrame = desyncCF * relative
				end
			end
		end
	end)

	-- Сброс CFrame ДО обновления камеры
	RunService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.Camera.Value - 1, function()
		if not IsDesynced or not hrp or not hrp.Parent then return end

		hrp.CFrame = realCF

		local cam = workspace.CurrentCamera
		if cam then
			cam.CameraSubject = hum
		end
	end)
end

local function ReloadDesync()
	StopDesync()
	task.wait(0.1)
	StartDesync()
end

local function stringToVector3(str)
	local coords = {}
	for num in string.gmatch(str, "[^,]+") do
		table.insert(coords, tonumber(num) or 0)
	end
	return Vector3.new(coords[1] or 0, coords[2] or 0, coords[3] or 0)
end

-- ==========================================
-- ИНТЕРФЕЙС (GUI)
-- ==========================================
local oldGui = CoreGui:FindFirstChild("WdymEditorGui")
if oldGui then oldGui:Destroy() end
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WdymEditorGui"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(164, 73, 163)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -145)
MainFrame.Size = UDim2.new(0, 250, 0, 430)
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 6)

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Parent = MainFrame
TopBar.BackgroundColor3 = Color3.fromRGB(164, 73, 163)
TopBar.BorderSizePixel = 0
TopBar.Size = UDim2.new(1, 0, 0, 32)
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 6)

local TitleText = Instance.new("TextLabel")
TitleText.Parent = TopBar
TitleText.Text = "WdymGaming's editor"
TitleText.TextColor3 = Color3.fromRGB(75, 33, 75)
TitleText.Font = Enum.Font.SourceSansBold
TitleText.TextSize = 20
TitleText.Size = UDim2.new(1, -65, 1, 0)
TitleText.Position = UDim2.new(0, 12, 0, 0)
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.BackgroundTransparency = 1

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Parent = TopBar
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.Position = UDim2.new(1, -50, 0, 0)
MinimizeBtn.Size = UDim2.new(0, 22, 1, 0)
MinimizeBtn.Font = Enum.Font.SourceSansBold
MinimizeBtn.TextSize = 18

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = TopBar
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Position = UDim2.new(1, -26, 0, 0)
CloseBtn.Size = UDim2.new(0, 22, 1, 0)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 15

local Container = Instance.new("Frame")
Container.Name = "Container"
Container.Parent = MainFrame
Container.BackgroundColor3 = Color3.fromRGB(164, 73, 163)
Container.BorderSizePixel = 0
Container.Position = UDim2.new(0, 0, 0, 32)
Container.Size = UDim2.new(1, 0, 1, -32)
Container.ClipsDescendants = true
Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 6)

local OrientationLabel = Instance.new("TextLabel")
OrientationLabel.Parent = Container
OrientationLabel.Text = "Orientation"
OrientationLabel.TextColor3 = Color3.fromRGB(77, 34, 77)
OrientationLabel.Size = UDim2.new(1, -24, 0, 18)
OrientationLabel.Position = UDim2.new(0, 12, 0, 8)
OrientationLabel.Font = Enum.Font.SourceSansSemibold
OrientationLabel.TextSize = 20
OrientationLabel.TextXAlignment = Enum.TextXAlignment.Left
OrientationLabel.BackgroundTransparency = 1

OrientationInput = Instance.new("TextBox")
OrientationInput.Parent = Container
OrientationInput.Text = "0,0,0"
OrientationInput.Size = UDim2.new(1, -24, 0, 24)
OrientationInput.Position = UDim2.new(0, 12, 0, 26)
OrientationInput.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
OrientationInput.TextColor3 = Color3.fromRGB(196, 121, 196)
OrientationInput.BorderSizePixel = 0
OrientationInput.Font = Enum.Font.SourceSans
OrientationInput.TextSize = 20
OrientationInput.ClearTextOnFocus = false
Instance.new("UICorner", OrientationInput).CornerRadius = UDim.new(0, 4)

local PositionLabel = Instance.new("TextLabel")
PositionLabel.Parent = Container
PositionLabel.Text = "Position"
PositionLabel.TextColor3 = Color3.fromRGB(77, 34, 77)
PositionLabel.Size = UDim2.new(1, -24, 0, 18)
PositionLabel.Position = UDim2.new(0, 12, 0, 56)
PositionLabel.Font = Enum.Font.SourceSansSemibold
PositionLabel.TextSize = 20
PositionLabel.TextXAlignment = Enum.TextXAlignment.Left
PositionLabel.BackgroundTransparency = 1

PositionInput = Instance.new("TextBox")
PositionInput.Parent = Container
PositionInput.Text = "0,0,0"
PositionInput.Size = UDim2.new(1, -24, 0, 24)
PositionInput.Position = UDim2.new(0, 12, 0, 74)
PositionInput.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
PositionInput.TextColor3 = Color3.fromRGB(196, 121, 196)
PositionInput.BorderSizePixel = 0
PositionInput.Font = Enum.Font.SourceSans
PositionInput.TextSize = 20
PositionInput.ClearTextOnFocus = false
Instance.new("UICorner", PositionInput).CornerRadius = UDim.new(0, 4)

local ApplyBtn = Instance.new("TextButton")
ApplyBtn.Parent = Container
ApplyBtn.Text = "Apply Changes"
ApplyBtn.TextColor3 = Color3.fromRGB(196, 121, 196)
ApplyBtn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
ApplyBtn.BorderSizePixel = 0
ApplyBtn.Position = UDim2.new(0, 12, 0, 110)
ApplyBtn.Size = UDim2.new(1, -24, 0, 28)
ApplyBtn.Font = Enum.Font.SourceSansBold
ApplyBtn.TextSize = 20
Instance.new("UICorner", ApplyBtn).CornerRadius = UDim.new(0, 4)

local AnimEditorBtn = Instance.new("TextButton")
AnimEditorBtn.Parent = Container
AnimEditorBtn.Text = "Desync animation editor"
AnimEditorBtn.TextColor3 = Color3.fromRGB(196, 121, 196)
AnimEditorBtn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
AnimEditorBtn.BorderSizePixel = 0
AnimEditorBtn.Position = UDim2.new(0, 12, 0, 145)
AnimEditorBtn.Size = UDim2.new(1, -24, 0, 28)
AnimEditorBtn.Font = Enum.Font.SourceSansBold
AnimEditorBtn.TextSize = 16
Instance.new("UICorner", AnimEditorBtn).CornerRadius = UDim.new(0, 4)

local DesyncAnimationsMenuBtn = Instance.new("TextButton")
DesyncAnimationsMenuBtn.Parent = Container
DesyncAnimationsMenuBtn.Text = "Desync Animations"
DesyncAnimationsMenuBtn.TextColor3 = Color3.fromRGB(196, 121, 196)
DesyncAnimationsMenuBtn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
DesyncAnimationsMenuBtn.BorderSizePixel = 0
DesyncAnimationsMenuBtn.Position = UDim2.new(0, 12, 0, 180)
DesyncAnimationsMenuBtn.Size = UDim2.new(1, -24, 0, 28)
DesyncAnimationsMenuBtn.Font = Enum.Font.SourceSansBold
DesyncAnimationsMenuBtn.TextSize = 16
Instance.new("UICorner", DesyncAnimationsMenuBtn).CornerRadius = UDim.new(0, 4)

local NormalAnimationsBtn = Instance.new("TextButton")
NormalAnimationsBtn.Parent = Container
NormalAnimationsBtn.Text = "Animations"
NormalAnimationsBtn.TextColor3 = Color3.fromRGB(196, 121, 196)
NormalAnimationsBtn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
NormalAnimationsBtn.BorderSizePixel = 0
NormalAnimationsBtn.Position = UDim2.new(0, 12, 0, 215)
NormalAnimationsBtn.Size = UDim2.new(1, -24, 0, 28)
NormalAnimationsBtn.Font = Enum.Font.SourceSansBold
NormalAnimationsBtn.TextSize = 16
Instance.new("UICorner", NormalAnimationsBtn).CornerRadius = UDim.new(0, 4)

local KeybindsBtn = Instance.new("TextButton")
KeybindsBtn.Parent = Container
KeybindsBtn.Text = "Keybinds"
KeybindsBtn.TextColor3 = Color3.fromRGB(196, 121, 196)
KeybindsBtn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
KeybindsBtn.BorderSizePixel = 0
KeybindsBtn.Position = UDim2.new(0, 12, 0, 250)
KeybindsBtn.Size = UDim2.new(1, -24, 0, 28)
KeybindsBtn.Font = Enum.Font.SourceSansBold
KeybindsBtn.TextSize = 16
Instance.new("UICorner", KeybindsBtn).CornerRadius = UDim.new(0, 4)

local AnimLoggerBtn = Instance.new("TextButton")
AnimLoggerBtn.Parent = Container
AnimLoggerBtn.Text = "Anim logger"
AnimLoggerBtn.TextColor3 = Color3.fromRGB(196, 121, 196)
AnimLoggerBtn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
AnimLoggerBtn.BorderSizePixel = 0
AnimLoggerBtn.Position = UDim2.new(0, 12, 0, 285)
AnimLoggerBtn.Size = UDim2.new(1, -24, 0, 28)
AnimLoggerBtn.Font = Enum.Font.SourceSansBold
AnimLoggerBtn.TextSize = 16
Instance.new("UICorner", AnimLoggerBtn).CornerRadius = UDim.new(0, 4)

-- Desync Toggle + Reload
DesyncToggleBtn = Instance.new("TextButton")
DesyncToggleBtn.Parent = Container
DesyncToggleBtn.Text = "Desync: OFF"
DesyncToggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
DesyncToggleBtn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
DesyncToggleBtn.BorderSizePixel = 0
DesyncToggleBtn.Position = UDim2.new(0, 12, 0, 320)
DesyncToggleBtn.Size = UDim2.new(0.5, -16, 0, 28)
DesyncToggleBtn.Font = Enum.Font.SourceSansBold
DesyncToggleBtn.TextSize = 15
Instance.new("UICorner", DesyncToggleBtn).CornerRadius = UDim.new(0, 4)

ReloadBtn = Instance.new("TextButton")
ReloadBtn.Parent = Container
ReloadBtn.Text = "Desync Reload"
ReloadBtn.TextColor3 = Color3.fromRGB(196, 121, 196)
ReloadBtn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
ReloadBtn.BorderSizePixel = 0
ReloadBtn.Position = UDim2.new(0.5, 4, 0, 320)
ReloadBtn.Size = UDim2.new(0.5, -16, 0, 28)
ReloadBtn.Font = Enum.Font.SourceSansBold
ReloadBtn.TextSize = 14
Instance.new("UICorner", ReloadBtn).CornerRadius = UDim.new(0, 4)

-- ==========================================
-- ЛОГИКА И СОБЫТИЯ
-- ==========================================
DesyncToggleBtn.MouseButton1Click:Connect(function()
	if IsDesynced then
		StopDesync()
	else
		StartDesync()
	end
end)

ReloadBtn.MouseButton1Click:Connect(function()
	ReloadDesync()
end)

ApplyBtn.MouseButton1Click:Connect(function()
	OffsetRot = ParseVector3(OrientationInput.Text)
	OffsetPos = ParseVector3(PositionInput.Text)
	ApplyBtn.Text = "Applied!"
	task.wait(0.4)
	ApplyBtn.Text = "Apply Changes"
end)

local currentDesyncAnimName = nil
local currentDesyncPlaying = false
local desyncAnimThread = nil

local function stopDesyncAnimation()
	if desyncAnimThread then
		task.cancel(desyncAnimThread)
		desyncAnimThread = nil
	end
	currentDesyncPlaying = false
	currentDesyncAnimName = nil
	OffsetRot = Vector3.new(0, 0, 0)
	OffsetPos = Vector3.new(0, 0, 0)
	if OrientationInput and PositionInput then
		OrientationInput.Text = "0,0,0"
		PositionInput.Text = "0,0,0"
	end
end

local function playDesyncAnimation(animName, loop, speed, reversed)
	stopDesyncAnimation()
	local animData = savedDesyncAnimations[animName]
	if not animData or not animData.frames then return end
	currentDesyncAnimName = animName
	currentDesyncPlaying = true
	local isLooped = loop or false
	local speedMultiplier = speed or 1.0
	local frames = animData.frames
	if reversed then
		local revFrames = {}
		for i = #frames, 1, -1 do table.insert(revFrames, frames[i]) end
		frames = revFrames
	end
	desyncAnimThread = task.spawn(function()
		while currentDesyncPlaying and isRunning do
			for _, frame in ipairs(frames) do
				if not currentDesyncPlaying then break end
				local targetRot = stringToVector3(frame.rot)
				local targetPos = stringToVector3(frame.pos)
				local duration = (frame.time or 1.0) / speedMultiplier
				local startRot = OffsetRot
				local startPos = OffsetPos
				local elapsed = 0
				while elapsed < duration and currentDesyncPlaying and isRunning do
					local step = h:Wait()
					elapsed = elapsed + step
					local t = math.min(elapsed / duration, 1)
					OffsetRot = startRot:Lerp(targetRot, t)
					OffsetPos = startPos:Lerp(targetPos, t)
				end
			end
			if not isLooped then break end
		end
		currentDesyncPlaying = false
		currentDesyncAnimName = nil
		desyncAnimThread = nil
	end)
end

local currentNormalTrack = nil
local currentNormalAnimName = nil

local function stopNormalAnimation()
	if currentNormalTrack then
		pcall(function() currentNormalTrack:Stop() end)
		currentNormalTrack = nil
	end
	currentNormalAnimName = nil
end

local function playNormalAnimation(bodyType, animName, speed, looped, reversed)
	stopNormalAnimation()
	local data = managerDataCache[bodyType]
	if not data then return end
	local animId = data[animName]
	if not animId then
		for subName, subTable in pairs(data._subcategories or {}) do
			if subTable[animName] then
				animId = subTable[animName]
				break
			end
		end
	end
	if not animId then return end
	local cleanId = string.match(tostring(animId), "%d+") or animId
	if c and c:FindFirstChildOfClass("Humanoid") then
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://" .. cleanId
		local humanoid = c:FindFirstChildOfClass("Humanoid")
		local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
		local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
		if ok and track then
			currentNormalTrack = track
			currentNormalAnimName = animName
			track.Looped = looped or false
			local spd = speed or 1.0
			if reversed then spd = -spd end
			track:Play()
			track:AdjustSpeed(spd)
			if reversed and track.Length > 0 then
				track.TimePosition = track.Length
			end
		end
	end
end

local keybindWaitForInput = false
local onKeybindPressed = nil

local function handleKeybind(key)
	if not key then return end
	if keybinds.Menu and keybinds.Menu.key == key then
		if MainFrame then
			MainFrame.Visible = not MainFrame.Visible
		end
		return
	end
	if keybinds.Desync and keybinds.Desync.key == key then
		if IsDesynced then
			StopDesync()
		else
			StartDesync()
		end
		return
	end
	if keybinds.Animations then
		for _, bind in ipairs(keybinds.Animations) do
			if bind.key == key then
				if bind.type == "Desync" then
					local animName = bind.animName
					if animName then
						if currentDesyncPlaying and currentDesyncAnimName == animName then
							stopDesyncAnimation()
						else
							playDesyncAnimation(animName, bind.looped, bind.speed, bind.reversed)
						end
					end
				elseif bind.type == "Normal" then
					local bodyType = bind.bodyType
					local animName = bind.animName
					if bodyType and animName then
						if currentNormalTrack and currentNormalAnimName == animName then
							stopNormalAnimation()
						else
							playNormalAnimation(bodyType, animName, bind.speed, bind.looped, bind.reversed)
						end
					end
				end
			end
		end
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.Keyboard then
		local key = input.KeyCode.Name
		if keybindWaitForInput then
			if onKeybindPressed then
				onKeybindPressed(key)
			end
			keybindWaitForInput = false
			return
		end
		handleKeybind(key)
	end
end)

local function addSubMenuControls(frame, topBar, container, titleName, defaultHeight)
	local title = Instance.new("TextLabel")
	title.Parent = topBar
	title.Text = titleName
	title.TextColor3 = Color3.fromRGB(75, 33, 75)
	title.Font = Enum.Font.SourceSansBold
	title.TextSize = 16
	title.Size = UDim2.new(1, -50, 1, 0)
	title.Position = UDim2.new(0, 10, 0, 0)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.BackgroundTransparency = 1
	local minBtn = Instance.new("TextButton")
	minBtn.Parent = topBar
	minBtn.Text = "-"
	minBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	minBtn.BackgroundTransparency = 1
	minBtn.Position = UDim2.new(1, -44, 0, 0)
	minBtn.Size = UDim2.new(0, 20, 1, 0)
	minBtn.Font = Enum.Font.SourceSansBold
	minBtn.TextSize = 16
	local clsBtn = Instance.new("TextButton")
	clsBtn.Parent = topBar
	clsBtn.Text = "X"
	clsBtn.TextColor3 = Color3.fromRGB(200, 50, 50)
	clsBtn.BackgroundTransparency = 1
	clsBtn.Position = UDim2.new(1, -22, 0, 0)
	clsBtn.Size = UDim2.new(0, 20, 1, 0)
	clsBtn.Font = Enum.Font.SourceSansBold
	clsBtn.TextSize = 14
	local subMinimized = false
	minBtn.MouseButton1Click:Connect(function()
		subMinimized = not subMinimized
		if subMinimized then
			container:TweenSize(UDim2.new(1, 0, 0, 0), "InOut", "Quad", 0.2, true)
			frame:TweenSize(UDim2.new(0, frame.Size.X.Offset, 0, 30), "InOut", "Quad", 0.2, true)
			minBtn.Text = "+"
		else
			container:TweenSize(UDim2.new(1, 0, 1, -30), "InOut", "Quad", 0.2, true)
			frame:TweenSize(UDim2.new(0, frame.Size.X.Offset, 0, defaultHeight), "InOut", "Quad", 0.2, true)
			minBtn.Text = "-"
		end
	end)
	clsBtn.MouseButton1Click:Connect(function()
		frame:Destroy()
	end)
end

-- ==========================================
-- AnimEditorBtn
-- ==========================================
AnimEditorBtn.MouseButton1Click:Connect(function()
	if ScreenGui:FindFirstChild("AnimEditorFrame") then return end
	local EditorFrame = Instance.new("Frame")
	EditorFrame.Name = "AnimEditorFrame"
	EditorFrame.Parent = ScreenGui
	EditorFrame.BackgroundColor3 = Color3.fromRGB(164, 73, 163)
	EditorFrame.Position = UDim2.new(MainFrame.Position.X.Scale, MainFrame.Position.X.Offset - 360, MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset)
	EditorFrame.Size = UDim2.new(0, 350, 0, 270)
	EditorFrame.Active = true
	EditorFrame.Draggable = true
	Instance.new("UICorner", EditorFrame).CornerRadius = UDim.new(0, 6)
	local TopBarE = Instance.new("Frame")
	TopBarE.Size = UDim2.new(1, 0, 0, 30)
	TopBarE.BackgroundColor3 = Color3.fromRGB(164, 73, 163)
	TopBarE.Parent = EditorFrame
	Instance.new("UICorner", TopBarE).CornerRadius = UDim.new(0, 6)
	local ContainerE = Instance.new("Frame")
	ContainerE.Size = UDim2.new(1, 0, 1, -30)
	ContainerE.Position = UDim2.new(0, 0, 0, 30)
	ContainerE.BackgroundColor3 = Color3.fromRGB(164, 73, 163)
	ContainerE.ClipsDescendants = true
	ContainerE.Parent = EditorFrame
	addSubMenuControls(EditorFrame, TopBarE, ContainerE, "Desync animation editor", 270)
	local LeftPanel = Instance.new("Frame")
	LeftPanel.Size = UDim2.new(0, 160, 1, 0)
	LeftPanel.BackgroundTransparency = 1
	LeftPanel.Parent = ContainerE
	local function createField(labelName, defaultText, yPos)
		local lbl = Instance.new("TextLabel")
		lbl.Text = labelName
		lbl.Size = UDim2.new(1, -20, 0, 16)
		lbl.Position = UDim2.new(0, 10, 0, yPos)
		lbl.TextColor3 = Color3.fromRGB(77, 34, 77)
		lbl.Font = Enum.Font.SourceSansSemibold
		lbl.TextSize = 14
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.BackgroundTransparency = 1
		lbl.Parent = LeftPanel
		local box = Instance.new("TextBox")
		box.Text = defaultText
		box.Size = UDim2.new(1, -20, 0, 22)
		box.Position = UDim2.new(0, 10, 0, yPos + 16)
		box.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
		box.TextColor3 = Color3.fromRGB(196, 121, 196)
		box.BorderSizePixel = 0
		box.Font = Enum.Font.SourceSans
		box.TextSize = 14
		box.ClearTextOnFocus = false
		Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
		box.Parent = LeftPanel
		return box
	end
	local EditOrient = createField("Orientation", "0,0,0", 5)
	local EditPos = createField("Position", "0,0,0", 45)
	local EditTime = createField("Time (seconds)", "1.0", 85)
	local AnimNameInput = createField("Animation Name", "MyAnimation", 125)
	local LoadBtn = Instance.new("TextButton")
	LoadBtn.Text = "Load Animation"
	LoadBtn.Size = UDim2.new(1, -20, 0, 22)
	LoadBtn.Position = UDim2.new(0, 10, 0, 165)
	LoadBtn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
	LoadBtn.TextColor3 = Color3.fromRGB(196, 121, 196)
	LoadBtn.Font = Enum.Font.SourceSansBold
	LoadBtn.TextSize = 12
	Instance.new("UICorner", LoadBtn).CornerRadius = UDim.new(0, 4)
	LoadBtn.Parent = LeftPanel
	local LoadDropdownList = Instance.new("ScrollingFrame")
	LoadDropdownList.Size = UDim2.new(1, -20, 0, 60)
	LoadDropdownList.Position = UDim2.new(0, 10, 0, 190)
	LoadDropdownList.BackgroundColor3 = Color3.fromRGB(60, 25, 60)
	LoadDropdownList.Visible = false
	LoadDropdownList.ZIndex = 5
	LoadDropdownList.CanvasSize = UDim2.new(0, 0, 0, 0)
	LoadDropdownList.ScrollBarThickness = 4
	LoadDropdownList.Parent = LeftPanel
	Instance.new("UIListLayout", LoadDropdownList)
	local RightPanel = Instance.new("ScrollingFrame")
	RightPanel.Size = UDim2.new(0, 170, 1, -10)
	RightPanel.Position = UDim2.new(0, 170, 0, 5)
	RightPanel.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
	RightPanel.BorderSizePixel = 0
	RightPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
	RightPanel.ScrollBarThickness = 4
	Instance.new("UICorner", RightPanel).CornerRadius = UDim.new(0, 4)
	RightPanel.Parent = ContainerE
	local UIList = Instance.new("UIListLayout")
	UIList.Parent = RightPanel
	UIList.Padding = UDim.new(0, 2)
	local currentEditingAnimation = {}
	local selectedItemIndex = nil
	local function refreshFramesList()
		if not RightPanel then return end
		for _, child in ipairs(RightPanel:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end
		for i, frameData in ipairs(currentEditingAnimation) do
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, 0, 0, 20)
			btn.BackgroundColor3 = (selectedItemIndex == i) and Color3.fromRGB(164, 73, 163) or Color3.fromRGB(90, 40, 90)
			btn.Text = string.format("[%d] P:%s O:%s T:%s", i, frameData.pos, frameData.rot, tostring(frameData.time))
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			btn.Font = Enum.Font.SourceSans
			btn.TextSize = 11
			btn.BorderSizePixel = 0
			btn.Parent = RightPanel
			btn.MouseButton1Click:Connect(function()
				selectedItemIndex = i
				EditOrient.Text = frameData.rot
				EditPos.Text = frameData.pos
				EditTime.Text = tostring(frameData.time)
				refreshFramesList()
			end)
		end
		RightPanel.CanvasSize = UDim2.new(0, 0, 0, #currentEditingAnimation * 22)
	end
	local function updateLoadDropdown()
		for _, child in ipairs(LoadDropdownList:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end
		local count = 0
		for name, data in pairs(savedDesyncAnimations) do
			if data.frames then
				count = count + 1
				local b = Instance.new("TextButton")
				b.Size = UDim2.new(1, 0, 0, 20)
				b.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
				b.TextColor3 = Color3.fromRGB(255, 255, 255)
				b.Text = name
				b.Font = Enum.Font.SourceSans
				b.TextSize = 12
				b.ZIndex = 6
				b.Parent = LoadDropdownList
				b.MouseButton1Click:Connect(function()
					local loaded = savedDesyncAnimations[name]
					if loaded and loaded.frames and #loaded.frames > 0 then
						currentEditingAnimation = {}
						for _, frame in ipairs(loaded.frames) do
							table.insert(currentEditingAnimation, {
								rot = frame.rot,
								pos = frame.pos,
								time = frame.time or 1.0
							})
						end
						AnimNameInput.Text = name
						refreshFramesList()
						LoadDropdownList.Visible = false
						LoadBtn.Text = "Loaded: " .. name
					else
						warn("No frames found for animation:", name)
					end
				end)
			end
		end
		LoadDropdownList.CanvasSize = UDim2.new(0, 0, 0, count * 22)
	end
	LoadBtn.MouseButton1Click:Connect(function()
		savedDesyncAnimations = loadDesyncAnimations()
		updateLoadDropdown()
		LoadDropdownList.Visible = not LoadDropdownList.Visible
	end)
	local AddBtn = Instance.new("TextButton")
	AddBtn.Text = "Add"
	AddBtn.Size = UDim2.new(0, 40, 0, 24)
	AddBtn.Position = UDim2.new(0, 10, 0, 215)
	AddBtn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
	AddBtn.TextColor3 = Color3.fromRGB(196, 121, 196)
	AddBtn.Font = Enum.Font.SourceSansBold
	AddBtn.TextSize = 14
	Instance.new("UICorner", AddBtn).CornerRadius = UDim.new(0, 4)
	AddBtn.Parent = LeftPanel
	local RemoveBtn = Instance.new("TextButton")
	RemoveBtn.Text = "Remove"
	RemoveBtn.Size = UDim2.new(0, 50, 0, 24)
	RemoveBtn.Position = UDim2.new(0, 55, 0, 215)
	RemoveBtn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
	RemoveBtn.TextColor3 = Color3.fromRGB(196, 121, 196)
	RemoveBtn.Font = Enum.Font.SourceSansBold
	RemoveBtn.TextSize = 14
	Instance.new("UICorner", RemoveBtn).CornerRadius = UDim.new(0, 4)
	RemoveBtn.Parent = LeftPanel
	local UpdateBtn = Instance.new("TextButton")
	UpdateBtn.Text = "Edit"
	UpdateBtn.Size = UDim2.new(0, 50, 0, 24)
	UpdateBtn.Position = UDim2.new(0, 110, 0, 215)
	UpdateBtn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
	UpdateBtn.TextColor3 = Color3.fromRGB(196, 121, 196)
	UpdateBtn.Font = Enum.Font.SourceSansBold
	UpdateBtn.TextSize = 14
	Instance.new("UICorner", UpdateBtn).CornerRadius = UDim.new(0, 4)
	UpdateBtn.Parent = LeftPanel
	local SaveBtn = Instance.new("TextButton")
	SaveBtn.Text = "Save"
	SaveBtn.Size = UDim2.new(0, 40, 0, 24)
	SaveBtn.Position = UDim2.new(1, -50, 0, 215)
	SaveBtn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
	SaveBtn.TextColor3 = Color3.fromRGB(196, 121, 196)
	SaveBtn.Font = Enum.Font.SourceSansBold
	SaveBtn.TextSize = 14
	Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 4)
	SaveBtn.Parent = LeftPanel
	AddBtn.MouseButton1Click:Connect(function()
		table.insert(currentEditingAnimation, {
			rot = EditOrient.Text,
			pos = EditPos.Text,
			time = tonumber(EditTime.Text) or 1.0
		})
		refreshFramesList()
	end)
	RemoveBtn.MouseButton1Click:Connect(function()
		if selectedItemIndex and currentEditingAnimation[selectedItemIndex] then
			table.remove(currentEditingAnimation, selectedItemIndex)
			selectedItemIndex = nil
			refreshFramesList()
		end
	end)
	UpdateBtn.MouseButton1Click:Connect(function()
		if selectedItemIndex then
			currentEditingAnimation[selectedItemIndex] = {
				rot = EditOrient.Text,
				pos = EditPos.Text,
				time = tonumber(EditTime.Text) or 1.0
			}
			refreshFramesList()
			UpdateBtn.Text = "Updated!"
			task.wait(0.3)
			UpdateBtn.Text = "Update"
		end
	end)
	SaveBtn.MouseButton1Click:Connect(function()
		local name = AnimNameInput.Text
		if name ~= "" and #currentEditingAnimation > 0 then
			savedDesyncAnimations[name] = { frames = currentEditingAnimation }
			saveDesyncAnimations(savedDesyncAnimations)
			SaveBtn.Text = "Saved!"
			task.wait(0.5)
			SaveBtn.Text = "Save"
		end
	end)
	refreshFramesList()
end)

DesyncAnimationsMenuBtn.MouseButton1Click:Connect(function()
	if ScreenGui:FindFirstChild("DesyncAnimationsPlayFrame") then return end
	local PlayFrame = Instance.new("Frame")
	PlayFrame.Name = "DesyncAnimationsPlayFrame"
	PlayFrame.Parent = ScreenGui
	PlayFrame.BackgroundColor3 = Color3.fromRGB(164, 73, 163)
	PlayFrame.Position = UDim2.new(MainFrame.Position.X.Scale, MainFrame.Position.X.Offset + 260, MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset)
	PlayFrame.Size = UDim2.new(0, 220, 0, 240)
	PlayFrame.Active = true
	PlayFrame.Draggable = true
	Instance.new("UICorner", PlayFrame).CornerRadius = UDim.new(0, 6)
	local TopBarP = Instance.new("Frame")
	TopBarP.Size = UDim2.new(1, 0, 0, 30)
	TopBarP.BackgroundColor3 = Color3.fromRGB(164, 73, 163)
	TopBarP.Parent = PlayFrame
	Instance.new("UICorner", TopBarP).CornerRadius = UDim.new(0, 6)
	local ContainerP = Instance.new("Frame")
	ContainerP.Size = UDim2.new(1, 0, 1, -30)
	ContainerP.Position = UDim2.new(0, 0, 0, 30)
	ContainerP.BackgroundColor3 = Color3.fromRGB(164, 73, 163)
	ContainerP.ClipsDescendants = true
	ContainerP.Parent = PlayFrame
	addSubMenuControls(PlayFrame, TopBarP, ContainerP, "Desync Animations", 240)
	local DropdownBtn = Instance.new("TextButton")
	DropdownBtn.Text = "Select Animation v"
	DropdownBtn.Size = UDim2.new(1, -24, 0, 30)
	DropdownBtn.Position = UDim2.new(0, 12, 0, 10)
	DropdownBtn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
	DropdownBtn.TextColor3 = Color3.fromRGB(196, 121, 196)
	DropdownBtn.Font = Enum.Font.SourceSansBold
	DropdownBtn.TextSize = 16
	Instance.new("UICorner", DropdownBtn).CornerRadius = UDim.new(0, 4)
	DropdownBtn.Parent = ContainerP
	local DropdownList = Instance.new("ScrollingFrame")
	DropdownList.Size = UDim2.new(1, -24, 0, 80)
	DropdownList.Position = UDim2.new(0, 12, 0, 42)
	DropdownList.BackgroundColor3 = Color3.fromRGB(60, 25, 60)
	DropdownList.Visible = false
	DropdownList.ZIndex = 5
	DropdownList.CanvasSize = UDim2.new(0, 0, 0, 0)
	DropdownList.ScrollBarThickness = 4
	DropdownList.Parent = ContainerP
	Instance.new("UIListLayout", DropdownList)
	local selectedAnimName = nil
	local function updateDropdown()
		for _, child in ipairs(DropdownList:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end
		local count = 0
		for name, data in pairs(savedDesyncAnimations) do
			if data.frames then
				count = count + 1
				local b = Instance.new("TextButton")
				b.Size = UDim2.new(1, 0, 0, 22)
				b.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
				b.TextColor3 = Color3.fromRGB(255, 255, 255)
				b.Text = name
				b.Font = Enum.Font.SourceSans
				b.TextSize = 14
				b.ZIndex = 6
				b.Parent = DropdownList
				b.MouseButton1Click:Connect(function()
					selectedAnimName = name
					DropdownBtn.Text = name .. " v"
					DropdownList.Visible = false
				end)
			end
		end
		DropdownList.CanvasSize = UDim2.new(0, 0, 0, count * 22)
	end
	DropdownBtn.MouseButton1Click:Connect(function()
		savedDesyncAnimations = loadDesyncAnimations()
		updateDropdown()
		DropdownList.Visible = not DropdownList.Visible
	end)
	local LoopContainer = Instance.new("Frame")
	LoopContainer.Size = UDim2.new(1, -24, 0, 24)
	LoopContainer.Position = UDim2.new(0, 12, 0, 85)
	LoopContainer.BackgroundTransparency = 1
	LoopContainer.Parent = ContainerP
	local LoopCheck = Instance.new("TextButton")
	LoopCheck.Text = ""
	LoopCheck.Size = UDim2.new(0, 20, 0, 20)
	LoopCheck.Position = UDim2.new(0, 0, 0, 2)
	LoopCheck.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
	Instance.new("UICorner", LoopCheck).CornerRadius = UDim.new(0, 4)
	LoopCheck.Parent = LoopContainer
	local LoopLabel = Instance.new("TextLabel")
	LoopLabel.Text = "Loop Animation"
	LoopLabel.Size = UDim2.new(1, -30, 1, 0)
	LoopLabel.Position = UDim2.new(0, 30, 0, 0)
	LoopLabel.TextColor3 = Color3.fromRGB(77, 34, 77)
	LoopLabel.Font = Enum.Font.SourceSansSemibold
	LoopLabel.TextSize = 16
	LoopLabel.TextXAlignment = Enum.TextXAlignment.Left
	LoopLabel.BackgroundTransparency = 1
	LoopLabel.Parent = LoopContainer
	local isLooped = false
	LoopCheck.MouseButton1Click:Connect(function()
		isLooped = not isLooped
		LoopCheck.Text = isLooped and "X" or ""
		LoopCheck.TextColor3 = Color3.fromRGB(196, 121, 196)
	end)
	local SpeedContainer = Instance.new("Frame")
	SpeedContainer.Size = UDim2.new(1, -24, 0, 24)
	SpeedContainer.Position = UDim2.new(0, 12, 0, 115)
	SpeedContainer.BackgroundTransparency = 1
	SpeedContainer.Parent = ContainerP
	local SpeedLabel = Instance.new("TextLabel")
	SpeedLabel.Text = "Speed:"
	SpeedLabel.Size = UDim2.new(0, 50, 1, 0)
	SpeedLabel.TextColor3 = Color3.fromRGB(77, 34, 77)
	SpeedLabel.Font = Enum.Font.SourceSansSemibold
	SpeedLabel.TextSize = 16
	SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
	SpeedLabel.BackgroundTransparency = 1
	SpeedLabel.Parent = SpeedContainer
	local SpeedInput = Instance.new("TextBox")
	SpeedInput.Text = "1.0"
	SpeedInput.Size = UDim2.new(1, -55, 1, 0)
	SpeedInput.Position = UDim2.new(0, 55, 0, 0)
	SpeedInput.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
	SpeedInput.TextColor3 = Color3.fromRGB(196, 121, 196)
	SpeedInput.BorderSizePixel = 0
	SpeedInput.Font = Enum.Font.SourceSans
	SpeedInput.TextSize = 16
	SpeedInput.ClearTextOnFocus = false
	Instance.new("UICorner", SpeedInput).CornerRadius = UDim.new(0, 4)
	SpeedInput.Parent = SpeedContainer
	local PlayBtn = Instance.new("TextButton")
	PlayBtn.Text = "Play"
	PlayBtn.Size = UDim2.new(0, 90, 0, 30)
	PlayBtn.Position = UDim2.new(0, 12, 0, 155)
	PlayBtn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
	PlayBtn.TextColor3 = Color3.fromRGB(196, 121, 196)
	PlayBtn.Font = Enum.Font.SourceSansBold
	PlayBtn.TextSize = 16
	Instance.new("UICorner", PlayBtn).CornerRadius = UDim.new(0, 4)
	PlayBtn.Parent = ContainerP
	local RemAnimBtn = Instance.new("TextButton")
	RemAnimBtn.Text = "Remove"
	RemAnimBtn.Size = UDim2.new(0, 90, 0, 30)
	RemAnimBtn.Position = UDim2.new(1, -102, 0, 155)
	RemAnimBtn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
	RemAnimBtn.TextColor3 = Color3.fromRGB(200, 50, 50)
	RemAnimBtn.Font = Enum.Font.SourceSansBold
	RemAnimBtn.TextSize = 16
	Instance.new("UICorner", RemAnimBtn).CornerRadius = UDim.new(0, 4)
	RemAnimBtn.Parent = ContainerP
	PlayBtn.MouseButton1Click:Connect(function()
		if animationPlaying then
			animationPlaying = false
			PlayBtn.Text = "Play"
			return
		end
		if not selectedAnimName or not savedDesyncAnimations[selectedAnimName] then return end
		animationPlaying = true
		PlayBtn.Text = "Stop"
		local animData = savedDesyncAnimations[selectedAnimName]
		task.spawn(function()
			while animationPlaying and isRunning do
				for _, frame in ipairs(animData.frames) do
					if not animationPlaying then break end
					local targetRot = stringToVector3(frame.rot)
					local targetPos = stringToVector3(frame.pos)
					local speedMultiplier = tonumber(SpeedInput.Text) or 1.0
					if speedMultiplier <= 0 then speedMultiplier = 1.0 end
					local duration = (frame.time or 1.0) / speedMultiplier
					local startRot = OffsetRot
					local startPos = OffsetPos
					local elapsed = 0
					while elapsed < duration and animationPlaying and isRunning do
						local step = h:Wait()
						elapsed = elapsed + step
						local t = math.min(elapsed / duration, 1)
						OffsetRot = startRot:Lerp(targetRot, t)
						OffsetPos = startPos:Lerp(targetPos, t)
					end
				end
				if not isLooped then break end
			end
			animationPlaying = false
			PlayBtn.Text = "Play"
		end)
	end)
	RemAnimBtn.MouseButton1Click:Connect(function()
		if selectedAnimName then
			savedDesyncAnimations[selectedAnimName] = nil
			saveDesyncAnimations(savedDesyncAnimations)
			selectedAnimName = nil
			DropdownBtn.Text = "Select Animation v"
			updateDropdown()
		end
	end)
end)

-- ==========================================
-- Normal Animations Manager (полный)
-- ==========================================
NormalAnimationsBtn.MouseButton1Click:Connect(function()
	if ScreenGui:FindFirstChild("NormalAnimationsFrame") then return end
	local AnimFrame = Instance.new("Frame")
	AnimFrame.Name = "NormalAnimationsFrame"
	AnimFrame.Parent = ScreenGui
	AnimFrame.BackgroundColor3 = Color3.fromRGB(164, 73, 163)
	AnimFrame.Position = UDim2.new(MainFrame.Position.X.Scale, MainFrame.Position.X.Offset + 260, MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset)
	AnimFrame.Size = UDim2.new(0, 320, 0, 490)
	AnimFrame.Active = true
	AnimFrame.Draggable = true
	Instance.new("UICorner", AnimFrame).CornerRadius = UDim.new(0, 6)
	local TopBarA = Instance.new("Frame")
	TopBarA.Size = UDim2.new(1, 0, 0, 30)
	TopBarA.BackgroundColor3 = Color3.fromRGB(164, 73, 163)
	TopBarA.Parent = AnimFrame
	Instance.new("UICorner", TopBarA).CornerRadius = UDim.new(0, 6)
	local ContainerA = Instance.new("Frame")
	ContainerA.Size = UDim2.new(1, 0, 1, -30)
	ContainerA.Position = UDim2.new(0, 0, 0, 30)
	ContainerA.BackgroundColor3 = Color3.fromRGB(164, 73, 163)
	ContainerA.ClipsDescendants = true
	ContainerA.Parent = AnimFrame
	addSubMenuControls(AnimFrame, TopBarA, ContainerA, "Animations Manager", 490)

	local currentMainCat = "R6"
	local currentSubCat = "[Main]"
	local searchFilter = ""
	local playSpeed = 1.0
	local isLooped = false
	local isReversed = false
	local activeTrack = nil

	local R6Btn = Instance.new("TextButton")
	R6Btn.Text = "R6"
	R6Btn.Size = UDim2.new(0.5, -6, 0, 26)
	R6Btn.Position = UDim2.new(0, 10, 0, 8)
	R6Btn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
	R6Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	R6Btn.Font = Enum.Font.SourceSansBold
	R6Btn.TextSize = 16
	Instance.new("UICorner", R6Btn).CornerRadius = UDim.new(0, 4)
	R6Btn.Parent = ContainerA

	local R15Btn = Instance.new("TextButton")
	R15Btn.Text = "R15"
	R15Btn.Size = UDim2.new(0.5, -6, 0, 26)
	R15Btn.Position = UDim2.new(0.5, 2, 0, 8)
	R15Btn.BackgroundColor3 = Color3.fromRGB(110, 50, 110)
	R15Btn.TextColor3 = Color3.fromRGB(180, 180, 180)
	R15Btn.Font = Enum.Font.SourceSansBold
	R15Btn.TextSize = 16
	Instance.new("UICorner", R15Btn).CornerRadius = UDim.new(0, 4)
	R15Btn.Parent = ContainerA

	local SubCatDropdown = Instance.new("TextButton")
	SubCatDropdown.Text = "Category: [Main] v"
	SubCatDropdown.Size = UDim2.new(1, -20, 0, 24)
	SubCatDropdown.Position = UDim2.new(0, 10, 0, 40)
	SubCatDropdown.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
	SubCatDropdown.TextColor3 = Color3.fromRGB(196, 121, 196)
	SubCatDropdown.Font = Enum.Font.SourceSans
	SubCatDropdown.TextSize = 14
	Instance.new("UICorner", SubCatDropdown).CornerRadius = UDim.new(0, 4)
	SubCatDropdown.Parent = ContainerA

	local SubDropdownList = Instance.new("ScrollingFrame")
	SubDropdownList.Size = UDim2.new(1, -20, 0, 80)
	SubDropdownList.Position = UDim2.new(0, 10, 0, 66)
	SubDropdownList.BackgroundColor3 = Color3.fromRGB(60, 25, 60)
	SubDropdownList.Visible = false
	SubDropdownList.ZIndex = 10
	SubDropdownList.ScrollBarThickness = 4
	SubDropdownList.Parent = ContainerA
	Instance.new("UIListLayout", SubDropdownList)

	local DelSubCatBtn = Instance.new("TextButton")
	DelSubCatBtn.Text = "Del Sub"
	DelSubCatBtn.Size = UDim2.new(0, 70, 0, 24)
	DelSubCatBtn.Position = UDim2.new(1, -80, 0, 40)
	DelSubCatBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
	DelSubCatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	DelSubCatBtn.Font = Enum.Font.SourceSansBold
	DelSubCatBtn.TextSize = 12
	DelSubCatBtn.Visible = false
	Instance.new("UICorner", DelSubCatBtn).CornerRadius = UDim.new(0, 4)
	DelSubCatBtn.Parent = ContainerA

	local NewSubInput = Instance.new("TextBox")
	NewSubInput.PlaceholderText = "New subcategory..."
	NewSubInput.Text = ""
	NewSubInput.Size = UDim2.new(1, -90, 0, 22)
	NewSubInput.Position = UDim2.new(0, 10, 0, 70)
	NewSubInput.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
	NewSubInput.TextColor3 = Color3.fromRGB(255, 255, 255)
	NewSubInput.Font = Enum.Font.SourceSans
	NewSubInput.TextSize = 14
	NewSubInput.ClearTextOnFocus = false
	Instance.new("UICorner", NewSubInput).CornerRadius = UDim.new(0, 4)
	NewSubInput.Parent = ContainerA

	local AddSubBtn = Instance.new("TextButton")
	AddSubBtn.Text = "Add"
	AddSubBtn.Size = UDim2.new(0, 70, 0, 22)
	AddSubBtn.Position = UDim2.new(1, -80, 0, 70)
	AddSubBtn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
	AddSubBtn.TextColor3 = Color3.fromRGB(196, 121, 196)
	AddSubBtn.Font = Enum.Font.SourceSansBold
	AddSubBtn.TextSize = 14
	Instance.new("UICorner", AddSubBtn).CornerRadius = UDim.new(0, 4)
	AddSubBtn.Parent = ContainerA

	local SearchBar = Instance.new("TextBox")
	SearchBar.PlaceholderText = "Search..."
	SearchBar.Text = ""
	SearchBar.Size = UDim2.new(1, -20, 0, 24)
	SearchBar.Position = UDim2.new(0, 10, 0, 100)
	SearchBar.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
	SearchBar.TextColor3 = Color3.fromRGB(255, 255, 255)
	SearchBar.Font = Enum.Font.SourceSans
	SearchBar.TextSize = 14
	SearchBar.ClearTextOnFocus = false
	Instance.new("UICorner", SearchBar).CornerRadius = UDim.new(0, 4)
	SearchBar.Parent = ContainerA

	local AnimListFrame = Instance.new("ScrollingFrame")
	AnimListFrame.Size = UDim2.new(1, -20, 0, 200)
	AnimListFrame.Position = UDim2.new(0, 10, 0, 130)
	AnimListFrame.BackgroundColor3 = Color3.fromRGB(60, 25, 60)
	AnimListFrame.ScrollBarThickness = 4
	AnimListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	Instance.new("UICorner", AnimListFrame).CornerRadius = UDim.new(0, 4)
	AnimListFrame.Parent = ContainerA
	local listLayout = Instance.new("UIListLayout", AnimListFrame)
	listLayout.Padding = UDim.new(0, 2)

	local AnimNameIn = Instance.new("TextBox")
	AnimNameIn.PlaceholderText = "Animation Name"
	AnimNameIn.Text = ""
	AnimNameIn.Size = UDim2.new(0.5, -12, 0, 24)
	AnimNameIn.Position = UDim2.new(0, 10, 0, 340)
	AnimNameIn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
	AnimNameIn.TextColor3 = Color3.fromRGB(255, 255, 255)
	AnimNameIn.Font = Enum.Font.SourceSans
	AnimNameIn.TextSize = 14
	AnimNameIn.ClearTextOnFocus = false
	Instance.new("UICorner", AnimNameIn).CornerRadius = UDim.new(0, 4)
	AnimNameIn.Parent = ContainerA

	local AnimIdIn = Instance.new("TextBox")
	AnimIdIn.PlaceholderText = "Animation ID"
	AnimIdIn.Text = ""
	AnimIdIn.Size = UDim2.new(0.5, -12, 0, 24)
	AnimIdIn.Position = UDim2.new(0.5, 2, 0, 340)
	AnimIdIn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
	AnimIdIn.TextColor3 = Color3.fromRGB(255, 255, 255)
	AnimIdIn.Font = Enum.Font.SourceSans
	AnimIdIn.TextSize = 14
	AnimIdIn.ClearTextOnFocus = false
	Instance.new("UICorner", AnimIdIn).CornerRadius = UDim.new(0, 4)
	AnimIdIn.Parent = ContainerA

	local SettingsPanel = Instance.new("Frame")
	SettingsPanel.Size = UDim2.new(1, -20, 0, 50)
	SettingsPanel.Position = UDim2.new(0, 10, 0, 370)
	SettingsPanel.BackgroundColor3 = Color3.fromRGB(95, 45, 95)
	Instance.new("UICorner", SettingsPanel).CornerRadius = UDim.new(0, 4)
	SettingsPanel.Parent = ContainerA

	local SpdLabel = Instance.new("TextLabel")
	SpdLabel.Text = "Speed:"
	SpdLabel.Size = UDim2.new(0, 45, 0, 20)
	SpdLabel.Position = UDim2.new(0, 8, 0, 4)
	SpdLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	SpdLabel.Font = Enum.Font.SourceSansSemibold
	SpdLabel.TextSize = 14
	SpdLabel.BackgroundTransparency = 1
	SpdLabel.Parent = SettingsPanel

	local SpdInput = Instance.new("TextBox")
	SpdInput.Text = "1.0"
	SpdInput.Size = UDim2.new(0, 40, 0, 18)
	SpdInput.Position = UDim2.new(0, 55, 0, 5)
	SpdInput.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
	SpdInput.TextColor3 = Color3.fromRGB(196, 121, 196)
	SpdInput.BorderSizePixel = 0
	SpdInput.Font = Enum.Font.SourceSans
	SpdInput.TextSize = 14
	SpdInput.ClearTextOnFocus = false
	Instance.new("UICorner", SpdInput).CornerRadius = UDim.new(0, 4)
	SpdInput.Parent = SettingsPanel
	SpdInput.FocusLost:Connect(function()
		playSpeed = tonumber(SpdInput.Text) or 1.0
		if activeTrack and activeTrack.IsPlaying then
			activeTrack:AdjustSpeed(playSpeed * (isReversed and -1 or 1))
		end
	end)

	local LoopBtn = Instance.new("TextButton")
	LoopBtn.Text = "Loop: OFF"
	LoopBtn.Size = UDim2.new(0, 80, 0, 20)
	LoopBtn.Position = UDim2.new(0, 110, 0, 4)
	LoopBtn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
	LoopBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
	LoopBtn.Font = Enum.Font.SourceSansBold
	LoopBtn.TextSize = 13
	Instance.new("UICorner", LoopBtn).CornerRadius = UDim.new(0, 4)
	LoopBtn.Parent = SettingsPanel
	LoopBtn.MouseButton1Click:Connect(function()
		isLooped = not isLooped
		LoopBtn.Text = isLooped and "Loop: ON" or "Loop: OFF"
		LoopBtn.TextColor3 = isLooped and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
		if activeTrack then
			activeTrack.Looped = isLooped
		end
	end)

	local ReverseBtn = Instance.new("TextButton")
	ReverseBtn.Text = "Reverse: OFF"
	ReverseBtn.Size = UDim2.new(0, 95, 0, 20)
	ReverseBtn.Position = UDim2.new(1, -103, 0, 4)
	ReverseBtn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
	ReverseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
	ReverseBtn.Font = Enum.Font.SourceSansBold
	ReverseBtn.TextSize = 13
	Instance.new("UICorner", ReverseBtn).CornerRadius = UDim.new(0, 4)
	ReverseBtn.Parent = SettingsPanel
	ReverseBtn.MouseButton1Click:Connect(function()
		isReversed = not isReversed
		ReverseBtn.Text = isReversed and "Reverse: ON" or "Reverse: OFF"
		ReverseBtn.TextColor3 = isReversed and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
		if activeTrack and activeTrack.IsPlaying then
			activeTrack:AdjustSpeed(playSpeed * (isReversed and -1 or 1))
		end
	end)

	local BoxHint = Instance.new("TextLabel")
	BoxHint.Text = "*Reverse changes direction on play/live adjust"
	BoxHint.Size = UDim2.new(1, -16, 0, 16)
	BoxHint.Position = UDim2.new(0, 8, 0, 28)
	BoxHint.TextColor3 = Color3.fromRGB(180, 150, 180)
	BoxHint.Font = Enum.Font.SourceSansItalic
	BoxHint.TextSize = 12
	BoxHint.TextXAlignment = Enum.TextXAlignment.Left
	BoxHint.BackgroundTransparency = 1
	BoxHint.Parent = SettingsPanel

	local ActionFrame = Instance.new("Frame")
	ActionFrame.Size = UDim2.new(1, -20, 0, 30)
	ActionFrame.Position = UDim2.new(0, 10, 0, 430)
	ActionFrame.BackgroundTransparency = 1
	ActionFrame.Parent = ContainerA

	local AddAnimBtn = Instance.new("TextButton")
	AddAnimBtn.Text = "Add Anim"
	AddAnimBtn.Size = UDim2.new(0.5, -2, 1, 0)
	AddAnimBtn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
	AddAnimBtn.TextColor3 = Color3.fromRGB(196, 121, 196)
	AddAnimBtn.Font = Enum.Font.SourceSansBold
	AddAnimBtn.TextSize = 16
	Instance.new("UICorner", AddAnimBtn).CornerRadius = UDim.new(0, 4)
	AddAnimBtn.Parent = ActionFrame

	local StopAnimBtn = Instance.new("TextButton")
	StopAnimBtn.Text = "Stop Playing"
	StopAnimBtn.Size = UDim2.new(0.5, -2, 1, 0)
	StopAnimBtn.Position = UDim2.new(0.5, 2, 0, 0)
	StopAnimBtn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
	StopAnimBtn.TextColor3 = Color3.fromRGB(196, 121, 196)
	StopAnimBtn.Font = Enum.Font.SourceSansBold
	StopAnimBtn.TextSize = 16
	Instance.new("UICorner", StopAnimBtn).CornerRadius = UDim.new(0, 4)
	StopAnimBtn.Parent = ActionFrame

	local updateAnimsList, updateSubDropdown

	updateAnimsList = function()
		for _, child in ipairs(AnimListFrame:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end
		local currentData = managerDataCache[currentMainCat]
		local targetContainer
		if currentSubCat == "[Main]" then
			targetContainer = currentData
			DelSubCatBtn.Visible = false
			SubCatDropdown.Size = UDim2.new(1, -20, 0, 24)
		else
			targetContainer = currentData._subcategories[currentSubCat]
			DelSubCatBtn.Visible = true
			SubCatDropdown.Size = UDim2.new(1, -95, 0, 24)
		end
		if not targetContainer then return end
		local count = 0
		for name, id in pairs(targetContainer) do
			if name ~= "_subcategories" then
				if searchFilter == "" or string.find(string.lower(name), string.lower(searchFilter), 1, true) then
					count = count + 1
					local row = Instance.new("Frame")
					row.Size = UDim2.new(1, 0, 0, 26)
					row.BackgroundTransparency = 1
					local playBtn = Instance.new("TextButton")
					playBtn.Text = "▶ " .. name
					playBtn.Size = UDim2.new(1, -30, 1, 0)
					playBtn.BackgroundColor3 = Color3.fromRGB(90, 40, 90)
					playBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
					playBtn.Font = Enum.Font.SourceSans
					playBtn.TextSize = 14
					playBtn.TextXAlignment = Enum.TextXAlignment.Left
					Instance.new("UICorner", playBtn).CornerRadius = UDim.new(0, 4)
					playBtn.Parent = row
					local delBtn = Instance.new("TextButton")
					delBtn.Text = "X"
					delBtn.Size = UDim2.new(0, 26, 1, 0)
					delBtn.Position = UDim2.new(1, -26, 0, 0)
					delBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
					delBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
					delBtn.Font = Enum.Font.SourceSansBold
					delBtn.TextSize = 12
					Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 4)
					delBtn.Parent = row
					playBtn.MouseButton1Click:Connect(function()
						if activeTrack then activeTrack:Stop() end
						if c and c:FindFirstChildOfClass("Humanoid") then
							local cleanId = string.match(tostring(id), "%d+") or id
							local anim = Instance.new("Animation")
							anim.AnimationId = "rbxassetid://" .. cleanId
							local humanoid = c:FindFirstChildOfClass("Humanoid")
							local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
							local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
							if ok and track then
								activeTrack = track
								track.Looped = isLooped
								track:Play()
								track:AdjustSpeed(playSpeed * (isReversed and -1 or 1))
								if isReversed then
									track.TimePosition = track.Length > 0 and track.Length or 0.1
								end
							end
						end
					end)
					delBtn.MouseButton1Click:Connect(function()
						targetContainer[name] = nil
						saveManagerData(currentMainCat, currentData)
						updateAnimsList()
					end)
					row.Parent = AnimListFrame
				end
			end
		end
		AnimListFrame.CanvasSize = UDim2.new(0, 0, 0, count * 28)
	end

	SearchBar:GetPropertyChangedSignal("Text"):Connect(function()
		searchFilter = SearchBar.Text
		updateAnimsList()
	end)

	updateSubDropdown = function()
		for _, child in ipairs(SubDropdownList:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end
		local currentData = managerDataCache[currentMainCat]
		local subs = currentData and currentData._subcategories or {}
		local function createDropdownItem(targetName)
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(1, 0, 0, 22)
			b.BackgroundColor3 = Color3.fromRGB(80, 35, 80)
			b.TextColor3 = Color3.fromRGB(255, 255, 255)
			b.Text = targetName
			b.Font = Enum.Font.SourceSans
			b.TextSize = 14
			b.ZIndex = 11
			b.Parent = SubDropdownList
			b.MouseButton1Click:Connect(function()
				currentSubCat = targetName
				SubCatDropdown.Text = "Category: " .. targetName .. " v"
				SubDropdownList.Visible = false
				updateAnimsList()
			end)
		end
		createDropdownItem("[Main]")
		for subName, _ in pairs(subs) do
			createDropdownItem(subName)
		end
	end

	local function selectMainCat(cat)
		currentMainCat = cat
		currentSubCat = "[Main]"
		SubCatDropdown.Text = "Category: [Main] v"
		if cat == "R6" then
			R6Btn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
			R6Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			R15Btn.BackgroundColor3 = Color3.fromRGB(110, 50, 110)
			R15Btn.TextColor3 = Color3.fromRGB(180, 180, 180)
		else
			R15Btn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
			R15Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			R6Btn.BackgroundColor3 = Color3.fromRGB(110, 50, 110)
			R6Btn.TextColor3 = Color3.fromRGB(180, 180, 180)
		end
		managerDataCache[cat] = loadManagerData(cat)
		updateSubDropdown()
		updateAnimsList()
	end

	R6Btn.MouseButton1Click:Connect(function() selectMainCat("R6") end)
	R15Btn.MouseButton1Click:Connect(function() selectMainCat("R15") end)

	SubCatDropdown.MouseButton1Click:Connect(function()
		SubDropdownList.Visible = not SubDropdownList.Visible
	end)

	DelSubCatBtn.MouseButton1Click:Connect(function()
		if currentSubCat ~= "[Main]" then
			local currentData = managerDataCache[currentMainCat]
			currentData._subcategories[currentSubCat] = nil
			saveManagerData(currentMainCat, currentData)
			currentSubCat = "[Main]"
			SubCatDropdown.Text = "Category: [Main] v"
			updateSubDropdown()
			updateAnimsList()
		end
	end)

	AddSubBtn.MouseButton1Click:Connect(function()
		local subName = NewSubInput.Text
		if subName ~= "" and subName ~= "[Main]" then
			local currentData = managerDataCache[currentMainCat]
			if not currentData._subcategories[subName] then
				currentData._subcategories[subName] = {}
				saveManagerData(currentMainCat, currentData)
				NewSubInput.Text = ""
				updateSubDropdown()
			end
		end
	end)

	AddAnimBtn.MouseButton1Click:Connect(function()
		local name = AnimNameIn.Text
		local id = AnimIdIn.Text
		if name ~= "" and id ~= "" then
			local cleanId = string.match(id, "%d+") or id
			local currentData = managerDataCache[currentMainCat]
			if currentSubCat == "[Main]" then
				currentData[name] = cleanId
			else
				currentData._subcategories[currentSubCat][name] = cleanId
			end
			saveManagerData(currentMainCat, currentData)
			AnimNameIn.Text = ""
			AnimIdIn.Text = ""
			updateAnimsList()
		end
	end)

	StopAnimBtn.MouseButton1Click:Connect(function()
		if activeTrack then
			activeTrack:Stop()
			activeTrack = nil
		end
	end)

	selectMainCat("R6")
end)

-- ==========================================
-- Anim Logger
-- ==========================================
AnimLoggerBtn.MouseButton1Click:Connect(function()
	if ScreenGui:FindFirstChild("AnimLoggerFrame") then return end
	local LoggerFrame = Instance.new("Frame")
	LoggerFrame.Name = "AnimLoggerFrame"
	LoggerFrame.Parent = ScreenGui
	LoggerFrame.BackgroundColor3 = Color3.fromRGB(164, 73, 163)
	LoggerFrame.Position = UDim2.new(MainFrame.Position.X.Scale, MainFrame.Position.X.Offset, MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset + 370)
	LoggerFrame.Size = UDim2.new(0, 350, 0, 130)
	LoggerFrame.Active = true
	LoggerFrame.Draggable = true
	Instance.new("UICorner", LoggerFrame).CornerRadius = UDim.new(0, 6)
	local TopBarL = Instance.new("Frame")
	TopBarL.Size = UDim2.new(1, 0, 0, 30)
	TopBarL.BackgroundColor3 = Color3.fromRGB(164, 73, 163)
	TopBarL.Parent = LoggerFrame
	Instance.new("UICorner", TopBarL).CornerRadius = UDim.new(0, 6)
	local ContainerL = Instance.new("Frame")
	ContainerL.Size = UDim2.new(1, 0, 1, -30)
	ContainerL.Position = UDim2.new(0, 0, 0, 30)
	ContainerL.BackgroundColor3 = Color3.fromRGB(164, 73, 163)
	ContainerL.ClipsDescendants = true
	ContainerL.Parent = LoggerFrame
	addSubMenuControls(LoggerFrame, TopBarL, ContainerL, "WdymGaming's anim logger", 130)
	local IdLabel = Instance.new("TextLabel")
	IdLabel.Parent = ContainerL
	IdLabel.Text = "Current Animation ID:"
	IdLabel.TextColor3 = Color3.fromRGB(77, 34, 77)
	IdLabel.Size = UDim2.new(1, -24, 0, 18)
	IdLabel.Position = UDim2.new(0, 12, 0, 8)
	IdLabel.Font = Enum.Font.SourceSansSemibold
	IdLabel.TextSize = 18
	IdLabel.TextXAlignment = Enum.TextXAlignment.Left
	IdLabel.BackgroundTransparency = 1
	local IdOutput = Instance.new("TextBox")
	IdOutput.Parent = ContainerL
	IdOutput.Text = interceptedIdText
	IdOutput.ClearTextOnFocus = false
	IdOutput.TextEditable = false
	IdOutput.Size = UDim2.new(1, -24, 0, 30)
	IdOutput.Position = UDim2.new(0, 12, 0, 30)
	IdOutput.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
	IdOutput.TextColor3 = Color3.fromRGB(196, 121, 196)
	IdOutput.BorderSizePixel = 0
	IdOutput.Font = Enum.Font.SourceSans
	IdOutput.TextSize = 16
	Instance.new("UICorner", IdOutput).CornerRadius = UDim.new(0, 4)
	task.spawn(function()
		while LoggerFrame and LoggerFrame.Parent do
			IdOutput.Text = interceptedIdText
			task.wait(0.2)
		end
	end)
end)

-- ==========================================
-- Keybinds
-- ==========================================
KeybindsBtn.MouseButton1Click:Connect(function()
	if ScreenGui:FindFirstChild("KeybindsFrame") then return end
	if keybindWaitForInput then
		keybindWaitForInput = false
		if onKeybindPressed then
			onKeybindPressed(nil)
			onKeybindPressed = nil
		end
	end
	local KeybindsFrame = Instance.new("Frame")
	KeybindsFrame.Name = "KeybindsFrame"
	KeybindsFrame.Parent = ScreenGui
	KeybindsFrame.BackgroundColor3 = Color3.fromRGB(164, 73, 163)
	KeybindsFrame.Position = UDim2.new(MainFrame.Position.X.Scale, MainFrame.Position.X.Offset + 260, MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset + 50)
	KeybindsFrame.Size = UDim2.new(0, 450, 0, 320)
	KeybindsFrame.Active = true
	KeybindsFrame.Draggable = true
	Instance.new("UICorner", KeybindsFrame).CornerRadius = UDim.new(0, 6)
	local TopBarK = Instance.new("Frame")
	TopBarK.Size = UDim2.new(1, 0, 0, 30)
	TopBarK.BackgroundColor3 = Color3.fromRGB(164, 73, 163)
	TopBarK.Parent = KeybindsFrame
	Instance.new("UICorner", TopBarK).CornerRadius = UDim.new(0, 6)
	local ContainerK = Instance.new("Frame")
	ContainerK.Size = UDim2.new(1, 0, 1, -30)
	ContainerK.Position = UDim2.new(0, 0, 0, 30)
	ContainerK.BackgroundColor3 = Color3.fromRGB(164, 73, 163)
	ContainerK.ClipsDescendants = true
	ContainerK.Parent = KeybindsFrame
	addSubMenuControls(KeybindsFrame, TopBarK, ContainerK, "Keybinds", 320)

	local currentType = "Animations"
	local currentAnimType = "Desync"
	local currentBodyType = "R6"
	local selectedDesyncAnim = nil
	local selectedNormalAnim = nil
	local tempKeyDesync = nil
	local tempKeyNormal = nil

	local function getAllKeybinds()
		local list = {}
		if keybinds.Menu and keybinds.Menu.key then
			table.insert(list, { type = "Menu", key = keybinds.Menu.key, path = {"Menu"}, data = keybinds.Menu })
		end
		if keybinds.Desync and keybinds.Desync.key then
			table.insert(list, { type = "Desync", key = keybinds.Desync.key, path = {"Desync"}, data = keybinds.Desync })
		end
		if keybinds.Animations then
			for i, bind in ipairs(keybinds.Animations) do
				if bind.key then
					table.insert(list, {
						type = "Anim " .. bind.type,
						key = bind.key,
						animName = bind.animName,
						bodyType = bind.bodyType,
						path = {"Animations", i},
						data = bind
					})
				end
			end
		end
		return list
	end

	local function refreshContent()
		for _, child in ipairs(ContainerK:GetChildren()) do
			if child.Name ~= "TypeLabel" and child.Name ~= "TypeDropdown" and child.Name ~= "TypeDropdownList" then
				child:Destroy()
			end
		end
		local yOffset = 40
		if currentType == "Animations" then
			local animTypeLabel = Instance.new("TextLabel")
			animTypeLabel.Name = "AnimTypeLabel"
			animTypeLabel.Parent = ContainerK
			animTypeLabel.Text = "Animation type:"
			animTypeLabel.TextColor3 = Color3.fromRGB(77, 34, 77)
			animTypeLabel.Size = UDim2.new(0, 120, 0, 20)
			animTypeLabel.Position = UDim2.new(0, 12, 0, yOffset)
			animTypeLabel.Font = Enum.Font.SourceSansSemibold
			animTypeLabel.TextSize = 16
			animTypeLabel.TextXAlignment = Enum.TextXAlignment.Left
			animTypeLabel.BackgroundTransparency = 1
			local animTypeDropdown = Instance.new("TextButton")
			animTypeDropdown.Name = "AnimTypeDropdown"
			animTypeDropdown.Parent = ContainerK
			animTypeDropdown.Text = currentAnimType .. " v"
			animTypeDropdown.Size = UDim2.new(0, 120, 0, 24)
			animTypeDropdown.Position = UDim2.new(0, 140, 0, yOffset - 2)
			animTypeDropdown.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
			animTypeDropdown.TextColor3 = Color3.fromRGB(196, 121, 196)
			animTypeDropdown.Font = Enum.Font.SourceSans
			animTypeDropdown.TextSize = 16
			Instance.new("UICorner", animTypeDropdown).CornerRadius = UDim.new(0, 4)
			local animTypeList = Instance.new("ScrollingFrame")
			animTypeList.Name = "AnimTypeList"
			animTypeList.Size = UDim2.new(0, 120, 0, 50)
			animTypeList.Position = UDim2.new(0, 140, 0, yOffset + 24)
			animTypeList.BackgroundColor3 = Color3.fromRGB(60, 25, 60)
			animTypeList.Visible = false
			animTypeList.ZIndex = 10
			animTypeList.ScrollBarThickness = 4
			animTypeList.Parent = ContainerK
			local layout = Instance.new("UIListLayout", animTypeList)
			local function fillAnimTypeList()
				for _, child in ipairs(animTypeList:GetChildren()) do
					if child:IsA("TextButton") then child:Destroy() end
				end
				local types = {"Desync", "Normal"}
				for _, t in ipairs(types) do
					local btn = Instance.new("TextButton")
					btn.Size = UDim2.new(1, 0, 0, 22)
					btn.BackgroundColor3 = Color3.fromRGB(80, 35, 80)
					btn.TextColor3 = Color3.fromRGB(255, 255, 255)
					btn.Text = t
					btn.Font = Enum.Font.SourceSans
					btn.TextSize = 14
					btn.ZIndex = 11
					btn.Parent = animTypeList
					btn.MouseButton1Click:Connect(function()
						currentAnimType = t
						animTypeDropdown.Text = t .. " v"
						animTypeList.Visible = false
						refreshContent()
					end)
				end
			end
			fillAnimTypeList()
			animTypeDropdown.MouseButton1Click:Connect(function()
				animTypeList.Visible = not animTypeList.Visible
			end)
			yOffset = yOffset + 32
			if currentAnimType == "Desync" then
				local searchBox = Instance.new("TextBox")
				searchBox.Name = "SearchBox"
				searchBox.Parent = ContainerK
				searchBox.PlaceholderText = "Search animation..."
				searchBox.Text = ""
				searchBox.Size = UDim2.new(1, -24, 0, 24)
				searchBox.Position = UDim2.new(0, 12, 0, yOffset)
				searchBox.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
				searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
				searchBox.PlaceholderColor3 = Color3.fromRGB(140, 100, 140)
				searchBox.Font = Enum.Font.SourceSans
				searchBox.TextSize = 14
				searchBox.ClearTextOnFocus = false
				Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 4)
				yOffset = yOffset + 28
				local animList = Instance.new("ScrollingFrame")
				animList.Name = "AnimList"
				animList.Size = UDim2.new(1, -24, 0, 90)
				animList.Position = UDim2.new(0, 12, 0, yOffset)
				animList.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
				animList.ScrollBarThickness = 4
				animList.Parent = ContainerK
				Instance.new("UICorner", animList).CornerRadius = UDim.new(0, 4)
				local listLayout = Instance.new("UIListLayout", animList)
				listLayout.Padding = UDim.new(0, 2)
				local function updateDesyncList(filter)
					for _, child in ipairs(animList:GetChildren()) do
						if child:IsA("TextButton") then child:Destroy() end
					end
					local count = 0
					for name, data in pairs(savedDesyncAnimations) do
						if data.frames then
							if filter == "" or string.find(string.lower(name), string.lower(filter), 1, true) then
								count = count + 1
								local btn = Instance.new("TextButton")
								btn.Size = UDim2.new(1, 0, 0, 22)
								btn.BackgroundColor3 = (selectedDesyncAnim == name) and Color3.fromRGB(164, 73, 163) or Color3.fromRGB(90, 40, 90)
								btn.TextColor3 = Color3.fromRGB(255, 255, 255)
								btn.Text = name
								btn.Font = Enum.Font.SourceSans
								btn.TextSize = 14
								btn.TextXAlignment = Enum.TextXAlignment.Left
								btn.Parent = animList
								btn.MouseButton1Click:Connect(function()
									selectedDesyncAnim = name
									updateDesyncList(searchBox.Text)
									if selectedLabelDesync then
										selectedLabelDesync.Text = "Selected: " .. name
									end
								end)
							end
						end
					end
					animList.CanvasSize = UDim2.new(0, 0, 0, count * 24)
				end
				searchBox:GetPropertyChangedSignal("Text"):Connect(function()
					updateDesyncList(searchBox.Text)
				end)
				local selectedLabelDesync = Instance.new("TextLabel")
				selectedLabelDesync.Name = "SelectedLabel"
				selectedLabelDesync.Parent = ContainerK
				selectedLabelDesync.Text = "Selected: " .. (selectedDesyncAnim or "none")
				selectedLabelDesync.Size = UDim2.new(1, -24, 0, 20)
				selectedLabelDesync.Position = UDim2.new(0, 12, 0, yOffset + 95)
				selectedLabelDesync.TextColor3 = Color3.fromRGB(77, 34, 77)
				selectedLabelDesync.Font = Enum.Font.SourceSansSemibold
				selectedLabelDesync.TextSize = 14
				selectedLabelDesync.TextXAlignment = Enum.TextXAlignment.Left
				selectedLabelDesync.BackgroundTransparency = 1
				yOffset = yOffset + 120
				local bindBtn = Instance.new("TextButton")
				bindBtn.Name = "BindBtn"
				bindBtn.Parent = ContainerK
				bindBtn.Text = "Bind: " .. (tempKeyDesync or "None")
				bindBtn.Size = UDim2.new(0, 120, 0, 28)
				bindBtn.Position = UDim2.new(0, 12, 0, yOffset)
				bindBtn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
				bindBtn.TextColor3 = Color3.fromRGB(196, 121, 196)
				bindBtn.Font = Enum.Font.SourceSansBold
				bindBtn.TextSize = 14
				Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0, 4)
				local saveBtn = Instance.new("TextButton")
				saveBtn.Name = "SaveBtn"
				saveBtn.Parent = ContainerK
				saveBtn.Text = "Save Bind"
				saveBtn.Size = UDim2.new(0, 100, 0, 28)
				saveBtn.Position = UDim2.new(0, 140, 0, yOffset)
				saveBtn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
				saveBtn.TextColor3 = Color3.fromRGB(196, 121, 196)
				saveBtn.Font = Enum.Font.SourceSansBold
				saveBtn.TextSize = 14
				Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 4)
				bindBtn.MouseButton1Click:Connect(function()
					keybindWaitForInput = true
					bindBtn.Text = "Press any key..."
					onKeybindPressed = function(key)
						keybindWaitForInput = false
						if key then
							bindBtn.Text = "Bind: " .. key
							tempKeyDesync = key
						else
							bindBtn.Text = "Bind: None"
							tempKeyDesync = nil
						end
						onKeybindPressed = nil
					end
				end)
				saveBtn.MouseButton1Click:Connect(function()
					if tempKeyDesync and selectedDesyncAnim then
						if not keybinds.Animations then keybinds.Animations = {} end
						table.insert(keybinds.Animations, {
							key = tempKeyDesync,
							type = "Desync",
							animName = selectedDesyncAnim,
							speed = 1.0,
							looped = false,
							reversed = false
						})
						saveKeybinds(keybinds)
						tempKeyDesync = nil
						bindBtn.Text = "Bind: None"
						saveBtn.Text = "Saved!"
						task.wait(0.5)
						saveBtn.Text = "Save Bind"
					else
						saveBtn.Text = "Error: Key & Anim"
						task.wait(1)
						saveBtn.Text = "Save Bind"
					end
				end)
				updateDesyncList("")
			elseif currentAnimType == "Normal" then
				local bodyTypeLabel = Instance.new("TextLabel")
				bodyTypeLabel.Name = "BodyTypeLabel"
				bodyTypeLabel.Parent = ContainerK
				bodyTypeLabel.Text = "Body type:"
				bodyTypeLabel.TextColor3 = Color3.fromRGB(77, 34, 77)
				bodyTypeLabel.Size = UDim2.new(0, 100, 0, 20)
				bodyTypeLabel.Position = UDim2.new(0, 12, 0, yOffset)
				bodyTypeLabel.Font = Enum.Font.SourceSansSemibold
				bodyTypeLabel.TextSize = 16
				bodyTypeLabel.TextXAlignment = Enum.TextXAlignment.Left
				bodyTypeLabel.BackgroundTransparency = 1
				local bodyTypeDropdown = Instance.new("TextButton")
				bodyTypeDropdown.Name = "BodyTypeDropdown"
				bodyTypeDropdown.Parent = ContainerK
				bodyTypeDropdown.Text = currentBodyType .. " v"
				bodyTypeDropdown.Size = UDim2.new(0, 80, 0, 24)
				bodyTypeDropdown.Position = UDim2.new(0, 120, 0, yOffset - 2)
				bodyTypeDropdown.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
				bodyTypeDropdown.TextColor3 = Color3.fromRGB(196, 121, 196)
				bodyTypeDropdown.Font = Enum.Font.SourceSans
				bodyTypeDropdown.TextSize = 16
				Instance.new("UICorner", bodyTypeDropdown).CornerRadius = UDim.new(0, 4)
				local bodyTypeList = Instance.new("ScrollingFrame")
				bodyTypeList.Name = "BodyTypeList"
				bodyTypeList.Size = UDim2.new(0, 80, 0, 46)
				bodyTypeList.Position = UDim2.new(0, 120, 0, yOffset + 24)
				bodyTypeList.BackgroundColor3 = Color3.fromRGB(60, 25, 60)
				bodyTypeList.Visible = false
				bodyTypeList.ZIndex = 10
				bodyTypeList.ScrollBarThickness = 4
				bodyTypeList.Parent = ContainerK
				local layout2 = Instance.new("UIListLayout", bodyTypeList)
				local function fillBodyTypeList()
					for _, child in ipairs(bodyTypeList:GetChildren()) do
						if child:IsA("TextButton") then child:Destroy() end
					end
					local types = {"R6", "R15"}
					for _, t in ipairs(types) do
						local btn = Instance.new("TextButton")
						btn.Size = UDim2.new(1, 0, 0, 22)
						btn.BackgroundColor3 = Color3.fromRGB(80, 35, 80)
						btn.TextColor3 = Color3.fromRGB(255, 255, 255)
						btn.Text = t
						btn.Font = Enum.Font.SourceSans
						btn.TextSize = 14
						btn.ZIndex = 11
						btn.Parent = bodyTypeList
						btn.MouseButton1Click:Connect(function()
							currentBodyType = t
							bodyTypeDropdown.Text = t .. " v"
							bodyTypeList.Visible = false
							refreshContent()
						end)
					end
				end
				fillBodyTypeList()
				bodyTypeDropdown.MouseButton1Click:Connect(function()
					bodyTypeList.Visible = not bodyTypeList.Visible
				end)
				yOffset = yOffset + 32
				local searchBox = Instance.new("TextBox")
				searchBox.Name = "SearchBox"
				searchBox.Parent = ContainerK
				searchBox.PlaceholderText = "Search animation..."
				searchBox.Text = ""
				searchBox.Size = UDim2.new(1, -24, 0, 24)
				searchBox.Position = UDim2.new(0, 12, 0, yOffset)
				searchBox.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
				searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
				searchBox.PlaceholderColor3 = Color3.fromRGB(140, 100, 140)
				searchBox.Font = Enum.Font.SourceSans
				searchBox.TextSize = 14
				searchBox.ClearTextOnFocus = false
				Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 4)
				yOffset = yOffset + 28
				local animList = Instance.new("ScrollingFrame")
				animList.Name = "AnimList"
				animList.Size = UDim2.new(1, -24, 0, 90)
				animList.Position = UDim2.new(0, 12, 0, yOffset)
				animList.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
				animList.ScrollBarThickness = 4
				animList.Parent = ContainerK
				Instance.new("UICorner", animList).CornerRadius = UDim.new(0, 4)
				local listLayout2 = Instance.new("UIListLayout", animList)
				listLayout2.Padding = UDim.new(0, 2)
				local function collectNormalAnimations(bodyType)
					local data = managerDataCache[bodyType]
					if not data then return {} end
					local anims = {}
					for name, id in pairs(data) do
						if name ~= "_subcategories" then
							anims[name] = id
						end
					end
					for subName, subTable in pairs(data._subcategories or {}) do
						for name, id in pairs(subTable) do
							anims[name] = id
						end
					end
					return anims
				end
				local function updateNormalList(filter)
					for _, child in ipairs(animList:GetChildren()) do
						if child:IsA("TextButton") then child:Destroy() end
					end
					local anims = collectNormalAnimations(currentBodyType)
					local count = 0
					for name, id in pairs(anims) do
						if filter == "" or string.find(string.lower(name), string.lower(filter), 1, true) then
							count = count + 1
							local btn = Instance.new("TextButton")
							btn.Size = UDim2.new(1, 0, 0, 22)
							btn.BackgroundColor3 = (selectedNormalAnim == name) and Color3.fromRGB(164, 73, 163) or Color3.fromRGB(90, 40, 90)
							btn.TextColor3 = Color3.fromRGB(255, 255, 255)
							btn.Text = name
							btn.Font = Enum.Font.SourceSans
							btn.TextSize = 14
							btn.TextXAlignment = Enum.TextXAlignment.Left
							btn.Parent = animList
							btn.MouseButton1Click:Connect(function()
								selectedNormalAnim = name
								updateNormalList(searchBox.Text)
								if selectedLabelNormal then
									selectedLabelNormal.Text = "Selected: " .. name
								end
							end)
						end
					end
					animList.CanvasSize = UDim2.new(0, 0, 0, count * 24)
				end
				searchBox:GetPropertyChangedSignal("Text"):Connect(function()
					updateNormalList(searchBox.Text)
				end)
				local selectedLabelNormal = Instance.new("TextLabel")
				selectedLabelNormal.Name = "SelectedLabel"
				selectedLabelNormal.Parent = ContainerK
				selectedLabelNormal.Text = "Selected: " .. (selectedNormalAnim or "none")
				selectedLabelNormal.Size = UDim2.new(1, -24, 0, 20)
				selectedLabelNormal.Position = UDim2.new(0, 12, 0, yOffset + 95)
				selectedLabelNormal.TextColor3 = Color3.fromRGB(77, 34, 77)
				selectedLabelNormal.Font = Enum.Font.SourceSansSemibold
				selectedLabelNormal.TextSize = 14
				selectedLabelNormal.TextXAlignment = Enum.TextXAlignment.Left
				selectedLabelNormal.BackgroundTransparency = 1
				yOffset = yOffset + 120
				local bindBtn = Instance.new("TextButton")
				bindBtn.Name = "BindBtn"
				bindBtn.Parent = ContainerK
				bindBtn.Text = "Bind: " .. (tempKeyNormal or "None")
				bindBtn.Size = UDim2.new(0, 120, 0, 28)
				bindBtn.Position = UDim2.new(0, 12, 0, yOffset)
				bindBtn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
				bindBtn.TextColor3 = Color3.fromRGB(196, 121, 196)
				bindBtn.Font = Enum.Font.SourceSansBold
				bindBtn.TextSize = 14
				Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0, 4)
				local saveBtn = Instance.new("TextButton")
				saveBtn.Name = "SaveBtn"
				saveBtn.Parent = ContainerK
				saveBtn.Text = "Save Bind"
				saveBtn.Size = UDim2.new(0, 100, 0, 28)
				saveBtn.Position = UDim2.new(0, 140, 0, yOffset)
				saveBtn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
				saveBtn.TextColor3 = Color3.fromRGB(196, 121, 196)
				saveBtn.Font = Enum.Font.SourceSansBold
				saveBtn.TextSize = 14
				Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 4)
				bindBtn.MouseButton1Click:Connect(function()
					keybindWaitForInput = true
					bindBtn.Text = "Press any key..."
					onKeybindPressed = function(key)
						keybindWaitForInput = false
						if key then
							bindBtn.Text = "Bind: " .. key
							tempKeyNormal = key
						else
							bindBtn.Text = "Bind: None"
							tempKeyNormal = nil
						end
						onKeybindPressed = nil
					end
				end)
				saveBtn.MouseButton1Click:Connect(function()
					if tempKeyNormal and selectedNormalAnim then
						if not keybinds.Animations then keybinds.Animations = {} end
						table.insert(keybinds.Animations, {
							key = tempKeyNormal,
							type = "Normal",
							animName = selectedNormalAnim,
							bodyType = currentBodyType,
							speed = 1.0,
							looped = false,
							reversed = false
						})
						saveKeybinds(keybinds)
						tempKeyNormal = nil
						bindBtn.Text = "Bind: None"
						saveBtn.Text = "Saved!"
						task.wait(0.5)
						saveBtn.Text = "Save Bind"
					else
						saveBtn.Text = "Error: Key & Anim"
						task.wait(1)
						saveBtn.Text = "Save Bind"
					end
				end)
				updateNormalList("")
			end
		elseif currentType == "Desync" then
			local infoLabel = Instance.new("TextLabel")
			infoLabel.Parent = ContainerK
			infoLabel.Text = "Toggle Desync mode"
			infoLabel.Size = UDim2.new(1, -24, 0, 20)
			infoLabel.Position = UDim2.new(0, 12, 0, yOffset)
			infoLabel.TextColor3 = Color3.fromRGB(77, 34, 77)
			infoLabel.Font = Enum.Font.SourceSansSemibold
			infoLabel.TextSize = 16
			infoLabel.TextXAlignment = Enum.TextXAlignment.Left
			infoLabel.BackgroundTransparency = 1
			yOffset = yOffset + 28
			local bindBtn = Instance.new("TextButton")
			bindBtn.Name = "BindBtn"
			bindBtn.Parent = ContainerK
			local currentKey = keybinds.Desync and keybinds.Desync.key or "None"
			bindBtn.Text = "Bind: " .. currentKey
			bindBtn.Size = UDim2.new(0, 120, 0, 28)
			bindBtn.Position = UDim2.new(0, 12, 0, yOffset)
			bindBtn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
			bindBtn.TextColor3 = Color3.fromRGB(196, 121, 196)
			bindBtn.Font = Enum.Font.SourceSansBold
			bindBtn.TextSize = 14
			Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0, 4)
			local saveBtn = Instance.new("TextButton")
			saveBtn.Name = "SaveBtn"
			saveBtn.Parent = ContainerK
			saveBtn.Text = "Save Bind"
			saveBtn.Size = UDim2.new(0, 100, 0, 28)
			saveBtn.Position = UDim2.new(0, 140, 0, yOffset)
			saveBtn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
			saveBtn.TextColor3 = Color3.fromRGB(196, 121, 196)
			saveBtn.Font = Enum.Font.SourceSansBold
			saveBtn.TextSize = 14
			Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 4)
			bindBtn.MouseButton1Click:Connect(function()
				keybindWaitForInput = true
				bindBtn.Text = "Press any key..."
				onKeybindPressed = function(key)
					keybindWaitForInput = false
					if key then
						bindBtn.Text = "Bind: " .. key
						if not keybinds.Desync then keybinds.Desync = {} end
						keybinds.Desync.key = key
					else
						bindBtn.Text = "Bind: None"
					end
					onKeybindPressed = nil
				end
			end)
			saveBtn.MouseButton1Click:Connect(function()
				saveKeybinds(keybinds)
				saveBtn.Text = "Saved!"
				task.wait(0.5)
				saveBtn.Text = "Save Bind"
			end)
		elseif currentType == "Menu" then
			local infoLabel = Instance.new("TextLabel")
			infoLabel.Parent = ContainerK
			infoLabel.Text = "Show/Hide Main Menu"
			infoLabel.Size = UDim2.new(1, -24, 0, 20)
			infoLabel.Position = UDim2.new(0, 12, 0, yOffset)
			infoLabel.TextColor3 = Color3.fromRGB(77, 34, 77)
			infoLabel.Font = Enum.Font.SourceSansSemibold
			infoLabel.TextSize = 16
			infoLabel.TextXAlignment = Enum.TextXAlignment.Left
			infoLabel.BackgroundTransparency = 1
			yOffset = yOffset + 28
			local bindBtn = Instance.new("TextButton")
			bindBtn.Name = "BindBtn"
			bindBtn.Parent = ContainerK
			local currentKey = keybinds.Menu and keybinds.Menu.key or "None"
			bindBtn.Text = "Bind: " .. currentKey
			bindBtn.Size = UDim2.new(0, 120, 0, 28)
			bindBtn.Position = UDim2.new(0, 12, 0, yOffset)
			bindBtn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
			bindBtn.TextColor3 = Color3.fromRGB(196, 121, 196)
			bindBtn.Font = Enum.Font.SourceSansBold
			bindBtn.TextSize = 14
			Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0, 4)
			local saveBtn = Instance.new("TextButton")
			saveBtn.Name = "SaveBtn"
			saveBtn.Parent = ContainerK
			saveBtn.Text = "Save Bind"
			saveBtn.Size = UDim2.new(0, 100, 0, 28)
			saveBtn.Position = UDim2.new(0, 140, 0, yOffset)
			saveBtn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
			saveBtn.TextColor3 = Color3.fromRGB(196, 121, 196)
			saveBtn.Font = Enum.Font.SourceSansBold
			saveBtn.TextSize = 14
			Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 4)
			bindBtn.MouseButton1Click:Connect(function()
				keybindWaitForInput = true
				bindBtn.Text = "Press any key..."
				onKeybindPressed = function(key)
					keybindWaitForInput = false
					if key then
						bindBtn.Text = "Bind: " .. key
						if not keybinds.Menu then keybinds.Menu = {} end
						keybinds.Menu.key = key
					else
						bindBtn.Text = "Bind: None"
					end
					onKeybindPressed = nil
				end
			end)
			saveBtn.MouseButton1Click:Connect(function()
				saveKeybinds(keybinds)
				saveBtn.Text = "Saved!"
				task.wait(0.5)
				saveBtn.Text = "Save Bind"
			end)
		elseif currentType == "View all keybinds" then
			local infoLabel = Instance.new("TextLabel")
			infoLabel.Parent = ContainerK
			infoLabel.Text = "Assigned Keybinds:"
			infoLabel.Size = UDim2.new(1, -24, 0, 20)
			infoLabel.Position = UDim2.new(0, 12, 0, yOffset)
			infoLabel.TextColor3 = Color3.fromRGB(77, 34, 77)
			infoLabel.Font = Enum.Font.SourceSansSemibold
			infoLabel.TextSize = 16
			infoLabel.TextXAlignment = Enum.TextXAlignment.Left
			infoLabel.BackgroundTransparency = 1
			yOffset = yOffset + 24
			local scrollFrame = Instance.new("ScrollingFrame")
			scrollFrame.Name = "AllKeybindsList"
			scrollFrame.Parent = ContainerK
			scrollFrame.Size = UDim2.new(1, -24, 1, -yOffset - 10)
			scrollFrame.Position = UDim2.new(0, 12, 0, yOffset)
			scrollFrame.BackgroundColor3 = Color3.fromRGB(60, 25, 60)
			scrollFrame.ScrollBarThickness = 4
			scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
			Instance.new("UICorner", scrollFrame).CornerRadius = UDim.new(0, 4)
			local listLayout = Instance.new("UIListLayout", scrollFrame)
			listLayout.Padding = UDim.new(0, 4)
			local keybindsList = getAllKeybinds()
			local totalHeight = 0
			for _, kb in ipairs(keybindsList) do
				local rowHeight = kb.type:find("Anim") and 46 or 24
				local row = Instance.new("Frame")
				row.Size = UDim2.new(1, -10, 0, rowHeight)
				row.BackgroundColor3 = Color3.fromRGB(90, 40, 90)
				row.BorderSizePixel = 0
				row.Parent = scrollFrame
				Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)
				local descText = string.format("%s [%s]", kb.type, kb.key)
				if kb.animName then
					descText = descText .. string.format(" -> %s%s", kb.animName, kb.bodyType and (" (" .. kb.bodyType .. ")") or "")
				end
				local desc = Instance.new("TextLabel")
				desc.Text = descText
				desc.Size = UDim2.new(1, -60, 0, 20)
				desc.Position = UDim2.new(0, 5, 0, 2)
				desc.BackgroundTransparency = 1
				desc.TextColor3 = Color3.fromRGB(255, 255, 255)
				desc.TextXAlignment = Enum.TextXAlignment.Left
				desc.TextTruncate = Enum.TextTruncate.AtEnd
				desc.Font = Enum.Font.SourceSans
				desc.TextSize = 14
				desc.Parent = row
				local delBtn = Instance.new("TextButton")
				delBtn.Text = "Delete"
				delBtn.Size = UDim2.new(0, 50, 0, 18)
				delBtn.Position = UDim2.new(1, -55, 0, 3)
				delBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
				delBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
				delBtn.Font = Enum.Font.SourceSansBold
				delBtn.TextSize = 12
				Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 4)
				delBtn.Parent = row
				delBtn.MouseButton1Click:Connect(function()
					local target = keybinds
					for i = 1, #kb.path - 1 do target = target[kb.path[i]] end
					local lastKey = kb.path[#kb.path]
					if type(lastKey) == "number" then
						table.remove(target, lastKey)
					else
						target[lastKey] = nil
					end
					saveKeybinds(keybinds)
					refreshContent()
				end)
				if kb.type:find("Anim") then
					local spdLabel = Instance.new("TextLabel")
					spdLabel.Text = "Spd:"
					spdLabel.Size = UDim2.new(0, 30, 0, 18)
					spdLabel.Position = UDim2.new(0, 5, 0, 24)
					spdLabel.BackgroundTransparency = 1
					spdLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
					spdLabel.TextXAlignment = Enum.TextXAlignment.Left
					spdLabel.Font = Enum.Font.SourceSans
					spdLabel.TextSize = 12
					spdLabel.Parent = row
					local spdInput = Instance.new("TextBox")
					spdInput.Text = tostring(kb.data.speed or 1.0)
					spdInput.Size = UDim2.new(0, 35, 0, 18)
					spdInput.Position = UDim2.new(0, 35, 0, 24)
					spdInput.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
					spdInput.TextColor3 = Color3.fromRGB(255, 255, 255)
					spdInput.Font = Enum.Font.SourceSans
					spdInput.TextSize = 12
					spdInput.ClearTextOnFocus = false
					Instance.new("UICorner", spdInput).CornerRadius = UDim.new(0, 4)
					spdInput.Parent = row
					spdInput.FocusLost:Connect(function()
						local val = tonumber(spdInput.Text)
						if val then
							kb.data.speed = val
							saveKeybinds(keybinds)
						end
					end)
					local loopBtn = Instance.new("TextButton")
					local isLooped = kb.data.looped or false
					loopBtn.Text = "Loop"
					loopBtn.TextColor3 = isLooped and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
					loopBtn.Size = UDim2.new(0, 45, 0, 18)
					loopBtn.Position = UDim2.new(0, 75, 0, 24)
					loopBtn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
					loopBtn.Font = Enum.Font.SourceSansBold
					loopBtn.TextSize = 12
					Instance.new("UICorner", loopBtn).CornerRadius = UDim.new(0, 4)
					loopBtn.Parent = row
					loopBtn.MouseButton1Click:Connect(function()
						isLooped = not isLooped
						kb.data.looped = isLooped
						loopBtn.TextColor3 = isLooped and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
						saveKeybinds(keybinds)
					end)
					local revBtn = Instance.new("TextButton")
					local isReversed = kb.data.reversed or false
					revBtn.Text = "Rev"
					revBtn.TextColor3 = isReversed and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
					revBtn.Size = UDim2.new(0, 45, 0, 18)
					revBtn.Position = UDim2.new(0, 125, 0, 24)
					revBtn.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
					revBtn.Font = Enum.Font.SourceSansBold
					revBtn.TextSize = 12
					Instance.new("UICorner", revBtn).CornerRadius = UDim.new(0, 4)
					revBtn.Parent = row
					revBtn.MouseButton1Click:Connect(function()
						isReversed = not isReversed
						kb.data.reversed = isReversed
						revBtn.TextColor3 = isReversed and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
						saveKeybinds(keybinds)
					end)
				end
				totalHeight = totalHeight + rowHeight + 4
			end
			scrollFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
		end
	end

	local TypeLabel = Instance.new("TextLabel")
	TypeLabel.Name = "TypeLabel"
	TypeLabel.Parent = ContainerK
	TypeLabel.Text = "Category:"
	TypeLabel.TextColor3 = Color3.fromRGB(77, 34, 77)
	TypeLabel.Size = UDim2.new(0, 80, 0, 20)
	TypeLabel.Position = UDim2.new(0, 12, 0, 10)
	TypeLabel.Font = Enum.Font.SourceSansSemibold
	TypeLabel.TextSize = 16
	TypeLabel.TextXAlignment = Enum.TextXAlignment.Left
	TypeLabel.BackgroundTransparency = 1

	local TypeDropdown = Instance.new("TextButton")
	TypeDropdown.Name = "TypeDropdown"
	TypeDropdown.Parent = ContainerK
	TypeDropdown.Text = currentType .. " v"
	TypeDropdown.Size = UDim2.new(0, 150, 0, 24)
	TypeDropdown.Position = UDim2.new(0, 100, 0, 8)
	TypeDropdown.BackgroundColor3 = Color3.fromRGB(77, 34, 77)
	TypeDropdown.TextColor3 = Color3.fromRGB(196, 121, 196)
	TypeDropdown.Font = Enum.Font.SourceSans
	TypeDropdown.TextSize = 16
	Instance.new("UICorner", TypeDropdown).CornerRadius = UDim.new(0, 4)

	local TypeDropdownList = Instance.new("ScrollingFrame")
	TypeDropdownList.Name = "TypeDropdownList"
	TypeDropdownList.Size = UDim2.new(0, 150, 0, 100)
	TypeDropdownList.Position = UDim2.new(0, 100, 0, 32)
	TypeDropdownList.BackgroundColor3 = Color3.fromRGB(60, 25, 60)
	TypeDropdownList.Visible = false
	TypeDropdownList.ZIndex = 15
	TypeDropdownList.ScrollBarThickness = 4
	TypeDropdownList.Parent = ContainerK
	Instance.new("UIListLayout", TypeDropdownList)

	local categories = {"Animations", "Desync", "Menu", "View all keybinds"}
	for _, catName in ipairs(categories) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 22)
		btn.BackgroundColor3 = Color3.fromRGB(80, 35, 80)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Text = catName
		btn.Font = Enum.Font.SourceSans
		btn.TextSize = 14
		btn.ZIndex = 16
		btn.Parent = TypeDropdownList
		btn.MouseButton1Click:Connect(function()
			currentType = catName
			TypeDropdown.Text = catName .. " v"
			TypeDropdownList.Visible = false
			refreshContent()
		end)
	end
	TypeDropdown.MouseButton1Click:Connect(function()
		TypeDropdownList.Visible = not TypeDropdownList.Visible
	end)
	refreshContent()
end)

-- ==========================================
-- АНИМАЦИОННЫЙ ЛОГГЕР (перехват анимаций)
-- ==========================================
local function trackAnimator(animator)
	animator.AnimationPlayed:Connect(function(animationTrack)
		if not isRunning then return end
		local animId = animationTrack.Animation.AnimationId
		interceptedIdText = tostring(animId)
		print("[Anim Logger] Intercepted ID: " .. tostring(animId))
	end)
end

local function initCharacter(character)
	if not character then return end
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid then
		local animator = humanoid:WaitForChild("Animator", 10)
		if animator then trackAnimator(animator) end
	end
end

local function OnCharacterAdded(char)
	c = char
	animationPlaying = false
	local hum = char:WaitForChild("Humanoid", 5)
	if hum then
		if CharDeathConn then CharDeathConn:Disconnect() end
		CharDeathConn = hum.Died:Connect(function()
			StopDesync()
		end)
	end
	if IsDesynced then
		StopDesync()
		task.wait(0.15)
		StartDesync()
	end
	initCharacter(char)
end

lp.CharacterAdded:Connect(OnCharacterAdded)
if lp.Character then OnCharacterAdded(lp.Character) end

-- Минимизация главного окна
local minimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		Container:TweenSize(UDim2.new(1, 0, 0, 0), "InOut", "Quad", 0.2, true)
		MainFrame:TweenSize(UDim2.new(0, 250, 0, 32), "InOut", "Quad", 0.2, true)
		MinimizeBtn.Text = "+"
	else
		Container:TweenSize(UDim2.new(1, 0, 1, -32), "InOut", "Quad", 0.2, true)
		MainFrame:TweenSize(UDim2.new(0, 250, 0, 430), "InOut", "Quad", 0.2, true)
		MinimizeBtn.Text = "-"
	end
end)

CloseBtn.MouseButton1Click:Connect(function()
	isRunning = false
	animationPlaying = false
	StopDesync()
	if CharDeathConn then CharDeathConn:Disconnect() end
	ScreenGui:Destroy()
end)