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
local MakeGemFunction, DeleteGemFunction = gemrun("gemfunctionmanager")
MakeGemFunction("overridesblocker", function(functionname, overrides, modname, overrides_to_block, updateanyways)
    if not overrides then return end
    overrides.blockoverrides = overrides.blockoverrides or {}
    overrides.blockoverrides[modname] = overrides.blockoverrides[modname] or {}
    if overrides_to_block == true then
        --true means block ALL overrides...
        overrides.blockoverrides[modname] = true
    elseif type(overrides.blockoverrides[modname]) == "table" then
        for i, override in ipairs(overrides_to_block) do
            overrides.blockoverrides[modname][override] = true
        end
    end
    if updateanyways then
        overrides.updateanyways = overrides.updateanyways or {}
        overrides.updateanyways[modname] = overrides.updateanyways[modname] or {}
        if overrides_to_block == true then
            --true means block ALL overrides...
            overrides.updateanyways[modname] = true
        elseif type(overrides.updateanyways[modname]) == "table" then
            for i, override in ipairs(overrides_to_block) do
                overrides.updateanyways[modname][override] = true
            end
        end
    end
end, true)

local function ShouldUpdateOverride(overrides, override)
    local blocked = false
    for mod, blocker in pairs(overrides.blockoverrides or {}) do
        if blocker == true then
            blocked = true
        else
            blocked = blocker[override]
        end
        if blocked then break end
    end
    if blocked then
        for mod, allower in pairs(overrides.updateanyways or {}) do
            if allower == true then
                blocked = false
            else
                blocked = allower[override] ~= true
            end
            if not blocked then break end
        end
    end
    return not blocked
end

if not IsTheFrontEnd then
    require("shardindex")
    UpvalueHacker.SetUpvalue(ShardIndex.SetServerShardData, function(wgo)
        --we are only keeping the first part of this sanity check, since the otherone would clog loads of prints on something I am not doing(adding the WorldGenOptions stuff to the backend.)
        print("  sanity-checking worldgenoverride.lua...")
        local validfields = {
            overrides = true,
            preset = true,
            override_enabled = true,
        }
        for k,v in pairs(wgo) do
            if validfields[k] == nil then
                print(string.format("    WARNING! Found entry '%s' in worldgenoverride.lua, but this isn't a valid entry.", k))
            end
        end
    end, "GetWorldgenOverride", "SanityCheckWorldGenOverride")
    local Customise = require("map/customise")

    local _Save = ShardIndex.Save
    function ShardIndex:Save(callback, ...)
        local options = self:GetGenOptions()
        if options then
            local blockoverrides = options.overrides.blockoverrides
            local updateanyways = options.overrides.updateanyways
            options.overrides.blockoverrides = nil
            options.overrides.updateanyways = nil
            local _callback = callback
            callback = function(...)
                options.overrides.blockoverrides = blockoverrides
                options.overrides.updateanyways = updateanyways
                if _callback then
                    return _callback(...)
                end
            end
        end
        return _Save(self, callback, ...)
    end

    gemrun("onsavegame", function(callback, ...)
        local args = {...}
        local options = ShardGameIndex:GetGenOptions()
        local overrides = options and options.overrides or {}
        local _overrides = TheWorld.topology.overrides
        for k, v in pairs(_overrides) do
            if k ~= "original" and k ~= "blockoverrides" and k ~= "updateanyways" then
                if ShouldUpdateOverride(_overrides, k) then
                    overrides[k] = v
                end
            end
        end
        ShardGameIndex:Save(function() callback(unpack(args)) end)
    end)

    local function GenerateBlockedOverridesList(overrides)
        local blocklist = {}
        for mod, blockers in pairs(overrides.blockoverrides or {}) do
            if blockers == true then
                print(mod.." has blocked all overrides")
                blocklist = true
                break
            end
            for override in pairs(blockers) do
                print(mod.." has blocked override: "..override.." from being updated from leveldataoverride/worldgenoverride")
                blocklist[override] = overrides[override]
            end
        end
        return blocklist
    end

    gemrun("ondoinitgame", function(callback, savedata, profile, ...)
        ShardGameIndex:SetServerShardData(ShardGameIndex:GetGenOptions(), ShardGameIndex:GetServerData())

        local options = ShardGameIndex:GetGenOptions()

        local blocklist = GenerateBlockedOverridesList(savedata.map.topology.overrides)
        if blocklist ~= true and savedata.map.topology then
            local original = savedata.map.topology.overrides.original or {}
            original.original = nil
            savedata.map.topology.overrides = options and options.overrides or savedata.map.topology.overrides
            savedata.map.topology.overrides.original = original
        end
        --reset any blocked values to their pre blocked state.
        for k, v in pairs(blocklist ~= true and blocklist or {}) do
            savedata.map.topology.overrides[k] = v
        end

        --prune out the "default" options.
        for k, v in pairs(savedata.map.topology.overrides) do
            if k ~= "original" and k ~= "blockoverrides" and k ~= "updateanyways" then
                if v == Customise.GetDefaultForOption(k) then
                    savedata.map.topology.overrides[k] = nil
                end
            end
        end
        callback(savedata, profile, ...)
    end)
    return
end

local Customise = require("map/customise")

local GROUP = UpvalueHacker.GetUpvalue(Customise.ValidateOption, "GROUP")
local DEFAULT_GROUP = deepcopy(GROUP)

local defaultdescs = {}

defaultdescs.frequency_descriptions = deepcopy(GROUP.monsters.desc)
defaultdescs.starting_swaps_descriptions = deepcopy(GROUP.misc.items.prefabswaps_start.desc)
defaultdescs.petrification_descriptions = deepcopy(GROUP.misc.items.petrification.desc)
defaultdescs.speed_descriptions = deepcopy(GROUP.misc.items.regrowth.desc)
defaultdescs.disease_descriptions = deepcopy({
    { text = STRINGS.UI.SANDBOXMENU.QTYNONE, data = "none" },
    { text = STRINGS.UI.SANDBOXMENU.RANDOM, data = "random" },
    { text = STRINGS.UI.SANDBOXMENU.SLIDESLOW, data = "long" },
    { text = STRINGS.UI.SANDBOXMENU.SLIDEDEFAULT, data = "default" },
    { text = STRINGS.UI.SANDBOXMENU.SLIDEFAST, data = "short" },
})
defaultdescs.day_descriptions = deepcopy(GROUP.misc.items.day.desc)
defaultdescs.season_length_descriptions = deepcopy(GROUP.misc.items.autumn.desc)
defaultdescs.season_start_descriptions = deepcopy(GROUP.misc.items.season_start.desc)
defaultdescs.size_descriptions = deepcopy(GROUP.misc.items.world_size.desc)
defaultdescs.branching_descriptions = deepcopy(GROUP.misc.items.branching.desc)
defaultdescs.loop_descriptions = deepcopy(GROUP.misc.items.loop.desc)
defaultdescs.complexity_descriptions = deepcopy({
    {text = STRINGS.UI.SANDBOXMENU.SLIDEVERYSIMPLE, data = "verysimple"},
    {text = STRINGS.UI.SANDBOXMENU.SLIDESIMPLE, data = "simple"},
    {text = STRINGS.UI.SANDBOXMENU.SLIDEDEFAULT, data = "default"},
    {text = STRINGS.UI.SANDBOXMENU.SLIDECOMPLEX, data = "complex"},
    {text = STRINGS.UI.SANDBOXMENU.SLIDEVERYCOMPLEX, data = "verycomplex"},
})
defaultdescs.specialevent_descriptions = deepcopy(GROUP.misc.items.specialevent.desc)
defaultdescs.yesno_descriptions = deepcopy({
    {text = STRINGS.UI.SANDBOXMENU.YES, data = "default"},
    {text = STRINGS.UI.SANDBOXMENU.NO, data = "never"},
})

--HELPER FUNCTIONS
local function GetServerCreationScreen()
    for _, screen_in_stack in pairs(TheFrontEnd.screenstack) do
        if screen_in_stack.name == "ServerCreationScreen" then
            return screen_in_stack
        end
    end
end

local function RefreshWorldTabs()
    local servercreationscreen = GetServerCreationScreen()
    if servercreationscreen then
        for k, v in pairs(servercreationscreen.world_tabs) do
            v:Refresh()
        end
    end
end

local function LoadBackendSetTweaks(worldcustomizationtab)
    local self = worldcustomizationtab

    --somehow sometimes caves exist on worlds where caves are disabled, don't ask me how, this check should fix that.
    if not ShardSaveGameIndex:IsSlotEmpty(self.slot) and self.current_option_settings[self.tab_location_index] ~= nil then
        local session_id = ShardSaveGameIndex:GetSlotSession(self.slot, self.tab_location_index == 1 and "Master" or "Caves")
        local meta
        local prefab
        if session_id ~= nil then
            local function onreadworldfile(success, str)
                if success and str ~= nil and #str > 0 then
                    local success, savedata = RunInSandbox(str)
                    if success and savedata ~= nil and GetTableSize(savedata) > 0 then
                        meta = savedata.meta
                        prefab = savedata.map.prefab
                    end
                end
            end
            if ShardSaveGameIndex:IsSlotMultiLevel(self.slot) or not ShardSaveGameIndex:GetSlotServerData(self.slot).use_legacy_session_path then
                local shard = self.tab_location_index == 1 and "Master" or "Caves"
                local file = TheNet:GetWorldSessionFileInClusterSlot(self.slot,  shard, session_id)
                if file ~= nil then
                    TheSim:GetPersistentStringInClusterSlot(self.slot, shard, file, onreadworldfile)
                end
            else
                local file = TheNet:GetWorldSessionFile(session_id)
                if file ~= nil then
                    TheSim:GetPersistentString(file, onreadworldfile)
                end
            end
        end

         --SPECIAL THING SO WORLDSEEDS GET PROPERLY LOADED
        local options = ShardSaveGameIndex:GetSlotGenOptions(self.slot)
        local overrides = options and options.overrides
        print(overrides.worldseed, tonumber(overrides.worldseed) or hash(overrides.worldseed), meta and meta.seed)
        if overrides.worldseed and (tonumber(overrides.worldseed) or hash(overrides.worldseed)) == (meta and meta.seed or nil) then
            overrides.worldseed = overrides.worldseed
        else
            overrides.worldseed = meta and meta.seed or "WORLD SEED NOT FOUND"
        end

        local FIRST_VALID_BUILD_VERSION = 435008 --this is the first build that has the fixed worldgen so its not completly random.
        if meta and (tonumber(meta.build_version) or 0) < FIRST_VALID_BUILD_VERSION then
            print((prefab or "unknown").." world's build version is: "..meta.build_version.." needs to be greater than "..FIRST_VALID_BUILD_VERSION)
            print("worldseed is: "..worldseed)
            overrides.worldseed = "WORLD VERSION IS TOO OLD"
        end

        for k, v in pairs(overrides) do
            if k ~= "original" and k ~= "blockoverrides" and k ~= "updateanyways" then
                if ShouldUpdateOverride(overrides, k) then
                    self:SetTweak(self.tab_location_index, k, v)
                end
            end
        end
    end
end

local function GetNewGroupNumber()
    local max = 0
    for k, v in pairs(GROUP) do
        max = math.max(max, v.order)
    end
    return max + 1
end

local function GetNewItemNumber(GROUPNAME)
    local max = 0
    for k, v in pairs(GROUP[GROUPNAME].items) do
        max = math.max(max, v.order)
    end
    return max + 1
end

local function FixGroupOrder()
    local groups = {}
    for k,v in pairs(GROUP) do
        table.insert(groups,k)
    end
    table.sort(groups, function(a,b) return GROUP[a].order < GROUP[b].order end)
    for i, groupname in ipairs(groups) do
        GROUP[groupname].order = i
    end
end

local function FixItemOrder(GROUPNAME)
    local items = {}
    for k,v in pairs(GROUP[GROUPNAME].items) do
        table.insert(items, k)
    end
    table.sort(items, function(a,b) return GROUP[GROUPNAME].items[a].order < GROUP[GROUPNAME].items[b].order end)
    for i, itemname in ipairs(items) do
        GROUP[GROUPNAME].items[itemname].order = i
    end
end

local function MakeGroupItemList()
    local list = {}
    list.groups = {}
    list.items = setmetatable({}, {
        __index = function(items, groupname)
            rawset(items, groupname, setmetatable({_ = {}}, {
                __index = function(t, k)
                    local v = rawget(t, "_")[k]
                    if GetTableSize(rawget(t, "_")) == 0 then
                        rawset(items, groupname, nil)
                    end
                    return v
                end,
                __newindex = function(t, k, v)
                    rawset(t, "_")[k] = v
                    if GetTableSize(rawget(t, "_")) == 0 then
                        rawset(items, groupname, nil)
                    end
                end
            }))
            return rawget(items, groupname)
        end,
    })
    return list
end
--END HELPER FUNCTIONS

FixGroupOrder()
for k, v in pairs(GROUP) do
    FixItemOrder(k)
end
RefreshWorldTabs()
do
    local servercreationscreen = GetServerCreationScreen()
    if servercreationscreen then
        for i, tab in ipairs(servercreationscreen.world_tabs) do
            LoadBackendSetTweaks(tab)
            if tab.customizationlist ~= nil then
                tab.customizationlist.scroll_list:RefreshView()
            end
        end 
    end
end

local CUSTOMGROUPLABELS = {}

local modifiers = {}
--PUBLIC INTERFACE
local WorldGenOptions = Class(function(self, modname)
    assert(KnownModIndex:DoesModExistAnyVersion(modname), "modname "..modname.." must refer to a valid mod!")
    self.modname = modname
    modifiers[modname] = {
        wgo = self,
        added = MakeGroupItemList(),
        removed = MakeGroupItemList(),
        reorder = MakeGroupItemList(),
        modified_properties = MakeGroupItemList(),
        modified_values = MakeGroupItemList(),
    }
    function self:GetModifier()
        return modifiers[modname]
    end
end, nil, {})

function WorldGenOptions:AddGroup(GROUPNAME, groupsettings)
    if groupsettings.customtext then
        CUSTOMGROUPLABELS[GROUPNAME] = groupsettings.customtext
        groupsettings.text = groupsettings.customtext
    end
    groupsettings.order = GetNewGroupNumber()
    GROUP[GROUPNAME] = groupsettings

    --self:GetModifier().added.groups[GROUPNAME] = true
    --remove this from the removed list if it was added back by this mod.
    --self:GetModifier().removed.groups[GROUPNAME] = nil

    FixItemOrder(GROUPNAME)
    RefreshWorldTabs()
end

function WorldGenOptions:AddItemToGroup(GROUPNAME, ITEMNAME, itemsettings)
    itemsettings.order = GetNewItemNumber(GROUPNAME)
    GROUP[GROUPNAME].items[ITEMNAME] = itemsettings

    --self:GetModifier().added.items[GROUPNAME][ITEMNAME] = true
    --remove this from the removed list if it was added back by this mod.
    --self:GetModifier().removed.items[GROUPNAME][ITEMNAME] = nil

    RefreshWorldTabs()
end

function WorldGenOptions:RemoveGroup(GROUPNAME)
    GROUP[GROUPNAME] = nil

    --if this mod added the group, just remove it from the added list, otherwise mark this as a removed group.
    --if --self:GetModifier().added.groups[GROUPNAME] then
        --self:GetModifier().added.groups[GROUPNAME] = nil
    --else
        --self:GetModifier().removed.groups[GROUPNAME] = true
    --end

    FixGroupOrder()
    RefreshWorldTabs()
end

function WorldGenOptions:RemoveItemFromGroup(GROUPNAME, ITEMNAME)
    GROUP[GROUPNAME].items[ITEMNAME] = nil
    --if this mod added the item, just remove it from the added list, otherwise mark this as a removed item.
    --if --self:GetModifier().added.items[GROUPNAME][ITEMNAME] then
        --self:GetModifier().added.items[GROUPNAME][ITEMNAME] = nil
    --else
        --self:GetModifier().removed.items[GROUPNAME][ITEMNAME] = true
    --end
    FixItemOrder(GROUPNAME)
    RefreshWorldTabs()
end

function WorldGenOptions:ReorderGroup(GROUPNAME, TARGETGROUPNAME, moveafter)
    GROUP[GROUPNAME].order = GROUP[TARGETGROUPNAME].order + (moveafter and 0.1 or -0.1)
    FixGroupOrder()
    RefreshWorldTabs()
end

function WorldGenOptions:ReorderItem(GROUPNAME, ITEMNAME, TARGETITEMNAME, moveafter)
    GROUP[GROUPNAME].items[ITEMNAME].order = GROUP[GROUPNAME].items[TARGETITEMNAME].order + (moveafter and 0.1 or -0.1)
    FixItemOrder(GROUPNAME)
    RefreshWorldTabs()
end

local blacklist = {
    ["order"] = true,
    ["items"] = true,
}

function WorldGenOptions:SetGroupProperty(GROUPNAME, property, value)
    if not blacklist[property] then
        GROUP[GROUPNAME][property] = value
    end
    RefreshWorldTabs()
end

function WorldGenOptions:SetItemProperty(GROUPNAME, ITEMNAME, property, value)
    if not blacklist[property] then
        GROUP[GROUPNAME].items[ITEMNAME][property] = value
    end
    if property == "alwaysedit" or property == "neveredit" then
        local servercreationscreen = GetServerCreationScreen()
        if servercreationscreen then
            for i, tab in ipairs(servercreationscreen.world_tabs) do
                if tab.customizationlist ~= nil then
                    for k, v in pairs(tab.customizationlist.options) do
                        if v.group == GROUPNAME and v.name == ITEMNAME then
                            v[property] = value
                            break
                        end
                    end
                    tab.customizationlist.scroll_list:RefreshView()
                end
            end 
        end
    else
        RefreshWorldTabs()
    end
end

function WorldGenOptions:GetGroupProperty(GROUPNAME, property)
    if not blacklist[property] then
        return GROUP[GROUPNAME][property]
    end
end

function WorldGenOptions:GetItemProperty(GROUPNAME, ITEMNAME, property)
    if not blacklist[property] then
        return GROUP[GROUPNAME].items[ITEMNAME][property]
    end
end

local event_listeners = {}

function WorldGenOptions:ListenForEvent(modname, event, fn)
    if not fn then
        fn = event
        event = modname
        modname = self.modname
    end
    if not event_listeners[modname] then
        event_listeners[modname] = {}
    end
    if not event_listeners[modname][event] then
        event_listeners[modname][event] = {}
    end
    table.insert(event_listeners[modname][event], fn)
end

function WorldGenOptions:RemoveEventCallback(modname, event, fn)
    if not fn then
        fn = event
        event = modname
        modname = self.modname
    end
    table.removearrayvalue(event_listeners[modname] and event_listeners[modname][event] or {}, fn)
    if GetTableSize(event_listeners[modname] and event_listeners[modname][event]) == 0 then
        event_listeners[modname][event] = nil
    end
    if GetTableSize(event_listeners[modname]) == 0 then
        event_listeners[modname] = nil
    end
end

function WorldGenOptions:SetOptionValue(location, option, value)
    local servercreationscreen = GetServerCreationScreen()
    if servercreationscreen then
        for i, tab in ipairs(servercreationscreen.world_tabs) do
            if location == tab:GetLocationForLevel(tab.currentmultilevel) then
                if tab.customizationlist ~= nil then
                    tab.customizationlist:SetValueForOption(option, value)
                    tab.current_option_settings[tab.currentmultilevel].tweaks[option] = value
                end
            end 
        end
    end
end

function WorldGenOptions:GetOptionValue(location, option)
    local servercreationscreen = GetServerCreationScreen()
    if servercreationscreen then
        for i, tab in ipairs(servercreationscreen.world_tabs) do
            if location == tab:GetLocationForLevel(tab.currentmultilevel) then
                if tab.customizationlist ~= nil then
                    for i, data in pairs(tab.customizationlist.optionitems) do
                        if data.option and data.option.name == option then
                            return data.selection
                        end
                    end
                end
            end
        end
    end
end

function WorldGenOptions:__index(name)
    return defaultdescs[name] == nil and getmetatable(self)[name] or deepcopy(defaultdescs[name])
end
--END PUBLIC INTERFACE

local function PushWorldGenEvent(event, ...)
    for modname, listeners in pairs(event_listeners) do
        for i, fn in ipairs(listeners[event] or {}) do
            fn(...)
        end
    end
end

--FUNCTION REPLACEMENTS
local FrontendHelper = gemrun("tools/frontendhelper", GEMENV.modname)

FrontendHelper.ReplaceFunction(Customise, "GetOptions", function(_GetOptions, ...)
    local options = _GetOptions(...)
    for i, v in ipairs(options) do
        options[i].widget_type = GROUP[v.group].items[v.name].widget_type or "optionsspinner"
        options[i].options_remap = GROUP[v.group].items[v.name].options_remap or nil
        options[i].atlas = GROUP[v.group].items[v.name].atlas or nil
        options[i].alwaysedit = GROUP[v.group].items[v.name].alwaysedit or nil
        options[i].neveredit = GROUP[v.group].items[v.name].neveredit or nil
    end
    return options
end)

FrontendHelper.DoOnce(UpvalueHacker.SetUpvalue, Customise.GetOptionsWithLocationDefaults, function(...)
    return Customise.GetOptions(...)
end, "GetOptions")

FrontendHelper.ReplaceFunction(string, "format", function(_stringformat, fmt, opt1, opt2, opt3, ...)
    if fmt == "%s %s" and table.contains(STRINGS.UI.SANDBOXMENU.LOCATION, opt1) and table.contains(CUSTOMGROUPLABELS, opt2) and opt3 == nil then
        fmt = "%s"
        return _stringformat(fmt, opt2)
    end
    return _stringformat(fmt, opt1, opt2, opt3, ...)
end)

local ServerCreationScreen = require("screens/redux/servercreationscreen")

FrontendHelper.ReplaceFunction(ServerCreationScreen, "OnBecomeActive", function(_OnBecomeActive, self, ...)
    local retval = {_OnBecomeActive(self, ...)}
    PushWorldGenEvent("becomeactive", self)
    return unpack(retval)
end)

local WorldCustomizationTab = require("widgets/redux/worldcustomizationtab")

FrontendHelper.ReplaceFunction(WorldCustomizationTab, "AddMultiLevel", function(_AddMultiLevel, self, level, ...)
    PushWorldGenEvent("addlocation", self:GetLocationForLevel(level))
    return _AddMultiLevel(self, level, ...)
end)

FrontendHelper.ReplaceFunction(WorldCustomizationTab, "RemoveMultiLevel", function(_RemoveMultiLevel, self, level, ...)
    PushWorldGenEvent("removelocation", self:GetLocationForLevel(level))
    return _RemoveMultiLevel(self, level, ...)
end)

local worldoptions

FrontendHelper.ReplaceFunction(WorldCustomizationTab, "CollectOptions", function(_CollectOptions, self, ...)
    --incase CollectOptions is overriden multiple times
    local stacklevel = 2
    local tabidx
    while debug.getinfo(stacklevel, "n") ~= nil do
        worldoptions = LocalVariableHacker.GetLocalVariable(stacklevel, "worldoptions")
        tabidx = LocalVariableHacker.GetLocalVariable(stacklevel, "i")
        if worldoptions ~= nil and tabidx ~= nil then
            break
        end
        stacklevel = stacklevel + 1
    end
    if tabidx == GetTableSize(self.servercreationscreen.world_tabs) then
        local ret = _CollectOptions(self, ...)
        worldoptions[tabidx] = ret
        PushWorldGenEvent("postcollectoptions", worldoptions)
        return ret
    end
    return _CollectOptions(self, ...)
end)

FrontendHelper.ReplaceFunction(WorldCustomizationTab, "LoadPreset", function(_LoadPreset, self, preset, ...)
    local retvals = {_LoadPreset(self, preset, ...)}
    PushWorldGenEvent("loadpreset", preset, self.current_option_settings[self.tab_location_index].preset)
    return unpack(retvals)
end)

FrontendHelper.ReplaceFunction(SystemService, "StartDedicatedServers", function(_StartDedicatedServers, self, ...)
    worldoptions = nil
    return _StartDedicatedServers(self, ...)
end)

FrontendHelper.ReplaceFunction(ShardGameIndex, "Save", function(_Save, self, ...)
    --we don't ever want this getting saved to the shardindex
    local options = self:GetGenOptions()
    for location_index, option in ipairs(options or {}) do
        option.overrides.blockoverrides = nil
        option.overrides.updateanyways = nil
    end
    return _Save(self, ...)
end)

local loadbackendsettweaks = false

FrontendHelper.ReplaceFunction(WorldCustomizationTab, "UpdateSlot", function(_UpdateSlot, self, slotnum, prevslot, delete, ...)
    loadbackendsettweaks = true
    return _UpdateSlot(self, slotnum, prevslot, delete, ...)
end)

FrontendHelper.ReplaceFunction(WorldCustomizationTab, "Refresh", function(_Refresh, self, ...)
    if loadbackendsettweaks then
        loadbackendsettweaks = false
        LoadBackendSetTweaks(self)
    end
    return _Refresh(self, ...)
end)
--END FUNCTION REPLACEMENTS

FrontendHelper.DoOnce(GEMENV.AddClassPostConstruct, "widgets/redux/worldcustomizationlist", function(inst)
    local _spinnerCB = inst.spinnerCB
    function inst.spinnerCB(option, value, ...)
        PushWorldGenEvent("anyoptionchange", inst.location, option, value)
        PushWorldGenEvent(option.."optionchange", inst.location, value)
        return _spinnerCB(option, value, ...)
    end

    local _update_fn = inst.scroll_list.update_fn
    function inst.scroll_list.update_fn(context, widget, data, index, ...)
        local retval = {_update_fn(context, widget, data, index, ...)}
        if not data or data.is_empty then
            return unpack(retval)
        end

        if data.heading_text then
            return unpack(retval)
        end
        if data.option.neveredit then
            widget.opt_spinner.spinner:SetEditable(false)
        else
            widget.opt_spinner.spinner:SetEditable(inst.allowEdit or data.option.alwaysedit)
        end
        return unpack(retval)
    end
end)

gemrun("unloadmodany", function(modname)
    if modname then
        event_listeners[modname] = nil
    end
end)

gemrun("unloadgemcore", function()
    for k in pairs(GROUP) do
        GROUP[k] = nil
    end
    for k, v in pairs(DEFAULT_GROUP) do
        GROUP[k] = deepcopy(v)
    end
    RefreshWorldTabs()
    event_listeners = {}
end)

local memoized_wgo = {}

local args = {...}
local functionname = args[1]
local modname = args[2]

MakeGemFunction(functionname, function(fname, mname, ...)
    memoized_wgo[mname] = memoized_wgo[mname] or WorldGenOptions(mname)
    return memoized_wgo[mname]
end, true)

memoized_wgo[modname] = WorldGenOptions(modname)
return memoized_wgo[modname]