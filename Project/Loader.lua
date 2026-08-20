-- Loader.lua
-- Загружает все 6 модулей в правильном порядке

local baseUrl = "https://raw.githubusercontent.com/MamaSdoxla/EmilyUiRaw/refs/heads/main/Project/"  -- измените под свой URL

local modules = {
    "FuckYouLibrary.lua",
    "EmilyUiModule.lua",
    "DesyncModule.lua",
    "MusicModule.lua",
    "AimModule.lua",
    "MovementModule.lua"
}

for _, name in ipairs(modules) do
    local url = baseUrl .. name
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if not success then
        warn("Ошибка загрузки " .. name .. ": " .. tostring(result))
        return
    end
end

print("Все модули успешно загружены!")