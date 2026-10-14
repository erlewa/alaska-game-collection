# Back button script
extends Button

func _on_pressed() -> void:
	# get_tree().quit() # EXIT GAME for now. FIXME: load up main map scene
	get_tree().change_scene_to_file("res://main_menu/main.tscn")
