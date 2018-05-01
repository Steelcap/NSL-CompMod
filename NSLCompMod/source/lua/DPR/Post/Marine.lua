function Marine:GetMedpackLevel()

    local medLevel = 0
    local techTree = self:GetTechTree()

    if techTree then
        
            local med2Node = techTree:GetTechNode(kTechId.MedTech2)
            local med1Node = techTree:GetTechNode(kTechId.MedTech1)
        
			if med2Node and med2Node:GetResearched()  then
                medLevel = 2
            elseif med1Node and med1Node:GetResearched()  then
                medLevel = 1
            end
            
    end

    return medLevel

end
