--// Loader.lua - Пример загрузки модулей
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/MamaSdoxla/EmilyUiRaw/refs/heads/main/Project/lib.lua"))()

--// Создание окна
local Window = Library:CreateWindow({
    Title = "FuckYou UI v1.0",
    ToggleKey = Enum.KeyCode.P
})

--// Создание боковых кнопок
Window:CreateSidebarButton("Main", function()
    print("Main clicked")
end)

Window:CreateSidebarButton("Modules", function()
    print("Modules clicked")
end)

--// Создание вкладок
local mainTab = Window:CreateTab("Main Info")
local universalTab = Window:CreateTab("Universal")
local characterTab = Window:CreateTab("Character")

--// Добавление элементов во вкладки
Window:CreateSection(mainTab, "Welcome")
Window:CreateLabel(mainTab, "This is the main info tab")
Window:CreateButton(mainTab, "Click Me", function()
    Library:Notify("Notification", "Button clicked!", 5)
end)

--// Toggle
Window:CreateToggle(mainTab, "Enable Feature", true, function(state)
    print("Toggle state:", state)
end)

--// Slider
Window:CreateSlider(mainTab, "Speed", 1, 100, 50, function(value)
    print("Speed:", value)
end)

--// Dropdown
Window:CreateDropdown(mainTab, "Mode", {"Auto", "Manual", "Semi"}, "Auto", function(selected)
    print("Selected mode:", selected)
end)

--// TextBox
Window:CreateTextBox(mainTab, "Enter text...", function(text)
    print("Entered:", text)
end)

--// Key System (опционально)
--[[
Window:CreateKeySystem({
    KeyUrl = "https://example.com/keys.txt",
    SecretKey = "mysecretkey",
    OnSuccess = function()
        Library:Notify("Success", "Key validated!", 5)
    end,
    OnFailure = function()
        Library:Notify("Error", "Invalid key!", 5)
    end
})
]]

--// Settings tab (встроенный)
Window:CreateSettingsTab()

Library:Notify("Library Loaded", "FuckYou UI Library v1.0", 5)