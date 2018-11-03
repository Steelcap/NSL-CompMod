local function NSLTechDataChanges(techData)
    local techToRemove = {
        -- remove lifeform Egg drops
        [kTechId.GorgeEgg] = true,
        [kTechId.LerkEgg] = true,
        [kTechId.FadeEgg] = true,
        [kTechId.OnosEgg] = true
    }

    for techIndex = #techData, 1, -1 do
        local record = techData[techIndex]
        local techDataId = record[kTechDataId]
		if techDataId == kTechId.Observatory then
            -- observatory has a supply cost
            record[kTechDataSupply] = kObservatorySupply
        elseif techDataId == kTechId.SentryBattery then
            -- sentry battery has a supply cost
            record[kTechDataSupply] = kSentryBatterySupply
		elseif techDataId == kTechId.Focus then
			-- focus is now neurotoxin
			record[kTechDataDisplayName] = "Neurotoxin"
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
		
	local medtech1 = { 
        [kTechDataId] = kTechId.MedTech1,
        [kTechDataDisplayName] = "Medpack Upgrade #1", 
        [kTechDataTooltipInfo] = "Improves Medpacks to 30 instant heal and 20 regen", 
        [kTechDataCostKey] = kTechMed1ResearchCost,             
        [kTechDataResearchTimeKey] = kTechMed1ResearchTime
    }

	local medtech2 = { 
        [kTechDataId] = kTechId.MedTech2,       
        [kTechDataDisplayName] = "Medpack Upgrade #2", 
        [kTechDataTooltipInfo] = "Improves Medpacks to 40 instant heal and 10 regen", 
        [kTechDataCostKey] = kTechMed2ResearchCost,             
        [kTechDataResearchTimeKey] = kTechMed2ResearchTime
    }

    local arcspeedboost = {    
        [kTechDataId] = kTechId.ARCSpeedBoost,      
        [kTechDataCostKey] = kARCSpeedBoostCost,  
        [kTechDataDisplayName] = "ARC Speed Boost",
        [kTechDataTooltipInfo] =  [[ARC Speed Boost:  Temporarily increases the movement speed of this ARC by 20% for ]] .. ToString(kARCSpeedBoostDuration) .. "s seconds, also makes ARC immune to damage slowdown." 
    }

	table.insert(techData, medtech1)
	table.insert(techData, medtech2)
    table.insert(techData, arcspeedboost)    
    return techData
end
