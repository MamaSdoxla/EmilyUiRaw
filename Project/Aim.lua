local Library = require("EmilyUiLib")

Library.AddSidebarButton("Aim", 4, "Aim")

local aimFrame = Library.AddContentFrame("LegitBot", game:GetService("Players").LocalPlayer.PlayerGui.FuckYouGui.FuckYou.Containment, "Aim")

local Legit = {
    Mode = "Hold",
    AimPart = "All"
}

-- 2. ИСПРАВЛЕНИЕ: ВСЕ dropdown'ы теперь передают ФУНКЦИЮ, возвращающую таблицу
Library.CreateDropdown(aimFrame, "Mode",
    function() return {"Hold", "Toggle", "Always"} end, -- <-- ФУНКЦИЯ, а не таблица
    function() return Legit.Mode end,
    function(v) Legit.Mode = v end
)

Library.CreateDropdown(aimFrame, "Aim Part",
    function() return {"All", "Head", "RootPart"} end, -- <-- ФУНКЦИЯ, а не таблица
    function() return Legit.AimPart end,
    function(v) Legit.AimPart = v end
)

local ESP_Instances = {}

-- 8. ИСПРАВЛЕНИЕ: Корректная очистка ESP при выключении
local function setESPEnabled(state)
    if state then
        -- Логика создания ESP
    else
        -- Полная очистка
        for _, data in pairs(ESP_Instances) do
            pcall(function() data.Highlight:Destroy() end)
            pcall(function() data.BillboardTop:Destroy() end)
            pcall(function() data.BillboardBottom:Destroy() end)
        end
        ESP_Instances = {}
    end
end

Library.registerKeyListProvider("Aim", function()
    local rows = {}
    -- Логика сбора активных функций аимбота
    return rows
end)

return {
    Gather = function()
        return { LegitMode = Legit.Mode, LegitPart = Legit.AimPart }
    end,
    Apply = function(data)
        if type(data) == "table" then
            Legit.Mode = data.LegitMode or "Hold"
            Legit.AimPart = data.LegitPart or "All"
        end
    end
}