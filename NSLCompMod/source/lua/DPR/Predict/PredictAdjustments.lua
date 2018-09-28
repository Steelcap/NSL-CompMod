// Natural Selection 2 Competitive Mod
// Source located at - https://github.com/xToken/CompMod
// Detailed breakdown of changes at https://docs.google.com/document/d/1YOnjJz6_GhioysLaWiRfc17xnrmw6AEJIb6gq7TX3Qg/edit?pli=1
// lua\CompMod\Predict\PredictAdjustments.lua
// - Dragon
// thx Dragon <3

if Predict then

	local kPredictTable = { }
	local kPredictUpdateRate = 0.5
	local kPredictFullUpdateRate = 0.025
	local kPredictTableBuilt = false
	local kPredictUpdateClasses = { "Clog", "TunnelEntrance" }
	local kPredictFullUpdateClasses = { }
	local kPredictUpdateClassHooks = { }
	
	local function RemoveOldId(entId)
		for i = #kPredictTable, 1, -1 do
			if kPredictTable[i] then
				if kPredictTable[i].i == entId then
					kPredictTable[i] = nil
				end
			end		
		end
	end
	
	local function BuildClassHooks(className)
		local oldClassCreateHook
		oldClassCreateHook = Class_ReplaceMethod(className, "OnCreate",
			function(self)
				oldClassCreateHook(self)
				table.insert(kPredictTable, {i = self:GetId(), t = kPredictUpdateRate})
			end
		)
		local oldClassDestroyHook
		oldClassDestroyHook = Class_ReplaceMethod(className, "OnDestroy",
			function(self)
				RemoveOldId(self:GetId())
				oldClassDestroyHook(self)
			end
		)
		table.insert(kPredictUpdateClassHooks, {classname = className, create = oldClassCreateHook, destroy = oldClassDestroyHook})
	end
	
	function AddClassToPredictionUpdate(className, fullyUpdateFunction, fullUpdateRate)
		if className then
			table.insert(kPredictUpdateClasses, className)
			if kPredictTableBuilt then
				BuildClassHooks(className)
			end
			if fullyUpdateFunction and type(fullyUpdateFunction) == "function" and not kPredictFullUpdateClasses[className] then
				kPredictFullUpdateClasses[className] = { }
				kPredictFullUpdateClasses[className].method = fullyUpdateFunction
				kPredictFullUpdateClasses[className].rate = fullUpdateRate or kPredictFullUpdateRate
			end
		end
	end
	
	local function OnHookPlayer()
		local oldPlayerOnUpdatePlayer
		oldPlayerOnUpdatePlayer = Class_ReplaceMethod("Player", "OnUpdatePlayer",
			function(self, deltaTime)
				for i = #kPredictTable, 1, -1 do
					if kPredictTable[i] then
						kPredictTable[i].t = kPredictTable[i].t - deltaTime
						if kPredictTable[i].t <= 0 then
							local ent = Shared.GetEntity(kPredictTable[i].i)
							if ent and table.contains(kPredictUpdateClasses, ent:GetClassName()) then
								ent:OnUpdate(deltaTime)
								local fUf = kPredictFullUpdateClasses[ent:GetClassName()]
								if fUf and fUf.method and fUf.method(ent) then
									kPredictTable[i].t = kPredictTable[i].t + fUf.rate
								else
									kPredictTable[i].t = kPredictTable[i].t + kPredictUpdateRate
								end
							else
								kPredictTable[i] = nil
							end
						end
					end
				end
			end
		)
	end
	
	function OnPredictVMLoadComplete()
		for i = 1, #kPredictUpdateClasses do
			BuildClassHooks(kPredictUpdateClasses[i])
		end
		OnHookPlayer()
		kPredictTableBuilt = true
	end
	
end