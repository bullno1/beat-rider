local m = {}

local cache = setmetatable({}, {__metatable = 0, __mode='v'})

-- Try to load an asset, will return a cached version if it's already loaded
-- * name: Name of the asset, in the form: typeName:assetName. e.g: texture:test.png
function m.get(assetType, assetName)
	assert(type(assetType) == "string", "Asset type must be a string, given '"..tostring(assetType).."'")
	assert(type(assetName) == "string", "Asset name must be a string, given '"..tostring(assetName).."'")
	return cache[assetType..":"..assetName] or m.load(assetType, assetName)
end

-- Force loading of an asset. Use if you want to force an asset to reload
function m.load(assetType, assetName)
	print("Trying to load "..tostring(assetType)..":"..tostring(assetName))
	local fqn = assetType..":"..assetName
	local loader = require("glider.loaders."..assetType)
	local asset = assert(loader(assetName))
	print("Loaded "..fqn)
	cache[fqn] = asset

	return asset
end

return m
