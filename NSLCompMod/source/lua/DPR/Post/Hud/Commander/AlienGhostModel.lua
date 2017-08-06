local kFontColor = Color(1, 0.8, 0.2)

local origInit = AlienGhostModel.Initialize
function AlienGhostModel:Initialize()
    origInit(self)

    if not self.specialText then
        self.specialText = GUIManager:CreateTextItem()
        self.specialText:SetIsVisible(false)
        self.specialText:SetFontName(Fonts.kStamp_Medium)
        self.specialText:SetColor(kFontColor)
        self.specialText:SetLayer(kGUILayerCommanderHUD)
    end
end

local origDestroy = AlienGhostModel.Destroy
function AlienGhostModel:Destroy()
    origDestroy(self)

    if self.specialText then
        GUI.DestroyItem(self.specialText)
        self.specialText = nil
    end
end

local origUpdate = AlienGhostModel.Update
function AlienGhostModel:Update()
    local modelCoords = GhostModel.Update(self)

    if modelCoords then
        self.cinematic:SetCoords(modelCoords)

        if GhostModelUI_GetTunnelName then
            self.specialText:SetIsVisible(true)
            local text = string.format(GhostModelUI_GetTunnelName())
            self.specialText:SetPosition(Client.WorldToScreen(modelCoords.origin) - Vector( 2 + (text:len()/2) ,0,0) )
            self.specialText:SetText(text)
        else
            self.specialText:SetIsVisible(false)
        end
    end
end
