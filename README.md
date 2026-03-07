# Deeper Level

`Deeper Level` is a discovery-driven adventure roguelite prototype. Each run drops the player into a generated world with hidden rules, local lifeforms, and a coherent internal logic that can be learned through observation and experimentation.

The current repository is focused on the first playable wedge:

- Can players tell that each world has different rules?
- Is discovering those rules fun?
- Do they want to immediately start another run?

## Project Layout

The root of the repository is intentionally minimal:

- `game/` - Godot 4 project for the playable prototype
- `README.md` - top-level project overview
- `LICENSE` - repository license

For implementation details and controls, see `game/README.md`.

## Tech Stack

- `Godot 4.x`
- typed `GDScript`
- data-driven rules via Godot `Resource` assets
- local telemetry written to Godot `user://` storage

## How To Run

1. Open `game/` as a Godot 4 project.
2. Run the main scene.
3. Start a run from the hub and infer how that world works.

## Core Prototype Loop

- enter a new world
- observe terrain, creatures, and strange devices
- form a hypothesis about the world's hidden rules
- test that hypothesis through interaction
- unlock the deeper chamber by understanding the world correctly
- extract an artifact or take a transformation back into the meta-layer

## Current Scope

This prototype is intentionally narrow. It does **not** yet include:

- world archetypes
- async social systems
- creator tools
- deeper simulation

Those come later only if the core discovery loop proves compelling.
