extends CharacterBody2D

# -------------- STATS --------------
@export var max_hp: float = 700.0
var current_hp = 700.0
var ON = false
@export var move_speed = 500.0
@export var dash_speed = 1500.0
@export var detection_range = 2500.0

# --- NEW: RANGES & TIMERS ---
@export var laser_range = 1200.0# Max distance to shoot laser
@export var attack_range = 600.0# Max distance for melee/dash
var attack_timer = 2.0# Boss waits 2 seconds before first attack

@export var hover_height = 24.0
@export var hover_speed = 2.0

# --- SKILL VARIABLES ---
@export var minion_scene: PackedScene
var has_summoned = false

var is_repairing = false
var repair_timer = 0.0

var laser_duration = 0.0

var dash_direction = Vector2.ZERO
var damaged_bodies = []

# Current AI state
var current_state = "IDLE"

# -------------- REFERENCES --------------
@onready var anim = $AnimatedSprite2D
@onready var hp_bar = $CanvasLayer/ProgressBar
@onready var attack_hitbox = $AttackHitbox
@onready var black_hole_hitbox = $BlackHoleHitbox
@onready var laser_pivot = $LaserPivot
@onready var laser_area = $LaserPivot/LaserArea/CollisionShape2D # Assuming this is a CollisionShape2D!
@onready var laser_visual = $LaserPivot/LaserVisual
@onready var warning_circle: Sprite2D = $CirclePng44653

var player = null
var spawn_position = Vector2.ZERO
var hover_timer = 0.0

func _ready():
	visible = false
	spawn_position = global_position
	current_hp = max_hp
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	$CollisionShape2D.disabled = true
	
	# Ensure the laser is turned off at the start
	laser_area.set_deferred("disabled", true)
	laser_visual.visible = false
	
	anim.play("idle")

# -------------- DAMAGE & HEALING --------------
func take_damage(amount):
	current_hp -= amount
	update_hp_bar()
	
	modulate = Color(10, 10, 10, 1)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1, 1)
	
	# Check for Phase 2 Summon interrupt
	if current_hp <= (max_hp / 2.0) and not has_summoned and current_state in ["IDLE", "CHASE"]:
		prepare_and_attack("SUMMON")

func heal(amount):
	current_hp += amount
	if current_hp > max_hp:
		current_hp = max_hp
	update_hp_bar()

func update_hp_bar():
	hp_bar.value = current_hp
	
func find_player():
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player")

func can_see_player():
	return player != null and is_instance_valid(player) and global_position.distance_to(player.global_position) <= detection_range

func get_hover_velocity():
	return Vector2(0, cos(hover_timer * hover_speed) * hover_height)

# -------------- SKILL DECISION MAKER --------------
func choose_next_attack():
	if player == null: return
	
	var distance = global_position.distance_to(player.global_position)
	
	# Reset cooldown timer so the boss doesn't spam attacks
	attack_timer = randf_range(1.5, 3.0)
	
	# 1. Force summon if below 50% HP (Highest Priority)
	if current_hp <= (max_hp / 2.0) and not has_summoned:
		prepare_and_attack("SUMMON")
		return
		
	# 2. THE LASER ZONE (Between 600 and 1200 pixels away)
	if distance > attack_range and distance <= laser_range:
		if randf() < 0.70:
			prepare_and_attack("LASER") # 70% chance to shoot laser
		else:
			prepare_and_attack("LUNGE") # 30% chance to dash in to close the gap
			
	# 3. THE MELEE ZONE (Less than 600 pixels away)
	elif distance <= attack_range:
		var roll = randf()
		if roll < 0.40:
			prepare_and_attack("LUNGE")# 40% chance
		elif roll < 0.80:
			prepare_and_attack("BLACK_HOLE")# 40% chance
		else:
			prepare_and_attack("REPAIR")# 20% chance

func die():
	var tween = create_tween()
	
	tween.tween_property(self, "modulate:a", 0.0, 3.0)
	await get_tree().create_timer(3.0).timeout
	$CollisionShape2D.disabled = true

func prepare_and_attack(skill: String):
	current_state = "PREPARE"
	velocity = Vector2.ZERO # Stop moving completely
	
	print("PREPARING: ", skill)
	
	# Visual tell: Flash a reddish color to warn the player
	modulate = Color(2.0, 1.0, 1.0, 1.0)
	
	# Wait for 1.2 seconds
	await get_tree().create_timer(1.2).timeout
	
	# Safety check: Did the Mecha die while waiting?
	if current_hp <= 0: return
	
	# Reset color
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	match skill:
		"SUMMON": execute_summon()
		"LUNGE": execute_lunge()
		"BLACK_HOLE": execute_black_hole()
		"LASER": execute_laser()
		"REPAIR": execute_repair()

# -------------- SKILL EXECUTIONS --------------

# AT1: LUNGE
func execute_lunge():
	if player != null:
		dash_direction = global_position.direction_to(player.global_position)
		damaged_bodies.clear()
		current_state = "DASH"
		anim.play("dash")

# AT2: SUMMON
func execute_summon():
	has_summoned = true
	current_state = "ATTACKING"
	print("SUMMONING MINIONS!")
	
	if minion_scene:
		var minion_left = minion_scene.instantiate()
		var minion_right = minion_scene.instantiate()
		
		minion_left.global_position = global_position + Vector2(-150, 0)
		minion_right.global_position = global_position + Vector2(150, 0)
		
		get_tree().current_scene.add_child(minion_left)
		get_tree().current_scene.add_child(minion_right)
		
	await get_tree().create_timer(0.5).timeout
	current_state = "IDLE"

# AT3: BLACK HOLE (STARFALL)
func execute_black_hole():
	current_state = "ATTACKING"
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", player.global_position + Vector2(0, -100), 0.6)
	await tween.finished
	warning_circle.visible = true
	$AnimatedSprite2D.play("prep_bh")
	await get_tree().create_timer(0.8).timeout
	warning_circle.visible = false
	print("BLACK HOLE SLASH!")
	$BlackHoleHitbox/AnimatedSprite2D.play("default")
	$AnimatedSprite2D.play("bh")
	$BlackHoleHitbox/AnimatedSprite2D.visible = true
	apply_black_hole_slash()
	await get_tree().create_timer(0.5).timeout
	
	apply_black_hole_slash()
	await get_tree().create_timer(0.5).timeout
	$BlackHoleHitbox/AnimatedSprite2D.stop()
	$BlackHoleHitbox/AnimatedSprite2D.visible = false
	current_state = "IDLE"

func apply_black_hole_slash():
	for body in black_hole_hitbox.get_overlapping_bodies():
		if body.is_in_group("Player"):
			body.take_damage(15)
			var pull_dir = body.global_position.direction_to(global_position)
			body.global_position += pull_dir * 50.0

# AT4: GIGA-LAZER
func execute_laser():
	current_state = "LASER"
	laser_duration = 3
	$LaserPivot/RedLine.visible = true
	laser_pivot.rotation = global_position.direction_to(player.global_position).angle()
	# Aim at player
	await get_tree().create_timer(1.5).timeout
	
	# Turn on laser
	$LaserPivot/RedLine.visible = false
	laser_visual.visible = true
	laser_area.set_deferred("disabled", false)
	print("FIRING LASER!")
	$LaserPivot/LaserVisual.play("default")

# AT5: SELF-REPAIR
func execute_repair():
	print("INITIATING REPAIR!")
	heal(50)
	
	is_repairing = true
	repair_timer = 5.0
	
	# Instantly go back to fighting while healing happens in the background!
	current_state = "IDLE"

func activate():
	visible = true
	
	# 2. Set its initial transparency to 0 (completely invisible)
	modulate.a = 0.0
	
	# 3. Create the Tween
	var tween = create_tween()
	
	tween.tween_property(self, "modulate:a", 1.0, 3.0)
	$CollisionShape2D.disabled = false

# -------------- MAIN LOGIC --------------
func _physics_process(delta):
	if not ON:
		hp_bar.visible = false
		$CanvasLayer/Label.visible = false
		return
	hp_bar.visible = true
	$CanvasLayer/Label.visible = true
	find_player()
	hover_timer += delta

	# --- BACKGROUND REPAIR LOGIC ---
	if is_repairing:
		$AnimatedSprite2D.modulate = Color(cos(repair_timer)**2,1,cos(repair_timer)**2,1)
		repair_timer -= delta
		heal(15.0 * delta)
		if repair_timer <= 0:
			is_repairing = false

	match current_state:
		"IDLE":
			anim.play("idle")
			var target_position = spawn_position + Vector2(0, sin(hover_timer * hover_speed) * hover_height)
			velocity = global_position.direction_to(target_position) * move_speed * 0.5
			
			if can_see_player():
				current_state = "CHASE"

		"CHASE":
			anim.play("chase")
			if player != null and is_instance_valid(player):
				var distance = global_position.distance_to(player.global_position)
				
				# Tick down the cooldown
				attack_timer -= delta
				
				# --- IS IT TIME TO ATTACK? ---
				if attack_timer <= 0:
					if distance <= laser_range:
						choose_next_attack() # Boss picks based on exact distance!
					else:
						# Player is completely out of range (> 1200px), just chase them
						velocity = global_position.direction_to(player.global_position) * move_speed
						velocity.y += get_hover_velocity().y
						
				# --- MOVEMENT WHILE ON COOLDOWN ---
				else:
					if distance > attack_range * 0.8:
						# 1. Player is far away: Walk closer to them
						velocity = global_position.direction_to(player.global_position) * move_speed
						
					elif distance < attack_range * 0.4:
						# 2. Player is TOO close: Back away slowly to maintain spacing! (Tactical Retreat)
						velocity = -global_position.direction_to(player.global_position) * (move_speed * 0.5)
						
					else:
						# 3. Perfect distance: Hover menacingly in place
						velocity.x = move_toward(velocity.x, 0, 900 * delta)
						
					velocity.y += get_hover_velocity().y
			else:
				current_state = "IDLE"

		"PREPARE", "ATTACKING":
			velocity = Vector2.ZERO
			
		"LASER":
			velocity = Vector2.ZERO
			laser_duration -= delta
			
			if player != null:
				var target_angle = global_position.direction_to(player.global_position).angle()
				laser_pivot.rotation = lerp_angle(laser_pivot.rotation, target_angle, 2.0 * delta)
				
			# In a standard Area2D + CollisionShape setup, Area2D handles overlapping bodies
			# If you used an Area2D script to handle damage, this loop goes there.
			# Otherwise, we check the parent of the collision shape (which should be the Area2D)
			var actual_area = laser_area.get_parent()
			if actual_area is Area2D:
				for body in actual_area.get_overlapping_bodies():
					if body.is_in_group("Player"):
						body.take_damage(10.0 * delta)
			
			if laser_duration <= 0:
				laser_visual.visible = false
				laser_area.set_deferred("disabled", true)
				current_state = "RECOVER"
				$LaserPivot/LaserVisual.stop()

		"DASH":
			velocity = dash_direction * dash_speed
			
			for body in attack_hitbox.get_overlapping_bodies():
				if body.is_in_group("Player") and not damaged_bodies.has(body):
					damaged_bodies.append(body)
					body.take_damage(18.0)
					current_state = "RECOVER"

			if is_on_wall():
				take_damage(40.0)
				print("MECHA HIT A WALL!")
				current_state = "RECOVER"

		"RECOVER":
			velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
			velocity.y += get_hover_velocity().y
			
			if velocity.x == 0:
				current_state = "IDLE"

	if velocity.x != 0:
		anim.flip_h = velocity.x > 0

	move_and_slide()
