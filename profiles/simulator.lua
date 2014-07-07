package.path="./src/?.lua;./src/?/init.lua"

MOAIFileSystem.affirmPath(".sandbox/document")
MOAIFileSystem.affirmPath(".sandbox/cache")
MOAIEnvironment.setValue("documentDirectory", ".sandbox/document")
MOAIEnvironment.setValue("cacheDirectory", ".sandbox/cache")
MOAIEnvironment.setValue("appID", os.getenv("APP_ID"))
MOAIEnvironment.setValue("devName", "simulator")

local function restartOnModification(action, file)
	if action == "modified" then
		Titan.restart()
	end
end

Titan.addWatch("src", restartOnModification)
Titan.addWatch("assets", restartOnModification)
