local techToMove = {
    -- swap silence and vampirism
    [kTechId.Silence] = {kTechId.Silence, 7, 5},
    [kTechId.Vampirism] = {kTechId.Vampirism, 9, 5},
    -- move spores to bio 7
    [kTechId.Spores] = {kTechId.Spores, 9, 9}
}

for techIndex = #kAlienTechMap, 1, -1 do
    local techId = kAlienTechMap[techIndex][1]

    if techToMove[techId] then
        kAlienTechMap[techIndex] = techToMove[techId]
    end
end
