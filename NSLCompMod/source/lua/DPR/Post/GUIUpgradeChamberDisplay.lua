local kIndexToUpgrades = {
    {kTechId.Shell, kTechId.Crush, kTechId.Carapace, kTechId.Regeneration},
    {kTechId.Spur, kTechId.Celerity, kTechId.Adrenaline},
    -- Move Silence to Veils
    -- Remove Focus
    {kTechId.Veil, kTechId.Vampirism, kTechId.Aura, kTechId.Silence},
}

ReplaceLocals( GUIUpgradeChamberDisplay.Update, {kIndexToUpgrades = kIndexToUpgrades} )
