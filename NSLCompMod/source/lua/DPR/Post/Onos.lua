Onos.kMaxSpeed = 7.5

Onos.kStampedeDefaultSettings =
{
    kChargeImpactForce = 0,
    kChargeDiffForce = 0,
    kChargeUpForce = 0,
    kDisableDuration = 0.2,
}

-- Mods can add their own overrides for other classes.
Onos.kStampedeOverrideSettings = Onos.kStampedeOverrideSettings or {}
Onos.kStampedeOverrideSettings["Exo"] = 
{
    kChargeImpactForce = 0,
    kChargeDiffForce = 0,
    kChargeUpForce = 0,
    kDisableDuration = 0.05,
}