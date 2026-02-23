-- OnyxV2 Reanimation: Mic Up Edition
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local plr = Players.LocalPlayer

-- ── CONFIG ──────────────────────────────────────────────────────────────────
local GITHUB_URL = "https://raw.githubusercontent.com/EORScopeZ/OnyxV2/refs/heads/main/Animations.lua"
local FAV_FILE = "Onyx_Favs.json"
local BIND_FILE = "Onyx_Binds.json"

-- ── STATE ───────────────────────────────────────────────────────────────────
local ReanimActive = false
local FakeChar = nil
local CurrentAnim = nil
local AnimationDatabase = {}
local Favourites = {}
local Keybinds = {}
local Connections = {}

-- ── DATA PERSISTENCE ────────────────────────────────────────────────────────
local function SaveData()
    pcall(writefile, FAV_FILE, HttpService:JSONEncode(Favourites))
    local b = {} for n, k in pairs(Keybinds) do b[n] = k.Name end
    pcall(writefile, BIND_FILE, HttpService:JSONEncode(b))
end

local function LoadData()
    pcall(function()
        if isfile(FAV_FILE) then Favourites = HttpService:JSONDecode(readfile(FAV_FILE)) end
        if isfile(BIND_FILE) then
            local r = HttpService:JSONDecode(readfile(BIND_FILE))
            for n, kn in pairs(r) do Keybinds[n] = Enum.KeyCode[kn] end
        end
    end)
end

-- ── THE CORE (MIC UP COMPATIBLE) ───────────────────────────────────────────
local function CleanUp()
    for _, v in pairs(Connections) do v:Disconnect() end
    Connections = {}
    if FakeChar then FakeChar:Destroy() FakeChar = nil end
    
    local char = plr.Character
    if char then
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then v.Transparency = 0 v.CanCollide = true end
        end
        char:BreakJoints() -- Forces a reset to fix joints
    end
    ReanimActive = false
    CurrentAnim = nil
end

local function StartReanim()
    local char = plr.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    char.Archivable = true
    FakeChar = char:Clone()
    FakeChar.Name = "OnyxGhost"
    FakeChar.Parent = workspace
    
    -- Mic Up Fix: Hide real body, show ghost
    for _, v in pairs(FakeChar:GetDescendants()) do
        if v:IsA("BasePart") then v.Transparency = 0.3 v.CanCollide = false
        elseif v:IsA("LocalScript") or v:IsA("Script") then v:Destroy() end
    end

    -- The "Bypass" Loop
    Connections.Phys = RunService.Heartbeat:Connect(function()
        if not char or not FakeChar then return end
        -- Force Network Ownership
        settings().Physics.AllowSleep = false
        
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
                local target = FakeChar:FindFirstChild(part.Name)
                if target then
                    part.CFrame = target.CFrame
                    -- Mic Up Velocity Fix: Keeps parts active in server physics
                    part.Velocity = Vector3.new(0, 35, 0) 
                end
            end
        end
    end)
    ReanimActive = true
end

-- ── ANIMATION PLAYER ────────────────────────────────────────────────────────
local function PlayAnim(name)
    if not ReanimActive then return end
    if CurrentAnim == name then 
        if Connections.Anim then Connections.Anim:Disconnect() end
        CurrentAnim = nil return 
    end
    
    local data = AnimationDatabase[name]
    if not data then return end
    
    if Connections.Anim then Connections.Anim:Disconnect() end
    CurrentAnim = name
    local start = tick()
    local duration = data[#data].Time
    
    Connections.Anim = RunService.RenderStepped:Connect(function()
        if not FakeChar then return end
        local elapsed = (tick() - start) % duration
        for i = 1, #data - 1 do
            local f1, f2 = data[i], data[i+1]
            if elapsed >= f1.Time and elapsed <= f2.Time then
                local alpha = (elapsed - f1.Time) / (f2.Time - f1.Time)
                for pName, cf in pairs(f1.Data) do
                    local p = FakeChar:FindFirstChild(pName)
                    if p then p.CFrame = FakeChar.HumanoidRootPart.CFrame * cf:Lerp(f2.Data[pName], alpha) end
                end
                break
            end
        end
    end)
end

-- ── UI & LOADER ─────────────────────────────────────────────────────────────
local function LoadFromGitHub()
    local success, content = pcall(function() return loadstring(game:HttpGet(GITHUB_URL))() end)
    if success then AnimationDatabase = content return true end
    return false
end

-- UI Initialization (Simplified for standalone use)
local ScreenGui = Instance.new("ScreenGui", plr.PlayerGui)
local Main = Instance.new("Frame", ScreenGui)
Main.Size, Main.Position = UDim2.new(0, 320, 0, 400), UDim2.new(0.5, -160, 0.5, -200)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Instance.new("UICorner", Main)

local MasterBtn = Instance.new("TextButton", Main)
MasterBtn.Size, MasterBtn.Position = UDim2.new(0.9, 0, 0, 40), UDim2.new(0.05, 0, 0.05, 0)
MasterBtn.Text, MasterBtn.BackgroundColor3 = "MASTER SYSTEM: OFF", Color3.fromRGB(60, 40, 40)
MasterBtn.TextColor3, MasterBtn.Font = Color3.new(1,1,1), Enum.Font.GothamBold
Instance.new("UICorner", MasterBtn)

local Scroll = Instance.new("ScrollingFrame", Main)
Scroll.Size, Scroll.Position = UDim2.new(0.9, 0, 0.7, 0), UDim2.new(0.05, 0, 0.2, 0)
Scroll.BackgroundTransparency, Scroll.ScrollBarThickness = 1, 0
Instance.new("UIListLayout", Scroll).Padding = UDim.new(0, 5)

local function Populate()
    for n, _ in pairs(AnimationDatabase) do
        local r = Instance.new("Frame", Scroll)
        r.Size, r.BackgroundColor3 = UDim2.new(1, 0, 0, 35), Color3.fromRGB(30, 30, 40)
        Instance.new("UICorner", r)
        
        local b = Instance.new("TextButton", r)
        b.Size, b.Text = UDim2.new(0.6, 0, 1, 0), "  "..n
        b.BackgroundTransparency, b.TextColor3, b.Font, b.TextXAlignment = 1, Color3.new(1,1,1), Enum.Font.Gotham, 0
        
        local fav = Instance.new("TextButton", r)
        fav.Size, fav.Position, fav.Text = UDim2.new(0.2, 0, 1, 0), UDim2.new(0.6, 0, 0, 0), Favourites[n] and "★" or "☆"
        fav.BackgroundTransparency, fav.TextColor3 = 1, Color3.new(1, 0.8, 0)
        
        local bind = Instance.new("TextButton", r)
        bind.Size, bind.Position, bind.Text = UDim2.new(0.2, 0, 1, 0), UDim2.new(0.8, 0, 0, 0), Keybinds[n] and Keybinds[n].Name or "[SET]"
        bind.BackgroundTransparency, bind.TextColor3 = 1, Color3.new(0.6, 0.6, 0.6)

        b.MouseButton1Click:Connect(function() PlayAnim(n) end)
        fav.MouseButton1Click:Connect(function() Favourites[n] = not Favourites[n] SaveData() fav.Text = Favourites[n] and "★" or "☆" end)
        bind.MouseButton1Click:Connect(function()
            bind.Text = "..."
            local c; c = UserInputService.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.Keyboard then
                    Keybinds[n] = i.KeyCode SaveData() bind.Text = i.KeyCode.Name c:Disconnect()
                end
            end)
        end)
    end
end

MasterBtn.MouseButton1Click:Connect(function()
    if not ReanimActive then
        StartReanim()
        MasterBtn.Text, MasterBtn.BackgroundColor3 = "MASTER SYSTEM: ON", Color3.fromRGB(40, 60, 40)
    else
        CleanUp()
        MasterBtn.Text, MasterBtn.BackgroundColor3 = "MASTER SYSTEM: OFF", Color3.fromRGB(60, 40, 40)
    end
end)

UserInputService.InputBegan:Connect(function(i, g)
    if g then return end
    for n, k in pairs(Keybinds) do if i.KeyCode == k then PlayAnim(n) end end
end)

LoadData()
if LoadFromGitHub() then Populate() end
