extends AudioStreamPlayer2D

@onready var ending_music: AudioStreamPlayer2D = $EndingMusic

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ending_music.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
