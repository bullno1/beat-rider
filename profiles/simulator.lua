package.path="./src/?.lua;./src/?/init.lua"

MOAIFileSystem.affirmPath(".sandbox/document")
MOAIFileSystem.affirmPath(".sandbox/cache")
MOAIEnvironment.setValue("documentDirectory", ".sandbox/document")
MOAIEnvironment.setValue("cacheDirectory", ".sandbox/cache")
