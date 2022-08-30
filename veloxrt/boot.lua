local tohuman = require "tohuman"
local hooks -- delay loading until we've decreased memory usage
local sched   = require "sched"
local gpu = _VELX.gpu


local strings = {
    "Main  Processor :",
    "Memory Capacity :",
    "Memory  Slot  1 :",
    "Memory  Slot  2 :",
    "Memory  Slot  3 :",
    "Memory  Slot  4 :",
    "EEPROM          :",

    "HOME Boot Menu   DEL BIOS Config",
    "Loading Boot Menu  ...          ",
    "Loading BIOS Config...          "
}

local meminfo, cpuinfo, eeprom = {}

for k, v in pairs(computer.getDeviceInfo()) do
    if v.class == "processor" then
        cpuinfo = v
    elseif v.class == "memory" then
        if not v.clock then eeprom = v else
        table.insert(meminfo, v) end
    end
end

local vix = require("vix")
local fox = (gpu.maxDepth() > 1) and require("images.fox") or require("images.fox")

local w, h = gpu.getViewport()
gpu.setBackground(0)
gpu.setForeground(0xFFFFFF)
gpu.fill(1, 1, w, h, " ")
local foximg = vix.load(fox)
--local f = io.open("fox.vix", "rb")
--local foximg = vix.load(f:read("*a"))
--f:close()
local iw,ih = foximg:size()
foximg:draw(gpu, 1, 1)
gpu.setBackground(0)
gpu.setForeground(0xFFFFFF)
gpu.set(iw+2,2, "VeloxRT BIOS v1.00OC")
gpu.set(iw+2,3, "(C) 2022, lunar-sam")
gpu.set(iw+2,4, "OpenComputers Velox BIOS")
gpu.set(w-#strings[8], h, strings[8])
computer.beep(1000, 0.2)
for i=1, 10 do
    computer.pullSignal(0)
end
hooks = require "hooks"
local lp = 1
local reserved_top = 5
local reserved_bottom = 1
local function print(msg)
    local w, h = gpu.getViewport()
    local resv = (reserved_top+reserved_bottom)
    for line in msg:gmatch("[^\n]+") do
        if (lp == h-resv) then
            gpu.copy(1, reserved_top+2, w, h-(resv+1), 0, -1)
            gpu.fill(1, h-reserved_bottom, w, 1, " ")
            --computer.pullSignal(1)
        else
            lp = lp + 1
        end
        gpu.set(2, lp+reserved_top, (line:gsub("\t", "  ")))
    end
end

local function tohz(clk)
    return tohuman(clk, false, {"Hz", "kHz", "MHz"}, 2)
end

local function tokb(bytes)
    return tohuman(bytes, true, {" bytes", "KiB", "MiB"}, 0)
end

local cpu_clk = tonumber(cpuinfo.clock:match("%d+"), 10)
print(string.format("%s %s %s %s", strings[1], cpuinfo.vendor, cpuinfo.product, tohz(cpu_clk*9999)))
print(string.format("%s %dK", strings[2], computer.totalMemory()//1024))
for i=1, #meminfo do
    local clk = tonumber(meminfo[i].clock:match("%d+"), 10)
    print(string.format("%s %s %s %s", strings[2+i], meminfo[i].vendor, meminfo[i].product, tohz(clk*999)))
end
print(string.format("%s %s %s %s bytes", strings[7], eeprom.vendor, eeprom.product, eeprom.capacity))
print("")
local waiting = {" ...", ". ..", ".. .", "... "}
local tlp = lp
local i = 0
local last_dot = computer.uptime()
_VELX.print = print
_VELX.panic = function(msg)

end
print("Waiting for devices...")
hooks.run("postinit")
local menu
local function await_keypress()
    local evt, key, _
    evt, _, _, key = computer.pullSignal(0)
    if menu then return end
    if evt == "key_down" and key == 211 then
        menu = "config"
        gpu.set(w-#strings[10], h, strings[10])
    elseif evt == "key_down" and key == 199 then
        menu = "menu"
        gpu.set(w-#strings[9], h, strings[9])
    end
end

while true do
    local _lp = lp
    lp = tlp
    print("Waiting for devices"..waiting[(i%4)+1])
    lp = _lp
    if (computer.uptime()-last_dot > 0.3) then
        i = i + 1
        last_dot = computer.uptime()
    end
    await_keypress()
    if #sched.get_threads() == 1 then break end
end

local st = computer.uptime()
while not menu do
    await_keypress()
    if (computer.uptime()-st > config.map.velox_boot_delay) then break end
end

if menu == "menu" then
    require("menus_menu")
elseif menu == "config" then
    require("menus_config")
end
reserved_bottom = 0
local fs = component.proxy(_VELX.root)

local h,buf,lc = fs.open("init.lua", "r"),""
repeat
    lc = fs.read(h, math.huge)
    buf = buf .. (lc or "")
until lc == "" or not lc
load(buf, "=init.lua")()