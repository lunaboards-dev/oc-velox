local v = {}
v.hdr = "<c4BBHB"

local vix = {}

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

-- Loads it into a more OC friendly format
function v.load(data)
    local magic, x, y, total, cmap, pos = v.hdr:unpack(data)
    if magic ~= "vix\1" then return nil, "bad vix image or wrong version" end
    local colors = {}
    for i=1, cmap & 0xF do
        -- Colors are encoded in BGR8 (like targa)
        colors[i], pos = string.unpack("<I3", data, pos)
    end
    pos = pos + 4 -- debugging label
    local strings = {}
    local cstr, ccol, lasty, count
    for i=0, total-1 do
        local idx, cl, px = i
        cl, px, pos = string.unpack("BB", data, pos)
        local xpos, ypos = idx % x, idx//x
        local rx = 0
        for i=0, 7 do
            rx = rx | (((px & (1 << i)) > 0 and (1 << xy_to_braile[i])) or 0)
        end
        if not cstr then
            cstr = utf8.char(0x2800+rx)
            ccol = cl
            lasty = ypos
            count = 1
        elseif ypos ~= lasty then
            if not strings[lasty+1] then
                strings[lasty+1] = {}
            end
            local bg = colors[(ccol & 15)+1]
            local fg = colors[(ccol >> 4)+1]
            --print("newline", bg, fg, (ccol & 15)+1, (ccol >> 4)+1)
            table.insert(strings[lasty+1], {
                bg = bg,
                fg = fg,
                str = cstr,
                c = count
            })
            ccol = cl
            cstr = utf8.char(0x2800+rx)
            lasty = ypos
            count = 1
        elseif ccol ~= cl then
            if not strings[lasty+1] then
                strings[lasty+1] = {}
            end
            local bg = colors[(ccol & 15)+1]
            local fg = colors[(ccol >> 4)+1]
            --print("change", bg, fg, (ccol & 15)+1, (ccol >> 4)+1)
            table.insert(strings[lasty+1], {
                bg = bg,
                fg = fg,
                str = cstr,
                c = count
            })
            ccol = cl
            cstr = utf8.char(0x2800+rx)
            count = 1
        else
            cstr = cstr..utf8.char(0x2800+rx)
            count = count + 1
        end
    end
    if not strings[lasty+1] then
        strings[lasty+1] = {}
    end
    local bg = colors[(ccol & 15)+1]
    local fg = colors[(ccol >> 4)+1]
    --print("last", bg, fg, (ccol & 15)+1, (ccol >> 4)+1)
    table.insert(strings[lasty+1], {
        bg = bg,
        fg = fg,
        str = cstr,
        c = count
    })
    return setmetatable({
        lines = strings,
        colors = colors,
        x = x,
        y = y
    }, {__index = vix})
end

function vix:draw(gpu, x, y)
    for i=1, #self.lines do
        local xoff = 0
        local line = self.lines[i]
        for j=1, #line do
            local chunk = line[j]
            gpu.setBackground(chunk.bg)
            gpu.setForeground(chunk.fg)
            gpu.set(x+xoff, i+y-1, chunk.str)
            xoff = xoff + chunk.c
        end
    end
end

function vix:resolution()
    return self.x*2, self.y*4
end

function vix:size()
    return self.x, self.y
end

return v