--[[
    ▒█
    ║═╔╗╚╝╟╢╤╧│─╨
]]

local gpu = _VELX.gpu
local mc = gpu.maxDepth() == 1
local function color(c)
    if mc then
        return c ~= 0xFFFFFF and 0 or 0xFFFFFF
    end
end
gpu.setForeground(color(0xFFFFFF))
gpu.setBackground(color(0xFF))
local w, h = gpu.getViewport()
gpu.fill(1, 1, w, h, " ")
