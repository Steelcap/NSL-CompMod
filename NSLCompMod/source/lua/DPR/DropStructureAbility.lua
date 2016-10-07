
function DropStructureAbility:OverrideHintString( hintString, forEntity )

    local player = self:GetOwner()
	local team = player:GetTeam()
	
	local numTunnels = team:GetNumDroppedGorgeStructures(player, kTechId.GorgeTunnel)
	
    if numTunnels >= 2 then
	
		local tunnels = team:GetTunnelList(player)
		if tunnels then
			local structure = nil
			local skip = true
			if techId == kTechId.GorgeTunnel and player and player:GetCrouching() then
				skip = false
			end
			
			for index, id in ipairs(tunnels)  do
			
				if id and not skip then
				
					removeIndex = index
					structure = Shared.GetEntity(id)
					break
					
				else
					skip = false
				end
				
			end
			
			local locationName = structure:GetDestinationLocationName()
			if locationName and locationName~="" then
				return string.format(Locale.ResolveString( "TUNNEL_ENTRANCE_HINT_TO_LOCATION" ), locationName )
			end
		end
    end

    return hintString
    
end

function DropStructureAbility:GetDestinationLocationName()

    local location = Shared.GetEntity(self.destLocationId)   
    if location then
        return location:GetName()
    end
    
end


local function GetTunnelList(player)
	
	if not player then
		return nil
	end

	local clientId = Server.GetOwner(player):GetUserId()
	local team = player:GetTeam()
	local COS = team:ClientOwnedStructures()
	local structureTypeTable = COS[clientId]
	
	return structureTypeTable[kTechId.GorgeTunnel]
end
