extends Control

const RUN_WORLD_SCENE_PATH := "res://scenes/RunWorld.tscn"

var summary_label := RichTextLabel.new()
var progress_label := RichTextLabel.new()
var start_button := Button.new()

func _ready() -> void:
	_build_ui()
	_refresh()

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.06, 0.07, 0.1)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(820, 560)
	center.add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(root)

	var title := Label.new()
	title.text = "DEEPER LEVEL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "A replayable exploration prototype about discovering how each world works."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(subtitle)

	progress_label.fit_content = true
	progress_label.bbcode_enabled = true
	progress_label.custom_minimum_size = Vector2(780, 170)
	root.add_child(progress_label)

	summary_label.fit_content = true
	summary_label.bbcode_enabled = true
	summary_label.custom_minimum_size = Vector2(780, 190)
	root.add_child(summary_label)

	start_button.text = "Start A New Run"
	start_button.custom_minimum_size = Vector2(0, 48)
	start_button.pressed.connect(_start_run)
	root.add_child(start_button)

	var footer := Label.new()
	footer.text = "Prototype goal: notice the rules, enjoy discovering them, and want another run."
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(footer)

func _refresh() -> void:
	var meta := ExtractionManager.get_meta_state()
	progress_label.text = (
		"[b]Meta Progress[/b]\nArtifacts extracted: %d\nTransformations earned: %d\n"
		+ "Knowledge facts archived: %d\nCompleted runs: %d\nImmediate replays this session: %d"
	) % [
		meta.get("artifacts", []).size(),
		meta.get("transformations", []).size(),
		meta.get("knowledge", []).size(),
		int(meta.get("completed_runs", 0)),
		int(meta.get("immediate_replays", 0))
	]

	var summary: Dictionary = meta.get("last_run_summary", {})
	if summary.is_empty():
		summary_label.text = (
			"[b]Last Run[/b]\n"
			+ "No expedition yet. Start a run and infer what this world values."
		)
		return

	summary_label.text = (
		"[b]Last Run[/b]\nSeed: %s\nResult: %s\nCorrect terrain guess: %s\n"
		+ "Correct resonator guess: %s\nExperiments attempted: %s\nReward: %s\n"
		+ "\n[b]Archived truths[/b]\n%s"
	) % [
		str(summary.get("seed", "-")),
		str(summary.get("finish_reason", "unknown")).capitalize(),
		"yes" if bool(summary.get("correct_affinity_guess", false)) else "no",
		"yes" if bool(summary.get("correct_transformation_guess", false)) else "no",
		str(summary.get("experiments_attempted", 0)),
		_summary_reward(summary),
		"\n".join(Array(summary.get("knowledge", [])))
	]

func _summary_reward(summary: Dictionary) -> String:
	if str(summary.get("artifact_id", "")).length() > 0:
		return "Artifact: %s" % summary["artifact_id"]
	if str(summary.get("transformation_id", "")).length() > 0:
		return "Transformation: %s" % summary["transformation_id"]
	return "None"

func _start_run() -> void:
	ExtractionManager.note_run_started()
	var run_world_scene := load(RUN_WORLD_SCENE_PATH) as PackedScene
	if run_world_scene == null:
		push_error("Failed to load run world scene.")
		return
	var run_world = run_world_scene.instantiate()
	run_world.run_seed = int(Time.get_unix_time_from_system()) + randi()
	get_tree().root.add_child(run_world)
	get_tree().current_scene = run_world
	queue_free()
