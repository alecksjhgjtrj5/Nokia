getgenv().Settings = {
    refreshRate = nil, -- nil = every frame

    teamCheck = true,
    ignoreDead = true,
    includeSelf = true,
    maxDistance = math.huge,

    Boxes = {
        Enabled = false,
        Outline = true,
        Filled = false,
        Color = Color3.fromRGB(255,255,255),
        OutlineColor = Color3.fromRGB(0,0,0)
    },

    Tracers = {
        Enabled = false,
        Thickness = 1.5,
        Color = Color3.fromRGB(255,255,255)
    },

    Names = {
        Enabled = false,
        Outline = true
    },

    Tool = {
        Enabled = false,
        Outline = true,
    },

    HealthText = {
        Enabled = false,
        Outline = true
    },

    Healthbar = {
        Enabled = false,
        FillColor = Color3.fromRGB(0,255,0)
    }
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local ESP = {}

local function RemoveESP(plr)
    if ESP[plr] then
        for _, element in pairs(ESP[plr]) do
            element:Remove()
        end
        ESP[plr] = nil
    end
end

local function AddPlayer(plr)
    local Elements = {}

    Elements.Box = Drawing.new("Square")
    Elements.BoxOutline = Drawing.new("Square")
    Elements.NameLabel = Drawing.new("Text")
    Elements.HealthLabel = Drawing.new("Text")
    Elements.ToolLabel = Drawing.new("Text")
    Elements.Healthbar = Drawing.new("Square")
    Elements.HealthbarFilling = Drawing.new("Square")
    Elements.Tracer = Drawing.new("Line")

    Elements.NameLabel.Center = true
    Elements.HealthLabel.Center = true
    Elements.ToolLabel.Center = true

    Elements.NameLabel.Outline = true
    Elements.HealthLabel.Outline = true
    Elements.ToolLabel.Outline = true

    ESP[plr] = Elements
end

local function UpdateESP(plr)
    local Elements = ESP[plr]
    if not Elements then return end

    local myChar = Player.Character
    local char = plr.Character
    if not (myChar and char) then
        for _, e in pairs(Elements) do e.Visible = false end
        return
    end

    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    local root = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    local humanoid = char:FindFirstChild("Humanoid")
    if not (myRoot and root and head and humanoid) then
        for _, e in pairs(Elements) do e.Visible = false end
        return
    end

    local showEsp = true
    local dist = (myRoot.Position - root.Position).Magnitude

    if Settings.teamCheck and plr.Team == Player.Team and plr.Team ~= nil then showEsp = false end
    if not Settings.includeSelf and plr == Player then showEsp = false end
    if humanoid.Health <= 0 and Settings.ignoreDead then showEsp = false end
    if dist > Settings.maxDistance then showEsp = false end

    if not showEsp then
        for _, e in pairs(Elements) do e.Visible = false end
        return
    end

    local rootPos, rootVis = Camera:WorldToViewportPoint(root.Position)
    local legsPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 0.5, 0))
    local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.75, 0) + Vector3.new(0, head.Size.Y / 2, 0))
    local myRootPos = Camera:WorldToViewportPoint(myRoot.Position)

    if not rootVis then
        for _, e in pairs(Elements) do e.Visible = false end
        return
    end

    local height = math.abs(legsPos.Y - headPos.Y) * 2
    local width = height / 1.5
    local textSize = math.clamp(20 - (dist * 0.075), 12, 20)

    -- Box
    Elements.Box.Size = Vector2.new(width, height)
    Elements.Box.Position = Vector2.new(legsPos.X - width / 2, legsPos.Y - height / 2)
    Elements.Box.Visible = Settings.Boxes.Enabled
    Elements.Box.Filled = Settings.Boxes.Filled
    Elements.Box.Color = Settings.Boxes.Color
    Elements.Box.Transparency = Settings.Boxes.Filled and 0.5 or 1

    Elements.BoxOutline.Size = Vector2.new(width + 2, height + 2)
    Elements.BoxOutline.Position = Elements.Box.Position + Vector2.new(-1, -1)
    Elements.BoxOutline.Visible = Settings.Boxes.Enabled and Settings.Boxes.Outline
    Elements.BoxOutline.Color = Settings.Boxes.OutlineColor

    -- Name
    Elements.NameLabel.Size = textSize
    Elements.NameLabel.Position = Elements.Box.Position + Vector2.new(width / 2, -textSize * 1.5)
    Elements.NameLabel.Text = plr.Name
    Elements.NameLabel.Outline = Settings.Names.Outline
    Elements.NameLabel.Visible = Settings.Names.Enabled

    -- Health Text
    Elements.HealthLabel.Size = textSize
    Elements.HealthLabel.Position = Elements.Box.Position + Vector2.new(width / 2, -textSize * 2.5)
    Elements.HealthLabel.Text = "Health: " .. math.round(humanoid.Health)
    Elements.HealthLabel.Outline = Settings.HealthText.Outline
    Elements.HealthLabel.Visible = Settings.HealthText.Enabled

    -- Tool
    local tool = char:FindFirstChildWhichIsA("Tool")
    Elements.ToolLabel.Size = textSize
    Elements.ToolLabel.Position = Elements.Box.Position + Vector2.new(width / 2, height + textSize * 0.1)
    Elements.ToolLabel.Outline = Settings.Tool.Outline
    Elements.ToolLabel.Visible = Settings.Tool.Enabled
    Elements.ToolLabel.Text = tool and tool.Name or "None"

    -- Healthbar
    local healthRatio = humanoid.Health / humanoid.MaxHealth
    Elements.Healthbar.Size = Vector2.new(3, height)
    Elements.Healthbar.Position = Elements.Box.Position + Vector2.new(-7, 0)
    Elements.Healthbar.Visible = Settings.Healthbar.Enabled

    Elements.HealthbarFilling.Size = Vector2.new(3, height * healthRatio)
    Elements.HealthbarFilling.Position = Elements.Box.Position + Vector2.new(-7, height * (1 - healthRatio))
    Elements.HealthbarFilling.Color = Settings.Healthbar.FillColor
    Elements.HealthbarFilling.Visible = Settings.Healthbar.Enabled

    -- Tracer
    Elements.Tracer.From = Vector2.new(myRootPos.X, myRootPos.Y)
    Elements.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
    Elements.Tracer.Thickness = Settings.Tracers.Thickness
    Elements.Tracer.Color = Settings.Tracers.Color
    Elements.Tracer.Visible = Settings.Tracers.Enabled
end

Players.PlayerAdded:Connect(AddPlayer)
Players.PlayerRemoving:Connect(RemoveESP)

for _, plr in pairs(Players:GetPlayers()) do
    AddPlayer(plr)
end

RunService.RenderStepped:Connect(function()
    for plr in pairs(ESP) do
        UpdateESP(plr)
    end
end)

return Settings
