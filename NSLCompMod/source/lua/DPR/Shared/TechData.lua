-- remove all Egg drops
local function NSLTechDataChanges(techData)
    -- we don't care about the value as long as it's not nil
    local techToRemove = {
        [kTechId.GorgeEgg] = true,
        [kTechId.LerkEgg] = true,
        [kTechId.FadeEgg] = true,
        [kTechId.OnosEgg] = true
    }

    for techIndex, record in ipairs(techData) do
        local techDataId = record[kTechDataId]

        if techDataId == kTechId.NutrientMist then
            record[kTechDataRequiresInfestation] = true
        elseif techDataId == kTechId.MedPack then
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
