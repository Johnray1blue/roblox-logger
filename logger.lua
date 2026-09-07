-- ============================================================
--  BotMovement.lua  —  LocalScript → StarterPlayerScripts
-- ============================================================

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local CFG = {
    -- Edit nama-nama supply di sini (case-sensitive, harus exact match)
    -- Jalanin "Scan Workspace" dulu buat tau nama aslinya
    SupplyNames     = { "Egg", "Coin", "Crystal", "Supply" },
    
    -- Partial match (case-insensitive) — kalau nama object MENGANDUNG string ini
    SupplyPartial   = { "egg", "coin", "crystal", "gem", "supply", "item", "collect" },

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

local basePosition = nil
local botRunning   = false

-- ────────────────────────────────────────────────────────────
--  isSupplyObject() — cek semua kriteria
-- ────────────────────────────────────────────────────────────
local function isSupplyObject(obj)
    local name = obj.Name

    -- Exact match
    for _, n in ipairs(CFG.SupplyNames) do
        if name == n then return true end
    end

    -- Partial match (case-insensitive)
    local nameLower = name:lower()
    for _, p in ipairs(CFG.SupplyPartial) do
        if nameLower:find(p, 1, true) then return true end
    end

    -- Token child
    if obj:FindFirstChild(CFG.SupplyTokenName) then return true end

    return false
end

-- ────────────────────────────────────────────────────────────
--  getPosition() — ambil posisi dari BasePart atau Model
-- ────────────────────────────────────────────────────────────
local function getPosition(obj)
    if obj:IsA("Model") then
        if obj.PrimaryPart then return obj.PrimaryPart.Position end
        local p = obj:FindFirstChildWhichIsA("BasePart")
        if p then return p.Position end
    elseif obj:IsA("BasePart") then
        return obj.Position
    end
    return nil
end

-- ────────────────────────────────────────────────────────────
--  findNearestSupply()
-- ────────────────────────────────────────────────────────────
local function findNearestSupply()
    local nearest     = nil
    local nearestDist = math.huge
    local nearestName = ""
    local botPos      = rootPart.Position

    for _, obj in ipairs(workspace:GetDescendants()) do
        if isSupplyObject(obj) then
            local targetPos = getPosition(obj)
            if targetPos then
                local dist = (botPos - targetPos).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearest     = targetPos
                    nearestName = obj.Name
                end
            end
        end
    end

    return nearest, nearestName
end

-- ────────────────────────────────────────────────────────────
--  moveToPosition() — dengan timeout
-- ────────────────────────────────────────────────────────────
local function moveToPosition(targetPos)
    humanoid:MoveTo(targetPos)
    local startTime = tick()
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if (rootPart.Position - targetPos).Magnitude <= CFG.ArrivalDistance then
            conn:Disconnect()
        elseif tick() - startTime >= CFG.MoveTimeout then
            conn:Disconnect()
        end
    end)
    while conn.Connected do task.wait() end
    local reached = (rootPart.Position - targetPos).Magnitude <= CFG.ArrivalDistance
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

-- Tombol toggle utama
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

-- Panel utama (diperbesar sedikit buat tombol scan)
local panel = Instance.new("Frame")
panel.Size             = UDim2.new(0, 340, 0, 380)
panel.Position         = UDim2.new(0, 12, 1, -510)
panel.BackgroundColor3 = Color3.fromRGB(12, 12, 22)
panel.BorderSizePixel  = 0
panel.Visible          = false
panel.ZIndex           = 9
panel.Parent           = gui
local panelStroke = Instance.new("UIStroke", panel)
panelStroke.Color     = Color3.fromRGB(30, 100, 210)
panelStroke.Thickness = 1

-- Header
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

-- Scroll log
local scroll = Instance.new("ScrollingFrame")
scroll.Size                 = UDim2.new(1, -8, 1, -148)
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

-- Panel bawah
local bottomPanel = Instance.new("Frame")
bottomPanel.Size             = UDim2.new(1, 0, 0, 145)
bottomPanel.Position         = UDim2.new(0, 0, 1, -145)
bottomPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 34)
bottomPanel.BorderSizePixel  = 0
bottomPanel.ZIndex           = 10
bottomPanel.Parent           = panel

local bottomStroke = Instance.new("UIStroke", bottomPanel)
bottomStroke.Color     = Color3.fromRGB(30, 100, 210)
bottomStroke.Thickness = 1
bottomStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local bottomPad = Instance.new("UIPadding", bottomPanel)
bottomPad.PaddingTop    = UDim.new(0, 8)
bottomPad.PaddingBottom = UDim.new(0, 8)
bottomPad.PaddingLeft   = UDim.new(0, 10)
bottomPad.PaddingRight  = UDim.new(0, 10)

local bottomLayout = Instance.new("UIListLayout", bottomPanel)
bottomLayout.FillDirection  = Enum.FillDirection.Vertical
bottomLayout.Padding        = UDim.new(0, 6)
bottomLayout.SortOrder      = Enum.SortOrder.LayoutOrder

-- Label info Base
local baseLabel = Instance.new("TextLabel")
baseLabel.LayoutOrder         = 1
baseLabel.Size                = UDim2.new(1, 0, 0, 18)
baseLabel.BackgroundTransparency = 1
baseLabel.Text                = "Base: belum diset"
baseLabel.TextColor3          = Color3.fromRGB(120, 160, 255)
baseLabel.TextSize            = 11
baseLabel.Font                = Enum.Font.Code
baseLabel.TextXAlignment      = Enum.TextXAlignment.Left
baseLabel.ZIndex              = 11
baseLabel.Parent              = bottomPanel

-- Tombol Scan Workspace (BARU)
local scanBtn = Instance.new("TextButton")
scanBtn.LayoutOrder         = 2
scanBtn.Size                = UDim2.new(1, 0, 0, 26)
scanBtn.BackgroundColor3    = Color3.fromRGB(80, 40, 120)
scanBtn.BorderSizePixel     = 0
scanBtn.Text                = "🔍 Scan Workspace (cari nama supply)"
scanBtn.TextColor3          = Color3.new(1, 1, 1)
scanBtn.TextSize            = 11
scanBtn.Font                = Enum.Font.GothamBold
scanBtn.ZIndex              = 11
scanBtn.Parent              = bottomPanel

-- Tombol Set Base
local setBaseBtn = Instance.new("TextButton")
setBaseBtn.LayoutOrder         = 3
setBaseBtn.Size                = UDim2.new(1, 0, 0, 26)
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
startBtn.LayoutOrder         = 4
startBtn.Size                = UDim2.new(1, 0, 0, 26)
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
--  WORKSPACE SCANNER — print semua nama object unik di Workspace
-- ════════════════════════════════════════════════════════════
local function scanWorkspace()
    pushLog("── SCAN MULAI ──", Color3.fromRGB(200, 150, 255))

    -- Kumpulkan nama unik + jumlahnya
    local counts = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        -- Skip internal Roblox stuff
        local skip = false
        local parent = obj.Parent
        while parent do
            if parent == character then skip = true; break end
            parent = parent.Parent
        end
        if not skip then
            local n = obj.Name
            counts[n] = (counts[n] or 0) + 1
        end
    end

    -- Sort by count descending
    local list = {}
    for name, count in pairs(counts) do
        table.insert(list, { name = name, count = count })
    end
    table.sort(list, function(a, b) return a.count > b.count end)

    -- Print top 40 (biar log ga overflow)
    local shown = 0
    for _, entry in ipairs(list) do
        if shown >= 40 then
            pushLog("... (truncated, max 40)", Color3.fromRGB(150, 150, 150))
            break
        end
        -- Highlight kalau kelihatan kayak item/collectible
        local nameLow = entry.name:lower()
        local isInteresting = nameLow:find("egg") or nameLow:find("coin")
            or nameLow:find("gem") or nameLow:find("crystal")
            or nameLow:find("supply") or nameLow:find("item")
            or nameLow:find("collect") or nameLow:find("token")
            or nameLow:find("pickup") or nameLow:find("drop")
            or nameLow:find("reward") or nameLow:find("star")
            or nameLow:find("loot") or nameLow:find("ore")
            or nameLow:find("wood") or nameLow:find("stone")
            or nameLow:find("resource") or nameLow:find("fruit")
            or nameLow:find("berry") or nameLow:find("fish")

        local color = isInteresting
            and Color3.fromRGB(100, 255, 150)   -- hijau = mungkin supply
            or  Color3.fromRGB(140, 140, 160)   -- abu = biasa

        pushLog(string.format("[%dx] %s", entry.count, entry.name), color)
        shown += 1
    end

    pushLog("── SCAN SELESAI ──", Color3.fromRGB(200, 150, 255))
    pushLog("Nama hijau = kandidat supply!", Color3.fromRGB(100, 255, 150))
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
        local supplyPos, supplyName = findNearestSupply()

        if supplyPos then
            pushLog(string.format('"%s" ditemukan (%.0f, %.0f, %.0f)',
                supplyName, supplyPos.X, supplyPos.Y, supplyPos.Z))
            pushLog(string.format('Menuju "%s"...', supplyName))
            local ok = moveToPosition(supplyPos)
            pushLog(ok and "Item diambil." or "Timeout ke item.",
                    ok and Color3.fromRGB(100, 220, 130) or Color3.fromRGB(255, 180, 60))
        else
            pushLog("Tidak ada supply — langsung ke Base.",
                    Color3.fromRGB(200, 180, 80))
        end

        -- ② Kembali ke Base
        if basePosition then
            pushLog("Kembali ke Base...")
            local ok = moveToPosition(basePosition)
            pushLog(ok and "Sampai Base — bongkar muatan." or "Timeout ke Base.",
                    ok and Color3.fromRGB(100, 220, 130) or Color3.fromRGB(255, 180, 60))
        else
            pushLog("Base belum diset!", Color3.fromRGB(255, 100, 100))
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

-- Scan Workspace
scanBtn.MouseButton1Click:Connect(function()
    task.spawn(scanWorkspace)
end)

-- Set Base
setBaseBtn.MouseButton1Click:Connect(function()
    basePosition = rootPart.Position
    local p = basePosition
    baseLabel.Text       = string.format("Base: (%.1f, %.1f, %.1f)", p.X, p.Y, p.Z)
    baseLabel.TextColor3 = Color3.fromRGB(100, 220, 130)
    setBaseBtn.BackgroundColor3 = Color3.fromRGB(20, 100, 60)
    setBaseBtn.Text      = "Base diset! (klik lagi untuk ubah)"
    pushLog(string.format("Base diset: (%.1f, %.1f, %.1f)", p.X, p.Y, p.Z),
            Color3.fromRGB(100, 220, 130))
end)

-- Start / Stop
startBtn.MouseButton1Click:Connect(function()
    if botRunning then
        botRunning = false
    else
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
pushLog("Siap. Klik 'Scan Workspace' dulu buat cari nama supply.")
pushLog("Nama hijau di hasil scan = kandidat supply.")
