local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
	return
end

local DEFAULT_MAX_DEPTH = 20
local DEFAULT_MAX_NODES = 50000

local function IsUnsupportedType(valueType)
	return valueType == "function" or valueType == "thread" or valueType == "userdata"
end

local function FormatPathSegment(key)
	local keyType = type(key)
	if keyType == "string" then
		return "." .. key
	elseif keyType == "number" then
		return "[" .. tostring(key) .. "]"
	elseif keyType == "boolean" then
		return "[" .. tostring(key) .. "]"
	elseif keyType == "table" then
		return ".[table-key]"
	end
	return ".[key:" .. keyType .. "]"
end

function addon:ValidateImportTree(root, maxDepth, maxNodes)
	if type(root) ~= "table" then
		return false, "Imported data is not a table."
	end

	local depthLimit = tonumber(maxDepth) or DEFAULT_MAX_DEPTH
	local nodeLimit = tonumber(maxNodes) or DEFAULT_MAX_NODES
	if depthLimit < 1 then
		depthLimit = DEFAULT_MAX_DEPTH
	end
	if nodeLimit < 1 then
		nodeLimit = DEFAULT_MAX_NODES
	end

	local seen = {}
	local stack = {
		{ node = root, depth = 1, path = "root" },
	}
	local nodeCount = 0

	while #stack > 0 do
		local current = stack[#stack]
		stack[#stack] = nil
		local node = current.node
		local depth = current.depth
		local path = current.path

		if depth > depthLimit then
			return false, ("Import nesting is too deep near %s (max depth %d)."):
				format(path, depthLimit)
		end

		nodeCount = nodeCount + 1
		if nodeCount > nodeLimit then
			return false, ("Import data is too large (max %d table nodes)."):
				format(nodeLimit)
		end

		if seen[node] then
			return false, "Import contains cyclic or repeated table references and cannot be safely imported."
		end
		seen[node] = true

		for key, value in pairs(node) do
			local keyType = type(key)
			if IsUnsupportedType(keyType) then
				return false, ("Import contains unsupported key type '%s' near %s."):
					format(keyType, path)
			end

			local valueType = type(value)
			if IsUnsupportedType(valueType) then
				return false, ("Import contains unsupported value type '%s' near %s%s."):
					format(valueType, path, FormatPathSegment(key))
			end

			if keyType == "table" then
				stack[#stack + 1] = {
					node = key,
					depth = depth + 1,
					path = path .. ".[table-key]",
				}
			end

			if valueType == "table" then
				stack[#stack + 1] = {
					node = value,
					depth = depth + 1,
					path = path .. FormatPathSegment(key),
				}
			end
		end
	end

	return true
end
