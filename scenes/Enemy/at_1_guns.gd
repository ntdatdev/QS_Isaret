extends CharacterBody2D
@export var bullet_scene: PackedScene

func delete():
	queue_free()

func shoot(n: int):

	var gun = "G%d" % n
	var muzzle = "G%d/Marker2D" % n
	var line = "G%d/RedLine" % n
	var bullet = bullet_scene.instantiate()
	
	get_node(line).visible = true
	await get_tree().create_timer(1).timeout
	get_node(line).visible = false
	
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = get_node(muzzle).global_position
	bullet.global_rotation = get_node(gun).global_rotation + PI/2
