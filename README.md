# VELX Loader
A simple bootloader for OC that runs a VELX file.

## Repo contents
* `velx-loader`: The actual BIOS
* `veloxrt`: The VeloxRT runtime
* `velx-stub`: A way to boot several different kernels from veloxrt
* `make-velx`: A way to make your own VELX files.

## Boot process
Boot process is super simple:
1. Find root drive from EEPROM.
2. Search for a .velox directory
    * If found, try to load veloxrt.velx
    * If not, continue.
3. Search for init.velx
    * If not found, continue.
4. Load init.lua
    * If not found, continue.
5. Search next drive, repeat from step 2.
