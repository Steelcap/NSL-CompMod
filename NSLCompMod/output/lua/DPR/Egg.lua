-- ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\Egg.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--                  Andreas Urwalek (andi@unknownworlds.com)
--
-- Thing that aliens spawn out of.
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
Script.Load("lua/ResearchMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/FireMixin.lua")
Script.Load("lua/UmbraMixin.lua")
Script.Load("lua/MaturityMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/TeleportMixin.lua")
Script.Load("lua/SleeperMixin.lua")
Script.Load("lua/CombatMixin.lua")

class 'Egg' (ScriptActor)

Egg.kMapName = "egg"

Egg.kModelName = PrecacheAsset("models/alien/egg/egg.model")
Egg.kGlowEffect = PrecacheAsset("cinematics/alien/egg/glow.cinematic")
Egg.kAnimationGraph = PrecacheAsset("models/alien/egg/egg.animation_graph")

Egg.kXExtents = 1
Egg.kYExtents = 1
Egg.kZExtents = 1

Egg.kHealth = kEggHealth
Egg.kArmor = kEggArmor

Egg.kSkinOffset = Vector(0, 0.12, 0)

Egg.kSpawnAnimLen = 1.5

local networkVars =
{
    empty = "boolean",   -- if player is inside it
    spawned = "boolean", -- Spawn cycle complete
    built = "boolean"    -- alive and spawned
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
AddMixinNetworkVars(ResearchMixin, networkVars)

AddMixinNetworkVars(FireMixin, networkVars)
AddMixinNetworkVars(UmbraMixin, networkVars)
AddMixinNetworkVars(MaturityMixin, networkVars)
AddMixinNetworkVars(TeleportMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)

if Server then
    
    local function SortByTechId(entId1, entId2)
        
        local ent1 = Shared.GetEntity(entId1)
        local ent2 = Shared.GetEntity(entId2)
    
        return ent1 and ent2 and ent1:GetTechId() > ent2:GetTechId()
        
    end

end

function Egg:OnCreate()

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
    InitMixin(self, ResearchMixin)
    InitMixin(self, FireMixin)
    InitMixin(self, UmbraMixin)
    InitMixin(self, MaturityMixin)
    InitMixin(self, TeleportMixin)
    InitMixin(self, CombatMixin)
    
    if Server then
        InitMixin(self, InfestationTrackerMixin)
    elseif Client then
        InitMixin(self, CommanderGlowMixin)    
    end
    
    self.spawned = true
    self.built = false
    self.empty = true
    
    self:SetLagCompensated(false)
    
end

function Egg:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    self:SetModel(Egg.kModelName, Egg.kAnimationGraph)
    self:SetPhysicsCollisionRep(CollisionRep.Move)
    
    self.queuedPlayerId = nil

    
    if Server then
    
        -- This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
        InitMixin(self, StaticTargetMixin)
        InitMixin(self, SleeperMixin)
        
        self:AddTimedCallback( Egg.UpdateSpawnedFlag, Egg.kSpawnAnimLen )
        
    elseif Client then
        InitMixin(self, UnitStatusMixin)
    end
    
end

function Egg:UpdateSpawnedFlag( deltaTime )
    self.spawned = false
    self.built = true
    return false
end

function Egg:GetShowCrossHairText(toPlayer)
    return not GetAreEnemies(self, toPlayer)
end    

function Egg:GetCanSleep()
    return true
end    

function Egg:GetMaturityRate()
    return kEggMaturationTime
end

function Egg:GetIsWallWalkingAllowed()
    return false
end    

function Egg:GetMatureMaxHealth()
    return kMatureEggHealth
end 

function Egg:GetMatureMaxArmor()
    return kMatureEggArmor
end

function Egg:GetBaseArmor()
    return Egg.kArmor
end

function Egg:GetBaseHealth()
    return Egg.kHealth  
end

function Egg:GetHealthPerBioMass()
    return 0
end    

function Egg:GetArmorFullyUpgradedAmount()
    return 0
end

function Egg:GetTechButtons(techId)

    local techButtons = { kTechId.SpawnAlien, kTechId.None, kTechId.None, kTechId.None, 
                          kTechId.None, kTechId.None, kTechId.None, kTechId.None }   

    --if self:GetTechId() == kTechId.Egg then   
    --    techButtons = { kTechId.SpawnAlien, kTechId.None, kTechId.None, kTechId.None, 
    --                    kTechId.GorgeEgg, kTechId.LerkEgg, kTechId.FadeEgg, kTechId.OnosEgg }      
    --end
    
    return techButtons
    
end

function Egg:GetTechAllowed(techId, techNode, player)

    local allowed, canAfford = ScriptActor.GetTechAllowed(self, techId, techNode, player) 

    if techId == kTechId.Cancel then
        allowed = true
    else
        allowed = allowed and self.empty
    end
    
    return allowed, canAfford
    
end

function Egg:OverrideHintString(hintString, forEntity)

    if (not GetAreEnemies(self, forEntity)) and self:GetIsResearching() then
        return "COMM_SEL_UPGRADING"
    end
    
    return hintString
    
end

function Egg:OnResearchComplete(techId)
    
    local success = false    

    if techId == kTechId.GorgeEgg or techId == kTechId.LerkEgg  or techId == kTechId.FadeEgg  or techId == kTechId.OnosEgg then
        self:UpgradeToTechId(techId)
    end
    
    return success
    
end

function Egg:SetHive(hive)
    self.hiveId = hive:GetId()
end

function Egg:GetHive()
    return Shared.GetEntity(self.hiveId)
end

function Egg:GetReceivesStructuralDamage()
    return false
end

function Egg:GetIsFlameAble()
    return true
end

--
-- Takes the queued player from this Egg and placed them back in the
-- respawn queue to be spawned elsewhere.
--
local function RequeuePlayer(self)

    if self.queuedPlayerId then
    
        local player = Shared.GetEntity(self.queuedPlayerId)
        local team = self:GetTeam()
        -- There are cases when the player or team is no longer valid such as
        -- when Egg:OnDestroy() is called during server shutdown.
        if player and team then
        
            if not player:isa("AlienSpectator") then
                error("AlienSpectator expected, instead " .. player:GetClassName() .. " was in queue")
            end
            
            player:SetEggId(Entity.invalidId)
            player:SetIsRespawning(false)
            team:PutPlayerInRespawnQueue(player)
            
        end
        
    end
    
    -- Don't spawn player
    self:SetEggFree()
    
end

if Server then

    function Egg:OnKill(attacker, doer, point, direction)
    
        RequeuePlayer(self)
        self:TriggerEffects("egg_death")
        DestroyEntity(self)
        
    end
    
end

function Egg:GetClassToGestate()
    return LookupTechData(self:GetGestateTechId(), kTechDataMapName, Skulk.kMapName)
end

function Egg:GetGestateTechId()

    local techId = self:GetTechId()
    
    if self:GetIsResearching() then
        techId = self:GetResearchingId()
    end

    if techId == kTechId.Egg then
        return kTechId.Skulk
    elseif techId == kTechId.GorgeEgg then
        return kTechId.Gorge
    elseif techId == kTechId.LerkEgg then
        return kTechId.Lerk
    elseif techId == kTechId.FadeEgg then
        return kTechId.Fade
    elseif techId == kTechId.OnosEgg then
        return kTechId.Onos
    end

end

local function GestatePlayer(self, player, fromTechId)

    player.oneHive = false
    player.twoHives = false
    player.threeHives = false

    local newPlayer = player:Replace(Embryo.kMapName)
    if not newPlayer:IsAnimated() then
        newPlayer:SetDesiredCamera(1.1, { follow = true, tweening = kTweeningFunctions.easeout7 })
    end
    newPlayer:SetCameraDistance(kGestateCameraDistance)
    
    -- Eliminate velocity so that we don't slide or jump as an egg
    newPlayer:SetVelocity(Vector(0, 0, 0))
    
    newPlayer:DropToFloor()
    
    local techIds = { self:GetGestateTechId() }
    newPlayer:SetGestationData(techIds, fromTechId, 1, 1)

end

function Egg:GetUnitNameOverride(viewer)

    if GetAreEnemies(self, viewer) then
        return GetDisplayNameForTechId(kTechId.Egg)
    end

    return GetDisplayName(self)    

end

-- Grab player out of respawn queue unless player passed in (for test framework)
function Egg:SpawnPlayer(player)

    PROFILE("Egg:SpawnPlayer")

    local queuedPlayer = player
    
    if not queuedPlayer or self.queuedPlayerId ~= nil then
        queuedPlayer = Shared.GetEntity(self.queuedPlayerId)
    end
    
    if queuedPlayer ~= nil then
    
        local queuedPlayer = player
        if not queuedPlayer then
            queuedPlayer = Shared.GetEntity(self.queuedPlayerId)
        end
    
        -- Spawn player on top of egg
        local spawnOrigin = Vector(self:GetOrigin())
        -- Move down to the ground.
        local _, normal = GetSurfaceAndNormalUnderEntity(self)
        if normal.y < 1 then
            spawnOrigin.y = spawnOrigin.y - (self:GetExtents().y / 2) + 1
        else
            spawnOrigin.y = spawnOrigin.y - (self:GetExtents().y / 2)
        end

        local gestationClass = self:GetClassToGestate()
        
        -- We must clear out queuedPlayerId BEFORE calling ReplaceRespawnPlayer
        -- as this will trigger OnEntityChange() which would requeue this player.
        self.queuedPlayerId = nil
        
        local team = queuedPlayer:GetTeam()
        local success, player = team:ReplaceRespawnPlayer(queuedPlayer, spawnOrigin, queuedPlayer:GetAngles(), gestationClass)                
        player:SetCameraDistance(0)
        player:SetHatched()
        -- It is important that the player was spawned at the spot we specified.
        assert(player:GetOrigin() == spawnOrigin)
        
        if success then
        
            self:TriggerEffects("egg_death")
            DestroyEntity(self) 
            
            return true, player
            
        end
            
    end
    
    return false, nil

end

function Egg:GetQueuedPlayerId()
    return self.queuedPlayerId
end

function Egg:SetQueuedPlayerId(playerId)

    self.queuedPlayerId = playerId
    self.empty = false
    
    local playerToSpawn = Shared.GetEntity(playerId)
    assert(playerToSpawn:isa("AlienSpectator"))
    
    playerToSpawn:SetEggId(self:GetId())

    --Refund costs for a non skulk egg
    local techId = self:GetIsResearching() and self:GetResearchingId() or self:GetTechId()
    if techId ~= kTechId.Egg then
        local eggCosts = LookupTechData(techId, kTechDataCostKey, 0)
        local team = self:GetTeam()
        team:AddTeamResources(eggCosts, true)
        self:ClearResearch()
        self:SetTechId(kTechId.Egg)
    end

    playerToSpawn:SetIsRespawning(true)
    
    if Server then
                
        if playerToSpawn.SetSpectatorMode then
            playerToSpawn:SetSpectatorMode(kSpectatorMode.Following)
        end
        
        playerToSpawn:SetFollowTarget(self)
        
    end
    
end

function Egg:SetEggFree()

    self.queuedPlayerId = nil
    self.empty = true

end

function Egg:GetIsFree()
    return self.queuedPlayerId == nil
end

--
-- Eggs never sight nearby enemy players.
--
function Egg:OverrideCheckVision()
    return false
end

function Egg:GetHealthbarOffset()
    return 0.4
end

function Egg:GetEngagementPointOverride()
    return self:GetOrigin() + Vector(0, 0.3, 0)
end

function Egg:InternalGetCanBeUsed(player)

    local canBeUsed = false
    -- SA: No longer allow players to enter eggs that are evolving/researching
    if self:GetTechId() ~= kTechId.Egg and player:GetTeamNumber() == self:GetTeamNumber() then
        canBeUsed = true
    end

    return canBeUsed

end

function Egg:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = self:InternalGetCanBeUsed(player)
end

if Server then

    function Egg:OnTeleportEnd(shift)
        self:SetOrigin(self:GetOrigin() + Vector(0, 0.2, 0)) 
    end

    -- delete the egg to avoid invalid ID's and reset the player to spawn queue if one is occupying it
    function Egg:OnDestroy()
    
        local team = self:GetTeam()
        
        -- Just in case there is a player waiting to spawn in this egg.
        RequeuePlayer(self)
        
        ScriptActor.OnDestroy(self)
        
    end
    
    function Egg:OnUse(player, elapsedTime, useSuccessTable)
    
        local useSuccess = false
        
        if self:InternalGetCanBeUsed(player) then
        
            GestatePlayer(self, player, player:GetTechId())
            useSuccess = true
            DestroyEntity(self)
            
        end
        
        useSuccessTable.useSuccess = useSuccessTable.useSuccess and useSuccess
        
    end
    
    function Egg:OnEntityChange(entityId, newEntityId)
    
        if self.queuedPlayerId and self.queuedPlayerId == entityId then
            RequeuePlayer(self)
        end
        
    end
    
end

function Egg:OnUpdateAnimationInput(modelMixin)

    PROFILE("Egg:OnUpdateAnimationInput")
    
    modelMixin:SetAnimationInput("empty", self.empty)
    modelMixin:SetAnimationInput("built", self.built)
    modelMixin:SetAnimationInput("spawned", self.spawned)
    
end

function Egg:OnAdjustModelCoords(coords)
    
    coords.origin = coords.origin - Egg.kSkinOffset
    return coords
    
end

function Egg:GetIsEmpty()
    return self.empty
end

Shared.LinkClassToMap("Egg", Egg.kMapName, networkVars)

class 'GorgeEgg' (Egg)
GorgeEgg.kMapName = "gorgeegg"
Shared.LinkClassToMap("GorgeEgg", GorgeEgg.kMapName, { })

class 'LerkEgg' (Egg)
LerkEgg.kMapName = "lerkegg"
Shared.LinkClassToMap("LerkEgg", LerkEgg.kMapName, { })

class 'FadeEgg' (Egg)
FadeEgg.kMapName = "fadeegg"
Shared.LinkClassToMap("FadeEgg", FadeEgg.kMapName, { })

class 'OnosEgg' (Egg)
OnosEgg.kMapName = "onosegg"
Shared.LinkClassToMap("OnosEgg", OnosEgg.kMapName, { })
