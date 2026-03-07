# Deeper Level Prototype

Godot 4 prototype for the discovery-first loop described in the plan.

## How to run

1. Open the `game/` folder as a Godot 4 project.
2. Run the main scene.
3. From the hub, start a run and learn the world's hidden rules.

## Controls

- `WASD` or arrow keys: move
- `E`: interact
- `1` / `2`: guess whether the world favors `Light` or `Shadow`
- `7` / `8` / `9`: guess how resonators wake
- `F3`: toggle debug overlay

## Prototype loop

- Observe how terrain changes movement and attunement
- Watch what creatures prefer
- Test resonators with touch, linked chimes, or creature luring
- Wake all 3 resonators
- Enter the deeper chamber
- Extract an `Archive Seed` or take a transformation

## Playtest data

The prototype writes local telemetry and meta-save data into Godot's `user://` storage so you can review:

- run duration
- experiment counts
- hypothesis accuracy
- extraction outcome
- immediate replay behavior
