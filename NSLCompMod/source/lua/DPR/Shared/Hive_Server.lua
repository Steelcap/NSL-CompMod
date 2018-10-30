local function UpdateHealing(self)

    if GetIsUnitActive(self) and not self:GetGameEffectMask(kGameEffect.OnFire) then

        if self.timeOfLastHeal == nil or Shared.GetTime() > (self.timeOfLastHeal + Hive.kHealthUpdateTime) then

            local players = GetEntitiesForTeam("Player", self:GetTeamNumber())
            for index, player in ipairs(players) do
                if player:GetIsAlive()and ((player:GetOrigin() - self:GetOrigin()):GetLength() < Hive.kHealRadius) then
                    player:AddHealth(math.max(10, player:GetMaxHealth() * Hive.kHealthPercentage), true)
                end
            end

            self.timeOfLastHeal = Shared.GetTime()

        end

    end

end

ReplaceLocals(Hive.OnUpdate, {UpdateHealing = UpdateHealing})