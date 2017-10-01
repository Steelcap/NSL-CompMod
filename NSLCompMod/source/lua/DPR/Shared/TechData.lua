local function NSLTechDataChanges(techData)
    local techToRemove = {
        -- remove lifeform Egg drops
        [kTechId.GorgeEgg] = true,
        [kTechId.LerkEgg] = true,
        [kTechId.FadeEgg] = true,
        [kTechId.OnosEgg] = true,
        -- remove Focus
        [kTechId.Focus] = true,
    }

    for techIndex = #techData, 1, -1 do
        local record = techData[techIndex]
        local techDataId = record[kTechDataId]

        if techDataId == kTechId.NutrientMist then
            -- nutrient mist requires infestation to place
            record[kTechDataRequiresInfestation] = true
        elseif techDataId == kTechId.Silence then
            -- silence is on shade hive
            record[kTechDataCategory] = kTechId.ShadeHive
        elseif techDataId == kTechId.MedPack then
            -- medpack auto-snap radius changed
            record[kCommanderSelectRadius] = 0.1
        elseif techDataId == kTechId.Observatory then
            -- observatory has a supply cost
            record[kTechDataSupply] = kObservatorySupply
        elseif techDataId == kTechId.SentryBattery then
            -- sentry battery has a supply cost
            record[kTechDataSupply] = kSentryBatterySupply
        elseif techToRemove[techDataId] then
            table.remove(techData, techIndex)
        end
    end
end

local oldBuildTechData = BuildTechData
function BuildTechData()
    local techData = oldBuildTechData()
    NSLTechDataChanges(techData)
    return techData
end
