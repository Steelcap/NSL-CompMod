-- cluster grenades set stuff on fire
if Server then
    -- Cluster Grenades set structures and players on fire
    -- Thanks Dragon :)
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

    -- Cluster Grenades burn and destroy abilities
    local function BurnNearbyAbilities(self, range)
        --TODO: should range be cluster size or individual cloud size?
        local grenadePos = self:GetOrigin()

        -- lerk spores
        local spores = GetEntitiesWithinRange("SporeCloud", grenadePos, range)

        -- lerk umbra
        local umbras = GetEntitiesWithinRange("CragUmbra", grenadePos, range)

        -- bilebomb (gorge and contamination), whip bomb
        local bombs = GetEntitiesWithinRange("Bomb", grenadePos, range)
        table.copy(GetEntitiesWithinRange("WhipBomb", grenadePos, range), bombs, true)

        for _, spore in ipairs(spores) do
            self:TriggerEffects("burn_spore", {effecthostcoords = Coords.GetTranslation(spore:GetOrigin())})
            DestroyEntity(spore)
        end

        for _, umbra in ipairs(umbras) do
            self:TriggerEffects("burn_umbra", {effecthostcoords = Coords.GetTranslation(umbra:GetOrigin())})
            DestroyEntity(umbra)
        end

        for _, bomb in ipairs(bombs) do
            self:TriggerEffects("burn_bomb", {effecthostcoords = Coords.GetTranslation(bomb:GetOrigin())})
            DestroyEntity(bomb)
        end
    end

    local oldClusterGrenadeDetonate = ClusterGrenade.Detonate
    function ClusterGrenade:Detonate(targetHit)
        IgniteNearbyEntities(self, kClusterGrenadeDamageRadius)
        BurnNearbyAbilities(self, kClusterGrenadeDamageRadius)

        oldClusterGrenadeDetonate(self, targetHit)
    end
end
