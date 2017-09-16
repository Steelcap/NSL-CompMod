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
    -- Move Vampirism to Spurs
    [kTechId.Vampirism] = {kTechId.Vampirism, kTechId.Spur, kTechId.None, kTechId.AllAliens}
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
