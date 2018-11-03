--thx Dragon <3

local oldARCOnCreate
oldARCOnCreate = Class_ReplaceMethod("ARC", "OnCreate",
	function(self)
		oldARCOnCreate(self)
		InitMixin(self, ArcSpeedBoostMixin)
    end
)

local oldARCPerformActivation
oldARCPerformActivation = Class_ReplaceMethod("ARC", "PerformActivation",
	function(self, techId, position, normal, commander)
		if techId == kTechId.ARCSpeedBoost and not self:SpeedBoostOnCooldown() then
			self:TriggerSpeedBoost()
			return true, true
		else
			return oldARCPerformActivation(self, techId, position, normal, commander)
		end  
    end
)

local oldARCGetActivationTechAllowed
oldARCGetActivationTechAllowed = Class_ReplaceMethod("ARC", "GetActivationTechAllowed",
	function(self, techId)
		if techId == kTechId.ARCSpeedBoost then
			return self.deployMode == ARC.kDeployMode.Undeployed and not self:SpeedBoostOnCooldown()
		else
			return oldARCGetActivationTechAllowed(self, techId)
		end
    end
)

local oldARCGetTechButtons
oldARCGetTechButtons = Class_ReplaceMethod("ARC", "GetTechButtons",
	function(self, techId)

		local techButtons = oldARCGetTechButtons(self, techId)
		techButtons[3] = kTechId.ARCSpeedBoost
		return techButtons
		
	end
)

local oldARCGetTurnSpeedOverride
oldARCGetTurnSpeedOverride = Class_ReplaceMethod("ARC", "GetTurnSpeedOverride",
	function(self)
		if self:HasSpeedBoost() then
			return kARCSpeedBoostTurnRate
		end
		return ARC.kTurnSpeed
	end
)

local networkVars = { }

AddMixinNetworkVars(ArcSpeedBoostMixin, networkVars)

Shared.LinkClassToMap("ARC", ARC.kMapName, networkVars, true)

//Cooldown hacks
function MarineCommander:GetCooldownFraction(techId)

	if techId == kTechId.ARCSpeedBoost then
		local selection = self:GetSelection()
		local cooldown = 1
		if #selection > 0 then
			//Look through arcs, look for any arcs that are off cooldown, otherwise take furthest along cooldown.
			for i = 1, #selection do
				local entity = selection[i]
				if entity and entity:isa("ARC") then
					if entity:SpeedBoostCooldown() < cooldown then
						cooldown = entity:SpeedBoostCooldown()
					end
				end
			end
		end
		return cooldown
	end
	
	return Commander.GetCooldownFraction(self, techId)

end

