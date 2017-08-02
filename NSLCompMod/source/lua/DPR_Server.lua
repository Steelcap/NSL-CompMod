local ServerFiles = {}
Shared.GetMatchingFileNames("lua/DPR/Server/*.lua", true, ServerFiles) --what does the bool do? recurse?

for i = 1, #ServerFiles do
    Script.Load(ServerFiles[i])
end