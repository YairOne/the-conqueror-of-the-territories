local Players = game:GetService("Players")

local BoxService = require(script.Parent.BoxService)
local CoreService = require(script.Parent.CoreService)
local NpcService = require(script.Parent.NpcService)
local PentagonService = require(script.Parent.PentagonService)
local PlayerBaseService = require(script.Parent.PlayerBaseService)

local GameService = {}

function GameService:Init()
  PlayerBaseService:Init()
  PentagonService:Init()
  BoxService:Init()
  NpcService:Init()
  CoreService:Init()

  Players.PlayerAdded:Connect(function(player)
    PlayerBaseService:AssignBase(player)
  end)

  Players.PlayerRemoving:Connect(function(player)
    PlayerBaseService:ReleaseBase(player)
  end)
end

return GameService
