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

function Egg:SpawnPlayer(player)

    PROFILE("Egg:SpawnPlayer")

    local queuedPlayer = player
    
    if not queuedPlayer or self.queuedPlayerId ~= nil then
        queuedPlayer = Shared.GetEntity(self.queuedPlayerId)
    end
    
    if queuedPlayer ~= nil then
    
        local queuedPlayer = player
        if not queuedPlayer then
            queuedPlayer = Shared.GetEntity(self.queuedPlayerId)
        end
    
        -- Spawn player on top of egg
        local spawnOrigin = Vector(self:GetOrigin())
        -- Move down to the ground.
        local _, normal = GetSurfaceAndNormalUnderEntity(self)
        if normal.y < 1 then
            spawnOrigin.y = spawnOrigin.y - (self:GetExtents().y / 2) + 1
        else
            spawnOrigin.y = spawnOrigin.y - (self:GetExtents().y / 2)
        end

        local gestationClass = self:GetClassToGestate()
        
        -- We must clear out queuedPlayerId BEFORE calling ReplaceRespawnPlayer
        -- as this will trigger OnEntityChange() which would requeue this player.
        self.queuedPlayerId = nil
        
        local team = queuedPlayer:GetTeam()
        local success, player = team:ReplaceRespawnPlayer(queuedPlayer, spawnOrigin, queuedPlayer:GetAngles(), gestationClass)                
        player:SetCameraDistance(0)
        player:SetHatched()
        -- It is important that the player was spawned at the spot we specified.
        assert(player:GetOrigin() == spawnOrigin)
        
        if success then
            -- self:PickUpgrades(player)

            self:TriggerEffects("egg_death")
            DestroyEntity(self) 
            
            return true, player
            
        end
            
    end
    
    return false, nil

end