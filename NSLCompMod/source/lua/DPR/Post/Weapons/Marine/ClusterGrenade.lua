-- Cluster Grenades set structures and players on fire
-- Thanks Dragon :)
if Server then
    local function IgniteNearbyEntities(self, range)
        local hitEntities = GetEntitiesWithMixinWithinRange("Fire", self:GetOrigin(), range)
        local player = self:GetOwner()
        table.removevalue(hitEntities, self)
        if player then
            for _, hitEnt in ipairs(hitEntities) do
                hitEnt:SetOnFire(player, self)
            end
        end
    end

    local oldClusterGrenadeDetonate = ClusterGrenade.Detonate
    function ClusterGrenade:Detonate(targetHit)
        IgniteNearbyEntities(self, kClusterGrenadeDamageRadius)
        oldClusterGrenadeDetonate(self, targetHit)
    end
end
