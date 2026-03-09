# Deeper Level

A discovery-driven roguelite adventure game prototype built in Godot 4 with typed GDScript.

## Cursor Cloud specific instructions

### Engine

Godot 4.4.x is the only runtime dependency. The binary is installed at `/usr/local/bin/godot`. There are no package managers, no Docker, no databases, and no external services.

### Running tests

Two headless GDScript test scripts live in `game/tests/`. Run them from the `game/` directory:

```
godot --headless --script res://tests/rule_resolver_test.gd
godot --headless --script res://tests/run_generator_smoke_test.gd
```

Both scripts extend `SceneTree`, run assertions, print a pass message, and call `quit()`.

### Running the editor

```
cd game && godot --editor --rendering-method gl_compatibility
```

The `gl_compatibility` renderer is required in the Cloud VM (no Vulkan/GPU support).

### Running the game

```
cd game && godot --rendering-method gl_compatibility
```

### Known issue: ExtractionManager autoload conflict

`scripts/systems/extraction_manager.gd` declares `class_name ExtractionManager` while also being registered as an autoload singleton named `ExtractionManager` in `project.godot`. Godot 4.4+ treats this as a parse error (`Class "ExtractionManager" hides an autoload singleton`), which prevents the main scene (`MetaHub`) and `RunWorld` from loading their scripts at runtime. The headless tests are unaffected because they do not depend on the autoload. To fix, remove the `class_name ExtractionManager` line from `extraction_manager.gd` (the singleton is accessed by autoload name, not class name).

### Project import

Before first use, import the project so Godot caches resources and registers global class names:

```
cd game && godot --headless --import
```

This generates the `.godot/` directory. It only needs to be done once (or after deleting `.godot/`).

### Lint / static analysis

There is no separate linter configured. GDScript parse errors surface during `--import` or `--editor` launch. The project uses a `## gdlint: disable=max-public-methods` pragma in `rule_resolver.gd`.
