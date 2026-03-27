extends CharacterBody2D

@export var bullet_scene: PackedScene # Drag your HomingBullet.tscn here in the inspector
@export var fire_rate: float = 1.5    # How often the drone shoots (in seconds)
@export var max_health = 55.0

var frozen = false
var current_hp = 55.0
var current_target = null
@onready var drone = $TechDrone
@onready var shoot_timer: Timer = $ShootTimer
@onready var shoot_point: Marker2D = $ShootPoint
@onready var hp_bar = $HealthBar

func _ready() -> void:
	drone.play("default")
	drone.scale = Vector2(1,1)
	shoot_timer.wait_time = fire_rate
	hp_bar.max_value = max_health
	hp_bar.value = current_hp

func _on_detection_zone_body_entered(body):
	if frozen:
		return
	# Check if the body entering the zone is the player
	if body.is_in_group("Player"):
		print('Found you!')
		current_target = body
		shoot_timer.start() # Begin firing sequence

func _on_detection_zone_body_exited(body):
	if frozen:
		return
	# Stop shooting if the player leaves the radius
	if body == current_target:
		current_target = null
		shoot_timer.stop()

func _on_shoot_timer_timeout() -> void:
	if frozen:
		return
	# Fired every time the timer completes its countdown
	if is_instance_valid(current_target) and bullet_scene:
		shoot()

func shoot() -> void:
	if frozen:
		return
	drone.play("new_animation")
	drone.scale = Vector2(0.35,0.35)
	var bullet = bullet_scene.instantiate()
	
	# Spawn the bullet at the Marker2D's position
	bullet.global_position = shoot_point.global_position
	
	# Pass the player reference to the bullet so it knows what to chase
	bullet.target = current_target
	
	# Add the bullet to the main scene tree (not as a child of the drone, 
	# otherwise it will move if the drone moves)
	get_tree().current_scene.add_child(bullet)
	await get_tree().create_timer(0.2).timeout
	drone.play("default")
	drone.scale = Vector2(1,1)

func die():
	frozen = true
	var original_transform = $Boom.transform
	$Boom.visible = true

	var tween = create_tween()
	
	# Set the parallel mode so both animations happen at the same time
	tween.set_parallel(true)
	
	# 1. Enlarge: Scale from current size to 3x over 1.5 seconds
	tween.tween_property($Boom, "scale", Vector2(0.2, 0.2), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 2. Fade Away: Change alpha to 0 over 1.5 seconds
	tween.tween_property($Boom, "modulate:a", 0.0, 0.5)
	tween.tween_property(drone, "modulate:a", 0.0, 0.5)
	
	await tween.finished
	# Optional: Delete the object automatically when finished
	tween.chain().kill() # Stops the tween
	tween.finished.connect(queue_free)
	
	$Boom.transform = original_transform
	$Boom.modulate.a = 1.0
	$Boom.visible = false
	
	# await get_tree().create_timer(0.5).timeout
	
	queue_free() # DEAD

func take_damage(damage):
	current_hp -= damage
	hp_bar.value = current_hp
	modulate = Color(10, 10, 10, 1)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1, 1)
	if current_hp <= 0:
		die()
