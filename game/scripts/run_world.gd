extends Node2D

const META_HUB_SCENE := preload("res://scenes/MetaHub.tscn")

var run_seed: int = 0
var state: WorldState
var resolver: RuleResolver
var journal: DiscoveryJournal
var telemetry: TelemetryLogger

var generator := RunGenerator.new()
var creature_brain := CreatureBrain.new()

var world_root: Node2D
var world_view: WorldView
var player: Player
var ui_root: Control
var status_label := RichTextLabel.new()
var journal_label := RichTextLabel.new()
var interaction_label := Label.new()
var flash_label := Label.new()
var rule_overlay: RuleOverlay

var lore_clues: Array[String] = []
var flash_timer: float = 0.0

func _ready() -> void:
	_build_scene()
	if run_seed == 0:
		run_seed = int(Time.get_unix_time_from_system()) + randi()
	_start_run(run_seed)

func _process(delta: float) -> void:
	if state == null or state.run_complete:
		return

	player.tick(delta, self, resolver)
	_update_player_observations()
	_update_objects(delta)
	_update_creatures(delta)
	_check_creature_resonance()
	_update_flash(delta)
	_update_ui()
	world_view.queue_redraw()
	rule_overlay.refresh()

	if player.health <= 0.0:
		_finish_run("perished")

func _unhandled_input(event: InputEvent) -> void:
	if state == null or state.run_complete:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_E:
				_interact()
			KEY_1:
				journal.set_affinity_guess("sol")
				telemetry.log_event("hypothesis_set", {"kind": "affinity", "value": "sol"})
				_flash("Hypothesis noted: this world favors Light terrain.")
			KEY_2:
				journal.set_affinity_guess("gloom")
				telemetry.log_event("hypothesis_set", {"kind": "affinity", "value": "gloom"})
				_flash("Hypothesis noted: this world favors Shadow terrain.")
			KEY_7:
				journal.set_transformation_guess("presence")
				telemetry.log_event("hypothesis_set", {"kind": "resonator", "value": "presence"})
				_flash("Hypothesis noted: direct touch wakes resonators.")
			KEY_8:
				journal.set_transformation_guess("chime")
				telemetry.log_event("hypothesis_set", {"kind": "resonator", "value": "chime"})
				_flash("Hypothesis noted: linked chimes wake resonators.")
			KEY_9:
				journal.set_transformation_guess("creature")
				telemetry.log_event("hypothesis_set", {"kind": "resonator", "value": "creature"})
				_flash("Hypothesis noted: local creatures wake resonators.")
			KEY_F3:
				rule_overlay.visible = not rule_overlay.visible
				rule_overlay.refresh()

func _build_scene() -> void:
	var background := ColorRect.new()
	background.color = Color(0.05, 0.06, 0.08)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	world_root = Node2D.new()
	world_root.position = Vector2(40, 72)
	add_child(world_root)

	world_view = WorldView.new()
	world_view.run_world = self
	world_root.add_child(world_view)

	player = Player.new()
	world_root.add_child(player)

	var canvas := CanvasLayer.new()
	add_child(canvas)

	ui_root = Control.new()
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(ui_root)

	status_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	status_label.offset_left = 24
	status_label.offset_top = 16
	status_label.custom_minimum_size = Vector2(840, 120)
	status_label.bbcode_enabled = true
	status_label.fit_content = true
	ui_root.add_child(status_label)

	journal_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	journal_label.offset_left = 910
	journal_label.offset_top = 245
	journal_label.offset_right = 1248
	journal_label.offset_bottom = 680
	journal_label.bbcode_enabled = true
	journal_label.fit_content = false
	ui_root.add_child(journal_label)

	interaction_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	interaction_label.offset_left = 24
	interaction_label.offset_top = 676
	interaction_label.offset_right = 900
	interaction_label.offset_bottom = 708
	ui_root.add_child(interaction_label)

	flash_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	flash_label.offset_left = 24
	flash_label.offset_top = 640
	flash_label.offset_right = 900
	flash_label.offset_bottom = 670
	ui_root.add_child(flash_label)

	rule_overlay = RuleOverlay.new()
	rule_overlay.run_world = self
	ui_root.add_child(rule_overlay)

func _start_run(seed: int) -> void:
	var payload: Dictionary = generator.generate(seed)
	state = payload["state"]
	resolver = RuleResolver.new(payload["bundle"])
	journal = DiscoveryJournal.new()
	journal.seed_initial_clues(resolver.get_starting_clues())
	lore_clues = resolver.get_lore_stone_clues()
	telemetry = TelemetryLogger.new(seed)
	telemetry.log_event("rule_bundle", {
		"physical": resolver.get_rule("physical").id,
		"ecology": resolver.get_rule("ecology").id,
		"transformation": resolver.get_rule("transformation").id
	})
	player.position = state.player_spawn
	player.health = 100.0
	player.attunement = 55.0
	_update_ui()
	_flash("Run seeded. Observe first, then test hypotheses.")

func _update_player_observations() -> void:
	var cell := state.world_to_grid(player.position)
	var affinity := state.get_affinity(cell)
	if affinity != "neutral":
		if resolver.is_favored_affinity(affinity):
			if state.mark_once("favored_step"):
				_add_clue(
					"Your body moves more cleanly on %s terrain."
					% resolver.get_affinity_display(affinity).to_lower(),
					"favored_step"
				)
		elif state.mark_once("resisted_step"):
			_add_clue("The opposite terrain drags at your movement and drains your focus.", "resisted_step")

	if player.attunement >= 85.0 and state.mark_once("high_attunement"):
		_add_clue(
			"Strong attunement seems to build when you linger where the world agrees with you.",
			"high_attunement"
		)
	if player.attunement <= 20.0 and state.mark_once("low_attunement"):
		_add_clue("When your attunement collapses, reality starts cutting back.", "low_attunement")

func _update_objects(delta: float) -> void:
	for object_data in state.get_objects_by_type("chime"):
		if float(object_data.get("active_timer", 0.0)) <= 0.0:
			continue
		state.update_object(str(object_data["id"]), {
			"active_timer": max(0.0, float(object_data["active_timer"]) - delta)
		})

func _update_creatures(delta: float) -> void:
	for creature in state.creatures:
		creature_brain.step_creature(creature, delta, state, resolver)
		var creature_cell := state.world_to_grid(creature["position"])
		if resolver.is_favored_affinity(state.get_affinity(creature_cell)) \
				and state.mark_once("creatures_prefer_favored"):
			_add_clue(
				"Local creatures keep settling on %s terrain."
				% resolver.get_affinity_display(resolver.get_creature_affinity()).to_lower(),
				"creatures_prefer_favored"
			)

func _check_creature_resonance() -> void:
	if resolver.get_transformation_method() != "creature":
		return
	for resonator in state.get_objects_by_type("resonator"):
		if bool(resonator.get("charged", false)):
			continue
		var resonator_position := state.grid_to_world(Vector2i(resonator["position"]))
		for creature in state.creatures:
			if creature["position"].distance_to(resonator_position) > 22.0:
				continue
			var creature_cell := state.world_to_grid(creature["position"])
			if not resolver.is_favored_affinity(state.get_affinity(creature_cell)):
				continue
			_charge_resonator(str(resonator["id"]), "creature")
			_add_clue(
				"A resonator wakes when local life enters its ring on favored terrain.",
				"creature_resonance"
			)
			return

func _interact() -> void:
	var nearest := _get_nearest_object()
	if nearest.is_empty():
		_flash("Nothing useful is within reach.")
		return
	match str(nearest.get("type", "")):
		"lore_stone":
			_use_lore_stone(nearest)
		"resonator":
			_touch_resonator(nearest)
		"chime":
			_ring_chime(nearest)
		"gate":
			var gate_text := (
				"stands open" if state.gate_open else "is still sealed by dormant resonators"
			)
			_flash("The gate %s." % gate_text)
		"artifact":
			_finish_run("extracted", "artifact", _build_artifact_id())
		"pool":
			_finish_run("transformed", "transformation", _build_transformation_id())

func _use_lore_stone(object_data: Dictionary) -> void:
	var clue_index := int(object_data.get("clue_index", 0))
	var clue := lore_clues[int(clamp(clue_index, 0, lore_clues.size() - 1))]
	state.update_object(str(object_data["id"]), {"used": true})
	_add_clue(clue, "lore_%d" % clue_index)
	telemetry.log_event("lore_stone_used", {"id": object_data["id"]})
	_flash("A stable clue settles into your notes.")

func _touch_resonator(object_data: Dictionary) -> void:
	journal.record_experiment("presence", "You pressed directly into a resonator.")
	telemetry.log_event("experiment", {"kind": "presence", "object_id": object_data["id"]})
	if resolver.get_transformation_method() != "presence":
		_flash("The resonator trembles, but your touch is not the missing piece.")
		return
	if not _player_on_favored_terrain():
		_add_clue(
			"Direct contact only seems promising when you stand on terrain the world favors.",
			"presence_needs_favored"
		)
		_flash("The contact fizzles. The ground beneath you feels wrong.")
		return
	_charge_resonator(str(object_data["id"]), "presence")

func _ring_chime(object_data: Dictionary) -> void:
	state.update_object(str(object_data["id"]), {"active_timer": 5.0})
	journal.record_experiment("chime", "A bell rang through the chamber.")
	telemetry.log_event("experiment", {"kind": "chime", "object_id": object_data["id"]})
	if resolver.get_transformation_method() != "chime":
		_flash("Creatures react, but the nearby resonator stays dormant.")
		return
	if not _player_on_favored_terrain():
		_add_clue(
			"The bell seems potent only when rung from terrain the world favors.",
			"chime_needs_favored"
		)
		_flash("The note dies thinly. The ground is resisting you.")
		return
	_charge_resonator(str(object_data.get("linked_resonator_id", "")), "chime")

func _charge_resonator(object_id: String, source: String) -> void:
	if object_id.is_empty():
		return
	if not state.charge_resonator(object_id):
		_flash("That resonator is already awake.")
		return
	telemetry.log_event(
		"resonator_charged",
		{"object_id": object_id, "source": source, "charged": state.charged_resonators}
	)
	_flash("A resonator wakes. %d of 3 now answer your theory." % state.charged_resonators)
	if state.gate_open:
		telemetry.log_event("gate_opened", {})
		_add_clue("All three resonators now agree. The inner gate has opened.", "gate_opened")

func _player_on_favored_terrain() -> bool:
	var cell := state.world_to_grid(player.position)
	return resolver.is_favored_affinity(state.get_affinity(cell))

func _get_nearest_object() -> Dictionary:
	var best_distance := 42.0
	var best: Dictionary = {}
	for object_data in state.objects:
		var object_position := state.grid_to_world(Vector2i(object_data["position"]))
		var distance := player.position.distance_to(object_position)
		if distance < best_distance:
			best_distance = distance
			best = object_data
	return best

func _update_ui() -> void:
	var player_cell := state.world_to_grid(player.position)
	var terrain_name := resolver.get_affinity_display(state.get_affinity(player_cell))
	status_label.text = (
		"[b]Objective[/b]\n%s\n\n[b]Status[/b]\n"
		+ "Health: %d   Attunement: %d   Terrain: %s   Resonators: %d / 3\n%s"
	) % [
		resolver.get_objective_text(),
		int(player.health),
		int(player.attunement),
		terrain_name,
		state.charged_resonators,
		resolver.get_control_hint()
	]
	journal_label.text = journal.build_text(state)
	interaction_label.text = _build_interaction_hint()

func _build_interaction_hint() -> String:
	var nearest := _get_nearest_object()
	if nearest.is_empty():
		return "Explore the chamber. Look for terrain patterns, creature habits, and linked devices."
	var template: ObjectTemplate = nearest.get("template") as ObjectTemplate
	var nearby_title := template.title if template != null else str(nearest.get("type", "object"))
	return "Nearby: %s. Press E to interact." % nearby_title

func _add_clue(text: String, key: String) -> void:
	if journal.record_clue(text, key):
		telemetry.log_event("clue_discovered", {"key": key, "text": text})

func _flash(text: String) -> void:
	flash_label.text = text
	flash_timer = 4.0

func _update_flash(delta: float) -> void:
	if flash_timer <= 0.0:
		return
	flash_timer = max(0.0, flash_timer - delta)
	if flash_timer == 0.0:
		flash_label.text = ""

func slide_body(current_position: Vector2, motion: Vector2, radius: float) -> Vector2:
	var result := current_position
	var x_step := Vector2(motion.x, 0.0)
	var y_step := Vector2(0.0, motion.y)
	if _circle_walkable(result + x_step, radius):
		result += x_step
	if _circle_walkable(result + y_step, radius):
		result += y_step
	return result

func _circle_walkable(center: Vector2, radius: float) -> bool:
	var sample_offsets := [
		Vector2(-radius, -radius),
		Vector2(radius, -radius),
		Vector2(-radius, radius),
		Vector2(radius, radius)
	]
	for offset in sample_offsets:
		if not state.is_walkable(state.world_to_grid(center + offset)):
			return false
	return true

func _build_artifact_id() -> String:
	return "%s_archive_seed" % resolver.get_favored_affinity()

func _build_transformation_id() -> String:
	return "%s_%s_shape" % [resolver.get_favored_affinity(), resolver.get_transformation_method()]

func _finish_run(reason: String, reward_kind: String = "", reward_id: String = "") -> void:
	state.run_complete = true
	state.finish_reason = reason
	state.reward_kind = reward_kind
	state.reward_id = reward_id

	var summary := telemetry.finalize(state, journal, resolver)
	summary["artifact_id"] = reward_id if reward_kind == "artifact" else ""
	summary["transformation_id"] = reward_id if reward_kind == "transformation" else ""
	summary["knowledge"] = resolver.describe_truths()

	ExtractionManager.record_run_outcome(summary)

	var hub = META_HUB_SCENE.instantiate()
	get_tree().root.add_child(hub)
	get_tree().current_scene = hub
	queue_free()
