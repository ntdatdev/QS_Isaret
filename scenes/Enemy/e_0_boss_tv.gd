extends Node2D
@export var max_health = 850.0
@export var bullet_scene: PackedScene
var current_hp = 850.0
var vulnerable = false

var FIREBALL = true
var BULLET_RAIN = false
var LAVA_FLOOR = false
var TVRAM = false

@onready var HP = $CanvasLayer/hpBar

func fireball():
	var bullet = bullet_scene.instantiate()
	bullet.target = 
	
	


func take_damage(dmg):
	if vulnerable:
		current_hp -= 1.5 * dmg
	else:
		current_hp -= 0.5 * dmg
	
	HP.value = current_hp	
	if current_hp <= 0:
		die()

func die():
	pass

func _ready():
	HP.max_value = max_health
	HP.value = current_hp
	
func _physics_process(delta: float) -> void:
	if FIREBALL:
		FIREBALL = false
		fireball()
		print("NUKE")
	pass
	
