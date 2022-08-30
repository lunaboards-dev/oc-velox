local hooks = require "hooks"
local gpu = {}

local colors = {}

function gpu.backup_colors(g)
    colors[g.address] = {}
    for i=1, 16 do
        colors[g.address][i] = g.getPaletteColor(i)
    end
end

function gpu.restore_colors(g)
    if not colors[g.address] then return end
    for i=1, 16 do
        g.setPaletteColor(i, colors[g.address][i])
    end
end

hooks.add("init", "gpubackup", function()
    for comp in component.list("gpu") do
        local p = component.proxy(comp)
        if (p.getDepth() > 1) then
            gpu.backup_colors(p)
        end
    end
end)

hooks.add("preboot", "gpurestore", function()
    for comp in component.list("gpu") do
        local p = component.proxy(comp)
        if (p.getDepth() > 1) then
            gpu.restore_colors(p)
        end
    end
end)

return gpu