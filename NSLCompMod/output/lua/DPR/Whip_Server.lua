-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Whip_Server.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================


-- reset attack if we don't get an end-tag from the animation inside this time
Whip.kAttackTimeout = 10
local kWhipAttackScanInterval = 0.33
local kSlapAfterBombardTimeout = 2
local kBombardAfterBombardTimeout = 5.3
local kAttackYawTurnRate = 120 -- degrees/sec

Script.Load("lua/Ballistics.lua")

function Whip:UpdateOrders(deltaTime)

    if GetIsUnitActive(self) then
        
        self:UpdateAttack(deltaTime)
        
    end
    
end


function Whip:SetBlockTime(interval)

    assert(type(interval) == "number")
    assert(interval > 0)
    
    self.unblockTime = Shared.GetTime() + interval
    
end



function Whip:OnTeleport()

    if self.rooted then
        self:Unroot()
    end
    
end

function Whip:UpdateRootState()
    
    local infested = self:GetGameEffectMask(kGameEffect.OnInfestation)
    local moveOrdered = self:GetCurrentOrder() and self:GetCurrentOrder():GetType() == kTechId.Move
    -- unroot if we have a move order or infestation recedes
    if self.rooted and (moveOrdered or not infested) then
        self:Unroot()
    end
    
    -- root if on infestation and not moving/teleporting
    if not self.rooted and infested and not (moveOrdered or self:GetIsTeleporting()) then
        self:Root()
    end
    
end

function Whip:Root()

    StartSoundEffectOnEntity(Whip.kRootedSound, self)
    
    self:AttackerMoved() -- reset target sel

    self.rooted = true
    self:SetBlockTime(0.5)
    
    self:EndAttack()
    
    return true
    
end

function Whip:Unroot()

    StartSoundEffectOnEntity(Whip.kUnrootSound, self)
    
    self.rooted = false
    self:SetBlockTime(0.5)
    self:EndAttack()
    self.attackStartTime = nil
    
    return true
    
end

-- handle the targetId
function Whip:OnEntityChange(oldId, newId)

    -- Check if an entity was destroyed.
    if oldId ~= nil and newId == nil then
    
        if oldId == self.targetId then
            self.targetId = Entity.invalidId
        end
 
   end
    
end

function Whip:OnMaturityComplete()

    self:GiveUpgrade(kTechId.WhipBombard)
    
end


function Whip:OnTeleportEnd()

    self:AttackerMoved() -- reset target sel
    self:ResetPathing()
    
end

function Whip:PerformAction(techNode, position)

    local success = false
    
    if techNode:GetTechId() == kTechId.Cancel or techNode:GetTechId() == kTechId.Stop then
    
        self:ClearOrders()
        success = true

    end
    
    return success
    
end


--
-- --- Attack block
--
function Whip:UpdateAttack(deltaTime)
    local now = Shared.GetTime()
    
    local target = Shared.GetEntity(self.targetId)
    if target then
        -- leaving tracking target for later... the other stuff works
        -- self:TrackTarget(target, deltaTime)
    end

    if not self.nextAttackScanTime or now > self.nextAttackScanTime then
        self:UpdateAttacks()
    end
    
    if self.attackStartTime and now > self.attackStartTime + Whip.kAttackTimeout then
        Log("%s: started attack more than %s seconds ago, anim graph bug? Reset...", self, Whip.kAttackTimeout)
        self:EndAttack()
    end
   
end

function Whip:UpdateAttacks()

    if self:GetCanStartSlapAttack() then
        local newTarget = self:TryAttack(self.slapTargetSelector)
        self.nextAttackScanTime = Shared.GetTime() + kWhipAttackScanInterval
        if newTarget then
            self:FaceTarget(newTarget)
            self.targetId = newTarget:GetId()
            self.slapping = true
            self.bombarding = false
        end
    end
    
    if self:GetCanStartBombardAttack() then
        local newTarget = self:TryAttack(self.bombardTargetSelector)
        self.nextAttackScanTime = Shared.GetTime() + kWhipAttackScanInterval
        if newTarget then
            self:FaceTarget(newTarget)
            self.targetId = newTarget:GetId()
            self.bombarding = true
            self.slapping = false;
        end
    end

end


function Whip:GetCanStartSlapAttack()
    if self.slapping or self.bombarding or not self.rooted or self:GetIsOnFire() then
        return false
    end
        
    -- if we are in the aftermath of a long attack (ie, bombarding) and enough time has passed, we can try slapping
    if self.waitingForEndAttack and self.attackStartTime and Shared.GetTime() > self.attackStartTime + kSlapAfterBombardTimeout then
        return true            
    end
    
    return not self.waitingForEndAttack

end

function Whip:GetCanStartBombardAttack()

    if not self:GetIsMature() then
        return false
    end

    if self.slapping or self.bombarding or not self.rooted or self:GetIsOnFire() then
        return false
    end
    
    if self.waitingForEndAttack or self.bombarding or self.slapping then
        return false
    end
    
    -- because bombard attacks can be terminated early, we have a second check to avoid premature bombardment
    if self.bombardAttackStartTime and Shared.GetTime() < self.bombardAttackStartTime + kBombardAfterBombardTimeout then
        return false
    end
    
    return true

end


function Whip:TryAttack(selector)

    -- prioritize hitting the already targeted entity, if possible
    --local target = Shared.GetEntity(self.targetId) 
    --if target and selector:ValidateTarget(target) then
    --    return target
    --end
    return selector:AcquireTarget()

end


local function AvoidSector(yaw, low, high)
    local mid = low + (high - low) / 2
    local result = 0
    if yaw > low and yaw < mid then
        result = low - yaw
    end
    if yaw >= mid and yaw < high then
        result = high - yaw
    end
    return result
end

--
-- figure out the best combo of attack yaw and view yaw to use aginst the given target.
-- returns viewYaw,attackYaw
--
function Whip:CalcTargetYaws(target)

    local point = target:GetEngagementPoint()

    -- Note: The whip animation is screwed up
    -- attack animation: valid for 270-90 degrees.
    -- attack_back : valid for 135-225 using poseParams 225-315
    -- bombard : valid for 270-90 degrees
    -- bombard_back : covers the 135-225 degree area using poseParams 225-315
    -- No valid attack animation covers the 90-135 and 225-270 angles - they are "dead"
    -- To avoid the dead angles, we lerp the view angle at half the attack yaw rate
    
    -- the attack_yaw we calculate here is the actual angle to be attacked. The pose_params
    -- attack_yaw will be transformed to cover it correctly. OnUpdateAnimationInput handles
    -- switching animations by use_back

    -- Update our attackYaw to aim at our current target
    local attackDir = GetNormalizedVector(point - self:GetModelOrigin())
    
    -- the animation rotates the wrong way, mathemathically speaking
    local attackYawRadians = -math.atan2(attackDir.x, attackDir.z)
    
    -- Factor in the orientation of the whip.
    attackYawRadians = attackYawRadians + self:GetAngles().yaw
    
    --[[
    local angles2 = self:GetAngles()
    local p1 = self:GetModelOrigin()
    local c = angles2:GetCoords()
    DebugLine(p1, p1 + c.zAxis * 2, 5, 0, 1, 0, 1)
    angles2.yaw = self:GetAngles().yaw - attackYawRadians
    c = angles2:GetCoords()
    DebugLine(p1, p1 + c.zAxis * 2, 5, 1, 0, 0, 1)
    --]]
    
    local attackYawDegrees = DegreesTo360(math.deg(attackYawRadians), true)
    --Log("%s: attackYawDegrees %s, view angle deg %s", self, attackYawDegrees, DegreesTo360(math.deg(self:GetAngles().yaw)))
    
    -- now figure out any adjustments needed in viewYaw to keep out of the bad animation zones
    local viewYawAdjust = AvoidSector(attackYawDegrees, 90,135)
    if viewYawAdjust == 0 then 
        viewYawAdjust = AvoidSector(attackYawDegrees, 225, 270)
    end
    
    attackYawDegrees = attackYawDegrees - viewYawAdjust
    viewYawAdjust = math.rad(viewYawAdjust)
    
    
    return  viewYawAdjust, attackYawDegrees

end

-- Note: Non-functional; intended to adjust the angle of the model to keep
-- facing the target, but not important enough to spend time on for 267
function Whip:TrackTarget(target, deltaTime)

    local point = target:GetEngagementPoint()

    -- we can't adjust attack yaw after the attack has started, as that will change what animation is run and thus screw
    -- the generation of hit tags. Instead, we rotate the whole whip so the attack will be towards the target
    
    local dir2Target = GetNormalizedVector(point - self:GetModelOrigin())
    
    local yaw2Target = -math.atan2(dir2Target.x, dir2Target.z)
    
    local attackYaw = math.rad(self.attackYaw)
    local desiredYaw = yaw2Target - attackYaw
    
    local angles = self:GetAngles()
    angles.yaw = desiredYaw
    -- think about slerping later
    Log("%s: Tracking to %s", self, desiredYaw)
    -- self:SetAngles(angles)
        
end


function Whip:FaceTarget(target)

    local viewYawAdjust, attackYaw = self:CalcTargetYaws(target)
    local angles = self:GetAngles()

    angles.yaw = angles.yaw + viewYawAdjust
    self:SetAngles(angles)
    
    self.attackYaw = attackYaw
   
end


function Whip:AttackerMoved()

    self.slapTargetSelector:AttackerMoved()
    self.bombardTargetSelector:AttackerMoved()

end

--
-- Slap attack
--
function Whip:SlapTarget(target)
    self:FaceTarget(target)
    -- where we hit
    local targetPoint = target:GetEngagementPoint()
    local attackOrigin = self:GetEyePos()
    local hitDirection = targetPoint - attackOrigin
    hitDirection:Normalize()
    -- fudge a bit - put the point of attack 0.5m short of the target
    local hitPosition = targetPoint - hitDirection * 0.5
    
    self:DoDamage(Whip.kDamage, target, hitPosition, hitDirection, nil, true)
    self:TriggerEffects("whip_attack")

end

--
-- Bombard attack
--
function Whip:BombardTarget(target)
    self:FaceTarget(target)
    -- This seems to fail completly; we get really weird values from the Whip_Ball point,
    local bombStart,success = self:GetAttachPointOrigin("Whip_Ball")
    if not success then
        Log("%s: no Whip_Ball point?", self)
        bombStart = self:GetOrigin() + Vector(0,1,0);
    end
   
    local targetPos = target:GetEngagementPoint()
    
    local direction = Ballistics.GetAimDirection(bombStart, targetPos, Whip.kBombSpeed)
    if direction then
        self:FlingBomb(bombStart, targetPos, direction, Whip.kBombSpeed)
    end

end

function Whip:FlingBomb(bombStart, targetPos, direction, speed)

    local bomb = CreateEntity(WhipBomb.kMapName, bombStart, self:GetTeamNumber())
    
    -- For callback purposes so we can adjust our aim
    bomb.intendedTargetPosition = targetPos
    bomb.shooter = self
    bomb.shooterEntId = self:GetId()
    
    SetAnglesFromVector(bomb, direction)

    local startVelocity = direction * speed
    bomb:Setup( self:GetOwner(), startVelocity, true, nil, self)
    
    -- we set the lifetime so that if the bomb does not hit something, it still explodes in the general area. Good for hunting jetpackers.
    bomb:SetLifetime(self:CalcLifetime(bombStart, targetPos, startVelocity))
    
end

function Whip:CalcLifetime(bombStart, targetPos, startVelocity)

    local xzRange = (targetPos - bombStart):GetLengthXZ()
    local xzVelocity = Vector(startVelocity)
    xzVelocity.y = 0
    xzVelocity:Normalize()
    xzVelocity = xzVelocity:DotProduct(startVelocity)
    
    -- Lifetime is enough to reach target + small random amount.
    local lifetime = xzRange / xzVelocity + math.random() * 0.2 
    
    return lifetime
    
end


-- --- End BombardAttack

-- --- Attack animation handling

function Whip:OnAttackStart() 

    -- attack animation has started, so the attack has started
    if HasMixin(self, "Cloakable") then
        self:TriggerUncloak() 
    end

    if self.bombarding then
        self:TriggerEffects("whip_bombard")
    end
    self.attackStartTime = Shared.GetTime()
    
end

function Whip:OnAttackHit(target)

    if target and self.slapping then
        if not self:GetIsOnFire() and self.slapTargetSelector:ValidateTarget(target) then
            self:SlapTarget(target)                           
        end
    end
    
    if target and self.bombarding then
        if not self:GetIsOnFire() and self.bombardTargetSelector:ValidateTarget(target) then
            self:BombardTarget(target)
        end        
    end
    -- Stop trigger new attacks
    self.slapping = false
    self.bombarding = false    
    -- mark that we are waiting for the end of an attack
    self.waitingForEndAttack = true
    
end

function Whip:EndAttack()

    -- unblock the next attack
    self.attackStartTime = nil
    self.targetId = Entity.invalidId
    self.waitingForEndAttack = false;

    self:UpdateAttacks()

end


function Whip:OnTag(tagName)

    PROFILE("Whip:OnTag")
   
    local target = Shared.GetEntity(self.targetId)
    
    --[[
    if tagName ~= "start" and tagName ~= "end" then
        Log("%s : %s for target %s, slapping %s, bombarding %s", self, tagName, target, self.slapping, self.bombarding)
    end
    --]]
    if tagName == "hit" then
        self:OnAttackHit(target)
    end

    if tagName == "slap_start" then
        self:OnAttackStart(target)                
    end

    if tagName == "slap_end" then
        self:EndAttack()
    end

    if tagName == "bombard_start" then
        self.bombardAttackStartTime = Shared.GetTime()
        self:OnAttackStart(target)                 
    end            

    if tagName == "bombard_end" then
      -- we are only allowed to end our own attack - if a slap-attack has started, we must not terminate it early
      if self.bombardAttackStartTime == self.attackStartTime and not self.slapping then
          self:EndAttack()
      end
    end            

 end
 

-- --- End attack animation