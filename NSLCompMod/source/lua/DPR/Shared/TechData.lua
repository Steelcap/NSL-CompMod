local function NSLTechDataChanges(techData)
    local techToRemove = {"GorgeEgg", "LerkEgg", "FadeEgg", "OnosEgg", 
                            "Focus"}

    for techIndex, record in ipairs(techData) do
        local techDataId = record[kTechDataId]

        if techDataId == kTechId.Silence then
            record[kTechDataCategory] = kTechId.ShadeHive
        elseif techDataId == kTechId.NutrientMist then
            record[kTechDataRequiresInfestation] = true
        elseif techDataId == kTechId.MedPack then
            record[kCommanderSelectRadius] = 0.1
        else
            for removeIndex, removeTech in ipairs(techToRemove) do
                if techDataId == kTechId[removeTech] then
                    table.remove(techData, techIndex)
                    table.remove(techToRemove, removeIndex)
                    break
                end
            end
        end
    end
end

local oldBuildTechData = BuildTechData
function BuildTechData()
    local techData = oldBuildTechData()
    NSLTechDataChanges(techData)
    return techData
end
