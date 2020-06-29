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

VectorLine = Class(function(self, s, e, x, z)
    if type(s) == "table" then
        self.s = s
        self.e = e or Vector3()
    elseif type(s) == "number" then
        self.s = Vector3(s, nil, e)
        self.e = Vector3(x, nil, z)
    else
        self.s = Vector3()
        self.e = Vector3()
    end
end)

function VectorLine:__add(rhs)
    if rhs.IsLine then
        return VectorLine(self.s + rhs.s, self.e + rhs.e)
    end
    return VectorLine(self.s + rhs, self.e + rhs)
end

function VectorLine:__sub(rhs)
    if rhs.IsLine then
        return VectorLine(self.s - rhs.s, self.e - rhs.e)
    end
    return VectorLine(self.s - rhs, self.e - rhs)
end

function VectorLine:__mul(rhs)
    return VectorLine(self.s * rhs, self.e * rhs)
end

function VectorLine:__div(rhs)
    return VectorLine(self.s / rhs, self.e / rhs)
end

function VectorLine:__unm()
    return VectorLine(self.e, self.s)
end

function VectorLine:__tostring()
    return "("..tostring(self.s)..", "..tostring(self.e)..") Vector: "..tostring(self:GetVector())
end

function VectorLine:__eq(rhs)
    return self.s == rhs.s and self.e == rhs.e
end

function VectorLine:InvertSelf()
    local _ = self.s
    self.s = self.e
    self.e = _
    return self
end

function VectorLine:GetVector()
    return self.e - self.s
end

function VectorLine:RHNormal()
    local vec = self:GetVector()
    return Vector3(-vec.z, nil, vec.x)
end

function VectorLine:LHNormal()
    local vec = self:GetVector()
    return Vector3(vec.z, nil, -vec.x)
end

function VectorLine:NormalizedRHNormal()
    return self:RHNormal():Normalize()
end

function VectorLine:NormalizedLHNormal()
    return self:LHNormal():Normalize()
end

function VectorLine:IsLine()
    return true
end