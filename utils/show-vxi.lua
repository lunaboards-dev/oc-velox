local arg = {...}
local gpu = require("component").gpu
local vxi = io.open(arg[1], "rb")
local vxi_header = "<c4BBH"
local magic, x, y, total = vxi_header:unpack(vxi:read(vxi_header:packsize()))
local colors = {}
for i=1, 16 do
    colors[i] = string.unpack("<I3", (vxi:read(3)))
end
vxi:seek("cur", 4)
local spos = 0
local lc = -1
local lchars = ""
local function can_fill()
    local c = lchars:sub(1,1)
    if c:match("%A") and c:byte() > 31 and c:byte() < 127 then
        c = "%" .. c
    end
    return not lchars:find("[^"..c.."]")
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

local pos = 0
while true do
    local blk = vxi:read(2)
    if not blk then break end
    local cl, px = blk:byte(1, 2)
    --[[if ((cl ~= lc or pos % x == 0) and lc > -1) then
        print("set", cl & 16, cl >> 4)
        gpu.setForeground(colors[(cl & 15)+1])
        gpu.setBackground(colors[(cl >> 4)+1])
        if (#lchars > 1 and can_fill()) then
            print("fill", (spos%x)+1, (spos//x)+1, #lchars, 1, utf8.char(lchars:byte(1)+0x2800))
            gpu.fill((spos%x)+1, (spos//x)+1, #lchars, 1, utf8.char(lchars:byte(1)+0x2800))
        else
            local pchars = ""
            for i=1, #lchars do
                pchars = pchars .. utf8.char(lchars:byte(i)+0x2800)
            end
            print("set", (spos%x)+1, (spos//x)+1, pchars)
            gpu.set((spos%x)+1, (spos//x)+1, pchars)
        end
        spos = pos
        lc = cl
        lchars = string.char(px)
    elseif lc == -1 then
        lc = cl
        lchars = string.char(px)
    end]]
    local rx = 0
    for i=0, 7 do
        rx = rx | (((px & (1 << i)) > 0 and (1 << xy_to_braile[i])) or 0)
    end
    gpu.setBackground(colors[(cl & 15)+1])
    gpu.setForeground(colors[(cl >> 4)+1])
    gpu.set((pos%x)+1, (pos//x)+1, utf8.char(rx+0x2800))
    pos = pos + 1
    if (pos == total) then break end
end