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
gemrun("gemdictionary/ingredient")
gemrun("gemdictionary/recipe")
gemrun("gemdictionary/ui")
gemrun("gemdictionary/loot")
local IngredientAllocator = gemrun("gemdictionary/ingredientallocator")

-- CONTAINER --
local function FindItems_Container(inst, fn)
    local items = {}
    for i, v in ipairs(inst._items) do
        local item = (inst._itemspreview and inst._itemspreview[i]) or (not inst._itemspreview and v:value()) or nil
        if item ~= nil and fn(item) then
            table.insert(items, item)
        end
    end
    return items
end

GEMENV.AddPrefabPostInit("container_classified", function(inst)
    if not TheWorld.ismastersim then
        inst.FindItems = FindItems_Container

        local SlotItem = UpvalueHacker.GetUpvalue(inst.ConsumeByName, "SlotItem")
        local PushItemLose = UpvalueHacker.GetUpvalue(inst.ConsumeByName, "PushItemLose")
        local PushStackSize = UpvalueHacker.GetUpvalue(inst.ConsumeByName, "PushStackSize")
        function inst.ConsumeByItem(inst, item, amount)
            if amount <= 0 then
                return
            end

            for i, v in ipairs(inst._items) do
                local _item = v:value()
                if _item == item then
                    local stacksize = item.replica.stackable ~= nil and item.replica.stackable:StackSize() or 1
                    if stacksize <= amount then
                        PushItemLose(inst, SlotItem(item, i))
                    else
                        PushStackSize(inst, nil, item, stacksize - amount, true)
                    end
                    return
                end
            end
        end
    end
end)

local Container_Replica = require("components/container_replica")

function Container_Replica:FindItems(fn)
    if self.inst.components.container ~= nil then
        return self.inst.components.container:FindItems(fn)
    elseif self.classified ~= nil then
        return self.classified:FindItems(fn)
    else
        return {}
    end
end
-- CONTAINER END --

-- INVENTORY --
local function FindItems_Inventory(inst, fn)
    local items = {}

    for i, v in ipairs(inst._items) do
        local item = (inst._itemspreview and inst._itemspreview[i]) or (not inst._itemspreview and v:value()) or nil
        if item ~= nil and (inst._itemspreview ~= nil or item ~= inst._activeitem) and fn(item) then
            table.insert(items, item)
        end
    end

    if inst._activeitem and fn(inst._activeitem) then
        table.insert(items, inst._activeitem)
    end

    local overflow = inst:GetOverflowContainer()
    if overflow ~= nil then
        for k, v in pairs(overflow:FindItems(fn)) do
            table.insert(items, v)
        end
    end

    return items
end

GEMENV.AddPrefabPostInit("inventory_classified", function(inst)
    if not TheWorld.ismastersim then
        inst.FindItems = FindItems_Inventory

        local SlotItem = UpvalueHacker.GetUpvalue(inst.RemoveIngredients, "ConsumeByName", "SlotItem")
        local PushItemLose = UpvalueHacker.GetUpvalue(inst.RemoveIngredients, "ConsumeByName", "PushItemLose")
        local PushStackSize = UpvalueHacker.GetUpvalue(inst.RemoveIngredients, "ConsumeByName", "PushStackSize")
        local PushNewActiveItem = UpvalueHacker.GetUpvalue(inst.RemoveIngredients, "ConsumeByName", "PushNewActiveItem")
        function inst.ConsumeByItem(inst, item, amount, overflow)
            if amount <= 0 then
                return
            end

            for i, v in ipairs(inst._items) do
                local _item = v:value()
                if _item == item then
                    local stacksize = item.replica.stackable ~= nil and item.replica.stackable:StackSize() or 1
                    if stacksize <= amount then
                        PushItemLose(inst, SlotItem(item, i))
                    else
                        PushStackSize(inst, item, stacksize - amount, true)
                    end
                    return
                end
            end

            if inst._activeitem == item then
                local stacksize = inst._activeitem.replica.stackable ~= nil and inst._activeitem.replica.stackable:StackSize() or 1
                if stacksize <= amount then
                    PushNewActiveItem(inst)
                else
                    PushStackSize(inst, item, stacksize - amount, true)
                end
                return
            end

            if overflow ~= nil then
                overflow:ConsumeByItem(item, amount)
            end
        end

        local _RemoveIngredients = inst.RemoveIngredients
        function inst.RemoveIngredients(inst, recipe, ingredientmod, ...)
            if inst:IsBusy() then
                return false
            end
            local overflow = inst:GetOverflowContainer()
            overflow = overflow and overflow.classified or nil
            if overflow ~= nil and overflow:IsBusy() then
                return false
            end
            local ingredients = IngredientAllocator(recipe):GetRecipeIngredients(inst._parent, ingredientmod)
            for item, ents in pairs(type(ingredients) ~= "table" and {} or ingredients) do
                for k, v in pairs(ents) do
                    inst:ConsumeByItem(k, v, overflow)
                end
            end
            return true
        end
    end
end)

local Inventory_Replica = require("components/inventory_replica")

function Inventory_Replica:FindItems(fn)
    if self.inst.components.inventory ~= nil then
        return self.inst.components.inventory:FindItems(fn)
    elseif self.classified ~= nil then
        return self.classified:FindItems(fn)
    else
        return {}
    end
end
-- INVENTORY END --

-- BUILDER --
local Builder = require("components/builder")

local _GetIngredients = Builder.GetIngredients
function Builder:GetIngredients(recname, ...)
    local recipe = AllRecipes[recname]
    if recipe then
        local ingredients
        ingredients, self.ingredientsdata = IngredientAllocator(recipe):GetRecipeIngredients(self.inst, self.ingredientmod)
        return type(ingredients) ~= "table" and {} or ingredients
    end
end

local _Builder_CanBuild = Builder.CanBuild
function Builder:CanBuild(recname, ...)
    local can_build = _Builder_CanBuild(self, recname, ...)
    if can_build then
        local recipe = GetValidRecipe(recname)
        if recipe ~= nil and not self.freebuildmode and recipe:HasGemDictIngredients() and not IngredientAllocator(recipe):GetRecipeIngredients(self.inst, self.ingredientmod, true) then
            return false
        end
    end
    return can_build
end

local _Builder_DoBuild = Builder.DoBuild
function Builder:DoBuild(recname, pt, rotation, skin, ...)
    local recipe = GetValidRecipe(recname)
    local _product
    if recipe then
        _product = rawget(recipe, "product")
        recipe.product = gemrun("getspecialprefab", recipe.product, function(pref)
            if self.ingredientsdata then
                pref:AddComponentAtRuntime("gemdict_craftinginfo")
                pref.components.gemdict_craftinginfo.ingredientsdata = self.ingredientsdata
            end
            for i, v in ipairs(recipe.modifiedoutputfns or {}) do
                v(pref)
            end
        end)
    end
    local retvals = {_Builder_DoBuild(self, recname, pt, rotation, skin, ...)}
    if _product then
        gemrun("getspecialprefab", recipe.product)
        recipe.product = _product
    end
    self.ingredientsdata = nil
    return unpack(retvals)
end

local _Builder_OnSave = Builder.OnSave
function Builder:OnSave(...)
    local retvals = {_Builder_OnSave(self, ...)}
    local data = retvals[1]
    data.gemdict_buffered_builds = self.gemdict_buffered_builds
    return unpack(retvals)
end

local _Builder_OnLoad = Builder.OnLoad
function Builder:OnLoad(data, ...)
    _Builder_OnLoad(self, data, ...)
    for k, v in pairs(data.gemdict_buffered_builds or {}) do
        if self:IsBuildBuffered(k) then
            self.gemdict_buffered_builds[k] = v
        end
    end
end

GEMENV.AddComponentPostInit("builder", function(self)
    self.gemdict_buffered_builds = {}
end)

local Builder_Replica = require("components/builder_replica")

local _Builder_Replica_CanBuild = Builder_Replica.CanBuild
function Builder_Replica:CanBuild(recname, ...)
    local can_build = _Builder_Replica_CanBuild(self, recname, ...)
    if can_build and self.inst.components.builder == nil and self.classified ~= nil then
        local recipe = GetValidRecipe(recname)
        if recipe ~= nil and not self.classified.isfreebuildmode:value() and recipe:HasGemDictIngredients() and not IngredientAllocator(recipe):GetRecipeIngredients(self.inst, self:IngredientMod(), true) then
            return false
        end
    end
    return can_build
end

local _Builder_Replica_SetIsBuildBuffered = Builder_Replica.SetIsBuildBuffered
function Builder_Replica:SetIsBuildBuffered(recipename, isbuildbuffered, ...)
    local builder = self.inst.components.builder
    if builder then
        if isbuildbuffered == true and builder.ingredientsdata then
            builder.gemdict_buffered_builds[recipename] = builder.ingredientsdata
            builder.ingredientsdata = nil
        elseif builder.gemdict_buffered_builds[recipename] then
            builder.ingredientsdata = builder.gemdict_buffered_builds[recipename]
            builder.gemdict_buffered_builds[recipename] = nil
        end
    end
    return _Builder_Replica_SetIsBuildBuffered(self, recipename, isbuildbuffered, ...)
end

-- BUILDER END --