extends CharacterBody2D

# Base Stats
@export var health = 50.0
@export var shield = 35.0
@export var speed = 300.0
@export var dash_speed = 1000.0
@export var jump_strength = -600.0
@export var wall_jump_push = 250.0

var current_hp = 50.0
var current_sp = 35.0

# World Stats
var double_jump = 1
const gravity = 2000.0
# Weapons
@onready var hp_bar = $HUD/HealthBar
@onready var hp_display = $HUD/HealthBar/HealthDisplay
@onready var sp_bar = $HUD/ShieldBar
@onready var sp_display = $HUD/ShieldBar/ShieldDisplay
@onready var active_weapon = $W1_Shotgun
@onready var side_weapon = $W2_Standard
@onready var player_sprite = $PlayerSprite
@onready var dash_cd = $HUD/DashCD
@onready var cast_cd = $HUD/CastCD
@export var shotgun_cd = 0.6
@export var rifle_cd = 0.08
@export var railgun_cd = 10.0
@export var switch_weapon_cd = 2.0

# die
signal died

# Miscellaneous
@onready var animated_sprite = $AnimatedSprite2D
var can_dash = true
var is_dashing = false
var direction
var can_shoot = true
var can_switch = true
var face_right = 1

func dash():
	can_dash = false
	is_dashing = true
	dash_cd.value = 0.0
	
	# no vertical movements while dashing
	velocity.y = 0
	velocity.x = dash_speed * face_right
	await get_tree().create_timer(0.4).timeout
	is_dashing = false
	
	var after_dash_dir = Input.get_axis("ui_left", "ui_right")
	if after_dash_dir == direction:
		velocity.x = after_dash_dir * speed
	else:
		velocity.x = 0
	
	await get_tree().create_timer(0.6).timeout # Wait 1.0 seconds to be able to dash again
	can_dash = true

func _ready():
	animated_sprite.play("idle")
	player_sprite.visible = false
	
	# Make sure the health bar matches our variables right when the game boots up
	cast_cd.value = 100.0
	dash_cd.value = 100.0
	hp_bar.max_value = health
	hp_bar.value = current_hp
	hp_display.text = "%.1f" % current_hp
	
	sp_bar.max_value = shield
	sp_bar.value = current_sp
	sp_display.text = "%.1f" % current_sp
	# (If you kept your weapon list code in _ready, keep it here too!)

func take_damage(dmg):
	current_sp -= dmg
	if current_sp < 0:
		current_hp += current_sp
		current_sp = 0
	
	hp_bar.value = current_hp # Update
	hp_display.text = "%.1f" % current_hp # update
	print("bro got -15 dmg")
	if current_hp <= 0:
		die()

func die():
	died.emit()
	queue_free()

func _physics_process(delta: float) -> void:
	# ----------------------- UI LOADING -----------------------
	cast_cd.value += 100 * delta / shotgun_cd
	
	if current_sp < shield:	
		current_sp += 1 * delta
		sp_bar.value = current_sp
		sp_display.text = "%.1f" % current_sp
	
	if direction == -1:
		face_right = -1
		player_sprite.flip_h = true
		animated_sprite.flip_h = true
		active_weapon.scale.x = -1
		active_weapon.position.x = -45.0
		side_weapon.scale.x = -1
	elif direction == 1:
		face_right = 1
		player_sprite.flip_h = false
		animated_sprite.flip_h = false
		active_weapon.scale.x = 1
		active_weapon.position.x = 45.0
		side_weapon.scale.x = 1
	
	# ----------------------- ANIMATION + MOVEMENTS -----------------------
	if is_dashing:
		animated_sprite.play("dash")
		move_and_slide()
		return # END THE FUNCTION RIGHT HERE
	elif velocity.y < 0:
		animated_sprite.play("up")
	elif velocity.y > 0:
		animated_sprite.play("down")
	elif direction != 0:
		animated_sprite.play("sprint")
	else:
		animated_sprite.play("idle")

	dash_cd.value += 180 * delta
	# 1. GRAVITY
	if not is_on_floor():
		if is_on_wall() and velocity.y > 0:
			velocity.y = 50
		else:
			velocity.y += gravity * delta
	
	# 2. Reset double jump count when we touch the floor
	if is_on_floor():
		double_jump = 1
		
	# 3. Jumping	
	if Input.is_action_just_pressed("ui_up"):
		if is_on_floor():
			velocity.y = jump_strength
		elif is_on_wall() and double_jump > 0:
			# WALL JUMP
			velocity.y = jump_strength
			# Push them away from the wall
			velocity.x = get_wall_normal().x * wall_jump_push
			double_jump -= 1
		elif double_jump > 0:
			velocity.y = jump_strength
			double_jump -= 1

	# 4. Smooth Horizontal Movement
	direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = move_toward(velocity.x, direction * speed, 1200 * delta)
	else:
		# If the player lets go of the keys, apply "friction" to gently slow them down
		velocity.x = move_toward(velocity.x, 0, 1000 * delta)

	# 5. Execute movement
	move_and_slide()
	
	if Input.is_action_just_pressed("dash") and can_dash:
		dash()
	
	# 5. Execute movement
	move_and_slide()
		
	# ----------------------- COMBAT -----------------------
	side_weapon.visible = false
	active_weapon.visible = true
	
	# Switch weapon
	if can_switch and Input.is_action_just_pressed("switch_weapon"):
		can_switch = false
		if active_weapon == $W1_Shotgun:
			active_weapon = $W2_Standard
			side_weapon = $W1_Shotgun
		else:
			active_weapon = $W1_Shotgun
			side_weapon = $W2_Standard
		
		await get_tree().create_timer(switch_weapon_cd).timeout
		can_switch = true
		
		
	if can_shoot and active_weapon == $W2_Standard:
		if Input.is_action_pressed("shoot"):
			active_weapon.shoot()
			can_shoot = false
			await get_tree().create_timer(rifle_cd).timeout
			can_shoot = true
	elif can_shoot and active_weapon == $W1_Shotgun:
		if Input.is_action_just_pressed("shoot"):
			active_weapon.shoot()
			cast_cd.value = 0.0
			can_shoot = false
			await get_tree().create_timer(shotgun_cd).timeout
			can_shoot = true
		
	# ----------------------- DEBUG -----------------------
	if Input.is_action_just_pressed("15-HP"):
		take_damage(15.0)
