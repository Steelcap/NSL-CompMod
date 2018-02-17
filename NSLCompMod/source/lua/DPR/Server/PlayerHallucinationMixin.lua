-- hallucinated players don't ragdoll
-- thanks Dragon :)
function PlayerHallucinationMixin:OnKill()
    self:TriggerEffects("death_hallucination")
    self:SetBypassRagdoll(true)
end