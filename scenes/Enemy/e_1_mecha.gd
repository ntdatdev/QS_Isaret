extends CharacterBody2D

# -------------- STATS --------------
@export var max_hp = 100.0
var current_hp = 100.0

@export var move_speed = 200.0
@export var dash_speed = 500.0
@export var detection_range = 1000.0
@export var attack_range = 600.0
@export var windup_time = 1
@export var dash_time = 1
@export var recover_time = 2
@export var hover_height = 12.0
@export var hover_speed = 2.0
@export var damage = 30.0

var current_state = "IDLE"

# -------------- REFERENCES --------------
@onready var anim = $AnimatedSprite2D
@onready var hp_bar = $HealthBar
@onready var attack_hitbox = $AttackHitbox

var player = null
var spawn_position = Vector2.ZERO
var hover_timer = 0.0
var dash_direction = Vector2.ZERO
var damaged_bodies = []

func _ready():
	spawn_position = global_position

	current_hp = max_hp
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp

	if has_node("Sprite2D"):
		$Sprite2D.visible = false

	anim.play("idle")

# -------------- DAMAGE / HP --------------
func take_damage(amount):
	current_hp -= amount
	current_hp = clamp(current_hp, 0.0, max_hp)
	hp_bar.value = current_hp

# -------------- PLAYER FINDING --------------
func find_player():
	if player == null or !is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player")

func can_see_player():
	return player != null and is_instance_valid(player) \
		and global_position.distance_to(player.global_position) <= detection_range

# -------------- ATTACK --------------
func dash_attack():
	current_state = "WINDUP"
	velocity = Vector2.ZERO

	# WINDUP
	await get_tree().create_timer(windup_time).timeout

	if player == null or !is_instance_valid(player):
		current_state = "IDLE"
		return

	# Lock dash direction right before attacking
	dash_direction = global_position.direction_to(player.global_position)
	damaged_bodies.clear()
	current_state = "DASH"
	anim.play("dash")

	# DASH ACTIVE
	await get_tree().create_timer(dash_time).timeout

	# If still dashing, go into recovery
	if current_state == "DASH":
		current_state = "RECOVER"
		anim.play("idle")

	# RECOVERY
	await get_tree().create_timer(recover_time).timeout

	if can_see_player():
		current_state = "CHASE"
	else:
		current_state = "IDLE"

func check_dash_damage():
	for body in attack_hitbox.get_overlapping_bodies():
		if body.is_in_group("Player") and not damaged_bodies.has(body):
			damaged_bodies.append(body)

			if body.has_method("take_damage"):
				body.take_damage(damage)
			# Stop the dash so enemy does not stick to player
			
			# Push enemy slightly away from the player
			var push_dir = (global_position - body.global_position).normalized()
			velocity = push_dir * 300.0
			current_state = "RECOVER"
			await get_tree().create_timer(1).timeout
			anim.play("idle")
			velocity = Vector2.ZERO
			return

# -------------- MAIN LOGIC --------------
func _physics_process(delta):
	find_player()
	hover_timer += delta

	match current_state:
		"IDLE":
			anim.play("idle")

			# Hover around spawn point
			var hover_offset = Vector2(0, sin(hover_timer * hover_speed) * hover_height)
			var target_position = spawn_position + hover_offset
			var direction = global_position.direction_to(target_position)
			velocity = direction * move_speed * 0.5

			if can_see_player():
				current_state = "CHASE"

		"CHASE":
			anim.play("idle")

			if player != null and is_instance_valid(player):
				var distance = global_position.distance_to(player.global_position)

				if distance <= attack_range:
					dash_attack()
				else:
					var direction = global_position.direction_to(player.global_position)
					velocity = direction * move_speed
			else:
				current_state = "IDLE"

		"WINDUP":
			# Stay still while charging attack
			velocity = Vector2.ZERO

		"DASH":
			# Rush toward locked direction
			velocity = dash_direction * dash_speed
			check_dash_damage()

		"RECOVER":
			# Slow down after dash
			velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)

	# Flip sprite
	if velocity.x != 0:
		anim.flip_h = velocity.x > 0

	# Death
	if current_hp <= 0.0:
		queue_free()

	move_and_slide()
