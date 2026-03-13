class_name WorldView
extends Node3D

var run_world: Node
var tile_root := Node3D.new()
var object_root := Node3D.new()
var creature_root := Node3D.new()
var object_nodes: Dictionary = {}
var creature_nodes: Dictionary = {}
var material_cache: Dictionary = {}

func _ready() -> void:
	add_child(tile_root)
	add_child(object_root)
	add_child(creature_root)

func rebuild_from_state() -> void:
	if run_world == null or run_world.state == null:
		return
	_clear_node(tile_root)
	_clear_node(object_root)
	_clear_node(creature_root)
	object_nodes.clear()
	creature_nodes.clear()
	_build_floor()
	_build_tiles()
	_build_objects()
	_build_creatures()
	sync_dynamic()

func sync_dynamic() -> void:
	if run_world == null or run_world.state == null:
		return
	var state: WorldState = run_world.state

	for object_data in state.objects:
		var object_id := str(object_data.get("id", ""))
		var node := object_nodes.get(object_id) as Node3D
		if node == null:
			continue
		node.position = run_world.cell_to_world(Vector2i(object_data["position"]), 0.0)
		_sync_object_visual(node, object_data)

	for creature in state.creatures:
		var creature_id := str(creature.get("id", ""))
		var creature_node := creature_nodes.get(creature_id) as Node3D
		if creature_node == null:
			continue
		var bob := 0.95 + sin(Time.get_ticks_msec() / 180.0 + creature_node.get_index()) * 0.08
		creature_node.position = run_world.plane_to_world(creature["position"], bob)
		var motion := creature.get("velocity", Vector2.ZERO) as Vector2
		if motion.length() > 0.01:
			creature_node.rotation.y = lerp_angle(
				creature_node.rotation.y,
				atan2(motion.x, motion.y),
				0.16
			)

func _build_floor() -> void:
	var state: WorldState = run_world.state
	var plate := MeshInstance3D.new()
	var base := BoxMesh.new()
	base.size = Vector3(
		state.width * state.tile_size * run_world.WORLD_SCALE + 8.0,
		0.6,
		state.height * state.tile_size * run_world.WORLD_SCALE + 8.0
	)
	plate.mesh = base
	plate.position = Vector3(0.0, -0.35, 0.0)
	plate.material_override = _get_material("base", Color(0.06, 0.07, 0.08), 0.0)
	tile_root.add_child(plate)

func _build_tiles() -> void:
	var state: WorldState = run_world.state
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(run_world.tile_world_size(), 0.5, run_world.tile_world_size())
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(run_world.tile_world_size(), 5.6, run_world.tile_world_size())

	for y in state.height:
		for x in state.width:
			var cell := Vector2i(x, y)
			var cell_data := state.get_cell(cell)
			var tile := MeshInstance3D.new()
			tile.mesh = wall_mesh if bool(cell_data.get("solid", false)) else floor_mesh
			tile.position = run_world.cell_to_world(cell, 2.8 if bool(cell_data.get("solid", false)) else -0.05)
			tile.material_override = _get_material(
				"tile:%s:%s" % [str(cell_data.get("affinity", "neutral")), str(bool(cell_data.get("solid", false)))],
				_tile_color(cell_data),
				0.0
			)
			tile_root.add_child(tile)

func _build_objects() -> void:
	for object_data in run_world.state.objects:
		var node := _create_object_node(object_data)
		object_nodes[str(object_data["id"])] = node
		object_root.add_child(node)

func _build_creatures() -> void:
	for creature in run_world.state.creatures:
		var node := _create_creature_node(creature)
		creature_nodes[str(creature["id"])] = node
		creature_root.add_child(node)

func _create_object_node(object_data: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = str(object_data["id"])
	var template: ObjectTemplate = object_data.get("template") as ObjectTemplate
	var color := Color(template.color_hex) if template != null else Color.WHITE

	match str(object_data.get("type", "")):
		"resonator":
			var base := MeshInstance3D.new()
			var base_mesh := CylinderMesh.new()
			base_mesh.top_radius = 1.8
			base_mesh.bottom_radius = 2.2
			base_mesh.height = 0.7
			base.mesh = base_mesh
			base.position.y = 0.35
			base.material_override = _get_material("resonator_base", Color(0.22, 0.18, 0.13), 0.0)
			root.add_child(base)

			var core := MeshInstance3D.new()
			var core_mesh := SphereMesh.new()
			core_mesh.radius = 1.15
			core_mesh.height = 2.2
			core.mesh = core_mesh
			core.name = "Core"
			core.position.y = 1.8
			core.material_override = _get_material("resonator_core_off", color.darkened(0.45), 0.0)
			root.add_child(core)

			var ring := MeshInstance3D.new()
			var ring_mesh := CylinderMesh.new()
			ring_mesh.top_radius = 3.3
			ring_mesh.bottom_radius = 3.3
			ring_mesh.height = 0.18
			ring.mesh = ring_mesh
			ring.name = "Ring"
			ring.position.y = 0.12
			ring.material_override = _get_material("resonator_ring_off", color.darkened(0.55), 0.0, true)
			root.add_child(ring)

			var light := OmniLight3D.new()
			light.name = "Light"
			light.position.y = 2.3
			light.light_color = color
			light.omni_range = 12.0
			light.light_energy = 0.0
			root.add_child(light)
		"chime":
			var post := MeshInstance3D.new()
			var post_mesh := CylinderMesh.new()
			post_mesh.top_radius = 0.28
			post_mesh.bottom_radius = 0.34
			post_mesh.height = 3.0
			post.mesh = post_mesh
			post.position.y = 1.5
			post.material_override = _get_material("chime_post", color.darkened(0.3), 0.0)
			root.add_child(post)

			var bell := MeshInstance3D.new()
			var bell_mesh := SphereMesh.new()
			bell_mesh.radius = 0.72
			bell_mesh.height = 1.2
			bell.mesh = bell_mesh
			bell.position = Vector3(0.0, 3.0, 0.0)
			bell.material_override = _get_material("chime_bell", color, 0.6)
			root.add_child(bell)

			var pulse := MeshInstance3D.new()
			var pulse_mesh := CylinderMesh.new()
			pulse_mesh.top_radius = 3.8
			pulse_mesh.bottom_radius = 3.8
			pulse_mesh.height = 0.1
			pulse.mesh = pulse_mesh
			pulse.name = "Pulse"
			pulse.position.y = 0.08
			pulse.material_override = _get_material("chime_pulse", Color(color, 0.22), 1.5, true)
			root.add_child(pulse)
		"lore_stone":
			var stone := MeshInstance3D.new()
			var stone_mesh := BoxMesh.new()
			stone_mesh.size = Vector3(1.9, 3.0, 1.25)
			stone.mesh = stone_mesh
			stone.name = "Stone"
			stone.position.y = 1.5
			stone.material_override = _get_material("lore_stone", color, 0.3)
			root.add_child(stone)
		"gate":
			var left := MeshInstance3D.new()
			var right := MeshInstance3D.new()
			var top := MeshInstance3D.new()
			var pillar_mesh := BoxMesh.new()
			pillar_mesh.size = Vector3(1.5, 5.2, 1.5)
			var top_mesh := BoxMesh.new()
			top_mesh.size = Vector3(7.8, 1.0, 1.5)
			left.mesh = pillar_mesh
			right.mesh = pillar_mesh
			top.mesh = top_mesh
			left.position = Vector3(-3.1, 2.6, 0.0)
			right.position = Vector3(3.1, 2.6, 0.0)
			top.position = Vector3(0.0, 5.0, 0.0)
			var gate_material := _get_material("gate", color, 0.0)
			left.material_override = gate_material
			right.material_override = gate_material
			top.material_override = gate_material
			root.add_child(left)
			root.add_child(right)
			root.add_child(top)
		"artifact":
			var seed := MeshInstance3D.new()
			var seed_mesh := SphereMesh.new()
			seed_mesh.radius = 0.95
			seed_mesh.height = 1.8
			seed.mesh = seed_mesh
			seed.name = "Seed"
			seed.position.y = 1.4
			seed.material_override = _get_material("artifact", color, 2.2)
			root.add_child(seed)

			var artifact_light := OmniLight3D.new()
			artifact_light.light_color = color
			artifact_light.omni_range = 10.0
			artifact_light.light_energy = 1.6
			artifact_light.position.y = 1.8
			root.add_child(artifact_light)
		"pool":
			var basin := MeshInstance3D.new()
			var basin_mesh := CylinderMesh.new()
			basin_mesh.top_radius = 2.4
			basin_mesh.bottom_radius = 2.7
			basin_mesh.height = 0.7
			basin.mesh = basin_mesh
			basin.position.y = 0.35
			basin.material_override = _get_material("pool_basin", color.darkened(0.45), 0.0)
			root.add_child(basin)

			var surface := MeshInstance3D.new()
			var surface_mesh := CylinderMesh.new()
			surface_mesh.top_radius = 2.1
			surface_mesh.bottom_radius = 2.1
			surface_mesh.height = 0.08
			surface.mesh = surface_mesh
			surface.name = "Surface"
			surface.position.y = 0.55
			surface.material_override = _get_material("pool_surface", Color(color, 0.7), 1.8, true)
			root.add_child(surface)

	return root

func _create_creature_node(creature: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = str(creature["id"])
	var template: CreatureTemplate = creature.get("template") as CreatureTemplate
	var color := Color(template.color_hex) if template != null else Color(0.7, 0.8, 1.0)

	var body := MeshInstance3D.new()
	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.75
	body_mesh.height = 1.4
	body.mesh = body_mesh
	body.material_override = _get_material("creature:%s" % color.to_html(), color, 0.7)
	root.add_child(body)

	var eye := MeshInstance3D.new()
	var eye_mesh := SphereMesh.new()
	eye_mesh.radius = 0.16
	eye_mesh.height = 0.3
	eye.mesh = eye_mesh
	eye.position = Vector3(0.0, 0.15, 0.62)
	eye.material_override = _get_material("creature_eye", Color(0.98, 0.98, 1.0), 0.4)
	root.add_child(eye)

	return root

func _sync_object_visual(node: Node3D, object_data: Dictionary) -> void:
	match str(object_data.get("type", "")):
		"resonator":
			var charged := bool(object_data.get("charged", false))
			var core := node.get_node_or_null("Core") as MeshInstance3D
			var ring := node.get_node_or_null("Ring") as MeshInstance3D
			var light := node.get_node_or_null("Light") as OmniLight3D
			var template := object_data.get("template") as ObjectTemplate
			var color := Color(template.color_hex) if template != null else Color(1.0, 0.8, 0.4)
			if core != null:
				core.material_override = _get_material(
					"resonator_core_%s" % str(charged),
					color if charged else color.darkened(0.45),
					2.4 if charged else 0.0
				)
				core.position.y = 1.8 + sin(Time.get_ticks_msec() / 280.0) * (0.12 if charged else 0.03)
			if ring != null:
				ring.material_override = _get_material(
					"resonator_ring_%s" % str(charged),
					Color(color, 0.55 if charged else 0.22),
					2.0 if charged else 0.0,
					true
				)
			if light != null:
				light.light_energy = 2.8 if charged else 0.0
		"chime":
			var active := float(object_data.get("active_timer", 0.0)) > 0.0
			var pulse := node.get_node_or_null("Pulse") as MeshInstance3D
			if pulse != null:
				pulse.visible = active
				var timer := float(object_data.get("active_timer", 0.0))
				var wave := 1.0 + sin((5.0 - timer) * 7.5) * 0.1
				pulse.scale = Vector3.ONE * wave
		"lore_stone":
			var stone := node.get_node_or_null("Stone") as MeshInstance3D
			if stone != null:
				var used := bool(object_data.get("used", false))
				var template := object_data.get("template") as ObjectTemplate
				var color := Color(template.color_hex) if template != null else Color(0.85, 0.9, 0.6)
				stone.material_override = _get_material(
					"lore_%s" % str(used),
					color.darkened(0.18 if used else 0.0),
					0.1 if used else 0.8
				)
		"gate":
			var open := bool(object_data.get("open", false))
			node.position.y = lerpf(node.position.y, -5.0 if open else 0.0, 0.16)
		"artifact":
			var seed := node.get_node_or_null("Seed") as MeshInstance3D
			if seed != null:
				seed.rotation.y += 0.035
				seed.position.y = 1.4 + sin(Time.get_ticks_msec() / 350.0) * 0.18
		"pool":
			var surface := node.get_node_or_null("Surface") as MeshInstance3D
			if surface != null:
				surface.scale = Vector3.ONE * (1.0 + sin(Time.get_ticks_msec() / 260.0) * 0.04)

func _tile_color(cell_data: Dictionary) -> Color:
	if bool(cell_data.get("solid", false)):
		return Color(0.16, 0.18, 0.22)
	match str(cell_data.get("affinity", "neutral")):
		"sol":
			return Color(0.58, 0.42, 0.16)
		"gloom":
			return Color(0.16, 0.2, 0.42)
		_:
			return Color(0.22, 0.25, 0.29)

func _clear_node(target: Node) -> void:
	for child in target.get_children():
		child.queue_free()

func _get_material(
	key: String,
	color: Color,
	emission_energy: float,
	transparent: bool = false
) -> StandardMaterial3D:
	if material_cache.has(key):
		return material_cache[key] as StandardMaterial3D
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.3 if emission_energy > 0.0 else 0.72
	material.metallic = 0.12 if emission_energy > 0.0 else 0.0
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy
	material_cache[key] = material
	return material
