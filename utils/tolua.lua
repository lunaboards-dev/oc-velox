local is = io.stdin:read("*a")
local function tostr(s) return s:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\n", "\\n"):gsub("\r", "\\r") end
io.stdout:write(string.format("return \"%s\"\n", tostr(is)))