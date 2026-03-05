-- Fish It Premium Exploit Suite
-- Advanced UI dengan Drag, Minimize, Toggle

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "🐟 FISH IT PREMIUM EXPLOIT",
    LoadingTitle = "Loading Premium Suite...",
    LoadingSubtitle = "by Exploit Assistant",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "FishItExploit",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvite",
        RememberJoins = true
    },
    KeySystem = false,
    KeySettings = {
        Title = "Fish It",
        Subtitle = "Key System",
        Note = "No key required",
        FileName = "FishItKey",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"EXPLOIT2024"}
    }
})

-- MAIN TAB
local MainTab = Window:CreateTab("Main Features", 4483362458)

-- Anti-Staff Section
local AntiStaffSection = MainTab:CreateSection("🛡️ Anti-Staff Protection")
local antiStaffToggle = MainTab:CreateToggle({
    Name = "Enable Anti-Staff",
    CurrentValue = false,
    Flag = "AntiStaffToggle",
    Callback = function(Value)
        if Value then
            spawn(function()
                while antiStaffToggle.CurrentValue do
                    wait(math.random(30, 60))
                    pcall(function()
                        local char = LocalPlayer.Character
                        if char then
                            -- Randomize appearance
                            local shirt = char:FindFirstChild("Shirt")
                            if shirt then
                                shirt.ShirtTemplate = "rbxassetid://"..tostring(math.random(1000000, 9999999))
                            end
                            
                            -- Fake ping
                            game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:SetValue(math.random(50, 150))
                        end
                    end)
                end
            end)
        end
    end,
})

-- Anti-AFK Section
local AntiAFKSection = MainTab:CreateSection("⏰ Anti-AFK System")
local antiAFKToggle = MainTab:CreateToggle({
    Name = "Enable Anti-AFK",
    CurrentValue = false,
    Flag = "AntiAFKToggle",
    Callback = function(Value)
        if Value then
            spawn(function()
                while antiAFKToggle.CurrentValue do
                    wait(120)
                    pcall(function()
                        local VirtualInput = game:GetService("VirtualInputManager")
                        VirtualInput:SendKeyEvent(true, Enum.KeyCode.W, false, nil)
                        wait(0.1)
                        VirtualInput:SendKeyEvent(false, Enum.KeyCode.W, false, nil)
                    end)
                end
            end)
        end
    end,
})

-- Fishing Tab
local FishingTab = Window:CreateTab("Fishing", 7733960981)

-- Auto Fishing Section
local AutoFishSection = FishingTab:CreateSection("🎣 Auto Fishing")
local autoFishToggle = FishingTab:CreateToggle({
    Name = "Enable Auto Fishing",
    CurrentValue = false,
    Flag = "AutoFishToggle",
    Callback = function(Value)
        if Value then
            spawn(function()
                while autoFishToggle.CurrentValue do
                    wait(0.5)
                    pcall(function()
                        for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
                            if string.find(tool.Name:lower(), "rod") then
                                tool:Activate()
                                wait(0.3)
                                
                                -- Auto catch
                                local remotes = {"FishCatch", "CatchFish", "FishingComplete"}
                                for _, remote in pairs(remotes) do
                                    local event = game:GetService("ReplicatedStorage"):FindFirstChild(remote)
                                    if event then
                                        event:FireServer(true, Vector3.new(0,0,0), math.huge)
                                    end
                                end
                            end
                        end
                    end)
                end
            end)
        end
    end,
})

-- Instant Catch Slider
local instantCatchSlider = FishingTab:CreateSlider({
    Name = "Catch Speed",
    Range = {0.1, 5},
    Increment = 0.1,
    Suffix = "seconds",
    CurrentValue = 0.5,
    Flag = "CatchSpeed",
    Callback = function(Value)
        getgenv().CatchSpeed = Value
    end,
})

-- Advanced Tab
local AdvancedTab = Window:CreateTab("Advanced", 9753762469)

-- ESP Section
local ESPSection = AdvancedTab:CreateSection("👁️ Fish ESP")
local fishESPToggle = AdvancedTab:CreateToggle({
    Name = "Show Fish ESP",
    CurrentValue = false,
    Flag = "FishESPToggle",
    Callback = function(Value)
        if Value then
            spawn(function()
                while fishESPToggle.CurrentValue do
                    wait(1)
                    pcall(function()
                        for _, fish in pairs(workspace:GetChildren()) do
                            if fish.Name:find("Fish") or fish.Name:find("fish") then
                                if not fish:FindFirstChild("ESPBox") then
                                    local box = Instance.new("BoxHandleAdornment")
                                    box.Name = "ESPBox"
                                    box.Adornee = fish
                                    box.AlwaysOnTop = true
                                    box.ZIndex = 10
                                    box.Size = fish.Size
                                    box.Transparency = 0.3
                                    box.Color3 = Color3.fromRGB(0, 255, 0)
                                    box.Parent = fish
                                end
                            end
                        end
                    end)
                end
            end)
        else
            pcall(function()
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj.Name == "ESPBox" then
                        obj:Destroy()
                    end
                end
            end)
        end
    end,
})

-- Auto-Sell Section
local AutoSellSection = AdvancedTab:CreateSection("💰 Auto Sell")
local autoSellToggle = AdvancedTab:CreateToggle({
    Name = "Auto Sell Fish",
    CurrentValue = false,
    Flag = "AutoSellToggle",
    Callback = function(Value)
        if Value then
            spawn(function()
                while autoSellToggle.CurrentValue do
                    wait(5)
                    pcall(function()
                        -- Find sell stations
                        for _, part in pairs(workspace:GetDescendants()) do
                            if part.Name:find("Sell") or part.Name:find("sell") then
                                firetouchinterest(LocalPlayer.Character.HumanoidRootPart, part, 0)
                                wait(0.1)
                                firetouchinterest(LocalPlayer.Character.HumanoidRootPart, part, 1)
                            end
                        end
                    end)
                end
            end)
        end
    end,
})

-- Settings Tab
local SettingsTab = Window:CreateTab("Settings", 6022668958)

-- UI Customization
local UICustomSection = SettingsTab:CreateSection("🎨 UI Customization")
local uiColorPicker = SettingsTab:CreateColorPicker({
    Name = "UI Color",
    Color = Color3.fromRGB(0, 170, 255),
    Flag = "UIColor",
    Callback = function(Color)
        Window:ChangeColor(Color)
    end
})

local uiTransparencySlider = SettingsTab:CreateSlider({
    Name = "UI Transparency",
    Range = {0, 1},
    Increment = 0.1,
    Suffix = "",
    CurrentValue = 0,
    Flag = "UITransparency",
    Callback = function(Value)
        for _, obj in pairs(game.CoreGui:GetDescendants()) do
            if obj:IsA("Frame") or obj:IsA("TextLabel") then
                obj.BackgroundTransparency = Value
            end
        end
    end,
})

-- Performance Section
local PerformanceSection = SettingsTab:CreateSection("⚡ Performance")
local fpsToggle = SettingsTab:CreateToggle({
    Name = "Show FPS Counter",
    CurrentValue = false,
    Flag = "FPSToggle",
    Callback = function(Value)
        if Value then
            local fpsLabel = Instance.new("TextLabel")
            fpsLabel.Name = "FPS_Counter"
            fpsLabel.Text = "FPS: 60"
            fpsLabel.Size = UDim2.new(0, 100, 0, 30)
            fpsLabel.Position = UDim2.new(1, -110, 0, 10)
            fpsLabel.BackgroundTransparency = 0.5
            fpsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            fpsLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            fpsLabel.Parent = game.CoreGui.Rayfield
        
            spawn(function()
                while fpsLabel.Parent do
                    wait(0.5)
                    fpsLabel.Text = "FPS: "..tostring(math.floor(1/RunService.RenderStepped:Wait()))
                end
            end)
        else
            local counter = game.CoreGui:FindFirstChild("FPS_Counter")
            if counter then counter:Destroy() end
        end
    end,
})

-- Keybinds Section
local KeybindSection = SettingsTab:CreateSection("⌨️ Keybinds")
local uiToggleKeybind = SettingsTab:CreateKeybind({
    Name = "Toggle UI",
    CurrentKeybind = "RightControl",
    HoldToInteract = false,
    Flag = "UIToggleKey",
    Callback = function(Key)
        Rayfield:Toggle()
    end,
})

-- Watermark
SettingsTab:CreateLabel("🐟 Fish It Premium v2.0")
SettingsTab:CreateLabel("Status: ✅ Injected")
SettingsTab:CreateLabel("Player: "..LocalPlayer.Name)

-- Notification system
local NotificationsTab = Window:CreateTab("Notifications", 6026568198)

NotificationsTab:CreateButton({
    Name = "Test Notification",
    Callback = function()
        Rayfield:Notify({
            Title = "Test Notification",
            Content = "Fish It Exploit is working!",
            Duration = 5,
            Image = 7733960981,
        })
    end,
})

-- Initialize with notification
wait(1)
Rayfield:Notify({
    Title = "Fish It Premium Loaded",
    Content = "All features are ready to use!",
    Duration = 5,
    Image = 7733960981,
})

-- Auto-start features (optional)
wait(2)
antiAFKToggle:Set(true)
antiStaffToggle:Set(true)
