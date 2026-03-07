class_name Player
extends Node2D

var move_speed: float = 135.0
var health: float = 100.0
var attunement: float = 55.0

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

	var current_cell := run_world.state.world_to_grid(position)
	var affinity := run_world.state.get_affinity(current_cell)
	var speed_multiplier := resolver.get_player_speed_multiplier(affinity)
	var motion := input_vector * move_speed * speed_multiplier * delta
	position = run_world.slide_body(position, motion, 10.0)

	current_cell = run_world.state.world_to_grid(position)
	affinity = run_world.state.get_affinity(current_cell)
	attunement = clamp(attunement + resolver.get_attunement_delta(affinity, delta), 0.0, 100.0)
	health = clamp(health + resolver.get_health_delta(attunement, delta), 0.0, 100.0)
