-- thx Dragon <3

WalkMixin = CreateMixin( WalkMixin )
WalkMixin.type = "Walk"

WalkMixin.networkVars =
{
    walking = "boolean"
}

function WalkMixin:__initmixin()
    self.walking = false
end

function WalkMixin:GetIsWalking()
    return self.walking
end

function WalkMixin:UpdateWalkMode(input)

    local walkState = bit.band(input.commands, Move.ReadyRoom) ~= 0
	local canWalk = not self.crouching and self:GetIsOnGround() and not self.sprinting
	
    if walkState ~= self.walking then
		if walkState and canWalk then
			self.walking = true
		else
			self.walking = false
		end
    end
	
	if self.walking and not canWalk then
		self.walking = false
	end
    
end