-- remove all Egg drops
local function NSLTechDataChanges(techData)
    -- we don't care about the value as long as it's not nil
    local techToRemove = {
        [kTechId.GorgeEgg] = true,
        [kTechId.LerkEgg] = true,
        [kTechId.FadeEgg] = true,
        [kTechId.OnosEgg] = true,
		[kTechId.Silence] = true,
		[kTechId.Focus] = true
    }

    for techIndex, record in ipairs(techData) do
        local techDataId = record[kTechDataId]
		if techDataId == kTechId.Observatory then
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
