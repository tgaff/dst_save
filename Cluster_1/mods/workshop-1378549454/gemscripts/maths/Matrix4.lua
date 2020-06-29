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

--dst uses column major order on the C side, but I'm to lazy to swap it, and as long as this never interfaces with the C side, its never a problem.
Matrix4 = Class(function(self)
    self.m00, self.m01, self.m02, self.m03 = 0, 0, 0, 0
    self.m10, self.m11, self.m12, self.m13 = 0, 0, 0, 0
    self.m20, self.m21, self.m22, self.m23 = 0, 0, 0, 0
    self.m30, self.m31, self.m32, self.m33 = 0, 0, 0, 0
end)

function Matrix4:SetIdentity()
    self.m00, self.m01, self.m02, self.m03 = 1, 0, 0, 0
    self.m10, self.m11, self.m12, self.m13 = 0, 1, 0, 0
    self.m20, self.m21, self.m22, self.m23 = 0, 0, 1, 0
    self.m30, self.m31, self.m32, self.m33 = 0, 0, 0, 1
end

function Matrix4:SetZero()
    self.m00, self.m01, self.m02, self.m03 = 0, 0, 0, 0
    self.m10, self.m11, self.m12, self.m13 = 0, 0, 0, 0
    self.m20, self.m21, self.m22, self.m23 = 0, 0, 0, 0
    self.m30, self.m31, self.m32, self.m33 = 0, 0, 0, 0
end

function Matrix4:__add(rhs)
    local dest = Matrix4()
    dest.m00, dest.m01, dest.m02, dest.m03 = self.m00 + rhs.m00, self.m01 + rhs.m01, self.m02 + rhs.m02, self.m03 + rhs.m03
    dest.m10, dest.m11, dest.m12, dest.m13 = self.m00 + rhs.m00, self.m01 + rhs.m01, self.m02 + rhs.m02, self.m03 + rhs.m03
    dest.m20, dest.m21, dest.m22, dest.m23 = self.m00 + rhs.m00, self.m01 + rhs.m01, self.m02 + rhs.m02, self.m03 + rhs.m03
    dest.m30, dest.m31, dest.m32, dest.m33 = self.m00 + rhs.m00, self.m01 + rhs.m01, self.m02 + rhs.m02, self.m03 + rhs.m03
    return dest
end

function Matrix4:__unm()
    local dest = Matrix4()
    dest.m00, dest.m01, dest.m02, dest.m03 = -self.m00, -self.m01, -self.m02, -self.m03
    dest.m10, dest.m11, dest.m12, dest.m13 = -self.m10, -self.m11, -self.m12, -self.m13
    dest.m20, dest.m21, dest.m22, dest.m23 = -self.m20, -self.m21, -self.m22, -self.m23
    dest.m30, dest.m31, dest.m32, dest.m33 = -self.m30, -self.m31, -self.m32, -self.m33
    return dest
end

function Matrix4:__sub(rhs)
    local dest = Matrix4()
    dest.m00, dest.m01, dest.m02, dest.m03 = self.m00 - rhs.m00, self.m01 - rhs.m01, self.m02 - rhs.m02, self.m03 - rhs.m03
    dest.m10, dest.m11, dest.m12, dest.m13 = self.m00 - rhs.m00, self.m01 - rhs.m01, self.m02 - rhs.m02, self.m03 - rhs.m03
    dest.m20, dest.m21, dest.m22, dest.m23 = self.m00 - rhs.m00, self.m01 - rhs.m01, self.m02 - rhs.m02, self.m03 - rhs.m03
    dest.m30, dest.m31, dest.m32, dest.m33 = self.m00 - rhs.m00, self.m01 - rhs.m01, self.m02 - rhs.m02, self.m03 - rhs.m03
    return dest
end

function Matrix4:__mul(rhs)
    if IsVec4(rhs) then
        return self:Transform(rhs)
    end
    local dest = Matrix4()
    dest.m00 = self.m00 * rhs.m00 + self.m10 * rhs.m01 + self.m20 * rhs.m02 + self.m30 * rhs.m03
    dest.m01 = self.m01 * rhs.m00 + self.m11 * rhs.m01 + self.m21 * rhs.m02 + self.m31 * rhs.m03
    dest.m02 = self.m02 * rhs.m00 + self.m12 * rhs.m01 + self.m22 * rhs.m02 + self.m32 * rhs.m03
    dest.m03 = self.m03 * rhs.m00 + self.m13 * rhs.m01 + self.m23 * rhs.m02 + self.m33 * rhs.m03
    dest.m10 = self.m00 * rhs.m10 + self.m10 * rhs.m11 + self.m20 * rhs.m12 + self.m30 * rhs.m13
    dest.m11 = self.m01 * rhs.m10 + self.m11 * rhs.m11 + self.m21 * rhs.m12 + self.m31 * rhs.m13
    dest.m12 = self.m02 * rhs.m10 + self.m12 * rhs.m11 + self.m22 * rhs.m12 + self.m32 * rhs.m13
    dest.m13 = self.m03 * rhs.m10 + self.m13 * rhs.m11 + self.m23 * rhs.m12 + self.m33 * rhs.m13
    dest.m20 = self.m00 * rhs.m20 + self.m10 * rhs.m21 + self.m20 * rhs.m22 + self.m30 * rhs.m23
    dest.m21 = self.m01 * rhs.m20 + self.m11 * rhs.m21 + self.m21 * rhs.m22 + self.m31 * rhs.m23
    dest.m22 = self.m02 * rhs.m20 + self.m12 * rhs.m21 + self.m22 * rhs.m22 + self.m32 * rhs.m23
    dest.m23 = self.m03 * rhs.m20 + self.m13 * rhs.m21 + self.m23 * rhs.m22 + self.m33 * rhs.m23
    dest.m30 = self.m00 * rhs.m30 + self.m10 * rhs.m31 + self.m20 * rhs.m32 + self.m30 * rhs.m33
    dest.m31 = self.m01 * rhs.m30 + self.m11 * rhs.m31 + self.m21 * rhs.m32 + self.m31 * rhs.m33
    dest.m32 = self.m02 * rhs.m30 + self.m12 * rhs.m31 + self.m22 * rhs.m32 + self.m32 * rhs.m33
    dest.m33 = self.m03 * rhs.m30 + self.m13 * rhs.m31 + self.m23 * rhs.m32 + self.m33 * rhs.m33
    return dest
end

function Matrix4:Transform(vec)
    local dest = Vec4()
    dest.x = self.m00 * vec.x + self.m10 * vec.y + self.m20 * vec.z + self.m30 * vec.w
    dest.y = self.m01 * vec.x + self.m11 * vec.y + self.m21 * vec.z + self.m31 * vec.w
    dest.z = self.m02 * vec.x + self.m12 * vec.y + self.m22 * vec.z + self.m32 * vec.w
    dest.w = self.m03 * vec.x + self.m13 * vec.y + self.m23 * vec.z + self.m33 * vec.w
    return dest
end

function Matrix4:Scale(vec)
    self.m00, self.m01, self.m02, self.m03 = self.m00 * vec.x, self.m01 * vec.x, self.m02 * vec.x, self.m03 * vec.x
    self.m10, self.m11, self.m12, self.m13 = self.m10 * vec.y, self.m11 * vec.y, self.m12 * vec.y, self.m13 * vec.y
    self.m20, self.m21, self.m22, self.m23 = self.m20 * vec.z, self.m21 * vec.z, self.m22 * vec.z, self.m23 * vec.z
end

function Matrix4:Rotate(angle, axis)
    local c = math.cos(angle)
    local s = math.sin(angle)
    local oneminusc = 1.0 - c
    local xy = axis.x*axis.y
    local yz = axis.y*axis.z
    local xz = axis.x*axis.z
    local xs = axis.x*s
    local ys = axis.y*s
    local zs = axis.z*s

    local f00 = axis.x*axis.x*oneminusc+c
    local f01 = xy*oneminusc+zs
    local f02 = xz*oneminusc-ys
    --n[3] not used
    local f10 = xy*oneminusc-zs
    local f11 = axis.y*axis.y*oneminusc+c
    local f12 = yz*oneminusc+xs
    --n[7] not used
    local f20 = xz*oneminusc+ys
    local f21 = yz*oneminusc-xs
    local f22 = axis.z*axis.z*oneminusc+c

    local t00 = self.m00 * f00 + self.m10 * f01 + self.m20 * f02
    local t01 = self.m01 * f00 + self.m11 * f01 + self.m21 * f02
    local t02 = self.m02 * f00 + self.m12 * f01 + self.m22 * f02
    local t03 = self.m03 * f00 + self.m13 * f01 + self.m23 * f02
    local t10 = self.m00 * f10 + self.m10 * f11 + self.m20 * f12
    local t11 = self.m01 * f10 + self.m11 * f11 + self.m21 * f12
    local t12 = self.m02 * f10 + self.m12 * f11 + self.m22 * f12
    local t13 = self.m03 * f10 + self.m13 * f11 + self.m23 * f12
    self.m20 = self.m00 * f20 + self.m10 * f21 + self.m20 * f22
    self.m21 = self.m01 * f20 + self.m11 * f21 + self.m21 * f22
    self.m22 = self.m02 * f20 + self.m12 * f21 + self.m22 * f22
    self.m23 = self.m03 * f20 + self.m13 * f21 + self.m23 * f22
    self.m00 = t00
    self.m01 = t01
    self.m02 = t02
    self.m03 = t03
    self.m10 = t10
    self.m11 = t11
    self.m12 = t12
    self.m13 = t13
end

function Matrix4:Translate(vec)
    if IsVec2(vec) then
        self.m30 = self.m30 + (self.m00 * vec.x + self.m10 * vec.y)
        self.m31 = self.m31 + (self.m01 * vec.x + self.m11 * vec.y)
        self.m32 = self.m32 + (self.m02 * vec.x + self.m12 * vec.y)
        self.m33 = self.m33 + (self.m03 * vec.x + self.m13 * vec.y)
    elseif IsVec3(vec) then
        self.m30 = self.m30 + (self.m00 * vec.x + self.m10 * vec.y + self.m20 * vec.z)
        self.m31 = self.m31 + (self.m01 * vec.x + self.m11 * vec.y + self.m21 * vec.z)
        self.m32 = self.m32 + (self.m02 * vec.x + self.m12 * vec.y + self.m22 * vec.z)
        self.m33 = self.m33 + (self.m03 * vec.x + self.m13 * vec.y + self.m23 * vec.z)
    end
end

function Matrix4:Transpose()
    local dest = Matrix4()
    dest.m00, dest.m01, dest.m02, dest.m03 = self.m00, self.m10, self.m20, self.m30
    dest.m10, dest.m11, dest.m12, dest.m13 = self.m01, self.m11, self.m21, self.m31
    dest.m20, dest.m21, dest.m22, dest.m23 = self.m02, self.m12, self.m22, self.m32
    dest.m30, dest.m31, dest.m32, dest.m33 = self.m03, self.m13, self.m23, self.m33
    return dest
end

function Matrix4:Determinant()
    local f = self.m00 * ((self.m11 * self.m22 * self.m33 + self.m12 * self.m23 * self.m31 + self.m13 * self.m21 * self.m32)
        - self.m13 * self.m22 * self.m31 - self.m11 * self.m23 * self.m32 - self.m12 * self.m21 * self.m33)
    f = f - (self.m01 * ((self.m10 * self.m22 * self.m33 + self.m12 * self.m23 * self.m30 + self.m13 * self.m20 * self.m32)
        - self.m13 * self.m22 * self.m30 - self.m10 * self.m23 * self.m32 - self.m12 * self.m20 * self.m33))
    f = f + (self.m02 * ((self.m10 * self.m21 * self.m33 + self.m11 * self.m23 * self.m30 + self.m13 * self.m20 * self.m31)
        - self.m13 * self.m21 * self.m30 - self.m10 * self.m23 * self.m31 - self.m11 * self.m20 * self.m33))
    f = f - (self.m03 * ((self.m10 * self.m21 * self.m32 + self.m11 * self.m22 * self.m30 + self.m12 * self.m20 * self.m31)
        - self.m12 * self.m21 * self.m30 - self.m10 * self.m22 * self.m31 - self.m11 * self.m20 * self.m32))
    return f
end

local function Determinant3x3(t00, t01, t02, t10, t11, t12, t20, t21, t22)
    return t00 * (t11 * t22 - t12 * t21) + t01 * (t12 * t20 - t10 * t22) + t02 * (t10 * t21 - t11 * t20)
end

function Matrix4:Invert()
    local determinant = self:Determinant()

    if determinant ~= 0 then
        --[[
        m00 m01 m02 m03
        m10 m11 m12 m13
        m20 m21 m22 m23
        m30 m31 m32 m33
        --]]
        local dest = Matrix4()
        local determinant_inv = 1/determinant

        --first row
        local t00 =  Determinant3x3(self.m11, self.m12, self.m13, self.m21, self.m22, self.m23, self.m31, self.m32, self.m33)
        local t01 = -Determinant3x3(self.m10, self.m12, self.m13, self.m20, self.m22, self.m23, self.m30, self.m32, self.m33)
        local t02 =  Determinant3x3(self.m10, self.m11, self.m13, self.m20, self.m21, self.m23, self.m30, self.m31, self.m33)
        local t03 = -Determinant3x3(self.m10, self.m11, self.m12, self.m20, self.m21, self.m22, self.m30, self.m31, self.m32)
        --second row
        local t10 = -Determinant3x3(self.m01, self.m02, self.m03, self.m21, self.m22, self.m23, self.m31, self.m32, self.m33)
        local t11 =  Determinant3x3(self.m00, self.m02, self.m03, self.m20, self.m22, self.m23, self.m30, self.m32, self.m33)
        local t12 = -Determinant3x3(self.m00, self.m01, self.m03, self.m20, self.m21, self.m23, self.m30, self.m31, self.m33)
        local t13 =  Determinant3x3(self.m00, self.m01, self.m02, self.m20, self.m21, self.m22, self.m30, self.m31, self.m32)
        --third row
        local t20 =  Determinant3x3(self.m01, self.m02, self.m03, self.m11, self.m12, self.m13, self.m31, self.m32, self.m33)
        local t21 = -Determinant3x3(self.m00, self.m02, self.m03, self.m10, self.m12, self.m13, self.m30, self.m32, self.m33)
        local t22 =  Determinant3x3(self.m00, self.m01, self.m03, self.m10, self.m11, self.m13, self.m30, self.m31, self.m33)
        local t23 = -Determinant3x3(self.m00, self.m01, self.m02, self.m10, self.m11, self.m12, self.m30, self.m31, self.m32)
        --fourth row
        local t30 = -Determinant3x3(self.m01, self.m02, self.m03, self.m11, self.m12, self.m13, self.m21, self.m22, self.m23)
        local t31 =  Determinant3x3(self.m00, self.m02, self.m03, self.m10, self.m12, self.m13, self.m20, self.m22, self.m23)
        local t32 = -Determinant3x3(self.m00, self.m01, self.m03, self.m10, self.m11, self.m13, self.m20, self.m21, self.m23)
        local t33 =  Determinant3x3(self.m00, self.m01, self.m02, self.m10, self.m11, self.m12, self.m20, self.m21, self.m22)

        --transpose and divide by the determinant
        dest.m00 = t00*determinant_inv
        dest.m11 = t11*determinant_inv
        dest.m22 = t22*determinant_inv
        dest.m33 = t33*determinant_inv
        dest.m01 = t10*determinant_inv
        dest.m10 = t01*determinant_inv
        dest.m20 = t02*determinant_inv
        dest.m02 = t20*determinant_inv
        dest.m12 = t21*determinant_inv
        dest.m21 = t12*determinant_inv
        dest.m03 = t30*determinant_inv
        dest.m30 = t03*determinant_inv
        dest.m13 = t31*determinant_inv
        dest.m31 = t13*determinant_inv
        dest.m32 = t23*determinant_inv
        dest.m23 = t32*determinant_inv
        return dest
    end
    return nil
end

function Matrix4:IsMatrix4()
    return true
end

function IsMatrix4(obj)
    if not obj or type(obj) ~= "table" or not type.IsMatrix4 then
        return false
    end
    return true
end