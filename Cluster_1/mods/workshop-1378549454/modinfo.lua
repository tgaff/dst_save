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
name = "[API] Gem Core"
version = "5.1.19"
credits = "\n\nCredits:\nZarklord - For creating this API.\nFidooop - For ensuring things were done right.\nRezecib - For his wonderful upvalue hacker.\nNSimplex - For memspikefix."
description = "Version: "..version.."\nLibrary of powerful modding tools for mod developers.\n\nVisit https://gitlab.com/DSTAPIS/GemCore/wikis/home for API info"..credits
author = "Zarklord"

restart_required = false

dst_compatible = true

api_version_dst = 10

--Custom field that lets the mods detect this mod more easily.
GemCore = true

if not folder_name:find("workshop-") then
    name = name.." - GitLab Version"
    version = version.."G"
    GemCoreGitLab = true
end

--largest number for priority possible
priority = 3.4028e+38

icon_atlas = "gemcore.xml"
icon = "gemcore.tex"

all_clients_require_mod = true
client_only_mod = false


server_filter_tags =
{
    "gemcore",
}

configuration_options = {
    {
        name = "craftinghighlight",
        label   = "Highlight Crafting Ingredients",
        hover   = "When crafting, Highlight all items that can be used to craft the current recipe.",
        options = {
            {description = "Always", data = true},
            {description = "Gem Dict Recipes", data = false},
        },
        default = false,
    },
}
