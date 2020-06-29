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

require "class"

local IngredientUI = require "widgets/ingredientui"

local GemDictIngredientUI = Class(IngredientUI, function(self, images, quantity, counts, names, owner, recipe_type)
    assert(IsGemDictIngredient(recipe_type), "recipe_type for GemDictIngredientUI is not "..GEMDICT_INGREDIENT)
    IngredientUI._ctor(self, images[1].atlas, images[1].image, quantity, counts[1].on_hand, counts[1].has_enough, names[1], owner, recipe_type)

    self.quantity = quantity
    self.builder = owner.replica.builder

    self.images = images
    self.counts = counts
    self.names = names
    self.index = 1
    self.dt = 0

    if #images > 1 then
        self:StartUpdating()
    end
end)

function GemDictIngredientUI:OnUpdate(dt)
    self.dt = self.dt + dt
    if self.dt >= 1 then
        self.dt = 0
        self.index = (#self.images == self.index and 1) or (self.index + 1)
        self.ing:SetTexture(self.images[self.index].atlas, self.images[self.index].image)
        self:SetTooltip(self.names[self.index])
        self:UpdateQuantity(self.quantity, self.counts[self.index].on_hand, self.counts[self.index].has_enough, self.builder)
    end
end


return GemDictIngredientUI
