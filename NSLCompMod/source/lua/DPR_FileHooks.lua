local function GetVanillaPath(DPRPath)
    DPRPath = string.gsub(DPRPath, "DPR/Replace/", "")
    DPRPath = string.gsub(DPRPath, "DPR/Post/", "")
    
    return DPRPath
end

local ReplaceFiles = {}
Shared.GetMatchingFileNames("lua/DPR/Replace/*.lua", true, ReplaceFiles) --what does the bool do? recurse?

for i = 1, #ReplaceFiles do
    ModLoader.SetupFileHook(GetVanillaPath(ReplaceFiles[i]), ReplaceFiles[i], "replace")
end

local PostFiles = {}
Shared.GetMatchingFileNames("lua/DPR/Post/*.lua", true, PostFiles) --what does the bool do? recurse?

for i = 1, #PostFiles do
    ModLoader.SetupFileHook(GetVanillaPath(PostFiles[i]), PostFiles[i], "post")
end
