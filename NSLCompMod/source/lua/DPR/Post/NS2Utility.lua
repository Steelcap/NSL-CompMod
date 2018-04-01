-- Alien supply limit is 50 + (50 * number of hives)
function GetMaxSupplyForTeam(teamNumber)
    local maxSupply = 50

    if Server then

        local team = GetGamerules():GetTeam(teamNumber)
        if team and team:GetIsAlienTeam() and team.GetNumCapturedTechPoints then
            maxSupply = maxSupply + (team:GetNumCapturedTechPoints() * kSupplyPerTechpoint)
        else
            return kMaxSupply
        end

    else

        local teamInfoEnt = GetTeamInfoEntity(teamNumber)
        if ( teamInfoEnt:GetTeamType() == kAlienTeamType) then
            if teamInfoEnt and teamInfoEnt.GetNumCapturedTechPoints then
                maxSupply = maxSupply + teamInfoEnt:GetNumCapturedTechPoints() * kSupplyPerTechpoint
            end
        else
            return kMaxSupply
        end

    end

    return maxSupply 
end



-- All damage is routed through here.
function CanEntityDoDamageTo(attacker, target, cheats, devMode, friendlyFire, damageType)

    if not GetGameInfoEntity():GetGameStarted() and not GetGameInfoEntity():GetWarmUpActive() then
        return false
    end

    if target:isa("Clog") then
        return true
    end

    if not HasMixin(target, "Live") then
        return false
    end

    if GetGameInfoEntity():GetWarmUpActive() and not GetValidTargetInWarmUp(target) then
        return false
    end

    if target:isa("ARC") and damageType == kDamageType.Splash then
        return true
    end

    if not target:GetCanTakeDamage() then
        return false
    end

    if target == nil or (target.GetDarwinMode and target:GetDarwinMode()) then
        return false
    elseif cheats or devMode then
        return true
    elseif attacker == nil then
        return true
    end

    -- You can always do damage to yourself.
    if attacker == target then
        return true
    end

    -- Command stations can kill even friendlies trapped inside.
    if attacker ~= nil and attacker:isa("CommandStation") then
        return true
    end

    -- Your own grenades can hurt you.
    if attacker:isa("Grenade") then

        local owner = attacker:GetOwner()
        if owner and owner:GetId() == target:GetId() then
            return true
        end

    end

    -- Same teams not allowed to hurt each other unless friendly fire enabled.
    local teamsOK = true
    if attacker ~= nil then
        teamsOK = GetAreEnemies(attacker, target) or friendlyFire
    end

	-- COMPMOD Prevent FT puddles from hurting teammates
	if attacker:isa("Flame") then
		if not GetAreEnemies(attacker, target) then
			return false
		end
	end
	
    -- Allow damage of own stuff when testing.
    return teamsOK

end