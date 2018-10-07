-- move spores to bio 6
-- move boneshield to bio 4
local techToMove = {
    [kTechId.Spores] = {kTechId.Spores, 8, 8},
    [kTechId.BoneShield] = {kTechId.BoneShield, 6, 9} 
}

for techIndex, record in ipairs(kAlienTechMap) do
    local techId = record[1]

    if techToMove[techId] then
        kAlienTechMap[techIndex] = techToMove[techId]
    end
end
