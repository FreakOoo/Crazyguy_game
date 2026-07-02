extends Control

func _ready():
	visible = false

func open():
	visible = true

func close():
	visible = false

	var player = get_node("/root/3Dworld/Player")
	player.can_move = true

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(_delta):
	if visible and Input.is_action_just_pressed("ui_cancel"):
		close()
