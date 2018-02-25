kAlienNeuroToxinDamage = 6
kFadeNeuroToxinDamage = 10
kLerkNeuroToxinDamage = 5
kOnosNeuroToxinDamage = 8

--Utility function to apply chamber-upgraded modifications to alien damage
--Note: this should _always_ be called BEFORE damage-type specific modifications are done (i.e. Light vs Normal vs Structural, etc)
function NS2Gamerules_GetUpgradedAlienDamage( target, attacker, doer, damage, armorFractionUsed, healthPerArmor, damageType, hitPoint, weapon )
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
        
        if attacker:GetHasUpgrade( kTechId.Vampirism ) and target:isa("Player") then --ShadeHive
            local veilLevel = GetVeilLevel( kTeam2Index )
            if veilLevel > 0 then
                local leechedHealth = NS2Gamerules_GetAlienVampiricLeechFactor( attacker, doer, damageType, veilLevel )
                if attacker:GetIsAlive() then
                    attacker:AddHealth( leechedHealth, true, kAlienVampirismNotHealArmor ) --TODO Find better method/location to perform this
                end
            end
        end
        
    end
    
    if attacker:GetHasUpgrade( kTechId.Focus ) and DoesFocusAffectAbility(weapon) then
        local veilLevel = GetVeilLevel( kTeam2Index )
        local damageBonus = kAlienNeuroToxinDamage
        if weapon == kTechId.Swipe or weapon == kTechId.Stab then
            damageBonus = kFadeNeuroToxinDamage
        elseif weapon == kTechId.LerkBite then 
            damageBonus = kLerkNeuroToxinDamage
		elseif weapon == kTechId.Gore then
            damageBonus = kOnosNeuroToxinDamage
        end
        if Server then
			local dotMarker = CreateEntity(DotMarker.kMapName, target:GetEngagementPoint(), attacker:GetTeamNumber())
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
			dotMarker:ImmuneCondition(                
				function (self, target)
					return not target:GetIsAlive()
				end                 
			)
		end
    end
    
    --!!!Note: if more than damage and armor fraction modified, be certain the calling-point of this function is updated
    return damage, armorFractionUsed
    
end