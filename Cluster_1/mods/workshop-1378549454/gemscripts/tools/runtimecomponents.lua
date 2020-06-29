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

function EntityScript:AddComponentAtRuntime(name)
    if self.components[name] then
        print("component "..name.." already exists! -- AddComponentAtRuntime")
        return
    end
    
    self:AddComponent(name)
    if not self.RuntimeComponents then
        self.RuntimeComponents = {}
    end
    self.RuntimeComponents[name] = name

end

function EntityScript:RemoveComponentAtRuntime(name)
    if not self.RuntimeComponents[name] then
        print("Tried to remove a component using 'RemoveComponentAtRuntime' that wasn't added using 'AddComponentAtRuntime'! Aborting!")
        return
    end
    self:RemoveComponent(name)
    self.RuntimeComponents[name] = nil
end

local _GetPersistData = EntityScript.GetPersistData
function EntityScript:GetPersistData(...)
    local data, references = _GetPersistData(self, ...)
    if self.RuntimeComponents then
        if not data then data = {} end
        data.RuntimeComponents = {}
        for k,v in pairs(self.RuntimeComponents) do
            if v then
                table.insert(data.RuntimeComponents, v)
            end
        end
    end

    if (data and next(data)) or references then
        return data, references
    end
end

local _SetPersistData = EntityScript.SetPersistData
function EntityScript:SetPersistData(data, newents, ...)
    if data and data.RuntimeComponents then
        for k,v in pairs(data.RuntimeComponents) do
            self:AddComponentAtRuntime(v)
        end
    end 
    return _SetPersistData(self, data, newents, ...)
end