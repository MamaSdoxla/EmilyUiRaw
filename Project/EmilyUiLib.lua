local Library = {}

-- 3. ИСПРАВЛЕНИЕ: Экспорт цветов для использования в других модулях
Library.Constants = {
    COL_BG = Color3.fromRGB(12, 12, 12),
    COL_BORDER = Color3.fromRGB(22, 22, 22),
    COL_TEXT = Color3.fromRGB(139, 135, 127),
    COL_TEXTBOX = Color3.fromRGB(18, 18, 18),
    FONT = Enum.Font.SpecialElite
}

Library.Modules = {}          -- 6. ИСПРАВЛЕНИЕ: Хранилище API модулей
Library.SidebarButtons = {}
Library.ModuleFrames = {}
Library.keyListProviders = {} -- 7. ИСПРАВЛЕНИЕ: Реестр провайдеров KeyList

function Library.registerKeyListProvider(group, fn)
    Library.keyListProviders[group] = fn
end

-- 1. ИСПРАВЛЕНИЕ: Глобальный переключатель модулей
function Library.switchModule(moduleName)
    -- Скрыть все кнопки всех модулей
    for _, btn in ipairs(Library.SidebarButtons) do
        btn.Visible = false
    end
    -- Скрыть все фреймы контента
    for _, frame in ipairs(Library.ModuleFrames) do
        frame.Visible = false
    end
    
    -- Показать кнопки и первый фрейм нужного модуля
    if Library.Modules[moduleName] then
        for _, btn in ipairs(Library.Modules[moduleName].Buttons) do
            btn.Visible = true
        end
        if Library.Modules[moduleName].Frames[1] then
            Library.Modules[moduleName].Frames[1].Visible = true
        end
    end
    Library.applyTheme()
end

-- 5. ИСПРАВЛЕНИЕ: Переключение табов внутри модуля
function Library.switchTab(moduleName, targetFrame)
    if Library.Modules[moduleName] then
        for _, frame in ipairs(Library.Modules[moduleName].Frames) do
            frame.Visible = (frame == targetFrame)
        end
    end
    Library.applyTheme()
end

-- 4. ИСПРАВЛЕНИЕ: Единое создание кнопок сайдбара с LayoutOrder
function Library.AddSidebarButton(name, order, moduleName)
    local btn = Instance.new("TextButton")
    btn.Name = "SideBtn_" .. name
    btn.Size = UDim2.new(1, 0, 0, 59)
    btn.Position = UDim2.new(0, 0, 0, (order - 1) * 59)
    btn.LayoutOrder = order
    btn.BackgroundColor3 = Library.Constants.COL_BG
    btn.BorderColor3 = Library.Constants.COL_BORDER
    btn.TextColor3 = Library.Constants.COL_TEXT
    btn.Text = name
    btn.Font = Library.Constants.FONT
    btn.TextSize = 12
    
    btn.MouseButton1Click:Connect(function()
        Library.switchModule(moduleName)
    end)
    
    table.insert(Library.SidebarButtons, btn)
    
    if not Library.Modules[moduleName] then
        Library.Modules[moduleName] = { Buttons = {}, Frames = {} }
    end
    table.insert(Library.Modules[moduleName].Buttons, btn)
    return btn
end

function Library.AddContentFrame(name, parent, moduleName)
    local frame = Instance.new("ScrollingFrame")
    frame.Name = "Tab_" .. name
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = parent
    
    -- Добавляем UIListLayout для автоматического размещения элементов
    local layout = Instance.new("UIListLayout")
    layout.Parent = frame
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    
    table.insert(Library.ModuleFrames, frame)
    if Library.Modules[moduleName] then
        table.insert(Library.Modules[moduleName].Frames, frame)
    end
    return frame
end

-- 2. ИСПРАВЛЕНИЕ: Правильная сигнатура CreateDropdown (getOptions ДОЛЖЕН быть функцией)
function Library.CreateDropdown(parent, labelText, getOptions, getCurrent, onselect)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 36)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.45, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Library.Constants.COL_TEXT
    label.TextSize = 13
    label.Font = Library.Constants.FONT
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.5, 0, 0.8, 0)
    btn.Position = UDim2.new(0.48, 0, 0.1, 0)
    btn.BackgroundColor3 = Library.Constants.COL_BG
    btn.BorderColor3 = Library.Constants.COL_BORDER
    btn.TextColor3 = Library.Constants.COL_TEXT
    btn.Text = labelText .. ": " .. tostring(getCurrent())
    btn.Font = Library.Constants.FONT
    btn.TextSize = 12
    btn.Parent = container

    local list = Instance.new("ScrollingFrame")
    list.Parent = container
    list.Size = UDim2.new(0.5, 0, 0, 110)
    list.Position = UDim2.new(0.48, 0, 0.95, 0)
    list.BackgroundColor3 = Library.Constants.COL_TEXTBOX
    list.BorderColor3 = Library.Constants.COL_BORDER
    list.ScrollBarThickness = 4
    list.Visible = false
    list.ZIndex = 25
    Instance.new("UIListLayout", list).Padding = UDim.new(0, 2)

    btn.MouseButton1Click:Connect(function()
        if list.Visible then list.Visible = false return end
        for _, ch in ipairs(list:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
        
        -- 2. ИСПРАВЛЕНИЕ: Вызов функции, а не таблицы
        local opts = getOptions() 
        for _, opt in ipairs(opts) do
            local ob = Instance.new("TextButton")
            ob.Parent = list
            ob.Size = UDim2.new(1, -4, 0, 24)
            ob.BackgroundColor3 = Library.Constants.COL_BG
            ob.TextColor3 = Library.Constants.COL_TEXT
            ob.Text = opt
            ob.ZIndex = 26
            ob.MouseButton1Click:Connect(function()
                onselect(opt)
                list.Visible = false
                btn.Text = labelText .. ": " .. tostring(getCurrent())
                if Library.saveConfig then Library.saveConfig() end
            end)
 a       end
        list.CanvasSize = UDim2.new(0, 0, 0, #opts * 26 + 4)
        list.Visible = true
    end)
    return container
end

-- Заглушки, которые будут переопределены в Loader.lua
Library.applyTheme = function() end
Library.saveConfig = function() end

return Library