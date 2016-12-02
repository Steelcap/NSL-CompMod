
-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\TunnelEntrance.lua
--
--    Created by:   Andreas Urwalek (andi@unknownworlds.com)
--
--    Entrance to a gorge tunnel. A "GorgeTunnel" entity is created once both entrances are completed.
--    In case both tunnel entrances are destroyed, the tunnel will collapse.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/AchievementGiverMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/CloakableMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/DetectableMixin.lua")
Script.Load("lua/InfestationTrackerMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/ConstructMixin.lua")
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/FireMixin.lua")
Script.Load("lua/SleeperMixin.lua")
Script.Load("lua/CatalystMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/UmbraMixin.lua")
Script.Load("lua/MaturityMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")
Script.Load("lua/ObstacleMixin.lua")
Script.Load("lua/DigestMixin.lua")
Script.Load("lua/InfestationMixin.lua")
Script.Load("lua/TeleportMixin.lua")

Script.Load("lua/Tunnel.lua")

class 'TunnelEntrance' (ScriptActor)

TunnelEntrance.kMapName = "tunnelentrance"

local kDigestDuration = 1.5
local kTunnelInfestationRadius = 7

TunnelEntrance.kModelName = PrecacheAsset("models/alien/tunnel/mouth.model")
TunnelEntrance.kModelNameShadow = PrecacheAsset("models/alien/tunnel/mouth_shadow.model")
local kAnimationGraph = PrecacheAsset("models/alien/tunnel/mouth.animation_graph")

local networkVars = { 
    connected = "boolean",
    beingUsed = "boolean",
    timeLastExited = "time",
    ownerId = "entityid",
    allowDigest = "boolean",
    destLocationId = "entityid",
    --otherSideInfested = "boolean"
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ClientModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(FlinchMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(CloakableMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(DetectableMixin, networkVars)
AddMixinNetworkVars(ConstructMixin, networkVars)
AddMixinNetworkVars(ObstacleMixin, networkVars)
AddMixinNetworkVars(CatalystMixin, networkVars)
AddMixinNetworkVars(UmbraMixin, networkVars)
AddMixinNetworkVars(FireMixin, networkVars)
AddMixinNetworkVars(MaturityMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(InfestationMixin, networkVars)
AddMixinNetworkVars(TeleportMixin, networkVars)

local function UpdateInfestationStatus(self)

    local wasOnInfestation = self.onNormalInfestation
    self.onNormalInfestation = false
    
    local origin = self:GetOrigin()
    -- use hives and cysts as "normal" infestation
    local infestationEnts = GetEntitiesForTeamWithinRange("Hive", self:GetTeamNumber(), origin, 25)
    table.copy(GetEntitiesForTeamWithinRange("Cyst", self:GetTeamNumber(), origin, 25), infestationEnts, true)
    
    -- update own infestation status
    for i = 1, #infestationEnts do
    
        if infestationEnts[i]:GetIsPointOnInfestation(origin) then
            self.onNormalInfestation = true
            break
        end
    
    end
    
    local otherSideInfested = false
    local tunnel = self:GetTunnelEntity()
    
    if tunnel then
    
        local exitA = tunnel:GetExitA()
        local exitB = tunnel:GetExitB()
        local otherSide = (exitA and exitA ~= self) and exitA or exitB
        otherSideInfested = (otherSide and otherSide.onNormalInfestation) and true or false
        
    end
        
    if otherSideInfested ~= self.otherSideInfested then
    
        self.otherSideInfested = otherSideInfested
        self:SetDesiredInfestationRadius(self:GetInfestationMaxRadius())
    
    end

    return true

end

function TunnelEntrance:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, FlinchMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, PointGiverMixin)
    InitMixin(self, AchievementGiverMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, CloakableMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, DetectableMixin)
    InitMixin(self, ConstructMixin)
    InitMixin(self, ObstacleMixin)    
    InitMixin(self, FireMixin)
    InitMixin(self, CatalystMixin)  
    InitMixin(self, UmbraMixin)
    InitMixin(self, MaturityMixin)
    InitMixin(self, CombatMixin)
    InitMixin(self, DigestMixin)
    InitMixin(self, InfestationMixin)
    InitMixin(self, TeleportMixin)
    
    if Server then
    
        InitMixin(self, InfestationTrackerMixin)
        self.connected = false
        self.tunnelId = Entity.invalidId
        
    elseif Client then
        InitMixin(self, CommanderGlowMixin)     
    end
    
    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.BigStructuresGroup)
    
    self.timeLastInteraction = 0
    self.timeLastExited = 0
    self.destLocationId = Entity.invalidId
    --self.otherSideInfested = false
    
end

function TunnelEntrance:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    self:SetModel(TunnelEntrance.kModelName, kAnimationGraph)
    
    if Server then
    
        InitMixin(self, StaticTargetMixin)
        InitMixin(self, SleeperMixin)
        
        -- This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
        self.onNormalInfestation = false
        --self:AddTimedCallback(UpdateInfestationStatus, 1)
		Print("New Tunnel Code is In")
        self:UpdateIncludeRelevancyMask()
		
    elseif Client then
    
        InitMixin(self, UnitStatusMixin)
        InitMixin(self, HiveVisionMixin)
        
    end

end

function TunnelEntrance:OnDestroy()

    ScriptActor.OnDestroy(self)
    
    if Client then
    
        Client.DestroyRenderDecal(self.decal)
        self.decal = nil
        
    end
    
end

function TunnelEntrance:SetVariant(gorgeVariant)

    if gorgeVariant == kGorgeVariant.shadow then
        self:SetModel(TunnelEntrance.kModelNameShadow, kAnimationGraph)
    else
        self:SetModel(TunnelEntrance.kModelName, kAnimationGraph)
    end
    
end

function TunnelEntrance:GetInfestationRadius()
    return kTunnelInfestationRadius
end

function TunnelEntrance:GetInfestationMaxRadius()
    return kTunnelInfestationRadius -- self.otherSideInfested and kTunnelInfestationRadius or 0
end

if not Server then
    function TunnelEntrance:GetOwner()
        return self.ownerId ~= nil and Shared.GetEntity(self.ownerId)
    end
end

function TunnelEntrance:GetOwnerClientId()
    return self.ownerClientId
end

function TunnelEntrance:GetDigestDuration()
    return kDigestDuration
end

function TunnelEntrance:GetCanDigest(player)
    return self.allowDigest and player == self:GetOwner() and player:isa("Gorge") and (not HasMixin(self, "Live") or self:GetIsAlive())
end

function TunnelEntrance:SetOwner(owner)

    if owner and not self.ownerClientId then
    
        local client = Server.GetOwner(owner)    
        self.ownerClientId = client:GetUserId()

        if Server then
            self:UpdateConnectedTunnel()
        end
    
        if self.tunnelId and self.tunnelId ~= Entity.invalidId then
        
            local tunnelEnt = Shared.GetEntity(self.tunnelId)
            tunnelEnt:SetOwnerClientId(self.ownerClientId)
        
        end

    end
    
end
function TunnelEntrance:GetCanAutoBuild()
    return self:GetGameEffectMask(kGameEffect.OnInfestation)
end

function TunnelEntrance:GetReceivesStructuralDamage()
    return true
end

function TunnelEntrance:GetMaturityRate()
    return kTunnelEntranceMaturationTime
end

function TunnelEntrance:GetMatureMaxHealth()
    return kMatureTunnelEntranceHealth
end 

function TunnelEntrance:GetMatureMaxArmor()
    return kMatureTunnelEntranceArmor
end 

function TunnelEntrance:GetIsWallWalkingAllowed()
    return false
end

function TunnelEntrance:GetDamagedAlertId()
    return kTechId.AlienAlertStructureUnderAttack
end

function TunnelEntrance:GetCanSleep()
    return true
end

function TunnelEntrance:GetTechButtons(techId)
    return {}
end

function TunnelEntrance:GetIsConnected()
    return self.connected
end

function TunnelEntrance:Interact()

    self.beingUsed = true
    self.clientBeingUsed = true
    self.timeLastInteraction = Shared.GetTime()
    
end

if Server then

	function TunnelEntrance:UpdateIncludeRelevancyMask()
		includeMask = Math.infinity
		self:SetIncludeRelevancyMask(includeMask)
	end
	
    function TunnelEntrance:OnTeleportEnd()
    
        local tunnel = Shared.GetEntity(self.tunnelId)
        if tunnel then
            tunnel:UpdateExit(self)
        end
        
        self:SetInfestationRadius(0)
        
    end

    local function ComputeDestinationLocationId(self)
    
        local destLocationId = Entity.invalidId
        
        if self.connected then
        
            local tunnel = Shared.GetEntity(self.tunnelId)
            local exitA = tunnel:GetExitA()
            local exitB = tunnel:GetExitB()
            local oppositeExit = ((exitA and exitA ~= self) and exitA) or ((exitB and exitB ~= self) and exitB)
            
            if oppositeExit then
                local location = GetLocationForPoint(oppositeExit:GetOrigin())
                if location then
                    destLocationId = location:GetId()
                end       
            end
        
        end
        
        return destLocationId
    
    end

    function TunnelEntrance:OnUpdate(deltaTime)

        ScriptActor.OnUpdate(self, deltaTime)    

        local tunnel = self:GetTunnelEntity()
    
        self.connected = tunnel ~= nil and not tunnel:GetIsDeadEnd()
        self.beingUsed = self.timeLastInteraction + 0.1 > Shared.GetTime()  
        self.destLocationId = ComputeDestinationLocationId(self)
        
        -- temp fix: push AI units away to prevent players getting stuck
        if self:GetIsAlive() and ( not self.timeLastAIPushUpdate or self.timeLastAIPushUpdate + 1.4 < Shared.GetTime() ) then
        
            local baseYaw = 0
            self.timeLastAIPushUpdate = Shared.GetTime()

            for i, entity in ipairs(GetEntitiesWithMixinWithinRange("Repositioning", self:GetOrigin(), 1.4)) do
            
                if entity:GetCanReposition() then
                
                    entity.isRepositioning = true
                    entity.timeLeftForReposition = 1
                    
                    baseYaw = entity:FindBetterPosition( GetYawFromVector(entity:GetOrigin() - self:GetOrigin()), baseYaw, 0 )
                    
                    if entity.RemoveFromMesh ~= nil then
                        entity:RemoveFromMesh()
                    end
                    
                end
            
            end
        
        end
        
        local destructionAllowedTable = { allowed = true }
        if self.GetDestructionAllowed then
            self:GetDestructionAllowed(destructionAllowedTable)
        end
        
        if destructionAllowedTable.allowed then
            DestroyEntity(self)
        end

    end

    function TunnelEntrance:GetTunnelEntity()
    
        if self.tunnelId and self.tunnelId ~= Entity.invalidId then
            return Shared.GetEntity(self.tunnelId)
        end
    
    end

    function TunnelEntrance:UpdateConnectedTunnel()

        local hasValidTunnel = self.tunnelId ~= nil and Shared.GetEntity(self.tunnelId) ~= nil

        if hasValidTunnel or self:GetOwnerClientId() == nil or not self:GetIsBuilt() then
            return
        end

        local foundTunnel = nil
        
        -- register if a tunnel entity already exists or a free tunnel has been found
        for index, tunnel in ientitylist( Shared.GetEntitiesWithClassname("Tunnel") ) do
        
            if tunnel:GetOwnerClientId() == self:GetOwnerClientId() then
                
                foundTunnel = tunnel
                break
                
            elseif not foundTunnel and not tunnel:GetOwnerClientId() then
                
                foundTunnel = tunnel
                
            end
            
        end
        
        if not foundTunnel then
            -- no tunnel entity present
            foundTunnel = CreateEntity(Tunnel.kMapName, nil, self:GetTeamNumber())
        end
        
        -- check if there is another tunnel entrance to connect with
        foundTunnel:SetOwnerClientId(self:GetOwnerClientId()) 
        foundTunnel:AddExit(self)
        self.tunnelId = foundTunnel:GetId()

    end

    function TunnelEntrance:OnConstructionComplete()
        self:UpdateConnectedTunnel()
    end
    
    function TunnelEntrance:OnKill(attacker, doer, point, direction)

        ScriptActor.OnKill(self, attacker, doer, point, direction)
        self:TriggerEffects("death")
        self:SetModel(nil)
        
        local team = self:GetTeam()
        if team then
            team:UpdateClientOwnedStructures(self:GetId())
        end
        
        local tunnel = Shared.GetEntity(self.tunnelId)
        if tunnel then
            tunnel:RemoveExit(self)
        end
    
    end  

end

function TunnelEntrance:GetHealthbarOffset()
    return 1
end

function TunnelEntrance:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = self.connected and useSuccessTable.useSuccess and self:GetCanDigest(player)  
end

function TunnelEntrance:GetCanBeUsedConstructed()
    return true
end

if Server then

    function TunnelEntrance:SuckinEntity(entity)
    
        if entity and HasMixin(entity, "TunnelUser") and self.tunnelId then
        
            local tunnelEntity = Shared.GetEntity(self.tunnelId)
            if tunnelEntity then
            
                tunnelEntity:MovePlayerToTunnel(entity, self)
                entity:SetVelocity(Vector(0, 0, 0))
                
                if entity.OnUseGorgeTunnel then
                    entity:OnUseGorgeTunnel()
                end

            end
            
        end
    
    end
    
    function TunnelEntrance:OnEntityExited(entity)
        self.timeLastExited = Shared.GetTime()
        self:TriggerEffects("tunnel_exit_3D")
    end

end   

function TunnelEntrance:OnUpdateAnimationInput(modelMixin)

    local sucking = self.beingUsed or (self.clientBeingUsed and self.timeLastInteraction and self.timeLastInteraction + 0.1 > Shared.GetTime())
    -- sucking will be nil when self.clientBeingUsed is nil. Handle this case here.
    sucking = sucking or false

    modelMixin:SetAnimationInput("open", self.connected)
    modelMixin:SetAnimationInput("player_in", sucking)
    modelMixin:SetAnimationInput("player_out", self.timeLastExited + 0.2 > Shared.GetTime())
    
end

function TunnelEntrance:GetEngagementPointOverride()
    return self:GetOrigin() + Vector(0, 0.25, 0)
end

function TunnelEntrance:OnUpdateRender()

    local showDecal = self:GetIsVisible() and not self:GetIsCloaked() and self:GetIsAlive()

    if not self.decal and showDecal then
        self.decal = CreateSimpleInfestationDecal(1.9, self:GetCoords())
    elseif self.decal and not showDecal then
        Client.DestroyRenderDecal(self.decal)
        self.decal = nil
    end

end


function TunnelEntrance:GetDestinationLocationName()

    local location = Shared.GetEntity(self.destLocationId)   
    if location then
        return location:GetName()
    end
    
end


function TunnelEntrance:GetUnitNameOverride(viewer)

    local unitName = GetDisplayName(self)    
    
    if not GetAreEnemies(self, viewer) and self.ownerId then        
        local ownerName
        for _, playerInfo in ientitylist(Shared.GetEntitiesWithClassname("PlayerInfoEntity")) do
            if playerInfo.playerId == self.ownerId then
                ownerName = playerInfo.playerName
                break
            end
        end
        if ownerName then
            
            local lastLetter = ownerName:sub(-1)
            if lastLetter == "s" or lastLetter == "S" then
                return string.format( Locale.ResolveString( "TUNNEL_ENTRANCE_OWNER_ENDS_WITH_S" ), ownerName )
            else
                return string.format( Locale.ResolveString( "TUNNEL_ENTRANCE_OWNER" ), ownerName )
            end
        end
        
    end

    return unitName

end

function TunnelEntrance:OverrideHintString( hintString, forEntity )
    
    if not GetAreEnemies(self, forEntity) then
        local locationName = self:GetDestinationLocationName()
        if locationName and locationName~="" then
            return string.format(Locale.ResolveString( "TUNNEL_ENTRANCE_HINT_TO_LOCATION" ), locationName )
        end
    end

    return hintString
    
end

Shared.LinkClassToMap("TunnelEntrance", TunnelEntrance.kMapName, networkVars)