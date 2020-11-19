--[[
Copyright (C) 2018-2020 Zarklord

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

--[[
Okay here is the deal with how this works:
We need some function that we can send a custom data from the lua side of the secondary shard servers, to the lua side of the master shard.
(Secondary Lua to Secondary C to Master C to Master Lua)
Tecnicaly we only need to be able to send a custom string since we can load a string as raw lua code,
THE ONLY way of doing this is the Announcements/SystemMessage system.
so we do a "System Message" with the unique prefix HSR(HandleShardRPC) if we encounter a system message with the prefix HSR,
we block it from reaching the player's screen and if its the intended shards we execute the string code.
there is some semi complicated code converting your arguments to a string.
the only thing you cant actually send directly is enitities(though they wouldn't exist on the master shard generaly anyway).
]]

local shard_components = {}

GEMENV.AddPrefabPostInitAny(function(inst)
    if TheWorld and TheWorld.shard == inst then
        for i, v in ipairs(shard_components) do
            inst:AddComponent(v)
        end
    end
end)

local MakeGemFunction, DeleteGemFunction = gemrun("gemfunctionmanager")
MakeGemFunction("shardcomponent", function(functionname, name, ...)
    table.insert(shard_components, name)
end, true)

SHARD_LIST = {}
SHARD_RPC = setmetatable(SHARD_RPC, {__index = function(t, k)
    return SHARD_MOD_RPC[k]
end})

local shardreportfns = {}
local function AddShardReportDataFn(func)
    table.insert(shardreportfns, func)
end

local function GetShardReportDataFromWorld()
    local data = {}
    data.tags = {}
    if TheWorld:HasTag("forest") then
        table.insert(data.tags, "forest")
    end
    if TheWorld:HasTag("cave") then
        table.insert(data.tags, "cave")
    end
    for i, v in ipairs(shardreportfns) do
        v(data)
    end
    return data
end

MakeGemFunction("shardreportdata", function(functionname, ...)
    return AddShardReportDataFn, GetShardReportDataFromWorld --GetShardReportDataFromWorld is only avaliable from inside gem core.
end)

local function AddShardRPCHandler(namespace, name, fn)
    AddShardModRPCHandler(namespace, name, fn)
end

local function ShardRPCWrapper(shard_id, namespace, code, string_args)
    if TheShard:GetShardId() ~= tostring(shard_id) then
        if SHARD_MOD_RPC_HANDLERS[namespace] ~= nil then
            local fn = SHARD_MOD_RPC_HANDLERS[namespace][code]
            local success, args = RunInSandbox(string_args)
            if success then
                fn(shard_id, unpack(args))
            end
        end
    end
end
AddShardRPCHandler("GemCore", "ShardRPCWrapper", ShardRPCWrapper)

--TODO: what other things might we want in the shard list?
local function ShardReportInfo(shard_id, fromShardID, shardData)
    if TheWorld.ismastershard then
        TheWorld:PushEvent("new_shard_report", {fromShard = fromShardID, data = DataDumper(shardData, nil, false)})
    end
end
AddShardRPCHandler("GemCore", "ShardReportInfo", ShardReportInfo)

local function SendShardRPC(id_table, shardlist, ...)
    assert(id_table.namespace ~= nil and SHARD_MOD_RPC_HANDLERS[id_table.namespace] ~= nil and SHARD_MOD_RPC_HANDLERS[id_table.namespace][id_table.id] ~= nil)
    SendModRPCToShard(GetShardModRPC("GemCore", "ShardRPCWrapper"), shardlist, id_table.namespace, id_table.id, DataDumper({...}, nil, true))
end

--small helper function for pure secondary -> master communication
local function SendShardRPCToServer(id_table, ...)
    assert(id_table.namespace ~= nil and SHARD_MOD_RPC_HANDLERS[id_table.namespace] ~= nil and SHARD_MOD_RPC_HANDLERS[id_table.namespace][id_table.id] ~= nil)
    SendModRPCToShard(GetShardModRPC("GemCore", "ShardRPCWrapper"), SHARDID.MASTER, id_table.namespace, id_table.id, DataDumper({...}, nil, true))
end

_G.require("components/shard_report")
gemrun("shardcomponent", "shard_report")

return AddShardRPCHandler, SendShardRPC, SendShardRPCToServer