local tohuman = require "tohuman"
local gpu = require("component").gpu
local computer = require("computer")

local strings = {
    "Main  Processor :",
    "Memory Capacity :",
    "Memory  Slot  1 :",
    "Memory  Slot  2 :",
    "Memory  Slot  3 :",
    "Memory  Slot  4 :",
    "EEPROM          :",

    "HOME Boot Menu   DEL Config"
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
--local fox = require("images.fox")
--local fox_mono = require("images.fox")

local w, h = gpu.getViewport()
gpu.setBackground(0)
gpu.setForeground(0xFFFFFF)
gpu.fill(1, 1, w, h, " ")
--local foximg = vix.load((gpu.maxDepth() == 1) and fox_mono or fox)
local f = io.open("fox.vix", "rb")
local foximg = vix.load(f:read("*a"))
f:close()
local iw,ih = foximg:size()
foximg:draw(gpu, 1, 1)
gpu.setBackground(0)
gpu.setForeground(0xFFFFFF)
gpu.set(iw+2,2, "VeloxRT BIOS v1.00OC")
gpu.set(iw+2,3, "(C) 2022, lunar-sam")
gpu.set(iw+2,4, "OpenComputers Velox BIOS")
gpu.set(w-#strings[8], h, strings[8])
computer.beep(1000, 0.2)

local lp = 1
local reserved_top = 5
local reserved_bottom = 1
local function print(msg)
    local w, h = gpu.getViewport()
    local resv = (reserved_top+reserved_top)
	if (lp == h-resv) then
		gpu.copy(1, reserved_top+1, w, h-(resv+1), 0, -1)
		gpu.fill(1, h, w-reserved_bottom, 1, " ")
	else
		lp = lp + 1
	end
	gpu.set(2, lp+reserved_top, msg)
end

local function tohz(clk)
    return tohuman(clk, false, {"Hz", "kHz", "MHz"}, 2)
end

local function tokb(bytes)
    return tohuman(bytes, true, {" bytes", "KiB", "MiB"}, 0)
end

local cpu_clk = tonumber(cpuinfo.clock:match("%d+"), 10)
print(string.format("%s %s %s %s", strings[1], cpuinfo.vendor, cpuinfo.product, tohz(cpu_clk*9999)))
os.sleep(0.1)
print(string.format("%s %dK", strings[2], computer.totalMemory()//1024))
print("")
for i=1, #meminfo do
    local clk = tonumber(meminfo[i].clock:match("%d+"), 10)
    print(string.format("%s %s %s %s", strings[2+i], meminfo[i].vendor, meminfo[i].product, tohz(clk*999)))
end
os.sleep(0.1)
print(string.format("%s %s %s %s bytes", strings[7], eeprom.vendor, eeprom.product, eeprom.capacity))
os.sleep(0.2)
print("")
local waiting = {" ...", ". ..", ".. .", "... "}
print("Waiting for devices ...")
for i=0, 39 do
    lp = lp - 1
    print("Waiting for devices"..waiting[(i%4)+1])
    os.sleep(0.2)
end
print("RTC set to 72.0Hz")

os.sleep(2)