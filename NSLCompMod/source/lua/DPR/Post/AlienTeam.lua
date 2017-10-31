-- pass in the player and if he's crouching, keep the oldest tunnel
function AlienTeam:RemoveGorgeStructureFromClient(techId, clientId, player)

    local structureTypeTable = self.clientOwnedStructures[clientId]
    
    if structureTypeTable then
    
        if not structureTypeTable[techId] then
        
            structureTypeTable[techId] = { }
            return
            
        end    
        
        local removeIndex = 0
        local structure
		local skip = false
		if techId == kTechId.GorgeTunnel and player and player:GetCrouching() then
			skip = true
		end
        for index, id in ipairs(structureTypeTable[techId])  do
        
            if id and not skip then
            
                removeIndex = index
                structure = Shared.GetEntity(id)
                break
                
            else
				skip = false
			end
            
        end
        
        if structure then
        
            table.remove(structureTypeTable[techId], removeIndex)
            structure.consumed = true
            if structure:GetCanDie() then
                structure:Kill()
            else
                DestroyEntity(structure)
            end
            
        end
        
    end
    
end

-- not changed but called in AddGorgeStructure
--TODO: getupvalue
local function ApplyGorgeStructureTheme(structure, player)

    assert(player:isa("Gorge"))
    
    if structure.SetVariant then
        structure:SetVariant(player:GetVariant())
    end
    
end

-- pass player to RGSFC
function AlienTeam:AddGorgeStructure(player, structure)

    if player ~= nil and structure ~= nil then

        local clientId = Server.GetOwner(player):GetUserId()
        local structureId = structure:GetId()
        local techId = structure:GetTechId()

        if not self.clientOwnedStructures[clientId] then
            table.insert(self.clientStructuresOwner, clientId)
            self.clientOwnedStructures[clientId] = {
                techIds = {}
            }
        end

        local structureTypeTable = self.clientOwnedStructures[clientId]

        if not structureTypeTable[techId] then
            structureTypeTable[techId] = {}
            table.insert(structureTypeTable.techIds, techId)
        end

        table.insertunique(structureTypeTable[techId], structureId)

        ApplyGorgeStructureTheme(structure, player)

        local numAllowedStructure = LookupTechData(techId, kTechDataMaxAmount, -1) --* self:GetNumHives()

        if numAllowedStructure >= 0 and table.icount(structureTypeTable[techId]) > numAllowedStructure then
            self:RemoveGorgeStructureFromClient(techId, clientId)
        end

    end

end


-- nutrient mist doesn't give health for structures off infestation
function AlienTeam:UpdateTeamAutoHeal(timePassed)

    PROFILE("AlienTeam:UpdateTeamAutoHeal")

    local time = Shared.GetTime()
    
    if self.timeOfLastAutoHeal == nil then
        self.timeOfLastAutoHeal = Shared.GetTime()
    end
    
    if time > (self.timeOfLastAutoHeal + AlienTeam.kStructureAutoHealInterval) then
        
        local intervalLength = time - self.timeOfLastAutoHeal
        local gameEnts = GetEntitiesWithMixinForTeam("InfestationTracker", self:GetTeamNumber())
        local numEnts = table.count(gameEnts)
        local toIndex = self.lastAutoHealIndex + AlienTeam.kAutoHealUpdateNum - 1
        toIndex = ConditionalValue(toIndex <= numEnts , toIndex, numEnts)
        for index = self.lastAutoHealIndex, toIndex do

            local entity = gameEnts[index]
            
            -- players update the auto heal on their own
            if not entity:isa("Player") then
            
                -- we add whips as an exception here. construction should still be restricted to onInfestation, we only don't want whips to take damage off infestation
                local requiresInfestation   = ConditionalValue(entity:isa("Whip"), false, LookupTechData(entity:GetTechId(), kTechDataRequiresInfestation))
                local isOnInfestation       = entity:GetGameEffectMask(kGameEffect.OnInfestation)
                local isHealable            = entity:GetIsHealable()
                local deltaTime             = 0

                -- Ignore nutrient mist healing
                local beingCatalyzed        = false --HasMixin(entity, "Catalyst") and entity:GetIsCatalysted()
                
                if not entity.timeLastAutoHeal then
                    entity.timeLastAutoHeal = Shared.GetTime()
                else
                    deltaTime = Shared.GetTime() - entity.timeLastAutoHeal
                    entity.timeLastAutoHeal = Shared.GetTime()
                end

                if requiresInfestation and not isOnInfestation and not beingCatalyzed then
                    
                    -- Take damage!
                    local damage = entity:GetMaxHealth() * kBalanceInfestationHurtPercentPerSecond/100 * deltaTime
                    damage = math.max(damage, kMinHurtPerSecond)
                    
                    local attacker
                    if entity.lastAttackerDidDamageTime and Shared.GetTime() < entity.lastAttackerDidDamageTime + 60 then
                        attacker = entity:GetLastAttacker()
                    end
                    
                    entity:DeductHealth(damage, attacker)
                               
                end
            
            end
        
        end
        
        if self.lastAutoHealIndex + AlienTeam.kAutoHealUpdateNum >= numEnts then
            self.lastAutoHealIndex = 1
        else
            self.lastAutoHealIndex = self.lastAutoHealIndex + AlienTeam.kAutoHealUpdateNum
        end 

        self.timeOfLastAutoHeal = Shared.GetTime()

   end
    
end

-- move silence to veils
function AlienTeam:OnUpgradeChamberDestroyed(upgradeChamber)

    if upgradeChamber:GetTechId() == kTechId.CarapaceShell then
        self.updateAlienArmor = true
    end

    -- These is a list of all tech to check when a upgrade chamber is destroyed.
    local checkForLostResearch = {
        [kTechId.RegenerationShell] = {"Shell", kTechId.Regeneration},
        [kTechId.CarapaceShell] = {"Shell", kTechId.Carapace},
        [kTechId.CrushShell] = {"Shell", kTechId.Crush},

        [kTechId.CeleritySpur] = {"Spur", kTechId.Celerity},
        [kTechId.AdrenalineSpur] = {"Spur", kTechId.Adrenaline},

        -- Remove Focus
        --[kTechId.FocusVeil] = {"Veil", kTechId.Focus},
        [kTechId.AuraVeil] = {"Veil", kTechId.Aura},
        -- Move Silence to Veils
        [kTechId.SilenceSpur] = {"Veil", kTechId.Silence},
        [kTechId.VampirismVeil] = {"Veil", kTechId.Vampirism},
    }

    local checkTech = checkForLostResearch[upgradeChamber:GetTechId()]
    if checkTech then

        local anyRemain = false
        for _, ent in ientitylist(Shared.GetEntitiesWithClassname(checkTech[1])) do

            -- Don't count the upgradeChamber as it is being destroyed now.
            if ent ~= upgradeChamber and ent:GetTechId() == upgradeChamber:GetTechId() then

                anyRemain = true
                break

            end

        end

        if not anyRemain then
            SendTeamMessage(self, kTeamMessageTypes.ResearchLost, checkTech[2])
        end

    end

end
