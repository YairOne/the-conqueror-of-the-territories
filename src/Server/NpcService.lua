local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Constants = require(ReplicatedStorage.Shared.Constants)
local MapService = require(script.Parent.MapService)
local PlayerBaseService = require(script.Parent.PlayerBaseService)

local NpcService = {
  npcInventory = {},
  spawnedNpcs = {},
}

local function getNpcFolder()
  local folder = ReplicatedStorage:FindFirstChild("NpcModels")
  if not folder then
    folder = Instance.new("Folder")
    folder.Name = "NpcModels"
    folder.Parent = ReplicatedStorage
  end
  return folder
end

local function buildNpcModel(npc)
  local model = Instance.new("Model")
  model.Name = npc.id

  local root = Instance.new("Part")
  root.Name = "Root"
  root.Size = Vector3.new(3, 4, 2)
  root.Anchored = true
  root.Material = Enum.Material.SmoothPlastic
  root.Color = Constants.NpcVisuals[npc.id] and Constants.NpcVisuals[npc.id].color or Color3.fromRGB(150, 150, 150)
  root.Parent = model

  local head = Instance.new("Part")
  head.Name = "Head"
  head.Shape = Enum.PartType.Ball
  head.Size = Vector3.new(2, 2, 2)
  head.Anchored = true
  head.Material = Enum.Material.SmoothPlastic
  head.Color = root.Color
  head.CFrame = root.CFrame + Vector3.new(0, 3, 0)
  head.Parent = model

  local nameLabel = Instance.new("BillboardGui")
  nameLabel.Name = "Nameplate"
  nameLabel.Size = UDim2.new(0, 120, 0, 24)
  nameLabel.StudsOffset = Vector3.new(0, 4, 0)
  nameLabel.AlwaysOnTop = true
  nameLabel.Parent = head

  local nameText = Instance.new("TextLabel")
  nameText.BackgroundTransparency = 1
  nameText.Size = UDim2.new(1, 0, 1, 0)
  nameText.Text = npc.name
  nameText.TextColor3 = Color3.fromRGB(255, 255, 255)
  nameText.TextStrokeTransparency = 0.5
  nameText.Font = Enum.Font.GothamBold
  nameText.TextSize = 14
  nameText.Parent = nameLabel

  local animationController = Instance.new("AnimationController")
  animationController.Name = "AnimationController"
  animationController.Parent = model

  local animator = Instance.new("Animator")
  animator.Parent = animationController

  local idleAnimation = Instance.new("Animation")
  idleAnimation.Name = "IdleAnimation"
  idleAnimation.AnimationId = Constants.NpcAnimations.idle
  idleAnimation.Parent = model

  local spawnSound = Instance.new("Sound")
  spawnSound.Name = "SpawnSound"
  spawnSound.SoundId = Constants.NpcSounds.spawn
  spawnSound.Volume = 0.6
  spawnSound.RollOffMaxDistance = 40
  spawnSound.Parent = root

  model.PrimaryPart = root

  return model
end

local function playIdle(model)
  local controller = model:FindFirstChild("AnimationController")
  if not controller then
    return
  end
  local animator = controller:FindFirstChildOfClass("Animator")
  local idle = model:FindFirstChild("IdleAnimation")
  if animator and idle then
    local track = animator:LoadAnimation(idle)
    track.Looped = true
    track:Play()
  end
end

function NpcService:Init()
  self.npcInventory = {}
  self.spawnedNpcs = {}
  self:EnsureNpcModels()
end

function NpcService:EnsureNpcModels()
  local folder = getNpcFolder()
  for _, npc in ipairs(Constants.NpcCatalog) do
    if not folder:FindFirstChild(npc.id) then
      local model = buildNpcModel(npc)
      model.Parent = folder
    end
  end
end

function NpcService:GetNpcTemplate(npcId)
  local folder = getNpcFolder()
  return folder:FindFirstChild(npcId)
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
      local success = PlayerBaseService:SetSlotNpc(player, slotIndex, npcId)
      if success then
        self:SpawnNpcForSlot(player, slotIndex, npcId)
      end
      return success
    end
  end

  return false
end

function NpcService:SpawnNpcForSlot(player, slotIndex, npcId)
  local base = PlayerBaseService:GetBase(player)
  if not base then
    return
  end

  local spawnPart = MapService:GetNpcSpawn(base.id, slotIndex)
  if not spawnPart then
    return
  end

  self:DespawnNpcForSlot(player, slotIndex)

  local template = self:GetNpcTemplate(npcId)
  if not template then
    return
  end

  local clone = template:Clone()
  clone.Name = ("Npc_%s_%02d"):format(npcId, slotIndex)
  clone.Parent = Workspace

  if clone.PrimaryPart then
    clone:PivotTo(spawnPart.CFrame + Vector3.new(0, clone.PrimaryPart.Size.Y * 0.5, 0))
  else
    clone:PivotTo(spawnPart.CFrame)
  end

  playIdle(clone)

  local sound = clone:FindFirstChild("SpawnSound", true)
  if sound then
    sound:Play()
  end

  self.spawnedNpcs[player.UserId] = self.spawnedNpcs[player.UserId] or {}
  self.spawnedNpcs[player.UserId][slotIndex] = clone
end

function NpcService:DespawnNpcForSlot(player, slotIndex)
  local playerNpcs = self.spawnedNpcs[player.UserId]
  if not playerNpcs then
    return
  end

  local existing = playerNpcs[slotIndex]
  if existing then
    existing:Destroy()
    playerNpcs[slotIndex] = nil
  end
end

function NpcService:ClearPlayerNpcs(player)
  local playerNpcs = self.spawnedNpcs[player.UserId]
  if not playerNpcs then
    return
  end

  for _, model in pairs(playerNpcs) do
    if model then
      model:Destroy()
    end
  end

  self.spawnedNpcs[player.UserId] = nil
  self.npcInventory[player.UserId] = nil
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
