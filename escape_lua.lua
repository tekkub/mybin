#! /c/Windows/system32/lua.exe

local file = ...

local f = assert(io.open(file, "r"), "Cannot open file to read")
local infile = f:read("*all")
f:close()

local outfile = infile:gsub("([\128-\255])", function(c) return "\\"..c:byte(); end)

local f = assert(io.open("escaped-"..file, "w"), "Cannot open file to write")
f:write(outfile)
f:close()
