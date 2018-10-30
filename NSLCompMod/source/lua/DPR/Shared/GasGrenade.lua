
local kLifeTime = 7.5 -- 10
local kNerveGasCloudLifetime = 4.5 -- 6

ReplaceLocals(GasGrenade.OnCreate, {kLifeTime = kLifeTime})
ReplaceLocals(NerveGasCloud.OnCreate, {kNerveGasCloudLifetime = kNerveGasCloudLifetime})