Script.Load("lua/AlienUpgradeManager.lua")

function Alien:UpdateSilenceLevel()

    if GetHasSilenceUpgrade(self) then
        self.silenceLevel = GetVeilLevel(self:GetTeamNumber())
    else
        self.silenceLevel = 0
    end

end

function Alien:UpdateAutoHeal()

    PROFILE("Alien:UpdateAutoHeal")

    if self:GetIsHealable() and ( not self.timeLastAlienAutoHeal or self.timeLastAlienAutoHeal + kAlienRegenerationTime <= Shared.GetTime() ) then

        local healRate = 1
        local hasRegenUpgrade = GetHasRegenerationUpgrade(self)
        local shellLevel = GetShellLevel(self:GetTeamNumber())
        local maxHealth = self:GetBaseHealth()
        
        if hasRegenUpgrade and shellLevel > 0 then
            healRate = Clamp(kAlienRegenerationPercentage * maxHealth, kAlienMinRegeneration, kAlienMaxRegeneration) * (shellLevel/3)
        else
            healRate = Clamp(kAlienInnateRegenerationPercentage * maxHealth, kAlienMinInnateRegeneration, kAlienMaxInnateRegeneration) 
        end
        
        if self:GetTimeLastDamageTaken() + 2 > Shared.GetTime() then
            healRate = healRate * kAlienRegenerationCombatModifier
        end

        self:AddHealth(healRate, false, false, not hasRegenUpgrade)  
        self.timeLastAlienAutoHeal = Shared.GetTime()
    
    end 

end

-- Morph into new class or buy upgrade.
function Alien:ProcessBuyAction(techIds)

    ASSERT(type(techIds) == "table")
    ASSERT(table.count(techIds) > 0)

    local success = false

    if GetGamerules():GetGameStarted() or GetGamerules():GetWarmUpActive() then
    
        local healthScalar = self:GetHealth() / self:GetMaxHealth()
        local armorScalar = self:GetMaxArmor() == 0 and 1 or self:GetArmor() / self:GetMaxArmor()
        local totalCosts = 0
        
        local upgradeIds = {}
        local lifeFormTechId = nil
        for _, techId in ipairs(techIds) do
            
            if LookupTechData(techId, kTechDataGestateName) then
                lifeFormTechId = techId
            else
                table.insertunique(upgradeIds, techId)
            end
            
        end

        local oldLifeFormTechId = self:GetTechId()
        
		
		-- Only evolve if something changed
		local oldUpgrades = self:GetUpgrades()
		local newUpgrades = upgradeIds

        local upgradesAllowed = true
		
		local suma = 0
		local sumb = 0
		local proda = 1
		local prodb = 1
		
		for _, ID in ipairs(oldUpgrades) do
            suma = suma + ID
			if (ID > 0) then
				proda = proda * ID
			end
        end
		
		for _, ID in ipairs(newUpgrades) do
            sumb = sumb + ID
            if (ID > 0) then
				prodb = prodb * ID
			end
        end

		if suma == sumb and proda == prodb then
			if not lifeFormTechId then
				upgradesAllowed = false
			elseif oldLifeFormTechId == lifeFormTechId then
				upgradesAllowed = false
			end
		end
		
        local upgradeManager = AlienUpgradeManager()
        upgradeManager:Populate(self)
        -- add this first because it will allow switching existing upgrades
        if lifeFormTechId then
            upgradeManager:AddUpgrade(lifeFormTechId)
        end
        for _, newUpgradeId in ipairs(techIds) do

            if newUpgradeId ~= kTechId.None and not upgradeManager:AddUpgrade(newUpgradeId, true) then
                upgradesAllowed = false 
                break
            end
            
        end

		
        local position = self:GetOrigin()
        local trace = Shared.TraceRay(position, position + Vector(0, -0.5, 0), CollisionRep.Move, PhysicsMask.AllButPCs, EntityFilterOne(self))
        
        if upgradesAllowed and trace.surface ~= "no_evolve" then
        
            -- Check for room
            local eggExtents = LookupTechData(kTechId.Embryo, kTechDataMaxExtents)
            local newLifeFormTechId = upgradeManager:GetLifeFormTechId()
            local newAlienExtents = LookupTechData(newLifeFormTechId, kTechDataMaxExtents)
            local physicsMask = PhysicsMask.Evolve
            
            -- Add a bit to the extents when looking for a clear space to spawn.
            local spawnBufferExtents = Vector(0.1, 0.1, 0.1)
            
            local evolveAllowed = self:GetIsOnGround() and GetHasRoomForCapsule(eggExtents + spawnBufferExtents, position + Vector(0, eggExtents.y + Embryo.kEvolveSpawnOffset, 0), CollisionRep.Default, physicsMask, self)

            local roomAfter
            local spawnPoint
       
            -- If not on the ground for the buy action, attempt to automatically
            -- put the player on the ground in an area with enough room for the new Alien.
            if not evolveAllowed then
            
                for index = 1, 100 do
                
                    spawnPoint = GetRandomSpawnForCapsule(eggExtents.y, math.max(eggExtents.x, eggExtents.z), self:GetModelOrigin(), 0.5, 5, EntityFilterOne(self))
  
                    if spawnPoint then
                        self:SetOrigin(spawnPoint)
                        position = spawnPoint
                        break 
                    end
                    
                end
                

            end
            
            if not GetHasRoomForCapsule(newAlienExtents + spawnBufferExtents, self:GetOrigin() + Vector(0, newAlienExtents.y + Embryo.kEvolveSpawnOffset, 0), CollisionRep.Default, PhysicsMask.AllButPCsAndRagdollsAndBabblers, nil, EntityFilterOne(self)) then
           
                for index = 1, 100 do

                    roomAfter = GetRandomSpawnForCapsule(newAlienExtents.y, math.max(newAlienExtents.x, newAlienExtents.z), self:GetModelOrigin(), 0.5, 5, EntityFilterOne(self))
                    
                    if roomAfter then
                        evolveAllowed = true
                        break
                    end

                end
                
            else
                roomAfter = position
                evolveAllowed = true
            end
            
            if evolveAllowed and roomAfter ~= nil then

                local newPlayer = self:Replace(Embryo.kMapName)
                position.y = position.y + Embryo.kEvolveSpawnOffset
                newPlayer:SetOrigin(position)
                
                -- Clear angles, in case we were wall-walking or doing some crazy alien thing
                local angles = Angles(self:GetViewAngles())
                angles.roll = 0.0
                angles.pitch = 0.0
                newPlayer:SetOriginalAngles(angles)
                newPlayer:SetValidSpawnPoint(roomAfter)
                
                -- Eliminate velocity so that we don't slide or jump as an egg
                newPlayer:SetVelocity(Vector(0, 0, 0))                
                newPlayer:DropToFloor()
                
                newPlayer:SetResources(upgradeManager:GetAvailableResources())
                newPlayer:SetGestationData(upgradeManager:GetUpgrades(), self:GetTechId(), self:GetHealthFraction(), self:GetArmorScalar())
                
                if oldLifeFormTechId and lifeFormTechId and oldLifeFormTechId ~= lifeFormTechId then
                    newPlayer.oneHive = false
                    newPlayer.twoHives = false
                    newPlayer.threeHives = false
                end
                
                success = true
                
            end    
            
        end
    
    end
    
    if not success then
        self:TriggerInvalidSound()
    end    
    
    return success
    
end
