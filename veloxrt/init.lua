-- Init
local hooks = require("hooks")
--#region hook registration
hooks.register "init"
hooks.register "postinit"
hooks.register "preboot"
hooks.register "shutdown"
hooks.register "vfs_ready"
hooks.register "rtc_ready"
hooks.register "thd_error"
--#endregion hook registration

_BIOS = "veloxrt"
_VELX = {
    id = 0x7E,
    name = "veloxrt",
    rt = "velox",
    print = _VELX.print,
    gpu = _VELX.gpu,
    root = computer.getBootAddress()
}

thd = require("sched")

local function tryload(path)
    if vfs.exists(path) then
        velx.loadfile(path)()
        return true
    end
end
thd.add("vxrt", function()
    xpcall(function()
        --[[if vfs.exists("/boot/.velox/config") then
            config("/boot/.velox/config")
        end
        tryload("/boot/.velox/preload.velx")
        if (config.primary and tryload(config.primary)) or
            tryload("/boot/.velox/boot.velx") or
            tryload("/boot/boot/boot.velx") or
            tryload("/boot/init.velx") then
                goto fail
        end
        panic("kernel not found")
        ::fail::
        panic("kernel exited")]]
        require("bootcfg")
        require("rtc")
        config = require("config")
        require("boot")
        --_VELX.print(config.map.default_drive)
        --[[bcfg = require("bootcfg")
        vfs = require("vfs")
        require("rtc")]]
    end, function(err)
        local bt = debug.traceback("PANIC!!! "..err)
        _VELX.print("uh oh")
        for line in bt:gmatch("[^\n]+") do
            _VELX.print(line:gsub("\t", "  "))
        end
        _VELX.print("Strike any key to shut down.")
        repeat until computer.pullSignal()=="key_up"
        computer.shutdown()
    end)
end)

while thd.run() do end
