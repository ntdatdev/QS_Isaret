extends Area2D

# --- CAMERA SETTINGS ---
# The exact center of your boss room where the camera should lock
var boss_entered = false
@export var arena_center := Vector2(4750, 12700) 
@export var target_zoom := Vector2(0.27, 0.27) 
@export var transition_duration: float = 2.0 

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		boss_entered = true
		var camera = body.get_node("Camera2D")
		
		if camera:
			print("Player entered! Locking camera to arena...")
			
			# --- THE FIX ---
			# 1. Save the exact current world position of the camera
			var start_pos = camera.global_position
			
			# 2. Detach from player (this is what normally breaks it)
			camera.top_level = true 
			
			# 3. Instantly force it back to where it just was before the Tween starts!
			camera.global_position = start_pos
			# ---------------
			
			# CREATE A PARALLEL TWEEN:
			var tween = create_tween().set_parallel(true)
			
			# Smoothly slide the camera to the center of the room
			tween.tween_property(camera, "global_position", arena_center, transition_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			
			# Smoothly zoom the camera out
			tween.tween_property(camera, "zoom", target_zoom, transition_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			
			# Turn off this trigger so it doesn't fire again
			$CollisionShape2D.set_deferred("disabled", true)
			
		else:
			print("Error: Could not find Camera2D on the Player!")
