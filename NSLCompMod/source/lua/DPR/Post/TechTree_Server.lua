local upgradeToRemove = {
    -- Remove lifeform egg drops
    [kTechId.GorgeEgg] = true,
    [kTechId.LerkEgg] = true,
    [kTechId.FadeEgg] = true,
    [kTechId.OnosEgg] = true,
}

local oldAddUpgradeNode = TechTree.AddUpgradeNode
function TechTree:AddUpgradeNode(techId, prereq1, prereq2)
    if upgradeToRemove[techId] then
        return
    else
        oldAddUpgradeNode(self, techId, prereq1, prereq2)
    end
end

local researchToRemove = {

}

local researchToChange = {

}

local oldAddResearchNode = TechTree.AddResearchNode
function TechTree:AddResearchNode(techId, prereq1, prereq2, addOnTechId)
    if researchToRemove[techId] then
        return
    elseif researchToChange[techId] then
        local changedNode = researchToChange[techId]

        oldAddResearchNode(self, changedNode[1], changedNode[2], changedNode[3], changedNode[4])
    else
        oldAddResearchNode(self, techId, prereq1, prereq2, addOnTechId)
    end
end

local targetedActivationToChange = {
}

local oldAddTargetedActivation = TechTree.AddTargetedActivation
function TechTree:AddTargetedActivation(techId, prereq1, prereq2)
    if targetedActivationToChange[techId] then
        local changedNode = targetedActivationToChange[techId]

        oldAddTargetedActivation(self, changedNode[1], changedNode[2], changedNode[3])
    else
        oldAddTargetedActivation(self, techId, prereq1, prereq2)
    end
end

local buyToRemove = {
    -- Remove Focus and Silence
    [kTechId.Focus] = true,
	[kTechId.Silence] =true,
}

local buyToChange = {
}

local oldAddBuyNode = TechTree.AddBuyNode
function TechTree:AddBuyNode(techId, prereq1, prereq2, addOnTechId)
    if buyToRemove[techId] then
        return
    elseif buyToChange[techId] then
        local changedNode = buyToChange[techId]

        oldAddBuyNode(self, changedNode[1], changedNode[2], changedNode[3], changedNode[4])
    else
        oldAddBuyNode(self, techId, prereq1, prereq2, addOnTechId)
    end
end