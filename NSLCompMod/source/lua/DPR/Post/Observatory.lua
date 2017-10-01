Script.Load("lua/SupplyUserMixin.lua")

-- Observatory costs supply
if Server then
    local oldIntitialize = Observatory.OnInitialized
    function Observatory:OnInitialized()
        oldIntitialize(self)
        InitMixin(self, SupplyUserMixin)
    end
end
