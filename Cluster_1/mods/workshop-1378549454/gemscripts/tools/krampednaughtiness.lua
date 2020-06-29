--[[
Copyright (C) 2018, 2019 Zarklord

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

local NAUGHTY_VALUE
local NAUGHTY_VALUE_ADD = {}

GEMENV.AddComponentPostInit("kramped", function(inst)
    --Zarklord: yeah yeah its stupid, but hey it works.
    local _OnKilledOther, _fn_i, scope_fn
    for i, v in ipairs(inst.inst.event_listening["ms_playerjoined"][TheWorld]) do
        if UpvalueHacker.GetUpvalue(v, "OnKilledOther") and UpvalueHacker.GetUpvalue(v, "OnKilledOther", "NAUGHTY_VALUE") then
            _OnKilledOther, _fn_i, scope_fn = UpvalueHacker.GetUpvalue(v, "OnKilledOther")
            break
        end
    end

    NAUGHTY_VALUE = UpvalueHacker.GetUpvalue(_OnKilledOther, "NAUGHTY_VALUE")
    for k, v in pairs(NAUGHTY_VALUE_ADD) do
        NAUGHTY_VALUE[k] = v
    end

    local function OnKilledOther(player, data, ...)
        if data ~= nil and data.victim ~= nil and data.victim.prefab ~= nil then
            local naughtiness = NAUGHTY_VALUE[data.victim.prefab]
            if type(naughtiness) == "function" then
                NAUGHTY_VALUE[data.victim.prefab] = naughtiness(player, data)
            end
            _OnKilledOther(player, data, ...)
            NAUGHTY_VALUE[data.victim.prefab] = naughtiness
        end
    end
    debug.setupvalue(scope_fn, _fn_i, OnKilledOther)

    local _activeplayers = UpvalueHacker.GetUpvalue(inst.GetDebugString, "_activeplayers")

    local OnNaughtyAction = UpvalueHacker.GetUpvalue(_OnKilledOther, "OnNaughtyAction") 
    function inst:OnNaughtyAction(how_naughty, player)
        OnNaughtyAction(how_naughty, _activeplayers[player])
    end
end)

local function AddNaughtinessFor(prefab, value)
    if NAUGHTY_VALUE ~= nil then
        NAUGHTY_VALUE[prefab] = value
    else
        NAUGHTY_VALUE_ADD[prefab] = value
    end
end

return AddNaughtinessFor