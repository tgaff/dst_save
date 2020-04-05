function dstPerishable(component)

	component.newUpdate = function (inst, dt)
		if inst.components.perishable then

			local modifier = 1
			local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner or nil
			if not owner and inst.components.occupier then
				owner = inst.components.occupier:GetOwner()
			end

			if owner then
				if owner:HasTag("fridge") then
					if inst:HasTag("frozen") and not owner:HasTag("nocool") and not owner:HasTag("lowcool") then
						modifier = TUNING.PERISH_COLD_FROZEN_MULT
					else
						modifier = TUNING.PERISH_FRIDGE_MULT
					end
----------------------------------
				elseif owner:HasTag("icestoreroom") then
					if inst:HasTag("frozen") and not owner:HasTag("nocool") and not owner:HasTag("lowcool") then
						modifier = TUNING.PERISH_COLD_FROZEN_MULT
					else
						modifier = TUNING.PERISH_STOREROOM_MULT
					end
----------------------------------
				elseif owner:HasTag("spoiler") then
					modifier = TUNING.PERISH_GROUND_MULT
				elseif owner:HasTag("cage") and inst:HasTag("small_livestock") then
					modifier = TUNING.PERISH_CAGE_MULT
				end
			else
				modifier = TUNING.PERISH_GROUND_MULT
			end

			if inst:GetIsWet() then
				modifier = modifier * TUNING.PERISH_WET_MULT
			end

			if _G.TheWorld.state.temperature < 0 then
				if inst:HasTag("frozen") and not inst.components.perishable.frozenfiremult then
					modifier = TUNING.PERISH_COLD_FROZEN_MULT
				else
					modifier = modifier * TUNING.PERISH_WINTER_MULT
				end
			end

			if inst.components.perishable.frozenfiremult then
				modifier = modifier * TUNING.PERISH_FROZEN_FIRE_MULT
			end

			if _G.TheWorld.state.temperature > TUNING.OVERHEAT_TEMP then
				modifier = modifier * TUNING.PERISH_SUMMER_MULT
			end

			if inst and inst.components.perishable and inst.components.perishable.localPerishMultiplyer then
				modifier = modifier * inst.components.perishable.localPerishMultiplyer * TUNING.PERISH_GLOBAL_MULT
			else
				modifier = modifier * 1 * TUNING.PERISH_GLOBAL_MULT
				print("WARNING! Something went wrong with localPerishMultiplyer.")
			end

			local old_val = inst.components.perishable.perishremainingtime
			local delta = dt or (10 + math.random()*_G.FRAMES*8)
			if inst.components.perishable.perishremainingtime then
				inst.components.perishable.perishremainingtime = inst.components.perishable.perishremainingtime - delta*modifier
				if math.floor(old_val*100) ~= math.floor(inst.components.perishable.perishremainingtime*100) then
					inst:PushEvent("perishchange", {percent = inst.components.perishable:GetPercent()})
				end
			end

			-- Cool off hot foods over time (faster if in a fridge)
			if inst.components.edible and inst.components.edible.temperaturedelta and inst.components.edible.temperaturedelta > 0 then
				if owner and owner:HasTag("fridge") then
					if not owner:HasTag("nocool") then
						inst.components.edible.temperatureduration = inst.components.edible.temperatureduration - 1
					end
----------------------------------
				elseif owner and owner:HasTag("icestoreroom") then
					if not owner:HasTag("nocool") then
						inst.components.edible.temperatureduration = inst.components.edible.temperatureduration - _G.TUNING.PERISH_STOREROOM_MULT
					end
----------------------------------
				elseif _G.TheWorld.state.temperature < TUNING.OVERHEAT_TEMP - 5 then
					inst.components.edible.temperatureduration = inst.components.edible.temperatureduration - .25
				end
				if inst.components.edible.temperatureduration < 0 then inst.components.edible.temperatureduration = 0 end
			end

			--trigger the next callback
			if inst.components.perishable.perishremainingtime and inst.components.perishable.perishremainingtime <= 0 then
				inst.components.perishable:Perish()
			end
		end

		--print("Perishable:Update is working")
	end

	component.LongUpdate = function(self, dt)
		if self.updatetask ~= nil then
			component.newUpdate(self.inst, dt or 0)

			--print("Perishable:LongUpdate is working")
		end
	end

	component.StartPerishing = function(self)
		if self.updatetask ~= nil then
			self.updatetask:Cancel()
			self.updatetask = nil
		end

		local dt = 10 + math.random()*_G.FRAMES*8
		self.updatetask = self.inst:DoPeriodicTask(dt, component.newUpdate, math.random()*2, dt)

		--print("Perishable:StartPerishing is working")
	end
end

AddComponentPostInit("perishable", dstPerishable)