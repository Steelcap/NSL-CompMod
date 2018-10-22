function CrouchMoveMixin:ModifyMaxSpeed(maxSpeedTable)

	local blinkingFade = self:isa("Fade") and self:GetIsBlinking()

    if self:GetIsOnGround() and not blinkingFade then
        local crouchMod = 1 - self:GetCrouchAmount() * self:GetCrouchSpeedScalar()
        maxSpeedTable.maxSpeed = maxSpeedTable.maxSpeed * crouchMod
    end

end
