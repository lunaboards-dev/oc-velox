local bit = require("bit")
-- Load VXI.
print("loading", arg[2])
local f = io.open(arg[2], "rb")
local hdr = f:read(8)
if hdr:sub(1, 4) ~= "vix\1" then error("bad header") end
local x, y = hdr:byte(5, 6)
local total = bit.bor(hdr:byte(7), bit.lshift(hdr:byte(8), 8))
local cbuffer = {
    "",
    "",
    "",
    ""
}
local out = ""
local colors = {}
local function flip_bgr(bgr)
    return bgr:sub(3,3)..bgr:sub(2,2)..bgr:sub(1,1)
end
for i=1, 16 do
    colors[i] = flip_bgr(f:read(3)).."\xff"
end
f:seek("cur", 4)
for i=0, total do
    if (i % x == 0 and #cbuffer[1] > 0) then
        out = out .. table.concat(cbuffer)
        cbuffer = {"","","",""}
    end
    local blk = f:read(2)
    if not blk then break end
    local bgfg, pix = blk:byte(1, 2)
    local fg = colors[bit.rshift(bgfg, 4)+1]
    local bg = colors[bit.band(bgfg, 0xF)+1]
    for i=1, 8 do
        local line = math.ceil(i/2)
        cbuffer[line] = cbuffer[line] .. ((bit.band(pix, bit.lshift(1, i-1)) > 0) and fg or bg)
    end
end

local xres, yres = x*2, y*4
local img = love.image.newImageData(xres, yres, "rgba8", out)
local tex = love.graphics.newImage(img)
tex:setFilter("nearest", "nearest")

function love.load()
end
local scale = 8
function love.draw()
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(tex, 0, 0, 0, scale, scale)
    love.graphics.setColor(0,0,1,1)
    for i=0, x do
        love.graphics.line(i*(2*scale)+1, 0, i*(2*scale)+1, yres*scale)
    end
    love.graphics.setColor(1,0,0,1)
    for i=0, y do
        love.graphics.line(0, i*(4*scale)+1, xres*scale, i*(4*scale)+1)
    end
end