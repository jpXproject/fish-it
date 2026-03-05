-- XcodeHub Premium Exploit Suite
-- FIXED VERSION - Semua error diperbaiki

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Load Rayfield UI Library dengan error handling
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield', true))()

-- Create Main Window
local Window = Rayfield:CreateWindow({
    Name = "XcodeHub | Fish It",
    LoadingTitle = "XcodeHub Loading...",
    LoadingSubtitle = "Premium Fishing Suite",
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

-- VARIABLES
local fishingActive = false
local notificationActive = true
local lastCatch = ""
local fishingRemotes = {} -- Cache untuk remote

-- FUNGSI PERBAIKAN 1: Mencari remote dengan aman
local function FindFishingRemotes()
    local remotes = {}
    local searchLocations = {ReplicatedStorage, workspace}
    
    for _, location in pairs(searchLocations) do
        pcall(function()
            for _, obj in pairs(location:GetDescendants()) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    local nameLower = obj.Name:lower()
                    if nameLower:find("fish") or nameLower:find("catch") or 
                       nameLower:find("rod") or nameLower:find("reel") or
                       nameLower:find("product") or nameLower:find("price") then
                        table.insert(remotes, obj)
                    end
                end
            end
        end)
    end
    
    return remotes
end

-- FUNGSI PERBAIKAN 2: Memanggil remote dengan aman
local function SafeFireRemote(remote, ...)
    if not remote then return false end
    local success, result = pcall(function()
        if remote:IsA("RemoteEvent") then
            remote:FireServer(...)
        elseif remote:IsA("RemoteFunction") then
            return remote:InvokeServer(...)
        end
    end)
    return success, result
end

-- FUNGSI PERBAIKAN 3: Mendapatkan posisi ikan terdekat
local function GetNearestFishPosition()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    local playerPos = character.HumanoidRootPart.Position
    local nearestPos = nil
    local nearestDist = math.huge
    
    -- Cari di Fishing Circles (berdasarkan error)
    local fishingCircles = workspace:FindFirstChild("Fishing Circles")
    if fishingCircles then
        for _, circle in pairs(fishingCircles:GetChildren()) do
            if circle:IsA("Part") or circle:IsA("Model") then
                local pos = circle:IsA("Model") and circle:FindFirstChild("Position") or circle
                if pos and pos:IsA("BasePart") then
                    local dist = (playerPos - pos.Position).Magnitude
                    if dist < nearestDist then
                        nearestDist = dist
                        nearestPos = pos.CFrame * CFrame.new(0, 5, 0)
                    end
                end
            end
        end
    end
    
    return nearestPos
end

-- FUNGSI PERBAIKAN 4: Auto fishing yang lebih stabil
local function StartAutoFishing()
    task.spawn(function()
        while fishingActive do
            -- Cari fishing rod
            local rod = nil
            for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
                if tool:IsA("Tool") and (tool.Name:lower():find("rod") or tool.Name:lower():find("fishing")) then
                    rod = tool
                    break
                end
            end
            
            if rod and LocalPlayer.Character then
                -- Equip rod
                pcall(function()
                    LocalPlayer.Character.Humanoid:EquipTool(rod)
                end)
                task.wait(0.5)
                
                -- Cast fishing rod
                mouse1click()
                task.wait(1)
                
                -- Fire remotes dengan aman
                if #fishingRemotes == 0 then
                    fishingRemotes = FindFishingRemotes()
                end
                
                for _, remote in pairs(fishingRemotes) do
                    SafeFireRemote(remote)
                end
            end
            
            task.wait(getgenv().FishingDelay or 2)
        end
    end)
end

-- FUNGSI NOTIFIKASI
local function SendNotification(title, message)
    if notificationActive then
        local success = pcall(function()
            Rayfield:Notify({
                Title = title,
                Content = message,
                Duration = 3,
                Image = 7733960981,
            })
        end)
    end
end

-- MAIN TAB
local MainTab = Window:CreateTab("Main", 4483362458)

-- Anti-Staff Section
MainTab:CreateSection("🛡️ Protection")
local antiStaffActive = false
MainTab:CreateToggle({
    Name = "Anti-Staff Protection",
    CurrentValue = false,
    Callback = function(Value)
        antiStaffActive = Value
        if Value then
            task.spawn(function()
                while antiStaffActive do
                    task.wait(math.random(45, 90))
                    pcall(function()
                        local original = LocalPlayer.DisplayName
                        LocalPlayer.DisplayName = "Player"..tostring(math.random(1000,9999))
                        task.wait(5)
                        LocalPlayer.DisplayName = original
                    end)
                end
            end)
        end
    end,
})

-- Anti-AFK
local antiAFKActive = false
MainTab:CreateToggle({
    Name = "Anti-AFK System",
    CurrentValue = false,
    Callback = function(Value)
        antiAFKActive = Value
        if Value then
            task.spawn(function()
                while antiAFKActive do
                    task.wait(60)
                    pcall(function()
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, nil)
                        task.wait(0.1)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, nil)
                    end)
                end
            end)
        end
    end,
})

-- FISHING TAB
local FishingTab = Window:CreateTab("Fishing", 7733960981)

-- Auto Fishing Section
FishingTab:CreateSection("🎣 Auto Fishing")
local autoFishToggle = FishingTab:CreateToggle({
    Name = "Enable Auto Fishing",
    CurrentValue = false,
    Callback = function(Value)
        fishingActive = Value
        if Value then
            SendNotification("XcodeHub", "Auto Fishing Started!")
            -- Refresh remote cache
            fishingRemotes = FindFishingRemotes()
            print("[XcodeHub] Found " .. #fishingRemotes .. " remotes")
            StartAutoFishing()
        else
            SendNotification("XcodeHub", "Auto Fishing Stopped!")
        end
    end,
})

-- Instant Catch
local instantCatchActive = false
FishingTab:CreateToggle({
    Name = "Instant Catch",
    CurrentValue = false,
    Callback = function(Value)
        instantCatchActive = Value
        if Value then
            task.spawn(function()
                while instantCatchActive do
                    task.wait(0.2)
                    pcall(function()
                        local catchRemotes = {}
                        if #fishingRemotes == 0 then
                            fishingRemotes = FindFishingRemotes()
                        end
                        for _, remote in pairs(fishingRemotes) do
                            if remote.Name:lower():find("catch") then
                                SafeFireRemote(remote, true)
                            end
                        end
                    end)
                end
            end)
        end
    end,
})

-- Catch Speed
getgenv().FishingDelay = 1
FishingTab:CreateSlider({
    Name = "Fishing Speed",
    Range = {0.1, 3},
    Increment = 0.1,
    Suffix = "seconds",
    CurrentValue = 1,
    Callback = function(Value)
        getgenv().FishingDelay = Value
    end,
})

-- UTILITY TAB
local UtilityTab = Window:CreateTab("Utility", 6022668958)

UtilityTab:CreateSection("👤 Player Utilities")

-- WalkSpeed
local walkSpeedValue = 16
UtilityTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 200},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 16,
    Callback = function(Value)
        walkSpeedValue = Value
        pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.WalkSpeed = Value
            end
        end)
    end,
})

-- Jump Power
local jumpPowerValue = 50
UtilityTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 500},
    Increment = 10,
    Suffix = "power",
    CurrentValue = 50,
    Callback = function(Value)
        jumpPowerValue = Value
        pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.JumpPower = Value
            end
        end)
    end,
})

-- Noclip
local noclipActive = false
UtilityTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(Value)
        noclipActive = Value
        if Value then
            task.spawn(function()
                while noclipActive do
                    task.wait()
                    pcall(function()
                        if LocalPlayer.Character then
                            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    part.CanCollide = false
                                end
                            end
                        end
                    end)
                end
            end)
        end
    end,
})

-- Infinite Jump
local infJumpConnection = nil
UtilityTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(Value)
        if infJumpConnection then
            infJumpConnection:Disconnect()
            infJumpConnection = nil
        end
        
        if Value then
            infJumpConnection = UserInputService.JumpRequest:Connect(function()
                pcall(function()
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end)
            end)
        end
    end,
})

-- Teleport to Nearest Fish (FIXED)
UtilityTab:CreateButton({
    Name = "Teleport to Nearest Fish",
    Callback = function()
        local targetCFrame = GetNearestFishPosition()
        
        if targetCFrame and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = targetCFrame
            SendNotification("Teleport", "Teleported to fishing spot!")
        else
            SendNotification("Error", "No fishing spots found!")
        end
    end,
})

-- SETTINGS TAB
local SettingsTab = Window:CreateTab("Settings", 9753762469)

-- Notifications Section
SettingsTab:CreateSection("🔔 Notifications")
local notifToggle = SettingsTab:CreateToggle({
    Name = "Enable Notifications",
    CurrentValue = true,
    Callback = function(Value)
        notificationActive = Value
        if Value then
            SendNotification("Settings", "Notifications: ON")
        end
    end,
})

-- UI Customization (FIXED - menggunakan method yang benar)
SettingsTab:CreateSection("🎨 UI Customization")
SettingsTab:CreateButton({
    Name = "Change Theme Color",
    Callback = function()
        -- Rayfield mungkin tidak punya ChangeColor, gunakan alternatif
        SendNotification("Info", "Theme color change disabled")
    end,
})

-- Keybinds
SettingsTab:CreateSection("⌨️ Keybinds")
SettingsTab:CreateKeybind({
    Name = "Toggle UI",
    CurrentKeybind = "RightControl",
    HoldToInteract = false,
    Callback = function()
        Rayfield:Toggle()
    end,
})

SettingsTab:CreateKeybind({
    Name = "Toggle Auto Fish",
    CurrentKeybind = "F",
    HoldToInteract = false,
    Callback = function()
        autoFishToggle:Set(not autoFishToggle.CurrentValue)
    end,
})

-- Info Section
SettingsTab:CreateSection("ℹ️ Information")
SettingsTab:CreateLabel("XcodeHub v2.2 - FIXED")
SettingsTab:CreateLabel("Player: " .. LocalPlayer.Name)
SettingsTab:CreateLabel("Game: Fish It")

-- Character added connection
LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(1)
    pcall(function()
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.WalkSpeed = walkSpeedValue
            character.Humanoid.JumpPower = jumpPowerValue
        end
    end)
end)

-- Initial notification
task.wait(1)
SendNotification("XcodeHub Loaded!", "Premium Fishing Suite Ready (Fixed Version)")
