function Egg:GetMaturityRate()
	return kEggMaturationTime
end

function Egg:GetMatureMaxHealth()
	return kMatureEggHealth
end

function Egg:GetMatureMaxArmor()
	return kMatureEggArmor
end

if Server then

	local function GestatePlayer(self, player, fromTechId)

   		player.oneHive = false
	    player.twoHives = false
	    player.threeHives = false

	    -- local playerHealthScalar = player:GetHealthScalar()
	    -- local playerArmorScalar = player:GetArmorScalar()
	    local newPlayer = player:Replace(Embryo.kMapName)
	    if not newPlayer:IsAnimated() then
	        newPlayer:SetDesiredCamera(1.1, { follow = true, tweening = kTweeningFunctions.easeout7 })
	    end
	    newPlayer:SetCameraDistance(kGestateCameraDistance)
	    
	    -- Eliminate velocity so that we don't slide or jump as an egg
	    newPlayer:SetVelocity(Vector(0, 0, 0))
	    
	    newPlayer:DropToFloor()
	    
	    local techIds = { self:GetGestateTechId() }
	    -- newPlayer:SetGestationData(techIds, fromTechId, playerHealthScalar, playerArmorScalar)
	    newPlayer:SetGestationData(techIds, fromTechId, 1, 1)

	end

	ReplaceLocals(Egg.OnUse, {GestatePlayer = GestatePlayer})
end