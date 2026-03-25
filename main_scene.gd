extends Node2D

@onready var player = $CharacterBody2D
@onready var death_menu = $CanvasLayer/DeathMenu
@onready var pause_menu = $CanvasLayer/PauseMenu
@onready var dialogue_box = $CanvasLayer/Dialogue
@onready var dialogue_text = $CanvasLayer/Label
@onready var dialogue_char = $CanvasLayer/Dialogue/Icon
@onready var debug_msg = $CanvasLayer/Debug_Message

var msg1 = false
var in_dialogue = false

func _ready():
	player.died.connect(_on_player_died)
	await get_tree().create_timer(0.5).timeout
	var tween = get_tree().create_tween()
	# Animate the "modulate" property to be transparent	
	# Arguments: (Property, Target Value, Duration in seconds)
	tween.tween_property($CanvasLayer/ColorRect, "modulate", Color(0, 0, 0, 0), 1.0)
	await get_tree().create_timer(1.0).timeout


func _on_player_died():
	death_menu.show_death()

func dialogue_message(char, text):
	in_dialogue = true
	
	dialogue_char = char
	dialogue_text.text = text
	dialogue_box.visible = true
	dialogue_text.visible = true
	debug_msg.visible = true
	
func dialogue_progress():
	player.frozen = false
	dialogue_box.visible = false
	dialogue_text.visible = false
	debug_msg.visible = false
	

func _process(_delta):
	
	if Input.is_action_just_pressed("ui_cancel") and not death_menu.visible:
		if get_tree().paused:
			pause_menu.close()
		else:
			pause_menu.open()
	
	if in_dialogue:
		player.frozen = true
		if Input.is_action_just_pressed("PROGRESS") and not death_menu.visible:
			dialogue_progress()
			in_dialogue = false
	
	# First dialogue
	if player.position.x > 3000.0 and not msg1:
		msg1 = true # msg activated
		dialogue_message(dialogue_char, "Ready?")
		
