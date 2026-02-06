local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local NpcService = require(script.Parent.NpcService)

local BoxService = {}

local function getWeightedRandomRarity()
  local totalWeight = 0
  for _, weight in pairs(Constants.RarityWeights) do
    totalWeight += weight
  end

  local roll = math.random(1, totalWeight)
  local current = 0
  for rarity, weight in pairs(Constants.RarityWeights) do
    current += weight
    if roll <= current then
      return rarity
    end
  end

  return "COMMON"
end

local function getNpcByRarity(rarity)
  local options = {}
  for _, npc in ipairs(Constants.NpcCatalog) do
    if npc.rarity == rarity then
      table.insert(options, npc)
    end
  end

  if #options == 0 then
    return nil
  end

  return options[math.random(1, #options)]
end

function BoxService:Init()
  math.randomseed(os.clock() * 100000)
end

function BoxService:OpenBox(player)
  local rarity = getWeightedRandomRarity()
  local npc = getNpcByRarity(rarity)

  if not npc then
    return nil
  end

  return NpcService:AddNpcToPlayer(player, npc)
end

return BoxService
