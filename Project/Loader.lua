--// Loader.lua
local BASE_URL = "https://raw.githubusercontent.com/MamaSdoxla/EmilyUiRaw/refs/heads/main/Project"

local function notify(title, text)
    -- Простая заглушка notify до загрузки библиотеки
    print("[" .. title .. "] " .. text)
end

local function loadScript(name, description)
    local url = BASE_URL .. "/" .. name
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if not success then
        notify("Ошибка загрузки", description .. ": " .. tostring(result))
        return nil
    end
    if type(result) ~= "function" and type(result) ~= "table" then
        notify("Ошибка инициализации", "Файл " .. name .. " не вернул ожидаемый модуль.")
        return nil
    end
    return result
end

-- 1. Загрузка библиотеки
local Library = loadScript("EmilyUiLib.lua", "Ошибка загрузки библиотеки")
if not Library then return end

-- Создаем временный notify через библиотеку
notify = Library.notify

-- 2. Загрузка главного модуля EmilyUi
local EmilyUiModule = loadScript("EmilyUi.lua", "Ошибка загрузки модуля EmilyUi")
if not EmilyUiModule then return end
local emilyData = EmilyUiModule(Library)
local mainSideBar = nil -- Будет передано, если нужно, или модуль сам его найдет
-- В данной архитектуре EmilyUi.lua сам создает сайдбар и возвращает окно.
-- Для упрощения передачи в другие модули, мы можем использовать глобальные ссылки или доработать Library.
-- Доработаем Library для хранения ссылок на основные контейнеры:
Library.MainSideBar = emilyData.Window:FindFirstChild("SideBar")
Library.MainMenu = emilyData.Window:FindFirstChild("MenuInsided")
Library.MainContainment = emilyData.Window:FindFirstChild("Containment")

-- 3. Загрузка модуля Desync
local DesyncModule = loadScript("Desync.lua", "Ошибка загрузки модуля Desync")
local desyncData = DesyncModule and DesyncModule(Library, Library.MainSideBar, Library.MainMenu, Library.MainContainment)

-- 4. Загрузка модуля Music
local MusicModule = loadScript("Music.lua", "Ошибка загрузки модуля Music")
local musicData = MusicModule and MusicModule(Library, Library.MainSideBar, Library.MainMenu, Library.MainContainment)

-- 5. Загрузка модуля Aim
local AimModule = loadScript("Aim.lua", "Ошибка загрузки модуля Aim")
local aimData = AimModule and AimModule(Library, Library.MainSideBar, Library.MainMenu, Library.MainContainment)

-- 6. Загрузка модуля Movement
local MovementModule = loadScript("Movement.lua", "Ошибка загрузки модуля Movement")
local movementData = MovementModule and MovementModule(Library, Library.MainSideBar, Library.MainMenu, Library.MainContainment)

-- 7. Инициализация и сборка конфигов
Library.registerConfigSaveListener(function()
    local extra = {}
    if aimData and aimData.Gather then extra.Aim = aimData.Gather() end
    if movementData and movementData.Gather then extra.Movement = movementData.Gather() end
    Library.autoSaveConfig(true, extra)
end)

-- Загрузка сохраненного конфига после инициализации всех модулей
task.defer(function()
    local cfg = Library.loadConfig()
    if cfg then
        if aimData and aimData.Apply and cfg.Aim then aimData.Apply(cfg.Aim) end
        if movementData and movementData.Apply and cfg.Movement then movementData.Apply(cfg.Movement) end
        Library.applyTheme()
    end
end)

-- Автосохранение каждые 10 минут
task.spawn(function()
    while true do
        task.wait(600)
        Library.autoSaveConfig(true)
    end
end)

notify("EmilyUi Loader", "All modules loaded successfully.")