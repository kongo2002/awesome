-- custom functions needed in rc.lua

function getlayouticon(s)
    if not awful.layout.get(s) then 
        return " . " 
    end

    return layout_icons[awful.layout.getname(awful.layout.get(s))]
end

function setBg(bgcolor, text)
    if text ~= nil then
        return string.format('<bg color="%s" />%s', bgcolor, text)
    end
end

function setFg(fgcolor, text)
    if text ~= nil then
        return string.format('<span color="%s">%s</span>', fgcolor, text)
    end
end

function setBgFg(bgcolor, fgcolor, text)
    if text ~= nil then
        return string.format('<bg color="%s"/><span color="%s">%s</span>', bgcolor, fgcolor, text)
    end
end

function setFont(font, text)
    if text ~= nil then
        return string.format('<span font_desc="%s">%s</span>', font, text)
    end
end

function getMpd()
    local mpc = io.popen("mpc status")
    local mpc_string = mpc:read("*line")

    if mpc_string:find("volume:") == nil then
        return setFg(beautiful.fg_widg, mpc_string .. " [" .. string.match(mpc:read("*line"), "%d+:%d%d/%d+:%d%d") .. "]" .. spacer)
    else
        return " "
    end
end

function memInfo()
    local f = io.open("/proc/meminfo")
 
    for line in f:lines() do
        if line:match("^MemTotal.*") then
            memTotal = math.floor(tonumber(line:match("(%d+)")) / 1024)
        elseif line:match("^MemFree.*") then
            memFree = math.floor(tonumber(line:match("(%d+)")) / 1024)
        elseif line:match("^Buffers.*") then
            memBuffers = math.floor(tonumber(line:match("(%d+)")) / 1024)
        elseif line:match("^Cached.*") then
            memCached = math.floor(tonumber(line:match("(%d+)")) / 1024)
            break
        end
    end
    f:close()
 
    memFree = memFree + memBuffers + memCached
    memInUse = memTotal - memFree
    memUsePct = math.floor(memInUse / memTotal * 100)
 
    if tonumber(memUsePct) >= 25 then
        memUsePct = setFg("#FF6565", memUsePct)
        memInUse = setFg("#FF6565", memInUse)
    else
        memUsePct = setFg(beautiful.fg_widg, memUsePct)
        memInUse = setFg(beautiful.fg_widg, ""..memInUse.."M")
    end

    memTotal = setFg(beautiful.fg_widg, ""..memTotal.."M")

    return memUsePct.."%".." ("..memInUse.."/"..memTotal..")"..spacer
end

function fsInfo(device)
    local f = io.popen("df -h "..device)

    local output = f:read("*line")
    output = f:read("*line")

    local total, used, perc = output:match("(%d+G)%s+(%d+G)%s+%d+G%s+(%d+%%)")

    return setFg(beautiful.fg_widg, used.."/"..total.." ("..perc..")"..spacer)
end

cpu0_total = 0
cpu0_active = 0
cpu1_total = 0
cpu1_active = 0

function cpuInfo()
    local f = io.open("/proc/stat")

    for l in f:lines() do
        local cpu = {}

        if l:find("cpu0") then
            cpu[1], cpu[2], cpu[3], cpu[4] = l:match("cpu0 (%d+) (%d+) (%d+) (%d+)")

            total_new = tonumber(cpu[1]) + tonumber(cpu[2]) + tonumber(cpu[3]) + tonumber(cpu[4])
            active_new = tonumber(cpu[1]) + tonumber(cpu[2]) + tonumber(cpu[3])

            diff_total = total_new - cpu0_total
            diff_active = active_new - cpu0_active

            cpu0_perc = math.floor(diff_active/diff_total*100)

            cpu0_total = total_new
            cpu0_active = active_new

        elseif l:find("cpu1") then
            cpu[1], cpu[2], cpu[3], cpu[4] = l:match("cpu1 (%d+) (%d+) (%d+) (%d+)")

            total_new = tonumber(cpu[1]) + tonumber(cpu[2]) + tonumber(cpu[3]) + tonumber(cpu[4])
            active_new = tonumber(cpu[1]) + tonumber(cpu[2]) + tonumber(cpu[3])

            diff_total = total_new - cpu1_total
            diff_active = active_new - cpu1_active

            cpu1_perc = math.floor(diff_active/diff_total*100)

            cpu1_total = total_new
            cpu1_active = active_new

            break
        end
    end

    f:close()

    return setFg(beautiful.fg_widg, cpu0_perc.."% | "..cpu1_perc.."%"..spacer)
end

netr_total = 0
nett_total = 0

function netInfo()
    local f = io.open("/proc/net/dev")

    for l in f:lines() do
        
        if l:find("eth0") then
            receive, transmit = l:match(":(%d+)%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+(%d+)")

            diff_r = receive - netr_total
            diff_t = transmit - nett_total

            -- divide by hook interval (2 seconds)
            receive_perc = math.floor(diff_r / 1024 / 2)
            transmit_perc = math.floor(diff_t / 1024 / 2)

            netr_total = receive
            nett_total = transmit
            
            break
        end
    end

    f:close()

    return setFg(beautiful.fg_widg, receive_perc .. " | " .. transmit_perc .. spacer)
end

function procInfo()
    local f = io.popen("ps -e | wc -l")
    local total = tonumber(f:read()) - 2

    f = io.open("/proc/stat")

    for l in f:lines() do
        if l:find("procs_running") then
            active = l:match("procs_running%s+(%d+)")

            break
        end
    end

    f:close()

    return setFg(beautiful.fg_widg, active.."/"..total..spacer)
end
