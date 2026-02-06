local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local PentagonService = require(script.Parent.PentagonService)
local PlayerBaseService = require(script.Parent.PlayerBaseService)

local CoreService = {
  cores = {},
}

function CoreService:Init()
  self.cores = {}
end

function CoreService:RegisterCore(player, health)
  local base = PlayerBaseService:GetBase(player)
  if not base then
    return nil
  end

  local core = {
    ownerUserId = player.UserId,
    maxHealth = health or 1000,
    health = health or 1000,
  }

  self.cores[player.UserId] = core
  base.core = core
  return core
end

function CoreService:DamageCore(targetUserId, amount, attackerUserId)
  local core = self.cores[targetUserId]
  if not core then
    return false
  end

  core.health -= amount
  if core.health <= 0 then
    self:HandleCoreDestroyed(targetUserId, attackerUserId)
    return true
  end

  return false
end

function CoreService:HandleCoreDestroyed(targetUserId, attackerUserId)
  if attackerUserId then
    PentagonService:TransferOwnership(targetUserId, attackerUserId)
  end

  local core = self.cores[targetUserId]
  if core then
    core.health = core.maxHealth
  end
end

function CoreService:GetCore(userId)
  return self.cores[userId]
end

return CoreService
