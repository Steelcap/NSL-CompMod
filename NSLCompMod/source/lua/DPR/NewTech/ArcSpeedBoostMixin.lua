-- thx Dragon <3

ArcSpeedBoostMixin = CreateMixin( ArcSpeedBoostMixin )
ArcSpeedBoostMixin.type = "ARCSpeedBoost"

PrecacheAsset("cinematics/vfx_materials/arcspeedboost.surface_shader")
local kARCSpeedBoostMaterial = PrecacheAsset("cinematics/vfx_materials/arcspeedboost.material")

ArcSpeedBoostMixin.networkVars =
{
    speedboost = "boolean",
	oncooldown = "boolean",
	speedboosttime = "time"
}

function ArcSpeedBoostMixin:__initmixin()

    if Server then
    
        self.speedboost = false
		self.oncooldown = false
		self.speedboosttime = 0
        
    end
    
end

local function ClearEffects(self)

    self.speedboost = false
	self.oncooldown = false
	self.speedboosttime = 0 
    
    if Client then
        self:_RemoveEffect()
    end
    
end

function ArcSpeedBoostMixin:OnDestroy()

    if self:HasSpeedBoost() then
        ClearEffects(self)
    end
    
end

local function SpeedBoostOffCooldown(self)
	self.speedboost = false
	self.oncooldown = false
	return false
end

local function DisableSpeedBoost(self)
	self.speedboost = false
	self:AddTimedCallback(SpeedBoostOffCooldown, math.ceil(kARCSpeedBoostCooldown - kARCSpeedBoostDuration))
	return false
end

function ArcSpeedBoostMixin:TriggerSpeedBoost()
	self.speedboost = true
	self.oncooldown = true
	self.speedboosttime = Shared.GetTime()
	self:AddTimedCallback(DisableSpeedBoost, kARCSpeedBoostDuration)
end

function ArcSpeedBoostMixin:ModifyMaxSpeed(maxSpeedTable)
	if self:HasSpeedBoost() then
		maxSpeedTable.maxSpeed = ARC.kMoveSpeed * kARCSpeedBoostIncrease
	end
end

local function ValidateSpeedBoost(self)
	if (self.oncooldown or self.speedboost) and Server then
		local timePassed = Shared.GetTime() - self.speedboosttime
		if timePassed > kARCSpeedBoostCooldown then
			//OFF Cooldown!
			self.oncooldown = false
		end
		if timePassed > kARCSpeedBoostIncrease then
			//Not boosting anymore
			self.speedboost = false
		end
	end
end

function ArcSpeedBoostMixin:HasSpeedBoost()
	//ValidateSpeedBoost(self)
	//Should this validate just in case?...
	return self.speedboost
end

function ArcSpeedBoostMixin:SpeedBoostOnCooldown()
	return self.oncooldown
end

function ArcSpeedBoostMixin:SpeedBoostCooldown()
	if self:SpeedBoostOnCooldown() then
		local timePassed = Shared.GetTime() - self.speedboosttime
        return 1 - math.min(1, timePassed / kARCSpeedBoostCooldown)
	end
	return 0
end

if Client then

	local function UpdateClientSpeedBoostEffects(self)

		if self:HasSpeedBoost() and self:GetIsAlive() then
			self:_CreateEffect()
		else
			self:_RemoveEffect() 
		end
		
	end

	local function SharedUpdate(self)
		   
		if not Shared.GetIsRunningPrediction() then
			UpdateClientSpeedBoostEffects(self)
		end
		
	end
	
	function ArcSpeedBoostMixin:OnUpdate(deltaTime)   
		SharedUpdate(self)
	end

    local function AddEffect(entity, material, entities)
	
		local numChildren = entity:GetNumChildren()
			
		if HasMixin(entity, "Model") then
			local model = entity._renderModel
			if model ~= nil then
				model:AddMaterial(material)
				table.insert(entities, entity:GetId())
			end
		end
		
		for i = 1, entity:GetNumChildren() do
			local child = entity:GetChildAtIndex(i - 1)
			AddEffect(child, material, entities)
		end
		
    end
    
    local function RemoveEffect(entities, material)
    
		for i =1, #entities do
            local entity = Shared.GetEntity( entities[i] )
            if entity ~= nil and HasMixin(entity, "Model") then
                local model = entity._renderModel
                if model ~= nil then
                    model:RemoveMaterial(material)
                end                    
            end
        end
    end

    function ArcSpeedBoostMixin:_CreateEffect()
   
        if not self.speedBoostMaterial then
        
            local material = Client.CreateRenderMaterial()
            material:SetMaterial(kARCSpeedBoostMaterial)
			self.speedBoostEntities = {}
            AddEffect(self, material, self.speedBoostEntities)
            self.speedBoostMaterial = material
            
        end    
        
    end

    function ArcSpeedBoostMixin:_RemoveEffect()

        if self.speedBoostMaterial then
		
            RemoveEffect(self.speedBoostEntities, self.speedBoostMaterial)
            Client.DestroyRenderMaterial(self.speedBoostMaterial)
            self.speedBoostMaterial = nil
			self.speedBoostEntities = nil
			
        end            

    end
    
end