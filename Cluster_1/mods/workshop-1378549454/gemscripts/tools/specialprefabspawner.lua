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

local MakeGemFunction, DeleteGemFunction = gemrun("gemfunctionmanager")

local PREFAB_PREFIX = "gemprefab_"
local UID = 0

local specialprefabs = {}
MakeGemFunction("getspecialprefab", function(functionname, prefab, onspawnfn, ...)
    if prefab == nil then return end
    if specialprefabs[prefab] then
        specialprefabs[prefab] = nil
    else
        local uniqueprefabid = PREFAB_PREFIX..prefab.."_"..UID
        UID = UID + 1
        specialprefabs[uniqueprefabid] = {prefab = prefab, onspawnfn = onspawnfn}
        return uniqueprefabid
    end
end, true)

local _SpawnPrefab = SpawnPrefab
function SpawnPrefab(name, ...)
    local pref
    if specialprefabs[name] then
        pref = specialprefabs[name].prefab
    end
    local prefab = _SpawnPrefab(pref or name, ...)
    if prefab and pref then
        specialprefabs[name].onspawnfn(prefab)
    end
    return prefab
end