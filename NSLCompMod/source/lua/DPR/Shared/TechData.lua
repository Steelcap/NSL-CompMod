-- remove all Egg drops
local function NSLTechDataChanges(techData)
    -- we don't care about the value as long as it's not nil
    local techToRemove = {
        [kTechId.GorgeEgg] = true,
        [kTechId.LerkEgg] = true,
        [kTechId.FadeEgg] = true,
        [kTechId.OnosEgg] = true,
		[kTechId.Silence] = true
    }

    for techIndex, record in ipairs(techData) do
        local techDataId = record[kTechDataId]
		if techDataId == kTechId.Observatory then
            -- observatory has a supply cost
            record[kTechDataSupply] = kObservatorySupply
        elseif techDataId == kTechId.SentryBattery then
            -- sentry battery has a supply cost
            record[kTechDataSupply] = kSentryBatterySupply
		elseif techDataId == kTechId.Focus then
			-- focus is now neurotoxin
			record[kTechDataDisplayName] = "NEUROTOXIN"
			record[kTechDataTooltipInfo] = "Each hit inflicts a poison toxin, hurting marines over time."
		elseif techToRemove[techDataId] then
			table.remove(techData, techIndex)
		end
    end

end

local oldBuildTechData = BuildTechData
function BuildTechData()
    local techData = oldBuildTechData()
    NSLTechDataChanges(techData)
		
	local medtech1 = { [kTechDataId] = kTechId.MedTech1,       [kTechDataDisplayName] = "Medpack Tech 1", [kTechDataTooltipInfo] = "Improves Medpacks", [kTechDataCostKey] = kTechMed1ResearchCost,             [kTechDataResearchTimeKey] = kTechMed1ResearchTime, }
	local medtech2 = { [kTechDataId] = kTechId.MedTech2,       [kTechDataDisplayName] = "Medpack Tech 2", [kTechDataTooltipInfo] = "Improves Medpacks", [kTechDataCostKey] = kTechMed2ResearchCost,             [kTechDataResearchTimeKey] = kTechMed2ResearchTime, }
	table.insert(techData, medtech1)
	table.insert(techData, medtech2)
    return techData
end
