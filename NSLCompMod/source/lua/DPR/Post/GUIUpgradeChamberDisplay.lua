
local newIndexToUpgrades =
{
    { kTechId.Shell, kTechId.Crush, kTechId.Carapace, kTechId.Regeneration },
    { kTechId.Spur, kTechId.Silence, kTechId.Celerity, kTechId.Adrenaline },
    { kTechId.Veil, kTechId.Vampirism, kTechId.Aura },
}

ReplaceLocals( GUIUpgradeChamberDisplay.Update, {  kIndexToUpgrades = newIndexToUpgrades } )
