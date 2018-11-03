local oldInitTechTree = MarineTeam.InitTechTree
function MarineTeam:InitTechTree()

	oldInitTechTree(self)
	
    self.techTree:AddResearchNode(kTechId.MedTech1,    kTechId.Armory, kTechId.None)
	self.techTree:AddResearchNode(kTechId.MedTech2,    kTechId.MedTech1, kTechId.AdvancedArmory)
	
	self.techTree:AddActivation(kTechId.ARCSpeedBoost)  

	self.techTree:SetComplete()
	-- re-enable it here
end