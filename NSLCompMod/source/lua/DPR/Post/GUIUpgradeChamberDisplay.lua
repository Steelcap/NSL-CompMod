local kIndexToUpgrades = {
    {kTechId.Shell, kTechId.Crush, kTechId.Carapace, kTechId.Regeneration},
    -- Move Vampirism to Spurs
    {kTechId.Spur, kTechId.Vampirism, kTechId.Celerity, kTechId.Adrenaline},
    -- Move Silence to Veils
    -- Remove Focus
    {kTechId.Veil, kTechId.Silence, kTechId.Aura},
}

ReplaceLocals( GUIUpgradeChamberDisplay.Update, {kIndexToUpgrades = kIndexToUpgrades} )
