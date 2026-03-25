extends CharacterBody2D

# -------------- STATS --------------
@export var max_hp = 100.0
var current_hp = 100.0
@export var speed = 250.0
@export var attack_power = 22.0
@export var attack_range = 300.0
@export var attack_duration = 0.5

var current_state = "IDLE"

const gravity = 2000.0

@onready var anim = $AnimatedSprite2D
@onready var hp_bar = $HealthBar
var player = null

func slash(dmg):
	current_state = "ATTACK"
	
	# 1. WINDUP: 0.2 seconds
	await get_tree().create_timer(0.3).timeout
	
	anim.play("slash")
	# 2. STRIKE: Turn monitoring ON. 
	# This instantly detects the player and fires the _on_hitbox_body_entered signal!
	$Hitbox.set_deferred("monitoring", true)
	
	# 3. ACTIVE FRAMES: Keep it dangerous for 0.1 seconds
	await get_tree().create_timer(0.3).timeout
	
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
	if body.is_in_group("Player"):
		if body.has_method("take_damage"):
			body.take_damage(attack_power)

func _on_detection_area_body_entered(body):
	# When something enters the circle, check if it's the player
	if body.is_in_group("Player"):
		player = body
		current_state = "CHASE"
		print("Target acquired! Chasing.")

func _on_detection_area_body_exited(body):
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

func _physics_process(delta: float) -> void:
	# Chasing
	match current_state:
		"IDLE":
			velocity = velocity.move_toward(Vector2.ZERO, speed * delta)
			anim.play("idle")
			
		"CHASE":
			anim.play("idle")
			if player != null:
				# 1. Check if we are close enough to attack!
				var distance = global_position.distance_to(player.global_position)
				
				if distance <= attack_range:
					slash(attack_power) # Trigger the attack
				else:
					# Otherwise, keep moving toward the player
					var direction = global_position.direction_to(player.global_position)
					velocity = direction * speed
					
		"ATTACK":
			# 2. Stop moving while attacking so we don't slide into the player
			velocity = Vector2.ZERO

	# Falling Gravity
	if not is_on_floor():
		if is_on_wall() and velocity.y > 0:
			velocity.y = 50
		else:
			velocity.y += gravity * delta
	
	# Death Condition
	if current_hp <= 0.0:
		queue_free() # DEAD
	
	move_and_slide()
	
	
	
