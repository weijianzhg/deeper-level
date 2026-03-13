class_name CreatureBrain
extends RefCounted

func step_creature(
	creature: Dictionary,
	delta: float,
	world_state: WorldState,
	resolver: RuleResolver
) -> void:
	var template: CreatureTemplate = creature.get("template") as CreatureTemplate
	var speed := template.speed if template != null else 50.0
	var target := _pick_target(creature, world_state, resolver)
	var direction := Vector2.ZERO
	if target != Vector2.ZERO:
		direction = (target - creature["position"]).normalized()
	else:
		creature["wander_timer"] = float(creature.get("wander_timer", 0.0)) - delta
		if float(creature["wander_timer"]) <= 0.0:
			creature["wander_timer"] = 1.5
			creature["wander_dir"] = Vector2.RIGHT.rotated(randf_range(0.0, TAU))
		direction = creature["wander_dir"]

	var next_position: Vector2 = creature["position"] + direction * speed * delta
	var next_cell := world_state.world_to_grid(next_position)
	creature["velocity"] = direction * speed
	if world_state.is_walkable(next_cell):
		creature["position"] = next_position
	else:
		creature["velocity"] = Vector2.ZERO
		creature["wander_dir"] = -direction

	var current_cell := world_state.world_to_grid(creature["position"])
	if resolver.is_favored_affinity(world_state.get_affinity(current_cell)):
		creature["favored_time"] = float(creature.get("favored_time", 0.0)) + delta
	else:
		creature["favored_time"] = max(
			0.0,
			float(creature.get("favored_time", 0.0)) - delta * 0.5
		)

func _pick_target(creature: Dictionary, world_state: WorldState, resolver: RuleResolver) -> Vector2:
	for object_data in world_state.get_objects_by_type("chime"):
		if float(object_data.get("active_timer", 0.0)) <= 0.0:
			continue
		var chime_cell := Vector2i(object_data["position"])
		if resolver.is_favored_affinity(world_state.get_affinity(chime_cell)):
			return world_state.grid_to_world(chime_cell)

	var current_cell := world_state.world_to_grid(creature["position"])
	if resolver.is_favored_affinity(world_state.get_affinity(current_cell)):
		return Vector2.ZERO

	var best_cell := current_cell
	var best_score := INF
	for y in range(max(1, current_cell.y - 4), min(world_state.height - 1, current_cell.y + 5)):
		for x in range(
			max(1, current_cell.x - 4),
			min(world_state.width - 1, current_cell.x + 5)
		):
			var cell := Vector2i(x, y)
			if not world_state.is_walkable(cell):
				continue
			if not resolver.is_favored_affinity(world_state.get_affinity(cell)):
				continue
			var distance := current_cell.distance_to(cell)
			if distance < best_score:
				best_score = distance
				best_cell = cell
	if best_score == INF:
		return Vector2.ZERO
	return world_state.grid_to_world(best_cell)
