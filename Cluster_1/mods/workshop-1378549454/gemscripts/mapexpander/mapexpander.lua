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
local BinaryString = require("binarystring")

local MAP_BORDER_SIZE = 20

local function ExpandMap(savedata)
    print("Loading Dynamic Gem Core Tiles!")
    print(savedata.map.prefab)
    --[[
    if savedata.map.prefab == "forest" then
        print(savedata.map.width, savedata.map.height)
        local _navmap = BinaryString(savedata.map.nav, "nav")
        local _tilemap = BinaryString(savedata.map.tiles, "tiles")
    end
    --assert(false)
    --]]
    --[[
    basic flow:
    create a brand new binary string
    start filling in the rows of savedata.map.width * 3 with impassable tiles
    when we hit the first spot where the original game tiles exist, run a copy into for that row
    ]]

    print(savedata.map.topology._tiles)
    if not savedata.map.topology._tiles then
        local _width, _height = savedata.map.width, savedata.map.height
        print(_width, _height)
        local _tilemap = BinaryString(savedata.map.tiles)
        local _navmap = BinaryString(savedata.map.nav)
        local tilemap = BinaryString()
        local navmap = BinaryString()

        --"VRSN\x0001000000"
        local VRSN1 = {0x56, 0x52, 0x53, 0x4E, 0x00, 0x01, 0x00, 0x00, 0x00}
        tilemap:DirectWrite(VRSN1)
        navmap:DirectWrite(VRSN1)

        local width_add = _width + MAP_BORDER_SIZE
        local height_add = _height + MAP_BORDER_SIZE

        local IMPASSABLE_TILES = {GROUND.IMPASSABLE, 0x10}
        local IMPASSABLE_NAV = {0xFF, 0x7F}
        tilemap:Fill(IMPASSABLE_TILES, (width_add * 2 + _width) * height_add)
        navmap:Fill(IMPASSABLE_NAV, (width_add * 2 + _width) * height_add)
        for i = 1, _height do
            tilemap:Fill(IMPASSABLE_TILES, width_add)
            navmap:Fill(IMPASSABLE_NAV, width_add)
            _tilemap:CopyTo(tilemap, 9 + ((i - 1) * _width * 2), _width * 2)
            _navmap:CopyTo(navmap, 9 + ((i - 1) * _width * 2), _width * 2)
            tilemap:Fill(IMPASSABLE_TILES, width_add)
            navmap:Fill(IMPASSABLE_NAV, width_add)
        end
        tilemap:Fill(IMPASSABLE_TILES, (width_add * 2 + _width) * height_add)
        navmap:Fill(IMPASSABLE_NAV, (width_add * 2 + _width) * height_add)

        savedata.map.topology._tiles = savedata.map.topology._tiles or savedata.map.tiles
        savedata.map.topology._nav = savedata.map.topology._nav or savedata.map.nav
        savedata.map.topology._width = savedata.map.topology._width or savedata.map.width
        savedata.map.topology._height = savedata.map.topology._height or savedata.map.height

        savedata.map.tiles = tilemap:GetAsString()
        savedata.map.nav = navmap:GetAsString()
        savedata.map.width = _width + width_add * 2
        savedata.map.height = _height + height_add * 2

        print(savedata.map.width, savedata.map.height)
    end
end
