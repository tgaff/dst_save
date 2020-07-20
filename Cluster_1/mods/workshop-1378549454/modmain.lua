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

_G.global("MOD_POSTINIT")

Assets = {
    Asset("IMAGE", "images/gemdict_ui.tex"),
    Asset("ATLAS", "images/gemdict_ui.xml"),
}

local MakeGemFunction, DeleteGemFunction = gemrun("gemfunctionmanager")

gemrun("memspikefix")
gemrun("sim")
gemrun("tools/customtechtree")
gemrun("tools/krampednaughtiness")
gemrun("tools/componentspoofer")
gemrun("tools/runtimecomponents")
gemrun("tools/soundmanager")
gemrun("tools/specialprefabspawner")
gemrun("gemdictionary/gemdict")
_G.GetNextTickPosition, _G.DoFakePhysicsWallMovement = gemrun("tools/physicscollisions")
_G.AddShardRPCHandler, _G.SendShardRPC, _G.SendShardRPCToServer = gemrun("tools/shardrpc")
_G.AddClientRPCHandler, _G.SendClientRPC = gemrun("tools/clientrpc")
local AddGetSet, RemoveGetSet = gemrun("tools/globalmetatable")

local MiscStuff = gemrun("tools/misc")

for k, v in pairs(MiscStuff.Global) do
	GLOBAL[k] = v
end

AddGetSet("TheLocalPlayer", function(t, n)
    return not _G.TheNet:IsDedicated() and _G.ThePlayer or nil
end, nil, true)

--[[
_G.AddRecipePostInitAny(function(recipe)
    local ingredient = recipe:FindAndConvertIngredient("poop")
    if ingredient then
        ingredient:AddDictionaryPrefab("guano")
        --ingredient.allowmultipleprefabtypes = false
    end
end)
--]]

gemrun("globalpause_patches")
gemrun("worldseedhelper")

modimport("gemscripts/legacy_modmain")

MakeGemFunction("extendenvironment", function(functionname, env, ...)
    local gemrun = gemrun
    _G.setfenv(1, env)
    UpvalueHacker = gemrun("tools/upvaluehacker")
    LocalVariableHacker = gemrun("tools/localvariablehacker")
    bit = gemrun("bit")
    DynamicTileManager = gemrun("tools/dynamictilemanager")
    AddShardRPCHandler = _G.AddShardRPCHandler
    AddClientRPCHandler = _G.AddClientRPCHandler
    for k, v in pairs(MiscStuff.Local) do
        env[k] = v
    end
    if modname then
        gemrun("forcememspikefix", true)
        function GetModModConfigData(optionname, modmodname, ...)
            return _G.GetModModConfigData(optionname, modmodname, modname, ...)
        end
    else
        GetModModConfigData = _G.GetModModConfigData
    end
end, true)

local function DoModsPostInit(ModManager)
    _G.MOD_POSTINIT = 1
    for i, mod in ipairs(ModManager.mods) do
        ModManager.currentlyloadingmod = mod.modname
        ModManager:InitializeModMain(mod.modname, mod, "modmainpostinit.lua")
        ModManager.currentlyloadingmod = nil
    end
end

local _InitializeModMain = _G.ModManager.InitializeModMain
function _G.ModManager:InitializeModMain(_modname, env, mainfile, ...)
    if mainfile == "modmain.lua" then
        env.gemrun = gemrun
    end
    if mainfile == "modmainpostinit.lua" and _modname == modname then
        MakeGemFunction("gemfunctionmanager", function(functionname, ...) return MakeGemFunction, DeleteGemFunction end)
    end
    local rets = {_InitializeModMain(self, _modname, env, mainfile, ...)}
    if mainfile == "modmain.lua" and #self.mods == #self.enabledmods then
        DoModsPostInit(self)
    end
    return _G.unpack(rets)
end

DeleteGemFunction("gemfunctionmanager")

if #_G.ModManager.mods == 1 then
    DoModsPostInit(_G.ModManager)
end