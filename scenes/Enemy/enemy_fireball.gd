extends Area2D

@export var speed = 500.0
@export var attack_damage = 30.0
@export var max_hp = 65.0
var current_hp = 65.0
var target

func _ready():
	$AnimatedSprite2D.play("default")

func _process(delta: float) -> void:
	var target = get_tree().get_nodes_in_group("Player")[0]
	# Check if the target still exists (prevents crashes if the player dies)
	if is_instance_valid(target):
		speed += 50 * delta
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
		current_hp -= 30
		modulate = Color(1.0,1.0,1.0,0.3 + 0.7 * current_hp / max_hp)
		attack_damage = 5 + 25 * current_hp / max_hp
	
	if area.is_in_group("Bullet 2"):
		area.queue_free()
		current_hp -= 12
		modulate = Color(1.0,1.0,1.0,0.3 + 0.7 * current_hp / max_hp)
		attack_damage = 5 + 25 * current_hp / max_hp
	
	
