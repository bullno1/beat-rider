package.path="./src/?.lua;./src/?/init.lua"

MOAIFileSystem.affirmPath(".sandbox/document")
MOAIFileSystem.affirmPath(".sandbox/cache")
MOAIEnvironment.setValue("documentDirectory", ".sandbox/document")
MOAIEnvironment.setValue("cacheDirectory", ".sandbox/cache")
MOAIEnvironment.setValue("appID", os.getenv("APP_ID"))
MOAIEnvironment.setValue("devName", "simulator")

local function restartOnModification(action, file)
	print(action, file)
	if action == "modified" then
		Titan.restart()
	end
end

local function watchRecursively(folder, action)
	Titan.addWatch(folder, action)

	local subDirs = MOAIFileSystem.listDirectories(folder)
	for i, subDir in ipairs(subDirs) do
		watchRecursively(folder.."/"..subDir, action)
	end
end

watchRecursively("src", restartOnModification)
watchRecursively("assets", restartOnModification)
