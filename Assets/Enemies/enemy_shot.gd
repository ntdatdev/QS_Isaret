extends Area2D

@export var speed: float = 1000.0
@export var attack_damage = 15.0
@export var max_hp = 65.0
@export var cd = 1.0
var current_hp = 65.0
var target: Node2D = null

func _ready():
	await get_tree().create_timer(cd).timeout
	queue_free() # DELETE
func _physics_process(delta: float) -> void:
	# Check if the target still exists (prevents crashes if the player dies)
	if is_instance_valid(target):
		var direction = global_position.direction_to(target.global_position)
		global_position += direction * speed * delta
		
		rotation = direction.angle()
	else:
		# If the target is destroyed, destroy the bullet (or let it fly straight)
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	# Assuming your player node is assigned to a group called "Player"
	if body.is_in_group("Player"):
		if body.has_method("take_damage"):
			body.take_damage(attack_damage)
		queue_free()
	
	# Optional: Destroy bullet if it hits a wall (assuming walls are StaticBody2D)
	elif body is StaticBody2D:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	# Check if the other area we hit is also a bullet
	if area.is_in_group("Bullet"):
		area.queue_free()
		queue_free() 
