extends SceneTree

func _initialize() -> void:
	var scene = load("res://scenes/RunWorld.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame

	assert(scene.state != null)
	assert(scene.player != null)
	assert(scene.world_view != null)
	assert(scene.camera != null)
	assert(scene.state.get_objects_by_type("resonator").size() == 3)

	scene._finish_run("perished")
	await process_frame
	assert(get_current_scene() != null)
	assert(get_current_scene().start_button != null)

	get_current_scene().queue_free()
	await process_frame
	print("run_world_scene_smoke_test passed")
	quit()
