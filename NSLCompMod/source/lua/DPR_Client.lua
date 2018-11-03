local ClientFiles = {}
Shared.GetMatchingFileNames("lua/DPR/Client/*.lua", true, ClientFiles) --what does the bool do? recurse?

for i = 1, #ClientFiles do
    Script.Load(ClientFiles[i])
end