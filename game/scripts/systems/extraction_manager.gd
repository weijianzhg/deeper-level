extends Node

const SAVE_PATH := "user://meta_save.json"

var meta_state: Dictionary = {
	"artifacts": [],
	"transformations": [],
	"knowledge": [],
	"completed_runs": 0,
	"immediate_replays": 0,
	"last_run_summary": {},
	"pending_replay_evaluation": false
}

func _ready() -> void:
	load_state()

func load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		for key in meta_state.keys():
			if parsed.has(key):
				meta_state[key] = parsed[key]

func save_state() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(meta_state, "\t"))
	file.close()

func note_run_started() -> void:
	if bool(meta_state.get("pending_replay_evaluation", false)):
		meta_state["immediate_replays"] = int(meta_state.get("immediate_replays", 0)) + 1
		meta_state["pending_replay_evaluation"] = false
	save_state()

func record_run_outcome(summary: Dictionary) -> void:
	meta_state["completed_runs"] = int(meta_state.get("completed_runs", 0)) + 1
	meta_state["last_run_summary"] = summary
	meta_state["pending_replay_evaluation"] = true

	var artifacts: Array = meta_state.get("artifacts", [])
	var transformations: Array = meta_state.get("transformations", [])
	var knowledge: Array = meta_state.get("knowledge", [])

	if str(summary.get("artifact_id", "")).length() > 0 and not artifacts.has(summary["artifact_id"]):
		artifacts.append(summary["artifact_id"])
	if str(summary.get("transformation_id", "")).length() > 0 \
			and not transformations.has(summary["transformation_id"]):
		transformations.append(summary["transformation_id"])
	for fact in summary.get("knowledge", []):
		if not knowledge.has(fact):
			knowledge.append(fact)

	meta_state["artifacts"] = artifacts
	meta_state["transformations"] = transformations
	meta_state["knowledge"] = knowledge
	save_state()

func get_meta_state() -> Dictionary:
	return meta_state.duplicate(true)

func dismiss_replay_prompt() -> void:
	meta_state["pending_replay_evaluation"] = false
	save_state()
