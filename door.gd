extends Area2D
var can_take_damage = false
var choice = 0

func ready():
	visible = false
	$CollisionShape2D.disabled = true

func activate():
	visible = true
	
	# 2. Set its initial transparency to 0 (completely invisible)
	modulate.a = 0.0 
	
	# 3. Create the Tween
	var tween = create_tween()
	
	tween.tween_property(self, "modulate:a", 1.0, 3.0)
	$CollisionShape2D.disabled = false
	await get_tree().create_timer(3).timeout
	$AnimatedSprite2D.play("OPEN")
	await get_tree().create_timer(0.5).timeout
	$AnimatedSprite2D.play("IDLE")
	can_take_damage = true

func end():
	choice = 999 # FIGHT ENDING
	$AnimatedSprite2D.play("OPEN")
	await get_tree().create_timer(0.5).timeout
	$AnimatedSprite2D.play("IDLE")
	$CollisionShape2D.disabled = false
	
func _on_area_entered(area: Node2D) -> void:
	# 1. If we are on cooldown, ignore the hit entirely
	if not can_take_damage:
		return 

	if area.is_in_group("Bullet") or area.is_in_group("Bullet 2"):
		area.queue_free()
		can_take_damage = false
		print(choice)
		choice -= 1
		modulate = Color(10,10,10,1)
		await get_tree().create_timer(0.2).timeout
		modulate = Color(1,1,1,1)
		await get_tree().create_timer(0.9).timeout
		can_take_damage = true
		
	if choice == -2:
		$CanvasLayer.visible = false
		$CollisionShape2D.disabled = true
		$AnimatedSprite2D.play("CLOSE") # 0.5s
		await get_tree().create_timer(0.5).timeout
		
		$AnimatedSprite2D.play("SHUT_DOWN")


func _on_body_entered(body) -> void:
	if body.is_in_group("Player"):
		$CanvasLayer.visible = false
		if choice == 0 or choice == -1:
			get_tree().change_scene_to_file("res://scenes/PASSIVE_END.tscn")
		if choice >= 2:
			get_tree().change_scene_to_file("res://scenes/ENDING.tscn")
		
