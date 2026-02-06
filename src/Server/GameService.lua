local Players = game:GetService("Players")

local BoxService = require(script.Parent.BoxService)
local CoreService = require(script.Parent.CoreService)
local MapService = require(script.Parent.MapService)
local NpcService = require(script.Parent.NpcService)
local PentagonService = require(script.Parent.PentagonService)
local PlayerBaseService = require(script.Parent.PlayerBaseService)
local RemoteService = require(script.Parent.RemoteService)

local GameService = {}

local function moveCharacterToBase(player, character)
  local spawnPart = MapService:GetPlayerSpawn(player)
  if not spawnPart then
    return
  end

  local root = character:WaitForChild("HumanoidRootPart", 5)
  if not root then
    return
  end

  character:PivotTo(spawnPart.CFrame + Vector3.new(0, 4, 0))
end

function GameService:Init()
  PlayerBaseService:Init()
  PentagonService:Init()
  MapService:Init()
  BoxService:Init()
  NpcService:Init()
  CoreService:Init()
  RemoteService:Init()

  Players.PlayerAdded:Connect(function(player)
    local base = PlayerBaseService:AssignBase(player)
    if base then
      MapService:AssignBaseToPlayer(player, base.id)
    end

    player.CharacterAdded:Connect(function(character)
      moveCharacterToBase(player, character)
    end)
  end)

  Players.PlayerRemoving:Connect(function(player)
    MapService:ReleaseBaseFromPlayer(player)
    PlayerBaseService:ReleaseBase(player)
    NpcService:ClearPlayerNpcs(player)
  end)

  for _, player in ipairs(Players:GetPlayers()) do
    local base = PlayerBaseService:AssignBase(player)
    if base then
      MapService:AssignBaseToPlayer(player, base.id)
    end

    if player.Character then
      moveCharacterToBase(player, player.Character)
    end
  end
end

return GameService
