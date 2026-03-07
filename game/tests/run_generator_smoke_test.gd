extends SceneTree

func _initialize() -> void:
	var generator := RunGenerator.new()
	var payload := generator.generate(12345)
	var state: WorldState = payload["state"]
	var bundle: Dictionary = payload["bundle"]

	assert(state.get_objects_by_type("resonator").size() == 3)
	assert(state.get_objects_by_type("chime").size() == 3)
	assert(state.get_object_by_type("gate").is_empty() == false)
	assert(bundle["physical"].favored_affinity == bundle["ecology"].favored_affinity)
	assert(state.creatures.size() == 3)

	print("run_generator_smoke_test passed")
	quit()
