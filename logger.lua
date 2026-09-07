-- ============================================================
--  PerformanceMonitorGUI.lua
--  LocalScript — letakkan di StarterPlayerScripts
-- ============================================================

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ────────────────────────────────────────────────────────────
--  KONFIGURASI
-- ────────────────────────────────────────────────────────────
local CFG = {
    Title           = "⚡ PerfMonitor v1.0",
    MaxLogLines     = 200,          -- batas buffer log
    LogInterval     = 0.5,          -- detik antara setiap snapshot
    WindowW         = 420,
    WindowH         = 540,
    HeaderH         = 36,
    ToggleBtnH      = 40,
    UtilBarH        = 34,
    Padding         = 10,
    ScrollLineH     = 16,
    Font            = Enum.Font.Code,
    FontBody        = Enum.Font.Gotham,
    -- Palette: dark terminal aesthetic
    BgDark          = Color3.fromHex("#0D1117"),
    BgPanel         = Color3.fromHex("#161B22"),
    BgHeader        = Color3.fromHex("#010409"),
    AccentOn        = Color3.fromHex("#3FB950"),   -- hijau aktif
    AccentOff       = Color3.fromHex("#F85149"),   -- merah nonaktif
    AccentCopy      = Color3.fromHex("#58A6FF"),   -- biru copy
    AccentClear     = Color3.fromHex("#E3B341"),   -- kuning clear
    TextPrimary     = Color3.fromHex("#E6EDF3"),
    TextMuted       = Color3.fromHex("#8B949E"),
    TextLog         = Color3.fromHex("#A5D6FF"),
    BorderColor     = Color3.fromHex("#30363D"),
}

-- ────────────────────────────────────────────────────────────
--  STATE
-- ────────────────────────────────────────────────────────────
local loopActive    = false
local loopConn      = nil           -- RenderStepped / Heartbeat connection
local logBuffer     = {}            -- akumulasi string log
local logLabels     = {}            -- TextLabel di dalam ScrollingFrame
local accTime       = 0
local frameCount    = 0
local isDragging    = false
local dragOffset    = Vector2.zero

-- ────────────────────────────────────────────────────────────
--  HELPER: buat instance berparameter
-- ────────────────────────────────────────────────────────────
local function make(cls, props, parent)
    local obj = Instance.new(cls)
    for k, v in pairs(props) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local function makeCorner(radius, parent)
    return make("UICorner", {CornerRadius = UDim.new(0, radius)}, parent)
end

local function makeStroke(thickness, color, parent)
    return make("UIStroke", {
        Thickness = thickness,
        Color     = color,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

-- ────────────────────────────────────────────────────────────
--  BANGUN ScreenGui
-- ────────────────────────────────────────────────────────────
local ScreenGui = make("ScreenGui", {
    Name             = "PerfMonitorGui",
    ResetOnSpawn     = false,
    ZIndexBehavior   = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset   = true,
}, PlayerGui)

-- Window utama
local Window = make("Frame", {
    Name            = "Window",
    Size            = UDim2.new(0, CFG.WindowW, 0, CFG.WindowH),
    Position        = UDim2.new(0.5, -CFG.WindowW/2, 0.5, -CFG.WindowH/2),
    BackgroundColor3 = CFG.BgDark,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, ScreenGui)
makeCorner(8, Window)
makeStroke(1, CFG.BorderColor, Window)

-- Drop shadow (dekoratif, di bawah window)
local Shadow = make("Frame", {
    Name            = "Shadow",
    Size            = UDim2.new(1, 16, 1, 16),
    Position        = UDim2.new(0, -8, 0, 6),
    BackgroundColor3 = Color3.new(0,0,0),
    BackgroundTransparency = 0.55,
    BorderSizePixel = 0,
    ZIndex          = Window.ZIndex - 1,
}, Window)
makeCorner(12, Shadow)

-- ── Header ──────────────────────────────────────────────────
local Header = make("Frame", {
    Name            = "Header",
    Size            = UDim2.new(1, 0, 0, CFG.HeaderH),
    BackgroundColor3 = CFG.BgHeader,
    BorderSizePixel = 0,
}, Window)
makeCorner(8, Header)

-- Patch sudut bawah header (agar tidak rounded di bawah)
make("Frame", {
    Size            = UDim2.new(1, 0, 0.5, 0),
    Position        = UDim2.new(0, 0, 0.5, 0),
    BackgroundColor3 = CFG.BgHeader,
    BorderSizePixel = 0,
}, Header)

make("TextLabel", {
    Text            = CFG.Title,
    Size            = UDim2.new(1, -60, 1, 0),
    Position        = UDim2.new(0, CFG.Padding, 0, 0),
    BackgroundTransparency = 1,
    Font            = CFG.FontBody,
    TextSize        = 14,
    TextColor3      = CFG.TextPrimary,
    TextXAlignment  = Enum.TextXAlignment.Left,
    TextYAlignment  = Enum.TextYAlignment.Center,
    ZIndex          = 5,
}, Header)

-- Indikator status (dot)
local StatusDot = make("Frame", {
    Name            = "StatusDot",
    Size            = UDim2.new(0, 10, 0, 10),
    Position        = UDim2.new(1, -CFG.Padding - 10, 0.5, -5),
    BackgroundColor3 = CFG.AccentOff,
    BorderSizePixel = 0,
    ZIndex          = 5,
}, Header)
makeCorner(50, StatusDot)

-- Drag handle pada header
Header.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        isDragging  = true
        dragOffset  = inp.Position - Vector2.new(Window.AbsolutePosition.X, Window.AbsolutePosition.Y)
    end
end)
Header.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if isDragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
    or inp.UserInputType == Enum.UserInputType.Touch) then
        local pos = inp.Position
        Window.Position = UDim2.new(0, pos.X - dragOffset.X, 0, pos.Y - dragOffset.Y)
    end
end)

-- ── Body container ───────────────────────────────────────────
local Body = make("Frame", {
    Name            = "Body",
    Size            = UDim2.new(1, 0, 1, -CFG.HeaderH),
    Position        = UDim2.new(0, 0, 0, CFG.HeaderH),
    BackgroundColor3 = CFG.BgPanel,
    BorderSizePixel = 0,
}, Window)

local BodyLayout = make("UIListLayout", {
    SortOrder       = Enum.SortOrder.LayoutOrder,
    Padding         = UDim.new(0, CFG.Padding),
    FillDirection   = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
}, Body)

make("UIPadding", {
    PaddingTop    = UDim.new(0, CFG.Padding),
    PaddingBottom = UDim.new(0, CFG.Padding),
    PaddingLeft   = UDim.new(0, CFG.Padding),
    PaddingRight  = UDim.new(0, CFG.Padding),
}, Body)

-- ── Toggle Button ────────────────────────────────────────────
local ToggleBtn = make("TextButton", {
    Name            = "ToggleBtn",
    LayoutOrder     = 1,
    Size            = UDim2.new(1, 0, 0, CFG.ToggleBtnH),
    BackgroundColor3 = CFG.AccentOff,
    Font            = CFG.FontBody,
    TextSize        = 14,
    TextColor3      = Color3.new(1,1,1),
    Text            = "▶  MULAI MONITORING",
    BorderSizePixel = 0,
    AutoButtonColor = false,
}, Body)
makeCorner(6, ToggleBtn)

-- ── Stats bar ────────────────────────────────────────────────
local StatsBar = make("Frame", {
    Name            = "StatsBar",
    LayoutOrder     = 2,
    Size            = UDim2.new(1, 0, 0, 28),
    BackgroundColor3 = CFG.BgDark,
    BorderSizePixel = 0,
}, Body)
makeCorner(4, StatsBar)
makeStroke(1, CFG.BorderColor, StatsBar)

local StatsLayout = make("UIListLayout", {
    FillDirection   = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Left,
    VerticalAlignment   = Enum.VerticalAlignment.Center,
    Padding         = UDim.new(0, 0),
}, StatsBar)

local function makeStatLabel(labelText, valueDefault, order)
    local cell = make("Frame", {
        LayoutOrder     = order,
        Size            = UDim2.new(0.33, 0, 1, 0),
        BackgroundTransparency = 1,
    }, StatsBar)
    make("TextLabel", {
        Text            = labelText,
        Size            = UDim2.new(0.5, 0, 1, 0),
        BackgroundTransparency = 1,
        Font            = CFG.FontBody,
        TextSize        = 11,
        TextColor3      = CFG.TextMuted,
        TextXAlignment  = Enum.TextXAlignment.Right,
    }, cell)
    local val = make("TextLabel", {
        Text            = valueDefault,
        Position        = UDim2.new(0.5, 4, 0, 0),
        Size            = UDim2.new(0.5, -4, 1, 0),
        BackgroundTransparency = 1,
        Font            = CFG.Font,
        TextSize        = 12,
        TextColor3      = CFG.AccentOn,
        TextXAlignment  = Enum.TextXAlignment.Left,
    }, cell)
    return val
end

local ValFPS  = makeStatLabel("FPS ", "—", 1)
local ValPing = makeStatLabel("Ping ", "—", 2)
local ValMem  = makeStatLabel("Mem ", "—", 3)

-- ── Log header row ───────────────────────────────────────────
local LogHeader = make("Frame", {
    Name        = "LogHeader",
    LayoutOrder = 3,
    Size        = UDim2.new(1, 0, 0, 22),
    BackgroundTransparency = 1,
}, Body)

make("TextLabel", {
    Text        = "LOG OUTPUT",
    Size        = UDim2.new(0.5, 0, 1, 0),
    BackgroundTransparency = 1,
    Font        = CFG.FontBody,
    TextSize    = 11,
    TextColor3  = CFG.TextMuted,
    TextXAlignment = Enum.TextXAlignment.Left,
}, LogHeader)

local LogCountLabel = make("TextLabel", {
    Text        = "0 baris",
    Size        = UDim2.new(0.5, 0, 1, 0),
    Position    = UDim2.new(0.5, 0, 0, 0),
    BackgroundTransparency = 1,
    Font        = CFG.Font,
    TextSize    = 11,
    TextColor3  = CFG.TextMuted,
    TextXAlignment = Enum.TextXAlignment.Right,
}, LogHeader)

-- ── ScrollingFrame (log panel) ───────────────────────────────
local LogScrollH = CFG.WindowH - CFG.HeaderH - CFG.ToggleBtnH - 28 - 22 - CFG.UtilBarH
                   - CFG.Padding * 6  -- account for padding/spacing

local LogScroll = make("ScrollingFrame", {
    Name                    = "LogScroll",
    LayoutOrder             = 4,
    Size                    = UDim2.new(1, 0, 1, -(CFG.ToggleBtnH + 28 + 22 + CFG.UtilBarH + CFG.Padding * 4 + 20)),
    BackgroundColor3        = CFG.BgDark,
    BorderSizePixel         = 0,
    CanvasSize              = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness      = 4,
    ScrollBarImageColor3    = CFG.BorderColor,
    AutomaticCanvasSize     = Enum.AutomaticSize.Y,
    ScrollingDirection      = Enum.ScrollingDirection.Y,
    ClipsDescendants        = true,
}, Body)
makeCorner(4, LogScroll)
makeStroke(1, CFG.BorderColor, LogScroll)

make("UIPadding", {
    PaddingLeft   = UDim.new(0, 6),
    PaddingRight  = UDim.new(0, 6),
    PaddingTop    = UDim.new(0, 4),
    PaddingBottom = UDim.new(0, 4),
}, LogScroll)

local LogLayout = make("UIListLayout", {
    SortOrder   = Enum.SortOrder.LayoutOrder,
    Padding     = UDim.new(0, 1),
}, LogScroll)

-- ── Utility bar ──────────────────────────────────────────────
local UtilBar = make("Frame", {
    Name        = "UtilBar",
    LayoutOrder = 5,
    Size        = UDim2.new(1, 0, 0, CFG.UtilBarH),
    BackgroundTransparency = 1,
}, Body)

local UtilLayout = make("UIListLayout", {
    FillDirection   = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment   = Enum.VerticalAlignment.Center,
    Padding         = UDim.new(0, 8),
}, UtilBar)

local function makeUtilBtn(label, color, order)
    local btn = make("TextButton", {
        LayoutOrder     = order,
        Size            = UDim2.new(0.47, 0, 1, 0),
        BackgroundColor3 = color,
        Font            = CFG.FontBody,
        TextSize        = 12,
        TextColor3      = Color3.new(1,1,1),
        Text            = label,
        BorderSizePixel = 0,
        AutoButtonColor = false,
    }, UtilBar)
    makeCorner(5, btn)
    return btn
end

local CopyBtn  = makeUtilBtn("📋  Salin Log", CFG.AccentCopy, 1)
local ClearBtn = makeUtilBtn("🗑  Hapus Log", CFG.AccentClear, 2)

-- ────────────────────────────────────────────────────────────
--  LOGIKA LOG
-- ────────────────────────────────────────────────────────────
local function timestamp()
    -- Format [MM:SS.ms]
    local t   = tick()
    local sec = math.floor(t) % 3600
    local ms  = math.floor((t % 1) * 100)
    return string.format("[%02d:%02d.%02d]", math.floor(sec/60), sec%60, ms)
end

local function pushLog(msg)
    if #logBuffer >= CFG.MaxLogLines then
        -- buang baris paling lama
        table.remove(logBuffer, 1)
        local firstLabel = logLabels[1]
        if firstLabel then
            firstLabel:Destroy()
            table.remove(logLabels, 1)
        end
        -- update LayoutOrder supaya tetap urut
        for i, lbl in ipairs(logLabels) do
            lbl.LayoutOrder = i
        end
    end

    local line = timestamp() .. "  " .. msg
    table.insert(logBuffer, line)

    local lbl = make("TextLabel", {
        LayoutOrder         = #logBuffer,
        Size                = UDim2.new(1, 0, 0, CFG.ScrollLineH),
        BackgroundTransparency = 1,
        Font                = CFG.Font,
        TextSize            = 12,
        TextColor3          = CFG.TextLog,
        Text                = line,
        TextXAlignment      = Enum.TextXAlignment.Left,
        TextYAlignment      = Enum.TextYAlignment.Center,
        TextTruncate        = Enum.TextTruncate.AtEnd,
        RichText            = false,
    }, LogScroll)
    table.insert(logLabels, lbl)

    LogCountLabel.Text = #logBuffer .. " baris"

    -- auto-scroll ke bawah
    task.defer(function()
        LogScroll.CanvasPosition = Vector2.new(0, math.huge)
    end)
end

-- ────────────────────────────────────────────────────────────
--  LOOP MONITORING
-- ────────────────────────────────────────────────────────────
local lastFPS   = 0
local function startLoop()
    accTime    = 0
    frameCount = 0
    loopConn   = RunService.Heartbeat:Connect(function(dt)
        accTime    = accTime + dt
        frameCount = frameCount + 1

        if accTime >= CFG.LogInterval then
            local fps   = math.round(frameCount / accTime)
            local ping  = LocalPlayer:GetNetworkPing and math.round(LocalPlayer:GetNetworkPing() * 1000) or 0
            local mem   = math.round(game:GetService("Stats"):GetTotalMemoryUsageMb())

            ValFPS.Text  = fps  .. " fps"
            ValPing.Text = ping .. " ms"
            ValMem.Text  = mem  .. " MB"

            -- Warna FPS sebagai indikator health
            if fps >= 55 then
                ValFPS.TextColor3 = CFG.AccentOn
            elseif fps >= 30 then
                ValFPS.TextColor3 = CFG.AccentClear
            else
                ValFPS.TextColor3 = CFG.AccentOff
            end

            pushLog(string.format("FPS: %3d | Ping: %4d ms | Mem: %5d MB", fps, ping, mem))

            accTime    = 0
            frameCount = 0
        end
    end)
end

local function stopLoop()
    if loopConn then
        loopConn:Disconnect()
        loopConn = nil
    end
    pushLog("── Monitoring dihentikan ──")
    ValFPS.Text  = "—"
    ValPing.Text = "—"
    ValMem.Text  = "—"
    ValFPS.TextColor3 = CFG.AccentOn
end

-- ────────────────────────────────────────────────────────────
--  EFEK TOMBOL (hover / press)
-- ────────────────────────────────────────────────────────────
local function btnEffect(btn, baseColor)
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = baseColor:Lerp(Color3.new(1,1,1), 0.12)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = baseColor
    end)
    btn.MouseButton1Down:Connect(function()
        btn.BackgroundColor3 = baseColor:Lerp(Color3.new(0,0,0), 0.2)
    end)
    btn.MouseButton1Up:Connect(function()
        btn.BackgroundColor3 = baseColor
    end)
end

-- ────────────────────────────────────────────────────────────
--  KONEKSI TOMBOL
-- ────────────────────────────────────────────────────────────
ToggleBtn.MouseButton1Click:Connect(function()
    loopActive = not loopActive
    if loopActive then
        ToggleBtn.Text              = "⏹  HENTIKAN MONITORING"
        ToggleBtn.BackgroundColor3  = CFG.AccentOn
        StatusDot.BackgroundColor3  = CFG.AccentOn
        pushLog("── Monitoring dimulai ──")
        startLoop()
    else
        ToggleBtn.Text              = "▶  MULAI MONITORING"
        ToggleBtn.BackgroundColor3  = CFG.AccentOff
        StatusDot.BackgroundColor3  = CFG.AccentOff
        stopLoop()
    end
end)

CopyBtn.MouseButton1Click:Connect(function()
    if #logBuffer == 0 then
        pushLog("[SISTEM] Buffer kosong, tidak ada yang disalin.")
        return
    end
    local fullLog = table.concat(logBuffer, "\n")
    if setclipboard then
        setclipboard(fullLog)
        pushLog(string.format("[SISTEM] %d baris disalin ke clipboard.", #logBuffer))
    else
        -- Fallback: warn jika setclipboard tidak tersedia
        pushLog("[SISTEM] setclipboard() tidak tersedia di lingkungan ini.")
    end
end)

ClearBtn.MouseButton1Click:Connect(function()
    -- Hapus semua label
    for _, lbl in ipairs(logLabels) do lbl:Destroy() end
    logLabels  = {}
    logBuffer  = {}
    LogCountLabel.Text = "0 baris"
    pushLog("[SISTEM] Log dibersihkan.")
end)

-- Efek visual tombol utilitas
btnEffect(CopyBtn,  CFG.AccentCopy)
btnEffect(ClearBtn, CFG.AccentClear)

-- Toggle button tidak pakai btnEffect generik karena warnanya berubah-ubah
ToggleBtn.MouseEnter:Connect(function()
    local base = loopActive and CFG.AccentOn or CFG.AccentOff
    ToggleBtn.BackgroundColor3 = base:Lerp(Color3.new(1,1,1), 0.12)
end)
ToggleBtn.MouseLeave:Connect(function()
    ToggleBtn.BackgroundColor3 = loopActive and CFG.AccentOn or CFG.AccentOff
end)

-- ────────────────────────────────────────────────────────────
--  LOG AWAL
-- ────────────────────────────────────────────────────────────
pushLog("[SISTEM] PerfMonitorGUI siap. Tekan tombol untuk memulai.")
pushLog(string.format("[SISTEM] Buffer maks: %d baris | Interval: %.1f dtk", CFG.MaxLogLines, CFG.LogInterval))

-- ============================================================
