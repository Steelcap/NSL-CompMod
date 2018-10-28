local kPulseGrenadeAutoExplodeRadius = 1

function PulseGrenade:OnUpdate(deltaTime)

    PredictedProjectile.OnUpdate(self, deltaTime)

    for _, enemy in ipairs( GetEntitiesForTeamWithinRange("Alien", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), kPulseGrenadeAutoExplodeRadius) ) do
    
        if enemy:GetIsAlive() and self.Detonate then
            self:Detonate()
            break
        end
    
    end

end