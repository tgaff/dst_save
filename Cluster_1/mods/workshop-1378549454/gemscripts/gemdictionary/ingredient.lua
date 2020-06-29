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

GEMDICT_INGREDIENT = "gemdict_ingredient"

GemDictIngredient = Class(function(self, ingredientdata)
    self.prefabingredients = {}
    self.functioningredients = {}
    self.images = {}
    self.hint_images = {}
    self.names = {}
    self.hint_names = {}
    self.type = GEMDICT_INGREDIENT
    self.amount = ingredientdata.amount
    self.deconstruct = ingredientdata.deconstruct
    self.allowmultipleprefabtypes = ingredientdata.allowmultipleprefabtypes == nil and true or ingredientdata.allowmultipleprefabtypes
    self.ingredientspawnfn = ingredientdata.ingredientspawnfn
    self.requiresitemdata = ingredientdata.requiresitemdata
    if Ingredient.is_a(ingredientdata, Ingredient) then
        --convert existing ingredient to a GemDictIngredient
        self:AddDictionaryPrefab(ingredientdata.type, ingredientdata.atlas, ingredientdata.image)
        self.fallbackprefab = ingredientdata.type
        self.signature = "GEMDICT_"..ingredientdata.type
    else
        for k, v in pairs(ingredientdata.prefabingredients or {}) do
            self:AddDictionaryPrefab(k, v.atlas, v.imageoverride)
        end
        for k, v in pairs(ingredientdata.functioningredients or {}) do
            self:AddDictionaryFunction(k, v)
        end
        self.fallbackprefab = ingredientdata.fallbackprefab
        self.signature = ingredientdata.signature
        assert(self.signature:sub(1,#"GEMDICT_") ~= "GEMDICT_", "the prefix GEMDICT_ for ingredients is reserved only for ingredients converted to gemdict_ingredients.")
    end
    assert(self.signature, "GemDictIngredient must have a signature")
end)

function GemDictIngredient:AddDictionaryPrefab(ingredienttype, atlas, image)
    assert(not (IsCharacterIngredient(ingredienttype) or IsTechIngredient(ingredienttype)), "GemDictIngredient:AddDictionaryPrefab ingredienttype can't be character or tech ingredients")
    self.prefabingredients[ingredienttype] = {atlas = atlas and resolvefilepath(atlas) or nil, image = image or ingredienttype..".tex"}
end

function GemDictIngredient:RemoveDictionaryPrefab(ingredienttype)
    self.prefabingredients[ingredienttype] = nil
end

function GemDictIngredient:AddDictionaryFunction(key, fn)
    self.functioningredients[key] = fn
end

function GemDictIngredient:RemoveDictionaryFunction(key)
    self.functioningredients[key] = nil
end

function GemDictIngredient:AddImage(image, atlas, name)
    table.insert(self.images, {image = image, atlas = atlas})
    table.insert(self.names, name)
end

function GemDictIngredient:RemoveImage(image)
    for i, v in ipairs(self.images) do
        if v.image == image then
            table.remove(self.images, i)
            table.remove(self.names, i)
            return
        end
    end
end

function GemDictIngredient:AddHintImage(image, atlas, name)
    table.insert(self.hint_images, {image = image, atlas = atlas})
    table.insert(self.hint_names, name)
end

function GemDictIngredient:RemoveHintImage(image)
    for i, v in ipairs(self.hint_images) do
        if v.image == image then
            table.remove(self.hint_images, i)
            table.remove(self.hint_names, i)
            return
        end
    end
end

function GemDictIngredient:GetImages(hint, count, has)
    local images = {}
    local names = {}
    local counts = {}
    for type, imagedata in pairs(self.prefabingredients) do
        table.insert(images, {image = imagedata.image, atlas = imagedata.atlas or resolvefilepath(GetInventoryItemAtlas(imagedata.image))})
        table.insert(names, STRINGS.NAMES[string.upper(type)])
        table.insert(counts, {on_hand = count or 0, has_enough = has})
    end
    for i, v in ipairs(self.images) do
        table.insert(images, {image = v.image, atlas = v.atlas or resolvefilepath(GetInventoryItemAtlas(v.image))})
        table.insert(names, self.names[i])
        table.insert(counts, {on_hand = count or 0, has_enough = has})
    end
    if hint then
        for i, v in ipairs(self.hint_images) do
            table.insert(images, {image = v.image, atlas = v.atlas or resolvefilepath(GetInventoryItemAtlas(v.image))})
            table.insert(names, self.hint_names[i])
            table.insert(counts, {on_hand = count or 0, has_enough = has})
        end
    end
    return images, names, counts
end

function GemDictIngredient:GetFallbackPrefab()
    return self.fallbackprefab
end

--GLOBAL function
function IsGemDictIngredient(ingredienttype)
    return ingredienttype == GEMDICT_INGREDIENT
end