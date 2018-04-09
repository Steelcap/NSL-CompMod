local oldInitTechTree = MarineTeam.InitTechTree
function MarineTeam:InitTechTree()

	oldInitTechTree(self)
	
    self.techTree:AddResearchNode(kTechId.MedTech1,    kTechId.None, kTechId.None)
	self.techTree:AddResearchNode(kTechId.MedTech2,    kTechId.MedTech1, kTechId.None)
	
	self.techTree:SetComplete()
	-- re-enable it here
end