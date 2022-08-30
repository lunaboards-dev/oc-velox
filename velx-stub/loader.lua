local knl = _ARCHIVE:get("kernel")
local params = table.pack(...)
if _ARCHIVE:exists("config") then
    params = load("return {".._ARCHIVE:get("config").."}")()
end
return load(knl, "=kernel")(table.unpack(params)) -- realistically we shouldn't return but oh well