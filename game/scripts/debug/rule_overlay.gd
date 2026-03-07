class_name RuleOverlay
extends Control

var run_world: Node
var label := RichTextLabel.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	offset_left = 910
	offset_top = 16
	offset_right = 1248
	offset_bottom = 220

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 10
	label.offset_top = 10
	label.offset_right = -10
	label.offset_bottom = -10
	label.bbcode_enabled = false
	label.fit_content = true
	panel.add_child(label)

	visible = false

func refresh() -> void:
	if not visible or run_world == null or run_world.resolver == null:
		return
	var resolver: RuleResolver = run_world.resolver
	label.text = (
		"DEBUG RULES\n\nPhysical: %s\nEcology: %s\nResonator Rule: %s\n"
		+ "Favored Terrain: %s\nSeed: %d"
	) % [
		resolver.get_rule("physical").title,
		resolver.get_rule("ecology").title,
		resolver.get_rule("transformation").title,
		resolver.get_affinity_display(resolver.get_favored_affinity()),
		run_world.state.seed
	]
