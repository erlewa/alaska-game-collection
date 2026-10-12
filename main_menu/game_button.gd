extends Button

@export var game_name: String
@export var game_scene: PackedScene
@export var thumbnail_image: Texture2D
@export var description: String

@onready var tooltip: Control = %Tooltip
@onready var thumbnail: TextureRect = %Thumbnail
@onready var game_description: Label = %Description

func _ready() -> void:
	text = game_name
	thumbnail.texture = thumbnail_image
	game_description.text = description

func _on_mouse_entered() -> void:
	tooltip.visible = true


func _on_mouse_exited() -> void:
	tooltip.visible = false

func _on_pressed() -> void:
	get_tree().change_scene_to_packed(game_scene)
