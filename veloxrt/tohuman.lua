local function tohuman(n, bin, labels, places)
    places = places or 1
    local div = bin and 1024 or 1000
    local i = 1
    while n >= div do
        n = n / div
        i = i + 1
        if not labels[i] then i = #labels break end
    end
    if (i == 1) then
        return string.format("%d%s", n, labels[1])
    end
    return string.format("%."..places.."f%s", n, labels[i])
end

return tohuman