local hooks = require "hooks"
-- Real time clock.
function computer.getRTC()
    local realoff = os.time()/config.map.rtc_divisor
    return config.map.rtc_offset+realoff
end

local sync_time, tmpfs_time
function computer.getRTC2()
    return (tmpfs_time+config.map.rtc2_offset+computer.uptime())-sync_time
end

hooks.add("postinit", "rtcsync", function()
    if not config.map.rtc_set then
        _VELX.print("Syncing RTC, please wait 3 seconds.")
        local st = computer.uptime()
        local ost = os.time()
        local dt = 3
        while true do
            computer.pullSignal(dt)
            if (computer.uptime()-st < dt) then
                dt = dt - (computer.uptime()-st)
            else
                break
            end
        end
        local fdt = computer.uptime()-st
        local odt = os.time()-ost
        config.map.rtc_divisor = odt/fdt
        config.map.rtc_set = true
        _VELX.print(string.format("RTC frequency set to %.1fHz", odt/fdt))
    end
    do
        _VELX.print("Syncing RTC2...")
        --[[
        local h = vfs.open("/tmp/.rtc", "w")
        vfs.close(h)
        tmpfs_time = vfs.lastModified()
        if os.date("*t", tmpfs_time/config.map.rtc2_scale).year > 10000 then
            config.map.rtc2_scale = 1000
        end
        sync_time = computer.uptime()]]
        sync_time = 0
        tmpfs_time = 0
        _VELX.print("NYI")
    end
    hooks.call("rtc_ready")
end)