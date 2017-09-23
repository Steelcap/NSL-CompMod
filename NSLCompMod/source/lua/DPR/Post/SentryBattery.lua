Script.Load("lua/SupplyUserMixin.lua")

if Server then
	local oldIntitialize = SentryBattery.OnInitialized
	function SentryBattery:OnInitialized()
		oldIntitialize(self)
		InitMixin(self, SupplyUserMixin)		
	end
end