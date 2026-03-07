class_name WorldState
extends RefCounted

var seed: int = 0
var tile_size: int = 32
var width: int = 0
var height: int = 0
var tiles: Array = []
var objects: Array = []
var creatures: Array = []
var player_spawn: Vector2 = Vector2.ZERO
var charged_resonators: int = 0
var gate_open: bool = false
var run_complete: bool = false
var finish_reason: String = ""
var reward_kind: String = ""
var reward_id: String = ""
var flags: Dictionary = {}

func world_to_grid(point: Vector2) -> Vector2i:
	return Vector2i(floor(point.x / tile_size), floor(point.y / tile_size))

func grid_to_world(cell: Vector2i) -> Vector2:
	return Vector2((cell.x + 0.5) * tile_size, (cell.y + 0.5) * tile_size)

func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height

func get_cell(cell: Vector2i) -> Dictionary:
	if not is_in_bounds(cell):
		return {"solid": true, "affinity": "void"}
	return tiles[cell.y][cell.x]

func get_affinity(cell: Vector2i) -> String:
	return str(get_cell(cell).get("affinity", "neutral"))

func is_walkable(cell: Vector2i) -> bool:
	if not is_in_bounds(cell):
		return false
	var cell_data: Dictionary = get_cell(cell)
	if bool(cell_data.get("solid", false)):
		return false
	var gate := get_object_by_type("gate")
	if gate and Vector2i(gate["position"]) == cell and not bool(gate.get("open", false)):
		return false
	return true

func get_object_by_type(object_type: String) -> Dictionary:
	for object_data in objects:
		if str(object_data.get("type", "")) == object_type:
			return object_data
	return {}

func get_objects_by_type(object_type: String) -> Array:
	var matches: Array = []
	for object_data in objects:
		if str(object_data.get("type", "")) == object_type:
			matches.append(object_data)
	return matches

func get_object_index(object_id: String) -> int:
	for index in objects.size():
		if str(objects[index].get("id", "")) == object_id:
			return index
	return -1

func get_object(object_id: String) -> Dictionary:
	var index := get_object_index(object_id)
	if index == -1:
		return {}
	return objects[index]

func update_object(object_id: String, values: Dictionary) -> void:
	var index := get_object_index(object_id)
	if index == -1:
		return
	for key in values.keys():
		objects[index][key] = values[key]

func charge_resonator(object_id: String) -> bool:
	var index := get_object_index(object_id)
	if index == -1:
		return false
	if bool(objects[index].get("charged", false)):
		return false
	objects[index]["charged"] = true
	charged_resonators += 1
	if charged_resonators >= get_objects_by_type("resonator").size():
		open_gate()
	return true

func open_gate() -> void:
	gate_open = true
	var gate := get_object_by_type("gate")
	if gate:
		update_object(str(gate["id"]), {"open": true})

func mark_once(flag_name: String) -> bool:
	if flags.has(flag_name):
		return false
	flags[flag_name] = true
	return true
