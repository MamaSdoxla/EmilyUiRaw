--// Loader.lua
local BASE_URL = "https://raw.githubusercontent.com/MamaSdoxla/EmilyUiRaw/refs/heads/main/Project"

local function loadScript(name)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(BASE_URL .. "/" .. name))()
    end)
    if not success then
        warn("Failed to load " .. name .. ": " .. tostring(result))
        return nil
    end
    return result
end

-- 1. Загрузка библиотеки
local Library = loadScript("EmilyUiLib.lua")
if not Library then 
    warn("Критическая ошибка: не удалось загрузить EmilyUiLib.lua")
    return 
end

-- 2. Загрузка главного модуля EmilyUi (он возвращает ссылки на UI-контейнеры)
local EmilyUiModule = loadScript("EmilyUi.lua")
if not EmilyUiModule then return end
local uiRefs = EmilyUiModule(Library)

-- 3-6. Загрузка модулей с передачей Library и uiRefs
local modules = {
    { name = "Desync.lua", desc = "Desync" },
    { name = "Music.lua", desc = "Music" },
    { name = "Aim.lua", desc = "Aim" },
    { name = "Movement.lua", desc = "Movement" }
}

for _, mod in ipairs(modules) do
    local ModuleFunc = loadScript(mod.name)
    if ModuleFunc then
        local success, err = pcall(function()
            ModuleFunc(Library, uiRefs)
        end)
        if not success then
            Library.notify("Ошибка инициализации", "Модуль " .. mod.desc .. " упал: " .. tostring(err))
        end
    else
        Library.notify("Ошибка загрузки", "Файл не найден: " .. mod.name)
    end
end

Library.notify("EmilyUi Loader", "All modules loaded successfully.")