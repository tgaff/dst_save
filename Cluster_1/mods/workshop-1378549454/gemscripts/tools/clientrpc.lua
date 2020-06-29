--[[
Copyright (C) 2019, 2020 Zarklord

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
We need some function that we can send a custom data from the lua side of the servers, to the lua side of the client(s).
(Server Lua to Server C to Client C to Client Lua)
Technicaly we only need to be able to send a custom string since we can load a string as raw lua code,
THE ONLY way of doing this is the Announcements/SystemMessage system.
so we do a "System Message" with the unique prefix HCR(HandleClientRPC) if we encounter a system message with the prefix HCR,
we block it from reaching the player's screen and if its the intended clients we execute the string code.
there is some semi complicated code converting your arguments to a string.
the only thing you cant actually send directly is entities(though this is due to a technical limitation, and could probably be implemented in the future).
]]

local client_components = {}

GEMENV.AddPrefabPostInitAny(function(inst)
    if TheWorld and TheWorld.net == inst then
        for i, v in ipairs(client_components) do
            inst:AddComponent(v)
        end
    end
end)

local MakeGemFunction, DeleteGemFunction = gemrun("gemfunctionmanager")
MakeGemFunction("clientcomponent", function(functionname, name, ...)
    table.insert(client_components, name)
end, true)

gemrun("clientcomponent", "server_info")

CLIENT_LIST = {}
CLIENT_RPC_HANDLERS = {}
CLIENT_RPC = {}

local function __index_lower(t, k)
    return rawget(t, string.lower(k))
end

local function __newindex_lower(t, k, v)
    rawset(t, string.lower(k), v)
end

local function setmetadata(tab)
    setmetatable(tab, {__index = __index_lower, __newindex = __newindex_lower})
end

local function HandleClientRPC(shard_id, clientlist, namespace, code, ...)
    if type(clientlist) == "string" then
        clientlist = {clientlist}
    end
    if CLIENT_RPC_HANDLERS[namespace] ~= nil then
        local fn = CLIENT_RPC_HANDLERS[namespace][code]
        if fn ~= nil then
            if (clientlist == nil) or --all clients
            (clientlist == true and TheWorld.net.components.server_info:GetShardId() == shard_id) or --all clients on the same shard as the sender
            (clientlist == false and TheWorld.net.components.server_info:GetShardId() ~= shard_id) or --all clients on a different shard from the sender
            (type(clientlist) == "table" and table.contains(clientlist, TheNet:GetUserID())) then --specified client list
                fn(shard_id, ...)
            end
        else
            print("Invalid Client RPC code: ", namespace, code)
        end
    else
        print("Invalid Client RPC namespace: ", namespace, code)
    end
end

local _Networking_SystemMessage = Networking_SystemMessage
function Networking_SystemMessage(message)
    if string.sub(message, 1, 3) == "HCR" then
        if TheNet:GetIsClient() then
            local RPC = loadstring("HandleClientRPC("..string.sub(message, 4)..")")
            setfenv(RPC, {HandleClientRPC = HandleClientRPC})
            RPC()
        end
    else
        _Networking_SystemMessage(message)
    end
end

local function AddClientRPCHandler(namespace, name, fn)
    if CLIENT_RPC[namespace] == nil then
        CLIENT_RPC[namespace] = {}
        CLIENT_RPC_HANDLERS[namespace] = {}

        setmetadata(CLIENT_RPC[namespace])
        setmetadata(CLIENT_RPC_HANDLERS[namespace])
    end

    table.insert(CLIENT_RPC_HANDLERS[namespace], fn)
    CLIENT_RPC[namespace][name] = { namespace = namespace, id = #CLIENT_RPC_HANDLERS[namespace] }

    setmetadata(CLIENT_RPC[namespace][name])
end

local function dump(val)
    return DataDumper(val, '', true)
end

local function SendClientRPC(id_table, clientlist, ...)
    assert(id_table.namespace ~= nil and CLIENT_RPC_HANDLERS[id_table.namespace] ~= nil and CLIENT_RPC_HANDLERS[id_table.namespace][id_table.id] ~= nil)

    --convert args to string format
    local ArgStrings = {}
    table.insert(ArgStrings, dump(TheShard:GetShardId()))
    --if we only have a single client were sending to we can optimize by not sending it as a table
    if type(clientlist) == "table" and #clientlist == 1 then
        clientlist = clientlist[1]
    end
    table.insert(ArgStrings, dump(clientlist))
    table.insert(ArgStrings, dump(id_table.namespace))
    table.insert(ArgStrings, dump(id_table.id))

    local args = {...}
    for i, v in ipairs(args) do
        table.insert(ArgStrings, dump(args[i]))
    end

    TheNet:SystemMessage("HCR"..table.concat(ArgStrings, ","))
end

return AddClientRPCHandler, SendClientRPC