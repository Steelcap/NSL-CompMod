function TunnelEntrance:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    self:SetModel(TunnelEntrance.kModelName, kAnimationGraph)
    
    if Server then
    
        InitMixin(self, StaticTargetMixin)
        InitMixin(self, SleeperMixin)
        
        -- This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
        self.onNormalInfestation = false
        --self:AddTimedCallback(UpdateInfestationStatus, 1)
        self:UpdateIncludeRelevancyMask()
		
    elseif Client then
    
        InitMixin(self, UnitStatusMixin)
        InitMixin(self, HiveVisionMixin)
        
    end

end

if Server then

	function TunnelEntrance:UpdateIncludeRelevancyMask()
		local includeMask = Math.infinity
		self:SetIncludeRelevancyMask(includeMask)
	end

end
