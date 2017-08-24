function Alien:UpdateHealthAmount(bioMassLevel, maxLevel)

    local level = math.max(0, bioMassLevel - 1)
	if self:isa("Skulk") then
		level = math.min(level,3)
	end
	
    local newMaxHealth = self:GetBaseHealth() + level * self:GetHealthPerBioMass()

    if newMaxHealth ~= self.maxHealth  then

        local healthPercent = self.maxHealth > 0 and self.health/self.maxHealth or 0
        self:SetMaxHealth(newMaxHealth)
        self:SetHealth(self.maxHealth * healthPercent)
    
    end

end