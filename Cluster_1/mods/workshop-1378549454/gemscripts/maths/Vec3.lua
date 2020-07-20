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

function Vec3:__add(rhs)
    return Vec3(self.x + rhs.x, self.y + rhs.y, self.z + rhs.z)
end

function Vec3:__sub(rhs)
    return Vec3(self.x - rhs.x, self.y - rhs.y, self.z - rhs.z)
end

function Vec3:__mul(rhs)
    return Vec3(self.x * rhs.x, self.y * rhs.y, self.z * rhs.z)
end

function Vec3:__div(rhs)
    return Vec3(self.x / rhs.x, self.y / rhs.y, self.z / rhs.z)
end

function Vec3:Dot(rhs)
    return self.x * rhs.x + self.y * rhs.y + self.z * rhs.z
end

function Vec3:Cross(rhs)
    return Vec3(self.y * rhs.z - self.z * rhs.y,
                self.z * rhs.x - self.x * rhs.z,
                self.x * rhs.y - self.y * rhs.x)
end

Vec3.__tostring = Vector3.__tostring
--we want comparison to work between Vec3 and Vector3
Vec3.__eq = Vector3.__eq

function Vec3:DistSq(other)
    return (self.x - other.x)*(self.x - other.x) + (self.y - other.y)*(self.y - other.y) + (self.z - other.z)*(self.z - other.z)
end

function Vec3:Dist(other)
    return math.sqrt(self:DistSq(other))
end

function Vec3:LengthSq()
    return self.x*self.x + self.y*self.y + self.z*self.z
end

function Vec3:Length()
    return math.sqrt(self:LengthSq())
end

function Vec3:Normalize()
    local len = self:Length()
    if len > 0 then
        self.x = self.x / len
        self.y = self.y / len
        self.z = self.z / len
    end
    return self
end

function Vec3:GetNormalized()
    return self / self:Length()
end

function Vec3:GetNormalizedAndLength()
    local len = self:Length()
    return (len > 0 and self / len) or self, len
end

function Vec3:Get()
    return self.x, self.y, self.z
end

function Vec3:__unm()
    return Vec3(-self.x, -self.y, -self.z)
end

function Vector3:__unm()
    return Vector3(-self.x, -self.y, -self.z)
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