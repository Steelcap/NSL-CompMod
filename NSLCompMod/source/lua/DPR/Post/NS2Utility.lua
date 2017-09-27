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
