extends Area2D
@onready var hitbox = $CollisionShape2D

func disabled():
	visible = false
	hitbox.disabled = true

func delete():
	queue_free()

func enabled():
	visible = true
	for i in range(1, 15): # Starts at 1, stops before 16
		var node_name = "Anim%d" % i
		var anim_node = get_node(node_name)
		
		if anim_node:
			anim_node.play("danger")
			anim_node.scale = Vector2(0.4,0.4)

	await get_tree().create_timer(2).timeout
	hitbox.disabled = false
	for i in range(1, 15): # Starts at 1, stops before 16
		var node_name = "Anim%d" % i
		var anim_node = get_node(node_name)
		
		if anim_node:
			anim_node.play("default")
			anim_node.scale = Vector2(1,1)
	

func _ready():
	disabled()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.on_fire = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.on_fire = false
