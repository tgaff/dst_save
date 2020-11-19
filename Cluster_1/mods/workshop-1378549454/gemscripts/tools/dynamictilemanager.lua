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

--this only runs in the backend
if GEMENV.IsTheFrontEnd then return end

-- Initialize the world tiles.
require("map/terrain")
local tiles = require("worldtiledefs")
local assets = tiles.assets
local BinaryString = gemrun("binarystring")

GEMCORETILEDATA = {}
local TILES_TO_MOVE = {}
local GEMCORE_TILES = {}
local TERRAFORM_IMMUNE = {}
local WORKSHOP_NONWORKSHOP_LINKS = {}
--Zarklord: with the exception of "FAKE_GROUND" I can't seem to find any usage for the other "non-walkable" tiles
--so we are gonna move them to a reserved space from 201-254(Remember 200 is FAKE_GROUND, 255 is INVALID)
--and then set TILES.UNDERGROUND = 199, this will give us (198 - vanilla game tiles) worth of tile space,
--this preserves all used vanilla game tiles meaning we dont break saves loaded with this.
--UPDATE 3/22/2019: Scott has informed of the following:
--The NOISE tiles are used in the game engine, and aren't moveable.
--The UNDERGROUND tile ID is used heavily in the engine and cant be changed, therefore we have 127-vanilla game tiles worth of space.
--[[
local FAKETILESSTART = 254

for tile_name, idx in pairs(GROUND) do
    local nidx = nil and string.find(tile_name, "NOISE")
    local widx = string.find(tile_name, "WALL")
    if (nidx and nidx >= 1) -- starts with NOISE
        or (widx and widx >= 1) then -- starts with WALL
        TILES_TO_MOVE[tile_name] = {
            old_idx = idx
        }
    end
end

local function MoveVanillaTileData(tiledata, old_id)
    GROUND[tiledata.name] = tiledata.id

    GROUND_NAMES[tiledata.id] = GROUND_NAMES[old_id]
    GROUND_NAMES[old_id] = nil

    for i, v in ipairs(tiles.ground) do
        if v[1] == old_id then
            v[1] = tiledata.id
            break
        end
    end
    for i, v in ipairs(tiles.wall) do
        if v[1] == old_id then
            v[1] = tiledata.id
            break
        end
    end
    for k, v in pairs(tiles.turf) do
        if k == old_id then
            tiles.turf[tiledata.id] = v
            tiles.turf[k] = nil
            break
        end
    end
    for i, v in ipairs(tiles.underground) do
        if v[1] == old_id then
            v[1] = tiledata.id
            break
        end
    end

    GROUND_FLOORING[tiledata.id] = GROUND_FLOORING[old_id]
    GROUND_FLOORING[old_id] = nil

    TERRAFORM_IMMUNE[tiledata.id] = TERRAFORM_IMMUNE[old_id]
    TERRAFORM_IMMUNE[old_id] = nil

    for k, v in pairs(terrain.filter) do
        if type(v) == "table" then
            for i, tileid in ipairs(v) do
                if tileid == old_id then
                    v[i] = tiledata.id
                end
            end
        end
    end

    for layoutname, data in pairs(require("map/layouts").Layouts) do
        if data.ground_types then
            for i, v in ipairs(data.ground_types) do
                if v == old_id then
                    data.ground_types[i] = tiledata.id
                end
            end
        end
    end

    for mod, roomset in pairs(modrooms) do
        for name, room in pairs(roomset) do
            if room.value == old_id then
                room.value = tiledata.id
            end
        end
    end

    for name, room in pairs(rooms) do
        if room.value == old_id then
            room.value = tiledata.id
        end
    end

    for mod, taskset in pairs(modtasks) do
        for _, task in ipairs(taskset) do
            if task.room_bg == old_id then
                task.room_bg = tiledata.id
            end
        end
    end

    for _, task in ipairs(tasks) do
        if task.room_bg == old_id then
            task.room_bg = tiledata.id
        end
    end
    print("Set tile "..tiledata.name.." from id: "..old_id.." to id: "..tiledata.id)
end

for k, v in pairs(TILES_TO_MOVE) do
    MoveVanillaTileData({name = k, id = FAKETILESSTART}, GROUND[k])
    FAKETILESSTART = FAKETILESSTART - 1
end
MoveVanillaTileData({name = "UNDERGROUND", id = 199}, GROUND.UNDERGROUND)
--]]
local INVERTEDGROUND = table.invert(GROUND)

local modrooms = UpvalueHacker.GetUpvalue(AddModRoom, "modrooms")
local rooms = UpvalueHacker.GetUpvalue(AddRoom, "rooms")
local modtasks = UpvalueHacker.GetUpvalue(AddModTask, "modtaskdefinitions")
local tasks = UpvalueHacker.GetUpvalue(AddTask, "taskdefinitions")

if GROUND.OCEAN_END then
    INVERTEDGROUND[GROUND.OCEAN_END] = nil
end
if GROUND.OCEAN_COASTAL then
    INVERTEDGROUND[GROUND.OCEAN_COASTAL] = "OCEAN_COASTAL"
end
if GROUND.UNDERGROUND then
    INVERTEDGROUND[GROUND.UNDERGROUND] = nil
end

local function GetNextFreeID(water, underground)
    if water then
        for i = 201, 247 do
            if INVERTEDGROUND[i] == nil then return i end
        end
    elseif underground then
        for i = 128, 200 do
            if INVERTEDGROUND[i] == nil then return i end
        end
        for i = 248, 255 do
            if INVERTEDGROUND[i] == nil then return i end
        end
    else
        for i = 1, 127 do
            if INVERTEDGROUND[i] == nil then return i end
        end
    end
    assert(false, "ERROR! No more tile IDs are avaliable, remove some mods that add tiles to fix this.")
end

local function MoveTileData(modtile, old_id)
    if modtile.isprocessed then
        GROUND[modtile.name] = modtile.id

        GROUND_NAMES[modtile.id] = GROUND_NAMES[old_id]
        GROUND_NAMES[old_id] = nil

        for i, v in ipairs(tiles.ground) do
            if v[1] == old_id then
                v[1] = modtile.id
                break
            end
        end

        GROUND_FLOORING[modtile.id] = GROUND_FLOORING[old_id]
        GROUND_FLOORING[old_id] = nil

        if modtile.ground.turf_name then
            tiles.turf[modtile.id] = tiles.turf[old_id]
            tiles.turf[old_id] = nil
        end

        TERRAFORM_IMMUNE[modtile.id] = TERRAFORM_IMMUNE[old_id]
        TERRAFORM_IMMUNE[old_id] = nil

        for k, v in pairs(terrain.filter) do
            if type(v) == "table" then
                for i, tileid in ipairs(v) do
                    if tileid == old_id then
                        v[i] = modtile.id
                    end
                end
            end
        end

        for layoutname, data in pairs(require("map/layouts").Layouts) do
            if data.ground_types then
                for i, v in ipairs(data.ground_types) do
                    if v == old_id then
                        data.ground_types[i] = modtile.id
                    end
                end
            end
        end

        for mod, roomset in pairs(modrooms) do
            for name, room in pairs(roomset) do
                if room.value == old_id then
                    room.value = modtile.id
                end
            end
        end

        for name, room in pairs(rooms) do
            if room.value == old_id then
                room.value = modtile.id
            end
        end

        for mod, taskset in pairs(modtasks) do
            for _, task in ipairs(taskset) do
                if task.room_bg == old_id then
                    task.room_bg = modtile.id
                end
            end
        end

        for _, task in ipairs(tasks) do
            if task.room_bg == old_id then
                task.room_bg = modtile.id
            end
        end

        --if your mod does stuff a little bit more complicated than the generic's use this callback system.
        if modtile.tileidchangedcb then
            modtile.tileidchangedcb(modtile.id, old_id)
        end
    end
end

setmetatable(GROUND, {__newindex = function(t, k, v)
    if INVERTEDGROUND[v] ~= nil then
        local didfindgemtile = false

        for modname, modtiles in pairs(GEMCORE_TILES) do
            for i, modtile in ipairs(modtiles) do

                if modtile.id == v then
                    didfindgemtile = true

                    local oldId = modtile.id
                    modtile.id = GetNextFreeID(modtile.water, modtile.underground)
                    --migrate all the old ref's to that modtile id.
                    MoveTileData(modtile, oldId)
                    print("Tile: "..modtile.name.." Moved from ID: "..oldId.." to ID: "..modtile.id)

                    print("Tile: "..k.." Set to ID: "..v)
                    rawset(t, k, v)
                end
            end
        end
        assert(didfindgemtile, "\nERROR! ERROR! ERROR!\n TWO MODS ARE TRYING TO ADD TILES UNDER THE SAME ID\nPLEASE FIND AND REPORT THIS TO THE MOD AUTHORS SO THEY CAN FIX THIS")
    else
        print("Tile: "..k.." Set to ID: "..v)
        rawset(t, k, v)
    end
    INVERTEDGROUND = table.invert(t)
end})

--this is really silly, but this is for compatibility with nsimplex's tile_adder.lua(which you dont need anymore)
local _error = error
function error(message, level)
    if string.find(message, "The numerical id [%d]- is already used by GROUND%..-!") then
        return
    end
    return _error(message, level)
end

local function GroundImage(name)
    if softresolvefilepath(name) then
        return resolvefilepath(name)
    end
    return resolvefilepath("levels/tiles/"..name..".tex")
end

local function GroundAtlas(name)
    if softresolvefilepath(name) then
        return resolvefilepath(name)
    end
    return resolvefilepath("levels/tiles/"..name..".xml")
end

local function GroundNoise(name)
    if softresolvefilepath(name) then
        return resolvefilepath(name)
    end
    return resolvefilepath("levels/textures/"..name..".tex")
end

local function Tile(texture_name, noise_texture, run_sound, walk_sound, snow_sound, mud_sound, flashpoint_modifier, turf_name, canbedug, bank_build)
    local tile = {}

    tile.name = texture_name
    tile.atlas = GroundAtlas(texture_name)
    tile.noise_texture = GroundNoise(noise_texture)
    tile.runsound = "dontstarve/movement/"..(run_sound and run_sound or "run_dirt")
    tile.walksound = "dontstarve/movement/"..(walk_sound and walk_sound or "walk_dirt")
    tile.snowsound = "dontstarve/movement/"..(snow_sound and snow_sound or "run_snow")
    tile.mudsound = "dontstarve/movement/"..(mud_sound and mud_sound or "run_mud")
    tile.flashpoint_modifier = flashpoint_modifier and flashpoint_modifier or 0
    tile.turf_name = turf_name
    tile.bank_build = bank_build or "turf"
    tile.canbedug = canbedug
    if canbedug == nil then
        tile.canbedug = (turf_name ~= nil)
    end
    return tile
end

if not ModManager.worldgen then
    GEMENV.AddPrefabPostInit("minimap", function(inst)
        for modname, modtiles in pairs(GEMCORE_TILES) do
            for i, modtile in ipairs(modtiles) do
                if modtile.minimap ~= nil then
                    local handle = MapLayerManager:CreateRenderLayer(
                        modtile.id,
                        modtile.minimap.atlas,
                        GroundImage(modtile.minimap.name),
                        modtile.minimap.noise_texture)

                    inst.MiniMap:AddRenderLayer(handle)
                end
            end
        end
    end)
end

GEMENV.AddSimPostInit(function()
    --Patch pitchfork logic
    local _CanTerraformAtPoint = Map.CanTerraformAtPoint
    function Map:CanTerraformAtPoint(x, y, z, ...)
        local tile = self:GetTileAtPoint(x, y, z)
        if _CanTerraformAtPoint(self, x, y, z, ...) then
            return not TERRAFORM_IMMUNE[tile]
        end
        return false
    end
end)


local MakeGemFunction = gemrun("gemfunctionmanager")

local ontileconversion = {}
MakeGemFunction("ontileconversion", function(functionname, cb, ...)
    table.insert(ontileconversion, cb)
end, true)

local function ConvertMapTiles(TileString, ConversionMap)
    if next(ConversionMap) ~= nil then
        local tiles = BinaryString(TileString)

        for tileid, writefn in iterator(tiles, 9, nil, nil, 2, 1) do
            writefn(ConversionMap[tileid] or tileid)
        end

        return tiles:GetAsString()
    end
    return TileString
end

local function GetGroundTileDiff(currentTileSet, previousTileSet)
    local ConversionMap = {}
    for k, v in pairs(currentTileSet) do
        if previousTileSet[k] ~= nil and previousTileSet[k] ~= v then
            ConversionMap[previousTileSet[k]] = v
        end
    end
    return ConversionMap
end

local function ConvertStaticTiles(savedata)
    print("Migrating Static Gem Core Tiles!")

    local ConversionMap = {}
    --this is first load for our DynamicTileManager
    for mod, record in pairs(savedata.mods or {}) do
        if WORKSHOP_NONWORKSHOP_LINKS[mod] ~= nil then
            savedata.mods[WORKSHOP_NONWORKSHOP_LINKS[mod]] = record
        end
    end
    for mod, record in pairs(savedata.mods or {}) do
        --wasLoaded and stillLoaded and HasGemTile's
        if record.active and table.contains(ModManager.enabledmods, mod) and GEMCORE_TILES[string.upper(mod)] ~= nil then
            for i, v in ipairs(GEMCORE_TILES[string.upper(mod)]) do
                ConversionMap[v.old_id] = v.id
            end
        end
    end
    GEMCORETILEDATA = {}
    savedata.map.tiles = ConvertMapTiles(savedata.map.tiles, ConversionMap)

    for i, mod_callback in ipairs(ontileconversion) do
        mod_callback(savedata, ConversionMap)
    end
end

local function ConvertDynamicTiles(savedata, old_GROUND)
    print("Loading Dynamic Gem Core Tiles!")

    local ConversionMap = GetGroundTileDiff(GROUND, old_GROUND)
    savedata.map.tiles = ConvertMapTiles(savedata.map.tiles, ConversionMap)

    for i, mod_callback in ipairs(ontileconversion) do
        mod_callback(savedata, ConversionMap)
    end

    --truncate useless data for nonexistant snapshots
    local function ShouldUseClusterSlot()
        if TheNet:IsDedicated() then
            return false
        end
        return not ShardGameIndex:GetServerData().use_legacy_session_path
    end

    local snapshot_infos
    local saveslot = ShardGameIndex:GetSlot()
    if ShouldUseClusterSlot() then
        --client hosted servers now properly save save games into the Cluster_XX folders!
        snapshot_infos = TheNet:ListSnapshotsInClusterSlot(saveslot, "Master", savedata.meta.session_identifier, TheNet:IsOnlineMode())
    else
        snapshot_infos = TheNet:ListSnapshots(savedata.meta.session_identifier, TheNet:IsOnlineMode())
    end

    if #snapshot_infos >= 1 then
        local deleteIdx = snapshot_infos[#snapshot_infos].snapshot_id - 1
        while deleteIdx > 1 do
            GEMCORETILEDATA[deleteIdx] = nil
            deleteIdx = deleteIdx - 1
        end
    end
end

gemrun("ongeneratenewworld", function(callback, self, savedata, metadataStr, session_identifier, _cb, ...)
    local function cb(...)
        GEMCORETILEDATA = {[2] = GROUND}
        local SetPersistentString
        local function ShouldUseClusterSlot()
            if TheNet:IsDedicated() then
                return false
            end
            return not self:GetServerData().use_legacy_session_path
        end
        local saveslot = ShardGameIndex:GetSlot()
        if ShouldUseClusterSlot() then
            --client hosted servers now properly save save games into the Cluster_XX folders!
            function SetPersistentString(path, data, encode, cb, ...)
                TheSim:SetPersistentStringInClusterSlot(saveslot, "Master", path, data, encode, cb, ...)
            end
        else
            function SetPersistentString(path, data, encode, cb, ...)
                TheSim:SetPersistentString(path, data, encode, cb, ...)
            end
        end
        SetPersistentString("session/"..session_identifier.."/GemCoreTileData", DataDumper(GEMCORETILEDATA, nil, true), false, _cb)
    end
    callback(self, savedata, metadataStr, session_identifier, cb, ...)
end)

gemrun("ondoinitgame", function(callback, savedata, profile, ...)
    local args = {...}
    error = _error
    local GetPersistentString

    local function ShouldUseClusterSlot()
        if TheNet:IsDedicated() then
            return false
        end
        return not ShardGameIndex:GetServerData().use_legacy_session_path
    end
    local saveslot = ShardGameIndex:GetSlot()
    if ShouldUseClusterSlot() then
        --client hosted servers now properly save save games into the Cluster_XX folders!
        function GetPersistentString(path, cb, ...)
            TheSim:GetPersistentStringInClusterSlot(saveslot, "Master", path, cb, ...)
        end
    else
        function GetPersistentString(path, cb, ...)
            TheSim:GetPersistentString(path, cb, ...)
        end
    end
    GetPersistentString("session/"..savedata.meta.session_identifier.."/GemCoreTileData", function(load_success, str)
        print("Loading GemCore's DynamicTileManager")

        if not (load_success and #str > 0) then
            ConvertStaticTiles(savedata)
        else
            GEMCORETILEDATA = loadstring(str)()

            local old_GROUND
            local idx = TheNet:GetCurrentSnapshot()
            while idx > 1 do
                if GEMCORETILEDATA[idx] ~= nil then
                    old_GROUND = GEMCORETILEDATA[idx]
                    break
                end
                idx = idx - 1
            end

            if old_GROUND then
                ConvertDynamicTiles(savedata, old_GROUND)
            else
                ConvertStaticTiles(savedata)
            end
        end
        callback(savedata, profile, unpack(args))
    end)
end)

gemrun("onsavegame", function(callback, ...)
    GEMCORETILEDATA[TheNet:GetCurrentSnapshot()] = GROUND
    local SetPersistentString
    local function ShouldUseClusterSlot()
        if TheNet:IsDedicated() then
            return false
        end
        return not ShardGameIndex:GetServerData().use_legacy_session_path
    end

    local saveslot = ShardGameIndex:GetSlot()
    if ShouldUseClusterSlot() then
        --client hosted servers now properly save save games into the Cluster_XX folders!
        function SetPersistentString(path, data, encode, cb, ...)
            TheSim:SetPersistentStringInClusterSlot(saveslot, "Master", path, data, encode, cb, ...)
        end
    else
        function SetPersistentString(path, data, encode, cb, ...)
            TheSim:SetPersistentString(path, data, encode, cb, ...)
        end
    end
    SetPersistentString("session/"..TheWorld.meta.session_identifier.."/GemCoreTileData", DataDumper(GEMCORETILEDATA, nil, true), false)
    callback(...)
end)

local DynamicTileManager = {}

function DynamicTileManager.AddModTile(modname, tile_name, tile_def, id_changed_cb)

    tile_name = string.upper(tile_name)
    modname = string.upper(modname)

    local tile = Tile(tile_def.texture_name, tile_def.noise_texture,
        tile_def.run_sound, tile_def.walk_sound,
        tile_def.snow_sound, tile_def.mud_sound,
        tile_def.flashpoint_modifier, tile_def.turf_name,
        tile_def.canbedug, tile_def.bank_build)

    local mini_tile = Tile("map_edge", tile_def.mini_noise_texture)

    -- Add assets to the assets table.
    table.insert(assets, Asset("IMAGE", GroundImage(tile.name)))
    table.insert(assets, Asset("FILE", tile.atlas))
    table.insert(assets, Asset("IMAGE", tile.noise_texture))
    table.insert(assets, Asset("IMAGE", mini_tile.noise_texture))

    if not GEMCORE_TILES[modname] then GEMCORE_TILES[modname] = {} end

    table.insert(GEMCORE_TILES[modname], {
        name = tile_name,
        ground = tile,
        minimap = mini_tile,
        old_id = tile_def.old_static_id,
        water = tile_def.water,
        underground = tile_def.underground,
        id = GetNextFreeID(tile_def.water, tile_def.underground),
        tileidchangedcb = tile_def.id_changed_cb or id_changed_cb,
    })

    -- Fill in GROUND[_uppercase]
    -- Fill in GROUND_NAMES[next_index]
    -- Fill in GROUND_PROPERTIES (worldtiledef.ground)
    -- Mod tiles are a little different
    -- we make sure to check to see if it's added first.
    local modtile = GEMCORE_TILES[modname][#GEMCORE_TILES[modname]]
    if not modtile.isprocessed then

        GROUND[modtile.name] = modtile.id
        GROUND_NAMES[modtile.id] = modtile.name

        table.insert(tiles.ground, {modtile.id, modtile.ground})

        if modtile.ground.turf_name then
            tiles.turf[modtile.id] = {name=modtile.ground.turf_name, anim=modtile.ground.turf_name, bank_build = modtile.ground.bank_build}
        end

        TERRAFORM_IMMUNE[modtile.id] = not modtile.ground.canbedug

        modtile.isprocessed = true
    end
end

function DynamicTileManager.ChangeTileRenderOrder(tile_id, target_tile_id, moveafter)
    local idx = nil
    for i, ground in ipairs(tiles.ground) do
        if ground[1] ~= nil and ground[1] == tile_id then
            idx = i
            break
        end
    end

    local item = table.remove(tiles.ground, idx)

    local targetidx = nil
    for i, ground in ipairs(tiles.ground) do
        if ground[1] ~= nil and ground[1] == target_tile_id then
            targetidx = i
            break
        end
    end
    targetidx = moveafter and targetidx + 1 or targetidx
    table.insert(tiles.ground, targetidx, item)
end

function DynamicTileManager.SetTileProperty(tile_id, propertyname, value)
    for i, ground in ipairs(tiles.ground) do
        if ground[1] ~= nil and ground[1] == tile_id then
            ground[2][propertyname] = value
            return
        end
    end
end

function DynamicTileManager.SetWorkshopNonWorkshopLink(workshop_folder_name, nonworkshop_folder_name)
    WORKSHOP_NONWORKSHOP_LINKS[workshop_folder_name] = nonworkshop_folder_name
    WORKSHOP_NONWORKSHOP_LINKS[nonworkshop_folder_name] = workshop_folder_name
end

return DynamicTileManager