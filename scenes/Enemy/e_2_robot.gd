extends CharacterBody2D

# -------------- STATS --------------
@export var max_hp = 82.0
var current_hp = 100.0
@export var speed = 450.0
@export var attack_power = 22.0
@export var attack_range = 300.0
@export var attack_duration = 0.5

var frozen = false
var current_state = "IDLE"

const gravity = 2000.0

@onready var anim = $AnimatedSprite2D
@onready var hp_bar = $HealthBar
var player = null

func slash(dmg):
	if frozen:
		return
	current_state = "ATTACK"
	
	# 1. WINDUP: 0.2 seconds
	await get_tree().create_timer(0.1).timeout
	
	anim.play("slash")
	# 2. STRIKE: Turn monitoring ON. 
	# This instantly detects the player and fires the _on_hitbox_body_entered signal!
	$Hitbox.set_deferred("monitoring", true)
	
	# 3. ACTIVE FRAMES: Keep it dangerous for 0.1 seconds
	await get_tree().create_timer(0.4).timeout
	
	# 4. RECOVERY: Turn monitoring OFF so it stops dealing damage
	$Hitbox.set_deferred("monitoring", false)
	anim.play("idle")
	
	# 5. Wait for the animation to finish
	await get_tree().create_timer(attack_duration).timeout
	
	if player != null:
		current_state = "CHASE" 
	else:
		current_state = "IDLE"

# Make sure your signal function looks like this (no changes needed here, just a reminder):
func _on_hitbox_body_entered(body):
	if frozen:
		return
	if body.is_in_group("Player"):
		if body.has_method("take_damage"):
			body.take_damage(attack_power)

func _on_detection_area_body_entered(body):
	if frozen:
		return
	# When something enters the circle, check if it's the player
	if body.is_in_group("Player"):
		player = body
		current_state = "CHASE"
		print("Target acquired! Chasing.")

func _on_detection_area_body_exited(body):
	if frozen:
		return
	# When something leaves the circle, check if it's the player we were chasing
	if body == player:
		player = null
		current_state = "IDLE"
		print("Target lost. Returning to idle.")

func _ready():
	$TechRobot.visible	 = false
	anim.play("idle")
	hp_bar.value = current_hp
	
	# Connect the signals via code (you can also do this in the editor interface)
	$DetectionArea.body_entered.connect(_on_detection_area_body_entered)
	$DetectionArea.body_exited.connect(_on_detection_area_body_exited)
	$Hitbox.body_entered.connect(_on_hitbox_body_entered)
	
	# NEW: Turn the Hitbox off via code as soon as the robot spawns
	$Hitbox.monitoring = false
	
func take_damage(damage):
	current_hp -= damage
	hp_bar.value = current_hp
	modulate = Color(10, 10, 10, 1)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1, 1)

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
	tween.tween_property(anim, "modulate:a", 0.0, 0.5)
	
	await tween.finished
	# Optional: Delete the object automatically when finished
	tween.chain().kill() # Stops the tween
	tween.finished.connect(queue_free)
	
	$Boom.transform = original_transform
	$Boom.modulate.a = 1.0
	$Boom.visible = false
	# await get_tree().create_timer(0.5).timeout
	
	queue_free() # DEAD

func _physics_process(delta: float) -> void:
	# Chasing
	match current_state:
		"IDLE":
			velocity = velocity.move_toward(Vector2.ZERO, speed * delta)
			anim.play("idle")
			
		"CHASE":
			anim.play("idle")
			if player != null:
				var distance = global_position.distance_to(player.global_position)
				
				if distance <= attack_range:
					velocity.x = 0 # STOP horizontal movement to attack
					slash(attack_power)
				else:
					var direction = global_position.direction_to(player.global_position)
					# Only care about left/right
					if direction.x > 0:
						anim.flip_h = true
						velocity.x = speed
					else:
						anim.flip_h = false
						velocity.x = -speed
			else:
				velocity.x = 0 # STOP if player is gone
					
		"ATTACK":
			# 2. Stop moving while attacking so we don't slide into the player
			velocity = Vector2.ZERO

	# Falling Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Death Condition
	if current_hp <= 0.0:
		die()
	
	move_and_slide()
	
	
	
