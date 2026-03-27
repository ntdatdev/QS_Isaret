extends Area2D
@export var speed = 2500.0
@export var attack_damage = 15.0

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.take_damage(attack_damage)
	queue_free()
	
func _physics_process(delta: float) -> void:
	position.x += speed * delta * cos(global_rotation + PI/2)
	position.y += speed * delta * sin(global_rotation + PI/2)
