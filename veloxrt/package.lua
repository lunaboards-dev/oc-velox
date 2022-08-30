package = {}
do
    local function preload(mod)
        if package.preload[mod] then
            return package.preload[mod]()
        end
        return "no field package.preload['"..mod.."']"
    end

    -- Helper!
    local function sub(path, module)
        return (path:gsub("%?", (module:gsub("%.", "/"))))
    end

    package.searchers = {
        preload
    }
    package.loaded = {}
    package.vxpath = "/boot/.velox/lib/?.velx;./?.velx"
    package.path = "/boot/.velox/lib/?.lua;/boot/.velox/lib/?/init.lua;./?.lua;./?/init.lua"

    function require(mod)
        local function cacheret(name, ...)
            rv = table.pack(...)
            package.loaded[name] = rv[1]
            return rv[1]
        end
        if package.loaded[mod] then return package.loaded[mod] end
        local err = ""
        for i=1, #package.searchers do
            local m, er = assert(package.searchers[i](mod))
            --component.invoke(component.list("sandbox")(), "log", tostring(i).." "..mod.."\n"..tostring(m))
            if type(m) == "string" then err = err .. "\n" .. m else return cacheret(mod, m()), er end
        end
    end
end
