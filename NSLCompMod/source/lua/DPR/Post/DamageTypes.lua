-- Vampirism is on Spurs
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
            local spurLevel = GetSpurLevel( kTeam2Index )
            if spurLevel > 0 then
                local leechedHealth = NS2Gamerules_GetAlienVampiricLeechFactor( attacker, doer, damageType, spurLevel )
                if attacker:GetIsAlive() then
                    attacker:AddHealth( leechedHealth, true, kAlienVampirismNotHealArmor ) --TODO Find better method/location to perform this
                end
            end
        end
        
    end
    
    if attacker:GetHasUpgrade( kTechId.Focus ) and DoesFocusAffectAbility(weapon) then
        local veilLevel = GetVeilLevel( kTeam2Index )
        local damageBonus = kAlienFocusDamageBonusAtMax
        if weapon == kTechId.Spit then -- gorge spit is a special case
            damageBonus = kGorgeSpitDamageBonusAtMax
        elseif weapon == kTechId.Stab then -- preparing for anticipated changes...
            damageBonus = kStabDamageBonusAtMax
        end
        damage = damage * (1 + (veilLevel/3) * damageBonus) --1.0, 1.333, 1.666, 2
    end
    
    --!!!Note: if more than damage and armor fraction modified, be certain the calling-point of this function is updated
    return damage, armorFractionUsed
    
end
