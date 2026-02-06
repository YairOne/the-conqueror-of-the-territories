local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

local frame = Instance.new("Frame")
frame.Name = "Panel"
frame.Size = UDim2.new(0, 320, 0, 360)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 30)
title.Position = UDim2.new(0, 10, 0, 10)
title.BackgroundTransparency = 1
title.Text = "Conqueror Base"
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(240, 240, 240)
title.Parent = frame

local baseLabel = Instance.new("TextLabel")
baseLabel.Size = UDim2.new(1, -20, 0, 22)
baseLabel.Position = UDim2.new(0, 10, 0, 44)
baseLabel.BackgroundTransparency = 1
baseLabel.Text = "Base: --"
baseLabel.Font = Enum.Font.Gotham
baseLabel.TextSize = 14
baseLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
baseLabel.TextXAlignment = Enum.TextXAlignment.Left
baseLabel.Parent = frame

local openButton = Instance.new("TextButton")
openButton.Size = UDim2.new(1, -20, 0, 32)
openButton.Position = UDim2.new(0, 10, 0, 74)
openButton.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
openButton.Text = "Open Box"
openButton.TextColor3 = Color3.new(1, 1, 1)
openButton.Font = Enum.Font.GothamBold
openButton.TextSize = 14
openButton.Parent = frame

local resultLabel = Instance.new("TextLabel")
resultLabel.Size = UDim2.new(1, -20, 0, 40)
resultLabel.Position = UDim2.new(0, 10, 0, 112)
resultLabel.BackgroundTransparency = 1
resultLabel.Text = "Last box: --"
resultLabel.TextWrapped = true
resultLabel.Font = Enum.Font.Gotham
resultLabel.TextSize = 14
resultLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
resultLabel.TextXAlignment = Enum.TextXAlignment.Left
resultLabel.Parent = frame

local inventoryLabel = Instance.new("TextLabel")
inventoryLabel.Size = UDim2.new(1, -20, 0, 70)
inventoryLabel.Position = UDim2.new(0, 10, 0, 156)
inventoryLabel.BackgroundTransparency = 1
inventoryLabel.Text = "Inventory: --"
inventoryLabel.TextWrapped = true
inventoryLabel.Font = Enum.Font.Gotham
inventoryLabel.TextSize = 13
inventoryLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
inventoryLabel.TextXAlignment = Enum.TextXAlignment.Left
inventoryLabel.TextYAlignment = Enum.TextYAlignment.Top
inventoryLabel.Parent = frame

local slotsHeader = Instance.new("TextLabel")
slotsHeader.Size = UDim2.new(1, -20, 0, 20)
slotsHeader.Position = UDim2.new(0, 10, 0, 230)
slotsHeader.BackgroundTransparency = 1
slotsHeader.Text = "Slots"
slotsHeader.Font = Enum.Font.GothamBold
slotsHeader.TextSize = 14
slotsHeader.TextColor3 = Color3.fromRGB(240, 240, 240)
slotsHeader.TextXAlignment = Enum.TextXAlignment.Left
slotsHeader.Parent = frame

local slotsFrame = Instance.new("Frame")
slotsFrame.Size = UDim2.new(1, -20, 0, 110)
slotsFrame.Position = UDim2.new(0, 10, 0, 252)
slotsFrame.BackgroundTransparency = 1
slotsFrame.Parent = frame

local slotButtons = {}

for i = 1, 8 do
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 150, 0, 22)
	button.Position = UDim2.new(0, ((i - 1) % 2) * 160, 0, math.floor((i - 1) / 2) * 26)
	button.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	button.TextColor3 = Color3.fromRGB(230, 230, 230)
	button.Font = Enum.Font.Gotham
	button.TextSize = 12
	button.Text = ("Slot %d: --"):format(i)
	button.Parent = slotsFrame
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
	inventoryLabel.Text = "Inventory: " .. (#inventoryNames > 0 and table.concat(inventoryNames, ", ") or "--")

	for _, slot in ipairs(state.slots) do
		local button = slotButtons[slot.index]
		if button then
			local status = slot.unlocked and "Unlocked" or "Locked"
			if slot.npcId then
				status = ("NPC: %s"):format(slot.npcId)
			end
			button.Text = ("Slot %d: %s"):format(slot.index, status)
			button.AutoButtonColor = slot.unlocked
			button.BackgroundColor3 = slot.unlocked and Color3.fromRGB(60, 60, 80) or Color3.fromRGB(35, 35, 35)
		end
	end
end

local function refreshState()
	local state = requestGetState:InvokeServer()
	renderState(state)
end

openButton.Activated:Connect(function()
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
