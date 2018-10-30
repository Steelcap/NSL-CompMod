local kClusterBurnDurationStructure = 2
local kClusterBurnDurationPlayer = 4
local kBurnUpdateRate = 0.5 -- same as vanilla

-- fire from cluster grenades burns for less time
local function SharedUpdate(self, deltaTime)
    PROFILE("FireMixin:UpdateFireState")

    if Client then
        self:UpdateFireMaterial()
        self:_UpdateClientFireEffects()
    end

    if not self:GetIsOnFire() then
        return
    end

    if Server then
        local time = Shared.GetTime()
        if self:GetIsAlive() and (not self.timeLastFireDamageUpdate or self.timeLastFireDamageUpdate + kBurnUpdateRate <= time) then

            local damageOverTime = kBurnUpdateRate * kBurnDamagePerSecond

            if self.GetReceivesStructuralDamage and self:GetReceivesStructuralDamage() then
                damageOverTime = damageOverTime * kStructuralDamageScalar
            end

            if self.GetIsFlameAble and self:GetIsFlameAble() then
                damageOverTime = damageOverTime * kFlameableMultiplier
            end

            local attacker
            if self.fireAttackerId ~= Entity.invalidId then
                attacker = Shared.GetEntity(self.fireAttackerId)
            end

            local doer
            if self.fireDoerId ~= Entity.invalidId then
                doer = Shared.GetEntity(self.fireDoerId)
            end

            local _, damageDone = self:DeductHealth(damageOverTime, attacker, doer)

            if attacker then
                SendDamageMessage( attacker, self, damageDone, self:GetOrigin(), damageDone )
            end

            self.timeLastFireDamageUpdate = time

        end

        -- See if we put ourselves out
        if time - self.timeBurnRefresh > self.timeBurnDuration then
            self:SetGameEffectMask(kGameEffect.OnFire, false)
        end
    end
end

-- Use the new function
function FireMixin:OnUpdate(deltaTime)
    SharedUpdate(self, deltaTime)
end

-- Track the name of what burned us, even if the entity is destroyed
-- (only tracks cluster grenade and flamethrower)
function FireMixin:SetOnFire(attacker, doer)
    if Server and not self:GetIsDestroyed() then
        if not self:GetCanBeSetOnFire() then
            return
        end

        self:SetGameEffectMask(kGameEffect.OnFire, true)

        if attacker then
            self.fireAttackerId = attacker:GetId()
        end

        if doer then
            self.fireDoerId = doer:GetId()
        end

        local time = Shared.GetTime()
        self.timeBurnRefresh = time
        self.timeLastFireDamageUpdate = time
        self.isOnFire = true
        
        --Flat restriction to single-shot player burn time. ideally will diminish "burn-out" deaths
        if doer and doer:isa("ClusterGrenade") then
            if self:isa("Player") then
                self.timeBurnDuration = kClusterBurnDurationPlayer
            else
                self.timeBurnDuration = kClusterBurnDurationStructure
            end
        else
            if self:isa("Player") then
                self.timeBurnDuration = kFlamethrowerBurnDuration
            else
                self.timeBurnDuration = math.min(self.timeBurnDuration + kFlamethrowerBurnDuration, kFlamethrowerMaxBurnDuration)
            end
        end
    end
end
