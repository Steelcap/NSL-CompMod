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
    -- Remove PowerSurge research
    [kTechId.PowerSurgeTech] = true
}

local researchToChange = {
    -- Move Spores to bio 7
    [kTechId.Spores] = {kTechId.Spores, kTechId.BioMassSeven, kTechId.None, kTechId.AllAliens}
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
    -- Move PowerSurge to robo
    [kTechId.PowerSurge] = {kTechId.PowerSurge, kTechId.RoboticsFactory}
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
    -- Remove Focus
    [kTechId.Focus] = true,
}

local buyToChange = {
    -- Move Silence to Veils
    [kTechId.Silence] = {kTechId.Silence, kTechId.Veil, kTechId.None, kTechId.AllAliens},
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

local buildToChange = {
    -- Move Contamination to bio 9
    [kTechId.Contamination] = {kTechId.Contamination, kTechId.BioMassNine},
}

local oldAddBuildNode = TechTree.AddBuildNode
function TechTree:AddBuildNode(techId, prereq1, prereq2, isRequired)
    if buildToChange[techId] then
        local changedNode = buildToChange[techId]

        oldAddBuildNode(self, changedNode[1], changedNode[2], changedNode[3], changedNode[4])
    else
        oldAddBuildNode(self, techId, prereq1, prereq2, isRequired)
    end
end
