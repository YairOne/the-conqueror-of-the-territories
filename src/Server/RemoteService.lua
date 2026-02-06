local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BoxService = require(script.Parent.BoxService)
local NpcService = require(script.Parent.NpcService)
local PlayerBaseService = require(script.Parent.PlayerBaseService)

local RemoteService = {}

local function getOrCreateRemotes()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = ReplicatedStorage
	end

	local function ensureRemote(name, className)
		local existing = remotes:FindFirstChild(name)
		if existing and existing.ClassName == className then
			return existing
		end

		local remote = Instance.new(className)
		remote.Name = name
		remote.Parent = remotes
		return remote
	end

	return remotes, ensureRemote
end

local function buildInventoryPayload(inventory)
	local payload = {}
	for _, npc in ipairs(inventory) do
		table.insert(payload, {
			id = npc.id,
			name = npc.name,
			rarity = npc.rarity,
		})
	end
	return payload
end

local function buildSlotPayload(base)
	local slots = {}
	for _, slot in ipairs(base.slots) do
		table.insert(slots, {
			index = slot.index,
			unlocked = slot.unlocked,
			npcId = slot.npcId,
			mode = slot.mode,
		})
	end
	return slots
end

function RemoteService:Init()
	local _, ensureRemote = getOrCreateRemotes()

	local requestOpenBox = ensureRemote("RequestOpenBox", "RemoteFunction")
	local requestAssignNpc = ensureRemote("RequestAssignNpc", "RemoteFunction")
	local requestGetState = ensureRemote("RequestGetState", "RemoteFunction")
	local requestSetMode = ensureRemote("RequestSetSlotMode", "RemoteFunction")

	requestOpenBox.OnServerInvoke = function(player)
		local npc = BoxService:OpenBox(player)
		if not npc then
			return nil
		end

		return {
			id = npc.id,
			name = npc.name,
			rarity = npc.rarity,
		}
	end

	requestAssignNpc.OnServerInvoke = function(player, slotIndex, npcId)
		if typeof(slotIndex) ~= "number" or typeof(npcId) ~= "string" then
			return false
		end
		return NpcService:AssignNpcToSlot(player, slotIndex, npcId)
	end

	requestSetMode.OnServerInvoke = function(player, slotIndex, mode)
		if typeof(slotIndex) ~= "number" or typeof(mode) ~= "string" then
			return false
		end
		return NpcService:SetNpcMode(player, slotIndex, mode)
	end

	requestGetState.OnServerInvoke = function(player)
		local base = PlayerBaseService:GetBase(player)
		if not base then
			return nil
		end

		local inventory = NpcService:GetInventory(player)

		return {
			baseId = base.id,
			slots = buildSlotPayload(base),
			inventory = buildInventoryPayload(inventory),
		}
	end
end

return RemoteService
