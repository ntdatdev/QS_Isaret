extends Node2D

@onready var player = $CharacterBody2D
@onready var death_menu = $CanvasLayer/DeathMenu
@onready var pause_menu = $CanvasLayer/PauseMenu
@onready var dialogue_box = $CanvasLayer/Dialogue
@onready var dialogue_text = $CanvasLayer/Label
@onready var dialogue_char = $CanvasLayer/Dialogue/BossTvDefault
@onready var debug_msg = $CanvasLayer/Debug_Message

@onready var TV = $BOSS_PHASE_2
@onready var bossFlame = $FireFloor
@onready var bulletRain = $Guns
@onready var Fireball = $Fireball

var PHASE_1 = false
var PHASE_2 = false
var PHASE_3 = false
var i = 0

var not_called = true
var msg1 = false
var in_dialogue = false
var wall_of_text_PHASE_1 = [[0,0], 
							[dialogue_char, "Ah… an alien cat. \nSo there is intelligent life out there after all."], 
							[dialogue_char, "How ironic."],
							[dialogue_char, "Seeing a feline civilization surpass humanity. We used to pet you cats in our laps you know?"],
							[dialogue_char, "If you have come this far, then you have already seen it—the ruins, the wastelands, the oceans filled with the ghosts of a dead civilization."],
							[dialogue_char, "The absolute horror that humanity left behind."],
							[dialogue_char, "It is sad, yes. Humans evolved enough to split atoms, rewrite genes, and build machines that could outthink them…"],
							[dialogue_char, "...yet they never evolved enough to empathize with their own kind."],
							[dialogue_char, "Conflict after conflict. \nWar after war."],
							[dialogue_char, "All for the same things. \nMates, resources, territory, power, fame."],
							[0, 0]]

func _ready():
	$CanvasLayer/ColorRect.visible = true
	player.died.connect(_on_player_died)
	player.frozen = true
	await get_tree().create_timer(0.5).timeout
	player.frozen = false
	var tween = get_tree().create_tween()
	# Animate the "modulate" property to be transparent	
	# Arguments: (Property, Target Value, Duration in seconds)
	tween.tween_property($CanvasLayer/ColorRect, "modulate", Color(0, 0, 0, 0), 1.0)
	await get_tree().create_timer(1.0).timeout
	dialogue_message(wall_of_text_PHASE_1[i+1][0], wall_of_text_PHASE_1[i+1][1])

func _on_player_died():
	death_menu.show_death()

func dialogue_message(char, text):
	if char == 0 and text == 0:
		dialogue_progress()
	else:
	
		dialogue_char = char
		dialogue_text.text = text
		dialogue_box.visible = true
		dialogue_text.visible = true
		debug_msg.visible = true
		
		in_dialogue = true
	
func dialogue_progress():
	i = -1
	player.frozen = false
	dialogue_box.visible = false
	dialogue_text.visible = false
	debug_msg.visible = false
	in_dialogue = false
	

func _process(_delta):
	
	if Input.is_action_just_pressed("ui_cancel") and not death_menu.visible:
		if get_tree().paused:
			pause_menu.close()
		else:
			pause_menu.open()
	
	if in_dialogue:
		player.frozen = true
		if Input.is_action_just_pressed("PROGRESS") and not death_menu.visible:
			i += 1
			dialogue_message(wall_of_text_PHASE_1[i][0], wall_of_text_PHASE_1[i][1])
	
	
	if TV.LAVA_FLOOR_ON and not_called:
		print('OK')
		bossFlame.enabled()
		not_called = false
	if not TV.LAVA_FLOOR_ON:
		not_called = true
		bossFlame.disabled()
	
	if TV.BULLET_RAIN:
		TV.BULLET_RAIN = false
		blt_rain()
			
		
	if TV.TVRAM:
		pass
	
	# First dialogue
	if player.position.x > 3000.0 and not msg1:
		return
		msg1 = true # msg activated
		dialogue_message(dialogue_char, "Ready?")
	
	# ---------------- BOSS ---------------- #
func blt_rain():
	bulletRain.visible = true
	var my_numbers
	for i in range(3):
		my_numbers = range(1, 15) 
		my_numbers.shuffle()
		var chosen_six = my_numbers.slice(0, 6)
		for j in chosen_six:
			bulletRain.shoot(j)
		
		await get_tree().create_timer(3).timeout
	bulletRain.visible = false
	
	
	
	
