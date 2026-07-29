---@diagnostic disable: undefined-global
-- Ожидание загрузки игрока
if not game:GetService("Players").LocalPlayer then
    game:GetService("Players"):GetPropertyChangedSignal("LocalPlayer"):Wait()
end
local Player = game:GetService("Players").LocalPlayer
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

-- Переменные состояния скрипта
local ScriptActive = true
local ToggleState = true

-- Создание папки для хранения файлов
if makefolder then
    pcall(function()
        makefolder("EmilyUi")
        makefolder("EmilyUi/Music")
    end)
end

-- Пути к файлам конфигурации
local jsonFileName = "EmilyUi/Music/EmilyUiMusic.json"
local settingsFileName = "EmilyUi/Music/EmilyUiMusicSettings.json"
local grabberFile = "EmilyUi/Music/EmilyUiMusicGrabber.json"
local blacklistFile = "EmilyUi/Music/EmilyUiMusicGrabberBlackList.json"

local MusicGuiRework = Instance.new("ScreenGui")
local TopBar = Instance.new("Frame")
local Container = Instance.new("Frame")
local PickerFrame = Instance.new("Frame")
local line = Instance.new("TextLabel")
local home = Instance.new("TextButton")
local music = Instance.new("TextButton")
local settings = Instance.new("TextButton")
local grabberBtn = Instance.new("TextButton")
local toggleScriptBtn = Instance.new("TextButton")
local Shadow = Instance.new("ImageLabel")
local musicFrame = Instance.new("ScrollingFrame")
local homeFrame = Instance.new("Frame")
local PlayBtn = Instance.new("TextButton")
local Pitch = Instance.new("TextBox")
local Volume = Instance.new("TextBox")
local SoundId = Instance.new("TextBox")
local StopBtn = Instance.new("TextButton")
local SoundPlaying = Instance.new("Frame")
local TimePos = Instance.new("TextLabel")
local TimeLen = Instance.new("TextLabel")
local Playing = Instance.new("TextLabel")
local Line = Instance.new("TextButton")
local Line_2 = Instance.new("TextLabel")
local settingsFrame = Instance.new("Frame")
local partsSetting = Instance.new("TextBox")
local materialBtn = Instance.new("TextButton")
local transSetting = Instance.new("TextBox")
local disposSetting = Instance.new("TextBox")
local splitSetting = Instance.new("TextBox")
local bodySetting = Instance.new("TextBox")
local powerSetting = Instance.new("TextBox")
local angleSetting = Instance.new("TextBox")
local angleSetting_2 = Instance.new("TextBox")
-- Элементы управления цветом
local colorSetting = Instance.new("TextBox")
local rainbowToggleBtn = Instance.new("TextButton")
local materialFrame = Instance.new("Frame")
local Shadow_2 = Instance.new("ImageLabel")
local materialPicker = Instance.new("ScrollingFrame")
local CloseButton = Instance.new("TextButton")
local TextLabel = Instance.new("TextLabel")
local MinimizeButton = Instance.new("TextButton")
-- Поле поиска для вкладки Music
local musicSearchBox = Instance.new("TextBox")
local searchQuery = ""

MusicGuiRework.Name = "Music Gui Rework"
MusicGuiRework.Parent = Player:WaitForChild("PlayerGui")
MusicGuiRework.ResetOnSpawn = false

TopBar.Name = "TopBar"
TopBar.Parent = MusicGuiRework
TopBar.Active = true
TopBar.AnchorPoint = Vector2.new(0.5, 0.5)
TopBar.BackgroundColor3 = Color3.new(0.121569, 0.121569, 0.121569)
TopBar.BorderSizePixel = 0
TopBar.Draggable = true
TopBar.Position = UDim2.new(0.5, 0, 0.35, 0)
TopBar.Size = UDim2.new(0, 430, 0, 27)
TopBar.ZIndex = 4

-- Увеличена высота GUI на 1.5х (было 176 стало 350)
local containerHeight = 350
Container.Name = "Container"
Container.Parent = TopBar
Container.AnchorPoint = Vector2.new(0.5, 0)
Container.BackgroundColor3 = Color3.new(0.156863, 0.156863, 0.156863)
Container.BorderSizePixel = 0
Container.Position = UDim2.new(0.5, 0, 0, 0)
Container.Size = UDim2.new(1, 0, 2, containerHeight)
Container.ZIndex = 2
Container.ClipsDescendants = true

PickerFrame.Name = "PickerFrame"
PickerFrame.Parent = Container
PickerFrame.AnchorPoint = Vector2.new(0.5, 0)
PickerFrame.BackgroundColor3 = Color3.new(0.137255, 0.137255, 0.137255)
PickerFrame.Position = UDim2.new(0.5, 0, 0.05, 0)
PickerFrame.Size = UDim2.new(1, 0, 0, 26)
PickerFrame.ZIndex = 3

line.Name = "line"
line.Parent = PickerFrame
line.BackgroundColor3 = Color3.new(0.784314, 0.784314, 0.784314)
line.Position = UDim2.new(0.02, 0, 1, -3)
line.Size = UDim2.new(0, 36, 0, 2)
line.ZIndex = 3
line.Font = Enum.Font.SourceSans
line.Text = ""
line.TextSize = 14

local function setupTopMenuBtn(btn, name, text, xScale, xOffset, width)
    btn.Name = name
    btn.Parent = PickerFrame
    btn.BackgroundTransparency = 1
    btn.Position = UDim2.new(xScale, xOffset, 0, 0)
    btn.Size = UDim2.new(0, width, 0, 26)
    btn.ZIndex = 3
    btn.Font = Enum.Font.SourceSansSemibold
    btn.Text = text
    btn.TextColor3 = Color3.new(0.784314, 0.784314, 0.784314)
    btn.TextSize = 15
    btn.TextWrapped = true
end

setupTopMenuBtn(home, "home", "HOME", 0.02, 0, 40)
setupTopMenuBtn(music, "music", "MUSIC", 0.13, 0, 45)
setupTopMenuBtn(settings, "settings", "SETTINGS", 0.25, 0, 60)
setupTopMenuBtn(grabberBtn, "grabber", "GRABBER", 0.41, 0, 60)
setupTopMenuBtn(toggleScriptBtn, "toggle", "TOGGLE: ON", 0.78, 0, 80)
toggleScriptBtn.TextColor3 = Color3.fromRGB(100, 220, 100)

Shadow.Name = "Shadow"
Shadow.Parent = Container
Shadow.BackgroundColor3 = Color3.new(1, 1, 1)
Shadow.BackgroundTransparency = 1
Shadow.Position = UDim2.new(0, -5, 0, -5)
Shadow.Size = UDim2.new(1, 10, 1, 10)
Shadow.ZIndex = 2
Shadow.Image = "rbxassetid://892210479"
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(6, 6, 25, 25)

-- Поле поиска на вкладке MUSIC (ИСПРАВЛЕНО ПОЗИЦИОНИРОВАНИЕ)
musicSearchBox.Name = "musicSearchBox"
musicSearchBox.Parent = Container
musicSearchBox.BackgroundColor3 = Color3.new(0.121569, 0.121569, 0.121569)
musicSearchBox.BorderColor3 = Color3.new(0.392157, 0.392157, 0.392157)
musicSearchBox.Position = UDim2.new(0, 5, 0, 50) -- Фиксированная позиция сверху
musicSearchBox.Size = UDim2.new(0, 420, 0, 24)
musicSearchBox.Visible = false
musicSearchBox.ZIndex = 3
musicSearchBox.Font = Enum.Font.SourceSans
musicSearchBox.PlaceholderText = "Search ID / Name..."
musicSearchBox.Text = ""
musicSearchBox.TextColor3 = Color3.new(0.784314, 0.784314, 0.784314)
musicSearchBox.TextSize = 14
musicSearchBox.ClearTextOnFocus = false

-- Пропорционально увеличен размер списков под новую высоту
local listHeight = 250
local categoryFrame = Instance.new("ScrollingFrame")
categoryFrame.Name = "categoryFrame"
categoryFrame.Parent = Container
categoryFrame.BackgroundTransparency = 1
categoryFrame.BorderSizePixel = 0
categoryFrame.Position = UDim2.new(0, 5, 0, 80)
categoryFrame.Size = UDim2.new(0, 95, 0, listHeight)
categoryFrame.Visible = false
categoryFrame.ZIndex = 3
categoryFrame.ScrollBarThickness = 2
categoryFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

musicFrame.Name = "musicFrame"
musicFrame.Parent = Container
musicFrame.BackgroundColor3 = Color3.new(1, 1, 1)
musicFrame.BackgroundTransparency = 1
musicFrame.BorderSizePixel = 0
musicFrame.Position = UDim2.new(0, 105, 0, 70)
musicFrame.Size = UDim2.new(0, 320, 0, listHeight)
musicFrame.Visible = false
musicFrame.ZIndex = 3
musicFrame.ScrollBarThickness = 4
musicFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

local musicControls = Instance.new("Frame")
musicControls.Name = "MusicControls"
musicControls.Parent = Container
musicControls.BackgroundTransparency = 1
musicControls.Position = UDim2.new(0, 0, 0, 70 + listHeight)
musicControls.Size = UDim2.new(1, 0, 0, 35)
musicControls.Visible = false
musicControls.ZIndex = 3

local function createControlBtn(name, text, xOffset, width, color, parent)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Parent = parent or musicControls
    btn.BackgroundColor3 = color or Color3.fromRGB(31, 31, 31)
    btn.BorderColor3 = Color3.fromRGB(60, 60, 60)
    btn.Size = UDim2.new(0, width, 0, 26)
    btn.Position = UDim2.new(0, xOffset, 0, 2)
    btn.Font = Enum.Font.SourceSansSemibold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Text = text
    btn.ZIndex = 4
    return btn
end

local addBtn = createControlBtn("AddBtn", "ADD", 5, 75, Color3.fromRGB(40, 70, 40))
local editBtn = createControlBtn("EditBtn", "EDIT", 85, 75, Color3.fromRGB(50, 50, 70))
local deleteBtn = createControlBtn("DeleteBtn", "DELETE", 165, 75, Color3.fromRGB(70, 40, 40))
local newCatBtn = createControlBtn("NewCatBtn", "+ CAT", 245, 70, Color3.fromRGB(60, 60, 60))
local delCatBtn = createControlBtn("DelCatBtn", "- CAT", 320, 70, Color3.fromRGB(45, 45, 45))

local grabberFrame = Instance.new("ScrollingFrame")
grabberFrame.Name = "grabberFrame"
grabberFrame.Parent = Container
grabberFrame.BackgroundTransparency = 1
grabberFrame.BorderSizePixel = 0
grabberFrame.Position = UDim2.new(0, 5, 0, 40)
grabberFrame.Size = UDim2.new(0, 420, 0, listHeight + 25)
grabberFrame.Visible = false
grabberFrame.ZIndex = 3
grabberFrame.ScrollBarThickness = 4

local grabberControls = Instance.new("Frame")
grabberControls.Name = "GrabberControls"
grabberControls.Parent = Container
grabberControls.BackgroundTransparency = 1
grabberControls.Position = UDim2.new(0, 0, 0, 70 + listHeight)
grabberControls.Size = UDim2.new(1, 0, 0, 35)
grabberControls.Visible = false
grabberControls.ZIndex = 3

local gStartBtn = createControlBtn("GStartBtn", "START", 10, 90, Color3.fromRGB(40, 70, 40), grabberControls)
local gScanBtn = createControlBtn("GScanBtn", "SCAN", 110, 100, Color3.fromRGB(40, 55, 70), grabberControls)
local gDeleteBtn = createControlBtn("GDeleteBtn", "DELETE", 220, 90, Color3.fromRGB(70, 40, 40), grabberControls)
local gBlacklistBtn = createControlBtn("GBlacklistBtn", "BLACKLIST", 320, 95, Color3.fromRGB(45, 45, 45), grabberControls)

local grabbedIds = {}
local blacklistedIds = {}
local selectedGrabbedId = ""
local isGrabberScanning = false
local scanConnection = nil
local isScanningLogicRunning = false

local addMenuFrame = Instance.new("Frame")
addMenuFrame.Name = "AddMenuFrame"
addMenuFrame.Parent = Container
addMenuFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
addMenuFrame.BorderSizePixel = 1
addMenuFrame.BorderColor3 = Color3.fromRGB(50, 50, 50)
addMenuFrame.Position = UDim2.new(0.05, 0, 0.15, 0)
addMenuFrame.Size = UDim2.new(0.9, 0, 0.75, 0)
addMenuFrame.Visible = false
addMenuFrame.ZIndex = 10

local addMenuTitle = Instance.new("TextLabel")
addMenuTitle.Parent = addMenuFrame
addMenuTitle.Size = UDim2.new(1, 0, 0.12, 0)
addMenuTitle.BackgroundTransparency = 1
addMenuTitle.Font = Enum.Font.SourceSansSemibold
addMenuTitle.Text = "TRACK EDITOR"
addMenuTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
addMenuTitle.TextSize = 15
addMenuTitle.ZIndex = 11

local inputId = Instance.new("TextBox")
inputId.Parent = addMenuFrame
inputId.PlaceholderText = "Sound ID"
inputId.Text = ""
inputId.Size = UDim2.new(0.45, 0, 0.15, 0)
inputId.Position = UDim2.new(0.04, 0, 0.15, 0)
inputId.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
inputId.TextColor3 = Color3.fromRGB(250, 250, 250)
inputId.Font = Enum.Font.SourceSans
inputId.TextSize = 14
inputId.ZIndex = 11
inputId.ClearTextOnFocus = false

local inputName = Instance.new("TextBox")
inputName.Parent = addMenuFrame
inputName.PlaceholderText = "Track Name"
inputName.Text = ""
inputName.Size = UDim2.new(0.45, 0, 0.15, 0)
inputName.Position = UDim2.new(0.51, 0, 0.15, 0)
inputName.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
inputName.TextColor3 = Color3.fromRGB(250, 250, 250)
inputName.Font = Enum.Font.SourceSans
inputName.TextSize = 14
inputName.ZIndex = 11
inputName.ClearTextOnFocus = false

local inputVol = Instance.new("TextBox")
inputVol.Parent = addMenuFrame
inputVol.PlaceholderText = "Volume (e.g. 1)"
inputVol.Text = "1"
inputVol.Size = UDim2.new(0.45, 0, 0.15, 0)
inputVol.Position = UDim2.new(0.04, 0, 0.35, 0)
inputVol.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
inputVol.TextColor3 = Color3.fromRGB(250, 250, 250)
inputVol.Font = Enum.Font.SourceSans
inputVol.TextSize = 14
inputVol.ZIndex = 11
inputVol.ClearTextOnFocus = false

local inputPitch = Instance.new("TextBox")
inputPitch.Parent = addMenuFrame
inputPitch.PlaceholderText = "Pitch (e.g. 1)"
inputPitch.Text = "1"
inputPitch.Size = UDim2.new(0.45, 0, 0.15, 0)
inputPitch.Position = UDim2.new(0.51, 0, 0.35, 0)
inputPitch.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
inputPitch.TextColor3 = Color3.fromRGB(250, 250, 250)
inputPitch.Font = Enum.Font.SourceSans
inputPitch.TextSize = 14
inputPitch.ZIndex = 11
inputPitch.ClearTextOnFocus = false

local inputStart = Instance.new("TextBox")
inputStart.Parent = addMenuFrame
inputStart.PlaceholderText = "Start Time (sec)"
inputStart.Text = "0"
inputStart.Size = UDim2.new(0.45, 0, 0.15, 0)
inputStart.Position = UDim2.new(0.04, 0, 0.55, 0)
inputStart.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
inputStart.TextColor3 = Color3.fromRGB(250, 250, 250)
inputStart.Font = Enum.Font.SourceSans
inputStart.TextSize = 14
inputStart.ZIndex = 11
inputStart.ClearTextOnFocus = false

local inputEnd = Instance.new("TextBox")
inputEnd.Parent = addMenuFrame
inputEnd.PlaceholderText = "End Time (0 = Max)"
inputEnd.Text = "0"
inputEnd.Size = UDim2.new(0.45, 0, 0.15, 0)
inputEnd.Position = UDim2.new(0.51, 0, 0.55, 0)
inputEnd.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
inputEnd.TextColor3 = Color3.fromRGB(250, 250, 250)
inputEnd.Font = Enum.Font.SourceSans
inputEnd.TextSize = 14
inputEnd.ZIndex = 11
inputEnd.ClearTextOnFocus = false

local saveTrackBtn = Instance.new("TextButton")
saveTrackBtn.Parent = addMenuFrame
saveTrackBtn.Text = "SAVE"
saveTrackBtn.Size = UDim2.new(0.45, 0, 0.15, 0)
saveTrackBtn.Position = UDim2.new(0.04, 0, 0.78, 0)
saveTrackBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
saveTrackBtn.TextColor3 = Color3.fromRGB(250, 250, 250)
saveTrackBtn.Font = Enum.Font.SourceSansSemibold
saveTrackBtn.TextSize = 14
saveTrackBtn.ZIndex = 11

local cancelTrackBtn = Instance.new("TextButton")
cancelTrackBtn.Parent = addMenuFrame
cancelTrackBtn.Text = "CANCEL"
cancelTrackBtn.Size = UDim2.new(0.45, 0, 0.15, 0)
cancelTrackBtn.Position = UDim2.new(0.51, 0, 0.78, 0)
cancelTrackBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
cancelTrackBtn.TextColor3 = Color3.fromRGB(250, 250, 250)
cancelTrackBtn.Font = Enum.Font.SourceSansSemibold
cancelTrackBtn.TextSize = 14
cancelTrackBtn.ZIndex = 11

local catMenuFrame = Instance.new("Frame")
catMenuFrame.Name = "CatMenuFrame"
catMenuFrame.Parent = Container
catMenuFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
catMenuFrame.BorderSizePixel = 1
catMenuFrame.BorderColor3 = Color3.fromRGB(60, 60, 60)
catMenuFrame.Position = UDim2.new(0.15, 0, 0.3, 0)
catMenuFrame.Size = UDim2.new(0.7, 0, 0.4, 0)
catMenuFrame.Visible = false
catMenuFrame.ZIndex = 12

local catMenuTitle = Instance.new("TextLabel")
catMenuTitle.Parent = catMenuFrame
catMenuTitle.Size = UDim2.new(1, 0, 0.3, 0)
catMenuTitle.BackgroundTransparency = 1
catMenuTitle.Text = "NEW CATEGORY NAME:"
catMenuTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
catMenuTitle.Font = Enum.Font.SourceSansSemibold
catMenuTitle.TextSize = 14
catMenuTitle.ZIndex = 13

local inputCatName = Instance.new("TextBox")
inputCatName.Parent = catMenuFrame
inputCatName.Size = UDim2.new(0.9, 0, 0.3, 0)
inputCatName.Position = UDim2.new(0.05, 0, 0.35, 0)
inputCatName.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
inputCatName.TextColor3 = Color3.fromRGB(250, 250, 250)
inputCatName.Text = ""
inputCatName.ZIndex = 13
inputCatName.ClearTextOnFocus = false

local saveCatBtn = createControlBtn("SaveCatBtn", "CREATE", 10, 110, Color3.fromRGB(40,80,40), catMenuFrame)
saveCatBtn.Position = UDim2.new(0.05, 0, 0.7, 0)
saveCatBtn.ZIndex = 13
local cancelCatBtn = createControlBtn("CancelCatBtn", "CANCEL", 130, 110, Color3.fromRGB(80,40,40), catMenuFrame)
cancelCatBtn.Position = UDim2.new(0.5, 5, 0.7, 0)
cancelCatBtn.ZIndex = 13

homeFrame.Name = "homeFrame"
homeFrame.Parent = Container
homeFrame.BackgroundTransparency = 1
homeFrame.Position = UDim2.new(0, 0, 0, 40)
homeFrame.Size = UDim2.new(0, 430, 0, listHeight + 50)
homeFrame.ZIndex = 3

-- HOME TAB LAYOUT REWORKED (БЕЗ ЭКВАЛАЙЗЕРА)
-- Строка ввода ID
SoundId.Name = "SoundId"
SoundId.Parent = homeFrame
SoundId.BackgroundColor3 = Color3.new(0.121569, 0.121569, 0.121569)
SoundId.BackgroundTransparency = 0.25
SoundId.BorderColor3 = Color3.new(0.392157, 0.392157, 0.392157)
SoundId.Position = UDim2.new(0, 10, 0, 10)
SoundId.Size = UDim2.new(0, 410, 0, 30)
SoundId.ZIndex = 4
SoundId.Font = Enum.Font.SourceSansSemibold
SoundId.Text = ""
SoundId.PlaceholderText = "Sound ID"
SoundId.TextColor3 = Color3.new(0.784314, 0.784314, 0.784314)
SoundId.TextSize = 16
SoundId.ClearTextOnFocus = false

-- Вторая строка: Play, Volume, Pitch, STOP в один ряд (растянуты на всю ширину)
PlayBtn.Name = "PlayBtn"
PlayBtn.Parent = homeFrame
PlayBtn.BackgroundColor3 = Color3.new(0.121569, 0.121569, 0.121569)
PlayBtn.BorderColor3 = Color3.new(0.392157, 0.392157, 0.392157)
PlayBtn.Position = UDim2.new(0, 10, 0, 50)
PlayBtn.Size = UDim2.new(0, 95, 0, 30)
PlayBtn.ZIndex = 4
PlayBtn.Font = Enum.Font.SourceSansSemibold
PlayBtn.Text = "PLAY"
PlayBtn.TextColor3 = Color3.new(0.784314, 0.784314, 0.784314)
PlayBtn.TextSize = 16

Volume.Name = "Volume"
Volume.Parent = homeFrame
Volume.BackgroundColor3 = Color3.new(0.121569, 0.121569, 0.121569)
Volume.BackgroundTransparency = 0.25
Volume.BorderColor3 = Color3.new(0.392157, 0.392157, 0.392157)
Volume.Position = UDim2.new(0, 115, 0, 50)
Volume.Size = UDim2.new(0, 95, 0, 30)
Volume.ZIndex = 4
Volume.Font = Enum.Font.SourceSansSemibold
Volume.Text = "1"
Volume.PlaceholderText = "Volume"
Volume.TextColor3 = Color3.new(0.784314, 0.784314, 0.784314)
Volume.TextSize = 16
Volume.ClearTextOnFocus = false

Pitch.Name = "Pitch"
Pitch.Parent = homeFrame
Pitch.BackgroundColor3 = Color3.new(0.121569, 0.121569, 0.121569)
Pitch.BackgroundTransparency = 0.25
Pitch.BorderColor3 = Color3.new(0.392157, 0.392157, 0.392157)
Pitch.Position = UDim2.new(0, 220, 0, 50)
Pitch.Size = UDim2.new(0, 95, 0, 30)
Pitch.ZIndex = 4
Pitch.Font = Enum.Font.SourceSansSemibold
Pitch.Text = "1"
Pitch.PlaceholderText = "Pitch"
Pitch.TextColor3 = Color3.new(0.784314, 0.784314, 0.784314)
Pitch.TextSize = 16
Pitch.ClearTextOnFocus = false

StopBtn.Name = "StopBtn"
StopBtn.Parent = homeFrame
StopBtn.BackgroundColor3 = Color3.new(0.121569, 0.121569, 0.121569)
StopBtn.BorderColor3 = Color3.new(0.392157, 0.392157, 0.392157)
StopBtn.Position = UDim2.new(0, 325, 0, 50)
StopBtn.Size = UDim2.new(0, 95, 0, 30)
StopBtn.ZIndex = 4
StopBtn.Font = Enum.Font.SourceSansSemibold
StopBtn.Text = "STOP"
StopBtn.TextColor3 = Color3.new(0.784314, 0.784314, 0.784314)
StopBtn.TextSize = 16

-- Полоса прогресса (Внизу как и требовалось)
SoundPlaying.Name = "SoundPlaying"
SoundPlaying.Parent = Container
SoundPlaying.BackgroundTransparency = 1
SoundPlaying.Position = UDim2.new(0, 0, 1, -35) -- Прижато к низу контейнера
SoundPlaying.Size = UDim2.new(1, 0, 0, 35)
SoundPlaying.ZIndex = 5

Line.Name = "Line"
Line.Parent = SoundPlaying
Line.BackgroundColor3 = Color3.new(0.137255, 0.137255, 0.137255)
Line.BorderColor3 = Color3.new(0.121569, 0.121569, 0.121569)
Line.Position = UDim2.new(0, 50, 0, 10)
Line.Size = UDim2.new(1, -100, 0, 6)
Line.ZIndex = 6
Line.Text = ""

Line_2.Name = "Line"
Line_2.Parent = Line
Line_2.AnchorPoint = Vector2.new(0, 0.5)
Line_2.BackgroundColor3 = Color3.new(0.784314, 0.784314, 0.784314)
Line_2.Position = UDim2.new(0, 0, 0.5, 0)
Line_2.Size = UDim2.new(0, 0, 0, 6)
Line_2.ZIndex = 7
Line_2.Text = ""

TimePos.Name = "TimePos"
TimePos.Parent = SoundPlaying
TimePos.BackgroundTransparency = 1
TimePos.Position = UDim2.new(0, 5, 0, 5)
TimePos.Size = UDim2.new(0, 45, 0, 20)
TimePos.ZIndex = 6
TimePos.Font = Enum.Font.SourceSansSemibold
TimePos.Text = "0:00"
TimePos.TextColor3 = Color3.new(0.784314, 0.784314, 0.784314)
TimePos.TextSize = 14

TimeLen.Name = "TimeLen"
TimeLen.Parent = SoundPlaying
TimeLen.BackgroundTransparency = 1
TimeLen.Position = UDim2.new(1, -50, 0, 5)
TimeLen.Size = UDim2.new(0, 45, 0, 20)
TimeLen.ZIndex = 6
TimeLen.Font = Enum.Font.SourceSansSemibold
TimeLen.Text = "0:00"
TimeLen.TextColor3 = Color3.new(0.784314, 0.784314, 0.784314)
TimeLen.TextSize = 14

Playing.Name = "Playing"
Playing.Parent = SoundPlaying
Playing.BackgroundTransparency = 1
Playing.Position = UDim2.new(0, 50, 0, 20)
Playing.Size = UDim2.new(1, -100, 0, 15)
Playing.ZIndex = 6
Playing.Font = Enum.Font.SourceSansSemibold
Playing.Text = ""
Playing.TextColor3 = Color3.new(0.784314, 0.784314, 0.784314)
Playing.TextSize = 12
Playing.TextWrapped = true

settingsFrame.Name = "settingsFrame"
settingsFrame.Parent = Container
settingsFrame.BackgroundTransparency = 1
settingsFrame.Position = UDim2.new(0, 0, 0, 40)
settingsFrame.Size = UDim2.new(0, 430, 0, listHeight + 50)
settingsFrame.Visible = false
settingsFrame.ZIndex = 3

-- ВЫРАВНИВАНИЕ НА ВКЛАДКЕ SETTINGS (Сетка 3 колонки)
local startX = 10
local startY = 10
local paddingX = 8
local paddingY = 8
local boxWidth = 130
local boxHeight = 26

local function setupSettingsBox(obj, name, placeholder, col, row)
    obj.Name = name
    obj.Parent = settingsFrame
    obj.BackgroundColor3 = Color3.new(0.121569, 0.121569, 0.121569)
    obj.BackgroundTransparency = 0.25
    obj.BorderColor3 = Color3.new(0.392157, 0.392157, 0.392157)
    obj.Position = UDim2.new(0, startX + (col-1) * (boxWidth + paddingX), 0, startY + (row-1) * (boxHeight + paddingY))
    obj.Size = UDim2.new(0, boxWidth, 0, boxHeight)
    obj.ZIndex = 4
    obj.Font = Enum.Font.SourceSansSemibold
    obj.PlaceholderText = placeholder
    obj.Text = ""
    obj.TextColor3 = Color3.new(0.784314, 0.784314, 0.784314)
    obj.TextSize = 14
    if obj:IsA("TextBox") then
        obj.ClearTextOnFocus = false
    end
end

setupSettingsBox(partsSetting, "partsSetting", "Parts", 1, 1)
setupSettingsBox(colorSetting, "colorSetting", "Color (255,255,255)", 2, 1)
colorSetting.Text = "255,255,255"
setupSettingsBox(angleSetting_2, "angleSetting_2", "Goal", 3, 1)
setupSettingsBox(transSetting, "transSetting", "Trans", 1, 2)
transSetting.Text = "0"
setupSettingsBox(splitSetting, "splitSetting", "Split", 2, 2)
setupSettingsBox(angleSetting, "angleSetting", "Angle", 3, 2)
setupSettingsBox(disposSetting, "disposSetting", "Disposition", 1, 3)
setupSettingsBox(bodySetting, "bodySetting", "Body", 2, 3)
setupSettingsBox(powerSetting, "powerSetting", "Power", 3, 3)

rainbowToggleBtn.Name = "rainbowToggleBtn"
rainbowToggleBtn.Parent = settingsFrame
rainbowToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
rainbowToggleBtn.BorderColor3 = Color3.new(0.392157, 0.392157, 0.392157)
rainbowToggleBtn.Position = UDim2.new(0, startX, 0, startY + 3 * (boxHeight + paddingY))
rainbowToggleBtn.Size = UDim2.new(0, boxWidth, 0, boxHeight)
rainbowToggleBtn.ZIndex = 4
rainbowToggleBtn.Font = Enum.Font.SourceSansSemibold
rainbowToggleBtn.Text = "RAINBOW: ON"
rainbowToggleBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
rainbowToggleBtn.TextSize = 13

materialBtn.Name = "materialBtn"
materialBtn.Parent = settingsFrame
materialBtn.BackgroundColor3 = Color3.new(0.121569, 0.121569, 0.121569)
materialBtn.BorderColor3 = Color3.new(0.392157, 0.392157, 0.392157)
materialBtn.Position = UDim2.new(0, startX + (boxWidth + paddingX), 0, startY + 3 * (boxHeight + paddingY))
materialBtn.Size = UDim2.new(0, boxWidth, 0, boxHeight)
materialBtn.ZIndex = 4
materialBtn.Font = Enum.Font.SourceSansSemibold
materialBtn.Text = "MATERIALS"
materialBtn.TextColor3 = Color3.new(0.784314, 0.784314, 0.784314)
materialBtn.TextSize = 13

materialFrame.Name = "materialFrame"
materialFrame.Parent = Container
materialFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
materialFrame.BorderSizePixel = 0
materialFrame.Position = UDim2.new(1, -208, 0, 40)
materialFrame.Size = UDim2.new(0, 208, 0, listHeight + 25)
materialFrame.Visible = false
materialFrame.ZIndex = 5

Shadow_2.Name = "Shadow"
Shadow_2.Parent = materialFrame
Shadow_2.BackgroundTransparency = 1
Shadow_2.Position = UDim2.new(0, -5, 0, -5)
Shadow_2.Size = UDim2.new(1, 10, 1, 10)
Shadow_2.Image = "rbxassetid://259010925"
Shadow_2.ScaleType = Enum.ScaleType.Slice
Shadow_2.SliceCenter = Rect.new(6, 6, 25, 25)
Shadow_2.ZIndex = 5

materialPicker.Name = "materialPicker"
materialPicker.Parent = materialFrame
materialPicker.BackgroundTransparency = 1
materialPicker.Size = UDim2.new(1, 0, 1, 0)
materialPicker.CanvasSize = UDim2.new(0, 0, 0, 28)
materialPicker.ScrollBarThickness = 4
materialPicker.ZIndex = 6

CloseButton.Name = "CloseButton"
CloseButton.Parent = TopBar
CloseButton.BackgroundColor3 = Color3.new(0.639216, 0.294118, 0.294118)
CloseButton.BorderSizePixel = 0
CloseButton.Position = UDim2.new(1, -25, 0, 0)
CloseButton.Size = UDim2.new(0, 25, 1, 0)
CloseButton.ZIndex = 5
CloseButton.Font = Enum.Font.SourceSans
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.new(1, 1, 1)

TextLabel.Parent = TopBar
TextLabel.BackgroundTransparency = 1
TextLabel.Size = UDim2.new(0, 200, 0, 27)
TextLabel.ZIndex = 5
TextLabel.Font = Enum.Font.SourceSansSemibold
TextLabel.Text = "WdymGaming's music gui"
TextLabel.TextColor3 = Color3.new(0.784314, 0.784314, 0.784314)
TextLabel.TextSize = 18

MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Parent = TopBar
MinimizeButton.BackgroundColor3 = Color3.new(0.694118, 0.509804, 0.141176)
MinimizeButton.BorderSizePixel = 0
MinimizeButton.Position = UDim2.new(1, -50, 0, 0)
MinimizeButton.Size = UDim2.new(0, 25, 1, 0)
MinimizeButton.ZIndex = 5
MinimizeButton.Font = Enum.Font.SourceSans
MinimizeButton.Text = "-"
MinimizeButton.TextColor3 = Color3.new(1, 1, 1)

local MaterialsList = {
    "Neon", "Plastic", "Glass", "ForceField", "Wood", "WoodPlanks",
    "Marble", "Slate", "Granite", "Brick", "Cobblestone", "Concrete",
    "Metal", "DiamondPlate", "CorrodedMetal", "Ice", "Sand", "Fabric"
}

local current = "home"
local pattern = '%02i:%02i'
local Rad = 0
local mRad = math.random(0, 100)
local LastB = 0
local LastL = 0

local Settings = {
    Body = 0,
    Angle = 25,
    Goal = .30,
    Split = 1,
    Parts = 2,
    Disposition = 3,
    Power = 400,
    Material = 'Neon',
    Rainbow = true,
    StaticColor = Color3.new(1,1,1),
    Transparency = 0
}

local DataStructure = {
    Categories = {
        ["Default"] = {}
    }
}

function new(a, b, c)
    local d = Instance.new(a, b)
    for e,f in pairs(c) do
        d[e] = f
    end
    return d
end

local Parts = Instance.new("Model")
Parts.Name = "MusicParts"

local function UpdatePartsParent()
    if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and ToggleState then
        Parts.Parent = Player.Character
    end
end

local function getRoot()
    return Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
end

function Sound(N, L, PS, V, ID)
    local S = new("Sound", MusicGuiRework, {Name = N, SoundId = 'rbxassetid://'..ID, Looped = L, PlaybackSpeed = PS, Volume = V})
    return S
end

function Part(Num)
    Settings.Parts = tonumber(Num) or 2
    Parts:ClearAllChildren()
    local root = getRoot()
    if not root or not ToggleState then return end
    for i = 1, Settings.Parts do
        local p = new("Part", Parts, {Color = Settings.StaticColor, Transparency = Settings.Transparency, Anchored = true, CanCollide = false, Material = Enum.Material[Settings.Material] or Enum.Material.Neon, Size = Vector3.new(.2,.2,.2), CFrame = root.CFrame * CFrame.new(0, Settings.Body, 0), Locked = true})
    end
end

local Music = nil
local runTimelineLoop

task.spawn(function()
    while ScriptActive do
        if ToggleState then
            if not Music or Music.Parent ~= MusicGuiRework then
                if Music then pcall(function() Music:Destroy() end) end
                Music = Sound('Music', true, 1, 1, (SoundId.Text ~= "" and SoundId.Text or "1"))
                if runTimelineLoop then runTimelineLoop() end
            end
            UpdatePartsParent()
            local root = getRoot()
            if root and #Parts:GetChildren() ~= Settings.Parts then
                Part(Settings.Parts)
            end
        end
        task.wait(0.5)
    end
end)

-- Логика сохранения настроек
local function saveSettingsData()
    if writefile then
        local dataToSave = {
            Body = Settings.Body,
            Angle = Settings.Angle,
            Goal = Settings.Goal,
            Split = Settings.Split,
            Parts = Settings.Parts,
            Disposition = Settings.Disposition,
            Power = Settings.Power,
            Material = Settings.Material,
            Rainbow = Settings.Rainbow,
            Transparency = Settings.Transparency,
            StaticColor = {Settings.StaticColor.R * 255, Settings.StaticColor.G * 255, Settings.StaticColor.B * 255}
        }
        local success, encoded = pcall(function() return HttpService:JSONEncode(dataToSave) end)
        if success then writefile(settingsFileName, encoded) end
    end
end

-- Логика загрузки настроек
local function loadSettingsData()
    if readfile and isfile and isfile(settingsFileName) then
        local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(settingsFileName)) end)
        if success and type(decoded) == "table" then
            Settings.Body = decoded.Body or Settings.Body
            Settings.Angle = decoded.Angle or Settings.Angle
            Settings.Goal = decoded.Goal or Settings.Goal
            Settings.Split = decoded.Split or Settings.Split
            Settings.Parts = decoded.Parts or Settings.Parts
            Settings.Disposition = decoded.Disposition or Settings.Disposition
            Settings.Power = decoded.Power or Settings.Power
            Settings.Material = decoded.Material or Settings.Material
            if decoded.Rainbow ~= nil then
                Settings.Rainbow = decoded.Rainbow
            end
            Settings.Transparency = decoded.Transparency or Settings.Transparency
            if decoded.StaticColor then
                Settings.StaticColor = Color3.fromRGB(decoded.StaticColor[1], decoded.StaticColor[2], decoded.StaticColor[3])
            end
            
            partsSetting.Text = tostring(Settings.Parts)
            colorSetting.Text = string.format("%d,%d,%d", Settings.StaticColor.R*255, Settings.StaticColor.G*255, Settings.StaticColor.B*255)
            angleSetting_2.Text = tostring(Settings.Goal)
            transSetting.Text = tostring(Settings.Transparency)
            splitSetting.Text = tostring(Settings.Split)
            angleSetting.Text = tostring(Settings.Angle)
            disposSetting.Text = tostring(Settings.Disposition)
            bodySetting.Text = tostring(Settings.Body)
            powerSetting.Text = tostring(Settings.Power)
            
            if Settings.Rainbow then
                rainbowToggleBtn.Text = "RAINBOW: ON"
                rainbowToggleBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
                rainbowToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
            else
                rainbowToggleBtn.Text = "RAINBOW: OFF"
                rainbowToggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
                rainbowToggleBtn.BackgroundColor3 = Color3.fromRGB(70, 40, 40)
            end
        end
    end
end

local function saveMusicData()
    if writefile then
        local success, encoded = pcall(function() return HttpService:JSONEncode(DataStructure) end)
        if success then writefile(jsonFileName, encoded) end
    end
end

local function loadMusicData()
    if readfile and isfile and isfile(jsonFileName) then
        local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(jsonFileName)) end)
        if success and type(decoded) == "table" and decoded.Categories then
            DataStructure = decoded
            return
        end
    end
    saveMusicData()
end

loadMusicData()
loadSettingsData()

local currentSelectedId = ""
local editingTrack = false
local CurrentCategory = "Default"
local updateMusicList

local function updateCategoryList()
    categoryFrame:ClearAllChildren()
    local yPos = 5
    for catName, _ in pairs(DataStructure.Categories) do
        local catBtn = new("TextButton", categoryFrame, {
            Size = UDim2.new(1, -10, 0, 25),
            Position = UDim2.new(0, 5, 0, yPos),
            BackgroundColor3 = (CurrentCategory == catName) and Color3.fromRGB(55, 55, 75) or Color3.fromRGB(25, 25, 25),
            TextColor3 = Color3.fromRGB(230, 230, 230),
            Font = Enum.Font.SourceSansBold,
            TextSize = 13,
            Text = catName,
            ZIndex = categoryFrame.ZIndex
        })
        catBtn.MouseButton1Click:Connect(function()
            CurrentCategory = catName
            updateCategoryList()
            updateMusicList()
        end)
        yPos = yPos + 28
    end
    categoryFrame.CanvasSize = UDim2.new(0, 0, 0, yPos + 10)
end

updateMusicList = function()
    musicFrame:ClearAllChildren()
    local trackStartX, trackStartY = 6, 5
    local trackPaddingX, trackPaddingY = 6, 6
    local trackWidth, trackHeight = 94, 40
    local col, row = 0, 0
    local tracks = DataStructure.Categories[CurrentCategory] or {}
    
    for id, trackData in pairs(tracks) do
        local nameLower = (trackData.name or ""):lower()
        local idLower = tostring(id):lower()
        if searchQuery == "" or nameLower:find(searchQuery, 1, true) or idLower:find(searchQuery, 1, true) then
            local btn = new("TextButton", musicFrame, {
                BackgroundColor3 = (currentSelectedId == tostring(id)) and Color3.fromRGB(50, 50, 80) or Color3.fromRGB(31, 31, 31),
                BorderColor3 = Color3.fromRGB(60, 60, 60),
                TextColor3 = Color3.fromRGB(220, 220, 220),
                Position = UDim2.new(0, trackStartX + col * (trackWidth + trackPaddingX), 0, trackStartY + row * (trackHeight + trackPaddingY)),
                Font = Enum.Font.SourceSans,
                TextSize = 12,
                Size = UDim2.new(0, trackWidth, 0, trackHeight),
                TextWrapped = true,
                Name = tostring(id),
                ZIndex = musicFrame.ZIndex,
                Text = trackData.name or tostring(id)
            })
            btn.MouseButton1Click:Connect(function()
                if not ToggleState then return end
                currentSelectedId = btn.Name
                SoundId.Text = btn.Name
                Volume.Text = tostring(trackData.volume or 1)
                Pitch.Text = tostring(trackData.pitch or 1)
                updateMusicList()
                
                -- ИСПРАВЛЕНИЕ БАГА С START/END TIME
                -- Создаем новый звук или обновляем старый, но явно сбрасываем TimePosition
                if not Music or Music.Parent ~= MusicGuiRework then
                    Music = Sound('Music', true, 1, 1, btn.Name)
                    runTimelineLoop()
                end
                
                if Music then
                    Music.SoundId = "rbxassetid://"..btn.Name
                    Music.Volume = tonumber(trackData.volume) or 1
                    Music.PlaybackSpeed = tonumber(trackData.pitch) or 1
                    Music.TimePosition = tonumber(trackData.start_time) or 0
                    Music:Play()
                    Playing.Text = "["..CurrentCategory.."] "..(trackData.name or btn.Name)
                end
            end)
            col = col + 1
            if col >= 3 then
                col = 0
                row = row + 1
            end
        end
    end
    local totalRows = col > 0 and (row + 1) or row
    musicFrame.CanvasSize = UDim2.new(0, 0, 0, trackStartY + totalRows * (trackHeight + trackPaddingY) + 10)
end

updateCategoryList()
updateMusicList()

musicSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    searchQuery = musicSearchBox.Text:lower()
    updateMusicList()
end)

newCatBtn.MouseButton1Click:Connect(function()
    inputCatName.Text = ""
    catMenuFrame.Visible = true
end)

saveCatBtn.MouseButton1Click:Connect(function()
    local name = inputCatName.Text:gsub("%s+", "")
    if name ~= "" then
        if not DataStructure.Categories[name] then
            DataStructure.Categories[name] = {}
            CurrentCategory = name
            saveMusicData()
            updateCategoryList()
            updateMusicList()
        end
        catMenuFrame.Visible = false
    end
end)

cancelCatBtn.MouseButton1Click:Connect(function()
    catMenuFrame.Visible = false
end)

delCatBtn.MouseButton1Click:Connect(function()
    if CurrentCategory ~= "Default" then
        DataStructure.Categories[CurrentCategory] = nil
        CurrentCategory = "Default"
        saveMusicData()
        updateCategoryList()
        updateMusicList()
    end
end)

local isInteractingWithSlider = false
local function updateSliderToMouse()
    if not Music or Music.TimeLength <= 0 or not ToggleState then return end
    local mousePos = UserInputService:GetMouseLocation()
    local relativeX = mousePos.X - Line.AbsolutePosition.X
    local percentage = math.clamp(relativeX / Line.AbsoluteSize.X, 0, 1)
    Line_2.Size = UDim2.new(percentage, 0, 0, 6)
    Music.TimePosition = Music.TimeLength * percentage
end

Line.MouseButton1Down:Connect(function()
    isInteractingWithSlider = true
    updateSliderToMouse()
end)

UserInputService.InputChanged:Connect(function(input)
    if isInteractingWithSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
        updateSliderToMouse()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isInteractingWithSlider = false
    end
end)

local timelineLoop = nil
runTimelineLoop = function()
    if timelineLoop then task.cancel(timelineLoop) end
    timelineLoop = task.spawn(function()
        while Music and Music.Parent and ScriptActive do
            if ToggleState and Music.IsPlaying and not isInteractingWithSlider then
                local tracks = DataStructure.Categories[CurrentCategory] or {}
                local currentTrack = tracks[currentSelectedId]
                
                -- Применяем End Time только если текущий трек совпадает с выбранным в библиотеке
                if currentTrack and tonumber(currentTrack.end_time) and currentTrack.end_time > 0 then
                    if Music.TimePosition >= currentTrack.end_time then
                        Music.TimePosition = currentTrack.start_time or 0
                    end
                end
                
                if Music.TimeLength > 0 then
                    Line_2.Size = UDim2.new(math.clamp(Music.TimePosition / Music.TimeLength, 0, 1), 0, 0, 6)
                end
                TimeLen.Text = pattern:format(math.floor(Music.TimeLength / 60) % 60, math.floor(Music.TimeLength % 60))
                TimePos.Text = pattern:format(math.floor(Music.TimePosition / 60) % 60, math.floor(Music.TimePosition % 60))
            end
            task.wait(0.3)
        end
    end)
end

addBtn.MouseButton1Click:Connect(function()
    editingTrack = false
    inputId.Text = ""
    inputName.Text = ""
    inputVol.Text = "1"
    inputPitch.Text = "1"
    inputStart.Text = "0"
    inputEnd.Text = "0"
    addMenuFrame.Visible = true
end)

editBtn.MouseButton1Click:Connect(function()
    local tracks = DataStructure.Categories[CurrentCategory] or {}
    local track = tracks[currentSelectedId]
    if track then
        editingTrack = true
        inputId.Text = currentSelectedId
        inputName.Text = track.name or ""
        inputVol.Text = tostring(track.volume or 1)
        inputPitch.Text = tostring(track.pitch or 1)
        inputStart.Text = tostring(track.start_time or 0)
        inputEnd.Text = tostring(track.end_time or 0)
        addMenuFrame.Visible = true
    end
end)

saveTrackBtn.MouseButton1Click:Connect(function()
    local idStr = inputId.Text:gsub("%s+", "")
    local nameStr = inputName.Text
    if idStr ~= "" and nameStr ~= "" then
        DataStructure.Categories[CurrentCategory][idStr] = {
            name = nameStr,
            volume = tonumber(inputVol.Text) or 1,
            pitch = tonumber(inputPitch.Text) or 1,
            start_time = tonumber(inputStart.Text) or 0,
            end_time = tonumber(inputEnd.Text) or 0
        }
        saveMusicData()
        updateMusicList()
        addMenuFrame.Visible = false
    end
end)

cancelTrackBtn.MouseButton1Click:Connect(function()
    addMenuFrame.Visible = false
end)

deleteBtn.MouseButton1Click:Connect(function()
    if DataStructure.Categories[CurrentCategory][currentSelectedId] then
        DataStructure.Categories[CurrentCategory][currentSelectedId] = nil
        saveMusicData()
        updateMusicList()
        currentSelectedId = ""
    end
end)

local function saveGrabberData()
    if writefile then
        local success, encoded = pcall(function() return HttpService:JSONEncode(grabbedIds) end)
        if success then writefile(grabberFile, encoded) end
    end
end

local function saveBlacklistData()
    if writefile then
        local listArray = {}
        for id, _ in pairs(blacklistedIds) do table.insert(listArray, id) end
        local success, encoded = pcall(function() return HttpService:JSONEncode(listArray) end)
        if success then writefile(blacklistFile, encoded) end
    end
end

local function loadGrabberData()
    if readfile and isfile and isfile(grabberFile) then
        local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(grabberFile)) end)
        if success and type(decoded) == "table" then grabbedIds = decoded end
    end
    if readfile and isfile and isfile(blacklistFile) then
        local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(blacklistFile)) end)
        if success and type(decoded) == "table" then
            for _, id in ipairs(decoded) do blacklistedIds[tonumber(id) or id] = true end
        end
    end
end

loadGrabberData()

local function updateGrabberList()
    grabberFrame:ClearAllChildren()
    local xPos, yPos = 5, 5
    for _, id in ipairs(grabbedIds) do
        local btn = Instance.new("TextButton", grabberFrame)
        btn.Name = tostring(id)
        btn.Size = UDim2.new(0, 125, 0, 40)
        btn.Position = UDim2.new(0, xPos, 0, yPos)
        btn.BackgroundColor3 = (selectedGrabbedId == tostring(id)) and Color3.fromRGB(50, 50, 80) or Color3.fromRGB(31, 31, 31)
        btn.TextColor3 = Color3.fromRGB(250, 250, 250)
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 14
        btn.Text = "ID: " .. tostring(id)
        btn.ZIndex = grabberFrame.ZIndex
        btn.MouseButton1Click:Connect(function()
            if not ToggleState then return end
            selectedGrabbedId = btn.Name
            SoundId.Text = btn.Name
            updateGrabberList()
            if setclipboard then setclipboard(btn.Name) elseif toclipboard then toclipboard(btn.Name) end
            
            -- ИСПРАВЛЕНИЕ БАГА ДЛЯ GRABBER (аналогично Music)
            if not Music or Music.Parent ~= MusicGuiRework then
                Music = Sound('Music', true, 1, 1, id)
                runTimelineLoop()
            end
            if Music then
                Music.SoundId = "rbxassetid://"..btn.Name
                Music.TimePosition = 0 -- Сброс времени для ручного запуска
                Music:Play()
                Playing.Text = "Grabbed ID: "..btn.Name
            end
        end)
        xPos = xPos + 130
        if xPos >= 380 then xPos = 5; yPos = yPos + 45 end
    end
    grabberFrame.CanvasSize = UDim2.new(0, 0, 0, yPos + 50)
end

updateGrabberList()

local function checkAndAddSound(sound)
    if sound:IsA("Sound") and sound.IsPlaying and sound.SoundId ~= "" then
        local rawId = sound.SoundId:match("%d+")
        if rawId then
            local idNum = tonumber(rawId)
            if idNum and not table.find(grabbedIds, idNum) and not blacklistedIds[idNum] then
                table.insert(grabbedIds, idNum)
                updateGrabberList()
                saveGrabberData()
            end
        end
    end
end

local function startSmartScanning()
    for _, serviceName in ipairs({"Workspace", "SoundService", "Players"}) do
        local service = game:GetService(serviceName)
        if service then
            for _, v in ipairs(service:GetDescendants()) do pcall(checkAndAddSound, v) end
        end
    end
    scanConnection = game.DescendantAdded:Connect(function(descendant)
        pcall(function()
            if descendant:IsA("Sound") then
                checkAndAddSound(descendant)
                descendant:GetPropertyChangedSignal("IsPlaying"):Connect(function() checkAndAddSound(descendant) end)
            end
        end)
    end)
end

gStartBtn.MouseButton1Click:Connect(function()
    if not ToggleState then return end
    isGrabberScanning = not isGrabberScanning
    if isGrabberScanning then
        gStartBtn.Text = "STOP"
        gStartBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
        startSmartScanning()
    else
        gStartBtn.Text = "START"
        gStartBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
        if scanConnection then scanConnection:Disconnect(); scanConnection = nil end
    end
end)

gScanBtn.MouseButton1Click:Connect(function()
    if not ToggleState or isScanningLogicRunning then return end
    isScanningLogicRunning = true
    local ScanGui = Instance.new("Frame")
    ScanGui.Name = "ScanProgressGui"
    ScanGui.Parent = Container
    ScanGui.AnchorPoint = Vector2.new(0.5, 0.5)
    ScanGui.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    ScanGui.BorderSizePixel = 1
    ScanGui.BorderColor3 = Color3.fromRGB(60, 60, 60)
    ScanGui.Position = UDim2.new(0.5, 0, 0.5, 0)
    ScanGui.Size = UDim2.new(0, 280, 0, 90)
    ScanGui.ZIndex = 20
    
    local ScanTitle = Instance.new("TextLabel", ScanGui)
    ScanTitle.Size = UDim2.new(1, 0, 0, 30)
    ScanTitle.BackgroundTransparency = 1
    ScanTitle.Font = Enum.Font.SourceSansSemibold
    ScanTitle.Text = "VALIDATING GRABBER LIST..."
    ScanTitle.TextColor3 = Color3.fromRGB(220, 220, 220)
    ScanTitle.TextSize = 14
    ScanTitle.ZIndex = 21
    
    local ScanStatus = Instance.new("TextLabel", ScanGui)
    ScanStatus.Position = UDim2.new(0, 0, 0, 30)
    ScanStatus.Size = UDim2.new(1, 0, 0, 20)
    ScanStatus.BackgroundTransparency = 1
    ScanStatus.Font = Enum.Font.SourceSans
    ScanStatus.Text = "Initializing..."
    ScanStatus.TextColor3 = Color3.fromRGB(160, 160, 160)
    ScanStatus.TextSize = 12
    ScanStatus.ZIndex = 21
    
    local ProgressBarBack = Instance.new("Frame", ScanGui)
    ProgressBarBack.Position = UDim2.new(0.05, 0, 0, 60)
    ProgressBarBack.Size = UDim2.new(0.9, 0, 0, 10)
    ProgressBarBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    ProgressBarBack.BorderSizePixel = 0
    ProgressBarBack.ZIndex = 21
    
    local ProgressBarFill = Instance.new("Frame", ProgressBarBack)
    ProgressBarFill.Size = UDim2.new(0, 0, 1, 0)
    ProgressBarFill.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    ProgressBarFill.BorderSizePixel = 0
    ProgressBarFill.ZIndex = 22
    
    task.spawn(function()
        task.wait(0.2)
        ScanStatus.Text = "Removing duplicates..."
        local uniqueIds = {}
        local seen = {}
        for _, id in ipairs(grabbedIds) do
            local idKey = tostring(id)
            if not seen[idKey] then
                seen[idKey] = true
                table.insert(uniqueIds, id)
            end
        end
        grabbedIds = uniqueIds
        
        ScanStatus.Text = "Cross-referencing with Music library..."
        task.wait(0.2)
        local musicIdSet = {}
        for _, catData in pairs(DataStructure.Categories) do
            for id, _ in pairs(catData) do
                musicIdSet[tostring(id)] = true
            end
        end
        local filteredIds = {}
        for _, id in ipairs(grabbedIds) do
            if not musicIdSet[tostring(id)] then
                table.insert(filteredIds, id)
            end
        end
        grabbedIds = filteredIds
        saveGrabberData()
        
        local total = #grabbedIds
        local validIds = {}
        for index, id in ipairs(grabbedIds) do
            ScanStatus.Text = string.format("Testing playback: %d / %d (ID: %s)", index, total, tostring(id))
            if total > 0 then
                ProgressBarFill.Size = UDim2.new(index / total, 0, 1, 0)
            end
            local tempSound = Instance.new("Sound")
            tempSound.SoundId = "rbxassetid://" .. tostring(id)
            tempSound.Volume = 0
            tempSound.Parent = game:GetService("SoundService")
            local isValid = false
            pcall(function() tempSound:Play() end)
            local elapsed = 0
            while elapsed < 5 do
                if tempSound.TimeLength > 0 then
                    isValid = true
                    break
                end
                task.wait(0.25)
                elapsed = elapsed + 0.25
            end
            tempSound:Stop()
            tempSound:Destroy()
            if isValid then
                table.insert(validIds, id)
            end
            task.wait(0.5)
        end
        grabbedIds = validIds
        saveGrabberData()
        updateGrabberList()
        selectedGrabbedId = ""
        ScanStatus.Text = string.format("Complete! %d / %d IDs are valid.", #validIds, total)
        ProgressBarFill.Size = UDim2.new(1, 0, 1, 0)
        task.wait(2)
        ScanGui:Destroy()
        isScanningLogicRunning = false
    end)
end)

gDeleteBtn.MouseButton1Click:Connect(function()
    local idNum = tonumber(selectedGrabbedId)
    if idNum then
        local idx = table.find(grabbedIds, idNum)
        if idx then
            table.remove(grabbedIds, idx)
            selectedGrabbedId = ""
            saveGrabberData()
            updateGrabberList()
        end
    end
end)

gBlacklistBtn.MouseButton1Click:Connect(function()
    local idNum = tonumber(selectedGrabbedId)
    if idNum then
        blacklistedIds[idNum] = true
        local idx = table.find(grabbedIds, idNum)
        if idx then table.remove(grabbedIds, idx) end
        selectedGrabbedId = ""
        saveGrabberData()
        saveBlacklistData()
        updateGrabberList()
    end
end)

toggleScriptBtn.MouseButton1Click:Connect(function()
    ToggleState = not ToggleState
    if ToggleState then
        toggleScriptBtn.Text = "TOGGLE: ON"
        toggleScriptBtn.TextColor3 = Color3.fromRGB(100, 220, 100)
        Part(Settings.Parts)
        runTimelineLoop()
    else
        toggleScriptBtn.Text = "TOGGLE: OFF"
        toggleScriptBtn.TextColor3 = Color3.fromRGB(220, 100, 100)
        if Music then Music:Stop() end
        Parts:ClearAllChildren()
        if isGrabberScanning then
            isGrabberScanning = false
            gStartBtn.Text = "START"
            gStartBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
            if scanConnection then scanConnection:Disconnect(); scanConnection = nil end
        end
        Line_2.Size = UDim2.new(0, 0, 0, 6)
        TimePos.Text = "0:00"
        Playing.Text = "Script Disabled"
    end
end)

rainbowToggleBtn.MouseButton1Click:Connect(function()
    Settings.Rainbow = not Settings.Rainbow
    if Settings.Rainbow then
        rainbowToggleBtn.Text = "RAINBOW: ON"
        rainbowToggleBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
        rainbowToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
    else
        rainbowToggleBtn.Text = "RAINBOW: OFF"
        rainbowToggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
        rainbowToggleBtn.BackgroundColor3 = Color3.fromRGB(70, 40, 40)
        for _, child in next, Parts:GetChildren() do
            if child:IsA("BasePart") then child.Color = Settings.StaticColor end
        end
    end
    saveSettingsData()
end)

for _,v in next, settingsFrame:GetChildren() do
    if v:IsA("TextBox") then
        v.FocusLost:Connect(function()
            if v.Name == "colorSetting" then
                local r, g, b = v.Text:match("(%d+),%s*(%d+),%s*(%d+)")
                if r and g and b then
                    Settings.StaticColor = Color3.fromRGB(math.clamp(tonumber(r),0,255), math.clamp(tonumber(g),0,255), math.clamp(tonumber(b),0,255))
                    if not Settings.Rainbow then
                        for _, child in next, Parts:GetChildren() do
                            if child:IsA("BasePart") then child.Color = Settings.StaticColor end
                        end
                    end
                end
                saveSettingsData()
                return
            end
            local val = tonumber(v.Text)
            if not val then return end
            if v.Name == "partsSetting" then
                Settings.Parts = math.clamp(val, 1, 200)
                Part(Settings.Parts)
            elseif v.Name == "disposSetting" then Settings.Disposition = val
            elseif v.Name == "bodySetting" then Settings.Body = val
            elseif v.Name == "splitSetting" then Settings.Split = val == 0 and 1 or val
            elseif v.Name == "powerSetting" then Settings.Power = val == 0 and 1 or val
            elseif v.Name == "angleSetting" then Settings.Angle = val
            elseif v.Name == "angleSetting_2" then Settings.Goal = math.clamp(val, 0.01, 1)
            elseif v.Name == "transSetting" then
                Settings.Transparency = math.clamp(val, 0, 1)
                for _, child in next, Parts:GetChildren() do
                    if child:IsA("BasePart") then child.Transparency = Settings.Transparency end
                end
            end
            saveSettingsData()
        end)
    end
end

PlayBtn.MouseButton1Click:Connect(function()
    if not ToggleState then return end
    
    -- ИСПРАВЛЕНИЕ БАГА С START/END TIME ДЛЯ КНОПКИ PLAY
    -- При ручном запуске через HOME всегда сбрасываем время на 0
    if not Music or Music.Parent ~= MusicGuiRework then
        Music = Sound('Music', true, 1, 1, SoundId.Text)
        runTimelineLoop()
    end
    
    if Music then
        Music.PlaybackSpeed = tonumber(Pitch.Text) or 1
        Music.Volume = tonumber(Volume.Text) or 1
        Music.SoundId = "rbxassetid://"..SoundId.Text
        Music.TimePosition = 0 -- Явный сброс времени
        Music:Play()
        Playing.Text = "Playing ID: "..SoundId.Text
    end
end)

StopBtn.MouseButton1Click:Connect(function()
    if Music then Music:Stop() end
end)

-- Обновленная функция громкости (Убран ReactToEverything)
local function getCurrentLoudness()
    return (Music and Music.Parent) and Music.PlaybackLoudness or 0
end

-- Рендеринг визуальных элементов (ТОЛЬКО PARTS, ЭКВАЛАЙЗЕР УБРАН)
RunService:BindToRenderStep("musicVisualRender", 0, function()
    if not ScriptActive or not ToggleState then return end
    
    local currentLoudness = getCurrentLoudness()
    local targetColor = Settings.StaticColor
    local beat = math.abs(math.floor(currentLoudness) - LastL)
    if beat > LastB then LastB = beat else LastB = math.max(0, LastB - 10) end
    mRad = (mRad + beat / 250) % 100
    LastL = math.floor(currentLoudness)
    if Settings.Rainbow then
        targetColor = Color3.fromHSV(mRad / 200, 1, math.min(1 + LastB / 9e5, 10))
    end
    for _, child in next, Parts:GetChildren() do
        if child:IsA("BasePart") then child.Color = targetColor end
    end
end)

task.spawn(function()
    while ScriptActive do
        task.wait()
        if ToggleState then
            local root = getRoot()
            if root then
                Rad = (Rad + 1) % 360
                local pList = Parts:GetChildren()
                if #pList > 0 then
                    for _, v in next, pList do
                        if v:IsA("BasePart") then
                            local sideCount = Settings.Parts > 0 and Settings.Parts or 1
                            local splitVal = Settings.Split > 0 and Settings.Split or 1
                            local goalVal = Settings.Goal > 0 and Settings.Goal or 0.3
                            pcall(function()
                                v.CFrame = v.CFrame:Lerp(CFrame.new(root.CFrame.X, root.CFrame.Y + Settings.Body, root.CFrame.Z) * CFrame.Angles(0, math.rad((360 / sideCount) * ((_ + (_ * Settings.Angle)) / splitVal) + Rad), 0) * CFrame.new(0, 0, Settings.Disposition + (v.Size.Z)), goalVal)
                            end)
                        end
                    end
                end
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not ToggleState then return end
    local currentLoudness = getCurrentLoudness()
    local pList = Parts:GetChildren()
    if #pList > 0 and currentLoudness > 0 then
        local powerVal = Settings.Power > 0 and Settings.Power or 1
        local goalVal = Settings.Goal > 0 and Settings.Goal or 0.3
        for _, v in next, pList do
            if v:IsA("BasePart") then
                pcall(function()
                    v.Size = v.Size:Lerp(Vector3.new(.8, .2, (currentLoudness / powerVal) * math.random(4, 8)), goalVal)
                end)
            end
        end
    end
end)

-- Навигация вкладок меню
for _,v in next, PickerFrame:GetChildren() do
    if v:IsA("TextButton") and v.Name ~= "toggle" then
        v.MouseButton1Click:Connect(function()
            current = v.Name
            if current == "music" then
                musicControls.Visible = true
                categoryFrame.Visible = true
                musicSearchBox.Visible = true
                grabberControls.Visible = false
            elseif current == "grabber" then
                musicControls.Visible = false
                categoryFrame.Visible = false
                musicSearchBox.Visible = false
                grabberControls.Visible = true
            else
                musicControls.Visible = false
                categoryFrame.Visible = false
                musicSearchBox.Visible = false
                grabberControls.Visible = false
            end
            line:TweenSizeAndPosition(UDim2.new(0, v.TextBounds.X, 0, 2), UDim2.new(v.Position.X.Scale, v.Position.X.Offset, 1, -3), "InOut", "Quad", .2, true)
            for _, frame in next, Container:GetChildren() do
                if frame:IsA("Frame") or frame:IsA("ScrollingFrame") then
                    if frame.Name ~= "PickerFrame" and frame.Name ~= "SoundPlaying" and frame.Name ~= "materialFrame" and frame.Name ~= "MusicControls" and frame.Name ~= "GrabberControls" and frame.Name ~= "AddMenuFrame" and frame.Name ~= "categoryFrame" and frame.Name ~= "CatMenuFrame" then
                        frame.Visible = (frame.Name == current.."Frame" or frame.Name == current)
                    end
                end
            end
        end)
    end
end

-- Сворачивание
local isMinimized = false
MinimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        Container:TweenSize(UDim2.new(1, 0, 0, 0), "InOut", "Quad", .2, true)
    else
        Container:TweenSize(UDim2.new(1, 0, 2, containerHeight), "InOut", "Quad", .2, true)
    end
end)

-- Закрытие
CloseButton.MouseButton1Click:Connect(function()
    ScriptActive = false
    saveSettingsData()
    if scanConnection then scanConnection:Disconnect() end
    RunService:UnbindFromRenderStep("musicVisualRender")
    if Music then Music:Destroy() end
    if Parts then Parts:Destroy() end
    MusicGuiRework:Destroy()
end)

materialBtn.MouseButton1Click:Connect(function()
    materialFrame.Visible = not materialFrame.Visible
end)

local xOffset, yOffset = 5, 5
for _, matName in ipairs(MaterialsList) do
    local matTextBtn = new("TextButton", materialPicker, {
        BackgroundColor3 = Color3.fromRGB(31, 31, 31),
        BorderColor3 = Color3.fromRGB(60, 60, 60),
        Size = UDim2.new(0, 92, 0, 25),
        Position = UDim2.new(0, xOffset, 0, yOffset),
        Name = matName,
        Text = matName:upper(),
        Font = Enum.Font.SourceSansBold,
        TextSize = 11,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        ZIndex = 6,
    })
    matTextBtn.MouseButton1Click:Connect(function()
        Settings.Material = matTextBtn.Name
        for _, a in next, Parts:GetChildren() do
            if a:IsA("Part") then a.Material = Enum.Material[matTextBtn.Name] or Enum.Material.Neon end
        end
        saveSettingsData()
    end)
    xOffset = xOffset + 96
    if xOffset >= 190 then
        xOffset = 5
        yOffset = yOffset + 28
    end
end
materialPicker.CanvasSize = UDim2.new(0, 0, 0, yOffset + 35)

runTimelineLoop()