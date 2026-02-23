-- OnyxV2 Reanimation Module
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local plr = Players.LocalPlayer

-- ── STATE MANAGEMENT ────────────────────────────────────────────────────────
local ReanimActive = false
local FakeChar = nil
local CurrentAnim = nil
local AnimationDatabase = {}
local Favourites = {}
local Keybinds = {} 
local Connections = {}

-- Persistence Files
local FAV_FILE = "OnyxReanim_Favs.json"
local BIND_FILE = "OnyxReanim_Binds.json"

-- ── UTILS & DATA ────────────────────────────────────────────────────────────
local function SaveSettings()
    writefile(FAV_FILE, HttpService:JSONEncode(Favourites))
    local bindsToSave = {}
    for name, key in pairs(Keybinds) do bindsToSave[name] = key.Name end
    writefile(BIND_FILE, HttpService:JSONEncode(bindsToSave))
end

local function LoadSettings()
    pcall(function()
        if isfile(FAV_FILE) then Favourites = HttpService:JSONDecode(readfile(FAV_FILE)) end
        if isfile(BIND_FILE) then
            local raw = HttpService:JSONDecode(readfile(BIND_FILE))
            for name, keyName in pairs(raw) do Keybinds[name] = Enum.KeyCode[keyName] end
        end
    end)
end

local function LoadAnimDatabase()
    local success, result = pcall(function()
        return loadstring(readfile("Animations.lua"))()
    end)
    if success then AnimationDatabase = result else warn("OnyxV2: Animations.lua missing!") end
end

-- ── THE MASTER SWITCH (RAGDOLL SYSTEM) ──────────────────────────────────────
local function CleanUp()
    -- Disconnect all loops
    for i, v in pairs(Connections) do v:Disconnect() Connections[i] = nil end
    
    -- Destroy the fake rig
    if FakeChar then FakeChar:Destroy() FakeChar = nil end
    
    -- Reset the real character
    local char = plr.Character
    if char then
        -- Making sure character is visible and functional
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then v.Transparency = 0 v.CanCollide = true end
        end
        -- If joints were broken, we force a respawn to fix the character
        char:BreakJoints() 
    end
    
    CurrentAnim = nil
    ReanimActive = false
end

local function StartReanim()
    local char = plr.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    char.Archivable = true
    FakeChar = char:Clone()
    FakeChar.Parent = workspace
    FakeChar.Name = "OnyxRig"
    
    -- Setup Fake Rig Visuals
    for _, v in pairs(FakeChar:GetDescendants()) do
        if v:IsA("BasePart") then 
            v.Transparency = (v.Name == "HumanoidRootPart") and 1 or 0.2 
            v.CanCollide = false 
        elseif v:IsA("LocalScript") or v:IsA("Script") then 
            v:Destroy() 
        end
    end
    
    -- Main Physics Loop: Glue real parts to fake parts
    Connections.Phys = RunService.Heartbeat:Connect(function()
        if not char or not char:FindFirstChild("HumanoidRootPart") then CleanUp() return end
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
                local target = FakeChar:FindFirstChild(part.Name)
                if target then part.CFrame = target.CFrame end
                -- Set velocity to keep networking active
                part.Velocity = Vector3.new(0, 30, 0)
            end
        end
    end)
    
    ReanimActive = true
end

-- ── ANIMATION ENGINE ────────────────────────────────────────────────────────
local function PlayAnim(name)
    if not ReanimActive then return end
    if CurrentAnim == name then 
        if Connections.Anim then Connections.Anim:Disconnect() end
        CurrentAnim = nil
        return 
    end
    
    local data = AnimationDatabase[name]
    if not data then return end
    
    if Connections.Anim then Connections.Anim:Disconnect() end
    CurrentAnim = name
    local startTime = tick()
    local duration = data[#data].Time
    
    Connections.Anim = RunService.RenderStepped:Connect(function()
        if not FakeChar then return end
        local elapsed = (tick() - startTime) % duration
        for i = 1, #data - 1 do
            local f1, f2 = data[i], data[i+1]
            if elapsed >= f1.Time and elapsed <= f2.Time then
                local alpha = (elapsed - f1.Time) / (f2.Time - f1.Time)
                for pName, cf in pairs(f1.Data) do
                    local p = FakeChar:FindFirstChild(pName)
                    if p and f2.Data[pName] then
                        p.CFrame = FakeChar.HumanoidRootPart.CFrame * cf:Lerp(f2.Data[pName], alpha)
                    end
                end
                break
            end
        end
    end)
end

-- ── UI CONSTRUCTION ──────────────────────────────────────────────────────────
local ScreenGui = Instance.new("ScreenGui", plr.PlayerGui)
local Main = Instance.new("Frame", ScreenGui)
Main.Size, Main.Position = UDim2.new(0, 300, 0, 420), UDim2.new(0.5, -150, 0.5, -210)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

-- MASTER TOGGLE (TOP)
local MasterTgl = Instance.new("TextButton", Main)
MasterTgl.Size, MasterTgl.Position = UDim2.new(0.9, 0, 0, 45), UDim2.new(0.05, 0, 0.05, 0)
MasterTgl.BackgroundColor3 = Color3.fromRGB(60, 40, 40)
MasterTgl.Text = "SYSTEM: DISABLED"
MasterTgl.TextColor3, MasterTgl.Font = Color3.new(1,1,1), Enum.Font.GothamBold
Instance.new("UICorner", MasterTgl)

local ScrollingFrame = Instance.new("ScrollingFrame", Main)
ScrollingFrame.Size, ScrollingFrame.Position = UDim2.new(0.9, 0, 0.7, 0), UDim2.new(0.05, 0, 0.25, 0)
ScrollingFrame.BackgroundTransparency, ScrollingFrame.ScrollBarThickness = 1, 0
local Layout = Instance.new("UIListLayout", ScrollingFrame)
Layout.Padding = UDim.new(0, 5)

-- Tab Logic
local TabFrame = Instance.new("Frame", Main)
TabFrame.Size, TabFrame.Position = UDim2.new(0.9, 0, 0, 30), UDim2.new(0.05, 0, 0.17, 0)
TabFrame.BackgroundTransparency = 1

local function RenderList(favOnly)
    for _, v in pairs(ScrollingFrame:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
    for name, _ in pairs(AnimationDatabase) do
        if not favOnly or (favOnly and Favourites[name]) then
            local row = Instance.new("Frame", ScrollingFrame)
            row.Size, row.BackgroundColor3 = UDim2.new(1, 0, 0, 35), Color3.fromRGB(25, 25, 35)
            Instance.new("UICorner", row)

            local btn = Instance.new("TextButton", row)
            btn.Size, btn.Text = UDim2.new(0.5, 0, 1, 0), "  " .. name
            btn.BackgroundTransparency, btn.TextColor3, btn.Font, btn.TextXAlignment = 1, Color3.new(1,1,1), Enum.Font.Gotham, Enum.TextXAlignment.Left

            local fav = Instance.new("TextButton", row)
            fav.Size, fav.Position, fav.Text = UDim2.new(0.2, 0, 1, 0), UDim2.new(0.5, 0, 0, 0), Favourites[name] and "★" or "☆"
            fav.BackgroundTransparency, fav.TextColor3 = 1, Color3.fromRGB(255, 200, 0)

            local bind = Instance.new("TextButton", row)
            bind.Size, bind.Position, bind.Text = UDim2.new(0.3, 0, 1, 0), UDim2.new(0.7, 0, 0, 0), Keybinds[name] and Keybinds[name].Name or "[SET]"
            bind.BackgroundTransparency, bind.TextColor3 = 1, Color3.fromRGB(150, 150, 150)

            btn.MouseButton1Click:Connect(function() PlayAnim(name) end)
            fav.MouseButton1Click:Connect(function() Favourites[name] = not Favourites[name] SaveSettings() fav.Text = Favourites[name] and "★" or "☆" end)
            bind.MouseButton1Click:Connect(function()
                bind.Text = "..."
                local c; c = UserInputService.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.Keyboard then
                        Keybinds[name] = i.KeyCode SaveSettings() bind.Text = i.KeyCode.Name c:Disconnect()
                    end
                end)
            end)
        end
    end
end

-- Logic for Master Switch
MasterTgl.MouseButton1Click:Connect(function()
    if not ReanimActive then
        StartReanim()
        MasterTgl.Text = "SYSTEM: ENABLED"
        MasterTgl.BackgroundColor3 = Color3.fromRGB(40, 60, 40)
    else
        CleanUp()
        MasterTgl.Text = "SYSTEM: DISABLED"
        MasterTgl.BackgroundColor3 = Color3.fromRGB(60, 40, 40)
    end
end)

-- Tabs
local t1 = Instance.new("TextButton", TabFrame)
t1.Size, t1.Text = UDim2.new(0.5,0,1,0), "ALL"
t1.BackgroundTransparency, t1.TextColor3, t1.Font = 1, Color3.new(1,1,1), Enum.Font.GothamBold
t1.MouseButton1Click:Connect(function() RenderList(false) end)

local t2 = Instance.new("TextButton", TabFrame)
t2.Size, t2.Position, t2.Text = UDim2.new(0.5,0,1,0), UDim2.new(0.5,0,0,0), "FAVS"
t2.BackgroundTransparency, t2.TextColor3, t2.Font = 1, Color3.new(1,1,1), Enum.Font.GothamBold
t2.MouseButton1Click:Connect(function() RenderList(true) end)

-- Keybind Listener
UserInputService.InputBegan:Connect(function(i, g)
    if g then return end
    for name, k in pairs(Keybinds) do
        if i.KeyCode == k then PlayAnim(name) end
    end
end)

-- Init
LoadSettings()
LoadAnimDatabase()
RenderList(false)
