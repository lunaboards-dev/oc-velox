local vfs = {}

local handles = {}

local function autoclose()
    for i=#handles, 1, -1 do
        if not handles[i].handle then
            local h = handles[i]
            h.fs.close(h.hand)
            table.remove(handles, i)
        end
    end     
end

local mr = {}
local dirs = {
    "boot",
    "dev"
}
local function not_supported() return nil, "not supported" end
local function static_return(s) return function() return s end end
mr.open = not_supported
mr.seek = not_supported
mr.write = not_supported
mr.isReadOnly = static_return(true)
mr.spaceTotal = static_return(-1)
mr.spaceUsed = static_return(-1)
mr.rename = not_supported
mr.lastModified = static_return(0)
mr.getLabel = static_return("rootfs")
mr.remove = not_supported
mr.size = static_return(0)
mr.read = not_supported
mr.setLabel = mr.getLabel

function mr.list(path)
    if not mr.exists(path) then return end
    path = path:gsub("^/", "")
    if path:sub(#path) ~= "/" then
        path = path .. "/"
    end
    local rv = {}
    for i=1, #dirs do
        if path == "/" then
            if not dirs[i]:find("/") then
                table.insert(rv, dirs[i])
            end
        else
            if dirs[i]:sub(1, #path) == path and not dirs[i]:sub(#path+1):find("/") then
                table.insert(rv, dirs[i])
            end
        end
    end
    return rv
end

function mr.makeDirectory(path)
    if mr.exists(path:gsub("/.+$", "")) then
        table.insert(dirs, path)
        return true
    end
end

function mr.exists(path)
    for i=1, #dirs do
        if dirs[i] == path then
            return true
        end
    end
    return false
end

mr.isDirectory = mr.exists

local mounts = {
    {point = "/", proxy=mr}
}

function vfs.mount(path, proxy)

end

function vfs.umount(path)

end

function vfs.resolve(path)
    for i=#mounts, 1, -1 do

    end
end

local function passthrough(func)
    return function(path, ...)
        autoclose()
        local fs, path = vfs.resolve(path)
        if not fs then return nil, path end
        return fs[func](path, ...)
    end
end

vfs.remove = passthrough("remove")
vfs.list = passthrough "list"
vfs.lastModified = passthrough "lastModified"
vfs.size = passthrough "size"
vfs.exists = passthrough "exists"
vfs.makeDirectory = passthrough "makeDirectory"
vfs.isDirectory = passthrough "exists"
vfs.isReadOnly = passthrough "isReadOnly"

vfs.makeDirectory("/boot")
vfs.makeDirectory("/dev")
for dev in component.list("filesystem") do
    local path = "/dev/"..dev:sub(1, 6)
    vfs.makeDirectory(path)
    vfs.mount(path, component.proxy(dev))
end

function vfs.open(path, mode)
    autoclose()
    local fs, path = vfs.resolve(path)
    if not fs then return nil, path end
    local h, err = fs.open(path, mode)
    if not h then return nil, err end
    local rh = {}
    table.insert(handles, setmetatable({
        check = rh,
        hand = h,
        fs = fs
    }, {__mode="v"}))
    return rh
end

function vfs.read(hand, amt)
    autoclose()
    for i=1, #handles do
        if handles[i].check == hand then
            local h = handles[i]
            return h.fs.read(h.hand, amt)
        end
    end
    return nil, "invalid handle"
end

function vfs.write(hand, dat)
    autoclose()
    for i=1, #handles do
        if handles[i].check == hand then
            local h = handles[i]
            return h.fs.write(h.hand, dat)
        end
    end
    return nil, "invalid handle"
end

function vfs.close(hand)
    autoclose()
    for i=1, #handles do
        if handles[i].check == hand then
            local h = handles[i]
            local rv, err = h.fs.close(h.hand)
            table.remove(handles, i)
            return rv, err
        end
    end
    return nil, "invalid handle"
end

function vfs.seek(hand, whence, offset)
    autoclose()
    for i=1, #handles do
        if handles[i].check == hand then
            local h = handles[i]
            return h.fs.seek(h.hand, whence, offset)
        end
    end
    return nil, "invalid handle"
end

function vfs.move(from, to)
    autoclose()
    local h1 = vfs.open()
end

-- pain
function vfs.rename(from, to)
    autoclose()
    local vfs1, path1 = vfs.resolve(from)
    local vfs2, path2 = vfs.resolve(to)
    if not vfs1 or not vfs2 then return nil, (not vfs1 and path1) or (not vfs2 and path2) end
    if vfs1 == vfs2 then
        return vfs1.rename(path1, path2)
    else

    end
end

vfs.mount("/boot", component.proxy(computer.getBootAddress()))
hooks.call("vfs_ready")

return vfs