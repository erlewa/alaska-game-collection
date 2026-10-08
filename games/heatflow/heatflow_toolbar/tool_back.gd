# Back button script
extends Button

func _on_pressed() -> void:
	get_tree().quit() # EXIT GAME for now. FIXME: load up main map scene

# Demo of how to read the current tool
#@export var tool_group: ButtonGroup  # hook up in Inspector
#func _physics_process(delta: float) -> void:
#	var tool = tool_group.get_pressed_button()
#	if (tool):
#		print("Tool: ",tool.name)
