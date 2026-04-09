-- For clearing up underline spam in Visual Studio Code
-- local getgenv, Iris, ESP, BetterLib, Get, FormatSemVer, makefolder, CEHGF, EXECUTOR_FILING_FUNCTIONS, EXECUTOR_FILING_ENABLED, FormatHours, CountList, deepCopy, ConfigLibrary, CancelLerpTeleport, LerpTeleport, Lerp, GetDurationFromDistance, writefile, isfile, readfile, listfiles

local SCRIPT_NAME = "EmdenHub"
local SCRIPT_VERSION = {
    -- Semantic Versioning
    Major = 1;
    Minor = 1;
    Patch = 7;
}

local genv = getgenv()

if not BetterLib then
    local OldGet = game.HttpGet or game.HttpGetAsync or nil
    assert(OldGet, "No HttpGet function found.")
    -- Load BetterLib first (if it's not already loaded), since every other loaded stuff will depend on it. If BetterLib fails to load, everything else won't work, but at least the error will be more informative.
    loadstring(OldGet(game, "https://raw.githubusercontent.com/CatOnEdge/BetterLib/refs/heads/main/main.lua", true))()
end
-- Begin Script:

-- Load Dependencies:

if not Iris then
    local IrisLoaderUrl = "https://raw.githubusercontent.com/CatOnEdge/Iris/refs/heads/main/loader.lua"
    genv.Iris = loadstring(Get(IrisLoaderUrl))()
end

if not ESP then
    local ESPLibUrl = "https://raw.githubusercontent.com/CatOnEdge/ESPLib/refs/heads/main/main.lua"
    genv.ESP = loadstring(Get(ESPLibUrl))()
end

-- Loaded Dependencies!

-- Generic Helpers
function genv.Lerp(a: Vector3, b: Vector3, t: number): Vector3
    return a + (b - a) * t
end

function genv.GetDurationFromDistance(distance: number, maxSpeed: number): number
    if maxSpeed <= 0 then
        return 0
    end

    return distance / maxSpeed
end

function genv.FormatHours(seconds: number): string
    seconds = math.max(0, math.floor(seconds)) -- clamp + remove decimals

    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60

    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

function genv.FormatMinutes(seconds: number): string
    seconds = math.max(0, math.floor(seconds))
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", minutes, secs)
end

function genv.FormatSemVer(versionTable: { Major: number?, Minor: number?, Patch: number? }): string
    assert(type(versionTable) == "table", "FormatSemVer expects a table")

    local major = versionTable.Major or 0
    local minor = versionTable.Minor or 0
    local patch = versionTable.Patch or 0

    return string.format("%d.%d.%d", major, minor, patch)
end
local ver = FormatSemVer(SCRIPT_VERSION)

local Emden_GameId = 4457060041
if game.GameId ~= Emden_GameId then
    warn("[EXECUTOR ERROR]: Script: "..SCRIPT_NAME.." v:"..ver.." failed to load because you're not playing Emden.")
    return
end

-- Setup executor workspace file directory for saving configs and settings:

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local SCRIPT_DIRECTORY_PATH = nil
local CONFIG_DIRECTORY_PATH = nil
if EXECUTOR_FILING_ENABLED then
    SCRIPT_DIRECTORY_PATH = SCRIPT_NAME .. "_" .. ver
    makefolder(SCRIPT_DIRECTORY_PATH)
    CONFIG_DIRECTORY_PATH = SCRIPT_DIRECTORY_PATH .. "/Configs"
    makefolder(CONFIG_DIRECTORY_PATH)
end

-- Done setting up file directory!

HEALTH_DISPLAY_TYPES = {
    None = "None";
    ["Vertical Bar"] = "Vertical Bar";
    ["Horizontal Bar"] = "Horizontal Bar";
    Text = "Text";
}
SELECTABLE_HEALTH_DISPLAY_TYPES = {
    [1] = HEALTH_DISPLAY_TYPES.None;
    [2] = HEALTH_DISPLAY_TYPES["Vertical Bar"];
    [3] = HEALTH_DISPLAY_TYPES["Horizontal Bar"];
    [4] = HEALTH_DISPLAY_TYPES.Text;
}

ESP_TYPES = {
    ["Box"] = "Box";
    ["Quad"] = "Quad";
    ["Rect"] = "Rect";
}
SELECTABLE_ESP_TYPES = {
    [1] = ESP_TYPES.Box;
    [2] = ESP_TYPES.Quad;
    [3] = ESP_TYPES.Rect;
}

TRACER_ORIGINS = ESP.TRACER_ORIGINS or {
    Mouse = "Mouse";
    Bottom = "Bottom";
    Top = "Top";
    Center = "Center";
}
SELECTABLE_TRACER_ORIGINS = ESP.SELECTABLE_TRACER_ORIGINS or {
    [1] = TRACER_ORIGINS.Mouse;
    [2] = TRACER_ORIGINS.Bottom;
    [3] = TRACER_ORIGINS.Top;
    [4] = TRACER_ORIGINS.Center;
}

TRACER_TARGETS = ESP.TRACER_TARGETS or {
    Center = "Center";
    Top = "Top";
    Bottom = "Bottom";
}
SELECTABLE_TRACER_TARGETS = ESP.SELECTABLE_TRACER_TARGETS or {
    [1] = TRACER_TARGETS.Center;
    [2] = TRACER_TARGETS.Top;
    [3] = TRACER_TARGETS.Bottom;
}

-- External States
local initESPType = table.find(SELECTABLE_ESP_TYPES, ESP_TYPES.Box)
local initTracerOrigin = table.find(SELECTABLE_TRACER_ORIGINS, TRACER_ORIGINS.Center)
local initTracerTarget = table.find(SELECTABLE_TRACER_TARGETS, TRACER_TARGETS.Bottom)
local initHealthDisplayType = table.find(SELECTABLE_HEALTH_DISPLAY_TYPES, HEALTH_DISPLAY_TYPES["Vertical Bar"])

local Config = {}
genv.Config = Config

function getIrisStatesRecursively(IrisTable)
    local configTable = {}
    for index, value in pairs(IrisTable) do
        if type(value) == "table" and type(value.get) == "function" and type(value.set) == "function" then
            local got = value:get()
            if type(got) == "table" then
                local temp = deepCopy(got)
                temp.IS_IRIS_TABLE_STATE = true
                configTable[index] = temp
            else
                configTable[index] = got
            end
        elseif type(value) == "table" then
            configTable[index] = getIrisStatesRecursively(value)
        end
    end
    return configTable
end

local function SaveIrisConfig(path: string)
    if not EXECUTOR_FILING_ENABLED then
        warn("Cannot save config, executor does not support file functions.")
        return
    end

    local ConfigTable = getIrisStatesRecursively(Config)
    if not ConfigTable then
        warn("Failed to get config table.")
        return
    end
    local success, err = pcall(function()
        ConfigLibrary:SaveConfig(path, ConfigTable)
    end)
    if not success and err then
        warn("Error saving config: " .. tostring(err))
    end
end

function setIrisStatesRecursively(IrisTable, Overwrite)
    for index, ovalue in pairs(Overwrite) do
        if ovalue == nil then
            warn("What? This shouldn't be happening... Config value for " .. index .. " is nil, skipping this setting to avoid breaking it.")
            continue
        end
        if index == "IS_IRIS_TABLE_STATE" then
            continue
        end

        local value = IrisTable[index]
        if value == nil then
            -- State doesn't exist in current config, add it in so it doesn't get lost when saving/loading configs that don't have newer settings
            if type(ovalue) == "table" then
                local temp = deepCopy(ovalue)
                temp.IS_IRIS_TABLE_STATE = nil
                if ovalue.IS_IRIS_TABLE_STATE == true then
                    IrisTable[index] = Iris.State(temp)
                else
                    IrisTable[index] = {}
                    setIrisStatesRecursively(IrisTable[index], temp)
                end
            else
                IrisTable[index] = Iris.State(ovalue)
            end
        elseif type(value) == "table" then
            -- all states are tables, but not all tables are states, so we have to check if it is a state or just a regular table
            -- State exists in current config, just update the value so it gets saved in the config file. This also allows for loading older configs that don't have newer settings without breaking them by removing those settings, since it will just keep the current value for those settings instead of trying to set them to nil or something.

            if (type(value.get) == "function" and type(value.set) == "function") then
                -- is a state table, so we can just set the value
                local got = value:get()
                if got and type(got) == "table" then
                    local temp = deepCopy(ovalue)
                    temp.IS_IRIS_TABLE_STATE = nil
                    IrisTable[index]:set(temp)
                else
                    IrisTable[index]:set(ovalue)
                end
            else
                -- is table but not state, so we have to go deeper
                if type(ovalue) == "table" then
                    local temp = deepCopy(ovalue)
                    temp.IS_IRIS_TABLE_STATE = nil
                    if ovalue.IS_IRIS_TABLE_STATE == true then
                        IrisTable[index] = Iris.State(temp)
                    else
                        IrisTable[index] = {}
                        setIrisStatesRecursively(IrisTable[index], temp)
                    end
                else
                    warn("Config value for " .. index .. " is not a table, but the current config value is a table. Skipping this setting to avoid breaking it.")
                end
            end
        end
    end
    return true
end

local function LoadIrisConfig(path: string)
    if not EXECUTOR_FILING_ENABLED then
        warn("Cannot load config, executor does not support file functions.")
        return
    end

    local ConfigTable = nil
    local success, err = pcall(function()
        ConfigTable = ConfigLibrary:LoadConfig(path)
    end)
    if not success and err then
        warn("Error loading config: " .. tostring(err))
    elseif success then
        -- Apply loaded config to current state
        local applySuccess, applyErr = pcall(function()
            setIrisStatesRecursively(Config, ConfigTable)
        end)
        if not applySuccess and applyErr then
            warn("Error applying config: " .. tostring(applyErr))
        end
    end
end

local function isKeybindActive(keycodeName: string)
    local keycode = Enum.KeyCode[keycodeName]
    if not keycode then
        warn("Invalid keycode name: " .. keycodeName)
        return false
    end
    local thumbstickName = keycodeName:match("Thumbstick[12]")
    if thumbstickName then
        local prefixLength = string.len(thumbstickName)
        local dir = keycodeName:sub(prefixLength + 1)
        local input = UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1)

        for _, obj in ipairs(input) do
            if obj.KeyCode.Name == thumbstickName then
                local x, y = obj.Position.X, obj.Position.Y
                local deadzone = 0.4

                if dir == "Left" and x < -deadzone then
                    return true
                elseif dir == "Right" and x > deadzone then
                    return true
                elseif dir == "Up" and y > deadzone then
                    return true
                elseif dir == "Down" and y < -deadzone then
                    return true
                end
            end
        end
    else
        return UserInputService:IsKeyDown(keycode)
    end
    return false
end

local DefaultConfig = {
    ["showMainWindow"] = true;
    ["showBackground"] = false;
    ["backgroundColor"] = Color3.fromRGB(115, 140, 152);
    ["backgroundTransparency"] = 0;
    ["showRuntimeInfo"] = false;
    ["showStyleEditor"] = false;
    ["showDebugWindow"] = false;
    --Referring to Iris' GlobalConfig:
    ["IrisSizingConfig"] = {
        IS_IRIS_TABLE_STATE = true;
    };
    ["IrisColorsConfig"] = {
        IS_IRIS_TABLE_STATE = true;
    };
    ["IrisFontsConfig"] = {
        IS_IRIS_TABLE_STATE = true;
    };

    ["windowKeyCode"] = {
        IS_IRIS_TABLE_STATE = true;
        "F3"
    };

    ["antis"] = {
        IS_IRIS_TABLE_STATE = true;
        ["antiCuffEnabled"] = false;
        ["antiRagdollEnabled"] = false;
        ["antiTazerEnabled"] = false;
        ["antiHackBypassEnabled"] = false;
    };

    ["carDamageDisabled"] = false;
    ["vehicleNoclipEnabled"] = false;

    ["ghostriderEnabled"] = false;
    ["nitrousKeybind"] = { -- To-do (not even started yet)
        IS_IRIS_TABLE_STATE = true;
        "LeftShift";
    };
    ["airbrakeKeybind"] = { -- To-do (not even started yet)
        IS_IRIS_TABLE_STATE = true;
        "LeftControl";
    };
    ["nitrous"] = 100;
    ["airbrake"] = 0.005;  -- Range 0 to 1 (0.1 is slow stop, 0.9 is almost instant)

    ["rocketLeagueControls"] = {
        IS_IRIS_TABLE_STATE = true;
        ["airRollEnabled"] = false;
        ["airPitchEnabled"] = false;
        ["powerSlideEnabled"] = false;
    };
    ["airRollLeftKeybind"] = {
        IS_IRIS_TABLE_STATE = true;
        "R";
    };
    ["airRollRightKeybind"] = {
        IS_IRIS_TABLE_STATE = true;
        "T";
    };
    ["airPitchUpKeybind"] = {
        IS_IRIS_TABLE_STATE = true;
        "F";
    };
    ["airPitchDownKeybind"] = {
        IS_IRIS_TABLE_STATE = true;
        "V";
    };
    ["powerSlideLeftKeybind"] = {
        IS_IRIS_TABLE_STATE = true;
        "A";
    };
    ["powerSlideRightKeybind"] = {
        IS_IRIS_TABLE_STATE = true;
        "D";
    };
    ["airRollStrength"] = 50000; -- Degrees
    ["airPitchStrength"] = 50000; -- Degrees
    ["powerSlideStrength"] = 50000; -- Degrees

    ["ESP"] = {
        ["MasterMaxRenderDistance"] = 20000;
        ["MasterShapes"] = true;
        ["MasterText"] = true;
        ["MasterTracers"] = false;
        ["Categories"] = {
            ["Player"] = {
                ["MaxRenderDistance"] = 20000;
                ["Shapes"] = true;
                ["Text"] = true;
                ["Tracers"] = false;
                ["Color"] = Color3.new(1, 1, 1);
                ["Transparency"] = 0;
                ["ESPType"] = initESPType;
                ["TracerOrigin"] = initTracerOrigin;
                ["TracerTarget"] = initTracerTarget;

                ["MaxHealthDistance"] = 300;
                ["HealthDisplayType"] = initHealthDisplayType;
                ["DisplayHealthText"] = true;
            };
        };
    };
}

setIrisStatesRecursively(Config, DefaultConfig)

local SelectableCategories = {
    [1] = "None";
    [2] = "Player";
};
local SelectedCategory = Iris.State(1);

local function getMySeat(): Seat?
    local char = LocalPlayer.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    if not hum.SeatPart then return nil end
    return hum.SeatPart
end

local function getMyVehicleModel(): Model?
    local seat = getMySeat()
    if not seat then return nil end
    if seat then
        local current = seat
        local vehicleModel = current
        while current and current.Parent and current.Parent ~= game.Workspace do
            current = current.Parent
            if current:IsA("Model") then
                vehicleModel = current
            elseif current:IsA("Folder") then
                break
            end
        end
        return vehicleModel
    end
    return nil
end

local function setEntireVehicleVelocity(vehicleModel: Model, linearVelocity: Vector3?, angularVelocity: Vector3?): boolean
    if not vehicleModel then
        vehicleModel = getMyVehicleModel()
    end
    if not vehicleModel then
        return false
    end
    if not linearVelocity then linearVelocity = Vector3.zero end
    if not angularVelocity then angularVelocity = Vector3.zero end
    if vehicleModel.PrimaryPart then
        vehicleModel.PrimaryPart.AssemblyLinearVelocity = linearVelocity
        vehicleModel.PrimaryPart.AssemblyAngularVelocity = angularVelocity
    else
        for _, part in ipairs(vehicleModel:GetDescendants()) do
            if not part:IsA("BasePart") then continue end
            part.AssemblyLinearVelocity = linearVelocity
            part.AssemblyAngularVelocity = angularVelocity
        end
    end
    return true
end

local function moveVehicleTo(vehicleModel: Model, new: Vector3|CFrame): boolean
     if not vehicleModel then
        vehicleModel = getMyVehicleModel()
    end
    if not vehicleModel then
        return false
    end
    local currentCFrame = vehicleModel:GetPivot()
    local newCFrame = typeof(new) == "Vector3" and CFrame.new(new) * currentCFrame.Rotation or typeof(new) == "CFrame" and new or nil
    if not newCFrame then
        warn("Invalid new position or cframe for moveVehicleTo: " .. tostring(new))
        return false
    end
    vehicleModel:PivotTo(newCFrame)
    return true
end

-- Lerp TP
local CurrentTeleportingConnection = nil
local TargetPosition = nil
local Duration = nil
local Elapsed = nil
local Alpha = nil
local TeleportFinishedCallbacks = {}

function genv.CancelLerpTeleport()
    if CurrentTeleportingConnection then
        if CurrentTeleportingConnection.Connected then
            CurrentTeleportingConnection:Disconnect()
        end
        CurrentTeleportingConnection = nil
    end
    if TargetPosition then
        TargetPosition = nil
    end
end

function genv.LerpTeleport(target: Vector3, duration: number)
    CancelLerpTeleport()

    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChild("Head")
    if not root then return end

    local startPos = root.Position
    Duration = duration
    Elapsed = 0

    TargetPosition = target

    CurrentTeleportingConnection = RunService.Heartbeat:Connect(function(dt)
        char = LocalPlayer.Character
        if not char then
            CancelLerpTeleport()
            return
        end
        root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChild("Head")
        if not root then
            CancelLerpTeleport()
            return
        end

        Elapsed += dt
        Alpha = math.clamp(Elapsed / Duration, 0, 1)

        local vehicleModel = getMyVehicleModel()
        if vehicleModel then
            local newPos = Lerp(startPos, target, Alpha)
            moveVehicleTo(vehicleModel, newPos)
        else
            root.CFrame = CFrame.new(Lerp(startPos, target, Alpha))
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end

        if Alpha >= 1 then
            CancelLerpTeleport()
            for i, callback in pairs(TeleportFinishedCallbacks) do
                task.spawn(callback)
            end
        end
    end)
end

-- Dex++
local dexLoaded = Iris.State(false)
local DEX_URL = "https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua"
local RunDex = nil
RunDex = function()
    RunDex = nil
    loadstring(Get(DEX_URL))()
end
-- Hydroxide
local hydroxideLoaded = Iris.State(false)
local RunHydroxide = nil
RunHydroxide = function()
    RunHydroxide = nil
    local owner = "Upbolt"
    local branch = "revision"

    local function webImport(file)
        return loadstring(Get(("https://raw.githubusercontent.com/%s/Hydroxide/%s/%s.lua"):format(owner, branch, file)), file .. '.lua')()
    end

    webImport("init")
    webImport("ui/main")
end
-- Vehicle Fling
local vehicleFlingLoaded = Iris.State(false)
local RunVehicleFling = nil
RunVehicleFling = function()
    RunVehicleFling = nil
    -- ==========================================
    -- GUI SETUP
    -- ==========================================
    local screenGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
    screenGui.Name = "MassiveFlingGui"

    -- Invisible container to hold both Search Bar and the List
    local container = Instance.new("Frame", screenGui)
    container.Size = UDim2.new(0, 280, 0, 500) 
    container.Position = UDim2.new(0.05, 0, 0.2, 0)
    container.BackgroundTransparency = 1

    -- Search Bar
    local searchBar = Instance.new("TextBox", container)
    searchBar.Size = UDim2.new(1, 0, 0, 45)
    searchBar.Position = UDim2.new(0, 0, 0, 0)
    searchBar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    searchBar.TextColor3 = Color3.new(1, 1, 1)
    searchBar.PlaceholderText = "Search username..."
    searchBar.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    searchBar.Font = Enum.Font.SourceSansBold
    searchBar.TextSize = 20
    searchBar.ClearTextOnFocus = false

    -- Player List
    local frame = Instance.new("ScrollingFrame", container)
    frame.Size = UDim2.new(1, 0, 1, -50) -- Fills the rest of the container
    frame.Position = UDim2.new(0, 0, 0, 50)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    frame.ScrollBarThickness = 8

    local layout = Instance.new("UIListLayout", frame)
    layout.Padding = UDim.new(0, 5)

    local targetPlayer = nil
    local isSpamming = false

    local linearVelocity = Vector3.new(0, 50, 0)
    local angularVelocity = Vector3.new(0, 15000, 0)
    local flingPositioningOffset = Vector3.new(0, 0, 0)

    RunService.Heartbeat:Connect(function(dt: number)
        if isSpamming and LocalPlayer and LocalPlayer.Character and targetPlayer and targetPlayer.Character then
            local vehicleModel = getMyVehicleModel()
            local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if vehicleModel and targetRoot and myRoot then
                local s1 = setEntireVehicleVelocity(vehicleModel) -- Stop the car before moving it
                if not s1 then return end -- Failed to get velocity setter, abort

                local dist = (myRoot.Position - targetRoot.Position).Magnitude
                local duration = GetDurationFromDistance(dist, 100) -- Assuming 100 studs per second fling speed, adjust as needed
                local target = targetRoot.Position + flingPositioningOffset
                local alphaStep = dt/duration
                local currentPos = vehicleModel:GetPivot().Position
                local lerpTarget = Lerp(currentPos, target, alphaStep)
                local s2 = moveVehicleTo(vehicleModel, lerpTarget) -- Move the car towards the target first before setting velocity to make it more likely to fling them even if they're in a vehicle themselves, and to reduce the chances of just launching yourself into the sky instead of towards the target
                if not s2 then return end -- Failed to set position, abort

                local s3 = setEntireVehicleVelocity(vehicleModel, linearVelocity, angularVelocity) -- Set the velocity after moving the car to try and fling the player better
                if not s3 then return end -- Failed to set velocity, abort
            end
        end
    end)

    -- ==========================================
    -- POPULATE PLAYER LIST (WITH SEARCH FILTER)
    -- ==========================================
    local function updateList(filterText)
        -- Default to empty string if nil
        filterText = filterText and string.lower(filterText) or ""
        
        for _, child in ipairs(frame:GetChildren()) do 
            if child:IsA("TextButton") then child:Destroy() end 
        end
        
        local buttonCount = 0
        
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local playerName = string.lower(p.Name)
                
                -- If search is empty OR the player's name contains the search text, show them
                if filterText == "" or string.find(playerName, filterText, 1, true) then
                    buttonCount = buttonCount + 1
                    
                    local btn = Instance.new("TextButton", frame)
                    btn.Size = UDim2.new(1, -15, 0, 50) 
                    btn.Text = "FLING: " .. p.Name 
                    
                    -- Keep the button green if they are the current active target
                    if targetPlayer == p and isSpamming then
                        btn.Text = "🛑 STOP FLINGING"
                        btn.BackgroundColor3 = Color3.fromRGB(30, 70, 30)
                    else
                        btn.BackgroundColor3 = Color3.fromRGB(70, 30, 30)
                    end
                    
                    btn.TextColor3 = Color3.new(1, 1, 1)
                    btn.Font = Enum.Font.SourceSansBold
                    btn.TextSize = 22 
                    btn.TextWrapped = true
                    
                    btn.MouseButton1Click:Connect(function()
                        if targetPlayer == p and isSpamming then
                            -- TURN OFF SAFELY
                            isSpamming = false
                            targetPlayer = nil
                            
                            btn.Text = "FLING: " .. p.Name 
                            btn.BackgroundColor3 = Color3.fromRGB(70, 30, 30)
                            
                            local seat = getMySeat()
                            local carModel = getMyVehicleModel()
                            if seat and carModel then
                                seat.AssemblyLinearVelocity = Vector3.zero
                                seat.AssemblyAngularVelocity = Vector3.zero
                                carModel:PivotTo(carModel:GetPivot() * CFrame.new(0, 5, 0))
                            end
                        else
                            -- TURN ON
                            targetPlayer = p
                            isSpamming = true
                            btn.Text = "🛑 STOP FLINGING"
                            btn.BackgroundColor3 = Color3.fromRGB(30, 70, 30)
                            
                            -- Force a UI update so other buttons reset their colors if you switched targets mid-fling
                            updateList(searchBar.Text)
                        end
                    end)
                end
            end
        end
        frame.CanvasSize = UDim2.new(0, 0, 0, buttonCount * 55)
    end

    -- Update list dynamically as you type
    searchBar:GetPropertyChangedSignal("Text"):Connect(function()
        updateList(searchBar.Text)
    end)

    -- Initial Load & Connections
    updateList()
    Players.PlayerAdded:Connect(function() updateList(searchBar.Text) end)
    Players.PlayerRemoving:Connect(function() updateList(searchBar.Text) end)

    -- Toggle Menu with 'K'
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == Enum.KeyCode.K then
            container.Visible = not container.Visible
        end
    end)
end

local antisConnection = nil
local function antisChanged(antis)
    if antis == nil then
        antis = Config.antis:get()
    end
    local amountEnabled = 0
    local enable = true
    for _, v in pairs(antis) do
        if v == true then
            amountEnabled += 1
        end
    end
    if amountEnabled == 0 then
        enable = false
    end
    if enable then
        if not antisConnection then
            antisConnection = RunService.Heartbeat:Connect(function()
                local antisNow = Config.antis:get()
                local disable = false
                for _, v in pairs(antisNow) do
                    if v == true then
                        amountEnabled += 1
                    end
                end
                if amountEnabled == 0 then
                    disable = true
                end
                amountEnabled = 0
                if disable then
                    antisConnection:Disconnect()
                    antisConnection = nil
                    return
                end

                local ch = LocalPlayer.Character
                if ch then
                    local hu = ch:FindFirstChildOfClass("Humanoid")
                    if hu then
                        if antis.antiCuffEnabled and hu:GetAttribute("CuffState") ~= 1 then
                            hu:SetAttribute("CuffState", 1)
                        end
                        if antis.antiRagdollEnabled and hu:GetAttribute("Ragdoll") == true then
                            hu:SetAttribute("Ragdoll", false)
                        end
                        if antis.antiTazerEnabled and hu:GetAttribute("IsTazerd") == true then
                            hu:SetAttribute("IsTazerd", false)
                        end
                    end
                    if antis.antiHackBypassEnabled then
                        local antihack_alt = ch:FindFirstChild("Antihack_alt")
                        local antihack = ch:FindFirstChild("Antihack")
                        if antihack_alt then
                            antihack_alt:Destroy()
                        end
                        if antihack then
                            antihack:Destroy()
                        end
                    end
                end
            end)
        end
    else
        if antisConnection then
            if antisConnection.Connected then
                antisConnection:Disconnect()
            end
            antisConnection = nil
        end
    end
end

local disableCarDamageConnection = nil
local oldCrashStep = nil
local function newCrashStep(_, p63)
    return 0
end
local function carDamageDisabledChanged(disabled)
    if disabled == nil then
        disabled = Config.carDamageDisabled:get()
    end
    if disabled then
        if not disableCarDamageConnection then
            disableCarDamageConnection = RunService.Heartbeat:Connect(function()
                local ch = LocalPlayer.Character
                if ch then
                    local occupantScript = ch:FindFirstChild("OccupantScript")
                    if occupantScript then
                        local driverScript = occupantScript:FindFirstChild("DriverScript")
                        if driverScript then
                            local vehicleObj = driverScript:FindFirstChild("VehicleObject")
                            if vehicleObj then
                                local vehicle = vehicleObj.Value
                                if vehicle then
                                    local vehicleScripts = vehicle:FindFirstChild("Scripts")
                                    if vehicleScripts then
                                        local chassisHandlerModule = vehicleScripts:FindFirstChild("ChassisHandler")
                                        if chassisHandlerModule then
                                            local chassisHandler = require(chassisHandlerModule)
                                            if oldCrashStep == nil then
                                                oldCrashStep = chassisHandler.CrashStep
                                            end
                                            chassisHandler.CrashStep = newCrashStep
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
    else
        if disableCarDamageConnection then
            if disableCarDamageConnection.Connected then
                disableCarDamageConnection:Disconnect()
            end
            disableCarDamageConnection = nil
        end
    end
end

local vehicleNoclipConnection = nil
local vs = workspace:FindFirstChild("Vehicles")
local originalCollisions = {}
local function resetCollisions(v: Instance)
    local tab = originalCollisions[v] or nil
    if tab then
       for p, cc in pairs(tab) do
           p.CanCollide = cc
       end
    else
        tab = {}
        for _, p in ipairs(v:GetDescendants()) do
            if p:IsA("BasePart") then
                tab[p] = p.CanCollide
            end
        end
        originalCollisions[v] = tab
    end
end
local function vehicleNoclipEnabledChanged(enabled)
    if not vs then
        vs = workspace:FindFirstChild("Vehicles")
    end
    if enabled == nil then
        enabled = Config.carDamageDisabled:get()
    end
    if vs and enabled then
        if not vehicleNoclipConnection then
            vehicleNoclipConnection = RunService.Heartbeat:Connect(function()
                local myv = nil
                local ch = LocalPlayer.Character
                if ch then
                    local occupantScript = ch:FindFirstChild("OccupantScript")
                    if occupantScript then
                        local driverScript = occupantScript:FindFirstChild("DriverScript")
                        if driverScript then
                            local vehicleObj = driverScript:FindFirstChild("VehicleObject")
                            if vehicleObj then
                                myv = vehicleObj.Value
                            end
                        end
                    end
                end
                for _, v in ipairs(vs:GetChildren()) do
                    resetCollisions(v)
                    if v ~= myv then
                        for _, p in ipairs(v:GetDescendants()) do
                            if p:IsA("BasePart") then
                                p.CanCollide = false
                            end
                        end
                    end
                end
            end)
        end
    else
        if vehicleNoclipConnection then
            if vehicleNoclipConnection.Connected then
                vehicleNoclipConnection:Disconnect()
            end
            vehicleNoclipConnection = nil
        end
    end
end

local ghostriderConnection = nil
local function ghostriderEnabledChanged(enabled)
    if enabled == nil then
        enabled = Config.ghostriderEnabled:get()
    end
    if enabled then
        if not ghostriderConnection then
            ghostriderConnection = RunService.PreSimulation:Connect(function()
                local intens = Config.nitrous:get()
                local brakePower = Config.airbrake:get()

                local subject = workspace.CurrentCamera.CameraSubject
                local targetPart = nil

                -- Determine the target (Seat or Part)
                if subject:IsA("Humanoid") and subject.SeatPart then
                    targetPart = subject.SeatPart
                elseif subject:IsA("BasePart") then
                    targetPart = subject
                end

                if not targetPart then return end

                local boosting = false
                local braking = false

                for _, keyCodeName in ipairs(Config.nitrousKeybind:get()) do
                    if isKeybindActive(keyCodeName) then
                        boosting = true
                        break
                    end
                end

                for _, keyCodeName in ipairs(Config.airbrakeKeybind:get()) do
                    if isKeybindActive(keyCodeName) then
                        braking = true
                        break
                    end
                end

                -- BOOST LOGIC (Left Shift)
                if boosting then
                    targetPart:ApplyImpulse(targetPart.CFrame.LookVector * Vector3.new(intens, intens, intens))
                end

                -- SMOOTH BRAKE LOGIC (Left Control)
                if braking then
                    -- We 'Lerp' the current velocity toward a zero vector
                    -- This creates a "Tween" effect for physics
                    targetPart.AssemblyLinearVelocity = targetPart.AssemblyLinearVelocity:Lerp(Vector3.zero, brakePower)
                    
                    -- We also smooth out the spinning/rotation so it doesn't jitter
                    targetPart.AssemblyAngularVelocity = targetPart.AssemblyAngularVelocity:Lerp(Vector3.zero, brakePower)
                end
            end)
        end
    else
        if ghostriderConnection then
            if ghostriderConnection.Connected then
                ghostriderConnection:Disconnect()
            end
            ghostriderConnection = nil
        end
    end
end

local function extendToolHitbox()
    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    local handle = tool:FindFirstChild("Handle")
    if not handle then return end
    if typeof(handle) ~= "Instance" or not handle:IsA("BasePart") then return end
    local a = Instance.new("SelectionBox", handle)
    a.Adornee = handle
    handle.Size=Vector3.new(20, 20, 20)
    handle.Transparency = 1
end

local rocketleagueConnection = nil
local function rocketLeagueControlsChanged(controls)
    if controls == nil then
        controls = Config.rocketLeagueControls:get()
    end
    local amountEnabled = 0
    local enable = true
    for _, v in pairs(controls) do
        if v == true then
            amountEnabled += 1
        end
    end
    if amountEnabled == 0 then
        enable = false
    end
    if enable then
        if not rocketleagueConnection then
            rocketleagueConnection = RunService.PreSimulation:Connect(function(dt: number)
                local controlsNow = Config.rocketLeagueControls:get()
                local disable = false
                for _, v in pairs(controlsNow) do
                    if v == true then
                        amountEnabled += 1
                    end
                end
                if amountEnabled == 0 then
                    disable = true
                end
                amountEnabled = 0
                if disable then
                    rocketleagueConnection:Disconnect()
                    rocketleagueConnection = nil
                    return
                end

                local airRollStrength = math.rad(Config.airRollStrength:get())
                local airPitchStrength = math.rad(Config.airPitchStrength:get())
                local powerSlideStrength = math.rad(Config.powerSlideStrength:get())

                local keybinds = {
                    airRollLeft = {controlsNow.airRollEnabled, Config.airRollLeftKeybind:get(), "LookVector", -airRollStrength};
                    airRollRight = {controlsNow.airRollEnabled, Config.airRollRightKeybind:get(), "LookVector", airRollStrength};
                    airPitchUp = {controlsNow.airPitchEnabled, Config.airPitchUpKeybind:get(), "RightVector" , airPitchStrength};
                    airPitchDown = {controlsNow.airPitchEnabled, Config.airPitchDownKeybind:get(), "RightVector", -airPitchStrength};
                    powerSlideLeft = {controlsNow.powerSlideEnabled, Config.powerSlideLeftKeybind:get(), "UpVector", powerSlideStrength};
                    powerSlideRight = {controlsNow.powerSlideEnabled, Config.powerSlideRightKeybind:get(), "UpVector", -powerSlideStrength};
                }

                local subject = workspace.CurrentCamera.CameraSubject
                local targetPart = nil

                -- Determine the target (Seat or Part)
                if subject:IsA("Humanoid") and subject.SeatPart then
                    targetPart = subject.SeatPart
                elseif subject:IsA("BasePart") then
                    targetPart = subject
                end

                if not targetPart then
                    return
                end
                for _, k in pairs(keybinds) do
                    if k[1] ~= true then
                        continue
                    end
                    local keyCodeList = k[2]
                    local exit = false
                    for _, keyCodeName in ipairs(keyCodeList) do
                        if exit then
                            continue
                        end
                        if keyCodeName == nil or keyCodeName == "" or keyCodeName == "None" then
                            continue
                        end
                        local keyCode = Enum.KeyCode[keyCodeName]
                        if not keyCode then
                            warn("Invalid keycode name: " .. keyCodeName)
                            continue
                        end
                        local dir = k[3]
                        if not dir then
                            continue
                        end
                        local strength = k[4]
                        if not strength then
                            continue
                        end
                        local must = k[5]
                        if must ~= nil and UserInputService:IsKeyDown(must) == false then
                            continue
                        end
                        local mustnt = k[6]
                        if mustnt ~= nil and UserInputService:IsKeyDown(mustnt) == true then
                            continue
                        end
                        if isKeybindActive(keyCodeName) then
                            exit = true
                            targetPart:ApplyAngularImpulse(targetPart.CFrame[dir] * strength)
                        end
                    end
                end
                local aav = targetPart.AssemblyAngularVelocity
                local rx, ry, rz = aav.X, aav.Y, aav.Z
                local eachmax = math.rad(90)
                if controlsNow.airPitchEnabled then
                    local max = eachmax
                    rx = math.clamp(rx, -max, max)
                end
                if controlsNow.powerSlideEnabled then
                    local max = eachmax
                    ry = math.clamp(ry, -max, max)
                end
                if controlsNow.airRollEnabled then
                    local max = eachmax
                    rz = math.clamp(rz, -max, max)
                end
                targetPart.AssemblyAngularVelocity = Vector3.new(rx, ry, rz)
            end)
        end
    else
        if rocketleagueConnection then
            if rocketleagueConnection.Connected then
                rocketleagueConnection:Disconnect()
            end
            rocketleagueConnection = nil
        end
    end
end

function setPropertiesRecursively(instance, properties)
    for i, v in pairs(properties) do
        if instance[i] ~= nil then
            if type(instance[i]) == "table" and type(v) == "table" then
                setPropertiesRecursively(instance[i], v)
            else
                instance[i] = v
            end
        end
    end
end

local ak47Tampered = false
local weaponModule = ReplicatedStorage.Client.Database.ToolInformation.Informations.Weapon
local weaponMod = require(weaponModule)
local function tamperGun(gun: string)
    local gun = weaponMod.Data[gun]

    -- print(repr(gun, reprSettings))

    local newProperties = {
        MaxAmmo = math.huge;
        Ammo = math.huge;
        CameraSettings = {
            Recoil = {
                Angle = 0;
            };
        };
        Damage = {
            Head = 100;
            Torso = 100;
            Limbs = 100;
        };
        ProjectileProperties = {
            MaxDistance = 10000;
        };
        MuzzleVelocity = 10000;
        Range = 10000;
        FullDamageRange = 0;
        Firerate = 10000;
        ReloadTime = 0.003;
        BurstShotCount = 100;
        ClimbRate = 0;
    }

    setPropertiesRecursively(gun, newProperties)
end

--AutoBus
local autobus_thread = nil
local autobus_enabled = Iris.State(false)
do
    local DefaultBusLocationsTable = {
        BusStop_4OrangeInv = { 904.1454467773438, 68.958984375, 834.0386352539062, -0.7661795616149902, 0, 0.6426267623901367, 0, 1, 0, -0.6426267623901367, 0, -0.7661795616149902 },
        BusStop_5Rot = { -1563.828125, 41.515625, -538.75390625, 0.938283383846283, 0, -0.34586742520332336, 0, 1, 0, 0.34586742520332336, 0, 0.938283383846283 },
        BusStop_5OrangeInv = { 642.195556640625, 41.515625, -2004.3958740234375, 0.9986181855201721, 0, 0.05255195498466492, 0, 1, 0, -0.05255195498466492, 0, 0.9986181855201721 },
        BusStop_6RotInv = { 612.1533813476562, 41.515625, -2003.4979248046875, -0.9986186027526855, 0, -0.05255195498466492, 0, 1, 0, 0.05255195498466492, 0, -0.9986186027526855 },
        BusStop_7RotInv = { -561.9729614257812, 41.51171875, -1204.152587890625, -0.9993922710418701, 0, -0.03486879914999008, 0, 1, 0, 0.03486879914999008, 0, -0.9993922710418701 },
        BusStop_1Rot = { 20.845703125, 68.958984375, 681.998046875, 0.9848124980926514, 0, 0.17362114787101746, 0, 1, 0, -0.17362114787101746, 0, 0.9848124980926514 },
        BusStop_2Orange = { -2097.86767578125, 41.515625, 425.59649658203125, -0.017623186111450195, 0, 0.9998448491096497, 0, 1, 0, -0.9998448491096497, 0, -0.017623186111450195 },
        BusStop_6OrangeInv = { -2332.544921875, 41.515625, -1221.6705322265625, -0.9658845663070679, 0, 0.25897300243377686, 0, 1, 0, -0.25897300243377686, 0, -0.9658845663070679 },
        BusStop_7Rot = { -2096.721435546875, 41.515625, 471.6341857910156, 0.01762288808822632, 0, -0.9998448491096497, 0, 1, 0, 0.9998448491096497, 0, 0.01762288808822632 },
        BusStop_2RotInv = { -2097.859375, 41.515625, 426.078125, -0.017623186111450195, 0, 0.9998448491096497, 0, 1, 0, -0.9998448491096497, 0, -0.017623186111450195 },
        BusStop_1RotInv = { 72.849609375, 68.958984375, 726.095703125, 0.9848124980926514, 0, 0.17362114787101746, 0, 1, 0, -0.17362114787101746, 0, 0.9848124980926514 },
        BusStop_3OrangeInv = { 830.0198364257812, 41.36328125, 1545.96484375, -1, 0, 0, 0, 1, 0, 0, 0, -1 },
        BusStop_5RotInv = { -525.1734619140625, 41.578125, -1102.8594970703125, 0.9993919134140015, 0, 0.03486879914999008, 0, 1, 0, -0.03486879914999008, 0, 0.9993919134140015 },
        BusStop_3Orange = { -2288.2734375, 41.515625, -1210.1875, 0.9658845663070679, 0, -0.25897300243377686, 0, 1, 0, 0.25897300243377686, 0, 0.9658845663070679 },
        BusStop_4Orange = { 612.56640625, 41.515625, -2003.51953125, -0.9986186027526855, 0, -0.05255195498466492, 0, 1, 0, 0.05255195498466492, 0, -0.9986186027526855 },
        BusStop_Start = { -12.13671875, 68.9609375, 1011.41796875, 0.9848124980926514, 0, 0.17362114787101746, 0, 1, 0, -0.17362114787101746, 0, 0.9848124980926514 },
        BusStop_1Orange = { 93.435546875, 68.958984375, 618.572265625, 0.9848124980926514, 0, 0.17362114787101746, 0, 1, 0, -0.17362114787101746, 0, 0.9848124980926514 },
        BusStop_3RotInv = { -2288.28125, 41.515625, -1210.15625, -0.9658845663070679, 0, 0.25897300243377686, 0, 1, 0, -0.25897300243377686, 0, -0.9658845663070679 },
        BusStop_2OrangeInv = { 892.01953125, 68.958984375, 823.86328125, -0.7661795616149902, 0, 0.6426267623901367, 0, 1, 0, -0.6426267623901367, 0, -0.7661795616149902 },
        BusStop_4RotInv = { -1578.69140625, 41.515625, -586.09765625, -0.9382835626602173, 0, 0.34586742520332336, 0, 1, 0, -0.34586742520332336, 0, -0.9382835626602173 },
        BusStop_5Orange = { 830.9609375, 41.36328125, 1545.96484375, -1, 0, 0, 0, 1, 0, 0, 0, -1 },
        BusStop_4Rot = { -561.64453125, 41.51171875, -1204.1640625, -0.9993922710418701, 0, -0.03486879914999008, 0, 1, 0, 0.03486879914999008, 0, -0.9993922710418701 },
        BusStop_1OrangeInv = { 0.58984375, 68.958984375, 790.365234375, 0.9848124980926514, 0, 0.17362114787101746, 0, 1, 0, -0.17362114787101746, 0, 0.9848124980926514 },
        BusStop_6Rot = { -2332.0546875, 41.515625, -1221.5390625, -0.9658845663070679, 0, 0.25897300243377686, 0, 1, 0, -0.25897300243377686, 0, -0.9658845663070679 },
        BusStop_7OrangeInv = { -2096.7265625, 41.515625, 471.3359375, 0.01762288808822632, 0, -0.9998448491096497, 0, 1, 0, 0.9998448491096497, 0, 0.01762288808822632 },
        BusStop_6Orange = { 903.943359375, 68.958984375, 833.869140625, -0.7661795616149902, 0, 0.6426267623901367, 0, 1, 0, -0.6426267623901367, 0, -0.7661795616149902 },
        BusStop_3Rot = { 641.94921875, 41.515625, -2004.3828125, 0.9986181855201721, 0, 0.05255195498466492, 0, 1, 0, -0.05255195498466492, 0, 0.9986181855201721 },
        BusStop_2Rot = { -525.40234375, 41.578125, -1102.8515625, 0.9993919134140015, 0, 0.03486879914999008, 0, 1, 0, -0.03486879914999008, 0, 0.9993919134140015 }
    }

    masterBusLocations = {}

    saveLocations = nil

    if EXECUTOR_FILING_ENABLED then
        local SAVE_FILE_PATH = SCRIPT_DIRECTORY_PATH.."/AutoBus_Locations.json"

        saveLocations = function()
            if writefile then
                local saveTable = {}
                for name, cf in pairs(masterBusLocations) do
                    saveTable[name] = {cf:GetComponents()}
                end
                writefile(SAVE_FILE_PATH, HttpService:JSONEncode(saveTable))
            end
        end

        function loadLocations()
            if isfile and isfile(SAVE_FILE_PATH) then
                local jsonData = readfile(SAVE_FILE_PATH)
                local success, saveTable = pcall(function() return HttpService:JSONDecode(jsonData) end)
                if success and type(saveTable) == "table" then
                    if #saveTable == 0 then
                        saveTable = DefaultBusLocationsTable
                    end
                    for name, comps in pairs(saveTable) do
                        masterBusLocations[name] = CFrame.new(table.unpack(comps))
                    end
                end
            end
        end

        loadLocations()
    else
        masterBusLocations = DefaultBusLocationsTable
    end

    -- ==========================================
    -- PROMPT DETECTION
    -- ==========================================
    function waitForPromptToClear()
        -- This looks for the "Stop Your Vehicle" text in your PlayerGui
        -- The script will wait here until that specific text disappears
        local startTime = tick()
        repeat 
            task.wait(0.5)
            local promptFound = false
            -- Search through PlayerGui for the specific text from your video
            local guiObjects = LocalPlayer.PlayerGui:GetDescendants()
            for _, obj in ipairs(guiObjects) do
                if obj:IsA("TextLabel") and (obj.Text:find("Stop Your Vehicle") or obj.Text:find("have to stop")) then
                    if obj.Visible == true and obj.TextTransparency < 1 then
                        promptFound = true
                        break
                    end
                end
            end
        until not promptFound or (tick() - startTime > 10) -- Max 10s timeout safety
    end

    -- ==========================================
    -- CORE LOGIC
    -- ==========================================
    function executeTeleport(bus: Model?, targetCFrame)
        local myRoot = LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or nil
        if not myRoot then return end -- Failed to find HumanoidRootPart, abort

        bus = bus or getMyVehicleModel()
        if not bus then return end
        
        local s1 = setEntireVehicleVelocity(bus, Vector3.zero)
        if not s1 then return end -- Failed to get velocity setter, abort
        
        -- 60 studs back, 3 studs up
        local backwardOffset = -targetCFrame.LookVector * 60
        local spawnCFrame = (targetCFrame + backwardOffset) + Vector3.new(0, 3, 0)
        local target = spawnCFrame.Position
        local targetRotation = spawnCFrame.Rotation

        local s2 = moveVehicleTo(bus, CFrame.new(bus:GetPivot().Position) * targetRotation)
        if not s2 then return end -- Failed to set vehicle rotation, abort

        local function AutoBusUponArrival()
            -- This function will run once the vehicle reaches the target location
            -- You can add any additional logic here that should happen after teleporting
            local driveSpeed = targetCFrame.LookVector * 60
            local s3 = setEntireVehicleVelocity(bus, driveSpeed)
            if not s3 then return end -- Failed to set drive speed, abort

            task.wait(1.5)

            -- Hard Brake
            local s4 = setEntireVehicleVelocity(bus, Vector3.zero)
            if not s4 then return end -- Failed to set brake speed, abort

            -- NEW: Wait for the game UI to finish before moving to the next stop
            waitForPromptToClear()

            task.wait(1) -- Short buffer after prompt clears
        end

        local dist = (myRoot.Position - spawnCFrame.Position).Magnitude
        local duration = GetDurationFromDistance(dist, 100) -- Assuming 100 studs per second fling speed, adjust as needed
        TeleportFinishedCallbacks.AutoBusUponArrival = AutoBusUponArrival
        LerpTeleport(target, duration) -- Move the car above the target to avoid getting stuck in the ground and to make it more likely to fling them even if they're in a vehicle themselves
    end
end

-- Iris Init
table.insert(Iris.Internal._initFunctions, function()
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.fromScale(1, 1)
    background.BackgroundColor3 = Config.backgroundColor:get()
    background.BackgroundTransparency = Config.backgroundTransparency:get()

    local widget
    if Iris._config.UseScreenGUIs then
        widget = Instance.new("ScreenGui")
        widget.Name = "Iris_Background"
        widget.IgnoreGuiInset = true
        widget.DisplayOrder = Iris._config.DisplayOrderOffset - 1
        widget.ScreenInsets = Enum.ScreenInsets.None
        widget.Enabled = true

        background.Parent = widget
    else
        background.ZIndex = Iris._config.DisplayOrderOffset - 1
        widget = background
    end

    Config.backgroundColor:onChange(function(value: Color3)
        background.BackgroundColor3 = value
    end)
    Config.backgroundTransparency:onChange(function(value: number)
        background.BackgroundTransparency = value
    end)

    Config.showBackground:onChange(function(show: boolean)
        if show then
            widget.Parent = Iris.Internal.parentInstance
        else
            widget.Parent = nil
        end
    end)
end)

-- Iris Helpers
local function helpMarker(helpText: string)
    Iris.PushConfig({ TextColor = Iris._config.TextDisabledColor })
    local text = Iris.Text({ "(?)" })
    Iris.PopConfig()

    Iris.PushConfig({ ContentWidth = UDim.new(0, 350) })
    if text.hovered() then
        Iris.Tooltip({ helpText })
    end
    Iris.PopConfig()
end

local function textAndHelpMarker(text: string, helpText: string)
    Iris.SameLine()
    do
        Iris.Text({ text })
        helpMarker(helpText)
    end
    Iris.End()
end

local waiting = nil
local function keybindButton(state: {[number]: string?}, index: number)
    -- the button has a clicked event, returning true when it is pressed
    local keybindingArray = state:get()
    local currentKeyCodeName = keybindingArray and index and keybindingArray[index] or nil
    if currentKeyCodeName == nil or currentKeyCodeName == "" then
        currentKeyCodeName = "None"
    end
    if Iris.Button({currentKeyCodeName}).clicked() then
        -- run code if we click the button
        if not waiting then
            waiting = {}

            -- Disconnect helper
            local function stopWaiting()
                if waiting.began and waiting.began.Connected then waiting.began:Disconnect() end
                if waiting.changed and waiting.changed.Connected then waiting.changed:Disconnect() end
                waiting = nil
            end

            -- Handle normal buttons (keyboard, mouse, gamepad buttons)
            waiting.began = UserInputService.InputBegan:Connect(function(input)
                local code = input.KeyCode
                local name = code and code.Name or nil

                if not name then return end

                -- Reject unusable keys
                if name == "Unknown" or name == "Escape" or name == "Return" then
                    name = ""
                end

                -- Reject thumbstick clicks (we only want directions)
                if name == "Thumbstick1" or name == "Thumbstick2" then
                    -- ignore here; handled in InputChanged
                    return
                end

                -- Save keybind
                if name ~= currentKeyCodeName then
                    local array = state:get() or {}
                    array[index] = name
                    state:set(array)
                end

                stopWaiting()
            end)

            -- Handle thumbstick movement
            waiting.changed = UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.Gamepad1 then return end

                local code = input.KeyCode
                if code ~= Enum.KeyCode.Thumbstick1 and code ~= Enum.KeyCode.Thumbstick2 then
                    return
                end

                local vec = input.Position
                local x, y = vec.X, vec.Y
                local deadzone = 0.4

                -- Deadzone
                if math.abs(x) < deadzone and math.abs(y) < deadzone then
                    return
                end

                local base = code.Name
                local direction = nil

                -- Determine direction
                if math.abs(x) > math.abs(y) then
                    if x > deadzone then direction = "Right"
                    elseif x < -deadzone then direction = "Left" end
                else
                    if y > deadzone then direction = "Up"
                    elseif y < -deadzone then direction = "Down" end
                end

                if not direction then return end

                local finalName = base .. direction

                -- Save keybind
                if finalName ~= currentKeyCodeName then
                    local array = state:get() or {}
                    array[index] = finalName
                    state:set(array)
                end

                stopWaiting()
            end)
        end
    end
end
local function keybindWidget(text: string, state)
    Iris.SameLine()
    do
        Iris.Text({ text })
        local addButton = Iris.Button({ "+" })
        Iris.Text({ "|" })
        local subtractButton = Iris.Button({ "-" })
        if addButton.clicked() then
            -- add a new keybind to the array
            local array = state:get() or {}
            table.insert(array, "None") -- default value for new keybinds
            state:set(array)
        elseif subtractButton.clicked() then
            -- remove the last keybind from the array
            local array = state:get() or {}
            if #array > 0 then
                table.remove(array, #array)
            end
            state:set(array)
        end
    end
    Iris.End()

    local keybindsTree = Iris.Tree({"Keybind(s)"})
    do
        if keybindsTree.state.isUncollapsed:get() then
            -- Keybind content would go here
            local array = state:get()
            if array and type(array) == "table" then
                for i: number = 1, #array, 1 do
                    keybindButton(state, i)
                end
            end
        end
    end
    Iris.End()
end

local function color4Picker(text: string, colorState, transparencyState)
    local ColorPicker = Iris.InputColor4({"Color"}, {
        color = Iris.WeakState(colorState:get());
        transparency = Iris.WeakState(transparencyState:get());
    })
    ColorPicker.state.color:set(colorState:get())
    ColorPicker.state.transparency:set(transparencyState:get())
    if ColorPicker.numberChanged() then
        colorState:set(ColorPicker.state.color:get())
        transparencyState:set(ColorPicker.state.transparency:get())
    end
end

-- shows list of runtime widgets and states, including IDs. shows other info about runtime and can show widgets/state info in depth.
local function runtimeInfo()
    local runtimeInfoWindow = Iris.Window({ "Runtime Info" }, { isOpened = Config.showRuntimeInfo })
    do
        local lastVDOM = Iris.Internal._lastVDOM
        local states = Iris.Internal._states

        local numSecondsDisabled = Iris.State(3)
        local rollingDT = Iris.State(0)
        local lastT = Iris.State(os.clock())

        Iris.SameLine()
        do
            Iris.InputNum({ [Iris.Args.InputNum.Text] = "", [Iris.Args.InputNum.Format] = "%d Seconds", [Iris.Args.InputNum.Max] = 10 }, { number = numSecondsDisabled })
            if Iris.Button({ "Disable" }).clicked() then
                Iris.Disabled = true
                task.delay(numSecondsDisabled:get(), function()
                    Iris.Disabled = false
                end)
            end
        end
        Iris.End()

        local t = os.clock()
        local dt = t - lastT.value
        rollingDT.value += (dt - rollingDT.value) * 0.2
        lastT.value = t
        Iris.Text({ string.format("Average %.3f ms/frame (%.1f FPS)", rollingDT.value * 1000, 1 / rollingDT.value) })

        Iris.Text({
            string.format("Window Position: (%d, %d), Window Size: (%d, %d)", runtimeInfoWindow.position.value.X, runtimeInfoWindow.position.value.Y, runtimeInfoWindow.size.value.X, runtimeInfoWindow.size.value.Y),
        })
    end
    Iris.End()
end

local function debugPanel()
    Iris.Window({ "Debug Panel" }, { isOpened = Config.showDebugWindow })
    do
        Iris.CollapsingHeader({ "Widgets" })
        do
            Iris.SeparatorText({ "GuiService" })
            Iris.Text({ `GuiOffset: {Iris.Internal._utility.GuiOffset}` })
            Iris.Text({ `MouseOffset: {Iris.Internal._utility.MouseOffset}` })

            Iris.SeparatorText({ "UserInputService" })
            Iris.Text({ `MousePosition: {Iris.Internal._utility.UserInputService:GetMouseLocation()}` })
            Iris.Text({ `MouseLocation: {Iris.Internal._utility.getMouseLocation()}` })

            Iris.Text({ `Left Control: {Iris.Internal._utility.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)}` })
            Iris.Text({ `Right Control: {Iris.Internal._utility.UserInputService:IsKeyDown(Enum.KeyCode.RightControl)}` })
        end
        Iris.End()
    end
    Iris.End()
end

local choosingConfig_open = Iris.State(false);
local choosingConfig_save = Iris.State(false);
local typingCustomConfig_save = Iris.State(false);

local function mainMenuBar()
    Iris.MenuBar()
    do
        Iris.Menu({ "Configs" })
        do
            local newMenuItem = Iris.MenuItem({ "New" })
            if newMenuItem.clicked() then
                setIrisStatesRecursively(Config, DefaultConfig)
            end
            if EXECUTOR_FILING_ENABLED then
                local openMenuItem = Iris.MenuItem({ "Open" })
                local saveMenuItem = Iris.MenuItem({ "Save" })
                if not choosingConfig_open:get() and not choosingConfig_save:get() and not typingCustomConfig_save:get() then
                    if openMenuItem.clicked() then
                        choosingConfig_open:set(true)
                    elseif saveMenuItem.clicked() then
                        choosingConfig_save:set(true)
                    end
                end
            else
                Iris.Text({ "Config saving/loading is not supported in this executor." })
            end
        end
        Iris.End()

        Iris.Menu({ "Tools" })
        do
            Iris.MenuToggle({ "Runtime Info" }, { isChecked = Config.showRuntimeInfo })
            Iris.MenuToggle({ "Style Editor" }, { isChecked = Config.showStyleEditor })
            Iris.MenuToggle({ "Debug Panel" }, { isChecked = Config.showDebugWindow })
        end
        Iris.End()
    end
    Iris.End()
end

-- allows users to edit state
local styleEditor
do
    styleEditor = function()
        local styleList = {
            {
                "Sizing",
                function()
                    Iris.SameLine()
                    do
                        if Iris.Button({ "Update" }).clicked() then
                            Iris.UpdateGlobalConfig(Config.IrisSizingConfig.value)
                            Config.IrisSizingConfig:set({})
                        end

                        helpMarker("Update the global config with these changes.")
                    end
                    Iris.End()

                    local function SliderInput(input: string, arguments: { any })
                        local Input = Iris[input](arguments, { number = Iris.WeakState(Iris._config[arguments[1]]) })
                        if Input.numberChanged() then
                            Config.IrisSizingConfig.value[arguments[1]] = Input.number:get()
                        end
                    end

                    local function BooleanInput(arguments: { any })
                        local Input = Iris.Checkbox(arguments, { isChecked = Iris.WeakState(Iris._config[arguments[1]]) })
                        if Input.checked() or Input.unchecked() then
                            Config.IrisSizingConfig.value[arguments[1]] = Input.isChecked:get()
                        end
                    end

                    Iris.SeparatorText({ "Main" })
                    SliderInput("SliderVector2", { "WindowPadding", nil, Vector2.zero, Vector2.new(20, 20) })
                    SliderInput("SliderVector2", { "WindowResizePadding", nil, Vector2.zero, Vector2.new(20, 20) })
                    SliderInput("SliderVector2", { "FramePadding", nil, Vector2.zero, Vector2.new(20, 20) })
                    SliderInput("SliderVector2", { "ItemSpacing", nil, Vector2.zero, Vector2.new(20, 20) })
                    SliderInput("SliderVector2", { "ItemInnerSpacing", nil, Vector2.zero, Vector2.new(20, 20) })
                    SliderInput("SliderVector2", { "CellPadding", nil, Vector2.zero, Vector2.new(20, 20) })
                    SliderInput("SliderNum", { "IndentSpacing", 1, 0, 36 })
                    SliderInput("SliderNum", { "ScrollbarSize", 1, 0, 20 })
                    SliderInput("SliderNum", { "GrabMinSize", 1, 0, 20 })

                    Iris.SeparatorText({ "Borders & Rounding" })
                    SliderInput("SliderNum", { "FrameBorderSize", 0.1, 0, 1 })
                    SliderInput("SliderNum", { "WindowBorderSize", 0.1, 0, 1 })
                    SliderInput("SliderNum", { "PopupBorderSize", 0.1, 0, 1 })
                    SliderInput("SliderNum", { "SeparatorTextBorderSize", 1, 0, 20 })
                    SliderInput("SliderNum", { "FrameRounding", 1, 0, 12 })
                    SliderInput("SliderNum", { "GrabRounding", 1, 0, 12 })
                    SliderInput("SliderNum", { "PopupRounding", 1, 0, 12 })

                    Iris.SeparatorText({ "Widgets" })
                    SliderInput("SliderVector2", { "DisplaySafeAreaPadding", nil, Vector2.zero, Vector2.new(20, 20) })
                    SliderInput("SliderVector2", { "SeparatorTextPadding", nil, Vector2.zero, Vector2.new(36, 36) })
                    SliderInput("SliderUDim", { "ItemWidth", nil, UDim.new(), UDim.new(1, 200) })
                    SliderInput("SliderUDim", { "ContentWidth", nil, UDim.new(), UDim.new(1, 200) })
                    SliderInput("SliderNum", { "ImageBorderSize", 1, 0, 12 })
                    local TitleInput = Iris.ComboEnum({ "WindowTitleAlign" }, { index = Iris.WeakState(Iris._config.WindowTitleAlign) }, Enum.LeftRight)
                    if TitleInput.closed() then
                        Config.IrisSizingConfig.value["WindowTitleAlign"] = TitleInput.index:get()
                    end
                    BooleanInput({ "RichText" })
                    BooleanInput({ "TextWrapped" })

                    Iris.SeparatorText({ "Config" })
                    BooleanInput({ "UseScreenGUIs" })
                    SliderInput("DragNum", { "DisplayOrderOffset", 1, 0 })
                    SliderInput("DragNum", { "ZIndexOffset", 1, 0 })
                    SliderInput("SliderNum", { "MouseDoubleClickTime", 0.1, 0, 5 })
                    SliderInput("SliderNum", { "MouseDoubleClickMaxDist", 0.1, 0, 20 })
                end,
            },
            {
                "Colors",
                function()
                    Iris.SameLine()
                    do
                        if Iris.Button({ "Update" }).clicked() then
                            Iris.UpdateGlobalConfig(Config.IrisColorsConfig.value)
                            Config.IrisColorsConfig:set({})
                        end
                        helpMarker("Update the global config with these changes.")
                    end
                    Iris.End()

                    local color4s = {
                        "Text",
                        "TextDisabled",
                        "WindowBg",
                        "PopupBg",
                        "Border",
                        "BorderActive",
                        "ScrollbarGrab",
                        "TitleBg",
                        "TitleBgActive",
                        "TitleBgCollapsed",
                        "MenubarBg",
                        "FrameBg",
                        "FrameBgHovered",
                        "FrameBgActive",
                        "Button",
                        "ButtonHovered",
                        "ButtonActive",
                        "Image",
                        "SliderGrab",
                        "SliderGrabActive",
                        "Header",
                        "HeaderHovered",
                        "HeaderActive",
                        "SelectionImageObject",
                        "SelectionImageObjectBorder",
                        "TableBorderStrong",
                        "TableBorderLight",
                        "TableRowBg",
                        "TableRowBgAlt",
                        "NavWindowingHighlight",
                        "NavWindowingDimBg",
                        "Separator",
                        "CheckMark",
                    }

                    for _, vColor in color4s do
                        local Input = Iris.InputColor4({ vColor }, {
                            color = Iris.WeakState(Iris._config[vColor .. "Color"]),
                            transparency = Iris.WeakState(Iris._config[vColor .. "Transparency"]),
                        })
                        if Input.numberChanged() then
                            Config.IrisColorsConfig.value[vColor .. "Color"] = Input.color:get()
                            Config.IrisColorsConfig.value[vColor .. "Transparency"] = Input.transparency:get()
                        end
                    end
                end,
            },
            {
                "Fonts",
                function()
                    Iris.SameLine()
                    do
                        if Iris.Button({ "Update" }).clicked() then
                            Iris.UpdateGlobalConfig(Config.IrisFontsConfig.value)
                            Config.IrisFontsConfig:set({})
                        end

                        helpMarker("Update the global config with these changes.")
                    end
                    Iris.End()

                    local fonts: { [string]: Font } = {
                        ["Code (default)"] = Font.fromEnum(Enum.Font.Code),
                        ["Ubuntu (template)"] = Font.fromEnum(Enum.Font.Ubuntu),
                        ["Arial"] = Font.fromEnum(Enum.Font.Arial),
                        ["Highway"] = Font.fromEnum(Enum.Font.Highway),
                        ["Roboto"] = Font.fromEnum(Enum.Font.Roboto),
                        ["Roboto Mono"] = Font.fromEnum(Enum.Font.RobotoMono),
                        ["Noto Sans"] = Font.new("rbxassetid://12187370747"),
                        ["Builder Sans"] = Font.fromEnum(Enum.Font.BuilderSans),
                        ["Builder Mono"] = Font.new("rbxassetid://16658246179"),
                        ["Sono"] = Font.new("rbxassetid://12187374537"),
                    }

                    Iris.Text({ `Current Font: {Iris._config.TextFont.Family} Weight: {Iris._config.TextFont.Weight} Style: {Iris._config.TextFont.Style}` })
                    Iris.SeparatorText({ "Size" })

                    local TextSize = Iris.SliderNum({ "Font Size", 1, 4, 20 }, { number = Iris.WeakState(Iris._config.TextSize) })
                    if TextSize.numberChanged() then
                        Config.IrisFontsConfig.value["TextSize"] = TextSize.state.number:get()
                    end

                    Iris.SeparatorText({ "Properties" })

                    local TextFont = Iris.WeakState(Iris._config.TextFont.Family)
                    local FontWeight = Iris.ComboEnum({ "Font Weight" }, { index = Iris.WeakState(Iris._config.TextFont.Weight) }, Enum.FontWeight)
                    local FontStyle = Iris.ComboEnum({ "Font Style" }, { index = Iris.WeakState(Iris._config.TextFont.Style) }, Enum.FontStyle)

                    Iris.SeparatorText({ "Fonts" })
                    for name, font in fonts do
                        font = Font.new(font.Family, FontWeight.state.index.value, FontStyle.state.index.value)
                        Iris.SameLine()
                        do
                            Iris.PushConfig({
                                TextFont = font,
                            })

                            if Iris.Selectable({ `{name} | "The quick brown fox jumps over the lazy dog."`, font.Family }, { index = TextFont }).selected() then
                                Config.IrisFontsConfig.value["TextFont"] = font
                            end
                            Iris.PopConfig()
                        end
                        Iris.End()
                    end
                end,
            },
        }

        Iris.Window({ "Style Editor" }, { isOpened = Config.showStyleEditor })
        do
            Iris.Text({ "Customize the look of Iris in realtime." })

            local ThemeState = Iris.State("Dark Theme")
            if Iris.ComboArray({ "Theme" }, { index = ThemeState }, { "Dark Theme", "Light Theme" }).closed() then
                if ThemeState.value == "Dark Theme" then
                    Iris.UpdateGlobalConfig(Iris.TemplateConfig.colorDark)
                elseif ThemeState.value == "Light Theme" then
                    Iris.UpdateGlobalConfig(Iris.TemplateConfig.colorLight)
                end
            end

            local SizeState = Iris.State("Classic Size")
            if Iris.ComboArray({ "Size" }, { index = SizeState }, { "Classic Size", "Larger Size" }).closed() then
                if SizeState.value == "Classic Size" then
                    Iris.UpdateGlobalConfig(Iris.TemplateConfig.sizeDefault)
                elseif SizeState.value == "Larger Size" then
                    Iris.UpdateGlobalConfig(Iris.TemplateConfig.sizeClear)
                end
            end

            Iris.SameLine()
            do
                if Iris.Button({ "Revert" }).clicked() then
                    Iris.UpdateGlobalConfig(Iris.TemplateConfig.colorDark)
                    Iris.UpdateGlobalConfig(Iris.TemplateConfig.sizeDefault)
                    ThemeState:set("Dark Theme")
                    SizeState:set("Classic Size")
                end

                helpMarker("Reset Iris to the default theme and size.")
            end
            Iris.End()

            Iris.TabBar()
            do
                for i, v in ipairs(styleList) do
                    Iris.Tab({ v[1] })
                    do
                        styleList[i][2]()
                    end
                    Iris.End()
                end
            end
            Iris.End()

            Iris.Separator()
        end
        Iris.End()
    end
end

local ConfigDisplayNames = {
    ["antiCuffEnabled"] = "Anti-Cuff Enabled";
    ["antiRagdollEnabled"] = "Anti-Ragdoll Enabled";
    ["antiTazerEnabled"] = "Anti-Tazer Enabled";
    ["antiHackBypassEnabled"] = "Anti-Hack Bypass Enabled";
    ["airRollEnabled"] = "Air Roll Enabled";
    ["airPitchEnabled"] = "Air Pitch Enabled";
    ["powerSlideEnabled"] = "Power Slide Enabled";
}

-- Widgets
Iris:Connect(function()
    --Connected to RunService.Heartbeat (~60 FPS)

    local sessionTime = FormatHours(time())
    local window = Iris.Window({"Emden Hub by @Brycki404 (" .. ver .. ") " .. sessionTime}, {
        size = Iris.State(Vector2.new(600, 550));
        position = Iris.State(Vector2.new(100, 25));
        isOpened = Config.showMainWindow;
    })
    -- the window has opened and uncollapsed events, which return booleans
    if window.state.isOpened:get() and window.state.isUncollapsed:get() then
        -- run the window code only if the window is actually open and uncollapsed,
        -- which is more efficient.
        Iris.Text({"Version: " .. ver})
        Iris.Text({"Your Session Time: " .. sessionTime})

        Iris.SameLine()
        do
            Iris.Text({ "Toggle UI Keybind" })
            keybindButton(Config.windowKeyCode, 1)
        end
        Iris.End()

        mainMenuBar()

        Iris.TabBar()
        do
            Iris.Tab({"ESP"})
            do
                Iris.SeparatorText({"Master Settings"})

                local MasterMaxRenderDistance = Iris.DragNum({"Max Render Distance", 1, 0, 20000}, { number = Config.ESP.MasterMaxRenderDistance })
                if MasterMaxRenderDistance.numberChanged() then
                    Config.ESP.MasterMaxRenderDistance:set(MasterMaxRenderDistance.state.number:get())
                end

                local MasterShapes = Iris.Checkbox({"Shapes Enabled"}, { isChecked = Config.ESP.MasterShapes })
                if MasterShapes.checked() or MasterShapes.unchecked() then
                    Config.ESP.MasterShapes:set(MasterShapes.state.isChecked:get())
                end

                local MasterText = Iris.Checkbox({"Text Enabled"}, { isChecked = Config.ESP.MasterText })
                if MasterText.checked() or MasterText.unchecked() then
                    Config.ESP.MasterText:set(MasterText.state.isChecked:get())
                end

                local MasterTracers = Iris.Checkbox({"Tracers Enabled"}, { isChecked = Config.ESP.MasterTracers })
                if MasterTracers.checked() or MasterTracers.unchecked() then
                    Config.ESP.MasterTracers:set(MasterTracers.state.isChecked:get())
                end

                local CategoryChanged = false
                local NewSelectedCategory = nil

                local NumCategories = CountList(SelectableCategories)
                if NumCategories > 0 then
                    Iris.SeparatorText({"Categories"})

                    local thisCategoryIndex = SelectedCategory:get()
                    local thisCategoryName = SelectableCategories[thisCategoryIndex]
                    
                    Iris.Text({"Selected Category: " .. thisCategoryName})
                    Iris.Combo({""}, {index = SelectedCategory})
                    for i, categoryName in ipairs(SelectableCategories) do
                        local thisCategoryConfig = Config.ESP.Categories[categoryName]
                        if thisCategoryConfig then
                            if thisCategoryConfig.HealthDisplayType ~= nil then
                                if not thisCategoryConfig.HealthDisplayTypeOnChangeCallbackSetup then
                                    thisCategoryConfig.HealthDisplayTypeOnChangeCallbackSetup = true
                                    thisCategoryConfig.HealthDisplayType:onChange(function(newIndex)
                                        local thisHealthDisplayType = SELECTABLE_HEALTH_DISPLAY_TYPES[newIndex]
                                        if thisHealthDisplayType == HEALTH_DISPLAY_TYPES.None then
                                            thisCategoryConfig.DisplayHealthText:set(false)
                                        elseif thisHealthDisplayType == HEALTH_DISPLAY_TYPES.Text then
                                            thisCategoryConfig.DisplayHealthText:set(true)
                                        end
                                    end)
                                end
                            end
                        end
                        if Iris.Selectable({categoryName, i}, {index = SelectedCategory}).selected() then
                            CategoryChanged = true
                            NewSelectedCategory = i
                            SelectedCategory:set(i)
                        end
                    end
                    Iris.End()

                    Iris.Separator()

                    thisCategoryIndex = NewSelectedCategory or SelectedCategory:get()
                    thisCategoryName = SelectableCategories[thisCategoryIndex]
                    local thisCategoryConfig = Config.ESP.Categories[thisCategoryName]
                    if thisCategoryConfig then
                        local MaxRenderDistance = Iris.SliderNum({"Max Render Distance", 1, 0, 300}, { number = thisCategoryConfig.MaxRenderDistance })
                        if MaxRenderDistance.numberChanged() then
                            thisCategoryConfig.MaxRenderDistance:set(MaxRenderDistance.state.number:get())
                        end

                        local Shapes = Iris.Checkbox({"Shapes Enabled"}, { isChecked = thisCategoryConfig.Shapes })
                        if Shapes.checked() or Shapes.unchecked() then
                            thisCategoryConfig.Shapes:set(Shapes.state.isChecked:get())
                        end

                        local Text = Iris.Checkbox({"Text Enabled"}, { isChecked = thisCategoryConfig.Text })
                        if Text.checked() or Text.unchecked() then
                            thisCategoryConfig.Text:set(Text.state.isChecked:get())
                        end

                        local Tracers = Iris.Checkbox({"Tracers Enabled"}, { isChecked = thisCategoryConfig.Tracers })
                        if Tracers.checked() or Tracers.unchecked() then
                            thisCategoryConfig.Tracers:set(Tracers.state.isChecked:get())
                        end

                        color4Picker("Color", thisCategoryConfig.Color, thisCategoryConfig.Transparency)

                        local NumESPTypes = CountList(SELECTABLE_ESP_TYPES)
                        if NumESPTypes > 0 then
                            local thisESPTypeIndex = thisCategoryConfig.ESPType:get()
                            local thisESPType = SELECTABLE_ESP_TYPES[thisESPTypeIndex]
                            Iris.Text({"ESP Type: " .. thisESPType})
                            Iris.Combo({""}, {index = thisCategoryConfig.ESPType})
                            for i, esptype in ipairs(SELECTABLE_ESP_TYPES) do
                                Iris.Selectable({esptype, i}, {index = thisCategoryConfig.ESPType})
                            end
                            Iris.End()
                        end

                        local NumTracerOrigins = CountList(SELECTABLE_TRACER_ORIGINS)
                        if NumTracerOrigins > 0 then
                            local thisOriginIndex = thisCategoryConfig.TracerOrigin:get()
                            local thisOrigin = SELECTABLE_TRACER_ORIGINS[thisOriginIndex]
                            Iris.Text({"Tracer Origin: " .. thisOrigin})
                            Iris.Combo({""}, {index = thisCategoryConfig.TracerOrigin})
                            for i, origin in ipairs(SELECTABLE_TRACER_ORIGINS) do
                                Iris.Selectable({origin, i}, {index = thisCategoryConfig.TracerOrigin})
                            end
                            Iris.End()
                        end

                        local NumTracerTargets = CountList(SELECTABLE_TRACER_TARGETS)
                        if NumTracerTargets > 0 then
                            local thisTargetIndex = thisCategoryConfig.TracerTarget:get()
                            local thisTarget = SELECTABLE_TRACER_TARGETS[thisTargetIndex]
                            Iris.Text({"Tracer Target: " .. thisTarget})
                            Iris.Combo({""}, {index = thisCategoryConfig.TracerTarget})
                            for i, target in ipairs(SELECTABLE_TRACER_TARGETS) do
                                Iris.Selectable({target, i}, {index = thisCategoryConfig.TracerTarget})
                            end
                            Iris.End()
                        end

                        if thisCategoryConfig.MaxHealthDistance ~= nil then
                            local MaxHealthDistance = Iris.SliderNum({"Max Health Distance", 1, 0, 300}, { number = thisCategoryConfig.MaxHealthDistance})
                            if MaxRenderDistance.numberChanged() then
                                thisCategoryConfig.MaxHealthDistance:set(MaxHealthDistance.state.number:get())
                            end
                        end

                        if thisCategoryConfig.HealthDisplayType ~= nil then
                            local NumHealthDisplayTypes = CountList(SELECTABLE_HEALTH_DISPLAY_TYPES)
                            if NumHealthDisplayTypes > 0 then
                                local thisHealthDisplayTypeIndex = thisCategoryConfig.HealthDisplayType:get()
                                local thisHealthDisplayType = SELECTABLE_HEALTH_DISPLAY_TYPES[thisHealthDisplayTypeIndex]
                                Iris.Text({"Health Display Type: " .. thisHealthDisplayType})
                                Iris.Combo({""}, {index = thisCategoryConfig.HealthDisplayType})
                                for i, healthDisplayType in ipairs(SELECTABLE_HEALTH_DISPLAY_TYPES) do
                                    Iris.Selectable({healthDisplayType, i}, {index = thisCategoryConfig.HealthDisplayType})
                                end
                                Iris.End()
                            end
                        end
                        
                        if thisCategoryConfig.DisplayHealthText ~= nil then
                            local thisHealthDisplayTypeIndex = thisCategoryConfig.HealthDisplayType:get()
                            local thisHealthDisplayType = SELECTABLE_HEALTH_DISPLAY_TYPES[thisHealthDisplayTypeIndex]
                            if thisHealthDisplayType == HEALTH_DISPLAY_TYPES["Vertical Bar"] or thisHealthDisplayType == HEALTH_DISPLAY_TYPES["Horizontal Bar"] then
                                local DisplayHealthText = Iris.Checkbox({"Display Health Text"}, { isChecked = thisCategoryConfig.DisplayHealthText })
                                if DisplayHealthText.checked() or DisplayHealthText.unchecked() then
                                    thisCategoryConfig.DisplayHealthText:set(DisplayHealthText.state.isChecked:get())
                                end
                            end
                        end
                    end
                end;
            end
            Iris.End()

            Iris.Tab({"External Scripts"})
            do
                Iris.Text({"The following scripts are not owned by Brycki404 and could be altered by their owners to run malicious code! Run at your own discretion!"})
                
                if dexLoaded:get() then
                    Iris.Text("Dex++ Loaded!")
                else
                    if Iris.Button({"Run Dex++"}).clicked() then
                        dexLoaded:set(true)
                        if RunDex ~= nil and type(RunDex) == "function" then
                            task.spawn(RunDex)
                        end
                    end
                end
                
                if hydroxideLoaded:get() then
                    Iris.Text("Hydroxide Loaded!")
                else
                    if Iris.Button({"Run Hydroxide"}).clicked() then
                        hydroxideLoaded:set(true)
                        if RunHydroxide ~= nil and type(RunHydroxide) == "function" then
                            task.spawn(RunHydroxide)
                        end
                    end
                end

                if vehicleFlingLoaded:get() then
                    Iris.Text("Vehicle Fling Loaded!")
                else
                    if Iris.Button({"Run Vehicle Fling"}).clicked() then
                        vehicleFlingLoaded:set(true)
                        if RunVehicleFling ~= nil and type(RunVehicleFling) == "function" then
                            task.spawn(RunVehicleFling)
                        end
                    end
                end
            end
            Iris.End()

            Iris.Tab("Vehicles")
            do
                local CarDamageDisabled = Iris.Checkbox({"Car Damage Disabled"}, { isChecked = Config.carDamageDisabled })
                if CarDamageDisabled.checked() or CarDamageDisabled.unchecked() then
                    local newDisabled = CarDamageDisabled.state.isChecked:get()
                    Config.carDamageDisabled:set(newDisabled)
                    carDamageDisabledChanged(newDisabled)
                end

                local VehicleNoclipEnabled = Iris.Checkbox({"Vehicle Noclip Enabled"}, { isChecked = Config.vehicleNoclipEnabled })
                if VehicleNoclipEnabled.checked() or VehicleNoclipEnabled.unchecked() then
                    local newEnabled = VehicleNoclipEnabled.state.isChecked:get()
                    Config.vehicleNoclipEnabled:set(newEnabled)
                    vehicleNoclipEnabledChanged(newEnabled)
                end
                
                Iris.Group()
                do
                    local GhostriderEnabled = Iris.Checkbox({"Ghost Rider Enabled"}, { isChecked = Config.ghostriderEnabled })
                    if GhostriderEnabled.checked() or GhostriderEnabled.unchecked() then
                        local newEnabled = GhostriderEnabled.state.isChecked:get()
                        Config.ghostriderEnabled:set(newEnabled)
                        ghostriderEnabledChanged(newEnabled)
                    end

                    if GhostriderEnabled.state.isChecked:get() then
                        local nitrous = Iris.SliderNum({"Ghost Rider Nitrous Strength", 1, 0, 5000}, { number = Config.nitrous })
                        if nitrous.numberChanged() then
                            Config.nitrous:set(nitrous.state.number:get())
                        end
                        keybindWidget("Nitrous", Config.nitrousKeybind)

                        local airbrake = Iris.SliderNum({"Ghost Rider Airbrake Strength", 0.001, 0, 1}, { number = Config.airbrake })
                        if airbrake.numberChanged() then
                            Config.airbrake:set(airbrake.state.number:get())
                        end
                        keybindWidget("Airbrake", Config.airbrakeKeybind)
                    end
                end
                Iris.End()

                Iris.SeparatorText({ "Vehicles: This is Rocket League!" })

                Iris.Group()
                do
                    for i, bool: boolean in pairs(Config.rocketLeagueControls:get()) do
                        Iris.Group()
                        do
                            local ConfigDisplayName = ConfigDisplayNames[i] or i
                            local checkbox = Iris.Checkbox({ConfigDisplayName}, { isChecked = Iris.State(bool) })
                            if checkbox.checked() or checkbox.unchecked() then
                                local newBool = checkbox.state.isChecked:get()
                                local rocketLeagueControls = Config.rocketLeagueControls:get()
                                rocketLeagueControls[i] = newBool
                                Config.rocketLeagueControls:set(rocketLeagueControls)
                                rocketLeagueControlsChanged(rocketLeagueControls)
                                bool = newBool
                            end
                            if checkbox.state.isChecked:get() ~= bool then
                                warn("Desync detected for " .. i .. "! Checkbox state: " .. tostring(checkbox.state.isChecked:get()) .. " | Config value: " .. tostring(bool))
                                checkbox.state.isChecked:set(bool)
                            end

                            if checkbox.state.isChecked:get() then
                                if i == "airRollEnabled" then
                                    keybindWidget("Air Roll Left", Config.airRollLeftKeybind)
                                    keybindWidget("Air Roll Right", Config.airRollRightKeybind)

                                    local airRollStrength = Iris.SliderNum({ "Air Roll Strength" , 10000, 1000, 100000}, { number = Config.airRollStrength })
                                    if airRollStrength.numberChanged() then
                                        Config.airRollStrength:set(airRollStrength.state.number:get())
                                    end
                                elseif i == "airPitchEnabled" then
                                    keybindWidget("Air Pitch Up", Config.airPitchUpKeybind)
                                    keybindWidget("Air Pitch Down", Config.airPitchDownKeybind)

                                    local airPitchStrength = Iris.SliderNum({ "Air Pitch Strength" , 10000, 1000, 200000}, { number = Config.airPitchStrength })
                                    if airPitchStrength.numberChanged() then
                                        Config.airPitchStrength:set(airPitchStrength.state.number:get())
                                    end
                                elseif i  == "powerSlideEnabled" then
                                    keybindWidget("Power Slide Left", Config.powerSlideLeftKeybind)
                                    keybindWidget("Power Slide Right", Config.powerSlideRightKeybind)

                                    local powerSlideStrength = Iris.SliderNum({ "Power Slide Strength" , 10000, 200, 50000}, { number = Config.powerSlideStrength })
                                    if powerSlideStrength.numberChanged() then
                                        Config.powerSlideStrength:set(powerSlideStrength.state.number:get())
                                    end
                                end
                            end
                        end
                        Iris.End()
                    end
                end
                Iris.End()
            end
            Iris.End()

            Iris.Tab("Auto Farm")
            do
                Iris.Text({"Auto farming scripts that can be toggled on and off."})
                Iris.SeparatorText({"Auto Bus"})
                local AutoBusEnabled = Iris.Checkbox({"Auto Bus Enabled"}, { isChecked = autobus_enabled })
                if AutoBusEnabled.checked() or AutoBusEnabled.unchecked() then
                    local newDisabled = AutoBusEnabled.state.isChecked:get()
                    autobus_enabled:set(newDisabled)
                    if autobus_thread ~= nil then
                        task.cancel(autobus_thread)
                        autobus_thread = nil
                    else
                        autobus_thread = task.spawn(function()
                            while autobus_enabled:get() == true do
                                local bus = getMyVehicleModel()
                                local nextStopName = LocalPlayer:GetAttribute("LastBusStation")
                                
                                if bus and nextStopName then
                                    if masterBusLocations[nextStopName] then
                                        executeTeleport(bus, masterBusLocations[nextStopName])
                                    else
                                        for _, stop in ipairs(CollectionService:GetTagged("BusStop")) do
                                            if stop.Name == nextStopName then
                                                local pad = stop:FindFirstChild("Pad")
                                                if pad then
                                                    masterBusLocations[nextStopName] = pad.CFrame
                                                    if saveLocations and type(saveLocations) == "function" then
                                                        saveLocations()
                                                    end
                                                    executeTeleport(bus, pad.CFrame)
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end
                                task.wait(0.1)
                            end
                        end)
                    end
                end
                Iris.Separator()
            end
            Iris.End()

            Iris.Tab({"Other"})
            do
                local tpTree = Iris.Tree({ "Lerp Teleporting" })
                do
                    if tpTree.state.isUncollapsed:get() then
                        Iris.Text({ "You can cancel a Lerp Teleport using getgenv().CancelLerpTeleport(),\nby calling a new Lerp Teleport," })
                        Iris.SameLine()
                            Iris.Text({ "or by pressing this button:" })
                            if Iris.Button({"Cancel Current Lerp Teleport"}).clicked() then
                                if CancelLerpTeleport then
                                    CancelLerpTeleport()
                                end
                            end
                        Iris.End()

                        if CurrentTeleportingConnection then
                            local currentTree = Iris.Tree({ "Current Lerp Teleport Status" })
                            do
                                if currentTree.state.isUncollapsed:get() then
                                    local components = {TargetPosition.X, TargetPosition.Y, TargetPosition.Z}
                                    for i,v in ipairs(components) do
                                        if v then
                                            components[i] = math.round(v * 100) / 100
                                        end
                                    end

                                    Iris.Text({ string.format("Target Position: (%.2f, %.2f, %.2f)", table.unpack(components)) })
                                    Iris.Text({ "Progress: " .. string.format("%.2f", (Alpha or 0) * 100) .. "%" })
                                    Iris.Text({ "Elapsed Time: " .. FormatHours(Elapsed or 0) })
                                    Iris.Text({ "Total Duration: " .. FormatHours(Duration or 10) })
                                end
                            end
                            Iris.End()
                        end

                        local howtoTree = Iris.Tree({ "How to use:" })
                        do
                            if howtoTree.state.isUncollapsed:get() then
                                Iris.Text({"Lerp Teleporting is available as a global function: getgenv().LerpTeleport(target: Vector3, duration: number): ()"})
                                Iris.Text({"You can use it to smoothly teleport your character to a target position over a specified duration."})
                                Iris.Text({ "Example usage: getgenv().LerpTeleport(Vector3.new(0, 50, 0), 2)" })
                                Iris.Text({ "\nYou can also use the following global helper function to get the duration for a given distance under a constant travelling speed constraint." })
                                Iris.Text({ "getgenv().GetDurationFromDistance(distance: number, speed: number): (number)" })
                                Iris.Text({ "Example usage: getgenv().GetDurationFromDistance(250, 75)" })
                            end
                        end
                        Iris.End()
                    end
                end
                Iris.End()

                local antiTree = Iris.Tree({ "Anti Toggles" })
                do
                    if antiTree.state.isUncollapsed:get() then
                        for i, bool: boolean in pairs(Config.antis:get()) do
                            local ConfigDisplayName = ConfigDisplayNames[i] or i
                            local checkbox = Iris.Checkbox({ConfigDisplayName}, { isChecked = Iris.State(bool) })
                            if checkbox.checked() or checkbox.unchecked() then
                                local newBool = checkbox.state.isChecked:get()
                                local antis = Config.antis:get()
                                antis[i] = newBool
                                Config.antis:set(antis)
                                antisChanged(antis)
                                bool = newBool
                            end
                            if checkbox.state.isChecked:get() ~= bool then
                                warn("Desync detected for " .. i .. "! Checkbox state: " .. tostring(checkbox.state.isChecked:get()) .. " | Config value: " .. tostring(bool))
                                checkbox.state.isChecked:set(bool)
                            end
                        end
                    end
                end
                Iris.End()

                local toolsTree = Iris.Tree({ "Tools" })
                do
                    if toolsTree.state.isUncollapsed:get() then
                        local hitboxExtendTool = Iris.Button({"Extend Hitbox (Melee)"})
                        if hitboxExtendTool.clicked() then
                            extendToolHitbox()
                        end

                        if ak47Tampered == false then
                            local TamperAK47 = Iris.Button({"Tamper AK47"})
                            if ak47Tampered == false and TamperAK47.clicked() then
                                ak47Tampered = true
                                tamperGun("AK47")
                            end
                        end
                    end
                end
                Iris.End()
            end
            Iris.End()
        end
        Iris.End()
    end
    Iris.End()

    if Config.showRuntimeInfo.value then
        runtimeInfo()
    end
    if Config.showDebugWindow.value then
        debugPanel()
    end
    if Config.showStyleEditor.value then
        styleEditor()
    end

    if EXECUTOR_FILING_ENABLED then
        if choosingConfig_open:get() then
            local chooseWindow = Iris.Window({ "Open Config" }, {
                size = Iris.State(Vector2.new(300, 200));
                isOpened = choosingConfig_open;
            })
            if chooseWindow.state.isOpened:get() and chooseWindow.state.isUncollapsed:get() then
                local files = listfiles(CONFIG_DIRECTORY_PATH)

                for _, filePath in ipairs(files) do
                    -- Extract just the filename (no path)
                    local fileName = filePath:match("([^/\\]+)$")
                    -- Only continue if it's a .json file
                    if fileName and fileName:match("%.json$") then
                        fileName = fileName:sub(1, -6) -- Remove the .json extension for display
                        if Iris.Button({ fileName }).clicked() then
                            choosingConfig_open:set(false)
                            LoadIrisConfig(filePath)
                        end
                    end
                end
            end
            Iris.End()
        elseif choosingConfig_save:get() then
            local chooseWindow = Iris.Window({ "Save Config" }, {
                size = Iris.State(Vector2.new(300, 200));
                isOpened = choosingConfig_save;
            })
            if chooseWindow.state.isOpened:get() and chooseWindow.state.isUncollapsed:get() then
                local files = listfiles(CONFIG_DIRECTORY_PATH)

                for _, filePath in ipairs(files) do
                    -- Extract just the filename (no path)
                    local fileName = filePath:match("([^/\\]+)$")
                    -- Only continue if it's a .json file
                    if fileName and fileName:match("%.json$") then
                        fileName = fileName:sub(1, -6) -- Remove the .json extension for display
                        if Iris.Button({ fileName }).clicked() then
                            choosingConfig_save:set(false)
                            SaveIrisConfig(filePath)
                        end
                    end
                end

                if Iris.Button({ "[Save To New Config]" }).clicked() then
                    choosingConfig_save:set(false)
                    typingCustomConfig_save:set(true)
                end
            end
            Iris.End()
        end
        if typingCustomConfig_save.value then
            local promptWindow = Iris.Window({ "Enter Config Name" }, { isOpened = typingCustomConfig_save })
            -- the promptWindow has opened and uncollapsed states, which return booleans
            if promptWindow.state.isOpened:get() and promptWindow.state.isUncollapsed:get() then
                local textInputWidget = nil
                Iris.SameLine()
                do
                    Iris.Text({ "Enter a Config Name: " })
                    textInputWidget = Iris.InputText({ "" }, { text = Iris.WeakState("Default") })
                end
                Iris.End()
                Iris.SameLine()
                do
                    local continueButton = Iris.Button({ "Continue" })
                    local cancelButton = Iris.Button({ "Cancel" })
                    if continueButton.clicked() then
                        local configName = textInputWidget.state.text:get()
                        if configName and configName ~= "" then
                            SaveIrisConfig(CONFIG_DIRECTORY_PATH .. "\\" .. configName .. ".json")
                        end
                        typingCustomConfig_save:set(false)
                    end
                    if cancelButton.clicked() then
                        typingCustomConfig_save:set(false)
                    end
                end
                Iris.End()
            end
            Iris.End()
        end
    end
end)

--Anti AFK
local VirtualUser = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

--Virtual Input (for keyboard inputs)
local VirtualInputManager = game:GetService("VirtualInputManager")
function genv.sendkeyevent(isPressed: boolean, keyCode: Enum.KeyCode)
    assert(isPressed ~= nil, "[ERROR] sendkeyevent parameter[1] \"isPressed\" must be a boolean!")
    assert(keyCode ~= nil, "[ERROR] sendkeyevent parameter[2] \"keyCode\" must be an Enum.KeyCode!")
    if VirtualInputManager and VirtualInputManager.SendKeyEvent then
        VirtualInputManager:SendKeyEvent(isPressed, keyCode, false, nil)
    else
        warn("VirtualInputManager isn't accessible")
    end
end

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
    if not gameProcessedEvent then
        for _, keyCodeName in ipairs(Config.windowKeyCode:get()) do
            if keyCodeName == nil or keyCodeName == "" or keyCodeName == "None" then
                continue
            end
            local keyCode = Enum.KeyCode[keyCodeName]
            if keyCode and input.KeyCode == keyCode then
                Config.showMainWindow:set(not Config.showMainWindow:get())
            end
        end
    end
end)

--ESP
do
    local ESPList = {}

    function DrawGenericShape(entry, calculations)
        local thisConfig = nil
        local thisESPTypeIndex = nil
        local thisESPType = nil
        local thisTracerOriginIndex = nil
        local thisTracerOrigin = nil
        local thisTracerTargetIndex = nil
        local thisTracerTarget = nil
        if entry.Category then
            thisConfig = Config.ESP.Categories[entry.Category]
            if thisConfig then
                thisESPTypeIndex = thisConfig.ESPType:get()
                thisESPType = SELECTABLE_ESP_TYPES[thisESPTypeIndex]

                thisTracerOriginIndex = thisConfig.TracerOrigin:get()
                thisTracerOrigin = SELECTABLE_TRACER_ORIGINS[thisTracerOriginIndex]

                thisTracerTargetIndex = thisConfig.TracerTarget:get()
                thisTracerTarget = SELECTABLE_TRACER_TARGETS[thisTracerTargetIndex]
            end
        end

        local CF = calculations.CF
        local Size = calculations.Size
        local ViewportPoint = calculations.ViewportPoint
        local ScreenPosition = calculations.ScreenPosition
        local ScreenSize = calculations.ScreenSize
        local OnScreen = calculations.OnScreen
        local ScreenPoints = calculations.ScreenPoints
        local Anchors = calculations.Anchors
        local FailedRenderDistance = calculations.FailedRenderDistance

        local baseZIndex = 1
        local bumpZIndex = thisConfig.ZIndexBump and type(thisConfig.ZIndexBump) == "number" and thisConfig.ZIndexBump or 0
        bumpZIndex = math.ceil(math.max(0, bumpZIndex))
        baseZIndex += bumpZIndex

        local drawing = nil
        local properties = {}
        properties.color = thisConfig and thisConfig.Color:get() or nil
        properties.visible = Config.ESP.MasterShapes:get() and (thisConfig and thisConfig.Shapes:get() or false) == true and OnScreen and not FailedRenderDistance or false
        properties.tracer = Config.ESP.MasterTracers:get() == true and (thisConfig and thisConfig.Tracers:get() or false) == true and ViewportPoint.Z > 0 and {} or nil
        if properties.tracer then
            properties.tracer.origin = thisTracerOrigin
            properties.tracer.target = thisTracerTarget
            properties.tracer.color = properties.color
        end

        local transparency = 1 - (thisConfig and thisConfig.Transparency:get()/255 or 0) --opposite from Roblox's Transparency!!!

        if thisConfig and thisESPType == ESP_TYPES.Box then
            --Box
            properties.data = {}
            properties.data.ZIndex = baseZIndex
            properties.data.Transparency = transparency
            properties.data.ScreenPoints = ScreenPoints
            properties.data.Anchors = Anchors
            
            drawing = ESP:createBox3D(properties)
        elseif thisConfig and thisESPType == ESP_TYPES.Quad then
            --Quad
            properties.data = {}
            properties.data.ZIndex = baseZIndex
            properties.data.Transparency = transparency
            properties.data.ScreenPoints = ScreenPoints
            properties.data.Anchors = Anchors

            drawing = ESP:createRect3D(properties)
        else
            --Rect
            properties.data = {}
            properties.data.ZIndex = baseZIndex
            properties.data.Transparency = transparency
            properties.data.ScreenPoints = ScreenPoints
            properties.data.Anchors = Anchors
            
            drawing = ESP:createRect2D(properties)
        end

        return drawing
    end

    function DrawText(entry, calculations)
        local thisConfig = nil
        if entry.Category then
            thisConfig = Config.ESP.Categories[entry.Category]
        end

        local OnScreen = calculations.OnScreen
        if not OnScreen then
            return nil
        end

        local visible = Config.ESP.MasterText:get() and (thisConfig and thisConfig.Text:get() or true)
        if not visible then
            return nil
        end

        local FailedRenderDistance = calculations.FailedRenderDistance
        if FailedRenderDistance then
            return nil
        end

        local CF = calculations.CF
        local Size = calculations.Size
        local ViewportPoint = calculations.ViewportPoint
        local ScreenPosition = calculations.ScreenPosition
        local ScreenSize = calculations.ScreenSize
        local Anchors = calculations.Anchors
        
        local baseZIndex = 91
        local bumpZIndex = thisConfig.ZIndexBump and type(thisConfig.ZIndexBump) == "number" and thisConfig.ZIndexBump or 0
        bumpZIndex = math.ceil(math.max(0, bumpZIndex))
        baseZIndex += bumpZIndex

        local properties = {}
        properties.color = thisConfig and thisConfig.Color:get() or nil
        properties.data = {}
        properties.data.ZIndex = baseZIndex
        properties.data.Transparency = 1
        properties.data.Text = entry.DisplayName
        properties.data.Pos = Vector2.new(math.floor(ScreenPosition.X+0.5), math.floor(ScreenPosition.Y+0.5))
        
        local drawing = ESP:createText(properties)

        return drawing
    end

    function DrawHealthbar(entry, calculations, displayType)
        if displayType == HEALTH_DISPLAY_TYPES.None then return nil end
        if not entry.Humanoid then return nil end

        local thisConfig = nil
        if entry.Category then
            thisConfig = Config.ESP.Categories[entry.Category]
        end

        local maxHealth = entry.Humanoid.MaxHealth
        local health = math.clamp(entry.Humanoid.Health, 0, maxHealth)
        local healthString = string.format("hp: %d/%d", math.ceil(health), math.ceil(maxHealth))
        local healthFraction = health/maxHealth

        local OnScreen = calculations.OnScreen
        if not OnScreen then
            return nil
        end

        local visible = Config.ESP.MasterText:get() and (thisConfig and thisConfig.Text:get() or true)
        if not visible then
            return nil
        end

        local FailedHealthDistance = calculations.FailedHealthDistance
        if FailedHealthDistance then
            return nil
        end

        local CF = calculations.CF
        local Size = calculations.Size
        local ViewportPoint = calculations.ViewportPoint
        local ScreenPosition = calculations.ScreenPosition
        local ScreenSize = calculations.ScreenSize
        local Anchors = calculations.Anchors

        local baseZIndex = 51
        local bumpZIndex = thisConfig.ZIndexBump and type(thisConfig.ZIndexBump) == "number" and thisConfig.ZIndexBump or 0
        bumpZIndex = math.ceil(math.max(0, bumpZIndex))
        baseZIndex += 3 * bumpZIndex

        local drawings = {}

        -- Based on ScreenPosition and ScreenSize to move the bar where I want it relative to the Model
        local textBoxWidth = ScreenSize.X
        local textBoxHeight = math.min(30, ScreenSize.Y * 0.15)
        local textBoxPos = Anchors.Top - Vector2.yAxis * textBoxHeight * 1.5
        
        local transparency = 1 - (thisConfig and thisConfig.Transparency:get()/255 or 0) --opposite from Roblox's Transparency!!!

        --BoxFill

        local fillproperties = {}
        fillproperties.data = {}
        fillproperties.data.ZIndex = baseZIndex
        fillproperties.data.Filled = true
        fillproperties.data.FillColor = Color3.new(1)
        fillproperties.data.FillTransparency = 1 - (1 - transparency) * (1 - 0.35) --opposite from Roblox's Transparency!!!
        fillproperties.data.Transparency = 0
        fillproperties.data.Thickness = 0

        --BoxOutline

        local outlineproperties = {}
        outlineproperties.data = {}
        outlineproperties.data.ZIndex = baseZIndex + 1
        outlineproperties.data.Transparency = transparency
        outlineproperties.data.Thickness = 1

        --Text

        local textproperties = {}
        textproperties.data = {}
        textproperties.data.ZIndex = baseZIndex + 2
        textproperties.data.Transparency = 1
        textproperties.data.Text = healthString
        textproperties.data.Pos = Vector2.new(math.floor(textBoxPos.X+0.5), math.floor(textBoxPos.Y+0.5))

        if displayType == HEALTH_DISPLAY_TYPES["Vertical Bar"] then
            local barWidth = math.min(30, ScreenSize.X * 0.15)
            local barHeight = ScreenSize.Y

            local barScreenPoints = {
                TopLeft = Anchors.TopLeft - Vector2.xAxis * barWidth;
                TopRight = Anchors.TopLeft;
                BottomRight = Anchors.BottomLeft;
                BottomLeft = Anchors.BottomLeft - Vector2.xAxis * barWidth;
            }

            local fillHeight = barHeight * healthFraction

            local fillScreenPoints = {
                TopLeft = barScreenPoints.BottomLeft - Vector2.yAxis * fillHeight;
                TopRight = barScreenPoints.BottomRight - Vector2.yAxis * fillHeight;
                BottomRight = barScreenPoints.BottomRight;
                BottomLeft = barScreenPoints.BottomLeft;
            }

            -- Fill anchored to the bottom\

            fillproperties.data.ScreenPoints = fillScreenPoints
            outlineproperties.data.ScreenPoints = barScreenPoints

            drawings.filling = ESP:createRect2D(fillproperties)
            drawings.outline = ESP:createRect2D(outlineproperties)
        elseif displayType == HEALTH_DISPLAY_TYPES["Horizontal Bar"] then
            local barWidth = textBoxWidth
            local barHeight = textBoxHeight
            local barScreenPoints = {
                TopLeft = Anchors.TopLeft - Vector2.xAxis * barHeight;
                TopRight = Anchors.TopLeft - Vector2.xAxis * barHeight;
                BottomRight = Anchors.TopRight;
                BottomLeft = Anchors.TopRight;
            }
            
            local fillWidth = barWidth * healthFraction

            local fillScreenPoints = {
                TopLeft = barScreenPoints.TopLeft;
                TopRight = barScreenPoints.TopLeft + Vector2.xAxis * fillWidth;
                BottomRight = barScreenPoints.BottomLeft + Vector2.xAxis * fillWidth;
                BottomLeft = barScreenPoints.BottomLeft;
            }

            -- Fill anchored to the left

            fillproperties.data.ScreenPoints = fillScreenPoints
            outlineproperties.data.ScreenPoints = barScreenPoints

            drawings.filling = ESP:createRect2D(fillproperties)
            drawings.outline = ESP:createRect2D(outlineproperties)
        end

        drawings.textlabel = ESP:createText(textproperties)

        return drawings
    end

    function DrawGenericESP(entry)
        if not entry.Model or not entry.Part then
            return nil
        end

        local thisConfig = nil
        local thisESPTypeIndex = nil
        local thisESPType = nil
        if entry.Category then
            thisConfig = Config.ESP.Categories[entry.Category]
            if thisConfig then
                if thisConfig.ESPType ~= nil then
                    thisESPTypeIndex = thisConfig.ESPType:get()
                    thisESPType = SELECTABLE_ESP_TYPES[thisESPTypeIndex]
                end
            end
        end
        local calculations = nil
        if thisESPType == ESP_TYPES.Box then
            calculations = ESP.CalculateBox3D(entry.Model)
        elseif thisESPType == ESP_TYPES.Quad then
            calculations = ESP.CalculateRect3D(entry.Model)
        else
            --Rect
            --also when Category == nil -> "default" category
            calculations = ESP.CalculateRect2D(entry.Model)
        end

        local itsPos = calculations and calculations.CF and calculations.CF.Position or nil
        if not itsPos then
            return nil
        end
        
        local MyDistanceSquared = ESP.GetMyDistanceSquared(itsPos)
        if MyDistanceSquared then
            local MaxRenderDistanceSquared = math.min(Config.ESP.MasterMaxRenderDistance:get() or 20000, (thisConfig ~= nil and thisConfig.MaxRenderDistance ~= nil and type(thisConfig.MaxRenderDistance:get()) == "number" and thisConfig.MaxRenderDistance:get()) or 20000)
            if MaxRenderDistanceSquared and type(MaxRenderDistanceSquared) == "number" then
                --Unsquared, so Square it
                MaxRenderDistanceSquared = MaxRenderDistanceSquared * MaxRenderDistanceSquared
                calculations.FailedRenderDistance = MyDistanceSquared > MaxRenderDistanceSquared
            else
                MaxRenderDistanceSquared = math.huge
                calculations.FailedRenderDistance = false
            end
            local MaxHealthDistanceSquared = (thisConfig ~= nil and thisConfig.MaxHealthDistance ~= nil and type(thisConfig.MaxHealthDistance:get()) == "number" and thisConfig.MaxHealthDistance:get() or 300)
            if MaxHealthDistanceSquared and type(MaxHealthDistanceSquared) == "number" then
                --Unsquared, so Square it
                MaxHealthDistanceSquared = MaxHealthDistanceSquared * MaxHealthDistanceSquared
                calculations.FailedHealthDistance = MyDistanceSquared > MaxHealthDistanceSquared
            end
        else
            calculations.FailedRenderDistance = false
            calculations.FailedHealthDistance = false
        end

        local drawings = {}

        if entry.Category == "Player" then
            if not thisConfig then
                return nil
            end

            local healthDisplayTypeIndex = thisConfig.HealthDisplayType:get()
            local healthDisplayType = SELECTABLE_HEALTH_DISPLAY_TYPES[healthDisplayTypeIndex]

            drawings.Shape = DrawGenericShape(entry, calculations)
            drawings.Text = DrawText(entry, calculations)
            drawings.Healthbar = DrawHealthbar(entry, calculations, healthDisplayType)

        else
            --"default" category, when Category == nil
            drawings.Shape = DrawGenericShape(entry, calculations)
            drawings.Text = DrawText(entry, calculations)
        end

        return drawings
    end

    function Draw(model, params)
        local displayName = params.DisplayName
        local category = params.Category
        local part = params.Part
        local humanoid = params.Humanoid

        local id = tostring(model:GetDebugId())
        local entry = {
            id = id;
            DisplayName = displayName;
            Category = category;
            Model = model;
            Part = part;
            Humanoid = humanoid;
        }
        ESPList[id] = entry
    end

    function makeESP(Model: Instance)
        if not Model or not Model:IsA("BasePart") and not Model:IsA("Model") then
            return
        end
        local id = tostring(Model:GetDebugId())
        if not ESPList[id] then
           if Model:IsDescendantOf(workspace) and Model:IsA("Model") then
                local Humanoid = Model:FindFirstChildOfClass("Humanoid")
                if Humanoid then
                    local gotPlayer = Players:GetPlayerFromCharacter(Model)
                    if gotPlayer then
                        if gotPlayer ~= LocalPlayer then
                            Draw(Model, {
                                Part = Model.PrimaryPart or Model:FindFirstChild("HumanoidRootPart");
                                DisplayName = gotPlayer.Name;
                                Category = "Player";
                                Humanoid = Humanoid;
                            })
                        end
                    end
                end
            end
        end
    end

    for i: number, v: Instance in ipairs(workspace.Characters:GetChildren()) do
        task.spawn(function()
            if v:IsA("Model") then
                if v:FindFirstChildOfClass("Humanoid") then
                    makeESP(v)
                end
            end
        end)
    end

    local workspace_child_added_connection = workspace.Characters.ChildAdded:Connect(function(v)
        task.spawn(makeESP, v)
    end)

    local function drawFunction()
        for modelId, entry in pairs(ESPList) do
            if not entry.Model or not entry.Part or not entry.Model:IsDescendantOf(workspace) or not entry.Part:IsDescendantOf(workspace) then
                table.clear(entry)
                entry = nil
                continue
            end
            DrawGenericESP(entry)
        end
    end

    local esp_update_draw_thread = task.spawn(function()
        while true do
            ESP:render(drawFunction)
            RunService.RenderStepped:Wait()
        end
    end)
end
