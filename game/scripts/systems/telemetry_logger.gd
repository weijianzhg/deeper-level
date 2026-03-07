class_name TelemetryLogger
extends RefCounted

var run_id: String = ""
var seed: int = 0
var started_at_ms: int = 0
var file_path: String = ""
var session_file_path: String = "user://playtest_session.jsonl"

func _init(run_seed: int) -> void:
	seed = run_seed
	started_at_ms = Time.get_ticks_msec()
	run_id = "%d_%d" % [seed, started_at_ms]
	file_path = "user://telemetry_%s.jsonl" % run_id
	log_event("run_started", {"seed": seed})

func log_event(name: String, payload: Dictionary = {}) -> void:
	var line := {
		"run_id": run_id,
		"seed": seed,
		"event": name,
		"at_ms": Time.get_ticks_msec() - started_at_ms,
		"payload": payload
	}
	_append_json_line(file_path, line)
	_append_json_line(session_file_path, line)

func finalize(
	world_state: WorldState,
	journal: DiscoveryJournal,
	resolver: RuleResolver
) -> Dictionary:
	var experiment_total := 0
	for value in journal.experiments.values():
		experiment_total += int(value)
	var summary := {
		"seed": seed,
		"duration_s": snapped(float(Time.get_ticks_msec() - started_at_ms) / 1000.0, 0.1),
		"experiments_attempted": experiment_total,
		"unique_experiments": journal.experiments.size(),
		"correct_affinity_guess": resolver.is_correct_affinity_guess(journal.affinity_guess),
		"correct_transformation_guess":
			resolver.is_correct_transformation_guess(journal.transformation_guess),
		"charged_resonators": world_state.charged_resonators,
		"reward_kind": world_state.reward_kind,
		"reward_id": world_state.reward_id,
		"finish_reason": world_state.finish_reason
	}
	log_event("run_finished", summary)
	return summary

func _append_json_line(target_path: String, data: Dictionary) -> void:
	var mode := FileAccess.READ_WRITE if FileAccess.file_exists(target_path) else FileAccess.WRITE
	var file := FileAccess.open(target_path, mode)
	if file == null:
		return
	file.seek_end()
	file.store_line(JSON.stringify(data))
	file.close()
