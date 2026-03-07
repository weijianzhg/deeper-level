class_name WorldView
extends Node2D

var run_world: Node

func _draw() -> void:
	if run_world == null or run_world.state == null:
		return
	var state: WorldState = run_world.state
	var tile_size := state.tile_size

	for y in state.height:
		for x in state.width:
			var cell := Vector2i(x, y)
			var cell_data := state.get_cell(cell)
			var rect := Rect2(Vector2(x * tile_size, y * tile_size), Vector2(tile_size, tile_size))
			var fill := _get_tile_color(cell_data)
			draw_rect(rect, fill)
			draw_rect(rect, Color(0.1, 0.12, 0.16), false, 1.0)

	for object_data in state.objects:
		_draw_object(object_data, state)

	for creature in state.creatures:
		_draw_creature(creature)

	if is_instance_valid(run_world.player):
		draw_circle(run_world.player.position, 11.0, Color(0.98, 0.95, 0.9))
		draw_circle(run_world.player.position, 14.0, Color(0.98, 0.95, 0.9, 0.25), false, 2.0)

func _get_tile_color(cell_data: Dictionary) -> Color:
	if bool(cell_data.get("solid", false)):
		return Color(0.14, 0.15, 0.2)
	match str(cell_data.get("affinity", "neutral")):
		"sol":
			return Color(0.41, 0.33, 0.15)
		"gloom":
			return Color(0.18, 0.19, 0.34)
		_:
			return Color(0.22, 0.24, 0.28)

func _draw_object(object_data: Dictionary, state: WorldState) -> void:
	var template: ObjectTemplate = object_data.get("template") as ObjectTemplate
	var color := Color(template.color_hex) if template != null else Color.WHITE
	var position := state.grid_to_world(Vector2i(object_data["position"]))
	match str(object_data.get("type", "")):
		"resonator":
			var resonator_color := color if bool(object_data.get("charged", false)) else color.darkened(0.35)
			draw_circle(position, 15.0, resonator_color)
			draw_circle(position, 24.0, color.lightened(0.25), false, 2.0)
		"chime":
			var rect := Rect2(position - Vector2(8, 18), Vector2(16, 36))
			draw_rect(rect, color)
			if float(object_data.get("active_timer", 0.0)) > 0.0:
				draw_circle(position, 38.0, color, false, 2.0)
		"lore_stone":
			draw_rect(Rect2(position - Vector2(12, 16), Vector2(24, 32)), color)
		"gate":
			var gate_color := color if bool(object_data.get("open", false)) else color.darkened(0.25)
			draw_rect(Rect2(position - Vector2(14, 20), Vector2(28, 40)), gate_color)
		"artifact":
			draw_circle(position, 10.0, color)
			draw_circle(position, 20.0, color, false, 2.0)
		"pool":
			draw_circle(position, 18.0, color)
			draw_circle(position, 28.0, color.lightened(0.15), false, 2.0)

func _draw_creature(creature: Dictionary) -> void:
	var template: CreatureTemplate = creature.get("template") as CreatureTemplate
	var color := Color(template.color_hex) if template != null else Color(0.7, 0.8, 1.0)
	draw_circle(creature["position"], 9.0, color)
