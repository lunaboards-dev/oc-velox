local config = {}

local sformat, srep, sbyte, _x = string.format, string.rep, string.byte, "%.2x"
local uuidfmt = sformat("%s-%s%s",srep(_x, 4),srep(_x.._x.."-",3),srep(_x,6))
local function b2a(data)return sformat(uuidfmt,sbyte(data, 1,#data))end
local function a2b(addr)
	addr=addr:gsub("%-", "")
	local baddr = ""
	for i=1, #addr, 2 do
		baddr = baddr .. string.char(tonumber(addr:sub(i, i+1), 16))
	end
	return baddr
end

local c_ents = {}

local types = {
    [0] = "string",
    "int",
    "float",
    "bool",
    "uuid",
    "hwpath",
    [7] = "any",
    string= 0,
    int = 1,
    float = 2,
    bool = 3,
    uuid = 4,
    hwpath = 5,
    any = 7
}

local function keys(t)
    local ks = {}
    for k, v in pairs(t) do
        if type(k) == "number" then
            table.insert(ks, k)
        end
    end
    table.sort(ks)
    local pos = 0
    return function()
        pos = pos + 1
        return ks[pos], t[ks[pos]]
    end
end

--[[
    types:
    - string (0x00)
    - int (0x01)
    - float (0x02)
    - bool (0x03)
    - uuid (0x04)
    - hwpath (0x05)
    - any (0x07)
    - arrays of all types (put [] on the end)
    not specifying makes it allow any type
]]
local defaults = {}
function config.add_entry(id, name, type, default)
    c_ents[id] = {name = name, type = type, default=default}
    defaults[name] = default
    defaults[id] = default
end

--#region parsing
local parse_array

local function parse_type(str, pos, epack)
    local etype, elen = epack & 0x7, epack >> 4
    local is_array = (epack >> 3) & 1
    if (is_array > 0) then
        local vl = string.unpack("I"..elen, str, pos)
        pos = pos + elen
        return parse_array(str, pos, vl)
    elseif (etype == 0) then
        local vl = string.unpack("I"..elen, str, pos)
        return str:sub(pos, pos+vl-1), pos+vl
    elseif (etype == 1) then
        return string.unpack("i"..elen, str, pos), pos+elen
    elseif (etype == 2) then
        if (elen == 4) then
            return string.unpack("f", str, pos), pos+4
        elseif (elen == 8) then
            return string.unpack("d", str, pos), pos+8
        else
            return 0/0, pos+elen
        end
    elseif (etype == 3) then
        return elen > 0, pos
    elseif (etype == 4) then
        return b2a(str:sub(pos, pos+15)), pos+16
    elseif (etype == 5) then
        local vl = string.unpack("I"..elen, str, pos)
        local packed = str:sub(pos, pos+vl-1)
        return {
            __type = "hwpath",
            fs = b2a(packed:sub(1, 16)),
            path = packed:sub(17)
        }, pos+vl+elen
    end
end

parse_array = function(str, pos, size)
    local epos = pos+size
    local arr = {}
    local i = 1
    while pos < epos do
        local epack, l = string.unpack("<B", str, pos)
        pos = pos + 1
        arr[i], pos = parse_type(str, pos, epack)
    end
    return arr, epos
end
--#endregion parsing

function config.parse(str, autofill, tbl)
    tbl = tbl or {}
    local pos = 1
    while pos < #str do
        local ent, epack, l = string.unpack("<HB", str, pos)
        pos = pos + 3
        local t
        t, pos = parse_type(str, pos, epack)
        rawset(tbl, ent, t)
    end
    for k, v in keys(c_ents) do
        if not rawget(tbl, k) and autofill then
            --tbl[k] = v.default
            --tbl[v.name] = v.default
            rawset(tbl, k, v.default)
            rawset(tbl, v.name, v.default)
        else
            --tbl[v.name] = tbl[k]
            rawset(tbl, v.name, rawget(tbl, k))
        end
        --_VELX.print(tostring(k).."  "..v.name.."  "..tostring(tbl[k]))
    end
    return tbl
end
--#region writing
local function get_width(n)
    for i=1, 8 do
        local ok, str = pcall(string.pack, "<i"..i, n)
        if ok then
            return str, n
        end
    end
    error("too large")
end

local function get_fwidth(n)
    local ok, str = pcall(string.pack, "<f", n)
    if not ok then return string.pack("<d", n), 8 end
    if string.unpack("<f", str) ~= n then return string.pack("<d", n), 8 end
    return str, 4
end

local function make_str(dt, data)
    if dt == "string" then
        data = tostring(data)
        local sval, width = get_width(#data)
        return string.char(((width & 0xF) << 4))..sval..data
    elseif dt == "int" then
        data = tonumber(data)//1
        local sval, width = get_width(data)
        return string.char(((width & 0xF) << 4) | 1)..sval
    elseif dt == "float" then
        data = tonumber(data)
        local sval, width = get_fwidth(data)
        return string.char(((width & 0xF) << 4) | 2)..sval
    elseif dt == "bool" then
        return string.char(((data and 1 or 0) << 4) | 3)
    elseif dt == "uuid" then
        return string.char(4)..a2b(data)
    elseif dt == "hwpath" then
        if not data.fs or not data.path then
            error("invalid hwpath")
        end
        local ds = a2b(data.fs)..data.path
        local sval, width = get_width(#ds)
        return string.char(((width & 0xF) << 4) | 5)..sval..ds
    elseif dt == "any" then
        if type(data) == "table" then
            if data.__type == "hwpath" then
                return make_str("hwpath", data)
            end
            error("cannot serialize table in non-array type")
        elseif type(data) == "string" then
            if (data:find("^"..uuidfmt.."$")) then
                return make_str("uuid", data)
            end
            return make_str("string", data)
        elseif type(data) == "number" and math.type(data) == "integer" then
            return make_str("int", data)
        elseif type(data) == "number" and math.type(data) == "float" then
            return make_str("float", data)
        elseif type(data) == "boolean" then
            return make_str("bool", data)
        else
            error("invalid type")
        end
    else
        error("invalid type")
    end
end
--#endregion writing
function config.write(cfg, max_size, start_with)
    local outstr = ""
    --_VELX.print("Writing cfg...")
    for k, v in keys(c_ents) do
        --_VELX.print(table.concat({k, tostring(cfg[k]), tostring(cfg[v.name]), tostring(v.default)}, "  "))
        --cfg[k] = cfg[v.name] or cfg[k] or v.default
        rawset(cfg, k, rawget(cfg, v.name) or rawget(cfg, k) or v.default)
    end
    for k, v in keys(cfg) do
        --_VELX.print(table.concat({tostring(k), tostring(v), tostring(start_with)}, "  "))
        if k < start_with then goto continue end
        local cent = c_ents[k]
        if cent then
            if cent.type:sub(#cent.type-1) == "[]" then
                local s = ""
                local ct = cent.type:sub(1, #cent.type-3)
                local ls = #outstr
                for i=1, #v do
                    s = s .. make_str(ct, v[i])
                    if (#s+ls > max_size) then
                        return outstr, k
                    end
                end
                local al = #s
                local str, width = get_width(al)
                if ls+width+al+1 > max_size then
                    return outstr, k
                end
                outstr = outstr .. string.char((width << 4) | (1 << 3) | (types[ct] or 7)) .. str .. s
            else
                local tstr = string.pack("<H", k)..make_str(cent.type, v)
                if #tstr+#outstr > max_size then
                    return outstr, k
                end
                outstr = outstr .. tstr
            end
        end
        --component.proxy(component.list("sandbox")()).log("end", k)
        ::continue::
    end
    return outstr
end

-- core entries
config.add_entry(0x0000, "default_drive", "uuid", b2a(srep("\0", 16))) -- used by velx-loader
config.add_entry(0x0010, "rtc_offset", "float", 0)
config.add_entry(0x0011, "rtc_divisor", "float", 0)
config.add_entry(0x0012, "rtc_set", "bool", false)
config.add_entry(0x0020, "rtc2_offset", "float", 0)
config.add_entry(0x0021, "rtc2_scale", "float", 1)

-- velox entries
config.add_entry(0x0100, "velox_version", "string")
config.add_entry(0x0101, "velox_preload", "hwpath[]")
config.add_entry(0x0102, "velox_boot_delay", "float", 2)

config.add_entry(0x0110, "velox_boot_paths", "string[]")
config.add_entry(0x0111, "velox_boot_names", "string[]")
config.add_entry(0x0112, "velox_boot_argc", "int[]")
config.add_entry(0x0113, "velox_boot_argv", "any[]")

config.add_entry(0x0120, "velox_bios_protection", "bool", false)
config.add_entry(0x0121, "velox_bios_locations", "hwpath[]")

local eeprom = component.proxy(component.list("eeprom")())
local prox = component.proxy(_VELX.root)
local sources = {
    {
        read = function()
            return eeprom.getData()
        end,
        write = function(d)
            return eeprom.setData(d)
        end,
        maxSize = 256
    },
    {
        read = function()
            if not prox.exists("/.velox/config") then return "" end
            local h = prox.open("/.velox/config", "rb")
            local buf = ""
            while true do
                local c = prox.read(h, math.huge)
                if c == "" or not c then prox.close(h) return buf end
                buf = buf .. c
            end
        end,
        write = function(d)
            local h = prox.open("/.velox/config", "wb")
            prox.write(h, d)
            prox.close(h)
        end
    }
}

local back = {}

for i=1, #sources do
    config.parse(sources[i].read(), false, back)
end

local function pk(k, v)
    --_VELX.print(string.format("__index: %q  %q", k, v or "n/a"))
    return v
end

config.map = setmetatable({}, {
    __index = function(t, k)
        --for k, v in pairs(t) do _VELX.print(tostring(k).."  "..tostring(v)) end
        if back[k] then return back[k] end
        for i=1, #sources do
            config.parse(sources[i].read(), false, back)
            if rawget(back, k) then return pk(k, rawget(back, k)) end
        end
        back[k] = defaults[k] or (c_ents[k] and c_ents[k].default)
        return pk(k, back[k])
    end,
    __newindex = function(t, k, v)
        --_VELX.print(table.concat({tostring(k), tostring(v)}, "  "))
        back[k] = v
        local last = 0
        for i=1, #sources do
            local res
            res, last = config.write(back, sources[i].max_size or math.huge, last)
            sources[i].write(res)
            if not last then break end
        end
    end
})

return config