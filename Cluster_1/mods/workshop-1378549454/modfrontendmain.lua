--[[
Copyright (C) 2019-2020 Zarklord

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
local _G = GLOBAL

frontendassets = {
    Asset("IMAGE", "images/world_seed.tex"),
    Asset("ATLAS", "images/world_seed.xml"),
}

local first_load = true
if _G.rawget(_G, "gemrun") then
    first_load = false
    gemrun = _G.gemrun
else
    modimport("gemscripts/gemrun")
    _G.gemrun = gemrun
end
local MakeGemFunction, DeleteGemFunction = gemrun("gemfunctionmanager")

_G.GEMENV = env

IsTheFrontEnd = true
_G.IsTheFrontEnd = true

if first_load then
    local onunloadmodanycb = {}
    local ongemcoreunload = {}
    MakeGemFunction("unloadmodany", function(functionname, cb, ...)
        table.insert(onunloadmodanycb, cb)
    end, true)
    MakeGemFunction("unloadgemcore", function(functionname, cb, ...)
        table.insert(ongemcoreunload, cb)
    end, true)

    function OnUnloadMod()
        for i, cb in ipairs(ongemcoreunload) do
            cb()
        end
    end

    function OnUnloadModAny(modname)
        for i, cb in ipairs(onunloadmodanycb) do
            cb(modname)
        end
    end
end

gemrun("tools/fnhider")
_G.UpvalueHacker = gemrun("tools/upvaluehacker")
_G.LocalVariableHacker = gemrun("tools/localvariablehacker")
_G.bit = gemrun("bit")
_G.DebugPrint = gemrun("tools/misc").Global.DebugPrint
_G.minitraceback = gemrun("tools/misc").Global.minitraceback
local AddGetSet, RemoveGetSet = gemrun("tools/globalmetatable")
_G.GlobalMetatable = {AddGetSet = AddGetSet, RemoveGetSet = RemoveGetSet}

gemrun("modconfigmanager")
gemrun("assetloader")
gemrun("memspikefix")
gemrun("worldgenoptiontypes")
gemrun("tools/worldgenoptions", modname)

gemrun("worldseedhelper")

env.first_load = first_load
modimport("gemscripts/legacy_modfrontendmain")
env.first_load = nil

MakeGemFunction("extendenvironment", function(functionname, env, ...)
    local gemrun = gemrun
    _G.setfenv(1, env)
    UpvalueHacker = gemrun("tools/upvaluehacker")
    LocalVariableHacker = gemrun("tools/localvariablehacker")
    bit = gemrun("bit")
    DebugPrint = gemrun("tools/misc").Global.DebugPrint
    minitraceback = gemrun("tools/misc").Global.minitraceback
    if modname then
        WorldGenOptions = gemrun("tools/worldgenoptions", modname)
        function GetModModConfigData(optionname, modmodname, ...)
            return _G.GetModModConfigData(optionname, modmodname, modname, ...)
        end
    else
        GetModModConfigData = _G.GetModModConfigData
    end
end, true)