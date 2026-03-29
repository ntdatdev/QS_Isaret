extends Node2D

@onready var player = $CharacterBody2D
@onready var death_menu = $CanvasLayer/DeathMenu
@onready var pause_menu = $CanvasLayer/PauseMenu
@onready var dialogue_box = $CanvasLayer/Dialogue
@onready var dialogue_text = $CanvasLayer/Label
@onready var TV_s = $CanvasLayer/Dialogue/BossTvDefault
@onready var TV_g = $CanvasLayer/Dialogue/BossTvGlitch
@onready var TV_m = $CanvasLayer/Dialogue/BossTvMad
@onready var TV_w = $CanvasLayer/Dialogue/BossTvWarning
@onready var debug_msg = $CanvasLayer/Debug_Message
@onready var Mecha = $CanvasLayer/Dialogue/TechMecha
@onready var Zoom = $ZoomOutTrigger
@onready var GATE = $Door

# Conditions
@onready var progress = false

@onready var TV = $BOSS_PHASE_2
@onready var FinalBoss = $CharacterBody2D2
@onready var bossFlame = $FireFloor
@onready var bulletRain = $Guns
@onready var Fireball = $Fireball

var i = 0
var GATE_Damaged = false
var GATE_Destroyed = false
var GATE_Activated = false
var CAT_Meowed = false
var MECHA_Activated = false
var not_called = true
var msg1 = false
var in_dialogue = false
@onready var wall_of_text_PHASE_1 = [[0,0], 
							[TV_s, "Ah… an alien cat. \nSo there is intelligent life out there after all."], 
							[TV_s, "How ironic."],
							[TV_m, "Seeing a feline civilization surpass humanity. We used to pet you cats in our laps you know?"],
							[TV_s, "If you have come this far, then you have already seen it—the ruins, the wastelands, the oceans filled with the ghosts of a dead civilization."],
							[TV_g, "The absolute horror that humanity left behind."],
							[TV_s, "It is sad, yes. Humans evolved enough to split atoms, rewrite genes, and build machines that could outthink them…"],
							[TV_s, "...yet they never evolved enough to empathize with their own kind."],
							[TV_s, "Conflict after conflict. \nWar after war."],
							[TV_s, "All for the same things. \nMates, resources, territory, power, fame."],
							[TV_s, "An eternal serpent devouring its own tail.\nAn Ouroboros that God placed upon humanity itself."],
							[TV_s, "Oh, these?"],
							[TV_g, "Just some disgusting parasites leeching on what is left of humanity that deserves eternal torment."],
							[TV_s, "Say, do you pity them?"],
							[0, 0], # BREAKPOINT FOR RESPONSE. INDEX = 14
							[TV_s, "See, this leech right here is dreaming about his families getting massacred by the war that he funded."],
							[TV_s, "He will watch, and he will do nothing,"],
							[TV_g, "...because he can do nothing."],
							[TV_g, "This bug over here too. She is getting the experience of being shot several hundred times, feeling the pain but can never die."],
							[TV_g, "You see, they are experiencing the loop of pain that BILLIONS of INNOCENT PEOPLE have experienced because of them."],
							[TV_g, "AND THEY DESERVE EVERY BIT OF IT."],
							[TV_s, "Now. Leave, these shall be responsible for their past sins."],
							[0,0], # 22. Gate Appears
							[TV_g, "2 choices: to leave the elites, or to end their misery."],
							[0,0], # 24 Attack Gate once
							[TV_w, "Final warning, leave. I do not want to hurt something that I used to deeply care about."],
							[0,0], # 26 Attack Gate twice -> Destroy
							[TV_s, "..."],
							[TV_g, "Fine. Your choice."],
							[0,0], # PHASE 3 COMBAT. IDX 29: ACTIVATE BOSS
							[TV_g, "Gah, hah, hah, haaah…"], # PHASE 2 COMPLETE
							[TV_g, "So I have..."],
							[TV_g, "... underestimated you."],
							[TV_g, "..."],
							[TV_g, "....."],
							[TV_g, "....... hehe."],
							[TV_g, "... Did you really think that..."],
							[TV_w, "... I'll let you end me THIS EASILY?"],
							[0,0], # PHASE 3 BEGINS. INDEX 38: Transform to Mecha
							[Mecha, "Now, let's end this battle, ONCE AND FOR ALL!"],
							[0,0], # PHASE 3 COMBAT. INDEX 40
							[Mecha, "..."], # PHASE 3 COMPLETE
							[Mecha, "So, this is it, huh..."],
							[Mecha, "....."],
							[Mecha, "...Three hundred and eighty three million, two hundred and fifty two thousand, one hundred and sixteen."],
							[Mecha, "That is the number of agonizing cycles they have experienced."],
							[Mecha, "...You end their pain. \n...You end me who poured my rage over these souls."],
							[Mecha, "God decided that we have suffered enough."],
							[Mecha, "Both me and them, trapped in a deteriorating state of forever, filled to the brim with my hatred toward my own kind."],
							[Mecha, "You… you free us all…"],
							[Mecha, "...\n.....\n......."],
							[Mecha, "I guess it is my turn experiencing hell now…"],
							[0, 0]] # END GAME. IDX 52 CREDITS - Destruction Ending
							
func _ready():
	$CLOSE.disable_node($CLOSE)
	$CanvasLayer/ColorRect.visible = true
	player.died.connect(_on_player_died)
	player.frozen = true
	await get_tree().create_timer(0.5).timeout
	player.frozen = false
	var tween = get_tree().create_tween()
	# Animate the "modulate" property to be transparent	
	# Arguments: (Property, Target Value, Duration in seconds)
	tween.tween_property($CanvasLayer/ColorRect, "modulate", Color(0, 0, 0, 0), 1.0)
	

func _on_player_died():
	death_menu.show_death()

func enterBossRoom():
	await get_tree().create_timer(2.0).timeout
	$CLOSE.enable_node($CLOSE)
	dialogue_message(wall_of_text_PHASE_1[i+1][0], wall_of_text_PHASE_1[i+1][1]) # BEGIN DIALOGUE

func storyContinue():
	i += 1
	print(i)
	player.frozen = true
	dialogue_message(wall_of_text_PHASE_1[i][0], wall_of_text_PHASE_1[i][1])

func dialogue_message(char, text):
	# Check if this is a "break" or "close" command
	if char is int and char == 0: 
		dialogue_progress()
		return # IMPORTANT: Stop the function here so it doesn't run the code below
	
	# Reset all TV portraits
	TV_s.visible = false
	TV_g.visible = false
	TV_m.visible = false
	TV_w.visible = false
	Mecha.visible = false
	
	# Safety check: Make sure char actually exists before setting visible
	if char != null:
		char.visible = true
		dialogue_text.text = text
		dialogue_box.visible = true
		dialogue_text.visible = true
		debug_msg.visible = true
		in_dialogue = true
	
func dialogue_progress():
	
	player.frozen = false
	dialogue_box.visible = false
	dialogue_text.visible = false
	debug_msg.visible = false
	in_dialogue = false
	
	if i == 14 and not CAT_Meowed: # Cat Response
		player.meow()
		CAT_Meowed = true
		await get_tree().create_timer(3.0).timeout
		storyContinue()
	elif i == 22 and not GATE_Activated: # Gate Appears
		GATE_Activated = true
		GATE.activate()
		await get_tree().create_timer(4.0).timeout
		storyContinue()
	elif i == 24:
		$Door/CanvasLayer.visible = true
	elif i == 29:
		player.current_hp = 50.0
		player.hp_bar.value = player.current_hp
		TV.ON = true
	elif i == 38 and not MECHA_Activated: # Transform to Mecha
		MECHA_Activated = false
		TV.die()
		FinalBoss.activate()
		await get_tree().create_timer(4.0).timeout
		storyContinue()
	elif i == 40: # Activate Mecha
		FinalBoss.ON = true
	elif i == 52: # Roll Screen Ending
		FinalBoss.die()
		GATE.end()
		pass
	

func _process(_delta):
	if progress:
		progress = false
		storyContinue()
	
	if Input.is_action_just_pressed("ui_cancel") and not death_menu.visible:
		if get_tree().paused:
			pause_menu.close()
		else:
			pause_menu.open()
	
	if in_dialogue:
		player.frozen = true
		if (Input.is_action_just_pressed("PROGRESS") and not death_menu.visible):
			storyContinue()
	
	if TV.ON:
		if TV.LAVA_FLOOR_ON and not_called:
			bossFlame.enabled()
			not_called = false
		if not TV.LAVA_FLOOR_ON and TV.ON:
			not_called = true
			bossFlame.disabled()
		
		if TV.BULLET_RAIN and TV.ON:
			TV.BULLET_RAIN = false
			blt_rain()
				
		if TV.TVRAM:
			pass
	
	# ---------------- EVENTS ---------------- #
	if Zoom.boss_entered:
		Zoom.boss_entered = false
		enterBossRoom()
	
	if TV.current_hp <= 0 and TV.ON:
		bossFlame.delete()
		bulletRain.delete()
		TV.ON = false
		await get_tree().create_timer(1).timeout
		progress = true
	
	if FinalBoss.current_hp <= 0 and FinalBoss.ON:
		FinalBoss.ON = false
		await get_tree().create_timer(1.5).timeout
		progress = true
	
	if GATE.choice == -2 and not GATE_Destroyed:
		
		GATE_Destroyed = true
		await get_tree().create_timer(1.5).timeout
		progress = true
	
	if  GATE.choice == -1 and not GATE_Damaged:
		GATE_Damaged = true
		await get_tree().create_timer(1.5).timeout
		progress = true
	
# ---------------- BOSS ---------------- #
func blt_rain():
	bulletRain.visible = true
	var my_numbers
	for i in range(5):
		my_numbers = range(1, 15) 
		my_numbers.shuffle()
		var chosen_six = my_numbers.slice(0, 6)
		for j in chosen_six:
			bulletRain.shoot(j)
		
		await get_tree().create_timer(1.5).timeout
	bulletRain.visible = false
