-- ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Cyst.lua
--
--    Created by:   Mats Olsson (mats.olsson@matsotech.se)
--
-- A cyst controls and spreads infestation
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/SleeperMixin.lua")
Script.Load("lua/FireMixin.lua")
Script.Load("lua/UmbraMixin.lua")
Script.Load("lua/MaturityMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/AchievementGiverMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/CatalystMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/CloakableMixin.lua")
Script.Load("lua/DetectableMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/ConstructMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")
Script.Load("lua/SpawnBlockMixin.lua")
Script.Load("lua/IdleMixin.lua")

Script.Load("lua/CommAbilities/Alien/EnzymeCloud.lua")
Script.Load("lua/CommAbilities/Alien/Rupture.lua")

class 'Cyst' (ScriptActor)

Cyst.kMaxEncodedPathLength = 30
Cyst.kMapName = "cyst"
Cyst.kModelName = PrecacheAsset("models/alien/cyst/cyst.model")

Cyst.kAnimationGraph = PrecacheAsset("models/alien/cyst/cyst.animation_graph")

Cyst.kEnergyCost = 25
Cyst.kPointValue = 5
-- how fast the impulse moves
Cyst.kImpulseSpeed = 8

Cyst.kThinkInterval = 1 
Cyst.kImpulseColor = Color(1,1,0)
Cyst.kImpulseLightIntensity = 8
local kImpulseLightRadius = 1.5

Cyst.kExtents = Vector(0.2, 0.1, 0.2)

Cyst.kBurstDuration = 3

-- range at which we can be a parent
Cyst.kCystMaxParentRange = kCystMaxParentRange

-- size of infestation patch
Cyst.kInfestationRadius = kInfestationRadius
Cyst.kInfestationGrowthDuration = Cyst.kInfestationRadius / kCystInfestDuration

-- how many seconds before a fully mature cyst, disconnected, becomes fully immature again.
Cyst.kMaturityLossTime = 15

-- cyst infestation spreads/recedes faster
Cyst.kInfestationRateMultiplier = 3

local networkVars =
{

    -- Since cysts don't move, we don't need the fields to be lag compensated
    -- or delta encoded
    m_origin = "position (by 0.05 [], by 0.05 [], by 0.05 [])",
    m_angles = "angles (by 0.1 [], by 10 [], by 0.1 [])",
    
    -- Cysts are never attached to anything, so remove the fields inherited from Entity
    m_attachPoint = "integer (-1 to 0)",
    m_parentId = "integer (-1 to 0)",
    
    -- Track our parentId
    parentId = "entityid",
    hasChild = "boolean",
    
    -- if we are connected. Note: do NOT use on the server side when calculating reconnects/disconnects,
    -- as the random order of entity update means that you can't trust it to reflect the actual connect/disconnects
    -- used on the client side by the ui to determine connection status for potently cyst building locations
    connected = "boolean",

    --Cysts scale their health based on the distance to the clostest hive
    healthScalar = "float (0 to 1 by 0.01)"
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ClientModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(UmbraMixin, networkVars)
AddMixinNetworkVars(FireMixin, networkVars)
AddMixinNetworkVars(MaturityMixin, networkVars)
AddMixinNetworkVars(CatalystMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(FlinchMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(PointGiverMixin, networkVars)
AddMixinNetworkVars(CloakableMixin, networkVars)
AddMixinNetworkVars(ConstructMixin, networkVars)
AddMixinNetworkVars(DetectableMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(InfestationMixin, networkVars)
AddMixinNetworkVars(IdleMixin, networkVars)

--
-- To avoid problems with minicysts on walls connection to each other through solid rock,
-- we need to move the start/end points a little bit along the start/end normals
--
local function CreateBetween(trackStart, startNormal, trackEnd, endNormal, startOffset, endOffset)

    trackStart = trackStart + startNormal * 0.01
    trackEnd = trackEnd + endNormal * 0.01
    
    local pathDirection = trackEnd - trackStart
    pathDirection:Normalize()
    
    if startOffset == nil then
        startOffset = 0.1
    end
    
    if endOffset == nil then
        endOffset = 0.1
    end
    
    -- DL: Offset the points a little towards the center point so that we start with a polygon on a nav mesh
    -- that is closest to the start. This is a workaround for edge case where a start polygon is picked on
    -- a tiny island blocked off by an obstacle.
    trackStart = trackStart + pathDirection * startOffset
    trackEnd = trackEnd - pathDirection * endOffset
    
    local points = PointArray()
    Pathing.GetPathPoints(trackEnd, trackStart, points)
    return points
    
end

--
-- Convinience function when creating a path between two entities, submits the y-axis of the entities coords as
-- the normal for use in CreateBetween()
--
function CreateBetweenEntities(srcEntity, endEntity)    
    return CreateBetween(srcEntity:GetOrigin(), srcEntity:GetCoords().yAxis, endEntity:GetOrigin(), endEntity:GetCoords().yAxis)    
end

if Server then
    Script.Load("lua/Cyst_Server.lua")
end

function Cyst:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, TeamMixin)
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, FireMixin)
    InitMixin(self, UmbraMixin)
    InitMixin(self, CatalystMixin)
    InitMixin(self, CombatMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, FlinchMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, PointGiverMixin)
    InitMixin(self, AchievementGiverMixin)
    InitMixin(self, CloakableMixin)
    InitMixin(self, ConstructMixin)
    InitMixin(self, MaturityMixin)
    InitMixin(self, DetectableMixin)
    
    if Server then
    
        InitMixin(self, SpawnBlockMixin)
        self:UpdateIncludeRelevancyMask()
        self.timeLastCystConstruction = 0
        
    elseif Client then
        InitMixin(self, CommanderGlowMixin)
        self.connectedFraction = 0
    end

    self:SetPhysicsCollisionRep(CollisionRep.Move)
    self:SetPhysicsGroup(PhysicsGroup.SmallStructuresGroup)
    
    self:SetLagCompensated(false)
    
    self.parentId = Entity.invalidId
    
end

function Cyst:OnDestroy()

    if Client then
        
        if self.redeployCircleModel then
        
            Client.DestroyRenderModel(self.redeployCircleModel)
            self.redeployCircleModel = nil
            
        end
        
    end
    
    ScriptActor.OnDestroy(self)
    
end

function Cyst:GetShowSensorBlip()
    return false
end

function Cyst:GetSpawnBlockDuration()
    return 7
end

--
-- A Cyst is redeployable if it is within range of the origin but
-- we ignore the Y distance within some tolerance.
--
local function GetCystIsRedeployable(cyst, origin)

    local immune = cyst.immuneToRedeploymentTime and Shared.GetTime() <= cyst.immuneToRedeploymentTime
    if cyst:GetDistance(origin) <= kCystRedeployRange and not immune then
        return math.abs(cyst:GetOrigin().y - origin.y) < 1
    end
    
    return false
    
end

local function DestroyNearbyCysts(self)

    local nearbyCysts = GetEntitiesForTeamWithinRange("Cyst", self:GetTeamNumber(), self:GetOrigin(), kCystRedeployRange)
    for c = 1, #nearbyCysts do
    
        local cyst = nearbyCysts[c]
        if cyst ~= self and GetCystIsRedeployable(cyst, self:GetOrigin()) then
            cyst:Kill()
        end
        
    end
    
end

function Cyst:OnInitialized()

    InitMixin(self, InfestationMixin)
    
    ScriptActor.OnInitialized(self)

    if Server then
    
        -- start out as disconnected; wait for impulse to arrive
        self.connected = false
        
        self.nextUpdate = Shared.GetTime()
        self.impulseActive = false
        self.bursted = false
        self.timeBursted = 0
        self.children = { }
        
        InitMixin(self, SleeperMixin)
        InitMixin(self, StaticTargetMixin)
        
        self:SetModel(Cyst.kModelName, Cyst.kAnimationGraph)
        
        -- This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
    elseif Client then    
    
        InitMixin(self, UnitStatusMixin)
        self:AddTimedCallback(Cyst.OnTimedUpdate, 0)
        -- note that even though a Client side cyst does not do OnUpdate, its mixins (cloakable mixin) requires it for
        -- now. If we can change that, then cysts _may_ be able to skip OnUpdate
         
    end   
    
    if Server then
        DestroyNearbyCysts(self)
    end
    
    InitMixin(self, IdleMixin)
    
end

function Cyst:GetPlayIdleSound()
    return self:GetIsBuilt() and self:GetCurrentInfestationRadiusCached() < 1
end

function Cyst:SetImmuneToRedeploymentTime(forTime)
    self.immuneToRedeploymentTime = Shared.GetTime() + forTime
end

function Cyst:GetInfestationGrowthRate()
    return Cyst.kInfestationGrowthDuration
end

function Cyst:GetHealthbarOffset()
    return 0.5
end 

--
-- Infestation never sights nearby enemy players.
--
function Cyst:OverrideCheckVision()
    return false
end

function Cyst:GetIsFlameAble()
    return true
end

function Cyst:GetMatureMaxHealth()
    return math.max(kMatureCystHealth * self.healthScalar or 0, kMinMatureCystHealth)
end 

function Cyst:GetMatureMaxArmor()
    return kMatureCystArmor
end 

function Cyst:GetMatureMaxEnergy()
    return 0
end

function Cyst:GetCanSleep()
    return true
end    

function Cyst:GetTechButtons(techId)
  
    return  { kTechId.Infestation,  kTechId.None, kTechId.None, kTechId.None,
              kTechId.None, kTechId.None, kTechId.None, kTechId.None }

end

function Cyst:GetInfestationRadius()
    return kInfestationRadius
end

function Cyst:GetInfestationMaxRadius()
    return kInfestationRadius
end

function Cyst:GetCystParentRange()
    return Cyst.kCystMaxParentRange
end  

function Cyst:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false    
end

--
-- Note: On the server side, used GetIsActuallyConnected()!
--
function Cyst:GetIsConnected() 
    return self.connected
end

function Cyst:GetIsConnectedAndAlive()
    return self.connected and self:GetIsAlive()
end

function Cyst:GetDescription()

    local prePendText = ConditionalValue(self:GetIsConnected(), "", "Unconnected ")
    return prePendText .. ScriptActor.GetDescription(self)
    
end

function Cyst:OnOverrideSpawnInfestation(infestation)

    infestation.maxRadius = kInfestationRadius
    -- New infestation starts partially built, but this allows it to start totally built at start of game
    local radiusPercent = math.max(infestation:GetRadius(), .2)
    infestation:SetRadiusPercent(radiusPercent)
    
end

function Cyst:GetReceivesStructuralDamage()
    return true
end

local function ServerUpdate(self, deltaTime)

    if not self:GetIsAlive() then
        return
    end
    
    if self.bursted then    
        self.bursted = self.timeBursted + Cyst.kBurstDuration > Shared.GetTime()    
    end
    
    local now = Shared.GetTime()
    
    if now > self.nextUpdate then
    
        local connectedNow = self:GetIsActuallyConnected()
        
        -- the very first time we are placed, we try to connect
        if not self.madeInitialConnectAttempt then
        
            if not connectedNow then 
                connectedNow = self:TryToFindABetterParent()
            end
            
            self.madeInitialConnectAttempt = true
            
        end
        
        -- try a single reconnect when we become disconnected
        if self.connected and not connectedNow then
            connectedNow = self:TryToFindABetterParent()
        end
        
        -- if we become connected, see if we have any unconnected cysts around that could use us as their parents
        if not self.connected and connectedNow then
            self:ReconnectOthers()
        end
        
        if connectedNow ~= self.connected then
            self.connected = connectedNow
            self:MarkBlipDirty()
        end
        
        -- avoid clumping; don't use now when calculating next think time (large kThinkTime)
        self.nextUpdate = self.nextUpdate + Cyst.kThinkTime
        
        -- become immature quickly if parents aren't around... that makes sense on so many levels ;)
        -- self:SetMaturityStarvation(not connectedNow)
		local damage = 1
		if self.constructionComplete then
			damage = kCystUnconnectedDamage 
		end
		
		if not self:GetCystParent() then
			self:DeductHealth(damage, nil)
		end
    end
    
end

function Cyst:GetHasChild()
    return self.hasChild
end

if Server then
  
    function Cyst:OnUpdate(deltaTime)

        PROFILE("Cyst:OnUpdate")
        
        ScriptActor.OnUpdate(self, deltaTime)
        
        if self:GetIsAlive() then
            
            ServerUpdate(self, deltaTime)
            self.hasChild = #self.children > 0
               
        else
        
            local destructionAllowedTable = { allowed = true }
            if self.GetDestructionAllowed then
                self:GetDestructionAllowed(destructionAllowedTable)
            end
            
            if destructionAllowedTable.allowed then
                DestroyEntity(self)
            end
        
        end
        
    end
    
elseif Client then
    
    -- avoid using OnUpdate for cysts, instead use a variable timed callback
    function Cyst:OnTimedUpdate(deltaTime)
      
      PROFILE("Cyst:OnTimedUpdate")
      if self:GetIsAlive() then
          local animateDirection = self.connected and 1 or -1
          self.connectedFraction = Clamp(self.connectedFraction + animateDirection * deltaTime, 0, self:GetBuiltFraction())      
          if self.connectedFraction > 0 and self.connectedFraction < 1 then
              return kUpdateIntervalAnimation
          end
      end
      return kUpdateIntervalLow
      
    end

end

function Cyst:GetCystParent()

    local parent = nil
    
    if self.parentId and self.parentId ~= Entity.invalidId then
        parent = Shared.GetEntity(self.parentId)
    end
    
    return parent
    
end

function MarkPotentialDeployedCysts(ents, origin)

    for i = 1, #ents do
    
        local ent = ents[i]
        if ent:isa("Cyst") and GetCystIsRedeployable(ent, origin) then
            ent.markAsPotentialRedeploy = true
        end
        
    end
    
end

--
-- Returns a parent and the track from that parent, or nil if none found.
--
function GetCystParentFromPoint(origin, normal, connectionMethodName, optionalIgnoreEnt)

    PROFILE("Cyst:GetCystParentFromPoint")
    
    local ents = GetSortedListOfPotentialParents(origin)
    
    if Client then
        MarkPotentialDeployedCysts(ents, origin)
    end
    
    for i = 1, #ents do
    
        local ent = ents[i]
        
        -- must be either a built hive or an cyst with a connected infestation
        if optionalIgnoreEnt ~= ent and
           ((ent:isa("Hive") and ent:GetIsBuilt()) or (ent:isa("Cyst") and ent[connectionMethodName](ent))) then
            
            local range = (origin - ent:GetOrigin()):GetLength()
            if range <= ent:GetCystParentRange() then
            
                -- check if we have a track from the entity to origin
                local endOffset = 0.1
                if ent:isa("Hive") then
                    endOffset = 3
                end
                
                local path = CreateBetween(origin, normal, ent:GetOrigin(), ent:GetCoords().yAxis, 0.1, endOffset)
                if path then
                
                    -- Check that the total path length is within the range.
                    local pathLength = GetPointDistance(path)
                    if pathLength <= ent:GetCystParentRange() then
                        return ent, path
                    end
                    
                end
                
            end
            
        end
        
    end
    
    return nil, nil
    
end

--
-- Return true if a connected cyst parent is availble at the given origin normal, and no destroyed cysts present
--
function GetIsDeadCystNearby(origin) 

    local deadCyst = false
    for _, cyst in ipairs(GetEntitiesWithinRange("Cyst", origin, kInfestationRadius)) do
        
        if not cyst:GetIsAlive() then
            deadCyst = true
            break
        end
        
    end
    
    return deadCyst

end

--
-- Returns a ghost-guide table for gui-use.
--
function GetCystGhostGuides(commander)

    local parent, path = commander:GetCystParentFromCursor()
    local result = { }
    
    if parent then
        result[parent] = parent:GetCystParentRange()
    end
    
    return result
    
end

function GetSortedListOfPotentialParents(origin)
    
    function sortByDistance(ent1, ent2)
        return (ent1:GetOrigin() - origin):GetLength() < (ent2:GetOrigin() - origin):GetLength()
    end
    
    -- first, check for hives
    local hives = GetEntitiesWithinRange("Hive", origin, kHiveCystParentRange)
    table.sort(hives, sortByDistance)
    
    -- add in the cysts. We get all cysts here, but mini-cysts have a shorter parenting range (bug, should be filtered out)
    local cysts = GetEntitiesWithinRange("Cyst", origin, kCystMaxParentRange)
    table.sort(cysts, sortByDistance)
    
    local parents = {}
    table.copy(hives, parents)
    table.copy(cysts, parents, true)
    
    return parents
    
end

-- Temporarily don't use "target" attach point
function Cyst:GetEngagementPointOverride()
    return self:GetOrigin() + Vector(0, 0.2, 0)
end

function Cyst:GetIsHealableOverride()
  return self:GetIsAlive() and self:GetIsConnected()
end

function Cyst:PerformActivation(techId, position, normal, commander)

    if techId == kTechId.Rupture and self:GetMaturityLevel() == kMaturityLevel.Mature then
    
        CreateEntity(Rupture.kMapName, self:GetOrigin(), self:GetTeamNumber())
        self.bursted = true
        self.timeBursted = Shared.GetTime()
        self:ResetMaturity()
        
        return true, true
        
    end
    
    return false, true
    
end

local function UpdateRedeployCircle(self, display)

    if not self.redeployCircleModel then
    
        self.redeployCircleModel = Client.CreateRenderModel(RenderScene.Zone_Default)
        self.redeployCircleModel:SetModel(Commander.kAlienCircleModelName)
        local coords = Coords.GetLookIn(self:GetOrigin() + Vector(0, kZFightingConstant, 0), Vector.xAxis)
        coords:Scale(kCystRedeployRange * 2)
        self.redeployCircleModel:SetCoords(coords)
        
    end
    
    self.redeployCircleModel:SetIsVisible(display)
    
end

function Cyst:OnUpdateRender()

    PROFILE("Cyst:OnUpdateRender")
    
    local model = self:GetRenderModel()
    if model then
    

        model:SetMaterialParameter("connected", self.connectedFraction)
        
        model:SetMaterialParameter("killWarning", self.markAsPotentialRedeploy and 1 or 0)
        
        UpdateRedeployCircle(self, self.markAsPotentialRedeploy or false)
        
        self.markAsPotentialRedeploy = false
        
    end
    
end

function Cyst:OverrideHintString(hintString)

    if not self:GetIsConnected() then
        return "CYST_UNCONNECTED_HINT"
    end
    
    return hintString
    
end

local kCystTraceStartPoint =
{
    Vector(0.2, 0.3, 0.2),
    Vector(-0.2, 0.3, 0.2),
    Vector(0.2, 0.3, -0.2),
    Vector(-0.2, 0.3, -0.2),

}

local kDownVector = Vector(0, -1, 0)

function AlignCyst(coords, normal)

    if Server and normal then
    
        -- get average normal:
        for _, startPoint in ipairs(kCystTraceStartPoint) do
        
            local startTrace = coords:TransformPoint(startPoint)
            local trace = Shared.TraceRay(startTrace, startTrace + kDownVector, CollisionRep.Select, PhysicsMask.CommanderBuild, EntityFilterAll())
            if trace.fraction ~= 1 then
                normal = normal + trace.normal
            end
        
        end
        
        normal:Normalize()

        coords.yAxis = normal
        coords.xAxis = coords.yAxis:CrossProduct(coords.zAxis)
        coords.zAxis = coords.xAxis:CrossProduct(coords.yAxis)

    end
    
    return coords

end

function Cyst:SetIncludeRelevancyMask(includeMask)

    includeMask = bit.bor(includeMask, kRelevantToTeam2Commander)    
    ScriptActor.SetIncludeRelevancyMask(self, includeMask)    

end

local kBestLength = 20
local kPointOffset = Vector(0, 0.1, 0)
local kParentSearchRange = 400

function FindPathToClosestParent(origin)

    PROFILE("Cyst:FindPathToClosestParent")

    local parents = GetEntitiesWithinRange("Cyst", origin, kParentSearchRange)
    table.copy(GetEntitiesWithinRange("Hive", origin, kParentSearchRange), parents, true)
    
    Shared.SortEntitiesByDistance(origin, parents)
    
    local currentPathLength = 100000
    local closestConnectedPathLength = 100000
    
    local currentPath = PointArray()

    local closestParent = nil
    local closestConnectedParent = nil
    
    for i = 1, #parents do
    
        local parent = parents[i]
        
        if parent:GetIsAlive() and ((parent:isa("Cyst") and parent:GetIsConnected()) or (parent:isa("Hive") and parent:GetIsBuilt())) then
        
            local path = PointArray()
            Pathing.GetPathPoints(parent:GetOrigin() + kPointOffset, origin + kPointOffset, path)
            local pathLength = GetPointDistance(path)

            -- it can happen on some maps, just break here when path length or number of points higher than 500
            if pathLength > 500 or #path > 500 then
                --DebugPrint("path length %s, points %s", ToString(pathLength), ToString(#path))
                break
            end
            
            if currentPathLength > pathLength then
            
                currentPath = path
                currentPathLength = pathLength
                closestParent = parent
                
            elseif currentPathLength + 6 < pathLength then                
                break
            end            
        
        end
    
    end
    
    return currentPath, closestParent

end

function GetCystParentAvailable(techId, origin, normal, commander)

    PROFILE("Cyst:GetCystParentAvailable")

    local points, parent = GetCystPoints(origin)
    return parent ~= nil
    
end

function GetCystPoints(origin)

    PROFILE("Cyst:GetCystPoints")

    local path, parent = FindPathToClosestParent(origin)

    local splitPoints = {}
    local normals = {}
    
    if parent then

        table.insert(splitPoints, parent:GetOrigin())
        
        local fromPoint = Vector(parent:GetOrigin())
        local currentDistance = 0
        local maxDistance = kCystMaxParentRange - 1.5
        local minDistance = kCystRedeployRange - 1

        for i = 1, #path do
        
            if #splitPoints > 20 then
                DebugPrint("split points exceeded 20")
                return {}, nil
            end
        
            local point = path[i]
            currentDistance = currentDistance + (point - fromPoint):GetLength()       
            
            if i == #path then
            
                if currentDistance > minDistance then
                
                    local groundTrace = Shared.TraceRay(point + Vector(0, 0.25, 0), point + Vector(0, -5, 0), CollisionRep.Default, PhysicsMask.CystBuild, EntityFilterAllButIsa("TechPoint"))
                    if groundTrace.fraction == 1 then                        
                        return {}, nil                        
                    end
                    
                    --if #GetEntitiesWithinRange("Cyst", groundTrace.endPoint, 2) == 0 then
                    
                        table.insert(splitPoints, groundTrace.endPoint)
                        table.insert(normals, groundTrace.normal)
                    
                    --end
                    
                end
            
            elseif currentDistance > maxDistance then
            
                local groundTrace = Shared.TraceRay(path[i] + Vector(0, 0.25, 0), path[i] + Vector(0, -5, 0), CollisionRep.Default, PhysicsMask.CystBuild, EntityFilterAllButIsa("TechPoint"))
                if groundTrace.fraction == 1 then                        
                    return {}, nil                        
                end
                
                --if #GetEntitiesWithinRange("Cyst", groundTrace.endPoint, 2) == 0 then
            
                    table.insert(splitPoints, groundTrace.endPoint)
                    table.insert(normals, groundTrace.normal)
                
                --end
                
                currentDistance = (path[i] - point):GetLength()
                
            end
            
            fromPoint = point
        
        end
    
    end
    
    return splitPoints, parent, normals
    

end

function Cyst:GetCanCatalyzeHeal()
    return true
end

function Cyst:GetInfestationRateMultiplier()
    return Cyst.kInfestationRateMultiplier
end

Shared.LinkClassToMap("Cyst", Cyst.kMapName, networkVars)