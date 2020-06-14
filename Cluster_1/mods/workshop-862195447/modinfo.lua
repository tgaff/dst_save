--[[
Copyright (C) 2018 Zarklord

This file is part of Followers For Everyone.

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
name = "Followers For Everyone!"
description = "(Formerly Chester For Everyone!)\n\nAllows each player to obtain a chester and a hutch and a packim baggims(if Island Adventures is installed)(Or more than one!)."
author = "Zarklord"
version = "2.2"
forumthread = ""

restart_required = false

dst_compatible = true

api_version =  10
api_version_dst = 10

icon_atlas = "followers.xml"
icon = "followers.tex"

priority = 2

all_clients_require_mod = true
client_only_mod = false

if folder_name ~= "workshop-862195447" then
    name = " "..name.." - Git Ver"
end

server_filter_tags = 
{ 
    "chester",
    "hutch",
    "packim",
    "player_chester",
    "player_hutch",
    "player_packim",
    "personal_chester",
    "personal_hutch",
    "personal_packim",
}

local function Title(title,hover)
    return {
        name=title,
        hover=hover,
        options={{description = "", data = 0}},
        default=0,
    }
end

configuration_options =
{
    Title("MAIN"),
    {
        name = "followertypes",
        label = "Follower Types",
        hover = "What types of followers that this mod applies to.\nWARNING: Changing this on existing saves could have unpredictable results.",
        options =
        {
            --[[
            alright now i know that these numbers must seem arbitrary but they aren't
            this is using bit flags:
            chester 3rd bit (enabled if 4, 5, 6, 7)
            hutch 2nd bit (enabled if 2, 3, 5, 7)
            packim(when IA comes out) 1st bit (enabled if 1, 3, 5, and 7)
            we also use value 7 as the default so that when packim support is added it will just work.
            --]]
            {description = "Chester+Hutch+P...", data = 7, hover = "Chester + Hutch + Packim Baggims"},
            {description = "Chester+Hutch", data = 6, hover = "Chester + Hutch"},
            {description = "Chester+Packim", data = 5, hover = "Chester + Packim Baggims"},
            {description = "Hutch+Packim", data = 3, hover = "Hutch + Packim Baggims"},
            {description = "Chester", data = 4, hover = "Chester"},
            {description = "Hutch", data = 2, hover = "Hutch"},
            {description = "Packim", data = 1, hover = "Packim Baggims"},
        },
        default = 7
    },
    {
        name = "ownership",
        label = "Ownership Restriction?",
        options =
        {
            {description = "Enable", data = true},
            {description = "Disable", data = false}
        },
        default = false,
    },
    Title("CHESTER", "Configuration options relating to Chester."),
    {
        name = "chester_craft",
        label = "Crafting Difficulty",
        hover = "The Difficulty of Crafting it.",
        options =
        {
            {description = "Easy", data = '{Ingredient("twigs", 2),Ingredient("rope", 1),Ingredient("goldnugget", 2)}', hover = "2 Twigs, 1 Rope, 2 Gold."},
            {description = "Medium", data = '{Ingredient("livinglog", 1),Ingredient("rope", 1),Ingredient("goldnugget", 1),Ingredient("nightmarefuel", 1)}', hover = "1 Living Log, 1 Rope, 1 Gold, 1 Nightmare Fuel."},
            {description = "Hard", data = '{Ingredient("livinglog", 2),Ingredient("rope", 1),Ingredient("gears", 2),Ingredient("nightmarefuel", 2)}', hover = "2 Living Log, 1 Rope, 2 Gears, 2 Nightmare Fuel."},
            {description = "Hardcore", data = '{Ingredient("livinglog", 1),Ingredient("rope", 1),Ingredient("deerclops_eyeball", 1),Ingredient("nightmarefuel", 1)}', hover = "1 Living Log, 1 Rope, 1 Deerclops Eyeball, 1 Nightmare Fuel."},
        },
        default = '{Ingredient("livinglog", 1),Ingredient("rope", 1),Ingredient("goldnugget", 1),Ingredient("nightmarefuel", 1)}'
    },
    {
        name = "chester_science",
        label = "Machine To Craft",
	    hover = "What Tech Level do you need to craft it?",
        options =
        {
            {description = "None", data = 'nil', hover = "Requires: Nothing!"},
            {description = "Science Machine", data = '{tech = TUNING.PROTOTYPER_TREES.SCIENCEMACHINE, hint = string.sub(STRINGS.UI.CRAFTING.NEEDSCIENCEMACHINE, 1, -14).." this!"}', hover = "Requires: Science Machine!"},
            {description = "Alchemy Engine", data = '{tech = TUNING.PROTOTYPER_TREES.ALCHEMYMACHINE, hint = string.sub(STRINGS.UI.CRAFTING.NEEDALCHEMYENGINE, 1, -14).." this!"}', hover = "Requires: Alchemy Engine!"},
            {description = "Prestihatita...", data = '{tech = TUNING.PROTOTYPER_TREES.PRESTIHATITATOR, hint = string.sub(STRINGS.UI.CRAFTING.NEEDPRESTIHATITATOR, 1, -14).." this!"}', hover = "Requires: Prestihatitator!"},
            {description = "Shadow Manip...", data = '{tech = TUNING.PROTOTYPER_TREES.SHADOWMANIPULATOR, hint = string.sub(STRINGS.UI.CRAFTING.NEEDSHADOWMANIPULATOR, 1, -14).." this!"}', hover = "Requires: Shadow Manipulator!"},
        },
        default = '{tech = TUNING.PROTOTYPER_TREES.SHADOWMANIPULATOR, hint = string.sub(STRINGS.UI.CRAFTING.NEEDSHADOWMANIPULATOR, 1, -14).."!"}',
    },
    {
        name = "chester_max",
        label = "Max Chesters?",
        hover = "Max Chesters Per Player?",
        options =
        {
            {description = "1", data = 1},
            {description = "2", data = 2},
            {description = "3", data = 3},
            {description = "4", data = 4},
            {description = "5", data = 5},
            {description = "6", data = 6},
            {description = "7", data = 7},
            {description = "8", data = 8},
            {description = "9", data = 9},
            {description = "10", data = 10},
        },
        default = 1,
    },
    {
        name = "chester_locations",
        label = "Allowed Shard Types",
        hover = "What Shards is chester allowed to go to(forest, cave, ect)?",
        options =
        {
            --for dedicated servers this is a list of tags to check to see if that shard can have a chester
            --due to tecnical limitations your never allowed to prevent chester from being allowed in his default game world(in this case the forest)
            --set data = 'nil' to remove all shard restrictions
            --encapsulate all data as a string because of stupid tecnical reasons
            {description = "Forests", data = '{}'},
            {description = "Forests + Caves", data = '{"cave"}', hover = "Forests, And Caves"},
            {description = "Forests + Is...", data = '{"island"}', hover = "Forests, And Islands"},
            {description = "Forests + Ca...", data = '{"cave", "island"}', hover = "Forests, Caves, And Islands"},
        },
        default = '{}',
    },
    Title("HUTCH", "Configuration options relating to Hutch."),
    {
        name = "hutch_craft",
        label = "Crafting Difficulty",
        hover = "The Difficulty of Crafting it.",
        options =
        {
            {description = "Easy", data = '{Ingredient("ice", 1),Ingredient("waterballoon", 1),Ingredient("fish", 1)}', hover = "1 Ice, 1 Water Balloon, 1 Fish."},
            {description = "Medium", data = '{Ingredient("ice", 1),Ingredient("waterballoon", 4),Ingredient("fish", 1),Ingredient("bluegem", 1)}', hover = "1 Ice, 4 Water Balloons, 1 Fish, 1 Blue Gem."},
            {description = "Hard", data = '{Ingredient("ice", 4),Ingredient("waterballoon", 8),Ingredient("fish", 1),Ingredient("nightmarefuel", 1),Ingredient("bluegem", 2)}', hover = "4 Ice, 8 Water Balloons, 1 Fish, 1 Nightmare Fuel, 2 Blue Gems."},
            {description = "Hardcore", data = '{Ingredient("ice", 10),Ingredient("waterballoon", 20),Ingredient("fish", 1),Ingredient("nightmarefuel", 5),Ingredient("bluegem", 10)}', hover = "10 Ice, 20 Water Balloons, 1 Fish, 5 Nightmare Fuel, 10 Blue Gems."},
        },
        default = '{Ingredient("ice", 1),Ingredient("waterballoon", 4),Ingredient("fish", 1),Ingredient("bluegem", 1)}'
    },
    {
        name = "hutch_science",
        label = "Machine To Craft",
        hover = "What Tech Level do you need to craft it?",
        options =
        {
            {description = "None", data = 'nil', hover = "Requires: Nothing!"},
            {description = "Science Machine", data = '{tech = TUNING.PROTOTYPER_TREES.SCIENCEMACHINE, hint = string.sub(STRINGS.UI.CRAFTING.NEEDSCIENCEMACHINE, 1, -14).." this!"}', hover = "Requires: Science Machine!"},
            {description = "Alchemy Engine", data = '{tech = TUNING.PROTOTYPER_TREES.ALCHEMYMACHINE, hint = string.sub(STRINGS.UI.CRAFTING.NEEDALCHEMYENGINE, 1, -14).." this!"}', hover = "Requires: Alchemy Engine!"},
            {description = "Prestihatita...", data = '{tech = TUNING.PROTOTYPER_TREES.PRESTIHATITATOR, hint = string.sub(STRINGS.UI.CRAFTING.NEEDPRESTIHATITATOR, 1, -14).." this!"}', hover = "Requires: Prestihatitator!"},
            {description = "Shadow Manip...", data = '{tech = TUNING.PROTOTYPER_TREES.SHADOWMANIPULATOR, hint = string.sub(STRINGS.UI.CRAFTING.NEEDSHADOWMANIPULATOR, 1, -14).." this!"}', hover = "Requires: Shadow Manipulator!"},
            {description = "Broken Ancie...", data = '{tech = TUNING.PROTOTYPER_TREES.ANCIENTALTAR_LOW}', hover = "Requires: Broken Ancient Pseudoscience Station!"},
            {description = "Ancient Pseu...", data = '{tech = TUNING.PROTOTYPER_TREES.ANCIENTALTAR_HIGH}', hover = "Requires: Ancient Pseudoscience Station!"},
        },
        default = '{tech = TUNING.PROTOTYPER_TREES.ANCIENTALTAR_HIGH}',
    },
    {
        name = "hutch_max",
        label = "Max Hutches?",
        hover = "Max Hutches Per Player?",
        options =
        {
            {description = "1", data = 1},
            {description = "2", data = 2},
            {description = "3", data = 3},
            {description = "4", data = 4},
            {description = "5", data = 5},
            {description = "6", data = 6},
            {description = "7", data = 7},
            {description = "8", data = 8},
            {description = "9", data = 9},
            {description = "10", data = 10},
        },
        default = 1,
    },
    {
        name = "hutch_locations",
        label = "Allowed Shard Types",
        hover = "What Shards is hutch allowed to go to(forest, cave, ect)?",
        options =
        {
            --for dedicated servers this is a list of tags to check to see if that shard can have a hutch
            --due to tecnical limitations your never allowed to prevent hutch from being allowed in his default game world(in this case the caves)
            --set data = 'nil' to remove all shard restrictions
            --encapsulate all data as a string because of stupid tecnical reasons,
            {description = "Caves", data = '{}'},
            {description = "Caves + Forests", data = '{"forest"}', hover = "Caves, And Forests"},
            {description = "Caves + Islands", data = '{"island"}', hover = "Caves, And Islands"},
            {description = "Caves + Fore...", data = '{"forest", "island"}', hover = "Caves, Forests, And Islands"},
        },
        default = '{}',
    },
    Title("PACKIM", "Configuration options relating to Packim."),
    {
        name = "packim_craft",
        label = "Crafting Difficulty",
        hover = "The Difficulty of Crafting it.",
        options =
        {
            {description = "Easy", data = '{Ingredient("fish", 1), Ingredient("nightmarefuel", 4)}', hover = "1 Fish, 4 Nightmare Fuel."},
            {description = "Medium", data = '{Ingredient("fish", 1), Ingredient("nightmarefuel", 8), Ingredient("Obsidian", 4, "images/ia_inventoryimages.xml")}', hover = "1 Fish, 8 Nightmare Fuel, 4 Obsidian."},
            {description = "Hard", data = '{Ingredient("fish", 1), Ingredient("nightmarefuel", 12), Ingredient("Obsidian", 6, "images/ia_inventoryimages.xml")}', hover = "1 Fish, 12 Nightmare Fuel, 6 Obsidian."},
            {description = "Hardcore", data = '{Ingredient("fish", 1), Ingredient("nightmarefuel", 8), Ingredient("Obsidian", 4, "images/ia_inventoryimages.xml"), Ingredient("shadowheart", 1)}', hover = "1 Fish, 8 Nightmare Fuel, 4 Obsidian, 1 Shadow Atrium."},
        },
        default = '{Ingredient("fish", 1), Ingredient("nightmarefuel", 8), Ingredient("Obsidian", 4, "images/ia_inventoryimages.xml")}',
    },
    {
        name = "packim_science",
        label = "Machine To Craft",
        hover = "What Tech Level do you need to craft it?",
        options =
        {
            {description = "None", data = 'nil', hover = "Requires: Nothing!"},
            {description = "Science Machine", data = '{tech = TUNING.PROTOTYPER_TREES.SCIENCEMACHINE, hint = string.sub(STRINGS.UI.CRAFTING.NEEDSCIENCEMACHINE, 1, -14).." this!"}', hover = "Requires: Science Machine!"},
            {description = "Alchemy Engine", data = '{tech = TUNING.PROTOTYPER_TREES.ALCHEMYMACHINE, hint = string.sub(STRINGS.UI.CRAFTING.NEEDALCHEMYENGINE, 1, -14).." this!"}', hover = "Requires: Alchemy Engine!"},
            {description = "Sea Lab", data = '{tech = TUNING.PROTOTYPER_TREES.SEALAB, hint = string.sub(STRINGS.UI.CRAFTING.NEEDSSEALAB, 1, -14).." this!"}', hover = "Requires: Sea Lab!"},
            {description = "Prestihatita...", data = '{tech = TUNING.PROTOTYPER_TREES.PRESTIHATITATOR, hint = string.sub(STRINGS.UI.CRAFTING.NEEDPRESTIHATITATOR, 1, -14).." this!"}', hover = "Requires: Prestihatitator!"},
            {description = "Shadow Manip...", data = '{tech = TUNING.PROTOTYPER_TREES.SHADOWMANIPULATOR, hint = string.sub(STRINGS.UI.CRAFTING.NEEDSHADOWMANIPULATOR, 1, -14).." this!"}', hover = "Requires: Shadow Manipulator!"},
            {description = "Obsidian Wor...", data = '{tech = TUNING.PROTOTYPER_TREES.OBSIDIAN_BENCH}', hover = "Requires: Obsidian Workbench!"},
        },
        default = '{tech = TUNING.PROTOTYPER_TREES.SEALAB, hint = string.sub(STRINGS.UI.CRAFTING.NEEDSSEALAB, 1, -14).."!"}',
    },
    {
        name = "packim_max",
        label = "Max Packim Baggims?",
        hover = "Max Packim Baggims Per Player?",
        options =
        {
            {description = "1", data = 1},
            {description = "2", data = 2},
            {description = "3", data = 3},
            {description = "4", data = 4},
            {description = "5", data = 5},
            {description = "6", data = 6},
            {description = "7", data = 7},
            {description = "8", data = 8},
            {description = "9", data = 9},
            {description = "10", data = 10},
        },
        default = 1,
    },
    {
        name = "packim_locations",
        label = "Allowed Shard Types",
        hover = "What Shards is packim baggims allowed to go to(forest, cave, ect)?",
        options =
        {
            --for dedicated servers this is a list of tags to check to see if that shard can have a hutch
            --due to tecnical limitations your never allowed to prevent packim from being allowed in his default game world(in this case the islands)
            --set data = 'nil' to remove all shard restrictions
            --encapsulate all data as a string because of stupid tecnical reasons,
            {description = "Islands", data = '{}'},
            {description = "Islands + Fo...", data = '{"forest"}', hover = "Islands, And Forests"},
            {description = "Islands + Caves", data = '{"cave"}', hover = "Islands, And Caves"},
            {description = "Islands + Fo...", data = '{"forest", "cave"}', hover = "Islands, Forests, And Caves"},
        },
        default = '{}',
    }
}