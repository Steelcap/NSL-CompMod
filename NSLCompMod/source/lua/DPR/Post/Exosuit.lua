function Exosuit:OnOwnerChanged(prevOwner, newOwner)

    if not newOwner or not (newOwner:isa("Marine") or newOwner:isa("JetpackMarine")) then
        self.resetOwnerTime = Shared.GetTime() + 0.1
    else
        self.resetOwnerTime = Shared.GetTime() + 0.5 -- magic number for NSL comp mod
    end
    
end