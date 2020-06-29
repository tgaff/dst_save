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

local GemDict_CraftingInfo = Class(function(self, inst)
    self.inst = inst
    self.ingredientsdata = {}
end)

function GemDict_CraftingInfo:OnSave()
    return {ingredientsdata = self.ingredientsdata}
end

function GemDict_CraftingInfo:OnLoad(data)
    self.ingredientsdata = data.ingredientsdata
end

function GemDict_CraftingInfo:GetIngredientsData()
    return self.ingredientsdata
end

return GemDict_CraftingInfo