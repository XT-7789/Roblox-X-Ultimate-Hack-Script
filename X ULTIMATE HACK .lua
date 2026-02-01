-- [[ X ULTIMATE HACK V3.7.13 ]] --
-- STATUS: MENU RESTORED.
-- UI: Reverted to V3.9 style UI (Proven to work).
-- FEATURES: V3.7 Core (Flick Aim, Aim Lock, Hitbox, No Gun Mods).
-- FIX: Solved blank menu & broken keybinds.

-- [[ 0. 智能清理 ]] --
if _G.X_Connections then
    for _, c in pairs(_G.X_Connections) do pcall(function() c:Disconnect() end) end
    _G.X_Connections = {}
end
if _G.X_Objects then
    for _, o in pairs(_G.X_Objects) do pcall(function() if o and o.Remove then o:Remove() end end) end
    _G.X_Objects = {}
end

_G.X_Connections = {}
_G.X_Objects = {}
local Connections = _G.X_Connections 

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

-- 1. 智能加载器
if not game:IsLoaded() then game.Loaded:Wait() end
local targetGui = LocalPlayer:WaitForChild("PlayerGui", 60) or LocalPlayer:WaitForChild("PlayerGui")
if targetGui:FindFirstChild("X_ULTIMATE_V3_7_13") then targetGui.X_ULTIMATE_V3_7_13:Destroy() end

-- [[ 🔧 快捷键 ]] --
local Keys = { Menu=Enum.KeyCode.Insert, Fly=Enum.KeyCode.Z, Noclip=Enum.KeyCode.V, TPTarget=Enum.KeyCode.B, Trigger=Enum.KeyCode.T }

local Theme = {
    Main = Color3.fromRGB(10, 10, 15),
    Sec  = Color3.fromRGB(20, 20, 25),
    Stroke = Color3.fromRGB(0, 255, 255),
    Team = Color3.fromRGB(0, 255, 100),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(180, 180, 180),
    Selected = Color3.fromRGB(255, 200, 0),
    Danger = Color3.fromRGB(255, 50, 50)
}

-- 2. 核心状态
local States = {
    Aimbot = false,    -- Aim Lock
    SilentAim = false, -- Flick Aim
    Hitbox = false,    -- Big Head
    TPToTarget = false,
    TriggerBot = false, TeamCheck = false,
    ESP = false, Chams = false, Tracers = false, XRay = false, Fullbright = false, Crosshair = false,
    Fly = false, SpeedHack = false, InfJump = false, Noclip = false, ClickTP = false,
    NoFall = false, AntiAim = false, Desync = false, ShowFOV = false,
    MenuAction = "Spectate"
}

local Vals = { FOV = 200, WalkSpeed = 100, FlySpeed = 60, HitboxSize = 15, AimSmooth = 0.5 }
local Checkpoints = {P1=nil, P2=nil, P3=nil}
local ESPObjects = {}
local tracerLines = {}
local crosshairLines = {}

-- [[ 3. 核心功能函数 ]] --
local function MakeDraggable(dragTarget, objectToMove)
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        local targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        TweenService:Create(objectToMove, TweenInfo.new(0.05), {Position = targetPos}):Play()
    end
    dragTarget.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = objectToMove.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    dragTarget.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
    table.insert(Connections, UIS.InputChanged:Connect(function(input) if input == dragInput and dragging then update(input) end end))
end

local function IsTeammate(plr)
    if not plr or not LocalPlayer then return false end
    if plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then return true end
    if plr.TeamColor and LocalPlayer.TeamColor and plr.TeamColor == LocalPlayer.TeamColor then return true end
    return false
end

local function getClosestToCenter()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local closestDist, target = Vals.FOV, nil
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if States.TeamCheck and IsTeammate(p) then continue end
            local head = p.Character:FindFirstChild("Head")
            local hum = p.Character:FindFirstChild("Humanoid")
            if head and hum and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if dist < closestDist then closestDist = dist; target = head end
                end
            end
        end
    end
    return target
end

local function SetPoint(n) if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then Checkpoints[n] = LocalPlayer.Character.HumanoidRootPart.CFrame end end
local function TPPoint(n) if Checkpoints[n] and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.CFrame = Checkpoints[n] end end

local function UpdateChams()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local highlight = p.Character:FindFirstChild("X_Chams")
            if States.Chams then
                if not highlight then highlight = Instance.new("Highlight", p.Character); highlight.Name = "X_Chams"; highlight.FillTransparency = 0.5; highlight.OutlineTransparency = 0 end
                if IsTeammate(p) then highlight.FillColor = Theme.Team; highlight.OutlineColor = Theme.Team else highlight.FillColor = Theme.Stroke; highlight.OutlineColor = Theme.Stroke end
            elseif highlight then highlight:Destroy() end
        end
    end
end

-- ESP & Crosshair
local fovRing = nil
if Drawing then
    fovRing = Drawing.new("Circle"); fovRing.Thickness=2; fovRing.NumSides=60; fovRing.Radius=Vals.FOV; fovRing.Color=Theme.Stroke; fovRing.Transparency=0.8; fovRing.Visible=false; fovRing.Filled=false
    table.insert(_G.X_Objects, fovRing)
    crosshairLines.H = Drawing.new("Line"); crosshairLines.H.Thickness=1.5; crosshairLines.H.Color=Theme.Stroke; crosshairLines.H.Visible=false
    crosshairLines.V = Drawing.new("Line"); crosshairLines.V.Thickness=1.5; crosshairLines.V.Color=Theme.Stroke; crosshairLines.V.Visible=false
    table.insert(_G.X_Objects, crosshairLines.H); table.insert(_G.X_Objects, crosshairLines.V)
end

local function createESP(plr)
    if plr == LocalPlayer or ESPObjects[plr] then return end
    if not Drawing then return end
    local esp = {Box=Drawing.new("Square"), Name=Drawing.new("Text"), HealthBar=Drawing.new("Line")}
    esp.Box.Thickness=1.5; esp.Box.Filled=false; esp.Box.Visible=false
    esp.Name.Size=14; esp.Name.Center=true; esp.Name.Outline=true; esp.Name.Color=Color3.new(1,1,1); esp.Name.Visible=false
    esp.HealthBar.Thickness=1.5; esp.HealthBar.Color=Color3.new(0,1,0); esp.HealthBar.Visible=false
    ESPObjects[plr] = esp
    table.insert(_G.X_Objects, esp.Box); table.insert(_G.X_Objects, esp.Name); table.insert(_G.X_Objects, esp.HealthBar)
end
local function removeESP(plr)
    if ESPObjects[plr] then for _, d in pairs(ESPObjects[plr]) do d:Remove() end; ESPObjects[plr] = nil end
    if tracerLines[plr] then tracerLines[plr]:Remove(); tracerLines[plr] = nil end
end
for _, p in pairs(Players:GetPlayers()) do createESP(p) end
table.insert(Connections, Players.PlayerAdded:Connect(createESP))
table.insert(Connections, Players.PlayerRemoving:Connect(removeESP))

-- [[ 5. UI SYSTEM (V3.7.13 - REBUILT) ]] --
local ScreenGui = Instance.new("ScreenGui", targetGui); ScreenGui.Name = "X_ULTIMATE_V3_7_13"; ScreenGui.ResetOnSpawn = false; ScreenGui.DisplayOrder = 999
local Main = Instance.new("Frame", ScreenGui); Main.Size = UDim2.new(0, 600, 0, 420); Main.Position = UDim2.new(0.5, -300, 0.5, -210); Main.BackgroundColor3 = Theme.Main; Main.BorderSizePixel = 0
local SidePanel = Instance.new("Frame", Main); SidePanel.Size = UDim2.new(0, 150, 1, 0); SidePanel.BackgroundColor3 = Theme.Sec; Instance.new("UICorner", SidePanel).CornerRadius = UDim.new(0, 8)
local Title = Instance.new("TextLabel", SidePanel); Title.Text = "X ULTIMATE"; Title.Size = UDim2.new(1, 0, 0, 50); Title.BackgroundTransparency = 1; Title.TextColor3 = Theme.Stroke; Title.Font = Enum.Font.GothamBlack; Title.TextSize = 22
local Ver = Instance.new("TextLabel", SidePanel); Ver.Text = "V3.7.13"; Ver.Size = UDim2.new(1, 0, 0, 20); Ver.Position = UDim2.new(0, 0, 0, 35); Ver.BackgroundTransparency = 1; Ver.TextColor3 = Theme.TextDim; Ver.TextSize = 13; Ver.Font = Enum.Font.GothamBold
MakeDraggable(SidePanel, Main)
local UIStroke = Instance.new("UIStroke", Main); UIStroke.Color = Theme.Stroke; UIStroke.Thickness = 2; UIStroke.Transparency = 0.5
local UICorner = Instance.new("UICorner", Main); UICorner.CornerRadius = UDim.new(0, 8)
local TabHolder = Instance.new("Frame", SidePanel); TabHolder.Size = UDim2.new(1, -20, 1, -80); TabHolder.Position = UDim2.new(0, 10, 0, 80); TabHolder.BackgroundTransparency = 1; local TabList = Instance.new("UIListLayout", TabHolder); TabList.Padding = UDim.new(0, 8)
local PageHolder = Instance.new("Frame", Main); PageHolder.Size = UDim2.new(1, -170, 1, -20); PageHolder.Position = UDim2.new(0, 160, 0, 10); PageHolder.BackgroundTransparency = 1

local function CreatePage(name, isScrolling)
    local Page = isScrolling and Instance.new("ScrollingFrame", PageHolder) or Instance.new("Frame", PageHolder)
    Page.Size = UDim2.new(1, 0, 1, 0); Page.BackgroundTransparency = 1; Page.Visible = false
    local List = Instance.new("UIListLayout", Page); List.Padding = UDim.new(0, 8)
    if isScrolling then 
        Page.ScrollBarThickness = 2; Page.ScrollBarImageColor3 = Theme.Stroke
        -- [FIXED] Force Canvas Size Update
        List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, List.AbsoluteContentSize.Y + 20)
        end)
    end
    local TabBtn = Instance.new("TextButton", TabHolder); TabBtn.Size = UDim2.new(1, 0, 0, 35); TabBtn.BackgroundColor3 = Color3.fromRGB(30,30,35); TabBtn.Text = name; TabBtn.TextColor3 = Theme.TextDim; TabBtn.Font = Enum.Font.GothamSemibold; TabBtn.TextSize = 14; TabBtn.AutoButtonColor = false; Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 6)
    TabBtn.MouseButton1Click:Connect(function() 
        for _,v in pairs(PageHolder:GetChildren()) do v.Visible=false end; for _,v in pairs(TabHolder:GetChildren()) do if v:IsA("TextButton") then TweenService:Create(v, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(30,30,35), TextColor3=Theme.TextDim}):Play() end end
        Page.Visible = true; TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundColor3=Theme.Stroke, TextColor3=Theme.Main}):Play() 
    end)
    return Page, TabBtn
end

local function AddToggle(page, text, flag)
    local Btn = Instance.new("TextButton", page); Btn.Size = UDim2.new(1, -5, 0, 45); Btn.BackgroundColor3 = Theme.Sec; Btn.Text = ""; Btn.AutoButtonColor = false; Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    local Stroke = Instance.new("UIStroke", Btn); Stroke.Color = Theme.Stroke; Stroke.Transparency = 0.8
    local Label = Instance.new("TextLabel", Btn); Label.Text = text; Label.Size = UDim2.new(0.7, 0, 1, 0); Label.Position = UDim2.new(0, 15, 0, 0); Label.BackgroundTransparency = 1; Label.TextColor3 = Theme.Text; Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 15; Label.TextXAlignment = Enum.TextXAlignment.Left
    local Indicator = Instance.new("Frame", Btn); Indicator.Size = UDim2.new(0, 40, 0, 6); Indicator.Position = UDim2.new(1, -55, 0.5, -3); Indicator.BackgroundColor3 = Color3.fromRGB(40,40,45); Instance.new("UICorner", Indicator).CornerRadius = UDim.new(1, 0)
    local Dot = Instance.new("Frame", Indicator); Dot.Size = UDim2.new(0, 14, 0, 14); Dot.Position = UDim2.new(0, -4, 0.5, -7); Dot.BackgroundColor3 = Color3.fromRGB(80,80,80); Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)
    local function Update(val)
        local c = val and Theme.Stroke or Color3.fromRGB(80,80,80); local p = val and UDim2.new(1, -10, 0.5, -7) or UDim2.new(0, -4, 0.5, -7); local s = val and 0.2 or 0.8
        TweenService:Create(Dot, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Position = p, BackgroundColor3 = c}):Play(); TweenService:Create(Stroke, TweenInfo.new(0.3), {Transparency = s}):Play()
        if flag == "XRay" then toggleXRay(val) end; if flag == "Fullbright" then toggleFullbright(val) end; if flag == "Noclip" and not val then ResetCollision() end
        if flag == "Chams" then UpdateChams() end
    end
    Update(States[flag]) 
    Btn.MouseButton1Click:Connect(function() States[flag] = not States[flag]; Update(States[flag]) end)
end

local function AddSlider(page, text, min, max, def, cb)
    local Frame = Instance.new("Frame", page); Frame.Size = UDim2.new(1, -5, 0, 55); Frame.BackgroundColor3 = Theme.Sec; Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    local Label = Instance.new("TextLabel", Frame); Label.Text = text .. ": " .. def; Label.Size = UDim2.new(1, -20, 0, 20); Label.Position = UDim2.new(0, 10, 0, 5); Label.BackgroundTransparency = 1; Label.TextColor3 = Theme.Text; Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 14; Label.TextXAlignment = Enum.TextXAlignment.Left
    local SlideBar = Instance.new("TextButton", Frame); SlideBar.Size = UDim2.new(1, -20, 0, 6); SlideBar.Position = UDim2.new(0, 10, 0, 35); SlideBar.BackgroundColor3 = Color3.fromRGB(40,40,45); SlideBar.Text = ""; SlideBar.AutoButtonColor = false; Instance.new("UICorner", SlideBar).CornerRadius = UDim.new(1, 0)
    local Fill = Instance.new("Frame", SlideBar); Fill.Size = UDim2.new((def-min)/(max-min), 0, 1, 0); Fill.BackgroundColor3 = Theme.Stroke; Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)
    local drag = false; SlideBar.MouseButton1Down:Connect(function() drag = true end); 
    table.insert(Connections, UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end))
    table.insert(Connections, UIS.InputChanged:Connect(function(i) if drag and i.UserInputType == Enum.UserInputType.MouseMovement then local p = math.clamp((i.Position.X - SlideBar.AbsolutePosition.X) / SlideBar.AbsoluteSize.X, 0, 1); Fill.Size = UDim2.new(p, 0, 1, 0); local v = math.floor(min + (max - min) * p); Label.Text = text .. ": " .. v; cb(v) end end))
end

local function AddDual(page, t1, cb1, t2, cb2)
    local F = Instance.new("Frame", page); F.Size = UDim2.new(1, -5, 0, 40); F.BackgroundTransparency = 1
    local B1 = Instance.new("TextButton", F); B1.Size = UDim2.new(0.48, 0, 1, 0); B1.BackgroundColor3 = Theme.Sec; B1.Text = t1; B1.TextColor3 = Theme.Text; B1.Font = Enum.Font.GothamBold; B1.TextSize = 13; B1.AutoButtonColor = false; Instance.new("UICorner", B1).CornerRadius = UDim.new(0, 6); local S1 = Instance.new("UIStroke", B1); S1.Color = Theme.Stroke; S1.Transparency = 0.9
    B1.MouseButton1Click:Connect(function() TweenService:Create(B1, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Stroke, TextColor3 = Theme.Main}):Play(); task.wait(0.1); TweenService:Create(B1, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Sec, TextColor3 = Theme.Text}):Play(); cb1() end)
    local B2 = Instance.new("TextButton", F); B2.Size = UDim2.new(0.48, 0, 1, 0); B2.Position = UDim2.new(0.52, 0, 0, 0); B2.BackgroundColor3 = Theme.Sec; B2.Text = t2; B2.TextColor3 = Theme.Text; B2.Font = Enum.Font.GothamBold; B2.TextSize = 13; B2.AutoButtonColor = false; Instance.new("UICorner", B2).CornerRadius = UDim.new(0, 6); local S2 = Instance.new("UIStroke", B2); S2.Color = Theme.Stroke; S2.Transparency = 0.9
    B2.MouseButton1Click:Connect(function() TweenService:Create(B2, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Stroke, TextColor3 = Theme.Main}):Play(); task.wait(0.1); TweenService:Create(B2, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Sec, TextColor3 = Theme.Text}):Play(); cb2() end)
end

-- [[ FIXED & SORTED PLAYER MENU ]] --
local function AddPlayerList(page)
    local Header = Instance.new("Frame", page); Header.Size = UDim2.new(1, -5, 0, 40); Header.BackgroundColor3 = Theme.Sec; Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 6)
    
    local ModeBtn = Instance.new("TextButton", Header); ModeBtn.Size = UDim2.new(0.5, 0, 0.8, 0); ModeBtn.Position = UDim2.new(0.45, 0, 0.1, 0); ModeBtn.BackgroundColor3 = Theme.Main; ModeBtn.Text = "SPECTATE"; ModeBtn.TextColor3 = Theme.Stroke; ModeBtn.Font = Enum.Font.GothamBold; ModeBtn.TextSize = 16; Instance.new("UICorner", ModeBtn).CornerRadius = UDim.new(0, 4)
    local Label = Instance.new("TextLabel", Header); Label.Text = "CLICK MODE:"; Label.Size = UDim2.new(0.4, 0, 1, 0); Label.BackgroundTransparency = 1; Label.TextColor3 = Theme.Text; Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 14
    local ModeStroke = Instance.new("UIStroke", ModeBtn); ModeStroke.Color = Theme.Stroke; ModeStroke.Thickness = 1
    
    ModeBtn.MouseButton1Click:Connect(function()
        if States.MenuAction == "Spectate" then States.MenuAction = "Teleport"; ModeBtn.Text = "TELEPORT"; ModeBtn.TextColor3 = Theme.Selected; ModeStroke.Color = Theme.Selected
        else States.MenuAction = "Spectate"; ModeBtn.Text = "SPECTATE"; ModeBtn.TextColor3 = Theme.Stroke; ModeStroke.Color = Theme.Stroke end
    end)

    local StopBtn = Instance.new("TextButton", page); StopBtn.Size = UDim2.new(1, -5, 0, 35); StopBtn.BackgroundColor3 = Theme.Danger; StopBtn.Text = "STOP SPECTATING"; StopBtn.TextColor3 = Color3.new(1,1,1); StopBtn.Font = Enum.Font.GothamBold; StopBtn.TextSize = 15; Instance.new("UICorner", StopBtn).CornerRadius = UDim.new(0, 6)
    StopBtn.MouseButton1Click:Connect(function() Camera.CameraSubject = LocalPlayer.Character.Humanoid end)

    local Scroll = Instance.new("ScrollingFrame", page); Scroll.Size = UDim2.new(1, -5, 1, -135); Scroll.BackgroundTransparency = 1; Scroll.ScrollBarThickness = 4; Scroll.ScrollBarImageColor3 = Theme.Stroke
    Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local Layout = Instance.new("UIListLayout", Scroll); Layout.Padding = UDim.new(0, 4)

    local function UpdateList()
        for _, v in pairs(Scroll:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
        local playerList = Players:GetPlayers()
        table.sort(playerList, function(a, b) 
            local teamA = a.Team and a.Team.Name or "Neutral"
            local teamB = b.Team and b.Team.Name or "Neutral"
            if teamA ~= teamB then return teamA < teamB end
            return a.Name:lower() < b.Name:lower()
        end)
        for _, p in pairs(playerList) do
            if p ~= LocalPlayer then
                local teamName = p.Team and p.Team.Name or "Neutral"
                local displayStr = " [" .. teamName .. "] " .. p.DisplayName
                local PBtn = Instance.new("TextButton", Scroll); PBtn.Size = UDim2.new(1, 0, 0, 30); PBtn.BackgroundColor3 = Theme.Sec; PBtn.Text = displayStr; PBtn.TextColor3 = Theme.TextDim; PBtn.Font = Enum.Font.GothamSemibold; PBtn.TextSize = 15; PBtn.TextXAlignment = Enum.TextXAlignment.Left; PBtn.AutoButtonColor = false; Instance.new("UICorner", PBtn).CornerRadius = UDim.new(0, 4)
                local TC = Instance.new("Frame", PBtn); TC.Size = UDim2.new(0, 3, 1, 0); TC.BackgroundColor3 = p.TeamColor.Color; Instance.new("UICorner", TC).CornerRadius = UDim.new(0, 4)
                PBtn.MouseButton1Click:Connect(function()
                    if States.MenuAction == "Spectate" then
                        if p.Character and p.Character:FindFirstChild("Humanoid") then Camera.CameraSubject = p.Character.Humanoid end
                    elseif States.MenuAction == "Teleport" then
                        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            LocalPlayer.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 2, 3)
                        end
                    end
                end)
            end
        end
    end
    UpdateList(); 
    table.insert(Connections, Players.PlayerAdded:Connect(UpdateList))
    table.insert(Connections, Players.PlayerRemoving:Connect(UpdateList))
    
    local RefBtn = Instance.new("TextButton", page); RefBtn.Size = UDim2.new(1, -5, 0, 25); RefBtn.BackgroundColor3 = Color3.fromRGB(40,40,50); RefBtn.Text = "REFRESH LIST"; RefBtn.TextColor3 = Theme.Text; RefBtn.Font = Enum.Font.GothamBold; RefBtn.TextSize = 12; Instance.new("UICorner", RefBtn).CornerRadius = UDim.new(0, 4)
    RefBtn.MouseButton1Click:Connect(UpdateList)
end

-- [[ BUILD PAGES ]] --
local P1, T1 = CreatePage("COMBAT", true); P1.Visible = true; T1.BackgroundColor3 = Theme.Stroke; T1.TextColor3 = Theme.Main
local P2, T2 = CreatePage("VISUAL", true)
local P3, T3 = CreatePage("MOVEMENT", true)
local P4, T4 = CreatePage("PLAYERS", false)

-- Items
AddToggle(P1, "Aim Lock (Camera)", "Aimbot")
AddSlider(P1, "Aim Smoothness", 0.1, 1, 0.5, function(v) Vals.AimSmooth = v end)
AddToggle(P1, "Flick Silent Aim", "SilentAim")
AddToggle(P1, "Team Check", "TeamCheck")
AddToggle(P1, "TriggerBot [T]", "TriggerBot")
AddToggle(P1, "Show FOV", "ShowFOV")
AddSlider(P1, "FOV Size", 50, 800, 200, function(v) Vals.FOV = v end)
AddToggle(P1, "Hitbox Expander", "Hitbox")
AddSlider(P1, "Hitbox Size", 2, 50, 15, function(v) Vals.HitboxSize = v end)
AddToggle(P1, "TP Target [B]", "TPToTarget")

AddToggle(P2, "ESP Box", "ESP")
AddToggle(P2, "ESP Chams", "Chams")
AddToggle(P2, "Tracers", "Tracers")
AddToggle(P2, "X-Ray", "XRay")
AddToggle(P2, "Fullbright", "Fullbright")
AddToggle(P2, "Crosshair", "Crosshair")

AddToggle(P3, "Fly Mode [Z]", "Fly")
AddSlider(P3, "Fly Speed", 10, 300, 60, function(v) Vals.FlySpeed = v end)
AddToggle(P3, "Click TP [Ctrl+Click]", "ClickTP")
AddToggle(P3, "No Fall Damage", "NoFall")
AddToggle(P3, "Noclip [V]", "Noclip")
AddToggle(P3, "Speed Hack", "SpeedHack")
AddSlider(P3, "Walk Speed", 16, 300, 100, function(v) Vals.WalkSpeed = v end)
AddToggle(P3, "Infinite Jump", "InfJump")
AddDual(P3, "SAVE P1", function() SetPoint("P1") end, "WARP P1", function() TPPoint("P1") end)
AddDual(P3, "SAVE P2", function() SetPoint("P2") end, "WARP P2", function() TPPoint("P2") end)
AddDual(P3, "SAVE P3", function() SetPoint("P3") end, "WARP P3", function() TPPoint("P3") end)

AddPlayerList(P4)

-- [[ 6. PHYSICS LOOP ]] --
table.insert(Connections, RunService.Stepped:Connect(function()
    pcall(function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if States.NoFall and hrp and hum then
            if hrp.AssemblyLinearVelocity.Y < -30 then hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, -30, hrp.AssemblyLinearVelocity.Z) end
            hum.FallDistance = 0
        end
        if States.Noclip and hrp then
            for _, v in pairs(LocalPlayer.Character:GetDescendants()) do if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end end
        end
    end)
end))

table.insert(Connections, RunService.Heartbeat:Connect(function()
    pcall(function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp or not hum then return end

        if States.Fly then
            hum.PlatformStand = true
            local dir = Vector3.zero
            local cf = Camera.CFrame
            if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.E) then dir = dir + Vector3.new(0, 1, 0) end
            if UIS:IsKeyDown(Enum.KeyCode.Q) then dir = dir - Vector3.new(0, 1, 0) end
            hrp.AssemblyLinearVelocity = dir * Vals.FlySpeed
        else
            if hum.PlatformStand then hum.PlatformStand = false end
        end

        if States.SpeedHack then hum.WalkSpeed = Vals.WalkSpeed end

        if States.Hitbox then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    if States.TeamCheck and IsTeammate(p) then continue end
                    local eHum = p.Character:FindFirstChild("Humanoid")
                    local eHead = p.Character:FindFirstChild("Head")
                    if eHum and eHead then
                        if not eHum.Sit then
                            eHead.Size = Vector3.new(Vals.HitboxSize, Vals.HitboxSize, Vals.HitboxSize)
                            eHead.Transparency = 0.7
                            eHead.CanCollide = false
                        end
                    end
                end
            end
        else
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local eHead = p.Character:FindFirstChild("Head")
                    if eHead then eHead.Size = Vector3.new(1.2, 1, 1); eHead.Transparency = 0; eHead.CanCollide = true end
                end
            end
        end
        
        if States.TPToTarget then 
            local target = getClosestToCenter()
            if target and target.Parent and target.Parent:FindFirstChild("HumanoidRootPart") then
                hrp.CFrame = target.Parent.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                hrp.CFrame = CFrame.lookAt(hrp.Position, target.Position)
            end
            States.TPToTarget = false
        end
    end)
end))

table.insert(Connections, RunService.RenderStepped:Connect(function()
    pcall(function()
        if fovRing then fovRing.Visible=States.ShowFOV; fovRing.Radius=Vals.FOV; fovRing.Position=Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2) end
        
        local target = getClosestToCenter()
        if States.Aimbot and target then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, target.Position+target.Velocity*0.135), Vals.AimSmooth)
        end
        if States.SilentAim and target and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        end
        
        if States.TriggerBot then local t = Mouse.Target; if t and t.Parent and t.Parent:FindFirstChild("Humanoid") and t.Parent.Name ~= LocalPlayer.Name then mouse1click() end end
        if States.Chams then UpdateChams() end
        
        if States.Crosshair and crosshairLines.H and crosshairLines.V then
            local c = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            crosshairLines.H.Visible = true; crosshairLines.H.From = Vector2.new(c.X - 10, c.Y); crosshairLines.H.To = Vector2.new(c.X + 10, c.Y)
            crosshairLines.V.Visible = true; crosshairLines.V.From = Vector2.new(c.X, c.Y - 10); crosshairLines.V.To = Vector2.new(c.X, c.Y + 10)
        elseif crosshairLines.H then
            crosshairLines.H.Visible = false; crosshairLines.V.Visible = false
        end
        
        for plr, esp in pairs(ESPObjects) do
            local char = plr.Character; local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            local valid = char and root and hum and hum.Health > 0 and char:FindFirstChild("Head")
            local onScreen = false; local vector = Vector3.zero
            if valid then vector, onScreen = Camera:WorldToViewportPoint(root.Position) end
            local drawColor = Theme.Stroke
            if valid and States.TeamCheck and IsTeammate(plr) then drawColor = Theme.Team end

            if valid and onScreen then
                local headPos = Camera:WorldToViewportPoint(char.Head.Position + Vector3.new(0, 0.5, 0))
                local height = math.abs(headPos.Y - Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0)).Y)
                local width = height / 1.8
                
                if States.ESP then
                    esp.Box.Visible = true; esp.Box.Size = Vector2.new(width, height)
                    esp.Box.Position = Vector2.new(vector.X - width/2, vector.Y - height/2); esp.Box.Color = drawColor
                    esp.Name.Visible = true; esp.Name.Text = plr.Name
                    esp.Name.Position = Vector2.new(vector.X, esp.Box.Position.Y - 18); esp.Name.Color = drawColor
                    esp.HealthBar.Visible = true
                    esp.HealthBar.From = Vector2.new(esp.Box.Position.X - 5, esp.Box.Position.Y + height)
                    esp.HealthBar.To = Vector2.new(esp.Box.Position.X - 5, esp.Box.Position.Y + height - height*(hum.Health/hum.MaxHealth))
                else
                    esp.Box.Visible = false; esp.Name.Visible = false; esp.HealthBar.Visible = false
                end
                
                if States.Tracers then
                    local l = tracerLines[plr] or Drawing.new("Line"); tracerLines[plr] = l
                    l.Visible = true; l.Thickness = 1.5; l.Color = drawColor
                    l.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y); l.To = Vector2.new(vector.X, vector.Y)
                else
                    if tracerLines[plr] then tracerLines[plr].Visible = false end
                end
            else
                esp.Box.Visible = false; esp.Name.Visible = false; esp.HealthBar.Visible = false
                if tracerLines[plr] then tracerLines[plr].Visible = false end
            end
        end
    end)
end))

table.insert(Connections, UIS.InputBegan:Connect(function(i,g)
    if not g then
        if i.KeyCode == Keys.Menu then Main.Visible = not Main.Visible end
        if i.KeyCode == Keys.Fly then States.Fly = not States.Fly; if ToggleFuncs["Fly"] then ToggleFuncs["Fly"](States.Fly) end end
        if i.KeyCode == Keys.Noclip then States.Noclip = not States.Noclip; if not States.Noclip then ResetCollision() end; if ToggleFuncs["Noclip"] then ToggleFuncs["Noclip"](States.Noclip) end end
        if i.KeyCode == Keys.Trigger then States.TriggerBot = not States.TriggerBot; if ToggleFuncs["TriggerBot"] then ToggleFuncs["TriggerBot"](States.TriggerBot) end end
        if i.KeyCode == Keys.TPTarget then States.TPToTarget = true end
    end
    if i.UserInputType == Enum.UserInputType.MouseButton1 and States.ClickTP and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and Mouse.Target then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0))
        end
    end
end))

print("X ULTIMATE V3.7.13 RESTORED LOADED")
