require "prefabutil"

local assets =
{
	Asset("ANIM", "anim/rabbit_cage.zip"),
	Asset("ATLAS", "images/inventoryimages/rabbit_cage.xml"),
	Asset("ATLAS", "minimap/rabbit_cage.xml" ),
}

local prefabs = 
{
	"rabbit",
	"rabbit_bomb",
	"beardhair",
}

local function ShouldAcceptItem(inst, item)
	local can_accept = item.prefab == "gunpowder"
 	or item.prefab == "monstermeat"
	return can_accept
end

local function OnGetItemFromPlayer(inst, giver, item)
	local can_accept = item.prefab == "gunpowder"
	or item.prefab == "monstermeat"
	if can_accept then if item.prefab == "gunpowder"
  	then inst.components.lootdropper:SpawnLootPrefab("rabbit_bomb")
end
	if can_accept then if item.prefab == "monstermeat" 
  	then inst.components.lootdropper:SpawnLootPrefab("beardhair")
    		end
		end
	end
end

local levels = 
{
		{ amount=3, idle="idle_3",true, hit="hit_idle_3",true },
		{ amount=2, idle="idle_2",true, hit="hit_idle_2",true },
		{ amount=1, idle="idle_1",true, hit="hit_idle_1",true },
		{ amount=0, idle="idle",true, hit="hit_idle",true },
}

local function setlevel(inst, level)
    if not inst:HasTag("burnt") then
    if inst.anims == nil then
    inst.anims = { idle = level.idle, hit = level.hit }
    else
    inst.anims.idle = level.idle
    inst.anims.hit = level.hit
end
    inst.AnimState:PlayAnimation(inst.anims.idle,true)
    end
end

local function updatelevel(inst)
    if not inst:HasTag("burnt") 
    then
    for k, v in pairs(levels) do
    if inst.components.harvestable.produce >= v.amount then
    setlevel(inst, v)
                break
            end
        end
    end
end

local function onharvest(inst)
    inst.SoundEmitter:PlaySound("dontstarve/rabbit/scream")
	updatelevel(inst)
end

local function onhammered(inst, worker)
	if inst.components.harvestable:CanBeHarvested() then
    inst.components.lootdropper:SpawnLootPrefab("rabbit")
end
	inst.components.lootdropper:DropLoot()
	inst:Remove()
end

local function onhit(inst, worker)
end

local function onbuilt(inst)
	inst.AnimState:PlayAnimation("idle")
	inst.SoundEmitter:PlaySound("dontstarve/common/birdcage_craft")
	inst.components.harvestable:StartGrowing()
	updatelevel(inst)
end

local function OnLoad(inst, data)
	inst.components.harvestable:StartGrowing()
	updatelevel(inst)
end

local function GetStatus(inst)
    return inst.components.harvestable ~= nil
    and 
(   
	(inst.components.harvestable.produce >= inst.components.harvestable.maxproduce and "READY") 
	or
    inst.components.harvestable:CanBeHarvested()

)
    or nil
end

local function fn(Sim)
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

	inst.entity:AddMiniMapEntity()
    inst.MiniMapEntity:SetIcon("rabbit_cage.tex")

	inst.AnimState:SetBank("rabbit_cage")
	inst.AnimState:SetBuild("rabbit_cage")
	inst.AnimState:PlayAnimation("idle")
	inst.Transform:SetScale(1.5,1.5,1.5)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:AddTag("trader")	
	inst:AddTag("alltrader")

	inst:AddComponent("harvestable")
	inst.components.harvestable:SetUp("rabbit", TUNING.RABBIT_AMOUNT, TUNING.RABBIT_TIME, onharvest, updatelevel)
	inst.components.harvestable:StartGrowing()

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus
    
	inst:AddComponent("lootdropper")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(2)
	inst.components.workable:SetOnFinishCallback(onhammered)
	
	inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
	inst.components.trader.onaccept = OnGetItemFromPlayer
	inst.components.trader:Enable()

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = TUNING.SANITYAURA_SMALL	

	updatelevel(inst)

	inst:ListenForEvent( "onbuilt", onbuilt)
	inst:ListenForEvent( "onharvest", updatelevel)		
		
	inst.OnLoad = OnLoad

 	return inst
end

return Prefab( "common/rabbit_cage", fn, assets),
MakePlacer("common/rabbit_cage_placer", "rabbit_cage", "rabbit_cage", "idle")
