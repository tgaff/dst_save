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

local cpx, cpy, cpz

local _SetCameraPos = Sim.SetCameraPos
function Sim:SetCameraPos(x, y, z, ...)
    cpx, cpy, cpz = x, y, z
    return _SetCameraPos(self, x, y, z, ...)
end

local cdx, cdy, cdz

local _SetCameraDir = Sim.SetCameraDir
function Sim:SetCameraDir(x, y, z, ...)
    cdx, cdy, cdz = x, y, z
    return _SetCameraDir(self, x, y, z, ...)
end

local cux, cuy, cuz

local _SetCameraUp = Sim.SetCameraUp
function Sim:SetCameraUp(x, y, z, ...)
    cux, cuy, cuz = x, y, z
    return _SetCameraUp(self, x, y, z, ...)
end

local cfov

local _SetCameraFOV = Sim.SetCameraFOV
function Sim:SetCameraFOV(fov, ...)
    cfov = fov
    return _SetCameraFOV(self, fov, ...)
end

local lpx, lpy, lpz, ldx, ldy, ldz, lux, luy, luz

local _SetListener = Sim.SetListener
function Sim:SetListener(px, py, pz, dx, dy, dz, yx, uy, uz, ...)
    lpx, lpy, lpz, ldx, ldy, ldz, lux, luy, luz = px, py, pz, dx, dy, dz, yx, uy, uz
    return _SetListener(self, px, py, pz, dx, dy, dz, yx, uy, uz, ...)
end

function Sim:GetCameraPos()
    return cpx, cpy, cpz
end

function Sim:GetCameraDir()
    return cdx, cdy, cdz
end

function Sim:GetCameraUp()
    return cux, cuy, cuz
end

function Sim:GetCameraFov()
    return cfov
end

function Sim:GetListener()
    return lpx, lpy, lpz, ldx, ldy, ldz, lux, luy, luz
end