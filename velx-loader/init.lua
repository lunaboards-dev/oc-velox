local sunpack,sformat,srep,sbyte,_x,cpu,vrt,ivx,ilu=string.unpack,string.format,string.rep,string.byte,"%.2x",computer,".velox/veloxrt.velx","init.velx","init.lua"
local function b2a(data)return sformat(sformat("%s-%s%s",srep(_x, 4),srep(_x.._x.."-",3),srep(_x,6)),sbyte(data, 1,#data))end
local function a2b(addr)
	addr=addr:gsub("%-", "")
	local baddr = ""
	for i=1, #addr, 2 do
		baddr = baddr .. string.char(tonumber(addr:sub(i, i+1), 16))
	end
	return baddr
end
_BIOS = "velx-loader"
_VELX = {id = 0x7F,name = "velx-loader",rt = "none"}
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
local velx_header = "<c5BBBBc4I3I3I3I4"
while cpu.pullSignal(0)do end
local comp=component
local clist,cproxy=comp.list, comp.proxy
local lp,eeprom,fg,bg,bs,edat,baddr,fs,iter,g,g_=1,cproxy(clist("eeprom")()),0xffffff,0,"VELX Loader v1.0"
g_ = clist("gpu")()
local function fgbg(f,b)g.setForeground(f)g.setBackground(b)end
if g_ then
	g = cproxy(g_)
	g_ = clist("screen")()
	if g_ then g.bind(g_) end
	local w, h = g.getViewport()
	fgbg(bg,fg)
	g.fill(1, 1, w, 1, " ")
	g.set((w/2)-(#bs//2),1,bs)
	fgbg(fg,bg)
	_VELX.gpu = g
end
local function p(msg)
	local w, h = g.getViewport()
	if (lp == h) then
		g.copy(1, 3, w, h-2, 0, -1)
		g.fill(1, h, w, 1, " ")
	else
		lp = lp + 1
	end
	g.set(1, lp, msg)
end
_VELX.print=p
local function panic(msg)p("PANIC!!! "..msg.."!!!")p"Strike any key to shutdown."repeat until cpu.pullSignal()=="key_up"cpu.shutdown()end
_VELX.panic = panic
local function load_velx(read, seek, close, name)
	local spos=seek()
	local magic,fver,compression,lver,osid,arctype,psize,lsize,ssize,rsize=sunpack(velx_header,read(string.packsize(velx_header)))
	if magic ~= "\27VelX" then
		panic("bad magic ("..magic..")")
	end
	if (fver ~= 1) then
		panic(string.format("bad version %x", fver))
	end
	if osid & 0x7F ~= 0x7F then
		panic(string.format("wrong os (%x ~= 0x7F)", osid & 0x7F))
	end
	if compression > 1 then
		panic"bad compression"
	end
	if arctype ~= "\0\0\0\0" then
		panic("bad arctype ("..arctype..")")
	end
	if (fver ~= 1) then
		panic"wrong version"
	end
	local prog = read(psize)
	if compression == 1 then
		prog = lzss_decompress(prog)
	end
	seek(lsize+ssize)
	return assert(load(prog, "="..(name or "(loaded velx)")))
end
local function boot_velx(path, ...)
	local h = fs.open(path, "r")
	if not h then
		panic(path.." not found")
	end
	local read = function(a)
		local want = a
		local buf = ""
		while want > 0 do
			local c = fs.read(h, want)
			if c then
				buf = buf .. c
				want = want-#c
			else
				return buf
			end
		end
		return buf
	end
	local seek = function(a) return fs.seek(h, "cur", a or 0) end
	local close = function() return fs.close(h) end
	load_velx(read, seek, close, path)(...)
	panic("system stopped")
end
local sskip = {[4]=16,[3]=0,[0]=-1,[11]=-1}
local function find_baddr()
	edat = eeprom.getData()
	local pos = 1
	while true do
		if pos+2 > #edat then break end
		local ent, etype = sunpack("<HB", edat, pos)
		if ent == 0 and etype & 15 == 4 then
			return pos+3
		else
			local llen = etype >> 4
			local ex = sskip[etype & 15]
			if ex & 0x8 > 0 then ex = -1 end
			pos = pos + 3 + ((ex > -1 and ex) or (ex == -1 and (sunpack("I"..llen, edat, pos)+llen)) or llen)
		end
	end
	eeprom.setData(edat.."\0\0\4"..srep("\0", 16))
	return find_baddr()
end
local function gbaddr()
	local bl = find_baddr()
	return b2a(edat:sub(bl, bl+16))
end
baddr = gbaddr()
function computer.setBootAddress(a)
	local bl = find_baddr()
	eeprom.setData(edat:sub(1, bl-1)..a2b(a)..edat:sub(bl+16))
end
computer.getBootAddress = gbaddr
local function setfs()--p("Boot address set to "..baddr)
	computer.setBootAddress(baddr)
end
::load::
fs = cproxy(baddr)
p("Trying boot address "..baddr)
if not fs then goto search end
if fs.exists(vrt) then setfs()
	p("Loading "..vrt)
	boot_velx(vrt, baddr, edat)
end
if fs.exists(ivx) then setfs()
	p("Loading "..ivx)
	boot_velx(ivx, baddr, edat)
end
if fs.exists(ilu) then setfs()
	p("Loading "..ilu)
	local h,buf,lc = fs.open(ilu, "r"),""
	repeat
		lc = fs.read(h, math.huge)
		buf = buf .. (lc or "")
	until lc == "" or not lc
	load(buf, "=init.lua")()
end
::search::
p("No boot found! Searching...")
if not iter then
	iter=clist"filesystem"
end
baddr=iter()
p("Trying "..baddr)
if not baddr then panic"no init found!"end
goto load