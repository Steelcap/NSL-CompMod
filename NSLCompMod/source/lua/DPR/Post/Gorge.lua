function Gorge:GetAirFriction()
    local speedFraction = self:GetVelocity():GetLengthXZ() / self:GetMaxSpeed()
    return math.max(0.15 * speedFraction, 0.12)
end

function Gorge:GetAirControl()
    return 30
end

Gorge.kBellyFriction = 0.2