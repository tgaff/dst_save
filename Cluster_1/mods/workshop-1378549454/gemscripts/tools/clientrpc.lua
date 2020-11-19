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

CLIENT_RPC = setmetatable(CLIENT_RPC, {__index = function(t, k)
    return CLIENT_MOD_RPC[k]
end})

local function AddClientRPCHandler(namespace, name, fn)
    AddClientModRPCHandler(namespace, name, fn)
end

local function SendClientRPC(id_table, clientlist, ...)
    SendModRPCToClient(id_table, clientlist, ...)
end

return AddClientRPCHandler, SendClientRPC