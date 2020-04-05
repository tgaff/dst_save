name = " Storeroom"
version = "2.5a"
-- thanks Some1
desc_variant = {en = "Your personal space.\n\nMod version: "..version,
		ru = "Твоё личное пространство.\nВерсия мода: "..version}
description = desc_variant[language] or desc_variant["en"]

author = "MrM"
forumthread = ""
api_version = 10

all_clients_require_mod = true
client_only_mod = false
dst_compatible = true
--priority = -0.0623749604

server_filter_tags = {"storeroom"}

icon_atlas = "storeroom.xml"
icon = "storeroom.tex"
----------------------

local russian = language == "ru"

configuration_options =
{
	{
		name = "Craft",
		label = russian and "Создание" or "Craft",
		options =
	{
		{description = russian and "Лёгкое" or "Easy", data = "Easy"},
		{description = russian and "Нормальное" or "Normal", data = "Normal"},
		{description = russian and "Сложное" or "Hard", data = "Hard"},
	},
		default = "Normal",
	},

	{
		name = "Slots",
		label = russian and "Слоты" or "Slots",
		options =
	{
		{description = "20", data = 20},
		{description = "40", data = 40},
		{description = "60", data = 60},
		{description = "80", data = 80},
	},
		default = 80,
	},

	{
		name = "Position",
		label = russian and "Позиция" or "Position",
		options =
	{
		{description = russian and "Слева" or "Left", data = "Left"},
		{description = russian and "По центру" or "Center", data = "Center"},
		{description = russian and "Справа" or "Right", data = "Right"},
	},
		default = "Center",
	},

	{
		name = "FoodSpoilage",
		label = russian and "Порча еды" or "Food Spoilage",
		options =
	{
		{description = russian and "Обычно" or "Default", data = 1, hover = " "},
		{description = russian and "Немного медленней" or "Little Slower", data = 0.85, hover = russian and "Немного медленней" or "Little Slower"},
		{description = russian and "Как зимой" or "As Winter", data = 0.75, hover = " "},
		{description = russian and "Как в холодильнике" or "Like Ice Box", data = 0.5, hover = russian and "Как в холодильнике" or "Like Ice Box"},
		{description = russian and "Лучше холодильника" or "Better than Ice Box", data = 0.25, hover = russian and "Лучше холодильника" or "Better than Ice Box"},
		{description = russian and "Не портится" or "No Spoilage", data = 0, hover = " "},
		{description = russian and "ВТФ?!??" or "WTF?!??", data = 999, hover = russian and "Сохраняйте спокойствие и смотрите на гниение" or "Keep calm and look at rotting"},
	},
		default = 1,
	},

	{
		name = "Destroyable",
		label = russian and "Разрушаемость" or "Destroyable",
		options =
	{
		{description = russian and "Всеми" or "All", data = "DestroyByAll"},
		{description = russian and "Только игроком" or "Only Player", data = "DestroyByPlayer"},
		{description = russian and "Выключена" or "Disabled ", data = "DestroyOff"},
	},
		default = "DestroyByAll",
	},

	{
		name = "Language",
		label = russian and "Язык" or "Language",
		options =
	{
		{description = russian and "Русский" or "English", data = "En"},
		{description = "Finnish", data = "Fn"},
		{description = "Francais", data = "Fr"},
		{description = "Croatian", data = "Cr"},
		{description = "German", data = "Gr"},
		{description = "Chinese", data = "TCh"},
		{description = "Polish", data = "Pl"},
		{description = "Portuguese", data = "Pr"},
		{description = "Spanish", data = "Sp"},
		{description = "Swedish", data = "Sw"},
		{description = "Turkish", data = "Tr"},
	},
		default = "En",
	},
}
