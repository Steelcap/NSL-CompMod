-- How many seconds your exo remains exclusive after you eject
local NSLExoLockoutTime = 0.5

function Exosuit:OnOwnerChanged(prevOwner, newOwner)

    if not newOwner or not (newOwner:isa("Marine") or newOwner:isa("JetpackMarine")) then
        self.resetOwnerTime = Shared.GetTime() + 0.1
    else
        self.resetOwnerTime = Shared.GetTime() + NSLExoLockoutTime
    end
    
end
