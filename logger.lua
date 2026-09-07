-- ============================================================
--  BotMovement.lua  —  LocalScript / Script (server-side bot)
--  Modul pergerakan bot dengan dynamic supply finder
-- ============================================================

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

-- ────────────────────────────────────────────────────────────
--  KONFIGURASI
-- ────────────────────────────────────────────────────────────
local CFG = {
    -- Ganti ini sesuai nama bot/karakter kamu
    BotName         = "Bot",

    -- Posisi Base (tempat bongkar muatan) — sesuaikan
    BasePosition    = Vector3.new(0, 3, 0),

    -- Jarak dianggap "sudah sampai" ke target / base
    ArrivalDistance = 5,

    -- Nama supply yang dicari
    SupplyNames     = { "Egg" },
    SupplyTokenName = "EggToken",

    -- Delay antar siklus (detik)
    CycleDelay      = 0.5,

    -- Timeout MoveTo (detik) sebelum retry
    MoveTimeout     = 8,
}

-- ────────────────────────────────────────────────────────────
--  REFERENSI BOT
-- ────────────────────────────────────────────────────────────
-- Jika dijalankan sebagai LocalScript, ambil karakter player.
-- Jika Script biasa (NPC), ganti baris ini dengan referensi NPC-mu.
local character, humanoid, rootPart

local function initBot()
    -- Coba cari sebagai NPC di Workspace dulu
    local npc = workspace:FindFirstChild(CFG.BotName)
    if npc then
        character = npc
    else
        -- Fallback: pakai LocalPlayer
        local player = Players.LocalPlayer
        if player then
            character = player.Character or player.CharacterAdded:Wait()
        end
    end

    humanoid = character and character:FindFirstChildOfClass("Humanoid")
    rootPart = character and character:FindFirstChild("HumanoidRootPart")

    return humanoid ~= nil and rootPart ~= nil
end

-- ────────────────────────────────────────────────────────────
--  FUNGSI: findNearestSupply()
--  Memindai workspace → cari model/part bernama 'Egg'
--  atau yang punya anak 'EggToken', ukur jarak dari RootPart,
--  kembalikan Vector3 posisi terdekat (atau nil jika tidak ada)
-- ────────────────────────────────────────────────────────────
local function findNearestSupply()
    local nearest     = nil
    local nearestDist = math.huge
    local botPos      = rootPart.Position

    for _, obj in ipairs(workspace:GetDescendants()) do
        local isSupply = false
        local targetPos = nil

        -- Cek apakah nama object cocok dengan SupplyNames
        for _, supplyName in ipairs(CFG.SupplyNames) do
            if obj.Name == supplyName then
                isSupply = true
                break
            end
        end

        -- Cek apakah punya anak bernama EggToken
        if not isSupply and obj:FindFirstChild(CFG.SupplyTokenName) then
            isSupply = true
        end

        if isSupply then
            -- Tentukan posisi: Model pakai PrimaryPart atau FindFirstChild("HumanoidRootPart")
            -- Part langsung pakai .Position
            if obj:IsA("Model") then
                if obj.PrimaryPart then
                    targetPos = obj.PrimaryPart.Position
                else
                    -- Fallback: cari part pertama di dalam model
                    local anyPart = obj:FindFirstChildWhichIsA("BasePart")
                    if anyPart then
                        targetPos = anyPart.Position
                    end
                end
            elseif obj:IsA("BasePart") then
                targetPos = obj.Position
            end

            -- Hitung jarak dan bandingkan
            if targetPos then
                local dist = (botPos - targetPos).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearest     = targetPos
                end
            end
        end
    end

    return nearest  -- Vector3 atau nil
end

-- ────────────────────────────────────────────────────────────
--  HELPER: MoveTo dengan timeout
--  Roblox Humanoid:MoveTo berhenti setelah 8 detik otomatis,
--  tapi kita tambahkan kontrol manual supaya lebih responsif.
-- ────────────────────────────────────────────────────────────
local function moveToPosition(targetPos)
    humanoid:MoveTo(targetPos)

    local startTime = tick()
    local reached   = false

    -- Tunggu sampai sampai atau timeout
    local conn
    conn = RunService.Heartbeat:Connect(function()
        local dist = (rootPart.Position - targetPos).Magnitude
        if dist <= CFG.ArrivalDistance then
            reached = true
            conn:Disconnect()
        elseif tick() - startTime >= CFG.MoveTimeout then
            -- Timeout — anggap gagal, lanjut siklus berikutnya
            conn:Disconnect()
        end
    end)

    -- Blok sampai koneksi selesai
    while conn.Connected do
        task.wait()
    end

    return reached
end

-- ────────────────────────────────────────────────────────────
--  GUI LOGGER (kotak biru, bukan bulat — simple)
-- ────────────────────────────────────────────────────────────
local function buildGUI()
    local player = Players.LocalPlayer
    if not player then return nil end

    local gui = Instance.new("ScreenGui")
    gui.Name           = "BotMonitorGui"
    gui.ResetOnSpawn   = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent         = player:WaitForChild("PlayerGui")

    -- Tombol toggle — kotak biru solid, sudut persegi
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

    -- Panel log
    local panel = Instance.new("Frame")
    panel.Size             = UDim2.new(0, 340, 0, 260)
    panel.Position         = UDim2.new(0, 12, 1, -390)
    panel.BackgroundColor3 = Color3.fromRGB(12, 12, 22)
    panel.BorderSizePixel  = 0
    panel.Visible          = false
    panel.ZIndex           = 9
    panel.Parent           = gui

    -- Garis border tipis
    local stroke = Instance.new("UIStroke", panel)
    stroke.Color     = Color3.fromRGB(30, 100, 210)
    stroke.Thickness = 1

    -- Header panel
    local header = Instance.new("Frame")
    header.Size             = UDim2.new(1, 0, 0, 30)
    header.BackgroundColor3 = Color3.fromRGB(30, 100, 210)
    header.BorderSizePixel  = 0
    header.ZIndex           = 10
    header.Parent           = panel

    local headerLabel = Instance.new("TextLabel")
    headerLabel.Size               = UDim2.new(1, -40, 1, 0)
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
    scroll.Size                 = UDim2.new(1, -8, 1, -36)
    scroll.Position             = UDim2.new(0, 4, 0, 32)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel      = 0
    scroll.ScrollBarThickness   = 3
    scroll.ScrollBarImageColor3 = Color3.fromRGB(30, 100, 210)
    scroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
    scroll.CanvasSize           = UDim2.new(0, 0, 0, 0)
    scroll.ZIndex               = 10
    scroll.Parent               = panel

    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding   = UDim.new(0, 2)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local pad = Instance.new("UIPadding", scroll)
    pad.PaddingTop    = UDim.new(0, 4)
    pad.PaddingLeft   = UDim.new(0, 4)
    pad.PaddingRight  = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 4)

    -- Status bar bawah
    local statusBar = Instance.new("TextLabel")
    statusBar.Size               = UDim2.new(1, 0, 0, 22)
    statusBar.Position           = UDim2.new(0, 0, 1, -22)
    statusBar.BackgroundColor3   = Color3.fromRGB(20, 60, 140)
    statusBar.BorderSizePixel    = 0
    statusBar.Text               = "Status: Menunggu..."
    statusBar.TextColor3         = Color3.fromRGB(180, 210, 255)
    statusBar.TextSize           = 11
    statusBar.Font               = Enum.Font.Code
    statusBar.TextXAlignment     = Enum.TextXAlignment.Left
    statusBar.ZIndex             = 11
    statusBar.Parent             = panel

    local statusPad = Instance.new("UIPadding", statusBar)
    statusPad.PaddingLeft = UDim.new(0, 6)

    -- Logika toggle
    local isOpen  = false
    local logIdx  = 0

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

    -- Fungsi log yang dikembalikan ke luar
    local function pushLog(msg)
        logIdx += 1
        local lbl = Instance.new("TextLabel")
        lbl.Size               = UDim2.new(1, 0, 0, 0)
        lbl.AutomaticSize      = Enum.AutomaticSize.Y
        lbl.BackgroundTransparency = 1
        lbl.Text               = os.date("%H:%M:%S") .. "  " .. msg
        lbl.TextColor3         = Color3.fromRGB(160, 200, 255)
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

    local function setStatus(msg)
        statusBar.Text = "Status: " .. msg
    end

    return pushLog, setStatus
end

-- ────────────────────────────────────────────────────────────
--  MAIN LOOP
-- ────────────────────────────────────────────────────────────
local function main()
    if not initBot() then
        warn("[BotMovement] Tidak dapat menemukan bot/karakter.")
        return
    end

    local pushLog, setStatus = buildGUI()

    -- Fallback jika GUI tidak tersedia (script server)
    pushLog   = pushLog   or function(m) print("[BOT]", m) end
    setStatus = setStatus or function(m) print("[STATUS]", m) end

    pushLog("Bot siap. Base: " .. tostring(CFG.BasePosition))
    pushLog("Mencari supply: " .. table.concat(CFG.SupplyNames, ", ")
            .. " / token: " .. CFG.SupplyTokenName)

    local cycle = 0

    while task.wait(CFG.CycleDelay) do
        -- Pastikan bot masih hidup
        if humanoid.Health <= 0 then
            setStatus("Bot mati — menunggu respawn...")
            pushLog("Bot mati. Loop berhenti.")
            break
        end

        cycle += 1
        pushLog(string.format("── Siklus #%d ──", cycle))

        -- ① Cari supply terdekat
        setStatus("Memindai supply...")
        local supplyPos = findNearestSupply()

        if supplyPos then
            pushLog(string.format("Supply ditemukan: (%.1f, %.1f, %.1f)",
                supplyPos.X, supplyPos.Y, supplyPos.Z))

            -- ② Jalan ke supply
            setStatus("Menuju supply...")
            local reached = moveToPosition(supplyPos)

            if reached then
                pushLog("Sampai di supply — muatan diambil.")
                setStatus("Muatan diambil!")
                task.wait(0.3)  -- jeda singkat simulasi pickup
            else
                pushLog("Timeout menuju supply — lanjut ke Base.")
            end
        else
            pushLog("Tidak ada supply ditemukan — kembali ke Base.")
        end

        -- ③ Kembali ke Base
        setStatus("Kembali ke Base...")
        pushLog(string.format("Menuju Base: (%.1f, %.1f, %.1f)",
            CFG.BasePosition.X, CFG.BasePosition.Y, CFG.BasePosition.Z))

        local atBase = moveToPosition(CFG.BasePosition)

        if atBase then
            pushLog("Sampai di Base — muatan dibongkar.")
            setStatus("Bongkar muatan selesai.")
        else
            pushLog("Timeout menuju Base.")
            setStatus("Gagal ke Base — retry...")
        end

        task.wait(0.2)
    end
end

-- Jalankan
task.spawn(main)
