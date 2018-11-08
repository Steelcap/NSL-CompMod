-- How many seconds your exo remains exclusive after you eject
local NSLExoLockoutTime = 0.5

function Exosuit:OnOwnerChanged(prevOwner, newOwner)

    if not newOwner or not (newOwner:isa("Marine") or newOwner:isa("JetpackMarine")) then
        self.resetOwnerTime = Shared.GetTime() + 0.1
    else
        self.resetOwnerTime = Shared.GetTime() + NSLExoLockoutTime
    end
    
end

function Exosuit:OnWeldOverride(doer, elapsedTime)

    -- macs weld marines by only 50% of the rate
    local macMod = (HasMixin(self, "Combat") and self:GetIsInCombat()) and 0.1 or 0.5    
    local weldMod = ( doer ~= nil and doer:isa("MAC") ) and macMod or 1

    if self:GetArmor() < self:GetMaxArmor() then
    
        local addArmor = kExoArmorWeldRate * elapsedTime * weldMod
        self:SetArmor(self:GetArmor() + addArmor)
        
    end
    
end