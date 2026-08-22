local Library = require("EmilyUiLib")

-- 3. ИСПРАВЛЕНИЕ: Используем экспортированный цвет вместо необъявленной переменной
local COL_BORDER = Library.Constants.COL_BORDER

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FuckYouGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local MainWindow = Instance.new("Frame")
MainWindow.Name = "FuckYou"
MainWindow.Parent = ScreenGui
MainWindow.Size = UDim2.new(0, 940, 0, 510)
MainWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
MainWindow.AnchorPoint = Vector2.new(0.5, 0.5)
MainWindow.BackgroundColor3 = Library.Constants.COL_BG
MainWindow.BorderColor3 = COL_BORDER -- 3. ИСПРАВЛЕНИЕ
MainWindow.Visible = false

local SideBar = Instance.new("Frame")
SideBar.Name = "SideBar"
SideBar.Parent = MainWindow
SideBar.Size = UDim2.new(0, 65, 1, -45)
SideBar.Position = UDim2.new(0, 0, 0, 45)
SideBar.BackgroundColor3 = Library.Constants.COL_BG
SideBar.BorderColor3 = COL_BORDER

local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "Containment"
ContentContainer.Parent = MainWindow
ContentContainer.Size = UDim2.new(1, -65, 1, -45)
ContentContainer.Position = UDim2.new(0, 65, 0, 45)
ContentContainer.BackgroundTransparency = 1

-- 4. ИСПРАВЛЕНИЕ: Используем единую систему добавления кнопок
Library.AddSidebarButton("EmilyUi", 1, "EmilyUi")

-- Создаем фреймы для модуля EmilyUi
local mainFrame = Library.AddContentFrame("Main", ContentContainer, "EmilyUi")
local settingsFrame = Library.AddContentFrame("Settings", ContentContainer, "EmilyUi")

-- Пример контента
local settingsBtn = Instance.new("TextButton")
settingsBtn.Parent = mainFrame
settingsBtn.Size = UDim2.new(1, 0, 0, 30)
settingsBtn.Text = "Open Settings"
settingsBtn.MouseButton1Click:Connect(function()
    -- 5. ИСПРАВЛЕНИЕ: Переключение таба внутри модуля
    Library.switchTab("EmilyUi", settingsFrame)
end)

return {
    Gather = function() return {} end,
    Apply = function(data) end
}