-- move spores to bio 7
local techToMove = {
    [kTechId.Spores] = {kTechId.Spores, 8, 9}
}

for techIndex, record in ipairs(kAlienTechMap) do
    local techId = record[1]

    if techToMove[techId] then
        kAlienTechMap[techIndex] = techToMove[techId]
    end
end
