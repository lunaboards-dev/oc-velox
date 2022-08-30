local parser = require("argparse")("make-velx")
local lfs = require("lfs")
local lzss = require("lzss")
local packstr = "<c5BBBBc4I3I3I3I4"

parser:argument("code", "Code for the main section")
parser:option("-A --archive", "Path to archive")
parser:option("--archive-type", "Archive type."):default "cpio"
parser:option("--security", "Path to security section contents")
parser:option("--os", "Path to OS specific section")
parser:option("--osid", "OS ID"):default("7F")
parser:flag("-z --compress", "Compress code section.")
parser:option("-O --out", "Output file"):default("out.velx")
local args = parser:parse()
local fout = assert(io.open(args.out, "wb"))

--[[
struct velx_header {
    char magic[5];
    uint8_t file_version;
    uint8_t compression;
    uint8_t lua_version;
    uint8_t os_id;
    char arctype[4];
    uint24_t program_size;
    uint24_t osdep_section;
    uint24_t signature_size;
    uint32_t archive_size;
}
]]

local psize, osize, ssize, asize = lfs.attributes(args.code, "size")
osize = args.os and lfs.attributes(args.os, "size") or 0
ssize = args.security and lfs.attributes(args.security, "size") or 0
asize = args.archive and lfs.attributes(args.archive, "size") or 0
fout:write(packstr:pack("\27VelX", 1, args.compress and 1, 0x53, tonumber(args.osid, 16), args.archive and args.archive_type or "", psize, osize, ssize, asize))
local function copy_file(path, compress)
    if not path then return end
    local h = assert(io.open(path, "rb"))
    local d = h:read "*a"
    if compress then
        d = lzss.compress(d)
    end
    fout:write(d)
    h:close()
end
copy_file(args.code, args.compress)
copy_file(args.os)
copy_file(args.security)
copy_file(args.archive)
fout:close()