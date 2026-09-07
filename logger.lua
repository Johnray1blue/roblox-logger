-- ============================================================
--  EggWatcher.lua — LocalScript → StarterPlayerScripts
-- ============================================================

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

local player  = Players.LocalPlayer
local gui     = Instance.new("ScreenGui")
gui.Name = "EggWatcher"; gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Toggle button — pojok kanan bawah, kecil
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size             = UDim2.new(0, 70, 0, 22)
toggleBtn.Position         = UDim2.new(1, -78, 1, -30)
toggleBtn.BackgroundColor3 = Color3.fromRGB(20, 100, 50)
toggleBtn.BorderSizePixel  = 0
toggleBtn.Text             = "🥚 LOG"
toggleBtn.TextColor3       = Color3.new(1,1,1)
toggleBtn.TextSize         = 11
toggleBtn.Font             = Enum.Font.GothamBold
toggleBtn.ZIndex           = 10
toggleBtn.Parent           = gui

-- Panel — hidden by default, hook jalan di background
local panel = Instance.new("Frame")
panel.Size             = UDim2.new(0, 460, 0, 420)
panel.Position         = UDim2.new(1, -474, 1, -460)
panel.BackgroundColor3 = Color3.fromRGB(6, 14, 10)
panel.BorderSizePixel  = 0
panel.Visible          = false
panel.ZIndex           = 9
panel.Parent           = gui
local ps = Instance.new("UIStroke", panel)
ps.Color = Color3.fromRGB(40, 180, 80); ps.Thickness = 1

local hdr = Instance.new("Frame")
hdr.Size = UDim2.new(1,0,0,24)
hdr.BackgroundColor3 = Color3.fromRGB(20, 100, 50)
hdr.BorderSizePixel = 0; hdr.ZIndex = 10; hdr.Parent = panel

local hLbl = Instance.new("TextLabel")
hLbl.Size = UDim2.new(1,-30,1,0); hLbl.Position = UDim2.new(0,6,0,0)
hLbl.BackgroundTransparency = 1; hLbl.Text = "EGG WORLD WATCHER"
hLbl.TextColor3 = Color3.new(1,1,1); hLbl.TextSize = 11
hLbl.Font = Enum.Font.GothamBold
hLbl.TextXAlignment = Enum.TextXAlignment.Left
hLbl.ZIndex = 11; hLbl.Parent = hdr

local xBtn = Instance.new("TextButton")
xBtn.Size = UDim2.new(0,26,1,0); xBtn.Position = UDim2.new(1,-26,0,0)
xBtn.BackgroundTransparency = 1; xBtn.Text = "X"
xBtn.TextColor3 = Color3.new(1,1,1); xBtn.TextSize = 12
xBtn.Font = Enum.Font.GothamBold; xBtn.ZIndex = 11; xBtn.Parent = hdr

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1,-6,1,-60)
scroll.Position = UDim2.new(0,3,0,26)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = Color3.fromRGB(40,180,80)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.ZIndex = 10; scroll.Parent = panel

local ll = Instance.new("UIListLayout", scroll)
ll.Padding = UDim.new(0,1); ll.SortOrder = Enum.SortOrder.LayoutOrder
local lp = Instance.new("UIPadding", scroll)
lp.PaddingTop = UDim.new(0,3)
lp.PaddingLeft = UDim.new(0,4)
lp.PaddingRight = UDim.new(0,4)

local bRow = Instance.new("Frame")
bRow.Size = UDim2.new(1,0,0,32)
bRow.Position = UDim2.new(0,0,1,-32)
bRow.BackgroundColor3 = Color3.fromRGB(10,20,12)
bRow.BorderSizePixel = 0; bRow.ZIndex = 10; bRow.Parent = panel

local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.new(0.5,-2,1,-8)
copyBtn.Position = UDim2.new(0,4,0,4)
copyBtn.BackgroundColor3 = Color3.fromRGB(20,80,40)
copyBtn.BorderSizePixel = 0
copyBtn.Text = "📋 Copy All"
copyBtn.TextColor3 = Color3.new(1,1,1)
copyBtn.TextSize = 11
copyBtn.Font = Enum.Font.GothamBold
copyBtn.ZIndex = 11; copyBtn.Parent = bRow

local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(0.5,-2,1,-8)
clearBtn.Position = UDim2.new(0.5,2,0,4)
clearBtn.BackgroundColor3 = Color3.fromRGB(50,20,20)
clearBtn.BorderSizePixel = 0
clearBtn.Text = "🗑 Clear"
clearBtn.TextColor3 = Color3.new(1,1,1)
clearBtn.TextSize = 11
clearBtn.Font = Enum.Font.GothamBold
clearBtn.ZIndex = 11; clearBtn.Parent = bRow

-- ── LOG ──────────────────────────────────────────────────────
local logIdx = 0
local function log(msg, color)
    logIdx += 1
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,0,0,0)
    l.AutomaticSize = Enum.AutomaticSize.Y
    l.BackgroundTransparency = 1
    l.Text = os.date("%H:%M:%S") .. " " .. msg
    l.TextColor3 = color or Color3.fromRGB(160, 230, 180)
    l.TextSize = 10
    l.Font = Enum.Font.Code
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextWrapped = true
    l.LayoutOrder = logIdx
    l.ZIndex = 11; l.Parent = scroll
    task.defer(function() scroll.CanvasPosition = Vector2.new(0, math.huge) end)
end

-- ── DEEP DUMP ────────────────────────────────────────────────
local function deepDump(val, depth)
    depth = depth or 0
    if depth > 3 then return "..." end
    local t = typeof(val)
    if t == "string"  then return string.format('"%s"', val:sub(1,40)) end
    if t == "number"  then return tostring(val) end
    if t == "boolean" then return tostring(val) end
    if t == "nil"     then return "nil" end
    if t == "Vector3" then return string.format("V3(%.2f,%.2f,%.2f)", val.X, val.Y, val.Z) end
    if t == "Vector2" then return string.format("V2(%.2f,%.2f)", val.X, val.Y) end
    if t == "CFrame"  then
        local p = val.Position
        return string.format("CF(%.1f,%.1f,%.1f)", p.X, p.Y, p.Z)
    end
    if t == "Instance" then return string.format("[%s:%s]", val.ClassName, val.Name) end
    if t == "table" then
        local parts = {}
        local count = 0
        for k, v in pairs(val) do
            count += 1
            if count <= 8 then
                table.insert(parts, tostring(k) .. "=" .. deepDump(v, depth+1))
            end
        end
        if count > 8 then table.insert(parts, string.format("...+%d", count-8)) end
        return "{" .. table.concat(parts, ", ") .. "}"
    end
    return t
end

-- ── HOOK ─────────────────────────────────────────────────────
local conns = {}

local function hookRemote(remote, folderName)
    local conn = remote.OnClientEvent:Connect(function(...)
        local args = { ... }
        local parts = {}
        for i, a in ipairs(args) do
            table.insert(parts, string.format("[%d]%s", i, deepDump(a)))
        end
        local argStr = #parts > 0 and table.concat(parts, "  ") or "(no args)"
        log(string.format("🟢 %s/%s", folderName, remote.Name), Color3.fromRGB(80, 255, 140))
        log(string.format("   └─ %s", argStr), Color3.fromRGB(200, 255, 200))
    end)
    table.insert(conns, conn)
end

local function hookAll()
    -- Cari RE folder tanpa hardcode path
    local reFolder = nil
    for _, obj in ipairs(RS:GetDescendants()) do
        if obj.Name == "RE" and obj:FindFirstChild("EggWorld") then
            reFolder = obj
            break
        end
    end

    if not reFolder then
        log("❌ RE/EggWorld tidak ditemukan!", Color3.fromRGB(255,80,80))
        for _, obj in ipairs(RS:GetDescendants()) do
            if obj:IsA("RemoteEvent") and obj.Name:lower():find("egg") then
                log("  → " .. obj:GetFullName(), Color3.fromRGB(255,180,60))
            end
        end
        return
    end

    log("✅ RE ditemukan: " .. reFolder:GetFullName(), Color3.fromRGB(100,255,150))

    local count = 0
    for _, folder in ipairs(reFolder:GetChildren()) do
        local folderName = folder.Name
        local isTarget = folderName == "EggWorld"
            or folderName == "Haul"
            or folderName == "Payouts"
            or folderName == "RewardScreen"
            or folderName == "PenRoster"
            or folderName == "ProfileMirror"
            or folderName == "Homestead"
        if isTarget then
            for _, remote in ipairs(folder:GetDescendants()) do
                if remote:IsA("RemoteEvent") then
                    hookRemote(remote, folderName)
                    count += 1
                end
            end
        end
    end

    log(string.format("✅ Hooking %d remote", count), Color3.fromRGB(100, 255, 150))
    log("Sekarang: ambil egg manual → balik base → copy log", Color3.fromRGB(200, 200, 100))
end

-- ── BUTTONS ──────────────────────────────────────────────────
copyBtn.MouseButton1Click:Connect(function()
    local labels = {}
    for _, c in ipairs(scroll:GetChildren()) do
        if c:IsA("TextLabel") then table.insert(labels, c) end
    end
    table.sort(labels, function(a,b) return a.LayoutOrder < b.LayoutOrder end)
    local lines = {}
    for _, l in ipairs(labels) do table.insert(lines, l.Text) end
    setclipboard(table.concat(lines, "\n"))
    local prev = copyBtn.Text
    copyBtn.Text = "✅ Copied!"
    copyBtn.BackgroundColor3 = Color3.fromRGB(10,120,60)
    task.delay(1.5, function()
        copyBtn.Text = prev
        copyBtn.BackgroundColor3 = Color3.fromRGB(20,80,40)
    end)
end)

clearBtn.MouseButton1Click:Connect(function()
    for _, c in ipairs(scroll:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    logIdx = 0
end)

local isOpen = false
toggleBtn.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    panel.Visible = isOpen
end)
xBtn.MouseButton1Click:Connect(function()
    isOpen = false
    panel.Visible = false
end)

-- ── START ─────────────────────────────────────────────────────
hookAll()
log("Watcher aktif. Lakukan aksi di game sekarang.")
