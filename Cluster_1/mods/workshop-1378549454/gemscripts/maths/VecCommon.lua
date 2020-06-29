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

function MakeVecCtor(class)
    local _ctor = class._ctor
    function class._ctor(self, ...)
        local vecargs = {}
        local args = {...}
        if #args == 1 and type(args[1]) == "number" then
            for i = 1, GetVecSize(self) do
                table.insert(vecargs, args[1])
            end
        else
            for i, v in ipairs(args) do
                if type(v) == "number" then
                    table.insert(vecargs, v)
                elseif IsVec(v) then
                    for i1, v1 in ipairs({v:Get()}) do
                        table.insert(vecargs, v1)
                    end
                end
            end
        end
        _ctor(self, unpack(vecargs))
    end
end

local swizzlesets = {
    "[xyzw]+",
    "[rgba]+",
    "[stpq]+",
}

local swizzlepattern = "([rgbastpqxyzw])"
local swizzleconvert = {
    r = "x",
    g = "y",
    b = "z",
    a = "w",
    s = "x",
    t = "y",
    p = "z",
    q = "w",
    x = "x",
    y = "y",
    z = "z",
    w = "w",
}

function GetSwizzle(t, k)
    local swizzlesize = #k
    local swizzle = validateswizzle(k, swizzlesets, swizzlepattern, swizzleconvert)
    if not swizzle then return end

    if swizzlesize == 1 then
        return rawget(t, swizzle:sub(1,1))
    elseif swizzlesize == 2 then
        return Vec2(rawget(t, swizzle:sub(1,1)), rawget(t, swizzle:sub(2,2)))
    elseif swizzlesize == 3 then
        return Vec3(rawget(t, swizzle:sub(1,1)), rawget(t, swizzle:sub(2,2)), rawget(t, swizzle:sub(3,3)))
    elseif swizzlesize == 4 then
        return Vec4(rawget(t, swizzle:sub(1,1)), rawget(t, swizzle:sub(2,2)), rawget(t, swizzle:sub(3,3)), rawget(t, swizzle:sub(4,4)))
    end
end

function SetSwizzle(t, k, v)
    local swizzlesize = #k
    local swizzle = validateswizzle(k, swizzlesets, swizzlepattern, swizzleconvert)
    if not swizzle or has_duplicate_chars(swizzle) then return end

    if swizzlesize == 1 then
        rawset(t, swizzle:sub(1,1), v)
    elseif swizzlesize == 2 and IsVec2(v) then
        rawset(t, swizzle:sub(1,1), v.x)
        rawset(t, swizzle:sub(2,2), v.y)
    elseif swizzlesize == 3 and IsVec3(v) then
        rawset(t, swizzle:sub(1,1), v.x)
        rawset(t, swizzle:sub(2,2), v.y)
        rawset(t, swizzle:sub(3,3), v.z)
    elseif swizzlesize == 4 and IsVec4(v) then
        rawset(t, swizzle:sub(1,1), v.x)
        rawset(t, swizzle:sub(2,2), v.y)
        rawset(t, swizzle:sub(3,3), v.z)
        rawset(t, swizzle:sub(4,4), v.w)
    end
end

function IsVec(obj)
    return IsVec2(obj) or IsVec3(obj) or IsVec4(obj)
end

function GetVecSize(obj)
    if IsVec2(obj) then
        return 2
    elseif IsVec3(obj) then
        return 3
    elseif IsVec4(obj) then
        return 4
    end
end