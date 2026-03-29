extends Control
@export var next_scene_path: String = "res://scenes/MAIN_SCENE.tscn"

func _ready():
	var tween = create_tween()
	
	tween.tween_property($Fade, "modulate:a", 0, 1)

func _input(event):
	# Allow the player to skip the intro by pressing Enter, Space, or Escape
	# (Assuming these are mapped to "ui_accept" and "ui_cancel" in Project Settings)
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		go_to_next_scene()
	
	# Alternatively, allow skipping with a left mouse click
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		go_to_next_scene()

func go_to_next_scene():
	# A helper function to handle the transition safely
	if next_scene_path != "":
		get_tree().change_scene_to_file(next_scene_path)
	else:
		print("Error: Next scene path is not set in the Inspector!")
