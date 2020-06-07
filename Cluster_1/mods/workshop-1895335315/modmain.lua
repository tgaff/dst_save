PrefabFiles = {
	"storeroom",
}

Assets =
{
	Asset("ATLAS", "minimap/storeroom.xml" ),
	Asset("ATLAS", "images/inventoryimages/storeroom.xml"),
}

AddMinimapAtlas("minimap/storeroom.xml")

_G = GLOBAL
STRINGS = _G.STRINGS
RECIPETABS = _G.RECIPETABS
Recipe = _G.Recipe
Ingredient = _G.Ingredient
TECH = _G.TECH
TUNING = _G.TUNING

local STOREROOM = {}
STOREROOM.DEBUG = true
STOREROOM.CRAFT = GetModConfigData("Craft")
STOREROOM.SLOTS = GetModConfigData("Slots")
STOREROOM.LANG = GetModConfigData("Language")

TUNING.STOREROOM_DESTROY = GetModConfigData("Destroyable")

local function updaterecipe(slots)
	if STOREROOM.CRAFT == "Easy" then

		cutstone_value = math.floor(slots / 7)
		boards_value = math.floor(slots / 7)
		marble_value = math.floor(slots / 20)

	elseif STOREROOM.CRAFT == "Hard" then

		cutstone_value = math.floor(slots / 2.6)
		boards_value = math.floor(slots / 2.6)
		marble_value = math.floor(slots / 10)

	else

		cutstone_value = math.floor(slots / 4)
		boards_value = math.floor(slots / 4)
		marble_value = math.floor(slots / 20)
	end
end
updaterecipe(STOREROOM.SLOTS)

---------------------------------------------------
---------------------- RECIPE ---------------------
---------------------------------------------------
storeroom = AddRecipe("storeroom",{ Ingredient("cutstone", cutstone_value), Ingredient("marble", marble_value), Ingredient("boards", boards_value) }, RECIPETABS.TOWN, TECH.SCIENCE_TWO, "storeroom_placer" )
storeroom.atlas = "images/inventoryimages/storeroom.xml"

---------------------------------------------------
---------------------- WIDGET ---------------------
---------------------------------------------------

--------------------- function --------------------
local function widgetcreation(widgetanimbank, widgetpos, slot_x, slot_y, posslot_x, posslot_y)
	local params = {}
	params.storeroom =
	{
		widget =
		{
			slotpos = {},
			animbank = widgetanimbank,
			animbuild = widgetanimbank,
			pos = widgetpos,
			side_align_tip = 160,
		},
	type = "chest",
	}

	for y = slot_y, 0, -1 do
		for x = 0, slot_x do
			table.insert(params.storeroom.widget.slotpos, _G.Vector3(80*x-346*2+posslot_x, 80*y-100*2+posslot_y,0))
		end
	end

	local containers = _G.require "containers"
	containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, params.storeroom.widget.slotpos ~= nil and #params.storeroom.widget.slotpos or 0)

	local old_widgetsetup = containers.widgetsetup
	function containers.widgetsetup(container, prefab, ...)
		local pref = prefab or container.inst.prefab
		if pref == "storeroom" then
			local t = params[pref]
			if t ~= nil then
				for k, v in pairs(t) do
					container[k] = v
				end
			container:SetNumSlots(container.widget.slotpos ~= nil and #container.widget.slotpos or 0)
			end
		else
			return old_widgetsetup(container, prefab, ...)
		end
	end
end

--------------------- position --------------------
if GetModConfigData("Position") == ("Left") then
	widgetpos = _G.Vector3(-110,160,0)
elseif GetModConfigData("Position") == ("Center") then
	widgetpos = _G.Vector3(360-(STOREROOM.SLOTS*4.5),160,0)
elseif GetModConfigData("Position") == ("Right") then
	widgetpos = _G.Vector3(820-(STOREROOM.SLOTS*9.3),160,0)
end

---------------- formation function ---------------
if STOREROOM.SLOTS == 20 then
	widgetanimbank = "ui_chest_4x5"
	slot_x = 4
	slot_y = 3
	posslot_x = 90
	posslot_y = 130
elseif STOREROOM.SLOTS == 40 then
	widgetanimbank = "ui_chest_5x8"
	slot_x = 7
	slot_y = 4
	posslot_x = 109
	posslot_y = 42
elseif STOREROOM.SLOTS == 60 then
	widgetanimbank = "ui_chest_5x12"
	slot_x = 11
	slot_y = 4
	posslot_x = 98
	posslot_y = 42
else
	widgetanimbank = "ui_chest_5x16"
	slot_x = 15
	slot_y = 4
	posslot_x = 91
	posslot_y = 42
end
------------------- call function -----------------
widgetcreation(widgetanimbank, widgetpos, slot_x, slot_y, posslot_x, posslot_y)

---------------------------------------------------
-------------------- TRANSLATE --------------------
---------------------------------------------------

--------------------- Russian ---------------------
local RegisterRussianName = GLOBAL.rawget(GLOBAL,"RegisterRussianName")
if RegisterRussianName and STOREROOM.LANG == "En" then
	RegisterRussianName("STOREROOM","Кладовая","she","Кладовой")
	STRINGS.RECIPE_DESC.STOREROOM = "Нужно больше места!"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.STOREROOM = "Мне очень нравится это большое хранилище!"

--------------------- Finnish ---------------------
-- by NoTC
elseif STOREROOM.LANG == "Fn" then
	STRINGS.NAMES.STOREROOM = "Varasto"
	STRINGS.RECIPE_DESC.STOREROOM = "Tarvitsee enemmän tilaa!"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.STOREROOM = "Tykkään tää on mahtava varasto!"

--------------------- French ----------------------
-- by John2022
elseif STOREROOM.LANG == "Fr" then
	STRINGS.NAMES.STOREROOM = "Debarras"
	STRINGS.RECIPE_DESC.STOREROOM = "Besoin de plus d'espace!"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.STOREROOM = "J'apprecie beaucoup le gain de place!"

--------------------- Croatian --------------------
-- by Doge
elseif STOREROOM.LANG == "Cr" then
	STRINGS.NAMES.STOREROOM = "Skladište"
	STRINGS.RECIPE_DESC.STOREROOM = "Treba više mjesta!"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.STOREROOM = "Sviđa mi se ovo skladište!"

--------------------- German ----------------------
-- by Ralkari
elseif STOREROOM.LANG == "Gr" then
	STRINGS.NAMES.STOREROOM = "Vorratskammer"
	STRINGS.RECIPE_DESC.STOREROOM = "Brauche mehr Platz!"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.STOREROOM = "Ich mag die Vorratskammer!"

--------------------- Traditional Chinese ---------
-- by Oh Deer!
elseif STOREROOM.LANG == "TCh" then
	STRINGS.NAMES.STOREROOM = "儲藏室"
	STRINGS.RECIPE_DESC.STOREROOM = "需要更多空間!"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.STOREROOM = "這個儲藏室很好，我很喜歡！"

--------------------- Polish ----------------------
-- by Hussarya
elseif STOREROOM.LANG == "Pl" then
	STRINGS.NAMES.STOREROOM = "Składzik"
	STRINGS.RECIPE_DESC.STOREROOM = "Więcej miejsca!"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.STOREROOM = "Naprawdę uwielbiam ten ogromny składzik!"

--------------------- Portuguese ------------------
-- by mauricioportella
elseif STOREROOM.LANG == "Pr" then
	STRINGS.NAMES.STOREROOM = "Porão"
	STRINGS.RECIPE_DESC.STOREROOM = "Preciso de mais espaço!"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.STOREROOM = "¡Me encanta un montón, es una bodega estupenda!"

--------------------- Spanish ---------------------
-- by MartiniAndres
elseif STOREROOM.LANG == "Sp" then
	STRINGS.NAMES.STOREROOM = "Bodega"
	STRINGS.RECIPE_DESC.STOREROOM = "¡Se necesita más espacio!"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.STOREROOM = "¡Me encanta este gran almacén!"

--------------------- Swedish ---------------------
-- by dLFN
elseif STOREROOM.LANG == "Sw" then
	STRINGS.NAMES.STOREROOM = "Förråd"
	STRINGS.RECIPE_DESC.STOREROOM = "Behöver mer utrymme!"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.STOREROOM = "Jag gillar verkligen detta bra föråd!"

--------------------- Turkish ---------------------
-- by DestORoyal
elseif STOREROOM.LANG == "Tr" then
	STRINGS.NAMES.STOREROOM = "Depo"
	STRINGS.RECIPE_DESC.STOREROOM = "Daha fazla alan gerek!"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.STOREROOM = "Bu depoyu gercekten begendim!"

--------------------- English ---------------------
else
	STRINGS.NAMES.STOREROOM = "Storeroom"
	STRINGS.RECIPE_DESC.STOREROOM = "Need more space!"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.STOREROOM = "I really like this is a great storeroom!"
end

---------------------------------------------------
---------------------- DEBUG ----------------------
---------------------------------------------------

if STOREROOM.DEBUG then
	print("--- STOREROOM DEBUG ---")
	print("slots = " .. STOREROOM.SLOTS)
	print("recipe: cutstone = " .. cutstone_value .. " marble = " .. marble_value .. " boards = " ..  boards_value)
	print("widget: widgetanimbank = " .. widgetanimbank .. " widgetpos = ", widgetpos, " slot_x = " .. slot_x .. " slot_y = " .. slot_y .. " posslot_x = " .. posslot_x .. " posslot_y = " .. posslot_y)
end