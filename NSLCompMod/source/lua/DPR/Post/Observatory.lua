Script.Load("lua/SupplyUserMixin.lua")

if Server then
	local oldIntitialize = Observatory.OnInitialized
	function Observatory:OnInitialized()
		oldIntitialize(self)
		InitMixin(self, SupplyUserMixin)		
	end
end