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
local _G = GLOBAL
_G.global("WORLDGEN_MOD_POSTINIT")

modimport("gemscripts/gemrun")
_G.gemrun = gemrun
local MakeGemFunction, DeleteGemFunction = gemrun("gemfunctionmanager")

_G.GEMENV = env

IsTheFrontEnd = false
_G.IsTheFrontEnd = false

gemrun("tools/fnhider")
_G.UpvalueHacker = gemrun("tools/upvaluehacker")
_G.LocalVariableHacker = gemrun("tools/localvariablehacker")
_G.bit = gemrun("bit")
_G.DebugPrint = gemrun("tools/misc").Global.DebugPrint
_G.minitraceback = gemrun("tools/misc").Global.minitraceback

gemrun("modconfigmanager")
gemrun("stringutils")
gemrun("tableutils")
gemrun("line")
gemrun("maths/mathutils")
gemrun("maths/VecCommon")
gemrun("maths/Vec2")
gemrun("maths/Vec3")
gemrun("maths/Vec4")
gemrun("maths/Matrix4")

gemrun("hooks")

gemrun("tools/dynamictilemanager")
gemrun("tools/originaltiles")
gemrun("tools/worldgenoptions")

modimport("gemscripts/legacy_modbackendmain")

if _G.rawget(_G, "WORLDGEN_MAIN") == 1 then
    gemrun("worldseedhelper")

    MakeGemFunction("extendenvironment", function(functionname, env, ...)
        local gemrun = gemrun
        _G.setfenv(1, env)
        UpvalueHacker = gemrun("tools/upvaluehacker")
        LocalVariableHacker = gemrun("tools/localvariablehacker")
        bit = gemrun("bit")
        DebugPrint = gemrun("tools/misc").Global.DebugPrint
        minitraceback = gemrun("tools/misc").Global.minitraceback
        DynamicTileManager = gemrun("tools/dynamictilemanager")
        if modname then
            function GetModModConfigData(optionname, modmodname, ...)
                return _G.GetModModConfigData(optionname, modmodname, modname, ...)
            end
        else
            GetModModConfigData = _G.GetModModConfigData
        end
    end, true)
end

local function DoModsPostInit(ModManager)
    _G.WORLDGEN_MOD_POSTINIT = 1
    for i, mod in ipairs(ModManager.mods) do
        ModManager.currentlyloadingmod = mod.modname
        ModManager:InitializeModMain(mod.modname, mod, "modworldgenmainpostinit.lua")
        ModManager.currentlyloadingmod = nil
    end
end

local _InitializeModMain = _G.ModManager.InitializeModMain
function _G.ModManager:InitializeModMain(_modname, env, mainfile, ...)
    if mainfile == "modworldgenmain.lua" then
        env.IsTheFrontEnd = false
    end
    if (mainfile == "modmain.lua" or mainfile == "modworldgenmainpostinit.lua") and _modname == modname then
        MakeGemFunction("gemfunctionmanager", function(functionname, ...) return MakeGemFunction, DeleteGemFunction end)
    end
    local rets = {_InitializeModMain(self, _modname, env, mainfile, ...)}
    if _G.rawget(_G, "WORLDGEN_MAIN") == 1 and mainfile == "modworldgenmain.lua" and #self.mods == #self.enabledmods then
        DoModsPostInit(self)
    end
    return _G.unpack(rets)
end

DeleteGemFunction("gemfunctionmanager")

if _G.rawget(_G, "WORLDGEN_MAIN") == 1 and #_G.ModManager.mods == 1 then
    DoModsPostInit(_G.ModManager)
end