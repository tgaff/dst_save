name = "Campfire Respawn"
description =
	"Allows you to respawn, when you haunt campfires."
.. "\nWorks the same way as the Jury-Rigged Portal."
.. "\n\nAffects (Enabled by default):"
.. "\n Campfire"
.. "\n Firepit"
.. "\n Endothermic Fire"
.. "\n Endothermic Fire Pit"
.. "\n\nOnly works in Endless and Survival mode."
.. "\n\n1.6 New Features : "
.. "\nMod is nolonger overriding the vanilla files, this should make it more compatible with other mods and more future proof with updates."
.. "\nRespawn when haunting (Disabled by default):"
.. "\n Telltale Heart that lies on the ground, consumes the heart."
.. "\n Skeletons and Player Skeletons."
.. "\nConfig options to disable/enable the various things."
.. "\nExposed some of the TUNING health penalties and spawn health in the config screen(i don't fully understand them myself)."
.. "\nAdded a \"Use Tags\" option(Disabled by Default), this will override all Campfire settings and will add the Resurrection mechanic to anything that has the \"campfire\" tag, this should make the mod work with other mods aslong as their Prefabs has the tag."
.. "\n\"Use Tags\" is Experimental and you should only use it if you need more Campfires than the 4 above to be affected. Backup your world before you try this option!"
.. "\n\nVersion 1.6"
.. "\nLicense : Public Domain"

author = "VampireMonkey"
version = "v1.6"

dont_starve_compatible = false
dst_compatible = true
reign_of_giants_compatible = true

client_only_mod = false
all_clients_require_mod = true

forumthread = ""

api_version = 10

server_filter_tags = {"utility"}

icon_atlas = "modicon.xml"
icon = "modicon.tex"

local Unchanged = "Unchanged";
local Enabled 	= "Enabled";

local Options =
{
	{description = "Disabled", data = Unchanged},
	{description = "Enabled",   data = Enabled}
}

local Generic_Haunt = "Respawn when you Haunt a "
local Generic_Health_Penalty = "Health penalty when respawning by "

-- Doesn't go up to 100%, can't have the player spawning with no health
local Options_0_99 =
{
	{description = "Unchanged",   data = Unchanged},
	{description = "0%", 		  data = 0.0},
	{description = "5%", 		  data = 0.05},
	{description = "10%", 		  data = 0.10},
	{description = "15%", 		  data = 0.15},
	{description = "20%", 		  data = 0.20},
	{description = "25%", 		  data = 0.25},
	{description = "30%", 		  data = 0.30},
	{description = "35%", 		  data = 0.35},
	{description = "40%", 		  data = 0.40},
	{description = "45%", 		  data = 0.45},
	{description = "50%", 		  data = 0.50},
	{description = "55%", 		  data = 0.55},
	{description = "60%", 		  data = 0.60},
	{description = "65%", 		  data = 0.65},
	{description = "70%", 		  data = 0.70},
	{description = "75%", 		  data = 0.75},
	{description = "80%", 		  data = 0.80},
	{description = "85%", 		  data = 0.85},
	{description = "90%", 		  data = 0.90},
	{description = "95%", 		  data = 0.95},
	{description = "99%", 		  data = 0.99}
};

local Options_1_99_Integers =
{
	{description = "Unchanged",   data = Unchanged},
	{description = "5", 		  data = 5},
	{description = "10", 		  data = 10},
	{description = "15", 		  data = 15},
	{description = "20", 		  data = 20},
	{description = "25", 		  data = 25},
	{description = "30", 		  data = 30},
	{description = "35", 		  data = 35},
	{description = "40", 		  data = 40},
	{description = "45", 		  data = 45},
	{description = "50", 		  data = 50},
	{description = "55", 		  data = 55},
	{description = "60", 		  data = 60},
	{description = "65", 		  data = 65},
	{description = "70", 		  data = 70},
	{description = "75", 		  data = 75},
	{description = "80", 		  data = 80},
	{description = "85", 		  data = 85},
	{description = "90", 		  data = 90},
	{description = "95", 		  data = 95},
	{description = "99", 		  data = 99}
};

local Options_1_500 =
{
	{description = "Unchanged",   data = Unchanged},
	{description = "500", 		  data = 500},
	{description = "300", 		  data = 300},
	{description = "200", 		  data = 200},
	{description = "190", 		  data = 190},
	{description = "180", 		  data = 180},
	{description = "170", 		  data = 170},
	{description = "160", 		  data = 160},
	{description = "150", 		  data = 150},
	{description = "140", 		  data = 140},
	{description = "130", 		  data = 130},
	{description = "120", 		  data = 120},
	{description = "110", 		  data = 110},
	{description = "100", 		  data = 100},
	{description = "90", 		  data = 90},
	{description = "80", 		  data = 80},
	{description = "70", 		  data = 70},
	{description = "60", 		  data = 60},
	{description = "40", 		  data = 40},
	{description = "30", 		  data = 30},
	{description = "20", 		  data = 20},
	{description = "10", 		  data = 10},
	{description = "5", 		  data = 5},
	{description = "1", 		  data = 1}
};

configuration_options =
{
    {
		name = "campfire",
		label = "Campfire",
		hover = Generic_Haunt .. "Campfire.",
		options = Options,
		default = Enabled
    },
    {
		name = "firepit",
		label = "Firepit",
		hover = Generic_Haunt .. "Firepit.",
		options = Options,
		default = Enabled
    },
    {
		name = "coldfire",
		label = "Endothermic Fire",
		hover = Generic_Haunt .. "Endothermic Fire.",
		options = Options,
		default = Enabled
    },
    {
		name = "coldfirepit",
		label = "Endothermic Fire Pit",
		hover = Generic_Haunt .. "Endothermic Fire Pit.",
		options = Options,
		default = Enabled
    },
    {
		name = "skeleton",
		label = "Skeleton",
		hover = Generic_Haunt .. "Skeleton or Player Skeleton.",
		options = Options,
		default = Unchanged
    },
    {
		name = "reviver",
		label = "Telltale Heart",
		hover = Generic_Haunt .. "Telltale Heart that lies on the ground.\nConsumes the Heart.",
		options = Options,
		default = Unchanged
    },
    {
		name = "usetags",
		label = "Use Tags",
		hover = "Experimental! Blocks all other Campfire settings, uses the \"campfire\" tag to add the resurrection mechanic to Prefabs.",
		options = Options,
		default = Unchanged
	},
	{
		name = "Health_Penalty_Generic",
		label = "Health Penalty - Generic",
		hover = "Generic Health Penalty.\nDefault : 25%",
		options = Options_0_99,
		default = Unchanged
	},
    {
		name = "Health_Penalty_Portal",
		label = "Health Penalty - Portal",
		hover = Generic_Health_Penalty .. "the Jury-Rigged Portal.\nDefault : 25%",
		options = Options_0_99,
		default = Unchanged
	},
    {
		name = "Health_Penalty_Maximum",
		label = "Health Penalty - Generic Max",
		hover = "Generic Max Health Penalty.\nDefault : 75%",
		options = Options_0_99,
		default = Unchanged
	},
    {
		name = "Health_PenaHealth_Penalty_Meat_Effigylty_Portal",
		label = "Health Penalty - Meat Effigy",
		hover = Generic_Health_Penalty .. "the Meat Effigy.\nMin amount of Health you can spawn with. Default : 40.",
		options = Options_1_99_Integers,
		default = Unchanged
	},
    {
		name = "Health_Respawn_Amount",
		label = "Health Respawn Amount",
		hover = "How much Health does the player respawn with?\nHealth can never be above the characters Max Health. Default : 50.",
		options = Options_1_500,
		default = Unchanged
	}
}
