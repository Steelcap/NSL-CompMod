-- ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\AlienTeam.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
--                  Max McGuire (max@unknownworlds.com)
--
-- This class is used for teams that are actually playing the game, e.g. Marines or Aliens.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/TechData.lua")
Script.Load("lua/Skulk.lua")
Script.Load("lua/PlayingTeam.lua")
Script.Load("lua/UpgradeStructureManager.lua")

class 'AlienTeam' (PlayingTeam)

-- Innate alien regeneration
AlienTeam.kAutoHealInterval = 2
AlienTeam.kStructureAutoHealInterval = 0.5
AlienTeam.kAutoHealUpdateNum = 20 -- number of structures to update per autoheal update

AlienTeam.kInfestationUpdateRate = 2

function AlienTeam:GetTeamType()
    return kAlienTeamType
end

function AlienTeam:GetIsAlienTeam()
    return true
end

function AlienTeam:Initialize(teamName, teamNumber)

    PlayingTeam.Initialize(self, teamName, teamNumber)
    
    self.respawnEntity = Skulk.kMapName

    -- List stores all the structures owned by builder player types such as the Gorge.
    -- This list stores them based on the player platform ID in order to maintain structure
    -- counts even if a player leaves and rejoins a server.
    self.clientOwnedStructures = { }
    self.lastAutoHealIndex = 1
    
    self.updateAlienArmorInTicks = nil
    
    self.timeLastWave = 0
    self.bioMassLevel = 0
    self.bioMassAlertLevel = 0
    self.maxBioMassLevel = 0
    self.bioMassFraction = 0
    
end

function AlienTeam:OnInitialized()

    PlayingTeam.OnInitialized(self)
    
    self.lastAutoHealIndex = 1
    
    self.clientOwnedStructures = { }
    
    self.timeLastWave = 0
    self.bioMassLevel = 0
    self.bioMassAlertLevel = 0
    self.maxBioMassLevel = 0
    self.bioMassFraction = 0
    
end

function AlienTeam:GetTeamInfoMapName()
    return AlienTeamInfo.kMapName
end

function AlienTeam:GetEggCount()
    return self.eggCount or 0
end

local function SortByBioMassAdd(ent1, ent2)
    
    local bioMassAdd1 = ent1.biomassResearchFraction
    if not ent1:GetIsBuilt() then
        bioMassAdd1 = ent1:GetBuiltFraction()
    end
    
    local bioMassAdd2 = ent2.biomassResearchFraction
    if not ent2:GetIsBuilt() then
        bioMassAdd2 = ent2:GetBuiltFraction()
    end
    
    return bioMassAdd1 > bioMassAdd2
    
end

local kBioMassTechIds =
{
    kTechId.BioMassOne,
    kTechId.BioMassTwo,
    kTechId.BioMassThree,
    kTechId.BioMassFour,
    kTechId.BioMassFive,
    kTechId.BioMassSix,
    kTechId.BioMassSeven,
    kTechId.BioMassEight,
    kTechId.BioMassNine
}
function AlienTeam:UpdateBioMassLevel()

    local lastBioMassLevel = self.bioMassLevel

    self.bioMassLevel = 0
    self.bioMassAlertLevel = 0
    self.bioMassFraction = 0
    local extraBioMass = 0
    local progress = 0
    

    local ents = GetEntitiesForTeam("Hive", self:GetTeamNumber())
    table.sort(ents, SortByBioMassAdd)

    for index, entity in ipairs(ents) do
    
        if entity:GetIsAlive() then
    
            local currentBioMass = entity:GetBioMassLevel()
            self.bioMassLevel = self.bioMassLevel + currentBioMass



            local bioMassAdd = entity.biomassResearchFraction
            
            if not entity:GetIsBuilt() then
                bioMassAdd = bioMassAdd + entity:GetBuiltFraction()
            end
            
            if index == 1 then
                progress = bioMassAdd
            end
        
            currentBioMass = currentBioMass + bioMassAdd

            
            currentBioMass = currentBioMass * entity:GetHealthScalar()
            
            self.bioMassFraction = self.bioMassFraction + currentBioMass
            
            if Shared.GetTime() - entity:GetTimeLastDamageTaken() < 7 then
                self.bioMassAlertLevel = self.bioMassAlertLevel + currentBioMass
            end

        end
    
    end
    
    if self.techTree then
    
        for i = 1, #kBioMassTechIds do
        
            local techId = kBioMassTechIds[i]
            local techNode = self.techTree:GetTechNode(techId)
            if techNode then
            
                local techNodeProgress = i == self.bioMassLevel + 1 and progress or 0     
                if techNode:GetResearchProgress() ~= techNodeProgress then                    
                    techNode:SetResearchProgress(techNodeProgress)
                    self.techTree:SetTechNodeChanged(techNode, string.format("researchProgress = %.2f", techNodeProgress))                 
                end
            end
        
        end
    
    end


    if lastBioMassLevel ~= self.bioMassLevel and self.techTree then
        self.techTree:SetTechChanged()
    end
    
    self.maxBioMassLevel = 0
    
    for _, hive in ipairs(GetEntitiesForTeam("Hive", self:GetTeamNumber())) do
    
        if GetIsUnitActive(hive) then
            self.maxBioMassLevel = self.maxBioMassLevel + 3
        end
    
    end
    
end

function AlienTeam:GetMaxBioMassLevel()
    if GetGameInfoEntity():GetWarmUpActive() then return 9 end

    return self.maxBioMassLevel
end

function AlienTeam:GetBioMassLevel()
    if GetGameInfoEntity():GetWarmUpActive() then return 9 end

    return self.bioMassLevel
end

function AlienTeam:GetBioMassAlertLevel()
    if GetGameInfoEntity():GetWarmUpActive() then return 0 end

    return self.bioMassAlertLevel
end

function AlienTeam:GetBioMassFraction()
    if GetGameInfoEntity():GetWarmUpActive() then return 9 end

    return self.bioMassFraction
end

function AlienTeam:ClientOwnedStructures()
	return self.clientOwnedStructures
end

local function RemoveGorgeStructureFromClient(self, techId, clientId, player)

    local structureTypeTable = self.clientOwnedStructures[clientId]
    
    if structureTypeTable then
    
        if not structureTypeTable[techId] then
        
            structureTypeTable[techId] = { }
            return
            
        end    
        
        local removeIndex = 0
        local structure = nil
		local skip = false
		if techId == kTechId.GorgeTunnel and player and player:GetCrouching() then
			skip = true
		end
        for index, id in ipairs(structureTypeTable[techId])  do
        
            if id and not skip then
            
                removeIndex = index
                structure = Shared.GetEntity(id)
                break
                
            else
				skip = false
			end
            
        end
        
        if structure then
        
            table.remove(structureTypeTable[techId], removeIndex)
            structure.consumed = true
            if structure:GetCanDie() then
                structure:Kill()
            else
                DestroyEntity(structure)
            end
            
        end
        
    end
    
end


local function ApplyGorgeStructureTheme(structure, player)

    assert(player:isa("Gorge"))
    
    if structure.SetVariant then
        structure:SetVariant(player:GetVariant())
    end
    
end

function AlienTeam:AddGorgeStructure(player, structure)

    if player ~= nil and structure ~= nil then
    
        local clientId = Server.GetOwner(player):GetUserId()
        local structureId = structure:GetId()
        local techId = structure:GetTechId()
        
        if not self.clientOwnedStructures[clientId] then
            self.clientOwnedStructures[clientId] = { }
        end
        
        local structureTypeTable = self.clientOwnedStructures[clientId]
        
        if not structureTypeTable[techId] then
            structureTypeTable[techId] = { }
        end
        
        table.insertunique(structureTypeTable[techId], structureId)
        
        ApplyGorgeStructureTheme(structure, player)
        
        local numAllowedStructure = LookupTechData(techId, kTechDataMaxAmount, -1) --* self:GetNumHives()
        
        if numAllowedStructure >= 0 and table.count(structureTypeTable[techId]) > numAllowedStructure then
            RemoveGorgeStructureFromClient(self, techId, clientId, player)
        end
        
    end
    
end

function AlienTeam:GetDroppedGorgeStructures(player, techId)

    local owner = Server.GetOwner(player)

    if owner then
    
        local clientId = owner:GetUserId()
        local structureTypeTable = self.clientOwnedStructures[clientId]
        
        if structureTypeTable then
            return structureTypeTable[techId]
        end
    
    end
    
end

function AlienTeam:GetNumDroppedGorgeStructures(player, techId)

    local structureTypeTable = self:GetDroppedGorgeStructures(player, techId)
    return (not structureTypeTable and 0) or #structureTypeTable
    
end

function AlienTeam:UpdateClientOwnedStructures(oldEntityId)

    if oldEntityId then
    
        for clientId, structureTypeTable in pairs(self.clientOwnedStructures) do
        
            for techId, structureList in pairs(structureTypeTable) do
            
                for i, structureId in ipairs(structureList) do
                
                    if structureId == oldEntityId then
                    
                        table.remove(structureList, i)
                        break
                        
                    end
                    
                end
                
            end
            
        end
        
    end
    
end

function AlienTeam:OnEntityChange(oldEntityId, newEntityId)

    PlayingTeam.OnEntityChange(self, oldEntityId, newEntityId)

    -- Check if the oldEntityId matches any client's built structure and
    -- handle the change.
    
    self:UpdateClientOwnedStructures(oldEntityId)
    
end

local function CreateCysts(hive, harvester, teamNumber)

    local hiveOrigin = hive:GetOrigin()
    local harvesterOrigin = harvester:GetOrigin()
    
    -- Spawn all the Cyst spawn points close to the hive.
    local dist = (hiveOrigin - harvesterOrigin):GetLength()
    for c = 1, #Server.cystSpawnPoints do
    
        local spawnPoint = Server.cystSpawnPoints[c]
        if (spawnPoint - hiveOrigin):GetLength() <= (dist * 1.5) then
        
            local cyst = CreateEntityForTeam(kTechId.Cyst, spawnPoint, teamNumber, nil)
            cyst:SetConstructionComplete()
            cyst:SetInfestationFullyGrown()
            cyst:SetImmuneToRedeploymentTime(1)
            
        end
        
    end
    
end

function AlienTeam:SpawnInitialStructures(techPoint)

    local tower, hive = PlayingTeam.SpawnInitialStructures(self, techPoint)
    
    hive:SetFirstLogin()
    hive:SetInfestationFullyGrown()
    
    -- It is possible there was not an available tower if the map is not designed properly.
    if tower then
        CreateCysts(hive, tower, self:GetTeamNumber())
    end
    
    return tower, hive
    
end

function AlienTeam:GetHasAbilityToRespawn()

    local hives = GetEntitiesForTeam("Hive", self:GetTeamNumber())
    return table.count(hives) > 0
    
end

local function UpdateEggCount(self)

    self.eggCount = 0

    for _, egg in ipairs(GetEntitiesForTeam("Egg", self:GetTeamNumber())) do
    
        if egg:GetIsFree() and egg:GetGestateTechId() == kTechId.Skulk then        
            self.eggCount = self:GetEggCount() + 1
        end
    
    end

end

local function AssignPlayerToEgg(self, player, enemyTeamPosition)

    local success = false
    
    -- use non-preevolved eggs sorted by "critical hives position"
    local lifeFormEgg = nil
    
    local spawnPoint = player:GetDesiredSpawnPoint()

    if not spawnPoint then
        spawnPoint = enemyTeamPosition or player:GetOrigin()
    end

    local eggs = GetEntitiesForTeam("Egg", self:GetTeamNumber())        
    Shared.SortEntitiesByDistance(spawnPoint, eggs)
    
    -- Find the closest egg, doesn't matter which Hive owns it.
    for _, egg in ipairs(eggs) do
    
        -- Any unevolved egg is fine as long as it is free.
        if egg:GetIsFree() then
        
            if egg:GetGestateTechId() == kTechId.Skulk then
        
                egg:SetQueuedPlayerId(player:GetId())
                success = true
                break
            
            elseif lifeFormEgg == nil then
                lifeFormEgg = egg
            end
            
        end
        
    end
    
    -- use life form egg
    if not success and lifeFormEgg then
    
        lifeFormEgg:SetQueuedPlayerId(player:GetId())
        success = true

    end
    
    return success
    
end

local function GetCriticalHivePosition(self)

    -- get position of enemy team, ignore commanders
    local numPositions = 0
    local teamPosition = Vector(0, 0, 0)
    
    for _, player in ipairs( GetEntitiesForTeam("Player", GetEnemyTeamNumber(self:GetTeamNumber())) ) do

        if (player:isa("Marine") or player:isa("Exo")) and player:GetIsAlive() then
        
            numPositions = numPositions + 1
            teamPosition = teamPosition + player:GetOrigin()
        
        end

    end
    
    if numPositions > 0 then    
        return teamPosition / numPositions    
    end

end

local function UpdateEggGeneration(self)

    if not self.timeLastEggUpdate then
        self.timeLastEggUpdate = Shared.GetTime()
    end

    if self.timeLastEggUpdate + ScaleWithPlayerCount(kEggGenerationRate, #GetEntitiesForTeam("Player", self:GetTeamNumber())) < Shared.GetTime() then

        local enemyTeamPosition = GetCriticalHivePosition(self)
        local hives = GetEntitiesForTeam("Hive", self:GetTeamNumber())
        
        local builtHives = {}
        
        -- allow only built hives to spawn eggs
        for _, hive in ipairs(hives) do
        
            if hive:GetIsBuilt() and hive:GetIsAlive() then
                table.insert(builtHives, hive)
            end
        
        end
        
        if enemyTeamPosition then
            Shared.SortEntitiesByDistance(enemyTeamPosition, builtHives)
        end
        
        for _, hive in ipairs(builtHives) do
        
            if hive:UpdateSpawnEgg() then
                break
            end
        
        end
        
        self.timeLastEggUpdate = Shared.GetTime()
    
    end

end

local function UpdateAlienSpectators(self)

    if self.timeLastSpectatorUpdate == nil then
        self.timeLastSpectatorUpdate = Shared.GetTime() - 1
    end

    if self.timeLastSpectatorUpdate + 1 <= Shared.GetTime() then

        local alienSpectators = self:GetSortedRespawnQueue()
        local enemyTeamPosition = GetCriticalHivePosition(self)
        
        for i = 1, #alienSpectators do
        
            local alienSpectator = alienSpectators[i]
            -- Do not spawn players waiting in the auto team balance queue.
            if alienSpectator:isa("AlienSpectator") and not alienSpectator:GetIsWaitingForTeamBalance() then
            
                -- Consider min death time.
                if alienSpectator:GetRespawnQueueEntryTime() + kAlienSpawnTime < Shared.GetTime() then
                
                    local egg = nil
                    if alienSpectator.GetHostEgg then
                        egg = alienSpectator:GetHostEgg()
                    end
                    
                    -- Player has no egg assigned, check for free egg.
                    if egg == nil then
                    
                        local success = AssignPlayerToEgg(self, alienSpectator, enemyTeamPosition)
                        
                        -- We have no eggs currently, makes no sense to check for every spectator now.
                        if not success then
                            break
                        end
                        
                    end
                    
                end
                
            end
            
        end
    
        self.timeLastSpectatorUpdate = Shared.GetTime()

    end
    
end

local function UpdateCystConstruction(self, deltaTime)

    local numCystsToConstruct = self:GetNumCapturedTechPoints()

    for _, cyst in ipairs(GetEntitiesForTeam("Cyst", self:GetTeamNumber())) do
    
        local parent = cyst:GetCystParent()
        if not cyst:GetIsBuilt() and parent and parent:GetIsBuilt() then
      
            cyst:Construct(deltaTime)
            numCystsToConstruct = numCystsToConstruct - 1

        end
        
        if numCystsToConstruct <= 0 then
            break
        end
    
    end

end

function AlienTeam:Update(timePassed)

    PROFILE("AlienTeam:Update")
    
    PlayingTeam.Update(self, timePassed)
    
    self:UpdateTeamAutoHeal(timePassed)
    UpdateEggGeneration(self)
    UpdateEggCount(self)
    UpdateAlienSpectators(self)
    self:UpdateBioMassLevel()
    
    local shellLevel = GetShellLevel(self:GetTeamNumber())  
    for index, alien in ipairs(GetEntitiesForTeam("Alien", self:GetTeamNumber())) do
        alien:UpdateArmorAmount(shellLevel)
        alien:UpdateHealthAmount(math.min(12, self.bioMassLevel), self.maxBioMassLevel)
    end
    
    UpdateCystConstruction(self, timePassed)
    
end

function AlienTeam:OnTechTreeUpdated()

    if self.updateAlienArmor then
        
        self.updateAlienArmor = false
        self.updateAlienArmorInTicks = 100
        
    end

end

-- update every tick but only a small amount of structures
function AlienTeam:UpdateTeamAutoHeal(timePassed)

    PROFILE("AlienTeam:UpdateTeamAutoHeal")

    local time = Shared.GetTime()
    
    if self.timeOfLastAutoHeal == nil then
        self.timeOfLastAutoHeal = Shared.GetTime()
    end
    
    if time > (self.timeOfLastAutoHeal + AlienTeam.kStructureAutoHealInterval) then
        
        local intervalLength = time - self.timeOfLastAutoHeal
        local gameEnts = GetEntitiesWithMixinForTeam("InfestationTracker", self:GetTeamNumber())
        local numEnts = table.count(gameEnts)
        local toIndex = self.lastAutoHealIndex + AlienTeam.kAutoHealUpdateNum - 1
        toIndex = ConditionalValue(toIndex <= numEnts , toIndex, numEnts)
        for index = self.lastAutoHealIndex, toIndex do

            local entity = gameEnts[index]
            
            -- players update the auto heal on their own
            if not entity:isa("Player") then
            
                -- we add whips as an exception here. construction should still be restricted to onInfestation, we only don't want whips to take damage off infestation
                local requiresInfestation   = ConditionalValue(entity:isa("Whip"), false, LookupTechData(entity:GetTechId(), kTechDataRequiresInfestation))
                local isOnInfestation       = entity:GetGameEffectMask(kGameEffect.OnInfestation)
                local isHealable            = entity:GetIsHealable()
                local deltaTime             = 0
                local beingCatalyzed        = false --HasMixin(entity, "Catalyst") and entity:GetIsCatalysted()
                
                if not entity.timeLastAutoHeal then
                    entity.timeLastAutoHeal = Shared.GetTime()
                else
                    deltaTime = Shared.GetTime() - entity.timeLastAutoHeal
                    entity.timeLastAutoHeal = Shared.GetTime()
                end

                if requiresInfestation and not isOnInfestation and not beingCatalyzed then
                    
                    -- Take damage!
                    local damage = entity:GetMaxHealth() * kBalanceInfestationHurtPercentPerSecond/100 * deltaTime
                    damage = math.max(damage, kMinHurtPerSecond)
                    
                    local attacker
                    if entity.lastAttackerDidDamageTime and Shared.GetTime() < entity.lastAttackerDidDamageTime + 60 then
                        attacker = entity:GetLastAttacker()
                    end
                    
                    entity:DeductHealth(damage, attacker)
                               
                end
            
            end
        
        end
        
        if self.lastAutoHealIndex + AlienTeam.kAutoHealUpdateNum >= numEnts then
            self.lastAutoHealIndex = 1
        else
            self.lastAutoHealIndex = self.lastAutoHealIndex + AlienTeam.kAutoHealUpdateNum
        end 

        self.timeOfLastAutoHeal = Shared.GetTime()

   end
    
end

function AlienTeam:InitTechTree()

    PlayingTeam.InitTechTree(self)
    
    -- Add special alien menus
    self.techTree:AddMenu(kTechId.MarkersMenu)
    self.techTree:AddMenu(kTechId.UpgradesMenu)
    self.techTree:AddMenu(kTechId.ShadePhantomMenu)
    self.techTree:AddMenu(kTechId.ShadePhantomStructuresMenu)
    self.techTree:AddMenu(kTechId.ShiftEcho, kTechId.ShiftHive)
    self.techTree:AddMenu(kTechId.LifeFormMenu)
    self.techTree:AddMenu(kTechId.SkulkMenu)
    self.techTree:AddMenu(kTechId.GorgeMenu)
    self.techTree:AddMenu(kTechId.LerkMenu)
    self.techTree:AddMenu(kTechId.FadeMenu)
    self.techTree:AddMenu(kTechId.OnosMenu)
    self.techTree:AddMenu(kTechId.Return)
    
    self.techTree:AddOrder(kTechId.Grow)
    self.techTree:AddAction(kTechId.FollowAlien)    
    
    self.techTree:AddPassive(kTechId.Infestation)
    self.techTree:AddPassive(kTechId.SpawnAlien)
    self.techTree:AddPassive(kTechId.CollectResources, kTechId.Harvester)
    
    -- Add markers (orders)
    self.techTree:AddSpecial(kTechId.ThreatMarker, kTechId.None, kTechId.None, true)
    self.techTree:AddSpecial(kTechId.LargeThreatMarker, kTechId.None, kTechId.None, true)
    self.techTree:AddSpecial(kTechId.NeedHealingMarker, kTechId.None, kTechId.None, true)
    self.techTree:AddSpecial(kTechId.WeakMarker, kTechId.None, kTechId.None, true)
    self.techTree:AddSpecial(kTechId.ExpandingMarker, kTechId.None, kTechId.None, true)
    
    -- bio mass levels (required to unlock new abilities)
    self.techTree:AddSpecial(kTechId.BioMassOne)
    self.techTree:AddSpecial(kTechId.BioMassTwo)
    self.techTree:AddSpecial(kTechId.BioMassThree)
    self.techTree:AddSpecial(kTechId.BioMassFour)
    self.techTree:AddSpecial(kTechId.BioMassFive)
    self.techTree:AddSpecial(kTechId.BioMassSix)
    self.techTree:AddSpecial(kTechId.BioMassSeven)
    self.techTree:AddSpecial(kTechId.BioMassEight)
    self.techTree:AddSpecial(kTechId.BioMassNine)
    
    -- Commander abilities
    self.techTree:AddBuildNode(kTechId.Cyst)
    self.techTree:AddBuildNode(kTechId.NutrientMist)
    self.techTree:AddBuildNode(kTechId.Rupture, kTechId.BioMassFour)
    self.techTree:AddBuildNode(kTechId.BoneWall, kTechId.BioMassThree)
    self.techTree:AddBuildNode(kTechId.Contamination, kTechId.BioMassNine)
    self.techTree:AddAction(kTechId.SelectDrifter)
    self.techTree:AddAction(kTechId.SelectHallucinations, kTechId.ShadeHive)
    self.techTree:AddAction(kTechId.SelectShift, kTechId.ShiftHive)
    
    -- Drifter triggered abilities
    self.techTree:AddTargetedActivation(kTechId.EnzymeCloud,      kTechId.ShiftHive,      kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.Hallucinate,      kTechId.ShadeHive,      kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.MucousMembrane,   kTechId.CragHive,      kTechId.None)    
    --self.techTree:AddTargetedActivation(kTechId.Storm,            kTechId.ShiftHive,       kTechId.None)
    self.techTree:AddActivation(kTechId.DestroyHallucination)
    
    -- Drifter passive abilities
    self.techTree:AddPassive(kTechId.DrifterCamouflage)
    self.techTree:AddPassive(kTechId.DrifterCelerity)
    self.techTree:AddPassive(kTechId.DrifterRegeneration)
           
    -- Hive types
    self.techTree:AddBuildNode(kTechId.Hive,                    kTechId.None,           kTechId.None)
    self.techTree:AddPassive(kTechId.HiveHeal)
    self.techTree:AddBuildNode(kTechId.CragHive,                kTechId.Hive,                kTechId.None)
    self.techTree:AddBuildNode(kTechId.ShadeHive,               kTechId.Hive,                kTechId.None)
    self.techTree:AddBuildNode(kTechId.ShiftHive,               kTechId.Hive,                kTechId.None)
    
    self.techTree:AddTechInheritance(kTechId.Hive, kTechId.CragHive)
    self.techTree:AddTechInheritance(kTechId.Hive, kTechId.ShiftHive)
    self.techTree:AddTechInheritance(kTechId.Hive, kTechId.ShadeHive)
    
    self.techTree:AddUpgradeNode(kTechId.ResearchBioMassOne)
    self.techTree:AddUpgradeNode(kTechId.ResearchBioMassTwo)
    self.techTree:AddUpgradeNode(kTechId.ResearchBioMassThree)
    self.techTree:AddUpgradeNode(kTechId.ResearchBioMassFour)

    self.techTree:AddUpgradeNode(kTechId.UpgradeToCragHive,     kTechId.Hive,                kTechId.None)
    self.techTree:AddUpgradeNode(kTechId.UpgradeToShadeHive,    kTechId.Hive,                kTechId.None)
    self.techTree:AddUpgradeNode(kTechId.UpgradeToShiftHive,    kTechId.Hive,                kTechId.None)
    
    self.techTree:AddBuildNode(kTechId.Harvester)
    self.techTree:AddBuildNode(kTechId.DrifterEgg)
    self.techTree:AddBuildNode(kTechId.Drifter, kTechId.None, kTechId.None, true)

    -- Whips
    self.techTree:AddBuildNode(kTechId.Whip,                      kTechId.None,                kTechId.None)
    self.techTree:AddUpgradeNode(kTechId.EvolveBombard,             kTechId.None,                kTechId.None)

    self.techTree:AddPassive(kTechId.WhipBombard)
    self.techTree:AddPassive(kTechId.Slap)
    self.techTree:AddActivation(kTechId.WhipUnroot)
    self.techTree:AddActivation(kTechId.WhipRoot)
    
    -- Tier 1 lifeforms
    self.techTree:AddAction(kTechId.Skulk,                     kTechId.None,                kTechId.None)
    self.techTree:AddAction(kTechId.Gorge,                     kTechId.None,                kTechId.None)
    self.techTree:AddAction(kTechId.Lerk,                      kTechId.None,                kTechId.None)
    self.techTree:AddAction(kTechId.Fade,                      kTechId.None,                kTechId.None)
    self.techTree:AddAction(kTechId.Onos,                      kTechId.None,                kTechId.None)
    self.techTree:AddBuyNode(kTechId.Egg,                      kTechId.None,                kTechId.None)
    
    self.techTree:AddUpgradeNode(kTechId.GorgeEgg, kTechId.BioMassTwo)
    self.techTree:AddUpgradeNode(kTechId.LerkEgg, kTechId.BioMassTwo)
    self.techTree:AddUpgradeNode(kTechId.FadeEgg, kTechId.BioMassNine)
    self.techTree:AddUpgradeNode(kTechId.OnosEgg, kTechId.BioMassNine)
    
    -- Special alien structures. These tech nodes are modified at run-time, depending when they are built, so don't modify prereqs.
    self.techTree:AddBuildNode(kTechId.Crag,                      kTechId.Hive,          kTechId.None)
    self.techTree:AddBuildNode(kTechId.Shift,                     kTechId.Hive,          kTechId.None)
    self.techTree:AddBuildNode(kTechId.Shade,                     kTechId.Hive,          kTechId.None)
    
    -- Alien upgrade structure
    self.techTree:AddBuildNode(kTechId.Shell, kTechId.CragHive)
    self.techTree:AddSpecial(kTechId.TwoShells, kTechId.Shell)
    self.techTree:AddSpecial(kTechId.ThreeShells, kTechId.TwoShells)
    
    self.techTree:AddBuildNode(kTechId.Veil, kTechId.ShadeHive)
    self.techTree:AddSpecial(kTechId.TwoVeils, kTechId.Veil)
    self.techTree:AddSpecial(kTechId.ThreeVeils, kTechId.TwoVeils)
    
    self.techTree:AddBuildNode(kTechId.Spur, kTechId.ShiftHive)  
    self.techTree:AddSpecial(kTechId.TwoSpurs, kTechId.Spur)
    self.techTree:AddSpecial(kTechId.ThreeSpurs, kTechId.TwoSpurs)
    
    
    -- personal upgrades (all alien types)
    self.techTree:AddBuyNode(kTechId.Crush, kTechId.Shell, kTechId.None, kTechId.AllAliens)    
    self.techTree:AddBuyNode(kTechId.Carapace, kTechId.Shell, kTechId.None, kTechId.AllAliens)    
    self.techTree:AddBuyNode(kTechId.Regeneration, kTechId.Shell, kTechId.None, kTechId.AllAliens)
    
    --self.techTree:AddBuyNode(kTechId.Focus, kTechId.Veil, kTechId.None, kTechId.AllAliens)
    self.techTree:AddBuyNode(kTechId.Aura, kTechId.Veil, kTechId.None, kTechId.AllAliens)
    self.techTree:AddBuyNode(kTechId.Vampirism, kTechId.Veil, kTechId.None, kTechId.AllAliens)
    
    self.techTree:AddBuyNode(kTechId.Silence, kTechId.Veil, kTechId.None, kTechId.AllAliens)  
    self.techTree:AddBuyNode(kTechId.Celerity, kTechId.Spur, kTechId.None, kTechId.AllAliens)  
    self.techTree:AddBuyNode(kTechId.Adrenaline, kTechId.Spur, kTechId.None, kTechId.AllAliens)  
    
    
    -- Crag
    self.techTree:AddPassive(kTechId.CragHeal)
    self.techTree:AddActivation(kTechId.HealWave,                kTechId.CragHive,          kTechId.None)

    -- Shift
    self.techTree:AddActivation(kTechId.ShiftHatch,               kTechId.None,         kTechId.None) 
    self.techTree:AddPassive(kTechId.ShiftEnergize,               kTechId.None,         kTechId.None)
    
    self.techTree:AddTargetedActivation(kTechId.TeleportHydra,       kTechId.ShiftHive,         kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.TeleportWhip,        kTechId.ShiftHive,         kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.TeleportTunnel,      kTechId.ShiftHive,         kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.TeleportCrag,        kTechId.ShiftHive,         kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.TeleportShade,       kTechId.ShiftHive,         kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.TeleportShift,       kTechId.ShiftHive,         kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.TeleportVeil,        kTechId.ShiftHive,         kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.TeleportSpur,        kTechId.ShiftHive,         kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.TeleportShell,       kTechId.ShiftHive,         kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.TeleportHive,        kTechId.ShiftHive,         kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.TeleportEgg,         kTechId.ShiftHive,         kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.TeleportHarvester,   kTechId.ShiftHive,         kTechId.None)

    -- Shade
    self.techTree:AddPassive(kTechId.ShadeDisorient)
    self.techTree:AddPassive(kTechId.ShadeCloak)
    self.techTree:AddActivation(kTechId.ShadeInk,                 kTechId.ShadeHive,         kTechId.None) 
    
    self.techTree:AddSpecial(kTechId.TwoHives)
    self.techTree:AddSpecial(kTechId.ThreeHives)
    
    self.techTree:AddSpecial(kTechId.TwoWhips)
    self.techTree:AddSpecial(kTechId.TwoShifts)
    self.techTree:AddSpecial(kTechId.TwoShades)
    self.techTree:AddSpecial(kTechId.TwoCrags)
    
    -- abilities unlocked by bio mass:
    
    -- skulk researches
    self.techTree:AddResearchNode(kTechId.Leap,              kTechId.BioMassFour, kTechId.None, kTechId.AllAliens) 
    self.techTree:AddResearchNode(kTechId.Xenocide,          kTechId.BioMassNine, kTechId.None, kTechId.AllAliens)
    
    -- gorge researches
    self.techTree:AddBuyNode(kTechId.BabblerAbility,        kTechId.None)
    self.techTree:AddPassive(kTechId.WebTech,            kTechId.None) --, kTechId.None, kTechId.AllAliens
    --FIXME Above still shows in Alien-Comm buttons/menu
    self.techTree:AddBuyNode(kTechId.Web,                   kTechId.None)
    self.techTree:AddBuyNode(kTechId.BabblerEgg,            kTechId.None)
    self.techTree:AddResearchNode(kTechId.BileBomb,         kTechId.BioMassThree, kTechId.None, kTechId.AllAliens)
    
    -- lerk researches
    self.techTree:AddResearchNode(kTechId.Umbra,               kTechId.BioMassFive, kTechId.None, kTechId.AllAliens) 
    self.techTree:AddResearchNode(kTechId.Spores,              kTechId.BioMassSeven, kTechId.None, kTechId.AllAliens)
    
    -- fade researches
    self.techTree:AddResearchNode(kTechId.MetabolizeEnergy,        kTechId.BioMassThree, kTechId.None, kTechId.AllAliens) 
    self.techTree:AddResearchNode(kTechId.MetabolizeHealth,            kTechId.BioMassFive, kTechId.MetabolizeEnergy, kTechId.AllAliens)
    self.techTree:AddResearchNode(kTechId.Stab,              kTechId.BioMassSeven, kTechId.None, kTechId.AllAliens)
    
    -- onos researches
    self.techTree:AddResearchNode(kTechId.Charge,            kTechId.BioMassTwo, kTechId.None, kTechId.AllAliens)
    self.techTree:AddResearchNode(kTechId.BoneShield,        kTechId.BioMassSix, kTechId.None, kTechId.AllAliens)
    self.techTree:AddResearchNode(kTechId.Stomp,             kTechId.BioMassEight, kTechId.None, kTechId.AllAliens)      

    -- gorge structures
    self.techTree:AddBuildNode(kTechId.GorgeTunnel)
    self.techTree:AddBuildNode(kTechId.Hydra)
    self.techTree:AddBuildNode(kTechId.Clog)

    self.techTree:SetComplete()
    
end
function AlienTeam:GetNumHives()

    local teamInfoEntity = Shared.GetEntity(self.teamInfoEntityId)
    return teamInfoEntity:GetNumCapturedTechPoints()
    
end

function AlienTeam:GetActiveHiveCount()

    local activeHiveCount = 0
    
    for index, hive in ipairs(GetEntitiesForTeam("Hive", self:GetTeamNumber())) do
    
        if hive:GetIsAlive() and hive:GetIsBuilt() then
            activeHiveCount = activeHiveCount + 1
        end
    
    end

    return activeHiveCount

end

function AlienTeam:GetActiveEggCount()

    local activeEggCount = 0
    
    for _, egg in ipairs(GetEntitiesForTeam("Egg", self:GetTeamNumber())) do
    
        if egg:GetIsAlive() and egg:GetIsEmpty() then
            activeEggCount = activeEggCount + 1
        end
    
    end
    
    return activeEggCount

end

--
-- Inform all alien players about the hive construction (add new abilities).
--
function AlienTeam:OnHiveConstructed(newHive)

    local activeHiveCount = self:GetActiveHiveCount()
    
    for index, alien in ipairs(GetEntitiesForTeam("Alien", self:GetTeamNumber())) do
    
        if alien:GetIsAlive() and alien.OnHiveConstructed then
            alien:OnHiveConstructed(newHive, activeHiveCount)
        end
        
    end
    
    SendTeamMessage(self, kTeamMessageTypes.HiveConstructed, newHive:GetLocationId())
    
end

--
-- Inform all alien players about the hive destruction (remove abilities).
--
function AlienTeam:OnHiveDestroyed(destroyedHive)

    local activeHiveCount = self:GetActiveHiveCount()
    
    for index, alien in ipairs(GetEntitiesForTeam("Alien", self:GetTeamNumber())) do
    
        if alien:GetIsAlive() and alien.OnHiveDestroyed then
            alien:OnHiveDestroyed(destroyedHive, activeHiveCount)
        end
        
    end
    
end

function AlienTeam:OnUpgradeChamberConstructed(upgradeChamber)

    if upgradeChamber:GetTechId() == kTechId.CarapaceShell then
        self.updateAlienArmor = true
    end
    
end

function AlienTeam:OnUpgradeChamberDestroyed(upgradeChamber)

    if upgradeChamber:GetTechId() == kTechId.CarapaceShell then
        self.updateAlienArmor = true
    end
    
    -- These is a list of all tech to check when a upgrade chamber is destroyed.
    local checkForLostResearch = 
    { 
        [kTechId.RegenerationShell] = { "Shell", kTechId.Regeneration },
        [kTechId.CarapaceShell] = { "Shell", kTechId.Carapace },
        [kTechId.CrushShell] = { "Shell", kTechId.Crush },
        
        [kTechId.CeleritySpur] = { "Spur", kTechId.Celerity },
        [kTechId.AdrenalineSpur] = { "Spur", kTechId.Adrenaline },
		
		--[kTechId.FocusVeil] = { "Veil", kTechId.Focus },
		
        [kTechId.SilenceSpur] = { "Veil", kTechId.Silence },
        [kTechId.AuraVeil] = { "Veil", kTechId.Aura },
        [kTechId.VampirismVeil] = { "Veil", kTechId.Vampirism }
    }
    
    local checkTech = checkForLostResearch[upgradeChamber:GetTechId()]
    if checkTech then
    
        local anyRemain = false
        for _, ent in ientitylist(Shared.GetEntitiesWithClassname(checkTech[1])) do
        
            -- Don't count the upgradeChamber as it is being destroyed now.
            if ent ~= upgradeChamber and ent:GetTechId() == upgradeChamber:GetTechId() then
            
                anyRemain = true
                break
                
            end
            
        end
        
        if not anyRemain then
            SendTeamMessage(self, kTeamMessageTypes.ResearchLost, checkTech[2])
        end
        
    end
    
end

function AlienTeam:OnResearchComplete(structure, researchId)

    PlayingTeam.OnResearchComplete(self, structure, researchId)
    
    local checkForGainedResearch = 
    {
        [kTechId.UpgradeCrushShell] = kTechId.Crush,
        [kTechId.UpgradeRegenerationShell] = kTechId.Regeneration,
        [kTechId.UpgradeCarapaceShell] = kTechId.Carapace,
        
        [kTechId.UpgradeCeleritySpur] = kTechId.Celerity,
        [kTechId.UpgradeAdrenalineSpur] = kTechId.Adrenaline,
        [kTechId.UpgradeSilenceSpur] = kTechId.Silence,
        
        [kTechId.UpgradeVampirismVeil] = kTechId.Vampirism,
        [kTechId.UpgradeAuraVeil] = kTechId.Aura,
        [kTechId.UpgradeFocusVeil] = kTechId.Focus
    }
    
    local gainedResearch = checkForGainedResearch[researchId]
    if gainedResearch then
        SendTeamMessage(self, kTeamMessageTypes.ResearchComplete, gainedResearch)
    end
    
end

function AlienTeam:GetSpectatorMapName()
    return AlienSpectator.kMapName
end

local function NotTooLate(waveTime, player)

    return player.GetRespawnQueueEntryTime ~= nil and player:GetRespawnQueueEntryTime() ~= nil and
           player:GetRespawnQueueEntryTime() + kAlienMinDeathTime < waveTime
    
end

function AlienTeam:OnEvolved(techId)

    local listeners = self.eventListeners['OnEvolved']

    if listeners then

        for _, listener in ipairs(listeners) do
            listener(techId)
        end

    end

end

local function OnSetDesiredSpawnPoint(client, message)

    local player = client:GetControllingPlayer()
    if player then
        player.desiredSpawnPoint = message.desiredSpawnPoint
    end

end
Server.HookNetworkMessage("SetDesiredSpawnPoint", OnSetDesiredSpawnPoint)

