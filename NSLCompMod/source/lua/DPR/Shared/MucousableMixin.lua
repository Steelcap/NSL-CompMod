local kMaxShield = 250 -- same as vanilla

-- Use biomass-included health, not just base health
function MucousableMixin:GetMaxShieldAmount()
    return math.floor(math.min(self:GetMaxHealth() * kMucousShieldPercent, kMaxShield))
end
