local vxi = io.open(arg[1], "rb")
local vxi_header = "<c4BBH"
local magic, x, y, total = vxi_header:unpack(vxi:read(vxi_header:packsize()))
local colors = {}
for i=1, 16 do
    colors[i] = string.unpack("<I3", (vxi:read(3)))
end
vxi:seek("cur", 4)

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

local pos = 0
while true do
    local blk = vxi:read(2)
    if not blk then break end
    local cl, px = blk:byte(1, 2)
    local rx = 0
    for i=0, 7 do
        rx = rx | (((px & (1 << i)) > 0 and (1 << xy_to_braile[i])) or 0)
    end
    --[[gpu.setBackground(colors[(cl & 15)+1])
    gpu.setForeground(colors[(cl >> 4)+1])
    gpu.set((pos%x)+1, (pos//x)+1, utf8.char(rx+0x2800))]]
    if (pos%x == 0) then
        io.stdout:write("\n")
    end
    local bg = colors[(cl & 15)+1]
    local fg = colors[(cl >> 4)+1]
    io.stdout:write(string.format("\27[38;2;%d;%d;%dm", fg >> 16, (fg >> 8) & 0xFF, fg & 0xFF))
    io.stdout:write(string.format("\27[48;2;%d;%d;%dm", bg >> 16, (bg >> 8) & 0xFF, bg & 0xFF))
    io.stdout:write(utf8.char(rx+0x2800))
    pos = pos + 1
    if (pos == total) then break end
end
io.stdout:write("\27[0m\n")