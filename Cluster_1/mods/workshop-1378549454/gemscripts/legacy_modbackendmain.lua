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
--any access form or function defined in the file is depreciated, and is subject to removal at my discretion.
local _G = GLOBAL

_G.GEMWORLDGENENV = env

local AddGetSet, RemoveGetSet = gemrun("tools/globalmetatable")
_G.GlobalMetatable = {AddGetSet = AddGetSet, RemoveGetSet = RemoveGetSet}

_G.SetupGemCoreWorldGenEnv = function(enviroment)
    local gemrun = gemrun
    _G.setfenv(1, enviroment or _G.getfenv(2))
    if _G.IsWorkshopMod(modname) then
        _G.modprint("MOD WARNING: ".._G.ModInfoname(modname)..": SetupGemCoreWorldGenEnv is DEPRECIATED")
    else
        moderror("SetupGemCoreWorldGenEnv is DEPRECIATED")
    end
    DebugPrint = gemrun("tools/misc").Local.DebugPrint
    UpvalueHacker = gemrun("tools/upvaluehacker")
    LocalVariableHacker = gemrun("tools/localvariablehacker")
    bit = gemrun("bit")
    local AddGetSet, RemoveGetSet = gemrun("tools/globalmetatable")
    GlobalMetatable = {AddGetSet = AddGetSet, RemoveGetSet = RemoveGetSet}
    DynamicTileManager = gemrun("tools/dynamictilemanager")
    MapTagger = gemrun("map/maptagger")
end

_G.SetupGemCoreWorldGenEnv()

local _InitializeModMain = _G.ModManager.InitializeModMain
function _G.ModManager:InitializeModMain(_modname, env, mainfile, ...)
    if mainfile == "modworldgenmain.lua" then
        env.SetupGemCoreWorldGenEnv = function() _G.SetupGemCoreWorldGenEnv(env) end
    end
    return _InitializeModMain(self, _modname, env, mainfile, ...)
end