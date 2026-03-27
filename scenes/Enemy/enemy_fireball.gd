extends Area2D

@export var speed: float = 700.0
@export var attack_damage = 30.0
@export var max_hp = 100.0
var current_hp = 60.0
var target: Node2D

func _ready():
	$AnimatedSprite2D.play("default")

func _physics_process(delta: float) -> void:
	# Check if the target still exists (prevents crashes if the player dies)
	if is_instance_valid(target):
		var direction = global_position.direction_to(target.global_position)
		global_position += direction * speed * delta
		
		rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
	# Assuming your player node is assigned to a group called "Player"
	if body.is_in_group("Player"):
		if body.has_method("take_damage"):
			body.take_damage(attack_damage)
		queue_free()



func _on_area_entered(area: Area2D) -> void:
	# Check if the other area we hit is also a bullet
	if area.is_in_group("Bullet"):
		area.queue_free()
		queue_free() 
