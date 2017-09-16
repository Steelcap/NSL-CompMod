kAlienFocusDamageBonusAtMax = 1 -- max focus adds 100% damage

-- Attacks with Focus against players become Light damage type
local oldGetDamageByType = GetDamageByType
function GetDamageByType(target, attacker, doer, damage, damageType, hitPoint, weapon)

    assert(target)
    
    if not kDamageTypeGlobalRules or not kDamageTypeRules then
        -- There is a local function (BuildDamageTypeRules) that needs to be called once
        oldGetDamageByType(target, attacker, doer, damage, damageType, hitPoint, weapon)
    end
    
    -- at first check if damage is possible, if not we can skip the rest
    if not CanEntityDoDamageTo(attacker, target, Shared.GetCheatsEnabled(), Shared.GetDevMode(), GetFriendlyFire(), damageType) then
        return 0, 0, 0
    end
    
    local armorUsed = 0
    local healthUsed = 0
    
    local armorFractionUsed, healthPerArmor = 0
    
    -- apply global rules at first
    for _, rule in ipairs(kDamageTypeGlobalRules) do
        damage, armorFractionUsed, healthPerArmor = rule(target, attacker, doer, damage, armorFractionUsed, healthPerArmor, damageType, hitPoint)
    end
    
    --Account for Alien Chamber Upgrades damage modifications (must be before damage-type rules)
    if attacker:GetTeamType() == kAlienTeamType and attacker:isa("Player") then
        damage, armorFractionUsed = NS2Gamerules_GetUpgradedAlienDamage( target, attacker, doer, damage, armorFractionUsed, healthPerArmor, damageType, hitPoint, weapon )
    end
    
    -- Focus changes damage type against players
    if DoesFocusAffectAbility(weapon) and attacker:GetHasUpgrade(kTechId.Focus) and
            (target:isa("Player") or target:isa("Exosuit")) then

        damageType = kDamageType.Light
    end

    -- apply damage type specific rules
    for _, rule in ipairs(kDamageTypeRules[damageType]) do
        damage, armorFractionUsed, healthPerArmor = rule(target, attacker, doer, damage, armorFractionUsed, healthPerArmor, damageType, hitPoint)
    end
    
    if damage > 0 and healthPerArmor > 0 then

        -- Each point of armor blocks a point of health but is only destroyed at half that rate (like NS1)
        -- Thanks Harimau!
        local healthPointsBlocked = math.min(healthPerArmor * target.armor, armorFractionUsed * damage)
        armorUsed = healthPointsBlocked / healthPerArmor
        
        -- Anything left over comes off of health
        healthUsed = damage - healthPointsBlocked

    end
    
    return damage, armorUsed, healthUsed

end

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
