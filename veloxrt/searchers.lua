local hooks = require "hooks"
hooks.add("vfs_ready", "searchers", function()
    local vfs = require("vfs")
    local function velx(mod)
        local err = {}
        for path in package.vxpath:gmatch("[^;]+") do
            local rpath = sub(path, mod)
            if vfs.exists(rpath) then
                return velx.loadfile(rpath)
            end
            table.insert(err, "no file '"..rpath.."'")
        end
        return table.concat(err, "\n")
    end

    local function lua(mod)
        local err = {}
        for path in package.path:gmatch("[^;]+") do
            local rpath = sub(path, mod)
            if vfs.exists(rpath) then
                return loadfile(rpath)
            end
            table.insert(err, "no file '"..rpath.."'")
        end
        return table.concat(err, "\n")
    end

    table.insert(package.searchers, velx)
    table.insert(package.searchers, lua)
end)