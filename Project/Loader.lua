--// Loader.lua — Главный загрузчик FuckYou UI
local function loadModule(url)
    local success, source = pcall(function() return game:HttpGet(url) end)
    if not success then warn("[FuckYou] Failed to load: " .. url); return nil end
    local fn, err = loadstring(source)
    if not fn then warn("[FuckYou] Compile error: " .. tostring(err)); return nil end
    return fn()
end

--// Базовый URL (ИСПРАВЛЕНО: добавлен слэш в конце)
local BASE_URL = "https://raw.githubusercontent.com/MamaSdoxla/EmilyUiRaw/refs/heads/main/Project/"

--// 1. Загружаем библиотеку
local Library = loadModule(BASE_URL .. "FuckYouLibrary.lua")
if not Library then warn("[FuckYou] CRITICAL: Library failed to load!"); return end

--// 2. Инициализируем GUI
Library.initGUI()

--// 3. Создаём кнопки сайдбара
local EmilyUiBtn = Library.makeSideBtn("EmilyUi", 0)
local DesyncBtn = Library.makeSideBtn("Desync", 59)
local MusicBtn = Library.makeSideBtn("Music", 118)
local AimBtn = Library.makeSideBtn("Aim", 177)

--// 4. Загружаем модули
local initEmilyUi = loadModule(BASE_URL .. "EmilyUiModule.lua")
local initDesync = loadModule(BASE_URL .. "DesyncModule.lua")
local initMusic = loadModule(BASE_URL .. "MusicModule.lua")
local initAim = loadModule(BASE_URL .. "AimModule.lua")
local initMovement = loadModule(BASE_URL .. "MovementModule.lua")

local emilyData = initEmilyUi and initEmilyUi(Library)
local desyncData = initDesync and initDesync(Library)
local musicData = initMusic and initMusic(Library)
local aimData = initAim and initAim(Library)
local movementData = initMovement and initMovement(Library)

--// 5. Регистрируем API модулей
if emilyData then Library.VisualsAPI = emilyData.VisualsAPI end
Library.AimAPI = aimData
Library.MovementAPI = movementData

--// 6. Загружаем конфиг
Library.loadConfig()

--// 7. Создаём Key Window
local keyTextBox, keyInfoLabel = Library.createKeyWindow()

--// 8. Настраиваем переключение вкладок
local function switchTab(targetTab)
    for _, tab in ipairs(Library.tabs) do tab.Frame.Visible = (tab == targetTab) end
    Library.updateTabButtonsTheme()
end

for index, tab in ipairs(Library.tabs) do
    local btn = Library.create("TextButton", {Name = "Btn_" .. tab.Name, Parent = Library.MenuInsided, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = index, Visible = false, BackgroundColor3 = Library.uiColor_ButtonColor, BorderColor3 = Library.COL_BORDER, TextColor3 = Library.uiColor_TextColor, Text = tab.Name, Font = Library.FONT, TextSize = 12})
    tab.Button = btn; table.insert(Library.themeElements.Buttons, btn); table.insert(Library.themeElements.Texts, btn)
    btn.MouseButton1Click:Connect(function() switchTab(tab) end)
end

local function hideAllModuleButtons()
    for _, t in ipairs(Library.tabs) do if t.Button then t.Button.Visible = false end end
    if desyncData then for _, t in ipairs(desyncData.Tabs) do if t.Button then t.Button.Visible = false end end end
    if musicData then for _, t in ipairs(musicData.Tabs) do if t.Button then t.Button.Visible = false end end end
    if aimData then for _, t in ipairs(aimData.Tabs) do if t.Button then t.Button.Visible = false end end end
    if movementData then for _, t in ipairs(movementData.Tabs) do if t.Button then t.Button.Visible = false end end end
end

local function hideAllFrames()
    for _, t in ipairs(Library.tabs) do t.Frame.Visible = false end
    if desyncData then for _, t in ipairs(desyncData.Tabs) do t.Frame.Visible = false end end
    if musicData then for _, t in ipairs(musicData.Tabs) do t.Frame.Visible = false end end
    if aimData then for _, t in ipairs(aimData.Tabs) do t.Frame.Visible = false end end
    if movementData then for _, t in ipairs(movementData.Tabs) do t.Frame.Visible = false end end
end

local function updateModuleTogglesVisibility(group)
    for _, t in ipairs(Library.moduleToggles) do t.btn.Visible = (t.group == group) end
end

EmilyUiBtn.MouseButton1Click:Connect(function()
    hideAllModuleButtons(); hideAllFrames()
    for _, t in ipairs(Library.tabs) do if t.Button then t.Button.Visible = true end end
    if Library.tabs[1] then Library.tabs[1].Frame.Visible = true end
    Library.updateTabButtonsTheme(); updateModuleTogglesVisibility("Main")
end)

DesyncBtn.MouseButton1Click:Connect(function()
    hideAllModuleButtons(); hideAllFrames()
    if desyncData then for _, t in ipairs(desyncData.Tabs) do if t.Button then t.Button.Visible = true end end; if desyncData.Tabs[1] then desyncData.Tabs[1].Frame.Visible = true end end
    Library.updateTabButtonsTheme(); updateModuleTogglesVisibility("Desync")
end)

MusicBtn.MouseButton1Click:Connect(function()
    hideAllModuleButtons(); hideAllFrames()
    if musicData then for _, t in ipairs(musicData.Tabs) do if t.Button then t.Button.Visible = true end end; if musicData.Tabs[1] then musicData.Tabs[1].Frame.Visible = true end end
    Library.updateTabButtonsTheme(); updateModuleTogglesVisibility("Music")
end)

AimBtn.MouseButton1Click:Connect(function()
    hideAllModuleButtons(); hideAllFrames()
    if aimData then for _, t in ipairs(aimData.Tabs) do if t.Button then t.Button.Visible = true end end; if aimData.Tabs[1] then aimData.Tabs[1].Frame.Visible = true end end
    Library.updateTabButtonsTheme(); updateModuleTogglesVisibility("Aim")
end)

if movementData then
    local MovementBtn = Library.makeSideBtn("Movement", 236); MovementBtn.TextSize = 11; MovementBtn.TextWrapped = true
    MovementBtn.MouseButton1Click:Connect(function()
        hideAllModuleButtons(); hideAllFrames()
        for _, t in ipairs(movementData.Tabs) do if t.Button then t.Button.Visible = true end end
        if movementData.Tabs[1] then movementData.Tabs[1].Frame.Visible = true end
        Library.updateTabButtonsTheme(); updateModuleTogglesVisibility("Movement")
    end)
end

local Minus = Library.makeTopBtn("-", 3)
local Equal = Library.makeTopBtn("=", 2)
local X = Library.makeTopBtn("X", 1)

local FULL_SIZE = UDim2.new(0, 940, 0, 510)
local STRIP_SIZE = UDim2.new(0, 940, 0, 45)
local windowState = "full"

local function tweenSize(target, cb)
    local tw = game:GetService("TweenService"):Create(Library.FuckYou, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = target})
    if cb then tw.Completed:Connect(function(ps) if ps == Enum.PlaybackState.Completed then cb() end end) end
    tw:Play()
end

local function openFull()
    Library.FuckYou.Visible = true; Library.uiCollapsed = false; Library.applyBackground(); tweenSize(FULL_SIZE); windowState = "full"
end

X.MouseButton1Click:Connect(function() Library.ScreenGui:Destroy() end)
Equal.MouseButton1Click:Connect(function()
    if windowState == "full" then windowState = "strip"; Library.uiCollapsed = true; Library.applyBackground(); tweenSize(STRIP_SIZE)
    elseif windowState == "strip" then openFull() end
end)
Minus.MouseButton1Click:Connect(function()
    windowState = "hidden"; Library.uiCollapsed = true; Library.applyBackground()
    tweenSize(UDim2.new(0, 940, 0, 0), function() Library.FuckYou.Visible = false end)
end)

game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Library.currentToggleKey and Library.unlocked then
        if windowState == "hidden" then openFull() else windowState = "hidden"; Library.FuckYou.Visible = false end
    end
end)

Library.makeDraggable(Library.TopBar, Library.FuckYou)
Library.applyTheme(); Library.applyBackground(); Library.updateBlur()

task.spawn(function() Library.checkKeySystem(keyTextBox, keyInfoLabel) end)
task.spawn(function() while true do task.wait(600); if Library.autoSaveConfig then Library.autoSaveConfig(true) end end end)

local KeyListAPI = (function()
    local KL = {Enabled = true, ShowEmily = true, ShowDesync = true, ShowMusic = true, ShowAim = true, ShowMovement = true}
    local overlay = Library.create("Frame", {Name = "FYKeyList", Parent = Library.ScreenGui, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.new(0, 250, 0, 60), BackgroundColor3 = Library.uiColor_MainWindow, BorderColor3 = Library.COL_BORDER, BorderSizePixel = 1, Visible = false, ZIndex = 5})
    table.insert(Library.themeElements.MainWindow, overlay)
    local titleBar = Library.create("TextLabel", {Parent = overlay, Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0, 0, 0, 2), BackgroundTransparency = 1, Text = "KEYBINDS", TextColor3 = Library.uiColor_TextColor, TextSize = 13, Font = Library.FONT, ZIndex = 6})
    table.insert(Library.themeElements.Texts, titleBar)
    local rowsFrame = Library.create("Frame", {Parent = overlay, Size = UDim2.new(1, 0, 1, -26), Position = UDim2.new(0, 0, 0, 26), BackgroundTransparency = 1, ZIndex = 6})
    local rowsLayout = Library.create("UIListLayout", {Parent = rowsFrame, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)})
    local GROUP_MAP = {{"ShowEmily", "EmilyUi", "EMILYUI"}, {"ShowDesync", "Desync", "DESYNC"}, {"ShowMusic", "Music", "MUSIC"}, {"ShowAim", "Aim", "AIM"}, {"ShowMovement", "Movement", "MOVEMENT"}}
    local function collectRows()
        local out = {}
        for _, g in ipairs(GROUP_MAP) do
            if KL[g[1]] then
                local fn = Library.keyListProviders[g[2]]
                if fn then
                    local ok, rows = pcall(fn); rows = (ok and type(rows) == "table") and rows or {}
                    if #rows > 0 then
                        table.insert(out, {"h", g[3]})
                        for _, r in ipairs(rows) do table.insert(out, {"r", tostring(r[1]), tostring(r[2])}) end
                    end
                end
            end
        end
        return out
    end
    local function rebuild()
        for _, ch in ipairs(rowsFrame:GetChildren()) do if ch:IsA("Frame") or ch:IsA("TextLabel") then ch:Destroy() end end
        for i, it in ipairs(collectRows()) do
            if it[1] == "h" then
                local h = Library.create("TextLabel", {Parent = rowsFrame, LayoutOrder = i, Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Text = it[2], TextColor3 = Library.uiColor_TextColor, TextSize = 11, Font = Library.FONT, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6})
                table.insert(Library.themeElements.Texts, h)
            else
                local r = Library.create("Frame", {Parent = rowsFrame, LayoutOrder = i, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, ZIndex = 6})
                Library.create("TextLabel", {Parent = r, Size = UDim2.new(0.62, 0, 1, 0), BackgroundTransparency = 1, Text = it[2], TextColor3 = Library.uiColor_TextColor, TextSize = 12, Font = Library.FONT, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6})
                Library.create("TextLabel", {Parent = r, Size = UDim2.new(0.38, 0, 1, 0), Position = UDim2.new(0.62, 0, 0, 0), BackgroundTransparency = 1, Text = it[3], TextColor3 = Library.uiColor_ToggleOnText, TextSize = 12, Font = Library.FONT, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6})
            end
        end
        overlay.Size = UDim2.new(0, 250, 0, 26 + rowsLayout.AbsoluteContentSize.Y + 8)
    end
    task.spawn(function() while true do task.wait(0.5); if KL.Enabled and Library.unlocked then overlay.Visible = true; rebuild() else overlay.Visible = false end end end)
    Library.makeDraggable(titleBar, overlay)
    return {Gather = function() local out = {}; for k, v in pairs(KL) do out[k] = v end; return out end, Apply = function(d) if type(d) ~= "table" then return end; for k, v in pairs(d) do if KL[k] ~= nil then KL[k] = v end end end}
end)()
Library.KeyListAPI = KeyListAPI

print("[FuckYou UI] Loaded successfully!")