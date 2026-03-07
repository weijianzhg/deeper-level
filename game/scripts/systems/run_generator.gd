class_name RunGenerator
extends RefCounted

const PHYSICAL_RULES := [
	"res://data/rules/sunlit_tides.tres",
	"res://data/rules/shadow_tides.tres"
]

const ECOLOGY_RULES := {
	"sol": "res://data/rules/sol_foragers.tres",
	"gloom": "res://data/rules/gloom_foragers.tres"
}

const TRANSFORMATION_RULES := [
	"res://data/rules/presence_attunement.tres",
	"res://data/rules/chime_attunement.tres",
	"res://data/rules/creature_attunement.tres"
]

const CREATURE_TEMPLATES := [
	"res://data/creatures/forager.tres",
	"res://data/creatures/wisp.tres",
	"res://data/creatures/shellback.tres"
]

const OBJECT_TEMPLATES := {
	"resonator": "res://data/objects/resonator.tres",
	"chime": "res://data/objects/chime.tres",
	"lore_stone": "res://data/objects/lore_stone.tres",
	"gate": "res://data/objects/gate.tres",
	"artifact": "res://data/objects/artifact.tres",
	"pool": "res://data/objects/pool.tres"
}

func generate(seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var physical_rule: RuleModule = load(PHYSICAL_RULES[rng.randi_range(0, PHYSICAL_RULES.size() - 1)])
	var ecology_rule: RuleModule = load(ECOLOGY_RULES[physical_rule.favored_affinity])
	var transformation_rule: RuleModule = load(
		TRANSFORMATION_RULES[rng.randi_range(0, TRANSFORMATION_RULES.size() - 1)]
	)

	var state := WorldState.new()
	state.seed = seed
	state.width = 26
	state.height = 18
	state.tiles = _build_tiles(state.width, state.height, physical_rule.favored_affinity, rng)
	state.player_spawn = state.grid_to_world(Vector2i(3, int(state.height / 2)))
	state.objects = _build_objects(state)
	state.creatures = _build_creatures(state, rng)

	return {
		"state": state,
		"bundle": {
			"physical": physical_rule,
			"ecology": ecology_rule,
			"transformation": transformation_rule
		}
	}

func _build_tiles(
	width: int,
	height: int,
	favored_affinity: String,
	rng: RandomNumberGenerator
) -> Array:
	var tiles: Array = []
	var gate_x := int(width / 2)
	var gate_y := int(height / 2)
	var favored_centers := [
		Vector2i(5, 4),
		Vector2i(9, height - 5),
		Vector2i(gate_x - 4, gate_y)
	]
	var opposing_centers := [
		Vector2i(6, int(height / 2)),
		Vector2i(gate_x - 2, 3),
		Vector2i(gate_x - 1, height - 4)
	]

	for y in height:
		var row: Array = []
		for x in width:
			var cell := {"solid": false, "affinity": "neutral"}
			if x == 0 or y == 0 or x == width - 1 or y == height - 1:
				cell["solid"] = true
			if x == gate_x and y > 2 and y < height - 3 and y != gate_y:
				cell["solid"] = true
			if not cell["solid"]:
				var favored_score := _nearest_distance(Vector2i(x, y), favored_centers)
				favored_score += rng.randf_range(-1.2, 1.2)
				var opposing_score := _nearest_distance(Vector2i(x, y), opposing_centers)
				opposing_score += rng.randf_range(-1.2, 1.2)
				if favored_score < opposing_score:
					cell["affinity"] = favored_affinity
				else:
					cell["affinity"] = "gloom" if favored_affinity == "sol" else "sol"
				if x > gate_x + 1:
					cell["affinity"] = favored_affinity
			row.append(cell)
		tiles.append(row)

	_carve_room(tiles, Rect2i(1, 1, 8, height - 2))
	_carve_room(tiles, Rect2i(gate_x - 5, 1, 5, height - 2))
	_carve_room(tiles, Rect2i(gate_x + 1, 3, width - gate_x - 2, height - 6))
	return tiles

func _build_objects(state: WorldState) -> Array:
	var objects: Array = []
	var resonator_positions := [Vector2i(9, 4), Vector2i(10, 9), Vector2i(9, 14)]
	var chime_positions := [Vector2i(6, 4), Vector2i(6, 9), Vector2i(6, 14)]

	for index in resonator_positions.size():
		objects.append({
			"id": "resonator_%d" % index,
			"type": "resonator",
			"position": resonator_positions[index],
			"charged": false,
			"template": load(OBJECT_TEMPLATES["resonator"])
		})
		objects.append({
			"id": "chime_%d" % index,
			"type": "chime",
			"position": chime_positions[index],
			"active_timer": 0.0,
			"linked_resonator_id": "resonator_%d" % index,
			"template": load(OBJECT_TEMPLATES["chime"])
		})

	var lore_positions := [Vector2i(3, 4), Vector2i(4, 13), Vector2i(11, 2)]
	for index in lore_positions.size():
		objects.append({
			"id": "lore_%d" % index,
			"type": "lore_stone",
			"position": lore_positions[index],
			"used": false,
			"clue_index": index,
			"template": load(OBJECT_TEMPLATES["lore_stone"])
		})

	objects.append({
		"id": "gate",
		"type": "gate",
		"position": Vector2i(int(state.width / 2), int(state.height / 2)),
		"open": false,
		"template": load(OBJECT_TEMPLATES["gate"])
	})
	objects.append({
		"id": "artifact",
		"type": "artifact",
		"position": Vector2i(state.width - 4, int(state.height / 2) - 2),
		"template": load(OBJECT_TEMPLATES["artifact"])
	})
	objects.append({
		"id": "pool",
		"type": "pool",
		"position": Vector2i(state.width - 4, int(state.height / 2) + 2),
		"template": load(OBJECT_TEMPLATES["pool"])
	})
	return objects

func _build_creatures(state: WorldState, rng: RandomNumberGenerator) -> Array:
	var creatures: Array = []
	var spawn_points := [Vector2i(5, 7), Vector2i(7, 11), Vector2i(4, 15)]
	for index in spawn_points.size():
		var template: CreatureTemplate = load(CREATURE_TEMPLATES[index % CREATURE_TEMPLATES.size()])
		creatures.append({
			"id": "creature_%d" % index,
			"template": template,
			"position": state.grid_to_world(spawn_points[index]),
			"velocity": Vector2.ZERO,
			"wander_timer": rng.randf_range(0.8, 2.2),
			"wander_dir": Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU)),
			"favored_time": 0.0
		})
	return creatures

func _nearest_distance(point: Vector2i, centers: Array) -> float:
	var best := INF
	for center in centers:
		best = min(best, point.distance_to(center))
	return best

func _carve_room(tiles: Array, rect: Rect2i) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			if y < 0 or y >= tiles.size():
				continue
			if x < 0 or x >= tiles[y].size():
				continue
			tiles[y][x]["solid"] = false
