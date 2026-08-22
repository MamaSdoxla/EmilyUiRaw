-- 1. Загружаем библиотеку (ЗАМЕНИТЕ URL на вашу реальную raw-ссылку на GitHub)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/MamaSdoxla/EmilyUiRaw/refs/heads/main/Project/Library.lua"))()

local Window = Library:CreateWindow({
    Title = "FuckYou UI v1.0",
    ToggleKey = Enum.KeyCode.P
})

-- Проверка что окно создано
print("Window created:", Window.Window)
print("Window visible:", Window.Window.Visible)
print("Window parent:", Window.Window.Parent)
Window.Window.Visible = true

-- 3. Создаем боковые кнопки
Window:CreateSidebarButton("Main", function()
    Library:Notify("Info", "Main sidebar clicked!")
end)

Window:CreateSidebarButton("Modules", function()
    Library:Notify("Info", "Modules sidebar clicked!")
end)

-- 4. Создаем вкладки
local mainTab = Window:CreateTab("Main Info")
local universalTab = Window:CreateTab("Universal")

-- 5. Добавляем элементы
Window:CreateSection(mainTab, "Welcome")
Window:CreateLabel(mainTab, "This is the main info tab")

Window:CreateButton(mainTab, "Click Me", function()
    Library:Notify("Success", "Button clicked!", 5)
end)

Window:CreateToggle(mainTab, "Enable Feature", true, function(state)
    Library:Notify("Toggle", "Feature is now: " .. tostring(state))
end)

Window:CreateSlider(mainTab, "Speed", 1, 100, 50, function(value)
    -- Действие при изменении
end)

Window:CreateDropdown(mainTab, "Mode", {"Auto", "Manual", "Semi"}, "Auto", function(selected)
    Library:Notify("Dropdown", "Selected: " .. selected)
end)

Window:CreateTextBox(mainTab, "Enter text...", function(text)
    Library:Notify("Input", "You entered: " .. text)
end)

-- 6. Встроенная вкладка настроек
Window:CreateSettingsTab()

Library:Notify("Library Loaded", "FuckYou UI Library v1.0 initialized", 5)