local CollectionService = game:GetService("CollectionService")

local CoreService = require(script.Parent.CoreService)
local MapBuilder = require(script.Parent.MapBuilder)
local PentagonService = require(script.Parent.PentagonService)
local PlayerBaseService = require(script.Parent.PlayerBaseService)

local MapService = {
	baseProtectedTiles = {},
	baseCoreParts = {},
	baseSpawnParts = {},
	npcSpawnParts = {},
	userBaseIds = {},
}

local function readBool(instance: Instance, attribute: string)
	local value = instance:GetAttribute(attribute)
	if value == nil then
		return false
	end
	return value == true
end

function MapService:Init()
	self.baseProtectedTiles = {}
	self.baseCoreParts = {}
	self.baseSpawnParts = {}
	self.npcSpawnParts = {}
	self.userBaseIds = {}

	MapBuilder:Build()
	self:RegisterWorld()
end

function MapService:RegisterWorld()
	self.baseProtectedTiles = {}
	self.baseCoreParts = {}
	self.baseSpawnParts = {}
	self.npcSpawnParts = {}

	for _, core in ipairs(CollectionService:GetTagged("BaseCore")) do
		if core:IsA("BasePart") then
			local baseId = core:GetAttribute("BaseId")
			if typeof(baseId) == "number" then
				self.baseCoreParts[baseId] = core
			end
		end
	end

	for _, spawn in ipairs(CollectionService:GetTagged("PlayerSpawn")) do
		if spawn:IsA("SpawnLocation") then
			local baseId = spawn:GetAttribute("BaseId")
			if typeof(baseId) == "number" then
				self.baseSpawnParts[baseId] = spawn
			end
		end
	end

	for _, spawn in ipairs(CollectionService:GetTagged("NpcSpawn")) do
		if spawn:IsA("BasePart") then
			local baseId = spawn:GetAttribute("BaseId")
			local padIndex = spawn:GetAttribute("PadIndex")
			if typeof(baseId) == "number" and typeof(padIndex) == "number" then
				self.npcSpawnParts[baseId] = self.npcSpawnParts[baseId] or {}
				self.npcSpawnParts[baseId][padIndex] = spawn
			end
		end
	end

	for _, tile in ipairs(CollectionService:GetTagged("TerritoryTile")) do
		local tileId = tile:GetAttribute("TileId")
		if typeof(tileId) ~= "number" then
			continue
		end

		local isProtected = readBool(tile, "IsProtected")
		local protectedBaseId = tile:GetAttribute("ProtectedBaseId")
		local pivot = tile:GetPivot()

		PentagonService:RegisterPentagon(tileId, pivot.Position, isProtected)

		if isProtected and typeof(protectedBaseId) == "number" then
			self.baseProtectedTiles[protectedBaseId] = self.baseProtectedTiles[protectedBaseId] or {}
			table.insert(self.baseProtectedTiles[protectedBaseId], tileId)
		end
	end
end

function MapService:AssignBaseToPlayer(player, baseId)
	self.userBaseIds[player.UserId] = baseId

	local protectedTiles = self.baseProtectedTiles[baseId]
	if protectedTiles then
		PentagonService:AssignProtectedPentagons(player, protectedTiles)
	end

	local corePart = self.baseCoreParts[baseId]
	if corePart then
		local maxHealth = corePart:GetAttribute("MaxHealth") or 1000
		CoreService:RegisterCore(player, maxHealth)
	end

	local spawnPart = self.baseSpawnParts[baseId]
	if spawnPart then
		player.RespawnLocation = spawnPart
	end
end

function MapService:ReleaseBaseFromPlayer(player)
	local baseId = self.userBaseIds[player.UserId]
	if not baseId then
		return
	end

	local base = PlayerBaseService:GetBaseByUserId(player.UserId)
	if base then
		for _, tileId in ipairs(base.protectedPentagons) do
			local pentagon = PentagonService.pentagons[tileId]
			if pentagon then
				pentagon.isProtected = false
				pentagon.ownerUserId = nil
			end
		end
		base.protectedPentagons = {}
	end

	CoreService:RemoveCore(player.UserId)
	self.userBaseIds[player.UserId] = nil
end

function MapService:GetPlayerSpawn(player)
	local baseId = self.userBaseIds[player.UserId]
	if not baseId then
		return nil
	end
	return self.baseSpawnParts[baseId]
end

function MapService:GetNpcSpawn(baseId, padIndex)
	if not baseId or not padIndex then
		return nil
	end
	local baseSpawns = self.npcSpawnParts[baseId]
	if not baseSpawns then
		return nil
	end
	return baseSpawns[padIndex]
end

return MapService
