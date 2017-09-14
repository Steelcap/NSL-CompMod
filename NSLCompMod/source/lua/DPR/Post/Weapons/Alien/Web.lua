-- Same as vanilla
local function GetDistance(self, fromPlayer)

    local tranformCoords = self:GetCoords():GetInverse()
    local relativePoint = tranformCoords:TransformPoint(fromPlayer:GetOrigin())    

    return math.abs(relativePoint.x), relativePoint.y

end

-- Remove parasite ability
local function NSLCheckForIntersection(self, fromPlayer)

    if not self.endPoint then
        self.endPoint = self:GetOrigin() + self.length * self:GetCoords().zAxis
    end
    
    if fromPlayer then
    
        -- need to manually check for intersection here since the local players physics are invisible and normal traces would fail
        local playerOrigin = fromPlayer:GetOrigin()
        local extents = fromPlayer:GetExtents()
        local fromWebVec = playerOrigin - self:GetOrigin()
        local webDirection = -self:GetCoords().zAxis
        local dotProduct = webDirection:DotProduct(fromWebVec)

        local minDistance = - extents.z
        local maxDistance = self.length + extents.z
        
        if dotProduct >= minDistance and dotProduct < maxDistance then
        
            local horizontalDistance, verticalDistance = GetDistance(self, fromPlayer)
            
            local horizontalOk = horizontalDistance <= extents.z
            local verticalOk = verticalDistance >= 0 and verticalDistance <= extents.y * 2         

            --DebugPrint("horizontalDistance %s  verticalDistance %s", ToString(horizontalDistance), ToString(verticalDistance))

            if horizontalOk and verticalOk then
              
                fromPlayer:SetWebbed(kWebbedDuration)
                
                --FIXME Web seems to not have Owner applied, because this is running in ProcessMove
                --  Owner only accessible on ServerVM ...
                -- if HasMixin( fromPlayer, "ParasiteAble" ) and HasMixin( self, "Owner" ) then
                    -- --TODO Modify ParasiteMixin to specify a duration
                    -- local WebOwner = self:GetOwner() or nil
                    -- fromPlayer:SetParasited( WebOwner, kWebbedParasiteDuration )
                -- end
                
                if Server then
                    DestroyEntity(self)
                end
          
            end
        
        end
    
    elseif Server then
    
        local trace = Shared.TraceRay(self:GetOrigin(), self.endPoint, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterNonWebables())
        if trace.entity and not trace.entity:isa("Player") then
            trace.entity:SetWebbed(kWebbedDuration)
            DestroyEntity(self)
        end    
    
    end

end 

-- Call changed function
function Web:UpdateWebOnProcessMove(fromPlayer)
    NSLCheckForIntersection(self, fromPlayer)
end

-- Call changed function
if Server then

    local function TriggerWebSpawnEffects(self)

        local startPoint = self:GetOrigin()
        local zAxis = -self:GetCoords().zAxis
        
        for i = 1, 20 do

            local effectPoint = startPoint + zAxis * 0.36 * i
            
            if (effectPoint - startPoint):GetLength() >= self.length then
                break
            end

            self:TriggerEffects("web_create", { effecthostcoords = Coords.GetTranslation(effectPoint) })    
        
        end
    
    end

    -- OnUpdate is only called when entities are in interest range, players are ignored here since they need to predict the effect
    function Web:OnUpdate(deltaTime)

        if self.enemiesInRange then        
            NSLCheckForIntersection(self)            
        end
        
        if not self.triggerSpawnEffect then
            TriggerWebSpawnEffects(self)
            self.triggerSpawnEffect = true
        end

    end
end
