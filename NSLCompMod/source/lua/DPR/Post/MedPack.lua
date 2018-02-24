function MedPack:OnTouch(recipient)

    if not recipient.timeLastMedpack or recipient.timeLastMedpack + self.kPickupDelay <= Shared.GetTime() then
    
		local level = recipient:GetArmorLevel()
		
		local heal = 20
		local regen = 30
		
		if level == 1 then
			heal = 25
			regen = 25
		elseif level == 2 then
			heal = 35
			regen = 15
		elseif level == 3 then
			heal = 50
			regen = 0
		end
		
        recipient:AddHealth(heal, false, true)
        recipient:AddRegeneration(regen)
        recipient.timeLastMedpack = Shared.GetTime()
        StartSoundEffectAtOrigin(MedPack.kHealthSound, self:GetOrigin())

    end
    
end