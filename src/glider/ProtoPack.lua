local MessagePack = require "glider.MessagePack"

local m = {}

function m.encode(data, schema)
	return MessagePack.pack(schema.encode(data, schema))
end

function m.decode(data, schema)
	return schema.decode(MessagePack.unpack(data), schema)
end

local dsl = {}
function m.desc(descriptor)
	setfenv(descriptor, setmetatable({}, {__index = dsl}))
	return descriptor()
end

local assertType

local encodeStruct, decodeStruct
function dsl.struct(...)
	return {
		fields = {...},
		encode = encodeStruct,
		decode = decodeStruct
	}
end

function dsl.required(schema, name)
	return {
		name = name,
		schema = schema,
		required = true
	}
end

function dsl.optional(schema, name, default)
	return {
		name = name,
		schema = schema,
		required = false,
		default = default
	}
end

encodeStruct = function(data, schema)
	assertType(data, "table")
	local output = {}

	for index, field in ipairs(schema.fields) do
		local value = data[field.name]
		assert(value ~= nil or field.required == false, "Missing required field '"..field.name.."'")
		if value == nil then
			assert(not field.required, "Missing required field '"..field.name.."'")
		else
			local fieldSchema = field.schema
			output[index] = fieldSchema.encode(value, fieldSchema)
		end
	end

	return output
end

decodeStruct = function(data, schema)
	assertType(data, "table")
	local output = {}

	for index, field in ipairs(schema.fields) do
		local value = data[index]
		if value == nil then
			assert(not field.required, "Missing required field '"..field.name.."'")
			output[field.name] = field.default
		else
			local fieldSchema = field.schema
			output[field.name] = fieldSchema.decode(value, fieldSchema)
		end
	end

	return output
end

local encodeArray, decodeArray
function dsl.array(elementSchema)
	return {
		elementSchema = elementSchema,
		encode = encodeArray,
		decode = decodeArray
	}
end

encodeArray = function(data, schema)
	assertType(data, "table")
	local output = {}

	local elementSchema = schema.elementSchema
	for index, item in ipairs(data) do
		output[index] = elementSchema.encode(item, elementSchema)
	end

	return output
end

decodeArray = function(data, schema)
	assertType(data, "table")
	local output = {}

	local elementSchema = schema.elementSchema
	for index, item in ipairs(data) do
		output[index] = elementSchema.decode(item, elementSchema)
	end

	return output
end

local function declarePrimType(protoName, nativeName)
	local function serialize(val)
		assertType(val, nativeName)
		return val
	end
	dsl[protoName] = {
		encode = serialize,
		decode = serialize
	}
end

declarePrimType("Boolean", "boolean")
declarePrimType("Number", "number")
declarePrimType("String", "string")

local function identity(val) return val end
dsl.Any = {
	encode = identity,
	decode = identity
}

assertType = function(val, expectedType)
	return assert(type(val) == expectedType, "Expecting '"..expectedType.."' got '"..type(val).."' instead")
end

return m
