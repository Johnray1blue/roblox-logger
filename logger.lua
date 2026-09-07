-- ============================================================
--  BotMovement.lua  —  LocalScript → StarterPlayerScripts
-- ============================================================

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local CFG = {
    -- ── Isi setelah Scan Workspace ──────────────────────────
    -- Nama object binatang/creature di Workspace (exact atau partial)
    AnimalNames     = { "Chicken", "Animal", "Creature", "Beast" },  -- ganti ini
    AnimalPartial   = { "animal", "creature", "chicken", "cow", "pig", "beast", "monster" },

    -- Nama egg/supply yang mau diambil
    EggNames        = { "Egg" },
    EggPartial      = { "egg" },

    -- Radius pencarian egg di sekitar binatang (stud)
    TerritoryRadius = 30,

    -- Mulai ambil dari territory ke-N (1 = terdekat dari base)
    -- User bisa ubah ini dari GUI
    StartFromTerritory = 1,

    -- Parent yang DILARANG — egg milik player lain
    -- Script akan skip egg yang ada di dalam karakter/base player lain
    BlockedParentNames = { "Base", "PlayerBase", "House", "Home" }, -- ganti kalau perlu

    ArrivalDistance = 5,
    MoveTimeout     = 8,
    CycleDelay      = 0.5,
}

-- ────────────────────────────────────────────────────────────
--  REFERENSI
-- ────────────────────────────────────────────────────────────
local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid")
local rootPart  = character:WaitForChild("HumanoidRootPart")

local basePosition = nil
local botRunning   = false

-- ────────────────────────────────────────────────────────────
--  HELPER: cek apakah object adalah milik player lain
-- ────────────────────────────────────────────────────────────
local function isOwnedByOtherPlayer(obj)
    -- Cek apakah obj ada di dalam karakter player lain
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            if obj:IsDescendantOf(p.Character) then
                return true
            end
        end
    end

    -- Cek parent chain — kalau ada nama yang masuk daftar "base player"
    local current = obj.Parent
    local depth = 0
    while current and current ~= workspace and depth < 8 do
        for _, blockedName in ipairs(CFG.BlockedParentNames) do
            if current.Name:lower():find(blockedName:lower(), 1, true) then
                return true
            end
        end
        -- Cek juga apakah parentnya adalah folder milik player lain
        -- (format umum: "PlayerName_Base" atau folder bernama username player)
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and current.Name == p.Name then
                return true
            end
        end
        current = current.Parent
        depth += 1
    end

    return false
end

-- ────────────────────────────────────────────────────────────
--  HELPER: getPosition
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
--  HELPER: cek apakah object adalah binatang/territory
-- ────────────────────────────────────────────────────────────
local function isAnimal(obj)
    local name = obj.Name
    for _, n in ipairs(CFG.AnimalNames) do
        if name == n then return true end
    end
    local nameLower = name:lower()
    for _, p in ipairs(CFG.AnimalPartial) do
        if nameLower:find(p, 1, true) then return true end
    end
    return false
end

-- ────────────────────────────────────────────────────────────
--  HELPER: cek apakah object adalah egg
-- ────────────────────────────────────────────────────────────
local function isEgg(obj)
    local name = obj.Name
    for _, n in ipairs(CFG.EggNames) do
        if name == n then return true end
    end
    local nameLower = name:lower()
    for _, p in ipairs(CFG.EggPartial) do
        if nameLower:find(p, 1, true) then return true end
    end
    return false
end

-- ────────────────────────────────────────────────────────────
--  CORE: Deteksi semua territory (binatang), sort by distance dari base
-- ────────────────────────────────────────────────────────────
local function detectTerritories(fromPos)
    local territories = {}

    for _, obj in ipairs(workspace:GetDescendants()) do
        if isAnimal(obj) then
            local pos = getPosition(obj)
            if pos then
                -- Skip kalau milik player lain
                if not isOwnedByOtherPlayer(obj) then
                    local dist = (fromPos - pos).Magnitude
                    table.insert(territories, {
                        name     = obj.Name,
                        position = pos,
                        distance = dist,
                        object   = obj,
                    })
                end
            end
        end
    end

    -- Sort: terdekat dari base = territory #1
    table.sort(territories, function(a, b)
        return a.distance < b.distance
    end)

    return territories
end

-- ────────────────────────────────────────────────────────────
--  CORE: Cari egg di sekitar territory tertentu (dalam radius)
-- ────────────────────────────────────────────────────────────
local function findEggsInTerritory(centerPos)
    local eggs = {}

    for _, obj in ipairs(workspace:GetDescendants()) do
        if isEgg(obj) then
            local pos = getPosition(obj)
            if pos then
                local dist = (centerPos - pos).Magnitude
                if dist <= CFG.TerritoryRadius then
                    -- Pastikan bukan milik player lain
                    if not isOwnedByOtherPlayer(obj) then
                        table.insert(eggs, { position = pos, name = obj.Name, dist = dist })
                    end
                end
            end
        end
    end

    -- Sort: terdekat dari center territory dulu
    table.sort(eggs, function(a, b) return a.dist < b.dist end)

    return eggs
end

-- ────────────────────────────────────────────────────────────
--  moveToPosition()
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
    return (rootPart.Position - targetPos).Magnitude <= CFG.ArrivalDistance
end

-- ════════════════════════════════════════════════════════════
--  GUI
-- ════════════════════════════════════════════════════════════
local gui = Instance.new("ScreenGui")
gui.Name           = "BotGui"
gui.ResetOnSpawn   = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent         = player:WaitForChild("PlayerGui")

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

local panel = Instance.new("Frame")
panel.Size             = UDim2.new(0, 360, 0, 440)
panel.Position         = UDim2.new(0, 12, 1, -580)
panel.BackgroundColor3 = Color3.fromRGB(12, 12, 22)
panel.BorderSizePixel  = 0
panel.Visible          = false
panel.ZIndex           = 9
panel.Parent           = gui
Instance.new("UIStroke", panel).Color = Color3.fromRGB(30, 100, 210)

local header = Instance.new("Frame")
header.Size             = UDim2.new(1, 0, 0, 30)
header.BackgroundColor3 = Color3.fromRGB(30, 100, 210)
header.BorderSizePixel  = 0
header.ZIndex           = 10
header.Parent           = panel

local headerLabel = Instance.new("TextLabel")
headerLabel.Size           = UDim2.new(1, -36, 1, 0)
headerLabel.Position       = UDim2.new(0, 8, 0, 0)
headerLabel.BackgroundTransparency = 1
headerLabel.Text           = "BOT MOVEMENT LOG"
headerLabel.TextColor3     = Color3.new(1, 1, 1)
headerLabel.TextSize       = 12
headerLabel.Font           = Enum.Font.GothamBold
headerLabel.TextXAlignment = Enum.TextXAlignment.Left
headerLabel.ZIndex         = 11
headerLabel.Parent         = header

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

local scroll = Instance.new("ScrollingFrame")
scroll.Size                 = UDim2.new(1, -8, 1, -210)
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

-- ── Bottom Panel ─────────────────────────────────────────────
local bottomPanel = Instance.new("Frame")
bottomPanel.Size             = UDim2.new(1, 0, 0, 208)
bottomPanel.Position         = UDim2.new(0, 0, 1, -208)
bottomPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 34)
bottomPanel.BorderSizePixel  = 0
bottomPanel.ZIndex           = 10
bottomPanel.Parent           = panel
local bStroke = Instance.new("UIStroke", bottomPanel)
bStroke.Color = Color3.fromRGB(30, 100, 210)
bStroke.Thickness = 1
bStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local bPad = Instance.new("UIPadding", bottomPanel)
bPad.PaddingTop    = UDim.new(0, 8)
bPad.PaddingBottom = UDim.new(0, 8)
bPad.PaddingLeft   = UDim.new(0, 10)
bPad.PaddingRight  = UDim.new(0, 10)

local bLayout = Instance.new("UIListLayout", bottomPanel)
bLayout.FillDirection = Enum.FillDirection.Vertical
bLayout.Padding       = UDim.new(0, 6)
bLayout.SortOrder     = Enum.SortOrder.LayoutOrder

-- Status labels
local baseLabel = Instance.new("TextLabel")
baseLabel.LayoutOrder = 1
baseLabel.Size        = UDim2.new(1, 0, 0, 16)
baseLabel.BackgroundTransparency = 1
baseLabel.Text        = "Base: belum diset"
baseLabel.TextColor3  = Color3.fromRGB(120, 160, 255)
baseLabel.TextSize    = 11
baseLabel.Font        = Enum.Font.Code
baseLabel.TextXAlignment = Enum.TextXAlignment.Left
baseLabel.ZIndex      = 11
baseLabel.Parent      = bottomPanel

local territoryLabel = Instance.new("TextLabel")
territoryLabel.LayoutOrder = 2
territoryLabel.Size        = UDim2.new(1, 0, 0, 16)
territoryLabel.BackgroundTransparency = 1
territoryLabel.Text        = "Mulai dari territory: #1 (terdekat)"
territoryLabel.TextColor3  = Color3.fromRGB(200, 160, 255)
territoryLabel.TextSize    = 11
territoryLabel.Font        = Enum.Font.Code
territoryLabel.TextXAlignment = Enum.TextXAlignment.Left
territoryLabel.ZIndex      = 11
territoryLabel.Parent      = bottomPanel

-- Territory selector (- / N / +)
local selectorFrame = Instance.new("Frame")
selectorFrame.LayoutOrder = 3
selectorFrame.Size        = UDim2.new(1, 0, 0, 28)
selectorFrame.BackgroundTransparency = 1
selectorFrame.ZIndex      = 11
selectorFrame.Parent      = bottomPanel

local minusBtn = Instance.new("TextButton")
minusBtn.Size             = UDim2.new(0, 28, 1, 0)
minusBtn.Position         = UDim2.new(0, 0, 0, 0)
minusBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
minusBtn.BorderSizePixel  = 0
minusBtn.Text             = "−"
minusBtn.TextColor3       = Color3.new(1, 1, 1)
minusBtn.TextSize         = 16
minusBtn.Font             = Enum.Font.GothamBold
minusBtn.ZIndex           = 12
minusBtn.Parent           = selectorFrame

local territoryNumLabel = Instance.new("TextLabel")
territoryNumLabel.Size    = UDim2.new(1, -60, 1, 0)
territoryNumLabel.Position = UDim2.new(0, 32, 0, 0)
territoryNumLabel.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
territoryNumLabel.BorderSizePixel  = 0
territoryNumLabel.Text    = "Territory #1"
territoryNumLabel.TextColor3 = Color3.fromRGB(200, 160, 255)
territoryNumLabel.TextSize   = 12
territoryNumLabel.Font       = Enum.Font.GothamBold
territoryNumLabel.ZIndex     = 12
territoryNumLabel.Parent     = selectorFrame

local plusBtn = Instance.new("TextButton")
plusBtn.Size             = UDim2.new(0, 28, 1, 0)
plusBtn.Position         = UDim2.new(1, -28, 0, 0)
plusBtn.BackgroundColor3 = Color3.fromRGB(20, 80, 30)
plusBtn.BorderSizePixel  = 0
plusBtn.Text             = "+"
plusBtn.TextColor3       = Color3.new(1, 1, 1)
plusBtn.TextSize         = 16
plusBtn.Font             = Enum.Font.GothamBold
plusBtn.ZIndex           = 12
plusBtn.Parent           = selectorFrame

-- Scan + Set Base + Start
local scanBtn = Instance.new("TextButton")
scanBtn.LayoutOrder       = 4
scanBtn.Size              = UDim2.new(1, 0, 0, 24)
scanBtn.BackgroundColor3  = Color3.fromRGB(80, 40, 120)
scanBtn.BorderSizePixel   = 0
scanBtn.Text              = "🔍 Scan (lihat territory & egg)"
scanBtn.TextColor3        = Color3.new(1, 1, 1)
scanBtn.TextSize          = 11
scanBtn.Font              = Enum.Font.GothamBold
scanBtn.ZIndex            = 11
scanBtn.Parent            = bottomPanel

local setBaseBtn = Instance.new("TextButton")
setBaseBtn.LayoutOrder    = 5
setBaseBtn.Size           = UDim2.new(1, 0, 0, 24)
setBaseBtn.BackgroundColor3 = Color3.fromRGB(30, 80, 160)
setBaseBtn.BorderSizePixel  = 0
setBaseBtn.Text           = "Set Base (posisi sekarang)"
setBaseBtn.TextColor3     = Color3.new(1, 1, 1)
setBaseBtn.TextSize       = 12
setBaseBtn.Font           = Enum.Font.GothamBold
setBaseBtn.ZIndex         = 11
setBaseBtn.Parent         = bottomPanel

local startBtn = Instance.new("TextButton")
startBtn.LayoutOrder      = 6
startBtn.Size             = UDim2.new(1, 0, 0, 24)
startBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 210)
startBtn.BorderSizePixel  = 0
startBtn.Text             = "Start Auto Collect"
startBtn.TextColor3       = Color3.new(1, 1, 1)
startBtn.TextSize         = 12
startBtn.Font             = Enum.Font.GothamBold
startBtn.ZIndex           = 11
startBtn.Parent           = bottomPanel

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
--  TERRITORY SELECTOR LOGIC
-- ════════════════════════════════════════════════════════════
local function updateTerritoryLabel()
    local n = CFG.StartFromTerritory
    territoryNumLabel.Text = string.format("Territory #%d", n)
    territoryLabel.Text    = string.format("Mulai dari territory: #%d", n)
end

minusBtn.MouseButton1Click:Connect(function()
    if CFG.StartFromTerritory > 1 then
        CFG.StartFromTerritory -= 1
        updateTerritoryLabel()
    end
end)

plusBtn.MouseButton1Click:Connect(function()
    CFG.StartFromTerritory += 1
    updateTerritoryLabel()
end)

-- ════════════════════════════════════════════════════════════
--  SCAN — preview territory & egg yang akan diambil
-- ════════════════════════════════════════════════════════════
local function doScan()
    if not basePosition then
        pushLog("Set Base dulu sebelum scan!", Color3.fromRGB(255, 100, 100))
        return
    end

    pushLog("── SCAN TERRITORY ──", Color3.fromRGB(200, 150, 255))
    local territories = detectTerritories(basePosition)

    if #territories == 0 then
        pushLog("Tidak ada territory/binatang ditemukan.", Color3.fromRGB(255, 180, 60))
        pushLog("Cek CFG.AnimalNames & AnimalPartial!", Color3.fromRGB(255, 180, 60))
        return
    end

    for i, t in ipairs(territories) do
        local skipped = i < CFG.StartFromTerritory
        local marker  = skipped and "[SKIP]" or "[AKTIF]"
        local color   = skipped
            and Color3.fromRGB(120, 120, 120)
            or  Color3.fromRGB(100, 220, 130)

        -- Cari egg di territory ini
        local eggs = findEggsInTerritory(t.position)
        pushLog(string.format("%s T#%d — %s (%.0f stud dari base) — %d egg",
            marker, i, t.name, t.distance, #eggs), color)

        -- Detail egg kalau aktif
        if not skipped then
            for j, e in ipairs(eggs) do
                pushLog(string.format("   Egg #%d: %s (%.0f stud dari binatang)",
                    j, e.name, e.dist),
                    Color3.fromRGB(255, 220, 100))
            end
        end
    end

    pushLog("── SCAN SELESAI ──", Color3.fromRGB(200, 150, 255))
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
        pushLog(string.format("══ Siklus #%d ══", cycle), Color3.fromRGB(100, 160, 255))

        -- Deteksi territory setiap siklus (bisa berubah)
        local territories = detectTerritories(basePosition)

        if #territories == 0 then
            pushLog("Tidak ada territory ditemukan!", Color3.fromRGB(255, 100, 100))
            task.wait(2)
        else
            local startN = CFG.StartFromTerritory
            pushLog(string.format("Deteksi %d territory, mulai dari #%d",
                #territories, startN), Color3.fromRGB(150, 150, 200))

            -- Loop territory dari startN ke akhir
            for i = startN, #territories do
                if not botRunning then break end

                local t = territories[i]
                pushLog(string.format("→ Territory #%d: %s", i, t.name),
                        Color3.fromRGB(180, 140, 255))

                local eggs = findEggsInTerritory(t.position)

                if #eggs == 0 then
                    pushLog(string.format("  Tidak ada egg di T#%d, skip.", i),
                            Color3.fromRGB(200, 180, 80))
                else
                    -- Ambil semua egg di territory ini
                    for j, egg in ipairs(eggs) do
                        if not botRunning then break end
                        pushLog(string.format("  Egg #%d/%d: menuju (%.0f,%.0f,%.0f)",
                            j, #eggs, egg.position.X, egg.position.Y, egg.position.Z))
                        local ok = moveToPosition(egg.position)
                        pushLog(ok and "  ✓ Egg diambil." or "  ✗ Timeout.",
                            ok and Color3.fromRGB(100, 220, 130) or Color3.fromRGB(255, 180, 60))
                    end
                end
            end

            -- Kembali ke base
            if botRunning and basePosition then
                pushLog("Kembali ke Base...", Color3.fromRGB(160, 160, 255))
                local ok = moveToPosition(basePosition)
                pushLog(ok and "✓ Sampai Base — bongkar muatan." or "✗ Timeout ke Base.",
                    ok and Color3.fromRGB(100, 220, 130) or Color3.fromRGB(255, 180, 60))
            end
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

scanBtn.MouseButton1Click:Connect(function()
    task.spawn(doScan)
end)

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
        pushLog(string.format("Bot dimulai! (mulai dari territory #%d)",
            CFG.StartFromTerritory), Color3.fromRGB(100, 220, 130))
        task.spawn(runBot)
    end
end)

-- Log awal
pushLog("Siap. Set Base → Scan → pilih territory → Start.")
pushLog("Territory #1 = terdekat dari Base.")
