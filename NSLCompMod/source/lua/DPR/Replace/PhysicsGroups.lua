--=============================================================================
--
-- RifleRange/PhysicsGroups.lua
--
-- Created by Max McGuire (max@unknownworlds.com)
-- Copyright 2011, Unknown Worlds Entertainment
--
--=============================================================================

--
-- Returns a bit mask with the specified groups filtered out.
--
function CreateMaskExcludingGroups(...)
  
    local mask = 0xFFFFFFFF
    local args = {...}
    
    for i,v in ipairs(args) do
        mask = bit.band( mask, bit.bnot(bit.lshift(1,v-1)) )
    end
  
    return mask
    
end

--
-- Returns a bit mask with everything but the specified groups filtered out.
--
function CreateMaskIncludingGroups(...)

    local mask = 0x0
    local args = {...}

    for i,v in ipairs(args) do
        mask = bit.bor( mask, bit.lshift(1,v-1) )
    end
  
    return mask

end

-- Different groups that physics objects can be assigned to.
-- Physics models and controllers can only be in ONE group (SetGroup()).
PhysicsGroup = enum
{ 
    'DefaultGroup',             -- Default Group Entities are created with
    'BigStructuresGroup',       -- command structures (hive, cs), robotics factory etc.
    'MediumStructuresGroup',    -- like structures group but onos will not collide with them.
    'SmallStructuresGroup',     -- Small structures that don't affect movement (cysts, mines)
    'RagdollGroup',             -- Ragdolls are in this group
    'PlayerControllersGroup',   -- Bullets will not collide with this group.
    'BigPlayerControllersGroup', -- onos
    'PlayerGroup',
    'WeaponGroup',
    'ProjectileGroup',
    'BabblerGroup',
    'CommanderPropsGroup',
    'CommanderUnitGroup',       -- Macs, Drifters, doors, etc.
    'AttachClassGroup',         -- Nozzles, tech points, etc.
    'CollisionGeometryGroup',   -- Used so players walk smoothly gratings and skulks wall-run on railings, etc.
    'DroppedWeaponGroup',
    'WhipGroup',
    'MarinePlayerGroup',
    'CommanderBuildGroup',
    'TriggerGroup',
    'PathingGroup',
    'WebsGroup',
}

-- Pre-defined physics group masks.
PhysicsMask = enum
{
    -- Don't collide with anything
    None = 0,
    
    DefaultOnly = CreateMaskIncludingGroups(PhysicsGroup.DefaultGroup),
    
    -- Don't filter out anything
    All = 0xFFFFFFFF,
    
    -- Filters anything that should not be collided with for player movement.
    Movement = CreateMaskExcludingGroups(PhysicsGroup.SmallStructuresGroup,
                                         PhysicsGroup.RagdollGroup,
                                         PhysicsGroup.PlayerGroup,
                                         PhysicsGroup.BabblerGroup,
                                         PhysicsGroup.ProjectileGroup,
                                         PhysicsGroup.WeaponGroup,
                                         PhysicsGroup.DroppedWeaponGroup,
                                         PhysicsGroup.CommanderBuildGroup,
                                         PhysicsGroup.PathingGroup,
                                         PhysicsGroup.WebsGroup),
    
    -- Filters anything that should not collide with onos movement.
    OnosMovement = CreateMaskExcludingGroups(PhysicsGroup.WhipGroup,
                                             PhysicsGroup.SmallStructuresGroup,
                                             PhysicsGroup.MediumStructuresGroup,
                                             PhysicsGroup.RagdollGroup,
                                             PhysicsGroup.PlayerGroup,
                                             PhysicsGroup.PlayerControllersGroup, 
                                             PhysicsGroup.BabblerGroup,
                                             PhysicsGroup.ProjectileGroup,
                                             PhysicsGroup.WeaponGroup,
                                             PhysicsGroup.DroppedWeaponGroup,
                                             PhysicsGroup.CommanderBuildGroup,
                                             PhysicsGroup.PathingGroup,
                                             PhysicsGroup.WebsGroup),
    
    -- Only collide with marines, we don't care about the environment.
    -- OnosStampede = CreateMaskExcludingGroups(PhysicsGroup.MarinePlayerGroup),
    
    -- Filters anything that should not collide with onos charging.
    OnosCharge = CreateMaskExcludingGroups(PhysicsGroup.WhipGroup,
                                           PhysicsGroup.SmallStructuresGroup,
                                           PhysicsGroup.MediumStructuresGroup,
                                           PhysicsGroup.RagdollGroup,
                                           PhysicsGroup.PlayerGroup,
                                           PhysicsGroup.PlayerControllersGroup,
                                           PhysicsGroup.BabblerGroup,
                                           PhysicsGroup.ProjectileGroup,
                                           PhysicsGroup.WeaponGroup,
                                           PhysicsGroup.DroppedWeaponGroup,
                                           PhysicsGroup.CommanderBuildGroup,
                                           PhysicsGroup.PathingGroup,
                                           PhysicsGroup.WebsGroup),
                                           --PhysicsGroup.MarinePlayerGroup),
    
    -- For Drifters, MACs
    AIMovement = CreateMaskExcludingGroups(PhysicsGroup.MediumStructuresGroup,
                                           PhysicsGroup.SmallStructuresGroup,
                                           PhysicsGroup.RagdollGroup,
                                           PhysicsGroup.PlayerGroup,
                                           PhysicsGroup.BigPlayerControllersGroup,
                                           PhysicsGroup.PlayerControllersGroup,
                                           PhysicsGroup.MarinePlayerGroup,
                                           PhysicsGroup.BabblerGroup,
                                           PhysicsGroup.CommanderBuildGroup,
                                           PhysicsGroup.PathingGroup,
                                           PhysicsGroup.WebsGroup),
    
    -- Use these with trace functions to determine which entities we collide with. Use the filter to then
    -- ignore specific entities.
    AllButPCs = CreateMaskExcludingGroups(PhysicsGroup.PlayerControllersGroup,
                                          PhysicsGroup.BigPlayerControllersGroup,
                                          PhysicsGroup.PathingGroup,
                                          PhysicsGroup.MarinePlayerGroup),
    
    -- For things the commander can build on top of other things
    CommanderStack = CreateMaskExcludingGroups(PhysicsGroup.PlayerControllersGroup,
                                               PhysicsGroup.BigPlayerControllersGroup,
                                               PhysicsGroup.PathingGroup,
                                               PhysicsGroup.MarinePlayerGroup),
    
    -- Used for all types of prediction
    AllButPCsAndRagdolls = CreateMaskExcludingGroups(PhysicsGroup.PlayerControllersGroup,
                                                     PhysicsGroup.BigPlayerControllersGroup,
                                                     PhysicsGroup.RagdollGroup,
                                                     PhysicsGroup.PathingGroup,
                                                     PhysicsGroup.MarinePlayerGroup),
    
    AllButTriggers = CreateMaskExcludingGroups(PhysicsGroup.TriggerGroup,
                                               PhysicsGroup.PathingGroup),
    
    -- Shooting
    Bullets = CreateMaskExcludingGroups(PhysicsGroup.PlayerControllersGroup,
                                        PhysicsGroup.BigPlayerControllersGroup,
                                        PhysicsGroup.RagdollGroup,
                                        PhysicsGroup.CollisionGeometryGroup,
                                        PhysicsGroup.WeaponGroup,
                                        PhysicsGroup.CommanderBuildGroup,
                                        PhysicsGroup.ProjectileGroup,
                                        PhysicsGroup.PathingGroup,
                                        PhysicsGroup.WebsGroup,
                                        PhysicsGroup.MarinePlayerGroup),
    
    Flame = CreateMaskExcludingGroups(PhysicsGroup.PlayerControllersGroup,
                                      PhysicsGroup.BigPlayerControllersGroup,
                                      PhysicsGroup.RagdollGroup,
                                      PhysicsGroup.CollisionGeometryGroup,
                                      PhysicsGroup.WeaponGroup,
                                      PhysicsGroup.CommanderBuildGroup,
                                      PhysicsGroup.ProjectileGroup,
                                      PhysicsGroup.PathingGroup,
                                      PhysicsGroup.MarinePlayerGroup),
    
    -- Melee attacks
    Melee = CreateMaskExcludingGroups(PhysicsGroup.PlayerControllersGroup,
                                      PhysicsGroup.BigPlayerControllersGroup,
                                      PhysicsGroup.RagdollGroup,
                                      PhysicsGroup.CollisionGeometryGroup,
                                      PhysicsGroup.WeaponGroup,
                                      PhysicsGroup.CommanderBuildGroup,
                                      PhysicsGroup.ProjectileGroup,
                                      PhysicsGroup.PathingGroup,
                                      PhysicsGroup.WebsGroup,
                                      PhysicsGroup.MarinePlayerGroup),

    PredictedProjectileGroup = CreateMaskExcludingGroups(PhysicsGroup.CollisionGeometryGroup,
                                                         PhysicsGroup.RagdollGroup,
                                                         PhysicsGroup.ProjectileGroup,
                                                         PhysicsGroup.BabblerGroup,
                                                         PhysicsGroup.WeaponGroup,
                                                         PhysicsGroup.DroppedWeaponGroup,
                                                         PhysicsGroup.CommanderBuildGroup,
                                                         PhysicsGroup.PathingGroup,
                                                         PhysicsGroup.WebsGroup,
                                                         PhysicsGroup.MarinePlayerGroup),
    
    -- Allows us to mark props as non interfering for commander selection (culls out any props with commAlpha < 1)
    CommanderSelect = CreateMaskExcludingGroups(PhysicsGroup.PlayerControllersGroup,
                                                PhysicsGroup.BigPlayerControllersGroup,
                                                PhysicsGroup.RagdollGroup,
                                                PhysicsGroup.CommanderPropsGroup,
                                                PhysicsGroup.CollisionGeometryGroup,
                                                PhysicsGroup.PathingGroup,
                                                PhysicsGroup.WebsGroup,
                                                PhysicsGroup.MarinePlayerGroup),
    
    -- The same as commander select mask, minus player entities and structures
    CommanderBuild = CreateMaskExcludingGroups(PhysicsGroup.PlayerControllersGroup,
                                               PhysicsGroup.BigPlayerControllersGroup,
                                               PhysicsGroup.RagdollGroup,
                                               PhysicsGroup.CommanderPropsGroup,
                                               PhysicsGroup.CommanderUnitGroup,
                                               PhysicsGroup.CollisionGeometryGroup,
                                               PhysicsGroup.PathingGroup,
                                               PhysicsGroup.WebsGroup,
                                               PhysicsGroup.MarinePlayerGroup),
    
    -- same as command build, minus CommanderPropsGroup (static props which set alpha to 0), otherwise cysts can be created outside of the map
    CystBuild = CreateMaskExcludingGroups(PhysicsGroup.PlayerControllersGroup,
                                          PhysicsGroup.BigPlayerControllersGroup,
                                          PhysicsGroup.RagdollGroup,
                                          PhysicsGroup.CommanderUnitGroup,
                                          PhysicsGroup.CollisionGeometryGroup,
                                          PhysicsGroup.PathingGroup,
                                          PhysicsGroup.MarinePlayerGroup),
    
    -- Dropped weapons don't collide with the player controller
    DroppedWeaponFilter = CreateMaskIncludingGroups(PhysicsGroup.PlayerControllersGroup,
                                                    PhysicsGroup.BigPlayerControllersGroup,
                                                    PhysicsGroup.RagdollGroup,
                                                    PhysicsGroup.PathingGroup,
                                                    PhysicsGroup.MarinePlayerGroup),
    
    BabblerMovement = CreateMaskIncludingGroups(PhysicsGroup.BabblerGroup),
    
    NoBabblers = CreateMaskIncludingGroups(PhysicsGroup.BabblerGroup,
                                           PhysicsGroup.ProjectileGroup),
    
    OnlyWhip = CreateMaskIncludingGroups(PhysicsGroup.WhipGroup),
    
    Evolve = CreateMaskExcludingGroups(PhysicsGroup.PlayerControllersGroup,
                                       PhysicsGroup.RagdollGroup,
                                       PhysicsGroup.BabblerGroup,
                                       PhysicsGroup.WebsGroup),
    
    AllButPCsAndRagdollsAndBabblers = CreateMaskExcludingGroups(PhysicsGroup.PlayerControllersGroup,
                                                                PhysicsGroup.BigPlayerControllersGroup,
                                                                PhysicsGroup.RagdollGroup,
                                                                PhysicsGroup.PathingGroup,
                                                                PhysicsGroup.BabblerGroup,
                                                                PhysicsGroup.MarinePlayerGroup),
}

PhysicsType = enum
{
    'None',             -- No physics representation.
    'Dynamic',          -- Bones are driven by physics simulation (client-side only)
    'DynamicServer',    -- Bones are driven by physics simulation (synced with server)
    'Kinematic'         -- Physics model is updated by animation
}
