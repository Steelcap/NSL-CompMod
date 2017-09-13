-- PowerSurge doesn't need researching
function MarineTeam:InitTechTree()
   
   PlayingTeam.InitTechTree(self)
    
    -- Marine tier 1
    self.techTree:AddBuildNode(kTechId.CommandStation,            kTechId.None,                kTechId.None)
    self.techTree:AddBuildNode(kTechId.Extractor,                 kTechId.None,                kTechId.None)
    
    self.techTree:AddUpgradeNode(kTechId.ExtractorArmor)
    
    -- Count recycle like an upgrade so we can have multiples
    self.techTree:AddUpgradeNode(kTechId.Recycle, kTechId.None, kTechId.None)
    
    self.techTree:AddPassive(kTechId.Welding)
    self.techTree:AddPassive(kTechId.SpawnMarine)
    self.techTree:AddPassive(kTechId.CollectResources, kTechId.Extractor)
    self.techTree:AddPassive(kTechId.Detector)
    
    self.techTree:AddSpecial(kTechId.TwoCommandStations)
    self.techTree:AddSpecial(kTechId.ThreeCommandStations)
    
    -- When adding marine upgrades that morph structures, make sure to add to GetRecycleCost() also
    self.techTree:AddBuildNode(kTechId.InfantryPortal,            kTechId.CommandStation,                kTechId.None)
    self.techTree:AddBuildNode(kTechId.Sentry,                    kTechId.RoboticsFactory,     kTechId.None, true)
    self.techTree:AddBuildNode(kTechId.Armory,                    kTechId.CommandStation,      kTechId.None)  
    self.techTree:AddBuildNode(kTechId.ArmsLab,                   kTechId.CommandStation,                kTechId.None)  
    self.techTree:AddManufactureNode(kTechId.MAC,                 kTechId.RoboticsFactory,                kTechId.None,  true) 

    self.techTree:AddBuyNode(kTechId.Axe,                         kTechId.None,              kTechId.None)
    self.techTree:AddBuyNode(kTechId.Pistol,                      kTechId.None,                kTechId.None)
    self.techTree:AddBuyNode(kTechId.Rifle,                       kTechId.None,                kTechId.None)

    self.techTree:AddBuildNode(kTechId.SentryBattery,             kTechId.RoboticsFactory,      kTechId.None)      
    
    self.techTree:AddOrder(kTechId.Defend)
    self.techTree:AddOrder(kTechId.FollowAndWeld)
    
    -- Commander abilities
    self.techTree:AddResearchNode(kTechId.NanoShieldTech)
    self.techTree:AddResearchNode(kTechId.CatPackTech)
    --self.techTree:AddResearchNode(kTechId.PowerSurgeTech)

    self.techTree:AddTargetedActivation(kTechId.NanoShield,       kTechId.NanoShieldTech)
    self.techTree:AddTargetedActivation(kTechId.Scan,             kTechId.Observatory)
    self.techTree:AddTargetedActivation(kTechId.PowerSurge,       kTechId.RoboticsFactory)
    self.techTree:AddTargetedActivation(kTechId.MedPack,          kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.AmmoPack,         kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.CatPack,          kTechId.CatPackTech) 
    
    self.techTree:AddAction(kTechId.SelectObservatory)

    -- Armory upgrades
    self.techTree:AddUpgradeNode(kTechId.AdvancedArmoryUpgrade,  kTechId.Armory)
    
    -- arms lab upgrades
    
    self.techTree:AddResearchNode(kTechId.Armor1,                 kTechId.ArmsLab)
    self.techTree:AddResearchNode(kTechId.Armor2,                 kTechId.Armor1, kTechId.None)
    self.techTree:AddResearchNode(kTechId.Armor3,                 kTechId.Armor2, kTechId.None)    
    self.techTree:AddResearchNode(kTechId.NanoArmor,              kTechId.None)
    
    self.techTree:AddResearchNode(kTechId.Weapons1,               kTechId.ArmsLab)
    self.techTree:AddResearchNode(kTechId.Weapons2,               kTechId.Weapons1, kTechId.None)
    self.techTree:AddResearchNode(kTechId.Weapons3,               kTechId.Weapons2, kTechId.None)
    
    -- Marine tier 2
    self.techTree:AddBuildNode(kTechId.AdvancedArmory,               kTechId.Armory,        kTechId.None)
    self.techTree:AddResearchNode(kTechId.PhaseTech,                    kTechId.Observatory,        kTechId.None)
    self.techTree:AddBuildNode(kTechId.PhaseGate,                    kTechId.PhaseTech,        kTechId.None, true)


    self.techTree:AddBuildNode(kTechId.Observatory,               kTechId.InfantryPortal,       kTechId.Armory)      
    self.techTree:AddActivation(kTechId.DistressBeacon,           kTechId.Observatory)         
    
    -- Door actions
    self.techTree:AddBuildNode(kTechId.Door, kTechId.None, kTechId.None)
    self.techTree:AddActivation(kTechId.DoorOpen)
    self.techTree:AddActivation(kTechId.DoorClose)
    self.techTree:AddActivation(kTechId.DoorLock)
    self.techTree:AddActivation(kTechId.DoorUnlock)
    
    -- Weapon-specific
    self.techTree:AddResearchNode(kTechId.ShotgunTech,           kTechId.Armory,              kTechId.None)
    self.techTree:AddTargetedBuyNode(kTechId.Shotgun,            kTechId.ShotgunTech,         kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.DropShotgun,     kTechId.ShotgunTech,         kTechId.None)

    self.techTree:AddResearchNode(kTechId.HeavyMachineGunTech,           kTechId.AdvancedWeaponry,              kTechId.None)
    self.techTree:AddTargetedBuyNode(kTechId.HeavyMachineGun,            kTechId.HeavyMachineGunTech,         kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.DropHeavyMachineGun,     kTechId.HeavyMachineGunTech,         kTechId.None)
    
    self.techTree:AddResearchNode(kTechId.AdvancedWeaponry,      kTechId.AdvancedArmory,      kTechId.None)    
    
    self.techTree:AddTargetedBuyNode(kTechId.GrenadeLauncher,  kTechId.AdvancedWeaponry)
    self.techTree:AddTargetedActivation(kTechId.DropGrenadeLauncher,  kTechId.AdvancedWeaponry)
    
    self.techTree:AddResearchNode(kTechId.GrenadeTech,           kTechId.Armory,                   kTechId.None)
    self.techTree:AddTargetedBuyNode(kTechId.ClusterGrenade,     kTechId.GrenadeTech)
    self.techTree:AddTargetedBuyNode(kTechId.GasGrenade,         kTechId.GrenadeTech)
    self.techTree:AddTargetedBuyNode(kTechId.PulseGrenade,       kTechId.GrenadeTech)
    
    self.techTree:AddTargetedBuyNode(kTechId.Flamethrower,     kTechId.AdvancedWeaponry)
    self.techTree:AddTargetedActivation(kTechId.DropFlamethrower,    kTechId.AdvancedWeaponry)
    
    self.techTree:AddResearchNode(kTechId.MinesTech,            kTechId.Armory,           kTechId.None)
    self.techTree:AddTargetedBuyNode(kTechId.LayMines,          kTechId.MinesTech,        kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.DropMines,      kTechId.MinesTech,        kTechId.None)
    
    self.techTree:AddTargetedBuyNode(kTechId.Welder,          kTechId.Armory,        kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.DropWelder,   kTechId.Armory,        kTechId.None)
    
    -- ARCs
    self.techTree:AddBuildNode(kTechId.RoboticsFactory,                    kTechId.InfantryPortal,                 kTechId.None)  
    self.techTree:AddUpgradeNode(kTechId.UpgradeRoboticsFactory,           kTechId.Armory,              kTechId.RoboticsFactory) 
    self.techTree:AddBuildNode(kTechId.ARCRoboticsFactory,                 kTechId.Armory,              kTechId.RoboticsFactory)
    
    self.techTree:AddTechInheritance(kTechId.RoboticsFactory, kTechId.ARCRoboticsFactory)
   
    self.techTree:AddManufactureNode(kTechId.ARC,    kTechId.ARCRoboticsFactory,     kTechId.None, true)        
    self.techTree:AddActivation(kTechId.ARCDeploy)
    self.techTree:AddActivation(kTechId.ARCUndeploy)
    
    -- Robotics factory menus
    self.techTree:AddMenu(kTechId.RoboticsFactoryARCUpgradesMenu)
    self.techTree:AddMenu(kTechId.RoboticsFactoryMACUpgradesMenu)
    
    self.techTree:AddMenu(kTechId.WeaponsMenu)
    
    -- Marine tier 3
    self.techTree:AddBuildNode(kTechId.PrototypeLab,          kTechId.AdvancedArmory,              kTechId.None)        

    -- Jetpack
    self.techTree:AddResearchNode(kTechId.JetpackTech,           kTechId.PrototypeLab, kTechId.None)
    self.techTree:AddBuyNode(kTechId.Jetpack,                    kTechId.JetpackTech, kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.DropJetpack,    kTechId.JetpackTech, kTechId.None)
    
    -- Exosuit
    self.techTree:AddResearchNode(kTechId.ExosuitTech,           kTechId.PrototypeLab, kTechId.None)
    self.techTree:AddBuyNode(kTechId.DualMinigunExosuit, kTechId.ExosuitTech, kTechId.None)
    self.techTree:AddBuyNode(kTechId.DualRailgunExosuit, kTechId.ExosuitTech, kTechId.None)
    
  --  self.techTree:AddTargetedActivation(kTechId.DropExosuit,     kTechId.ExosuitTech, kTechId.None)
    
    --self.techTree:AddResearchNode(kTechId.DualMinigunTech,       kTechId.ExosuitTech, kTechId.TwoCommandStations)
    --self.techTree:AddResearchNode(kTechId.DualMinigunExosuit,    kTechId.DualMinigunTech, kTechId.TwoCommandStations)
    --self.techTree:AddResearchNode(kTechId.ClawRailgunExosuit,    kTechId.ExosuitTech, kTechId.None)
    --self.techTree:AddResearchNode(kTechId.DualRailgunTech,       kTechId.ExosuitTech, kTechId.TwoCommandStations)
    --self.techTree:AddResearchNode(kTechId.DualRailgunExosuit,    kTechId.DualMinigunTech, kTechId.TwoCommandStations)
    

    self.techTree:AddActivation(kTechId.SocketPowerNode,    kTechId.None,   kTechId.None)
    
    self.techTree:SetComplete()

end
