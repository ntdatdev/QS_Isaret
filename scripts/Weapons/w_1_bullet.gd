extends Area2D

@export var bullet_time = 0.5
@export var speed = 1800

func _ready():
	await get_tree().create_timer(bullet_time).timeout
	queue_free() # DELETE


func _physics_process(delta: float) -> void:
	position.x += speed * delta * cos(global_rotation)
	position.y += speed * delta * sin(global_rotation)

func _on_body_entered(body):
	# Ask the object: "Do you have a function called take_damage?"
	if body.has_method("take_damage"):
		# If yes, this must be an enemy! Tell it to take 10 damage.
		body.take_damage(10)
		queue_free()
		
	# If it DOESN'T have that method (like a Wall), just destroy the bullet.
	elif body is TileMap or body is StaticBody2D:
		queue_free()
