function MedPack:OnTouch(recipient)

    if not recipient.timeLastMedpack or recipient.timeLastMedpack + self.kPickupDelay <= Shared.GetTime() then
    
		local level = recipient:GetArmorLevel() + recipient:GetWeaponLevel()
		
		local heal = 30
		local regen = 20
		
		if level == 1 then
			heal = 35
			regen = 15
		elseif level == 2 then
			heal = 40
			regen = 10
		elseif level == 3 then
			heal = 45
			regen = 5
		elseif level == 4 then
			heal = 50
			regen = 0
		elseif level == 5 then
			heal = 55
			regen = 0
		elseif level == 6 then
			heal = 60
			regen = 0
		end
		
        recipient:AddHealth(heal, false, true)
        recipient:AddRegeneration(regen)
        recipient.timeLastMedpack = Shared.GetTime()
        StartSoundEffectAtOrigin(MedPack.kHealthSound, self:GetOrigin())

    end
    
end