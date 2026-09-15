--[[
    DEV AIM / ESP / FULLBRIGHT
    Roblox Luau - mobile friendly

    Changes in this version:
    • Aim snaps instantly (no Lerp / no smoothing)
    • Smaller responsive menu for phones
    • ESP rebuilt with Highlight + BillboardGui so it is visible reliably
    • Tracer is kept as a normal GUI element
    • Sliders are touch friendly
    • FOV circle stays centered and resizes correctly
    • Optional executor file configs are kept

    For testing in your own Roblox experience.
    LocalScript -> StarterPlayer > StarterPlayerScripts
]]

--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// CONFIG
local Config = {
    SilentAim = false,
    VisibilityCheck = true,
    DistanceCheck = true,
    Distance = 500,
    Bhop = false,
    FOV = 120,
    HitChance = 100,
    Bhop = false,

    FOVCircle = true,
    FOVNumSides = 64,
    FOVThickness = 2,

    ESPBox = true,
    ESPName = true,
    ESPHealth = true,
    ESPTracer = false,
    ESPColor = Color3.fromRGB(0, 170, 255),

    FullBright = false,
    Brightness = 2,
    ClockTime = 14,
    Fog = true,

    ConfigName = "default"
}

local DefaultConfig = {}
for key, value in pairs(Config) do
    DefaultConfig[key] = value
end

--// FILE CONFIG
local CONFIG_FOLDER = "DevAimConfigs"
local LAST_CONFIG_FILE = CONFIG_FOLDER .. "/last.txt"
local BUTTON_POSITION_FILE = CONFIG_FOLDER .. "/button_position.json"
local BUTTON_LOCK_FILE = CONFIG_FOLDER .. "/button_lock.txt"

local DEFAULT_BUTTON_X = 14
local DEFAULT_BUTTON_Y_FROM_BOTTOM = 58

local function canUseFiles()
    return typeof(writefile) == "function"
        and typeof(readfile) == "function"
        and typeof(isfile) == "function"
        and typeof(makefolder) == "function"
end

local function serializeValue(value)
    if typeof(value) == "Color3" then
        return {
            __type = "Color3",
            R = value.R,
            G = value.G,
            B = value.B
        }
    end
    return value
end

local function deserializeValue(value)
    if type(value) == "table" and value.__type == "Color3" then
        return Color3.new(value.R, value.G, value.B)
    end
    return value
end

local function encodeConfig()
    local data = {}
    for key, value in pairs(Config) do
        data[key] = serializeValue(value)
    end
    return HttpService:JSONEncode(data)
end

local function decodeConfig(text)
    local ok, data = pcall(function()
        return HttpService:JSONDecode(text)
    end)

    if not ok or type(data) ~= "table" then
        return false
    end

    for key, value in pairs(data) do
        if Config[key] ~= nil then
            Config[key] = deserializeValue(value)
        end
    end

    return true
end

local function saveConfig(name)
    if not canUseFiles() then
        return false, "File API unavailable"
    end

    pcall(function()
        if not isfolder(CONFIG_FOLDER) then
            makefolder(CONFIG_FOLDER)
        end
    end)

    local file = CONFIG_FOLDER .. "/" .. name .. ".json"

    local ok, err = pcall(function()
        writefile(file, encodeConfig())
        writefile(LAST_CONFIG_FILE, name)
    end)

    return ok, err
end

local function loadConfig(name)
    if not canUseFiles() then
        return false
    end

    local file = CONFIG_FOLDER .. "/" .. name .. ".json"
    if not isfile(file) then
        return false
    end

    local ok, text = pcall(readfile, file)
    if not ok then
        return false
    end

    return decodeConfig(text)
end

if canUseFiles() then
    pcall(function()
        if isfile(LAST_CONFIG_FILE) then
            local last = readfile(LAST_CONFIG_FILE)
            if last and last ~= "" then
                Config.ConfigName = last
                loadConfig(last)
            end
        end
    end)
end

--// GUI ROOT
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DevAimInterface"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

--// MAIN MENU
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(420, 310)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(13, 15, 18)
Main.BackgroundTransparency = 0.03
Main.Visible = false
Main.ClipsDescendants = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(45, 50, 58)
MainStroke.Transparency = 0.15
MainStroke.Parent = Main

local UIScale = Instance.new("UIScale")
UIScale.Scale = 1
UIScale.Parent = Main

local function updateMenuScale()
    local viewport = Camera.ViewportSize
    local scaleX = (viewport.X * 0.92) / 420
    local scaleY = (viewport.Y * 0.86) / 310
    UIScale.Scale = math.clamp(math.min(scaleX, scaleY), 0.65, 1)
end

updateMenuScale()

--// TOP BAR
local Top = Instance.new("Frame")
Top.Size = UDim2.new(1, 0, 0, 48)
Top.BackgroundTransparency = 1
Top.Parent = Main

local Avatar = Instance.new("ImageLabel")
Avatar.Size = UDim2.fromOffset(32, 32)
Avatar.Position = UDim2.fromOffset(10, 8)
Avatar.BackgroundColor3 = Color3.fromRGB(25, 28, 33)
Avatar.Parent = Top

local AvatarCorner = Instance.new("UICorner")
AvatarCorner.CornerRadius = UDim.new(1, 0)
AvatarCorner.Parent = Avatar

pcall(function()
    Avatar.Image = Players:GetUserThumbnailAsync(
        LocalPlayer.UserId,
        Enum.ThumbnailType.HeadShot,
        Enum.ThumbnailSize.Size100x100
    )
end)

local Nick = Instance.new("TextLabel")
Nick.Size = UDim2.fromOffset(130, 18)
Nick.Position = UDim2.fromOffset(50, 7)
Nick.BackgroundTransparency = 1
Nick.Text = LocalPlayer.DisplayName
Nick.TextColor3 = Color3.fromRGB(240, 240, 240)
Nick.Font = Enum.Font.GothamBold
Nick.TextSize = 12
Nick.TextXAlignment = Enum.TextXAlignment.Left
Nick.Parent = Top

local Status = Instance.new("TextLabel")
Status.Size = UDim2.fromOffset(130, 15)
Status.Position = UDim2.fromOffset(50, 25)
Status.BackgroundTransparency = 1
Status.Text = "Developer"
Status.TextColor3 = Color3.fromRGB(0, 190, 255)
Status.Font = Enum.Font.Gotham
Status.TextSize = 9
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Top

local Title = Instance.new("TextLabel")
Title.Size = UDim2.fromOffset(130, 28)
Title.Position = UDim2.new(0.5, -65, 0, 10)
Title.BackgroundTransparency = 1
Title.Text = "DEV AIM"
Title.TextColor3 = Color3.fromRGB(245, 245, 245)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = Top

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(30, 30)
Close.Position = UDim2.new(1, -40, 0, 9)
Close.BackgroundColor3 = Color3.fromRGB(25, 28, 33)
Close.Text = "×"
Close.TextColor3 = Color3.fromRGB(220, 220, 220)
Close.Font = Enum.Font.GothamBold
Close.TextSize = 20
Close.AutoButtonColor = false
Close.Parent = Top

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = Close

--// SIDEBAR
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 92, 1, -48)
Sidebar.Position = UDim2.fromOffset(0, 48)
Sidebar.BackgroundColor3 = Color3.fromRGB(17, 19, 23)
Sidebar.BackgroundTransparency = 0.05
Sidebar.Parent = Main

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 10)
SidebarCorner.Parent = Sidebar

local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -102, 1, -58)
Content.Position = UDim2.fromOffset(97, 53)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = Color3.fromRGB(70, 170, 220)
Content.CanvasSize = UDim2.fromOffset(0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.ScrollingDirection = Enum.ScrollingDirection.Y
Content.Parent = Main

local CurrentCategory = "Combat"
local CategoryButtons = {}
local updateContent

local Categories = {
    {"Combat", "A"},
    {"Visuals", "V"},
    {"Misc", "M"},
    {"Config", "C"}
}

local function createCategory(name, icon, index)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -12, 0, 38)
    Button.Position = UDim2.fromOffset(6, 8 + ((index - 1) * 43))
    Button.BackgroundColor3 = Color3.fromRGB(28, 60, 75)
    Button.BackgroundTransparency = index == 1 and 0 or 1
    Button.Text = ""
    Button.AutoButtonColor = false
    Button.Parent = Sidebar

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Button

    local Icon = Instance.new("TextLabel")
    Icon.Size = UDim2.fromOffset(25, 38)
    Icon.Position = UDim2.fromOffset(2, 0)
    Icon.BackgroundTransparency = 1
    Icon.Text = icon
    Icon.TextColor3 = Color3.fromRGB(80, 185, 240)
    Icon.Font = Enum.Font.GothamBold
    Icon.TextSize = 12
    Icon.Parent = Button

    local Text = Instance.new("TextLabel")
    Text.Size = UDim2.new(1, -27, 1, 0)
    Text.Position = UDim2.fromOffset(27, 0)
    Text.BackgroundTransparency = 1
    Text.Text = name
    Text.TextColor3 = index == 1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(190, 195, 205)
    Text.Font = Enum.Font.GothamMedium
    Text.TextSize = 10
    Text.TextXAlignment = Enum.TextXAlignment.Left
    Text.Parent = Button

    Button.MouseButton1Click:Connect(function()
        CurrentCategory = name

        for _, data in pairs(CategoryButtons) do
            data.Button.BackgroundTransparency = 1
            data.Text.TextColor3 = Color3.fromRGB(190, 195, 205)
        end

        Button.BackgroundTransparency = 0
        Button.BackgroundColor3 = Color3.fromRGB(28, 60, 75)
        Text.TextColor3 = Color3.fromRGB(255, 255, 255)

        if updateContent then
            updateContent()
        end
    end)

    CategoryButtons[name] = {
        Button = Button,
        Text = Text
    }
end

for index, data in ipairs(Categories) do
    createCategory(data[1], data[2], index)
end

--// UI HELPERS
local function clearContent()
    for _, child in ipairs(Content:GetChildren()) do
        child:Destroy()
    end
end

local function createPanel(title, height)
    local Panel = Instance.new("Frame")
    Panel.Size = UDim2.new(1, -8, 0, height)
    Panel.BackgroundColor3 = Color3.fromRGB(18, 21, 25)
    Panel.BackgroundTransparency = 0.04
    Panel.Parent = Content

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 9)
    Corner.Parent = Panel

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(40, 44, 50)
    Stroke.Transparency = 0.45
    Stroke.Parent = Panel

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -24, 0, 26)
    Label.Position = UDim2.fromOffset(12, 5)
    Label.BackgroundTransparency = 1
    Label.Text = title
    Label.TextColor3 = Color3.fromRGB(245, 245, 245)
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Panel

    return Panel
end

local function createToggle(parent, text, y, getter, setter)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -20, 0, 32)
    Button.Position = UDim2.fromOffset(10, y)
    Button.BackgroundTransparency = 1
    Button.Text = ""
    Button.AutoButtonColor = false
    Button.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -55, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(205, 208, 215)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 10
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Button

    local Switch = Instance.new("Frame")
    Switch.Size = UDim2.fromOffset(32, 17)
    Switch.Position = UDim2.new(1, -32, 0.5, -8)
    Switch.BackgroundColor3 = Color3.fromRGB(45, 48, 54)
    Switch.Parent = Button

    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(1, 0)
    SwitchCorner.Parent = Switch

    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.fromOffset(11, 11)
    Circle.Position = UDim2.fromOffset(3, 3)
    Circle.BackgroundColor3 = Color3.fromRGB(150, 155, 160)
    Circle.Parent = Switch

    local CircleCorner = Instance.new("UICorner")
    CircleCorner.CornerRadius = UDim.new(1, 0)
    CircleCorner.Parent = Circle

    local function refresh()
        local state = getter()
        Switch.BackgroundColor3 = state and Color3.fromRGB(0, 150, 210) or Color3.fromRGB(45, 48, 54)
        Circle.Position = state and UDim2.new(1, -14, 0, 3) or UDim2.fromOffset(3, 3)
    end

    Button.MouseButton1Click:Connect(function()
        setter(not getter())
        refresh()
    end)

    refresh()
end

local function createSlider(parent, text, y, minValue, maxValue, getter, setter)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -20, 0, 46)
    Container.Position = UDim2.fromOffset(10, y)
    Container.BackgroundTransparency = 1
    Container.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.65, 0, 0, 17)
    Label.BackgroundTransparency = 1
    Label.TextColor3 = Color3.fromRGB(205, 208, 215)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 10
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Container

    local Value = Instance.new("TextLabel")
    Value.Size = UDim2.new(0.35, 0, 0, 17)
    Value.Position = UDim2.new(0.65, 0, 0, 0)
    Value.BackgroundTransparency = 1
    Value.TextColor3 = Color3.fromRGB(120, 195, 240)
    Value.Font = Enum.Font.GothamBold
    Value.TextSize = 10
    Value.TextXAlignment = Enum.TextXAlignment.Right
    Value.Parent = Container

    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(1, 0, 0, 6)
    Bar.Position = UDim2.fromOffset(0, 27)
    Bar.BackgroundColor3 = Color3.fromRGB(45, 48, 55)
    Bar.Active = true
    Bar.Parent = Container

    local BarCorner = Instance.new("UICorner")
    BarCorner.CornerRadius = UDim.new(1, 0)
    BarCorner.Parent = Bar

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new(0, 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(0, 160, 220)
    Fill.Parent = Bar

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = Fill

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.fromOffset(12, 12)
    Knob.AnchorPoint = Vector2.new(0.5, 0.5)
    Knob.Position = UDim2.new(0, 0, 0.5, 0)
    Knob.BackgroundColor3 = Color3.fromRGB(220, 240, 250)
    Knob.Parent = Bar

    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(1, 0)
    KnobCorner.Parent = Knob

    local dragging = false

    local function refresh()
        local current = math.clamp(tonumber(getter()) or minValue, minValue, maxValue)
        local alpha = (current - minValue) / (maxValue - minValue)
        Label.Text = text
        Value.Text = tostring(math.floor(current + 0.5))
        Fill.Size = UDim2.new(alpha, 0, 1, 0)
        Knob.Position = UDim2.new(alpha, 0, 0.5, 0)
    end

    local function setFromX(x)
        local width = math.max(Bar.AbsoluteSize.X, 1)
        local alpha = math.clamp((x - Bar.AbsolutePosition.X) / width, 0, 1)
        local value = minValue + ((maxValue - minValue) * alpha)
        setter(value)
        refresh()
    end

    Bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(input.Position.X)
        end
    end)

    Bar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            setFromX(input.Position.X)
        end
    end)

    refresh()
end

local function createButton(parent, text, y, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -20, 0, 34)
    Button.Position = UDim2.fromOffset(10, y)
    Button.BackgroundColor3 = Color3.fromRGB(25, 50, 63)
    Button.Text = text
    Button.TextColor3 = Color3.fromRGB(230, 240, 245)
    Button.Font = Enum.Font.GothamBold
    Button.TextSize = 10
    Button.AutoButtonColor = false
    Button.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Button

    Button.MouseButton1Click:Connect(callback)
end

--// CONTENT
updateContent = function()
    clearContent()

    local panel

    if CurrentCategory == "Combat" then
        panel = createPanel("Aim Assist / FOV", 350)

        createToggle(panel, "Enable Aim", 36,
            function() return Config.SilentAim end,
            function(v) Config.SilentAim = v end)

        createToggle(panel, "Bhop", 69,
            function() return Config.Bhop end,
            function(v) Config.Bhop = v end)

        createToggle(panel, "Visibility Check", 102,
            function() return Config.VisibilityCheck end,
            function(v) Config.VisibilityCheck = v end)

        createToggle(panel, "Distance Check", 135,
            function() return Config.DistanceCheck end,
            function(v) Config.DistanceCheck = v end)

        createSlider(panel, "Distance", 170, 50, 2000,
            function() return Config.Distance end,
            function(v) Config.Distance = v end)

        createSlider(panel, "FOV", 216, 20, 500,
            function() return Config.FOV end,
            function(v) Config.FOV = v end)

        createSlider(panel, "Hit Chance", 262, 0, 100,
            function() return Config.HitChance end,
            function(v) Config.HitChance = v end)

        createToggle(panel, "FOV Circle", 310,
            function() return Config.FOVCircle end,
            function(v) Config.FOVCircle = v end)


    elseif CurrentCategory == "Visuals" then
        panel = createPanel("ESP", 270)

        createToggle(panel, "Box", 36,
            function() return Config.ESPBox end,
            function(v) Config.ESPBox = v end)

        createToggle(panel, "Name", 69,
            function() return Config.ESPName end,
            function(v) Config.ESPName = v end)

        createToggle(panel, "Health", 102,
            function() return Config.ESPHealth end,
            function(v) Config.ESPHealth = v end)

        createToggle(panel, "Tracer", 135,
            function() return Config.ESPTracer end,
            function(v) Config.ESPTracer = v end)

        local colorButton
        colorButton = createButton(panel, "Change ESP Color", 178, function()
            local colors = {
                Color3.fromRGB(0, 170, 255),
                Color3.fromRGB(0, 255, 120),
                Color3.fromRGB(255, 80, 80),
                Color3.fromRGB(255, 190, 0),
                Color3.fromRGB(200, 100, 255)
            }

            local closest = 1
            local best = math.huge
            for i, color in ipairs(colors) do
                local difference = math.abs(color.R - Config.ESPColor.R)
                    + math.abs(color.G - Config.ESPColor.G)
                    + math.abs(color.B - Config.ESPColor.B)
                if difference < best then
                    best = difference
                    closest = i
                end
            end

            local nextIndex = closest + 1
            if nextIndex > #colors then
                nextIndex = 1
            end
            Config.ESPColor = colors[nextIndex]
        end)

    elseif CurrentCategory == "Misc" then
        panel = createPanel("Lighting", 220)

        createToggle(panel, "FullBright", 36,
            function() return Config.FullBright end,
            function(v) Config.FullBright = v end)

        createSlider(panel, "Brightness", 73, 0, 10,
            function() return Config.Brightness end,
            function(v) Config.Brightness = v end)

        createSlider(panel, "ClockTime", 119, 0, 24,
            function() return Config.ClockTime end,
            function(v) Config.ClockTime = v end)

        createToggle(panel, "Remove Fog", 166,
            function() return Config.Fog end,
            function(v) Config.Fog = v end)

    elseif CurrentCategory == "Config" then
        panel = createPanel("Config System", 260)

        local NameBox = Instance.new("TextBox")
        NameBox.Size = UDim2.new(1, -20, 0, 32)
        NameBox.Position = UDim2.fromOffset(10, 38)
        NameBox.BackgroundColor3 = Color3.fromRGB(25, 28, 33)
        NameBox.PlaceholderText = "Config name"
        NameBox.Text = Config.ConfigName
        NameBox.TextColor3 = Color3.fromRGB(235, 235, 235)
        NameBox.PlaceholderColor3 = Color3.fromRGB(100, 105, 110)
        NameBox.Font = Enum.Font.Gotham
        NameBox.TextSize = 10
        NameBox.ClearTextOnFocus = false
        NameBox.Parent = panel

        local BoxCorner = Instance.new("UICorner")
        BoxCorner.CornerRadius = UDim.new(0, 7)
        BoxCorner.Parent = NameBox

        createButton(panel, "Save Config", 78, function()
            local name = NameBox.Text:gsub("[^%w_%-%s]", "")
            name = name:gsub("^%s+", ""):gsub("%s+$", "")
            if name == "" then
                name = "default"
            end
            Config.ConfigName = name
            saveConfig(name)
            NameBox.Text = name
        end)

        createButton(panel, "Load Config", 118, function()
            local name = NameBox.Text
            if name == "" then
                name = "default"
            end
            if loadConfig(name) then
                Config.ConfigName = name
                updateContent()
            end
        end)

        createButton(panel, "Reset Config", 158, function()
            for key, value in pairs(DefaultConfig) do
                Config[key] = value
            end
            updateContent()
        end)

        local Info = Instance.new("TextLabel")
        Info.Size = UDim2.new(1, -20, 0, 45)
        Info.Position = UDim2.fromOffset(10, 205)
        Info.BackgroundTransparency = 1
        Info.TextWrapped = true
        Info.TextColor3 = Color3.fromRGB(135, 140, 148)
        Info.Font = Enum.Font.Gotham
        Info.TextSize = 9
        Info.TextXAlignment = Enum.TextXAlignment.Left
        Info.TextYAlignment = Enum.TextYAlignment.Top
        Info.Text = canUseFiles()
            and "File configs: READY"
            or "File configs: unavailable in normal Roblox Studio"
        Info.Parent = panel
    end

    if panel then
        panel.LayoutOrder = 1
    end
end

updateContent()

--// OPEN BUTTON + LOCK/RESPAWN CONTROLS
-- Forward declarations: the open button is created before the menu-control section.
local MenuOpen = false
local openMenu, closeMenu, toggleMenu

local function loadOpenButtonPosition()
    if not canUseFiles() then
        return nil
    end

    local ok, text = pcall(readfile, BUTTON_POSITION_FILE)
    if not ok or not text or text == "" then
        return nil
    end

    local decodedOk, data = pcall(function()
        return HttpService:JSONDecode(text)
    end)

    if decodedOk and type(data) == "table" and tonumber(data.x) and tonumber(data.y) then
        return tonumber(data.x), tonumber(data.y)
    end

    return nil
end

local function saveOpenButtonPosition(x, y)
    if not canUseFiles() then
        return
    end

    pcall(function()
        if not isfolder(CONFIG_FOLDER) then
            makefolder(CONFIG_FOLDER)
        end
        writefile(BUTTON_POSITION_FILE, HttpService:JSONEncode({x = x, y = y}))
    end)
end

local function clearOpenButtonPosition()
    if not canUseFiles() then
        return
    end

    pcall(function()
        if isfile(BUTTON_POSITION_FILE) then
            delfile(BUTTON_POSITION_FILE)
        end
    end)
end

local OpenButton = Instance.new("TextButton")
OpenButton.Name = "OpenButton"
OpenButton.Size = UDim2.fromOffset(44, 44)
local savedX, savedY = loadOpenButtonPosition()
if savedX and savedY then
    OpenButton.Position = UDim2.fromOffset(savedX, savedY)
else
    OpenButton.Position = UDim2.new(0, DEFAULT_BUTTON_X, 1, -DEFAULT_BUTTON_Y_FROM_BOTTOM)
end
OpenButton.BackgroundColor3 = Color3.fromRGB(18, 23, 28)
OpenButton.Text = "≡"
OpenButton.TextColor3 = Color3.fromRGB(0, 180, 240)
OpenButton.Font = Enum.Font.GothamBold
OpenButton.TextSize = 21
OpenButton.AutoButtonColor = false
OpenButton.Parent = ScreenGui

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(1, 0)
OpenCorner.Parent = OpenButton

local OpenStroke = Instance.new("UIStroke")
OpenStroke.Color = Color3.fromRGB(0, 150, 210)
OpenStroke.Thickness = 1.3
OpenStroke.Parent = OpenButton

-- Small control bar above the default opening-button position.
-- It is placed with a clear gap so it never covers the opening button.
local ButtonControl = Instance.new("Frame")
ButtonControl.Name = "ButtonControl"
ButtonControl.Size = UDim2.fromOffset(178, 38)
ButtonControl.Position = UDim2.new(0, DEFAULT_BUTTON_X, 1, -(DEFAULT_BUTTON_Y_FROM_BOTTOM + OpenButton.Size.Y.Offset + 14 + 38))
ButtonControl.BackgroundColor3 = Color3.fromRGB(15, 20, 25)
ButtonControl.BackgroundTransparency = 0.04
ButtonControl.BorderSizePixel = 0
ButtonControl.Parent = ScreenGui

local ControlCorner = Instance.new("UICorner")
ControlCorner.CornerRadius = UDim.new(0, 9)
ControlCorner.Parent = ButtonControl

local ControlStroke = Instance.new("UIStroke")
ControlStroke.Color = Color3.fromRGB(45, 65, 75)
ControlStroke.Thickness = 1
ControlStroke.Parent = ButtonControl

local LockButton = Instance.new("TextButton")
LockButton.Name = "LockButton"
LockButton.Size = UDim2.fromOffset(84, 30)
LockButton.Position = UDim2.fromOffset(4, 4)
LockButton.BackgroundColor3 = Color3.fromRGB(25, 50, 63)
LockButton.Text = "UnLock"
LockButton.TextColor3 = Color3.fromRGB(230, 240, 245)
LockButton.Font = Enum.Font.GothamBold
LockButton.TextSize = 11
LockButton.AutoButtonColor = false
LockButton.Parent = ButtonControl

local LockCorner = Instance.new("UICorner")
LockCorner.CornerRadius = UDim.new(0, 7)
LockCorner.Parent = LockButton

local RespawnButton = Instance.new("TextButton")
RespawnButton.Name = "RespawnButton"
RespawnButton.Size = UDim2.fromOffset(84, 30)
RespawnButton.Position = UDim2.fromOffset(90, 4)
RespawnButton.BackgroundColor3 = Color3.fromRGB(25, 50, 63)
RespawnButton.Text = "Respawn"
RespawnButton.TextColor3 = Color3.fromRGB(230, 240, 245)
RespawnButton.Font = Enum.Font.GothamBold
RespawnButton.TextSize = 11
RespawnButton.AutoButtonColor = false
RespawnButton.Parent = ButtonControl

local RespawnCorner = Instance.new("UICorner")
RespawnCorner.CornerRadius = UDim.new(0, 7)
RespawnCorner.Parent = RespawnButton

-- Locked by default on every script activation.
local OpenButtonLocked = true
local buttonDragging = false
local buttonMoved = false
local buttonDragStart
local buttonStartPosition

local function updateLockText()
    LockButton.Text = OpenButtonLocked and "UnLock" or "Lock"
end

local function resetOpenButtonPosition()
    local viewport = Camera.ViewportSize
    local x = math.clamp(DEFAULT_BUTTON_X, 0, math.max(viewport.X - OpenButton.AbsoluteSize.X, 0))
    local y = math.clamp(
        viewport.Y - DEFAULT_BUTTON_Y_FROM_BOTTOM - OpenButton.AbsoluteSize.Y,
        0,
        math.max(viewport.Y - OpenButton.AbsoluteSize.Y, 0)
    )

    OpenButton.Position = UDim2.fromOffset(x, y)
    saveOpenButtonPosition(x, y)
end

LockButton.MouseButton1Click:Connect(function()
    OpenButtonLocked = not OpenButtonLocked
    updateLockText()
end)

RespawnButton.MouseButton1Click:Connect(function()
    resetOpenButtonPosition()
end)

OpenButton.InputBegan:Connect(function(input)
    if OpenButtonLocked then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        buttonDragging = true
        buttonMoved = false
        buttonDragStart = input.Position
        buttonStartPosition = OpenButton.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if OpenButtonLocked or not buttonDragging then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - buttonDragStart
        if delta.Magnitude > 5 then
            buttonMoved = true
        end

        local viewport = Camera.ViewportSize
        local maxX = math.max(viewport.X - OpenButton.AbsoluteSize.X, 0)
        local maxY = math.max(viewport.Y - OpenButton.AbsoluteSize.Y, 0)
        local x = math.clamp(buttonStartPosition.X.Offset + delta.X, 0, maxX)
        local y = math.clamp(buttonStartPosition.Y.Offset + delta.Y, 0, maxY)
        OpenButton.Position = UDim2.fromOffset(x, y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if not buttonDragging then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        buttonDragging = false
        local pos = OpenButton.AbsolutePosition
        saveOpenButtonPosition(pos.X, pos.Y)
    end
end)

OpenButton.MouseButton1Click:Connect(function()
    if not buttonMoved then
        toggleMenu()
    end
    buttonMoved = false
end)

updateLockText()

--// FOV CIRCLE
local FOVGui = Instance.new("Frame")
FOVGui.Name = "FOVCircle"
FOVGui.AnchorPoint = Vector2.new(0.5, 0.5)
FOVGui.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
FOVGui.BackgroundTransparency = 1
FOVGui.BorderSizePixel = 0
FOVGui.Parent = ScreenGui

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVGui

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Color = Color3.fromRGB(0, 170, 255)
FOVStroke.Thickness = Config.FOVThickness
FOVStroke.Parent = FOVGui

--// ESP
local ESPCache = {}

local function getCharacter(player)
    local character = player.Character
    if not character then
        return nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")

    if not humanoid or humanoid.Health <= 0 or not root or not head then
        return nil
    end

    return character, humanoid, root, head
end

local function createESP(player)
    if ESPCache[player] then
        return ESPCache[player]
    end

    local data = {}

    data.highlight = Instance.new("Highlight")
    data.highlight.Name = "DevAimESP"
    data.highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    data.highlight.FillTransparency = 1
    data.highlight.OutlineTransparency = 0
    data.highlight.OutlineColor = Config.ESPColor
    data.highlight.Enabled = false
    data.highlight.Parent = ScreenGui

    data.billboard = Instance.new("BillboardGui")
    data.billboard.Name = "DevAimESPInfo"
    data.billboard.Size = UDim2.fromOffset(140, 38)
    data.billboard.StudsOffset = Vector3.new(0, 3.1, 0)
    data.billboard.AlwaysOnTop = true
    data.billboard.Enabled = false
    data.billboard.Parent = ScreenGui

    data.name = Instance.new("TextLabel")
    data.name.Size = UDim2.new(1, 0, 0, 18)
    data.name.BackgroundTransparency = 1
    data.name.TextColor3 = Config.ESPColor
    data.name.Font = Enum.Font.GothamBold
    data.name.TextSize = 11
    data.name.TextStrokeTransparency = 0.4
    data.name.Parent = data.billboard

    data.health = Instance.new("TextLabel")
    data.health.Size = UDim2.new(1, 0, 0, 15)
    data.health.Position = UDim2.fromOffset(0, 18)
    data.health.BackgroundTransparency = 1
    data.health.TextColor3 = Color3.fromRGB(80, 255, 100)
    data.health.Font = Enum.Font.GothamBold
    data.health.TextSize = 9
    data.health.TextStrokeTransparency = 0.4
    data.health.Parent = data.billboard

    data.tracer = Instance.new("Frame")
    data.tracer.Name = "DevAimTracer"
    data.tracer.AnchorPoint = Vector2.new(0.5, 0.5)
    data.tracer.BorderSizePixel = 0
    data.tracer.BackgroundColor3 = Config.ESPColor
    data.tracer.Size = UDim2.fromOffset(0, 1)
    data.tracer.Visible = false
    data.tracer.Parent = ScreenGui

    ESPCache[player] = data
    return data
end

local function hideESP(data)
    data.highlight.Enabled = false
    data.billboard.Enabled = false
    data.tracer.Visible = false
end

local function updateESP(player)
    local data = createESP(player)
    local character, humanoid, root, head = getCharacter(player)

    if not character or player == LocalPlayer then
        hideESP(data)
        return
    end

    local distance = (Camera.CFrame.Position - root.Position).Magnitude
    if distance > Config.Distance then
        hideESP(data)
        return
    end

    local headPosition, onScreen = Camera:WorldToViewportPoint(head.Position)
    if not onScreen then
        hideESP(data)
        return
    end

    data.highlight.Adornee = character
    data.highlight.OutlineColor = Config.ESPColor
    data.highlight.Enabled = Config.ESPBox

    data.billboard.Adornee = head
    data.billboard.Enabled = Config.ESPName or Config.ESPHealth
    data.name.Visible = Config.ESPName
    data.health.Visible = Config.ESPHealth
    data.name.Text = player.DisplayName
    data.name.TextColor3 = Config.ESPColor
    data.health.Text = "HP " .. math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)

    if Config.ESPTracer then
        local screenSize = Camera.ViewportSize
        local start = Vector2.new(screenSize.X / 2, screenSize.Y - 5)
        local finish = Vector2.new(headPosition.X, headPosition.Y)
        local difference = finish - start

        data.tracer.Visible = true
        data.tracer.BackgroundColor3 = Config.ESPColor
        data.tracer.Position = UDim2.fromOffset(
            (start.X + finish.X) / 2,
            (start.Y + finish.Y) / 2
        )
        data.tracer.Size = UDim2.fromOffset(math.max(difference.Magnitude, 1), 1)
        data.tracer.Rotation = math.deg(math.atan2(difference.Y, difference.X))
    else
        data.tracer.Visible = false
    end
end

local NPCModels = {}

local function isNPCModel(obj)
    if not obj:IsA("Model") then
        return false
    end
    if Players:GetPlayerFromCharacter(obj) then
        return false
    end
    local humanoid = obj:FindFirstChildOfClass("Humanoid")
    local root = obj:FindFirstChild("HumanoidRootPart")
    local head = obj:FindFirstChild("Head")
    return humanoid ~= nil and root ~= nil and head ~= nil
end

local function addNPCIfValid(obj)
    if isNPCModel(obj) then
        NPCModels[obj] = true
    end
end

for _, obj in ipairs(workspace:GetDescendants()) do
    addNPCIfValid(obj)
end

workspace.DescendantAdded:Connect(function(obj)
    task.defer(function()
        if obj:IsA("Model") then
            addNPCIfValid(obj)
        else
            local model = obj:FindFirstAncestorOfClass("Model")
            if model then
                addNPCIfValid(model)
            end
        end
    end)
end)

workspace.DescendantRemoving:Connect(function(obj)
    if NPCModels[obj] then
        NPCModels[obj] = nil
    end
end)

local function updateESPForModel(model, displayName)
    local key = model
    local data = ESPCache[key]
    if not data then
        data = {}
        data.highlight = Instance.new("Highlight")
        data.highlight.Name = "DevAimESP"
        data.highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        data.highlight.FillTransparency = 1
        data.highlight.OutlineTransparency = 0
        data.highlight.Enabled = false
        data.highlight.Parent = ScreenGui

        data.billboard = Instance.new("BillboardGui")
        data.billboard.Name = "DevAimESPInfo"
        data.billboard.Size = UDim2.fromOffset(140, 38)
        data.billboard.StudsOffset = Vector3.new(0, 3.1, 0)
        data.billboard.AlwaysOnTop = true
        data.billboard.Enabled = false
        data.billboard.Parent = ScreenGui

        data.name = Instance.new("TextLabel")
        data.name.Size = UDim2.new(1, 0, 0, 18)
        data.name.BackgroundTransparency = 1
        data.name.Font = Enum.Font.GothamBold
        data.name.TextSize = 11
        data.name.TextStrokeTransparency = 0.4
        data.name.Parent = data.billboard

        data.health = Instance.new("TextLabel")
        data.health.Size = UDim2.new(1, 0, 0, 15)
        data.health.Position = UDim2.fromOffset(0, 18)
        data.health.BackgroundTransparency = 1
        data.health.TextColor3 = Color3.fromRGB(80, 255, 100)
        data.health.Font = Enum.Font.GothamBold
        data.health.TextSize = 9
        data.health.TextStrokeTransparency = 0.4
        data.health.Parent = data.billboard

        data.tracer = Instance.new("Frame")
        data.tracer.Name = "DevAimTracer"
        data.tracer.AnchorPoint = Vector2.new(0.5, 0.5)
        data.tracer.BorderSizePixel = 0
        data.tracer.BackgroundColor3 = Config.ESPColor
        data.tracer.Size = UDim2.fromOffset(0, 1)
        data.tracer.Visible = false
        data.tracer.Parent = ScreenGui

        ESPCache[key] = data
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    local head = model:FindFirstChild("Head")
    if not humanoid or humanoid.Health <= 0 or not root or not head then
        hideESP(data)
        return
    end

    local distance = (Camera.CFrame.Position - root.Position).Magnitude
    local headPosition, onScreen = Camera:WorldToViewportPoint(head.Position)
    if distance > Config.Distance or not onScreen then
        hideESP(data)
        return
    end

    data.highlight.Adornee = model
    data.highlight.OutlineColor = Config.ESPColor
    data.highlight.Enabled = Config.ESPBox
    data.billboard.Adornee = head
    data.billboard.Enabled = Config.ESPName or Config.ESPHealth
    data.name.Visible = Config.ESPName
    data.health.Visible = Config.ESPHealth
    data.name.Text = displayName or model.Name
    data.name.TextColor3 = Config.ESPColor
    data.health.Text = "HP " .. math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)

    if Config.ESPTracer then
        local screenSize = Camera.ViewportSize
        local start = Vector2.new(screenSize.X / 2, screenSize.Y - 5)
        local finish = Vector2.new(headPosition.X, headPosition.Y)
        local difference = finish - start
        data.tracer.Visible = true
        data.tracer.BackgroundColor3 = Config.ESPColor
        data.tracer.Position = UDim2.fromOffset(
            (start.X + finish.X) / 2,
            (start.Y + finish.Y) / 2
        )
        data.tracer.Size = UDim2.fromOffset(math.max(difference.Magnitude, 1), 1)
        data.tracer.Rotation = math.deg(math.atan2(difference.Y, difference.X))
    else
        data.tracer.Visible = false
    end
end

local function cleanupNPCESP()
    for model, data in pairs(ESPCache) do
        if typeof(model) == "Instance" and model:IsA("Model") and not Players:GetPlayerFromCharacter(model) then
            if not model:IsDescendantOf(workspace) then
                for _, object in pairs(data) do
                    pcall(function() object:Destroy() end)
                end
                ESPCache[model] = nil
            end
        end
    end
end

Players.PlayerRemoving:Connect(function(player)
    local data = ESPCache[player]
    if data then
        for _, object in pairs(data) do
            pcall(function()
                object:Destroy()
            end)
        end
    end
    ESPCache[player] = nil
end)

--// AIM
local function visibleTarget(character, targetPart)
    if not Config.VisibilityCheck then
        return true
    end

    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {
        LocalPlayer.Character,
        character
    }

    return workspace:Raycast(origin, direction, params) == nil
end

local function getBestTarget()
    local bestPlayer = nil
    local bestPart = nil
    local bestScreenDistance = math.huge

    local viewport = Camera.ViewportSize
    local center = Vector2.new(viewport.X / 2, viewport.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character, humanoid, root, head = getCharacter(player)

            if character then
                local screenPosition, onScreen = Camera:WorldToViewportPoint(head.Position)

                if onScreen then
                    local screenDistance = (
                        Vector2.new(screenPosition.X, screenPosition.Y) - center
                    ).Magnitude

                    if screenDistance <= Config.FOV then
                        local worldDistance = (root.Position - Camera.CFrame.Position).Magnitude
                        local distanceOK = not Config.DistanceCheck or worldDistance <= Config.Distance

                        if distanceOK
                            and visibleTarget(character, head)
                            and screenDistance < bestScreenDistance then
                            bestScreenDistance = screenDistance
                            bestPlayer = player
                            bestPart = head
                        end
                    end
                end
            end
        end
    end

    return bestPlayer, bestPart
end

--// LIGHTING
local OriginalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows
}

local function updateLighting()
    if Config.FullBright then
        Lighting.Brightness = Config.Brightness
        Lighting.ClockTime = Config.ClockTime
        Lighting.GlobalShadows = false

        if Config.Fog then
            Lighting.FogEnd = 100000
        else
            Lighting.FogEnd = OriginalLighting.FogEnd
        end
    else
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.ClockTime = OriginalLighting.ClockTime
        Lighting.GlobalShadows = OriginalLighting.GlobalShadows
        Lighting.FogEnd = OriginalLighting.FogEnd
    end
end

--// MENU CONTROLS
openMenu = function()
    if MenuOpen then
        return
    end

    MenuOpen = true
    updateMenuScale()
    Main.Visible = true
end

closeMenu = function()
    if not MenuOpen then
        return
    end

    MenuOpen = false
    Main.Visible = false
end

toggleMenu = function()
    if MenuOpen then
        closeMenu()
    else
        openMenu()
    end
end

Close.MouseButton1Click:Connect(closeMenu)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.KeyCode == Enum.KeyCode.Insert
        or input.KeyCode == Enum.KeyCode.RightShift then
        toggleMenu()
    elseif input.KeyCode == Enum.KeyCode.X and MenuOpen then
        closeMenu()
    end
end)

--// RENDER LOOP
local LightingTimer = 0
local ESPTimer = 0
local AimTimer = 0

RunService.RenderStepped:Connect(function(deltaTime)
    Camera = workspace.CurrentCamera or Camera

    -- FOV
    local viewport = Camera.ViewportSize
    FOVGui.Position = UDim2.fromOffset(viewport.X / 2, viewport.Y / 2)
    FOVGui.Size = UDim2.fromOffset(Config.FOV * 2, Config.FOV * 2)
    FOVGui.Visible = Config.FOVCircle
    FOVGui.BackgroundTransparency = 1
    FOVStroke.Thickness = math.clamp(math.floor(Config.FOVThickness + 0.5), 1, 8)

    -- AIM: instant snap, intentionally no Lerp
    AimTimer += deltaTime
    if Config.SilentAim and AimTimer >= 0.016 then
        AimTimer = 0

        if math.random(1, 100) <= math.clamp(math.floor(Config.HitChance + 0.5), 0, 100) then
            local target, targetPart = getBestTarget()

            if target and targetPart then
                Camera.CFrame = CFrame.lookAt(
                    Camera.CFrame.Position,
                    targetPart.Position
                )
            end
        end
    end

    -- ESP update
    ESPTimer += deltaTime
    if ESPTimer >= 0.03 then
        ESPTimer = 0
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                updateESP(player)
            end
        end
        for model in pairs(NPCModels) do
            if model:IsDescendantOf(workspace) then
                updateESPForModel(model, model.Name)
            else
                NPCModels[model] = nil
            end
        end
        cleanupNPCESP()
    end

    -- BHOP: auto-jump while moving/grounded. This is a normal client-side movement helper.
    if Config.Bhop then
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 and humanoid.MoveDirection.Magnitude > 0 then
            if humanoid.FloorMaterial ~= Enum.Material.Air then
                humanoid.Jump = true
            end
        end
    end

    -- LIGHTING
    LightingTimer += deltaTime
    if LightingTimer >= 0.1 then
        LightingTimer = 0
        pcall(updateLighting)
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    Camera = workspace.CurrentCamera or Camera
end)

updateLighting()
updateMenuScale()
