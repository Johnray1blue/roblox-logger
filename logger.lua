-- INTEGRATED AUTOMATION & LOG SYSTEM (CUSTOM NATIVE)
-- LocalScript → Jalankan langsung di Executor Anda

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Bersihkan versi lama jika tumpuk
if playerGui:FindFirstChild("SteelAnEggAuditSystem") then
    playerGui.SteelAnEggAuditSystem:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SteelAnEggAuditSystem"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- ==========================================
-- 1. ELEMEN VISUAL (BERDASARKAN TEMPLATE ANDA)
-- ==========================================

-- FAB tombol toggle panel (tengah bawah)
local fab = Instance.new("TextButton")
fab.Size = UDim2.new(0, 120, 0, 44)
fab.Position = UDim2.new(0.5, -60, 1, -130)
fab.BackgroundColor3 = Color3.fromRGB(26, 26, 46)
fab.BorderSizePixel = 0
fab.Text = "⬡ PANEL MENU"
fab.TextColor3 = Color3.fromRGB(74, 222, 128)
fab.TextSize = 14
fab.Font = Enum.Font.GothamBold
fab.ZIndex = 10
fab.Parent = screenGui
Instance.new("UICorner", fab).CornerRadius = UDim.new(0, 10)
local fabStroke = Instance.new("UIStroke", fab)
fabStroke.Color = Color3.fromRGB(74, 222, 128)
fabStroke.Thickness = 2

-- Tombol Copy All Log (tengah bawah)
local copyFloating = Instance.new("TextButton")
copyFloating.Size = UDim2.new(0, 160, 0, 44)
copyFloating.Position = UDim2.new(0.5, -80, 1, -75)
copyFloating.BackgroundColor3 = Color3.fromRGB(74, 222, 128)
copyFloating.Text = "📋 Copy All Log"
copyFloating.TextColor3 = Color3.fromRGB(15, 15, 26)
copyFloating.TextSize = 14
copyFloating.Font = Enum.Font.GothamBold
copyFloating.ZIndex = 10
copyFloating.Parent = screenGui
Instance.new("UICorner", copyFloating).CornerRadius = UDim.new(0, 10)

-- Panel utama (tengah layar)
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0.95, 0, 0.55, 0) -- Disesuaikan ukurannya agar muat tombol kontrol
panel.Position = UDim2.new(0.025, 0, 0.05, 0)
panel.BackgroundColor3 = Color3.fromRGB(15, 15, 26)
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 9
panel.Parent = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
local panelStroke = Instance.new("UIStroke", panel)
panelStroke.Color = Color3.fromRGB(45, 45, 78)
panelStroke.Thickness = 1

-- Header Panel
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 44)
header.BackgroundColor3 = Color3.fromRGB(26, 26, 46)
header.BorderSizePixel = 0
header.ZIndex = 10
header.Parent = panel
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -60, 1, 0)
titleLabel.Position = UDim2.new(0, 14, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "⬡ EXPERT AUDIT TOOL"
titleLabel.TextColor3 = Color3.fromRGB(74, 222, 128)
titleLabel.TextSize = 13
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 11
titleLabel.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 36, 0, 30)
closeBtn.Position = UDim2.new(1, -42, 0.5, -15)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(160, 160, 192)
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold
closeBtn.ZIndex = 11
closeBtn.Parent = header

-- TOMBOL KONTROL UTAMA: TOGGLE AUTOMATION
local automationToggleBtn = Instance.new("TextButton")
automationToggleBtn.Size = UDim2.new(1, -16, 0, 45)
automationToggleBtn.Position = UDim2.new(0, 8, 0, 52)
automationToggleBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68) -- Merah default (OFF)
automationToggleBtn.Text = "AUTO COLLECT EGG: OFF"
automationToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
automationToggleBtn.TextSize = 13
automationToggleBtn.Font = Enum.Font.GothamBold
automationToggleBtn.ZIndex = 10
automationToggleBtn.Parent = panel
Instance.new("UICorner", automationToggleBtn).CornerRadius = UDim.new(0, 8)

-- Area Logging / Scrolling Frame
local logArea = Instance.new("ScrollingFrame")
logArea.Size = UDim2.new(1, -8, 1, -110) -- Geser ke bawah agar tidak bertabrakan dengan tombol toggle
logArea.Position = UDim2.new(0, 4, 0, 105)
logArea.BackgroundTransparency = 1
logArea.BorderSizePixel = 0
logArea.ScrollBarThickness = 4
logArea.ScrollBarImageColor3 = Color3.fromRGB(45, 45, 78)
logArea.CanvasSize = UDim2.new(0, 0, 0, 0)
logArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
logArea.ZIndex = 10
logArea.Parent = panel
local listLayout = Instance.new("UIListLayout", logArea)
listLayout.Padding = UDim.new(0, 4)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- ==========================================
-- 2. LOGIC & DATA STREAM MANAGEMENT
-- ==========================================
_G.AutoCollect = false
local allLogs = {}
local logCount = 0

local function addLogEntry(message, isError)
    logCount += 1
    local time = os.date("%H:%M:%S")
    local prefix = isError and "[⚠️ ERROR] " or "[ℹ️ INFO] "
    local fullText = "[" .. time .. "] " .. prefix .. tostring(message)
    table.insert(allLogs, fullText)

    local entry = Instance.new("TextButton")
    entry.Size = UDim2.new(1, 0, 0, 0)
    entry.AutomaticSize = Enum.AutomaticSize.Y
    entry.BackgroundColor3 = Color3.fromRGB(26, 26, 46)
    entry.BorderSizePixel = 0
    entry.TextTransparency = 1
    entry.LayoutOrder = logCount
    entry.ZIndex = 11
    entry.Parent = logArea
    Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 6)

    local leftBar = Instance.new("Frame", entry)
    leftBar.Size = UDim2.new(0, 3, 1, 0)
    leftBar.BackgroundColor3 = isError and Color3.fromRGB(239, 68, 68) or Color3.fromRGB(74, 222, 128)
    leftBar.BorderSizePixel = 0
    leftBar.ZIndex = 12

    local textLabel = Instance.new("TextLabel", entry)
    textLabel.Size = UDim2.new(1, -14, 0, 0)
    textLabel.Position = UDim2.new(0, 10, 0, 6)
    textLabel.AutomaticSize = Enum.AutomaticSize.Y
    textLabel.BackgroundTransparency = 1
    textLabel.Text = fullText
    textLabel.TextColor3 = isError and Color3.fromRGB(252, 165, 165) or Color3.fromRGB(180, 200, 255)
    textLabel.TextSize = 11
    textLabel.Font = Enum.Font.Code
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextWrapped = true
    textLabel.ZIndex = 12

    -- Klik satu entri log = copy entri tersebut saja ke clipboard
    entry.MouseButton1Click:Connect(function()
        setclipboard(fullText)
        textLabel.TextColor3 = Color3.fromRGB(74, 222, 128)
        task.wait(0.5)
        textLabel.TextColor3 = isError and Color3.fromRGB(252, 165, 165) or Color3.fromRGB(180, 200, 255)
    end)

    task.defer(function()
        logArea.CanvasPosition = Vector2.new(0, logArea.AbsoluteCanvasSize.Y)
    end)
end

-- ==========================================
-- 3. CORE AUTOMATION MOVEMENT (STEALTH)
-- ==========================================
-- Koordinat Target Game (Atur kembali jika letak Map bergeser)
local BASE_POSITION = Vector3.new(100, 5, 200) 
local EGG_SPAWN_POSITION = Vector3.new(10, 5, 20)

local function performMovement(targetPosition)
    local character = player.Character
    if not character then error("Karakter Anda tidak termuat di Workspace.") end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then error("Komponen fisik HumanoidRootPart hilang.") end
    
    humanoid:MoveTo(targetPosition)
    local startTime = tick()
    
    while tick() - startTime < 10 and _G.AutoCollect do
        task.wait(0.1)
        if not _G.AutoCollect then 
            humanoid:MoveTo(rootPart.Position) -- Rem paksa karakter
            break 
        end
        if humanoid.Health <= 0 then error("Karakter tereliminasi saat bergerak!") end
        if (rootPart.Position - targetPosition).Magnitude < 4 then return true end
        humanoid:MoveTo(targetPosition) -- Terus paksa berjalan agar tidak macet rintangan
    end
    error("Pergerakan timeout! Karakter terhalang / anti-cheat memblokir WalkSpeed.")
end

local function startAutomationLoop()
    task.spawn(function()
        while _G.AutoCollect do
            addLogEntry("Berjalan menuju koordinat kemunculan Telur...", false)
local eggSuccess, eggError = pcall(function() performMovement(EGG_SPAWN_POSITION) end)if not eggSuccess thenaddLogEntry(tostring(eggError), true)_G.AutoCollect = falseautomationToggleBtn.Text = "AUTO COLLECT EGG: OFF"automationToggleBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68)breakendif not _G.AutoCollect then break endtask.wait(0.8) -- Animasi penyerapan objek teluraddLogEntry("Telur terkumpul. Berjalan membawa telur ke Base...", false)local baseSuccess, baseError = pcall(function() performMovement(BASE_POSITION) end)if not baseSuccess thenaddLogEntry(tostring(baseError), true)_G.AutoCollect = falseautomationToggleBtn.Text = "AUTO COLLECT EGG: OFF"automationToggleBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68)breakendaddLogEntry("Siklus pengiriman sukses! Mengulang dari awal...", false)task.wait(0.2)endend)end-- ==========================================-- 4. KONEKSI EVENT & INTERAKSI BUTTON-- ==========================================-- Klik Tombol Toggle Menu Utamafab.MouseButton1Click:Connect(function()panel.Visible = not panel.Visibleend)closeBtn.MouseButton1Click:Connect(function()panel.Visible = falseend)-- Klik Tombol Aktifkan Auto CollectautomationToggleBtn.MouseButton1Click:Connect(function()_G.AutoCollect = not _G.AutoCollectif _G.AutoCollect thenautomationToggleBtn.Text = "AUTO COLLECT EGG: ON"automationToggleBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94) -- Hijau terangaddLogEntry("Automasi diaktifkan oleh Bug Hunter Expert.", false)startAutomationLoop()elseautomationToggleBtn.Text = "AUTO COLLECT EGG: OFF"automationToggleBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68) -- Merah terangaddLogEntry("Automasi dihentikan paksa via UI.", false)endend)-- Klik Tombol Salin Seluruh Riwayat LogcopyFloating.MouseButton1Click:Connect(function()local textToCopy = table.concat(allLogs, "\n")if setclipboard thensetclipboard(textToCopy)addLogEntry("Seluruh teks log berhasil disalin ke clipboard.", false)elseaddLogEntry("Fungsi setclipboard tidak didukung oleh perangkat ini.", true)endend)addLogEntry("Sistem Audit Siap. Tekan ⬡ PANEL MENU untuk mengonfigurasi.", false)
