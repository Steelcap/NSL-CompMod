
if Server then
	function RegenerationMixin:AddRegeneration(regen)
		local max = self:GetMaxHealth() - self:GetHealth()
		self.regenerationValue = regen
		self.regenerationHealth = math.min(self.regenerationHealth + self.regenerationValue, max)

		self.regenerating = true
	end
end