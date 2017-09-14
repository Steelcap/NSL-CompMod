-- Hide the opposing team's commander in pregame
local function GetIsVisibleTeam(teamNumber)
    local isVisibleTeam = false
    local localPlayer = Client.GetLocalPlayer()
    if localPlayer then
    
        local localPlayerTeamNum = localPlayer:GetTeamNumber()
        -- Can see secret information if the player is on the team or is a spectator.
        if teamNumber == kTeamReadyRoom or localPlayerTeamNum == teamNumber or localPlayerTeamNum == kSpectatorIndex then
            isVisibleTeam = true
        end
        
    end
    
    -- if not isVisibleTeam then
        -- -- Allow seeing who is commander during pre-game
        -- local gInfo = GetGameInfoEntity()
        -- if gInfo and gInfo:GetState() <= kGameState.PreGame then
            -- return true
        -- end
    -- end
    
    return isVisibleTeam
end

ReplaceLocals( GUIScoreboard.UpdateTeam, {  GetIsVisibleTeam = GetIsVisibleTeam } )
ReplaceLocals( GUIScoreboard.SendKeyEvent, {  GetIsVisibleTeam = GetIsVisibleTeam } )
