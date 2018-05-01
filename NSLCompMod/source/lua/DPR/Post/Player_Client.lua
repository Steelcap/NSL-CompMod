-- Hide enemy health bars
function Player:GetShowHealthFor(player)
    return ( player:isa("Spectator") or player:isa("Commander") or ( not GetAreEnemies(self, player) and self:GetIsAlive() ) ) and self:GetTeamType() ~= kNeutralTeamType
end