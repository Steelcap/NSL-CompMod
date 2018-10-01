function MedPack:OnTouch(recipient)

    if not recipient.timeLastMedpack or recipient.timeLastMedpack + self.kPickupDelay <= Shared.GetTime() then
    
		local level = recipient:GetMedpackLevel()
		
		local heal = 25
		local regen = 25
		
		if level == 1 then
			heal = 30
			regen = 20
		elseif level == 2 then
			heal = 40
			regen = 10
		end
		
        recipient:AddHealth(heal, false, true)
        recipient:AddRegeneration(regen)
        recipient.timeLastMedpack = Shared.GetTime()

        self:TriggerEffects("medpack_pickup", { effecthostcoords = self:GetCoords() })

    end
    
end