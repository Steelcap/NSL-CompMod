local function NSLTechDataChanges(techData)
    local techToRemove = {
        -- remove lifeform Egg drops
        [kTechId.GorgeEgg] = true,
        [kTechId.LerkEgg] = true,
        [kTechId.FadeEgg] = true,
        [kTechId.OnosEgg] = true
    }

    for techIndex, record in ipairs(techData) do
        local techDataId = record[kTechDataId]

        if techDataId == kTechId.NutrientMist then
            -- nutrient mist requires infestation to place
            record[kTechDataRequiresInfestation] = true
        elseif techDataId == kTechId.Silence then
            -- silence is on shade hive
            record[kTechDataCategory] = kTechId.ShadeHive
        elseif techDataId == kTechId.Vampirism then
            -- vampirism is on shift hive
            record[kTechDataCategory] = kTechId.ShiftHive
        elseif techDataId == kTechId.MedPack then
            -- medpack auto-snap radius changed
            record[kCommanderSelectRadius] = 0.1
        else
            if techToRemove[techDataId] then
                table.remove(techData, techIndex)
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
