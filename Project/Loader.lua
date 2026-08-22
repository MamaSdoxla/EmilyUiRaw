local Library = require("EmilyUiLib") -- Укажи правильный путь

-- 6. ИСПРАВЛЕНИЕ: Инициализация модулей и сохранение их API
-- Пути require должны соответствовать твоей структуре
Library.Modules.Desync = require("DesyncModule")(Library)
Library.Modules.Music = require("MusicModule")(Library)
Library.Modules.Aim = require("AimModule")(Library)
Library.Modules.Movement = require("MovementModule")(Library)
Library.Modules.EmilyUi = require("EmilyUiModule")(Library)

-- Глобальная функция сохранения конфигурации
function Library.saveConfig()
    local config = {
        ToggleKey = "P", -- Заменить на реальную переменную
        -- ... основные цвета UI ...
    }
    
    -- 6. ИСПРАВЛЕНИЕ: Сбор данных из всех модулей через их API
    for moduleName, moduleAPI in pairs(Library.Modules) do
        if moduleAPI and type(moduleAPI.Gather) == "function" then
            config[moduleName] = moduleAPI.Gather()
        end
    end
    
    -- Логика записи в файл (writefile)
    pcall(function()
        writefile("EmilyUi/Config.json", game:GetService("HttpService"):JSONEncode(config))
    end)
end

-- Глобальная функция загрузки конфигурации
function Library.loadConfig()
    local success, json = pcall(function() return readfile("EmilyUi/Config.json") end)
    if not success or not json then return end
    
    local ok, config = pcall(function() return game:GetService("HttpService"):JSONDecode(json) end)
    if not ok or type(config) ~= "table" then return end

    -- 6. ИСПРАВЛЕНИЕ: Применение конфигов модулей ПОСЛЕ их инициализации
    for moduleName, moduleAPI in pairs(Library.Modules) do
        if config[moduleName] and type(moduleAPI.Apply) == "function" then
            moduleAPI.Apply(config[moduleName])
        end
    end
end

-- Функция разблокировки (вызывается после успешного ввода ключа)
function Library.onUnlock()
    Library.loadConfig()
    Library.applyTheme()
    Library.switchModule("EmilyUi") -- 1. ИСПРАВЛЕНИЕ: Правильный старт
    Library.saveConfig()
end

-- Запуск проверки ключа или немедленная разблокировка для тестов
task.spawn(function()
    -- Здесь твоя логика проверки ключа
    -- При успехе: Library.onUnlock()
    Library.onUnlock() 
end)