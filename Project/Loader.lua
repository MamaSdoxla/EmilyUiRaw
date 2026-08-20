-- Полифил для task
if not _G.task then
    _G.task = {
        spawn = function(f) return coroutine.wrap(f)() end,
        wait = function(t) return wait(t) end,
        delay = function(t, f) return delay(t, f) end,
        defer = function(f) return spawn(f) end,
        cancel = function() end,
    }
end

-- Загрузка модулей
local baseUrl = "https://raw.githubusercontent.com/MamaSdoxla/EmilyUiRaw/refs/heads/main/Project/"
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
    local success, err = pcall(function()
        loadstring(game:HttpGet(url))()
    end)
    if not success then
        warn("Ошибка загрузки " .. name .. ": " .. tostring(err))
        return
    end
end

print("Все модули загружены!")