function Egg:GetTechButtons(techId)

    local techButtons = { kTechId.SpawnAlien, kTechId.None, kTechId.None, kTechId.None,
                          kTechId.None, kTechId.None, kTechId.None, kTechId.None }

    -- if self:GetTechId() == kTechId.Egg then
        -- techButtons = { kTechId.SpawnAlien, kTechId.None, kTechId.None, kTechId.None,
                        -- kTechId.GorgeEgg, kTechId.LerkEgg, kTechId.FadeEgg, kTechId.OnosEgg }
    -- end

    return techButtons

end