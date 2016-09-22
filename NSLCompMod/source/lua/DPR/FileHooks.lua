--This global disables balance changes of the UWE Extensions
gDisableUWEBalance = true

ModLoader.SetupFileHook( "lua/ResourceTower_Server.lua", "lua/DPR/ResourceTower_Server.lua", "replace" )
ModLoader.SetupFileHook( "lua/AlienTeam.lua", "lua/DPR/AlienTeam.lua", "replace" )
ModLoader.SetupFileHook( "lua/TechData.lua", "lua/DPR/TechData.lua", "replace" )
ModLoader.SetupFileHook( "lua/Cyst.lua", "lua/DPR/Cyst.lua", "replace" )
ModLoader.SetupFileHook( "lua/Egg.lua", "lua/DPR/Egg.lua", "replace" )
ModLoader.SetupFileHook( "lua/Ability.lua", "lua/DPR/Ability.lua", "replace" )
ModLoader.SetupFileHook( "lua/Shotgun.lua", "lua/DPR/Shotgun.lua", "replace" )
ModLoader.SetupFileHook( "lua/GUIUpgradeChamberDisplay.lua", "lua/DPR/GUIUpgradeChamberDisplay.lua", "replace" )

ModLoader.SetupFileHook( "lua/BalanceMisc.lua", "lua/DPR/BalanceMisc.lua", "post" )
ModLoader.SetupFileHook( "lua/Balance.lua", "lua/DPR/Balance.lua", "post" )
ModLoader.SetupFileHook( "lua/BalanceHealth.lua", "lua/DPR/BalanceHealth.lua", "post" )
ModLoader.SetupFileHook( "lua/AlienTechMap.lua", "lua/DPR/AlienTechMap.lua", "post" )
ModLoader.SetupFileHook( "lua/Gorge.lua", "lua/DPR/Gorge.lua", "post" )
ModLoader.SetupFileHook( "lua/DamageTypes.lua", "lua/DPR/DamageTypes.lua", "post" )
ModLoader.SetupFileHook( "lua/Player_Client.lua", "lua/DPR/Player_Client.lua", "post" )
ModLoader.SetupFileHook( "lua/Alien_Server.lua", "lua/DPR/Alien_Server.lua", "post" )