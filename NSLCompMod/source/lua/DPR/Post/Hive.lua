local oldGetTechButtons = Hive.GetTechButtons
function Hive:GetTechButtons()
    local techButtons = oldGetTechButtons(self)

    if techButtons[2] == kTechId.ResearchBioMassThree then
        techButtons[2] = kTechId.None
    end

    return techButtons
end
