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

Vec3 = Class(function(self, x, y, z)
    self.x, self.y, self.z = x or 0, y or 0, z or 0
end)

Vec3.__add = Vector3.__add
Vec3.__sub = Vector3.__sub
Vec3.__mul = Vector3.__mul
Vec3.__div = Vector3.__div
Vec3.Dot = Vector3.Dot
Vec3.Cross = Vector3.Cross
Vec3.__tostring = Vector3.__tostring
Vec3.__eq = Vector3.__eq

Vec3.DistSq = Vector3.DistSq
Vec3.Dist = Vector3.Dist
Vec3.LengthSq = Vector3.LengthSq
Vec3.Length = Vector3.Length
Vec3.Normalize = Vector3.Normalize
Vec3.GetNormalized = Vector3.GetNormalized
Vec3.GetNormalizedAndLength = Vector3.GetNormalizedAndLength
Vec3.Get = Vector3.Get

function Vec3:__unm()
    return Vec3(-self.x, -self.y, -self.z)
end

MakeVecCtor(Vec3)

local swizzlepattern = "[rgbstpxyz]+"

function Vec3:__index(k)
    local val = rawget(self, k)
    if val ~= nil then
        return val
    end
    if #k > 3 or not isswizzle(k, swizzlepattern) then
        return getmetatable(self)[k]
    end
    return GetSwizzle(self, k)
end

function Vec3:__newindex(k, v)
    local val = rawget(self, k)
    if val ~= nil then
        return rawset(self, k, v)
    end
    if #k > 3 or not isswizzle(k, swizzlepattern) then
        return rawset(self, k, v)
    end

    return SetSwizzle(self, k, v)
end

function Vec3:IsVec3()
    return true
end

function IsVec3(obj)
    if not obj or type(obj) ~= "table" or not obj.IsVec3 then
        return false
    end
    return true
end