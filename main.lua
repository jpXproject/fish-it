--[[
    FILE: fishing_uqill_v4.0_final.lua
    VERSION: 4.0 FINAL (Stable Release)
    CREDIT: jpXCode for optimization & stability fixes
    ORIGINAL: UQiLL Fishing Script
]]

-- =====================================================
-- 📝 CREDIT & VERSION INFO
-- =====================================================
local SCRIPT_INFO = {
    Name = "UQiLL Fishing Suite",
    Version = "4.0 FINAL",
    Author = "UQi",
    OptimizedBy = "jpXCode",
    LastUpdate = os.date("%Y-%m-%d"),
    Features = "Auto Fishing | Auto Favorite | Webhook | Teleport | Optimization"
}

print(string.format([[

    ╔══════════════════════════════════════╗
    ║       UQiLL FISHING SUITE v4.0       ║
    ║          OPTIMIZED BY jpXCode        ║
    ║    %s    ║
    ╚══════════════════════════════════════╝

]], os.date("%Y-%m-%d %H:%M:%S")))

-- =====================================================
-- 🧹 BAGIAN 1: ENHANCED CLEANUP SYSTEM
-- =====================================================
if getgenv().fishingStart then
    getgenv().fishingStart = false
    task.wait(0.5)
end

local CoreGui = game:GetService("CoreGui")
local GUI_NAMES = {
    Main = "UQiLL_Fishing_UI",
    Mobile = "UQiLL_Mobile_Button",
    Coords = "UQiLL_Coords_HUD",
    Performance = "UQiLL_PerformanceHUD"
}

-- Enhanced cleanup with better tracking
local function SafeDestroyGUI()
    for _, name in pairs(GUI_NAMES) do
        local gui = CoreGui:FindFirstChild(name)
        if gui then
            pcall(function() gui:Destroy() end)
        end
    end
    
    -- Clean up any leftover UQiLL elements
    for _, v in pairs(CoreGui:GetDescendants()) do
        if v:IsA("TextLabel") and (v.Text == "UQiLL" or string.find(v.Text, "UQiLL")) then
            local container = v
            for i = 1, 6 do
                if typeof(container) ~= "Instance" then break end
                local parent = container.Parent
                if not parent then break end
                container = parent
                if container:IsA("ScreenGui") then
                    pcall(function() container:Destroy() end)
                    break
                end
            end
        end
    end
end

SafeDestroyGUI()

-- =====================================================
-- 🎣 BAGIAN 2: ENHANCED VARIABEL & REMOTE SYSTEM
-- =====================================================
getgenv().fishingStart = false
local legit = false
local instant = false
local superInstant = true 

local args = { -1.115296483039856, 0, 1763651451.636425 }
local delayTime = 0.56   
local delayCharge = 1.15 
local delayReset = 0.2 

-- Enhanced remote fetching with fallbacks
local rs = game:GetService("ReplicatedStorage")
local net

-- Safe net package loading
pcall(function()
    net = rs.Packages["_Index"]["sleitnick_net@0.2.0"].net
end)

if not net then
    warn("[INIT] Net package not found, attempting alternative loading...")
    for _, pkg in pairs(rs.Packages:GetChildren()) do
        if string.find(pkg.Name, "net") then
            net = require(pkg).net
            break
        end
    end
end

-- Remote Definitions with validation
local function GetRemote(name)
    if not net then return nil end
    local remote = net[name]
    if not remote then
        warn("[REMOTE] " .. name .. " not found in net table")
        -- Try direct path as fallback
        local parts = string.split(name, "/")
        local container = rs
        for _, part in ipairs(parts) do
            container = container:FindFirstChild(part)
            if not container then break end
        end
        if container and container:IsA("RemoteEvent") or container:IsA("RemoteFunction") then
            return container
        end
    end
    return remote
end

local ChargeRod    = GetRemote("RF/ChargeFishingRod")
local RequestGame  = GetRemote("RF/RequestFishingMinigameStarted")
local CompleteGame = GetRemote("RE/FishingCompleted")
local CancelInput  = GetRemote("RF/CancelFishingInputs")
local SellAll      = GetRemote("RF/SellAllItems")
local EquipTank    = GetRemote("RF/EquipOxygenTank")
local UpdateRadar  = GetRemote("RF/UpdateFishingRadar")

-- Enhanced Settings State with better memory management
local SettingsState = {
    FPSBoost = { Active = false, Original = {} },
    VFXRemoved = false,
    DestroyerActive = false,
    PopupDestroyed = false,
    AutoSell = {
        TimeActive = false,
        TimeInterval = 60,
        IsSelling = false,
        Task = nil
    },
    AutoWeather = {
        Active = false,
        Targets = {},
        Connection = nil,
        SelectedList = {}
    },
    PosWatcher = { Active = false, Connection = nil },
    WaterWalk = { Active = false, Part = nil, Connection = nil },
    AnimsDisabled = { Active = false, Connections = {} },
    AutoEventDisco = { Active = false },
    AutoFavorite = {
        Active = false,
        Rarities = {},
        Cache = {},
        Connection = nil
    },
    WebhookFish = {
        Active = false,
        Url = "",
        SentUUID = {},
        SelectedRarities = {}
    },
    PerformanceHUD = { Active = false }
}

-- Service declarations
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

-- Enhanced validation
if not LocalPlayer then
    error("LocalPlayer not found! Cannot continue.")
end

-- =====================================================
-- 🔧 BAGIAN 3: ENHANCED UI LOADER WITH FALLBACK
-- =====================================================
local WindUI
local uiLoadSuccess = false

local function LoadWindUI()
    local maxAttempts = 3
    for attempt = 1, maxAttempts do
        local success, result = pcall(function()
            return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
        end)
        
        if success and result then
            WindUI = result
            uiLoadSuccess = true
            print("[UI] WindUI loaded successfully (Attempt " .. attempt .. ")")
            return true
        else
            warn("[UI] Failed to load WindUI (Attempt " .. attempt .. "): " .. tostring(result))
            task.wait(1)
        end
    end
    
    -- Fallback to simple UI if WindUI fails
    warn("[UI] Using fallback UI system")
    WindUI = {
        CreateWindow = function() return {
            Tab = function() return {
                Section = function() return {
                    Toggle = function() end,
                    Button = function() end,
                    Input = function() end,
                    Dropdown = function() end,
                    Paragraph = function() end
                } end
            } end
        } end,
        Notify = function(params)
            warn("[NOTIFY] " .. (params.Title or "") .. ": " .. (params.Content or ""))
        end
    }
    return false
end

LoadWindUI()

-- =====================================================
-- ⏰ BAGIAN 4: ENHANCED AUTO TIMED EVENT
-- =====================================================
do
    ----------------------------------------------------------------
    -- SERVICES
    ----------------------------------------------------------------
    local Players = game:GetService("Players")
    local LP = Players.LocalPlayer
    ----------------------------------------------------------------
    -- CONFIG
    ----------------------------------------------------------------
    local EVENT_HOURS = {
        [0]=true,[2]=true,[4]=true,[6]=true,
        [8]=true,[10]=true,[12]=true,
        [14]=true,[16]=true,[18]=true,
        [20]=true,[22]=true,
    }
    local EVENT_DURATION = 29 * 60 -- 30 menit
    local TARGET_POS = Vector3.new(715, -487, 8910)
    ----------------------------------------------------------------
    -- INTERNAL STATE
    ----------------------------------------------------------------
    local running = false
    local active = false
    local eventStartUTC = 0
    local savedPos = nil
    local uiConn = nil
    ----------------------------------------------------------------
    -- ENHANCED TELEPORT UTILS
    ----------------------------------------------------------------
    local function HRP()
        local c = LP.Character
        return c and c:FindFirstChild("HumanoidRootPart")
    end
    
    local function SafeTP(pos)
        for _ = 1, 5 do
            local hrp = HRP()
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.CFrame = CFrame.new(pos)
            end
            task.wait(0.08)
        end
    end
    
    ----------------------------------------------------------------
    -- TIME HELPERS (UTC SAFE)
    ----------------------------------------------------------------
    local function NowUTC()
        return os.time(os.date("!*t"))
    end

    local function FormatHMS(sec)
        sec = math.max(0, sec)
        local h = math.floor(sec / 3600)
        local m = math.floor((sec % 3600) / 60)
        local s = sec % 60
        return string.format("%02d:%02d:%02d", h, m, s)
    end

    local function FormatHM(ts, utc)
        local t = os.date(utc and "!*t" or "*t", ts)
        return string.format("%02d:%02d", t.hour, t.min)
    end

    ----------------------------------------------------------------
    -- NEXT EVENT (ABSOLUTE, TERDEKAT)
    ----------------------------------------------------------------
    local function NextEventTs()
        local now = NowUTC()
        local t = os.date("!*t", now)
        local nearest = nil

        -- hari ini (UTC)
        for h in pairs(EVENT_HOURS) do
            local ts = os.time({
                year=t.year, month=t.month, day=t.day,
                hour=h, min=0, sec=0, isdst=false
            })
            if ts > now and (not nearest or ts < nearest) then
                nearest = ts
            end
        end

        -- besok (UTC)
        if not nearest then
            for h in pairs(EVENT_HOURS) do
                local ts = os.time({
                    year=t.year, month=t.month, day=t.day + 1,
                    hour=h, min=0, sec=0, isdst=false
                })
                if not nearest or ts < nearest then
                    nearest = ts
                end
            end
        end

        return nearest
    end
    
    ----------------------------------------------------------------
    -- PUBLIC FUNCTION WITH DEBOUNCE
    ----------------------------------------------------------------
    local lastToggleTime = 0
    local toggleDebounce = 1 -- seconds
    
    function ToggleAutoTimedEvent(state, uiParagraph)
        local now = tick()
        if now - lastToggleTime < toggleDebounce then
            return
        end
        lastToggleTime = now
        
        running = state

        -- OFF
        if not state then
            active = false

            if uiConn then
                uiConn:Disconnect()
                uiConn = nil
            end

            if savedPos then
                pcall(function() SafeTP(savedPos + Vector3.new(0,2,0)) end)
            end

            savedPos = nil
            if uiParagraph then
                uiParagraph:SetDesc("Status: Off")
            end
            return
        end

        -- ON (RenderStepped updater with error handling)
        uiConn = RunService.RenderStepped:Connect(function()
            if not running or not uiParagraph then 
                if uiConn then uiConn:Disconnect() end
                return 
            end

            local success, result = pcall(function()
                local nowUTC = NowUTC()
                local nowT = os.date("!*t", nowUTC)

                -- START EVENT (UTC, menit 00)
                if EVENT_HOURS[nowT.hour] and nowT.min == 0 and not active then
                    local hrp = HRP()
                    if hrp then
                        savedPos = hrp.Position
                    end
                    active = true
                    eventStartUTC = nowUTC
                    SafeTP(TARGET_POS + Vector3.new(0,2,0))
                end

                -- STOP EVENT (30 menit)
                if active and (nowUTC - eventStartUTC >= EVENT_DURATION) then
                    active = false
                    if savedPos then
                        SafeTP(savedPos + Vector3.new(0,2,0))
                    end
                    savedPos = nil
                end

                -- UI UPDATE (OPSI C)
                if active then
                    uiParagraph:SetDesc(
                        "EVENT ACTIVE\nRemaining: " ..
                        FormatHMS(EVENT_DURATION - (nowUTC - eventStartUTC))
                    )
                else
                    local nextTs = NextEventTs()
                    if nextTs then
                        uiParagraph:SetDesc(
                            string.format(
                                "Server : %s\nLocal : %s\nCountdown : %s",
                                FormatHM(nextTs, true),       -- server (UTC)
                                FormatHM(nextTs, false),      -- local
                                FormatHMS(nextTs - nowUTC)    -- countdown
                            )
                        )
                    else
                        uiParagraph:SetDesc("Next Event: --:--")
                    end
                end
            end)
            
            if not success then
                warn("[AutoTimedEvent] Error in update loop:", result)
            end
        end)
    end
end

-- =====================================================
-- 🗺️ BAGIAN 5: ENHANCED WAYPOINTS & TELEPORT
-- =====================================================
local Waypoints = {
    ["Fisherman Island"]    = Vector3.new(-33, 10, 2770),
    ["Traveling Merchant"]  = Vector3.new(-135, 2, 2764),
    ["Kohana"]              = Vector3.new(-626, 16, 588),
    ["Kohana Lava"]         = Vector3.new(-594, 59, 112),
    ["Esoteric Island"]     = Vector3.new(1991, 6, 1390),
    ["Esoteric Depths"]     = Vector3.new(3240, -1302, 1404),
    ["Tropical Grove"]      = Vector3.new(-2132, 53, 3630),
    ["Coral Reef"]          = Vector3.new(-3138, 4, 2132),
    ["Weather Machine"]     = Vector3.new(-1517, 3, 1910),
    ["Sisyphus Statue"]     = Vector3.new(-3657, -134, -963),
    ["Treasure Room"]       = Vector3.new(-3604, -284, -1632),
    ["Ancient Jungle"]      = Vector3.new(1463, 8, -358),
    ["Ancient Ruin"]        = Vector3.new(6067, -586, 4714),
    ["Sacred Temple"]       = Vector3.new(1476, -22, -632),
    ["Classic Island"]      = Vector3.new(1433, 44, 2755),
    ["Iron Cavern"]         = Vector3.new(-8798, -585, 241),
    ["Iron Cafe"]           = Vector3.new(-8647, -548, 160),
    ["Crater Island"]       = Vector3.new(1070, 2, 5102),
    ["Cristmas Island"]     = Vector3.new(1175, 24, 1558),
    ["Underground Cellar"]  = Vector3.new(2135, -91, -700),
    ["Christmas Cave"]      = Vector3.new(715, -487, 8910),
}

local WaypointsTNT = {
    ["TNT 1"]  = Vector3.new(3347, 14, 3442),
    ["TNT 2"]  = Vector3.new(3439, 10, 3560),
    ["TNT 3"]  = Vector3.new(3144, 5, 3790),
    ["TNT 4"]  = Vector3.new(3392, 13, 3632),
    ["Door TNT"] = Vector3.new(3405, 10, 3350),
}

-- Enhanced Teleport Function with validation
local function TeleportTo(targetPos, offset)
    offset = offset or Vector3.new(0, 3, 0)
    
    if typeof(targetPos) ~= "Vector3" then
        warn("[TELEPORT] Invalid target position")
        return false
    end
    
    local char = LocalPlayer.Character
    if not char then
        warn("[TELEPORT] Character not found")
        return false
    end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        warn("[TELEPORT] HRP not found")
        return false
    end
    
    local success = pcall(function()
        -- Stop velocity
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        
        -- Apply teleport
        hrp.CFrame = CFrame.new(targetPos + offset)
        
        -- Small delay for stabilization
        task.wait(0.1)
    end)
    
    if success then
        print("[TELEPORT] Successfully teleported to:", targetPos)
        return true
    else
        warn("[TELEPORT] Failed to teleport")
        return false
    end
end

-- ============================================
-- ⛅ ENHANCED AUTO WEATHER v4.1
-- ============================================
do
    local RS = game:GetService("ReplicatedStorage")
    local Replion = require(RS.Packages.Replion)
    local EventsReplion = Replion.Client:WaitReplion("Events")
    
    local PurchaseWeather = GetRemote("RF/PurchaseWeatherEvent")
    
    -- Enhanced weather state
    local WeatherState = {
        Connection = nil,
        Active = false,
        LastUpdate = 0,
        UpdateInterval = 15, -- seconds
        RetryCount = 0,
        MaxRetries = 3
    }
    
    -- Check if weather is active
    local function IsWeatherActive(name)
        local list = EventsReplion:Get("WeatherMachine")
        if not list or typeof(list) ~= "table" then 
            return false 
        end
        
        for _, v in ipairs(list) do
            if v == name then
                return true
            end
        end
        return false
    end
    
    -- Purchase missing weather
    local function PurchaseMissingWeather()
        if not SettingsState.AutoWeather.Active then return end
        if not SettingsState.AutoWeather.SelectedList then return end
        if #SettingsState.AutoWeather.SelectedList == 0 then return end
        
        local activeList = EventsReplion:Get("WeatherMachine") or {}
        local purchased = false
        
        for _, weather in ipairs(SettingsState.AutoWeather.SelectedList) do
            if not IsWeatherActive(weather) then
                warn("[AUTO WEATHER] Purchasing missing weather:", weather)
                local success = pcall(function()
                    PurchaseWeather:InvokeServer(weather)
                end)
                
                if success then
                    purchased = true
                    WeatherState.RetryCount = 0
                else
                    WeatherState.RetryCount = WeatherState.RetryCount + 1
                    warn("[AUTO WEATHER] Purchase failed, retry count:", WeatherState.RetryCount)
                end
                
                task.wait(0.5) -- Delay between purchases
            end
        end
        
        return purchased
    end
    
    -- Enhanced weather update handler
    local function WeatherUpdated()
        if not SettingsState.AutoWeather.Active then return end
        
        local now = tick()
        if now - WeatherState.LastUpdate < WeatherState.UpdateInterval then
            return
        end
        
        WeatherState.LastUpdate = now
        
        -- Check max retries
        if WeatherState.RetryCount >= WeatherState.MaxRetries then
            warn("[AUTO WEATHER] Max retries reached, disabling...")
            if WeatherState.Connection then
                WeatherState.Connection:Disconnect()
                WeatherState.Connection = nil
            end
            SettingsState.AutoWeather.Active = false
            return
        end
        
        PurchaseMissingWeather()
    end
    
    -- Start auto weather
    function StartAutoWeather()
        if SettingsState.AutoWeather.Active then 
            warn("[AUTO WEATHER] Already active")
            return 
        end
        
        if not PurchaseWeather then
            warn("[AUTO WEATHER] PurchaseWeather remote not found")
            return
        end
        
        SettingsState.AutoWeather.Active = true
        WeatherState.Active = true
        WeatherState.RetryCount = 0
        
        warn("===== ENHANCED WEATHER SYSTEM v4.1 =====")
        
        -- Disconnect old connection
        if WeatherState.Connection then
            WeatherState.Connection:Disconnect()
            WeatherState.Connection = nil
        end
        
        -- Listen for weather changes
        WeatherState.Connection = EventsReplion:OnChange("WeatherMachine", function(newValue)
            warn("[WEATHER] WeatherMachine changed:", newValue)
            task.defer(WeatherUpdated)
        end)
        
        -- Initial scan
        task.defer(WeatherUpdated)
        
        -- Periodic check (safety net)
        task.spawn(function()
            while SettingsState.AutoWeather.Active do
                task.wait(WeatherState.UpdateInterval)
                WeatherUpdated()
            end
        end)
    end
    
    -- Stop auto weather
    function StopAutoWeather()
        SettingsState.AutoWeather.Active = false
        WeatherState.Active = false
        
        if WeatherState.Connection then
            WeatherState.Connection:Disconnect()
            WeatherState.Connection = nil
        end
        
        warn("[AUTO WEATHER] Disabled")
    end
end

-- =====================================================
-- 💰 BAGIAN 6: ENHANCED AUTO SELL
-- =====================================================
local function StartAutoSellLoop()
    if SettingsState.AutoSell.Task then
        warn("[AUTO SELL] Loop already running")
        return
    end
    
    SettingsState.AutoSell.Task = task.spawn(function()
        print("💰 Enhanced Auto Sell: BACKGROUND MODE STARTED")
        
        while SettingsState.AutoSell.TimeActive do
            -- Wait for interval
            for i = 1, SettingsState.AutoSell.TimeInterval do
                if not SettingsState.AutoSell.TimeActive then 
                    SettingsState.AutoSell.Task = nil
                    return 
                end
                task.wait(1)
            end
            
            -- Perform sell with safety
            if SettingsState.AutoSell.TimeActive then
                pcall(function() 
                    SellAll:InvokeServer() 
                    print("[AUTO SELL] Sold items at", os.date("%H:%M:%S"))
                end)
            end
        end
        
        SettingsState.AutoSell.Task = nil
    end)
end

-- Enhanced sell function with feedback
local function SellNow()
    if SettingsState.AutoSell.IsSelling then
        warn("[SELL] Already selling, please wait")
        return false
    end
    
    SettingsState.AutoSell.IsSelling = true
    
    local success = pcall(function()
        SellAll:InvokeServer()
    end)
    
    SettingsState.AutoSell.IsSelling = false
    
    if success then
        print("[SELL] Manual sell successful")
        return true
    else
        warn("[SELL] Manual sell failed")
        return false
    end
end

-- =====================================================
-- 🎣 BAGIAN 7: ENHANCED FISHING LOGIC
-- =====================================================
local FishingBlocker = {
    Enabled = false,
    AutoGreat = false,
    Debounce = false
}

-------------------------------------------------------
-- ENHANCED FISHING BLOCKER WITH DEBOUNCE
-------------------------------------------------------
local BLOCKED_REMOTES = {
    [ChargeRod]    = true,
    [RequestGame]  = true,
    [CompleteGame] = true,
    [CancelInput]  = true,
}

-- Safe hookmetamethod with fallback
local oldNamecall
local function SetupFishingBlocker()
    if not (syn or protectgui or getgenv) then
        warn("[BLOCKER] Executor not supported for advanced blocking")
        return
    end
    
    if oldNamecall then return end
    
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        
        -- Check if blocker is active and remote is blocked
        if FishingBlocker.Enabled and BLOCKED_REMOTES[self] then
            -- Simple caller check (compatible with most executors)
            local callerScript = getcallingscript()
            if callerScript and callerScript:IsDescendantOf(game) then
                if method == "InvokeServer" then
                    -- Return nil but don't freeze
                    return nil
                elseif method == "FireServer" then
                    return nil
                end
            end
        end
        
        return oldNamecall(self, ...)
    end)
    
    print("[BLOCKER] Fishing blocker initialized")
end

-- Initialize blocker
task.defer(SetupFishingBlocker)

-------------------------------------------------
-- ENHANCED SPAWN LIMITER WITH QUEUE
-------------------------------------------------
local MAX_PARALLEL = 4
local activeTasks = 0
local taskQueue = {}

local function ProcessTaskQueue()
    while #taskQueue > 0 and activeTasks < MAX_PARALLEL do
        local taskFn = table.remove(taskQueue, 1)
        activeTasks = activeTasks + 1
        
        task.spawn(function()
            pcall(taskFn)
            activeTasks = activeTasks - 1
            ProcessTaskQueue()
        end)
    end
end

local function QueueTask(fn)
    table.insert(taskQueue, fn)
    ProcessTaskQueue()
end

-------------------------------------------------
-- ENHANCED FISHING LOOPS
-------------------------------------------------
local fishingDebounce = false

local function StartFishingLoop()
    if fishingDebounce then return end
    fishingDebounce = true
    
    local _Cancel = CancelInput
    local _Complete = CompleteGame
    local _Charge = ChargeRod
    
    -- Enable AutoGreat if set
    if FishingBlocker.AutoGreat then
        pcall(function()
            local state = { true }
            GetRemote("RF/UpdateAutoFishingState"):InvokeServer(unpack(state))
        end)
    end
    
    while getgenv().fishingStart do
        QueueTask(function()
            pcall(function() _Charge:InvokeServer() end)
        end)
        
        task.wait(0.055)
        
        if not getgenv().fishingStart then break end
        
        QueueTask(function()
            pcall(function() 
                RequestGame:InvokeServer(unpack(args)) 
            end)
        end)
        
        task.wait(delayTime)
        
        if not getgenv().fishingStart then break end 
        
        QueueTask(function()
            pcall(function() _Complete:FireServer() end)
        end)
        
        task.wait(0.05)
        
        QueueTask(function()
            pcall(function() _Cancel:InvokeServer() end)
        end)
    end
    
    fishingDebounce = false
end

local function StartFishingSuperInstantLoop()
    if fishingDebounce then return end
    fishingDebounce = true
    
    warn("🚀 ENHANCED SUPER INSTANT LOOP ACTIVATED")
    
    local _Charge = ChargeRod
    local _Request = RequestGame
    local _Complete = CompleteGame
    local _Cancel = CancelInput
    
    -- Enable AutoGreat if set
    if FishingBlocker.AutoGreat then
        pcall(function()
            local state = { true }
            GetRemote("RF/UpdateAutoFishingState"):InvokeServer(unpack(state))
        end)
    end
    
    -- Initial cancel
    pcall(function() _Cancel:InvokeServer() end)
    task.wait(0.055)
    
    while getgenv().fishingStart do
        QueueTask(function()
            _Charge:InvokeServer()
        end)
        
        task.wait(0.01)
        
        QueueTask(function()
            _Request:InvokeServer(unpack(args))
        end)
        
        task.wait(delayCharge)
        
        QueueTask(function()
            pcall(function() _Complete:FireServer() end)
        end)
        
        task.wait(delayReset)
        
        QueueTask(function()
            pcall(function() _Cancel:InvokeServer() end)
        end)
        
        task.wait(0.01)
    end
    
    fishingDebounce = false
end

local function ResetCharacter()
    if not CompleteGame or not CancelInput then
        warn("[RESET] Remotes not available")
        return false
    end
    
    local success = pcall(function()
        CompleteGame:FireServer()
        task.wait(0.05)
        CancelInput:InvokeServer()
    end)
    
    return success
end

-- =====================================================
-- ⚙️ BAGIAN 8: ENHANCED FEATURES
-- =====================================================

-------------------------------------------------
-- ENHANCED FPS BOOST
-------------------------------------------------
local function ToggleFPSBoost(state)
    if state then
        -- Save original settings
        if not next(SettingsState.FPSBoost.Original) then
            SettingsState.FPSBoost.Original = {
                QualityLevel = settings().Rendering.QualityLevel,
                GlobalShadows = game:GetService("Lighting").GlobalShadows
            }
        end
        
        -- Apply optimizations
        pcall(function()
            settings().Rendering.QualityLevel = 1
            game:GetService("Lighting").GlobalShadows = false
            
            -- Optional: reduce particle count
            for _, v in pairs(game:GetDescendants()) do
                if v:IsA("BasePart") then 
                    v.Material = Enum.Material.Plastic
                    v.CastShadow = false 
                end
            end
        end)
        
        print("[FPS] Boost activated")
    else
        -- Restore original settings
        if next(SettingsState.FPSBoost.Original) then
            pcall(function()
                settings().Rendering.QualityLevel = SettingsState.FPSBoost.Original.QualityLevel
                game:GetService("Lighting").GlobalShadows = SettingsState.FPSBoost.Original.GlobalShadows
            end)
        end
        
        print("[FPS] Boost deactivated")
    end
end

-------------------------------------------------
-- ENHANCED VFX REMOVAL
-------------------------------------------------
local VFXState = {
    Active = false,
    Connections = {},
    Original = {}
}

local function EnableVFXRemoval()
    if VFXState.Active then return end
    VFXState.Active = true
    
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local VFXFolder = ReplicatedStorage:FindFirstChild("VFX")
    
    if not VFXFolder then
        warn("[VFX] VFX folder not found")
        return
    end
    
    local function HasDiveOrThrowAncestor(instance)
        local current = instance
        while current and current ~= VFXFolder do
            if type(current.Name) == "string" then
                if string.find(current.Name, "Dive") or string.find(current.Name, "Throw") then
                    return true
                end
            end
            current = current.Parent
        end
        return false
    end
    
    local function DisableVisual(obj)
        if obj:IsA("ParticleEmitter") then
            -- Save original state
            if not VFXState.Original[obj] then
                VFXState.Original[obj] = {
                    Enabled = obj.Enabled,
                    Transparency = obj.Transparency
                }
            end
            obj.Enabled = false
            obj.Transparency = NumberSequence.new(1)
        elseif obj:IsA("Trail") or obj:IsA("Beam") then
            if not VFXState.Original[obj] then
                VFXState.Original[obj] = { Enabled = obj.Enabled }
            end
            obj.Enabled = false
        elseif obj:IsA("Explosion") then
            if not VFXState.Original[obj] then
                VFXState.Original[obj] = { Visible = obj.Visible }
            end
            obj.Visible = false
        end
    end
    
    -- Apply to existing
    for _, obj in ipairs(VFXFolder:GetDescendants()) do
        if HasDiveOrThrowAncestor(obj) then
            DisableVisual(obj)
        end
    end
    
    -- Listen for new
    VFXState.Connections[#VFXState.Connections + 1] = VFXFolder.DescendantAdded:Connect(function(child)
        task.wait()
        if VFXState.Active and HasDiveOrThrowAncestor(child) then
            DisableVisual(child)
        end
    end)
    
    print("[VFX] Removal activated")
end

local function DisableVFXRemoval()
    if not VFXState.Active then return end
    VFXState.Active = false
    
    -- Restore original states
    for obj, original in pairs(VFXState.Original) do
        if obj and obj.Parent then
            pcall(function()
                if obj:IsA("ParticleEmitter") then
                    obj.Enabled = original.Enabled
                    obj.Transparency = original.Transparency or NumberSequence.new(0)
                elseif obj:IsA("Trail") or obj:IsA("Beam") then
                    obj.Enabled = original.Enabled
                elseif obj:IsA("Explosion") then
                    obj.Visible = original.Visible
                end
            end)
        end
    end
    
    -- Cleanup connections
    for _, conn in ipairs(VFXState.Connections) do
        conn:Disconnect()
    end
    table.clear(VFXState.Connections)
    table.clear(VFXState.Original)
    
    print("[VFX] Removal deactivated")
end

-------------------------------------------------
-- ENHANCED POPUP DESTROYER
-------------------------------------------------
local function ExecuteDestroyPopup()
    if SettingsState.PopupDestroyed then return end
    
    local function DestroyPopup(child)
        if child.Name == "Small Notification" then
            task.wait(0.1)
            pcall(function() child:Destroy() end)
        end
    end
    
    -- Destroy existing
    for _, child in pairs(PlayerGui:GetChildren()) do
        DestroyPopup(child)
    end
    
    -- Listen for new
    PlayerGui.ChildAdded:Connect(DestroyPopup)
    
    SettingsState.PopupDestroyed = true
    print("[POPUP] Destroyer activated")
end

-------------------------------------------------
-- ENHANCED ANTI-AFK
-------------------------------------------------
local function StartAntiAFK()
    local VirtualUser = game:GetService("VirtualUser")
    
    -- Disable existing idle connections
    pcall(function()
        for _, conn in pairs(getconnections(LocalPlayer.Idled)) do
            if conn.Disable then 
                conn:Disable() 
            elseif conn.Disconnect then 
                conn:Disconnect() 
            end
        end
    end)
    
    -- Add our own
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
    
    print("[AFK] Anti-AFK activated")
end

-------------------------------------------------
-- ENHANCED WATER WALK
-------------------------------------------------
local function ToggleWaterWalk(state)
    SettingsState.WaterWalk.Active = state
    
    if state then
        if SettingsState.WaterWalk.Part then return end
        
        local char = LocalPlayer.Character
        if not char then 
            warn("[WATER WALK] Character not found")
            return 
        end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then 
            warn("[WATER WALK] HRP not found")
            return 
        end
        
        -- Create platform
        local platform = Instance.new("Part")
        platform.Name = "UQiLL_WaterPlatform"
        platform.Size = Vector3.new(18, 1, 18)
        platform.Anchored = true
        platform.CanCollide = true
        platform.Transparency = 0.7
        platform.Material = Enum.Material.Neon
        platform.Color = Color3.fromRGB(0, 150, 255)
        platform.Parent = Workspace
        
        SettingsState.WaterWalk.Part = platform
        
        -- Update position
        SettingsState.WaterWalk.Connection = RunService.Heartbeat:Connect(function()
            local charNow = LocalPlayer.Character
            if not charNow then return end
            
            local hrpNow = charNow:FindFirstChild("HumanoidRootPart")
            if not hrpNow then return end
            
            platform.CFrame = CFrame.new(
                hrpNow.Position.X,
                hrpNow.Position.Y - 5, -- Keep below player
                hrpNow.Position.Z
            )
        end)
        
        print("[WATER WALK] Activated")
    else
        -- Cleanup
        if SettingsState.WaterWalk.Connection then
            SettingsState.WaterWalk.Connection:Disconnect()
            SettingsState.WaterWalk.Connection = nil
        end
        
        if SettingsState.WaterWalk.Part then
            SettingsState.WaterWalk.Part:Destroy()
            SettingsState.WaterWalk.Part = nil
        end
        
        print("[WATER WALK] Deactivated")
    end
end

-------------------------------------------------
-- ENHANCED ANIMATION DISABLER
-------------------------------------------------
local function ToggleAnims(state)
    SettingsState.AnimsDisabled.Active = state
    
    if state then
        -- Stop all current animations
        local function StopAll()
            local Char = LocalPlayer.Character
            if Char and Char:FindFirstChild("Humanoid") then
                local Hum = Char.Humanoid
                local Animator = Hum:FindFirstChild("Animator")
                if Animator then
                    for _, track in pairs(Animator:GetPlayingAnimationTracks()) do
                        track:Stop()
                    end
                end
            end
        end
        
        StopAll()
        
        -- Hook character
        local function HookChar(char)
            local hum = char:WaitForChild("Humanoid")
            local animator = hum:WaitForChild("Animator")
            local conn = animator.AnimationPlayed:Connect(function(track)
                if SettingsState.AnimsDisabled.Active then 
                    track:Stop() 
                end
            end)
            table.insert(SettingsState.AnimsDisabled.Connections, conn)
        end
        
        if LocalPlayer.Character then HookChar(LocalPlayer.Character) end
        
        local conn2 = LocalPlayer.CharacterAdded:Connect(HookChar)
        table.insert(SettingsState.AnimsDisabled.Connections, conn2)
        
        print("[ANIMS] Disabled")
    else
        -- Restore
        for _, conn in pairs(SettingsState.AnimsDisabled.Connections) do
            conn:Disconnect()
        end
        SettingsState.AnimsDisabled.Connections = {}
        
        print("[ANIMS] Enabled")
    end
end

-- ============================================================
-- 🎣 ENHANCED AUTO FAVORITE v8 - FIXED VERSION
-- ============================================================
do
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Replion = require(ReplicatedStorage.Packages.Replion)
    local Data = Replion.Client:WaitReplion("Data")
    
    local FavoriteItem = GetRemote("RE/FavoriteItem")
    local ObtainedNewFish = GetRemote("RE/ObtainedNewFishNotification")
    
    -------------------------------------------------------
    -- Fish Database
    -------------------------------------------------------
    local FishDB = {}
    local function LoadFishDB()
        for _, module in ipairs(ReplicatedStorage.Items:GetChildren()) do
            if module:IsA("ModuleScript") then
                local ok, mod = pcall(require, module)
                if ok and mod and mod.Data and mod.Data.Type == "Fish" then
                    FishDB[mod.Data.Id] = mod.Data.Tier
                end
            end
        end
        print("[AF] FishDB loaded:", #FishDB, "entries")
    end
    
    LoadFishDB()
    
    local function GetTier(id)
        return FishDB[id]
    end
    
    -------------------------------------------------------
    -- Rarity Mapping
    -------------------------------------------------------
    local RarityMap = {
        Common = 1,
        Uncommon = 2,
        Rare = 3,
        Epic = 4,
        Legendary = 5,
        Mythic = 6,
        Secret = 7,
        Exotic = 8,
        Azure = 9
    }
    
    local SelectedTier = {}
    local KnownUUID = {}
    local AutoFavActive = false
    local newFishConnection = nil
    
    -------------------------------------------------------
    -- Set Selected Rarities (FIXED FUNCTION DECLARATION)
    -------------------------------------------------------
    local function SetSelectedRarities(list)
        SelectedTier = {}
        
        for _, rarity in ipairs(list) do
            local tier = RarityMap[rarity]
            if tier then 
                SelectedTier[tier] = true 
            end
        end
        
        print("[AF] Selected tiers updated:", SelectedTier)
    end
    
    -------------------------------------------------------
    -- Favorite Logic
    -------------------------------------------------------
    local function FavoriteIfMatch(item)
        if not item then return end
        
        local uuid = item.UUID
        if KnownUUID[uuid] then return end
        
        local id = item.Id
        local fav = item.Favorited
        local tier = GetTier(id)
        
        if tier and SelectedTier[tier] and not fav then
            print("[AF] Favoriting:", uuid, "Tier:", tier)
            pcall(function()
                FavoriteItem:FireServer(uuid)
            end)
        end
        
        KnownUUID[uuid] = true
    end
    
    -------------------------------------------------------
    -- Initial Scan
    -------------------------------------------------------
    local function InitialScan()
        local inv = Data:Get("Inventory")
        if inv and inv.Items then
            print("[AF] Performing initial scan...")
            local count = 0
            for _, item in pairs(inv.Items) do
                FavoriteIfMatch(item)
                count = count + 1
            end
            print("[AF] Scanned", count, "items")
        end
    end
    
    -------------------------------------------------------
    -- Start Auto Favorite
    -------------------------------------------------------
    local function StartAutoFavorite()
        if AutoFavActive then return end
        
        print("[AF] Auto Favorite ENABLED")
        AutoFavActive = true
        
        -- Reset cache
        KnownUUID = {}
        
        -- Initial scan
        task.defer(InitialScan)
        
        -- Listen for new fish
        if ObtainedNewFish then
            newFishConnection = ObtainedNewFish.OnClientEvent:Connect(function(...)
                if not AutoFavActive then return end
                
                print("[AF] New fish obtained, scanning...")
                
                task.defer(function()
                    local inv = Data:Get("Inventory")
                    if not inv or not inv.Items then return end
                    
                    for _, item in pairs(inv.Items) do
                        FavoriteIfMatch(item)
                    end
                end)
            end)
        else
            warn("[AF] ObtainedNewFish remote not found")
        end
    end
    
    -------------------------------------------------------
    -- Stop Auto Favorite
    -------------------------------------------------------
    local function StopAutoFavorite()
        if not AutoFavActive then return end
        
        print("[AF] Auto Favorite DISABLED")
        AutoFavActive = false
        
        -- Cleanup
        if newFishConnection then
            newFishConnection:Disconnect()
            newFishConnection = nil
        end
        
        -- Clear cache
        KnownUUID = {}
    end
    
    -------------------------------------------------------
    -- UI Wrapper (FIXED - removed improper function declaration)
    -------------------------------------------------------
    -- This function will be called from UI
    local function ToggleAutoFavorite(state)
        if state then 
            StartAutoFavorite()
        else 
            StopAutoFavorite() 
        end
    end
    
    -------------------------------------------------------
    -- Export functions to global scope for UI access
    -------------------------------------------------------
    _G.SetSelectedRarities = SetSelectedRarities
    _G.ToggleAutoFavorite = ToggleAutoFavorite
end

-- =====================================================
-- 🌌 BAGIAN 9: ENHANCED TELEPORT UTILS
-- =====================================================
local function TeleportToMegalodon()
    local ringsFolder = Workspace:FindFirstChild("!!! MENU RINGS")
    if not ringsFolder then 
        warn("[MEGALODON] Rings folder not found")
        return false
    end
    
    local propsFolder = ringsFolder:FindFirstChild("Props")
    if not propsFolder then 
        warn("[MEGALODON] Props folder not found")
        return false
    end
    
    local eventModel = propsFolder:FindFirstChild("Megalodon Hunt")
    if not eventModel then
        warn("[MEGALODON] Megalodon Hunt not found")
        return false
    end
    
    local topPart = eventModel:FindFirstChild("Top")
    if topPart and topPart:FindFirstChild("BlackHole") then
        return TeleportTo(topPart.BlackHole.Position + Vector3.new(0, 20, 0))
    else
        return TeleportTo(eventModel:GetPivot().Position)
    end
end

-- =====================================================
-- 📍 ENHANCED POSITION WATCHER
-- =====================================================
local CoordDisplay = nil 
local LivePosToggle = nil 

local function TogglePosWatcher(state)
    SettingsState.PosWatcher.Active = state
    
    if state then
        if SettingsState.PosWatcher.Connection then
            SettingsState.PosWatcher.Connection:Disconnect()
        end
        
        SettingsState.PosWatcher.Connection = RunService.RenderStepped:Connect(function()
            local Char = LocalPlayer.Character
            if Char and Char:FindFirstChild("HumanoidRootPart") then
                local pos = Char.HumanoidRootPart.Position
                local txt = string.format("X: %.1f | Y: %.1f | Z: %.1f", pos.X, pos.Y, pos.Z)
                
                if CoordDisplay then 
                    pcall(function() CoordDisplay:SetDesc(txt) end) 
                end
                
                if LivePosToggle then 
                    pcall(function() LivePosToggle:SetDesc(txt) end) 
                end
            end
        end)
        
        print("[POS WATCHER] Activated")
    else
        if SettingsState.PosWatcher.Connection then 
            SettingsState.PosWatcher.Connection:Disconnect() 
            SettingsState.PosWatcher.Connection = nil
        end
        
        if CoordDisplay then 
            pcall(function() CoordDisplay:SetDesc("Status: Off") end) 
        end
        
        if LivePosToggle then 
            pcall(function() LivePosToggle:SetDesc("Click to show coordinates") end) 
        end
        
        print("[POS WATCHER] Deactivated")
    end
end

-- =====================================================
-- 👤 ENHANCED PLAYER UTILS
-- =====================================================
local function FindPlayer(name)
    if not name or name == "" then return nil end
    
    name = string.lower(name)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if string.find(string.lower(p.Name), name) or 
               string.find(string.lower(p.DisplayName), name) then
                return p
            end
        end
    end
    return nil
end

local function GetPlayerList()
    local names = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then 
            table.insert(names, p.Name) 
        end
    end
    table.sort(names)
    return names
end

-- =====================================================
-- 🎭 ENHANCED NAME SPOOFER
-- =====================================================
local NameSpoof = {
    Active = false,
    FakeName = "",
    OriginalText = nil,
    Label = nil,
    CharConn = nil
}

local function GetNameLabel()
    local char = LocalPlayer.Character
    if not char then return nil end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    local overhead = hrp:FindFirstChild("Overhead")
    if not overhead then return nil end
    
    local content = overhead:FindFirstChild("Content")
    if not content then return nil end
    
    local header = content:FindFirstChild("Header")
    if header and header:IsA("TextLabel") then
        return header
    end
    
    return nil
end

local function ApplyNameSpoof()
    if not NameSpoof.Active or NameSpoof.FakeName == "" then return end
    
    local label = GetNameLabel()
    if not label then return end
    
    if not NameSpoof.OriginalText then
        NameSpoof.OriginalText = label.Text
    end
    
    NameSpoof.Label = label
    label.Text = NameSpoof.FakeName
end

local function RestoreName()
    if NameSpoof.Label and NameSpoof.OriginalText then
        pcall(function()
            NameSpoof.Label.Text = NameSpoof.OriginalText
        end)
    end
    
    NameSpoof.OriginalText = nil
    NameSpoof.Label = nil
end

local function EnableNameSpoof()
    if NameSpoof.Active or NameSpoof.FakeName == "" then return end
    
    NameSpoof.Active = true
    ApplyNameSpoof()
    
    NameSpoof.CharConn = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.3)
        ApplyNameSpoof()
    end)
    
    print("[SPOOF] Name spoof enabled:", NameSpoof.FakeName)
end

local function DisableNameSpoof()
    if not NameSpoof.Active then return end
    
    NameSpoof.Active = false
    
    if NameSpoof.CharConn then
        NameSpoof.CharConn:Disconnect()
        NameSpoof.CharConn = nil
    end
    
    RestoreName()
    print("[SPOOF] Name spoof disabled")
end

-- =====================================================
-- 🎯 ENHANCED AUTO EVENT PROPS
-- =====================================================
do
    local Workspace = game:GetService("Workspace")
    
    local AutoPropsEvent = {
        Enabled = false,
        Active = false,
        SavedPos = nil,
        CurrentEvent = nil,
        SelectedEvent = nil,
        Connections = {}
    }
    
    local function _HRP()
        local char = LocalPlayer.Character
        return char and char:FindFirstChild("HumanoidRootPart")
    end
    
    local function GetValidPropsContainers()
        local containers = {}
        for _, inst in ipairs(Workspace:GetChildren()) do
            if inst.Name == "Props" and (inst:IsA("Folder") or inst:IsA("Model")) then
                table.insert(containers, inst)
            end
        end
        return containers
    end
    
    local function IsEventNode(node)
        if not AutoPropsEvent.SelectedEvent then return false end
        if not node then return false end
        if not (node:IsA("Model") or node:IsA("Folder")) then return false end
        if not node.Parent or node.Parent.Name ~= "Props" then return false end
        if node.Parent.Parent ~= Workspace then return false end
        
        return node.Name == AutoPropsEvent.SelectedEvent
    end
    
    local function StartEvent(eventNode)
        if AutoPropsEvent.Active then return end
        
        local hrp = _HRP()
        if not hrp then return end
        
        AutoPropsEvent.Active = true
        AutoPropsEvent.CurrentEvent = eventNode
        AutoPropsEvent.SavedPos = hrp.Position
        
        print("[AUTO EVENT] START ->", eventNode:GetFullName())
        TeleportTo(eventNode:GetPivot().Position + Vector3.new(0, 2, 0))
    end
    
    local function EndEvent(eventNode)
        if AutoPropsEvent.CurrentEvent ~= eventNode then return end
        
        print("[AUTO EVENT] END ->", eventNode:GetFullName())
        
        if AutoPropsEvent.SavedPos then
            TeleportTo(AutoPropsEvent.SavedPos + Vector3.new(0, 2, 0))
        end
        
        AutoPropsEvent.Active = false
        AutoPropsEvent.SavedPos = nil
        AutoPropsEvent.CurrentEvent = nil
    end
    
    function SetAutoEventSelection(eventName)
        AutoPropsEvent.SelectedEvent = eventName
        print("[AUTO EVENT] Selected:", eventName)
    end
    
    function GetAvailableAutoEvents()
        local found, list = {}, {}
        for _, props in ipairs(GetValidPropsContainers()) do
            for _, child in ipairs(props:GetChildren()) do
                if (child:IsA("Model") or child:IsA("Folder")) and not found[child.Name] then
                    found[child.Name] = true
                    table.insert(list, child.Name)
                end
            end
        end
        table.sort(list)
        return list
    end
    
    function EnableAutoEventProps()
        if AutoPropsEvent.Enabled then return end
        if not AutoPropsEvent.SelectedEvent then return end
        
        AutoPropsEvent.Enabled = true
        print("[AUTO EVENT] ENABLED")
        
        -- Scan existing
        for _, props in ipairs(GetValidPropsContainers()) do
            for _, child in ipairs(props:GetChildren()) do
                if IsEventNode(child) then
                    StartEvent(child)
                end
            end
        end
        
        -- Listen for changes
        table.insert(AutoPropsEvent.Connections, Workspace.ChildAdded:Connect(function(container)
            if container.Name == "Props" and container.Parent == Workspace then
                container.ChildAdded:Connect(function(child)
                    if IsEventNode(child) then
                        StartEvent(child)
                    end
                end)
            end
        end))
        
        table.insert(AutoPropsEvent.Connections, Workspace.DescendantRemoving:Connect(function(inst)
            if inst == AutoPropsEvent.CurrentEvent then
                EndEvent(inst)
            end
        end))
    end
    
    function DisableAutoEventProps()
        if not AutoPropsEvent.Enabled then return end
        
        AutoPropsEvent.Enabled = false
        
        for _, conn in ipairs(AutoPropsEvent.Connections) do
            conn:Disconnect()
        end
        AutoPropsEvent.Connections = {}
        
        AutoPropsEvent.Active = false
        AutoPropsEvent.SavedPos = nil
        AutoPropsEvent.CurrentEvent = nil
        
        print("[AUTO EVENT] DISABLED")
    end
    
    function TeleportOnlyToEvent()
        if not AutoPropsEvent.SelectedEvent then return false end
        
        for _, props in ipairs(GetValidPropsContainers()) do
            for _, child in ipairs(props:GetChildren()) do
                if IsEventNode(child) then
                    TeleportTo(child:GetPivot().Position + Vector3.new(0, 2, 0))
                    return true
                end
            end
        end
        return false
    end
end

-- =====================================================
-- 🎣 ENHANCED FISH WEBHOOK LOGGER
-- =====================================================
do
    -------------------------------------------------------
    -- CONFIG
    -------------------------------------------------------
    local DEBUG = false
    
    -------------------------------------------------------
    -- SERVICES
    -------------------------------------------------------
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local HttpService = game:GetService("HttpService")
    
    local LocalPlayer = Players.LocalPlayer
    local ObtainedNewFish = GetRemote("RE/ObtainedNewFishNotification")
    
    -------------------------------------------------------
    -- DEBUG LOGGER
    -------------------------------------------------------
    local function dlog(...)
        if DEBUG then
            print("[WEBHOOK][DEBUG]", ...)
        end
    end
    
    -------------------------------------------------------
    -- RARITY MAP
    -------------------------------------------------------
    local RARITY_MAP = {
        [1] = "Common",
        [2] = "Uncommon",
        [3] = "Rare",
        [4] = "Epic",
        [5] = "Legendary",
        [6] = "Mythic",
        [7] = "Secret",
    }
    
    -------------------------------------------------------
    -- NAME → TIER
    -------------------------------------------------------
    local RARITY_NAME_TO_TIER = {
        Common = 1,
        Uncommon = 2,
        Rare = 3,
        Epic = 4,
        Legendary = 5,
        Mythic = 6,
        Secret = 7,
    }
    
    -------------------------------------------------------
    -- COLOR + GRADIENT
    -------------------------------------------------------
    local RARITY_COLOR = {
        [1] = 0x9e9e9e,
        [2] = 0x4caf50,
        [3] = 0x2196f3,
        [4] = 0x9c27b0,
        [5] = 0xff9800,
        [6] = 0xf44336,
        [7] = 0xff1744,
    }
    
    local RARITY_GRADIENT = {
        [1] = "⬜",
        [2] = "🟩",
        [3] = "🟦",
        [4] = "🟪",
        [5] = "🟧",
        [6] = "🟥",
        [7] = "⬛",
    }
    
    -------------------------------------------------------
    -- FISH DATABASE
    -------------------------------------------------------
    local FishDB = {}
    local IconCache = {}
    local IconWaiter = {}
    
    local function LoadFishWebhookDB()
        for _, module in ipairs(ReplicatedStorage.Items:GetChildren()) do
            if module:IsA("ModuleScript") then
                local ok, mod = pcall(require, module)
                if ok and mod and mod.Data and mod.Data.Type == "Fish" then
                    FishDB[mod.Data.Id] = {
                        Name = mod.Data.Name,
                        Tier = mod.Data.Tier,
                        Icon = mod.Data.Icon
                    }
                end
            end
        end
        dlog("FishDB loaded:", #FishDB, "entries")
    end
    
    LoadFishWebhookDB()
    
    -------------------------------------------------------
    -- FETCH ICON
    -------------------------------------------------------
    local function FetchFishIconAsync(fishId, onReady)
        if IconCache[fishId] then
            onReady(IconCache[fishId])
            return
        end
        
        if IconWaiter[fishId] then
            table.insert(IconWaiter[fishId], onReady)
            return
        end
        
        IconWaiter[fishId] = { onReady }
        
        task.spawn(function()
            local fish = FishDB[fishId]
            if not fish or not fish.Icon then
                dlog("No icon for fishId", fishId)
                return
            end
            
            local assetId = tostring(fish.Icon):match("%d+")
            if not assetId then return end
            
            local api = string.format(
                "https://thumbnails.roblox.com/v1/assets?assetIds=%s&size=420x420&format=Png&isCircular=false",
                assetId
            )
            
            local success, response = pcall(function()
                local res = game:HttpGet(api)
                return HttpService:JSONDecode(res)
            end)
            
            if not success then return end
            
            local imageUrl = response and response.data and response.data[1] and response.data[1].imageUrl
            
            if not imageUrl then return end
            
            IconCache[fishId] = imageUrl
            dlog("Icon cached for", fishId)
            
            for _, cb in ipairs(IconWaiter[fishId]) do
                cb(imageUrl)
            end
            IconWaiter[fishId] = nil
        end)
    end
    
    -------------------------------------------------------
    -- RARITY FILTER
    -------------------------------------------------------
    local function IsRarityAllowedById(fishId)
        local fish = FishDB[fishId]
        if not fish then
            dlog("BLOCK: fish not in DB", fishId)
            return false
        end
        
        local tier = fish.Tier
        if type(tier) ~= "number" then
            dlog("BLOCK: invalid tier for", fishId)
            return false
        end
        
        local selected = SettingsState.WebhookFish.SelectedRarities
        
        if next(selected) == nil then
            dlog("ALLOW: no filter selected")
            return true
        end
        
        if selected[tier] then
            dlog("ALLOW: tier", tier, "matched")
            return true
        end
        
        dlog("BLOCK: tier", tier, "not selected")
        return false
    end
    
    -------------------------------------------------------
    -- BUILD PAYLOAD
    -------------------------------------------------------
    local function BuildFishPayload(player, fishId, weight, mutation)
        local fish = FishDB[fishId]
        if not fish then return nil end
        
        local tier = fish.Tier
        local mutationText = mutation or "None"
        
        return {
            username = "UQiLL Fishing Suite",
            avatar_url = "https://i.imgur.com/9fVwZQ2.png",
            embeds = {{
                title = string.format("%s 🎣 %s", RARITY_GRADIENT[tier] or "", fish.Name),
                color = RARITY_COLOR[tier] or 0x000000,
                fields = {
                    { name = "👤 Player", value = player, inline = true },
                    { name = "🎯 Rarity", value = RARITY_MAP[tier] or "Unknown", inline = true },
                    { name = "⚖️ Weight", value = string.format("%.2f kg", weight or 0), inline = true },
                    { name = "🧬 Mutation", value = mutationText, inline = true },
                    { name = "🆔 Fish ID", value = tostring(fishId), inline = true },
                },
                thumbnail = { url = IconCache[fishId] or "" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                footer = {
                    text = string.format("UQiLL v4.0 | Optimized by jpXCode | %s", os.date("%X")),
                },
            }}
        }
    end
    
    -------------------------------------------------------
    -- SEND WEBHOOK
    -------------------------------------------------------
    local function SendWebhook(payload)
        if not SettingsState.WebhookFish.Active then
            dlog("Webhook inactive")
            return
        end
        
        if SettingsState.WebhookFish.Url == "" then
            dlog("Webhook URL empty")
            return
        end
        
        dlog("Sending webhook...")
        
        local success, result = pcall(function()
            local json = HttpService:JSONEncode(payload)
            return game:HttpPost(SettingsState.WebhookFish.Url, json, Enum.HttpContentType.ApplicationJson)
        end)
        
        if success then
            dlog("Webhook sent successfully")
        else
            dlog("Webhook failed:", result)
        end
    end
    
    -------------------------------------------------------
    -- EVENT HANDLER
    -------------------------------------------------------
    if ObtainedNewFish then
        ObtainedNewFish.OnClientEvent:Connect(function(_, weightData, wrapper)
            dlog("Event fired")
            
            if not SettingsState.WebhookFish.Active then return end
            if not wrapper or not wrapper.InventoryItem then return end
            
            local item = wrapper.InventoryItem
            if not item.Id or not item.UUID then return end
            
            if not IsRarityAllowedById(item.Id) then
                dlog("Event blocked by rarity filter")
                return
            end
            
            if SettingsState.WebhookFish.SentUUID[item.UUID] then
                dlog("Duplicate UUID")
                return
            end
            
            SettingsState.WebhookFish.SentUUID[item.UUID] = true
            
            -- Extract mutation
            local mutation = nil
            if weightData then
                mutation = weightData.Mutation or weightData.Variant or weightData.VariantID
            end
            
            if not mutation and item then
                mutation = item.Mutation or item.Variant or item.VariantID
            end
            
            -- Fetch icon and send
            FetchFishIconAsync(item.Id, function()
                local payload = BuildFishPayload(
                    LocalPlayer.Name,
                    item.Id,
                    weightData and weightData.Weight or 0,
                    mutation
                )
                
                if payload then
                    SendWebhook(payload)
                end
            end)
        end)
    else
        warn("[WEBHOOK] ObtainedNewFish remote not found")
    end
    
    -------------------------------------------------------
    -- CONTROLLER
    -------------------------------------------------------
    function StartFishWebhook()
        if SettingsState.WebhookFish.Active then 
            print("[WEBHOOK] Already active")
            return 
        end
        
        if SettingsState.WebhookFish.Url == "" then
            WindUI:Notify({ 
                Title = "Webhook", 
                Content = "Webhook URL belum diisi", 
                Duration = 3 
            })
            return
        end
        
        SettingsState.WebhookFish.Active = true
        SettingsState.WebhookFish.SentUUID = {}
        
        -- Send activation message
        task.spawn(function()
            local activationPayload = {
                username = "UQiLL Fishing Suite",
                avatar_url = "https://i.imgur.com/9fVwZQ2.png",
                embeds = {{
                    title = "🚀 Webhook Activated",
                    description = string.format(
                        "**Player:** %s\n**Version:** v4.0\n**Optimized by:** jpXCode\n**Time:** %s",
                        LocalPlayer.Name,
                        os.date("%Y-%m-%d %H:%M:%S")
                    ),
                    color = 0x30ff6a,
                    footer = {
                        text = "UQiLL Fishing Suite | Enhanced & Stable"
                    }
                }}
            }
            
            SendWebhook(activationPayload)
        end)
        
        print("[WEBHOOK] ENABLED")
        WindUI:Notify({ 
            Title = "Webhook", 
            Content = "Webhook activated successfully", 
            Duration = 3 
        })
    end
    
    function StopFishWebhook()
        if not SettingsState.WebhookFish.Active then return end
        
        SettingsState.WebhookFish.Active = false
        SettingsState.WebhookFish.SentUUID = {}
        
        print("[WEBHOOK] DISABLED")
        WindUI:Notify({ 
            Title = "Webhook", 
            Content = "Webhook deactivated", 
            Duration = 3 
        })
    end
end

-- =====================================================
-- 📊 ENHANCED PERFORMANCE HUD
-- =====================================================
do
    -------------------------------------------------------
    -- SERVICES
    -------------------------------------------------------
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Stats = game:GetService("Stats")
    local UserInputService = game:GetService("UserInputService")
    
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    -------------------------------------------------------
    -- CONFIG
    -------------------------------------------------------
    local ICON_ID = "rbxassetid://130835920424032"
    
    -------------------------------------------------------
    -- STATE
    -------------------------------------------------------
    local HudState = {
        Visible = false,
        Dragging = false,
        DragStart = Vector2.zero,
        StartPos = UDim2.new(0, 20, 0, 140),
        Connection = nil
    }
    
    -------------------------------------------------------
    -- UI ROOT
    -------------------------------------------------------
    local Gui = Instance.new("ScreenGui")
    Gui.Name = GUI_NAMES.Performance
    Gui.ResetOnSpawn = false
    Gui.Parent = PlayerGui
    Gui.Enabled = false
    
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.fromOffset(240, 100)
    Frame.Position = HudState.StartPos
    Frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    Frame.BackgroundTransparency = 0.12
    Frame.BorderSizePixel = 0
    Frame.Parent = Gui
    
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 12)
    
    -------------------------------------------------------
    -- HEADER
    -------------------------------------------------------
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 32)
    Header.BackgroundTransparency = 1
    Header.Parent = Frame
    
    -- Icon
    local Icon = Instance.new("ImageLabel")
    Icon.Size = UDim2.fromOffset(20, 20)
    Icon.Position = UDim2.fromOffset(10, 6)
    Icon.BackgroundTransparency = 1
    Icon.Image = ICON_ID
    Icon.Parent = Header
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Position = UDim2.fromOffset(36, 0)
    Title.Size = UDim2.new(1, -36, 1, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "UQiLL Performance Monitor"
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 13
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextColor3 = Color3.fromRGB(170, 255, 170)
    Title.Parent = Header
    
    -------------------------------------------------------
    -- CONTENT
    -------------------------------------------------------
    local Content = Instance.new("TextLabel")
    Content.Position = UDim2.fromOffset(12, 36)
    Content.Size = UDim2.new(1, -24, 1, -40)
    Content.BackgroundTransparency = 1
    Content.TextXAlignment = Enum.TextXAlignment.Left
    Content.TextYAlignment = Enum.TextYAlignment.Top
    Content.Font = Enum.Font.Gotham
    Content.TextSize = 13
    Content.TextColor3 = Color3.fromRGB(230, 230, 230)
    Content.TextWrapped = true
    Content.Text = "Loading performance data..."
    Content.Parent = Frame
    
    -------------------------------------------------------
    -- DRAG HANDLER
    -------------------------------------------------------
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            HudState.Dragging = true
            HudState.DragStart = input.Position
            HudState.StartPos = Frame.Position
        end
    end)
    
    Header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            HudState.Dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if HudState.Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - HudState.DragStart
            Frame.Position = UDim2.new(
                HudState.StartPos.X.Scale,
                HudState.StartPos.X.Offset + delta.X,
                HudState.StartPos.Y.Scale,
                HudState.StartPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -------------------------------------------------------
    -- FPS CALCULATION
    -------------------------------------------------------
    local fps = 0
    local frameCount = 0
    local lastTick = os.clock()
    
    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local now = os.clock()
        
        if now - lastTick >= 1 then
            fps = frameCount
            frameCount = 0
            lastTick = now
        end
    end)
    
    -------------------------------------------------------
    -- UPDATE LOOP
    -------------------------------------------------------
    local function UpdatePerformanceHUD()
        if not HudState.Visible then return end
        
        local ping = 0
        local memory = 0
        
        pcall(function()
            ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            memory = math.floor(Stats:GetTotalMemoryUsageMb())
        end)
        
        Content.Text = string.format(
            "FPS    : %d\nPing   : %d ms\nMemory : %d MB",
            fps,
            ping,
            memory
        )
    end
    
    -------------------------------------------------------
    -- PUBLIC API
    -------------------------------------------------------
    function TogglePerformanceHUD(state)
        HudState.Visible = state
        Gui.Enabled = state
        
        if state then
            if HudState.Connection then
                HudState.Connection:Disconnect()
            end
            
            HudState.Connection = RunService.RenderStepped:Connect(function()
                UpdatePerformanceHUD()
            end)
            
            print("[PERFORMANCE HUD] Activated")
        else
            if HudState.Connection then
                HudState.Connection:Disconnect()
                HudState.Connection = nil
            end
            
            print("[PERFORMANCE HUD] Deactivated")
        end
    end
end

-- =====================================================
-- 🚫 NO 3D RENDERING (SAFE)
-- =====================================================
local NoRender3D = {
    Active = false,
    Supported = false
}

-- Check support
pcall(function()
    NoRender3D.Supported = typeof(RunService.Set3dRenderingEnabled) == "function"
end)

function NoRender3D:Enable()
    if self.Active or not self.Supported then return end
    
    local success = pcall(function()
        RunService:Set3dRenderingEnabled(false)
    end)
    
    if success then
        self.Active = true
        print("[NO 3D] Rendering disabled")
    else
        warn("[NO 3D] Failed to disable rendering")
    end
end

function NoRender3D:Disable()
    if not self.Active or not self.Supported then return end
    
    local success = pcall(function()
        RunService:Set3dRenderingEnabled(true)
    end)
    
    if success then
        self.Active = false
        print("[NO 3D] Rendering restored")
    else
        warn("[NO 3D] Failed to restore rendering")
    end
end

-- =====================================================
-- 📋 ENHANCED QUEST UI CONTROLLER
-- =====================================================
local function SetQuestListVisible(state)
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    
    local questGui = playerGui:FindFirstChild("Quest")
    if not questGui then return false end
    
    local list = questGui:FindFirstChild("List")
    if list and list:IsA("Frame") then
        list.Visible = state
        return true
    end
    
    return false
end

-- =====================================================
-- 🎨 BAGIAN 10: ENHANCED WIND UI SETUP
-- =====================================================
local function setElementVisible(name, visible)
    task.spawn(function()
        local CoreGui = game:GetService("CoreGui")
        for _, v in pairs(CoreGui:GetDescendants()) do
            if v:IsA("TextLabel") and v.Text == name then
                local current = v
                for i = 1, 6 do
                    if current.Parent then
                        current = current.Parent
                        if current.Parent:IsA("ScrollingFrame") then
                            current.Visible = visible
                            break 
                        end
                    end
                end
                
                pcall(function()
                    if v.Parent.Parent:IsA("Frame") and v.Parent.Parent.Name ~= "Content" then 
                        v.Parent.Parent.Visible = visible 
                    end
                    if v.Parent.Parent.Parent:IsA("Frame") then 
                        v.Parent.Parent.Parent.Visible = visible 
                    end
                end)
                break 
            end
        end
    end)
end

-- Create main window
local Window
if uiLoadSuccess then
    Window = WindUI:CreateWindow({ 
        Title = "UQiLL Fishing Suite", 
        Icon = "fish", 
        Author = "UQi | Enhanced by jpXCode", 
        Transparent = true 
    })
    
    Window.Name = GUI_NAMES.Main
    Window:Tag({ 
        Title = "v4.0 FINAL", 
        Icon = "github", 
        Color = Color3.fromHex("#30ff6a"), 
        Radius = 0 
    })
    Window:SetToggleKey(Enum.KeyCode.H)
    Window:EditOpenButton({
        Enabled = false,
    })
else
    warn("[UI] Using fallback UI mode")
end

-- =====================================================
-- 📱 ENHANCED FLOATING TOGGLE BUTTON
-- =====================================================
do
    -- Cleanup old button
    local old = CoreGui:FindFirstChild(GUI_NAMES.Mobile)
    if old then old:Destroy() end
    
    -- ScreenGui
    local Gui = Instance.new("ScreenGui")
    Gui.Name = GUI_NAMES.Mobile
    Gui.ResetOnSpawn = false
    Gui.Parent = CoreGui
    Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Button
    local Button = Instance.new("ImageButton")
    Button.Size = UDim2.fromOffset(52, 52)
    Button.Position = UDim2.fromScale(0.05, 0.5)
    Button.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Button.BackgroundTransparency = 0.1
    Button.AutoButtonColor = false
    Button.BorderSizePixel = 0
    Button.Image = "rbxassetid://130835920424032"
    Button.ImageTransparency = 0
    Button.ScaleType = Enum.ScaleType.Fit
    Button.Parent = Gui
    
    -- Rounded corners
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(1, 0)
    Corner.Parent = Button
    
    -- Border
    local Stroke = Instance.new("UIStroke")
    Stroke.Thickness = 1.6
    Stroke.Color = Color3.fromRGB(48, 255, 106) -- UQiLL green
    Stroke.Transparency = 0.1
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Stroke.Parent = Button
    
    -- Glow effect
    local Glow = Instance.new("UIStroke")
    Glow.Thickness = 4
    Glow.Color = Color3.fromRGB(48, 255, 106)
    Glow.Transparency = 0.8
    Glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Glow.Parent = Button
    
    -- Tooltip
    local Tooltip = Instance.new("TextLabel")
    Tooltip.Name = "Tooltip"
    Tooltip.Text = "Toggle UI (H)"
    Tooltip.Size = UDim2.fromOffset(80, 24)
    Tooltip.Position = UDim2.new(0, 60, 0.5, -12)
    Tooltip.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Tooltip.BackgroundTransparency = 0.2
    Tooltip.TextColor3 = Color3.fromRGB(255, 255, 255)
    Tooltip.Font = Enum.Font.Gotham
    Tooltip.TextSize = 11
    Tooltip.Visible = false
    Tooltip.Parent = Button
    
    Instance.new("UICorner", Tooltip).CornerRadius = UDim.new(0, 4)
    
    -- Toggle logic
    local visible = true
    
    Button.MouseButton1Click:Connect(function()
        visible = not visible
        if Window and Window.Toggle then
            pcall(function() Window:Toggle(visible) end)
        end
    end)
    
    -- Tooltip hover
    Button.MouseEnter:Connect(function()
        Tooltip.Visible = true
    end)
    
    Button.MouseLeave:Connect(function()
        Tooltip.Visible = false
    end)
    
    -- Enhanced drag system
    local dragging = false
    local dragOffset = Vector2.zero
    
    local function ClampToScreen(pos)
        local cam = workspace.CurrentCamera
        if not cam then return pos end
        
        local viewport = cam.ViewportSize
        local size = Button.AbsoluteSize
        
        return Vector2.new(
            math.clamp(pos.X, 0, viewport.X - size.X),
            math.clamp(pos.Y, 0, viewport.Y - size.Y)
        )
    end
    
    Button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            Tooltip.Visible = false
            
            local mousePos = UserInputService:GetMouseLocation()
            local btnPos = Button.AbsolutePosition
            dragOffset = mousePos - btnPos
        end
    end)
    
    Button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    RunService.RenderStepped:Connect(function()
        if dragging then
            local mousePos = UserInputService:GetMouseLocation()
            local targetPos = mousePos - dragOffset
            local clamped = ClampToScreen(targetPos)
            
            Button.Position = UDim2.fromOffset(clamped.X, clamped.Y)
        end
    end)
end

-- =====================================================
-- 📑 TAB CREATION (WITH FALLBACK)
-- =====================================================
local TabPlayer, TabFishing, TabFavorite, TabSell, TabWeather, TabTeleport, TabWebHook, TabSettings

if Window then
    TabPlayer = Window:Tab({ Title = "Player", Icon = "user" })
    TabFishing = Window:Tab({ Title = "Auto Fishing", Icon = "fish" })
    TabFavorite = Window:Tab({ Title = "Auto Favorite", Icon = "star" })
    TabSell = Window:Tab({ Title = "Auto Sell", Icon = "shopping-bag" })
    TabWeather = Window:Tab({ Title = "Weather", Icon = "cloud-lightning" })
    TabTeleport = Window:Tab({ Title = "Teleport", Icon = "map-pin" })
    TabWebHook = Window:Tab({ Title = "Webhook", Icon = "webhook" })
    TabSettings = Window:Tab({ Title = "Settings", Icon = "settings" })
else
    -- Create dummy tabs for fallback
    TabPlayer = { Section = function() return {
        Input = function() end,
        Toggle = function() end,
        Button = function() end,
        Dropdown = function() end,
        Paragraph = function() end
    } end }
    
    TabFishing = TabPlayer
    TabFavorite = TabPlayer
    TabSell = TabPlayer
    TabWeather = TabPlayer
    TabTeleport = TabPlayer
    TabWebHook = TabPlayer
    TabSettings = TabPlayer
end

-- =====================================================
-- 🎮 TAB 1: PLAYER SETTINGS
-- =====================================================
do
    local sectionHideName = TabPlayer:Section({ Title = "Hide Name", Opened = false})
    
    sectionHideName:Input({
        Title = "Fake Player Name",
        Desc = "Visual only (level safe)",
        Placeholder = "Input fake name",
        Callback = function(text)
            NameSpoof.FakeName = tostring(text):gsub("^%s+", ""):gsub("%s+$", "")
        end
    })
    
    sectionHideName:Toggle({
        Title = "Spoof Player Name",
        Desc = "Only name, level untouched",
        Icon = "user-check",
        Value = false,
        Callback = function(state)
            if state then
                EnableNameSpoof()
                WindUI:Notify({ Title = "Name Spoof", Content = "Enabled", Duration = 2 })
            else
                DisableNameSpoof()
                WindUI:Notify({ Title = "Name Spoof", Content = "Restored", Duration = 2 })
            end
        end
    })
    
    local sectionPlayerFeature = TabPlayer:Section({ Title = "Movement", Opened = false})
    
    sectionPlayerFeature:Toggle({ 
        Title = "Walk on Water", 
        Desc = "Creates a platform below you", 
        Icon = "waves", 
        Value = false, 
        Callback = function(state) 
            ToggleWaterWalk(state)
            WindUI:Notify({
                Title = "Movement", 
                Content = state and "Water Walk ON" or "Water Walk OFF", 
                Duration = 2
            }) 
        end 
    })
    
    sectionPlayerFeature:Toggle({ 
        Title = "Disable Animation", 
        Desc = "Stop character anims (T-Pose)", 
        Icon = "user-x", 
        Value = false, 
        Callback = function(state) 
            ToggleAnims(state)
            WindUI:Notify({
                Title = "Player", 
                Content = state and "Animations Disabled" or "Animations Enabled", 
                Duration = 2
            }) 
        end 
    })
    
    local sectionPlayerEquipment = TabPlayer:Section({ Title = "Equipment", Opened = false})
    
    sectionPlayerEquipment:Toggle({ 
        Title = "Equip Diving Gear", 
        Desc = "Toggle Oxygen Tank", 
        Icon = "anchor", 
        Value = false, 
        Callback = function(state) 
            if state then 
                pcall(function() 
                    EquipTank:InvokeServer(105) 
                end)
                WindUI:Notify({
                    Title = "Item", 
                    Content = "Diving Gear Equipped", 
                    Duration = 2
                }) 
            else 
                -- Unequip
                local Char = Players.LocalPlayer.Character
                local Backpack = Players.LocalPlayer.Backpack
                if Char then
                    for _, t in pairs(Char:GetChildren()) do
                        if t:IsA("Tool") and (string.find(t.Name, "Oxygen") or string.find(t.Name, "Tank")) then
                            t.Parent = Backpack
                        end
                    end
                end
                WindUI:Notify({
                    Title = "Item", 
                    Content = "Diving Gear Unequipped", 
                    Duration = 2
                }) 
            end 
        end 
    })
    
    sectionPlayerEquipment:Toggle({ 
        Title = "Equip Radar", 
        Desc = "Toggle Fishing Radar", 
        Icon = "radar", 
        Value = false, 
        Callback = function(state) 
            pcall(function() 
                UpdateRadar:InvokeServer(state) 
            end)
            WindUI:Notify({
                Title = "Item", 
                Content = state and "Radar ON" or "Radar OFF", 
                Duration = 2
            }) 
        end 
    })
end

-- =====================================================
-- 🎣 TAB 2: AUTO FISHING
-- =====================================================
do
    TabFishing:Section({ Title = "Mode Selection" })
    
    TabFishing:Dropdown({
        Title = "Fishing Mode",
        Desc = "Select fishing method",
        Values = {"Instant", "Blatan"},
        Value = "Instant",
        Callback = function(option)
            instant = (option == "Instant")
            superInstant = (option == "Blatan")
            
            -- Show/hide relevant settings
            setElementVisible("Delay Fishing", false)
            setElementVisible("Delay Catch", false)
            setElementVisible("Reset Delay", false)
            
            if instant then
                setElementVisible("Delay Catch", true)
            elseif superInstant then
                setElementVisible("Delay Fishing", true)
                setElementVisible("Reset Delay", true)
            end
        end
    })
    
    TabFishing:Section({ Title = "Timing Settings" })
    
    TabFishing:Input({
        Title = "Delay Fishing",
        Value = "1.30",
        Desc = "Charge delay (Blatan mode)",
        Callback = function(text)
            if not text:match("^%d*%.?%d+$") then
                delayCharge = 1.30
                return "1.30"
            end
            
            local num = tonumber(text)
            if not num or num < 0.1 or num > 3 then
                WindUI:Notify({
                    Title = "Invalid",
                    Content = "Delay must be between 0.1 and 3",
                    Duration = 2
                })
                delayCharge = 1.30
                return "1.30"
            end
            
            delayCharge = num
            return tostring(delayCharge)
        end
    })
    
    TabFishing:Input({
        Title = "Reset Delay",
        Value = "0.35",
        Desc = "Reset delay (Blatan mode)",
        Callback = function(text)
            if not text:match("^%d*%.?%d+$") then
                delayReset = 0.35
                return "0.35"
            end
            
            local num = tonumber(text)
            if not num or num < 0.1 or num > 2 then
                WindUI:Notify({
                    Title = "Invalid",
                    Content = "Delay must be between 0.1 and 2",
                    Duration = 2
                })
                delayReset = 0.35
                return "0.35"
            end
            
            delayReset = num
            return tostring(delayReset)
        end
    })
    
    TabFishing:Input({
        Title = "Delay Catch",
        Value = "1.05",
        Desc = "Catch delay (Instant mode)",
        Callback = function(text)
            if not text:match("^%d*%.?%d+$") then
                delayTime = 1.05
                return "1.05"
            end
            
            local num = tonumber(text)
            if not num or num < 0.1 or num > 3 then
                WindUI:Notify({
                    Title = "Invalid",
                    Content = "Delay must be between 0.1 and 3",
                    Duration = 2
                })
                delayTime = 1.05
                return "1.05"
            end
            
            delayTime = num
            return tostring(delayTime)
        end
    })
    
    TabFishing:Toggle({
        Title = "Auto Great",
        Desc = "Activate before fishing",
        Icon = "check",
        Value = false,
        Callback = function(state)
            FishingBlocker.AutoGreat = state
            WindUI:Notify({
                Title = "Auto Great",
                Content = state and "Enabled" or "Disabled",
                Duration = 2
            })
        end
    })
    
    TabFishing:Section({ Title = "Fishing Control" })
    
    local fishingToggle = TabFishing:Toggle({
        Title = "Activate Fishing",
        Icon = "power",
        Value = false,
        Callback = function(state)
            if fishingDebounce then
                WindUI:Notify({
                    Title = "Wait",
                    Content = "Please wait...",
                    Duration = 1
                })
                return
            end
            
            getgenv().fishingStart = state
            FishingBlocker.Enabled = state
            
            if state then
                -- Start fishing
                pcall(function()
                    CancelInput:InvokeServer()
                end)
                
                if superInstant then
                    task.spawn(StartFishingSuperInstantLoop)
                else
                    task.spawn(StartFishingLoop)
                end
                
                WindUI:Notify({
                    Title = "Fishing", 
                    Content = "Started!", 
                    Duration = 2
                })
            else
                -- Stop fishing
                if FishingBlocker.AutoGreat then
                    pcall(function()
                        local state = { false }
                        GetRemote("RF/UpdateAutoFishingState"):InvokeServer(unpack(state))
                    end)
                end
                
                pcall(function()
                    CompleteGame:FireServer()
                end)
                
                pcall(function()
                    CancelInput:InvokeServer()
                end)
                
                WindUI:Notify({
                    Title = "Fishing", 
                    Content = "Stopped", 
                    Duration = 2
                })
            end
        end
    })
    
    TabFishing:Button({
        Title = "Emergency Stop",
        Icon = "octagon-alert",
        Callback = function()
            getgenv().fishingStart = false
            FishingBlocker.Enabled = false
            
            if fishingToggle then
                fishingToggle:Set(false)
            end
            
            pcall(function()
                CompleteGame:FireServer()
                CancelInput:InvokeServer()
            end)
            
            WindUI:Notify({
                Title = "Emergency",
                Content = "Fishing stopped immediately",
                Duration = 3
            })
        end
    })
    
    TabFishing:Button({
        Title = "Unstuck",
        Icon = "person-standing",
        Callback = function()
            local success = ResetCharacter()
            WindUI:Notify({
                Title = "Unstuck",
                Content = success and "Character reset" or "Reset failed",
                Duration = 2
            })
        end
    })
end

-- =====================================================
-- 💰 TAB 3: AUTO SELL
-- =====================================================
do
    TabSell:Toggle({ 
        Title = "Auto Sell (Timer)", 
        Desc = "Sell automatically at intervals", 
        Icon = "timer", 
        Value = false, 
        Callback = function(state) 
            SettingsState.AutoSell.TimeActive = state
            
            if state then
                StartAutoSellLoop()
                WindUI:Notify({
                    Title = "Auto Sell", 
                    Content = "Loop started", 
                    Duration = 2
                })
            else
                SettingsState.AutoSell.IsSelling = false
                WindUI:Notify({
                    Title = "Auto Sell", 
                    Content = "Loop stopped", 
                    Duration = 2
                })
            end
        end 
    })
    
    TabSell:Input({
        Title = "Sell Interval (Seconds)",
        Desc = "Time between automatic sells",
        Value = "600",
        Callback = function(text)
            if not text:match("^%d+$") then
                SettingsState.AutoSell.TimeInterval = 600
                WindUI:Notify({
                    Title = "Invalid",
                    Content = "Must be a number",
                    Duration = 2
                })
                return "600"
            end
            
            local num = tonumber(text)
            if not num or num < 10 or num > 3600 then
                SettingsState.AutoSell.TimeInterval = 600
                WindUI:Notify({
                    Title = "Invalid",
                    Content = "Must be between 10-3600 seconds",
                    Duration = 2
                })
                return "600"
            end
            
            SettingsState.AutoSell.TimeInterval = num
            return tostring(num)
        end
    })
    
    TabSell:Button({ 
        Title = "Sell Now", 
        Desc = "Sell all items immediately", 
        Icon = "trash-2", 
        Callback = function() 
            task.spawn(function()
                local success = SellNow()
                WindUI:Notify({
                    Title = "Sell All", 
                    Content = success and "Sold!" or "Sell failed", 
                    Duration = 2
                })
            end)
        end 
    })
end

-- =====================================================
-- ⛅ TAB 4: WEATHER
-- =====================================================
do
    TabWeather:Dropdown({ 
        Title = "Select Weather(s)", 
        Desc = "Choose weathers to maintain", 
        Values = {"Wind", "Cloudy", "Snow", "Storm", "Radiant"}, 
        Value = {}, 
        Multi = true, 
        AllowNone = true, 
        Callback = function(option) 
            SettingsState.AutoWeather.SelectedList = option
            WindUI:Notify({
                Title = "Weather",
                Content = #option .. " weather(s) selected",
                Duration = 2
            })
        end 
    })
    
    TabWeather:Toggle({ 
        Title = "Smart Monitor", 
        Desc = "Automatically maintain selected weathers", 
        Icon = "cloud-lightning", 
        Value = false, 
        Callback = function(state) 
            SettingsState.AutoWeather.Active = state
            
            if state then
                StartAutoWeather()
                WindUI:Notify({
                    Title = "Weather", 
                    Content = "Monitor started", 
                    Duration = 2
                })
            else
                StopAutoWeather()
                WindUI:Notify({
                    Title = "Weather", 
                    Content = "Monitor stopped", 
                    Duration = 2
                })
            end
        end 
    })
end

-- =====================================================
-- 🗺️ TAB 5: TELEPORT
-- =====================================================
do
    local sectionEventLimited = TabTeleport:Section({ Title = "Auto Event", Opened = false })
    
    local sectionTPIsland = TabTeleport:Section({ Title = "Islands" })
    
    -- Get zone names
    local zoneNames = {}
    for name, _ in pairs(Waypoints) do 
        table.insert(zoneNames, name) 
    end
    table.sort(zoneNames)
    
    local selectedZone = zoneNames[1] or "Fisherman Island"
    
    local TP_Dropdown = sectionTPIsland:Dropdown({ 
        Title = "Select Island", 
        Values = zoneNames, 
        Value = selectedZone,
        Callback = function(val) 
            selectedZone = val 
        end 
    })
    
    sectionTPIsland:Button({ 
        Title = "Teleport to Island", 
        Icon = "navigation", 
        Callback = function() 
            if selectedZone and Waypoints[selectedZone] then
                local success = TeleportTo(Waypoints[selectedZone])
                WindUI:Notify({
                    Title = "Teleport",
                    Content = success and "Teleported to " .. selectedZone or "Teleport failed",
                    Duration = 2
                })
            else
                WindUI:Notify({
                    Title = "Error", 
                    Content = "Coordinates missing", 
                    Duration = 2
                })
            end
        end 
    })
    
    sectionTPIsland:Button({ 
        Title = "Refresh List", 
        Icon = "refresh-cw", 
        Callback = function() 
            WindUI:Notify({
                Title = "System", 
                Content = "Waypoint list reloaded", 
                Duration = 1
            }) 
        end 
    })
    
    local sectionTPPlayer = TabTeleport:Section({ Title = "Player Teleport" })
    
    local targetPlayerName = ""
    local playerNames = GetPlayerList()
    local PlayerDropdown = sectionTPPlayer:Dropdown({ 
        Title = "Select Player", 
        Values = playerNames, 
        Value = playerNames[1] or "None", 
        Callback = function(val) 
            targetPlayerName = val 
        end 
    })
    
    sectionTPPlayer:Button({ 
        Title = "Teleport to Player", 
        Icon = "user", 
        Callback = function() 
            local target = FindPlayer(targetPlayerName)
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                local success = TeleportTo(target.Character.HumanoidRootPart.Position + Vector3.new(3, 0, 0))
                WindUI:Notify({
                    Title = "Teleport", 
                    Content = success and "Warped to " .. target.Name or "Teleport failed", 
                    Duration = 2
                })
            else
                WindUI:Notify({
                    Title = "Error", 
                    Content = "Player not found!", 
                    Duration = 2
                })
            end
        end 
    })
    
    sectionTPPlayer:Button({ 
        Title = "Refresh Players", 
        Desc = "Update player list", 
        Icon = "refresh-cw", 
        Callback = function() 
            local newPlayers = GetPlayerList()
            PlayerDropdown:Refresh(newPlayers, newPlayers[1] or "None")
            WindUI:Notify({
                Title = "System", 
                Content = "Player list updated!", 
                Duration = 2
            }) 
        end 
    })
    
    local sectionCoordinateTools = TabTeleport:Section({ Title = "Coordinate Tools" })
    
    LivePosToggle = sectionCoordinateTools:Toggle({ 
        Title = "Show Live Position", 
        Desc = "Display real-time coordinates", 
        Icon = "monitor", 
        Value = false, 
        Callback = function(state) 
            TogglePosWatcher(state)
        end 
    })
    
    sectionCoordinateTools:Button({ 
        Title = "Copy Position", 
        Desc = "Copy 'Vector3.new(...)' to clipboard", 
        Icon = "copy", 
        Callback = function() 
            local Char = LocalPlayer.Character
            if Char and Char:FindFirstChild("HumanoidRootPart") then
                local pos = Char.HumanoidRootPart.Position
                local str = string.format("Vector3.new(%.0f, %.0f, %.0f)", pos.X, pos.Y, pos.Z)
                
                if setclipboard then
                    setclipboard(str)
                    WindUI:Notify({
                        Title = "Copied!", 
                        Content = "Position saved to clipboard", 
                        Duration = 2
                    })
                else
                    print("📍 COPIED: " .. str)
                    WindUI:Notify({
                        Title = "Position", 
                        Content = "Check F9 console", 
                        Duration = 2
                    })
                end
            end
        end 
    })
end

-- =====================================================
-- ⚙️ TAB 6: SETTINGS
-- =====================================================
do
    local sectionServer = TabSettings:Section({ Title = "Server" })
    
    sectionServer:Button({ 
        Title = "Server Hop (Low Player)", 
        Desc = "Find server with more space", 
        Icon = "server", 
        Callback = function() 
            WindUI:Notify({
                Title = "Server Hop", 
                Content = "Searching for low-pop server...", 
                Duration = 3
            })
            
            task.spawn(function()
                local Http = game:GetService("HttpService")
                local TPS = game:GetService("TeleportService")
                local PlaceId = game.PlaceId
                local Api = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
                
                local function ListServers(cursor)
                    local Raw = game:HttpGet(Api .. ((cursor and "&cursor="..cursor) or ""))
                    return Http:JSONDecode(Raw)
                end
                
                local Server, Next
                repeat
                    local Servers = ListServers(Next)
                    Server = Servers.data[1]
                    Next = Servers.nextPageCursor
                until Server
                
                TPS:TeleportToPlaceInstance(PlaceId, Server.id, LocalPlayer)
            end)
        end 
    })
    
    sectionServer:Button({
        Title = "Rejoin Game",
        Desc = "Rejoin & auto-execute script",
        Icon = "rotate-cw",
        Callback = function()
            local ts = game:GetService("TeleportService")
            
            WindUI:Notify({
                Title = "System", 
                Content = "Rejoining...", 
                Duration = 3
            })
            
            -- Queue script for rejoin
            local myScript = [[
                task.wait(3)
                loadstring(game:HttpGet("https://raw.githubusercontent.com/syauqiaditia/roblox-uqill-fishit/main/uqill.lua"))()
            ]]
            
            if (syn and syn.queue_on_teleport) then
                syn.queue_on_teleport(myScript)
            elseif queue_on_teleport then
                queue_on_teleport(myScript)
            end
            
            ts:Teleport(game.PlaceId, LocalPlayer)
        end
    })
    
    local sectionOptimization = TabSettings:Section({ Title = "Optimization" })
    
    sectionOptimization:Button({
        Title = "Anti-AFK",
        Desc = "Prevent being kicked for AFK",
        Icon = "clock",
        Callback = function()
            StartAntiAFK()
            WindUI:Notify({
                Title = "Anti-AFK", 
                Content = "Activated", 
                Duration = 2
            })
        end
    })
    
    sectionOptimization:Button({
        Title = "Destroy Fish Popup",
        Desc = "Remove 'Small Notification' UI",
        Icon = "trash-2",
        Callback = function()
            if SettingsState.PopupDestroyed then
                WindUI:Notify({
                    Title = "UI", 
                    Content = "Already destroyed!", 
                    Duration = 2
                })
                return
            end
            
            SettingsState.PopupDestroyed = true
            ExecuteDestroyPopup()
            WindUI:Notify({
                Title = "UI", 
                Content = "Popup destroyed!", 
                Duration = 3
            })
        end
    })
    
    sectionOptimization:Toggle({
        Title = "FPS Boost (Potato)",
        Desc = "Reduce graphics for better FPS",
        Icon = "monitor",
        Value = false,
        Callback = function(state)
            ToggleFPSBoost(state)
            WindUI:Notify({
                Title = "FPS Boost", 
                Content = state and "Enabled" or "Disabled", 
                Duration = 2
            })
        end
    })
    
    sectionOptimization:Toggle({
        Title = "Remove VFX",
        Desc = "Disable visual effects",
        Icon = "trash",
        Value = false,
        Callback = function(state)
            if state then
                EnableVFXRemoval()
                WindUI:Notify({
                    Title = "VFX", 
                    Content = "Removal activated", 
                    Duration = 2
                })
            else
                DisableVFXRemoval()
                WindUI:Notify({
                    Title = "VFX", 
                    Content = "Restored", 
                    Duration = 2
                })
            end
        end
    })
    
    sectionOptimization:Toggle({
        Title = "No 3D Rendering",
        Desc = "Extreme FPS boost (executor only)",
        Icon = "eye-off",
        Value = false,
        Callback = function(state)
            if not NoRender3D.Supported then
                WindUI:Notify({
                    Title = "Not Supported",
                    Content = "Executor tidak mendukung",
                    Duration = 3
                })
                return
            end

            if state then
                NoRender3D:Enable()
                WindUI:Notify({
                    Title = "Performance",
                    Content = "3D Rendering Disabled",
                    Duration = 2
                })
            else
                NoRender3D:Disable()
                WindUI:Notify({
                    Title = "Performance",
                    Content = "3D Rendering Restored",
                    Duration = 2
                })
            end
        end
    })
    
    local sectionMonitoring = TabSettings:Section({ Title = "Monitoring" })
    
    sectionMonitoring:Toggle({
        Title = "Performance HUD",
        Desc = "FPS / Ping / Memory display",
        Icon = "monitor",
        Value = false,
        Callback = function(state)
            TogglePerformanceHUD(state)
            WindUI:Notify({
                Title = "Performance HUD", 
                Content = state and "Enabled" or "Disabled", 
                Duration = 2
            })
        end
    })
    
    local sectionMisc = TabSettings:Section({ Title = "Miscellaneous" })
    
    sectionMisc:Toggle({
        Title = "Show Quest List",
        Icon = "list",
        Value = true,
        Callback = function(state)
            local success = SetQuestListVisible(state)
            WindUI:Notify({
                Title = "Quest UI",
                Content = success and (state and "Quest List Shown" or "Quest List Hidden") or "Quest UI not found",
                Duration = 2
            })
        end
    })
    
    sectionMisc:Button({
        Title = "Script Info",
        Icon = "info",
        Callback = function()
            local info = string.format([[
Version: %s
Author: %s
Optimized by: %s
Features: %s
Loaded: %s
            ]], 
            SCRIPT_INFO.Version,
            SCRIPT_INFO.Author,
            SCRIPT_INFO.OptimizedBy,
            SCRIPT_INFO.Features,
            SCRIPT_INFO.LastUpdate)
            
            WindUI:Notify({
                Title = "Script Information",
                Content = info,
                Duration = 5
            })
        end
    })
end

-- =====================================================
-- ⭐ TAB 7: AUTO FAVORITE - FIXED VERSION
-- =====================================================
do
    local RarityList = {
        "Common", "Uncommon", "Rare", "Epic", 
        "Legendary", "Mythic", "Secret"
    }
    
    TabFavorite:Dropdown({
        Title = "Select Rarity to Favorite",
        Desc = "Choose which rarities to auto-favorite",
        Values = RarityList,
        Value = {},
        Multi = true,
        AllowNone = true,
        Callback = function(list)
            if _G.SetSelectedRarities then
                _G.SetSelectedRarities(list)
            end
            WindUI:Notify({
                Title = "Auto Favorite",
                Content = #list .. " rarity(ies) selected",
                Duration = 2
            })
        end
    })
    
    TabFavorite:Toggle({
        Title = "Activate Auto Favorite",
        Desc = "Automatically favorite selected rarities",
        Icon = "star",
        Value = false,
        Callback = function(state)
            SettingsState.AutoFavorite.Active = state
            if _G.ToggleAutoFavorite then
                _G.ToggleAutoFavorite(state)
            end
            
            WindUI:Notify({
                Title = "Auto Favorite", 
                Content = state and "Running..." or "Stopped", 
                Duration = 2
            })
        end
    })
end

-- =====================================================
-- 🌐 TAB 8: WEBHOOK
-- =====================================================
do
    TabWebHook:Section({ Title = "Webhook Configuration" })
    
    local WebhookInputBuffer = ""
    
    TabWebHook:Input({
        Title = "Discord Webhook URL",
        Desc = "Paste your Discord webhook URL",
        Placeholder = "https://discord.com/api/webhooks/...",
        Callback = function(text)
            WebhookInputBuffer = tostring(text)
            return text
        end
    })
    
    TabWebHook:Button({
        Title = "Save Webhook URL",
        Icon = "save",
        Callback = function()
            local url = WebhookInputBuffer:gsub("%s+", "")
            
            if not url:match("^https://discord%.com/api/webhooks/") then
                WindUI:Notify({
                    Title = "Webhook",
                    Content = "Invalid webhook URL format",
                    Duration = 3
                })
                return
            end
            
            SettingsState.WebhookFish.Url = url
            
            WindUI:Notify({
                Title = "Webhook",
                Content = "Webhook URL saved",
                Duration = 2
            })
            
            print("[WEBHOOK] URL saved")
        end
    })
    
    TabWebHook:Section({ Title = "Rarity Filter" })
    
    local RarityList = {
        "Common", "Uncommon", "Rare", "Epic", 
        "Legendary", "Mythic", "Secret"
    }
    
    TabWebHook:Dropdown({
        Title = "Webhook Rarity Filter",
        Desc = "Select which rarities to send to webhook",
        Values = RarityList,
        Multi = true,
        AllowNone = true,
        Callback = function(selectedList)
            SettingsState.WebhookFish.SelectedRarities = {}
            
            for _, rarity in ipairs(selectedList) do
                local tier = RARITY_NAME_TO_TIER[rarity]
                if tier then
                    SettingsState.WebhookFish.SelectedRarities[tier] = true
                end
            end
            
            local count = #selectedList
            WindUI:Notify({
                Title = "Webhook Filter",
                Content = count == 0 and "All rarities enabled" or count .. " rarity(ies) selected",
                Duration = 2
            })
        end
    })
    
    TabWebHook:Toggle({
        Title = "Fish Webhook Logger",
        Desc = "Enable fish webhook notifications",
        Value = false,
        Callback = function(state)
            if state then
                StartFishWebhook()
            else
                StopFishWebhook()
            end
        end
    })
end

-- =====================================================
-- 🚀 INITIALIZATION
-- =====================================================
-- Initialize UI visibility
task.delay(1, function()
    if instant then 
        setElementVisible("Delay Catch", true)
    elseif superInstant then 
        setElementVisible("Delay Fishing", true)
        setElementVisible("Reset Delay", true) 
    end
end)

-- Start Anti-AFK
task.spawn(StartAntiAFK)

-- Final initialization message
print("\n" .. string.rep("=", 50))
print("UQiLL Fishing Suite v4.0 FINAL")
print("Optimized by jpXCode")
print("Successfully loaded!")
print(string.rep("=", 50) .. "\n")

WindUI:Notify({
    Title = "UQiLL Fishing Suite",
    Content = string.format("v4.0 FINAL loaded!\nOptimized by jpXCode\nPress H to toggle UI"),
    Duration = 5
})

-- Emergency cleanup on script termination
game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        -- Clean up created objects
        if SettingsState.WaterWalk.Part then
            SettingsState.WaterWalk.Part:Destroy()
        end
        
        -- Stop all loops
        getgenv().fishingStart = false
        SettingsState.AutoSell.TimeActive = false
        SettingsState.AutoWeather.Active = false
        SettingsState.AutoFavorite.Active = false
        SettingsState.WebhookFish.Active = false
        
        print("[CLEANUP] Script terminated, resources cleaned up")
    end
end)
