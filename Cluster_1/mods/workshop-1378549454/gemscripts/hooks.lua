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
local MakeGemFunction, DeleteGemFunction = gemrun("gemfunctionmanager")

local ondoinitgame = {}
MakeGemFunction("ondoinitgame", function(functionname, cb, ...)
    table.insert(ondoinitgame, cb)
end, true)

local onsavegame = {}
MakeGemFunction("onsavegame", function(functionname, cb, ...)
    table.insert(onsavegame, cb)
end, true)

local ongeneratenewworld = {}
MakeGemFunction("ongeneratenewworld", function(functionname, cb, ...)
    table.insert(ongeneratenewworld, cb)
end, true)

local function MakeCallbackManager(original_callback, callbacklist, ...)
    local index = 1
    local function CallbackManager(...)
        local mod_callback = callbacklist[index]
        index = index + 1
        if mod_callback then
            return mod_callback(CallbackManager, ...)
        else
            return original_callback(...)
        end
    end
    return CallbackManager(...)
end

if rawget(_G, "MAIN") == 1 then
    local _Load = Profile.Load
    function Profile:Load(callback, ...)
        if TheNet:GetIsServer() and callback ~= nil then
            if UpvalueHacker.GetUpvalue(callback, "OnFilesLoaded") then
                local _DoInitGame = UpvalueHacker.GetUpvalue(callback, "OnFilesLoaded", "OnUpdatePurchaseStateComplete", "DoResetAction", "DoLoadWorldFile", "DoInitGame")
                UpvalueHacker.SetUpvalue(callback,  function(...)
                    return MakeCallbackManager(_DoInitGame, ondoinitgame, ...)
                end, "OnFilesLoaded", "OnUpdatePurchaseStateComplete", "DoResetAction", "DoLoadWorldFile", "DoInitGame")
            end
        end
        _Load(self, callback, ...)
    end

    local _SaveGame = SaveGame
    function SaveGame(...)
        return MakeCallbackManager(_SaveGame, onsavegame, ...)
    end

    local _OnGenerateNewWorld = ShardIndex.OnGenerateNewWorld
    function ShardIndex.OnGenerateNewWorld(...)
        return MakeCallbackManager(_OnGenerateNewWorld, ongeneratenewworld, ...)
    end
end