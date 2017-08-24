-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Weapons\Alien\BoneShield.lua
--
--    Created by:   Andreas Urwalek (andi@unknownworlds.com)
--
--    Puts the onos in a defensive, slow moving position where it uses energy to absorb damage.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/StompMixin.lua")

class 'BoneShield' (Ability)

BoneShield.kMapName = "boneshield"

local kAnimationGraph = PrecacheAsset("models/alien/onos/onos_view.animation_graph")

local networkVars =
{
    lastShieldTime = "private time",
    timeFuelChanged = "private time",
    fuelAtChange = "private float (0 to 1 by 0.01)",
}

AddMixinNetworkVars(StompMixin, networkVars)

function BoneShield:OnCreate()

    Ability.OnCreate(self)
    
    InitMixin(self, StompMixin)
   
    self.lastShieldTime = 0 
    self.timeFuelChanged = 0
    self.fuelAtChange = 1

end

function BoneShield:SetFuel(fuel)
   self.timeFuelChanged = Shared.GetTime()
   self.fuelAtChange = fuel
end

function BoneShield:GetFuel()
    if self.primaryAttacking then
        return Clamp(self.fuelAtChange - (Shared.GetTime() - self.timeFuelChanged) / kBoneShieldMaxDuration, 0, 1)
    else
        return Clamp(self.fuelAtChange + (Shared.GetTime() - self.timeFuelChanged) / kBoneShieldCooldown, 0, 1)
    end
end

function BoneShield:GetEnergyCost()
    return kBoneShieldInitialEnergyCost
end

function BoneShield:GetAnimationGraphName()
    return kAnimationGraph
end

function BoneShield:GetHUDSlot()
    return 2
end

function BoneShield:GetCooldownFraction()
    return 1 - self:GetFuel()
end
    
function BoneShield:IsOnCooldown()
    return self:GetFuel() < kBoneShieldMinimumFuel
end

function BoneShield:GetCanUseBoneShield(player)
    return not self:IsOnCooldown() and not self.secondaryAttacking and not player.charging
end

function BoneShield:OnPrimaryAttack(player)

    if not self.primaryAttacking then
        if player:GetIsOnGround() and self:GetCanUseBoneShield(player) and self:GetEnergyCost() < player:GetEnergy() then
                
            player:DeductAbilityEnergy(self:GetEnergyCost())
            
            self:SetFuel( self:GetFuel() ) -- set it now, because it will go down from this point
            self.primaryAttacking = true
			self.lastShieldTime = Shared.GetTime()
            
            if Server then
                player:TriggerEffects("onos_shield_start")
            end
        end
    end

end

function BoneShield:OnPrimaryAttackEnd(player)
    
    if self.primaryAttacking then 
    
        self:SetFuel( self:GetFuel() ) -- set it now, because it will go up from this point
        self.primaryAttacking = false
    
    end
    
end

function BoneShield:OnUpdateAnimationInput(modelMixin)

    local activityString = "none"
    local abilityString = "boneshield"
    
    if self.primaryAttacking then
        activityString = "primary" -- TODO: set anim input
    end
    
    modelMixin:SetAnimationInput("ability", abilityString)
    modelMixin:SetAnimationInput("activity", activityString)
    
end

function BoneShield:OnHolster(player)

    Ability.OnHolster(self, player)
    
    self:OnPrimaryAttackEnd(player)
    
end

function BoneShield:OnProcessMove(input)

    if self.primaryAttacking then
        
        if self:GetFuel() > 0 then
            
            local player = self:GetParent()
            if player then
                
                player:AddHealth(kBoneShieldHealPerSecond * input.time, true, false, true, player)
                player:AddArmor(kBoneShieldArmorPerSecond * input.time, true, true, player)
                
            end
        
        else
           
            self:SetFuel( 0 )
            self.primaryAttacking = false
           
        end
        
    end

end

Shared.LinkClassToMap("BoneShield", BoneShield.kMapName, networkVars)