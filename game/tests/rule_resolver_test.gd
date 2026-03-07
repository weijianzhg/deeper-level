extends SceneTree

func _initialize() -> void:
	var resolver := RuleResolver.new({
		"physical": load("res://data/rules/sunlit_tides.tres"),
		"ecology": load("res://data/rules/sol_foragers.tres"),
		"transformation": load("res://data/rules/chime_attunement.tres")
	})

	assert(resolver.get_favored_affinity() == "sol")
	assert(resolver.is_correct_affinity_guess("sol"))
	assert(resolver.is_correct_transformation_guess("chime"))
	assert(resolver.get_player_speed_multiplier("sol") > resolver.get_player_speed_multiplier("gloom"))

	print("rule_resolver_test passed")
	quit()
