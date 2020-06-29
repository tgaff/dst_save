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

local MakeGemFunction, DeleteGemFunction = gemrun("gemfunctionmanager")

_G.GEMWORLDGENENV = env

_G.global("GEMWORLDGENCALLBACKS")

local AddGetSet, RemoveGetSet = gemrun("tools/globalmetatable")
_G.GlobalMetatable = {AddGetSet = AddGetSet, RemoveGetSet = RemoveGetSet}

--OLD VERSION FRONTEND COMPAT
local function SetupGemCoreWorldGenEnv(enviroment)
    _G.setfenv(1, enviroment)
    gemrun = _G.gemrun
    DebugPrint = gemrun("tools/misc").Local.DebugPrint
    UpvalueHacker = gemrun("tools/upvaluehacker")
    LocalVariableHacker = gemrun("tools/localvariablehacker")
    bit = gemrun("bit")
    WorldGenOptions = gemrun("tools/worldgenoptions", modname)
    --wrap all functions to automatically call with self.
    if WorldGenOptions.wrapped ~= true then
        for k, v in pairs(WorldGenOptions) do
            if type(v) == "function" then
                local _compat = v
                WorldGenOptions[k] = function(self, ...)
                    if self == WorldGenOptions then
                        return _compat(self, ...)
                    else
                        return _compat(WorldGenOptions, self, ...)
                    end
                end
            end
        end
        for k, v in pairs(_G.getmetatable(WorldGenOptions)) do
            if type(v) == "function" then
                local _compat = v
                WorldGenOptions[k] = function(self, ...)
                    if self == WorldGenOptions then
                        return _compat(self, ...)
                    else
                        return _compat(WorldGenOptions, self, ...)
                    end
                end
            end
        end
        WorldGenOptions.wrapped = true
    end
    local AddGetSet, RemoveGetSet = gemrun("tools/globalmetatable")
    GlobalMetatable = {AddGetSet = AddGetSet, RemoveGetSet = RemoveGetSet}

    function ReloadFrontEndAssets()
        gemrun("unloadassets", enviroment.modname or true)--we do the "or true", to prevent nil getting passed which is how we signal deletion of all frontend_assets_prefabs.
        gemrun("loadassets", enviroment.modname, enviroment.frontendassets)
    end
    ReloadFrontEndAssets()
end

SetupGemCoreWorldGenEnv(env)
if first_load then
    gemrun("unloadgemcore", function() _G.GEMWORLDGENCALLBACKS = nil end)
end

--these are in here, since I need to delete them to prevent bad access to these functions
DeleteGemFunction("unloadmodany")
DeleteGemFunction("unloadgemcore")
MakeGemFunction("gemfunctionmanager", function() return function() end, function() end end)

local function CallWorldgenModCallback(callback)
    local enviroment = _G.getfenv(callback)
    _G.setfenv(1, enviroment)
    if _G.IsWorkshopMod(modname) then
        _G.modprint("MOD WARNING: ".._G.ModInfoname(modname)..": Worldgen Mod Callback is DEPRECIATED")
    else
        moderror("Worldgen Mod Callback is DEPRECIATED")
    end
    local _path = _G.package.path
    local _currentlyloadingmod = _G.ModManager.currentlyloadingmod

    _G.package.path = enviroment.MODROOT.."\\scripts\\?.lua;".._G.package.path
    SetupGemCoreWorldGenEnv(enviroment)
    _G.RunInEnvironmentSafe(callback, enviroment)
    
    _G.package.path = _path
    _G.ModManager.currentlyloadingmod = _currentlyloadingmod
end

for i, v in ipairs(_G.GEMWORLDGENCALLBACKS or {}) do
    CallWorldgenModCallback(v)
end

_G.GEMWORLDGENCALLBACKS = _G.setmetatable({}, {__newindex = function(t, k, v)
    CallWorldgenModCallback(v)
end})