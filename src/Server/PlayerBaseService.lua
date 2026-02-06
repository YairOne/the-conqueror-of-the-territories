local Players = game:GetService("Players")

local Constants = require(game:GetService("ReplicatedStorage").Shared.Constants)

local PlayerBaseService = {
  bases = {},
  playerBases = {},
}

local function createBase(index)
  local base = {
    id = index,
    owner = nil,
    slots = {},
    protectedPentagons = {},
    core = nil,
  }

  for slotIndex = 1, Constants.SlotsPerBase do
    base.slots[slotIndex] = {
      index = slotIndex,
      unlocked = slotIndex <= Constants.UnlockedSlotsAtStart,
      npcId = nil,
      mode = "GUARD",
    }
  end

  return base
end

function PlayerBaseService:Init()
  self.bases = {}
  self.playerBases = {}

  for index = 1, Constants.MaxBases do
    self.bases[index] = createBase(index)
  end
end

function PlayerBaseService:AssignBase(player)
  for _, base in ipairs(self.bases) do
    if not base.owner then
      base.owner = player
      self.playerBases[player.UserId] = base
      return base
    end
  end

  player:Kick("All bases are occupied.")
  return nil
end

function PlayerBaseService:ReleaseBase(player)
  local base = self.playerBases[player.UserId]
  if base then
    base.owner = nil
    for _, slot in ipairs(base.slots) do
      slot.npcId = nil
      slot.mode = "GUARD"
      slot.unlocked = slot.index <= Constants.UnlockedSlotsAtStart
    end
    self.playerBases[player.UserId] = nil
  end
end

function PlayerBaseService:GetBase(player)
  return self.playerBases[player.UserId]
end

function PlayerBaseService:UnlockSlot(player, slotIndex)
  local base = self:GetBase(player)
  if not base then
    return false
  end

  local slot = base.slots[slotIndex]
  if not slot then
    return false
  end

  slot.unlocked = true
  return true
end

function PlayerBaseService:SetSlotNpc(player, slotIndex, npcId)
  local base = self:GetBase(player)
  if not base then
    return false
  end

  local slot = base.slots[slotIndex]
  if not slot or not slot.unlocked then
    return false
  end

  slot.npcId = npcId
  return true
end

function PlayerBaseService:SetSlotMode(player, slotIndex, mode)
  local base = self:GetBase(player)
  if not base then
    return false
  end

  local slot = base.slots[slotIndex]
  if not slot or not slot.unlocked then
    return false
  end

  slot.mode = mode
  return true
end

function PlayerBaseService:GetActiveSlots(player)
  local base = self:GetBase(player)
  if not base then
    return {}
  end

  local active = {}
  for _, slot in ipairs(base.slots) do
    if slot.unlocked and slot.npcId then
      table.insert(active, slot)
    end
  end

  return active
end

function PlayerBaseService:GetBaseByUserId(userId)
  return self.playerBases[userId]
end

return PlayerBaseService
