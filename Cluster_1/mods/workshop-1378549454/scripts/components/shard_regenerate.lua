--[[
Copyright (C) 2019 Zarklord

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

--------------------------------------------------------------------------
--[[ Shard_Regenerate ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "Shard_Regenerate should not exist on client")

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _world = TheWorld
local _ismastershard = _world.ismastershard
local _regenreadylist = {}

--------------------------------------------------------------------------
--[[ Private event listeners ]]
--------------------------------------------------------------------------
local function AllShardsRegenReady()
    for k, v in pairs(SHARD_LIST) do
        if not _regenreadylist[k] then
            return false
        end
    end
    return true
end

local function ResetServer(inst, data)
    local slotdata = SaveGameIndex.data.slots[SaveGameIndex:GetCurrentSaveSlot()]
    local options = slotdata and slotdata.world.options or nil
    if options then
        print("Shard_Regenerate regenerating world", data.preserve_seed)
        options[1] = options[1] or {overrides = {}}
        options[1].overrides.worldseed = data.preserve_seed and (options[1].overrides.worldseed or _world.meta.seed) or (nil)
        options[1].preserveworldseed = true
        SaveGameIndex:Save(function()
            if data.srpc_sender then
                --notify the sending server that we are ready for regen.
                SendShardRPC(SHARD_RPC.GemCore.ReportRegenReady, data.srpc_sender)
            else
                _regenreadylist = {}
                --notify all other servers to preserve/delete the world seed.
                SendShardRPC(SHARD_RPC.GemCore.ResetServer, nil, data)
                _world:PushEvent("shard_reportregenready", tonumber(TheShard:GetShardId())) 
            end
        end)
    end
end

local function ReportRegenReady(src, shard_id)
    _regenreadylist[shard_id] = true
    if AllShardsRegenReady() then
        TheNet:ActualSendWorldResetRequestToServer()
    end
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

inst:ListenForEvent("shard_resetserver", ResetServer, _world)
inst:ListenForEvent("shard_reportregenready", ReportRegenReady, _world)

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)
