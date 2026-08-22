local Library = require("EmilyUiLib")

Library.AddSidebarButton("Desync", 2, "Desync")

local DesyncSectionEnabled = false
local IsDesynced = false

-- 8. ИСПРАВЛЕНИЕ: Корректное переключение состояния
local function toggleDesyncSection()
    DesyncSectionEnabled = not DesyncSectionEnabled
    if not DesyncSectionEnabled and IsDesynced then
        -- Логика остановки десинка
        IsDesynced = false
    end
    if Library.saveConfig then Library.saveConfig() end
end

local desyncFrame = Library.AddContentFrame("Main", game:GetService("Players").LocalPlayer.PlayerGui.FuckYouGui.FuckYou.Containment, "Desync")

local toggleBtn = Instance.new("TextButton")
toggleBtn.Parent = desyncFrame
toggleBtn.Size = UDim2.new(1, 0, 0, 30)
toggleBtn.Text = "Enable Desync Module"
toggleBtn.MouseButton1Click:Connect(toggleDesyncSection)

local startBtn = Instance.new("TextButton")
startBtn.Parent = desyncFrame
startBtn.Size = UDim2.new(1, 0, 0, 30)
startBtn.Text = "Start Desync"
startBtn.MouseButton1Click:Connect(function()
    -- 8. ИСПРАВЛЕНИЕ: Проверка флага перед запуском
    if not DesyncSectionEnabled then 
        warn("Desync module is disabled!")
        return 
    end
    IsDesynced = true
    -- Логика запуска десинка
end)

-- 7. ИСПРАВЛЕНИЕ: Регистрация провайдера для KeyList
Library.registerKeyListProvider("Desync", function()
    local rows = {}
    if DesyncSectionEnabled and IsDesynced then
        table.insert(rows, {"DESYNC", "ACTIVE"})
    end
    return rows
end)

return {
    Gather = function()
        return { Enabled = DesyncSectionEnabled, IsDesynced = IsDesynced }
 end,
    Apply = function(data)
        if type(data) == "table" then
            DesyncSectionEnabled = data.Enabled or false
            IsDesynced = data.IsDesynced or false
        end
    end
}