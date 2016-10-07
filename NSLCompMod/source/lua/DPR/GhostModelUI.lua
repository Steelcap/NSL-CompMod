-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\GhostModelUI.lua
--
--    Created by:   Andreas Urwalek (andi@unknownworlds.com)
--
--
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/UnitStatusMixin.lua")

local gGhostModel = nil
local gLoadedTechId = nil

function LoadGhostModel(className)

    local pathToFile = string.format("lua/Hud/Commander/%s.lua", className)

    if gGhostModel then
        gGhostModel:Destroy()
        gGhostModel = nil
    end
    
    Script.Load(pathToFile)
    local creationFunction = _G[className]

    if creationFunction == nil then
    
        Shared.Message("Error: Failed to load ghostmodel class named " .. className)
        return nil
        
    end

    gGhostModel = creationFunction()
    gGhostModel:Initialize()
	gGhostModel:InitMxin(UnitStatusMixin)
end

function GhostModelUI_GetModelName()

    local player = Client.GetLocalPlayer()
    if player then
    
        local modelName = nil
        if player.GetGhostModelOverride then
            modelName = player:GetGhostModelOverride()
        end
        
        if not modelName and player.GetGhostModelTechId then
            modelName = LookupTechData(player:GetGhostModelTechId(), kTechDataModel)
        end
        
        return modelName
        
    end
    
end

function GhostModelUI_GetNearestAttachPointDirection()

    local player = Client.GetLocalPlayer()
    if player then
    
        local attachClass = LookupTechData(player.currentTechId, kStructureAttachClass)
        if attachClass and player:GetGhostModelCoords() then
        
            local ghostOrigin = player:GetGhostModelCoords().origin
            local nearestAttachEnt = GetNearestFreeAttachEntity(player.currentTechId, ghostOrigin)
            if nearestAttachEnt then
            
                local withinSnapRadius = nearestAttachEnt:GetOrigin():GetDistanceTo(ghostOrigin) <= kStructureSnapRadius
                if not withinSnapRadius then
                    return GetNormalizedVectorXZ(nearestAttachEnt:GetOrigin() - ghostOrigin)
                end
                
            end
            
        end
        
    end
    
    return nil
    
end

function GhostModelUI_GetNearestAttachStructureDirection()

    local player = Client.GetLocalPlayer()
    if player then
    
        local attachId = LookupTechData(player.currentTechId, kStructureAttachId)
        
        -- Handle table of attach ids.
        local supportingTechIds = { }
        if type(attachId) == "table" then
        
            for index, currentAttachId in ipairs(attachId) do
                table.insert(supportingTechIds, currentAttachId)
            end
            
        else
            table.insert(supportingTechIds, attachId)
        end
        
        local ents = GetEntsWithTechIdIsActive(supportingTechIds)
        if #ents > 0 then
        
            local ghostOrigin = player:GetGhostModelCoords().origin
            Shared.SortEntitiesByDistance(ghostOrigin, ents)
            local ghostRadius = LookupTechData(player.currentTechId, kStructureAttachRange, 0)
            if ents[1]:GetOrigin():GetDistanceTo(ghostOrigin) > ghostRadius then
                return GetNormalizedVectorXZ(ents[1]:GetOrigin() - ghostOrigin)
            end
            
        end
        
    end
    
    return nil
    
end

function GhostModelUI_GetCost()

    local player = Client.GetLocalPlayer()
    if player then
    
        if not player.GetGhostModelCost then
            return LookupTechData(player:GetGhostModelTechId(), kTechDataCostKey)
        else    
            return player:GetGhostModelCost()    
        end
        
    end

end

function GhostModelUI_GetGhostModelCoords()

    local player = Client.GetLocalPlayer()
    if player then    
        return player:GetGhostModelCoords()
    end
    
end

function GhostModelUI_GetLastClickedPosition()

    local player = Client.GetLocalPlayer()
    if player then    
        return player:GetLastClickedPosition()
    end
    
end

function GhostModelUI_GetIsValidPlacement()

    local player = Client.GetLocalPlayer()
    if player then    
        return player:GetIsPlacementValid()    
    end

end

local function OnUpdateRenderGhostModel()

    local player = Client.GetLocalPlayer()
    local showGhostModel = false
    if player and player.GetShowGhostModel then
        showGhostModel = player:GetShowGhostModel()
    end
    
    local techId = player and player.GetGhostModelTechId and player:GetGhostModelTechId()
    
    if showGhostModel and techId then

        if gLoadedTechId ~= techId then
            LoadGhostModel(LookupTechData(techId, kTechDataGhostModelClass, "GhostModel") )
            gLoadedTechId = techId
        end

        gGhostModel:Update()

    else

        if gGhostModel then
        
            gGhostModel:Destroy()
            gGhostModel = nil
            gLoadedTechId = nil
            
        end

    end  
        
end

function gGhostModel:OverrideHintString( hintString, forEntity )

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


Event.Hook("UpdateRender", OnUpdateRenderGhostModel)