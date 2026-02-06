# Conqueror of the Territories (Roblox)

This repo contains a starter Roblox experience that matches the game design:

- 8 player bases per server.
- Each base has 8 NPC slots (4 unlocked at the start).
- Players open boxes to roll NPCs of different rarities.
- NPCs can guard the base or take pentagons.
- Pentagons are easier to take when free, harder when owned.
- Each base has protected pentagons that cannot be captured by others.
- Each base has a core; destroying it transfers all owned pentagons to the attacker.

## Recommended tooling
This project is structured for **Rojo**. Use `default.project.json` to sync `src/` into Roblox Studio.

## Quick start
1. Install [Rojo](https://rojo.space/).
2. In Roblox Studio, create a new experience.
3. Run `rojo serve` and connect.
4. The scripts will appear under **ServerScriptService** and **ReplicatedStorage**.

## Game logic overview
- **GameService**: server bootstrap, coordinates services.
- **PlayerBaseService**: creates and tracks bases, slots, and protected pentagons.
- **BoxService**: handles NPC rolls and rarity odds.
- **NpcService**: spawns NPCs, assigns them to slots, and switches between guard/capture.
- **PentagonService**: tracks ownership, capture progress, and difficulty.
- **CoreService**: manages base core health and territory transfer on destruction.

## Notes
This is a foundation. You will still need to:
- Build the actual 3D map (pentagon tiles, base models).
- Add UI for boxes, NPC selection, and placement.
- Hook NPC movement/AI (PathfindingService) to take pentagons.
- Balance odds, NPC stats, and capture rates.
