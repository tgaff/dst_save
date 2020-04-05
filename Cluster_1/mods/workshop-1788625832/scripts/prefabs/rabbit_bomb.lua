local assets=
{
	Asset("ANIM", "anim/rabbit_bomb.zip"),
	Asset("ANIM", "anim/swap_rabbit_bomb.zip"),
  	Asset("ATLAS", "images/inventoryimages/rabbit_bomb.xml"),
  	Asset("IMAGE", "images/inventoryimages/rabbit_bomb.tex"),
}

local function onhit(inst, attacker, target)
	SpawnPrefab("collapse_small").Transform:SetPosition(target.Transform:GetWorldPosition())
	SpawnPrefab("explode_small").Transform:SetPosition(target.Transform:GetWorldPosition())
	TheWorld:PushEvent("screenflash", 0.5)
	for i, v in ipairs(AllPlayers) do
	v:ShakeCamera(CAMERASHAKE.FULL, 0.7, 0.02, 0.5, inst, 40)
end
	inst.components.combat:DoAreaAttack(target, 8)
	inst:Remove()
end

local function onthrown(inst, data)
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
end

local function fn(inst)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

	inst.AnimState:SetBank("rabbit_bomb")
	inst.AnimState:SetBuild("rabbit_bomb")
	inst.AnimState:PlayAnimation("idle")
	inst.Transform:SetScale(1.5,2,1.5)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	MakeInventoryPhysics(inst)

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/rabbit_bomb.xml"

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

	inst:AddComponent("inspectable")

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(300)
	inst.components.weapon:SetRange(13, 13)

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(200)
	inst.components.combat.playerdamagepercent = 0

	inst:AddComponent("equippable")
	inst.components.equippable.equipstack = true

	inst:AddComponent("projectile")
	inst.components.projectile:SetSpeed(30)
	inst.components.projectile:SetOnHitFn(onhit)

	inst:ListenForEvent("onthrown", onthrown)

	inst:AddComponent("selfstacker")

	return inst
end	
return Prefab("common/inventory/rabbit_bomb", fn, assets)

