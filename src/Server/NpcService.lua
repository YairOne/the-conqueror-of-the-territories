local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local PlayerBaseService = require(script.Parent.PlayerBaseService)

local NpcService = {
  npcInventory = {},
}

function NpcService:Init()
  self.npcInventory = {}
end

function NpcService:AddNpcToPlayer(player, npc)
  local inventory = self.npcInventory[player.UserId]
  if not inventory then
    inventory = {}
    self.npcInventory[player.UserId] = inventory
  end

  table.insert(inventory, npc)
  return npc
end

function NpcService:GetInventory(player)
  return self.npcInventory[player.UserId] or {}
end

function NpcService:AssignNpcToSlot(player, slotIndex, npcId)
  local inventory = self:GetInventory(player)
  for _, npc in ipairs(inventory) do
    if npc.id == npcId then
      return PlayerBaseService:SetSlotNpc(player, slotIndex, npcId)
    end
  end

  return false
end

function NpcService:SetNpcMode(player, slotIndex, mode)
  return PlayerBaseService:SetSlotMode(player, slotIndex, mode)
end

function NpcService:GetNpcStats(npcId)
  for _, npc in ipairs(Constants.NpcCatalog) do
    if npc.id == npcId then
      local rarity = npc.rarity
      local stats = Constants.RarityStats[rarity]
      return {
        id = npcId,
        name = npc.name,
        rarity = rarity,
        power = stats.power,
        maxHealth = stats.maxHealth,
        captureSpeed = stats.captureSpeed,
      }
    end
  end

  return nil
end

return NpcService
