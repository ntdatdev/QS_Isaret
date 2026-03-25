extends Control

var started = false

func _on_start_button_pressed() -> void:
	# Create a Tween object (Godot 4 syntax)
	if not started:
		started = true
		var tween = get_tree().create_tween()
		
		# Animate the "modulate" property to be transparent
		# Arguments: (Property, Target Value, Duration in seconds)
		tween.tween_property(self, "modulate", Color(0, 0, 0, 255.0), 2.0)
		await get_tree().create_timer(2.0).timeout
		
		get_tree().change_scene_to_file("res://scenes/INTRO_CUTSCENE.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
