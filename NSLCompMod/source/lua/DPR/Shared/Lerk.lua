local kMaxSpeed = 13 -- same as vanilla

-- Use gravityTable.gravity instead of kSwoopGravity (why, I don't know)
local originalModifyGravityForce
originalModifyGravityForce = Class_ReplaceMethod("Lerk", "ModifyGravityForce",
    function(self, gravityTable)
        if self.gliding or self:GetIsWallGripping() or self:GetIsOnGround() then
            gravityTable.gravity = 0
        elseif self:GetCrouching() then
            gravityTable.gravity = gravityTable.gravity * 4
        end
    end
)

-- Reduce air friction with celerity level instead of constant number
local originalGetAirFriction
originalGetAirFriction = Class_ReplaceMethod("Lerk", "GetAirFriction", 
    function(self)
        return 0.1 - (GetHasCelerityUpgrade(self) and GetSpurLevel(self:GetTeamNumber()) or 0) * 0.02
    end
)

-- Changes forward and strafe flapping force
local function UpdateFlap(self, input, velocity)

    local flapPressed = bit.band(input.commands, Move.Jump) ~= 0

    if flapPressed ~= self.flapPressed then

        self.flapPressed = flapPressed
        self.glideAllowed = not self:GetIsOnGround()

        if flapPressed and self:GetEnergy() > kLerkFlapEnergyCost and not self.gliding then
        
            -- take off
            if self:GetIsOnGround() or input.move:GetLength() == 0 then
                velocity.y = velocity.y * 0.5 + 5

            else

                local flapForce = Lerk.kFlapForce
                local move = Vector(input.move)
                move.x = move.x * 0.75
                -- flap only at 50% speed side wards
                
                local wishDir = self:GetViewCoords():TransformVector(move)
                wishDir:Normalize()

                -- the speed we already have in the new direction
                local currentSpeed = move:DotProduct(velocity)
                -- prevent exceeding max speed of kMaxSpeed by flapping
                local maxSpeedTable = { maxSpeed = kMaxSpeed }
                self:ModifyMaxSpeed(maxSpeedTable, input)
                
                local maxSpeed = math.max(currentSpeed, maxSpeedTable.maxSpeed)
                
                if input.move.z ~= 1 and velocity.y < 0 then
                    -- apply vertical flap
                    velocity.y = velocity.y * 0.5 + 3.8     
                elseif input.move.z == 1 and input.move.x == 0 then
                    -- flapping forward
                    --flapForce = Lerk.kFlapForceForward
                    flapForce = 3 + flapForce + (GetHasCelerityUpgrade(self) and GetSpurLevel(self:GetTeamNumber()) or 0) * 0.3               
                elseif input.move.z == 0 and input.move.x ~= 0 then
                    -- strafe flapping
                    --flapForce = Lerk.kFlapForceStrafe
                    velocity.y = velocity.y + 3.5
                end
                
                -- directional flap
                velocity:Scale(0.65)
                velocity:Add(wishDir * flapForce)
                
                if velocity:GetLengthSquared() > maxSpeed * maxSpeed then
                    velocity:Normalize()
                    velocity:Scale(maxSpeed)
                end
                
            end
 
            self:DeductAbilityEnergy(kLerkFlapEnergyCost)
            self.lastTimeFlapped = Shared.GetTime()
            self.onGround = false
            self:TriggerEffects("flap")

        end

    end

end

ReplaceLocals(Lerk.ModifyVelocity, {UpdateFlap = UpdateFlap})

local function UpdateCrouchDive(self, input, velocity, deltaTime)
    -- Ignore vanilla's extra crouch dive stuff
end

ReplaceLocals(Lerk.ModifyVelocity, {UpdateCrouchDive = UpdateCrouchDive})
