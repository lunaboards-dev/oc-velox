local lzss = require("lzss")
local outscr = [[
local function lzss_decompress(a)local b,c,d,e,j,i,h,g=1,'',''while b<=#a do
e=c.byte(a,b)b=b+1
for k=0,7 do h=c.sub
g=h(a,b,b)if e>>k&1<1 and b<#a then
i=c.unpack('>I2',a,b)j=1+(i>>4)g=h(d,j,j+(i&15)+2)b=b+1
end
b=b+1
c=c..g
d=h(d..g,-4^6)end
end
return c end
load(lzss_decompress("%s"), "=%s")()
]]

local f = io.open(arg[1], "rb")
local s1 = lzss.compress(f:read("*a"))
local s2 = arg[1]
local function tostr(s) return s:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\n", "\\n"):gsub("\r", "\\r") end
io.stdout:write(string.format(outscr, tostr(s1), s2))