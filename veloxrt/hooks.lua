local hooks = {}
local thd

local hlist = {}

function hooks.register(type)
    hlist[type] = {}
end

function hooks.add(type, name, func)
    hlist[type][name] = func
end

function hooks.remove(type, name)
    hlist[type][name] = nil
end

function hooks.call(htype, ...)
    for k, v in pairs(hlist[htype]) do
        if (type(v) == "function") then
            local rv = table.pack(pcall(v, ...))
            if rv.n > 1 and rv[1] then
                return table.unpack(rv, 2)
            end
        end
    end
end

function hooks.run(htype, ...)
    local args = table.pack(...)
    hlist[htype][-1] = (hlist[htype][-1] or 0)+1
    if not thd then thd = require("sched") end
    thd.add("hookrun$"..htype.."#"..hlist[htype][-1], function()
        for k, v in pairs(hlist[htype]) do
            if (type(v) == "function") then
                pcall(v, table.unpack(args))
            end
        end
    end)
end

return hooks