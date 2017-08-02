function ResourceTower:CollectResources()

    for _, player in ipairs(GetEntitiesForTeam("Player", self:GetTeamNumber())) do
		local newPResrate = .1
		
		--if player:isa("Fade") or player:isa("Lerk") or player:isa("Onos") then
		--	newPResrate = .1
		--	end
			
		--if player:isa("Marine") then
		--	newPResrate = .1
		--	end
			
        if not player:isa("Commander") then
            player:AddResources(newPResrate)  --kPlayerResPerInterval was .125
        end
    end
    
    local team = self:GetTeam()
    if team then
        team:AddTeamResources(kTeamResourcePerTick, true)
    end

    if self:isa("Extractor") then
       self:TriggerEffects("extractor_collect")
    else
        self:TriggerEffects("harvester_collect")
    end
    
    local attached = self:GetAttached()
    
    if attached and attached.CollectResources then
    
        -- reduces the resource count of the node
        attached:CollectResources()
    
    end

end

function ResourceTower:OnResearchComplete(researchId)

    if researchId == kTechId.TransformResources then
    
        for _, player in ipairs(GetEntitiesForTeam("Player", self:GetTeamNumber())) do
            if not player:isa("Commander") then
                player:AddResources(kTransformResourcesRate)
            end
        end
    
    end

end

function ResourceTower:OnSighted(sighted)

    local attached = self:GetAttached()
    if attached and sighted then
        attached.showObjective = true
    end

end

function ResourceTower:GetIsCollecting()
    return GetIsUnitActive(self) and GetGamerules():GetGameStarted()
end

function ResourceTower:OnUpdate(deltaTime)

    ScriptActor.OnUpdate(self, deltaTime)

    if self:GetIsCollecting() then

        if not self.timeLastCollected then
            self.timeLastCollected = Shared.GetTime()
        end

        if self.timeLastCollected + kResourceTowerResourceInterval < Shared.GetTime() then
        
            self:CollectResources()
            self.timeLastCollected = Shared.GetTime()
            
        end
        
    else
        self.timeLastCollected = nil
    end

end
