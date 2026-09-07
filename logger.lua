-- ============================================================
--  BotMovement.lua  —  LocalScript → StarterPlayerScripts
-- ============================================================

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local CFG = {
    SupplyNames     = { "Egg" },
    SupplyTokenName = "EggToken",
    ArrivalDistance = 5,
    MoveTimeout     = 8,
    CycleDelay      = 0.5,
}

-- ────────────────────────────────────────────────────────────
--  REFERENSI KARAKTER (selalu LocalPlayer)
-- ────────────────────────────────────────────────────────────
local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid")
local rootPart  = character:WaitForChild("HumanoidRootPart")

-- Base Position — nil sampai user klik "Set Base"
local basePosition = nil

-- Flag kontrol loop
local botRunning = false
local botThread  = nil

-- ────────────────────────────────────────────────────────────
--  findNearestSupply()
-- ────────────────────────────────────────────────────────────
local function findNearestSupply()
    local nearest     = nil
    local nearestDist = math.huge
    local botPos      = rootPart.Position

    for _, obj in ipairs(workspace:GetDescendants()) do
        local isSupply = false

        for _, name in ipairs(CFG.SupplyNames) do
            if obj.Name == name then isSupply = true; break end
        end
        if not isSupply and obj:FindFirstChild(CFG.SupplyTokenName) then
            isSupply = true
        end

        if isSupply then
            local targetPos
            if obj:IsA("Model") then
                if obj.PrimaryPart then
                    targetPos = obj.PrimaryPart.Position
                else
                    local p = obj:FindFirstChildWhichIsA("BasePart")
                    if p then targetPos = p.Position end
                end
            elseif obj:IsA("BasePart") then
                targetPos = obj.Position
            end

            if targetPos then
                local dist = (botPos - targetPos).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearest     = targetPos
                end
            end
        end
    end

    return nearest
end

-- ────────────────────────────────────────────────────────────
--  moveToPosition() — dengan timeout
-- ────────────────────────────────────────────────────────────
local function moveToPosition(targetPos)
    humanoid:MoveTo(targetPos)
    local startTime = tick()
    local reached   = false
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if (rootPart.Position - targetPos).Magnitude <= CFG.ArrivalDistance then
            reached = true
            conn:Disconnect()
        elseif tick() - startTime >= CFG.MoveTimeout then
            conn:Disconnect()
        end
    end)
    while conn.Connected do task.wait() end
    return reached
end

-- ════════════════════════════════════════════════════════════
--  GUI
-- ════════════════════════════════════════════════════════════
local gui = Instance.new("ScreenGui")
gui.Name           = "BotGui"
gui.ResetOnSpawn   = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent         = player:WaitForChild("PlayerGui")

-- ── Tombol toggle utama (kotak biru) ────────────────────────
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size             = UDim2.new(0, 90, 0, 32)
toggleBtn.Position         = UDim2.new(0, 12, 1, -120)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 210)
toggleBtn.BorderSizePixel  = 0
toggleBtn.Text             = "BOT LOG"
toggleBtn.TextColor3       = Color3.new(1, 1, 1)
toggleBtn.TextSize         = 13
toggleBtn.Font             = Enum.Font.GothamBold
toggleBtn.ZIndex           = 10
toggleBtn.Parent           = gui

-- ── Panel utama ──────────────────────────────────────────────
local panel = Instance.new("Frame")
panel.Size             = UDim2.new(0, 340, 0, 340)
panel.Position         = UDim2.new(0, 12, 1, -470)
panel.BackgroundColor3 = Color3.fromRGB(12, 12, 22)
panel.BorderSizePixel  = 0
panel.Visible          = false
panel.ZIndex           = 9
panel.Parent           = gui
local panelStroke = Instance.new("UIStroke", panel)
panelStroke.Color     = Color3.fromRGB(30, 100, 210)
panelStroke.Thickness = 1

-- Header panel
local header = Instance.new("Frame")
header.Size             = UDim2.new(1, 0, 0, 30)
header.BackgroundColor3 = Color3.fromRGB(30, 100, 210)
header.BorderSizePixel  = 0
header.ZIndex           = 10
header.Parent           = panel

local headerLabel = Instance.new("TextLabel")
headerLabel.Size               = UDim2.new(1, -36, 1, 0)
headerLabel.Position           = UDim2.new(0, 8, 0, 0)
headerLabel.BackgroundTransparency = 1
headerLabel.Text               = "BOT MOVEMENT LOG"
headerLabel.TextColor3         = Color3.new(1, 1, 1)
headerLabel.TextSize           = 12
headerLabel.Font               = Enum.Font.GothamBold
headerLabel.TextXAlignment     = Enum.TextXAlignment.Left
headerLabel.ZIndex             = 11
headerLabel.Parent             = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size               = UDim2.new(0, 30, 1, 0)
closeBtn.Position           = UDim2.new(1, -30, 0, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text               = "X"
closeBtn.TextColor3         = Color3.new(1, 1, 1)
closeBtn.TextSize           = 13
closeBtn.Font               = Enum.Font.GothamBold
closeBtn.ZIndex             = 11
closeBtn.Parent             = header

-- ── Scroll log ───────────────────────────────────────────────
local scroll = Instance.new("ScrollingFrame")
scroll.Size                 = UDim2.new(1, -8, 1, -110)  -- sisakan ruang untuk panel bawah
scroll.Position             = UDim2.new(0, 4, 0, 32)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel      = 0
scroll.ScrollBarThickness   = 3
scroll.ScrollBarImageColor3 = Color3.fromRGB(30, 100, 210)
scroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
scroll.CanvasSize           = UDim2.new(0, 0, 0, 0)
scroll.ZIndex               = 10
scroll.Parent               = panel

local logLayout = Instance.new("UIListLayout", scroll)
logLayout.Padding   = UDim.new(0, 2)
logLayout.SortOrder = Enum.SortOrder.LayoutOrder
local logPad = Instance.new("UIPadding", scroll)
logPad.PaddingTop   = UDim.new(0, 4)
logPad.PaddingLeft  = UDim.new(0, 4)
logPad.PaddingRight = UDim.new(0, 4)

-- ── Panel bawah: Set Base + Start/Stop ───────────────────────
local bottomPanel = Instance.new("Frame")
bottomPanel.Size             = UDim2.new(1, 0, 0, 108)
bottomPanel.Position         = UDim2.new(0, 0, 1, -108)
bottomPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 34)
bottomPanel.BorderSizePixel  = 0
bottomPanel.ZIndex           = 10
bottomPanel.Parent           = panel

local bottomStroke = Instance.new("UIStroke", bottomPanel)
bottomStroke.Color     = Color3.fromRGB(30, 100, 210)
bottomStroke.Thickness = 1
bottomStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local bottomPad = Instance.new("UIPadding", bottomPanel)
bottomPad.PaddingTop    = UDim.new(0, 10)
bottomPad.PaddingBottom = UDim.new(0, 10)
bottomPad.PaddingLeft   = UDim.new(0, 10)
bottomPad.PaddingRight  = UDim.new(0, 10)

local bottomLayout = Instance.new("UIListLayout", bottomPanel)
bottomLayout.FillDirection  = Enum.FillDirection.Vertical
bottomLayout.Padding        = UDim.new(0, 8)
bottomLayout.SortOrder      = Enum.SortOrder.LayoutOrder

-- Label info Base
local baseLabel = Instance.new("TextLabel")
baseLabel.LayoutOrder         = 1
baseLabel.Size                = UDim2.new(1, 0, 0, 20)
baseLabel.BackgroundTransparency = 1
baseLabel.Text                = "Base: belum diset"
baseLabel.TextColor3          = Color3.fromRGB(120, 160, 255)
baseLabel.TextSize            = 11
baseLabel.Font                = Enum.Font.Code
baseLabel.TextXAlignment      = Enum.TextXAlignment.Left
baseLabel.ZIndex              = 11
baseLabel.Parent              = bottomPanel

-- Tombol Set Base
local setBaseBtn = Instance.new("TextButton")
setBaseBtn.LayoutOrder         = 2
setBaseBtn.Size                = UDim2.new(1, 0, 0, 28)
setBaseBtn.BackgroundColor3    = Color3.fromRGB(30, 80, 160)
setBaseBtn.BorderSizePixel     = 0
setBaseBtn.Text                = "Set Base  (posisi sekarang)"
setBaseBtn.TextColor3          = Color3.new(1, 1, 1)
setBaseBtn.TextSize            = 12
setBaseBtn.Font                = Enum.Font.GothamBold
setBaseBtn.ZIndex              = 11
setBaseBtn.Parent              = bottomPanel

-- Tombol Start / Stop
local startBtn = Instance.new("TextButton")
startBtn.LayoutOrder         = 3
startBtn.Size                = UDim2.new(1, 0, 0, 28)
startBtn.BackgroundColor3    = Color3.fromRGB(30, 100, 210)
startBtn.BorderSizePixel     = 0
startBtn.Text                = "Start Auto Collect"
startBtn.TextColor3          = Color3.new(1, 1, 1)
startBtn.TextSize            = 12
startBtn.Font                = Enum.Font.GothamBold
startBtn.ZIndex              = 11
startBtn.Parent              = bottomPanel

-- ════════════════════════════════════════════════════════════
--  LOG HELPER
-- ════════════════════════════════════════════════════════════
local logIdx = 0
local function pushLog(msg, color)
    logIdx += 1
    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(1, 0, 0, 0)
    lbl.AutomaticSize      = Enum.AutomaticSize.Y
    lbl.BackgroundTransparency = 1
    lbl.Text               = os.date("%H:%M:%S") .. "  " .. msg
    lbl.TextColor3         = color or Color3.fromRGB(160, 200, 255)
    lbl.TextSize           = 11
    lbl.Font               = Enum.Font.Code
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.TextWrapped        = true
    lbl.LayoutOrder        = logIdx
    lbl.ZIndex             = 11
    lbl.Parent             = scroll
    task.defer(function()
        scroll.CanvasPosition = Vector2.new(0, math.huge)
    end)
end

-- ════════════════════════════════════════════════════════════
--  MAIN BOT LOOP
-- ════════════════════════════════════════════════════════════
local function runBot()
    local cycle = 0
    while botRunning do
        if humanoid.Health <= 0 then
            pushLog("Bot mati — berhenti.", Color3.fromRGB(255, 100, 100))
            break
        end

        cycle += 1
        pushLog(string.format("── Siklus #%d ──", cycle),
                Color3.fromRGB(100, 160, 255))

        -- ① Cari supply terdekat
        local supplyPos = findNearestSupply()

        if supplyPos then
            pushLog(string.format("Egg ditemukan (%.0f, %.0f, %.0f)",
                supplyPos.X, supplyPos.Y, supplyPos.Z))
            pushLog("Menuju Egg...")
            local ok = moveToPosition(supplyPos)
            pushLog(ok and "Egg diambil." or "Timeout ke Egg.",
                    ok and Color3.fromRGB(100, 220, 130) or Color3.fromRGB(255, 180, 60))
        else
            pushLog("Tidak ada Egg — langsung ke Base.",
                    Color3.fromRGB(200, 180, 80))
        end

        -- ② Kembali ke Base
        if basePosition then
            pushLog("Kembali ke Base...")
            local ok = moveToPosition(basePosition)
            pushLog(ok and "Sampai Base — bongkar muatan." or "Timeout ke Base.",
                    ok and Color3.fromRGB(100, 220, 130) or Color3.fromRGB(255, 180, 60))
        else
            pushLog("Base belum diset! Set Base dulu.",
                    Color3.fromRGB(255, 100, 100))
        end

        task.wait(CFG.CycleDelay)
    end

    pushLog("Bot dihentikan.", Color3.fromRGB(255, 120, 120))
    startBtn.Text             = "Start Auto Collect"
    startBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 210)
    botRunning = false
end

-- ════════════════════════════════════════════════════════════
--  KONEKSI TOMBOL
-- ════════════════════════════════════════════════════════════

-- Toggle panel
local isOpen = false
toggleBtn.MouseButton1Click:Connect(function()
    isOpen        = not isOpen
    panel.Visible = isOpen
    toggleBtn.BackgroundColor3 = isOpen
        and Color3.fromRGB(20, 60, 140)
        or  Color3.fromRGB(30, 100, 210)
end)

closeBtn.MouseButton1Click:Connect(function()
    isOpen        = false
    panel.Visible = false
    toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 210)
end)

-- Set Base → ambil posisi karakter sekarang
setBaseBtn.MouseButton1Click:Connect(function()
    basePosition = rootPart.Position
    local p = basePosition
    baseLabel.Text      = string.format("Base: (%.1f, %.1f, %.1f)", p.X, p.Y, p.Z)
    baseLabel.TextColor3 = Color3.fromRGB(100, 220, 130)
    setBaseBtn.BackgroundColor3 = Color3.fromRGB(20, 100, 60)
    setBaseBtn.Text     = "Base diset! (klik lagi untuk ubah)"
    pushLog(string.format("Base diset: (%.1f, %.1f, %.1f)", p.X, p.Y, p.Z),
            Color3.fromRGB(100, 220, 130))
end)

-- Start / Stop bot
startBtn.MouseButton1Click:Connect(function()
    if botRunning then
        -- Stop
        botRunning = false
        -- botThread akan berhenti sendiri di iterasi berikutnya
    else
        -- Validasi Base dulu
        if not basePosition then
            pushLog("Set Base dulu sebelum mulai!", Color3.fromRGB(255, 100, 100))
            return
        end
        botRunning = true
        startBtn.Text             = "Stop Bot"
        startBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        pushLog("Bot dimulai!", Color3.fromRGB(100, 220, 130))
        task.spawn(runBot)
    end
end)

-- Log awal
pushLog("Siap. Set Base lalu tekan Start.")
