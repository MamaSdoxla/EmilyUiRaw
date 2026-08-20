-- FuckYou Loader
-- Запускает модули строго в порядке:
-- Core -> EmilyUi -> Desync -> Music -> Aim -> Movement

local MODULES = {
    "FuckYouLibrary.lua",
    "EmilyUiModule.lua",
    "DesyncModule.lua",
    "MusicModule.lua",
    "AimModule.lua",
    "MovementModule.lua",
}

-- false: читать локальные .lua через readfile()
-- true: загружать модули через game:HttpGet()
local USE_REMOTE = false

-- Используется только при USE_REMOTE = true
local BASE_URL = "https://raw.githubusercontent.com/YOUR_NAME/YOUR_REPO/main/"

local function notify(title, text)
    if _G.FuckYouCore and _G.FuckYouCore.Notify then
        pcall(_G.FuckYouCore.Notify, title, text)
    else
        print(("[FuckYou Loader] %s: %s"):format(title, text))
    end
end

local function execute(source, chunkName)
    local compiler = loadstring or load
    if not compiler then
        return false, "loadstring/load недоступен"
    end

    local okCompile, chunk = pcall(compiler, source, "@" .. chunkName)
    if not okCompile or type(chunk) ~= "function" then
        return false, "ошибка компиляции: " .. tostring(chunk)
    end

    local okRun, result = pcall(chunk)
    if not okRun then
        return false, "ошибка выполнения: " .. tostring(result)
    end

    return true, result
end

local function loadLocal(fileName)
    if typeof(readfile) ~= "function" then
        return false, "readfile недоступен"
    end

    local ok, source = pcall(readfile, fileName)
    if not ok or type(source) ~= "string" or source == "" then
        return false, "не удалось прочитать " .. fileName
    end

    return execute(source, fileName)
end

local function loadRemote(fileName)
    local ok, source = pcall(function()
        return game:HttpGet(BASE_URL .. fileName)
    end)

    if not ok or type(source) ~= "string" or source == "" then
        return false, "не удалось загрузить " .. BASE_URL .. fileName
    end

    return execute(source, fileName)
end

local loaded = 0

for i, fileName in ipairs(MODULES) do
    notify("Loader", ("Загрузка %d/%d: %s"):format(i, #MODULES, fileName))

    local ok, err

    if USE_REMOTE then
        ok, err = loadRemote(fileName)
    else
        ok, err = loadLocal(fileName)
    end

    if not ok then
        warn("[FuckYou Loader] " .. tostring(err))
        notify("Loader Error", tostring(err))
        return
    end

    loaded += 1
end

notify("Loader", ("Готово: %d/%d модулей"):format(loaded, #MODULES))
print("[FuckYou Loader] Все модули успешно загружены.")
