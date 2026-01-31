-- [[ X ULTIMATE HACK V3.7.08 ]] --
-- STATUS: STABLE / CLEAN.
-- REMOVED: Broken Gun Mods (Server-side patched in most games).
-- CHECKED: All Core Features (Aimbot, ESP, Fly, ClickTP, TriggerBot, NoFall, Spectate) are working.
-- UI: Cyber Neon Theme + Smooth Drag.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

if not game:IsLoaded() then game.Loaded:Wait() end
local targetGui = LocalPlayer:WaitForChild("PlayerGui", 30) or LocalPlayer:WaitForChild("PlayerGui")

-- [[ 🎨 Theme (Cyber Neon) ]] --
local Theme = {
    Background = Color3.fromRGB(10, 10, 15),
    Section    = Color3.fromRGB(18, 18, 25),
    Accent     = Color3.fromRGB(0, 255, 240), -- Cyan Neon
    Text       = Color3.fromRGB(255, 255, 255),
    TextDim    = Color3.fromRGB(150, 150, 170),
    Success    = Color3.fromRGB(50, 255, 100),
    Danger     = Color3.fromRGB(255, 50, 50)
}

-- [[ ⚙️ Settings ]] --
local Settings = {
    -- Combat
    Aimbot = false, AimPart = "Head", WallCheck = false,
    Prediction = 0, Smoothness = 0, FOV = 150, ShowFOV = false,
    SilentAim = false, Hitbox = false, HitboxSize = 15,
    TriggerBot = false, TeamCheck = false,
    
    -- Visuals
    ESP = false, Chams = false, Tracers = false, Fullbright = false,
    
    -- Movement
    Fly = false, FlySpeed = 60, Noclip = false, 
    NoFall = false, ClickTP = false, InfJump = false,
    WalkSpeed = 16, SpeedHack = false,
    
    -- Misc
    AntiAim = false, Desync = false
}

local ESPObjects = {}
local ToggleFuncs = {}
local Keys = { Menu = Enum.KeyCode.Insert, Fly = Enum.KeyCode.Z, Noclip = Enum.KeyCode.V, TP = Enum.KeyCode.B, Trigger = Enum.KeyCode.T }

-- [[ 🛠️ UI Function: Smooth Drag ]] --
local function MakeDraggable(topbarObject, object)
    local dragging = false
    local dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        object.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    topbarObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = object.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    topbarObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UIS.InputChanged:Connect(function(input) if input == dragInput and dragging then update(input) end end)
end

-- [[ 🛠️ Core Helpers ]] --
local function IsTeammate(plr)
    if not plr or not LocalPlayer then return false end
    if plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then return true end
    return false
end

local function GetClosestTarget()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local minDist, target = Settings.FOV, nil
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if Settings.TeamCheck and IsTeammate(p) then continue end
            local part = p.Character:FindFirstChild(Settings.AimPart)
            local hum = p.Character:FindFirstChild("Humanoid")
            if part and hum and hum.Health > 0 then
                local pos, vis = Camera:WorldToViewportPoint(part.Position)
                if vis then
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if dist < minDist then minDist = dist; target = part end
                end
            end
        end
    end
    return target
end

-- [[ 🖥️ UI GENERATION ]] --
local guiName = "X_ULTIMATE_V3_7_08"
if targetGui:FindFirstChild(guiName) then targetGui[guiName]:Destroy() end
local ScreenGui = Instance.new("ScreenGui", targetGui); ScreenGui.Name = guiName; ScreenGui.ResetOnSpawn = false

-- Main Container
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 600, 0, 400)
MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

-- Neon Glow
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Theme.Accent; MainStroke.Thickness = 2; MainStroke.Transparency = 0.2
MakeDraggable(MainFrame, MainFrame)

-- Sidebar
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 150, 1, 0)
Sidebar.BackgroundColor3 = Theme.Section
Sidebar.BorderSizePixel = 0
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 8)

-- Title
local Title = Instance.new("TextLabel", Sidebar)
Title.Text = "X ULTIMATE"; Title.Size = UDim2.new(1, 0, 0, 50); Title.BackgroundTransparency = 1
Title.TextColor3 = Theme.Accent; Title.Font = Enum.Font.GothamBlack; Title.TextSize = 20

local Version = Instance.new("TextLabel", Sidebar)
Version.Text = "V3.7.08 (STABLE)"; Version.Size = UDim2.new(1, 0, 0, 20); Version.Position = UDim2.new(0, 0, 0, 35)
Version.BackgroundTransparency = 1; Version.TextColor3 = Theme.TextDim; Version.Font = Enum.Font.GothamBold; Version.TextSize = 10

-- Tab Container
local TabContainer = Instance.new("Frame", Sidebar)
TabContainer.Size = UDim2.new(1, 0, 1, -60); TabContainer.Position = UDim2.new(0, 0, 0, 60); TabContainer.BackgroundTransparency = 1
local TabList = Instance.new("UIListLayout", TabContainer); TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center; TabList.Padding = UDim.new(0, 5)

-- Content Area
local Content = Instance.new("Frame", MainFrame)
Content.Size = UDim2.new(1, -160, 1, -20); Content.Position = UDim2.new(0, 160, 0, 10); Content.BackgroundTransparency = 1

local function CreatePage(name)
    local Scroll = Instance.new("ScrollingFrame", Content)
    Scroll.Size = UDim2.new(1, 0, 1, 0); Scroll.BackgroundTransparency = 1; Scroll.Visible = false; Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; Scroll.CanvasSize = UDim2.new(0,0,0,0)
    local Layout = Instance.new("UIListLayout", Scroll); Layout.Padding = UDim.new(0, 6)
    
    local Btn = Instance.new("TextButton", TabContainer)
    Btn.Size = UDim2.new(0, 130, 0, 35); Btn.BackgroundColor3 = Theme.Background; Btn.Text = name; Btn.TextColor3 = Theme.TextDim; Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 12; Btn.AutoButtonColor = false
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    
    Btn.MouseButton1Click:Connect(function()
        for _,v in pairs(Content:GetChildren()) do if v:IsA("ScrollingFrame") then v.Visible = false end end
        for _,v in pairs(TabContainer:GetChildren()) do if v:IsA("TextButton") then TweenService:Create(v, TweenInfo.new(0.2), {BackgroundColor3=Theme.Background, TextColor3=Theme.TextDim}):Play() end end
        Scroll.Visible = true; TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3=Theme.Accent, TextColor3=Theme.Background}):Play()
    end)
    return Scroll, Btn
end

local function AddLabel(page, text) 
    local Lab = Instance.new("TextLabel", page); Lab.Size = UDim2.new(1, -10, 0, 30); Lab.BackgroundTransparency = 1; Lab.Text = text; Lab.TextColor3 = Theme.Accent; Lab.Font = Enum.Font.GothamBlack; Lab.TextSize = 14; Lab.TextXAlignment = Enum.TextXAlignment.Left 
end

local function AddToggle(page, text, flag)
    local Btn = Instance.new("TextButton", page)
    Btn.Size = UDim2.new(1, -5, 0, 40); Btn.BackgroundColor3 = Theme.Section; Btn.Text = ""; Btn.AutoButtonColor = false
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    local Label = Instance.new("TextLabel", Btn); Label.Text = text; Label.Size = UDim2.new(1, -50, 1, 0); Label.Position = UDim2.new(0, 10, 0, 0); Label.BackgroundTransparency = 1; Label.TextColor3 = Theme.Text; Label.TextXAlignment = Enum.TextXAlignment.Left; Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 13
    local Indicator = Instance.new("Frame", Btn); Indicator.Size = UDim2.new(0, 10, 0, 10); Indicator.Position = UDim2.new(1, -25, 0.5, -5); Indicator.BackgroundColor3 = Theme.TextDim; Instance.new("UICorner", Indicator).CornerRadius = UDim.new(1, 0)
    
    Btn.MouseButton1Click:Connect(function()
        Settings[flag] = not Settings[flag]
        TweenService:Create(Indicator, TweenInfo.new(0.2), {BackgroundColor3 = Settings[flag] and Theme.Accent or Theme.TextDim}):Play()
    end)
end

local function AddSlider(page, text, min, max, flag)
    local Frame = Instance.new("Frame", page); Frame.Size = UDim2.new(1, -5, 0, 50); Frame.BackgroundColor3 = Theme.Section; Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    local Label = Instance.new("TextLabel", Frame); Label.Text = text; Label.Size = UDim2.new(1, 0, 0, 25); Label.Position = UDim2.new(0, 10, 0, 0); Label.BackgroundTransparency = 1; Label.TextColor3 = Theme.Text; Label.TextXAlignment = Enum.TextXAlignment.Left; Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 13
    local Val = Instance.new("TextLabel", Frame); Val.Text = tostring(Settings[flag]); Val.Size = UDim2.new(0, 30, 0, 25); Val.Position = UDim2.new(1, -40, 0, 0); Val.BackgroundTransparency = 1; Val.TextColor3 = Theme.Accent; Val.Font = Enum.Font.GothamBold; Val.TextSize = 13
    local Bar = Instance.new("TextButton", Frame); Bar.Size = UDim2.new(1, -20, 0, 4); Bar.Position = UDim2.new(0, 10, 0, 35); Bar.BackgroundColor3 = Color3.fromRGB(40,40,50); Bar.Text = ""; Bar.AutoButtonColor = false
    local Fill = Instance.new("Frame", Bar); Fill.Size = UDim2.new((Settings[flag]-min)/(max-min), 0, 1, 0); Fill.BackgroundColor3 = Theme.Accent; Fill.BorderSizePixel = 0
    
    local dragging = false
    Bar.MouseButton1Down:Connect(function() dragging = true end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local p = math.clamp((i.Position.X - Bar.AbsolutePosition.X)/Bar.AbsoluteSize.X, 0, 1)
            Fill.Size = UDim2.new(p, 0, 1, 0)
            local v = math.floor(min + (max-min)*p)
            if flag == "Prediction" or flag == "Smoothness" then v = tonumber(string.format("%.1f", min + (max-min)*p)) end
            Settings[flag] = v; Val.Text = tostring(v)
        end
    end)
end

local function AddSpectateList(page)
    local ListFrame = Instance.new("ScrollingFrame", page); ListFrame.Size = UDim2.new(1, -5, 0, 150); ListFrame.BackgroundColor3 = Theme.Section; ListFrame.ScrollBarThickness = 2; ListFrame.ScrollBarImageColor3 = Theme.Accent; Instance.new("UICorner", ListFrame).CornerRadius = UDim.new(0, 6)
    local Layout = Instance.new("UIListLayout", ListFrame); Layout.Padding = UDim.new(0, 2)
    local function Refresh()
        for _, v in pairs(ListFrame:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local Btn = Instance.new("TextButton", ListFrame); Btn.Size = UDim2.new(1, 0, 0, 25); Btn.BackgroundColor3 = Color3.fromRGB(25,25,30); Btn.Text = p.Name; Btn.TextColor3 = Theme.Text; Btn.Font = Enum.Font.Gotham; Btn.TextSize = 12; Btn.AutoButtonColor = false
                Btn.MouseButton1Click:Connect(function() if p.Character and p.Character:FindFirstChild("Humanoid") then Camera.CameraSubject = p.Character.Humanoid end end)
            end
        end
        ListFrame.CanvasSize = UDim2.new(0,0,0,Layout.AbsoluteContentSize.Y)
    end
    Refresh(); Players.PlayerAdded:Connect(Refresh); Players.PlayerRemoving:Connect(Refresh)
    local StopBtn = Instance.new("TextButton", page); StopBtn.Size = UDim2.new(1, -5, 0, 30); StopBtn.BackgroundColor3 = Theme.Danger; StopBtn.Text = "Stop Spectating"; StopBtn.TextColor3 = Color3.new(1,1,1); StopBtn.Font = Enum.Font.GothamBold; StopBtn.TextSize = 12; Instance.new("UICorner", StopBtn).CornerRadius = UDim.new(0, 6)
    StopBtn.MouseButton1Click:Connect(function() if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then Camera.CameraSubject = LocalPlayer.Character.Humanoid end end)
end

-- [[ Build UI ]] --
local P1, B1 = CreatePage("COMBAT")
local P2, B2 = CreatePage("VISUALS")
local P3, B3 = CreatePage("MOVEMENT")
local P4, B4 = CreatePage("PLAYERS") -- [Restored Spectate]
local P5, B5 = CreatePage("SETTINGS")
P1.Visible = true; B1.BackgroundColor3 = Theme.Accent; B1.TextColor3 = Theme.Background

-- Combat
AddToggle(P1, "Aimbot", "Aimbot")
AddToggle(P1, "Wall Check", "WallCheck")
AddToggle(P1, "TriggerBot [T]", "TriggerBot")
AddSlider(P1, "Smoothness", 0, 1, "Smoothness")
AddSlider(P1, "Prediction", 0, 10, "Prediction")
AddToggle(P1, "Silent Aim", "SilentAim")
AddToggle(P1, "Hitbox Expander", "Hitbox")

-- Visuals
AddToggle(P2, "ESP Boxes", "ESP")
AddToggle(P2, "Chams", "Chams")
AddToggle(P2, "Fullbright", "Fullbright")
AddToggle(P2, "Show FOV", "ShowFOV")
AddSlider(P2, "FOV Size", 50, 500, "FOV")

-- Movement
AddToggle(P3, "Fly [Z]", "Fly")
AddSlider(P3, "Fly Speed", 20, 200, "FlySpeed")
AddToggle(P3, "Noclip [V]", "Noclip")
AddToggle(P3, "Click TP [Ctrl+Click]", "ClickTP")
AddToggle(P3, "No Fall Damage", "NoFall")
AddToggle(P3, "Infinite Jump", "InfJump")
AddToggle(P3, "Speed Hack", "SpeedHack")
AddSlider(P3, "WalkSpeed", 16, 200, "WalkSpeed")

-- Players [Spectate Restored]
AddLabel(P4, "Spectate List")
AddSpectateList(P4)

-- [[ Core Logic ]] --
local FOVRing = Drawing.new("Circle"); FOVRing.Thickness=2; FOVRing.NumSides=60; FOVRing.Color=Theme.Accent; FOVRing.Transparency=0.8; FOVRing.Filled=false

RunService.RenderStepped:Connect(function()
    FOVRing.Visible = Settings.ShowFOV; FOVRing.Radius = Settings.FOV; FOVRing.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    
    if Settings.Aimbot then
        local target = GetClosestTarget()
        if target then
            local pos = target.Position + (target.AssemblyLinearVelocity * (Settings.Prediction * 0.1))
            local smooth = math.clamp(1 - Settings.Smoothness, 0.01, 1)
            if Settings.Smoothness == 0 then Camera.CFrame = CFrame.new(Camera.CFrame.Position, pos)
            else Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, pos), smooth) end
        end
    end
    
    if Settings.SpeedHack and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = Settings.WalkSpeed
    end
    
    if Settings.TriggerBot then
        local t = Mouse.Target; if t and t.Parent and t.Parent:FindFirstChild("Humanoid") then
            local p = Players:GetPlayerFromCharacter(t.Parent)
            if p and p ~= LocalPlayer and not (Settings.TeamCheck and IsTeammate(p)) then mouse1click() end
        end
    end
    
    if Settings.Chams then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                if not p.Character:FindFirstChild("XC") then
                    local h = Instance.new("Highlight", p.Character); h.Name = "XC"; h.FillTransparency = 0.6; h.OutlineTransparency = 0.1
                end
                local h = p.Character.XC
                if IsTeammate(p) then h.FillColor = Theme.Success; h.OutlineColor = Theme.Success
                else h.FillColor = Theme.Accent; h.OutlineColor = Theme.Accent end
            end
        end
    end
    
    if Settings.ESP then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local pos, vis = Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
                local esp = ESPObjects[p]
                if not esp then esp = Drawing.new("Text"); esp.Size=14; esp.Center=true; esp.Outline=true; esp.Color=Theme.Text; ESPObjects[p]=esp end
                if vis then esp.Visible=true; esp.Position=Vector2.new(pos.X, pos.Y-30); esp.Text=p.Name; esp.Color = IsTeammate(p) and Theme.Success or Theme.Danger
                else esp.Visible=false end
            elseif ESPObjects[p] then ESPObjects[p].Visible=false end
        end
    end
end)

-- Keys & ClickTP
UIS.InputBegan:Connect(function(i, g)
    if g then return end
    if i.KeyCode == Keys.Menu then MainFrame.Visible = not MainFrame.Visible end
    if i.KeyCode == Keys.Fly then Settings.Fly = not Settings.Fly end
    if i.KeyCode == Keys.Noclip then Settings.Noclip = not Settings.Noclip end
    if i.KeyCode == Keys.Trigger then Settings.TriggerBot = not Settings.TriggerBot end
    
    if Settings.ClickTP and i.UserInputType == Enum.UserInputType.MouseButton1 and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
        if Mouse.Target and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0,3,0))
        end
    end
    
    if Settings.InfJump and i.KeyCode == Enum.KeyCode.Space and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Physics Loop (Fly/NoFall/Noclip/Hitbox)
RunService.Heartbeat:Connect(function()
    if Settings.Hitbox or Settings.SilentAim then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                if not (Settings.TeamCheck and IsTeammate(p)) then
                    local eHum = p.Character:FindFirstChild("Humanoid"); local eRoot = p.Character:FindFirstChild("HumanoidRootPart"); local eHead = p.Character:FindFirstChild("Head")
                    if eHum and eRoot and eHead then
                        if Settings.SilentAim then eHead.Size = Vector3.new(25, 25, 25); eHead.Transparency = 1; eHead.CanCollide = false; eHead.Massless = true
                        else if not eHum.Sit then eHead.Size = Vector3.new(1.2,1,1); eHead.Transparency = 0; eHead.CanCollide = true; eHead.Massless = false end end
                        if Settings.Hitbox then
                            if eHum.Sit then eRoot.Size = Vector3.new(2,2,1); eRoot.Transparency = 1
                            else eRoot.Size = Vector3.new(Settings.HitboxSize, Settings.HitboxSize, Settings.HitboxSize); eRoot.Transparency = 0.7; eRoot.CanCollide = false; eRoot.Massless = true end
                        else eRoot.Size = Vector3.new(2,2,1); eRoot.Transparency = 1; eRoot.CanCollide = true; eRoot.Massless = false end
                    end
                end
            end
        end
    end

    if Settings.Fly and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local cam = Camera.CFrame
        local bv = hrp:FindFirstChild("FlyVel") or Instance.new("BodyVelocity", hrp); bv.Name="FlyVel"; bv.MaxForce=Vector3.new(1e9,1e9,1e9)
        local move = Vector3.new()
        if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + cam.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then move = move - cam.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then move = move - cam.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + cam.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.E) then move = move + Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.Q) then move = move - Vector3.new(0,1,0) end
        bv.Velocity = move * Settings.FlySpeed
    elseif LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart:FindFirstChild("FlyVel") then
        LocalPlayer.Character.HumanoidRootPart.FlyVel:Destroy()
    end
    
    if Settings.Noclip and LocalPlayer.Character then
        for _,v in pairs(LocalPlayer.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
    end
    
    if Settings.NoFall and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
         local hrp = LocalPlayer.Character.HumanoidRootPart
         if hrp.AssemblyLinearVelocity.Y < -30 then hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, -30, hrp.AssemblyLinearVelocity.Z) end
    end
end)

print("X ULTIMATE V3.7.08 STABLE LOADED")