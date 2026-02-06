local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local PlayerBaseService = require(script.Parent.PlayerBaseService)

local PentagonService = {
  pentagons = {},
}

function PentagonService:Init()
  self.pentagons = {}
end

function PentagonService:RegisterPentagon(pentagonId, position, isProtected)
  self.pentagons[pentagonId] = {
    id = pentagonId,
    ownerUserId = nil,
    captureProgress = 0,
    position = position,
    isProtected = isProtected or false,
  }
end

function PentagonService:GetOwner(pentagonId)
  local pentagon = self.pentagons[pentagonId]
  return pentagon and pentagon.ownerUserId or nil
end

function PentagonService:CanCapture(player, pentagonId)
  local pentagon = self.pentagons[pentagonId]
  if not pentagon then
    return false
  end

  if pentagon.isProtected then
    return false
  end

  return true
end

function PentagonService:CaptureTick(player, pentagonId, capturePower)
  local pentagon = self.pentagons[pentagonId]
  if not pentagon then
    return false
  end

  if not self:CanCapture(player, pentagonId) then
    return false
  end

  local owned = pentagon.ownerUserId ~= nil
  local difficultyMultiplier = owned and 1.5 or 1
  pentagon.captureProgress += capturePower / difficultyMultiplier

  if pentagon.captureProgress >= 100 then
    pentagon.ownerUserId = player.UserId
    pentagon.captureProgress = 0
    return true
  end

  return false
end

function PentagonService:TransferOwnership(fromUserId, toUserId)
  for _, pentagon in pairs(self.pentagons) do
    if pentagon.ownerUserId == fromUserId then
      pentagon.ownerUserId = toUserId
    end
  end
end

function PentagonService:GetPentagonsByOwner(userId)
  local owned = {}
  for _, pentagon in pairs(self.pentagons) do
    if pentagon.ownerUserId == userId then
      table.insert(owned, pentagon)
    end
  end
  return owned
end

function PentagonService:AssignProtectedPentagons(player, pentagonIds)
  local base = PlayerBaseService:GetBase(player)
  if not base then
    return false
  end

  base.protectedPentagons = {}
  for _, pentagonId in ipairs(pentagonIds) do
    local pentagon = self.pentagons[pentagonId]
    if pentagon then
      pentagon.isProtected = true
      pentagon.ownerUserId = player.UserId
      table.insert(base.protectedPentagons, pentagonId)
    end
  end

  return true
end

return PentagonService
