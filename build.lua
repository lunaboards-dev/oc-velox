local lfs = require("lfs")

local files = {}
for name in lfs.dir("veloxrt") do
    local pname = name:sub(1, #name-4)
    if (name:sub(1,1) ~= "." and name ~= "package.lua" and name ~= "coreinit.lua" and name:sub(#name-3) == ".lua") then
        table.insert(files, string.format("%q", string.format("%s=veloxrt/%s", pname, name)))
    end
    
end
os.execute("rm -rf build")
os.execute("mkdir -p build/tmp")
--print(string.format("luaroll -m veloxrt -o- %s | cat veloxrt/package.lua - > veloxrt.bin", table.concat(files, " ")))
--os.execute("luamin -f velx-loader/init.lua > build/velx-loader.lua") -- fuck off, luamin
--os.execute("luacomp zlua/init.lua > build"..t1)
os.execute("lua utils/targa-to-vxi.lua assets/fox.tga build/fox.vix")
os.execute("lua utils/targa-to-vxi.lua assets/fox-bw.tga build/fox_mono.vix")
os.execute("cat build/fox.vix | lua utils/tolua.lua > build/fox.vix.lua")
os.execute("cat build/fox_mono.vix | lua utils/tolua.lua > build/fox_mono.vix.lua")
os.execute("luaroll -o build/zlua.lua init=zlua/init.lua lzss=lzss.lua")
os.execute("luaroll -o build/make-velx.lua init=make-velx/init.lua lzss=lzss.lua")

os.execute("lua build/zlua.lua velx-loader/init.lua > build/velx-loader.lua")
local tmp = os.tmpname()
os.execute(string.format("luaroll -Z -o- lzss=mini-lzss.lua images.fox=build/fox.vix.lua images.fox_mono=build/fox_mono.vix.lua %s | cat veloxrt/coreinit.lua veloxrt/package.lua - > build/"..tmp, table.concat(files, " ")))
os.execute("lua build/make-velx.lua --compress --out build/veloxrt.velx build/"..tmp)
--os.remove("build/"..tmp)