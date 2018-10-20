function Gorge:GetAirControl()
    return 18
end

function Gorge:GetAirFriction()
	local speedFraction = self:GetVelocity():GetLengthXZ() / self:GetMaxSpeed()
    return math.max(0.165 * speedFraction, 0.12)
end