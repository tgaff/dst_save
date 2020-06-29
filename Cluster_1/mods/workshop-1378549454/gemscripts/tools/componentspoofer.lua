--[[
Copyright (C) 2018 Zarklord

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

local COMPONENTS_REPLICATED_AS = {}

local function AddSpoofedReplicableComponent(componentname, name)
	COMPONENTS_REPLICATED_AS[componentname] = name
end

local Replicas = UpvalueHacker.GetUpvalue(EntityScript.ReplicateComponent, "Replicas")
local REPLICATABLE_COMPONENTS = UpvalueHacker.GetUpvalue(EntityScript.ReplicateEntity, "REPLICATABLE_COMPONENTS")
local LoadComponent = UpvalueHacker.GetUpvalue(EntityScript.AddComponent, "LoadComponent")

function EntityScript:ReplicateSpoofedComponent(componentname, name)
    if not REPLICATABLE_COMPONENTS[componentname] then
        return
    end

	self:AddTag(componentname.."_SpoofedAs_"..name)

    if TheWorld.ismastersim then
        self:AddTag("_"..name)
        if self:HasTag("__"..name) then
            self:RemoveTag("__"..name)
            return
        end
    end

    if rawget(self.replica, "_")[name] ~= nil then
        print("replica "..name.." already exists! "..debugstack_oneline(3))
    end

    local filename = componentname.."_replica"
    local cmp = Replicas[filename]
    if cmp == nil then
        cmp = require("components/"..filename)
        Replicas[filename] = cmp
    end
    modassert(cmp ~= nil, "replica "..componentname.." does not exist!")

    rawset(self.replica._, name, cmp(self))
end

function EntityScript:AddSpoofedComponent(componentname, name)
	local lower_name = string.lower(name)
	if self.lower_components_shadow[lower_name] ~= nil then
		print("component "..name.." already exists!"..debugstack_oneline(3))
	end

	local cmp = LoadComponent(componentname)
	modassert(cmp, "component ".. componentname .. " does not exist!")

	self:ReplicateSpoofedComponent(componentname, name)

	local loadedcmp = cmp(self)
	self.components[name] = loadedcmp
	self.lower_components_shadow[lower_name] = true

	local postinitfns = ModManager:GetPostInitFns("ComponentPostInit", componentname)

	for i, fn in ipairs(postinitfns) do
		fn(loadedcmp, self)
	end

	self:RegisterComponentActions(name)
end

local _ReplicateEntity = EntityScript.ReplicateEntity
EntityScript.ReplicateEntity = function(self)
	local SpoofedList = {}
	for k, v in pairs(COMPONENTS_REPLICATED_AS) do
		if self:HasTag(k.."_SpoofedAs_"..v) then
            SpoofedList[k] = v
		end
	end
    local MimicList = table.invert(SpoofedList)
	if not IsTableEmpty(SpoofedList) then
	    for k, v in pairs(REPLICATABLE_COMPONENTS) do
	        if v and SpoofedList[k] then
	            self:ReplicateSpoofedComponent(k, COMPONENTS_REPLICATED_AS[k])
	        elseif v and (self:HasTag("_"..k) or self:HasTag("__"..k)) and not MimicList[k] then
	            self:ReplicateComponent(k)
	        end
	    end

	    if self.OnEntityReplicated ~= nil then
	        self:OnEntityReplicated()
	    end
	else
		_ReplicateEntity(self)
	end
end

return AddSpoofedReplicableComponent