--[[
    ✨ ORCA FROSTED REANIMATION MENU ✨
    Glassmorphism aesthetic with frosted white overlays
    Inspired by Orca UI's Frosted theme - clean, elegant, premium feel
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Mouse = LocalPlayer:GetMouse()

-- Load APIs
local ReanimateAPI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Rootleak/Reanimation/refs/heads/main/module.lua"))()
local AnimationList = loadstring(game:HttpGet("https://raw.githubusercontent.com/EORScopeZ/OnyxV2/refs/heads/main/Animations.lua"))()

-- ─────────────────────────────────────────────────────────────────────────────
-- COLOR PALETTE (ORCA FROSTED THEME)
-- ─────────────────────────────────────────────────────────────────────────────
local Colors = {
    -- Frosted theme: semi-transparent whites with very dark background
    accentWhite = Color3.fromRGB(255, 255, 255),   -- Pure white (0.9)
    accentLight = Color3.fromRGB(200, 200, 200),   -- Light white (0.5)
    accentMid = Color3.fromRGB(220, 220, 220),     -- Mid white (0.7)
    bgDark = Color3.fromRGB(20, 20, 30),           -- Very dark (rgba 20,20,30 0.5)
    surface2 = Color3.fromRGB(50, 50, 70),         -- Frosted (rgba 255,255,255 0.06)
    surface3 = Color3.fromRGB(40, 40, 55),         -- Frosted (rgba 255,255,255 0.03)
    text = Color3.fromRGB(255, 255, 255),          -- Pure white text
    muted = Color3.fromRGB(170, 170, 190),         -- Muted (rgba 255,255,255 0.45)
    stroke = Color3.fromRGB(120, 120, 140),        -- Subtle white border
}

-- ─────────────────────────────────────────────────────────────────────────────
-- STATE & CONFIGURATION
-- ─────────────────────────────────────────────────────────────────────────────

local State = {
    isReanimated = false,
    isMinimized = false,
    currentSpeed = 1.0,
    currentTab = "All",
    selectedAnimation = nil,
    listeningForKeybind = false,
    listeningButton = nil,
}

local Favorites = {}
local Keybinds = {}
local AnimationButtons = {}

local function LoadData()
    local ok1, fav = pcall(function()
        if not isfile("ReanimFavorites.json") then return {} end
        return HttpService:JSONDecode(readfile("ReanimFavorites.json"))
    end)
    Favorites = (ok1 and type(fav) == "table") and fav or {}

    local ok2, key = pcall(function()
        if not isfile("ReanimKeybinds.json") then return {} end
        return HttpService:JSONDecode(readfile("ReanimKeybinds.json"))
    end)
    Keybinds = (ok2 and type(key) == "table") and key or {}
end

local function SaveData()
    pcall(function() writefile("ReanimFavorites.json", HttpService:JSONEncode(Favorites)) end)
    pcall(function() writefile("ReanimKeybinds.json", HttpService:JSONEncode(Keybinds)) end)
end

LoadData()

-- ─────────────────────────────────────────────────────────────────────────────
-- NOTIFICATIONS
-- ─────────────────────────────────────────────────────────────────────────────

local function Notify(text, duration)
    duration = duration or 3
    
    local notif = Instance.new("TextLabel")
    notif.Name = "Notification"
    notif.Parent = ScreenGui
    notif.Size = UDim2.new(0, 340, 0, 50)
    notif.Position = UDim2.new(0.5, -170, 0, -70)
    notif.BackgroundColor3 = Colors.surface2
    notif.BackgroundTransparency = 0.15
    notif.BorderSizePixel = 0
    notif.Text = text
    notif.TextColor3 = Colors.text
    notif.TextSize = 12
    notif.Font = Enum.Font.GothamSemibold
    notif.TextWrapped = true
    notif.ZIndex = 1000

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = notif

    local stroke = Instance.new("UIStroke")
    stroke.Color = Colors.accentWhite
    stroke.Transparency = 0.7
    stroke.Thickness = 1
    stroke.Parent = notif

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 14)
    padding.PaddingRight = UDim.new(0, 14)
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 8)
    padding.Parent = notif

    TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -170, 0, 20)}):Play()

    task.delay(duration, function()
        TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(0.5, -170, 0, -70)}):Play()
        game:GetService("Debris"):AddItem(notif, 0.4)
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- MAIN GUI
-- ─────────────────────────────────────────────────────────────────────────────

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OrcaFrostedMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local MainWindow = Instance.new("Frame")
MainWindow.Name = "MainWindow"
MainWindow.Size = UDim2.new(0, 350, 0, 480)
MainWindow.Position = UDim2.new(0.5, -175, 0.5, -240)
MainWindow.BackgroundColor3 = Colors.bgDark
MainWindow.BackgroundTransparency = 0.4
MainWindow.BorderSizePixel = 0
MainWindow.ClipsDescendants = true
MainWindow.Active = true
MainWindow.Parent = ScreenGui
MainWindow.ZIndex = 100

local windowCorner = Instance.new("UICorner")
windowCorner.CornerRadius = UDim.new(0, 18)
windowCorner.Parent = MainWindow

local windowStroke = Instance.new("UIStroke")
windowStroke.Color = Colors.stroke
windowStroke.Transparency = 0.6
windowStroke.Thickness = 1.2
windowStroke.Parent = MainWindow

-- Frosted glass overlay effect
local glassOverlay = Instance.new("Frame")
glassOverlay.Size = UDim2.new(1, 0, 1, 0)
glassOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
glassOverlay.BackgroundTransparency = 0.92
glassOverlay.BorderSizePixel = 0
glassOverlay.Parent = MainWindow
glassOverlay.ZIndex = 1

local glassCorner = Instance.new("UICorner")
glassCorner.CornerRadius = UDim.new(0, 18)
glassCorner.Parent = glassOverlay

-- ─────────────────────────────────────────────────────────────────────────────
-- HEADER
-- ─────────────────────────────────────────────────────────────────────────────

local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 65)
Header.BackgroundColor3 = Colors.surface2
Header.BackgroundTransparency = 0.2
Header.BorderSizePixel = 0
Header.Parent = MainWindow
Header.ZIndex = 102

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 18)
headerCorner.Parent = Header

local headerDivider = Instance.new("Frame")
headerDivider.Size = UDim2.new(1, -30, 0, 0.5)
headerDivider.Position = UDim2.new(0, 15, 1, -1)
headerDivider.BackgroundColor3 = Colors.stroke
headerDivider.BackgroundTransparency = 0.8
headerDivider.BorderSizePixel = 0
headerDivider.Parent = Header
headerDivider.ZIndex = 103

local titleIcon = Instance.new("TextLabel")
titleIcon.Size = UDim2.new(0, 40, 0, 40)
titleIcon.Position = UDim2.new(0, 12, 0.5, -20)
titleIcon.BackgroundTransparency = 1
titleIcon.Text = "✨"
titleIcon.TextSize = 26
titleIcon.Font = Enum.Font.GothamBlack
titleIcon.Parent = Header
titleIcon.ZIndex = 103

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -100, 0, 22)
titleText.Position = UDim2.new(0, 54, 0, 10)
titleText.BackgroundTransparency = 1
titleText.Text = "Reanimation"
titleText.TextColor3 = Colors.text
titleText.TextSize = 19
titleText.Font = Enum.Font.GothamBlack
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = Header
titleText.ZIndex = 103

local subtitleText = Instance.new("TextLabel")
subtitleText.Size = UDim2.new(1, -100, 0, 16)
subtitleText.Position = UDim2.new(0, 54, 0, 32)
subtitleText.BackgroundTransparency = 1
subtitleText.Text = "Frosted Glass Experience"
subtitleText.TextColor3 = Colors.muted
subtitleText.TextSize = 10
subtitleText.Font = Enum.Font.Gotham
subtitleText.TextXAlignment = Enum.TextXAlignment.Left
subtitleText.Parent = Header
subtitleText.ZIndex = 103

-- Header Buttons
local function CreateHeaderBtn(icon, pos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 32, 0, 32)
    btn.Position = pos
    btn.BackgroundColor3 = Colors.surface3
    btn.BackgroundTransparency = 0.5
    btn.BorderSizePixel = 0
    btn.Text = icon
    btn.TextSize = 16
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Colors.muted
    btn.Parent = Header
    btn.ZIndex = 103
    btn.AutoButtonColor = false

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Colors.stroke
    stroke.Transparency = 0.7
    stroke.Thickness = 0.8
    stroke.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = Colors.surface2,
            BackgroundTransparency = 0.1,
            TextColor3 = Colors.text
        }):Play()
    end)

    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = Colors.surface3,
            BackgroundTransparency = 0.5,
            TextColor3 = Colors.muted
        }):Play()
    end)

    btn.MouseButton1Click:Connect(callback)
    return btn
end

local minimizeBtn = CreateHeaderBtn("−", UDim2.new(1, -74, 0.5, -16), function()
    State.isMinimized = not State.isMinimized
    local targetSize = State.isMinimized and UDim2.new(0, 350, 0, 65) or UDim2.new(0, 350, 0, 480)
    TweenService:Create(MainWindow, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize}):Play()
    minimizeBtn.Text = State.isMinimized and "+" or "−"
end)

local closeBtn = CreateHeaderBtn("×", UDim2.new(1, -38, 0.5, -16), function()
    if State.isReanimated then
        pcall(function() ReanimateAPI.reanimate(false) end)
    end
    TweenService:Create(MainWindow, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, -175, 0.5, -240),
        Size = UDim2.new(0, 350, 0, 0)
    }):Play()
    task.wait(0.25)
    ScreenGui:Destroy()
end)

-- Dragging
do
    local dragging, dragStart, dragStartPos

    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = Vector2.new(Mouse.X, Mouse.Y)
            dragStartPos = MainWindow.Position
        end
    end)

    Header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    RunService.RenderStepped:Connect(function()
        if dragging and dragStart then
            local delta = Vector2.new(Mouse.X, Mouse.Y) - dragStart
            MainWindow.Position = UDim2.new(dragStartPos.X.Scale, dragStartPos.X.Offset + delta.X, dragStartPos.Y.Scale, dragStartPos.Y.Offset + delta.Y)
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- CONTENT
-- ─────────────────────────────────────────────────────────────────────────────

local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, 0, 1, -65)
Content.Position = UDim2.new(0, 0, 0, 65)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.Parent = MainWindow
Content.ZIndex = 101

-- Toggle Section
local ToggleSection = Instance.new("Frame")
ToggleSection.Name = "ToggleSection"
ToggleSection.Size = UDim2.new(1, -24, 0, 50)
ToggleSection.Position = UDim2.new(0, 12, 0, 12)
ToggleSection.BackgroundColor3 = Colors.surface3
ToggleSection.BackgroundTransparency = 0.4
ToggleSection.BorderSizePixel = 0
ToggleSection.Parent = Content
ToggleSection.ZIndex = 101

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 10)
toggleCorner.Parent = ToggleSection

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Colors.stroke
toggleStroke.Transparency = 0.7
toggleStroke.Thickness = 0.8
toggleStroke.Parent = ToggleSection

local toggleLabel = Instance.new("TextLabel")
toggleLabel.Size = UDim2.new(0.5, 0, 1, 0)
toggleLabel.Position = UDim2.new(0, 12, 0, 0)
toggleLabel.BackgroundTransparency = 1
toggleLabel.Text = "Reanimation"
toggleLabel.TextColor3 = Colors.text
toggleLabel.TextSize = 13
toggleLabel.Font = Enum.Font.GothamSemibold
toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
toggleLabel.Parent = ToggleSection
toggleLabel.ZIndex = 102

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0, 75, 0, 32)
ToggleBtn.Position = UDim2.new(1, -87, 0.5, -16)
ToggleBtn.BackgroundColor3 = Colors.surface2
ToggleBtn.BackgroundTransparency = 0.3
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Text = "OFF"
ToggleBtn.TextColor3 = Colors.text
ToggleBtn.TextSize = 11
ToggleBtn.Font = Enum.Font.GothamBlack
ToggleBtn.Parent = ToggleSection
ToggleBtn.ZIndex = 102
ToggleBtn.AutoButtonColor = false

local toggleBtnCorner = Instance.new("UICorner")
toggleBtnCorner.CornerRadius = UDim.new(0, 6)
toggleBtnCorner.Parent = ToggleBtn

local toggleBtnStroke = Instance.new("UIStroke")
toggleBtnStroke.Color = Colors.accentWhite
toggleBtnStroke.Transparency = 0.7
toggleBtnStroke.Thickness = 0.8
toggleBtnStroke.Parent = ToggleBtn

local function UpdateToggleBtn()
    if State.isReanimated then
        TweenService:Create(ToggleBtn, TweenInfo.new(0.25), {BackgroundTransparency = 0, TextColor3 = Color3.fromRGB(0, 0, 0)}):Play()
        ToggleBtn.Text = "ON"
    else
        TweenService:Create(ToggleBtn, TweenInfo.new(0.25), {BackgroundTransparency = 0.3, TextColor3 = Colors.text}):Play()
        ToggleBtn.Text = "OFF"
    end
end

ToggleBtn.MouseButton1Click:Connect(function()
    if State.isReanimated then
        pcall(function() ReanimateAPI.reanimate(false) end)
        State.isReanimated = false
        State.selectedAnimation = nil
        Notify("Reanimation disabled")
    else
        pcall(function() ReanimateAPI.reanimate(true) end)
        State.isReanimated = true
        Notify("Reanimation enabled!")
    end
    UpdateToggleBtn()
end)

ToggleBtn.MouseEnter:Connect(function()
    TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.1}):Play()
end)

ToggleBtn.MouseLeave:Connect(function()
    if not State.isReanimated then
        TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.3}):Play()
    end
end)

-- Tab Section
local TabSection = Instance.new("Frame")
TabSection.Name = "TabSection"
TabSection.Size = UDim2.new(1, -24, 0, 40)
TabSection.Position = UDim2.new(0, 12, 0, 70)
TabSection.BackgroundTransparency = 1
TabSection.BorderSizePixel = 0
TabSection.Parent = Content
TabSection.ZIndex = 101

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.Padding = UDim.new(0, 8)
tabLayout.Parent = TabSection

local function CreateTab(icon, name, tabKey)
    local tab = Instance.new("TextButton")
    tab.Name = name .. "Tab"
    tab.Parent = TabSection
    tab.Size = UDim2.new(0, 195, 0, 32)
    tab.BackgroundColor3 = Colors.surface3
    tab.BackgroundTransparency = 0.6
    tab.BorderSizePixel = 0
    tab.Text = icon .. "  " .. name
    tab.TextColor3 = Colors.muted
    tab.TextSize = 11
    tab.Font = Enum.Font.GothamSemibold
    tab.AutoButtonColor = false
    tab.ZIndex = 102

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = tab

    local stroke = Instance.new("UIStroke")
    stroke.Color = Colors.stroke
    stroke.Transparency = 0.7
    stroke.Thickness = 0.8
    stroke.Parent = tab

    tab.MouseButton1Click:Connect(function()
        State.currentTab = tabKey
        RefreshAnimationList()
        
        for _, t in ipairs(TabSection:GetChildren()) do
            if t:IsA("TextButton") then
                local isActive = t == tab
                if isActive then
                    TweenService:Create(t, TweenInfo.new(0.2), {
                        BackgroundColor3 = Colors.accentWhite,
                        BackgroundTransparency = 0.15,
                        TextColor3 = Color3.fromRGB(0, 0, 0)
                    }):Play()
                else
                    TweenService:Create(t, TweenInfo.new(0.2), {
                        BackgroundColor3 = Colors.surface3,
                        BackgroundTransparency = 0.6,
                        TextColor3 = Colors.muted
                    }):Play()
                end
            end
        end
    end)

    tab.MouseEnter:Connect(function()
        if State.currentTab ~= tabKey then
            TweenService:Create(tab, TweenInfo.new(0.15), {BackgroundTransparency = 0.4}):Play()
        end
    end)

    tab.MouseLeave:Connect(function()
        if State.currentTab ~= tabKey then
            TweenService:Create(tab, TweenInfo.new(0.15), {BackgroundTransparency = 0.6}):Play()
        end
    end)

    return tab
end

local AllTab = CreateTab("📋", "All", "All")
local FavoritesTab = CreateTab("⭐", "Favorites", "Favorites")

AllTab.BackgroundColor3 = Colors.accentWhite
AllTab.BackgroundTransparency = 0.15
AllTab.TextColor3 = Color3.fromRGB(0, 0, 0)

-- Search Box
local SearchBox = Instance.new("TextBox")
SearchBox.Name = "SearchBox"
SearchBox.Size = UDim2.new(1, -24, 0, 36)
SearchBox.Position = UDim2.new(0, 12, 0, 118)
SearchBox.BackgroundColor3 = Colors.surface3
SearchBox.BackgroundTransparency = 0.4
SearchBox.BorderSizePixel = 0
SearchBox.Text = ""
SearchBox.PlaceholderText = "🔍 Search..."
SearchBox.TextColor3 = Colors.text
SearchBox.PlaceholderColor3 = Colors.muted
SearchBox.TextSize = 11
SearchBox.Font = Enum.Font.Gotham
SearchBox.ClearTextOnFocus = false
SearchBox.Parent = Content
SearchBox.ZIndex = 101

local searchCorner = Instance.new("UICorner")
searchCorner.CornerRadius = UDim.new(0, 8)
searchCorner.Parent = SearchBox

local searchStroke = Instance.new("UIStroke")
searchStroke.Color = Colors.stroke
searchStroke.Transparency = 0.7
searchStroke.Thickness = 0.8
searchStroke.Parent = SearchBox

local searchPadding = Instance.new("UIPadding")
searchPadding.PaddingLeft = UDim.new(0, 10)
searchPadding.PaddingRight = UDim.new(0, 10)
searchPadding.Parent = SearchBox

-- Animations Scroll
local AnimationsScroll = Instance.new("ScrollingFrame")
AnimationsScroll.Name = "AnimationsScroll"
AnimationsScroll.Size = UDim2.new(1, -24, 0, 310)
AnimationsScroll.Position = UDim2.new(0, 12, 0, 162)
AnimationsScroll.BackgroundTransparency = 1
AnimationsScroll.BorderSizePixel = 0
AnimationsScroll.ScrollBarThickness = 4
AnimationsScroll.ScrollBarImageColor3 = Colors.accentWhite
AnimationsScroll.ScrollBarImageTransparency = 0.6
AnimationsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
AnimationsScroll.Parent = Content
AnimationsScroll.ZIndex = 101

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 5)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = AnimationsScroll

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    AnimationsScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end)

-- Speed Control
local SpeedSection = Instance.new("Frame")
SpeedSection.Name = "SpeedSection"
SpeedSection.Size = UDim2.new(1, -24, 0, 40)
SpeedSection.Position = UDim2.new(0, 12, 1, -52)
SpeedSection.BackgroundColor3 = Colors.surface3
SpeedSection.BackgroundTransparency = 0.4
SpeedSection.BorderSizePixel = 0
SpeedSection.Parent = Content
SpeedSection.ZIndex = 101

local speedCorner = Instance.new("UICorner")
speedCorner.CornerRadius = UDim.new(0, 8)
speedCorner.Parent = SpeedSection

local speedStroke = Instance.new("UIStroke")
speedStroke.Color = Colors.stroke
speedStroke.Transparency = 0.7
speedStroke.Thickness = 0.8
speedStroke.Parent = SpeedSection

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0, 50, 1, 0)
speedLabel.Position = UDim2.new(0, 10, 0, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed"
speedLabel.TextColor3 = Colors.text
speedLabel.TextSize = 11
speedLabel.Font = Enum.Font.GothamSemibold
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = SpeedSection
speedLabel.ZIndex = 102

local SpeedInput = Instance.new("TextBox")
SpeedInput.Size = UDim2.new(0, 55, 0, 26)
SpeedInput.Position = UDim2.new(1, -65, 0.5, -13)
SpeedInput.BackgroundColor3 = Colors.accentWhite
SpeedInput.BackgroundTransparency = 0.6
SpeedInput.BorderSizePixel = 0
SpeedInput.Text = "1.0"
SpeedInput.TextColor3 = Color3.fromRGB(0, 0, 0)
SpeedInput.TextSize = 11
SpeedInput.Font = Enum.Font.GothamBold
SpeedInput.Parent = SpeedSection
SpeedInput.ZIndex = 102

local speedInputCorner = Instance.new("UICorner")
speedInputCorner.CornerRadius = UDim.new(0, 6)
speedInputCorner.Parent = SpeedInput

local speedInputStroke = Instance.new("UIStroke")
speedInputStroke.Color = Colors.accentWhite
speedInputStroke.Transparency = 0.7
speedInputStroke.Thickness = 0.8
speedInputStroke.Parent = SpeedInput

SpeedInput.FocusLost:Connect(function()
    local speed = tonumber(SpeedInput.Text)
    if speed and speed > 0 then
        State.currentSpeed = speed
        ReanimateAPI.set_animation_speed(State.currentSpeed)
        Notify("Speed: " .. State.currentSpeed .. "x")
    else
        SpeedInput.Text = tostring(State.currentSpeed)
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- ANIMATION BUTTON
-- ─────────────────────────────────────────────────────────────────────────────

local function CreateAnimationButton(name, url)
    local btnBg = Instance.new("Frame")
    btnBg.Name = name
    btnBg.Parent = AnimationsScroll
    btnBg.Size = UDim2.new(1, -8, 0, 38)
    btnBg.BackgroundColor3 = Colors.surface3
    btnBg.BackgroundTransparency = 0.6
    btnBg.BorderSizePixel = 0
    btnBg.ZIndex = 102

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btnBg

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Colors.stroke
    btnStroke.Transparency = 0.7
    btnStroke.Thickness = 0.8
    btnStroke.Parent = btnBg

    local playBtn = Instance.new("TextButton")
    playBtn.Size = UDim2.new(1, -110, 1, 0)
    playBtn.Position = UDim2.new(0, 10, 0, 0)
    playBtn.BackgroundTransparency = 1
    playBtn.Text = name
    playBtn.TextColor3 = Colors.text
    playBtn.TextSize = 11
    playBtn.Font = Enum.Font.Gotham
    playBtn.TextXAlignment = Enum.TextXAlignment.Left
    playBtn.TextTruncate = Enum.TextTruncate.AtEnd
    playBtn.Parent = btnBg
    playBtn.ZIndex = 103

    local keyBtn = Instance.new("TextButton")
    keyBtn.Size = UDim2.new(0, 38, 0, 26)
    keyBtn.Position = UDim2.new(1, -100, 0.5, -13)
    keyBtn.BackgroundColor3 = Colors.accentLight
    keyBtn.BackgroundTransparency = 0.5
    keyBtn.BorderSizePixel = 0
    keyBtn.Text = Keybinds[name] and "[" .. Keybinds[name] .. "]" or "[+]"
    keyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    keyBtn.TextSize = 9
    keyBtn.Font = Enum.Font.GothamBold
    keyBtn.Parent = btnBg
    keyBtn.ZIndex = 103
    keyBtn.AutoButtonColor = false

    local keyCorner = Instance.new("UICorner")
    keyCorner.CornerRadius = UDim.new(0, 6)
    keyCorner.Parent = keyBtn

    local keyStroke = Instance.new("UIStroke")
    keyStroke.Color = Colors.accentWhite
    keyStroke.Transparency = 0.6
    keyStroke.Thickness = 0.8
    keyStroke.Parent = keyBtn

    local favBtn = Instance.new("TextButton")
    favBtn.Size = UDim2.new(0, 38, 0, 26)
    favBtn.Position = UDim2.new(1, -56, 0.5, -13)
    favBtn.BackgroundColor3 = Favorites[name] and Colors.accentWhite or Colors.surface3
    favBtn.BackgroundTransparency = Favorites[name] and 0.3 or 0.7
    favBtn.BorderSizePixel = 0
    favBtn.Text = Favorites[name] and "★" or "☆"
    favBtn.TextColor3 = Favorites[name] and Color3.fromRGB(0, 0, 0) or Colors.muted
    favBtn.TextSize = 14
    favBtn.Font = Enum.Font.GothamBold
    favBtn.Parent = btnBg
    favBtn.ZIndex = 103
    favBtn.AutoButtonColor = false

    local favCorner = Instance.new("UICorner")
    favCorner.CornerRadius = UDim.new(0, 6)
    favCorner.Parent = favBtn

    local favStroke = Instance.new("UIStroke")
    favStroke.Color = Colors.stroke
    favStroke.Transparency = Favorites[name] and 0.5 or 0.7
    favStroke.Thickness = 0.8
    favStroke.Parent = favBtn

    local function UpdateState()
        local isPlaying = State.selectedAnimation == name
        if isPlaying then
            TweenService:Create(btnBg, TweenInfo.new(0.2), {
                BackgroundColor3 = Colors.accentWhite,
                BackgroundTransparency = 0.2
            }):Play()
            TweenService:Create(playBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(0, 0, 0)}):Play()
        else
            TweenService:Create(btnBg, TweenInfo.new(0.2), {
                BackgroundColor3 = Colors.surface3,
                BackgroundTransparency = 0.6
            }):Play()
            TweenService:Create(playBtn, TweenInfo.new(0.2), {TextColor3 = Colors.text}):Play()
        end
    end

    playBtn.MouseButton1Click:Connect(function()
        if not State.isReanimated then
            Notify("Enable reanimation first")
            return
        end

        if State.selectedAnimation == name then
            ReanimateAPI.stop_animation()
            State.selectedAnimation = nil
            Notify("Animation stopped")
        else
            -- Attempt to play with retry logic
            local success = false
            local attempts = 0
            local maxAttempts = 3
            
            while not success and attempts < maxAttempts do
                attempts = attempts + 1
                local ok, err = pcall(function()
                    ReanimateAPI.play_animation(url, State.currentSpeed)
                    success = true
                end)
                
                if not ok then
                    if attempts < maxAttempts then
                        task.wait(0.5)  -- Wait before retry
                    else
                        Notify("Failed to load animation", 2)
                        return
                    end
                end
            end
            
            if success then
                State.selectedAnimation = name
                Notify("Playing: " .. name)
            end
        end

        UpdateState()
        RefreshAnimationList()
    end)

    favBtn.MouseButton1Click:Connect(function()
        if Favorites[name] then
            Favorites[name] = nil
            TweenService:Create(favBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = Colors.surface3,
                BackgroundTransparency = 0.7,
                TextColor3 = Colors.muted
            }):Play()
            TweenService:Create(favStroke, TweenInfo.new(0.2), {Transparency = 0.7}):Play()
            favBtn.Text = "☆"
            Notify("Removed from favorites")
        else
            Favorites[name] = url
            TweenService:Create(favBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = Colors.accentWhite,
                BackgroundTransparency = 0.3,
                TextColor3 = Color3.fromRGB(0, 0, 0)
            }):Play()
            TweenService:Create(favStroke, TweenInfo.new(0.2), {Transparency = 0.5}):Play()
            favBtn.Text = "★"
            Notify("Added to favorites!")
        end
        SaveData()
    end)

    keyBtn.MouseButton1Click:Connect(function()
        State.listeningForKeybind = true
        State.listeningButton = keyBtn

        TweenService:Create(keyBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Colors.accentMid
        }):Play()
        keyBtn.Text = "..."
    end)

    btnBg.MouseEnter:Connect(function()
        if State.selectedAnimation ~= name then
            TweenService:Create(btnBg, TweenInfo.new(0.15), {BackgroundTransparency = 0.4}):Play()
        end
    end)

    btnBg.MouseLeave:Connect(function()
        if State.selectedAnimation ~= name then
            TweenService:Create(btnBg, TweenInfo.new(0.15), {BackgroundTransparency = 0.6}):Play()
        end
    end)

    AnimationButtons[name] = {btn = btnBg, play = playBtn, key = keyBtn, updateState = UpdateState}
    return btnBg
end

-- ─────────────────────────────────────────────────────────────────────────────
-- ANIMATION LIST
-- ─────────────────────────────────────────────────────────────────────────────

RefreshAnimationList = function()
    for _, btn in pairs(AnimationButtons) do
        btn.btn:Destroy()
    end
    AnimationButtons = {}

    local list = State.currentTab == "All" and AnimationList or Favorites

    local names = {}
    for name in pairs(list) do
        table.insert(names, name)
    end
    table.sort(names)

    local searchText = SearchBox.Text:lower()
    for _, name in ipairs(names) do
        if searchText == "" or name:lower():find(searchText, 1, true) then
            CreateAnimationButton(name, list[name])
        end
    end
end

SearchBox:GetPropertyChangedSignal("Text"):Connect(RefreshAnimationList)

-- ─────────────────────────────────────────────────────────────────────────────
-- KEYBINDS
-- ─────────────────────────────────────────────────────────────────────────────

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if State.listeningForKeybind and input.UserInputType == Enum.UserInputType.Keyboard then
        local keyName = input.KeyCode.Name

        if keyName == "Escape" then
            State.listeningForKeybind = false
            TweenService:Create(State.listeningButton, TweenInfo.new(0.2), {
                BackgroundColor3 = Colors.accentLight
            }):Play()
            State.listeningButton.Text = "[+]"
            State.listeningButton = nil
            return
        end

        local animName = nil
        for name, data in pairs(AnimationButtons) do
            if data.key == State.listeningButton then
                animName = name
                break
            end
        end

        if animName then
            Keybinds[animName] = keyName
            SaveData()
            State.listeningButton.Text = "[" .. keyName .. "]"
            TweenService:Create(State.listeningButton, TweenInfo.new(0.2), {
                BackgroundColor3 = Colors.accentLight
            }):Play()
            Notify("Keybind set: " .. keyName)
        end

        State.listeningForKeybind = false
        State.listeningButton = nil
        return
    end

    if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
        local keyName = input.KeyCode.Name
        for animName, keyBind in pairs(Keybinds) do
            if keyBind == keyName then
                if not State.isReanimated then return end

                if State.selectedAnimation == animName then
                    ReanimateAPI.stop_animation()
                    State.selectedAnimation = nil
                    Notify("Animation stopped")
                else
                    if AnimationList[animName] then
                        ReanimateAPI.play_animation(AnimationList[animName], State.currentSpeed)
                        State.selectedAnimation = animName
                        Notify("Playing: " .. animName)
                    elseif Favorites[animName] then
                        ReanimateAPI.play_animation(Favorites[animName], State.currentSpeed)
                        State.selectedAnimation = animName
                        Notify("Playing: " .. animName)
                    end
                end

                RefreshAnimationList()
                break
            end
        end
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- STATUS
-- ─────────────────────────────────────────────────────────────────────────────

RunService.RenderStepped:Connect(function()
    local apiState = ReanimateAPI.is_reanimated()
    if apiState ~= State.isReanimated then
        State.isReanimated = apiState
        State.selectedAnimation = nil
        UpdateToggleBtn()
    end

    local playing, url = ReanimateAPI.is_animation_playing()
    if not playing and State.selectedAnimation then
        State.selectedAnimation = nil
        RefreshAnimationList()
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- INIT
-- ─────────────────────────────────────────────────────────────────────────────

RefreshAnimationList()
UpdateToggleBtn()
Notify("✨ Frosted Glass Menu Ready!", 3)

print("✨ Orca Frosted Theme Reanimation Menu loaded!")
