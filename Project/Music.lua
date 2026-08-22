local Library = require("EmilyUiLib")

Library.AddSidebarButton("Music", 3, "Music")

local musicFrame = Library.AddContentFrame("Main", game:GetService("Players").LocalPlayer.PlayerGui.FuckYouGui.FuckYou.Containment, "Music")

local currentSound = nil

-- 8. ИСПРАВЛЕНИЕ: Исправлена функция создания звука (убран таймер на 2 секунды)
local function makeMusicSound(id)
    if currentSound then
        currentSound:Stop()
        currentSound:Destroy()
    end
    local s = Instance.new("Sound")
    s.Name = "MusicPlayer"
    s.SoundId = "rbxassetid://" .. tostring(id)
    s.Volume = 1
    s.Looped = true
    s.Parent = game:GetService("SoundService")
    currentSound = s
    return s
end

local playBtn = Instance.new("TextButton")
playBtn.Parent = musicFrame
playBtn.Size = UDim2.new(1, 0, 0, 30)
playBtn.Text = "Play ID: 1838730782"
playBtn.MouseButton1Click:Connect(function()
    local s = makeMusicSound(1838730782)
    s:Play()
end)

Library.registerKeyListProvider("Music", function()
    local rows = {}
    if currentSound and currentSound.IsPlaying then
        table.insert(rows, {"MUSIC", "PLAYING"})
    end
    return rows
end)

return {
    Gather = function() return { Playing = currentSound and currentSound.IsPlaying } end,
    Apply = function(data) end
}