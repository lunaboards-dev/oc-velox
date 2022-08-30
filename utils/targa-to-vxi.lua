local targa_header = "<BBBHHBHHHHBB"

local f = io.open(arg[1], "rb")
local of = io.open(arg[2], "wb")
local compress = arg[3] == "z"

local header = f:read(targa_header:packsize())

local idlen, cmap_type, itype, cmap_first, cmap_len, cmap_size, xorigin, yorigin, iwidth, iheight, pdepth, idesc = targa_header:unpack(header)
local color_map = {}
for i=1, cmap_len do
    color_map[i] = f:read(cmap_size//8)
end
local block_map = {}
local function block(x, y)
    return x>>1, y>>2
end
local xy_to_braile = {
    [0] = 0,
    [1] = 3,
    [2] = 1,
    [3] = 4,
    [4] = 2,
    [5] = 5,
    [6] = 6,
    [7] = 7
}
local function get_block(x, y)
    local bx, by = block(x, y)
    for i=1, #block_map do
        local blk = block_map[i]
        if blk.x == bx and blk.y == by then
            return blk
        end
    end
    table.insert(block_map, {
        x = bx,
        y = by,
        colors = {},
        writes = 0,
        pixels = 0
    })
    --print("new blk")
    return get_block(x, y)
end
local function blkpos(x, y)
    return ((y & 3)<<1)|(x&1)
    --return ((y%4)*2)+(x%2)
end
for y=0,iheight-1 do
    for x=0,iwidth-1 do
        local blk = get_block(x, y)
        --print(x, y, blk.x, blk.y)
        local c = f:read(1):byte()
        if #blk.colors > 2 and blk.colors[2] ~= c then
            --print(string.format("too many colors in block %d, %d (px %d, py %d, c %d, o %x)", blk.x, blk.y, x, y, c, f:seek("cur", 0)))
            c = blk.colors[1]
        elseif blk.colors[1] ~= c then
            table.insert(blk.colors, c)
        end
        if (blk.colors[2] == c) then
            blk.pixels = blk.pixels | (1 << blkpos(x, y))
        end
        blk.writes = blk.writes+1
        if (blk.writes > 8) then
            --print(string.format("WARNING: block %d, %d has %d writes!", blk.x, blk.y, blk.writes))
        end
    end
end

--[[
    struct vxi_header {
        char magic[4];
        char blks_x;
        char blks_y;
        ushort blks_total;
    };
]]
local vxi_header = string.pack("<c4BBHB", "vix\1", iwidth/2, iheight/4, #block_map, math.min(#color_map, 16))
of:write(vxi_header)
for i=1, 16 do
    if not color_map[i] then break end
    of:write(color_map[i] or "\0\0\0")
end
if (compress) then
    of:write("IMZ:")
else
    of:write("IMG:")
end
local buf = ""
for i=1, #block_map do
    local blk = block_map[i]
    --of:write(string.pack("BB", blk.colors[1] | ((blk.colors[2] or 0) << 4), blk.pixels))
    buf = buf .. string.pack("BB", blk.colors[1] | ((blk.colors[2] or 0) << 4), blk.pixels)
end
if (compress) then
    buf = require("lzss").compress(buf)
end
of:write(buf)
of:close()
f:close()