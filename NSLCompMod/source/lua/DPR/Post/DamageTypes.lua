--Utility function to apply chamber-upgraded modifications to alien damage
--Note: this should _always_ be called BEFORE damage-type specific modifications are done (i.e. Light vs Normal vs Structural, etc)
function NS2Gamerules_GetUpgradedAlienDamage( target, attacker, doer, damage, armorFractionUsed, healthPerArmor, damageType, hitPoint, weapon )
    
    if not doer then return damage, armorFractionUsed end

    local teamNumber = attacker:GetTeamNumber()

    local isAffectedByCrush = doer.GetIsAffectedByCrush and attacker:GetHasUpgrade( kTechId.Crush ) and doer:GetIsAffectedByCrush()
    local isAffectedByVampirism = doer.GetVampiricLeechScalar and attacker:GetHasUpgrade( kTechId.Vampirism )
    local isAffectedByFocus = doer.GetIsAffectedByFocus and attacker:GetHasUpgrade( kTechId.Focus ) and doer:GetIsAffectedByFocus()

    if attacker:GetHasUpgrade( kTechId.Crush ) then --CragHive
        
        local shellLevel = GetShellLevel( kTeam2Index )
        if shellLevel > 0 then
            if target:isa("Exo") or target.GetReceivesStructuralDamage and target:GetReceivesStructuralDamage(damageType) then
                damage = damage + ( damage * ( shellLevel * kAlienCrushDamagePercentByLevel ) )
            elseif target:isa("Player") then
                armorFractionUsed = kBaseArmorUseFraction + ( shellLevel * kAlienCrushDamagePercentByLevel )
            end
        end
        
    end
    
    if Server then

        -- Vampirism
        if isAffectedByVampirism then
            local vampirismLevel = attacker:GetShellLevel()
            if vampirismLevel > 0 then
                if attacker:GetIsHealable() and target:isa("Player") then
                    local scalar = doer:GetVampiricLeechScalar()
                    if scalar > 0 then
                        local maxHealth = attacker:GetMaxHealth()
                        local leechedHealth =  maxHealth * vampirismLevel * scalar
                        attacker:AddHealth( leechedHealth, true, kAlienVampirismNotHealArmor )

                    end
                end
            end
        end
        
    end
    
    if isAffectedByFocus then
        local veilLevel = GetVeilLevel( kTeam2Index )
        local damageBonus = kSkulkNeuroToxinDamage
        if weapon == kTechId.Swipe or weapon == kTechId.Stab then
            damageBonus = kFadeNeuroToxinDamage
        elseif weapon == kTechId.LerkBite then 
            damageBonus = kLerkNeuroToxinDamage
		elseif weapon == kTechId.Gore then
            damageBonus = kOnosNeuroToxinDamage
		elseif weapon == kTechId.Spit then
            damageBonus = kGorgeNeuroToxinDamage
        end
        if Server then
				local dotMarker = CreateEntity(DotMarker.kMapName, target:GetOrigin(), attacker:GetTeamNumber())
				dotMarker:SetDamageType(kDamageType.Gas)
				dotMarker:SetLifeTime(0.1 + veilLevel)
				dotMarker:SetDamage(damageBonus)
				dotMarker:SetRadius(0.1)
				dotMarker:SetDamageIntervall(1)
				dotMarker:SetDotMarkerType(DotMarker.kType.SingleTarget)
				dotMarker:SetTargetEffectName("poison_dart_trail")
				dotMarker:SetDeathIconIndex(kDeathMessageIcon.SporeCloud)
				dotMarker:SetOwner(attacker)
				dotMarker:SetAttachToTarget(target, target:GetEngagementPoint())
			
				dotMarker:SetDestroyCondition(                
					function (self, target)
						return not target:GetIsAlive()
					end                 
				)
				-- dotMarker:ImmuneCondition(                
				-- 	function (self, target)
				-- 		return not target:GetIsAlive()
				-- 	end                 
				-- )
		end
    end
    
    --!!!Note: if more than damage and armor fraction modified, be certain the calling-point of this function is updated
    return damage, armorFractionUsed
    
end