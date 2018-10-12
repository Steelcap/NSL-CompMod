local kFadeGroundFrictionBase = 9
local kFadeGroundFrictionPostBlink = 1
local kFadeGroundFrictionPostBlinkDelay = 1.5

function Fade:GetGroundFriction()
	if self:GetIsBlinking() then
		return 0
	end
	local x = Shared.GetTime() - self.etherealEndTime
	if x < kFadeGroundFrictionPostBlinkDelay then
		local ratio = x / kFadeGroundFrictionPostBlinkDelay
		return kFadeGroundFrictionPostBlink + ((kFadeGroundFrictionBase - kFadeGroundFrictionPostBlink) * ratio)
	end

	return kFadeGroundFrictionBase
end