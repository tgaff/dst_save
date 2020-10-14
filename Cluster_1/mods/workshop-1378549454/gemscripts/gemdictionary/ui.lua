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

local RecipePopup = require("widgets/recipepopup")
local IngredientUI = require("widgets/ingredientui")

function IngredientUI:UpdateQuantity(quantity, on_hand, has_enough, builder)
    if builder ~= nil then
        quantity = math.round(quantity * builder:IngredientMod())
    end
    local hud_atlas = resolvefilepath("images/hud.xml")
    self.bg:SetTexture(hud_atlas, has_enough and "inv_slot.tex" or "resource_needed.tex")
    self.quant:SetString(string.format("%d/%d", on_hand, quantity))
    if has_enough then
        self.quant:SetColour(255/255, 255/255, 255/255, 1)
    else
        self.quant:SetColour(255/255, 155/255, 155/255, 1)
    end
end

local GemDictIngredientUI = require("widgets/gemdictingredientui")
local IngredientAllocator = gemrun("gemdictionary/ingredientallocator")

local function ImageTableContainsImage(imagetable, image)
    for i, v in ipairs(imagetable) do
        if v.image == image then
            return i
        end
    end
    return true
end

local craftinghighlight = GEMENV.GetModConfigData("craftinghighlight", true)

local visible_recipepopup = nil --I hate this!!!

local startidx
local localdata
local RecipePopupRefreshEnv = setmetatable({
    ipairs = function(t, ...)
        if not localdata then return ipairs(t, ...) end
        local self = localdata.self

        local recipe = self.recipe

        if t == self.ing then
            --increase the size of the tech ingredients table so the ui spaces the ingredients properly.
            localdata._tech_ingredients = recipe.tech_ingredients
            recipe.tech_ingredients = ExtendedArray({}, {true}, #recipe.tech_ingredients + #recipe.gemdict_ingredients)
        elseif t == recipe.tech_ingredients then
            --if t is ever == to my modified tech ingredients table, replace it with the proper value before iterating
            t = localdata._tech_ingredients
            recipe.tech_ingredients = localdata._tech_ingredients
        elseif t == recipe.ingredients then
            --obtain the index where recipe.ingredients start.
            startidx = #self.ing + 1
        elseif t == recipe.character_ingredients then
            local owner = self.owner
            local builder = owner.replica.builder
            --get the local variables from _Refresh
            local num
            local w
            local half_div
            local offset
            local stacklevel = 2
            while debug.getinfo(stacklevel, "n") ~= nil do
                num = LocalVariableHacker.GetLocalVariable(stacklevel, "num")
                w = LocalVariableHacker.GetLocalVariable(stacklevel, "w")
                half_div = LocalVariableHacker.GetLocalVariable(stacklevel, "half_div")
                offset = LocalVariableHacker.GetLocalVariable(stacklevel, "offset")
                if num ~= nil and offset ~= nil and w ~= nil ~= nil and half_div ~= nil then
                    break
                end
                stacklevel = stacklevel + 1
            end

            local ingredientdata = IngredientAllocator(recipe):GetRecipePopupIngredients(owner, builder:IngredientMod())

            --update recipe.ingredients, if some of the items it thought were avaliable actually weren't
            for i = startidx, #self.ing do
                local ingredient = recipe.ingredients[1 + (i - startidx)]
                local _ingredientdata = ingredientdata[ingredient]
                self.ing[i]:UpdateQuantity(ingredient.amount, _ingredientdata.num_found, _ingredientdata.has, builder)

                for item, count in pairs(_ingredientdata.items) do
                    item:PushEvent("gemdict_setstate", count)
                end
            end

            for i, v in ipairs(recipe.gemdict_ingredients) do
                local _ingredientdata = ingredientdata[v]
                local images, names, counts = v:GetImages(not _ingredientdata.has, _ingredientdata.num_found, not _ingredientdata.nomix and _ingredientdata.has or false)
                if _ingredientdata.nomix then
                    for i1, v1 in ipairs(_ingredientdata) do
                        for item, count in pairs(v1.items) do
                            local image = item.replica.inventoryitem:GetImage()
                            local index = ImageTableContainsImage(images, image)
                            if index then
                                counts[index].on_hand = v1.num_found
                                counts[index].has_enough = v1.has
                            else
                                table.insert(images, {image = image, atlas = item.replica.inventoryitem:GetAtlas()})
                                table.insert(names, item:GetBasicDisplayName())
                                table.insert(counts, {on_hand = v1.num_found, has_enough = v1.has})
                            end
                            item:PushEvent("gemdict_setstate", count)
                        end
                    end
                else
                    --obtain inv images, and names from val, and use them if they aren't already present in the list of images.
                    for item, count in pairs(_ingredientdata.items) do
                        local image = item.replica.inventoryitem:GetImage()
                        if not ImageTableContainsImage(images, image) then
                            table.insert(images, {image = image, atlas = item.replica.inventoryitem:GetAtlas()})
                            table.insert(names, item:GetBasicDisplayName())
                            table.insert(counts, {on_hand = _ingredientdata.num_found, has_enough = _ingredientdata.has})
                        end
                        item:PushEvent("gemdict_setstate", count)
                    end
                end

                local ing = self.contents:AddChild(GemDictIngredientUI(images, v.amount, counts, names, owner, v.type))

                if GetGameModeProperty("icons_use_cc") then
                    ing.ing:SetEffect("shaders/ui_cc.ksh")
                end
                if num > 1 and #self.ing > 0 then
                    offset = offset + half_div
                end
                ing:SetPosition(Vector3(offset, self.skins_spinner ~= nil and 110 or 80, 0))
                offset = offset + w + half_div
                table.insert(self.ing, ing)
            end

            LocalVariableHacker.SetLocalVariable(stacklevel, "offset", offset)
        end
        return ipairs(t, ...)
    end
}, {__index = _G, __newindex = _G})
setfenv(RecipePopup.Refresh, RecipePopupRefreshEnv)

local _Refresh = RecipePopup.Refresh
function RecipePopup:Refresh(...)
    localdata = nil

    local owner = self.owner
    if owner == nil then
        return _Refresh(self, ...)
    end

    if self:IsVisible() then
        visible_recipepopup = self
        if craftinghighlight or self.recipe:HasGemDictIngredients() then
            self.owner:PushEvent("gemdict_setoverlay")
        else
            self.owner:PushEvent("gemdict_resetoverlay")
            return _Refresh(self, ...)
        end
    else
        return _Refresh(self, ...)
    end

    local recipe = self.recipe

    localdata = {self = self}

    return _Refresh(self, ...)
end

--4 states:
--state > 0, show consumecount, and hide overlay
--state == 0, hide consumecount, and hide overlay
--state == false, hide consumecount, show overlay
--state == nil, hide consumecount, hide overlay
local function SetGemDictState(self, state)
    self.gemdict_ingredientoverlay:Hide()
    self.gemdict_consumecount:Hide()
    if state ~= nil then
        if not state then
            self.gemdict_ingredientoverlay:Show()
            self.gemdict_ingredientoverlay:MoveToFront()

            if self.quantity ~= nil then
                self.quantity:MoveToFront()
            end
        elseif state > 0 then
            self.gemdict_consumecount:Show()
            self.gemdict_consumecount:MoveToFront()
            self.gemdict_consumecount:SetString(tostring(state))
        end
    end
end

local function Refresh(self, ...)
    self:SetGemDictState(self.item._gemdictstate)
end

local Text = require("widgets/text")
local Image = require("widgets/image")

GEMENV.AddClassPostConstruct("widgets/itemtile", function(self)
    self.gemdict_ingredientoverlay = self:AddChild(Image("images/gemdict_ui.xml", "gemdict_ingredientoverlay.tex"))
    self.gemdict_ingredientoverlay:SetTint(255/255, 255/255, 255/255, 0.5)
    self.gemdict_ingredientoverlay:SetClickable(false)
    self.gemdict_ingredientoverlay:Hide()

    self.gemdict_consumecount = self:AddChild(Text(NUMBERFONT, 36))
    self.gemdict_consumecount:SetPosition(24, 16, 0)
    self.gemdict_consumecount:SetClickable(false)
    self.gemdict_consumecount:Hide()


    self.inst:ListenForEvent("gemdict_setstate", function(invitem, state)
        invitem._gemdictstate = state and ((invitem._gemdictstate or 0) + state) or state
        self:SetGemDictState(invitem._gemdictstate)
    end, self.item)

    local _Refresh = self.Refresh
    function self:Refresh(...)
        _Refresh(self, ...)
        Refresh(self, ...)
    end

    local _StartDrag = self.StartDrag
    function self:StartDrag(...)
        _StartDrag(self, ...)
        self:SetGemDictState(nil)
    end

    self.SetGemDictState = SetGemDictState

    Refresh(self)
end)

local function SetItemlessGemDictState(self, state)
    if state == false then
        self.gemdict_ingredientoverlay:Show()
        self.gemdict_ingredientoverlay:MoveToFront()
    elseif state == nil then
        self.gemdict_ingredientoverlay:Hide()
    end
end

GEMENV.AddClassPostConstruct("widgets/itemslot", function(self)
    self.gemdict_ingredientoverlay = self:AddChild(Image("images/gemdict_ui.xml", "gemdict_ingredientoverlay.tex"))
    self.gemdict_ingredientoverlay:SetTint(255/255, 255/255, 255/255, 0.5)
    self.gemdict_ingredientoverlay:SetClickable(false)
    self.gemdict_ingredientoverlay:Hide()

    self.inst:ListenForEvent("gemdict_resetoverlay", function(owner)
        local item = self.tile and self.tile.item
        if type(item) == "table" then
            item:PushEvent("gemdict_setstate")
        else
            self:SetItemlessGemDictState()
        end
    end, self.owner)
    self.inst:ListenForEvent("gemdict_setoverlay", function(owner)
        local item = self.tile and self.tile.item
        if type(item) == "table" then
            item:PushEvent("gemdict_setstate", false)
        else
            self:SetItemlessGemDictState(false)
        end
    end, self.owner)

    local _SetTile = self.SetTile
    function self:SetTile(tile, ...)
        if tile then
            self:SetItemlessGemDictState()
        end
        return _SetTile(self, tile, ...)
    end

    self.SetItemlessGemDictState = SetItemlessGemDictState

end)

GEMENV.AddClassPostConstruct("widgets/craftslot", function(self)
    local _HideRecipe = self.HideRecipe
    function self:HideRecipe(...)
        _HideRecipe(self, ...)
        if self.recipepopup and not self.recipepopup:IsVisible() and self.recipepopup == visible_recipepopup then
            self.owner:PushEvent("gemdict_resetoverlay")
        end
    end
end)

GEMENV.AddClassPostConstruct("widgets/crafttabs", function(self)
    local _CloseControllerCrafting = self.CloseControllerCrafting
    function self:CloseControllerCrafting(...)
        self.owner:PushEvent("gemdict_resetoverlay")
        _CloseControllerCrafting(self, ...)
    end
end)