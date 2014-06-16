local m = {}

local cache = setmetatable({}, {__metatable = 0, __mode='v'})

-- Try to load an asset, will return a cached version if it's already loaded
-- * name: Name of the asset, in the form: typeName:assetName. e.g: texture:test.png
function m.get(name)
	assert(type(name) == "string", "Asset name must be a string, given "..tostring(name).."("..type(name)..")")
	return cache[name] or m.load(name)
end

-- Force loading of an asset. Use if you want to force an asset to reload
function m.load(name)
	local assetType, assetName = unpack(name:split(":"))
	local loader = require("glider.loaders."..assetType)
	local asset = assert(loader(assetName))
	print("Loaded "..name)
	cache[name] = asset

	return asset
end

return m
