extends SceneTree

func _initialize() -> void:
	var scene = load("res://scenes/MetaHub.tscn").instantiate()
	root.add_child(scene)
	await process_frame

	assert(scene.start_button != null)
	assert(scene.start_button.text == "Start A New Run")

	scene.queue_free()
	await process_frame
	print("meta_hub_scene_smoke_test passed")
	quit()
