--[[
    OnyxV2    By Biscuit
    Main script — auth is handled by the loader.
]]

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SERVICES & GLOBALS                                          ║
-- ╚══════════════════════════════════════════════════════════════╝
-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local plr = Players.LocalPlayer
local mouse = plr:GetMouse()

-- local httpRequest
do
    local candidates = {
        function() return request end,
        function() return http and http.request end,
        function() return http_request end,
        function() return syn and syn.request end,
        function() return fluxus and fluxus.request end,
    }
    for _, getter in ipairs(candidates) do
        local ok, fn = pcall(getter)
        if ok and type(fn) == "function" then
            httpRequest = fn
            break
        end
    end
    if not httpRequest then
        httpRequest = function(opts)
            return { Success = false, StatusCode = 0, Body = "" }
        end
    end
end

local function GetService(sn)
    if cloneref then
        return cloneref(game:GetService(sn))
    else
        return game:GetService(sn)
    end
end

local VoiceChatService = (function() local ok, s = pcall(GetService, 'VoiceChatService') return ok and s or nil end)()
local VoiceChatInternal = (function() local ok, s = pcall(GetService, 'VoiceChatInternal') return ok and s or nil end)()
	
local canUsePhysicsRep = false
do
    local execName = ""
    pcall(function() execName = string.lower(tostring(identifyexecutor and identifyexecutor() or "")) end)
    
    if execName:match("xeno") then
        canUsePhysicsRep = false
    elseif sethiddenproperty then
        local ok = pcall(function()
            local char = Players.LocalPlayer.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    sethiddenproperty(hrp, "PhysicsRepRootPart", hrp)
                end
            end
        end)
        canUsePhysicsRep = ok
    end
end

local TargetedPlayer = nil

local activeOnyxTagIds = {}

GetPlayer = function(UserDisplay)
    if UserDisplay ~= "" then
        for i,v in pairs(Players:GetPlayers()) do
            if v.Name:lower():match(UserDisplay:lower()) or v.DisplayName:lower():match(UserDisplay:lower()) then
                return v
            end
        end
        return nil
    else
        return nil
    end
end

GetCharacter = function(Player)
    if Player and Player.Character then
        return Player.Character
    end
end

GetRoot = function(Player)
    local char = GetCharacter(Player)
    if char and char:FindFirstChild("HumanoidRootPart") then
        return char.HumanoidRootPart
    end
end

notifCount = 0
NotifContainer = nil -- defined after OnyxUI is created

SendNotify = function(title, message, duration)
    if not NotifContainer then return end
    notifCount = notifCount + 1
    local order = notifCount
    duration = duration or 3

    local wrapper = Instance.new("Frame")
    wrapper.Name = "NotifWrap_" .. order
    wrapper.Parent = NotifContainer
    wrapper.BackgroundTransparency = 1
    wrapper.BorderSizePixel = 0
    wrapper.Size = UDim2.new(1, 0, 0, 64)   -- full height always
    wrapper.ClipsDescendants = true
    wrapper.LayoutOrder = -order

    local card = Instance.new("Frame")
    card.Name = "Card"
    card.Parent = wrapper
    card.BackgroundColor3 = Color3.fromRGB(9, 9, 18)
    card.BackgroundTransparency = 0.08
    card.BorderSizePixel = 0
    card.AnchorPoint = Vector2.new(1, 0)
    card.Position = UDim2.new(1, 0, 0, 0)
    card.Size = UDim2.new(1, 0, 1, 0)
    card.ClipsDescendants = false
    card.ZIndex = 100
    do
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 11); c.Parent = card
        local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255,255,255)
        s.Transparency = 0.76; s.Thickness = 1.2; s.Parent = card
        local bar = Instance.new("Frame"); bar.Parent = card
        bar.BackgroundColor3 = Color3.fromRGB(200, 80, 255)
        bar.BorderSizePixel = 0; bar.Size = UDim2.new(0, 3, 1, 0); bar.ZIndex = 101
        do local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,11); bc.Parent = bar end
        local overlay = Instance.new("Frame"); overlay.Parent = card
        overlay.BackgroundColor3 = Color3.fromRGB(185, 195, 255)
        overlay.BackgroundTransparency = 0.95; overlay.BorderSizePixel = 0
        overlay.Size = UDim2.new(1, 0, 1, 0); overlay.ZIndex = 100
        do local oc = Instance.new("UICorner"); oc.CornerRadius = UDim.new(0,11); oc.Parent = overlay end
    end

    local titleLbl = Instance.new("TextLabel"); titleLbl.Parent = card
    titleLbl.BackgroundTransparency = 1
    titleLbl.Position = UDim2.new(0, 14, 0, 8)
    titleLbl.Size = UDim2.new(1, -22, 0, 20)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.Text = title
    titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLbl.TextSize = 12
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
    titleLbl.ZIndex = 102

    local msgLbl = Instance.new("TextLabel"); msgLbl.Parent = card
    msgLbl.BackgroundTransparency = 1
    msgLbl.Position = UDim2.new(0, 14, 0, 30)
    msgLbl.Size = UDim2.new(1, -22, 0, 20)
    msgLbl.Font = Enum.Font.Gotham
    msgLbl.Text = message
    msgLbl.TextColor3 = Color3.fromRGB(170, 170, 200)
    msgLbl.TextSize = 11
    msgLbl.TextXAlignment = Enum.TextXAlignment.Left
    msgLbl.TextTruncate = Enum.TextTruncate.AtEnd
    msgLbl.ZIndex = 102

    local progressBg = Instance.new("Frame"); progressBg.Parent = card
    progressBg.BackgroundColor3 = Color3.fromRGB(255,255,255)
    progressBg.BackgroundTransparency = 0.88; progressBg.BorderSizePixel = 0
    progressBg.Position = UDim2.new(0, 3, 1, -5)
    progressBg.Size = UDim2.new(1, -6, 0, 3); progressBg.ZIndex = 102
    do local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(1,0); pc.Parent = progressBg end

    local progressFill = Instance.new("Frame"); progressFill.Parent = progressBg
    progressFill.BackgroundColor3 = Color3.fromRGB(200, 80, 255)
    progressFill.BorderSizePixel = 0
    progressFill.Size = UDim2.new(1, 0, 1, 0); progressFill.ZIndex = 103
    do local pfc = Instance.new("UICorner"); pfc.CornerRadius = UDim.new(1,0); pfc.Parent = progressFill end

    task.spawn(function()
        wrapper.Size = UDim2.new(0, 0, 0, 64)
        TweenService:Create(wrapper, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, 64)
        }):Play()

        task.wait(0.05) -- let slide finish before draining
        TweenService:Create(progressFill, TweenInfo.new(duration - 0.05, Enum.EasingStyle.Linear), {
            Size = UDim2.new(0, 0, 1, 0)
        }):Play()

        task.wait(duration)

        TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            BackgroundTransparency = 1
        }):Play()
        TweenService:Create(titleLbl, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
        TweenService:Create(msgLbl,   TweenInfo.new(0.2), {TextTransparency = 1}):Play()
        task.wait(0.1)
        TweenService:Create(wrapper, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Size = UDim2.new(1, 0, 0, 0)
        }):Play()
        task.wait(0.28)
        wrapper:Destroy()
    end)
end

local function TeleportTO(player)
    pcall(function()
        if GetRoot(plr) and GetRoot(player) then
            GetRoot(plr).CFrame = GetRoot(player).CFrame * CFrame.new(0, 2, 0)
        end
    end)
end

OnyxUI = Instance.new("ScreenGui")
OnyxUI.Name = "OnyxUI"

HideTagsGui = Instance.new("ScreenGui")
HideTagsGui.Name = "OnyxHideTagsGui"
HideTagsGui.ResetOnSpawn = false
pcall(function() HideTagsGui.Parent = game:GetService("CoreGui") end)
if not HideTagsGui.Parent then HideTagsGui.Parent = plr:WaitForChild("PlayerGui") end

HideTagsBtn = Instance.new("TextButton")
HideTagsBtn.Parent = HideTagsGui
HideTagsBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
HideTagsBtn.BackgroundTransparency = 0.5
HideTagsBtn.Position = UDim2.new(1, -120, 0, 10)
HideTagsBtn.Size = UDim2.new(0, 110, 0, 30)
HideTagsBtn.Font = Enum.Font.GothamBold
HideTagsBtn.Text = "👁️ Hide Tags"
HideTagsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HideTagsBtn.TextSize = 12
do local htCorner = Instance.new("UICorner")
htCorner.CornerRadius = UDim.new(0, 8)
htCorner.Parent = HideTagsBtn end
do local htStroke = Instance.new("UIStroke")
htStroke.Color = Color3.fromRGB(255, 255, 255)
htStroke.Transparency = 0.7
htStroke.Parent = HideTagsBtn end

HideTagsBtn.MouseButton1Click:Connect(function()
    GlobalHideNametags = not GlobalHideNametags
    HideTagsBtn.Text = GlobalHideNametags and "🚫 Show Tags" or "👁️ Hide Tags"
    SendNotify("Nametags", GlobalHideNametags and "All nametags hidden" or "Nametags visible", 2)
    -- Scan CoreGui (where other players' tags live)
    pcall(function()
        for _, tag in ipairs(game:GetService("CoreGui"):GetDescendants()) do
            if tag:IsA("BillboardGui") and (tag.Name:sub(1, 12) == "OnyxNametag_" or tag.Name == "OnyxSelfTag") then
                tag.Enabled = not GlobalHideNametags
            end
        end
    end)
    -- Scan PlayerGui (where self-tag lives)
    pcall(function()
        for _, tag in ipairs(plr.PlayerGui:GetDescendants()) do
            if tag:IsA("BillboardGui") and (tag.Name == "OnyxSelfTag" or tag.Name:sub(1, 12) == "OnyxNametag_") then
                tag.Enabled = not GlobalHideNametags
            end
        end
    end)
    -- Scan workspace characters (fallback location for tags)
    pcall(function()
        for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
            if p.Character then
                for _, tag in ipairs(p.Character:GetDescendants()) do
                    if tag:IsA("BillboardGui") and (tag.Name:sub(1, 12) == "OnyxNametag_" or tag.Name == "OnyxSelfTag") then
                        tag.Enabled = not GlobalHideNametags
                    end
                end
            end
        end
    end)
end)
OnyxUI.Parent = game.CoreGui
OnyxUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
OnyxUI.ResetOnSpawn = false

NotifContainer = Instance.new("Frame")
NotifContainer.Name = "OnyxNotifContainer"
NotifContainer.Parent = OnyxUI
NotifContainer.BackgroundTransparency = 1
NotifContainer.AnchorPoint = Vector2.new(1, 1)
NotifContainer.Position = UDim2.new(1, -14, 1, -14)
NotifContainer.Size = UDim2.new(0, 290, 0.6, 0)
NotifContainer.ZIndex = 200
NotifContainer.ClipsDescendants = false
do
    local l = Instance.new("UIListLayout"); l.Parent = NotifContainer
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.VerticalAlignment = Enum.VerticalAlignment.Bottom
    l.HorizontalAlignment = Enum.HorizontalAlignment.Right
    l.Padding = UDim.new(0, 6)
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  GUI — VC MUTE PILL BUTTON (top-left, always visible)        ║
-- ╚══════════════════════════════════════════════════════════════╝
-- Sits above the native Roblox VC button (top-left area), always visible.
do
    local vcMuteGui = Instance.new("ScreenGui")
    vcMuteGui.Name = "OnyxVCMuteBtn"
    vcMuteGui.Parent = game.CoreGui
    vcMuteGui.ResetOnSpawn = false
    vcMuteGui.DisplayOrder = 999998
    vcMuteGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Pill-shaped button
    local pill = Instance.new("TextButton")
    pill.Name = "MuteToggle"
    pill.Parent = vcMuteGui
    pill.AnchorPoint = Vector2.new(0, 0)
    pill.Position = UDim2.new(0, 10, 0, 10)
    pill.Size = UDim2.new(0, 110, 0, 36)
    pill.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    pill.BackgroundTransparency = 0.25
    pill.BorderSizePixel = 0
    pill.Font = Enum.Font.GothamBold
    pill.Text = "🎤 Mute"
    pill.TextColor3 = Color3.fromRGB(255, 255, 255)
    pill.TextSize = 13
    pill.AutoButtonColor = false
    pill.ZIndex = 10
    do
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = pill
        local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255,255,255)
        s.Transparency = 0.78; s.Thickness = 1.2; s.Parent = pill
    end

    -- Keep label/color in sync with real mic state
    local function syncMuteBtn()
        if not VoiceChatInternal then
            pill.Text = "🎤 VC N/A"
            pill.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            return
        end
        local ok, paused = pcall(function() return VoiceChatInternal:IsPublishPaused() end)
        if not ok then return end
        if paused then
            pill.Text = "🎤 Unmute"
            pill.BackgroundColor3 = Color3.fromRGB(60, 15, 15)
        else
            pill.Text = "🔇 Mute"
            pill.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
        end
    end

    pill.MouseButton1Click:Connect(function()
        if not VoiceChatInternal then return end
        local ok, paused = pcall(function() return VoiceChatInternal:IsPublishPaused() end)
        if ok then pcall(function() VoiceChatInternal:PublishPause(not paused) end) end
        task.wait(0.05)
        syncMuteBtn()
    end)

    -- Hover glow
    pill.MouseEnter:Connect(function()
        TweenService:Create(pill, TweenInfo.new(0.15), {BackgroundTransparency = 0.05}):Play()
    end)
    pill.MouseLeave:Connect(function()
        TweenService:Create(pill, TweenInfo.new(0.15), {BackgroundTransparency = 0.25}):Play()
    end)

    -- Poll every 0.3s to stay in sync with Roblox native VC button
    task.spawn(function()
        while pill and pill.Parent do
            syncMuteBtn()
            task.wait(0.3)
        end
    end)

    syncMuteBtn()
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  GUI — MAIN WINDOW                                           ║
-- ╚══════════════════════════════════════════════════════════════╝
-- Main Frame (Glass Effect — Orca dark style)
MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = OnyxUI
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
MainFrame.BackgroundTransparency = 0.05
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.Size = UDim2.new(0, 560, 0, 415)
MainFrame.ClipsDescendants = true
MainFrame.Active = true

-- Corner for Main Frame
do
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 16)
    MainCorner.Parent = MainFrame

    -- Orca-style accent border: subtle purple/pink tint
    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Color3.fromRGB(180, 100, 255)
    MainStroke.Transparency = 0.7
    MainStroke.Thickness = 1.5
    MainStroke.Parent = MainFrame

    -- Frosted overlay — very subtle purple tint like Orca
    local BlurOverlay = Instance.new("Frame")
    BlurOverlay.Name = "BlurOverlay"
    BlurOverlay.Parent = MainFrame
    BlurOverlay.BackgroundColor3 = Color3.fromRGB(140, 80, 255)
    BlurOverlay.BackgroundTransparency = 0.97
    BlurOverlay.BorderSizePixel = 0
    BlurOverlay.Size = UDim2.new(1, 0, 1, 0)
    BlurOverlay.ZIndex = 1
    local BlurCorner = Instance.new("UICorner")
    BlurCorner.CornerRadius = UDim.new(0, 16)
    BlurCorner.Parent = BlurOverlay
end

-- Title Bar — Orca style: deeper dark, purple-pink accent strip
TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Parent = MainFrame
TitleBar.BackgroundColor3 = Color3.fromRGB(18, 18, 30)
TitleBar.BackgroundTransparency = 0.0
TitleBar.BorderSizePixel = 0
TitleBar.Size = UDim2.new(1, 0, 0, 48)
TitleBar.ZIndex = 2
do
    local TitleBarCorner = Instance.new("UICorner")
    TitleBarCorner.CornerRadius = UDim.new(0, 16)
    TitleBarCorner.Parent = TitleBar

    -- Orca-style bottom separator with purple accent
    local TitleBorder = Instance.new("Frame")
    TitleBorder.Name = "TitleBorder"
    TitleBorder.Parent = TitleBar
    TitleBorder.BackgroundColor3 = Color3.fromRGB(160, 80, 255)
    TitleBorder.BackgroundTransparency = 0.6
    TitleBorder.BorderSizePixel = 0
    TitleBorder.Position = UDim2.new(0, 12, 1, -1)
    TitleBorder.Size = UDim2.new(1, -24, 0, 1)
    TitleBorder.ZIndex = 3
end

-- Title Text
TitleText = Instance.new("TextLabel")
TitleText.Name = "TitleText"
TitleText.Parent = TitleBar
TitleText.BackgroundTransparency = 1
TitleText.Position = UDim2.new(0, 18, 0, 5)
TitleText.Size = UDim2.new(1, -120, 0, 22)
TitleText.Font = Enum.Font.GothamBlack
TitleText.Text = "ONYX"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.TextSize = 17
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.ZIndex = 3

-- Subtitle Text
SubtitleText = Instance.new("TextLabel")
SubtitleText.Name = "SubtitleText"
SubtitleText.Parent = TitleBar
SubtitleText.BackgroundTransparency = 1
SubtitleText.Position = UDim2.new(0, 18, 0, 28)
SubtitleText.Size = UDim2.new(0.5, 0, 0, 14)
SubtitleText.Font = Enum.Font.Gotham
SubtitleText.Text = "by Biscuit"
SubtitleText.TextColor3 = Color3.fromRGB(160, 100, 255)
SubtitleText.TextSize = 11
SubtitleText.TextXAlignment = Enum.TextXAlignment.Left
SubtitleText.ZIndex = 3

-- Minimize Button — Orca style
MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Parent = TitleBar
MinimizeButton.AnchorPoint = Vector2.new(1, 0.5)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(160, 80, 255)
MinimizeButton.BackgroundTransparency = 0.75
MinimizeButton.BorderSizePixel = 0
MinimizeButton.Position = UDim2.new(1, -10, 0.5, 0)
MinimizeButton.Size = UDim2.new(0, 26, 0, 26)
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.Text = "−"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.TextSize = 18
MinimizeButton.ZIndex = 3
MinimizeButton.AutoButtonColor = false
do
    local MinimizeCorner = Instance.new("UICorner")
    MinimizeCorner.CornerRadius = UDim.new(0, 7)
    MinimizeCorner.Parent = MinimizeButton
end

-- Close Button

-- Content Container
ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Parent = MainFrame
ContentContainer.BackgroundTransparency = 1
ContentContainer.BorderSizePixel = 0
ContentContainer.Position = UDim2.new(0, 0, 0, 48)
ContentContainer.Size = UDim2.new(1, 0, 1, -48)
ContentContainer.ZIndex = 2

-- Tab Container — Orca sidebar style
TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Parent = ContentContainer
TabContainer.BackgroundColor3 = Color3.fromRGB(18, 18, 30)
TabContainer.BackgroundTransparency = 0.0
TabContainer.BorderSizePixel = 0
TabContainer.Position = UDim2.new(0, 10, 0, 10)
TabContainer.Size = UDim2.new(0, 118, 1, -20)
TabContainer.ZIndex = 2
do
    local TabCorner = Instance.new("UICorner")
    TabCorner.CornerRadius = UDim.new(0, 12)
    TabCorner.Parent = TabContainer
    local TabStroke = Instance.new("UIStroke")
    TabStroke.Color = Color3.fromRGB(160, 80, 255)
    TabStroke.Transparency = 0.82
    TabStroke.Thickness = 1
    TabStroke.Parent = TabContainer
end

-- Tab List Layout
do
    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.Parent = TabContainer
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 4)

    local TabPadding = Instance.new("UIPadding")
    TabPadding.Parent = TabContainer
    TabPadding.PaddingTop = UDim.new(0, 8)
    TabPadding.PaddingBottom = UDim.new(0, 8)
    TabPadding.PaddingLeft = UDim.new(0, 7)
    TabPadding.PaddingRight = UDim.new(0, 7)
end

-- Function to create tab buttons
local function CreateTab(name, order)
    local TabButton = Instance.new("TextButton")
    TabButton.Name = name .. "Tab"
    TabButton.Parent = TabContainer
    TabButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TabButton.BackgroundTransparency = 1
    TabButton.BorderSizePixel = 0
    TabButton.Size = UDim2.new(1, 0, 0, 32)
    TabButton.Font = Enum.Font.GothamMedium
    TabButton.Text = name
    TabButton.TextColor3 = Color3.fromRGB(160, 160, 185)
    TabButton.TextSize = 12
    TabButton.TextXAlignment = Enum.TextXAlignment.Left
    TabButton.ZIndex = 3
    TabButton.LayoutOrder = order
    TabButton.AutoButtonColor = false
    
    local TabButtonPadding = Instance.new("UIPadding")
    TabButtonPadding.Parent = TabButton
    TabButtonPadding.PaddingLeft = UDim.new(0, 10)
    
    local TabButtonCorner = Instance.new("UICorner")
    TabButtonCorner.CornerRadius = UDim.new(0, 7)
    TabButtonCorner.Parent = TabButton
    
    return TabButton
end

-- Create Tabs
HomeTab = CreateTab("Home", 1)
PlayerTab = CreateTab("Player", 2)
AnimationTab = CreateTab("Animation", 3)
CombatTab = CreateTab("Combat", 4)
VisualTab = CreateTab("Visual", 5)
MiscTab = CreateTab("Misc", 6)

-- Set Home tab as default selected
HomeTab.BackgroundTransparency = 0.82
HomeTab.TextColor3 = Color3.fromRGB(255, 255, 255)

-- Main Content Area
MainContent = Instance.new("Frame")
MainContent.Name = "MainContent"
MainContent.Parent = ContentContainer
MainContent.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MainContent.BackgroundTransparency = 0.965
MainContent.BorderSizePixel = 0
MainContent.Position = UDim2.new(0, 138, 0, 10)
MainContent.Size = UDim2.new(1, -148, 1, -20)
MainContent.ZIndex = 2
do
    local ContentCorner = Instance.new("UICorner")
    ContentCorner.CornerRadius = UDim.new(0, 10)
    ContentCorner.Parent = MainContent
    local ContentStroke = Instance.new("UIStroke")
    ContentStroke.Color = Color3.fromRGB(255, 255, 255)
    ContentStroke.Transparency = 0.88
    ContentStroke.Thickness = 1
    ContentStroke.Parent = MainContent
end

-- Content Padding
do
    local ContentPadding = Instance.new("UIPadding")
    ContentPadding.Parent = MainContent
    ContentPadding.PaddingTop = UDim.new(0, 15)
    ContentPadding.PaddingBottom = UDim.new(0, 15)
    ContentPadding.PaddingLeft = UDim.new(0, 15)
    ContentPadding.PaddingRight = UDim.new(0, 15)
end

-- Scrolling Frame for content
ContentScroll = Instance.new("ScrollingFrame")
ContentScroll.Name = "ContentScroll"
ContentScroll.Parent = MainContent
ContentScroll.BackgroundTransparency = 1
ContentScroll.BorderSizePixel = 0
ContentScroll.Size = UDim2.new(1, 0, 1, 0)
ContentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentScroll.ScrollBarThickness = 4
ContentScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
ContentScroll.ScrollBarImageTransparency = 0.8
ContentScroll.ZIndex = 3

-- Auto-resize canvas
ContentLayout = Instance.new("UIListLayout")
ContentLayout.Parent = ContentScroll
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Padding = UDim.new(0, 10)

ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ContentScroll.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 20)
end)

-- TARGET SECTION (Hidden by default, shown when Player tab clicked)
TargetSection = Instance.new("Frame")
TargetSection.Name = "TargetSection"
TargetSection.Parent = ContentScroll
TargetSection.BackgroundTransparency = 1
TargetSection.Size = UDim2.new(1, 0, 0, 600)
TargetSection.Visible = false
TargetSection.LayoutOrder = 1
do
-- Target Header (local to this block, not used elsewhere)
TargetHeader = Instance.new("TextLabel")
TargetHeader.Name = "TargetHeader"
TargetHeader.Parent = TargetSection
TargetHeader.BackgroundTransparency = 1
TargetHeader.Size = UDim2.new(1, 0, 0, 30)
TargetHeader.Font = Enum.Font.GothamBold
TargetHeader.Text = "Target Player"
TargetHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetHeader.TextSize = 20
TargetHeader.TextXAlignment = Enum.TextXAlignment.Left
TargetHeader.ZIndex = 3
end -- header do

-- Target Info Container
TargetInfoContainer = Instance.new("Frame")
TargetInfoContainer.Name = "TargetInfoContainer"
TargetInfoContainer.Parent = TargetSection
TargetInfoContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TargetInfoContainer.BackgroundTransparency = 0.95
TargetInfoContainer.BorderSizePixel = 0
TargetInfoContainer.Position = UDim2.new(0, 0, 0, 40)
TargetInfoContainer.Size = UDim2.new(1, 0, 0, 120)
TargetInfoContainer.ZIndex = 3
do
    local TargetInfoCorner = Instance.new("UICorner")
    TargetInfoCorner.CornerRadius = UDim.new(0, 10)
    TargetInfoCorner.Parent = TargetInfoContainer
    local TargetInfoStroke = Instance.new("UIStroke")
    TargetInfoStroke.Color = Color3.fromRGB(255, 255, 255)
    TargetInfoStroke.Transparency = 0.9
    TargetInfoStroke.Thickness = 1
    TargetInfoStroke.Parent = TargetInfoContainer
end

-- Target Avatar Image
TargetImage = Instance.new("ImageLabel")
TargetImage.Name = "TargetImage"
TargetImage.Parent = TargetInfoContainer
TargetImage.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
TargetImage.BackgroundTransparency = 0.5
TargetImage.BorderSizePixel = 0
TargetImage.Position = UDim2.new(0, 15, 0, 15)
TargetImage.Size = UDim2.new(0, 90, 0, 90)
TargetImage.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
TargetImage.ZIndex = 4
do
    local TargetImageCorner = Instance.new("UICorner")
    TargetImageCorner.CornerRadius = UDim.new(0, 10)
    TargetImageCorner.Parent = TargetImage
end

-- Target Name Input
TargetNameInput = Instance.new("TextBox")
TargetNameInput.Name = "TargetNameInput"
TargetNameInput.Parent = TargetInfoContainer
TargetNameInput.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TargetNameInput.BackgroundTransparency = 0.9
TargetNameInput.BorderSizePixel = 0
TargetNameInput.Position = UDim2.new(0, 120, 0, 15)
TargetNameInput.Size = UDim2.new(1, -135, 0, 35)
TargetNameInput.Font = Enum.Font.GothamMedium
TargetNameInput.PlaceholderText = "Enter player name..."
TargetNameInput.Text = ""
TargetNameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetNameInput.TextSize = 14
TargetNameInput.ZIndex = 4
TargetNameInput.ClearTextOnFocus = false
do
    local TargetNameCorner = Instance.new("UICorner")
    TargetNameCorner.CornerRadius = UDim.new(0, 8)
    TargetNameCorner.Parent = TargetNameInput
    local TargetNamePadding = Instance.new("UIPadding")
    TargetNamePadding.Parent = TargetNameInput
    TargetNamePadding.PaddingLeft = UDim.new(0, 12)
end

-- Target Info Label
TargetInfoLabel = Instance.new("TextLabel")
TargetInfoLabel.Name = "TargetInfoLabel"
TargetInfoLabel.Parent = TargetInfoContainer
TargetInfoLabel.BackgroundTransparency = 1
TargetInfoLabel.Position = UDim2.new(0, 120, 0, 55)
TargetInfoLabel.Size = UDim2.new(1, -135, 0, 50)
TargetInfoLabel.Font = Enum.Font.Gotham
TargetInfoLabel.Text = "No target selected"
TargetInfoLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
TargetInfoLabel.TextSize = 12
TargetInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
TargetInfoLabel.TextYAlignment = Enum.TextYAlignment.Top
TargetInfoLabel.ZIndex = 4
TargetInfoLabel.TextWrapped = true

-- Function to create action buttons
local function CreateActionButton(parent, name, position, text, layoutOrder)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Parent = parent
    button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    button.BackgroundTransparency = 0.91
    button.BorderSizePixel = 0
    button.Size = UDim2.new(1, 0, 0, 36)
    button.Font = Enum.Font.GothamMedium
    button.Text = text
    button.TextColor3 = Color3.fromRGB(225, 225, 235)
    button.TextSize = 12
    button.ZIndex = 4
    button.AutoButtonColor = false
    button.LayoutOrder = layoutOrder
    button.TextXAlignment = Enum.TextXAlignment.Left
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = button
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.91
    stroke.Thickness = 1
    stroke.Parent = button

    local pad = Instance.new("UIPadding")
    pad.Parent = button
    pad.PaddingLeft = UDim.new(0, 10)
    
    -- Hover effect
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.72}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Transparency = 0.78}):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.91}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Transparency = 0.91}):Play()
    end)
    button.MouseButton1Down:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.55}):Play()
    end)
    button.MouseButton1Up:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.72}):Play()
    end)
    
    return button
end

-- Target Actions Container
TargetActionsContainer = Instance.new("Frame")
TargetActionsContainer.Name = "TargetActionsContainer"
TargetActionsContainer.Parent = TargetSection
TargetActionsContainer.BackgroundTransparency = 1
TargetActionsContainer.Position = UDim2.new(0, 0, 0, 170)
TargetActionsContainer.Size = UDim2.new(1, 0, 0, 400)
TargetActionsContainer.ZIndex = 3

do
    local ActionsLayout = Instance.new("UIListLayout")
    ActionsLayout.Parent = TargetActionsContainer
    ActionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ActionsLayout.Padding = UDim.new(0, 8)
end

-- Create Target Action Buttons
ViewButton = CreateActionButton(TargetActionsContainer, "ViewButton", UDim2.new(0, 0, 0, 0), "👁️ View Target", 1)
TeleportButton = CreateActionButton(TargetActionsContainer, "TeleportButton", UDim2.new(0, 0, 0, 0), "⚡ Teleport to Target", 2)
BringButton = CreateActionButton(TargetActionsContainer, "BringButton", UDim2.new(0, 0, 0, 0), "🔄 Bring Target to You", 3)
FocusButton = CreateActionButton(TargetActionsContainer, "FocusButton", UDim2.new(0, 0, 0, 0), "🎯 Focus Target (Loop TP)", 4)
HeadSitButton = CreateActionButton(TargetActionsContainer, "HeadSitButton", UDim2.new(0, 0, 0, 0), "🪑 Sit on Head", 5)
BackpackButton = CreateActionButton(TargetActionsContainer, "BackpackButton", UDim2.new(0, 0, 0, 0), "🎒 Backpack Mode", 6)
ClearTargetButton = CreateActionButton(TargetActionsContainer, "ClearTargetButton", UDim2.new(0, 0, 0, 0), "❌ Clear Target", 7)
CharCloneButton = CreateActionButton(TargetActionsContainer, "CharCloneButton", UDim2.new(0, 0, 0, 0), "🦸 Clone Char: OFF", 8)

-- HOME SECTION (Default visible)
HomeSection = Instance.new("Frame")
HomeSection.Name = "HomeSection"
HomeSection.Parent = ContentScroll
HomeSection.BackgroundTransparency = 1
HomeSection.Size = UDim2.new(1, 0, 0, 600)
HomeSection.Visible = true
HomeSection.LayoutOrder = 0

-- Build Home section UI in a do block to avoid polluting top-level local scope
-- local UpdatesScroll, UpdatesLayout
do
WelcomeText = Instance.new("TextLabel")
WelcomeText.Name = "WelcomeText"
WelcomeText.Parent = HomeSection
WelcomeText.BackgroundTransparency = 1
WelcomeText.Size = UDim2.new(1, 0, 0, 40)
WelcomeText.Font = Enum.Font.GothamBold
WelcomeText.Text = "Welcome to Onyx"
WelcomeText.TextColor3 = Color3.fromRGB(255, 255, 255)
WelcomeText.TextSize = 24
WelcomeText.TextXAlignment = Enum.TextXAlignment.Left
WelcomeText.ZIndex = 3

WelcomeSubtext = Instance.new("TextLabel")
WelcomeSubtext.Name = "WelcomeSubtext"
WelcomeSubtext.Parent = HomeSection
WelcomeSubtext.BackgroundTransparency = 1
WelcomeSubtext.Position = UDim2.new(0, 0, 0, 45)
WelcomeSubtext.Size = UDim2.new(1, 0, 0, 20)
WelcomeSubtext.Font = Enum.Font.Gotham
WelcomeSubtext.Text = "Version 2.5 | By Biscuit"
WelcomeSubtext.TextColor3 = Color3.fromRGB(180, 180, 180)
WelcomeSubtext.TextSize = 13
WelcomeSubtext.TextXAlignment = Enum.TextXAlignment.Left
WelcomeSubtext.ZIndex = 3

-- Updates Container
UpdatesContainer = Instance.new("Frame")
UpdatesContainer.Name = "UpdatesContainer"
UpdatesContainer.Parent = HomeSection
UpdatesContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
UpdatesContainer.BackgroundTransparency = 0.95
UpdatesContainer.BorderSizePixel = 0
UpdatesContainer.Position = UDim2.new(0, 0, 0, 75)
UpdatesContainer.Size = UDim2.new(1, 0, 0, 500)
UpdatesContainer.ZIndex = 3

UpdatesCorner = Instance.new("UICorner")
UpdatesCorner.CornerRadius = UDim.new(0, 10)
UpdatesCorner.Parent = UpdatesContainer

UpdatesStroke = Instance.new("UIStroke")
UpdatesStroke.Color = Color3.fromRGB(255, 255, 255)
UpdatesStroke.Transparency = 0.9
UpdatesStroke.Thickness = 1
UpdatesStroke.Parent = UpdatesContainer

-- Updates Title
UpdatesTitle = Instance.new("TextLabel")
UpdatesTitle.Name = "UpdatesTitle"
UpdatesTitle.Parent = UpdatesContainer
UpdatesTitle.BackgroundTransparency = 1
UpdatesTitle.Position = UDim2.new(0, 15, 0, 10)
UpdatesTitle.Size = UDim2.new(1, -30, 0, 25)
UpdatesTitle.Font = Enum.Font.GothamBold
UpdatesTitle.Text = "📋 Recent Updates"
UpdatesTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
UpdatesTitle.TextSize = 16
UpdatesTitle.TextXAlignment = Enum.TextXAlignment.Left
UpdatesTitle.ZIndex = 4

-- Updates Scroll Frame
UpdatesScroll = Instance.new("ScrollingFrame")
UpdatesScroll.Name = "UpdatesScroll"
UpdatesScroll.Parent = UpdatesContainer
UpdatesScroll.BackgroundTransparency = 1
UpdatesScroll.BorderSizePixel = 0
UpdatesScroll.Position = UDim2.new(0, 15, 0, 45)
UpdatesScroll.Size = UDim2.new(1, -30, 1, -55)
UpdatesScroll.ScrollBarThickness = 0
UpdatesScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
UpdatesScroll.ScrollBarImageTransparency = 0.8
UpdatesScroll.ZIndex = 4
UpdatesScroll.CanvasSize = UDim2.new(0, 0, 0, 0)

UpdatesLayout = Instance.new("UIListLayout")
UpdatesLayout.Parent = UpdatesScroll
UpdatesLayout.SortOrder = Enum.SortOrder.LayoutOrder
UpdatesLayout.Padding = UDim.new(0, 10)

UpdatesLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    UpdatesScroll.CanvasSize = UDim2.new(0, 0, 0, UpdatesLayout.AbsoluteContentSize.Y + 10)
end)

-- Function to create update entry
local function CreateUpdateEntry(version, title, features, order)
    local entry = Instance.new("Frame")
    entry.Name = "UpdateEntry"
    entry.Parent = UpdatesScroll
    entry.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    entry.BackgroundTransparency = 0.97
    entry.BorderSizePixel = 0
    entry.Size = UDim2.new(1, -10, 0, 120)
    entry.ZIndex = 5
    entry.LayoutOrder = order
    
    local entryCorner = Instance.new("UICorner")
    entryCorner.CornerRadius = UDim.new(0, 8)
    entryCorner.Parent = entry
    
    local versionLabel = Instance.new("TextLabel")
    versionLabel.Parent = entry
    versionLabel.BackgroundTransparency = 1
    versionLabel.Position = UDim2.new(0, 10, 0, 5)
    versionLabel.Size = UDim2.new(1, -20, 0, 20)
    versionLabel.Font = Enum.Font.GothamBold
    versionLabel.Text = version .. " - " .. title
    versionLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    versionLabel.TextSize = 13
    versionLabel.TextXAlignment = Enum.TextXAlignment.Left
    versionLabel.ZIndex = 6
    
    local featuresLabel = Instance.new("TextLabel")
    featuresLabel.Parent = entry
    featuresLabel.BackgroundTransparency = 1
    featuresLabel.Position = UDim2.new(0, 10, 0, 30)
    featuresLabel.Size = UDim2.new(1, -20, 1, -35)
    featuresLabel.Font = Enum.Font.Gotham
    featuresLabel.Text = features
    featuresLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    featuresLabel.TextSize = 11
    featuresLabel.TextXAlignment = Enum.TextXAlignment.Left
    featuresLabel.TextYAlignment = Enum.TextYAlignment.Top
    featuresLabel.TextWrapped = true
    featuresLabel.ZIndex = 6
    
    -- Auto-resize entry based on text
    local textHeight = featuresLabel.TextBounds.Y
    entry.Size = UDim2.new(1, -10, 0, math.max(120, textHeight + 45))
end

-- Add update entries (most recent first)
CreateUpdateEntry("v2.5", "Chat Commands + QoL",
    "⌨️ Full chat command system (.esp, .aimlock, .tp, .emotes, etc.)\n" ..
    "📋 Command List panel (button in Misc tab)\n" ..
    "🔑 Configurable minimize keybind (Misc tab)\n" ..
    "🏷️ Nametag system overhaul — only shows users with script active\n" ..
    "⚡ Nametag detection now near-instant via active user polling\n" ..
    "❌ Removed X close button — minimize only", 1)

CreateUpdateEntry("v2.4", "Nametag System",
    "🏷️ Live nametag system — shows Onyx users in your server\n" ..
    "💓 Heartbeat registration every 10 seconds\n" ..
    "🎨 Custom nametag configs (name, color, icon, glow, glitch)\n" ..
    "✨ Glitch animation effect on tags\n" ..
    "📏 LOD system — tags shrink at distance\n" ..
    "🔄 Auto-removes tags when players leave or stop script", 2)

CreateUpdateEntry("v2.3", "Face Bang Update",
    "💀 Face Bang — attach to target's face and oscillate\n" ..
    "🏃 Speed slider (1–40)\n" ..
    "📏 Distance slider\n" ..
    "🔄 Directional tracking — follows head rotation\n" ..
    "⌨️ Z key to start/stop", 3)

CreateUpdateEntry("v2.2", "Key System",
    "🔑 48-hour temporary keys\n" ..
    "💾 Key saved per user (auto-login on next execute)\n" ..
    "✅ Whitelist system — no key needed if whitelisted\n" ..
    "🚫 HWID blacklist support\n" ..
    "📊 Execution logging", 4)

CreateUpdateEntry("v2.1", "Combat + Misc",
    "👁️ ESP — boxes, names, distance, health bars\n" ..
    "🎯 Aimlock with FOV circle\n" ..
    "⏮️ Time Reverse (Hold C) — 10 second buffer\n" ..
    "🤸 Trip (Press T)\n" ..
    "🎤 Anti VC Ban protection\n" ..
    "📍 Click Teleport (Press F)\n" ..
    "🟦 Infinite Baseplate\n" ..
    "🌟 Shaders", 5)

CreateUpdateEntry("v2.0", "Major Overhaul",
    "🎭 358+ Animations with search\n" ..
    "👤 Target Player system\n" ..
    "⚡ Teleport to / Bring / Focus target\n" ..
    "📹 Spectate mode\n" ..
    "🪑 HeadSit & Backpack modes\n" ..
    "💾 Animation persistence across respawns", 6)
end -- end Home section do block

-- ANIMATION SECTION (NEW)
AnimationSection = Instance.new("Frame")
AnimationSection.Name = "AnimationSection"
AnimationSection.Parent = ContentScroll
AnimationSection.BackgroundTransparency = 1
AnimationSection.Size = UDim2.new(1, 0, 0, 536)
AnimationSection.Visible = false
AnimationSection.LayoutOrder = 2
do
    local AnimationHeader = Instance.new("TextLabel")
    AnimationHeader.Name = "AnimationHeader"
    AnimationHeader.Parent = AnimationSection
    AnimationHeader.BackgroundTransparency = 1
    AnimationHeader.Size = UDim2.new(1, 0, 0, 30)
    AnimationHeader.Font = Enum.Font.GothamBold
    AnimationHeader.Text = "🎭 Animation Changer"
    AnimationHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
    AnimationHeader.TextSize = 20
    AnimationHeader.TextXAlignment = Enum.TextXAlignment.Left
    AnimationHeader.ZIndex = 3
end

-- COMBAT SECTION (NEW)
CombatSection = Instance.new("Frame")
CombatSection.Name = "CombatSection"
CombatSection.Parent = ContentScroll
CombatSection.BackgroundTransparency = 1
CombatSection.Size = UDim2.new(1, 0, 0, 500)
CombatSection.Visible = false
CombatSection.LayoutOrder = 3
do
    local CombatHeader = Instance.new("TextLabel")
    CombatHeader.Name = "CombatHeader"
    CombatHeader.Parent = CombatSection
    CombatHeader.BackgroundTransparency = 1
    CombatHeader.Size = UDim2.new(1, 0, 0, 30)
    CombatHeader.Font = Enum.Font.GothamBold
    CombatHeader.Text = "⚔️ Combat Features"
    CombatHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
    CombatHeader.TextSize = 20
    CombatHeader.TextXAlignment = Enum.TextXAlignment.Left
    CombatHeader.ZIndex = 3
end

-- Combat Actions Container
CombatActionsContainer = Instance.new("Frame")
CombatActionsContainer.Name = "CombatActionsContainer"
CombatActionsContainer.Parent = CombatSection
CombatActionsContainer.BackgroundTransparency = 1
CombatActionsContainer.Position = UDim2.new(0, 0, 0, 40)
CombatActionsContainer.Size = UDim2.new(1, 0, 0, 450)
CombatActionsContainer.ZIndex = 3
do
    local CombatLayout = Instance.new("UIListLayout")
    CombatLayout.Parent = CombatActionsContainer
    CombatLayout.SortOrder = Enum.SortOrder.LayoutOrder
    CombatLayout.Padding = UDim.new(0, 8)
end

-- ESP Button
ESPButton = CreateActionButton(CombatActionsContainer, "ESPButton", UDim2.new(0, 0, 0, 0), "👁️ ESP: OFF", 1)

-- Aimlock Button
AimlockButton = CreateActionButton(CombatActionsContainer, "AimlockButton", UDim2.new(0, 0, 0, 0), "🎯 Aimlock: OFF", 2)

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  GUI — MISC TAB BUTTONS                                      ║
-- ╚══════════════════════════════════════════════════════════════╝
-- MISC SECTION
MiscSection = Instance.new("Frame")
MiscSection.Name = "MiscSection"
MiscSection.Parent = ContentScroll
MiscSection.BackgroundTransparency = 1
MiscSection.Size = UDim2.new(1, 0, 0, 400)
MiscSection.Visible = false
MiscSection.LayoutOrder = 4
do
    local MiscHeader = Instance.new("TextLabel")
    MiscHeader.Name = "MiscHeader"
    MiscHeader.Parent = MiscSection
    MiscHeader.BackgroundTransparency = 1
    MiscHeader.Size = UDim2.new(1, 0, 0, 30)
    MiscHeader.Font = Enum.Font.GothamBold
    MiscHeader.Text = "Miscellaneous"
    MiscHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
    MiscHeader.TextSize = 20
    MiscHeader.TextXAlignment = Enum.TextXAlignment.Left
    MiscHeader.ZIndex = 3
end

-- Misc Actions Container
MiscActionsContainer = Instance.new("Frame")
MiscActionsContainer.Name = "MiscActionsContainer"
MiscActionsContainer.Parent = MiscSection
MiscActionsContainer.BackgroundTransparency = 1
MiscActionsContainer.Position = UDim2.new(0, 0, 0, 40)
MiscActionsContainer.Size = UDim2.new(1, 0, 0, 450)
MiscActionsContainer.ZIndex = 3
do
    local MiscLayout = Instance.new("UIListLayout")
    MiscLayout.Parent = MiscActionsContainer
    MiscLayout.SortOrder = Enum.SortOrder.LayoutOrder
    MiscLayout.Padding = UDim.new(0, 8)
end

-- Anti VC Ban Button
AntiVCButton = CreateActionButton(MiscActionsContainer, "AntiVCButton", UDim2.new(0, 0, 0, 0), "🎤 Open Anti VC Ban", 1)

-- Face Bang Button
FaceBangButton = CreateActionButton(MiscActionsContainer, "FaceBangButton", UDim2.new(0, 0, 0, 0), "💀 Open Face Bang (Z)", 2)

-- Click Teleport Button
ClickTeleportButton = CreateActionButton(MiscActionsContainer, "ClickTeleportButton", UDim2.new(0, 0, 0, 0), "📍 Click Teleport (F): OFF", 3)

-- Infinite Baseplate Button
InfiniteBaseplateButton = CreateActionButton(MiscActionsContainer, "InfiniteBaseplateButton", UDim2.new(0, 0, 0, 0), "🟦 Infinite Baseplate: OFF", 4)

-- Time Reverse Button (moved from Combat)
TimeReverseButton = CreateActionButton(MiscActionsContainer, "TimeReverseButton", UDim2.new(0, 0, 0, 0), "⏮️ Time Reverse (C): OFF", 5)

-- Trip Button (NEW)
TripButton = CreateActionButton(MiscActionsContainer, "TripButton", UDim2.new(0, 0, 0, 0), "🤸 Trip (T): OFF", 6)

SpeedButton = CreateActionButton(MiscActionsContainer, "SpeedButton", UDim2.new(0, 0, 0, 0), "🏃 Player Speed", 7)
SupermanFlyButton = CreateActionButton(MiscActionsContainer, "SupermanFlyButton", UDim2.new(0, 0, 0, 0), "🦸 Superman Fly (G): OFF", 8)

UnloadScriptButton = CreateActionButton(MiscActionsContainer, "UnloadScriptButton", UDim2.new(0, 0, 0, 0), "❌ Unload Script", 9)

CommandsButton = CreateActionButton(MiscActionsContainer, "CommandsButton", UDim2.new(0, 0, 0, 0), "⌨️ Command List", 10)

-- Minimize Keybind Changer
minimizeKey = Enum.KeyCode.B -- default
minimizeKeyListening = false

MinimizeKeyRow = Instance.new("Frame")
MinimizeKeyRow.Name = "MinimizeKeyRow"
MinimizeKeyRow.Parent = MiscActionsContainer
MinimizeKeyRow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MinimizeKeyRow.BackgroundTransparency = 0.92
MinimizeKeyRow.BorderSizePixel = 0
MinimizeKeyRow.Size = UDim2.new(1, 0, 0, 36)
MinimizeKeyRow.LayoutOrder = 8
MinimizeKeyRow.ZIndex = 3
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = MinimizeKeyRow end

MinimizeKeyLabel = Instance.new("TextLabel")
MinimizeKeyLabel.Parent = MinimizeKeyRow
MinimizeKeyLabel.BackgroundTransparency = 1
MinimizeKeyLabel.Position = UDim2.new(0, 10, 0, 0)
MinimizeKeyLabel.Size = UDim2.new(0.6, 0, 1, 0)
MinimizeKeyLabel.Font = Enum.Font.GothamMedium
MinimizeKeyLabel.Text = "⌨️ Minimize Key"
MinimizeKeyLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
MinimizeKeyLabel.TextSize = 13
MinimizeKeyLabel.TextXAlignment = Enum.TextXAlignment.Left
MinimizeKeyLabel.ZIndex = 4

MinimizeKeyBtn = Instance.new("TextButton")
MinimizeKeyBtn.Parent = MinimizeKeyRow
MinimizeKeyBtn.AnchorPoint = Vector2.new(1, 0.5)
MinimizeKeyBtn.Position = UDim2.new(1, -10, 0.5, 0)
MinimizeKeyBtn.Size = UDim2.new(0, 80, 0, 24)
MinimizeKeyBtn.BackgroundColor3 = Color3.fromRGB(140, 130, 255)
MinimizeKeyBtn.BackgroundTransparency = 0.5
MinimizeKeyBtn.BorderSizePixel = 0
MinimizeKeyBtn.Font = Enum.Font.GothamBold
MinimizeKeyBtn.Text = "[B]"
MinimizeKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeKeyBtn.TextSize = 12
MinimizeKeyBtn.ZIndex = 4
MinimizeKeyBtn.AutoButtonColor = false
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = MinimizeKeyBtn end

MinimizeKeyBtn.MouseButton1Click:Connect(function()
    if minimizeKeyListening then return end
    minimizeKeyListening = true
    MinimizeKeyBtn.Text = "..."
    MinimizeKeyBtn.BackgroundTransparency = 0.2
end)

-- VISUAL SECTION
VisualSection = Instance.new("Frame")
VisualSection.Name = "VisualSection"
VisualSection.Parent = ContentScroll
VisualSection.BackgroundTransparency = 1
VisualSection.Size = UDim2.new(1, 0, 0, 400)
VisualSection.Visible = false
VisualSection.LayoutOrder = 5
do
    local VisualHeader = Instance.new("TextLabel")
    VisualHeader.Name = "VisualHeader"
    VisualHeader.Parent = VisualSection
    VisualHeader.BackgroundTransparency = 1
    VisualHeader.Size = UDim2.new(1, 0, 0, 30)
    VisualHeader.Font = Enum.Font.GothamBold
    VisualHeader.Text = "👁️ Visual Features"
    VisualHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
    VisualHeader.TextSize = 20
    VisualHeader.TextXAlignment = Enum.TextXAlignment.Left
    VisualHeader.ZIndex = 3
end

-- Visual Actions Container
VisualActionsContainer = Instance.new("Frame")
VisualActionsContainer.Name = "VisualActionsContainer"
VisualActionsContainer.Parent = VisualSection
VisualActionsContainer.BackgroundTransparency = 1
VisualActionsContainer.Position = UDim2.new(0, 0, 0, 40)
VisualActionsContainer.Size = UDim2.new(1, 0, 0, 450)
VisualActionsContainer.ZIndex = 3
do
    local VisualLayout = Instance.new("UIListLayout")
    VisualLayout.Parent = VisualActionsContainer
    VisualLayout.SortOrder = Enum.SortOrder.LayoutOrder
    VisualLayout.Padding = UDim.new(0, 8)
end

-- Shaders Button (with loadstring)
ShadersButton = CreateActionButton(VisualActionsContainer, "ShadersButton", UDim2.new(0, 0, 0, 0), "🌟 Shaders", 1)

-- Emotes Button (in Animation tab, above search)
EmotesButton = Instance.new("TextButton")
EmotesButton.Name = "EmotesButton"
EmotesButton.Parent = AnimationSection
EmotesButton.BackgroundColor3 = Color3.fromRGB(9, 9, 18)
EmotesButton.BackgroundTransparency = 0.08
EmotesButton.BorderSizePixel = 0
EmotesButton.Position = UDim2.new(0, 0, 0, 40)
EmotesButton.Size = UDim2.new(0.5, -4, 0, 36)
EmotesButton.Font = Enum.Font.GothamBold
EmotesButton.Text = "🎭  Emote Menu"
EmotesButton.TextColor3 = Color3.fromRGB(200, 200, 255)
EmotesButton.TextSize = 13
EmotesButton.AutoButtonColor = false
EmotesButton.ZIndex = 4
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = EmotesButton
    local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255,255,255); s.Transparency = 0.82; s.Thickness = 1; s.Parent = EmotesButton
end
EmotesButton.MouseEnter:Connect(function()
    TweenService:Create(EmotesButton, TweenInfo.new(0.15), {BackgroundTransparency = 0.6, TextColor3 = Color3.fromRGB(255,255,255)}):Play()
end)
EmotesButton.MouseLeave:Connect(function()
    TweenService:Create(EmotesButton, TweenInfo.new(0.15), {BackgroundTransparency = 0.08, TextColor3 = Color3.fromRGB(200,200,255)}):Play()
end)

-- Stop Animations Button
RestoreAnimsButton = Instance.new("TextButton")
RestoreAnimsButton.Name = "RestoreAnimsButton"
RestoreAnimsButton.Parent = AnimationSection
RestoreAnimsButton.BackgroundColor3 = Color3.fromRGB(9, 9, 18)
RestoreAnimsButton.BackgroundTransparency = 0.08
RestoreAnimsButton.BorderSizePixel = 0
RestoreAnimsButton.Position = UDim2.new(0.5, 4, 0, 40)
RestoreAnimsButton.Size = UDim2.new(0.5, -4, 0, 36)
RestoreAnimsButton.Font = Enum.Font.GothamBold
RestoreAnimsButton.Text = "🛑 Stop Anims"
RestoreAnimsButton.TextColor3 = Color3.fromRGB(255, 100, 100)
RestoreAnimsButton.TextSize = 13
RestoreAnimsButton.AutoButtonColor = false
RestoreAnimsButton.ZIndex = 4
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = RestoreAnimsButton
    local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255,100,100); s.Transparency = 0.82; s.Thickness = 1; s.Parent = RestoreAnimsButton
end
RestoreAnimsButton.MouseEnter:Connect(function()
    TweenService:Create(RestoreAnimsButton, TweenInfo.new(0.15), {BackgroundTransparency = 0.6, TextColor3 = Color3.fromRGB(255,150,150)}):Play()
end)
RestoreAnimsButton.MouseLeave:Connect(function()
    TweenService:Create(RestoreAnimsButton, TweenInfo.new(0.15), {BackgroundTransparency = 0.08, TextColor3 = Color3.fromRGB(255,100,100)}):Play()
end)

-- Reanimation Button
ReanimationButton = Instance.new("TextButton")
ReanimationButton.Name = "ReanimationButton"
ReanimationButton.Parent = AnimationSection
ReanimationButton.BackgroundColor3 = Color3.fromRGB(9, 9, 18)
ReanimationButton.BackgroundTransparency = 0.08
ReanimationButton.BorderSizePixel = 0
ReanimationButton.Position = UDim2.new(0, 0, 0, 84)
ReanimationButton.Size = UDim2.new(1, 0, 0, 36)
ReanimationButton.Font = Enum.Font.GothamBold
ReanimationButton.Text = "Reanimation"
ReanimationButton.TextColor3 = Color3.fromRGB(180, 140, 255)
ReanimationButton.TextSize = 13
ReanimationButton.AutoButtonColor = false
ReanimationButton.ZIndex = 4
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = ReanimationButton
    local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(180,140,255); s.Transparency = 0.82; s.Thickness = 1; s.Parent = ReanimationButton
end
ReanimationButton.MouseEnter:Connect(function()
    TweenService:Create(ReanimationButton, TweenInfo.new(0.15), {BackgroundTransparency = 0.6, TextColor3 = Color3.fromRGB(220,190,255)}):Play()
end)
ReanimationButton.MouseLeave:Connect(function()
    TweenService:Create(ReanimationButton, TweenInfo.new(0.15), {BackgroundTransparency = 0.08, TextColor3 = Color3.fromRGB(180,140,255)}):Play()
end)
ReanimationButton.MouseButton1Click:Connect(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EORScopeZ/OnyxV2/refs/heads/main/Reanimation.lua"))()
end)

RestoreAnimsButton.MouseButton1Click:Connect(function()
    local Char = plr.Character
    if not Char then return end
    
    -- Clear saved custom anims to prevent auto-reloading them on respawn
    pcall(function() delfile("OnyxLastAnims.json") end)
    table.clear(lastAnimations)
    
    -- Stop ALL playing animation tracks (Humanoid + Animator)
    local Hum = Char:FindFirstChildOfClass("Humanoid")
    if Hum then
        for _, track in ipairs(Hum:GetPlayingAnimationTracks()) do
            track:Stop(0)
        end
        local animator = Hum:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                track:Stop(0)
            end
        end
    end
    
    local Animate = Char:FindFirstChild("Animate")
    if Animate then
        -- Re-enable the Animate script (emotes/custom anims may have disabled it)
        pcall(function() Animate.Disabled = false end)

        pcall(function()
            local desc = game:GetService("Players"):GetHumanoidDescriptionFromUserId(plr.UserId)
            if desc then
                -- Inline replace: destroy locked Animation child and create a fresh one.
                -- Works even when AnimationId is property-locked by the engine.
                local function restoreSlot(parent, childName, id)
                    if not parent then return end
                    local full = "http://www.roblox.com/asset/?id=" .. tostring(id)
                    local existing = parent:FindFirstChild(childName)
                    if existing then
                        local ok = pcall(function() existing.AnimationId = full end)
                        if not ok then pcall(function() existing:Destroy() end) end
                    end
                    if not parent:FindFirstChild(childName) then
                        local a = Instance.new("Animation")
                        a.Name = childName; a.AnimationId = full; a.Parent = parent
                    end
                end
                if Animate:FindFirstChild("idle") then
                    restoreSlot(Animate.idle, "Animation1", desc.IdleAnimation)
                    restoreSlot(Animate.idle, "Animation2", desc.IdleAnimation)
                end
                if Animate:FindFirstChild("walk")  then restoreSlot(Animate.walk,  "WalkAnim",  desc.WalkAnimation)  end
                if Animate:FindFirstChild("run")   then restoreSlot(Animate.run,   "RunAnim",   desc.RunAnimation)   end
                if Animate:FindFirstChild("jump")  then restoreSlot(Animate.jump,  "JumpAnim",  desc.JumpAnimation)  end
                if Animate:FindFirstChild("fall")  then restoreSlot(Animate.fall,  "FallAnim",  desc.FallAnimation)  end
                if Animate:FindFirstChild("swim")  then restoreSlot(Animate.swim,  "Swim",      desc.SwimAnimation)  end
                if Animate:FindFirstChild("climb") then restoreSlot(Animate.climb, "ClimbAnim", desc.ClimbAnimation) end
            end
        end)
    end
    
    -- Kick the humanoid state to restart default animations
    if Hum then
        pcall(function() Hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
    end
    
    SendNotify("Animations", "Restored to original Roblox animations", 3)
end)

-- Animation Changer UI Components (for Animation Tab)
AnimSearchBar = Instance.new("TextBox")
AnimSearchBar.Name = "AnimSearchBar"
AnimSearchBar.Parent = AnimationSection
AnimSearchBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
AnimSearchBar.BackgroundTransparency = 0.7
AnimSearchBar.BorderSizePixel = 0
AnimSearchBar.Position = UDim2.new(0, 0, 0, 120)
AnimSearchBar.Size = UDim2.new(1, 0, 0, 35)
AnimSearchBar.Font = Enum.Font.Gotham
AnimSearchBar.PlaceholderText = "Search animations..."
AnimSearchBar.Text = ""
AnimSearchBar.TextColor3 = Color3.fromRGB(200, 200, 200)
AnimSearchBar.TextSize = 13
AnimSearchBar.ZIndex = 4
AnimSearchBar.ClearTextOnFocus = false
do
    local AnimSearchCorner = Instance.new("UICorner")
    AnimSearchCorner.CornerRadius = UDim.new(0, 8)
    AnimSearchCorner.Parent = AnimSearchBar
    local AnimSearchPadding = Instance.new("UIPadding")
    AnimSearchPadding.Parent = AnimSearchBar
    AnimSearchPadding.PaddingLeft = UDim.new(0, 10)
end

-- Animation Scroll Frame
AnimScrollFrame = Instance.new("ScrollingFrame")
AnimScrollFrame.Name = "AnimScrollFrame"
AnimScrollFrame.Parent = AnimationSection
AnimScrollFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
AnimScrollFrame.BackgroundTransparency = 0.9
AnimScrollFrame.BorderSizePixel = 0
AnimScrollFrame.Position = UDim2.new(0, 0, 0, 165)
AnimScrollFrame.Size = UDim2.new(1, 0, 1, -189)
AnimScrollFrame.ScrollBarThickness = 0
AnimScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
AnimScrollFrame.ScrollBarImageTransparency = 0.8
AnimScrollFrame.ZIndex = 4
AnimScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
do
    local AnimScrollCorner = Instance.new("UICorner")
    AnimScrollCorner.CornerRadius = UDim.new(0, 8)
    AnimScrollCorner.Parent = AnimScrollFrame
end

AnimScrollLayout = Instance.new("UIListLayout")
AnimScrollLayout.Parent = AnimScrollFrame
AnimScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
AnimScrollLayout.Padding = UDim.new(0, 5)
do
    local AnimScrollPadding = Instance.new("UIPadding")
    AnimScrollPadding.Parent = AnimScrollFrame
    AnimScrollPadding.PaddingTop = UDim.new(0, 5)
    AnimScrollPadding.PaddingBottom = UDim.new(0, 5)
    AnimScrollPadding.PaddingLeft = UDim.new(0, 5)
    AnimScrollPadding.PaddingRight = UDim.new(0, 5)
end

-- Animation Info Label
AnimInfoLabel = Instance.new("TextLabel")
AnimInfoLabel.Name = "AnimInfoLabel"
AnimInfoLabel.Parent = AnimationSection
AnimInfoLabel.BackgroundTransparency = 1
AnimInfoLabel.Position = UDim2.new(0, 0, 1, -55)
AnimInfoLabel.Size = UDim2.new(1, 0, 0, 50)
AnimInfoLabel.Font = Enum.Font.Gotham
AnimInfoLabel.Text = "Select an animation from the list above\nAnimations persist on respawn"
AnimInfoLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
AnimInfoLabel.TextSize = 11
AnimInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
AnimInfoLabel.TextYAlignment = Enum.TextYAlignment.Top
AnimInfoLabel.ZIndex = 4
AnimInfoLabel.TextWrapped = true

-- Update canvas size when animations are added
AnimScrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    AnimScrollFrame.CanvasSize = UDim2.new(0, 0, 0, AnimScrollLayout.AbsoluteContentSize.Y + 10)
end)

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  GUI — FACE BANG WINDOW                                      ║
-- ╚══════════════════════════════════════════════════════════════╝
-- =====================================================
-- FACE BANG WINDOW
-- =====================================================

-- All GUI-only locals are scoped inside this do block to avoid
-- hitting Lua 5.1's 200 local register limit at chunk level.
-- Only variables needed by the logic below are declared outside.
-- local FaceBangWindow, FBTitleBar, FBStatusLabel, FBToggleBtn
-- local getFBSpeed, getFBDistance

do
    FaceBangWindow = Instance.new("Frame")
    FaceBangWindow.Name = "FaceBangWindow"
    FaceBangWindow.Parent = OnyxUI
    FaceBangWindow.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    FaceBangWindow.BackgroundTransparency = 0.3
    FaceBangWindow.BorderSizePixel = 0
    FaceBangWindow.Position = UDim2.new(0.5, -140, 0.5, -130)
    FaceBangWindow.Size = UDim2.new(0, 280, 0, 260)
    FaceBangWindow.Visible = false
    FaceBangWindow.Active = true
    FaceBangWindow.ZIndex = 20
    FaceBangWindow.ClipsDescendants = true
    do
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 16); c.Parent = FaceBangWindow
        local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255,255,255)
        s.Transparency = 0.8; s.Thickness = 1; s.Parent = FaceBangWindow
    end

    FBTitleBar = Instance.new("Frame")
    FBTitleBar.Name = "TitleBar"
    FBTitleBar.Parent = FaceBangWindow
    FBTitleBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    FBTitleBar.BackgroundTransparency = 0.95
    FBTitleBar.BorderSizePixel = 0
    FBTitleBar.Size = UDim2.new(1, 0, 0, 40)
    FBTitleBar.ZIndex = 21
    do
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 16); c.Parent = FBTitleBar
        local t = Instance.new("TextLabel"); t.Parent = FBTitleBar
        t.BackgroundTransparency = 1; t.Position = UDim2.new(0, 15, 0, 0)
        t.Size = UDim2.new(1, -80, 1, 0); t.Font = Enum.Font.GothamBold
        t.Text = "💀 Face Bang"; t.TextColor3 = Color3.fromRGB(255, 255, 255)
        t.TextSize = 16; t.TextXAlignment = Enum.TextXAlignment.Left; t.ZIndex = 22
    end

    -- Close button
    do
        local FBCloseBtn = Instance.new("TextButton")
        FBCloseBtn.Name = "CloseBtn"; FBCloseBtn.Parent = FBTitleBar
        FBCloseBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80); FBCloseBtn.BackgroundTransparency = 0.3
        FBCloseBtn.BorderSizePixel = 0; FBCloseBtn.AnchorPoint = Vector2.new(1, 0.5)
        FBCloseBtn.Position = UDim2.new(1, -10, 0.5, 0); FBCloseBtn.Size = UDim2.new(0, 25, 0, 25)
        FBCloseBtn.Font = Enum.Font.GothamBold; FBCloseBtn.Text = "×"
        FBCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255); FBCloseBtn.TextSize = 18
        FBCloseBtn.ZIndex = 22; FBCloseBtn.AutoButtonColor = false
        do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = FBCloseBtn end
        FBCloseBtn.MouseButton1Click:Connect(function() FaceBangWindow.Visible = false end)

        -- Minimize button
        local FBMinimizeBtn = Instance.new("TextButton")
        FBMinimizeBtn.Name = "MinimizeBtn"; FBMinimizeBtn.Parent = FBTitleBar
        FBMinimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255); FBMinimizeBtn.BackgroundTransparency = 0.9
        FBMinimizeBtn.BorderSizePixel = 0; FBMinimizeBtn.AnchorPoint = Vector2.new(1, 0.5)
        FBMinimizeBtn.Position = UDim2.new(1, -45, 0.5, 0); FBMinimizeBtn.Size = UDim2.new(0, 25, 0, 25)
        FBMinimizeBtn.Font = Enum.Font.GothamBold; FBMinimizeBtn.Text = "−"
        FBMinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255); FBMinimizeBtn.TextSize = 18
        FBMinimizeBtn.ZIndex = 22; FBMinimizeBtn.AutoButtonColor = false
        do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = FBMinimizeBtn end

        local fbMinimized = false
        FBMinimizeBtn.MouseButton1Click:Connect(function()
            fbMinimized = not fbMinimized
            local ti = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            TweenService:Create(FaceBangWindow, ti, {
                Size = fbMinimized and UDim2.new(0, 280, 0, 40) or UDim2.new(0, 280, 0, 260)
            }):Play()
            FBMinimizeBtn.Text = fbMinimized and "+" or "−"
        end)
    end

    FBStatusLabel = Instance.new("TextLabel")
    FBStatusLabel.Parent = FaceBangWindow
    FBStatusLabel.BackgroundTransparency = 1
    FBStatusLabel.Position = UDim2.new(0, 15, 0, 48)
    FBStatusLabel.Size = UDim2.new(1, -30, 0, 18)
    FBStatusLabel.Font = Enum.Font.Gotham
    FBStatusLabel.Text = "Status: Idle | Press Z to attach to nearest"
    FBStatusLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
    FBStatusLabel.TextSize = 11
    FBStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    FBStatusLabel.ZIndex = 21
    FBStatusLabel.TextTruncate = Enum.TextTruncate.AtEnd

    local function BuildSlider(yPos, labelText, minVal, maxVal, defaultVal)
        local val = defaultVal

        local row = Instance.new("Frame")
        row.Parent = FaceBangWindow
        row.BackgroundTransparency = 1
        row.Position = UDim2.new(0, 15, 0, yPos)
        row.Size = UDim2.new(1, -30, 0, 52)
        row.ZIndex = 21

        local lbl = Instance.new("TextLabel")
        lbl.Parent = row; lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(0.6, 0, 0, 18); lbl.Font = Enum.Font.GothamMedium
        lbl.Text = labelText; lbl.TextColor3 = Color3.fromRGB(220, 220, 240)
        lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 22

        local valLbl = Instance.new("TextLabel")
        valLbl.Parent = row; valLbl.BackgroundTransparency = 1
        valLbl.AnchorPoint = Vector2.new(1, 0); valLbl.Position = UDim2.new(1, 0, 0, 0)
        valLbl.Size = UDim2.new(0.38, 0, 0, 18); valLbl.Font = Enum.Font.GothamBold
        valLbl.Text = tostring(defaultVal); valLbl.TextColor3 = Color3.fromRGB(180, 170, 255)
        valLbl.TextSize = 12; valLbl.TextXAlignment = Enum.TextXAlignment.Right; valLbl.ZIndex = 22

        local track = Instance.new("Frame")
        track.Parent = row; track.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        track.BackgroundTransparency = 0.88; track.BorderSizePixel = 0
        track.Position = UDim2.new(0, 0, 0, 26); track.Size = UDim2.new(1, 0, 0, 8); track.ZIndex = 22
        do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = track end

        local pct0 = (defaultVal - minVal) / (maxVal - minVal)
        local fill = Instance.new("Frame")
        fill.Parent = track; fill.BackgroundColor3 = Color3.fromRGB(140, 130, 255)
        fill.BorderSizePixel = 0; fill.Size = UDim2.new(pct0, 0, 1, 0); fill.ZIndex = 23
        do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = fill end

        local knob = Instance.new("Frame")
        knob.Parent = track; knob.BackgroundColor3 = Color3.fromRGB(200, 195, 255)
        knob.BorderSizePixel = 0; knob.AnchorPoint = Vector2.new(0.5, 0.5)
        knob.Position = UDim2.new(pct0, 0, 0.5, 0); knob.Size = UDim2.new(0, 16, 0, 16); knob.ZIndex = 24
        do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = knob end

        local btn = Instance.new("TextButton")
        btn.Parent = track; btn.BackgroundTransparency = 1
        btn.Size = UDim2.new(1, 0, 1, 0); btn.Text = ""; btn.ZIndex = 25; btn.AutoButtonColor = false

        local sliding = false
        local function setFromX(x)
            local p = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            val = math.round(minVal + (maxVal - minVal) * p)
            fill.Size = UDim2.new(p, 0, 1, 0)
            knob.Position = UDim2.new(p, 0, 0.5, 0)
            valLbl.Text = tostring(val)
        end

        btn.MouseButton1Down:Connect(function() sliding = true; setFromX(plr:GetMouse().X) end)
        UserInputService.InputChanged:Connect(function(inp)
            if sliding and inp.UserInputType == Enum.UserInputType.MouseMovement then setFromX(inp.Position.X) end
        end)
        UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
        end)

        return function() return val end
    end

    getFBSpeed    = BuildSlider(72,  "🏃 Speed",    1, 80, 40)
    getFBDistance = BuildSlider(132, "📏 Distance",  1, 10, 3)

    FBToggleBtn = Instance.new("TextButton")
    FBToggleBtn.Parent = FaceBangWindow
    FBToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    FBToggleBtn.BackgroundTransparency = 0.88
    FBToggleBtn.BorderSizePixel = 0
    FBToggleBtn.Position = UDim2.new(0.1, 0, 0, 200)
    FBToggleBtn.Size = UDim2.new(0.8, 0, 0, 40)
    FBToggleBtn.Font = Enum.Font.GothamBold
    FBToggleBtn.Text = "▶ Start (Z)"
    FBToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    FBToggleBtn.TextSize = 14; FBToggleBtn.ZIndex = 21; FBToggleBtn.AutoButtonColor = false
    do
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = FBToggleBtn
        local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255, 255, 255)
        s.Transparency = 0.88; s.Thickness = 1; s.Parent = FBToggleBtn
    end
    FBToggleBtn.MouseEnter:Connect(function() TweenService:Create(FBToggleBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.65}):Play() end)
    FBToggleBtn.MouseLeave:Connect(function() TweenService:Create(FBToggleBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.88}):Play() end)

    do
        local fbDragging, fbDragInput, fbDragStart, fbStartPos
        local function fbUpdate(input)
            local d = input.Position - fbDragStart
            FaceBangWindow.Position = UDim2.new(fbStartPos.X.Scale, fbStartPos.X.Offset + d.X, fbStartPos.Y.Scale, fbStartPos.Y.Offset + d.Y)
        end
        FBTitleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                fbDragging = true; fbDragStart = input.Position; fbStartPos = FaceBangWindow.Position
                input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then fbDragging = false end end)
            end
        end)
        FBTitleBar.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                fbDragInput = input
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input == fbDragInput and fbDragging then fbUpdate(input) end
        end)
    end

    -- Open from Misc menu
    FaceBangButton.MouseButton1Click:Connect(function()
        FaceBangWindow.Visible = not FaceBangWindow.Visible
    end)
end -- end GUI do block

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  LOGIC — FACE BANG                                           ║
-- ╚══════════════════════════════════════════════════════════════╝
-- =====================================================
-- FACE BANG LOGIC
-- =====================================================

FaceBangEnabled = false
faceBangThread = nil
faceBangTarget = nil  -- the player we're attached to
faceBangPhase = 1     -- 1 = forward, -1 = backward

local function GetNearestPlayer()
    local char = plr.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local nearest = nil
    local nearestDist = math.huge

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= plr and p.Character then
            local otherHRP = p.Character:FindFirstChild("HumanoidRootPart")
            if otherHRP then
                local dist = (hrp.Position - otherHRP.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = p
                end
            end
        end
    end
    return nearest
end

local function StopFaceBang()
    FaceBangEnabled = false
    faceBangTarget  = nil
    if faceBangThread then
        faceBangThread:Disconnect()
        faceBangThread = nil
    end
    pcall(function()
        local char = plr.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = false
            hum.AutoRotate    = true
            hum.Sit           = false
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.AssemblyLinearVelocity  = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)
    if canUsePhysicsRep then
        pcall(function()
            local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then sethiddenproperty(hrp, "PhysicsRepRootPart", nil) end
        end)
    end
    pcall(function()
        if FBToggleBtn and FBToggleBtn.Parent then
            FBToggleBtn.Text = "▶ Start (Z)"
            FBToggleBtn.BackgroundTransparency = 0.88
        end
        if FBStatusLabel and FBStatusLabel.Parent then
            FBStatusLabel.Text = "Status: Idle | Press Z to attach to nearest"
        end
    end)
    SendNotify("Face Bang", "Stopped", 2)
end

local function StartFaceBang(targetPlayer)
    if FaceBangEnabled then StopFaceBang() end

    local char = plr.Character
    if not char then SendNotify("Error", "No character", 2) return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    FaceBangEnabled = true
    faceBangTarget  = targetPlayer

    -- Set once — not every frame
    hum.PlatformStand = true
    hum.AutoRotate    = false
    hum.Sit           = false

    pcall(function()
        if FBToggleBtn and FBToggleBtn.Parent then
            FBToggleBtn.Text = "■ Stop (Z)"
            FBToggleBtn.BackgroundTransparency = 0.6
        end
        if FBStatusLabel and FBStatusLabel.Parent then
            FBStatusLabel.Text = "Status: Active → " .. targetPlayer.DisplayName
        end
    end)

    local oscillatorTime = 0

    -- PreSimulation: snaps position BEFORE the physics step — zero scheduling lag
    faceBangThread = RunService.PreSimulation:Connect(function(dt)
        if not FaceBangEnabled then return end
        if not UserInputService.WindowFocused then return end

        local localChar = plr.Character
        if not localChar then StopFaceBang(); return end
        local localHRP = localChar:FindFirstChild("HumanoidRootPart")
        local localHum = localChar:FindFirstChildOfClass("Humanoid")
        if not localHRP or not localHum then return end

        local targetChar = faceBangTarget and faceBangTarget.Character
        if not targetChar then
            pcall(function()
                if FBStatusLabel and FBStatusLabel.Parent then
                    FBStatusLabel.Text = "Status: Waiting for target..."
                end
            end)
            return
        end

        local targetHead = targetChar:FindFirstChild("Head")
        local targetHRP  = targetChar:FindFirstChild("HumanoidRootPart")
        if not targetHead or not targetHRP then return end

        -- Keep upright — no Sit (causes knee bend)
        localHum.PlatformStand = true
        localHum.AutoRotate    = false
        localHum.Sit           = false

        -- PhysicsRep replication
        if canUsePhysicsRep then
            pcall(sethiddenproperty, localHRP, "PhysicsRepRootPart", targetHead)
        end

        local speed    = getFBSpeed()
        local distance = getFBDistance()

        -- Oscillation driven by real dt for frame-rate independence
        oscillatorTime = oscillatorTime + (speed / 1.5) * dt
        local t        = (math.sin(oscillatorTime) + 1) / 2  -- 0..1..0

        local headCF = targetHead.CFrame
        local relativeOffset = Vector3.new(0, 0.75, -(0.5 + t * distance))
        local finalPos = headCF:PointToWorldSpace(relativeOffset)
        local lookBack = headCF.LookVector * -1
        local finalCF  = CFrame.lookAt(finalPos, finalPos + lookBack, Vector3.new(0, 1, 0))

        -- Direct snap — no lerp
        localHRP.CFrame                  = finalCF
        localHRP.AssemblyLinearVelocity  = Vector3.zero
        localHRP.AssemblyAngularVelocity = Vector3.zero
    end)

    SendNotify("Face Bang", "Attached to " .. targetPlayer.DisplayName, 3)
end

-- Toggle button click
FBToggleBtn.MouseButton1Click:Connect(function()
    if FaceBangEnabled then
        StopFaceBang()
    else
        local target = GetNearestPlayer()
        if target then
            StartFaceBang(target)
        else
            SendNotify("Face Bang", "No players nearby", 2)
        end
    end
end)

-- Z key: only works when FaceBang window is open
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Z and FaceBangWindow.Visible then
        if FaceBangEnabled then
            StopFaceBang()
        else
            local target = GetNearestPlayer()
            if target then
                StartFaceBang(target)
            else
                SendNotify("Face Bang", "No players nearby", 2)
            end
        end
    end
end)

-- Stop facebang when window is closed
FaceBangWindow:GetPropertyChangedSignal("Visible"):Connect(function()
    if not FaceBangWindow.Visible and FaceBangEnabled then
        StopFaceBang()
    end
end)

-- Minimize/Maximize Toggle Button (When Minimized)
ToggleButton = Instance.new("ImageButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = OnyxUI
ToggleButton.AnchorPoint = Vector2.new(1, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
ToggleButton.BackgroundTransparency = 0.2
ToggleButton.BorderSizePixel = 0
ToggleButton.Position = UDim2.new(1, -15, 0, 100)
ToggleButton.Size = UDim2.new(0, 50, 0, 50)
ToggleButton.Visible = false
ToggleButton.ZIndex = 10
ToggleButton.AutoButtonColor = false
ToggleButton.Image = ""

do
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 12)
    ToggleCorner.Parent = ToggleButton
    local ToggleStroke = Instance.new("UIStroke")
    ToggleStroke.Color = Color3.fromRGB(255, 255, 255)
    ToggleStroke.Transparency = 0.7
    ToggleStroke.Thickness = 2
    ToggleStroke.Parent = ToggleButton
end

-- Create logo icon inside toggle button
do
    local LogoIcon = Instance.new("Frame")
    LogoIcon.Name = "LogoIcon"
    LogoIcon.Parent = ToggleButton
    LogoIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    LogoIcon.BackgroundTransparency = 1
    LogoIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    LogoIcon.Size = UDim2.new(0, 30, 0, 30)
    LogoIcon.ZIndex = 11

    -- Create 3 horizontal lines for a minimalist menu icon
    local function createLine(yPos)
        local line = Instance.new("Frame")
        line.Parent = LogoIcon
        line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        line.BorderSizePixel = 0
        line.Position = UDim2.new(0, 0, 0, yPos)
        line.Size = UDim2.new(1, 0, 0, 3)
        line.ZIndex = 11
        local lineCorner = Instance.new("UICorner")
        lineCorner.CornerRadius = UDim.new(1, 0)
        lineCorner.Parent = line
        return line
    end
    createLine(4); createLine(13); createLine(22)
end

-- Dragging Functionality
do
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then update(input) end
    end)
end

-- Minimize/Maximize Animation
do
    local isMinimized = false
    local function toggleMinimize()
        isMinimized = not isMinimized
        if isMinimized then
            local tweenInfo = TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
            local sizeTween = TweenService:Create(MainFrame, tweenInfo, {Size = UDim2.new(0, 560, 0, 0)})
            local fadeTween = TweenService:Create(MainFrame, tweenInfo, {BackgroundTransparency = 1})
            sizeTween:Play(); fadeTween:Play()
            sizeTween.Completed:Connect(function()
                MainFrame.Visible = false; ToggleButton.Visible = true
                ToggleButton.BackgroundTransparency = 1
                TweenService:Create(ToggleButton, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.2}):Play()
            end)
        else
            MainFrame.Visible = true; MainFrame.Size = UDim2.new(0, 560, 0, 0); MainFrame.BackgroundTransparency = 1
            local fadeOut = TweenService:Create(ToggleButton, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1})
            fadeOut:Play()
            fadeOut.Completed:Connect(function() ToggleButton.Visible = false end)
            TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, 560, 0, 415)}):Play()
            TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0.1}):Play()
        end
    end
    MinimizeButton.MouseButton1Click:Connect(toggleMinimize)
    ToggleButton.MouseButton1Click:Connect(toggleMinimize)

    -- Keyboard shortcut to toggle minimize (key is configurable in Misc tab)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

        -- Capture new keybind if listening
        if minimizeKeyListening then
            -- Ignore modifier keys
            local ignored = {
                [Enum.KeyCode.LeftShift] = true, [Enum.KeyCode.RightShift] = true,
                [Enum.KeyCode.LeftControl] = true, [Enum.KeyCode.RightControl] = true,
                [Enum.KeyCode.LeftAlt] = true, [Enum.KeyCode.RightAlt] = true,
            }
            if not ignored[input.KeyCode] then
                minimizeKey = input.KeyCode
                minimizeKeyListening = false
                MinimizeKeyBtn.Text = "[" .. tostring(input.KeyCode.Name) .. "]"
                MinimizeKeyBtn.BackgroundTransparency = 0.5
            end
            return
        end

        if gameProcessed then return end
        if input.KeyCode == minimizeKey then
            toggleMinimize()
        end
    end)
end -- end minimize do

-- Close Button Functionality
do
-- Button Hover Effects
local function createHoverEffect(button, hoverTransparency, normalTransparency)
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = hoverTransparency}):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = normalTransparency}):Play()
    end)
end

createHoverEffect(MinimizeButton, 0.65, 0.88)

-- Special hover effect for toggle button
ToggleButton.MouseEnter:Connect(function()
    TweenService:Create(ToggleButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.05, Size = UDim2.new(0, 54, 0, 54)}):Play()
end)
ToggleButton.MouseLeave:Connect(function()
    TweenService:Create(ToggleButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.2, Size = UDim2.new(0, 50, 0, 50)}):Play()
end)

-- Tab Button Hover and Click Effects
local function setupTabButton(tabButton)
    createHoverEffect(tabButton, 0.88, 1)
    tabButton.MouseButton1Click:Connect(function()
        for _, child in pairs(TabContainer:GetChildren()) do
            if child:IsA("TextButton") then
                TweenService:Create(child, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(130, 130, 160)}):Play()
            end
        end
        TweenService:Create(tabButton, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.6, TextColor3 = Color3.fromRGB(220, 180, 255)}):Play()
        local tabName = tabButton.Name:gsub("Tab", "")
        HomeSection.Visible = false; TargetSection.Visible = false; AnimationSection.Visible = false
        CombatSection.Visible = false; MiscSection.Visible = false; VisualSection.Visible = false
        if tabName == "Home" then HomeSection.Visible = true
        elseif tabName == "Player" then TargetSection.Visible = true
        elseif tabName == "Animation" then AnimationSection.Visible = true
        elseif tabName == "Combat" then CombatSection.Visible = true
        elseif tabName == "Visual" then VisualSection.Visible = true
        elseif tabName == "Misc" then MiscSection.Visible = true
        end
    end)
end

setupTabButton(HomeTab); setupTabButton(PlayerTab); setupTabButton(AnimationTab)
setupTabButton(CombatTab); setupTabButton(VisualTab); setupTabButton(MiscTab)
end -- end hover/tab do

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  LOGIC — ZERO-DELAY ATTACHMENT (HeadSit / Backpack)          ║
-- ╚══════════════════════════════════════════════════════════════╝
-- =====================================================
-- ZERO DELAY ATTACHMENT SYSTEM (FIXED)
-- =====================================================

local ZeroDelayEnabled = false
local zeroDelayThread = nil
local zeroDelayTargetPlayer = nil
local zeroDelayConnection = nil
local zeroDelayMode = nil -- "headsit" or "backpack"

-- Freeze/unfreeze functions to prevent flinging
local function StopZeroDelayCleanup()
    if canUsePhysicsRep then
        pcall(function()
            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                sethiddenproperty(plr.Character.HumanoidRootPart, "PhysicsRepRootPart", nil)
            end
        end)
    end
    pcall(function()
        local char = plr.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = false
            hum.AutoRotate    = true
            hum.Sit           = false
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.AssemblyLinearVelocity  = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

local function StopZeroDelay()
    if not ZeroDelayEnabled then return end
    ZeroDelayEnabled = false
    zeroDelayMode    = nil
    if zeroDelayThread then
        zeroDelayThread:Disconnect()
        zeroDelayThread = nil
    end
    if zeroDelayConnection then
        zeroDelayConnection:Disconnect()
        zeroDelayConnection = nil
    end
    zeroDelayTargetPlayer = nil
    StopZeroDelayCleanup()
    SendNotify("Zero Delay", "Stopped", 2)
end

-- ZERO DELAY: PreSimulation snap — runs BEFORE the physics step for minimum lag
local function StartZeroDelay(targetPlayer, mode)
    if not targetPlayer then
        SendNotify("Error", "No target player", 3)
        return
    end

    if ZeroDelayEnabled then StopZeroDelay() end

    local char = plr.Character
    if not char then SendNotify("Error", "Character not loaded", 3) return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then SendNotify("Error", "Humanoid/HRP not found", 3) return end

    zeroDelayTargetPlayer = targetPlayer
    ZeroDelayEnabled      = true
    zeroDelayMode         = mode

    -- Disable auto-rotate; ensure PlatformStand is OFF for animations
    hum.PlatformStand = false
    hum.AutoRotate    = false
    hum.Sit           = true
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Seated) end)

    -- Pre-simulation: runs before Roblox physics tick → minimum possible delay
    zeroDelayThread = RunService.PreSimulation:Connect(function()
        if not ZeroDelayEnabled then return end
        if not UserInputService.WindowFocused then return end

        local localChar = plr.Character
        if not localChar then StopZeroDelay(); return end
        local localHRP = localChar:FindFirstChild("HumanoidRootPart")
        local localHum = localChar:FindFirstChildOfClass("Humanoid")
        if not localHRP or not localHum then return end

        local target = zeroDelayTargetPlayer
        if not target then StopZeroDelay(); return end
        local targetChar = target.Character
        if not targetChar then return end
        local targetHRP  = targetChar:FindFirstChild("HumanoidRootPart")
        local targetHead = targetChar:FindFirstChild("Head")
        if not targetHRP or not targetHead then return end

        -- PhysicsRep: tells the engine we're physically at the target
        if canUsePhysicsRep then
            pcall(sethiddenproperty, localHRP, "PhysicsRepRootPart", targetHead)
        end

        -- Compute final world CFrame
        local finalCF
        if mode == "headsit" then
            finalCF = targetHead.CFrame * CFrame.new(0, 2.5, 0)
        elseif mode == "backpack" then
            local tRot = targetHRP.CFrame.Rotation
            finalCF = CFrame.new(targetHRP.Position - tRot.LookVector * 1.8 + Vector3.new(0, 0.5, 0)) * tRot * CFrame.Angles(0, math.pi, 0)
        else
            finalCF = targetHRP.CFrame
        end

        -- Direct snap — no lerp, no lag
        localHRP.CFrame                  = finalCF
        localHRP.AssemblyLinearVelocity  = Vector3.zero
        localHRP.AssemblyAngularVelocity = Vector3.zero
        localHum.PlatformStand           = false
        localHum.AutoRotate              = false
        localHum.Sit                     = true
        if localHum:GetState() ~= Enum.HumanoidStateType.Seated then
            pcall(function() localHum:ChangeState(Enum.HumanoidStateType.Seated) end)
        end
    end)

    -- Respawn: restart tracking on new character
    if zeroDelayConnection then zeroDelayConnection:Disconnect() end
    zeroDelayConnection = plr.CharacterAdded:Connect(function()
        if ZeroDelayEnabled then
            task.wait(0.6)
            StartZeroDelay(zeroDelayTargetPlayer, zeroDelayMode)
        end
    end)

    SendNotify("Zero Delay", mode:upper() .. " started → " .. targetPlayer.DisplayName, 2)
end

-- HeadSit Button - ZERO DELAY BY DEFAULT
isHeadSitToggling = false
HeadSitButton.MouseButton1Click:Connect(function()
    if isHeadSitToggling then return end
    isHeadSitToggling = true

    if TargetedPlayer then
        local target = Players:FindFirstChild(TargetedPlayer)
        if target then
            if ZeroDelayEnabled and zeroDelayMode == "headsit" then
                StopZeroDelay()
                HeadSitButton.Text = "🪑 Sit on Head"
                HeadSitButton.BackgroundTransparency = 0.91
            else
                StartZeroDelay(target, "headsit")
                HeadSitButton.Text = "🪑 Stop HeadSit"
                HeadSitButton.BackgroundTransparency = 0.7
            end
        else
            SendNotify("Error", "Target not found", 3)
        end
    else
        SendNotify("Error", "No target selected", 3)
    end

    task.wait(0.5)
    isHeadSitToggling = false
end)

-- Backpack Button - ZERO DELAY BY DEFAULT
isBackpackToggling = false
BackpackButton.MouseButton1Click:Connect(function()
    if isBackpackToggling then return end
    isBackpackToggling = true

    if TargetedPlayer then
        local target = Players:FindFirstChild(TargetedPlayer)
        if target then
            if ZeroDelayEnabled and zeroDelayMode == "backpack" then
                StopZeroDelay()
                BackpackButton.Text = "🎒 Backpack Mode"
                BackpackButton.BackgroundTransparency = 0.91
            else
                StartZeroDelay(target, "backpack")
                BackpackButton.Text = "🎒 Stop Backpack"
                BackpackButton.BackgroundTransparency = 0.7
            end
        else
            SendNotify("Error", "Target not found", 3)
        end
    else
        SendNotify("Error", "No target selected", 3)
    end

    task.wait(0.5)
    isBackpackToggling = false
end)

-- TARGET FUNCTIONS
-- =====================================================

ViewingTarget = false
SpectatingTarget = false
FocusingTarget = false
AttachedToTarget = false
HeadSitting = false
BackpackMode = false

local function UpdateTarget(player)
    if player then
        TargetedPlayer = player.Name
        TargetNameInput.Text = player.Name
        TargetInfoLabel.Text = "Target: " .. player.DisplayName .. " (@" .. player.Name .. ")\nUserID: " .. player.UserId
        
        local userId = player.UserId
        local thumbType = Enum.ThumbnailType.HeadShot
        local thumbSize = Enum.ThumbnailSize.Size150x150
        local ok, content = pcall(function()
            return Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
        end)
        if ok and content then
            TargetImage.Image = content
        end
        
        SendNotify("Target Selected", player.DisplayName .. " is now your target", 3)
    else
        TargetedPlayer = nil
        -- Stop zero delay attach
        if ZeroDelayEnabled then
            StopZeroDelay()
            HeadSitButton.Text = "🪑 Sit on Head"
            HeadSitButton.BackgroundTransparency = 0.91
            BackpackButton.Text = "🎒 Backpack Mode"
            BackpackButton.BackgroundTransparency = 0.91
        end
        TargetNameInput.Text = ""
        TargetInfoLabel.Text = "No target selected"
        TargetImage.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
        
        ViewingTarget = false
        SpectatingTarget = false
        FocusingTarget = false
        AttachedToTarget = false
        HeadSitting = false
        BackpackMode = false
        
        ViewButton.Text = "👁️ View Target"
        FocusButton.Text = "🎯 Focus Target (Loop TP)"
        HeadSitButton.Text = "🪑 Sit on Head"
        BackpackButton.Text = "🎒 Backpack Mode"
        
        if plr.Character and plr.Character:FindFirstChild("Humanoid") then
            plr.Character.Humanoid.Sit = false
        end
    end
end

-- Target Name Input Handler
TargetNameInput.FocusLost:Connect(function()
    local playerName = TargetNameInput.Text
    local player = GetPlayer(playerName)
    
    if player then
        UpdateTarget(player)
    else
        SendNotify("Error", "Player not found", 3)
        TargetNameInput.Text = ""
    end
end)

-- View Target Button
ViewButton.MouseButton1Click:Connect(function()
    if TargetedPlayer then
        local target = Players:FindFirstChild(TargetedPlayer)
        if target and target.Character and target.Character:FindFirstChild("Humanoid") then
            ViewingTarget = not ViewingTarget
            
            if ViewingTarget then
                SendNotify("View Target", "Now viewing " .. target.DisplayName, 2)
                ViewButton.Text = "👁️ Stop Viewing"
                
                task.spawn(function()
                    repeat
                        pcall(function()
                            local currentTarget = Players:FindFirstChild(TargetedPlayer)
                            if currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild("Humanoid") then
                                local hum = currentTarget.Character and currentTarget.Character:FindFirstChildOfClass("Humanoid")
                                if hum then workspace.CurrentCamera.CameraSubject = hum end
                            end
                        end)
                        task.wait(0.5)
                    until not ViewingTarget or not TargetedPlayer
                    
                    if plr.Character and plr.Character:FindFirstChild("Humanoid") then
                        local selfHum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
                                if selfHum then workspace.CurrentCamera.CameraSubject = selfHum end
                    end
                    ViewButton.Text = "👁️ View Target"
                end)
            else
                if plr.Character and plr.Character:FindFirstChild("Humanoid") then
                    local selfHum2 = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
                if selfHum2 then workspace.CurrentCamera.CameraSubject = selfHum2 end
                end
                SendNotify("View Target", "Stopped viewing", 2)
                ViewButton.Text = "👁️ View Target"
            end
        else
            SendNotify("Error", "Target not found or has no character", 3)
        end
    else
        SendNotify("Error", "No target selected", 3)
    end
end)

-- Teleport to Target Button
TeleportButton.MouseButton1Click:Connect(function()
    if TargetedPlayer then
        local target = Players:FindFirstChild(TargetedPlayer)
        if target then
            TeleportTO(target)
            SendNotify("Teleport", "Teleported to " .. target.DisplayName, 2)
        end
    else
        SendNotify("Error", "No target selected", 3)
    end
end)

-- Bring Target Button
BringButton.MouseButton1Click:Connect(function()
    if TargetedPlayer then
        SendNotify("Bring Target", "This feature requires specific exploit capabilities", 3)
    else
        SendNotify("Error", "No target selected", 3)
    end
end)

-- Focus Target Button (Loop TP)
FocusButton.MouseButton1Click:Connect(function()
    if TargetedPlayer then
        local target = Players:FindFirstChild(TargetedPlayer)
        if target then
            FocusingTarget = not FocusingTarget
            
            if FocusingTarget then
                SendNotify("Focus Target", "Looping teleport to " .. target.DisplayName, 2)
                FocusButton.Text = "🎯 Stop Focus"
                
                task.spawn(function()
                    while FocusingTarget and TargetedPlayer do
                        local currentTarget = Players:FindFirstChild(TargetedPlayer)
                        if currentTarget then
                            TeleportTO(currentTarget)
                        else
                            FocusingTarget = false
                            FocusButton.Text = "🎯 Focus Target (Loop TP)"
                            break
                        end
                        task.wait(0.1)
                    end
                end)
            else
                SendNotify("Focus Target", "Stopped focusing", 2)
                FocusButton.Text = "🎯 Focus Target (Loop TP)"
            end
        end
    else
        SendNotify("Error", "No target selected", 3)
    end
end)

-- Clear Target Button
ClearTargetButton.MouseButton1Click:Connect(function()
    -- Stop zero delay attach if active
    if ZeroDelayEnabled then
        StopZeroDelay()
        HeadSitButton.Text = "🪑 Sit on Head"
        HeadSitButton.BackgroundTransparency = 0.91
        BackpackButton.Text = "🎒 Backpack Mode"
        BackpackButton.BackgroundTransparency = 0.91
    end
    UpdateTarget(nil)
    SendNotify("Target Cleared", "Target has been cleared", 2)
end)

-- Auto-clear target when they leave
Players.PlayerRemoving:Connect(function(player)
    if TargetedPlayer == player.Name then
        -- Stop zero delay attach if active
        if ZeroDelayEnabled then
            StopZeroDelay()
        end
        UpdateTarget(nil)
        SendNotify("Target Left", player.DisplayName .. " left the game", 3)
    end
end)

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  LOGIC — ANTI VC BAN WINDOW                                  ║
-- ╚══════════════════════════════════════════════════════════════╝
-- =====================================================
-- ANTI VC BAN — embedded from Antivcban.lua
-- Button spawns the standalone script's UI + logic
-- =====================================================

local _antiVCLoaded = false
AntiVCButton.MouseButton1Click:Connect(function()
    if _antiVCLoaded then return end
    _antiVCLoaded = true

    local function gs(sn)
        if cloneref then return cloneref(game:GetService(sn))
        else return game:GetService(sn) end
    end
    local vc = (function() local ok,s = pcall(gs,"VoiceChatService") return ok and s or nil end)()
    local vi = (function() local ok,s = pcall(gs,"VoiceChatInternal") return ok and s or nil end)()

    local mf = Instance.new("Frame")
    mf.Name = "AntiVCWindow"; mf.Parent = OnyxUI
    mf.BackgroundColor3 = Color3.fromRGB(15,15,25)
    mf.BackgroundTransparency = 0.3; mf.BorderSizePixel = 0
    mf.Position = UDim2.new(0.5,-125,0.5,-120)
    mf.Size = UDim2.new(0,250,0,240)
    mf.Active = true; mf.Draggable = true
    mf.ZIndex = 20; mf.ClipsDescendants = true
    do
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,16); c.Parent = mf
        local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255,255,255)
        s.Transparency = 0.8; s.Thickness = 1; s.Parent = mf
    end

    local tb = Instance.new("Frame"); tb.Parent = mf
    tb.BackgroundColor3 = Color3.fromRGB(255,255,255)
    tb.BackgroundTransparency = 0.95; tb.BorderSizePixel = 0
    tb.Size = UDim2.new(1,0,0,40); tb.ZIndex = 21
    do
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,16); c.Parent = tb
        local t = Instance.new("TextLabel"); t.Parent = tb
        t.BackgroundTransparency = 1; t.Position = UDim2.new(0,15,0,0)
        t.Size = UDim2.new(1,-80,1,0); t.Font = Enum.Font.GothamBold
        t.Text = "🎤 Anti VC Ban"; t.TextColor3 = Color3.fromRGB(255,255,255)
        t.TextSize = 16; t.TextXAlignment = Enum.TextXAlignment.Left; t.ZIndex = 22
    end
    do
        local cb = Instance.new("TextButton"); cb.Parent = tb
        cb.BackgroundColor3 = Color3.fromRGB(255,80,80); cb.BackgroundTransparency = 0.3
        cb.BorderSizePixel = 0; cb.AnchorPoint = Vector2.new(1,0.5)
        cb.Position = UDim2.new(1,-10,0.5,0); cb.Size = UDim2.new(0,25,0,25)
        cb.Font = Enum.Font.GothamBold; cb.Text = "×"
        cb.TextColor3 = Color3.fromRGB(255,255,255); cb.TextSize = 18
        cb.ZIndex = 22; cb.AutoButtonColor = false
        do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = cb end
        cb.MouseButton1Click:Connect(function() mf:Destroy(); _antiVCLoaded = false end)

        local mn = Instance.new("TextButton"); mn.Parent = tb
        mn.BackgroundColor3 = Color3.fromRGB(255,255,255); mn.BackgroundTransparency = 0.9
        mn.BorderSizePixel = 0; mn.AnchorPoint = Vector2.new(1,0.5)
        mn.Position = UDim2.new(1,-45,0.5,0); mn.Size = UDim2.new(0,25,0,25)
        mn.Font = Enum.Font.GothamBold; mn.Text = "−"
        mn.TextColor3 = Color3.fromRGB(255,255,255); mn.TextSize = 18
        mn.ZIndex = 22; mn.AutoButtonColor = false
        do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = mn end
        local minimized = false
        mn.MouseButton1Click:Connect(function()
            minimized = not minimized
            TweenService:Create(mf, TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out), {
                Size = minimized and UDim2.new(0,250,0,40) or UDim2.new(0,250,0,240)
            }):Play()
            mn.Text = minimized and "+" or "−"
        end)
    end

    local micFrame = Instance.new("Frame"); micFrame.Parent = mf
    micFrame.BackgroundColor3 = Color3.fromRGB(0,0,0)
    micFrame.BackgroundTransparency = 0.5
    micFrame.AnchorPoint = Vector2.new(0.5,0)
    micFrame.Position = UDim2.new(0.5,0,0,50)
    micFrame.Size = UDim2.new(0,56,0,56); micFrame.ZIndex = 21
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = micFrame end

    local micIcon = Instance.new("ImageLabel"); micIcon.Parent = micFrame
    micIcon.BackgroundTransparency = 1
    micIcon.Position = UDim2.new(0.15,0,0.15,0); micIcon.Size = UDim2.new(0.7,0,0.7,0)
    micIcon.Image = "rbxassetid://10734888864"
    micIcon.ImageColor3 = Color3.fromRGB(100,255,100); micIcon.ZIndex = 22

    local crossLine = Instance.new("Frame"); crossLine.Parent = micFrame
    crossLine.BackgroundColor3 = Color3.fromRGB(255,60,60); crossLine.BorderSizePixel = 0
    crossLine.AnchorPoint = Vector2.new(0.5,0.5)
    crossLine.Position = UDim2.new(0.5,0,0.5,0); crossLine.Size = UDim2.new(1.2,0,0,4)
    crossLine.Rotation = -45; crossLine.Visible = false; crossLine.ZIndex = 23

    -- Status text
    local statusLbl = Instance.new("TextLabel"); statusLbl.Parent = mf
    statusLbl.BackgroundTransparency = 1
    statusLbl.Position = UDim2.new(0,0,0,112); statusLbl.Size = UDim2.new(1,0,0,16)
    statusLbl.Font = Enum.Font.GothamMedium; statusLbl.Text = "● Mic Active"
    statusLbl.TextColor3 = Color3.fromRGB(100,255,100); statusLbl.TextSize = 12
    statusLbl.ZIndex = 21

    local function makeBtn(yPos, label, strokeColor)
        local btn = Instance.new("TextButton"); btn.Parent = mf
        btn.BackgroundColor3 = Color3.fromRGB(255,255,255)
        btn.BackgroundTransparency = 0.9; btn.BorderSizePixel = 0
        btn.Position = UDim2.new(0.08,0,0,yPos); btn.Size = UDim2.new(0.84,0,0,32)
        btn.Font = Enum.Font.GothamBold; btn.Text = label
        btn.TextColor3 = Color3.fromRGB(255,255,255); btn.TextSize = 13
        btn.ZIndex = 21; btn.AutoButtonColor = false
        do
            local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,10); c.Parent = btn
            local s = Instance.new("UIStroke"); s.Color = strokeColor or Color3.fromRGB(255,255,255)
            s.Transparency = 0.82; s.Thickness = 1; s.Parent = btn
        end
        btn.MouseEnter:Connect(function() TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundTransparency=0.7}):Play() end)
        btn.MouseLeave:Connect(function() TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundTransparency=0.9}):Play() end)
        return btn
    end

       local muteBtn = makeBtn(136, "🔇 Mute", Color3.fromRGB(255,160,100))

    local function refreshMicUI()
        local isMuted = false
        
        -- Try multiple methods to check mute status
        if vi then
            local ok, paused = pcall(function() return vi:IsPublishPaused() end)
            if ok then 
                isMuted = paused
            end
        end
        
        -- Also try VoiceChatService
        if vc and not isMuted then
            local ok, vcMuted = pcall(function() return vc:IsMuted() end)
            if ok then
                isMuted = vcMuted
            end
        end
        
        -- Update UI based on mute state
        if isMuted then
            micIcon.ImageColor3  = Color3.fromRGB(180,180,180)
            micIcon.ImageTransparency = 0.4
            crossLine.Visible    = true
            statusLbl.Text       = "● Mic Muted"
            statusLbl.TextColor3 = Color3.fromRGB(255,100,100)
            muteBtn.Text         = "🎤 Unmute"
        else
            micIcon.ImageColor3  = Color3.fromRGB(100,255,100)
            micIcon.ImageTransparency = 0
            crossLine.Visible    = false
            statusLbl.Text       = "● Mic Active"
            statusLbl.TextColor3 = Color3.fromRGB(100,255,100)
            muteBtn.Text         = "🔇 Mute"
        end
    end

    muteBtn.MouseButton1Click:Connect(function()
        local currentlyMuted = false
        local success = false
        
        -- Method 1: Try VoiceChatInternal first
        if vi then
            local ok, paused = pcall(function() return vi:IsPublishPaused() end)
            if ok then
                currentlyMuted = paused
                -- Toggle mute
                local toggleOk = pcall(function() 
                    vi:PublishPause(not currentlyMuted)
                end)
                if toggleOk then
                    success = true
                    SendNotify("🎤 Mic", (not currentlyMuted) and "Muted" or "Unmuted", 1.5)
                end
            end
        end
        
        -- Method 2: Try VoiceChatService as fallback
        if not success and vc then
            local ok, vcMuted = pcall(function() return vc:IsMuted() end)
            if ok then
                currentlyMuted = vcMuted
                local toggleOk = pcall(function()
                    vc:SetMicrophoneMuted(not currentlyMuted)
                end)
                if toggleOk then
                    success = true
                    SendNotify("🎤 Mic", (not currentlyMuted) and "Muted" or "Unmuted", 1.5)
                end
            end
        end
        
        -- Method 3: Try direct mute/unmute if both failed
        if not success then
            if vi then
                -- Just try to mute regardless of current state
                pcall(function() vi:PublishPause(true) end)
                task.wait(0.1)
                -- Then check if we should unmute based on button text
                if muteBtn.Text:match("Unmute") then
                    pcall(function() vi:PublishPause(false) end)
                end
            elseif vc then
                pcall(function() vc:ToggleMic() end)
            end
            SendNotify("🎤 Mic", "Toggle attempted", 1.5)
        end
        
        -- Wait and refresh UI
        task.wait(0.1)
        refreshMicUI()
    end)

    -- Poll mic state every 0.25s so the icon stays in sync
    local pollConn
    pollConn = RunService.Heartbeat:Connect(function()
        if not mf.Parent then pollConn:Disconnect(); return end
    end)
    local lastPaused = nil
    task.spawn(function()
        while mf.Parent do
            local currentState = false
            
            -- Check mute state
            if vi then
                local ok, paused = pcall(function() return vi:IsPublishPaused() end)
                if ok then currentState = paused end
            end
            
            if vc and not currentState then
                local ok, vcMuted = pcall(function() return vc:IsMuted() end)
                if ok then currentState = vcMuted end
            end
            
            -- Only refresh UI if state changed
            if currentState ~= lastPaused then
                lastPaused = currentState
                refreshMicUI()
            end
            
            task.wait(0.25)
        end
    end)
    refreshMicUI()

    -- Poll mic state every 0.5s so the icon stays in sync
    local pollConn
    pollConn = RunService.Heartbeat:Connect(function()
        if not mf.Parent then pollConn:Disconnect(); return end
    end)
    local lastPaused = nil
    task.spawn(function()
        while mf.Parent do
            if vi then
                local ok, paused = pcall(function() return vi:IsPublishPaused() end)
                if ok and paused ~= lastPaused then
                    lastPaused = paused
                    refreshMicUI()
                end
            end
            task.wait(0.25)
        end
    end)
    refreshMicUI()

    local activateBtn = makeBtn(178, "⚡ Activate Anti-Ban", Color3.fromRGB(140,130,255))

    -- ── Anti-VC Ban logic ────────────────────────────────────────────────────
    -- Method: continuous session reset via JoinByGroupId(groupId, FALSE).
    --   false = join UNMUTED so your mic stays live for other players.
    --   Each call resets your VC moderation session counter on Roblox's backend.
    --   8-second interval keeps resets happening before any warning can register.
    --   PublishPause(false) is called each cycle to auto-unmute your REAL mic.
    --   The pill button / GUI mic indicator is NOT touched — only the audio stream.
    -- ──────────────────────────────────────────────────────────────────────────
    local vcRunning  = false
    local vcTask     = nil
    local isProcessing = false

    local function doVCResetImproved()
        if isProcessing then return end
        isProcessing = true
        
        pcall(function()
            if not vi then return end
            
            -- Step 1: Get group ID and ensure unmuted
            local gi = vi:GetGroupId()
            if not gi or gi == "" then 
                isProcessing = false
                return 
            end
            
            vi:PublishPause(false)
            task.wait(3)
            
            -- Step 2-3: Join muted, leave, join muted again
            vi:JoinByGroupId(gi, true)
            if vc then pcall(function() vc:leaveVoice() end) end
            vi:JoinByGroupId(gi, true)
            task.wait(6)
            
            -- Step 4-5: Final join and voice activation
            vi:JoinByGroupId(gi, true)
            if vc then pcall(function() vc:joinVoice() end) end
            
            -- Ensure we're unmuted after the cycle
            task.wait(0.5)
            vi:PublishPause(false)
        end)
        
        isProcessing = false
    end

    local function stopVCProtection()
        vcRunning = false
        if vcTask then 
            task.cancel(vcTask)
            vcTask = nil 
        end
        if mf.Parent then
            activateBtn.Text = "⚡ Activate Anti-Ban"
            activateBtn.BackgroundTransparency = 0.9
            TweenService:Create(activateBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(255,255,255)
            }):Play()
            statusLbl.Text       = "● Mic Active"
            statusLbl.TextColor3 = Color3.fromRGB(100,255,100)
        end
        SendNotify("🎤 Anti VC Ban", "Protection stopped", 2)
    end

    local function startVCProtection()
        if not vi then
            SendNotify("Anti VC Ban", "VoiceChatInternal unavailable on this executor", 3)
            return
        end
        if not vc then
            SendNotify("Anti VC Ban", "VoiceChatService unavailable", 3)
            return
        end
        
        vcRunning = true

        activateBtn.Text = "⛔ Stop Protection (Active)"
        TweenService:Create(activateBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(40, 180, 100)
        }):Play()
        activateBtn.BackgroundTransparency = 0
        statusLbl.Text       = "⚡ Processing anti-ban..."
        statusLbl.TextColor3 = Color3.fromRGB(140,130,255)

        -- Run initial cycle
        SendNotify("🎤 Anti VC Ban", "Running initial protection cycle...", 2)
        
        vcTask = task.spawn(function()
            -- Do first cycle immediately
            doVCResetImproved()
            
            if mf.Parent then
                statusLbl.Text = "✓ Protection complete!"
                statusLbl.TextColor3 = Color3.fromRGB(100,255,100)
            end
            
            task.wait(2)
            
            -- Update status
            if mf.Parent then
                statusLbl.Text = "● Ready (Click to run again)"
                statusLbl.TextColor3 = Color3.fromRGB(140,200,255)
            end
            
            -- Reset button state after completion
            vcRunning = false
            if mf.Parent then
                activateBtn.Text = "⚡ Activate Anti-Ban"
                activateBtn.BackgroundTransparency = 0.9
                TweenService:Create(activateBtn, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(255,255,255)
                }):Play()
            end
            
            SendNotify("🎤 Anti VC Ban", "Cycle complete - You're protected!", 3)
        end)
    end

    activateBtn.MouseButton1Click:Connect(function()
        if vcRunning or isProcessing then 
            SendNotify("Anti VC Ban", "Protection cycle already running...", 2)
            return 
        end
        startVCProtection()
    end)

    -- Stop protection if window is destroyed (close button)
    mf:GetPropertyChangedSignal("Parent"):Connect(function()
        if not mf.Parent then stopVCProtection() end
    end)
end)

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  LOGIC — ANIMATION SYSTEM                                    ║
-- ╚══════════════════════════════════════════════════════════════╝
-- =====================================================
-- ANIMATION SYSTEM (Integrated from Gazer)
-- =====================================================

-- Check R15 requirement
pcall(function()
    local char = plr.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
    if not hum or hum.RigType ~= Enum.HumanoidRigType.R15 then
        SendNotify("R6 Detected", "Animations require R15! Please switch to R15.", 10)
    end
end)

-- Original Animations Database (Complete from document)
OriginalAnimations = {
    ["Idle"] = {
        ["2016 Animation (mm2)"] = {"387947158", "387947464"},
        ["(UGC) Oh Really?"] = {"98004748982532", "98004748982532"},
        ["Astronaut"] = {"891621366", "891633237"},
        ["Adidas Community"] = {"122257458498464", "102357151005774"},
        ["Bold"] = {"16738333868", "16738334710"},
        ["(UGC) Slasher"] = {"140051337061095", "140051337061095"},
        ["(UGC) Retro"] = {"80479383912838", "80479383912838"},
        ["(UGC) Magician"] = {"139433213852503", "139433213852503"},
        ["(UGC) John Doe"] = {"72526127498800", "72526127498800"},
        ["(UGC) Noli"] = {"139360856809483", "139360856809483"},
        ["(UGC) Coolkid"] = {"95203125292023", "95203125292023"},
        ["(UGC) Survivor Injured"] = {"73905365652295", "73905365652295"},
        ["(UGC) Retro Zombie"] = {"90806086002292", "90806086002292"},
        ["(UGC) 1x1x1x1"] = {"76780522821306", "76780522821306"},
        ["Borock"] = {"3293641938", "3293642554"},
        ["Bubbly"] = {"910004836", "910009958"},
        ["Cartoony"] = {"742637544", "742638445"},
        ["Confident"] = {"1069977950", "1069987858"},
        ["Catwalk Glam"] = {"133806214992291", "94970088341563"},
        ["Cowboy"] = {"1014390418", "1014398616"},
        ["Drooling Zombie"] = {"3489171152", "3489171152"},
        ["Elder"] = {"10921101664", "10921102574"},
        ["Ghost"] = {"616006778", "616008087"},
        ["Knight"] = {"657595757", "657568135"},
        ["Levitation"] = {"616006778", "616008087"},
        ["Mage"] = {"707742142", "707855907"},
        ["MrToilet"] = {"4417977954", "4417978624"},
        ["Ninja"] = {"656117400", "656118341"},
        ["NFL"] = {"92080889861410", "74451233229259"},
        ["OldSchool"] = {"10921230744", "10921232093"},
        ["Patrol"] = {"1149612882", "1150842221"},
        ["Pirate"] = {"750781874", "750782770"},
        ["Default Retarget"] = {"95884606664820", "95884606664820"},
        ["Very Long"] = {"18307781743", "18307781743"},
        ["Sway"] = {"560832030", "560833564"},
        ["Popstar"] = {"1212900985", "1150842221"},
        ["Princess"] = {"941003647", "941013098"},
        ["R6"] = {"12521158637", "12521162526"},
        ["R15 Reanimated"] = {"4211217646", "4211218409"},
        ["Realistic"] = {"17172918855", "17173014241"},
        ["Robot"] = {"616088211", "616089559"},
        ["Sneaky"] = {"1132473842", "1132477671"},
        ["Sports (Adidas)"] = {"18537376492", "18537371272"},
        ["Soldier"] = {"3972151362", "3972151362"},
        ["Stylish"] = {"616136790", "616138447"},
        ["Stylized Female"] = {"4708191566", "4708192150"},
        ["Superhero"] = {"10921288909", "10921290167"},
        ["Toy"] = {"782841498", "782845736"},
        ["Udzal"] = {"3303162274", "3303162549"},
        ["Vampire"] = {"1083445855", "1083450166"},
        ["Werewolf"] = {"1083195517", "1083214717"},
        ["Wicked (Popular)"] = {"118832222982049", "76049494037641"},
        ["No Boundaries (Walmart)"] = {"18747067405", "18747063918"},
        ["Zombie"] = {"616158929", "616160636"},
        ["(UGC) Zombie"] = {"77672872857991", "77672872857991"},
        ["(UGC) TailWag"] = {"129026910898635", "129026910898635"},
        ["[VOTE] warming up"] = {"83573330053643", "83573330053643"},
        ["cesus"] = {"115879733952840", "115879733952840"},
        ["[VOTE] Float"] = {"110375749767299", "110375749767299"},
        ["UGC Oneleft"] = {"121217497452435", "121217497452435"},
        ["AuraFarming"] = {"138665010911335", "138665010911335"},
        ["[VOTE] Mech Float"] = {"74447366032908", "74447366032908"},
        ["Badware"] = {"140131631438778", "140131631438778"},
        ["Wicked 'Dancing Through Life'"] = {"92849173543269", "132238900951109"},
        ["Unboxed By Amazon"] = {"98281136301627", "138183121662404"}
    },
    ["Walk"] = {
        ["Geto"] = "85811471336028",
        ["Patrol"] = "1151231493",
        ["Drooling Zombie"] = "3489174223",
        ["Adidas Community"] = "122150855457006",
        ["Levitation"] = "616013216",
        ["Catwalk Glam"] = "109168724482748",
        ["Knight"] = "10921127095",
        ["Pirate"] = "750785693",
        ["Bold"] = "16738340646",
        ["Sports (Adidas)"] = "18537392113",
        ["Zombie"] = "616168032",
        ["Astronaut"] = "891667138",
        ["Cartoony"] = "742640026",
        ["Ninja"] = "656121766",
        ["Confident"] = "1070017263",
        ["Wicked 'Dancing Through Life'"] = "73718308412641",
        ["Unboxed By Amazon"] = "90478085024465",
        ["Gojo"] = "95643163365384",
        ["R15 Reanimated"] = "4211223236",
        ["Ghost"] = "616013216",
        ["2016 Animation (mm2)"] = "387947975",
        ["(UGC) Zombie"] = "113603435314095",
        ["No Boundaries (Walmart)"] = "18747074203",
        ["Rthro"] = "10921269718",
        ["Werewolf"] = "1083178339",
        ["Wicked (Popular)"] = "92072849924640",
        ["Vampire"] = "1083473930",
        ["Popstar"] = "1212980338",
        ["Mage"] = "707897309",
        ["(UGC) Smooth"] = "76630051272791",
        ["R6"] = "12518152696",
        ["NFL"] = "110358958299415",
        ["Bubbly"] = "910034870",
        ["(UGC) Retro"] = "107806791584829",
        ["(UGC) Retro Zombie"] = "140703855480494",
        ["OldSchool"] = "10921244891",
        ["Elder"] = "10921111375",
        ["Stylish"] = "616146177",
        ["Stylized Female"] = "4708193840",
        ["Robot"] = "616095330",
        ["Sneaky"] = "1132510133",
        ["Superhero"] = "10921298616",
        ["Udzal"] = "3303162967",
        ["Toy"] = "782843345",
        ["Default Retarget"] = "115825677624788",
        ["Princess"] = "941028902",
        ["Cowboy"] = "1014421541"
    },
    ["Run"] = {
        ["Robot"] = "10921250460",
        ["Patrol"] = "1150967949",
        ["Drooling Zombie"] = "3489173414",
        ["Adidas Community"] = "82598234841035",
        ["Heavy Run (Udzal / Borock)"] = "3236836670",
        ["Catwalk Glam"] = "81024476153754",
        ["Knight"] = "10921121197",
        ["Pirate"] = "750783738",
        ["Bold"] = "16738337225",
        ["Sports (Adidas)"] = "18537384940",
        ["Zombie"] = "616163682",
        ["Astronaut"] = "10921039308",
        ["Cartoony"] = "10921076136",
        ["Ninja"] = "656118852",
        ["(UGC) Dog"] = "130072963359721",
        ["Wicked 'Dancing Through Life'"] = "135515454877967",
        ["Unboxed By Amazon"] = "134824450619865",
        ["[UGC] Flipping"] = "124427738251511",
        ["Sneaky"] = "1132494274",
        ["R6"] = "12518152696",
        ["[VOTE] Aura"] = "120142877225965",
        ["Popstar"] = "1212980348",
        ["[UGC] reset"] = "0",
        ["Wicked (Popular)"] = "72301599441680",
        ["[UGC] chibi"] = "85887415033585",
        ["R15 Reanimated"] = "4211220381",
        ["Mage"] = "10921148209",
        ["Ghost"] = "616013216",
        ["Rthro"] = "10921261968",
        ["Confident"] = "1070001516",
        ["Stylized Female"] = "4708192705",
        ["No Boundaries (Walmart)"] = "18747070484",
        ["Elder"] = "10921104374",
        ["Werewolf"] = "10921336997",
        ["[UGC] Girly"] = "128578785610052",
        ["Stylish"] = "10921276116",
        ["(UGC) Pride"] = "116462200642360",
        ["NFL"] = "117333533048078",
        ["(UGC) Soccer"] = "116881956670910",
        ["MrToilet"] = "4417979645",
        ["[VOTE] Float"] = "71267457613791",
        ["Levitation"] = "616010382",
        ["(UGC) Retro"] = "107806791584829",
        ["(UGC) Retro Zombie"] = "140703855480494",
        ["OldSchool"] = "10921240218",
        ["Vampire"] = "10921320299",
        ["furry"] = "102269417125238",
        ["Bubbly"] = "10921057244",
        ["fake wicked"] = "138992096476836",
        ["2016 Animation (mm2)"] = "387947975",
        ["[UGC] ball"] = "132499588684957",
        ["Superhero"] = "10921291831",
        ["Toy"] = "10921306285",
        ["Default Retarget"] = "102294264237491",
        ["Princess"] = "941015281",
        ["Cowboy"] = "1014401683"
    },
    ["Jump"] = {
        ["Robot"] = "616090535",
        ["Patrol"] = "1148811837",
        ["Adidas Community"] = "75290611992385",
        ["Levitation"] = "616008936",
        ["Catwalk Glam"] = "116936326516985",
        ["Knight"] = "910016857",
        ["Pirate"] = "750782230",
        ["Bold"] = "16738336650",
        ["Sports (Adidas)"] = "18537380791",
        ["Zombie"] = "616161997",
        ["Astronaut"] = "891627522",
        ["Cartoony"] = "742637942",
        ["Ninja"] = "656117878",
        ["Confident"] = "1069984524",
        ["Wicked 'Dancing Through Life'"] = "78508480717326",
        ["Unboxed By Amazon"] = "121454505477205",
        ["R6"] = "12520880485",
        ["R15 Reanimated"] = "4211219390",
        ["Ghost"] = "616008936",
        ["Rthro"] = "10921263860",
        ["No Boundaries (Walmart)"] = "18747069148",
        ["Werewolf"] = "1083218792",
        ["Cowboy"] = "1014394726",
        ["UGC"] = "91788124131212",
        ["[VOTE] Animal"] = "131203832825082",
        ["Popstar"] = "1212954642",
        ["Mage"] = "10921149743",
        ["Sneaky"] = "1132489853",
        ["Superhero"] = "10921294559",
        ["Elder"] = "10921107367",
        ["(UGC) Retro"] = "139390570947836",
        ["NFL"] = "119846112151352",
        ["OldSchool"] = "10921242013",
        ["Stylized Female"] = "4708188025",
        ["Stylish"] = "616139451",
        ["Bubbly"] = "910016857",
        ["[VOTE] Float"] = "75611679208549",
        ["[VOTE] Aura"] = "93382302369459",
        ["Vampire"] = "1083455352",
        ["Wicked (Popular)"] = "104325245285198",
        ["Toy"] = "10921308158",
        ["Default Retarget"] = "117150377950987",
        ["Princess"] = "941008832",
        ["[UGC] happy"] = "72388373557525"
    },
    ["Fall"] = {
        ["Robot"] = "616087089",
        ["Patrol"] = "1148863382",
        ["Adidas Community"] = "98600215928904",
        ["Levitation"] = "616005863",
        ["Catwalk Glam"] = "92294537340807",
        ["Knight"] = "10921122579",
        ["Pirate"] = "750780242",
        ["Bold"] = "16738333171",
        ["Sports (Adidas)"] = "18537367238",
        ["Zombie"] = "616157476",
        ["Astronaut"] = "891617961",
        ["Cartoony"] = "742637151",
        ["Ninja"] = "656115606",
        ["Confident"] = "1069973677",
        ["Wicked 'Dancing Through Life'"] = "78147885297412",
        ["Unboxed By Amazon"] = "94788218468396",
        ["R6"] = "12520972571",
        ["[UGC] skydiving"] = "102674302534126",
        ["R15 Reanimated"] = "4211216152",
        ["Rthro"] = "10921262864",
        ["No Boundaries (Walmart)"] = "18747062535",
        ["Werewolf"] = "1083189019",
        ["[VOTE] TPose"] = "139027266704971",
        ["Mage"] = "707829716",
        ["[VOTE] Animal"] = "77069224396280",
        ["Wicked (Popular)"] = "121152442762481",
        ["Popstar"] = "1212900995",
        ["NFL"] = "129773241321032",
        ["OldSchool"] = "10921241244",
        ["Sneaky"] = "1132469004",
        ["Elder"] = "10921105765",
        ["Bubbly"] = "910001910",
        ["Stylish"] = "616134815",
        ["Stylized Female"] = "4708186162",
        ["Vampire"] = "1083443587",
        ["Superhero"] = "10921293373",
        ["Toy"] = "782846423",
        ["Default Retarget"] = "110205622518029",
        ["Princess"] = "941000007",
        ["Cowboy"] = "1014384571"
    },
    ["SwimIdle"] = {
        ["Sneaky"] = "1132506407",
        ["SuperHero"] = "10921297391",
        ["Adidas Community"] = "109346520324160",
        ["Levitation"] = "10921139478",
        ["Catwalk Glam"] = "98854111361360",
        ["Knight"] = "10921125935",
        ["Pirate"] = "750785176",
        ["Bold"] = "16738339817",
        ["Sports (Adidas)"] = "18537387180",
        ["Stylized"] = "4708190607",
        ["Astronaut"] = "891663592",
        ["Cartoony"] = "10921079380",
        ["Wicked (Popular)"] = "113199415118199",
        ["Mage"] = "707894699",
        ["Wicked 'Dancing Through Life'"] = "129183123083281",
        ["Unboxed By Amazon"] = "129126268464847",
        ["R6"] = "12518152696",
        ["Rthro"] = "10921265698",
        ["CowBoy"] = "1014411816",
        ["No Boundaries (Walmart)"] = "18747071682",
        ["Werewolf"] = "10921341319",
        ["NFL"] = "79090109939093",
        ["OldSchool"] = "10921244018",
        ["Robot"] = "10921253767",
        ["Elder"] = "10921110146",
        ["Bubbly"] = "910030921",
        ["Patrol"] = "1151221899",
        ["Vampire"] = "10921325443",
        ["Popstar"] = "1212998578",
        ["Ninja"] = "656118341",
        ["Toy"] = "10921310341",
        ["Confident"] = "1070012133",
        ["Princess"] = "941025398",
        ["Stylish"] = "10921281964"
    },
    ["Swim"] = {
        ["Sneaky"] = "1132500520",
        ["Patrol"] = "1151204998",
        ["Adidas Community"] = "133308483266208",
        ["Levitation"] = "10921138209",
        ["Catwalk Glam"] = "134591743181628",
        ["Knight"] = "10921125160",
        ["Pirate"] = "750784579",
        ["Bold"] = "16738339158",
        ["Sports (Adidas)"] = "18537389531",
        ["Zombie"] = "616165109",
        ["Astronaut"] = "891663592",
        ["Cartoony"] = "10921079380",
        ["Wicked (Popular)"] = "99384245425157",
        ["Mage"] = "707876443",
        ["PopStar"] = "1212998578",
        ["Unboxed By Amazon"] = "105962919001086",
        ["R6"] = "12518152696",
        ["[VOTE] Boat"] = "85689117221382",
        ["Rthro"] = "10921264784",
        ["CowBoy"] = "1014406523",
        ["No Boundaries (Walmart)"] = "18747073181",
        ["Werewolf"] = "10921340419",
        ["NFL"] = "132697394189921",
        ["OldSchool"] = "10921243048",
        ["Wicked 'Dancing Through Life'"] = "110657013921774",
        ["Elder"] = "10921108971",
        ["Bubbly"] = "910028158",
        ["Robot"] = "10921253142",
        ["[VOTE] Aura"] = "80645586378736",
        ["Vampire"] = "10921324408",
        ["Stylish"] = "10921281000",
        ["Toy"] = "10921309319",
        ["SuperHero"] = "10921295495",
        ["Princess"] = "941018893",
        ["Confident"] = "1070009914"
    },
    ["Climb"] = {
        ["Robot"] = "616086039",
        ["Patrol"] = "1148811837",
        ["Adidas Community"] = "88763136693023",
        ["Levitation"] = "10921132092",
        ["Catwalk Glam"] = "119377220967554",
        ["Knight"] = "10921125160",
        ["[VOTE] Animal"] = "124810859712282",
        ["Bold"] = "16738332169",
        ["Sports (Adidas)"] = "18537363391",
        ["Zombie"] = "616156119",
        ["Astronaut"] = "10921032124",
        ["Cartoony"] = "742636889",
        ["Ninja"] = "656114359",
        ["Confident"] = "1069946257",
        ["Wicked 'Dancing Through Life'"] = "129447497744818",
        ["Unboxed By Amazon"] = "121145883950231",
        ["R6"] = "12520982150",
        ["Ghost"] = "616003713",
        ["Rthro"] = "10921257536",
        ["CowBoy"] = "1014380606",
        ["No Boundaries (Walmart)"] = "18747060903",
        ["Mage"] = "707826056",
        ["[VOTE] sticky"] = "77520617871799",
        ["Reanimated R15"] = "4211214992",
        ["Popstar"] = "1213044953",
        ["(UGC) Retro"] = "121075390792786",
        ["NFL"] = "134630013742019",
        ["OldSchool"] = "10921229866",
        ["Sneaky"] = "1132461372",
        ["Elder"] = "845392038",
        ["Stylized Female"] = "4708184253",
        ["Stylish"] = "10921271391",
        ["SuperHero"] = "10921286911",
        ["WereWolf"] = "10921329322",
        ["Vampire"] = "1083439238",
        ["Toy"] = "10921300839",
        ["Wicked (Popular)"] = "131326830509784",
        ["Princess"] = "940996062",
        ["[VOTE] Rope"] = "134977367563514"
    }
}

-- Load saved animations or use defaults
Animations = {}

-- Always update with the latest complete animation list
pcall(function() writefile("OnyxAnimations.json", HttpService:JSONEncode(OriginalAnimations)) end)
Animations = OriginalAnimations
SendNotify("Animations", "Loaded complete animation database", 3)

-- Track last applied animations
lastAnimations = {}
pcall(function()
    if isfile("OnyxLastAnims.json") then
        local data = readfile("OnyxLastAnims.json")
        lastAnimations = HttpService:JSONDecode(data)
    end
end)

-- Animation Helper Functions
local function StopAnim()
    local Char = plr.Character or plr.CharacterAdded:Wait()
    local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")
    if Hum then
        for _, track in ipairs(Hum:GetPlayingAnimationTracks()) do
            track:Stop(0)
        end
    end
end

local function refreshState(state)
    local character = plr.Character
    if not character then return end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    if state == "swim" then
        humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
    elseif state == "climb" then
        humanoid:ChangeState(Enum.HumanoidStateType.Climbing)
    else
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end

local function freeze()
    if plr and plr.Character then
        local humanoid = plr.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.PlatformStand = true
        end
        task.spawn(function()
            for i, part in ipairs(plr.Character:GetDescendants()) do
                if part:IsA("BasePart") and not part.Anchored then
                    part.Anchored = true
                end
            end
        end)
    end
end

local function unfreeze()
    if plr and plr.Character then
        local humanoid = plr.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
        end
        task.spawn(function()
            for i, part in ipairs(plr.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Anchored then
                    part.Anchored = false
                end
            end
        end)
    end
end

-- Roblox locks AnimationId on Animate's children in newer engine versions.
-- Neither direct assignment nor sethiddenproperty can write it.
-- Solution: DESTROY the locked Animation object and CREATE a new one with the
-- desired AnimationId. Instance.new is never property-locked.
-- The Animate script detects the new child by name and uses it normally.
base = "http://www.roblox.com/asset/?id="

local function replaceAnim(parent, childName, id)
    -- parent  = e.g. Animate.walk
    -- childName = e.g. "WalkAnim"
    -- id      = numeric string like "507766388"
    if not parent or not id then return end
    local full = base .. tostring(id)

    -- Try fastest path first: direct write
    local existing = parent:FindFirstChild(childName)
    if existing then
        local ok = pcall(function() existing.AnimationId = full end)
        if ok then return end
        -- Direct write blocked — try sethiddenproperty
        if sethiddenproperty then
            ok = pcall(sethiddenproperty, existing, "AnimationId", full)
            if ok then return end
        end
        -- Both blocked — destroy the locked object and replace it
        pcall(function() existing:Destroy() end)
    end

    -- Create a fresh Animation with the target ID (never property-locked)
    local newAnim = Instance.new("Animation")
    newAnim.Name        = childName
    newAnim.AnimationId = full
    newAnim.Parent      = parent
end

local function nudgeState(Hum)
    if not Hum then return end
    local s = Hum:GetState()
    if s == Enum.HumanoidStateType.Swimming then
        refreshState("swim")
    elseif s == Enum.HumanoidStateType.Climbing then
        refreshState("climb")
    else
        Hum:ChangeState(Enum.HumanoidStateType.Running)
        task.wait(0.05)
        Hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end

local function stopAllTracks(Hum, Animator)
    if Hum then
        for _, t in ipairs(Hum:GetPlayingAnimationTracks()) do pcall(function() t:Stop(0) end) end
    end
    if Animator then
        for _, t in ipairs(Animator:GetPlayingAnimationTracks()) do pcall(function() t:Stop(0) end) end
    end
end

local function ResetAnimation(animType)
    local Char = plr.Character
    if not Char then return end
    local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")
    for _, v in next, Hum:GetPlayingAnimationTracks() do v:Stop(0) end
    local Animate = Char:FindFirstChild("Animate")
    if not Animate then return end
    if animType == "Idle" then
        replaceAnim(Animate:FindFirstChild("idle"), "Animation1", "0")
        replaceAnim(Animate:FindFirstChild("idle"), "Animation2", "0")
    elseif animType == "Walk"     then replaceAnim(Animate:FindFirstChild("walk"),     "WalkAnim",  "0")
    elseif animType == "Run"      then replaceAnim(Animate:FindFirstChild("run"),      "RunAnim",   "0")
    elseif animType == "Jump"     then replaceAnim(Animate:FindFirstChild("jump"),     "JumpAnim",  "0")
    elseif animType == "Fall"     then replaceAnim(Animate:FindFirstChild("fall"),     "FallAnim",  "0")
    elseif animType == "Swim"     then replaceAnim(Animate:FindFirstChild("swim"),     "Swim",      "0")
    elseif animType == "SwimIdle" then replaceAnim(Animate:FindFirstChild("swimidle"), "SwimIdle",  "0")
    elseif animType == "Climb"    then replaceAnim(Animate:FindFirstChild("climb"),    "ClimbAnim", "0")
    end
end

-- Main animation setter
function setAnimation(animationType, animationId)
    if type(animationId) ~= "table" and type(animationId) ~= "string" then return end
    if not plr.Character then return end

    local Char    = plr.Character
    local Animate = Char:FindFirstChild("Animate")
    if not Animate then return end

    local Hum      = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")
    local Animator = Hum and Hum:FindFirstChildOfClass("Animator")

    -- Save and inject the target animation
    if animationType == "Idle" then
        lastAnimations.Idle = animationId
        replaceAnim(Animate:FindFirstChild("idle"), "Animation1", animationId[1])
        replaceAnim(Animate:FindFirstChild("idle"), "Animation2", animationId[2])
    elseif animationType == "Walk" then
        lastAnimations.Walk = animationId
        replaceAnim(Animate:FindFirstChild("walk"), "WalkAnim", animationId)
    elseif animationType == "Run" then
        lastAnimations.Run = animationId
        replaceAnim(Animate:FindFirstChild("run"), "RunAnim", animationId)
    elseif animationType == "Jump" then
        lastAnimations.Jump = animationId
        replaceAnim(Animate:FindFirstChild("jump"), "JumpAnim", animationId)
    elseif animationType == "Fall" then
        lastAnimations.Fall = animationId
        replaceAnim(Animate:FindFirstChild("fall"), "FallAnim", animationId)
    elseif animationType == "Swim" then
        lastAnimations.Swim = animationId
        replaceAnim(Animate:FindFirstChild("swim"), "Swim", animationId)
    elseif animationType == "SwimIdle" then
        lastAnimations.SwimIdle = animationId
        replaceAnim(Animate:FindFirstChild("swimidle"), "SwimIdle", animationId)
    elseif animationType == "Climb" then
        lastAnimations.Climb = animationId
        replaceAnim(Animate:FindFirstChild("climb"), "ClimbAnim", animationId)
    end

    -- Re-apply all other saved anims so nothing reverts on next state cycle
    if lastAnimations.Idle then
        replaceAnim(Animate:FindFirstChild("idle"), "Animation1", lastAnimations.Idle[1])
        replaceAnim(Animate:FindFirstChild("idle"), "Animation2", lastAnimations.Idle[2])
    end
    if lastAnimations.Walk     then replaceAnim(Animate:FindFirstChild("walk"),     "WalkAnim",  lastAnimations.Walk)     end
    if lastAnimations.Run      then replaceAnim(Animate:FindFirstChild("run"),      "RunAnim",   lastAnimations.Run)      end
    if lastAnimations.Jump     then replaceAnim(Animate:FindFirstChild("jump"),     "JumpAnim",  lastAnimations.Jump)     end
    if lastAnimations.Fall     then replaceAnim(Animate:FindFirstChild("fall"),     "FallAnim",  lastAnimations.Fall)     end
    if lastAnimations.Climb    then replaceAnim(Animate:FindFirstChild("climb"),    "ClimbAnim", lastAnimations.Climb)    end
    if lastAnimations.Swim     then replaceAnim(Animate:FindFirstChild("swim"),     "Swim",      lastAnimations.Swim)     end
    if lastAnimations.SwimIdle then replaceAnim(Animate:FindFirstChild("swimidle"), "SwimIdle",  lastAnimations.SwimIdle) end

    pcall(function() writefile("OnyxLastAnims.json", HttpService:JSONEncode(lastAnimations)) end)

    -- Stop cached tracks so Animate reloads from the new Animation objects
    stopAllTracks(Hum, Animator)

    -- Nudge humanoid state so the new animation plays immediately
    task.wait(0.05)
    nudgeState(Hum)
end

-- Batch-apply a full animations table in one pass
local function applyAnimationsBatch(anims)
    if not plr.Character then return end
    local Char = plr.Character
    local Animate = Char:FindFirstChild("Animate")
    if not Animate then return end

    local Hum      = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")
    local Animator = Hum and Hum:FindFirstChildOfClass("Animator")

    if anims.Idle then
        replaceAnim(Animate:FindFirstChild("idle"), "Animation1", anims.Idle[1])
        replaceAnim(Animate:FindFirstChild("idle"), "Animation2", anims.Idle[2])
    end
    if anims.Walk     then replaceAnim(Animate:FindFirstChild("walk"),     "WalkAnim",  anims.Walk)     end
    if anims.Run      then replaceAnim(Animate:FindFirstChild("run"),      "RunAnim",   anims.Run)      end
    if anims.Jump     then replaceAnim(Animate:FindFirstChild("jump"),     "JumpAnim",  anims.Jump)     end
    if anims.Fall     then replaceAnim(Animate:FindFirstChild("fall"),     "FallAnim",  anims.Fall)     end
    if anims.Climb    then replaceAnim(Animate:FindFirstChild("climb"),    "ClimbAnim", anims.Climb)    end
    if anims.Swim     then replaceAnim(Animate:FindFirstChild("swim"),     "Swim",      anims.Swim)     end
    if anims.SwimIdle then replaceAnim(Animate:FindFirstChild("swimidle"), "SwimIdle",  anims.SwimIdle) end

    stopAllTracks(Hum, Animator)
    task.wait(0.05)
    nudgeState(Hum)
end

-- Load last animations on startup
local function loadLastAnimations()
    if not pcall(function() return isfile end) then return end
    if isfile("OnyxLastAnims.json") then
        local ok, data = pcall(readfile, "OnyxLastAnims.json")
        if not ok or not data then return end
        local lastAnimationsData = HttpService:JSONDecode(data)
        -- Merge into lastAnimations so CharacterAdded respawn handler also has it
        for k, v in pairs(lastAnimationsData) do
            lastAnimations[k] = v
        end
        SendNotify("Animations", "Restoring saved animations", 3)
        task.wait(1) -- Wait for character to load
        applyAnimationsBatch(lastAnimationsData)
    end
end

-- Re-apply animations on respawn
plr.CharacterAdded:Connect(function(character)
    local hum = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 10)
    if not hum then return end
    local animate = character:WaitForChild("Animate", 10)
    if not animate then return end
    task.wait(0.5)
    applyAnimationsBatch(lastAnimations)
end)

-- Populate animation buttons
animButtons = {}

local function CreateAnimationButton(animName, animType, animId)
    local button = Instance.new("TextButton")
    button.Name = animName .. "_" .. animType
    button.Parent = AnimScrollFrame
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    button.BackgroundTransparency = 0.8
    button.BorderSizePixel = 0
    button.Size = UDim2.new(1, -10, 0, 35)
    button.Font = Enum.Font.Gotham
    button.Text = animName .. " - " .. animType
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 11
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.ZIndex = 5
    button.AutoButtonColor = false
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button
    
    local padding = Instance.new("UIPadding")
    padding.Parent = button
    padding.PaddingLeft = UDim.new(0, 10)
    
    -- Hover effect
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundTransparency = 0.6}):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundTransparency = 0.8}):Play()
    end)
    
    -- Click to apply animation
    button.MouseButton1Click:Connect(function()
        setAnimation(animType, animId)
        SendNotify("Animation", animName .. " applied", 2)
    end)
    
    table.insert(animButtons, button)
end

-- Populate all animations
local function PopulateAnimations()
    -- Clear existing buttons
    for _, btn in ipairs(animButtons) do
        if btn and btn.Parent then btn:Destroy() end
    end
    animButtons = {}
    
    local typeOrder = {"Idle", "Walk", "Run", "Jump", "Fall", "Swim", "SwimIdle", "Climb"}
    
    for _, animType in ipairs(typeOrder) do
        local anims = Animations[animType]
        if anims then
            for name, ids in pairs(anims) do
                CreateAnimationButton(name, animType, ids)
            end
        end
    end
end

-- Search functionality for animations
AnimSearchBar:GetPropertyChangedSignal("Text"):Connect(function()
    local searchText = AnimSearchBar.Text:lower()
    for _, button in ipairs(animButtons) do
        if searchText == "" or button.Text:lower():find(searchText) then
            button.Visible = true
        else
            button.Visible = false
        end
    end
end)

-- Initial population
PopulateAnimations()

-- Load animations after a short delay
task.delay(1, loadLastAnimations)

-- =====================================================
-- EMOTE MENU SYSTEM (Full Database + Per-Emote Keybinds + Speed)
-- =====================================================
do -- scope block: all emote locals are contained here

-- State
local currentEmoteTrack  = nil
local currentEmoteSpeed  = 1.0
local selectedEmoteId    = nil
local selectedEmoteName  = nil
local emoteMenuVisible   = false
local emoteListenTarget  = nil
local emoteKeybinds      = {}
local favoritedEmotes = {}
local emoteButtons       = {}
local allEmotes          = {}
local emotesLoaded       = false
listeningKeyBtn    = nil
local isDraggingSpeed    = false
local EMOTE_JSON_URL     = "https://raw.githubusercontent.com/7yd7/sniper-Emote/refs/heads/test/EmoteSniper.json"
local EMOTE_CACHE        = "OnyxEmotes.json"

-- Load saved keybinds
do
    local ok, decoded = pcall(function()
        if not isfile("OnyxEmoteBinds.json") then return nil end
        return HttpService:JSONDecode(readfile("OnyxEmoteBinds.json"))
    end)
    if ok and type(decoded) == "table" then
        emoteKeybinds = decoded
    end
end

local function SaveKeybinds()
    local toSave = {}
    for id, data in pairs(emoteKeybinds) do
        toSave[id] = data.key and data.key.Name or nil
    end
    pcall(function() writefile("OnyxEmoteBinds.json", HttpService:JSONEncode(toSave)) end)
end

-- Load saved favorites
do
    local ok, decoded = pcall(function()
        if not isfile("OnyxEmoteFavorites.json") then return nil end
        return HttpService:JSONDecode(readfile("OnyxEmoteFavorites.json"))
    end)
    if ok and type(decoded) == "table" then
        favoritedEmotes = decoded
    end
end

local function SaveFavorites()
    pcall(function() 
        writefile("OnyxEmoteFavorites.json", HttpService:JSONEncode(favoritedEmotes)) 
    end)
end

local function ToggleFavorite(emoteId)
    local id = tostring(emoteId)
    if favoritedEmotes[id] then
        favoritedEmotes[id] = nil
    else
        favoritedEmotes[id] = true
    end
    SaveFavorites()
end

local function IsFavorited(emoteId)
    return favoritedEmotes[tostring(emoteId)] == true
end

-- local EmoteMenu, NowPlayingLabel, StopEmoteBtn, EmoteMenuClose
-- local SpeedLabel, SpeedTrack, SpeedFill, SpeedHandle, SpeedValueBox
-- local EmoteListFrame, EmoteCountLabel, LoadingLabel, EmoteSearch

local function BuildEmoteUI()
    local menu = Instance.new("Frame")
    menu.Name               = "EmoteMenu"
    menu.Parent             = OnyxUI
    menu.BackgroundColor3   = Color3.fromRGB(15, 15, 25)
    menu.BackgroundTransparency = 0.3
    menu.BorderSizePixel    = 0
    menu.Position           = UDim2.new(0.5, 200, 0.5, 0)
    menu.Size               = UDim2.new(0, 340, 0, 510)
    menu.Visible            = false
    menu.Active             = true
    menu.ZIndex             = 30
    menu.ClipsDescendants   = true
    do
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 16); c.Parent = menu
        local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255, 255, 255)
        s.Transparency = 0.8; s.Thickness = 1; s.Parent = menu
    end

    -- Add this code right after EmoteSearch is created:

local favFilterBtn = Instance.new("TextButton")
favFilterBtn.Name = "FavoritesFilter"
favFilterBtn.Parent = menu
favFilterBtn.BackgroundColor3 = Color3.fromRGB(255,255,255)
favFilterBtn.BackgroundTransparency = 0.9
favFilterBtn.BorderSizePixel = 0
favFilterBtn.Position = UDim2.new(0, 15, 0, 170)
favFilterBtn.Size = UDim2.new(0, 100, 0, 28)
favFilterBtn.Font = Enum.Font.GothamBold
favFilterBtn.Text = "⭐ Favorites"
favFilterBtn.TextColor3 = Color3.fromRGB(200,200,220)
favFilterBtn.TextSize = 11
favFilterBtn.ZIndex = 31
favFilterBtn.AutoButtonColor = false
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = favFilterBtn
    local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255,220,100)
    s.Transparency = 0.7; s.Thickness = 1; s.Parent = favFilterBtn
end

local showingFavorites = false

favFilterBtn.MouseButton1Click:Connect(function()
    showingFavorites = not showingFavorites
    
    if showingFavorites then
        -- Show only favorites
        favFilterBtn.BackgroundTransparency = 0.3
        favFilterBtn.BackgroundColor3 = Color3.fromRGB(255,220,100)
        favFilterBtn.TextColor3 = Color3.fromRGB(50,50,70)
        
        visibleEmotes = {}
        for _, e in ipairs(allEmotes) do
            if IsFavorited(e.id) then
                table.insert(visibleEmotes, e)
            end
        end
        
        if #visibleEmotes == 0 then
            SendNotify("⭐ Favorites", "No favorites yet! Click ☆ to add emotes", 3)
        end
    else
        -- Show all emotes
        favFilterBtn.BackgroundTransparency = 0.9
        favFilterBtn.BackgroundColor3 = Color3.fromRGB(255,255,255)
        favFilterBtn.TextColor3 = Color3.fromRGB(200,200,220)
        
        RebuildVisible(EmoteSearch.Text)
        return
    end
    
    local totalH = VPAD * 2 + #visibleEmotes * VROW_H
    EmoteListFrame.CanvasSize = UDim2.new(0, 0, 0, totalH)
    EmoteListFrame.CanvasPosition = Vector2.new(0, 0)
    RefreshVirtualRows()
end)

    local titleBar = Instance.new("Frame")
    titleBar.Name = "EmoteTitleBar"; titleBar.Parent = menu
    titleBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    titleBar.BackgroundTransparency = 0.95; titleBar.BorderSizePixel = 0
    titleBar.Size = UDim2.new(1, 0, 0, 40); titleBar.ZIndex = 31; titleBar.Active = true
    do
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 16); c.Parent = titleBar
        local t = Instance.new("TextLabel"); t.Parent = titleBar
        t.BackgroundTransparency = 1; t.Position = UDim2.new(0, 15, 0, 0)
        t.Size = UDim2.new(1, -100, 1, 0); t.Font = Enum.Font.GothamBold
        t.Text = "🎭 Emote Menu"; t.TextColor3 = Color3.fromRGB(255, 255, 255)
        t.TextSize = 16; t.TextXAlignment = Enum.TextXAlignment.Left; t.ZIndex = 32
    end

    local countLbl = Instance.new("TextLabel"); countLbl.Parent = titleBar
    countLbl.BackgroundTransparency = 1; countLbl.AnchorPoint = Vector2.new(1, 0.5)
    countLbl.Position = UDim2.new(1, -78, 0.5, 0); countLbl.Size = UDim2.new(0, 60, 0, 20)
    countLbl.Font = Enum.Font.Gotham; countLbl.Text = "Loading..."
    countLbl.TextColor3 = Color3.fromRGB(130, 130, 160); countLbl.TextSize = 10
    countLbl.TextXAlignment = Enum.TextXAlignment.Right; countLbl.ZIndex = 32

    -- Close + Minimize (Anti-VC style)
    local closeBtn = Instance.new("TextButton"); closeBtn.Parent = titleBar
    closeBtn.Name = "CloseBtn"
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80); closeBtn.BackgroundTransparency = 0.3
    closeBtn.BorderSizePixel = 0; closeBtn.AnchorPoint = Vector2.new(1, 0.5)
    closeBtn.Position = UDim2.new(1, -10, 0.5, 0); closeBtn.Size = UDim2.new(0, 25, 0, 25)
    closeBtn.Font = Enum.Font.GothamBold; closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255); closeBtn.TextSize = 18
    closeBtn.ZIndex = 32; closeBtn.AutoButtonColor = false
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = closeBtn end

    local minimizeBtn = Instance.new("TextButton"); minimizeBtn.Parent = titleBar
    minimizeBtn.Name = "MinimizeBtn"
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255); minimizeBtn.BackgroundTransparency = 0.9
    minimizeBtn.BorderSizePixel = 0; minimizeBtn.AnchorPoint = Vector2.new(1, 0.5)
    minimizeBtn.Position = UDim2.new(1, -45, 0.5, 0); minimizeBtn.Size = UDim2.new(0, 25, 0, 25)
    minimizeBtn.Font = Enum.Font.GothamBold; minimizeBtn.Text = "−"
    minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255); minimizeBtn.TextSize = 18
    minimizeBtn.ZIndex = 32; minimizeBtn.AutoButtonColor = false
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = minimizeBtn end

    -- Minimize logic (Anti-VC style: Quad tween to 40px height)
    local emoteMinimized = false
    local fullSize = UDim2.new(0, 340, 0, 510)
    local miniSize = UDim2.new(0, 340, 0, 40)
    minimizeBtn.MouseButton1Click:Connect(function()
        emoteMinimized = not emoteMinimized
        local ti = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(menu, ti, {Size = emoteMinimized and miniSize or fullSize}):Play()
        minimizeBtn.Text = emoteMinimized and "+" or "−"
    end)

    do
        local emDragging, emDragInput, emDragStart, emStartPos
        local function emUpdate(input)
            local d = input.Position - emDragStart
            menu.Position = UDim2.new(emStartPos.X.Scale, emStartPos.X.Offset + d.X,
                                      emStartPos.Y.Scale, emStartPos.Y.Offset + d.Y)
        end
        titleBar.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                emDragging = true; emDragStart = inp.Position; emStartPos = menu.Position
                inp.Changed:Connect(function() if inp.UserInputState == Enum.UserInputState.End then emDragging = false end end)
            end
        end)
        titleBar.InputChanged:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                emDragInput = inp
            end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if inp == emDragInput and emDragging then emUpdate(inp) end
        end)
    end

    local body = Instance.new("Frame"); body.Parent = menu
    body.BackgroundTransparency = 1; body.Position = UDim2.new(0, 0, 0, 40)
    body.Size = UDim2.new(1, 0, 1, -40); body.ZIndex = 31
    do
        local l = Instance.new("UIListLayout"); l.Parent = body
        l.SortOrder = Enum.SortOrder.LayoutOrder; l.Padding = UDim.new(0, 5)
        local p = Instance.new("UIPadding"); p.Parent = body
        p.PaddingTop = UDim.new(0, 8); p.PaddingLeft = UDim.new(0, 10)
        p.PaddingRight = UDim.new(0, 10); p.PaddingBottom = UDim.new(0, 8)
    end

    -- Search
    local search = Instance.new("TextBox"); search.Parent = body
    search.BackgroundColor3 = Color3.fromRGB(255, 255, 255); search.BackgroundTransparency = 0.9
    search.BorderSizePixel = 0; search.Size = UDim2.new(1, 0, 0, 32)
    search.Font = Enum.Font.GothamMedium; search.PlaceholderText = "🔍  Search emotes..."
    search.PlaceholderColor3 = Color3.fromRGB(140, 140, 160); search.Text = ""
    search.TextColor3 = Color3.fromRGB(220, 220, 235); search.TextSize = 12
    search.ZIndex = 32; search.ClearTextOnFocus = false; search.LayoutOrder = 1
    do
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 7); c.Parent = search
        local p = Instance.new("UIPadding"); p.Parent = search; p.PaddingLeft = UDim.new(0, 10)
    end

    -- Now-playing bar
    local npBar = Instance.new("Frame"); npBar.Parent = body
    npBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255); npBar.BackgroundTransparency = 0.93
    npBar.BorderSizePixel = 0; npBar.Size = UDim2.new(1, 0, 0, 28)
    npBar.ZIndex = 32; npBar.LayoutOrder = 2
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = npBar end

    local npLabel = Instance.new("TextLabel"); npLabel.Parent = npBar
    npLabel.BackgroundTransparency = 1; npLabel.Position = UDim2.new(0, 8, 0, 0)
    npLabel.Size = UDim2.new(1, -72, 1, 0); npLabel.Font = Enum.Font.Gotham
    npLabel.Text = "▶  No emote playing"; npLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
    npLabel.TextSize = 11; npLabel.TextXAlignment = Enum.TextXAlignment.Left
    npLabel.TextTruncate = Enum.TextTruncate.AtEnd; npLabel.ZIndex = 33

    local stopBtn = Instance.new("TextButton"); stopBtn.Parent = npBar
    stopBtn.AnchorPoint = Vector2.new(1, 0.5); stopBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
    stopBtn.BackgroundTransparency = 0.3; stopBtn.BorderSizePixel = 0
    stopBtn.Position = UDim2.new(1, -6, 0.5, 0); stopBtn.Size = UDim2.new(0, 58, 0, 20)
    stopBtn.Font = Enum.Font.GothamBold; stopBtn.Text = "■  Stop"
    stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255); stopBtn.TextSize = 10
    stopBtn.ZIndex = 33; stopBtn.AutoButtonColor = false
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 5); c.Parent = stopBtn end

    -- Speed row
    local speedRow = Instance.new("Frame"); speedRow.Parent = body
    speedRow.BackgroundTransparency = 1; speedRow.Size = UDim2.new(1, 0, 0, 28)
    speedRow.ZIndex = 32; speedRow.LayoutOrder = 3

    local speedLbl = Instance.new("TextLabel"); speedLbl.Parent = speedRow
    speedLbl.BackgroundTransparency = 1; speedLbl.Size = UDim2.new(0, 100, 1, 0)
    speedLbl.Font = Enum.Font.GothamMedium; speedLbl.Text = "⚡ Speed: 1.0x"
    speedLbl.TextColor3 = Color3.fromRGB(200, 200, 220); speedLbl.TextSize = 11
    speedLbl.TextXAlignment = Enum.TextXAlignment.Left; speedLbl.ZIndex = 33

    local speedTrack = Instance.new("Frame"); speedTrack.Parent = speedRow
    speedTrack.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    speedTrack.BackgroundTransparency = 0.88; speedTrack.BorderSizePixel = 0
    speedTrack.Position = UDim2.new(0, 105, 0.5, -5); speedTrack.Size = UDim2.new(1, -150, 0, 10)
    speedTrack.ZIndex = 33
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = speedTrack end

    local speedFill = Instance.new("Frame"); speedFill.Parent = speedTrack
    speedFill.BackgroundColor3 = Color3.fromRGB(120, 180, 255); speedFill.BackgroundTransparency = 0.1
    speedFill.BorderSizePixel = 0; speedFill.Size = UDim2.new(0.231, 0, 1, 0); speedFill.ZIndex = 34
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = speedFill end

    local speedHandle = Instance.new("Frame"); speedHandle.Parent = speedTrack
    speedHandle.AnchorPoint = Vector2.new(0.5, 0.5)
    speedHandle.BackgroundColor3 = Color3.fromRGB(255, 255, 255); speedHandle.BackgroundTransparency = 0.1
    speedHandle.BorderSizePixel = 0; speedHandle.Position = UDim2.new(0.231, 0, 0.5, 0)
    speedHandle.Size = UDim2.new(0, 14, 0, 14); speedHandle.ZIndex = 35
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = speedHandle end

    local speedValBox = Instance.new("TextBox"); speedValBox.Parent = speedRow
    speedValBox.AnchorPoint = Vector2.new(1, 0.5)
    speedValBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255); speedValBox.BackgroundTransparency = 0.88
    speedValBox.BorderSizePixel = 0; speedValBox.Position = UDim2.new(1, 0, 0.5, 0)
    speedValBox.Size = UDim2.new(0, 40, 0, 22); speedValBox.Font = Enum.Font.GothamBold
    speedValBox.Text = "1.0"; speedValBox.TextColor3 = Color3.fromRGB(200, 200, 220)
    speedValBox.TextSize = 10; speedValBox.ZIndex = 33; speedValBox.ClearTextOnFocus = false
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 5); c.Parent = speedValBox end

    -- Hint
    local hint = Instance.new("TextLabel"); hint.Parent = body
    hint.BackgroundTransparency = 1; hint.Size = UDim2.new(1, 0, 0, 14)
    hint.Font = Enum.Font.Gotham
    hint.Text = "Click [+] to bind key  |  Click bound key to unbind"
    hint.TextColor3 = Color3.fromRGB(100, 100, 130); hint.TextSize = 10
    hint.TextXAlignment = Enum.TextXAlignment.Left; hint.ZIndex = 32; hint.LayoutOrder = 4

    -- Emote list
    local listFrame = Instance.new("ScrollingFrame"); listFrame.Parent = body
    listFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255); listFrame.BackgroundTransparency = 0.95
    listFrame.BorderSizePixel = 0; listFrame.Size = UDim2.new(1, 0, 1, -120)
    listFrame.ScrollBarThickness = 4; listFrame.ScrollBarImageColor3 = Color3.fromRGB(160, 160, 255)
    listFrame.ScrollBarImageTransparency = 0.5; listFrame.ZIndex = 32
    listFrame.CanvasSize = UDim2.new(0, 0, 0, 0); listFrame.LayoutOrder = 5
    listFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 7); c.Parent = listFrame end

    local loadingLbl = Instance.new("TextLabel"); loadingLbl.Parent = listFrame
    loadingLbl.BackgroundTransparency = 1; loadingLbl.Size = UDim2.new(1, 0, 0, 40)
    loadingLbl.Font = Enum.Font.GothamMedium; loadingLbl.Text = "⏳ Loading emotes..."
    loadingLbl.TextColor3 = Color3.fromRGB(160, 160, 190); loadingLbl.TextSize = 13; loadingLbl.ZIndex = 33

    -- Assign to outer locals via upvalue
    EmoteMenu       = menu
    EmoteCountLabel = countLbl
    EmoteMenuClose  = closeBtn
    NowPlayingLabel = npLabel
    StopEmoteBtn    = stopBtn
    SpeedLabel      = speedLbl
    SpeedTrack      = speedTrack
    SpeedFill       = speedFill
    SpeedHandle     = speedHandle
    SpeedValueBox   = speedValBox
    EmoteSearch     = search
    EmoteListFrame  = listFrame
    LoadingLabel    = loadingLbl
end

BuildEmoteUI()

local RefreshVirtualRows  -- forward declaration, defined later in virtual scroll section

local function StopCurrentEmote()
    if currentEmoteTrack then
        pcall(function() currentEmoteTrack:Stop(0) end)
        currentEmoteTrack = nil
    end
    selectedEmoteId   = nil
    selectedEmoteName = nil
    NowPlayingLabel.Text = "▶  No emote playing"

    local char = plr.Character
    if char then
        -- Re-enable the Animate script
        local animate = char:FindFirstChild("Animate")
        if animate then
            pcall(function()
                pcall(function() animate.Disabled = false end)
                -- Restore idle if we have saved anims
                if lastAnimations and lastAnimations.Idle and animate:FindFirstChild("idle") then
                    local ids = lastAnimations.Idle
                    local base2 = "http://www.roblox.com/asset/?id="
                    local function restoreOne(parent, name, id)
                        local full = base2 .. id
                        local ex = parent:FindFirstChild(name)
                        if ex then
                            local ok = pcall(function() ex.AnimationId = full end)
                            if not ok then pcall(function() ex:Destroy() end) end
                        end
                        if not parent:FindFirstChild(name) then
                            local a = Instance.new("Animation"); a.Name = name; a.AnimationId = full; a.Parent = parent
                        end
                    end
                    restoreOne(animate.idle, "Animation1", ids[1])
                    restoreOne(animate.idle, "Animation2", ids[2])
                end
            end)
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        end
    end
    if RefreshVirtualRows then RefreshVirtualRows() end
end

local function PlayEmoteById(emoteId, emoteName)
    local idStr = tostring(emoteId):gsub("%.0$", "")

    -- Toggle: same emote → stop
    if selectedEmoteId and tostring(selectedEmoteId):gsub("%.0$", "") == idStr then
        StopCurrentEmote()
        return
    end

    -- Clear previous
    if currentEmoteTrack then
        pcall(function() currentEmoteTrack:Stop(0) end)
        currentEmoteTrack = nil
    end
    selectedEmoteId   = emoteId
    selectedEmoteName = emoteName
    NowPlayingLabel.Text = "▶  " .. emoteName

    local char = plr.Character
    if not char then SendNotify("Emotes","No character",2) return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then SendNotify("Emotes","No Humanoid",2) return end
    if hum.RigType ~= Enum.HumanoidRigType.R15 then
        SendNotify("Emotes","R15 required for emotes!",3) return
    end

    task.spawn(function()
        -- Step 1: Disable the Animate script so it stops controlling animations
        local animate = char:FindFirstChild("Animate")
        if animate then
            pcall(function() animate.Disabled = true end)
        end
        task.wait(0.05)

        -- Step 2: Stop all currently playing tracks
        local animator = hum:FindFirstChildOfClass("Animator")
        if not animator then
            -- Re-enable Animate and bail if no Animator found
            if animate then pcall(function() animate.Disabled = false end) end
            SendNotify("Emotes","Animator not found",2)
            return
        end
        for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
            pcall(function() t:Stop(0) end)
        end

        -- Step 3: Verify we're still playing this emote (user may have changed)
        if tostring(selectedEmoteId):gsub("%.0$","") ~= idStr then return end

        -- Step 4: Load animation via game:GetObjects() which bypasses sanitization.
        -- GetObjects fetches the real Animation asset from Roblox and inserts it
        -- into the DataModel - the Animator then accepts it as a trusted asset.
        local anim, track
        local getOk, fetched = pcall(function()
            local objs = game:GetObjects("rbxassetid://" .. idStr)
            if objs and objs[1] and objs[1]:IsA("Animation") then
                -- Check if engine sanitized it immediately
                local currentId = objs[1].AnimationId
                if currentId == "" or currentId == "rbxassetid://0" or currentId:match("id=0") then
                    return nil
                end
                return objs[1]
            end
        end)
        
        if getOk and fetched then
            anim = fetched
            pcall(function() anim.Parent = workspace end)
        else
            -- Fallback: plain Animation instance
            anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://" .. idStr
            
            -- If it was immediately sanitized upon assignment, try alternative URL format
            if anim.AnimationId == "rbxassetid://0" or anim.AnimationId == "" then
                anim.AnimationId = "http://www.roblox.com/asset/?id=" .. idStr
            end
        end

        -- Final security check before passing to LoadAnimation
        if anim.AnimationId == "rbxassetid://0" or anim.AnimationId == "" or anim.AnimationId:match("id=0") then
            if animate then pcall(function() animate.Disabled = false end) end
            SendNotify("Emotes","Executor does not support custom animations",3)
            selectedEmoteId   = nil
            selectedEmoteName = nil
            NowPlayingLabel.Text = "▶  No emote playing"
            if RefreshVirtualRows then RefreshVirtualRows() end
            pcall(function() if anim then anim:Destroy() end end)
            return
        end

        local ok
        ok, track = pcall(function() return animator:LoadAnimation(anim) end)
        -- Clean up from workspace if we parented it there
        pcall(function()
            if anim and anim.Parent == workspace then anim:Destroy() end
        end)

        if not ok or not track then
            -- Re-enable Animate and report failure
            if animate then pcall(function() animate.Disabled = false end) end
            SendNotify("Emotes","Failed to load: " .. emoteName,2)
            selectedEmoteId   = nil
            selectedEmoteName = nil
            NowPlayingLabel.Text = "▶  No emote playing"
            if RefreshVirtualRows then RefreshVirtualRows() end
            return
        end

        -- Verify still our emote
        if tostring(selectedEmoteId):gsub("%.0$","") ~= idStr then
            pcall(function() track:Stop(0) end)
            return
        end

        track.Priority = Enum.AnimationPriority.Action4
        track.Looped   = true
        track:Play(0)
        track:AdjustSpeed(currentEmoteSpeed)
        currentEmoteTrack = track

        track.Stopped:Connect(function()
            if currentEmoteTrack == track then
                currentEmoteTrack = nil
                selectedEmoteId   = nil
                selectedEmoteName = nil
                NowPlayingLabel.Text = "▶  No emote playing"
                -- Re-enable Animate when track naturally ends
                if animate then pcall(function() animate.Disabled = false end) end
                if RefreshVirtualRows then RefreshVirtualRows() end
            end
        end)

        if RefreshVirtualRows then RefreshVirtualRows() end
    end)

    if RefreshVirtualRows then RefreshVirtualRows() end
    SendNotify("Emotes","Playing: " .. emoteName, 2)
end

local function ApplySpeed(fraction)
    fraction = math.clamp(fraction, 0, 1)
    local speed = math.floor((0.1 + fraction * 3.9) * 10 + 0.5) / 10
    currentEmoteSpeed    = speed
    SpeedFill.Size       = UDim2.new(fraction, 0, 1, 0)
    SpeedHandle.Position = UDim2.new(fraction, 0, 0.5, 0)
    SpeedLabel.Text      = "⚡ Speed: " .. string.format("%.1f", speed) .. "x"
    SpeedValueBox.Text   = string.format("%.1f", speed)
    if currentEmoteTrack then pcall(function() currentEmoteTrack:AdjustSpeed(speed) end) end
end

ApplySpeed(0.9 / 3.9)

SpeedTrack.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        isDraggingSpeed = true
        ApplySpeed((inp.Position.X - SpeedTrack.AbsolutePosition.X) / SpeedTrack.AbsoluteSize.X)
    end
end)
SpeedTrack.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then isDraggingSpeed = false end
end)
UserInputService.InputChanged:Connect(function(inp)
    if isDraggingSpeed and inp.UserInputType == Enum.UserInputType.MouseMovement then
        ApplySpeed((inp.Position.X - SpeedTrack.AbsolutePosition.X) / SpeedTrack.AbsoluteSize.X)
    end
end)
SpeedValueBox.FocusLost:Connect(function()
    local v = tonumber(SpeedValueBox.Text)
    if v then ApplySpeed((math.clamp(v,0.1,4.0)-0.1)/3.9)
    else SpeedValueBox.Text = string.format("%.1f", currentEmoteSpeed) end
end)

local function CancelListening()
    if listeningKeyBtn then
        -- find what emote this btn is currently bound to via emoteListenTarget
        local id = emoteListenTarget and emoteListenTarget.id
        local bound = id and emoteKeybinds[tostring(id)]
        listeningKeyBtn.Text             = bound and ("[" .. bound.key.Name .. "]") or "[+]"
        listeningKeyBtn.BackgroundColor3 = bound and Color3.fromRGB(50,80,140) or Color3.fromRGB(50,50,75)
        listeningKeyBtn.TextColor3       = bound and Color3.fromRGB(200,220,255) or Color3.fromRGB(140,140,170)
        listeningKeyBtn = nil
    end
    emoteListenTarget = nil
end

local function BindKey(keyCode)
    if not emoteListenTarget then return end
    local id   = emoteListenTarget.id
    local name = emoteListenTarget.name
    local btn  = emoteListenTarget.keyBtn
    for existId, data in pairs(emoteKeybinds) do
        if data.key == keyCode and existId ~= tostring(id) then
            data.key = nil
            if data.btn and data.btn.Parent then
                data.btn.Text = "[+]"; data.btn.BackgroundColor3 = Color3.fromRGB(50,50,75)
                data.btn.TextColor3 = Color3.fromRGB(140,140,170)
            end
        end
    end
    emoteKeybinds[tostring(id)] = { key = keyCode, btn = btn }
    btn.Text = "[" .. keyCode.Name .. "]"
    btn.BackgroundColor3 = Color3.fromRGB(50,80,140)
    btn.TextColor3 = Color3.fromRGB(200,220,255)
    listeningKeyBtn = nil; emoteListenTarget = nil
    SaveKeybinds()
    SendNotify("Emotes", keyCode.Name .. " → " .. name, 2)
end

local function UnbindEmote(id, btn)
    emoteKeybinds[tostring(id)] = nil
    btn.Text = "[+]"; btn.BackgroundColor3 = Color3.fromRGB(50,50,75)
    btn.TextColor3 = Color3.fromRGB(140,140,170)
    SaveKeybinds()
end

-- VIRTUAL SCROLL SYSTEM - renders only visible rows (no lag)

VROW_H     = 34   -- px per row including gap
VPAD       = 5    -- top/bottom padding inside list
VPOOL_SIZE = 22   -- number of reusable row widgets (> visible rows)

visibleEmotes  = {}  -- filtered subset currently shown
vPool          = {}  -- reusable row widgets
vFirstIdx      = 0   -- index of topmost rendered row in visibleEmotes

-- Build the reusable row pool (done ONCE, no lag)
local function BuildRowPool()
    for i = 1, VPOOL_SIZE do
        local row = Instance.new("Frame")
        row.Name = "VRow"..i; row.Parent = EmoteListFrame
        row.BackgroundTransparency = 1
        row.Size = UDim2.new(1, -10, 0, VROW_H - 4)
        row.Position = UDim2.new(0, 5, 0, 0)
        row.ZIndex = 33; row.Visible = false

        local playBtn = Instance.new("TextButton"); playBtn.Parent = row
        playBtn.BackgroundColor3 = Color3.fromRGB(255,255,255)
        playBtn.BackgroundTransparency = 0.93; playBtn.BorderSizePixel = 0
        playBtn.Size = UDim2.new(1,-52,1,0)
        playBtn.Font = Enum.Font.GothamMedium; playBtn.Text = ""
        playBtn.TextColor3 = Color3.fromRGB(215,215,235); playBtn.TextSize = 11
        playBtn.TextXAlignment = Enum.TextXAlignment.Left
        playBtn.TextTruncate = Enum.TextTruncate.AtEnd
        playBtn.ZIndex = 34; playBtn.AutoButtonColor = false
        do
            local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,5); c.Parent = playBtn
            local p = Instance.new("UIPadding"); p.Parent = playBtn; p.PaddingLeft = UDim.new(0,8)
        end

        local keyBtn = Instance.new("TextButton"); keyBtn.Parent = row
        keyBtn.BackgroundColor3 = Color3.fromRGB(50,50,75)
        keyBtn.BackgroundTransparency = 0.2; keyBtn.BorderSizePixel = 0
        keyBtn.Position = UDim2.new(1,-50,0,0)
        keyBtn.Size = UDim2.new(0,46,1,0); keyBtn.Font = Enum.Font.GothamBold
        keyBtn.Text = "[+]"; keyBtn.TextColor3 = Color3.fromRGB(140,140,170)
        keyBtn.TextSize = 9; keyBtn.ZIndex = 34; keyBtn.AutoButtonColor = false
        do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,5); c.Parent = keyBtn end

        -- Hover effects
        playBtn.MouseEnter:Connect(function()
            if row.Visible then playBtn.BackgroundTransparency = 0.72 end
        end)
        playBtn.MouseLeave:Connect(function()
            playBtn.BackgroundTransparency = 0.93
        end)
        playBtn.MouseButton1Down:Connect(function()
            if row.Visible then playBtn.BackgroundTransparency = 0.5 end
        end)

        -- Clicks read the emote bound to THIS widget at click time
        playBtn.MouseButton1Click:Connect(function()
            local emote = row:GetAttribute("BoundEmoteId")
            local name  = row:GetAttribute("BoundEmoteName")
            if emote and name then
                PlayEmoteById(emote, name)
                task.defer(function() if RefreshVirtualRows then RefreshVirtualRows() end end)
            end
        end)

        keyBtn.MouseButton1Click:Connect(function()
            local emote = row:GetAttribute("BoundEmoteId")
            local name  = row:GetAttribute("BoundEmoteName")
            if not emote then return end
            if emoteKeybinds[emote] and listeningKeyBtn ~= keyBtn then
                UnbindEmote(emote, keyBtn)
                -- refresh display
                local bound = emoteKeybinds[emote]
                keyBtn.Text = bound and ("["..bound.key.Name.."]") or "[+]"
                keyBtn.BackgroundColor3 = bound and Color3.fromRGB(50,80,140) or Color3.fromRGB(50,50,75)
                keyBtn.TextColor3 = bound and Color3.fromRGB(200,220,255) or Color3.fromRGB(140,140,170)
                return
            end
            if listeningKeyBtn then CancelListening() end
            listeningKeyBtn = keyBtn
            emoteListenTarget = {id=emote, name=name, keyBtn=keyBtn}
            keyBtn.Text = "[ ? ]"; keyBtn.BackgroundColor3 = Color3.fromRGB(220,120,20)
            keyBtn.TextColor3 = Color3.fromRGB(255,255,255)
        end)

        vPool[i] = {row=row, playBtn=playBtn, keyBtn=keyBtn}
    end
end

-- Bind a pool widget to an emote entry
local function BindRowToEmote(widget, emote, yPos)
    local row = widget.row
    row:SetAttribute("BoundEmoteId",   emote.id)
    row:SetAttribute("BoundEmoteName", emote.name)
    row.Position = UDim2.new(0, 5, 0, yPos)
    row.Visible  = true

    local isPlaying = selectedEmoteId and tostring(selectedEmoteId):gsub("%.0$","") == tostring(emote.id):gsub("%.0$","")
    widget.playBtn.Text = (isPlaying and "■  " or "") .. emote.name
    widget.playBtn.BackgroundTransparency = isPlaying and 0.6 or 0.93
    widget.playBtn.TextColor3 = isPlaying and Color3.fromRGB(120, 220, 120) or Color3.fromRGB(215,215,235)

    local bound = emoteKeybinds[tostring(emote.id)]
    widget.keyBtn.Text = bound and ("["..bound.key.Name.."]") or "[+]"
    widget.keyBtn.BackgroundColor3 = bound and Color3.fromRGB(50,80,140) or Color3.fromRGB(50,50,75)
    widget.keyBtn.TextColor3 = bound and Color3.fromRGB(200,220,255) or Color3.fromRGB(140,140,170)

    -- NEW: Update favorite button state
    local isFav = IsFavorited(emote.id)
    widget.favBtn.Text = isFav and "★" or "☆"
    widget.favBtn.TextColor3 = isFav and Color3.fromRGB(255,220,100) or Color3.fromRGB(200,180,100)

    if bound then emoteKeybinds[tostring(emote.id)].btn = widget.keyBtn end
end

-- Refresh which rows are visible based on scroll position
RefreshVirtualRows = function()
    local scrollY    = EmoteListFrame.CanvasPosition.Y
    local listH      = EmoteListFrame.AbsoluteSize.Y
    local startIdx   = math.max(1, math.floor((scrollY - VPAD) / VROW_H))
    local endIdx     = math.min(#visibleEmotes, startIdx + VPOOL_SIZE - 1)

    -- hide all first
    for _, w in ipairs(vPool) do w.row.Visible = false end

    -- show visible range
    local poolIdx = 1
    for i = startIdx, endIdx do
        if poolIdx > VPOOL_SIZE then break end
        local yPos = VPAD + (i - 1) * VROW_H
        BindRowToEmote(vPool[poolIdx], visibleEmotes[i], yPos)
        poolIdx = poolIdx + 1
    end
    vFirstIdx = startIdx
end

-- Call RefreshVirtualRows when scroll moves
EmoteListFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(RefreshVirtualRows)

-- Rebuild visibleEmotes from search term and refresh
local function RebuildVisible(term)
    visibleEmotes = {}
    if term == "" then
        visibleEmotes = allEmotes
    else
        term = term:lower()
        for _, e in ipairs(allEmotes) do
            if e.name:lower():find(term, 1, true) then
                table.insert(visibleEmotes, e)
            end
        end
    end
    local totalH = VPAD * 2 + #visibleEmotes * VROW_H
    EmoteListFrame.CanvasSize = UDim2.new(0, 0, 0, totalH)
    EmoteListFrame.CanvasPosition = Vector2.new(0, 0)
    RefreshVirtualRows()
end

-- Search connects to virtual rebuild
EmoteSearch:GetPropertyChangedSignal("Text"):Connect(function()
    RebuildVisible(EmoteSearch.Text)
end)

local function PopulateEmoteList(emoteList)
    pcall(function() LoadingLabel:Destroy() end)
    allEmotes = emoteList
    EmoteCountLabel.Text = tostring(#allEmotes) .. " emotes"
    -- Normalize keybinds
    local restoredBinds = {}
    for idStr, v in pairs(emoteKeybinds) do
        idStr = tostring(idStr):gsub("%.0$","")
        if type(v) == "string" then
            local ok, kc = pcall(function() return Enum.KeyCode[v] end)
            if ok and kc then restoredBinds[idStr] = {key=kc, btn=nil} end
        elseif type(v) == "table" and v.key then
            restoredBinds[idStr] = v
        end
    end
    emoteKeybinds = restoredBinds
    -- Build the fixed pool of widgets (fast, only ~22 instances)
    BuildRowPool()
    task.spawn(function()
        local total = #allEmotes
        local chunkSize = 50
        visibleEmotes = {}
        
        for i = 1, total, chunkSize do
            local endIdx = math.min(i + chunkSize - 1, total)
            for j = i, endIdx do
                table.insert(visibleEmotes, allEmotes[j])
            end
            
            -- Update UI every chunk so users can scroll as it loads
            local totalH = VPAD * 2 + #visibleEmotes * VROW_H
            EmoteListFrame.CanvasSize = UDim2.new(0, 0, 0, totalH)
            RefreshVirtualRows()
            
            task.wait(0.05) -- Small delay between chunks to prevent frame drops
        end
        
        emotesLoaded = true
        SendNotify("Emotes", tostring(#allEmotes) .. " emotes loaded!", 3)
    end)
end

local function LoadEmoteDatabase()
    EmoteCountLabel.Text = "Loading..."
    task.spawn(function()
        local raw = nil
        -- Try the standard cache file first
        local cacheFiles = {EMOTE_CACHE, "Onyx_emotes.lua", "OnyxEmotes.lua", "emotes.json"}
        for _, fname in ipairs(cacheFiles) do
            if isfile(fname) then
                local ok, data = pcall(readfile, fname)
                if ok and data and #data > 100 then
                    raw = data
                    -- If loaded from an alternate file, save it as the standard cache
                    if fname ~= EMOTE_CACHE then
                        pcall(function() writefile(EMOTE_CACHE, raw) end)
                    end
                    break
                end
            end
        end
        if not raw then
            local ok, result = pcall(function() return game:HttpGet(EMOTE_JSON_URL) end)
            if ok and result and #result > 100 then
                raw = result
                pcall(function() writefile(EMOTE_CACHE, raw) end)
            else
                EmoteCountLabel.Text = "Load failed"
                SendNotify("Emotes","Failed to fetch emote database — put Onyx_emotes.lua in your workspace folder",5)
                pcall(function() LoadingLabel.Text = "❌ Failed to load. Place Onyx_emotes.lua in your executor workspace." end)
                return
            end
        end
        local ok, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
        if not ok or not decoded or not decoded.data then
            EmoteCountLabel.Text = "Parse error"
            pcall(function() LoadingLabel.Text = "❌ Failed to parse emote data." end)
            return
        end
        -- Normalize all IDs to strings to avoid float precision loss
        for _, entry in ipairs(decoded.data) do
            entry.id = tostring(entry.id)
            -- Strip any trailing .0 that JSON decoding may add
            entry.id = entry.id:gsub("%.0$", "")
        end
        PopulateEmoteList(decoded.data)
    end)
end

StopEmoteBtn.MouseButton1Click:Connect(function()
    StopCurrentEmote()
    RefreshVirtualRows()
end)

EmoteMenuClose.MouseButton1Click:Connect(function()
    emoteMenuVisible = false; EmoteMenu.Visible = false; CancelListening()
end)

local function ToggleEmoteMenu()
    emoteMenuVisible = not emoteMenuVisible
    EmoteMenu.Visible = emoteMenuVisible
    if emoteMenuVisible and not emotesLoaded then LoadEmoteDatabase() end
end

EmotesButton.MouseButton1Click:Connect(ToggleEmoteMenu)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if emoteListenTarget then
        if input.KeyCode == Enum.KeyCode.Escape then CancelListening()
        else BindKey(input.KeyCode) end
        return
    end
    if gameProcessed then return end
    for emoteIdStr, data in pairs(emoteKeybinds) do
        if data.key and data.key == input.KeyCode then
            -- Toggle: if this emote is already playing, stop it
            if selectedEmoteId and tostring(selectedEmoteId):gsub("%.0$","") == emoteIdStr then
                StopCurrentEmote()
                RefreshVirtualRows()
            else
                for _, emote in ipairs(allEmotes) do
                    if tostring(emote.id):gsub("%.0$","") == emoteIdStr then
                        PlayEmoteById(emote.id, emote.name)
                        task.defer(function() if RefreshVirtualRows then RefreshVirtualRows() end end)
                        break
                    end
                end
            end
            break
        end
    end
end)

plr.CharacterAdded:Connect(function(char)
    currentEmoteTrack = nil
    selectedEmoteId   = nil
    selectedEmoteName = nil
    NowPlayingLabel.Text = "▶  No emote playing"
    -- Make sure Animate is re-enabled if we died during an emote
    local animate = char:FindFirstChild("Animate") or char:WaitForChild("Animate", 5)
    if animate then pcall(function() animate.Disabled = false end) end
    task.defer(function() if RefreshVirtualRows then RefreshVirtualRows() end end)
end)

end -- end emote scope block

-- =====================================================
-- CLICK TELEPORT SYSTEM
-- =====================================================

ClickTeleportEnabled = false

-- Click Teleport Toggle
ClickTeleportButton.MouseButton1Click:Connect(function()
    ClickTeleportEnabled = not ClickTeleportEnabled
    
    if ClickTeleportEnabled then
        ClickTeleportButton.Text = "📍 Click Teleport (F): ON"
        ClickTeleportButton.BackgroundTransparency = 0.7
        SendNotify("Click Teleport", "Enabled - Press F to teleport to mouse", 3)
    else
        ClickTeleportButton.Text = "📍 Click Teleport (F): OFF"
        ClickTeleportButton.BackgroundTransparency = 0.9
        SendNotify("Click Teleport", "Disabled", 2)
    end
end)

-- Click Teleport Input Handler
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F and ClickTeleportEnabled then
        local character = plr.Character
        if not character then return end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end
        
        -- Raycast from mouse position
        local mouseLocation = mouse.Hit.Position
        
        -- Teleport player
        humanoidRootPart.CFrame = CFrame.new(mouseLocation + Vector3.new(0, 3, 0))
        
        -- Visual feedback
        local teleportEffect = Instance.new("Part")
        teleportEffect.Anchored = true
        teleportEffect.CanCollide = false
        teleportEffect.Size = Vector3.new(5, 0.2, 5)
        teleportEffect.CFrame = CFrame.new(mouseLocation)
        teleportEffect.Material = Enum.Material.Neon
        teleportEffect.BrickColor = BrickColor.new("Cyan")
        teleportEffect.Transparency = 0.5
        teleportEffect.Parent = workspace
        
        task.spawn(function()
            for i = 1, 10 do
                teleportEffect.Transparency = teleportEffect.Transparency + 0.05
                teleportEffect.Size = teleportEffect.Size + Vector3.new(0.5, 0, 0.5)
                teleportEffect.CFrame = CFrame.new(mouseLocation)
                task.wait(0.05)
            end
            teleportEffect:Destroy()
        end)
    end
end)

-- =====================================================
-- INFINITE BASEPLATE SYSTEM
-- =====================================================

InfiniteBaseplateEnabled = false
baseplateClones = {}
originalBaseplate = nil
checkDistance = 50
gridSize = 512

-- Function to find the original baseplate
local function FindBaseplate()
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Part") and obj.Name:lower():find("baseplate") then
            return obj
        end
    end
    return nil
end

-- Function to create baseplate clone
local function CreateBaseplateClone(position, original)
    local clone = Instance.new("Part")
    clone.Size = original.Size
    clone.CFrame = CFrame.new(position)
    clone.Material = original.Material
    clone.BrickColor = original.BrickColor
    clone.Color = original.Color
    clone.Transparency = original.Transparency
    clone.Reflectance = original.Reflectance
    clone.TopSurface = original.TopSurface
    clone.BottomSurface = original.BottomSurface
    clone.Anchored = true
    clone.CanCollide = true
    clone.Name = "InfiniteBaseplateClone"
    clone.Parent = workspace
    
    -- Copy texture if it exists
    local texture = original:FindFirstChildOfClass("Texture")
    if texture then
        local newTexture = texture:Clone()
        newTexture.Parent = clone
    end
    
    return clone
end

-- Function to update baseplates around player
local function UpdateBaseplates()
    if not InfiniteBaseplateEnabled or not originalBaseplate then return end
    
    local character = plr.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local playerPos = humanoidRootPart.Position
    local baseY = originalBaseplate.Position.Y
    
    -- Calculate grid position
    local gridX = math.floor(playerPos.X / gridSize) * gridSize
    local gridZ = math.floor(playerPos.Z / gridSize) * gridSize
    
    -- Check if we need new baseplates
    local neededPositions = {}
    for x = -1, 1 do
        for z = -1, 1 do
            local pos = Vector3.new(gridX + (x * gridSize), baseY, gridZ + (z * gridSize))
            table.insert(neededPositions, pos)
        end
    end
    
    -- Remove far baseplates
    for i = #baseplateClones, 1, -1 do
        local clone = baseplateClones[i]
        if clone and clone.Parent then
            local distance = (clone.Position - playerPos).Magnitude
            if distance > gridSize * 2 then
                clone:Destroy()
                table.remove(baseplateClones, i)
            end
        else
            table.remove(baseplateClones, i)
        end
    end
    
    -- Add new baseplates
    for _, pos in ipairs(neededPositions) do
        local exists = false
        
        -- Check if baseplate already exists at this position
        for _, clone in ipairs(baseplateClones) do
            if clone and clone.Parent then
                local diff = (clone.Position - pos).Magnitude
                if diff < 10 then
                    exists = true
                    break
                end
            end
        end
        
        -- Check if it's the original baseplate position
        local diffFromOriginal = (originalBaseplate.Position - pos).Magnitude
        if diffFromOriginal < 10 then
            exists = true
        end
        
        if not exists then
            local newClone = CreateBaseplateClone(pos, originalBaseplate)
            table.insert(baseplateClones, newClone)
        end
    end
end

-- Infinite Baseplate Toggle
InfiniteBaseplateButton.MouseButton1Click:Connect(function()
    InfiniteBaseplateEnabled = not InfiniteBaseplateEnabled
    
    if InfiniteBaseplateEnabled then
        originalBaseplate = FindBaseplate()
        
        if originalBaseplate then
            InfiniteBaseplateButton.Text = "🟦 Infinite Baseplate: ON"
            InfiniteBaseplateButton.BackgroundTransparency = 0.7
            SendNotify("Infinite Baseplate", "Enabled - Baseplate will extend as you move", 3)
            
            -- Initial generation
            UpdateBaseplates()
        else
            InfiniteBaseplateEnabled = false
            SendNotify("Error", "No baseplate found in workspace", 3)
        end
    else
        InfiniteBaseplateButton.Text = "🟦 Infinite Baseplate: OFF"
        InfiniteBaseplateButton.BackgroundTransparency = 0.9
        SendNotify("Infinite Baseplate", "Disabled", 2)
        
        -- Clean up all clones
        for _, clone in ipairs(baseplateClones) do
            if clone and clone.Parent then
                clone:Destroy()
            end
        end
        baseplateClones = {}
    end
end)

-- Update baseplates continuously (throttled - no need to run every frame)
do
    local lastBaseplateUpdate = 0
    RunService.Heartbeat:Connect(function()
        if not InfiniteBaseplateEnabled then return end
        if not UserInputService.WindowFocused then return end
        local now = tick()
        if now - lastBaseplateUpdate < 0.5 then return end
        lastBaseplateUpdate = now
        UpdateBaseplates()
    end)
end

-- =====================================================
-- SHADERS SYSTEM (via loadstring)
-- =====================================================

-- Shaders Button Click (loads external script)
ShadersButton.MouseButton1Click:Connect(function()
    SendNotify("Shaders", "Loading shaders script...", 2)
    
    -- Load the shaders script via loadstring
    local success, errorMsg = pcall(function()
        -- Replace this URL with your actual shader script URL
        loadstring(game:HttpGet("https://raw.githubusercontent.com/randomstring0/pshade-ultimate/refs/heads/main/src/cd.lua"))()
    end)
    
    if success then
        SendNotify("Shaders", "Script loaded successfully!", 3)
    else
        SendNotify("Shaders Error", "Failed to load: " .. tostring(errorMsg), 5)
    end
end)

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  LOGIC — ESP SYSTEM                                          ║
-- ╚══════════════════════════════════════════════════════════════╝
-- =====================================================
-- ESP SYSTEM
-- =====================================================

ESPEnabled = false
espObjects = {}

-- ESP Toggle
ESPButton.MouseButton1Click:Connect(function()
    ESPEnabled = not ESPEnabled
    
    if ESPEnabled then
        ESPButton.Text = "👁️ ESP: ON"
        ESPButton.BackgroundTransparency = 0.7
        SendNotify("ESP", "Enabled - Showing all players", 3)
    else
        ESPButton.Text = "👁️ ESP: OFF"
        ESPButton.BackgroundTransparency = 0.9
        SendNotify("ESP", "Disabled", 2)
        
        -- Clean up all ESP objects
        for _, espData in pairs(espObjects) do
            if espData.box then espData.box:Destroy() end
            if espData.nameLabel then espData.nameLabel:Destroy() end
            if espData.distanceLabel then espData.distanceLabel:Destroy() end
            if espData.healthBar then espData.healthBar:Destroy() end
        end
        espObjects = {}
    end
end)

-- =====================================================
-- ╔══════════════════════════════════════════════════════════════╗
-- ║  LOGIC — UTILITY SYSTEMS (Anti-Void, Player Hide/Mute)       ║
-- ╚══════════════════════════════════════════════════════════════╝
-- UTILITY SYSTEMS (Anti-Void, Player Hiding)
-- =====================================================

AntiVoidEnabled = false

HiddenPlayers = {}

-- ── Audio mute: Wire destruction method ────────────────────────────────────
-- Roblox new audio pipeline: AudioDeviceInput → Wire → AudioEmitter
-- Setting Volume/Muted on endpoints does NOTHING while a Wire actively feeds them.
-- Destroying the Wire locally breaks the pipeline on our client. That's the fix.
-- We store destroyed Wires' data so we can recreate them on unhide.

-- [userId] = { wires = { {parent, name, src, tgt} }, sounds = { {sound, vol} } }
local hiddenAudioData = {}

local function mutePlayerAudio(userId)
    local p = Players:GetPlayerByUserId(userId)
    if not p then return end

    -- Don't double-process
    if hiddenAudioData[userId] then return end

    local data = { wires = {}, sounds = {} }
    hiddenAudioData[userId] = data

    -- Method 1: FIXED - Only destroy wires connected to THIS player's character
    local function nukeWiresIn(container)
        if not container then return end
        pcall(function()
            for _, v in ipairs(container:GetDescendants()) do
                if v:IsA("Wire") then
                    local ok, src = pcall(function() return v.SourceInstance end)
                    local ok2, tgt = pcall(function() return v.TargetInstance end)
                    if ok and ok2 then
                        -- FIX: Check if the wire belongs to this specific player
                        local belongsToTarget = false
                        
                        -- Check if source or target is in the player's character
                        if src then
                            local srcAncestor = src:FindFirstAncestorOfClass("Model")
                            if srcAncestor == p.Character then
                                belongsToTarget = true
                            end
                        end
                        
                        if tgt and not belongsToTarget then
                            local tgtAncestor = tgt:FindFirstAncestorOfClass("Model")
                            if tgtAncestor == p.Character then
                                belongsToTarget = true
                            end
                        end
                        
                        -- Only destroy if it belongs to THIS player
                        if belongsToTarget then
                            local srcIsAudio = src and (src:IsA("AudioDeviceInput") or src:IsA("AudioEmitter") or src:IsA("AudioPlayer") or src:IsA("AudioCompressor") or src:IsA("AudioEcho"))
                            local tgtIsAudio = tgt and (tgt:IsA("AudioEmitter") or tgt:IsA("AudioDeviceInput") or tgt:IsA("AudioPlayer") or tgt:IsA("AudioCompressor"))
                            
                            if srcIsAudio or tgtIsAudio then
                                -- Save wire info for restoration
                                table.insert(data.wires, {
                                    parent = v.Parent,
                                    name   = v.Name,
                                    src    = src,
                                    tgt    = tgt,
                                })
                                pcall(function() v:Destroy() end)
                            end
                        end
                    end
                end
            end
        end)
    end

    -- Only search in the player's character, not all of workspace
    nukeWiresIn(p.Character)

    -- Method 2: Zero all Sound objects in THIS player's character only
    if p.Character then
        for _, v in ipairs(p.Character:GetDescendants()) do
            if v:IsA("Sound") then
                local ok, vol = pcall(function() return v.Volume end)
                if ok then
                    table.insert(data.sounds, { sound = v, vol = vol })
                    pcall(function() v.Volume = 0; v:Stop() end)
                end
            end
            -- Also zero AudioEmitter volume
            if v:IsA("AudioEmitter") then
                pcall(function() v.Volume = 0 end)
            end
        end
    end

    -- Method 3: VoiceChatInternal participant mute (ONLY this player)
    if VoiceChatInternal then
        pcall(function() VoiceChatInternal:MuteParticipant(tostring(userId), true) end)
        pcall(function() VoiceChatInternal:MutePlayer(userId) end)
    end
end

local function unmutePlayerAudio(userId)
    local data = hiddenAudioData[userId]
    hiddenAudioData[userId] = nil

    local p = Players:GetPlayerByUserId(userId)
    if not p then return end

    -- Restore Wires: recreate each destroyed wire with original endpoints
    if data then
        -- IMPROVED: Try multiple times to restore wires
        for attempt = 1, 3 do
            for _, w in ipairs(data.wires) do
                pcall(function()
                    if w.src and w.tgt and w.src.Parent and w.tgt.Parent then
                        -- Check if wire already exists
                        local wireExists = false
                        if w.parent and w.parent.Parent then
                            for _, existingWire in ipairs(w.parent:GetChildren()) do
                                if existingWire:IsA("Wire") then
                                    local ok1, eSrc = pcall(function() return existingWire.SourceInstance end)
                                    local ok2, eTgt = pcall(function() return existingWire.TargetInstance end)
                                    if ok1 and ok2 and eSrc == w.src and eTgt == w.tgt then
                                        wireExists = true
                                        break
                                    end
                                end
                            end
                        end
                        
                        -- Only create if it doesn't exist
                        if not wireExists and w.parent and w.parent.Parent then
                            local wire = Instance.new("Wire")
                            wire.Name           = w.name
                            wire.SourceInstance = w.src
                            wire.TargetInstance = w.tgt
                            wire.Parent         = w.parent
                        end
                    end
                end)
            end
            
            if attempt < 3 then
                task.wait(0.1) -- Wait between attempts
            end
        end
        
        -- Restore Sound volumes
        for _, s in ipairs(data.sounds) do
            pcall(function()
                if s.sound and s.sound.Parent then
                    s.sound.Volume = s.vol
                    s.sound:Play() -- Restart sounds
                end
            end)
        end
        
        -- Restore AudioEmitter volumes from saved data
        for _, e in ipairs(data.emitters) do
            pcall(function()
                if e.emitter and e.emitter.Parent then
                    e.emitter.Volume = e.vol
                end
            end)
        end
    end

    -- Restore AudioEmitter volumes (fallback to default 1)
    if p.Character then
        for _, v in ipairs(p.Character:GetDescendants()) do
            if v:IsA("AudioEmitter") then
                pcall(function()
                    if v.Volume == 0 then
                        v.Volume = 1
                    end
                end)
            end
        end
    end

    -- Un-mute VoiceChatInternal
    if VoiceChatInternal then
        pcall(function() VoiceChatInternal:MuteParticipant(tostring(userId), false) end)
        pcall(function() VoiceChatInternal:UnmutePlayer(userId) end)
    end
    
    -- EXTRA FIX: Force rejoin voice chat for this player to refresh audio
    task.delay(0.5, function()
        if VoiceChatInternal then
            pcall(function()
                -- This forces the player's audio to reinitialize
                local groupId = VoiceChatInternal:GetGroupId()
                if groupId then
                    VoiceChatInternal:UnmutePlayer(userId)
                end
            end)
        end
    end)
end

local function applyHideToChar(char, userId)
    if not char then return end

    -- Visual suppression
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            pcall(function() v.LocalTransparencyModifier = 1 end)
            pcall(function() v.Transparency = 1 end)
        elseif v:IsA("Decal") or v:IsA("Texture") then
            pcall(function() v.Transparency = 1 end)
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Light") or v:IsA("SelectionBox") then
            pcall(function() v.Enabled = false end)
        elseif v:IsA("BillboardGui") or v:IsA("SurfaceGui") or v:IsA("ScreenGui") then
            pcall(function() v.Enabled = false end)
        elseif v:IsA("SpecialMesh") or v:IsA("BlockMesh") then
            pcall(function() v.Scale = Vector3.zero end)
        end
    end

    -- Audio suppression (dedicated function above)
    mutePlayerAudio(userId)
end

local function applyUnhideToChar(char, userId)
    if not char then return end

    -- Visual restoration
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            pcall(function() v.LocalTransparencyModifier = 0 end)
            if v.Name ~= "HumanoidRootPart" then
                pcall(function() v.Transparency = 0 end)
            end
        elseif v:IsA("Decal") or v:IsA("Texture") then
            pcall(function() v.Transparency = 0 end)
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Light") then
            pcall(function() v.Enabled = true end)
        elseif v:IsA("BillboardGui") or v:IsA("SurfaceGui") then
            pcall(function() v.Enabled = true end)
        end
    end

    -- Audio restoration (dedicated function)
    unmutePlayerAudio(userId)
end

local _chatFilterInstalled = false
local function installChatFilter()
    if _chatFilterInstalled then return end
    _chatFilterInstalled = true
    pcall(function()
        local TCS = game:GetService("TextChatService")
        local channels = TCS and TCS:FindFirstChild("TextChannels")
        if not channels then return end
        for _, ch in ipairs(channels:GetChildren()) do
            if ch:IsA("TextChannel") then
                pcall(function()
                    ch.ShouldDeliverCallback = function(msgObj, txSource)
                        if txSource and txSource.UserId == plr.UserId then return true end
                        if txSource and HiddenPlayers[txSource.UserId] then return false end
                        return true
                    end
                end)
            end
        end
        channels.ChildAdded:Connect(function(ch)
            if ch:IsA("TextChannel") then
                task.wait(0.1)
                pcall(function()
                    ch.ShouldDeliverCallback = function(msgObj, txSource)
                        if txSource and txSource.UserId == plr.UserId then return true end
                        if txSource and HiddenPlayers[txSource.UserId] then return false end
                        return true
                    end
                end)
            end
        end)
    end)
end

local function removeChatFilter()
    pcall(function()
        local TCS = game:GetService("TextChatService")
        local channels = TCS and TCS:FindFirstChild("TextChannels")
        if not channels then return end
        for _, ch in ipairs(channels:GetChildren()) do
            if ch:IsA("TextChannel") then
                pcall(function() ch.ShouldDeliverCallback = nil end)
            end
        end
    end)
    _chatFilterInstalled = false
end

local function hidePlayer(target)
    if not target then return end
    local uid = target.UserId
    if HiddenPlayers[uid] then return end -- already hidden

    installChatFilter()

    local entry = { respawnConn = nil }
    HiddenPlayers[uid] = entry

    applyHideToChar(target.Character, uid)

    entry.respawnConn = target.CharacterAdded:Connect(function(char)
        if not HiddenPlayers[uid] then return end
        task.wait(0.1) -- let the character fully load first
        applyHideToChar(char, uid)
    end)

    SendNotify("👻 Hide", target.DisplayName .. " completely hidden", 2)
end

local function unhidePlayer(target)
    if not target then return end
    local uid = target.UserId
    local entry = HiddenPlayers[uid]
    if not entry then return end

    HiddenPlayers[uid] = nil

    if entry.respawnConn then
        pcall(function() entry.respawnConn:Disconnect() end)
    end

    applyUnhideToChar(target.Character, uid)

    local anyHidden = next(HiddenPlayers) ~= nil
    if not anyHidden then
        removeChatFilter()
    end

    SendNotify("👁️ Unhide", target.DisplayName .. " restored", 2)
end

-- Hide enforcement loop: tracks character instances per hidden player.
-- Re-applies visuals + audio whenever a player respawns (new Character object).
-- Audio wire destruction is NOT re-run every tick — only on fresh characters.
local _hiddenCharCache = {}  -- [userId] = character instance last processed

task.spawn(function()
    while true do
        task.wait(0.3)
        for uid, _ in pairs(HiddenPlayers) do
            local p = Players:GetPlayerByUserId(uid)
            if p and p.Character then
                local char = p.Character
                -- Only re-apply if this is a different character than last time
                -- (player respawned) — avoids destroying freshly re-created Wires
                if _hiddenCharCache[uid] ~= char then
                    _hiddenCharCache[uid] = char
                    -- Clear old audio data so mutePlayerAudio runs fresh
                    hiddenAudioData[uid] = nil
                    applyHideToChar(char, uid)
                end
            end
        end
    end
end)

-- Anti-Void Loop
task.spawn(function()
    while true do
        if AntiVoidEnabled then
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and hrp.Position.Y < -500 then
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                hrp.CFrame = hrp.CFrame * CFrame.new(0, 550, 0)
                SendNotify("Anti-Void", "Saved from falling!", 2)
            end
        end
        task.wait(0.5)
    end
end)

-- ESP Update Loop
local espLast = 0
RunService.Heartbeat:Connect(function()
    if not ESPEnabled then return end
    local now = tick(); if now - espLast < 0.05 then return end; espLast = now
    if not ESPEnabled then return end
    if not game:GetService("GuiService"):IsTenFootInterface() and not UserInputService.WindowFocused then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= plr and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            
            -- Create ESP if doesn't exist
            if not espObjects[player.Name] then
                -- Box ESP
                local box = Drawing.new("Square")
                box.Visible = false
                box.Color = Color3.fromRGB(255, 255, 255)
                box.Thickness = 2
                box.Transparency = 1
                box.Filled = false
                
                -- Name Label
                local nameLabel = Drawing.new("Text")
                nameLabel.Visible = false
                nameLabel.Color = Color3.fromRGB(255, 255, 255)
                nameLabel.Size = 16
                nameLabel.Center = true
                nameLabel.Outline = true
                nameLabel.Font = 2
                
                -- Distance Label
                local distanceLabel = Drawing.new("Text")
                distanceLabel.Visible = false
                distanceLabel.Color = Color3.fromRGB(200, 200, 200)
                distanceLabel.Size = 14
                distanceLabel.Center = true
                distanceLabel.Outline = true
                distanceLabel.Font = 2
                
                -- Health Bar
                local healthBar = Drawing.new("Square")
                healthBar.Visible = false
                healthBar.Color = Color3.fromRGB(0, 255, 0)
                healthBar.Thickness = 1
                healthBar.Transparency = 1
                healthBar.Filled = true
                
                espObjects[player.Name] = {
                    box = box,
                    nameLabel = nameLabel,
                    distanceLabel = distanceLabel,
                    healthBar = healthBar
                }
            end
            
            local esp = espObjects[player.Name]
            
            -- Update ESP
            local vector, onScreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
            
            if onScreen then
                -- Calculate box size based on distance
                local selfHRP = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                if not selfHRP then return end
                local distance = (hrp.Position - selfHRP.Position).Magnitude
                local scaleFactor = 1 / (distance / 10)
                local boxWidth = math.clamp(2000 / distance, 50, 300)
                local boxHeight = boxWidth * 1.5
                
                -- Update box
                esp.box.Size = Vector2.new(boxWidth, boxHeight)
                esp.box.Position = Vector2.new(vector.X - boxWidth / 2, vector.Y - boxHeight / 2)
                esp.box.Visible = true
                
                -- Update name
                esp.nameLabel.Text = player.DisplayName
                esp.nameLabel.Position = Vector2.new(vector.X, vector.Y - boxHeight / 2 - 20)
                esp.nameLabel.Visible = true
                
                -- Update distance
                esp.distanceLabel.Text = string.format("[%d studs]", math.floor(distance))
                esp.distanceLabel.Position = Vector2.new(vector.X, vector.Y + boxHeight / 2 + 5)
                esp.distanceLabel.Visible = true
                
                -- Update health bar
                if humanoid then
                    local healthPercent = humanoid.Health / humanoid.MaxHealth
                    esp.healthBar.Size = Vector2.new(4, boxHeight * healthPercent)
                    esp.healthBar.Position = Vector2.new(vector.X - boxWidth / 2 - 8, vector.Y - boxHeight / 2 + (boxHeight * (1 - healthPercent)))
                    esp.healthBar.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
                    esp.healthBar.Visible = true
                end
                
                -- Color based on distance
                local color = distance < 50 and Color3.fromRGB(255, 0, 0) or 
                             distance < 150 and Color3.fromRGB(255, 255, 0) or 
                             Color3.fromRGB(255, 255, 255)
                esp.box.Color = color
                esp.nameLabel.Color = color
            else
                esp.box.Visible = false
                esp.nameLabel.Visible = false
                esp.distanceLabel.Visible = false
                esp.healthBar.Visible = false
            end
        end
    end
    
    -- Clean up disconnected players
    for playerName, esp in pairs(espObjects) do
        if not Players:FindFirstChild(playerName) then
            if esp.box then esp.box:Destroy() end
            if esp.nameLabel then esp.nameLabel:Destroy() end
            if esp.distanceLabel then esp.distanceLabel:Destroy() end
            if esp.healthBar then esp.healthBar:Destroy() end
            espObjects[playerName] = nil
        end
    end
end)

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  LOGIC — AIMLOCK SYSTEM                                      ║
-- ╚══════════════════════════════════════════════════════════════╝
-- =====================================================
-- AIMLOCK SYSTEM
-- =====================================================

AimlockEnabled = false
aimlockTarget = nil
fovCircle = nil

-- Create FOV Circle
local function CreateFOVCircle()
    if not fovCircle then
        fovCircle = Drawing.new("Circle")
        fovCircle.Visible = false
        fovCircle.Thickness = 2
        fovCircle.NumSides = 64
        fovCircle.Radius = 100
        fovCircle.Filled = false
        fovCircle.Color = Color3.fromRGB(255, 255, 255)
        fovCircle.Transparency = 1
    end
end

CreateFOVCircle()

-- Aimlock Toggle
AimlockButton.MouseButton1Click:Connect(function()
    AimlockEnabled = not AimlockEnabled
    
    if AimlockEnabled then
        AimlockButton.Text = "🎯 Aimlock: ON"
        AimlockButton.BackgroundTransparency = 0.7
        SendNotify("Aimlock", "Enabled - Aim at closest player in FOV", 3)
        fovCircle.Visible = true
    else
        AimlockButton.Text = "🎯 Aimlock: OFF"
        AimlockButton.BackgroundTransparency = 0.9
        SendNotify("Aimlock", "Disabled", 2)
        aimlockTarget = nil
        fovCircle.Visible = false
    end
end)

-- Aimlock Update Loop
aimlockLast = 0
RunService.Heartbeat:Connect(function()
    if not AimlockEnabled then return end
    local now = tick(); if now - aimlockLast < 0.033 then return end; aimlockLast = now
    if not AimlockEnabled then return end
    if not UserInputService.WindowFocused then return end
    
    -- Update FOV circle position
    local mousePos = UserInputService:GetMouseLocation()
    fovCircle.Position = mousePos
    
    -- Find closest player in FOV
    local closestPlayer = nil
    local closestDistance = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= plr and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character and player.Character:FindFirstChild("Head")
            if not head then return end
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            
            if humanoid and humanoid.Health > 0 then
                local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(head.Position)
                
                if onScreen then
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    
                    if distance < fovCircle.Radius and distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
    end
    
    aimlockTarget = closestPlayer
    
    -- Aim at target
    if aimlockTarget and aimlockTarget.Character and aimlockTarget.Character:FindFirstChild("Head") then
        local head = aimlockTarget.Character and aimlockTarget.Character:FindFirstChild("Head")
        if not head then return end
        workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, head.Position)
    end
end)

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  LOGIC — TIME REVERSE SYSTEM                                 ║
-- ╚══════════════════════════════════════════════════════════════╝
-- =====================================================
-- TIME REVERSE SYSTEM
-- =====================================================

TimeReverseEnabled = false
maxHistoryLength = 300 -- 10 seconds at 30fps
isReversing = false
-- Circular buffer for O(1) inserts instead of O(n) table.remove(t,1)
positionHistory = table.create(maxHistoryLength)
histHead = 1  -- next write index
histCount = 0 -- how many valid entries

-- Time Reverse Toggle
TimeReverseButton.MouseButton1Click:Connect(function()
    TimeReverseEnabled = not TimeReverseEnabled
    
    if TimeReverseEnabled then
        TimeReverseButton.Text = "⏮️ Time Reverse (C): ON"
        TimeReverseButton.BackgroundTransparency = 0.7
        SendNotify("Time Reverse", "Enabled - Hold C to reverse up to 10 seconds", 3)
    else
        TimeReverseButton.Text = "⏮️ Time Reverse (C): OFF"
        TimeReverseButton.BackgroundTransparency = 0.9
        SendNotify("Time Reverse", "Disabled", 2)
        positionHistory = table.create(maxHistoryLength); histHead = 1; histCount = 0
    end
end)

-- Record position history
trLast = 0
RunService.Heartbeat:Connect(function()
    if not TimeReverseEnabled or isReversing then return end
    local now = tick(); if now - trLast < 0.033 then return end; trLast = now
    if not TimeReverseEnabled or isReversing then return end
    if not UserInputService.WindowFocused then return end
    
    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        -- O(1) circular buffer write
        positionHistory[histHead] = { CFrame = hrp.CFrame }
        histHead = (histHead % maxHistoryLength) + 1
        if histCount < maxHistoryLength then histCount = histCount + 1 end
    end
end)

-- Time Reverse Input Handler
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.C and TimeReverseEnabled then
        isReversing = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.C and TimeReverseEnabled then
        isReversing = false
    end
end)

-- Apply time reverse (throttled to match record rate so speed feels 1:1)
trApplyLast = 0
RunService.Heartbeat:Connect(function()
    if not isReversing or not TimeReverseEnabled then return end
    if not UserInputService.WindowFocused then return end
    local now = tick(); if now - trApplyLast < 0.033 then return end; trApplyLast = now

    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and histCount > 0 then
        local hrp = plr.Character.HumanoidRootPart
        -- Read newest entry from circular buffer
        local readIdx = ((histHead - 2) % maxHistoryLength) + 1
        local lastPos = positionHistory[readIdx]
        if lastPos then
            hrp.CFrame = lastPos.CFrame
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            histHead = readIdx
            histCount = histCount - 1
        end
    end
end)

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  LOGIC — TRIP SYSTEM                                         ║
-- ╚══════════════════════════════════════════════════════════════╝
-- =====================================================
-- TRIP SYSTEM
-- =====================================================

TripEnabled = false

-- Trip Toggle
TripButton.MouseButton1Click:Connect(function()
    TripEnabled = not TripEnabled
    
    if TripEnabled then
        TripButton.Text = "🤸 Trip (T): ON"
        TripButton.BackgroundTransparency = 0.7
        SendNotify("Trip", "Enabled - Press T to trip and ragdoll", 3)
    else
        TripButton.Text = "🤸 Trip (T): OFF"
        TripButton.BackgroundTransparency = 0.9
        SendNotify("Trip", "Disabled", 2)
    end
end)

-- Trip Input Handler
tripActive = false

local function doTrip()
    if tripActive then return end
    local char = plr.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return end

    tripActive = true

    local origWalkSpeed  = humanoid.WalkSpeed
    local origJumpPower  = humanoid.JumpPower
    local origAutoRotate = humanoid.AutoRotate

    -- Freeze all movement
    humanoid.WalkSpeed     = 0
    humanoid.JumpPower     = 0
    humanoid.AutoRotate    = false
    humanoid.PlatformStand = true

    -- Tiny nudge forward so we tip over, no upward launch
    local lookDir = hrp.CFrame.LookVector
    hrp.AssemblyLinearVelocity = Vector3.new(lookDir.X * 8, -2, lookDir.Z * 8)

    -- Single forward-roll rotation to make it look like a faceplant
    hrp.AssemblyAngularVelocity = Vector3.new(
        hrp.CFrame.RightVector.X * 18,
        hrp.CFrame.RightVector.Y * 18,
        hrp.CFrame.RightVector.Z * 18
    )

    humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
    SendNotify("Trip", "Flopped!", 1)

    -- Get up after 1.5s
    task.delay(1.5, function()
        if not char or not char.Parent then tripActive = false return end
        if not humanoid or not humanoid.Parent then tripActive = false return end
        humanoid.PlatformStand = false
        humanoid.AutoRotate    = origAutoRotate
        humanoid.WalkSpeed     = origWalkSpeed
        humanoid.JumpPower     = origJumpPower
        pcall(function()
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.AssemblyLinearVelocity  = Vector3.zero
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
        tripActive = false
    end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.T and TripEnabled then
        doTrip()
    end
end)

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  LOGIC — PLAYER SPEED WINDOW                                 ║
-- ╚══════════════════════════════════════════════════════════════╝
-- =====================================================
-- PLAYER SPEED WINDOW
-- =====================================================
do
    local SpeedWindow = Instance.new("Frame")
    SpeedWindow.Name = "SpeedWindow"; SpeedWindow.Parent = OnyxUI
    SpeedWindow.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    SpeedWindow.BackgroundTransparency = 0.3; SpeedWindow.BorderSizePixel = 0
    SpeedWindow.Position = UDim2.new(0.5, -130, 0.5, -90)
    SpeedWindow.Size = UDim2.new(0, 260, 0, 200)
    SpeedWindow.Visible = false; SpeedWindow.Active = true
    SpeedWindow.ZIndex = 20; SpeedWindow.ClipsDescendants = true
    do
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 16); c.Parent = SpeedWindow
        local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255,255,255); s.Transparency = 0.8; s.Thickness = 1; s.Parent = SpeedWindow
    end

    -- Title bar
    local swTB = Instance.new("Frame"); swTB.Parent = SpeedWindow
    swTB.BackgroundColor3 = Color3.fromRGB(255,255,255); swTB.BackgroundTransparency = 0.95
    swTB.BorderSizePixel = 0; swTB.Size = UDim2.new(1,0,0,40); swTB.ZIndex = 21
    do
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,16); c.Parent = swTB
        local t = Instance.new("TextLabel"); t.Parent = swTB
        t.BackgroundTransparency = 1; t.Position = UDim2.new(0,15,0,0)
        t.Size = UDim2.new(1,-80,1,0); t.Font = Enum.Font.GothamBold
        t.Text = "🏃 Player Speed"; t.TextColor3 = Color3.fromRGB(255,255,255)
        t.TextSize = 16; t.TextXAlignment = Enum.TextXAlignment.Left; t.ZIndex = 22
    end
    do
        local cb = Instance.new("TextButton"); cb.Parent = swTB
        cb.BackgroundColor3 = Color3.fromRGB(255,80,80); cb.BackgroundTransparency = 0.3
        cb.BorderSizePixel = 0; cb.AnchorPoint = Vector2.new(1,0.5)
        cb.Position = UDim2.new(1,-10,0.5,0); cb.Size = UDim2.new(0,25,0,25)
        cb.Font = Enum.Font.GothamBold; cb.Text = "×"
        cb.TextColor3 = Color3.fromRGB(255,255,255); cb.TextSize = 18; cb.ZIndex = 22; cb.AutoButtonColor = false
        do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = cb end
        cb.MouseButton1Click:Connect(function() SpeedWindow.Visible = false end)

        local mn = Instance.new("TextButton"); mn.Parent = swTB
        mn.BackgroundColor3 = Color3.fromRGB(255,255,255); mn.BackgroundTransparency = 0.9
        mn.BorderSizePixel = 0; mn.AnchorPoint = Vector2.new(1,0.5)
        mn.Position = UDim2.new(1,-45,0.5,0); mn.Size = UDim2.new(0,25,0,25)
        mn.Font = Enum.Font.GothamBold; mn.Text = "−"
        mn.TextColor3 = Color3.fromRGB(255,255,255); mn.TextSize = 18; mn.ZIndex = 22; mn.AutoButtonColor = false
        do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = mn end
        local swMin = false
        mn.MouseButton1Click:Connect(function()
            swMin = not swMin
            TweenService:Create(SpeedWindow, TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out), {
                Size = swMin and UDim2.new(0,260,0,40) or UDim2.new(0,260,0,200)
            }):Play()
            mn.Text = swMin and "+" or "−"
        end)
    end

    -- Dragging
    do
        local swDragging, swDragInput, swDragStart, swStartPos
        swTB.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                swDragging = true; swDragStart = inp.Position; swStartPos = SpeedWindow.Position
                inp.Changed:Connect(function() if inp.UserInputState == Enum.UserInputState.End then swDragging = false end end)
            end
        end)
        swTB.InputChanged:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseMovement then swDragInput = inp end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if inp == swDragInput and swDragging then
                local d = inp.Position - swDragStart
                SpeedWindow.Position = UDim2.new(swStartPos.X.Scale, swStartPos.X.Offset + d.X, swStartPos.Y.Scale, swStartPos.Y.Offset + d.Y)
            end
        end)
    end

    -- Slider builder (reuse pattern from fly window)
    local function BuildSpeedSlider(yPos, labelText, minVal, maxVal, defaultVal, applyFn)
        local val = defaultVal
        local row = Instance.new("Frame"); row.Parent = SpeedWindow
        row.BackgroundTransparency = 1; row.Position = UDim2.new(0,15,0,yPos)
        row.Size = UDim2.new(1,-30,0,52); row.ZIndex = 21

        local lbl = Instance.new("TextLabel"); lbl.Parent = row; lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(0.65,0,0,18); lbl.Font = Enum.Font.GothamMedium
        lbl.Text = labelText; lbl.TextColor3 = Color3.fromRGB(220,220,240)
        lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 22

        local valLbl = Instance.new("TextLabel"); valLbl.Parent = row; valLbl.BackgroundTransparency = 1
        valLbl.AnchorPoint = Vector2.new(1,0); valLbl.Position = UDim2.new(1,0,0,0)
        valLbl.Size = UDim2.new(0.33,0,0,18); valLbl.Font = Enum.Font.GothamBold
        valLbl.Text = tostring(defaultVal); valLbl.TextColor3 = Color3.fromRGB(100,220,255)
        valLbl.TextSize = 12; valLbl.TextXAlignment = Enum.TextXAlignment.Right; valLbl.ZIndex = 22

        local track = Instance.new("Frame"); track.Parent = row
        track.BackgroundColor3 = Color3.fromRGB(255,255,255); track.BackgroundTransparency = 0.88
        track.BorderSizePixel = 0; track.Position = UDim2.new(0,0,0,26); track.Size = UDim2.new(1,0,0,8); track.ZIndex = 22
        do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = track end

        local pct0 = (defaultVal - minVal) / (maxVal - minVal)
        local fill = Instance.new("Frame"); fill.Parent = track
        fill.BackgroundColor3 = Color3.fromRGB(100,200,255); fill.BorderSizePixel = 0
        fill.Size = UDim2.new(pct0,0,1,0); fill.ZIndex = 23
        do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = fill end

        local knob = Instance.new("Frame"); knob.Parent = track
        knob.BackgroundColor3 = Color3.fromRGB(180,240,255); knob.BorderSizePixel = 0
        knob.AnchorPoint = Vector2.new(0.5,0.5); knob.Position = UDim2.new(pct0,0,0.5,0)
        knob.Size = UDim2.new(0,16,0,16); knob.ZIndex = 24
        do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = knob end

        local btn = Instance.new("TextButton"); btn.Parent = track
        btn.BackgroundTransparency = 1; btn.Size = UDim2.new(1,0,1,0)
        btn.Text = ""; btn.ZIndex = 25; btn.AutoButtonColor = false

        local sliding = false
        local function setFromX(x)
            local p = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            val = math.round(minVal + (maxVal - minVal) * p)
            fill.Size = UDim2.new(p,0,1,0); knob.Position = UDim2.new(p,0,0.5,0)
            valLbl.Text = tostring(val)
            applyFn(val)
        end

        btn.MouseButton1Down:Connect(function() sliding = true; setFromX(plr:GetMouse().X) end)
        UserInputService.InputChanged:Connect(function(inp)
            if sliding and inp.UserInputType == Enum.UserInputType.MouseMovement then setFromX(inp.Position.X) end
        end)
        UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
        end)
    end

    -- WalkSpeed slider (16–200, default 16)
    BuildSpeedSlider(48, "⚡ Walk Speed", 1, 200, 16, function(v)
        local char = plr.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end)

    -- JumpPower slider (0–200, default 50)
    BuildSpeedSlider(108, "🦘 Jump Power", 0, 200, 50, function(v)
        local char = plr.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = v end
    end)

    -- Reset button
    local resetBtn = Instance.new("TextButton"); resetBtn.Parent = SpeedWindow
    resetBtn.BackgroundColor3 = Color3.fromRGB(255,255,255); resetBtn.BackgroundTransparency = 0.9
    resetBtn.BorderSizePixel = 0; resetBtn.Position = UDim2.new(0.08,0,0,166)
    resetBtn.Size = UDim2.new(0.84,0,0,26); resetBtn.Font = Enum.Font.GothamBold
    resetBtn.Text = "Reset to Default"; resetBtn.TextColor3 = Color3.fromRGB(200,200,220)
    resetBtn.TextSize = 12; resetBtn.ZIndex = 21; resetBtn.AutoButtonColor = false
    do
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = resetBtn
        local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255,255,255); s.Transparency = 0.85; s.Thickness = 1; s.Parent = resetBtn
    end
    resetBtn.MouseEnter:Connect(function() TweenService:Create(resetBtn,TweenInfo.new(0.15),{BackgroundTransparency=0.7}):Play() end)
    resetBtn.MouseLeave:Connect(function() TweenService:Create(resetBtn,TweenInfo.new(0.15),{BackgroundTransparency=0.9}):Play() end)
    resetBtn.MouseButton1Click:Connect(function()
        local char = plr.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16; hum.JumpPower = 50 end
        SendNotify("Speed", "Reset to defaults", 2)
    end)

    SpeedButton.MouseButton1Click:Connect(function()
        SpeedWindow.Visible = not SpeedWindow.Visible
    end)
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  LOGIC — SUPERMAN FLY (UI + Logic)                           ║
-- ╚══════════════════════════════════════════════════════════════╝
-- =====================================================
-- SUPERMAN FLY  (UI + Logic)
-- G or window button to toggle. WASD = camera-relative.
-- Space = ascend, Ctrl = descend, Shift = boost speed.
-- =====================================================

SupermanFlyEnabled = false
superFlyConn       = nil
superBodyVel       = nil
superBodyGyro      = nil

-- Speed getters — overwritten by slider callbacks when window builds
getFlySpeed      = function() return 80  end
getFlyBoostSpeed = function() return 220 end

-- local FlyWindow, FlyTitleBar, FlyStatusLabel, FlyToggleBtn
do
    FlyWindow = Instance.new("Frame")
    FlyWindow.Name = "FlyWindow"; FlyWindow.Parent = OnyxUI
    FlyWindow.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    FlyWindow.BackgroundTransparency = 0.3; FlyWindow.BorderSizePixel = 0
    FlyWindow.Position = UDim2.new(0.5, -140, 0.5, -100)
    FlyWindow.Size = UDim2.new(0, 280, 0, 240)
    FlyWindow.Visible = false; FlyWindow.Active = true
    FlyWindow.ZIndex = 20; FlyWindow.ClipsDescendants = true
    do
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 16); c.Parent = FlyWindow
        local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255,255,255)
        s.Transparency = 0.8; s.Thickness = 1; s.Parent = FlyWindow
    end

    FlyTitleBar = Instance.new("Frame")
    FlyTitleBar.Name = "TitleBar"; FlyTitleBar.Parent = FlyWindow
    FlyTitleBar.BackgroundColor3 = Color3.fromRGB(255,255,255)
    FlyTitleBar.BackgroundTransparency = 0.95; FlyTitleBar.BorderSizePixel = 0
    FlyTitleBar.Size = UDim2.new(1,0,0,40); FlyTitleBar.ZIndex = 21
    do
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,16); c.Parent = FlyTitleBar
        local t = Instance.new("TextLabel"); t.Parent = FlyTitleBar
        t.BackgroundTransparency = 1; t.Position = UDim2.new(0,15,0,0)
        t.Size = UDim2.new(1,-80,1,0); t.Font = Enum.Font.GothamBold
        t.Text = "ð¦¸ Superman Fly"; t.TextColor3 = Color3.fromRGB(255,255,255)
        t.TextSize = 16; t.TextXAlignment = Enum.TextXAlignment.Left; t.ZIndex = 22
    end

    do
        local flyClose = Instance.new("TextButton")
        flyClose.Name = "CloseBtn"; flyClose.Parent = FlyTitleBar
        flyClose.BackgroundColor3 = Color3.fromRGB(255,80,80); flyClose.BackgroundTransparency = 0.3
        flyClose.BorderSizePixel = 0; flyClose.AnchorPoint = Vector2.new(1,0.5)
        flyClose.Position = UDim2.new(1,-10,0.5,0); flyClose.Size = UDim2.new(0,25,0,25)
        flyClose.Font = Enum.Font.GothamBold; flyClose.Text = "Ã"
        flyClose.TextColor3 = Color3.fromRGB(255,255,255); flyClose.TextSize = 18
        flyClose.ZIndex = 22; flyClose.AutoButtonColor = false
        do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = flyClose end
        flyClose.MouseButton1Click:Connect(function() FlyWindow.Visible = false end)

        local flyMin = Instance.new("TextButton")
        flyMin.Name = "MinimizeBtn"; flyMin.Parent = FlyTitleBar
        flyMin.BackgroundColor3 = Color3.fromRGB(255,255,255); flyMin.BackgroundTransparency = 0.9
        flyMin.BorderSizePixel = 0; flyMin.AnchorPoint = Vector2.new(1,0.5)
        flyMin.Position = UDim2.new(1,-45,0.5,0); flyMin.Size = UDim2.new(0,25,0,25)
        flyMin.Font = Enum.Font.GothamBold; flyMin.Text = "â"
        flyMin.TextColor3 = Color3.fromRGB(255,255,255); flyMin.TextSize = 18
        flyMin.ZIndex = 22; flyMin.AutoButtonColor = false
        do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = flyMin end
        local flyMinimized = false
        flyMin.MouseButton1Click:Connect(function()
            flyMinimized = not flyMinimized
            local ti = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            TweenService:Create(FlyWindow, ti, {
                Size = flyMinimized and UDim2.new(0,280,0,40) or UDim2.new(0,280,0,240)
            }):Play()
            flyMin.Text = flyMinimized and "+" or "â"
        end)
    end

    FlyStatusLabel = Instance.new("TextLabel")
    FlyStatusLabel.Parent = FlyWindow; FlyStatusLabel.BackgroundTransparency = 1
    FlyStatusLabel.Position = UDim2.new(0,15,0,48); FlyStatusLabel.Size = UDim2.new(1,-30,0,18)
    FlyStatusLabel.Font = Enum.Font.Gotham
    FlyStatusLabel.Text = "Status: Off  |  WASD  |  Space/Ctrl  |  Shift boost"
    FlyStatusLabel.TextColor3 = Color3.fromRGB(150,150,180); FlyStatusLabel.TextSize = 11
    FlyStatusLabel.TextXAlignment = Enum.TextXAlignment.Left; FlyStatusLabel.ZIndex = 21
    FlyStatusLabel.TextTruncate = Enum.TextTruncate.AtEnd

    local function BuildFlySlider(yPos, labelText, minVal, maxVal, defaultVal)
        local val = defaultVal
        local row = Instance.new("Frame")
        row.Parent = FlyWindow; row.BackgroundTransparency = 1
        row.Position = UDim2.new(0,15,0,yPos); row.Size = UDim2.new(1,-30,0,52); row.ZIndex = 21

        local lbl = Instance.new("TextLabel")
        lbl.Parent = row; lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(0.6,0,0,18); lbl.Font = Enum.Font.GothamMedium
        lbl.Text = labelText; lbl.TextColor3 = Color3.fromRGB(220,220,240)
        lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 22

        local valLbl = Instance.new("TextLabel")
        valLbl.Parent = row; valLbl.BackgroundTransparency = 1
        valLbl.AnchorPoint = Vector2.new(1,0); valLbl.Position = UDim2.new(1,0,0,0)
        valLbl.Size = UDim2.new(0.38,0,0,18); valLbl.Font = Enum.Font.GothamBold
        valLbl.Text = tostring(defaultVal); valLbl.TextColor3 = Color3.fromRGB(180,170,255)
        valLbl.TextSize = 12; valLbl.TextXAlignment = Enum.TextXAlignment.Right; valLbl.ZIndex = 22

        local track = Instance.new("Frame")
        track.Parent = row; track.BackgroundColor3 = Color3.fromRGB(255,255,255)
        track.BackgroundTransparency = 0.88; track.BorderSizePixel = 0
        track.Position = UDim2.new(0,0,0,26); track.Size = UDim2.new(1,0,0,8); track.ZIndex = 22
        do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = track end

        local pct0 = (defaultVal - minVal) / (maxVal - minVal)
        local fill = Instance.new("Frame")
        fill.Parent = track; fill.BackgroundColor3 = Color3.fromRGB(140,130,255)
        fill.BorderSizePixel = 0; fill.Size = UDim2.new(pct0,0,1,0); fill.ZIndex = 23
        do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = fill end

        local knob = Instance.new("Frame")
        knob.Parent = track; knob.BackgroundColor3 = Color3.fromRGB(200,195,255)
        knob.BorderSizePixel = 0; knob.AnchorPoint = Vector2.new(0.5,0.5)
        knob.Position = UDim2.new(pct0,0,0.5,0); knob.Size = UDim2.new(0,16,0,16); knob.ZIndex = 24
        do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = knob end

        local btn = Instance.new("TextButton")
        btn.Parent = track; btn.BackgroundTransparency = 1
        btn.Size = UDim2.new(1,0,1,0); btn.Text = ""; btn.ZIndex = 25; btn.AutoButtonColor = false

        local sliding = false
        local function setFromX(x)
            local p = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            val = math.round(minVal + (maxVal - minVal) * p)
            fill.Size = UDim2.new(p,0,1,0)
            knob.Position = UDim2.new(p,0,0.5,0)
            valLbl.Text = tostring(val)
        end

        btn.MouseButton1Down:Connect(function() sliding = true; setFromX(plr:GetMouse().X) end)
        UserInputService.InputChanged:Connect(function(inp)
            if sliding and inp.UserInputType == Enum.UserInputType.MouseMovement then setFromX(inp.Position.X) end
        end)
        UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
        end)

        return function() return val end
    end

    getFlySpeed      = BuildFlySlider(72,  "â¡ Speed",       10, 300, 80)
    getFlyBoostSpeed = BuildFlySlider(132, "ð Boost Speed",  10, 600, 220)

    FlyToggleBtn = Instance.new("TextButton")
    FlyToggleBtn.Parent = FlyWindow
    FlyToggleBtn.BackgroundColor3 = Color3.fromRGB(255,255,255)
    FlyToggleBtn.BackgroundTransparency = 0.88; FlyToggleBtn.BorderSizePixel = 0
    FlyToggleBtn.Position = UDim2.new(0.1,0,0,188); FlyToggleBtn.Size = UDim2.new(0.8,0,0,38)
    FlyToggleBtn.Font = Enum.Font.GothamBold; FlyToggleBtn.Text = "â¶ Start Fly (G)"
    FlyToggleBtn.TextColor3 = Color3.fromRGB(255,255,255); FlyToggleBtn.TextSize = 14
    FlyToggleBtn.ZIndex = 21; FlyToggleBtn.AutoButtonColor = false
    do
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,10); c.Parent = FlyToggleBtn
        local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255,255,255)
        s.Transparency = 0.88; s.Thickness = 1; s.Parent = FlyToggleBtn
    end
    FlyToggleBtn.MouseEnter:Connect(function()
        TweenService:Create(FlyToggleBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.65}):Play()
    end)
    FlyToggleBtn.MouseLeave:Connect(function()
        TweenService:Create(FlyToggleBtn, TweenInfo.new(0.15), {
            BackgroundTransparency = SupermanFlyEnabled and 0 or 0.88
        }):Play()
    end)

    -- Drag
    do
        local flyDragging, flyDragInput, flyDragStart, flyStartPos
        FlyTitleBar.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                flyDragging = true; flyDragStart = inp.Position; flyStartPos = FlyWindow.Position
                inp.Changed:Connect(function() if inp.UserInputState == Enum.UserInputState.End then flyDragging = false end end)
            end
        end)
        FlyTitleBar.InputChanged:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                flyDragInput = inp
            end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if inp == flyDragInput and flyDragging then
                local d = inp.Position - flyDragStart
                FlyWindow.Position = UDim2.new(flyStartPos.X.Scale, flyStartPos.X.Offset + d.X, flyStartPos.Y.Scale, flyStartPos.Y.Offset + d.Y)
            end
        end)
    end

    -- Misc button opens the window
    SupermanFlyButton.MouseButton1Click:Connect(function()
        FlyWindow.Visible = not FlyWindow.Visible
    end)
end

-- ── Superman Fly: LinearVelocity + AlignOrientation (modern Roblox constraints)
-- LinearVelocity replaces deprecated BodyVelocity — no oscillation jitter.
-- AlignOrientation replaces BodyGyro — instant snap, RigidityEnabled.
-- Smooth momentum lerp makes it feel weighty. Falls back to BodyVelocity/BodyGyro
-- on executors that don't support the new API.
-- Controls: WASD camera-relative | Space = up | Ctrl = down | Shift = boost | G toggle

local superFlyAtt0     = nil
local superLinVel      = nil
local superAlignOri    = nil
local currentVelocity  = Vector3.zero

local function stopSupermanFly()
    SupermanFlyEnabled = false
    currentVelocity    = Vector3.zero

    if superFlyConn  then superFlyConn:Disconnect();  superFlyConn  = nil end
    if superLinVel   then pcall(function() superLinVel:Destroy()   end); superLinVel   = nil end
    if superAlignOri then pcall(function() superAlignOri:Destroy() end); superAlignOri = nil end
    if superFlyAtt0  then pcall(function() superFlyAtt0:Destroy()  end); superFlyAtt0  = nil end
    if superBodyVel  then pcall(function() superBodyVel:Destroy()  end); superBodyVel  = nil end
    if superBodyGyro then pcall(function() superBodyGyro:Destroy() end); superBodyGyro = nil end

    local char = plr.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false; hum.AutoRotate = true end

    pcall(function() SupermanFlyButton.Text = "🦸 Superman Fly (G): OFF"; SupermanFlyButton.BackgroundTransparency = 0.9 end)
    pcall(function()
        FlyToggleBtn.Text = "▶ Start Fly (G)"
        TweenService:Create(FlyToggleBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(255,255,255), BackgroundTransparency = 0.88
        }):Play()
        FlyStatusLabel.Text = "Status: Off  |  WASD  |  Space/Ctrl  |  Shift boost"
    end)
end

local function startSupermanFly()
    local char = plr.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    SupermanFlyEnabled = true
    currentVelocity    = Vector3.zero
    hum.PlatformStand  = true
    hum.AutoRotate     = false

    -- Try new-API: LinearVelocity + AlignOrientation
    local useNewAPI = false
    pcall(function()
        superFlyAtt0          = Instance.new("Attachment")
        superFlyAtt0.Position = Vector3.zero
        superFlyAtt0.Parent   = hrp

        superLinVel                  = Instance.new("LinearVelocity")
        superLinVel.MaxForce         = math.huge
        superLinVel.VectorVelocity   = Vector3.zero
        superLinVel.RelativeTo       = Enum.ActuatorRelativeTo.World
        superLinVel.Attachment0      = superFlyAtt0
        superLinVel.Parent           = hrp

        superAlignOri                       = Instance.new("AlignOrientation")
        superAlignOri.MaxTorque             = math.huge
        superAlignOri.MaxAngularVelocity    = math.huge
        superAlignOri.Responsiveness        = 60
        superAlignOri.RigidityEnabled       = true
        superAlignOri.Mode                  = Enum.OrientationAlignmentMode.OneAttachment
        superAlignOri.Attachment0           = superFlyAtt0
        superAlignOri.Parent                = hrp

        useNewAPI = true
    end)

    -- Fallback: legacy BodyVelocity + BodyGyro
    if not useNewAPI then
        pcall(function() if superFlyAtt0 then superFlyAtt0:Destroy() end end); superFlyAtt0 = nil

        superBodyVel          = Instance.new("BodyVelocity")
        superBodyVel.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        superBodyVel.Velocity = Vector3.zero
        superBodyVel.Parent   = hrp

        superBodyGyro           = Instance.new("BodyGyro")
        superBodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
        superBodyGyro.D         = 100
        superBodyGyro.P         = 1e5
        superBodyGyro.CFrame    = hrp.CFrame
        superBodyGyro.Parent    = hrp
    end

    pcall(function() SupermanFlyButton.Text = "🦸 Superman Fly (G): ON"; SupermanFlyButton.BackgroundTransparency = 0.7 end)
    pcall(function()
        FlyToggleBtn.Text = "■ Stop Fly (G)"
        TweenService:Create(FlyToggleBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(100,220,120), BackgroundTransparency = 0
        }):Play()
    end)

    superFlyConn = RunService.RenderStepped:Connect(function(dt)
        local c2   = plr.Character
        local hrp2 = c2 and c2:FindFirstChild("HumanoidRootPart")
        local alive = useNewAPI and (superLinVel and superLinVel.Parent) or (superBodyVel and superBodyVel.Parent)
        if not hrp2 or not alive then stopSupermanFly(); return end

        local UIS   = UserInputService
        local camCF = workspace.CurrentCamera.CFrame

        -- Camera-relative horizontal direction, Y stripped
        local function flat(v) local f = Vector3.new(v.X,0,v.Z); return f.Magnitude > 0.001 and f.Unit or Vector3.zero end
        local moveDir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + flat(camCF.LookVector)  end
        if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - flat(camCF.LookVector)  end
        if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - flat(camCF.RightVector) end
        if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + flat(camCF.RightVector) end
        if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end

        local vertical   = 0
        if UIS:IsKeyDown(Enum.KeyCode.Space)        then vertical =  1 end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl)
        or UIS:IsKeyDown(Enum.KeyCode.RightControl) then vertical = -1 end

        local isBoosting = UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)
        local speed      = isBoosting and getFlyBoostSpeed() or getFlySpeed()

        -- Smooth momentum lerp — snappier when boosting
        local targetVel = Vector3.new(moveDir.X * speed, vertical * speed * 0.65, moveDir.Z * speed)
        local alpha     = math.clamp(dt * (isBoosting and 14 or 9), 0, 1)
        currentVelocity = currentVelocity:Lerp(targetVel, alpha)

        -- Apply
        if useNewAPI then
            superLinVel.VectorVelocity = currentVelocity
        else
            superBodyVel.Velocity = currentVelocity
        end

        -- Orientation: tilt nose down when moving, face camera yaw when idle
        local travelFlat = Vector3.new(currentVelocity.X, 0, currentVelocity.Z)
        local orientCF
        if travelFlat.Magnitude > 2 then
            local tilt = math.clamp(travelFlat.Magnitude / speed, 0, 1) * (vertical < 0 and 0.15 or 0.55)
            orientCF = CFrame.lookAt(hrp2.Position, hrp2.Position + (travelFlat.Unit + Vector3.new(0, -tilt, 0)).Unit)
        else
            local _, yaw, _ = camCF:ToEulerAnglesYXZ()
            orientCF = CFrame.new(hrp2.Position) * CFrame.Angles(vertical * 0.3, yaw, 0)
        end

        if useNewAPI then
            pcall(function() superAlignOri.CFrame = orientCF end)
        else
            superBodyGyro.CFrame = orientCF
        end

        pcall(function()
            FlyStatusLabel.Text = (isBoosting and "🚀 Boosting" or (travelFlat.Magnitude > 1 and "✈ Flying" or "● Hovering"))
                .. "  " .. math.floor(currentVelocity.Magnitude) .. " st/s  |  Shift = boost"
        end)
    end)
end

FlyToggleBtn.MouseButton1Click:Connect(function()
    if SupermanFlyEnabled then stopSupermanFly() else startSupermanFly() end
end)

-- G key toggle
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.G then
        if SupermanFlyEnabled then
            stopSupermanFly()
            SendNotify("Superman Fly", "Disabled", 2)
        else
            startSupermanFly()
            SendNotify("Superman Fly", "On — WASD · Space/Ctrl · Shift boost", 3)
        end
    end
end)

-- Respawn cleanup
plr.CharacterAdded:Connect(function()
    if SupermanFlyEnabled then
        task.wait(0.5)
        stopSupermanFly()
    end
end)

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  LOGIC — FE CHARACTER CLONER                                 ║
-- ╚══════════════════════════════════════════════════════════════╝
-- =====================================================
-- FE CHARACTER CLONER
-- .char <name> copies a player's HumanoidDescription
-- (outfit, scales, body colors) AND their animation IDs
-- onto YOUR character — visible to everyone on the server.
-- .char reset restores your original appearance.
-- =====================================================

charCloneActive   = false
originalDesc      = nil   -- saved before first clone
charCloneTarget   = nil   -- name string

local function applyAnimationsFromDesc(desc)
    -- Applies the animation IDs from a HumanoidDescription to the local Animate script
    local char = plr.Character
    if not char then return end
    local animate = char:FindFirstChild("Animate")
    if not animate then return end

    local animMap = {
        idle       = { desc.IdleAnimationId,   desc.IdleAnimationId   },
        walk       = { desc.WalkAnimationId                            },
        run        = { desc.RunAnimationId                             },
        jump       = { desc.JumpAnimationId                            },
        fall       = { desc.FallAnimationId                            },
        climb      = { desc.ClimbAnimationId                           },
        swim       = { desc.SwimAnimationId                            },
        swimidle   = { desc.SwimIdleAnimationId                        },
    }

    for scriptChildName, ids in pairs(animMap) do
        local folder = animate:FindFirstChild(scriptChildName)
        if not folder then continue end
        local anims = folder:GetChildren()
        for i, anim in ipairs(anims) do
            if anim:IsA("Animation") and ids[i] and ids[i] ~= 0 then
                local full = "rbxassetid://" .. tostring(ids[i])
                local ok = pcall(function() anim.AnimationId = full end)
                if not ok then
                    local parent = anim.Parent
                    local name   = anim.Name
                    pcall(function() anim:Destroy() end)
                    local a = Instance.new("Animation"); a.Name = name; a.AnimationId = full; a.Parent = parent
                end
            end
        end
    end
end

local function doCharClone(targetPlayer)
    local char = plr.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then SendNotify("Char Clone", "No humanoid found", 2) return end

    -- Save original description once before any clone
    if not originalDesc then
        local ok, desc = pcall(function()
            return Players:GetHumanoidDescriptionFromUserId(plr.UserId)
        end)
        if ok and desc then originalDesc = desc end
    end

    local ok, targetDesc = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(targetPlayer.UserId)
    end)
    if not ok or not targetDesc then
        SendNotify("Char Clone", "Failed to fetch appearance for " .. targetPlayer.DisplayName, 3)
        return
    end

    -- Apply appearance — HumanoidDescription changes replicate to server so everyone sees it
    pcall(function() hum:ApplyDescription(targetDesc) end)
    -- Swap in their animations too
    applyAnimationsFromDesc(targetDesc)

    charCloneActive = true
    charCloneTarget = targetPlayer.Name
    pcall(function()
        CharCloneButton.Text = "🦸 Clone Char: ON (" .. targetPlayer.Name .. ")"
        CharCloneButton.BackgroundTransparency = 0.7
    end)
    SendNotify("🦸 Char Clone", "Cloned " .. targetPlayer.DisplayName .. "'s appearance", 3)
end

local function resetCharClone()
    if not originalDesc then
        SendNotify("Char Clone", "No saved appearance to restore", 2)
        return
    end
    local char = plr.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    pcall(function() hum:ApplyDescription(originalDesc) end)
    applyAnimationsFromDesc(originalDesc)
    charCloneActive = false
    charCloneTarget = nil
    pcall(function()
        CharCloneButton.Text = "🦸 Clone Char: OFF"
        CharCloneButton.BackgroundTransparency = 0.9
    end)
    SendNotify("Char Clone", "Appearance restored", 2)
end

CharCloneButton.MouseButton1Click:Connect(function()
    if charCloneActive then
        resetCharClone()
    else
        -- Try to use currently targeted player
        local target = TargetedPlayer and GetPlayer(TargetedPlayer)
        if not target then target = GetPlayer(TargetNameInput.Text) end
        if target then
            doCharClone(target)
        else
            SendNotify("Char Clone", "Set a target first or use .char <name>", 3)
        end
    end
end)

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  LOGIC — UNLOAD SCRIPT                                       ║
-- ╚══════════════════════════════════════════════════════════════╝
-- =====================================================
-- UNLOAD SCRIPT
-- =====================================================

-- Unload Script Button
unloadPending = false
UnloadScriptButton.MouseButton1Click:Connect(function()
    if unloadPending then return end
    unloadPending = true

    -- Show confirmation with different color
    UnloadScriptButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    UnloadScriptButton.Text = "⚠️ Click Again to Confirm"
    
    -- Reset after 3 seconds if not confirmed
    task.delay(3, function()
        if unloadPending then
            unloadPending = false
            UnloadScriptButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            UnloadScriptButton.Text = "❌ Unload Script"
        end
    end)
    
    -- Wait for second click
    local connection
    connection = UnloadScriptButton.MouseButton1Click:Connect(function()
        if not unloadPending then connection:Disconnect() return end
        unloadPending = false
        connection:Disconnect()
        
        SendNotify("Unloading", "Cleaning up and removing Onyx...", 2)
        
        -- Disable all features
        ClickTeleportEnabled = false
        InfiniteBaseplateEnabled = false
        ESPEnabled = false
        AimlockEnabled = false
        TimeReverseEnabled = false
        TripEnabled = false
        if SupermanFlyEnabled then stopSupermanFly() end
        if charCloneActive then resetCharClone() end
        
        -- Clean up ESP
        for _, espData in pairs(espObjects) do
            if espData.box then espData.box:Destroy() end
            if espData.nameLabel then espData.nameLabel:Destroy() end
            if espData.distanceLabel then espData.distanceLabel:Destroy() end
            if espData.healthBar then espData.healthBar:Destroy() end
        end
        espObjects = {}
        
        -- Clean up aimlock
        if fovCircle then
            fovCircle:Destroy()
        end
        
        -- Clean up infinite baseplate clones
        for _, clone in ipairs(baseplateClones) do
            if clone and clone.Parent then
                clone:Destroy()
            end
        end
        
        -- Stop all target functions
        ViewingTarget = false
        SpectatingTarget = false
        FocusingTarget = false
        AttachedToTarget = false
        HeadSitting = false
        BackpackMode = false
        
        -- Stop face bang
        if FaceBangEnabled then
            StopFaceBang()
        end
        
        -- Reset camera
        if plr.Character and plr.Character:FindFirstChild("Humanoid") then
            workspace.CurrentCamera.CameraSubject = plr.Character.Humanoid
        end
        
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        local fadeTween = TweenService:Create(MainFrame, tweenInfo, {BackgroundTransparency = 1})
        fadeTween:Play()
        
        task.wait(0.5)
        
        -- Destroy the entire GUI
        OnyxUI:Destroy()
        
        SendNotify("Onyx", "Successfully unloaded. Goodbye!", 3)
    end)
end)

-- Success notification

SendNotify("Onyx", "Press B to toggle | Loaded Successfully", 4)
task.wait(0.5)
if canUsePhysicsRep then
    SendNotify("Onyx", "Zero-delay mode active (PhysicsRepRootPart supported)", 3)
else
    SendNotify("Onyx", "Fallback mode active (CFrame tracking - PhysicsRepRootPart unsupported)", 4)
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SYSTEM — ONYX NAMETAG SYSTEM                                ║
-- ╚══════════════════════════════════════════════════════════════╝
-- =====================================================
-- ONYX NAMETAG SYSTEM
-- =====================================================
local function setupOnyxNametags()
-- Mark this executor as active
plr:SetAttribute("OnyxExecuted", true)

-- Runtime state
local nametagObjects = {}   -- [userId] = BillboardGui instance
local nametagConfigs = {}   -- [username] = config OR "loading" OR "inactive"
local WORKER_BASE = "https://onyx-backend-production-22fa.up.railway.app"
local registeredNames = {} -- [username:lower()] = true

-- refreshDiscoveryList is defined here but only CALLED after all other functions exist.
-- It uses onDiscovery callback (set later) to avoid forward-reference nil crashes.
local onDiscovery = nil  -- set after pollPlayer/removeNametag/isNametagValid are defined
local pollPlayer  -- forward declaration: defined below, used in CharacterAdded hook above

local function refreshDiscoveryList()
    local ok, result = pcall(function()
        return httpRequest({
            Url    = WORKER_BASE .. "/registered-users?job_id=" .. game.JobId,
            Method = "GET",
        })
    end)
    if not ok or not result then return end
    if result.StatusCode ~= 200 then return end
    local decoded = HttpService:JSONDecode(result.Body)
    if decoded and decoded.usernames and onDiscovery then
        onDiscovery(decoded.usernames)
    end
end

local function GetHWID()
    local hwid = "Unknown"
    pcall(function() hwid = game:GetService("RbxAnalyticsService"):GetClientId() end)
    return hwid
end

local function GetExecutor()
    return (identifyexecutor or getexecutorname or function() return "Unknown" end)()
end

local function logExecution()
    pcall(function()
        httpRequest({
            Url     = WORKER_BASE .. "/log-execution",
            Method  = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body    = game:GetService("HttpService"):JSONEncode({
                username = plr.Name,
                userId   = plr.UserId,
                hwid     = GetHWID(),
                executor = GetExecutor(),
                type     = "MainScript"
            })
        })
    end)
end

task.spawn(logExecution)

-- Always clear self from cache so custom tag is always fetched fresh
nametagConfigs[plr.Name] = nil
nametagConfigs[plr.Name:lower()] = nil

DEFAULT_BG_IMAGE   = "" -- Set to "" for solid color only
DEFAULT_ICON_IMAGE = "rbxassetid://138249935932599"

NAMETAG_FONT_MAP = {
    ["GothamBlack"]  = Enum.Font.GothamBlack,
    ["Arcade"]       = Enum.Font.Arcade,
    ["Oswald"]       = Enum.Font.Oswald,
    ["Jura"]         = Enum.Font.Jura,
    ["Creepster"]    = Enum.Font.Creepster,
}

-- Default nametag config
local function getDefaultConfig()
    return {
        displayName            = "Onyx User",
        font                   = "GothamBlack",
        textColor              = Color3.fromRGB(139, 127, 255),
        outlineColor           = Color3.fromRGB(255, 255, 255),
        backgroundColor        = Color3.fromRGB(0, 0,0),
        backgroundTransparency = 0,
        backgroundImage        = (DEFAULT_BG_IMAGE ~= "") and DEFAULT_BG_IMAGE or nil,
        iconImage              = (DEFAULT_ICON_IMAGE ~= "") and DEFAULT_ICON_IMAGE or nil,
        glitchAnim             = false,
        width                  = 5,
        topTextSize            = 18,
        botTextSize            = 13,
    }
end

-- Parse hex color string (#RRGGBB) → Color3
local function hexToColor3(hex)
    if not hex then return nil end
    hex = hex:gsub("#", "")
    if #hex == 3 then
        hex = hex:sub(1,1):rep(2) .. hex:sub(2,2):rep(2) .. hex:sub(3,3):rep(2)
    end
    if #hex ~= 6 then return nil end
    local r = tonumber(hex:sub(1,2), 16)
    local g = tonumber(hex:sub(3,4), 16)
    local b = tonumber(hex:sub(5,6), 16)
    if r and g and b then
        return Color3.fromRGB(r, g, b)
    end
    return nil
end

-- Pending callbacks for configs still being fetched
fetchPending = {} -- [username] = {callback, ...}

-- Fetch nametag config from Cloudflare, non-blocking
local function fetchNametagConfig(username, callback)
    username = username:lower()
    local cached = nametagConfigs[username]
    -- Fully resolved already
    -- NOTE: "inactive" is NO LONGER treated as a valid cache hit here
    if cached and cached ~= "loading" and cached ~= "inactive" then
        callback(cached == "default" and getDefaultConfig() or cached)
        return
    end

    -- Already in-flight: queue the callback
    if cached == "loading" then
        fetchPending[username] = fetchPending[username] or {}
        table.insert(fetchPending[username], callback)
        return
    end

    -- Fresh fetch
    username = username:lower()
    nametagConfigs[username] = "loading"
    fetchPending[username] = fetchPending[username] or {}
    table.insert(fetchPending[username], callback)

    task.spawn(function()
        local fullUrl = WORKER_BASE .. "/get-nametag/" .. username
        local ok, result = pcall(function()
            return httpRequest({
                Url    = fullUrl,
                Method = "GET",
            })
        end)

        local resolved
        if ok and result then
            if result.StatusCode == 200 then
                local parsed
                ok, parsed = pcall(function()
                    return game:GetService("HttpService"):JSONDecode(result.Body)
                end)
                
                if ok and parsed then
                    local cfg = parsed.config or {}
                    local isSelf = username:lower() == plr.Name:lower()

                    -- Show tag if found in DB (registeredNames already gates active-only users before we get here)
                    if parsed.found then
                        local iconImgVal = (cfg.icon_image and cfg.icon_image ~= "") and cfg.icon_image or nil
                        local bgImgVal   = (cfg.image_url and cfg.image_url ~= "") and cfg.image_url or nil

                        resolved = {
                            displayName            = cfg.name_text or cfg.displayName or "Onyx User",
                            textColor              = hexToColor3(cfg.name_color or cfg.textColor) or Color3.fromRGB(240, 240, 240),
                            outlineColor           = hexToColor3(cfg.outline_color or cfg.glow_color or cfg.outlineColor) or Color3.fromRGB(255, 255, 255),
                            backgroundColor        = hexToColor3(cfg.tag_color or cfg.backgroundColor) or Color3.fromRGB(15, 15, 15),
                            backgroundTransparency = 0, -- Solid background
                            backgroundImage        = (cfg.image_url and cfg.image_url ~= "") and cfg.image_url or ((DEFAULT_BG_IMAGE ~= "") and DEFAULT_BG_IMAGE or nil),
                            iconImage              = (cfg.icon_image and cfg.icon_image ~= "") and cfg.icon_image or ((DEFAULT_ICON_IMAGE ~= "") and DEFAULT_ICON_IMAGE or nil),
                            glitchAnim             = (cfg.glitch_anim == true) or (cfg.glitchAnim == true),
                        }
                        nametagConfigs[username] = resolved
                    else
                        nametagConfigs[username] = "inactive"
                    end
                elseif not ok then
                    -- JSON decode failed silently
                end
            else
                -- HTTP Error silently ignored
            end
        else
            -- HTTP Request Failed silently
        end

        if not resolved then
            -- Only fallback to default for SELF. For others, we just don't show the tag.
            if username:lower() == plr.Name:lower() then
                resolved = getDefaultConfig()
                nametagConfigs[username] = resolved
            else
                nametagConfigs[username] = "inactive"
            end
        end

        -- Fire all pending callbacks
        local pending = fetchPending[username] or {}
        fetchPending[username] = nil
        for _, cb in ipairs(pending) do
            task.spawn(cb, resolved)
        end
    end)
end

-- Serial fetch queue: ensures only one HTTP request fires at a time
local fetchQueue = {}
local fetchQueueRunning = false

local function enqueueFetch(username, callback)
    -- Already cached (or loading) — bypass the queue
    -- NOTE: "inactive" is NOT treated as a valid cache hit so we always recheck
    -- players who haven't executed yet (they may have executed since last check)
    local lowerName = username:lower()
    
    local lowerName = username:lower()
    local cached = nametagConfigs[lowerName]
    if cached and cached ~= "loading" and cached ~= "inactive" then
        callback(cached == "default" and getDefaultConfig() or cached)
        return
    end

    table.insert(fetchQueue, { username = lowerName, callback = callback })

    if fetchQueueRunning then return end
    fetchQueueRunning = true

    task.spawn(function()
        while #fetchQueue > 0 do
            local item = table.remove(fetchQueue, 1)
            -- Only fetch if not already populated
            if nametagConfigs[item.username] and nametagConfigs[item.username] ~= "loading" and nametagConfigs[item.username] ~= "inactive" then
                local c = nametagConfigs[item.username]
                item.callback(c == "default" and getDefaultConfig() or c)
            else
                fetchNametagConfig(item.username, item.callback)
                task.wait(0.1) -- throttle: 100ms between fetches (was 500ms)
            end
        end
        fetchQueueRunning = false
    end)
end

-- Particle animation loop for cool background effects
local function startParticleAnimation(parentBg, particleColor)
    task.spawn(function()
        if not parentBg then return end
        -- CRITICAL: DO NOT set ClipsDescendants = true on parentBg!
        -- That would clip the icon and text container.
        -- Instead, use a dedicated clipping frame for particles only.
        local particleClip = Instance.new("Frame")
        particleClip.Name = "ParticleClip"
        particleClip.BackgroundTransparency = 1
        particleClip.Size = UDim2.new(1, 0, 1, 0)
        particleClip.ZIndex = 1
        particleClip.ClipsDescendants = true -- Clip ONLY particles, not icon/text
        particleClip.Parent = parentBg

        local particleContainer = Instance.new("Frame")
        particleContainer.Name = "Particles"
        particleContainer.BackgroundTransparency = 1
        particleContainer.Size = UDim2.new(1, 0, 1, 0)
        particleContainer.ZIndex = 1
        particleContainer.Parent = particleClip

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 14)
        c.Parent = particleContainer

        local rng = Random.new()
        
        while parentBg and parentBg.Parent do
            task.wait(rng:NextNumber(0.15, 0.4))
            if not parentBg or not parentBg.Parent then break end
            if not particleContainer or not particleContainer.Parent then break end

            local p = Instance.new("Frame")
            local size = rng:NextInteger(2, 6)
            p.Size = UDim2.new(0, size, 0, size)
            if typeof(particleColor) == "Color3" then
                p.BackgroundColor3 = particleColor
            else
                p.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
            end
            p.BackgroundTransparency = rng:NextNumber(0.3, 0.7)
            p.BorderSizePixel = 0
            p.Position = UDim2.new(rng:NextNumber(0, 1), 0, 1, size)
            p.ZIndex = 1
            
            local pc = Instance.new("UICorner")
            pc.CornerRadius = UDim.new(1, 0)
            pc.Parent = p
            
            p.Parent = particleContainer

            local lifetime = rng:NextNumber(1.5, 3.0)
            local targetY = rng:NextNumber(-0.2, 0.4)
            local targetX = p.Position.X.Scale + rng:NextNumber(-0.1, 0.1)

            local tween = TweenService:Create(p, TweenInfo.new(lifetime, Enum.EasingStyle.Linear), {
                Position = UDim2.new(targetX, 0, targetY, 0),
                BackgroundTransparency = 1
            })
            tween:Play()
            
            task.delay(lifetime, function()
                if p then p:Destroy() end
            end)
        end
    end)
end

-- Glitch animation loop (lightweight, optimized for performance)
local function startGlitchAnimation(parentBg)
    task.spawn(function()
        if not parentBg then return end
        
        local contentFrame = parentBg:FindFirstChild("Content")
        if not contentFrame then return end
        local textContainer = contentFrame:FindFirstChild("TextContainer")
        if not textContainer then return end

        local topLabel  = textContainer:FindFirstChild("DisplayName")
        local botLabel  = textContainer:FindFirstChild("Username")
        local icon      = contentFrame:FindFirstChild("Icon")
        local stroke    = parentBg:FindFirstChildOfClass("UIStroke")
        
        if not topLabel or not stroke then return end

        local rng = Random.new()

        -- Initial stagger so they don't all glitch at once
        task.wait(rng:NextNumber(0.5, 5.0))

        while parentBg and parentBg.Parent do
            -- Glitch rarely (every 6 to 15 seconds) to save resources
            task.wait(rng:NextNumber(6.0, 15.0))
            if not parentBg or not parentBg.Parent then break end

            -- Brief intense glitch burst
            for _ = 1, rng:NextInteger(3, 5) do
                if not parentBg or not parentBg.Parent then break end

                -- Aggressive jitter
                local offsetX = rng:NextInteger(-5, 5)
                local offsetY = rng:NextInteger(-3, 3)
                topLabel.Position = UDim2.new(0, offsetX, 0, offsetY)
                if icon then icon.Position = UDim2.new(0, offsetX/2, 0, offsetY/2) end

                -- Hyper flicker (Removed transparency flicker for better visibility)
                local glitchColors = {
                    Color3.fromRGB(255, 0, 80),  -- Cyber Pink
                    Color3.fromRGB(0, 255, 255), -- Electric Cyan
                    Color3.fromRGB(255, 255, 255) -- White flash
                }
                local chosenColor = glitchColors[rng:NextInteger(1, #glitchColors)]
                topLabel.TextStrokeColor3 = chosenColor
                stroke.Color = chosenColor
                
                task.wait(0.04)
            end

            -- Restore to normal
            if parentBg and parentBg.Parent then
                topLabel.Position         = UDim2.new(0, 0, 0, 0)
                if icon then icon.Position = UDim2.new(0, 0, 0, 0) end
                topLabel.TextTransparency = 0
                if icon then icon.ImageTransparency = 0 end
                if botLabel then botLabel.TextTransparency = 0 end
                local origColor = parentBg:GetAttribute("OriginalStrokeColor") or Color3.new(0,0,0)
                topLabel.TextStrokeColor3 = origColor
                stroke.Color = origColor
            end
        end
    end)
end

-- Format asset URLs for Decals/IDs
-- rbxassetid:// works for legacy assets (< ~1 trillion ID)
-- rbxthumb://type=Asset works for modern UGC catalog items (large IDs)
local function resolveAsset(url)
    if not url or url == "" then return nil end
    local sUrl = tostring(url):match("^%s*(.-)%s*$")
    -- Already a thumb URL: pass through
    if sUrl:find("rbxthumb://")   then return sUrl end
    if sUrl:find("rbxasset://")   then return sUrl end
    -- Extract numeric ID (handles rbxassetid://ID, CDN URLs, or raw numbers)
    local id
    if sUrl:find("rbxassetid://") then
        id = sUrl:match("rbxassetid://(%d+)")
    elseif sUrl:find("roblox%.com/asset") then
        id = sUrl:match("id=(%d+)")
    elseif sUrl:find("^https?://") then
        return sUrl  -- External URL: pass through
    else
        id = sUrl:match("^(%d+)$")
    end
    if id then
        -- UGC/catalog IDs (>= 12 digits) need rbxthumb to render as images
        -- Legacy asset IDs (< 12 digits) work fine with rbxassetid://
        if #id >= 12 then
            return "rbxthumb://type=Asset&id=" .. id .. "&w=420&h=420"
        else
            return "rbxassetid://" .. id
        end
    end
    return sUrl
end

-- Shared UI builder for the Pill tag design
local function buildPillTag(cfg, targetPlayer, parentGui, isSelf)
    local bg = isSelf and Instance.new("Frame") or Instance.new("TextButton")
    bg.Name                  = "Background"
    if isSelf then
        bg.AnchorPoint       = Vector2.new(0.5, 1)   -- anchor bottom-center for ScreenGui
        bg.Visible           = false                  -- Hidden until first Heartbeat positions it
        bg.Position          = UDim2.fromOffset(-9999, -9999) -- Off-screen until first frame
    else
        bg.Text              = ""
        bg.AutoButtonColor   = false
        bg.AnchorPoint       = Vector2.new(0.5, 0.5)
        bg.Position          = UDim2.new(0.5, 0, 0.5, 0)
        
        -- Click to Teleport: snap directly onto target
        bg.MouseButton1Click:Connect(function()
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local tChar = targetPlayer.Character
            local tHrp = tChar and tChar:FindFirstChild("HumanoidRootPart")
            if hrp and tHrp then
                -- Land right on top of them (same X/Z, +2 Y so we don't clip inside)
                hrp.CFrame = CFrame.new(tHrp.Position + Vector3.new(0, 2, 0))
                SendNotify("👑 Onyx", "Teleported to " .. targetPlayer.DisplayName, 2)
            end
        end)
    end
    if isSelf then
        bg.Size                  = UDim2.new(0, 48, 0, 48) -- Non-zero base size to prevent collapse
        bg.AutomaticSize         = Enum.AutomaticSize.XY
    else
        bg.Size                  = UDim2.new(0, 48, 0, 48) -- Non-zero base size to prevent collapse
        bg.AutomaticSize         = Enum.AutomaticSize.XY
    end
    
    bg.BackgroundColor3      = cfg.backgroundColor
    bg.BackgroundTransparency = cfg.backgroundTransparency
    bg.BorderSizePixel       = 0
    bg.ClipsDescendants      = false -- Ensure layout items aren't clipped
    bg.Parent                = parentGui

    -- Store original stroke color for glitch effect restoration
    bg:SetAttribute("OriginalStrokeColor", cfg.outlineColor)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = bg

    local stroke = Instance.new("UIStroke")
    stroke.Color     = cfg.outlineColor
    stroke.Thickness = 3 -- Increased from 2 to 3 for thicker outlines
    stroke.Transparency = 0.2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent    = bg
    
    if cfg.backgroundImage and cfg.backgroundImage ~= "" then
        local bgImage = Instance.new("ImageLabel")
        bgImage.Name = "BgImage"
        bgImage.Size = UDim2.new(1, 0, 1, 0)
        bgImage.BackgroundTransparency = 1
        bgImage.Image = resolveAsset(cfg.backgroundImage)
        bgImage.ScaleType = Enum.ScaleType.Crop
        bgImage.ZIndex = 0
        bgImage.Parent = bg
        local ic = Instance.new("UICorner")
        ic.CornerRadius = UDim.new(0, 14)
        ic.Parent = bgImage
    end

    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.BackgroundTransparency = 1
    contentFrame.Size = UDim2.new(0, 0, 0, 0)
    contentFrame.AutomaticSize = Enum.AutomaticSize.XY
    contentFrame.ZIndex = 50 -- Ensure it's above background particles
    contentFrame.ClipsDescendants = false
    contentFrame.Parent = bg

    local mainLayout = Instance.new("UIListLayout")
    mainLayout.FillDirection       = Enum.FillDirection.Horizontal
    mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    mainLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
    mainLayout.SortOrder           = Enum.SortOrder.LayoutOrder
    mainLayout.Padding             = UDim.new(0, 10)
    mainLayout.Parent              = contentFrame

    local uiPadding = Instance.new("UIPadding")
    uiPadding.PaddingLeft   = UDim.new(0, 8)
    uiPadding.PaddingRight  = UDim.new(0, 14)
    uiPadding.PaddingTop    = UDim.new(0, 5)
    uiPadding.PaddingBottom = UDim.new(0, 5)
    uiPadding.Parent = contentFrame

    local icon
    if cfg.iconImage and cfg.iconImage ~= "" then
        local resolvedIconUrl = resolveAsset(cfg.iconImage)
        icon = Instance.new("ImageLabel")
        icon.Name                   = "Icon"
        icon.Size                   = UDim2.new(0, 46, 0, 46) 
        icon.BackgroundTransparency = 1  -- Transparent background
        icon.Image                  = resolvedIconUrl
        icon.ImageTransparency      = 0
        icon.ImageColor3            = Color3.new(1, 1, 1)
        icon.ScaleType              = Enum.ScaleType.Crop
        icon.LayoutOrder            = 0
        icon.ZIndex                 = 250
        icon.Parent                 = contentFrame

        local iconCorner = Instance.new("UICorner")
        iconCorner.CornerRadius = UDim.new(0, 10)
        iconCorner.Parent = icon
    end

    local textContainer = Instance.new("Frame")
    textContainer.Name = "TextContainer"
    textContainer.BackgroundTransparency = 1
    textContainer.Size = UDim2.new(0, 0, 0, 0)
    textContainer.AutomaticSize = Enum.AutomaticSize.XY
    textContainer.LayoutOrder = 1
    textContainer.Parent = contentFrame

    local textLayout = Instance.new("UIListLayout")
    textLayout.FillDirection = Enum.FillDirection.Vertical
    textLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    textLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    textLayout.SortOrder = Enum.SortOrder.LayoutOrder
    textLayout.Padding = UDim.new(0, 0)
    textLayout.Parent = textContainer

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name                   = "DisplayName"
    nameLabel.Size                   = UDim2.new(0, 0, 0, 18)
    nameLabel.AutomaticSize         = Enum.AutomaticSize.X
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text                   = cfg.displayName
    nameLabel.Font                   = Enum.Font.GothamBold
    nameLabel.TextSize               = 16
    nameLabel.TextColor3             = cfg.textColor
    nameLabel.TextStrokeColor3       = cfg.outlineColor
    nameLabel.TextStrokeTransparency = 0.6
    nameLabel.TextXAlignment         = Enum.TextXAlignment.Left
    nameLabel.LayoutOrder            = 0
    nameLabel.ZIndex                 = 250
    nameLabel.Parent                 = textContainer

    local tagLabel = Instance.new("TextLabel")
    tagLabel.Name                   = "Username"
    tagLabel.Size                   = UDim2.new(0, 0, 0, 14)
    tagLabel.AutomaticSize         = Enum.AutomaticSize.X
    tagLabel.BackgroundTransparency = 1
    tagLabel.Text                   = "@" .. targetPlayer.Name
    tagLabel.Font                   = Enum.Font.Gotham
    tagLabel.TextSize               = 12
    tagLabel.TextColor3             = Color3.fromRGB(240, 240, 240)
    tagLabel.TextStrokeTransparency = 0.5
    tagLabel.TextStrokeColor3       = cfg.outlineColor
    tagLabel.TextXAlignment         = Enum.TextXAlignment.Left
    tagLabel.LayoutOrder            = 1
    tagLabel.ZIndex                 = 250
    tagLabel.Parent                 = textContainer

    -- Dynamic Shrinking Logic (LOD)
    task.spawn(function()
        local lastState = nil -- Initialize as nil to force immediate first run
        while bg and bg.Parent do
            local cam = workspace.CurrentCamera
            local targetPos = nil
            
            if isSelf then
                local head = targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head")
                if head then targetPos = head.Position end
            else
                if parentGui and parentGui.Adornee then
                    targetPos = parentGui.Adornee.Position
                end
            end
            
            if cam and targetPos then
                local dist = (cam.CFrame.Position - targetPos).Magnitude
                local isClose = dist < 85 -- Slightly increased threshold
                
                if isClose ~= lastState then
                    lastState = isClose
                    textContainer.Visible = isClose 
                    
                    if isClose then
                        corner.CornerRadius = UDim.new(0, 14) 
                        uiPadding.PaddingLeft = UDim.new(0, 8)
                        uiPadding.PaddingRight = UDim.new(0, 14)
                        uiPadding.PaddingTop = UDim.new(0, 5)
                        uiPadding.PaddingBottom = UDim.new(0, 5)
                        if icon then 
                            icon.Visible = true
                            icon.ZIndex = 200
                            icon.Size = UDim2.new(0, 46, 0, 46) 
                        end
                    else
                        corner.CornerRadius = UDim.new(0, 11) 
                        uiPadding.PaddingLeft = UDim.new(0, 5) 
                        uiPadding.PaddingRight = UDim.new(0, 5)
                        uiPadding.PaddingTop = UDim.new(0, 5)
                        uiPadding.PaddingBottom = UDim.new(0, 5)
                        if icon then 
                            icon.Visible = true 
                            icon.ZIndex = 200
                            icon.Size = UDim2.new(0, 36, 0, 36) 
                        end
                    end
                end
            end
            task.wait(0.2)
        end
    end)

    return bg, nameLabel, tagLabel, icon
end

-- Remove nametag for a given player (safe)
local function removeNametag(userId)
    local data = nametagObjects[userId]
    if data then
        if data.billboard  and data.billboard.Parent  then data.billboard:Destroy()      end
        if data.selfGui    and data.selfGui.Parent    then data.selfGui:Destroy()        end
        if data.renderConn                            then data.renderConn:Disconnect()  end
        nametagObjects[userId] = nil
        activeOnyxTagIds[userId] = nil
    end
end

-- Check if a stored nametag is still valid
local function isNametagValid(userId)
    local data = nametagObjects[userId]
    if not data then return false end
    
    if data.selfGui then
        if not data.selfGui.Parent then
            removeNametag(userId)
            return false
        end
        return true
    end
    
    if data.billboard then
        if not data.billboard.Parent then
            removeNametag(userId)
            return false
        end
        local adornee = data.billboard.Adornee
        if not adornee or not adornee.Parent then
            removeNametag(userId)
            return false
        end
        return true
    end
    
    return false
end

-- Build and return the nametag data object
local function buildNametag(targetPlayer, cfg)
    if not cfg or type(cfg) ~= "table" then return nil end
    
    local character = targetPlayer.Character
    if not character then return nil end

    local head = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
    if not head then return nil end

    local data = {}

    if targetPlayer == plr then
        local selfBillboard = Instance.new("BillboardGui")
        selfBillboard.Name            = "OnyxSelfTag"
        selfBillboard.Adornee         = head
        selfBillboard.Size            = UDim2.new(0, 300, 0, 80) -- Fixed size (AutomaticSize not valid on BillboardGui)
        selfBillboard.StudsOffset     = Vector3.new(0, 2.2, 0)
        selfBillboard.AlwaysOnTop     = true  -- Always visible through walls too
        selfBillboard.MaxDistance     = math.huge -- Never disappear on zoom out
        selfBillboard.LightInfluence  = 0
        selfBillboard.ClipsDescendants = false
        selfBillboard.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
        selfBillboard.ResetOnSpawn    = false
        selfBillboard.Enabled         = not GlobalHideNametags
        selfBillboard.Parent          = plr.PlayerGui

        local bg, nameLabel, tagLabel, imageLabel = buildPillTag(cfg, targetPlayer, selfBillboard, false)

        startParticleAnimation(bg, cfg.outlineColor)
        if cfg.glitchAnim then
            startGlitchAnimation(bg)
        end

        -- Store as selfGui for removeNametag compatibility
        data.selfGui    = selfBillboard
        data.bg         = bg
        data.nameLabel  = nameLabel
        data.tagLabel   = tagLabel
        data.nameBase   = cfg.displayName
        data.tagBase    = "@" .. targetPlayer.Name
        return data
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name            = "OnyxNametag_" .. targetPlayer.Name
    billboard.Adornee         = head
    billboard.Size            = UDim2.new(0, 300, 0, 80) -- Fixed size (AutomaticSize not valid on BillboardGui)
    billboard.StudsOffset     = Vector3.new(0, 2.2, 0)
    billboard.AlwaysOnTop     = true
    billboard.MaxDistance     = math.huge
    billboard.LightInfluence  = 0
    billboard.ClipsDescendants = false
    billboard.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    billboard.ResetOnSpawn    = false
    billboard.Enabled         = not GlobalHideNametags

    -- Fix: BillboardGui MUST NOT be a child of a ScreenGui
    local ok, coreGui = pcall(function() 
        if gethui then return gethui() end
        return game:GetService("CoreGui") 
    end)
    -- If no CoreGui access, attaching it to the target character itself is much more reliable than PlayerGui
    billboard.Parent = (ok and coreGui) and coreGui or character

    local bg, nameLabel, tagLabel, imageLabel = buildPillTag(cfg, targetPlayer, billboard, false)

    startParticleAnimation(bg, cfg.outlineColor)
    if cfg.glitchAnim then
        startGlitchAnimation(bg)
    end

    data.billboard = billboard
    data.bg        = bg
    data.nameLabel = nameLabel
    data.tagLabel  = tagLabel
    data.nameBase  = cfg.displayName
    data.tagBase   = "@" .. targetPlayer.Name
    return data
end

GLITCH_CHARS = {"!", "@", "#", "$", "%", "^", "&", "*", "~", "?", "/", "|", "Ξ", "Ω", "█", "▓", "▒"}

local function glitchText(original, intensity)
    if not original or original == "" then return "" end
    local chars = {}
    for i = 1, #original do
        if math.random() < intensity then
            chars[i] = GLITCH_CHARS[math.random(#GLITCH_CHARS)]
        else
            chars[i] = original:sub(i, i)
        end
    end
    return table.concat(chars)
end

task.spawn(function()
    local t = 0
    local GLITCH_INTERVAL = 0.08
    while true do
        task.wait(GLITCH_INTERVAL)
        -- Only proceed if window is focused or if physics rep is disabled
        if not UserInputService.WindowFocused then continue end
        t = t + GLITCH_INTERVAL
        for userId, data in pairs(nametagObjects) do
            local alive = false
            if data.selfGui then
                alive = data.selfGui.Parent ~= nil
            elseif data.billboard then
                alive = data.billboard.Parent ~= nil
            end

            if not alive then
                nametagObjects[userId] = nil
            else
                -- Subtle glitch: only scramble if glitchAnim is enabled, keep intensity very low
                local intensity = math.max(0, math.sin(t * math.pi) * 0.06) -- Max 6% chars scrambled
                if math.random() < 0.02 then intensity = math.random() * 0.12 end -- Rare spike to 12%

                if data.nameLabel and data.nameLabel.Parent and data.nameBase then
                    data.nameLabel.Text = glitchText(data.nameBase, intensity)
                end
                if data.tagLabel and data.tagLabel.Parent and data.tagBase then
                    data.tagLabel.Text = glitchText(data.tagBase, intensity * 0.3)
                end

                if data.bg then
                    local st = data.bg:FindFirstChildOfClass("UIStroke")
                    if st then
                        -- Thicker feeling pulse
                        st.Transparency = 0.1 + math.sin(t * 3) * 0.45
                    end
                end
            end
        end
    end
end)

-- Create (or recreate) the nametag for a target player
local function applyNametag(targetPlayer)
    
    -- Local player must have executed to see anything
    if not plr:GetAttribute("OnyxActive") then 
        plr:SetAttribute("OnyxActive", true)
    end

    local userId = targetPlayer.UserId
    removeNametag(userId)

    enqueueFetch(targetPlayer.Name, function(cfg)
        -- Re-check after async fetch in case player left
        if targetPlayer ~= plr then
            if not targetPlayer or not targetPlayer.Parent then 
                return 
            end
        end
        if not targetPlayer.Character then 
            return 
        end

        local nametagData = buildNametag(targetPlayer, cfg)
        if not nametagData then 
            return 
        end

        nametagObjects[userId] = nametagData
        if targetPlayer ~= plr then activeOnyxTagIds[userId] = true end
        local adornee = nil
        if nametagData.billboard then adornee = nametagData.billboard.Adornee end
        if adornee then
            adornee.AncestryChanged:Connect(function(_, newParent)
                if not newParent then
                    removeNametag(userId)
                end
            end)
        end
    end)
end

-- Apply self-nametag immediately (so you can see your own tag)
local function applySelfNametag()
    if not plr.Character then return end
    applyNametag(plr)
end

local function processActiveUsers(activeSet)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= plr then
            local name = p.Name:lower()
            local isActive = activeSet[name] ~= nil
            local cached = nametagConfigs[name]
            local tagValid = isNametagValid(p.UserId)
            
            if isActive and not tagValid then
                -- Newly active, or tag got orphaned — (re)apply if character is loaded
                if cached ~= "loading" then
                    if p.Character and p.Character:FindFirstChild("Head") then
                        applyNametag(p)
                    else
                        -- Quietly wait for character load
                    end
                end
            elseif not isActive then
                -- Player not in current server metadata. 
                -- We no longer explicitly remove them here because it causes flickering/disappearance 
                -- if the heartbeat list is truncated or the request hits a different backend.
                -- PlayerRemoving will handle actual cleanup.
            end
        end
    end
end

task.spawn(function()
    task.wait(1.5)
    applySelfNametag()
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
    removeNametag(leavingPlayer.UserId)
    nametagConfigs[leavingPlayer.Name] = nil  -- clear cache so fresh data on rejoin
end)

plr.CharacterAdded:Connect(function()
    task.wait(1.0)
    plr:SetAttribute("OnyxActive", true)
    applySelfNametag() 
    
    -- Instant poll of everyone else (Fix: removed duplicate applySelfNametag)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= plr then pollPlayer(p) end
    end
end)

SendNotify("Onyx", "Nametag system active", 3)

task.spawn(function()
    while true do
        pcall(function()
            httpRequest({
                Url    = WORKER_BASE .. "/register-onyx-user",
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body   = game:GetService("HttpService"):JSONEncode({
                    roblox_user = plr.Name,
                    job_id      = game.JobId
                })
            })
        end)
        task.wait(10) -- Less aggressive heartbeat
    end
end)

pollPlayer = function(p)
    if not p or p == plr then return end
    local name = p.Name:lower()

    -- registeredNames is filtered server-side to heartbeat within last 2 minutes,
    -- so this is the only gate needed: are they running Onyx right now?
    if not registeredNames[name] then
        removeNametag(p.UserId)
        return
    end

    enqueueFetch(p.Name, function(cfg)
        if not cfg or cfg == "inactive" then
            removeNametag(p.UserId)
            return
        end
        if isNametagValid(p.UserId) then return end

        -- Wait for character + Head to be ready (async fetch may have completed before char loaded)
        task.spawn(function()
            local deadline = tick() + 10
            while tick() < deadline do
                local char = p.Character
                if char and (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")) then
                    if not isNametagValid(p.UserId) then
                        local nametagData = buildNametag(p, cfg)
                        if nametagData then
                            removeNametag(p.UserId)
                            nametagObjects[p.UserId] = nametagData
                            activeOnyxTagIds[p.UserId] = true
                            -- Auto-cleanup when adornee is removed
                            local adornee = nametagData.billboard and nametagData.billboard.Adornee
                            if adornee then
                                adornee.AncestryChanged:Connect(function(_, newParent)
                                    if not newParent then removeNametag(p.UserId) end
                                end)
                            end
                        else
                        end
                    end
                    return
                end
                task.wait(0.5)
            end
        end)
    end)
end

-- Monitor and Poll Loop
local function monitorAndPoll(p)
    if p == plr then return end

    -- Initial poll — registeredNames may not have loaded yet, but the
    -- refreshDiscoveryList loop runs every 8s and will catch them shortly.
    pollPlayer(p)

    -- Re-poll every 10s in case they just executed (heartbeat takes up to 10s to register)
    task.spawn(function()
        while p and p.Parent do
            task.wait(10)
            local lowerName = p.Name:lower()
            if nametagConfigs[lowerName] ~= "loading" then
                nametagConfigs[lowerName] = nil
            end
            pollPlayer(p)
        end
    end)

    -- Re-apply tag on respawn
    p.CharacterAdded:Connect(function()
        task.wait(1.5)
        local lowerName = p.Name:lower()
        if nametagConfigs[lowerName] ~= "loading" then
            nametagConfigs[lowerName] = nil
        end
        pollPlayer(p)
    end)
end

-- All functions now defined — wire up the discovery callback and start the loop
onDiscovery = function(usernames)
    local names = {}
    for _, name in ipairs(usernames) do
        names[name:lower()] = true
    end
    registeredNames = names
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= plr then
            local lowerName = p.Name:lower()
            if registeredNames[lowerName] then
                if not isNametagValid(p.UserId) then
                    task.spawn(function() pollPlayer(p) end)
                end
            else
                removeNametag(p.UserId)
                nametagConfigs[lowerName] = nil
            end
        end
    end
end

refreshDiscoveryList() -- Initial fetch immediately
task.spawn(function()
    while true do
        task.wait(8)
        refreshDiscoveryList()
    end
end)

for _, p in ipairs(Players:GetPlayers()) do
    monitorAndPoll(p)
end
Players.PlayerAdded:Connect(monitorAndPoll)
end
task.spawn(setupOnyxNametags)

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SYSTEM — CLICK-TO-TELEPORT (Onyx users only)                ║
-- ╚══════════════════════════════════════════════════════════════╝
-- =====================================================
-- CLICK-TO-TELEPORT: ONYX NAMETAG USERS ONLY
-- Screen-space click detection — BillboardGui TextButton clicks are
-- unreliable when parented to CoreGui, so we handle it here instead.
-- Only teleports if the target player has an active Onyx nametag.
-- =====================================================
do
    local CLICK_RADIUS_PX = 55

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if gameProcessed then return end

        local cam = workspace.CurrentCamera
        if not cam then return end

        local mousePos = UserInputService:GetMouseLocation()
        local closestPlayer = nil
        local closestDist   = CLICK_RADIUS_PX

        for _, p in ipairs(Players:GetPlayers()) do
            if p == plr then continue end
            -- Only consider players with an active Onyx nametag
            if not activeOnyxTagIds[p.UserId] then continue end

            local char = p.Character
            if not char then continue end
            local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
            if not head then continue end

            local worldPos = head.Position + Vector3.new(0, 2.5, 0)
            local screenPos, onScreen = cam:WorldToViewportPoint(worldPos)
            if not onScreen then continue end

            local dx = screenPos.X - mousePos.X
            local dy = screenPos.Y - mousePos.Y
            local dist = math.sqrt(dx*dx + dy*dy)

            if dist < closestDist then
                closestDist   = dist
                closestPlayer = p
            end
        end

        if closestPlayer then
            local char = plr.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            local tChar = closestPlayer.Character
            local tHrp  = tChar and tChar:FindFirstChild("HumanoidRootPart")
            if hrp and tHrp then
                hrp.CFrame = tHrp.CFrame * CFrame.new(0, 2, 0)
                SendNotify("⚡ Teleport", "Jumped to " .. closestPlayer.DisplayName, 2)
            end
        end
    end)
end
-- =====================================================

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SYSTEM — CHAT COMMAND SYSTEM                                ║
-- ╚══════════════════════════════════════════════════════════════╝
-- =====================================================
-- CHAT COMMAND SYSTEM + COMMAND LIST UI
-- =====================================================

-- Commands table: declared here (chunk level) so both initCommandSystems and
-- onChat (defined later in same scope) share the same upvalue.
Commands = {}

local function initCommandSystems()
local allCommands = {
    -- Player / Target
    { cmd = ".view",        desc = "View target" },
    { cmd = ".tp [name]",   desc = "Teleport to target or named player" },
    { cmd = ".bring",       desc = "Bring target to you" },
    { cmd = ".spectate",    desc = "Spectate target" },
    { cmd = ".focus",       desc = "Loop TP to target" },
    { cmd = ".headsit",     desc = "Sit on target's head" },
    { cmd = ".backpack",    desc = "Backpack mode on target" },
    { cmd = ".cleartarget", desc = "Clear target" },
    -- Combat
    { cmd = ".esp",         desc = "Toggle ESP" },
    { cmd = ".aimlock",     desc = "Toggle Aimlock" },
    -- Animation
    { cmd = ".emotes",      desc = "Open Emote Menu" },
    -- Visual
    { cmd = ".shaders",     desc = "Load Shaders" },
    -- Misc
    { cmd = ".antivcb",     desc = "Open Anti VC Ban" },
    { cmd = ".facebang",    desc = "Open Face Bang" },
    { cmd = ".teleport",    desc = "Toggle Click Teleport" },
    { cmd = ".baseplate",   desc = "Toggle Infinite Baseplate" },
    { cmd = ".timereverse", desc = "Toggle Time Reverse" },
    { cmd = ".trip",        desc = "Toggle Trip" },
    { cmd = ".fly",         desc = "Toggle Superman Fly" },
    { cmd = ".char [name]", desc = "Clone player char (reset to undo)" },
    { cmd = ".minimize",    desc = "Toggle Minimize GUI" },
    { cmd = ".rj",          desc = "Rejoin same server" },
    { cmd = ".cmds",        desc = "Show/hide Command List" },
    { cmd = ".antivoid",    desc = "Toggle Anti-Void" },
    { cmd = ".hide [name]",  desc = "Hide player visuals/audio" },
    { cmd = ".unhide [p]",   desc = "Unhide player" },
    { cmd = ".re",           desc = "Respawn in place" },
    { cmd = ".unheadsit",    desc = "Stop HeadSit mode" },
    { cmd = ".unbackpack",   desc = "Stop Backpack mode" },
}

-- Build the command list window
local function buildCommandListUI()
CmdListFrame = Instance.new("Frame")
CmdListFrame.Name = "OnyxCmdList"
CmdListFrame.Parent = OnyxUI
CmdListFrame.AnchorPoint = Vector2.new(0.5, 0.5)
CmdListFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
CmdListFrame.Size = UDim2.new(0, 300, 0, 380)
CmdListFrame.BackgroundColor3 = Color3.fromRGB(9, 9, 18)
CmdListFrame.BackgroundTransparency = 0.08
CmdListFrame.BorderSizePixel = 0
CmdListFrame.Visible = false
CmdListFrame.ZIndex = 30
CmdListFrame.Active = true
do
    Instance.new("UICorner", CmdListFrame).CornerRadius = UDim.new(0, 14)
    local s = Instance.new("UIStroke", CmdListFrame); s.Color = Color3.fromRGB(255,255,255); s.Transparency = 0.82; s.Thickness = 1.2
    local ov = Instance.new("Frame", CmdListFrame); ov.BackgroundColor3 = Color3.fromRGB(185,195,255); ov.BackgroundTransparency = 0.96
    ov.BorderSizePixel = 0; ov.Size = UDim2.new(1,0,1,0); ov.ZIndex = 30
    Instance.new("UICorner", ov).CornerRadius = UDim.new(0,14)
    local bar = Instance.new("Frame", CmdListFrame); bar.BackgroundColor3 = Color3.fromRGB(140,130,255)
    bar.BorderSizePixel = 0; bar.Size = UDim2.new(1,0,0,3); bar.ZIndex = 31
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0,14)
end

-- Title bar
CmdTitleBar = Instance.new("Frame")
CmdTitleBar.Parent = CmdListFrame; CmdTitleBar.BackgroundTransparency = 1
CmdTitleBar.Size = UDim2.new(1,0,0,38); CmdTitleBar.ZIndex = 31

CmdTitleLbl = Instance.new("TextLabel")
CmdTitleLbl.Parent = CmdTitleBar; CmdTitleLbl.BackgroundTransparency = 1
CmdTitleLbl.Position = UDim2.new(0,14,0,0); CmdTitleLbl.Size = UDim2.new(1,-50,1,0)
CmdTitleLbl.Font = Enum.Font.GothamBold; CmdTitleLbl.Text = "⌨️  Command List"
CmdTitleLbl.TextColor3 = Color3.fromRGB(255,255,255); CmdTitleLbl.TextSize = 14
CmdTitleLbl.TextXAlignment = Enum.TextXAlignment.Left; CmdTitleLbl.ZIndex = 32

CmdCloseBtn = Instance.new("TextButton", CmdTitleBar); CmdCloseBtn.AnchorPoint = Vector2.new(1,0.5)
CmdCloseBtn.Position = UDim2.new(1,-10,0.5,0); CmdCloseBtn.Size = UDim2.new(0,24,0,24)
CmdCloseBtn.BackgroundColor3 = Color3.fromRGB(255,255,255); CmdCloseBtn.BackgroundTransparency = 0.88
CmdCloseBtn.BorderSizePixel = 0; CmdCloseBtn.Font = Enum.Font.GothamBold
CmdCloseBtn.Text = "×"; CmdCloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
CmdCloseBtn.TextSize = 16; CmdCloseBtn.ZIndex = 32; CmdCloseBtn.AutoButtonColor = false
Instance.new("UICorner", CmdCloseBtn).CornerRadius = UDim.new(0,7)
CmdCloseBtn.MouseButton1Click:Connect(function() CmdListFrame.Visible = false end)

divLine = Instance.new("Frame", CmdListFrame)
divLine.BackgroundColor3 = Color3.fromRGB(255,255,255)
divLine.BackgroundTransparency = 0.88
divLine.BorderSizePixel = 0
divLine.Position = UDim2.new(0,12,0,38)
divLine.Size = UDim2.new(1,-24,0,1)
divLine.ZIndex = 31

-- Scroll area
CmdScroll = Instance.new("ScrollingFrame")
CmdScroll.Parent = CmdListFrame; CmdScroll.Position = UDim2.new(0,0,0,44)
CmdScroll.Size = UDim2.new(1,0,1,-44); CmdScroll.BackgroundTransparency = 1
CmdScroll.BorderSizePixel = 0; CmdScroll.ScrollBarThickness = 3
CmdScroll.ScrollBarImageColor3 = Color3.fromRGB(140,130,255); CmdScroll.ZIndex = 31
CmdScroll.CanvasSize = UDim2.new(0,0,0,0); CmdScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

CmdListLayout = Instance.new("UIListLayout", CmdScroll)
CmdListLayout.SortOrder = Enum.SortOrder.LayoutOrder; CmdListLayout.Padding = UDim.new(0,3)
CmdListPad = Instance.new("UIPadding", CmdScroll)
CmdListPad.PaddingLeft = UDim.new(0,10); CmdListPad.PaddingRight = UDim.new(0,10)
CmdListPad.PaddingTop = UDim.new(0,6); CmdListPad.PaddingBottom = UDim.new(0,6)

for i, entry in ipairs(allCommands) do
    local row = Instance.new("Frame", CmdScroll)
    row.BackgroundColor3 = Color3.fromRGB(255,255,255); row.BackgroundTransparency = 0.93
    row.BorderSizePixel = 0; row.Size = UDim2.new(1,0,0,36); row.LayoutOrder = i; row.ZIndex = 32
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,7)

    local cmdL = Instance.new("TextLabel", row); cmdL.BackgroundTransparency = 1
    cmdL.Position = UDim2.new(0,8,0,2); cmdL.Size = UDim2.new(0.5,-8,0,17)
    cmdL.Font = Enum.Font.GothamBold; cmdL.Text = entry.cmd
    cmdL.TextColor3 = Color3.fromRGB(180,170,255); cmdL.TextSize = 12
    cmdL.TextXAlignment = Enum.TextXAlignment.Left; cmdL.ZIndex = 33

    local descL = Instance.new("TextLabel", row); descL.BackgroundTransparency = 1
    descL.Position = UDim2.new(0,8,0,19); descL.Size = UDim2.new(1,-16,0,13)
    descL.Font = Enum.Font.Gotham; descL.Text = entry.desc
    descL.TextColor3 = Color3.fromRGB(130,130,165); descL.TextSize = 10
    descL.TextXAlignment = Enum.TextXAlignment.Left; descL.ZIndex = 33
end

-- Dragging for cmd list window
do
    local dragging, dragStart, startPos
    CmdTitleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = inp.Position; startPos = CmdListFrame.Position
            inp.Changed:Connect(function() if inp.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - dragStart
            CmdListFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
        end
    end)
end

-- Wire up the Commands button in Misc tab
CommandsButton.MouseButton1Click:Connect(function()
    CmdListFrame.Visible = not CmdListFrame.Visible
end)

return CmdListFrame
end
CmdListFrame = buildCommandListUI()
-- =====================================================
Commands = {}  -- reset/populate the outer Commands table
local function RegisterCommand(names, callback, category)
    if type(names) == "string" then names = {names} end
    for _, name in ipairs(names) do
        Commands[name:lower()] = {
            Callback = callback,
            Category = category or "Misc"
        }
    end
end

-- Migrate all existing logic to the new system
RegisterCommand({"view"}, function(argLine)
    local target = argLine ~= "" and GetPlayer(argLine) or GetPlayer(TargetNameInput.Text)
    if target then
        local char = GetCharacter(target)
        if char then workspace.CurrentCamera.CameraSubject = char:FindFirstChildOfClass("Humanoid") end
        TargetedPlayer = target.Name; TargetNameInput.Text = target.Name
        SendNotify("View", "Viewing " .. target.DisplayName, 2)
    else SendNotify("Command", "Player not found", 2) end
end, "Visual")

RegisterCommand({"tp"}, function(argLine)
    local target = argLine ~= "" and GetPlayer(argLine) or GetPlayer(TargetNameInput.Text)
    if target then
        TeleportTO(target)
        SendNotify("Teleport", "Teleported to " .. target.DisplayName, 2)
    else SendNotify("Command", "Player not found", 2) end
end, "Movement")

RegisterCommand({"bring"}, function(argLine)
    local target = argLine ~= "" and GetPlayer(argLine) or GetPlayer(TargetNameInput.Text)
    if target then
        local root = GetRoot(target)
        local myRoot = GetRoot(plr)
        if root and myRoot then root.CFrame = myRoot.CFrame * CFrame.new(0, 0, -3) end
        SendNotify("Bring", "Brought " .. target.DisplayName, 2)
    else SendNotify("Command", "Player not found", 2) end
end, "Combat")

RegisterCommand({"spectate"}, function(argLine)
    local target = argLine ~= "" and GetPlayer(argLine) or (TargetedPlayer and Players:FindFirstChild(TargetedPlayer))
    if not target and argLine == "" then target = GetPlayer(TargetNameInput.Text) end
    if target then
        SpectatingTarget = not SpectatingTarget
        if SpectatingTarget then
            pcall(function()
                local hum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
                if hum then workspace.CurrentCamera.CameraSubject = hum end
            end)
            SendNotify("Spectate", "Now spectating " .. target.DisplayName, 2)
        else
            pcall(function()
                local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
                if hum then workspace.CurrentCamera.CameraSubject = hum end
            end)
            SendNotify("Spectate", "Stopped", 2)
        end
    else SendNotify("Command", "Player not found", 2) end
end, "Visual")

RegisterCommand({"focus"}, function(argLine)
    local target = argLine ~= "" and GetPlayer(argLine) or (TargetedPlayer and Players:FindFirstChild(TargetedPlayer))
    if not target and argLine == "" then target = GetPlayer(TargetNameInput.Text) end
    if target then
        FocusingTarget = not FocusingTarget
        if FocusingTarget then
            TargetedPlayer = target.Name; TargetNameInput.Text = target.Name
            FocusButton.Text = "🎯 Stop Focus"
            SendNotify("Focus", "Looping TP to " .. target.DisplayName, 2)
            task.spawn(function()
                while FocusingTarget do
                    if not target or not target.Parent then FocusingTarget = false; break end
                    TeleportTO(target)
                    task.wait(0.1)
                end
                FocusButton.Text = "🎯 Focus Target (Loop TP)"; FocusButton.BackgroundTransparency = 0.9
            end)
            FocusButton.BackgroundTransparency = 0.7
        else
            FocusButton.Text = "🎯 Focus Target (Loop TP)"; FocusButton.BackgroundTransparency = 0.9
            SendNotify("Focus", "Stopped", 2)
        end
    else SendNotify("Command", "Player not found", 2) end
end, "Movement")

RegisterCommand({"headsit"}, function(argLine)
    local target = argLine ~= "" and GetPlayer(argLine) or (TargetedPlayer and Players:FindFirstChild(TargetedPlayer))
    if not target and argLine == "" then target = GetPlayer(TargetNameInput.Text) end
    if target then
        if ZeroDelayEnabled and zeroDelayMode == "headsit" then
            StopZeroDelay(); HeadSitButton.Text = "🪑 Sit on Head"; HeadSitButton.BackgroundTransparency = 0.91
        else
            StartZeroDelay(target, "headsit"); HeadSitButton.Text = "🪑 Stop HeadSit"; HeadSitButton.BackgroundTransparency = 0.7
        end
    else SendNotify("Command", "Player not found", 2) end
end, "Misc")

RegisterCommand({"backpack"}, function(argLine)
    local target = argLine ~= "" and GetPlayer(argLine) or (TargetedPlayer and Players:FindFirstChild(TargetedPlayer))
    if not target and argLine == "" then target = GetPlayer(TargetNameInput.Text) end
    if target then
        if ZeroDelayEnabled and zeroDelayMode == "backpack" then
            StopZeroDelay(); BackpackButton.Text = "🎒 Backpack Mode"; BackpackButton.BackgroundTransparency = 0.91
        else
            StartZeroDelay(target, "backpack"); BackpackButton.Text = "🎒 Stop Backpack"; BackpackButton.BackgroundTransparency = 0.7
        end
    else SendNotify("Command", "Player not found", 2) end
end, "Misc")

RegisterCommand({"re"}, function()
    local char = plr.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then SendNotify("Respawn", "No character found", 2) return end

    local savedCFrame = hrp.CFrame

    -- Hook CharacterAdded BEFORE triggering the respawn so we never miss it
    local conn
    conn = plr.CharacterAdded:Connect(function(newChar)
        conn:Disconnect()
        -- Wait for HumanoidRootPart to exist and the character to fully load
        local newHrp = newChar:WaitForChild("HumanoidRootPart", 10)
        if newHrp then
            -- Wait one more frame so Roblox doesn't override our CFrame on spawn
            task.wait(0.15)
            newHrp.CFrame = savedCFrame
        end
    end)

    -- Kill the humanoid — this triggers a server-side respawn reliably
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Health = 0
    else
        -- Fallback: try LoadCharacter
        pcall(function() plr:LoadCharacter() end)
    end

    SendNotify("Respawn", "Respawned in place", 2)
end, "Misc")

RegisterCommand({"unheadsit"}, function()
    if ZeroDelayEnabled and zeroDelayMode == "headsit" then
        StopZeroDelay()
        pcall(function() HeadSitButton.Text = "🪑 Sit on Head"; HeadSitButton.BackgroundTransparency = 0.91 end)
        SendNotify("HeadSit", "HeadSit stopped", 2)
    else
        SendNotify("HeadSit", "Not currently in HeadSit mode", 2)
    end
end, "Misc")

RegisterCommand({"unbackpack"}, function()
    if ZeroDelayEnabled and zeroDelayMode == "backpack" then
        StopZeroDelay()
        pcall(function() BackpackButton.Text = "🎒 Backpack Mode"; BackpackButton.BackgroundTransparency = 0.91 end)
        SendNotify("Backpack", "Backpack mode stopped", 2)
    else
        SendNotify("Backpack", "Not currently in Backpack mode", 2)
    end
end, "Misc")

RegisterCommand({"cleartarget"}, function()
    UpdateTarget(nil); SendNotify("Command", "Target cleared", 2)
end, "Misc")

RegisterCommand({"esp"}, function()
    ESPEnabled = not ESPEnabled
    if ESPEnabled then
        ESPButton.Text = "👁️ ESP: ON"; ESPButton.BackgroundTransparency = 0.7; SendNotify("ESP", "Enabled", 2)
    else
        ESPButton.Text = "👁️ ESP: OFF"; ESPButton.BackgroundTransparency = 0.9
        for _, d in pairs(espObjects) do
            if d.box then d.box:Destroy() end
            if d.nameLabel then d.nameLabel:Destroy() end
            if d.distanceLabel then d.distanceLabel:Destroy() end
            if d.healthBar then d.healthBar:Destroy() end
        end
        espObjects = {}; SendNotify("ESP", "Disabled", 2)
    end
end, "Combat")

RegisterCommand({"aimlock"}, function()
    AimlockEnabled = not AimlockEnabled
    if AimlockEnabled then
        AimlockButton.Text = "🎯 Aimlock: ON"; AimlockButton.BackgroundTransparency = 0.7; SendNotify("Aimlock", "Enabled", 2)
    else
        AimlockButton.Text = "🎯 Aimlock: OFF"; AimlockButton.BackgroundTransparency = 0.9; SendNotify("Aimlock", "Disabled", 2)
    end
end, "Combat")

RegisterCommand({"emotes"}, function() ToggleEmoteMenu() end, "Animation")
RegisterCommand({"shaders"}, function() ShadersButton.MouseButton1Click:Fire() end, "Visual")
RegisterCommand({"antivcb"}, function()
    AntiVCButton.MouseButton1Click:Fire()
end, "Misc")

RegisterCommand({"facebang"}, function() FaceBangWindow.Visible = not FaceBangWindow.Visible end, "Misc")

RegisterCommand({"teleport"}, function()
    ClickTeleportEnabled = not ClickTeleportEnabled
    if ClickTeleportEnabled then
        ClickTeleportButton.Text = "📍 Click Teleport (F): ON"; ClickTeleportButton.BackgroundTransparency = 0.7; SendNotify("Click Teleport", "Enabled", 2)
    else
        ClickTeleportButton.Text = "📍 Click Teleport (F): OFF"; ClickTeleportButton.BackgroundTransparency = 0.9; SendNotify("Click Teleport", "Disabled", 2)
    end
end, "Movement")

RegisterCommand({"baseplate"}, function() InfiniteBaseplateButton.MouseButton1Click:Fire() end, "Misc")

RegisterCommand({"timereverse"}, function()
    TimeReverseEnabled = not TimeReverseEnabled
    if TimeReverseEnabled then
        TimeReverseButton.Text = "⏮️ Time Reverse (C): ON"; TimeReverseButton.BackgroundTransparency = 0.7; SendNotify("Time Reverse", "Enabled", 2)
    else
        TimeReverseEnabled = false; TimeReverseButton.Text = "⏮️ Time Reverse (C): OFF"; TimeReverseButton.BackgroundTransparency = 0.9; SendNotify("Time Reverse", "Disabled", 2)
    end
end, "Movement")

RegisterCommand({"trip"}, function()
    TripEnabled = not TripEnabled
    if TripEnabled then
        TripButton.Text = "🤸 Trip (T): ON"; TripButton.BackgroundTransparency = 0.7; SendNotify("Trip", "Enabled", 2)
    else
        TripButton.Text = "🤸 Trip (T): OFF"; TripButton.BackgroundTransparency = 0.9; SendNotify("Trip", "Disabled", 2)
    end
end, "Movement")

RegisterCommand({"fly", "superman"}, function()
    if SupermanFlyEnabled then
        stopSupermanFly()
        SendNotify("Superman Fly", "Disabled", 2)
    else
        startSupermanFly()
        SendNotify("Superman Fly", "Enabled — WASD · Space/Ctrl · Shift boost", 3)
    end
end, "Movement")

RegisterCommand({"char"}, function(argLine)
    if argLine == "" or argLine:lower() == "reset" or argLine:lower() == "off" then
        resetCharClone()
    else
        local target = GetPlayer(argLine)
        if target then
            doCharClone(target)
        else
            SendNotify("Char Clone", "Player not found: " .. argLine, 2)
        end
    end
end, "Player")

RegisterCommand({"minimize"}, function() MinimizeButton.MouseButton1Click:Fire() end, "Misc")
RegisterCommand({"rj", "rejoin"}, function()
    pcall(function() game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, plr) end)
end, "Misc")

RegisterCommand({"cmds", "commands"}, function() CmdListFrame.Visible = not CmdListFrame.Visible end, "Misc")
RegisterCommand({"antivoid"}, function()
    AntiVoidEnabled = not AntiVoidEnabled; SendNotify("Anti-Void", (AntiVoidEnabled and "Enabled" or "Disabled"), 2)
end, "Misc")

RegisterCommand({"hide"}, function(argLine)
    local target = argLine ~= "" and GetPlayer(argLine) or (TargetedPlayer and Players:FindFirstChild(TargetedPlayer))
    if target then
        hidePlayer(target)
    else SendNotify("Command", "Player not found", 2) end
end, "Misc")

RegisterCommand({"unhide"}, function(argLine)
    local target = argLine ~= "" and GetPlayer(argLine) or (TargetedPlayer and Players:FindFirstChild(TargetedPlayer))
    if target then
        unhidePlayer(target)
    else SendNotify("Command", "Player not found", 2) end
end, "Misc")

-- Chat command handler
onChat = function(msg)
    if not msg or msg == "" then return end
    
    -- Strip whitespace and handle common prefixes
    msg = msg:match("^%s*(.-)%s*$")
    
    -- Handle common Roblox prefixes that can wrap commands
    if msg:sub(1,3):lower() == "/e " then
        msg = msg:sub(4)
    elseif msg:sub(1,1) == "/" then
        msg = msg:sub(2)
    end
    
    -- Check for prefix '.'
    if not msg:match("^%.") then return end
    
    local parts = msg:split(" ")
    if #parts == 0 then return end
    
    local cmdName = parts[1]:sub(2):lower()
    local argLine = msg:sub(#parts[1] + 2):match("^%s*(.-)%s*$") or ""
    
    local cmd = Commands[cmdName]
    if cmd then
        local success, err = pcall(function() cmd.Callback(argLine) end)
        if not success then 
            SendNotify("Onyx Error", "Cmd: " .. cmdName .. "\nErr: " .. tostring(err), 3)
        end
    end
end

-- Hook chat — covers both legacy (Chatted) and modern (TextChatService) Roblox
chatHooked = false

-- METHOD 1: Modern TextChatService — hook WillSendTextChannelMessage on the general channel
-- This fires BEFORE the message is sent, capturing our own messages reliably
pcall(function()
    local TCS = game:GetService("TextChatService")
    if TCS and TCS.ChatVersion == Enum.ChatVersion.TextChatService then
        -- Hook MessageReceived on ALL TextChannels (fires for own messages too on some games)
        local function hookChannel(channel)
            pcall(function()
                channel.WillSendTextChannelMessage:Connect(function(msgObj)
                    onChat(msgObj.Text)
                end)
            end)
            -- Also hook ShouldDeliverCallback alternative path
            pcall(function()
                channel.MessageReceived:Connect(function(msgObj)
                    if msgObj.TextSource and msgObj.TextSource.UserId == plr.UserId then
                        onChat(msgObj.Text)
                    end
                end)
            end)
        end

        -- Hook existing channels
        local channels = TCS:FindFirstChild("TextChannels")
        if channels then
            for _, ch in ipairs(channels:GetChildren()) do
                if ch:IsA("TextChannel") then hookChannel(ch) end
            end
            channels.ChildAdded:Connect(function(ch)
                if ch:IsA("TextChannel") then hookChannel(ch) end
            end)
        end

        -- Fallback: top-level MessageReceived (fires for messages WE receive, not always ours)
        TCS.MessageReceived:Connect(function(msgObj)
            if msgObj.TextSource and msgObj.TextSource.UserId == plr.UserId then
                onChat(msgObj.Text)
            end
        end)

        chatHooked = true
    end
end)

-- METHOD 2: Legacy Chatted event (works in Legacy Chat and some TextChatService games)
pcall(function()
    plr.Chatted:Connect(onChat)
end)

SendNotify("Onyx", "Chat commands hooked", 3)

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SYSTEM — OWNER COMMANDS (USERNAME RESTRICTED)               ║
-- ╚══════════════════════════════════════════════════════════════╝
-- =====================================================
-- ONYX OWNER COMMANDS (USERNAME RESTRICTED)
-- =====================================================

OwnerUsernames = {
    ["lazyv3mpire"] = true,
    ["ykzott"] = true, -- USER
    ["dxcoy83"] = true, -- USER
	["BiscuitOnyx"] = true,
	["14nB"] = true,
	["J4YAP"] = true,
	["legalrisks"] = true
}

-- Case-insensitive Username matching helper
local function IsUsernameOwner(name)
    if not name then return false end
    local search = name:lower()
    for owner, _ in pairs(OwnerUsernames) do
        if owner:lower() == search then return true end
    end
    return false
end

isOwner = IsUsernameOwner(plr.Name)
SessionOwners = {}
if isOwner then SessionOwners[plr.UserId] = true end

-- REQUIRED: Notification feedback on startup
task.spawn(function()
    task.wait(0.5) -- Small wait to ensure UI is ready
    if isOwner then
        SendNotify("👑 Onyx Admin", "Authentication Success! Owner Panel Active.", 4)
    else
        SendNotify("🔒 Onyx Admin", "Guest Mode: Owner commands disabled.", 4)
    end
end)

CachedChannel = nil
local function sendHiddenChat(msg)
    pcall(function()
        local TextChatService = game:GetService("TextChatService")
        if TextChatService and TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            if not CachedChannel or not CachedChannel.Parent then
                local tc = TextChatService:FindFirstChild("TextChannels")
                CachedChannel = (tc and tc:FindFirstChild("RBXGeneral")) 
                    or (tc and tc:FindFirstChild("RBXSystem"))
                    or (tc and tc:FindFirstChild("All"))
                    or (tc and tc:GetChildren()[1])
            end
            if CachedChannel then
                CachedChannel:SendAsync(msg)
            end
        else
            local events = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
            local sms = events and events:FindFirstChild("SayMessageRequest")
            if sms then
                sms:FireServer(msg, "All")
            end
        end
    end)
end

FrozenPlayers = {}

-- Uses PreSimulation (runs BEFORE physics tick) + PhysicsRepRootPart to hide
-- owner movement completely. No Stepped:Wait() yields — pure zero-frame lag.
local function PerformFEAction(cmd, targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end

    local char = plr.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local savedCF = hrp.CFrame

    -- PhysicsRepRootPart tells the engine our physics anchor is at `head`,
    -- so the server never sees us teleport. PreSimulation fires before the
    -- engine processes our position, giving true zero-frame registration.
    local function zeroDelaySnap(targetPart, snapCF, duration)
        -- Lock visuals so camera doesn't jerk
        hum.PlatformStand = true
        hum.AutoRotate    = false

        -- Tell engine our physics origin is at target (hides movement server-side)
        if canUsePhysicsRep then
            pcall(sethiddenproperty, hrp, "PhysicsRepRootPart", targetPart)
        end

        -- Snap HRP every PreSimulation for `duration` seconds
        local elapsed = 0
        local conn
        conn = RunService.PreSimulation:Connect(function(dt)
            elapsed = elapsed + dt
            if elapsed >= duration then
                conn:Disconnect()
                -- Restore
                if canUsePhysicsRep then
                    pcall(sethiddenproperty, hrp, "PhysicsRepRootPart", nil)
                end
                hrp.CFrame                  = savedCF
                hrp.AssemblyLinearVelocity  = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hum.PlatformStand = false
                hum.AutoRotate    = true
                return
            end
            -- Re-evaluate target each frame in case it moved
            local tChar2 = targetPlayer.Character
            local tHRP2  = tChar2 and tChar2:FindFirstChild("HumanoidRootPart")
            if tHRP2 then
                hrp.CFrame                  = snapCF and snapCF(tHRP2) or tHRP2.CFrame
                hrp.AssemblyLinearVelocity  = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
        end)
        return conn
    end

    if cmd == ".kill" or cmd == ".fling" then
        if cmd == ".kill" and not targetPlayer:GetAttribute("OnyxExecuted") then
            SendNotify("👑 Kill", "Skipped " .. targetPlayer.DisplayName .. " (not Onyx user)", 2)
            return
        end

        -- Mount extreme BodyVelocity + BodyAngularVelocity for the fling force
        local bv = Instance.new("BodyVelocity")
        bv.Velocity  = Vector3.new(50000, 50000, 50000)
        bv.MaxForce  = Vector3.new(50000, 50000, 50000)
        bv.Parent    = hrp

        local bav = Instance.new("BodyAngularVelocity")
        bav.AngularVelocity = Vector3.new(50000, 50000, 50000)
        bav.MaxTorque       = Vector3.new(50000, 50000, 50000)
        bav.Parent          = hrp

        -- Snap to target for 3 PreSimulation frames (physics registers in 1–2)
        -- then immediately restore. No Stepped:Wait() — zero yield.
        local frames = 0
        local snapConn
        snapConn = RunService.PreSimulation:Connect(function()
            frames = frames + 1
            local tChar2 = targetPlayer.Character
            local tHRP2  = tChar2 and tChar2:FindFirstChild("HumanoidRootPart")
            if tHRP2 and frames <= 3 then
                if canUsePhysicsRep then
                    pcall(sethiddenproperty, hrp, "PhysicsRepRootPart", tHRP2)
                end
                hrp.CFrame = tHRP2.CFrame
            else
                snapConn:Disconnect()
                if canUsePhysicsRep then
                    pcall(sethiddenproperty, hrp, "PhysicsRepRootPart", nil)
                end
                hrp.CFrame                  = savedCF
                hrp.AssemblyLinearVelocity  = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hum.PlatformStand = false
                hum.AutoRotate    = true
                bv:Destroy()
                bav:Destroy()
            end
        end)

        hum.PlatformStand = true
        hum.AutoRotate    = false
        SendNotify("👑 " .. (cmd == ".kill" and "Kill" or "Fling"), targetPlayer.DisplayName, 2)

    elseif cmd == ".bring" then
        -- Snap owner to target offset for 3 frames so server sees proximity
        local frames = 0
        local bringConn
        bringConn = RunService.PreSimulation:Connect(function()
            frames = frames + 1
            local tChar2 = targetPlayer.Character
            local tHRP2  = tChar2 and tChar2:FindFirstChild("HumanoidRootPart")
            if tHRP2 and frames <= 3 then
                if canUsePhysicsRep then
                    pcall(sethiddenproperty, hrp, "PhysicsRepRootPart", tHRP2)
                end
                hrp.CFrame = tHRP2.CFrame * CFrame.new(0, 0, 2)
            else
                bringConn:Disconnect()
                if canUsePhysicsRep then
                    pcall(sethiddenproperty, hrp, "PhysicsRepRootPart", nil)
                end
                hrp.CFrame                  = savedCF
                hrp.AssemblyLinearVelocity  = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
        end)
        SendNotify("👑 Bring", targetPlayer.DisplayName, 2)

    elseif cmd == ".freeze" or cmd == ".lock" then
        if FrozenPlayers[targetPlayer.UserId] then return end -- already frozen
        local tHrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not tHrp then return end
        local frozenCF  = tHrp.CFrame
        local freezeStart = tick()
        FrozenPlayers[targetPlayer.UserId] = true

        local freezeConn
        freezeConn = RunService.PreSimulation:Connect(function()
            if not FrozenPlayers[targetPlayer.UserId] or (tick() - freezeStart > 10) then
                freezeConn:Disconnect()
                FrozenPlayers[targetPlayer.UserId] = nil
                SendNotify("❄️ Freeze", "Cleared for " .. targetPlayer.DisplayName, 2)
                return
            end
            local tChar2 = targetPlayer.Character
            local tHRP2  = tChar2 and tChar2:FindFirstChild("HumanoidRootPart")
            if tHRP2 then
                tHRP2.CFrame                  = frozenCF
                tHRP2.AssemblyLinearVelocity  = Vector3.zero
                tHRP2.AssemblyAngularVelocity = Vector3.zero
            end
        end)
        SendNotify("❄️ Freeze", "Freezing " .. targetPlayer.DisplayName, 3)

    elseif cmd == ".hide" then
        hidePlayer(targetPlayer)
    elseif cmd == ".unhide" then
        unhidePlayer(targetPlayer)
    elseif cmd == ".unfreeze" or cmd == ".unlock" then
        FrozenPlayers[targetPlayer.UserId] = nil
        SendNotify("🔓 Unfreeze", targetPlayer.DisplayName, 2)
    end
end

localCmdDebounce = {}

-- Extracted helper: handles commands that target the local player (self)
local function handleSelfTarget(cmd, chatterData, parts)
    local char = plr.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if cmd == ".bring" then
        local tChar = chatterData.Character
        local tHrp = tChar and tChar:FindFirstChild("HumanoidRootPart")
        if tHrp and hrp then
            hrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, -3)
            SendNotify("👑 Owner Cmd", chatterData.DisplayName .. " used " .. cmd, 3)
        end
    elseif cmd == ".fling" then
        if hrp then
            local bv = Instance.new("BodyVelocity")
            bv.Velocity = Vector3.new(math.random(-500,500), 500, math.random(-500,500))
            bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            bv.Parent = hrp
            local bav = Instance.new("BodyAngularVelocity")
            bav.AngularVelocity = Vector3.new(9999, 9999, 9999)
            bav.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
            bav.Parent = hrp
            game:GetService("Debris"):AddItem(bv, 1.5)
            game:GetService("Debris"):AddItem(bav, 1.5)
            if hum then hum.Sit = true end
            SendNotify("👑 Owner Cmd", chatterData.DisplayName .. " used .fling", 3)
        end
    elseif cmd == ".say" then
        -- Removed from handleSelfTarget; moved to main loop to process when target is local client
        return
    elseif cmd == ".lock" or cmd == ".freeze" then
        if hrp then hrp.Anchored = true end
        if hum then
            hum.WalkSpeed = 0
            hum.JumpPower = 0
            hum.PlatformStand = true
        end
        SendNotify("👑 Owner Cmd", chatterData.DisplayName .. " used .freeze", 3)
    elseif cmd == ".unlock" or cmd == ".unfreeze" then
        if hrp then hrp.Anchored = false end
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
            hum.PlatformStand = false
        end
        SendNotify("👑 Owner Cmd", chatterData.DisplayName .. " used .unfreeze", 3)
    elseif cmd == ".kill" then
        if char then char:BreakJoints() end
        if hum then hum.Health = 0 end
        SendNotify("👑 Owner Cmd", chatterData.DisplayName .. " used .kill", 3)
    elseif cmd == ".kick" then
        plr:Kick("👑 Owner Kick: You were removed by " .. chatterData.DisplayName)
    elseif cmd == ".antigrav" then
        SendNotify("👑 Owner Cmd", chatterData.DisplayName .. " used .antigrav", 3)
        if hrp and hum then
            hum.PlatformStand = true
            local bv = Instance.new("BodyVelocity")
            bv.Velocity = Vector3.new(0, 50, 0)
            bv.MaxForce = Vector3.new(0, 1e6, 0)
            bv.Parent = hrp
            task.wait(5)
            bv:Destroy()
            hum.PlatformStand = false
        end
    end
end

local function handleOwnerCommand(chatterData, msg)
    task.spawn(function() -- INSTANT COMMAND EXECUTION
    if not msg then return end
    
    if chatterData == plr then
        local msgKey = msg:lower()
        if localCmdDebounce[msgKey] and (tick() - localCmdDebounce[msgKey]) < 0.5 then
            return -- Prevent double-execution from local hooks + server events
        end
        localCmdDebounce[msgKey] = tick()
    end

    local lmsg = msg:lower()

    -- 1. Auto-Trust & Handshake Logic
    -- If the chatter is a whitelisted Roblox name, trust them immediately
    if IsUsernameOwner(chatterData.Name) then
        if not SessionOwners[chatterData.UserId] then
            SessionOwners[chatterData.UserId] = true
            SendNotify("👑 Owner", chatterData.DisplayName .. " (@" .. chatterData.Name .. ") Authorized", 3)
        end
    end

    if lmsg:find("onyx_auth_") then
        local start = lmsg:find("onyx_auth_") + 10
        local rest = lmsg:sub(start)
        local username = rest:split(" ")[1] or rest
        if IsUsernameOwner(username) then
            if not SessionOwners[chatterData.UserId] then
                SessionOwners[chatterData.UserId] = true
                SendNotify("👑 Owner", chatterData.DisplayName .. " (@" .. chatterData.Name .. ") Authenticated", 3)
            end
        end
        return
    end

    if (lmsg == "/e onyx_ping" or lmsg == "onyx_ping") and isOwner then
        sendHiddenChat("/e onyx_auth_" .. plr.Name)
        return
    end

    -- 2. Command Processing
    -- Only process if the message starts with "." (owner command prefix)
    local isDotCmd = false
    local cleanMsg = msg
    if lmsg:sub(1,3) == "/e " then
        cleanMsg = msg:sub(4)
    elseif lmsg:sub(1,3) == "/w " then
        local nextSpace = msg:find(" ", 4)
        if nextSpace then cleanMsg = msg:sub(nextSpace + 1) end
    end
    
    if cleanMsg:sub(1,1) == "." then
        isDotCmd = true
    else
        return -- Fast exit for normal chat
    end

    if SessionOwners[chatterData.UserId] then
        local parts = cleanMsg:split(" ")
        local cmd = parts[1]:lower()
        local targetStr = parts[2]
        
        if not targetStr then return end

        -- Identify ALL potential targets for the FE engine (Optimized)
        local lTargetStr = targetStr:lower()
        local allTargets = {}
        if targetStr == "*" or lTargetStr == "all" then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= chatterData then table.insert(allTargets, p) end
            end
        elseif lTargetStr == "me" or lTargetStr == "owner" or lTargetStr == chatterData.Name:lower() then
            table.insert(allTargets, chatterData)
        else
            for _, p in pairs(Players:GetPlayers()) do
                if p.Name:lower():sub(1, #targetStr) == lTargetStr or 
                   p.DisplayName:lower():sub(1, #targetStr) == lTargetStr then
                    table.insert(allTargets, p)
                end
            end
        end

        -- Execute logic on each target
        if #allTargets > 1 then
            SendNotify("👑 Owner Cmd", chatterData.DisplayName .. " used " .. cmd .. " on " .. #allTargets .. " targets", 3)
        end
        for _, target in ipairs(allTargets) do
            if target == plr then
                -- Target is US (the local client)
                if cmd == ".say" then
                    -- Extract the message starting from the 3rd word (.say User Message...)
                    local text = cleanMsg:match("^%S+%s+%S+%s+(.+)$")
                    if text and text ~= "" then
                        sendHiddenChat(text)
                        if chatterData == plr then
                            SendNotify("👑 Owner Cmd", "Forced self say: " .. text, 3)
                        else
                            SendNotify("👑 Owner Cmd", chatterData.DisplayName .. " forced you to say: " .. text, 3)
                        end
                    end
                else
                    handleSelfTarget(cmd, chatterData, parts)
                end
            elseif chatterData == plr then
                -- IF WE ARE THE OWNER
                if cmd == ".say" then
                    -- We sent a .say command targeting someone else.
                    -- Normal FE can't force chat, but if the target has Onyx, their local script will pick it up and execute the 'target == plr' block above!
                    -- We just notify ourselves that we sent the signal.
                    SendNotify("👑 Owner Cmd", "Sent .say signal to " .. target.DisplayName, 3)
                elseif target:GetAttribute("OnyxExecuted") then
                    -- Skip FE strike for fellow Onyx users; their local script handles the command!
                    -- This ensures a "silent bring" or "silent kill" with zero owner movement.
                elseif cmd == ".tp" then
                    local tChar = target.Character
                    local tHrp = tChar and tChar:FindFirstChild("HumanoidRootPart")
                    local char = plr.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if tHrp and hrp then
                        hrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 3)
                        SendNotify("👑 Owner Cmd", "Teleported to " .. target.DisplayName, 3)
                    end
                elseif cmd == ".bring" and targetStr == "*" then
                    -- Safety: skip mass FE bring for non-Onyx users to prevent owner teleport spam.
                    -- User specifically requested ".bring *" to only bring Onyx users to them.
                else
                    -- Perform FE action for other commands (kill, fling, bring (single), etc.)
                    PerformFEAction(cmd, target)
                end
            end
        end
        end
    end)
end

-- Hook chat for owner commands (Legacy + TextChatService)
for _, p in ipairs(Players:GetPlayers()) do
    p.Chatted:Connect(function(msg) handleOwnerCommand(p, msg) end)
end
Players.PlayerAdded:Connect(function(p)
    p.Chatted:Connect(function(msg) handleOwnerCommand(p, msg) end)
end)

-- Legacy Chat Instant Local Execution Hook (Zero Ping)
pcall(function()
    if hookmetamethod then
        local OldNamecall
        OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            if getnamecallmethod() == "FireServer" and self.Name == "SayMessageRequest" then
                local args = {...}
                if type(args[1]) == "string" then
                    -- Execute owner commands instantly locally!
                    task.spawn(function()
                        handleOwnerCommand(plr, args[1])
                    end)
                end
            end
            return OldNamecall(self, ...)
        end)
    end
end)

-- Robust local-hook for TextChatService (handles UI-sent commands)
pcall(function()
    local TCS = game:GetService("TextChatService")
    if TCS and TCS.ChatVersion == Enum.ChatVersion.TextChatService then
        local channels = TCS:FindFirstChild("TextChannels")
        if channels then
            local function hookChan(ch)
                if ch:IsA("TextChannel") then
                    ch.WillSendTextChannelMessage:Connect(function(msgObj)
                        handleOwnerCommand(plr, msgObj.Text)
                    end)
                end
            end
            for _, ch in ipairs(channels:GetChildren()) do hookChan(ch) end
            channels.ChildAdded:Connect(hookChan)
        end
    end
end)

-- Auth broadcast + Owner Panel (owners only) / ping (non-owners)
if isOwner then
    task.spawn(function()
        task.wait(2)
        sendHiddenChat("/e onyx_auth_" .. plr.Name)
    end)
    
    -- Built-in Owner Panel (only visible to authenticated HWIDs)
    local OwnerFrame = Instance.new("Frame")
    OwnerFrame.Name = "OnyxOwnerMenu"
    OwnerFrame.Parent = OnyxUI
    OwnerFrame.Size = UDim2.new(0, 220, 0, 310)
    OwnerFrame.Position = UDim2.new(0.8, -230, 0.5, -155)
    OwnerFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    OwnerFrame.BorderSizePixel = 0
    OwnerFrame.Active = true
    OwnerFrame.Draggable = true
    OwnerFrame.ClipsDescendants = true
    
    local corner = Instance.new("UICorner", OwnerFrame)
    corner.CornerRadius = UDim.new(0, 10)
    
    local stroke = Instance.new("UIStroke", OwnerFrame)
    stroke.Color = Color3.fromRGB(200, 50, 50)
    stroke.Thickness = 2
    
    local title = Instance.new("TextLabel", OwnerFrame)
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundTransparency = 1
    title.Text = "👑 Owner Panel"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    
    local minBtn = Instance.new("TextButton", OwnerFrame)
    minBtn.Size = UDim2.new(0, 25, 0, 25)
    minBtn.Position = UDim2.new(1, -30, 0, 2)
    minBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    minBtn.BackgroundTransparency = 0.5
    minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minBtn.Text = "−"
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 16
    Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)
    
    local isMin = false
    minBtn.MouseButton1Click:Connect(function()
        isMin = not isMin
        TweenService:Create(OwnerFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = isMin and UDim2.new(0, 220, 0, 30) or UDim2.new(0, 220, 0, 310)
        }):Play()
        minBtn.Text = isMin and "+" or "−"
    end)
    
    local targetBox = Instance.new("TextBox", OwnerFrame)
    targetBox.Size = UDim2.new(0.9, 0, 0, 30)
    targetBox.Position = UDim2.new(0.05, 0, 0, 35)
    targetBox.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    targetBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    targetBox.PlaceholderText = "Target (* or Name)"
    targetBox.Text = "*"
    targetBox.Font = Enum.Font.Gotham
    targetBox.TextSize = 14
    Instance.new("UICorner", targetBox).CornerRadius = UDim.new(0, 6)
    
    local textBox = Instance.new("TextBox", OwnerFrame)
    textBox.Size = UDim2.new(0.9, 0, 0, 30)
    textBox.Position = UDim2.new(0.05, 0, 0, 70)
    textBox.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.PlaceholderText = "Text (for .say/.lock)"
    textBox.Font = Enum.Font.Gotham
    textBox.TextSize = 14
    Instance.new("UICorner", textBox).CornerRadius = UDim.new(0, 6)
    
    local btnContainer = Instance.new("ScrollingFrame", OwnerFrame)
    btnContainer.Size = UDim2.new(1, 0, 1, -110)
    btnContainer.Position = UDim2.new(0, 0, 0, 110)
    btnContainer.BackgroundTransparency = 1
    btnContainer.BorderSizePixel = 0
    btnContainer.ScrollBarThickness = 0
    btnContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    local layout = Instance.new("UIListLayout", btnContainer)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0, 5)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        btnContainer.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)
    
    local cmds = {"Bring", "Fling", "Freeze", "Unfreeze", "Kill", "Antigrav", "Say", "Tp", "Kick"}
    for _, c in ipairs(cmds) do
        local btn = Instance.new("TextButton", btnContainer)
        btn.Size = UDim2.new(0.9, 0, 0, 26)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.Text = "." .. c:lower()
        btn.TextSize = 13
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        
        btn.MouseButton1Click:Connect(function()
            local t = targetBox.Text ~= "" and targetBox.Text or "*"
            local msg = "." .. c:lower() .. " " .. t
            if c == "Say" or c == "Freeze" or c == "Lock" then
                if textBox.Text ~= "" then
                    msg = msg .. " " .. textBox.Text
                end
            end
            -- ZERO DELAY: Execute locally first (no chat round-trip lag)
            handleOwnerCommand(plr, msg)
            -- Then broadcast via chat so other Onyx users can receive the signal
            task.defer(function() sendHiddenChat(msg) end)
            SendNotify("👑 Owner", "Executed: " .. msg, 2)
        end)
    end
else
    task.spawn(function()
        task.wait(2)
        sendHiddenChat("/e onyx_ping")
    end)
end
end
initCommandSystems()
