-- Universal RemoteEvent Logger with GUI (ICON FIXED)
-- LocalScript → StarterPlayerScripts
-- Fix: FAB pakai ImageButton + rbxassetid, fallback ke TextButton tanpa emoji

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ════════════════════════════════════════════════════════════
--  SCREEN GUI
-- ════════════════════════════════════════════════════════════
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "RemoteLogger"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = playerGui

-- ════════════════════════════════════════════════════════════
--  FAB TOMBOL TOGGLE  (ImageButton — icon pasti muncul)
-- ════════════════════════════════════════════════════════════
-- Kita pakai ImageButton dengan icon dari Roblox asset library.
-- rbxassetid://3926307971 = icon "list/log" (Roblox Studio icon sheet)
-- Jika ingin ganti icon, cukup ubah ImageRectOffset & ImageRectSize.

local fab = Instance.new("ImageButton")
fab.Size                  = UDim2.new(0, 56, 0, 56)
fab.Position              = UDim2.new(0.5, -28, 1, -120)
fab.BackgroundColor3      = Color3.fromRGB(26, 26, 46)
fab.BorderSizePixel       = 0
fab.ZIndex                = 10
fab.Image                 = "rbxassetid://3926307971"  -- Roblox UI icon sheet
fab.ImageRectOffset       = Vector2.new(4, 804)        -- icon "view list"
fab.ImageRectSize         = Vector2.new(36, 36)
fab.ImageColor3           = Color3.fromRGB(74, 222, 128)
fab.ScaleType             = Enum.ScaleType.Fit
fab.Parent                = screenGui
Instance.new("UICorner", fab).CornerRadius = UDim.new(1, 0)  -- bulat sempurna

local fabStroke = Instance.new("UIStroke", fab)
fabStroke.Color     = Color3.fromRGB(74, 222, 128)
fabStroke.Thickness = 2

-- Label kecil di bawah FAB supaya user tau fungsinya
local fabLabel = Instance.new("TextLabel")
fabLabel.Size               = UDim2.new(0, 80, 0, 18)
fabLabel.Position           = UDim2.new(0.5, -40, 1, -58)
fabLabel.BackgroundTransparency = 1
fabLabel.Text               = "LOGGER"
fabLabel.TextColor3         = Color3.fromRGB(74, 222, 128)
fabLabel.TextSize           = 11
fabLabel.Font               = Enum.Font.GothamBold
fabLabel.TextXAlignment     = Enum.TextXAlignment.Center
fabLabel.ZIndex             = 10
fabLabel.Parent             = screenGui

-- ════════════════════════════════════════════════════════════
--  TOMBOL COPY ALL (floating, selalu kelihatan)
-- ════════════════════════════════════════════════════════════
local copyFloating = Instance.new("ImageButton")
copyFloating.Size             = UDim2.new(0, 44, 0, 44)
copyFloating.Position         = UDim2.new(0.5, 36, 1, -120)   -- kanan FAB
copyFloating.BackgroundColor3 = Color3.fromRGB(58, 180, 100)
copyFloating.BorderSizePixel  = 0
copyFloating.ZIndex           = 10
copyFloating.Image            = "rbxassetid://3926307971"
copyFloating.ImageRectOffset  = Vector2.new(324, 604)         -- icon "copy/clipboard"
copyFloating.ImageRectSize    = Vector2.new(36, 36)
copyFloating.ImageColor3      = Color3.fromRGB(15, 15, 26)
copyFloating.ScaleType        = Enum.ScaleType.Fit
copyFloating.Parent           = screenGui
Instance.new("UICorner", copyFloating).CornerRadius = UDim.new(1, 0)

local copyLabel = Instance.new("TextLabel")
copyLabel.Size               = UDim2.new(0, 56, 0, 18)
copyLabel.Position           = UDim2.new(0.5, 22, 1, -58)
copyLabel.BackgroundTransparency = 1
copyLabel.Text               = "COPY"
copyLabel.TextColor3         = Color3.fromRGB(58, 180, 100)
copyLabel.TextSize           = 11
copyLabel.Font               = Enum.Font.GothamBold
copyLabel.TextXAlignment     = Enum.TextXAlignment.Center
copyLabel.ZIndex             = 10
copyLabel.Parent             = screenGui

-- ════════════════════════════════════════════════════════════
--  PANEL UTAMA
-- ════════════════════════════════════════════════════════════
local panel = Instance.new("Frame")
panel.Name              = "Panel"
panel.Size              = UDim2.new(0.95, 0, 0.65, 0)
panel.Position          = UDim2.new(0.025, 0, 0.05, 0)
panel.BackgroundColor3  = Color3.fromRGB(15, 15, 26)
panel.BorderSizePixel   = 0
panel.Visible           = false
panel.ZIndex            = 9
panel.Parent            = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
local panelStroke = Instance.new("UIStroke", panel)
panelStroke.Color     = Color3.fromRGB(45, 45, 78)
panelStroke.Thickness = 1

-- Header
local header = Instance.new("Frame")
header.Size             = UDim2.new(1, 0, 0, 44)
header.BackgroundColor3 = Color3.fromRGB(26, 26, 46)
header.BorderSizePixel  = 0
header.ZIndex           = 10
header.Parent           = panel
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)

-- patch sudut bawah header agar tidak melengkung di bawah
local headerFix = Instance.new("Frame")
headerFix.Size            = UDim2.new(1, 0, 0, 12)
headerFix.Position        = UDim2.new(0, 0, 1, -12)
headerFix.BackgroundColor3 = Color3.fromRGB(26, 26, 46)
headerFix.BorderSizePixel = 0
headerFix.ZIndex          = 10
headerFix.Parent          = header

-- Icon kecil di header (ImageLabel, bukan emoji)
local headerIcon = Instance.new("ImageLabel")
headerIcon.Size             = UDim2.new(0, 22, 0, 22)
headerIcon.Position         = UDim2.new(0, 10, 0.5, -11)
headerIcon.BackgroundTransparency = 1
headerIcon.Image            = "rbxassetid://3926307971"
headerIcon.ImageRectOffset  = Vector2.new(4, 804)
headerIcon.ImageRectSize    = Vector2.new(36, 36)
headerIcon.ImageColor3      = Color3.fromRGB(74, 222, 128)
headerIcon.ZIndex           = 11
headerIcon.Parent           = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Size             = UDim2.new(1, -120, 1, 0)
titleLabel.Position         = UDim2.new(0, 38, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text             = "REMOTE LOGGER"
titleLabel.TextColor3       = Color3.fromRGB(74, 222, 128)
titleLabel.TextSize         = 13
titleLabel.Font             = Enum.Font.GothamBold
titleLabel.TextXAlignment   = Enum.TextXAlignment.Left
titleLabel.ZIndex           = 11
titleLabel.Parent           = header

local counterLabel = Instance.new("TextLabel")
counterLabel.Size               = UDim2.new(0, 80, 1, 0)
counterLabel.Position           = UDim2.new(1, -130, 0, 0)
counterLabel.BackgroundTransparency = 1
counterLabel.Text               = "0 log"
counterLabel.TextColor3         = Color3.fromRGB(96, 96, 160)
counterLabel.TextSize           = 11
counterLabel.Font               = Enum.Font.Gotham
counterLabel.TextXAlignment     = Enum.TextXAlignment.Right
counterLabel.ZIndex             = 11
counterLabel.Parent             = header

-- Tombol close di header (X teks, bukan emoji — pasti render)
local closeBtn = Instance.new("TextButton")
closeBtn.Size               = UDim2.new(0, 36, 0, 30)
closeBtn.Position           = UDim2.new(1, -42, 0.5, -15)
closeBtn.BackgroundTransparency = 1
closeBtn.Text               = "X"          -- huruf biasa, bukan emoji
closeBtn.TextColor3         = Color3.fromRGB(200, 100, 100)
closeBtn.TextSize           = 15
closeBtn.Font               = Enum.Font.GothamBold
closeBtn.ZIndex             = 11
closeBtn.Parent             = header

-- ════════════════════════════════════════════════════════════
--  LOG AREA (ScrollingFrame)
-- ════════════════════════════════════════════════════════════
local logArea = Instance.new("ScrollingFrame")
logArea.Size                  = UDim2.new(1, -8, 1, -50)
logArea.Position              = UDim2.new(0, 4, 0, 48)
logArea.BackgroundTransparency = 1
logArea.BorderSizePixel       = 0
logArea.ScrollBarThickness    = 4
logArea.ScrollBarImageColor3  = Color3.fromRGB(45, 45, 78)
logArea.CanvasSize            = UDim2.new(0, 0, 0, 0)
logArea.AutomaticCanvasSize   = Enum.AutomaticSize.Y
logArea.ZIndex                = 10
logArea.Parent                = panel

local listLayout = Instance.new("UIListLayout", logArea)
listLayout.Padding    = UDim.new(0, 4)
listLayout.SortOrder  = Enum.SortOrder.LayoutOrder

local logPad = Instance.new("UIPadding", logArea)
logPad.PaddingTop    = UDim.new(0, 4)
logPad.PaddingBottom = UDim.new(0, 4)

-- ════════════════════════════════════════════════════════════
--  SERIALIZER
-- ════════════════════════════════════════════════════════════
local function serializeArg(arg, depth)
    depth = depth or 0
    local indent = string.rep("  ", depth)
    if type(arg) == "table" then
        local parts = {}
        for k, v in pairs(arg) do
            table.insert(parts, indent .. "  [" .. tostring(k) .. "] = " .. serializeArg(v, depth + 1))
        end
        return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
    elseif typeof(arg) == "Instance" then
        return "<" .. arg.ClassName .. ": '" .. arg.Name .. "'>"
    elseif typeof(arg) == "Vector3" then
        return string.format("Vector3(%.2f, %.2f, %.2f)", arg.X, arg.Y, arg.Z)
    elseif typeof(arg) == "CFrame" then
        local p = arg.Position
        return string.format("CFrame(%.2f, %.2f, %.2f)", p.X, p.Y, p.Z)
    elseif typeof(arg) == "Color3" then
        return string.format("Color3(%.2f, %.2f, %.2f)", arg.R, arg.G, arg.B)
    elseif type(arg) == "string" then
        return '"' .. arg .. '"'
    else
        return tostring(arg)
    end
end

local function formatArgs(args)
    if #args == 0 then return "(no args)" end
    local parts = {}
    for i, v in ipairs(args) do
        table.insert(parts, "Arg[" .. i .. "]: " .. serializeArg(v))
    end
    return table.concat(parts, "\n")
end

-- ════════════════════════════════════════════════════════════
--  TAMBAH LOG ENTRY
-- ════════════════════════════════════════════════════════════
local allLogs  = {}
local logCount = 0

local function addLogEntry(remoteName, argsText)
    logCount += 1
    local time     = os.date("%H:%M:%S")
    local fullText = "[" .. time .. "] " .. remoteName .. "\n" .. argsText
    table.insert(allLogs, fullText)
    counterLabel.Text = logCount .. " log"

    local entry = Instance.new("TextButton")
    entry.Size            = UDim2.new(1, 0, 0, 0)
    entry.AutomaticSize   = Enum.AutomaticSize.Y
    entry.BackgroundColor3 = Color3.fromRGB(26, 26, 46)
    entry.BorderSizePixel = 0
    entry.TextTransparency = 1
    entry.LayoutOrder     = logCount
    entry.ZIndex          = 11
    entry.Parent          = logArea
    Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 6)

    local leftBar = Instance.new("Frame", entry)
    leftBar.Size             = UDim2.new(0, 3, 1, 0)
    leftBar.BackgroundColor3 = Color3.fromRGB(74, 222, 128)
    leftBar.BorderSizePixel  = 0
    leftBar.ZIndex           = 12

    local textLabel = Instance.new("TextLabel", entry)
    textLabel.Size              = UDim2.new(1, -14, 0, 0)
    textLabel.Position          = UDim2.new(0, 10, 0, 6)
    textLabel.AutomaticSize     = Enum.AutomaticSize.Y
    textLabel.BackgroundTransparency = 1
    textLabel.Text              = fullText
    textLabel.TextColor3        = Color3.fromRGB(180, 200, 255)
    textLabel.TextSize          = 11
    textLabel.Font              = Enum.Font.Code
    textLabel.TextXAlignment    = Enum.TextXAlignment.Left
    textLabel.TextWrapped       = true
    textLabel.ZIndex            = 12

    local pad = Instance.new("UIPadding", entry)
    pad.PaddingLeft   = UDim.new(0, 10)
    pad.PaddingRight  = UDim.new(0, 6)
    pad.PaddingTop    = UDim.new(0, 6)
    pad.PaddingBottom = UDim.new(0, 6)

    -- Klik entry = copy entry itu saja
    entry.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(fullText)
        end
        textLabel.TextColor3 = Color3.fromRGB(74, 222, 128)
        task.wait(0.5)
        textLabel.TextColor3 = Color3.fromRGB(180, 200, 255)
    end)

    task.defer(function()
        logArea.CanvasPosition = Vector2.new(0, logArea.AbsoluteCanvasSize.Y)
    end)
end

-- ════════════════════════════════════════════════════════════
--  HOOK REMOTE
-- ════════════════════════════════════════════════════════════
local function hookRemote(remote)
    remote.OnClientEvent:Connect(function(...)
        addLogEntry(remote:GetFullName(), formatArgs({...}))
    end)
end

local function scanAndHook(parent)
    for _, obj in ipairs(parent:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            hookRemote(obj)
        end
    end
    parent.DescendantAdded:Connect(function(obj)
        if obj:IsA("RemoteEvent") then
            task.wait(0.1)
            hookRemote(obj)
        end
    end)
end

-- ════════════════════════════════════════════════════════════
--  KONTROL TOMBOL
-- ════════════════════════════════════════════════════════════
local isPanelOpen = false

fab.MouseButton1Click:Connect(function()
    isPanelOpen = not isPanelOpen
    panel.Visible = isPanelOpen
    -- Animasi sederhana: pulse warna border FAB
    fabStroke.Color = isPanelOpen
        and Color3.fromRGB(255, 255, 100)
        or  Color3.fromRGB(74, 222, 128)
end)

closeBtn.MouseButton1Click:Connect(function()
    isPanelOpen   = false
    panel.Visible = false
    fabStroke.Color = Color3.fromRGB(74, 222, 128)
end)

copyFloating.MouseButton1Click:Connect(function()
    if #allLogs == 0 then
        copyLabel.Text      = "KOSONG!"
        copyLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        task.wait(1)
        copyLabel.Text      = "COPY"
        copyLabel.TextColor3 = Color3.fromRGB(58, 180, 100)
        return
    end
    if setclipboard then
        setclipboard(table.concat(allLogs, "\n---\n"))
    end
    copyLabel.Text      = "DONE!"
    copyLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
    task.wait(1.5)
    copyLabel.Text      = "COPY"
    copyLabel.TextColor3 = Color3.fromRGB(58, 180, 100)
end)

-- ════════════════════════════════════════════════════════════
--  START
-- ════════════════════════════════════════════════════════════
task.wait(1)
scanAndHook(ReplicatedStorage)
scanAndHook(workspace)
