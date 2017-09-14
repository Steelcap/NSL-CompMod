-- halve the diameter of railgun bullets
local kBulletSize = 0.15
ReplaceUpValue(Railgun.OnTag, "kBulletSize", kBulletSize, {LocateRecurse = true})
