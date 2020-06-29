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

Vec4 = Class(function(self, x, y, z, w)
    self.x, self.y, self.z, self.w = x or 0, y or 0, z or 0, w or 0
end)

function Vec4:__add(rhs)
    return Vec4(self.x + rhs.x, self.y + rhs.y, self.z + rhs.z, self.w + rhs.w)
end

function Vec4:__sub(rhs)
    return Vec4(self.x - rhs.x, self.y - rhs.y, self.z - rhs.z, self.w - rhs.w)
end

function Vec4:__unm()
    return Vec4(-self.x, -self.y, -self.z, -self.w)
end

function Vec4:__mul(rhs)
    return Vec4(self.x * rhs, self.y * rhs, self.z * rhs, self.w * rhs)
end

function Vec4:__div(rhs)
    return Vec4(self.x / rhs, self.y / rhs, self.z / rhs, self.w / rhs)
end

function Vec4:Dot(rhs)
    return self.x * rhs.x + self.y * rhs.y + self.z * rhs.z + self.w * rhs.w
end

function Vec4:__tostring()
    return string.format("(%2.2f, %2.2f, %2.2f, %2.2f)", self.x, self.y, self.z, self.w)
end

function Vec4:__eq(rhs)
    return self.x == rhs.x and self.y == rhs.y and self.z == rhs.z and self.w == rhs.w
end

function Vec4:DistSq(other)
    return (self.x - other.x)*(self.x - other.x) + (self.y - other.y)*(self.y - other.y) + (self.z - other.z)*(self.z - other.z) + (self.w - other.w)
end

function Vec4:Dist(other)
    return math.sqrt(self:DistSq(other))
end

function Vec4:LengthSq()
    return self.x*self.x + self.y*self.y + self.z*self.z + self.w*self.w
end

function Vec4:Length()
    return math.sqrt(self:LengthSq())
end

function Vec4:Normalize()
    local len = self:Length()
    if len > 0 then
        self.x = self.x / len
        self.y = self.y / len
        self.z = self.z / len
        self.w = self.w / len
    end
    return self
end

function Vec4:GetNormalized()
    return self / self:Length()
end

function Vec4:GetNormalizedAndLength()
    local len = self:Length()
    return (len > 0 and self / len) or self, len
end

function Vec4:Get()
    return self.x, self.y, self.z, self.w
end

MakeVecCtor(Vec4)

local swizzlepattern = "[rgbastpqxyzw]+"

function Vec4:__index(k)
    local val = rawget(self, k)
    if val ~= nil then
        return val
    end
    if #k > 4 or not isswizzle(k, swizzlepattern) then
        return getmetatable(self)[k]
    end
    return GetSwizzle(self, k)
end

function Vec4:__newindex(k, v)
    local val = rawget(self, k)
    if val ~= nil then
        return rawset(self, k, v)
    end
    if #k > 4 or not isswizzle(k, swizzlepattern) then
        return rawset(self, k, v)
    end

    return SetSwizzle(self, k, v)
end

function Vec4:IsVec4()
    return true
end

function IsVec4(obj)
    if not obj or type(obj) ~= "table" or not obj.IsVec4 then
        return false
    end
    return true
end