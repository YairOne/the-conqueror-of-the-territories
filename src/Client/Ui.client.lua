local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)

local player = Players.LocalPlayer

local function waitForRemote(name)
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	return remotes:WaitForChild(name)
end

local requestOpenBox = waitForRemote("RequestOpenBox")
local requestAssignNpc = waitForRemote("RequestAssignNpc")
local requestGetState = waitForRemote("RequestGetState")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ConquerorUi"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local uiSound = Instance.new("Sound")
uiSound.Name = "UiClick"
uiSound.SoundId = Constants.UiSounds.click
uiSound.Volume = 0.4
uiSound.Parent = screenGui

local mainPanel = Instance.new("Frame")
mainPanel.Name = "Panel"
mainPanel.Size = UDim2.new(0, 360, 0, 470)
mainPanel.Position = UDim2.new(0, 24, 0, 24)
mainPanel.BackgroundColor3 = Color3.fromRGB(35, 45, 80)
mainPanel.BorderSizePixel = 0
mainPanel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 16)
panelCorner.Parent = mainPanel

local panelStroke = Instance.new("UIStroke")
panelStroke.Thickness = 2
panelStroke.Color = Color3.fromRGB(125, 180, 255)
panelStroke.Parent = mainPanel

local panelPadding = Instance.new("UIPadding")
panelPadding.PaddingTop = UDim.new(0, 12)
panelPadding.PaddingBottom = UDim.new(0, 12)
panelPadding.PaddingLeft = UDim.new(0, 12)
panelPadding.PaddingRight = UDim.new(0, 12)
panelPadding.Parent = mainPanel

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 70)
header.BackgroundColor3 = Color3.fromRGB(70, 130, 220)
header.BorderSizePixel = 0
header.Parent = mainPanel

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 14)
headerCorner.Parent = header

local headerGradient = Instance.new("UIGradient")
headerGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 170, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 110, 210)),
})
headerGradient.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 28)
title.Position = UDim2.new(0, 10, 0, 8)
title.BackgroundTransparency = 1
title.Text = "Conqueror Command"
title.Font = Enum.Font.FredokaOne
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -20, 0, 18)
subtitle.Position = UDim2.new(0, 10, 0, 40)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Manage your base and NPC squads"
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 12
subtitle.TextColor3 = Color3.fromRGB(220, 235, 255)
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = header

local baseLabel = Instance.new("TextLabel")
baseLabel.Size = UDim2.new(0, 120, 0, 24)
baseLabel.Position = UDim2.new(1, -130, 0, 8)
baseLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
baseLabel.Text = "Base: --"
baseLabel.Font = Enum.Font.GothamBold
baseLabel.TextSize = 14
baseLabel.TextColor3 = Color3.fromRGB(40, 70, 140)
baseLabel.Parent = header

local baseCorner = Instance.new("UICorner")
baseCorner.CornerRadius = UDim.new(0, 8)
baseCorner.Parent = baseLabel

local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, 0, 1, -80)
content.Position = UDim2.new(0, 0, 0, 80)
content.BackgroundTransparency = 1
content.Parent = mainPanel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 10)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = content

local function createCard(name, height)
	local card = Instance.new("Frame")
	card.Name = name
	card.Size = UDim2.new(1, 0, 0, height)
	card.BackgroundColor3 = Color3.fromRGB(45, 60, 110)
	card.BorderSizePixel = 0
	card.Parent = content

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 12)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Thickness = 1
	cardStroke.Color = Color3.fromRGB(90, 140, 230)
	cardStroke.Parent = card

	local cardPadding = Instance.new("UIPadding")
	cardPadding.PaddingTop = UDim.new(0, 10)
	cardPadding.PaddingBottom = UDim.new(0, 10)
	cardPadding.PaddingLeft = UDim.new(0, 10)
	cardPadding.PaddingRight = UDim.new(0, 10)
	cardPadding.Parent = card

	return card
end

local actionCard = createCard("ActionCard", 110)
actionCard.LayoutOrder = 1

local openButton = Instance.new("TextButton")
openButton.Size = UDim2.new(0, 150, 0, 36)
openButton.Position = UDim2.new(0, 0, 0, 0)
openButton.BackgroundColor3 = Color3.fromRGB(255, 200, 80)
openButton.Text = "Open Box"
openButton.TextColor3 = Color3.fromRGB(65, 45, 10)
openButton.Font = Enum.Font.FredokaOne
openButton.TextSize = 16
openButton.Parent = actionCard

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(0, 10)
openCorner.Parent = openButton

local resultLabel = Instance.new("TextLabel")
resultLabel.Size = UDim2.new(1, -170, 0, 36)
resultLabel.Position = UDim2.new(0, 170, 0, 0)
resultLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
resultLabel.Text = "Last box: --"
resultLabel.Font = Enum.Font.GothamBold
resultLabel.TextSize = 13
resultLabel.TextColor3 = Color3.fromRGB(60, 60, 80)
resultLabel.TextWrapped = true
resultLabel.Parent = actionCard

local resultCorner = Instance.new("UICorner")
resultCorner.CornerRadius = UDim.new(0, 10)
resultCorner.Parent = resultLabel

local helperText = Instance.new("TextLabel")
helperText.Size = UDim2.new(1, 0, 0, 26)
helperText.Position = UDim2.new(0, 0, 0, 48)
helperText.BackgroundTransparency = 1
helperText.Text = "Tap a slot to deploy your last NPC."
helperText.Font = Enum.Font.Gotham
helperText.TextSize = 12
helperText.TextColor3 = Color3.fromRGB(210, 230, 255)
helperText.TextXAlignment = Enum.TextXAlignment.Left
helperText.Parent = actionCard

local inventoryCard = createCard("InventoryCard", 120)
inventoryCard.LayoutOrder = 2

local inventoryTitle = Instance.new("TextLabel")
inventoryTitle.Size = UDim2.new(1, 0, 0, 18)
inventoryTitle.BackgroundTransparency = 1
inventoryTitle.Text = "Inventory"
inventoryTitle.Font = Enum.Font.FredokaOne
inventoryTitle.TextSize = 16
inventoryTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
inventoryTitle.TextXAlignment = Enum.TextXAlignment.Left
inventoryTitle.Parent = inventoryCard

local inventoryFrame = Instance.new("ScrollingFrame")
inventoryFrame.Size = UDim2.new(1, 0, 0, 80)
inventoryFrame.Position = UDim2.new(0, 0, 0, 28)
inventoryFrame.BackgroundTransparency = 1
inventoryFrame.BorderSizePixel = 0
inventoryFrame.ScrollBarThickness = 6
inventoryFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
inventoryFrame.Parent = inventoryCard

local inventoryLabel = Instance.new("TextLabel")
inventoryLabel.Size = UDim2.new(1, -8, 0, 20)
inventoryLabel.Position = UDim2.new(0, 0, 0, 0)
inventoryLabel.BackgroundTransparency = 1
inventoryLabel.Text = "Inventory: --"
inventoryLabel.Font = Enum.Font.Gotham
inventoryLabel.TextSize = 12
inventoryLabel.TextColor3 = Color3.fromRGB(220, 235, 255)
inventoryLabel.TextWrapped = true
inventoryLabel.TextXAlignment = Enum.TextXAlignment.Left
inventoryLabel.TextYAlignment = Enum.TextYAlignment.Top
inventoryLabel.Parent = inventoryFrame

local slotsCard = createCard("SlotsCard", 150)
slotsCard.LayoutOrder = 3

local slotsHeader = Instance.new("TextLabel")
slotsHeader.Size = UDim2.new(1, 0, 0, 18)
slotsHeader.BackgroundTransparency = 1
slotsHeader.Text = "Deployment Slots"
slotsHeader.Font = Enum.Font.FredokaOne
slotsHeader.TextSize = 16
slotsHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
slotsHeader.TextXAlignment = Enum.TextXAlignment.Left
slotsHeader.Parent = slotsCard

local slotsFrame = Instance.new("Frame")
slotsFrame.Size = UDim2.new(1, 0, 0, 110)
slotsFrame.Position = UDim2.new(0, 0, 0, 28)
slotsFrame.BackgroundTransparency = 1
slotsFrame.Parent = slotsCard

local slotsLayout = Instance.new("UIGridLayout")
slotsLayout.CellSize = UDim2.new(0, 150, 0, 28)
slotsLayout.CellPadding = UDim2.new(0, 8, 0, 8)
slotsLayout.SortOrder = Enum.SortOrder.LayoutOrder
slotsLayout.Parent = slotsFrame

local slotButtons = {}

for i = 1, 8 do
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 150, 0, 28)
	button.BackgroundColor3 = Color3.fromRGB(60, 75, 130)
	button.TextColor3 = Color3.fromRGB(230, 240, 255)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 12
	button.Text = ("Slot %d: --"):format(i)
	button.Parent = slotsFrame

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = button

	slotButtons[i] = button
end

local lastNpc = nil

local function renderState(state)
	if not state then
		return
	end

	baseLabel.Text = ("Base: %02d"):format(state.baseId)

	local inventoryNames = {}
	for _, npc in ipairs(state.inventory) do
		table.insert(inventoryNames, npc.name)
	end

	local inventoryText = #inventoryNames > 0 and table.concat(inventoryNames, ", ") or "--"
	inventoryLabel.Text = "Inventory: " .. inventoryText

	local textBounds = inventoryLabel.TextBounds
	inventoryFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(20, textBounds.Y + 6))

	for _, slot in ipairs(state.slots) do
		local button = slotButtons[slot.index]
		if button then
			local status = slot.unlocked and "Unlocked" or "Locked"
			if slot.npcId then
				status = ("NPC: %s"):format(slot.npcId)
			end
			button.Text = ("Slot %d: %s"):format(slot.index, status)
			button.AutoButtonColor = slot.unlocked
			button.BackgroundColor3 = slot.unlocked and Color3.fromRGB(70, 95, 160) or Color3.fromRGB(45, 55, 85)
		end
	end
end

local function refreshState()
	local state = requestGetState:InvokeServer()
	renderState(state)
end

openButton.Activated:Connect(function()
	uiSound:Play()
	local npc = requestOpenBox:InvokeServer()
	if npc then
		lastNpc = npc
		resultLabel.Text = ("Last box: %s (%s)"):format(npc.name, npc.rarity)
	else
		resultLabel.Text = "Last box: none"
	end
	refreshState()
end)

for index, button in ipairs(slotButtons) do
	button.Activated:Connect(function()
		uiSound:Play()
		if not lastNpc then
			resultLabel.Text = "Open a box first to assign."
			return
		end

		local success = requestAssignNpc:InvokeServer(index, lastNpc.id)
		if success then
			resultLabel.Text = ("Assigned %s to slot %d."):format(lastNpc.name, index)
			refreshState()
		else
			resultLabel.Text = ("Failed to assign to slot %d."):format(index)
		end
	end)
end

refreshState()
