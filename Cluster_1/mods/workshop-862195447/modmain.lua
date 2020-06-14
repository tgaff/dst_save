--[[
Copyright (C) 2018, 2019 Zarklord

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
local enabledmods = {}

for _,modname in pairs(GLOBAL.TheNet:GetIsServer() and GLOBAL.ModManager:GetEnabledServerModNames() or GLOBAL.TheNet:GetServerModNames()) do
	enabledmods[GLOBAL.KnownModIndex:GetModFancyName(modname)] = true
end

--create dummy bit.band function if gemcore isn't loaded.
bit = {band = function() return 0 end}
if enabledmods["[API] Gem Core"] == true then
	GLOBAL.SetupGemCoreEnv()
end

local loadstring = GLOBAL.loadstring
local STRINGS = GLOBAL.STRINGS

TUNING.FOLLOWEREVERYONE = 
{
	FOLLOWERTYPES = GetModConfigData("followertypes"),
}

local chester = bit.band(TUNING.FOLLOWEREVERYONE.FOLLOWERTYPES, 4) ~= 0
local hutch = bit.band(TUNING.FOLLOWEREVERYONE.FOLLOWERTYPES, 2) ~= 0
local packim = bit.band(TUNING.FOLLOWEREVERYONE.FOLLOWERTYPES, 1) ~= 0 and (enabledmods["Island Adventures"] or enabledmods["Island Adventures - GitLab Ver."]) == true

if chester then
	CustomTechTree.AddNewTechType("EYEBONE")
	TUNING.FOLLOWEREVERYONE.CHESTER = {
		INGREDIENTS = loadstring("return "..GetModConfigData("chester_craft"))(),
		TECH = loadstring("return "..GetModConfigData("chester_science"))(),
		TECHLVL = 2,
	}
	local CHESTER = TUNING.FOLLOWEREVERYONE.CHESTER

	GLOBAL.TECH.EYETECH = {EYEBONE = CHESTER.TECHLVL}

	local TECH = CHESTER.TECH
	if TECH ~= nil then
		for k, v in pairs(TECH.tech) do
			GLOBAL.TECH.EYETECH[k] = v
		end
		if TECH.hint ~= nil then
			CustomTechTree.AddTechHint(GLOBAL.TECH.EYETECH, TECH.hint)
		end
	end
	STRINGS.RECIPE_DESC.CHESTER_EYEBONE = "Get Your Very Own Chester!" 
	AddRecipe("chester_eyebone", CHESTER.INGREDIENTS, GLOBAL.RECIPETABS.TOOLS, GLOBAL.TECH.EYETECH, nil, nil, true)
end

if hutch then
	CustomTechTree.AddNewTechType("STARSKY")
	TUNING.FOLLOWEREVERYONE.HUTCH = {
		INGREDIENTS = loadstring("return "..GetModConfigData("hutch_craft"))(),
		TECH = loadstring("return "..GetModConfigData("hutch_science"))(),
		TECHLVL = 2,
	}
	local HUTCH = TUNING.FOLLOWEREVERYONE.HUTCH

	GLOBAL.TECH.STARTECH = {STARSKY = HUTCH.TECHLVL}

	local TECH = HUTCH.TECH
	if TECH ~= nil then
		for k, v in pairs(TECH.tech) do
			GLOBAL.TECH.STARTECH[k] = v
		end
		if TECH.hint ~= nil then
			CustomTechTree.AddTechHint(GLOBAL.TECH.STARTECH, TECH.hint)
		end
	end
	STRINGS.RECIPE_DESC.HUTCH_FISHBOWL = "Get Your Very Own Hutch!" 
	AddRecipe("hutch_fishbowl", HUTCH.INGREDIENTS, GLOBAL.RECIPETABS.TOOLS, GLOBAL.TECH.STARTECH, nil, nil, true)
end

if packim then
	CustomTechTree.AddNewTechType("FISHBONE")
	TUNING.FOLLOWEREVERYONE.PACKIM = {
		INGREDIENTS = loadstring("return "..GetModConfigData("packim_craft"))(),
		TECH = loadstring("return "..GetModConfigData("packim_science"))(),
		TECHLVL = 2,
		MAX = GetModConfigData("packim_max"),
		WORLDLOCATIONS = loadstring("return "..GetModConfigData("packim_locations"))(),
	}
	local PACKIM = TUNING.FOLLOWEREVERYONE.PACKIM

	GLOBAL.TECH.FISHTECH = {FISHBONE = PACKIM.TECHLVL}

	local TECH = PACKIM.TECH
	if TECH ~= nil then
		for k, v in pairs(TECH.tech) do
			GLOBAL.TECH.FISHTECH[k] = v
		end
		if TECH.hint ~= nil then
			CustomTechTree.AddTechHint(GLOBAL.TECH.FISHTECH, TECH.hint)
		end
	end
	STRINGS.RECIPE_DESC.PACKIM_FISHBONE = "Get Your Very Own Packim Baggims!" 
	AddRecipe("packim_fishbone", PACKIM.INGREDIENTS, GLOBAL.RECIPETABS.TOOLS, GLOBAL.TECH.FISHTECH, nil, nil, true, nil, nil, "images/ia_inventoryimages.xml")
end

if not GLOBAL.TheNet:GetIsServer() then return end

TUNING.FOLLOWEREVERYONE.OWNERSHIP = GetModConfigData("ownership")

if chester or hutch or packim then
	GLOBAL.AddShardRPCHandler("FOLLOWERSFORALL", "SpawnAndKillFollower", function(shard_id, followerdata)
		GLOBAL.SpawnSaveRecord(followerdata).components.health:Kill()
	end)
end

local function IsValidWorld(follower)
	local FOLLOWER = TUNING.FOLLOWEREVERYONE[follower] 
	if FOLLOWER.WORLDLOCATIONS == nil then return true end
	for i, v in pairs(FOLLOWER.WORLDLOCATIONS) do
		if GLOBAL.TheWorld:HasTag(v) then return true end
	end
	return false
end

if chester then
	local CHESTER = TUNING.FOLLOWEREVERYONE.CHESTER
	CHESTER.MAX = GetModConfigData("chester_max")
	CHESTER.WORLDLOCATIONS = loadstring("return "..GetModConfigData("chester_locations"))()
	if CHESTER.WORLDLOCATIONS ~= nil then CHESTER.WORLDLOCATIONS[#CHESTER.WORLDLOCATIONS + 1] = "forest" end

	local function ChesterPost()
		MODENV.AddPrefabPostInit("chester", function(inst)
			inst.components.inspectable.nameoverride = "chester"

			inst:AddComponent("named")
		end)

		MODENV.AddPrefabPostInit("chester_eyebone", function(inst)
			local SPAWN_DIST = 30

			local function OpenEye(inst)
			    if not inst.isOpenEye then
			        inst.isOpenEye = true
			        inst.components.inventoryitem:ChangeImageName(inst.openEye)
			        inst.AnimState:PlayAnimation("idle_loop", true)
			    end
			end

			local function CloseEye(inst)
			    if inst.isOpenEye then
			        inst.isOpenEye = nil
			        inst.components.inventoryitem:ChangeImageName(inst.closedEye)
			        inst.AnimState:PlayAnimation("dead", true)
			    end
			end

			local function GetSpawnPoint(pt)
                local offset = FindWalkableOffset(pt, math.random() * 2 * PI, SPAWN_DIST, 12, true)
                if offset ~= nil then
                    offset.x = offset.x + pt.x
                    offset.z = offset.z + pt.z
                    return offset
                end
			end

			local function SpawnChester(inst)
			    if not inst.CHESTEREVERYONE.owner then
			        print("Error: Eyebone has no linked player!")
			        return
			    end
			    --print("chester_eyebone - SpawnChester")

			    local pt = inst:GetPosition()
			    --print("    near", pt)

			    local spawn_pt = GetSpawnPoint(pt)
			    if spawn_pt ~= nil then
			        --print("    at", spawn_pt)
			        local chester = SpawnPrefab("chester")
			        if chester ~= nil then
			            chester.Physics:Teleport(spawn_pt:Get())
			            chester:FacePoint(pt:Get())
					    if inst.CHESTEREVERYONE.owner and inst.CHESTEREVERYONE.owner.CHESTEREVERYONE then
					        inst.CHESTEREVERYONE.owner.CHESTEREVERYONE[inst.CHESTEREVERYONE.eyenum].chester = chester
					    end
			            return chester
			        end

			    --else
			        -- this is not fatal, they can try again in a new location by picking up the bone again
			        --print("chester_eyebone - SpawnChester: Couldn't find a suitable spawn point for chester")
			    end
			end

			local StartRespawn

			local function StopRespawn(inst)
			    if inst.respawntask ~= nil then
			        inst.respawntask:Cancel()
			        inst.respawntask = nil
			        inst.respawntime = nil
			    end
			end

			local function RebindChester(inst,chester)
			    chester = chester or (inst.CHESTEREVERYONE.owner and inst.CHESTEREVERYONE.owner.CHESTEREVERYONE and inst.CHESTEREVERYONE.owner.CHESTEREVERYONE[inst.CHESTEREVERYONE.eyenum].chester)
			    chester = chester or FindEntity(inst,16,nil,{"chester"},{"claimed_chester"},nil)
			    if chester ~= nil then
			        if inst.CHESTEREVERYONE.owner then
			            chester.components.named:SetName(inst.CHESTEREVERYONE.owner.name.."'s Chester")
			            chester:AddTag("claimed_chester")
			            chester.persists = false
			            if inst.CHESTEREVERYONE.ownership then
			                chester:AddTag("uid_private")
			                chester:AddTag("uid_" .. inst.CHESTEREVERYONE.owner.userid)
			            end
			            inst.CHESTEREVERYONE.owner.CHESTEREVERYONE[inst.CHESTEREVERYONE.eyenum].chester = chester
			        end
			        OpenEye(inst)
			        inst:ListenForEvent("death", function()
			            if inst.CHESTEREVERYONE.owner and inst.CHESTEREVERYONE.owner.CHESTEREVERYONE then
			                inst.CHESTEREVERYONE.owner.CHESTEREVERYONE[inst.CHESTEREVERYONE.eyenum].chester = nil
			            end 
			            StartRespawn(inst, TUNING.CHESTER_RESPAWN_TIME) 
			        end, chester)

			        if chester.components.follower.leader ~= inst then
			            chester.components.follower:SetLeader(inst)
			        end
			        return true
			    end
			end

			local function RespawnChester(inst)
			    StopRespawn(inst)
			    --try to find a unclaimed chester if that fails spawn a new chester
			    RebindChester(inst, 
			        (inst.CHESTEREVERYONE.owner and inst.CHESTEREVERYONE.owner.CHESTEREVERYONE and inst.CHESTEREVERYONE.owner.CHESTEREVERYONE[inst.CHESTEREVERYONE.eyenum].chester)
			        or FindEntity(inst,16,nil,{"chester"},{"claimed_chester"},nil)
			        or SpawnChester(inst))
			end

			StartRespawn = function(inst, time)
			    StopRespawn(inst)

			    time = time or 0
			    inst.respawntask = inst:DoTaskInTime(time, RespawnChester)
			    inst.respawntime = GetTime() + time
			    CloseEye(inst)
			end

			local function FixChester(inst)
			    inst.fixtask = nil
			    --take an existing chester if there is one
			    if not RebindChester(inst) then
			        CloseEye(inst)
			        
			        if inst.components.inventoryitem.owner ~= nil then
			            local time_remaining = inst.respawntime ~= nil and math.max(0, inst.respawntime - GetTime()) or 0
			            StartRespawn(inst, time_remaining)
			        end
			    end
			end

			local function OnPutInInventory(inst)
				if IsValidWorld("CHESTER") then
					local owner = inst.components.inventoryitem:GetGrandOwner()
					if owner ~= nil and owner:HasTag("player") then
						if inst.CHESTEREVERYONE.owner == nil then
							if (#owner.CHESTEREVERYONE or 0) < CHESTER.MAX then
								owner.CHESTEREVERYONE[#owner.CHESTEREVERYONE + 1] = {}
								owner.CHESTEREVERYONE[#owner.CHESTEREVERYONE].eyebone = inst
								inst.CHESTEREVERYONE.owner = owner
								inst.CHESTEREVERYONE.eyenum = #owner.CHESTEREVERYONE
								inst.persists = false
								inst.components.named:SetName(owner.name.."'s Eye Bone")
								inst.CHESTEREVERYONE.ownership = TUNING.FOLLOWEREVERYONE.OWNERSHIP
							else 
								inst:DoTaskInTime(0, function(inst, owner)
									if owner.components.inventory ~= nil then
										owner.components.inventory:DropItem(inst, true, true)
									end
								end, owner)
								if owner.components.talker then
									owner.components.talker:Say("I can't do that.")
								end
							end
						end
						if (#owner.CHESTEREVERYONE or 0) >= CHESTER.MAX and owner.components.builder then
							owner.components.builder.eyebone_bonus = 0
						end
					end
				end
			    if inst.fixtask == nil then
			        inst.fixtask = inst:DoTaskInTime(1, FixChester)
			    end
			end

		    --replace the fn with our modified version...
		    --this is really hacky and only slightly better than putting the full modified prefabs in our mod
		    --this is the only way to replace the actual functions that we need to modify
		    inst.fixtask.fn = FixChester

		    inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInventory)

		    inst.components.inspectable.nameoverride = "chester_eyebone"

		    inst:AddComponent("named")

		    inst.CHESTEREVERYONE = {GetSpawnPoint = GetSpawnPoint}

		end)
	end
	GLOBAL.setfenv(ChesterPost, GLOBAL)
	ChesterPost()
end

if hutch then
	local HUTCH = TUNING.FOLLOWEREVERYONE.HUTCH
	HUTCH.MAX = GetModConfigData("hutch_max")
	HUTCH.WORLDLOCATIONS = loadstring("return "..GetModConfigData("hutch_locations"))()
	if HUTCH.WORLDLOCATIONS ~= nil then HUTCH.WORLDLOCATIONS[#HUTCH.WORLDLOCATIONS + 1] = "cave" end

	local function HutchPost()
		MODENV.AddPrefabPostInit("hutch", function(inst)
			inst.components.inspectable.nameoverride = "hutch"

			inst:AddComponent("named")
		end)

		MODENV.AddPrefabPostInit("hutch_fishbowl", function(inst)
			local SPAWN_DIST = 30

			local function FishAlive(inst, instant)
			    if not inst.isFishAlive then
			        inst.isFishAlive = true
			        inst.components.inventoryitem:ChangeImageName(inst.fishAlive)
			        if instant then
			            inst.AnimState:PlayAnimation("idle_loop", true)
			        else
			            inst.AnimState:PlayAnimation("revive")
			            inst.AnimState:PushAnimation("idle_loop", true)
			        end
			    end
			end

			local function FishDead(inst, instant)
			    if inst.isFishAlive then
			        inst.isFishAlive = nil
			        inst.components.inventoryitem:ChangeImageName(inst.fishDead)
			        if instant then
			            inst.AnimState:PlayAnimation("dead", true)
			        else
			            inst.AnimState:PlayAnimation("die")
			            inst.AnimState:PushAnimation("dead", true)
			        end
			    end
			end

			local function NoHoles(pt)
			    return not TheWorld.Map:IsPointNearHole(pt)
			end

			local function GetSpawnPoint(pt)
			    local offset = FindWalkableOffset(pt, math.random() * 2 * PI, SPAWN_DIST, 12, true, true, NoHoles)
			    if offset ~= nil then
			        offset.x = offset.x + pt.x
			        offset.z = offset.z + pt.z
			        return offset
			    end
			end

			local function SpawnHutch(inst)
			    if not inst.HUTCHEVERYONE.owner then
			        print("Error: Starsky has no linked player!")
			        return
			    end
			    local pt = inst:GetPosition()
			    local spawn_pt = GetSpawnPoint(pt)
			    if spawn_pt ~= nil then
			        local hutch = SpawnPrefab("hutch")
			        if hutch ~= nil then
			            hutch.Physics:Teleport(spawn_pt:Get())
			            hutch:FacePoint(pt:Get())
		                if inst.HUTCHEVERYONE.owner and inst.HUTCHEVERYONE.owner.HUTCHEVERYONE then
		                    inst.HUTCHEVERYONE.owner.HUTCHEVERYONE[inst.HUTCHEVERYONE.starnum].hutch = hutch
		                end
			            return hutch
			        end
			    --else
			        -- this is not fatal, they can try again in a new location by picking up the starsky again
			        --print("hutch_fishbowl - SpawnHutch: Couldn't find a suitable spawn point for hutch")
			    end
			end

			local StartRespawn

			local function StopRespawn(inst)
			    if inst.respawntask ~= nil then
			        inst.respawntask:Cancel()
			        inst.respawntask = nil
			        inst.respawntime = nil
			    end
			    if inst.fishalivetask ~= nil then
			        inst.fishalivetask:Cancel()
			        inst.fishalivetask = nil
			    end
			end

			local function RebindHutch(inst, hutch)
			    hutch = hutch or (inst.HUTCHEVERYONE.owner and inst.HUTCHEVERYONE.owner.HUTCHEVERYONE and inst.HUTCHEVERYONE.owner.HUTCHEVERYONE[inst.HUTCHEVERYONE.starnum].hutch)
			    hutch = hutch or FindEntity(inst,16,nil,{"hutch"},{"claimed_hutch"},nil)
			    if hutch ~= nil then
			        if inst.HUTCHEVERYONE.owner then
			            hutch.components.named:SetName(inst.HUTCHEVERYONE.owner.name.."'s Hutch")
			            hutch:AddTag("claimed_hutch")
			            hutch.persists = false
			            if inst.HUTCHEVERYONE.ownership then
			                hutch:AddTag("uid_private")
			                hutch:AddTag("uid_" .. inst.HUTCHEVERYONE.owner.userid)
			            end
			            inst.HUTCHEVERYONE.owner.HUTCHEVERYONE[inst.HUTCHEVERYONE.starnum].hutch = hutch
			        end
			        FishAlive(inst)
			        inst:ListenForEvent("death", function() 
			            if inst.HUTCHEVERYONE.owner and inst.HUTCHEVERYONE.owner.HUTCHEVERYONE then
			                inst.HUTCHEVERYONE.owner.HUTCHEVERYONE[inst.HUTCHEVERYONE.starnum].hutch = nil
			            end 
			        	StartRespawn(inst, TUNING.HUTCH_RESPAWN_TIME) 
			        end, hutch)

			        if hutch.components.follower.leader ~= inst then
			            hutch.components.follower:SetLeader(inst)
			        end
			        return true
			    end
			end
			
			local function RespawnHutch(inst)
			    StopRespawn(inst)
			    --try to find a unclaimed hutch if that fails spawn a new hutch
			    RebindHutch(inst, 
			    	(inst.HUTCHEVERYONE.owner and inst.HUTCHEVERYONE.owner.HUTCHEVERYONE and inst.HUTCHEVERYONE.owner.HUTCHEVERYONE[inst.HUTCHEVERYONE.starnum].hutch) 
			    	or FindEntity(inst,16,nil,{"hutch"},{"claimed_hutch"},nil)
			    	or SpawnHutch(inst))
			end

			StartRespawn = function(inst, time)
			    StopRespawn(inst)

			    time = time or 0
			    inst.respawntask = inst:DoTaskInTime(time, RespawnHutch)
			    inst.respawntime = GetTime() + time
			    if time > 0 then
			        FishDead(inst)
			    end
			end

			local function Onfishalivetask(inst)
			    inst.fishalivetask = nil
			    FishAlive(inst)
			end

			local function FixHutch(inst)
			    inst.fixtask = nil
			    --take an existing hutch if there is one
			    if not RebindHutch(inst) then
			        local time_remaining = inst.respawntime ~= nil and math.max(0, inst.respawntime - GetTime()) or 0

			        if inst.components.inventoryitem.owner ~= nil then
			            StartRespawn(inst, time_remaining)
			        elseif time_remaining > 0 then
			            FishDead(inst)
			            if inst.fishalivetask ~= nil then
			                inst.fishalivetask:Cancel()
			            end
			            inst.fishalivetask = inst:DoTaskInTime(time_remaining, Onfishalivetask)
			        end
			    end
			end

			local function OnPutInInventory(inst)
				if IsValidWorld("HUTCH") then
					local owner = inst.components.inventoryitem:GetGrandOwner()
					if owner ~= nil and owner:HasTag("player") then
						if inst.HUTCHEVERYONE.owner == nil then
							if (#owner.HUTCHEVERYONE or 0) < HUTCH.MAX then
								owner.HUTCHEVERYONE[#owner.HUTCHEVERYONE + 1] = {}
								owner.HUTCHEVERYONE[#owner.HUTCHEVERYONE].starsky = inst
								inst.HUTCHEVERYONE.owner = owner
								inst.HUTCHEVERYONE.starnum = #owner.HUTCHEVERYONE
								inst.persists = false
								inst.components.named:SetName(owner.name.."'s Star-Sky")
								inst.HUTCHEVERYONE.ownership = TUNING.FOLLOWEREVERYONE.OWNERSHIP
							else 
								inst:DoTaskInTime(0, function(inst, owner)
									if owner.components.inventory ~= nil then
										owner.components.inventory:DropItem(inst, true, true)
									end
								end, owner)
								if owner.components.talker then
									owner.components.talker:Say("I can't do that.")
								end
							end
						end
						if (#owner.HUTCHEVERYONE or 0) >= HUTCH.MAX and owner.components.builder then
							owner.components.builder.starsky_bonus = 0
						end
					end
				end
			    if inst.fixtask == nil then
			        inst.fixtask = inst:DoTaskInTime(1, FixHutch)
			    end
			end

		    --replace the fn with our modified version...
		    --this is really hacky and only slightly better than putting the full modified prefabs in our mod
		    --this is the only way to replace the actual functions that we need to modify
		    inst.fixtask.fn = FixHutch

		    inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInventory)

		    inst.components.inspectable.nameoverride = "hutch_fishbowl"

		    inst:AddComponent("named")

		    inst.HUTCHEVERYONE = {GetSpawnPoint = GetSpawnPoint}

		end)
	end
	GLOBAL.setfenv(HutchPost, GLOBAL)
	HutchPost()
end

if packim then
	local PACKIM = TUNING.FOLLOWEREVERYONE.PACKIM
	PACKIM.MAX = GetModConfigData("packim_max")
	PACKIM.WORLDLOCATIONS = loadstring("return "..GetModConfigData("packim_locations"))()
	if PACKIM.WORLDLOCATIONS ~= nil then PACKIM.WORLDLOCATIONS[#PACKIM.WORLDLOCATIONS + 1] = "island" end

    local function PackimPost()
        MODENV.AddPrefabPostInit("packim", function(inst)
            inst.components.inspectable.nameoverride = "packim"

            inst:AddComponent("named")
        end)

        MODENV.AddPrefabPostInit("packim_fishbone", function(inst)
            local SPAWN_DIST = 30

            local function PackimDead(inst)
                inst.components.floatable:UpdateAnimations("dead_water", "dead")
                if inst.components.floatable.onwater then
                    inst.AnimState:PlayAnimation("dead_water", true)
                else
                    inst.AnimState:PlayAnimation("dead", true)
                end
                inst.components.inventoryitem:ChangeImageName("packim_fishbone_dead")
            end

            local function PackimLive(inst)
                inst.components.floatable:UpdateAnimations("idle_water", "idle_loop")
                if inst.components.floatable.onwater then
                    inst.AnimState:PlayAnimation("idle_water")
                else
                    inst.AnimState:PlayAnimation("idle_loop")
                end
                inst.components.inventoryitem:ChangeImageName("packim_fishbone")
            end

            local function GetSpawnPoint(pt)
                local offset = FindWalkableOffset(pt, math.random() * 2 * PI, SPAWN_DIST, 12, true)
                if offset ~= nil then
                    offset.x = offset.x + pt.x
                    offset.z = offset.z + pt.z
                    return offset
                end
            end

            local function SpawnPackim(inst)
                if not inst.PACKIMEVERYONE.owner then
                    print("Error: Fishbone has no linked player!")
                    return
                end
                local pt = inst:GetPosition()
                local spawn_pt = GetSpawnPoint(pt)
                if spawn_pt ~= nil then
                    local packim = SpawnPrefab("packim")
                    if packim ~= nil then
                        packim.Physics:Teleport(spawn_pt:Get())
                        packim:FacePoint(pt:Get())
                        if inst.PACKIMEVERYONE.owner and inst.PACKIMEVERYONE.owner.PACKIMEVERYONE then
                            inst.PACKIMEVERYONE.owner.PACKIMEVERYONE[inst.PACKIMEVERYONE.fishnum].packim = packim
                        end
                        return packim
                    end
                -- else
                    -- this is not fatal, they can try again in a new location by picking up the bone again
                end
            end

            local StartRespawn --initialised later

            local function StopRespawn(inst)
                if inst.respawntask then
                    inst.respawntask:Cancel()
                    inst.respawntask = nil
                    inst.respawntime = nil
                end
            end

            local function RebindPackim(inst, packim)
                packim = packim or (inst.PACKIMEVERYONE.owner and inst.PACKIMEVERYONE.owner.PACKIMEVERYONE and inst.PACKIMEVERYONE.owner.PACKIMEVERYONE[inst.PACKIMEVERYONE.fishnum].packim)
                packim = packim or FindEntity(inst,16,nil,{"packim"},{"claimed_packim"},nil)
                if packim then
                    if inst.PACKIMEVERYONE.owner then
                        packim.components.named:SetName(inst.PACKIMEVERYONE.owner.name.."'s Packim Baggims")
                        packim:AddTag("claimed_packim")
                        packim.persists = false
                        if inst.PACKIMEVERYONE.ownership then
                            packim:AddTag("uid_private")
                            packim:AddTag("uid_" .. inst.PACKIMEVERYONE.owner.userid)
                        end
                        inst.PACKIMEVERYONE.owner.PACKIMEVERYONE[inst.PACKIMEVERYONE.fishnum].packim = packim
                    end
                    PackimLive(inst)
                    inst:ListenForEvent("death", function()
                        if inst.PACKIMEVERYONE.owner and inst.PACKIMEVERYONE.owner.PACKIMEVERYONE then
                            inst.PACKIMEVERYONE.owner.PACKIMEVERYONE[inst.PACKIMEVERYONE.fishnum].packim = nil
                        end 
                        StartRespawn(inst, TUNING.PACKIM_RESPAWN_TIME) 
                    end, packim)

                    if packim.components.follower.leader ~= inst then
                        packim.components.follower:SetLeader(inst)
                    end
                    return true
                end
            end

            local function RespawnPackim(inst)
                StopRespawn(inst)
                --try to find a unclaimed packim if that fails spawn a new packim
                RebindPackim(inst,  
                    (inst.PACKIMEVERYONE.owner and inst.PACKIMEVERYONE.owner.PACKIMEVERYONE and inst.PACKIMEVERYONE.owner.PACKIMEVERYONE[inst.PACKIMEVERYONE.fishnum].packim) 
                    or FindEntity(inst,16,nil,{"packim"},{"claimed_packim"},nil)
                    or SpawnPackim(inst))
            end

            function StartRespawn(inst, time)
                StopRespawn(inst)

                local time = time or 0
                inst.respawntask = inst:DoTaskInTime(time, RespawnPackim)
                inst.respawntime = GetTime() + time
                if time > 0 then
                    PackimDead(inst)
                end
            end

            local function FixPackim(inst)
                inst.fixtask = nil
                --take an existing FAT BIRD if there is one
                if not RebindPackim(inst) then
                    PackimDead(inst)

                    if inst.components.inventoryitem.owner then
                        local time_remaining = inst.respawntime ~= nil and math.max(0, inst.respawntime - GetTime()) or 0
                        StartRespawn(inst, time_remaining)
                    end
                end
            end

            local function OnPutInInventory(inst)
                if IsValidWorld("PACKIM") then
                    local owner = inst.components.inventoryitem:GetGrandOwner()
                    if owner ~= nil and owner:HasTag("player") then
                        if inst.PACKIMEVERYONE.owner == nil then
                            if (#owner.PACKIMEVERYONE or 0) < PACKIM.MAX then
                                owner.PACKIMEVERYONE[#owner.PACKIMEVERYONE + 1] = {}
                                owner.PACKIMEVERYONE[#owner.PACKIMEVERYONE].fishbone = inst
                                inst.PACKIMEVERYONE.owner = owner
                                inst.PACKIMEVERYONE.fishnum = #owner.PACKIMEVERYONE
                                inst.persists = false
                                inst.components.named:SetName(owner.name.."'s Fishbone")
                                inst.PACKIMEVERYONE.ownership = TUNING.FOLLOWEREVERYONE.OWNERSHIP
                            else 
                                inst:DoTaskInTime(0, function(inst, owner)
                                    if owner.components.inventory ~= nil then
                                        owner.components.inventory:DropItem(inst, true, true)
                                    end
                                end, owner)
                                if owner.components.talker then
                                    owner.components.talker:Say("I can't do that.")
                                end
                            end
                        end
                        if (#owner.PACKIMEVERYONE or 0) >= PACKIM.MAX and owner.components.builder then
                            owner.components.builder.fishbone_bonus = 0
                        end
                    end
                end
                if inst.fixtask == nil then
                    inst.fixtask = inst:DoTaskInTime(1, FixPackim)
                end
            end

            --replace the fn with our modified version...
            --this is really hacky and only slightly better than putting the full modified prefabs in our mod
            --this is the only way to replace the actual functions that we need to modify
            inst.fixtask.fn = FixPackim

            inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInventory)

            inst.components.inspectable.nameoverride = "packim_fishbone"

            inst:AddComponent("named")

            inst.PACKIMEVERYONE = {GetSpawnPoint = GetSpawnPoint}

        end)
    end
    GLOBAL.setfenv(PackimPost, GLOBAL)
    PackimPost()
end

local function PlayerPost(inst)
------------------------------------------------------------------------------------------
--                                  Chester Start                                       --
------------------------------------------------------------------------------------------
	local OnNewSpawnChester = chester and IsValidWorld("CHESTER") and function(inst)
		inst.CHESTEREVERYONE = {}
		inst.components.builder.eyebone_bonus = TUNING.FOLLOWEREVERYONE.CHESTER.TECHLVL
	end or function() end

	local OnDespawnChester = chester and IsValidWorld("CHESTER") and function(inst)
		for i, v in ipairs(inst.CHESTEREVERYONE) do
			if v.eyebone.components then
				-- Eyebone drops from whatever its in
				local owner = v.eyebone.components.inventoryitem:GetGrandOwner()
				v.canMigrate = owner == inst
				if owner then
					--drop items from containers/inv's
					if owner.components.container then
						owner.components.container:DropItem(v.eyebone)
					elseif owner.components.inventory then
						owner.components.inventory:DropItem(v.eyebone)
					end
		 		end

				-- We need time to save before despawning.
				v.eyebone:DoTaskInTime(0.1, function(eyebone)
					if eyebone and eyebone:IsValid() then
						eyebone:Remove()
					end
				end)

                if v.chester then
                    -- Don't allow chester to despawn with irreplaceable items
                    v.chester.components.container:DropEverythingWithTag("irreplaceable")
    				v.chester:DoTaskInTime(0.1, function(chester)
    					if chester and chester:IsValid() then
    						chester:Remove()
    					end
    				end)
                end
			end
		end
	end or function() end

	local OnSaveChester = chester and IsValidWorld("CHESTER") and function(inst, data)
		data.CHESTEREVERYONE = {}

		for i, v in ipairs(inst.CHESTEREVERYONE) do
			data.CHESTEREVERYONE[i] = {}
			--Save Chester and the Eyebone
			if v.eyebone.components then
				--Chester and the Eyebone are alive in the world so save the data
				data.CHESTEREVERYONE[i].canMigrate = v.canMigrate
				data.CHESTEREVERYONE[i].eyebone = v.eyebone:GetSaveRecord()
				data.CHESTEREVERYONE[i].shardId = TheShard:GetShardId()
                if v.chester then
                    data.CHESTEREVERYONE[i].chester = v.chester:GetSaveRecord()
                end
			else
				--Chester and The Eyebone aren't alive in the world so pass through the data
				data.CHESTEREVERYONE[i].eyebone = v.eyebone
				data.CHESTEREVERYONE[i].chester = v.chester
				data.CHESTEREVERYONE[i].shardId = v.shardId
				data.CHESTEREVERYONE[i].canMigrate = v.canMigrate
			end
		end
	end or function(inst, data) 
		--pass through the data but dont do anything else
		data.CHESTEREVERYONE = inst.CHESTEREVERYONE or {}
	end

	local OnLoadChester = chester and IsValidWorld("CHESTER") and function(inst, data)
		inst.CHESTEREVERYONE = {}
		if data.CHESTEREVERYONE then

			--migrating to a new save format...
			if data.CHESTEREVERYONE.chester ~= nil and data.CHESTEREVERYONE.eyebone ~= nil then
				for i, v in ipairs(data.CHESTEREVERYONE.eyebone) do
					data.CHESTEREVERYONE[i] = {}
					data.CHESTEREVERYONE[i].eyebone = data.CHESTEREVERYONE.eyebone[i]
					data.CHESTEREVERYONE[i].chester = data.CHESTEREVERYONE.chester[i]
				end
				data.CHESTEREVERYONE.eyebone = nil
				data.CHESTEREVERYONE.chester = nil
			end

			for i, v in ipairs(data.CHESTEREVERYONE) do
				inst.CHESTEREVERYONE[i] = {}

				if (data.CHESTEREVERYONE[i].shardId == nil and data.CHESTEREVERYONE[i].canMigrate == nil and TheWorld:HasTag("forest"))
					or (data.CHESTEREVERYONE[i].shardId == TheShard:GetShardId() or data.CHESTEREVERYONE[i].canMigrate == true) then
					--conditions for entering this code:
					--the save data is from a old version of this mod, so we do the best we can.
					--chester was saved on this shard previously
					--eyebone was in the inventory when migration happened so we possibly migrate

					--spawn Eyebone
					inst.CHESTEREVERYONE[i].eyebone = SpawnSaveRecord(data.CHESTEREVERYONE[i].eyebone)
					inst.CHESTEREVERYONE[i].eyebone.CHESTEREVERYONE.owner = inst
					inst.CHESTEREVERYONE[i].eyebone.CHESTEREVERYONE.eyenum = i
					inst.CHESTEREVERYONE[i].eyebone.persists = false
					inst.CHESTEREVERYONE[i].eyebone.CHESTEREVERYONE.ownership = TUNING.FOLLOWEREVERYONE.OWNERSHIP

					--spawn Chester
                    if data.CHESTEREVERYONE[i].chester ~= nil then
    					inst.CHESTEREVERYONE[i].chester = SpawnSaveRecord(data.CHESTEREVERYONE[i].chester)
    					inst.CHESTEREVERYONE[i].chester:AddTag("claimed_chester")
    					inst.CHESTEREVERYONE[i].chester.persists = false
                    end
				
					-- Look for eyebone at spawn point and re-equip
					inst:DoTaskInTime(0, function(inst, i, migrating)
						--if we are migrating, we need to actualy change the spawn positions of the eyebone
						if migrating then
	        				inst.CHESTEREVERYONE[i].eyebone.Transform:SetPosition(inst.Transform:GetWorldPosition())
						end

						if inst.CHESTEREVERYONE[i].eyebone and inst:IsNear(inst.CHESTEREVERYONE[i].eyebone, 4) then
							--inst.components.inventory:GiveItem(inst.eyebone)
							inst:ReturnEyebone(i)
						end
					end, i, data.CHESTEREVERYONE[i].shardId ~= TheShard:GetShardId() and data.CHESTEREVERYONE[i].canMigrate)
				else
					inst.CHESTEREVERYONE[i].eyebone = v.eyebone
					inst.CHESTEREVERYONE[i].chester = v.chester
					inst.CHESTEREVERYONE[i].shardId = v.shardId
					if v.canMigrate ~= nil then v.canMigrate = false end
					inst.CHESTEREVERYONE[i].canMigrate = v.canMigrate
				end
			end
		end

		if (#inst.CHESTEREVERYONE or 0) < TUNING.FOLLOWEREVERYONE.CHESTER.MAX then
			inst.components.builder.eyebone_bonus = TUNING.FOLLOWEREVERYONE.CHESTER.TECHLVL
		else
			inst.components.builder.eyebone_bonus = 0
		end
	end or function(inst, data) 
		--pass through the data but dont spawn the eyebones or chesters
		inst.CHESTEREVERYONE = data.CHESTEREVERYONE or {}
		for i, v in ipairs(inst.CHESTEREVERYONE) do
			if v.canMigrate ~= nil then v.canMigrate = false end
		end
		--also VERY important dont allow the player to craft eyebones on invalid shards as they would disapear on traveling to another shard
		inst.components.builder.eyebone_bonus = 0
	end

	inst.ReturnEyebone = function(inst,i)
		if inst.CHESTEREVERYONE[i].eyebone and inst.CHESTEREVERYONE[i].eyebone:IsValid() then
			if inst.CHESTEREVERYONE[i].eyebone.components.inventoryitem:GetGrandOwner() ~= inst then
				inst.components.inventory:GiveItem(inst.CHESTEREVERYONE[i].eyebone)
			end
		end
		if inst.CHESTEREVERYONE[i].chester and not inst:IsNear(inst.CHESTEREVERYONE[i].chester, 20) then
			local pt = inst:GetPosition()
			local spawn_pt = inst.CHESTEREVERYONE[i].eyebone.CHESTEREVERYONE.GetSpawnPoint(pt)
			if spawn_pt ~= nil then
				inst.CHESTEREVERYONE[i].chester.Physics:Teleport(spawn_pt:Get())
				inst.CHESTEREVERYONE[i].chester:FacePoint(pt:Get())
			end
		end
	end

	local function OnDeathChester(inst, data)
		-- Kill player's chester in wilderness mode :(
		for i, v in ipairs(inst.CHESTEREVERYONE) do
			if v.eyebone.components then
				v.eyebone:Remove()
				v.chester.components.health:Kill()
			--if your in wilderness mode and you dont enter the proper shard before dying, chesters on the "old save format" will just disapear
			elseif v.shardId ~= nil and v.canMigrate ~= nil then
				SendShardRPC(SHARD_RPC.FOLLOWERSFORALL.SpawnAndKillFollower, tonumber(v.shardId), v.chester)
			end
		end		
	end
------------------------------------------------------------------------------------------
--                                   Chester End                                        --
------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------
--                                   Hutch Start                                        --
------------------------------------------------------------------------------------------
	local OnNewSpawnHutch = hutch and IsValidWorld("HUTCH") and function(inst)
		inst.HUTCHEVERYONE = {}
		inst.components.builder.starsky_bonus = TUNING.FOLLOWEREVERYONE.HUTCH.TECHLVL
	end or function() end

	local OnDespawnHutch = hutch and IsValidWorld("HUTCH") and function(inst)
		for i, v in ipairs(inst.HUTCHEVERYONE) do
			if v.starsky.components then
				-- Starsky drops from whatever its in
				local owner = v.starsky.components.inventoryitem:GetGrandOwner()
				v.canMigrate = owner == inst
				if owner then
					--drop items from containers/inv's
					if owner.components.container then
						owner.components.container:DropItem(v.starsky)
					elseif owner.components.inventory then
						owner.components.inventory:DropItem(v.starsky)
					end
		 		end
					
				-- We need time to save before despawning.
				v.starsky:DoTaskInTime(0.1, function(starsky)
					if starsky and starsky:IsValid() then
						starsky:Remove()
					end
				end)

                if v.hutch then
                    -- Don't allow hutch to despawn with irreplaceable items
                    v.hutch.components.container:DropEverythingWithTag("irreplaceable")
    				v.hutch:DoTaskInTime(0.1, function(hutch)
    					if hutch and hutch:IsValid() then
    						hutch:Remove()
    					end
    				end)
                end
			end
		end
	end or function() end

	local OnSaveHutch = hutch and IsValidWorld("HUTCH") and function(inst, data)
		data.HUTCHEVERYONE = {}

		for i, v in ipairs(inst.HUTCHEVERYONE) do
			data.HUTCHEVERYONE[i] = {}
			--Save Hutch and Starsky
			if v.starsky.components then
				--Hutch and Starsky are alive in the world so save the data
				data.HUTCHEVERYONE[i].canMigrate = v.canMigrate
				data.HUTCHEVERYONE[i].starsky = v.starsky:GetSaveRecord()
				data.HUTCHEVERYONE[i].shardId = TheShard:GetShardId()
                if v.hutch then
                    data.HUTCHEVERYONE[i].hutch = v.hutch:GetSaveRecord()
                end
			else
				--Hutch and Starsky aren't alive in the world so pass through the data
				data.HUTCHEVERYONE[i].starsky = v.starsky
				data.HUTCHEVERYONE[i].hutch = v.hutch
				data.HUTCHEVERYONE[i].shardId = v.shardId
				data.HUTCHEVERYONE[i].canMigrate = v.canMigrate
			end
		end
	end or function(inst, data) 
		--pass through the data but dont do anything else
		data.HUTCHEVERYONE = inst.HUTCHEVERYONE or {}
	end

	local OnLoadHutch = hutch and IsValidWorld("HUTCH") and function(inst, data)
		inst.HUTCHEVERYONE = {}
		if data.HUTCHEVERYONE then

			--migrating to a new save format...
			if data.HUTCHEVERYONE.hutch ~= nil and data.HUTCHEVERYONE.starsky ~= nil then
				for i, v in ipairs(data.HUTCHEVERYONE.starsky) do
					data.HUTCHEVERYONE[i] = {}
					data.HUTCHEVERYONE[i].starsky = data.HUTCHEVERYONE.starsky[i]
					data.HUTCHEVERYONE[i].hutch = data.HUTCHEVERYONE.hutch[i]
				end
				data.HUTCHEVERYONE.starsky = nil
				data.HUTCHEVERYONE.hutch = nil
			end

			for i, v in ipairs(data.HUTCHEVERYONE) do
				inst.HUTCHEVERYONE[i] = {}

				if (data.HUTCHEVERYONE[i].shardId == nil and data.HUTCHEVERYONE[i].canMigrate == nil and TheWorld:HasTag("cave"))
					or (data.HUTCHEVERYONE[i].shardId == TheShard:GetShardId() or data.HUTCHEVERYONE[i].canMigrate) then
					--conditions for entering this code:
					--the save data is from a old version of this mod, so we do the best we can.
					--hutch was saved on this shard previously
					--starsky was in the inventory when migration happened so we possibly migrate

					--spawn Starsky
					inst.HUTCHEVERYONE[i].starsky = SpawnSaveRecord(data.HUTCHEVERYONE[i].starsky)
					inst.HUTCHEVERYONE[i].starsky.HUTCHEVERYONE.owner = inst
					inst.HUTCHEVERYONE[i].starsky.HUTCHEVERYONE.starnum = i
					inst.HUTCHEVERYONE[i].starsky.persists = false
					inst.HUTCHEVERYONE[i].starsky.HUTCHEVERYONE.ownership = TUNING.FOLLOWEREVERYONE.OWNERSHIP

					--spawn Hutch
                    if data.HUTCHEVERYONE[i].hutch ~= nil then
                        inst.HUTCHEVERYONE[i].hutch = SpawnSaveRecord(data.HUTCHEVERYONE[i].hutch)
                        inst.HUTCHEVERYONE[i].hutch:AddTag("claimed_hutch")
                        inst.HUTCHEVERYONE[i].hutch.persists = false
                    end
				
					-- Look for starsky at spawn point and re-equip
					inst:DoTaskInTime(0, function(inst, i, migrating)
						--if we are migrating, we need to actualy change the spawn positions of the starsky
						if migrating then
	        				inst.HUTCHEVERYONE[i].starsky.Transform:SetPosition(inst.Transform:GetWorldPosition())
						end
						
						if inst.HUTCHEVERYONE[i].starsky and inst:IsNear(inst.HUTCHEVERYONE[i].starsky, 4) then
							--inst.components.inventory:GiveItem(inst.starsky)
							inst:ReturnStarsky(i)
						end
					end, i, data.HUTCHEVERYONE[i].shardId ~= TheShard:GetShardId() and data.HUTCHEVERYONE[i].canMigrate)

				else
					inst.HUTCHEVERYONE[i].starsky = v.starsky
					inst.HUTCHEVERYONE[i].hutch = v.hutch
					inst.HUTCHEVERYONE[i].shardId = v.shardId
					if v.canMigrate ~= nil then v.canMigrate = false end
					inst.HUTCHEVERYONE[i].canMigrate = v.canMigrate
				end
			end
		end

		if (#inst.HUTCHEVERYONE or 0) < TUNING.FOLLOWEREVERYONE.HUTCH.MAX then
			inst.components.builder.starsky_bonus = TUNING.FOLLOWEREVERYONE.HUTCH.TECHLVL
		else
			inst.components.builder.starsky_bonus = 0
		end
	end or function(inst, data) 
		--pass through the data but dont spawn the starskys or hutchs
		inst.HUTCHEVERYONE = data.HUTCHEVERYONE or {}
		for i, v in ipairs(inst.HUTCHEVERYONE) do
			if v.canMigrate ~= nil then v.canMigrate = false end
		end
		--also VERY important dont allow the player to craft starskys on invalid shards as they would disapear on traveling to another shard
		inst.components.builder.starsky_bonus = 0
	end

	inst.ReturnStarsky = function(inst,i)
		if inst.HUTCHEVERYONE[i].starsky and inst.HUTCHEVERYONE[i].starsky:IsValid() then
			if inst.HUTCHEVERYONE[i].starsky.components.inventoryitem:GetGrandOwner() ~= inst then
				inst.components.inventory:GiveItem(inst.HUTCHEVERYONE[i].starsky)
			end
		end
		if inst.HUTCHEVERYONE[i].hutch and not inst:IsNear(inst.HUTCHEVERYONE[i].hutch, 20) then
			local pt = inst:GetPosition()
			local spawn_pt = inst.HUTCHEVERYONE[i].starsky.HUTCHEVERYONE.GetSpawnPoint(pt)
			if spawn_pt ~= nil then
				inst.HUTCHEVERYONE[i].hutch.Physics:Teleport(spawn_pt:Get())
				inst.HUTCHEVERYONE[i].hutch:FacePoint(pt:Get())
			end
		end
	end

	local function OnDeathHutch(inst, data)
		-- Kill player's hutch in wilderness mode :(
		for i, v in ipairs(inst.HUTCHEVERYONE) do
			if v.starsky.components then
				v.starsky:Remove()
				v.hutch.components.health:Kill()
			--if your in wilderness mode and you dont enter the proper shard before dying, hutches on the "old save format" will just disapear
			elseif v.shardId ~= nil and v.canMigrate ~= nil then
				SendShardRPC(SHARD_RPC.FOLLOWERSFORALL.SpawnAndKillFollower, tonumber(v.shardId), v.hutch)
			end
		end	
	end
------------------------------------------------------------------------------------------
--                                    Hutch End                                         --
------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------
--                                   Packim Start                                       --
------------------------------------------------------------------------------------------
	local OnNewSpawnPackim = packim and IsValidWorld("PACKIM") and function(inst)
		inst.PACKIMEVERYONE = {}
		inst.components.builder.fishbone_bonus = TUNING.FOLLOWEREVERYONE.PACKIM.FISHBONELEVEL
	end or function() end

    local OnDespawnPackim = packim and IsValidWorld("PACKIM") and function(inst)
        for i, v in ipairs(inst.PACKIMEVERYONE) do
            if v.fishbone.components then
                -- Fishbone drops from whatever its in
                local owner = v.fishbone.components.inventoryitem:GetGrandOwner()
                v.canMigrate = owner == inst
                if owner then
                    --drop items from containers/inv's
                    if owner.components.container then
                        owner.components.container:DropItem(v.fishbone)
                    elseif owner.components.inventory then
                        owner.components.inventory:DropItem(v.fishbone)
                    end
                end

                -- We need time to save before despawning.
                v.fishbone:DoTaskInTime(0.1, function(fishbone)
                    if fishbone and fishbone:IsValid() then
                        fishbone:Remove()
                    end
                end)
                    
                if v.packim then
                    -- Don't allow packim to despawn with irreplaceable items
                    v.packim.components.container:DropEverythingWithTag("irreplaceable")
                    v.packim:DoTaskInTime(0.1, function(packim)
                        if packim and packim:IsValid() then
                            packim:Remove()
                        end
                    end)
                end
            end
        end
    end or function() end

    local OnSavePackim = packim and IsValidWorld("PACKIM") and function(inst, data)
        data.PACKIMEVERYONE = {}

        for i, v in ipairs(inst.PACKIMEVERYONE) do
            data.PACKIMEVERYONE[i] = {}
            --Save Packim and Fishbone
            if v.fishbone.components then
                --Packim and Fishbone are alive in the world so save the data
                data.PACKIMEVERYONE[i].canMigrate = v.canMigrate
                data.PACKIMEVERYONE[i].fishbone = v.fishbone:GetSaveRecord()
                data.PACKIMEVERYONE[i].shardId = TheShard:GetShardId()
                if v.packim then
                    data.PACKIMEVERYONE[i].packim = v.packim:GetSaveRecord()
                end
            else
                --Packim and Fishbone aren't alive in the world so pass through the data
                data.PACKIMEVERYONE[i].fishbone = v.fishbone
                data.PACKIMEVERYONE[i].packim = v.packim
                data.PACKIMEVERYONE[i].shardId = v.shardId
                data.PACKIMEVERYONE[i].canMigrate = v.canMigrate
            end
        end
    end or function(inst, data) 
        --pass through the data but dont do anything else
        data.PACKIMEVERYONE = inst.PACKIMEVERYONE or {}
    end

	local OnLoadPackim = packim and IsValidWorld("PACKIM") and function(inst, data)
        inst.PACKIMEVERYONE = {}
        if data.PACKIMEVERYONE then

            --migrating to a new save format...
            if data.PACKIMEVERYONE.packim ~= nil and data.PACKIMEVERYONE.fishbone ~= nil then
                for i, v in ipairs(data.PACKIMEVERYONE.fishbone) do
                    data.PACKIMEVERYONE[i] = {}
                    data.PACKIMEVERYONE[i].fishbone = data.PACKIMEVERYONE.fishbone[i]
                    data.PACKIMEVERYONE[i].packim = data.PACKIMEVERYONE.packim[i]
                end
                data.PACKIMEVERYONE.fishbone = nil
                data.PACKIMEVERYONE.packim = nil
            end

            for i, v in ipairs(data.PACKIMEVERYONE) do
                inst.PACKIMEVERYONE[i] = {}

                if (data.PACKIMEVERYONE[i].shardId == nil and data.PACKIMEVERYONE[i].canMigrate == nil and TheWorld:HasTag("cave"))
                    or (data.PACKIMEVERYONE[i].shardId == TheShard:GetShardId() or data.PACKIMEVERYONE[i].canMigrate) then
                    --conditions for entering this code:
                    --the save data is from a old version of this mod, so we do the best we can.
                    --packim was saved on this shard previously
                    --fishbone was in the inventory when migration happened so we possibly migrate

                    --spawn Fishbone
                    inst.PACKIMEVERYONE[i].fishbone = SpawnSaveRecord(data.PACKIMEVERYONE[i].fishbone)
                    inst.PACKIMEVERYONE[i].fishbone.PACKIMEVERYONE.owner = inst
                    inst.PACKIMEVERYONE[i].fishbone.PACKIMEVERYONE.fishnum = i
                    inst.PACKIMEVERYONE[i].fishbone.persists = false
                    inst.PACKIMEVERYONE[i].fishbone.PACKIMEVERYONE.ownership = TUNING.FOLLOWEREVERYONE.OWNERSHIP

                    --spawn Packim
                    if data.PACKIMEVERYONE[i].packim ~= nil then
                        inst.PACKIMEVERYONE[i].packim = SpawnSaveRecord(data.PACKIMEVERYONE[i].packim)
                        inst.PACKIMEVERYONE[i].packim:AddTag("claimed_packim")
                        inst.PACKIMEVERYONE[i].packim.persists = false
                    end
                
                    -- Look for fishbone at spawn point and re-equip
                    inst:DoTaskInTime(0, function(inst, i, migrating)
                        --if we are migrating, we need to actualy change the spawn positions of the fishbone
                        if migrating then
                            inst.PACKIMEVERYONE[i].fishbone.Transform:SetPosition(inst.Transform:GetWorldPosition())
                        end
                        
                        if inst.PACKIMEVERYONE[i].fishbone and inst:IsNear(inst.PACKIMEVERYONE[i].fishbone, 4) then
                            --inst.components.inventory:GiveItem(inst.fishbone)
                            inst:ReturnFishbone(i)
                        end
                    end, i, data.PACKIMEVERYONE[i].shardId ~= TheShard:GetShardId() and data.PACKIMEVERYONE[i].canMigrate)

                else
                    inst.PACKIMEVERYONE[i].fishbone = v.fishbone
                    inst.PACKIMEVERYONE[i].packim = v.packim
                    inst.PACKIMEVERYONE[i].shardId = v.shardId
                    if v.canMigrate ~= nil then v.canMigrate = false end
                    inst.PACKIMEVERYONE[i].canMigrate = v.canMigrate
                end
            end
        end

        if (#inst.PACKIMEVERYONE or 0) < TUNING.FOLLOWEREVERYONE.PACKIM.MAX then
            inst.components.builder.fishbone_bonus = TUNING.FOLLOWEREVERYONE.PACKIM.TECHLVL
        else
            inst.components.builder.fishbone_bonus = 0
        end
	end or function(inst, data) 
		--pass through the data but dont spawn the fishbones or packims
		inst.PACKIMEVERYONE = data.PACKIMEVERYONE or {}
        for i, v in ipairs(inst.PACKIMEVERYONE) do
            if v.canMigrate ~= nil then v.canMigrate = false end
        end
		--also VERY important dont allow the player to craft fishbones on invalid shards as they would disapear on traveling to another shard
		inst.components.builder.fishbone_bonus = 0
	end

	inst.ReturnFishbone = function(inst,i)
		if inst.PACKIMEVERYONE[i].fishbone and inst.PACKIMEVERYONE[i].fishbone:IsValid() then
			if inst.PACKIMEVERYONE[i].fishbone.components.inventoryitem:GetGrandOwner() ~= inst then
				inst.components.inventory:GiveItem(inst.PACKIMEVERYONE[i].fishbone)
			end
		end
		if inst.PACKIMEVERYONE[i].packim and not inst:IsNear(inst.PACKIMEVERYONE[i].packim, 20) then
			local pt = inst:GetPosition()
			local spawn_pt = inst.PACKIMEVERYONE[i].fishbone.PACKIMEVERYONE.GetSpawnPoint(pt)
			if spawn_pt ~= nil then
				inst.PACKIMEVERYONE[i].packim.Physics:Teleport(spawn_pt:Get())
				inst.PACKIMEVERYONE[i].packim:FacePoint(pt:Get())
			end
		end
	end

	local function OnDeathPackim(inst, data)
		-- Kill player's packim in wilderness mode :(
		for i, v in ipairs(inst.PACKIMEVERYONE) do
			if v.fishbone.components then
				v.fishbone:Remove()
				v.packim.components.health:Kill()
			--if your in wilderness mode and you dont enter the proper shard before dying, packimes on the "old save format" will just disapear
			elseif v.shardId ~= nil and v.canMigrate ~= nil then
				SendShardRPC(SHARD_RPC.FOLLOWERSFORALL.SpawnAndKillFollower, tonumber(v.shardId), v.packim)
			end
		end	
	end
------------------------------------------------------------------------------------------
--                                    Packim End                                        --
------------------------------------------------------------------------------------------
	local old_OnNewSpawn = inst.OnNewSpawn
	function inst.OnNewSpawn(inst)
		OnNewSpawnChester(inst)
		OnNewSpawnHutch(inst)
		OnNewSpawnPackim(inst)
		if old_OnNewSpawn then
			return old_OnNewSpawn(inst)
		end
	end

	local old_OnDespawn = inst.OnDespawn
	function inst.OnDespawn(inst)
		OnDespawnChester(inst)
		OnDespawnHutch(inst)
		OnDespawnPackim(inst)
		return old_OnDespawn(inst)
	end
    
    local old_OnSave = inst.OnSave
    function inst.OnSave(inst, data)
        OnSaveChester(inst, data)
        OnSaveHutch(inst, data)
        OnSavePackim(inst, data)
        local references = old_OnSave(inst, data)
        return references
    end
    
    local old_OnLoad = inst.OnLoad
    function inst.OnLoad(inst, data)
        OnLoadChester(inst, data)
        OnLoadHutch(inst, data)
        OnLoadPackim(inst, data)
        return old_OnLoad(inst, data)
    end
    
    local old_SaveForReroll = inst.SaveForReroll
    function inst.SaveForReroll(inst)
        local data = old_SaveForReroll ~= nil and old_SaveForReroll(inst) or {}
        OnSaveChester(inst, data)
        OnSaveHutch(inst, data)
        OnSavePackim(inst, data)
        return next(data) ~= nil and data or nil
    end
    
    local old_LoadForReroll = inst.LoadForReroll
    function inst.LoadForReroll(inst, data)
        if old_LoadForReroll ~= nil then
            old_LoadForReroll(inst, data)
        end
        OnLoadChester(inst, data)
        OnLoadHutch(inst, data)
        OnLoadPackim(inst, data)
    end

	if TheNet:GetServerGameMode() == "wilderness" then
		local function OnDeath(inst, data)
			OnDeathChester(inst, data)
			OnDeathHutch(inst, data)
			OnDeathPackim(inst, data)
		end
		inst:ListenForEvent("death", OnDeath)
	end
end
GLOBAL.setfenv(PlayerPost, GLOBAL)
AddPlayerPostInit(PlayerPost)