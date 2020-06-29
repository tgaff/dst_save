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

local map_data = {}
local map_tags = {}

local MapTagger = {}

--TODO, allow deleting vanilla map data? maybe?
function MapTagger.AddMapData(dataname, value)
    map_data[dataname] = value
end
--TODO, allow deleting vanilla map tags? maybe?
function MapTagger.AddMapTag(tagname, fn)
    map_tags[tagname] = fn
end

local _MakeTags
local function MakeTags(...)
    if not _MakeTags then
        local _map_maptags_preload = package.preload["map/maptags"]
        local _map_maptags_loaded= package.loaded["map/maptags"]
        package.preload["map/maptags"] = nil
        package.loaded["map/maptags"] = nil
        _MakeTags = require("map/maptags")
        package.preload["map/maptags"] = _map_maptags_preload
        package.loaded["map/maptags"] = _map_maptags_loaded
    end

    local maptags = deepcopy(_MakeTags(...))
    for k, v in pairs(map_data) do
        maptags.TagData[k] = v
    end
    for k, v in pairs(map_tags) do
        maptags.Tag[k] = v
    end
    return maptags
end

package.loaded["map/maptags"] = nil
package.preload["map/maptags"] = function() return MakeTags end --this effictively replaces the return value of map/maptags, if the value was cleared from package.loaded.

return MapTagger