--[[
Copyright (C) 2018-2020 Zarklord

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

local containers = require("containers")

--Zarklord: i cant think of a reason why you would want to access this
--but if its needed I can add a api for you to access the raw container
local params = UpvalueHacker.GetUpvalue(containers.widgetsetup, "params")

local function AddContainerWidget(name, data)
	params[name] = data
end

local function packstring(...)
    local str = ""
    local n = select('#', ...)
    local args = toarray(...)
    for i=1,n do
        str = str..tostring(args[i]).."\t"
    end
    return str
end
--extremly useful for debugging' as you dont need to write unique messages for checking code path's if you want to check this way.
local function DebugPrint(...)
	print((debug.getinfo(2,'S').source or "Unkown Source").." "..(debug.getinfo(2, "n").name or "Unkown Name").." "..(debug.getinfo(2, 'l').currentline or "Unkown Line").." "..(packstring(...) or ""))
end

local function minitraceback()
    for level = 3, 13 do
        local info = debug.getinfo(level, "Sl")
        if not info then break end
        if info.what == "C" then
            print(level, "C function")
        else
            print(string.format("[%s]:%d", info.short_src, info.currentline))
        end
    end
end

require("simutil")
local inventoryItemAtlasLookup = UpvalueHacker.GetUpvalue(GetInventoryItemAtlas, "inventoryItemAtlasLookup")
local custom_atlases = {}
local _GetInventoryItemAtlas = GetInventoryItemAtlas
function GetInventoryItemAtlas(imagename, ...)
    local atlas = inventoryItemAtlasLookup[imagename]
    if atlas then _GetInventoryItemAtlas(imagename, ...) end
    for i, custom_atlas in ipairs(custom_atlases) do
        atlas = TheSim:AtlasContains(custom_atlas, imagename) and custom_atlas or nil
        if atlas then
            inventoryItemAtlasLookup[imagename] = atlas
            return atlas
        end
    end
    return _GetInventoryItemAtlas(imagename, ...)
end
gemrun("hidefn", GetInventoryItemAtlas, _GetInventoryItemAtlas)

local function AddInventoryItemAtlas(atlas)
    table.insert(custom_atlases, atlas)
end

local function GetNextAvaliableCollisionMask()
    local mask = 0
    for k, v in pairs(COLLISION) do
        mask = bit.bor(mask, v)
    end
    local i = 1
    while i <= 0x7FFF do
        if bit.band(mask, i) == 0 then
            print("Collision Mask: ", i, " Found!")
            return i
        end
        i = i * 2
    end
    print("ERROR: Ran out of available collision mask's")
    return 0
end

return {
	Global = {
		DebugPrint = DebugPrint,
        minitraceback = minitraceback,
        GetNextAvaliableCollisionMask = GetNextAvaliableCollisionMask,
	},
	Local = {
		DebugPrint = DebugPrint,
		AddContainerWidget = AddContainerWidget,
        AddInventoryItemAtlas = AddInventoryItemAtlas,
	},
}