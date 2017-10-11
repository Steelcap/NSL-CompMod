-- Each upgrade swapped costs this much extra evolution time
local kUpgradeSwapGestateTime = 1

local kMinGestationTime = 1 -- same as vanilla

-- Take extra evolution time for each upgrade you swap
local origSetGestationData
origSetGestationData = Class_ReplaceMethod("Embryo", "SetGestationData",
    function(self, techIds, previousTechId, healthScalar, armorScalar)
        -- get this before origSetGestationData clears upgrade data
        local previousUpgrades = self:GetUpgrades()

        origSetGestationData(self, techIds, previousTechId, healthScalar, armorScalar)

        -- in some cases we can use the original gestation time
        local firstUpgrade = #previousUpgrades == 0
        local newLifeform = self.gestationTypeTechId ~= previousTechId
        local emptyUpgrades = #self.evolvingUpgrades == 0
        local devOrWarmUp = Shared.GetDevMode() or GetGameInfoEntity():GetWarmUpActive()
        local fastEvolveCheat = Embryo.gFastEvolveCheat

        if firstUpgrade or newLifeform or emptyUpgrades or devOrWarmUp or fastEvolveCheat then
            return
        end

        local previousHives = {}
        for _, upgradeId in ipairs(previousUpgrades) do
            local hiveId = LookupTechData(upgradeId, kTechDataCategory)

            previousHives[hiveId] = true
        end

        local swappedUpgradesAmount = 0
        for _, upgradeId in ipairs(self.evolvingUpgrades) do
            if not table.contains(previousUpgrades, upgradeId) then
                local hiveId = LookupTechData(upgradeId, kTechDataCategory)

                if previousHives[hiveId] then
                    swappedUpgradesAmount = swappedUpgradesAmount + 1
                end
            end
        end

        self.gestationTime = self.gestationTime + swappedUpgradesAmount * kUpgradeSwapGestateTime
        self.gestationTime = math.max(kMinGestationTime, self.gestationTime)
    end
)
