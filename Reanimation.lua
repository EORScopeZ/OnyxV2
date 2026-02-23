-- OnyxV2 Reanimation Module
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local plr = Players.LocalPlayer

-- ── CONFIGURATION ───────────────────────────────────────────────────────────
local GITHUB_ANIM_URL = "https://raw.githubusercontent.com/EORScopeZ/OnyxV2/refs/heads/main/Animations.lua"

-- ── STATE MANAGEMENT ────────────────────────────────────────────────────────
local ReanimActive = false
local FakeChar = nil
local CurrentAnim = nil
local AnimationDatabase = {}
local Connections = {}

-- ── GITHUB LOADER ───────────────────────────────────────────────────────────
local function LoadFromGitHub()
    local success, content = pcall(function()
        -- Use the internal game:HttpGet or the httpRequest shim from OnyxV2
        local response = game:HttpGet(GITHUB_ANIM_URL)
        return loadstring(response)()
    end)
    
    if success and type(content) == "table" then
        AnimationDatabase = content
        return true
    else
        warn("OnyxV2: Failed to sync animations from GitHub.")
        return false
    end
end

-- ── MASTER TOGGLE LOGIC ─────────────────────────────────────────────────────
local function CleanUp()
    -[span_0](start_span)- Stop all physics and animation loops[span_0](end_span)
    for i, v in pairs(Connections) do 
        v:Disconnect() 
        Connections[i] = nil 
    end
    
    -[span_1](start_span)- Destroy the fake rig and clear tracks[span_1](end_span)
    if FakeChar then 
        FakeChar:Destroy() 
        FakeChar = nil 
    end
    
    local char = plr.Character
    if char then
        -- Restore transparency and collision for the real character
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then 
                v.Transparency = 0 
                v.CanCollide = true 
            end
        end
        -- Force a character reset to re-anchor joints broken during reanim
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
    
    -[span_2](start_span)[span_3](start_span)- Setup Fake Rig Visuals to match the ghost-style reanimation[span_2](end_span)[span_3](end_span)
    for _, v in pairs(FakeChar:GetDescendants()) do
        if v:IsA("BasePart") then 
            v.Transparency = (v.Name == "HumanoidRootPart") and 1 or 0.2 
            v.CanCollide = false 
        elseif v:IsA("LocalScript") or v:IsA("Script") then 
            v:Destroy() 
        end
    end
    
    -[span_4](start_span)- Physics Loop: Glue real parts to fake parts using Heartbeat[span_4](end_span)
    Connections.Phys = RunService.Heartbeat:Connect(function()
        if not char or not char:FindFirstChild("HumanoidRootPart") then CleanUp() return end
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
                local target = FakeChar:FindFirstChild(part.Name)
                if target then 
                    part.CFrame = target.CFrame 
                end
                -- Networking "velocity" trick to maintain part ownership
                part.Velocity = Vector3.new(0, 30, 0)
            end
        end
    end)
    
    ReanimActive = true
end

-- ── UI CONSTRUCTION (Integrated) ─────────────────────────────────────────────
local MainFrame = Instance.new("Frame") -- This would be your Reanim Tab
MainFrame.Size = UDim2.new(1, 0, 1, 0)
MainFrame.BackgroundTransparency = 1

-- THE MASTER SWITCH
local MasterTgl = Instance.new("TextButton", MainFrame)
MasterTgl.Size = UDim2.new(0.9, 0, 0, 40)
MasterTgl.Position = UDim2.new(0.05, 0, 0, 10)
MasterTgl.BackgroundColor3 = Color3.fromRGB(60, 40, 40) -- Red-ish when off
MasterTgl.Text = "SYSTEM: DISABLED"
MasterTgl.TextColor3 = Color3.new(1, 1, 1)
[span_5](start_span)MasterTgl.Font = Enum.Font.GothamBold -- Consistent with OnyxV2 font[span_5](end_span)
Instance.new("UICorner", MasterTgl).CornerRadius = UDim.new(0, 8)

MasterTgl.MouseButton1Click:Connect(function()
    if not ReanimActive then
        StartReanim()
        MasterTgl.Text = "SYSTEM: ENABLED"
        MasterTgl.BackgroundColor3 = Color3.fromRGB(40, 60, 40) -- Green-ish when on
    else
        CleanUp()
        MasterTgl.Text = "SYSTEM: DISABLED"
        MasterTgl.BackgroundColor3 = Color3.fromRGB(60, 40, 40)
    end
end)

-- Animation List Frame
local ListScroll = Instance.new("ScrollingFrame", MainFrame)
ListScroll.Position = UDim2.new(0.05, 0, 0, 60)
ListScroll.Size = UDim2.new(0.9, 0, 1, -70)
ListScroll.BackgroundTransparency = 1
ListScroll.ScrollBarThickness = 0
local Layout = Instance.new("UIListLayout", ListScroll)
Layout.Padding = UDim.new(0, 5)

local function RefreshUI()
    for _, v in pairs(ListScroll:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
    for name, _ in pairs(AnimationDatabase) do
        local row = Instance.new("Frame", ListScroll)
        row.Size = UDim2.new(1, 0, 0, 30)
        row.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
        Instance.new("UICorner", row)
        
        local btn = Instance.new("TextButton", row)
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = "  " .. name
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Font = Enum.Font.Gotham
    end
end

-- Initialize
task.spawn(function()
    if LoadFromGitHub() then
        RefreshUI()
    end
end)
