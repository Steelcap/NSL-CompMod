-- Pregame damage only right next to command structures
function NS2Gamerules:KillEnemiesNearCommandStructureInPreGame(timePassed)

    if self:GetGameState() < kGameState.Countdown then

        local commandStations = Shared.GetEntitiesWithClassname("CommandStructure")
        for _, ent in ientitylist(commandStations) do

            local enemyPlayers = GetEntitiesForTeam("Player", GetEnemyTeamNumber(ent:GetTeamNumber()))
            for e = 1, #enemyPlayers do

                local enemy = enemyPlayers[e]
                if enemy:GetDistance(ent) <= 5 then
                    enemy:TakeDamage(25 * timePassed, nil, nil, nil, nil, 0, 25 * timePassed, kDamageType.Normal)
                end
            end
        end
    end
end
