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

local MakeAssetLoader = require("prefabs/assetloader")

local ASSETPREFABPREFIX = "GEMCOREASSETLOADER"

local frontend_assets_prefabs = {}
local frontend_assets_prefabnames = {}

local MakeGemFunction = gemrun("gemfunctionmanager")

local function unloadassets(modname)
    if modname == nil then
        TheSim:UnloadPrefabs(frontend_assets_prefabs)
        TheSim:UnregisterPrefabs(frontend_assets_prefabnames)
        frontend_assets_prefabs = {}
        frontend_assets_prefabnames = {}
    else
        local idx = table.reverselookup(frontend_assets_prefabnames, ASSETPREFABPREFIX..modname)
        if idx ~= nil then
            TheSim:UnloadPrefabs({frontend_assets_prefabs[idx]})
            table.remove(frontend_assets_prefabs, idx)
            TheSim:UnregisterPrefabs({frontend_assets_prefabnames[idx]})
            table.remove(frontend_assets_prefabnames, idx)
        end
    end
end

local function loadassets(modname, assets)
    if assets then
        assert(KnownModIndex:DoesModExistAnyVersion(modname), "modname "..modname.." must refer to a valid mod!")
        local prefabname = ASSETPREFABPREFIX..modname
        for i, v in ipairs(assets) do
            if softresolvefilepath(v.file, nil, MODS_ROOT..modname.."/") ~= nil then
                resolvefilepath(v.file, nil, MODS_ROOT..modname.."/")
            end
        end
        local prefab = MakeAssetLoader(prefabname, assets)
        table.insert(frontend_assets_prefabs, prefab)
        table.insert(frontend_assets_prefabnames, prefabname)
        RegisterPrefabs(prefab)
        TheSim:LoadPrefabs({prefabname})
    end
end

gemrun("unloadmodany", unloadassets)
MakeGemFunction("unloadassets", function(functionname, modname, ...) unloadassets(modname) end, true)
MakeGemFunction("loadassets", function(functionname, modname, assets, ...) loadassets(modname, assets) end, true)