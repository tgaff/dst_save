--[[
Copyright (C) 2019 Zarklord

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
local BinaryString = gemrun("binarystring")

local function CreateOriginalTileMap(map)
    local TileMapping, TileString = {}, map.tiles
    local currentx, currenty = 0, 0

    for tileid in iterator(BinaryString(TileString), 9, nil, nil, 2, 1) do
        TileMapping[currentx] = TileMapping[currentx] or {}
        TileMapping[currentx][currenty] = tileid
        currentx = currentx + 1
        if currentx >= map.width then
            currenty = currenty + 1
            currentx = 0
        end
    end

    return TileMapping
end

if rawget(_G, "Map") then
    function Map:GetOriginalTile(x, y)
        if TheWorld.topology.original_tiles == nil then
            return GROUND.IMPASSABLE
        end
        return TheWorld.topology.original_tiles[x] and TheWorld.topology.original_tiles[x][y] or GROUND.INVALID
    end

    function Map:GetOriginalTileAtPoint(x, y, z)
        return self:GetOriginalTile(self:GetTileXYAtPoint(x, y, z))
    end
end

--it doesn't matter which of these gets called on first load,
--since if this doinitgame got called first, then the tileconversion callback would adjust the tiles,
--if the tileconversion callback got called, nothing would happen, then the ondoinitgame callback would just make the map with already adjusted tiles.
gemrun("ondoinitgame", function(callback, savedata, ...)
    if not savedata.map.topology.original_tiles then
        savedata.map.topology.original_tiles = CreateOriginalTileMap(savedata.map)
    end
    callback(savedata, ...)
end)

gemrun("ontileconversion", function(savedata, conversionmap)
    local original_tiles = savedata.map.topology.original_tiles
    for x, v in pairs(original_tiles or {}) do
        for y, v1 in pairs(v) do
            original_tiles[x][y] = conversionmap[v1] or v1
        end
    end
end)