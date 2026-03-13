class_name Player
extends CharacterBody3D

var move_speed: float = 135.0
var health: float = 100.0
var attunement: float = 55.0
var plane_position: Vector2 = Vector2.ZERO

var body_mesh := MeshInstance3D.new()
var aura_mesh := MeshInstance3D.new()
var pulse: float = 0.0

func _ready() -> void:
	_build_visuals()

func tick(delta: float, run_world: Node, resolver: RuleResolver) -> void:
	var input_vector := Vector2.ZERO
	input_vector.x = Input.get_axis("ui_left", "ui_right")
	input_vector.y = Input.get_axis("ui_up", "ui_down")
	if input_vector == Vector2.ZERO:
		if Input.is_key_pressed(KEY_A):
			input_vector.x -= 1.0
		if Input.is_key_pressed(KEY_D):
			input_vector.x += 1.0
		if Input.is_key_pressed(KEY_W):
			input_vector.y -= 1.0
		if Input.is_key_pressed(KEY_S):
			input_vector.y += 1.0

	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()

	var current_cell: Vector2i = run_world.state.world_to_grid(plane_position)
	var affinity: String = run_world.state.get_affinity(current_cell)
	var speed_multiplier := resolver.get_player_speed_multiplier(affinity)
	var motion := input_vector * move_speed * speed_multiplier * delta
	plane_position = run_world.slide_body(plane_position, motion, 10.0)

	current_cell = run_world.state.world_to_grid(plane_position)
	affinity = run_world.state.get_affinity(current_cell)
	attunement = clamp(attunement + resolver.get_attunement_delta(affinity, delta), 0.0, 100.0)
	health = clamp(health + resolver.get_health_delta(attunement, delta), 0.0, 100.0)

	if input_vector != Vector2.ZERO:
		rotation.y = lerp_angle(rotation.y, atan2(input_vector.x, input_vector.y), min(1.0, delta * 10.0))

	pulse += delta * (1.2 + attunement / 140.0)
	_sync_visual(run_world)

func place_at(world: Node, new_plane_position: Vector2) -> void:
	plane_position = new_plane_position
	_sync_visual(world)

func _build_visuals() -> void:
	var body := CapsuleMesh.new()
	body.radius = 0.7
	body.height = 2.8
	body_mesh.mesh = body
	body_mesh.position.y = 1.35
	body_mesh.material_override = _make_material(Color(0.95, 0.93, 0.88), 0.0)
	add_child(body_mesh)

	var aura := CylinderMesh.new()
	aura.top_radius = 1.25
	aura.bottom_radius = 1.25
	aura.height = 0.15
	aura_mesh.mesh = aura
	aura_mesh.position.y = 0.08
	aura_mesh.material_override = _make_material(Color(0.85, 0.92, 1.0, 0.32), 1.4, true)
	add_child(aura_mesh)

func _sync_visual(run_world: Node) -> void:
	position = run_world.plane_to_world(plane_position, 0.0)
	var bob := 1.35 + sin(pulse * 1.7) * 0.04
	body_mesh.position.y = bob
	var aura_scale := 0.92 + attunement / 240.0
	aura_mesh.scale = Vector3.ONE * aura_scale
	var aura_material := aura_mesh.material_override as StandardMaterial3D
	if aura_material != null:
		aura_material.emission_energy_multiplier = lerp(0.5, 2.2, attunement / 100.0)
		aura_material.albedo_color = Color(0.72, 0.88, 1.0, lerp(0.18, 0.38, attunement / 100.0))

func _make_material(color: Color, emission_energy: float, transparent: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.32
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy
	return material
