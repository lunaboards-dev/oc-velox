do
    local bstr = "VeloxRT v1.0"
    local gpu = _VELX.gpu
    gpu.setForeground(0)
    gpu.setBackground(0xFFFFFF)
    local w, h = gpu.getViewport()
    gpu.fill(1, 1, w, 1, " ")
    gpu.set((w/2)-(#bstr//2), 1, bstr)
    gpu.setForeground(0xFFFFFF)
    gpu.setBackground(0)
    _VELX.print("Loading VeloxRT...")
end
