-- XcodeHub Premium Exploit Suite
-- Fixed Fishing Features + Enhanced UI

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

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

-- FIXED FISHING FUNCTION
local function FindFishingRemotes()
    local remotes = {}
    
    -- Check ReplicatedStorage
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            if string.find(obj.Name:lower(), "fish") or 
               string.find(obj.Name:lower(), "catch") or
               string.find(obj.Name:lower(), "rod") or
               string.find(obj.Name:lower(), "reel") then
                table.insert(remotes, obj)
            end
        end
    end
    
    -- Check workspace
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            if string.find(obj.Name:lower(), "fish") then
                table.insert(remotes, obj)
            end
        end
    end
    
    return remotes
end

-- FIXED AUTO FISHING
local function StartAutoFishing()
    fishingActive = true
    
    spawn(function()
        while fishingActive do
            -- Wait for rod
            local rod = nil
            repeat
                for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
                    if string.find(tool.Name:lower(), "rod") or 
                       string.find(tool.Name:lower(), "fishing") then
                        rod = tool
                        break
                    end
                end
                wait(0.5)
            until rod or not fishingActive
            
            if rod and fishingActive then
                -- Equip rod
                LocalPlayer.Character.Humanoid:EquipTool(rod)
                wait(0.5)
                
                -- Cast fishing
                mouse1click()
                wait(1)
                
                -- Try to catch
                local remotes = FindFishingRemotes()
                for _, remote in pairs(remotes) do
                    pcall(function()
                        if remote:IsA("RemoteEvent") then
                            remote:FireServer()
                        elseif remote:IsA("RemoteFunction") then
                            remote:InvokeServer()
                        end
                    end)
                end
                
                -- Wait before next cast
                wait(2)
            end
        end
    end)
end

-- NOTIFICATION SYSTEM
local function SendNotification(title, message)
    if notificationActive then
        Rayfield:Notify({
            Title = title,
            Content = message,
            Duration = 3,
            Image = 7733960981,
        })
    end
end

-- MAIN TAB
local MainTab = Window:CreateTab("Main", 4483362458)

-- Anti-Staff Section
MainTab:CreateSection("🛡️ Protection")
local antiStaffToggle = MainTab:CreateToggle({
    Name = "Anti-Staff Protection",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            spawn(function()
                while antiStaffToggle.CurrentValue do
                    wait(math.random(45, 90))
                    pcall(function()
                        -- Change display name temporarily
                        local original = LocalPlayer.DisplayName
                        LocalPlayer.DisplayName = "Player"..tostring(math.random(1000,9999))
                        wait(5)
                        LocalPlayer.DisplayName = original
                    end)
                end
            end)
        end
    end,
})

-- Anti-AFK
local antiAFKToggle = MainTab:CreateToggle({
    Name = "Anti-AFK System",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            spawn(function()
                while antiAFKToggle.CurrentValue do
                    wait(60)
                    pcall(function()
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, nil)
                        wait(0.1)
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
            StartAutoFishing()
        else
            SendNotification("XcodeHub", "Auto Fishing Stopped!")
        end
    end,
})

-- Instant Catch
local instantCatchToggle = FishingTab:CreateToggle({
    Name = "Instant Catch",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            spawn(function()
                while instantCatchToggle.CurrentValue do
                    wait(0.2)
                    pcall(function()
                        local remotes = FindFishingRemotes()
                        for _, remote in pairs(remotes) do
                            pcall(function()
                                if remote.Name:find("Catch") then
                                    remote:FireServer(true)
                                end
                            end)
                        end
                    end)
                end
            end)
        end
    end,
})

-- Catch Speed
local catchSpeedSlider = FishingTab:CreateSlider({
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

-- Player Utilities Section
UtilityTab:CreateSection("👤 Player Utilities")

-- WalkSpeed
local walkSpeedSlider = UtilityTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 200},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 16,
    Callback = function(Value)
        pcall(function()
            LocalPlayer.Character.Humanoid.WalkSpeed = Value
        end)
    end,
})

-- Jump Power
local jumpPowerSlider = UtilityTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 500},
    Increment = 10,
    Suffix = "power",
    CurrentValue = 50,
    Callback = function(Value)
        pcall(function()
            LocalPlayer.Character.Humanoid.JumpPower = Value
        end)
    end,
})

-- Noclip
local noclipToggle = UtilityTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            spawn(function()
                while noclipToggle.CurrentValue do
                    wait()
                    pcall(function()
                        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end)
                end
            end)
        end
    end,
})

-- Infinite Jump
local infJumpToggle = UtilityTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            UserInputService.JumpRequest:Connect(function()
                pcall(function()
                    LocalPlayer.Character.Humanoid:ChangeState("Jumping")
                end)
            end)
        end
    end,
})

-- Teleport to Fish
UtilityTab:CreateButton({
    Name = "Teleport to Nearest Fish",
    Callback = function()
        local nearestFish = nil
        local nearestDist = math.huge
        
        for _, obj in pairs(workspace:GetChildren()) do
            if obj.Name:find("Fish") or obj.Name:find("fish") then
                local dist = (LocalPlayer.Character.HumanoidRootPart.Position - obj.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearestFish = obj
                end
            end
        end
        
        if nearestFish then
            LocalPlayer.Character.HumanoidRootPart.CFrame = nearestFish.CFrame + Vector3.new(0, 5, 0)
            SendNotification("Teleport", "Teleported to fish!")
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
        SendNotification("Settings", "Notifications: " .. (Value and "ON" or "OFF"))
    end,
})

-- UI Customization
SettingsTab:CreateSection("🎨 UI Customization")
local uiColor = SettingsTab:CreateColorPicker({
    Name = "UI Color",
    Color = Color3.fromRGB(0, 120, 215),
    Callback = function(Color)
        Window:ChangeColor(Color)
    end
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
SettingsTab:CreateLabel("XcodeHub v2.1")
SettingsTab:CreateLabel("Player: " .. LocalPlayer.Name)
SettingsTab:CreateLabel("Executor: Velocity")
SettingsTab:CreateLabel("Game: Fish It")

-- Auto-connect character for utilities
LocalPlayer.CharacterAdded:Connect(function()
    wait(1)
    if walkSpeedSlider.CurrentValue > 16 then
        pcall(function()
            LocalPlayer.Character.Humanoid.WalkSpeed = walkSpeedSlider.CurrentValue
        end)
    end
    if jumpPowerSlider.CurrentValue > 50 then
        pcall(function()
            LocalPlayer.Character.Humanoid.JumpPower = jumpPowerSlider.CurrentValue
        end)
    end
end)

-- INITIAL NOTIFICATION
wait(1)
Rayfield:Notify({
    Title = "XcodeHub Loaded!",
    Content = "Premium Fishing Suite Ready",
    Duration = 5,
    Image = 7733960981,
})

-- DEBUG: Print found remotes (for testing)
spawn(function()
    wait(3)
    local remotes = FindFishingRemotes()
    print("[XcodeHub] Found " .. #remotes .. " fishing remotes")
    for _, remote in pairs(remotes) do
        print("  - " .. remote.Name .. " (" .. remote.ClassName .. ")")
    end
end)
