--This global disables balance changes of the UWE Extensions
gDisableUWEBalance = true

local SharedFiles = {}
Shared.GetMatchingFileNames("lua/DPR/Shared/*.lua", true, SharedFiles) --what does the bool do? recurse?

for i = 1, #SharedFiles do
    Script.Load(SharedFiles[i])
end