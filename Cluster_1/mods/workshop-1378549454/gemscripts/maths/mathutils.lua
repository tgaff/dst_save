--[[
Copyright (C) 2018 Zarklord

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

function math.round(num)
    return math.floor(num + 0.5)
end

function math.variance(num1, num2, variance)
    return math.abs(num1 - num2) < variance
end

function math.absmin(...)
    local vals = {...}
    for i, v in ipairs(vals) do
        vals[i] = math.abs(v)
    end
    return math.min(unpack(vals))
end

function math.absmax(...)
    local vals = {...}
    for i, v in ipairs(vals) do
        vals[i] = math.abs(v)
    end
    return math.max(unpack(vals))
end

function math.roundedsin(angle)
    local i, fp = math.modf(math.sin(angle))
    if math.abs(fp) < 0.0000000001 then
        return i
    end
    return i + fp
end

function math.roundedcos(angle)
    local i, fp = math.modf(math.cos(angle))
    if math.abs(fp) < 0.0000000001 then
        return i
    end
    return i + fp
end

math.rsin = math.roundedsin
math.rcos = math.roundedcos

function math.rotate(x, z, angle)
    local cos = math.rcos(angle)
    local sin = math.rsin(-angle)
    return (x * cos) + (z * sin), -(x * sin) + (z * cos)
end

function math.precision(flt, precision)
    return tonumber(string.format("%."..precision.."f", flt))
end