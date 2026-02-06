local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local MapBuilder = {}

-- =========================================================
-- CONFIG
-- =========================================================
local CONFIG = {
	MapFolderName = "Map",

	BaseCount = 8,

	-- Base layout
	BaseRingRadius = 420, -- distance from center to each base
	BasePlatformSize = Vector3.new(90, 6, 90),
	BaseWallHeight = 18,
	BaseWallThickness = 3,

	CoreSize = Vector3.new(10, 14, 10),

	-- NPC pads & spawns
	NpcPadCount = 8,
	NpcPadsFreeAtStart = 4,
	NpcPadSize = Vector3.new(10, 1.2, 10),
	NpcSpawnMarkerSize = Vector3.new(2.5, 2.5, 2.5),

	NpcPadRingRadius = 30, -- pads around the base center
	NpcSpawnOffsetY = 4, -- spawn marker above pad

	-- Territory field
	TileRadius = 18, -- “radius” of pentagon footprint
	TileThickness = 1.2,
	TileSpacing = 44, -- spacing between tile centers (grid)
	FieldHalfSize = 10, -- grid extends from -FieldHalfSize..+FieldHalfSize in both x and z
	FieldCenter = Vector3.new(0, 0, 0),

	-- Protected tiles near each base
	ProtectedRingCount = 9, -- how many protected pentagon tiles near each base
	ProtectedRingRadius = 85, -- distance from base center for protected tiles ring

	-- Heights
	GroundY = 0, -- base ground level
}

-- =========================================================
-- UTILS
-- =========================================================
local function wipeOldMap()
	local old = Workspace:FindFirstChild(CONFIG.MapFolderName)
	if old then
		old:Destroy()
	end
end

local function ensureFolder(parent: Instance, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function setCommonPartProps(p: BasePart)
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = true
end

local function tag(instance: Instance, tagName: string)
	if not CollectionService:HasTag(instance, tagName) then
		CollectionService:AddTag(instance, tagName)
	end
end

-- =========================================================
-- TRIANGLE BUILDING (two-wedge technique)
-- This lets us construct a flat pentagon floor out of triangles.
-- =========================================================
local function makeWedge(parent: Instance, cf: CFrame, size: Vector3, color: Color3): WedgePart
	local w = Instance.new("WedgePart")
	w.Size = size
	w.CFrame = cf
	w.Color = color
	setCommonPartProps(w)
	w.Parent = parent
	return w
end

-- Creates a single triangle on a plane by using 2 wedgeparts.
-- a, b, c are Vector3 vertices (should be roughly coplanar).
local function drawTriangle(parent: Instance, a: Vector3, b: Vector3, c: Vector3, thickness: number, color: Color3)
	-- Ensure we have a consistent winding: we’ll just work with vectors.
	local ab = b - a
	local ac = c - a

	-- Normal for the triangle plane
	local n = ab:Cross(ac)
	if n.Magnitude < 1e-6 then
		return
	end
	n = n.Unit

	-- Build an orthonormal basis on the triangle plane
	local xAxis = ab.Unit
	local zAxis = n
	local yAxis = zAxis:Cross(xAxis).Unit

	-- Transform vertices into local 2D (x,y) in that basis
	local function toLocal(v: Vector3): Vector3
		local p = v - a
		return Vector3.new(p:Dot(xAxis), p:Dot(yAxis), p:Dot(zAxis))
	end

	local bl = toLocal(b)
	local cl = toLocal(c)

	-- Triangle in 2D: (0,0), (bx,by), (cx,cy)
	-- We split it into 2 wedges along the altitude.
	-- We’ll use the “largest side” trick for stable wedges.
	local p0 = Vector2.new(0, 0)
	local p1 = Vector2.new(bl.X, bl.Y)
	local p2 = Vector2.new(cl.X, cl.Y)

	-- Helper: distance squared
	local function d2(u: Vector2, v: Vector2): number
		local dx = u.X - v.X
		local dy = u.Y - v.Y
		return dx * dx + dy * dy
	end

	-- Pick the longest edge as base
	local d01 = d2(p0, p1)
	local d02 = d2(p0, p2)
	local d12 = d2(p1, p2)

	local A2D, B2D, C2D = p0, p1, p2
	local A3D, B3D, C3D = a, b, c

	if d02 >= d01 and d02 >= d12 then
		-- base is 0-2
		A2D, B2D, C2D = p0, p2, p1
		A3D, B3D, C3D = a, c, b
	elseif d12 >= d01 and d12 >= d02 then
		-- base is 1-2
		A2D, B2D, C2D = p1, p2, p0
		A3D, B3D, C3D = b, c, a
	end

	-- Now base is A-B, with C as apex
	local AB = B2D - A2D
	local AB_len = AB.Magnitude
	if AB_len < 1e-6 then
		return
	end

	local AB_dir = AB / AB_len
	-- Project C onto AB to find foot of altitude
	local AC = C2D - A2D
	local proj = AC:Dot(AB_dir)
	local foot = A2D + AB_dir * proj

	-- Heights
	local h = (C2D - foot).Magnitude
	local base1 = (foot - A2D).Magnitude
	local base2 = (B2D - foot).Magnitude

	-- Build two wedges in 2D space then lift to 3D using the basis
	-- Wedge geometry in Roblox:
	-- A wedge is basically a right triangular prism. We’ll place it so its slanted face matches the triangle.
	-- We create each wedge centered in its rectangular bounding box and orient it.

	local function localToWorld(px: number, py: number, pz: number): Vector3
		-- a is local origin in world; xAxis,yAxis,zAxis are world vectors
		return a + xAxis * px + yAxis * py + zAxis * pz
	end

	-- Triangle lies on plane pz=0, we give it thickness along zAxis.

	-- Wedge 1 covers A -> foot -> C
	if base1 > 1e-4 and h > 1e-4 then
		local size = Vector3.new(base1, thickness, h)
		-- Place wedge so:
		-- X along base segment, Z along height direction (in plane), Y is thickness (we'll map to Roblox Y)
		-- We’ll use a CFrame with:
		-- RightVector = xAxis (base direction)
		-- UpVector = zAxis (thickness direction)
		-- LookVector = yAxis (in-plane "up")
		-- Then map size axes: X=base, Y=thickness, Z=height

		local baseMid = (A2D + foot) * 0.5
		local centerLocal = Vector3.new(baseMid.X, baseMid.Y, 0) + Vector3.new(0, 0, 0)
		local centerWorld = localToWorld(centerLocal.X, centerLocal.Y, 0)

		local cf = CFrame.fromMatrix(
			centerWorld,
			xAxis, -- Right
			zAxis, -- Up (thickness)
			yAxis -- Back (so Look aligns with -yAxis; that's ok for wedge)
		)

		makeWedge(parent, cf, size, color)
	end

	-- Wedge 2 covers foot -> B -> C
	if base2 > 1e-4 and h > 1e-4 then
		local size = Vector3.new(base2, thickness, h)

		local baseMid = (foot + B2D) * 0.5
		local centerLocal = Vector3.new(baseMid.X, baseMid.Y, 0)
		local centerWorld = localToWorld(centerLocal.X, centerLocal.Y, 0)

		-- Base direction from foot to B in world:
		local baseDir2D = (B2D - foot)
		local baseDirLen = baseDir2D.Magnitude
		if baseDirLen > 1e-6 then
			local baseDirUnit2D = baseDir2D / baseDirLen
			local baseDirWorld = (xAxis * baseDirUnit2D.X + yAxis * baseDirUnit2D.Y).Unit

			local cf = CFrame.fromMatrix(
				centerWorld,
				baseDirWorld, -- Right
				zAxis, -- Up (thickness)
				yAxis -- Back (not perfect but stable visually)
			)

			makeWedge(parent, cf, size, color)
		end
	end
end

-- =========================================================
-- PENTAGON TILE BUILDER
-- Returns a Model containing a pentagon floor.
-- =========================================================
local function createPentagonTile(parent: Instance, center: Vector3, radius: number, thickness: number, color: Color3): Model
	local m = Instance.new("Model")
	m.Name = "PentagonTile"
	m.Parent = parent

	-- Create 5 vertices around center on XZ plane
	local verts: { Vector3 } = {}
	for i = 0, 4 do
		local angle = math.rad((i * 72) - 90) -- rotate so one point faces "up"
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		table.insert(verts, Vector3.new(center.X + x, center.Y, center.Z + z))
	end

	-- Triangulate as fan from center: (center, v[i], v[i+1])
	for i = 1, 5 do
		local v1 = verts[i]
		local v2 = verts[(i % 5) + 1]
		drawTriangle(m, center, v1, v2, thickness, color)
	end

	-- Add an invisible “Hitbox” part for easy region checks/clicks/raycasting later
	local hit = Instance.new("Part")
	hit.Name = "Hitbox"
	hit.Size = Vector3.new(radius * 2.1, thickness, radius * 2.1)
	hit.CFrame = CFrame.new(center + Vector3.new(0, thickness * 0.5, 0))
	hit.Transparency = 1
	hit.CanCollide = false
	setCommonPartProps(hit)
	hit.Parent = m

	-- PrimaryPart helps you move the tile model if needed
	m.PrimaryPart = hit

	return m
end

-- =========================================================
-- BASE BUILDER
-- =========================================================
local function createBase(parent: Instance, baseId: number, position: Vector3, lookAt: Vector3): Model
	local baseModel = Instance.new("Model")
	baseModel.Name = ("Base_%02d"):format(baseId)
	baseModel.Parent = parent
	tag(baseModel, "Base")

	baseModel:SetAttribute("BaseId", baseId)

	-- Platform
	local platform = Instance.new("Part")
	platform.Name = "Platform"
	platform.Size = CONFIG.BasePlatformSize
	platform.CFrame = CFrame.new(position + Vector3.new(0, CONFIG.BasePlatformSize.Y * 0.5, 0))
	platform.Color = Color3.fromRGB(70, 70, 70)
	setCommonPartProps(platform)
	platform.Parent = baseModel

	-- Walls (simple square walls)
	local wallColor = Color3.fromRGB(55, 55, 55)
	local half = CONFIG.BasePlatformSize.X * 0.5
	local wallH = CONFIG.BaseWallHeight
	local wallT = CONFIG.BaseWallThickness

	local function wall(name: string, cf: CFrame, size: Vector3)
		local w = Instance.new("Part")
		w.Name = name
		w.Size = size
		w.CFrame = cf
		w.Color = wallColor
		setCommonPartProps(w)
		w.Parent = baseModel
	end

	local y = position.Y + CONFIG.BasePlatformSize.Y + wallH * 0.5
	wall("Wall_N", CFrame.new(position.X, y, position.Z - half + wallT * 0.5), Vector3.new(CONFIG.BasePlatformSize.X, wallH, wallT))
	wall("Wall_S", CFrame.new(position.X, y, position.Z + half - wallT * 0.5), Vector3.new(CONFIG.BasePlatformSize.X, wallH, wallT))
	wall("Wall_E", CFrame.new(position.X + half - wallT * 0.5, y, position.Z), Vector3.new(wallT, wallH, CONFIG.BasePlatformSize.Z))
	wall("Wall_W", CFrame.new(position.X - half + wallT * 0.5, y, position.Z), Vector3.new(wallT, wallH, CONFIG.BasePlatformSize.Z))

	-- Core (this is what other players will destroy)
	local core = Instance.new("Part")
	core.Name = "Core"
	core.Size = CONFIG.CoreSize
	core.CFrame = CFrame.new(position + Vector3.new(0, CONFIG.BasePlatformSize.Y + core.Size.Y * 0.5, 0))
	core.Color = Color3.fromRGB(200, 70, 70)
	core.Material = Enum.Material.Neon
	setCommonPartProps(core)
	core.Parent = baseModel
	tag(core, "BaseCore")
	core:SetAttribute("BaseId", baseId)
	core:SetAttribute("MaxHealth", 1000)
	core:SetAttribute("Health", 1000)

	-- Player spawn
	local playerSpawn = Instance.new("SpawnLocation")
	playerSpawn.Name = "PlayerSpawn"
	playerSpawn.Size = Vector3.new(12, 1.2, 12)
	playerSpawn.CFrame = CFrame.new(position + Vector3.new(0, CONFIG.BasePlatformSize.Y + playerSpawn.Size.Y * 0.5, 0))
	playerSpawn.Anchored = true
	playerSpawn.Neutral = true
	playerSpawn.Transparency = 1
	playerSpawn.CanCollide = false
	playerSpawn.Parent = baseModel
	tag(playerSpawn, "PlayerSpawn")
	playerSpawn:SetAttribute("BaseId", baseId)

	-- Pads + Spawns folders
	local padsFolder = ensureFolder(baseModel, "NpcPads")
	local spawnsFolder = ensureFolder(baseModel, "NpcSpawns")

	-- Create 8 pads in a ring
	for i = 1, CONFIG.NpcPadCount do
		local angle = math.rad((i - 1) * (360 / CONFIG.NpcPadCount))
		local offset = Vector3.new(math.cos(angle) * CONFIG.NpcPadRingRadius, 0, math.sin(angle) * CONFIG.NpcPadRingRadius)

		local pad = Instance.new("Part")
		pad.Name = ("Pad_%02d"):format(i)
		pad.Size = CONFIG.NpcPadSize
		pad.CFrame = CFrame.new(position + offset + Vector3.new(0, CONFIG.BasePlatformSize.Y + pad.Size.Y * 0.5, 0))
		pad.Color = (i <= CONFIG.NpcPadsFreeAtStart) and Color3.fromRGB(80, 180, 90) or Color3.fromRGB(120, 120, 120)
		pad.Material = Enum.Material.SmoothPlastic
		setCommonPartProps(pad)
		pad.Parent = padsFolder

		tag(pad, "NpcPad")
		pad:SetAttribute("BaseId", baseId)
		pad:SetAttribute("PadIndex", i)
		pad:SetAttribute("IsFreeAtStart", i <= CONFIG.NpcPadsFreeAtStart)
		pad:SetAttribute("Unlocked", i <= CONFIG.NpcPadsFreeAtStart)
		pad:SetAttribute("AssignedNpcId", "") -- you’ll fill later

		-- Spawn marker directly above the pad (where NPC model will appear)
		local sp = Instance.new("Part")
		sp.Name = ("Spawn_%02d"):format(i)
		sp.Size = CONFIG.NpcSpawnMarkerSize
		sp.CFrame = pad.CFrame + Vector3.new(0, CONFIG.NpcSpawnOffsetY, 0)
		sp.Color = Color3.fromRGB(70, 130, 200)
		sp.Material = Enum.Material.Neon
		setCommonPartProps(sp)
		sp.Parent = spawnsFolder

		tag(sp, "NpcSpawn")
		sp:SetAttribute("BaseId", baseId)
		sp:SetAttribute("PadIndex", i)
	end

	-- Base orientation helper (optional)
	local facing = CFrame.lookAt(position, lookAt)
	baseModel:SetAttribute("FacingLookVectorX", facing.LookVector.X)
	baseModel:SetAttribute("FacingLookVectorZ", facing.LookVector.Z)

	-- PrimaryPart for easy moving/debug
	baseModel.PrimaryPart = platform

	return baseModel
end

-- =========================================================
-- TERRITORY FIELD BUILDER
-- =========================================================
local function createTerritoryTile(territoryFolder: Instance, center: Vector3, ownerBaseId: number, isProtected: boolean, protectedBaseId: number?, tileId: number)
	local tileColor = Color3.fromRGB(90, 90, 90)
	if ownerBaseId ~= 0 then
		-- Slightly different for owned tiles (you can recolor later per-base)
		tileColor = Color3.fromRGB(80, 80, 110)
	end
	if isProtected then
		tileColor = Color3.fromRGB(60, 120, 60)
	end

	local tile = createPentagonTile(territoryFolder, center, CONFIG.TileRadius, CONFIG.TileThickness, tileColor)
	tag(tile, "TerritoryTile")

	tile:SetAttribute("TileId", tileId)
	tile:SetAttribute("OwnerBaseId", ownerBaseId) -- 0 = neutral
	tile:SetAttribute("CaptureProgress", 0)
	tile:SetAttribute("IsProtected", isProtected)
	tile:SetAttribute("ProtectedBaseId", protectedBaseId or 0)

	-- For quick radius checks later (NPC capture range, etc.)
	tile:SetAttribute("TileRadius", CONFIG.TileRadius)
end

local function buildMainField(territoryFolder: Instance, tileIdCounter: number)
	-- Build a big grid of pentagon tiles.
	-- NOTE: Real pentagon tiling isn’t perfectly regular, but for gameplay you just need “cells”.
	-- We place pentagon models on a clean grid spacing; they still *look* like pentagons.

	local counter = tileIdCounter
	for gx = -CONFIG.FieldHalfSize, CONFIG.FieldHalfSize do
		for gz = -CONFIG.FieldHalfSize, CONFIG.FieldHalfSize do
			local x = CONFIG.FieldCenter.X + gx * CONFIG.TileSpacing
			local z = CONFIG.FieldCenter.Z + gz * CONFIG.TileSpacing

			-- Slight offset every other row for variety
			if (gz % 2) == 1 then
				x += CONFIG.TileSpacing * 0.5
			end

			local center = Vector3.new(x, CONFIG.GroundY, z)
			createTerritoryTile(territoryFolder, center, 0, false, 0, counter)
			counter += 1
		end
	end

	return counter
end

local function buildProtectedTilesAroundBase(territoryFolder: Instance, baseId: number, basePos: Vector3, tileIdCounter: number)
	-- Protected ring: tiles that cannot be captured from this base.
	local counter = tileIdCounter
	for i = 1, CONFIG.ProtectedRingCount do
		local angle = math.rad((i - 1) * (360 / CONFIG.ProtectedRingCount))
		local offset = Vector3.new(math.cos(angle) * CONFIG.ProtectedRingRadius, 0, math.sin(angle) * CONFIG.ProtectedRingRadius)
		local center = Vector3.new(basePos.X + offset.X, CONFIG.GroundY, basePos.Z + offset.Z)
		createTerritoryTile(territoryFolder, center, baseId, true, baseId, counter)
		counter += 1
	end

	return counter
end

-- =========================================================
-- MAIN BUILD
-- =========================================================
function MapBuilder:Build()
	wipeOldMap()

	local mapFolder = ensureFolder(Workspace, CONFIG.MapFolderName)
	local basesFolder = ensureFolder(mapFolder, "Bases")
	local territoryFolder = ensureFolder(mapFolder, "Territories")

	tag(mapFolder, "GeneratedMapRoot")

	local tileIdCounter = 1
	-- Build territory field first (big neutral area)
	tileIdCounter = buildMainField(territoryFolder, tileIdCounter)

	-- Build 8 bases in a ring
	for baseId = 1, CONFIG.BaseCount do
		local t = (baseId - 1) / CONFIG.BaseCount
		local angle = t * math.pi * 2

		local bx = math.cos(angle) * CONFIG.BaseRingRadius
		local bz = math.sin(angle) * CONFIG.BaseRingRadius
		local basePos = Vector3.new(bx, CONFIG.GroundY, bz)

		-- Make each base face the center of the map
		local lookAt = Vector3.new(0, CONFIG.GroundY, 0)

		createBase(basesFolder, baseId, basePos, lookAt)

		-- Protected tiles around each base
		tileIdCounter = buildProtectedTilesAroundBase(territoryFolder, baseId, basePos, tileIdCounter)
	end

	-- Helpful attributes at the map root
	mapFolder:SetAttribute("BaseCount", CONFIG.BaseCount)
	mapFolder:SetAttribute("NpcPadsPerBase", CONFIG.NpcPadCount)
	mapFolder:SetAttribute("FreePadsAtStart", CONFIG.NpcPadsFreeAtStart)

	print(("✅ Map build complete: %d bases + territory field created."):format(CONFIG.BaseCount))

	return mapFolder
end

return MapBuilder
