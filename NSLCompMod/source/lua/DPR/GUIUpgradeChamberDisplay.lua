
local newIndexToUpgrades =
{
    { kTechId.Shell, kTechId.Crush, kTechId.Carapace, kTechId.Regeneration },
    { kTechId.Spur,  kTechId.Celerity, kTechId.Adrenaline },
    { kTechId.Veil, kTechId.Vampirism, kTechId.Aura, kTechId.Silence, },
}

ReplaceLocals( GUIUpgradeChamberDisplay.Update, {  kIndexToUpgrades = newIndexToUpgrades } )
