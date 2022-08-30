local hooks = require "hooks"
-- Boot config
local bcfg = {}

local cfglist = {}

function bcfg.add(path, name, ...)
    table.insert(cfglist, {
        path = path,
        name = name,
        args = table.pack(...)
    })
end

function bcfg.reload()
    cfglist = {}
    local arg_offset = 0
    for i=1, #config.map.velox_boot_paths do
        local args = {}
        for j=1, config.map.velox_boot_argc[i] do
            args[j] = config.map.velox_boot_argv[arg_offset+j]
        end
        arg_offset = arg_offset + config.map.velox_boot_argc
        bcfg.add(config.map.velox_boot_paths[i], config.map.velox_boot_names, table.unpack(args))
    end
end

function bcfg.save()
    local paths, names, argc, argv = {},{},{},{}
    for i=1, #bcfg do
        local boot = cfglist[i]
        paths[i] = boot.path
        names[i] = boot.name
        argc[i] = #boot.args
        for j=1, argc[i] do
            table.insert(argv, boot.args[j])
        end
    end
    config.map.velox_boot_paths = paths
    config.map.velox_boot_names = names
    config.map.velox_boot_argc = argc
    config.map.velox_boot_argv = argv
end

hooks.add("postinit", "bcfg_load", function()
    bcfg.reload()
end)

return bcfg