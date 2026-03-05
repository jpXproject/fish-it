-- XcodeHub Premium Suite | Fish It!
-- Executor: Velocity | v3.1
-- Fix: Singleton guard (no double UI), Rayfield fallback URL, crash protection

-- ==============================
-- SINGLETON GUARD
-- Cegah script jalan 2x / UI dobel
-- ==============================
if getgenv()._XcodeHubRunning then
    -- Script sudah berjalan, hentikan instance lama dulu
    getgenv()._XcodeHubRunning = false
    task.wait(0.5)
end
getgenv()._XcodeHubRunning = true

-- ==============================
-- SERVICES
-- ==============================
local Players           = game:GetService("Players")
local LocalPlayer       = Players.LocalPlayer
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ==============================
-- LOAD RAYFIELD (dengan fallback & error handling)
-- ==============================
local Rayfield
local rayfieldLoaded = false

-- Coba URL utama dulu, fallback ke mirror jika gagal
local rayfieldURLs = {
    'https://sirius.menu/rayfield',
    'https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua',
}

for _, url in ipairs(rayfieldURLs) do
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(url, true))()
    end)
    if ok and result then
        Rayfield = result
        rayfieldLoaded = true
        break
    else
        warn("[XcodeHub] Rayfield gagal dari: " .. url .. " | " .. tostring(result))
    end
end

if not rayfieldLoaded or not Rayfield then
    warn("[XcodeHub] FATAL: Semua URL Rayfield gagal. Pastikan HTTP enabled & koneksi aktif.")
    getgenv()._XcodeHubRunning = false
    return -- Hentikan script agar tidak crash lebih lanjut
end

-- ==============================
-- CREATE WINDOW
-- ==============================
local Window = Rayfield:CreateWindow({
    Name = "XcodeHub | Fish It",
    LoadingTitle = "XcodeHub Loading...",
    LoadingSubtitle = "v3.1 • Velocity",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "XcodeHubConfig",
        FileName = "FishIt"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvite",
        RememberJoins = true
    },
    KeySystem = false,
})

-- ==============================
-- GLOBAL STATE
-- ==============================
local fishingActive      = false
local notificationActive = true
local infJumpConn        = nil
local noclipConn         = nil
local currentWalkSpeed   = 16
local currentJumpPower   = 50
getgenv().FishingDelay           = 1.5
getgenv().InstantCatchActive     = false
getgenv().SelectedTeleportPlayer = nil

-- ==============================
-- HELPERS
-- ==============================
local function Notify(title, msg, duration)
    if not notificationActive then return end
    pcall(function()
        Rayfield:Notify({
            Title = title,
            Content = msg,
            Duration = duration or 3,
            Image = 7733960981,
        })
    end)
end

local function GetHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function ApplyCharacterStats()
    local hum = GetHumanoid()
    if hum then
        hum.WalkSpeed = currentWalkSpeed
        hum.JumpPower = currentJumpPower
    end
end

-- Re-apply stats saat respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1.5)
    ApplyCharacterStats()
end)

local function FindFishingRemotes()
    local remotes = {}
    local keywords = {"fish", "catch", "rod", "reel", "cast", "bite", "hook"}
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local low = obj.Name:lower()
            for _, kw in ipairs(keywords) do
                if low:find(kw) then
                    table.insert(remotes, obj)
                    break
                end
            end
        end
    end
    return remotes
end

-- ==============================
-- AUTO FISHING
-- ==============================
local function StartAutoFishing()
    fishingActive = true
    task.spawn(function()
        while fishingActive and getgenv()._XcodeHubRunning do
            pcall(function()
                local char = LocalPlayer.Character
                if not char then task.wait(1) return end

                local rod = nil
                for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
                    if tool:IsA("Tool") and (tool.Name:lower():find("rod") or tool.Name:lower():find("fish")) then
                        rod = tool; break
                    end
                end
                if not rod then
                    for _, tool in ipairs(char:GetChildren()) do
                        if tool:IsA("Tool") and (tool.Name:lower():find("rod") or tool.Name:lower():find("fish")) then
                            rod = tool; break
                        end
                    end
                end

                if rod then
                    if rod.Parent ~= char then
                        local hum = GetHumanoid()
                        if hum then hum:EquipTool(rod) end
                        task.wait(0.5)
                    end
                    -- Charge cast
                    mouse1press()
                    task.wait(getgenv().FishingDelay or 1.5)
                    mouse1release()
                    task.wait(0.4)
                    -- Reel spam
                    for _ = 1, 40 do
                        if not fishingActive then break end
                        mouse1click()
                        task.wait(0.06)
                    end
                    task.wait(0.8)
                else
                    task.wait(1.5)
                end
            end)
        end
    end)
end

-- ==============================
-- INSTANT CATCH
-- ==============================
local function StartInstantCatch()
    task.spawn(function()
        while getgenv().InstantCatchActive and getgenv()._XcodeHubRunning do
            pcall(function()
                mouse1click()
                for _, remote in ipairs(FindFishingRemotes()) do
                    pcall(function()
                        local low = remote.Name:lower()
                        if low:find("catch") or low:find("reel") or low:find("bite") or low:find("hook") then
                            if remote:IsA("RemoteEvent") then remote:FireServer() end
                        end
                    end)
                end
            end)
            task.wait(0.07)
        end
    end)
end

-- ==============================
-- TELEPORT
-- ==============================
local function RefreshPlayerList()
    local list = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(list, player.Name)
        end
    end
    return list
end

local function TeleportToPlayer(targetName)
    local hrp = GetHRP()
    if not hrp then Notify("Error", "Karakter kamu tidak ditemukan!", 3); return false end

    local target = Players:FindFirstChild(targetName)
    if not target then Notify("Error", "'" .. targetName .. "' tidak ada di server!", 3); return false end

    local targetChar = target.Character
    if not targetChar then Notify("Error", targetName .. " belum spawn!", 3); return false end

    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetHRP then Notify("Error", targetName .. " HRP tidak ada!", 3); return false end

    hrp.CFrame = targetHRP.CFrame + Vector3.new(0, 3, 2)
    Notify("✈️ Teleport", "Berhasil → " .. targetName, 3)
    return true
end

-- ==============================================================
-- TAB: MAIN
-- ==============================================================
local MainTab = Window:CreateTab("Main", 4483362458)
MainTab:CreateSection("🛡️ Protection")

local antiStaffActive = false
MainTab:CreateToggle({
    Name = "Anti-Staff Protection",
    CurrentValue = false,
    Callback = function(Value)
        antiStaffActive = Value
        if Value then
            task.spawn(function()
                while antiStaffActive and getgenv()._XcodeHubRunning do
                    task.wait(math.random(50, 90))
                    pcall(function()
                        local hrp = GetHRP()
                        if hrp then
                            hrp.CFrame = hrp.CFrame * CFrame.new(math.random(-1,1), 0, math.random(-1,1))
                        end
                    end)
                end
            end)
            Notify("Anti-Staff", "Aktif", 2)
        else
            Notify("Anti-Staff", "Nonaktif", 2)
        end
    end,
})

local antiAFKActive = false
MainTab:CreateToggle({
    Name = "Anti-AFK System",
    CurrentValue = false,
    Callback = function(Value)
        antiAFKActive = Value
        if Value then
            task.spawn(function()
                while antiAFKActive and getgenv()._XcodeHubRunning do
                    task.wait(55)
                    pcall(function()
                        local hum = GetHumanoid()
                        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                    end)
                end
            end)
            Notify("Anti-AFK", "Aktif - jump tiap 55 detik", 2)
        else
            Notify("Anti-AFK", "Nonaktif", 2)
        end
    end,
})

-- ==============================================================
-- TAB: FISHING
-- ==============================================================
local FishingTab = Window:CreateTab("Fishing", 7733960981)
FishingTab:CreateSection("🎣 Auto Fishing")

local autoFishToggleRef
autoFishToggleRef = FishingTab:CreateToggle({
    Name = "Enable Auto Fishing",
    CurrentValue = false,
    Callback = function(Value)
        fishingActive = Value
        if Value then
            StartAutoFishing()
            Notify("🎣 Fishing", "Auto Fishing ON! Pastikan ada rod.", 3)
        else
            Notify("🎣 Fishing", "Auto Fishing OFF.", 2)
        end
    end,
})

FishingTab:CreateToggle({
    Name = "Instant Catch",
    CurrentValue = false,
    Callback = function(Value)
        getgenv().InstantCatchActive = Value
        if Value then
            StartInstantCatch()
            Notify("Instant Catch", "Aktif!", 2)
        else
            Notify("Instant Catch", "Nonaktif.", 2)
        end
    end,
})

FishingTab:CreateSlider({
    Name = "Cast Hold Duration",
    Range = {0.5, 3.5},
    Increment = 0.1,
    Suffix = "detik",
    CurrentValue = 1.5,
    Callback = function(Value)
        getgenv().FishingDelay = Value
    end,
})

FishingTab:CreateSection("🔧 Debug")
FishingTab:CreateButton({
    Name = "Scan Fishing Remotes (Print)",
    Callback = function()
        local remotes = FindFishingRemotes()
        Notify("Debug", "Ditemukan " .. #remotes .. " remote. Cek console.", 3)
        print("=== [XcodeHub] Fishing Remotes ===")
        for _, r in ipairs(remotes) do
            print("  >> " .. r:GetFullName() .. " (" .. r.ClassName .. ")")
        end
    end,
})

-- ==============================================================
-- TAB: TELEPORT
-- ==============================================================
local TeleportTab = Window:CreateTab("Teleport", 4483362458)
TeleportTab:CreateSection("🎯 Teleport ke Player")

local playerDropdown = TeleportTab:CreateDropdown({
    Name = "Pilih Target Player",
    Options = {"(Tekan Refresh dulu)"},
    CurrentOption = {"(Tekan Refresh dulu)"},
    MultipleOptions = false,
    Callback = function(Option)
        getgenv().SelectedTeleportPlayer = type(Option) == "table" and Option[1] or Option
    end,
})

TeleportTab:CreateButton({
    Name = "🔄 Refresh Player List",
    Callback = function()
        local list = RefreshPlayerList()
        if #list == 0 then
            pcall(function() playerDropdown:Refresh({"(Tidak ada player lain)"}, false) end)
            Notify("Refresh", "Tidak ada player lain di server.", 3)
            return
        end
        pcall(function()
            playerDropdown:Refresh(list, false)
            playerDropdown:Set({list[1]})
        end)
        getgenv().SelectedTeleportPlayer = list[1]
        Notify("🔄 Refresh", "Ada " .. #list .. " player. Pilih lalu teleport!", 3)
    end,
})

TeleportTab:CreateButton({
    Name = "✈️ Teleport ke Player Dipilih",
    Callback = function()
        local target = getgenv().SelectedTeleportPlayer
        if not target
            or target == "(Tekan Refresh dulu)"
            or target == "(Tidak ada player lain)" then
            Notify("Teleport", "Klik Refresh dulu, lalu pilih player!", 3)
            return
        end
        TeleportToPlayer(target)
    end,
})

TeleportTab:CreateSection("⚡ Teleport Cepat")

TeleportTab:CreateButton({
    Name = "Teleport ke Player Terdekat",
    Callback = function()
        local hrp = GetHRP()
        if not hrp then Notify("Error", "Karakter tidak ditemukan!", 3) return end
        local nearest, nearestDist = nil, math.huge
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local oHRP = player.Character:FindFirstChild("HumanoidRootPart")
                if oHRP then
                    local dist = (hrp.Position - oHRP.Position).Magnitude
                    if dist < nearestDist then nearestDist = dist; nearest = player end
                end
            end
        end
        if nearest then TeleportToPlayer(nearest.Name)
        else Notify("Teleport", "Tidak ada player lain di server!", 3) end
    end,
})

TeleportTab:CreateButton({
    Name = "Teleport ke Semua Player (Loop)",
    Callback = function()
        task.spawn(function()
            local list = RefreshPlayerList()
            if #list == 0 then Notify("Teleport", "Tidak ada player lain!", 3); return end
            Notify("Loop TP", "Mulai ke " .. #list .. " player...", 3)
            for _, name in ipairs(list) do
                TeleportToPlayer(name)
                task.wait(2.5)
            end
            Notify("Loop TP", "Selesai!", 3)
        end)
    end,
})

-- ==============================================================
-- TAB: UTILITY
-- ==============================================================
local UtilityTab = Window:CreateTab("Utility", 6022668958)
UtilityTab:CreateSection("👤 Player Stats")

UtilityTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 300},
    Increment = 1,
    Suffix = "studs/s",
    CurrentValue = 16,
    Callback = function(Value)
        currentWalkSpeed = Value
        pcall(function() GetHumanoid().WalkSpeed = Value end)
    end,
})

UtilityTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 500},
    Increment = 10,
    Suffix = "power",
    CurrentValue = 50,
    Callback = function(Value)
        currentJumpPower = Value
        pcall(function() GetHumanoid().JumpPower = Value end)
    end,
})

UtilityTab:CreateButton({
    Name = "Reset Speed & Jump ke Default",
    Callback = function()
        currentWalkSpeed = 16; currentJumpPower = 50
        pcall(function()
            local hum = GetHumanoid()
            hum.WalkSpeed = 16; hum.JumpPower = 50
        end)
        Notify("Reset", "Speed & Jump direset ke default.", 2)
    end,
})

UtilityTab:CreateSection("⚙️ Movement")

UtilityTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(Value)
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        if Value then
            noclipConn = RunService.Stepped:Connect(function()
                pcall(function()
                    local char = LocalPlayer.Character
                    if char then
                        for _, part in ipairs(char:GetDescendants()) do
                            if part:IsA("BasePart") then part.CanCollide = false end
                        end
                    end
                end)
            end)
            Notify("Noclip", "Aktif!", 2)
        else
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = true end
                    end
                end
            end)
            Notify("Noclip", "Nonaktif.", 2)
        end
    end,
})

UtilityTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(Value)
        if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
        if Value then
            infJumpConn = UserInputService.JumpRequest:Connect(function()
                pcall(function()
                    local hum = GetHumanoid()
                    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                end)
            end)
            Notify("Infinite Jump", "Aktif!", 2)
        else
            Notify("Infinite Jump", "Nonaktif.", 2)
        end
    end,
})

-- ==============================================================
-- TAB: SETTINGS
-- ==============================================================
local SettingsTab = Window:CreateTab("Settings", 9753762469)
SettingsTab:CreateSection("🔔 Notifikasi")

SettingsTab:CreateToggle({
    Name = "Enable Notifications",
    CurrentValue = true,
    Callback = function(Value)
        notificationActive = Value
        if Value then Notify("Settings", "Notifikasi: ON", 2) end
    end,
})

SettingsTab:CreateSection("🎨 UI")
SettingsTab:CreateColorPicker({
    Name = "UI Accent Color",
    Color = Color3.fromRGB(0, 120, 215),
    Callback = function(Color)
        pcall(function() Window:ChangeColor(Color) end)
    end
})

SettingsTab:CreateSection("⌨️ Keybinds")
SettingsTab:CreateKeybind({
    Name = "Toggle UI",
    CurrentKeybind = "RightControl",
    HoldToInteract = false,
    Callback = function() Rayfield:Toggle() end,
})
SettingsTab:CreateKeybind({
    Name = "Toggle Auto Fish (F)",
    CurrentKeybind = "F",
    HoldToInteract = false,
    Callback = function()
        fishingActive = not fishingActive
        pcall(function() autoFishToggleRef:Set(fishingActive) end)
        if fishingActive then StartAutoFishing() end
        Notify("Fishing", "Auto Fish: " .. (fishingActive and "ON" or "OFF"), 2)
    end,
})

SettingsTab:CreateSection("ℹ️ Info")
SettingsTab:CreateLabel("XcodeHub v3.1 | Fish It!")
SettingsTab:CreateLabel("Player: " .. LocalPlayer.Name)
SettingsTab:CreateLabel("Executor: Velocity")
SettingsTab:CreateLabel("Fix: No double UI, crash protection, Rayfield fallback")

-- ==============================================================
-- INIT
-- ==============================================================
task.wait(1)
Notify("XcodeHub v3.1", "Loaded! Tab Teleport → Refresh dulu sebelum TP.", 5)

task.spawn(function()
    task.wait(3)
    local remotes = FindFishingRemotes()
    print("[XcodeHub v3.1] Remotes: " .. #remotes)
    for _, r in ipairs(remotes) do
        print("  >> " .. r:GetFullName() .. " (" .. r.ClassName .. ")")
    end
end)
