local Players = game:GetService("Players")

local BoxService = require(script.Parent.BoxService)
local CoreService = require(script.Parent.CoreService)
local MapService = require(script.Parent.MapService)
local NpcService = require(script.Parent.NpcService)
local PentagonService = require(script.Parent.PentagonService)
local PlayerBaseService = require(script.Parent.PlayerBaseService)
local RemoteService = require(script.Parent.RemoteService)

local GameService = {}

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
  end)

  Players.PlayerRemoving:Connect(function(player)
    MapService:ReleaseBaseFromPlayer(player)
    PlayerBaseService:ReleaseBase(player)
  end)

  for _, player in ipairs(Players:GetPlayers()) do
    local base = PlayerBaseService:AssignBase(player)
    if base then
      MapService:AssignBaseToPlayer(player, base.id)
    end
  end
end

return GameService
