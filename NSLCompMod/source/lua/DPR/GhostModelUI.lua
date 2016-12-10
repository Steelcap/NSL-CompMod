
function NewGhostModelUI_GetTunnelName()
	
	local player = Client.GetLocalPlayer()

	if player and player.GetGhostModelTechId and player:GetGhostModelTechId() == kTechId.GorgeTunnel and not player:GetCrouching() then
		return "Crouch while building to preserve the oldest entrance"
	end
    return ""
end

function GhostModelUI_GetTunnelName()
	
	local player = Client.GetLocalPlayer()

	if player and player.GetGhostModelTechId and player:GetGhostModelTechId() == kTechId.GorgeTunnel then
		local tunnels = {}
		local entlist =  EntityListToTable(Shared.GetEntitiesWithClassname("TunnelEntrance"))
		for i = 0, #entlist do
			local ent = entlist[i]
			if ent and ent.GetOwner and ent:GetOwner() == player then
				tunnels[#tunnels+1] = ent
			end
		end
		
		local structure = nil
		
		if tunnels and #tunnels >= 2 then
			local skip = false
			if player:GetCrouching() then
				skip = true
			end
			for i = 1, #tunnels  do	
				local ent = tunnels[i]
				if ent then 
					if not skip then
						structure = ent
						break
					else
						skip = false
					end
				end
			end
		end
		
		if structure then
			local locationName = structure:GetDestinationLocationName()
			if locationName and locationName~="" then
				return string.format(Locale.ResolveString( "TUNNEL_ENTRANCE_HINT_TO_LOCATION" ), locationName )
				
			end
		else
			return "Crouch while building to preserve the oldest entrance"
		end

	end
    return ""
end
