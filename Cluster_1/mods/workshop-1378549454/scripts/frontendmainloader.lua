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

if CurrentRelease.GreaterOrEqualTo("R15_QOL_WORLDSETTINGS") then
    local frontend_envs = {}
    local unload_fns = {}
    local unload_any_fns = {}

    local GEMCOREFRONTENDLOADED = false
    local function CallModFrontendMain(modname)
        local _path = package.path
        local _currentlyloadingmod = ModManager.currentlyloadingmod
        local initenv = KnownModIndex:GetModInfo(modname)
        local env = CreateEnvironment(modname,  ModManager.worldgen)
        env.modinfo = initenv

        function env.ReloadFrontEndAssets()
            if env.frontendassets then
                _G.ModReloadFrontEndAssets(env.frontendassets, env.modname)
            end
        end

        env.gemrun = rawget(_G, "gemrun")
        package.path = MODS_ROOT..env.modname.."\\scripts\\?.lua;"..package.path
        ModManager.currentlyloadingmod = env.modname
        ModManager:InitializeModMain(env.modname, env, "modfrontendmain.lua", true)
        if kleifileexists(MODS_ROOT..env.modname.."/modfrontendmain.lua") then
            env.ReloadFrontEndAssets()
            frontend_envs[modname] = env
            if env.OnUnloadMod then
                unload_fns[modname] = env.OnUnloadMod
            end
            if env.OnUnloadModAny then
                unload_any_fns[modname] = env.OnUnloadModAny
            end
        end
        ModManager.currentlyloadingmod = _currentlyloadingmod
        package.path = _path
    end
    --call our frontendmain.lua
    CallModFrontendMain(GEMENV.modname)
    GEMCOREFRONTENDLOADED = true
    if IsSaveSlotLoading then
        for i, modname in ipairs(ModManager:GetEnabledServerModNames()) do
            if modname == GEMENV.modname then break end
            CallModFrontendMain(modname)
        end
    else
        for i, modname in ipairs(ModManager:GetEnabledServerModNames()) do
            if modname ~= GEMENV.modname then
                CallModFrontendMain(modname)
            end
        end
    end

    local _FrontendLoadMod = ModManager.FrontendLoadMod
    function ModManager:FrontendLoadMod(_modname, ...)
        _FrontendLoadMod(self, _modname, ...)
        if GEMCOREFRONTENDLOADED then
            CallModFrontendMain(_modname)
        elseif _modname == GEMENV.modname then
            --call our frontendmain.lua
            CallModFrontendMain(GEMENV.modname)
            GEMCOREFRONTENDLOADED = true
            for i, modname in ipairs(ModManager:GetEnabledServerModNames()) do
                if modname ~= GEMENV.modname then
                    CallModFrontendMain(modname)
                end
            end
        end
    end

    local _FrontendUnloadMod = ModManager.FrontendUnloadMod
    function ModManager:FrontendUnloadMod(_modname, ...)
        if _modname == nil then
            GEMCOREFRONTENDLOADED = false
            for i, modname in ipairs(ModManager:GetEnabledServerModNames()) do
                local unload_fn = unload_fns[modname]
                if unload_fn then unload_fn() end
                local unload_any_fn = unload_any_fns[modname]
                if unload_any_fn then unload_any_fn(nil) end
            end
            frontend_envs = {}
        else
            if _modname == GEMENV.modname then
                GEMCOREFRONTENDLOADED = false
            end
            local unload_fn = unload_fns[_modname]
            if unload_fn then unload_fn() end
            for i, modname in ipairs(ModManager:GetEnabledServerModNames()) do
                local unload_any_fn = unload_any_fns[modname]
                if unload_any_fn then unload_any_fn(_modname) end
            end
            frontend_envs[_modname] = nil
        end
        return _FrontendUnloadMod(self, _modname, ...)
    end
else
    local frontend_envs = {}
    local unload_fns = {}
    local unload_any_fns = {}

    local GEMCOREFRONTENDLOADED = false
    local function CallModFrontendMain(modname)
        local _path = package.path
        local _currentlyloadingmod = ModManager.currentlyloadingmod
        local initenv = KnownModIndex:GetModInfo(modname)
        local env = CreateEnvironment(modname,  ModManager.worldgen)
        env.modinfo = initenv
        function env.ReloadFrontEndAssets()
            gemrun("unloadassets", env.modname or true)--we do the "or true", to prevent nil getting passed which is how we signal deletion of all frontend_assets_prefabs.
            gemrun("loadassets", env.modname, env.frontendassets)
        end
        env.gemrun = rawget(_G, "gemrun")
        setfenv(env.ReloadFrontEndAssets, env)
        package.path = MODS_ROOT..env.modname.."\\scripts\\?.lua;"..package.path
        ModManager.currentlyloadingmod = env.modname
        ModManager:InitializeModMain(env.modname, env, "modfrontendmain.lua", true)
        if kleifileexists(MODS_ROOT..env.modname.."/modfrontendmain.lua") then
            env.ReloadFrontEndAssets()
            frontend_envs[modname] = env
            if env.OnUnloadMod then
                unload_fns[modname] = env.OnUnloadMod
            end
            if env.OnUnloadModAny then
                unload_any_fns[modname] = env.OnUnloadModAny
            end
        end
        ModManager.currentlyloadingmod = _currentlyloadingmod
        package.path = _path
    end
    --call our frontendmain.lua
    CallModFrontendMain(GEMENV.modname)
    GEMCOREFRONTENDLOADED = true
    if IsSaveSlotLoading then
        for i, modname in ipairs(ModManager:GetEnabledServerModNames()) do
            if modname == GEMENV.modname then break end
            CallModFrontendMain(modname)
        end
    else
        for i, modname in ipairs(ModManager:GetEnabledServerModNames()) do
            if modname ~= GEMENV.modname then
                CallModFrontendMain(modname)
            end
        end
    end

    local _FrontendLoadMod = ModManager.FrontendLoadMod
    function ModManager:FrontendLoadMod(_modname, ...)
        _FrontendLoadMod(self, _modname, ...)
        if GEMCOREFRONTENDLOADED then
            CallModFrontendMain(_modname)
        elseif _modname == GEMENV.modname then
            --call our frontendmain.lua
            CallModFrontendMain(GEMENV.modname)
            GEMCOREFRONTENDLOADED = true
            for i, modname in ipairs(ModManager:GetEnabledServerModNames()) do
                if modname ~= GEMENV.modname then
                    CallModFrontendMain(modname)
                end
            end
        end
    end

    local _FrontendUnloadMod = ModManager.FrontendUnloadMod
    function ModManager:FrontendUnloadMod(_modname, ...)
        if _modname == nil then
            GEMCOREFRONTENDLOADED = false
            for i, modname in ipairs(ModManager:GetEnabledServerModNames()) do
                local unload_fn = unload_fns[modname]
                if unload_fn then unload_fn() end
                local unload_any_fn = unload_any_fns[modname]
                if unload_any_fn then unload_any_fn(nil) end
            end
            frontend_envs = {}
        else
            if _modname == GEMENV.modname then
                GEMCOREFRONTENDLOADED = false
            end
            local unload_fn = unload_fns[_modname]
            if unload_fn then unload_fn() end
            for i, modname in ipairs(ModManager:GetEnabledServerModNames()) do
                local unload_any_fn = unload_any_fns[modname]
                if unload_any_fn then unload_any_fn(_modname) end
            end
            frontend_envs[_modname] = nil
        end
        return _FrontendUnloadMod(self, _modname, ...)
    end
end