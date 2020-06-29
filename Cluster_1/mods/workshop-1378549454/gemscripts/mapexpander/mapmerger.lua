--[[
Copyright (C) 2019, 2020 Zarklord

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

local function EncodeColors(existing, new)
    local function FindColor(map, c)
        for i, v in ipairs(map) do
            if v.r == c.r and
            v.g == c.g and
            v.b == c.b and
            v.a == c.a then
                return i
            end
        end
        return nil
    end
    local conversionmap = {}
    for i, v in ipairs(new.colours) do
        local id = FindColor(existing, v)
        if not id then
            table.insert(existing, v)
            id = #existing
        end
        conversionmap[i] = id
    end
    return conversionmap
end

local function MapMerger(main, merge, id)
    assert(id >= 1 and id <= 8, "id is invalid, must be a value between 1 and 8")

    local colorconversionmap = EncodeColors(main.map.topology.colours, merge.map.topology.colours)

    local worldxoffset = main.map.topology.exmap[id].xoffset
    local worldzoffset = main.map.topology.exmap[id].zoffset
    local densitiesadd = main.map.topology.exmap[id].densitiesadd
    if merge.map.generated and merge.map.generated.densities then
        main.map.generated = main.map.generated or {}
        main.map.generated.densities = main.map.generated.densities or {}
        local _densities = main.map.generated.densities
        local densities = merge.map.generated.densities

    end

    --useless? either way, its a simple append to the end.
    for i, v in ipairs(merge.map.topology.story_depths) do
        main.map.topology.story_depths[#main.map.topology.story_depths] = v
    end

    main.map.topology.exmap[id].overrides = merge.map.topology.overrides
    main.map.topology.exmap[id].meta = {}
    main.map.topology.exmap[id].meta.level_id = merge.meta.level_id
    main.map.topology.exmap[id].meta.seed = merge.meta.seed

    for k, v in pairs(merge.ents) do
        main.ents[k] = main.ents[k] or {}
        local _ent = main.ents[k]
        for i1, v1 in pairs(v) do
            v1.x = v1.x - worldxoffset
            v1.z = v1.z - worldzoffset
            table.insert(_ent, v1)
        end
    end
end