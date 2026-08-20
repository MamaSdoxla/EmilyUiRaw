---@diagnostic disable: undefined-global
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

if not localPlayer then
    return -- на случай, если скрипт запущен не на клиенте
end

-- Функция телепортации персонажа
local function teleportCharacter(character)
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        humanoidRootPart.CFrame = CFrame.new(-980, 3, -983)
    else
        -- если RootPart ещё не загружен, ждём его
        humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        humanoidRootPart.CFrame = CFrame.new(-980, 3, -983)
    end
end

-- Если персонаж уже существует, телепортируем сразу
if localPlayer.Character then
    teleportCharacter(localPlayer.Character)
end

-- Слушаем появление нового персонажа
localPlayer.CharacterAdded:Connect(teleportCharacter)