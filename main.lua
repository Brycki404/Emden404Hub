local SCRIPT_NAME = "Emden404Hub"
local SCRIPT_VERSION = {
    --Semantic Versioning
    Major = 1;
    Minor = 0;
    Patch = 0;
}

local genv = getgenv()

if not BetterLib then
    local OldGet = game.HttpGet or game.HttpGetAsync or nil
    assert(OldGet, "No HttpGet function found.")
    -- Load BetterLib first (if it's not already loaded), since every other loaded stuff will depend on it. If BetterLib fails to load, everything else won't work, but at least the error will be more informative.
    loadstring(OldGet(game, "https://raw.githubusercontent.com/Brycki404/BetterLib/refs/heads/main/main.lua", true))()
end
-- Begin Script:

-- Load Dependencies:

if not Iris then
    local IrisLoaderUrl = "https://raw.githubusercontent.com/Brycki404/Iris/refs/heads/main/loader.lua"
    genv.Iris = loadstring(Get(IrisLoaderUrl))()
end

if not ESP then
    local ESP404LibUrl = "https://raw.githubusercontent.com/Brycki404/ESP404Lib/refs/heads/main/main.lua"
    genv.ESP = loadstring(Get(ESP404LibUrl))()
end

-- Loaded Dependencies!

-- Generic Helpers
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

-- Setup executor workspace file directory for saving configs and settings:

--Check Executor Has Global Function
function genv.CEHGF(name: string): boolean
    if genv[name] and type(genv[name]) == "function" then
        return true
    end
    return false
end

genv.EXECUTOR_FILING_FUNCTIONS = {
    "readfile";
    "listfiles";
    "writefile";
    "makefolder";
    "appendfile";
    "isfile";
    "isfolder";
    "delfile";
    "delfolder";
    "loadfile";
    "dofile";
}

genv.EXECUTOR_FILING_ENABLED = true
for i, name in ipairs(EXECUTOR_FILING_FUNCTIONS) do
    if not CEHGF(name) then
        EXECUTOR_FILING_ENABLED = false
        break
    end
end

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

genv.Config = {
    ["showMainWindow"] = Iris.State(true);
    ["showBackground"] = Iris.State(false);
    ["backgroundColor"] = Iris.State(Color3.fromRGB(115, 140, 152));
    ["backgroundTransparency"] = Iris.State(0);
    ["showRuntimeInfo"] = Iris.State(false);
    ["showStyleEditor"] = Iris.State(false);
    ["showDebugWindow"] = Iris.State(false);
    --Referring to Iris' GlobalConfig:
    ["IrisSizingConfig"] = Iris.State({});
    ["IrisColorsConfig"] = Iris.State({});
    ["IrisFontsConfig"] = Iris.State({});

    ["windowKeyCode"] = Iris.State("F3");

    ["antis"] = Iris.State({
        ["antiCuffEnabled"] = false;
        ["antiRagdollEnabled"] = false;
        ["antiTazerEnabled"] = false;
        ["antiHackBypassEnabled"] = false;
    });
    ["carDamageDisabled"] = Iris.State(false);
    ["vehicleNoclipEnabled"] = Iris.State(false);

    ["ESP"] = {
        ["MasterMaxRenderDistance"] = Iris.State(20000);
        ["MasterShapes"] = Iris.State(true);
        ["MasterText"] = Iris.State(true);
        ["MasterTracers"] = Iris.State(false);
        ["Categories"] = {
            ["Player"] = {
                ["MaxRenderDistance"] = Iris.State(20000);
                ["Shapes"] = Iris.State(true);
                ["Text"] = Iris.State(true);
                ["Tracers"] = Iris.State(false);
                ["Color"] = Iris.State(Color3.new(1, 1, 1));
                ["Transparency"] = Iris.State(0);
                ["ESPType"] = Iris.State(initESPType);
                ["TracerOrigin"] = Iris.State(initTracerOrigin);
                ["TracerTarget"] = Iris.State(initTracerTarget);

                ["MaxHealthDistance"] = Iris.State(300);
                ["HealthDisplayType"] = Iris.State(initHealthDisplayType);
                ["DisplayHealthText"] = Iris.State(true);
            };
        };
    };
}

local SelectableCategories = {
    [1] = "None";
    [2] = "Player";
};
local SelectedCategory = Iris.State(1);

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

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

local function extendToolHitbox()
    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    local handle = tool:FindFirstChild("Handle")
    if not handle then return end
    if typeof(handle) ~= "BasePart" then return end
    local a = Instance.new("SelectionBox", handle)
    a.Adornee = handle
    handle.Size=Vector3.new(20, 20, 20)
    handle.Transparency = 1
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

local function keybindButton(text: string, state)
    Iris.SameLine()
    do
        Iris.Text({ text })
        -- the button has a clicked event, returning true when it is pressed
        if Iris.Button({state:get()}).clicked() then
            -- run code if we click the button
            UserInputService.InputBegan:Once(function(input: InputObject, gameProcessedEvent: boolean)
                if not gameProcessedEvent then
                    if input.KeyCode and input.KeyCode.Name then
                        state:set(input.KeyCode.Name)
                    end
                end
            end)
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

local function mainMenuBar()
    Iris.MenuBar()
    do
        Iris.Menu({ "Configs" })
        do
            Iris.MenuItem({ "New" })
            Iris.MenuItem({ "Open" })
            Iris.MenuItem({ "Save" })
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
        keybindButton("Toggle UI Keybind", Config.windowKeyCode)

        mainMenuBar()

        Iris.TabBar()
        do
            Iris.Tab({"ESP"})
            do
                Iris.SeparatorText({"Master Settings"})

                local MasterMaxRenderDistance = Iris.DragNum({"Max Render Distacne", 1, 0, 20000}, { number = Config.ESP.MasterMaxRenderDistance })
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

            Iris.Tab({"Other"})
            do
                for i, bool: boolean in pairs(Config.antis:get()) do
                    local ConfigDisplayName = ConfigDisplayNames[i] or i
                    local checkbox = Iris.Checkbox({ConfigDisplayName}, { isChecked = Iris.WeakState(bool) })
                    if checkbox.checked() or checkbox.unchecked() then
                        local newBool = checkbox.state.isChecked:get()
                        local antis = Config.antis:get()
                        antis[i] = newBool
                        Config.antis:set(antis)
                        antisChanged(antis)
                    end
                end

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
end)

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
        local validWindowKeyCode = Enum.KeyCode[Config.windowKeyCode:get()]
        if validWindowKeyCode then
            if input.KeyCode == validWindowKeyCode then
                Config.showMainWindow:set(not Config.showMainWindow:get())
            end
        end
    end
end)

local MapFolder = workspace:FindFirstChild("map")
local NPCFolder = MapFolder:FindFirstChild("NPC")

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
            return
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
            return
        end
        
        local MyDistanceSquared = ESP.GetMyDistanceSquared(itsPos)
        local MaxRenderDistanceSquared = math.min(Config.ESP.MasterMaxRenderDistance:get() or 20000, (thisConfig ~= nil and thisConfig.MaxRenderDistance ~= nil and thisConfig.MaxRenderDistance:get()) or 20000)
        if MaxRenderDistanceSquared and type(MaxRenderDistanceSquared) == "number" then
            --Unsquared, so Square it
            MaxRenderDistanceSquared = MaxRenderDistanceSquared * MaxRenderDistanceSquared
            calculations.FailedRenderDistance = MyDistanceSquared > MaxRenderDistanceSquared
        else
            MaxRenderDistanceSquared = math.huge
            calculations.FailedRenderDistance = false
        end
        local MaxHealthDistanceSquared = (thisConfig ~= nil and thisConfig.MaxHealthDistance ~= nil and thisConfig.MaxHealthDistance:get() or 300)
        if MaxHealthDistanceSquared and type(MaxHealthDistanceSquared) == "number" then
            --Unsquared, so Square it
            MaxHealthDistanceSquared = MaxHealthDistanceSquared * MaxHealthDistanceSquared
            calculations.FailedHealthDistance = MyDistanceSquared > MaxHealthDistanceSquared
        end

        if entry.Category == "NPC" then
            if not thisConfig then
                return
            end

            DrawGenericShape(entry, calculations)
            DrawText(entry, calculations)

        elseif entry.Category == "Interactable" then
            if not thisConfig then
                return
            end

            DrawGenericShape(entry, calculations)
            DrawText(entry, calculations)

        elseif entry.Category == "Enemy" then
            if not thisConfig then
                return
            end

            local healthDisplayTypeIndex = thisConfig.HealthDisplayType:get()
            local healthDisplayType = SELECTABLE_HEALTH_DISPLAY_TYPES[healthDisplayTypeIndex]

            DrawGenericShape(entry, calculations)
            DrawText(entry, calculations)
            DrawHealthbar(entry, calculations, healthDisplayType)
            
        elseif entry.Category == "Player" then
            if not thisConfig then
                return
            end

            local healthDisplayTypeIndex = thisConfig.HealthDisplayType:get()
            local healthDisplayType = SELECTABLE_HEALTH_DISPLAY_TYPES[healthDisplayTypeIndex]

            DrawGenericShape(entry, calculations)
            DrawText(entry, calculations)
            DrawHealthbar(entry, calculations, healthDisplayType)

        else
            --"default" category, when Category == nil
            DrawGenericShape(entry, calculations)
            DrawText(entry, calculations)
        end
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
            if Model:IsDescendantOf(NPCFolder) then
                if Model.Name == "ChatBox" then
                    if Model.Parent:FindFirstChildOfClass("Humanoid") then
                        Draw(Model, {
                            Part = Model;
                            DisplayName = Model.Parent.Name;
                            Category = "NPC";
                        })
                    else
                        Draw(Model, {
                            Part = Model;
                            DisplayName = Model.Parent.Name;
                            Category = "Interactable";
                        })
                    end
                end
            elseif Model:IsDescendantOf(workspace) and Model:IsA("Model") then
                local Humanoid = Model:FindFirstChildOfClass("Humanoid")
                if Humanoid then
                    local gotPlayer = Players:GetPlayerFromCharacter(Model)
                    if not gotPlayer then
                        Draw(Model, {
                            Part = Model.PrimaryPart or Model:FindFirstChild("HumanoidRootPart");
                            DisplayName = Model.Name;
                            Category = "Enemy";
                            Humanoid = Humanoid;
                        })
                    elseif gotPlayer then
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

    for i: number, v: Instance in ipairs(workspace:GetChildren()) do
        task.spawn(function()
            if v:IsA("Model") then
                if v:FindFirstChildOfClass("Humanoid") then
                    makeESP(v)
                end
            end
        end)
    end

    for i: number, v: Instance in ipairs(workspace:GetDescendants()) do
        task.spawn(function()
            if v:IsDescendantOf(NPCFolder) then
                local Humanoid = v:FindFirstChildOfClass("Humanoid")
                if Humanoid then
                    makeESP(v)
                else
                    if v.Name == "ChatBox" then
                        makeESP(v)
                    end
                end
            end
        end)
    end

    local workspace_child_added_connection = workspace.ChildAdded:Connect(function(v)
        task.spawn(makeESP, v)
    end)

    local npc_descendant_added_connection = NPCFolder.DescendantAdded:Connect(function(v)
        task.spawn(makeESP, v)
    end)

    local function drawFunction()
        for modelId, entry in pairs(ESPList) do
            if not entry.Model or not entry.Part then
                table.clear(entry)
                entry = nil
                continue
            end
            DrawGenericESP(entry)
        end
    end

    local esp_update_draw_connection = RunService.RenderStepped:Connect(function()
        ESP:render(drawFunction)
    end)
end
