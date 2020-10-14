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

local permodconfigs = {}
local function GeneratePerModConfigOptions(_modname)
    local configsets = {}
    for optionname, data in pairs(permodconfigs[_modname] or {}) do
        local moddirnames = TheSim:GetModDirectoryNames()
        local configdata = {}
        for _, modname in ipairs(moddirnames) do
            if not (data.options.exclude_self and _modname == modname) then
                local modinfo = KnownModIndex:GetModInfo(modname)
                if modinfo and (not data.options.client_only or modinfo.client_only_mod) and (not data.options.server_only or not modinfo.client_only_mod) then
                    local config = deepcopy(data.template)
                    config.label = modinfo.name
                    config.name = optionname:gsub(" ", "_")..modname:gsub(" ", "_")
                    table.insert(configdata, config)
                end
            end
        end

        table.sort(configdata, function(a,b)
            if not a.label then return false end
            if not b.label then return true end
            return string.lower(a.label) < string.lower(b.label)
        end)
        if data.options.master_override then
            local master_override = deepcopy(data.options.master_override)
            master_override.label = "Master Option"
            master_override.name = optionname:gsub(" ", "_").."master_override"
            master_override.hover = "Sets the default value for every mod."
            table.insert(configdata, 1, master_override)
        end
        table.insert(configdata, 1, {
            name = optionname..":",
            options = {{description="", data=false}},
            default = false,
        })
        table.insert(configsets, configdata)
    end
    return configsets
end

--mostly copied from modindex@line323
local function RefreshModConfigOptions(modname)
    local env = (KnownModIndex:LoadModOverides() or {})[modname]
    if env and env.configuration_options ~= nil then
        local actual_modname = ResolveModname(modname)
        if actual_modname ~= nil then
            local force_local_options = true
            local config_options, _ = KnownModIndex:GetModConfigurationOptions_Internal(actual_modname,force_local_options)
            if config_options and type(config_options) == "table" then
                for option, override in pairs(env.configuration_options) do
                    for _, config_option in pairs(config_options) do
                        if config_option.name == option then
                            config_option.saved = override
                        end
                    end
                end
            end
        end
    end
end

local function ApplyPerModConfigOptions(modname)
    local _info = KnownModIndex:GetModInfo(modname)
    _info.configuration_options = _info.configuration_options or {}
    _info.gemcore_configuration_start = _info.gemcore_configuration_start or #_info.configuration_options
    if #_info.configuration_options == _info.gemcore_configuration_start then
        for i, v in ipairs(GeneratePerModConfigOptions(modname)) do
            for i1, v1 in ipairs(v) do
                table.insert(_info.configuration_options, v1)
            end
        end
        RefreshModConfigOptions(modname)
    end
    return _info
end

local function ShouldSaveGemConfig(modname, configdata)
    if not (KnownModIndex:IsModEnabled(modname) or KnownModIndex:IsModForceEnabled(modname)) then
        return false
    end
    if not permodconfigs[modname] then
        return false
    end
    local _info = ApplyPerModConfigOptions(modname)
    for k, v in pairs(configdata) do
        if v.name == _info.configuration_options[#_info.configuration_options].name and v.saved ~= nil then
            return true
        end
    end
    return false
end

local add_gem_path = false

local function LoadGemCoreModConfigurationOptions(_LoadModConfigurationOptions, self, modname, client_config, ...)
    local known_mod = self.savedata.known_mods[modname]
    if known_mod == nil then
        return _LoadModConfigurationOptions(self, modname, client_config, ...)
    end

    -- Try to find saved config settings first
    add_gem_path = true
    local filename = self:GetModConfigurationPath(modname, client_config)
    add_gem_path = false

    _LoadModConfigurationOptions(self, modname, client_config, ...)
    TheSim:GetPersistentString(filename, function(load_success, str)
        if load_success == true then
            local success, savedata = RunInSandboxSafe(str)
            if success and string.len(str) > 0 then
                -- Carry over saved data from old versions when possible
                if self:HasModConfigurationOptions(modname) then
                    self:UpdateConfigurationOptions(known_mod.modinfo.configuration_options, savedata)
                end
            end
        end
    end)

    if known_mod and known_mod.modinfo and known_mod.modinfo.configuration_options then
        return known_mod.modinfo.configuration_options
    end
    return nil
end

if IsTheFrontEnd then
    local ModsTab = require("widgets/redux/modstab")
    local FrontendHelper = gemrun("tools/frontendhelper", GEMENV.modname)

    FrontendHelper.ReplaceFunction(ModsTab, "ShowModDetails", function(_ShowModDetails, self, widget_idx, client_mod, ...)
        local items_table = client_mod and self.optionwidgets_client or self.optionwidgets_server
        local modnames_versions = client_mod and self.modnames_client or self.modnames_server

        local idx = items_table[widget_idx] and items_table[widget_idx].index or nil
        local modname = idx and modnames_versions[idx] and modnames_versions[idx].modname or nil

        if modname then
            ApplyPerModConfigOptions(modname)
        end
        return _ShowModDetails(self, widget_idx, client_mod, ...)
    end)

    FrontendHelper.ReplaceFunction(KnownModIndex, "SaveConfigurationOptions", function(_SaveConfigurationOptions, self, callback, modname, configdata, ...)
        if ShouldSaveGemConfig(modname, configdata) then
            print("saving _gemcore configuration_options")
            --save a second one with _gemcore as its save path.
            add_gem_path = true
            _SaveConfigurationOptions(self, function()end, modname, configdata, ...)
            add_gem_path = false
        end
        return _SaveConfigurationOptions(self, callback, modname, configdata, ...)
    end)

    FrontendHelper.ReplaceFunction(KnownModIndex, "LoadModConfigurationOptions", function(_LoadModConfigurationOptions, self, modname, ...)
        ApplyPerModConfigOptions(modname)
        return LoadGemCoreModConfigurationOptions(_LoadModConfigurationOptions, self, modname, ...)
    end)

    FrontendHelper.ReplaceFunction(KnownModIndex, "GetModConfigurationPath", function(_GetModConfigurationPath, self, modname, ...)
        local path = _GetModConfigurationPath(self, modname, ...)
        if modname and add_gem_path then
            path = path.."_gemcore"
        end
        return path
    end)
else
    local _LoadModConfigurationOptions = KnownModIndex.LoadModConfigurationOptions
    function KnownModIndex:LoadModConfigurationOptions(modname, ...)
        ApplyPerModConfigOptions(modname)
        return LoadGemCoreModConfigurationOptions(_LoadModConfigurationOptions, self, modname, ...)
    end

    local _GetModConfigurationPath = KnownModIndex.GetModConfigurationPath
    function KnownModIndex:GetModConfigurationPath(modname, ...)
        local path = _GetModConfigurationPath(self, modname, ...)
        if modname and add_gem_path then
            path = path.."_gemcore"
        end
        return path
    end
end

--[[
template = {
    hover = "hover text",
    options = {
        {
            description = "description",
            data = false,
            hover = "hover text when disabled."
        },
        {
            description = "description",
            data = true,
            hover = "hover text when enabled."
        }
    },
    default = true,
}
]]

local MakeGemFunction = gemrun("gemfunctionmanager")
MakeGemFunction("addpermodconfig", function(functionname, modname, optionname, template, options, ...)
    local modconfig = permodconfigs[modname]
    if not modconfig then
        modconfig = {}
        permodconfigs[modname] = modconfig
    end
    modconfig[optionname] = {template = template, options = options or {}}
end, true)

function GetModModConfigData(optionname, modmodname, modname, get_local_config)
    --get_local_config probably won't ever be supported, since in order to save it I would need to have code running outside of ServerCreationScreen.
    ApplyPerModConfigOptions(modname)
    local value = GetModConfigData(optionname:gsub(" ", "_")..modmodname:gsub(" ", "_"), modname, false)
    if value == "default" then
        value = GetModConfigData(optionname:gsub(" ", "_").."master_override", modname, false)
    end
    return value
end