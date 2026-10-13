extends Button

@export var game_name: String
@export var game_scene: PackedScene
@export var thumbnail_image: Texture2D
@export var description: String
@export var padding: int = 3

@onready var tooltip: PanelContainer = %Tooltip
@onready var v_box_container: VBoxContainer = %VBoxContainer
@onready var thumbnail: TextureRect = %Thumbnail
@onready var game_description: Label = %Description



func _ready() -> void:
	text = game_name
	thumbnail.texture = thumbnail_image
	game_description.text = description
	tooltip.visible = false

func _on_mouse_entered() -> void:
	tooltip.visible = true


func _on_mouse_exited() -> void:
	tooltip.visible = false

func _on_pressed() -> void:
	get_tree().change_scene_to_packed(game_scene)
