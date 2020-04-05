	PrefabFiles = 
{
	"rabbit_cage",
    "rabbit_bomb",
}  

	Assets = 
{
	Asset("ATLAS", "images/inventoryimages/rabbit_cage.xml"),
}

    AddMinimapAtlas("minimap/rabbit_cage.xml") 
 
    STRINGS = GLOBAL.STRINGS
    RECIPETABS = GLOBAL.RECIPETABS
    Recipe = GLOBAL.Recipe
    Ingredient = GLOBAL.Ingredient
    TECH = GLOBAL.TECH

    STRINGS.NAMES.RABBIT_CAGE = "Rabbit Cage"
    STRINGS.RECIPE_DESC.RABBIT_CAGE = "Farm some Rabbits!"
    STRINGS.CHARACTERS.GENERIC.DESCRIBE.RABBIT_CAGE = "Cute and tasty!"

    STRINGS.NAMES.RABBIT_BOMB = "Bunny Bomb"
    STRINGS.CHARACTERS.GENERIC.DESCRIBE.RABBIT_BOMB = "A cluster of exploding bunny poop!"

	TUNING.RABBIT_AMOUNT = 3
	TUNING.RABBIT_TIME = 480

	local rabbit_cage = Recipe("rabbit_cage",
{
	Ingredient("boards", 6),
	Ingredient("carrot", 1),
	Ingredient("rabbit", 2),
},
	RECIPETABS.FARM, TECH.SCIENCE_TWO,"rabbit_cage_placer", 1)
	rabbit_cage.atlas = "images/inventoryimages/rabbit_cage.xml"
    rabbit_cage.sortkey = -1

local function makeit(inst)
    inst:AddComponent("tradable")
end 
AddPrefabPostInit("gunpowder", makeit)

