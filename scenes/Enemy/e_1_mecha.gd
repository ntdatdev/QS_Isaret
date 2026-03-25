extends CharacterBody2D

# -------------- STATS --------------
@export var max_hp = 100.0
var current_hp = 100.0

@export var move_speed = 200.0
@export var dash_speed = 500.0
@export var detection_range = 1000.0
@export var attack_range = 600.0
@export var windup_time = 1.0
@export var dash_time = 1.0
@export var recover_time = 2.0
@export var hover_height = 24.0
@export var hover_speed = 2.0
@export var damage = 30.0

# Current AI state: IDLE, CHASE, WINDUP, DASH, or RECOVER
var current_state = "IDLE"

# -------------- REFERENCES --------------
# Animated sprite for idle / dash visuals
@onready var anim = $AnimatedSprite2D
# HP bar shown above the enemy
@onready var hp_bar = $HealthBar
# Area2D used to damage the player during dash
@onready var attack_hitbox = $AttackHitbox

# Cached player reference
var player = null
# Position where the enemy first spawned
var spawn_position = Vector2.ZERO
# Timer used to drive hovering motion
var hover_timer = 0.0
# Direction locked in when dash begins
var dash_direction = Vector2.ZERO
# Keeps track of who was already hit this dash
var damaged_bodies = []

func _ready():
	# Remember spawn point so idle hovering stays near this spot
	spawn_position = global_position

	# Initialize HP and health bar
	current_hp = max_hp
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp

	# Hide old static sprite if it exists
	if has_node("Sprite2D"):
		$Sprite2D.visible = false

	# Start in idle animation
	anim.play("idle")

# -------------- DAMAGE / HP --------------
func take_damage(amount):
	# Reduce HP and update the health bar
	current_hp -= amount
	current_hp = clamp(current_hp, 0.0, max_hp)
	hp_bar.value = current_hp

# -------------- PLAYER FINDING --------------
func find_player():
	# If player reference is missing, try finding the player by group
	if player == null or !is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player")

func can_see_player():
	# True if player exists and is inside detection range
	return player != null and is_instance_valid(player) \
		and global_position.distance_to(player.global_position) <= detection_range

# -------------- HOVER --------------
func get_hover_velocity():
	# Creates smooth up/down motion using cosine wave
	# Only affects Y movement
	return Vector2(0, cos(hover_timer * hover_speed) * hover_height)

# -------------- ATTACK --------------
func dash_attack():
	# Enter windup state before dashing
	current_state = "WINDUP"
	velocity = Vector2.ZERO

	# Wait during windup so player has time to react
	await get_tree().create_timer(windup_time).timeout

	# If player disappeared during windup, go back to idle
	if player == null or !is_instance_valid(player):
		current_state = "IDLE"
		return

	# Lock the dash direction right before attack starts
	dash_direction = global_position.direction_to(player.global_position)
	# Clear hit list so this dash can damage again
	damaged_bodies.clear()
	# Enter dash state and play dash animation
	current_state = "DASH"
	anim.play("dash")

	# Keep dashing for dash_time seconds
	await get_tree().create_timer(dash_time).timeout

	# If still in dash state after timer, switch to recover
	if current_state == "DASH":
		current_state = "RECOVER"
		anim.play("idle")

	# Wait during recovery
	await get_tree().create_timer(recover_time).timeout

	# After recovery, either chase again or return to idle
	if can_see_player():
		current_state = "CHASE"
	else:
		current_state = "IDLE"

func check_dash_damage():
	# Check all bodies overlapping the dash hitbox
	for body in attack_hitbox.get_overlapping_bodies():
		# Only damage the player, and only once per dash
		if body.is_in_group("Player") and not damaged_bodies.has(body):
			damaged_bodies.append(body)

			# Call player's damage function if it exists
			if body.has_method("take_damage"):
				body.take_damage(damage)

			# Stop dash immediately so enemy does not stick to the player
			current_state = "RECOVER"
			await get_tree().create_timer(0.5).timeout
			anim.play("idle")
			return

# -------------- MAIN LOGIC --------------
func _physics_process(delta):
	# Keep trying to find the player if needed
	find_player()
	# Advance hover timer every frame
	hover_timer += delta

	match current_state:
		"IDLE":
			# Play idle animation while hovering near spawn point
			anim.play("idle")

			# Create hover target above/below spawn point
			var hover_offset = Vector2(0, sin(hover_timer * hover_speed) * hover_height)
			var target_position = spawn_position + hover_offset
			var direction = global_position.direction_to(target_position)

			# Move gently toward hover target
			velocity = direction * move_speed * 0.5

			# Start chasing if player is detected
			if can_see_player():
				current_state = "CHASE"

		"CHASE":
			# Still use idle animation while chasing
			anim.play("idle")

			if player != null and is_instance_valid(player):
				var distance = global_position.distance_to(player.global_position)

				# If close enough, begin dash attack
				if distance <= attack_range:
					dash_attack()
				else:
					# Move toward player
					var direction = global_position.direction_to(player.global_position)
					velocity = direction * move_speed
					# Add hovering to chase movement so enemy still floats
					velocity.y += get_hover_velocity().y
			else:
				# If player is gone, return to idle
				current_state = "IDLE"

		"WINDUP":
			# Stay still while charging dash
			velocity = Vector2.ZERO

		"DASH":
			# Rush toward locked direction
			velocity = dash_direction * dash_speed
			# Check if dash hitbox is touching the player
			check_dash_damage()

		"RECOVER":
			# Slow down after dash
			velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
			# Keep slight hovering motion during recovery
			velocity.y += get_hover_velocity().y

	# Flip sprite left/right based on horizontal movement
	if velocity.x != 0:
		anim.flip_h = velocity.x > 0

	# Remove enemy when HP reaches zero
	if current_hp <= 0.0:
		queue_free()

	# Apply movement
	move_and_slide()
