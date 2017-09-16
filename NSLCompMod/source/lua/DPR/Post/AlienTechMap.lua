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
