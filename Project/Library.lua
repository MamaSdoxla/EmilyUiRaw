--// FuckYou UI Library v1.0
--// Modular UI Library based on FuckYou UI

local Library = {
    Version = "1.0.0",
    Theme = {
        MainWindow = Color3.fromRGB(12, 12, 12),
        TopBar = Color3.fromRGB(22, 22, 22),
        SideBar = Color3.fromRGB(12, 12, 12),
        Text = Color3.fromRGB(139, 135, 127),
        Button = Color3.fromRGB(12, 12, 12),
        TextBox = Color3.fromRGB(18, 18, 18),
        ToggleOn = Color3.fromRGB(100, 255, 100),
        ToggleOff = Color3.fromRGB(255, 100, 100),
        Border = Color3.fromRGB(22, 22, 22),
    },
    Font = Enum.Font.SpecialElite,
    Opacity = 1,
    Tabs = {},
    SidebarButtons = {},
    CurrentTab = nil,
    Window = nil,
    TopBar = nil,
    Sidebar = nil,
    ContentArea = nil,
    MenuSidebar = nil,
}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function CreateInstance(class, properties)
    local inst = Instance.new(class)
    for k, v in pairs(properties) do inst[k] = v end
    return inst
end

local function ParseRGB(str)
    local r, g, b = string.match(str, "(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
    return r and Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b)) or nil
end

function Library:Notify(title, text, duration)
    duration = duration or 15
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)
    if not playerGui then return end
    
    local gui = CreateInstance("ScreenGui", {Name = "Notification_" .. os.time(), ResetOnSpawn = false, IgnoreGuiInset = true, Parent = playerGui})
    local main = CreateInstance("Frame", {AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.new(0, 300, 0, 64), BackgroundColor3 = self.Theme.MainWindow, BorderColor3 = self.Theme.Border, BorderSizePixel = 1, Parent = gui})
    
    CreateInstance("TextLabel", {Size = UDim2.new(1, -16, 0, 20), Position = UDim2.new(0, 8, 0, 6), BackgroundTransparency = 1, Text = title, Font = self.Font, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 255, 255), Parent = main})
    CreateInstance("TextLabel", {Size = UDim2.new(1, -16, 0, 30), Position = UDim2.new(0, 8, 0, 26), BackgroundTransparency = 1, Text = text, Font = self.Font, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, TextColor3 = self.Theme.Text, Parent = main})
    
    task.delay(duration, function() gui:Destroy() end)
    return gui
end

function Library:CreateWindow(settings)
    settings = settings or {}
    local title = settings.Title or "FuckYou UI"
    local toggleKey = settings.ToggleKey or Enum.KeyCode.P
    
    self.Window = CreateInstance("Frame", {Name = "FuckYouWindow", Parent = LocalPlayer:WaitForChild("PlayerGui"), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 940, 0, 510), ClipsDescendants = true, Visible = false, BackgroundColor3 = self.Theme.MainWindow, BorderColor3 = self.Theme.Border, BorderSizePixel = 1})
    self.TopBar = CreateInstance("Frame", {Name = "TopBar", Parent = self.Window, Size = UDim2.new(1, 0, 0, 45), BackgroundColor3 = self.Theme.TopBar, BorderSizePixel = 0})
    CreateInstance("TextLabel", {Name = "Title", Parent = self.TopBar, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = title, TextColor3 = self.Theme.Text, TextSize = 13, Font = self.Font})
    
    local function CreateTopBtn(symbol, offset)
        local btn = CreateInstance("TextButton", {Name = symbol, Parent = self.TopBar, Position = UDim2.new(1, -45 * offset, 0, 0), Size = UDim2.new(0, 45, 0, 45), BackgroundColor3 = self.Theme.TopBar, BorderColor3 = self.Theme.Border, Text = symbol, TextColor3 = self.Theme.Text, TextSize = 13, Font = self.Font})
        btn.MouseEnter:Connect(function()
            local c = btn.BackgroundColor3
            btn.BackgroundColor3 = Color3.fromRGB(math.min(c.R * 255 + 10, 255), math.min(c.G * 255 + 10, 255), math.min(c.B * 255 + 10, 255))
        end)
        btn.MouseLeave:Connect(function() btn.BackgroundColor3 = self.Theme.TopBar end)
        return btn
    end
    
    local minimizeBtn = CreateTopBtn("-", 3)
    local expandBtn = CreateTopBtn("=", 2)
    local closeBtn = CreateTopBtn("X", 1)
    
    self.Sidebar = CreateInstance("Frame", {Name = "Sidebar", Parent = self.Window, Position = UDim2.new(0, 0, 0, 45), Size = UDim2.new(0, 65, 1, -45), BackgroundColor3 = self.Theme.SideBar, BorderSizePixel = 0})
    self.MenuSidebar = CreateInstance("ScrollingFrame", {Name = "MenuSidebar", Parent = self.Window, Position = UDim2.new(0, 65, 0, 45), Size = UDim2.new(0, 105, 1, -45), BackgroundColor3 = self.Theme.SideBar, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = self.Theme.Border, CanvasSize = UDim2.new(0, 0, 0, 0), ClipsDescendants = true})
    
    local menuLayout = CreateInstance("UIListLayout", {Parent = self.MenuSidebar, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)})
    CreateInstance("UIPadding", {Parent = self.MenuSidebar, PaddingTop = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)})
    menuLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() self.MenuSidebar.CanvasSize = UDim2.new(0, 0, 0, menuLayout.AbsoluteContentSize.Y + 10) end)
    
    self.ContentArea = CreateInstance("Frame", {Name = "ContentArea", Parent = self.Window, Position = UDim2.new(0, 170, 0, 45), Size = UDim2.new(1, -170, 1, -45), BackgroundTransparency = 1, BorderSizePixel = 0})
    
    CreateInstance("Frame", {Name = "SepH", Parent = self.Window, Position = UDim2.new(0, 0, 0, 45), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = self.Theme.Border, BorderSizePixel = 0})
    CreateInstance("Frame", {Name = "SepV1", Parent = self.Window, Position = UDim2.new(0, 65, 0, 46), Size = UDim2.new(0, 1, 1, -46), BackgroundColor3 = self.Theme.Border, BorderSizePixel = 0})
    CreateInstance("Frame", {Name = "SepV2", Parent = self.Window, Position = UDim2.new(0, 170, 0, 46), Size = UDim2.new(0, 1, 1, -46), BackgroundColor3 = self.Theme.Border, BorderSizePixel = 0})
    
    local state = "full"
    local fullSize = UDim2.new(0, 940, 0, 510)
    local stripSize = UDim2.new(0, 940, 0, 45)
    
    minimizeBtn.MouseButton1Click:Connect(function()
        if state == "full" then
            state = "hidden"
            local tween = TweenService:Create(self.Window, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, 940, 0, 0)})
            tween:Play()
            tween.Completed:Connect(function() self.Window.Visible = false end)
        else
            self.Window.Visible = true
            state = "full"
            TweenService:Create(self.Window, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = fullSize}):Play()
        end
    end)
    
    expandBtn.MouseButton1Click:Connect(function()
        if state == "full" then
            state = "strip"
            TweenService:Create(self.Window, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = stripSize}):Play()
        elseif state == "strip" then
            state = "full"
            self.Window.Visible = true
            TweenService:Create(self.Window, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = fullSize}):Play()
        end
    end)
    
    closeBtn.MouseButton1Click:Connect(function() self.Window:Destroy() end)
    
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == toggleKey then
            if self.Window.Visible then
                self.Window.Visible = false
                state = "hidden"
            else
                self.Window.Visible = true
                state = "full"
                TweenService:Create(self.Window, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = fullSize}):Play()
            end
        end
    end)
    
    local dragging, dragStart, startPos = false, nil, nil
    self.TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = self.Window.Position
        end
    end)
    self.TopBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            self.Window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    self.Window.Visible = true
    return self
end

function Library:CreateSidebarButton(text, callback)
    local offsetY = #self.SidebarButtons * 59
    local btn = CreateInstance("TextButton", {Name = text, Parent = self.Sidebar, Position = UDim2.new(0, 0, 0, offsetY), Size = UDim2.new(1, 0, 0, 59), BackgroundColor3 = self.Theme.SideBar, BorderColor3 = self.Theme.Border, Text = text, TextColor3 = self.Theme.Text, TextSize = 12, Font = self.Font})
    btn.MouseEnter:Connect(function()
        local c = btn.BackgroundColor3
        btn.BackgroundColor3 = Color3.fromRGB(math.min(c.R * 255 + 10, 255), math.min(c.G * 255 + 10, 255), math.min(c.B * 255 + 10, 255))
    end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = self.Theme.SideBar end)
    if callback then btn.MouseButton1Click:Connect(callback) end
    table.insert(self.SidebarButtons, btn)
    return btn
end

function Library:CreateTab(name)
    local tabFrame = CreateInstance("ScrollingFrame", {Name = "Tab_" .. name, Parent = self.ContentArea, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = self.Theme.Border, CanvasSize = UDim2.new(0, 0, 0, 0), Visible = false})
    local layout = CreateInstance("UIListLayout", {Parent = tabFrame, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
    CreateInstance("UIPadding", {Parent = tabFrame, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)})
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() tabFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20) end)
    
    local btn = CreateInstance("TextButton", {Name = "Btn_" .. name, Parent = self.MenuSidebar, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = #self.Tabs + 1, BackgroundColor3 = self.Theme.Button, BorderColor3 = self.Theme.Border, TextColor3 = self.Theme.Text, Text = name, Font = self.Font, TextSize = 12})
    
    btn.MouseButton1Click:Connect(function()
        for _, tab in ipairs(self.Tabs) do
            tab.Frame.Visible = false
            tab.Button.BackgroundColor3 = self.Theme.Button
            tab.Button.TextColor3 = self.Theme.Text
        end
        tabFrame.Visible = true
        btn.BackgroundColor3 = self.Theme.Button
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        self.CurrentTab = tabFrame
    end)
    
    local tabData = {Name = name, Frame = tabFrame, Button = btn, Elements = {}}
    table.insert(self.Tabs, tabData)
    if #self.Tabs == 1 then btn.MouseButton1Click:Fire() end
    return tabData
end

function Library:CreateSection(tab, text)
    local label = CreateInstance("TextLabel", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = text, TextColor3 = self.Theme.Text, TextSize = 13, Font = self.Font, Parent = tab.Frame})
    table.insert(tab.Elements, label)
    return label
end

function Library:CreateLabel(tab, text)
    local label = CreateInstance("TextLabel", {Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = text, TextColor3 = self.Theme.Text, TextSize = 13, Font = self.Font, TextXAlignment = Enum.TextXAlignment.Left, Parent = tab.Frame})
    table.insert(tab.Elements, label)
    return label
end

function Library:CreateButton(tab, text, callback)
    local btn = CreateInstance("TextButton", {Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = self.Theme.Button, BorderColor3 = self.Theme.Border, TextColor3 = self.Theme.Text, Text = text, Font = self.Font, TextSize = 13, Parent = tab.Frame})
    btn.MouseEnter:Connect(function()
        local c = btn.BackgroundColor3
        btn.BackgroundColor3 = Color3.fromRGB(math.min(c.R * 255 + 10, 255), math.min(c.G * 255 + 10, 255), math.min(c.B * 255 + 10, 255))
    end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = self.Theme.Button end)
    if callback then btn.MouseButton1Click:Connect(callback) end
    table.insert(tab.Elements, btn)
    return btn
end

function Library:CreateTextBox(tab, placeholder, callback)
    local box = CreateInstance("TextBox", {BackgroundColor3 = self.Theme.TextBox, BorderColor3 = self.Theme.Border, TextColor3 = self.Theme.Text, PlaceholderColor3 = Color3.fromRGB(90, 90, 90), PlaceholderText = placeholder, Text = "", TextSize = 13, Font = self.Font, ClearTextOnFocus = false, Parent = tab.Frame})
    if callback then
        box.FocusLost:Connect(function(enterPressed)
            if enterPressed then callback(box.Text) end
        end)
    end
    table.insert(tab.Elements, box)
    return box
end

function Library:CreateSlider(tab, labelText, min, max, default, callback)
    local container = CreateInstance("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = tab.Frame})
    CreateInstance("TextLabel", {Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1, Text = labelText, TextColor3 = self.Theme.Text, TextSize = 13, Font = self.Font, TextXAlignment = Enum.TextXAlignment.Left, Parent = container})
    local valLabel = CreateInstance("TextLabel", {Size = UDim2.new(0.5, 0, 0, 14), Position = UDim2.new(0.48, 0, 0.05, 0), BackgroundTransparency = 1, Text = tostring(default or min), TextColor3 = self.Theme.Text, TextSize = 13, Font = self.Font, TextXAlignment = Enum.TextXAlignment.Right, Parent = container})
    local track = CreateInstance("TextButton", {Size = UDim2.new(0.5, 0, 0, 10), Position = UDim2.new(0.48, 0, 0.55, 0), BackgroundColor3 = self.Theme.TextBox, BorderColor3 = self.Theme.Border, Text = "", Parent = container})
    local fill = CreateInstance("Frame", {Size = UDim2.new((default or min) / (max - min), 0, 1, 0), BackgroundColor3 = self.Theme.Text, BorderSizePixel = 0, Parent = track})
    
    local dragging = false
    local function updateFromX(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + (max - min) * rel + 0.5)
        fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
        valLabel.Text = tostring(value)
        if callback then callback(value) end
    end
    
    track.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then updateFromX(input.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    table.insert(tab.Elements, container)
    return container
end

function Library:CreateToggle(tab, labelText, default, callback)
    local state = default or false
    local btn = CreateInstance("TextButton", {Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = self.Theme.Button, BorderColor3 = self.Theme.Border, TextColor3 = self.Theme.Text, Text = "", Font = self.Font, TextSize = 13, Parent = tab.Frame})
    
    local function updateText()
        btn.Text = labelText .. ": " .. (state and "ON" or "OFF")
        btn.BackgroundColor3 = state and Color3.fromRGB(100, 40, 40) or Color3.fromRGB(40, 100, 40)
        btn.TextColor3 = state and self.Theme.ToggleOff or self.Theme.ToggleOn
    end
    updateText()
    
    btn.MouseButton1Click:Connect(function()
        state = not state
        updateText()
        if callback then callback(state) end
    end)
    table.insert(tab.Elements, btn)
    return btn
end

function Library:CreateDropdown(tab, labelText, options, default, callback)
    local container = CreateInstance("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = tab.Frame})
    CreateInstance("TextLabel", {Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1, Text = labelText, TextColor3 = self.Theme.Text, TextSize = 13, Font = self.Font, TextXAlignment = Enum.TextXAlignment.Left, Parent = container})
    local currentValue = default or options[1]
    local btn = CreateInstance("TextButton", {Size = UDim2.new(0.5, 0, 0, 28), Position = UDim2.new(0.48, 0, 0.1, 0), BackgroundColor3 = self.Theme.Button, BorderColor3 = self.Theme.Border, TextColor3 = self.Theme.Text, Text = labelText .. ": " .. currentValue, Font = self.Font, TextSize = 12, Parent = container})
    local list = CreateInstance("ScrollingFrame", {Parent = container, Size = UDim2.new(0.5, 0, 0, 110), Position = UDim2.new(0.48, 0, 0.95, 0), BackgroundColor3 = self.Theme.TextBox, BorderColor3 = self.Theme.Border, ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 0), Visible = false, ZIndex = 25})
    CreateInstance("UIListLayout", {Parent = list, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2)})
    
    btn.MouseButton1Click:Connect(function() list.Visible = not list.Visible end)
    for _, opt in ipairs(options) do
        local optBtn = CreateInstance("TextButton", {Size = UDim2.new(1, -4, 0, 24), BackgroundColor3 = self.Theme.Button, BorderColor3 = self.Theme.Border, TextColor3 = self.Theme.Text, Text = opt, Font = self.Font, TextSize = 12, ZIndex = 26, Parent = list})
        optBtn.MouseButton1Click:Connect(function()
            currentValue = opt
            btn.Text = labelText .. ": " .. opt
            list.Visible = false
            if callback then callback(opt) end
        end)
    end
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() list.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 4) end)
    table.insert(tab.Elements, container)
    return container
end

function Library:CreateKeySystem(settings)
    settings = settings or {}
    local keyUrl = settings.KeyUrl or ""
    local secretKey = settings.SecretKey or ""
    local onSuccess = settings.OnSuccess or function() end
    local onFailure = settings.OnFailure or function() end
    
    local keyWindow = CreateInstance("Frame", {Name = "KeyWindow", Parent = self.Window, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 450, 0, 310), BackgroundColor3 = self.Theme.MainWindow, BorderColor3 = self.Theme.Border, ZIndex = 100})
    CreateInstance("Frame", {Parent = keyWindow, Size = UDim2.new(1, 0, 0, 35), BackgroundColor3 = self.Theme.TopBar, BorderSizePixel = 0})
    CreateInstance("TextLabel", {Parent = keyWindow, Size = UDim2.new(1, -40, 0, 35), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = "Key System", TextColor3 = self.Theme.Text, TextSize = 15, Font = self.Font, TextXAlignment = Enum.TextXAlignment.Left})
    local infoLabel = CreateInstance("TextLabel", {Parent = keyWindow, Size = UDim2.new(1, -30, 0, 40), Position = UDim2.new(0, 15, 0, 50), BackgroundTransparency = 1, Text = "Please enter your access key below.", TextColor3 = self.Theme.Text, TextSize = 13, Font = self.Font, TextWrapped = true})
    local keyBox = CreateInstance("TextBox", {Parent = keyWindow, Size = UDim2.new(1, -40, 0, 36), Position = UDim2.new(0, 20, 0, 160), BackgroundColor3 = self.Theme.TextBox, BorderColor3 = self.Theme.Border, TextColor3 = self.Theme.Text, PlaceholderColor3 = Color3.fromRGB(90, 90, 90), PlaceholderText = "Enter key here...", Text = "", TextSize = 13, Font = self.Font})
    
    local function checkKey()
        local enteredKey = keyBox.Text
        if keyUrl ~= "" then
            local success, response = pcall(function() return game:HttpGet(keyUrl) end)
            if success and response:find(enteredKey) then
                keyWindow:Destroy()
                onSuccess()
            else
                infoLabel.Text = success and "Invalid key!" or "Failed to fetch key database!"
                infoLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                onFailure()
            end
        else
            if enteredKey == secretKey then
                keyWindow:Destroy()
                onSuccess()
            else
                infoLabel.Text = "Invalid key!"
                infoLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                onFailure()
            end
        end
    end
    
    local submitBtn = CreateInstance("TextButton", {Parent = keyWindow, Size = UDim2.new(0, 150, 0, 36), Position = UDim2.new(0.5, -75, 0, 240), BackgroundColor3 = Color3.fromRGB(40, 90, 40), BorderColor3 = self.Theme.Border, TextColor3 = Color3.fromRGB(255, 255, 255), Text = "Check Key", Font = self.Font, TextSize = 13})
    submitBtn.MouseButton1Click:Connect(checkKey)
    keyBox.FocusLost:Connect(function(enterPressed) if enterPressed then checkKey() end end)
    return keyWindow
end

function Library:CreateSettingsTab()
    local settingsTab = self:CreateTab("Settings")
    self:CreateSection(settingsTab, "UI Customization")
    local colors = {{name = "Main Window", key = "MainWindow"}, {name = "Top Bar", key = "TopBar"}, {name = "Side Bar", key = "SideBar"}, {name = "Text", key = "Text"}, {name = "Button", key = "Button"}}
    for _, color in ipairs(colors) do
        self:CreateTextBox(settingsTab, color.name .. " Color (R,G,B)", function(text)
            local newColor = ParseRGB(text)
            if newColor then self.Theme[color.key] = newColor end
        end)
    end
    return settingsTab
end

-- ЭТО ДОЛЖНА БЫТЬ ПОСЛЕДНЯЯ СТРОКА В ФАЙЛЕ БИБЛИОТЕКИ
return Library