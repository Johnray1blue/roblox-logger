-- ============================================================
--  Logger.lua — LocalScript → StarterPlayerScripts
--  Tujuan: dump struktur game dari client side
-- ============================================================

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart  = character:WaitForChild("HumanoidRootPart")

-- ════════════════════════════════════════════════════════════
--  GUI — simple scrolling log
-- ════════════════════════════════════════════════════════════
local gui = Instance.new("ScreenGui")
gui.Name         = "LoggerGui"
gui.ResetOnSpawn = false
gui.Parent       = player:WaitForChild("PlayerGui")

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size             = UDim2.new(0, 80, 0, 28)
toggleBtn.Position         = UDim2.new(0, 8, 1, -100)
toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 100)
toggleBtn.BorderSizePixel  = 0
toggleBtn.Text             = "LOGGER"
toggleBtn.TextColor3       = Color3.new(1,1,1)
toggleBtn.TextSize         = 12
toggleBtn.Font             = Enum.Font.GothamBold
toggleBtn.ZIndex           = 10
toggleBtn.Parent           = gui

local panel = Instance.new("Frame")
panel.Size             = UDim2.new(0, 420, 0, 500)
panel.Position         = UDim2.new(0, 8, 1, -615)
panel.BackgroundColor3 = Color3.fromRGB(8, 8, 16)
panel.BorderSizePixel  = 0
panel.Visible          = false
panel.ZIndex           = 9
panel.Parent           = gui
local ps = Instance.new("UIStroke", panel)
ps.Color = Color3.fromRGB(120, 60, 200); ps.Thickness = 1

-- Header
local hdr = Instance.new("Frame")
hdr.Size             = UDim2.new(1,0,0,26)
hdr.BackgroundColor3 = Color3.fromRGB(60, 20, 100)
hdr.BorderSizePixel  = 0; hdr.ZIndex = 10; hdr.Parent = panel

local hdrLbl = Instance.new("TextLabel")
hdrLbl.Size = UDim2.new(1,-30,1,0); hdrLbl.Position = UDim2.new(0,6,0,0)
hdrLbl.BackgroundTransparency = 1; hdrLbl.Text = "CLIENT LOGGER"
hdrLbl.TextColor3 = Color3.new(1,1,1); hdrLbl.TextSize = 11
hdrLbl.Font = Enum.Font.GothamBold
hdrLbl.TextXAlignment = Enum.TextXAlignment.Left
hdrLbl.ZIndex = 11; hdrLbl.Parent = hdr

local xBtn = Instance.new("TextButton")
xBtn.Size = UDim2.new(0,26,1,0); xBtn.Position = UDim2.new(1,-26,0,0)
xBtn.BackgroundTransparency = 1; xBtn.Text = "X"
xBtn.TextColor3 = Color3.new(1,1,1); xBtn.TextSize = 12
xBtn.Font = Enum.Font.GothamBold; xBtn.ZIndex = 11; xBtn.Parent = hdr

-- Scroll
local scroll = Instance.new("ScrollingFrame")
scroll.Size                 = UDim2.new(1,-6, 1,-120)
scroll.Position             = UDim2.new(0,3, 0,28)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel      = 0
scroll.ScrollBarThickness   = 3
scroll.ScrollBarImageColor3 = Color3.fromRGB(120, 60, 200)
scroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
scroll.CanvasSize           = UDim2.new(0,0,0,0)
scroll.ZIndex = 10; scroll.Parent = panel

local ll = Instance.new("UIListLayout", scroll)
ll.Padding = UDim.new(0,1); ll.SortOrder = Enum.SortOrder.LayoutOrder
local lp = Instance.new("UIPadding", scroll)
lp.PaddingTop = UDim.new(0,3); lp.PaddingLeft = UDim.new(0,4); lp.PaddingRight = UDim.new(0,4)

-- Button panel bawah
local btnPanel = Instance.new("Frame")
btnPanel.Size             = UDim2.new(1,0,0,90)
btnPanel.Position         = UDim2.new(0,0,1,-90)
btnPanel.BackgroundColor3 = Color3.fromRGB(14, 10, 24)
btnPanel.BorderSizePixel  = 0; btnPanel.ZIndex = 10; btnPanel.Parent = panel
local bps = Instance.new("UIStroke", btnPanel)
bps.Color = Color3.fromRGB(120,60,200); bps.Thickness = 1
bps.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local bpl = Instance.new("UIListLayout", btnPanel)
bpl.FillDirection = Enum.FillDirection.Vertical
bpl.Padding = UDim.new(0,4); bpl.SortOrder = Enum.SortOrder.LayoutOrder
local bpp = Instance.new("UIPadding", btnPanel)
bpp.PaddingTop = UDim.new(0,6); bpp.PaddingBottom = UDim.new(0,6)
bpp.PaddingLeft = UDim.new(0,8); bpp.PaddingRight = UDim.new(0,8)

local function makeBtn(text, color, order)
    local b = Instance.new("TextButton")
    b.LayoutOrder = order
    b.Size = UDim2.new(1,0,0,22)
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.new(1,1,1)
    b.TextSize = 11
    b.Font = Enum.Font.GothamBold
    b.ZIndex = 11
    b.Parent = btnPanel
    return b
end

local btnScanWS       = makeBtn("📦 Scan Workspace (nama object unik)", Color3.fromRGB(40,80,160), 1)
local btnScanRemotes  = makeBtn("📡 Scan Remotes (ReplicatedStorage)", Color3.fromRGB(80,40,140), 2)
local btnWatchRemotes = makeBtn("👁 Watch Remotes LIVE (on/off)",       Color3.fromRGB(100,50,30), 3)
local btnClear        = makeBtn("🗑 Clear Log",                          Color3.fromRGB(40,40,40),  4)

-- ════════════════════════════════════════════════════════════
--  LOG HELPER
-- ════════════════════════════════════════════════════════════
local logIdx   = 0
local function log(msg, color)
    logIdx += 1
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,0,0,0)
    l.AutomaticSize = Enum.AutomaticSize.Y
    l.BackgroundTransparency = 1
    l.Text = os.date("%H:%M:%S") .. " " .. msg
    l.TextColor3 = color or Color3.fromRGB(180, 210, 255)
    l.TextSize = 10
    l.Font = Enum.Font.Code
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextWrapped = true
    l.LayoutOrder = logIdx
    l.ZIndex = 11
    l.Parent = scroll
    task.defer(function() scroll.CanvasPosition = Vector2.new(0, math.huge) end)
end

local function logSep(title)
    log("══ " .. title .. " ══", Color3.fromRGB(180, 120, 255))
end

-- ════════════════════════════════════════════════════════════
--  1. SCAN WORKSPACE — nama object unik + jumlah + parent
-- ════════════════════════════════════════════════════════════
local function scanWorkspace()
    logSep("SCAN WORKSPACE")

    local counts  = {}   -- name → count
    local parents = {}   -- name → set of parent names

    for _, obj in ipairs(workspace:GetDescendants()) do
        -- skip karakter sendiri
        if obj:IsDescendantOf(character) then continue end

        local n = obj.Name
        counts[n]  = (counts[n] or 0) + 1
        parents[n] = parents[n] or {}
        local pname = obj.Parent and obj.Parent.Name or "?"
        parents[n][pname] = true
    end

    local list = {}
    for name, count in pairs(counts) do
        table.insert(list, { name = name, count = count, pnames = parents[name] })
    end
    table.sort(list, function(a,b) return a.count > b.count end)

    local shown = 0
    for _, e in ipairs(list) do
        if shown >= 60 then log("  ... (max 60 ditampilkan)", Color3.fromRGB(100,100,100)); break end

        -- Kumpulkan parent names
        local plist = {}
        for pn in pairs(e.pnames) do table.insert(plist, pn) end
        local parentStr = table.concat(plist, ", ")
        if #parentStr > 40 then parentStr = parentStr:sub(1,40) .. "…" end

        -- Highlight keywords yang menarik
        local nl = e.name:lower()
        local interesting = nl:find("egg") or nl:find("animal") or nl:find("creature")
            or nl:find("territory") or nl:find("nest") or nl:find("spawn")
            or nl:find("token") or nl:find("collect") or nl:find("item")
            or nl:find("pickup") or nl:find("drop") or nl:find("reward")
            or nl:find("zone") or nl:find("region") or nl:find("base")
            or nl:find("farm") or nl:find("bird") or nl:find("chicken")
            or nl:find("hen") or nl:find("duck") or nl:find("lay")

        local color = interesting
            and Color3.fromRGB(120, 255, 160)
            or  Color3.fromRGB(120, 120, 140)

        log(string.format("[%3dx] %-28s ← parent: %s", e.count, e.name, parentStr), color)
        shown += 1
    end

    logSep("WORKSPACE SELESAI")
end

-- ════════════════════════════════════════════════════════════
--  2. SCAN REMOTES — ReplicatedStorage & semua service
-- ════════════════════════════════════════════════════════════
local function scanRemotes()
    logSep("SCAN REMOTES")

    local services = {
        game:GetService("ReplicatedStorage"),
        game:GetService("ReplicatedFirst"),
    }

    local found = 0
    for _, svc in ipairs(services) do
        for _, obj in ipairs(svc:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("BindableEvent") then
                local t = obj.ClassName
                local path = obj.Name
                local p = obj.Parent
                -- bangun path pendek
                local parts = { obj.Name }
                local cur = obj.Parent
                local depth = 0
                while cur and cur ~= svc and depth < 4 do
                    table.insert(parts, 1, cur.Name)
                    cur = cur.Parent
                    depth += 1
                end
                path = table.concat(parts, "/")

                local color = obj:IsA("RemoteEvent")
                    and Color3.fromRGB(100, 200, 255)
                    or  Color3.fromRGB(255, 180, 100)

                log(string.format("[%s] %s", t:gsub("Remote",""):gsub("Bindable","Bind:"), path), color)
                found += 1
            end
        end
    end

    if found == 0 then
        log("Tidak ada Remote ditemukan di ReplicatedStorage.", Color3.fromRGB(255,140,60))
        log("Coba Watch Remotes LIVE untuk tangkap yang firing.", Color3.fromRGB(255,140,60))
    end

    logSep(string.format("REMOTES SELESAI (%d found)", found))
end

-- ════════════════════════════════════════════════════════════
--  3. WATCH REMOTES LIVE — hook semua RemoteEvent yang ada
--     Print setiap kali OnClientEvent / InvokeClient firing
-- ════════════════════════════════════════════════════════════
local watchConns  = {}
local watchActive = false

local function stopWatch()
    for _, c in ipairs(watchConns) do pcall(function() c:Disconnect() end) end
    watchConns = {}
    watchActive = false
    btnWatchRemotes.BackgroundColor3 = Color3.fromRGB(100,50,30)
    log("Watch LIVE dimatikan.", Color3.fromRGB(200,100,100))
end

local function startWatch()
    logSep("WATCH REMOTES LIVE")
    log("Intercepting semua RemoteEvent.OnClientEvent...", Color3.fromRGB(200,150,255))

    local hooked = 0
    local services = {
        game:GetService("ReplicatedStorage"),
        game:GetService("ReplicatedFirst"),
    }

    for _, svc in ipairs(services) do
        for _, obj in ipairs(svc:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                local name = obj.Name
                local conn = obj.OnClientEvent:Connect(function(...)
                    local args = { ... }
                    local parts = {}
                    for i, a in ipairs(args) do
                        local t = typeof(a)
                        local v
                        if t == "string"  then v = string.format('"%s"', a:sub(1,30))
                        elseif t == "number" then v = tostring(a)
                        elseif t == "boolean" then v = tostring(a)
                        elseif t == "table" then
                            -- shallow dump table
                            local kv = {}
                            for k, val in pairs(a) do
                                if #kv < 6 then
                                    table.insert(kv, tostring(k).."="..tostring(val):sub(1,20))
                                end
                            end
                            v = "{" .. table.concat(kv, ", ") .. "}"
                        elseif t == "Instance" then v = "["..a.ClassName..":"..a.Name.."]"
                        elseif t == "Vector3" then v = string.format("V3(%.1f,%.1f,%.1f)", a.X, a.Y, a.Z)
                        else v = t
                        end
                        table.insert(parts, string.format("arg%d:%s=%s", i, t:sub(1,4), v))
                    end
                    local argStr = #parts > 0 and table.concat(parts, "  ") or "(no args)"

                    -- Highlight event yang kelihatan terkait gameplay
                    local nl = name:lower()
                    local hot = nl:find("egg") or nl:find("collect") or nl:find("item")
                        or nl:find("pick") or nl:find("reward") or nl:find("spawn")
                        or nl:find("animal") or nl:find("token") or nl:find("give")
                        or nl:find("drop") or nl:find("territory") or nl:find("zone")
                        or nl:find("nest") or nl:find("farm") or nl:find("lay")

                    local color = hot
                        and Color3.fromRGB(120, 255, 160)
                        or  Color3.fromRGB(160, 160, 200)

                    log(string.format("🔔 %s  %s", name, argStr), color)
                end)
                table.insert(watchConns, conn)
                hooked += 1
            end
        end
    end

    log(string.format("Hooking %d RemoteEvent. Main-main di game sekarang!", hooked),
        Color3.fromRGB(100, 255, 160))
    watchActive = true
    btnWatchRemotes.BackgroundColor3 = Color3.fromRGB(180, 60, 20)
end

-- ════════════════════════════════════════════════════════════
--  KONEKSI TOMBOL
-- ════════════════════════════════════════════════════════════
local isOpen = false
toggleBtn.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    panel.Visible = isOpen
    toggleBtn.BackgroundColor3 = isOpen
        and Color3.fromRGB(40,10,70)
        or  Color3.fromRGB(60,20,100)
end)
xBtn.MouseButton1Click:Connect(function()
    isOpen = false; panel.Visible = false
    toggleBtn.BackgroundColor3 = Color3.fromRGB(60,20,100)
end)

btnScanWS.MouseButton1Click:Connect(function()      task.spawn(scanWorkspace) end)
btnScanRemotes.MouseButton1Click:Connect(function() task.spawn(scanRemotes)   end)
btnWatchRemotes.MouseButton1Click:Connect(function()
    if watchActive then stopWatch() else startWatch() end
end)
btnClear.MouseButton1Click:Connect(function()
    for _, c in ipairs(scroll:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    logIdx = 0
    log("Log cleared.", Color3.fromRGB(100,100,100))
end)

log("Logger siap. Klik tombol di bawah untuk mulai scan.")
log("Urutan: Scan Workspace → Scan Remotes → Watch LIVE saat main")
