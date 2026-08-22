local Library = require("EmilyUiLib")

Library.AddSidebarButton("Movement", 5, "Movement")

local movementFrame = Library.AddContentFrame("Main", game:GetService("Players").LocalPlayer.PlayerGui.FuckYouGui.FuckYou.Containment, "Movement")

-- 8. ИСПРАВЛЕНИЕ: Безопасная сериализация CFrame в таблицу чисел для JSON
local function serCF(cf)
    if typeof(cf) ~= "CFrame" then return {0, 0, 0} end
    return {cf:GetComponents()} -- Возвращает таблицу из 12 чисел
end

-- 8. ИСПРАВЛЕНИЕ: Безопасная десериализация таблицы чисел обратно в CFrame
local function deCF(t)
    if type(t) ~= "table" then return CFrame.new() end
    if #t >= 12 then
        local ok, cf = pcall(function() return CFrame.new(unpack(t, 1, 12)) end)
        if ok then return cf end
    end
    if #t >= 3 then return CFrame.new(t[1], t[2], t[3]) end
    return CFrame.new()
end

local testBtn = Instance.new("TextButton")
testBtn.Parent = movementFrame
testBtn.Size = UDim2.new(1, 0, 0, 30)
testBtn.Text = "Test CFrame Serialization"
testBtn.MouseButton1Click:Connect(function()
    local originalCF = CFrame.new(10, 20, 30) * CFrame.Angles(0, math.pi/4, 0)
    local serialized = serCF(originalCF)
    local restored = deCF(serialized)
    print("Original:", originalCF)
    print("Restored:", restored)
end)

Library.registerKeyListProvider("Movement", function()
    local rows = {}
    -- Логика сбора состояний мувмента
    return rows
end)

return {
    Gather = function()
        return { TestValue = 1 }
    end,
    Apply = function(data)
        -- Логика применения
    end
}