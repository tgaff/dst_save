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

local function GetItemCount(item)
    return item.replica.stackable ~= nil and item.replica.stackable:StackSize() or 1
end

local function ItemPriorityToIndex(tbl, item_priority)
    local _priority = 1
    for priority, data in ipairs(tbl) do
        if item_priority < data.item_priority then
            return _priority, false
        elseif item_priority == data.item_priority then
            return priority, true
        end
        _priority = _priority + 1
    end
end

local function IngredientPriorityToIndex(tbl, ingredient_priority)
    local _priority = 1
    for priority, data in ipairs(tbl) do
        if ingredient_priority < data.ingredient_priority then
            return _priority, false
        elseif ingredient_priority == data.ingredient_priority then
            return priority, true
        end
        _priority = _priority + 1
    end
end

local IngredientAllocator = Class(function(self, recipe)
    self.recipe = recipe
end)

function IngredientAllocator:GetSharedItemCount(item, ingredient_priority)
    if self.shared_items.total[item] then
        local count = self.shared_items.total[item]
        if ingredient_priority then
            count = count - self.shared_items[item][ingredient_priority]
        end
        return count
    end
end

function IngredientAllocator:IsSharedItemUsedByIngredient(item, ingredient_priority)
    if self.shared_items.total[item] then
        return self.shared_items[item][ingredient_priority] ~= nil
    end
end

function IngredientAllocator:ConsumeSharedItemCount(item, count, ingredient_priority)
    if self.shared_items.total[item] then
        if ingredient_priority then
            for _ingredient_priority = ingredient_priority, #self.ingredientallocator.ingredient_allocations, 1 do
                if shared_items[item][_ingredient_priority] then
                    shared_items[item][_ingredient_priority] = shared_items[item][_ingredient_priority] + count
                    self.ingredient_allocations[_ingredient_priority].mightconsumecountdirty = true
                end
            end
        else
            self.shared_items.total[item] = self.shared_items.total[item] - count
            for _ingredient_priority, ingredient_allocation in ipairs(self.ingredient_allocations) do
                if self.shared_items[item][_ingredient_priority] then
                    ingredient_allocation.mightconsumecountdirty = true
                end
            end
        end
    end
end

local IngredientSet = Class(function(self, data, ingredientmod)
    self.ingredient = data.ingredient
    self.gemdict_ingredient = data.gemdict_ingredient
    assert(self.ingredient or self.gemdict_ingredient, "ingredient or gemdict_ingredient is required for class IngredientSet")
    self.canmixingredients = data.canmix ~= false
    self.amount = math.max(1, math.round(self:GetIngredient().amount * ingredientmod))
    self.itemoptions = data.itemoptions
end)

function IngredientSet:GetIngredient()
    return self.ingredient or self.gemdict_ingredient
end

function IngredientSet:GetItemOptions()
    return self.itemoptions
end

local IngredientAllocation = Class(function(self, ingredientallocator, ingredient_priority)
    self.ingredientallocator = ingredientallocator
    self.ingredient_priority = ingredient_priority
    self.amountneeded = self:GetIngredientSet().amount
    self.willconsume = {}
    self.willconsumecount = 0
    self.tryconsume = {}
    self.tryconsumecount = 0
    self.mightconsume = {}
    self.mightconsumecount = 0
    self.mightconsumecountdirty = false
end)

function IngredientAllocation:GetIngredientSet()
    return self.ingredientallocator.ingredient_sets[self.ingredient_priority]
end

function IngredientAllocation:IsValid()
    return (self.willconsumecount + self.tryconsumecount + self:GetMightConsumeCount()) >= self.amountneeded
end

function IngredientAllocation:IsFinished()
    return (self.willconsumecount + self.tryconsumecount) >= self.amountneeded
end

function IngredientAllocation:GetRemaingNeededItemsCount()
    return self.amountneeded - (self.willconsumecount + self.tryconsumecount)
end

function IngredientAllocation:AddWillConsume(item, count, item_priority, index)
    index = index or #self.willconsume + 1
    table.insert(self.willconsume, index, {item = item, count = count, item_priority = item_priority})
    self.willconsumecount = self.willconsumecount + count
end

function IngredientAllocation:AddTryConsume(item, count, item_priority, index)
    index = index or #self.tryconsume + 1
    table.insert(self.tryconsume, index, {item = item, count = count, item_priority = item_priority})
    self.tryconsumecount = self.tryconsumecount + count
end

function IngredientAllocation:AddMightConsume(item, item_priority, count, index)
    index = index or #self.mightconsume + 1
    table.insert(self.mightconsume, index, {item = item, count = count, item_priority = item_priority})
    self.mightconsumecount = self.mightconsumecount + (count or self.ingredientallocator:GetSharedItemCount(item))
end

function IngredientAllocation:Consume(item_priority, count)
    local item = self.mightconsume[ItemPriorityToIndex(self.mightconsume, item_priority)].item
    if self.ingredientallocator:GetSharedItemCount(item) then
        self.ingredientallocator:ConsumeSharedItemCount(item, count)
    else
        local mindex, mexists = ItemPriorityToIndex(self.mightconsume, item_priority)
        assert(mexists, "tried to Consume and item that wasn't shared, and lacked mightconsume entry!")
        self.mightconsume[mindex].count = self.mightconsume[mindex].count - count
        if self.mightconsume[mindex].count <= 0 then
            table.remove(self.mightconsume, mindex)
        end
    end
    local index, exists = ItemPriorityToIndex(self.willconsume, item_priority)
    if exists then
        self.willconsume[index].count = self.willconsume[index].count + count
    else
        self:AddWillConsume(item, count, item_priority, index)
    end
    self.willconsumecount = self.willconsumecount + count
    self.mightconsumecount = self.mightconsumecount - count
end

function IngredientAllocation:Unconsume(item_priority, count)
    local index, exists = ItemPriorityToIndex(self.willconsume, item_priority)
    assert(exists, "tried to Unconsume and item that wasn't willconsumed!")
    local item = self.willconsume[index].item
    if self.ingredientallocator:GetSharedItemCount(item) then
        self.ingredientallocator:ConsumeSharedItemCount(item, -count)
    else
        local mindex, mexists = ItemPriorityToIndex(self.mightconsume, item_priority)
        if mexists then
            self.mightconsume[mindex].count = self.mightconsume[mindex].count + count
        else
            self:AddMightConsume(item, item_priority, count, mindex)
        end
    end
    self.willconsume[index].count = self.willconsume[index].count - count
    if self.willconsume[index].count <= 0 then
        table.remove(self.willconsume, index)
    end
    self.willconsumecount = self.willconsumecount - count
    self.mightconsumecount = self.mightconsumecount + count
end

function IngredientAllocation:TryConsume(item_priority, count)
    local item = self.mightconsume[ItemPriorityToIndex(self.mightconsume, item_priority)].item
    self.ingredientallocator:ConsumeSharedItemCount(item, count, self.ingredient_priority)
    local index, exists = ItemPriorityToIndex(self.tryconsume, item_priority)
    if exists then
        self.tryconsume[index].count = self.tryconsume[index].count + count
    else
        self:AddTryConsume(item, count, item_priority, index)
    end
    self.tryconsumecount = self.tryconsumecount + count
    self.mightconsumecount = self.mightconsumecount - count
end

function IngredientAllocation:UntryConsume(item_priority, count)
    local index, exists = ItemPriorityToIndex(self.tryconsume, item_priority)
    assert(exists, "tried to UntryConsume and item that wasn't tryconsumed!")
    local item = self.tryconsume[index].item
    self.ingredientallocator:ConsumeSharedItemCount(item, -count, self.ingredient_priority)
    self.tryconsume[index].count = self.tryconsume[index].count - count
    if self.tryconsume[index].count <= 0 then
        table.remove(self.tryconsume, index)
    end
    self.tryconsumecount = self.tryconsumecount - count
    self.mightconsumecount = self.mightconsumecount + count
end

function IngredientAllocation:RemoveRequestedItems(item_priority, amountrequested)
    local index, exists = ItemPriorityToIndex(self.tryconsume, item_priority)
    if exists then
        return self:UntryConsume(item_priority, math.min(self:GetMightConsumeCount(), amountrequested, self.tryconsume[index].count))
    end
    return 0
end

function IngredientAllocation:GetMightConsumeCount()
    if self.mightconsumecountdirty then
        self.mightconsumecountdirty = false
        self.mightconsumecount = 0

        for i, v in ipairs(self.mightconsume) do
            self.mightconsumecount = self.mightconsumecount + (v.count or self.ingredientallocator:GetSharedItemCount(v.item, self.ingredient_priority))
        end
    end
    return self.mightconsumecount
end

function IngredientAllocation:ConsumeNonSharedItems()
    for i, v in ipairs(self.itemoptions or self:GetIngredientSet().itemoptions) do
        if not self.ingredientallocator:GetSharedItemCount(v.item) then
            local neededitemcount = self.amountneeded - self.willconsumecount
            if (v.count - neededitemcount) > 0 then
                self:AddMightConsume(v.item, i, v.count - neededitemcount)
            end
            if neededitemcount > 0 then
                self:AddWillConsume(v.item, math.min(neededitemcount, v.count), i)
            end
        elseif self.ingredientallocator:GetSharedItemCount(v.item) > 0 then
            self:AddMightConsume(v.item, i)
        end
        if not self.ingredientallocator.allowinvalid and self:IsFinished() then break end
    end
end

function IngredientAllocation:ConsumeSharedRequiredItems()
    local old_willconsumecount = self.willconsumecount
    if not self:IsFinished() then
        for i, v in ipairs(self.mightconsume) do
            local neededitemcount = (self.amountneeded - self.willconsumecount) - (self:GetMightConsumeCount() - self.ingredientallocator:GetSharedItemCount(v.item))
            if neededitemcount > 0 then
                self:Consume(v.item_priority, math.min(neededitemcount, self.ingredientallocator:GetSharedItemCount(v.item)))
                if self:IsFinished() then
                    break
                end
            end
        end
    end
    return old_willconsumecount < self.willconsumecount
end

function IngredientAllocation:ConsumeLowestPriorityItems()
    local ingredients_to_reallocate = {}
    for i, v in ipairs_reverse(self.mightconsume) do
        for ingredient_priority = #self.ingredientallocator.ingredient_allocations, self.ingredient_priority + 1, -1 do
            if self.ingredientallocator:IsSharedItemUsedByIngredient(v.item, ingredient_priority) then
                local amountremoved = self.ingredientallocator.ingredient_allocations[ingredient_priority]:RemoveRequestedItems(v.item_priority, self:GetRemaingNeededItemsCount())
                if amountremoved > 0 then
                    table.insert(ingredients_to_reallocate, ingredient_allocation)
                    self:TryConsume(v.item_priority, amountremoved)
                    if self:IsFinished() then break end
                end
            end
        end
        if self:IsFinished() then break end
    end
    if not self.ingredientallocator.allowinvalid and not self:IsFinished() then return false end

    for i, ingredient_allocation in ipairs(ingredients_to_reallocate) do
        if not ingredient_allocation:ConsumeLowestPriorityItems() then return false end
    end
    return true
end

function IngredientAllocation:FinishConsuming()
    for i, v in ipairs_reverse(self.tryconsume) do
        local item_priority, count = v.item_priority, v.count
        self:UntryConsume(item_priority, count)
        self:Consume(item_priority, count)
    end
end

function IngredientAllocation:ConsumeHighestPriorityItems()
    if self:GetMightConsumeCount() > 0 then
        local mightconsumeidx
        for i, v in ipairs(self.mightconsume) do
            local count = v.count or self.ingredientallocator:GetSharedItemCount(v.item) or 0
            if count > 0 then
                mightconsumeidx = i
                break
            end
        end

        if mightconsumeidx and self.mightconsume[mightconsumeidx].item_priority < self.willconsume[#self.willconsume].item_priority then
            for i, v in ipairs_reverse(self.willconsume) do
                self:Unconsume(v.item_priority, v.count)
            end
            for i, v in ipairs(self.mightconsume) do
                self:Consume(v.item_priority, math.min(self:GetRemaingNeededItemsCount(), v.count or self.ingredientallocator:GetSharedItemCount(v.item)))
                if self:IsFinished() then return true end
            end
        end
    end
    return false
end

function IngredientAllocation:GetConsumedItems()
    return self.willconsume
end

function IngredientAllocation:GetRecipePopupData()
    local ingredientdata = {}
    ingredientdata.has = self:IsFinished()
    self.mightconsumecountdirty = true --blegh
    ingredientdata.num_found = self.willconsumecount + self:GetMightConsumeCount()
    ingredientdata.items = {}
    for i, v in ipairs(self.willconsume) do
        ingredientdata.items[v.item] = v.count
    end
    for i, v in ipairs(self.mightconsume) do
        ingredientdata.items[v.item] = ingredientdata.items[v.item] or 0
    end
    return ingredientdata
end

local function onmightconsumecountdirty(self, mightconsumecountdirty)
    for i, v in ipairs(self.ingredient_allocations) do
        v.mightconsumecountdirty = mightconsumecountdirty
    end
end

local IngredientAllocation_NoMix = Class(function(self, ingredientallocator, ingredient_priority)
    self.ingredientallocator = ingredientallocator
    self.ingredient_priority = ingredient_priority
    self.ingredient_allocations = {}
    self.invalid_ingredient_allocations = {}
end,
nil,
{
    mightconsumecountdirty = onmightconsumecountdirty
})

function IngredientAllocation_NoMix:GetIngredientSet()
    return self.ingredientallocator.ingredient_sets[self.ingredient_priority]
end

function IngredientAllocation_NoMix:IsValid()
    local j = 1
    for i, ingredient_allocation in ipairs(self.ingredient_allocations) do
        if ingredient_allocation:IsValid() then
            if i ~= j then
                self.ingredient_allocations[j] = ingredient_allocation
                self.ingredient_allocations[i] = nil
            end
            j = j + 1
        else
            self:ReleaseIngredientAllocation(i)
        end
    end
    return self:GetIngredientAllocationsCount() >= 1
end

function IngredientAllocation_NoMix:IsFinished()
    if self:GetIngredientAllocationsCount() < 1 then
        return false
    end
    return self:GetLowestPriorityIngredientAllocation():IsFinished()
end

function IngredientAllocation_NoMix:AddIngredientAllocation(ingredient_allocation)
    table.insert(self.ingredient_allocations, ingredient_allocation)
end

function IngredientAllocation_NoMix:RemoveIngredientAllocation(ingredient_allocation_index)
    table.remove(self.ingredient_allocations, ingredient_allocation_index)
end

function IngredientAllocation_NoMix:GetLowestPriorityIngredientAllocation()
    return self.ingredient_allocations[#self.ingredient_allocations]
end

function IngredientAllocation_NoMix:GetHighestPriorityIngredientAllocation()
    return self.ingredient_allocations[1]
end

function IngredientAllocation_NoMix:GetIngredientAllocationsCount()
    return #self.ingredient_allocations
end

--note: this doesn't use table.remove, meaning you must manualy shift ingredients if this isn't the lowest priority
function IngredientAllocation_NoMix:ReleaseIngredientAllocation(ingredient_priority)
    local ingredient_allocation = self.ingredient_allocations[ingredient_priority]
    for i, tryconsume in ipairs_reverse(ingredient_allocation.tryconsume) do
        ingredient_allocation:UntryConsume(tryconsume.item_priority, tryconsume.count)
    end
    for i, willconsume in ipairs_reverse(ingredient_allocation.willconsume) do
        ingredient_allocation:Unconsume(willconsume.item_priority, willconsume.count)
    end
    self.ingredient_allocations[ingredient_priority] = nil
end

function IngredientAllocation_NoMix:RemoveRequestedItems(item_priority, amountrequested)
    local ingredient_allocation = self:GetLowestPriorityIngredientAllocation()
    local index, exists = ItemPriorityToIndex(ingredient_allocation.tryconsume, item_priority)
    if exists then
        local amountavaliable = math.min(amountrequested, ingredient_allocation[index].count)
        if amountavaliable > 0 then
            if ingredient_allocation:GetMightConsumeCount() < amountavaliable and self:GetIngredientAllocationsCount() > 1 then
                self:ReleaseIngredientAllocation(self:GetIngredientAllocationsCount())
                return amountavaliable
            else
                return ingredient_allocation:UntryConsume(item_priority, math.min(ingredient_allocation:GetMightConsumeCount(), amountavaliable))
            end
        end
    end
    return 0
end

function IngredientAllocation_NoMix:ConsumeNonSharedItems()
    local itemgroups = {}
    local previousprefab
    for i, v in ipairs(self:GetIngredientSet().itemoptions) do
        if v.item.prefab ~= previousprefab then
            table.insert(itemgroups, {})
            previousprefab = v.item.prefab
        end
        table.insert(itemgroups[#itemgroups], v)
    end
    for i, itemgroup in ipairs(itemgroups) do
        local ingredient_allocation = IngredientAllocation(self.ingredientallocator, self.ingredient_priority)
        ingredient_allocation.itemoptions = itemgroup
        ingredient_allocation:ConsumeNonSharedItems()
        table.insert(self.invalid_ingredient_allocations, ingredient_allocation)
        if ingredient_allocation:IsValid() and not self:IsFinished() then
            self:AddIngredientAllocation(ingredient_allocation)
            if not self.ingredientallocator.allowinvalid and ingredient_allocation:IsFinished() then
                break
            end
        else
            self:AddIngredientAllocation(ingredient_allocation)
            self:ReleaseIngredientAllocation(self:GetIngredientAllocationsCount())
        end
    end
end

function IngredientAllocation_NoMix:ConsumeSharedRequiredItems()
    if self:GetIngredientAllocationsCount() < 1 then
        return false
    end
    return self:GetLowestPriorityIngredientAllocation():ConsumeSharedRequiredItems()
end

function IngredientAllocation_NoMix:ConsumeLowestPriorityItems()
    for i, ingredient_allocation in ipairs_reverse(self.ingredient_allocations) do
        if ingredient_allocation:ConsumeLowestPriorityItems() and ingredient_allocation:IsFinished() then break end
        self:ReleaseIngredientAllocation(self:GetIngredientAllocationsCount())
    end
    return self.ingredientallocator.allowinvalid or self:IsFinished()
end

function IngredientAllocation_NoMix:FinishConsuming()
    if self:GetIngredientAllocationsCount() < 1 then
        return
    end
    self:GetLowestPriorityIngredientAllocation():FinishConsuming()
end

function IngredientAllocation_NoMix:ConsumeHighestPriorityItems()
    local returnvalue
    for ingredient_priority, ingredient_allocation in ipairs(self.ingredient_allocations) do
        if returnvalue == nil and ingredient_allocation:IsValid() then
            returnvalue = ingredient_allocation:ConsumeHighestPriorityItems()
            self.ingredient_allocations[ingredient_priority] = nil
            self.ingredient_allocations[1] = ingredient_allocation
        else
            self:ReleaseIngredientAllocation(ingredient_priority)
        end
    end
    return returnvalue or false
end

function IngredientAllocation_NoMix:GetConsumedItems()
    if self:GetIngredientAllocationsCount() < 1 then
        return {}
    end
    return self:GetHighestPriorityIngredientAllocation():GetConsumedItems()
end

function IngredientAllocation_NoMix:GetRecipePopupData()
    local ingredientdata = {nomix = true}
    for ingredient_priority, ingredient_allocation in ipairs(self.invalid_ingredient_allocations) do
        table.insert(ingredientdata, ingredient_allocation:GetRecipePopupData())
        ingredientdata.has = ingredientdata.has or ingredientdata[#ingredientdata].has
        ingredientdata[#ingredientdata].has = ingredientdata[#ingredientdata].has or ingredientdata[#ingredientdata].num_found >= ingredient_allocation.amountneeded
    end
    return ingredientdata
end

function IngredientAllocator:GetIngredientSets(ingredientmod)
    local ingredient_sets = {}
    for i, ingredient in ipairs(self.recipe.ingredients) do
        local items = self.builder.replica.inventory:FindItems(function(item)
            return ingredient.type == item.prefab
        end)
        local itemoptions = {}
        local count = 0
        for _, v in ipairs(items) do
            local _count = GetItemCount(v)
            count = count + _count
            table.insert(itemoptions, {item = v, count = _count})
        end
        if count >= math.max(1, math.round(ingredient.amount * ingredientmod)) or self.allowinvalid then
            table.insert(ingredient_sets, IngredientSet({ingredient = ingredient, itemoptions = itemoptions}, ingredientmod))
        end
    end
    for i, gemdict_ingredient in ipairs(self.recipe.gemdict_ingredients) do
        local items = self.builder.replica.inventory:FindItems(function(item)
            if gemdict_ingredient.prefabingredients[item.prefab] ~= nil then
                return true
            end
            for k, v in pairs(gemdict_ingredient.functioningredients) do
                if v(item) then
                    return true
                end
            end
            return false
        end)
        if gemdict_ingredient.sortfn then
            stable_sort(items, gemdict_ingredient.sortfn)
        end

        local itemoptions = {}
        local count = 0
        for _, v in ipairs(items) do
            local _count = GetItemCount(v)
            count = count + _count
            table.insert(itemoptions, {item = v, count = _count})
        end

        if count >= math.max(1, math.round(gemdict_ingredient.amount * ingredientmod)) or self.allowinvalid then
            if gemdict_ingredient.allowmultipleprefabtypes then
                table.insert(ingredient_sets, IngredientSet({gemdict_ingredient = gemdict_ingredient, itemoptions = itemoptions}, ingredientmod))
            else
                local itemcounts = {}
                local prefab_to_index = {}
                local index = 1
                for _, v in pairs(itemoptions) do
                    itemcounts[v.item.prefab] = (itemcounts[v.item.prefab] or 0) + v.count
                    if not prefab_to_index[v.item.prefab] then
                        prefab_to_index[v.item.prefab] = index
                        index = index + 1
                    end
                end
                local _itemoptions = {}
                for _, v in ipairs(itemoptions) do
                    if itemcounts[v.item.prefab] >= math.max(1, math.round(gemdict_ingredient.amount * ingredientmod)) or self.allowinvalid then
                        table.insert(_itemoptions, v)
                    end
                end

                stable_sort(_itemoptions, function(a, b)
                    return prefab_to_index[a.item.prefab] < prefab_to_index[b.item.prefab]
                end)

                if #_itemoptions > 0 or self.allowinvalid then
                    table.insert(ingredient_sets, IngredientSet({gemdict_ingredient = gemdict_ingredient, canmix = false, itemoptions = _itemoptions}, ingredientmod))
                end
            end
        end
    end
    return ingredient_sets
end

function IngredientAllocator:GetSharedItems()
    local shared_items = {total = {}}
    for ingredient_priority, ingredient_set in pairs(self.ingredient_sets) do
        for i, v in ipairs(ingredient_set:GetItemOptions()) do
            shared_items.total[v.item] = (shared_items.total[v.item] or 0) + v.count
            shared_items[v.item] = shared_items[v.item] or {ingredients = 0}
            shared_items[v.item][ingredient_priority] = 0
            shared_items[v.item].ingredients = shared_items[v.item].ingredients + 1
        end
    end
    for item, shared_item in pairs(shared_items) do
        --shared_items.total.ingredients is nil, but we don't want shared_items["total"] = nil to get called, so if ingredients is nil(total) then we use the value 2.
        if (shared_item.ingredients or 2) <= 1 then
            shared_items.total[item] = nil
            shared_items[item] = nil
        end
    end
    return shared_items
end

function IngredientAllocator:IsFinished()
    for ingredient_priority, ingredient_allocation in ipairs(self.ingredient_allocations) do
        if not ingredient_allocation:IsFinished() then
            return false
        end
    end
    return true
end

function IngredientAllocator:GetBuilderItems()
    local ingredients = {}
    local ingredientsdata = {}
    for ingredient_priority, ingredient_allocation in ipairs(self.ingredient_allocations) do
        local ingredient = self.ingredient_sets[ingredient_priority]:GetIngredient()
        local _type = ingredient.type..(IsGemDictIngredient(ingredient.type) and ("_"..(ingredient_priority - #self.recipe.ingredients)) or "")
        ingredients[_type] = {}
        ingredientsdata[ingredient.signature or ingredient.type] = {}
        for i, v in ipairs(ingredient_allocation:GetConsumedItems()) do
            ingredients[_type][v.item] = v.count
            local itemdata
            if ingredient.requiresitemdata then
                itemdata = v.item:GetSaveRecord()
            else
                itemdata = {prefab = v.item.prefab, data = {}}
                for _, cmp in ipairs({"stackable", "gemdict_craftinginfo"}) do
                    if v.item.components[cmp] then
                        local t = v.item.components[cmp]:OnSave()
                        if type(t) == "table" then
                            itemdata.data[cmp] = t
                        end
                    end
                end
            end
             table.insert(ingredientsdata[ingredient.signature or ingredient.type], itemdata)
        end
    end
    return ingredients, ingredientsdata
end

function IngredientAllocator:GetRecipeIngredients(builder, ingredientmod, validonly)
    self.builder = builder
    self.ingredient_sets = self:GetIngredientSets(ingredientmod)
    if (#self.recipe.ingredients + #self.recipe.gemdict_ingredients) ~= #self.ingredient_sets then
        return false
    end
    self.shared_items = self:GetSharedItems()

    --Step 1: consume all non shared items up to the amount the ingredient requires
    self.ingredient_allocations = {}
    for ingredient_priority, ingredient_set in ipairs(self.ingredient_sets) do
        local ingredient_allocation
        if ingredient_set.canmixingredients then
            ingredient_allocation = IngredientAllocation(self, ingredient_priority)
        else
            ingredient_allocation = IngredientAllocation_NoMix(self, ingredient_priority)
        end
        ingredient_allocation:ConsumeNonSharedItems()
        self.ingredient_allocations[ingredient_priority] = ingredient_allocation
    end

    if (not self.recipe:HasGemDictIngredients() or validonly) and self:IsFinished() then
        if validonly then
            return true
        end
        return self:GetBuilderItems()
    end

    --Step 2: consume any shared items that would be required to fulfill the ingredient, keep doing this until all ingredients are finished consuming.
    local consumefinishedcount = 0
    while consumefinishedcount < #self.ingredient_allocations do
        for ingredient_priority, ingredient_allocation in ipairs(self.ingredient_allocations) do
            if not ingredient_allocation:IsValid() then return false end
            consumefinishedcount = (ingredient_allocation:ConsumeSharedRequiredItems() and 0) or (consumefinishedcount + 1)
            if consumefinishedcount == #self.ingredient_allocations then break end
        end
    end

    if validonly and self:IsFinished() then
        return true
    end

    --Step 3: go from lowest ingredient_priority, lowest item_priority and start tryconsuming items until all ingredients have fulfilled their amount needed.
    --higher priority ingredients can request items from lower priority ingredients, and the lower priority ingredient **must** give them up, as long as they can still obtain enough items to fulfill the amount needed.
    for ingredient_priority, ingredient_allocation in ipairs_reverse(self.ingredient_allocations) do
        if not ingredient_allocation:IsFinished() then
            if not ingredient_allocation:ConsumeLowestPriorityItems() then return false end
        end
    end
    if validonly then return true end

    --Step 4: go from highest ingredient_priority, highest item_priority, and start actually consuming the ingredients.
    for ingredient_priority, ingredient_allocation in ipairs(self.ingredient_allocations) do
        ingredient_allocation:FinishConsuming()
    end

    consumefinishedcount = 0
    while consumefinishedcount < #self.ingredient_allocations do
        for ingredient_priority, ingredient_allocation in ipairs(self.ingredient_allocations) do
            consumefinishedcount = (ingredient_allocation:ConsumeHighestPriorityItems() and 0) or (consumefinishedcount + 1)
            if consumefinishedcount == #self.ingredient_allocations then break end
        end
    end

    return self:GetBuilderItems()
end

--this function goes to completion, regardless of whether there is enough ingredients or not
function IngredientAllocator:GetRecipePopupIngredients(builder, ingredientmod)
    self.allowinvalid = true
    self.builder = builder
    self.ingredient_sets = self:GetIngredientSets(ingredientmod)
    self.shared_items = self:GetSharedItems()

    --Step 1: consume all non shared items up to the amount the ingredient requires
    self.ingredient_allocations = {}
    for ingredient_priority, ingredient_set in ipairs(self.ingredient_sets) do
        local ingredient_allocation
        if ingredient_set.canmixingredients then
            ingredient_allocation = IngredientAllocation(self, ingredient_priority)
        else
            ingredient_allocation = IngredientAllocation_NoMix(self, ingredient_priority)
        end
        ingredient_allocation:ConsumeNonSharedItems()
        self.ingredient_allocations[ingredient_priority] = ingredient_allocation
    end

    --Step 2: consume any shared items that would be required to fulfill the ingredient, keep doing this until all ingredients are finished consuming.
    local consumefinishedcount = 0
    while consumefinishedcount < #self.ingredient_allocations do
        for ingredient_priority, ingredient_allocation in ipairs(self.ingredient_allocations) do
            consumefinishedcount = (ingredient_allocation:ConsumeSharedRequiredItems() and 0) or (consumefinishedcount + 1)
            if consumefinishedcount == #self.ingredient_allocations then break end
        end
    end

    --Step 3: go from lowest ingredient_priority, lowest item_priority and start tryconsuming items until all ingredients have fulfilled their amount needed.
    --higher priority ingredients can request items from lower priority ingredients, and the lower priority ingredient **must** give them up, as long as they can still obtain enough items to fulfill the amount needed.
    for ingredient_priority, ingredient_allocation in ipairs_reverse(self.ingredient_allocations) do
        if not ingredient_allocation:IsFinished() then
            ingredient_allocation:ConsumeLowestPriorityItems()
        end
    end

    --Step 4: go from highest ingredient_priority, highest item_priority, and start actually consuming the ingredients.
    for ingredient_priority, ingredient_allocation in ipairs(self.ingredient_allocations) do
        ingredient_allocation:FinishConsuming()
    end

    consumefinishedcount = 0
    while consumefinishedcount < #self.ingredient_allocations do
        for ingredient_priority, ingredient_allocation in ipairs(self.ingredient_allocations) do
            consumefinishedcount = (ingredient_allocation:ConsumeHighestPriorityItems() and 0) or (consumefinishedcount + 1)
            if consumefinishedcount == #self.ingredient_allocations then break end
        end
    end
    self.allowinvalid = nil

    local ingredientdata = {}
    for ingredient_priority, ingredient_allocation in ipairs(self.ingredient_allocations) do
        local ingredient = ingredient_allocation:GetIngredientSet():GetIngredient()
        ingredientdata[ingredient] = ingredient_allocation:GetRecipePopupData()
    end
    return ingredientdata
end

return IngredientAllocator