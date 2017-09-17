local techToRemove = {
    -- remove focus
    [kTechId.Focus] = true,
}

local techToMove = {
    -- move silence to shade hive (in focus's spot)
    [kTechId.Silence] = {kTechId.Silence, 6, 5},
    -- move spores to bio 7
    [kTechId.Spores] = {kTechId.Spores, 9, 9}
}

for techIndex = #kAlienTechMap, 1, -1 do
    local techId = kAlienTechMap[techIndex][1]

    if techToRemove[techId] then
        table.remove(kAlienTechMap, techIndex)
    elseif techToMove[techId] then
        kAlienTechMap[techIndex] = techToMove[techId]
    end
end

-- remove focus
-- move silence to veils
kAlienLines = {
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Hive, kTechId.Crag),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Hive, kTechId.Shift),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Hive, kTechId.Shade),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Hive, kTechId.Whip),

    GetLinePositionForTechMap(kAlienTechMap, kTechId.Harvester, kTechId.Hive),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Hive, kTechId.Drifter),

    GetLinePositionForTechMap(kAlienTechMap, kTechId.Hive, kTechId.ShadeHive),
    {4, 2.5, 10, 2.5}, --just above crag hive to just above shift hive
    {4, 2.5, 4, 3}, --just above crag hive to crag hive
    {10, 2.5, 10, 3}, --just above shift hive to shift hive

    GetLinePositionForTechMap(kAlienTechMap, kTechId.CragHive, kTechId.Shell),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.ShadeHive, kTechId.Veil),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.ShiftHive, kTechId.Spur),

    GetLinePositionForTechMap(kAlienTechMap, kTechId.Shell, kTechId.Crush),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Shell, kTechId.Carapace),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Shell, kTechId.Regeneration),

    -- move silence to veil
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Veil, kTechId.Silence),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Veil, kTechId.Vampirism),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Veil, kTechId.Aura),

    GetLinePositionForTechMap(kAlienTechMap, kTechId.Spur, kTechId.Celerity),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Spur, kTechId.Adrenaline),
}
