-- Based on https://github.com/mimetic/tar.lua/tree/master
-- Modified (heavily) to work with Love2D Data objects
-- by Simon Bordeyne for @balamod
-- License: MIT

local ffi = require("ffi")
local logging = require("logging")
local logger = logging.getLogger('tar')
local math = require('math')

local tar = {}
local blocksize = 512
local byte = string.byte


--- Strip the path off a path+filename.
-- @param pathname string: A path+name, such as "/a/b/c"
-- or "\a\b\c".
-- @return string: The filename without its path, such as "c".
local function base_name(pathname)
   assert(type(pathname) == "string")

   local base = pathname:match(".*[/\\]([^/\\]*)")
   return base or pathname
end

--- Strip the name off a path+filename.
-- @param pathname string: A path+name, such as "/a/b/c".
-- @return string: The filename without its path, such as "/a/b/".
-- For entries such as "/a/b/", "/a/" is returned. If there are
-- no directory separators in input, "" is returned.
local function dir_name(pathname)
   assert(type(pathname) == "string")

   return (pathname:gsub("/*$", ""):match("(.*/)[^/]*")) or ""
end

local function strip_base_dir(pathname)
   return pathname:gsub("^[^/]*/", "")
end

-- trim5 from http://lua-users.org/wiki/StringTrim
local function trim(s)
  return s:match'^%s*(.*%S)' or ''
end


local function get_typeflag(flag)
    if flag == "0" or flag == "\0" then return "file"
    elseif flag == "1" then return "link"
    elseif flag == "2" then return "symlink" -- "reserved" in POSIX, "symlink" in GNU
    elseif flag == "3" then return "character"
    elseif flag == "4" then return "block"
    elseif flag == "5" then return "directory"
    elseif flag == "6" then return "fifo"
    elseif flag == "7" then return "contiguous" -- "reserved" in POSIX, "contiguous" in GNU
    elseif flag == "x" then return "next file"
    elseif flag == "g" then return "global extended header"
    elseif flag == "L" then return "long name"
    elseif flag == "K" then return "long link name"
    end
    return "unknown"
end

local function octal_to_number(octal)
    local exp = 0
    local number = 0
    octal = trim(octal)
    for i = #octal,1,-1 do
        local digit = tonumber(octal:sub(i,i))
        if not digit then break end
        number = number + (digit * 8^exp)
        exp = exp + 1
    end
    return number
end

--[[
It is correct that the checksum is the sum of the 512 header
bytes after filling the checksum field itself with spaces.
The checksum is then written as a string giving the *octal*
representation of the checksum. Maybe you forgot to convert
your hand computed sum to octal ??.
]]

local function checksum_header(block)
    local sum = 256
    for i = 1,148 do
        sum = sum + block:byte(i)
    end
    for i = 157,500 do
        sum = sum + block:byte(i)
    end
    return sum
end

local function nullterm(s)
    return s:match("^[^%z]*")
end

local function read_header_block(block)
    local header = {}
    header.name = nullterm(block:sub(1,100))
    header.mode = nullterm(block:sub(101,108))
    header.uid = octal_to_number(nullterm(block:sub(109,116)))
    header.gid = octal_to_number(nullterm(block:sub(117,124)))
    header.size = octal_to_number(nullterm(block:sub(125,136)))
    header.mtime = octal_to_number(nullterm(block:sub(137,148)))
    header.chksum = octal_to_number(nullterm(block:sub(149,156)))
    header.typeflag = get_typeflag(block:sub(157,157))
    header.linkname = nullterm(block:sub(158,257))
    header.magic = block:sub(258,263)
    header.version = block:sub(264,265)
    header.uname = nullterm(block:sub(266,297))
    header.gname = nullterm(block:sub(298,329))
    header.devmajor = octal_to_number(nullterm(block:sub(330,337)))
    header.devminor = octal_to_number(nullterm(block:sub(338,345)))
    header.prefix = block:sub(346,500)
    header.pad = block:sub(501,512)
    if header.magic ~= "ustar " and header.magic ~= "ustar\0" then
        return false, "Invalid header magic "..header.magic
    end
    if header.version ~= "00" and header.version ~= " \0" then
        return false, "Unknown version "..header.version
    end
    if not checksum_header(block) == header.chksum then
        return false, "Failed header checksum"
    end
    return header
end

local function readBlock(data, start, size)
    local uint8Array = {}
    for i=0, size do
        uint8Array[i] = data[start + i]
    end
    assert(#uint8Array == size, "readBlock: size mismatch")
    logger:debug("readBlock: ", #uint8Array)
    local str = ""
    for i=1, #uint8Array do
        str = str .. string.char(uint8Array[i])
    end
    return str
end

function tar.unpack(data)
    -- data is a Data object from love
    local ptr = ffi.cast('uint8_t*', data:getFFIPointer())
    local dataSize = data:getSize()
    local i = -1
    local longName = nil
    local longLinkName = nil
    local unpackedData = {}
    local block = ""
    repeat
        -- iterate by blocks of 512 bytes over the data
        block = readBlock(ptr, i, blocksize)
        local header, err = read_header_block(block)
        if not header then
            logger:error("tar.unpack: ", err)
            break
        end
        -- read entire file that follows header
        i = i + blocksize -- increment by the size of the header
        -- calculate how many bytes to read in total, it's a multiple of blocksize
        local endOfBlock = math.ceil(header.size / blocksize) * blocksize
        -- then read everything into a buffer
        local fileData = readBlock(ptr, i, endOfBlock):sub(1,header.size)
        i = i + endOfBlock
        logger:debug("header: ", header)
        logger:debug("data: ", fileData)
        if header.typeflag == "long name" then
            longName = nullterm(fileData)
        elseif header.typeflag == "long link name" then
            longLinkName = nullterm(fileData)
        else
            if longName then
                header.name = longName
                longName = nil
            end
            if longLinkName then
                header.name = longLinkName
                longLinkName = nil
            end
        end


        if header.typeflag == "directory" or header.typeflag == "file" then
            table.insert(unpackedData, {name = header.name, data = fileData, type=header.typeflag})
        end
    until i >= dataSize or checksum_header(block) <= 256
    logger:debug("unpackedData: ", unpackedData)
    return unpackedData
end

return tar
