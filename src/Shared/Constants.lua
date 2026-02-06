local Constants = {}

Constants.MaxBases = 8
Constants.SlotsPerBase = 8
Constants.UnlockedSlotsAtStart = 4
Constants.ProtectedPentagons = 5

Constants.Rarities = {
  "COMMON",
  "UNCOMMON",
  "RARE",
  "EPIC",
  "LEGENDARY",
  "MYTHIC",
  "SECRET",
}

Constants.RarityWeights = {
  COMMON = 600,
  UNCOMMON = 250,
  RARE = 100,
  EPIC = 35,
  LEGENDARY = 12,
  MYTHIC = 2,
  SECRET = 1,
}

Constants.RarityStats = {
  COMMON = { power = 1, maxHealth = 100, captureSpeed = 1 },
  UNCOMMON = { power = 1.2, maxHealth = 120, captureSpeed = 1.1 },
  RARE = { power = 1.5, maxHealth = 150, captureSpeed = 1.25 },
  EPIC = { power = 2, maxHealth = 200, captureSpeed = 1.5 },
  LEGENDARY = { power = 2.6, maxHealth = 260, captureSpeed = 1.9 },
  MYTHIC = { power = 3.2, maxHealth = 320, captureSpeed = 2.4 },
  SECRET = { power = 4, maxHealth = 400, captureSpeed = 3 },
}

Constants.NpcCatalog = {
  { id = "spear_guard", name = "Spear Guard", rarity = "COMMON" },
  { id = "slinger", name = "Slinger", rarity = "COMMON" },
  { id = "shieldbearer", name = "Shieldbearer", rarity = "UNCOMMON" },
  { id = "saboteur", name = "Saboteur", rarity = "RARE" },
  { id = "stormcaller", name = "Stormcaller", rarity = "EPIC" },
  { id = "crystal_knight", name = "Crystal Knight", rarity = "LEGENDARY" },
  { id = "void_marcher", name = "Void Marcher", rarity = "MYTHIC" },
  { id = "oracle_zero", name = "Oracle Zero", rarity = "SECRET" },
}

return Constants
