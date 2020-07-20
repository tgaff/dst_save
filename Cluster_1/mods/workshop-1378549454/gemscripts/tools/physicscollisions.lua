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

local TICKTIME
if rawget(_G, "GetTickTime") then
    TICKTIME = GetTickTime()
end

local PhysicsCollisionCallbacksList = {}

local _OnPhysicsCollision = OnPhysicsCollision
--REALLY, why isn't this a vector? or atleast converted to a vector? /shrug
function OnPhysicsCollision(guid1, guid2, world_position_on_a_x, world_position_on_a_y, world_position_on_a_z, world_position_on_b_x, world_position_on_b_y, world_position_on_b_z, world_normal_on_b_x, world_normal_on_b_y, world_normal_on_b_z, lifetime_in_frames, ...)
    _OnPhysicsCollision(guid1, guid2, world_position_on_a_x, world_position_on_a_y, world_position_on_a_z, world_position_on_b_x, world_position_on_b_y, world_position_on_b_z, world_normal_on_b_x, world_normal_on_b_y, world_normal_on_b_z, lifetime_in_frames, ...)
    local i1 = Ents[guid1]
    local i2 = Ents[guid2]

    if PhysicsCollisionCallbacksList[guid1] then
        for k, fn in pairs(PhysicsCollisionCallbacksList[guid1]) do
            fn(i1, i2, world_position_on_a_x, world_position_on_a_y, world_position_on_a_z, world_position_on_b_x, world_position_on_b_y, world_position_on_b_z, world_normal_on_b_x, world_normal_on_b_y, world_normal_on_b_z, lifetime_in_frames, ...)
        end
    end

    if PhysicsCollisionCallbacksList[guid2] then
        for k, fn in pairs(PhysicsCollisionCallbacksList[guid2]) do
            fn(i2, i1, world_position_on_a_x, world_position_on_a_y, world_position_on_a_z, world_position_on_b_x, world_position_on_b_y, world_position_on_b_z, world_normal_on_b_x, world_normal_on_b_y, world_normal_on_b_z, lifetime_in_frames, ...)
        end
    end
end

local _OnRemoveEntity = OnRemoveEntity
function OnRemoveEntity(entityguid)
    PhysicsCollisionCallbacksList[entityguid] = nil
    _OnRemoveEntity(entityguid)
end

function EntityScript:AddPhysicsCallback(src, fn)
    if PhysicsCollisionCallbacksList[self.GUID] == nil then
        PhysicsCollisionCallbacksList[self.GUID] = {}
    end
    PhysicsCollisionCallbacksList[self.GUID][src] = fn
end

function EntityScript:RemovePhysicsCallback(src)
    if PhysicsCollisionCallbacksList[self.GUID] == nil then
        PhysicsCollisionCallbacksList[self.GUID] = {}
    end
    PhysicsCollisionCallbacksList[self.GUID][src] = nil
end

function SpeedToTickSpeed(speed, scale)
    return speed * TICKTIME * (scale or 1)
end

function TickSpeedToSpeed(tickspeed, scale)
    return tickspeed / TICKTIME / (scale or 1)
end

local function GetNextTickPosition(inst, reverse_deg, speedmultiplierx, speedmultiplierz)
    local x, y, z = inst.Transform:GetWorldPosition()

    if speedmultiplierx == nil and speedmultiplierz == nil then
        local is_running = inst.sg and inst.sg:HasStateTag("running")
        speedmultiplierx = is_running and TUNING.WILSON_RUN_SPEED or TUNING.WILSON_WALK_SPEED
        speedmultiplierz = 0
        if inst.components.locomotor then
            speedmultiplierx = is_running and inst.components.locomotor:GetRunSpeed() or inst.components.locomotor:GetWalkSpeed() or speedmultiplierx
        end
    end
    local sx, sy, sz = inst.Transform:GetScale()
    speedmultiplierx = SpeedToTickSpeed(speedmultiplierx or 0, sx)
    speedmultiplierz = SpeedToTickSpeed(speedmultiplierz or 0, sz)

    local deg = math.rad(inst.Transform:GetRotation())

    if reverse_deg then
        deg = -deg
    end

    local xmov, zmov = math.rotate(speedmultiplierx, speedmultiplierz, -deg)

    return (x or 0) + (xmov or 0), (y or 0), (z or 0) + (zmov or 0)
end

local function DoFakePhysicsWallMovement(inst, speed, canmoveto, getmaxxz, dorealmovement, ...)
    local x, y, z = inst.Transform:GetWorldPosition()
    --doing this to support older function calls before the speed table was added.
    local dorealargs
    if type(speed) == "function" then
        dorealargs = {dorealmovement, ...}
        dorealmovement = getmaxxz
        getmaxxz = canmoveto
        canmoveto = speed
        speed = {}
    else
        dorealargs = {...}
        speed = type(speed) == "table" and speed or {}
    end
    local px, py, pz = GetNextTickPosition(inst, nil, speed.x, speed.z)
    local deg = math.rad(inst.Transform:GetRotation())

    if not canmoveto(inst, x, y, z, px, py, pz, deg) then
        local cos = math.rcos(deg)
        local sin = math.rsin(-deg)

        local finalxpos, finalzpos = 0, 0
        local mcx, mcz = getmaxxz(inst, x, y, z, cos, sin)

        if cos == 0 and sin ~= 0 or sin == 0 and cos ~= 0 then
            if cos ~= 0 then
                finalxpos = mcx
                finalzpos = z
            else
                finalxpos = x
                finalzpos = mcz
            end
        else
            local tz = math.variance(z, mcz, 0.1) and mcz or z
            if not canmoveto(inst, x, y, z, px, py, tz, deg) then
                finalxpos = mcx
            else
                finalxpos = px
            end
            local tx = math.variance(x, mcx, 0.1) and mcx or x
            if not canmoveto(inst, x, y, z, tx, py, pz, deg) then
                finalzpos = mcz
            else
                finalzpos = pz
            end
            if finalxpos == px and finalzpos == pz then
                finalxpos = x
                finalzpos = z
            end
        end
        local sx, sy, sz = inst.Transform:GetScale()
        local cx, cz = TickSpeedToSpeed(finalxpos - x, sx), TickSpeedToSpeed(finalzpos - z, sz)

        dorealmovement(unpack(dorealargs))
        local mx, my, mz = inst.Physics:GetMotorVel()
        local rcx, rcz = math.rotate(mx, mz, -deg)
        mx, mz = math.rotate(math.abs(cx) < math.abs(rcx) and cx or rcx, math.abs(cz) < math.abs(rcz) and cz or rcz, deg)
        inst.Physics:SetMotorVel(mx, my, mz)

        if false and inst:HasTag("player") then
            print(string.format("\npredictedcoords:\ndeg: %.2f\nx: %.4f z: %.4f\npx: %.4f pz: %.4f\nfinalx: %.4f finalz: %.4f\nmomentumx: %.4f momentumz: %.4f\nmovementdata:\ncalcx: %.4f calcz: %.4f\nrealx: %.4f realz: %.4f",
                math.deg(deg), x, z, px, pz, finalxpos, finalzpos, mx, mz, cx, cz, rcx, rcz))
        end
        return true
    end
    dorealmovement(unpack(dorealargs))
    return false
end

return GetNextTickPosition, DoFakePhysicsWallMovement