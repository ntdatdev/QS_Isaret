extends CharacterBody2D

@onready var accept_boss = $AcceptBoss
@onready var boss_death = $BossDeath
@onready var boss_monologue = $BossMonologue

@export var max_health: float = 1000.0
@export var speed = 1000.0
@export var bullet_scene: PackedScene

@export var fixed_x: float = 6300.0 # The fixed horizontal line the boss stays on
@export var min_y: float = 12000.0  # The highest point on the screen it can go
@export var max_y: float = 13000.0  # The lowest point on the screen it can go

var ON = false

var is_choosing_skill = false
var idle_timer: float = 3.0
var current_hp = 1000.0
var vulnerable = false
var time_passed = 0.0
var i = 0

@onready var original_transform = $AnimatedSprite2D.transform
var FIREBALL = false
var BULLET_RAIN = false
var LAVA_FLOOR = false
var LAVA_FLOOR_ON = false
var TVRAM = false


var ramming = false
var is_aiming = false
var aim_timer = 0.0
var charge_direction := Vector2.ZERO # Store the direction to charge
@onready var HP = $CanvasLayer/hpBar
func hide_ui():
	$CanvasLayer.visible = false

func play_accept_boss():
	accept_boss.play()
func stop_accept_boss():
	accept_boss.stop()

func play_boss_death():
	boss_death.play()
func stop_boss_death():
	boss_death.stop()

func play_boss_monologue():
	boss_monologue.play()
func stop_boss_monologue():
	boss_monologue.stop()

func fireball():
	$AnimatedSprite2D.visible = true

	var tween = create_tween()
	
	# Set the parallel mode so both animations happen at the same time
	tween.set_parallel(true)
	
	# 1. Enlarge: Scale from current size to 3x over 1.5 seconds
	tween.tween_property($AnimatedSprite2D, "scale", Vector2(2, 2), 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 2. Fade Away: Change alpha to 0 over 1.5 seconds
	tween.tween_property($AnimatedSprite2D, "modulate:a", 1.0, 1.5)
	
	await tween.finished
	# Optional: Delete the object automatically when finished
	tween.chain().kill() # Stops the tween
	tween.finished.connect(queue_free)
	
	$AnimatedSprite2D.transform = original_transform
	$AnimatedSprite2D.modulate.a = 0.0
	$AnimatedSprite2D.visible = false
	var fireball = bullet_scene.instantiate()
	get_tree().current_scene.add_child(fireball)
	fireball.global_position = $Marker2D.global_position

func vulnerability():
	vulnerable = true
	$BossState.play("glitch")
	await get_tree().create_timer(6.0).timeout
	$BossState.play("default")
	vulnerable = false
	modulate = Color(1, 1, 1, 1)
	rotation = 0

func take_damage(dmg):
	if vulnerable:
		current_hp -= 1.25 * dmg
	else:
		current_hp -= 0.5 * dmg
	
	HP.value = current_hp	
	modulate = Color(10, 10, 10, 1)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1, 1)

func die():
	var tween = create_tween()
	
	tween.tween_property(self, "modulate:a", 0.0, 3.0)
	await get_tree().create_timer(3.0).timeout
	$Hitbox.disabled = true

func movement_and_skill():
	# If we are already moving/choosing, abort! This prevents the rapid-fire glitch.
	if is_choosing_skill:
		return
		
	is_choosing_skill = true # Lock the door
	$BossState.play("warning")
	# --- PHASE 1: Calculate Target and Move ---
	var random_y = randf_range(min_y, max_y)
	var target_position = Vector2(fixed_x, random_y)
	
	print("Boss moving to: ", target_position)
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_position, 1.5).set_trans(Tween.TRANS_SINE)
	
	await tween.finished 
	
	# --- PHASE 2: Reset current skills ---
	FIREBALL = false
	BULLET_RAIN = false
	LAVA_FLOOR = false
	TVRAM = false
	
	# --- PHASE 3: Choose and activate a random skill ---
	var skills = ["BULLET_RAIN", "FIREBALL", "TVRAM", "LAVA_FLOOR"]
	var chosen_skill = skills[i % 4]
	i += 1
	
	print("Boss arrived! Activating: ", chosen_skill)
	
	match chosen_skill:
		"BULLET_RAIN":
			BULLET_RAIN = true
		"FIREBALL":
			FIREBALL = true
		"TVRAM":
			TVRAM = true
		"LAVA_FLOOR":
			LAVA_FLOOR = true
			
	# Unlock the door and reset the 3-second timer for the NEXT attack cycle
	is_choosing_skill = false
	idle_timer = 3.0

func _ready():
	$Hitbox.disabled = true
	HP.max_value = max_health
	HP.value = current_hp

func ram():
	await get_tree().create_timer(5.0).timeout
	ramming = true

func lava_floor_timer():
	await get_tree().create_timer(15.0).timeout
	LAVA_FLOOR_ON = false
	
func _physics_process(delta: float) -> void:
	if not ON:
		HP.visible = false
		$CanvasLayer/Label.visible = false
		return
	$CanvasLayer/Label.visible = true
	HP.visible = true
	$Hitbox.disabled = false
	
	if vulnerable:
		time_passed += delta * 2
		var pulse = (sin(time_passed)/2 + 0.5)
		modulate = Color(1, 1, pulse, 1)
		return
		
	if BULLET_RAIN:
		print('BULLET_RAIN')
		# RUN THROUGH MAIN SCENE
		pass
	elif LAVA_FLOOR:
		print('LAVA_FLOOR')
		LAVA_FLOOR_ON = true
		lava_floor_timer()
		LAVA_FLOOR = false
		# RUN THROUGH MAIN SCENE
		pass
	elif TVRAM:
		# 1. Fix the visual pulse
		time_passed += delta * 2
		var pulse = (sin(time_passed * 2.0) + 1.0) * 1.5 + 1.0
		modulate = Color(pulse, 1, 1, 1)
		
		var target = get_tree().get_nodes_in_group("Player")[0]
		
		if is_instance_valid(target):
			# PHASE 1: Aiming
			if not ramming and not is_aiming:
				is_aiming = true
				aim_timer = 4.0 # Set the 4-second countdown here
				speed = 1000.0  # Reset speed for the next charge
				
			if is_aiming:
				aim_timer -= delta # Count down
				
				# Track the player
				var direction = global_position.direction_to(target.global_position)
				rotation = direction.angle() - deg_to_rad(157) # Visual rotation
				charge_direction = Vector2(direction.x, direction.y) # Save the true direction for the charge
				
				# Time to charge!
				if aim_timer <= 0:
					is_aiming = false
					set_collision_mask_value(3, false)
					ramming = true
					
			# PHASE 2: Charging
			if ramming:
				speed += 1000 * delta
				# Use the true direction, NOT the adjusted sprite rotation
				velocity = charge_direction * speed 
				move_and_slide()
				
				if get_slide_collision_count() > 0:
					var collision = get_slide_collision(0)
					var collider = collision.get_collider()
					print("I collided with: ", collider.name)
					
					if collider.is_in_group("Player"):
						ramming = false
						target.take_damage(40)
						await get_tree().create_timer(0.1).timeout
						modulate = Color(10, 10, 10, 1)
						await get_tree().create_timer(0.1).timeout
						modulate = Color(1, 1, 1, 1)
					else:
						print("Hit a wall")
						ramming = false
						vulnerability()
						take_damage(80)
						modulate = Color(10, 10, 10, 1)
						await get_tree().create_timer(0.2).timeout
						modulate = Color(1, 1, 1, 1)
						modulate = Color(10, 10, 10, 1)
						await get_tree().create_timer(0.2).timeout
						modulate = Color(1, 1, 1, 1)
						modulate = Color(10, 10, 10, 1)
						await get_tree().create_timer(0.2).timeout
						modulate = Color(1, 1, 1, 1)
					TVRAM = false # Optional: Turn off the attack so it doesn't immediately loop
	elif FIREBALL:
		FIREBALL = false
		fireball()
		print("NUKE")
	else:
		if not is_choosing_skill:
			$BossState.play("default")
			idle_timer -= delta
			if idle_timer <= 0:
				movement_and_skill()
