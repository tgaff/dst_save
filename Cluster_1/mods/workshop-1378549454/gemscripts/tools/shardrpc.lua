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
SHARD_RPC_HANDLERS = {}
SHARD_RPC = {}

local function __index_lower(t, k)
    return rawget(t, string.lower(k))
end

local function __newindex_lower(t, k, v)
    rawset(t, string.lower(k), v)
end

local function setmetadata( tab )
    setmetatable(tab, {__index = __index_lower, __newindex = __newindex_lower})
end

local function HandleShardRPC(shard_id, shardlist, namespace, code, ...)
    if type(shardlist) == "number" then
        shardlist = {shardlist}
    end
    if SHARD_RPC_HANDLERS[namespace] ~= nil then
        local fn = SHARD_RPC_HANDLERS[namespace][code]
        if fn ~= nil then
            if shard_id ~= TheShard:GetShardId() and (shardlist == nil or table.contains(shardlist, tonumber(TheShard:GetShardId()))) then
                fn(shard_id, ...)
            end
        else
            print("Invalid Shard RPC code: ", namespace, code)
        end
    else
        print("Invalid Shard RPC namespace: ", namespace, code)
    end
end

local _Networking_SystemMessage = Networking_SystemMessage
function Networking_SystemMessage(message)
    if string.sub(message, 1, 3) == "HSR" then
        if TheWorld.ismastersim then
            local RPC = loadstring("HandleShardRPC("..string.sub(message, 4)..")")
            setfenv(RPC, {HandleShardRPC = HandleShardRPC})
            RPC()
        end
    else
        _Networking_SystemMessage(message)
    end
end

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
    if SHARD_RPC[namespace] == nil then
        SHARD_RPC[namespace] = {}
        SHARD_RPC_HANDLERS[namespace] = {}

        setmetadata(SHARD_RPC[namespace])
        setmetadata(SHARD_RPC_HANDLERS[namespace])
    end

    table.insert(SHARD_RPC_HANDLERS[namespace], fn)
    SHARD_RPC[namespace][name] = { namespace = namespace, id = #SHARD_RPC_HANDLERS[namespace] }

    setmetadata(SHARD_RPC[namespace][name])
end

--TODO: what other things might we want in the shard list?
local function ShardReportInfo(shard_id, fromShardID, shardData)
    if TheWorld.ismastershard then
        TheWorld:PushEvent("new_shard_report", {fromShard = fromShardID, data = DataDumper(shardData, nil, false)})
    end
end
AddShardRPCHandler("GemCore", "ShardReportInfo", ShardReportInfo)

local function dump(val)
    return DataDumper(val, '', true)
end

local function SendShardRPC(id_table, shardlist, ...)
    assert(id_table.namespace ~= nil and SHARD_RPC_HANDLERS[id_table.namespace] ~= nil and SHARD_RPC_HANDLERS[id_table.namespace][id_table.id] ~= nil)

    --convert args to string format
	local ArgStrings = {}
    table.insert(ArgStrings, dump(TheShard:GetShardId()))
    --if we only have a single shard were sending to we can optimize by not sending it as a table
    if type(shardlist) == "table" and #shardlist == 1 then
        shardlist = tonumber(shardlist[1])
    elseif type(shardlist) == "string" then
        shardlist = tonumber(shardlist)
    elseif type(shardlist) == "table" then
        for i, v in ipairs(shardlist) do
            shardlist[i] = tonumber(v)
        end
    end
    table.insert(ArgStrings, dump(shardlist))
    table.insert(ArgStrings, dump(id_table.namespace))
    table.insert(ArgStrings, dump(id_table.id))

    for i, v in ipairs({...}) do
    	table.insert(ArgStrings, dump(v))
    end

	TheNet:SystemMessage("HSR"..table.concat(ArgStrings, ","))
end

--small helper function for pure secondary -> master communication
local function SendShardRPCToServer(id_table, ...)
    SendShardRPC(id_table, tonumber(SHARDID.MASTER), ...)
end

_G.require("components/shard_report")
gemrun("shardcomponent", "shard_report")

return AddShardRPCHandler, SendShardRPC, SendShardRPCToServer