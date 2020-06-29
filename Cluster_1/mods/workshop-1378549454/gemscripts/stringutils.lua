--[[
Copyright (C) 2020 Zarklord

This file is part of Gem Core.

The source code of this program is shared under the RECEX
SHARED SOURCE LICENSE (version 1.0).
The source code is shared for referrence and academic purposes
with the hope that people can read and learn from it. This is not
Free and Open Source software, and code is not redistributable
without permission of the author. Read the RECEX SHARED
SOURCE LICENSE for details
The source codes does not come with any warranty including
the implied warranty of merchandise.
You should have received a copy of the RECEX SHARED SOURCE
LICENSE in the form of a LICENSE file in the root of the source
directory. If not, please refer to
<https://raw.githubusercontent.com/Recex/Licenses/master/SharedSourceLicense/LICENSE.txt>
]]

function has_duplicate_chars(str)
    local charsfound = {}
    for c in string.gmatch(str, "%w") do
        if charsfound[c] then
            return true
        end
        charsfound[c] = true
    end
    return false
end

function validateswizzle(k, sets, pattern, convert)
    local swizzle_s, swizzle_e
    for i, v in ipairs(sets) do
        swizzle_s, swizzle_e = k:find(v)
        if swizzle_s then break end
    end
    if swizzle_s ~= 1 and swizzle_e ~= #k then
        return
    end
    return k:gsub(pattern, convert)
end

function isswizzle(k, swizzletest)
    local swizzle_s, swizzle_e = k:find(swizzletest)
    return swizzle_s == 1 and swizzle_e == #k
end