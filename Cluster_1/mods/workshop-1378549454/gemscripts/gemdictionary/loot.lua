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

local function defaultspawnfn(ingredient, amt, ingredientsdata, deconstructfn)
    local loots = {}

    if ingredientsdata[ingredient.signature or ingredient.type] then
        while amt > 0 do
            for i, v in ipairs(ingredientsdata[ingredient.signature or ingredient.type]) do
                local stack = v.data.stackable and v.data.stackable.stack or 1
                local _ingredientsdata = v.data.gemdict_craftinginfo and v.data.gemdict_craftinginfo.ingredientsdata
                for n = 1, stack do
                    if deconstructfn and ingredient.deconstruct then
                        for _, loot in ipairs(deconstructfn(AllRecipes[v.prefab], _ingredientsdata or {})) do
                            table.insert(loots, loot)
                        end
                    else
                        local prefab
                        prefab = not _ingredientsdata and v.prefab or gemrun("getspecialprefab", v.prefab, function(pref)
                            pref:AddComponentAtRuntime("gemdict_craftinginfo")
                            pref.components.gemdict_craftinginfo.ingredientsdata = _ingredientsdata
                            gemrun("getspecialprefab", prefab) --upvalue prefab will contain the appropriate value to remove the special prefab after getting spawned
                        end)
                        table.insert(loots, prefab)
                    end
                    amt = amt - 1
                    if amt <= 0 then break end
                end
                if amt <= 0 then break end
            end
        end
    else
        for n = 1, amt do
            local prefab = not IsGemDictIngredient(ingredient) and ingredient.type or ingredient:GetFallbackPrefab()
            if deconstructfn and ingredient.deconstruct then
                for _, loot in ipairs(deconstructfn(AllRecipes[prefab], {})) do
                    table.insert(loots, loot)
                end
            else
                table.insert(loots, prefab)
            end
        end
    end

    return loots
end

-- LOOTDROPPER --

local LootDropper = require("components/lootdropper")

local function GetRecipeLoot(self, recipe, ingredientsdata)
    local percent = 1

    local loots = {}

    if self.inst.components.finiteuses then
        percent = self.inst.components.finiteuses:GetPercent()
    end

    for k, v in multiipairs(recipe.ingredients, recipe.gemdict_ingredients) do
        local amt = math.ceil((v.amount * (self.inst:HasTag("burnt") and TUNING.BURNT_HAMMER_LOOT_PERCENT or TUNING.HAMMER_LOOT_PERCENT)) * percent)
        local spawnfn = v.ingredientspawnfn or defaultspawnfn
        for _, loot in ipairs(spawnfn(v, amt, ingredientsdata, function(...) return GetRecipeLoot(self, ...) end)) do
            table.insert(loots, loot)
        end
    end
    return loots
end

local _GetRecipeLoot = LootDropper.GetRecipeLoot
function LootDropper:GetRecipeLoot(recipe, ...)
    local ingredientsdata = self.inst.components.gemdict_craftinginfo and self.inst.components.gemdict_craftinginfo:GetIngredientsData() or {}
    return GetRecipeLoot(self, recipe, ingredientsdata)
end

-- LOOTDROPPER END --

-- GREENSTAFF --

local localdata
local RecipePopupRefreshEnv = setmetatable({
    ipairs = function(t, ...)
        if not localdata then return ipairs(t, ...) end
        local DESTSOUNDSMAP = localdata.DESTSOUNDSMAP
        local SpawnLootPrefab = localdata.SpawnLootPrefab
        local target = localdata.target
        local recipe = AllRecipes[target.prefab]

        if recipe.ingredients ~= t then
            return ipairs(t, ...)
        end

        local ingredient_percent, caster
        local stacklevel = 2
        while debug.getinfo(stacklevel, "n") ~= nil do
            ingredient_percent = LocalVariableHacker.GetLocalVariable(stacklevel, "ingredient_percent")
            caster = LocalVariableHacker.GetLocalVariable(stacklevel, "caster")
            if ingredient_percent ~= nil and caster ~= nil then
                break
            end
            stacklevel = stacklevel + 1
        end

        local ingredientsdata = target.components.gemdict_craftinginfo and target.components.gemdict_craftinginfo:GetIngredientsData() or {}
        for k, v in multiipairs(recipe.ingredients, recipe.gemdict_ingredients) do
            local amt = math.max(1, math.ceil(v.amount * ingredient_percent))
            local spawnfn = v.ingredientspawnfn or defaultspawnfn
            local playedsoundloot = {}
            for _, loot in ipairs(spawnfn(v, amt, ingredientsdata)) do
                if not playedsoundloot[loot] then
                    playedsoundloot[loot] = true
                    if caster ~= nil and DESTSOUNDSMAP[loot] ~= nil then
                        caster.SoundEmitter:PlaySound(DESTSOUNDSMAP[loot])
                    end
                end
                if string.sub(loot, -3) ~= "gem" or string.sub(loot, -11, -4) == "precious" then
                    SpawnLootPrefab(target, loot)
                end
            end
        end
        return ipairs({})
    end
}, {__index = _G, __newindex = _G})

GEMENV.AddSimPostInit(function()
    if Prefabs.greenstaff then
        local _destroystructure = UpvalueHacker.GetUpvalue(Prefabs.greenstaff.fn, "destroystructure")
        local DESTSOUNDSMAP = UpvalueHacker.GetUpvalue(_destroystructure, "DESTSOUNDSMAP")
        local SpawnLootPrefab = UpvalueHacker.GetUpvalue(_destroystructure, "SpawnLootPrefab")
        local function destroystructure(staff, target, ...)
            localdata = nil
            if AllRecipes[target.prefab] ~= nil then
                localdata = {DESTSOUNDSMAP = DESTSOUNDSMAP, SpawnLootPrefab = SpawnLootPrefab, target = target}
            end
            return _destroystructure(staff, target, ...)
        end
        UpvalueHacker.SetUpvalue(Prefabs.greenstaff.fn, destroystructure, "destroystructure")
        UpvalueHacker.SetUpvalue(Prefabs.greenstaff.fn, destroystructure, "onhauntgreen", "destroystructure")
        gemrun("hidefn", destroystructure, _destroystructure)
    end
end)

-- GREENSTAFF END --

-- STACKABLE --

local Stackable = require("components/stackable")

local _Get = Stackable.Get
function Stackable:Get(num, ...)
    local instance = _Get(self, num, ...)
    if instance ~= self.inst and self.inst.components.gemdict_craftinginfo then
        instance:AddComponentAtRuntime("gemdict_craftinginfo")
        instance.components.gemdict_craftinginfo.ingredientsdata = self.inst.components.gemdict_craftinginfo:GetIngredientsData()
    end
    return instance
end

-- STACKABLE END --