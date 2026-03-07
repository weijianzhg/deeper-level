## gdlint: disable=max-public-methods
class_name RuleResolver
extends RefCounted

const AFFINITY_DISPLAY := {
	"sol": "Light",
	"gloom": "Shadow",
	"neutral": "Neutral"
}

var bundle: Dictionary = {}

func _init(rule_bundle: Dictionary = {}) -> void:
	bundle = rule_bundle

func get_rule(domain: String) -> RuleModule:
	return bundle.get(domain) as RuleModule

func get_favored_affinity() -> String:
	var physical_rule := get_rule("physical")
	if physical_rule == null:
		return "neutral"
	return physical_rule.favored_affinity

func get_affinity_display(affinity: String) -> String:
	return str(AFFINITY_DISPLAY.get(affinity, affinity.capitalize()))

func is_favored_affinity(affinity: String) -> bool:
	return affinity == get_favored_affinity()

func get_player_speed_multiplier(affinity: String) -> float:
	if affinity == "neutral":
		return 1.0
	if is_favored_affinity(affinity):
		return 1.22
	return 0.82

func get_attunement_delta(affinity: String, delta: float) -> float:
	if affinity == "neutral":
		return -6.0 * delta
	if is_favored_affinity(affinity):
		return 18.0 * delta
	return -20.0 * delta

func get_health_delta(attunement: float, delta: float) -> float:
	if attunement >= 25.0:
		return min(0.0, 4.0 * delta)
	return -10.0 * delta

func get_objective_text() -> String:
	return (
		"Infer the world's favored terrain and how resonators accept charge. "
		+ "Wake all 3 resonators, enter the deeper chamber, then extract an "
		+ "Archive Seed or return transformed."
	)

func get_control_hint() -> String:
	return (
		"Move: WASD or arrows | Interact: E | Guess terrain: 1/2 | "
		+ "Guess resonator rule: 7/8/9 | Toggle debug: F3"
	)

func get_affinity_clue() -> String:
	var physical_rule := get_rule("physical")
	if physical_rule == null:
		return ""
	return physical_rule.clue_text

func get_ecology_clue() -> String:
	var ecology_rule := get_rule("ecology")
	if ecology_rule == null:
		return ""
	return ecology_rule.clue_text

func get_transformation_clue() -> String:
	var transformation_rule := get_rule("transformation")
	if transformation_rule == null:
		return ""
	return transformation_rule.clue_text

func get_hypothesis_options() -> Dictionary:
	return {
		"affinity": {"1": "Light", "2": "Shadow"},
		"transformation": {
			"7": "Touch resonators",
			"8": "Ring linked chimes",
			"9": "Lure creatures into the rings"
		}
	}

func get_transformation_method() -> String:
	var transformation_rule := get_rule("transformation")
	if transformation_rule == null:
		return "presence"
	return transformation_rule.experiment_tag

func get_transformation_display() -> String:
	match get_transformation_method():
		"presence":
			return "Touch resonators while standing on favored terrain"
		"chime":
			return "Ring linked chimes while standing on favored terrain"
		"creature":
			return "Lure creatures into resonator rings on favored terrain"
		_:
			return "Unknown"

func get_creature_affinity() -> String:
	var ecology_rule := get_rule("ecology")
	if ecology_rule == null:
		return get_favored_affinity()
	return ecology_rule.favored_affinity

func get_starting_clues() -> Array[String]:
	var clues: Array[String] = []
	clues.append(
		"This run has hidden rules. Record what the terrain, creatures, and resonators seem to prefer."
	)
	clues.append(
		"Three resonators seal the deeper chamber. Only one kind of experiment will wake them."
	)
	return clues

func get_lore_stone_clues() -> Array[String]:
	return [
		get_affinity_clue(),
		get_ecology_clue(),
		get_transformation_clue()
	]

func get_observables() -> Array[String]:
	var results: Array[String] = []
	for domain in ["physical", "ecology", "transformation"]:
		var rule := get_rule(domain)
		if rule == null:
			continue
		for item in rule.observables:
			results.append(item)
	return results

func is_correct_affinity_guess(guess: String) -> bool:
	return guess == get_favored_affinity()

func is_correct_transformation_guess(guess: String) -> bool:
	return guess == get_transformation_method()

func describe_truths() -> Array[String]:
	return [
		"Favored terrain: %s" % get_affinity_display(get_favored_affinity()),
		"Creature behavior: %s terrain attracts them."
		% get_affinity_display(get_creature_affinity()),
		"Resonators wake through: %s" % get_transformation_display()
	]
