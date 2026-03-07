class_name DiscoveryJournal
extends RefCounted

var clues: Array[String] = []
var clue_keys: Dictionary = {}
var experiments: Dictionary = {}
var affinity_guess: String = ""
var transformation_guess: String = ""
var first_hypothesis_time_ms: int = -1

func seed_initial_clues(lines: Array[String]) -> void:
	for line in lines:
		record_clue(line)

func record_clue(text: String, key: String = "") -> bool:
	if text.is_empty():
		return false
	var dedupe_key := key
	if dedupe_key.is_empty():
		dedupe_key = text
	if clue_keys.has(dedupe_key):
		return false
	clue_keys[dedupe_key] = true
	clues.append(text)
	if clues.size() > 12:
		clues = clues.slice(clues.size() - 12, clues.size())
	return true

func record_experiment(tag: String, text: String = "") -> void:
	experiments[tag] = int(experiments.get(tag, 0)) + 1
	if not text.is_empty():
		record_clue(text, "experiment:%s:%s" % [tag, text])

func set_affinity_guess(guess: String) -> void:
	affinity_guess = guess
	_mark_hypothesis_time()

func set_transformation_guess(guess: String) -> void:
	transformation_guess = guess
	_mark_hypothesis_time()

func _mark_hypothesis_time() -> void:
	if first_hypothesis_time_ms == -1:
		first_hypothesis_time_ms = Time.get_ticks_msec()

func build_text(world_state: WorldState) -> String:
	var lines: Array[String] = []
	lines.append("DISCOVERY JOURNAL")
	lines.append("")
	lines.append("Terrain guess: %s" % _display_affinity_guess())
	lines.append("Resonator guess: %s" % _display_transformation_guess())
	lines.append(
		"Charged resonators: %d / %d"
		% [world_state.charged_resonators, world_state.get_objects_by_type("resonator").size()]
	)
	lines.append("")
	lines.append("Recent clues:")
	for clue in clues:
		lines.append("- %s" % clue)
	return "\n".join(lines)

func _display_affinity_guess() -> String:
	match affinity_guess:
		"sol":
			return "Light"
		"gloom":
			return "Shadow"
		_:
			return "No hypothesis yet"

func _display_transformation_guess() -> String:
	match transformation_guess:
		"presence":
			return "Touch resonators"
		"chime":
			return "Ring linked chimes"
		"creature":
			return "Lure creatures into resonators"
		_:
			return "No hypothesis yet"
